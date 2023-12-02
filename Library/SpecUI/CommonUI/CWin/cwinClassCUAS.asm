COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for all specific UIs)
FILE:		cwinClassCUAS.asm (OLWinClass code specific to _CUA_STYLE UIs.)

ROUTINES:
	Name				Description
	----				-----------
    INT OpenWinEnsureSysMenu    This procedure creates the System Menu
				which appears in the window header area.

    INT WinCommon_CallSysMenu   This procedure creates the System Menu
				which appears in the window header area.

    INT WinCommon_CallSysMenuButton
				This procedure creates the System Menu
				which appears in the window header area.

    INT GetSystemMenuBlockHandle
				Return the block in which the system menu
				resides

    INT CustomizeSysMenu        Makes correct accelerators.  It would be
				nice to be setting the correct icon here,
				so we only had one template, but I had
				trouble with COPY_VIS_MONIKER.

    INT OpenWinEnsureSysMenuIcons
				This procedure creates the System icons
				which appear in the window header
				area. (The System Menu itself is now
				created by a separate routine: see
				OpenWinEnsureSysMenu.)

    INT AttachAndBuildSysMenuIcon
				Attach system menu icon to window, & build
				it out

    INT OpenWinUpdatePinnedMenu This procedure updates the GenTriggers
				within a pinned menu.

				NOTE: this procedure only does some of the
				work! See OLPopupWinTogglePushpin of a good
				example of the rest.

    INT OpenWinPositionSysMenuIcons
				This CUA/MOTIF specific procedure positions
				and enables the appropriate icons for the
				system menu - minimize, maximize, system
				menu button, etc.

    INT OpenWinGetTitleBarGroupSize
				Get width and height of title bar group.

    INT OpenWinPositionTitleBarGroup
				Set width and height and position of title
				bar group.

    INT OpenWinEnableAndPosSysMenuIcon
				This procedure updates one of the objects
				related to the Motif/CUA system menu:
				system menu button, triggers inside the
				system menu, and the icons which serve as
				shortcuts to the items in the system menu.

    INT EnableDisableAndPosSysIcon
				Enable/disables system icon, & positions it
				if being enabled.

    INT EnableDisableSysMenuItem
				Enables/disables a menu item somewhere on
				the system menu.

    INT OpenWinGetSysMenuButtonWidth
				Returns width of window's system menu
				button.

    MTD MSG_MO_SYSMENU_MOVE     This is invoked when the user presses on
				the Move icon or menu item in the system
				menu.

    INT OpenWinStartMoveResizeCommon
				setup params for and call ImStartMoveResize

    INT OpenWinStartMoveResizeMonitor
				set up input monitor to detect mouse button
				activity to stop keyboard move/resize

    MTD MSG_MO_SYSMENU_SIZE     This is invoked when the user presses on
				the Size icon or menu item in the system
				menu.

    INT OpenWinMoveResizeAbortMonitor
				input monitor to detect mouse press on
				which to abort keyboard move/resize

    MTD MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE
				Turn on ptr and do MSG_VIS_VUP_BUMP_MOUSE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Moved from Motif/Win/winClassSpec.asm so that
				new Motif and CUA can both use this code.

DESCRIPTION:
	This file contains OLWinClass-related code which is specific to
	_CUA_STYLE User Interfaces (Motif, Deskmate, CUA). See cwinClass.asm
	for class declaration and method table.

	$Id: cwinClassCUAS.asm,v 1.5 98/05/04 07:17:43 joon Exp $

------------------------------------------------------------------------------@

OLS <	ErrMessage THIS FILE SHOULD NOT BE INCLUDED BY OPEN_LOOK - STYLE UI'S! >

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureSysMenu

DESCRIPTION:	This procedure creates the System Menu which appears
		in the window header area.

CALLED BY:	OpenWinUpdateSpecBuild, OpenWinGenSetNotMaximized

PASS:		ds:*si	- instance data
		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	?	well, please don't trash bp, at least!

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version

------------------------------------------------------------------------------@
OpenWinEnsureSysMenu	proc	far
	class	OLWinClass

	;if this window has a system menu, create/update the four associated
	;objects: menu button and three menu icons.

	push	bp			;save SpecBuildFlags until end.
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU
	LONG jz	next2			;skip if not...

	;see if we have created a custom system menu object yet

if TOOL_AREA_IS_TASK_BAR
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	jne	notPrimary
	tst	ds:[di].OLBWI_titleBarMenu.handle
	LONG	jnz	next2
	notPrimary:
endif

	;see if we have created the system menu objects yet

	tst	ds:[di].OLWI_sysMenu	;check first handle
	jne	sendUpdateSpecBuild	;skip if so...


if (not _ISUI)

	;no system menu if UIWindowOptions says no system menu

	push	es
	mov	ax, segment olWindowOptions
	mov	es, ax
	test	es:[olWindowOptions], mask UIWO_WINDOW_MENU
	pop	es
	jnz	buildSystemMenu		;build regular system menu

	;else, just build close button

	mov	ax, offset OLWI_sysMenu
				;assume display system menu close button
	mov	bx, handle DisplayWindowMenuResource
	mov	dx, offset DisplayWindowMenuButton

	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	je	createSysMenuCloseButton	;skip if a display window
				;else regular system menu close button
	mov	bx, handle StandardWindowMenuResource
	mov	dx, offset StandardWindowMenuButton
createSysMenuCloseButton:
	mov	ds:[di].OLWI_sysMenuButton, dx
	call	OpenWinDuplicateBlock
	call	WinCommon_DerefVisSpec_DI
	ornf	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jmp	short sendUpdateSpecBuild
buildSystemMenu:

endif	; if (not _ISUI)

	;now DUPLICATE this resource objects into the Object Block.

	mov	ax, offset OLWI_sysMenu		;point to field which has handle
	mov	bx, handle DisplayWindowMenuResource
	mov	dx, offset DisplayWindowMenu	;assume display system menu

	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	je	createSysMenu			;skip if a display window
	mov	bx, handle StandardWindowMenuResource
	mov	dx, offset StandardWindowMenu	;assume regular system menu

createSysMenu:
	call	OpenWinDuplicateBlock
	call	CustomizeSysMenu		;setup correct accelerators

	;when GenInteraction or GenTrigger object is gen->specific built,
	;the HINT_MO_SYS_MENU forces us skip the BUILD_INFO query,
	;and instead indicates that the GenPrimary should be the visible
	;parent. See cspecInteraction.asm

sendUpdateSpecBuild:
	;This object has been created; send MSG_SPEC_BUILD_BRANCH
	;on to it so it can build itself and its children.
	;	bp = flags for method

	and	bp, not mask SBF_WIN_GROUP	; NOT doing WIN_GROUP, rather,
						; we're doing its children
	or	bp, mask SBF_TREE_BUILD		; & doing tree build

	mov	cx, -1				; do full, non-optimized check
	call	GenCheckIfFullyEnabled	; see if we're fully enabled
	jnc	10$			; no, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	mov     ax, MSG_SPEC_BUILD_BRANCH
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jz	callSysMenu
	call	WinCommon_CallSysMenuButton
	jmp	short next2

callSysMenu:
	call	WinCommon_CallSysMenu
next2:
if _ISUI
	;
	; Replace system window menu moniker with application tool
	; moniker
	;
	call	SetAppMonikerForSysMenu
endif
	;If we don't have the handle of the System Menu Button,
	;grab it now. (This must be done after the System Menu
	;has received MSG_SPEC_BUILD_BRANCH.)

	call	WinCommon_DerefVisSpec_DI
	tst	ds:[di].OLWI_sysMenu	;do we have a system menu?
	jz	done			;skip if not...

	tst	ds:[di].OLWI_sysMenuButton
	jne	done			;skip if have handle of button...

	mov	ax, MSG_OL_POPUP_FIND_BUTTON
	call	WinCommon_CallSysMenu
					; returns cx:dx = button
	call	WinCommon_DerefVisSpec_DI
	mov	ds:[di].OLWI_sysMenuButton, dx	;save chunk handle of sys menu


	;set a flag in the menu button so that it detects double-click
	;operations, and will dismiss the window.

	mov	ax, MSG_OL_MENU_BUTTON_SET_IS_SYS_MENU_ICON
	call	WinCommon_CallSysMenuButton

