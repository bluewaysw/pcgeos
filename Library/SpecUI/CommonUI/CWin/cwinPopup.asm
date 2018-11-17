COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		winPopup.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLPopupWinClass		Open look popup window class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:

	$Id: cwinPopup.asm,v 1.1 97/04/07 10:53:34 newdeal Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLPopupWinClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------------------------------

WinClasses segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinInitialize -- MSG_META_INITIALIZE for OLPopupWinClass

DESCRIPTION:	Initialize an open look menu from a Generic Group object

PASS:
	*ds:si - instance data
	es - segment of OlPopupClass

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


OLPopupWinInitialize	method static	OLPopupWinClass, MSG_META_INITIALIZE
	uses	bx, di, es		; Conform to static call requirements
	.enter

	;call superclass

	mov	di, segment OLPopupWinClass
	mov	es, di
	mov	di, offset OLPopupWinClass
	CallSuper	MSG_META_INITIALIZE

	;initialize our modality flags

EC <	push	es, di							>
EC <	mov	di, segment GenInteractionClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenInteractionClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	es, di							>

	mov	ax, HINT_INTERACTION_MODAL
	call	ObjVarFindData			; carry set if found
	pushf					; preserves flags
	clr	ah
	call	WinClasses_DerefGen_DI
	popf					; retrieve flags
	jc	isAppModal			; HINT_INTERACTION_MODAL -> app-modal
	mov	al, ds:[di].GII_attrs
	test	al, mask GIA_MODAL
	jz	notAppModal
isAppModal:
	ornf	ah, mask OLPWF_APP_MODAL
notAppModal:
	test	al, mask GIA_SYS_MODAL
	jz	notSysModal
	ornf	ah, mask OLPWF_SYS_MODAL
notSysModal:
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLPWI_flags, ah

	ORNF	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP

EC <	and	ah, mask GIA_MODAL or mask GIA_SYS_MODAL		>
EC <	cmp	ah, mask GIA_MODAL or mask GIA_SYS_MODAL		>
EC <	ERROR_Z	OL_POPUP_IT_IS_ILLEGAL_TO_BE_BOTH_APP_MODAL_AND_SYS_MODAL  >

	;no need to set OLWI_attrs (such as OWA_THICK_LINE_BORDER), because
	;objects which subclass from this object will set window attributes
	;in their MSG_META_INITIALIZE handler.

	;set visual attributes: "DUAL_BUILD" means than this object will
	;need to get two SPEC_BUILDs to work: the first build the button
	;associated with this popup window, and the second builds the popup
	;window itself. Setting this flag changes the way that SPEC_BUILD
	;methods recursively descends the visual tree.

					; Mark as being a window group, a
					; window & using DUAL_BUILD
	ORNF	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	.leave
	ret
OLPopupWinInitialize	endp


COMMENT @----------------------------------------------------------------------

METHOD:         OLPopupWinUpdateSpecBuild

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

OLPopupWinUpdateSpecBuild   method dynamic  OLPopupWinClass, \
						MSG_SPEC_BUILD_BRANCH

	test	bp, mask SBF_WIN_GROUP		; Doing win group portion?
	jz	callSuper			; just skip & call superclass
						; if not.

	; Set optimization flag indicating that no object
	; at this point or below in the tree, when being
	; TREE_BUILD'd, will be adding itself visually
	; outside the visual realm of this popup window.  (Allows 
	; VisAddChildRelativeToGen to work much quicker)

	or	bp, mask SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD

callSuper:
	GOTO	WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far

OLPopupWinUpdateSpecBuild   endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinSpecBuild -- MSG_SPEC_BUILD for OLPopupWinClass

DESCRIPTION:	Build out this popup visually, attaching it onto
		some background window in the system.  Depending on whether
		the top of the branch being build is this popup, or somewhere
		above, we'll be hooking up either the button associated with
		this popup, or the popup itself.

		NOTE:  Subclass is responsible for visible positioning of
		popup window.

PASS:
	*ds:si - instance data
	es - segment of OLPopupWinClass

	ax - MSG_SPEC_BUILD

	cx - ?
	dx - ?
	bp - SpecBuildFlags (SBF_WIN_GROUP, etc)

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
	Doug	3/89		Initial version

------------------------------------------------------------------------------@


OLPopupWinSpecBuild	method dynamic	OLPopupWinClass, MSG_SPEC_BUILD

if	ERROR_CHECK
						; MUST be a WIN_GROUP
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	ERROR_Z	OL_ERROR
endif
	;first test if this MSG_SPEC_BUILD has been recursively descending
	;the visible tree. If it has, it means we want to SPEC_BUILD our button.
	;Otherwise, it means that the popup window has been activated; we want
	;to SPEC_BUILD it.

	test	bp, mask SBF_WIN_GROUP	;at top of tree?
	jz	buildButton		;skip if not...

	;we are at the top of the visible tree (within this window group):
	;send MSG_SPEC_BUILD on to superclass (OLWinClass) so it will
	;build out this window.

OLS <	call	OLPopupWinSetPinnedIfLongTerm				>
					;if OWFA_LONG_TERM, set OLWSS_PINNED...

if BUBBLE_DIALOGS
	push	ax
	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
	jnc	afterActivatorTest
	call	WinClasses_DerefVisSpec_DI
	or	ds:[di].OLPWI_flags, mask OLPWF_HAS_ACTIVATOR
afterActivatorTest:
	pop	ax
endif

	GOTO	WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far

;(This happens first)

buildButton:
	;this MSG_SPEC_BUILD has been descending the visible tree; we
	;want to build our button.
	
	call	WinClasses_DerefGen_DI
	test	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE or \
				mask GIA_INITIATED_VIA_USER_DO_DIALOG
	LONG	jnz veryDone		;skip if not button requested...

	;Marked as user-initiatable.  Before building button, make sure the
	;generic parent isn't the app-object, as it is pointless (and foils
	;UserDestroyDialog optimizations) to build a button below
	;the app object.	-- Doug 1/93
	;
EC <	call	ECEnsureParentNotAppObj				>

	;since this button will use the menu's generic moniker, we must reduce
	;the menu's generic moniker list into a single moniker. Search this
	;object's VisMonikerList for the moniker which matches the
	;DisplayType for this application, and replace the list with
	;that moniker.

	push	bp, es
	mov	bp, mask VMSF_REPLACE_LIST or mask VMSF_GSTRING \
		    or (VMS_ICON shl offset VMSF_STYLE)
	clc				;flag: use this object's visual moniker
	call	GenFindMoniker		;trashes ax, di, es, may move ds
	pop	bp, es

	;now see about building the button itself.

	call	WinClasses_DerefVisSpec_DI
	mov	bx, ds:[di].OLCI_buildFlags	;bx = build flags
	mov	dx, ds:[di].OLPWI_button
	tst	dx			;See if already built
	LONG	jnz haveButton		;skip if have button...

	;if this is a menu window, create an OLMenuButtonClass object to
	;open it. Otherwise, create an OLButtonClass object to open it.
	;First retrieve the results of the BUILD_INFO query that was
	;sent up the generic tree when this window was gen->specific built
	;(see cspecInteraction.asm).

	push	bp			;save SpecBuildFlags

	;Create a menu button to drive this popup window

	push	bx			;save OLBuildFlags
	mov	bh, ds:[di].OLWI_fixedAttr ;set BH = OLWinFixedAttr
	mov	bl, ds:[di].OLWI_type	;set BL = OLWinType
	push	bx

	;
	; In Rudy, always use a button, not a menu button, since we don't
	; really have menus, just dialog boxes.
	;
	mov	di, offset OLMenuButtonClass	;assume this is a menu

	test	bh, mask OWFA_IS_MENU		;is this a menu?
	jnz	buildButtonHaveClass		;skip if so...
	mov	di, offset OLButtonClass	;is a CommandWindow or summons

buildButtonHaveClass:
	push	si			;save menu chunk handle
	;
	; Check if window for which button is being built has 
	; HINT_DEFAULT_DEFAULT_ACTION.  If so, we want to mark button
	; appropriately.  ONLY if not a menu.
	;	bh = OLWinFixedAttr
	;
	test	bh, mask OWFA_IS_MENU	;menu? (test clears carry)
	jnz	skipDefaultCheck	;yes, skip check (carry clear)
	mov	ax, HINT_DEFAULT_DEFAULT_ACTION
	call	ObjVarFindData		;carry set if found
