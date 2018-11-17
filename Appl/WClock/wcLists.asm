
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Palm Computing, Inc. 1993 -- All Rights Reserved

PROJECT:	PEN GEOS
MODULE:		World Clock
FILE:		wcLists.asm

AUTHOR:		Roger Flores, Oct 16, 1992

ROUTINES:
	Name			Description
	----			-----------
	WorldClockInitSelectionLists
		Initialize the city selection lists.


New PENELOPE routines:
	WorldClockPopHomeCityUI (MSG_WC_POPUP_HOME_CITY_UI)
		Displays the UI for the Home/Dest City Selection
		Dialog.  This is rewritten from existing code for Penelope.

	WorldClockSetSortOption (MSG_WC_SET_SORT_OPTION)
		Sorts the city list according to the user selection.

	WorldClockSetCityOption (MSG_WC_SET_CITY_OPTION)
		Responds to UI to set user or city selection.

	WorldClockDisplayMiscellaneousUI
		Sets up the home/dest selection dialog title, ok
		trigger, and daylight boolean.

	WorldClockUpdateListSelections
		Displays the City List listbox according to user's
		sort and user city selections.

	WorldClockChangeUserSelectedCityIndex
		Changes the index into the CityList when the sort
		option changes.

	WorldClockApplySummerTime
		Handles any daylight savings UI changes made in
		response to the apply on the set home/dest city dialogs.

	WorldClockListboxKbdChar
		Intercepts alpha chars to implement quick index
		feature in the city listbox.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial revision
	rsf	4/9/93		Broke from wcUI.asm
	pam	10/15/96	Added Penelope specifc code

DESCRIPTION:
	Contains code to handle the city selection box.
		
	$Id: wcLists.asm,v 1.1 97/04/04 16:22:00 newdeal Exp $

;if _PENELOPE
	All code related to the city listbox and the Set Home/Dest
	City dialog boxes.

;else

	This handles the seven things a user can do in the selection box:


	city, country
	country
	city
	city selection on
	city selection off
	user city on
	user city off


	The first three have their own methods.  The last four share
	MSG_WC_SWITCH_SELECTION which is sent by the boolean group which
	they are in.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



CommonCode	segment	resource



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitSelectionLists

DESCRIPTION:	Initialize the selection lists with the count.

CALLED BY:	WorldClockOpenApplication 

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Initialize the city list and the country list.  This is the
	only place which initializes them.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/ 2/92	Initial version

----------------------------------------------------------------------------@

WorldClockInitSelectionLists	proc	far
	.enter

EC <	call	ECCheckDGroupES						>

	; lock the block to pass to ChunkArrayGetCount
	mov	bx, es:[cityIndexHandle]
	call	MemLock
	mov	ds, ax

	; the city selection list
	; get the number of cities in the list so we can tell the list object
	mov	si, es:[cityNamesIndexHandle]
	call	ChunkArrayGetCount		; count in cx

	; pass count in cx
	ObjCall	MSG_GEN_DYNAMIC_LIST_INITIALIZE, CityList

	; the country city selection list
	; get the number of cities in the list so we can tell the list object
	mov	si, es:[countryNamesIndexHandle]
	call	ChunkArrayGetCount		; count in cx

	; pass count in cx
	ObjCall	MSG_GEN_DYNAMIC_LIST_INITIALIZE, CountryList
	; we no longer need the city index block
	mov	bx, es:[cityIndexHandle]
	call	MemUnlock

	.leave
	ret
WorldClockInitSelectionLists	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WorldClockPopHomeCityUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Popup the city selection ui set to the home city
CALLED BY:	MSG_WC_POPUP_HOME_CITY_UI

PASS:		es - dgroup
		cl - HOME_CITY or DEST_CITY

RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	It is assumed that the appropriate lists are visible.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WorldClockPopHomeCityUI	method WorldClockProcessClass, MSG_WC_POPUP_HOME_CITY_UI

EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>

	push	cx				; save city to change
	call	WorldClockMarkAppBusy
	pop	cx				; restore city to change


	call	BlinkerStop

	mov	es:[changeCity], cl		; save which city to change



	; record which city is selected.  This variable is only changed
	; when the user selects a different city.  It is used by
	; WorldClockSelectLists for selections.
	cmp	cl, mask DEST_CITY
	je	getDestCity

getHomeCity:
	mov	ax, es:[homeCityPtr]
	jmp	gotCityPtr

getDestCity:
	mov	ax, es:[destCityPtr]
	cmp	ax, CITY_NOT_SELECTED
	je	getHomeCity

gotCityPtr:

	mov	es:[userSelectedCity], ax



	; We now must set the user city option if on.   Note that this must be
	; set because it may be set differently if the other city is different.
	; By setting it the user city option, those handlers will insure that
	; the currently selected city is either shown or not shown as well
	; as set program variables. We also set which lists are visible from here.
	and	cl, es:[userCities]		; non zero if this is a user city
	jz	userCityBitOk
	mov	cl, mask USER_CITY_SELECTION
userCityBitOk:
	mov	ch, es:[citySelection]		; find which city lists to use
	andnf	ch, mask CITY_SELECTION		; the only info we want
	ornf	cl, ch				; set the city lists
	clr	ch				; no high bits

	; we must set this new value for citySelection because the boolean
	; list's status message handler does not handle multiple bits
	; changing.  We can avoid adding this capability by set the
	; variable here and letting the status message handler set the lists.
;	mov	es:[citySelection], cl

	clr	dx				; clear no bits
	ObjCall	MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE, CityCountrySelectionOption
	mov	cx, mask CITY_SELECTION or mask USER_CITY_SELECTION
	ObjSend	MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG


	; Now we wish the popup's title bar to display either Home or Destination
	; depending on which the user is changing.

	test	es:[changeCity], mask HOME_CITY
	jz	destCity

	mov	si, offset homeCityText
	jmp	gotCityText

destCity:
	mov	si, offset destCityText

gotCityText:
	GetResourceHandleNS	homeCityText, bx
	call	MemLock
	mov	ds, ax				; text segment
	mov	si, ds:[si]			; dereference chunk handle

	; We do not want the trailing ':' to appear at the top of the dialog
	; so we want to strip off the last ':'.  To do this we count the
	; length of the string and strip off the last character. We will
	; write the ':' back in later.
	push	es				; save dgroup
	segmov	es, ds
	mov	di, si
	call	LocalStringSize
	add	di, cx
	dec	di				; position at char before null
DBCS <	dec	di	>
	pop	es				; restore dgroup
	push	ds:[di]				; save character value
	push	di				; save character position
SBCS <	clr	{byte}ds:[di] >
DBCS <	clr	{word}ds:[di] >

	movdw	cxdx, dssi			; bu

	mov	bp, VUM_MANUAL
	ObjCall	MSG_GEN_REPLACE_VIS_MONIKER_TEXT, CitySelectionInteraction
	mov	dx, bx				; save resource handle

	; now restore the ':' to the trigger name and unlock the block
	pop	di				; restore character position
	pop	ds:[di]				; restore character value
	GetResourceHandleNS	homeCityText, bx
	call	MemUnlock


	mov	bx, dx				; restore resource handle
	ObjCall	MSG_GEN_INTERACTION_INITIATE


	call	WorldClockMarkAppNotBusy


	ret
WorldClockPopHomeCityUI	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_CITY_LIST_REQUEST_MONIKER for WorldClockProcessClass

DESCRIPTION:	Called by ui to set moniker of list entry

PASS:		^lcx:dx - ItemGenDynamicList
		bp - entry # of requested moniker(0-N)

RETURN:		none

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/20/92	Initial version

----------------------------------------------------------------------------@
WorldClockCityListRequestMoniker	method dynamic WorldClockProcessClass,\
					MSG_WC_CITY_LIST_REQUEST_MONIKER
	.enter

