COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinClassCommonHigh.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS
				Scans geometry hints.  The default handler
				for OLWinClass. This handler does NOT
				actually scan for geometry hints; it is
				assumed that any window that does not
				subclass this message doesn't actually want
				to handle hints.

 ?? INT OpenWinProcessHints	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintDismissWhenDisabled	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintPreventDefaultOverrides
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintPreserveFocus	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintDoNotPreserveFocus	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintNoTallerThanChildrenRequire
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintNoWiderThanChildrenRequire
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintGeneralConsumerMode	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintUseInitialBoundsWhenRestored
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowShouldFitInParent
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowNeedntFitInParent
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintKeepPartiallyVisible
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintKeepEntirelyVisibleWithMargin
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintKeepEntirelyVisible	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowNoConstraints	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintPositionWindowAtRatio
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintStaggerWindow	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintCenterWindow	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintTileWindow		This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintPositionWindowAtMouse
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintExtendWindowToBottomRight
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintSizeWindowAsDesired	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintSizeWindowAsRatioOfParent
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintSizeWindowAsRatioOfField
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintExtendWindowNearBottomRight
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintNotMovable		This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintCustomWindow	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowNoTitleBar	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowNoSysMenu	This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT HintWindowMinimizeTitleBar
				This is a general hint-checker for
				OLWinClass objects. We would normally
				handle this directly in the
				MSG_META_INITIALIZE handler for OLWinClass,
				but we want the subclass's handler to have
				a chance to assert some object-specific
				defaults BEFORE we scan hints. So we call
				this routine from those handlers.

 ?? INT SetWinPosSizeAttrFromRegs
				Sets win pos size stuff from registers.

 ?? INT EnsureRightBottomBoundsAreIndependent
				Sets win pos size stuff from registers.

 ?? INT EnsureBoundsAreDependent
				Sets win pos size stuff from registers.

 ?? INT AvoidCenteringIfExtending
				Can't center a window that extends, so
				restore position.

    MTD MSG_SPEC_BUILD_BRANCH	We get this method when the UI is
				recursively SPEC_BUILDing the objects in
				the generic tree. We allow superclass to
				send on to self and to kids, and then we
				create our system menu and menu icons if
				necessary. We then send SPEC_BUILD on to
				these objects, since they are not
				generically connected to anything.

 ?? INT OpenWinEnsureHeaderGCMIcons
				This procedure creates the System icons
				which appear in the window header area.

    MTD MSG_SPEC_GUP_QUERY_VIS_PARENT
				This handles the SGQT_BRING_UP_KEYBOARD
				GupQuery by setting the appropriate flag on
				the object, so when it gets the focus, it
				will bring up the keyboard.

    MTD MSG_SPEC_BUILD		Build out this base window visually,
				attaching it onto some background window in
				the system.  NOTE that this routine can
				only handle the case of doing a WIN_GROUP
				spec build for this window.  This routine
				should be replaced for the non-WIN_GROUP
				cases.

 ?? INT LegosSetWindowLookFromHints
				The legos look is stored in instance data,
				so when we unbuild and rebuild we need to
				set it from the hints.

 ?? INT UpdateWinPosSize	This procedure updates this windowed
				Object's position and size in relation to
				its parent window, given the current state,
				specific UI defaults for this object type,
				and application hints concerning
				positioning/resizing.

 ?? INT UpdateWinPosition	Maybe move Window

 ?? INT UpdateWinSize		Maybe size Window

 ?? INT OpenWinSwapState	save current position, size, and state
				information in instance data

 ?? INT SwapInstanceWords	save current position, size, and state
				information in instance data

 ?? INT GetParentWinSize	This procedure sends a visual upward query
				to find the Parent window size, as
				specified by the WinPosSizeFlags record in
				ax.

    MTD MSG_SPEC_GET_VIS_PARENT	Returns visual parent for this generic
				object

 ?? INT OpenWinSetVisParent	This procedure handles the "visibly attach
				to parent" phase of the standard OLWinClass
				SPEC_BUILD method handler.

 ?? INT ConvertSpecWinSizePairsToPixels
				If this windowed object was just ATTACHED,
				then their might be position and size info
				(as % of parent) that was recovered and
				placed in this object's VI_bounds. If so,
				convert to actual pixel values now. See
				OpenWinSpecBuild - this info might not be
				needed.

    MTD MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP
				Get the title-bar group, creating if
				necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinClass.asm

DESCRIPTION:

	$Id: cwinClassCommonHigh.asm,v 1.5 98/07/10 11:06:00 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize an open look base window

PASS:		*ds:si - instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinInitialize	method private static OLWinClass, \
						MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

					;call super (OLCtrlClass) for init
	call	OLCtrlInitialize	;make a direct call, for speed

	;Initialize visible characteristics

	call	WinCommon_DerefGen_DI
	mov	bx, di
	call	WinCommon_DerefVisSpec_DI

	; Set OWA_TARGETABLE based on generic attribute
	;
	test	ds:[bx].GI_attrs, mask GA_TARGETABLE
	jz	afterTargetable
	ORNF	ds:[di].OLWI_attrs, mask OWA_TARGETABLE
afterTargetable:

					;Mark this object as being a win group
					;Mark as being a win group & a window
					;& uses a different visible parent
					;than its generic parent.  Also mark
					;so that the children look for a custom
					;vis parent.
	ORNF	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP or \
				      mask VTF_IS_WINDOW
	ORNF	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT or \
				      mask SA_CUSTOM_VIS_PARENT_FOR_CHILD

	mov	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE \
				     or mask OWFA_PRESERVE_FOCUS

	;Initialize some HierarchicalGrab structures which are used by the
	;UserFlow utility routines to implement the FOCUS, TARGET, and DEFAULT
	;exclusives below this level in the hierarchy. Note: the focus and
	;target exclusives at this level are dual grabs, meaning either a
	;windowed objects (GenDisplay or menu) or a non-windowed object
	;(like a GenText) can have the exclusive. Therefore we don't set
	;the GAIN&LOSS methods here - we do it in OpenWinGrabFWExcl, etc.

	mov	ds:[di].OLWI_defaultExcl.HG_flags, mask HGF_APP_EXCL
					;this is the root-level of the
					;default exclusive hierarchy, so
					;set this node permanently enabled.

	clr	ax
	clrdw	ds:[di].OLWI_titleBarLeftGroup, ax
	clrdw	ds:[di].OLWI_titleBarRightGroup, ax

	.leave
	ret
OpenWinInitialize	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLWinScanGeometryHints --
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLWinClass

DESCRIPTION:	Scans geometry hints.  The default handler for OLWinClass.
		This handler does NOT actually scan for geometry hints; it
		is assumed that any window that does not subclass this message
		doesn't actually want to handle hints.

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

OLWinScanGeometryHints	method static OLWinClass, MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLWinClass
	mov	es, di

	;get superclass geometry stuff done.

	mov	di, offset OLWinClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;Make sure minimum size method is called.

	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE

	;set specific-UI dependent position/resizing behavior flags -
	;may be altered by subclassed objects. Then scan our hints
	;to check for application-requested behavior

	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID
					;let's party

	; Ignore any moniker hints that may have been used.  These don't
	; apply to windows and would get handled when a window calls its
	; superclass.   Also ignore any desired size hints.

	ANDNF	ds:[di].OLCI_optFlags, not (mask OLCOF_DISPLAY_MONIKER or \
		    mask OLCOF_DISPLAY_MKR_ABOVE or \
		    mask OLCOF_DISPLAY_BORDER)
	ORNF	ds:[di].OLCI_optFlags,  mask OLCOF_IGNORE_DESIRED_SIZE_HINTS

	.leave
	ret

OLWinScanGeometryHints	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinProcessHints

DESCRIPTION:	This is a general hint-checker for OLWinClass objects.
		We would normally handle this directly in the
		MSG_META_INITIALIZE handler for OLWinClass, but we want
		the subclass's handler to have a chance to assert some
		object-specific defaults BEFORE we scan hints. So we call
		this routine from those handlers.

CALLED BY:	OLPopupWinInitialize, OLBaseWinInitialize, OLMenuWinInitialize

PASS:		ds:*si	- instance data
		cx	- 0 if this class does NOT support a window icon
			(OLDisplayWinClass and OLBaseWinClass pass cx = TRUE)

RETURN:		ds, si = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

OpenWinProcessHints	proc	far

	;Make any resizeable window expand-to-fit, so that they can be resized
	;without regard to the contents of the windows (and also so they will
	;hold their size.)   This is done here so gadget areas can copy the
	;correct attributes when they're built, but I may change them to
	;always be expand to fit anyway.  -cbh 6/12/92 (Used to only set these
	;for non-menu menued wins)  (Changed 6/17/92 to make *any* non-menu
	;expand-to-fit, even if not resizable.  Fixes problems with keyboard-
	;only windows.)  (Moved from UPDATE_SPEC_BUILD handler 3/12/93 cbh)

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	5$			;skip if is menu...
	ORNF	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
5$:

					;setup es:di to be ptr to
					;Hint handler table

	push	ds:[di].OLWI_winPosSizeFlags	;save old flags

	segmov	es, cs
	mov	di, offset cs:OpenWinHintHandlers
	mov	ax, length (cs:OpenWinHintHandlers)
	call	OpenScanVarData

	pop	cx
	call	AvoidCenteringIfExtending

	ret
OpenWinProcessHints	endp


