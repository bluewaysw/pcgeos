COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinBase.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_INITIALIZE     Initialize an open look base window

    INT BaseWinAttrGenDisplayNotMinimizable
				Initialize an open look base window

    INT BaseWinAttrGenDisplayNotMaximizable
				Initialize an open look base window

    INT BaseWinAttrGenDisplayNotRestorable
				Initialize an open look base window

    INT BaseWinHintDisplayNotResizable
				Initialize an open look base window

    INT BaseWinHintNoExpressMenu
				Initialize an open look base window

    INT MakeNotResizableIfKeyboardOnly
				Clear the OWA_RESIZABLE bit if user is
				working with a keyboard only, i.e. no mouse

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS
				Scans geometry hints.

    INT AA_DerefVisSpec_DI      Scans geometry hints.

    MTD MSG_SPEC_BUILD_BRANCH

    INT AddPrimaryHelp          Add a help trigger to the primary if
				requested

    INT AddPrimaryKeyboard      Add a floating keyboard trigger to the
				right side of titlebar

    MTD MSG_SPEC_BUILD          Make sure this window is added to the
				window list

    INT EnsureItemAddedToWindowList
				Make sure this window is added to the
				window list.

    MTD MSG_SPEC_UPDATE_VIS_MONIKER
				If a new moniker is set, then we need to
				update the entry in the Window List

    MTD MSG_OL_BASE_WIN_UPDATE_WINDOW_ENTRY
				Update window list selection

    MTD MSG_META_NOTIFY_TASK_SELECTED
				Bring window to front.

    MTD MSG_META_NOTIFY_TASK_SELECTED
				Notify window that it has been selected.

    MTD MSG_OL_WINDOW_LIST_ITEM_SET_OPERATING_PARAMS
				Save data.

    MTD MSG_OL_WINDOW_LIST_ITEM_CLOSE_WINDOW
				Close window

    MTD MSG_META_KBD_CHAR       Handle keyboard events for WindowListItem.

    INT EnsureFileMenu          Make sure we have a File menu.

    INT EnsureAppMenu           Make sure we have an app menu trigger.

    INT EnsureMoreTrigger       Add a "More" Button to the menu bar.

    INT EnsureJotterControl     Add a Jotter Control.

    INT CheckForJotterControl   see if this child is a JotterControl

    MTD MSG_OL_BASE_WIN_REBUILD_APP_MENU_BUTTON
				rebuild App menu button

    MTD MSG_OL_BASE_WIN_NOTIFY_OF_FILE_MENU
				notification that "File" menu exists

    INT OLBaseWinDetermineInitialMinimizedStatus
				See if this app should come up minimized

    MTD MSG_META_UPDATE_WINDOW  *ds:si - instance data (for object in
				OLBaseWin class) es - segment of
				OLBaseWinClass

				ax - MSG_META_UPDATE_WINDOW

				cx	- UpdateWindowFlags dl	-
				VisUpdateMode

    INT RemoveTitleBarIfPossible
				RemoveTitleBarIfPossible

    INT OLBaseWinDetermineInitialMaximizedStatus
				Determine intitial MAXIMIZED status for
				this primary window. At this time, always
				preserve state if restoring from state.  If
				coming up fresh, we generally rely on
				application hints, though override forcing
				maximization in certain situations

				NOTE: UIWO_MAXIMIZE_ON_STARTUP is set in
				SpecInit, called when this library is first
				loaded.

    MTD MSG_SPEC_UNBUILD        Remove this window from the window list
				before doing normal unbuild.

    INT OLBaseWinRemoveSpecBuildCreatedObjects
				remove ui objects added to this OLBaseWin
				during spec build

    INT OLBWRSBO_destroyIfFound remove ui objects added to this OLBaseWin
				during spec build

    INT OLBWRSBO_genDestroy     remove ui objects added to this OLBaseWin
				during spec build

    INT RemoveAppMenuButton     remove creatd App menu button

    INT EnsureItemRemovedFromWindowList
				Ensures that this window is removed from
				the window list

    MTD MSG_VIS_COMP_GET_MINIMUM_SIZE
				Returns the minimum size for a window.

    MTD MSG_GEN_DISPLAY_SET_MINIMIZED
				Moves base window off-screen, then performs
				superclass action

    MTD MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
				Call superclass and update express menu

    INT OLWinMoveOffScreen      Move window off-screen, so it will not be
				visible

    MTD MSG_META_GAINED_SYS_TARGET_EXCL
				We intercept this method here so that we
				can update the TaskEntry in the express
				menu.

    INT UpdateAppMenuItemCommon We intercept this method here so that we
				can update the TaskEntry in the express
				menu.

    INT OLRedoMenuBarGeometryIfMenusInHeader
				We intercept this method here so that we
				can update the TaskEntry in the express
				menu.

    INT OLBaseWinHideExpressToolArea
				Hide the express tool area by moving it off
				screen

    INT OLBaseWinAdjustTitleBoundsForExpressToolArea
				Adjusts bounds of title area to be smaller
				if this app currently has the express tool
				area associated with it.

    MTD MSG_META_LOST_SYS_TARGET_EXCL
				We intercept this method here so that we
				can release our hold on the express menu

    MTD MSG_META_GET_TARGET_AT_TARGET_LEVEL
				Returns current target object within this
				branch of the hierarchical target
				exclusive, at level requested

    MTD MSG_GEN_DISPLAY_CLOSE   We intercept this method here because it
				has a distinct meaning to applications:
				QUIT!

    MTD MSG_VIS_OPEN            Intercept MSG_VIS_OPEN so we can draw
				"zoom-lines" before the window comes up.

    MTD MSG_VIS_CLOSE           Intercept this method here as the window is
				closing To see if we cna't find another
				suitable object to take the focus/target
				exclusives.

    INT DrawZoomLines           Draw zoom lines before a window opens to
				indicate where the window was opened from.

    INT ZoomLinesStuffPositionHint
				If we are zooming all primarys (as opposed
				to just those with the
				HINT_PRIMARY_OPEN_ICON_BOUNDS hint) then
				when we don't encounter this hint we stuff
				it with the mouse position

    MTD MSG_GET_MENU_BAR_WIN    Return the handle of the associated
				MenuBarWin if one exists

    MTD MSG_SPEC_GUP_QUERY      Respond to a query traveling up the generic
				composite tree

    MTD MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER
				Switch to specific long term moniker.

    INT WinUncommon_DerefVisSpec_DI
				Switch to specific long term moniker.

    INT WinUncommon_ObjMessageCallFixupDS
				Switch to specific long term moniker.

    INT OLBaseWinDrawGCMIcon    Draw the Exit or Help buttons in the header
				of this window.

    MTD MSG_OL_BASE_WIN_UPDATE_EXPRESS_TOOL_AREA
				This procedure positions the "express tool area", if this app current "has it" floating above it.  Does NOT mess with the title bar bounds, just references them to figure out where the area should be moved.

    INT OLBaseWinEnableAndPositionHeaderIcon
				This procedure is used to position and enable the icons which appear in the header area of a window:

				- GCM "Exit" and "Help" icons - Workspace
				and Application menu buttons

    INT OLBaseWinPositionGCMHeaderIcons
				This procedure positions and enables the "Exit" and "Help" icons in the header when running in GC mode.

    MTD MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
				update express menu button, if any

    MTD MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
				Returns widths of icons left and right of
				title bar.

    INT OLBaseWinGetExpressMenuButtonWidth
				Returns width of window's system menu
				button.

    MTD MSG_META_FUP_KBD_CHAR   This method is sent by child which 1) is
				the focused object and 2) has received a
				MSG_META_KBD_CHAR or MSG_META_FUP_KBD_CHAR
				which is does not care about. Since we also
				don't care about the character, we forward
				this method up to the parent in the focus
				hierarchy.

				At this class level, the parent in the
				focus hierarchy is is the generic parent.

    MTD MSG_SPEC_SET_USABLE     Handle set-usable by maximizing OLBaseWin
				if HINT_DISPLAY_MAXIMIZED_ON_STARTUP is
				set.

    MTD MSG_SPEC_SET_USABLE     Handle set-usable by maximizing OLBaseWin
				if HINT_DISPLAY_MAXIMIZED_ON_STARTUP is
				set.

    MTD MSG_OL_BASE_WIN_TOGGLE_MENU_BAR
				toggle menu bar, if togglable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	6/89		Moved to winBase.asm from openBaseWin.asm
	Eric	7/89		Motif extensions
	Joon	7/92		PM extensions

DESCRIPTION:

	$Id: cwinBase.asm,v 1.5 98/07/10 11:00:05 joon Exp $

------------------------------------------------------------------------------@

CommonUIClassStructures segment resource

	OLBaseWinClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED


if TOOL_AREA_IS_TASK_BAR
	OLWindowListItemClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
endif

if RADIO_STATUS_ICON_ON_PRIMARY
	RadioStatusIconClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
endif

CommonUIClassStructures ends


;---------------------------------------------------

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinInitialize -- MSG_META_INITIALIZE for OLBaseWinClass

DESCRIPTION:	Initialize an open look base window

PASS:
	*ds:si - instance data
	es - segment of OLBaseWinClass

	ax - MSG_META_INITIALIZE

	cx, dx, bp	- ?

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
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

------------------------------------------------------------------------------@
OLBaseWinInitialize	method dynamic	OLBaseWinClass, MSG_META_INITIALIZE

	;set these for FindMonikers in OLMenuedWinInitalize, they may be
	;reset by superclass, so we set them again later

OLS <	mov	ds:[di].OLWI_type, OLWT_BASE_WINDOW			>
CUAS <	mov	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>

	;call superclass (do not call OpenWinInitialize directly!)

	mov	di, offset OLBaseWinClass
	CallSuper	MSG_META_INITIALIZE

	; Initialize Visible characteristics that we'd like to have unless
	; overridden by hints handling

	call	WinCommon_DerefVisSpec_DI

	;
	; clear build target (effectively ignores SEEK_TITLE_BAR)
	;
.assert (OLBT_NO_TARGET eq 0)
	andnf	ds:[di].OLCI_buildFlags, not mask OLBF_TARGET

				; & give basic base window attributes

OLS <	ORNF	ds:[di].OLWI_attrs, OL_ATTRS_BASE_WIN			>
OLS <	mov	ds:[di].OLWI_type, OLWT_BASE_WINDOW			>

CUAS <	ORNF	ds:[di].OLWI_attrs, MO_ATTRS_PRIMARY_WINDOW		>
CUAS <	mov	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
				; Store is base window

	; Remove resize borders if keyboard only-operation, since user can't
	; use mouse on it.  Clearing the single flag here works OK at this
	; time, where we've not yet implemented the "Size" option in the
	; window menu.  When this is done, however, we'll have to be careful
	; to distinguish between "Resizable" & just not showing the resize
	; border.		- Doug 2/11/92
	;
	call	MakeNotResizableIfKeyboardOnly

	;If GenDisplay attribute = GDA_USER_DISMISSABLE, then set CLOSABLE flag
	;This will not affect functionality; just which gadgets are provided
	;by the specific UI to close this window.

	push	di
	call	WinCommon_DerefGen_DI
	test	ds:[di].GDI_attributes, mask GDA_USER_DISMISSABLE
	pop	di
	jz	30$			; skip if not.
					; If dismissable:

					; Mark as closable
	ORNF	ds:[di].OLWI_attrs, mask OWA_CLOSABLE

30$:	;Allow windows to come up when usable

	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

	;process positioning and sizing hints

	call	OLBaseWinScanGeometryHints

	;
	; Handle the following hints:
	; ATTR_GEN_DISPLAY_NOT_MINIMIZABLE,
	; ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE,
	; ATTR_GEN_DISPLAY_NOT_RESTORABLE,
	; HINT_DISPLAY_NOT_RESIZABLE
	;
	push	es
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLBaseWinHintHandlers
	mov	ax, length (cs:OLBaseWinHintHandlers)
	call	ObjVarScanData
	pop	es

if _ISUI
	mov	ax, HINT_PRIMARY_MINIMIZE_REPLACES_CLOSE_FUNCTION
	call	ObjVarFindData
	jnc	noMinClose
	mov	ax, TEMP_OL_WIN_MINIMIZE_IS_CLOSE
	clr	cx
	call	ObjVarAddData

noMinClose:
	mov	ax, HINT_PRIMARY_HIDE_MINIMIZE_UI
	call	ObjVarFindData
	jnc	noHideMin
	mov	ax, TEMP_OL_WIN_HIDE_MINIMIZE
	clr	cx
	call	ObjVarAddData

noHideMin:
endif


if	 _ALLOW_MINIMIZED_TITLE_BARS
	; If we are supposed to minimize the title bar, then set the window
	; to be not closable (no close button).  Also, go ahead and set the
	; window to be not minimizable nor restorable - there won't be any
	; gadgetry for it anyway.

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_moreFixedAttr, mask OMWFA_MINIMIZE_TITLE_BAR
	jz	checkMinMaxRestoreControls
	andnf	ds:[di].OLWI_attrs, not mask OWA_CLOSABLE
	jmp	SHORT dontAllowMinRestore

checkMinMaxRestoreControls:
endif	;_ALLOW_MINIMIZED_TITLE_BARS

	;
	; If UIWindowOptions (.ini) prevents minimizing, maximizing, and
	; restoring, make not-minimizable and not-restorable.
	;
	; We leave maximizing capability because we could be run on a
	; maximize-on-startup field, which checks this flag.  The
	; OpenWinCheckIfMinMaxRestoreControls works elsewhere to actually
	; remove the maxmize gadgetry, so we are okay there.
	;
	call	OpenWinCheckIfMinMaxRestoreControls
	jc	allowMinMaxRestore

if	 _ALLOW_MINIMIZED_TITLE_BARS
dontAllowMinRestore:
endif	;_ALLOW_MINIMIZED_TITLE_BARS

if _ISUI
	;
	; We also leave minimizing capability if the hints
	; HINT_PRIMARY_MINIMIZE_REPLACES_CLOSE_FUNCTION or
	; HINT_PRIMARY_HIDE_MINIMIZE_UI are present.  The presense of the
	; latter will actually remove the minimize gadgetry.
	;
	push	ax, bx
	mov	ax, HINT_PRIMARY_MINIMIZE_REPLACES_CLOSE_FUNCTION
	call	ObjVarFindData
	jc	minReplacesClose
	mov	ax, HINT_PRIMARY_HIDE_MINIMIZE_UI
	call	ObjVarFindData
minReplacesClose:
	pop	ax, bx
	jc	allowMinMaxRestore
endif

	call	BaseWinAttrGenDisplayNotMinimizable
	call	BaseWinAttrGenDisplayNotRestorable

allowMinMaxRestore:

	;
	; If being run in "desk accessory" mode, make not-maximizable
	;
	; This means that a desk accessory will not be maximized, even when
	; started in a maximized-on-startup field (see
	; OLBaseWinDetermineInitialMaximizedStatus), this is desired.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	GenCallApplication	; al = AppLaunchFlags
	test	al, mask ALF_DESK_ACCESSORY
	jz	notDeskAccessory
	call	BaseWinAttrGenDisplayNotMaximizable
	jmp	short afterDeskAccessory

notDeskAccessory:

	;not a desk accessory, if running in UILM_TRANSPARENT mode, cannot
	;close (as close means exit app and you can't exit app in
	;UILM_TRANSPARENT mode)

	call	UserGetLaunchModel		; ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	closable
	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jnz	closable
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_CLOSABLE
closable:

afterDeskAccessory:

if _GCM
	;
	; If marked as GCM, maximize & prevent min/restore behavior.
	;
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jz	notGCM
	call	BaseWinAttrGenDisplayNotMinimizable
	call	BaseWinAttrGenDisplayNotRestorable
