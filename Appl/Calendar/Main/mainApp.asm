COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainApp.asm<2>

AUTHOR:		Don Reeves, May  4, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 4/92		Initial revision

DESCRIPTION:
	Contains code dealing with GeoPlanner's application object 

	$Id: mainApp.asm,v 1.1 97/04/04 14:48:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
	CalendarAppClass
idata		ends

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the attach, and then tell any reminder boxes to
		reset their time & date strings.

CALLED BY:	UI (MSG_META_ATTACH)
	
PASS:		DS:*SI	= CalendarAppClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarAttach	method	CalendarAppClass,	MSG_META_ATTACH
	.enter

	; If we are in the CUI, we need to:
	; - set the .INI category to "calendar0"
	; - wipe out the View menu
	;
	push	ax, cx, dx, si, bp
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	checkOptions

	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	mov	cx, 10				;'calendar0' + NULL
	call	ObjVarAddData
	mov	{word}ds:[bx+0], 'ca'
	mov	{word}ds:[bx+2], 'le'
	mov	{word}ds:[bx+4], 'nd'
	mov	{word}ds:[bx+6], 'ar'
	mov	{word}ds:[bx+8], '0'		;'calendar0' + NULL

	mov	ax, MSG_GEN_SET_NOT_USABLE
	GetResourceHandleNS	ViewMenu, bx
	mov	si, offset ViewMenu
	mov	dl, VUM_NOW
	call	ObjMessage_init_send

ifdef GPC
	; In CUI, remove File:New/Open and File:Close
	GetResourceHandleNS	CalendarDocumentControl, bx
	call	ObjSwapLock
	mov	si, offset CalendarDocumentControl
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	.warn -private
	ornf	ds:[di].GDCI_features, mask GDCF_SINGLE_DOCUMENT
	.warn @private
	call	ObjMarkDirty
	call	ObjSwapUnlock
endif

	; Wipe out Options menu & Pref DB, if directed by the .INI file
checkOptions:
	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	doAttach
if _OPTIONS_MENU
	mov	ax, MSG_GEN_SET_NOT_USABLE
	GetResourceHandleNS	OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	dl, VUM_NOW
	call	ObjMessage_init_send
endif
	mov	ax, MSG_GEN_SET_NOT_USABLE
	GetResourceHandleNS	PreferencesEntry, bx
	mov	si, offset PreferencesEntry
	mov	dl, VUM_NOW
	call	ObjMessage_init_send

	; Complete the MSG_META_ATTACH & reset reminder time/date strings
doAttach:
	pop	ax, cx, dx, si, bp
	mov	di, offset CalendarAppClass
	call	ObjCallSuperNoLock		; pass on the MSG_META_ATTACH

	push	si
	mov	ax, MSG_CALENDAR_RESET_REMINDER	; method to send to window list
						;	entries
	push	es
	GetResourceSegmentNS	ReminderClass, es
	mov	bx, es				; method is for Reminder objs
	pop	es
	mov	si, offset ReminderClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	pop	si
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, offset CalendarAppClass
	call	ObjCallSuperNoLock		
	add	sp, size GCNListMessageParams
	
if PZ_PCGEOS ; Pizza
	; Load holiday data from file
	;
	push	si, bx
	mov	ax, MSG_JC_SHIC_CONSTRUCT
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bx
endif

	.leave
	ret
CalendarAttach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the detach, to let the GeoPlanner clean up
		any loose ends.

CALLED BY:	UI (MSG_META_DETACH)
	
PASS:		DS:*SI	= CalendarAppClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	BX, DI, Same as MSG_META_DETACH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/8/90		Initial version
	sean	12/5/95		Responder change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarDetach	method	CalendarAppClass,	MSG_META_DETACH
	.enter

	; For Responder, we can't have the Details Dialog, or
	; other dialogs intiatable from Details, open when
	; we save to state.  Also, if To-do list is showing,
	; we can't have the "Mark As" dialog initiated.  sean 12/5/95.
	;

	tst	es:[alarmsUp]			; any alarms visible ??
	jz	done
	push	ax, cx, dx, bp

	push	si
	clr	cx				; CX must not be -1
	mov	dx, -1				; DX indicates snooze disable
	mov	ax, MSG_CALENDAR_KILL_REMINDER	; method to send to window list
						;	entries
	push	es
	GetResourceSegmentNS	ReminderClass, es
	mov	bx, es				; method is for Reminder objs
	pop	es
	mov	si, offset ReminderClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	pop	si
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, offset CalendarAppClass	; ES:DI => SuperClass
	call	ObjCallSuperNoLock		; send method onto superclass
	add	sp, size GCNListMessageParams

	pop	ax, cx, dx, bp			; restore all the data
