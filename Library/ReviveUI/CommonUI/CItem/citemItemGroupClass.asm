COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUICItem (common code for specific UIs)
FILE:		citemItemGroupClass.asm

ROUTINES:
	 Name			Description
	 ----			-----------
    INT OLItemGroupHintMakeDefaultFocus 
				Initialize item group from a Generic Group
				object.

    INT OLItemGroupAvoidToolbox Initialize item group from a Generic Group
				object.

    MTD MSG_SPEC_SET_USABLE     Sets an object usable, doing the vis stuff
				necessary.

    MTD MSG_SPEC_BUILD          We intercept this here to test if this list
				is inside a menu.

    MTD MSG_SPEC_GET_SPECIFIC_VIS_OBJECT 
				Returns specific visual object for this
				generic object.

    INT InitFocusItem           Initializes the focus item.

    MTD MSG_SPEC_BUILD_BRANCH   Builds the branch for this item group

    MTD MSG_SPEC_UNBUILD        Unbuilds.

    INT MakePopupListIfNeeded   Makes an item group into a popup list.

    INT CopyHintIfSpecified     Makes an item group into a popup list.

    INT CheckIfInPopup          Checks to see if the object is below a
				popup GenInteraction.

    INT UseFixedHeightIfSpecified 
				Takes any height that is specified on the
				item group and uses it as a minimum height
				for the menu button.  This is generally
				needed for dynamic popup lists whose button
				displays the currently selected item.  Some
				kind of minimum size necessary in this case
				for the button to have any size at all
				before the dynamic list items are built
				out.

    INT FixSize                 Fixes size to work in a popup list button.

    INT CheckChildUnique        Checks to make sure child is unique.

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS 
				Scans geometry hints.

    INT ItemGroupHasGeoHint     Scans geometry hints.

    INT ItemGroupProperty       Scans geometry hints.

    INT ItemGroupNotProperty    Scans geometry hints.

    INT OLItemGroupScanPopupHints 
				Copies some hints to visual parent.

    INT OLIGCopyHint            Copies some hints to visual parent.

    INT ItemGroupWrapAfterChildCount 
				Copies some hints to visual parent.

    INT SetupDynamicListItems   If we're a dynamic list, sends appropriate
				messages to initiate the query mechanism.

    MTD MSG_VIS_OPEN            Handles vis open.

    INT StoreInitialSelectionForResetIfDelayed 
				If delayed, Squirrel the current selection
				away in case we get RESET later.

    MTD MSG_VIS_RECALC_SIZE     Recalc's size.

    MTD MSG_VIS_POSITION_BRANCH Positions the object.

    INT ItemGroupPassMarginInfo Passes margin info for OpenRecalcCtrlSize.

    MTD MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE 
				Returns typical extra size for a child of
				this object.

    MTD MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN 
				Resets size of everything to stay onscreen.

    INT CalcNewExtent           Figures out the current extent item.

    MTD MSG_OL_IGROUP_TOGGLE_ADD_MODE 
				Toggles add mode in the item group.

    MTD MSG_OL_IGROUP_DESELECT_ALL 
				Deselects all items in the item group.

    INT EC_DerefVisDI           Deselects all items in the item group.

    INT EC_DerefGenDI           Deselects all items in the item group.

    INT EC_ObjMessageCall       Deselects all items in the item group.

    INT EC_ObjCallInstanceNoLock 
				Deselects all items in the item group.

    MTD MSG_OL_IGROUP_START_EXTENDED_SELECTION 
				Starts extended selection.

    MTD MSG_OL_IGROUP_EXTEND_SELECTION 
				Extends selection appropriately, from a
				mouse operation.

    MTD MSG_OL_IGROUP_END_EXTENDED_SELECTION 
				Ends extended selection.

    INT ExtendSelectionSettingItems 
				Extends the selection.

    INT ExtendSelection         Extends the selection.

    INT SetToToggleAnchorItem   Gets anchor item state, and prepares any
				subsequent extended selections to toggle
				the state.

    INT CheckIfInAddMode        Checks to see if we're in add mode.

    INT CheckChildInExtent      Checks if child is in extent rectangle
				passed.

    INT IsBetween               Checks if child is in extent rectangle
				passed.

    INT IsNonExclusive          Checks to see if we're a non-exclusive
				behaving group. Works for OLItemGroups and
				OLBooleanGroups.

    INT IsExtendedSelection     Checks to see if we're an
				extended-selection behaving group. Works
				for OLItemGroups and OLBooleanGroups.

    INT GetFocusItemOptr        Returns optr of focus item, or null if no
				focus item, of the list itself if there is
				a focus item, but it doesn't currently
				exist under the list.

    INT GetOptr                 Returns optr of focus item, or null if no
				focus item, of the list itself if there is
				a focus item, but it doesn't currently
				exist under the list.

    INT SetFocusFromOptr        Sets the focus, given an optr.

    INT SetFocusItem            Sets the focus item.

    INT GetIdentifierFromCxDx   Returns identifier of object.

    INT IsFocusItemOptr         Returns whether focus item is the optr.

    INT IsFocusItem             Returns item passed has the focus

    GLB FindChildIdentifier     Callback routine to find child with given
				identifier

    INT ECEnsureNotBooleanGroup Ensures that this is not a boolean group
				object.

    INT RemoveDynamicListItems  Removes dynamic list items during unbuild.

    INT SetAnchorItem           Sets an anchor item.  Invalidates the
				extended selection.

    MTD MSG_SPEC_MENU_SEP_QUERY This method travels the visible tree within
				a menu, to determine which OLMenuItemGroups
				need top and bottom separators to be drawn.

    MTD MSG_META_GRAB_FOCUS_EXCL 
				if popup list, pass request to popup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItemGroup.asm

DESCRIPTION:
	$Id: citemItemGroupClass.asm,v 1.27 97/03/31 21:20:48 cthomas Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	 OLItemGroupClass		mask CLASSF_DISCARD_ON_SAVE or \
					 mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;-----------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupInitialize -- MSG_META_INITIALIZE
			 for OLItemGroupClass

DESCRIPTION:	Initialize item group from a Generic Group object.

PASS:		*ds:si - instance data
		 es - segment of OlMenuClass
		 ax - MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	 Name	Date		Description
	 ----	----		-----------
	 Doug	2/89		Initial version
	 Eric	3/90		cleanup
	 Chris	5/92		GenItemGroupClass V2.0 rewrite
	 sean	5/96		Added vardata handler for 
				HINT_ITEM_GROUP_TAB_STYLE

------------------------------------------------------------------------------@

OLItemGroupInitialize	method private static	OLItemGroupClass, 
							 MSG_META_INITIALIZE
	 uses	bx, di, es		; To comply w/static call requirements
	 .enter				; that bx, si, di, & es are preserved.
					 ; NOTE that es is NOT segment of class
;	 mov	di, segment dgroup
;	 mov	es, di			; now it is :)

	 ;call superclass for default initialization (will grow out visible
	 ;portion of object)
	 segmov	es, <segment OLItemGroupClass>, di
	 mov	di, offset OLItemGroupClass
	 CallSuper MSG_META_INITIALIZE

	 ;Set current size w/desired size constants.  THe first time the
	 ;geometry is updated, it will use this value.

	 mov	cx, mask RSA_CHOOSE_OWN_SIZE
	 mov	dx, cx
	 call	VisSetSize

	 ;Before we scan hints, set the color flag in the state, if applicable.

	 mov	di, ds:[si]			
	 add	di, ds:[di].Vis_offset
	 mov	cl, ds:[di].OLIGI_state	;get OLItemGroupState (may have been
					 ;written to by subclasses)
	 ;
	 ; Let's mark ourselves as a dynamic list, if need be.
	 ;
	 mov	di, segment GenDynamicListClass				
	 mov	es, di							
	 mov	di, offset GenDynamicListClass				
	 call	ObjIsObjectInClass					
	 jnc	30$				
	 or	cl, mask OLIGS_DYNAMIC
30$:
	 ;
	 ; Let's mark ourselves as a boolean group, if need be.
	 ;
	 mov	di, segment GenBooleanGroupClass				
	 mov	es, di							
	 mov	di, offset GenBooleanGroupClass				
	 call	ObjIsObjectInClass					
	 jnc	40$				
	 or	cl, mask OLIGS_CHECKBOXES
;	 jmp	50$
40$:

	 ; *** Only do this if this is not a BooleanGroup ***

	 ;Before doing anything else, we'll force GIGI_numSelections from 0 to
	 ;1 if GIGI_selection != GIGS_NONE.  This helps programmers to the right
	 ;thing.  (Moved to generic relocate handler.  -cbh 2/23/93)

;	 call 	Build_DerefGenDI
;	 tst	ds:[di].GIGI_numSelections
;	 jnz	50$
;	 cmp	ds:[di].GIGI_selection, GIGS_NONE
;	 je	50$
;	 inc	ds:[di].GIGI_numSelections
;50$:

	 ;SCAN HINTS to figure out what kind of children to use.
	 ;(CL = OLIGI_state value, to be updated by hints)

	 segmov	es, cs				; Point to segment w/ hint
	 mov	di, offset cs:OLItemGroupHints	
	 mov	ax, length (cs:OLItemGroupHints)	
	 call	OpenScanVarData

	 call 	Build_DerefVisSpecDI
	 mov	ds:[di].OLIGI_state, cl

	; Setting focus to selection used to be here. -cbh 10/20/92

EC <	mov	ax, MSG_OL_IGROUP_EC_CHECK_ALL_CHILDREN_UNIQUE		>
EC <	call	ObjCallInstanceNoLock					>
	 ;
	 .leave
	 ret
OLItemGroupInitialize	endp


;VERY IMPORTANT: CL contains OLIGI_state flags during these hint handlers.
;Do not trash cl!

	; Added scan/handler for HINT_ITEM_GROUP_TAB_STYLE.
	;
OLItemGroupHints	VarDataHandler \
	 <HINT_DEFAULT_FOCUS, \
			 offset Build:OLItemGroupHintMakeDefaultFocus>,
if	_ODIE
	 <HINT_ITEM_GROUP_TAB_STYLE, \
			 offset Build:OLItemGroupTabStyle>,
endif
	 <HINT_ITEM_GROUP_MINIMIZE_SIZE, \
			 offset Build:OLItemGroupAvoidToolbox>


OLItemGroupHintMakeDefaultFocus	proc	far
	 class	OLItemGroupClass

	 ORNF	cl, mask OLIGS_DEFAULT_FOCUS
	 ret
OLItemGroupHintMakeDefaultFocus	endp

OLItemGroupAvoidToolbox proc	far
	class	OLItemGroupClass

	;
	; Avoid setting the toolbox flag.  Popup lists cannot be set as a
	; toolbox if the hint is directly on them -- only if the hint is
	; above them.   This will only affect orphan-toolboxed item groups --
	; OLBF_TOOLBOX will be set on the item group during spec build
	; if the parent is a toolbox, no matter what.  5/18/93 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLCI_buildFlags, not mask OLBF_TOOLBOX
	ret
OLItemGroupAvoidToolbox endp

if	_ODIE
	; For Odie, we don't want tabs focusable.
	;
OLItemGroupTabStyle proc	far
	class	OLItemGroupClass

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset	
	ornf	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	ret
