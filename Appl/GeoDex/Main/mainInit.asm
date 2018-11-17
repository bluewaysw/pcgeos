COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Main		
FILE:		mainInit.asm

AUTHOR:		Ted H. Kim, March 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	RolodexOpenApp		Does initial work for launching an application 
	AddToTextSelectGCNList	Add GeoDex to text select state change GCNList
	ReadInViewMode		Read in view mode setting from .INI file
	RolodexApplicationAttach Deal with user level stuff
	RolodexApplicationLoadOptions
				Read in user level settings from .INI file
	RolodexApplicationUpdateAppFeatures
				Update feature states
	RolodexApplicationSetUserLevel
				Set the new user level
	SetViewMode		Set the current view mode to card view
	RolodexApplicationInitiateFineTune
				Bring up the fine tune DB
	RolodexApplicationFineTune
				Set the fine tune settings
	RolodexApplicationResetOptions
				Reset the options menu
	CreateDataBlock		Create a data block to be sent to GCN list
	SendDataBlockToGCNList	Send the data block to GCN list
	RolodexInstallToken	Install tokens
	RolodexRestoreState	Restores variables saved with state file
	ReadInNumOfCharSet	Read in number of character sets in use
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains various routines called when GeoDex is starting.	

	$Id: mainInit.asm,v 1.1 97/04/04 15:50:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexOpenApp 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a lot of initial work for launching an application

CALLED BY:	UI (MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		bp - handle of extra state block, or 0 if none 
		cx - AppAttachFlags
                dx - Handle of AppLaunchBlock, or 0 if none.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/10/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexOpenApp	method	GeoDexClass, MSG_GEN_PROCESS_OPEN_APPLICATION 
	push	ax, cx, dx, bp, si
	mov	ds:[ignoreInput], TRUE		; ignore all input 
ifdef GPC
	mov	ds:[openApp], TRUE		; for initial focus handling
endif

	; get what video mode the system is running

	GetResourceHandleNS     RolodexApp, bx
	mov	si, offset RolodexApp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ah - DisplayType

	; check to see if we are using color video drivers

	push	ax
	and	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1			; B&W monitor?
	mov	ds:[colorFlag], FALSE		; assume B&W
	je	bw				; jump if B&W
	mov	ds:[colorFlag], TRUE		; set the color flag
bw:
	pop	ax

	; now check to see if we are using CGA 

ifdef GPC
	mov	al, ah				; save DisplayType for later
endif
	and	ah, mask DT_DISP_ASPECT_RATIO	; clear high 2 and low 4 bits
	cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	mov	ds:[cga], FALSE			; assume not CGA
	jne	notCGA				; jump if not CGA
	mov	ds:[cga], TRUE			; set CGA flag
notCGA:
ifdef GPC
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	mov	ds:[tvFlag], FALSE		; assume not TV
	jne	notTV				; jump if not CGA
	mov	ds:[tvFlag], TRUE		; set TV flag
notTV:
	and	al, mask DT_DISP_SIZE
	shr	al, offset DT_DISP_SIZE
	mov	ds:[displaySize], al		; store DisplaySize
endif
	pop	ax, cx, dx, bp, si
	call	ReadInViewMode		; read in view mode option from .ini

	; call super class

	mov	di, offset GeoDexClass
	call	ObjCallSuperNoLock	

	; send notification data block to Map Controller

	call    CreateDataBlock		; create the data block 
	mov	ax, 1
	call	MemInitRefCount		; initialize the reference count to one
	call	SendDataBlockToGCNList	; send the data block 

	; get the process handle and save it away

	call    GeodeGetProcessHandle   
	mov	ds:[processID], bx	

	; add GeoDex to clipboard notification list

	mov	cx, bx			; cx - process handle
	clr	dx			; cx:dx - OD to add
	call	ClipboardAddToNotificationList

	; initialize other stuff

	call	InitComUse		; initialize serial port 
	call	ReadInNumOfCharSet	; read in number of character sets
	call	AddToTextSelectGCNList	; add GeoDex to text select GCNList
ifdef GPC
	; set focus to New button, if available
	cmp	ds:[displayStatus], BROWSE_VIEW
	je	done
	GetResourceHandleNS	NewTrigger, bx
	mov	si, offset NewTrigger
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di
	call	ObjMessage
done:
endif
	ret
RolodexOpenApp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToTextSelectGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add GeoDex to text select state change GCNList so that
		whenever new text gets selected or deselected, GeoDex
		gets a message.

CALLED BY:	(INTERNAL) RolodexOpenApp

PASS:		nothing		

RETURN:		GeoDex added to GCNList

DESTROYED:	ax, bx, dx, bp, si

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToTextSelectGCNList	proc	near

	; Setup GCNListParams

	mov	bx, ds:[processID] 		; bx - process handle
	mov	dx, size GCNListParams		; dx - size of stack frame
	sub	sp, dx
	mov	bp, sp				; GCNListParams => SS:BP
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, \
			GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	mov	ss:[bp].GCNLP_optr.handle, bx	; bx:si - send it to process
	mov	ss:[bp].GCNLP_optr.chunk, 0	

	; get AppObject of current process 

	clr	bx
	call    GeodeGetAppObject		; returns OD in bx:si
	mov	ax, MSG_META_GCN_LIST_ADD	; add GeoDex to GCNList
	mov	di, mask MF_STACK
	call	ObjMessage			; send it!!
	add	sp, dx				; clean up the stack
	ret
AddToTextSelectGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInViewMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in initial view mode from GEOS.INI file.

CALLED BY:	RolodexOpenApp

PASS:		nothing

RETURN:		displayStatus - updated

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadInViewMode		proc	near 	uses  ax, bx, cx, dx, si, di, bp, ds
	.enter

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp		; cx:dx - buffer for .ini category

	mov	ax, MSG_META_GET_INI_CATEGORY
	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp	; bx:si - Application Object 
	mov	di, mask MF_CALL
	call	ObjMessage		; copy category string into the buffer
	mov	ax, sp
	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax			; ds:si - category string
	mov	cx, cs
	mov	dx, offset featuresKey	; cx:dx - key string
	call	InitFileReadInteger	; ax - value 
	pop	si, ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]	; restore sp
	jc	readView		; if value not found, skip 

	; check to see if the view menu feature is enabled

	test	ax, mask GF_VIEW_MENU 
	je	exit			; if not, just exit