if _GCM	;----------------------------------------------------------------------
OpenWinHintHandlers	VarDataHandler \
	< HINT_PREVENT_DEFAULT_OVERRIDES, \
			offset HintPreventDefaultOverrides >,
	< HINT_GENERAL_CONSUMER_MODE, \
			offset HintGeneralConsumerMode >,
	< HINT_PRESERVE_FOCUS, offset HintPreserveFocus >,
	< HINT_DO_NOT_PRESERVE_FOCUS, offset HintDoNotPreserveFocus >,
	< HINT_DISMISS_WHEN_DISABLED, offset HintDismissWhenDisabled>,
	< HINT_USE_INITIAL_BOUNDS_WHEN_RESTORED, \
			  offset HintUseInitialBoundsWhenRestored>,
	< HINT_KEEP_INITIALLY_ONSCREEN, \
			  offset HintWindowShouldFitInParent>,
	< HINT_DONT_KEEP_INITIALLY_ONSCREEN, \
			  offset HintWindowNeedntFitInParent>,
	< HINT_DONT_KEEP_PARTIALLY_ONSCREEN, \
			  offset HintWindowNoConstraints>,
	< HINT_KEEP_PARTIALLY_ONSCREEN, \
			  offset HintKeepPartiallyVisible>,
	< HINT_KEEP_ENTIRELY_ONSCREEN, \
			  offset HintKeepEntirelyVisible>,
	< HINT_WINDOW_NO_CONSTRAINTS, \
			  offset HintWindowNoConstraints>,
	< HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN, \
			  offset HintKeepEntirelyVisibleWithMargin>,
	< HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT, \
			  offset HintPositionWindowAtRatio>,
	< HINT_STAGGER_WINDOW, offset HintStaggerWindow>,
	< HINT_CENTER_WINDOW, offset HintCenterWindow>,
	< HINT_TILE_WINDOW, offset HintTileWindow>,
	< HINT_POSITION_WINDOW_AT_MOUSE, \
			  offset HintPositionWindowAtMouse>,
	< HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT, \
			  offset HintExtendWindowToBottomRight>,
	< HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT, \
			  offset HintExtendWindowNearBottomRight>,
	< HINT_SIZE_WINDOW_AS_DESIRED, \
			  offset HintSizeWindowAsDesired>,
	< HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT, \
			  offset HintSizeWindowAsRatioOfParent>,
	< HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD, \
			  offset HintSizeWindowAsRatioOfField>,
	< HINT_NOT_MOVABLE, offset HintNotMovable>,
	< ATTR_GEN_WINDOW_CUSTOM_WINDOW, \
			  offset HintCustomWindow>,
	< HINT_WINDOW_NO_TITLE_BAR, \
			  offset HintWindowNoTitleBar>,
	< HINT_WINDOW_NO_SYS_MENU, \
			  offset HintWindowNoSysMenu>,
	< HINT_NO_TALLER_THAN_CHILDREN_REQUIRE, \
			  offset HintNoTallerThanChildrenRequire>,
	< HINT_NO_WIDER_THAN_CHILDREN_REQUIRE, \
			  offset HintNoWiderThanChildrenRequire>,
        < HINT_WINDOW_MINIMIZE_TITLE_BAR, \
			  offset HintWindowMinimizeTitleBar>

else	; not _GCM ------------------------------------------------------------

OpenWinHintHandlers	VarDataHandler \
	< HINT_PREVENT_DEFAULT_OVERRIDES, \
			offset HintPreventDefaultOverrides >,
	< HINT_PRESERVE_FOCUS, offset HintPreserveFocus >,
	< HINT_DO_NOT_PRESERVE_FOCUS, offset HintDoNotPreserveFocus >,
	< HINT_DISMISS_WHEN_DISABLED, offset HintDismissWhenDisabled>,
	< HINT_USE_INITIAL_BOUNDS_WHEN_RESTORED, \
			  offset HintUseInitialBoundsWhenRestored>,
	< HINT_KEEP_INITIALLY_ONSCREEN, \
			  offset HintWindowShouldFitInParent>,
	< HINT_DONT_KEEP_INITIALLY_ONSCREEN, \
			  offset HintWindowNeedntFitInParent>,
	< HINT_DONT_KEEP_PARTIALLY_ONSCREEN, \
			  offset HintWindowNoConstraints>,
	< HINT_KEEP_PARTIALLY_ONSCREEN, \
			  offset HintKeepPartiallyVisible>,
	< HINT_KEEP_ENTIRELY_ONSCREEN, \
			  offset HintKeepEntirelyVisible>,
	< HINT_WINDOW_NO_CONSTRAINTS, \
			  offset HintWindowNoConstraints>,
	< HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN, \
			  offset HintKeepEntirelyVisibleWithMargin>,
	< HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT, \
			  offset HintPositionWindowAtRatio>,
	< HINT_STAGGER_WINDOW, offset HintStaggerWindow>,
	< HINT_CENTER_WINDOW, offset HintCenterWindow>,
	< HINT_TILE_WINDOW, offset HintTileWindow>,
	< HINT_POSITION_WINDOW_AT_MOUSE, \
			  offset HintPositionWindowAtMouse>,
	< HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT, \
			  offset HintExtendWindowToBottomRight>,
	< HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT, \
			  offset HintExtendWindowNearBottomRight>,
	< HINT_SIZE_WINDOW_AS_DESIRED, \
			  offset HintSizeWindowAsDesired>,
	< HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT, \
			  offset HintSizeWindowAsRatioOfParent>,
	< HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD, \
			  offset HintSizeWindowAsRatioOfField>,
	< HINT_NOT_MOVABLE, offset HintNotMovable>,
	< ATTR_GEN_WINDOW_CUSTOM_WINDOW, \
			  offset HintCustomWindow>,
	< HINT_WINDOW_NO_TITLE_BAR, \
			  offset HintWindowNoTitleBar>,
	< HINT_WINDOW_NO_SYS_MENU, \
			  offset HintWindowNoSysMenu>,
	< HINT_NO_TALLER_THAN_CHILDREN_REQUIRE, \
			  offset HintNoTallerThanChildrenRequire>,
	< HINT_NO_WIDER_THAN_CHILDREN_REQUIRE, \
			  offset HintNoWiderThanChildrenRequire>,
        < HINT_WINDOW_MINIMIZE_TITLE_BAR, \
			  offset HintWindowMinimizeTitleBar>

endif	; if _GCM -------------------------------------------------------------

;DO NOT TRASH CX IN THESE HANDLERS!

HintDismissWhenDisabled	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_attrs, mask OWA_DISMISS_WHEN_DISABLED
	ret
HintDismissWhenDisabled	endp

HintPreventDefaultOverrides	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_PREVENT_DEFAULT_OVERRIDES
	ret
HintPreventDefaultOverrides	endp

HintPreserveFocus	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_PRESERVE_FOCUS
	ret
HintPreserveFocus	endp

HintDoNotPreserveFocus	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_PRESERVE_FOCUS)
	ret
HintDoNotPreserveFocus	endp

HintNoTallerThanChildrenRequire	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	and	ds:[di].VCI_geoDimensionAttrs, \
				not mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	ret
HintNoTallerThanChildrenRequire	endp

HintNoWiderThanChildrenRequire	proc	far
	class	OLWinClass
	call	WinCommon_DerefVisSpec_DI
	and	ds:[di].VCI_geoDimensionAttrs, \
				not mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
	ret
HintNoWiderThanChildrenRequire	endp

	.assert	WPT_AT_RATIO eq 0
	.assert	WST_AS_RATIO_OF_PARENT eq 0
	.assert	offset WPSS_VIS_POS_IS_SPEC_PAIR lt 8
	.assert	offset WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT lt 8
	.assert	offset WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD lt 8

	.warn	-private

	.assert (offset OLWI_winPosSizeState)-(offset OLWI_winPosSizeFlags) eq 2

if not _NO_WIN_ICONS	;------------------------------------------------------
	.assert (offset OLMDWI_iconWinPosSizeState) \
		-(offset OLMDWI_iconWinPosSizeFlags) eq 2
	.assert (offset OLMDWI_iconPosLeft) \
		-(offset OLMDWI_iconWinPosSizeFlags) eq 4
	.assert (offset OLMDWI_iconPosTop) \
		-(offset OLMDWI_iconWinPosSizeFlags) eq 6
endif			; if not _NO_WIN_ICONS --------------------------------

	.warn	@private

;pass cx = 0 if this window does not support a window icon.



HintUseInitialBoundsWhenRestored	proc	far
	clr	cx				;bits to clear
	mov	dx, mask WPSF_PERSIST		;bits to set
	call	SetWinPosSizeAttrFromRegs
	ret
HintUseInitialBoundsWhenRestored	endp

HintWindowShouldFitInParent 	proc	far
	clr	cx			;bits to clear
	mov	dx, mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
	call	SetWinPosSizeAttrFromRegs
	ret
HintWindowShouldFitInParent 	endp

HintWindowNeedntFitInParent 	proc	far
	mov	cx, mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
	clr	dx				;bits to set
	call	SetWinPosSizeAttrFromRegs
	ret
HintWindowNeedntFitInParent 	endp

HintKeepPartiallyVisible	proc	far
	mov	cx, mask WPSF_CONSTRAIN_TYPE	;bits to clear
	mov	dx, WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintKeepPartiallyVisible	endp

HintKeepEntirelyVisibleWithMargin	proc	far
	mov	cx, mask WPSF_CONSTRAIN_TYPE	;bits to clear
	mov	dx, WCT_KEEP_VISIBLE_WITH_MARGIN shl offset WPSF_CONSTRAIN_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintKeepEntirelyVisibleWithMargin	endp

HintKeepEntirelyVisible	proc	far
	mov	cx, mask WPSF_CONSTRAIN_TYPE	;bits to clear
	mov	dx, WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintKeepEntirelyVisible endp

HintWindowNoConstraints	proc	far
	mov	cx, mask WPSF_CONSTRAIN_TYPE	;bits to clear
	clr	dx				;bits to set
	call	SetWinPosSizeAttrFromRegs
	ret
HintWindowNoConstraints	endp

HintPositionWindowAtRatio	proc	far
EC <	push	ax							  >
EC <	VarDataSizePtr	ds, bx, ax					  >
EC <	cmp	ax, size SpecWinSizePair				  >
EC <	ERROR_NE  OL_WIN_HINT_REQUIRES_SPEC_WIN_SIZE_PAIR_ARGUMENT	  >
EC <	pop	ax							  >

	mov	cx, mask WPSF_POSITION_TYPE
	mov	dx, WPT_AT_RATIO shl offset WPSF_POSITION_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintPositionWindowAtRatio	endp

HintStaggerWindow	proc	far
	mov	cx, mask WPSF_POSITION_TYPE
	mov	dx, WPT_STAGGER shl offset WPSF_POSITION_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintStaggerWindow	endp

HintCenterWindow	proc	far
	mov	cx, mask WPSF_POSITION_TYPE
	mov	dx, WPT_CENTER shl offset WPSF_POSITION_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintCenterWindow	endp

HintTileWindow	proc	far
	mov	cx, mask WPSF_POSITION_TYPE
	mov	dx, WPT_TILED shl offset WPSF_POSITION_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintTileWindow	endp

HintPositionWindowAtMouse	proc	far
	mov	cx, mask WPSF_POSITION_TYPE
	mov	dx, WPT_AT_MOUSE_POSITION shl offset WPSF_POSITION_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintPositionWindowAtMouse	endp

