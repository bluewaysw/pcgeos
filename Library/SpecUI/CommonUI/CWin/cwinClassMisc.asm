COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinClassMisc.asm

ROUTINES:
	Name			Description
	----			-----------
    INT EnsureHeaderGCMIcons    Ensure Header GCM Icons :)

    INT OLWinCreateGCMChildTrigger
				Creates a GCM child trigger in parent
				object's block, gives it a
				ATTR_GEN_TRIGGER_ACTION_DATA w/OD of parent
				object, adds it with a one-way linkage, &
				SPEC_BUILD's it.

    MTD MSG_GEN_SET_WIN_POSITION
				This method is used by applications to
				override a window's positioning attributes
				and update the window.

    MTD MSG_GEN_SET_WIN_SIZE    This method is used by applications to
				override a window's sizing attributes and
				update the window.

    MTD MSG_GEN_SET_WIN_CONSTRAIN
				This method is used by applications to
				override a window's constrain attributes
				and update the window.

    MTD MSG_OL_WIN_IS_MAXIMIZED Returns whether maximized.

    MTD MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD
				Returns whether default action is navigate
				to next field.

    MTD MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
				Returns whether default action is navigate
				to next field.

    MTD MSG_SPEC_NAVIGATION_QUERY
				This method is used to implement the
				keyboard navigation within-a-window
				mechanism. See method declaration for full
				details.

    INT OpenWinGetHeaderTitleBounds
				This procedure returns the bounds of the
				title area of an OLWinClass object (this is
				the Header area, less the area taken up by
				system icons). This bounds information
				comes directly from the instance data for
				this object - see
				OpenWinCalcWindowheaderGeometry for code
				which sets this instance data.

    MTD MSG_META_FUP_KBD_CHAR   This method is sent by child which 1) is
				the focused object and 2) has received a
				MSG_META_FUP_KBD_CHAR which is does not
				care about. Since we also don't care about
				the character, we forward this method up to
				the parent in the focus hierarchy.

				At this class level, the parent in the
				focus hierarchy is either the generic
				parent (if this is a Display) or
				GenApplication object.

    MTD MSG_OL_WIN_ACTIVATE_DEFAULT_OR_NAVIGATE
				Activate default or navigate if no default

    INT HandleMenuToggling      Figures out whether we should toggle menu
				navigation.

    INT MenuKeyToggles?         See if key press toggles menus.

    INT AnyMouseButtonDown?     Returns non-zero if any mouse button is
				down.  Uses VUP method to do this, so is
				not particularly fast.

    INT HandleMenuNavigation    Handles any menu navigation.

    MTD MSG_OL_WIN_TOGGLE_MENU_NAVIGATION
				A window sends this method to itself when
				then user presses the Alt key, to begin or
				end menu navigation.

    MTD MSG_OL_WIN_QUERY_MENU_BAR
				Returns menu bar handle in cx.  The class
				default is none.

    MTD MSG_OL_WIN_QUERY_MENU_BAR_HAS_FOCUS
				Sees if menu bar currently has the focus.

    MTD MSG_SPEC_NOTIFY_ENABLED Handles notifying an object that it is
				enabled.

    INT SendToChild             Handles notifying an object that it is
				enabled.

    MTD MSG_SPEC_SET_LEGOS_LOOK Set the hints on a window according to the
				legos look requested, after removing the
				hints for its previous look. these hintes
				are stored in tables that each different
				SpecUI will change according to the legos
				looks they support.

    MTD MSG_SPEC_GET_LEGOS_LOOK Get the legos look.

    MTD MSG_OL_WIN_CHECK_IF_POTENTIAL_NEXT_WINDOW
				see if this window should be "next window"
				for Alt-F6 function.

    MTD MSG_OL_WIN_CLEAR_TOGGLE_MENU_NAV_PENDING
				clears OLWMS_TOGGLE_MENU_NAV_PENDING

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinClass.asm

DESCRIPTION:

	$Id: cwinClassMisc.asm,v 1.2 98/03/11 06:07:49 joon Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLWinClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------------------------------


WinClasses	segment resource

if _GCM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureHeaderGCMIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure Header GCM Icons :)

CALLED BY:

PASS:

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureHeaderGCMIcons	proc	far

;ERROR CHECK: make sure this is a base window!

	call	WinClasses_DerefVisSpec_DI
	mov	bl, ds:[di].OLBWI_gcmFlags

	push	bx
	test	bl, mask GCMF_LEFT_ICON		; see if left icon needed
	jz	noLeftIcon

	tst	ds:[di].OLBWI_gcmLeftIcon
	jnz	noLeftIcon			; skip if already created

	; Create object and SPEC_BUILD_BRANCH
	;
	mov	ax, MSG_OL_WIN_CLOSE
	mov	cx, ds:[LMBH_handle]		; destination is self
	mov	dx, si
	mov	di, handle GCMHeaderExitMoniker
	mov	bp, offset GCMHeaderExitMoniker
	call	OLWinCreateGCMChildTrigger
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLBWI_gcmLeftIcon, dx	; save away chunk

noLeftIcon:
	pop	bx

	ret
EnsureHeaderGCMIcons	endp
endif	; _GCM


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinCreateGCMChildTrigger

DESCRIPTION:	Creates a GCM child trigger in parent object's block,
		gives it a ATTR_GEN_TRIGGER_ACTION_DATA w/OD of parent object,
		adds it with a one-way linkage, & SPEC_BUILD's it.

CALLED BY:	INTERNAL

PASS:		*ds:si	- parent for trigger
		ax	- actionMessage to set
		^lcx:dx	- destination to set
		^ldi:bp - VisMoniker/VisMonikerList for trigger

RETURN:		^lcx:dx	- trigger

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@


if _GCM

OLWinCreateGCMChildTrigger	proc	near	uses	ax, bx
	.enter
	mov	bx, HINT_GCM_SYS_ICON
	stc				; one-way upward link
	call	OpenCreateChildTrigger
	push	cx
	xchg	si, dx			; get *ds:si = GenTrigger object,
					; *ds:dx = parent
	mov	ax, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	cx, size optr
	call	ObjVarAddData
	mov	ax, ds:[LMBH_handle]	; set CXDX data = parent
	mov	ds:[bx].handle, ax
	mov	ds:[bx].chunk, dx
	xchg	si, dx			; get *ds:si = parent,
					; ^lcx:dx = new trigger
	pop	cx
	.leave
	ret

OLWinCreateGCMChildTrigger	endp

endif	; _GCM

WinClasses	ends




ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGenSetWinPosition - MSG_GEN_SET_WIN_POSITION