;
; UIWO_MAXIMIZE_ON_STARTUP is dealt with in
; OLBaseWinDetermineInitialMaximizedStatus, called from META_UPDATE_WINDOW
; handler, so should not need to be handled here.  Doing this here also
; screws up restoring an unmaxmized window from state on a
; UIWO_MAXIMIZE_ON_STARTUP system.  - brianc 9/17/92
;
if 0
	jmp	short maximize

notGCM:
	;
	; If marked as UIWO_MAXIMIZE_ON_STARTUP, maximize the window.
	;
	push	es, ax
	segmov	es, dgroup, ax
	test	es:[olWindowOptions], mask UIWO_MAXIMIZE_ON_STARTUP
	pop	es, ax
	jz	afterMaximized

maximize:
else
;
; Post-mortem comment:
; I guess if it is a GCM window, we want to force maximized state regardless
; of state info - brianc 12/8/92
;
				; don't save to state as this will be checked
				; again on next startup (and we don't want to
				; falsely report maximized when we really just
				; meant to set it for this session)
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	clr	cx
	call	ObjVarAddData
;afterMaximized:
notGCM:
endif
endif

;	;if this window is marked as minimized and the specific UI
;	;allows this, set as not SA_REALIZABLE and SA_BRANCH_MINIMIZED
;	;so visible build will not occur. (This could be handled
;	;in OLMenuedWinClass, but there is no INITIALIZE handler there.)
;
;this is handled in MSG_META_UPDATE_WINDOW (of OLMenuedWinClass) and
;MSG_SPEC_SET_USABLE handlers - brianc 3/12/92

	ret
OLBaseWinInitialize	endp


OLBaseWinHintHandlers	VarDataHandler \
	< ATTR_GEN_DISPLAY_NOT_MINIMIZABLE, offset BaseWinAttrGenDisplayNotMinimizable >,
	< ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE, offset BaseWinAttrGenDisplayNotMaximizable >,
	< ATTR_GEN_DISPLAY_NOT_RESTORABLE, offset BaseWinAttrGenDisplayNotRestorable >,
	< HINT_DISPLAY_NOT_RESIZABLE, offset BaseWinHintDisplayNotResizable >,
	< HINT_PRIMARY_NO_EXPRESS_MENU, offset BaseWinHintNoExpressMenu >

BaseWinAttrGenDisplayNotMinimizable	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MINIMIZABLE
	ret
BaseWinAttrGenDisplayNotMinimizable	endp

BaseWinAttrGenDisplayNotMaximizable	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MAXIMIZABLE
	ret
BaseWinAttrGenDisplayNotMaximizable	endp

BaseWinAttrGenDisplayNotRestorable	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_RESTORABLE)
	ret
BaseWinAttrGenDisplayNotRestorable	endp

BaseWinHintDisplayNotResizable	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_RESIZABLE)
	ret
BaseWinHintDisplayNotResizable	endp

BaseWinHintNoExpressMenu	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLBWI_flags, mask OLBWF_REJECT_EXPRESS_TOOL_AREA
	ret
BaseWinHintNoExpressMenu	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MakeNotResizableIfKeyboardOnly

DESCRIPTION:	Clear the OWA_RESIZABLE bit if user is working with a
		keyboard only, i.e. no mouse

CALLED BY:	INTERNAL
		OLBaseWinInitialize

PASS:		*ds:si	- base window

RETURN:		nothing

DESTROYED:	ax

------------------------------------------------------------------------------@
MakeNotResizableIfKeyboardOnly	proc	near
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	10$
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_RESIZABLE
10$:
	ret
MakeNotResizableIfKeyboardOnly	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinScanGeometryHints --
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLBaseWinClass

DESCRIPTION:	Scans geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLBaseWinScanGeometryHints	method static OLBaseWinClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLBaseWinClass
	mov	es, di

	mov	di, offset OLBaseWinClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;override OLWinClass positioning/sizing behavior:

	call	WinCommon_DerefVisSpec_DI
if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT \
		or mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
endif		;END of OPEN LOOK specific code -------------------------------

if _CUA_STYLE	;START of MOTIF specific code ---------------------------------
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE)
endif		;END of MOTIF specific code -----------------------------------

	;now set positioning behavior for icon:

if _NO_WIN_ICONS	;------------------------------------------------------

	mov	cx, FALSE

else	;----------------------------------------------------------------------

	mov	ds:[di].OLMDWI_iconWinPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_NONE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)

	mov	ds:[di].OLMDWI_iconWinPosSizeState, \
			  (mask SSPR_ICON shl offset WPSS_STAGGERED_SLOT) \
			or mask WPSS_POSITION_INVALID or mask WPSS_SIZE_INVALID
					;set flag: is icon, so stagger as one.

	mov	cx, TRUE		;pass flag: window can have an icon

endif	; if _NO_WIN_ICONS ----------------------------------------------------

	call	OpenWinProcessHints

	; handle the special "I'm a major app" hint -- the interpretation of
	; this is specific UI determined

	mov	ax, HINT_PRIMARY_FULL_SCREEN
	call	ObjVarFindData
	jnc	done

	call	WinCommon_DerefVisSpec_DI
				; set geometry flags (after clearing fields)
				;	(must clear fields seperately!)
	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_POSITION_TYPE)

	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_SIZE_TYPE)
	ornf	ds:[di].OLWI_winPosSizeFlags, \
			WPT_AT_RATIO shl offset WPSF_POSITION_TYPE or \
			WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	add	di, offset VI_bounds		; ds:di = VI_bounds
	mov	bp, di				; ds:bp+2 = OLWI_winPosSizeState
	add	bp, offset OLWI_winPosSizeFlags
	call	EnsureRightBottomBoundsAreIndependent
	mov	ds:[di].R_left, mask SWSS_RATIO or PCT_0
	mov	ds:[di].R_top, mask SWSS_RATIO or PCT_0
				; indicate that VI_bounds.R_left and R_top
				;	contain a SpecWinSizePair
	ornf	{word} ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR

done:

	.leave
	ret
OLBaseWinScanGeometryHints	endm

if GRAFFITI_ANYWHERE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass to focused child.  Implements "Graffiti-anywhere."

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK

PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

BUGS/SIDE EFFECTS/IDEAS:

	Any bugs fixed in this routine should probably also be fixed in
	OLCtrlQueryIfPressIsInk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBaseWinQueryIfPressIsInk	method dynamic OLBaseWinClass,
					MSG_META_QUERY_IF_PRESS_IS_INK
		.enter
	;
	;  Pass the query onto the first focused child.
	;
		push	ax, cx, dx
		mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
		call	ObjCallInstanceNoLock		; ^lcx:dx = obj
		movdw	bxbp, cxdx			; save object
		pop	ax, cx, dx			; passed args
	;
	;  Don't call self in infinite loop, or try to call an object
	;  that isn't there.
	;
		tst	bx
		jz	callSuper			; no object!
		cmp	bx, ds:[LMBH_handle]		; same obj block?
		jne	doCall
		cmp	bp, si				; same obj?
		je	callSuper
doCall:
	;
	;  Send to focused object.
	;
		mov	si, bp				; ^lbx:si = obj
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, bp = returned
done:
		.leave
		ret
callSuper:
		mov	di, offset OLBaseWinClass
		call	ObjCallSuperNoLock
		jmp	done
OLBaseWinQueryIfPressIsInk	endm

endif	; GRAFFITI_ANYWHERE

WinCommon	ends


AppAttach segment resource

AA_DerefVisSpec_DI	proc	near
	class	VisClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
AA_DerefVisSpec_DI	endp


COMMENT @----------------------------------------------------------------------

METHOD:         OLBaseWinUpdateSpecBuild

DESCRIPTION:

PASS:           *ds:si - instance data
                es - segment of OpenWinClass

                ax - MSG_SPEC_BUILD_BRANCH
                cx - ?
                dx - ?
                bp - SpecBuildFlags

RETURN:         carry - ?
                ax, cx, dx, bp - ?

DESTROYED:      bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Doug    10/90           Initial version

------------------------------------------------------------------------------@

OLBaseWinUpdateSpecBuild   method dynamic  OLBaseWinClass, \
						MSG_SPEC_BUILD_BRANCH
	;
	; Set optimization flag indicating that no object
	; at this point or below in the tree, when being
	; TREE_BUILD'd, will be adding itself visually
	; outside the visual realm of this Base window.  (Allows
	; VisAddChildRelativeToGen to work much quicker)

	or	bp, mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

if RADIO_STATUS_ICON_ON_PRIMARY
	call	AddPrimaryRadioStatusIcon
endif

if _FLOATING_KEYBOARD_TRIGGER_ON_PRIMARY
	call	AddPrimaryKeyboard
endif

if (not _NO_PRIMARY_HELP_TRIGGER)
	call	AddPrimaryHelp
endif

	call	EnsureFileMenu
	ret
OLBaseWinUpdateSpecBuild   endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPrimaryHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a help trigger to the primary if requested

CALLED BY:	OLBaseWinUpdateSpecBuild()
PASS:		*ds:si - OLBaseWin object
RETURN:		ds - fixed up
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not _NO_PRIMARY_HELP_TRIGGER) ;--------------------------------------------

AddPrimaryHelp		proc	near
	uses	ax, cx, dx, bp, si, es
	.enter

	;
	; See if we are hiding help buttons (eg. for a system
	; with a dedicated help button or icon)
	;
	call	OpenGetHelpOptions
	test	ax, mask UIHO_HIDE_HELP_BUTTONS
	LONG jnz noHelp				;branch if help hidden
	;
	; See if there is a hint specifying we shouldn't add the trigger
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW
	call	ObjVarFindData
	LONG jc	noHelp				;branch if no primary help
	;
	; See if there is a hint specifying we shouldn't add the trigger
	;
	mov	ax, HINT_PRIMARY_NO_HELP_BUTTON
	call	ObjVarFindData
	LONG jc	noHelp				;branch if no primary help
	;
	; Finally, see if there is even help specified
	;
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	LONG jnc noHelp				;branch if no help context
	push	si
if _GCM
	;
	; Check to see if this should be a GCM icon
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	;
	; We've survived the gauntlet of vardata...create a trigger
	;
	pushf					;flag indicates GCM_TITLED
endif
	mov	ax, segment GenTriggerClass
	mov	es, ax
	mov	di, offset GenTriggerClass	;es:di <- ptr to class
	mov	bx, ds:LMBH_handle		;bx <- block to create in
	call	GenInstantiateIgnoreDirty
if _GCM
	popf
	jz	afterGCM
	;
	; Indicate that this trigger is a GCM_SYS_ICON
	;
	mov	ax, HINT_GCM_SYS_ICON
	clr	cx				;cx <- no extra data
	call	ObjVarAddData

ISU <	mov	ax, HINT_ENSURE_TEMPORARY_DEFAULT			>
ISU <	clr	cx				; hack to make trigger	>
ISU <	call	ObjVarAddData			;  larger than moniker	>

afterGCM:
endif
	;
	; Set the moniker of the trigger to our special default
	;
	mov	ax, ATTR_GEN_DEFAULT_MONIKER
	mov	cx, (size GenDefaultMonikerType)
	call	ObjVarAddData
	mov	{word}ds:[bx], GDMT_HELP_PRIMARY

	;
	; Add a hint to put the trigger in the title bar
	;
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	clr	cx				;cx <- no extra data
	call	ObjVarAddData

if BUBBLE_HELP
	;
	; Add focus help hint
	;
	mov	ax, ATTR_GEN_FOCUS_HELP
	mov	cx, size optr
	call	ObjVarAddData
	mov	ds:[bx].handle, handle HelpHelpString
	mov	ds:[bx].offset, offset HelpHelpString
endif

	;
	; Set the message & output of the trigger
	;
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_META_BRING_UP_HELP
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, ds:LMBH_handle
	mov	dx, si				;^lcx:dx <- dest OD (self)
	call	ObjCallInstanceNoLock

	;
	; Add the new trigger
	;
	mov	cx, ds:LMBH_handle
	mov	dx, si				;^lcx:dx <- OD of trigger
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	pop	si				;*ds:si <- OLBaseWin object
	call	ObjCallInstanceNoLock

	;
	; Save the lptr of the help trigger we added
	;
	mov	ax, TEMP_OL_BASE_WIN_HELP_TRIGGER
	mov	cx, (size lptr)			;cx <- size of extra data
	call	ObjVarAddData
	mov	ds:[bx], dx			;save lptr

	;
	; Finally, set the trigger usable
	;
	mov	si, dx				;*ds:si <- trigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	;dl <- VisUpdateMode
	call	ObjCallInstanceNoLock
noHelp:
	.leave
	ret
AddPrimaryHelp		endp

endif	; (not _NO_PRIMARY_HELP_TRIGGER) --------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPrimaryKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a floating keyboard trigger to the right side of titlebar

CALLED BY:	OLBaseWinUpdateSpecBuild
PASS:		*ds:si - OLBaseWin object
RETURN:		ds - fixed up
DESTROYED:	bx,cx,dx,di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _FLOATING_KEYBOARD_TRIGGER_ON_PRIMARY ;-------------------------------------

AddPrimaryKeyboard	proc	near
	uses	ax,si,bp,es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_attrs, mask OWA_HEADER
	LONG jz	done

	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	addButton			;add button if no vardata

	cmp	{KeyboardOverride} ds:[bx], KO_NO_KEYBOARD
	LONG je	done				;don't add keyboard button
	cmp	{KeyboardOverride} ds:[bx], KO_KEYBOARD_EMBEDDED
	LONG je	done				;don't add keyboard button

addButton:
	push	si
	mov	ax, segment GenTriggerClass
	mov	es, ax
	mov	di, offset GenTriggerClass	;es:di <- ptr to class
	mov	bx, ds:[LMBH_handle]		;bx <- block to create in
	call	GenInstantiateIgnoreDirty

	;
	; Set the moniker of the trigger - ' KBD '
	;
	mov	ax, ' '
	push	ax
	mov  	ax, 'BD'
	push	ax
	mov	ax, ' K'
	push	ax
	movdw	cxdx, sssp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock
	add	sp, 6

	;
	; Add a hint to put the trigger in the title bar
	;
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	clr	cx				;cx <- no extra data
	call	ObjVarAddData

	;
	; Set action data so keyboard will come up/down when trigger is clicked
	;
	mov	ax, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	cx, 3 * (size word)
	call	ObjVarAddData
	mov	{word} ds:[bx], MANUFACTURER_ID_GEOWORKS		; cx
	mov	{word} ds:[bx+2], GWNT_HARD_ICON_BAR_FUNCTION		; dx
	mov	{word} ds:[bx+4], HIBF_DISPLAY_FLOATING_KEYBOARD	; bp

	;
	; Set the message & output of the trigger
	;
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_META_NOTIFY
	call	ObjCallInstanceNoLock

	push	si
	clr	bx
	call	GeodeGetAppObject
	movdw	cxdx, bxsi			;^lcx:dx <- appObj
	pop	si

	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	call	ObjCallInstanceNoLock

	;
	; Add the new trigger
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;^lcx:dx <- OD of trigger
	pop	si				;*ds:si <- OLBaseWin object
	call	GenAddChildUpwardLinkOnly

	mov	ax, TEMP_OL_BASE_WIN_KBD_TRIGGER
	mov	cx, (size lptr)			;cx <- size of extra data
	call	ObjVarAddData
	mov	ds:[bx], dx			;save lptr
	;
	; Finally, set the trigger usable
	;
	mov	si, dx				;*ds:si <- trigger
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	;dl <- VisUpdateMode
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
AddPrimaryKeyboard	endp

endif	; if _FLOATING_KEYBOARD_TRIGGER_ON_PRIMARY ----------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPrimaryRadioStatusIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a status icon to the left side of titlebar

CALLED BY:	OLBaseWinUpdateSpecBuild
PASS:		*ds:si - OLBaseWin object
RETURN:		ds - fixed up
DESTROYED:	ax,bx,cx,dx,di,bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY ;-------------------------------------