ISU <	mov	ax, MSG_OL_WIN_SET_CUSTOM_SYSTEM_MENU_MONIKER		>
ISU <	call	ObjCallInstanceNoLock					>

done:
	pop	bp
	ret
OpenWinEnsureSysMenu	endp

WinCommon_CallSysMenu	proc	near	uses	bx, si, di
	.enter
	call	WinCommon_DerefVisSpec_DI

if TOOL_AREA_IS_TASK_BAR
	call	GetSystemMenuBlockHandle	;returns bx = block handle
	mov	si, offset StandardWindowMenu
	jz	haveSysMenu
	mov	si, ds:[di].OLBWI_titleBarMenu.chunk
haveSysMenu:
else
	mov	bx, ds:[di].OLWI_sysMenu
	mov	si, offset StandardWindowMenu
endif

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
WinCommon_CallSysMenu	endp

WinCommon_CallSysMenuButton	proc	near	uses	bx, si, di
	.enter
	call	WinCommon_DerefVisSpec_DI
if TOOL_AREA_IS_TASK_BAR
	call	GetSystemMenuBlockHandle	;returns bx = block handle
else
	mov	bx, ds:[di].OLWI_sysMenu
endif
	mov	si, ds:[di].OLWI_sysMenuButton
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
WinCommon_CallSysMenuButton	endp

if _ISUI
;
; pass: *ds:si = OLWin
;
SetAppMonikerForSysMenu	proc	near
		uses	si
		.enter
	;
	; if no system menu, exit
	;
		call	WinCommon_DerefVisSpec_DI
		mov	bx, ds:[di].OLWI_sysMenu
		tst	bx
		jz	done
	;
	; if custom system menu, exit
	;
if TOOL_AREA_IS_TASK_BAR
		cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
		jne	normalSysMenu
		tst	ds:[di].OLBWI_titleBarMenu.handle
		jnz	done
endif
normalSysMenu:
	;
	; copy app tool moniker into this block
	;
		mov	ax, MSG_GEN_FIND_MONIKER
		mov	dx, 1			; use app moniker
		mov	bp, mask VMSF_GSTRING or mask VMSF_COPY_CHUNK or \
			VMS_TOOL shl offset VMSF_STYLE
		mov	cx, ds:[LMBH_handle]
		call	ObjCallInstanceNoLock	; ^lcx:dx = moniker, if any
		jcxz	done
	;
	; make sure it is a gstring and small enough
	;
		mov	di, dx
		mov	di, ds:[di]
		test	ds:[di].VM_type, mask VMT_GSTRING
		jz	doneFree
		cmp	ds:[di].VM_width, 16
		ja	doneFree
		cmp	({VisMonikerGString}(ds:[di].VM_data)).VMGS_height, 16
		ja	doneFree
	;
	; set it as moniker for system menu
	;
.assert (offset StandardWindowMenu) eq (offset DisplayWindowMenu)
		push	dx
		mov	si, offset StandardWindowMenu
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	dx
doneFree:
		mov	ax, dx
		call	LMemFree
done:
		.leave
		ret
SetAppMonikerForSysMenu	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSystemMenuBlockHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the block in which the system menu resides

CALLED BY:	WinCommon_CallSysMenuButton
		EnableDisableAndPosSysIcon

PASS:		ds:di		Vis instance data

RETURN:		bx		block handle of system menu
		zero flag set	if a custom system menu was not found

DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		If the window is a primary, check to see if it has a custom
		system menu.  Else just return the standard system menu
		block handle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

GetSystemMenuBlockHandle	proc	far

	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	jne	normalSysMenu
	mov	bx, ds:[di].OLBWI_titleBarMenu.handle
	tst	bx
	jnz	haveMenu
normalSysMenu:
	clr	bx				; make sure zero flag is set
	mov	bx, ds:[di].OLWI_sysMenu
haveMenu:
	ret

GetSystemMenuBlockHandle	endp

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	CustomizeSysMenu

SYNOPSIS:	Makes correct accelerators.  It would be nice to be setting
		the correct icon here, so we only had one template, but I
		had trouble with COPY_VIS_MONIKER.

CALLED BY:	OpenWinEnsureSysMenu

PASS:		*ds:si -- handle of parent win object
		^lcx:dx	- new menu

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/25/90		Initial version

------------------------------------------------------------------------------@

CustomizeSysMenu	proc	far		uses	si
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	bx, cx			; new menu in ^lbx:si
	mov	si, dx

	mov	cx, 0ffffh			;assume menu, clear accelerator
	clr	dx				;no bits to set
	cmp	ds:[di].OLWI_type, MOWT_MENU
	je	setAccel			;
	cmp	ds:[di].OLWI_type, MOWT_SUBMENU
	je	setAccel			;

	inc	cx				;assume normal sys menu, set ALT
	mov	dx, KSS_ALT
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	jne	setAccel			;not display, branch to set

	clr	cx				;no bits to clear
	mov	dx, KSS_CTRL			;assume display, set CTRL bit

setAccel:
	call	ObjSwapLock
	push	bx
	;
	; Let's modify the monikers of the menu items. Bits to clear in cx,
	; bits to set in dx.
	;
	mov	ax, MSG_GEN_CHANGE_ACCELERATOR
	call	GenSendToChildren
	pop	bx
	call	ObjSwapUnlock
	.leave
	ret
CustomizeSysMenu	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureSysMenuIcons

DESCRIPTION:	This procedure creates the System icons which appear
		in the window header area. (The System Menu itself is now
		created by a separate routine: see OpenWinEnsureSysMenu.)

CALLED BY:	OpenWinUpdateSpecBuild, OpenWinGenSetNotMaximized

PASS:		ds:*si	- instance data
		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version

------------------------------------------------------------------------------@
OpenWinEnsureSysMenuIcons	proc	far
	class	OLWinClass

	;if this window has a system menu, create/update the four associated
	;icons

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU
	jz	done			;skip if not...

	; see if we have created the icons yet

	test	ds:[di].OLWI_specState, mask OLWSS_SYS_ICONS_ATTACHED
	jnz	done			; skip if so...

	;
	; if running in keyboard only mode, don't create system menu icons
	;
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	done				; skip if keyboard only

	; Need block that system menu items & system icons are in
	;
	mov	cx, ds:[di].OLWI_sysMenu

EC <	; make sure that the menu was created				>
EC <	tst	cx			; check first handle		>
EC <	ERROR_Z	OL_ERROR						>
					; set done now..
	ornf	ds:[di].OLWI_specState, mask OLWSS_SYS_ICONS_ATTACHED

	and	bp, not mask SBF_WIN_GROUP	; NOT doing WIN_GROUP, rather,
						; we're doing its children
	or	bp, mask SBF_TREE_BUILD	or \
		    mask SBF_VIS_PARENT_FULLY_ENABLED
		    				; do tree build, make
						; minimize, maximize & restore
						; icons ALWAYS enabled

	mov	dx, offset SMI_MinimizeIcon
	call	AttachAndBuildSysMenuIcon

	mov	dx, offset SMI_MaximizeIcon
	call	AttachAndBuildSysMenuIcon

	mov	dx, offset SMI_RestoreIcon
	call	AttachAndBuildSysMenuIcon

if _ISUI
	mov	dx, offset SMI_CloseIcon
	call	AttachAndBuildSysMenuIcon
endif

done:
if _ISUI
	;
	; Add help button if needed
	;
	call	AddWindowHelp
endif

	ret
OpenWinEnsureSysMenuIcons	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AttachAndBuildSysMenuIcon

DESCRIPTION:	Attach system menu icon to window, & build it out