DESCRIPTION:	This method is used by applications to override a window's
		positioning attributes and update the window.

PASS:		*ds:si	= instance data for object
		dl = VisUpdateMode
		dh = WinPositionType (WPS_AT_RATIO, etc)
		cx = X position (SpecWinSizeSpec)
		bp = Y position (SpecWinSizeSpec)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinGenSetWinPosition	method dynamic	OLWinClass, MSG_GEN_SET_WIN_POSITION
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ OL_BAD_VIS_UPDATE_MODE					>
;EC <	test	dh, not WinPositionType					>
;EC <	ERROR_NZ OL_BAD_WIN_POSITION_TYPE				>

	mov	bx, bp			;bx = Y position

	;first get two offsets which can be used to update instance data

	lea	bp, ds:[di].VI_bounds	;set ds:bp = VI_bounds
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	pushf				;save result for later
	pushf
	add	di, offset offset OLWI_winPosSizeFlags
	popf
	jz	haveOffsets		;skip if not maximized...

	;window is maximized: update offsets so that we save this new info
	;in the "Previous State" area. Will be used when window is un-maximized.

	add	di, (offset OLWI_prevWinPosSizeFlags - offset OLWI_winPosSizeFlags)
	add	bp, (offset OLWI_prevWinBounds) - (offset VI_bounds)

haveOffsets:
	;Now ds:di points to OLWI_winPosSizeFlags/State or
	;OLWI_prevWinPosSizeFlags/State, and ds:bp points to VI_bounds
	;OR OLWI_prevWinBounds

	cmp	dh, WPT_AT_SPECIFIC_POSITION
	jne	checkIfRatio

	xchg	di, bp			;SAVE BYTES here
					;pass ds:di = Rectangle
					;ds:[bp]+2 = winPosSizeState field
	call	EnsureRightBottomBoundsAreIndependent
	xchg	di, bp

	and	byte ptr ds:[di]+2, not mask WPSS_VIS_POS_IS_SPEC_PAIR
					;SPEC_BUILD must examine to convert
					;to pixel units.
	cmp	ds:[bp].R_left, cx
	jne	10$
	cmp	ds:[bp].R_top, bx
10$:
	pushf				;save whether any change happening
	mov	ds:[bp].R_left, cx	;set new position values
	mov	ds:[bp].R_top, bx

	xchg	di, bp			;SAVE BYTES here
					;pass ds:di = Rectangle
					;ds:[bp]+2 = winPosSizeState field
	call	EnsureBoundsAreDependent	;make "chris hawley" bounds
						;  if no spec stuff left now
	xchg	di, bp
	popf
	jne	setFlags		;something changing go invalidate stuff
	jmp	short done		;else get out

checkIfRatio:
	cmp	dh, WPT_AT_RATIO		;ratio?
	jne	setFlags			;skip if not...

	;first make sure that the size of this object is not descibed using
	;the difference between bounds values.

	xchg	di, bp			;SAVE BYTES here
					;pass ds:di = Rectangle
					;ds:[bp]+2 = winPosSizeState field
	call	EnsureRightBottomBoundsAreIndependent
	xchg	di, bp

	or	byte ptr ds:[di]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR
					;SPEC_BUILD must examine to convert
					;to pixel units.
	mov	ds:[bp].R_left, cx	;set new position values
	mov	ds:[bp].R_top, bx

setFlags: ;check passed position mode
	mov	al, dh			;al = WinPositionType
	clr	ah
	mov	cl, offset WPSF_POSITION_TYPE
	shl	ax, cl

					;clear WinPositionType
	ANDNF	{word} ds:[di]+0, not mask WPSF_POSITION_TYPE
	ORNF	ds:[di]+0, ax		;set winPosSizeFlags (WinPositionType)
	ORNF	{word} ds:[di]+2, mask WPSS_POSITION_INVALID or \
						mask WPSS_HAS_MOVED_OR_RESIZED
					;set winPosSizeState

	;if window is maximized we are done. When window is RESTORED,
	;this info will be applied.

	popf
	pushf
	jnz	done			;skip if maximized...

;updateWindow:
	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(Note: if parent geometry is not yet valid, this does nothing)

	push	dx
	call	ConvertSpecWinSizePairsToPixels

	;now update the window according to new info. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to do this.
					;(VisSetSize call will set window
					;invalid)

	pop	dx			;get VisUpdateMode

	mov	cl, mask VOF_WINDOW_INVALID
	call	VisMarkInvalid

done:
	popf				;cleanup stack
	ret
OpenWinGenSetWinPosition	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGenSetWinSize - MSG_GEN_SET_WIN_SIZE

DESCRIPTION:	This method is used by applications to override a window's
		sizing attributes and update the window.

PASS:		*ds:si	= instance data for object
		dl = VisUpdateMode
		dh = WinSizeType (WPS_AS_RATIO, etc)
		cx = width (SpecWinSizeSpec)
		bp = height (SpecWinSizeSpec)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinGenSetWinSize	method dynamic	OLWinClass, MSG_GEN_SET_WIN_SIZE
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ OL_BAD_VIS_UPDATE_MODE					>
;EC <	test	dh, not WinSizeType					>
;EC <	ERROR_NZ OL_BAD_WIN_SIZE_TYPE					>

	mov	bx, bp			;bx = height info if any

	;first get two offsets which can be used to update instance data

	lea	bp, ds:[di].VI_bounds	;set ds:bp = VI_bounds
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	pushf				;save result for later
	pushf
	add	di, offset offset OLWI_winPosSizeFlags
	popf
	jz	haveOffsets		;skip if not maximized...

	;window is maximized: update offsets so that we save this new info
	;in the "Previous State" area. Will be used when window is un-maximized.

	add	di, (offset OLWI_prevWinPosSizeFlags - offset OLWI_winPosSizeFlags)
	add	bp, (offset OLWI_prevWinBounds) - (offset VI_bounds)

haveOffsets:
	;Now ds:di points to OLWI_winPosSizeFlags/State or
	;OLWI_prevWinPosSizeFlags/State, and ds:bp points to VI_bounds
	;OR OLWI_prevWinBounds

	mov	ax, mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD

	cmp	dh, WST_AS_RATIO_OF_FIELD
	je	haveRatio		;skip if stuffing value...

	cmp	dh, WST_AS_RATIO_OF_PARENT
	jne	setFlags		;skip if stuffing value...

	mov	ax, mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT

haveRatio:
	;stuff sizing value into visible bounds. Will be converted later.
	;set "VIS_BOUNDS_IS_SPEC_PAIR_" flags

	or	ds:[di]+2, ax		;set WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT
					;or WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	mov	ds:[bp].R_right, cx	;save size info in bounds
	mov	ds:[bp].R_bottom, bx

