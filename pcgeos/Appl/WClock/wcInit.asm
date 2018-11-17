COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Palm Computing, Inc. 1992 -- All Rights Reserved

PROJECT:	PEN GEOS
MODULE:		World Clock
FILE:		wcInit.asm

AUTHOR:		Roger Flores, Oct 13, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/13/92	Initial revision
	pam	10/15/96	added Penelope specific changes

DESCRIPTION:
	Contains intialization routines for World Clock.
		
	$Id: wcInit.asm,v 1.1 97/04/04 16:21:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WorldClockOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize WorldClock -- build a fonts menu
CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		cx - AppAttachFlags
		dx - Handle of AppLaunchBlock
		bp - Handle of extra state block
RETURN:		none

DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WorldClockOpenApplication	method WorldClockProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	push	bp				;save extra block handle 
	

	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset WorldClockProcessClass
	call	ObjCallSuperNoLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>

FXIP <	GetResourceHandleNS	dgroup, ES				>

	pop	bx				;bx <- block handle for data
	
	tst	bx				;check for no block
	jz	stateDataProcessed		;branch if no state data

	; Restore the data
	;
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>

	mov	ds, ax				; set up the segment
	mov	cx, (RestoreStateEnd - RestoreStateBegin)
	clr	si
	mov	di, offset RestoreStateBegin
	cld
	rep	movsb				; copy the bytes
	call	MemUnlock

stateDataProcessed:

	call	WorldClockReadDataFile
	jc	quitApp

	call	WorldClockInitCityDatabase
	jc	quitApp

	; Add World Clock to the general notification list
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx			; clear because bx is process handle
	mov     bx, MANUFACTURER_ID_GEOWORKS
	mov     ax, GCNSLT_DATE_TIME
	call    GCNListAdd

	call	WorldClockInitSelectionLists	
	
	call	WorldClockInitViewWindowHandle

	call	WorldClockSetupFromStateData

	call	WorldClockStartTimer

done:
	ret


quitApp:
	mov	ax, MSG_META_QUIT
	GetResourceHandleNS	WorldClockApp, bx
	mov	si, offset WorldClockApp
	clr	di
	call	ObjMessage

	jmp	done

WorldClockOpenApplication	endm


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitViewWindowHandle

DESCRIPTION:	Get the view's window handle.  Must be done after the
		ui has been created but before anything draws to the view.
	

CALLED BY:	WorldClockOpenApplication

PASS:		es	- dgroup

RETURN:		es:[winHandle]

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Drawing to the view happens every second as the blinker blinks.
	This routine simply caches the view's window handle in a variable
	in dgroup to reduce the speed overhead.

	NOTE: We used to rely on getting the view's window handle from
	within it's META_EXPOSED, but this proved insufficient with the
	Lazarus state saving stuff which could sometimes revive the app
	so that the blinker was activated before the META_EXPOSED 
	occurred.  This now prevents it by explicitly getting the handle.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/18/93		Initial version

----------------------------------------------------------------------------@

WorldClockInitViewWindowHandle	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	ObjCall	MSG_GEN_VIEW_GET_WINDOW, WorldView
	mov	es:[winHandle], cx		; if the result is null it's ok
						; the draw routines detect it

	.leave
	ret
WorldClockInitViewWindowHandle	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockSetupFromStateData

DESCRIPTION:	Setup based on the state data.
		Sets up the default cities and the city selection type.

CALLED BY:	WorldClockOpenApplication

PASS:		es - dgroup

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/30/92	Initial version
	rsf	3/16/93		Made defaults for both home & dest cities

----------------------------------------------------------------------------@

WorldClockSetupFromStateData	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	; if the home city isn't selected then this app is running for
	; the first time (because homeCityPtr is ALWAYS set and saved to 
	; state).  In this case use the defaults and then try to get any 
	; stuff previously set by the user and kept in the ini file.

	cmp	es:[homeCityPtr], CITY_NOT_SELECTED
	jne	setCities

	mov	ax, es:[defaultTimeZone]
	mov	es:[selectedTimeZone], ax

	mov	ax, es:[defaultHomeCity]
	mov	es:[homeCityPtr], ax

	mov	ax, es:[defaultDestinationCity]
	mov	es:[destCityPtr], ax


	; These may or may not read entries from the ini file.
	call	GetHomeCity
	call	GetDestCity
	call	GetSelectedTimeZone
	call	GetCitySummerTime
	call	GetUserCities
	call	GetHomeIsSystemClock
	call	GetUserCityTimeZone
	call	GetUserCityX
	call	GetUserCityY
	call	GetUserCityName


