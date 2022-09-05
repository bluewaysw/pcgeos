COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		copenMenuButton.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLMenuButtonClass	Open look button for running a menu

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:

	$Id: copenMenuButton.asm,v 2.171 97/04/02 21:36:03 brianc Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLMenuButtonClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonSetup -- MSG_OL_BUTTON_SETUP
		for OLMenuButtonClass

DESCRIPTION:	Setup an OLButton object for popup windows or menus.
		(This METHOD is invoked immediately after the initialization
		method above; see OLPopupWinClass.)

PASS:		*ds:si - instance data
		es - segment of OLMenuButtonClass
		ax - MSG_OL_BUTTON_SETUP
		cx - generic object in same block which this button is
			associated with.
		dl - type of popup window that button is associated
			with (OLWinType)
		dh - OLWinFixedAttr (contains OWFA_IS_MENU, etc)
		bp - OLBuildFlags which BUILD_INFO query determined for the
			popup window this button opens

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	Eric	2/90		Rewrite, is now MSG_OL_BUTTON_SETUP instead
				of MSG_OL_MENU_BUTTON_SETUP.
	sean	6/96		Setup for Selection Boxes (Odie)

------------------------------------------------------------------------------@


OLMenuButtonSetup	method	OLMenuButtonClass, MSG_OL_BUTTON_SETUP

	;make sure that this menu button has been created for a menu window
EC <	test	dh, mask OWFA_IS_MENU 					>
EC <	ERROR_Z OL_ERROR						>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLBI_genChunk, cx	;save handle of gen parent
	mov	ds:[di].OLMBI_popupType, dl	;save window type

	push	bp
	call	OLButtonScanGeometryHints	;scan geometry, to reflect hints
	pop	bp				;  in popup window


	;If this button opens a menu which was in a GenDisplay but is now
	;accessable via a menu bar in a GenPrimary above the GenDisplayControl,
	;(whew!), then set this button not SA_REALIZABLE - when the Display
	;gets the focus, it will tell this button to show itself.

	test	bp, mask OLBF_ABOVE_DISP_CTRL
	jz	afterTransientCheck		;skip if is permanent...

	test	bp, mask OLBF_ALWAYS_ADOPT
	jnz	afterTransientCheck		;skip if is permanent...

;NOTE: ERIC: see doug about problem in OLMenuButtonSetup
;If we set this object UN_MANAGED here, we would expect that geometry
;would run on it when we get SHOW_BUTTON and set it managed. This is not
;the case.
;	ANDNF	ds:[di].VI_attrs, not (mask VA_MANAGED)

	ANDNF	ds:[di].VI_attrs, not (mask VA_DRAWABLE or mask VA_DETECTABLE)
					;reset these flags

afterTransientCheck:

	;update some flags according to where this menu button has been
	;placed, and the type of menu that it opens

	call	UseQueryResultsToSetButtonAttributes
					;update IN_MENU / IN_MENU_BAR status,
					;and bordered status
					;returns ds:di = VisSpec instance data

OLS <	cmp	dl, OLWT_SYSTEM_MENU	;if opens a system menu		>
CUAS <	cmp	dl, MOWT_SYSTEM_MENU					>
	je	isSystemMenuButton	;then skip ahead to handle...

	;now set the OLBSS_MENU_DOWN_MARK, etc. according to which type of
	;window is opened.  (In CUAS, we'll change it so the menu down mark is
	;only set when we want to use it, i.e. in popup lists.)

	mov	ax, mask OLBSS_MENU_RIGHT_MARK
OLS <	cmp	dl, OLWT_SUBMENU	;if opens a sub			>
CUAS <	cmp	dl, MOWT_SUBMENU					>

	je 	setWindowFlagAndMakeEnabled	;submenu, use right arrow

	; For Odie, the OLMBSS_OPENS_POPUP_LIST flag denotes a 
	; selection box.  We set flags relating to this, and 
	; purposely let ax be cleared in the next instruction,
	; since we don't want a menu down mark for selection
	; boxes.  sean 6/10/96.
	;
if	SELECTION_BOX
	call	SetSelectionBoxFlags
endif
	mov	ax, mask OLBSS_MENU_DOWN_MARK
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jnz	setWindowFlag		;popup list, use down mark.

if _JEDIMOTIF
	;
	; JEDI menu buttons in menu bar have menu mark
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jnz	setWindowFlagAndMakeEnabled
endif

	clr	ax			;regular menu, use nothing.

setWindowFlagAndMakeEnabled:

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	; For now, set as enabled, no matter what our parent is...
	; (Moved here 12/17/92 so popup lists don't automatically set this.)

	ORNF	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
endif

setWindowFlag:		
	ORNF	ds:[di].OLBI_specState, ax
	jmp	short updateButtonState

isSystemMenuButton:
	;this is a system menu button: we must reset some flags:
	;set bordered, not in menu bar, etc.

	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_IN_MENU_BAR)

if _PM
	;
	; This is a hack for PM.  PM allow menus to be put in stay-mode without
	; the menu button being pressed.  When the menu leaves stay up mode,
	; the button restores it old state.  But because the old button state
	; was never saved, it restores garbage.  So we initialize the old
	; state here. - Joon (3/22/93)
	;
	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED or \
					mask OLBSS_WAS_BORDERED
else
CUAS <	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED		>
endif

	mov	cx, si
	call	OLButtonHintSysIcon	;set OLBSS_SYS_ICON flag, make button
					;not MANAGED.

updateButtonState:	
	;DO NOT CALL SUPERCLASS: OLButtonClass does something completely
	;different!

	call	SetToolboxBasedOnParent	;set toolbox flag

if (_ODIE and DRAW_STYLES)
	;
	; for menu buttons in title bar:
	; sys icons are not bordered, though close button is bordered
	; sys icons are flat, though close button is raised
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jz	notSysIcon
					; sys icons, no bordered and flat
	andnf	ds:[di].OLBI_specState, not mask OLBSS_BORDERED
	mov	ds:[di].OLBI_drawStyle, DS_FLAT
notSysIcon:
	;
	; buttons in menu and menu bar use flat draw style
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
						mask OLBSS_IN_MENU_BAR
	jz	notInMenu
	mov	ds:[di].OLBI_drawStyle, DS_FLAT
notInMenu:
endif

	GotoMod	UpdateButtonState	;copy generic state data from
					;GenTrigger object, set DRAW_STATE_KNOWN
OLMenuButtonSetup	endp

;See OpenWinEnsureSysMenuIcons.

OLMenuButtonSetIsSysMenuIcon	method	dynamic OLMenuButtonClass, \
				MSG_OL_MENU_BUTTON_SET_IS_SYS_MENU_ICON
	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_SYS_MENU_ICON
	ret
OLMenuButtonSetIsSysMenuIcon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectionBoxFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the flags associated with selection boxes.

CALLED BY:	OLMenuButtonSetup

PASS:		*ds:si	= OLMenuButton object
		ds:di	= fptr to OLMenuButton instance data

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	sets OLMBI_odieFlags instance data

PSEUDO CODE/STRATEGY:
		if(popup list)
		  set selection box flag
		  if(oriented vertically)
		    set vertical selection box flag
		  if(non-wrapping list)
		    set non-wrapping list flag
		    check if arrows initially disabled
		  if(3-D border)
		    set 3-D border flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SetSelectionBoxFlags	proc	near
	uses	ax,bx,di,si,bp
	.enter

	; If the menu button opens a popup list, it must be a 
	; selection box.
	;
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	exit	
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX

;EC <	call	ECSelectionBoxValidateNumberOfChildren			>

	; The popup win should always orient the children vertically
	; (since we need to calculate the width of the largest).
	;
	mov	bp, si				; *ds:bp = menu button
	mov	bx, ds:[di].OLBI_genChunk	; *ds:si = popup win
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	ornf	ds:[bx].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	call	GetMenuButtonsItemGroupFar	; *ds:si = item group

	; Check to see if it's a vertical selection box
	;
checkVertical:
	mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
	call	ObjVarFindData			; look for hint
	jnc	checkForWrapping		; no hint--check next hint
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	
checkForWrapping:
	mov	ax, HINT_ITEM_GROUP_NON_WRAPPING_LIST
	call	ObjVarFindData			; wrapping list ?
	jnc	check3D				; yes (default)
	
	; Non-wrapping list.  Set non-wrapping selection box
	; flag.  Check if any arrow boxes are initially disabled.
	;
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_NON_WRAPPING_SELECTION_BOX
	push	si				; save item group
	mov	si, bp				; *ds:si = menu button
	call	CheckIfArrowsDisabledFar	; arrows initially disabled ?
	pop	si				; restore item group

	; Check if we have a 3-D border or not.  Default is bordered.
	;
check3D:
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_BORDERED_SELECTION_BOX
	mov	ax, HINT_DRAW_STYLE_FLAT
	call	ObjVarFindData
	jnc	exit
	ANDNF	ds:[di].OLMBI_odieFlags, not (mask OLMBOF_BORDERED_SELECTION_BOX)
exit:
	.leave
	ret
SetSelectionBoxFlags	endp
endif		; if SELECTION_BOX


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonGupQuery (MSG_SPEC_GUP_QUERY)

DESCRIPTION:	HandleMem GUP query for menu button.  This routine is needed
		because this button has been fabricated, & doesn't have a
		generic parent.  Where generic matters are concerned, we
		want to pass those queries off to the menu from which we
		came.

PASS:		*ds:si - instance data
		cx, dx, bp	- data

RETURN:

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@
OLMenuButtonGupQuery	method	OLMenuButtonClass, MSG_SPEC_GUP_QUERY
	GOTO	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.
OLMenuButtonGupQuery	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonInitPopupOrientation -- 
		MSG_OL_MENU_BUTTON_INIT_POPUP_ORIENTATION for OLMenuButtonClass

DESCRIPTION:	Initializes popup orientation.  Sent by the PopupWin when it
		is spec building and needs this information.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_MENU_BUTTON_INIT_POPUP_ORIENTATION

RETURN:		carry set if we're to orient the popup horizontally
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/10/92		Initial Version

------------------------------------------------------------------------------@

if not _RUDY

OLMenuButtonInitPopupOrientation	method dynamic	OLMenuButtonClass, \
				MSG_OL_MENU_BUTTON_INIT_POPUP_ORIENTATION

EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST	>
EC <	ERROR_Z	OL_ERROR			;popup shouldn't have called

	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	exit				;not in toolbox, orient
						;  vertically
	;
	; If our vis parent is vertical, display a horizontal popup list.
	;
	call	VisGetParentGeometry		;parent geometry in cl
	test	cl, mask VCGA_ORIENT_CHILDREN_VERTICALLY	; clears carry
	jz	exit
	ornf	ds:[di].OLMBI_specState, mask OLMBSS_ORIENT_POPUP_HORIZONTALLY
	stc
exit:
	ret
OLMenuButtonInitPopupOrientation	endm

endif

Build	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		MSG_HIDE_MENU_BUTTON/MSG_SHOW_MENU_BUTTON

DESCRIPTION:	This method is sent from a GenDisplay when it has menus
		which have been adopted by the GenPrimary above the
		GenDisplayControl. The GenDisplay sends this methods to
		all of its generic children, hoping to get to the
		GenInteractions which become menus. These menus forward
		this method to their menu button objects, so here we are.
		We set the button visible or not visible, and update
		their parent (the menu bar in the GenPrimary).

PASS:		ds:*si	- instance data
		ax - METHOD
		cx, dx, bp - ?

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		initial version

------------------------------------------------------------------------------@

OLMenuButtonShowMenuButton	method	OLMenuButtonClass, \
							MSG_SHOW_MENU_BUTTON
	mov	cx, mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE
					;set these flags
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
					;NO NOT USE VUM_NOW, because will get
					;UI_NESTED_VISUAL_UPDATE
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock
	ret
OLMenuButtonShowMenuButton	endm


OLMenuButtonHideMenuButton	method	OLMenuButtonClass, \
							MSG_HIDE_MENU_BUTTON
	;in case the user is (or was) interacting with this menu button,
	;release the GADGET exclusive now. This will force us to release
	;the mouse, focus, and target exclusives if necessary.

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParent

	mov	cx, (mask VA_MANAGED or mask VA_DRAWABLE \
				or mask VA_DETECTABLE) shl 8
					;reset these flags
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
					;NO NOT USE VUM_NOW, because will get
					;UI_NESTED_VISUAL_UPDATE
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock

	ret
OLMenuButtonHideMenuButton	endm

ActionObscure ends

;-----------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonEnsureIsDrawnDepressedNOW

DESCRIPTION:	This procedure makes sure that this OLMenuButton is
		drawn as depressed, which depending upon the specific
		UI might mean DEPRESSED (blackened) and/or BORDERED.

CALLED BY:	OLMenuButtonHandleMenuFunction
		OLMenuButtonHandleDefaultFunction
		OLMenuButtonGenActivate

PASS:		*ds:si	= instance data for object

RETURN:		ds, si = same

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonEnsureIsDrawnDepressedNOW	proc	far
	;First: if this is the first moment of interaction with this
	;menu button, save its BORDERED and DEPRESSED states, so can restore
	;later to reset the button visually.

	call	OLMenuButtonSaveBorderedAndDepressedStatusIfStartingInteraction
					;returns ds:di = spec instance data

	;now set depressed and/or bordered as required.

	call	OLMenuButtonSetBorderedAndOrDepressed
	call	OLButtonDrawNOWIfNewState ;redraw immediately if necessary
	ret
OLMenuButtonEnsureIsDrawnDepressedNOW	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonSaveBorderedAndDepressedStatusIfStartingInteraction

DESCRIPTION:	if this is the first moment of interaction with this
		menu button, save its BORDERED and DEPRESSED states, so can
		restore later to reset the button visually.

CALLED BY:	OLMenuButtonEnsureIsDrawnDepressedNOW
		OLMenuButtonSetCursored

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same
		ds:di	= specific instance data for object

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonSaveBorderedAndDepressedStatusIfStartingInteraction	 proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED or \
					mask OLBSS_HAS_MOUSE_GRAB
	jnz	done

	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jnz	done			;skip if already open...

	call	OLButtonSaveBorderedAndDepressedStatus
					;does not trash bx, ds, si, di

done:
	ret
OLMenuButtonSaveBorderedAndDepressedStatusIfStartingInteraction	 endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonSetBorderedAndOrDepressed

DESCRIPTION:	This procedure makes sure that this OLMenuButton is
		drawn as depressed, which depending upon the specific
		UI might mean DEPRESSED (blackened) and/or BORDERED.

CALLED BY:	OLMenuButtonEnsureIsDrawnDepressedNOW
			(called by:	OLMenuButtonHandleMenuFunction
					OLMenuButtonHandleDefaultFunction)

PASS:		*ds:si	= instance data for object

RETURN:		ds, si, cx, dx, bp = same

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonSetBorderedAndOrDepressed	proc	near

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

;if ERROR_CHECK
;	;make sure that we are inside a menu or menu bar, or is sys menu icon
;
;	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR or \
;				mask OLBSS_IN_MENU or mask OLBSS_SYS_ICON
;	ERROR_Z OL_ERROR
;endif

	;first let's decide which of the DEPRESSED and BORDERED flags
	;we are dealing with. Start by assuming this OLMenuButton is a
	;system menu button:
	;	OPEN_LOOK:	assume B, set D
	;	PM:		assume B, set D
	;	MOTIF:		assume B, set D
	;	CUA:		assume B, set D

	mov	bx, mask OLBSS_DEPRESSED ;bx = flags to set

	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jnz	haveFlags		;popup list button, allow to invert

	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	haveFlags		;skip if is a system menu button...

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR or \
					mask OLBSS_IN_MENU
	jz	haveFlags		;neither set, is floating menu, 
					;  allow to invert

MO <	mov	bx, mask OLBSS_DEPRESSED or mask OLBSS_BORDERED		>
MO <	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR		>
MO <	jz	M10						 	>
MO <	call	OpenCheckIfBW		;B/W menus invert now. -cbh 3/10/93 >
MO <	jc	haveFlags						>
MO <M10:								>


	;This OLMenuButton is either in the menu bar or in a menu.
	;The behavior is the same in both cases:
	;	(NOT TRUE ANYMORE.. see code above by cbh, and ** below).
	;
	;In Menu:
	;	OPEN_LOOK:	set B, set D
	;			(OL: if in pinned menu, B will already be set)
	;	PM:		set B, set D
	;	MOTIF:		set B
	;	CUA:		set D
	;
	;In Menu bar:
	;	OPEN_LOOK:	assume B, set D
	;	PM:		set B, set D
	;	MOTIF:		set B in color, set B, D in B & W **
	;	CUA:		set D
	
	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, the menu buttons
	; are depressed if we are in B&W.  If _ASSUME_BW_ONLY is true, then
	; we do not check confirm that we are in B&W mode, but just assume
	; that is the case. --JimG 5/5/94

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	mov	bx, mask OLBSS_DEPRESSED
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	
if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)
	call	OpenCheckIfBW
	jc	haveFlags			; if BW, we are done..
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)