CALLED BY:	INTERNAL
		OpenWinEnsureSysMenuIcons

PASS:		*ds:si	- OLWinClass object
		^lcx:dx	- icon object to add in/build
		bp	- SpecBuildFlags to use for icon

RETURN:		nothing

DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@

AttachAndBuildSysMenuIcon	proc	near	uses	cx, si, bp
	.enter
	call	GenAddChildUpwardLinkOnly	; add object in, w/one-way link

	;when GenInteraction or GenTrigger object is gen->specific built,
	;the HINT_MO_SYS_MENU forces us skip the BUILD_INFO query,
	;and instead indicates that the GenPrimary should be the visible
	;parent. See cspecInteraction.asm

	;These objects have been created; send MSG_SPEC_BUILD_BRANCH
	;on to them so they can build themselves and their children.
	;	bp = flags for method

	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock

	mov     ax, MSG_SPEC_BUILD_BRANCH
	call    WinCommon_ObjCallInstanceNoLock

	call	ObjSwapUnlock
	.leave
	ret
AttachAndBuildSysMenuIcon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddWindowHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a help trigger to the window if requested, unless
		primary

CALLED BY:	OpenWinEnsureSysMenuIcons()
PASS:		*ds:si - OLWin object
RETURN:		ds - fixed up
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ISUI

AddWindowHelp		proc	far
	uses	ax, cx, dx, bp, si, es
	.enter
	;
	; Primaries do their own thing
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	je	noHelpShort
	;
	; If there is no header area, don't add help trigger  -Don 10/27/00
	;
	test	ds:[di].OLWI_attrs, mask OWA_HEADER
	jz	noHelpShort
	;
	; already there?
	;
	mov	ax, TEMP_OL_WIN_HELP_TRIGGER
	call	ObjVarFindData
	jc	noHelpShort
	;
	; See if we are hiding help buttons (eg. for a system
	; with a dedicated help button or icon)
	;
	call	OpenGetHelpOptions
	test	ax, mask UIHO_HIDE_HELP_BUTTONS
	jnz	noHelpShort			;branch if help hidden
	;
	; See if there is a hint specifying we shouldn't add the trigger
	;
	mov	ax, HINT_NO_HELP_BUTTON
	call	ObjVarFindData
	jc	noHelpShort			;branch if no window help
	;
	; Finally, see if there is even help specified
	;
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	jc	continue			;continue only if help context
noHelpShort:
	jmp	noHelp
continue:
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
	mov	ax, TEMP_OL_WIN_HELP_TRIGGER
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
AddWindowHelp		endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinUpdatePinnedMenu

DESCRIPTION:	This procedure updates the GenTriggers within a pinned menu.

		NOTE: this procedure only does some of the work!
		      See OLPopupWinTogglePushpin of a good example of the rest.

CALLED BY:	OpenWinUpdateSpecBuild, OLPopupWinTogglePushpin

PASS:		ds:*si	- instance data

RETURN:		ds:*si	= same
		bp	= same
		carry set if handled pinned menu case

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	Eric	3/90		Changeover: now pinned menus have system menu,
				this routine is used in all cases to start
				pinned mode correctly.

------------------------------------------------------------------------------@

if _MENUS_PINNABLE	;------------------------------------------------------

OpenWinUpdatePinnedMenu	proc	far
	class	OLWinClass

	;_CUA_STYLE: if this window is PINNED, add a system menu.

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	done			;skip if not pinnable (cy=0)...

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	done			;skip if not pinned (cy=0)...

	ORNF	ds:[di].OLWI_attrs, mask OWA_MOVABLE or mask OWA_TITLED \
						or mask OWA_HAS_SYS_MENU

	ANDNF	ds:[di].OLWI_winPosSizeFlags, not (mask WPSF_CONSTRAIN_TYPE)
	ORNF	ds:[di].OLWI_winPosSizeFlags, \
		(WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE)

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED

	;CUA/Motif: create system menu now (do not create icons!) and position
	;the menu button in the header area. (pass bp = SpecBuildFlags)

	tst	ds:[di].OLWI_sysMenu		;already have menu?
	jnz	haveSysMenu			;skip if so...

	push	bp, es

	mov	bp, mask SBF_IN_UPDATE_WIN_GROUP or mask SBF_WIN_GROUP \
							or VUM_NOW
	call	OpenWinEnsureSysMenu
ISU <	call	OpenWinEnsureSysMenuIcons				>
	call	OpenWinPositionSysMenuIcons	;see Motif/Win/winClassSpec

	; Set the menu button window invalid, so that it gets an update
	;
	push	si
	call	WinCommon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWI_sysMenu
	mov	si, ds:[di].OLWI_sysMenuButton
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	call	ObjSwapLock
	call	WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL
	call	ObjSwapUnlock
	pop	si

	pop	bp, es

haveSysMenu:
	stc				;return carry: handled menu case.

done:
	ret
OpenWinUpdatePinnedMenu	endp

endif		; if _MENUS_PINNABLE ------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinPositionSysMenuIcons

DESCRIPTION:	This CUA/MOTIF specific procedure positions and enables
		the appropriate icons for the system menu - minimize, maximize,
		system menu button, etc.

CALLED BY:	OpenWinCalcWinHdrGeometry
		OpenWinUpdatePinnedMenu

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version
	Eric	1/90		split from parent routine, more doc
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

;this structure is used to keep track of which icons need to be
;enabled/disable WITHIN this procedure only.

OLWinSysIcons	record
    OLWSI_SYS_MENU:1
    OLWSI_MAXI:1
    OLWSI_MINI:1
    OLWSI_RESTORE:1
    OLWSI_CLOSABLE:1
    OLWSI_PINNED:1
    OLWSI_MOVE:1
    OLWSI_SIZE:1
OLWinSysIcons	end

OpenWinPositionSysMenuIcons	proc	near
	class	OLWinClass

	clr	bh				; default: no menu, icons

	; If no duplicated system menu block, then we can't possibly position
	; the objects within it here.. just exit.
	;
	; No, we need to deal with title bar groups - brianc 3/11/93
	;
	call	WinCommon_DerefVisSpec_DI
	tst	ds:[di].OLWI_sysMenu
	LONG jz	afterSysMenuIcons

	; Set size and move status.

	push	es
	segmov	es, idata, ax
	test	ds:[di].OLWI_attrs, mask OWA_MOVABLE
	jz	notMovable
	test	es:[olExtWinAttrs], mask EWA_MOVABLE
	jz	notMovable
	ornf	bh, mask OLWSI_MOVE
notMovable:
	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jz	notResizable
	test	es:[olExtWinAttrs], mask EWA_RESIZABLE
	jz	notResizable
	ornf	bh, mask OLWSI_SIZE
notResizable:
	pop	es

	; if we have just a close button for the system menu, and the window
	; isn't closable, disable the close button (still need the system
	; menu resource as there may be minimize or maximize, etc. buttons)

	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jnz	keepButton
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	afterCloseButton
keepButton:

if _ISUI
	call	CheckSysMenuButton
	jnc	afterCloseButton
endif
	; Subtract ICON_WIDTH-1 for each icon, since the icons overlap
	; Get width of system menu button from the system menu
	;
	call	OpenWinGetSysMenuButtonWidth	; cx = button width
	dec	cx

	call	WinCommon_DerefVisSpec_DI
	add	ds:[di].OLWI_titleBarBounds.R_left, cx

ISUI_SYS_MENU_FUDGE	equ	8

ISU <	add	ds:[di].OLWI_titleBarBounds.R_left, ISUI_SYS_MENU_FUDGE >

	or	bh, mask OLWSI_SYS_MENU		; flag so System menu button
						; will be visible

	; Are there icons attached & built ready to be positioned?
	;