FXIP <	GetResourceSegmentNS	dgroup, es				>

	sub	sp, TEMP_STR_SIZE
	push	cx, dx				; ^lcx:dx of GenDynamicList

	mov	cx, ss
	mov	dx, sp				; buffer starts at sp
	add	dx, 4				; plus the two pushes
	mov	ax, bp				; element number

	call	WorldClockFormCityNameText


	; send the GenDynamicList the text in the buffer
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	pop	bx, si				; ^lcx:dx of GenDynamicList
	mov	cx, ss				; buffer segment
	mov	dx, sp				; buffer offset
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed

	add	sp, TEMP_STR_SIZE		; free stack buffer

	.leave
	ret
WorldClockCityListRequestMoniker	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_COUNTRY_CITY_LIST_REQUEST_MONIKER for WorldClockProcessClass

DESCRIPTION:	Called by ui to set moniker of list entry

PASS:		^lcx:dx - ItemGenDynamicList
		bp - entry # of requested moniker(0-N)

RETURN:		none

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/20/92	Initial version

----------------------------------------------------------------------------@
WorldClockCountryCityListRequestMoniker	method dynamic WorldClockProcessClass, \
					MSG_WC_COUNTRY_CITY_LIST_REQUEST_MONIKER
	.enter

	sub	sp, TEMP_STR_SIZE
	push	cx, dx				; ^lcx:dx of GenDynamicList

	mov	cx, ss
	mov	dx, sp				; buffer starts at sp
	add	dx, 4				; plus the two pushes
	mov	ax, bp				; element number
	add	ax, es:[firstCityInCountry]
	mov	si, es:[countryCityNamesIndexHandle]
	call	CityInfoEntryLock

	; get the number of cities in the list so we can tell the list object
	mov	es, cx				; buffer segment
	mov	di, dx				; buffer offset
	mov	si, dx				; move to indexing register
	mov	si, es:[si]			; get pointer

	LocalCopyString


	; we no longer need the city index block, text is on the stack
	call	MemUnlock


	; send the GenDynamicList the text in the buffer
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	pop	bx, si				; ^lcx:dx of GenDynamicList
	mov	cx, ss				; buffer segment
	mov	dx, sp				; buffer offset
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed

	add	sp, TEMP_STR_SIZE		; free stack buffer

	.leave
	ret
WorldClockCountryCityListRequestMoniker	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_COUNTRY_LIST_REQUEST_MONIKER for WorldClockProcessClass

DESCRIPTION:	Called by ui to set moniker of list entry

PASS:		^lcx:dx - ItemGenDynamicList
		bp - entry # of requested moniker (0-N)
		es - dgroup

RETURN:		none

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/20/92	Initial version

----------------------------------------------------------------------------@
WorldClockCountryListRequestMoniker	method dynamic WorldClockProcessClass, \
					MSG_WC_COUNTRY_LIST_REQUEST_MONIKER
	.enter

EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>


	sub	sp, TEMP_STR_SIZE
	push	cx, dx				; ^lcx:dx of GenDynamicList

	mov	cx, ss
	mov	dx, sp				; buffer starts at sp
	add	dx, 4				; plus the two pushes
	mov	ax, bp				; element number
	mov	si, es:[countryNamesIndexHandle]
	call	CityInfoEntryLock		; does right thing

	mov	si, dx
	mov	es, cx				; buffer segment
	mov	di, dx				; buffer offset
	mov	si, es:[si].CIE_name		; use ptr
	LocalCopyString


	; we no longer need the city index block, text is on the stack
	call	MemUnlock


	; send the GenDynamicList the text in the buffer
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	pop	bx, si				; ^lcx:dx of GenDynamicList
	mov	cx, ss				; buffer segment
	mov	dx, sp				; buffer offset
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed

	add	sp, TEMP_STR_SIZE		; free stack buffer

	.leave
	ret
WorldClockCountryListRequestMoniker	endm


COMMENT @------------------------------------------------------------------

FUNCTION:	WorldClockNotUserCity

DESCRIPTION:	A city has been selected so don't use the user city

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/12/93		Initial version

----------------------------------------------------------------------------@
WorldClockNotUserCity	proc	near
	.enter