if	 (not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)
PMAN <	mov	bx, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED		>
NOT_MO<	mov	bx, mask OLBSS_DEPRESSED				>

if _ODIE
	mov	bx, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED
else
MO <	mov	bx, mask OLBSS_BORDERED					>
endif
endif	;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

haveFlags:
	ORNF	ds:[di].OLBI_specState, bx

done:
	ret
OLMenuButtonSetBorderedAndOrDepressed	endp


COMMENT @----------------------------------------------------------------------

METHOD:  	OLMenuButtonStartSelect -- MSG_META_START_SELECT
		for OLMenuButtonClass

DESCRIPTION:	Handle SELECT press in menu button.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		bp	- [ UIFunctionsActive | ButtonInfo ]

RETURN:

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@

OLMenuButtonStartSelect	method	OLMenuButtonClass, MSG_META_START_SELECT

if _CUA_STYLE	;--------------------------------------------------------------
	;CUA/Motif: if system menu button, check for double-click

	test	bp, mask BI_DOUBLE_PRESS
	jz	OLMBSS_90			;skip if not...

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_SYS_MENU_ICON
	jz	OLMBSS_90			;skip if not...


	push	ax, bx, cx, dx, si, bp

	; OK, let's do something unusual here, to solve an unusual bug; that of
	; a double-click-hold action "going through" the window that is being
	; closed, to allow interaction with menu buttons underneath the window
	; being closed.  This unique problem has been give a unique solution:
	; We synchronously tell the Flow object to terminate the current
	; SELECT operation in progress -- it is converted to an "OTHER" 
	; operation, for the remainder of its life (i.e. subsequent button
	; events will be MSG_META_PTR w/no active function, MSG_META_DRAG_OTHER,
	; MSG_META_END_OTHER.  NOTE: The post-passive grab will still see
	; the MSG_META_START_SELECT.
	;
	mov	ax, MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION
	call	VisCallParent

	; Send "CLOSE" method to queue for GenPrimary/GenDisplay/
	; GenInteraction - so that the remaining menu window processing is not
	; screwed up because there is suddenly no window where the button has
	; landed -- an INSERT_AT_FRONT will allow the close to happen as soon
	; as the double-press has finished being processed.
	; (GenPrimary/GenDisplay/GenInteraction will ignore if is not
	;  USER_DISMISSABLE)

	call	VisFindParent			;returns bx:*si = visparent
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_OL_WIN_CLOSE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

	pop	ax, bx, cx, dx, si, bp

OLMBSS_90:
endif 		;--------------------------------------------------------------

	call	OpenDoClickSound
	GOTO	OLMenuButtonHandleEvent

OLMenuButtonStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuButtonIsMenuBarButtonCascading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if: 1) button is in menu bar, 2) the button's
		menu is cascading

CALLED BY:	OLMenuButtonHandleEvent
PASS:		*ds:si	= Menu Button
RETURN:		carry: Set if Yes to both 1) & 2).  Clear if no
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuButtonIsMenuBarButtonCascading	proc	near
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jz	done
	
	mov	di, ds:[di].OLBI_genChunk	; (menu) for this button's
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	jz	done
	
	stc
done:
	.leave
	ret
OLMenuButtonIsMenuBarButtonCascading	endp
endif	;_CASCADING_MENUS




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonTranslateMenuFunctions

DESCRIPTION:	This routine translates the UI-specified function buttons
		(UIFA_SELECT, etc) into menu functions: MENU and DEFAULT.

CALLED BY:	OLMenuButtonHandleEvent

PASS:		*ds:si	= instance data for object
		bp(high) = UIFunctionsActive (UIFA_SELECT, UIFA_FEATURES, etc)

RETURN:		bp(high) = OLMenuButtonFunctionsActive

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	sean	6/96		Got rid of Open Look version

------------------------------------------------------------------------------@

OLMenuButtonTranslateMenuFunctions	proc	near
	;CUA style: only keep MENU and IN_BOUNDS info. Ignore default action.

	ANDNF	bp, ((mask OLMBFA_MENU or mask OLMBFA_IN_BOUNDS) shl 8) or 0ffh
	ret
OLMenuButtonTranslateMenuFunctions	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonHandleEvent

DESCRIPTION:	This procedure is called when:
		 - the mouse button is pressed inside the menu button
		 - the menu button has the mouse grab, and:
			- the mouse button is released
			- the mouse pointer leaves the menu button region

		This procedure examines the current mouse and menu button state
		and decides whether to open or close the menu, and how to
		draw the menu button.

CALLED BY:	OLMenuButtonStartSelect
		MSG_META_END_SELECT
		MSG_META_PTR

PASS:		ds:*si	- OLButton object
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | ButtonInfo ]
		ax	- message that got us here

RETURN:		ax = MRF_PROCESSED if menu button has handled event
		   = MRF_REPLAY if menu button has handled event by releasing
			mouse grab, and so event must be sent to implied
			grab now.

DESTROYED:	bx, cx, dx, di


PSEUDO CODE/STRATEGY:
	read the code!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version
	sean	6/96		Support for Selection Boxes (Odie)

------------------------------------------------------------------------------@


OLMenuButtonHandleEvent	method	OLMenuButtonClass, \
				MSG_META_END_SELECT, MSG_META_PTR 
if _JEDIMOTIF
	;
	; On MSG_META_PTR, ignore if Jotter drag in progress
	;
	cmp	ax, MSG_META_PTR
	jne	notJotterDrag
	call	JotterIsDragActive	; (does tst <is-active BOOLEAN>)
	jnz	ignoreEvent		; is active
notJotterDrag:
endif
	;
	; Have popup buttons ignore MSG_META_PTR's if they don't have the
	; mouse grab.  We don't want to be able to wander over popup list
	; buttons.  -cbh 2/17/93
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	10$
	cmp	ax, MSG_META_PTR
	jne	10$
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jz	ignoreEvent
10$:

	;translate UIFunctionsActive (UIFA_SELECT, UIFA_FEATURES, UIFA_IN)
	;into OLMenuButtonFunctionsActive (OLMBFA_MENU, OLMBFA_DEFAULT, and
	;OLMBFA_IN_BOUNDS) according to this specific UI.

	call	OLMenuButtonTranslateMenuFunctions
					;returns bp (high) = OLMBFA flags

	;see if a menu function is already in progress

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING
	jnz	menuFunctionPending	;skip if menu is opened...

	test	ds:[di].OLMBI_specState, mask OLMBSS_DEFAULT_FUNCTION_PENDING
	jnz	defaultFunctionPending	;skip if default is displayed...

	;no menu function is in progress. If this button is disabled,
	;ignore new events.  

	call	OpenButtonCheckIfFullyEnabled
	jnc	ignoreEvent		;skip to end if not...

if	 _CASCADING_MENUS
	; Ignore event if this menu button is in a menu bar at the menu is
	; already cascading -- it will be closed by another mechanism within
	; the cascading menu code inside the menu.
	call	OLMenuButtonIsMenuBarButtonCascading
	jc	ignoreEvent
endif	;_CASCADING_MENUS

if _PM	;----------------------------------------------------------------------
	;PM: If this menu button opens a drop down list, then the "MENU"
	;button is considered pressed only if the mouse pointer is pressed
	;over the down menu mark at the right end of the menu button.

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_MENU_DOWN_MARK
	jz	notDropDownList
;dropDownList:
	mov	bx, ds:[di].VI_bounds.R_right
	sub	bx, OL_MARK_WIDTH + 3
	cmp	cx, bx
	jg	pressed				;if greater, then pressed
;notPressed:
	ANDNF	bp, not ((mask OLMBFA_MENU) shl 8)	;button is not pressed
pressed:
notDropDownList:
endif	;----------------------------------------------------------------------

	; For Odie, take care of selection boxes.  Selection box mouse
	; takes care of redrawing its arrow boxes & taking care of 
	; gadget/mouse/focus exclusives.
	;
if	SELECTION_BOX ; -----------------------------------------------------
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX
	jz	15$
	call	SelectionBoxMouse
	jmp	ignoreEvent
15$:	
endif	; if SELECTION_BOX --------------------------------------------------

	;no menu function is in progress. Check OLMBFA flags to see if
	;a new mouse button is pressed. If none pressed, ignore event.
	;At present, we do not have a specific UI whose menu buttons react
	;to a mouse sliding over them.

	test	bp, (mask OLMBFA_MENU) shl 8	;"MENU" button pressed?
	jz	checkForDefault			;skip if not...

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING
	
if	 _CASCADING_MENUS
	; At this point, this menu button is first becoming selected.  So we
	; need to inform the menu about our cascade state.  It this menu
	; button's submenu is already open, then we need to tell the menu
	; that we are CASCADING, otherwise we are not.  
	; OLButtonSendCascadeModeToMenu may also be called from
	; OLMenuButtonHandleMenuFunction.

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	menuFunctionPending
	
	push	cx, dx, bp
	; Flags passed in cl: Don't start grab.
	clr	cx				; assume not CASCADING
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	sendToMenu
	ornf	cl, mask OMWCMO_CASCADE		; already open, CASCADE please
	mov	dx, ds:[LMBH_handle]		; ^ldx:bp = GenInteraction
	mov	bp, ds:[di].OLBI_genChunk	; (menu) for this button's
						; submenu
sendToMenu:
	call	OLButtonSendCascadeModeToMenu
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;may have moved
	pop	cx, dx, bp
endif	;_CASCADING_MENUS

menuFunctionPending:
	;pass ds:di = instance data

	call	OLMenuButtonHandleMenuFunction
	
	ret				;return MouseReturnFlags in ax

checkForDefault:
	test	bp, (mask OLMBFA_DEFAULT) shl 8	;"DEFAULT" button pressed?
	jz	ignoreEvent			;skip if not...

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_DEFAULT_FUNCTION_PENDING

defaultFunctionPending:
	;pass ds:di = instance data

	call	OLMenuButtonHandleDefaultFunction
	ret				;return MouseReturnFlags in ax

ignoreEvent:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret				;return MouseReturnFlags in ax
OLMenuButtonHandleEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionBoxMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes care of mouse clicks within a selection box.

CALLED BY:	OLMenuButtonHandleEvent

PASS:		*ds:si	= menu button
		ds:di	= Vis instance of menu button
		cx, dx	- ptr position

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

		if(prev/next arrow down)  /* must be end selection msg */
		  release mouse
		  set arrow NOT depressed
		  check if arrows are now disabled (sets area mask)
		  redraw selection box
		else  /* start select message */
		  get focus excl
		  if(mouse w/i arrow bounds && arrow NOT disabled)
		      set arrow depressed
		      redraw selection box 
		      select next/prev item in selection box
		      take gadget excl
		      get mouse excl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SelectionBoxMouse	proc	near
	uses	ax,bx,si,di,bp
	.enter

EC <	test 	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX 	>
EC <	ERROR_Z		OL_ERROR_SELECTION_BOX				>

	cmp	ax, MSG_META_MOUSE_PTR
	je	checkIfStillInBounds

	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN or\
					 mask OLMBOF_NEXT_ARROW_DOWN 	
	jnz	endSelect

EC <	cmp	ax, MSG_META_START_SELECT				>
EC <	ERROR_NE	OL_ERROR_SELECTION_BOX				>

	push	cx, dx				; save ptr coordinates
	call	OLMenuButtonGrabFocusExcl
	pop	cx, dx				; restore ptr coordinates

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			; redef menu button

	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_NEXT	; assume next press
	mov	bl, AT_NEXT_ARROW			; check next arrow
	call	CheckIfMouseInArrowBoxBounds		; carry set = press
	jc	nextPressed

	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	mov	bl, AT_PREV_ARROW			; check prev arrow
	call	CheckIfMouseInArrowBoxBounds
	jc	prevPressed
exit:

	.leave
	ret

	; MSG_META_PTR--User may have dragged out of arrow box.  If
	; so, we want same response as end select.
	;
checkIfStillInBounds:
	test	ds:[di].OLMBI_moreOdieFlags, mask OLMBOF_PENDING_END_SELECT
	jnz	endSelect
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN or\
					 mask OLMBOF_NEXT_ARROW_DOWN
	jz	exit
	mov	bl, AT_NEXT_ARROW
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_NEXT_ARROW_DOWN
	jnz	checkBounds
	mov	bl, AT_PREV_ARROW
checkBounds:
	call	CheckIfMouseInArrowBoxBounds
	jc	exit

	; End Select.
	;
endSelect:
	call	SelectionBoxEndSelect
	jmp	exit

	; This is where we take care of a mouse press within either
	; the next/prev arrow box bounds.  If the arrow is not
	; disabled (non-wrapping lists), then we redraw the arrow box
	; depressed & send the SET_SELECTION_NEXT/PREVIOUS message to
	; the item group.
	;
prevPressed:
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_PREV_DISABLED
	jnz	exit			; previous arrow button disabled
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN
	jmp	pressed

nextPressed:
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_NEXT_DISABLED
	jnz	exit			; next arrow button disabled
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_NEXT_ARROW_DOWN
pressed:
	call	OpenDrawObject			; redraw selection box
	call	StartSelectionBoxTimer		; repeat press timer
	push	si				; save menu button
	call	GetMenuButtonsItemGroup		; *ds:si = item group
	call	ObjCallInstanceNoLock		; select next/prev item
	pop	si				; restore menu button

	; Take care of the mouse grab, gadget excl.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	call	OLMenuButtonTakeGadgetExcl	;grab GADGET EXCLUSIVE
	call	VisGrabMouse			;Grab the mouse for this button
	jmp	exit

SelectionBoxMouse	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionBoxEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End select for selection box

CALLED BY:	SelectionBoxMouse, SelectionBoxLostGadget 

PASS:		*ds:si	= OLMenuButton object
		ds:di	= OLMenuButton instance

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Releases mouse, cancels timer if one is pending

PSEUDO CODE/STRATEGY:
		Cancel repeat-press timer
		Release mouse
		Check if at end of non-wrapping list
		Clear arrow down flag
		Clear pending end select flag
		Redraw object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	1/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SelectionBoxEndSelect	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	CancelSelectionBoxTimer		; cancel repeat press timer
	call	VisReleaseMouse			; don't need mouse anymore
	call	CheckIfArrowsDisabled		; check in non-wrapping list
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLMBI_odieFlags, not (mask OLMBOF_NEXT_ARROW_DOWN or\
					     mask OLMBOF_PREV_ARROW_DOWN)
	ANDNF	ds:[di].OLMBI_moreOdieFlags, not (mask\
					OLMBOF_PENDING_END_SELECT)
	call	OpenDrawObject			; redraw selection box

	.leave
	ret
SelectionBoxEndSelect	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Start/CancelSelectionBoxTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts/ends timer for selection box (needed for repeat press)

CALLED BY:	SelectionBoxMouse

PASS:		*ds:si	= OLMenuButton object

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	sets timer with application object

PSEUDO CODE/STRATEGY:
		Set/Clear instance data for pending timer		
		Set/Clear timer with app obj

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	1/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
StartSelectionBoxTimer	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLMBI_moreOdieFlags, mask OLMBOF_TIMER_PENDING
	
	mov	dx, si
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = menu button
	mov	ax, MSG_OL_APP_STOP_TIMER	; stop previous timer
	call	GenCallApplication

	mov	dx, si
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = menu button
	clr	bp			; standard repeat timer
	mov	ax, MSG_OL_APP_START_TIMER	; start timer
	call	GenCallApplication

	.leave
	ret
StartSelectionBoxTimer	endp

CancelSelectionBoxTimer	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_moreOdieFlags, mask OLMBOF_TIMER_PENDING
	jz	exit
	ANDNF	ds:[di].OLMBI_moreOdieFlags, not (mask OLMBOF_TIMER_PENDING)

	mov	dx, si
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = menu button
	mov	ax, MSG_OL_APP_STOP_TIMER	; stop previous timer
	call	GenCallApplication