OLItemGroupTabStyle endp
endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupSetUsable -- 
		 MSG_SPEC_SET_USABLE for OLItemGroupClass

DESCRIPTION:	Sets an object usable, doing the vis stuff necessary.

PASS:		*ds:si 	- instance data
		 es     	- segment of MetaClass
		 ax 	- MSG_SPEC_SET_USABLE

		 dl	- update mode

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
	 chris	5/18/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupSetUsable	method dynamic	OLItemGroupClass, MSG_SPEC_SET_USABLE
	 push	dx
	 mov	di, offset OLItemGroupClass
	 call	ObjCallSuperNoLock
	 pop	dx

	 call 	Build_DerefVisSpecDI
	 test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	 jz	exit
	 ;
	 ; If we're a popup list, the default spec build handler wasn't smart
	 ; enough to update the menu button's window.  We'll do it now.
	 ;
	 mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	 call	GenCallParent
exit:
	 ret
OLItemGroupSetUsable	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupSpecBuild

DESCRIPTION:	We intercept this here to test if this list is inside a menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	 Name	Date		Description
	 ----	----		-----------
	 Eric	7/90		initial version
	 Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupSpecBuild	method	dynamic	OLItemGroupClass, MSG_SPEC_BUILD

	 call	VisSpecBuildSetEnabledState	; make sure this happens.

	 ;If the item group is supposed to fit in a small are, we'll put it
	 ;in a popup list.

	 call	MakePopupListIfNeeded

if _RUDY
	; In Rudy, this item group might run in the mode of it's
	; Gen (settings dialog) or Vis (popup list) parent, depending
	; on a decision made when MSG_SPEC_CHANGE hits it.
	; We'll record the OLBF_DELAYED_MODE flag returned from both,
	; so that we can diddle our own to the correct value at that time.
	; (Vis delayed mode is set below, after superclass build and
	; scanning geometry hints)
	; -CT 12/4/95

	CheckHack <offset OLCRF_GEN_IS_DELAYED lt offset OLBF_DELAYED_MODE>

	;
	; Extract OLBF_DELAYED_MODE and place it into OLCRF_GEN_IS_DELAYED
	;

	call 	Build_DerefVisSpecDI
	andnf	ds:[di].OLCI_rudyFlags, not (mask OLCRF_GEN_IS_DELAYED or \
					     mask OLCRF_VIS_IS_DELAYED)
	mov	ax, ds:[di].OLCI_buildFlags
	andnf	ax, mask OLBF_DELAYED_MODE
	mov	cl, offset OLBF_DELAYED_MODE - offset OLCRF_GEN_IS_DELAYED
	shr	ax, cl
	ornf	ds:[di].OLCI_rudyFlags, ax

endif ; _RUDY


	;first call superclass, so that the OLCOF_IN_MENU flag can be set.

	mov	di, offset OLItemGroupClass
	CallSuper MSG_SPEC_BUILD

	;Set horizontal/vertical orientation default according to whether
	;is in menu or not.

	call 	Build_DerefVisSpecDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	10$			;skip if not inside menu...

	;and force the completesInteraction flag TRUE in the
	;GenAttributes field, so that menus will get dismissed when you make
	;a selection, EVEN if the ignoreInput flag is TRUE, preventing the
	;menu from getting the POST_PASSIVE_BUTTON event.

	call 	Build_DerefGenDI
	ORNF	ds:[di].GI_attrs, mask GA_SIGNAL_INTERACTION_COMPLETE
10$:
	call	OLItemGroupScanGeometryHints	;Yes, we scanned Ctrl geometry
						 ;hints in the superclass
						 ;spec build.  Sigh.

if _RUDY
	;
	; OLCI_buildFlags has now inherited the Vis Parent's delayed mode.
	; Extract OLBF_DELAYED_MODE and place it into OLCRF_VIS_DELAYED
	;
	call 	Build_DerefVisSpecDI
	mov	ax, ds:[di].OLCI_buildFlags
	andnf	ax, mask OLBF_DELAYED_MODE
	mov	cl, offset OLBF_DELAYED_MODE - offset OLCRF_VIS_IS_DELAYED
	shr	ax, cl
	ornf	ds:[di].OLCI_rudyFlags, ax

endif ; _RUDY

	call	SetupDynamicListItems		

	call	InitFocusItem			;moved from initialize 10/20/92

if _HAS_LEGOS_LOOKS
	call	LegosSetChoiceLookFromHints
endif
	;
	; Mark the dialog box applyable if we're coming up modified, via
	; the queue, to ensure the dialog box is all set up.
	; -cbh 2/ 9/93
	;
	call 	Build_DerefGenDI
	test	ds:[di].GIGI_stateFlags, mask GIGSF_MODIFIED
	jz	exit
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
exit:
	ret
OLItemGroupSpecBuild	endm


if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegosSetChoiceLookFromHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The legos look is stored in instance data, so when
		we unbuild and rebuild we need to set it from the hints.

CALLED BY:	OLItemGroupSpecBuild
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
LegosSetChoiceLookFromHints	proc	near
	uses	ax, bx, bp, di
	.enter

	clr	bp			; our table index

	;
	; Start our indexing at 1, as 0 has no hint
	;
loopTop:
	inc	bp
	inc	bp			; next entry
	mov	ax, cs:[buildLegosChoiceLookHintTable][bp]
	call	ObjVarFindData
	jc	gotLook

	cmp	bp, LAST_BUILD_LEGOS_CHOICE_LOOK * 2
	jl	loopTop

	clr	bp			; no hints found, so must be look 0

gotLook:
	mov	ax, bp			; use ax as bp can't be byte addressable
	sar	ax, 1			; words to bytes
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLIGI_legosLook, al
done:
	.leave
	ret
LegosSetChoiceLookFromHints	endp

	;
	; Make sure this table matches that in citemItemGroupCommon.asm.
	; The only reason the table is in two places it is that I don't
	; want to be bringing in the ItemCommon resource at build time,
	; and it is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
buildLegosChoiceLookHintTable	label word
	word	0
if _PCV
	word	HINT_ITEM_GROUP_PCV_RADIO_BUTTON_STYLE
	word	HINT_ITEM_GROUP_LOWER_LEFT_STYLE
	word	HINT_ITEM_GROUP_LOWER_RIGHT_STYLE
	word	HINT_ITEM_GROUP_UPPER_TAB_STYLE
	word	HINT_ITEM_GROUP_LOWER_TAB_STYLE
	word	HINT_ITEM_GROUP_BLANK_STYLE
endif
LAST_BUILD_LEGOS_CHOICE_LOOK	equ ((($ - buildLegosChoiceLookHintTable) / \
					(size word)) - 1)
CheckHack<LAST_BUILD_LEGOS_CHOICE_LOOK eq LAST_LEGOS_CHOICE_LOOK>

endif		; if _HAS_LEGOS_LOOKS




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupGetSpecificVisObject -- 
		MSG_SPEC_GET_SPECIFIC_VIS_OBJECT for OLItemGroupClass

DESCRIPTION:	Returns specific visual object for this generic object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_SPECIFIC_VIS_OBJECT

RETURN:		carry set if anything interesting, with:
			^lcx:dx - specific object
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/22/93         	Initial Version

------------------------------------------------------------------------------@

OLItemGroupGetSpecificVisObject	method dynamic	OLItemGroupClass, \
				MSG_SPEC_GET_SPECIFIC_VIS_OBJECT

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	exit				;not a popup list, branch (C=0)
	call	VisCallParent			;else send to parent popup
exit:
	ret
OLItemGroupGetSpecificVisObject	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	InitFocusItem

SYNOPSIS:	Initializes the focus item.

CALLED BY:	OLItemGroupSpecBuild

PASS:		*ds:si -- item group

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/20/92	Initial version

------------------------------------------------------------------------------@

InitFocusItem	proc	far
	 ;
	 ; For some reason, exit if not scrollable.  The reason we skip the rest
	 ; of the code escapes me now.   Removed, cbh to make scrolling lists
	 ; work -- we'll see what happens.  -cbh 10/20/92
	 ;
;	 call 	Build_DerefVisSpecDI
;	 test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE 
;	 jnz	exit

	 ;
	 ; If this is a non-exclusive list, set some flags. If is an exclusive
	 ; list, will set up the selection when the items
	 ; are set USABLE.
	 ;
	 call	IsNonExclusive
	 jc	nonExclusiveInit

exclusiveInit:
	 call	OLItemGroupScanListForExcl
	 jc	exit			;skip if successful...
;	 jmp	short setFocusToFirst	;skip to set FOCUS to first item.

nonExclusiveInit:
	 ;For Motif/CUA/Dogmate, if the group is nonexclusive, use X-boxes, not
	 ;radio buttons.

	 ;uncomment above line if adding code here!

setFocusToFirst:
	 ;place the FOCUS exclusive (for within this GenList) on the first
	 ;item which is USABLE and ENABLED.

	 call	OLItemGroupGetFirstItemOptr
	 jnc	exit			;skip if found none...
	 call	SetFocusFromOptr	;set focus item
					 ;can stuff values directly, because
					 ;we are in MSG_META_INITIALIZE handler.

exit:
	ret
InitFocusItem	endp






COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupSpecBuildBranch -- 
		 MSG_SPEC_BUILD_BRANCH for OLItemGroupClass

DESCRIPTION:	Builds the branch for this item group

PASS:		*ds:si 	- instance data
		 es     	- segment of MetaClass
		 ax 	- MSG_SPEC_BUILD_BRANCH
		 bp	- SpecBuildFlags

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
	 chris	4/29/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupSpecBuildBranch	method dynamic	OLItemGroupClass, \
			 MSG_SPEC_BUILD_BRANCH

	 mov	di, offset OLItemGroupClass
	 CallSuper	MSG_SPEC_BUILD_BRANCH
	 call	SetPopupListMonikerIfNeeded
	 ret
OLItemGroupSpecBuildBranch	endm


 
COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupUnbuild -- 
		 MSG_SPEC_UNBUILD for OLItemGroupClass

DESCRIPTION:	Unbuilds.  

PASS:		*ds:si 	- instance data
		 es     	- segment of MetaClass
		 ax 	- MSG_SPEC_UNBUILD

RETURN:		
		 ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		 bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 8/92		Initial Version
	chris	12/19/92	Changed to destroy parent moniker on popup list

------------------------------------------------------------------------------@

OLItemGroupUnbuild	method dynamic	OLItemGroupClass, MSG_SPEC_UNBUILD
	;
	; Clearly no longer displaying our selection, zero this flag so it will
	; get initially redrawn if we come back to life.
	;
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_DISPLAYING_SELECTION
						
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	pushf	
	push	bp
	call	RemoveDynamicListItems		;remove any dynamic items
	pop	bp
	popf
	mov	di, 0				;assume no popup list
	mov	ax, di				;  and not destroying parent mkr
	jz	10$				;nope, branch to just remove
						;   ourselves
	mov	di, si				;*ds:di <- ourselves
	call	VisFindParent			;*ds:si <- parent interaction
	xchg	di, si				;*ds:di -- parent,
						;*ds:si -- ourselves
	mov	ax, si				;ax!=0: destroy parent moniker
10$:
	clr	bl				;not a view
	call	OpenUnbuildCreatedParent	;unbuildem
	ret