HintExtendWindowToBottomRight	proc	far
	mov	cx, mask WPSF_SIZE_TYPE
	mov	dx, WST_EXTEND_TO_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintExtendWindowToBottomRight	endp

HintSizeWindowAsDesired	proc	far
	mov	cx, mask WPSF_SIZE_TYPE
	mov	dx, WST_AS_DESIRED shl offset WPSF_SIZE_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintSizeWindowAsDesired	endp

HintSizeWindowAsRatioOfParent	proc	far
EC <	push	ax							  >
EC <	VarDataSizePtr	ds, bx, ax					  >
EC <	cmp	ax, size SpecWinSizePair				  >
EC <	ERROR_NE  OL_WIN_HINT_REQUIRES_SPEC_WIN_SIZE_PAIR_ARGUMENT 	  >
EC <	pop	ax							  >

	mov	cx, mask WPSF_SIZE_TYPE
	mov	dx, WST_AS_RATIO_OF_PARENT shl offset WPSF_SIZE_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintSizeWindowAsRatioOfParent	endp

HintSizeWindowAsRatioOfField	proc	far
EC <	push	ax							  >
EC <	VarDataSizePtr	ds, bx, ax					  >
EC <	cmp	ax, size SpecWinSizePair				  >
EC <	ERROR_NE  OL_WIN_HINT_REQUIRES_SPEC_WIN_SIZE_PAIR_ARGUMENT	  >
EC <	pop	ax							  >

	mov	cx, mask WPSF_SIZE_TYPE
	mov	dx, WST_AS_RATIO_OF_FIELD shl offset WPSF_SIZE_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintSizeWindowAsRatioOfField	endp

HintExtendWindowNearBottomRight	proc	far
	mov	cx, mask WPSF_SIZE_TYPE
	mov	dx, WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	call	SetWinPosSizeAttrFromRegs
	ret
HintExtendWindowNearBottomRight	endp

HintNotMovable	proc	far
	class	OLWinClass

	call	WinCommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MOVABLE
	ret
HintNotMovable	endp

HintCustomWindow	proc	far
	class	OLWinClass

	; Nuke ALL window options except for those which are non-visible
	;
	call	WinCommon_DerefVisSpec_DI
	and	ds:[di].OLWI_attrs, mask OWA_DISMISS_WHEN_DISABLED or \
				    mask OWA_FOCUSABLE or mask OWA_TARGETABLE \
				    or mask OWA_MAXIMIZABLE
	;OWA_MAXIMIZABLE is something we need for Workplace Shell (PM).
	;This needs to be here until we find a better solution.
	or	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	ret
HintCustomWindow	endp

HintWindowNoTitleBar	proc	far
	class	OLWinClass

	; nuke title bar
	call	WinCommon_DerefVisSpec_DI
	andnf	ds:[di].OLWI_attrs, not (mask OWA_HEADER or \
					mask OWA_HAS_SYS_MENU or \
					mask OWA_TITLED or \
					mask OWA_MOVABLE)
ISU <	andnf	ds:[di].OLWI_attrs, not mask OWA_REAL_MARGINS		>
	ret
HintWindowNoTitleBar	endp

HintWindowNoSysMenu	proc	far
	class	OLWinClass

	; nuke system menu
	call	WinCommon_DerefVisSpec_DI
	andnf	ds:[di].OLWI_attrs, not mask OWA_HAS_SYS_MENU
	ret
HintWindowNoSysMenu	endp

HintWindowMinimizeTitleBar	proc	far
	class	OLWinClass

if	 _ALLOW_MINIMIZED_TITLE_BARS
	; set bit to indicate minimized title bar
	call	WinCommon_DerefVisSpec_DI
	ornf	ds:[di].OLWI_moreFixedAttr, mask OMWFA_MINIMIZE_TITLE_BAR

	; disable sys menu since the title bar will not be big enough to
	; support it.
	andnf	ds:[di].OLWI_attrs, not mask OWA_HAS_SYS_MENU
endif	;_ALLOW_MINIMIZED_TITLE_BARS
	ret
HintWindowMinimizeTitleBar	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetWinPosSizeAttrFromRegs

SYNOPSIS:	Sets win pos size stuff from registers.

CALLED BY:	HintStaggered, etc.

PASS:		cx -- bits to clear
		dx -- bits to set

RETURN:		nothing

DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/21/91		Initial version

------------------------------------------------------------------------------@

SetWinPosSizeAttrFromRegs	proc	near
	mov	ax, cx				;ax = "has icon" flag
;SAVE BYTES - nuke this push
	push	bp, cx

	not	cx

	;setup ds:bp and ds:di assuming hint is for windowed object


	call	WinCommon_DerefVisSpec_DI
	lea	bp, ds:[di].OLWI_winPosSizeFlags ;set ds:bp = WinPosSizeFlags

	add	di, offset VI_bounds

	test	dx, mask WPSF_HINT_FOR_ICON	;is hint for icon?

if _NO_WIN_ICONS	;------------------------------------------------------

	jnz	done

else	; not _NO_WIN_ICONS ---------------------------------------------------

	jz	updateFlags			;skip if not...

	;hint is for icon: adjust ds:bp and ds:di

	tst	ax				;does this window have an icon?
	jz	done				;ignore hint if not...

	.warn	-private

	add	bp, (offset OLMDWI_iconWinPosSizeFlags) \
		     - (offset OLWI_winPosSizeFlags)

	.warn	@private

	mov	di, bp
	add	di, 4

	;make sure we are not going to set a size for the icon
EC <	test	cl, mask WPSF_SIZE_TYPE		;changing size?		>
EC <	ERROR_Z	OL_APPLICATION_CANNOT_SET_SIZE_FOR_WIN_ICON		>

endif	; if _NO_WIN_ICONS ----------------------------------------------------

updateFlags:
	;Update the WinPosSizeFlags record:
	;ds:bp points to WinPosSizeFlags record,
	;ds:di points to left and top position values

	push	cx
	and	cx, ds:[bp]			;clear some flags
	or	cx, dx				;set some flags
	mov	ds:[bp], cx			;save result
	pop	cx

	;see if specific position has been specified

						;check low byte of RESET mask
	test	cl, mask WPSF_POSITION_TYPE	;changing position?
	jne	checkSize			;skip if not...

						;check low byte of SET mask
	test	dl, mask WPSF_POSITION_TYPE	;is WPT_AT_RATIO?
	jne	checkSize			;skip if not WPT_AT_RATIO...

	;set WinPosSizeState flag for window or icon object
	;first make sure that the size of this object is not descibed using
	;the difference between bounds values.

					;pass ds:di = Rectangle
					;ds:[bp]+2 = winPosSizeState field
	call	EnsureRightBottomBoundsAreIndependent
	or	byte ptr ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR
					;SPEC_BUILD must examine to convert
					;to pixel units.
	mov	ax, ds:[bx].SWSP_x
	mov	ds:[di]+0, ax
	mov	ax, ds:[bx].SWSP_y
	mov	ds:[di]+2, ax

checkSize:
	;see if specific size has been specified

						;check low byte of RESET mask
	test	cl, mask WPSF_SIZE_TYPE		;changing size?
	jne	done				;skip if not...

	mov	ah, mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT

	mov	al, dl				;get low byte of SET mask
	and	al, mask WPSF_SIZE_TYPE
	je	checkSize2			;skip if WST_AT_RATIO_OF_PARENT.

	cmp	al, WST_AS_RATIO_OF_FIELD
	jne	done			;skip if not WST_AS_RATIO_OF_FIELD...

	mov	ah, mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD

checkSize2:
	or	byte ptr ds:[bp]+2, ah	;SPEC_BUILD must examine to convert
					;to pixel units.

	mov	ax, ds:[bx].SWSP_x
	mov	ds:[di]+4, ax
	mov	ax, ds:[bx].SWSP_y
	mov	ds:[di]+6, ax

done:
	pop	bp, cx
	ret
SetWinPosSizeAttrFromRegs	endp





;make sure that the size of this object is not descibed using
;the difference between bounds values.
;pass	ds:di = Rectangle
;	ds:bp+2 = winPosSizeState field - indicates whether size is
;			already described independently
;	ax, bx = new position value (SpecWinSpecSize)