exit:
	.leave
	ret
CancelSelectionBoxTimer	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMBTimerExpired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Repeat press timer has expired.

CALLED BY:	MSG_TIMER_EXPIRED

PASS:		*ds:si	= OLMenuButtonClass object
		ds:di	= OLMenuButtonClass instance data
		ds:bx	= OLMenuButtonClass object (same as *ds:si)
		es 	= segment of OLMenuButtonClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Sets instance data of menu button

PSEUDO CODE/STRATEGY:
		if(TIMER_PENDING)
		  Clear TIMER_PENDING
		  if(arrow not disabled)  /* e.g. non-wrapping list */
		    Make repeat press
		  else
		    set pending end select flag
		    cancel timer
		    redraw object (because arrow is now disabled)
		else
		  exit
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	1/ 8/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
OLMBTimerExpired	method dynamic OLMenuButtonClass, 
					MSG_TIMER_EXPIRED
	uses	ax, cx, dx, bp
	.enter

	test	ds:[di].OLMBI_moreOdieFlags, mask OLMBOF_TIMER_PENDING
EC <	WARNING_Z	OL_WARNING_SPURIOUS_TIMER			>
	jz	exit

EC <	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN or\
					 mask OLMBOF_NEXT_ARROW_DOWN 	>
EC <	ERROR_Z		OL_ERROR_SELECTION_BOX				>

	ANDNF	ds:[di].OLMBI_moreOdieFlags, not (mask OLMBOF_TIMER_PENDING)

	mov	al, mask OLMBOF_SELECTION_BOX_PREV_DISABLED
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN
	jnz	checkIfDisabled
	mov	al, mask OLMBOF_SELECTION_BOX_NEXT_DISABLED
checkIfDisabled:
	test	ds:[di].OLMBI_odieFlags, al
	jnz	disabled

	call	SelectionBoxRepeatPress
exit:
	.leave
	ret

disabled:
	ORNF	ds:[di].OLMBI_moreOdieFlags, mask OLMBOF_PENDING_END_SELECT
	call	CancelSelectionBoxTimer		; cancel repeat press timer
	call	OpenDrawObject
	jmp	exit

OLMBTimerExpired	endm
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionBoxRepeatPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles a repeat press on a selection box

CALLED BY:	OLMBTimerExpired

PASS:		*ds:si	= OLMenuButton object
		ds:di	= OLMenuButton instance

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Re-starts app timer

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	1/ 8/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SelectionBoxRepeatPress	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Select next/previous item depending on which arrow is 
	; being repeat-pressed.
	;
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN
	jnz	repeatPress
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
repeatPress:
	push	si				; save menu button
	call	GetMenuButtonsItemGroup		; *ds:si = item group
	call	ObjCallInstanceNoLock		; select next/prev item
	pop	si				; restore menu button

	; Re-start repeat press timer
	;
	call	StartSelectionBoxTimer	

	; See if we're at the first/last item in non-wrapping
	; list.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	CheckIfArrowsDisabled		

	.leave
	ret
SelectionBoxRepeatPress	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMouseInArrowBoxBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a mouse press is within the bounds of
		a selection box's next/previous arrow box bounds.

CALLED BY:	SelectionBoxMouse

PASS:		*ds:si	= menu button
		bl	= ArrowType enum
		cx, dx	= (x,y) coordinate of mouse press

RETURN:		carry clear = mouse press NOT within arrow box bounds
		carry set   = mouse press within arrow box bounds

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
CheckIfMouseInArrowBoxBounds	proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	Assert	etype		bl, ArrowType			> 
EC <	Assert	objectPtr	dssi, OLMenuButtonClass		>

	mov	di, cx			; di = mouse x-coordinate
	mov	bp, dx			; bp = mouse y-coordinate
	
	cmp	bl, AT_NEXT_ARROW
	jne	prevArrow
	call	SelectionBoxGetNextArrowBounds	; ax,bx,cx,dx = bounds
	jmp	checkBounds
prevArrow:
	call	SelectionBoxGetPrevArrowBounds	; ax,bx,cx,dx = bounds

checkBounds:
	cmp	di, ax
	jl	notPressed
	cmp	di, cx
	jg	notPressed
	cmp	bp, bx
	jl	notPressed
	cmp	bp, dx
	jg	notPressed
	stc				; within bounds -> press valid
exit:
	.leave
	ret

notPressed:
	clc				; not within bounds -> press not valid
	jmp	exit

CheckIfMouseInArrowBoxBounds	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionBoxGetNext/PrevArrowBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns bounds of arrow boxes within selection box

CALLED BY:	DrawSelectionBoxIfNecessary

PASS:		*ds:si	= menu button

RETURN:		ax,bx,cx,dx = bounds of next/prev arrow box
			      within the selection box

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SelectionBoxGetNextArrowBoundsFar	proc	far
	call	SelectionBoxGetNextArrowBounds
	ret
SelectionBoxGetNextArrowBoundsFar	endp

SelectionBoxGetNextArrowBounds	proc	near
	uses	di, bp
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass		>

	call	VisGetBounds		; ax, bx, cx, dx = bounds
if CURSOR_OUTSIDE_BOUNDS
	;
	; adjust selection box bounds for outside cursor
	;
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
endif

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, SELECTION_BOX_INSET
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_BORDERED_SELECTION_BOX
	jz	notBordered
	add	bp, SELECTION_BOX_BORDER

notBordered:	
	sub	cx, bp
	sub	dx, bp
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	vertical

	mov	ax, cx
	sub	ax, SELECTION_BOX_ARROW_WIDTH
	add	bx, bp
exit:
	.leave
	ret

vertical:
	mov	bx, dx			; bx = bottom coordinate
	sub	bx, SELECTION_BOX_ARROW_HEIGHT
	add	ax, bp
	jmp	exit

SelectionBoxGetNextArrowBounds	endp


SelectionBoxGetPrevArrowBoundsFar	proc	far
	call	SelectionBoxGetPrevArrowBounds
	ret
SelectionBoxGetPrevArrowBoundsFar	endp

SelectionBoxGetPrevArrowBounds	proc	near
	uses	di, bp
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass		>

	call	VisGetBounds		; ax, bx, cx, dx = bounds
if CURSOR_OUTSIDE_BOUNDS
	;
	; adjust selection box bounds for outside cursor
	;
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
endif

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, SELECTION_BOX_INSET
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_BORDERED_SELECTION_BOX
	jz	notBordered
	add	bp, SELECTION_BOX_BORDER

notBordered:	
	add	ax, bp
	add	bx, bp
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	vertical

	mov	cx, ax
	add	cx, SELECTION_BOX_ARROW_WIDTH
	sub	dx, bp
exit:
	.leave
	ret

vertical:
	mov	dx, bx			; bx = bottom coordinate
	add	dx, SELECTION_BOX_ARROW_HEIGHT
	sub	cx, bp
	jmp	exit
	
SelectionBoxGetPrevArrowBounds	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMenuButtonsItemGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the item group associated with an OLMenuButton

CALLED BY:	SelectionBoxMouse, GetCurrentFirstAndLastItems,
		SetSelectionBoxFlags

PASS:		*ds:si	= menu button

RETURN:		*ds:si	= OLItemGroup associated with menu button

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Get parent interaction of menu button
		Get first child of interaction		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
GetMenuButtonsItemGroupFar	proc	far
	call	GetMenuButtonsItemGroup
	ret
GetMenuButtonsItemGroupFar	endp

GetMenuButtonsItemGroup	proc	near
	uses	di
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass		>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLBI_genChunk	;get popup window interaction
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk ; si = gen item group

	; Make sure we got the item group.
	;
EC <	push	es, di							>
EC <	mov	di, segment OLItemGroupClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLItemGroupClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR_CANT_FIND_SELECTION_BOX_ITEM_GROUP	>
EC <	pop	es, di							>


	.leave
	ret
GetMenuButtonsItemGroup	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfArrowsDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For non-wrapping selection boxes, we need to check if
		any of the arrows in the selection box should be 
		disabled.

CALLED BY:	SelectionBoxMouse

PASS:		*ds:si	= menu button
		ds:di	= menu button instance

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		if(non-wrapping selection box)
		  get current item in list
		  get first & last item in list	
		  if(current item = first)
		    previous arrow box disabled
		  else
		    previous arrow box enabled
		  if(current item = last)
		    next arrow box disabled
		  else
		    next arrow box enabled

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
CheckIfArrowsDisabledFar	proc	Far
	call	CheckIfArrowsDisabled
	ret
CheckIfArrowsDisabledFar	endp
	
CheckIfArrowsDisabled	proc	near
	uses	ax,bx,cx,dx
	.enter

	; If it's a wrapping selection box, we don't need to worry
	; about disabling the arrow boxes.
	;
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_NON_WRAPPING_SELECTION_BOX
	jz	exit
	
	; Get current selection.  Also get the first & last items
	; in the list.  
	;
	call	GetCurrentFirstAndLastItems	; ax = current, cx = first, 
						; dx = last
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; deref menu button

	; Assume that the current item is the first item in the list,
	; so disable the previous arrow box.  If not equal enable the
	; previous arrow box.
	;
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_PREV_DISABLED
	cmp	cx, ax
	je	checkLastItem
	ANDNF	ds:[di].OLMBI_odieFlags, not (mask OLMBOF_SELECTION_BOX_PREV_DISABLED)

	; Now check if the current item is the last item.
	;
checkLastItem:
	ORNF	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_NEXT_DISABLED
	cmp	dx, ax
	je	exit
	ANDNF	ds:[di].OLMBI_odieFlags, not (mask OLMBOF_SELECTION_BOX_NEXT_DISABLED)
exit:
	.leave
	ret
CheckIfArrowsDisabled	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentFirstAndLastItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the identifiers for the current, first,
		and last items in the selection box.

CALLED BY:	CheckIfArrowsDisabled

PASS:		*ds:si	= menu button

RETURN:		ax	= current item identifier
		cx	= first item identifier
		dx	= last item identifier

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
GetCurrentFirstAndLastItems	proc	near
	uses	bx,si,di,bp
	.enter

	call	GetMenuButtonsItemGroup		; *ds:si = item group

	mov	ax, MSG_GEN_ITEM_GROUP_SCAN_ITEMS
	mov	cl, mask GSIF_FROM_START or\
		    mask GSIF_FORWARD or\
		    mask GSIF_EXISTING_ITEMS_ONLY
	clr	bp				; scan amount
	call	ObjCallInstanceNoLock		; ax = first, bp = last
EC  <	ERROR_NC	OL_ERROR_SELECTION_BOX			>
	push	ax, bp				

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; ax = current item identifier
EC  <	ERROR_C	OL_ERROR_SELECTION_BOX				>
	
	pop	cx, dx
exit:
	.leave
	ret
GetCurrentFirstAndLastItems	endp
endif		; if SELECTION_BOX


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonHandleMenuFunction

DESCRIPTION:	This procedure is called when the user presses the
		"MENU" button on the mouse, or drags the mouse over this
		menu button.

CALLED BY:	OLMenuButtonHandleEvent

PASS:		*ds:si	= instance data for object
		ds:di	= instance data
		cx, dx	- ptr position
		bp (high) = OLMenuButtonFunctionsActive
		bp (low)  = UIButtonInfo

RETURN:		ax = MRF_PROCESSED if menu button has handled event
		   = MRF_REPLAY if menu button has handled event by releasing
			mouse grab, and so event must be sent to implied
			grab now.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonHandleMenuFunction	proc	near

	;make sure that our state flags are consistent

EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING >
EC <	ERROR_Z	OL_ERROR						   >
EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_DEFAULT_FUNCTION_PENDING >
EC <	ERROR_NZ OL_ERROR						   >

	test	bp, (mask OLMBFA_IN_BOUNDS) shl 8 ;inside button?
	LONG	jz notInBounds		  ;skip if not...

inBounds: ;is in bounds. test if MENU function button is pressed
	test	bp, (mask OLMBFA_MENU) shl 8
	jz	inBoundsNotPressed	;skip if not...

inBoundsIsPressed:
	;if menu button does not have mouse grab, then this is a
	;START_SELECT type of event, or MSG_META_PTR with the button pressed.
	;Initialize the CLOSING flag correctly, and grab the mouse.
 
	push	cx, bp			;save mouse x position, mouse flags
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jnz	alreadyHadMouseGrab	;skip if already have mouse grab...

	;important: set this flag before we grab the GADGET exclusive,
	;because grabbing the gadget may cause our menu to try to close;
	;it will look at the OLBSS_HAS_MOUSE_GRAB flag in this object to
	;see if it should ignore the loss of the gadget.
	;See OLMenuWinLostGadgetExcl.

	ORNF	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
						;set bit so we release later

	;Since we're about to grab the mouse, let's first force a release of
	;the gadget exclusive, from whoever has it, before we go redrawing
	;ourselves.  This will ensure that we don't collide with the save-under
	;area of a menu already on-screen	--Doug

	call	OLMenuButtonTakeGadgetExcl	;grab GADGET EXCLUSIVE

	;if we are just starting to interact with this menu button,
	;save the present BORDERED and DEPRESSED flags, so can restore later.
	;(do this before we grab the mouse.)
	;Quick hack: we must turn off the OLBSS_HAS_MOUSE_GRAB flag
	;temporarily, so that OLMenuButtonSaveBorderedAndDepressedStatusIf-
	;StartingInteraction will still save our bordered state)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_HAS_MOUSE_GRAB)

	call	OLMenuButtonEnsureIsDrawnDepressedNOW

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB

	;request the mouse grab, and grab the GADGET exclusive.
	;Also updates the CLOSING flag.

					;pass ds:di = instance data
	call	OLMenuButtonUpdateClosingFlag

	;first, take FOCUS exclusive for UI window. This, and/or the 
	;taking of the GADGET exclusive which is done below, will force
	;other buttons to redraw properly. Note: cannot rely upon getting
	;the focus, since we might be inside a pinned menu...
	;(do this after OLBSS_HAS_MOUSE_GRAB is set)
	;IMPORTANT: if our menu is opened, do NOT grab the focus, since this
	;would grab the focus away from our menu, and as the user drags the
	;mouse back into the menu, the menu would not grab the focus back,
	;and items inside of it (such as GenItemGroups) would not interact.

	push	cx, dx
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jnz	15$			;skip if menu already opened...

	; Grab focus for the menu button, passing correct flags
	;
	call	OLMenuButtonGrabFocusExcl

15$:
	call	VisGrabMouse			;Grab the mouse for this button
	pop	cx, dx
	jmp	short afterGrab

alreadyHadMouseGrab:
	;we already had the mouse grab: must be dragging on this button.
	;Let's just make sure our image is correct.

	call	OLMenuButtonEnsureIsDrawnDepressedNOW

afterGrab:
	pop	cx, bp			;restore mouse x position, mouse flags
					; (do not use OLButtonClass version) ?

if	_CASCADING_MENUS
	call	EnsureOpenAndCascade
else
	; Be sure that bp contains mouse flags

	call	OLMenuButtonEnsureMenuOpen
					;open menu if it is not already
endif

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
					;return, keeping MENU_FUNCTION
	ret				;pending...

inBoundsNotPressed:
	;the mouse pointer has been released on this menu button.
	;First: release the mouse grab if we had it.

	call	OLButtonReleaseMouseGrab
	jc	inBoundsNotPressedDidReleaseMouse
					;skip if did have mouse grab...

returnProcessed:
	mov	ax, mask MRF_PROCESSED	;essentially, ignore this event.
	ret				;the mouse is just sliding over button

inBoundsNotPressedDidReleaseMouse:
	;mouse button released on the menu button: if the CLOSING flag is
	;FALSE, it means we want to enter stay-up mode.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_CLOSING_MENU
	jz	inBoundsNotPressedEnterStayUpMode ;skip if not...

	;we are closing the menu

if	 _CASCADING_MENUS
	; This menu is no longer cascading.. inform the menu.  The menu will
	; take care of closing submenus.
	
	; Only send the message of this button is inside of a menu and thus
	; this is a submenu.
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	dontInformMenu
	
	; This menu is now the "top"-most menu, so take the grabs and the
	; gadget exclusive.  But, we are no longer cascading.
	mov	cl, mask OMWCMO_START_GRAB
	call	OLButtonSendCascadeModeToMenu
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;may have moved
	
dontInformMenu:
endif	;_CASCADING_MENUS

	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_CLOSING_MENU)

	;If we are using cascading menus, the previos call to
	;OLButtonSendCascadeModeToMenu will cause the submenus to be closed.
	;Therefore, this call is not necessary.