AddPrimaryRadioStatusIcon	proc	near
	uses	si
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_attrs, mask OWA_HEADER
	LONG jz	done

	push	si
	mov	ax, segment RadioStatusIconClass
	mov	es, ax
	mov	di, offset RadioStatusIconClass	;es:di <- ptr to class
	mov	bx, ds:[LMBH_handle]		;bx <- block to create in
	call	GenInstantiateIgnoreDirty

	mov	bx, offset Gen_offset
	call	ObjInitializePart

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GI_attrs, mask GA_INITIATES_INPUT_IGNORE

	;
	; Add a hint to put the trigger in the title bar
	;
	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	clr	cx				;cx <- no extra data
	call	ObjVarAddData

	mov	ax, HINT_FIXED_SIZE
	mov	cx, size GadgetSizeHintArgs
	call	ObjVarAddData
	mov	ds:[bx].GSHA_width, SpecWidth <SST_PIXELS, 30>
	mov	ds:[bx].GSHA_height, 0

	mov	ax, HINT_SHORT_LONG_TOUCH
	mov	cx, size ShortLongTouchParams
	call	ObjVarAddData
	mov	cx, ds:[LMBH_handle]
	mov	ds:[bx].SLTP_shortMessage, MSG_RADIO_STATUS_ICON_SHORT_TOUCH
	movdw	ds:[bx].SLTP_shortDestination, cxsi
	mov	ds:[bx].SLTP_longMessage, MSG_RADIO_STATUS_ICON_LONG_TOUCH
	movdw	ds:[bx].SLTP_longDestination, cxsi

	;
	; Add the new trigger
	;
	mov	cx, ds:[LMBH_handle]		;*ds:si <- OD of trigger
	pop	dx				;^lcx:dx <- OLBaseWin object
	call	GenSetUpwardLink

	;
	; Save radio status icon chunk handle in OLBaseWin instance data
	;
	mov	bx, dx				;*ds:bx = OLBaseWin object
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	mov	ds:[bx].OLBWI_radioStatusIcon, si

	;
	; Add to GCNList
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PENELOPE_RADIO_STATUS_NOTIFICATIONS
	call	GCNListAdd

	;
	; Finally, set the trigger usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	;dl <- VisUpdateMode
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
AddPrimaryRadioStatusIcon	endp

endif	; if RADIO_STATUS_ICON_ON_PRIMARY ----------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure this window is added to the window list

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ; We will be adding this window to the window list ------------------

OLBaseWinSpecBuild	method dynamic OLBaseWinClass, MSG_SPEC_BUILD

	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

	; Create a GenItem to represent this primary in the GenField's
	; WindowList.

	call	EnsureItemAddedToWindowList

	ret
OLBaseWinSpecBuild	endm

endif	; if TOOL_AREA_IS_TASK_BAR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureItemAddedToWindowList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure this window is added to the window list.

CALLED BY:	OLBaseWinSpecBuild
		OLBaseWinUpdateWindow
PASS:		*ds:si	- OLBaseWin object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

EnsureItemAddedToWindowList	proc	near

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	done			; skip if so...

	call	AA_DerefVisSpec_DI
	tst	ds:[di].OLBWI_windowListEntry.handle
	jnz	done			; skip if so...

	; Let's not put an item in the windowlist/taskbar if custom window and
	; ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY = LAYER_PRIO_ON_BOTTOM.
	;
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jz	continue

	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarFindData
	jnc	continue

	cmp	{LayerPriority}ds:[bx], LAYER_PRIO_ON_BOTTOM
	je	done

continue:
	mov	ax, HINT_AVOID_MENU_BAR
	call	ObjVarFindData
	jc	done
	mov	ax, HINT_PRIMARY_AVOID_MENU_BAR_IF_EXTENDIBLE_SYSTRAY
	call	ObjVarFindData
	jc	done

	; Get default field window (presume only one), where most all windows
	; of the app will be placed.
	;
	mov	cx, GUQT_FIELD
	mov	ax, MSG_SPEC_GUP_QUERY
	call	ObjCallInstanceNoLock	;^lcx:dx = Field, bp = fieldWin

	push	bp			;save fieldWin

	; Specify an "OLWindowListItemClass" object to be created
	;
	push	si
	mov	bx, cx			; ^lbx:si = field
	mov	si, dx
	mov	ax, MSG_OL_FIELD_CREATE_WINDOW_LIST_ENTRY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; returns ^lcx:dx = window list entry
	mov	ax, si			; ^lbx:ax = field
	pop	si

	; Save away optr of object just created
	;
	call	AA_DerefVisSpec_DI
	mov	ds:[di].OLBWI_windowListEntry.handle, cx
	mov	ds:[di].OLBWI_windowListEntry.chunk, dx
	pop	bp			; restore fieldWin
	jcxz	done			; exit if no window list entry

	; Setup our OLWindowListItem object to have the info it will need to
	; function correctly.
	;
	push	si
	mov	bx, cx
	xchg	si, dx			; item obj in ^lbx:si
	mov	cx, ds:[LMBH_handle]	; window obj in ^lcx:dx
	mov	ax, MSG_OL_WINDOW_LIST_ITEM_SET_OPERATING_PARAMS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	; Set moniker of Window List Entry to be a copy of the window moniker.
	;
	mov	ax, MSG_OL_BASE_WIN_SET_WINDOW_ENTRY_MONIKER
	call	ObjCallInstanceNoLock
done:
	ret
EnsureItemAddedToWindowList	endp

endif	; TOOL_AREA_IS_TASK_BAR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTaskBarList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update taskbar list to match window list

CALLED BY:	EnsureItemAddedToWindowList, EnsureItemRemovedFromWindowList
PASS:		cx	= TRUE - reinitialize list and update current selection
			  FALSE - just update current selection
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TOOL_AREA_IS_TASK_BAR
UpdateTaskBarList	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_UPDATE_TASK_BAR_LIST
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	mov	cx, di
	call	UserCallApplication
	.leave
	ret
UpdateTaskBarList	endp
endif ; TOOL_AREA_IS_TASK_BAR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinUpdateVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a new moniker is set, then we need to update the entry
		in the Window List

CALLED BY:	MSG_SPEC_UPDATE_VIS_MONIKER
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
		dl	- VisUpdateMode
		cx 	- width of old moniker
		bp 	- height of old moniker
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	1/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

OLBaseWinUpdateVisMoniker	method dynamic OLBaseWinClass,
					MSG_SPEC_UPDATE_VIS_MONIKER
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

	FALL_THRU OLBaseWinSetWindowEntryMoniker

OLBaseWinUpdateVisMoniker	endm

endif ; TOOL_AREA_IS_TASK_BAR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinSetWindowEntryMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the moniker for this window in the window list

CALLED BY:	MSG_OL_BASE_WIN_SET_WINDOW_ENTRY_MONIKER
PASS:		*ds:si	= OLBaseWinClass object
		es	= segment of OLBaseWinClass
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

OLBaseWinSetWindowEntryMoniker	method OLBaseWinClass,
				MSG_OL_BASE_WIN_SET_WINDOW_ENTRY_MONIKER
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLBWI_windowListEntry.handle
	LONG 	jz done

getTextMoniker:
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
	clc				;check window's moniker list
	call	GenFindMoniker
	tst	cx
	jnz	getIconMoniker
	stc				;check app's moniker list
	call	GenFindMoniker
	tst	cx
	LONG	jz done

getIconMoniker:

if _MOTIF

	; in Motif, get icon moniker from app monikers

	push	cx, dx
	mov	bp, mask VMSF_GSTRING or (VMS_TOOL shl offset VMSF_STYLE)
	stc				; check app's moniker list
	call	GenFindMoniker		; result: ^lcx:dx = moniker...
	tst	cx
	LONG	jz done
	mov	bx, cx			; ...but we need the icon moniker in ^lbx:di
	mov 	di, dx
	pop	cx, dx
	jmp 	haveMonikers
else
	; in ISUI, get system menu button icon moniker from window

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLWI_sysMenu
	mov	di, ds:[di].OLWI_sysMenuButton
	tst	bx
	jz	haveMonikers

	call	ObjSwapLock
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLBI_genChunk
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker
	call	ObjSwapUnlock
endif
haveMonikers:
	push	bx, cx
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	; Make it sharable so UI process can legally lock it. -dhunter 3/3/2000
	mov	ax, (0 shl 8) or (mask HF_SHARABLE)
	call	MemModifyFlags
	mov	bp, bx			;^hbp = new block
	pop	bx, cx

	call	OLBaseWinCreateCombinationMoniker
	push	bp

	tst	dx
	jz	free

	call	AA_DerefVisSpec_DI
	movdw	bxsi, ds:[di].OLBWI_windowListEntry
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
free:
	pop	bx
	call	MemFree

	; Update task bar list
	;
	mov	cx, TRUE		; re-initialize list
	call	UpdateTaskBarList
done:
	ret
OLBaseWinSetWindowEntryMoniker	endm

endif	; if TOOL_AREA_IS_TASK_BAR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinCreateCombinationMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a icon+text moniker

CALLED BY:	OLBaseWinSetWindowEntryMoniker
PASS:		*ds:si	= OLBaseWinClass object
		^lbx:di	= icon moniker
		^lcx:dx	= text moniker
RETURN:		^lcx:dx	= combination moniker in a new sharable memory block
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR	;--------------------

OLBaseWinCreateCombinationMoniker	proc	far
combMkr		local	optr		push	bp, 0
iconMkr		local	optr		push	bx, di
textMkr		local	optr		push	cx, dx
iconWidth	local	word
iconHeight	local	word
	uses	ax, bx, si, di, es
	.enter

	movdw	bxdi, ss:[iconMkr]	;^lbx:di = moniker
	tst	bx
	jnz	copyMoniker
	movdw	bxdi, ss:[textMkr]	;^lbx:di = moniker
	tst	bx
	LONG jz	done
	clr	ax			;set the zero flag = no icon moniker

copyMoniker:
	pushf
	call	ObjSwapLock		;*ds:di = moniker
	push	bx
	mov	cx, ss:[combMkr].handle
	push	bp
	mov	bp, di
	clr	ax, bx, dx, di
	call	UserCopyChunkOut	;ax = chunk handle of copy
	pop	bp
	mov	ss:[combMkr].offset, ax
	pop	bx
	call	ObjSwapUnlock
	popf
	LONG jz	done			;exit if no icon moniker

	push	ds:[LMBH_handle]

	movdw	bxsi, ss:[combMkr]
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]		;ds:si = icon VisMoniker
	test	ds:[si].VM_type, mask VMT_GSTRING
	LONG jz	unlockCombMkr

	movdw	bxdi, ss:[textMkr]
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, es:[di]		;es:di = text VisMoniker
	test	es:[di].VM_type, mask VMT_GSTRING
	jnz	unlockTextMkr

	add	di, VM_data+VMT_text
	LocalStrLength

	push	cx
DBCS <	shl	cx, 1						>
	add	cx, (size OpDrawText) + (size OpMoveTo)
	mov	bx, VM_data+VMGS_gstring
	mov	ax, ss:[combMkr].offset
	call	LMemInsertAt
	pop	cx

	mov	si, ax
	mov	si, ds:[si]		;ds:si = icon VisMoniker

	; get cached size and reset it and calculate moniker positions

	clr	ax
	xchg	ax, ds:[si].VM_width
	add	ax, 2			;ax = text moniker x position
	clr	bx
	xchg	bx, ds:[si].VM_data+VMGS_height

	push	ds
	segmov	ds, <segment systemFontHeight>, dx
	mov	dx, ds:[systemFontHeight]
	pop	ds

	sub	bx, dx			;bx = difference in height
	mov	dx, 0			;dx = icon moniker y position
	jns	iconBigger
	sar	bx, 1
	neg	bx
	xchg	bx, dx
	jmp	drawText
iconBigger:
	sar	bx, 1			;bx = text moniker y position
	adc	bx, 0
drawText:
	add	si, VM_data+VMGS_gstring
	mov	ds:[si].ODT_opcode, GR_DRAW_TEXT
	mov	ds:[si].ODT_x1, ax
	mov	ds:[si].ODT_y1, bx
	mov	ds:[si].ODT_len, cx
	add	si, size OpDrawText

	mov	di, ss:[textMkr].offset
	mov	di, es:[di]
	add	di, VM_data+VMT_text

	segxchg	ds, es
	xchg	si, di
	LocalCopyNString

	mov	es:[di].OMT_opcode, GR_MOVE_TO
	mov	es:[di].OMT_x1, 0
	mov	es:[di].OMT_y1, dx

unlockTextMkr:
	mov	bx, ss:[textMkr].handle
	call	MemUnlock

unlockCombMkr:
	mov	bx, ss:[combMkr].handle
	call	MemUnlock

	pop	bx
	call	MemDerefDS
done:
	movdw	cxdx, ss:[combMkr]

	.leave
	ret
OLBaseWinCreateCombinationMoniker	endp

endif ; TOOL_AREA_IS_TASK_BAR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinUpdateWindowEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update window list selection

CALLED BY:	MSG_OL_BASE_WIN_UPDATE_WINDOW_ENTRY
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
		cx	= TRUE/FALSE - gained/lost target
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ;--------------------------------------------------------------------

OLBaseWinUpdateWindowEntry	method dynamic OLBaseWinClass,
					MSG_OL_BASE_WIN_UPDATE_WINDOW_ENTRY
EC <	cmp	cx, TRUE						>
EC <	je	10$							>
EC <	cmp	cx, FALSE						>
EC <	ERROR_NE OL_ERROR						>
EC <10$:								>
	;
	; Find the WindowItem we created earlier, that's in the Window List
	;
	movdw	bxsi, ds:[di].OLBWI_windowListEntry
	tst	bx
	jz	done			;skip if none...

	push	cx
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = identifier
	pop	cx
	jcxz	setNoneIfSet

	mov	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	callWindowList
	jmp	updateTaskBar

setNoneIfSet:
	push	ax
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	callWindowList
	pop	cx
	cmp	ax, cx
	jne	done

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	callWindowList

updateTaskBar:
	;
	; Update task bar list
	;
	mov	cx, FALSE		; just update selection
	call	UpdateTaskBarList
done:
	ret

callWindowList:
	push	bx, si
	mov	bx, segment GenItemGroupClass
	mov	si, offset GenItemGroupClass
	clr	dx
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;ClassedEvent to cx
	pop	bx, si			;bx:si is ListEntry
	;
	; Send message to GenItemGroup
	;
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn

OLBaseWinUpdateWindowEntry	endm

endif	; TOOL_AREA_IS_TASK_BAR ------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinNotifyWindowSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring window to front.

CALLED BY:	MSG_META_NOTIFY_TASK_SELECTED
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ;--------------------------------------

OLBaseWinNotifyWindowSelected	method dynamic OLBaseWinClass,
					MSG_META_NOTIFY_TASK_SELECTED
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GI_states, mask GS_USABLE
	jz	done				; abort is window is not usable

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_BRING_TO_TOP
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLBaseWinNotifyWindowSelected	endm

endif	; TOOL_AREA_IS_TASK_BAR ---------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWindowListItemNotifyWindowSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify window that it has been selected.

CALLED BY:	MSG_META_NOTIFY_TASK_SELECTED
PASS:		*ds:si	= OLWindowListItemClass object
		ds:di	= OLWindowListItemClass instance data
		ds:bx	= OLWindowListItemClass object (same as *ds:si)
		es 	= segment of OLWindowListItemClass
		ax	= message #
RETURN:		carry set
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ; NOTE: this is not OLBaseWin, It is OLWindowListItem!

OLWindowListItemNotifyWindowSelected	method dynamic OLWindowListItemClass,
					MSG_META_NOTIFY_TASK_SELECTED

	mov	bx, ds:[di].OLWLI_windowObj.handle
	push	bx
	push	ds:[di].OLWLI_windowObj.chunk

	; Raise app to top within field
	;
	call	MemOwner			;Get owning geode
	mov	cx, bx
	mov	dx, bx				;which is also LayerID to raise
	mov	bp, ds:[di].OLWLI_parentWin
	mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	call	UserCallSystem

	; Then pass on notification to the app object
	;
	pop	si
	pop	bx
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	stc
	ret