setCities:
	call	GeodeGetProcessHandle			; target of msgs below


	; set the home city
	test	es:[userCities], mask HOME_CITY
	jnz	setDestCity

	mov	es:[changeCity], mask HOME_CITY
	mov	cx, es:[homeCityPtr]
	ObjCall	MSG_WC_USE_CITY


	; set the destination city
setDestCity:
	test	es:[userCities], mask DEST_CITY
	jnz	updateUserCities

	mov	es:[changeCity], mask DEST_CITY
	mov	cx, es:[destCityPtr]
	ObjCall	MSG_WC_USE_CITY


	tst	es:[userCities]
	jz	userCitiesUpdated

updateUserCities:
	call	WorldClockUpdateUserCities

userCitiesUpdated:

	call	SetupUIFromData

	; citySelection indicates whether the city selection or city/country
	; selection list is in use.
	mov	cl, es:[citySelection]
	cmp	cl, FALSE
	je	citySelectionDialogSet

   	ObjCall	MSG_WC_SWITCH_SELECTION

citySelectionDialogSet:

	; all the ui is set so now enable and perform an update
	mov	es:[uiSetupSoUpdatingUIIsOk], TRUE

	call	WorldClockUpdateTimeDates

	.leave
	ret
WorldClockSetupFromStateData	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetupUIFromData

DESCRIPTION:	Sets up the extra ui gadetry with the last settings

CALLED BY:	WorldClockSetupFromStateData

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
2	----	----		-----------
	rsf	11/18/93		Initial version

----------------------------------------------------------------------------@

SetupUIFromData	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	cmp	es:[destCityPtr], CITY_NOT_SELECTED
	jne	enableDest

	test	es:[userCities], mask DEST_CITY
	jz	destCitySet

enableDest:
	call	EnableDestCityUI
destCitySet:


	; it is possible to start up without a state file.  The ui
	; for the user city option when selecting a city is to be not
	; enabled.  Thus, if we want the user to be able to select it
	; we had better enable it here after the default value, state
	; saved value, and ini file value for the userCities variable
	; has been resolved.

	; we want to enable the user city option if the city has a name
	; and a non zero location.
	tst	es:[userCityName]
	jz	noUserCity

	tst	es:[userCityX]
	jnz	userCity

	tst	es:[userCityY]
	jnz	userCity

	jmp	noUserCity

userCity:
	segmov	ds, es
	mov	si, offset userCityName
	call	SetUserCityText

	mov	dl, VUM_NOW
	ObjSend	MSG_GEN_SET_ENABLED, UserCity

noUserCity:

	; Now handle the system clock ui
	cmp	es:[systemClockCity], mask HOME_CITY
	je	systemClockCitySet


	mov	cl, es:[systemClockCity]	; city for system time
	clr	dx				; determinate
	mov	ch, dh				; clear ch
	ObjSend	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION, SetSystemClock

systemClockCitySet:
	cmp	es:[citySummerTime], NO_CITY
	je	citySummerTimeSet

	mov	cl, es:[citySummerTime]
	clr	dx				; no indeterminate items
	mov	ch, dh				; clear ch
	ObjSend	MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE, SetSummerTime


citySummerTimeSet:


	.leave
	ret
SetupUIFromData	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_META_DETACH for WorldClockProcessClass

DESCRIPTION:	Intercept to remove the timer

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The timer must be removed before the application's window is
	destroyed.  Otherwise if we get a timer event and try to draw 
	to the view we will find that the handle we have is no longer 
	valid.  The solution is to not even try!

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/13/93		Initial version

----------------------------------------------------------------------------@
WorldClockMetaDetach	method dynamic WorldClockProcessClass, MSG_META_DETACH
	.enter