readView:
	; read in the view mode from .ini file

	mov	ds:[displayStatus], CARD_VIEW	; assume card view
	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp		; cx:dx - buffer for .ini category

	mov	ax, MSG_META_GET_INI_CATEGORY
	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp	; bx:si - Application object
	mov	di, mask MF_CALL
	call	ObjMessage		; read category string into the buffer
	mov	ax, sp
	push	ds
	segmov	ds, ss
	mov_tr	si, ax			; ds:si - category string
	mov	cx, cs
	mov	dx, offset viewString	; cx:dx - key string
	call	InitFileReadInteger	; ax - value
	pop	ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]	; restore sp
	jc	exit			; if no value, exit

	cmp	ax, CARD_VIEW		; if card view,
	je	exit			; then exit

	push	ax			; save view enum value
	cmp	ax, BOTH_VIEW		; both view?
	jne	doBrowse		; if not, must be browse view

	call	RolodexBoth		; come up in both view
	jmp	common
doBrowse:
	; call RolodexBrowse passing a flag in AX indicating
	; that it is being called from ReadInViewMode

	mov	ax, -1				
	call	RolodexBrowse		; come up in browse mode
common:
	pop	ax 			; ax - view mode enum
	mov	ds:[displayStatus], al	; update the variable
exit:
	.leave
	ret
ReadInViewMode		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationAttach
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with starting Rolodex app	

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si - instance data
		es - segment of RolodexApplicationClass
		ax - The message
		cx - AppAttachFlags
		dx - Handle of AppLaunchBlock, or 0 if none.
		bp - Handle of extra state block, or 0 if none.

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexApplicationAttach	method dynamic	RolodexApplicationClass, 
						MSG_META_ATTACH
	push	ax, cx, dx, si, bp

ifdef GPC
	;
	; and also change the .ini file category based on interfaceLevel.
	; address book0
	; 0123456789111
	;           012
	;
	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	call	ObjVarFindData
	jnc	gotCat
	call	UserGetDefaultUILevel		;ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	je	gotCat
	mov	{char}ds:[bx+12], C_NULL	;null-term AUI category