skipDefaultCheck:
	pushf				;save result (carry set -> is default)
	mov	bx, ds:[LMBH_handle]	;put menu button in same block
	call	GenInstantiateIgnoreDirty	;returns si = handle of object
	popf				;carry set if DEFAULT_DEFAULT_ACTION
	pop	cx			;get menu chunk (was in si)
	pop	dx			;get window type and OLWinFixedAttr
	pop	bp			;get OLBuildFlags

	;send MSG_OL_BUTTON_SETUP to menu button, to give it info
	;on its menu window, and to allow it to perform special initialization
	;if necessary (as in the SystemMenuButton case in Motif/CUA).
	;	cx = handle of menu window
	;	dl = window type (OLWT_MENU, OLWT_SUBMENU,OLWT_SYSTEM_MENU, etc)
	;	dh = OLWinFixedAttr (contains OWFA_IS_MENU, etc)
	;	bp = OLBuildFlags (for popup window, but they really pertain
	;		to this button object - see OLDisplayGroupGupQuery)
	;	carry set if DEFAULT_DEFAULT_ACTION

	push	cx			;save menu chunk on stack again
	push	bp			;save OLBuildFlags
	pushf				;save DEFAULT_DEFAULT_ACTION state

	;quick error check: WE DO NOT want to pass dh = TRUE, since this
	;means something completely different!

EC <	cmp	dh, 0ffh		;passing dh = TRUE means is a GenList >
EC <	ERROR_Z	OL_ERROR						      >

if _ISUI
	;copy focus help hint
	push	cx, dx, es, bp, si
	segmov	es, ds			; *es:bp = new button
	mov	bp, si
	mov	si, cx			; *ds:si = parent popup
	mov	cx, ATTR_GEN_FOCUS_HELP
	mov	dx, cx
	call	ObjVarCopyDataRange
	pop	cx, dx, es, bp, si
endif

	mov	ax, MSG_OL_BUTTON_SETUP
	call	WinClasses_ObjMessageCallFixupDS

	;
	; mark button with OLBFA_MASTER_DEFAULT_TRIGGER if
	; OLBFA_MASTER_DEFAULT_TRIGGER.
	; MUST be done after sending MSG_OL_BUTTON_SETUP to ensure that
	; OLButton is built
	;
	popf				;get DEFAULT_DEFAULT_ACTION state
	jnc	notDefault
	call	WinClasses_DerefVisSpec_DI	; *ds:si = OLButton
	.warn	-private
	ornf	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
	.warn	@private
notDefault:

	call	WinClasses_Mov_CXDX_Self ;put handle of button instance in dx

	pop	bx			;bx = OLBuildFlags
	pop	si			;set *ds:si = window object
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLPWI_button, dx ;store handle to menu button
	pop	bp			;Get SpecBuildFlags



haveButton: ;bx = OLBuildFlags, bp = SpecBuildFlags
	push	si			;save handle of menu window
	mov	si, dx
	call	VisCheckIfSpecBuilt	; If button already built,
	pop	si
	LONG	jc done			; then we're all done, quit.

	;Set the button fully enabled based on our parent's fully enabled
	;state (passed in with BuildFlags) and the menu window's enabled state.
	;important: bp = SpecBuildFlags
	
	push	bx			;save OLBuildFlags
	push	si

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	call	OLQueryIsMenu
					;does not destroy any registers!
	pushf				;save result
endif
	mov	bx, ds:[si]		;ds:bx <- menu window's GenInstance
	add	bx, ds:[bx].Gen_offset	;

	mov	si, dx			;assume we'll leave button disabled
	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].VI_attrs, not mask VA_FULLY_ENABLED

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	popf				;was the popup a menu?
	jc	enableButton		;yes, always enabled the button
endif
	test	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
	jz	afterEnable		;build flags not fully enabled, branch
	
	test	ds:[bx].GI_states, mask GS_ENABLED
	jz	afterEnable		;popup not generically enabled, branch
	
enableButton:
	ORNF	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

afterEnable:
	pop	si 			;restore menu window handle,
   
	;Now we want to add this OLMenuButton object visible to the correct
	;parent. First, to find the parent, we send call VisGetVisParent,
	;which sees that the menu has a SA_CUSTOM_VIS_PARENT, and so it
	;sends a MSG_SPEC_GET_VIS_PARENT, which returns the OLCI_visParent
	;field from the menu (info determined during gen->specific build).

	mov	bx, dx			;set *ds:bx = OLMenuButton
	call	VisGetVisParent 	;returns ^lcx:dx = OLMenuBar, etc.

	;if this object is a system icon, make it the first visible child,
	;since it will be an UNMANAGED object, so visible order does not matter.

	pop	di			;set di = OLBuildFlags
	ANDNF	di, mask OLBF_TARGET

	
OLS <	mov	ax, CCO_FIRST		;assume that we will place menu 1st >
CUAS <	mov	ax, CCO_FIRST+1		;assume that we will place menu 2nd >
	cmp	di, OLBT_IS_EXPRESS_MENU shl offset OLBF_TARGET
	je	systemIcon		;branch if an express menu
	
	mov	ax, CCO_FIRST		;assume that we will place menu first

	;
	; check for "File" menu, which must be placed first
	;	*ds:si = OLPopupWin
	;
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLPWI_flags, mask OLPWF_FILE_MENU	; "File" menu?
	jnz	specificPlacement	;if so, use CCO_FIRST
					;(carry clear is passed)

	mov	di, ds:[bx]		;set ds:di = spec data for button
	add	di, ds:[di].Vis_offset

	.warn	-private
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	.warn	@private
	
	jz	isRegularMenu		;skip if not an icon...

systemIcon:
	;
	; Added hack 6/28/91 cbh to bypass where the primary thinks this
	; object should be, the OLGadgetArea.  We're a system icon, and
	; we want to be a direct child of the primary.
	;
	push	bx, si
	call	GenFindParent		;always attach to parent
	mov	cx, bx
	mov	dx, si
	pop	bx, si

	stc				;indicate not "File" menu

specificPlacement:
	;carry clear here if "File" menu, carry set otherwise
	
	;make it the first visible child

	pushf				;save "File" menu flag

	mov	bp, ax			;set bp = ChildCompFlags
	push	si			;save OLPopupWin
	mov	si, dx
	mov	dx, bx
	mov	bx, cx			;set ^lbx:si = OD of menu bar, etc.
	mov	cx, ds:[LMBH_handle]	;pass ^lcx:dx = OD of OLMenuButton

	mov	ax, MSG_VIS_ADD_CHILD
	call	WinClasses_ObjMessageCallFixupDS

	pop	si			;restore OLPopupWin

	popf				;restore "File" menu flags
	jc	done			;not "File" menu, done

	;finish up for "File" menu, mark button invalid

	push	si			;save OLPopupWin
	mov	si, dx			;*ds:si = OLMenuButton
	call	VisMarkFullyInvalid
	pop	si			;restore OLPopupWin
	jmp	done			;skip ahead to end...

isRegularMenu:
	;This is a regular menu. Position its menu button within its visual
	;parent's sibling list according to how the menu sits in its generic
	;parent's sibling list. NOTE: if this is a UI-fabricated menu, such
	;as the MDIWindowsMenu, it only has a one-way generic link directly
	;to the parent, so it appears to be the last child, and so the menu
	;button will be added as the last visible child.
	;Pass:
	;	*ds:si	- generic object, which will be used as the ref obj
	;	^lax:bx	- visual object to add to parent
	;	^lcx:dx	- visual parent to use
	;	bp = SpecBuildFlags

	mov	ax, ds:[LMBH_handle]	;set ^lax:bx = OD of OLMenuButton
	call	VisAddChildRelativeToGen

afterRegularMenu:

	;Set the button's window mark flag so it will show a "..."

	push	si
	call	WinClasses_DerefVisSpec_DI
	mov	si, bx			;Get button in *ds:si

	test	ds:[di].OLCI_buildFlags, mask OLBF_ABOVE_DISP_CTRL
	pushf				;save result of test for later

if 0	; this is done in MSG_OL_BUTTON_SETUP, so no need to do it here
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	setGeoFlags		;skip if menu or submenu...

	.warn	-private

					; Get SpecInstance of button in
					; ds:di
	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLBI_specState, mask OLBSS_WINDOW_MARK

	.warn	@private

setGeoFlags: ;set geometry for button, and invalidate button and its parent
endif


	call	VisMarkFullyInvalid

	;
	; if button is DEFAULT_DEFAULT_ACTION, tell window about it
	;	*ds:si = OLButton
	;
	call	WinClasses_DerefVisSpec_DI
	.warn	-private
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
	.warn	@private
	jz	notDefault2
	push	ax, cx, dx, bp
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = OLButton object
	mov	dx, si
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_SET_MASTER_DEFAULT
	call	CallOLWin
	pop	ax, cx, dx, bp
notDefault2:

	;if this GenInteraction was adopted by a higher menu bar,
	;better send it an update...

	popf				;check test performed above
	jz	afterGeometryInit	;skip if not...

	;Was adopted: make sure the menu bar redraws

	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;must delay since no vis parent
						;established yet
	call	WinClasses_ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

afterGeometryInit:
	pop	si				;get handle of window

done:	;the button now exists. If button is in a pinned menu, set the button
	;to be BORDERED in OpenLook