FXIP <	GetResourceHandleNS	dgroup, ds				>

	push	cx, dx				; save for superclass

	; remove the continual timer
	mov	bx, ds:[timerHandle]		; timer handle => BX
	clr	ax				; 0 => continual
	call	TimerStop			; stop the timer
EC <	ERROR_C	WC_ERROR_TIMER_NOT_STOPPED				>


	; Remove World Clock from the general notification list
	; cx:dx must both be identical to the optr added!
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx			; clear because bx is process handle
        mov     bx, MANUFACTURER_ID_GEOWORKS
        mov     ax, GCNSLT_DATE_TIME
        call    GCNListRemove
EC <	ERROR_NC WC_ERROR_NOT_REMOVED_FROM_GCN_LIST			>


	pop	cx, dx				; save for superclass

	mov	ax, MSG_META_DETACH
	mov	di, offset WorldClockProcessClass
	call	ObjCallSuperNoLock


	.leave
	ret
WorldClockMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WorldClockCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down WorldClock
CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		es - dgroup
		ax - the method
RETURN:		cx - handle of block to save (0 for none)
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WorldClockCloseApplication	method dynamic WorldClockProcessClass, \
					MSG_GEN_PROCESS_CLOSE_APPLICATION

FXIP <	GetResourceHandleNS	dgroup, es				>

	; Palm applications are subject to Lazarus revival on the Zoomer.
	; One consenquence is that idata may not be reinitialized if the
	; dgroup block hasn't been discarded, but instead reused from the 
	; prior instance of the application.  Because of this we clear
	; the variables dependendant on being reinitialized.
	mov	es:[uiSetupSoUpdatingUIIsOk], FALSE
	mov	es:[destCityBlinkDrawn], FALSE
	;
	; Store the state
	;
	mov	ax, (RestoreStateEnd - RestoreStateBegin)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or \
		    mask HF_SHARABLE or \
		    (mask HAF_LOCK shl 8)
	call	MemAlloc
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	es, ax

	;
	; Copy the state into the locked block, and then unlock it.
	;
	mov	cx, (RestoreStateEnd - RestoreStateBegin)
	clr	di
	mov	si, offset RestoreStateBegin
	cld
	rep	movsb				; copy the bytes
	call	MemUnlock
	mov	cx, bx

	ret
WorldClockCloseApplication	endm



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockReadBlockFromDataFile

DESCRIPTION:	Allocate a block and fill it with the next data file block.
		This is called three times:
			1. read the world map bitmap
			2. read the time zone info
			3. read the city info

CALLED BY:	WorldClockReadDataFile

PASS:		si - dgroup variable to assign block handle
		bx - file handle
		ss:sp - word sized buffer on stack

RETURN:		carry set if error
		bp - user error msg if error
		cx - number of bytes read for block

DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:
		read block size from the data file
		allocate it
		read in the block
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/10/92	Initial version

----------------------------------------------------------------------------@

WorldClockReadBlockFromDataFile	proc	near
	.enter

	sub	sp, size word		; create word size buffer on stack

	mov	di, bx			; save file handle

	clr	al			; no flags
	mov	cx, size word
	segmov	ds, ss, dx		; buffer segment
	mov	dx, sp			; buffer offset
	call	FileRead
	jnc	gotBlockSize
	mov	bp, WC_MSG_ERROR_BAD_DATA_FILE
	jmp	done
gotBlockSize:

	mov	bp, sp
	mov	ax, ss:[bp]		; size of this part of the file
	mov	cx, ALLOC_DYNAMIC_LOCK;was:mov	cx,(HAF_STANDARD_LOCK) shl 8
	call	MemAlloc
	jnc	gotNewBlock
	mov	bp, WC_MSG_ERROR_CRITICAL_OUT_OF_MEMORY
	mov	bx, di			; file handle
	jmp	done
gotNewBlock:
	mov	es:[si], bx

	mov	ds, ax			; this info segment
	clr	dx			; this info offset
	mov	cx, ss:[bp]		; bytes to read
	clr	al			; no flags
	xchg	bx, di			; xchg file handle with block handle
	call	FileRead
	jnc	gotBlockData
	mov	bp, WC_MSG_ERROR_BAD_DATA_FILE
	jmp	done