OLWindowListItemNotifyWindowSelected	endm

endif	; TOOL_AREA_IS_TASK_BAR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWindowListItemSetOperatingParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save data.

CALLED BY:	MSG_OL_WINDOW_LIST_ITEM_SET_OPERATING_PARAMS
PASS:		*ds:si	= OLWindowListItemClass object
		ds:di	= OLWindowListItemClass instance data
		ds:bx	= OLWindowListItemClass object (same as *ds:si)
		es 	= segment of OLWindowListItemClass
		ax	= message #
		cx:dx	= window object
		bp	= field window
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ; NOTE: this is not OLBaseWin, It is OLWindowListItem ---------------

OLWindowListItemSetOperatingParams	method dynamic OLWindowListItemClass,
				MSG_OL_WINDOW_LIST_ITEM_SET_OPERATING_PARAMS
	mov	ds:[di].OLWLI_windowObj.handle, cx
	mov	ds:[di].OLWLI_windowObj.chunk, dx
	mov	ds:[di].OLWLI_parentWin, bp
	ret
OLWindowListItemSetOperatingParams	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWindowListItemCloseWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close window

CALLED BY:	MSG_OL_WINDOW_LIST_ITEM_CLOSE_WINDOW
PASS:		*ds:si	= OLWindowListItemClass object
		ds:di	= OLWindowListItemClass instance data
		ds:bx	= OLWindowListItemClass  object (same as *ds:si)
		es 	= segment of OLWindowListItem
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ; NOTE: this is not OLBaseWin, It is OLWindowListItem ---------------

OLWindowListItemCloseWindow	method dynamic OLWindowListItemClass,
					MSG_OL_WINDOW_LIST_ITEM_CLOSE_WINDOW
	mov	bx, ds:[di].OLWLI_windowObj.handle
	mov	si, ds:[di].OLWLI_windowObj.chunk

	mov	ax, MSG_GEN_DISPLAY_CLOSE
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

OLWindowListItemCloseWindow	endm

endif	; if TOOL_AREA_IS_TASK_BAR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWindowListItemKeyboardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keyboard events for WindowListItem.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= OLWindowListItemClass object
		ds:di	= OLWindowListItemClass instance data
		ds:bx	= OLWindowListItemClass object (same as *ds:si)
		es 	= segment of OLWindowListItemClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR ; NOTE: this is not OLBaseWin, It is OLWindowListItem ---------------

OLWindowListItemKeyboardChar	method dynamic OLWindowListItemClass,
					MSG_META_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS
	jz	callSuper			; callsuper if not first press

	tst	dh
	jnz	callSuper			; callsuper if any ShiftState

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_ENTER			>
DBCS <	cmp	cx, C_SYS_ENTER						>
	jne	callSuper

	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	GOTO	ObjCallInstanceNoLock

callSuper:
	mov	di, offset OLWindowListItemClass
	GOTO	ObjCallSuperNoLock

OLWindowListItemKeyboardChar	endm

endif	; if TOOL_AREA_IS_TASK_BAR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle status icon notification

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
		cx:dx	= NotificationType
				cx - NT_manuf
				dx - NT_type
		bp	= change specific data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;------------------------

RadioStatusIconNotify	method dynamic RadioStatusIconClass,
					MSG_META_NOTIFY
	cmp	dx, GWNT_PENELOPE_RADIO_STATUS_NOTIFICATION
	jne	callSuper
	mov	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper

	clr	ds:[di].RSII_iconCycleCount
	mov	ds:[di].RSII_radioStatus, bp
	call	OpenDrawObject

	mov	di, ds:[si]
	add	di, ds:[di].RadioStatusIcon_offset
	cmp	ds:[di].RSII_radioStatus, PRS_CALL_IN_PROGRESS
	jne	done

	tst	ds:[di].RSII_sysTarget
	jz	done

	GOTO	RadioStatusIconStartTimer

callSuper:
	mov	di, offset RadioStatusIconClass
	GOTO	ObjCallSuperNoLock
done:
	ret
RadioStatusIconNotify	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw radio status icon

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState to draw through
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/27/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------

RadioStatusIconDraw	method RadioStatusIconClass,
					MSG_VIS_DRAW
	push	bp
	mov	di, offset RadioStatusIconClass
	call	ObjCallSuperNoLock
	pop	di				; di = gstate

	call	VisGetBounds			; (ax,bx) = draw position
	mov	cx, ax
	mov	dx, bx				; (cx,dx) = draw position

	mov	bp, ds:[si]
	add	bp, ds:[bp].RadioStatusIcon_offset
	mov	ax, ds:[bp].RSII_radioStatus
	mov	si, offset RadioStatusOffMoniker
	cmp	ax, PRS_TRANSMITTER_OFF
	je	draw
	mov	si, offset RadioStatusOn2Moniker
	cmp	ax, PRS_TRANSMITTER_ON
	je	draw

EC <	cmp	ax, PRS_CALL_IN_PROGRESS				>
EC <	ERROR_NE -1				; invalid radio status	>

	mov	al, ds:[bp].RSII_iconCycleCount
	mov	si, offset RadioStatusOn1Moniker
	tst	al
	jz	draw
	mov	si, offset RadioStatusOn2Moniker
	dec	al
	jz	draw
	mov	si, offset RadioStatusOn3Moniker
draw:
	mov	bx, handle RadioStatusOffMoniker
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			; ds:si = bitmap to draw
	mov	ax, cx
	mov	bx, dx				; (ax,bx) = draw position
	clr	dx				; no callback
	call	GrDrawBitmap
	mov	bx, handle RadioStatusOffMoniker
	GOTO	MemUnlock

RadioStatusIconDraw	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;-----------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconCallInProgressTimerMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "call in progress" timer message

CALLED BY:	MSG_RADIO_STATUS_ICON_CALL_IN_PROGRESS_TIMER_MSG
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------

RadioStatusIconCallInProgressTimerMsg	method dynamic RadioStatusIconClass,
			MSG_RADIO_STATUS_ICON_CALL_IN_PROGRESS_TIMER_MSG
	clr	ds:[di].RSII_cycleTimer

	cmp	ds:[di].RSII_radioStatus, PRS_CALL_IN_PROGRESS
	jne	done

	inc	ds:[di].RSII_iconCycleCount
	cmp	ds:[di].RSII_iconCycleCount, PenelopeRadioStatus
	jb	10$
	clr	ds:[di].RSII_iconCycleCount
10$:
	call	OpenDrawObject
	GOTO	RadioStatusIconStartTimer
done:
	ret
RadioStatusIconCallInProgressTimerMsg	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconShortTouch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle short touch on radio status icon

CALLED BY:	MSG_RADIO_STATUS_ICON_SHORT_TOUCH
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/27/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;----------------------------

RadioStatusIconShortTouch	method dynamic RadioStatusIconClass,
					MSG_RADIO_STATUS_ICON_SHORT_TOUCH
token	local	GeodeToken
msg	local	word
	.enter

	push	ss
	lea	ax, ss:[token]
	push	ax
	push	ss
	lea	ax, ss:[msg]
	push	ax
	call	PUGETRADIOSTATUSICONSHORTTOUCH

	call	RadioStatusIconSendIACPMessage

	.leave
	ret
RadioStatusIconShortTouch	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;--------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconLongTouch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle long touch on radio status icon

CALLED BY:	MSG_RADIO_STATUS_ICON_LONG_TOUCH
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/27/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;----------------------------

RadioStatusIconLongTouch	method dynamic RadioStatusIconClass,
					MSG_RADIO_STATUS_ICON_LONG_TOUCH
token	local	GeodeToken
msg	local	word
	.enter

	push	ss
	lea	ax, ss:[token]
	push	ax
	push	ss
	lea	ax, ss:[msg]
	push	ax
	call	PUGETRADIOSTATUSICONLONGTOUCH

	call	RadioStatusIconSendIACPMessage

	.leave
	ret
RadioStatusIconLongTouch	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;--------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconSendIACPMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send IACP message

CALLED BY:	RadioStatusIconShortTouch, RadioStatusIconLongTouch
PASS:		inherit stack
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,ds,es
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/27/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;--------------------------

RadioStatusIconSendIACPMessage	proc	near
	.enter	inherit RadioStatusIconShortTouch

	tstdw	ss:[token].GT_chars
	jz	done

	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	jc	done

	push	bp
	segmov	es, ss
	lea	di, ss:[token]
	mov	bx, dx
	clr	ax
	call	IACPConnect
	mov	di, bp			; di = IACPConnection
	pop	bp
	jc	done

	push	di
	mov	bx, segment GenApplicationClass
	mov	si, offset GenApplicationClass
	mov	ax, ss:[msg]
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	bx, di
	pop	di

	push	bp
	mov	ax, IACPS_CLIENT
	clr	cx			; no completion message
	mov	dx, TO_PROCESS
	mov	bp, di
	call	IACPSendMessage
	clr	cx
	call	IACPShutdown
	pop	bp
done:
	.leave
	ret
RadioStatusIconSendIACPMessage	endp

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;----------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Primary gained sys target excl

CALLED BY:	MSG_META_GAINED_SYS_TARGET_EXCL
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------------

RadioStatusIconGainedSysTargetExcl	method dynamic RadioStatusIconClass,
					MSG_META_GAINED_SYS_TARGET_EXCL
	mov	ds:[di].RSII_sysTarget, TRUE
	cmp	ds:[di].RSII_radioStatus, PRS_CALL_IN_PROGRESS
	jne	done

	clr	ds:[di].RSII_iconCycleCount
	GOTO	RadioStatusIconStartTimer
done:
	ret
RadioStatusIconGainedSysTargetExcl	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconLostSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Primary lost sys focus excl

CALLED BY:	MSG_META_LOST_SYS_TARGET_EXCL
PASS:		*ds:si	= RadioStatusIconClass object
		ds:di	= RadioStatusIconClass instance data
		ds:bx	= RadioStatusIconClass object (same as *ds:si)
		es 	= segment of RadioStatusIconClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;---------------------------

RadioStatusIconLostSysTargetExcl	method dynamic RadioStatusIconClass,
					MSG_META_LOST_SYS_TARGET_EXCL
	mov	ds:[di].RSII_sysTarget, FALSE

	clr	bx
	xchg	bx, ds:[di].RSII_cycleTimer
	tst	bx
	jz	done

	mov	ax, ds:[di].RSII_cycleTimerID
	GOTO	TimerStop
done:
	ret
RadioStatusIconLostSysTargetExcl	endm

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;---------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RadioStatusIconStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start "call in progress" cycle timer

CALLED BY:	RadioStatusIconNotify,
		RadioStatusIconCallInProgressTimerMsg,
		RadioStatusIconGainedSysTargetExcl,
PASS:		*ds:si	= RadioStatusIconClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;---------------------

RadioStatusIconStartTimer	proc	far

	mov	di, ds:[si]
	add	di, ds:[di].RadioStatusIcon_offset
	tst	ds:[di].RSII_cycleTimer
	jnz	done

	tst	ds:[di].RSII_sysTarget
	jz	done

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]
	mov	cx, RADIO_STATUS_ICON_CYCLE_INTERVAL
	mov	dx, MSG_RADIO_STATUS_ICON_CALL_IN_PROGRESS_TIMER_MSG
	call	TimerStart

	mov	di, ds:[si]
	add	di, ds:[di].RadioStatusIcon_offset
	mov	ds:[di].RSII_cycleTimer, bx
	mov	ds:[di].RSII_cycleTimerID, ax
done:
	ret
RadioStatusIconStartTimer	endp

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;---------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureFileMenu

DESCRIPTION:	Make sure we have a File menu.

CALLED BY:	INTERNAL
			OLBaseWinUpdateSpecBuild

PASS:
	*ds:si	- OLBaseWin object

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/18/92		Initial version
	VL	7/10/95		Comment this procedure out if
				_DISABLE_APP_EXIT_UI is true.

------------------------------------------------------------------------------@
EnsureFileMenu	proc	near

if not _DISABLE_APP_EXIT_UI

	call	AA_DerefVisSpec_DI
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	LONG	jnz	done			; not for custom windows
if _GCM
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	LONG	jnz	done				; not for GCM
endif
	mov	ax, HINT_PRIMARY_NO_FILE_MENU
	call	ObjVarFindData			; carry set if found
	jc	done				; don't want "File" menu
	mov	ax, ATTR_OL_BASE_WIN_HAVE_FILE_MENU
	call	ObjVarFindData			; carry set if found
	jc	done				; have "File" menu
	;
	; don't add "File" menu if in UILM_TRANSPARENT mode and not a
	; Desk Accessory, cause all we're gonna do with it is add an "Exit"
	; trigger, which we don't want for UILM_TRANSPARENT
	;
	call	UserGetLaunchModel		; ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	addFileMenu			; not UILM_TRANSPARENT, add
	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jne	addFileMenu
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	GenCallApplication		; al = AppLaunchFlags
	test	al, mask ALF_DESK_ACCESSORY
	jz	done				; not DA, no File menu
addFileMenu:
	;
	; need to add "File" menu
	;
	push	es
	mov	cx, ds:[LMBH_handle]		; add to OLBaseWin
	mov	dx, si
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	mov	al, -1				; init USABLE
	mov	ah, -1				; one-way upward generic link
	clr	bx
	mov	bp, CCO_FIRST			; (not dirty)
	call	OpenCreateChildObject		; ^lcx:dx = "File" menu
	pop	es
	;
	; Save lptr of created "File" menu in OLBaseWin.
	;
	mov	ax, TEMP_OL_BASE_WIN_FILE_MENU
	mov	cx, size lptr
	call	ObjVarAddData
	mov	ds:[bx], dx			; save lptr of "File" menu

	mov	si, dx				; *ds:si = "File" menu
.warn -private
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GII_visibility, GIV_POPUP
.warn @private
	mov	ax, ATTR_GEN_INTERACTION_GROUP_TYPE or \
						mask VDF_SAVE_TO_STATE
	mov	cx, size GenInteractionGroupType
	call	ObjVarAddData			; ds:dx = pointer to extra data
	mov	{GenInteractionGroupType} ds:[bx], GIGT_FILE_MENU
	mov	ax, si				; *ds:ax = "File" menu
	mov	bx, mask OCF_DIRTY shl 8
	call	ObjSetFlags			; undo dirtying by ObjVarAddData
	clr	bp				; basic build
	call	VisSendSpecBuildBranch		; build it
done:

endif
	ret
EnsureFileMenu	endp

AppAttach ends

;------------------

WinClasses segment resource


COMMENT @----------------------------------------------------------------------

METHOD:         OLBaseWinNotifyOfFileMenu

DESCRIPTION:    notification that "File" menu exists

PASS:           *ds:si - instance data
                es - segment of OpenWinClass

                ax - MSG_OL_BASE_WIN_NOTIFY_OF_FILE_MENU
                ^lcx:dx - OD of "File" menu

RETURN:         carry - ?
                ax, cx, dx, bp - ?

DESTROYED:      bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        brianc	5/1892           Initial version

------------------------------------------------------------------------------@

OLBaseWinNotifyOfFileMenu   method dynamic  OLBaseWinClass, \
					MSG_OL_BASE_WIN_NOTIFY_OF_FILE_MENU

	mov	ax, ATTR_OL_BASE_WIN_HAVE_FILE_MENU	; don't save to state
	clr	cx					; no extra data
	call	ObjVarAddData
	ret

OLBaseWinNotifyOfFileMenu   endm

WinClasses ends

;--------------------

AppAttach segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinDetermineInitialMinimizedStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this app should come up minimized

CALLED BY:	OLBaseWinUpdateWindow

PASS:		*ds:si - OLBaseWinClass object
		cx - UpdateWindowFlags

