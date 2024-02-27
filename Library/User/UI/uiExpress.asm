COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User Library
FILE:		uiExpress.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ExpressMenuControlClass	Express Menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/92		Initial version

DESCRIPTION:
	This file contains routines to implement ExpressMenuControlClass

	$Id$

------------------------------------------------------------------------------@

if _EXPRESS_MENU
;
; Internally used subclass of ProcessClass for launching applications.  This
; can't be done on the global UI thread (which runs most ExpressMenuControls),
; because it needs to use IACP stuff, which blocks during IACPConnect waiting
; for the newly-launched server to register. The server can't register, however,
; until the GenApplication object asks its generic parent, run by the UI thread,
; some questions...
;
EMCThreadClass	class	ProcessClass

MSG_EMC_THREAD_LAUNCH_APPLICATION	message
;
; Launch application with passed info
;
; Pass:		dx = AppLaunchBlock
;			(freed after use)
;		cx = block containing GeodeToken
;			(freed after use)
;

EMCThreadClass	endc
endif		; if _EXPRESS_MENU

;---------------------------------------------------

UserClassStructures	segment resource

	ExpressMenuControlClass		;declare the class record

	EMCInteractionClass		mask CLASSF_DISCARD_ON_SAVE

	EMCPanelInteractionClass	mask CLASSF_DISCARD_ON_SAVE

	EMCTriggerClass			mask CLASSF_DISCARD_ON_SAVE

if _EXPRESS_MENU
	EMCThreadClass
endif

UserClassStructures	ends

idata	segment
	runningISUI		byte	0x80
	runningMotif		byte	0x80
	forceSmallIcons		byte	0x80
idata	ends

;---------------------------------------------------

ExpressMenuControlCode segment resource
if _EXPRESS_MENU

COMMENT @----------------------------------------------------------------------