if	 not _CASCADING_MENUS
	call	OLMenuButtonCloseMenu	;close menu if not pinned or in stay-
					;up-mode, reset and redraw menu button
endif	;not _CASCADING_MENUS

	;let's release the FOCUS exclusive, in case we had it. This will allow
	;the focus to be restored to the previous owner, if no menu opens soon.
	;(must do this after POPUP_OPEN flag is reset, so button will redraw.)

if	PRESERVE_FOCUS_IF_PEN_ONLY
	call	OpenCheckIfMenusTakeFocus
	jnc	20$
	call	OLMenuButtonLostFocusExcl
	jmp	short 22$
20$:
	call	MetaReleaseFocusExclLow
22$:
else
	call	MetaReleaseFocusExclLow
endif

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	jmp	short resetMenuFunctionAndReturnAX

inBoundsNotPressedEnterStayUpMode:
	;in bounds, not pressed, not closing: see if menu is open.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jnz	inBoundsNotPressedEnterStayUpMode2 ;skip if already opened...

	;menu is not open: mouse must not be over right side of button.
	;Make sure that menu button is drawn as depressed (do NOT use
	;OLMenuButtonEnsureIsDrawnDepressedNOW, since MOUSE_GRAB flag is clear),
	;and force the menu open now.

	call	OLMenuButtonSetBorderedAndOrDepressed
	call	OLButtonDrawNOWIfNewState ;redraw immediately if necessary
					  ;(might cause flash in CUA or OL)
					  ;...so move below the draw code below)

	mov	cx, 32767		;pass largest x position for mouse,
					;to force menu open (signed #)
	
	mov	bp, mask BI_PRESS	;make sure it thinks it was a button
					;press
	call	OLMenuButtonEnsureMenuOpen
					;open menu if it is not already
					
if	 _CASCADING_MENUS
	; Send notice to menu that the submenu is opened.
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; may have been moved by open
	
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	notInAMenu
	
	; Flags passed in cl: Don't take the grabs, but enable cascading
	mov	cl, mask OMWCMO_CASCADE
	mov	dx, ds:[LMBH_handle]		; ^ldx:bp = GenInteraction
	mov	bp, ds:[di].OLBI_genChunk	; (menu) for this button's
						; submenu
	call	OLButtonSendCascadeModeToMenu
notInAMenu:
endif	;_CASCADING_MENUS
			    

inBoundsNotPressedEnterStayUpMode2:
	;Menu is open --> enter stay-up mode (Motif: no redraw required)

NOT_MO<	call	OLMenuButtonEnsureIsDrawnHollow				>

	;place menu in stay-up-mode, passing CX = TRUE so that the
	;gadget exclusive is forcibly taken, so any other menus close.

	mov	cx, TRUE		;close other menus
	mov	ax, MSG_MO_MW_ENTER_STAY_UP_MODE
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	jmp	short resetMenuFunctionAndReturnAX

notInBounds:
	;the mouse pointer is not inside the bounds of this menu button.
	;Restore the menu button to its original state, but do not
	;close the menu. The menu will close itself, or the Gadget Exclusive
	;will force it to close. (Motif: no redraw required)

	call	OLButtonReleaseMouseGrab ;release mouse grab if we had it
	;skip if did not have mouse grab...
if	 _CASCADING_MENUS
	LONG	jnc returnProcessed
else	;_CASCADING_MENUS is FALSE
	jnc	returnProcessed
endif	;_CASCADING_MENUS

	;In case this is a top-level menu button, DO NOT release the FOCUS
	;exclusive, since the focus will be restored to the previous owner
	;(some gadget in the primary), which will grab the gadget exclusive,
	;and close this menu.

	;However, if this is a sub-menu button,
	;send a query upwards so that our menu grabs the focus window exclusive
	;back from our menu which is closing.

	call	OpenCheckIfMenusTakeFocus
	jnc	30$
	mov	cx, SVQT_GRAB_FOCUS_EXCL_FOR_MENU
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
30$:
	;reset the button visually

NOT_MO<	call	OLMenuButtonEnsureIsDrawnHollow				>

	mov	ax, mask MRF_REPLAY	;replay this event, since we had the
					;mouse grab.

resetMenuFunctionAndReturnAX:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_MENU_FUNCTION_PENDING)
	ret
OLMenuButtonHandleMenuFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureOpenAndCascade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call OLMenuButtonEnsureMenuOpen and
		OLButtonSendCascadeModeToMenu

CALLED BY:	OLMenuButtonHandleMenuFunction
		OLMenuButtonGenActivate
PASS:		*ds:si = OLMenuButton
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
EnsureOpenAndCascade	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLMBI_specState
	push	ax

	; Be sure that bp contains mouse flags
	call	OLMenuButtonEnsureMenuOpen
					;open menu if it is not already
					
	pop	bx			;old OLMBI_specState (in bl)
					
	; Here we make sure that if the menu button's popup was opened that
	; we inform the menu that we are now in CASCADE mode.
	; We check to see if OLMBSS_POPUP_OPEN changed.  If it changed, then
	; the submenu was opened.  (The above routine will never close the
	; menu.)  If this was the case, send up a message.
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	didntOpenMenu			; not in a menu, skip..
	
	xor	bl, ds:[di].OLMBI_specState
	test	bl, mask OLMBSS_POPUP_OPEN
	jz	didntOpenMenu			; bit didn't change, skip..

	; Flags passed in cl: Cascading, but don't start grab.
	mov	cl, mask OMWCMO_CASCADE
	mov	dx, ds:[LMBH_handle]		; ^ldx:bp = GenInteraction
	mov	bp, ds:[di].OLBI_genChunk	; (menu) for this button's
						; submenu
	call	OLButtonSendCascadeModeToMenu
	
didntOpenMenu:
	ret
EnsureOpenAndCascade	endp
endif	;_CASCADING_MENUS


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonHandleDefaultFunction

DESCRIPTION:	This procedure is called when the user presses the
		"DEFAULT" button on the mouse, or drags the mouse over this
		menu button.

CALLED BY:	OLMenuButtonHandleEvent

PASS:		*ds:si	= instance data for object
		ds:di	= instance data
		cx, dx	- ptr position
		bp (high) = OLMenuButtonFunctionsActive
		bp (low)  = UIButtonInfo

RETURN:		ax = MRF_PROCESSED if menu button has handled event
		   = MRF_REPLAY if menu button has handled event by releasing
			mouse grab, and so event must be sent to implied
			grab now.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonHandleDefaultFunction	proc	near

	;make sure that our state flags are consistent
EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_DEFAULT_FUNCTION_PENDING >
EC <	ERROR_Z OL_ERROR						   >
EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING >
EC <	ERROR_NZ OL_ERROR						   >

	test	bp, (mask OLMBFA_IN_BOUNDS) shl 8 ;inside button?
	jz	notInBounds			  ;skip if not...

inBounds: ;is in bounds. test if DEFAULT function button is pressed
	test	bp, (mask OLMBFA_DEFAULT) shl 8
	jz	inBoundsNotPressed	;skip if not...

inBoundsIsPressed:
	;if menu button does not have mouse grab, then this is a
	;START_SELECT type of event, or MSG_META_PTR with the button pressed.
	;Initialize the CLOSING flag correctly, and grab the mouse.

	call	OLMenuButtonEnsureHaveDefaultMoniker
					;grab default moniker from menu,
					;changing button status if necessary

	call	OLMenuButtonEnsureIsDrawnDepressedNOW
				;draw as BORDERED and DEPRESSED if not already

	call	OLButtonEnsureMouseGrab	;grab mouse if do not already have it

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
					;Say processed if ptr in bounds
	ret

inBoundsNotPressed:
	;the mouse pointer has been released on this menu button

	call	OLButtonReleaseMouseGrab
					;release mouse grab if we have it
	call	OLMenuButtonEnsureReleaseDefaultMoniker
					;restore our original moniker
	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

	mov	ax, MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
					;Say processed if ptr in bounds
	jmp	short resetDefaultFunctionAndReturnAX

notInBounds:
	;the mouse pointer is not inside the bounds of this menu button.
	;Restore the menu button to its original state, but do not
	;close the menu. The menu will close itself, or the Gadget Exclusive
	;will force it to close.

	call	OLButtonReleaseMouseGrab
					;release mouse grab if we have it
	call	OLMenuButtonEnsureReleaseDefaultMoniker
					;restore our original moniker
	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

	mov	ax, mask MRF_REPLAY	;replay this event, since we had the
					;mouse grab.

resetDefaultFunctionAndReturnAX:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLMBI_specState, \
				not (mask OLMBSS_DEFAULT_FUNCTION_PENDING)
	ret
OLMenuButtonHandleDefaultFunction	endp

OLMenuButtonTakeGadgetExcl	proc	far	;grab GADGET EXCLUSIVE
	;set a flag indicating that unless a SVQT_REMOTE_GRAB_GADGET_EXCL
	;is passed through this button, we want to close our menu when
	;we lose the gadget exclusive.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLMBI_specState, \
				mask OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;grab GADGET EXCLUSIVE
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL	;so other menus close up
	GOTO	VisCallParent			;does not trash di
OLMenuButtonTakeGadgetExcl	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonUpdateClosingFlag

DESCRIPTION:	This procedure updates a state flag which is used to
		implement "Stay-up mode" in menu buttons.

CALLED BY:	OLMenuButtonEnsureMouseGrab

PASS:		*ds:si	= instance data for object
		ds:di	= instance data for object

RETURN:		ds, si, di, cx, dx, bp = same

DESTROYED:	

PSEUDO CODE/STRATEGY:
	set CLOSING = FALSE
	if menu is currently opened
		set CLOSING = TRUE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonUpdateClosingFlag	proc	near
	;assume we are opening the menu for the first time, reset flag.

	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_CLOSING_MENU)

	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	10$			;skip if menu is closed...

	;We are opening the menu, but it is already open (in stay up mode)
	;Set the CLOSING flag so that when they release the mouse button,
	;the menu will close.

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_CLOSING_MENU

10$:
	ret
OLMenuButtonUpdateClosingFlag	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonEnsureIsDrawnHollow

DESCRIPTION:	This CUA-specific procedure is called when a top-level menu
		enters stay-up mode. It makes sure that this menu button is
		drawn as bordered and not depressed.

CALLED BY:	OLMenuButtonHandleMenuFunction

PASS:		*ds:si	= instance data for object

RETURN:		ds, si, cx, dx, bp = same

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

if _CUA_STYLE and (not _MOTIF) and (not _PM)	;-------------------------------

OLMenuButtonEnsureIsDrawnHollow	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	done			;menu button is inside menu: this means
					;that it opens a sub-menu, so we have
					;no style guide to follow! Let's do
					;whatever we want. Skip to end...

inMenuBar:
	;menu button is in menu bar or is system menu: turn off depressed,
	;turn on bordered.

	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED)
	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	call	OLButtonDrawNOWIfNewState ;redraw immediately if necessary

done:
	ret
OLMenuButtonEnsureIsDrawnHollow	endp

endif		;--------------------------------------------------------------

CommonFunctional	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonGenActivate - MSG_GEN_ACTIVATE

DESCRIPTION:	This procedure is called in the following situations:
			1) the space bar (SELECT key) is released while this
			   object is cursored.
			2) the UP or DOWN arrow keys are pressed while this
			   object is cursored.
			3) the keyboard mnemonic shortcut for this object is
			   received, and the window sends MSG_GEN_ACTIVATE
			   to this object.
			4) the user navigates to this item using the arrow
			   keys, coming from a menu button which has an open
			   menu.
			5) somebody sends MSG_GEN_ACTIVATE to this object.
			6) the RIGHT arrow is pressed while the focus is on
			   this button, which opens a sub-menu.

		In all cases, we open the menu and place it in stay-up-mode.
		(Note that if this menu button was already navigated to,
		then it is already drawn as depressed, and its previous border
		state has been saved.)

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	sean	6/96		Support for Selection Boxes (Odie)

------------------------------------------------------------------------------@

OLMenuButtonGenActivate	method	OLMenuButtonClass, MSG_GEN_ACTIVATE

if _JEDIMOTIF
	;
	; if we are a App Menu button, make sure the App menu points to us
	;
	call	EnsureAppMenuButton
endif

	;see if a menu or default function is already in progress

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING \
					or mask OLMBSS_DEFAULT_FUNCTION_PENDING
	jnz	done			;skip to end if so...

	;no menu function is in progress. If this button is disabled,
	;ignore new events.

	call	OpenButtonCheckIfFullyEnabled	
	jnc	done			;skip to end if not fully enabled
	
	; if no VA_REALIZED, don't activate

	mov	di, ds:[si]		;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	done			;not realized, done

	; For Odie, selection boxes don't open menus, so we ignore
	; the activate.
	;
if	SELECTION_BOX
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX
	jnz	done
endif

	;start a menu function, placing menu in stay-up-mode

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_MENU_FUNCTION_PENDING

	;now save state and redraw button according to the specific UI