setFlags: ;check passed size mode
	mov	al, dh			;al = WinSizeType
	clr	ah
	mov	cl, offset WPSF_SIZE_TYPE
	shl	ax, cl

					; clear WinSizeType
	ANDNF	{word} ds:[di]+0, not mask WPSF_SIZE_TYPE
	ORNF	ds:[di]+0, ax		;set winPosSizeFlags (WinSizeType)
	ORNF	{word} ds:[di]+2, mask WPSS_SIZE_INVALID or \
						mask WPSS_HAS_MOVED_OR_RESIZED
					;set winPosSizeState

	;if window is maximized we are done. When window is RESTORED,
	;this info will be applied.

	popf
	pushf
	jnz	done			;skip if maximized...

;updateWindow:
	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(Note: if parent geometry is not yet valid, this does nothing)

	push	dx
	call	ConvertSpecWinSizePairsToPixels

	;now update the window according to new info. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to do this.
					;(VisSetSize call will set window
					;invalid)

	pop	dx			;get VisUpdateMode
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID \
					or mask VOF_IMAGE_INVALID
	call	VisMarkInvalid

done:
	popf				;cleanup stack
	ret
OpenWinGenSetWinSize	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGenSetWinConstrain - MSG_GEN_SET_WIN_CONSTRAIN

DESCRIPTION:	This method is used by applications to override a window's
		constrain attributes and update the window.

PASS:		*ds:si	= instance data for object
		dl = VisUpdateMode
		dh = WinConstrainType (WCT_KEEP_VISIBLE, etc)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinGenSetWinConstrain	method dynamic	OLWinClass,
					MSG_GEN_SET_WIN_CONSTRAIN

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ OL_BAD_VIS_UPDATE_MODE					>
;EC <	cmp	dh, WinConstrainType					>
;EC <	ERROR_NZ OL_BAD_WIN_CONSTRAIN_TYPE				>

	mov	bx, bp			;bx = height info if any

	;first get two offsets which can be used to update instance data

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	pushf				;save result for later
	pushf
	add	di, offset offset OLWI_winPosSizeFlags
	popf
	jz	haveOffsets		;skip if not maximized...

	;window is maximized: update offsets so that we save this new info
	;in the "Previous State" area. Will be used when window is un-maximized.

	add	di, (offset OLWI_prevWinPosSizeFlags - offset OLWI_winPosSizeFlags)
haveOffsets:
	;Now ds:di points to OLWI_winPosSizeFlags/State or
	;OLWI_prevWinPosSizeFlags/State.

	mov	al, dh			;al = WinConstrainType
	clr	ah
	mov	cl, offset WPSF_CONSTRAIN_TYPE
	shl	ax, cl

	ANDNF	ds:[di]+0, not (mask WPSF_CONSTRAIN_TYPE)
	ORNF	ds:[di]+0, ax		;set winPosSizeFlags
;	ORNF	{word} ds:[di]+2, mask WPSS_POSITION_INVALID
;					;set winPosSizeState

	;if window is maximized we are done. When window is RESTORED,
	;this info will be applied.

	popf
	pushf
	jnz	done			;skip if maximized...

;updateWindow:
	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(Note: if parent geometry is not yet valid, this does nothing)

	push	dx

	;now update the window according to new info. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to do this.
					;(VisSetSize call will set window
					;invalid)

	pop	dx			;get VisUpdateMode
	mov	cl, mask VOF_WINDOW_INVALID
	call	VisMarkInvalid

done:
	popf				;cleanup stack
	ret
OpenWinGenSetWinConstrain	endm

ActionObscure	ends



;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIsMaximized --
		MSG_OL_WIN_IS_MAXIMIZED for OLWinClass

DESCRIPTION:	Returns whether maximized.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_IS_MAXIMIZED

RETURN:		carry set if maximized
		ax, cx, dx, bp - preserved

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 6/92		Initial Version

------------------------------------------------------------------------------@

OLWinIsMaximized	method dynamic	OLWinClass, \
				MSG_OL_WIN_IS_MAXIMIZED
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	exit			;not maximizable, exit, carry clear
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	exit			;not maximized, exit carry clear
	stc				;else set carry
exit:
	ret
OLWinIsMaximized	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIsDefaultActionNavigateToNextField --
		MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD for
		OLWinClass

DESCRIPTION:	Returns whether default action is navigate to next field.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD

RETURN:		carry set if default action is navigate to next field
		ax, cx, dx, bp - preserved

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/28/92		Initial Version

------------------------------------------------------------------------------@

OLWinIsDefaultActionNavigateToNextField	method dynamic	OLWinClass, \
			MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD
	test	ds:[di].OLWI_moreFixedAttr, \
			mask OWMFA_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
	jz	exit			;not navigate, exit, carry clear
	stc				;else set carry
exit:
	ret
OLWinIsDefaultActionNavigateToNextField	endm

WinMethods	ends




KbdNavigation	segment resource

OpenWinSpecNavigateToPreviousField	method dynamic	OLWinClass, \
					MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
	mov	bp, mask NF_TRAVEL_CIRCUIT or mask NF_BACKTRACK_AFTER_TRAVELING
					;pass flags: we are trying to navigate
					;backards.
					;pass ds:di = VisSpec instance data
	call	OpenWinNavigateCommon
	ret
OpenWinSpecNavigateToPreviousField	endm

KbdNavigation	ends



;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLWinClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLWinClass handler:
	    This OLWinClass object serves as the root-level node of the
	    visible tree in this window. It can receive this method
	    in two situations:
		1) a MSG_SPEC_NAVIGATE_TO_NEXT/PREVIOUS_FIELD method
		was sent, travelled up the visible tree to this node,
		and this MSG_SPEC_NAVIGATION_QUERY was sent to this object,
		seeking the first leaf node in this window in which no object
		has the focus exclusive. (If there was an object which
		had the focus exclusive, the MSG_SPEC_NAVIGATION_QUERY
		method dynamic would have been sent directly to it.)

		2) Case 1 applied, and the MSG_SPEC_NAVIGATION_QUERY
		travelled through one or more visible children of this window.
		After reaching the last child, it was sent up through the
		parent linkages back to this object. Since the navigation
		path forms a circuit, we must wrap around from the last node
		to the first node in the list by sending this method to
		our first visible child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OpenWinNavigate	method dynamic	OLWinClass, MSG_SPEC_NAVIGATION_QUERY
	;ERROR CHECKING is in VisNavigateCommon

	;call utility routine, passing flags to indicate that this is
	;the root-level composite node, and that this object cannot
	;get the FOCUS_EXCLUSIVE (windows such as this one CAN get
	;the FOCUS_EXCLUSIVE, that is a different mechanism altogether).
	;This routine will check the passed NavigationFlags and decide
	;what to respond.

	mov	bl, mask NCF_IS_ROOT_NODE or mask NCF_IS_COMPOSITE
					;pass flags: is root node, is composite,
					;is not focusable.
	clr	di			;should be no reason to scan hints in
					;this object.
	call	VisNavigateCommon
	ret