EnsureRightBottomBoundsAreIndependent	proc	far
	;if the position of this object is already a SpecWinSizeSpec
	;value, then the size of this object is already in the right/bottom
	;fields - the data is already independent, so just return.
	;Similarly, if the size of this object is already a SpecWinSizeSpec
	;value, can also return.

	test	byte ptr ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR \
				 or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
				 or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT
	jnz	done

	;We have Chris Hawley bounds - pixels, size is difference between.
	;Calculate size of object and place in right/bottom fields
	;(no need to set a flag indicating this - WPSS_VIS_POS_IS_SPEC_PAIR
	;being true implies that the size of the object is contained in the
	;right/bottom bounds fields.  (Old graphics system increment
	;finally commented out 4/20/93 cbh)

	push	ax
	mov	ax, ds:[di].R_right
	sub	ax, ds:[di].R_left
	mov	ds:[di].R_right, ax

	mov	ax, ds:[di].R_bottom
	sub	ax, ds:[di].R_top
	mov	ds:[di].R_bottom, ax
	pop	ax
done:
	ret
EnsureRightBottomBoundsAreIndependent	endp


;make sure that the size of this object *is* descibed using
;the difference between bounds values.  (Added 5/18/93 cbh)
;pass	ds:di = Rectangle
;	ds:bp+2 = winPosSizeState field - indicates whether size is
;			already described independently
;	ax, bx = new position value (SpecWinSpecSize)

EnsureBoundsAreDependent	proc	far
	;if the position of this object is still a SpecWinSizeSpec
	;value, then the size of this object is already in the right/bottom
	;fields - the data still needs to be independent, so just return.
	;Similarly, if the size of this object is still a SpecWinSizeSpec
	;value, can also return.

	test	byte ptr ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR \
				 or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
				 or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT
	jnz	done

	;We need Chris Hawley bounds - pixels, size is difference between.

	push	ax
	mov	ax, ds:[di].R_right
	add	ax, ds:[di].R_left
	mov	ds:[di].R_right, ax

	mov	ax, ds:[di].R_bottom
	add	ax, ds:[di].R_top
	mov	ds:[di].R_bottom, ax
	pop	ax
done:
	ret
EnsureBoundsAreDependent	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	AvoidCenteringIfExtending

SYNOPSIS:	Can't center a window that extends, so restore position.

CALLED BY:	OpenWinProcessHints

PASS:		*ds:si -- window
		cx -- old winPosSizeFlags

RETURN:		nothing

DESTROYED:	di, ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/93       	Initial version

------------------------------------------------------------------------------@

AvoidCenteringIfExtending	proc	near
	;
	; Not extending to bottom right, exit.
	;
	call	WinCommon_DerefVisSpec_DI
	mov	ax, ds:[di].OLWI_winPosSizeFlags
	mov	ah, al
	and	al, mask WPSF_SIZE_TYPE
	cmp	al, WST_EXTEND_TO_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	je	checkCentering
	cmp	al, WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	jne	exit

checkCentering:
	;
	; Not centering, exit
	;
	mov	al, ah
	and	al, mask WPSF_POSITION_TYPE
ifdef WPT_CENTER_ON_GEN_PARENT
	cmp	al, WPT_CENTER_ON_GEN_PARENT shl offset WPSF_POSITION_TYPE
	je	nukeCenter
endif
	cmp	al, WPT_CENTER shl offset WPSF_POSITION_TYPE
	jne	exit

nukeCenter:
	;
	; Replace center stuff by whatever the default was before hints were
	; processed.
	;
	mov	ax, ds:[di].OLWI_winPosSizeFlags
	and	ax, not mask WPSF_POSITION_TYPE
	and	cx, mask WPSF_POSITION_TYPE
	or	ax, cx
	mov	ds:[di].OLWI_winPosSizeFlags, ax

exit:
	ret
AvoidCenteringIfExtending	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateSpecBuild -- MSG_SPEC_BUILD_BRANCH for
		OLWinClass

DESCRIPTION:	We get this method when the UI is recursively SPEC_BUILDing
		the objects in the generic tree. We allow superclass to
		send on to self and to kids, and then we create our
		system menu and menu icons if necessary. We then send
		SPEC_BUILD on to these objects, since they are not generically
		connected to anything.

PASS:		*ds:si - instance data
		es - segment of OpenWinClass

		ax - MSG_SPEC_BUILD_BRANCH
		cx - ?
		dx - ?
		bp - SpecBuildFlags

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Lifted from Tony's MenuBar code
	Eric	1/90		Moved from Motif/Win/winClassSpec.asm
				so can be used for all specific UIs
	Joon	8/92		PM extensions

------------------------------------------------------------------------------@


OpenWinUpdateSpecBuild	method dynamic	OLWinClass, MSG_SPEC_BUILD_BRANCH

	;lastly send on to superclass so that self and kids get MSG_SPEC_BUILD
	;(moved to end to get menu bar working in header -cbh 2/ 6/92)

	push	bp
	call	WinCommon_ObjCallSuperNoLock_OLWinClass
	pop	bp

	test	bp, mask SBF_WIN_GROUP
	jz	done			;if not, quit, just doing button at this
					;time. Will send SPEC_BUILD to
					;OLWinClass, then update bp and send
					;UPDATE_SPEC_BUILD to kids (such as
					;view). Returns updated bp

	;Do UI-specific stuff only if we are not using a custom window.

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	done

	;if this window is a pinned menu, do some UI-specific stuff
	;OpenLook: enable borders on all triggers
	;CUA/Motif: create system menu

if _MENUS_PINNABLE
	call	OpenWinUpdatePinnedMenu
					;see OpenLook/Win/winClassSpec.asm and
					;and CommonUI/CWin/cwinClassCUAS.asm
	jc	done			;skip if handled....
endif

if _GCM
	;
	; if running in General Consumer Mode, create the appropriate
	; big icons in the header area.
	; (pass bp = SpecBuildFlags)

	call	OpenWinEnsureHeaderGCMIcons

endif	; _GCM
	;
	; if this window has a system menu, create/update the four
	; associated objects: menu button and three menu icons.
	; (pass bp = SpecBuildFlags)
	;
CUAS <	call	OpenWinEnsureSysMenu					     >
CUAS <	call	OpenWinEnsureSysMenuIcons				     >
	;
	; Now that we have setup the system menu, we can go ahead and
	; find the title monikers for OLMenued windows.  (And destroy
	; the window's moniker list in the process.)
	;

ISU <	call	WinCommon_DerefVisSpec_DI				     >
ISU <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			     >
ISU <	je	findTitle						     >
ISU <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			     >
ISU <	jne	done							     >
ISU <findTitle:								     >
ISU <	call	OLMenuedWinFindTitleMonikerFar				     >

done:
	ret

OpenWinUpdateSpecBuild	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureHeaderGCMIcons

DESCRIPTION:	This procedure creates the System icons which appear
		in the window header area.

CALLED BY:	OpenWinUpdateSpecBuild

PASS:		ds:*si	- instance data
		bp	- SpecBuildFlags from UPDATE_SPEC_BUILD

RETURN:		bp	- same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		initial version

------------------------------------------------------------------------------@

if _GCM

.assert (offset GCMF_LEFT_ICON eq 3)
.assert (offset GCMF_RIGHT_ICON eq 0)

OpenWinEnsureHeaderGCMIcons	proc	far
	class	OLBaseWinClass

	;are we in General Consumer Mode?

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jz	done			;skip if not...

	call	EnsureHeaderGCMIcons	;in WinClasses
done:
	ret
OpenWinEnsureHeaderGCMIcons	endp

endif	; _GCM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinGupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This handles the SGQT_BRING_UP_KEYBOARD GupQuery by setting
		the appropriate flag on the object, so when it gets the
		focus, it will bring up the keyboard.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinGupQuery	method	OLWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BRING_UP_KEYBOARD
	je	bringUpKeyboard

if _DUI
	cmp	cx, SGQT_SET_KEYBOARD_TYPE
	je	setKeyboardType
endif

	cmp	cx, SGQT_WIN_GROUP
	je	checkWinGroup

passItUp:
	mov	di, offset OLWinClass
	call	ObjCallSuperNoLock
exit:
	ret

checkWinGroup:
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	passItUp
	tst	ds:[di].VCI_window
	jz	passItUp

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCI_window
	stc
	jmp	exit

bringUpKeyboard:

;	If the kbd override flag already exists, just exit, otherwise set
;	our own flag to force the data to come on screen.

	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE	;Exit if override
	call	ObjVarFindData				; already present
	jc	exit

	mov	ax, MSG_GEN_SET_KBD_OVERRIDE
	mov	cx, KO_KEYBOARD_REQUIRED
	call	ObjCallInstanceNoLock
	stc			;Query answered
	jmp	exit

if _DUI
setKeyboardType:
	;
	; get keyboard type info
	;
	push	es
	mov	es, dx
	mov	di, bp
	mov	cx, es:[di].KTP_displayType
	mov	dx, es:[di].KTP_disallowType
	mov	bp, es:[di].KTP_entryMode
	pop	es
	;
	; save desired keyboard type for this window
	;
	push	cx				; save display type
	mov	ax, HINT_KEYBOARD_TYPE or mask VDF_SAVE_TO_STATE
	mov	cx, size KeyboardTypeParams
	call	ObjVarAddData
	pop	cx
	mov	ds:[bx].KTP_displayType, cx
	mov	ds:[bx].KTP_disallowType, dx
	mov	ds:[bx].KTP_entryMode, bp
	;
	; set keyboard type if we are focused
	;	cx, dx, bp = type info
	;
	call	CheckIfKeyboardRequired
	jnc	dontTellKbd
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	dontTellKbd
	cmp	{word}ds:[bx], KO_NO_KEYBOARD
	je	dontTellKbd
	mov	di, ds:[si]
	add	di, ds:[di].OLWin_offset
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_APP_EXCL
	jz	dontTellKbd
	call	FloatingKbdSetType
dontTellKbd:
	stc					; query answered
	jmp	exit
endif

OLWinGupQuery	endp

if 0	; I tried this to get popups to come up on the screen, not the field,
	; when generically inside a sysmodal box, but no one expects the window
	; that OLApplication returns, so the attempt was a failure. I leave
	; this here lest anyone make that mechanism work better -- ardeb 6/8/93
;;;
;;;COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;;		OLWinGupQueryVisParent
;;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;;
;;;SYNOPSIS:	Transform query for popup into query for sys-modal if
;;;		we are sys-modal
;;;
;;;CALLED BY:	MSG_SPEC_GUP_QUERY_VIS_PARENT
;;;PASS:		*ds:si	= object
;;;		cx	= SpecQueryVisParentType
;;;RETURN:		carry set if answered:
;;;			^lcx:dx	= vis parent to use
;;;DESTROYED:	ax, bp
;;;SIDE EFFECTS:
;;;
;;;PSEUDO CODE/STRATEGY:
;;;
;;;
;;;REVISION HISTORY:
;;;	Name	Date		Description
;;;	----	----		-----------
;;;	ardeb	6/ 8/93		Initial version
;;;
;;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;;OLWinGupQueryVisParent method dynamic OLWinClass, MSG_SPEC_GUP_QUERY_VIS_PARENT
;;;		cmp	cx, SQT_VIS_PARENT_FOR_POPUP
;;;		jne	passItUp
;;;		push	es
;;;		segmov	es, <segment GenInteractionClass>, di
;;;		mov	di, offset GenInteractionClass
;;;		call	ObjIsObjectInClass
;;;		pop	es
;;;		jnc	passItUp
;;;		mov	di, ds:[si]
;;;		add	di, ds:[di].GenInteraction_offset
;;;		test	ds:[di].GII_attrs, mask GIA_SYS_MODAL
;;;		jz	passItUp
;;;		mov	cx, SQT_VIS_PARENT_FOR_SYS_MODAL
;;;passItUp:
;;;		mov	di, offset OLWinClass
;;;		GOTO	ObjCallSuperNoLock
;;;OLWinGupQueryVisParent endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinSetKbdPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the cached position of the floating keyboard.

CALLED BY:	GLOBAL
PASS:		cx, dx - x,y coord
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinSetKbdPosition	method	OLWinClass, MSG_GEN_SET_KBD_POSITION
	mov	bp, cx
	mov	ax, ATTR_GEN_WINDOW_KBD_POSITION or mask VDF_SAVE_TO_STATE
	mov	cx, size Point
	call	ObjVarAddData
	mov	ds:[bx].P_x, bp
	mov	ds:[bx].P_y, dx
	ret
OLWinSetKbdPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinSetKbdOverride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the keyboard override for this object

CALLED BY:	GLOBAL
PASS:		cx - KeyboardOverride
		*ds:si - OLWin object
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinSetKbdOverride	method	OLWinClass, MSG_GEN_SET_KBD_OVERRIDE
	.enter
	push	cx
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE or mask VDF_SAVE_TO_STATE
	mov	cx, size KeyboardOverride
.assert	size KeyboardOverride eq size word
	call	ObjVarAddData
	pop	ds:[bx]

;	Now, if we have the focus, we need to force the keyboard either
;	up or down (only do this on NO_KEYBOARD systems)

	call	CheckIfKeyboardRequired
	jnc	exit

	mov	di, ds:[si]
	add	di, ds:[di].OLWin_offset
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_APP_EXCL
	jz	exit

	mov	ax, ds:[bx]			;AX <- KeyboardOverride
	call	SendKbdStatusNotification
exit:
	.leave
	ret
OLWinSetKbdOverride	endp

if _DUI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinToggleFloatingKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle state of floating kbd

CALLED BY:	MSG_GEN_TOGGLE_FLOATING_KBD
PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		ds:bx	= OLWinClass object (same as *ds:si)
		es 	= segment of OLWinClass
		ax	= message #
RETURN:
DESTROYED:
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLWinToggleFloatingKbd	method dynamic OLWinClass,
					MSG_GEN_TOGGLE_FLOATING_KBD
	.enter
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	done
	mov	ax, ds:[bx]
	cmp	ax, KO_NO_KEYBOARD
	je	turnOnKeyboard
	;
	; turning keyboard off, save current state
	;	ax = current state
	;
	push	ax				; save current state
	mov	ax, HINT_PREVIOUS_KBD_OVERRIDE or mask VDF_SAVE_TO_STATE
	mov	cx, size KeyboardOverride
	call	ObjVarAddData
	pop	ds:[bx]				; store current state
	mov	ax, KO_NO_KEYBOARD		; ax = new state
	jmp	short storeNewState

turnOnKeyboard:
	;
	; restore previous state
	;
	mov	ax, HINT_PREVIOUS_KBD_OVERRIDE
	call	ObjVarFindData
	mov	ax, KO_KEYBOARD_REQUIRED	; in case no prev state!
	jnc	storeNewState
	mov	ax, ds:[bx]			; new state = prev state
	;
	; re-deref in case we moved from adding TEMP vardata
	;
storeNewState:
	push	ax				; save new stae
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	mov	cx, size KeyboardOverride
	call	ObjVarAddData
	pop	ax
	mov	ds:[bx], ax			; store new state
	call	SendKbdStatusNotification
done:
	.leave
	ret
OLWinToggleFloatingKbd	endm

endif	; _DUI

WinCommon	ends
WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinSpecBuild -- MSG_SPEC_BUILD for OLWinClass

DESCRIPTION:	Build out this base window visually, attaching it onto
		some background window in the system.  NOTE that this routine
		can only handle the case of doing a WIN_GROUP spec build for
		this window.  This routine should be replaced for the
		non-WIN_GROUP cases.

IMPORTANT:	if you change this procedure, be sure to update
		OLMenuedWinSpecBuild.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - MSG_SPEC_BUILD

	cx - ?
	dx - ?
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use data set during BUILD to determine vis parent
	Reduce VisMonikerList to VisMoniker
	Update position and size according to specific UI and application needs
	Check if generic state data indicates that window is minimized or maxi.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	11/89		Reorganization, added position/size/moniker code

------------------------------------------------------------------------------@

OpenWinSpecBuild	method dynamic	OLWinClass, MSG_SPEC_BUILD

EC <	; We can't deal with non win-group case				>
EC <	test	bp, mask SBF_WIN_GROUP					>
EC <	ERROR_Z	OL_ERROR						>

	call	VisCheckIfSpecBuilt	; If already vis built, done.
	jc	Done

	; First, set the fully enabled based on our parent's fully enabled
	; state (passed in with BuildFlags) and our enabled state.

	call	VisSpecBuildSetEnabledState

if	ERROR_CHECK	;------------------------------------------------------
	;
	; Ensure that GenPrimary and GenDisplay are handled by
	; OLMenuedWinSpecBuild.
	;
	call	WinCommon_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
CUAS <	ERROR_Z	OL_OPENWINVISBUILD_CANNOT_HANDLE_PRIMARY_OR_DISPLAY_WIN	>
CUAS <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
CUAS <	ERROR_Z	OL_OPENWINVISBUILD_CANNOT_HANDLE_PRIMARY_OR_DISPLAY_WIN	>
endif			;------------------------------------------------------

if _HAS_LEGOS_LOOKS
	call	LegosSetWindowLookFromHints
endif
	call	OpenWinSetVisParent	;query for visual parent and visually
					;attach self to that object.

	;search this object's VisMonikerList for the moniker which matches
	;the DisplayType for this application, and replace the list with that
	;moniker.

	mov	bp, mask VMSF_REPLACE_LIST \
		    or (VMS_TEXT shl offset VMSF_STYLE)
					;return non-abbreviated text string,
					;otherwise abbreviated text string,
					;otherwise textual GString, otherwise
					;non-textual GString.
	clc				;flag: use this object's list
	call	GenFindMoniker		;trashes ax, di, es, may move ds

	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(Note: if parent geometry is not yet valid, this does nothing)

	call	ConvertSpecWinSizePairsToPixels

	;now update the window according to hints passed from the application
	;or specific-ui determined behavior. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to;do this.

	;FINALLY, PROCESS HINTS.  The hints requesting that the window be
	;made the default focus or target are processed here.

	; If ALL_DIALOGS_ARE_MODAL, don't grab the focus before the
	; window is built  -- kho, 7/13/95

ife	ALL_DIALOGS_ARE_MODAL
	call	ScanFocusTargetHintHandlers
endif
	;
	; NOTE: we do not handling restoring maximized state as only
	; GenDisplay and its subclass GenPrimary supports this.  This
	; is handled in OLMenuedWinSpecBuild.
	;
Done:
	ret

OpenWinSpecBuild	endp


if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegosSetWindowLookFromHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The legos look is stored in instance data, so when
		we unbuild and rebuild we need to set it from the hints.

CALLED BY:	OpenWinSpecBuild
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegosSetWindowLookFromHints	proc	near
	uses	ax, bx, bp, di
	.enter

	clr	bp			; our table index

	;
	; Start our indexing at 1, as 0 has no hint
	;
loopTop:
	inc	bp
	inc	bp			; next entry
	mov	ax, cs:[buildLegosWindowLookHintTable][bp]
	call	ObjVarFindData
	jc	gotLook

	cmp	bp, LAST_BUILD_LEGOS_WINDOW_LOOK * 2
	jl	loopTop

	clr	bp			; no hints found, so must be look 0

gotLook:
	mov	ax, bp			; use ax as bp can't be byte addressable
	sar	ax, 1			; words to bytes
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLWI_legosLook, al
done:
	.leave
	ret
LegosSetWindowLookFromHints	endp

	;
	; Make sure this table matches that in cwinClassMisc.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the WinMethods resource at build time, and it
	; is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
buildLegosWindowLookHintTable	label word
	word	0
LAST_BUILD_LEGOS_WINDOW_LOOK	equ ((($ - buildLegosWindowLookHintTable) / \
					(size word)) - 1)
CheckHack<LAST_BUILD_LEGOS_WINDOW_LOOK eq LAST_LEGOS_WINDOW_LOOK>

endif	; endif of if _HAS_LEGOS_LOOKS




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWinPosSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure updates this windowed Object's position and
		size in relation to its parent window, given the current
		state, specific UI defaults for this object type, and
		application hints concerning positioning/resizing.

CALLED BY:	OpenWinSpecBuild, OpenWinMoveResizeWin

PASS:		*ds:si	- instance data
		OLWI_winPosSizeFlags = WinPosSizeFlags record
			(specific UI requested or application hinted)
		OLWI_winPosSizeState = OLWinPosSizeState record

USES:		VI_bounds - current bounds information for object.
			(in pixel units)

RETURN:		OLWI_winPosSizeState updated
		bx = new WinPosSizeState value
		ax = WinPosSizeFlags value

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert	(offset WPSF_PERSIST) gt 7
.assert	(offset WPSF_PERSIST) eq (offset WPSS_HAS_MOVED_OR_RESIZED)

.assert	(offset WPSF_POSITION_TYPE) lt 6
.assert	(offset WPSF_SIZE_TYPE) lt 7

UpdateWinPosSize	proc	far
	class	OLWinClass

	call	WinCommon_DerefVisSpec_DI

	mov	ax, ds:[di].OLWI_winPosSizeFlags
	mov	bx, ds:[di].OLWI_winPosSizeState

	mov	ch, bh			;get WinPosSizeState (HIGH)
	and	ch, ah			;mask with WinPosSizeFlags (HIGH)
					;pass result to these two procedures...

	test	bx, mask WPSS_POSITION_INVALID or mask WPSS_HAS_RESTARTED
					;(restarted check added cbh 7/ 2/90)
	jz	checkSize		;don't update if valid

	push	cx
	call	UpdateWinPosition	;update position (if not centering)
	pop	cx

checkSize:
	test	bx, mask WPSS_SIZE_INVALID	;is size valid?
	jz	UWPS_done			;skip if so...

	call	UpdateWinSize		;update size

UWPS_done:
	;save state record back to object instance data

	call	WinCommon_DerefVisSpec_DI
	ANDNF	bx, not mask WPSS_HAS_RESTARTED
					;clear this now -- cbh 7/ 2/90
	mov	ds:[di].OLWI_winPosSizeState, bx
	ret

UpdateWinPosSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWinPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maybe move Window

CALLED BY:	UpdateWinPosSize

PASS:		*ds:si = object
		ax = WinPosSizeFlags record
		bx = WinPosSizeState record
		ch = WinPosSizeFlags(HIGH) AND WinPosSizeState (HIGH)

RETURN:		ax = same
		bx = updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/15/96		added header, thank you very much

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAXIMUM_HEIGHT_OF_FLOATING_KEYBOARD	equ	116

UpdateWinPosition	proc	far
	class	OLWinClass
	push	ax, bx

	mov	cl, al			;cl = position request (LOW BYTE)
	and	cl, mask WPSF_POSITION_TYPE

;no, let icons go wherever they want! - brianc 3/27/92
;	test	bh, mask SSPR_ICON		;if an icon always request slot
;	jnz	checkPosRequest1		;  (added cbh 7/ 2/90)

	test	ch, (mask WPSF_PERSIST) shr 8
	jnz	useCurrentBoundsAsPosition	;skip if moved and care...

	;
	; case WPSF_POSITION_TYPE {
	;	/* note that if we are centering, we can't do anything until
	;	 * the window is sized. */
	;
	cmp	cl, WPT_AT_SPECIFIC_POSITION
	jz	useCurrentPosition

.assert	WPT_AT_RATIO	eq	0
	tst	cl
	jne	checkPosRequest1

useCurrentBoundsAsPosition:
	;
	; is WPT_AT_RATIO, or was MOVED and we care (both cases mean that
	; the VI_bounds values have already been converted from ratios)
	;
	test	bx, mask WPSS_VIS_POS_IS_SPEC_PAIR \
		    or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
		    or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	LONG	jnz UWP_end		; skip if not converted yet...

useCurrentPosition:
	call	WinCommon_DerefVisSpec_DI
	mov	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_top
	jmp	havePositionCxDx

checkPosRequest1:
	cmp	cl, WPT_STAGGER shl offset WPSF_POSITION_TYPE
	jne	checkPosRequest2

	;
	; WPT_STAGGER:
	;	send VUQ_REQUEST_STAGGER_SLOT, passing current value
	;	   of StaggerNumber. (If is 0, will assign a new stagger
	;	   number and position. Otherwise will calculate the
	;	   position for the specified stagger number.
	;	set position = staggerPosition
	;	WPSS_POSITION_INVALID = FALSE
	;

;	call	WinCommon_DerefVisSpec_DI
;	or	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_STATE
;					;flag: will need to save object
;					;state when closed or detached.

	mov	dl, bh			;get HIGH BYTE of state
					;(previously assigned stagger slot#
					;SWSS_ICON bit set if window is icon,
					;slot = 0 if never assigned.)

	test	bx, mask WPSS_HAS_RESTARTED
	jz	requestSlot		;skip if not...

	;
	; this window was once shut-down. Is now restarting: if this slot
	; is occupied, give me another.
	;
	or	dl, mask SSPR_REASSIGN_IF_CONFLICT

requestSlot:
	mov	cx, SVQT_REQUEST_STAGGER_SLOT
	call	WinCommon_VisCallParent_VUP_QUERY
					;returns bp = slot #, (cx,dx) position
EC <	ERROR_NC OL_ERROR		;parent MUST answer!		>

if TOOL_AREA_IS_TASK_BAR

	;
	; If taskbar is at the top of the screen, adjust position to
	; account for taskbar above.
	;
	call	GetTaskBarPositionAdjustment
	add	dx, di			; add adjustment for taskbar

endif
	pop	bx			;get WinPosSizeState
	mov	ax, bp
	or	bh, al			;set previously assigned stagger slot#
					;SWSS_ICON bit set if window is icon
	push	bx			;save WinPosSizeState
	jmp	havePositionCxDx	;skip to change bounds and
					;mark position VALID...

checkPosRequest2:
	cmp	cl, WPT_TILED shl offset WPSF_POSITION_TYPE
	jne	checkPosRequest3

	;
	; WPT_TILED:
	;	Position this window at right bound of previous child.
	;	If this window is not fully visible within parent,
	;	position at bottom bound of previous child.
	;
	test	bx, mask WPSS_SIZE_INVALID	;do we have size yet?
	LONG	jnz UWP_end			;skip if not...

	call	WinCommon_Mov_CXDX_Self

	;
	;  MAKE SURE THERE IS A PARENT!
	;
	mov	ax, MSG_VIS_FIND_CHILD
	call	WinCommon_VisCallParent	;returns CF=0, bp = child #
					;or CF=1 if not found
	pushf
	clr	cx			;assume could not find child
	clr	dx			;	or is first child
	popf
	LONG	jc havePositionCxDx	;skip if failed...
	tst	bp
	LONG	jz havePositionCxDx	;skip if is first child

	; bp = child # for this child, and it has an older sibling.
	;
	; THIS IS A HACK
	;
	; DUBIOUS DS
	;
	push	ds, si
	call	VisFindParent		;returns *bx:si = parent

	push	bx
	call	ObjLockObjBlock		;set *ds:si = parent
	mov	ds, ax

	dec	bp

	clr	cl			;get real bounds
	mov	ax, MSG_VIS_GET_BOUNDS
	clr	dx
	push	dx			; initial child (first
	push	bp			; child of composite)
	mov	bx, offset VI_link
	push	bx			; Push offset to LinkPart
	push	dx			; No call-back routine
	mov	dx, OCCT_ABORT_AFTER_FIRST
	push	dx
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren	; Returns:
					;	ax -- left
					;	bp -- top
					;	cx -- right
					;	dx -- bottom
	inc	cx
	mov	dx, bp			;make cx, dx = top right coord of sib

	pop	bx
	call	MemUnlock
	pop	ds, si

	jmp	havePositionCxDx	;skip to change bounds and
					;mark position VALID...

checkPosRequest3:
ifdef WPT_CENTER_ON_GEN_PARENT
	cmp	cl, WPT_CENTER_ON_GEN_PARENT shl offset WPSF_POSITION_TYPE
	jne	checkPosRequest3_5

	;
	; if size still invalid, application request must be bad
	; if size is not yet valid, this must be SPEC_BUILD - wait until
	; WIN_MOVE_RESIZE to do this work.
	;
	test	bx, mask WPSS_SIZE_INVALID	;do we have size yet?
	jnz	UWP_end				;skip if not...

	; calculate center of generic parent
	; WPSS_POSITION_INVALID = FALSE

	call	GetGenParentWinSize
	jc	UWP_end			;skip if parent size invalid...
	jnc	handleCenter

checkPosRequest3_5:
endif

	cmp	cl, WPT_CENTER shl offset WPSF_POSITION_TYPE
	jne	checkPosRequest4

	;
	; if size still invalid, application request must be bad
	; if size is not yet valid, this must be SPEC_BUILD - wait until
	; WIN_MOVE_RESIZE to do this work.
	;
	test	bx, mask WPSS_SIZE_INVALID	;do we have size yet?
	LONG	jnz	UWP_end			;skip if not...

	;
	; send VUQ_GET_WIN_SIZE
	; calculate center of parent
	; WPSS_POSITION_INVALID = FALSE
	;
	call	GetParentWinSize	;using al = WinPosSizeFlags,
					;find Field or Parent window size
	jc	UWP_end			;skip if parent size invalid...

handleCenter::
	call	WinCommon_DerefVisSpec_DI

	mov	ax, ds:[di].VI_bounds.R_right
	sub	ax, ds:[di].VI_bounds.R_left
	sub	cx, ax			;find total width margin
					;(may be negative)
	sar	cx, 1			;divide by 2


	mov	ax, ds:[di].VI_bounds.R_bottom
	sub	ax, ds:[di].VI_bounds.R_top
	sub	dx, ax			;find total width margin
					;(may be negative)
	sar	dx, 1			;divide by 2

	;
	; If we can have a floating keyboard, then center the box so it
	; won't be obscured by the floating keyboard (-atw 4/19/93)
	;

	call	CheckIfKeyboardRequired
	jnc	havePositionCxDx
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	havePositionCxDx
	cmp	{word} ds:[bx], KO_NO_KEYBOARD
	je	havePositionCxDx
if _DUI
	call	getKbdHeight		; ax = height
	shr	ax, 1
	sub	dx, ax
else
	sub	dx, (MAXIMUM_HEIGHT_OF_FLOATING_KEYBOARD/2)
endif
	jns	havePositionCxDx	;If this moved the top off the screen,
	clr	dx			; move it back on screen.
	jmp	short havePositionCxDx

checkPosRequest4:
	;
	;  Is this a menu or other UI-positioned object?
	;
	cmp	cl, WPT_AS_REQUIRED shl offset WPSF_POSITION_TYPE
	je	havePosition		;skip if so...

EC <	cmp	cl, WPT_AT_MOUSE_POSITION shl offset WPSF_POSITION_TYPE	>
EC <	ERROR_NZ OL_ILLEGAL_WIN_POSITION_FLAG				>

	;
	; WPT_AT_MOUSE_POSITION:
	;	get mouse position
	;	WPSS_POSITION_INVALID = FALSE
	;
	clr	cx, dx			;default position of mouse

	call	VisQueryParentWin
	tst	di
	jz	havePositionCxDx
					;pass di = window
	call	ImGetMousePos		;returns cx, dx
					;does not trash registers

havePositionCxDx:
	call	VisSetPosition			;move window

					;Just moving the window won't do it.
					;Have to mark window invalid for it to
					;actually be moved.
	call	WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL

havePosition:
	;
	; VI_bounds now represents correct position
	;
	pop	bx			;get WinPosSizeState
	and	bx, not mask WPSS_POSITION_INVALID
	push	bx			;save WinPosSizeState

UWP_end:
	pop	ax, bx
	ret

if _DUI
getKbdHeight	label	near
	mov	ax, 144			; default
	push	ds, si, cx, dx
	segmov	ds, cs, cx
	mov	si, offset kbdHeightCategory
	mov	dx, offset kbdHeightKey
	call	InitFileReadInteger
	pop	ds, si, cx, dx
	retn

kbdHeightCategory	char	"ui", 0
kbdHeightKey		char	"floatingKbdHeight", 0
endif

UpdateWinPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWinSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maybe size Window

CALLED BY:	UpdateWinPosSize

PASS:		*ds:si = object
		ax = WinPosSizeFlags record
		bx = WinPosSizeState record
		ch = WinPosSizeFlags(HIGH) AND WinPosSizeState (HIGH)

RETURN:		ax = same
		bx = updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/15/96		Added header, thank you very much.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert offset WPSF_SIZE_TYPE eq 0
.assert	WST_AS_RATIO_OF_PARENT eq 0
.assert	WST_AS_RATIO_OF_FIELD eq 1

UpdateWinSize	proc	far
	class	OLWinClass
	push	ax, bx

	test	ch, (mask WPSF_PERSIST) shr 8
	jnz	useCurrentBoundsAsSize	;skip if resized and care...

	;
	; case WPSF_SIZE_TYPE:
	;
	mov	cl, al			;cl = size request (LOW BYTE)
	and	cl, mask WPSF_SIZE_TYPE
	cmp	cl, WST_AS_RATIO_OF_FIELD
	jg	checkSizeRequest1	;skip if not WPS_AS_RATIO...

useCurrentBoundsAsSize:
	;
	; is WPS_AS_RATIO_OF_PARENT/FIELD, or was RESIZED and we care
	; (both cases mean that
	; the VI_bounds values have already been converted from ratios)

	test	bx, mask WPSS_VIS_POS_IS_SPEC_PAIR \
		    or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
		    or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	LONG	jnz UWS_end		;skip if not converted yet...

	call	WinCommon_DerefVisSpec_DI

	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left

	mov	dx, ds:[di].VI_bounds.R_bottom
	sub	dx, ds:[di].VI_bounds.R_top
	jmp	haveSizeCxDx

checkSizeRequest1:
	cmp	cl, WST_AS_DESIRED shl offset WPSF_SIZE_TYPE
	jne	checkSizeRequest2

;----------------------
;dontTryThisAtHomeKids:
;----------------------
	;
	; WST_AS_DESIRED
	;	RESET THE GEOMETRY OF THE WINDOW, so that children such
	;		as GenViews will take on a DESIRED geometry also.
	;	ask window how big it wants to be
	;	WPSS_SIZE_INVALID = FALSE
	;
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_MANUAL
	mov	di, segment OLWinClass
	mov	es, di
	mov	di, offset OLWinClass
	call	ObjCallSuperNoLock

	mov	cx, mask RSA_CHOOSE_OWN_SIZE	;start off with desired size
	mov	dx, cx
	jmp	short haveSizeCxDx	;skip to mark size VALID...

checkSizeRequest2:
	cmp	cl, WST_EXTEND_TO_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	jne	checkSizeRequest4

	;
	; WST_EXTEND_TO_BOTTOM_RIGHT
	;	send VUQ_GET_WIN_SIZE
	;	set bottom and right bounds
	;	WPSS_SIZE_INVALID = FALSE
	;
	test	bx, mask WPSS_POSITION_INVALID
	jnz	UWS_end

	call	GetParentWinSize	;using ax = WinPosSizeFlags,
					;find Field or Parent window size
					;(returns bp = x and y margins)
	jc	UWS_end			;skip if parent size invalid...

if TOOL_AREA_IS_TASK_BAR

	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.

	call	GetTaskBarSizeAdjustment
	sub	dx, di					; subtract off taskbar adjustment

endif

	;
	; We're going to add some code for B/W that allows the edges of windows
	; to sit OUTSIDE of their visual parent, which will avoid unneeded line
	; drawing in both the DisplayControl and a Primary.  (We only have to
	; take into account an extra pixel on the right and bottom, as the
	; left and top are accounted for in the size in handleExtend when it
	; subtracts the left/top of our window.)  -cbh 2/ 7/92    (Do it in
	; color, too, at least in Motif.  -cbh 12/ 7/92)  (Now, we'll do it
	; doubly in B/W, since there is not a right-bottom shadow on windows.
	; -3/11/93)
	;
if _MOTIF	;add one; add another if shadowing and B/W
    if THREE_DIMENSIONAL_BORDERS
	add	cx, THREE_D_BORDER_THICKNESS
	add	dx, THREE_D_BORDER_THICKNESS
    else
	inc	cx
	inc	dx
    if DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenCheckIfBW
	jnc	color
	inc	cx
	inc	dx
    endif
    endif
else		;add one if B/W; add another if shadowing and B/W
	call	OpenCheckIfBW
	jnc	color
	inc	cx
	inc	dx
    if DRAW_SHADOWS_ON_BW_GADGETS
	inc	cx
	inc	dx
    endif
endif
color:
	clr	bp
	jmp	handleExtend		;loop to set bounds...

checkSizeRequest4:

EC <	cmp	cl, WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE >
EC <	ERROR_NZ OL_ILLEGAL_WIN_SIZE_FLAG				   >

	;
	; WST_EXTEND_NEAR_BOTTOM_RIGHT
	;	send VUQ_GET_WIN_SIZE
	;	set bottom and right bounds
	;	WPSS_SIZE_INVALID = FALSE
	;
	test	bx, mask WPSS_POSITION_INVALID
	jnz	UWS_end

	call	GetParentWinSize	;using ax = WinPosSizeFlags,
					;find Field or Parent window size
					;(returns bp = x and y margins)
	jc	UWS_end

if TOOL_AREA_IS_TASK_BAR

	; If taskbar is at the top of the screen, subtract off the
	; height of the tool area (taskbar) from y margin.

	call	GetTaskBarPositionAdjustment
	sub	bp, di			; subtract off taskbar adjustment

endif

	;
	; We're going to add some code for B/W that allows the edges of windows
	; to sit OUTSIDE of their visual parent, which will avoid unneeded line
	; drawing in both the DisplayControl and a Primary.  (We only have to
	; take into account an extra pixel on the right and bottom, as the
	; left and top are accounted for in the size in handleExtend when it
	; subtracts the left/top of our window.)    (Now in color, too, at
	; least in Motif. -cbh 12/ 7/92)   (Code added now to do it doubly in
	; B/W Motif, thanks to the shadow we use.)
	;
if _MOTIF
	;
	; add one; add another if shadowing and B/W
	;
	inc	cx
    if DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenCheckIfBW
	jnc	handleExtend
	inc	cx
    endif
else		;add one if B/W; add another if shadowing and B/W
	call	OpenCheckIfBW
	jnc	handleExtend
	inc	cx
    if DRAW_SHADOWS_ON_BW_GADGETS
	inc	cx
    endif
endif

handleExtend:
	;
	; cx, dx = size of parent window
	; bp high, bp low = x and y margins recommended by parent for
	; windows which are extending to NEAR parent size.
	;
	call	WinCommon_DerefVisSpec_DI
	sub	cx, ds:[di].VI_bounds.R_left
	sub	dx, ds:[di].VI_bounds.R_top

	mov	ax, bp			;get margin info

	mov	al, ah			;ax = width margin
	clr	ah
	sub	cx, ax

	mov	ax, bp			;get margin info
	clr	ah			;ax = height margin
	sub	dx, ax

haveSizeCxDx:
	call	VisSetSize		;set in instance data

haveSize::
	;
	; VI_bounds now represents correct size
	;
	call	VisMarkFullyInvalid	;force geometry manager to position
					;children within windowed object
	pop	bx			;get WinPosSizeState
	and	bx, not mask WPSS_SIZE_INVALID
	push	bx			;save WinPosSizeState

UWS_end:
	pop	ax, bx
	ret
UpdateWinSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinSwapState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save current position, size, and state information in
		instance data

CALLED BY:	UTILITY

PASS:		*ds:si = window

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/15/96		Added header & documentation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	.warn	-private

	.assert	(offset OLWI_winPosSizeFlags)-(offset OLWI_attrs) eq 2
	.assert	(offset OLWI_winPosSizeState)-(offset OLWI_attrs) eq 4

	.assert	(offset OLWI_prevWinPosSizeFlags)-(offset OLWI_prevAttrs) eq 2
	.assert	(offset OLWI_prevWinPosSizeState)-(offset OLWI_prevAttrs) eq 4
	.assert	(offset OLWI_prevWinBounds)-(offset OLWI_prevAttrs) eq 6
	.assert (size Rectangle) eq 8

	.warn	@private

OpenWinSwapState	proc	far
	class	OLWinClass

	push	cx, di
	call	WinCommon_DerefVisSpec_DI
	push	di
	mov	bp, di
	add	bp, offset OLWI_prevAttrs ;ds:bp = start of save area
	add	di, offset OLWI_attrs	  ;ds:di = start of instance data
	mov	cx, 3			  ;swap 3 words
	call	SwapInstanceWords
	pop	di
	add	di, offset VI_bounds
	mov	cx, 4			;swap 4 words
	call	SwapInstanceWords
	pop	cx, di
	ret
OpenWinSwapState	endp

SwapInstanceWords	proc	near
	mov	ax, ds:[bp]
	xchg	ax, ds:[di]
	mov	ds:[bp], ax
	inc	di
	inc	di
	inc	bp
	inc	bp
	loop	SwapInstanceWords
	ret
SwapInstanceWords	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetParentWinSize

DESCRIPTION:	This procedure sends a visual upward query to find
		the Parent window size, as specified by the
		WinPosSizeFlags record in ax.

CALLED BY:	UpdateWinPosSize

PASS:		ds:*si	- instance data
		ax = WinPosSizeFlags
		bx = WinPosSizeStatus (not used)

RETURN:		ax, bx = same
		carry set if parent geometry invalid
		cx, dx = window size
		bp high = width margin to use if child window does not
			want to extend to parent's full width
		bp low = height margin to use if child window does not
			want to extend to parent's full height

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

GetParentWinSize	proc	near
	push	ax, bx
	call	OpenGetParentWinSize
	pop	ax, bx
	jnc	noParentSize		;skip if query not answered...
					;returns (cx, dx) = size of parent win

	;if parent does not yet have geometry, return carry set
	;(Changed code to avoid negative sizes, which apparently is a problem
	; now for some reason.  -cbh 1/21/92)

	tst	cx
	jz	noParentSize
	js	noParentSize
	tst	dx
	jz	noParentSize
	jns	haveSize

noParentSize:
	stc
	ret

haveSize:
	clc
	ret

GetParentWinSize	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinGetVisParent

DESCRIPTION:	Returns visual parent for this generic object

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_SPEC_GET_VIS_PARENT

	cx - ?
	dx - ?
	bp - SpecBuildFlags
		mask SBF_WIN_GROUP	- set if building win group

RETURN:
	carry - set
	ax - ?
	cx:dx	- Visual parent to use
	bp - SpecBuildFlags

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@


OpenWinGetVisParent	method dynamic	OLWinClass, MSG_SPEC_GET_VIS_PARENT
	test	bp, mask SBF_WIN_GROUP
	jnz	OWGVB_WinGroup
	clr	cx		; If not building win group, don't know
	clr	dx		; vis parent.  Should be subclassed.
	stc
	ret

OWGVB_WinGroup:
	; if building a WIN_GROUP and doing a DUAL_BUILD, then we need to
	; query for our vis parent

	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	OWGVB_useVisParent

	call	GetVisParentForDialog	; Fetch cx:dx as OD of visible parent
					; for WIN_GROUP part
	stc
	ret


OWGVB_useVisParent:

	; if not doing a DUAL_BUILD, then PRESUME that this is a Display,
	; & that OLCI_visParent has the correct place for this window to
	; be attached to.

	mov	di, offset OLCI_visParent
	call	WinCommon_Deref_Load_OD_CXDX
	stc
	ret

OpenWinGetVisParent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinSetVisParent

DESCRIPTION:	This procedure handles the "visibly attach to parent"
		phase of the standard OLWinClass SPEC_BUILD method handler.

CALLED BY:

PASS:		ds:*si	- instance data
		es	- segment of OLWinClass
		ax	- MSG_SPEC_BUILD
		cx, dx	- ?
		bp	- BuildFlags

RETURN:		*ds:si	- same

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Removed from OpenWinSpecBuild so superclasses
				can call from their SpecBuild.

------------------------------------------------------------------------------@

OpenWinSetVisParent	proc	far
;	class	OLWinClass		;can use OLWinClass instance data

	;THIS ROUTINE CAN'T DO A NON_WIN_GROUP BUILD. Classes w/dual build
	;should replace the non-win group case.

EC <	test	bp, mask SBF_WIN_GROUP					>
EC <	ERROR_Z	OL_OPEN_WIN_SPEC_BUILD_CANNOT_HANDLE_NON_WIN_GROUP_BUILD	>

	;HANDLE CASE OF VIS BUILD FOR WIN_GROUP

	call	VisGetVisParent		; uses MSG_SPEC_GET_VIS_PARENT
					; to return visual parent to use
					; cx:dx = parent to use
EC <	tst	cx							>
EC <	ERROR_Z	OL_SPEC_BUILD_NO_PARENT					>

	push	si
	mov	bx,cx			;bx:si = parent
	xchg	dx,si
	mov	cx,ds:[LMBH_handle]	;cx:dx = ourself

	;Since we're just adding to the Field or DisplayControl window,
	;can always add as last child.

	mov	bp, CCO_LAST	; add at the end
	mov	ax, MSG_VIS_ADD_CHILD
	call	WinCommon_ObjMessageCallFixupDS
	pop	si
	ret
OpenWinSetVisParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertSpecWinSizePairsToPixels

DESCRIPTION:	If this windowed object was just ATTACHED, then their might
		be position and size info (as % of parent) that was recovered
		and placed in this object's VI_bounds. If so, convert to
		actual pixel values now. See OpenWinSpecBuild - this info
		might not be needed.

CALLED BY:	OpenWinSpecBuild

PASS:		*ds:si - object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if WPSS_VIS_POS_IS_SPEC_PAIR or WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
		convert bounds to pixels

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	11/89		Renamed and squeezed into new pos/size scheme

------------------------------------------------------------------------------@


ConvertSpecWinSizePairsToPixels	proc	far
	class	OLWinClass
	;first see if the right/bottom fields contains window size information
	;(See Ensure...Independent)

	call	WinCommon_DerefVisSpec_DI
	push	ds:[di].OLWI_winPosSizeState

	test	ds:[di].OLWI_winPosSizeState, mask WPSS_VIS_POS_IS_SPEC_PAIR \
				or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
				or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	LONG jz	done			;skip if nothing invalid...

	;position and/or size must be converted
	;IN ANY CASE, WE MUST handle the size value first
	;(IMPORTANT: DO NOT CHECK FOR VIS_SIZE_IS_SPEC_PAIR HERE.)


	;convert ratio (%) of field window into window bounds

	call	WinCommon_DerefVisSpec_DI
	mov	ax, ds:[di].VI_bounds.R_right
	mov	bx, ds:[di].VI_bounds.R_bottom
	clr	cx			;use parent window to get values
	call	VisConvertRatioToCoords ;returns SpecWinSizePair in ax, bx
	jc	done			;skip if parent has no geometry...
	call	WinCommon_DerefVisSpec_DI

	mov	cx, ax			;(cx, dx) = size value
	mov	dx, bx

	;now check the position value

	test	ds:[di].OLWI_winPosSizeState, mask WPSS_VIS_POS_IS_SPEC_PAIR
	jz	saveSize		;skip if not...

	;convert ratio (%) of parent window into pixel position value

	push	cx, dx			;save size value until after we
					;calculate position, in case query
					;fails miserably
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_top
	clr	cx			;get size of parent window
	call	VisConvertRatioToCoords ;returns SpecWinSizePair in ax, bx

if TOOL_AREA_IS_TASK_BAR

	; If taskbar is at the top of the screen, adjust position
	; so window is below taskbar.

	call	GetTaskBarPositionAdjustment
	add	bx, di			;add adjustment to position

endif

	;
	; We're going to add some code for B/W that allows the edges of windows
	; to sit OUTSIDE of their visual parent, which will avoid unneeded line
	; drawing in both the DisplayControl and a Primary.  We do this
	; regardless of the zeroness of ax and bx, to cover the display control
	; case.  -cbh 2/14/92  (Now in color, too, at least in Motif.  -cbh
	; 12/ 7/92)
	;
	pushf
if	(not _MOTIF)
	call	OpenCheckIfBW
	jnc	dontInset		;color, exit
endif
	dec	ax			;else inset the position a bit.
	dec	bx
dontInset::
	popf
	pop	cx, dx			;get size values
	jc	done			;skip if parent has no size...
	call	WinCommon_DerefVisSpec_DI

	;save position

	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_top, bx

saveSize: ;add size to position info to get right/bottom bounds values
	  ;(cx, dx) = size)
	  ;bp = invalid flags

	add	cx, ds:[di].VI_bounds.R_left
	mov	ds:[di].VI_bounds.R_right, cx

	add	dx, ds:[di].VI_bounds.R_top
	mov	ds:[di].VI_bounds.R_bottom, dx

	;now since we know that position and size are regular pixel values,
	;stored as everybody else in the world expects them, reset our
	;state flags

	and	ds:[di].OLWI_winPosSizeState, not \
				(  mask WPSS_VIS_POS_IS_SPEC_PAIR \
				or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
				or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD)


	;now determine how invalid this window is

	mov	cl, mask VOF_WINDOW_INVALID	;at least window invalid

	pop	ax			;get original winPosSizeState
	push	ax
	test	ax, mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT or \
					mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	jz	markInvalid

	or	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID

markInvalid:
	call	WinCommon_VisMarkInvalid_MANUAL

done:
	pop	ax			;clean up stack
	ret
ConvertSpecWinSizePairsToPixels	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTaskBarPositionAdjustment GetTaskBarSizeAdjustment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get taskbar position/size adjustment

CALLED BY:	INTERNAL

PASS:		*ds:si	= OLWinClass object
RETURN:		di	= position/size adjustment
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TOOL_AREA_IS_TASK_BAR
GetTaskBarPositionAdjustment	proc	far

	;
	; if TOOL_AREA_IS_TASK_BAR
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds

	mov	di, 0					; assume no adjustment (di = 0)
	jz	done					; skip if no taskbar

	;
	; No adjustment for GenDisplay.
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW

	mov	di, 0			; assume no adjustment (di = 0)
	je	done

	;
	; If taskbar is at the top of the screen, adjust position to
	; account for taskbar.
	;

	push	ds, ax					; save ds
	segmov	ds, dgroup				; get dgroup
	mov	ax, ds:[taskBarPrefs]			; load taskBarPrefs in dx
	andnf	ax, mask TBF_POSITION			; mask out everything but the position bits
	cmp	ax, (TBP_TOP) shl offset TBF_POSITION	; compare position bits with TBP_TOP
	pop	ds, ax					; restore ds, ax

	jne	done					; jump if not top position, no adjustment (di = 0)

	;
	; If auto-hide is on, then the adjustment is one pixel.
	;

	push	ds
	segmov	ds, dgroup
	test	ds:[taskBarPrefs], mask TBF_AUTO_HIDE
	pop	ds

	mov	di, 1			; assume auto-hide is on (di = 1)
	jnz	done

	;
	; Else use tool area height.
	;

	push	cx, dx
	call	OLWinGetToolAreaSize
	mov	di, dx			; di = height of tool area (taskbar)
	pop	cx, dx
done:
	ret
GetTaskBarPositionAdjustment	endp

GetTaskBarSizeAdjustment	proc	far

	;
	; if TOOL_AREA_IS_TASK_BAR
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds

	mov	di, 0					; assume no adjustment (di = 0)
	jz	done					; skip if no taskbar

	;
	; No adjustment for GenDisplay.
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW

	mov	di, 0			; assume no adjustment (di = 0)
	je	done

	;
	; If taskbar is at the bottom of the screen, adjust size to
	; account for taskbar.
	;

	push	ds, ax					; save ds
	segmov	ds, dgroup				; get dgroup
	mov	ax, ds:[taskBarPrefs]			; load taskBarPrefs in dx
	andnf	ax, mask TBF_POSITION			; mask out everything but the position bits
	cmp	ax, (TBP_TOP) shl offset TBF_POSITION	; compare position bits with TBP_TOP
	pop	ds, ax					; restore ds

	je	done					; jump if top position, no adjustment (di = 0)

	;
	; If auto-hide is on, then the adjustment is one pixel.
	;

	push	ds
	segmov	ds, dgroup
	test	ds:[taskBarPrefs], mask TBF_AUTO_HIDE
	pop	ds

	mov	di, 1			; assume auto-hide is on (di = 1)
	jnz	done

	;
	; Else use tool area height.
	;

	push	cx, dx
	call	OLWinGetToolAreaSize
	mov	di, dx			; di = height of tool area (taskbar)
	pop	cx, dx
done:
	ret
GetTaskBarSizeAdjustment	endp
endif

WinCommon	ends
WinCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinGetOrCreateTitleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the title-bar group, creating if necessary.

CALLED BY:	MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		cx	= TitleGroupType

RETURN:		^lcx:dx = group
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinGetOrCreateTitleGroup	method dynamic OLWinClass,
					MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP
		.enter
	;
	;  Get the requested group.
	;
CheckHack <offset OLWI_titleBarRightGroup eq (offset OLWI_titleBarLeftGroup+4)>

		mov	bx, cx
		movdw	cxdx, ds:[di+bx].OLWI_titleBarLeftGroup
	;
	;  If the requested group is null, create the thing and
	;  store it before returning.
	;
		tst	dx
		jnz	done
	;
	;  Need to create & store group.
	;
		call	CreateTitleBarGroup		; ^lcx:dx = group
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; block may have moved
		movdw	ds:[di+bx].OLWI_titleBarLeftGroup, cxdx
done:
		.leave
		ret
OLWinGetOrCreateTitleGroup	endm

WinCommon	ends