MO    <	call	OLMenuButtonEnsureIsDrawnDepressedNOW			>
PMAN  <	call	OLMenuButtonEnsureIsDrawnDepressedNOW			>
NOT_MO<	call	OLMenuButtonEnsureIsDrawnHollow				>

	mov	cx, 32767		;pass largest x position for mouse,
					;to force menu open (signed #)
if	_CASCADING_MENUS
	call	EnsureOpenAndCascade
else
	call	OLMenuButtonEnsureMenuOpen
					;open menu if it is not already
endif

	;place menu in stay-up-mode, passing CX = FALSE so that higher-level
	;menus are allowed to remain in stay-up-mode.  (Changed 10/15/92 cbh
	;to pass CX = TRUE if the menu button is not in a menu, and therefore
	;there are no higher level menus.  Menu buttons need to receive a
	;lost gadget exclusive after a gen activate to work consistently with
	;other things (in particular, it needs to clear the MENU_FUNCTION_-
	;PENDING flag so that navigating between menus continues to work
	;properly.))

if _JEDIMOTIF
	mov	cx, TRUE		;no reason to not always grab in JEDI
else
	mov	cx, FALSE		;in menu, bringing up

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	10$

	mov	cx, TRUE		;menu bar button, allow gadget grabs
10$:
endif
	mov	ax, MSG_MO_MW_ENTER_STAY_UP_MODE
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.

done:
	ret
OLMenuButtonGenActivate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuButtonToggleActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle open/close state of menu

CALLED BY:	MSG_OL_MENU_BUTTON_TOGGLE_ACTIVATE
PASS:		*ds:si	= OLMenuButtonClass object
		ds:di	= OLMenuButtonClass instance data
		ds:bx	= OLMenuButtonClass object (same as *ds:si)
		es 	= segment of OLMenuButtonClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _JEDIMOTIF
OLMenuButtonToggleActivate	method dynamic OLMenuButtonClass, 
					MSG_OL_MENU_BUTTON_TOGGLE_ACTIVATE
	mov	ax, MSG_GEN_ACTIVATE		; assume need to open
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	haveAction			; yes, open it
	mov	ax, MSG_OL_MENU_BUTTON_CLOSE_MENU	; else, close it
haveAction:
	GOTO	ObjCallInstanceNoLock
OLMenuButtonToggleActivate	endm
endif

KbdNavigation	ends


CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonEnsureMenuOpen

DESCRIPTION:	Open the associated window, if not opened already.

CALLED BY:	OLMenuButtonHandleEvent, OLMenuButtonGenActivate

PASS:		*ds:si	= instance data for object
		cx, dx	= ptr position (cx = 32767 if keyboard navigation)
		bp	= [ UIFunctionsActive | ButtonInfo ]

RETURN:		ds, si = same

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		initial version
	Eric	6/90		updated for Motif
	Chris	4/91		Updated for new graphics, bounds conventions
	Joon	8/92		PM extensions

------------------------------------------------------------------------------@

OLMenuButtonEnsureMenuOpen	proc	far
	class	OLMenuButtonClass

	;see if menu already up

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	LONG	jnz	done			;skip if so...

	;
	; First close any sibling menus
	;
	
    	; Cascading menus: in general, they do not need to have the siblings
	; closed by sending a message to all siblings - it will be handled
	; by the CASCADE_MODE message handler in the menu window code.  The
	; ONLY exception is when the user click-drags open some (> 1) menus
	; and, with the mouse button still down, exits the menu window and
	; goes back up to the menu bar to bring down another menu.  At this
	; point, only the first menu opened has the gadget exclusive and
	; when it loses the gadget exclusive, it will not close because it
	; is cascading (it has a submenu open).  Bummer.  So, we check for
	; that case here and force them all to be closed with the heinous 
	; MSG_MO_MW_CLOSE_ALL_MENUS_IN_CASCADE (by 
	; MSG_OL_MENU_BUTTON_CLOSE_MENU).
	
if	 _CASCADING_MENUS
	; check to see if this is a button in the menu bar.. we only care
	; about that case.
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jz	afterCloseSiblings
	
	; See if it was a button press.. we only care about click-dragging.
	test	bp, mask BI_PRESS
	jnz	afterCloseSiblings
endif	;_CASCADING_MENUS

	; Okay, send the message to all siblings.
	; Note that in cascading menus, _OL_MENU_BUTTON_CLOSE_MENU sends
	; MSG_MO_MW_CLOSE_ALL_MENUS_IN_CASCADE to the menu rather than just
	; an INTERACTION_COMPLETE message.
	
	push	cx, bp
	push	si
	mov	ax, MSG_OL_MENU_BUTTON_CLOSE_MENU
	mov	bx, segment OLMenuButtonClass
	mov	si, offset OLMenuButtonClass
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	mov	cx, di			; cx = event
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	call	VisCallParent
	pop	cx, bp

afterCloseSiblings::			;conditional: _CASCADING_MENUS

	mov	dx, cx			;dx = X position of mouse, in window
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cl, ds:[di].OLMBI_popupType	;set cl = OLWinType

	;Check some specific UI requirements on where the mouse pointer
	;should be.

if (_CUA or _MOTIF) and (not _JEDIMOTIF) and (not _ODIE)
	;
	; OpenLook, Motif: only activate menu if mouse pointer is over 
	; right side of menu button.
	;
OLS <	cmp	cl, OLWT_SUBMENU					>
CUAS <	cmp	cl, MOWT_SUBMENU					>
	jne	10$			;skip if does not open sub-menu...

	mov	bx, ds:[di].VI_bounds.R_right
	sub	bx, OL_MARK_WIDTH + BUTTON_INSET_X
	sub	bx, OL_MARK_WIDTH + BUTTON_INSET_X
	cmp	dx, bx
   LONG	jl	done			;skip if left of mark...
10$:
endif ; (_CUA or _MOTIF or _OL_STYLE) and (not _JEDIMOTIF) and (not _ODIE)

if 0	; JEDI submenus should open anywhere
if _JEDIMOTIF	;--------------------------------------------------------------
	cmp	cl, MOWT_SUBMENU
	jne	10$

	mov	bx, ds:[di].VI_bounds.R_right
	sub	bx, ds:[di].VI_bounds.R_left		; bx = width
	shr	bx					; bx = width / 2
	add	bx, ds:[di].VI_bounds.R_left		; bx = middle
	cmp	dx, bx
	jg	done			; skip if right of middle...
10$:
endif	;----------------------------------------------------------------------
endif

if _PM	;----------------------------------------------------------------------
	cmp	cl, MOWT_SUBMENU
	jne	10$			;skip if does not open sub-menu...

	;
	; If the submenu is not infrequently used, then activate the submenu.
	;
	push	di
	mov	di, ds:[di].OLBI_genChunk	;get gen chunk of button
	mov	di, ds:[di]			; which is the sub-menu
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMWI_specState, mask OMWSS_INFREQUENT_USAGE
	pop	di
	jz	10$

	; else: only activate menu if mouse pointer is over the right menu mark
	mov	bx, ds:[di].VI_bounds.R_right
	sub	bx, OL_MARK_WIDTH + BUTTON_INSET_X
	cmp	dx, bx
	jl	done			;skip if left of mark...
10$:
endif	; if _PM --------------------------------------------------------------


	;set flag indicating that the menu is open

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN

if _ODIE	;=============================================================

	; we need to determine whether this menu is a stand-alone menu or
	; under the menubar.

	call	CheckIfMenuButtonUnderMenuBar
	jnc	notMenuBar

	; ODIE has these rules for menus that are related to the menubar:
	; - main menus (menubar) opens centered at the bottom of the screen.
	; - submenus opens centered above the initiating menu botton.

	push	si
	mov	si, ds:[di].OLBI_genChunk
	mov	ax, HINT_MENU_BAR
	call	ObjVarFindData
	pop	si
	jnc	subMenu

if MENU_BAR_IS_A_MENU
	;
	; get menu center point
	;
	push	di, bp					; save instance
	push	si					; save menu button
	mov	bx, segment OLMenuedWinClass
	mov	si, offset OLMenuedWinClass
	mov	ax, MSG_OL_MENUED_WIN_GET_MENU_CENTER
	mov	di, mask MF_RECORD
	call	ObjMessage				; di = event
	pop	si					; *ds:si = menu button
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock			; cx = menu center
	pop	di, bp					; restore instance
	mov	ax, cx					; ax = menu center
	call	OpenGetScreenDimensions			; cx, dx = screen dim
	sar	cx, 1
	tst	ax					; any menu center?
	jz	haveCenter				; no, use screen center
	mov	cx, ax					; yes, use menu center
haveCenter:
else
	call	OpenGetScreenDimensions
	sar	cx, 1
endif
	jmp	activate

subMenu:
	mov	ax, ds:[di].VI_bounds.R_right
	add	ax, ds:[di].VI_bounds.R_left
	sar	ax, 1
	mov	bx, ds:[di].VI_bounds.R_top
	sub	bx, BUBBLE_WEDGE_SIZE+1
	jmp	havePosition

notMenuBar:
endif	; _ODIE	;==============================================================
	
	;now assume is a top-level menu, and get coordinates for it

if _JEDIMOTIF	;=============================================================
	;
	; skip all of these shenanigans for JEDI
	;
	; JEDI has these rules:
	; - main menus open with left side lining up with button left and
	;	bottom lining up with button top
	; - submenus open with right side lining up with button left,
	;	with 2 pixel overlap and top lining up with button top but
	;	2 pixels up
;	; - title bar menus open with left side lining up with button left
;	;	and top of menu lining up with button bottom
;correction - 4/21/95
	; - title bar menus are right justified (on assumption that there will
	;	be more menus in title bar right than title bar left)
	; - popup lists open with left side lining up with button left and
	; 	bottom lining up with button top (same as main menus)
	;
	; we only pass the reference point here, there is code in
	; OLMenuWinActivate that justifies relative to the passed position
	;
	;	ds:di = OLMenuButton
	;
	mov	ax, ds:[di].VI_bounds.R_left	; main menu and popup lists
	mov	bx, ds:[di].VI_bounds.R_top
	cmp	cl, MOWT_SUBMENU
	jne	notSubmenu
	inc	ax				; overlap at left
	inc	ax
	dec	bx				; 2 pixels up
	dec	bx
	jmp	havePosition			; submenus can't be title bar
notSubmenu:
	push	ax, bx
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData			; carry set if in title bar
	pop	ax, bx
	jnc	havePosition			; not in title bar
;correction - 4/21/95
	mov	ax, ds:[di].VI_bounds.R_right
	inc	ax				; small adj for border
	inc	ax
	mov	bx, ds:[di].VI_bounds.R_bottom	; pass button bottom

else	;=====================================================================

	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_bottom

if _ODIE
	;
	; open sys menus (event menu, express menu) right justified
	;
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jz	notSysMenu
	mov	ax, ds:[di].VI_bounds.R_right
notSysMenu:
endif

if	DRAW_SHADOWS_ON_BW_GADGETS

	;Overlap button if there's a shadow here.

	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
					mask OLBSS_IN_MENU_BAR
	jnz	12$
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	12$
	dec	bx			;overlap menu button
12$:
endif

CUA <	dec	bx			;overlap menu button		>

OLS <	cmp	cl, OLWT_SUBMENU					>
CUAS <	cmp	cl, MOWT_SUBMENU					>
	je	positionToRight		;send off right side if submenu...

	;
	; If we're bringing up a horizontal popup, position to the right.
	; (Changed back from opening all children of verticals this way.
	; -cbh 2/19/93)
	;
	test	ds:[di].OLMBI_specState, mask OLMBSS_ORIENT_POPUP_HORIZONTALLY
	jnz	positionToRight		;popup horizontal, go off right side	

	push	si, ax, bx		;check for popup hint  -cbh 2/19/93
	mov	si, ds:[di].OLBI_genChunk	
	mov	ax, HINT_POPS_UP_TO_RIGHT
	call	ObjVarFindData
	pop	si, ax, bx
	jnc	havePosition

positionToRight:
	push	si			;add vardata attribute -cbh 2/10/93
	push	cx
	mov	si, ds:[di].OLBI_genChunk	
	mov	ax, TEMP_POPUP_OPENING_TO_RIGHT
	mov	cx, 0			;no extra data
	call	ObjVarAddData
	pop	cx
	pop	si

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

if	 _SUBMENU_ALWAYS_OVERLAPS_PARENT
	; position the submenu to be _OVERLAPPING_MENU_LEFT_INSET pixel to
	; the right of the left edge of the parent menu.  Do not let this
	; position be past the right edge of the parent menu.
	
	mov	bx, ds:[di].VI_bounds.R_left
	add	bx, _OVERLAPPING_MENU_LEFT_INSET	; bx = left + inset
	mov	ax, ds:[di].VI_bounds.R_right		; ax = right
	
	; adjust for overlap on right edge
	inc	ax
if	 _THICK_MENU_BOXES
	inc	ax					; two pixel overlap
endif	;_THICK_MENU_BOXES

	cmp	ax, bx					; is right edge better?
	jl	setYPos	
	mov	ax, bx					; no, use left + inset

setYPos:
	mov	bx, ds:[di].VI_bounds.R_bottom
	
else	;_SUBMENU_ALWAYS_OVERLAPS_PARENT is FALSE

	;position just to the right of the menu button, overlapping a bit.
	;(OpenWinMoveResizeWin will re-position to keep on screen)

	mov	ax, ds:[di].VI_bounds.R_right
	mov	bx, ds:[di].VI_bounds.R_top

	;submenus actually overlap a bit.

OLS <	cmp	cl, OLWT_SUBMENU					>
CUAS <	cmp	cl, MOWT_SUBMENU					>
	jne	havePosition

if _PM	;----------------------------------------------------------------------
	inc	ax
	inc	bx
else	;----------------------------------------------------------------------

	;Changed to solve problems with pinning the submenu if you press on
	;the menu, then release on the submenu due to overlapping of the menus.
	;  -cbh 2/10/93

;CUAS <	sub	ax, BUTTON_INSET_X-1					    >
CUAS <	inc	ax							    >
endif	;----------------------------------------------------------------------

endif	;_SUBMENU_ALWAYS_OVERLAPS_PARENT

endif	;_JEDIMOTIF	;=====================================================

havePosition:
	call	VisQueryWindow		;get window we're on
	call	WinTransform	;get screen coords

	push	ax, si
	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov_tr	di, ax
	pop	ax, si
	call	WinUntransform	; and make parent-relative

	mov	cx, ax
	mov	dx, bx

activate::
	mov	ax, MSG_OL_POPUP_ACTIVATE	;bring up menu
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.
done:
	ret
OLMenuButtonEnsureMenuOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMenuUnderMenuBar	CheckIfMenuButtonUnderMenuBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this menubutton is under the menubar

CALLED BY:	OLMenuButtonEnsureMenuOpen
PASS:		*ds:si	= OLMenuButtonClass
RETURN:		carry set if under menu bar
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ODIE	;--------------------------------------------------------------

CheckIfMenuButtonUnderMenuBar	proc	far
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

	; First find the menubar object

	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, SGQT_FIND_MENU_BAR
	call	OLButtonCallGenPart	; ^lcx:dx = menubar
	jnc	done			; exit with carry clear if no menubar

	; Now, does this menubutton open the menubar?

	mov	bx, ds:[LMBH_handle]	; ^lbx:si = menubutton
	cmp	cx, bx
	jne	startSearch
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	dx, ds:[di].OLBI_genChunk
	stc				; assume found menu bar
	je	done

startSearch:
	; Search up the vis tree until we find the menubar or a non-menu window

searchLoop:
	push	cx, dx
	mov	ax, MSG_VIS_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	bxsi, cxdx		; ^lbx:si = parent
	pop	cx, dx			; ^lcx:dx = menu bar
	tst	bx
	jz	done			; exit with carry clear if no parent

	cmpdw	bxsi, cxdx
	stc				; assume found menu bar
	je	done			; exit with carry set if menu bar found

	call	ObjSwapLock
	push	bx

	segmov	es, <segment GenInteractionClass>, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jnc	unlock			; exit - not under menubar

	segmov	es, <segment OLMenuWinClass>, di
	mov	di, offset OLMenuWinClass
	call	ObjIsObjectInClass
	cmc
	jc	unlock			; continue search if not OLMenuWin

checkButton:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLPWI_button
	tst	si
	jz	unlock			; unlock with carry clear if no button

	stc				; carry set means continue searching
unlock:
	pop	bx
	call	ObjSwapUnlock
	jc	searchLoop		; continue seaching if carry set
done:
	.leave
	ret
CheckIfMenuButtonUnderMenuBar	endp

endif	; _ODIE ---------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuButtonCloseMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the associated menu, if not closed already, and
		not pinned, and not in stay-up-mode.
		NOTE: if cascading menus, then will send a message to close
		all menus in cascade.

CALLED BY:	OLMenuButtonHandleEvent

PASS:		ds:*si = handle of menu button object

RETURN:		ds, si = same
		carry set if was able to close menu, and redraw menu button

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLMenuButtonCloseMenu	method	OLMenuButtonClass, MSG_OL_MENU_BUTTON_CLOSE_MENU
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	90$				;skip if menu not up (cy=0)...

	; FIRST, bring down menu, so that if save-under is in effect, the
	; part of the menu which THIS button is on will be restored from
	; save-under, BEFORE we go re-drawing the button, which would nuke
	; the effect of the save-under for this menu.

	; If cascading menus, then tell all menus in the cascade to close.
	; Otherwise, dismiss menu if it is not pinned
if	 _CASCADING_MENUS
	mov	ax, MSG_MO_MW_CLOSE_ALL_MENUS_IN_CASCADE
else	;_CASCADING_MENUS is FALSE
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
endif	;_CASCADING_MENUS
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.

60$:	;reset OLButton and OLMenuButton state flags for this menu button

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_POPUP_OPEN)

	;draw as not depressed, and restore bordered state

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW
	stc				;return flag: was successful

90$:
	ret
OLMenuButtonCloseMenu	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonLostGadgetExclusive

DESCRIPTION:	This procedure is called when this menu button looses
		the Gadget Exclusive - some other UI object is now
		being used. If the menu which this menu button opens
		is not in stay-up mode, close it now.

PASS:		*ds:si	- OLButton object

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	sean	1/97		Selection box addition for
				repeat-press timer
	
------------------------------------------------------------------------------@
OLMenuButtonLostGadgetExcl	method	dynamic OLMenuButtonClass, \
						MSG_VIS_LOST_GADGET_EXCL

	; If we're a selection box, we want to stop the repeat-press
	; timer when we lose the gadget.  This is mostly defensive.
	;
if	SELECTION_BOX
	call	SelectionBoxLostGadget
endif

	;if a SVQT_REMOTE_GRAB_GADGET_EXCL has been passed through this
	;menu button after it has gained the gadget exclusive, then we do
	;NOT want to cause our menu to close. We know that we are losing the
	;gadget exclusive because our menu is grabbing it.

	test	ds:[di].OLMBI_specState, \
				mask OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL
if _ODIE
	;
	; for ODIE, we want title bar menu buttons (i.e. approximated as
	; not in menu or not in menu bar) to have transient invert effect
	; (i.e. not stay inverted when the menu opens)
	;
	jz	checkTransient
else
	jz	done			;skip to end if not...
endif

	;for cascading menus, check to see if the menu object for this
	;button is in cascade mode.  If so, then we should ignore losing the
	;gadget exclusive.
if	 _CASCADING_MENUS
	push	di
	mov	di, ds:[di].OLBI_genChunk
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	pop	di
	jnz	done