gotBlockData:

	xchg	bx, di			; xchg block handle with file handle 
	call	MemUnlock		; unlock this part 

	mov	bx, di			; file handle
	clr	bp			; no error

done:
	add	sp, size word

	.leave
	ret
WorldClockReadBlockFromDataFile	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockReadDataFile

DESCRIPTION:	Read the city database from a file into a chunk array

CALLED BY:	WorldClockOpenApplication

PASS:		es - dgroup

RETURN:		carry set if error
		dgroup:[worldMapBitmapHandle]
		dgroup:[timeZoneInfoHandle]
		dgroup:[cityInfoHandle]

DESTROYED:	ax, bx, cx, dx, si, bp, ds

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial version

----------------------------------------------------------------------------@

WorldClockReadDataFile	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	; set the path to WCLOCK
	segmov	ds, es			; ds:dx - path 
	mov	dx, offset dataFilePath
	mov	bx, SP_USER_DATA
	call	FileSetCurrentPath


	; open the file for reading
	mov     al, FILE_ACCESS_R or FILE_DENY_NONE
	mov	dx, offset dataFileName	; ds:dx - file name
	call	FileOpen		; open the file
	LONG	jc	errorFileNotOpen; exit if error 

	mov	bx, ax			; file handle

	segmov	ds, es, dx		; dest segment
	mov	dx, offset DataFileVariablesBegin		; dest offset
	mov	cx, DataFileVariablesEnd - DataFileVariablesBegin	; bytes to read
	clr	al			; no flags
	call	FileRead
	jnc	gotVersionNumber
	mov	bp, WC_MSG_ERROR_BAD_DATA_FILE
	jmp	errorRecoverCloseFile
gotVersionNumber:

	; compare the read in version of the wcm file and signal an error
	; if the version is different.
	mov	ax, es:[versionWCM]
	cmp	ax, CURRENT_VERSION_WCM
	je	versionWCMOK
	mov	bp, WC_MSG_ERROR_DATA_FILE_IS_BAD_VERSION
	jmp	errorRecoverCloseFile
versionWCMOK:

	mov	si, offset worldMapBitmapHandle
	call	WorldClockReadBlockFromDataFile
	tst	bp			; non zero if error
	jnz	errorRecoverCloseFile	


	mov	si, offset timeZoneInfoHandle
	call	WorldClockReadBlockFromDataFile
	tst	bp			; non zero if error
	jnz	errorRecoverCloseFile	

	
	mov	si, offset cityInfoHandle
	call	WorldClockReadBlockFromDataFile
	tst	bp			; non zero if error
	jnz	errorRecoverCloseFile	
	mov	es:[cityInfoSize], cx	; byte read for block


	; close the file
	clr	al			; no flags
	call	FileClose

	mov	es:[dataFileLoaded], TRUE

	clc				; return no error

done:

	.leave
	ret



errorFileNotOpen:
	mov	bp, WC_MSG_ERROR_NO_DATA_FILE
	jmp	reportError

errorRecoverCloseFile:
	call	FileClose

reportError:
	mov	cx, es			; cx:dx - file name
	mov	dx, offset dataFileName
	mov	ax, MSG_WC_DISPLAY_USER_MESSAGE
	call	DisplayUserMessage	; put up an error dialog box

	stc				; return error
	jmp	done

WorldClockReadDataFile	endp




COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockCreateCityNamesIndex

DESCRIPTION:	Build a city names index to the city info block
		Used to retrieve data by city name.

CALLED BY:	WorldClockInitCityDatabase

PASS:		es - dgroup

RETURN:		ds - city index segment (LOCKED)
		bx - city info segment (LOCKED)

DESTROYED:	ax, bx, cx, dx, bp, di, si, ds
		city info unlocked

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial version

----------------------------------------------------------------------------@

WorldClockCreateCityNamesIndex	proc	near

cityIndexSegment		local	word
localCityNamesIndexHandle	local	word
	uses	es
	.enter