EC <	call	ECCheckDGroupES					>

	test	es:[citySelection], mask USER_CITY_SELECTION
	jz	done

	; Change the UI boolean option and send the status message.
	mov	cx, mask USER_CITY_SELECTION	; boolean to change
	clr	dx				; clear the boolean
	ObjCall	MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE, CityCountrySelectionOption
	mov	cx, mask USER_CITY_SELECTION
	ObjSend	MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG


done:
	.leave
	ret
WorldClockNotUserCity	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_USE_CITY for WorldClockProcessClass

DESCRIPTION:	Set the city to a new one

PASS:		es - dgroup
		es:[changeCity] - HOME_CITY or DEST_CITY
		cx - city just selected


RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/92	Initial version

----------------------------------------------------------------------------@
WorldClockUseCity      method WorldClockProcessClass, MSG_WC_USE_CITY
	.enter

EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>


	; set the correct city ptr
	cmp	es:[changeCity], mask HOME_CITY
	jne	changeDestCityPtr

; Removed done if identical because it failed to handle exiting user city mode
; when the city is identical!
;	cmp	es:[homeCityPtr], cx		; do nothing if unchanged
;LONG	je	done
	call	SetHomeCity
	jmp	changedCityPtr

changeDestCityPtr:

;	cmp	es:[destCityPtr], cx		; do nothing if unchanged
;LONG	je	done

	call	SetDestCity

	push	cx				; save city selected
	call	EnableDestCityUI
	pop	cx				; restore city selected


changedCityPtr:


	sub	sp, DATE_TIME_BUFFER_SIZE	; large enough buffer

	mov	ax, cx				; element number
	mov	cx, ss
	mov	dx, sp				; buffer starts at sp
	call	WorldClockFormCityNameText


	; lock the Time Zone Info block.  It's used by 
	; WorldClockResolvePointToTimeZone.
	push	ax, bx				; save x, y coords
	mov	bx, es:[timeZoneInfoHandle]
	call	MemLock
	mov	ds, ax
	pop	ax, bx				; restore x, y coords

	; write in the coords and set the correct city text from the buffer
	cmp	es:[changeCity], mask HOME_CITY
	jne	changeDestCityName

	mov	es:[homeCityX], ax
	mov	es:[homeCityY], bx
	mov	cx, ax
	mov	dx, bx
	call	WorldClockResolvePointToTimeZone
	mov	es:[homeCityTimeZone], ax	; time zone hour and minute
	GetResourceHandleNS	HomeCityName, bx
	mov	si, offset HomeCityName
	jmp	changedCityName

changeDestCityName:
	mov	es:[destCityX], ax
	mov	es:[destCityY], bx
	mov	cx, ax
	mov	dx, bx
	call	BlinkerMove
	call	WorldClockResolvePointToTimeZone
	mov	es:[destCityTimeZone], ax	; time zone hour and minute
	GetResourceHandleNS	DestCityName, bx
	mov	si, offset DestCityName

changedCityName:
	push	bx
	mov	bx, es:[timeZoneInfoHandle]	; done with info
	call	MemUnlock
	pop	bx

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, ss				; buffer segment
	mov	dx, sp				; buffer offset
	cmp	es:[uiSetupSoUpdatingUIIsOk], FALSE
	jne	updateNow
	mov	bp, VUM_MANUAL			; ui still setting up
	jmp	vumSet
updateNow:
	mov	bp, VUM_NOW
vumSet:
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed

	add	sp, DATE_TIME_BUFFER_SIZE	; free stack buffer

	call	WorldClockUpdateTimeDates

;done:
	.leave
	ret
WorldClockUseCity	endm



COMMENT @-------------------------------------------------------------------

FUNCTION:	EnableDestCityUI

DESCRIPTION:	

CALLED BY:	

PASS:		

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/18/93		Initial version

----------------------------------------------------------------------------@

EnableDestCityUI	proc	far
	.enter

	; These two options are now usable because there is a destination city.
	mov	dl, VUM_NOW
	ObjSend	MSG_GEN_SET_ENABLED, SetSystemToDestTime


	mov	dl, VUM_NOW
	ObjSend	MSG_GEN_SET_ENABLED, SetDestTimeToSummer

	.leave
	ret