endif	;_CASCADING_MENUS
	
	ANDNF	ds:[di].OLMBI_specState, not \
				mask OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL
					;not necessary, but is cleaner	

	;HACK: since the Primary has a post-passive grab which is looking
	;for button releases, we may be loosing the Gadget Exclusive because
	;the primary has intercepted a button release, even though an other
	;button is still pressed, and we have the mouse grab.
	;If so, ignore this loss. ONLY IMPORTANT FOR >1 BUTTON UIs.

	;fool OLButtonLostGadgetExcl into thinking that this
	;is a regular button...

	ORNF	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
					;say it has mouse grab

	ANDNF	ds:[di].OLMBI_specState, not \
			(mask OLMBSS_MENU_FUNCTION_PENDING or \
			 mask OLMBSS_DEFAULT_FUNCTION_PENDING)

	;if these are cascading menus, then check to see if this menu button
	;is actually IN a menu.  If so, we do not want to close the menu
	;since other mechanisms will take care of that.  Otherwise, go ahead
	;and close the menu.
	
if	 _CASCADING_MENUS
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	resetButton
endif	;_CASCADING_MENUS

	call	OLMenuButtonCloseMenu	;close menu if not pinned or in stay-
					;up-mode, reset and redraw menu button
					;Will reset DEPRESSED and BORDERED flags

	jc	done			;skip if did close menu and redraw
					;menu button already...

resetButton:
	;reset button visually

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

done:
	call	OLButtonReleaseMouseGrab
	ret

if _ODIE
checkTransient:
	;
	; for ODIE, we want title bar menu buttons (i.e. approximated as
	; not in menu or not in menu bar) to have transient invert effect
	; (i.e. not stay inverted when the menu opens)
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR
	jnz	done			; in menu or menu bar, leave inverted
	jmp	short resetButton	; else, clear inversion
endif

OLMenuButtonLostGadgetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionBoxLostGadget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes care of selection box losing the gadget.

CALLED BY:	OLMenuButtonLostGadgetExcl

PASS:		*ds:si	= OLMenuButton object
		ds:di	= fptr to OLMenuButton instance data

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Turns off app timer for this button is one is set.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	1/17/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	SELECTION_BOX
SelectionBoxLostGadget	proc	near
	.enter

	; Is this a selection box.  If not leave.
	;
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX
	jz	exit

	; Clear the pending end select flag.  Clear the timer if there
	; is one pending.
	;
	call	SelectionBoxEndSelect
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; re-dereference object
exit:
	.leave
	ret
SelectionBoxLostGadget	endp
endif		; if SELECTION_BOX


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonVupQuery -- MSG_VIS_VUP_QUERY

DESCRIPTION:	We intercept this here so that we can reset the
		OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL flag if this is
		a SVQT_NOTIFY_MENU_BUTTON_AND_REMOTE_GRAB_GADGET_EXCL query.
		See the documentation on the _CLOSE_MENU_ON_LOST_GADGET_EXCL
		flag.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonVupQuery	method	dynamic OLMenuButtonClass, MSG_VIS_VUP_QUERY

	cmp	cx, SVQT_HAS_MENU_IN_STAY_UP_MODE
	jne	10$

	;if our menu is telling us that it is entering stay-up-mode.
	;Let's reset a flag, so that if we lose the gadget exclusive,
	;we WILL NOT close the menu.

	ANDNF	ds:[di].OLMBI_specState, not \
				mask OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL
	jmp	callSuper		;send onwards...

10$:
	cmp	cx, SVQT_NOTIFY_MENU_BUTTON_AND_REMOTE_GRAB_GADGET_EXCL
	jne	callSuper		;skip if cannot handle query...

	;if a SVQT_NOTIFY_MENU_BUTTON_AND_REMOTE_GRAB_GADGET_EXCL is being
	;passed through this menu button, then we do NOT want to close our
	;menu when we lose the gadget exclusive, because our menu initiated
	;this request for the gadget exclusive as the menu is opening.

	ANDNF	ds:[di].OLMBI_specState, not \
				mask OLMBSS_CLOSE_MENU_ON_LOST_GADGET_EXCL

	;now continue, sending the standard REMOTE_GRAB_GADGET_EXCL request.
	;(So higher-level menu buttons do not reset their CLOSE_MENU flags.)

	mov	cx, SVQT_REMOTE_GRAB_GADGET_EXCL

callSuper:
	mov	di, offset OLMenuButtonClass
	CallSuper	MSG_VIS_VUP_QUERY
	ret
OLMenuButtonVupQuery	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonEnsureHaveDefaultMoniker
					;grab default moniker from menu,
					;changing button status if necessary

DESCRIPTION:	This procedure grabs the default moniker from the menu window,
		saving this menu button's current moniker for later.

CALLED BY:	OLMenuButtonHandleDefaultFunction

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	1) We can't just change the OLBI_genChunk, because the default
	trigger may be in another ObjectBlock. It may also not be
	a generic object - it may have its own OLBI_genChunk pointer
	to the window which has the moniker.

	2) send method to window, it sends to default, default sends
	to its window if necessary, until we get to the object which
	has the moniker. This target object copies its moniker back
	to this ObjectBlock, and we have to place it into a generic object?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonEnsureHaveDefaultMoniker	proc	near
	ret
OLMenuButtonEnsureHaveDefaultMoniker	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonEnsureReleaseDefaultMoniker

DESCRIPTION:	This procedure restores the original moniker for this
		menu button.

CALLED BY:	OLMenuButtonHandleDefaultFunction

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonEnsureReleaseDefaultMoniker	proc	near
	ret
OLMenuButtonEnsureReleaseDefaultMoniker	endp

if _JEDIMOTIF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuButtonGainedMouseExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If App menu button, ensure the App menu points to us
		correctly

CALLED BY:	MSG_META_GAINED_MOUSE_EXCL
PASS:		*ds:si	= OLMenuButtonClass object
		ds:di	= OLMenuButtonClass instance data
		ds:bx	= OLMenuButtonClass object (same as *ds:si)
		es 	= segment of OLMenuButtonClass
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
OLMenuButtonGainedMouseExcl	method dynamic OLMenuButtonClass, 
					MSG_META_GAINED_MOUSE_EXCL
	call	EnsureAppMenuButton
	mov	di, offset OLMenuButtonClass
	call	ObjCallSuperNoLock
	ret
OLMenuButtonGainedMouseExcl	endm

EnsureAppMenuButton	proc	far
	uses	ax, cx, dx, bp
	.enter
	mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
	call	ObjVarFindData
	jnc	done
	mov	cx, si			; cx = this menu button
	mov	ax, MSG_OL_MENU_UPDATE_APP_MENU
	call	OLButtonCallGenPart
done:
	.leave
	ret
EnsureAppMenuButton	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonGainedDefaultExclusive -- MSG_META_GAINED_DEFAULT_EXCL

DESCRIPTION:	This method is sent by the parent window (see OpenWinGupQuery)
		when it decides that this GenTrigger should have the
		default exclusive.

PASS:		*ds:si	= instance data for object
		bp	= TRUE if this button should redraw itself,
			because it did not initiate this GAINED sequence, 
			and is not gaining any other exclusives that
			would cause it to redraw.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonGainedDefaultExclusive	method	OLMenuButtonClass, \
						MSG_META_GAINED_DEFAULT_EXCL

	;grab the Gadget exclusive for this button, so that other menus close

	push	ax, cx, dx, bp
	call	OLMenuButtonTakeGadgetExcl	;grab GADGET EXCLUSIVE
	pop	ax, cx, dx, bp

	;let OLButton class redraw this button

	CallSuper	MSG_META_GAINED_DEFAULT_EXCL
	ret

OLMenuButtonGainedDefaultExclusive	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonNavigate - MSG_SPEC_NAVIGATION_QUERY handler for
			OLMenuButtonClass

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
	OLMenuButtonClass handler:
	    1) Indicate that this button is menu-related.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonNavigate	method	OLMenuButtonClass, MSG_SPEC_NAVIGATION_QUERY
	;ERROR CHECKING is in OLButtonNavigateCommon

	;see if this button is enabled (generic state may come from window
	;which is opened by this button)

	push	cx, dx
	call	OLButtonGetGenAndSpecState ;returns dh = VI_attrs
					   ;bx = OLBI_specState

	;see if this button is enabled or not...

if _KBD_NAVIGATION and (not _DUI)	; no focus for _DUI
	clr	dh			   ;assume not taking focus

	; don't navigate if in a toolbox.  -cbh 1/22/93
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	5$			    ;in toolbox, don't take focus

	call	OpenCheckIfKeyboard
	jnc	5$			    ;no keyboard, can't take focus.
					    ;  -cbh 4/20/93

	call	OpenButtonCheckIfFullyEnabled
	jnc	5$
	mov	dh, mask NCF_IS_FOCUSABLE	   ;only look at this
5$:
else	;_CR_NAVIGATION might be true, so preserve navigation sequencing.
	clr	dh			   ;indicate this node is disabled.
endif

	;if this menu button has not been placed in a menu, indicate that it
	;is menu related  (Also if menu-down-mark is set.   Generally this is
	;only set for popup lists, but it also covers the case on non-menu-bar
	;menus.  We want these things to be tabbable. Babble.  -9/22/93 cbh)

	clr	bl
	test	bx, mask OLBSS_IN_MENU
	jnz	10$

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST 
	jnz	10$	
	test	ds:[di].OLBI_specState, mask OLBSS_MENU_DOWN_MARK
	jnz	10$

	ORNF	bl, mask NCF_IS_MENU_RELATED

10$:	
if _JEDIMOTIF
	;
	; don't allow navigation for menu buttons in menu bar
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jz	allowNav
	andnf	dh, not mask NCF_IS_FOCUSABLE
allowNav:
endif
					;default: not root-level node, is not
					;composite node, is not focusable,
					;is menu-related
	ORNF	bl, dh			;set NCF_IS_FOCUSABLE if VA_FULLY_ENBLD
	pop	cx, dx

	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and whether or not this object can
	;get the focus. This routine will check the passed NavigationFlags
	;and decide what to respond.

	mov	di, ds:[di].OLBI_genChunk
	call	VisNavigateCommon
	ret
OLMenuButtonNavigate	endm

CommonFunctional	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonKbdActivate -- 
		MSG_OL_BUTTON_KBD_ACTIVATE for OLMenuButtonClass
			(sent by the mnemonic code)
		MSG_OL_MENU_BUTTON_KBD_ACTIVATE for OLMenuButtonClass
			(sent when navigating from menu to menu)

DESCRIPTION:	Activates the menu button, and gives it the gadget exclusive.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_BUTTON_KBD_ACTIVATE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/90		Initial version

------------------------------------------------------------------------------@

OLMenuButtonKbdActivate	method OLMenuButtonClass, \
					MSG_OL_BUTTON_KBD_ACTIVATE,
					MSG_OL_MENU_BUTTON_KBD_ACTIVATE

	;Grab focus for button, so that it will properly be transferred to
	;window when it comes up.

	call	OLMenuButtonGrabFocusExcl

	;Take the gadget exclusive -- otherwise it never is done.

	call	OLMenuButtonTakeGadgetExcl	;grab GADGET EXCLUSIVE

	mov	ax, MSG_GEN_ACTIVATE		;now activate
	GOTO	ObjCallInstanceNoLock
OLMenuButtonKbdActivate	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonFupKbdChar -- MSG_META_FUP_KBD_CHAR handler

DESCRIPTION:	We intercept this for the case where ESCAPE was pressed
		in the menu or submenu below the menu that we open.
		We dismiss the menu, and then allow this event to continue
		up the focus hierarchy.

PASS:		*ds:si	= instance data for object
		ax = MSG_META_FUP_KBD_CHAR.
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OLMenuButtonFupKbdChar	method	dynamic OLMenuButtonClass, 
						MSG_META_FUP_KBD_CHAR,
						MSG_META_KBD_CHAR

	;we should not get events when the button is disabled...

EC <	call	OpenButtonCheckIfFullyEnabled				>
EC <	ERROR_NC	OL_ERROR					>

	;Don't handle state keys (shift, ctrl, etc).

if _JEDIMOTIF or SELECTION_BOX
	;
	; no reason to handle repeat presses any differently
	;
	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	LONG jnz	callSuper	; is state key
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	LONG jz	callSuper		; not press
else
	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT \
				      or mask CF_REPEAT_PRESS
LONG	jnz	callSuper		;quit if not character.

	test	dl, mask CF_FIRST_PRESS
LONG	jz	callSuper		;skip if not press event...
endif

	;see if the ESCAPE key is pressed (or passed from the menu which
	;this button opens)

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_ESCAPE			>
DBCS <	cmp	cx, C_SYS_ESCAPE					>
	je	handleEscape		;skip if so...

	;If we're opening a popup list, send the message to the list.
	;Only if we're dealing with certain navigation characters, though.
	;(Moved after escape check to allow popup lists to dismiss on escape.
	; -cbh 1/28/93)

	cmp	ax, MSG_META_KBD_CHAR	;don't want or need to send to popup 
	jne	fuppingChar		;  if a FUP, cause it originated there
					;  anyway, and causes infinite
					;  recursion.  -cbh 3/27/93
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	checkRightArrow

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di
	call	OLPopupListKbdChar	
	pop	di
	call	ThreadReturnStackSpace
	ret

fuppingChar:

	;	
	; In all systems, we'll send up and used (fupped) alt chars to be used
	; as mnemonics in the parent dialog.   In any case, we'll release
	; the popup.  10/13/93 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	checkRightArrow
	test	dh, mask SS_LALT or mask SS_RALT
	jz	checkRightArrow		
	call	DismissAndSendCharUpwards
	ret

checkRightArrow:

if _ODIE

	;
	; up arrow opens menu from menu bar
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLMBI_popupType, MOWT_MENU
	jne	callSuper		;skip if not menu...
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jz	callSuper
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_UP				>
DBCS <	cmp	cx, C_SYS_UP						>
	jne	callSuper

else	; (not _ODIE)

	;if this button opens a sub-menu, see if the RIGHT arrow is pressed
	;(means open the sub-menu)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLMBI_popupType, MOWT_SUBMENU
	jne	callSuper		;skip if not sub-menu...

if _JEDIMOTIF
	;
	; left arrow opens submenu in Jedi
	;
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_LEFT			>
DBCS <	cmp	cx, C_SYS_LEFT						>
else
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_RIGHT			>
DBCS <	cmp	cx, C_SYS_RIGHT						>
endif
	jne	callSuper		;skip if not...

endif	;_ODIE

translateRightArrowToOpenSubMenu:
	;RIGHT arrow key has been pressed: open our sub-menu.

	mov	ax, MSG_OL_MENU_BUTTON_KBD_ACTIVATE
	GOTO	ObjCallInstanceNoLock

handleEscape:

if _ODIE ; let superclass handle it

	jmp	callSuper

else	; (not _ODIE)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	dismissAndSendUp	;no popup open, allow sending to 
					;  superclass to close parent dialog.

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	dismissAndSendUp	;also if we're in a menu, close parent
					;  menu if any.
	;We're not in a menu, and our menu is open, dismiss but do not
	;send up to the parent object.

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	OLButtonCallGenPart	;forward method on to object designated
	ret				;as generic object for this button.

endif	;_ODIE

dismissAndSendUp:

	FALL_THRU	DismissAndSendCharUpwards

OLMenuButtonFupKbdChar	endm


DismissAndSendCharUpwards	proc	far
	;dismiss the menu, and allow this character to be forwarded
	;up the focus tree.

	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	OLButtonCallGenPart	;forward method on to object designated
					;as generic object for this button.
	pop	ax, cx, dx, bp

callSuper	label	near
	mov	di, offset OLMenuButtonClass
	GOTO	ObjCallSuperNoLock
DismissAndSendCharUpwards	endp

endif			;------------------------------------------------------






COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPopupListKbdChar

SYNOPSIS:	Handles keyboard chars for a popup list button.

CALLED BY:	OLMenuButtonFupKbdChar

PASS:		*ds:si -- button
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/22/92	Initial version
	sean	6/28/96		Selection box keyboard stuff (Odie)
	sean	9/12/96		vertical selection boxes ignore left/right keys
				horizontal selection boxes ignore up/down keys

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OLPopupListKbdChar	proc	far

if	SELECTION_BOX	; ----------------------------------------------------

	; In Odie, popup lists must be selection boxes.
	;
EC <	push	di						>
EC <	mov	di, ds:[si]					>
EC < 	add	di, ds:[di].Vis_offset				>
EC <	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX >
EC <	ERROR_Z		OL_ERROR_SELECTION_BOX			>
EC <	pop	di						>	

	; Did we receive an arrow key ?
	;
	push	ds, si, ax
	segmov	ds, cs
	mov	si, offset SelectionBoxKbdBindings
	lodsw				;set ax = # of entries in table
	call	FlowCheckKbdShortcut	;search shortcut table for match
	pop	ds, si, ax
	jc	arrowKey

	; Don't care about this key, so send it up the focus
	; hierarchy.
	;