OpenWinNavigate	endm

WinMethods	ends

;-------------------------------

if	_FXIP
RegionResourceXIP 	segment resource
else
WinCommon	segment resource
endif

if	DRAW_SHADOWS_ON_BW_GADGETS

windowRegionBW	label	Region
	; Implied Bounds (UL - LR): (PARAM_0, PARAM_1) - (PARAM_2, PARAM_3)
	word	PARAM_1-1,					EOREGREC
	word	PARAM_1,	PARAM_0,   PARAM_2-1,		EOREGREC
	word	PARAM_3-1,	PARAM_0,   PARAM_2,		EOREGREC
	word	PARAM_3,	PARAM_0+1, PARAM_2,		EOREGREC
	word	EOREGREC

endif	; end of if DRAW_SHADOWS_ON_BW_GADGETS

; NOTE: _ROUND_THICK_DIALOGS and DRAW_SHADOWS_ON_BW_GADGETS are
; mutually exclusive!

if	_ROUND_THICK_DIALOGS

; Define a region with rounded corners and thicker edges.
; Coincidentally, the Jedi and Stylus windows have the same
; mask region, so we don't define a new one for Jedi.

; This affects the region used to draw the window as defined in
; Stylus/Win/winDraw.asm (label: STWindow_thickDialogBorder).  Also,
; it affects the title bar button shapes defined in copenButtonData.asm
; (labels: STBWButton_titleLeftInterior and STBWButton_titleRightInterior).

windowRegionBW	label	Region
	; Implied Bounds (UL - LR): (PARAM_0, PARAM_1) - (PARAM_2, PARAM_3)

	word	PARAM_1-1,					EOREGREC
	word	PARAM_1,    PARAM_0+4, PARAM_2-4,		EOREGREC
	word	PARAM_1+1,  PARAM_0+2, PARAM_2-2,		EOREGREC
	word	PARAM_1+3,  PARAM_0+1, PARAM_2-1,		EOREGREC
	word	PARAM_3-4,  PARAM_0,   PARAM_2,			EOREGREC
	word	PARAM_3-2,  PARAM_0+1, PARAM_2-1,		EOREGREC
	word	PARAM_3-1,  PARAM_0+2, PARAM_2-2,		EOREGREC
	word	PARAM_3,    PARAM_0+4, PARAM_2-4,		EOREGREC
	word	EOREGREC
endif	;_ROUND_THICK_DIALOGS


if _FXIP
RegionResourceXIP	ends
else
WinCommon	ends
endif


;------------------





Resident	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetTitleBounds

DESCRIPTION:	This procedure returns the bounds of the title area
		of an OLWinClass object (this is the Header area,
		less the area taken up by system icons).
		This bounds information comes directly from the instance
		data for this object - see OpenWinCalcWindowheaderGeometry
		for code which sets this instance data.

CALLED BY:	utility

PASS:		ds:*si	- handle of instance data

RETURN:		(ax, bx, cx, dx) = bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version

------------------------------------------------------------------------------@

OpenWinGetHeaderTitleBounds	proc	far
	class	OLWinClass

	push	di
	call	Res_DerefVisDI
	mov	ax, ds:[di].OLWI_titleBarBounds.R_left
	mov	bx, ds:[di].OLWI_titleBarBounds.R_top
	mov	cx, ds:[di].OLWI_titleBarBounds.R_right
	mov	dx, ds:[di].OLWI_titleBarBounds.R_bottom
	pop	di
	ret
OpenWinGetHeaderTitleBounds	endp

Resident	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinFupKbdChar - MSG_META_FUP_KBD_CHAR handler for OLWinClass

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		either the generic parent (if this is a Display) or
		GenApplication object.

PASS:		*ds:si	= instance data for object
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
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OpenWinFupKbdChar	method dynamic	OLWinClass,
					MSG_META_FUP_KBD_CHAR

if HANDLE_MENU_TOGGLING
   	call	HandleMenuToggling		;handle menu toggling.
	LONG jc	done				;menu was toggled, we're done
endif
						;pass ds:di = instance data
	call	HandleMenuNavigation		;do menu navigation, if needed
	LONG jc	done				;handled, exit

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	LONG jnz sendUpFocusHierarchy		;let application deal with these

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	LONG jz	sendUpFocusHierarchy		;skip if not press event...

if _KBD_NAVIGATION	;------------------------------------------------------
	push	es
						;set es:di = table of shortcuts
						;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLWinKbdBindings
	call	ConvertKeyToMethod
	pop	es
	LONG jc	sendMethod			;skip if found...
endif	;----------------------------------------------------------------------

if _CR_DEFAULT		;------------------------------------------------------
	push	es
						;set es:di = table of shortcuts
						;and matching methods
	segmov	es, cs
	mov	di, offset OLWinKbdBindings2
	call	ConvertKeyToMethod
	pop	es
	LONG jc	sendMethod			;skip if found...
endif	;----------------------------------------------------------------------

	;Try using the character as a mnemonic, unless some stay-up window
	;currently has the focus exclusive.  (I'm not sure why this is done.
	;Presumably the opened menu will be checked first.  -cbh 10/13/93)

	call	KN_DerefVisSpec_DI
	test	ds:[di].OLWI_menuState, mask OLWMS_HAS_MENU_IN_STAY_UP_MODE
	jnz	tryAccelerators			;has stay up menu, skip

	test	dh, CTRL_KEYS			;are these down?
	jnz	tryAccelerators			;yes, forget mnemonics

	; No mnemonic check if not in focus tree - brianc 10/3/94

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_SYS_EXCL
	jz	tryAccelerators

	push	cx, dx, bp
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	jc	done				;mnemonic found, exit

tryAccelerators:
	;Before sending up the key to the application, to look for application
	;accelerators, we'll look for accelerators in this window's system menu
	;(if CUAS) or popup menu (if OLS).
	;ISUI: we need to check for a custom sys menu before checking the
	;    standard sys menu.