afterCloseButton:
	test	ds:[di].OLWI_specState, mask OLWSS_SYS_ICONS_ATTACHED
	LONG jz	OWCWHG_60			; if not, just do system menu
						; (But don't forget to check
						; if closable so that
						; "Close" item is set
						; correctly)

	; If user isn't allowed to min/max/restore, then don't present
	; icons for those features.
	;
	call	OpenWinCheckIfMinMaxRestoreControls
	jnc	afterMinimizeTest

	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	OWCWHG_50			;skip if not...

	;window is maximizable: decide if we need the MAXIMIZE or RESTORE icon

	mov	bl, mask OLWSI_MAXI		;default: allow MAXI icon

testMaximized:
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	makeRoomForIcon			;skip if not maximized,
						;but is maximizable...
maximized:
	clr	bl				;default: no RESTORE icon!

	test	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE
	jz	afterMaximizeTest		;skip if not restorable...

	mov	bl, mask OLWSI_RESTORE		;allow RESTORE icon

makeRoomForIcon:

	;
	; if keyboard only, don't make room for system menu icons
	;
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	20$				; not if keyboard only
	sub	ds:[di].OLWI_titleBarBounds.R_right, CUAS_WIN_ICON_WIDTH-1
20$:
						;make room for icon
afterMaximizeTest:
	or	bh, bl				;set MAXI or RESTORE bit

OWCWHG_50: ;see if window is minimizable
	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	OWCWHG_60			;skip if not...

if _ISUI
	;
	; if HINT_PRIMARY_HIDE_MINIMIZE_UI is present don't make room for
	; minimize icon, and don't set OLWSI_MINI.
	;
	push	bx
	mov	ax, TEMP_OL_WIN_HIDE_MINIMIZE
	call	ObjVarFindData
	pop	bx
	jc	OWCWHG_60
endif

	;
	; if keyboard only, don't make room for system menu icons
	;
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	30$				; not if keyboard only
	sub	ds:[di].OLWI_titleBarBounds.R_right, CUAS_WIN_ICON_WIDTH-1
30$:
						;make room for icon
	or	bh, mask OLWSI_MINI		;allow MINI icon

afterMinimizeTest:

OWCWHG_60: ;see if window is closable

	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
if not _ISUI
	jz	OWCWHG_70		;skip if not...
else
	jz	OWCWHG_70_near		;skip if not...
	;
	; Check for the MINIMIZE_IS_CLOSE functionality
	; Must be minimizable and closable
	;
	test	bh, mask OLWSI_MINI
	jz	doneMinClose

	push	bx
	mov	ax, TEMP_OL_WIN_MINIMIZE_IS_CLOSE
	call	ObjVarFindData
	pop	bx
	jnc	doneMinClose			; no hint, no funky deal-e-o

	call	UserGetDefaultUILevel		; ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	je	doneMinClose			; don't do for consumerUI

	; Get the action message from the close button and stick
	; it on the minimize button.
	;
	push	bx, si
	mov	bx, ds:[di].OLWI_sysMenu
	mov	si, offset SMI_CloseIcon
	mov	ax, MSG_GEN_TRIGGER_GET_ACTION_MSG	; destroys ax,dx,bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset SMI_MinimizeIcon
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG	; destroys ax,dx,bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si

	; Finally, restore instance data pointer.
	;
	call	WinCommon_DerefVisSpec_DI

	; Skip setting the closable bit for the UI; however, leave the
	; OWA_CLOSABLE bit set or else we can't close this dang thing.
	;
OWCWHG_70_near:
	jmp	OWCWHG_70

doneMinClose:
endif ;_ISUI

if _ISUI
adjustTitleForClose:
	; close button on right side

	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	40$

	sub	ds:[di].OLWI_titleBarBounds.R_right, CUAS_WIN_ICON_WIDTH+1
40$:
endif

	or	bh, mask OLWSI_CLOSABLE		;update CLOSE menu item

OWCWHG_70:

afterSysMenuIcons:

	;
	; make room for left title bar group, if any
	;
	mov	bp, offset OLWI_titleBarLeftGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	jcxz	afterLeftGroup
;give full space for title bar groups
;	dec	cx				; adjust for overlap
	call	WinCommon_DerefVisSpec_DI
	add	ds:[di].OLWI_titleBarBounds.R_left, cx
;doesn't work
;	mov	ax, ds:[di].OLWI_titleBarBounds.R_bottom
;	sub	ax, ds:[di].OLWI_titleBarBounds.R_top
;	cmp	dx, ax
;	jbe	afterLeftGroup
;	add	dx, ds:[di].OLWI_titleBarBounds.R_top
;	mov	ds:[di].OLWI_titleBarBounds.R_bottom, dx
afterLeftGroup:

	;
	; make room for right title bar group, if any
	;
	mov	bp, offset OLWI_titleBarRightGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	jcxz	afterRightGroup
;give full space for title bar groups
;	dec	cx				; adjust for overlap
	call	WinCommon_DerefVisSpec_DI
	sub	ds:[di].OLWI_titleBarBounds.R_right, cx
;doesn't work
;	mov	ax, ds:[di].OLWI_titleBarBounds.R_bottom
;	sub	ax, ds:[di].OLWI_titleBarBounds.R_top
;	cmp	dx, ax
;	jbe	afterRightGroup
;	add	dx, ds:[di].OLWI_titleBarBounds.R_top
;	mov	ds:[di].OLWI_titleBarBounds.R_bottom, dx
afterRightGroup:

;updateAndPositionIcons:	;=========================================
	;now update the System Menu button and icons according to
	;our flag byte (BH)

	call	WinCommon_DerefVisSpec_DI
	mov	cx, ds:[di].OLWI_titleBarBounds.R_left
	mov	dx, ds:[di].OLWI_titleBarBounds.R_top

if _MOTIF
	call	OpenCheckIfBW			; Is this a B&W display
	jc	80$				;   skip if so...
	inc	cx				; Place it NEXT TO resize
	inc	dx				;   bar in a color display
80$:
elif _ISUI
	call	OpenCheckIfBW			; Is this a B&W display
	jc	80$				;  skip if so...
	inc	dx				; add some margin on top
	inc	dx				; add some margin on top
80$:
endif
	push	ds:[di].OLWI_titleBarBounds.R_right

if THREE_DIMENSIONAL_BORDERS
	add	dx, THREE_D_BORDER_THICKNESS
endif
	;
	; position left title bar group, if any
	;	cx = position for rightmost part of this group
	;	dx = Y position for this group
	;
	push	cx, dx
	mov	bp, OLWI_titleBarLeftGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	mov	ax, cx				; ax = width
	pop	cx, dx
	jcxz	noLeftGroupPosition
	sub	cx, ax				; cx = position for left part
	dec	cx				; HACK! adjustment
	mov	bp, offset OLWI_titleBarLeftGroup
	call	OpenWinPositionTitleBarGroup
	inc	cx				; adjust for next icon (overlap)

noLeftGroupPosition:
	;
	; position standard icons on left
	;
	call	WinCommon_DerefVisSpec_DI
	tst	ds:[di].OLWI_sysMenu
	jz	noLeftStandardIcons		;no sys menu -> no icons

;	sub	cx, CUAS_WIN_ICON_WIDTH		;(cx,dx)= position
	;get width of system menu button from the system menu
if _ISUI
	call	CheckSysMenuButton
	jnc	noSysMenu
endif
	mov_tr	ax, cx
	call	OpenWinGetSysMenuButtonWidth	; cx = button width
ISU <	add	cx, ISUI_SYS_MENU_FUDGE		; ISUI sysMenuButton is wider>
	sub	ax, cx
	mov_tr	cx, ax

noSysMenu::
ISU <	push	dx							>
ISU <	mov	dx, ds:[di].OLWI_titleBarBounds.R_top			>
	clr	ax				;no SysMenu item to update
	mov	bl, mask OLWSI_SYS_MENU		;mask for Sys Menu icon
	call	WinCommon_DerefVisSpec_DI
	mov	bp, ds:[di].OLWI_sysMenuButton	;chunk handle of menu button
	call	OpenWinEnableAndPosSysMenuIcon
