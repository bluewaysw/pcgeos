COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1996.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		copenCtrlClass.asm

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS 
				Scans geometry hints.

    INT DoCtrlHints             Scans geometry hints.

    INT CtrlProperty            Scans geometry hints.

    INT CtrlNotProperty         Scans geometry hints.

    INT CtrlWrapAfterChildCount Scans geometry hints.

    INT CtrlWrapAfterChildCountIfVerticalScreen 
				Scans geometry hints.

    INT CtrlDivideWidthEqually  Scans geometry hints.

    INT CtrlDivideHeightEqually Scans geometry hints.

    INT CtrlExpandHeightToFitParent 
				Scans geometry hints.

    INT CtrlNoTallerThanChildrenRequire 
				Scans geometry hints.

    INT CtrlAllowChildrenToWrap Scans geometry hints.

    INT CtrlDontAllowChildrenToWrap 
				Scans geometry hints.

    INT CtrlOrientVertically    Scans geometry hints.

    INT CtrlOrientHorizontally  Scans geometry hints.

    INT CtrlOrientChildrenAlongLargerDimension 
				Scans geometry hints.

    INT CtrlTopJustify          Scans geometry hints.

    INT CtrlCenterVertically    Scans geometry hints.

    INT CtrlBottomJustify       Scans geometry hints.

    INT CtrlLeftJustify         Scans geometry hints.

    INT CtrlCenterHorizontally  Scans geometry hints.

    INT CtrlRightJustify        Scans geometry hints.

    INT CtrlSameOrientationAsParent 
				Copy parent's orientation down to ourselves

    INT CtrlJustify             Sets up justification.

    INT CtrlFullJustifyVertically 
				Sets up justification.

    INT CtrlFullJustifyHorizontally 
				Sets up justification.

    INT CtrlIncludeEndsInSpacing 
				Sets up justification.

    INT CtrlNoEndsInSpacing     Sets up justification.

    INT CtrlDontFullJustify     Sets up justification.

    INT CtrlExpandWidthToFitParent 
				Sets up justification.

    INT CtrlNoWiderThanChildrenRequire 
				Sets up justification.

    INT CtrlDoNotUseMoniker     Sets up justification.

    INT CtrlPlaceMonikerToLeft  Sets up justification.

    INT CtrlPlaceMonikerToRight Sets up justification.

    INT CtrlCenterMoniker       Sets up justification.

    INT CtrlAlignLeftMonikerEdgeWithChild 
				Sets up justification.

    INT CtrlPlaceMonikerAbove   Sets up justification.

    INT CtrlPlaceMonikerAlongLargerDimension 
				Sets up justification.

    INT CtrlDrawInBox           Sets up justification.

    INT CtrlCenterByMonikers    Sets up justification.

    INT CtrlSetCustomSpacing    Sets up justification.

    INT CtrlMakeReplyBar        Sets up justification.

    INT CtrlSetMinSize          Sets up justification.

    MTD MSG_SPEC_CTRL_SET_MORE_FLAGS 
				Sets more flags

    INT CtrlBuild_DerefVisSpecDI 
				We intercept this method here, for the case
				where this button is inside a menu. We want
				to update the separators which are drawn
				within the menu.

    MTD MSG_SPEC_CTRL_UPDATE_CENTER_STUFF 
				Sent upwards from OLCtrl children to make
				sure center-by- monikers stuff is
				recalculated.

    INT CenterByMonikers        Returns carry set if the composite wants
				its children centered by monikers. Called
				by children so they can set their own flag.

    INT LeftJustifyMonikers     Returns carry set if the composite wants
				its children centered by monikers. Called
				by children so they can set their own flag.

    MTD MSG_SPEC_UNBUILD_BRANCH We intercept this method here, for the case
				where this OLCtrl is in title bar.

    MTD MSG_SPEC_NAVIGATION_QUERY 
				Navigation query.

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL 
				Gains system focus exclusive.

    MTD MSG_META_LOST_SYS_FOCUS_EXCL 
				Gains system focus exclusive.

    MTD MSG_SPEC_NOTIFY_CHILD_CHANGING_FOCUS 
				Notifies us that the child is either losing
				or gaining the focus, so we can jump
				through hoops if we're centering on
				monikers.

    MTD MSG_SPEC_NOTIFY_NO_RIGHT_ARROW 
				Notifies the control that there should be
				no right arrow.

    INT ActivateFirstGenChild   Activate first gen child, handling text
				objects specially.

    INT FocusFirstChildCallback find first focusable child

    INT GetParentMonikerSpace   Returns space reserved for moniker in
				center-by-moniker situations.

    INT GetNonMonikerMarginTotals 
				Returns margins, without the moniker.
				Should stay equivalent to the get spacing
				routine!

    INT OpenPassMarginInfo      Sets up margin info, if needed, for
				MSG_VIS_RECALC_SIZE. Checks to see if our
				margins and spacing can even fit in a
				margin info word.  And if we're wrapping,
				we better have the same wrap spacing as
				regular spacing, or forget it.

    MTD MSG_SPEC_MENU_SEP_QUERY Handles a menu separator query in a minimal
				way.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenCtrl.asm

DESCRIPTION:

	$Id: copenCtrlClass.asm,v 1.2 98/03/11 05:48:57 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonUIClassStructures segment resource

if NOTEBOOK_INTERACTION
	NotebookBinderClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
	NotebookPageClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
endif

	OLCtrlClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	method	VupCreateGState, OLCtrlClass, MSG_VIS_VUP_CREATE_GSTATE
	
;	method	VisCallParent, OLCtrlClass, MSG_VIS_VUP_RELEASE_ALL_MENUS
	method	VisCallParent, OLCtrlClass, MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS
	method	VisCallParentEnsureStack, OLCtrlClass, MSG_VIS_VUP_RELEASE_MENU_FOCUS
	method	VisCallParentEnsureStack, OLCtrlClass, MSG_OL_VUP_MAKE_APPLYABLE
	
	method	VisSendToChildren, OLCtrlClass, MSG_OL_MAKE_APPLYABLE
	method	VisSendToChildren, OLCtrlClass, MSG_OL_MAKE_NOT_APPLYABLE
;	method	VisCompMakePressesInk, OLCtrlClass, MSG_META_QUERY_IF_PRESS_IS_INK
if INDENT_BOXED_CHILDREN
	method	VisCallParent, OLCtrlClass, MSG_SPEC_VUP_ADD_GADGET_AREA_LEFT_MARGIN
endif

CommonUIClassStructures ends


;---------------------------------------------------


CtrlBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlInitialize -- MSG_META_INITIALIZE for OLCtrlClass

DESCRIPTION:	Initialize an OL ctrl class instance data

PASS:
	*ds:si - instance data
	es - segment of OLCtrlClass

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

------------------------------------------------------------------------------@

OLCtrlInitialize	method private static OLCtrlClass, MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	CallMod	VisCompInitialize

	; remove conditional hints here before we start checking hints.

	call	RemoveConditionalHintsIfNeeded

	; recover data from MSG_META_RESOLVE_VARIANT_SUPERCLASS

	call	CtrlBuild_DerefVisSpecDI
if	(0)	; an idea in progress
	mov	ax, TEMP_SPEC_MAP_GROUP_DATA
else
	mov	ax, MAP_GROUP_DATA
endif
	call	ObjVarFindData		; ds:bx = data entry, if found
	jnc	noTemp
	mov	ax,ds:[bx].OLMGDE_visParent.handle
	mov	ds:[di].OLCI_visParent.handle,ax
	mov	ax,ds:[bx].OLMGDE_visParent.chunk
	mov	ds:[di].OLCI_visParent.chunk,ax
	mov	ax,ds:[bx].OLMGDE_flags
	mov	ds:[di].OLCI_buildFlags,ax
	call	ObjVarDeleteDataAt
	jmp	short afterTemp

noTemp:
	clr	ax
	mov	ds:[di].OLCI_visParent.handle,ax
	mov	ds:[di].OLCI_visParent.chunk,ax
	mov	ds:[di].OLCI_buildFlags,ax

afterTemp:
	mov	ax, HINT_TOOLBOX
	call	ObjVarFindData
	jnc	afterToolbox

	call	CtrlBuild_DerefVisSpecDI		;ds:[di] -- SpecInstance
	or	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
afterToolbox:

	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	call	ObjVarFindData
	jnc	afterTitleBarLeft
	call	CtrlBuild_DerefVisSpecDI
EC <	test	ds:[di].OLCI_buildFlags, mask OLBF_TARGET		>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ornf	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_LEFT shl offset OLBF_TARGET
afterTitleBarLeft:

	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarFindData
	jnc	afterTitleBarRight
	call	CtrlBuild_DerefVisSpecDI
EC <	test	ds:[di].OLCI_buildFlags, mask OLBF_TARGET		>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>
	ornf	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_RIGHT shl offset OLBF_TARGET