RETURN:		nothing

DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 3/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBaseWinDetermineInitialMinimizedStatus	proc near

		test	cx, mask UWF_RESTORING_FROM_STATE
		jz	done

	;
	; If we're not in transparent mode, then leave it the way it is.
	;

		call	UserGetLaunchModel
		cmp	al, UILM_TRANSPARENT
		jne	done

	;
	; see if we were restored from state by the GenField, as
	; opposed to being clicked-on by the user.
	; This is a hack, since we know the GenField sets the
	; ALF_OPEN_IN_BACK flag, and this isn't set when the
	; user clicks on an app.
	;
		push	cx
		mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
		call	UserCallApplication
		pop	cx

		test	al, mask ALF_OPEN_IN_BACK
		jnz	done

	;
	; Launched by the user -- get rid of the MINIMIZED hint, if
	; it's there
	;
		mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
		call	ObjVarDeleteData
done:
		ret
OLBaseWinDetermineInitialMinimizedStatus	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinUpdateWindow -- MSG_META_UPDATE_WINDOW for
		OLBaseWinClass

DESCRIPTION:

PASS:
	*ds:si - instance data (for object in OLBaseWin class)
	es - segment of OLBaseWinClass

	ax - MSG_META_UPDATE_WINDOW

	cx	- UpdateWindowFlags
	dl	- VisUpdateMode

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/9/92		Initial version

------------------------------------------------------------------------------@
OLBaseWinUpdateWindow	method dynamic	OLBaseWinClass, MSG_META_UPDATE_WINDOW

	test	cx, mask UWF_ATTACHING
	jz	callSuper

	; Attaching:
	;

	push	ax, cx, dx

	;
	; If restoring from state, decide whether the app should be
	; minimized or not (if it was minimized before).  This is kind
	; of a hack, but the idea is this:  if the GenField is
	; restoring us from state, then we want the minimized status
	; to be the same as it was when we exited.  If we're in
	; transparent mode, however, and we were previously minimized
	; and then detached, then we want to come back full-sized.

	call	OLBaseWinDetermineInitialMinimizedStatus

	; Decided here whether applications coming up for the first time
	; should be maximized or not.  If restarting, leave in whatever state
	; they were in.
	;

	call	OLBaseWinDetermineInitialMaximizedStatus

	call	RemoveTitleBarIfPossible

	pop	ax, cx, dx

callSuper:

	push	cx
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock
	pop	cx

	test	cx, mask UWF_DETACHING
	jz	notDetaching

; detaching:

; Don't need to do this -- trigger is IGNORE_DIRTY & set up with one way generic
; linkage so that it will just disappear on detach.   -- Doug 1/29/93
;	;
;	; If we added a help trigger before, remove it now during detach
;	;
;	call	OLBaseWinRemoveHelpTrigger

if RADIO_STATUS_ICON_ON_PRIMARY
	call	OLBaseWinRemoveRadioStatusIcon
endif

if TOOL_AREA_IS_TASK_BAR
	call	EnsureItemRemovedFromWindowList
endif
	jmp	short done

notDetaching:

; FIXME!!! - should this be "if _ISUI"?
if TOOL_AREA_IS_TASK_BAR
	test	cx, mask UWF_ATTACHING
	jz	done
	call	EnsureItemAddedToWindowList
endif

done:
	ret
OLBaseWinUpdateWindow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveTitleBarIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	RemoveTitleBarIfPossible

CALLED BY:	INTERNAL
			OLBaseWinUpdateWindow
			OLBaseWinSpecSetUsable

PASS:		*ds:si = OLBaseWin

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveTitleBarIfPossible	proc	far
	;
	; If the window is maxmized and we are running UILM_TRANSPARENT mode
	; and we have no window header gadgetry, then remove the title bar
	; completely.
	;
	call	UserGetLaunchModel	;ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	leaveTitleBar		;not UILM_TRANSPARENT, leave title bar
	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jne	leaveTitleBar
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	call	ObjVarFindData
	jnc	leaveTitleBar		;not maximized, leave title bar
	call	AA_DerefVisSpec_DI
	;
	; unfortunately, it is not as simple as check OWA_HAS_SYS_MENU, etc.
	;
	; XXX: what about HINT_SEEK_TITLE_BAR_{RIGHT,LEFT}
	;
	; if express menu appears in top primary, leave title bar
	call	SpecGetExpressOptions	;ax = UIExpressOptions
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_TOP_PRIMARY shl offset UIEO_POSITION
	je	leaveTitleBar
	; if hiding help buttons, continue checks
	push	es, ax
	segmov	es, dgroup, ax			;es = dgroup
	test	es:[olHelpOptions], mask UIHO_HIDE_HELP_BUTTONS
	pop	es, ax
	jnz	10$
	; if not hiding help buttons, and no no-help-button hint, leave title
	; bar
	mov	ax, HINT_PRIMARY_NO_HELP_BUTTON
	call	ObjVarFindData
	jnc	leaveTitleBar
10$:	; if OWA_HAS_SYS_MENU is clear, then we definitely don't have header
	; gadgets, and can nuke title bar
	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU
	jz	nukeTitleBar
	; if a window menu is allowed, we have title bar
	call	SpecGetWindowOptions	;al = UIWindowOptions
	test	al, mask UIWO_WINDOW_MENU
	jnz	leaveTitleBar
	; we have no window menu (it is just a close button), if we are
	; closable, we have title bar
	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jnz	leaveTitleBar
	; if we don't allow min/max/restore controls, we can nuke title bar
	test	al, mask UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS
	jz	nukeTitleBar
	; if we do allow min/max/restore controls, and we are minimizable,
	; maximizable, or restorable, we have title bar
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE or \
					mask OWA_MINIMIZABLE
	jnz	leaveTitleBar
	test	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE
	jnz	leaveTitleBar
nukeTitleBar:
	andnf	ds:[di].OLWI_attrs, not (mask OWA_HEADER or mask OWA_TITLED)
leaveTitleBar:
	ret
RemoveTitleBarIfPossible	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinDetermineInitialMaximizedStatus

DESCRIPTION:	Determine intitial MAXIMIZED status for this primary window.
		At this time, always preserve state if restoring from state.
		If coming up fresh, we generally rely on application hints,
		though override forcing maximization in certain situations

		NOTE:  UIWO_MAXIMIZE_ON_STARTUP is set in
		SpecInit, called when this library is first loaded.

CALLED BY:	INTERNAL
		OLBaseWinUpdateWindow

PASS:		*ds:si	- base win
		cx - UpdateWindowFlags
			UWF_RESTORING_FROM_STATE

RETURN:		nothing

ALLOWED TO DESTROY:	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		set ATTR_GEN_DISPLAY_MAXIMIZED_STATE if necessary, actual
		maximization is handled in MSG_SPEC_BUILD (in OLMenuedWin).

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/11/92		Initial version
	brianc	3/12/92		Add HINT_DISPLAY_MAXIMIZED_ON_STARTUP
------------------------------------------------------------------------------@

OLBaseWinDetermineInitialMaximizedStatus	proc	near
	;
	; If restoring from state, leave ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	; (if any) alone.
	;
	test	cx, mask UWF_RESTORING_FROM_STATE
if (not _IGNORE_STATES_MAXIMIZING)
	jnz	done
else		; else of if (not _IGNORE_STATES_MAXIMIZING)
	jz	notRestoringFromState

	;
	; Check .ini file to see if we need to blindly follow the state
	; files (default) or check the system configuration.
	;
	push	ds, si, cx, dx
	mov	cx, cs
	mov	dx, offset ignoreStateKey
	mov	ds, cx
	mov	si, offset ignoreStateCategory
	call	InitFileReadBoolean
	pop	ds, si, cx, dx
	jc	done			; if not found, default is believe state
	tst	ax
	jz	done			; if not set, believe state.

	;
	; nuke this hint if it was there when we shut down, and
	; just believe the sytem's defaults for bringing up the Primary
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	call	ObjVarDeleteData

notRestoringFromState:
endif		; endif of else of if (not _IGNORE_STATES_MAXIMIZING)

	;
	; If HINT_DISPLAY_MAXIMIZED_ON_STARTUP, maximize.  This is
	; spui dependent.  This code implements default-to-non-maximized.
	; Check HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP instead, if we
	; change to default-to-maximized.
	;
	mov	ax, HINT_DISPLAY_MAXIMIZED_ON_STARTUP
	call	ObjVarFindData		; carry set if found
	jc	setMax			; found, set max
	;
	; Test global Motif flag, initialized in library init code based on
	; system conditions (See SpecInitDefaultDisplayScheme).
	;
	push	es
	segmov	es, dgroup, ax
	test	es:[olWindowOptions], mask UIWO_MAXIMIZE_ON_STARTUP
	pop	es
	jz	done
setMax:

	;
	; set maximized if spui lets us -- hints could clear this
	;
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	done
	;
	; set maximized, will be evaluated in MSG_SPEC_BUILD.
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
done:
	ret
OLBaseWinDetermineInitialMaximizedStatus	endp

if _IGNORE_STATES_MAXIMIZING
LocalDefNLString	ignoreStateCategory, <'ui features',0>
LocalDefNLString	ignoreStateKey, <'ignoreStatesMaximizing',0>
endif		; if _IGNORE_STATES_MAXIMIZING

AppAttach ends

;-------------------------------

Unbuild	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinSpecUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove this window from the window list before doing
		normal unbuild.

CALLED BY:	MSG_SPEC_UNBUILD
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLBaseWinSpecUnbuild	method dynamic OLBaseWinClass, MSG_SPEC_UNBUILD

	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

	;
	; If we added objects to the primary during spec build,
	; remove them now during unbuild
	;
	call	OLBaseWinRemoveSpecBuildCreatedObjects

if RADIO_STATUS_ICON_ON_PRIMARY
	call	OLBaseWinRemoveRadioStatusIcon
endif

if TOOL_AREA_IS_TASK_BAR
	call	EnsureItemRemovedFromWindowList
endif

	ret
OLBaseWinSpecUnbuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinRemoveSpecBuildCreatedObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove ui objects added to this OLBaseWin during spec build

CALLED BY:	INTERNAL
			OLBaseWinSpecUnbuild

PASS:		*ds:si = OLBaseWin

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/25/93		Broke out of OLBaseWinUpdateWindow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBaseWinRemoveSpecBuildCreatedObjects	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
if _GCM
	mov	ax, ds:[di].OLBWI_gcmLeftIcon
	tst	ax
	jz	afterLeftGCM
	call	OLBWRSBO_genDestroy		;destroy GCM left moniker

afterLeftGCM:
endif
	mov	ax, TEMP_OL_BASE_WIN_HELP_TRIGGER
	call	OLBWRSBO_destroyIfFound

if _FLOATING_KEYBOARD_TRIGGER_ON_PRIMARY
	mov	ax, TEMP_OL_BASE_WIN_KBD_TRIGGER
	call	OLBWRSBO_destroyIfFound
endif

	mov	ax, TEMP_OL_BASE_WIN_FILE_MENU
	FALL_THRU OLBWRSBO_destroyIfFound
OLBaseWinRemoveSpecBuildCreatedObjects	endp

; Pass:	ax = vardata
;
OLBWRSBO_destroyIfFound	proc	near
	call	ObjVarFindData
	jc	destroy				;destroy if found
	ret

destroy:
	mov	ax, ds:[bx]			;ax <- lptr of object
	call	ObjVarDeleteDataAt
	FALL_THRU OLBWRSBO_genDestroy
OLBWRSBO_destroyIfFound	endp

; Pass: ax = lptr of object to destroy
;
OLBWRSBO_genDestroy	proc	near
	push	si
	mov_tr	si, ax
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp				;bp <- don't dirty
	call	ObjCallInstanceNoLock
	pop	si
	ret
OLBWRSBO_genDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureItemRemovedFromWindowList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that this window is removed from the window list

CALLED BY:	OLBaseWinSpecUnbuild
		OLBaseWinUpdateWindow

PASS:		*ds:si	- OLBaseWin object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, ds
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

EnsureItemRemovedFromWindowList	proc	far
	clr	bx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	bx, ds:[di].OLBWI_windowListEntry.handle
	tst	bx
	jz	done

	push	si
	mov	si, ds:[di].OLBWI_windowListEntry.chunk
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	cx, TRUE		; re-initialize list
	call	UpdateTaskBarList
done:
	ret
EnsureItemRemovedFromWindowList	endp

endif	;TOOL_AREA_IS_TASK_BAR

Unbuild ends

;-------------------------------

Geometry segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLBaseWinGetMinSize

SYNOPSIS:	Returns the minimum size for a window.

CALLED BY:	INTERNAL

PASS:		*ds:si -- object

RETURN:		cx -- minimum width
		dx -- minimum height

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 1/89	Initial version

------------------------------------------------------------------------------@

OLBaseWinGetMinSize	method dynamic	OLBaseWinClass, \
			MSG_VIS_COMP_GET_MINIMUM_SIZE

	;call superclass to get minimum size info

	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

	;now, since this is a GenPrimary, it may have to display the
	;Workspace and Application icons in the future - let's set aside
	;the room for them now.

OLS <	add	cx, OLS_WIN_ICON_WIDTH*5	;was *2			>
CUAS <	add	cx, CUAS_WIN_ICON_WIDTH*2				>
	ret
OLBaseWinGetMinSize	endm

Geometry ends

;-------------------------------

WinIconCode segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinMoveOffScreen

DESCRIPTION:	Moves base window off-screen, then performs superclass action

PASS:
	*ds:si - instance data (for object in OLBaseWin class)
	es - segment of OLBaseWinClass

	ax - MSG_GEN_DISPLAY_SET_MINIMIZED
	cx, dx, bp	- data to pass on to superclass handler

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version
	Joon	11/92		PM additions

------------------------------------------------------------------------------@
OLBaseWinMoveOffScreen	method dynamic	OLBaseWinClass, \
						MSG_GEN_DISPLAY_SET_MINIMIZED

	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	done				; not minimizable, do nothing
	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jnz	done				; already minimized, do nothing

	;let superclass set OLWSS_MINIMIZED

	call	OLWinMoveOffScreen		; Move window off-screen first,
						; to minimize calculations,
						; drawing, for both speed &
						; visual effect


	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

if _NO_WIN_ICONS
	; Since we do not create an icon when we minimize, we need to make
	; sure that some other object has the active focus/target.

	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_FORCE_QUEUE		; (but do this after the window
	call	ObjMessage			; is actually up on screen)
endif

done:
	ret
OLBaseWinMoveOffScreen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinSetNotMinimized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call superclass and update express menu

CALLED BY:	MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if PLACE_EXPRESS_MENU_ON_PRIMARY and (not TOOL_AREA_IS_TASK_BAR)
OLBaseWinDisplaySetNotMinimized	method dynamic OLBaseWinClass,
					MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock

	call	OLBaseWinUpdateExpressToolArea
	ret
OLBaseWinDisplaySetNotMinimized	endm
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY and (not TOOL_AREA_IS_TASK_BAR)


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinMoveOffScreen

DESCRIPTION:	Move window off-screen, so it will not be visible

CALLED BY:	INTERNAL

PASS:
	*ds:si	- VisComp object

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version
------------------------------------------------------------------------------@
OLWinMoveOffScreen	proc	near	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW		>
EC <	ERROR_Z	OL_ERROR						>
	mov	di, ds:[di].VCI_window	; get window handle
	or	di, di
	jz	done			; if no window, done

	call	WinGetWinScreenBounds	; Get current bounds of window
	tst	cx			; If right edge is negative, done.
	js	done

	mov	ax, cx			; Otherwise, move right edge to left
	neg	ax			; edge of screen,
	dec	ax			; & one more to be completely off.
	clr	bx			; leave as is vertically
	clr	si			; move relative
	call	WinMove
done:
	.leave
	ret
OLWinMoveOffScreen	endp