MESSAGE:	ExpressMenuControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ExpressMenuControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ExpressMenuControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	cx, bx, si, di, ds, es(message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlGetInfo	method dynamic	ExpressMenuControlClass,
					MSG_GEN_CONTROL_GET_INFO

	movdw	esdi, cxdx		;es:di = dest
	segmov	ds, cs
	mov	si, offset EMC_dupInfo
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

ExpressMenuControlGetInfo	endm

EMC_dupInfo	GenControlBuildInfo	<
					; GCBI_flags
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST or mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED,
	; Cannot ever destroy children, as applications keep internal ptrs to
	; their express menu list entries.
	EMC_IniFileKey,			; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	EMCName,			; GCBI_controllerName

	handle ExpressMenuControlUI,	; GCBI_dupBlock
	EMC_childList,			; GCBI_childList
	length EMC_childList,		; GCBI_childCount
	EMC_featuresList,		; GCBI_featuresList
	length EMC_featuresList,	; GCBI_featuresCount
	EMC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

EMC_IniFileKey	char	"expressMenuControl", 0

;---

EMC_childList	GenControlChildInfo	\
	<offset DocumentsMenu, mask EMCF_DOCUMENTS_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GEOSTasksSubMenu, mask EMCF_GEOS_TASKS_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeskAccessoryList, mask EMCF_DESK_ACCESSORY_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset MainAppsList, mask EMCF_MAIN_APPS_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset OtherAppsList, mask EMCF_OTHER_APPS_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ControlPanel, mask EMCF_CONTROL_PANEL,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DOSTasksList, mask EMCF_DOS_TASKS_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset UtilitiesPanel, mask EMCF_UTILITIES_PANEL,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ExitToDOS, mask EMCF_EXIT_TO_DOS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

EMC_featuresList	GenControlFeaturesInfo	\
	<offset ExitToDOS, ExitToDOSName>,
	<offset UtilitiesPanel, UtilitiesPanelName>,
	<offset DOSTasksList, DOSTasksListName>,
	<offset ControlPanel, ControlPanelName>,
	<offset OtherAppsList, OtherAppsListName>,
	<offset MainAppsList, MainAppsListName>,
	<offset DeskAccessoryList, DeskAccessoryListName>,
	<offset GEOSTasksSubMenu, GEOSTasksListName>,
	<offset DocumentsMenu, DocumentsListName>

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	ExpressMenuControlGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
					for ExpressMenuControlClass

DESCRIPTION:	Generate UI for controller

PASS:
	*ds:si - instance data
	es - segment of ExpressMenuControlClass

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
	brianc	11/3/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlGenerateUI	method dynamic	ExpressMenuControlClass,
						MSG_GEN_CONTROL_GENERATE_UI

	; first call our superclass

	mov	di, offset ExpressMenuControlClass
	call	ObjCallSuperNoLock

	mov	ax, ATTR_EMC_SYSTEM_TRAY
	call	ObjVarFindData
	LONG jc	setupSystemTray

	push	si				; save our chunk handle

	; create necessary application lists

	call	EMGetFeaturesAndChildBlock	; ax = features, bx = block

;-------------------------------------------------------------------------

	; create "Floating Keyboard" item if .ini file specifies it
	;	ax = features
	;	bx = block
	;	*ds:si = EMC

	push	ax, si				; save features, EMC chunk
	mov	dx, offset floatingKeyboardKey
	call	checkIniKeyBoolean		; ax = TRUE/FALSE
	jc	afterFloatingKbd		; not found, nothing to add
	tst	ax
	jz	afterFloatingKbd		; floatingKeyboard = FALSE
	;
	; add "Floating Keyboard" item just before "Exit to DOS" item
	;	bx = child block
	;	*ds:si  = EMC
	;
	mov	cx, bx				; ^lcx:dx = "Exit to DOS" item
	mov	dx, offset ExitToDOS
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	jnc	havePosition
	mov	bp, CCO_LAST			; no "Exit to DOS", add at end
						;	not dirty
havePosition:
	mov	cx, bx				; ^lcx:dx = floating kbd item
	mov	dx, offset OpenFloatingKbd
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx			; ^lbx:si = "Floating Kbd"
						; bx = still child block
	call	emcGUISetUsable
afterFloatingKbd:
	pop	ax, si				; ax = features, EMC chunk

;-------------------------------------------------------------------------

	;
	; add "Go to GeoManager" in Motif Redux
	;	bx = child block
	;	*ds:si  = EMC
	;

	push	ax, si

	call	CheckIfRunningMotif95
	jnz	afterMotif95			; jump if zero flag is not set, no Motif Redux

	mov	cx, bx				; ^lcx:dx = "Exit to DOS" item
	mov	dx, offset ExitToDOS
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	jnc	havePosition2
	mov	bp, CCO_LAST			; no "Exit to DOS", add at end
						; not dirty
havePosition2:
	mov	cx, bx				; ^lcx:dx = Go to GeoManager item
	mov	dx, offset GoToGeoManager
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx			; ^lbx:si = "Go to GeoManager"
						; bx = still child block
	call	emcGUISetUsable

afterMotif95:

	pop	ax, si				; ax = features, EMC chunk

;-------------------------------------------------------------------------

	call	CheckIfRunningISDesk
	LONG je noReturnToDefault

	;
	; create "Return to <default launcher>" item if hint specifies it
	;	ax = features
	;	bx = block
	;	*ds:si = EMC

	push	ax, bx, si
	mov	di, bx				; di = child block
	mov	ax, TEMP_EMC_HAS_RETURN_TO_DEFAULT_LAUNCHER
	call	ObjVarFindData			; carry set if found
						; ds:bx = launcher name/path
	LONG jnc	afterReturn
	;
	; find tail component of launcher name/path
	;	*ds:si = EMC
	;	ds:bx = launcher name/path
	;	di = child block
	;
	push	si				; save EMC chunk
	mov	si, bx
saveTailPosition:
	mov	bx, si				; ds:bx = potential tail comp.
findTailLoop:
	LocalGetChar ax, dssi
	LocalCmpChar ax, C_BACKSLASH
	je	saveTailPosition
	LocalIsNull ax
	jnz	findTailLoop
SBCS <	cmp	{char} ds:[bx], 0		; any tail?		>
DBCS <	cmp	{wchar} ds:[bx], 0		; any tail?		>
	pop	si				; *ds:si = EMC
	jz	afterReturn			; nope
	xchg	di, bx				; bx = child block
						; ds:di = tail component
	;
	; add "Return to <default launcher>" item just before
	; "Exit to DOS" item
	;	*ds:si  = EMC
	;	bx = child block
	;	ds:di = tail component
	;
	mov	cx, bx				; ^lcx:dx = "Exit to DOS" item
	mov	dx, offset ExitToDOS
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	jnc	haveReturnPosition
	mov	bp, CCO_LAST			; no "Exit to DOS", add at end
						;	not dirty
haveReturnPosition:
	mov	cx, bx				; ^lcx:dx = return item
	mov	dx, offset ReturnToDefaultLauncher
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx			; ^lbx:si = return item
						; bx = still child block
	;
	; append default launcher name to moniker
	;	^lbx:si = return item
	;	ds:di = tail component
	;
	push	es
	segmov	es, ds				; es:di = tail component
if DBCS_PCGEOS
	call	LocalStringSize
else
	mov	al, 0
	mov	cx, -1
	push	di
	repne scasb
	pop	di
	not	cx
	dec	cx				; cx = length w/o null
endif

	call	ObjSwapLock			; *ds:si = return item
	push	bx				; bx = EMC block
	push	cx				; save tail component length
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	ObjCallInstanceNoLockES		; ax = moniker chunk
	pop	cx				; cx = len of tail component
	mov	si, ax				; *ds:si = *ds:ax = moniker
	mov	bx, ds:[si]			; ds:bx = VisMoniker
	mov	ds:[bx].VM_width, 0		; changing moniker manually
	ChunkSizeHandle	ds, si, bx		; insert at end of chunk
	dec	bx				; ...before null
DBCS <	dec	bx							>
	call	LMemInsertAt
	add	bx, ds:[si]			; bx = end of chunk
	segxchg	ds, es				; ds:di = tail component
						; es:bx = end of moniker
	mov	si, di				; ds:si = tail component
	mov	di, bx				; es:di = end of moniker
	rep movsb				; copy in tail component
	segmov	ds, es				; ds = moniker segment
						;	(child block)
	pop	bx				; bx = EMC block
	call	ObjSwapUnlock			; ds = EMC segment
						; ^lbx:si = return item
	mov	si, offset ReturnToDefaultLauncher
	call	emcGUISetUsable
	pop	es
afterReturn:
	pop	ax, bx, si
noReturnToDefault:

;-------------------------------------------------------------------------

	;
	; disable submenu-conversion-on-small-size if .ini specifies it
	;	*ds:si = EMC
	;	bx = child block
	;	ax = features

	test	ax, mask EMCF_MAIN_APPS_LIST or \
			mask EMCF_OTHER_APPS_LIST or \
			mask EMCF_DESK_ACCESSORY_LIST
	jz	afterNoSubMenus

	push	si				;save features, EMC chunk
	push	ax
	mov	dx, offset noSubMenusKey
	call	checkIniKeyBoolean		;ax = TRUE/FALSE
	jc	allowSubMenus			;branch if not found
	tst	ax
	jz	allowSubMenus			;branch if noSubMenus=FALSE
	;
	; remove monikers from main apps, other apps, desk accessory
	;	bx = child block
	;
	pop	ax
	push	ax
	test	ax, mask EMCF_MAIN_APPS_LIST
	jz	noMainAppsSubMenu
	mov	si, offset MainAppsList
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noMainAppsSubMenu:
	pop	ax
	push	ax
	test	ax, mask EMCF_OTHER_APPS_LIST
	jz	noOtherAppsSubMenu
	mov	si, offset OtherAppsList
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noOtherAppsSubMenu:
	pop	ax
	push	ax
	test	ax, mask EMCF_DESK_ACCESSORY_LIST
	jz	noDeskAccessorySubMenu
	mov	si, offset DeskAccessoryList
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noDeskAccessorySubMenu:

allowSubMenus:
	pop	ax
	pop	si				; *ds:si = EMC, ax = features
afterNoSubMenus:

;-------------------------------------------------------------------------

	;
	; force submenus if .ini specifies it
	;	*ds:si = EMC
	;	bx = child block
	;	ax = features

	test	ax, mask EMCF_MAIN_APPS_LIST or \
			mask EMCF_OTHER_APPS_LIST or \
			mask EMCF_DESK_ACCESSORY_LIST
	jz	afterForceSubMenus

	push	si				;save features, EMC chunk
	push	ax
	mov	dx, offset forceSubMenusKey
	call	checkIniKeyBoolean
	jc	noForceSubMenus			;branch if not found
	tst	ax
	jz	noForceSubMenus			;branch if forceSubMenus=FALSE
	;
	; set visibility = popup on main-apps, other-apps, desk-accessory
	;	bx = child block
	;
	pop	ax
	push	ax
	test	ax, mask EMCF_MAIN_APPS_LIST
	jz	noMainAppsForceSubMenu
	mov	si, offset MainAppsList
	call	emcGUIForceSubMenu
noMainAppsForceSubMenu:
	pop	ax
	push	ax
	test	ax, mask EMCF_OTHER_APPS_LIST
	jz	noOtherAppsForceSubMenu
	mov	si, offset OtherAppsList
	call	emcGUIForceSubMenu
noOtherAppsForceSubMenu:
	pop	ax
	push	ax
	test	ax, mask EMCF_DESK_ACCESSORY_LIST
	jz	noDeskAccessoryForceSubMenu
	mov	si, offset DeskAccessoryList
	call	emcGUIForceSubMenu
noDeskAccessoryForceSubMenu:

noForceSubMenus:
	pop	ax
	pop	si				; *ds:si = EMC, ax = features
afterForceSubMenus:

;-------------------------------------------------------------------------

	;
	; move top level apps and other apps into Run sub menu if .ini
	; specifies this
	;	*ds:si = EMC
	;	bx = child block
	;	ax = features

	test	ax, mask EMCF_MAIN_APPS_LIST or mask EMCF_OTHER_APPS_LIST
	jz	afterRunSubMenu			;neither feature exists

	push	ax, si				;save features, EMC chunk
	call	CheckIfRunningISUI
	jnz	makeRunSubMenu
	mov	dx, offset runSubMenuKey
	call	checkIniKeyBoolean
	jc	makeRunSubMenu			;branch if not found
	tst	ax
	jz	leaveRunSubMenu			;branch if runSubMenu=FALSE
makeRunSubMenu:
	;
	; add RunSubMenu item after desk accessory list or after GEOS tasks
	; list or first
	;	bx = child block
	;	*ds:si  = EMC
	;
	mov	cx, bx				;^lcx:dx = desk accessory list
	mov	dx, offset DeskAccessoryList
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		;bp = position, not dirty
	inc	bp				; (add after) (preserve carry)
	jnc	haveRunPosition			;branch if found
	mov	cx, bx
	mov	dx, offset GEOSTasksSubMenu	;^lcx:dx <- GEOS tasks list
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	inc	bp				; (add after) (preserve carry)
	jnc	haveRunPosition			;branch if found
	mov	bp, CCO_FIRST			;no pos refs, add first
						;	not dirty
haveRunPosition:
	mov	cx, bx
	mov	dx, offset RunSubMenu		;^lcx:dx <- Run submenu item
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	pushdw	cxdx				;save Run submenu
	mov	bp, offset RunSubMenu		;^lbx:bp <- submenu to update
	call	EMCUpdateSubMenuPriority
	popdw	bxsi				;^lbx:si <- Run submenu
						;bx <- still child block
	call	emcGUISetUsable
	;
	; move top level apps list and other apps list to Run sub menu
	;	bx = child block
	;
	pop	ax, si				;*ds:si <- EMC, ax <- features
	mov	dx, offset OtherAppsList	;subdirs above apps
	call	moveItemToRunSubMenu
	mov	dx, offset MainAppsList
	call	moveItemToRunSubMenu
	jmp	short afterRunSubMenu

leaveRunSubMenu:
	pop	ax, si				;*ds:si <- EMC, ax <- features
afterRunSubMenu:

;-------------------------------------------------------------------------

	; create list of desk accessories, if needed
	;	*ds:si = EMC
	;	bx = child block

	push	si
	test	ax, mask EMCF_DESK_ACCESSORY_LIST
	jz	afterDeskAccessoryList
	mov	bp, offset DeskAccessoryList	;^bx:bp <- possible submenu
	call	EMCUpdateSubMenuPriority
	call	LockDAPathname			;cx:dx <- desk accessory path
	mov	bp, SP_APPLICATION		;bp, cx:dx <- dir to search
	mov	si, offset DeskAccessoryList	;^lbx:si <- list to add to
	call	StorePathInAppList
	call	UnlockDAPathname		;(preserves flags)
	jc	afterDeskAccessoryList		;branch if error
	call	CreateAppList
	call	addAppsBuiltFlag
afterDeskAccessoryList:
	pop	si				;*ds:si = EMC

;-------------------------------------------------------------------------

	;
	; create list of top level apps
	;	*ds:si = EMC
	;	bx = child block
	;

	test	ax, mask EMCF_MAIN_APPS_LIST
	jz	afterMainAppsList
	mov	bp, offset MainAppsList		;^bx:bp <- possible submenu
	call	EMCUpdateSubMenuPriority
	mov	si, offset MainAppsList		;^lbx:si <- list to add to
	mov	bp, SP_APPLICATION		;bp, cx:dx <- dir to search
	mov	cx, cs
	mov	dx, offset nullPathname
	call	StorePathInAppList
	jc	afterMainAppsList		;branch if error
	call	CreateAppList
	call	addAppsBuiltFlag
afterMainAppsList:

;-------------------------------------------------------------------------

	;
	; create list of other apps (hierarichal)
	;

	test	ax, mask EMCF_OTHER_APPS_LIST
	LONG jz	afterOtherAppsList
	;
	; if the .ini file requests it, change the OtherApps subgroup into
	; a submenu
	;
	push	ax				;save features
	call	CheckIfRunningISUI
	jnz	leaveSubGroup
	mov	dx, offset otherAppSubMenuKey
	call	checkIniKeyBoolean
	jc	leaveSubGroup			;branch if not found
	tst	ax
	jz	leaveSubGroup			;branch if submenu=FALSE
	;
	; change into submenu
	;	bx = child block
	;
	mov	si, offset OtherAppsList	;^lbx:si <- other apps list
	call	ObjSwapLock			;*ds:si <- other apps list
						;bx <- EMC block
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	call	ObjCallInstanceNoLock

	mov	cx, offset OtherAppsListMoniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock			;ds <- EMC
						;bx <- child block
	;
	; even though we aren't a submenu, we'll still need to custom window
	; hints, so they can be copied to the subdirectory submenus
	;
leaveSubGroup:
	pop	ax				;ax <- features
	;
	; give OtherAppsList submenu the same window characteristics as the
	; parent window (we require that the ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	; and ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY hints be placed on the
	; ExpressMenuControl if they are to be used at all for the express
	; menu)
	;	bx = child block
	;	ds = EMC segment
	;
	pop	si				;*ds:si <- EMC
	push	si
	mov	bp, offset OtherAppsList	;^lbx:bp <- other apps list
	call	EMCUpdateSubMenuPriority
	mov	si, offset OtherAppsList	;^lbx:si <- list to add to
	mov	bp, SP_APPLICATION		;bp, cx:dx <- dir to search
	mov	cx, cs
	mov	dx, offset nullPathname
	call	StorePathInAppList
	jc	afterOtherAppsList
	call	CreateOtherAppsList
	call	ForceOtherAppsSubdirIfTooManyEntries
	call	addAppsBuiltFlag
afterOtherAppsList:

;-------------------------------------------------------------------------

	;
	; give DocumentsList submenu the same window characteristics as the
	; parent window
	;	bx = child block
	;	ds = EMC segment
	;
	test	ax, mask EMCF_DOCUMENTS_LIST
	jz	afterDocumentList
	pop	si				;*ds:si <- EMC
	push	si
	mov	bp, offset DocumentsMenu	;^lbx:bp <- documents menu
	call	EMCUpdateSubMenuPriority
	mov	si, offset DocumentsList	;^lbx:si <- list to add to
	mov	bp, SP_DOCUMENT			;bp, cx:dx <- dir to search
	mov	cx, cs
	mov	dx, offset nullPathname
	call	StorePathInAppList
	jc	afterDocumentList		;branch if error
	call	CreateDocumentList
	call	addAppsBuiltFlag

	;
	; move DocumentsMenu before ControlPanel
	;
	push	ax
	mov	si, offset DocumentsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

	movdw	cxdx, bxsi			;^lcx:dx <- DocumentsList
	pop	si				;*ds:si <- EMC
	push	si

	push	ax
	push	cx, dx
	mov	ax, MSG_GEN_FIND_CHILD
	mov	dx, offset ControlPanel
	call	ObjCallInstanceNoLock
	pop	cx, dx
	jc	setDocListUsable

	mov	ax, MSG_GEN_MOVE_CHILD
	dec	bp
	call	ObjCallInstanceNoLock

setDocListUsable:
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax

afterDocumentList:

;-------------------------------------------------------------------------

	;
	; do special stuff for Start menu in ISUI
	;

	test	ax, mask EMCF_CONTROL_PANEL or mask EMCF_UTILITIES_PANEL
	jz	afterPanels

	call	CheckIfRunningISUI
	jz	afterPanels			;branch if not ISUI

	pop	si				;*ds:si <- EMC
	push	si

	push	ax
	mov	di, CCO_LAST			;di <- position to add
	mov	dx, offset ControlPanel
	call	moveItemToSettingsMenu
	mov	dx, offset UtilitiesPanel
	call	moveItemToSettingsMenu

	push	si
	mov	bp, offset StartMenuGroup	;^lbx:bp <- StartMenuGroup
	call	EMCUpdateSubMenuPriority
	pop	si

	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, bx
	mov	dx, offset StartMenuGroup
	mov	bp, di
	call	ObjCallInstanceNoLock

	push	si
	movdw	bxsi, cxdx
	call	emcGUISetUsable
	pop	si
	pop	ax

afterPanels:

;-------------------------------------------------------------------------

	;
	; update GEOS Tasks List submenu
	;

	test	ax, mask EMCF_GEOS_TASKS_LIST
	jz	afterGEOSTasksList
	;
	; if the .ini file requests it, change the GEOS tasks list submenu into
	; a subgroup
	;
	push	ax				;save features
	mov	dx, offset geosTaskSubMenuKey
	call	checkIniKeyBoolean
	jc	leaveGeosTaskSubMenu		;branch if not found
	tst	ax
	jz	leaveGeosTaskSubMenu		;branch if submenu=FALSE
	;
	; change into submenu
	;	bx = child block
	;
	mov	si, offset GEOSTasksSubMenu	;^lbx:si <- GEOS tasks list
	call	ObjSwapLock			;*ds:si <- GEOS tasks list
						;bx = EMC block
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock			;ds <- EMC
						;bx <- child block
	;
	; even though we aren't a submenu, we'll still need custom window
	; hints so they can be copied to the subdirectory submenus
	;
leaveGeosTaskSubMenu:
	pop	ax				;ax <- features
	;
	; give GEOSTasksSubMenu submenu the same window characteristics as the
	; parent window (we require that the ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	; and ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY hints be placed on the
	; ExpressMenuControl if they are to be used at all for the express
	; menu)
	;	bx = child block
	;	ds = EMC segment
	;
	pop	si				;*ds:si <- EMC
	push	si
	mov	bp, offset GEOSTasksSubMenu	;^lbx:bp <- submenu to update
	call	EMCUpdateSubMenuPriority
afterGEOSTasksList:

;-------------------------------------------------------------------------

	;
	; send out notification that EMC has been created
	;

	mov	cx, ds:[LMBH_handle]		;^lcx:dx <- EMC
	pop	dx
	mov	ax, MSG_NOTIFY_EXPRESS_MENU_CHANGE
	mov	bp, GCNEMNT_CREATED
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_EXPRESS_MENU_CHANGE
	mov	di, mask GCNLSF_FORCE_QUEUE	;force queue to avoid deadlock
	pushdw	cxdx
	call	GCNListRecordAndSend
	popdw	cxdx

	;
	; add ourselves to list of Express Menu Control objects in the system
	;	^lcx:dx - Express Menu Control
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
	call	GCNListAdd
	;
	; add ourselves to be notified of file changes
	;	^lcx:dx = Express Menu Control
	;
	mov	si, dx
	mov	ax, ATTR_EMC_SYSTEM_TRAY
	call	ObjVarFindData
	jc	skipFileChanges
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListAdd
skipFileChanges:
	;
	; add ourselves to the active list
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or mask GCNLTF_SAVE_TO_STATE
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_ADD

	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	exit

	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
exit:
	add	sp, size GCNListParams
	ret

setupSystemTray:
	push	si
	call	EMGetFeaturesAndChildBlock
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, bx
	push	cx
	mov	dx, offset SysTrayPanel
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock
	pop	bx
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_SET_USABLE
	call	ObjMessage
	jmp	afterGEOSTasksList

;---------------------------------------------------------------------------

;
; pass:
;	dx = offset in code segment of .ini key string
; return:
;	carry clear if .ini key found
;		ax = TRUE/FALSE
;	carry set if not found
; destoryed:
;	cx, cx
;
checkIniKeyBoolean	label	near
	push	ds, si
	mov	cx, cs
	mov	ds, cx
	mov	si, offset emcCategory
	call	InitFileReadBoolean		;ax <- TRUE/FALSE
	pop	ds, si
	retn

;
; pass:
;	^lbx:si = EMCInteraction
; return:
;	nothing
; destroyed:
;	nothing
;
addAppsBuiltFlag	label	near
	push	ax, cx
	call	ObjSwapLock
	push	bx
	mov	ax, TEMP_EMC_INTERACTION_APPS_BUILT
	clr	cx
	call	ObjVarAddData
	pop	bx
	call	ObjSwapUnlock
	pop	ax, cx
	retn

;
; pass:
;	*ds:si = EMC
;	^lbx:dx = item to move
;	bx = child block
;	ax = features
; return:
;	nothing
; destroyed:
;	cx, dx, bp, di
;
moveItemToRunSubMenu	label	near
	push	ax, bx, si
	mov	cx, bx				; ^lcx:dx = item
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	jc	notFound
	push	bx, si				; save child block, EMC chunk
	movdw	bxsi, cxdx			; ^lbx:si = item
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	cx				; nuke moniker, so we won't
	mov	dl, VUM_MANUAL			;   try to create a sub-submenu
	mov	ax, MSG_GEN_USE_VIS_MONIKER	;   if there's not enough room.
	call	ObjMessage			;   (cbh 4/22/93)

	movdw	cxdx, bxsi			; ^lcx:dx = item
	pop	bx, si				; bx = child block, *ds:si = EMC
	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp
	call	ObjCallInstanceNoLock		; (preserves ^lcx:dx)
	mov	si, offset RunSubMenu		; ^lbx:si = Run sub menu
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST			; not dirty
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	bxsi, cxdx
	call	emcGUISetUsable
notFound:
	pop	ax, bx, si
	retn

;
; pass:
;	*ds:si = EMC
;	^lbx:dx = item to move
;	bx = child block
;	ax = features
;	di = initial position to add start menu group
; return:
;	di = updated position to add start menu group
; destroyed:
;	cx, dx, bp
;
moveItemToSettingsMenu	label	near
	push	ax, bx, si
	mov	cx, bx				; ^lcx:dx = item
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; bp = position, not dirty
	jc	notFound2

	cmp	di, CCO_LAST
	jne	haveStartMenuGroupPosition
	mov	di, bp				; di = position to add start

haveStartMenuGroupPosition:
	push	di
	push	bx, si				; save child block, EMC chunk
	movdw	bxsi, cxdx			; ^lbx:si = item
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi			; ^lcx:dx = item
	pop	bx, si				; bx = child block, *ds:si =EMC

	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp
	call	ObjCallInstanceNoLock		; (preserves ^lcx:dx)

	mov	si, offset SettingsGroup	; ^lbx:si = Settings menu
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST			; not dirty
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	movdw	bxsi, cxdx
	call	emcGUISetUsable
	pop	di
notFound2:
	pop	ax, bx, si
	retn

;
; pass:
;	^lbx:si = object
; return:
;	nothing
; destroyed:
;	ax, cx, dx, bp, di
;
emcGUISetUsable	label	near
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn

;
; pass:
;	^lbx:si = object
; return:
;	nothing
; destroeyd:
;	ax, cx, dx, bp, di
;
emcGUIForceSubMenu	label	near
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn

ExpressMenuControlGenerateUI	endm

LocalDefNLString nullPathname <0>

emcCategory		byte	"expressMenuControl",0
geosTaskSubMenuKey	byte	"runningAppSubMenu",0
otherAppSubMenuKey	byte	"otherAppSubMenu",0
floatingKeyboardKey	byte	"floatingKeyboard",0
runSubMenuKey		byte	"runSubMenu",0
noSubMenusKey		byte	"noSubMenus",0
forceSubMenusKey	byte	"forceSubMenus",0
forceSmallIconsKey	byte	"forceSmallIcons",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCUpdateSubMenuPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy custom window priority hints from parent (EMC)

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI

PASS:		*ds:si - ExpressMenuControl
		bx - child block
		bp - offset of sub menu in child block to update

RETURN:		nothing

DESTROYED:	cx, dx, bp, si, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/22/92	broke out of ExpressMenuControlGenerateUI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCUpdateSubMenuPriority	proc	near
	uses	ax
	.enter
	call	ObjLockObjBlock
	mov	es, ax
.assert (ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY+4 eq ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY)
.assert (ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY+4 eq ATTR_GEN_WINDOW_CUSTOM_PARENT)
	mov	cx, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	mov	dx, ATTR_GEN_WINDOW_CUSTOM_PARENT
	call	ObjVarCopyDataRange
	mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	mov	dx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	call	ObjVarCopyDataRange
	segxchg	ds, es				; *ds:si = other apps list
	mov	si, bp				; es = EMC segment
	mov	ax, cx				; ax = CUSTOM_LAYER_ID
	push	bx				; save child block
	call	ObjVarFindData			; ds:bx = vardata
	tst	<{word} ds:[bx]>
	jnz	leaveLayerID
	mov	ax, es:[LMBH_handle]		; if layer id = NULL, use EMC
	mov	ds:[bx], ax			;	block handle
leaveLayerID:
	pop	bx				; bx = child block
	segmov	ds, es				; ds = EMC segment
	call	MemUnlock
	.leave
	ret
EMCUpdateSubMenuPriority	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	ExpressMenuControlSpecUnbuild --
			MSG_SPEC_UNBUILD for ExpressMenuControlClass

DESCRIPTION:	Remove ourselves from GCN list

PASS:
	*ds:si - instance data
	es - segment of ExpressMenuControlClass

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
	brianc	11/10/92	Initial version

------------------------------------------------------------------------------@
ExpressMenuControlSpecUnbuild	method dynamic	ExpressMenuControlClass,
						MSG_SPEC_UNBUILD

	; call our superclass

	mov	di, offset ExpressMenuControlClass
	call	ObjCallSuperNoLock

	ret

ExpressMenuControlSpecUnbuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressMenuControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clean up after ourselves

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI

PASS:		*ds:si	= ExpressMenuControlClass object
		ds:di	= ExpressMenuControlClass instance data
		es 	= segment of ExpressMenuControlClass
		ax	= MSG_GEN_CONTROL_DESTROY_UI

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/20/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressMenuControlDestroyUI	method	dynamic	ExpressMenuControlClass,
						MSG_GEN_CONTROL_DESTROY_UI
	;
	; free up floating keyboard, if any
	;
	call	EMGetFeaturesAndChildBlock	; bx = child block
	mov	cx, bx				; ^lcx:dx = floating keyboard
	mov	dx, offset OpenFloatingKbd
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; carry set if not found
	jc	noKeyboard
	push	si
	movdw	bxsi, cxdx			; ^lcx:dx preserved above
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	si				; *ds:si = EMC
	clr	bp				; not dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock
noKeyboard:
	;
	; free up "Return to <default launcher>", if any
	;
	call	EMGetFeaturesAndChildBlock	; bx = child block
	mov	cx, bx				; ^lcx:dx = return item
	mov	dx, offset ReturnToDefaultLauncher
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; carry set if not found
	jc	noReturn
	push	si
	movdw	bxsi, cxdx			; ^lcx:dx preserved above
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	si				; *ds:si = EMC
	clr	bp				; not dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock
noReturn:
	;
	; undo Run sub menu, if any
	;
	call	EMGetFeaturesAndChildBlock	; bx = child block
	mov	cx, bx				; ^lcx:dx = Run sub menu
	mov	dx, offset RunSubMenu
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; carry set if not found
	jc	noRunSubMenu
	push	si
	movdw	bxsi, cxdx			; ^lcx:dx preserved above
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	si				; *ds:si = EMC
	clr	bp				; not dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock
noRunSubMenu:
	;
	; remove the StartMenuGroup, if any
	;
	call	EMGetFeaturesAndChildBlock	; bx = child block
	mov	cx, bx				; ^lcx:dx = StartMenuGroup
	mov	dx, offset StartMenuGroup
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; carry set if not found
	jc	noStartMenuGroup
	push	si
	movdw	bxsi, cxdx			; ^lcx:dx preserved above
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	si				; *ds:si = EMC
	clr	bp				; not dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock
noStartMenuGroup:
	;
	; free up system tray, if any
	;
	call	EMGetFeaturesAndChildBlock	; bx = child block
	mov	cx, bx				; ^lcx:dx = system tray
	mov	dx, offset SysTrayPanel
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock		; carry set if not found
	jc	noSysTray
	push	si
	movdw	bxsi, cxdx			; ^lcx:dx preserved above
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	si				; *ds:si = EMC
	clr	bp				; not dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock
noSysTray:
	;
	; let superclass handle
	;
	mov	ax, MSG_GEN_CONTROL_DESTROY_UI
	mov	di, offset ExpressMenuControlClass
	call	ObjCallSuperNoLock
	ret
ExpressMenuControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressMenuControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make some changes to Express menu if running under ISUI

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= ExpressMenuControl object
		ds:di	= ExpressMenuControlInstance
		cx	= duplicated block handle
		dx	= features mask
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

finderKey char "finder", 0

ExpressMenuControlTweakDuplicatedUI method dynamic ExpressMenuControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	;
	; check if ISUI is loaded
	;
	call	CheckIfRunningISUI
	LONG jz done

if 0
	;
	; check for [expressMenuControl] finder = key
	;
	push	si, bx, cx, dx
	sub	sp, (size GeodeToken)+(size AddVarDataParams)
	mov	di, sp
	push	cx, ds				;save dup. block
	segmov	ds, cs, cx
	mov	si, offset EMC_IniFileKey	;ds:si <- category
	mov	dx, offset finderKey		;cx:dx <- key
	mov	bp, (size GeodeToken)		;bp <- buffer size
	segmov	es, ss				;es:di <- buffer
	call	InitFileReadData
	pop	bx, ds				;bx <- handle of dup. block
	jc	noFinder
	lea	bp, ss:[di][(size GeodeToken)]
	movdw	ss:[bp].AVDP_data, esdi
	mov	ss:[bp].AVDP_dataSize, (size GeodeToken)
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	si, offset FindTrigger
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
noFinder:
	add	sp, (size GeodeToken)+(size AddVarDataParams)
	pop	si, bx, cx, dx
endif

	;
	; tweak some ui
	;
	mov	bx, cx
	test	dx, mask EMCF_DESK_ACCESSORY_LIST
	jz	afterDeskAccessory

	push	dx
	push	bx
	mov	bp, bx
	mov	ax, SMMT_APPLICATIONS_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle DeskAccessoryTextMoniker
	mov	dx, offset DeskAccessoryTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset DeskAccessoryList
	call	useVisMoniker

	mov	ax, HINT_INFREQUENTLY_USED
	call	addHintNoData
	pop	dx
afterDeskAccessory:

	test	dx, mask EMCF_MAIN_APPS_LIST or mask EMCF_OTHER_APPS_LIST
	jz	afterRunSubMenu

	push	dx
	push	bx
	mov	bp, bx
	mov	ax, SMMT_APPLICATIONS_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle ApplicationsTextMoniker
	mov	dx, offset ApplicationsTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset RunSubMenu
	call	useVisMoniker

	mov	ax, HINT_INFREQUENTLY_USED
	call	addHintNoData

	pop	dx
afterRunSubMenu:

	test	dx, mask EMCF_DOCUMENTS_LIST
	jz	afterDocumentsList

	push	dx
	push	bx
	mov	bp, bx
	mov	ax, SMMT_DOCUMENTS_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle DocumentsTextMoniker
	mov	dx, offset DocumentsTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset DocumentsMenu
	call	useVisMoniker
	pop	dx
afterDocumentsList:

	test	dx, mask EMCF_CONTROL_PANEL or mask EMCF_UTILITIES_PANEL
	LONG jz	afterControlPanel

	push	dx
	push	bx
	mov	bp, bx
	mov	ax, SMMT_SETTINGS_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle SettingsTextMoniker
	mov	dx, offset SettingsTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset SettingsGroup
	call	useVisMoniker

	push	bx
	mov	bp, bx
	mov	ax, SMMT_PREFERENCES_TOOL_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle PreferencesTextMoniker
	mov	dx, offset PreferencesTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset PreferencesTrigger
	call	useVisMoniker

	push	bx
	mov	bp, bx
	mov	ax, SMMT_DIALUP_TOOL_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle DialUpTextMoniker
	mov	dx, offset DialUpTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset DialUpTrigger
	call	useVisMoniker

	push	bx
	mov	bp, bx
	mov	ax, SMMT_FIND_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle FindTextMoniker
	mov	dx, offset FindTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset FindTrigger
	call	useVisMoniker

	push	bx
	mov	bp, bx
	mov	ax, SMMT_HELP_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle HelpTextMoniker
	mov	dx, offset HelpTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset HelpTrigger
	call	useVisMoniker

	pop	dx

	;
	; check [motifOptions]::helpOptions
	;
	push	dx, ds
	clr	ax				; ax = default UIHelpOptions
	mov	cx, cs
	mov	dx, offset helpOptionsKey
	mov	ds, cx
	mov	si, offset helpOptionsCategory
	call	InitFileReadInteger
	pop	dx, ds
	test	ax, mask UIHO_HIDE_HELP_BUTTONS
	jz	afterHelp

	;
	; remove HelpTrigger
	;
	push	dx
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	bp
	mov	si, offset HelpTrigger
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx
afterHelp:

afterControlPanel::
	test	dx, mask EMCF_EXIT_TO_DOS
	jz	afterExitToDOS

	push	dx
	push	bx
	mov	bp, bx
	mov	ax, SMMT_EXIT_MONIKER
	call	StartMenuGetIconMoniker
	mov	cx, handle ExitTextMoniker
	mov	dx, offset ExitTextMoniker
	call	CreateCombinationMonikerOptr
	pop	bx

	mov	si, offset ExitToDOS
	call	useVisMoniker
	pop	dx
afterExitToDOS:

done:
	ret

useVisMoniker:
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn

addHintNoData:
	sub	sp, size AddVarDataParams
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, 0
	mov	ss:[bp].AVDP_dataSize, 0
	mov	ss:[bp].AVDP_dataType, ax
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams
	retn

ExpressMenuControlTweakDuplicatedUI endm

helpOptionsCategory	char	"motifOptions",0
helpOptionsKey		char	"helpOptions",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartMenuGetIconMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for Start Menu

CALLED BY:	INTERNAL
PASS:		ax	= StartMenuMonikerType
RETURN:		^lbx:di	= VisMoniker
DESTROYED:	ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartMenuMonikerType	etype	word
	SMMT_APPLICATIONS_MONIKER	enum	StartMenuMonikerType
	SMMT_DOCUMENTS_MONIKER		enum	StartMenuMonikerType
	SMMT_SETTINGS_MONIKER		enum	StartMenuMonikerType
	SMMT_FIND_MONIKER		enum	StartMenuMonikerType
	SMMT_HELP_MONIKER		enum	StartMenuMonikerType
	SMMT_EXIT_MONIKER		enum	StartMenuMonikerType
	SMMT_APPLICATIONS_TOOL_MONIKER	enum	StartMenuMonikerType
	SMMT_DOCUMENTS_TOOL_MONIKER	enum	StartMenuMonikerType
	SMMT_PREFERENCES_TOOL_MONIKER	enum	StartMenuMonikerType
	SMMT_DEFAULT_TOOL_MONIKER	enum	StartMenuMonikerType
	SMMT_DIALUP_TOOL_MONIKER	enum	StartMenuMonikerType

StartMenuMonikerStruct	struct
	SMMS_colorMoniker	optr
	SMMS_colorToolMoniker	optr
StartMenuMonikerStruct	ends

startMenuMonikerTable	nptr	\
	applicationsMonikerList,	; SMMT_APPLICATIONS_MONIKER
	documentsMonikerList,		; SMMT_DOCUMENTS_MONIKER
	settingsMonikerList,		; SMMT_SETTINGS_MONIKER
	findMonikerList,		; SMMT_FIND_MONIKER
	helpMonikerList,		; SMMT_HELP_MONIKER
	exitMonikerList,		; SMMT_EXIT_MONIKER
	applicationsToolMonikerList,	; SMMT_APPLICATIONS_TOOL_MONIKER
	documentsToolMonikerList,	; SMMT_DOCUMENTS_TOOL_MONIKER
	preferencesToolMonikerList,	; SMMT_PREFERENCES_TOOL_MONIKER
	defaultToolMonikerList,		; SMMT_DEFAULT_TOOL_MONIKER
	dialupMonikerList		; SMMT_DIALUP_TOOL_MONIKER

applicationsMonikerList StartMenuMonikerStruct <
	ApplicationsSCMoniker,
	ApplicationsTCMoniker
>
documentsMonikerList StartMenuMonikerStruct <
	DocumentsSCMoniker,
	DocumentsTCMoniker
>
settingsMonikerList StartMenuMonikerStruct <
	SettingsSCMoniker,
	SettingsTCMoniker
>
findMonikerList StartMenuMonikerStruct <
	FindSCMoniker,
	FindTCMoniker
>
helpMonikerList StartMenuMonikerStruct <
	HelpSCMoniker,
	HelpTCMoniker
>
exitMonikerList StartMenuMonikerStruct <
	ExitSCMoniker,
	ExitTCMoniker
>
applicationsToolMonikerList StartMenuMonikerStruct <
	ApplicationsTCMoniker,
	ApplicationsTCMoniker
>
documentsToolMonikerList StartMenuMonikerStruct <
	DocumentsTCMoniker,
	DocumentsTCMoniker
>
preferencesToolMonikerList StartMenuMonikerStruct <
	PreferencesTCMoniker,
	PreferencesTCMoniker
>
defaultToolMonikerList StartMenuMonikerStruct <
	DefaultExpressMenuTCMoniker,
	DefaultExpressMenuTCMoniker
>
dialupMonikerList StartMenuMonikerStruct <
	DialUpTCMoniker,
	DialUpTCMoniker
>

StartMenuGetIconMoniker	proc	near

	CheckHack <length startMenuMonikerTable eq StartMenuMonikerType>
EC <	cmp	ax, StartMenuMonikerType				>
EC <	ERROR_AE -1		; not valid StartMenuMonikerType	>


	shl	ax, 1
	mov	bx, ax
	mov	bx, cs:[startMenuMonikerTable][bx]

	CheckHack <DS_TINY eq 0>

	call	UserGetDisplayType
	test	ah, mask DT_DISP_SIZE
	jz	tiny
	call	CheckIfForceSmallIcons
	jnc	notTiny
tiny:
	add	bx, (size optr)
notTiny:
	mov	di, cs:[bx].offset
	mov	bx, cs:[bx].handle

	ret
StartMenuGetIconMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfForceSmallIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if forcing small icons

CALLED BY:	INTERNAL
PASS:		none
RETURN:		carry set if forcing small icons
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfForceSmallIcons	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	segmov	ds, dgroup, ax
	cmp	ds:[forceSmallIcons], 0x80
	jne	check

	clr	ax				; assume not force small icons
	mov	dx, offset forceSmallIconsKey
	call	checkIniKeyBoolean		; ax = TRUE=0xffff/FALSE=0x0

	shr	ax, 1
	rcl	ds:[forceSmallIcons], 1
check:
	tst	ds:[forceSmallIcons]
	jz	done				; not forcing small icons
	stc					; forcing small icons
done:
	.leave
	ret
CheckIfForceSmallIcons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRunningISUI / CheckIfRunningMotif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if running ISUI / Motif

CALLED BY:	INTERNAL
PASS:		none
RETURN:		z flag set if running ISUI / Motif
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckIfRunningISUI	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	segmov	ds, dgroup, ax
	cmp	ds:[runningISUI], 0x80
	jne	doCheck

	segmov	es, cs
	mov	di, offset isuiName
	mov	ax, 8
	mov	cx, mask GA_LIBRARY
	mov	dx, mask GA_PROCESS or mask GA_DRIVER or mask GA_APPLICATION
	call	GeodeFind

	rcl	ds:[runningISUI], 1
doCheck:
	tst	ds:[runningISUI]			;z flag set if ISUI

	.leave
	ret
CheckIfRunningISUI	endp

CheckIfRunningMotif	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	segmov	ds, dgroup, ax
	cmp	ds:[runningMotif], 0x80
	jne	doCheck

	segmov	es, cs
	mov	di, offset motifName
	mov	ax, 8
	mov	cx, mask GA_LIBRARY
	mov	dx, mask GA_PROCESS or mask GA_DRIVER or mask GA_APPLICATION
	call	GeodeFind

	rcl	ds:[runningMotif], 1
doCheck:
	tst	ds:[runningMotif]			;z flag set if Motif

	.leave
	ret
CheckIfRunningMotif	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRunningISDesk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if running ISDesk

CALLED BY:	INTERNAL
PASS:		none
RETURN:		z flag set if running ISDesk
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckIfRunningISDesk	proc	near
launcherBuf		local	FileLongName

	.enter

	pusha
	push	ds, es
	;
	; See which launcher we're running
	; we can't check the geode in memory because it hasn't loaded yet...
	;
	segmov	ds, cs, cx
	mov	si, offset uiFeaturesCatString
	mov	dx, offset defaultLauncherString
	segmov	es, ss
	lea	di, ss:launcherBuf
	mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, (size launcherBuf)>
	call	InitFileReadString		; es:di - Pointer to string2 for compare

	clr	cx				; cx - Maximum number of characters to compare (0 for NULL terminated).
	segmov	ds, cs
	mov	si, offset ISDeskString		; ds:si - Pointer to string1 for compare.
	call	LocalCmpStrings			; check long name of App: ISDesk
						; **Returns:** ZF - Set if strings were equal.
	pop	ds, es
	popa

	.leave
	ret
CheckIfRunningISDesk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRunningTaskBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if running TaskBar

CALLED BY:	INTERNAL
PASS:		none
RETURN:		ZF if running Taskbar
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckIfRunningTaskBar	proc	near

	.enter

	;
	; is Taskbar running?
	;

	;push	cx, ds, ax, dx, si
	push	ds, si
	mov	cx, cs
	mov	ds, cx

	; **Pass:**
	; ds:si - Category (null-terminated ASCII string) of data within the
	; GEOS.INI file.
	; cx:dx - Key (null-terminated ASCII string) of data within the
	; GEOS.INI file.

	clr	ax
	mov	dx, offset taskBarEnabledString
	mov	si, offset optionsCatString
	call	InitFileReadBoolean
	jc	failed				; if read-in was successful, carry flag is clear
	cmp	ax, TRUE
	jmp	done				; if option is TRUE => ZF is set (= not zero => jnz)

failed:
	test	dx, dx				; sets ZF to zero - we assume taskbar is off

done:
	pop	ds, si

	.leave
	ret

CheckIfRunningTaskBar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRunningMotif95
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if running Motif95

CALLED BY:	INTERNAL
PASS:		none
RETURN:		ZF=1 if running Motif95
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckIfRunningMotif95	proc	near

	.enter
	;pusha

	call	CheckIfRunningMotif
	jnz	done				; jump if zero flag is not set
	call	CheckIfRunningISDesk
	jnz	done				; jump if zero flag is not set
	call	CheckIfRunningTaskBar

done:

	;popa
	.leave
	ret

CheckIfRunningMotif95	endp

if ERROR_CHECK
LocalDefNLString ISDeskString <"EC ISDesk", 0>
else
LocalDefNLString ISDeskString <"ISDesk", 0>
endif

optionsCatString	char	"motif options", 0
taskBarEnabledString	char	"taskBarEnabled", 0
uiFeaturesCatString	char	"uiFeatures", 0
defaultLauncherString	char	"defaultLauncher", 0
isuiName 		char 	"isui    ", 0
motifName 		char 	"motif   ", 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPathIsUnderSP_DOCUMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if path is under SP_DOCUMENT

CALLED BY:	INTERNAL
PASS:		^lbx:si	- object to check path for
RETURN:		carry set if path is under SP_DOCUMENT
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPathIsUnderSP_DOCUMENT	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ss
	mov	bp, sp			; dx:bp = just point somewhere
	clr	cx			; don't want path, just the disk handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	cx, SP_DOCUMENT
	stc				;carry <- set if SP_DOCUMENT
	je	done
	clc				;carry <- clear: not SP_DOCUMENT
done:
	.leave
	ret
CheckIfPathIsUnderSP_DOCUMENT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCombinationMonikerOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a combination graphic+text moniker

CALLED BY:	INTERNAL
PASS:		^hbp	- destination block for combined moniker
		^lbx:di	- optr of icon moniker (VisMoniker)
		^lcx:dx	- optr of text moniker (CreateCombinationMonikerOptr)
		   or
		cx:dx	- fptr to moniker text (CreateCombinationMoniker)
RETURN:		cx	- chunk handle of combined moniker
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateCombinationMonikerOptr	proc	near
	uses	ax, dx, bp
	.enter

	mov	ax, bp			; ^hax = destination

	sub	sp, size CreateIconTextMonikerParams
	mov	bp, sp
	mov	ss:[bp].CITMP_flags, mask CITMF_CREATE_CHUNK
	mov	ss:[bp].CITMP_spacing, 8
	mov	ss:[bp].CITMP_destination, ax
	movdw	ss:[bp].CITMP_iconMoniker, bxdi
	movdw	ss:[bp].CITMP_textMoniker, cxdx
	call	UserCreateIconTextMoniker
	add	sp, size CreateIconTextMonikerParams

	mov	cx, ax

	.leave
	ret
CreateCombinationMonikerOptr	endp

CreateCombinationMoniker	proc	near
	uses	ax,dx,bp
	.enter

	mov	ax, bp			; ^hax = destination

	sub	sp, size CreateIconTextMonikerParams
	mov	bp, sp
	mov	ss:[bp].CITMP_flags, mask CITMF_TEXT_IS_FPTR or \
					mask CITMF_CREATE_CHUNK
	mov	ss:[bp].CITMP_spacing, 8
	mov	ss:[bp].CITMP_destination, ax
	movdw	ss:[bp].CITMP_iconMoniker, bxdi
	movdw	ss:[bp].CITMP_textMoniker, cxdx
	call	UserCreateIconTextMoniker
	add	sp, size CreateIconTextMonikerParams

	mov	cx, ax

	.leave
	ret
CreateCombinationMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMonikerFromFilenameAndToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create graphic+text moniker from filename and GeodeToken

CALLED BY:	INTERNAL
PASS:		es:di - FileLongName + FileID + GeodeToken
		^hbx - destination block
RETURN:		cx -  chunk handle of moniker
		      0 if no moniker created
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMonikerFromFilenameAndToken	proc	near
	uses	ax, bx, dx, si, di, bp
	.enter

	call	ObjSwapLock
	push	bx

	call	UserGetDisplayType	; ah = DisplayType
	call	UserLimitDisplayTypeToStandard
	mov	dh, ah

	push	ds:[LMBH_handle], di
	mov	ax, {word}es:[di+size FileLongName+size FileID].GT_chars[0]
	mov	bx, {word}es:[di+size FileLongName+size FileID].GT_chars[2]
	mov	si, {word}es:[di+size FileLongName+size FileID].GT_manufID

	tstdw	axbx
	jnz	search
	mov	ax, 'Te'
	mov	bx, 'Ed'
	mov	si, MANUFACTURER_ID_GEOWORKS
search:
	mov	cx, ds:[LMBH_handle]
	mov	di, VisMonikerSearchFlags <VMS_TOOL,0,0,1>
	push	di
	clr	di
	push	di
	call	TokenLoadMoniker	; ^lcx:di = icon moniker
	pop	bx, dx			; ^lbx:di = icon moniker

	mov	cx, es			; cx:dx = filename
	call	MemDerefDS
	jc	useDefault

	mov	bp, ds:[di]
	test	ds:[bp].VM_type, mask VMT_GSTRING
	jz	freeAndUseDefault
	cmp	ds:[bp].VM_width, 16
	ja	freeAndUseDefault

	mov	bp, bx
	call	CreateCombinationMoniker

	mov	ax, di			; free icon moniker from token database
	call	LMemFree
	jmp	unlock

freeAndUseDefault:
	mov	ax, di
	call	LMemFree
useDefault:
	mov	bp, bx
	mov	ax, SMMT_DEFAULT_TOOL_MONIKER
	call	StartMenuGetIconMoniker
	call	CreateCombinationMoniker

unlock:
	pop	bx
	call	ObjSwapUnlock

	.leave
	ret
CreateMonikerFromFilenameAndToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjInstantiateForThreadAndSetOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiate an object for thread and set block output

CALLED BY:	INTERNAL
PASS:		es:di - class of new object to instantiate
		^hbx - block to copy obj block output from
RETURN:		^lbx:si	- optr of new object
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjInstantiateForThreadAndSetOutput	proc	near
	uses	cx, dx
	.enter

	call	ObjSwapLock
	movdw	cxdx, ds:[OLMBH_output]
	call	ObjSwapUnlock

	clr	bx
	call	ObjInstantiateForThread

	call	ObjSwapLock
	movdw	ds:[OLMBH_output], cxdx
	call	ObjSwapUnlock

	.leave
	ret
ObjInstantiateForThreadAndSetOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDOSDocumentToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get token for DOS document

CALLED BY:	INTERNAL
PASS:		ds:dx - DOS document filename
		es:di - buffer to store GeodeToken
		carry set to find icon token
		carry clear to find owner token
RETURN:		es:di - filled with GeodeToken
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

filenameTokenCategory	char	"fileManager",0
filenameTokenKey	char	"filenameTokens",0

GetDOSDocumentToken	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	;
	; initialize file extension we are looking for
	;
	mov	{word}es:[di], '  '
	mov	{byte}es:[di+2], ' '
	mov	{byte}es:[di+3], 0		; assume owner token
	jnc	gotFlag
	mov	{byte}es:[di+3], 1		; else, get icon token
gotFlag:
	;
	; figure out the extension of DOS document
	;

	push	di
	mov	si, dx			; ds:si = DOS document filename
extensionLoop:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_PERIOD
	je	foundExtension
	LocalIsNull	ax
	jnz	extensionLoop
	jmp	gotExtension

foundExtension:
	clr	ax
	mov	cx, DOS_FILE_NAME_EXT_LENGTH
copyExtensionLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	gotExtension
	call	LocalUpcaseChar
	LocalPutChar	esdi, ax
	loop	copyExtensionLoop
gotExtension:
	pop	di

	;
	; now find matching token in the 'fileManager::filenameTokens' list
	;

	mov	bx, di				; es:bx = GeodeToken buffer
	mov	cx, cs
	mov	dx, offset filenameTokenKey
	mov	ds, cx
	mov	si, offset filenameTokenCategory
	mov	di, vseg GetDOSDocumentTokenEnumCB
	mov	ax, offset GetDOSDocumentTokenEnumCB
	mov	bp, mask IFRF_READ_ALL
	call	InitFileEnumStringSection
	jc	done

	;
	; default to Text Editor
	;
	mov	{word}es:[bx].GT_chars[0], 'Te'
	mov	{word}es:[bx].GT_chars[2], 'Ed'
	mov	es:[bx].GT_manufID, MANUFACTURER_ID_GEOWORKS
done:
	.leave
	ret
GetDOSDocumentToken	endp

;
; Pass:		ds:si	= String section (null-terminated)
;		dx	= Section #
;		cx	= Length of section
;		es:bx	= GeodeToken buffer
; Return:	es:bx	= GeodeToken buffer updated if token found
;		Carry	= Clear (continue enumeration)
;			= Set (stop enumeration)
; Destroyed:	ax,cx,dx,di,si,bp,ds,es
;
GetDOSDocumentTokenEnumCB	proc	far
	uses	bx
	.enter

	mov	di, bx			; es:di = GeodeToken buffer

	; scan for start of extension in string section
10$:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	noMatch
	LocalCmpChar	ax, C_PERIOD
	je	foundExtension
SBCS <	cmp	al, C_EQUAL						>
DBCS <	cmp	ax, C_EQUALS_SIGN					>
	jne	10$

	; if we're here then we have a blank extension

	cmp	{word}es:[bx], '  '
	jne	noMatch
	cmp	{byte}es:[bx+2], ' '
	jne	noMatch
	jmp	skipIconToken

foundExtension:
	clr	ax
	mov	cx, DOS_FILE_NAME_EXT_LENGTH
extensionLoop:
	LocalGetChar	ax, dssi
SBCS <	cmp	al, C_EQUAL						>
DBCS <	cmp	ax, C_EQUALS_SIGN					>
	jne	20$
	LocalLoadChar	ax, C_SPACE
	LocalPrevChar	dssi
20$:	call	LocalUpcaseChar
SBCS < 	cmp	es:[bx], al						>
DBCS < 	cmp	es:[bx], ax						>
	jne	noMatch
	LocalNextChar	esbx
	loop	extensionLoop

	; we found matching extension, now find C_EQUAL

findEqual:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	noMatch
SBCS <	cmp	al, C_EQUAL						>
DBCS <	cmp	ax, C_EQUALS_SIGN					>
	jne	findEqual

skipIconToken:
	tst	{byte}es:[di+3]		; check icon/creator flag
	jnz	findQuote		; want icon, we're there now

	; find end of icon token chars and icon token manufID

	call	findComma		; token chars
	jnc	noMatch
	call	findComma		; token manufID
	jnc	noMatch

	; find start of app token chars

findQuote:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	noMatch
	LocalCmpChar	ax, C_QUOTE
	jne	findQuote

	; get app token chars (this trashed passed in extension chars. oh well)

	lodsw
	stosw
	lodsw
	stosw

	; get app token manufID

	call	findComma
	call	UtilAsciiToHex32
	stosw
	stc					; got GeodeToken
	jmp	done
noMatch:
	clc
done:
	.leave
	ret

; Pass:		ds:si	= string
; Return:	ds:si	= character after C_COMMA if carry set
;
findComma:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	noComma
	LocalCmpChar	ax, C_COMMA
	jne	findComma
	stc				; found comma
noComma:
	retn

GetDOSDocumentTokenEnumCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressMenuDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to be shut down.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ExpressMenuControl object
		ds:di	= ExpressMenuControlInstance
		cx	= ack ID
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	child block is nuked once everyone on the
		GCNSLT_EXPRESS_MENU_CHANGE list has responded to the
		GCNEMNT_DESTROYED list.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressMenuDetach method dynamic ExpressMenuControlClass, MSG_META_DETACH
	.enter
	;
	; Prepare for delayed detach.
	;
	call	ObjInitDetach
	push	ax, cx, dx, bp
	;
	; Remove ourselves from the GCN list of all express menu objects, and
	; notify all interested parties that we're history.
	;
	call	ExpressMenuControlRemoveFromLists
	;
	; Record a MSG_META_ACK to be sent back by everyone on the list of
	; interested parties.
	;
	movdw	bxsi, cxdx
	mov	ax, MSG_META_ACK
	clr	dx, bp
	mov	di, mask MF_RECORD
	call	ObjMessage

	;
	; Save that handle and the child block's handle in vardata for nuking
	; when DETACH_COMPLETE is received.
	;
	call	EMGetFeaturesAndChildBlock
	mov	dx, bx
	mov	ax, TEMP_EXPRESS_MENU_CONTROL_DETACH_DATA
	mov	cx, size EMCDetachData
	call	ObjVarAddData
	mov	ds:[bx].EMCDD_childBlock, dx
	mov	ds:[bx].EMCDD_ackEvent, di
	;
	; Tell all interested parties to send a MSG_META_ACK back to us.
	;
	push	si
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE or mask MF_RECORD
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_EXPRESS_MENU_CHANGE
	mov	di, mask GCNLSF_FORCE_QUEUE
	call	GCNListRecordAndSend
	pop	si
	;
	; Now up our detach count by the number of those messages actually
	; sent out, so our final detach is delayed until all have responded.
	;
	jcxz	passItUp
incLoop:
	call	ObjIncDetach
	loop	incLoop
passItUp:
	;
	; Skip over GenControl handling of MSG_META_DETACH, we wait until
	; we get MSG_META_DETACH_COMPLETE for that.
	;
	pop	ax, cx, dx, bp
	mov	di, offset GenControlClass
	call	ObjCallSuperNoLock
	;
	; And let the detach proceed.
	;
	call	ObjEnableDetach
	.leave
	ret
ExpressMenuDetach endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressMenuDetachComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the finish of our detach by freeing the recorded
		event and the child block we were safeguarding.

CALLED BY:	MSG_META_DETACH_COMPLETE
PASS:		*ds:si	= ExpressMenuControl object
		cx	= ack ID
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressMenuDetachComplete method dynamic ExpressMenuControlClass, MSG_META_DETACH_COMPLETE
	uses	ax, cx, dx, bp
	.enter
	;
	; set the EMC not usable if we are asked to
	;
	mov	ax, ATTR_EMC_SET_NOT_USABLE_ON_DETACH
	call	ObjVarFindData
	jnc	dontSetNotUsable
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
dontSetNotUsable:
	;
	; then do normal GenControl detach, this unlinks gen and vis stuff,
	; removes from lists, but leaves child block (on assumption that
	; app is exiting and blocks will be freed anyway)
	;
	clr	cx, dx, bp			; no detach ACK
	mov	ax, MSG_META_DETACH
	mov	di, offset ExpressMenuControlClass
	call	ObjCallSuperNoLock		; send to superclass,
						;	not ourselves
	mov	ax, TEMP_EXPRESS_MENU_CONTROL_DETACH_DATA
	call	ObjVarFindData
	jnc	done
	;
	; Fetch the two handles out.
	;
	mov	ax, ds:[bx].EMCDD_childBlock
	mov	cx, ds:[bx].EMCDD_ackEvent
	;
	; Nuke the vardata record.
	;
	call	ObjVarDeleteDataAt
	;
	; Free the recorded ACK event.
	;
	mov	bx, cx
	call	ObjFreeMessage
	;
	; If we didn't set not usable on detach, free the child block, since
	; GenControl won't have done so.  If we did set not usable, it will
	; have been freed by GenControl.
	;
	push	ax				; save child block
	mov	ax, ATTR_EMC_SET_NOT_USABLE_ON_DETACH
	call	ObjVarFindData
	pop	bx				; bx = child block
	jc	childBlockGone
	call	ObjFreeObjBlock
childBlockGone:
done:
	.leave
	mov	di, offset ExpressMenuControlClass
	GOTO	ObjCallSuperNoLock
ExpressMenuDetachComplete endm

;---

ExpressMenuControlRemoveFromLists	proc	near

	; send out notification that we have been destroyed

	mov	cx, ds:[LMBH_handle]		; ^lcx:dx - Express Menu Control
	mov	dx, si
	mov	ax, MSG_NOTIFY_EXPRESS_MENU_CHANGE
	mov	bp, GCNEMNT_DESTROYED
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_EXPRESS_MENU_CHANGE
	mov	di, mask GCNLSF_FORCE_QUEUE	; force queue to avoid potential
						;	deadlocks
	pushdw	cxdx
	call	GCNListRecordAndSend
	popdw	cxdx

	; remove ourselves to list of Express Menu Control objects in the system
	;	^lcx:dx - Express Menu Control

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
	call	GCNListRemove

	; remove ourselves from file change notification list
	;	^lcx:dx - Express Menu Control

	mov	ax, ATTR_EMC_SYSTEM_TRAY
	mov	si, dx
	call	ObjVarFindData
	jc	noFileList
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListRemove
noFileList:
	ret

ExpressMenuControlRemoveFromLists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StorePathInAppList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the passed path in this object's vardata

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI
			CreateOtherAppsList

PASS:		ds = fixup-able object block
		^lbx:si = object in which to store path
		bp = disk handle of path to store
		cx:dx = path to store

RETURN:		carry set if problem storing path

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		broke out of CreateAppList

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StorePathInAppList	proc	near

	uses	ax, cx, dx, bp, di
	.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Copy the path in the stack before sending it to the far routines
	;
		mov	ax, ds
		mov	ds, cx
		xchg	si, dx			;ds:si = path to store
		clr	cx			; null terminated str
		call	SysCopyToStackDSSI	;ds:si = pathname in stack
		mov	cx, ds
		xchg	dx, si			;cx:dx = pathname in stack
		mov	ds, ax			;restore ds
endif
	;
	; set path of passed object to be passed path (used when running
	; applications in list)
	;
		mov	ax, MSG_GEN_PATH_SET
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

	;
	; Restore the stack
	;
FXIP <		call	SysRemoveFromStack				>

	.leave
	ret
StorePathInAppList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAppList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CreateAppList

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI
			EMCInteractionSpecBuildBranch
			EMCInteractionNotifyFileChange


PASS:		ds = fixup-able object block
		^lbx:si = parent to add items to

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_NUM_APPS = 100

calMatchAttrs	FileExtAttrDesc \
	<FEA_GEODE_ATTR, mask GA_APPLICATION, size GeodeAttrs>,
			; no hidden files
	<FEA_FILE_ATTR, mask FA_HIDDEN shl 16, size FileAttrs>,
	<FEA_END_OF_LIST>
calReturnAttrs	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_FILE_ID, size FileLongName, size FileID>,
	<FEA_TOKEN, size FileLongName + size FileID, size GeodeToken>,
	<FEA_END_OF_LIST>

CreateAppList	proc	far

	uses	ax,bx,cx,dx,si,di,bp

parentBlock	local	word	push	bx
parentChunk	local	word	push	si

	.enter

	call	FilePushDir

	;
	; set current directory to stored path
	;
	call	ObjSwapLock		; *ds:si = parent object
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jc	pathError
	;
	; while we are here, store path IDs for file change notification
	;	*ds:si = parent object
	;
	call	StorePathIDs

pathError:
	call	ObjSwapUnlock		; ^lbx:si = parent object
					; (preserves flags)
	LONG	jc	done		; if error, no apps

	push	bp

if FULL_EXECUTE_IN_PLACE
	;
	; We need to copy FileExtAttrDesc array onto the stack
	;
	push	ds, si
	segmov	ds, cs, cx
	mov	si, offset calReturnAttrs	;ds:si = calReturnAttrs
	mov	cx, (size FileExtAttrDesc) * (length calReturnAttrs)
	call	SysCopyToStackDSSI	;ds:si = calReturnAttrs on stack
	mov	di, si			;ds:di = calReturnAttrs on stack
	segmov	ds, cs, cx
	mov	si, offset calMatchAttrs	;ds:si = calMatchAttrs
	mov	cx, (size FileExtAttrDesc) * (length calMatchAttrs)
	call	SysCopyToStackDSSI		;ds:si = calMatchAttrs
endif

	sub	sp, size FileEnumParams
	mov	bp, sp		; ss:bp points at structure
				; Setup params for search
	mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_EXECS
if	FULL_EXECUTE_IN_PLACE
	mov	ss:[bp].FEP_returnAttrs.offset, di
	mov	ss:[bp].FEP_returnAttrs.segment, ds
	mov	ss:[bp].FEP_returnSize, size FileLongName + size FileID + \
					size GeodeToken
	mov	ss:[bp].FEP_matchAttrs.offset, si
	mov	ss:[bp].FEP_matchAttrs.segment, ds
else
	mov	ss:[bp].FEP_returnAttrs.offset, offset calReturnAttrs
	mov	ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_returnSize, size FileLongName + size FileID + \
					size GeodeToken
	mov	ss:[bp].FEP_matchAttrs.offset, offset calMatchAttrs
	mov	ss:[bp].FEP_matchAttrs.segment, cs
endif
	mov	ss:[bp].FEP_bufSize, MAX_NUM_APPS
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum		; bx = buffer, cx = count
if FULL_EXECUTE_IN_PLACE
	pop	ds, si
	lahf
	call	SysRemoveFromStack
	call	SysRemoveFromStack
	sahf
endif

	pop	bp
	jc	done			; if error, no apps
	call	BuildEmptyList
	jc	done
	jcxz	done			; no apps

	call	MemLock
	push	bx
	mov	es, ax
	call	SortAppOrDirMenu
	;
	; go through buffer, adding an app item for each entry
	;	es = buffer
	;	cx = count
	;
	push	cx
	clr	di			; es:di = buffer entry (FileLongName)
fileLoop:
	push	cx, di
	mov	bx, parentBlock		; ^lbx:si = parent for item
	mov	si, parentChunk
	call	AddAppListItem
	pop	cx, di
	add	di, size FileLongName + size FileID + size GeodeToken
	loop	fileLoop
	pop	cx
	;
	; make another pass through buffer to extract FileIDs
	;	es = buffer
	;	cx = count
	;
	mov	bx, parentBlock		; ^lbx:si = parent EMCInteraction
	mov	si, parentChunk
	call	BuildFileIDs

	pop	bx
	call	MemFree			; free file list buffer

done:
	call	FilePopDir

	.leave
	ret
CreateAppList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StorePathIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chunk of path IDs for this object

CALLED BY:	CreateAppList, CreateOtherAppsList

PASS:		*ds:si - EMCInteractionClass object

RETURN:		nothing

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 8/93   	broken out from CreateAppList

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StorePathIDs	proc near

		call	FileGetCurrentPathIDs	; ax = path IDs chunk
		push	bx
		push	ax
	;
	; free current chunk, if any
	;
		mov	ax, TEMP_EMC_INTERACTION_PATH_IDS
		call	ObjVarFindData
		jnc	noFree

		mov	ax, ds:[bx]
		tst	ax
		jz	noFree
		call	LMemFree		; free it
noFree:
					; don't save to state
		mov	ax, TEMP_EMC_INTERACTION_PATH_IDS
		mov	cx, size word
		call	ObjVarAddData
		pop	ds:[bx]			; store path IDs chunk
		pop	bx

		ret
StorePathIDs	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFileIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build array of FileIDs and store in vardata

CALLED BY:	CreateAppList

PASS:		ds = object block
		^lbx:si = EMCInteraction
		es = buffer with FileLongName + FileID + GeodeToken entries
		cx = count of entries in buffer

RETURN:		nothing

DESTROYED:	ax, cx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFileIDs	proc	near
	call	ObjSwapLock		; *ds:si = parent EMCInteraction
.assert (size FileID eq 4)
	shl	cx, 1
	shl	cx, 1			; cx = bytes needed
	mov	al, 0
	call	LMemAlloc
	jc	afterFileIDs		; if error, don't bother
	shr	cx, 1
	shr	cx, 1			; cx = count
	push	bx, cx
	mov	di, ax			; di = chunk handle
	;
	; free current chunk, if any
	;
	mov	ax, TEMP_EMC_INTERACTION_CHILD_FILE_IDS
	call	ObjVarFindData
	jnc	noFree
	clr	ax
	xchg	ax, ds:[bx]		; *ds:ax = file IDs chunk
	tst	ax
	jz	noFree
	call	LMemFree		; free it
noFree:
	mov	ax, TEMP_EMC_INTERACTION_CHILD_FILE_IDS
	mov	cx, size word
	call	ObjVarAddData
	mov	ds:[bx], di
	pop	bx, cx			; bx = ObjSwapLock block, cx = count
	segxchg	ds, es			; ds = buffer, es = parent block (chunk)
	mov	si, size FileLongName	; ds:si = buffer entry (FileID)
	mov	di, es:[di]		; es:di = chunk
fileIDLoop:
	movsw
	movsw
	add	si, size FileLongName + GeodeToken
					; advance to next FileID (already moved
					;	past current FileID)
	loop	fileIDLoop
	segxchg	ds, es			; es = buffer, ds = parent block
afterFileIDs:
	call	ObjSwapUnlock
	ret
BuildFileIDs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildEmptyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build dummy file list block.

CALLED BY:	INTERNAL
			AddAppListItem
			AddDocListItem

PASS:		cx = number of items
		bx = block containing items

RETURN:		carry clear if successful
			bx = file list block
			cx = 1 (number of items in block)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if no files, or only Directory file, allocate dummy one

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildEmptyList	proc	far
		uses	ax, dx, bp, si, di, ds, es
parentBlock	local	word
parentChunk	local	word
		.enter inherit
	;
	; check if parent already has items
	;
		push	bx, cx
		mov	bx, parentBlock
		mov	si, parentChunk
		mov	ax, MSG_GEN_COUNT_CHILDREN
		mov	di, mask MF_CALL
		call	ObjMessage		; dx = child count
		pop	bx, cx
		tst_clc	dx			; already have children?
		LONG jnz	done			; carry clear
	;
	; check number of found items
	;
		tst	cx
		jz	alloc
		cmp	cx, 1
		clc				; no error
		jne	done			; have more than 1 item
	;
	; check if single item is dir file
	;
		call	MemLock
		mov	ds, ax
		clr	si
		segmov	es, cs
		mov	di, offset ndDirName
		push	cx
		clr	cx
		call	LocalCmpStrings
		pop	cx
		call	MemUnlock		; preserves flags
		clc				; no error
		jne	done
		call	MemFree			; free useless list
alloc:
		mov	ax, size FileLongName + size FileID + size GeodeToken
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	done
		mov	es, ax			; es:di = name
		clr	di
		push	bx
		mov	bx, handle NoneText
		call	MemLock
		mov	ds, ax
		mov	si, offset NoneText
		mov	si, ds:[si]
		mov	cx, size FileLongName
		rep movsb
		call	MemUnlock
		pop	bx
		mov	{word}es:[size FileLongName], 0
		mov	{word}es:[size FileLongName+2], 0
		mov	{word}es:[size FileLongName + size FileID], 0xffff
		mov	{word}es:[size FileLongName + size FileID +2], 0xffff
		mov	{word}es:[size FileLongName + size FileID +4], 0xffff
		call	MemUnlock
		mov	cx, 1
done:
		.leave
		ret
BuildEmptyList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddAppListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	AddAppListItem

CALLED BY:	INTERNAL
			CreateAppList

PASS:		^lbx:si = parent for item
		es:di = pointer to FileLongName + FileID + GeodeToken
		ds = fixup-able object block

RETURN:		^lbx:si = new item

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddAppListItem	proc	near
	uses	es, bp

	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	pushdw	bxsi			; save parent object chunk
	pushdw	esdi			; save name

	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	call	ObjInstantiateForThreadAndSetOutput	; ^lbx:si = new trigger

	popdw	esdi			; esdi = filename + fileID + GeodeToken

	; Save the filename as vardata

	call	ObjSwapLock
	push	bx, di

	mov	ax, ATTR_GEN_PATH_DATA
	mov	cx, size GenFilePath
	call	ObjVarAddData
	mov	ds:[bx].GFP_disk, 0
10$:
	LocalGetChar	ax, esdi
SBCS <	mov	ds:[bx].GFP_path, al					>
DBCS <	mov	ds:[bx].GFP_path, ax					>
	LocalNextChar	dsbx
	LocalIsNull	ax
	jnz	10$

	pop	bx, di
	call	ObjSwapUnlock

	; create moniker for item

	mov	ax, es:[di][size FileLongName + size FileID]
	and	ax, es:[di][size FileLongName + size FileID + 2]
	and	ax, es:[di][size FileLongName + size FileID + 4]
	cmp	ax, 0xffff
	je	useText
	call	CreateMonikerFromFilenameAndToken
	jcxz	useText

	push	di
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	jmp	setActionMsg

useText:
	push	di
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	movdw	cxdx, esdi
	mov	bp, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di

setActionMsg:
	mov	ax, es:[di][size FileLongName + size FileID]
	and	ax, es:[di][size FileLongName + size FileID + 2]
	and	ax, es:[di][size FileLongName + size FileID + 4]
	cmp	ax, 0xffff
	je	skipAction
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_EMC_LAUNCH_APPLICATION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
skipAction:

	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, 0
	mov	dx, TO_OBJ_BLOCK_OUTPUT		; ( = controller)
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	push	bp
	sub	sp, size AddVarDataParams + size optr
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ax, bp
	add	ax, size AddVarDataParams
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size optr + size word
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ss:[bp][(size AddVarDataParams)]+0, bx	; cx data
	mov	ss:[bp][(size AddVarDataParams)]+2, si	; dx data
	mov	{word} ss:[bp][(size AddVarDataParams)]+4, 0	; bp data
							; (don't force DA mode)
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams + size optr
	pop	bp

	movdw	cxdx, bxsi		; ^lcx:dx = new trigger
	popdw	bxsi			; ^lbx:si = parent
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST		; not dirty
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	movdw	bxsi, cxdx		; ^lbx:si = new trigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
AddAppListItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDirListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	AddDirListItem

CALLED BY:	INTERNAL
			CreateOtherAppsList

PASS:		^lbx:si = parent for item
		es:di = pointer to FileLongName of directory

RETURN:		^lbx:si = new item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDirListItem	proc	near
	uses	ax,cx,dx,di,bp,es
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	.enter

	pushdw	bxsi			; save parent object optr
	pushdw	esdi			; save name
	mov	di, segment EMCInteractionClass
	mov	es, di
	mov	di, offset EMCInteractionClass
	call	ObjInstantiateForThreadAndSetOutput
					; ^lbx:si = new interaction
	popdw	cxdx			; cxdx = null-terminated name

	call	CheckIfRunningISUI
	jz	notISUI

	movdw	bpax, bxsi		; ^lbp:si = new interaction
	popdw	bxsi			; ^lbx:si = parent interaction
	pushdw	bxsi			; check path in parent interaction
	call	CheckIfPathIsUnderSP_DOCUMENT
	movdw	bxsi, bpax

	push	bx
	mov	ax, SMMT_DOCUMENTS_TOOL_MONIKER
	jc	createMoniker
	mov	ax, SMMT_APPLICATIONS_TOOL_MONIKER
createMoniker:
	call	StartMenuGetIconMoniker	; ^lbx:di = icon moniker
	call	CreateCombinationMoniker
	pop	bx

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_MANUAL
	call	EMCObjMessageCallFixupDS
	jmp	setVisibility

notISUI:
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_MANUAL
	call	EMCObjMessageCallFixupDS

setVisibility:
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	call	EMCObjMessageCallFixupDS

	;
	; If we're running ISUI then add HINT_INFREQUENTLY_USED to
	; get rid of the pin
	;

	call	CheckIfRunningISUI
	jz	notISUI2

	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	clr	ss:[bp].AVDP_dataSize
	mov	ss:[bp].AVDP_dataType, HINT_INFREQUENTLY_USED
	mov	ax, MSG_META_ADD_VAR_DATA
	call	EMCObjMessageCallFixupDS
	add	sp, size AddVarDataParams
notISUI2:

	movdw	cxdx, bxsi		; ^lcx:dx = new interaction
	popdw	bxsi			; ^lbx:si = parent
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST		; not dirty
	call	EMCObjMessageCallFixupDS


	pushdw	bxsi			; save parent chunk
	movdw	bxsi, cxdx		; ^lbx:si = new interaction
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	EMCObjMessageCallFixupDS
	popdw	dxbp			; ^ldx:bp = parent
	;
	; copy custom window hints from parent
	;	^lbx:si = new interaction
	;	^ldx:bp = parent
	;
	xchg	si, bp			; ^ldx:si = parent
					; ^lbx:bp = new interaction
	push	bx			; save new interaction obj block
	call	ObjLockObjBlock
	mov	es, ax			; *es:bp = new interaction
	mov	bx, dx			; ^lbx:si = parent
	push	bx			; save parent obj block
	call	ObjLockObjBlock
	push	ds:[LMBH_handle]	; save ds segment handle
	mov	ds, ax			; *ds:si = parent
.assert (ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY+4 eq ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY)
.assert (ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY+4 eq ATTR_GEN_WINDOW_CUSTOM_PARENT)
	mov	cx, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	mov	dx, ATTR_GEN_WINDOW_CUSTOM_PARENT
	call	ObjVarCopyDataRange
	;
	; Note that when we copy ATTR_GEN_WINDOW_CUSTOM_LAYER_ID (if any)
	; from our parent (the OtherAppsList), the layer id will have been
	; adjusted to be the EMC block handle if it was NULL (in
	; ExpressMenuControlGenerateUI), so we don't have to do that again here
	;
	mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	mov	dx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	call	ObjVarCopyDataRange
	pop	bx			; bx = ds segment handle
	call	MemDerefDS
	pop	bx			; bx = parent obj block
	call	MemUnlock
	pop	bx			; bx = new interaction obj block
	call	MemUnlock
	mov	si, bp			; ^lbx:si = new interaction
	.leave
	ret
AddDirListItem	endp

EMCObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
EMCObjMessageCallFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDocListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	AddDocListItem

CALLED BY:	INTERNAL
			CreateDocumentList

PASS:		^lbx:si = parent for item
		es:di = pointer to FileLongName + FileID + GeodeToken
		ds = fixup-able object block

RETURN:		^lbx:si = new item

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ndDirName	char	"@Directory Information",0

AddDocListItem	proc	near
	uses	es, bp

	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, esdi					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif

	pushdw	bxsi			; save parent object chunk
	pushdw	esdi			; save name

	push	ds, si, cx
	segmov	ds, cs
	mov	si, offset ndDirName
	clr	cx
	call	LocalCmpStrings
	pop	ds, si, cx
	je	cleanupAndExit

	; don't create an item for *.EXE/*.COM/*.BAT

	mov	ax, C_PERIOD
	mov	cx, length FileLongName
	LocalFindChar
	jne	continue

SBCS <	cmp	{word}es:[di], 'EX'				>
SBCS <	jne	checkCOM					>
SBCS <	cmp	{word}es:[di+2], 'E'		; 'E'+NULL	>
SBCS <	jne	continue					>

DBCS <	cmp	{wchar}es:[di], 'E'				>
DBCS <	jne	checkCOM					>
DBCS <	cmp	{wchar}es:[di+(size wchar)], 'X'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+2*(size wchar)], 'E'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+3*(size wchar)], C_NULL		>
DBCS <	jne	continue					>

	jmp	cleanupAndExit