OLS <	push	si							>
OLS <	call	WinClasses_DerefVisSpec_DI				>
OLS <	mov	si, ds:[di].OLPWI_button				>
OLS <	tst	si							>
OLS <	jz	90$							>
OLS <	call	OLButtonTestIfInPinnedMenu				>
OLS <90$:								>
OLS <	pop	si							>


veryDone:
	ret



OLPopupWinSpecBuild	endp

;
;-------
;

if	ERROR_CHECK
ECEnsureParentNotAppObj	proc	near
	uses	bx, si, cx, dx
	.enter
	clr	bx
	push	si
	call	GeodeGetAppObject
	mov	cx, bx
	mov	dx, si
	pop	si
	push	si
	call	GenFindParent
	cmp	bx, cx
	jne	ok
	cmp	si, dx
ok:
	pop	si
	ERROR_E	OL_ERROR_DIALOG_PLACED_BELOW_APP_OBJ_MUST_BE_MARKED_NOT_USER_INITIATABLE
	.leave
	ret
ECEnsureParentNotAppObj	endp
endif

WinClasses ends

;--------------------

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLQueryIsMenu

DESCRIPTION:	Query an object to see if it's a window

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	carry - set if this is a menu

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/93		Initial version

------------------------------------------------------------------------------@
if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
OLQueryIsMenu	proc	far

	;
	; check if OLWin first
	;
	push	es
	mov	di, segment OLWinClass
	mov	es, di
	mov	di, offset OLWinClass
	call	ObjIsObjectInClass
	pop	es
	jnc	exit			;not OLWin, exit with "not a menu"

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	exit			;skip if not (cy=0)...

	;
	; Popup lists no longer return carry set here, so they can be 
	; disabled and stuff.  Also menus that are not in the reply bar, as
	; they're closer to popup list functionality.  -cbh 12/17/92
	;
	mov	di, ds:[di].OLCI_buildFlags
	test	di, mask OLBF_AVOID_MENU_BAR
	jnz	exit			;ignoring menu bar, return not a menu.
					; (c=0)

	and	di, mask OLBF_TARGET
	cmp	di, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	je	exit			;popup list, not really a menu (C=0)
	stc
exit:
	ret

OLQueryIsMenu	endp
endif

Resident ends

;------------------

WinClasses segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPopupWinVisUnBuild

DESCRIPTION:	Unbuild generic object

CALLED BY:	

PASS:		*ds:si	= instance data for object
		bp	- SpecBuildFlags:
				SBF_WIN_GROUP	- if WIN_GROUP portion is
						  being visually unbuilt
				SBF_VIS_PARENT_UNBUILDING - SHOULD NEVER
						  be set, since the visible
						  linkage for this object
						  itself only ever sits on
						  the field, which should
						  never be unbuilding before
						  this object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@
OLPopupWinVisUnBuild	method dynamic	OLPopupWinClass, MSG_SPEC_UNBUILD

				; Unbuilding button or WIN_GROUP?
	test	bp, mask SBF_WIN_GROUP
	jnz	UnbuildWinGroup

	;if this popup window has a button, tell it to un-build itself
	;
	mov	bx, ds:[di].OLPWI_button
	tst	bx
	jz	afterButtonUnbuilt
	push	si
	mov	si, bx			; *ds:si is visible object button
					; Send method to button object,
					; to cause it to close visually,
					; unhook iself & be destroyed
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	WinClasses_ObjCallInstanceNoLock
	pop	si

	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLPWI_button, 0	; NULL out reference to button
afterButtonUnbuilt:

	ret

UnbuildWinGroup:
	;
	; destroy pin trigger
	;
	push	si, bp
	clr	si
	xchg	si, ds:[di].OLPWI_pinTrigger
	tst	si
	jz	afterPin
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	push	ax, dx, bp
	call	GenSendToChildren	; single child of pin group is
					;	pin trigger
	pop	ax, dx, bp
	call	WinClasses_ObjCallInstanceNoLock	; nuke pin group
afterPin:
	pop	si, bp

	mov	ax, MSG_SPEC_UNBUILD
	FALL_THRU	WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far
OLPopupWinVisUnBuild	endm

WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far	proc	far
	call	WinClasses_ObjCallSuperNoLock_OLPopupWinClass
	ret
WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupGetVisParent

DESCRIPTION:	Returns visual parent for this generic object

PASS:
	*ds:si - instance data
	es - segment of OLPopupWinClass

	ax - MSG_SPEC_GET_VIS_PARENT

	cx - ?
	dx - ?
	bp - SpecBuildFlags
		mask SBF_WIN_GROUP	- set if building win group

RETURN:
	carry - ?
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


OLPopupGetVisParent	method dynamic	OLPopupWinClass,
					MSG_SPEC_GET_VIS_PARENT
	test	bp, mask SBF_WIN_GROUP
	jnz	WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far

				; Fetch visible parent for button, in cx:dx
	mov	cx,ds:[di].OLCI_visParent.handle
	mov	dx,ds:[di].OLCI_visParent.chunk
	
	;
	; If there the generic parent is set here, we'll call our superclass to
	; determine the visual parent.  The genView will cause this to be
	; set zero when handling GQT_BUILD_INFO so that this will happen.
	; 10/24/91 cbh
	;
	push	si
	call	GenFindParent
	cmp	dx, si
	jne	10$
	cmp	cx, bx
10$:
	pop	si
	jne	90$			;something other than gen parent, exit

	push	si
	call	GenSwapLockParent
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT_FOR_CHILD
	call	ObjSwapUnlock
	pop	si
	jz	15$
	
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	call	GenCallParent
	jc	20$
15$:
	push	si			;in case not answered, store parent
	call	GenFindParent
	mov	cx, bx
	mov	dx, si
	pop	si
20$:
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLCI_visParent.handle, cx
	mov	ds:[di].OLCI_visParent.chunk, dx
90$:
	stc
	ret

OLPopupGetVisParent	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupGetSpecificVisObj

DESCRIPTION:	Returns top visible object that this generic object has turned
		into.  Used to help position new object that are being added
		near this one.

PASS:
	*ds:si - instance data
	es - segment of OLPopupClass

	ax - MSG_SPEC_GET_SPECIFIC_VIS_OBJECT

	cx - ?
	dx - ?
	bp - SpecBuildFlags (SBF_WIN_GROUP set if querying for win groups)

RETURN:
	carry 	- set
	cx:dx	- Either this object or button object, depending on
		  VBG_WIN_GROUP flag passed
	bp	- ?

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


OLPopupGetSpecificVisObj 	method dynamic	OLPopupWinClass,
					MSG_SPEC_GET_SPECIFIC_VIS_OBJECT

	call	WinClasses_Mov_CXDX_Self
				; If looking for win group
	test	bp, mask SBF_WIN_GROUP
	jnz	thisObj

 	mov	dx, ds:[di].OLPWI_button	; return button object
	tst	dx				; unless null
	jz	noObj

thisObj:
	stc
	ret

noObj:
	clr	cx
	clr	dx
	stc
	ret

OLPopupGetSpecificVisObj 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopupGetMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes any minimum size requirements for dialogs

CALLED BY:	MSG_VIS_COMP_GET_MINIMUM_SIZE
PASS:		*ds:si	= OLPopupWinClass object
		ds:di	= OLPopupWinClass instance data
		ds:bx	= OLPopupWinClass object (same as *ds:si)
		es 	= segment of OLDialogWinClass
		ax	= message #

RETURN:		cx	= min width for compsite
		dx	= Min height of composite
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	10/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopupDestroyAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle specific-UI part of this -- take off screen, make
		sure no FTVMC, gadget, etc. exclusives, no app GCN etc.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_DESTROY_AND_FREE_BLOCK

RETURN:		carry set, to use optimized approach

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLPopupDestroyAndFreeBlock 	method dynamic	OLPopupWinClass,
				MSG_GEN_DESTROY_AND_FREE_BLOCK

	; If a button's been created for this window, then there's more 
	; unbuilding to be done than meets the eye (remaining visible
	; linkage after dismiss, geometry, etc.)
	; Return flag indicating non-optimial, full unbuild needed.
	;
	tst    ds:[di].OLPWI_button
	jnz	slowWay


;	Call the superclass to knock the dialog off the screen if it is still
;	up, and nuke any objects it may have in other blocks (like window
;	menus).

	mov	di, offset OLPopupWinClass
	call	ObjCallSuperNoLock

	call	CleanUpObjBlockForNukage

	stc			; successful.
	ret

slowWay:
	clc			; no optimization -- destroy the slow way
	ret
OLPopupDestroyAndFreeBlock 	endp

CleanUpObjBlockForNukage	proc	near
	; Get us off any active lists we think we might still be on.
	; Remember that no objects within the block are on an active list,
	; or this routine wouldn't have been called in the first place.
	; We're also off-screen, meaning nothing is visible, has the focus,
	; target, or mouse grab.

	mov	ax, GAGCNLT_WINDOWS
	call	TakeObjectsInBlockOffList
	ret