done:
if PZ_PCGEOS ; Pizza
	; Save holiday data to file
	;
	push	ax, bx, si
	mov	ax, MSG_JC_SHIC_DESTRUCT
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, si
endif

	mov	di, offset CalendarAppClass	; ES:DI => SuperClass
	call	ObjCallSuperNoLock		; complete the method

	.leave
	ret
CalendarDetach	endp

InitCode	ends



CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarDateTimeChangeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the General Notification mechanism for the
		GeoPlanner (becuase this object is run by the UI)

CALLED BY:	FlowObject
	
PASS: 		DS:*SI	= CalendarAppClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:
		If the app uses RTCM for date/time notification, then
		GCN List is not used.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not USE_RTCM
CalendarDateTimeChangeNotification	method	dynamic	CalendarAppClass,
					MSG_NOTIFY_DATE_TIME_CHANGE

	; Tell the process that the time has changed
	;
	push	ax				; preserve message
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	call	MemOwner			; process handle => BX	
	mov	ax, MSG_CALENDAR_TIME_CHANGE	; send the method
	mov	di, mask MF_FORCE_QUEUE		; ...via the queue
	call	ObjMessage			; ...to force date/time update

	; as there is no extra data block with MSG_NOTIFY_DATE_TIME_CHANGE,
	; it is safe to call our superclass now to acknowledge receipt of the
	; notification.
	;
	pop	ax
	mov	di, offset CalendarAppClass
	GOTO	ObjCallSuperNoLock
CalendarDateTimeChangeNotification	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the application object that some change has
		occurred on a GCN list.

CALLED BY:	GLOBAL (MSG_META_NOTIFY_WITH_DATA_BLOCK)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance
		CX:DX	= NotificationType
		BP	= Data block handle

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarNotifyWithDataBlock	method dynamic	CalendarAppClass,
						MSG_META_NOTIFY_WITH_DATA_BLOCK

		; See if this is one we are interested in
		;
		tst	bp
		jz	callSuper		; no data, so we're done
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	callSuper
		cmp	dx, GWNT_SELECT_STATE_CHANGE
		jne	callSuper
		
		; Since we are only interest in one case, we are lucky since
		; the value we are looking for is what we need to pass in DL.
		; We don't need to reset DL, not push/pop DX
		;
		CheckHack <GWNT_SELECT_STATE_CHANGE eq VUM_DELAYED_VIA_UI_QUEUE>

		; Alright, we need to do some work
		;
		push	ax, si, es
		mov	bx, bp
		call	MemLock
		mov	es, ax			; NotifySelectStateChange => ES

		; Enable/disable the GeoDex trigger
		;
		mov	ax, MSG_GEN_SET_ENABLED
		tst	es:[NSSC_clipboardableSelection]
		jnz	setStatus		; TRUE, so enable		
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setStatus:
		GetResourceHandleNS     GeoDexTrigger, bx
		mov     si, offset GeoDexTrigger
		mov     di, mask MF_FIXUP_DS
		call	ObjMessage

		; Clean up
		;
		mov	bx, bp
		call	MemUnlock
		pop	ax, si, es

		; Now call our superclass
callSuper:
		mov	di, offset CalendarAppClass
		GOTO	ObjCallSuperNoLock
CalendarNotifyWithDataBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarVisibilityNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that UI elements are becoming visible or
		not visible