ISU <	pop	dx							>
noLeftStandardIcons:

	pop	cx				;(cx,dx) = top right of title
;	inc	cx				;new coordinate system

	;
	; position right title bar group, if any
	;	cx = position for leftmost part of this group
	;
	mov	bp, offset OLWI_titleBarRightGroup
	call	OpenWinPositionTitleBarGroup

	jc	noRightGroupPosition
	push	cx, dx
	mov	bp, OLWI_titleBarRightGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	mov	ax, cx				; ax = width
	pop	cx, dx
	add	cx, ax				; cx = next icon X position
;give full room for title bar groups
;	dec	cx				; adjust for next icon (overlap)
noRightGroupPosition:

	;
	; position standard icons on right
	;

	call	WinCommon_DerefVisSpec_DI
	tst	ds:[di].OLWI_sysMenu
	jz	noRightStandardIcons		;no sys menu -> no icons

	mov	ax, offset SMI_Move		;chunk handle of menu item
	mov	bl, mask OLWSI_MOVE		;mask for Move
	clr	bp				;no Move icon
	call	OpenWinEnableAndPosSysMenuIcon

	mov	ax, offset SMI_Size		;chunk handle of menu item
	mov	bl, mask OLWSI_SIZE		;mask for Size
	clr	bp				;no Size icon
	call	OpenWinEnableAndPosSysMenuIcon

	mov	ax, offset SMI_Minimize		;chunk handle of menu item
	mov	bl, mask OLWSI_MINI		;mask for Minimize icon
	mov	bp, offset SMI_MinimizeIcon	;chunk handle of icon
	call	OpenWinEnableAndPosSysMenuIcon

	mov	ax, offset SMI_Maximize		;chunk handle of menu item
	mov	bl, mask OLWSI_MAXI		;mask for Maximize icon
	mov	bp, offset SMI_MaximizeIcon	;chunk handle of icon
	call	OpenWinEnableAndPosSysMenuIcon

	mov	ax, offset SMI_Restore		;chunk handle of menu item
	mov	bl, mask OLWSI_RESTORE		;mask for Restore icon
	mov	bp, offset SMI_RestoreIcon	;chunk handle of icon
	call	OpenWinEnableAndPosSysMenuIcon

	mov	ax, offset SMI_Close		;chunk handle of menu item
	mov	bl, mask OLWSI_CLOSABLE		;mask for Close icon
if _ISUI
	add	cx, 2				;gap between min/max & close
	mov	bp, offset SMI_CloseIcon	;chunk handle of icon
else
	clr	bp				;pass: no icon
endif
	call	OpenWinEnableAndPosSysMenuIcon

noRightStandardIcons:

done:
	ret
OpenWinPositionSysMenuIcons	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetTitleBarGroupSize

DESCRIPTION:	Get width and height of title bar group.

CALLED BY:	INTERNAL
			OpenWinPositionSysMenuIcons
		EXTERNAL
			OpenWinCalcMinWidth

PASS:		*ds:si	- OLWinClass instance data
		bp	- offset in OLWinClass instance to optr of title bar
				group

RETURN:		cx, dx	= size of title bar group
		cx = 0 if no title bar group

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/16/92		Initial version

------------------------------------------------------------------------------@
OpenWinGetTitleBarGroupSize	proc	far
	uses	ax, bx, si
	.enter
	call	WinCommon_DerefVisSpec_DI
	mov	bx, ({optr} ds:[di][bp]).handle
	mov	cx, bx				; in case no group
	tst	bx
	jz	done
	mov	si, ({optr} ds:[di][bp]).chunk
	call	ObjSwapLock			; *ds:si = title bar group
						; (bx = OLWin block handle)
	clr	cx				; assume not in visible tree
	call	VisCheckIfSpecBuilt
	jnc	unlockDone			; nope
;we never want to check this when getting title bar group size!
;- brianc 2/25/93
;	call	WinCommon_DerefVisSpec_DI
;	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
;	jz	unlockDone			; nope
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	mov	ax, MSG_VIS_RECALC_SIZE
;	mov	ax, MSG_VIS_RECALC_SIZE_AND_INVAL_IF_NEEDED
	call	WinCommon_ObjCallInstanceNoLock	; cx = width, dx = height
	call	OpenCheckIfBW
	jnc	unlockDone
	jcxz	unlockDone			; keep non-negative
	dec	cx				; so we overlap adjacent button
unlockDone:
	call	ObjSwapUnlock
done:
	.leave
	ret
OpenWinGetTitleBarGroupSize	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinPositionTitleBarGroup

DESCRIPTION:	Set width and height and position of title bar group.

CALLED BY:	OpenWinPositionSysMenuIcons

PASS:		*ds:si	- OLWinClass instance data
		bp	- offset in OLWinClass instance to optr of title bar
				group
		cx, dx	- position for top, left of title bar group

RETURN:		carry clear if title bar group positioned
		carry set otherwise

DESTROYED:	ax, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/16/92		Initial version

------------------------------------------------------------------------------@
OpenWinPositionTitleBarGroup	proc	near
	uses	bx, si, cx, dx
	.enter
	;
	;  If no title group, bail.
	;
	call	WinCommon_DerefVisSpec_DI
	mov	bx, ({optr} ds:[di][bp]).handle
	tst	bx				; (clears carry)
	jz	done
	;
	;  Sadly, this little piece of code cost me many hours of
	;  debugging time.  The title-bar "height" we get here is
	;  actually the wrong height!  See OLWinGetTitleBarHeight
	;  for more details -- this code needs to match that code.
	;
	mov	ax, ds:[di].OLWI_titleBarBounds.R_bottom
	sub	ax, ds:[di].OLWI_titleBarBounds.R_top	; ax = title bar height
if _ISUI
	call	OpenCheckIfBW			; that's all for BW
	jc	gotHeight
	sub	ax, 4				; margins = 2 above / 2 below
gotHeight:
else
	call	OpenCheckIfBW			; that's all for BW
	jc	gotHeight
	dec	ax				; small adjustment for color
	dec	ax
gotHeight:
endif
	;
	; Fairly bad hack to match menu bar height.  -cbh 5/12/92
	; Must match similar hack in OLBaseWinUpdateExpressToolArea.
	;
	call	OpenWinCheckIfSquished		; running CGA?
	jc	205$				; yes, skip this
	call	OpenWinCheckMenusInHeader	; are we in the header?
	jnc	205$				; nope, done
	add	ax, 3				; else expand to match menu bar
205$:

	mov	si, ({optr} ds:[di][bp]).chunk
	call	ObjSwapLock			; *ds:si = title bar group
						; (bx = OLWin block handle)
	call	VisCheckIfSpecBuilt
	jnc	unlockDone			; nope (carry clear -> title
						;	bar group not placed)
;we never want to check this when positioning title bar group! - brianc 2/25/93
;	call	WinCommon_DerefVisSpec_DI
;	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
;	jz	unlockDone			; nope (carry clear -> title
						;	bar group not placed)
	;
	;  Tell the title group to resize itself, but pass the
	;  height of the title bar as the requested height.
	;
	push	cx, dx				; save position
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, ax
	mov	ax, MSG_VIS_RECALC_SIZE
	call	WinCommon_ObjCallInstanceNoLock	; cx = width, dx = height
	push	cx				; save untweaked width

	push	dx
	call	VisSetSize
	pop	dx

	pop	ax				; ax = untweaked width
	pop	cx, dx				; get position for group

	mov	ax, MSG_VIS_POSITION_BRANCH
	call	WinCommon_ObjCallInstanceNoLock
	;
	;  Last thing to do is set the bits on the object to say
	;  the geometry has been calculated.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
					 or mask VOF_GEO_UPDATE_PATH)

	mov	ax, MSG_VIS_SET_ATTRS
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE)
	mov	dl, VUM_MANUAL			;object will be updated later
	call	WinCommon_ObjCallInstanceNoLock
	call	WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL

	stc					; indicate success
unlockDone:
	call	ObjSwapUnlock			; (preserves flags)