EnableDestCityUI	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_COUNTRY_CITY_CHANGE for WorldClockProcessClass

DESCRIPTION:	Records the city selected and removes the user city selection


PASS:		es - dgroup
		cx - city just selected
		bp - StatTypeMask indicating which items changed. ???

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/9/93		Initial version

----------------------------------------------------------------------------@

WorldClockCountryCityChange	method dynamic WorldClockProcessClass, MSG_WC_COUNTRY_CITY_CHANGE

	push	cx				; save city
	ObjCall	MSG_GEN_ITEM_GROUP_GET_SELECTION, CountryList	; ax = selection
	cmp	ax, GIGS_NONE
	jne	gotCountry


	; the user has selected a city when they were in user city mode.
	; This means that the two lists visible have nothing selected (and
	; that is how this condition is detected).  What we need to ultimately
	; is to determine the city number of the city selected.  To do that 
	; we need to know the number of the country and also select the country
	; in the country list.  We can then pass the country number along.
	; We can use userSelectedCity because the lists shown show it's city.
	mov	ax, es:[userSelectedCity]
	call	WorldClockMapCityToCountryAndCity
	mov	cx, bx				; country number
	clr	dx				; determinate
	ObjSend	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, CountryList
	mov	ax, cx				; country number


gotCountry:
	pop	cx				; restore city

	call	WorldClockMapCountryAndCityToCity
	mov	es:[userSelectedCity], cx
	
	call	WorldClockNotUserCity		; remove user city selection stuff

	ret
WorldClockCountryCityChange	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_CITY_CHANGE for WorldClockProcessClass

DESCRIPTION:	Records the city selected and removes the user city selection


PASS:		es - dgroup
		cx - city just selected
		bp - StatTypeMask indicating which items changed. 

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/9/93		Initial version

----------------------------------------------------------------------------@

WorldClockCityChange	method dynamic WorldClockProcessClass, MSG_WC_CITY_CHANGE

FXIP <	GetResourceSegmentNS	dgroup, es 				>

	mov	es:[userSelectedCity], cx
	
	call	WorldClockNotUserCity	;remove user city selection stuff


	ret
WorldClockCityChange	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_COUNTRY_CHANGE for WorldClockProcessClass

DESCRIPTION:	This inits a new city list for the country and selects 
		the first city.  Also removes the user city selection.

PASS:		es - dgroup
		cx - country just selected
		bp - StatTypeMask indicating which items changed. ???

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/92	Initial version
	rsf	4/9/93		redone

----------------------------------------------------------------------------@

WorldClockCountryChange	method dynamic WorldClockProcessClass, MSG_WC_COUNTRY_CHANGE
	.enter

FXIP <	GetResourceSegmentNS	dgroup, es 				>

	call	WorldClockCountryChangeHandleListStuffOnly


	; now record the city selected
	mov	ax, es:[currentCountry]
	clr	cx				; first city has been selected
	call	WorldClockMapCountryAndCityToCity
	mov	es:[userSelectedCity], cx


	call	WorldClockNotUserCity		; remove user city selection stuff


	.leave
	ret
WorldClockCountryChange	endm



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockCountryChangeHandleListStuffOnly

DESCRIPTION:	This inits a new city list for the country and selects 
		the first city.  

CALLED BY:	WorldClockCountryChange, WorldClockUpdateListSelections

PASS:		cx	= country just selected
		es	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/ 9/93		Initial version

----------------------------------------------------------------------------@

WorldClockCountryChangeHandleListStuffOnly	proc	near
	.enter