CleanUpObjBlockForNukage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopupDiscardBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the block containing this object

CALLED BY:	GLOBAL
PASS:		*ds:si - OLPopup object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPopupDiscardBlock	method	dynamic OLPopupWinClass,
			MSG_OL_POPUP_DISCARD_BLOCK
	.enter

	mov	ax, TEMP_INTERACTION_DISCARD_INFO
	call	ObjVarFindData

	; This *should've* been added by OLPopupInitiate - if it's gone for
	; some reason, then just exit.

EC <	ERROR_NC	OL_ERROR					>
NEC <	jnc	cannotDiscard						>

;	If the object is on screen, or if we're waiting for more discards to
;	come through the queue, just exit.

EC <	tst	ds:[bx].GIDI_discardCount				>
EC <	ERROR_Z	-1							>
	dec	ds:[bx].GIDI_discardCount
	jnz	cannotDiscard
	tst	ds:[bx].GIDI_inUse
	jnz	cannotDiscard


;	If for some reason there is a button hanging around for this object,
;	we cannot discard it, so don't bother trying.

	tst	ds:[di].OLPWI_button
	jnz	cannotDiscard

	tst	ds:[OLMBH_inUseCount]		;If the block is in-use, we
	jnz	cannotDiscard			; cannot discard it.

;	Check to see if something in this block is on the active list.
;	If so, we can't discard it, so exit.

	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	mov	ss:[bp].GCNLP_optr.chunk, 0
	mov	ax, MSG_META_GCN_LIST_FIND_ITEM
	clr	bx
	call	GeodeGetAppObject
	mov	dx, size GCNListParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	mov	bp, sp
	lea	bp, ss:[bp + size GCNListParams]
	mov	sp, bp
	jc	cannotDiscard

;	Queue up a message to the process to discard this block. Must insert
; 	the message at the front of the queue to avoid having any other
;	messages sneak in before the block is discarded.

	clr	bx
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo		;BX <- current process handle

	mov	ax, MSG_PROCESS_OBJ_BLOCK_DISCARD
	mov	cx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

	call	CleanUpObjBlockForNukage
cannotDiscard:
	.leave
	ret
OLPopupDiscardBlock	endp


WinClasses	ends

;-------------------------------

WinMethods	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPWMetaCheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the popup window is sys modal, in which case it
		should always be interactable.

CALLED BY:	MSG_META_CHECK_IF_INTERACTABLE_OBJECT
PASS:		*ds:si	= OLPopupWinClass object
		ds:di	= OLPopupWinClass instance data
		ds:bx	= OLPopupWinClass object (same as *ds:si)
		es 	= segment of OLPopupWinClass
		ax	= message #
RETURN:		carry set if interactable
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPWMetaCheckIfInteractableObject	method dynamic OLPopupWinClass, 
					MSG_META_CHECK_IF_INTERACTABLE_OBJECT
		.enter

	;
	; If this dialog is sys modal, return carry set, so it will be 
	; interactable.
	;
		test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
		stc
		jnz	exit
	;
	; This dialog is not sys modal, so let the superclass decide if it
	; should be interactable or not.
	;
		mov	di, offset OLPopupWinClass
		call	ObjCallSuperNoLock
exit:		
		.leave
		ret
OLPWMetaCheckIfInteractableObject	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinFindButton -- MSG_OL_POPUP_FIND_BUTTON
		for OLPopupWinClass

DESCRIPTION:	Get handle for OLButton object which opens this popup.
		This is used by the GenPrimary to get the handle for
		the menu button which opens the system menu.

PASS:
	*ds:si - instance data
	es - segment of OLPopupWinClass

	ax - MSG_OL_POPUP_FIND_BUTTON

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax, bp - ?
	cx, dx - handle of button

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


OLPopupWinFindButton	method dynamic	OLPopupWinClass,
					MSG_OL_POPUP_FIND_BUTTON

	mov	cx, ds:[LMBH_handle]		;get handle of obj block
	mov	dx, ds:[di].OLPWI_button
	ret
OLPopupWinFindButton	endp

WinMethods	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MSG_SHOW_MENU_BUTTON/MSG_HIDE_MENU_BUTTON

DESCRIPTION:	These methods are sent from a GenDisplay to all of its generic
		children. The intent is that those children which are menus
		will hide or show their menus buttons which have been adopted
		by the GenPrimary.

PASS:		ds:*si	- instance data

RETURN:		ds, si = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

	; called directly

OLPopupWinSendToButton	method OLPopupWinClass,MSG_SHOW_MENU_BUTTON, \
						MSG_HIDE_MENU_BUTTON

	push	si
	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button
	tst	si			;does this popup window have a button?
	jz	done			;skip if not...

	call	WinClasses_ObjCallInstanceNoLock

done:
	pop	si
	ret
OLPopupWinSendToButton	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinGenActivate -- 
		MSG_GEN_ACTIVATE for OLPopupWinClass

DESCRIPTION:	Handles MSG_GEN_ACTIVATE, usually a result of a keyboard
		moniker being pressed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ACTIVATE

RETURN:		nothing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/22/91		Initial version

------------------------------------------------------------------------------@

OLPopupWinGenActivate	method dynamic OLPopupWinClass, MSG_GEN_ACTIVATE
	mov	di, ds:[di].OLPWI_button
	tst	di			;does this popup window have a button?
	jz	noButtonYet		;skip if not...

	mov	si, di			;else send to button
	call	WinClasses_ObjCallInstanceNoLock
	jmp	short done
	
noButtonYet:
	;
	; Button is apparently not yet built.  Send an initiate to ourselves.
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
done:
	call	WinClasses_ObjCallInstanceNoLock
	ret
OLPopupWinGenActivate	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupInitiateBlockingThreadOnResponse

DESCRIPTION:	Called to cause this popup to be placed up on screen, but
	in a manner as initiated by the application in the routine
	UserDoDialog.  The application will shortly be blocked on a semaphore,
	& will not be freed until this object V's the semaphore.  It has
	conveniently passed us a ptr to this semaphore.  We store it, &
	then wait for MSG_GEN_GUP_INTERACTION_COMMAND (sent up by some trigger
	which dismisses any interaction group it is in), at which point
	we stuff data to be passed to the application into the structure
	that was passed earlier, & then V the semaphore in it, to let the
	application thread continue.


PASS:
	*ds:si - instance data
	es - segment of OlPopupClass

	ax - MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_REPSONSE

	cx 	- ?
	dx:bp	- far ptr to UserDoDialogStruct

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
	Doug	8/89		Initial version

------------------------------------------------------------------------------@


OLPopupInitiateBlockingThreadOnResponse	method dynamic	OLPopupWinClass,
			MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE
EC <	push	di							>
EC <	call	WinClasses_DerefVisSpec_DI				>
EC <	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL >
EC <	ERROR_Z	OL_ERROR_CANT_USE_DO_DIALOG_ON_NON_MODAL_OBJECTS	>
EC <	tst	ds:[di].OLPWI_udds.segment				>
EC <	ERROR_NZ	CANNOT_CALL_USER_DO_DIALOG_WITH_SAME_DIALOG_TWICE >

EC <	call	WinClasses_DerefGen_DI				>
EC <	test	ds:[di].GII_attrs, mask GIA_INITIATED_VIA_USER_DO_DIALOG >
EC <	ERROR_Z	OL_ERROR_CANT_USE_DO_DIALOG_ON_NON_MODAL_OBJECTS	>
EC <	pop	di							>

	; If dialog is run by the global UI thread, then we must force
	; sys-modal, to reflect the UI's status as a system-wide application
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo		; ax = exec thread
	mov	bx, handle ui		; bx = ui process
	call	ProcInfo		; bx = global ui thread
	cmp	ax, bx			; run by UI thread?
	jne	notRunByUI
	call	WinClasses_DerefVisSpec_DI
	andnf	ds:[di].OLPWI_flags, not mask OLPWF_APP_MODAL
	ornf	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
notRunByUI:

				; Store pointer to semaphore
	call	WinClasses_DerefVisSpec_DI
	movdw	ds:[di].OLPWI_udds, dxbp

	; If the dialog box isn't even enabled, don't bring it up.
	;
   	call	VisCheckIfFullyEnabled	; is the dialog box enabled?
	jnc	terminateDoDialog	; no, exit
	
	; Now, before allowing the application to block, let's check to
	; make sure there aren't any unusual circumstances, such as being
	; in the middle of an ATTACH or DETACH.  If so, we alter the 
	; standard behavior....
	;
	push	dx, bp
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication
	pop	es, di			; es:di = UserDoDialogStruct

	; If application is attaching, & UserDoDialog was called by the UI
	; thread, promote dialog to be system modal, to ensure that it
	; will get the focus, appear above any "Activating" dialog, & not
	; have a cursor above it in the case that the application will
	; be blocked from being able to finish attaching.
	;
	test	al, mask AS_ATTACHING
	jz	afterAttachCheck
	tst	es:[di].UDDS_boxRunByCurrentThread
	jz	afterAttachCheck
	call	WinClasses_DerefVisSpec_DI
	andnf	ds:[di].OLPWI_flags, not mask OLPWF_APP_MODAL
	ornf	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