EC <	call	ECCheckDGroupES						>

	mov	dx, es:[cityInfoSize]		; size of city info

	mov	bx, es:[cityInfoHandle]
	call	MemLock				; city info block
	mov	ds, ax				; city info segment 
	push	ds, ds				; save city info segment twice

	; Allocate a single block and make it the map block
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	mov	es:[cityIndexHandle], bx

	call	MemLock
	mov	ds, ax

	; initialize the selected list chunk array.
	clr	ax, cx, si		; no flags, no extra space, new chunk
	mov	bx, size nptr
	call	ChunkArrayCreate
	mov	ss:[cityIndexSegment], ds	; may have moved!
	mov	es:[cityNamesIndexHandle], si
	mov	ss:[localCityNamesIndexHandle], si ; so we may use es

	; setup for loop

	pop	es				; city info segment
	clr	si				; start with first entry

makeNameIndexLoop:
	cmp	si, dx				; CityInfoSize
	jge	cityInfoConverted

	push	si				; save position
	mov	ds, ss:[cityIndexSegment]
	mov	si, ss:[localCityNamesIndexHandle]
	mov	ax, size nptr
	call	ChunkArrayAppend
	mov	ss:[cityIndexSegment], ds	; may have moved!
	pop	si				; restore position
	mov	ds:[di], si			; index element gets info ptr
 
SBCS <	; localize the city name field					>
SBCS <	segmov	ds, es, ax			; city info segment	>
SBCS <	clr	cx							>
SBCS <	mov	ax, C_PERIOD						>
SBCS <	call	LocalDosToGeos						>


	; skip past city name field to country name field
	mov	di, si				; current pos in info segment
	clr	ax				; null terminator
	mov	cx, -1				; scan forever
	LocalFindChar				; scan es:[di] for null char
	mov	si, di				; end of field


SBCS <	; localize the country name field				>
SBCS <	clr	cx							>
SBCS <	mov	ax, C_PERIOD						>
SBCS <	call	LocalDosToGeos						>

	; skip past country name field to coordinates
	mov	di, si				; current pos in info segment
	clr	ax				; null terminator
	mov	cx, -1				; scan forever
	LocalFindChar				; scan es:[di] for null char
	mov	si, di				; end of field

	; skip the x, y coordinate fields
	add	si, 2 * size word;



	jmp	makeNameIndexLoop

cityInfoConverted:

	pop	bx				; return city info segment

	mov	ds, ss:[cityIndexSegment]	; return

	.leave
	ret
WorldClockCreateCityNamesIndex	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitCountryCityNamesIndex

DESCRIPTION:	Copy the cityNamesIndex to the countryCityNamesIndex
		so it can be resorted.

CALLED BY:	WorldClockInitCityDatabase

PASS:		es - dgroup
		ds - city index segment (LOCKED)
		bx - city info segment (LOCKED)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/29/92	Initial version

----------------------------------------------------------------------------@

WorldClockInitCountryCityNamesIndex	proc	near
	uses	bx, es
	.enter

EC <	call	ECCheckDGroupES					>

	;allocate another chunk the same size as the cityNamesIndex chunk
	mov	bx, es:[cityNamesIndexHandle]
	ChunkSizeHandle	ds, bx, cx
	call	LMemAlloc
	mov	es:[countryCityNamesIndexHandle], ax

	; copy the cityNamesIndex to the countryCityNamesIndex
	; these are the same except they are later sorted differently
	segmov	es, ds, si			; memcpy to same segment
	mov	si, ds:[bx]
	mov	di, ax
	mov	di, es:[di]
	rep	movsb				; memcpy ds:si to es:di

	.leave
	ret
WorldClockInitCountryCityNamesIndex	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockSortCityDatabaseIndexes

DESCRIPTION:	Sort the city names index in ascending order

CALLED BY:	WorldClockInitCityDatabase, WorldClockInitCountryIndex

PASS:		es - dgroup
		ds - city index segment (LOCKED)
		bx - city info block (LOCKED)

RETURN:		nothing

DESTROYED:	bx, cx, dx, si, ds

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial version

----------------------------------------------------------------------------@

WorldClockSortCityDatabaseIndexes	proc	near
	.enter