afterTitleBarRight:

	;
	; If we are a reply bar, notify the interaction we are in
	;
	; We do this before vis building because we want the GenInteraction
	; to know about us before we are added as a child of it (so that
	; OLDialogWinClass doesn't mistakenly direct us to its OLGadgetArea
	; object).  We also know that the reply must be generic child of the
	; parent GenInteraction.
	;
;	call	CtrlBuild_DerefVisSpecDI		;ds:[di] -- SpecInstance
;	mov	ax, ds:[di].OLCI_buildFlags
;	and	ax, mask OLBF_TARGET
;	cmp	ax, OLBT_REPLY_BAR shl offset OLBF_TARGET
;	jne	notReplyBar
;these aren't set yet!, use this instead (well check for it again later to
;set up geometry stuff) - brianc 4/24/92
	mov	ax, HINT_MAKE_REPLY_BAR
	call	ObjVarFindData
	jnc	notReplyBar

	mov	cx, ds:[LMBH_handle]		; cx:dx = this reply bar
	mov	dx, si
	mov	ax, MSG_OL_WIN_NOTIFY_OF_REPLY_BAR
;unfortunately, we need to look up the generic tree as the visible tree is
;built yet! - brianc 6/25/92
;if	(0)
	mov	bx, segment OLDialogWinClass	; parent WILL be spec built
	mov	si, offset OLDialogWinClass	;	so okay to go to spui
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	mov	si, dx				; *ds:si = OLCtrl
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock		; Notify Dialog that we're
						; it's reply bar
;else
;	call	CallOLWin			; A quicker way to contact
;						; the OLDialogWin
;endif
notReplyBar:

	.leave
	ret
OLCtrlInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLCtrlClass

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
	chris	2/ 4/92		Initial Version

------------------------------------------------------------------------------@

OLCtrlScanGeometryHints	method static OLCtrlClass, MSG_SPEC_SCAN_GEOMETRY_HINTS

	; Initialize Visible characteristics that we'd like to have unless
	; overridden by hints handling
	;
	; Vertical alignment, normal justifications
	;
	push	di
	mov	di, ds:[si]			;must dereference for static
	add	di, ds:[di].Vis_offset		;   method!
	mov	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	clr	ds:[di].VCI_geoDimensionAttrs

	;
	; Clear all but this bit (clearing this one can cause image update
	; problems.  -cbh 10/27/92)
	;
	and	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED or mask VGA_NOTIFY_GEOMETRY_VALID

	and	ds:[di].OLCI_optFlags, not (mask OLCOF_DISPLAY_BORDER or \
				            mask OLCOF_DISPLAY_MKR_ABOVE  or \
					    mask OLCOF_CUSTOM_SPACING)
	pop	di
	FALL_THRU	DoCtrlHints
OLCtrlScanGeometryHints	endm



DoCtrlHints	proc	far
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	; If a generic object then scan the hints

if	(0)
	mov	di, ds:[si]		;ds:di = object
	les	di, ds:[di].MB_class
	cmp	es:[di].Class_masterOffset,offset Vis_offset
	jz	noGen

	call	CtrlBuild_DerefVisSpecDI
					; Mark as being a generic object
	or	ds:[di].VI_typeFlags, mask VTF_IS_GEN
else
	call	CtrlBuild_DerefVisSpecDI
EC <	; Can't we just test the VTF_IS_GEN flag?  Let's check here:	>
EC <	;								>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN		>
EC <	jnz	isGen						>
EC <	push	di, es						>
EC <	mov	di, segment GenClass				>
EC <	mov	es, di						>
EC <	mov	di, offset GenClass				>
EC <	call	ObjIsObjectInClass				>
EC <	pop	di, es						>
EC <	ERROR_C	OL_ERROR					>
EC <isGen:							>
EC <	call	CtrlBuild_DerefVisSpecDI				>

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	noGen
endif
	
	;
	; We'll assume that any OLCtrl will not need to draw inside its
	; margins.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS

	;
	; We'll assume left justification of any moniker that comes along.
	;	
	or	ds:[di].OLCI_moreFlags, mask OLCOF_LEFT_JUSTIFY_MONIKER

	;
	; If the control has a moniker, we'll set the flag to get it 
	; displayed, and default as left justification.
	;
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Gen_offset	; ds:[di] -- GenInstance
	tst	ds:[di].GI_visMoniker	; see if there's a vis moniker
	jz	10$			; no, branch
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
10$:
					; Process alignment hints
	segmov	es, cs			; setup es:di to be ptr to
					; Hint handler table
	mov	di, offset CtrlBuild:CtrlGeoHintHandlers
	mov	ax, length (CtrlBuild:CtrlGeoHintHandlers)
	call	OpenScanVarData

noGen:
	; If we're in a menu, we'll want to set up geometry to match the
	; orientation of the menu.  Also we'll also do centering to do the
	; keyboard monikers correctly.

	push	si
	call	SwapLockOLWin
	LONG	jnc	notInVisTree
	call	CtrlBuild_DerefVisSpecDI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	mov	cl, ds:[di].VCI_geoAttrs	;keep geo attrs in cl if menu
	call	ObjSwapUnlock
	pop	si
	jz	checkCentered			;skip if not in menu...

	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU

	and	ds:[di].OLCI_optFlags, not (mask OLCOF_DISPLAY_MONIKER or \
					   mask OLCOF_DISPLAY_BORDER or \
				           mask OLCOF_DISPLAY_MKR_ABOVE  or \
				           mask OLCOF_DISPLAY_MONIKER)

	;
	; Turn off these geometry flags.  (Allow children to wrap also turned
	; off, to be turned on if needed by OLCtrlResetSizeToStayOnscreen.
	; -cbh 2/ 4/93.  Also wrap-after-child-count, which is bad, anyway.
	; -cbh 2/18/93)
	;
	and	ds:[di].VCI_geoAttrs, not (mask VCGA_HAS_MINIMUM_SIZE or \
				   mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING or \
				   mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
				   mask VCGA_WRAP_AFTER_CHILD_COUNT)


	; We can now do this, since items in a menu get their size right the
	; first time.  
	or	ds:[di].VCI_geoAttrs, mask VCGA_ONE_PASS_OPTIMIZATION

	test	cl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	verticalMenu

;horizontalMenu:
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY

	jmp	short finishMenu

verticalMenu:
	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY

finishMenu:
	;
	;These should *always* be clear in menus, or we'll get funny behavior.
	;
	and	ds:[di].VCI_geoDimensionAttrs, \
				not (mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT or \
				     mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT)
	jmp	short checkBuildFlags		;don't need center-by-monikers

checkCentered:

	;
	; Speed up geometry a bit.
	;
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VI_geoAttrs, mask VGA_USE_VIS_CENTER
				     
	; See if our parent wishes us to have our moniker centered.  Mostly
	; this is the parent's job, but we have to do a couple of things in
	; RerecalcSize to get it to work.  Also we have our own GetCenter in
	; this case.

	mov	ax, MSG_QUERY_CENTER_BY_MONIKERS
	call	GenCallParent
	jnc	checkBuildFlags			;not handled, branch

	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, cl	;set any flags returned

checkBuildFlags:

	;Check for OLBF_TOOLBOX set it parent.  Set ourselves if so.

	call	OpenGetParentBuildFlagsIfCtrl	
	and	cx, mask OLBF_TOOLBOX or mask OLBF_DELAYED_MODE
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_buildFlags, cx

	segmov	es, cs				; setup es:di to be ptr to
	mov	di, offset cs:DelayedCtrlVarDataHandler
	mov	ax, length (cs:DelayedCtrlVarDataHandler)
	call	ObjVarScanData			; 
	;
	; Reply bars mustn't worry about centering on monikers. -cbh 1/29/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jnz	exit				;not reply bar, exit

	and	ds:[di].OLCI_optFlags, not (mask OLCOF_CENTER_ON_MONIKER or \
					    mask OLCOF_LEFT_JUSTIFY_MONIKER)
exit:
	.leave
	ret

notInVisTree:
	pop	si
	jmp	checkCentered

DoCtrlHints	endp


DelayedCtrlVarDataHandler	VarDataHandler \
 <ATTR_GEN_PROPERTY, offset CtrlProperty>,
 <ATTR_GEN_NOT_PROPERTY, offset CtrlNotProperty>
		
CtrlProperty	proc	far
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	ret
CtrlProperty	endp

CtrlNotProperty	proc	far
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].OLCI_buildFlags, not mask OLBF_DELAYED_MODE
	ret
CtrlNotProperty	endp