EC <	call	ECCheckDGroupES						>


	; check to see if the country is different than that shown
	; Calls to this routine sometimes occur when the country is
	; the same as that shown.  This saves the time of the costly
	; initialization and the annoying flicker too.
	; we need to run this whole procedure in Dove, so no escape valve...
	cmp	es:[currentCountry], cx
	je	done

	mov	es:[currentCountry], cx


	sub	sp, size CountryIndexElement
	mov	ax, cx					; index number
	mov	cx, ss					; buffer segment
	mov	dx, sp					; buffer offset
	mov	si, es:[countryNamesIndexHandle]
	call	CityInfoEntryLock

	call	MemUnlock				; unlock city info

	mov	si, sp
	mov	ax, ss:[si].CIE_firstCity
	mov	es:[firstCityInCountry], ax
	mov	cx, ss:[si].CIE_cityCount
	mov	es:[cityInCountryCount], cx
	
	add	sp, size CountryIndexElement	; sp back to buffer, now free

	; pass count in cx
	ObjCall	MSG_GEN_DYNAMIC_LIST_INITIALIZE, CountryCityList
	clr	cx, dx				; first item, determinate
	ObjCall	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, CountryCityList


done:

	.leave
	ret
WorldClockCountryChangeHandleListStuffOnly	endp



COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_SWITCH_SELECTION for WorldClockProcess

DESCRIPTION:	Switch from city selection to country-city selection and back

PASS:		es - dgroup
		cx - selection mode
		bp - value changed

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/4/92		Initial version
	rsf	7/1/93		Changed to handle multiple bits changing

----------------------------------------------------------------------------@
WorldClockSwitchSelection	method dynamic WorldClockProcessClass, MSG_WC_SWITCH_SELECTION

FXIP <	GetResourceSegmentNS	dgroup, es 				>

EC <	call	ECCheckDGroupES						>

	mov	es:[citySelection], cl		; current status of bits

	test	bp, mask CITY_SELECTION		; did this change?
	jz	updateLists


;	push	cx				; save selection state
;	call	WorldClockMarkAppBusy
;	pop	cx				; restore selection state

;	andnf	es:[citySelection], not mask CITY_SELECTION
;	ornf	es:[citySelection], cl		; record for later
	test	cl, mask CITY_SELECTION
	jnz	doCitySelection



	; set the country city list
	mov	dl, VUM_NOW
	ObjCall	MSG_GEN_SET_NOT_USABLE, CityList


	; set the country and country city list
	mov	dl, VUM_NOW
;	GetResourceHandleNS	CityCountrySelectionGroup, bx	; same resource
	mov	si, offset CityCountrySelectionGroup
	ObjCall	MSG_GEN_SET_USABLE


	jmp	markNotBusy

doCitySelection:


	; set the country and country city list
	mov	dl, VUM_NOW
	ObjCall	MSG_GEN_SET_NOT_USABLE, CityCountrySelectionGroup


	; set the country city list
	mov	dl, VUM_NOW
;	GetResourceHandleNS	CityList, bx	; same resource
	mov	si, offset CityList
	ObjCall	MSG_GEN_SET_USABLE


markNotBusy:
	; This should ideally be done after the update lists but if this
	; routine is entered because the user city changes then the app
	; isn't marked busy because the action is a fairly quick one
	; and so doesn't deserve a busy cursor.
;	call	WorldClockMarkAppNotBusy



updateLists:
	call	WorldClockUpdateListSelections


	.leave
	ret
WorldClockSwitchSelection	endm


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateListSelections

DESCRIPTION:	This handles selecting the user city option when selecting cities.

CALLED BY:	WorldClockSwitchSelection

PASS:		es - dgroup
		cx - selection mode

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	NOTE: The user city info isn't stored yet.  It is stored at the
	apply event.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/9/93		Initial version

----------------------------------------------------------------------------@

WorldClockUpdateListSelections	proc	near
EC <	call	ECCheckDGroupES						>

	test	es:[citySelection], mask USER_CITY_SELECTION ; is there a user city?
LONG	jz	noUserCity


	; There is now a user city so select nothing in the list being shown

	test	es:[citySelection], mask CITY_SELECTION
	jz	deselectCountryCityLists

	clr	dx				; determinate
	ObjCall	MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED, CityList

	mov	cx, es:[userSelectedCity]
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


	jmp	done