CALLED BY:	GLOBAL (MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance
		CX	= VisibilityUIGroups
		DX	= ignored
		BP	= non-zero if group is becoming visible

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarVisibilityNotification	method dynamic	CalendarAppClass,
				MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION

	; Either set or clean the visibility flags
	;
	tst	bp				; opening or closing ??
	jz	closing				; closing, so jump
	or	ds:[di].CAI_visibilityGroups, cx
	mov_tr	ax, cx				; groups to update => AX
	mov	cx, mask VisibilityUIData	; data to look at => CX
	GOTO	UpdateUI			; go do the work
closing:
	not	cx				; clear this group flag
	and	ds:[di].CAI_visibilityGroups, cx	
doneVisibility	label	far
	ret
CalendarVisibilityNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateVisibilityData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub to call to send message to GenApplication object

CALLED BY:	GLOBAL

PASS:		CX, DX	= Data
		BP	= VisibilityUIData

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateVisibilityData	proc	far
	GetResourceHandleNS	Calendar, bx
	mov	si, offset Calendar		; Application OD => BX:SI
	mov	ax, MSG_CALENDAR_APP_SET_VISIBILITY_DATA
	clr	di
	GOTO	ObjMessage			; send the message
UpdateVisibilityData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSetVisibilityData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set some state for the current document

CALLED BY:	GLOBAL (MSG_CALENDAR_SET_VISIBILITY_DATA)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance
		CX, DX	= Data
		BP	= VisibilityUIData

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSetVisibilityData	method dynamic	CalendarAppClass,
				MSG_CALENDAR_APP_SET_VISIBILITY_DATA

	; Check document state change
	;
	test	bp, mask VUID_DOCUMENT_STATE
	jz	checkRepeatEvents
	cmp	cx, ds:[di].CAI_documentState
	je	doneVisibility			; if the same, do nothing
	mov	ds:[di].CAI_documentState, cx	; else store new "state"
EC <	jmp	update				; ...and update		>

	; Check repeat event change (no data, so always update)
checkRepeatEvents:
EC <	test	bp, mask VUID_REPEAT_EVENTS				>
EC <	ERROR_Z	CALENDAR_APP_ILLEGAL_NOTIFY_UI_DATA_TYPE_PASSED		>

	; Now update the UI
EC <update:								>
	mov	ax, ds:[di].CAI_visibilityGroups ; VisibleNotifyGroups => AX
	mov	cx, bp				 ; VisibleNotifyData => CX
	FALL_THRU	UpdateUI
CalendarSetVisibilityData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI, based upon the current visibility & data

CALLED BY:	CalendarVisibilityNotification, CalendarSetVisibilityData

PASS:		AX	= VisibilityUIGroups
		CX	= VisibilityUIData

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateUI	proc	far
groups		local	VisibilityUIGroups \
		push	ax
data		local	VisibilityUIData \
		push	cx
	.enter

	; Check for the repeat data
	;
	test	ss:[groups], mask VUIG_REPEAT_DIALOG_BOX
	jz	doneRepeat
	test	ss:[data], mask VUID_REPEAT_EVENTS
	jz	doneRepeat	

	; Update the repeat data
	;
	push	di
	GetResourceHandleNS	RepeatDynamicList, bx
	mov	si, offset RepeatDynamicList
	GetResourceSegmentNS	dgroup, ds	; DGroup => DS
	call	RepeatGetNumEvents		; # of entries in list => CX
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessage_common_forceQueue
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	clr	cx				; don't send modified bit
	call	ObjMessage_common_forceQueue
	pop	di
doneRepeat:

	; Check for the print dialog box
	;
	test	ss:[groups], mask VUIG_PRINT_DIALOG_BOX
	jz	donePrint
	test	ss:[data], mask VUID_DOCUMENT_STATE
	jz	donePrint

	; Disable/enable the event printing capabilities
	;
	push	di
	GetResourceHandleNS	PrintBlock, bx
	mov	ax, MSG_MY_PRINT_UPDATE_DISPLAY_DATA
	mov	si, offset PrintBlock:CalendarPrintOptions
	call	ObjMessage_common_send
	pop	di
	mov	si, offset PrintBlock:IncludeEventsList
	call	UpdateSetToDocState		; enable/disable trigger
	mov	si, offset PrintBlock:EventsEntry
	call	UpdateSetToDocState		; enable/disable choice
	cmp	ax, MSG_GEN_SET_NOT_ENABLED
	jne	donePrint			; if enabling, do nothing

	; Need to move the exclusive off of the Event Printing if
	; there is no valid file open & if it has the current excl.
	;
	push	di
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset PrintBlock:PrintOutputType
	call	ObjMessage_common_call		; get the exlcusive
	cmp	ax, MPOT_EVENTS
	jne	donePrintRestore		; if not TEXT_DAY, we're OK
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, MPOT_GR_MONTH
	clr	dx
	call	ObjMessage_common_send		; reset the value
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessage_common_send
donePrintRestore:
	pop	di
donePrint:

	; Check for the edit->new trigger openining
	;
;;;	test	ss:[groups], mask VUIG_EDIT_MENU
;;;	jz	doneEdit
;;;	test	ss:[data], mask VUID_DOCUMENT_STATE
;;;	jz	doneEdit
;;;doneEdit:
	.leave
	ret
UpdateUI	endp

UpdateSetToDocState	proc	near
	mov	ax, ds:[di].CAI_documentState	; MSG_GEN_SET_[NOT_]ENABLED=>AX
	mov	dl, VUM_NOW			; data to pass along
	push	di
	call	ObjMessage_common_send
	pop	di
	ret
UpdateSetToDocState	endp	

CommonCode	ends



InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load GeoPlanner options

CALLED BY:	GLOBAL (MSG_META_LOAD_OPTIONS)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

settingsTable	CalendarFeatures \
		INTRODUCTORY_FEATURES,
		BEGINNING_FEATURES,
		INTERMEDIATE_FEATURES,
		INTERMEDIATE_FEATURES

featuresKey	char	"features", 0

CalendarLoadOptions	method dynamic	CalendarAppClass, MSG_META_LOAD_OPTIONS,
							  MSG_META_RESET_OPTIONS
		.enter

		; First call the superclass
		;
		mov	di, offset CalendarAppClass
		call	ObjCallSuperNoLock

		; if no features settings are stored then use
		; defaults based on the system's user level

		sub	sp, INI_CATEGORY_BUFFER_SIZE
		movdw	cxdx, sssp

		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock
		mov	ax, sp
		push	si, ds
		segmov	ds, ss
		mov_tr	si, ax
		mov	cx, cs
		mov	dx, offset featuresKey
		call	InitFileReadInteger
		pop	si, ds
		mov	bp, sp
		lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]
		jnc	done

		; Grab the launch level, and calculate default features
		;
		call	UserGetDefaultLaunchLevel
		shl	ax, 1			; offset into settingsTable
		mov_tr	di, ax			; user level offset => AX
		push	cs:[settingsTable][di]

		; Now grab the current user-level selection
		;
		GetResourceHandleNS	UserLevelList, bx
		mov	si, offset UserLevelList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_init_call	; current selection => AX
		pop	cx			; new selection => CX
		cmp	ax, cx
		jz	done

		; Reset the user-level selection
		;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; determinate selection
		call	ObjMessage_init_send		
		mov	cx, 1			; mark modified
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		call	ObjMessage_init_send
		mov	ax, MSG_GEN_APPLY
		call	ObjMessage_init_send