CtrlGeoHintHandlers	VarDataHandler \
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, \
			offset CtrlBuild:CtrlExpandHeightToFitParent>,
			
	<HINT_NO_TALLER_THAN_CHILDREN_REQUIRE, \
			offset CtrlBuild:CtrlNoTallerThanChildrenRequire>,
			
	<HINT_ALLOW_CHILDREN_TO_WRAP, \
			offset CtrlBuild:CtrlAllowChildrenToWrap>,
			
	<HINT_DONT_ALLOW_CHILDREN_TO_WRAP, \
			offset CtrlBuild:CtrlDontAllowChildrenToWrap>,
			
	<HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY, \
			offset CtrlBuild:CtrlFullJustifyHorizontally>,
			
	<HINT_FULL_JUSTIFY_CHILDREN_VERTICALLY, \
			offset CtrlBuild:CtrlFullJustifyVertically>,
			
	<HINT_INCLUDE_ENDS_IN_CHILD_SPACING, \
			offset CtrlBuild:CtrlIncludeEndsInSpacing>,
			
	<HINT_DONT_INCLUDE_ENDS_IN_CHILD_SPACING, \
			offset CtrlBuild:CtrlNoEndsInSpacing>,
			
	<HINT_DONT_FULL_JUSTIFY_CHILDREN, \
			offset CtrlBuild:CtrlDontFullJustify>,
			
	<HINT_ORIENT_CHILDREN_VERTICALLY, \
			offset CtrlBuild:CtrlOrientVertically>,
			
	<HINT_ORIENT_CHILDREN_HORIZONTALLY, \
			offset CtrlBuild:CtrlOrientHorizontally>,
			
	<HINT_TOP_JUSTIFY_CHILDREN, \
			offset CtrlBuild:CtrlTopJustify>,
			
	<HINT_CENTER_CHILDREN_VERTICALLY,\
			offset CtrlBuild:CtrlCenterVertically>,
			
	<HINT_BOTTOM_JUSTIFY_CHILDREN, \
			offset CtrlBuild:CtrlBottomJustify>,
			
	<HINT_LEFT_JUSTIFY_CHILDREN, \
			offset CtrlBuild:CtrlLeftJustify>,
			
	<HINT_CENTER_CHILDREN_HORIZONTALLY ,\
			offset CtrlBuild:CtrlCenterHorizontally>,
			
	<HINT_RIGHT_JUSTIFY_CHILDREN, \
			offset CtrlBuild:CtrlRightJustify>,
			
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, \
			offset CtrlBuild:CtrlExpandWidthToFitParent>,
			
	<HINT_NO_WIDER_THAN_CHILDREN_REQUIRE, \
			offset CtrlBuild:CtrlNoWiderThanChildrenRequire>,
			
	<HINT_DO_NOT_USE_MONIKER, \
			offset CtrlBuild:CtrlDoNotUseMoniker>,
			
	<HINT_PLACE_MONIKER_TO_LEFT, \
			offset CtrlBuild:CtrlPlaceMonikerToLeft>,
			
	<HINT_PLACE_MONIKER_TO_RIGHT, \
			offset CtrlBuild:CtrlPlaceMonikerToRight>,
			
	<HINT_CENTER_MONIKER, \
			offset CtrlBuild:CtrlCenterMoniker>,
			
	<HINT_PLACE_MONIKER_ABOVE,\
			offset CtrlBuild:CtrlPlaceMonikerAbove>,
			
	<HINT_PLACE_MONIKER_ALONG_LARGER_DIMENSION,\
			offset CtrlBuild:CtrlPlaceMonikerAlongLargerDimension>,
			
	<HINT_DRAW_IN_BOX, \
			offset CtrlBuild:CtrlDrawInBox>,

if (_MOTIF or _ISUI) and ALLOW_TAB_ITEMS
	<HINT_RAISED_FRAME, \
			offset CtrlBuild:CtrlDrawInBox>,
endif
			
	<HINT_CENTER_CHILDREN_ON_MONIKERS, \
			offset CtrlBuild:CtrlCenterByMonikers>,
			
	<HINT_CUSTOM_CHILD_SPACING, \
			offset CtrlBuild:CtrlSetCustomSpacing>,
			
	<HINT_CUSTOM_CHILD_SPACING_IF_LIMITED_SPACE, \
			offset CtrlBuild:CtrlSetCustomSpacing>,
			
	<HINT_MINIMIZE_CHILD_SPACING, \
			offset CtrlBuild:CtrlSetCustomSpacing>,
			
	<HINT_MAKE_REPLY_BAR, \
			offset CtrlBuild:CtrlMakeReplyBar>,
			
	<HINT_MINIMUM_SIZE, \
			offset CtrlBuild:CtrlSetMinSize>,

	<HINT_FIXED_SIZE, \
			offset CtrlBuild:CtrlSetMinSize>,

	<HINT_INITIAL_SIZE, \
			offset CtrlBuild:CtrlSetMinSize>,

	<HINT_WRAP_AFTER_CHILD_COUNT, \
			offset CtrlBuild:CtrlWrapAfterChildCount>,

	<HINT_WRAP_AFTER_CHILD_COUNT_IF_VERTICAL_SCREEN, \
			offset CtrlBuild:CtrlWrapAfterChildCountIfVerticalScreen>,

	<HINT_SAME_ORIENTATION_AS_PARENT, \
			offset CtrlBuild:CtrlSameOrientationAsParent>,

	<HINT_ORIENT_CHILDREN_ALONG_LARGER_DIMENSION, \
			offset CtrlBuild:CtrlOrientChildrenAlongLargerDimension>,

	<HINT_DIVIDE_WIDTH_EQUALLY, \
			offset CtrlBuild:CtrlDivideWidthEqually>,

	<HINT_DIVIDE_HEIGHT_EQUALLY, \
			offset CtrlBuild:CtrlDivideHeightEqually>,

	<HINT_ALIGN_LEFT_MONIKER_EDGE_WITH_CHILD, \
			offset CtrlBuild:CtrlAlignLeftMonikerEdgeWithChild>

CtrlWrapAfterChildCount	proc	far
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT or \
				      mask VCGA_ALLOW_CHILDREN_TO_WRAP
	ret
CtrlWrapAfterChildCount	endp

CtrlWrapAfterChildCountIfVerticalScreen	proc	far
	call	OpenCheckIfVerticalScreen	; C set if taller than wide
	jnc	horiz				; wider than tall, done
vert::
	call	CtrlWrapAfterChildCount		; taller than wide, wrap count
horiz:
	ret
CtrlWrapAfterChildCountIfVerticalScreen	endp
			
			
CtrlDivideWidthEqually	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoDimensionAttrs, mask \
			VCGDA_DIVIDE_WIDTH_EQUALLY
	ret
CtrlDivideWidthEqually endp

CtrlDivideHeightEqually	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoDimensionAttrs, mask \
			VCGDA_DIVIDE_HEIGHT_EQUALLY
	ret
CtrlDivideHeightEqually endp

CtrlExpandHeightToFitParent	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoDimensionAttrs, mask \
			VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	ret
CtrlExpandHeightToFitParent endp

CtrlNoTallerThanChildrenRequire	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoDimensionAttrs, not mask \
			VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	ret
CtrlNoTallerThanChildrenRequire	endp

CtrlAllowChildrenToWrap	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	ret
CtrlAllowChildrenToWrap	endp

CtrlDontAllowChildrenToWrap	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ALLOW_CHILDREN_TO_WRAP
	ret
CtrlDontAllowChildrenToWrap	endp


CtrlOrientVertically	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	ret
CtrlOrientVertically	endp

CtrlOrientHorizontally	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY
	ret
CtrlOrientHorizontally	endp

CtrlOrientChildrenAlongLargerDimension	proc	far
	call	OpenCheckIfVerticalScreen	; C set if taller than wide
	jnc	horiz
vert::
	call	CtrlOrientVertically		; taller than wide, vertical
	ret
horiz:
	call	CtrlOrientHorizontally		; wider than tall, horizontal
	ret
CtrlOrientChildrenAlongLargerDimension	endp

CtrlTopJustify	proc	far
	class	OLCtrlClass
	mov	al, not mask VCGDA_HEIGHT_JUSTIFICATION
	mov	ah, HJ_TOP_JUSTIFY_CHILDREN shl offset VCGDA_HEIGHT_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlTopJustify	endp

CtrlCenterVertically	proc	far
	class	OLCtrlClass
	
	mov	al, not mask VCGDA_HEIGHT_JUSTIFICATION
	mov	ah, HJ_CENTER_CHILDREN_VERTICALLY shl offset VCGDA_HEIGHT_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlCenterVertically	endp

CtrlBottomJustify	proc	far
	class	OLCtrlClass
	
	mov	al, not mask VCGDA_HEIGHT_JUSTIFICATION
	mov	ah, HJ_BOTTOM_JUSTIFY_CHILDREN shl \
				offset VCGDA_HEIGHT_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlBottomJustify	endp

CtrlLeftJustify	proc	far
	class	OLCtrlClass
	
	mov	al, not mask VCGDA_WIDTH_JUSTIFICATION
	mov	ah, WJ_LEFT_JUSTIFY_CHILDREN shl offset VCGDA_WIDTH_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlLeftJustify	endp

CtrlCenterHorizontally	proc	far
	class	OLCtrlClass
	
	mov	al, not mask VCGDA_WIDTH_JUSTIFICATION
	mov	ah, WJ_CENTER_CHILDREN_HORIZONTALLY shl offset VCGDA_WIDTH_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlCenterHorizontally	endp