done:
	cmc					; carry clear = success
	.leave
	ret
OpenWinPositionTitleBarGroup	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnableAndPosSysMenuIcon

DESCRIPTION:	This procedure updates one of the objects related to
		the Motif/CUA system menu: system menu button, triggers
		inside the system menu, and the icons which serve as
		shortcuts to the items in the system menu.

CALLED BY:	OpenWinPositionSysMenuIcons

PASS:		ds:*si	- OLWinClass instance data
		cx, dx	= position to place this icon
		bh	= icon enable/disable flags - determined above
		bl	= mask to choose one of the icons to enable/disable
		bp	= chunk handle of icon object (if there is one)
		ax	= chunk handle of menu item (if there is one)

RETURN:		cx, dx	= position to place next icon, to the right

DESTROYED:	bp

PSEUDO CODE/STRATEGY:

	SEE OpenWinCalcWinHdrGeometry FOR FULL DOC.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version
	Doug	4/92		Broke up for clarity, augmentation

------------------------------------------------------------------------------@

OpenWinEnableAndPosSysMenuIcon	proc	near
	class	OLWinClass
	;
	; If no system menu, skip icons, though update the system menu
	; button itself (pinnable menus have this button added when pinned,
	; removed when unpinned)
	;
	push	bx
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU
	jnz	doIcon

	clr	bh				; disable icon
doIcon:
	call	EnableDisableAndPosSysIcon
	pop	bx

	GOTO	EnableDisableSysMenuItem

OpenWinEnableAndPosSysMenuIcon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnableDisableAndPosSysIcon

DESCRIPTION:	Enable/disables system icon, & positions it if being
		enabled.

CALLED BY:	OpenWinEnableAndPosSysMenuIcon

PASS:		ds:*si	- OLWinClass instance data
		cx, dx	= position to place this icon
		bh	= icon enable/disable flags - determined above
		bl	= mask to choose one of the icons to enable/disable
		bp	= chunk handle of icon object (if there is one)

RETURN:		cx, dx	= position to place next icon, to the right

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	SEE OpenWinCalcWinHdrGeometry FOR FULL DOC.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version
	Doug	4/92		broke out from OpenWinEnableAndPosSysMenuIcon

------------------------------------------------------------------------------@

EnableDisableAndPosSysIcon	proc	near	uses	ax, bx, si, di, bp
	class	OLWinClass
	.enter
	tst	bp			; is there an icon?
	LONG	jz	exit			; quit out if not.

	; Get width & height to use, if enabling.  Do this NOW while it is
	; easy to get to OLWinClass object.
	;
	test	bh, bl
	jz	readyWithWidthHeight
	; Set ax = width of system menu button
	;     di = height of title bar
	;
	push	cx, dx
	call	OpenWinGetSysMenuButtonWidth	; cx = button width
	mov	ax, cx
	call	WinCommon_DerefVisSpec_DI
	mov	dx, ds:[di].OLWI_titleBarBounds.R_bottom
	sub	dx, ds:[di].OLWI_titleBarBounds.R_top
if THREE_DIMENSIONAL_BORDERS
	sub	dx, THREE_D_BORDER_THICKNESS
endif
if _ISUI
	cmp	bp, ds:[di].OLWI_sysMenuButton	; sysMenu button is 3 pixels
	jne	notSysMenuButton		; wider and is as tall as the
	add	ax, 3+4				; titlebar in ISUI
						; more room for icon
	jmp	afterAdjustment
notSysMenuButton:
	call	OpenCheckIfBW			; that's all for BW
	jc	10$
	sub	dx, 4				; margins = 2 above / 2 below
10$:
	; we need to adjust the width of the button if it is a SMI_CloseIcon
	; button for GenPrimary and we are in ConsumerUI
	;
	; Changed this to put "Done" in place of "X" everywhere
	; in the ConsumerUI. If making a change, also change
	; OpenWinEnsureSysMenuIcons() & OpenWinPositionSysMenuIcons()
	;   -Don 4/22/99
	;
	cmp	bp, offset SMI_CloseIcon
	jne	afterAdjustment

;;;	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
;;;	jne	afterAdjustment

	push	ax
	call	UserGetDefaultUILevel		;ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	pop	ax
	jne	afterAdjustment

	push	bx, si, dx, bp
	mov	bx, ds:[di].OLWI_sysMenu
	mov	si, bp
	mov	ax, MSG_VIS_RECALC_SIZE
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	inc	cx				; looks better with a bit more
	mov	ax, cx				; ax = button width
	pop	bx, si, dx, bp
afterAdjustment:
endif

	;Fairly bad hack to match menu bar height.  -cbh 5/12/92
	;Must match similar hack in OLBaseWinUpdateExpressToolArea.

	call	OpenWinCheckIfSquished		; running CGA?
	jc	5$				; yes, skip this
	call	OpenWinCheckMenusInHeader	; are we in the header?
	jnc	5$				; nope, done
	add	dx, 3				; else expand to match menu bar
5$:

	mov	di, dx
	pop	cx, dx
readyWithWidthHeight:

	test	bh, bl
	pushf

	; NOW, get *ds:bp = icon
	;
	push	di
	call	WinCommon_DerefVisSpec_DI
if TOOL_AREA_IS_TASK_BAR
	test	bl, mask OLWSI_SYS_MENU		;mask for Sys Menu icon
	jz	normalSysMenu
	call	GetSystemMenuBlockHandle	; return bx = sys menu
	jmp	short haveSysMenu
endif
normalSysMenu:
	mov	bx, ds:[di].OLWI_sysMenu	; fetch system menu block
haveSysMenu:
	pop	di
	call	ObjSwapLock		; bx is old block, must be preserved
	mov	si, bp			; *ds:si = icon

	;since we're about to handle geometry, clear geometry flags now

	push	di
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	pop	di
	popf				; get flag from above
	push	bx				; save old block for end

;	test	bh, bl
	jz	disableIcon			; skip to disable icon...

;enableIcon:
	;enable icon: calculate height of title bar

	push	cx, dx			; save position passed in
	mov	cx, ax			; get width, height calculated earlier
	mov	dx, di
	push	cx				; save width

MO <	push	ds							>
MO <	mov	ax, segment dgroup					>
MO <	mov	ds, ax							>
MO <	test	ds:[moCS_flags], mask CSF_BW	; Is this a B&W display?>
MO <	pop	ds							>
MO <	jnz	20$				;   skip if so...	>
MO <	sub	dx, 2				; Nest icon inside resize  >
MO <	dec	cx				;   bars & title in a color>
MO <20$:					;   display		   >

ISU <	push	ds							>
ISU <	mov	ax, segment dgroup					>
ISU <	mov	ds, ax							>
ISU <	test	ds:[moCS_flags], mask CSF_BW	; Is this a B&W display?>
ISU <	pop	ds							>
ISU <	jnz	20$				;   skip if so...	>
ISU <	dec	cx				; Nest icon inside resize  >
ISU <20$:					;   bars & title in a color>
						;   display		   >

	;set size of icon (dx = height of title bar)
	mov	ax, MSG_VIS_SET_SIZE
	call	WinCommon_ObjCallInstanceNoLock
	pop	ax				; ax = button width
	pop	cx, dx			; get position

	;set position of icon

	push	ax				; save button witdh
	push	cx, dx				;save position
	mov	ax, MSG_VIS_POSITION_BRANCH
	call	WinCommon_ObjCallInstanceNoLock
	pop	cx, dx
;	add	cx, CUAS_WIN_ICON_WIDTH-1	;provide hint as to where
;						;next icon goes
	pop	ax				; ax = button width
	dec	ax
	add	cx, ax				; cx = next icon X position

	;set drawable and detectable: will set IMAGE_INVALID bits upwards

	push	cx, dx
	mov	ax, MSG_VIS_SET_ATTRS
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE)
	mov	dl, VUM_MANUAL			;object will be updated later
	call	WinCommon_ObjCallInstanceNoLock