done:
		.leave
		ret
CalendarLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarUpdateAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update GeoPlanner's feature set

CALLED BY:	GLOBAL (MSG_GEN_APPLICATION_UPDATE_APP_FEATURES)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance
		SS:BP	= GenUpdateAppFeaturesParams

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; This table has an entry corresponding to each feature bit.  The entry is a
; point to the list of objects to turn on/off.
;
if PZ_PCGEOS ; Pizza
usabilityTable	fptr	\
		selectionList,		; CF_SELECTION
		pageSetupList,    	; CF_PAGE_SETUP
		alarmsList,	    	; CF_ALARMS
		viewBothList,    	; CF_VIEW_BOTH
		viewDataList,    	; CF_VIEW_DATA
		preferencesList,    	; CF_PREFERENCES
		quickPreviousList,	; CF_QUICK_PREVIOUS
		repeatEventsList,    	; CF_REPEAT_EVENTS
		setHolidayList,    	; CF_SET_HOLIDAY
		searchList,	    	; CF_DO_SEARCH
		geodexLookupList    	; CF_GEODEX_LOOKUP
else
usabilityTable	fptr	\
		selectionList,		; CF_SELECTION
		pageSetupList,    	; CF_PAGE_SETUP
		alarmsList,	    	; CF_ALARMS
		viewBothList,    	; CF_VIEW_BOTH
		viewDataList,    	; CF_VIEW_DATA
		preferencesList,    	; CF_PREFERENCES
		quickPreviousList,	; CF_QUICK_PREVIOUS
		repeatEventsList,    	; CF_REPEAT_EVENTS
		searchList,	    	; CF_DO_SEARCH
		geodexLookupList    	; CF_GEODEX_LOOKUP