OLItemGroupUnbuild	endm







COMMENT @----------------------------------------------------------------------

ROUTINE:	MakePopupListIfNeeded

SYNOPSIS:	Makes an item group into a popup list.

CALLED BY:	OLItemGroupSpecBuild

PASS:		*ds:si -- item group
		bp -- SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/28/92		Initial version

------------------------------------------------------------------------------@

MakePopupListIfNeeded	proc	near		uses	bp
	.enter

	;First of all, make sure the delayed mode flags are set
	;before we juggle our parent.  At the moment we can get the info from
	;the parent; once there's a win group in between, we won't get the
	;right value.  (Probably should update the popup window with the
	;correct delayed mode values, too, but who cares.)  -cbh 8/26/92
	;(The toolbox flag shouldn't be set here, as toolbox style items in a
	; menu will not work.)

	clr	cx
	mov	ax, MSG_VUP_GET_BUILD_FLAGS	; else send message to self
	call	GenCallParent
	and	cx, mask OLBF_DELAYED_MODE
	call 	Build_DerefVisSpecDI
	ORNF	ds:[di].OLCI_buildFlags, cx

	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
	call	ObjVarFindData
	jc	makePopup			;found, handle

if _RUDY
	;
	; Rudy, all non-scrollable, non-boolean, not in popup item groups 
	; become popup lists.
	;
	call	CheckIfInPopup			;in a popup already, exit
	LONG	jc	exit

	push	es
	mov	di, segment GenBooleanGroupClass
	mov	es, di
	mov	di, offset GenBooleanGroupClass
	call	ObjIsObjectInClass
	pop	es
	LONG	jc	exit			;boolean group, no popup

	mov	ax, HINT_ITEM_GROUP_SCROLLABLE
	call	ObjVarFindData
	LONG	jc	exit			;scrollable item groups do not
						;  automatically become popups
else
	call	OpenCheckIfVerticalScreen	;vertical screen?
	LONG	jnc	exit			;no, done
						;else, check if vertical screen
						;	hint
	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE_IF_VERTICAL_SCREEN
	call	ObjVarFindData
	LONG	jnc	exit			;not found, exit
endif

makePopup:
	push	bp				;build flags
	;
	; Get out keyboard moniker and save it.  -cbh 12/ 2/92
	;
	call	Build_DerefGenDI
	push	ds:[di].GI_kbdAccelerator

	;
	; The first order of business is to place ourselves in a popup window.
	;
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	call	OpenCreateNewParentObject	;popup GenInteraction in di
	pop	ax				;restore kbdAccelerator

	xchg	si, di				;new parent in *ds:si
						;item group in *ds:di

if _RUDY
	push	di				;save location of interaction
	mov	di, ds:[di]			;   should be for all products
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLIGI_popupInteraction, si
	pop	di
endif

	push	di

	call 	Build_DerefGenDI
	mov	ds:[di].GI_kbdAccelerator, ax	;copy accel to parent (12/ 2/92)

if _RUDY
	mov	ds:[di].GII_attrs, mask GIA_MODAL
	mov	ds:[di].GII_type, GIT_PROPERTIES
endif
	mov	ds:[di].GII_visibility, GIV_POPUP

	mov	ax, HINT_IS_POPUP_LIST		;make sure added at current spot
	clr	cx				
	call	ObjVarAddData
	pop	di				;*ds:di -- item group
						;*ds:si -- parent interaction

if _RUDY
 	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT   ;desperation attempt
 						       ; to clean up popups
 	clr	cx				
 	call	ObjVarAddData
endif

if BUBBLE_DIALOGS
	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarDeleteData
endif

	clr	cx
	mov	ax, HINT_CAN_CLIP_MONIKER_WIDTH
	call	CopyHintIfSpecified
if _RUDY ; We want to propigate focus issues from lists to the buttons
         ; that activate them.
	mov	ax, HINT_DEFAULT_FOCUS
	call	CopyHintIfSpecified
endif ; _RUDY
	mov	cx, 2
	mov	ax, HINT_GADGET_TEXT_COLOR
	call	CopyHintIfSpecified
	mov	bp, si				;bp = obj to clear visMoniker of

	xchg	si, di				;*ds:si <- item group, 
						;*ds:di <- parent
	pop	ax				;build flags
	clr	bx				;not creating a view
	call	OpenBuildNewParentObject	;build a view, place us 
						;   underneath
	call 	Build_DerefVisSpecDI
	ORNF	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST

if _RUDY
	; Force the ItemGroup to use a bold moniker.  It's a spec thing.
	;
	ORNF 	ds:[di].OLCI_rudyFlags, mask OLCRF_USE_LARGE_FONT or \
					mask OLCRF_FORCE_BOLD_MONIKER

	mov	ax, HINT_PLACE_MONIKER_ABOVE
	clr	cx
	call	ObjVarAddData			;try it this way

	;
	; get popup list moniker's underline to reach to the reply buttons
	;
	mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
	clr	cx
	call	ObjVarAddData
endif

	call	IsExtendedSelection		;extended selection?
	jc	done				;yes, skip extended stuff

	call	IsNonExclusive			;non-exclusive, done
	jc	done				;
	
if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	mov	ax, HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION
	call	ObjVarFindData
	jnc	done				;not found, exit
endif
	call 	Build_DerefVisSpecDI
	ornf	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	mov	di, ds:[bp]
	add	di, ds:[di].Gen_offset
	clr	ds:[di].GI_visMoniker		;nuke the copied moniker chunk,
						;  we'll set it via a copy later
done:
	stc					;say built new parent
exit:
	.leave
	ret
MakePopupListIfNeeded	endp



CopyHintIfSpecified	proc	near
	;
	; *ds:di -- source, *ds:si -- dest.  cx = bytes of extra data
	; word of data to copy (either 2 or 0, currently)
	;
	
	push	dx
	xchg	si, di				;*ds:si <- item group
	call	ObjVarFindData			;look for hint in item group 
	xchg	si, di
	jnc	exit				;not found, exit
	jcxz	10$
	mov	dx, {word} ds:[bx]
10$:
	call	ObjVarAddData			;else add hint to parent
	jcxz	exit
	mov	{word} ds:[bx], dx
exit:
	pop	dx
	ret
CopyHintIfSpecified	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfInPopup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the object is below a popup GenInteraction.

CALLED BY:	MakePopupListIfNeeded

PASS:		*ds:si -- object

RETURN:		carry set if in popup

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

CheckIfInPopup	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; search up the generic tree for popup

	mov	bx, ds:[LMBH_handle]

findPopupLoop:
	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	clc
	jcxz	exit				;exit, c=0

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment GenInteractionClass
	mov	dx, offset GenInteractionClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	exit				;exit, c=0

	movdw	bxsi, cxdx			;^lbx:si = GenInteraction
	mov	ax, MSG_GEN_INTERACTION_GET_VISIBILITY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	cl, GIV_DIALOG
	je	exit				;exit, c=0
	cmp	cl, GIV_POPUP
	jne	findPopupLoop

inPopup:
	stc					;in popup interaction, c=1
exit:
	.leave
	ret
CheckIfInPopup	endp

endif




COMMENT @----------------------------------------------------------------------

ROUTINE:	UseFixedHeightIfSpecified

SYNOPSIS:	Takes any height that is specified on the item group and uses
		it as a minimum height for the menu button.  This is generally
		needed for dynamic popup lists whose button displays the
		currently selected item.  Some kind of minimum size necessary
		in this case for the button to have any size at all before the
		dynamic list items are built out.

CALLED BY:	MakePopupListIfNeeded

PASS:		*ds:si -- popup list

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/27/92       	Initial version

------------------------------------------------------------------------------@

UseFixedHeightIfSpecified	proc	near		uses	es, bp, si
	.enter
	call	VisSwapLockParent		;get at the parent interaction
	jnc	exit
	push	bx

	mov	di, cs
	mov	es, di
	mov	di, offset cs:IntSizeHints
	mov	ax, length (cs:IntSizeHints)
	call	ObjVarScanData			;scan for raw hints

	pop	bx
	call	ObjSwapUnlock
exit:
	.leave
	ret
UseFixedHeightIfSpecified	endp

IntSizeHints	VarDataHandler \
 <HINT_INITIAL_SIZE, offset FixSize>,
 <HINT_MINIMUM_SIZE, offset FixSize>,
 <HINT_MAXIMUM_SIZE, offset FixSize>,
 <HINT_FIXED_SIZE, offset FixSize>




COMMENT @----------------------------------------------------------------------

ROUTINE:	FixSize

SYNOPSIS:	Fixes size to work in a popup list button.

CALLED BY:	UseFixedHeightIfSpecified (via ObjVarScanData)

PASS:		*ds:si -- a GenItemGroup's parent GenInteraction
		ds:bx -- pointer to hint data

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/27/92       	Initial version

------------------------------------------------------------------------------@

FixSize	proc	far
	VarDataSizePtr	ds, bx, ax
	cmp	ax, size CompSizeHintArgs
	jne	exit			;do nothing if no count specified

	mov	cx, ({CompSizeHintArgs} ds:[bx]).CSHA_count
	cmp	cx, 1
	jbe	exit			;no child count, or one child, exit
	
	mov	ax, ({CompSizeHintArgs} ds:[bx]).CSHA_height
	mov	bp, ax
	and	bp, mask SSS_TYPE	;save type in bp
	and	ax, mask SSS_DATA	;look at data only
	clr	dx
	div	cx			;divide height by num children
	or	ax, bp			;get type back
	mov	({CompSizeHintArgs} ds:[bx]).CSHA_height, ax
	mov	({CompSizeHintArgs} ds:[bx]).CSHA_count, 1
					;save new values
exit:
	ret
FixSize	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	ECCheckAllChildrenUnique

SYNOPSIS:	Make sure all children are unique.

CALLED BY:	GenItemGroupSetIndeterminateState

PASS:		*ds:si -- item group

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 2/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckAllChildrenUnique method OLItemGroupClass, \
			 MSG_OL_IGROUP_EC_CHECK_ALL_CHILDREN_UNIQUE

	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	10$
	GOTO	OLBooleanGroupCheckAllChildrenUnique
10$:
	;
	; Make room for all the generic children.
	;
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jnz	exit				;dynamic, has intermediate
						;  states where ID's aren't set
						;  up, skip error checking
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock		;returned in dx
	shl	dx, 1				;double for word offset
	sub	sp, dx
	mov	bp, sp
	push	dx				;save size of buffer
	mov	cx, bp				;keep buffer start in cx

	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx,offset CheckChildUnique
	push	bx				;pass callback routine (off)
	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
						;returns list of ID's 
	pop	dx				;restore size of buffer
	add	sp, dx
exit:
	ret
ECCheckAllChildrenUnique	endp

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckChildUnique

SYNOPSIS:	Checks to make sure child is unique.

CALLED BY:	ObjCompProcessChildren (via ECCheckAllChildrenUnique)

PASS:		*ds:si -- child in question
		ss:bp  -- place to add identifier
		ss:cx  -- start of list

RETURN:		bp     -- passed bp+2

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 2/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