;Added 4/4/90 to ensure that a VisOpen will occur.

	;set the menu button window invalid, so that it gets an update

	call	WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL

;ADDED 4/4/90 to make these icons work as Workspace/Application menu buttons
;and GCM header icons do.

	;since we have handled geometry, clear invalid flags now

	mov	cx, (mask VOF_GEOMETRY_INVALID or \
		     mask VOF_GEO_UPDATE_PATH) shl 8
	clc				;*ds:si is object
	call	OpenWinSetObjVisOptFlags ;reset these flags
	pop	cx, dx
	jmp	short done

disableIcon:
	;set not drawable or detectable (will set IMAGE_INVALID bits upwards)

	push	cx, dx
	mov	ax, MSG_VIS_SET_ATTRS
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE) shl 8
	mov	dl, VUM_MANUAL			;object will be updated later
	call	WinCommon_ObjCallInstanceNoLock
	pop	cx, dx
done:
	pop	bx
	call	ObjSwapUnlock

exit:
	.leave
	ret
EnableDisableAndPosSysIcon	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	EnableDisableSysMenuItem

DESCRIPTION:	Enables/disables a menu item somewhere on the system menu.

CALLED BY:	OpenWinEnableAndPosSysMenuIcon

PASS:		ds:*si	- OLWinClass instance data
		bh	= icon enable/disable flags - determined above
		bl	= mask to choose one of the icons to enable/disable
		ax	= chunk handle of menu item in sys menu
				(if there is one)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	SEE OpenWinCalcWinHdrGeometry FOR FULL DOC.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version
	Doug	4/92		broke out from OpenWinEnableAndPosSysMenuIcon

------------------------------------------------------------------------------@

EnableDisableSysMenuItem	proc	near	uses	ax, cx, dx, bp, bx, si
	class	OLWinClass

	tst	ax				; if no item, done.
	jz	exit

	.enter
	call	WinCommon_DerefVisSpec_DI	; get ds:di ptr to OLWinInstance

	;
	; if sys menu is just a close button, there are no menu items to
	; enable/disable
	;
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	done

	mov	si, ax				; get si = item chunk handle

	test	bh, bl				; enable icon or disable icon?
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume disabling
	jz	disableIcon			; skip to disable icon...
	mov	ax, MSG_GEN_SET_ENABLED		; wrong -- enable it.
disableIcon:
if TOOL_AREA_IS_TASK_BAR
	test	bl, mask OLWSI_SYS_MENU		; mask for Sys Menu icon
	jz	normalSysMenu
	call	GetSystemMenuBlockHandle	; return bx = sys menu
	jmp	short haveSysMenu
endif

normalSysMenu:
	mov	bx, ds:[di].OLWI_sysMenu	; get system menu block handle,
						; so ^lbx:si is item
haveSysMenu:
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave

exit:
	ret
EnableDisableSysMenuItem	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetSysMenuButtonWidth

DESCRIPTION:	Returns width of window's system menu button.

CALLED BY:	INTERNAL
			?
		EXTERNAL
			OpenWinCalcMinWidth

PASS:		*ds:si	- instance data

RETURN:		cx = width of button

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/7/92		initial version
	Doug	4/92		fixed to work w/sys menu in separate block,
				and require *ds:si of OLWinClass only

------------------------------------------------------------------------------@

if _ISUI
CheckSysMenuButton	proc	far
	push	ax
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	je	done			; C clr, no sys menu
	stc				; else C set, have sys menu
done:
	pop	ax
	ret
CheckSysMenuButton	endp
endif

OpenWinGetSysMenuButtonWidth	proc	far
	class	OLWinClass
	uses	ax, bx, dx, bp, si, di
	.enter
	call	WinCommon_DerefVisSpec_DI
	mov	si, ds:[di].OLWI_sysMenuButton	; si = offset of button chunk
	clr	cx				; in case no button
	tst	si
	jz	done				; no button --> no width

if TOOL_AREA_IS_TASK_BAR
	call	GetSystemMenuBlockHandle	; returns bx = sys menu block
else
	mov	bx, ds:[di].OLWI_sysMenu
endif

	call	ObjSwapLock			; *ds:si is menu button
	push	bx
	;
	; Find out from button if it is going to show its keyboard
	; accelerator.  If not, use fixed width button.  Else, ask
	; button to compute its size.
	;
	clr	al				; normal handling
	call	OLButtonSetupMonikerAttrs	; cx = moniker attrs
	test	cx, mask OLMA_DISP_KBD_MONIKER	; does it show shortcut?
	mov	cx, CUAS_WIN_ICON_WIDTH		; assume not
	jz	ok				; it doesn't use fixed width
						;	button
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	mov	ax, MSG_VIS_RECALC_SIZE
	call	ObjCallInstanceNoLock		; cx = width
ok:
	pop	bx
	call	ObjSwapUnlock
done:
	.leave
	ret
OpenWinGetSysMenuButtonWidth	endp

WinCommon	ends
WinOther	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinSysMenuMove -- MSG_MO_SYSMENU_MOVE

DESCRIPTION:	This is invoked when the user presses on the Move icon
		or menu item in the system menu.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version
	brianc	12/17/92	implemented

------------------------------------------------------------------------------@

OpenWinSysMenuMove	method dynamic	OLWinClass, MSG_MO_SYSMENU_MOVE
						; in case we aren't
	test	ds:[di].OLWI_attrs, mask OWA_MOVABLE
	jz	done
	call	OpenWinStartMoveResizeMonitor
	jc	done				; something already in progress
	ornf	ds:[di].OLWI_moveResizeState, mask OLWMRS_MOVING
;	mov	bp, mask XF_END_MATCH_ACTION
;no end on button action
	mov	bp, mask XF_NO_END_MATCH_ACTION
	call	OpenWinStartMoveResizeCommon
done:
	ret
OpenWinSysMenuMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinStartMoveResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	setup params for and call ImStartMoveResize

CALLED BY:	INTERNAL
			OpenWinSysMenuMove, OpenWinSysMenuResize

PASS:		*ds:si = OLWin
		bp = XorFlags

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinStartMoveResizeCommon	proc	near

xorFlags	local	word	push	bp
bottom		local	word
right		local	word

	.enter

	mov	di, [di].VCI_window	; Get window handle
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	;make sure we have a window	>

	;now begin to PUSH ARGS for call to ImStartMoveResize:

	;
	; move mouse to center of window
	;
	call	VisGetSize		;cx, dx = bottom, right
	mov	right, cx
	mov	bottom, dx
	shr	cx, 1
	shr	dx, 1
	movdw	axbx, cxdx		;ax, bx = desired mouse position
	call	ImGetMousePos		;cx, dx = current mouse position
					;XXX: not relative to this thread?
	sub	ax, cx			;ax, bx = mouse deflection needed
	sub	bx, dx
	movdw	cxdx, axbx		;cx, dx = mouse deflection needed
	push	bp, di			;save locals, window
	mov	ax, MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE
	call	ObjCallInstanceNoLock
	;
	; now that pointer is over window, grab mouse and kbd
	;
	mov	ax, MSG_FLOW_GRAB_MOUSE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallFlow
	call	VisForceGrabMouse
	mov	ax, MSG_OL_WIN_STARTUP_GRAB
	call	ObjCallInstanceNoLock
	;
	; We grab focus for the Express menu case (it gets released when the
	; system menu is closed (see OLMenuWinAlterFTVMCExcl)).  Doesn't hurt
	; for other windows.
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	;
	; grab keyboard: must grab keyboard after grabbing focus as some
	; objects in dialogs like to grab the keyboard when they gain focus
	;
	call	VisForceGrabKbd
	pop	bp, di			;restore locals, window
	;
	; pass start mouse position (mouse deflection above may be limited
	; by screen, so we call ImGetMousePos again)
	;
	push	bp			;save locals before any params
					; (restored after ImStartMoveResize)
	call	ImGetMousePos		;cx, dx = current mouse position
					;XXX: not relative to this thread?
	push	cx			;Pass the x offset in doc coords
	push	dx			;Pass the y offset in doc coords

	movdw	axbx, cxdx
	call	WinTransform		;convert to screen coordinates
					;store for end
	push	es
	segmov	es, dgroup, cx		;es = dgroup
	mov	es:[olScreenStart.P_x], ax
	mov	es:[olScreenStart.P_y], bx
	pop	es

	mov	cx, right
	mov	dx, bottom

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	;just a thin line
	clr	ax			; rectangle, not a region
	push	ax			;   (pass 0 address)
	push	ax