CtrlRightJustify	proc	far
	class	OLCtrlClass
	
	mov	al, not mask VCGDA_WIDTH_JUSTIFICATION
	mov	ah, WJ_RIGHT_JUSTIFY_CHILDREN shl offset VCGDA_WIDTH_JUSTIFICATION
	GOTO	CtrlJustify
	
CtrlRightJustify	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CtrlSameOrientationAsParent

DESCRIPTION:	Copy parent's orientation down to ourselves

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLCtrl object

RETURN:		nothing

DESTROYED:	al, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Moved into scan table
------------------------------------------------------------------------------@

CtrlSameOrientationAsParent	proc	far
	push	si
	call	VisSwapLockParent
	call	CtrlBuild_DerefVisSpecDI
	mov	al, ds:[di].VCI_geoAttrs
	and	al, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	call	ObjSwapUnlock
	pop	si
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY
	or	ds:[di].VCI_geoAttrs, al
	ret
CtrlSameOrientationAsParent	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CtrlJustify

SYNOPSIS:	Sets up justification.

CALLED BY:	CtrlRightJustify, etc.

PASS:		*ds:si -- object
		al     -- mask to and with current dimension flags
		ah     -- value to or into dimension flags

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 9/91		Initial version

------------------------------------------------------------------------------@

CtrlJustify	proc	far
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoDimensionAttrs, al
	or	ds:[di].VCI_geoDimensionAttrs, ah
	ret
CtrlJustify	endp

		
		
		
CtrlFullJustifyVertically	proc	far
	class	OLCtrlClass
	mov	al, not mask VCGDA_HEIGHT_JUSTIFICATION
	mov	ah, HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY \
				shl offset VCGDA_HEIGHT_JUSTIFICATION
	GOTO	CtrlJustify

CtrlFullJustifyVertically	endp
				
CtrlFullJustifyHorizontally	proc	far
	class	OLCtrlClass
	mov	al, not mask VCGDA_WIDTH_JUSTIFICATION
	mov	ah, WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY \
				shl offset VCGDA_WIDTH_JUSTIFICATION
	GOTO	CtrlJustify

CtrlFullJustifyHorizontally	endp
	
CtrlIncludeEndsInSpacing	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoAttrs, mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	ret

CtrlIncludeEndsInSpacing	endp

CtrlNoEndsInSpacing	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_INCLUDE_ENDS_IN_CHILD_SPACING
	ret

CtrlNoEndsInSpacing	endp

CtrlDontFullJustify	proc	far
	class	OLCtrlClass
	
	mov	al, not (mask VCGDA_WIDTH_JUSTIFICATION or \
			 mask VCGDA_HEIGHT_JUSTIFICATION)
	clr	ah
	GOTO	CtrlJustify

CtrlDontFullJustify	endp

CtrlExpandWidthToFitParent	proc	far
	class	OLCtrlClass

	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
	ret
CtrlExpandWidthToFitParent endp

CtrlNoWiderThanChildrenRequire	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].VCI_geoDimensionAttrs, \
			not mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
	ret
CtrlNoWiderThanChildrenRequire	endp

CtrlDoNotUseMoniker		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER
	ret
CtrlDoNotUseMoniker		endp

CtrlPlaceMonikerToLeft		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_moreFlags, mask OLCOF_LEFT_JUSTIFY_MONIKER
	and	ds:[di].OLCI_moreFlags, \
		   not (mask OLCOF_RIGHT_JUSTIFY_MONIKER or\
		        mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD)
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ret
CtrlPlaceMonikerToLeft		endp

CtrlPlaceMonikerToRight		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].OLCI_moreFlags, not (mask OLCOF_LEFT_JUSTIFY_MONIKER or\
		        mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD)

	or	ds:[di].OLCI_moreFlags, mask OLCOF_RIGHT_JUSTIFY_MONIKER
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ret
CtrlPlaceMonikerToRight		endp

CtrlCenterMoniker		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].OLCI_moreFlags, not (mask OLCOF_LEFT_JUSTIFY_MONIKER or\
			mask OLCOF_RIGHT_JUSTIFY_MONIKER or\
		        mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD)
	
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ret
CtrlCenterMoniker		endp

CtrlAlignLeftMonikerEdgeWithChild		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	and	ds:[di].OLCI_moreFlags, not (mask OLCOF_LEFT_JUSTIFY_MONIKER or\
					     mask OLCOF_RIGHT_JUSTIFY_MONIKER)
	or	ds:[di].OLCI_moreFlags, \
			mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD or \
			mask OLCOF_LEFT_JUSTIFY_MONIKER
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE

	ret
CtrlAlignLeftMonikerEdgeWithChild		endp

CtrlPlaceMonikerAbove		proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	;
	; We're going to make sure that the control is as least as wide as
	; its moniker.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ret
CtrlPlaceMonikerAbove		endp

CtrlPlaceMonikerAlongLargerDimension	proc	far
	call	OpenCheckIfVerticalScreen	; C set if taller than wide
	jnc	horiz
vert::
	call	CtrlPlaceMonikerAbove		; taller than wide, place above
	ret
horiz:
	call	CtrlPlaceMonikerToLeft		; wider than tall, place to left
	ret
CtrlPlaceMonikerAlongLargerDimension	endp

	
CtrlDrawInBox		proc	far
	class	OLCtrlClass
	
	; 10/7/90 -- added OLCOF_DISPLAY_MONIKER so frame always gets
	; drawn, even if there's no moniker.

	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER or \
				       mask OLCOF_DISPLAY_MKR_ABOVE  or \
				       mask OLCOF_DISPLAY_MONIKER

	; 11/16/92 -- Don't center the moniker if an align-left-edge hint has
	; already been encountered.
	;
	test	ds:[di].OLCI_moreFlags,mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jnz	10$

	;
	; if we've also got a HINT_PLACE_MONIKER_TO_LEFT, don't center
	; (we could also parse HINT_DRAW_IN_BOX seperately, before the rest
	;  of the hints, or set a new bit if we've found TO_LEFT, but this
	;  is okay, too -- it'll only be executated for HINT_DRAW_IN_BOX,
	;  saves OLCOF bits, and avoids always scanning for HINT_DRAW_IN_BOX
	;  separately)   
	;
	push	ax, bx
	mov	ax, HINT_PLACE_MONIKER_TO_LEFT
	call	ObjVarFindData		; doesn't move chunk
	pop	ax, bx
	jc	10$			; found TO_LEFT, don't center
EC <	push	ax							>
EC <	mov	ax, di							>
EC <	call	CtrlBuild_DerefVisSpecDI				>
EC <	cmp	di, ax							>
EC <	ERROR_NE	OL_ERROR					>
EC <	pop	ax							>
	
	and	ds:[di].OLCI_moreFlags, not mask OLCOF_LEFT_JUSTIFY_MONIKER
10$:
	ret
CtrlDrawInBox		endp
	
	
CtrlCenterByMonikers	proc	far
	class	OLCtrlClass
	
	call	CtrlOrientVertically		;orient vertically.  Other
						;  stuff done later.
	ret
CtrlCenterByMonikers	endp

			

CtrlSetCustomSpacing	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	or	ds:[di].OLCI_optFlags, mask OLCOF_CUSTOM_SPACING
	ret
CtrlSetCustomSpacing	endp
	
CtrlMakeReplyBar	proc	far
	class	OLCtrlClass
	
	; Set a flag so special centering is done for reply bars.  Also make
	; horizontal, expand-to-fit, and center the buttons lengthwise.
	; Also, make parent ignore this object when centering its children.

	call	CtrlOrientHorizontally
	call	CtrlExpandWidthToFitParent

	; Center the thing vertically, to handle buttons that don't know to
	; have the silly outline around them (buttons in another composite).
	; -cbh 1/23/93
	
	call	CtrlCenterVertically

OLS <	call	CtrlCenterHorizontally					>
MO <	call	CtrlFullJustifyHorizontally				>
MO <	call	CtrlIncludeEndsInSpacing				>
ISU <	call	CtrlFullJustifyHorizontally				>
ISU <	call	CtrlIncludeEndsInSpacing				>

	; Always allow reply bar triggers to wrap

	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	ORNF	ds:[di].VI_geoAttrs, mask VGA_DONT_CENTER

	call	CtrlBuild_DerefVisSpecDI
EC <	test	ds:[di].OLCI_buildFlags, mask OLBF_TARGET		>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_TARGETS			>

	ORNF	ds:[di].OLCI_buildFlags, OLBT_REPLY_BAR shl offset OLBF_TARGET

 	; Please, don't show the moniker!
 	
 	ANDNF	ds:[di].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER
	ret
CtrlMakeReplyBar	endp

CtrlSetMinSize	proc	far
	class	OLCtrlClass
	
	call	CtrlBuild_DerefVisSpecDI
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ret
CtrlSetMinSize	endp
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlSendToGenChildren

DESCRIPTION:	This procedure receives some specific methods and forwards
		them on to our generic children. The purpose of this is
		to allow arbitrary OLCtrl-nesting without damaging specific
		UI mechanisms. At present, this is only used in cases where
		GenDisplays are notifying their menus of focus changes.

PASS:		ds:*si	- instance data

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		initial version

------------------------------------------------------------------------------@

OLCtrlSendToGenChildren	method	OLCtrlClass, MSG_SHOW_MENU_BUTTON,
					     MSG_HIDE_MENU_BUTTON,
					     MSG_KILL_MENU_BUTTON

	mov	di,400
	call	ThreadBorrowStackSpace
	push	di

	;send notification to all Generic children: if you are a menu, and
	;have a menu button, change the button's visibility status.

	call	GenSendToChildren	; pass on incoming method

	pop	di
	call	ThreadReturnStackSpace

	ret
OLCtrlSendToGenChildren	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlSendToVisChildren

DESCRIPTION:	This procedure receives some specific methods and forwards
		them on to our visible children. The purpose of this is
		to allow arbitrary OLCtrl-nesting without damaging specific
		UI mechanisms. At present, this is only used for
		MSG_OL_BUTTON_SET_BORDERED.

PASS:		ds:*si	- instance data
		ax	- method to send to children
		cx 	- data to pass on to child (in CX and DX)
		bp	- flags to pass on to any children called

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		initial version

------------------------------------------------------------------------------@

if _OL_STYLE	;--------------------------------------------------------------

OLCtrlSendToVisChildren	method	OLCtrlClass, MSG_OL_BUTTON_SET_BORDERED
	clr	dl			;call all visible children
	call	VisIfFlagSetCallVisChildren
	ret
OLCtrlSendToVisChildren	endm

endif 		;--------------------------------------------------------------





COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlSetMoreFlags -- 
		MSG_SPEC_CTRL_SET_MORE_FLAGS for OLCtrlClass

DESCRIPTION:	Sets more flags

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CTRL_SET_MORE_FLAGS
		cl	- OLCtrlMoreFlags to set
		ch	- OLCtrlMoreFlags to clear

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
	chris	12/ 8/92         	Initial Version

------------------------------------------------------------------------------@

OLCtrlSetMoreFlags	method dynamic	OLCtrlClass, \
				MSG_SPEC_CTRL_SET_MORE_FLAGS

	or	ds:[di].OLCI_moreFlags, cl
	not	ch
	and	ds:[di].OLCI_moreFlags, ch
	ret
OLCtrlSetMoreFlags	endm

CtrlBuild	ends




CtrlBuild	segment resource




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlSpecChangeUsable -- MSG_SPEC_SET_USABLE,
					  MSG_SPEC_SET_NOT_USABLE handler.

DESCRIPTION:	We intercept this method here, for the case where this button
		is inside a menu. We want to update the separators which are
		drawn within the menu.

PASS:		*ds:si	= instance data for object
		dl = VisUpdateMode

RETURN:		nothing

DESTROYED:	anything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@
OLCtrlSpecChangeUsable method	private static OLCtrlClass, \
						MSG_SPEC_SET_USABLE,
						MSG_SPEC_SET_NOT_USABLE
	
	;
	; If setting not usable, we'll look up the guy's parent now so
	; we'll have it after the thing has been disconnected. -cbh 3/ 9/93
	;
	cmp	ax, MSG_SPEC_SET_NOT_USABLE
	jne	10$
	push	si
	call	VisFindParent
	mov	cx, si			;parent in ^lbx:cx
	pop	si
10$:

	;
	; If centering on monikers, we'll be doing some bigtime geometry
	; in a second, so callSuper with VUM_MANUAL.  -cbh 4/23/93
	;
	push	dx	
	call	CtrlBuild_DerefVisSpecDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	pushf
	jz	15$
	mov	dl, VUM_MANUAL
15$:

	;cannot use CallSuper macro, because we do not know the method #
	;at assembly time.

	push	ax, cx
	mov	di, offset OLCtrlClass
	call	ObjCallSuperNoLock
	pop	ax, cx
	popf				;center on moniker flag
	pop	dx

	;
	; Have center-on-moniker controls talk to the head honcho about 
	; recalculating the left-of-center amount.  -cbh 4/23/93
	;
	jz	done

	;
	; Setting not usable, use the parent passed in ^lbx:dx.
	;
	cmp	ax, MSG_SPEC_SET_NOT_USABLE
	jne	20$
	mov	si, cx				;old VisParent in ^lbx:si
	mov	ax, MSG_SPEC_CTRL_UPDATE_CENTER_STUFF
	mov	di, mask MF_CALL
	GOTO	ObjMessage
20$:
	mov	ax, MSG_SPEC_CTRL_UPDATE_CENTER_STUFF
	call	VisCallParent			;was CallOLWin from 1-93 to 3-93
done:
	ret
OLCtrlSpecChangeUsable	endm

CtrlBuild_DerefVisSpecDI	proc near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
CtrlBuild_DerefVisSpecDI	endp

CtrlBuild	ends

GadgetBuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlUpdateCenterStuff -- 
		MSG_SPEC_CTRL_UPDATE_CENTER_STUFF for OLCtrlClass

DESCRIPTION:	Sent upwards from OLCtrl children to make sure center-by-
		monikers stuff is recalculated.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CTRL_UPDATE_CENTER_STUFF

		dl	- VisUpdateMode

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
	chris	4/23/93         Initial Version

------------------------------------------------------------------------------@

OLCtrlUpdateCenterStuff	method dynamic	OLCtrlClass, \
				MSG_SPEC_CTRL_UPDATE_CENTER_STUFF

	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	doCenterStuff

	;
	; Not at the top, send upwards.
	;
	GOTO	VisCallParent
	
doCenterStuff:

	;
	; All we have to do here is mark ourselves invalid.  The reset happens
	; on MSG_VIS_RECALC_SIZE.   
	;
	mov	cl, mask VOF_GEOMETRY_INVALID
	GOTO	VisMarkInvalid

OLCtrlUpdateCenterStuff	endm


GadgetBuild	ends

CtrlBuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlSetVisParent -- MSG_OL_CTRL_SET_VIS_PARENT for
			OLCtrlClass

DESCRIPTION:	Set the vis parent for an OLCtrlClass object.

PASS:
	*ds:si - instance data
	es - segment of OLCtrlClass

	ax - MSG_OL_CTRL_SET_VIS_PARENT

	cx:dx - vis parent
	bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	12/89		Moved to OLCtrlClass from remote subclass.

------------------------------------------------------------------------------@

OLCtrlSetVisParent	method	OLCtrlClass, MSG_OL_CTRL_SET_VIS_PARENT
	mov	ds:[di].OLCI_visParent.handle,cx
	mov	ds:[di].OLCI_visParent.chunk,dx
	ret
OLCtrlSetVisParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlDetermineVisParentForChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is a notebook style OLCtrl, then the vis parent
		of the child may be either the leftPage or rightPage.

CALLED BY:	MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD

PASS:		*ds:si	= OLCtrlClass object
		ds:di	= OLCtrlClass instance data
		ds:bx	= OLCtrlClass object (same as *ds:si)
		es 	= segment of OLCtrlClass
		ax	= message #
		^lcx:dx	= child to get vis parent for
		bp	= SpecBuildFlags

RETURN:		carry set if method handled & therefore data returned:
		^lcx:dx	= vis parent to use
		bp	= SpecBuildFlags

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

OLCtrlDetermineVisParentForChild	method dynamic OLCtrlClass, 
					MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	mov	ax, TEMP_OL_CTRL_NOTEBOOK_PARTS
	call	ObjVarFindData
	jc	notebook

	mov	ax, MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	mov	di, offset OLCtrlClass
	GOTO	ObjCallSuperNoLock

notebook:
	;
	; This is a notebook interaction.  Figure out which side of the
	; notebook rings this child should be add to.
	;
	mov	di, bx			; ds:di = TEMP_OL_CTRL_NOTEBOOK_PARTS
	movdw	bxsi, cxdx		; ^lbx:si = child object
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].TOCNP_leftPage
	mov	di, ds:[di].TOCNP_rightPage

	call	ObjSwapLock
	push	bx
	mov	ax, HINT_SEEK_NOTEBOOK_RIGHT
	call	ObjVarFindData
	pop	bx
	call	ObjSwapUnlock
	jnc	gotParent		; if not found then
					;   ^lcx:dx = TOCNP_leftPage
	mov	dx, di			; else
gotParent:				;   ^lcx:dx = TOCNP_rightPage
	stc				; indicate that we have a parent
	ret
OLCtrlDetermineVisParentForChild	endm

endif	; NOTEBOOK_INTERACTION


COMMENT @----------------------------------------------------------------------
	
METHOD:		OLCtrlSpecBuild --
		MSG_SPEC_BUILD for OLCtrlClass

DESCRIPTION:	Handles some spec build stuff at the OLCtrl level.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 6/89	Initial version

------------------------------------------------------------------------------@
;NOTE: UIGROUP: Change this when Interactions become Properties windows!