EC <	call	ECCheckDGroupES					>
	
	mov	si, es:[cityNamesIndexHandle]
	mov	cx, cs
	mov	dx, offset WorldClockSortCityIndexesCallback
	call	ChunkArraySort


	mov	si, es:[countryCityNamesIndexHandle]
	mov	cx, cs
	mov	dx, offset WorldClockSortCountryCityIndexesCallback
	call	ChunkArraySort

	.leave
	ret
WorldClockSortCityDatabaseIndexes	endp


WorldClockSortCityIndexesCallback	proc	far
	uses	ds, es
	.enter

	mov	si, ds:[si]
	mov	ds, bx				; city info segment
	mov	di, es:[di]
	mov	es, bx				; city info segment
	clr	cx
	call	LocalCmpStrings


	.leave
	ret
WorldClockSortCityIndexesCallback	endp


WorldClockSortCountryCityIndexesCallback	proc	far
	uses	ds, es
	.enter

	mov	cx, -1				; forever
	clr	ax				; null char
	mov	si, ds:[si]
	mov	di, es:[di]			; 2nd string
	mov	ds, bx				; city info segment
	mov	es, bx				; city info segment
; Other versions: Sort primarily on the country name, and secondly on the
; city name.
	push	si				; save ptr to city name
	push	di				; save ptr to city name

	push	di				; save 2nd string handle
	mov	di, si				; 1st string
	LocalFindChar				; scan for end of string
	mov	si, di				; first string
	pop	di				; 2nd string handle
	LocalFindChar				; scan for end of string

	clr	cx
	call	LocalCmpStrings
	pop	si, di				; restore pointers to city name

	jne	done

	call	LocalCmpStrings
done:
	.leave
	ret
WorldClockSortCountryCityIndexesCallback	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitCountryIndex

DESCRIPTION:	Initialize the country name index.

CALLED BY:	WorldClockInitCityDatabase

PASS:		es - dgroup
		ds - city index segment (LOCKED)
		bx - city info segment (LOCKED)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The country name index is a chunk array of ptrs to the
		country names in the the city info block.  The index
		is in the order of the country city index, which
		is in ascending country name order.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/2/92		Initial version

----------------------------------------------------------------------------@

WorldClockInitCountryIndex	proc	near
	uses	bx, ds, es
	.enter

EC <	call	ECCheckDGroupES			; check dgroup		>
EC <	mov	ax, ds				; check city index	>
EC <	call	ECCheckSegment						>
EC <	mov	ax, bx				; check city info	>
EC <	call	ECCheckSegment						>


	; initialize the selected list chunk array.
	push	bx				; save city info segment
	mov	bx, size CountryIndexElement
	clr	ax, cx, si		; no flags, no extra space, new chunk
	call	ChunkArrayCreate
	mov	es:[countryNamesIndexHandle], si


	mov	dx, si				; country names handle
	mov	si, es:[countryCityNamesIndexHandle]	; enum this array
	pop	es				; save city info segment
	push	bp
	clr	bp				; this may point to anything
						; except the first country name
						; points to city name
	mov	ax, NO_COUNTRY			; no country yet
	clr	cx				; no cities in country
	mov	bx, cs
	mov	di, offset WorldClockInitCountryIndexCallback
	call	ChunkArrayEnum
	pop	bp

	; The last created element will not have it's city count.  Do this now.
	mov	si, dx
	call	ChunkArrayElementToPtr
	mov	ds:[di].CIE_cityCount, cx


	.leave
	ret
WorldClockInitCountryIndex	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitCountryIndexCallback

DESCRIPTION:	Add a country name to the index if new

CALLED BY:	WorldClockInitCountryIndex

PASS:		*ds:si - array
		ds:di - array element being enumerated
		es:bp - current country name
		dx - country index handle
		ax - last county index handle
		cx - count of cities in country


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/ 2/92	Initial version

----------------------------------------------------------------------------@