gotCat:
	;
	; center CUI version
	;
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	noCenter
	GetResourceHandleNS	RolodexPrimary, bx
	mov	si, offset RolodexPrimary
	call	ObjSwapLock
	push	bx
	mov	ax, HINT_CENTER_CHILDREN_HORIZONTALLY
	clr	cx
	call	ObjVarAddData
	mov	ax, HINT_CENTER_CHILDREN_VERTICALLY
	clr	cx
	call	ObjVarAddData
	pop	bx
	call	ObjSwapUnlock

	; In CUI, remove File:New/Open and File:Close
	GetResourceHandleNS	RolUIDocControl, bx
	call	ObjSwapLock
	mov	si, offset RolUIDocControl
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	.warn -private
	ornf	ds:[di].GDCI_features, mask GDCF_SINGLE_DOCUMENT
	.warn @private
	call	ObjMarkDirty
	call	ObjSwapUnlock

noCenter:
	;
	; easier not to table drive since we need to support
	; multiple instances (if feature already exists, we just
	; remove the feature control object, otherwise, we remove
	; the real object)
	;
	mov	bx, offset gpcNonFeaturesKey
	call	GetIniCategory
	jnc	gotGPCFeatures
	mov	ax, 0
gotGPCFeatures:
	push	es
	GetResourceSegmentNS	dgroup, es
	mov	es:[gpcFeatures], al
	pop	es
if not NDO_NEWDEX_SORT_OPTION
	;;; Do not disable the Sort Option feature in NDO2000.   
	test	ax, mask GPCNF_SORT_OPTIONS
	jnz	afterSortOpts
	GetResourceHandleNS	SortFeatureEntry, bx
	mov	si, offset SortFeatureEntry
	call	myMakeObjectNotUsable
afterSortOpts:
endif
if not NDO_NEWDEX_DIAL_OPTION
if _QUICK_DIAL
	test	ax, mask GPCNF_DIAL_OPTIONS
	jnz	afterDialOpts
	GetResourceHandleNS	DialFeatureEntry, bx
	mov	si, offset DialFeatureEntry
	call	myMakeObjectNotUsable
afterDialOpts:
endif
endif
if not NDO_NEWDEX_UTIL_MENU
	test	ax, mask GPCNF_UTIL_MENU
	jnz	afterUtilMenu
	GetResourceHandleNS	UtilsMenuEntry, bx
	mov	si, offset UtilsMenuEntry
	call	myMakeObjectNotUsable
afterUtilMenu:
endif
if not NDO_NEWDEX_COPY_PASTE
	;;; Do not disable the Copy Record feature in NDO2000.   
	test	ax, mask GPCNF_RECORD_COPY_PASTE
	jnz	afterRecordCopyPaste
	GetResourceHandleNS	EditCopyRecord, bx
	mov	si, offset EditCopyRecord
	call	MakeObjectNotUsable
	GetResourceHandleNS	EditPasteRecord, bx
	mov	si, offset EditPasteRecord
	call	MakeObjectNotUsable
afterRecordCopyPaste:
endif
endif

	; set things that are solely dependent on the UI state

	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepOptionsMenu
if _OPTIONS_MENU
	GetResourceHandleNS	OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endif
keepOptionsMenu:

ifdef GPC
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	keepUserLevel
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
keepUserLevel:
endif

	pop	ax, cx, dx, si, bp
	mov	di, offset RolodexApplicationClass
	call	ObjCallSuperNoLock
	ret

ifdef GPC
myMakeObjectNotUsable	label	near
	push	ax
	call	MakeObjectNotUsable
	pop	ax
	retn
endif
RolodexApplicationAttach	endm

ifdef GPC
gpcNonFeaturesKey	char	'extraFeatures',0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load in the features settings from .INI file.	

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si - instance data
		es - segment of GeoDexClass
		ax - the message

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SettingTableEntry	struct
    STE_features	GeoDexFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_FEATURES>,
 <BEGINNING_FEATURES>,
 <INTERMEDIATE_FEATURES>,
 <INTERMEDIATE_FEATURES>

featuresKey	char	"features", 0
viewString	char	"view", 0
dial1String	char	"dial1", 0
dial2String	char	"dial2", 0