WinIconCode	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinGainedSystemTargetExcl

DESCRIPTION:	We intercept this method here so that we can update the
		TaskEntry in the express menu.

PASS:		*ds:si - instance data
		ax - MSG_META_GAINED_SYS_TARGET_EXCL

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	Doug	6/91		Switched from focus to target interception

------------------------------------------------------------------------------@
OLBaseWinGainedSystemTargetExcl	method dynamic	OLBaseWinClass,
					MSG_META_GAINED_SYS_TARGET_EXCL

	call	WinClasses_ObjCallSuperNoLock_OLBaseWinClass

if PLACE_EXPRESS_MENU_ON_PRIMARY ;and (not TOOL_AREA_IS_TASK_BAR)
	push	es
	segmov	es, dgroup, ax
	mov	ax, es:[olExpressOptions]
	pop	es
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_NONE shl offset UIEO_POSITION
	je	afterExpressMenu		; if turned off, size = 0
	cmp	ax, UIEP_LOWER_LEFT shl offset UIEO_POSITION
	je	afterExpressMenu		; if lower left, don't place
						;	in primary

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLBWI_flags, mask OLBWF_REJECT_EXPRESS_TOOL_AREA
	jz	haveExpress

	call	OLBaseWinHideExpressToolArea ; wrap with if

	jmp	short afterExpressMenu

haveExpress:
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY

if PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR
	; Set flag indicating we have the express tool area now, &
	; move it to the correct place.
	;
	call	WinClasses_DerefVisSpec_DI
EC <	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA	>
EC <	ERROR_NZ	OL_ERROR					>
	ornf	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR

if PLACE_EXPRESS_MENU_ON_PRIMARY ;and (not TOOL_AREA_IS_TASK_BAR)
	; Cheat -- instead of doing full geometry, just update
	; OLWI_titleBarBounds to reflect the addition of the express tool area.
	;
	call	OLBaseWinAdjustTitleBoundsForExpressToolArea

;if REDO_GEOMETRY_FOR_EXPRESS_MENU
	; If we're putting the menu bar in the title area, we need to
	; invalidate the geometry of the menu bar so it gets resized.
	;
	call	OLRedoMenuBarGeometryIfMenusInHeader
;endif
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY

if PLACE_EXPRESS_MENU_ON_PRIMARY ;or TOOL_AREA_IS_TASK_BAR
	; Now that the new title bounds have been determined, ask the field
	; to position the little tool area over the edge of it.
	;
	call	OLBaseWinUpdateExpressToolArea
afterExpressMenu:
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR

if RADIO_STATUS_ICON_ON_PRIMARY
	mov	ax, MSG_META_GAINED_SYS_TARGET_EXCL
	call	OLBaseWinUpdateStatusIcon
endif

	; Now set some INVALID flags indicating how much of the header area
	; should be redrawn.
	;
	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
	call	OpenWinHeaderMarkInvalid

	;Have our GenApplication update the GenItem which represents this
	;GenPrimary in the ApplicationMenu

	mov	cx, TRUE
	FALL_THRU	UpdateAppMenuItemCommon
OLBaseWinGainedSystemTargetExcl	endp


UpdateAppMenuItemCommon	proc	far

if TOOL_AREA_IS_TASK_BAR
	push	cx
	mov	ax, MSG_OL_BASE_WIN_UPDATE_WINDOW_ENTRY
	call	ObjCallInstanceNoLock
	pop	cx
endif
	mov	ax, MSG_OL_APP_UPDATE_TASK_ENTRY
	call	GenCallApplication
	ret
UpdateAppMenuItemCommon	endp


;if REDO_GEOMETRY_FOR_EXPRESS_MENU
OLRedoMenuBarGeometryIfMenusInHeader	proc	near
	; If we're putting the menu bar in the title area, we need to
	; invalidate the geometry of the menu bar so it gets resized.
	;
	call	OpenWinCheckMenusInHeader
	jnc	noInval
	call	WinClasses_DerefVisSpec_DI
	push	si
	mov	bx, ds:[LMBH_handle]
	mov	si, ds:[di].OLMDWI_menuBar
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	pop	si
noInval:
	ret
OLRedoMenuBarGeometryIfMenusInHeader	endp
;endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinHideExpressToolArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide the express tool area by moving it off screen

CALLED BY:	OLBaseWinGainedSystemTargetExcl
PASS:		*ds:si	= instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/15/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if PLACE_EXPRESS_MENU_ON_PRIMARY ;and (not TOOL_AREA_IS_TASK_BAR)
OLBaseWinHideExpressToolArea	proc	near

	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	dx, size OLFieldMoveToolAreaParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].OLFMTAP_geode, 0	; park the tool area off screen
	mov	ss:[bp].OLFMTAP_xPos, 0	; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_yPos, 0	; not needed for parking off-screen
					; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_layerPriority, 0
	mov	ax, MSG_OL_FIELD_MOVE_TOOL_AREA
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	add	sp, size OLFieldMoveToolAreaParams
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent

	ret
OLBaseWinHideExpressToolArea	endp
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY and (not TOOL_AREA_IS_TASK_BAR)



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinAdjustTitleBoundsForExpressToolArea

DESCRIPTION:	Adjusts bounds of title area to be smaller if this app
		currently has the express tool area associated with it.

CALLED BY:	INTERNAL
		OLBaseWinGainedTargetExcl (Calls here from above to avoid full
					   geometry)
		OpenWinCalcWinHdrGeometry (cwinClassCommon.asm - WinCommon)

PASS:		*ds:si	- OLWinClass

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@
if PLACE_EXPRESS_MENU_ON_PRIMARY ;and (not TOOL_AREA_IS_TASK_BAR)
OLBaseWinAdjustTitleBoundsForExpressToolArea	proc	far

	; If doesn't have Express tool area, then nothing to adjust.
	;
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA
	jz	done

	; Adjust left edge of title area
	;
	call	OLBaseWinGetExpressMenuButtonWidth
	call	WinClasses_DerefVisSpec_DI
	add	ds:[di].OLWI_titleBarBounds.R_left, bp
done:
	ret
OLBaseWinAdjustTitleBoundsForExpressToolArea	endp
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY and (not TOOL_AREA_IS_TASK_BAR)



COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinLostSystemTargetExcl

DESCRIPTION:	We intercept this method here so that we can release our
		hold on the express menu

PASS:		*ds:si - instance data
		ax - MSG_META_LOST_SYS_TARGET_EXCL

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@
OLBaseWinLostSystemTargetExcl	method dynamic	OLBaseWinClass,
					MSG_META_LOST_SYS_TARGET_EXCL

	call	WinClasses_ObjCallSuperNoLock_OLBaseWinClass

if PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR
;
; we cannot use olExpressOptions as MSG_META_LOST_SYS_TARGET_EXCL could
; come in after we've switched to another field and updated olExpressOptions
; for that field.  Instead, we'll just depend on OLBWF_HAS_EXPRESS_TOOL_AREA
; - brianc 11/30/92
if 0
	push	es
	segmov	es, dgroup, ax
	mov	ax, es:[olExpressOptions]
	pop	es
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_NONE shl offset UIEO_POSITION
	je	afterExpressMenu		; if turned off, no geometry
	cmp	ax, UIEP_LOWER_LEFT shl offset UIEO_POSITION
	je	afterExpressMenu		; if lower left, no geometry

	call	WinClasses_DerefVisSpec_DI
EC <	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA or\
				     mask OLBWF_REJECT_EXPRESS_TOOL_AREA>
EC <	ERROR_Z	OL_ERROR		;one of them should be set	>

	test	ds:[di].OLBWI_flags, mask OLBWF_REJECT_EXPRESS_TOOL_AREA
	jnz	afterExpressMenu

EC <	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA	>
EC <	ERROR_Z	OL_ERROR						>
	andnf	ds:[di].OLBWI_flags, not mask OLBWF_HAS_EXPRESS_TOOL_AREA

else

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA
	jz	afterExpressMenu
	andnf	ds:[di].OLBWI_flags, not mask OLBWF_HAS_EXPRESS_TOOL_AREA

endif
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR

if PLACE_EXPRESS_MENU_ON_PRIMARY ;and (not TOOL_AREA_IS_TASK_BAR)

	; Adjust left edge of title area
	;
	call	OLBaseWinGetExpressMenuButtonWidth
	call	WinClasses_DerefVisSpec_DI
	sub	ds:[di].OLWI_titleBarBounds.R_left, bp

	; If we're putting the menu bar in the title area, we need to
	; invalidate the geometry of the menu bar so it gets resized.
	;
if REDO_GEOMETRY_FOR_EXPRESS_MENU
	call	OLRedoMenuBarGeometryIfMenusInHeader
endif
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY and (not TOOL_AREA_IS_TASK_BAR)

afterExpressMenu:

if RADIO_STATUS_ICON_ON_PRIMARY
	mov	ax, MSG_META_LOST_SYS_TARGET_EXCL
	call	OLBaseWinUpdateStatusIcon
endif

	; Now set some INVALID flags indicating how much of the header area
	; should be redrawn.
	;
	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
	call	OpenWinHeaderMarkInvalid

if TOOL_AREA_IS_TASK_BAR
	mov	ax, MSG_OL_BASE_WIN_UPDATE_WINDOW_ENTRY
	clr	cx
	call	ObjCallInstanceNoLock
endif

	ret
OLBaseWinLostSystemTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinUpdateStatusIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update status icon if necessary

CALLED BY:	OLBaseWinGainedTargetExcl, OLBaseWinLostSystemTargetExcl
PASS:		*ds:si	= instance data
		ax	= MSG_META_{GAINED/LOST}_SYS_TARGET_EXCL
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;----------------------

OLBaseWinUpdateStatusIcon	proc	near
	uses	ax,cx,dx,bp,si
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].OLBWI_radioStatusIcon
	tst	si
	jz	done

	call	ObjCallInstanceNoLock
done:
	.leave
	ret
OLBaseWinUpdateStatusIcon	endp

endif ; RADIO_STATUS_ICON_ON_PRIMARY ;-----------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinRemoveRadioStatusIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove radio status icon

CALLED BY:	OLBaseWinSpecUnbuild, OLBaseWinUpdateWindow
PASS:		*ds:si	= OLBaseWinClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	3/26/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if RADIO_STATUS_ICON_ON_PRIMARY	;-----------------------

OLBaseWinRemoveRadioStatusIcon	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	dx
	xchg	dx, ds:[di].OLBWI_radioStatusIcon
	tst	dx
	jz	done

	mov	cx, ds:[LMBH_handle]
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PENELOPE_RADIO_STATUS_NOTIFICATIONS
	call	GCNListRemove
EC <	ERROR_NC -1							>
done:
	.leave
	ret
OLBaseWinRemoveRadioStatusIcon	endp

endif ; RADIO_STATUS_ICON_ON_PRIMARY	;---------------

WinClasses	ends

ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLBaseClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	ax:bp	- Class of target object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


OLBaseWinGetTargetAtTargetLevel	method dynamic	OLBaseWinClass, \
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_GEN_PRIMARY
	mov	bx, Vis_offset
	mov	di, offset OLWI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
OLBaseWinGetTargetAtTargetLevel	endm

ActionObscure	ends


WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinGenCloseInteraction -- MSG_GEN_CLOSE_INTERACTION
		handler for OLBaseWinClass

DESCRIPTION:	We intercept this method here because it has a distinct meaning
		to applications: QUIT!

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		MSG_OL_WIN_CLOSE is handled by OLMenuedWinClass where it
		its transformed into MSG_GEN_DISPLAY_CLOSE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Doug	4/93		Special behavior for transparent detach DA's
	VL	7/11/95		Always moves things to back if
				_DISABLE_APP_EXIT_UI if true.

------------------------------------------------------------------------------@

OLBaseWinGenCloseInteraction	method	dynamic OLBaseWinClass, \
						MSG_GEN_DISPLAY_CLOSE

	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jz	done			;skip if not closable

	add	bx, ds:[bx].Gen_offset	;set ds:bx = Gen instance data
	test	ds:[bx].GDI_attributes, mask GDA_USER_DISMISSABLE
	jz	done			;skip if not dismissable...

ife (_DISABLE_APP_EXIT_UI)
	;
	; Just quit app if standard launch mode.
	;
	call	UserGetLaunchModel	;ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	closeApp

	; If in transparent mode, but closable apps are allowed,
	; then close the app, otherwise, just move it to the back
	; (hide it)

	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jz	moveToBack
closeApp:

	mov	ax, MSG_META_QUIT
	GOTO	GenCallApplication
endif	; not (_DISABLE_APP_EXIT_UI)

moveToBack:
	;
	; If this is a DA running ON_TOP, drop the priority to standard,
	; so we can hide in back as with other apps in the app cache.
	;
	clr	bx
	call	GeodeGetAppObject
	call	ObjSwapLock
	call	OLAppLowerLayerPrioIfDeskAccessory
	call	ObjSwapUnlock
	;
	; Now lower to bottom to force focus/target change
	;
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

done:
	ret
OLBaseWinGenCloseInteraction	endm

WinMethods	ends

;-------------------------------

WinClasses	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept MSG_VIS_OPEN so we can draw "zoom-lines"
		before the window comes up.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
		^hbp	= parent window

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ZOOM_LINES

OLBaseWinVisOpen	method dynamic OLBaseWinClass, MSG_VIS_OPEN

	call	DrawZoomLines

	call	WinClasses_ObjCallSuperNoLock_OLBaseWinClass
	ret

OLBaseWinVisOpen	endm

endif						; if _ZOOM_LINES



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinVisClose

DESCRIPTION:	Intercept this method here as the window is closing
		To see if we cna't find another suitable object to take the
		focus/target exclusives.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Joon	11/92		PM zoom lines

------------------------------------------------------------------------------@

OLBaseVisClose	method dynamic	OLBaseWinClass, MSG_VIS_CLOSE

if _ZOOM_LINES
	call	DrawZoomLines
endif

	;call super class
	;
	call	WinClasses_ObjCallSuperNoLock_OLBaseWinClass

	; Ensure Focus & Target exist within application (window on close
	; will first release these exclusives if it has them)
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	GOTO	GenCallApplication

OLBaseVisClose	endp



if _ZOOM_LINES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawZoomLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw zoom lines before a window opens to indicate where
		the window was opened from.

CALLED BY:
PASS:		*ds:si	= instance data
		ax	= MSG_VIS_OPEN if opening zoom lines
			  MSG_VIS_CLOSE if closing zoom lines
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawZoomLines	proc	far
openCloseMsg	local	word		push	ax
zoomLine	local	Rectangle
zoomIncrement	local	Rectangle
lineCount	local	word
if	 _ROUND_THICK_DIALOGS
zoomRegionOffset	local	word
endif	;_ROUND_THICK_DIALOGS
	uses	ax, si
	.enter

	;
	; Get window handle of the field window.  We use the field window
	; to reference mouse position.
	;
	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, GUQT_FIELD
	push	bp
	call	ObjCallInstanceNoLock
	mov	di, bp
	pop	bp
	tst	di
	LONG	jz	done

	;
	; Check for hint which indicates whether we should draw zoom-lines.
	;
	mov	ax, HINT_PRIMARY_OPEN_ICON_BOUNDS
	call	ObjVarFindData

;
; If we are Zooming all primarys:  We want to stuff the hint with
; the mouses's position for opening.  If we are closing and can't
; find the hint then it has been nuked by a transparent detatch,
; and so we want skip drawing the close lines.
; dlitwin 3/4/94
;
if _ZOOM_ALL_PRIMARYS
	jc	gotVarData

	cmp	ss:[openCloseMsg], MSG_VIS_CLOSE	; opening or closing
LONG	je	done

	call	ZoomLinesStuffPositionHint

gotVarData:
else						; else of if _ZOOM_ALL_PRIMARYS
;
; If not zooming all primarys then we exit if we don't find the
; hint.
;
	LONG	jnc	done