endif

selectionList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple QuickWeekTrigger
	GenAppMakeUsabilityTuple QuickWeekendTrigger
	GenAppMakeUsabilityTuple QuickMonthTrigger
	GenAppMakeUsabilityTuple QuickQuarterTrigger
	GenAppMakeUsabilityTuple QuickYearTrigger, end

pageSetupList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple CalendarPageSetup, end


alarmsList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple EditAlarm
	GenAppMakeUsabilityTuple PrecedeValues, end
	
viewBothList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ViewBothGroup
	GenAppMakeUsabilityTuple ViewModeChoices, end

viewDataList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ViewDataList, end

preferencesList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple PreferencesBox, end

quickPreviousList	label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple QuickSubGroup, end

repeatEventsList	label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RepeatBox, end

if PZ_PCGEOS ; Pizza
setHolidayList	label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple SetHoliday, end
endif

searchList		label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple CalendarSearch, end

geodexLookupList	label	 GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GeoDexTrigger, end

; This table has an entry corresponding to each level (intro, beginning, etc.)
;
levelTable 		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple CalendarDocumentControl, recalc, end

if PZ_PCGEOS ; Pizza
UTILITIES_MENU_ITEMS	equ mask CF_REPEAT_EVENTS or \
			    mask CF_SET_HOLIDAY or \
			    mask CF_GEODEX_LOOKUP
else
UTILITIES_MENU_ITEMS	equ mask CF_REPEAT_EVENTS or \
			    mask CF_GEODEX_LOOKUP
endif

CalendarUpdateAppFeatures	method dynamic	CalendarAppClass,
				MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
		.enter

		; Call general routine to update usability
		;
		mov	ss:[bp].GAUFP_table.segment, cs
		mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
		mov	ss:[bp].GAUFP_tableLength, length usabilityTable
		mov	ss:[bp].GAUFP_levelTable.segment, cs
		mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable
		mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
		call	ObjCallInstanceNoLock

		; See if there are any other updates we need to perform
		;
		mov	ax, es:[features]
		mov	bx, ss:[bp].GAUFP_featuresChanged

		; Check out the selection feature
		;
		test	bx, mask CF_SELECTION
		jz	alarms
		test	ax, mask CF_SELECTION
		jnz	alarms

		; Reset the selection to today, so that only one day
		; will be selected.
		;
		push	ax, bx
		mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
		clr	cl
		GetResourceHandleNS	QuickDayTrigger, bx
		mov	si, offset QuickDayTrigger
		call	ObjMessage_init_send
		pop	ax, bx

		; Check out the alarms features
alarms:
		test	bx, mask CF_ALARMS
		jz	viewBoth

		; The alarm state changed, so re-draw the EventWindow
		;
		push	ax, bx
		mov	ax, MSG_VIS_INVALIDATE
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		call	ObjMessage_init_send
		pop	ax, bx

		; Check out the View->Both features
viewBoth:
		test	bx, mask CF_VIEW_BOTH
		jz	viewData

		; Set/Clear the "Both" selection, based on what it is now
		;
		push	ax, bx
		clr	cx, dx			; assume it was cleared
		test	ax, mask CF_VIEW_BOTH
		jz	setViewBothState
		mov	cx, mask VI_BOTH
setViewBothState:
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		GetResourceHandleNS	ViewBothList, bx
		mov	si, offset ViewBothList
		call	ObjMessage_init_send
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
		mov	cx, mask VI_BOTH
		call	ObjMessage_init_send
		mov	ax, MSG_GEN_APPLY
		call	ObjMessage_init_send

		; Some change has occurred, so reset geometry
		;
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		GetResourceHandleNS	PlannerPrimary, bx
		mov	si, offset PlannerPrimary
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_init_send
		pop	ax, bx

		; Check out the View->Data features