RolodexApplicationLoadOptions	method dynamic	RolodexApplicationClass, 
						MSG_META_LOAD_OPTIONS,
						MSG_META_RESET_OPTIONS
	mov	di, offset RolodexApplicationClass
	call	ObjCallSuperNoLock

	; if no features settings are stored then use
	; defaults based on the system's user level

	mov	bx, offset featuresKey
	call	GetIniCategory
	jnc	checkView

	; no .ini file settings -- set objects correctly based on level

	call	UserGetDefaultLaunchLevel	;ax = UserLevel (0-3)
	mov	bl, size SettingTableEntry
	mul	bl
	mov_tr	di, ax				;calculate array offset

	push	si
	push	cs:[settingsTable][di].STE_features	;save default settings

	; get the currently selected features

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	pop	cx

	; are they equal to the default settings?

	cmp	ax, cx
	jz	restoreSI0			; if so, skip

	; if not equal, then we must change the feature settings

	push	cx

	; first, change the settings in GenItemGroup

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; mark the object modified

	mov	cx, 1					
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; now apply the state change

	mov	ax, MSG_GEN_APPLY
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage
	pop	ax				; feature settings
restoreSI0:
	pop	si
checkView:
	mov	es:[appFeatures], ax		;save the features bits

	; get the value of 'view' field from .ini file 

	mov	bx, offset viewString
	call	GetIniCategory
	jnc	checkDial1			; if field exits, skip 

	; no .ini setting for 'view' field - use default setting
if _OPTIONS_MENU_VIEW
	push	si

	; get the current setting of start up view list

	GetResourceHandleNS	StartUpViewList, bx
	mov	si, offset StartUpViewList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage

	cmp	ax, CARD_VIEW		; is it equal to the default setting?
	jz	restoreSI2		; if so, skip

	; if not equal, change it to the default setting

	mov	cx, CARD_VIEW
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; mark the object modified 

	mov	cx, 1					
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; apply the state change

	mov	ax, MSG_GEN_APPLY
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage
restoreSI2:
	pop	si

endif 	;if _OPTIONS_MENU_VIEW

checkDial1:
	; get the value of 'dial1' field from .ini file 

	mov	bx, offset dial1String
	call	GetIniCategory
	jnc	checkDial2			; if field exits, skip

	; no .ini setting for 'dial1' field - use default setting

	push	si

	; get the current setting of phone list option

	GetResourceHandleNS	PhoneListOption, bx
	mov	si, offset PhoneListOption
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage

	tst	ax			; is it equal to the default setting?
	jnz	restoreSI3		; if so, skip

	; if not equal, change it to the default setting

	mov	cx, 1
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; mark the object not modified so as not to enable 
	; or disable the apply trigger

	clr	cx					
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage
restoreSI3:
	pop	si
checkDial2:
	; get the value of 'dial2' field from .ini file 

	mov	bx, offset dial2String
	call	GetIniCategory
	jnc	done			; if field exists, skip

	; no .ini setting for 'dial2' field - use default setting
	; get the current setting of dial options

	GetResourceHandleNS	DialingOptions, bx
	mov	si, offset DialingOptions
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage

	cmp	ax, mask DOF_CONFIRM 	; are they equal to default settings?
	jz	done			; if so, exit

	; if not equal, change them to the default settings

	mov	cx, mask DOF_CONFIRM
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	; mark the object not modified so as not to enable 
	; or disable the apply trigger

	clr	cx
	mov	dx, mask DOF_RESET or mask DOF_CONFIRM
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage
done:
	ret
RolodexApplicationLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIniCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the integer value of geodex key field from
		the .ini file.

CALLED BY:	UTILITY	

PASS:		*ds:si - instance data
		bx - offset to the key string

RETURN:		carry clear if successful
			ax - value
		else carry set
			ax - unchanged

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	1/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIniCategory	proc	near	uses	si
	.enter

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp		; cx:dx - buffer for .ini category 
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock	; read in category string into the buf.
	mov	ax, sp
	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax			; ds:si - category string
	mov	cx, cs
	mov	dx, bx			; cx:dx - key string
	call	InitFileReadInteger	; ax - value
	pop	si, ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]	; restore sp

	.leave
	ret
GetIniCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationUpdateAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates feature states

CALLED BY:	MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

PASS:		*ds:si - instance data
		es - segment of RolodexApplicationClass
		ax - the message
		ss:bp - GenAppUpdateFeaturesParams

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK			Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; This table has an entry corresponding to each feature bit.  The entry is a
; point to the list of objects to turn on/off

usabilityTable	fptr	\
	notesFeatureList,	;GF_NOTES_FEATURE
	geoPlannerList,		;GF_GEOPLANNER
	utilMenuList,		;GF_UTILS_MENU
	viewMenuList,		;GF_VIEW_MENU
	searchFeatureList,	;GF_SEARCH_FEATURES
if _QUICK_DIAL
	sortFeatureList,		;GF_SORT_OPTION
	dialFeatureList		;GF_DIAL_OPTION
else
	sortFeatureList		;GF_SORT_OPTION
endif

notesFeatureList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple PrintNotes
	GenAppMakeUsabilityTuple NotesTrigger, end

geoPlannerList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple CalendarTrigger, end

utilMenuList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple UtilMenu, end

if _OPTIONS_MENU_VIEW
viewMenuList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowMenu 
	GenAppMakeUsabilityTuple StartUpViewOption, end
else
viewMenuList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowMenu, end
endif	;if _OPTIONS_MENU_VIEW

searchFeatureList	label	GenAppUsabilityTuple
ifdef GPC
	GenAppMakeUsabilityTuple SearchPrompt, reversed
endif
	GenAppMakeUsabilityTuple SearchOptionList, end

sortFeatureList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple SortOptions, end

if _QUICK_DIAL
dialFeatureList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple PhoneOptions, end
endif

levelTable		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RolUIDocControl, recalc
        GenAppMakeUsabilityTuple RolodexSearchControl, recalc, end

RolodexApplicationUpdateAppFeatures	method dynamic	RolodexApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
	; call general routine to update usability

	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov     ss:[bp].GAUFP_levelTable.segment, cs
	mov     ss:[bp].GAUFP_levelTable.offset, offset levelTable
	mov     ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock
	ret
RolodexApplicationUpdateAppFeatures	endm

ifdef GPC
RolodexApplicationSetAppFeatures	method	dynamic	RolodexApplicationClass,
					MSG_GEN_APPLICATION_SET_APP_FEATURES
	
	push	ds
	GetResourceSegmentNS	dgroup, es
	test	es:[gpcFeatures], mask GPCNF_UTIL_MENU
	jnz	leaveUtil
	andnf	cx, not mask GF_UTILS_MENU
leaveUtil:
	test	es:[gpcFeatures], mask GPCNF_SORT_OPTIONS
	jnz	leaveSort
	andnf	cx, not mask GF_SORT_OPTION
leaveSort:
	test	es:[gpcFeatures], mask GPCNF_DIAL_OPTIONS
	jnz	leaveDial
	andnf	cx, not mask GF_DIAL_OPTION
leaveDial:
	pop	ds
	mov	di, offset RolodexApplicationClass
	call	ObjCallSuperNoLock
	ret
RolodexApplicationSetAppFeatures	endm

;
; ignore when attaching
;
if not _NDO1998
RolodexApplicationOptionsChanged	method	dynamic RolodexApplicationClass,
					MSG_ROLODEX_OPTIONS_CHANGED
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	GOTO	ObjCallInstanceNoLock
done:
	ret
RolodexApplicationOptionsChanged	endm
endif

;
; in case we are used before app obj gets META_ATTACH
;
RolodexApplicationGetIniCat	method	dynamic RolodexApplicationClass,
					MSG_META_GET_INI_CATEGORY
	mov	di, offset RolodexApplicationClass
	call	ObjCallSuperNoLock
	jnc	exit			; not found
	push	cx, dx
	movdw	esdi, cxdx
	cmp	{char}es:[di], C_NULL
	je	done
	mov	cx, -1
	clr	ax
	repne scasb			; es:di points past null
	cmp	{char}es:[di-2], '0'	; CUI name?
	jne	done			; nope, don't care
	call	UserGetDefaultUILevel	; ax = UIIL
	cmp	ax, UIIL_INTRODUCTORY
	je	done			; CUI, leave it
	mov	{char}es:[di-2], C_NULL	; else, make AUI name