OLCtrlSpecBuild	method private static OLCtrlClass, MSG_SPEC_BUILD
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	call	VisCheckIfSpecBuilt	; Make sure NOT vis built yet. 
	jc	exit			; if it is, quit.

	mov	di, segment OLCtrlClass	;handle superclass build
	mov	es, di
	mov	di, offset OLCtrlClass	;handle superclass build
	CallSuper	MSG_SPEC_BUILD

	; 
	;  If our parent has OLBT_FOR_TITLE_BAR_LEFT or _RIGHT, set
	;  in ourselves as well.
	;
	call	OpenGetParentBuildFlagsIfCtrl
	call	CtrlBuild_DerefVisSpecDI
	cmp	ds:[di].OLCI_buildFlags, OLBT_NO_TARGET shl offset OLBF_TARGET
	jne	noTitle
	push	cx
	andnf	cx, mask OLBF_TARGET
	cmp	cx, OLBT_FOR_TITLE_BAR_LEFT shl offset OLBF_TARGET
	jne	notTitleLeft
	ornf	ds:[di].OLCI_buildFlags, cx
notTitleLeft:
	cmp	cx, OLBT_FOR_TITLE_BAR_RIGHT shl offset OLBF_TARGET
	jne	notTitleRight
	ornf	ds:[di].OLCI_buildFlags, cx
notTitleRight:
	pop	cx
noTitle:

if _HAS_LEGOS_LOOKS
	call	LegosSetGroupLookFromHints
endif
	;
	; Scan for geometry hints now.
	;
	call	OLCtrlScanGeometryHints

if INDENT_BOXED_CHILDREN
	;
	; if draw in box, tell parent gadget area that we need a left margin
	;
	call	CtrlBuild_DerefVisSpecDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	noMargin
	mov	ax, MSG_SPEC_VUP_ADD_GADGET_AREA_LEFT_MARGIN
	call	VisCallParent
noMargin:
endif

if NOTEBOOK_INTERACTION
	call	OLCtrlCreateNotebookIfNeeded
endif

exit:
	.leave
	ret
OLCtrlSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlCreateNotebookIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a "notebook" if needed

CALLED BY:	OLCtrlSpecBuild
PASS:		*ds:si	= OLCtrlClass object
		es 	= segment of OLCtrlClass
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

OLCtrlCreateNotebookIfNeeded	proc	far

	mov	ax, HINT_INTERACTION_NOTEBOOK_STYLE
	call	ObjVarFindData
	jnc	done

	; Set custom vis parent for children

	call	CtrlBuild_DerefVisSpecDI
	ornf	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT_FOR_CHILD

	; Create notebook binder

	push	si
	mov	di, offset NotebookBinderClass	; es:di = NotebookBinderClass
	call	OLCtrlCreateChildObject		; dx = binder chunk
	mov	si, dx

	; Create left page, rings bitmap, and right page

	mov	di, offset NotebookPageClass	; es:di = NotebookPageClass
	call	OLCtrlCreateChildObject		; dx = leftPage chunk
	push	dx				; save leftPage chunk
	mov	di, offset NotebookRingsClass	; es:di = NotebookRingsClass
	call	OLCtrlCreateChildObject		; dx = rings chunk
	push	dx				; save rings chunk
	mov	di, offset NotebookPageClass	; es:di = NotebookPageClass
	call	OLCtrlCreateChildObject		; dx = rightPage chunk
	pop	bp				; bp = rings chunk
	pop	di				; di = leftPage chunk
	pop	si				; si = GenInteraction

	; Create temporary vardata to store notebook parts

	mov	ax, TEMP_OL_CTRL_NOTEBOOK_PARTS
	mov	cx, size TempOLCtrlNotebookParts
	call	ObjVarAddData
	mov	ds:[bx].TOCNP_rightPage, dx
	mov	ds:[bx].TOCNP_rings, bp
	mov	ds:[bx].TOCNP_leftPage, di

	; Now save the rings chunk handle in the page objects

	push	si
	mov	si, di				; *ds:si = leftPage
	call	CtrlBuild_DerefVisSpecDI
	mov	ds:[di].NBPI_notebookRings, bp
	mov	si, dx				; *ds:si = rightPage
	call	CtrlBuild_DerefVisSpecDI
	mov	ds:[di].NBPI_notebookRings, bp
	pop	si
done:
	ret
OLCtrlCreateNotebookIfNeeded	endp

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlCreateChildObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and add a child object

CALLED BY:	OLCtrlSpecBuildBackground
PASS:		*ds:si	= parent object
		es:di	= class of object to create
RETURN:		dx	= chunk handle of child object
DESTROYED:	ax, bx, cx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

OLCtrlCreateChildObject	proc	near	
	push	si				;save handle of parent object
	mov	bx, ds:[LMBH_handle]		;pass block to create obj in
	call	GenInstantiateIgnoreDirty	;si = child object
	mov	bp, si				;*ds:bp = child object
	pop	si

	cmp	di, offset NotebookBinderClass
	jne	checkPage

	; copy some vardata from GenInteraction to NotebookBinder

	push	es
	segmov	es, ds				;*es:bp = child object
	mov	cx, HINT_CUSTOM_CHILD_SPACING
	mov	dx, HINT_CUSTOM_CHILD_SPACING
	call	ObjVarCopyDataRange		;copy child spacing
	pop	es
	jmp	expand				;expand width and height

checkPage:
	cmp	di, offset NotebookPageClass
	jne	addChild

expand:
	; make object expand width and height

	push	si
	mov	si, bp
	mov	bx, offset Vis_offset
	call	ObjInitializePart
	call	CtrlBuild_DerefVisSpecDI
	ORNF	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	pop	si

addChild:
	mov	ax, MSG_VIS_ADD_CHILD
	mov	cx, ds:[LMBH_handle]
	mov	dx, bp				;^lcx:dx = child object
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock

	; if parent has been specifically built, spec build the child

	call	VisCheckIfSpecBuilt
	jnc	done				;skip if not vis built...

	; we need to "Vis build" this visible object

	clr	bp
	call	VisCheckIfFullyEnabled
	jnc	10$				;not fully enabled, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	push	si
	mov	si, dx
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallInstanceNoLock
	mov	dx, si
	pop	si
done:
	ret
OLCtrlCreateChildObject	endp

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegosSetGroupLookFromHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The legos look is stored in instance data, so when
		we unbuild and rebuild we need to set it from the hints.

CALLED BY:	OLCtrlSpecBuild
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

if _HAS_LEGOS_LOOKS

LegosSetGroupLookFromHints	proc	near
	uses	ax, bx
	.enter

	clr	bp			; our table index

	;
	; Start our indexing at 1, as 0 has no hint
	;
loopTop:
	inc	bp
	inc	bp			; next entry
	mov	ax, cs:[buildLegosGroupLookHintTable][bp]
	call	ObjVarFindData
	jc	gotLook

	cmp	bp, LAST_BUILD_LEGOS_GROUP_LOOK * 2
	jl	loopTop

	clr	bp			; no hints found, so must be look 0

gotLook:
	mov	ax, bp			; use ax as bp can't be byte addressable
	sar	ax, 1			; words to bytes
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLCI_legosLook, al
done:
	.leave
	ret
LegosSetGroupLookFromHints	endp

	;
	; Make sure this table matches that in copenCtrlClass.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the CommonFunctional resource at build time,
	; and it is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
buildLegosGroupLookHintTable	label word
	word	0
LAST_BUILD_LEGOS_GROUP_LOOK	equ ((($ - buildLegosGroupLookHintTable) / \
					(size word)) - 1)
CheckHack<LAST_BUILD_LEGOS_GROUP_LOOK eq LAST_LEGOS_GROUP_LOOK>

endif		; if _HAS_LEGOS_LOOKS





COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGupQuery -- MSG_SPEC_GUP_QUERY for OLCtrlClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLCtrlClass

	ax - MSG_SPEC_GUP_QUERY
	cx - Query type (GenQueryType or SpecGenQueryType)
	dx -?
	bp - OLBuildFlags