afterAttachCheck:

	; If application is detaching, don't allow dialog to come up at all -
	; if asked to detach, we don't ask questions, we just do it.
	;
	test	al, mask AS_DETACHING
	jnz     terminateDoDialog

	; If in the app-cache, don't allow UserDoDialogs at all -- from the
	; user's point of view, this app isn't even running, so they
	; should not be subjected to dialogs from it.  Will also keep the
	; code from blocking in a UserDoDialog, thereby keeping locks blocked
	; on the heap in the background.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_TRANSPARENT_DETACH_LIST
	call	UserCallApplication
	cmp	ax, GCNSLT_TRANSPARENT_DETACH		; see if app hidden
	je	terminateDoDialog			; in app cache

					; Else cause dlg box to come up.

	mov	ax, MSG_META_GCN_LIST_ADD		; Add ourselves to the
	call	AddRemoveGCNListCommon			; associated GCN list
	mov	ax, MSG_GEN_INTERACTION_INITIATE	; Bring'er up.
	call	WinClasses_ObjCallInstanceNoLock

	;
	; ask field to make sure that there is a focus (this fixes a problem
	; where a restored app puts up a UserDoDialog during its restore
	; (before getting focus) causing that dialog never to become the focus)
	;
	mov	cx, segment OLFieldClass
	mov	dx, offset OLFieldClass
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock	; ^lcx:dx = OLField, or null
					; (null if UIApp dialog)
	movdw	bxsi, cxdx
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	clr	di
	GOTO	ObjMessage

terminateDoDialog:
	clr	cx
.assert IC_NULL eq 0
	mov	ax, MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE
	call	WinClasses_ObjCallInstanceNoLock
	ret

OLPopupInitiateBlockingThreadOnResponse	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	AddRemoveGCNListCommon

DESCRIPTION:	Add/remove this object to/from an Application GCN list

CALLED BY:	INTERNAL
PASS:		*ds:si	- this object
		ax	- MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@

AddRemoveGCNListCommon	proc	near	uses	ax, bx, cx, dx, bp, si
	.enter
	sub	sp, size GCNListParams	; create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_USER_DO_DIALOGS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	dx, size GCNListParams	; create stack frame

;	Send the method to the application object

	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	exit
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	add	sp, size GCNListParams	; fix stack
	.leave
	ret
AddRemoveGCNListCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPopupReleaseBlockedThreadWithResponse

DESCRIPTION:	Terminate any UserDoDialog in progress for this window,
		unblocking thread.  This does not dismiss the dialog.  This
		can be done with MSG_GEN_GUP_INTERACTION_COMMAND and IC_DISMISS
		or IC_INTERACTION_COMPLETE (the latter always dismisses a modal
		dialog, which is required for UserDoDialog).

CALLED BY:	INTERNAL
		OLPopupGenDismiss

PASS:
	*ds:si - instance data
	es - segment of OLPopupClass

	ax 	- MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE

	cx	- InteractionCommand

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
	Doug	6/90		Initial version
------------------------------------------------------------------------------@

OLPopupReleaseBlockedThreadWithResponse	method dynamic	OLPopupWinClass,
		MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE

EC <	push	di							>
EC <	call	WinClasses_DerefVisSpec_DI				>
EC <	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL >
EC <	ERROR_Z	OL_ERROR_CANT_USE_DO_DIALOG_ON_NON_MODAL_OBJECTS	>
EC <	call	WinClasses_DerefGen_DI					>
EC <	test	ds:[di].GII_attrs, mask GIA_INITIATED_VIA_USER_DO_DIALOG >
EC <	ERROR_Z	OL_ERROR_CANT_USE_DO_DIALOG_ON_NON_MODAL_OBJECTS	>
EC <	pop	di							>

	;Remove ourselves from the associated GCN list
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddRemoveGCNListCommon
	;
	; Fetch pointer to UserDoDialogStruct
	;
	call	WinClasses_DerefVisSpec_DI
	mov	bx, ds:[di].OLPWI_udds.segment
	tst	bx		;Exit if we are already off-screen...	
	jz	exit

	mov	bp, ds:[di].OLPWI_udds.offset
	clr	ds:[di].OLPWI_udds.segment
	mov	es, bx		; setup es:bp as ptr to semaphore

				; Stuff reponse onto UserDoDialogStruct so can
				; be returned to application. Set this 
				; *before* setting UDDS_complete non-zero.
	mov	es:[bp].UDDS_response, cx

				; Set flag to indicate dialog has completed. 
				; This will be checked by UserDoDialog on 
				; return from this method handler if in the
				; mode where it is dispatching events itself.
	mov	es:[bp].UDDS_complete, -1

	mov	bx, es:[bp].UDDS_callingThread
	tst	bx
	jz	doSemaphore
EC <	tst	es:[bp].UDDS_semaphore					>
EC <	ERROR_NZ	OL_ERROR					>

	mov	ax, MSG_META_DUMMY	;Force a message through the
	clr	di			; queue, in case the other thread
	call	ObjMessage		; is in dispatch-mode, so it will
					; wake up and realize that the
					; dialog has come down.
exit:
	ret

doSemaphore:

;	The thread that UserDoDialog was called from had no event queue, so
;	V the semaphore instead.

	mov	bx, es:[bp].UDDS_semaphore

	;We must have a calling thread, or a semaphore, otherwise there is no
	; way to wake up the caller.	
EC <	tst	bx						>
EC <	ERROR_Z	OL_ERROR					>

	call	ThreadVSem	; Let application continue
	jmp	exit
OLPopupReleaseBlockedThreadWithResponse	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupActivate

DESCRIPTION:	Handle internal activation.

PASS:
	*ds:si - instance data
	es - segment of OlPopupClass

	ax - MSG_OL_POPUP_ACTIVATE

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
	brianc	8/27/92		Initial version

------------------------------------------------------------------------------@

OLPopupActivate	method dynamic	OLPopupWinClass, MSG_OL_POPUP_ACTIVATE
	;
	; allow subclassing of MSG_GEN_INTERACTION_INITIATE
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	WinClasses_ObjCallInstanceNoLock
	ret
OLPopupActivate	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupGenInitiate

DESCRIPTION:	Causes the popup window to be placed up on screen.  This
		method dynamic may be sent both internally by the UI & by the
		application.  This turns around & calls a local method to
		do the operation.  Why was this done this way?  I think
		just because the method had been defined locally...  Oh, well,
		this does give us a little more flexibility in the future,
		but for now the generic & specific implementations are the
		same.

PASS:
	*ds:si - instance data
	es - segment of OlPopupClass

	ax - MSG_GEN_INTERACTION_INITIATE

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
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLPopupGenInitiate	method dynamic	OLPopupWinClass, \
					MSG_GEN_INTERACTION_INITIATE

	;first check status of this window

	clr	cx			;allow optimized check
	call	GenCheckIfFullyUsable	;Check to see if we're fully USABLE
	jnc	done			;skip to end if not...

	;
	; if window is OWA_DISMISS_WHEN_DISABLED, ignore initiate requests
	; if disabled
	;
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_DISMISS_WHEN_DISABLED
	jz	notDismissWhenDisabled
	clr	cx			;allow optimized check
	call	GenCheckIfFullyEnabled	;carry set if so
	jnc	done			;not fully enabled, ignore request
notDismissWhenDisabled:

if _ISUI
	; If opening modal dialog, close stay up menus
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL
	jnz	closeMenus
	test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
	jz	notModal
closeMenus:
	call	OLReleaseAllStayUpModeMenus
notModal:
endif

	;if window is not yet visible, and OWFA_LONG_TERM, set OLWSS_PINNED

OLS <	CallMod	OLPopupWinSetPinnedIfLongTerm				>

					;set REALIZABLE if not that way
					;already.  Bring up on screen, raise
					;to top.
	call	OpenWinEnsureRealizableOnTop
	jz	done			;skip if not visible...

	mov	ax, HINT_INTERACTION_DISCARD_WHEN_CLOSED
	call	ObjVarFindData
	jnc	done

	; The interaction is marked as wanting to be discarded when closed.
	; Do some error-checking here, and tell the interaction that we are
	; onscreen.

	mov	ax, MSG_GEN_INTERACTION_DISABLE_DISCARDING
	call	ObjCallInstanceNoLock
	
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Gen_offset					>
EC <	test	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE	>
EC <	ERROR_Z	DISCARDABLE_INTERACTION_MUST_NOT_BE_USER_INITIATABLE	>

	; Ensure that there is only a one-way link to the parent
