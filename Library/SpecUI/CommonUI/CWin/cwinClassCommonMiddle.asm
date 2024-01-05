COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinClassCommonMiddle.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OpenWinCheckMenusInHeader
				Checks if menus can go in header.

    MTD MSG_SPEC_UNBUILD        For ANY window, if unbuilt, then shouldn't
				be on active list, as windows are only
				unbuilt if completely not USABLE.  This
				approach is better than handling this in
				MSG_SPEC_SET_NOT_USABLE, since that method
				is only called for the exact object which
				is set NOT_USABLE, & not if any of its
				parents are.

    INT WinCommon_ObjCallSuperNoLock_OLWinClass_Far
				For ANY window, if unbuilt, then shouldn't
				be on active list, as windows are only
				unbuilt if completely not USABLE.  This
				approach is better than handling this in
				MSG_SPEC_SET_NOT_USABLE, since that method
				is only called for the exact object which
				is set NOT_USABLE, & not if any of its
				parents are.

    INT OpenWinEnsureOnWindowList
				Makes sure that the OLWinClass object
				passed is on the window list.

    INT OLWinTakeOffWindowList  Deal with window list, now that window no
				longer needs to be on it.

    INT OpenWinEnsureRealizableOnTop
				A general routine for making sure that a
				window is marked as REALIABLE, & if
				otherwise allowed, visible on screen, on
				top of all other windows within the layer.

    MTD MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT
				This method is sent up the focus hierarchy
				(visible tree) by some object in this
				window which thinks that the default action
				for the window should be triggered.

    MTD MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
				This method is used to implement the
				keyboard navigation within-a-window
				mechanism. See method declaration for full
				details.

    INT OpenWinNavigateCommon   This procedure is used by
				MSG_SPEC_NAVIGATE_TO_NEXT_FIELD and
				MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
				handlers.

    MTD MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS
				The generic version of this method is sent
				when the specific UI opens a window, and
				wants to know if an object within the
				window has HINT_DEFAULT_FOCUS{_WIN}.

    MTD MSG_SPEC_UPDATE_VIS_MONIKER
				Intercept method heading for VisClass which
				would normally cause whole window to be
				invalidated.  Instead, just redraw the
				header.

    INT OpenWinHeaderMarkInvalid
				This procedure is used to mark that certain
				aspects of the window header area are
				invalid and must be redrawn.

    INT OpenWinTestForFocusAndTarget
				This procedure tests if this window should
				be drawn with a highlighted border (BLUE in
				CUA, Dark in OpenLook, etc).

    INT OpenWinHeaderResetInvalid
				This procedure is called to reset one or
				more of the header area INVALID flags. We
				generally so this as we draw that item.

    MTD MSG_OL_WIN_UPDATE_HEADER
				This method is sent by
				OpenWinHeaderMarkInvalid when it changes
				the OLWI_headerState flags. By the time
				this method gets through the UI queue, all
				of the various state changing (and geometry
				adjusting) methods have finished, and we
				can redraw the appropriate sections of the
				header.

    INT OpenWinDrawFieldIconsIfBaseWindow
				This procedure draws the Express Menu
				button if this window is an OLBaseWinClass
				object.

    INT OpenWinCalcWinHdrGeometry
				This procedure is called when the window is
				created, moved, or resized. We determine
				which UI-specific icons should appear in
				the header, enable and position them, and
				set the size of the title area
				appropriately.

    MTD MSG_VIS_VUP_QUERY       Handle various VUP query

    INT OpenWinReleaseDefaultGrabAndFixFlag
				Handle various VUP query

    MTD MSG_VIS_OPEN_WIN        Perform MSG_VIS_OPEN_WIN given an OLWinPart

    MTD MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
				update for title group change

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinClassCommon.asm

DESCRIPTION:
	This file contains "WinCommon" procedures for OLWinClass
	See cwinClass.asm for class declaration and method table.

	$Id: cwinClassCommonMiddle.asm,v 1.3 98/05/04 07:24:00 joon Exp $

------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinCheckMenusInHeader

SYNOPSIS:	Checks if menus can go in header.

CALLED BY:	utility
			OpenWinDrawHeaderTitle
			OpenWinDrawHeaderTitleBackground
			OLBaseWinAddFieldIcons
			OLBaseWinRemoveFieldIcons
			OpenWinGetMargins

PASS:		*ds:si -- object

RETURN:		carry set if menus go in the header

DESTROYED:	hmm.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/13/92		Initial version

------------------------------------------------------------------------------@
OpenWinCheckMenusInHeader	proc	far		uses	di
	.enter
	;
	; Check first to see if we're in appropriate mode.
	;
	call	OpenCheckMenusInHeaderOnMax
	jnc	exit

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	exit			;not maximizable, exit, carry clear
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	exit			;not maximized, exit, carry clear

EC <	push	es, di							>
EC <	mov	di, segment OLMenuedWinClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLMenuedWinClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR	;Oops. Chris screwed up.	>
EC <	pop	es, di							>

	tst	ds:[di].OLMDWI_menuBar		;any menu bar?
	jz	exit				;nope, exit carry clear
	stc					;else carry set
exit:
	.leave
	ret
OpenWinCheckMenusInHeader	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinVisUnbuild

DESCRIPTION:	For ANY window, if unbuilt, then shouldn't be on active list,
		as windows are only unbuilt if completely not USABLE.  This
		approach is better than handling this in
		MSG_SPEC_SET_NOT_USABLE, since that method is only called
		for the exact object which is set NOT_USABLE, & not if any
		of its parents are.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_SPEC_UNBUILD

	cx, dx, - ?
	bp	- SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@
OpenWinVisUnbuild	method dynamic	OLWinClass,
					MSG_SPEC_UNBUILD

	test	bp, mask SBF_WIN_GROUP
	LONG jz	afterWinGroup

	; We're unbuilding the win group, therefore we must do several things
	; in addition to the default handling:
	;

	;	0) Set our size invalid, so geometry will be redone if we
	;	   are ever brought back onscreen.

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID

	push	bp

	;	1) Remove ourself from the active list
	;
	call	OLWinTakeOffWindowList

	;	1.5) RELEASE the FOCUS_EXCL, TARGET_EXCL, should we
	; 	   happen to have them.
	;
					; Release exclusives, if we
					; happened to have had it.
	mov	ax, MSG_META_RELEASE_FT_EXCL
	call	ObjCallInstanceNoLock

	pop	bp

	;	2) Free the created objects

	push	si
	push	bp				; Save SpecBuildFlags

	call	WinCommon_DerefVisSpec_DI
CUAS <	push	ds:[di].OLWI_sysMenu		;get system menu >

if	(0)	; are now freed along w/block
if	_CUA_STYLE
	push	ds:[di].OLWI_minButton
	push	ds:[di].OLWI_maxButton
	mov	si, ds:[di].OLWI_restoreButton
	call	SendObjFree
	pop	si				;OLWI_maxButton
	call	SendObjFree
	pop	si				;OLWI_minButton
	call	SendObjFree
endif
endif
	;	2.5) Destroy help trigger, if any

if _ISUI
	mov	ax, TEMP_OL_WIN_HELP_TRIGGER
	call	ObjVarFindData
	jnc	noHelp
	push	si
	push	ds:[bx]
	call	ObjVarDeleteDataAt
	pop	si				; *ds:si = help trigger
	mov	dl, VUM_NOW
	clr	bp
	mov	ax, MSG_GEN_DESTROY
	call	ObjCallInstanceNoLock
	pop	si
noHelp:
endif

	;	3) Destroy the window menu (System menu)
	;.
	pop	bx				; Get system menu
	pop	bp				; Restore SpecBuildFlags
	tst	bx				; if no system menu, skip
	jz	noWindowMenu
CUAS <	clr	ds:[di].OLWI_sysMenu					>

CUAS <	mov	ds:[di].OLWI_sysMenu, 0					>

	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	push	bp
	pushf
	push	ds:[di].OLWI_sysMenuButton