deselectCountryCityLists:

	; for both lists we select none but make sure that the last thing
	; the user selected is visible so they can select it again if desired.
	mov	ax, es:[userSelectedCity]
	call	WorldClockMapCityToCountryAndCity
	push	bx				; country list item
	push	ax				; country city list item


	; handle the city
	mov_tr	cx, bx				; country city list item
	call	WorldClockCountryChangeHandleListStuffOnly
						; insure cities for country showing
	clr	dx				; determinate
	ObjCall	MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED, CountryCityList
	pop	cx				; country city list item
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


	clr	dx				; determinate
	ObjCall	MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED, CountryList
	pop	cx				; country list item
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


	jmp	done


noUserCity:

	mov	cx, es:[userSelectedCity]
	test	es:[citySelection], mask CITY_SELECTION
	jz	selectCountryCityLists

	clr	dx				; determinate
	ObjSend	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, CityList


	jmp	done


selectCountryCityLists:

	; for both lists we select none but make sure that the last thing
	; the user selected is visible so they can select it again if desired.
	mov	ax, es:[userSelectedCity]
	call	WorldClockMapCityToCountryAndCity
	push	bx				; country list item

	; handle the city
	push	ax				; save city number
	mov_tr	cx, bx				; country list item
	call	WorldClockCountryChangeHandleListStuffOnly 
						; insure cities for country showing
	pop	cx				; country city list item
	clr	dx				; determinate
	ObjSend	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, CountryCityList

	pop	cx				; restore country number
;	clr	dx				; determinate
	ObjSend	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, CountryList


done:
	ret

WorldClockUpdateListSelections	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockMapCityToCountryAndCity

DESCRIPTION:	Set the country-city lists from the city list

CALLED BY:	WorldClockCountryCityChange, WorldClockUpdateListSelections

PASS:		ax	- city number
		es	- dgroup

RETURN:		ax	- city number
		bx	- country number

DESTROYED:	cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:


		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/9/93		Initial version

----------------------------------------------------------------------------@

WorldClockMapCityToCountryAndCity	proc	near
	uses	es

countryElementNptr	local	nptr

	.enter

EC <	call	ECCheckDGroupES						>

	; lock the block to pass to ChunkArrayGetElement
	mov	bx, es:[cityIndexHandle]
	push	bx				; save handle for unlock
						; since dgroup won't be available
	push	ax				; city index number
	call	MemLock
	mov	ds, ax
	pop	ax				; city index number


	; get the nptr to the city in city info
	mov	si, es:[cityNamesIndexHandle]
	call	ChunkArrayElementToPtr		; pointer at ds:di
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	mov	di, ds:[di]			; get nptr to city info entry
	push	di				; nptr to city name

	mov	si, es:[countryCityNamesIndexHandle]
	push	si				; save index handle
	mov	si, es:[countryNamesIndexHandle]


	; lock the block to copy to stack
	mov	bx, es:[cityInfoHandle]
	call	MemLock
	mov	es, ax

	; skip to the next field
	clr	ax
	mov	cx, -1				; forever
	LocalFindChar
	mov	dx, di				; nptr to country name

loopFindMatchingCountry:
	call	ChunkArrayElementToPtr
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	inc	ax				; point to next element
	mov	countryElementNptr, di		; save, used later if match found
	mov	di, ds:[di].CIE_name
	push	ds, si
	segmov	ds, es, si
	mov	si, dx
	clr	cx				; null terminated
	call	LocalCmpStrings
	pop	ds, si
	jne	loopFindMatchingCountry

	dec	ax				; undo the inc
	call	MemUnlock			; done with city info


	; now find the matching city
	pop	si				; country city names index handle
	pop	dx				; nptr to city name
	push	ax				; country element number
	mov	di, countryElementNptr		; restore element nptr
	mov	ax, ds:[di].CIE_firstCity

loopFindMatchingCity:
	call	ChunkArrayElementToPtr
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	inc	ax				; point to next element
	cmp	ds:[di], dx			; same nptr to city names?
	jne	loopFindMatchingCity

	dec	ax				; undo inc
	mov	di, countryElementNptr		; restore element nptr
	sub	ax, ds:[di].CIE_firstCity

	; ax is city element
	pop	cx				; country number


	pop	bx				; city index handle
	call	MemUnlock
	mov	bx, cx				; return country number

	.leave
	ret