if _ISUI
	call	KN_DerefVisSpec_DI
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW	;only primaries have
	jne	checkSysMenu				; custom sys menus
	mov	bx, ds:[di].OLBWI_titleBarMenu.handle	;custom sys menu handle
	tst	bx
	jz	checkSysMenu
	push	si, cx, dx, bp
	mov	si, ds:[di].OLBWI_titleBarMenu.chunk
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	ObjMessage
	pop	si, cx, dx, bp
	jc	foundKbdAccel				;found, branch
checkSysMenu:
endif

	call	KN_DerefVisSpec_DI
OLS <	mov	bx, ds:[di].OLWI_menu		;get popup menu button handle >
CUAS <	mov	bx, ds:[di].OLWI_sysMenu	;get system menu button handle>
	tst	bx				;is there one?
	jz	10$				;no, branch

	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	10$
	push	si, cx, dx, bp
	mov	si, offset StandardWindowMenu
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	call	ObjMessage
	pop	si, cx, dx, bp
	jnc	10$				;nothing found, branch

	;found and executed kbd accelerator --
	;call a utility routine to send a method to the Flow object that
	;will force the dismissal of all menus in stay-up-mode.
foundKbdAccel:
	call	OLReleaseAllStayUpModeMenus
	jmp	short handled
10$:

sendUpFocusHierarchy:
	;we don't care about this keyboard event. Forward it up the
	;focus hierarchy.

	mov	ax, MSG_META_FUP_KBD_CHAR
					; call GenApplication or GenParent
					; (must be call, as is in different
					; resource)
	call	OpenWinCallParentOfWindow
	ret

sendMethod:
	;found a shortcut: send method to self.

	call	ObjCallInstanceNoLock
handled:
	stc				  ;say handled
done:
	ret
OpenWinFupKbdChar	endm

if _KBD_NAVIGATION	;------------------------------------------------------

;Keyboard shortcut bindings for OLWinClass (do not separate tables)

OLWinKbdBindings	label	word
	word	length OLWShortcutList


if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLWShortcutList KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;next field
	<0, 0, 0, 1, C_SYS_TAB and mask KS_CHAR>,	;previous field
	<0, 0, 1, 0, C_SYS_TAB and mask KS_CHAR>,	;next field
	<0, 0, 1, 1, C_SYS_TAB and mask KS_CHAR>,	;previous field
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR> ,	;PREVIOUS FIELD
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;NEXT FIELD
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>	;PREVIOUS FIELD
else
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLWShortcutList	KeyboardShortcut \
		<0, 0, 0, 0, 0xf, VC_TAB>,	;NEXT FIELD
		<0, 0, 0, 1, 0xf, VC_TAB>,	;PREVIOUS FIELD
		<0, 0, 1, 0, 0xf, VC_TAB>,	;NEXT FIELD
		<0, 0, 1, 1, 0xf, VC_TAB>,	;PREVIOUS FIELD
		<0, 0, 0, 0, 0xf, VC_DOWN>,	;NEXT FIELD
		<0, 0, 0, 0, 0xf, VC_UP>,	;PREVIOUS FIELD
		<0, 0, 0, 0, 0xf, VC_RIGHT>,	;NEXT FIELD
		<0, 0, 0, 0, 0xf, VC_LEFT>	;PREVIOUS FIELD
endif

	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD

endif	;----------------------------------------------------------------------

if _CR_DEFAULT		;------------------------------------------------------

;Keyboard shortcut bindings for OLWinClass (do not separate tables)

OLWinKbdBindings2	label	word
	word	length OLWShortcutList2
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLWShortcutList2 KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>	;activate default
else

OLWShortcutList2	KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_ENTER>	;ACTIVATE DEFAULT
endif
;OLWMethodList2	label word
	word	MSG_GEN_ACTIVATE_INTERACTION_DEFAULT

endif	;----------------------------------------------------------------------

KbdNavigation	ends

;-------------------------------

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleMenuToggling

SYNOPSIS:	Figures out whether we should toggle menu navigation.

CALLED BY:	OpenWinFupKbdChar

PASS:		*ds:si -- handle
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/90		Initial version

------------------------------------------------------------------------------@

if HANDLE_MENU_TOGGLING

HandleMenuToggling	proc	near
	class	OLWinClass

	;
	; Allow escape to toggle in displays, so the right thing happens.
	; -cbh 11/24/92
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_ESCAPE	;escape key?	>
DBCS <	cmp	cx, C_SYS_ESCAPE			;escape key?	>
	je	checkToggling				;yes, allow toggling


	call	KN_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
OLS  <	cmp	ds:[di].OLWI_type, OLWT_DISPLAY_WINDOW			>
     	je	notHandled

checkToggling:

	;first check for ALT presses and releases

	call	MenuKeyToggles?				;well, does it?
							;do not trash ds:di
	jz	resetAndExitNotHandled			;no, move on
	jc	sendToggle				;yes, and do it NOW
							;else wait for release
;isToggleKey:
	;
	; On the alt and F10 key presses, we'll toggle on the release, provided
	; no other keys have come along in the meantime.
	;
	test	dl, mask CF_FIRST_PRESS
	jz	10$

	test	ds:[di].OLWI_menuState,mask OLWMS_TOGGLE_MENU_NAV_PENDING
	jnz	resetAndExitNotHandled			;another first press,
							;get out!
	ORNF	ds:[di].OLWI_menuState,mask OLWMS_TOGGLE_MENU_NAV_PENDING
	jmp	short handled				;changed from returning
							;  not handled 12/20/92

10$:	test	dl, mask CF_RELEASE
	jz	notHandled

	test	ds:[di].OLWI_menuState,mask OLWMS_TOGGLE_MENU_NAV_PENDING
	jz	notHandled

sendToggle:
	;
	; Clear the pending flag and send out a toggle method.
	;
	ANDNF	ds:[di].OLWI_menuState, not mask OLWMS_TOGGLE_MENU_NAV_PENDING

	mov	ax, MSG_OL_WIN_TOGGLE_MENU_NAVIGATION
	call	ObjCallInstanceNoLock
handled:
	stc					;say handled
	ret

resetAndExitNotHandled:
	call	KN_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_menuState, not mask OLWMS_TOGGLE_MENU_NAV_PENDING

notHandled:
	clc					;say not handled
	ret
HandleMenuToggling	endp

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	MenuKeyToggles?

SYNOPSIS:	See if key press toggles menus.

CALLED BY:	HandleMenuToggling