endif		;END of OPEN LOOK specific code -------------------------------

if	_CUA_STYLE	;START of MOTIF specific code -------------------------

if	 _ROUND_THICK_DIALOGS
	mov	ax, offset RoundedPrimaryResizeRegion	;assume rounded border
	call	OpenWinShouldHaveRoundBorderFar		;destroys nothing
	jc	wasRounded
endif	;_ROUND_THICK_DIALOGS

	mov	ax, offset PrimaryResizeRegion
					;assume is normal window
	push	di
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	jz	notIcon			;skip if is not window icon

	mov	ax, offset WinIconResizeRegion

notIcon:
	pop	di

if	 _ROUND_THICK_DIALOGS
wasRounded:
endif	;_ROUND_THICK_DIALOGS
					; Get segment that regions are in
	mov	bx, handle PrimaryResizeRegion
	push	bx			; ^hbx:ax = region definition, push
	push	ax
endif		;END of MOTIF specific code -----------------------------------

	clr	ax			; top, left of bounds
	clr	bx

	mov	si, xorFlags		; si = XorFlags
;	mov	bp, 0x0080		; end on any press
;no end on button action
	mov	bp, 0
	call	ImStartMoveResize	; Start the screen xor'ing

	pop	bp			; restore locals

	.leave
	ret
OpenWinStartMoveResizeCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinStartMoveResizeMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up input monitor to detect mouse button activity to
		stop keyboard move/resize

CALLED BY:	INTERNAL
			OpenWinSysMenuMove
			OpenWinSysMenuSize

PASS:		*ds:si = OLWin
		es = segment of OLWinClass

RETURN:		carry clear if monitor installed
		carry set if exclusive keyboard move/resize already
			in progress, should not start another

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinStartMoveResizeMonitor	proc	near
	;
	; set up input monitor to detect mouse press
	;
	mov	bx, ds:[LMBH_handle]

	push	ds
;	segmov	ds, es				;es is no longer dgroup
	segmov	ds, dgroup, ax			;ds = dgroup
	PSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
	test	ds:[olMoveResizeMonitorFlags], mask OLMRMF_ACTIVE or \
						mask OLMRMF_REMOVE_PENDING
	jnz	alreadyActive

	movdw	ds:[olWinObject], bxsi

	;
	; get PtrFlags so we can restore them when we finish (we set certain
	; PtrFlags during the keyboard move/resize)
	;
	call	ImGetPtrFlags			; al = PtrFlags
	mov	ds:[olMoveResizeSavedPtrFlags], al
	;
	; get current mouse position so we can restore it when we finish
	; *if* we have PF_DISEMBODIED_PTR or
	; PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	;
	push	di
	clr	di				; no window
	call	ImGetMousePos			; cx, dx = mouse pos
	mov	ds:[olMoveResizeSavedMousePos].P_x, cx
	mov	ds:[olMoveResizeSavedMousePos].P_y, dx
	pop	di
	;
	; add monitor
	;
	mov	bx, offset olMoveResizeAbortMonitor
	mov	cx, segment OpenWinMoveResizeAbortMonitor
	mov	dx, offset OpenWinMoveResizeAbortMonitor
	mov	al, ML_OUTPUT-1
	call	ImAddMonitor
	mov	ds:[olMoveResizeMonitorFlags], mask OLMRMF_ACTIVE
	clc					; indicate success
	jmp	short done

alreadyActive:
	stc
done:
	pushf
	VSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
	popf
	pop	ds
	ret
OpenWinStartMoveResizeMonitor	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinSysMenuSize -- MSG_MO_SYSMENU_SIZE

DESCRIPTION:	This is invoked when the user presses on the Size icon
		or menu item in the system menu.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version
	brianc	12/17/92	implemented

------------------------------------------------------------------------------@

OpenWinSysMenuSize	method dynamic	OLWinClass, MSG_MO_SYSMENU_SIZE
						; in case we aren't
	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jz	done
	call	OpenWinStartMoveResizeMonitor
	jc	done				; something already in progress
	ornf	ds:[di].OLWI_moveResizeState, mask OLWMRS_RESIZE_PENDING
;	mov	bp, mask XF_END_MATCH_ACTION or \
;			mask XF_RESIZE_PENDING	; just sit there
;no end on button action
	mov	bp, mask XF_NO_END_MATCH_ACTION or mask XF_RESIZE_PENDING
	call	OpenWinStartMoveResizeCommon
done:
	ret
OpenWinSysMenuSize	endp

WinOther	ends

;---------------------------

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinMoveResizeAbortMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	input monitor to detect mouse press on which to abort
		keyboard move/resize

CALLED BY:	Input Manager

PASS:		al	= MF_DATA
		di	= event type
				MSG_META_MOUSE_PTR
				MSG_META_MOUSE_BUTTON
				MSG_META_KBD_CHAR
		for MSG_META_MOUSE_PTR, MSG_META_MOUSE_BUTTON:
			cx = pointer x position
			dx = pointer y position
			bp low = ButtonInfo
			bp high = ShiftState
		for MSG_META_KBD_CHAR
			cx = character value
			dl = CharFlags
			dh = ShiftState
			bp = low ToggleState
			bp high = scan code

RETURN:		al	= MonitorFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinMoveResizeAbortMonitor	proc	far
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	done			; not button, send on through
	;
	; button press or release, remove monitor, then send out a fake
	; RETURN kbd char event to finish the move resize
	;

	push	bx, si

	push	ds
	mov	ax, segment olMoveResizeAbortMonitor
	mov	ds, ax
	PSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
EC <	test	ds:[olMoveResizeMonitorFlags], mask OLMRMF_ACTIVE	>
EC <	ERROR_Z	OL_ERROR		; was not active?!?!		>
	test	ds:[olMoveResizeMonitorFlags], mask OLMRMF_REMOVE_PENDING
	jnz	skip			; carry clear
	ornf	ds:[olMoveResizeMonitorFlags], mask OLMRMF_REMOVE_PENDING
	stc				; send RETURN
skip:
	movdw	bxsi, ds:[olWinObject]

	pushf
	VSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
	popf
	pop	ds
	jnc	consume

SBCS <	mov	cx, VC_ENTER or (CS_CONTROL shl 8) 			>
DBCS <	mov	cx, C_SYS_ENTER						>
	mov	dx, mask CF_FIRST_PRESS
	clr	bp
	mov	ax, MSG_META_KBD_CHAR	; convert to kbd char
	clr	di
	call	ObjMessage

consume:
	pop	bx, si
	clr	al			; consume event

done:
	ret
OpenWinMoveResizeAbortMonitor	endp

Resident	ends

;-------------

WinOther	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinTurnOnAndBumpMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on ptr and do MSG_VIS_VUP_BUMP_MOUSE

CALLED BY:	MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE

		cx, dx, bp	= Same as MSG_VIS_VUP_BUMP_MOUSE

RETURN:		Same as MSG_VIS_VUP_BUMP_MOUSE

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinTurnOnAndBumpMouse	method	dynamic	OLWinClass,
					MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE

	mov	ax, (mask PF_DISEMBODIED_PTR or \
			mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE ) shl 8
	call	ImSetPtrFlags
	mov	ax, MSG_VIS_VUP_BUMP_MOUSE
	GOTO	ObjCallInstanceNoLock

OLWinTurnOnAndBumpMouse	endm

WinOther	ends