viewData:
		test	bx, mask CF_VIEW_DATA
		jz	utilities
		test	ax, mask CF_VIEW_DATA
		jnz	utilities

		; The year view choice was removed, so set it to month
		;
		push	ax, bx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		GetResourceHandleNS	ViewDataList, bx
		mov	si, offset ViewDataList
		mov	cx, YI_ONE_MONTH_SIZE
		clr	dx
		call	ObjMessage_init_send
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		mov	cx, 1
		call	ObjMessage_init_send
		mov	ax, MSG_GEN_APPLY
		call	ObjMessage_init_send
		pop	ax, bx

		; Check out the utilities menu
utilities:
		test	bx, UTILITIES_MENU_ITEMS
		jz	done

		; Need to make the utilties menu appear/disappear
		;
		test	ax, UTILITIES_MENU_ITEMS
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jz	setUtilitiesStatus
		mov	ax, MSG_GEN_SET_USABLE
setUtilitiesStatus:
		GetResourceHandleNS	UtilitiesMenu, bx
		mov	si, offset UtilitiesMenu
		mov	dl, VUM_NOW
		call	ObjMessage_init_send
done:
		.leave
		ret
CalendarUpdateAppFeatures	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSetUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level (features) for GeoPlanner

CALLED BY:	GLOBAL (MSG_CALENDAR_APP_SET_USER_LEVEL)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance
		CX	= CalendarFeatures

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSetUserLevel	method dynamic	CalendarAppClass,
					MSG_CALENDAR_APP_SET_USER_LEVEL
		.enter
		
		; See which UI level this best corresponds to
		;
		mov_tr	ax, cx			; CalendarFeatures => AX
		mov	es:[features], ax	; store these away
		clr	di
		mov	cx, (length settingsTable - 1)
		mov	dx, UIIL_INTRODUCTORY or (UIIL_INTRODUCTORY shl 8)
		mov	bp, 16			; bp <- nearest so far (# bits)
findLoop:
		cmp	ax, cs:settingsTable[di]
		je	found

		; See how closely the features match what we're looking for
		;
		push	ax, cx
		mov	bx, ax
		xor	bx, cs:settingsTable[di]
		clr	ax			;no bits on
		mov	cx, 16
countBits:
		ror	bx, 1
		adc	ax, 0			; update bit count
		loop	countBits
		cmp	ax, bp			; fewer differences?
		ja	nextEntry		; branch if not fewer difference

		; In the event we don't find a match, use the closest
		;
		mov_tr	bp, ax			; bp <- nearest so far (# bits)
		mov	dh, dl			; dh <- nearest so far (level)
nextEntry:
		pop	ax, cx
		inc	dl			; dl <- next UIInterfaceLevel
		add	di, (size CalendarFeatures)
		loop	findLoop
		mov	dl, dh			; dl <- nearest level

		; Set the app features and level
found:
		clr	dh			; UIInterfaceLevel => DX
		push	dx
		mov	cx, ax			; CalendarFeatures => CX
		mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
		call	ObjCallInstanceNoLock
		pop	cx			; UIInterfaceLevel => CX
		mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
		call	ObjCallInstanceNoLock

		; now tell the application to save the options
		;
		mov	di, ds:[si]
		add	di, ds:[di].GenApplication_offset
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	done
ifdef PRODUCT_NDO2000
		mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
		call	ObjCallInstanceNoLock
else
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock
endif
done:
		.leave
		ret
CalendarSetUserLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarFineTuneInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Fine Tune dialog box, and display it

CALLED BY:	GLOBAL (MSG_CALENDAR_APP_FINE_TUNE_INIT)

PASS:		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarFineTuneInit	method dynamic	CalendarAppClass,
					MSG_CALENDAR_APP_FINE_TUNE_INIT
		.enter

		; Get the features bit. Look here to avoid resetting
		; the features if the user chooses to re-display the
		; Fine Tune dialog box w/o first applying their changes
		;
		GetResourceHandleNS	UserLevelList, bx
		mov	si, offset UserLevelList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_init_call	
		mov_tr	cx, ax			; CalendarFeatures => AX

		; Set the feature to be displayed
		;
		clr	dx
		GetResourceHandleNS	FeaturesList, bx
		mov	si, offset FeaturesList
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		call	ObjMessage_init_send

		; Now display the dialog box
		;
		GetResourceHandleNS	FineTuneDialog, bx
		mov	si, offset FineTuneDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_init_send

		.leave
		ret
CalendarFineTuneInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fine tune the calendar feature set

CALLED BY:	GLOBAL (MSG_CALENDAR_APP_FINE_TUNE)

PASS:		ES	= DGroup
		*DS:SI	= CalendarAppClass object
		DS:DI	= CalendarAppClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarFineTune	method dynamic	CalendarAppClass,
					MSG_CALENDAR_APP_FINE_TUNE
		.enter

		; Get the new fine tune settings
		;
		GetResourceHandleNS	FeaturesList, bx
		mov	si, offset FeaturesList
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage_init_call	; CalendarFeatures => AX

		; set new settings
		;
		mov_tr	cx, ax
		GetResourceHandleNS	UserLevelList, bx
		mov	si, offset UserLevelList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage_init_send
		mov	cx, 1			; mark modified
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		call	ObjMessage_init_send

		; now tell the application to save the options
		;
		mov	si, offset Calendar
		mov	di, ds:[si]
		add	di, ds:[di].GenApplication_offset
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	done
ifdef PRODUCT_NDO2000
		mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
		call	ObjCallInstanceNoLock
else
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjCallInstanceNoLock
endif
done:
		.leave
		ret
CalendarFineTune	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CalendarAppChangeUserLevel --
		MSG_CALENDAR_APP_CHANGE_USER_LEVEL
						for CalendarAppClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of CalendarAppClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
CalendarAppChangeUserLevel	method dynamic	CalendarAppClass,
					MSG_CALENDAR_APP_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	clr	di
	call	ObjMessage
	pop	si


	ret

CalendarAppChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CalendarAppCancelUserLevel --
		MSG_CALENDAR_APP_CANCEL_USER_LEVEL
						for CalendarAppClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of CalendarAppClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
CalendarAppCancelUserLevel	method dynamic	CalendarAppClass,
					MSG_CALENDAR_APP_CANCEL_USER_LEVEL

	mov	cx, ds:[di].GAI_appFeatures

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	clr	di
	call	ObjMessage

	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	clr	di
	call	ObjMessage

	ret

CalendarAppCancelUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CalendarAppQueryResetOptions --
		MSG_CALENDAR_APP_QUERY_RESET_OPTIONS
						for CalendarAppClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of CalendarAppClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
CalendarAppQueryResetOptions	method dynamic	CalendarAppClass,
				MSG_CALENDAR_APP_QUERY_RESET_OPTIONS

	; ask the user if she wants to reset the options

	push	ds:[LMBH_handle]
	clr	ax
	pushdw	axax				;SDOP_helpContext
	pushdw	axax				;SDOP_customTriggers
	pushdw	axax				;SDOP_stringArg2
	pushdw	axax				;SDOP_stringArg1
	GetResourceHandleNS	ResetOptionsQueryString, bx
	mov	ax, offset ResetOptionsQueryString
	pushdw	bxax
	mov	ax, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION, 0>
	push	ax
	call	UserStandardDialogOptr
	pop	bx
	call	MemDerefDS
	cmp	ax, IC_YES
	jnz	done

	mov	ax, MSG_META_RESET_OPTIONS
	call	ObjCallInstanceNoLock
done:
	ret

CalendarAppQueryResetOptions	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	CalendarAppUserLevelStatus --
		MSG_CALENDAR_APP_USER_LEVEL_STATUS
						for CalendarAppClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of CalendarAppClass

	ax - The message

	cx - current selection

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
if 0
CalendarAppUserLevelStatus	method dynamic	CalendarAppClass,
				MSG_CALENDAR_APP_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, INTERMEDIATE_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	clr	di
	GOTO	ObjMessage

CalendarAppUserLevelStatus	endm
endif

InitCode	ends