WorldClockMapCityToCountryAndCity	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockMapCountryAndCityToCity


DESCRIPTION:	Map from the Country and City lists to a city number.

CALLED BY:	

PASS:		ax	- country number
		cx	- city number
		es	- dgroup

RETURN:		cx - city number

DESTROYED:	ax, bx, dx, di, si, bp, ds

PSEUDO CODE/STRATEGY:
	Works by get the selection from each list.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/9/93		Initial version

----------------------------------------------------------------------------@
WorldClockMapCountryAndCityToCity	proc	far
	.enter

EC <	call	ECCheckDGroupES						>

	push	cx				; save country city number


	; lock the block to pass to ChunkArrayGetElement
	push	ax				; country index number
	mov	bx, es:[cityIndexHandle]
	call	MemLock
	mov	ds, ax
	pop	ax				; country index number

	; get the first city in the country
	mov	si, es:[countryNamesIndexHandle]
	call	ChunkArrayElementToPtr		; pointer at ds:di
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	mov	cx, ds:[di].CIE_firstCity	; get nptr to city info entry

	; get the nptr to the city in city info
	pop	ax				; country selection
	add	ax, cx
	mov	si, es:[countryCityNamesIndexHandle]
	call	ChunkArrayElementToPtr		; pointer at ds:di
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	mov	cx, ds:[di]			; get nptr to city info entry


	; now find the matching city
	mov	si, es:[cityNamesIndexHandle]
	clr	ax				; start with first element

loopFindMatchingCity:
	call	ChunkArrayElementToPtr
EC <	ERROR_C	WC_ERROR_OUT_OF_ARRAY_BOUNDS				>
	inc	ax				; point to next element
	cmp	ds:[di], cx			; same nptr to city names?
	jne	loopFindMatchingCity

	dec	ax				; undo inc
	mov	cx, ax				; city number

	mov	bx, es:[cityIndexHandle]
	call	MemUnlock


	.leave
	ret
WorldClockMapCountryAndCityToCity	endp




COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_APPLY for CustomApplyInteractionClass

DESCRIPTION:	Apply the changes to the city.

PASS:		*ds:si	= CustomApplyInteractionClass object
		ds:di	= CustomApplyInteractionClass instance data
		ds:bx	= CustomApplyInteractionClass object (same as *ds:si)
		es 	= segment of CustomApplyInteractionClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/12/93		Initial version
	rsf	6/9/93		recoded

----------------------------------------------------------------------------@
WorldClockUserCityApply	method dynamic CustomApplyInteractionClass, MSG_GEN_APPLY

	mov	di, offset CustomApplyInteractionClass
	call	ObjCallSuperNoLock

FXIP <	GetResourceSegmentNS	dgroup, es			>


	;Did the user pick the user city?
	test	es:[citySelection], mask USER_CITY_SELECTION
	jz	notUserCity

	;Record the city as using the user city.
	mov	al, es:[changeCity]
	ornf	es:[userCities], al
	call	SetUserCities

	call	WorldClockUpdateUserCities
	jmp	done

notUserCity:

	;Remove any user city stuff and set the city data.
	mov	al, es:[changeCity]
	not	al
	andnf	es:[userCities], al
	call	SetUserCities

	mov	cx, es:[userSelectedCity]
	call	WorldClockUseCity


done:

	ret

WorldClockUserCityApply	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_VIS_CLOSE for CustomApplyInteractionClass

DESCRIPTION:	Apply the user city info and then call the super class for rest

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
CustomApplyInteractionClose	method dynamic CustomApplyInteractionClass, \
	MSG_VIS_CLOSE

	.enter


	mov	di, offset CustomApplyInteractionClass
	call	ObjCallSuperNoLock


	; call BlinkerOn after all the ui stuff has settled down.  We force
	; it on the queue so it occurs after the ui junk.
	mov	ax, MSG_WC_BLINKER_ON
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


	.leave
	ret
CustomApplyInteractionClose	endm



CommonCode	ends