PASS:		*ds:si	= instance data for object
		ds:di = pointer to SpecInstance
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		zero flag clear (jnz) if this key toggles the menu bar, with
		    carry set if the press should immediately toggle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       if a menu is up, return not togglable
       elif ALT pressed, return togglable
       elif menu bar has focus
       	    if F10 pressed
	    	return togglable
       elif ESCAPE pressed
       	    return immediately togglable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 4/90		Initial version

------------------------------------------------------------------------------@

if HANDLE_MENU_TOGGLING

MenuKeyToggles?	proc	near
	class	OLWinClass
	;
	; If there's a menu currently up, let's not do any toggling whatsoever.
	;

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	checkToggleKeys				;skip if not doing menus
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_WINDOW
	jnz	notTogglable				;menu up, skip these

checkToggleKeys:
	; not togglable if CTRL-ALT-release ALT or SHIFT-ALT-release ALT
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_LALT	;left ALT key?	>
DBCS <	cmp	cx, C_SYS_LEFT_ALT			;left ALT key?	>
	je	mayBeTogglable				;ya, activate on release
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_RALT	;right ALT key?	>
DBCS <	cmp	cx, C_SYS_RIGHT_ALT			;right ALT key?	>
	jne	10$

mayBeTogglable:
	test	dh, LCTRL or RCTRL or LSHIFT or RSHIFT
	jz	togglable				; yes, if keys NOT down
10$:
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	notDoingMenus				;skip if not doing menus

	;
	; If the menu bar has the focus, escape will toggle.
	;
	test	dh, LCTRL or RCTRL or LALT or RALT or LSHIFT or RSHIFT
	jnz	notTogglable				;must be escape only

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_ESCAPE	;escape key?	>
DBCS <	cmp	cx, C_SYS_ESCAPE			;escape key?	>
	jne	notTogglable				;nope, branch

	call	AnyMouseButtonDown?		; If mouse button down, skip
	jnz	notTogglable

	tst	cl					;else clear zero flag
	stc						;and don't wait for
	ret						;    release.

notDoingMenus:

if _USE_KBD_ACCELERATORS and 0
	;
	; If the menu bar doesn't have the focus, F10 will toggle.
	;
	test	dh, LCTRL or RCTRL or LALT or RALT or LSHIFT or RSHIFT
	jnz	notTogglable				;must be F10 only
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F10	;F10 key?	>
DBCS <	cmp	cx, C_SYS_F10				;F10 key?	>
	jne	notTogglable				;nope, branch
else
	jmp	short notTogglable			;F10 does NOT toggle
endif
							;else activate onrelease
togglable:
	call	AnyMouseButtonDown?		; If mouse button down, skip
	jnz	notTogglable

reallyTogglable:
	tst	cl					;clear zero flag
	jmp	short notImmediate			;and branch

notTogglable:
	test	cl, 0					;set zero flag

notImmediate:
	clc						;toggle on a release
	ret

MenuKeyToggles?	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	AnyMouseButtonDown?

DESCRIPTION:	Returns non-zero if any mouse button is down.  Uses VUP
		method to do this, so is not particularly fast.

CALLED BY:	INTERNAL
		MenuKeyToggles?

PASS:	*ds:si	- visible object

RETURN:	zero flag	- non-zero if mouse button down

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version
------------------------------------------------------------------------------@


if HANDLE_MENU_TOGGLING

AnyMouseButtonDown?	proc	near	uses	ax, cx, dx, bp
	.enter
	;
	; Any buttons down?   If so, don't do any toggling.
	;
	mov	ax, MSG_VIS_VUP_GET_MOUSE_STATUS
	call	ObjCallInstanceNoLock
	mov	ax, bp
	test	al, mask BI_B3_DOWN or mask BI_B2_DOWN or \
		    mask BI_B1_DOWN or mask BI_B0_DOWN
	.leave
	ret

AnyMouseButtonDown?	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleMenuNavigation

SYNOPSIS:	Handles any menu navigation.

CALLED BY: 	OpenWinFupKbdChar

PASS:		*ds:si -- object
		ds:di = instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/90		Initial version

------------------------------------------------------------------------------@

HandleMenuNavigation	proc	near
	class	OLWinClass

if _MENU_NAVIGATION	;------------------------------------------------------
	push	ax   			;save method
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	exitNotHandled		;skip if not press event...

	;if we are navigating the menu bar, Translate:
	;	LEFT_ARROW	= NAVIGATE TO PREVIOUS
	;	RIGHT_ARROW	= NAVIGATE TO NEXT
	;	UP_ARROW	= ACTIVATE (send to focused object -menu button)
	;	DOWN_ARROW	= ACTIVATE (send to focused object -menu button)


	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	exitNotHandled		;skip if not doing menus

	push	es			;set es:di = table of shortcuts
	mov	di, cs			;and matching methods
	mov	es, di
	mov	di, offset cs:OLMenuNavKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	exitNotHandled		;skip if none found...

	;found a shortcut: send method to self.

	cmp	di, OLMNSendToFocus	;send to focused object or menu?
	jl	sendToSelf		;skip to send to menu...

	;trigger the menu button which has the focus exclusive

	call	OpenSaveNavigationChar	;save KBD char in idata so that when
					;menu (and genlist inside it) gains
					;focus, it knows whether to start at
					;top or bottom of the menu/genlist.
	push	si
	call	KN_DerefVisSpec_DI
	mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle

	;just in case we are getting this FUP method late, and the Focus
	;is now nil (John was able to make this happen), test:

	tst	bx			;if OD = nil, then skip to end
	jz	finishUp
	tst	si
	jz	finishUp

if 	ERROR_CHECK
	push	ax, cx, dx, bp
	mov	cx, segment OLButtonClass
	mov	dx, offset  OLButtonClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ERROR_NC	OL_ERROR
	pop	ax, cx, dx, bp
endif
	mov	ax, MSG_OL_BUTTON_KBD_ACTIVATE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

finishUp:
	pop	si

	clr	cx
	call	OpenSaveNavigationChar	;reset our saved KBD char to "none"
					;so that if a menu gains the focus
					;due to mouse usage, the menu does not
					;begin navigation at the bottom item.
exitCarry:
	stc				;key handled
	jmp	exit

sendToSelf:
	call	ObjCallInstanceNoLock
	jmp	exitCarry

exitNotHandled:
	clc				;key not handled
exit:
	pop	ax
endif			;------------------------------------------------------
	ret
HandleMenuNavigation	endp


if _MENU_NAVIGATION	;------------------------------------------------------

;Keyboard shortcut bindings for OLMenuedWinClass, USED ONLY IN CASE WHERE
;we are navigating in the menu bar. (do not separate tables)