checkCOM:
SBCS <	cmp	{word}es:[di], 'CO'				>
SBCS <	jne	checkBAT					>
SBCS <	cmp	{word}es:[di+2], 'M'		; 'M'+NULL	>
SBCS <	jne	continue					>

DBCS <	cmp	{wchar}es:[di], 'C'				>
DBCS <	jne	checkBAT					>
DBCS <	cmp	{wchar}es:[di+(size wchar)], 'O'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+2*(size wchar)], 'M'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+3*(size wchar)], C_NULL		>
DBCS <	jne	continue					>

	jmp	cleanupAndExit

checkBAT:
SBCS <	cmp	{word}es:[di], 'BA'				>
SBCS <	jne	continue					>
SBCS <	cmp	{word}es:[di+2], 'T'		; 'T'+NULL	>
SBCS <	jne	continue					>

DBCS <	cmp	{wchar}es:[di], 'B'				>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+(size wchar)], 'A'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+2*(size wchar)], 'T'		>
DBCS <	jne	continue					>
DBCS <	cmp	{wchar}es:[di+3*(size wchar)], C_NULL		>
DBCS <	jne	continue					>

cleanupAndExit:
	popdw	esdi				; es:di = name
	;make sure we have non-matching FileID for this filtered item
	mov	{word}es:[di+(size FileLongName)], 0
	mov	{word}es:[di+(size FileLongName)+2], 0
	popdw	bxsi
	jmp	done