RETURN:
	carry - set if query acknowledged, clear if not
	bp - OLBuildFlags
	cx:dx - vis parent

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	WARNING: see OLMapGroup for up-to-date details

	if (query = SGQT_BUILD_INFO) {
		;Is below a control area: if is a menu or a GenTrigger which
		;want to be moved into a GenFile-type object, then send query
		;to parent to see if such a beast exists. Return if somebody
		;above wants to grab this object. Otherwise, is a plain
		;GenTrigger which should stay in this OLCtrl object.
	    if (not a win group) {
	        if (MENUABLE) or (HINT_FILE or HINT_EDIT) {
		    MSG_SPEC_GUP_QUERY(vis parent, SGQT_BUILD_INFO);
		    if (visParent != NULL) {
			return(stuff from parent)
		    }
		}
	    }
	    ;Nothing above grabbed object, or object is plain GenTrigger.
	    ;Place inside this OLCtrl object.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = this object;

	} else {
		send query to superclass (will send to generic parent)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

OLCtrlGupQuery	method private static OLCtrlClass, MSG_SPEC_GUP_QUERY
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLCtrlClass
	mov	es, di

	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	answer				;skip if so...

	cmp	cx, GUQT_DELAYED_OPERATION
	je	returnDelayed

	;we can't answer this query: call super class to handle
	mov	di, offset OLCtrlClass
	call	ObjCallSuperNoLock
	jmp	short exit

returnDelayed:
EC <	call	VisCheckVisAssumption					>
	call	CtrlBuild_DerefVisSpecDI
	mov	ax, ds:[di].OLCI_buildFlags
	andnf	ax, mask OLBF_DELAYED_MODE	; ax <- non-zero if delayed
	jmp	done

answer:
EC <	call	VisCheckVisAssumption					>

	call	CtrlBuild_DerefVisSpecDI
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	noPromote

checkPromotable:
	test	bp, mask OLBF_MENUABLE
	jnz	promote

	mov	bx, bp
	ANDNF	bx, mask OLBF_TARGET

;In cspecInteraction.asm, we prevent HINT_SYS_MENU and HINT_IS_EXPRESS_MENU
;from using the BUILD_INFO query. So we should not be in this routine!

EC <	cmp	bx, OLBT_SYS_MENU shl offset OLBF_TARGET		>
EC <	ERROR_E OL_ERROR						>
EC <	cmp	bx, OLBT_IS_EXPRESS_MENU shl offset OLBF_TARGET		>
EC <	ERROR_E OL_ERROR						>

	cmp	bx, OLBT_FOR_REPLY_BAR shl offset OLBF_TARGET
	jnz	noPromote

promote: ;send query to generic parent to see if it wants to grab object

	push	bp				;save OLBuildFlags in case
						;we ignore parent
	call	GenCallParent
	pop	di				;di = original OLBuildFlags

	mov	bx, bp
	ANDNF	bx, mask OLBF_REPLY
	cmp	bx, OLBR_TOP_MENU shl offset OLBF_REPLY
	je	done

	;
	; This used to branch to done, but we really want ourselves to be
	; the visual parent of anything that finds out it's in a menu.
	; We'll keep the SUB_MENU status.  -cbh 5/11/92
	;
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY
	je	noPromote

	cmp	bx, OLBR_REPLY_BAR shl offset OLBF_REPLY
	je	done

	mov	bp, di				;return original OLBuildFlags

noPromote:		;use this OLCtrlClass object as visible parent
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
done:
	stc					;return query acknowledged
exit:
	.leave
	ret

OLCtrlGupQuery	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlQueryCenterByMonikers -- 
		MSG_QUERY_CENTER_BY_MONIKERS for OLCtrlClass

DESCRIPTION:	Returns carry set if the composite wants its children centered
		by monikers. Called by children so they can set their own
		flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_QUERY_CENTER_BY_MONIKERS

RETURN:		cl 	- OLCtrlOptFlags, with some flags possibly set.

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/30/89	Initial version

------------------------------------------------------------------------------@

OLCtrlQueryCenterByMonikers method OLCtrlClass, MSG_QUERY_CENTER_BY_MONIKERS
	clr	cl
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	exit			; not generic, exit now
	segmov	es, cs			; setup es:di to be ptr to
	mov	di, offset CtrlBuild:CenterHintHandlers
	mov	ax, length (CtrlBuild:CenterHintHandlers)
	call	ObjVarScanData
	test	cl, mask OLCOF_CENTER_ON_MONIKER	  ;is this set?
	jnz	exit					  ;yes, exit
	and	cl, not mask OLCOF_LEFT_JUSTIFY_MONIKERS  ;else ignore this
exit:
	stc						  ;mark handled
	ret
OLCtrlQueryCenterByMonikers endm

			    
CenterHintHandlers	VarDataHandler \
	<HINT_CENTER_CHILDREN_ON_MONIKERS, \
			offset CtrlBuild:CenterByMonikers>,
	<HINT_LEFT_JUSTIFY_MONIKERS, \
			offset CtrlBuild:LeftJustifyMonikers>
			
CenterByMonikers	proc	far
	or	cl, mask OLCOF_CENTER_ON_MONIKER
	ret
CenterByMonikers	endp
			
LeftJustifyMonikers	proc	far
	or	cl, mask OLCOF_LEFT_JUSTIFY_MONIKERS
	ret
LeftJustifyMonikers	endp
			


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetBuildFlags -- 
		MSG_VUP_GET_BUILD_FLAGS for OLCtrlClass

DESCRIPTION:	Method that returns the OLBuildFlags for the control group.
		It returns the carry set to show that the query was 
		responded to and CX is valid.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_BUILD_FLAGS

RETURN:		CX	- BuildFlags (OLCI_buildFlags)
		carry	- set to show query was responded to & CX is valid

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	2/89		Initial version

------------------------------------------------------------------------------@

OLCtrlGetBuildFlags method OLCtrlClass, MSG_VUP_GET_BUILD_FLAGS
	mov	cx, ds:[di].OLCI_buildFlags	; Get the build flags
	stc					;return carry set
	ret
OLCtrlGetBuildFlags endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlSpecUnbuildBranch -- MSG_SPEC_UNBUILD_BRANCH handler.

DESCRIPTION:	We intercept this method here, for the case where this OLCtrl
		is in title bar.

PASS:		*ds:si	= instance data for object
		bp = SpecBuildFlags

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/90		initial version

------------------------------------------------------------------------------@

if 0
OLCtrlSpecUnbuildBranch method	dynamic OLCtrlClass, MSG_SPEC_UNBUILD_BRANCH

	;
	; if we are setting a title bar OLCtrl not usable, notify the
	; window
	;
	push	ax, bp
	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	call	ObjVarFindData
	jnc	noTitleBarLeft
	mov	ax, MSG_OL_WIN_NOTIFY_OF_TITLE_BAR_LEFT_GROUP
	jmp	short notifyParent
noTitleBarLeft:
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarFindData
	jnc	noTitleBarCleanup
	mov	ax, MSG_OL_WIN_NOTIFY_OF_TITLE_BAR_RIGHT_GROUP
notifyParent:
	clr	cx			; no more title bar group
	mov	dx, cx
EC <	call	OpenEnsureGenParentIsOLWin				>
	call	GenCallParent
noTitleBarCleanup:
	pop	ax, bp

	mov	di, offset OLCtrlClass
	call	ObjCallSuperNoLock
	ret
OLCtrlSpecUnbuildBranch	endm

endif

CtrlBuild ends

;-----------------------------------

ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLCtrlClass

DESCRIPTION:	Specific UI handler for setting the vis moniker.
		Sets OLCOF_DISPLAY_MONIKER flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

		dl	- VisUpdateMode
		cx 	- width of old moniker  
		bp 	- height of old moniker 

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@

OLCtrlUpdateVisMoniker	method OLCtrlClass,	MSG_SPEC_UPDATE_VIS_MONIKER
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER
	
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_visMoniker
	pop	di
	jz	handleCentering			;no moniker anymore, exit
	or	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER

handleCentering:
	;
	; If we're centering on monikers, tell parent to update center
	; stuff.   We'll use VUM_MANUAL since an update follows behind
	; via the callSuper.  -cbh 4/23/93
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	callSuper

	push	ax, cx, dx, bp
	mov	dl, VUM_MANUAL
	mov	ax, MSG_SPEC_CTRL_UPDATE_CENTER_STUFF
	call	VisCallParent			
	pop	ax, cx, dx, bp

callSuper:
	;
	; Since the margins are most likely changing, we really need to
	; force the entire ctrl to be invalidated, despite the
	; ONLY_DRAWS_IN_MARGINS flag.  -cbh 11/ 5/92
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	push	{word} ds:[di].VCI_geoAttrs
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ONLY_DRAWS_IN_MARGINS

	mov	di, offset OLCtrlClass		;now call superclass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	pop	{word} ds:[di].VCI_geoAttrs
done::
	ret
OLCtrlUpdateVisMoniker	endm

if GRAFFITI_ANYWHERE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass query to first focused child, if any.

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK

PASS:		*ds:si	= OLCtrlClass object
		ds:di	= OLCtrlClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

BUGS/SIDE EFFECTS/IDEAS:

	Any bugs fixed in this routine should probably also be fixed in
	OLBaseWinQueryIfPressIsInk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLCtrlQueryIfPressIsInk	method dynamic OLCtrlClass, 
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
		mov	di, offset OLCtrlClass
		call	ObjCallSuperNoLock
		jmp	done
OLCtrlQueryIfPressIsInk	endm

endif	; GRAFFITI_ANYWHERE

ActionObscure	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlActivateObjectWithMnemonic --
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC handler

DESCRIPTION:	Let this pass through us untouched, don't check our
		mnemonic.

PASS:		*ds:si	= instance data for object
		ax = MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if found, clear otherwise

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLCtrlActivateObjectWithMnemonic	method	OLCtrlClass, \
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	VisCheckIfFullyEnabled
	jnc	tryChildren

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_moreFlags, mask OLCOF_IGNORE_MNEMONIC
	jnz	tryChildren		;ignore
	;
	; skip checking this object's mnemonic if a window, this was intended
	; for subgroups within a window.  Fixes problem of sending
	; MSG_GEN_ACTIVATE to a pin trigger. - brianc 12/28/92
	;
	mov	di, segment OLWinClass
	mov	es, di
	mov	di, offset OLWinClass
	call	ObjIsObjectInClass
	jc	tryChildren

	call	VisCheckMnemonic
	jnc	tryChildren

	call	ActivateFirstGenChild	;activate first child if mnemonic
					;  matches (what the heck)
	stc				;  -cbh 12/11/92
	ret				;  

tryChildren:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE	
	clc
	jz	exit				;not composite, exit no match
	
	mov	di, 1000		;changed to match GenSendToChildren
					;   2/ 9/94 cbh
	call	ThreadBorrowStackSpace
	push	di

	;
	; call children, until one returns carry set
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, OCCT_SAVE_PARAMS_TEST_ABORT
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	call	ObjCompProcessChildren

	pop	di
	call	ThreadReturnStackSpace

exit:
	Destroy	ax, cx, dx, bp
	ret
OLCtrlActivateObjectWithMnemonic	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	ActivateFirstGenChild

SYNOPSIS:	Activate first gen child, handling text objects specially.

CALLED BY:	OLCtrlActivateObjectWithMnemonic

PASS:		*ds:si -- OLCtrl

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/94		Initial version

------------------------------------------------------------------------------@
ActivateFirstGenChild	proc	near
	uses	bx, si
	.enter

	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	clr	cx
	call	ObjCallInstanceNoLock		;^lcx:dx = first child, if any
	jcxz	done
	movdw	bxsi, cxdx
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment GenTextClass
	mov	dx, offset GenTextClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;carry set if text object
	mov	ax, MSG_GEN_ACTIVATE		;for non-text objects
	jnc	notText
	mov	ax, MSG_META_GRAB_FOCUS_EXCL	;grab focus for text object
notText:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;
done:
	.leave
	ret
ActivateFirstGenChild	endp

KbdNavigation ends
	 
;--------------------------------

Resident segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetParentMonikerSpace

SYNOPSIS:	Returns space reserved for moniker in center-by-moniker
		situations.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		ax -- moniker space

DESTROYED:	bx, di 
		(destroys nothing in _RUDY)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/26/93       	Initial version

------------------------------------------------------------------------------@

GetParentMonikerSpace	proc	far
	uses	si
	.enter
	call	VisSwapLockParent	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLCI_monikerSpace	;use this as the moniker space
	call	ObjSwapUnlock
exit:
	.leave
	ret
GetParentMonikerSpace	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GetNonMonikerMarginTotals

SYNOPSIS:	Returns margins, without the moniker.  Should stay equivalent
		to the get spacing routine!

CALLED BY:	OLCtrlGetExtraSize, OLCtrlCalcDesiredSize

PASS:		*ds:si -- handle of control

RETURN:		cx, dx, total composite length and width
		ax -- child spacing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 9/90		Initial version

------------------------------------------------------------------------------@

GetNonMonikerMarginTotals	proc	far		uses	bp
	class	OLCtrlClass
	
	;
	; Save the size of the moniker, so we can subtract it from the spacing.
	; We don't want to include the moniker in our extra size calculations.
	;
	.enter
	clr	cx				;assume no moniker
	clr	dx
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	jz	finishUp			;no moniker, branch

	clr	bp				;no gstate around
    	call	SpecGetGenMonikerSize		;get the moniker size in cx, dx

	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jnz	dispMkrAbove			;branch if displaying above
	
	clr	dx				;no extra on top if disp to left
	jmp	short finishUp

dispMkrAbove:
	clr	cx				;no extra on left if disp above
finishUp:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	gotMoniker
	xchg	cx, dx				;cx now composite "length" 
						;dx now composite "width"
gotMoniker:
	push	cx, dx				;save these fine moniker totals
	mov	ax, MSG_VIS_COMP_GET_CHILD_SPACING
	call	ObjCallInstanceNoLock		;get child spacing
	push	cx				;save result
	
	call	OLCtrlGetMargins		;get margins (we're not 
						;  interested in subclasses, 
						;  this is to get the mkr size)
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY	
	jz	10$
	xchg	ax, bp				;make ax, cx along length
	xchg	cx, dx				;make bp, dx along width
10$:
	add	cx, ax				;add length margins, in cx
	add	dx, bp				;add width margins, in dx
	pop	ax				;restore child spacing
	
	pop	bx				;restore moniker width
	sub	dx, bx				;subtract from width returned
	pop	bx				;restore moniker length
	sub	cx, bx				;subtract from length returned
	.leave
	ret
GetNonMonikerMarginTotals	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenPassMarginInfo

SYNOPSIS:	Sets up margin info, if needed, for MSG_VIS_RECALC_SIZE.
		Checks to see if our margins and spacing can even fit in
		a margin info word.   And if we're wrapping, we better have
		the same wrap spacing as regular spacing, or forget it.

CALLED BY:	utility

PASS:		*ds:si -- object
		ax, bp, cx, dx -- margins
		di -- child spacing
		bx -- wrap spacing

RETURN:		bp -- VisCompSpacingMarginInfo

DESTROYED:	ax, bx, bp, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version
	Chris	4/22/93		Changed to pass in wrap spacing, and check it
				here.

------------------------------------------------------------------------------@

OpenPassMarginInfo	proc	far
	;
	; Check for whether we need wrap spacing, and regular spacing won't
	; suffice.  In this case, we can't optimize.  -cbh 4/22/93
	;
	cmp	di, bx				;child spacing same as wrap?
	je	spacingOK

EC <	push	di, es							>
EC <	mov	di, segment VisCompClass				>
EC <	mov	es, di							>
EC <	mov	di, offset VisCompClass					>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	di, es							>

	mov	bx, ds:[si]			
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
				      mask VCGA_WRAP_AFTER_CHILD_COUNT 
	jnz	returnZero			;we're wrapping, give up.

spacingOK:					
	mov	bx, ax
	or	bx, bp
	or	bx, cx
	or	bx, dx
	or	bx, di
	cmp	bx, 7				;make sure all fit in 3 bits
	ja	returnZero			;nope, do via normal methods

	tst	bx				;all zeroes, we're done (ax=0)
	jz	gotMargins 

	mov	bx, cx				;now in ax/bp/bx/dx
	mov	cl, 3				;width of a field

	shl	ax, cl				;make room for top
	or	ax, bp				;add top
	shl	ax, cl				;make room for right
	or	ax, bx				;add right
	shl	ax, cl				;make room for bottom
	or	ax, dx				;add bottom
	shl	ax, cl				;make room for spacing
	or	ax, di				;add spacing

gotMargins:
	ORNF	ax, mask VCSMI_USE_THIS_INFO	;use the info
	mov	bp, ax
	jmp	short exit

returnZero:	
	clr	bp				;can't pass spacing/margin args
exit:
	ret
OpenPassMarginInfo	endp

Resident ends

MenuSepQuery	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlMenuSepQuery -- 
		MSG_SPEC_MENU_SEP_QUERY for OLCtrlClass

DESCRIPTION:	Handles a menu separator query in a minimal way.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_MENU_SEP_QUERY
		ch	= MenuSepFlags

RETURN:		ch	= MenuSepFlags, updated
		ax, cl, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/21/92		Initial Version

------------------------------------------------------------------------------@

OLCtrlMenuSepQuery	method dynamic	OLCtrlClass, MSG_SPEC_MENU_SEP_QUERY

	;see if this group is GS_USABLE

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	LONG	jz notUsable		;skip if not...

;isUsable:
	;see which case this is: were we called from sibling/parent, or child?

	test	ch, mask MSF_FROM_CHILD
	jnz	fromChild		;skip if called from child

fromSibling:
	;this method was sent by the previous sibling or the parent of this
	;object. First save the current TOP and BOTTOM separator status.


	call	ForwardMenuSepQueryToFirstChildOrSelf
					 ;forwards query through remainder of
					 ;menu. Returns flags.

;fromSiblingReturning:
	;un-recursing: we'll just return what the kids have and leave it at
	;that.

	;return with carry set
	stc
	ret

fromChild:
	;this method was sent by the last child of this object. Store the
	;computed HAS_USABLE_CHILD status for later.

	ANDNF	ch, not (mask MSF_FROM_CHILD)	;reset flag
	call	ForwardMenuSepQueryToNextSiblingOrParent

;fromChildReturning:
	;now we are travelling back up the menu: see if a separator should
	;be drawn below this object.

	stc
	ret

notUsable:
	;this object is not usable: pass the SEP and USABLE flags as is,
	;and return them as is.

	call	ForwardMenuSepQueryToNextSiblingOrParent
	ret
OLCtrlMenuSepQuery	endm

MenuSepQuery	ends