OLMenuNavKbdBindings	label	word
	word	length OLMNShortcutList

	;these first key bindings cause a method to be sent to this object
	;(do not move this comment inside the list!

if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLMNShortcutList KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;navigate left
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;navigate right

	;these key bindings cause a method to be sent to the focused object

	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;open menu
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>	;open menu
else

OLMNShortcutList KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;NAVIGATE TO LEFT
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;NAVIGATE TO RIGHT

	;these key bindings cause a method to be sent to the focused object

	<0, 0, 0, 0, 0xf, VC_UP>,	;OPEN MENU
	<0, 0, 0, 0, 0xf, VC_DOWN>	;OPEN MENU
endif


OLMNMethodList	label word

	;these methods are sent to this object (OLMenuedWinClass, so will
	;move FOCUS to next menu button in sequence.

	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD

OLMNMethodListFocus label word

	;these methods are sent to the focused object (menu button)

	word	MSG_GEN_ACTIVATE
	word	MSG_GEN_ACTIVATE

OLMNSendToFocus = (offset OLMNMethodListFocus) - (offset OLMNMethodList)
					;any method past this offset in the
					;above table are send to the focused
					;object (menu button) instead of the
					;menu itself.
endif	;----------------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_OL_WIN_TOGGLE_MENU_NAVIGATION

DESCRIPTION:	A window sends this method to itself when then user
		presses the Alt key, to begin or end menu navigation.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Joon	8/92		PM extensions

------------------------------------------------------------------------------@

if _KBD_NAVIGATION and _MENU_NAVIGATION	;--------------------------------------


;SAVE BYTES: I should be able to do this better. Why can't I use the navigation
;query to find the first menu-related object in the window?

OLWinToggleMenuNavigation	method dynamic	OLWinClass, \
					MSG_OL_WIN_TOGGLE_MENU_NAVIGATION

if HANDLE_MENU_TOGGLING
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jnz	exitMenuBar			;if we currently have focus
						;branch

	;if there's a menu bar, then let's try to give its first child the
	;grab.  Otherwise, we'll give it to the system menu.

	mov	ax, MSG_OL_WIN_QUERY_MENU_BAR
	call	ObjCallInstanceNoLock		;see if there's a menu bar
	tst	cx				;is there one?
	jz	useSysMenu			;no, we'll take whatever we get

if MENU_BAR_IS_A_MENU
	mov	si, cx				;activate the menu bar
	mov	ax, MSG_GEN_ACTIVATE
	GOTO	ObjCallInstanceNoLock
else
	mov	di, cx				;move to di
	mov	di, ds:[di]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	mov	cx, ds:[di].VCI_comp.CP_firstChild.handle
	tst	cx
	jz	useSysMenu			;no children, use system menu

	mov	dx, ds:[di].VCI_comp.CP_firstChild.chunk
	jmp	setFocus
endif	; MENU_BAR_IS_A_MENU

useSysMenu:
	call	KN_DerefVisSpec_DI

if _ISUI
	call	GetSystemMenuBlockHandle	;returns bx = block handle
						; zf - if no titleBarMenu
	mov	ax, offset StandardWindowMenu
	jz	haveSysMenu
	mov	ax, ds:[di].OLBWI_titleBarMenu.chunk
haveSysMenu:
	tst	bx
	jz	exitMenuBar

	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	exitMenuBar

	push	si
	mov	si, ax
else
	mov	bx, ds:[di].OLWI_sysMenu	;start pointing to sys menu
	tst	bx				;any sys menu?
	jz	exitMenuBar			;none, let's give up on this

	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	exitMenuBar

	push	si
	mov	si, offset StandardWindowMenu
endif

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_OL_POPUP_FIND_BUTTON	;point to its button
	call	ObjMessage
	pop	si
	tst	dx				;any button?
	jz	exitMenuBar			;no, let's give up

setFocus:
	mov	bp, mask MAEF_OD_IS_MENU_RELATED or \
		    mask MAEF_GRAB or mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
callAndExit:
	call	ObjCallInstanceNoLock

	; Start a pre-passive grab so we can release the menu focus on ANY
	; mouse click.  -cbh 10/22/90

	call	VisAddButtonPrePassive
exit:
	ret

exitMenuBar:

	; No previous focus exclusive, there's not much point in leaving menu
	; focus mode, so don't do it.  -cbh 12/10/92

	call	KN_DerefVisSpec_DI
	tst	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk
	jz	exit

	mov	ax, MSG_VIS_VUP_RELEASE_MENU_FOCUS
	jmp	callAndExit

else
	ret
endif

OLWinToggleMenuNavigation	endm

endif	;----------------------------------------------------------------------

KbdNavigation	ends




KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinQueryMenuBar --
		MSG_OL_WIN_QUERY_MENU_BAR for OLWinClass

DESCRIPTION:	Returns menu bar handle in cx.  The class default is none.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_QUERY_MENU_BAR

RETURN:		cx 	- menu bar handle, of zero if none

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/90		Initial version

------------------------------------------------------------------------------@

OLWinQueryMenuBar	method dynamic	OLWinClass, MSG_OL_WIN_QUERY_MENU_BAR
	clr	cx				;default is no menu bar.
	ret
OLWinQueryMenuBar	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinMenuBarHasFocus --
		MSG_OL_WIN_QUERY_MENU_BAR_HAS_FOCUS for OLWinClass

DESCRIPTION:	Sees if menu bar currently has the focus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_QUERY_MENU_BAR_HAS_FOCUS

RETURN:		carry set if menu bar has the focus

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@

OLWinQueryMenuBarHasFocus method dynamic OLWinClass, \
					MSG_OL_WIN_QUERY_MENU_BAR_HAS_FOCUS
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	exit			;skip if not (cy=0)...
	stc				;return flag: we have the focus
exit:
	ret
OLWinQueryMenuBarHasFocus	endm

KbdNavigation	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinNotifyEnabled --
		MSG_SPEC_NOTIFY_ENABLED for OLWinClass

DESCRIPTION:	Handles notifying an object that it is enabled.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

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
	chris	12/13/91	Initial Version

------------------------------------------------------------------------------@

OLWinNotifyEnabled	method dynamic	OLWinClass, MSG_SPEC_NOTIFY_ENABLED,
						    MSG_SPEC_NOTIFY_NOT_ENABLED
	push	ax, dx				;save method
	mov	di, offset OLWinClass
	call	ObjCallSuperNoLock		;call superclass
	DoPop	dx, ax				;restore method
	jnc	exit				;no state change, exit

if NORMAL_HEADERS_ON_DISABLED_WINDOWS
						;never disable if normal headers
	cmp	ax, MSG_SPEC_NOTIFY_NOT_ENABLED
	je	afterNotifications
endif
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLWI_sysMenu	;get block that objects are in
	tst	bx
	jz	afterNotifications

	mov	si, ds:[di].OLWI_sysMenuButton
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	pushf
	call	ObjSwapLock
	call	SendToChild			;send to OLWI_sysMenuButton
	popf
	jnz	doneButtonNotify
	mov	si, offset StandardWindowMenu
	call	SendToChild
doneButtonNotify:
	mov	si, offset SMI_MinimizeIcon
	call	SendToChild
	mov	si, offset SMI_MaximizeIcon
	call	SendToChild
	mov	si, offset SMI_RestoreIcon
	call	SendToChild
	call	ObjSwapUnlock

afterNotifications:
	stc					;return state changed
exit:
	ret
OLWinNotifyEnabled	endm

SendToChild	proc	near
	tst	si
	jz	10$
	push	dx, ax
	call	ObjCallInstanceNoLock
	pop	dx, ax
10$:
	ret
SendToChild	endp

if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWSpecSetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hints on a window according to the legos look
		requested, after removing the hints for its previous look.
		these hintes are stored in tables that each different SpecUI
		will change according to the legos looks they support.

CALLED BY:	MSG_SPEC_SET_LEGOS_LOOK
PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		cl	= legos look
RETURN:		carry	= set if the look was invalid (new look not set)
			= clear if the look was valid (new look set)
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWSpecSetLegosLook	method dynamic OLWinClass,
					MSG_SPEC_SET_LEGOS_LOOK
	uses	ax, cx
	.enter

	clr	bx
	mov	bl, ds:[di].OLWI_legosLook
	cmp	bx, LAST_LEGOS_WINDOW_LOOK
	jbe	validExistingLook

	clr	bx		; make the look valid if it wasn't
EC<	WARNING	WARNING_INVALID_LEGOS_LOOK		>

validExistingLook:
	clr	ch
	cmp	cx, LAST_LEGOS_WINDOW_LOOK
	ja	invalidNewLook

	mov	ds:[di].OLWI_legosLook, cl
	;
	; remove hint from old look
	;
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosWindowLookHintTable][bx]
	tst	ax
	jz	noHintToRemove

	call	ObjVarDeleteData

	;
	; add hints for new look
	;
noHintToRemove:
	mov	bx, cx
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosWindowLookHintTable][bx]
	jz	noHintToAdd

	clr	cx
	call	ObjVarAddData