EC <	mov	cx, ds:[LMBH_handle]					>
EC <	mov	dx, si							>
EC <	mov	ax, MSG_GEN_FIND_CHILD					>
EC <	call	GenCallParent						>
EC <	ERROR_NC	DISCARDABLE_INTERACTION_MUST_HAVE_ONE_WAY_LINK	>
	
done:
	ret
OLPopupGenInitiate	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupTogglePushpin -- MSG_OL_POPUP_TOGGLE_PUSHPIN
				for OLPopupWinClass

DESCRIPTION:	Toggles pushpin on menu or popup window.

PASS:
	*ds:si - instance data
	es - segment of OlPopupClass
	ax - METHOD
	bp = (when toggling to unpin menu) TRUE if menu should be dismissed.

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
	Doug	5/89		Initial version

------------------------------------------------------------------------------@


OLPopupTogglePushpin	method dynamic	OLPopupWinClass,
					MSG_OL_POPUP_TOGGLE_PUSHPIN

	;See if popup is pinned or not

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	LONG	jnz unPin			;skip if so to unpin it...

	;PIN this popup window ################################################

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	pinMenu			;skip if is menu or submenu...

	;pin a popup window

	ORNF	ds:[di].OLWI_specState, mask OLWSS_PINNED
OLS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_SHADOW)		>
OLS <	ORNF	ds:[di].OLWI_attrs, mask OWA_MOVABLE or mask OWA_TITLED >
CUAS <	ORNF	ds:[di].OLWI_attrs, mask OWA_MOVABLE or mask OWA_TITLED \
						or mask OWA_HAS_SYS_MENU >

	;set state flag so that header is redrawn.

OLS <	mov	cl, mask OLWHS_HEADER_MARK_IMAGES_INVALID		>
OLS <	call	OpenWinHeaderMarkInvalid				>
	jmp	done			;skip to end...

pinMenu:
if _MENUS_PINNABLE	;------------------------------------------------------
	;Change the window's priority from menu to command dialog

	call	VisQueryWindow		;Fetch window handle
	tst	di
	LONG	jz afterPrioSet		;skip if no window...

	mov	ax, WIN_PRIO_COMMAND
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

	;set PINNED, and allow menu to be moved off-screen
	;IMPORTANT: IF YOU CHANGE THIS CODE, CHANGE OpenWinUpdatePinnedMenu also

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_specState, mask OLWSS_PINNED \
				     or mask OLWSS_NOTIFY_TRIGGERS_IS_PINNED

	;release focus window exclusive, since this menu is effectively
	;a child of the Primary. IMPORTANT: do this AFTER you have set
	;the PINNED flag, because the focus will be restored to some other
	;object in the Primary, and it will grab the Gadget Exclusive.
	;(Do not use OpenWinReleaseFocusExcl, because it will see that PINNED
	;is true, and will assume the GenApplication is the focus parent node)

	call	WinClasses_Mov_CXDX_Self
	mov	bp, mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	OLMenuWinCallButtonOrGenParent

	;do some UI-specific stuff:
	;	OpenLook: enable borders on all triggers
	;	CUA/Motif: create system menu

	call	OpenWinUpdatePinnedMenu
					;see OpenLook/Win/winClassSpec.asm and
					;and CommonUI/CWin/cwinClassCUAS.asm
EC <	ERROR_NC OL_ERROR		;must have handled.		>

	;tell our menu button to make sure that it is reset visually

	mov	ax, MSG_OL_MENU_BUTTON_NOTIFY_MENU_DISMISSED
	call	OLPopupWinSendToButton

pinMenu2:
if _CUA_STYLE		;------------------------------------------------------
	;make PinTrigger NOT_USABLE

	mov	di, offset OLPWI_pinTrigger
					;pass offset to object chunk handle
					;in instance data
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE \
					or mask VA_MANAGED) shl 8
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_MANUAL		;object will be updated later
	call	SendToObjectAndItsChildren

	;update separators in this menu (will set geometry invalid if necessary)

	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	call	WinClasses_ObjCallInstanceNoLock

	;set state flag so that header is redrawn.

	mov	cl, mask OLWHS_SYS_ICON_IMAGES_INVALID
	call	OpenWinHeaderMarkInvalid
endif			;------------------------------------------------------

	;now set the geometry of this menu invalid, since some attribute
	;bits (and possibly menu items) have changed.

	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE ;reset the geometry of window
	clr	bp				;use DESIRED_SIZE
	mov	dl, VUM_NOW
	call	WinClasses_ObjCallInstanceNoLock

	;code added by Eric 10/24/90 to force temporarily un-pinned menu
	;to release mouse and window grabs as it gets re-pinned.

	mov	ax, MSG_OL_WIN_END_GRAB
	clr	cx				;don't force release of grabs
	call	WinClasses_ObjCallInstanceNoLock

	;code added by Joon 3/19/99 to release gadget excl so parent menus
	;will close.
	
	call	OLMenuWinReleaseRemoteGadgetExcl

	;Code added by chris 5/22/90 in the hopes that the menu button
	;will be unhighlighted.
	;IMPORTANT: keep this code, as it allows us to kill stay up mode
	;when a key is pressed in a temporarily un-pinned menu.

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE
	jz	skipToDone			;skip if not...

	mov	ax, MSG_MO_MW_LEAVE_STAY_UP_MODE
	call	WinClasses_ObjCallInstanceNoLock

skipToDone:

endif 		;(MENUS_PINNABLE)----------------------------------------------
	ret

;##############################################################################
unPin:	;if menu or submenu, unpin it

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	unPinMenu		;skip if is menu or submenu...

	;unpin a popup window: Close the interaction (toggling of pushpin is
	;a user request, which might possibly be overriden, or verified by app)
	;(DO NOT RESET PINNED STATE FLAG)

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	WinClasses_ObjCallInstanceNoLock
	ret

unPinMenu:

	;Change the window's priority from command back to menu

	call	VisQueryWindow			; Fetch window handle
	tst	di
	jz	afterPrioSet

	mov	ax, WIN_PRIO_POPUP
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

afterPrioSet:
	;Mark as not pinned

if _MENUS_PINNABLE	;------------------------------------------------------
	push	bp			;save bp flags for later

	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	WinClasses_ObjCallInstanceNoLock
					;release focus window exclusive,
					;as child of GenApplication

	;set NOT PINNED etc.

	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_specState, not mask OLWSS_PINNED
OLS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_MOVABLE or mask OWA_TITLED) >
CUAS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_MOVABLE or \
				mask OWA_TITLED or mask OWA_HAS_SYS_MENU ) >
OLS <	ORNF	ds:[di].OLWI_attrs, mask OWA_SHADOW			>

	;keep menu on-screen in future

	ANDNF	ds:[di].OLWI_winPosSizeFlags, not (mask WPSF_CONSTRAIN_TYPE)
	ORNF	ds:[di].OLWI_winPosSizeFlags, \
			(WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE)

	;if window is not being dismissed, 

	pop	bp
	push	bp
	tst	bp			;will menu be dismissed?
	jnz	willClose		;skip if so...

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	WinClasses_ObjCallInstanceNoLock
willClose:

if _CUA_STYLE		;------------------------------------------------------

	;if pinnable (may temporarily not be) then make PinTrigger USABLE

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	80$

	call	OLMenuWinEnsurePinTrigger
					;create Pin trigger object
					;if necessary

	;mark the PinTrigger as WINDOW_INVALID, so that the invalid
	;path flags get set up the visible tree.

	push	si
	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_pinTrigger
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>

	call	WinClasses_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL
	pop	si

	mov	di, offset OLPWI_pinTrigger
					;pass offset to object chunk handle
					;in instance data
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_MANAGED)
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_MANUAL		;object will be updated later
	call	SendToObjectAndItsChildren

	;update separators in this menu (will set geometry invalid if necessary)

	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	call	WinClasses_ObjCallInstanceNoLock

80$:
	;Need to mark the geometry invalid so the header is taken into account
	;the next time the thing appears on screen

;	call	WinClasses_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL
	;
	; WHY ISN'T GEOMETRY MARKED INVALID AS THE COMMENT CLAIMS?
	; (fixes problems with pinned menus restored from state)
	; - brianc 6/1/93
	;
	mov	cl, mask VOF_WINDOW_INVALID or mask VOF_GEOMETRY_INVALID
	call	WinClasses_VisMarkInvalid_MANUAL

endif			;------------------------------------------------------

	pop	bp				;get CLOSE flag
	tst	bp
	jz	done				;skip to keep open...

	;recalc geometry in this window, so will appear correctly next time.

OLS <	mov	ax, MSG_VIS_RESET_WIN_GROUP_GEOMETRY	;reset the geometry of window >
OLS <	clr	bp				;use DESIRED_SIZE	>
OLS <	mov	dl, VUM_NOW						>
OLS <	call	WinClasses_ObjCallInstanceNoLock				>

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	WinClasses_ObjCallInstanceNoLock
endif		;(_MENUS_PINNABLE)---------------------------------------------

	;(if menus not pinnable, we just ignore this method)

done:
	ret