done:
	pop	cx, dx
	stc				; indicate found
exit:
	ret
RolodexApplicationGetIniCat	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationSetUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level.

CALLED BY:	MSG_ROLODEX_APPLICATION_SET_USER_LEVEL

PASS:		*ds:si - instance data
		es - segment of RolodexApplicationClass
		ax - the message
		cx - user level (as feature bits)

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	NOTE: the user level set here is expressed in terms of feature bits

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexApplicationSetUserLevel	method dynamic	RolodexApplicationClass,
					MSG_ROLODEX_APPLICATION_SET_USER_LEVEL
	mov	es:[appFeatures], cx		;save the features bits
	mov	ax, cx				;ax <- new features
	;
	; find the corresponding bar states and level
	;
	push	si
	clr	di, bp
	mov	cx, (length settingsTable)	;cx <- # entries
	mov	dl, UIIL_INTRODUCTORY		;dl <- UIInterfaceLevel
	mov	dh, dl				;dh <- nearest so far (level)
	mov	si, 16				;si <- nearest so far (# bits)
findLoop:
	cmp	ax, cs:settingsTable[di].STE_features
	je	found
	push	ax, cx
	;
	; See how closely the features match what we're looking for
	;
	mov	bx, ax
	xor	bx, cs:settingsTable[di].STE_features
	clr	ax				;no bits on
	mov	cx, 16
countBits:
	ror	bx, 1
	jnc	nextBit				;bit on?
	inc	ax				;ax <- more bit
nextBit:
	loop	countBits

	cmp	ax, si				;fewer differences?

	jae	nextEntry			;branch if not fewer difference
	;
	; In the event we don't find a match, use the closest
	;
	mov	si, ax				;si <- nearest so far (# bits)
	mov	dh, dl				;dh <- nearest so far (level)
	mov	bp, di				;bp <- corresponding entry
nextEntry:
	pop	ax, cx
	inc	dl				;dl <- next UIInterfaceLevel
	add	di, (size SettingTableEntry)
	loop	findLoop
	;
	; No exact match -- set the level to the closest
	;
	mov	dl, dh				;dl <- nearest level
	mov	di, bp				;di <- corresponding entry
	;
	; Set the app features
	;
found:
	pop	si
	clr	dh				;dx <- UIInterfaceLevel
	push	ax
	push	dx
	mov	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	pop	ax
	;
	; if not attaching, save after user level change
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	push	ax
ifdef PRODUCT_NDO2000
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	ObjCallInstanceNoLock
else
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
endif
	pop	ax
done:
	call	SetViewMode
	ret
RolodexApplicationSetUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RolodexApplicationChangeUserLevel --
		MSG_ROLODEX_APPLICATION_CHANGE_USER_LEVEL
						for RolodexApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of RolodexApplicationClass

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
RolodexApplicationChangeUserLevel	method dynamic	RolodexApplicationClass,
					MSG_ROLODEX_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	clr	di
	call	ObjMessage
	pop	si

	ret

RolodexApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RolodexApplicationCancelUserLevel --
		MSG_ROLODEX_APPLICATION_CANCEL_USER_LEVEL
						for RolodexApplicationClass

DESCRIPTION:	Cancel User change to the user level

PASS:
	*ds:si - instance data
	es - segment of RolodexApplicationClass

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
RolodexApplicationCancelUserLevel	method dynamic	RolodexApplicationClass,
					MSG_ROLODEX_APPLICATION_CANCEL_USER_LEVEL

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

RolodexApplicationCancelUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RolodexApplicationQueryResetOptions --
		MSG_ROLODEX_APPLICATION_QUERY_RESET_OPTIONS
						for RolodexApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of RolodexApplicationClass

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
RolodexApplicationQueryResetOptions	method dynamic	RolodexApplicationClass,
				MSG_ROLODEX_APPLICATION_QUERY_RESET_OPTIONS

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

RolodexApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RolodexApplicationUserLevelStatus --
		MSG_ROLODEX_APPLICATION_USER_LEVEL_STATUS
						for RolodexApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of RolodexApplicationClass

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
RolodexApplicationUserLevelStatus	method dynamic	RolodexApplicationClass,
				MSG_ROLODEX_APPLICATION_USER_LEVEL_STATUS

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

RolodexApplicationUserLevelStatus	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetViewMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the view mode to card view.

CALLED BY:	(INTERNAL)

PASS:		ax - feature bits 
		es - segment address of dgroup

RETURN:		nothing

DESTROYED:	bx, cx, dx, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetViewMode	proc	near	uses	ax
	.enter

	test	ax, mask GF_VIEW_MENU	; is view menu enabled?
	jne	exit			; if so, skip
	push	ds
	segmov	ds, es
	mov	cx, CARD_VIEW
ifdef GPC
	;
	; default to both view in CUI
	;
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	haveView
	mov	cx, BOTH_VIEW
haveView:
endif
	call	RolodexChangeView	; change to card view
	pop	ds
exit:
	.leave
	ret
SetViewMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationInitiateFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the fine tune dialog box.

CALLED BY:	MSG_ROLODEX_APPLICATION_INITIATE_FINE_TUNE

PASS:		*ds:si - instance data
		es - segment of RolodexApplicationClass
		ax - the message

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexApplicationInitiateFineTune	method dynamic	RolodexApplicationClass,
				MSG_ROLODEX_APPLICATION_INITIATE_FINE_TUNE

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov     di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov     di, mask MF_FIXUP_DS
	call	ObjMessage
	ret

RolodexApplicationInitiateFineTune	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexApplicationFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the fine tune settings

CALLED BY:	MSG_ROLODEX_APPLICATION_FINE_TUNE

PASS:		*ds:si - instance data
		es - segment of RolodexApplicationClass
		ax - the message

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (message handler)

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexApplicationFineTune	method dynamic	RolodexApplicationClass,
				MSG_ROLODEX_APPLICATION_FINE_TUNE

	; get fine tune settings

	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov_tr	cx, ax				;cx = new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov     di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov     di, mask MF_FIXUP_DS
	call	ObjMessage
	;
	; if not attaching, save after fine tune
	;
	mov	si, offset RolodexApp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
ifdef PRODUCT_NDO2000
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	ObjCallInstanceNoLock
else
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
endif
done:
	ret

RolodexApplicationFineTune	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a data block that will be sent to the GCN list.

CALLED BY:	RolodexOpenApp

PASS:		nothing

RETURN:		bx - handle of data block

DESTROYED:	ax, cx, dx, si, di, es, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateDataBlock	proc	near	uses	ds 
	.enter

	mov	ax, LMEM_TYPE_GENERAL		; ax - LMemType
	mov	cx, size ImpexMapFileInfoHeader	; cx - size of header  
	call	MemAllocLMem			; allocate a data block
	push	bx				; save memory handle
	mov	ah, 0
	mov	al, mask HF_SHARABLE
	call	MemModifyFlags			; mark this block shareable
	call	MemLock				; lock this block
	mov	ds, ax
	clr	bx				; bx - variable element size
	clr	cx				; use default ChunkArrayHeader
	clr	si				; allocate a chunk handle
	clr	al				; no ObjChunkFlags passed
	call	ChunkArrayCreate		; create a chunk array
	clr	di				; ds:di - ptr to LMem header
	mov	ds:[di].IMFIH_fieldChunk, si	; save the chunk handle
	mov	ds:[di].IMFIH_numFields, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS
	mov     ds:[di].IMFIH_flag, DFNU_FIXED	; use pre-defined field names

	GetResourceHandleNS	TextResource, bx	
	call	MemLock				; lock the strings block
	mov	es, ax
	mov	di, offset DexListArray		; *ds:si - DexListArray
	mov	di, es:[di]			; dereference it
	clr	dx				; offset into DexListArray
mainLoop:
	push	es, si, di, dx
	shl	dx, 1
	add	di, dx				; es:di - ptr to offset list
	mov	di, es:[di]			
	mov	di, es:[di]			; es:di - ptr to string

	ChunkSizePtr	es, di, ax		; ax - size of lmem chunk
	mov	cx, ax				; cx - number of bytes to copy

	push	es, di
	call	ChunkArrayAppend		; add a new element
	segmov	es, ds				; es:di - destination
	pop	ds, si				; ds:si - source
	rep	movsb				; copy the string

	segmov	ds, es				; ds - seg addr of chunk array
	pop	es, si, di, dx
	inc	dx
	cmp	dx, GEODEX_NUM_FIELDS+NUM_PHONE_TYPE_FIELDS ; are we done?
	jne	mainLoop			; if not, continue

	call	MemUnlock			; unlock TextResource block

	pop	bx
	call	MemUnlock			; unlock LMem block

	.leave
	ret
CreateDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDataBlockToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends newly created data block to the GCN list.

CALLED BY:	RolodexOpenApp

PASS:		bx - handle of data block to be sent

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDataBlockToGCNList	proc	near

	; Create the classed event

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_MAP_APP_CHANGE		; cx:dx - notificatoin type
	mov	bp, bx
	mov	di, mask MF_RECORD
	call	ObjMessage			; event handle => DI

	; Setup the GCNListMessageParams

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp				; GCNListMessageParams => SS:BP
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, \
			GAGCNLT_APP_TARGET_NOTIFY_APP_CHANGE
	mov	ss:[bp].GCNLMP_block, bx	; bx - handle of data block
	mov	ss:[bp].GCNLMP_event, di	; di - even handle
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_STACK
	call	ObjMessage			; send it!!
	add	sp, dx				; clean up the stack
	ret
SendDataBlockToGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexInstallToken
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
RolodexInstallToken	method GeoDexClass, MSG_GEN_PROCESS_INSTALL_TOKEN
	
	; Call our superclass to get the ball rolling...
	
	mov	di, offset GeoDexClass
	call	ObjCallSuperNoLock

	; install datafile token

	mov	ax, ('a') or ('d' shl 8)	; ax:bx:si = token used for
	mov	bx, ('b') or ('k' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; moniker list is in data
						;  resource, so no relocation
	call	TokenDefineToken		; add icon to token database
done:
	ret

RolodexInstallToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores variables that were saved with state file.

CALLED BY:	UI (MSG_GEN_PROCESS_RESTORE_FROM_STATE)

PASS:		bp - handle of data block that contains saved variables
		es - segment address of core block

RETURN:		nothing

DESTROYED:	ax, bx, cx, es, si, di

PSEUDO CODE/STRATEGY:
	Lock the data block
	Read in data into udata segment of each module
	Free the data block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/10/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexRestoreState	method	GeoDexClass, MSG_GEN_PROCESS_RESTORE_FROM_STATE
        mov     es:[startFromScratch],-1; set the flag

	push	ds, es, bp
	mov	di, offset GeoDexClass
	call	ObjCallSuperNoLock	; call superclass 
	pop	ds, es, bp

	tst	bp			; is there a block saved? 
	je	exit			; if not, skip

	push	es			; save seg addr of map block
	push	ds			; save seg addr of core block
	mov	bx, bp			; bx - handle of memory block 
	call	MemLock			; lock the map block
	clr	si
	segmov	es, ds		
	mov	ds, ax			; ds:si - source data block

	; read in udata for all modules

	mov	di, offset begStateData	; es:di - destination
	mov	cx, endStateData - begStateData ; cx - # of bytes to read
	rep	movsb			; read map block into udata
	pop	ds			; restore seg addr of core block
	pop	es			; restore seg addr of data block
	call	MemUnlock		; unlock state data block
exit:
	ret
RolodexRestoreState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInNumOfCharSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in total number of character sets used for letter tabs.

CALLED BY:	RolodexOpenApp

PASS:		nothing

RETURN:		numCharSet - updated

DESTROYED:	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadInNumOfCharSet	proc	near	uses	ax, bx, dx, si
	.enter

	push	ds
	GetResourceHandleNS	TextResource, bx  
	call	MemLock				; lock the block with char set 
	mov	ds, ax				; set up the segment
	mov	si, offset NumberOfCharSet 
	mov	si, ds:[si]			; dereference the handle
	call	UtilAsciiToHex32
	pop	ds
	mov	ds:[numCharSet], 1		; assume one character set 
	jc	skip				; if illegal numuber, skip
	mov	ds:[numCharSet], ax		; save it
skip:
	call	MemUnlock			; unlock the block

	.leave
	ret
ReadInNumOfCharSet	endp

Init	ends