noHintToAdd:
	clc
done:
	.leave
	ret

invalidNewLook:
	stc
	jmp	done
OLWSpecSetLegosLook	endm

	;
	; Make sure this table matches that in cwinClassCommonHigh.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the WinMethods resource at build time, and it
	; is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
legosWindowLookHintTable	label word
	word	0
LAST_LEGOS_WINDOW_LOOK	equ ((($ - legosWindowLookHintTable)/(size word)) - 1)
CheckHack<LAST_LEGOS_WINDOW_LOOK eq LAST_BUILD_LEGOS_WINDOW_LOOK>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWSpecGetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the legos look.

CALLED BY:	MSG_SPEC_GET_LEGOS_LOOK
PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
RETURN:		cl	= legos look
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWSpecGetLegosLook	method dynamic OLWinClass,
					MSG_SPEC_GET_LEGOS_LOOK
	.enter
	mov	cl, ds:[di].OLWI_legosLook
	.leave
	ret
OLWSpecGetLegosLook	endm



endif		; if _HAS_LEGOS_LOOKS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinRotateDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize ourselves

CALLED BY:	MSG_GEN_ROTATE_DISPLAY

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if RECTANGULAR_ROTATION

OLWinRotateDisplay	method dynamic OLWinClass, MSG_GEN_ROTATE_DISPLAY
		.enter

	;
	;  Set flag for OpenWinSaveState, so it'll save new window
	;  position and size in case application is shut down.
	;
		ornf	ds:[di].OLWI_winPosSizeState, \
				mask WPSS_HAS_MOVED_OR_RESIZED
	;
	;  Set the Magic Flag that will cause our Window to be sized
	;  the same as the parent, plus all the other necessary shme.
	;
		ornf	ds:[di].OLWI_winPosSizeState, mask WPSS_SIZE_INVALID

		mov	ax, MSG_VIS_MOVE_RESIZE_WIN
		call	ObjCallInstanceNoLock

noWindow:
	;
	;  Invalidate children.
	;
		mov	dl, VUM_MANUAL
		mov	ax, MSG_VIS_INVAL_ALL_GEOMETRY
		call	ObjCallInstanceNoLock
	;
	;  Force redraw.
	;
		mov	cl, mask VOF_GEOMETRY_INVALID \
				or mask VOF_WINDOW_INVALID \
				or mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_MARK_INVALID
		call	ObjCallInstanceNoLock

		.leave
		ret
OLWinRotateDisplay	endm

endif	; RECTANGULAR_ROTATION

WinMethods ends


KbdNavigation	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinCheckIfPotentiatNextWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if this window should be "next window" for Alt-F6
		function.

CALLED BY:	MSG_OL_WIN_CHECK_IF_POTENTIAL_NEXT_WINDOW

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		es 	= segment of OLWinClass
		ax	= MSG_OL_WIN_CHECK_IF_POTENTIAL_NEXT_WINDOW

RETURN:		carry set if so

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/11/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinCheckIfPotentiatNextWindow	method	dynamic	OLWinClass,
				MSG_OL_WIN_CHECK_IF_POTENTIAL_NEXT_WINDOW
	test	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE
	jz	done			; not focusable (carry clear)
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_NO_DISTURB
	jnz	done			; not focusable (carry clear)
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	done			; not realized (carry clear)
	stc				; else, allow becoming "next window"
done:
	ret
OLWinCheckIfPotentiatNextWindow	endm

KbdNavigation	ends

;--------------------

CommonFunctional segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinClearToggleMenuNavPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears OLWMS_TOGGLE_MENU_NAV_PENDING

CALLED BY:	MSG_OL_WIN_CLEAR_TOGGLE_MENU_NAV_PENDING

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		es 	= segment of OLWinClass
		ax	= MSG_OL_WIN_CLEAR_TOGGLE_MENU_NAV_PENDING

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinClearToggleMenuNavPending	method	dynamic	OLWinClass,
				MSG_OL_WIN_CLEAR_TOGGLE_MENU_NAV_PENDING
	andnf	ds:[di].OLWI_menuState, not mask OLWMS_TOGGLE_MENU_NAV_PENDING
	ret
OLWinClearToggleMenuNavPending	endm

CommonFunctional ends