CUAS <	clr	ds:[di].OLWI_sysMenuButton				>
	call	ObjSwapLock
	pop	si				; *ds:si = sys menu close button
	popf					; restore sys menu close flag
	jnz	haveObjectToDestroy		; yes, have sys menu close
	mov	si, offset StandardWindowMenu	; else, have normal sys menu
haveObjectToDestroy:
						; First, visually unbuild
						; the branch (menu & button)
						; (NOTE:  can't use
						; SET_NOT_USABLE, since parent
						; is already NOT_USABLE, &
						; hence nothing will be done.)
	and	bp, not mask SBF_UPDATE_MODE
	or	bp, VUM_NOW			; update NOW
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_BLOCK_FREE		; Then, start process to
	call	ObjCallInstanceNoLock		; NUKE the block
	call	ObjSwapUnlock

	pop	bp

noWindowMenu:
	pop	si

afterWinGroup:
	;	4) Finish up w/having superclass unbuild this object itself

					; Pass method on to superclass
	mov	ax, MSG_SPEC_UNBUILD
	FALL_THRU	WinCommon_ObjCallSuperNoLock_OLWinClass_Far

OpenWinVisUnbuild	endm

WinCommon_ObjCallSuperNoLock_OLWinClass_Far	proc	far
	call	WinCommon_ObjCallSuperNoLock_OLWinClass
	ret
WinCommon_ObjCallSuperNoLock_OLWinClass_Far	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinDestroyAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes any of the objects in this obj block.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLWinClass object
RETURN:		carry set, saying that the object can be nuked
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinDestroyAndFreeBlock	method	OLWinClass,
					MSG_GEN_DESTROY_AND_FREE_BLOCK
	.enter

;	Take the object off the screen.

	mov	cx, IC_DISMISS	; knock dialog off screen if still up
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock

;	Nuke the window menu.

	call	WinCommon_DerefVisSpec_DI
	clr	bx
CUAS <	xchg	bx, ds:[di].OLWI_sysMenu		;get system menu >
	tst	bx
	jz	exit

;	Set BX:SI to be either the "close button" or the top of the "sys menu

	mov	si, ds:[di].OLWI_sysMenuButton
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	nukeMenu
	mov	si, offset StandardWindowMenu
nukeMenu:

;	Visually unbuild the menu, and free it...

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	stc
	.leave
	ret
OpenWinDestroyAndFreeBlock	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureOnWindowList

DESCRIPTION:	Makes sure that the OLWinClass object passed is on the
		window list.

CALLED BY:	INTERNAL
		OpenWinOpenWin, MSG_INITIATE_INTERACTION handlers

PASS:
	*ds:si	- object to ensure on window list

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version pulled from OpenWinOpenWin

------------------------------------------------------------------------------@
OpenWinEnsureOnWindowList	proc	far

	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS or \
						mask GCNLTF_SAVE_TO_STATE
	mov	ax, MSG_META_GCN_LIST_ADD
	call	OpenCallApplicationWithStack	; carry set if successful
						; carry clear if already there
	jnc	done

					; Set hint indicating REALIZABLE
	mov	ax, HINT_INITIATED or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData

done:
	add	sp, size GCNListParams
	ret

OpenWinEnsureOnWindowList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinTakeOffWindowList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with window list, now that window no longer needs to
		be on it.

CALLED BY:	OpenWinVisUnbuild

PASS:		*ds:si	- object to get off window list

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinTakeOffWindowList	proc	far
	uses	ax, cx, dx, bp
	.enter

					;remove hint indicating REALIZABLE
	mov	ax, HINT_INITIATED
	call	ObjVarDeleteData

	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	OpenCallApplicationWithStack
	add	sp, size GCNListParams

	.leave
	ret
OLWinTakeOffWindowList	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureRealizableOnTop

DESCRIPTION:	A general routine for making sure that a window is
		marked as REALIABLE, & if otherwise allowed, visible on
		screen, on top of all other windows within the layer.

CALLED BY:	INTERNAL
		MSG_INITIATE_INTERACTION handlers

PASS:
	*ds:si	- object to set REALIZABLE

RETURN:
	non-zero if object is visible at end.

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

	; Also called from MDIAction resource

OpenWinEnsureRealizableOnTop	proc	far
	class	OLWinClass
					; Make sure window is on the active
					; list, as ALL REALIZABLE windows
					; should be.
	call	OpenWinEnsureOnWindowList

					; If already visible, then must
					; be on active list, just bring it
					; to the top.
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jnz	bringToTop
					; If NOT visible, try again:

					; Mark flag to realize on top,
					; if becomes totally visible
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_OPEN_ON_TOP

					; Cast specific-UI vote to
					; make this OLWinClass realizable
	mov	cx, mask SA_REALIZABLE
	call	WinCommon_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW

					; Clear OPEN_ON_TOP bit, in case
					; it wasn't used.
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_OPEN_ON_TOP)

					; test to see if was made visible,
					; so we can return that status
	test	ds:[di].VI_attrs, mask VA_VISIBLE

bringToTop:
					; In any case, bring the window to
					; the top, in case it isn't there
					; yet.  If not realized, then just
					; update generic instance data to
					; show on top.
	pushf
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	WinCommon_ObjCallInstanceNoLock
	popf
	ret
OpenWinEnsureRealizableOnTop	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinActivateInteractionDefault -
		MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT handler for OLWinClass

DESCRIPTION:	This method is sent up the focus hierarchy (visible tree)
		by some object in this window which thinks that the default
		action for the window should be triggered.

PASS:		*ds:si	= instance data for object

RETURN:		carry set if default activated

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OpenWinActivateInteractionDefault	method dynamic	OLWinClass, \
				MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT

	;
	; if default action is to navigate to next field, do so
	;
	test	ds:[di].OLWI_moreFixedAttr, \
			mask OWMFA_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
	jz	notNavigate
	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	call	ObjCallInstanceNoLock
	jmp	short defaultActionDone

notNavigate:
	;
	; ENTER key has been pressed in this window, or some object
	; decided to send a MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT.
	; Send MSG_GEN_ACTIVATE to GenTrigger which has the default
	; exclusive.
	;
	mov	bx, offset OLWI_defaultExcl
	call	WinCommon_Deref_Load_OD_BXSI
	tst	bx			;is there a default exclusive?
	jz	noDefault		;skip if not...

sendActivate:
	mov	ax, MSG_GEN_ACTIVATE
	call	WinCommon_ObjMessageCallFixupDS

defaultActionDone:
	;
	; return carry set, indicating that default has been activated
	;
	stc
	ret

noDefault:
	;
	; DO NOT USE WinCommon_Deref_Load_FocusExcl_BXSI, because si
	; has been trashed!
	;	ds:di = VisSpec instance data

	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	tst	bx			;is there a focus exclusive?
	clc				;assume not
	jz	done			;skip if not...

	mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
					;set ^lbx:si = focused object

;	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_WINDOW
;	jz	sendActivate		;activate if it is not a window...
;					;(else, carry clear)
;try this instead: - brianc 1/15/93
	mov	cx, segment OLButtonClass
	mov	dx, offset OLButtonClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	WinCommon_ObjMessageCallFixupDS
	jc	sendActivate		;activate if button, popup, etc.

done:
	ret
OpenWinActivateInteractionDefault	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinSpecNavigateToNext - MSG_SPEC_NAVIGATE_TO_NEXT
		OpenWinSpecNavigateToPrevious - MSG_SPEC_NAVIGATE_TO_PREVIOUS

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same

DESTROYED:	ax, bx, cx, dx, bp, es, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OpenWinSpecNavigateToNextField	method dynamic	OLWinClass, \
					MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	clr	bp			;pass flags: navigate forwards
					;pass ds:di = VisSpec instance data
	GOTO	OpenWinNavigateCommon
OpenWinSpecNavigateToNextField	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinNavigateCommon

DESCRIPTION:	This procedure is used by MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
		and MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD handlers.

CALLED BY:	OpenWinSpecNavigateToNextField
		OpenWinSpecNavigateToPreviousField
		OLMenuedWinSpecNavigateToNextField
		OLMenuedWinSpecNavigateToPreviousField

PASS:		*ds:si	= instance data for object
		ds:di	= VisSpec instance data
		bp	= NavigationFlags, to indicate whether navigating
				backwards or forwards, and whether navigating
				through menu bar or controls in window.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Chris	12/ 9/91	Changed to be non-recursive

------------------------------------------------------------------------------@

OpenWinNavigateCommon	proc	far
	;
	; get OD of focused object within this window
	;
	push	bp			;save forward/backward info
	call	WinCommon_Deref_Load_FocusExcl_CXDX

	ORNF	bp, mask NF_SKIP_NODE or mask NF_INITIATE_QUERY
					;pass flag: skip focused node,
					;find next focusable node
	mov	ax, cx			;is there a focused object?
	or	ax, dx
	jnz	sendNavQueryToOD	;skip if so...

	;this window does not yet have a focused object. Find the first
	;object in the visible tree and place the focus on it.
	;(If the application wanted the navigation to start on some specific
	;object, the object would have HINT_MAKE_FOCUS.) Since this method
	;will be passed downwards by composite objects, turn off the SKIP flag.

	call	WinCommon_Mov_CXDX_Self	;set ^lcx:dx = this root object
	ANDNF	bp, not (mask NF_SKIP_NODE)

sendNavQueryToOD:
	;
	; send a navigation query to the specified object. It will forward
	; the method around the navigation circuit (visible tree) if
	; necessary, to find the NEXT/PREVIOUS object we are seeking.
	;
EC <	call	ECVisStartNavigation	;for swat's showcalls		>
EC <	push	bp			;save pass flags		>
	push	si
	mov	ax, MSG_SPEC_NAVIGATE
	mov	bx, cx			;pass ^lcx:dx = object which will
	mov	si, dx			;start the navigation query.
	call	WinCommon_ObjMessageCallFixupDS
	pop	si
EC <	pop	ax			;get passed flags		>
	;
	; error check: if sent to focused object, it MUST return respond
	; by setting the carry flag, even if it is the only object in the
	; navigation circuit. If the focused object was disabled, and there
	; are no other focused objects, then it should have released the
	; focus exclusive already.
	;
EC <	jc	exitNav			;skip if got a reply...		>
EC <	pushf								>
EC <	test	ax, mask NF_SKIP_NODE	;sent to focused object?	>
EC <	ERROR_NZ OL_NAVIGATION_QUERY_TO_FOCUSED_OBJECT_FAILED		>
EC <	popf				;(signal error if so)		>
EC <exitNav:								>
EC <	pushf								>
EC <	call	ECVisEndNavigation	;for swat's showcalls		>
EC <	popf								>

	pop	ax

	;
	; Nothing returned; release the focus.
	;
	jnc	releaseExcl		;skip if not answered (no focusable
					;objects in window)

	tst	cx			;do we have a focusable node?
	jnz	grabFocusExclIfNeeded	;branch if so

releaseExcl:
	;
	; Release the focus excl on the object having the focus below
	; this node.
	;
	call	WinCommon_Deref_Load_FocusExcl_CXDX
	tst	cx
	LONG jz	done
	mov	bp, mask MAEF_FOCUS
	jmp	alterFocusBelowThisNode

grabFocusExclIfNeeded:
	;
	; See if object that answered query hasn't changed.  Don't do anything
	; if so.  Otherwise, grab the focus for the object.
	;
	push	si
	call	WinCommon_Deref_Load_FocusExcl_BXSI
	cmp	si, dx
	pop	si
	jne	grabFocusExcl
	cmp	bx, cx
	LONG je	done

grabFocusExcl:

	;we have found a PREVIOUS node in the navigation circuit.
	;Make it the focused object in this window by sending a
	;MSG_VIS_VUP_GRAB_FOCUS_EXCL to this OLWinClass object with
	;the OD of the child, so as to simulate the child requesting the excl.

	test	bp, mask NF_NAV_MENU_BAR ;are we navigating to the menu bar?
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS
	jz	20$			;skip if is not menu-related object
	ORNF	bp, mask MAEF_OD_IS_MENU_RELATED
20$:

alterFocusBelowThisNode:
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	WinCommon_ObjCallInstanceNoLock
done:
	ret
OpenWinNavigateCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinSpecStartBroadcastForDefaultFocus --
			MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS

DESCRIPTION:	The generic version of this method is sent when the specific
		UI opens a window, and wants to know if an object within the
		window has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint (0:0 if none)
		bp	= info on that object (HGF_IS_WINDOW, etc)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Eric	5/90		rewritten to use broadcast which scans entire
					window.

------------------------------------------------------------------------------@

OpenWinSpecStartBroadcastForDefaultFocus	method dynamic	OLWinClass, \
			MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS
	;
	; initialize OD to nil, since we do not yet know of a default
	; focus obj.
	;
	clr	cx, dx, bp

	;
	; send MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS to all visible
	; children which are FULLY_ENABLED. Returns OD of last object
	; in visible tree which has HINT_DEFAULT_FOCUS{_WIN}.
	;
	mov	ax, MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS
	mov	bx, offset OLBroadcastForDefaultFocus_callBack
					;pass offset to callback routine,
					;in Resident resource
	GOTO	OLResidentProcessVisChildren
OpenWinSpecStartBroadcastForDefaultFocus	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinUpdateVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept method heading for VisClass which would normally
		cause whole window to be invalidated.  Instead, just redraw
		the header.

PASS:		*ds:si	= instance data
		(cx,bp)	= size of old moniker
		dx	= update flags (ignored)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Eric	1/90		New invalid flags used.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinUpdateVisMoniker	method dynamic	OLWinClass, MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; mark the header area as invalid, and place an UPDATE method on the
	; queue so that we will respond to it soon.
	;
	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
					;should we set title area also invalid
					;in case moniker is getting smaller?
	FALL_THRU	OpenWinHeaderMarkInvalid
OpenWinUpdateVisMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinHeaderMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure is used to mark that certain aspects of the
		window header area are invalid and must be redrawn.

PASS:		*ds:si	= instance data for object
		cl	= OpenWinHeaderFlags to set invalid

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinHeaderMarkInvalid	proc	far
	class	OLWinClass
	uses	ax, bx, cx, dx, bp
	.enter

	call	WinCommon_DerefVisSpec_DI

	;
	; If no header or title, nothing to invalidate - brianc 1/5/94
	;
	test	ds:[di].OLWI_attrs, mask OWA_TITLED
	jnz	10$
	test	ds:[di].OLWI_attrs, mask OWA_HEADER
	LONG	jz	done
10$:
	;
	; set the invalid flags
	;
	mov	al, ds:[di].OLWI_headerState	;get current flags
	and	al, cl			;keep bits which where set
					;AND which are being set
	cmp	al, cl			;where all of these bits set?
	LONG	je done			;skip to end if so...

	;we have added an additional flag or two

	xor	al, cl			;set flags which have changed to 1
	push	ax, si, cx

	call	VisQueryWindow		;find Window for this OLWinClass
	or	di, di			;is it realized yet?
	jz	useManual		;skip if not...

if (not _ISUI)	; never use manual as that will erase system icons

	mov	si, WIT_FLAGS		;pass which info we need back
	call	WinGetInfo		;get info on Window structure
	test	al, mask WRF_EXPOSE_PENDING ;will a MSG_META_EXPOSED arrive?
	jz	useManual		;skip if not...

endif	; (not _ISUI)

	;a MSG_META_EXPOSED is pending on this window. Instead of using our
	;MSG_UPDATE_HEADER to later draw portions of the window, let's
	;just set those portions invalid, so that the method_EXPOSED will
	;draw them also.

	pop	ax, si, cx
	;
	; see if the header area is invalid
	;
