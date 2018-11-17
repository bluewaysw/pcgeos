COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUICItem (common code for specific UIs)
FILE:		citemItemGroupVeryCommon.asm

ROUTINES:
	 Name			Description
	 ----			-----------
    INT OLItemGroupScanListForExcl 
				Scan the list entries to get the selection
				and FOCUS exclusive.  Only works for
				exclusive lists.

    INT OLItemGroupAbortAllUserInteraction 
				This routine is called when someone tries
				to move the USER exclusive. If tell the
				currently focused item to clean up its
				state relating to user interaction. We also
				pass flags indicating what to do about
				intermediate mode.

				if (FOCUS item != NEW item) { pass flag so
				currently focused item is redrawn as its
				PRESSING flag is reset.

    MTD MSG_SPEC_UPDATE_SPECIFIC_OBJECT 
				Handles updating of the specific
				representation of the item list.  This
				message assumes some change has been made.

    INT SetPopupListMonikerIfNeeded 
				If we're a popup list, and we're supposed
				to display the selected item, we'll do it
				here.

    INT EnsureCurrentSelectionVisible 
				Scrolls if necessary to ensure the current
				selection is onscreen.

    INT EnsureCurrentItemVisible 
				Scrolls if necessary to ensure the passed
				item is onscreen.

    INT UpdateItem              Updates an item based on our instance data.

    INT GetCurrentSelection     Returns optr of current selection.

    INT GetCurrentSelectionOptr Returns optr of current selection.

    INT GetOptrOrSelf           Yet another routine for getting the optr,
				maybe.  Sigh.

    INT GetItemOptr             Returns item's optr.

    INT OLItemGroupMoveFocusExclToItem 
				Moves focus exclusive if we've moved the
				selection.

    INT OLItemGroupVupGrabFocusExclForItem 
				Moves focus exclusive if we've moved the
				selection.

    INT CheckIfExtendingSelection 
				Checks to see if item group is extending
				the selection.

    INT ScanItems               Scans the list, returns an item.

    INT OLItemGroupGetFirstItemOptr 
				Returns optr of first usable and enabled
				item, if any.

    MTD MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS 
				This broadcast method is used to find the
				object within a window which has
				HINT_DEFAULT_FOCUS{_WIN}.

    MTD MSG_GEN_ITEM_GROUP_REDRAW_ITEMS 
				Redraws items as needed.

    MTD MSG_SPEC_NOTIFY_ENABLED Sent to object to update its visual enabled
				state.

    MTD MSG_SPEC_NOTIFY_NOT_ENABLED 
				Disables the text object and its cohorts,
				if needed.

    MTD MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER 
				Resets popup list moniker.

    MTD MSG_GEN_MAKE_APPLYABLE  Handles making the dialog box applyable.

    MTD MSG_GEN_RESET           Does a reset.

    MTD MSG_SPEC_CTRL_GET_LARGEST_CENTER 
				Gets the largest left-of-center, for
				properties boxes.

    MTD MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER 
				Set popup list moniker if needed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItemGroup.asm

DESCRIPTION:
	$Id: citemItemGroupVeryCommon.asm,v 1.1 97/04/07 10:55:35 newdeal Exp $

-------------------------------------------------------------------------------@
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupScanListForExcl

DESCRIPTION:	Scan the list entries to get the selection and FOCUS
		exclusive.  Only works for exclusive lists.

CALLED BY:	OLItemGroupInitialize

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupScanListForExcl	proc	far
	;place the FOCUS exclusive (for within this GenList) on the first
	;item which is USABLE.

	call	GetCurrentSelection		;ax = cur selection
	mov	bl, mask OLIGS_HAS_FOCUS_ITEM	;assume there is one
	jc	checkEnabled			;there is, branch

	clr	bx				;nope, clear flag

checkEnabled:
	call	SetFocusItem			;set as focus
					;can stuff values directly, because
					;we are in MSG_META_INITIALIZE handler.

	;return the carry set if we have established a FOCUS exclusive

	tst	bl
	clc
	jz	done			;skip if no FOCUS excl...

	stc

done:
	ret
OLItemGroupScanListForExcl	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupAbortAllUserInteraction

DESCRIPTION:	This routine is called when someone tries to move the USER
		exclusive. If tell the currently focused item to clean
		up its state relating to user interaction. We also pass
		flags indicating what to do about intermediate mode.

		if (FOCUS item != NEW item) {
			pass flag so currently focused item is redrawn as
				its PRESSING flag is reset.

CALLED BY:	OLItemGroupSetExcl

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of item we are moving the USER exclusive to.

RETURN:		ds, si, cx, dx, bp = same

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupAbortAllUserInteraction	proc	far
	push	cx, dx, bp, si

	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	exit			;no item has the focus, exit
	;
	; Get current focus, from win group since we may have been called
	; from OLItemGroupSetUserCommon, which may have scrolled the list,
 	; which invalidates any optr checks of the focus.
	;
	push	cx, dx
	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
EC <	ERROR_NC OL_ERROR		;make sure is answered		>

	cmp	ds:[LMBH_handle], cx	;is the focus on the list itself?
	jne	10$
	cmp	si, dx
	mov	bx, 0			;assume so, hack bx to pop things and
					;  get out...
	je	20$			;yes, get out!
10$:
	movdw	bxsi, cxdx		;object with focus now in ^lbx:si
20$:
	pop	cx, dx

	tst	bx			;is there a focused object
	jz	exit			;skip if none...

	mov	bp, mask OIENPF_REDRAW_PRESSED_ITEM

	cmp	cx, bx
	jne	50$
	cmp	dx, si
	jne	50$

	clr	bp			;do not redraw item when turning
					;off DEPRESSED flag

50$:	;why am I not passing OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER?

	push	cx, dx 
	mov	cx, segment OLItemClass					  
	mov	dx, offset OLItemClass					  
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				  
	call	IVC_ObjMessageCall					  
	pop	cx, dx
	jnc	exit			;not an item, just forget it.

	mov	ax, MSG_OL_ITEM_ENSURE_IS_NOT_PRESSED
	call	IVC_ObjMessageCall
exit:
	pop	cx, dx, bp, si
	ret
OLItemGroupAbortAllUserInteraction	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupUpdateSpecificObject -- 
		MSG_SPEC_UPDATE_SPECIFIC_OBJECT for OLItemGroupClass

DESCRIPTION:	Handles updating of the specific representation of the item
		list.  This message assumes some change has been made.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_SPECIFIC_OBJECT

		bp	- handle of block containing items to update
		dx	- size of list

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
	chris	2/27/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupUpdateSpecificObject	method dynamic	OLItemGroupClass, \
				MSG_SPEC_UPDATE_SPECIFIC_OBJECT

if	ERROR_CHECK
	;
	; Make sure exclusive and exclusive-none lists don't have more than 
	; one item set.
	;
	call	IsNonExclusive
	jc	EC3
	push	di
	call	IVC_DerefGenDI
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXTENDED_SELECTION
	je	EC2
	cmp	ds:[di].GIGI_numSelections, 1
	ERROR_A	OL_ERROR_EXCLUSIVE_ITEM_GROUPS_CANNOT_HAVE_MULTIPLE_SELECTIONS
EC2:
	pop	di
EC3:
endif

	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	5$
	call	OLBooleanGroupUpdateSpecificObject
	jmp	exit
5$:
	call	VisCheckIfSpecBuilt	; Make sure we're vis built.
	LONG jnc exit			; if not, quit.
 
EC <	tst	dx							>
EC <	ERROR_Z	OL_ERROR			;shouldn't happen	>

	mov	cx, dx
	shr	cx, 1				;number of items
	mov	dl, ds:[di].OLIGI_updateFlags	;get update flags to pass


	;If this list (or the child with the USER exclusive) has the FOCUS
	;exclusive, then suppress drawing of items as the USER exclusive moves.
	;This is a drawing optimization that takes advantage of the fact that
	;the FOCUS exclusive will move, forcing redraws.

	push	di
	call	IVC_DerefGenDI
	tst	ds:[di].GIGI_numSelections   ;are we setting list to empty?
	pop	di
	jz	noSuppressDraw	;skip if so (focus does not move)...

	call	IsNonExclusive
	jc	noSuppressDraw		;skip if is non-exclusive list...

	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	noSuppressDraw		;skip if do not have focus, so will
					;not move...

	;Extended selection, force a redraw.  This seems to be necessary.

	call	IsExtendedSelection
	jc	noSuppressDraw

	;
	; In toolboxes, always force the redraw, since we never have the
	; focus no matter what.  -cbh 2/18/92
	;
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	noSuppressDraw		

	;Let's make sure that a) the new current selection doesn't already have
	;the focus exclusive (which could happen, even if the selection 
	;changes, in a dynamic list when items get moved around), and b) we're
	;not in a situation where the window has lost the focus window exclusive
	;temporarily, and so should not rely on the focus mechanism to move,
	;causing visual updates.   In either of these cases, we must redraw.

	push	cx, dx, bp
	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
EC <	ERROR_NC OL_ERROR		;make sure is answered		>
	tst	bp
	jz	10$
	pushdw	cxdx			;save what is returned
	call	GetCurrentSelectionOptr	;new selection in ^lcx:dx
	popdw	axbp			;current focus in ^lax:bp now
	cmpdw	axbp, cxdx		;see if focus is staying the same
10$:
	pop	cx, dx, bp
	jz	noSuppressDraw		;skip if window DOES NOT have excl or
					;focus is NOT changing...

	ORNF	dl, mask OLIUF_SUPPRESS_DRAW
noSuppressDraw:

	;
	; If the user is pressing on an item, we'll reset all state, including
	; intermediate mode.  Unless, of course, we've set a certain flag
	; while in the process of ending intermediate mode.
	;
	mov	bx, bp				; just in case we jump
	call	MemLock				; ax = buffer segment
	clr	bp

	test	dl, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE
	jnz	updateLoop
	push	ax, bx
	call	OLItemGroupAbortAllUserInteraction
	pop	ax, bx				;segment & handle
	;
	; UpdateItem isn't documented as taking es = class of the
	; current object, but it does, and it also takes *ds:si
	; and a valid stack segment, so we're stuck swapping
	; registers a bit here.
	;
updateLoop:

	push	cx, ax				;loop counter & buffer
	push	es				;class segment
	mov	es, ax				;es:bp = buffer pointer
	mov	cx, es:[bp]			;get ID of item to select
	pop	es				;es = class segment
	push	bx
	call	UpdateItem			;update item.  Nukes everything.
	pop	bx				; mem handle
	pop	cx, ax
	inc	bp
	inc	bp				;next item in list		
	loop	updateLoop			;loop if not done

	call	MemUnlock

	;
	; Check update flags to see if we can mess with focus.  Clear the
	; update flags for next time.
	;
	call	IsNonExclusive
	jc	exit			;skip if is non-exclusive list...
	call	CheckIfExtendingSelection
	jc	exit			;extending selection, get out


	clr	dx
	call	IVC_DerefVisDI
	xchg	dl, ds:[di].OLIGI_updateFlags	;clear update flags
	test	dl, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE
	jnz	updatePopupListMoniker

	call	EnsureCurrentSelectionVisible

	;move the FOCUS exclusive to the newly selected item.
	;(THIS IS ESSENTIAL for regular, scrolling, and dynamic lists to work!
	;We have drawing optimizations that will fail if you hooey with this.)

	call	GetCurrentSelectionOptr	;cx:dx = guy to give focus to
	jnc	updatePopupListMoniker	;skip if no sel (do not reset focus!)...
	call	OLItemGroupMoveFocusExclToItem

updatePopupListMoniker:

if 0	; This make the popup list moniker flicker.  And maybe we can do
	; without it. - Joon (9/13/95)

	; RUDY
	; Delay setting the moniker, so we can get the window down.  The
	; bubble closing needs are pretty complex (read: snarled)

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
else
	call	SetPopupListMonikerIfNeeded
endif

exit:
	ret
OLItemGroupUpdateSpecificObject	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetPopupListMonikerIfNeeded

SYNOPSIS:	If we're a popup list, and we're supposed to display the 
		selected item, we'll do it here.

CALLED BY:	OLItemGroupSpecBuild, OLItemGroupUpdateSpecificObject

PASS:		*ds:si -- item group

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/29/92		Initial version

------------------------------------------------------------------------------@

SetPopupListMonikerIfNeeded	proc	far
	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	LONG	jz	exit			;get out if not popup list

if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	;
	; Rudy always displays the current selection.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	sendListMonikerToButton		;use item group moniker
endif

	test	ds:[di].VI_attrs, mask VA_REALIZED
	LONG jnz	exit			;we're onscreen, don't do it!

EC <	call	ECEnsureNotBooleanGroup					>
	call	IVC_DerefGenDI

	test	ds:[di].GIGI_stateFlags, mask GIGSF_INDETERMINATE

if POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	jnz	setBlank			;indeterminate, draw nothing
else
	jnz	sendListMonikerToButton		;indeterminate, use our mkr
endif
	
	call	GetCurrentSelectionOptr		;^lcx:dx cur selection,
						;  bp -> identifier

if POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	jcxz	setBlank			;no selection, set blank

	cmp	cx, ds:[LMBH_handle]
	jne	getMoniker
	cmp	dx, si				;if cur selection != self
	jne	getMoniker			; get item moniker

	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	setBlank			;setblank if not dynamic

	;
	; will query OD for item moniker
	;
	; must also indicate that we currently haven't got the right thing
	; displayed -- brianc 1/19/96
	;
	andnf	ds:[di].OLIGI_moreState, not mask OLIGMS_DISPLAYING_SELECTION
	mov	ax, MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
	call	ObjCallInstanceNoLock
	jmp	exit
else
	jcxz	sendListMonikerToButton		;no selectn, use item group mkr
endif

getMoniker::
	push	si, bp
	mov	bx, cx				;get moniker of selected item
	mov	si, dx
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	IVC_ObjMessageCall		;moniker in ax
	pop	si, cx				;restore item group, item ID
	mov	dl, mask OLIGMS_DISPLAYING_SELECTION
	jmp	short sendMonikerOptrToButton


if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION

sendListMonikerToButton:
	call	IVC_DerefGenDI
	mov	ax, ds:[di].GI_visMoniker		
	mov	bx, ds:[LMBH_handle]		;^lbx:ax <- item group moniker
	mov	cx, GIGS_NONE
	clr	dx				;not going to display an item
endif

sendMonikerOptrToButton:
	mov	bp, MSG_GEN_REPLACE_VIS_MONIKER_OPTR

sendMonikerToButton:	
	;
	; Set the moniker of the item group's parent window, updating if we've
	; been realized previously.   We will not set the moniker if it has
	; already been set for the identical item previously.
	;
	;	bp -- MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	;	^lbx:ax -- moniker
	;	dl -- OLIGMS_DISPLAYING_SELECTION clear if we're going to 
	; 	      display the parent, moniker.  Otherwise:
	;		cx -- item we want to represent
	; or
	;	bp -- MSG_GEN_USE_VIS_MONIKER
	;	bx -- vis moniker chunk
	;	dl -- OLIGMS_DISPLAYING_SELECTION clear if we're going to 
	; 	      display the parent, moniker.  Otherwise:
	;		cx -- item we want to represent
	;    (not being used:)
	;	bp -- MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	;	bx:ax -- pointer to the text
	;	dl -- OLIGMS_DISPLAYING_SELECTION clear if we're going to 
	; 	      display the parent, moniker.  Otherwise:
	;		cx -- item we want to represent
	;
	tst	ax				;was there a moniker?
	jz	setBlank			;no, set blank

	call	IVC_DerefVisDI
	mov	dh, dl				;selection flag in dh
	xor	dh, ds:[di].OLIGI_moreState	;see if bit matches current
	test	dh, mask OLIGMS_DISPLAYING_SELECTION
	jnz	needToSend			;bit has changed, need moniker
	tst	dl				;just doing parent?
	jz	exit				;yes, already been done, exit
	cmp	cx, ds:[di].OLIGI_displayedItem	;see if already displaying this
	je	exit				;yes, exit

needToSend:
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_DISPLAYING_SELECTION
	or	ds:[di].OLIGI_moreState, dl	;set new flag
	mov	ds:[di].OLIGI_displayedItem, cx	;and new displayed item

	mov	dx, ax				;moniker in ^lcx:dx
	mov	cx, bx
	mov	ax, bp
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE	;not onscreen don't update

	call	CallOLWin			;set moniker on OLWin

if SELECTION_BOX
	;
	; then, redraw button if needed
	;
	call	redrawSelectionBoxIfNeeded
endif

exit:
	ret

setBlank:
	clr	bx				;set a null moniker
	mov	al, VUM_DELAYED_VIA_UI_QUEUE
	mov	bp, MSG_GEN_USE_VIS_MONIKER
	mov	cx, GIGS_NONE
	clr	dx				;not displaying an item
	jmp	short sendMonikerToButton

if SELECTION_BOX
redrawSelectionBoxIfNeeded	label	near
	call	IVC_DerefVisDI
	cmp	ds:[di].OLIGI_displayedItem, -1
	je	noRedraw
	push	si
	call	VisFindParent			; ^lbx:si = parent
	cmp	bx, ds:[LMBH_handle]
	jne	exit
EC <	push	es							>
EC <	mov	di, segment OLPopupWinClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLPopupWinClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	es							>
EC <	ERROR_NC	OL_ERROR					>
	call	IVC_DerefVisDI
	mov	si, ds:[di].OLPWI_button	; *ds:si = selection box
	call	IVC_DerefVisDI			; ds:di = selection box
	call	CheckIfArrowsDisabledFar	; update arrow state
	call	OpenDrawObject
	pop	si
noRedraw:
	retn
endif

SetPopupListMonikerIfNeeded	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsureCurrentSelectionVisible

SYNOPSIS:	Scrolls if necessary to ensure the current selection is
		onscreen.

CALLED BY:	OLItemGroupUpdateSpecificObject

PASS:		*ds:si -- list

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/92		Initial version

------------------------------------------------------------------------------@

EnsureCurrentSelectionVisible	proc	far
	;
	; Let's get the current selection, and before trying to move the focus
	; there, make sure it's onscreen.  Hopefully this will cover most
	; dynamic list situations, where we need an optr (which requires the
	; item being onscreen) before continuing on.
	;
		; If we've been called, assume this is the case.
	call	IsNonExclusive
	jc	exit			;skip if is non-exclusive list...

	call	GetCurrentSelection
	jnc	exit				;no selection, done
	call	EnsureCurrentItemVisible
exit:	
	ret
EnsureCurrentSelectionVisible	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsureItemVisible

SYNOPSIS:	Scrolls if necessary to ensure the passed item is
		onscreen.

CALLED BY:	EnsureCurrentSelectionVisible
		OLItemGroupSetUserCommon

PASS:		*ds:si -- list
		ax -- item to make visible

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/92		Initial version

------------------------------------------------------------------------------@

EnsureCurrentItemVisible	proc	far
	mov	cx, ax				;cx <- item
	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE
	jz	exit
	
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	10$
	mov	ax, MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE
10$:
	GOTO	ObjCallInstanceNoLock
exit:
	ret
EnsureCurrentItemVisible	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateItem

SYNOPSIS:	Updates an item based on our instance data.

CALLED BY:	OLItemGroupUpdateSpecificObject

PASS:		*ds:si -- item group
		cx     -- identifier of item
		dl     -- OLItemUpdateFlags

RETURN:		nothing

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

UpdateItem	proc	near		uses	dx, bp, si
	.enter
	push	cx				;save item ID
	call	OLItemGroupGetItemState		;return state for item
	pop	cx				;restore item ID
	push	ax, dx
	call	GetItemOptr			;get its optr in ^lcx:dx
	mov	bx, cx				;optr in ^lbx:si
	mov	si, dx
	pop	cx, dx				;cl <- state flags
						;dl <- update flags
	jnc	exit				;can't find item, exit
	mov	ax, MSG_OL_ITEM_SET_STATE	;update the item
	call	IVC_ObjMessageCall
exit:
	.leave
	ret
UpdateItem	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupGetItemState -- 
		MSG_OL_IGROUP_GET_ITEM_STATE for OLItemGroupClass

DESCRIPTION:	Returns item state for any item, whether we're an ItemGroup
		or BooleanGroup.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_GET_ITEM_STATE

		cx	- item identifier

RETURN:		al      - OLItemState:
				OLIS_SELECTED if item is selected
				OLIS_INDETERMINATE if item is indeterminate
		ax, bp - destroyed

		if _RUDY
			carry	- set if item is the focus item

ALLOWED TO DESTROY:	
		di 	(can be called statically)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 2/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupGetItemState	method OLItemGroupClass, \
				MSG_OL_IGROUP_GET_ITEM_STATE

	; Can be called statically -- do not remove!
	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	10$
	GOTO	OLBooleanGroupGetItemState
10$:

EC <	call	ECEnsureNotBooleanGroup					>
	;
	; Set al so the item knows whether to be selected or deselected.
	; (We'll do this in an optimized way.)
	;
	call	IVC_DerefGenDI
	cmp	ds:[di].GIGI_numSelections, 1
	mov	al, 0				;assume nothing set
	jb	selectedStateSet		;no selections at all, branch
	ja	useMessage			;multiple selections, use msg
	cmp	cx, ds:[di].GIGI_selection
	je	isSelected			;selection matches, branch
	jmp	short selectedStateSet		;else not selected

useMessage:
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	push	dx
	call	ObjCallInstanceNoLock
	pop	dx
	mov	al, 0				;start with nothing set
	jnc	selectedStateSet

isSelected:
	or	al, mask OLIS_SELECTED

selectedStateSet:
	;
	; Pass indeterminate state of list.
	;
	call	IVC_DerefGenDI
	test	ds:[di].GIGI_stateFlags, mask GIGSF_INDETERMINATE
	jz	exit
	or	al, mask OLIS_INDETERMINATE
exit:
	ret
OLItemGroupGetItemState	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetCurrentSelection

SYNOPSIS:	Returns optr of current selection.

CALLED BY:	utility

PASS:		*ds:si -- item group

RETURN:		carry set if item found, with:
			ax -- current selection

DESTROYED:	cx, dx, bp, di
		Can make objects move, however.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

GetCurrentSelection	proc	far	
EC <	call	ECEnsureNotBooleanGroup					>

	call	IVC_DerefGenDI
	cmp	ds:[di].GIGI_numSelections, 1
	clc
	jne	exit				;<> 1 item selected, exit (c=0)

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		;returns cur selection in ax
	cmc
exit:
	ret
GetCurrentSelection	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetCurrentSelectionOptr

SYNOPSIS:	Returns optr of current selection.

CALLED BY:	utility

PASS:		*ds:si -- item group

RETURN:		carry set if item found
		^lcx:dx -- current selection (or if no selection)
			   (returns item group if selection is not present)
		bp -- identifier of current selection, if there is one

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

GetCurrentSelectionOptr	proc	far	uses	bx, si, ax
	.enter
	call	GetCurrentSelection
	mov	cx, 0				;assume no selection
	mov	dx, cx	
	jnc	exit				;no selection, exit
	call	GetOptrOrSelf
exit:
	.leave
	ret
GetCurrentSelectionOptr	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetOptrOrSelf

SYNOPSIS:	Yet another routine for getting the optr, maybe.  Sigh.

CALLED BY:	GetCurrentSelectionOptr
		ExtendSelection

PASS:		*ds:si -- item group	
		ax -- item to look up

RETURN:		^lcx:dx -- current selection
			   (returns item gropu if selection is not present)
		bp -- identifier or current selection if there is one

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/28/92		Initial version

------------------------------------------------------------------------------@

GetOptrOrSelf	proc	far
	mov	cx, ax				;pass item in cx
	call	GetItemOptr			;returns optr in ^lcx:dx
	mov	bp, ax				;return ID (if any) in bp
	jc	exit				;item exists, branch

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;else return ourselves
	stc
exit:
	ret
GetOptrOrSelf	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemOptr

SYNOPSIS:	Returns item's optr.

CALLED BY:	utility

PASS:		*ds:si -- item group
		cx     -- identifier of item

RETURN:		carry set if item found
		^lcx:dx -- item (null if no selection)
		ax -- item identifier, if no selection

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

GetItemOptr	proc	far		uses	bp
	.enter
	call	GetOptr
	jc	exit				;found, exit
	clr	cx				;return no selection
	mov	dx, cx	
	mov	ax, bp				;return ID in ax
exit:
	.leave
	ret
GetItemOptr	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemGroupMoveFocusExclToItem

SYNOPSIS:	Moves focus exclusive if we've moved the selection.

CALLED BY:	OLItemGroupUpdateSpecificObject

PASS:		*ds:si -- item group
		^lcx:dx -- item to give focus to 
		bp -- item identifier

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

OLItemGroupMoveFocusExclToItem	proc	far
	;
	;If the FOCUS exclusive is on this list, and we are moving the selection
	;to another item (is an exclusive list), then move the FOCUS also.
	;This even works in dynamic lists, when the selection is moving into
	;the visible region of items.
	;

	;first, see if the FOCUS for this window is on this item
	;(regardless of whether the window itself has the FOCUS_WIN_EXCL).
	;(yes, we cannot just test OLIGS_LIST_HAS_FOCUS_EXCL. Trust me...)

	push	cx, dx
	push	bp
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	call	VisCallParent
	jc	5$			;skip if answered...

	or	al, 1			;RESET Z flag, meaning that we DO NOT
	jmp	short 10$		;have the exclusive...

5$:	;^lcx:dx = the object which has the focus in this window. If is on
	;this list, or the item which this list THINKS has the focus,
	;then we can go ahead and move the FOCUS.

	cmp	cx, ds:[LMBH_handle]	
	jne	7$			;skip if not on list...

	cmp	dx, si
	je	10$			;skip if is on list (Z=1)...

7$:	
	;See if the exclusive is on an item underneath us.  We used to match 
	;the focus object with the list's notion of the focus, but in the new
	;dynamic list that has scrolled, the optr will have moved and will no
	;longer match the list's idea of things.  I'm assuming that the point
	;of any of this is to avoid moving the exclusive when the focus is 
	;on some other object entirely, so this less finicky check should still
	;accomplish what is desired.  -cbh 3/23/92   

	push	si
	movdw	bxsi, cxdx
	mov	cx, segment GenClass
	mov	dx, offset GenClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	IVC_ObjMessageCall
	jc	9$				;is a gen object, continue
	tst	si				;not gen, set Z=0
	pop	si
	jmp	short 10$
9$:
	mov	ax, MSG_GEN_FIND_PARENT
	call	IVC_ObjMessageCall		;parent in ^lcx:dx
	pop	si
	cmp	cx, ds:[LMBH_handle]	
	jne	10$			;skip if parent is NOT the list...
	cmp	dx, si

10$:	;Z flag is SET if this item or the list itself has the exclusive.

	;Whether or not this list actually has the FOCUS,
	;let's update our internal FOCUS exclusive, so that when the FOCUS
	;returns to this list, we know where to place it.

	pop	ax				;restore item getting focus
	push	ax
	pushf
	mov	bl, mask OLIGS_HAS_FOCUS_ITEM	;assume there is one
	call	SetFocusItem			;set as focus
	popf
	pop	bp				;item getting focus
	pop	cx, dx				;optr	

	jne	localRet			;skip if does not have excl...
	FALL_THRU OLItemGroupVupGrabFocusExclForItem

OLItemGroupMoveFocusExclToItem	endp

;Grab the FOCUS exclusive for the specified item  (I'll assume this takes
;  the item group in *ds:si  -chris 2/13/92)
;
; Pass:		^lcx:dx	= item to grab focus

OLItemGroupVupGrabFocusExclForItem	proc	far	uses	bx, si, di

	.enter

	call	IVC_DerefVisDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	exit			;is a toolbox, don't grab.
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	call	MetaGrabFocusExclLow
	call	ObjSwapUnlock


exit:
	.leave
localRet	label	near
	ret
OLItemGroupVupGrabFocusExclForItem	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfExtendingSelection

SYNOPSIS:	Checks to see if item group is extending the selection.

CALLED BY:	OLItemGroupSetUserCommon
		OLItemGroupUpdateSpecificObject

PASS:		*ds:si -- item group

RETURN:		carry set if extening

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/23/92		Initial version

------------------------------------------------------------------------------@

CheckIfExtendingSelection	proc	far
	call	IsExtendedSelection
	jnc	exit

	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
	jz	exit				;not extending, exit, c=0
	stc					;return c=1
exit:
	ret
CheckIfExtendingSelection	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ScanItems

SYNOPSIS:	Scans the list, returns an item.

CALLED BY:	utility

PASS:		*ds:si -- item group
		cl -- GenScanItemsFlags
		dx -- initial item
		bp -- direction

RETURN:		carry clear if nothing found, else:
			^lcx:dx -- item
			ax -- identifier

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/26/92		Initial version
	Chris	5/27/92		Rewritten to always set the navigate flags
					here.

------------------------------------------------------------------------------@

ScanItems	proc	far
	class	OLItemGroupClass

	mov	ax, MSG_GEN_ITEM_GROUP_SCAN_ITEMS
	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	10$
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SCAN_BOOLEANS
10$:
	call	ObjCallInstanceNoLock
	mov	bp, cx				;GenScanItemFlags in bp
	jnc	exit				;skip if nothing appropriate

	mov	cx, ax				;item in cx
	push	cx, bp
	call	GetItemOptr			;^lcx:dx = item
	pop	ax, bp				;restore item in ax, 	
						;    scan flags in bp

if DISABLED_ITEMS_ARE_SELECTABLE
	;
	; Skip the MSG_OL_ITEM_NAVIGATE_IF_DISABLED stuff, because 
	; disabled items can have the focus in Responder.
	;
else
	call	IVC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exitItemFound			;not dynamic, exit with found

	;In case this is a dynamic list, mark the item as needing further
	;navigation if it turns out to be disabled.

	push	ax, cx, dx, si			;save item
	movdw	bxsi, cxdx
	clr	cx
	test	bp, mask GSIF_FORWARD
	jnz	30$
	or	cl, mask OLIS_NAVIGATE_BACKWARD
30$:
	mov	ax, MSG_OL_ITEM_NAVIGATE_IF_DISABLED
	call	IVC_ObjMessageCall
	pop	ax, cx, dx, si			;restore item, optr, etc.
endif	; DISABLED_ITEMS_ARE_SELECTABLE

exitItemFound:
	stc					;say found an item
exit:
	ret
ScanItems	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemGroupGetFirstItemOptr

SYNOPSIS:	Returns optr of first usable and enabled item, if any.

CALLED BY:	utility

PASS:		*ds:si -- GenItemGroup

RETURN:		^lcx:dx -- optr

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/20/92		Initial version

------------------------------------------------------------------------------@

OLItemGroupGetFirstItemOptr	proc	far
	mov	cl, mask GSIF_FROM_START or mask GSIF_FORWARD or \
		    mask GSIF_EXISTING_ITEMS_ONLY
	call	ScanItems
	ret
OLItemGroupGetFirstItemOptr	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= optr of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupBroadcastForDefaultFocus	method	dynamic OLItemGroupClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	test	ds:[di].OLIGI_state, mask OLIGS_DEFAULT_FOCUS
	jz	done			;skip if not...

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	clr	bp			;pass OWNER_INFO_MASK

done:
	ret
OLItemGroupBroadcastForDefaultFocus	endm

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyItemSetUsable
			-- MSG_OL_IGROUP_NOTIFY_ITEM_SET_USABLE handler

DESCRIPTION:	This method is sent when a child item is set USABLE.
		We want to move the selection, and FOCUS exclusives
		to it if necessary.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyItemSetUsable	method	private static \
				OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_ITEM_SET_USABLE

	;if is an exclusive list, and this entry is selected
	;exclusive marked, select it explicitly.

	call	IsNonExclusive
	jc	done			;skip if non-exclusive...

	;move the FOCUS exclusive to the newly selected item.
	;(THIS IS ESSENTIAL for regular, scrolling, and dynamic lists to work!
	;We have drawing optimizations that will fail if you hooey with this.)

EC <	push	si							>
	call	GetCurrentSelectionOptr	;cx:dx = guy to give focus to
	jnc	10$			;skip if no sel (do not reset focus!)...
	call	OLItemGroupMoveFocusExclToItem
10$:
EC <	pop	si							>

done:
EC <	mov	ax, MSG_OL_IGROUP_EC_CHECK_ALL_CHILDREN_UNIQUE		>
EC <	call	ObjCallInstanceNoLock					>
	ret
OLItemGroupNotifyItemSetUsable	endm

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupRedraw -- 
		MSG_GEN_ITEM_GROUP_REDRAW_ITEMS for OLItemGroupClass

DESCRIPTION:	Redraws items as needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
		cx 	- number of items we don't have to redraw,
			  or the ID of the first item to redraw, in
			  the case of a dynamic list.
		(TEMP_OL_ITEM_GROUP_LAST_ITEM_TO_REDRAW will contain
			the last ID to redraw, for scrolling dynamic lists)

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
	chris	3/31/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupRedraw	method dynamic	OLItemGroupClass, \
			MSG_GEN_ITEM_GROUP_REDRAW_ITEMS	

	tst	cx			; nothing to redraw, just exit.
	js	exit			;   6/22/93

	call	VupCreateGState			;bp <- gstate w/spec UI stuff
	push	bp

if USE_REDRAW_ITEMS_OPTIMIZATION
	;
	; Fetch last item to draw from vardata, if it exists.
	; Otherwise, draw to end of list.
	;
	mov	ax, TEMP_OL_ITEM_GROUP_LAST_ITEM_TO_REDRAW
	mov	dx, 0xffff
	call	ObjVarFindData
	jnc	haveLast
	mov	dx, ds:[bx]
haveLast:		
endif ; USE_REDRAW_ITEMS_OPTIMIZATION

	mov	ax, MSG_OL_ITEM_REDRAW

	clr	bx			; child to start with
	push	bx			
	push	cx			

	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
if USE_REDRAW_ITEMS_OPTIMIZATION
	mov	di, OCCT_DONT_SAVE_PARAMS_TEST_ABORT
else
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
endif
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren	
	pop	di
	tst	di
	jz	exit
	call	GrDestroyState

	;
	; For exclusive lists with <> 1 current selection, or with any 
	; non-exclusive list, this is only chance to move the focus.
	;
	call	IsNonExclusive
	jc	updateFocus

	call	IVC_DerefGenDI
	cmp	ds:[di].GIGI_numSelections, 1
	je	exit

updateFocus:
	call	GetFocusItemOptr		;optr in ^lcx:dx
	jnc	exit
	call	OLItemGroupVupGrabFocusExclForItem
exit:
	call	SetPopupListMonikerIfNeeded
	ret
OLItemGroupRedraw	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for OLItemGroupClass

DESCRIPTION:	Sent to object to update its visual enabled state.

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
       		This is called by the specific UI to see if anything special
		needs to be done.  In out case, we need to mark our view or
		composite disabled as well, and return the carry clear so that
		the update will happen normally.

		We'll also reset the selectable flag, if applicable.
		
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/30/90		Initial version

------------------------------------------------------------------------------@

OLItemGroupNotifyEnabled	method dynamic OLItemGroupClass, \
				MSG_SPEC_NOTIFY_ENABLED

	mov	di, MSG_GEN_NOTIFY_ENABLED	
	mov	bp, MSG_GEN_SET_ENABLED

FinishPopupNotify	label	far		;message in ax
						;gen message in bp
						;gen notify message in di
	push	dx, ax, bp, di
	mov	di, offset OLItemGroupClass
	call	ObjCallSuperNoLock
	pop	dx, ax, bp, di
	jnc	exit				;nothing special happened, exit

	;
	; Set the popup enabled, if applicable.
	;
	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[bx].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	exitCarrySet			;not popup list, exit
	mov	ax, bp
	call	VisCallParent			;sets GS_ENABLED
	mov	ax, di
	call	VisCallParent			;sets VA_FULLY_ENABLED if needed

exitCarrySet:
	stc					;say handled
exit:
	ret
OLItemGroupNotifyEnabled	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLItemGroupClass

DESCRIPTION:	Disables the text object and its cohorts, if needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	- update mode

RETURN:		carry set if visual state changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/30/90	Initial version

------------------------------------------------------------------------------@

OLItemGroupNotifyNotEnabled method dynamic OLItemGroupClass, \
			      MSG_SPEC_NOTIFY_NOT_ENABLED

	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	finishNotEnabled		;skip if do not have FOCUS...

	push	ax, cx, dx
	call	OLItemGroupMoveFocusToNextField
	pop	ax, cx, dx

finishNotEnabled:
	mov	bp, MSG_GEN_SET_NOT_ENABLED
	mov	di, MSG_GEN_NOTIFY_NOT_ENABLED
	GOTO	FinishPopupNotify

OLItemGroupNotifyNotEnabled	endm

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupResetPopupListMoniker -- 
		MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER for OLItemGroupClass

DESCRIPTION:	Resets popup list moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER

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
	chris	6/10/92		Initial Version
	chris	3/16/95		For POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION,
				to f

------------------------------------------------------------------------------@

OLItemGroupResetPopupListMoniker	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER

	;
	; Force any popup list that displays the current selection to redraw.
	;

if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	test	ds:[di].OLIGI_moreState, \
			mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	exit
endif
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_DISPLAYING_SELECTION
	call	SetPopupListMonikerIfNeeded
exit:
	ret
OLItemGroupResetPopupListMoniker	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupGenMakeApplyable -- 
		MSG_GEN_MAKE_APPLYABLE for OLItemGroupClass

DESCRIPTION:	Handles making the dialog box applyable.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_MAKE_APPLYABLE

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
	chris	8/27/92		Initial Version

------------------------------------------------------------------------------@

			;   See comment in cwinDialog.asm

OLItemGroupGenMakeApplyable	method dynamic	OLItemGroupClass, 
				MSG_GEN_MAKE_APPLYABLE, 
				MSG_GEN_MAKE_NOT_APPLYABLE

	;
	; Not a property, do not make dialog boxes applyable!  -cbh 2/ 1/93
	;
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	jz	exit				  ;not delayed, exit

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	callSuper			;not a popup list be normal

if 0	;can't do this for Rudy, it seems to mess up setting the moniker
	;  on an apply, and will probably dork canceling from a bubble.

	push	ax, es				;Rudy, call for our generic
	call	GenCallParent			;  parent, then for the window
	pop	ax, es				;  we're in as well.
else
	GOTO	GenCallParent			;send to generic parent instead
endif

callSuper:
	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock
exit:
	ret

OLItemGroupGenMakeApplyable	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupReset -- 
		MSG_GEN_RESET for OLItemGroupClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Does a reset.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemGroupClass
		ax 	- MSG_GEN_RESET

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If we get this here, and we're a popup list, we will try to reset
	our selection to what it is currently displayed as the list item.
	The user has mucked up the selection with his browsing in the
	bubble.

	To make this possible for both exclusive and non-exclusive lists,
	use state that was explicitly stashed away for this purpose,
	instead of overloading poor OLIGI_displayedItem. - ct 10/96

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/16/95         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if MENUS_HAVE_APPLY_CANCEL_BUTTONS 

OLItemGroupReset	method dynamic	OLItemGroupClass, \
				MSG_GEN_RESET,
				MSG_SPEC_POPUP_LIST_CANCEL
	.enter

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
if DELAYED_LISTS_DO_RESET
	jz	testForDelayed
else
	jz	exit				;get out if not popup list
endif
	
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYING_SELECTION
	jnz	setSelection

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx
	jmp	short callObj

if DELAYED_LISTS_DO_RESET
testForDelayed:
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	jz	exit
endif
	
setSelection:

if DELAYED_LISTS_DO_RESET
	call	IsExtendedSelection
EC <	WARNING_C	OL_NON_EXCLUSIVE_ITEM_GROUPS_CANNOT_RESET	>
	jc	exit
endif

	mov	cx, ds:[di].OLIGI_displayedItem
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
callObj:
	call	ObjCallInstanceNoLock

	;
	; Selection has effectively changed.  If the destination cares,
	; send the status message.  After all, it has been getting a status
	; update whenever the user changed the selection, why not now?
	;

	clr	cx				; Reset makes us un-modified
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
OLItemGroupReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLIGGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When user OK's a the current selection, store it as the
		original selection so that any resets we get after
		this don't reset to the wrong thing.

CALLED BY:	MSG_GEN_APPLY
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
	CT	6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DELAYED_LISTS_DO_RESET
OLIGGenApply	method dynamic OLItemGroupClass, 
					MSG_GEN_APPLY
	.enter
	;
	; This only necessary for lists that don't turn into
	; popups themselves.  Popup lists are always keeping
	; OLIGI_displayedItem up-to-date (in SetPopupListMonikerIfNeeded)
	;
		test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
		jnz	done

		call	GetCurrentSelection	; ax = selection ID
		jnc	done			; not exactly 1 selection
		call	IVC_DerefVisDI
		mov	ds:[di].OLIGI_displayedItem, ax
done:
	.leave
	ret
OLIGGenApply	endm
endif ; DELAYED_LISTS_DO_RESET

endif ; MENUS_HAVE_APPLY_CANCEL_BUTTONS




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupGetLargestCenter -- 
		MSG_SPEC_CTRL_GET_LARGEST_CENTER for OLItemGroupClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Gets the largest left-of-center, for properties boxes.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemGroupClass
		ax 	- MSG_SPEC_CTRL_GET_LARGEST_CENTER
		cx	- largest moniker found so far
		bp	- set if any child with valid geometry found

RETURN:		cx, bp	- possibly updated
		ax, dx 	- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/ 3/95         	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupReplaceItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set popup list moniker if needed.

CALLED BY:	MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
		ss:bp	= ReplaceItemMonikerFrame
		dx	= size ReplaceItemMonikerFrame
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupReplaceItemMoniker	method dynamic OLItemGroupClass, 
				MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
if SELECTION_BOX
	;
	; only do this if a popup list
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	done		; done if not a popup list
endif
if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	done		; done if doesn't display current selection
endif

	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYING_SELECTION
	jnz	done		; done if already displaying current selection

	push	di
	call	IVC_DerefGenDI
	mov	cx, ss:[bp].RIMF_item
	cmp	cx, ds:[di].GIGI_selection
	pop	di
	jne	done		; done if item is not current selection

	or	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYING_SELECTION
	mov	ds:[di].OLIGI_displayedItem, cx

	; Update popup list moniker

	mov	ss:[bp].RVMF_updateMode, VUM_DELAYED_VIA_UI_QUEUE

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	dx, size ReplaceVisMonikerFrame

	call	CallOLWin			;set moniker on OLWin
done:
	ret
OLItemGroupReplaceItemMoniker	endm



ItemVeryCommon ends

ItemCommon	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupGetFocusItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the ID of the item that currently has the focus,
		if any.  Used by externally by applications, not internally
		by the spui.

CALLED BY:	MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
RETURN:		cx	= item ID, or GIGS_NONE if none.
		carry set if none.
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	11/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupGetFocusItem	method dynamic OLItemGroupClass, 
					MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM
	.enter

	call	GetFocusItem			; carry set if have one
	mov_tr	cx, dx				; cx = item
	cmc

	.leave
	ret
OLItemGroupGetFocusItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupSetFocusItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the focus to the passed item, scrolling if necessary.

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_FOCUS_ITEM
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
		cx	= item identifier
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	the list may be scrolled.

PSEUDO CODE/STRATEGY:

	NOTE: This hasn't been extensively tested in Spui's other
	than Rudy.  If there is going to be anything wrong in your
	Spui, it will probably be the assumption that exclusive
	lists change their selection as the focus changes
	(which isn't true in Motif radio button item groups?).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	11/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupSetFocusItem	method dynamic OLItemGroupClass, 
					MSG_GEN_ITEM_GROUP_SET_FOCUS_ITEM
	.enter

	push	cx				; keep item id on top of
						;   stack
	mov_tr	ax, cx
	call	EnsureCurrentItemVisible	; ax, cx, dx, bp, di trashed
	pop	cx

	push	cx
	call	GetItemOptr			; cx:dx = optr
	jnc	done

	call	OLItemGroupAbortAllUserInteraction

	call	IsExtendedSelection
	jnc	excl

	call	SetFocusFromOptr		; ax, di trashed
	call	OLItemGroupVupGrabFocusExclForItem
	jmp	done
excl:
	pop	cx
	push	cx
	mov	dx, 0 or (1 shl 8)	;no update flags, one selection
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	call	IC_ObjCallInstanceNoLock
done:
	pop	cx
	.leave
	ret
OLItemGroupSetFocusItem	endm

ItemCommon	ends

ItemVeryCommon	segment	resource

if (_MOTIF or _ISUI) and ALLOW_TAB_ITEMS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line underneath the tabs 

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si - OLItemGroupClass object
		ds:di - OLItemGroupClass instance data
		es - segment of OLItemGroupClass
		bp - GState
RETURN:		none
DESTROYED:	bx, dx, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemGroupVisDraw	method dynamic OLItemGroupClass, 
					MSG_VIS_DRAW
	uses	ax, cx, bp, es
	.enter

	call	CheckForTabs
	tst	dh					;tabs?
	jz	callSuper				;branch if no tabs

	mov_tr	di, bp					;di <- GState	
	mov_tr	dl, dh
	clr	dh
	dec	dx					;dx <- index
	shl	dl					;dx <- table offset
	mov_tr	bp, dx
	call	VisGetBounds
	dec	cx
	dec	dx
	jmp	cs:tabGroupBranchTable[bp]

tabsTop:
	call	setWhite
	mov_tr	bx, dx					;bx <- bottom
	call	GrDrawHLine
	jmp	callSuper


tabsLeft:
	call	setWhite
	mov_tr	ax, cx					;ax <- right
	call	GrDrawVLine
	jmp	callSuper

tabsBottom:
	call	setDark
	call	GrDrawHLine
	jmp	callSuper

tabsRight:
	call	setDark
	call	GrDrawVLine

callSuper:
	.leave
	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock	

setWhite:
	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax
	retn

setDark:
	push	ax
	call	GetDarkColor
	call	GrSetLineColor
	pop	ax
	retn

if _ISUI
setBlack:
	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax
	retn
endif

tabGroupBranchTable	nptr.near	\
	tabsTop,
	tabsLeft,
	tabsRight,
	tabsBottom

OLItemGroupVisDraw	endm

endif

ItemVeryCommon	ends