continue:
	; create document list item

	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	call	ObjInstantiateForThreadAndSetOutput	; ^lbx:si = new trigger

	popdw	esdi

	mov	ax, es:[di][size FileLongName + size FileID]
	and	ax, es:[di][size FileLongName + size FileID + 2]
	and	ax, es:[di][size FileLongName + size FileID + 4]
	cmp	ax, 0xffff
	je	gotToken
	; If a DOS file (no token), try token mapping
	cmp	{word}es:[di+((size FileLongName)+(size FileID))], 0
	jne	gotToken
	cmp	{word}es:[di+((size FileLongName)+(size FileID))]+2, 0
	jne	gotToken
	push	ds, dx, di
	segmov	ds, es				; ds:dx = filename
	mov	dx, di
	lea	di, es:[di][((size FileLongName)+(size FileID))]
	stc					; find icon token
	call	GetDOSDocumentToken		; fill in GeodeToken, if any
	pop	ds, dx, di
gotToken:

	; Save the filename as vardata

	call	ObjSwapLock
	push	bx, di

	mov	ax, ATTR_GEN_PATH_DATA
	mov	cx, size GenFilePath
	call	ObjVarAddData
	mov	ds:[bx].GFP_disk, 0
10$:
	LocalGetChar	ax, esdi