CUAS <	test	cl, mask OLWHS_HEADER_AREA_INVALID >
	jz	checkTitle

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset	;pass ds:bp = instance data
	call	OpenWinGetHeaderBoundsFar
	jmp	haveBounds

checkTitle:
	;see if the title area is invalid

CUAS <	test	cl, mask OLWHS_TITLE_AREA_INVALID or mask OLWHS_TITLE_IMAGE_INVALID or mask OLWHS_FOCUS_AREA_INVALID >
	jz	checkButtons

	call	OpenWinGetHeaderTitleBounds

ISU <	push	bx, dx							>
ISU <	call	OpenWinGetBounds		;all the way across	>
ISU <	add	ax, 2				;inside window border	>
ISU <	sub	cx, 2				;inside window border	>
ISU <	pop	bx, dx							>

	jmp	haveBounds

checkButtons:
	;see if the button area (Field icons) are invalid
	;	di = gstate

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
CUAS <	cmp	ds:[bp].OLWI_type, MOWT_PRIMARY_WINDOW			>
	jne	done				;skip if not a primary...

haveBounds: ;(ax, bx) - (cx, dx) = bounds of object(s) which should be redrawn.
	push	si
	clr	bp, si				;region is rectangular
	call	WinInvalReg
	pop	si
	jmp	done

useManual:
	pop	ax, si, cx
	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_headerState, cl	;set new flags

	; If window is not allowed to be VISIBLE, then it either isn't on
	; screen yet, or is going down, so in either case, let's skip sending
	; the UPDATE method, to avoid either waste or fatal error, respectively

	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jz	done

	;if no update pending, create one

	test	ds:[di].OLWI_headerState, mask OLWHS_UPDATE_PENDING
	jnz	done

	ORNF	ds:[di].OLWI_headerState, mask OLWHS_UPDATE_PENDING
	mov	ax, MSG_OL_WIN_UPDATE_HEADER
	mov	bx, ds:[LMBH_handle]
	call	WinCommon_ObjMessageForceQueue

done:
	.leave
	ret
OpenWinHeaderMarkInvalid	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinTestForFocusAndTarget

DESCRIPTION:	This procedure tests if this window should be drawn with
		a highlighted border (BLUE in CUA, Dark in OpenLook, etc).

CALLED BY:	OpenWinDrawHeaderBackground

PASS:		*ds:si	= instance data for object
		ds:bp	= specific instance data for object