ignoreKey:
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent

	; For horizontal selection boxes, we ignore up/down keys, and
	; for vertical selection boxes, we ignore left/right keys.
	;
arrowKey:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; rederef menu button instance	
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_NON_WRAPPING_SELECTION_BOX
	jz	sendArrowToItemGroup

	; If next arrow disabled, we ignore either right or down keys.
	;
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_NEXT_DISABLED
	jz	checkPrevArrow
SBCS < 	cmp	cl, VC_DOWN						>
DBCS < 	cmp	cl, C_SYS_DOWN and 0x00ff				>
	je	exit
SBCS < 	cmp	cl, VC_RIGHT						>
DBCS < 	cmp	cl, C_SYS_RIGHT and 0x00ff				>
	je	exit

	; If prev arrow disabled, we ignore either left or up keys.
	;
checkPrevArrow:
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_PREV_DISABLED
	jz	sendArrowToItemGroup
SBCS < 	cmp	cl, VC_UP						>
DBCS < 	cmp	cl, C_SYS_UP and 0x00ff					>
	je	exit
SBCS < 	cmp	cl, VC_LEFT						>
DBCS < 	cmp	cl, C_SYS_LEFT and 0x00ff				>
	je	exit

sendArrowToItemGroup:
	push	si				; save menu button
	call	GetMenuButtonsItemGroupFar	; *ds:si = item group
	call	ObjCallInstanceNoLock
	pop	si				; restore menu button
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; rederef menu button instance
	call	CheckIfArrowsDisabledFar	; check if any arrows disabled
	
	call	OpenDrawObject			; redraw selection box

exit:
	ret

OLPopupListKbdChar	endp

SelectionBoxKbdBindings	label	word
	word	length	SelectionBoxShortcutList

if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
SelectionBoxShortcutList	KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>, ; down arrow
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>, ; up arrow
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>, ; right arrow
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>, ; left arrow
else
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
SelectionBoxShortcutList	KeyboardShortcut \
		 <1, 0, 0, 0, 0xf, VC_DOWN>,	; down arrow
		 <1, 0, 0, 0, 0xf, VC_UP>,	; up arrow
		 <1, 0, 0, 0, 0xf, VC_RIGHT>,	; right arrow
		 <1, 0, 0, 0, 0xf, VC_LEFT>	; left arrow
endif	; if/else DBCS_PCGEOS

else		; not SELECTION_BOX -----------------------------------------
	push	ds, si, ax
	segmov	ds, cs
	mov	si, offset OLListButtonKbdBindings
	lodsw				;set ax = # of entries in table
	call	FlowCheckKbdShortcut	;search shortcut table for match
	pop	ds, si, ax
	jc	altDownPressed		;alt-down arrow, drop menu.

SBCS <	cmp	ch, VC_ISCTRL						>
DBCS <	cmp	ch, CS_CONTROL_HB					>
	jne	ignoreKey
SBCS < 	cmp	cl, VC_UP						>
DBCS < 	cmp	cl, C_SYS_UP and 0x00ff					>
	jb	ignoreKey
SBCS <	cmp	cl, VC_END						>
DBCS <	cmp	cl, C_SYS_UP and 0x00ff					>
	ja	ignoreKey

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLBI_genChunk	;get popup window
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk

EC <	push	es, di							>
EC <	mov	di, segment OLItemGroupClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLItemGroupClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR		;Chris goofed.		>
EC <	pop	es, di							>
	
	GOTO	ObjCallInstanceNoLock		;send to the list

altDownPressed:
	;
	; Alt-down has been pressed.  Either drop the menu or close it, 
	; depending upon the current situation.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	activate
	GOTO	DismissAndSendCharUpwards

activate:
	call	OpenSaveNavigationChar	;save KBD char in idata so that when
					;a button gets MSG_GEN_ACTIVATE,
					;it knows whether it is a result of
					;KBD navigation or not.
	mov	ax, MSG_OL_BUTTON_KBD_ACTIVATE
	call	ObjCallInstanceNoLock

	clr	cx
	call	OpenSaveNavigationChar	;reset our saved KBD char to "none".

returnProcessed:
	ret

ignoreKey:
	;this button does not care about this keyboard event. As a leaf object
	;in the FOCUS exclusive hierarchy, we must now initiate a FOCUS-UPWARD
	;query to see a parent object (directly) or a parent's descendants
	;(indirectly) cares about this event.
	;	cx, dx, bp = data from MSG_META_KBD_CHAR

	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent

OLPopupListKbdChar	endp

OLListButtonKbdBindings	label	word
	word	length OLListButtonShortcutList

if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLListButtonShortcutList	KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR> ;alt-down arrow opens list
else
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLListButtonShortcutList	KeyboardShortcut \
		 <1, 1, 0, 0, 0xf, VC_DOWN>,	;alt-down arrow opens list
		 <0, 0, 0, 0, 0,   ' '>		;spacebar opens list

endif	; if/else DBCS_PCGEOS
endif	; if/else SELECTION_BOX -----------------------------------------------

endif	; if KBD_NAVIGATION ---------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonSendRightArrowToParentMenu
		-- MSG_OL_MENU_BUTTON_SEND_RIGHT_ARROW_TO_PARENT_MENU handler

DESCRIPTION:	This method is sent by the sub-menu which this button opens,
		when the RIGHT arrow is pressed in that menu. We want to close
		the sub-menu and the menu in which this button is located,
		and open the next top-level menu.

PASS:		*ds:si	= instance data for object
		cx, dx, bp = MSG_META_KBD_CHAR data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonSendRightArrowToParentMenu	method	OLMenuButtonClass, \
			MSG_OL_MENU_BUTTON_SEND_RIGHT_ARROW_TO_PARENT_MENU

	;first close our menu. We can't rely upon the Gadget exclusive to
	;do this work for us, because this menu-button might be inside
	;a temporarily un-pinned menu, which is about to snap back to pinned
	;state. When a menu snaps back to the pinned state, it DOES NOT
	;force the release of the gadget exclusive within itself, therefore,
	;this menu button will never get the LOST_GADGET event.

	push	dx, bp			;save MSG_META_KBD_CHAR values
	call	OLMenuButtonCloseMenu	;close menu if not pinned or in stay-
					;up-mode, reset and redraw menu button
	pop	dx, bp

	;translate into RIGHT_ARROW press, and send up the focus tree to the
	;top-level menu which contains this button.

if _JEDIMOTIF
	;
	; In Jedi, this message means close submenus and menus, and move
	; to previous top level menu (i.e. left arrow)
	;
SBCS <	mov	cx, (VC_ISCTRL shl 8) or VC_LEFT			>
DBCS <	mov	cx, C_SYS_LEFT						>
else
SBCS <	mov	cx, (VC_ISCTRL shl 8) or VC_RIGHT			>
DBCS <	mov	cx, C_SYS_RIGHT						>
endif
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
OLMenuButtonSendRightArrowToParentMenu	endm

KbdNavigation	ends


CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonGrabFocusExcl

DESCRIPTION:	Grab focus for menu button

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		initial version

------------------------------------------------------------------------------@

OLMenuButtonGrabFocusExcl	proc	far

	call	OpenCheckIfMenusTakeFocus
	jnc	fakeGainedFocus

	; In toolbox, don't be grabbing focus no matter what. -cbh 10/15/92

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	exit

	; (Attempt something here.  We need to have make sure our menu has the
	; focus before we get it for ourselves.  -cbh 6/22/92)
	;
	mov	cx, SVQT_GRAB_FOCUS_EXCL_FOR_MENU
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent

	;if this menu button is inside a menu, DO NOT pass the
	;HGF_OD_IS_MENU_RELATED flag, as this will prevent gadgets such
	;as GenItemGroups further down in the menu from redrawing, as they
	;will never get the FOCUS, as a menu-related object is hanging on
	;to it.
	;
					;assume is not in menu
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	14$			;skip if is inside menu...

	;
	; If the focus is on a text object, we might as well treat this focus
	; as menu-related, even if this is a popup list, so that the focus can
	; return to the text object.  -cbh 2/ 1/93
	;
if SELECTION_BOX
	;
	; selection box button is never menu-related
	;
	call	CheckIfSelectionBoxFar
	jnz	14$			; not menu related
endif
	push	bp
	call	OpenTestIfFocusOnTextEditObject
	pop	bp
	jnc	12$			

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jnz	14$			;popup list, not menu related!
12$:
	ORNF	bp, mask MAEF_OD_IS_MENU_RELATED or mask MAEF_NOT_HERE
					;not in menu: is in Primary or
					;Display. Indicate that use of this
					;gadget causes FOCUS to be saved
					;and later restored.

14$:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
exit:
	ret

if	PRESERVE_FOCUS_IF_PEN_ONLY
fakeGainedFocus:
	push	si
	call	GainedFocusExclLow
	pop	si
	jmp	exit
endif
OLMenuButtonGrabFocusExcl	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonGainedFocusExcl

DESCRIPTION:	This procedure is called when the window in which this button
		is located decides that this button has the focus exclusive.

PASS:		*ds:si	= instance data for object
		^lcx:dx	= OD of object which has lost focus exclusive

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonGainedFocusExcl	method	dynamic OLMenuButtonClass, \
						MSG_META_GAINED_SYS_FOCUS_EXCL
if BUBBLE_HELP
	call	OLButtonCreateBubbleHelp
endif ; BUBBLE_HELP

	FALL_THRU	GainedFocusExclLow
OLMenuButtonGainedFocusExcl	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	GainedFocusExclLow

DESCRIPTION:	This procedure is called when the window in which this button
		is located decides that this button has the focus exclusive.

PASS:		ES	= Segment of object class
		*DS:SI	= Object gaining the focus exclusive
		DS:DI	= Object's instance data
		^lCX:DX	= OD of object which has lost focus exclusive

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/92		initial version

------------------------------------------------------------------------------@

GainedFocusExclLow	proc	far

	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jnz	done			;skip if already drawn as cursored...

	;first, take gadget exclusive for UI window, setting flag so that
	;we know what to do when we lose the gadget exclusive.

	call	OLMenuButtonTakeGadgetExcl

	;if this button is not yet CURSORED, then save the current bordered
	;and depressed state, and set DEPRESSED and/or BORDERED as required
	;by the specific UI.

	call	OLMenuButtonSaveStateSetCursored
					;sets OLBSS_CURSORED

	call	OLButtonDrawLATERIfNewState	;send method to self on queue so
					;will redraw button if necessary

	;
	; Call our superclass (if nothing else, so our subclasses
	; get MSG_META_GAINED_FOCUS_EXCL, too)
	;
done:
	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	mov	di, offset OLMenuButtonClass
	GOTO	ObjCallSuperNoLock
GainedFocusExclLow	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonSaveStateSetCursored

DESCRIPTION:	This routine tests if this menu button is pressed already,
		and if not, saves the button's current bordered and depressed
		state, and sets the new state, so that the button shows
		the cursored emphasis.

SEE ALSO:	OLMenuButtonSaveStateSetBorderedAndOrDepressed

CALLED BY:	OLMenuButtonGainedFocusExcl

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Joon	8/92		PM extensions
	sean	6/96		Support for Selection Boxes (Odie)

------------------------------------------------------------------------------@

OLMenuButtonSaveStateSetCursored	proc	near
	;First: if this is the first moment of interaction with this
	;menu button, save its BORDERED and DEPRESSED states, so can restore
	;later to reset the button visually.

	call	OLMenuButtonSaveBorderedAndDepressedStatusIfStartingInteraction
					;returns ds:di = spec instance data

	;now set the CURSORED flag

	ORNF	ds:[di].OLBI_specState, mask OLBSS_CURSORED

	;Menu buttons which open popup lists should not be depressed here.
	;Why
PMAN <	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST	>
PMAN <	jnz	done							>

	;first let's decide which of the DEPRESSED and BORDERED flags
	;we are dealing with. Start by assuming this OLMenuButton is a
	;system menu button:
	;	OPEN_LOOK:	assume B, set D
	;	PM:		assume B, set D
	;	MOTIF:		assume B, set D
	;	CUA:		assume B, set D

	mov	bx, mask OLBSS_DEPRESSED ;bx = flags to set

	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	haveFlags		;skip if is a system menu button...

	;This OLMenuButton is either in the menu bar or in a menu.
	;The behavior is the same in both cases: (NOT TRUE, see **)
	;
	;In Menu:
	;	OPEN_LOOK:	set B, set D
	;			(OL: if in pinned menu, B will already be set)
	;	PM:		set B, set D
	;	MOTIF:		set B
	;	CUA:		set D
	;
	;In Menu bar:
	;	OPEN_LOOK:	assume B, set D
	;	PM:		set B, set D
	;	MOTIF:		set B in color, set B, D in black-and-white. **
	;	CUA:		set D
	
	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, the menu buttons
	; are depressed if we are in B&W.  If _ASSUME_BW_ONLY is true, then
	; we do not check confirm that we are in B&W mode, but just assume
	; that is the case. --JimG 5/5/94

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	mov	bx, mask OLBSS_DEPRESSED
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)
	call	OpenCheckIfBW
	jc	haveFlags			; if BW, we are done..
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)

if	 (not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)
PMAN  <	mov	bx, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED		>
NOT_MO<	mov	bx, mask OLBSS_DEPRESSED				>

if _ODIE
	mov	bx, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	M10
	mov	bx, mask OLBSS_BORDERED
M10:
else
MO <	mov	bx, mask OLBSS_BORDERED					>
MO <	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR		>
MO <	jz	M10							>
MO <	call	OpenCheckIfBW		;B/W menus invert now. -cbh 3/10/93 >
MO <	jnc	M10							>
MO <	or	bx, mask OLBSS_DEPRESSED				>
MO <M10:								>
endif	;_ODIE
endif	;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

haveFlags:
	ORNF	ds:[di].OLBI_specState, bx

done:
	ret
OLMenuButtonSaveStateSetCursored	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonLostFocusExcl

DESCRIPTION:	This procedure is called when the window in which this menu
		button is located decides that this button does not have the
		focus exclusive.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonLostFocusExcl	method	OLMenuButtonClass, \
						MSG_META_LOST_SYS_FOCUS_EXCL
if BUBBLE_HELP
	call	OLButtonDestroyBubbleHelp
endif ; BUBBLE_HELP

	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jz	done			;skip if already drawn as not cursored

	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_CURSORED)

	;if our menu is not in stay-up mode, then some other object in the
	;system has grabbed the FOCUS, so we should reset our BORDERED
	;and/or DEPRESSED status to normal and REDRAW

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jnz	done			;skip if menu in stay-up-mode

	call	OLButtonRestoreBorderedAndDepressedStatus
	call	OLButtonDrawLATERIfNewState	;send method to self on queue so
					;will redraw button if necessary
done:
	ret
OLMenuButtonLostFocusExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		MSG_MO_MB_LEAVE_STAY_UP_MODE

DESCRIPTION:	This method is sent by our menu window when it leaves
		stay-up-mode. We reset some state flags, so that Gadget
		Exclusive handling will be restored in the future.
		We also return info about whether the mouse is inside
		the menu button, so that the menu window knows if it
		should close immediately or not.

PASS:		*ds:si	- OLMenuButton object
		cx, dx	- position of mouse (relative to top-left corner
				of menu window)
		bp	- [ UIFunctionsActive | buttonInfo ]
			(for menu window - indicates if pointer is inside menu)

RETURN:		cx = TRUE if pointer in menu button AND button press
			is correct for this specific UI

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


OLMenuButtonLeaveStayUpMode	method	dynamic OLMenuButtonClass, \
						MSG_MO_MB_LEAVE_STAY_UP_MODE

	;mouse pointer is over menu window or deep space: in any case,
	;we know menu will close momentarily. Set POPUP_OPEN = FALSE
	;ERIC:  I don't know if this belongs here or not...

	ANDNF	ds:[di].OLMBI_specState, not \
			(mask OLMBSS_MENU_FUNCTION_PENDING or \
			 mask OLMBSS_DEFAULT_FUNCTION_PENDING)

	;if this OLMenuButton is inside menu whose submenu is leaving
	;stay-up mode, then this menu button is no longer visible!

	mov	ax, cx			;(ax, bx) = mouse coordinates
	mov	bx, dx
	call	VisQueryWindow		;get window we're on
	tst	di			;are we realized?
	jz	notPressing		;skip if not (this menu is closed. Will
					;restore visual state of button)...

	;do we know for a fact that the mouse pointer is inside the menu window?

	test	bp, (mask UIFA_IN) shl 8
					;is mouse ptr in menu window?
	jnz	done			;skip if so...

	;this menu button is visible: see if mouse pointer in bounds.
	;first translate the pointer coordinates so that they
	;are relative to this window which contains this button

EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	; ensure good window		>
EC <	pop	bx							>

	call	WinUntransform	; get window coords
	mov	cx, ax			; cx, dx = ptr position in window coords
	mov	dx, bx

	call	VisTestPointInBounds	;see if ptr inside menu button bounds
	jnc	notPressing		;skip if not...

	;mouse pointer is over menu button: now make sure this button press
	;would normally activate the button in this UI

	call	OLMenuButtonTranslateMenuFunctions
					;returns bp (high) = OLMBFA flags
	test	bp, (mask OLMBFA_MENU) shl 8
	jz	notPressing		;skip if menu should not be up...

pressingOnMenuFunction:
	;We are leaving stay-up-mode, and the mouse IS PRESSING ON THE
	;MENU BUTTON. We want to tell the base window to restart its
	;SelectMyControlsOnly mechanism, so we are at the same state
	;as if the user had just opened the menu.
	;To find the base window, send generic query to self, superclass will
	;send upwards to GenDisplay. GenDisplay will return its' handle.

	;Find the generic window group that this object is in

	mov	ax, MSG_OL_WIN_STARTUP_GRAB	;get method
	call	CallOLWin		
						;get TRUE/FALSE - whether
						;mouse is over menu button
	mov	cx, TRUE
	ret

notPressing:
	;this menu button is visible, but the mouse pointer is not
	;pressing on it. Reset this menu button visually.

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

done:
	clr	cx			;return: pointer NOT over menu button
	ret
OLMenuButtonLeaveStayUpMode	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuButtonNotifyMenuDismissed --
			MSG_OL_MENU_BUTTON_NOTIFY_MENU_DISMISSED handler

DESCRIPTION:	This method is sent by the menu that this button drives,
		when that menu is DISMISSed.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuButtonNotifyMenuDismissed	method	dynamic	OLMenuButtonClass, \
				MSG_OL_MENU_BUTTON_NOTIFY_MENU_DISMISSED

	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN
	jz	done			; popup not open

	;Reset this menu button visually, and reset our flag.

	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_POPUP_OPEN)

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW
done:
	ret
OLMenuButtonNotifyMenuDismissed	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonDraw -- 
		MSG_VIS_DRAW for OLMenuButtonClass

DESCRIPTION:	Draws a menu button.   Basically we have some hacks in here
		for popups that have reply bar spacing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW
		cl	- DrawFlags
		bp	- gstate

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

OLMenuButtonDraw	method dynamic	OLMenuButtonClass, MSG_VIS_DRAW
	;
	; This is probably terrible, but we do this so that code in the
	; button draw code may mess with the bounds.  Since it only happens
	; to menu buttons, we'll do this here rather than OLButtonDraw.
	;
	push	ds:[di].VI_bounds.R_left
	push	ds:[di].VI_bounds.R_top
	push	ds:[di].VI_bounds.R_right
	push	ds:[di].VI_bounds.R_bottom

if	not SELECTION_BOX
	test	ds:[di].OLBI_specState, mask OLBSS_MENU_DOWN_MARK
	jz	10$
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jz	10$
	or	ds:[di].OLBI_specState, mask OLBSS_DEFAULT_TRIGGER
10$:
endif
	mov	di, offset OLMenuButtonClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	pop	ds:[di].VI_bounds.R_bottom
	pop	ds:[di].VI_bounds.R_right
	pop	ds:[di].VI_bounds.R_top
	pop	ds:[di].VI_bounds.R_left
	ret
OLMenuButtonDraw	endm

CommonFunctional ends

Geometry segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLMenuButtonClass

DESCRIPTION:	Resizes object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - size suggestions

RETURN:		cx, dx, - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/29/92		Initial Version
	sean	6/28/96		Selection box schme (Odie)
	sean	9/10/96		Selection box again

------------------------------------------------------------------------------@

if not _RUDY

OLMenuButtonRecalcSize	method dynamic	OLMenuButtonClass, \
				MSG_VIS_RECALC_SIZE

	mov	di, offset OLMenuButtonClass	;do normal button stuff
	CallSuper	MSG_VIS_RECALC_SIZE

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	;
	; If we open a popup list, we have this little code to get our size
	; from that of the popup window.  Actually, we'll get our width from
	; the popup list if it's vertical, our height from it if it's 
	; horizontal.
	;
	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	exit				

if	SELECTION_BOX	;----------------------------------------------------
EC <	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX	>
EC <	ERROR_Z		OL_ERROR_SELECTION_BOX				>

	mov	al, ds:[di].OLMBI_odieFlags
	mov	ah, ds:[di].OLBI_moreAttrs
	mov	si, ds:[di].OLBI_genChunk	; *ds:si = popup win

	; Calculate the minimum width & compare this to the passed
	; width.  We'll suggest the larger of the two.
	;
	push	ax, cx, dx
	call	UpdatePopupAndGetSize		; cx = calculated width (from moniker)
	pop	ax, bx, dx			; bx = passed width

	add	cx, (2 * SELECTION_BOX_INSET)	; outline lines

	test	al, mask OLMBOF_BORDERED_SELECTION_BOX
	jz	addArrows			; bordered -- add 3-D borders to width
	add	cx, (2 * SELECTION_BOX_BORDER)

addArrows:
	test	al, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	checkMinWidth			; horizontal -- add arrows to width
	add	cx, ((2 * SELECTION_BOX_ARROW_WIDTH) +\
		    (2 * SELECTION_BOX_INSET))

checkMinWidth:
	cmp	bx, cx				; return larger width
	jbe	checkHeight
	mov	cx, bx	

	; Calculate the minimum height, & compare this to the passed
	; height.  We'll return the larger of the two.
	;
checkHeight:
	mov	bx, dx				; bx = passed height
	mov	dx, SELECTION_BOX_MIN_HEIGHT	

	test	al, mask OLMBOF_BORDERED_SELECTION_BOX	
	jz	noVerticalBorder		; bordered -- add 3-D borders to height
	add	dx, (2 * SELECTION_BOX_BORDER)

noVerticalBorder:
	test	al, mask OLMBOF_VERTICAL_SELECTION_BOX
	jz	checkMinHeight			; vertical -- add arrows to height
	add	dx, ((2 * SELECTION_BOX_ARROW_HEIGHT) +\
		    (2 * SELECTION_BOX_INSET))

checkMinHeight:
	cmp	bx, dx				; return larger height
	jbe	exit
	mov	dx, bx

else	; not SELECTION_BOX  -------------------------------------------------
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_specState, mask OLMBSS_ORIENT_POPUP_HORIZONTALLY
	mov	si, ds:[di].OLBI_genChunk	;get popup window
	jnz	horizPopup

	push	cx, dx
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT
	jnz	10$				;expanding width to passed, 
						;   don't mess with width

	mov	bl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	call	UpdatePopupAndGetSize
10$:
	pop	ax, dx			;restore button's calc'ed height
	cmp	ax, cx			;return the larger width
	jbe	finishPopup		;  (cbh 12/ 2/92)
	mov	cx, ax
	jmp	short finishPopup

horizPopup:
	push	cx
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_HEIGHT_TO_FIT_PARENT
	jnz	20$				;expanding height to passed, 
						;   don't mess with height
	clr	bl
	call	UpdatePopupAndGetSize
20$:
	pop	cx				;restore button's calced width

finishPopup:
	;
	;*ds:si -- popup window
	;
	CallMod	VisApplySizeHints		;account for popup hints here

endif		; if/else SELECTION_BOX  -------------------------------------
exit:
	ret
OLMenuButtonRecalcSize	endm
endif		; if not RUDY




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdatePopupAndGetSize

SYNOPSIS:	Updates popup win's geometry, returning its size.

CALLED BY:	OLMenuButtonRecalcSize

PASS:		*ds:si -- popup win
		cx, dx -- size of the button based on its moniker
		bl     -- zero if popup must be vertical to use size,
			  VCGA_ORIENT_CHILDREN_VERTICALLY if popup must be horiz

RETURN:		cx, dx -- new size, if its list displays the current selection,
			else unchanged

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/29/92		Initial version
	Joon	8/17/92		PM extensions

------------------------------------------------------------------------------@


if (not _RUDY)

UpdatePopupAndGetSize	proc	near
	class	OLItemGroupClass

	;
	; If the list we're running is not display the current selection, we
	; won't muck with the size at all.
	;
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>

if	(not SELECTION_BOX)
	;
	; If the orientation of the popup isn't what we expect, forget about
	; using its size.  It must have been changed on the fly to improve
	; its appearance.  (Rudy, always make a pass to spec build the thing.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
if not _RUDY
	xor	bl, ds:[di].VCI_geoAttrs
	test	bl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	exit
endif

	; At this point I don't know whether this is popup list is scrollable
	; or not.  Therefore I don't really know where the item group is.

	mov	di, ds:[di].VCI_comp.CP_firstChild.chunk

	push	es, si, di
	mov	si, di
	mov	di, segment OLItemGroupClass
	mov	es, di
	mov	di, offset OLItemGroupClass
	call	ObjIsObjectInClass
	pop	es, si, di
	jc	checkDisplayFlag

	;
	; Not an item group, assume a view and reference through the content
	; to find the item group.  If it isn't there, die.  -cbh 11/23/92
	;
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GVI_content.chunk
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VCI_comp.CP_firstChild.chunk
	
EC <	push	es, si, di						>
EC <	mov	si, di							>
EC <	mov	di, segment OLItemGroupClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLItemGroupClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR		;Chris goofed.		>
EC <	pop	es, si, di						>


checkDisplayFlag:

if _RUDY
	;
	; We'll update geometry on the item group itself, we really just want
	; it spec built.   And all Rudy item groups display current selection.
	;
	mov	si, di
else
	mov	di, ds:[di]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	exit
endif	; if/else _RUDY
endif	; if not SELECTION_BOX
	
	mov	ax, MSG_VIS_UPDATE_GEOMETRY	;update popup's geometry
	call	ObjCallInstanceNoLock		

	mov	cl, mask VOF_GEOMETRY_INVALID	;mark the popup invalid so it
	mov	dl, VUM_MANUAL			; will re-evaluate its geometry
	call	VisMarkInvalid			; after being spec built

if not _RUDY
	call	VisGetSize			;return size of popup win
endif

exit::
	ret
UpdatePopupAndGetSize	endp

endif	



if	0		;don't need this for rudy...

UpdatePopupAndGetSize	proc	near
	class	OLItemGroupClass

	;
	; If the list we're running is not display the current selection, we
	; won't muck with the size at all.
	;
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>

	;
	; If the orientation of the popup isn't what we expect, forget about
	; using its size.  It must have been changed on the fly to improve
	; its appearance.  (Rudy, always make a pass to spec build the thing.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
if not _RUDY
	xor	bl, ds:[di].VCI_geoAttrs
	test	bl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	exit
endif

	; At this point I don't know whether this is popup list is scrollable
	; or not.  Therefore I don't really know where the item group is.

	mov	di, ds:[di].VCI_comp.CP_firstChild.chunk

	push	es, si, di
	mov	si, di
	mov	di, segment OLItemGroupClass
	mov	es, di
	mov	di, offset OLItemGroupClass
	call	ObjIsObjectInClass
	pop	es, si, di
	jc	checkDisplayFlag

	;
	; Not an item group, assume a view and reference through the content
	; to find the item group.  If it isn't there, die.  -cbh 11/23/92
	;
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GVI_content.chunk
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VCI_comp.CP_firstChild.chunk
	
EC <	push	es, si, di						>
EC <	mov	si, di							>
EC <	mov	di, segment OLItemGroupClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLItemGroupClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR		;Chris goofed.		>
EC <	pop	es, si, di						>


checkDisplayFlag:

if _RUDY
	;
	; We'll update geometry on the item group itself, we really just want
	; it spec built.   And all Rudy item groups display current selection.
	;
	mov	si, di
else
	mov	di, ds:[di]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	exit
endif

	mov	ax, MSG_VIS_UPDATE_GEOMETRY	;update popup's geometry
	call	ObjCallInstanceNoLock		

	mov	cl, mask VOF_GEOMETRY_INVALID	;mark the popup invalid so it
	mov	dl, VUM_NOW			; will re-evaluate its geometry
	call	VisMarkInvalid			; after being spec built

if not _RUDY
	call	VisGetSize			;return size of popup win
endif

exit:
	ret
UpdatePopupAndGetSize	endp

endif	 ;0


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuButtonUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLMenuButtonClass

DESCRIPTION:	Updates windows and image.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER
		bp	- some stuff

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
	chris	5/25/92		Initial Version
	Joon	9/92		PM Version
	sean	6/96		Support for Selection Boxes (Odie)

------------------------------------------------------------------------------@

if (not _PM)	;--------------------------------------------------------------

OLMenuButtonUpdateVisMoniker	method dynamic	OLMenuButtonClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER

	; If we're a selection box, skip this stuff entirely.
	;
if	SELECTION_BOX
	call	CheckIfSelectionBoxFar
	jnz	exit
endif

	;
	; Do normal invalidation in most situations.
	;
	push	dx
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID

	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	markInvalid
	;
	; Opening popup lists, we'll painfully only the moniker area to the
	; inval region, to avoid the border being redrawn.  We'll still
	; mark the geometry invalid, in case it needs to be resized.
	;
	sub	sp, size OpenMonikerArgs ;make room for args
	mov	bp, sp			;pass pointer in bp
   	call	SetupMonikerArgs	;pass things to moniker routine
;	call	OpenGetLineBounds	;we'll pretend there's a good reason
;					;   for using this, not VisGetBounds
;VisGetBounds fixes descenders in CGA - brianc 6/9/93
	call	VisGetBounds
	add	ax, ss:[bp].OMA_leftInset
	add	bx, ss:[bp].OMA_topInset
	sub	cx, ss:[bp].OMA_rightInset

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_MENU_DOWN_MARK
	jz	10$	
	sub	cx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING
10$:

	sub	dx, ss:[bp].OMA_bottomInset
	add	sp, size OpenMonikerArgs

	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_left, ax
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	clr	ss:[bp].VARP_flags

	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock

	add	sp, size VisAddRectParams

	mov	cl, mask VOF_GEOMETRY_INVALID

markInvalid:
	pop	dx

	call	VisMarkInvalid
exit::
	ret
OLMenuButtonUpdateVisMoniker	endm

else	; we're PM ------------------------------------------------------------

OLMenuButtonUpdateVisMoniker	method dynamic	OLMenuButtonClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER

	;
	; Do normal invalidation in most situations.
	;
	push	dx
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID

	test	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST
	jz	markInvalid
	;
	; Opening popup lists, we'll painfully only the moniker area to the
	; inval region, to avoid the border being redrawn.  We'll still
	; mark the geometry invalid, in case it needs to be resized.
	; PM needs to invalidate the entire moniker area to make sure that the
	; selection cursor around the moniker is erased.
	;
	call	OpenGetLineBounds	;we'll pretend there's a good reason
					;   for using this, not VisGetBounds

	inc	ax
	inc	bx
	sub	cx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING + 1
	dec	dx

	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_left, ax
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	clr	ss:[bp].VARP_flags

	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams

	mov	cl, mask VOF_GEOMETRY_INVALID

markInvalid:
	pop	dx
	call	VisMarkInvalid
	ret
OLMenuButtonUpdateVisMoniker	endm

endif		; if (not _PM) ------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMBSpecGetExtraSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In PCV, don't add extra size to fixed size menu buttons.

CALLED BY:	MSG_SPEC_GET_EXTRA_SIZE
PASS:		*ds:si	= OLMenuButtonClass object
		ds:di	= OLMenuButtonClass instance data
		ds:bx	= OLMenuButtonClass object (same as *ds:si)
		es 	= segment of OLMenuButtonClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	3/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PCV or SELECTION_BOX
OLMBSpecGetExtraSize	method dynamic OLMenuButtonClass, 
					MSG_SPEC_GET_EXTRA_SIZE
	.enter
	clrdw	cxdx
	.leave
	ret
OLMBSpecGetExtraSize	endm
endif
Geometry ends