SBCS <	mov	ds:[bx].GFP_path, al					>
DBCS <	mov	ds:[bx].GFP_path, ax					>
	LocalNextChar	dsbx
	LocalIsNull	ax
	jnz	10$

	pop	bx, di
	call	ObjSwapUnlock

	; create moniker for item

	mov	ax, es:[di][size FileLongName + size FileID]
	and	ax, es:[di][size FileLongName + size FileID + 2]
	and	ax, es:[di][size FileLongName + size FileID + 4]
	cmp	ax, 0xffff
	je	useText
	call	CreateMonikerFromFilenameAndToken
	jcxz	useText

	push	di
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	jmp	setActionMsg

useText:
	push	di
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	movdw	cxdx, esdi
	mov	bp, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di

setActionMsg:
	mov	ax, es:[di][size FileLongName + size FileID]
	and	ax, es:[di][size FileLongName + size FileID + 2]
	and	ax, es:[di][size FileLongName + size FileID + 4]
	cmp	ax, 0xffff
	je	skipAction
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_EMC_OPEN_DOCUMENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
skipAction:

	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, 0
	mov	dx, TO_OBJ_BLOCK_OUTPUT		; ( = controller)
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	push	bp
	sub	sp, size AddVarDataParams + size optr
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ax, bp
	add	ax, size AddVarDataParams
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size optr + size word
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ss:[bp][(size AddVarDataParams)]+0, bx	; cx data
	mov	ss:[bp][(size AddVarDataParams)]+2, si	; dx data
	mov	{word} ss:[bp][(size AddVarDataParams)]+4, 0	; bp data
							; (don't force DA mode)
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams + size optr
	pop	bp

	movdw	cxdx, bxsi		; ^lcx:dx = new trigger
	popdw	bxsi			; ^lbx:si = parent
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST		; not dirty
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	movdw	bxsi, cxdx		; ^lbx:si = new trigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
AddDocListItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareFileLongName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two FileLongNames (null terminated) in
		FileLongName + FileID + GeodeToken element

CALLED BY:	GLOBAL
PASS:		ds:si - first array element
		es:di - second array element
		(es:di and ds:si *cannot* be in the movable XIP resources.)
RETURN:		flags set so caller can jl, je, or jg if first element is
		less than, equal, or greater than second element.
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompareFileLongName	proc	far
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	clr	cx
	call	LocalCmpStrings
	je	exit
	mov	bx, 1
	mov	ax, 0
	jb	doCompareExit
	xchg	ax, bx
doCompareExit:
	cmp	ax, bx
exit:
	ret
CompareFileLongName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortAppOrDirMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sorts the app menu entries alphabetically.

CALLED BY:	GLOBAL
PASS:		es:0 - ptr to block
		cx - # files in block
RETURN:		nada
DESTROYED:	si, di, cx, bx, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SortAppOrDirMenu	proc	near	uses	cx, bp, ds
	params	local	QuickSortParameters
	.enter
	segmov	ds, es
	clr	si
	mov	ax, size FileLongName + size FileID + size GeodeToken
	mov	params.QSP_compareCallback.segment, SEGMENT_CS
	mov	params.QSP_compareCallback.offset, offset CompareFileLongName
	clr	params.QSP_lockCallback.segment
	clr	params.QSP_unlockCallback.segment
	mov	params.QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	params.QSP_medianLimit, DEFAULT_MEDIAN_LIMIT
	call	ArrayQuickSort
	.leave
	ret
SortAppOrDirMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateOtherAppsList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the "Other" list, which has EMCInteractionClass
		objects as children, rather than triggers.

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI
			EMCInteractionNotifyFileChange

PASS:		ds = fixup-able object block
		^lbx:si = parent to add items to

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Only works if passed path to search (cx:dx) is null

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_NUM_APP_DIRS = 25

coalReturnAttrs	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_FILE_ID, size FileLongName, size FileID>,
	<FEA_TOKEN, size FileLongName + size FileID, size GeodeToken>,
	<FEA_END_OF_LIST>

CreateOtherAppsList	proc	far

	uses	ax,bx,cx,dx,si,di,bp

parent		local	optr	push	bx, si
currentPath	local	GenFilePath
currentPathEnd	local	word		; offset to end of currentPath

	.enter

	call	FilePushDir

	;
	; set current directory to stored path
	;
	call	ObjSwapLock		; *ds:si = parent object
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jc	pathError
	;
	; while we are here, store path IDs for file change notification
	;	*ds:si = parent object
	;
	call	StorePathIDs

pathError:
	call	ObjSwapUnlock		; ^lbx:si = parent object
					; (preserves flags)
	LONG	jc	done		; if error, no apps

	push	bp

if FULL_EXECUTE_IN_PLACE
	;
	; Copy the data used by file enum to stack.
	;
	push	ds, si
	segmov	ds, cs, cx
	mov	si, offset coalReturnAttrs	;ds:si= coalReturnAttrs
	mov	cx, (size FileExtAttrDesc) * (length coalReturnAttrs)
	call	SysCopyToStackDSSI		;ds:si = data on stack
endif

	sub	sp, size FileEnumParams
	mov	bp, sp		; ss:bp points at structure
				; Setup params for search
		mov	ss:[bp].FEP_searchFlags, mask FESF_DIRS
if FULL_EXECUTE_IN_PLACE
	mov	ss:[bp].FEP_returnAttrs.offset, si
	mov	ss:[bp].FEP_returnAttrs.segment, ds
else
	mov     ss:[bp].FEP_returnAttrs.offset, offset coalReturnAttrs
	mov     ss:[bp].FEP_returnAttrs.segment, cs
endif
	mov	ss:[bp].FEP_returnSize, size FileLongName + size FileID + \
					size GeodeToken
	mov	ss:[bp].FEP_matchAttrs.offset, 0
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, MAX_NUM_APP_DIRS
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum		; bx = buffer, cx = count

if  FULL_EXECUTE_IN_PLACE
	pop	ds, si		;restore regs
	lahf			;save the flags
	call	SysRemoveFromStack
	sahf			;restore the flags
endif
	pop	bp
	LONG jc	done			; if error, no app dirs
	LONG jcxz done			; no app dirs

	;
	; setup current path
	;
	push	ds, si, es, di, bx, cx
	segmov	ds, ss
	lea	si, currentPath.GFP_path
	mov	cx, size currentPath.GFP_path
	call	FileGetCurrentPath
	mov	currentPath.GFP_disk, bx
	segmov	es, ds
	mov	di, si
	LocalStrSize			; es:di = 1 character past NULL
	LocalPrevChar esdi		; es:di = NULL
	mov	ax, C_BACKSLASH
	LocalPutChar esdi, ax
	mov	currentPathEnd, di
	pop	ds, si, es, di, bx, cx

	;
	; loop through list of directories
	;
	call	MemLock
	push	bx
	mov	es, ax
	call	SortAppOrDirMenu
	push	cx			; save file count
	clr	di			; es:di = buffer entry (FileLongName)
dirLoop:
	push	cx
	;
	; skip if Desk Accessory directory
	;
	push	ds, di
	call	LockDAPathname		; cx:dx = desk accessory pathname
	mov	ds, cx
	mov	si, dx			; ds:si = desk accessory pathname
	ChunkSizePtr	ds, si, cx	; cx = length
	repe cmpsb
	call	UnlockDAPathname	; (preserves flags)
	pop	ds, di
	je	dirNext

	movdw	bxsi, parent		; ^lbx:si = parent for item
	call	AddDirListItem		; ^lbx:si = new dir item

	push	ds, si, es, di
	segmov	ds, es
	mov	si, di
	segmov	es, ss
	mov	di, currentPathEnd
	LocalCopyString
	pop	ds, si, es, di

	push	bp
	mov	cx, ss
	lea	dx, currentPath.GFP_path
	mov	bp, currentPath.GFP_disk
	call	StorePathInAppList	; store path, build when menu opened
	;
	; if error storing path, remove this dir entry
	;
	jnc	dirOkay
	push	di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
dirOkay:
	pop	bp			; (EMCInteractionSpecBuildBranch)
dirNext:
	pop	cx
	add	di, size FileLongName + size FileID + size GeodeToken
	loop	dirLoop
	pop	cx			; cx = file count
	;
	; make another pass through buffer to extract FileIDs
	;	es = buffer
	;	cx = count
	;
	movdw	bxsi, parent		; ^lbx:si = parent EMCInteraction
	call	BuildFileIDs

	pop	bx
	call	MemFree			; free file list buffer
done:
	call	FilePopDir

	.leave
	ret
CreateOtherAppsList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDocumentList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the "Documents" list, which has triggers (documents)
		and EMCInteractionClass (folders) objects as children.

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI
			EMCInteractionNotifyFileChange

PASS:		ds = fixup-able object block
		^lbx:si = parent to add items to

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Only works if passed path to search (cx:dx) is null

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

cdlMatchAttrs	FileExtAttrDesc \
	<FEA_FILE_ATTR, (mask FA_HIDDEN or mask FA_SUBDIR) shl 16, \
	 size FileAttrs>,
	<FEA_END_OF_LIST>
cdlReturnAttrs	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_FILE_ID, size FileLongName, size FileID>,
	<FEA_TOKEN, size FileLongName + size FileID, size GeodeToken>,
	<FEA_END_OF_LIST>

CreateDocumentList	proc	far

	uses	ax,bx,cx,dx,si,di,bp

parentBlock	local	word	push	bx
parentChunk	local	word	push	si

	.enter

	call	FilePushDir

	;
	; first create list of subdirectories
	;
	call	CreateOtherAppsList	; this creates a list of subdirs

	;
	; set current directory to stored path
	;
	call	ObjSwapLock		; *ds:si = parent object
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jc	pathError
	;
	; while we are here, store path IDs for file change notification
	;	*ds:si = parent object
	;
	call	StorePathIDs

pathError:
	call	ObjSwapUnlock		; ^lbx:si = parent object
	LONG jc	done			; if error, no docs

	push	bp

if FULL_EXECUTE_IN_PLACE
	;
	; Copy the data used by file enum to stack.
	;
	push	ds, si
	segmov	ds, cs, cx
	mov	si, offset cdlReturnAttrs	;ds:si = cdlReturnAttrs
	mov	cx, (size FileExtAttrDesc) * (length cdlReturnAttrs)
	call	SysCopyToStackDSSI		;ds:si = data on stack
	mov	di, si				;ds:di = cdlReturnAttrs
	segmov	ds, cs, cx
	mov	si, offset cdlMatchAttrs	;ds:si = cdlMatchAttrs
	mov	cx, (size FileExtAttrDesc) * (length cdlMatchAttrs)
	call	SysCopyToStackDSSI		;ds:si = cdlMatchAttrs
endif

	sub	sp, size FileEnumParams
	mov	bp, sp		; ss:bp points at structure
				; Setup params for search
	mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_NON_EXECS or \
					 mask FESF_NON_GEOS
if FULL_EXECUTE_IN_PLACE
	mov	ss:[bp].FEP_returnAttrs.offset, di
	mov	ss:[bp].FEP_returnAttrs.segment, ds
	mov	ss:[bp].FEP_matchAttrs.offset, si
	mov	ss:[bp].FEP_matchAttrs.segment, ds
else
	mov     ss:[bp].FEP_returnAttrs.offset, offset cdlReturnAttrs
	mov     ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_matchAttrs.offset, offset cdlMatchAttrs
	mov	ss:[bp].FEP_matchAttrs.segment, cs
endif
	mov	ss:[bp].FEP_returnSize, size FileLongName + size FileID + \
					size GeodeToken
	mov	ss:[bp].FEP_bufSize, MAX_NUM_APPS
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum		; bx = buffer, cx = count
if  FULL_EXECUTE_IN_PLACE
	pop	ds, si			;restore regs
	lahf				;save the flags
	call	SysRemoveFromStack
	call	SysRemoveFromStack
	sahf				;restore the flags
endif
	pop	bp
	jc	done			; if error, no app dirs
	call	BuildEmptyList
	jc	done
	jcxz	done			; no app dirs

	call	MemLock
	push	bx
	mov	es, ax
	call	SortAppOrDirMenu
	push	cx			; save file count
	clr	di			; es:di = buffer entry (FileLongName)
dirLoop:
	push	cx, di
	mov	bx, parentBlock		; ^lbx:si = parent for item
	mov	si, parentChunk
	call	AddDocListItem		; ^lbx:si = new dir item
	pop	cx, di			; es:di = name of dir
	add	di, size FileLongName + size FileID + size GeodeToken
	loop	dirLoop
	pop	cx			; cx = file count
	;
	; make another pass through buffer to extract FileIDs
	;	es = buffer
	;	cx = count
	;
	mov	bx, parentBlock		; ^lbx:si = parent EMCInteraction
	mov	si, parentChunk
	call	BuildFileIDs

	pop	bx
	call	MemFree			; free file list buffer

done:
	call	FilePopDir

	.leave
	ret
CreateDocumentList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAppOrDocList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the "Documents" list, which has triggers (documents)
		and EMCInteractionClass (folders) objects as children.

CALLED BY:	INTERNAL
			ExpressMenuControlGenerateUI
			EMCInteractionNotifyFileChange

PASS:		ds = fixup-able object block
		^lbx:si = parent to add items to

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Only works if passed path to search (cx:dx) is null

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAppOrDocList	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	CheckIfPathIsUnderSP_DOCUMENT
	jc	docList

	call	CreateAppList
	jmp	done
docList:
	call	CreateDocumentList
done:
	.leave
	ret
CreateAppOrDocList	endp


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlExitToDOS

DESCRIPTION:	Exit to DOS

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_EXIT_TO_DOS

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/4/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlExitToDOS	method	dynamic ExpressMenuControlClass,
						MSG_EMC_EXIT_TO_DOS
	;
	; send up to field (assumes Express menu is generically below some
	; field
	;
	push	si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	pop	si
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	ret
ExpressMenuControlExitToDOS	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlOpenFloatingKbd

DESCRIPTION:	Open floating keyboard.

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_OPEN_FLOATING_KBD

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/4/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlOpenFloatingKbd	method	dynamic ExpressMenuControlClass,
						MSG_EMC_OPEN_FLOATING_KBD
	;
	; go through flow object
	;
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_HARD_ICON_BAR_FUNCTION
	mov	bp, HIBF_DISPLAY_FLOATING_KEYBOARD
	mov	di, mask MF_FORCE_QUEUE	; force queue to regain app focus
	call	UserCallFlow
	ret
ExpressMenuControlOpenFloatingKbd	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlSelectGEOSTaskListItem

DESCRIPTION:	Select item in GEOS Tasks list

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_SELECT_GEOS_TASKS_LIST_ITEM

	cx - identifier of selected item
	dx - ?
	bp - number of items selected

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/4/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlSelectGEOSTaskListItem	method	dynamic ExpressMenuControlClass,
					MSG_EMC_SELECT_GEOS_TASKS_LIST_ITEM
	tst	bp
	jz	done				; no selections, done
						; ax= features,bx = child block
	call	EMGetFeaturesAndEnsureChildBlock
	test	ax, mask EMCF_GEOS_TASKS_LIST
	jz	done				; GEOS tasks list not supported

	; Send notification to the entry itself.  Custom class should handle
	; this message.
	;
	mov	si, cx				; ^lbx:si = selected item
	mov	cx, bx				; ^lcx:dx = selected item
	mov	dx, si
	call	ObjSwapLock			; *ds:si  = selected item
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock
done:
	ret
ExpressMenuControlSelectGEOSTaskListItem	endm


;
; Code for EMCPanelInteractionClass
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCPanelInteractionAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a child to the EMCPanelInteraction

CALLED BY:	MSG_EMC_PANEL_ADD_CHILD
PASS:		*ds:si	= EMCPanelInteractionClass object
		ds:di	= EMCPanelInteractionClass instance data
		ds:bx	= EMCPanelInteractionClass object (same as *ds:si)
		es 	= segment of EMCPanelInteractionClass
		ax	= message #
		^lcx:dx = child object to add
		bp	= CreateExpressMenuControlItemPriority
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCPanelInteractionAddChild	method dynamic EMCPanelInteractionClass,
					MSG_EMC_PANEL_ADD_CHILD
	.assert	(CEMCIP_STANDARD_PRIORITY eq CCO_LAST)
	cmp	bp, CEMCIP_STANDARD_PRIORITY
	je	addChild

	; save CreateExpressMenuControlItemPriority in vardata

	push	si, cx
	movdw	bxsi, cxdx		; ^lbx:si = child object
	call	ObjSwapLock		; *ds:si = child object
	push	bx
	mov	ax, TEMP_GEN_EMC_PANEL_ITEM_PRIORITY
	mov	cx, size CreateExpressMenuControlItemPriority
	call	ObjVarAddData
	mov	ds:[bx], bp
	pop	bx
	call	ObjSwapUnlock
	pop	si, cx

	; process children to find position to add new item

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
NOFXIP<	push	cs			;push call-back routine	>
FXIP <	mov	bx, SEGMENT_CS					>
FXIP <	push	bx						>
	mov	bx, offset EMCPanelInteractionProcessChild
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	; if carry set, returns ^lax:bp =
	jc	findChild		;  object to add in front of

	mov	bp, CEMCIP_STANDARD_PRIORITY
	jmp	short addChild

	; add new child in front of ^lax:bp
findChild:
	push	cx, dx
	movdw	cxdx, axbp
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock	; returns bp = position of ^lcx:dx
	pop	cx, dx
EC <	ERROR_C -1			; this should never happen!!!	>

addChild:
	mov	ax, MSG_GEN_ADD_CHILD
	GOTO	ObjCallInstanceNoLock

EMCPanelInteractionAddChild	endm

;
; PASS:		*ds:si = child
;		*es:di = composite
;		bp - CreateExpressMenuControlItemPriority
; RETURN:	carry - set to end processing
;			ax, cx, dx, bp - data to send to next child
;		Destroy: bx, si, di, ds, es
;
EMCPanelInteractionProcessChild	proc	far
	mov	ax, TEMP_GEN_EMC_PANEL_ITEM_PRIORITY
	call	ObjVarFindData
	jnc	endProcessing

	cmp	bp, ds:[bx]		; compare priorities
	jl	endProcessing		; end processing if new item has lower
					;  priority number
	ret				; return carry clear to continue

endProcessing:
	mov	ax, ds:[LMBH_handle]	; ^lax:bp = child to insert new item
	mov	bp, si			; 	    in front of
	stc				; return carry set to end processing
	ret
EMCPanelInteractionProcessChild	endp

;
; Code for EMCInteractionClass
;


COMMENT @----------------------------------------------------------------------

METHOD:		EMCInteractionSpecBuildBranch

DESCRIPTION:	Build application submenu

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_SPEC_BUILD_BRANCH

	cx, dx, bp - MSG_SPEC_BUILD_BRANCH params

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/92	Initial version

------------------------------------------------------------------------------@
EMCInteractionSpecBuildBranch	method	dynamic EMCInteractionClass,
					MSG_SPEC_BUILD_BRANCH

	mov	ax, TEMP_EMC_INTERACTION_APPS_BUILT
	call	ObjVarFindData
	jc	callSuper

	test	bp, mask SBF_WIN_GROUP
	jz	callSuper

	push	cx, dx, bp

	clr	cx
	call	ObjVarAddData

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	;
	; first build list
	;
	push	si, es
	mov	bx, ds:[LMBH_handle]	; ^lbx:si = parent object to build
					;  app list for (using stored path)
	call	CreateAppOrDocList
	pop	si, es

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	pop	cx, dx, bp

callSuper:
	;
	; THEN, let superclass open menu
	;
	mov	ax, MSG_SPEC_BUILD_BRANCH
	mov	di, offset EMCInteractionClass
	call	ObjCallSuperNoLock

	ret
EMCInteractionSpecBuildBranch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCInteractionFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free path IDs chunk

CALLED BY:	MSG_META_FINAL_OBJ_FREE

PASS:		*ds:si	= EMCInteractionClass object
		ds:di	= EMCInteractionClass instance data
		es 	= segment of EMCInteractionClass
		ax	= MSG_META_FINAL_OBJ_FREE

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/16/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCInteractionFinalObjFree	method	dynamic	EMCInteractionClass,
						MSG_META_FINAL_OBJ_FREE

	mov	ax, TEMP_EMC_INTERACTION_PATH_IDS
	call	ObjVarFindData
	jnc	afterPathIDs
	clr	ax
	xchg	ax, ds:[bx]		; *ds:ax = path IDs chunk
	tst	ax
	jz	callSuper
	call	LMemFree		; free it
afterPathIDs:

	mov	ax, TEMP_EMC_INTERACTION_CHILD_FILE_IDS
	call	ObjVarFindData
	jnc	afterFileIDs
	clr	ax
	xchg	ax, ds:[bx]		; *ds:ax = file IDs chunk
	tst	ax
	jz	callSuper
	call	LMemFree		; free it
afterFileIDs:

callSuper:
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset EMCInteractionClass
	GOTO	ObjCallSuperNoLock

EMCInteractionFinalObjFree	endm

;
; Code for EMCTriggerClass
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCTriggerLaunchApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch application

CALLED BY:	MSG_EMC_TRIGGER_LAUNCH_APPLICATION

PASS:		*ds:si - EMCTriggerClass object
		ds:di - EMCTriggerClass instance data
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCTriggerLaunchApplication	method	dynamic	EMCTriggerClass,
					MSG_EMC_TRIGGER_LAUNCH_APPLICATION
token		local	GeodeToken	push	bp, dx, cx
albHandle	local	hptr		push	0
tokenHandle	local	hptr		push	0
	.enter

	;
	; create AppLaunchBlock
	;
	mov	ax, size AppLaunchBlock
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	LONG jc	done

	mov	ss:[albHandle], bx
	mov	ds, ax
	mov	ds:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE

	;
	; get GeodeToken of app to launch to a block
	;

	mov	ax, size GeodeToken + size FileLongName
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jc	freeALB

	mov	ss:[tokenHandle], bx	; save handle
	mov	es, ax			; es = GeodeTokenBlock

	mov	ax, {word}ss:[token].GT_chars[0]
	mov	{word}es:[GT_chars][0], ax
	mov	{word}es:[(size GeodeToken)+GT_chars][0], ax

	mov	ax, {word}ss:[token].GT_chars[2]
	mov	{word}es:[GT_chars][2], ax
	mov	{word}es:[(size GeodeToken)+GT_chars][2], ax

	mov	ax, ss:[token].GT_manufID
	mov	es:[GT_manufID], ax
	;
	; open document on another thread
	;
	push	bp
	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	bx, handle 0
	mov	cx, segment EMCThreadClass
	mov	dx, offset EMCThreadClass
	mov	bp, 2048		; stack size for launching apps
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = new thread handle
	pop	bp
	jc	freeToken

	mov	bx, ax			; bx = new thread handle
	mov	al, PRIORITY_UI
	mov	ah, mask TMF_BASE_PRIO	; High prio for temporary thread
	call	ThreadModify

	push	bp
	mov	cx, ss:[tokenHandle]	; cx = GeodeToken block
	mov	dx, ss:[albHandle]	; dx = AppLaunchBlock
	mov	ax, MSG_EMC_THREAD_LAUNCH_APPLICATION
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp
	jmp	done

freeToken:
	mov	bx, ss:[tokenHandle]
	tst	bx
	jz	freeALB
	call	MemFree			; free GeodeToken block
freeALB:
	mov	bx, ss:[albHandle]
	tst	bx
	jz	done
	call	MemFree			; free AppLaunchBlock
done:
	.leave
	ret
EMCTriggerLaunchApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCTriggerLowerToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lower to bottom

CALLED BY:	MSG_GEN_LOWER_TO_BOTTOM

PASS:		*ds:si - EMCTriggerClass object
		ds:di - EMCTriggerClass instance data
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCTriggerLowerToBottom	method	dynamic EMCTriggerClass,
					MSG_GEN_LOWER_TO_BOTTOM
	push	si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	mov	cx, di
	GOTO	GenCallParent

EMCTriggerLowerToBottom	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlLaunchApplication

DESCRIPTION:	Launch application whose trigger is passed

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_LAUNCH_APPLICATION

	^lcx:dx	- trigger for application that we wish to launch
	bp - non-zero to force launching application as desk accessory

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version
	brianc	11/16/92	Use IACP

------------------------------------------------------------------------------@
ExpressMenuControlLaunchApplication	method	dynamic ExpressMenuControlClass,
						MSG_EMC_LAUNCH_APPLICATION

triggerHandle	local	word	push	cx
triggerChunk	local	word	push	dx
appPath		local	PathName
appDiskHandle	local	word
appNameOffset	local	word
appTokenBlock	local	word
appLaunchBlock	local	word

	.enter

	mov	appTokenBlock, 0	; in case of error
	mov	appLaunchBlock, 0	; in case of error
	call	FilePushDir
	;
	; get gen-parent of GenTrigger to get it's path
	;
	movdw	bxsi, cxdx		; ^lbx:si = GenTrigger
	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ^lcx:dx = gen parent

	movdw	bxsi, cxdx		; ^lbx:si = gen parent
	push	bp
	mov	cx, size appPath
	mov	dx, ss			; dx:bp = buffer
	lea	bp, appPath
	mov	ax, MSG_GEN_PATH_GET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	LONG jc	done			; if error, don't launch
	mov	appDiskHandle, cx	; save disk handle

	;
	; set path as current directory, so we can get token
	;
	mov	bx, cx			; bx = disk handle
	segmov	ds, ss			; ds:dx = path
	lea	dx, appPath
	call	FileSetCurrentPath
	pushf				; save error flag
	;
	; tack on filename to end of path
	;
	segmov	es, ss
	lea	di, appPath
SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
	LocalFindChar			; find end of path
	LocalPrevChar	esdi		; es:di = null
	lea	ax, appPath
	cmp	di, ax			; beginning of buffer?
	je	bufferReady		; yes, stick app name here
SBCS <	cmp	{byte} es:[di-1], C_BACKSLASH				>
DBCS <	cmp	{wchar} es:[di-2], C_BACKSLASH				>
	je	bufferReady		; yes, stick app name here
	LocalLoadChar	ax, C_BACKSLASH
	LocalPutChar	esdi, ax	; else, append slash
bufferReady:
	mov	appNameOffset, di	; save for error reporting

	mov	bx, triggerHandle	; ^lbx:si = gen parent
	mov	si, triggerChunk
	call	ObjSwapLock
	push	bx

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	si, ds:[bx].GFP_path
	mov	cx, size FileLongName
	rep	movsb

	pop	bx
	call	ObjSwapUnlock

	segmov	ds, ss
	mov	dx, ss:[appNameOffset]	; ds:dx = app name
	popf				; restore change path error flag
	mov	ax, GLE_FILE_NOT_FOUND	; use this error in case path error
	LONG jc	reportError		; path error
	;
	; get GeodeToken of app to launch to a block
	;
	mov	cx, (mask HAF_LOCK shl 8) or mask HF_SHARABLE or mask HF_SWAPABLE
	mov	ax, size GeodeToken + size FileLongName
	call	MemAlloc		; bx = handle, ax = segment
	jc	memError		; if error, report it (use mem error)
	mov	appTokenBlock, bx	; save handle
	mov	es, ax
	clr	di			; es:di = GeodeToken buffer
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	call	FileGetPathExtAttributes	; get GeodeToken
	mov	ax, GLE_FILE_NOT_FOUND	; in case of ext attr error, use this
	LONG jc	reportError		; if ext attr error, report it now
	;
	; copy in the name of the app, also, for error reporting purposes
	;
	mov	si, appNameOffset	; ds:si = app name
	mov	di, size GeodeToken
SBCS <	mov	cx, size FileLongName					>
SBCS <	rep movsb							>
DBCS <	mov	cx, length FileLongName					>
DBCS <	rep	movsw							>
	call	MemUnlock
	lea	si, appPath		; ds:si = app pathname
	clr	cx			; Use default mode
	clr	dx			; No data file, no state file
	mov	ah, mask ALF_OVERRIDE_MULTIPLE_INSTANCE
					; normal launch mode, but if app
					;  already running, just bring it
					;  up, don't ask the user if s/he
					;  wants to start a new instance
	mov	bx, appDiskHandle	; bx = disk handle
	push	bp
	clrdw	dibp			; use default gen parent
	call	PrepAppLaunchBlock	; dx = AppLaunchBlock
	pop	bp
memError:
					; in case of ALB error, use this
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jc	reportError		; if ALB error, report it now

	mov	appLaunchBlock, dx	; save AppLaunchBlock

	cmp	{word} ss:[bp], 0	; check force-DA flag
	je	dontForceDA
	mov	bx, dx			; bx = AppLaunchBlock
	call	MemLock
	mov	es, ax			; es = AppLaunchBlock
	ornf	es:[ALB_launchFlags], mask ALF_DESK_ACCESSORY
	call	MemUnlock
dontForceDA:

	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	bx, handle 0
	mov	cx, segment EMCThreadClass
	mov	dx, offset EMCThreadClass
	push	bp
	mov	bp, 2048		; stack size for launching apps
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = new thread handle
	pop	bp
	jc	memError		; if error, report it
	mov	bx, ax			; bx = new thread handle
	mov	al, PRIORITY_UI
	mov	ah, mask TMF_BASE_PRIO	; High prio for temporary thread
	call	ThreadModify
	mov	cx, appTokenBlock	; cx = GeodeToken block
	mov	dx, appLaunchBlock	; dx = AppLaunchBlock
	mov	ax, MSG_EMC_THREAD_LAUNCH_APPLICATION
	mov	di, mask MF_FORCE_QUEUE
	push	bp
	call	ObjMessage
	pop	bp
	jmp	short done

reportError:
	mov	di, offset GEOSExecErrorTextOne
	mov	si, appNameOffset	; ds:si = app name
	push	bp
	call	ReportLoadAppError
	pop	bp
	mov	bx, appTokenBlock
	tst	bx
	jz	80$
	call	MemFree			; free GeodeToken block
80$:
	mov	bx, appLaunchBlock
	tst	bx
	jz	done
	call	MemFree			; free AppLaunchBlock
done:
	call	FilePopDir
	.leave
	ret
ExpressMenuControlLaunchApplication	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlOpenDocument

DESCRIPTION:	Open document whose trigger is passed

PASS:
	*ds:si - instance data
	es - segment of class
	ax - MSG_EMC_OPEN_DOCUMENT
	^lcx:dx	- trigger for document that we wish to open

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version
	brianc	11/16/92	Use IACP

------------------------------------------------------------------------------@
ExpressMenuControlOpenDocument	method	dynamic ExpressMenuControlClass,
						MSG_EMC_OPEN_DOCUMENT
trigger		local	optr	push	cx, dx
appLaunchBlock	local	word
docTokenBlock	local	word
	.enter

	call	FilePushDir
	;
	; setup docTokenBlock and appLaunchBlock in case of error
	;
	clr	appLaunchBlock
	clr	docTokenBlock
	;
	; create AppLaunchBlock
	;
	mov	ax, size AppLaunchBlock
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	LONG jc	done

	mov	appLaunchBlock, bx
	mov	es, ax
	;
	; get document filename
	;
	movdw	bxsi, trigger		; ^lbx:si = GenTrigger
	call	ObjLockObjBlock
	push	bx

	mov	ds, ax
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	si, ds:[bx].GFP_path
	mov	di, offset ALB_dataFile
	mov	cx, size FileLongName
	rep	movsb

	pop	bx
	call	MemUnlock

	segmov	ds, es			; ds = es = AppLaunchBlock
	;
	; get path of document
	;
	push	bp
	movdw	bxsi, trigger		; ^lbx:si = GenTrigger
	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL
	call	ObjMessage

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ds
	mov	bp, offset ALB_path
	mov	cx, size ALB_path
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	LONG jc	fileError

	mov	ds:[ALB_diskHandle], cx	; save disk handle
	mov	ds:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	;
	; get GeodeToken of app to launch to a block
	;
	mov	ax, size GeodeToken + size FileLongName
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	LONG jc	memError

	mov	docTokenBlock, bx	; save handle
	mov	es, ax			; es = GeodeTokenBlock
	;
	; set path as current directory, so we can get token
	;
	mov	bx, ds:[ALB_diskHandle]	; bx = disk handle
	mov	dx, offset ALB_path	; ds:dx = path
	call	FileSetCurrentPath

	clr	di			; es:di = GeodeToken buffer
	mov	ax, FEA_CREATOR
	mov	cx, size GeodeToken
	mov	dx, offset ALB_dataFile
	call	FileGetPathExtAttributes ; get GeodeToken
	jnc	copyToken

	cmp	ax, ERROR_ATTR_NOT_FOUND
	jne	fileError

	clc				; find owner token
	call	GetDOSDocumentToken

copyToken:
	;
	; copy ALB_dataFile for error reporting
	;
	push	si
	mov	si, offset ALB_dataFile
	mov	di, size GeodeToken
	LocalCopyString
	pop	si
	;
	; open document on another thread
	;
	push	bp
	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	bx, handle 0
	mov	cx, segment EMCThreadClass
	mov	dx, offset EMCThreadClass
	mov	bp, 2048		; stack size for launching apps
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = new thread handle
	pop	bp
	jc	memError

	mov	bx, ax			; bx = new thread handle
	mov	al, PRIORITY_UI
	mov	ah, mask TMF_BASE_PRIO	; High prio for temporary thread
	call	ThreadModify

	push	bp
	mov	cx, docTokenBlock	; cx = GeodeToken block
	mov	dx, appLaunchBlock	; dx = AppLaunchBlock
	mov	ax, MSG_EMC_THREAD_LAUNCH_APPLICATION
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp
	jmp	short done

memError:
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jmp	reportError
fileError:
	mov	ax, GLE_FILE_NOT_FOUND
reportError:
	push	bp
	mov	si, offset ALB_dataFile	; ds:si = doc name
	mov	di, offset GEOSExecErrorTextOne
	call	ReportLoadAppError
	pop	bp

	mov	bx, docTokenBlock
	tst	bx
	jz	10$
	call	MemFree			; free GeodeToken block
10$:
	mov	bx, appLaunchBlock
	tst	bx
	jz	done
	call	MemFree			; free AppLaunchBlock
done:
	call	FilePopDir

	.leave
	ret
ExpressMenuControlOpenDocument	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlReturnToDefaultLauncher

DESCRIPTION:	Return to default launcher

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_RETURN_TO_DEFAULT_LAUNCHER

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/13/93		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlReturnToDefaultLauncher	method	dynamic ExpressMenuControlClass,
					MSG_EMC_RETURN_TO_DEFAULT_LAUNCHER

appDiskHandle	local	word
appNameOffset	local	word
appTokenBlock	local	word
appLaunchBlock	local	word

	.enter

	mov	ax, TEMP_EMC_HAS_RETURN_TO_DEFAULT_LAUNCHER
	call	ObjVarFindData		; carry set if found
	LONG jnc	exit			; nothing to return to
	mov	appNameOffset, bx

	mov	appTokenBlock, 0	; in case of error
	mov	appLaunchBlock, 0	; in case of error
	call	FilePushDir

	mov	ax, SP_APPLICATION
	mov	appDiskHandle, ax	; save disk handle
	call	FileSetStandardPath

	;
	; get GeodeToken of app to launch to a block
	;	ds:appNameOffset = default launcher name/path
	;
	mov	cx, (mask HAF_LOCK shl 8) or mask HF_SHARABLE or mask HF_SWAPABLE
	mov	ax, size GeodeToken + size FileLongName
	call	MemAlloc		; bx = handle, ax = segment
	jc	memError		; if error, report it (use mem error)
	mov	appTokenBlock, bx	; save handle
	mov	es, ax
	clr	di			; es:di = GeodeToken buffer
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	mov	dx, appNameOffset
	call	FileGetPathExtAttributes	; get GeodeToken
	jnc	noError
	cmp	ax, ERROR_FILE_NOT_FOUND
	jne	notFileNotFound

	mov	ax, SP_SYS_APPLICATION	; try SYSAPPL
	mov	appDiskHandle, ax	; save disk handle
	call	FileSetStandardPath

	mov	ax, FEA_TOKEN
	call	FileGetPathExtAttributes	; get GeodeToken

notFileNotFound:
	mov	ax, GLE_FILE_NOT_FOUND	; in case of ext attr error, use this
	jc	reportError		; if ext attr error, report it now
noError:
	;
	; copy in the name of the app, also, for error reporting purposes
	;	ds:appNameOffset = default launcher name/path
	;
	mov	si, appNameOffset	; ds:si = app name (use whole thing)
	mov	di, size GeodeToken
lameCopyLoop:
	movsb
SBCS <	cmp	{char} es:[di]-1, 0	; copied null terminator yet?	>
DBCS <	cmp	{wchar} es:[di]-2, 0	; copied null terminator yet?	>
	jnz	lameCopyLoop		; nope, continue
	call	MemUnlock
	mov	si, appNameOffset	; ds:si = app pathname
	clr	cx			; Use default mode
	clr	dx			; No data file, no state file
	mov	ah, mask ALF_OVERRIDE_MULTIPLE_INSTANCE
					; normal launch mode, but if app
					;  already running, just bring it
					;  up, don't ask the user if s/he
					;  wants to start a new instance
	mov	bx, appDiskHandle	; bx = disk handle
	push	bp
	clrdw	dibp			; use default gen parent
	call	PrepAppLaunchBlock	; dx = AppLaunchBlock
	pop	bp
memError:
					; in case of ALB error, use this
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jc	reportError		; if ALB error, report it now

	mov	appLaunchBlock, dx	; save AppLaunchBlock

	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	bx, handle 0
	mov	cx, segment EMCThreadClass
	mov	dx, offset EMCThreadClass
	push	bp
	mov	bp, 2048		; stack size for launching apps
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = new thread handle
	pop	bp
	jc	memError		; if error, report it
	mov	bx, ax			; bx = new thread handle
	mov	al, PRIORITY_UI
	mov	ah, mask TMF_BASE_PRIO	; High prio for temporary thread
	call	ThreadModify
	mov	cx, appTokenBlock	; cx = GeodeToken block
	mov	dx, appLaunchBlock	; dx = AppLaunchBlock
	mov	ax, MSG_EMC_THREAD_LAUNCH_APPLICATION
	mov	di, mask MF_FORCE_QUEUE
	push	bp
	call	ObjMessage
	pop	bp
	jmp	short done

reportError:
	mov	di, offset GEOSExecErrorTextOne
	mov	si, appNameOffset	; ds:si = app name
	push	bp
	call	ReportLoadAppError
	pop	bp
	mov	bx, appTokenBlock
	tst	bx
	jz	80$
	call	MemFree			; free GeodeToken block
80$:
	mov	bx, appLaunchBlock
	tst	bx
	jz	done
	call	MemFree			; free AppLaunchBlock
done:
	call	FilePopDir
exit:
	.leave
	ret
ExpressMenuControlReturnToDefaultLauncher	endm

endif		; if _EXPRESS_MENU
ExpressMenuControlCode ends

;---

ExpressMenuCommon segment resource
if _EXPRESS_MENU

EMGetFeaturesAndChildBlock	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
EMGetFeaturesAndChildBlock	endp

EMGetFeaturesAndEnsureChildBlock	proc	far
	call	EMGetFeaturesAndChildBlock
	tst	bx
	jnz	done
	push	cx, dx, bp
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	call	EMGetFeaturesAndChildBlock
done:
	ret
EMGetFeaturesAndEnsureChildBlock	endp


COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlCreateItem

DESCRIPTION:	Create item in requested feature

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM

	ss:bp - CreateExpressMenuControlItemParams
	dx - size CreateExpressMenuControlItemParams

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/6/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlCreateItem	method	dynamic ExpressMenuControlClass,
			MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM

	mov	dx, ss:[bp].CEMCIP_feature
	mov	cx, mask EMCF_GEOS_TASKS_LIST
	mov	ax, offset GEOSTasksList
	cmp	dx, CEMCIF_GEOS_TASKS_LIST
	je	haveFeatureBit
	mov	cx, mask EMCF_DOS_TASKS_LIST
	mov	ax, offset DOSTasksList
	cmp	dx, CEMCIF_DOS_TASKS_LIST
	je	haveFeatureBit
	mov	cx, mask EMCF_CONTROL_PANEL
	mov	ax, offset ControlPanel
	cmp	dx, CEMCIF_CONTROL_PANEL
	je	haveFeatureBit
	mov	cx, mask EMCF_UTILITIES_PANEL
	mov	ax, offset UtilitiesPanel
	cmp	dx, CEMCIF_UTILITIES_PANEL
	je	haveFeatureBit
EC <	cmp	dx, CEMCIF_SYSTEM_TRAY					 >
EC <	ERROR_NE	EXPRESS_MENU_CONTROL_ILLEGAL_CREATE_ITEM_FEATURE >
	mov	ax, ATTR_EMC_SYSTEM_TRAY
	call	ObjVarFindData
	LONG jnc	done
	call	EMGetFeaturesAndEnsureChildBlock
	mov	ax, offset SysTrayPanel
	jmp	checkField
haveFeatureBit:
	push	ax				; save feature object
						; ax = features, bx = flags
	call	EMGetFeaturesAndEnsureChildBlock
	test	ax, cx
	pop	ax				; restore feature object
	jz	done				; requested feature not
						;	supported
	;
	; if a GenField is specified, make sure we are associated with that
	; GenField
	;
checkField:
	call	IsFieldOkay?
	jc	done				; nope, done

	push	si				; save EMC chunk
	push	bp				; save params
EC <	push	bx				; save child block	>

	push	ax, bx
	mov	ax, ATTR_EMC_TRIGGERS_SIGNAL_INTERACTION_COMPLETE
	call	ObjVarFindData
	pop	ax, bx

	pushf					; save carry set if data found
	movdw	esdi, ss:[bp].CEMCIP_class
	call	GenInstantiateIgnoreDirty	; create new item in child block
						; ^lbx:si = new item
	test	cx, mask EMCF_GEOS_TASKS_LIST
	jz	notTaskItem

	;
	; GEOS Tasks List uses GenItems with internal-defined identifier,
	; set it now
	;
	popf
	push	ax				; save feature object
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	mov	cx, si				; set chunk handle as identifier
	jmp	swapLock

notTaskItem:
	;
	; Make this trigger signal interaction complete if vardata was found.
	;
	popf
	jnc	afterItem

	push	ax				; save feature object
	mov	ax, MSG_GEN_SET_ATTRS
	mov	cx, mask GA_SIGNAL_INTERACTION_COMPLETE

swapLock:
	call	ObjSwapLock			; *ds:si = new item
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock			; ^lbx:si = new item
	pop	ax				; restore feature object

afterItem:
	movdw	cxdx, bxsi			; ^lcx:dx = new item
EC <	pop	bx				; bx = child block	>
EC <	cmp	cx, bx				; must also be child block >
EC <	ERROR_NE	EXPRESS_MENU_CONTROL_BAD_ASSUMPTION		>
	mov_tr	si, ax				; ^lbx:si = feature object
	pop	bp				; bp = params

	mov	ax, MSG_GEN_ADD_CHILD		; assume not control or util
	test	ss:[bp].CEMCIP_feature, mask EMCF_CONTROL_PANEL or \
					mask EMCF_UTILITIES_PANEL
	jz	haveMessage
	mov	ax, MSG_EMC_PANEL_ADD_CHILD	; must be control or utilities
haveMessage:
	push	bp				; save again
	mov	bp, ss:[bp].CEMCIP_itemPriority
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; (preserves ^lcx:dx)
	pop	bp				; bp = params
	pop	di				; *ds:di = Express Menu Control
	;
	; notify of newly created item
	;	^lcx:dx = newly created item
	;	*ds:di = Express Menu Control
	;
	call	NotifyOfNewItem
done:
	ret
ExpressMenuControlCreateItem	endm

;
; pass:		ss:bp = CreateExpressMenuControlItemParams
; return:	carry clear if field is okay, carry set if not
; destroyed:	nothing
;
IsFieldOkay?	proc	near
	uses	ax, cx, dx
	.enter
	tst	ss:[bp].CEMCIP_field.handle	; any field?
	jz	done				; nope, field is okay (C clr)
	push	bp
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock		; ^lcx:dx = GenField, if any
	pop	bp
	jnc	done				; GenField not found, just
						;	create item (C clr)
	cmpdw	cxdx, ss:[bp].CEMCIP_field
	je	done				; match, create (C clr)
	stc					; else, indicate not okay
done:
	.leave
	ret
IsFieldOkay?	endp

;
; pass:		ss:bp = CreateExpressMenuControlItemParams
;		^lcx:dx = newly created item
;		*ds:di = Express Menu Control
; return:	nothing
; destroyed:
;
NotifyOfNewItem	proc	near
	mov	ax, ss:[bp].CEMCIP_responseMessage
	movdw	bxsi, ss:[bp].CEMCIP_responseDestination
	push	ds:[LMBH_handle],	; CEMCIRP_expressMenuControl.handle
		di,			; CEMCIRP_expressMenuControl.chunk
		ss:[bp].CEMCIP_responseData,	; CEMCIRP_data
		cx,			; CEMCIRP_newItem.handle
		dx			; CEMCIRP_newItem.chunk
	CheckHack <CEMCIRP_newItem eq 0>
	CheckHack <CEMCIRP_data eq 4>
	CheckHack <CEMCIRP_expressMenuControl eq 6>
	CheckHack <size CreateExpressMenuControlItemResponseParams eq 10>
	mov	bp, sp
	mov	dx, size CreateExpressMenuControlItemResponseParams
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size CreateExpressMenuControlItemResponseParams
	ret
NotifyOfNewItem	endp



COMMENT @----------------------------------------------------------------------

METHOD:		ExpressMenuControlDestroyCreatedItem

DESCRIPTION:	Destroy created item.

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM

	^lcx:dx - optr of created item
	bp - VisUpdateMode (in low byte, high byte clear)

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/9/92		Initial version

------------------------------------------------------------------------------@
ExpressMenuControlDestroyCreatedItem	method	dynamic ExpressMenuControlClass,
				MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	call	EMGetFeaturesAndChildBlock	; ax = features,bx = child block
						;	(bx may be zero)
	cmp	bx, cx				; is it in child block?
	jne	done				; nope, can't destroy
	mov	si, dx				; ^lbx:si = object to destroy
	mov	dx, bp				; dl = VisUpdateMode
	mov	bp, 0				; not dirty
	mov	ax, MSG_GEN_DESTROY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
ExpressMenuControlDestroyCreatedItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressMenuControlNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle file change notification

CALLED BY:	MSG_NOTIFY_FILE_CHANGE

PASS:		*ds:si	= ExpressMenuControl object
		ds:di	= ExpressMenuControl instance data
		es 	= segment of ExpressMenuControl
		ax	= MSG_NOTIFY_FILE_CHANGE

		^hbp	= FileChangeNotificationData block
		dx	= FileChangeNotificationType

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/16/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressMenuControlNotifyFileChange	method	dynamic	ExpressMenuControlClass,
						MSG_NOTIFY_FILE_CHANGE

	push	ax, si
	cmp	dx, FCNT_ADD_SP_DIRECTORY
	je	sendOn
	cmp	dx, FCNT_DELETE_SP_DIRECTORY
	je	sendOn
	cmp	dx, FCNT_BATCH
	je	sendOn
	cmp	dx, FCNT_BATCH
	je	sendOn
	cmp	dx, FCNT_CREATE
	je	sendOn
	cmp	dx, FCNT_RENAME
	je	sendOn
	cmp	dx, FCNT_ATTRIBUTES
	je	sendOn
	cmp	dx, FCNT_DELETE
	jne	callSuper
sendOn:
	call	EMGetFeaturesAndChildBlock	;ax = features,bx = child block
	tst	bx
	jz	callSuper
	;
	; send notification to desk accessories list, if necessary
	;
	test	ax, mask EMCF_DESK_ACCESSORY_LIST
	jz	afterDeskAccessoryList
	mov	si, offset DeskAccessoryList
	call	sendEMCNotifyFileChange
afterDeskAccessoryList:
	;
	; send notification to main apps list, if necessary
	;
	test	ax, mask EMCF_MAIN_APPS_LIST
	jz	afterMainAppsList
	mov	si, offset MainAppsList
	call	sendEMCNotifyFileChange
afterMainAppsList:
	;
	; send notification to document list, if necessary
	;
	test	ax, mask EMCF_DOCUMENTS_LIST
	jz	afterDocumentsList
	mov	si, offset DocumentsList
	call	sendEMCNotifyFileChange
afterDocumentsList:
	;
	; send notification to other apps list, if necessary
	;
	test	ax, mask EMCF_OTHER_APPS_LIST
	jz	afterOtherAppsList
	mov	si, offset OtherAppsList
	call	sendEMCNotifyFileChange
afterOtherAppsList:

callSuper:
	pop	ax, si
	mov	di, offset ExpressMenuControlClass
	GOTO	ObjCallSuperNoLock

sendEMCNotifyFileChange	label	near
	push	ax, dx, bp
	mov	ax, MSG_EMC_INTERACTION_NOTIFY_FILE_CHANGE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, dx, bp
	retn

ExpressMenuControlNotifyFileChange	endm

;
; Code for EMCInteractionClass
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCInteractionNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle file change notification

CALLED BY:	MSG_EMC_INTERACTION_NOTIFY_FILE_CHANGE

PASS:		*ds:si	= EMCInteraction object
		ds:di	= EMCInteraction instance data
		es 	= segment of EMCInteraction
		ax	= MSG_NOTIFY_FILE_CHANGE

		^hbp	= FileChangeNotificationData block
		dx	= FileChangeNotificationType
				FCNT_BATCH
				FCNT_CREATE
				FCNT_RENAME
				FCNT_DELETE

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/16/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCInteractionNotifyFileChange	method	dynamic	EMCInteractionClass,
					MSG_EMC_INTERACTION_NOTIFY_FILE_CHANGE

	push	ds:[LMBH_handle], si
	push	dx, bp

	mov	ax, TEMP_EMC_INTERACTION_APPS_BUILT
	call	ObjVarFindData
	jnc	toDone			; app list not built, no need
					; to update

	mov	ax, TEMP_EMC_INTERACTION_PATH_IDS
	call	ObjVarFindData
	jnc	toDone			; not found, don't bother

	cmp	dx, FCNT_BATCH
	LONG je	batch
	cmp	dx, FCNT_ADD_SP_DIRECTORY
	LONG je	addSPDir
	cmp	dx, FCNT_DELETE_SP_DIRECTORY
	LONG je	deleteSPDir
	cmp	dx, FCNT_CREATE
	je	create
	cmp	dx, FCNT_RENAME
	je	rename
	cmp	dx, FCNT_ATTRIBUTES
	je	rename			; treat as rename - rebuild
	cmp	dx, FCNT_DELETE
	jne	done
;delete:
rename:
	;
	; FCNT_DELETE and FCNT_RENAME - check child file IDs
	;
	call	getIDFromBlock			; cx:dx = file ID, bp = disk
	pushdw	cxdx
	clrdw	cxdx				; check only disk
	call	emcCheckPathIDs
	popdw	cxdx				; cx:dx = file ID
	jnc	done				; disk doesn't match, done
	call	emcCheckFileIDs			; check file IDs
	jmp	short checkRebuild

toDone:
	jmp	done

create:
	;
	; FCNT_CREATE - check this path's IDs
	;
	call	checkCreateNDDir		; ignore this file?
	je	toDone
	push	bp				; save notification data block
	call	getIDFromBlock			; cx:dx = file ID, bp = disk
	call	emcCheckPathIDs
	pop	bp
	jc	rebuildThisEMCInteraction	; need to rebuild, continue
	call	checkCreateLocalSP		; else, check if creating our
						;	local SP
						; (carry set if so)
checkRebuild:
	jnc	done				; no rebuild needed

rebuildThisEMCInteraction:
	;
	; rebuild this EMCInteraction
	;	*ds:si = EMCInteraction
	;
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bp, mask CCF_MARK_DIRTY
	call	GenSendToChildren
	mov	ax, ATTR_EMC_INTERACTION_SUBDIRS
	call	ObjVarFindData
	jc	rebuildSubdirs
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = add items here
	call	CreateAppOrDocList
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication
done:
	;
	; send notification to children of interaction (must be done
	; after interaction itself is notified)
	;
	pop	dx, bp
	mov	bx, segment EMCInteractionClass
	mov	si, offset EMCInteractionClass
	mov	ax, MSG_EMC_INTERACTION_NOTIFY_FILE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	pop	bx, si
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	dx, bp
	call	ObjMessage
	pop	dx, bp

	ret			; <-- EXIT HERE

	;
	; FCNT_ADD_SP_DIRECTORY
	; FCNT_DELETE_SP_DIRECTORY
	;
addSPDir:
deleteSPDir:
	;
	; Extract the pertinent word from the block
	;
	call	getIDFromBlock
	call	EMCCheckIDIsAncestor
	jc	rebuildThisEMCInteraction
	jmp	done


rebuildSubdirs:
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = add items here
	call	CreateOtherAppsList
	call	ForceOtherAppsSubdirIfTooManyEntries
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication
	jmp	short done

batch:
	;
	; FCNT_BATCH
	;
	mov	bx, bp				; ^hbx = FCBND_
	push	es
	call	MemLock
	mov	es, ax				; es = FCBND_
	mov	di, offset FCBND_items
	cmp	di, es:[FCBND_end]
	je	batchDone			; nothing, (carry clear)
batchLoop:
	mov	ax, es:[di].FCBNI_type
EC <	cmp	ax, FileChangeNotificationType		>
EC <	ERROR_A -1					>
	cmp	ax, FCNT_CREATE
	je	batchCreate
	cmp	ax, FCNT_RENAME
	je	batchDeleteRename
	cmp	ax, FCNT_ATTRIBUTES
	je	batchDeleteRename	; treat as rename - rebuild
	cmp	ax, FCNT_DELETE
	je	batchDeleteRename
	cmp	ax, FCNT_ADD_SP_DIRECTORY
	je	batchAddSPDir
	cmp	ax, FCNT_DELETE_SP_DIRECTORY
	je	batchDeleteSPDir
	clc					; no rebuild needed
						; offset to next batch item
gotoNext:
	mov	ax, size FileChangeBatchNotificationItem
batchNext:
	jc	batchDone		; need to rebuild EMCInteraction
	add	di, ax
	cmp	di, es:[FCBND_end]
	jb	batchLoop
	clc					; no rebuild needed
batchDone:
	call	MemUnlock			; unlock FCBND_ block
						; (preserves flags)
	pop	es
	LONG jc	rebuildThisEMCInteraction
	jmp	done

batchAddSPDir:
batchDeleteSPDir:
	mov	bp, es:[di].FCBNI_disk
	movdw	cxdx, es:[di].FCBNI_id
	call	EMCCheckIDIsAncestor
	jmp	gotoNext

batchDeleteRename:
						; offset to next batch item
	mov	bp, size FileChangeBatchNotificationItem
	cmp	ax, FCNT_DELETE
	je	batchDeleteRenameCommon		; FCNT_DELETE, have offset
	cmp	ax, FCNT_ATTRIBUTES
	je	batchDeleteRenameCommon		; FCNT_ATTRIBUTES, have offset
	add	bp, size FileLongName		; offset for FCNT_RENAME
batchDeleteRenameCommon:
	mov_tr	ax, bp
	;
	; batch FCNT_DELETE and FCNT_RENAME -- check child file IDs
	;	*ds:si = EMCInteraction
	;	es:di = FileChangeBatchNotificationItem
	;	ax = offset to next item in FileChangeBatchNotification buffer
	;
	mov	bp, es:[di].FCBNI_disk		; bp = disk
	clrdw	cxdx				; only match disk
	call	emcCheckPathIDs
	jnc	nextBatchDeleteRename		; diff disk, no rebuild
	mov	cx, es:[di].FCBNI_id.high	; cx:dx = file ID
	mov	dx, es:[di].FCBNI_id.low
	call	emcCheckFileIDs			; carry set if match
nextBatchDeleteRename:
	jmp	short batchNext

batchCreate:
	;
	; batch FCNT_CREATE - check this path's IDs
	;	*ds:si = EMCInteraction
	;	es:di = FileChangeBatchNotificationItem
	;
	push	di
	lea	di, es:[di].FCBNI_name		; ignore ND Dir file
	call	checkCreateNDDirLow
	pop	di
	clc
	je	batchCreateRebuild		; C clr, don't need to rebuild
	mov	cx, es:[di].FCBNI_id.high
	mov	dx, es:[di].FCBNI_id.low
	mov	bp, es:[di].FCBNI_disk
	call	emcCheckPathIDs
	jc	batchCreateRebuild		; need to rebuild, continue
	call	checkCreateLocalSPBatch		; else, check if creating our
						;	local SP
						; (carry set if so)
batchCreateRebuild:
						; offset to next batch item
	mov	ax, size FileChangeBatchNotificationItem + size FileLongName
	jmp	short batchNext

;
; pass:
;	^hbp = FileChangeNotificationData
; return:
;	cx:dx = file ID
;	bp = disk
; destroyed:
;	ax, bx
;
getIDFromBlock	label	near
	mov	bx, bp				; ^hbx = FCND_
	push	ds
	call	MemLock
	mov	ds, ax				; ds = FCND_
	mov	cx, ds:[FCND_id].high
	mov	dx, ds:[FCND_id].low
	mov	bp, ds:[FCND_disk]
	call	MemUnlock
	pop	ds
	retn

;
; pass:
;	^hbp = FileChangeNotificationData
; return:
;	Z set if @Directory Information file
; destroyed:
;	ax, bx
;
checkCreateNDDir	label	near
	mov	bx, bp				; ^hbx = FCND_
	push	es, di
	call	MemLock
	mov	es, ax				; ds = FCND_
	lea	di, es:[FCND_name]
	call	checkCreateNDDirLow
	call	MemUnlock			; preserves flags
	pop	es, di
	retn

;
; pass:
;	es:di = create name
; return:
;	Z set if @Directory Information file
; destroyed:
;	nothing
;
checkCreateNDDirLow	label	near
	push	ds, si, cx
	segmov	ds, cs, si
	mov	si, offset createNDDirName
	clr	cx
	call	LocalCmpStrings
	stc					; assume ND Dir
	je	ccnddlDone
	clc					; else, not
ccnddlDone:
	pop	ds, si, cx
	retn
createNDDirName	char	"@Directory Information",0

;
; pass:
;	*ds:si = EMCInteraction
;	cx:dx = id (0 to match any)
;	bp = disk handle
; return:
;	carry set if found
;	carry clear otherwise
; destroyed:
;	none
;
emcCheckPathIDs	label	near
	push	ax, bx, di
	mov	ax, TEMP_EMC_INTERACTION_PATH_IDS
	call	ObjVarFindData
	jnc	pathIDReturn			; (carry clear)
	mov	di, ds:[bx]			; *ds:di = path IDs chunk
	mov	di, ds:[di]
	ChunkSizePtr	ds, di, bx
	tst	bx
	jz	pathIDReturn			; (carry clear)
	add	bx, di				; bx = end
findPathIDLoop:
	cmp	bp, ds:[di].FPID_disk
	jne	tryNextPathID
	tstdw	cxdx
	jz	pathIDMatch
	cmp	cx, ds:[di].FPID_id.high
	jne	tryNextPathID
	cmp	dx, ds:[di].FPID_id.low
pathIDMatch:
	stc					; assume match
	je	pathIDReturn			; if so, return carry set
tryNextPathID:
	add	di, size FilePathID
	cmp	di, bx
	jne	findPathIDLoop
	clc					; indicate not found
pathIDReturn:
	pop	ax, bx, di
	retn

;
; pass:
;	*ds:si = EMCInteraction
;	cx:dx = file ID
; return:
;	carry set if found
;	carry clear otherwise
; destroyed:
;	none
;
emcCheckFileIDs	label	near
	push	ax, bx, di
	mov	ax, TEMP_EMC_INTERACTION_CHILD_FILE_IDS
	call	ObjVarFindData
	jnc	fileIDReturn			; (carry clear)
	mov	di, ds:[bx]			; *ds:di = file IDs chunk
	mov	di, ds:[di]
	ChunkSizePtr	ds, di, bx
	tst	bx
	jz	fileIDReturn			; (carry clear)
	add	bx, di				; bx = end
findFileIDLoop:
	cmp	cx, ds:[di].high
	jne	tryNextFileID
	cmp	dx, ds:[di].low
	stc					; assume match
	je	fileIDReturn			; if so, return carry set
tryNextFileID:
	add	di, size FileID
	cmp	di, bx
	jne	findFileIDLoop
	clc					; indicate not found
fileIDReturn:
	pop	ax, bx, di
	retn

;
; pass:
;	*ds:si = ECMInteraction
;	^hbp = FileChangeNotificationData
; return:
;	carry set if creating local standard path of this EMCInteraction
;	carry clear otherwise
; destroys:
;	nothing
;
checkCreateLocalSP	label	near
	push	ax, bx, di, es
	mov	bx, bp
	call	MemLock
	mov	es, ax			; es:di = FileChangeNotificationData
	clr	di
	call	checkCreateLocalSPLow
	call	MemUnlock		; (preserves flags)
	pop	ax, bx, di, es
	retn
;
; pass:
;	*ds:si = ECMInteraction
;	es:di = FileChangeBatchNotificationItem
; return:
;	carry set if creating local standard path of this EMCInteraction
;	carry clear otherwise
; destroys:
;	nothing
;
checkCreateLocalSPBatch	label	near
	push	di
	add	di, offset FCBNI_disk	; point to FileChangeNotificationData
	call	checkCreateLocalSPLow
	pop	di
	retn

;
; pass:
;	*ds:si = ECMInteraction
;	es:di = FileChangeNotificationData
; return:
;	carry set if creating local standard path of this EMCInteraction
;	carry clear otherwise
; destroys:
;	nothing
;
; NOTE:  This code doesn't work and should probably be nuked.
;
checkCreateLocalSPLow	label	near
	push	ax, bx, cx, dx, si, di
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	jnc	cclsplDone		; not found, carry clear
	mov	cx, ds:[bx].GFP_disk
	test	cx, DISK_IS_STD_PATH_MASK
	jz	cclsplDone		; not SP, carry clear
	lea	si, ds:[bx].GFP_path	; ds:si = our path
	;
	; get tail component
	;
saveBSPos:
	mov	dx, si
findBSPos:
	LocalGetChar ax, dssi
	LocalCmpChar ax, C_BACKSLASH
	je	saveBSPos
	LocalIsNull ax
	jnz	findBSPos
	mov	si, dx			; ds:si = tail
	add	di, offset FCND_name	; es:di = created name
	push	di
	mov	cx, -1
SBCS <	mov	al, 0							>
DBCS <	clr	ax							>
	LocalFindChar			;repne scasb/scasw
	not	cx			; cx = length w/null
	pop	di
SBCS <	repe cmpsb							>
DBCS <	repe cmpsw							>
	clc				; in case no match
	jne	cclsplDone
	stc				; else, creating local version of SP
cclsplDone:
	pop	ax, bx, cx, dx, si, di
	retn

EMCInteractionNotifyFileChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCCheckIDIsAncestor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the FCND_disk as a StandardPath is the ancestor of
		one of those for our window

CALLED BY:	EMCInteractionNotifyFileChange

PASS:		*ds:si	= OLFileSelector object
		cx:dx - FileID
		bp - disk handle

RETURN:		carry set if the ID is one of ours

DESTROYED:	di

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	 4/19/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMCCheckIDIsAncestor proc	near
	class	EMCInteractionClass
	uses	ax, bx, cx, dx, bp
	.enter

	;
	; Get our current path
	;
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	test	ax, DISK_IS_STD_PATH_MASK
	jz	done			;branch (carry clear)
	;
	; Are we below the StandardPath or at it?
	;
	cmp	ax, bp			;at path?
	je	isOurs			;branch if at path
	mov	bx, ax			;bx <- our StandardPath
	call	FileStdPathCheckIfSubDir
	tst	ax			;subdirectory?
	jnz	done			;branch (carry clear)
isOurs:
	stc				;carry <- is changed
done:

	.leave
	ret
EMCCheckIDIsAncestor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceOtherAppsSubdirIfTooManyEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	force OtherAppsList into submenu if number of items
		exceeds number specified in .ini file

CALLED BY:	EXTERNAL
			ExpressMenuControlGenerateUI
			EMCInteractionNotifyFileChange

PASS:		ds - fixupable object block
		^lbx:si = OtherAppsList

RETURN:		nothing

DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceOtherAppsSubdirIfTooManyEntries	proc	far
	uses	ax
	.enter
	push	ds, si
	mov	cx, cs
	mov	ds, cx
	mov	si, offset forceCategory
	mov	dx, offset forceKey
	call	InitFileReadInteger		; ax = max #
	pop	ds, si
	jc	done				; not found, do nothing
	push	ax
	mov	ax, MSG_GEN_COUNT_CHILDREN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; dx = #children
	pop	ax
	cmp	ax, dx
	jae	intoSubgroup		; less than max, back to subgroup
	;
	; force the OtherAppsList into submenu (restoring moniker)
	;
	mov	cx, offset OtherAppsListMoniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cl, GIV_POPUP
	jmp	short setVis

intoSubgroup:
	mov	cl, GIV_SUB_GROUP
setVis:
	push	cx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	pop	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
ForceOtherAppsSubdirIfTooManyEntries	endp

forceCategory		byte	"expressMenuControl",0
forceKey		byte	"maxNumDirs",0

endif		; if _EXPRESS_MENU
ExpressMenuCommon ends

;----

Resident	segment	resource
if _EXPRESS_MENU


COMMENT @----------------------------------------------------------------------

METHOD:		EMCThreadLaunchApplication

DESCRIPTION:	Launch application

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_EMC_THREAD_LAUNCH_APPLICATION

	cx - GeodeToken block
		(freed after use)
	dx - AppLaunchBlock
	bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/16/92	Initial version

------------------------------------------------------------------------------@
;
; This is in Resident module, to launch from safe memory situation
;
EMCThreadLaunchApplication	method	dynamic EMCThreadClass,
					MSG_EMC_THREAD_LAUNCH_APPLICATION


	mov	bx, cx			; bx = GeodeToken block
	push	bx
	call	MemLock
	mov	es, ax			; es:di = GeodeToken
	clr	di
	mov	bx, dx			; bx = AppLaunchBlock
	mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	push	bp
	call	IACPConnect		; (frees AppLaunchBlock)
	mov	cx, bp			; cx = connection
	pop	bp
	pop	bx			; bx = GeodeToken block
	jc	reportError
	push	bp
	mov	bp, cx			; bp = connection
	clr	cx			; client shutting down
	call	IACPShutdown
	pop	bp
	jmp	short done

reportError:
	mov	ax, GLE_FILE_NOT_FOUND
	mov	di, offset GEOSExecErrorTextOne
	segmov	ds, es
	mov	si, size GeodeToken	; ds:si = app name
	push	bp, bx
	call	ReportLoadAppError
	pop	bp, bx
done:
	;
	; free GeodeToken block, AppLaunchBlock is handled by IACPConnect
	; via UserLoadApplication
	;	bx = GeodeToken block
	;
	call	MemFree			; free GeodeToken block
	clr	cx			; exit code
	clr	dx			; send ACK to no one
	jmp	ThreadDestroy		; all done
EMCThreadLaunchApplication	endm

endif		; if _EXPRESS_MENU
Resident	ends