CheckChildUnique	proc	far		uses	cx
	class	GenItemClass

	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GII_identifier	;add identifier to list

	mov	di, cx				;have es:di point to buffer
	segmov	es, ss
	push	bp
	sub	bp, cx				;get size of buffer
	shr	bp, 1				;divide by two for word count
	mov	cx, bp
	tst	cx
	jz	10$
	repne	scasw				;scan for the ID in buffer
	ERROR_E	OL_ERROR_NO_TWO_ITEMS_CAN_HAVE_SAME_IDENTIFIER
10$:
	pop	bp				;nothing found, restore bp

	mov	ss:[bp], ax			;store ID in buffer
	add	bp, 2				;bump the buffer count
	clc					;continue
	.leave
	ret
CheckChildUnique	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLItemGroupClass

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

OLItemGroupScanGeometryHints	method static OLItemGroupClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLItemGroupClass
	mov	es, di

	; Handle OLCtrl stuff.  

	mov	di, offset OLItemGroupClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;
	; Change the orientation of this object to be horizontal only if
	; no orientation was already specified and we're not in a menu.
	; (Rudy, everything's vertical regardless.)
	;
if not _RUDY
	clr	cx				; no orientation hint yet
endif
	segmov	es, cs				
	mov	di, offset cs:OLItemGroupHints2	
	mov	ax, length (cs:OLItemGroupHints2)	
	call	ObjVarScanData

if not _RUDY
	tst	cx				; did an orientation hint exist?
	jnz	checkPopup			; yes, get out

	call	Build_DerefVisSpecDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jnz	checkPopup			; in a menu, get out

	; Default to a horizontal orientation.  

	and	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY

checkPopup:

else	;_RUDY
	call	Build_DerefVisSpecDI
	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
endif

	call	Build_DerefVisSpecDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	exit

	; Popup list, default to a vertical orientation, thank you very much.
	; (Also center horizontally.  Vertical centering set on all windows,
	;  mainly for the benefit of popup lists.)

	call	OLItemGroupAvoidToolbox		;don't be a toolbox. 5/19/93 cbh
						;  toolbox-style is still OK.
	call	OLItemGroupScanPopupHints
	call	UseFixedHeightIfSpecified	;transfer fixed height of the
						;  list up to the menu button 
exit:
	.leave
	ret
OLItemGroupScanGeometryHints	endm

if _RUDY
OLItemGroupHints2	VarDataHandler \
 	<ATTR_GEN_PROPERTY, offset Build:ItemGroupProperty>, 
	<ATTR_GEN_NOT_PROPERTY, offset Build:ItemGroupNotProperty>
else
OLItemGroupHints2	VarDataHandler \
	<HINT_ORIENT_CHILDREN_VERTICALLY, \
				offset Build:ItemGroupHasGeoHint>,
	<HINT_ORIENT_CHILDREN_HORIZONTALLY, \
				offset Build:ItemGroupHasGeoHint>,
	<HINT_SAME_ORIENTATION_AS_PARENT, \
				offset Build:ItemGroupHasGeoHint>,
	<HINT_ORIENT_CHILDREN_ALONG_LARGER_DIMENSION, \
				offset Build:ItemGroupHasGeoHint>,
 	<ATTR_GEN_PROPERTY, offset Build:ItemGroupProperty>, 
	<ATTR_GEN_NOT_PROPERTY, offset Build:ItemGroupNotProperty>
endif

;------------------------------------------------------------------------------
;	If HINT_ORIENT_CHILDREN_VERTICALLY is used, then set the geometry flags 
;	appropriately.
;------------------------------------------------------------------------------

if not _RUDY
ItemGroupHasGeoHint	proc	far
	dec	cx				;has orientation hint
	ret
ItemGroupHasGeoHint	endp
endif

ItemGroupProperty	proc	far
	call	Build_DerefVisSpecDI
	or	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
if _RUDY
	or	ds:[di].OLCI_rudyFlags, mask OLCRF_VIS_IS_DELAYED or \
					mask OLCRF_GEN_IS_DELAYED
endif
	ret
ItemGroupProperty	endp

ItemGroupNotProperty	proc	far
	call	Build_DerefVisSpecDI
	and	ds:[di].OLCI_buildFlags, not mask OLBF_DELAYED_MODE
if _RUDY
	and	ds:[di].OLCI_rudyFlags, not (mask OLCRF_VIS_IS_DELAYED or \
					     mask OLCRF_GEN_IS_DELAYED)
endif
	ret
ItemGroupNotProperty	endp


	

COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemGroupScanPopupHints

SYNOPSIS:	Copies some hints to visual parent.

CALLED BY:	OLItemGroupScanGeometryHints

PASS:		*ds:si -- item group object

RETURN:		nothing

DESTROYED:	ax, bx, cx

		NOTE:  invalidates any chunk pointers, dereference them
			again or die

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/25/91		Initial version

------------------------------------------------------------------------------@
MIN_POPUP_CHAR_WIDTH	equ	10

OLItemGroupScanPopupHints	proc	near		
	class	OLItemGroupClass

	mov	bp, si				;*ds:bp <- item group
	call	VisFindParent			;^lbx:si <- parent
EC <	clr	cx				;zero seg if no parent	>
	tst	bx
	jz	10$
	call	ObjLockObjBlock			;*ax:si = parent
	mov_tr	cx, ax				;*cx:si = parent

if _RUDY
;	;
;	; In Rudy, popup lists should always be at least one system text line
;	; high, and say, 10 characters wide, minimum.
;	;
;	push	bx
;	push	ds:[LMBH_handle]
;	mov	ds, cx				;*ds:si <- parent
;	mov	cx, size CompSizeHintArgs
;	mov	ax, HINT_MINIMUM_SIZE
;	call	ObjVarAddData
;	mov	ds:[bx].CSHA_width, SpecWidth <SST_AVG_CHAR_WIDTHS, \
;					       MIN_POPUP_CHAR_WIDTH>
;	mov	ds:[bx].CSHA_height, SpecHeight <SST_LINES_OF_TEXT, 1>
;	mov	ds:[bx].CSHA_count, 0
;	pop	bx
;	call	MemDerefDS
;	pop	bx
endif

10$:
	xchg	bp, si				;*cx:bp = parent, *ds:si = group

	segmov	es, cs
	mov	di, offset cs:OLIGHintHandlers
	mov	ax, length (cs:OLIGHintHandlers)
	call	ObjVarScanData
	tst	bx
	jz	20$
	call	MemUnlock
20$:
	ret
OLItemGroupScanPopupHints	endp

OLIGHintHandlers	VarDataHandler \
	<HINT_FIXED_SIZE, offset OLIGCopyHint>,
	<HINT_MINIMUM_SIZE, OLIGCopyHint>,
	<HINT_MAXIMUM_SIZE, OLIGCopyHint>,
	<HINT_INITIAL_SIZE, OLIGCopyHint>,
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, OLIGCopyHint>,
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, OLIGCopyHint>,
	<HINT_GADGET_BACKGROUND_COLORS, OLIGCopyHint>,
	<HINT_WRAP_AFTER_CHILD_COUNT, ItemGroupWrapAfterChildCount>


; copy the current hint to the visual parent
OLIGCopyHint	proc	far
EC <	tst	cx							>
EC <	ERROR_Z	OL_ERROR						>
	push	cx
	mov	es, cx			; *es:bp <- dest
	mov	cx, ax			; cx <- start of range to copy
	mov_tr	dx, ax			; dx <- end of range to copy
	call	ObjVarCopyDataRange
	pop	cx
	ret
OLIGCopyHint	endp


ItemGroupWrapAfterChildCount	proc	far
	call	Build_DerefVisSpecDI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ONE_PASS_OPTIMIZATION
	or	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT or \
				      mask VCGA_ALLOW_CHILDREN_TO_WRAP
	ret
ItemGroupWrapAfterChildCount	endp



COMMENT @----------------------------------------------------------------------

METHOD:		SetupDynamicListItems -- 

DESCRIPTION:	If we're a dynamic list, sends appropriate messages to initiate
		the query mechanism.

CALLED BY:	OLItemGroupSpecBuild

PASS:		*ds:si 	- instance data

RETURN:		nothing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es, ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/31/92		Initial Version

------------------------------------------------------------------------------@

SetupDynamicListItems	proc	far
	;
	; For non-scrollable dynamic lists, we'll go get the gen children
	; that we so desperately need.  Scrollable dynamic lists get their
	; children off of MSG_META_CONTENT_VIEW_SIZE_CHANGED calls.  Also
	; we ignore OLBooleanGroup objects, since they're never dynamic lists.
	;
	call	Build_DerefVisSpecDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exit
	test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE 
	jnz	exit
	mov	cx, -1				;get all the children we need
	mov	dx, FALSE			;initialize new items
	clr	bp				;first one is visible
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
exit:
	ret
SetupDynamicListItems	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupVisOpen -- 
		MSG_VIS_OPEN for OLItemGroupClass

DESCRIPTION:	Handles vis open.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_OPEN

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
	chris	5/12/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupVisOpen	method dynamic	OLItemGroupClass, MSG_VIS_OPEN
	mov	di, offset OLItemGroupClass
	CallSuper	MSG_VIS_OPEN

	;
	;
	; If this is a dynamic list, let's set the proper bounds for the view 
	; as well.  (It won't get set via MSG_VIEW_SIZE_CHANGED unless the
	; thing has been previously visible.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	afterDynamicList
	test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE 
	jz	afterDynamicList

	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	call	ObjCallInstanceNoLock			;num items in cx
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED
	call	ObjCallInstanceNoLock
afterDynamicList:
	call	IsExtendedSelection
	jnc	maybeStoreSelection
	call	Build_DerefVisSpecDI
	clr	ds:[di].OLIGI_displayedItem	;no valid extended selection

if _RUDY
	;
	; If exactly one item selected, initally behave like
	; an exclusive list.
	;
	call	Build_DerefGenDI
	clr	ax
	cmp	ds:[di].GIGI_numSelections, 1
	jne	afterBehavior
	not	ax				; TRUE if 1 selected
afterBehavior:
	call	Build_DerefVisSpecDI
	mov	ds:[di].OLIGI_exclusiveBehavior, ax

	;
	; If the user previously selected one item, then moved the focus,
	; put the focus back on the selection, as a convenience.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; ax = first or GIGS_NONE
	cmp	ax, GIGS_NONE
	je	afterFocus

	mov	bl, mask OLIGS_HAS_FOCUS_ITEM	;assume there is one
	call	SetFocusItem
	push	ax
	call	EnsureCurrentItemVisible	;make item visible
	pop	cx

	mov	bp, cx
	call	GetItemOptr			; ^lcx:dx = item
	jnc	afterFocus			; cx = id
	call	OLItemGroupVupGrabFocusExclForItem
afterFocus:
endif ; _RUDY

if DELAYED_LISTS_DO_RESET
	jmp	maybeSetMoniker
endif
maybeStoreSelection:
if DELAYED_LISTS_DO_RESET
	call	StoreInitialSelectionForResetIfDelayed
 if _RUDY
	;
	; Ensure that the current selection has the focus.
	;
	mov	ax, TRUE
	jmp	afterBehavior
 endif ; _RUDY
maybeSetMoniker:
endif

	call	SetPopupListMonikerIfNeeded
	ret
OLItemGroupVisOpen	endm


if DELAYED_LISTS_DO_RESET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreInitialSelectionForResetIfDelayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If delayed, Squirrel the current selection away
		in case we get RESET later.

CALLED BY:	OLItemGroupVisOpen
PASS:		*ds:si	= OLItemGroup object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Stores original selection in the OLIGI_displayedItem field,
	which is also used by extended-selection lists, so
	this can't currently be used for those.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreInitialSelectionForResetIfDelayed	proc	far
	uses	cx, di
	.enter

	;
	; This method won't work with extended lists
	;
	call	IsExtendedSelection
	jc	exit

	call	Build_DerefGenDI
	mov	cx, ds:[di].GIGI_selection
	call	Build_DerefVisSpecDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	jz	exit
	mov	ds:[di].OLIGI_displayedItem, cx
exit:
	.leave
	ret
StoreInitialSelectionForResetIfDelayed	endp

endif

Build	ends

;------------------------

ItemGeometry segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLItemGroupClass

DESCRIPTION:	Recalc's size.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE

		cx, dx  - size suggestions

RETURN:		cx, dx  - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 1/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupRecalcSize	method dynamic OLItemGroupClass, MSG_VIS_RECALC_SIZE
	
if not _RUDY
    ; For RUDY, we want to be able to specify size hints for the popup
    ; itself (in addition to the trigger) so don't do this. --JimG 8/14/95

	;
	; If we're here and a popup list, we want to ignore desired size hints,
	; since they're meant for the trigger.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	10$
	ORNF	ds:[di].VI_geoAttrs, mask VGA_NO_SIZE_HINTS
10$:
endif ;not _RUDY

	call	ItemGroupPassMarginInfo
	call	OpenRecalcCtrlSize
	ret
OLItemGroupRecalcSize	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupVisPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLItemGroupClass

DESCRIPTION:	Positions the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH
		cx, dx  - position

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
	chris	5/ 1/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupVisPositionBranch	method dynamic	OLItemGroupClass, \
				MSG_VIS_POSITION_BRANCH

	call	ItemGroupPassMarginInfo	
	call	VisCompPosition
	ret
OLItemGroupVisPositionBranch	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	ItemGroupPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLItemGroupRecalcSize, OLItemGroupPositionBranch

PASS:		*ds:si -- trigger bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

ItemGroupPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLItemGroupGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLCtrlGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
ItemGroupPassMarginInfo	endp






COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupGetTypicalChildExtraSize -- 
		MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE for OLItemGroupClass

DESCRIPTION:	Returns typical extra size for a child of this object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE

RETURN:		al	- typical x extra size
		ah	- typical y extra size
		cx, dx, bp - preserved

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/25/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupGetTypicalChildExtraSize	method dynamic	OLItemGroupClass, \
				MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE

	mov	ax, (MO_ITEM_INSET_Y * 2) shl 8 or \
		    (MO_ITEM_INSET_LEFT + MO_ITEM_INSET_RIGHT)
	
	call	OpenCheckIfCGA
	jnc	5$
	clr	ah				;no vertical size in CGA
5$:
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	10$
	mov	ax, (TOOLBOX_INSET_Y * 2) shl 8 or (TOOLBOX_INSET_X * 2)

if (BW_TOOLBOX_INSET_X - TOOLBOX_INSET_X)	;code currently not used
   	CheckHack <((BW_TOOLBOX_INSET_X - TOOLBOX_INSET_X) eq 1)>
	
	call	OpenCheckIfBW
	jnc	10$				;not B/W, branch
	add	ax, (2 shl 8) or 2
endif
10$:
	test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE
	jz	20$
OLS <	mov	ax, (SCROLL_ITEM_INSET_Y*2) shl 8 or (SCROLL_ITEM_INSET_X*2) >
CUAS <	mov	ax, (MO_SCROLL_ITEM_INSET_Y*2) shl 8 or \
		    (MO_SCROLL_ITEM_INSET_X*2) >
20$:
	ret
OLItemGroupGetTypicalChildExtraSize	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupGetSpacing -- MSG_VIS_COMP_GET_CHILD_SPACING for
							OLItemGroupClass

DESCRIPTION:	Returns spacing for the object.
		Note that exclusive items have different spacing than
		nonexclusive items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_COMP_GET_CHILD_SPACING

RETURN:		cx	- spacing between children
		dx	- spacing between lines of wrapped children

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@

OLItemGroupGetSpacing	method	OLItemGroupClass, \
			MSG_VIS_COMP_GET_CHILD_SPACING

	;Assume non-exclusive, set spacing (should be zero).

CUAS <	mov	cx, MO_ITEM_SPACING					>
CUAS <	mov	dx, cx							>

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

if _MOTIF or _PM	;-------------------------------------------------------
	;Most Motif items don't overlap. However, if it's a B&W toolbox,
	;you do want its children to overlap. (OL_BW_TOOLBOX_SPACING).
	;(Check toolbox-style as well.  -cbh 2/26/93)

	mov	ax, HINT_ITEM_GROUP_TOOLBOX_STYLE
	call	ObjVarFindData
	jc	treatAsToolbox

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	defaultSpacingSet		;skip if not toolbox...

treatAsToolbox:
	call	OpenCheckIfBW
	jnc	toolbox				;skip if not B/W
	mov	cx, OL_BW_TOOLBOX_SPACING
	mov	dx, cx
	
endif		;--------------------------------------------------------------
     
if	_OL_STYLE ;---------------------------------------------------------
	mov	cx, OL_NONEXCLUSIVE_SPACING
	mov	dx, cx

	call	IsNonExclusive
	jc	toolbox			;skip if non-exclusive list...

	mov	cx, OL_COLOR_EXCLUSIVE_SPACING 
	mov	dx, cx

	call	OpenCheckIfBW
	jnc	toolbox				;is color item, branch
	mov	cx, OL_BW_EXCLUSIVE_SPACING
	mov	dx, cx
	
endif ;---------------------------------------------------------------------

toolbox:	
	;
	; Non-exclusive toolboxes have a little spacing in them.
	;
	CheckHack <OL_NON_EXCL_TOOLBOX_SPACING eq 0>
;	call	IsNonExclusive
;	jnc	defaultSpacingSet		;skip if exclusive list...
;	mov	cx, OL_NON_EXCL_TOOLBOX_SPACING
;
defaultSpacingSet:
	call	OpenCtrlCheckCustomSpacing	;use custom spacing if there.

	;Let's see if we're running CGA.  If so, we won't space children 
	;too much.  (Added code for narrow screens 12/ 2/92 cbh)

	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf	
	jz	10$				;horizontal, branch
	xchg	cx, dx
10$:
	call	OpenCheckIfCGA			;running CGA?
	jnc	20$				;no, branch

	cmp	dx, MINIMAL_Y_SPACING
	jle	done				;(spacing might be negative)
	mov	dx, MINIMAL_Y_SPACING		;use minimal wrap spacing
	jmp	short 20$

20$:
	call	OpenCheckIfNarrow
	jnc	done
	cmp	cx, MINIMAL_X_SPACING
	jle	done
	mov	cx, MINIMAL_X_SPACING		;use minimal child spacing
done:
	popf
	jz	exit
	xchg	cx, dx
exit:
	ret
OLItemGroupGetSpacing	endp



ItemGeometry ends

;--------------------------------

GeometryObscure	segment resource	




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupResetSizeToStayOnscreen -- 
		MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN for OLItemGroupClass

DESCRIPTION:	Resets size of everything to stay onscreen.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/10/93         Initial Version

------------------------------------------------------------------------------@

OLItemGroupResetSizeToStayOnscreen	method dynamic	OLItemGroupClass, \
				MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

	;
	; If we're a popup list, try wrapping to make life easier.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	callSuper
	or	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP

callSuper:
	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock

OLItemGroupResetSizeToStayOnscreen	endm


GeometryObscure	ends


;--------------------


ExtendedCommon	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcNewExtent

SYNOPSIS:	Figures out the current extent item.

CALLED BY:	OLItemGroupExtendSelection

PASS:		*ds:si -- item group
		cx, dx -- mouse position defining the extent

RETURN:		cx -- new extent item

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/10/92		Initial version

------------------------------------------------------------------------------@

CalcNewExtent	proc	near
	class	OLScrollListClass
	extentRect		local	Rectangle
	foundItemInExtent	local	word
	.enter
	;
	; Get the position of the anchor item.	
	;
	push	cx, dx, bp			;save 
	call	EC_DerefVisDI
	mov	cx, ds:[di].OLIGI_anchorItem	;get anchor item pos
	call	GetOptr				;^lcx:dx <- optr
	jc	5$				;found object, branch

	call	EC_DerefVisDI
EC <	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC			>
EC <	ERROR_Z		OL_ERROR					>

	;
	; A hack to guess which direction the anchor might have been.  If I
	; were nice, I'd send a message to find out.
	;
	clr	cx				;assume above, use 0, 0
	mov	dx, cx
	mov	ax, ds:[di].OLIGI_anchorItem
	cmp	ax, ds:[di].OLSLI_topItem
	jb	8$
	mov	cx, 8000			;else, somewhere below the 
	mov	dx, cx				;  visible items.  8000, 8000
						;  ought to do it.
	jmp	short 8$
5$:
	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_GET_POSITION
	call	EC_ObjMessageCall		;cx, dx position of anchor
	pop	si
8$:
	pop	ax, bx, bp			;ax, bx is extent bounds
	;
	; Rearrange to make a reasonable rect.
	;	
	cmp	ax, cx
	jle	10$
	xchg	ax, cx
10$:
	cmp	bx, dx
	jle 	20$
	xchg	bx, dx
20$:
	mov	extentRect.R_left, ax		
	mov	extentRect.R_top, bx
	mov	extentRect.R_right, cx
	mov	extentRect.R_bottom, dx

	;	
	; Go through the children, finding who is in the extent rect.
	;	ax -- current child position
	;	cx -- first child in extent rect (-1 if not yet found)
	;	dx -- last child in extent rect (-1 if not yet found)
	;
	clr	ax				;no item found in extent yet
	mov	bx, offset CheckChildInExtent
	call	OLResidentProcessVisChildren	

	call	EC_DerefVisDI
	tst	ax				;anything found?
	jnz	foundItemsInExtent
	mov	cx, ds:[di].OLIGI_anchorItem	;no, return anchor
	jmp	short exit

foundItemsInExtent:
	;
	; cx is first child in extent rect, dx is last child in extend rect.
	; One of these is the anchorItem.  The other is our new extentItem.
	;
	cmp	cx, ds:[di].OLIGI_anchorItem
	je	returnDx			;anchor item, return other guy

	cmp	dx, ds:[di].OLIGI_anchorItem	;it matches, doesn't it?
	je	exit				;yes, exit

	;
	; Neither matches, must be dynamic list (we hope).  Guess that 
	; identifiers are in numerical order and do the right thing.
	;
	jb	exit				;if dx less than anchor item,
						;  cx should be extent
returnDx:
	mov	cx, dx				;else return last item 
exit:
	.leave
	ret
CalcNewExtent	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupToggleAddMode -- 
		MSG_OL_IGROUP_TOGGLE_ADD_MODE for OLItemGroupClass

DESCRIPTION:	Toggles add mode in the item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_TOGGLE_ADD_MODE

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
	chris	9/10/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupToggleAddMode	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_TOGGLE_ADD_MODE

	xor	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
	ret
OLItemGroupToggleAddMode	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupDeselectAll -- 
		MSG_OL_IGROUP_DESELECT_ALL for OLItemGroupClass

DESCRIPTION:	Deselects all items in the item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_DESELECT_ALL

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
	chris	9/10/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupDeselectAll	method dynamic	OLItemGroupClass,
				MSG_OL_IGROUP_DESELECT_ALL

	call	EC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	deselect			;non-excl, deselect

	;
	; Else is OLItemGroupClass (GenItemGroupClass).  Check for exclusive
	; behavior.
	;
	call	EC_DerefGenDI
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXCLUSIVE
	je	exit				;exclusive, can't deselect

deselect:
if _RUDY
	; In Rudy, we deselect everything but the focus item, which
	; becomes the only thing selected, moving the list back
	; into exclusive mode.
	;
	mov	cx, (1 shl 8)
	call	GetFocusItemFar			; dx = focus item
	jc	setIt
	call	InitFocusItem			; no? try again.
	call	GetFocusItemFar			; dx = focus item
	jc	exit
	clr	cx				; no focus, no selection
setIt:
	xchg	cx, dx

else ; not _RUDY

	clr	dx				;no flags, no selection

endif
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	call	EC_ObjCallInstanceNoLock
exit:	
	ret

OLItemGroupDeselectAll	endm

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects all items

CALLED BY:	MSG_OL_IGROUP_SELECT_ALL
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	10/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupSelectAll	method dynamic OLItemGroupClass, 
					MSG_OL_IGROUP_SELECT_ALL
	.enter

	call	EC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	select			;non-excl, select

	;
	; Else is OLItemGroupClass (GenItemGroupClass).  Check for exclusive
	; behavior.
	;
	call	EC_DerefGenDI
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXCLUSIVE
	je	exit				;exclusive, can't select
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXCLUSIVE_NONE
	je	exit				;exclusive, can't select

select:
	;
	; Go make the adjustments to the selection, based on the new extent
	; item.
	;
	mov	dx, size GenItemGroupUpdateExtSelParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GIGUESP_setSelMsg, MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE
	;
	; Get first item in list
	;
	push	bp
	clr	bp
	mov	cl, mask GSIF_FROM_START or mask GSIF_FORWARD
	call	ScanItems
	pop	bp
	mov	ss:[bp].GIGUESP_anchorItem, ax
	mov	ax, ds:[di].OLIGI_extentItem
	mov	ss:[bp].GIGUESP_prevExtentItem, ax

	;
	; Get last item in list
	;
	push	bp
	mov	cl, mask GSIF_FROM_START
	clr	bp
	call	ScanItems
	pop	bp
	mov	ss:[bp].GIGUESP_extentItem, ax

	;
	; Have everything inbetween selected
	; Use TEMPORARY_CHANGE flag to prevent N status/apply messages
	; from being sent.
	;
	mov	ss:[bp].GIGUESP_flags, mask ESF_SELECT or mask ESF_INITIAL_SELECTION
	mov	ss:[bp].GIGUESP_passFlags, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE \
		or mask OLIUF_TEMPORARY_CHANGE

	mov	dx, size GenItemGroupUpdateExtSelParams
	mov	ax, MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, size GenItemGroupUpdateExtSelParams

	;
	; We should have a focus item.
	;
	call	GetFocusItemFar			; dx = focus item
	jc	setIt
	call	InitFocusItem			; no? try again.
	call	GetFocusItemFar			; dx = focus item
	jnc	afterFocus
setIt:
	push	dx
	mov	ax, dx
	call	EnsureCurrentItemVisible	;make item visible
	pop	cx

	call	GetItemOptr			; ^lcx:dx = item
	jnc	afterFocus			; cx = id
	call	OLItemGroupVupGrabFocusExclForItem
afterFocus:

	;
	; Now we're done, send out one status/apply
	;
	clr	ax				;send no message
	clr	bl				;no special flags
	call	CallSelfWithUpdateFlagsAndSetModified

exit:
	.leave
	ret
OLItemGroupSelectAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupToggleAllSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggles between all things selected, and none selected

CALLED BY:	MSG_OL_IGROUP_TOGGLE_ALL_SELECTED
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	What we'll actually do is to deselect all if _all_ are already
	selected, otherwise, select all

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	11/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupToggleAllSelected	method dynamic OLItemGroupClass, 
					MSG_OL_IGROUP_TOGGLE_ALL_SELECTED

	call	GetNumItems			; cx = Num items

	call	EC_DerefGenDI
	mov	ax, MSG_OL_IGROUP_SELECT_ALL

	cmp	ds:[di].GIGI_numSelections, cx
	jne	doIt

	mov	ax, MSG_OL_IGROUP_DESELECT_ALL
doIt:
	GOTO	ObjCallInstanceNoLock

OLItemGroupToggleAllSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the total number of items in an item group.

CALLED BY:	OLItemGroupToggleAllSelected
PASS:		*ds:si	= OLItemGroupClass
RETURN:		cx	= number of items
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

		May move object blocks

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	11/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumItems	proc	near
	uses	ax,bx,dx,si,di,bp
	.enter

	;
	; If it's a dynamic list, just look at GDLI_numItems.
	; Otherwise, count children
	;
	call	EC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	countChildren
	call	EC_DerefGenDI
	mov	cx, ds:[di].GDLI_numItems
	jmp	exit

countChildren:
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	EC_ObjCallInstanceNoLock
	mov	cx, dx
	
exit:
	.leave
	ret
GetNumItems	endp

endif ; _RUDY

EC_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
EC_DerefVisDI	endp

EC_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
EC_DerefGenDI	endp

EC_ObjMessageCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cx, dx position of anchor
	ret
EC_ObjMessageCall	endp

EC_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
EC_ObjCallInstanceNoLock	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupStartExtendedSelection -- 
		MSG_OL_IGROUP_START_EXTENDED_SELECTION for OLItemGroupClass

DESCRIPTION:	Starts extended selection.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_START_EXTENDED_SELECTION
		cx	- item
		bp high - UIFunctionsActive

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
	chris	9/24/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupStartExtendedSelection	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_START_EXTENDED_SELECTION

	;
	; We need to save the current selection as the last one, so we can
	; check for redunancies later.  (Moved from end of END_EXTENDED_-
	; SELECTION so things will work if the item group is set externally
	; between extended selections.  -cbh 12/ 1/92)
	;
	push	cx, bp
	call	SaveCurrentSelection
	pop	cx, bp

	call	EC_DerefVisDI
	ORNF	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION

	;
	; Not extending from the old branch, we'll set the anchor.  
	;
	test	bp, (mask UIFA_PREF_B) shl 8
	jnz	checkXor
	call	SetAnchorItem

checkXor:
	;
	; Set xor mode if applicable.
	;
	call	EC_DerefVisDI
	call	IsNonExclusive
	jnc	checkMouse

	;
	; Non-exclusive: always xoring, always extending.  -cbh 2/16/93
	; (No longer needed; will check CheckIfInAddMode rather than check
	;  this flag, which will return true for non-exclusive.  -cbh 4/20/93)
	;
;	or	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
	jmp	toggleAnchorItem

checkMouse:
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_XORING_SELECTION
	test	bp, (mask UIFA_PREF_A) shl 8
	jz	notXor

	or	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
	
	;
	; If both xoring and not extending from the old branch. then we'll
	; want to toggle the current anchor item and use that state in our
	; extended selection
	;
	test	bp, (mask UIFA_PREF_B) shl 8
	jnz	exit

toggleAnchorItem:
	call	SetToToggleAnchorItem
	jmp	short exit
notXor:
	;
	; Not xoring, let's clear everything for the moment, accept for our
	; anchor item, which of course will be always be selected.  Also,
	; set things so we'll be turning things on.
	;
	or	ds:[di].OLIGI_moreState, mask OLIGMS_SELECTING_ITEMS

;	Commented out -- the update-extended-selection stuff should take care
;	of this.
;	mov	cx, ds:[di].OLIGI_anchorItem
;	clr	dx			;OK to nuke indeterminate status...
;	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
;	call	EC_ObjCallInstanceNoLock
exit:
	ret
OLItemGroupStartExtendedSelection	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupExtendSelection -- 
		MSG_OL_IGROUP_EXTEND_SELECTION for OLItemGroupClass

DESCRIPTION:	Extends selection appropriately, from a mouse operation.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_EXTEND_SELECTION

		cx, dx	- position of new extent
		bp      - non-zero if initial selection

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
	chris	9/24/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupExtendSelection	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_EXTEND_SELECTION
	push	bp
	call	CalcNewExtent			;calc new extent item
	mov	ax, cx				;pass in cx
	pop	bp				;restore initial sel flag

	call	EC_DerefVisDI

	tst	bp				;initial selection, always
	jnz	10$				;  extend

	cmp	ax, ds:[di].OLIGI_extentItem	;didn't change, exit
	je	exit
10$:
	;
	; Extend the selection.
	;
	mov	cx, mask OLIUF_TEMPORARY_CHANGE
	call	ExtendSelection			;extend the selection

	;
	; Get the focus on the extent item here.
	;
	call	EC_DerefVisDI
	mov	ax, ds:[di].OLIGI_extentItem
	call	GetOptrOrSelf		;return optr to use
	pushdw	cxdx
	call	OLItemGroupMoveFocusExclToItem
	popdw	cxdx
	
	;
	; If the focus is now on the extent item, have it grab the mouse so
	; it can receive the mouse events from now on.  Otherwise, it will 
	; only get the mouse events if the pointer is over the item, which
	; it isn't, necessarily.
	;
	cmp	cx, ds:[LMBH_handle]
	jne	20$
	cmp	dx, si
	je	exit
20$:
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_GRAB_MOUSE
	call	EC_ObjMessageCall
exit:
	ret
OLItemGroupExtendSelection	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupEndExtendedSelection -- 
		MSG_OL_IGROUP_END_EXTENDED_SELECTION for OLItemGroupClass

DESCRIPTION:	Ends extended selection.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_END_EXTENDED_SELECTION
		bp high	- UIFunctionsActive

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
	chris	9/24/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupEndExtendedSelection	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_END_EXTENDED_SELECTION

	push	bp
	ANDNF	 ds:[di].OLIGI_moreState, not (mask OLIGMS_XORING_SELECTION or \
					       mask OLIGMS_EXTENDING_SELECTION)

	;
	; Force the item group to be modified and send its apply message, but
	; only if the extent differs from the anchor.  (Otherwise, nothing
	; has changed since we started this business.)  (New code added 12/ 1/92
	; cbh to do this right.   Previously we just checked the anchorItem
	; against the extentItem, which couldn't possibly work.)
	;
	mov	bp, si				;get selection from instance 
						;  data
	mov	ax, MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION
	call	ObjCallInstanceNoLock
	jnc	apply				;selection not redundant, branch

	mov	ax, ATTR_GEN_ITEM_GROUP_SET_MODIFIED_ON_REDUNDANT_SELECTION
	call	ObjVarFindData			;carry set if found
	jnc	savePrevSel			;not found, move on.
apply:
	clr	ax				;send no message
	clr	bl				;no special flags
	call	CallSelfWithUpdateFlagsAndSetModified

savePrevSel:
	pop	bp

	; Previous selection no longer valid.  -cbh 12/ 1/92

	call	EC_DerefVisDI
	ANDNF	ds:[di].OLIGI_moreState, not mask OLIGMS_PREV_SELECTION_VALID

	;
	; If a shift key is still down as we release, we want to restore
	; this flag to the correct state so navigation will continue to
	; work.  (Shift-press cannot be distinguished from a plain press
	; in this world).
	;
	test	bp, (mask UIFA_PREF_B) shl 8
	jz	exit

	call	EC_DerefVisDI
	ORNF	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
exit:
	ret
OLItemGroupEndExtendedSelection	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	ExtendSelection

SYNOPSIS:	Extends the selection.

CALLED BY:	OLItemGroupSetUserCommon

PASS:		*ds:si -- item group
		ax -- curItem
		cl -- OLItemUpdateFlags to pass

RETURN:		nothing

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/22/92		Initial version

------------------------------------------------------------------------------@

ExtendSelectionSettingItems	proc	far
	call	EC_DerefVisDI
	or	ds:[di].OLIGI_moreState, mask OLIGMS_SELECTING_ITEMS
	FALL_THRU	ExtendSelection
ExtendSelectionSettingItems	endp


ExtendSelection	proc	far	uses	ax, cx, dx
	.enter
	call	EC_DerefVisDI
	;
	; See if old selection is still valid.  If not, we'll be initializing
	; the selection.
	;
	tst	ds:[di].OLIGI_displayedItem
	jnz	5$
	ORNF	ch, mask ESF_INITIAL_SELECTION
5$:
	test	ds:[di].OLIGI_moreState, mask OLIGMS_SELECTING_ITEMS
	jz	20$				;flag used for whither select
	ORNF	ch, mask ESF_SELECT
20$:
	;
	; Code to clear anything not in the selection, if we're not xoring.
	;
	call	CheckIfInAddMode	;changed from just XORING_SELECTION
	jc	30$			;   4/20/93 cbh
	ORNF	ch, mask ESF_CLEAR_UNSELECTED_ITEMS
30$:
	;
	; Go make the adjustments to the selection, based on the new extent
	; item.
	;
	push	cx
	mov	dx, size GenItemGroupUpdateExtSelParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GIGUESP_setSelMsg, MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE
	mov	ss:[bp].GIGUESP_extentItem, ax
	mov	ax, ds:[di].OLIGI_anchorItem
	mov	ss:[bp].GIGUESP_anchorItem, ax
	mov	ax, ds:[di].OLIGI_extentItem
	mov	ss:[bp].GIGUESP_prevExtentItem, ax
	mov	ss:[bp].GIGUESP_flags, ch
	mov	ss:[bp].GIGUESP_passFlags, cl
	mov	ax, MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, size GenItemGroupUpdateExtSelParams
	pop	cx

	;
	; Mark our selection as valid (displayedItem non-zero) as long as we
	; were selecting items.  If we weren't selection, then we were toggling
	; some stuff off, and most likely an entire selection will have to be
	; redrawn next time.
	;
	call	EC_DerefVisDI
	test	ch, mask ESF_SELECT
	jz	40$
	mov	ds:[di].OLIGI_displayedItem, si
40$:
	.leave
	;
	; Store new extent item.
	;
	mov	ds:[di].OLIGI_extentItem, ax
	ret
ExtendSelection	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetToToggleAnchorItem

SYNOPSIS:	Gets anchor item state, and prepares any subsequent extended
		selections to toggle the state.

CALLED BY:	utility

PASS:		*ds:si -- item group
		cx -- anchor item

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 6/92		Initial version

------------------------------------------------------------------------------@

SetToToggleAnchorItem	proc	far		uses	ax, cx, dx, bp
	.enter
	call	EC_DerefVisDI
	mov	cx, ds:[di].OLIGI_anchorItem
	call	OLItemGroupGetItemState		;return state for item
	
	call	EC_DerefVisDI			;assume we'll turn things on
	or	ds:[di].OLIGI_moreState, mask OLIGMS_SELECTING_ITEMS

	test	al, mask OLIS_INDETERMINATE	;indeterminate, branch
	jnz	exit
	test	al, mask OLIS_SELECTED		;not selected, branch
	jz	exit
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_SELECTING_ITEMS
	
exit:
	.leave
	ret
SetToToggleAnchorItem	endp

ExtendedCommon	ends

Resident segment resource




COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfInAddMode

SYNOPSIS:	Checks to see if we're in add mode.

CALLED BY:	utility

PASS:		*ds:si -- item group

RETURN:		carry set if in add mode

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/93       	Initial version

------------------------------------------------------------------------------@

CheckIfInAddMode	proc	far		uses	di
	.enter
	call	IsNonExclusive			;non exclusive, always add mode
	jc	exit
	call	Res_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
	jz	exit				;not xoring, branch
	stc					;else in add mode
exit:
	.leave
	ret
CheckIfInAddMode	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckChildInExtent

SYNOPSIS:	Checks if child is in extent rectangle passed.

CALLED BY:	CalcNewExtent (via OLResidentProcessVisChildren)

PASS:		*ds:si -- item group
		ax     -- whether child found in extent
		cx     -- position of first child in extent rect
		dx     -- position of last child in extent rect
		ss:bp  -- local vars

RETURN:		ax, cx, dx -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/10/92		Initial version

------------------------------------------------------------------------------@

CheckChildInExtent	proc	far
	;	
	; Determine whether the child is in the extent rect:
	;
	; (isBetween(bounds.left, selRect.left, selRect.right) or
	;  isBetween(bounds.right,selRect.left, selRect.right) or
	;  isBetween(selRect.left,bounds.left,  bounds.right)) AND
	; (isBetween(bounds.top,   selRect.top, selRect.bottom) or
	;  isBetween(bounds.bottom,selRect.top, selRect.bottom)
	;  isBetween(selRect.top,  bounds.top,  bounds.bottom)))
	;
	.enter inherit CalcNewExtent

	call	GenCheckIfFullyEnabled		;not enabled, can't be an
	jnc	exit				;  extent.

	push	ax, cx, dx
	call	Res_DerefVisDI
	mov	cx, extentRect.R_left		
	mov	dx, extentRect.R_right

	mov	ax, ds:[di].VI_bounds.R_right	
	dec	ax				;use screen pixel coords
	call	IsBetween
	jc	inRectHorizontally		;right edge in rect, branch

	mov	ax, ds:[di].VI_bounds.R_left
	call	IsBetween
	jc	inRectHorizontally		;left edge in rect, branch

	xchg	ax, cx				;last check: selRect left within
	mov	dx, ds:[di].VI_bounds.R_right	;  object's left and right
	jnc	carrySetIfInRect		;not horizontally in rect, done

inRectHorizontally:
	mov	cx, extentRect.R_top
	mov	dx, extentRect.R_bottom

	mov	ax, ds:[di].VI_bounds.R_bottom
	dec	ax				;use screen pixel coords
	call	IsBetween			
	jc	carrySetIfInRect		;bottom edge in rect, done

	mov	ax, ds:[di].VI_bounds.R_top
	call	IsBetween
	jc	carrySetIfInRect		;top edge in rect, done

	xchg	ax, cx				;last check: selRect top within
	mov	dx, ds:[di].VI_bounds.R_top	;  object's top and bottom

carrySetIfInRect:
	pop	ax, cx, dx
	jnc	exit				;not in rect, make our egress

	;
	; If in the rect, we'll set ourselves as the first child if none have
	; been along yet, as the last child in any case.
	;
	call	Res_DerefGenDI
	mov	di, ds:[di].GII_identifier
	
	tst	ax				;found a child yet?
	jnz	10$				;yes, branch
	dec	ax
	mov	cx, di				;set as first item in extent
10$:
	mov	dx, di				;set as last item in extent
exit:
	clc					;continue
	.leave
	ret

CheckChildInExtent	endp


IsBetween	proc	near
	;
	; Returns carry set if ax between cx and dx.
	;
	cmp	ax, cx
	clc					;assume failure
	jl	exit				;before cx, failed.
	cmp	ax, dx
	clc
	jg	exit				;after dx, failed
	stc					;else OK
exit:
	inc	ax				;bump child count
	ret
IsBetween	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	IsNonExclusive

SYNOPSIS:	Checks to see if we're a non-exclusive behaving group.
		Works for OLItemGroups and OLBooleanGroups.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		carry set if non-exclusive

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

IsNonExclusive	proc	far		uses es, di
	.enter
	call	Res_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	nonExcl				;yes, definitely non-excl

	;
	; Else is OLItemGroupClass (GenItemGroupClass).  Check for non-excl
	; behavior.
	;
	call	Res_DerefGenDI
	cmp	ds:[di].GIGI_behaviorType, GIGBT_NON_EXCLUSIVE
	clc					;no match, exit
	jne	exit
nonExcl:
	stc					;is non exclusive
exit:
	.leave
	ret
IsNonExclusive	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	IsExtendedSelection

SYNOPSIS:	Checks to see if we're an extended-selection behaving group.
		Works for OLItemGroups and OLBooleanGroups.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		carry set if extended selection

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version
	Chris	2/16/93		Changed to include item group non-exclusives

------------------------------------------------------------------------------@

IsExtendedSelection	proc	far		uses es, di
	.enter
	call	Res_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	exit				;yes, definitely not (c=0)

	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jnz	exit				;in menu, not extending (c=0)

	;
	; Else is OLItemGroupClass (GenItemGroupClass).  Check for ext-sel
	; behavior.
	;
	call	Res_DerefGenDI
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXTENDED_SELECTION
	stc					;a match, exit
	je	exit
	cmp	ds:[di].GIGI_behaviorType, GIGBT_NON_EXCLUSIVE
	clc
	jne	exit				;no match, exit (c=0)
	stc					;is extended selection
exit:
	.leave
	ret
IsExtendedSelection	endp

	




COMMENT @----------------------------------------------------------------------

ROUTINE:	GetFocusOptr

SYNOPSIS:	Returns optr of focus item, or null if no focus item, of
		the list itself if there is a focus item, but it doesn't
		currently exist under the list.

CALLED BY:	utility

PASS:		*ds:si -- item group

RETURN:		^lcx:dx -- focus item (or null if none)
		carry set if there's a focus item

DESTROYED:	ax, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

GetFocusItemOptr	proc	far
	call	Res_DerefVisDI
	clr	cx
	mov	dx, cx				;assume no item
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	exit				;no focus item, exit, carry clr

	mov	cx, ds:[di].OLIGI_focusItem
	call	GetOptr
	jc	exit				;found the item, exit

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc
exit:
	ret
GetFocusItemOptr	endp


GetOptr		proc	far		;pass: cx - item
					;return: carry, ^lcx:dx - item
					;  		bp -- identifier
	mov	bp, cx			;keep identifier in bp
	clr	cx			;start with null OD in ^lcx:dx
	mov	dx, cx	
	mov	bx, offset FindChildIdentifier
	clr	di				;do all children
	call	OLResidentProcessGenChildrenFromDI
	ret
GetOptr		endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetFocusFromOptr

SYNOPSIS:	Sets the focus, given an optr.

CALLED BY:	utility

PASS:		*ds:si -- scroll list
		^lcx:dx -- optr of item to set 

RETURN:		nothing

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

SetFocusFromOptr	proc	far
	call	GetIdentifierFromCxDx		;ax <- identifier, if any
						;bl <- OLIGS_HAS_FOCUS_ITEM flag
	FALL_THRU	SetFocusItem

SetFocusFromOptr	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	SetFocusItem

SYNOPSIS:	Sets the focus item.

CALLED BY:	utility

PASS:		*ds:si -- item group
		bl -- OLIGS_HAS_FOCUS_ITEM, if any
		ax -- item to set

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

	RUDY:
	 We always want to start an extended selection from wherever
	 the cursor is, so reset the anchor every time the focus
	 changes, unless we're already extending a selection.
	 NOTE: if we also provide a way to select a range
	  by setting the initial and final items, then this will
	  interfere with that, as the anchor (initial item)
          will have changed in the process of moving to the final
	  item
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

SetFocusItem	proc	far
	call	Res_DerefVisDI

if _RUDY	; If this is a list that doesn't get the focus,
		; then the items don't ever get gained/lost focus
		; notifications, so won't update their state
		; (namely, OLBSS_CURSORED) and redraw. So we
		; emulate it here when the focus item changes.

	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	afterLoss		; no previous item had focus -> skip
	test	bl, mask OLIGS_HAS_FOCUS_ITEM
	jz	loseIt			; not setting a new item -> lose
	cmp	ds:[di].OLIGI_focusItem, ax
	je	afterLoss		; not changing item -> skip
loseIt:
	mov_tr	di, ax
	mov	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	call	SendMessageToFocusItemIfShowSelectionHint
	mov_tr	ax, di
	call	Res_DerefVisDI
afterLoss:
endif ; _RUDY

	and	ds:[di].OLIGI_state, not mask OLIGS_HAS_FOCUS_ITEM
if _JEDIMOTIF
	;
	; skip marking focus flag if GIGS_NONE
	;
	cmp	ax, GIGS_NONE
	je	noFocus
endif
	or	ds:[di].OLIGI_state, bl		;set has-focus flag

noFocus::
	mov	ds:[di].OLIGI_focusItem, ax	;set focus
if _RUDY
	;
	; Move the anchor with the focus.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
	jnz	dontResetAnchor
	xchg	cx, ax
	call	SetAnchorItem
	xchg	cx, ax
dontResetAnchor:
endif ; _RUDY

	ret
SetFocusItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToFocusItemIfShowSelectionHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message(no args) to the focusItem
		if HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS
		is present.

CALLED BY:	SetFocusItem
PASS:		*ds:si	= OLItemGroupInstance
		ax	= message to send
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	This routine may move the LMem heap

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	11/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RUDY
SendMessageToFocusItemIfShowSelectionHint	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

	push	ax				; save message for later
	call	Res_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	done

	mov	ax, HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS
	call	ObjVarFindData			; nukes bx
	jnc	done

	call	GetFocusItemOptr		; ^lcx:dx = item or list
	jnc	done
	cmp	cx, ds:[LMBH_handle]
	jne	send
	cmp	dx, si
	je	done
send:
	pop	ax				; ax <- message
	push	si
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	reallyDone
done:
	pop	ax				; pop stored message
reallyDone:
	.leave
	ret
SendMessageToFocusItemIfShowSelectionHint	endp
endif ; _RUDY


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetIdentifierFromCxDx

SYNOPSIS:	Returns identifier of object.

CALLED BY:	SetFocusFromOptr, IsFocusItemOptr

PASS:		*ds:si -- item group
		^lcx:dx -- item to check

RETURN:		bl -- OLIGS_HAS_FOCUS_ITEM, if cx:dx passed was non-null, with:
			ax -- identifier
		
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@


GetIdentifierFromCxDx	proc	near		uses	cx, dx, bp
	.enter
	clr	bx				;assume no item passed
	tst	cx				;is an item passed?
	jz	exit				;nope, done

	cmp	cx, ds:[LMBH_handle]		;passed ourselves?
	jne	10$
	cmp	dx, si
	je	exit				;yes, exit with no item
10$:
	push	si				;save scroll list
	movdw	bxsi, cxdx
EC <	push	cx, dx							     >
EC <	call	ECCheckLMemOD			;can't be anything           >
EC <	mov	cx, segment OLItemClass					     >
EC <	mov	dx, offset OLItemClass					     >
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				     >
EC <	mov	di, mask MF_CALL or mask MF_FIXUP_DS			     >
EC <	call	ObjMessage						     >
EC <	ERROR_NC	OL_ERROR		;must be OLItem		     >
EC <	pop	cx, dx							     >

	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;returns selection in ax
	pop	si				;restore scroll list
	mov	bl, mask OLIGS_HAS_FOCUS_ITEM	;else looking for an item
exit:
	.leave
	ret
GetIdentifierFromCxDx	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	IsFocusItemOptr

SYNOPSIS:	Returns whether focus item is the optr.

CALLED BY:	utility	

PASS:		*ds:si -- item group
		^lcx:dx -- object to see if focus

RETURN:		zero flag set if object is the focus

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

IsFocusItemOptr	proc	far
	call	GetIdentifierFromCxDx		;bl <- OLIGS_HAS_FOCUS_ITEM flag
	FALL_THRU	IsFocusItem
IsFocusItemOptr	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	IsFocusItem

SYNOPSIS:	Returns item passed has the focus

CALLED BY:	utility	

PASS:		*ds:si -- item group
		bl -- OLIGS_HAS_FOCUS_ITEM set if an item passed, clear if
			checking for no focus
		ax -- item to check, if bl set  

RETURN:		zero flag set if object is the focus

DESTROYED:	bh, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

IsFocusItem	proc	far
	call	Res_DerefVisDI
	mov	bh, ds:[di].OLIGI_state		;get current state
	and	bh, mask OLIGS_HAS_FOCUS_ITEM
	cmp	bh, bl				;make sure both set or clear
	jne	exit				;nope, return zero flag clear
	cmp	ds:[di].OLIGI_focusItem, ax	;see if focus item
exit:
	ret
IsFocusItem	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	FindChildIdentifier

DESCRIPTION:	Callback routine to find child with given identifier

CALLED BY:	GLOBAL

PASS:
	*ds:si - child
	*es:di - composite
	cx:dx  - should be null coming in 
	bp - identifier to search for

RETURN:
	cx:dx - optr if found, still zero if not

DESTROYED:
	bx, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

FindChildIdentifier	proc	far
	class	GenBooleanClass
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	cmp	bp, ds:[bx].GBI_identifier
	clc
	jne	exit			;skip if does not match...

;found:	;return carry set, indicating that we found the item
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc
exit:
	ret
FindChildIdentifier	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	ECEnsureNotBooleanGruop

SYNOPSIS:	Ensures that this is not a boolean group object.

CALLED BY:	EC utility

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 6/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECEnsureNotBooleanGroup	proc	far		uses	es, di
	.enter
	mov	di, segment GenBooleanClass
	mov	es, di
	mov	di, offset GenBooleanClass
	call	ObjIsObjectInClass
	ERROR_C	OL_ERROR			;can't be boolean group
	.leave
	ret
ECEnsureNotBooleanGroup	endp

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	RemoveDynamicListItems

SYNOPSIS:	Removes dynamic list items during unbuild.

CALLED BY:	OLItemGroupSpecUnbuild, OLScrollListSpecUnbuild

PASS:		*ds:si -- list

RETURN:		nothing

DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/12/92		Initial version

------------------------------------------------------------------------------@

RemoveDynamicListItems	proc	far
	call	Res_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC			
	jz	exit					;not dynamic, exit
	;
	; Nuke all items.
	;
	clr	cx					;get rid of all items
							;bp doesn't matter
	push	ax
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
	call	Res_ObjCallInstanceNoLock
	pop	ax
exit:
	ret
RemoveDynamicListItems	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetAnchorItem

SYNOPSIS:	Sets an anchor item.  Invalidates the extended selection.

CALLED BY:	utility

PASS:		*ds:si -- item group
		cx -- new anchor item

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 7/92		Initial version

------------------------------------------------------------------------------@

SetAnchorItem	proc	far
	call	Res_DerefVisDI
	mov	ds:[di].OLIGI_anchorItem, cx

if _RUDY or SELECTION_BOX
	;
	; This dorks up popup lists, if done indiscriminately.
	;
	call	IsExtendedSelection
	jnc	exit
endif
	clr	ds:[di].OLIGI_displayedItem	;selection no longer valid
if _RUDY or SELECTION_BOX
exit:
endif
	ret
SetAnchorItem	endp



Resident ends

MenuSepQuery	segment resource

 
COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupSpecMenuSepQuery -- MSG_SPEC_MENU_SEP_QUERY handler

DESCRIPTION:	This method travels the visible tree within a menu,
		 to determine which OLMenuItemGroups need top and bottom
		 separators to be drawn.

PASS:		*ds:si	= instance data for object
		 ch	= MenuSepFlags

RETURN:		ch	= MenuSepFlags (updated)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	 Name	Date		Description
	 ----	----		-----------
	 Eric	3/90		initial version
	 Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupSpecMenuSepQuery	method	dynamic OLItemGroupClass, \
						 MSG_SPEC_MENU_SEP_QUERY

	 ;see if this OLItemGroupClass object is GS_USABLE

	 add	bx, ds:[bx].Gen_offset
	 test	ds:[bx].GI_states, mask GS_USABLE
	 jz	notUsable		;skip if not...

isUsable: ;indicate that a separator should be drawn next, and that there
	   ;is at least one usable object within this composite level.

	 ORNF	ch, mask MSF_SEP or mask MSF_USABLE
	 call	ForwardMenuSepQueryToNextSiblingOrParent

	 ;now we are travelling back up the menu: indicate that a separator
	 ;should be drawn above this object.

	 ORNF	ch, mask MSF_SEP
	 stc
	 ret

notUsable:
	 ;this object is not usable: pass the SEP and USABLE flags as is,
	 ;and return them as is.

	 call	ForwardMenuSepQueryToNextSiblingOrParent
	 ret
OLItemGroupSpecMenuSepQuery endm




MenuSepQuery	ends


if _JEDIMOTIF or _RUDY

ItemCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupGrabFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if popup list, pass request to popup

CALLED BY:	MSG_META_GRAB_FOCUS_EXCL
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupGrabFocusExcl	method dynamic OLItemGroupClass, 
					MSG_META_GRAB_FOCUS_EXCL

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	callSuper
	mov	di, si				; *ds:di = OLItemGroup
	call	VisSwapLockParent		; *ds:si = OLPopupWin
	jnc	done				; no parent, eat it
	call	IC_DerefVisDI
	mov	si, ds:[di].OLPWI_button	; *ds:si = menu button
	tst	si
	jz	doneUnlock			; no button, eat it
	call	ObjCallInstanceNoLock
doneUnlock:
	call	ObjSwapUnlock
done:
	ret

callSuper:
	mov	di, offset OLItemGroupClass
	call	ObjCallSuperNoLock
	ret
OLItemGroupGrabFocusExcl	endm

ItemCommon	ends

endif ; _JEDIMOTIF or _RUDY