RETURN:		*ds:si	= same
		ds:bp	= same
		ax	= HGF_HAS_EXCLUSIVE or 0

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	if (IS_MENU) {
		return FALSE (never draw header as highlighted)
	} elif (IS_PRIMARY) {

	    THIS STRANGENESS HAS BEEN NUKED:

		if (TARGET is on windowed object) {
			/* such as a DisplayControl... the user is not
			   interacting with the Primary, but with a Display,
			   so if no FOCUS, do not draw as highlighted. */
			return FOCUS
		} else {
			/* target is on an object - the user is interacting
			   with this Primary, so show title if have
			   FOCUS or TARGET */
			return FOCUS or TARGET
		}
	} else {
		/* is GenPrimary, GenDisplay, or Command Window */

		return FOCUS or TARGET
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OpenWinTestForFocusAndTarget	proc	near
ForceRef	OpenWinTestForFocusAndTarget	; called in winDraw.asm files

	class	OLWinClass
	clr	ax			;if menu, do not show focus or target
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	done			;skip if is menu...

	;
	; assume standard window
	;
	mov	ax, ds:[bp].OLWI_focusExcl.FTVMC_flags
	ORNF	ax, ds:[bp].OLWI_targetExcl.FTVMC_flags
done:
	ret
OpenWinTestForFocusAndTarget	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinHeaderResetInvalid

DESCRIPTION:	This procedure is called to reset one or more of the header
		area INVALID flags. We generally so this as we draw that item.

PASS:		*ds:si	= instance data for object
		cl	= OpenWinHeaderFlags to set valid

RETURN:		nothing

DESTROYED:	cl ONLY

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinHeaderResetInvalid	proc	near
	class	OLWinClass
	push	di
	call	WinCommon_DerefVisSpec_DI
	not	cl
	ANDNF	ds:[di].OLWI_headerState, cl
	pop	di
	ret
OpenWinHeaderResetInvalid	endp



COMMENT @----------------------------------------------------------------------

METHOD:		MSG_OL_WIN_UPDATE_HEADER

DESCRIPTION:	This method is sent by OpenWinHeaderMarkInvalid when it
		changes the OLWI_headerState flags. By the time this method
		gets through the UI queue, all of the various state changing
		(and geometry adjusting) methods have finished, and we can
		redraw the appropriate sections of the header.

PASS:		ds:*si	- instance data for OLWinClass object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Eric	1/90		full rewrite

------------------------------------------------------------------------------@

OpenWinUpdateHeader	method dynamic	OLWinClass, MSG_OL_WIN_UPDATE_HEADER

	ANDNF	ds:[di].OLWI_headerState, not (mask OLWHS_UPDATE_PENDING)

	;we will need to redraw something - create a GState

	call	ViewCreateDrawGState	;di = gstate
	tst	di			;is the window realized yet?
	jz	exit			;as doug says, "ACK!"...

	clr	cx			;set font, etc in GState
	call	OpenWinInitGState	;returns al = color scheme

	push	di
	call	WinCommon_DerefVisSpec_DI
	mov	dl, ds:[di].OLWI_headerState
	pop	di

	;now see which invalid flags are set
	;IMPORTANT: ds:bp = specific instance data, di = GState,
	;al - color scheme.

	;if header color or focus state changed, draw everything

CUAS <	test	dl, mask OLWHS_HEADER_AREA_INVALID >

	jz	headerOK

CUAS <	call	OpenWinDrawHeaderTitleBackground			>
	call	OpenWinDrawHeaderTitle

if	(0)
	;since the header was just drawn, we must redraw the Express menu
	;button (if this is a GenPrimary)

	call	OpenWinDrawFieldIconsIfBaseWindow
endif

if _GCM
	;if this is a GCM window, redraw the Exit and Help icons.
	;(di = GState)

	push	di
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	pop	di
	jz	notGCM

	.warn	-private

	mov	ax, offset OLBWI_gcmLeftIcon
	call	OLBaseWinDrawGCMIcon
	mov	ax, offset OLBWI_gcmRightIcon
	call	OLBaseWinDrawGCMIcon

	.warn	@private

notGCM:
endif
	;
	; Clear invalid flags manually. (We don't want
	; OLMenuButtonClass to have to do this work.)
	;
	mov	cl, mask OLWHS_FIELD_ICON_IMAGES_INVALID
	call	OpenWinHeaderResetInvalid
	jmp	done

headerOK:
	;
	; we might want to test for the case where the title area is invalid
	; but the title image is still valid - can just redraw background
	; and bitblt image to new position.
	;
CUAS <	test	dl, mask OLWHS_TITLE_AREA_INVALID or \
					mask OLWHS_TITLE_IMAGE_INVALID or \
					mask OLWHS_FOCUS_AREA_INVALID >
	jz	done

	push	dx
	call	OpenWinDrawHeaderTitleBackground
	call	OpenWinDrawHeaderTitle
	pop	dx
done:
	call	GrDestroyState
exit:
	ret

OpenWinUpdateHeader	endp


COMMENT @----------------------------------------------------------------------

PROCEDURE:	OpenWinCalcWinHdrGeometry

DESCRIPTION:	This procedure is called when the window is created,
		moved, or resized. We determine which UI-specific icons
		should appear in the header, enable and position them,
		and set the size of the title area appropriately.

CALLED BY:	OpenWinUpdateGeometry

PASS:		*ds:si - instance data of OLWinClass object

RETURN:		*ds:si - same

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
	if (is a GenPrimary window) {
	    OLBaseWinPositionGCMHeaderIcons:
		if (OWFA_GCM_TITLED AND GCMF_LEFT_ICON) {
		    insert icon into left side of title area
		    OLBaseWinEnableAndPositionHeaderIcon:
			send MSG_VIS_SET_SIZE and MSG_VIS_POSITION_BRANCH to icon
			clear VOF_GEOMETRY_INVALID and VOF_GEO_UPDATE_PATH
				on the icon object.
		}
		repeat above step, for right side icon.
	}

	;now allow the specific UI to position its icons which
	;will sit in the header area, reducing the size of the title.
	;(CUAS: will also enable and disable menu items in the System menu)

	    CUAS: OpenWinPositionSysMenuIcons
		if (OWA_HAS_SYS_MENU) {
		    decide which icons (max, min, restore) are required, and
		    reduce size of title bar accordingly.
		}
		if (OLWI_sysMenu != null) {
		    for each required icon and menu button:
			call OpenWinEnableAndPosSysMenuIcon:
			    if (there is an icon) {
				clears VOF_GEOMETRY_INVALID and
				  VOF_GEO_UPDATE_PATH flags on object
			    }
			    if (is enabled) {
				if (there is an icon) {
				    send MSG_VIS_SET_SIZE and MSG_VIS_POSITION_BRANCH
				    set DRAWABLE and DETECTABLE flags (sets
					path flags upwards)
				    mark object as WINDOW_INVALID, so will get
					VisOpen, so will be REALIZED.
				}
				enable the corresponding menu item in menu
			    } else {
				if (there is an icon) {
				    reset DRAWABLE and DETECTABLE flags (sets
					path flags upwards)
				}
				disable corresponding menu item in menu
			    }
		}

	    OLS:  OpenWinAdjustTitleForHeaderMarks
		FILL THIS IN

	;OpenLook: enable and disable items in the Windows menu for this window.

	    OLS: OpenWinUpdateWindowMenuItems				>
		FILL THIS IN

	;and finally, if this is a GenPrimary window (OLBaseWin) which
	;has the focus, then position the "Workspace" and "Applications" icons
	;on the header area, further reducing the size of the title.

	if (is a GenPrimary window) {
	    ;UPDATE the Workspace and Application menu buttons: this is not the
	    ;procedure which initially places or removes them - here we are just
	    ;moving them in response to a window size change.

	    OLBaseWinPositionWorkspaceAndAppIcons
		if (have workspace menu button) {
		    insert icon into left side of title area
		    OLBaseWinEnableAndPositionHeaderIcon:
			send MSG_VIS_SET_SIZE and MSG_VIS_POSITION_BRANCH to icon
			clear VOF_GEOMETRY_INVALID and VOF_GEO_UPDATE_PATH
				on the icon object.
		}
		repeat above step, for the application menu button.
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version
	Eric	1/90		extended to all specific UIs
	JimG	4/94		Added Stylus stuff.

------------------------------------------------------------------------------@
OpenWinCalcWinHdrGeometry	proc	far
	class	OLWinClass

	;this prevents icons from flashing when we get GEOMETRY_UPDATE for
	;no apparant reason.

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or \
				     mask VOF_WINDOW_INVALID
if	 _ROUND_THICK_DIALOGS
	LONG	jz	done		;skip if not invalid...
else	;_ROUND_THICK_DIALOGS is FALSE
	jz	done			;skip if not invalid...
endif	;_ROUND_THICK_DIALOGS

	mov	bp, di			;pass ds:bp = VisSpec instance data
	call	OpenWinGetHeaderBounds	;get bounds or header area in window,
					;taking resize border into account

	;calculate default title area (depends upon specific UI)

if _CUA_STYLE	;---------------------------------------------------------------
	inc	ax				;move inside frame border
	dec	cx				;on left and right

endif		;---------------------------------------------------------------

	;save default title area size

	;If this should have round border, include that in the title
	;bar calculations

if THREE_DIMENSIONAL_BORDERS
	add	ax, THREE_D_BORDER_THICKNESS
	sub	cx, THREE_D_BORDER_THICKNESS
	add	dx, (THREE_D_BORDER_THICKNESS-1)
else
if	_ROUND_THICK_DIALOGS
	call	OpenWinShouldHaveRoundBorder
	pushf				; check again later
	jnc	notRoundBorder

	; Doing the mov to bp and the add/subs takes the same number of
	; cycles (16) as doing the add/subs directly, but 5 less bytes
	; (11 vs. 16).

	mov	bp, _ROUND_THICK_DIALOG_BORDER
	add	ax, bp
	add	bx, bp
	sub	cx, bp
	add	dx, bp
notRoundBorder:
endif	;_ROUND_THICK_DIALOGS
endif	;THREE_DIMENSIONAL_BORDERS

	mov	ds:[di].OLWI_titleBarBounds.R_left, ax
	mov	ds:[di].OLWI_titleBarBounds.R_top, bx
	mov	ds:[di].OLWI_titleBarBounds.R_right, cx
	mov	ds:[di].OLWI_titleBarBounds.R_bottom, dx

if	 _ROUND_THICK_DIALOGS
	; save the left and right title bar bounds for later
	push	ax, cx
endif	; _ROUND_THICK_DIALOGS

10$:	;now allow the specific UI to position its icons which
	;will sit in the header area, reducing the size of the title.
	;(CUAS: will also enable and disable menu items in the System menu)

CUAS <	call	OpenWinPositionSysMenuIcons	;see Motif/Win/winClassSpec >

if	 _ROUND_THICK_DIALOGS or (not _OL_STYLE)
	call	WinCommon_DerefVisSpec_DI
endif	;_ROUND_THICK_DIALOGS or (not _OL_STYLE)

if	 _ROUND_THICK_DIALOGS
	; Here we compare the left and right bounds before any system icons
	; or title bar groups were added to the bounds afterwords.  This
	; comparison can tell us whether or not the corners have to be drawn
	; rounded or rectangular.  We then set vardata to indicate this state.

	pop	bx, cx			; restore original left, right bounds

	popf				; do we even have rounded window?
	jnc	doneWithRoundedCorner	; nope! outta' here.

	; Quick check to see if this window *really* has a title bar.  If
	; not, no point in adding the VarData.
	test	ds:[di].OLWI_attrs, mask OWA_HEADER or mask OWA_TITLED
	jz	doneWithRoundedCorner

	clr	dx
	cmp	ds:[di].OLWI_titleBarBounds.R_left, bx
	jne	testRightBoundary
	; left side didn't moved.. should be rounded
	ornf	dl, mask OLWTBCA_LEFT_CORNER_ROUNDED

testRightBoundary:
	cmp	ds:[di].OLWI_titleBarBounds.R_right, cx
	jne	setRoundVarData
	; right side didn't moved.. should be rounded
	ornf	dl, mask OLWTBCA_RIGHT_CORNER_ROUNDED

setRoundVarData:
	tst	dl
	jz	removeOldVarData

	mov	ax, ATTR_TITLE_BAR_HAS_ROUNDED_CORNERS
	mov	cx, size OLWinTitleBarCornerAttributes
	call	ObjVarAddData
	mov	ds:[bx], dl
	jmp	short doneWithRoundedCorner

removeOldVarData:
	; clean up old
	mov	ax, ATTR_TITLE_BAR_HAS_ROUNDED_CORNERS
	call	ObjVarDeleteData

doneWithRoundedCorner:
endif	;_ROUND_THICK_DIALOGS

if PLACE_EXPRESS_MENU_ON_PRIMARY
	;and finally, if this is a GenPrimary window (OLBaseWin) which
	;has the focus, then position the "Workspace" and "Applications" icons
	;on the header area, further reducing the size of the title.

CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
	jne	done

	;UPDATE the express tool area location, to match any window change.
	call	OLBaseWinAdjustTitleBoundsForExpressToolArea

endif ; PLACE_EXPRESS_MENU_ON_PRIMARY

done:
	ret
OpenWinCalcWinHdrGeometry	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinVupQuery -- MSG_VIS_VUP_QUERY for OLWinClass

DESCRIPTION:	Handle various VUP query

PASS:
	*ds:si - instance data
	es - segment of OLWinClass
	ds:di	= VisSpec instance data

	ax - The method

	cx - VupQueryTypes
	dx - ?
	bp - ?

RETURN:
		for VUQ_DISPLAY_SCHEME:
			Pull out display scheme from GenApp object,
			unless this object isn't owned by an application
			(must be the UI process), in which case we
			query our visible parent for the display scheme
			to use.

		otherwise:
			call superclass

some new stuff:
	if (query = SVQT_SET_MASTER_DEFAULT ) {
		if masterDefault != 0:0 then ERROR- too many masters!
		set masterDefaultOD = cx:dx
		if defaultExclusive = 0:0, then
			grab default for cx:dx. (gets a GAINED method)

	} elif (query = SVQT_RESET_DEFAULT ) {
		if masterDefault = cx:dx, then
			masterDefaultOD = 0:0.
			if defaultExclusive = cx:dx, then
				release default exclusive (gets a LOST method)

	} elif (query = SVQT_TAKE_DEFAULT_EXCLUSIVE ) {
		if defaultExclusive != cx:dx, then
			if defaultExclusive != 0:0, then
				release defaultExclusive (gets a LOST method)
			set defaultExclusive = cx:dx (gets a GAINED method)

	} elif (query = SVQT_RELEASE_DEFAULT_EXCLUSIVE ) {
		if defaultExclusive = cx:dx, then
			set defaultExclusive = 0:0 (gets a LOST method)
			if masterDefaultOD != 0:0 then
				grab default for masterDefault (gets GAINED)

	} elif (query = SVQT_QUERY_FOR_REPLY_BAR ) {
		return carry clear, for reply bars only happen BELOW windows.

	} else {
		send query to superclass (will send to generic parent)
	}

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


OpenWinVupQuery	method dynamic	OLWinClass, MSG_VIS_VUP_QUERY
	;set up some registers in case we can handle this query
	;(IMPORTANT: ds:di = vis/specific instance data)

;------------------------------------------------------------------------------

	cmp	cx, VUQ_DISPLAY_SCHEME
	jne	10$

displayScheme:
	ForceRef displayScheme
	call	SpecGetDisplayScheme	; Pull display scheme out of
					; application object
	mov	bp, dx			; Move into standard method return
	mov	dx, cx			; registers
	mov	cx, bx
	stc				; & return the query acknowledged.
	ret

;------------------------------------------------------------------------------
10$:
	cmp	cx, SVQT_SET_MASTER_DEFAULT
	jne	16$

setMasterDefault:
	ForceRef setMasterDefault

	mov	cx, bp			;set ^lcx:dx = OD of GenTrigger

	;make sure that we don't already have a master default

if ERROR_CHECK
	mov	ax, ds:[di].OLWI_masterDefault.handle
	or	ax, ds:[di].OLWI_masterDefault.chunk
	jz	145$			;skip if no master default already...

	cmp	ds:[di].OLWI_masterDefault.handle, cx
	jne	144$			;skip if error...
	cmp	ds:[di].OLWI_masterDefault.chunk, dx
144$:
	ERROR_NE OL_WINDOW_CANNOT_HAVE_MORE_THAN_ONE_DEFAULT_TRIGGER

145$:
endif

	mov	ds:[di].OLWI_masterDefault.handle, cx	;set new master OD
	mov	ds:[di].OLWI_masterDefault.chunk, dx

	;if nobody has the default exclusive, let the master have it

	mov	ax, MSG_META_GAINED_DEFAULT_EXCL
	mov	bx, offset Vis_offset		; pass master part
	mov	di, offset OLWI_defaultExcl	; & offset to BasicGrab
	call	FlowRequestGrab
	stc
	ret

;------------------------------------------------------------------------------
16$:	cmp	cx, SVQT_RESET_MASTER_DEFAULT
	jne	18$

resetMasterDefault:
	ForceRef resetMasterDefault

	mov	cx, bp			;set ^lcx:dx = OD of GenTrigger

	;see if this GenTrigger has the master default

	cmp	ds:[di].OLWI_masterDefault.handle, cx	;set new master OD
	jne	165$
	cmp	ds:[di].OLWI_masterDefault.chunk, dx
	jne	165$

	;set master default OD = NULL

	clr	ds:[di].OLWI_masterDefault.handle
	clr	ds:[di].OLWI_masterDefault.chunk

	;if this GenTrigger had the default exclusive, release it now
	;call FlowReleaseGrab and re-assert that root node has exclusive.

	call	OpenWinReleaseDefaultGrabAndFixFlag

165$:
	stc
	ret

;------------------------------------------------------------------------------
18$:	cmp	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE	;can we answer this query?
	jne	20$

takeDefaultExclusive:
	ForceRef takeDefaultExclusive

	test	ds:[di].OLWI_fixedAttr, mask OWFA_PREVENT_DEFAULT_OVERRIDES
	jnz	185$

	mov	cx, bp			;set ^lcx:dx = OD of GenTrigger
	mov	bp, FALSE		;pass flag which will be sent
					;to trigger: no need to redraw,
					;since you probably requested this
					;exclusive and will redraw yourself.
	mov	ax, MSG_META_GAINED_DEFAULT_EXCL
	mov	bx, offset Vis_offset		; pass master part
	mov	di, offset OLWI_defaultExcl	; & offset to BasicGrab
	call	FlowForceGrab		;grab default exclusive for this trigger
185$:
	stc
	ret

;------------------------------------------------------------------------------
20$:	cmp	cx, SVQT_REQUEST_DEFAULT_EXCLUSIVE ;can we answer this query?
	jne	22$

requestDefaultExclusive:
	ForceRef requestDefaultExclusive

	test	ds:[di].OLWI_fixedAttr, mask OWFA_PREVENT_DEFAULT_OVERRIDES
	jnz	205$

	mov	cx, bp			;set ^lcx:dx = OD of GenTrigger
	mov	bp, TRUE		;pass flag which will be sent
					;to trigger: you must redraw,
					;since you probably did not request
					;this exclusive.

	mov	ax, MSG_META_GAINED_DEFAULT_EXCL
	mov	bx, offset Vis_offset		; pass master part
	mov	di, offset OLWI_defaultExcl	; & offset to BasicGrab
	call	FlowRequestGrab		;grab default exclusive for this trigger
205$:
	stc
	ret

;------------------------------------------------------------------------------
22$:	cmp	cx, SVQT_RELEASE_DEFAULT_EXCLUSIVE ;can we answer this query?
	jne	23$

releaseDefaultExclusive:
	ForceRef releaseDefaultExclusive

	mov	cx, bp			;set ^lcx:dx = OD of GenTrigger

releaseDefaultExclusiveCXDX:
	;call FlowReleaseGrab and re-assert that root node has exclusive.
	;	^lcx:dx = OD of object releasing default exclusive

	test	ds:[di].OLWI_fixedAttr, mask OWFA_PREVENT_DEFAULT_OVERRIDES
	jnz	225$

	call	OpenWinReleaseDefaultGrabAndFixFlag

	;if there is a master default trigger, give it the default exclusive now

	;skip this is we still have a defaultExcl (i.e. non-default tried to
	;release defaultExcl)
	cmp	ds:[di].OLWI_defaultExcl.HG_OD.handle, 0
	jne	225$

	mov	bp, ds:[di].OLWI_masterDefault.handle
;Can't do this as it breaks tabbing away from a default trigger to a
;non-defaultable trigger; the default trigger won't take back the default.
;It is sufficient that OLButtonVisUnbuildBranch releases the default
;exclusive after releasing the master default to fix problems where the
;default exclusive field is left after the default object is destroyed
; -- brianc 7/8/95
;	cmp	bp, cx
;	jne	setMaster
;	cmp	dx, ds:[di].OLWI_masterDefault.chunk
;	je	225$			;don't give default back to releaser
;setMaster:
	mov	dx, ds:[di].OLWI_masterDefault.chunk
	mov	bx, bp
	or	bx, dx
	jz	225$

	;send a REQUEST_DEFAULT_EXCL method to self on the queue, so that
	;if any other button in the window gets the FOCUS exclusive first,
	;and requests the default exclusive, it will get the excl, and keep it.
	;Otherwise, this method will arrive on the queue, and the master;
	;default will be given the exclusive.

	mov	bx, ds:[LMBH_handle]	;pass ^lbx:si = this object
	mov	cx, SVQT_REQUEST_DEFAULT_EXCLUSIVE
	mov	ax, MSG_VIS_VUP_QUERY
	call	WinCommon_ObjMessageForceQueue

225$:
	stc
	ret

;------------------------------------------------------------------------------
23$:
	cmp	cx, SVQT_FORCE_RELEASE_DEFAULT_EXCLUSIVE
	jne	24$

forceReleaseDefaultExclusive:
	ForceRef forceReleaseDefaultExclusive

	;Forcibly release the current owner of the DEFAULT exclusive,
	;if it is not on the MASTER default item. This is used when a dialog
	;box is dismissed, to restore the DEFAULT exclusive to the
	;MASTER default item.

	mov	cx, ds:[di].OLWI_defaultExcl.HG_OD.handle
	mov	dx, ds:[di].OLWI_defaultExcl.HG_OD.chunk

	cmp	cx, ds:[di].OLWI_masterDefault.handle
	jne	releaseDefaultExclusiveCXDX

	cmp	dx, ds:[di].OLWI_masterDefault.chunk
	jne	releaseDefaultExclusiveCXDX

	stc
	ret

;------------------------------------------------------------------------------
24$:	cmp	cx, SVQT_HAS_MENU_IN_STAY_UP_MODE
	jne	26$

hasMenuInStayUpMode:
	ForceRef hasMenuInStayUpMode

	;set a flag so that OpenWinEndGrab does not force the release of the
	;GADGET exclusive as the user releases the mouse on this window.

	ORNF	ds:[di].OLWI_menuState, mask OLWMS_HAS_MENU_IN_STAY_UP_MODE
	stc
	ret

;------------------------------------------------------------------------------
26$:	cmp	cx, SVQT_NO_MENU_IN_STAY_UP_MODE
	jne	28$

noMenuInStayUpMode:
	ForceRef noMenuInStayUpMode

	;reset a flag so that OpenWinEndGrab can once again force the release
	;of the GADGET exclusive as the user releases the mouse on this window.

	ANDNF	ds:[di].OLWI_menuState, not mask OLWMS_HAS_MENU_IN_STAY_UP_MODE
	stc
	ret

;------------------------------------------------------------------------------
28$:	cmp	cx, SVQT_REMOTE_GRAB_GADGET_EXCL
	je	remoteGrabGadgetExcl

	cmp	cx, SVQT_NOTIFY_MENU_BUTTON_AND_REMOTE_GRAB_GADGET_EXCL
	jne	30$

remoteGrabGadgetExcl:
	;a menu is requesting the GADGET exclusive, even though it is
	;not a visible child.

	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	jmp	selfSelfAndExitWithCarrySet

;------------------------------------------------------------------------------
30$:	cmp	cx, SVQT_REMOTE_RELEASE_GADGET_EXCL
	jne	32$

remoteReleaseGadgetExcl:
	ForceRef remoteReleaseGadgetExcl

	;a menu is requesting a release of the GADGET exclusive

	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL

selfSelfAndExitWithCarrySet:
	mov	cx, bp			;pass ^lcx:dx = requesting menu obj.
	call	WinCommon_ObjCallInstanceNoLock
	stc
	ret

;------------------------------------------------------------------------------
32$:	cmp	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	jne	34$

queryWinGroupForFocusExcl:
	ForceRef queryWinGroupForFocusExcl

	;This query is sent by a GenItemGroup which is inside this window
	;when it needs to know if it will get the FOCUS exclusive when
	;it requests it. It uses this info to optimize its redraws.
	;Also, gadgets use this query to find out which object has the focus,
	;to see if the gadget is permitted to grab the focus as the user
	;presses the mouse on that gadget.
	;
	;IF THIS ROUTINE MUST ERR, LEAN TOWARDS "FALSE". This will
	;cause excessive drawing in gadgets, which is better than no drawing!

	clr	bp			;assume FALSE
	call	WinCommon_Deref_Load_FocusExcl_CXDX
	mov	ax, ds:[di].OLWI_focusExcl.FTVMC_flags
	test	ax, mask HGF_APP_EXCL
	jz	325$			;skip if not...

	mov	bp, TRUE

325$:
	stc
	ret

;------------------------------------------------------------------------------
34$:	cmp	cx, SVQT_GRAB_FOCUS_EXCL_FOR_MENU
	jne	36$

grabFocusWinExclForMenu:
	ForceRef grabFocusWinExclForMenu

	;This query is sent when the user drags off of a menu button inside
	;this menu window. Since we expect the sub-menu to close, we
	;want to grab the focus quickly, so that it is not restored to the
	;previous focus owner (some gadget inside the Primary)

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	345$			;skip if is not a menu...

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
345$:
	stc
	ret

;------------------------------------------------------------------------------
36$:
	cmp	cx, SVQT_QUERY_FOR_REPLY_BAR
	jne	callSuper
	clc				; end fruitless search right here, to
					; keep it from going all the way
					; through the system object
	ret
;------------------------------------------------------------------------------

callSuper:
	GOTO	WinCommon_ObjCallSuperNoLock_OLWinClass_Far
OpenWinVupQuery	endm

;--------------

OpenWinReleaseDefaultGrabAndFixFlag	proc	near
	class	OLWinClass

	mov	ax, MSG_META_GAINED_DEFAULT_EXCL
	mov	bx, offset Vis_offset		; pass master part
	mov	di, offset OLWI_defaultExcl	; & offset to BasicGrab
	call	FlowReleaseGrab

	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_defaultExcl.HG_flags, mask HGF_APP_EXCL
					;this is the root-level of the
					;default exclusive hierarchy, so
					;re-assert that this node is
					;permanently enabled.
	;MUST return valid ds:di
	ret
OpenWinReleaseDefaultGrabAndFixFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinOpenWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform MSG_VIS_OPEN_WIN given an OLWinPart

CALLED BY:	INTERNAL

PASS:		*ds:si = object

RETURN:		bp = parent window to open window on

DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Chris	4/19/91		Updated for new graphics, bounds conventions
	Doug	3/92		Broke into a few separate pieces
	JimG	4/94		Added hooks for Stylus' rounded dialogs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinOpenWin	method	dynamic	OLWinClass, MSG_VIS_OPEN_WIN
regionBlock	local	hptr
colorAX		local	word
colorBX		local	word
passFlags	local	WinPassFlags
layerID		local	hptr
parent		local	hptr
FXIP <unlockBlock	local	word					>
	;
	; If unlockBlock != 0, then we need to unlock the block containing
	; the window regions.
	;
	mov	ax, bp			; keep default parent win
	.enter

	push	bp
	mov	parent, ax
FXIP <	clr	unlockBlock						>

EC <	cmp	ds:[di].VCI_window, 0	; already have a window?	>
EC <	ERROR_NZ	OPEN_WIN_ON_OPEN_WINDOW				>

	; first check for general window positioning preferences
	; (most can be handled at SPEC_BUILD, but some have to be handled
	; here, because now we have size information.)

	; if the visible bounds for this object are actually
	; ratios of the Parent/Field window, convert to pixel coordinates
	; now. (Note: if parent geometry is not yet valid, this does nothing)

	push	bp			; save locals
	call	ConvertSpecWinSizePairsToPixels
	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until MSG_VIS_MOVE_RESIZE_WIN to
					;do this.

	;
	; New code to make one last gasp to move the window onscreen, if needed.
	; Some of the positioning may not have been done until now.
	; -cbh 1/21/93
	;
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_winPosSizeFlags, \
			mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
	jz	dontMove

	;
	; Don't force onscreen if the user has moved it...
	;

	test	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	jnz	dontMove

	push	bx
	call	OpenGetParentWinSize

	;
	; if TOOL_AREA_IS_TASK_BAR
	;
	; push	ds
	; segmov	ds, dgroup
	; tst	ds:[taskBarEnabled] ; if taskbar == on, ZF == 1
	; pop	ds
	; jz	hasNoTaskbar ; if ZF==0 skip the following code

	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.
	; call	GetTaskBarSizeAdjustment
	; sub	dx, di			; subtract off taskbar adjustment

hasNoTaskbar:
	movdw	axbp, cxdx		 ;put size values in weird places
	call	MoveWindowToKeepOnscreen ;try to move the window onscreen
	pop	bx

dontMove:

EC <	test	bx, mask WPSS_POSITION_INVALID or mask WPSS_SIZE_INVALID >
EC <	ERROR_NZ OL_WIN_POSITION_OR_SIZE_INVALID_AFTER_UPDATE		 >

	;
	; check for window visibility preferences
	;
	call	OpenWinCheckVisibleConstraints
	pop	bp			; restore local vars


	call	GetWinColor		; Get color & WinColorFlags
	mov	colorAX, ax		; store away until ready to use
	mov	colorBX, bx

	mov	di, parent		; get default parent win
	call	GetCoreWinOpenParams
	mov	passFlags, cx
	mov	layerID, dx
	mov	parent, di

	push	si			; save object until after WinOpen
	push	bp			; save stack frame too

	;
	; We start setting up actual WinOpen regs & on-stack data here
	;

	push	layerID			; Push layer ID to use (owner of win)

	call	GeodeGetProcessHandle	; Get owner for this window
	push	bx			; Push owner

	push	parent			; Push parent window handle
getRegion::
	;
	;  Following are code sections from approximately umpteen
	;  different UIs, all of which somehow get a pointer to the
	;  window region to use for WinOpen.  Some of them create
	;  the region on the fly; others simply set up pointers to
	;  predefined regions.  Add your region code here.
	;
if BUBBLE_DIALOGS	;oooooooooooooooooooooooooooooooooooooooooooooooooooooo
	call	OpenWinCreateWindowRegion
	mov	regionBlock, bx
	tst	bx
	jz	9$

	andnf	passFlags, not mask WPF_SAVE_UNDER

	call	MemLock
	push	ax
	mov	ax, size Rectangle
	jmp	20$
9$:
endif	; BUBBLE_DIALOGS oooooooooooooooooooooooooooooooooooooooooooooooooooooo

if	DIALOGS_WITH_FOLDER_TABS
	call	OpenWinCreateTabbedWindowRegion
	mov	regionBlock, bx
	tst	bx
	jz	9$

	push	dx			; push segment of region
	jmp	20$
9$:
endif	; DIALOGS_WITH_FOLDER_TABS

if	DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenCheckIfBW		; doing color, branch
	jnc	10$

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	10$			; custom window, branch
endif	; DRAW_SHADOWS_ON_BW_GADGETS

if _ROUND_THICK_DIALOGS
	call	OpenWinShouldHaveRoundBorder
	jnc	10$
endif ; _ROUND_THICK_DIALOGS

if DRAW_SHADOWS_ON_BW_GADGETS or _ROUND_THICK_DIALOGS	;----------------------
NOFXIP<	mov	ax, cs						>

FXIP <	push	bx						>
FXIP <	mov	bx, handle RegionResourceXIP			>
FXIP <	call	MemLock			; ax = segment		>
FXIP <	pop	bx						>
FXIP <	inc	unlockBlock					>

	push	ax
	mov	ax, offset windowRegionBW

	jmp	short 20$
endif	; DRAW_SHADOWS_ON_BW_GADGETS or _ROUND_THICK_DIALOGS ------------------

10$:
	clr	ax			; default: use rectangular region
	push	ax			; push segment of region
20$:
	push	ax			; push offset of region
	;
	; Pass visible bounds of window
	;
	clr	cl			; normal bounds
	call	OpenGetLineBounds	; pass bounds, as screen coords

EC <	push	cx, dx							>
EC <	sub	cx, ax							>
EC <	inc	cx			; get size			>
EC <	sub	dx, bx							>
EC <	inc	dx							>
EC <	test	cx, mask RSA_CHOOSE_OWN_SIZE				>
EC <	ERROR_NZ	OL_OPEN_WIN_BAD_VIS_BOUNDS			>
EC <	test	dx, mask RSA_CHOOSE_OWN_SIZE				>
EC <	ERROR_NZ	OL_OPEN_WIN_BAD_VIS_BOUNDS			>
EC <	pop	cx, dx							>

	push	dx, cx, bx, ax		; pass region parameters on stack

	;
	;  Open the Window now.  Really.
	;
openNow::
	mov	ax, colorAX		; get color setup
	mov	bx, colorBX
	call	WinCommon_Mov_CXDX_Self	; this obj is inputOD
	mov	si, passFlags
	mov	di, cx			; & exposureOD
	mov	bp, dx
	call	WinOpen

	pop	bp			; restore stack frame

	;
	;  Here's where all the people who created regions get to
	;  free up the region blocks.  Joy.
	;

if	DRAW_SHADOWS_ON_BW_GADGETS or _ROUND_THICK_DIALOGS
FXIP <	tst	unlockBlock						>
FXIP <	jz	noUnlock						>
FXIP <	push	bx							>
FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
FXIP <noUnlock:								>
endif

if BUBBLE_DIALOGS ;oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
	;
	; Free up created region, if any, for a bubble dialog.
	;
	push	bx
	mov	bx, regionBlock
	tst	bx
	jz	30$
	call	MemFree
30$:
	pop	bx
endif	; BUBBLE_DIALOGS oooooooooooooooooooooooooooooooooooooooooooooooooooooo

if DIALOGS_WITH_FOLDER_TABS
	push	bx
	mov	bx, regionBlock
	tst	bx
	jz	30$
	call	MemFree
30$:
	pop	bx
endif	; DIALOGS_WITH_FOLDER_TABS

	pop	si			; get back chunk handle of obj.

	call	WinCommon_DerefVisSpec_DI
	mov	ds:[di].VCI_window, bx	; store window handle

	;
	; Now add the OD of this object to the window list
	; This will allow the window to be notified when the system is
	; shutting down, so that it can save position and size info, etc.
	; NOTE: see OpenWinDetach for how we store extra data on the active
	; list.
	;
	call	OpenWinEnsureOnWindowList
					; FINALLY, if new window was opened
					; in front of other windows within
					; the application, bring its active
					; list entry to the front, so that
					; we have a generic reminder of
					; that fact.
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_OPEN_ON_TOP
	jz	afterTopTest
					; Clear "ON_TOP" bit afterwards, as
					; it only has a one-time affect
	and	ds:[di].OLWI_fixedAttr, not (mask OWFA_OPEN_ON_TOP)
					; Raise the active list entry to
					; the top, to reflect position at
					; top of window layer.
	mov	ax, MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GenCallApplication

afterTopTest:

	pop	bp
	.leave
	ret
OpenWinOpenWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinUpdateForTitleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update for title group change

CALLED BY:	MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		ds:bx	= OLWinClass object (same as *ds:si)
		es 	= segment of OLWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Wouldn't it be cool to be able to update for the title
		group changes without invalidating the entire header?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinUpdateForTitleGroup	method dynamic OLWinClass,
					MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
	.enter

	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	.leave
	ret
OLWinUpdateForTitleGroup	endm

WinCommon	ends