WorldClockInitCountryIndexCallback	proc	far
	.enter

	push	ds, si, di, ax, cx
	mov	si, ds:[di]
	segmov	ds, es, ax
	mov	di, bp
	clr	ax
	mov	cx, -1					; forever

	push	es, di
	segmov	es, ds, di
	mov	di, si
	LocalFindChar					; skip to country field
	mov	si, di
	pop	es, di

	clr	cx					; null term strings
	call	LocalCmpStrings
	pop	ds, bx, di, ax, cx
	je	done

	mov	bp, si					; country name ptr

	push	ax					; country element num
	mov	si, bx
	call	ChunkArrayPtrToElement			; ax <- element(ds:di)
	mov	bx, ax					; city element number
	pop	ax					; country element num

	mov	si, dx					; country index array
	cmp	ax, NO_COUNTRY
	jz	wroteCountForLastCountry
	call	ChunkArrayElementToPtr
	mov	ds:[di].CIE_cityCount, cx

wroteCountForLastCountry:
	mov	ax, size CountryIndexElement
	call	ChunkArrayAppend

	mov	ds:[di].CIE_name, bp
	mov	ds:[di].CIE_firstCity, bx
	clr	cx					; clear city count

	call	ChunkArrayPtrToElement			; ax <- element num
done:
	inc	cx					; one more city
	clc						; don't stop enum!
	.leave
	ret
WorldClockInitCountryIndexCallback	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockInitCityDatabase

DESCRIPTION:	Initialize the city info block and the indexes

CALLED BY:	WorldClockOpenApplication

PASS:		es - dgroup

RETURN:		carry set if error

DESTROYED:	lots

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/19/92	Initial version

----------------------------------------------------------------------------@

WorldClockInitCityDatabase	proc	near
	.enter

EC <	call	ECCheckDGroupES					>

	call	WorldClockCreateCityNamesIndex
	jc	done

	call	WorldClockInitCountryCityNamesIndex

	call	WorldClockSortCityDatabaseIndexes

	call	WorldClockInitCountryIndex
	; free the locked blocks from above
	mov	bx, es:[cityIndexHandle]
	call	MemUnlock

	mov	bx, es:[cityInfoHandle]
	call	MemUnlock

	clc						; no error

done:
	.leave
	ret
	
WorldClockInitCityDatabase	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockStartTimer

DESCRIPTION:	Starts a timer to blink the destination city

CALLED BY:	

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, 

PSEUDO CODE/STRATEGY:
	add the app to the active list to receive MSG_META_DETACH to
	remove timer 
	start the timer
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/4/93		Initial version

----------------------------------------------------------------------------@
WorldClockStartTimer	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	; start the timer
	mov	cx, TICKS_PER_SECOND		; time until first event (1 sec.)
	mov	di, TICKS_PER_SECOND		; go off once a second
	mov	al, TIMER_EVENT_CONTINUAL	; a continual timer
	call	GeodeGetProcessHandle		; process handle to BX
	mov	dx, MSG_WC_TIMER_TICK		; method to send
	call	TimerStart

	;handle needed to remove later.  Id is not needed for continual timers.
	mov	es:[timerHandle], bx		; save the handle

	call	WorldClockCalibrateClock

	.leave
	ret
WorldClockStartTimer	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockCalibrateClock

DESCRIPTION:	Calibrate the minute countdown to the system clock

CALLED BY:	WorldClockStartTimer
		WorldClockNotifyTimeDateChange

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/24/93		Initial version

----------------------------------------------------------------------------@

WorldClockCalibrateClock	proc	far
	.enter

EC <	call	ECCheckDGroupES					>

	; This variable contains the number of ticks to the next change of the
	; minute.  Calculate the time to the change of the minute and 
	; place the number of ticks in minuteCountdown.  After the first
	; countdown, the variable will be set to TICKS_PER_SECOND * 
	; SECONDS_PER_MINUTE.  See MSG_WC_TIMER_TICK.
	call	TimerGetDateAndTime
	mov	ax, SECONDS_PER_MINUTE
	sub	al, dh				; 60 - seconds = seconds left
	mov	dh, TICKS_PER_SECOND
	mul	dh				; ax = ticks left this minute
	mov	es:[minuteCountdown], ax

	.leave
	ret
WorldClockCalibrateClock	endp


InitCode	ends