OLPopupTogglePushpin	endp



if _MENUS_PINNABLE and _CUA_STYLE
SendToObjectAndItsChildren	proc	near
	push	ax, cx, dx, di
	call	OLCallSpecObject
	pop	ax, cx, dx, di

	push	si			;send this to the object's children
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset	;VisInstance
	add	si, di			;offset to object handle
	mov	si, ds:[si]		;get it
	tst	si
	jz	noObj
	call	VisSendToChildren
noObj:
	pop	si
	ret
SendToObjectAndItsChildren	endp
endif


WinClasses	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupClose

DESCRIPTION:	Handle specific UI close message by sending
		MSG_GEN_GUP_INTERACTION_COMMAND with IC_DISMISS to self.

PASS:
	*ds:si - instance data
	es - segment of OLPopupClass

	ax 	- MSG_OL_WIN_CLOSE

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
	brianc	3/3/92		Initial version

------------------------------------------------------------------------------@
OLPopupClose	method	dynamic	OLPopupWinClass, MSG_OL_WIN_CLOSE
	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE	; closable?
	jz	done					; NOT!
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock
done:
	ret
OLPopupClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopupTestWinInteractibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Message called on modal window by application object to
		find out whether or not the window passed is considered 
		"part" of the modal window, i.e. whether it should be
		interactable or not.  This is the mechanism by which sub-windows
		& popup windows of a modal dialog box are allowed to be
		interacted with.  The default handler here should cover the
		cases of GenView's & popup lists within the window.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_INTERACTION_TEST_WIN_INTERACTIBILITY

		^lcx:dx	- InputOD of window to check
		^hbp	- Window to check

RETURN:		carry	- set if mouse allowed in window, clear if not.

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

	* Popup list case not handled yet!!! *

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLPopupTestWinInteractibility	method dynamic	OLPopupWinClass, \
				MSG_META_TEST_WIN_INTERACTIBILITY
	tst_clc	cx			; if no InputOD, mouse can't interact
	jz	exit

	; Default behavior is to allow interaction with the current modal
	; window itself.
	;
	cmp	cx, ds:[LMBH_handle]
	jne	notSelf
	cmp	dx, si
	stc
	je	exit
notSelf:

	; Next, figure out if this is a child window which has been passed
	;
	mov	di, bp			; get window passed
	push	si
	mov	si, WIT_PARENT_WIN	; & find it's parent
	call	WinGetInfo
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].VCI_window	; see if us
	stc
	je	exit			; if so, let mouse interact with it

	; OK, next, a tough one:  Is the user walking a menu (or a popup
	; list) coming from this dialog?  If so, we must let the mouse in to
	; make this possible.
	;
	; Assumptions made in the following code:
	;
	;	1) When a modal dialog comes up, all non-pinnned menus
	;	   will be dismissed.  Thus, if the window we've
	;	   been passed is indeed a non-pinned menu,
	;	   then the only possibility is that it indeed came from this
	;	   dialog box, & thus must be OK for the user to enter.
	;
	;	2) This specific UI won't allow the pinning of menus
	;	   coming from a modal dialog.  This being established,
	;	   we don't have to worry about the case of pinned menus, i.e.
	;	   they will always be non-interactable while a modal window
	;	   is up.
	;
	; Our check is then simple:  If the passed window is a meneu that is
	; not pinned, then it is interactable.
	;
	mov	bx, cx
	mov	si, dx
					; First, make sure we can make this
					; check -- if not, then just return
					; not interactable.
	call	ObjTestIfObjBlockRunByCurThread
	clc
	jne	exit			;If not run by current thread, exclude

	call	ObjSwapLock
if _ISUI
	;
	; using same explanations as above, any menu scroller (which should
	; only appear for non-pinned menus) should be made interactable
	;
	mov	di, segment MenuWinScrollerClass
	mov	es, di
	mov	di, offset MenuWinScrollerClass
	call	ObjIsObjectInClass
	jc	letHimIn		; menu scroller, let him in
endif
	mov	di, segment OLMenuWinClass
	mov	es, di
	mov	di, offset OLMenuWinClass
	call	ObjIsObjectInClass
	jnc	unlock			; if not a menu, exclude
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	unlock			; if pinned, don't let user in (carry
					; is cleared by test)
letHimIn::
	stc				; otherwise, let him in
unlock:
	call	ObjSwapUnlock		;Preserves flags

exit:
					; Well, no good reason found to believe
					; that window passed has anything to
					; do with this window, so don't let
					; mouse interact with it.
	ret


OLPopupTestWinInteractibility	endm

WinMethods	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupInteractionCommand

DESCRIPTION:	If IC_DISMISS, dismiss the interaction group.  If called from
		UserDoDialog, stuff return data & V the semaphore so that the
		application thread can continue.

PASS:
	*ds:si - instance data
	es - segment of OLPopupClass

	ax 	- MSG_GEN_GUP_INTERACTION_COMMAND

	cx	- InteractionCommand

RETURN:
	carry - set (query answered)
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLPopupInteractionCommand	method dynamic	OLPopupWinClass, \
						MSG_GEN_GUP_INTERACTION_COMMAND
	;
	; only handle IC_DISMISS and IC_INTERACTION_COMPLETE
	;
	cmp	cx, IC_DISMISS
	je	dismiss
	cmp	cx, IC_INTERACTION_COMPLETE
	je	interactionComplete
	jmp	short done

interactionComplete:
	;
	;If this is a regular popup window, ignore dismissal request if PINNED.
	;If this is a menu, since it is PINNED we know that _MENUS_PINNABLE
	;is TRUE. Therefore perform same test.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	done			; if so, ignore dismissal request
	;
	; Dismiss the popup and unblock, if needed.  Normally,
	; IC_INTERACTION_COMPLETE shouldn't unblock.  This is true for
	; OLDialogWinClass.  Since OLPopupWinClass doesn't support other
	; InteractionCommands to unblock with, we'll unblock on both
	; IC_DISMISS (below) and IC_INTERACTION_COMPLETE (here)
	;
	; Send IC_DISMISS to ourselves to do this so that subclasses that
	; need to do special stuff on IC_DISMISS can get them done, when
	; dismissing from IC_INTERACTION_COMPLETE.  OLDialogWinClass handles
	; IC_INTERACTION_COMPLETE by itself, so it doesn't use this code (which
	; would result in the undesired unblocking with IC_DISMISS).
	;
	mov	cx, IC_DISMISS
	call	WinClasses_ObjCallInstanceNoLock

dismiss:
	;HACK: if this is a menu, force it out of stay-up-mode. This situation
	;occurs when the user triple-clicks on the system menu button.
	;The third click opens the system menu again, and then the menu button
	;loses the GADGET exclusive (as the base window closes). The system
	;menu is forced to close, but because it is set as IN_STAY_UP_MODE,
	;the MSG_OL_WIN_END_GRAB handler does not release the window grab
	;as it should.

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	10$			;skip if not a menu...

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	done			;abort if is pinned...

	mov	ax, MSG_MO_MW_LEAVE_STAY_UP_MODE
	call	WinClasses_ObjCallInstanceNoLock

10$:
	;
	; Handle IC_DISMISS by dismissing and unblocking with IC_DISMISS
	;
	call	OLPopupDismiss
	;
	; If this GenInteraction was displayed with UserDoDialog,
	; unlock application thread and return IC_DISMISS response.
	;
	call	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLPWI_udds.segment
	jz	done
	mov	cx, IC_DISMISS		; else, unblock and return IC_DISMISS
					;	response
	mov	ax, MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE
	call	WinClasses_ObjCallInstanceNoLock
done:
	stc				; query answered (stop gup)
	ret
OLPopupInteractionCommand	endp

;
; pass:
;	ds:si - OLPopupWin or subclass
;
OLPopupDismiss	proc	far
	class	OLPopupWinClass

	;
	; make non-visible
	;
	clr	cl
	mov	ch, mask SA_REALIZABLE
	call	WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW

;	Now, the object is off-screen, so check to see if it needs to be
;	discarded.

	mov	ax, HINT_INTERACTION_DISCARD_WHEN_CLOSED
	call	ObjVarFindData
	jnc	noDiscard

	mov	ax, TEMP_INTERACTION_DISCARD_INFO
	call	ObjVarFindData

	; This *should've* been added by OLPopupInitiate - if it's gone for
	; some reason, then just exit.

EC <	ERROR_NC	OL_ERROR					>
NEC <	jnc	noDiscard						>

	clr	ds:[bx].GIDI_inUse
	inc	ds:[bx].GIDI_discardCount

;	Queue up a message that tells the object to discard itself after
;	having flushed the input queue.

	mov	ax, MSG_OL_POPUP_DISCARD_BLOCK
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	mov	cx, di
	mov	dx, ds:[LMBH_handle]
	clr	bp
	call	ObjCallInstanceNoLock
noDiscard:
	ret
OLPopupDismiss	endp
				   
				  
COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinVisClose

DESCRIPTION:	Handle closing of a popup window.  Basically, just call
		superclass, but before we do that, see if we are modal.
		If so, then release the application modal exclusive first,
		as this window won't exist anymore.

PASS:		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_VIS_CLOSE
		cx, dx, bp - ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Doug	1/90		Initial version

------------------------------------------------------------------------------@
				   
OLPopupWinVisClose	method dynamic	OLPopupWinClass, MSG_VIS_CLOSE
	; Call superclass to do normal stuff
		
	call	WinClasses_ObjCallSuperNoLock_OLPopupWinClass
		
	; If this is a modal window, notify app object, & sys object if
	; SYS_MODAL, that one of these types of windows has either opened,
	; closed, or changed in priority.
	;
	call	OpenWinUpdateModalStatus
		
	; Ensure Focus & Target within the application
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	GOTO	GenCallApplication

OLPopupWinVisClose	endp

				  
COMMENT @----------------------------------------------------------------------
				   
METHOD:		OLPopupUpdateVisual

DESCRIPTION:	Visually updates entire OLPopup object, including button &
		window.  We have to replace the default method because we
		utilize DUAL_BUILD.

PASS:		*ds:si 	- instance data
		es     	- segment of OLPopupClass
		ax 	- MSG_SPEC_UPDATE_VISUAL

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Doug	10/89		Initial version
				   
------------------------------------------------------------------------------@
				   
OLPopupUpdateVisual	method dynamic	OLPopupWinClass,
						MSG_SPEC_UPDATE_VISUAL
	push	dx
	push	si
	mov	si, ds:[di].OLPWI_button		; fetch chunk of button
	tst	si
	jz	OLPDVU_80
		
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP	; update button part
	call	WinClasses_ObjCallInstanceNoLock
		
OLPDVU_80:
	pop	si
	pop	dx
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP	; update win group part
	GOTO	WinClasses_ObjCallInstanceNoLock_Far
		
OLPopupUpdateVisual	endp
				   
				   
				   
				  
COMMENT @----------------------------------------------------------------------
				   
METHOD:		OLPopupWinNotifyEnabled --
		MSG_SPEC_NOTIFY_ENABLED for OLPopupWinClass

DESCRIPTION:	Notifies the object that a parent above has been enabled.
		Re-calc's its fully-enabled bit and does anything else
		appropriate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
		mask NEF_STATE_CHANGING if this is the object
			getting its enabled state changed

RETURN:		carry set if visual state changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	5/10/90		Initial version
				   
------------------------------------------------------------------------------@
				   
OLPopupWinNotifyEnabled	method dynamic OLPopupWinClass,
		MSG_SPEC_NOTIFY_ENABLED
		
	;
	; if we are generic, we must make sure that we are going to
	; be enabled before sending MSG_SPEC_NOTIFY_ENABLED off to
	; button, as the default handler can't know to check back here
	; for the enabled state - brianc 9/30/92
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	5$				;not generic, just let
	;	default handler
	;	use button's
	;	VA_FULLY_ENABLED bit
	mov	cx, -1				;no optimization
	call	GenCheckIfFullyEnabled		;carry set if fully enabled
	jnc	11$				;not fully enabled, don't

	;	notify button
5$:
	push	si
	mov	si, ds:[di].OLPWI_button	;send to button as well
	tst	si
	jz	10$
	push	ax, dx
	call	WinClasses_ObjCallInstanceNoLock
	pop	ax, dx

10$:
	pop	si
11$:
	GOTO	WinClasses_ObjCallSuperNoLock_OLPopupWinClass_Far
		
OLPopupWinNotifyEnabled	endm
				   
				   
				  
COMMENT @----------------------------------------------------------------------
				   
METHOD:		OLPopupWinNotifyNotEnabled --
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLPopupWinClass

DESCRIPTION:	Notifies the object that a parent above has been disabled.
		Re-calc's its fully-enabled bit and does anything else
		appropriate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
		mask NEF_STATE_CHANGING if this is the object
			getting its enabled state changed

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	5/10/90		Initial version

------------------------------------------------------------------------------@
	
OLPopupWinNotifyNotEnabled	method dynamic OLPopupWinClass,
						MSG_SPEC_NOTIFY_NOT_ENABLED
	;
	; Send to button as well, unless we're a menu.
	;
	
if  ALLOW_ACTIVATION_OF_DISABLED_MENUS
	call	OLQueryIsMenu
	jc	callSuper			;don't disable menu buttons ever
endif

	push	si				;save popup's handler
	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button	;send to button as well	
	tst	si
	jz	checkDismiss
	push	ax, dx
	call	WinClasses_ObjCallInstanceNoLock
	pop	ax, dx
	
checkDismiss:
	pop	si				;restore popup's handle
	;
	; Not a menu, dismiss the popup window if:
	;	a) the user had HINT_DISMISS_WHEN_DISABLED, or
	;	b) the window doesn't have a system menu.
	;
	call	WinClasses_DerefVisSpec_DI

	; PCV dialogs should not disappear when set not enabled.
	;
CUAS <	tst	ds:[di].OLWI_sysMenu		;is there a system menu?     >
CUAS <	jz	dismiss				;no, definitely dismiss      >

	test	ds:[di].OLWI_attrs, mask OWA_DISMISS_WHEN_DISABLED
	jz	callSuper
dismiss:
	push	ax, dx
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	WinClasses_ObjCallInstanceNoLock
	pop	ax, dx

callSuper:
	push	ax, dx				;save method
	call	WinClasses_ObjCallSuperNoLock_OLPopupWinClass
	pop	ax, dx				;restore method
	ret
	
OLPopupWinNotifyNotEnabled	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPopupWinUpdateVisMoniker

DESCRIPTION:	If we have a button that brings us up, invalidate it so it
		shows the new moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of OLPopupWinClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

		cx, bp	- size of old moniker
		dx	- VisUpdateMode

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/21/92		Initial version

------------------------------------------------------------------------------@
	
OLPopupWinUpdateVisMoniker	method dynamic OLPopupWinClass,
				MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; call superclass for normal handling, first
	;
	push	cx, dx, bp
	mov	di, offset OLPopupWinClass
	call	ObjCallSuperNoLock
	pop	cx, dx, bp
	;
	; invalidate button, if any.  We'll invalidate image AND geomtry,
	; without bothering to see if the old and new monikers are the same
	; size.
	;	dl = VisUpdateMode
	;
	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button	; *ds:si = button
	tst	si				; is there anything here?
	jz	done				; if not, we're all done.
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	update

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	; delay to avoid nested update
update:
	mov	ax, MSG_SPEC_UPDATE_VIS_MONIKER	; pass VUM, size
	GOTO	ObjCallInstanceNoLock		; send to button
done:
	ret
OLPopupWinUpdateVisMoniker endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPopupWinSpecChangeUsable -- MSG_SPEC_SET_USABLE,
			MSG_SPEC_SET_NOT_USABLE handler.

DESCRIPTION:	We intercept this method here, for the case where this button
		is inside a menu. We want to update the separators which are
		drawn within the menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

DESTROYED:	di, si, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/27/93		Initial version

------------------------------------------------------------------------------@

OLPopupWinSpecChangeUsable method	private static OLPopupWinClass, \
						MSG_SPEC_SET_USABLE,
						MSG_SPEC_SET_NOT_USABLE

	;If this OLPopupWinClass' button is in a menu, update the separators
	;in the menu, since they might be immediately above or below this
	;button.

	cmp	ax, MSG_SPEC_SET_USABLE
	je	10$				;setting usable, can't find yet
	push	si
	call	FindButtonMenu			;look for menu of button if any
	mov	di, si
	pop	si
10$:

	;cannot use CallSuper macro, because we do not know the method #
	;at assembly time.

	push	di, ax
	mov	di, offset OLPopupWinClass
	call	ObjCallSuperNoLock
	pop	di, ax

	cmp	ax, MSG_SPEC_SET_NOT_USABLE	;set not usable, have menu.
	je	20$
	call	FindButtonMenu			;else find the button's menu.
	mov	di, si				;in ^lbx:di
20$:
	mov	si, di				;now in ^lbx:si
	tst	si				;anything to do?
	jz	done				;no, branch

	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
done:	
	ret
OLPopupWinSpecChangeUsable	endm



FindButtonMenu	proc	near
	;
	; Returns button's window in ^lbx:si.
	;
	clrdw	bxdi				; assume nothing to find
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].OLPWI_button	; *ds:si = button
	tst	si				; is there anything here?
	jz	done				; if not, we're 2all done.

EC <	push	es, di							>
EC <	mov	di, segment OLButtonClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLButtonClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	es, di							>

	push	di
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	done
	call	FindOLWin			; returns window in ^lbx:si
	mov	di, si				; stick in ^lbx:di
done:
	mov	si, di				; now in ^lbx:si
	ret
FindButtonMenu	endp

WinClasses ends