endif					; end of else of if _ZOOM_ALL_PRIMARYS

if	 _ROUND_THICK_DIALOGS
	;
	; Figure out which region to zoom with.  NOTE: *ds:si must still be
	; pointing to object.
	;
	mov	ss:[zoomRegionOffset], offset RoundedPrimaryResizeRegion
	call	OpenWinShouldHaveRoundBorderFar
	jc	useRoundBorder
	mov	ss:[zoomRegionOffset], offset PrimaryResizeRegion

useRoundBorder:
endif	;_ROUND_THICK_DIALOGS

	mov	ss:[lineCount], 15		; 15 iterations of zoom-lines

	cmp	ss:[openCloseMsg], MSG_VIS_CLOSE	; opening or closing
	je	closing
	;
	; If left bound is PARAM_0, then we will be starting zoom-lines from
	; the center of the window.
	;
	mov	ax, ds:[bx].R_left
	cmp	ax, PARAM_0
	jne	getIconBounds
	;
	; Get window bounds and calculate the center of the window.
	;
	call	VisGetBounds
	mov	si, ax
	add	si, cx
	shr	si, 1
	mov	ss:[zoomLine].R_left, si
	mov	ss:[zoomLine].R_right, si

	mov	si, bx
	add	si, dx
	shr	si, 1
	mov	ss:[zoomLine].R_top, si
	mov	ss:[zoomLine].R_bottom, si
	mov	si, cx
	jmp	short calcIncrements

getIconBounds:
	;
	; Get icon bounds from hint data.
	;
	mov	ss:[zoomLine].R_left, ax
	mov	ax, ds:[bx].R_top
	mov	ss:[zoomLine].R_top, ax
	mov	ax, ds:[bx].R_right
	mov	ss:[zoomLine].R_right, ax
	mov	ax, ds:[bx].R_bottom
	mov	ss:[zoomLine].R_bottom, ax
	;
	; Get final position of zoom lines.
	;
	call	VisGetBounds
	mov	si, cx
	jmp	short calcIncrements

closing:
	;
	; For closing windows, we start zoom-lines from the window bounds
	; and shrink down to the center of the window.
	;
	call	VisGetBounds
	mov	ss:[zoomLine].R_left, ax
	mov	ss:[zoomLine].R_top, bx
	mov	ss:[zoomLine].R_right, cx
	mov	ss:[zoomLine].R_bottom, dx

	add	ax, cx
	shr	ax, 1
	mov	si, ax

	add	bx, dx
	shr	bx, 1
	mov	dx, bx

calcIncrements:
	;
	; Calculate the increments by which we will change the zoom-line bounds
	;
	mov	cl, 4

	sub	ax, ss:[zoomLine].R_left
	sar	ax, cl
	mov	ss:[zoomIncrement].R_left, ax

	sub	bx, ss:[zoomLine].R_top
	sar	bx, cl
	mov	ss:[zoomIncrement].R_top, bx

	sub	si, ss:[zoomLine].R_right
	sar	si, cl
	mov	ss:[zoomIncrement].R_right, si

	sub	dx, ss:[zoomLine].R_bottom
	sar	dx, cl
	mov	ss:[zoomIncrement].R_bottom, dx

lineLoop:
	call	ImGetMousePos			; get mouse position
	push	bp				; save stack frame pointer
	push	cx				; pass mouse x-position
	push	dx				; pass mouse y-position

	mov	ax, ss:[zoomLine].R_left	; get bounds for zoom-lines
	mov	bx, ss:[zoomLine].R_top		;
	mov	cx, ss:[zoomLine].R_right	;
	mov	dx, ss:[zoomLine].R_bottom	;

	mov	si, cx				; draw zoom-lines only if
	sub	si, ax				;  it's wider than
	cmp	si, 2 * (RESIZE_WIDTH+1)	;  2 * (RESIZE_WIDTH+1)
	jl	pop4				; otherwise, next zoom-line

	mov	si, dx				; draw zoom-lines only if
	sub	si, bx				;  it's wider than
	cmp	si, 2 * (RESIZE_WIDTH+1)	;  2 * (RESIZE_WIDTH+1)
	jl	pop4				; otherwise, next zoom-line

	mov	si, handle PrimaryResizeRegion	; push location of region
	push	si				;  definition of zoom-lines
if	 _ROUND_THICK_DIALOGS			;
	push	ss:[zoomRegionOffset]		; bp should still be valid here.
else	;_ROUND_THICK_DIALOGS is FALSE		;
	mov	si, offset PrimaryResizeRegion	;
	push	si				;
endif	;_ROUND_THICK_DIALOGS			;

	mov	si, mask XF_RESIZE_PENDING	; lines should not follow mouse
	mov	bp, 0ffffh			; no end match action
	call	ImStartMoveResize		; draw new zoom-lines
nextLine:
	pop	bp				; restore stack frame pointer
	add	ax, ss:[zoomIncrement].R_left	;
	mov	ss:[zoomLine].R_left, ax	;
	add	bx, ss:[zoomIncrement].R_top	;
	mov	ss:[zoomLine].R_top, bx		; calculate bounds for next
	add	cx, ss:[zoomIncrement].R_right	;  set of zoom-lines
	mov	ss:[zoomLine].R_right, cx	;
	add	dx, ss:[zoomIncrement].R_bottom	;
	mov	ss:[zoomLine].R_bottom, dx	;

	call	ImStopMoveResize		; erase previous zoom-lines

	dec	ss:[lineCount]			; decrement line count
	jnz	lineLoop
done:
	.leave
	ret

pop4:
	;
	; Since we skipped this iteration of ImStartMoveResize, we must make
	; sure to pop the 2 words that we have already pushed onto the stack.
	;
	add	sp, 4
	jmp	short nextLine

DrawZoomLines	endp


if _ZOOM_ALL_PRIMARYS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomLinesStuffPositionHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are zooming all primarys (as opposed to just those
		with the HINT_PRIMARY_OPEN_ICON_BOUNDS hint) then when we
		don't encounter this hint we stuff it with the mouse position

CALLED BY:	DrawZoomLines

PASS:		*ds:si	= GenPrimary
		ds:bx	= HINT_PRIMARY_OPEN_ICON_BOUNDS data
		di	= GState
RETURN:		ds:bx	= set to mouse position
DESTROYED:	ax, cx, dx

SIDE EFFECTS:
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZoomLinesStuffPositionHint	proc	near
	.enter

	mov	ax, HINT_PRIMARY_OPEN_ICON_BOUNDS
	mov	cx, size Rectangle
	call	ObjVarAddData

	call	ImGetMousePos
	mov	ds:[bx].R_left, cx
	mov	ds:[bx].R_right, cx
	mov	ds:[bx].R_top, dx
	mov	ds:[bx].R_bottom, dx

	.leave
	ret
ZoomLinesStuffPositionHint	endp
endif 						;_ZOOM_ALL_PRIMARYS
endif						; if _ZOOM_LINES

WinClasses	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinGetMenuBarWin -- MSG_GET_MENU_BAR_WIN
		for OLBaseWinClass

DESCRIPTION:	Return the handle of the associated MenuBarWin if one
		exists

PASS:
	*ds:si - instance data
	es - segment of OLBaseWinClass

	ax - MSG_GET_MENU_BAR_WIN

	cx:dx - 0

RETURN:
	cx:dx - optr of MenuBarWin

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@


OLBaseWinGetMenuBarWin	method dynamic	OLBaseWinClass, MSG_GET_MENU_BAR_WIN
	mov	dx, ds:[di].OLMDWI_menuBar
	clr	cx				;assume no menu bar
	tst	dx
	jz	exit
	mov	cx, ds:[LMBH_handle]
exit:
	ret

OLBaseWinGetMenuBarWin	endp

WinMethods	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinGupQuery -- MSG_SPEC_GUP_QUERY for OLBaseWinClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

	ax - MSG_SPEC_GUP_QUERY
	cx - Query type (GenQueryType or SpecGenQueryType)
	dx -
	bp -
RETURN:
	carry - set if query acknowledged, clear if not
	cx:dx - handle of GenPrimary

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

THIS IS OLD
	if (query = SGQT_FIND_PRIMARY) {
		;look for GenPrimary - return our handle
	} else {
		send query to superclass (will send to generic parent)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLBaseWinGupQuery	method dynamic	OLBaseWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_IS_CHILD_OF_PRIMARY	;can we answer this query?
	je	isChildOfPrimary		;skip if so...

	;we can't answer this query: call super class to handle

	mov	di, offset OLBaseWinClass
	GOTO	ObjCallSuperNoLock

isChildOfPrimary:
	mov	cx, TRUE
queryAnswered:
	stc
	ret
OLBaseWinGupQuery	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinUseLongTermMoniker --
		MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER for OLBaseWinClass

DESCRIPTION:	Switch to specific long term moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of OLBaseWinClass
		ax 	- MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER

		cx	- long term moniker chunk to use

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/19/92		Initial version

------------------------------------------------------------------------------@
OLBaseWinUseLongTermMoniker	method	dynamic OLBaseWinClass, \
				MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER

	call	WinClasses_DerefGen_DI
	cmp	cx, ds:[di].GPI_longTermMoniker	;same chunk?
	je	done				;skip if so...
	mov	ds:[di].GPI_longTermMoniker, cx
	;
	; resolve moniker list, if necessary
	;	cx = moniker chunk
	;
	mov	ax, MSG_SPEC_RESOLVE_MONIKER_LIST
	call	ObjCallInstanceNoLock		; resolve in-place

	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
					;should we set title area also invalid
					;in case moniker is getting smaller?
	call	OpenWinHeaderMarkInvalid
done:
	ret
OLBaseWinUseLongTermMoniker	endm

WinClasses	ends


WinUncommon	segment resource

if _GCM	;----------------------------------------------------------------------

WinUncommon_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinUncommon_DerefVisSpec_DI	endp

WinUncommon_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
WinUncommon_ObjMessageCallFixupDS	endp

endif	; _GCM ----------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinDrawGCMIcon

DESCRIPTION:	Draw the Exit or Help buttons in the header of this window.

PASS:		*ds:si	= instance data for object
		di	= GState to use

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

if _GCM

OLBaseWinDrawGCMIcon	proc	far
	push	si, di			;save GState
	mov	bp, di			;bp = GState
	call	WinUncommon_DerefVisSpec_DI
	add	di, ax			;ds:[di] = OD of button
	tst	ds:[di].handle
	jz	DrawIconCommon_done

	mov	bx, ds:[LMBH_handle]

	mov	si, ds:[di].chunk
					;pass bp = GState, cl = DrawFlags
	mov	ax, MSG_OL_BUTTON_SET_DRAW_STATE_UNKNOWN
					;force button to do a full redraw.
	call	WinUncommon_ObjMessageCallFixupDS

	mov	ax, MSG_VIS_DRAW
	call	WinUncommon_ObjMessageCallFixupDS

	;Since we are handling draw directly, reset the image invalid flags >

	mov	cx, (mask VOF_IMAGE_INVALID or mask VOF_IMAGE_UPDATE_PATH) shl 8
	stc				;^lbx:si is object
	call	OpenWinSetObjVisOptFlags ;reset these flags

DrawIconCommon_done	label	near
	pop	si, di
	ret

OLBaseWinDrawGCMIcon	endp

endif

WinUncommon	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinUpdateExpressToolArea

DESCRIPTION:	This procedure positions the "express tool area", if this
		app current "has it" floating above it.  Does NOT mess with
		the title bar bounds, just references them to figure out
		where the area should be moved.

CALLED BY:	INTERNAL
		OpenWinMoveResizeWin

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Inital Version

------------------------------------------------------------------------------@
if PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR
OLBaseWinUpdateExpressToolArea	method static OLBaseWinClass,
				 MSG_OL_BASE_WIN_UPDATE_EXPRESS_TOOL_AREA

	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA
	LONG 	jz	done

	; Move tool area w/Express menu to the corner of our title area
	;
	mov	ax, ds:[di].OLWI_titleBarBounds.R_left
	mov	bx, ds:[di].OLWI_titleBarBounds.R_top
	call	OLBaseWinGetExpressMenuButtonWidth	; bp = width of area
	sub	ax, bp					; pass left edge for
							; tool area

	inc	bx		; One down from there, actually, seems to be
				; where the title actually starts, for some
				; reason...
	; If -1 spacing is being used (best test I know of is for B&W display),
	; then pull tool area up & to the left one pixel, to overlap with the
	; one-pixel line at the edge of the title area
	;
	call	OpenCheckIfBW
	jnc	gotIt
	dec	ax
	dec	bx
if EVENT_MENU
	dec	dx
endif
gotIt:
	call	VisQueryWindow
	tst	di
	LONG jz	done

if EVENT_MENU
	push	ax, bx
	mov	ax, dx
	call	WinTransform		; transform event menu position
	mov	dx, ax
	pop	ax, bx
	push	dx			; save event menu position
endif
	call	WinTransform
	mov	cx, ax
	mov	dx, bx
	mov	bx, ds:[LMBH_handle]
	call	MemOwner		; bx = geode
	push	si
	sub	sp, size OLFieldMoveToolAreaParams
	mov	bp, sp
	mov	ss:[bp].OLFMTAP_geode, bx
	mov	ss:[bp].OLFMTAP_xPos, cx
	mov	ss:[bp].OLFMTAP_yPos, dx
	mov	si, WIT_PRIORITY
	call	WinGetInfo		; al = WinPriorityData
	andnf	al, mask WPD_LAYER	; al = layer priority
	mov	cl, offset WPD_LAYER
	shr	al, cl			; convert to absolute value
	mov	ss:[bp].OLFMTAP_layerPriority, al
	mov	si, WIT_LAYER_ID
	call	WinGetInfo		; ax = layer ID
	mov	ss:[bp].OLFMTAP_layerID, ax
if EVENT_MENU
					; get event menu pos from stack
	mov	ax, ss:[bp][(size OLFieldMoveToolAreaParams)+2]
	mov	ss:[bp].OLFMTAP_eventPos, ax
endif
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	dx, size OLFieldMoveToolAreaParams
	mov	ax, MSG_OL_FIELD_MOVE_TOOL_AREA
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	add	sp, size OLFieldMoveToolAreaParams
	pop	si
if EVENT_MENU
	pop	cx			; throw away event menu position
endif
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent

if (not TOOL_AREA_IS_TASK_BAR)

	call	WinClasses_DerefVisSpec_DI
	mov	cx, ds:[di].OLWI_titleBarBounds.R_bottom
	sub	cx, ds:[di].OLWI_titleBarBounds.R_top

	;Fairly bad hacks to match menu bar height.  -cbh 6/29/92
	;Must match similar code in EnableDisableAndPosSysIcon.

	call	OpenWinCheckIfSquished		; running CGA?
	jc	5$				; yes, skip this
	call	OpenWinCheckMenusInHeader	; are we in the header?
	jnc	5$				; nope, done
	add	cx, 3				; else expand to match menu bar
5$:
MO <	push	ds							>
MO <	mov	ax, segment dgroup					>
MO <	mov	ds, ax							>
MO <	test	ds:[moCS_flags], mask CSF_BW	; Is this a B&W display?>
MO <	pop	ds							>
MO <	jnz	20$				;   skip if so...	>
MO <	sub	cx, 2				; Nest icon inside resize  >
MO <20$:					;   display		   >

ISU <	push	ds							>
ISU <	mov	ax, segment dgroup					>
ISU <	mov	ds, ax							>
ISU <	test	ds:[moCS_flags], mask CSF_BW	; Is this a B&W display?>
ISU <	pop	ds							>
ISU <	jnz	20$				;   skip if so...	>
ISU <	dec	cx				; Nest icon inside resize  >
ISU <20$:					;   display		   >

	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_SIZE_TOOL_AREA
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent

endif ; (not TOOL_AREA_IS_TASK_BAR)

done:
	.leave
	ret
OLBaseWinUpdateExpressToolArea	endm
endif	; PLACE_EXPRESS_MENU_ON_PRIMARY or TOOL_AREA_IS_TASK_BAR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinUpdateToolAreas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update title bar and tool areas

CALLED BY:	MSG_OL_BASE_WIN_UPDATE_TOOL_AREAS
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if EVENT_MENU
OLBaseWinUpdateToolAreas	method dynamic OLBaseWinClass,
					MSG_OL_BASE_WIN_UPDATE_TOOL_AREAS

	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid
	call	OpenWinCalcWinHdrGeometry
	call	OLBaseWinUpdateExpressToolArea
	ret
OLBaseWinUpdateToolAreas	endm
endif

WinClasses ends

;---------------------------

WinUncommon segment resource

if _GCM

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinEnableAndPositionHeaderIcon

DESCRIPTION:	This procedure is used to position and enable the icons
		which appear in the header area of a window:

			- GCM "Exit" and "Help" icons
			- Workspace and Application menu buttons

CALLED BY:	OLBaseWinPositionGCMHeaderIcons

PASS:		*ds:si	= instance data for object
		^lbx:si = OLMenuButton object (bx = 0 if none)
		cx, dx = position for icon
		ax	= height of title bar
		bp	= width of icon

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLBaseWinEnableAndPositionHeaderIcon	proc	near
	tst	bx			;check handle
	jz	done			;skip if no icon...

	;set size of icon

	push	cx, dx
	mov	cx, bp			;(cx, dx) = size of icon
	mov	dx, ax
	mov	ax, MSG_VIS_SET_SIZE
	call	WinUncommon_ObjMessageCallFixupDS
	pop	cx, dx

	;set position of icon

	mov	ax, MSG_VIS_POSITION_BRANCH
	call	WinUncommon_ObjMessageCallFixupDS

	;since we have handled geometry, clear invalid flags now

	mov	cx, (mask VOF_GEOMETRY_INVALID or \
		     mask VOF_GEO_UPDATE_PATH) shl 8
	stc				;^lbx:si is object
	call	OpenWinSetObjVisOptFlags ;reset these flags

done:
	ret
OLBaseWinEnableAndPositionHeaderIcon	endp

endif	; _GCM


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinPositionGCMHeaderIcons

DESCRIPTION:	This procedure positions and enables the "Exit" and "Help"
		icons in the header when running in GC mode.

CALLED BY:	OpenWinCalcWinHdrGeometry (cwinClassCommon.asm) ONLY

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@

if _GCM

OLBaseWinPositionGCMHeaderIcons	proc	far
	class	OLBaseWinClass
	;are we in General Consumer Mode?

EC <	call	WinUncommon_DerefVisSpec_DI				>
EC <	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED		>
EC <	ERROR_Z	OL_ERROR		;must have OWFA_GCM_TITLED	>

;ERROR CHECK: test for OLBaseWinClass

	;See if there is an icon on the left.

	test	ds:[di].OLBWI_gcmFlags, mask GCMF_LEFT_ICON
	jz	checkForRight		;skip if not...

	;move title bar in according to width of left side icon

	mov	cx, ds:[di].OLWI_titleBarBounds.R_left
	mov	dx, ds:[di].OLWI_titleBarBounds.R_top
OLS <	add	cx, 2			;move icon over 2 pixels 	>
OLS <	add	dx, 2			;move icon down 2 pixels 	>
CUAS <	inc	dx			;move icon down 1 pixel 	>

OLS <	mov	ax, OLS_GCM_HEADER_HEIGHT				>
CUAS <	mov	ax, CUAS_GCM_HEADER_HEIGHT				>
     	call	OpenWinCheckIfSquished
	jnc	10$
CUAS <	mov	ax, CUAS_GCM_CGA_HEADER_HEIGHT				>
10$:

OLS <	add	ds:[di].OLWI_titleBarBounds.R_left, OLS_GCM_HEADER_ICON_WIDTH+4>
CUAS <	add	ds:[di].OLWI_titleBarBounds.R_left, CUAS_GCM_HEADER_ICON_WIDTH >
					;reduce the size of the title area
	push	si
	mov	bx, ds:[LMBH_handle]
	mov	si, ds:[di].OLBWI_gcmLeftIcon
	push	ax
OLS <	mov	bp, OLS_GCM_HEADER_ICON_WIDTH				>
MO <	mov	bp, CUAS_GCM_HEADER_ICON_WIDTH-1			>
ISU <	mov	bp, CUAS_GCM_HEADER_ICON_WIDTH-1			>
NOT_MO <mov	bp, CUAS_GCM_HEADER_ICON_WIDTH				>
	call	OLBaseWinEnableAndPositionHeaderIcon
	pop	ax
	pop	si

checkForRight:
	;"Help" icon:

	call	WinUncommon_DerefVisSpec_DI
	test	ds:[di].OLBWI_gcmFlags, mask GCMF_RIGHT_ICON
	jz	done			;skip if not...

	;move title bar in according to width of right side icon

OLS <	sub	ds:[di].OLWI_titleBarBounds.R_right,OLS_GCM_HEADER_ICON_WIDTH+4>
CUAS <	sub	ds:[di].OLWI_titleBarBounds.R_right, CUAS_GCM_HEADER_ICON_WIDTH>

	mov	cx, ds:[di].OLWI_titleBarBounds.R_right
	mov	dx, ds:[di].OLWI_titleBarBounds.R_top

OLS <	add	cx, 3			;adjust for subtract, add 2	>
OLS <	add	dx, 2			;move icon down 2 pixels 	>
CUAS <	inc	cx			;adjust for subtract		>
CUAS <	inc	dx			;move icon down 1 pixel 	>
	push	si
	mov	bx, ds:[LMBH_handle]
	mov	si, ds:[di].OLBWI_gcmRightIcon
OLS <	mov	bp, OLS_GCM_HEADER_ICON_WIDTH				>
MO <	mov	bp, CUAS_GCM_HEADER_ICON_WIDTH-1			>
ISU <	mov	bp, CUAS_GCM_HEADER_ICON_WIDTH-1			>
NOT_MO <mov	bp, CUAS_GCM_HEADER_ICON_WIDTH				>
	call	OLBaseWinEnableAndPositionHeaderIcon
	pop	si
done:
	ret
OLBaseWinPositionGCMHeaderIcons	endp

endif	; if _GCM -------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinUpdateForTitleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update express menu button, if any

CALLED BY:	MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBaseWinUpdateForTitleGroup	method dynamic OLBaseWinClass,
					MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
	.enter
	;
	; normal update first
	;
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock
	;
	; update express menu button
	;
	mov	ax, MSG_OL_BASE_WIN_UPDATE_EXPRESS_TOOL_AREA
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
OLBaseWinUpdateForTitleGroup	endm

WinUncommon ends

;-------------------

WinClasses segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinGetHeaderTitleBounds --
		MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS for OLBaseWinClass

DESCRIPTION:	Returns widths of icons left and right of title bar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS

RETURN:		ax 	- width of icons left of title
		bp	- width of icons right of title
		cx, dx	- preserved

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 7/92		Initial Version

------------------------------------------------------------------------------@

OLBaseWinGetHeaderTitleBounds	method dynamic	OLBaseWinClass, \
				MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
if _GCM	;----------------------------------------------------------------------
	mov	ax, CUAS_GCM_HEADER_ICON_WIDTH	;assume GCM
	mov	bp, CUAS_GCM_HEADER_ICON_WIDTH
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED	;GCM?
	jnz	done				;yes, have widths
						;call superclass to get
						;	system menu icon width
endif	; if _GCM -------------------------------------------------------------

	mov	ax, MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
	call	WinClasses_ObjCallSuperNoLock_OLBaseWinClass
						;ax, bp = widths

	call	WinClasses_DerefVisSpec_DI		; ds:di = instance data
	test	ds:[di].OLBWI_flags, mask OLBWF_HAS_EXPRESS_TOOL_AREA
	jz	done				; nope
	push	bp				;save right side width
	call	OLBaseWinGetExpressMenuButtonWidth	; bp = width
	dec	bp				;overlap express menu button
						;	with other left side
						;	icons, but not with
						;	title bar
	add	ax, bp				;compute left side width
if EVENT_MENU
	call	OLBaseWinGetEventMenuButtonWidth
	dec	bp
	add	ax, bp
endif
	pop	bp				;restore right side width

done:
	ret
OLBaseWinGetHeaderTitleBounds	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinGetExpressMenuButtonWidth

DESCRIPTION:	Returns width of window's system menu button.

CALLED BY:	INTERNAL

PASS:		*ds:si	- instance data
		ds:di	- instance data

RETURN:		bp = width of button

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/7/92		initial version
	doug	6/92		new for new Express menu

------------------------------------------------------------------------------@

OLBaseWinGetExpressMenuButtonWidth	proc	near	uses	ax, bx, cx, dx
	.enter
	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_GET_TOOL_AREA_SIZE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent
	mov	bp, cx
	;
	; mystery adjustment for B/W - brianc 2/5/93
	;
	call	OpenCheckIfBW
	jnc	done			; not B/W, no adjustment
	dec	bp
done:
	.leave
	ret
OLBaseWinGetExpressMenuButtonWidth	endp

if EVENT_MENU
OLBaseWinGetEventMenuButtonWidth	proc	near	uses	ax, bx, cx, dx, di
	.enter
	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_GET_TOOL_AREA_SIZE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent		; bp = width of event menu area
	;
	; mystery adjustment for B/W - brianc 2/5/93
	;
	call	OpenCheckIfBW
	jnc	done			; not B/W, no adjustment
	dec	bp
done:
	.leave
	ret
OLBaseWinGetEventMenuButtonWidth	endp
endif

if TOOL_AREA_IS_TASK_BAR
OLWinGetToolAreaSize	proc	far
	uses	ax, bx, di, bp
	.enter

	;
	; doesn't work from UI thread, so return 0 as size
	mov	bx, 0
	mov	dx, bx
	mov	cx, bx
	call	GeodeGetProcessHandle
	cmp	bx, handle ui
	je	done

	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_GET_TOOL_AREA_SIZE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	mov	cx, di
	call	UserCallApplication	; cx,dx = tool area size
done:
	.leave
	ret
OLWinGetToolAreaSize	endp
endif ; TOOL_AREA_IS_TASK_BAR

WinClasses	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBaseWinFupKbdChar - MSG_META_FUP_KBD_CHAR handler

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_KBD_CHAR or MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		is the generic parent.

PASS:		*ds:si	= instance data for object
		ds:di = specific instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/92		Initial version (adapted from similar handlers)

------------------------------------------------------------------------------@

OLBaseWinFupKbdChar	method dynamic	OLBaseWinClass, \
				MSG_META_FUP_KBD_CHAR, MSG_META_KBD_CHAR

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper		;ignore character...

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

if	(0)	; this should be done by system/field object...
	;
	; Check for Ctrl-Esc - express menu
	;
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	callSuper
	cmp     cx, (CS_CONTROL shl 8) or VC_ESCAPE
	jne     callSuper
	mov     bx, ds:[di].OLBWI_expressMenuButton.handle
	mov     si, ds:[di].OLBWI_expressMenuButton.chunk
	mov     ax, MSG_GEN_ACTIVATE
	mov     di, mask MF_FIXUP_DS
	call    ObjMessage

	stc				;say handled
	ret
endif

if _USE_KBD_ACCELERATORS

	;
	; Check for Ctrl-F1 - temporary measure to restore menu bar
	;
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	callSuper
SBCS <	cmp     cx, (CS_CONTROL shl 8) or VC_F1				>
DBCS <	cmp     cx, C_SYS_F1						>
	jne     callSuper
	tst     ds:[di].OLMDWI_menuBar
	jz	callSuper		;no menu bar, let it go up?
	mov     ax, MSG_OL_BASE_WIN_TOGGLE_MENU_BAR
callSelfRetHandled:
	call    ObjCallInstanceNoLock
	stc				;say handled
	ret
endif

callSuper:
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock
	ret
OLBaseWinFupKbdChar	endm

KbdNavigation	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLBaseWinSpecSetUsable

DESCRIPTION:	Handle set-usable by maximizing OLBaseWin if
		HINT_DISPLAY_MAXIMIZED_ON_STARTUP is set.

PASS:
	*ds:si - instance data
	es - segment of OLBaseWinClass

	ax 	- MSG_SPEC_SET_USABLE
	dl	- VisUpdateMode

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
	brianc	3/13/92		Initial version

------------------------------------------------------------------------------@
if 0		; "on-startup" no longer includes setting usable
		; - brianc 7/9/92
OLBaseWinSpecSetUsable	method	dynamic	OLBaseWinClass, MSG_SPEC_SET_USABLE
	;
	; Check if we should be maximized on startup (additional
	; interpretation of this is to maximize on usable).  If so, set
	; ATTR_GEN_DISPLAY_MAXIMIZED_STATE.  OLMenuedWinSpecBuild will
	; take care of the rest.
	;
	push	ax, cx, dx, bp
	mov	ax, HINT_DISPLAY_MAXIMIZED_ON_STARTUP
	call	ObjVarFindData			; carry set if found
	jnc	notMaximized
	;
	; if maximized on startup, set ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
notMaximized:
	pop	ax, cx, dx, bp
	;
	; then, let superclass handle
	;
	mov	di, offset OLBaseWinClass
	call	ObjCallSuperNoLock
	ret
OLBaseWinSpecSetUsable	endm
endif

OLBaseWinSpecSetUsable	method	dynamic	OLBaseWinClass, MSG_SPEC_SET_USABLE
	call	RemoveTitleBarIfPossible
	mov	ax, MSG_SPEC_SET_USABLE
	mov	di, offset OLBaseWinClass
	GOTO	ObjCallSuperNoLock
OLBaseWinSpecSetUsable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinToggleMenuBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle menu bar, if togglable

CALLED BY:	MSG_OL_BASE_WIN_TOGGLE_MENU_BAR

PASS:		*ds:si	= OLBaseWin object
		ds:di	= OLBaseWin instance data
		es 	= segment of OLBaseWinClass
		ax	= MSG_OL_BASE_WIN_TOGGLE_MENU_BAR

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/25/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBaseWinToggleMenuBar	method	dynamic	OLBaseWinClass,
						MSG_OL_BASE_WIN_TOGGLE_MENU_BAR
	mov     si, ds:[di].OLMDWI_menuBar
	tst	si
	jz	done				; no menu bar
	mov	di, segment OLPopoutClass	; make sure it is a popout
	mov	es, di
	mov	di, offset OLPopoutClass
	call	ObjIsObjectInClass
	jnc	done				; not a popout
	mov     ax, MSG_OL_POPOUT_TOGGLE_POPOUT
	call    ObjCallInstanceNoLock
done:
	ret
OLBaseWinToggleMenuBar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBaseWinMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle changes of Secret Mode

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= OLBaseWinClass object
		ds:di	= OLBaseWinClass instance data
		ds:bx	= OLBaseWinClass object (same as *ds:si)
		es 	= segment of OLBaseWinClass
		ax	= message #
		cx:dx	= NotificationType
			  cx - NT_manuf
			  dx - NT_type
		bp	= change specific data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _DUI
OLBaseWinMetaNotify	method dynamic OLBaseWinClass,
					MSG_META_NOTIFY
		uses	ax, cx, dx, bp
		.enter

		cmp	cx, MANUFACTURER_ID_NEC
		LONG jne	callSuper
		cmp	dx, NECNT_SECRET_MODE_CHANGE
		LONG jne	callSuper
	;
	; The "Secret Mode" status has changed (either on / off).
	; Redraw the primary so the indicator will redraw in the
	; titlebar.
	;
		mov	cl, mask OLWHS_TITLE_AREA_INVALID
		call	OpenWinHeaderMarkInvalid
callSuper:
		mov	di, offset OLBaseWinClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret

OLBaseWinMetaNotify	endm
endif

ActionObscure ends
