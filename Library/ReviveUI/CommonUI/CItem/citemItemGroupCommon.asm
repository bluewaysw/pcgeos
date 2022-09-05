COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUICItem (common code for specific UIs)
FILE:		citemItemGroupCommon.asm


ROUTINES:
	 Name			Description
	 ----			-----------
    MTD MSG_VIS_CLOSE           Handles closing of the item group.  If
				dynamic, we'll nuke our items here.

    MTD MSG_OL_IGROUP_SET_MODIFIED_AND_APPLY_IF_NEEDED 
				Sets modified state based on flags passed
				in.  (So I can't spell.  Sue me.)

    MTD MSG_OL_IGROUP_SET_MODIFIED_SELECTION 
				Sets a single selection in the item group,
				by first item any flags passed, calling the
				appropriate generic message and marking the
				object as modified.  Nukes the object's
				indeterminate state as well.

    INT CallSelfWithUpdateFlagsAndSetModified 
				Sends message to ourselves, setting any
				update flags before- hand, and setting the
				modified state afterwards.  If no message
				is specified, just does the modified and
				apply stuff.

    MTD MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE 
				Used internally to set the state for a
				single item, item update flags beforehand
				and item the item group modified
				afterwards.  Clears indeterminate state.

    INT OLItemGroupSetMultipleSelections 
				Sets multiple selections, changing the
				state bits as ordered.

    MTD MSG_OL_IGROUP_NOTIFY_GROUP_HAS_MOUSE_GRAB 
				These methods are sent by a child OLItem
				object which grabs/releases the mouse. See
				method definitions for more info.

    MTD MSG_META_POST_PASSIVE_BUTTON 
				This method is sent by the Flow object when
				the user presses or releases one of the
				mouse buttons.

    MTD MSG_VIS_LOST_GADGET_EXCL 
				This method is sent to this list when the
				user begins interacting with some other
				object in the window, or when the window is
				closed. If we have not done so already, we
				should release our post-passive grab.

    MTD MSG_OL_IGROUP_START_INTERMEDIATE_MODE 
				 This initiates Intermediate Mode. This
				mode is used in exclusive items which want
				to move the SELECTED emphasis from item to
				item as the user drags across each. As the
				user drags into a new item, that object
				sends this method to the GenList,
				indicating that the selection should
				temporarily be cleared.  The new item will
				have its PRESSING flag set, so it will be
				drawn as SELECTED. If the user drags out of
				this new item, it turns off Intermediate
				Mode, causing the GenList to restore the
				selection to the previously selected item.

				This routine also returns a flag which
				indicates the child's chances of getting
				the focus exclusive when it requests it.

    INT SaveCurrentSelection    Saves current selection to a chunk.  Saves
				a pointer to the chunk and the previous
				state flags.

    MTD MSG_OL_IGROUP_END_INTERMEDIATE_MODE 
				Called by the item's pointer method when a
				pointer wanders out of bounds.  When this
				happens, there are two possibilities.  The
				first is that the pointer moved on top of
				another item, which will then grab the
				exclusive and continue intermediate mode.
				The second is that the pointer moved
				outside of the list.  In this case, the
				current exclusive reverts back to the
				original, since only a release on a item
				can actually make it the current exclusive.

				This routine basically turns off the
				intermediate mode.  It then sets up the
				list to determine whether or not to
				reselect the current exclusive by playing a
				timing trick.  It forces a
				MSG_OL_IGROUP_RESELECT_EXCL onto the UI
				queue. Since the pointer event will be
				replayed, if it fell on top of another
				sibling item, it would start intermediate
				mode again.  Thus, by the time that
				MSG_OL_IGROUP_RESELECT_EXCL gets processed,
				it just checks if intermediate mode is
				on/off. If it's on, then that means the
				pointer is on top of a sibling item and
				nothing else needs to be done.  If
				intermediate mode is off, then that means
				no sibling grabbed the pointer, so the list
				should reselect the original exclusive.

    MTD MSG_OL_IGROUP_RESELECT_EXCL 
				A ItemGroup-specific method that is used to
				determine whether the pointer has moved off
				of a item onto another or off of the list
				entirely.  As is explained in
				MSG_OL_IGROUP_END_INTERMEDIATE_MODE, a
				MSG_OL_IGROUP_RESELECT_EXCL onto the UI
				queue when the pointer leaves a item's
				bounds.  Since the pointer event will be
				replayed, if it fell on top of another
				sibling item, it would start intermediate
				mode again.  Thus, by the time that
				MSG_OL_IGROUP_RESELECT_EXCL gets processed,
				it just checks if intermediate mode is
				on/off.  If it's on, then that means the
				pointer is on top of a sibling item and
				nothing else needs to be done.  If
				intermediate mode is off, then that means
				no sibling grabbed the pointer, so the list
				should reselect the original exclusive.

    INT OLItemGroupSetUserCommon 
				Sets the user item.

    INT IsJustMovingFocus       Sets the user item.

    INT SetNoneSelectedAndWraparoundState 
				Sets none selected if non-extended
				exclusive, and turn off wraparound state if
				extended selection.

    INT SetExtendingFromKbdFlags 
				Sets EXTENDING_SELECTION flag based on the
				shift key flag passed.

    INT GetFocusItem            Returns identifier of focus item.

    INT OLItemGroupGetCurrentFocusExclOrFirst 
				Get the optr of the current FOCUS
				exclusive, or the first item in the list if
				there is no FOCUS exclusive.

    INT OLItemGroupTestForShiftKeyEvent 
				See if the SHIFT key (space bar) is
				selected, and set the EXTENDING_SELECTION
				flag on a press, clear on a release, and
				hope for the best.

    INT OLItemGroupTestForSelectKeyEvent 
				See if the SELECT key (space bar) or RETURN
				key is pressed, and handle the event
				correctly for the in-menu case.

    INT OLItemGroupTestForArrowKeyEvent 
				See if the SELECT key (space bar) or RETURN
				key is pressed, and handle the event
				correctly for both in-menu and not-in-menu
				cases.

    INT OLItemGroupMoveFocusToNextOrPreviousItem 
				See if the SELECT key (space bar) or RETURN
				key is pressed, and handle the event
				correctly for both in-menu and not-in-menu
				cases.

    MTD MSG_SPEC_NAVIGATION_QUERY 
				This method is used to implement the
				keyboard navigation within-a-window
				mechanism. See method declaration for full
				details.

    MTD MSG_META_GAINED_FOCUS_EXCL 
				This procedure is called when the window in
				which this GenList is located decides that
				this object has the focus exclusive. Now,
				GenLists are not supposed to have the focus
				-- their children are. So pass the focus on
				to the child which has the USER exclusive,
				or the first usable child. If do not have
				any usable children, should not have been
				given the focus in the first place!

    MTD MSG_META_LOST_FOCUS_EXCL 
				This procedure is called when the window in
				which this GenList is located decides that
				this object has the focus exclusive. Now,
				GenLists are not supposed to have the focus
				-- their children are. So pass the focus on
				to the child which has the USER exclusive,
				or the first usable child. If do not have
				any usable children, should not have been
				given the focus in the first place!

    INT OLItemGroupMoveFocusElsewhere 
				This routine is called when an item in the
				list is set NOT USABLE, and that item has
				the focus exclusive on it. We try to place
				the focus on the first USABLE item. If none
				exists, then we request that the focus be
				moved elsewhere in the window. If this
				fails...

    MTD MSG_SPEC_SET_NOT_USABLE This method is sent when this GenList is
				set not usable. We intercept it here, to
				make sure that the focus is moved to the
				NEXT object in the window.

    INT OLItemGroupMoveFocusToNextField 
				There are no usable entries in the list, so
				navigate to the next gadget in the window.

    MTD MSG_OL_IGROUP_NOTIFY_DOUBLE_PRESS 
				Sent by GenListEntry when the user
				double-clicks on it.

    INT CustomDoublePress       Sent by GenListEntry when the user
				double-clicks on it.

    MTD MSG_GEN_ACTIVATE        If we get one, and we're a popup list,
				we'll send it to our interaction.

    INT IC_DerefGenDI           Specific UI handler for setting the vis
				moniker. Sets OLCOF_DISPLAY_MONIKER flag.

    INT IC_DerefVisDI           Specific UI handler for setting the vis
				moniker. Sets OLCOF_DISPLAY_MONIKER flag.

    INT IC_ObjCallInstanceNoLock 
				Specific UI handler for setting the vis
				moniker. Sets OLCOF_DISPLAY_MONIKER flag.

    INT IC_ObjMessageCall       Specific UI handler for setting the vis
				moniker. Sets OLCOF_DISPLAY_MONIKER flag.

    INT IC_ObjMessage           Specific UI handler for setting the vis
				moniker. Sets OLCOF_DISPLAY_MONIKER flag.

    MTD MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION 
				Tests for a redundant selection.  See the
				message header for more info.

    MTD MSG_META_GET_ACTIVATOR_BOUNDS 
				Returns bounds of activator.

    MTD MSG_SPEC_POPUP_LIST_APPLY 
				Popup list apply.

    MTD MSG_SPEC_CHANGE         Does a "change" for this ItemGroup.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItemGroup.asm

DESCRIPTION:
	$Id: citemItemGroupCommon.asm,v 1.34 97/02/18 19:04:52 cthomas Exp $

-------------------------------------------------------------------------------@
ItemCommon segment resource


OLExtendedKbdFlags	record
	:5
	OLEKF_USE_PREVIOUS:1		;go on whatever previous presses were
	OLEKF_CTRL_PRESSED:1		;must stay in this position
	OLEKF_SHIFT_PRESSED:1		;must stay in this position
OLExtendedKbdFlags	end



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupVisClose -- 
		MSG_VIS_CLOSE for OLItemGroupClass

DESCRIPTION:	Handles closing of the item group.  If dynamic, we'll nuke
		our items here.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CLOSE

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
	chris	3/26/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupVisClose	method dynamic	OLItemGroupClass, MSG_VIS_CLOSE
	mov	di, offset OLItemGroupClass
	call	ObjCallSuperNoLock

	;
	; If we display the current selection, and it changed while onscreen,
	; we'll try to update it.
	;
if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_moreState, \
			mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jz	exit
endif ; not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	call	SetPopupListMonikerIfNeeded		;set new moniker
exit:
	ret
OLItemGroupVisClose	endm

ItemCommon ends
ItemCommon segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupSetModifiedAndApplyIfNeedd -- 
		MSG_OL_IGROUP_SET_MODIFIED_AND_APPLY_IF_NEEDED 
			for OLItemGroupClass

DESCRIPTION:	Sets modified state based on flags passed in.  (So I can't 
		spell.  Sue me.)

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_SET_MODIFIED_AND_APPLY_IF_NEEDED
		dl	- OLItemUpdateFlags

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
	chris	9/29/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupSetModifiedAndApplyIfNeedd	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_SET_MODIFIED_AND_APPLY_IF_NEEDED

	clr	ax				;forget a message
	mov	bl, dl
	GOTO	CallSelfWithUpdateFlagsAndSetModified

OLItemGroupSetModifiedAndApplyIfNeedd	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupSetModifiedSelection -- 
		MSG_OL_IGROUP_SET_MODIFIED_SELECTION for OLItemGroupClass

DESCRIPTION:	Sets a single selection in the item group, by first item
		any flags passed, calling the appropriate generic message
		and marking the object as modified.  Nukes the object's
		indeterminate state as well.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_SET_MODIFIED_SELECTION

		cx	- selection, if dh = 1, else ignored
		dh	- num selections
		dl	- OLItemUpdateFlags

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
	chris	2/28/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupSetModifiedSelection	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_SET_MODIFIED_SELECTION

EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	tst	dh				;any selection made?
	jnz	10$				;yes, branch
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
10$:
	mov	bl, dl				;pass update flags in bl
	clr	dx				;clear indeterminate state
	FALL_THRU CallSelfWithUpdateFlagsAndSetModified

OLItemGroupSetModifiedSelection	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	CallSelfWithUpdateFlagsAndSetModified

SYNOPSIS:	Sends message to ourselves, setting any update flags before-
		hand, and setting the modified state afterwards.  If no
		message is specified, just does the modified and apply stuff.

CALLED BY:	OLItemGroupResetExcl
		OLItemGroupSetModifiedSelection
		OLItemGroupSetModifiedItemState

PASS:		*ds:si     -- item group
		ax         -- message
		cx, dx, bp -- arguments
		bl	   -- OLItemUpdateFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

CallSelfWithUpdateFlagsAndSetModified	proc	far
	call	IC_DerefGenDI
	mov	bh, ds:[di].GIGI_stateFlags	;save current state flags

	call	IC_DerefVisDI
	mov	ds:[di].OLIGI_updateFlags, bl	;set update flags

	push	bx				;save update flags
	tst	ax
	jz	10$				;no message passed, branch
	call	IC_ObjCallInstanceNoLock	;call message
10$:
	;
	; Add code so that OLIUF_TEMPORARY_CHANGE, basically what's called
	; by StartIntermediateMode, doesn't set the item modified.  Without
	; this, drags over any item resulted in a modified object, even if
	; the user released on the originally selected item, or dragged off the
	; whole thing.  -cbh 8/28/92   (Nope.  What TEMPORARY_CHANGE was
	; doing was not preserving the modified state, but clearing it (all
	; the SET... messages sent above clear the modified state.  We'll
	; attempt to preserve the modified state instead.  -cbh 2/ 6/93)
	;
	clr	cx				;assume preserving modified
	mov	cl, bh				;  state -- pass old flag

	test	bl, mask OLIUF_TEMPORARY_CHANGE
	jnz	preserveModified
	inc	cx				;mark modified (cx guaranteed
						;  not to be 0ffffh, so won't
						;  go zero here)
preserveModified:
	push	cx
EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	IC_ObjCallInstanceNoLock
	pop	cx

dontSetModified:

	;
	; At this point, let's spit out a status message and apply message,
	; if appropriate.  (We won't send out an apply *or* status if 
	; suppressing apply, which currently only occurs when all items are
	; deselected at the start of intermediate mode.)
	;
	;	cx -- non-zero to indicate modified
	
EC <	call	ECEnsureNotBooleanGroup					>

	pop	bx				   ;restore update flags
	test	bl, mask OLIUF_TEMPORARY_CHANGE  ;suppress apply?
	jnz	exit				   ;yes, exit

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	IC_ObjCallInstanceNoLock

FinishSetModifiedState	label	far
	call	IC_DerefVisDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	jnz	exit				;in delayed mode, branch
	mov	ax, MSG_GEN_APPLY		;else send an apply to ourselves
	;
	; Changed to not use a call here, to match what the GenTrigger does.
	; It appears that when an item group runs something in the UI queue
	; the action takes place before we return here, causing annoying
	; delays in updating the item group and its menu, and causing bugs
	; when the action disables its popup list if it has one. -2/ 6/93 cbh
	;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_FIXUP_DS
	call	IC_ObjMessage
exit:
	ret
CallSelfWithUpdateFlagsAndSetModified	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupSetModifiedItemState -- 
		MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE for OLItemGroupClass

DESCRIPTION:	Used internally to set the state for a single item, item
		update flags beforehand and item the item group modified
		afterwards.  Clears indeterminate state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE
	
		cx	- item 
		dh	- zero to deselect, non-zero to select
		dl	- OLItemUpdateFlags

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
	chris	2/28/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupSetModifiedItemState	method dynamic	OLItemGroupClass, \
				MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE

	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	10$
	GOTO	OLBooleanGroupSetModifiedItemState
10$:
	mov	bl, dl				;pass update flags in bl
	mov	dl, dh				;extend dh to word
EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
	GOTO	CallSelfWithUpdateFlagsAndSetModified

OLItemGroupSetModifiedItemState	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemGroupSetMultipleSelections

SYNOPSIS:	Sets multiple selections, changing the state bits as ordered.

CALLED BY:	OLItemGroupEndIntermediateMode

PASS:		*ds:si -- item group
		ds:cx  -- buffer containing items to set
		dl     -- OLItemUpdateFlags
		dh     -- GenItemGroupStateFlags
		bp     -- number of selections

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version

------------------------------------------------------------------------------@

OLItemGroupSetMultipleSelections	proc	near
	;
	; Set update flags according to what is passed.
	;
	mov	di, ds:[si]			
	mov	bx, di
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLIGI_updateFlags, dl	;set update flags

	;
	; Set indeterminate flag according to what is passed. (We set
	; directly to ensure that the thing doesn't redraw twice.)
	;
	push	dx
	add	bx, ds:[bx].Gen_offset
	and	ds:[bx].GIGI_stateFlags, not mask GIGSF_INDETERMINATE
	and	dh, mask GIGSF_INDETERMINATE
	or	ds:[bx].GIGI_stateFlags, dh

	;
	; Set up buffer and set the selections.
	;
	mov	dx, cx				;cx:dx <- buffer 
	mov	cx, ds
EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	call	IC_ObjCallInstanceNoLock		;call message
	
	;
	; Reset the modified state appropriately (we send a message to ensure
	; that the object behaves correctly w.r.t making applyable/not 
	; applyable.
	;
	pop	dx
	clr	cx				;set cx according to mod flag
	test	dh, mask GIGSF_MODIFIED
	jz	10$
	dec	cx
10$:
EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	IC_ObjCallInstanceNoLock
	ret
OLItemGroupSetMultipleSelections	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyGroupHasMouseGrab --
			MSG_OL_IGROUP_NOTIFY_GROUP_HAS_MOUSE_GRAB handler.
FUNCTION:	OLItemGroupNotifyGroupReleasedMouseGrab --
			MSG_OL_IGROUP_NOTIFY_GROUP_RELEASED_MOUSE_GRAB handler

DESCRIPTION:	These methods are sent by a child OLItem object which
		grabs/releases the mouse. See method definitions for more info.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyGroupHasMouseGrab	method	dynamic OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_GROUP_HAS_MOUSE_GRAB

	test	ds:[di].OLIGI_state, mask OLIGS_GROUP_HAS_MOUSE_GRAB
	jnz	done			;skip if this is old news...

	;set up a post-passive mouse grab, so that we know when the mouse
	;button is release, even if it is not over a child item.

	ORNF	ds:[di].OLIGI_state, mask OLIGS_GROUP_HAS_MOUSE_GRAB

	call	VisAddButtonPostPassive

done:
	ret
OLItemGroupNotifyGroupHasMouseGrab	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupPostPassiveButton -- MSG_META_POST_PASSIVE_BUTTON

DESCRIPTION:	This method is sent by the Flow object when the user
		presses or releases one of the mouse buttons.

CALLED BY:	

PASS:		*ds:si	= instance data for object
		cx, dx	= pointer position
		bp	= [ UIFunctionsActive | buttonInfo ]

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupPostPassiveButton	method dynamic OLItemGroupClass, \
						MSG_META_POST_PASSIVE_BUTTON

	;make sure that we think there is still a post-passive grab active

EC <	test	ds:[di].OLIGI_state, mask OLIGS_GROUP_HAS_MOUSE_GRAB	>
EC <	ERROR_Z	OL_ERROR						>

	;are any of the buttons pressed?

	test	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or \
		    mask BI_B1_DOWN or mask BI_B0_DOWN
	jnz	50$			;skip if so...

	;all of the buttons have been released: reset our state flag,
	;so that none of our kids will interact with the mouse anymore.

	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_GROUP_HAS_MOUSE_GRAB)

	call	VisRemoveButtonPostPassive

50$:
	mov	ax, MSG_META_POST_PASSIVE_BUTTON
	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock

OLItemGroupPostPassiveButton	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupLostGadgetExcl -- MSG_VIS_LOST_GADGET_EXCL

DESCRIPTION:	This method is sent to this list when the user begins
		interacting with some other object in the window, or when
		the window is closed. If we have not done so already,
		we should release our post-passive grab.

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

OLItemGroupLostGadgetExcl	method dynamic OLItemGroupClass, \
						MSG_VIS_LOST_GADGET_EXCL

	;do we have a post-passive grab?

	test	ds:[di].OLIGI_state, mask OLIGS_GROUP_HAS_MOUSE_GRAB
	jz	done			;skip if not...

	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_GROUP_HAS_MOUSE_GRAB)

	call	VisRemoveButtonPostPassive

done:
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	mov	di, offset OLItemGroupClass
	CallSuper MSG_VIS_LOST_GADGET_EXCL
	ret
OLItemGroupLostGadgetExcl	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyItemWillGrabFocus --
			MSG_OL_IGROUP_NOTIFY_ITEM_WILL_GRAB_FOCUS_EXCL

DESCRIPTION:
	This method is sent from an OLItemClass object when the user
	presses the mouse on it; This GenList object asks the window if
	the focus exclusive will be granted, and sets a state flag here
	indicating that the focus exclusive is/will be inside this object,
	and so redraws can be optimized to assume that focus movement will
	trigger redraws.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyItemWillGrabFocus	method	OLItemGroupClass, \
			MSG_OL_IGROUP_NOTIFY_ITEM_WILL_GRAB_FOCUS_EXCL

;KIND OF REDUNDANT, BECAUSE BELOW WE CALL A ROUTINE WHICH DOES THIS QUERY AGAIN!
	;see if the window in which this list is located has the FOCUS
	;exclusive, meaning that we will get the FOCUS for within this window
	;if we request it.

	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
EC <	ERROR_NC OL_ERROR		;make sure is answered		>
	tst	bp
	jz	done			;skip if not...

	;now let's make sure that we will be allowed to grab the focus

	call	OpenTestIfFocusOnTextEditObject
	jnc	done			;skip if not...

	;yes: set a state flag that sort of indicates that this GenList or
	;one of its children has the focus exclusive.

	call	IC_DerefVisDI
	ORNF	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL

done:
	ret
OLItemGroupNotifyItemWillGrabFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupStartIntermediateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	This initiates Intermediate Mode. This mode is used in exclusive
	items which want to move the SELECTED emphasis from item to
	item as the user drags across each. As the user drags into a new
	item, that object sends this method to the GenList, indicating that
	the selection should temporarily be cleared.   The new item will have 
	its PRESSING flag set, so it will be drawn as SELECTED. If the user 
	drags out of this new item, it turns off Intermediate Mode, causing the
	GenList to restore the selection to the previously selected item.

	This routine also returns a flag which indicates the child's
	chances of getting the focus exclusive when it requests it.

CALLED BY:	MSG_OL_IGROUP_START_INTERMEDIATE_MODE

PASS:		*ds:si - instance data 
		es - segment of OLItemGroupClass
		ax - MSG_OL_IGROUP_START_INTERMEDIATE_MODE
		cx - ID of entry requesting mode

RETURN:		carry set if GenList or children does not have the focus,
		and so the child which is requesting intermediate mode
		should redraw itself directly, and not rely upon the
		movement of the focus exclusive.

DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	6/89	Initial version
	Eric	3/90	rework
	Joon	8/92	PM extensions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemGroupStartIntermediateMode	method	dynamic OLItemGroupClass, \
				MSG_OL_IGROUP_START_INTERMEDIATE_MODE

	;first abort if this is a non-exclusive list or if we are already
	;in intermediate mode.  

	add	bx, ds:[bx].Gen_offset
	call	IsExtendedSelection
	jc	done			 ;don't do it for extended sel mode

	call	IsNonExclusive
	jc	done			 ;skip if is non-exclusive...

	test	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE
	jnz	done			;skip if already in mode...

	;This is an exclusive list: see if should enter intermediate mode.
	;Motif, CUA/PM and Deskmate: exclusive items in menu can show
	;SELECTED emphasis independently of DEPRESSED/BORDERED emphasis,
	;so no need for Intermediate mode. This item will be drawn as
	;DEPRESSED(CUA/PM) or BORDERED (Motif) for now. If the user
	;releases on it, the GenList will be told to move the selection.
	;(Added 10/23/92 cbh -- anything in toolbox style will do intermediate.)

	;However, we must always use intermediate mode for scrollable lists,
	;so that popups work correctly.  -cbh 11/23/92

	test	ds:[di].OLIGI_state, mask OLIGS_SCROLLABLE		
	jnz	exclusiveList						

CUAS <	push	bx, di							>
CUAS <	mov	ax, HINT_ITEM_GROUP_TOOLBOX_STYLE			>
CUAS <	call	ObjVarFindData						>
CUAS <	pop	bx, di							>
CUAS <	jc	exclusiveList						>

CUAS <	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU		>
CUAS <	jnz	done			;Skip if can show depressed emph. >

exclusiveList:
	;
	; If there is a previous selection present, we'll assume that inter-
	; mediate mode has already been turned on, and we've just deselected
	; a sibling and are selecting a new item.  Skip these other checks
	; that decide whether to start up intermediate based on the initial
	; state and just do it.
	;

	test	ds:[di].OLIGI_moreState, mask OLIGMS_PREV_SELECTION_VALID
	jnz	turnOnMode

	;if no selection, it means this is an exclusive-none
	;list with NO item on. Do not start intermediate mode. When the
	;user releases on the item, it will be selected directly.

	tst	ds:[bx].GIGI_numSelections
	jz	doneSaveCurrentSelection		;skip if is OFF...

	;if an already selected item is requesting intermediate mode,
	;we know better: ignore it.  But first, at least make sure the right
	;selection is stored as the previous selection, so we can properly
	;check for redundant selections.

EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	call	IC_ObjCallInstanceNoLock
	jnc	turnOnMode

doneSaveCurrentSelection:
	call	SaveCurrentSelection
	call	IC_DerefVisDI
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_PREV_SELECTION_VALID
	jmp	short done

turnOnMode:
	;Set for intermediate mode.  Most of the intermediate mode
	;deselection will be handled by the TAKE_GADGET_EXCL mech, but the
	;first deselection is a special case, so go deselect the current
	;item.

	call	IC_DerefVisDI
	ORNF	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE

	;Create an lmem chunk to hold the current selection, so we can
	;restore it in END_INTERMEDIATE_MODE.

	call	SaveCurrentSelection

if _KBD_NAVIGATION	;------------------------------------------------------

	clr	cx

	;if this list or its children does not have the FOCUS exclusive
	;(might be inside a pinned menu), then force redraws now!

	mov	dl, mask OLIUF_SUPPRESS_DRAW_IF_CURSORED 

					;pass flags: full deselect, but do not
					;redraw if CURSORED because will redraw
					;when it loses the focus.

	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jnz	15$			;skip if has focus (cy=0)...

	clr	dl
					;pass flags: full deselect, with redraw
	stc				;return flag: redraw new item
15$:
else
	clr	bp
	stc				;return flag: redraw new item
endif 			;------------------------------------------------------

	pushf
	clr	dh			;no items to select
	or	dl, mask OLIUF_TEMPORARY_CHANGE or \
	 	    mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE
					;don't send apply!
					;don't set modified either! -cbh 8/28/92
					;don't wreck intermediate mode just as
					; we're starting it!  -cbh 11/24/92

	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	call	IC_ObjCallInstanceNoLock	;ignore errors returned
	popf
	ret

done:
	;if this list or its children does not have the FOCUS exclusive
	;(might be inside a pinned menu), then force redraws now!

	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jnz	exit			;skip if does have focus (cy=0)...

	stc				;return flag: will NOT get focus,
					;so had better redraw now
exit:
	ret
OLItemGroupStartIntermediateMode	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveCurrentSelection

SYNOPSIS:	Saves current selection to a chunk.  Saves a pointer to 
		the chunk and the previous state flags.

CALLED BY:	OLItemGroupStartIntermediateMode

PASS:		*ds:si -- item group

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/28/92		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

SaveCurrentSelection	proc	far		uses	bx, dx
	.enter
	;
	; If there's still a previous selection, it was left over from the
	; beginning of the user dragging (we entered intermediate mode, ended
	; as the user moved off an item, and restarted as the user moved over
	; a sibling before a reselect occurred.).  We'd like to save that one.
	;
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_PREV_SELECTION_VALID
	jnz	exit

	ORNF	ds:[di].OLIGI_moreState, mask OLIGMS_PREV_SELECTION_VALID

	;
	; Nuke the old chunk, if there is one.  -cbh 12/1/92
	;
	mov	ax, ds:[di].OLIGI_prevSelections
	tst	ax
	jz	10$
	call	LMemFree
10$:
	;
	; Create a chunk to hold the current selections, and save in instance
	; data.
	;
	call	IC_DerefGenDI
	mov	cx, ds:[di].GIGI_numSelections
	mov	bl, ds:[di].GIGI_stateFlags
	mov	bp, cx				;num sels in bp
	shl	cx, 1
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc			;chunk in *ds:ax
	call	IC_DerefVisDI
	mov	ds:[di].OLIGI_prevSelections, ax
	mov	ds:[di].OLIGI_prevState, bl

	mov	di, ax
	mov	dx, ds:[di]			;deref chunk, in dx
	mov	cx, ds				;now in cx:dx
	;
	; Chunk in cx:dx, numSelections in bp, get the selections.
	;
EC <	call	ECEnsureNotBooleanGroup					>
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	call	IC_ObjCallInstanceNoLock		;fill in list
exit:
	.leave
	ret
SaveCurrentSelection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupEndIntermediateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by the item's pointer method when a pointer
		wanders out of bounds.  When this happens, there are two
		possibilities.  The first is that the pointer moved on
		top of another item, which will then grab the exclusive
		and continue intermediate mode.  The second is that the
		pointer moved outside of the list.  In this case, the 
		current exclusive reverts back to the original, since only
		a release on a item can actually make it the current
		exclusive.  

		This routine basically turns off the intermediate mode.  It
		then sets up the list to determine whether or not to reselect
		the current exclusive by playing a timing trick.  It forces
		a MSG_OL_IGROUP_RESELECT_EXCL onto the UI queue.
		Since the pointer event will be replayed, if it fell on top
		of another sibling item, it would start intermediate mode
		again.  Thus, by the time that MSG_OL_IGROUP_RESELECT_EXCL
		gets processed, it just checks if intermediate mode is on/off.
		If it's on, then that means the pointer is on top of a sibling
		item and nothing else needs to be done.  If intermediate
		mode is off, then that means no sibling grabbed the pointer,
		so the list should reselect the original exclusive.

CALLED BY:	MSG_OL_IGROUP_END_INTERMEDIATE_MODE

PASS:		*ds:si - instance data 
		bp	- OLItemEnsureNotPressedFlags (see citemItem.asm)

RETURN:		ds, si, bp = same

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	11/89	Initial version
	Eric	3/90	Cleanup, renaming.
	Chris	5/92	GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemGroupEndIntermediateMode	method	dynamic OLItemGroupClass,
					MSG_OL_IGROUP_END_INTERMEDIATE_MODE

	;
	; Don't mess up prevSelections if extended selection.  -cbh 12/ 1/92
	; (Changed non-excl behavior to match extended selection. -cbh 2/16/93)
	;
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	exit
	call	IC_DerefGenDI
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXTENDED_SELECTION
	je	exit
10$:

	;Turn off intermediate mode

	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE
	jz	nukePrevSelsAndExit	;skip if already off...

turnOffMode:
	ANDNF	ds:[di].OLIGI_state, not mask OLIGS_INTERMEDIATE

	test	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER
	jz	nukePrevSelsAndExit

	;Send out a reselect method to the queue.  
	;(pass ^lcx:dx = item to deselect, bp = whether to move FOCUS excl)
	;(added insert-at-front 2/24/93 cbh)

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_IGROUP_RESELECT_EXCL
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage		;Reselect the current entry, and
					;definitely don't nuke previous
					;selections chunk yet.
nukePrevSelsAndExit:
	;
	; Previous selection no longer valid.  (We don't nuke it anymore,
	; -cbh 8/31/92)
	;
	ANDNF	ds:[di].OLIGI_moreState, not mask OLIGMS_PREV_SELECTION_VALID
exit:
	ret

OLItemGroupEndIntermediateMode	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupReselectExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A ItemGroup-specific method that is used to determine
		whether the pointer has moved off of a item onto another
		or off of the list entirely.  As is explained in 
		MSG_OL_IGROUP_END_INTERMEDIATE_MODE, a
		MSG_OL_IGROUP_RESELECT_EXCL onto the UI queue when the
		pointer leaves a item's bounds.  Since the pointer event
		will be replayed, if it fell on top of another sibling item,
		it would start intermediate mode again.  Thus, by the time that
		MSG_OL_IGROUP_RESELECT_EXCL gets processed, it just
		checks if intermediate mode is on/off.  If it's on, then that
		means the pointer is on top of a sibling item and nothing
		else needs to be done.  If intermediate mode is off, then that
		means no sibling grabbed the pointer, so the list should
		reselect the original exclusive.

CALLED BY:	MSG_OL_IGROUP_RESELECT_EXCL

PASS:		*ds:si - instance data 
		es - segment of OLItemGroupClass
		ax - MSG_OL_IGROUP_END_INTERMEDIATE_MODE
		bp	- OLItemEnsureNotPressedFlags (see citemItem.asm)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	11/89	Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemGroupReselectExcl	method	dynamic OLItemGroupClass, \
						MSG_OL_IGROUP_RESELECT_EXCL

	;make sure we don't get this in non-exclusive cases.

EC <	call	IsNonExclusive						>
EC <	ERROR_C OL_ERROR						>

	;if we have entered intermediate mode again, it means that some other
	;child GenListEntry has grabbed the mouse. Abort this handler,
	;saving the previous selection for later.

	test	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE
	jnz	done			;skip if again in intermediate mode...

exitIntermediateMode:
	;
	; Reselect old entries.  If there is no previous selection valid, it
	; means there were two RESELECT_EXCL messages back to back, and the 
	; first one took care of things.  Exit.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_PREV_SELECTION_VALID
	jz	done			

	mov	bx, ds:[di].OLIGI_prevSelections
	ChunkSizeHandle	ds, bx, ax	;size of selections in ax
	shr	ax, 1			;halve for number of items
	mov	cx, ds:[bx]		;deref, buffer now in ds:cx

	;pass flags: full select, and redraw because cannot rely upon
	;focus to move.

if _KBD_NAVIGATION	;------------------------------------------------------
	;should we move the FOCUS to original owner?

	push	bp
;	test	bp, mask OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER
endif 			;------------------------------------------------------

	;
	; For anything we do, we don't want to move the focus or release
	; any grabs.
	;
	mov	dl, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE

if _KBD_NAVIGATION	;------------------------------------------------------
;	jz	50$			;skip if not moving focus...

	;another reason for the focus to not move it that this GenList does
	;not have the focus (is in a pinned menu, etc). If this is the case,
	;force a redraw with the USER exclusive changes we are making.

;	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
;	jz	50$			;skip if do not have focus...

	;in toolboxes, the list never actually has the focus, which causes
	;problems here.  Let's ensure that we redraw the list entry if we're
	;in a toolbox.  -cbh 2/12/92

;	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
;	jnz	50$

	;This GenList (or a child) has the focus exclusive. Pass flags:
	;full select, but do not redraw because we will handle

;	or	dl, mask OLIUF_SUPPRESS_DRAW

endif 			;------------------------------------------------------

50$:
	;
	; Reselect item(s) previously selected.  Does not affect focus excl.
	; Hopefully.
	;
	mov	dh, ds:[di].OLIGI_prevState
	mov	bp, ax			;num selections in bp
	call	OLItemGroupSetMultipleSelections

					;deselect old item, and select new
					;item. Does not affect focus excl.

if _KBD_NAVIGATION	;------------------------------------------------------
	pop	bp			;should we move the FOCUS to original
	test	bp, mask OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER
	jz	doneNukePrevSel			;skip if not...

	;force the focus exclusive to move from the old item to the new item.
	;This will cause each of them to redraw, showing their new
	;SELECTED and CURSORED states. (Only do this if some object in this
	;list has the focus exclusive!)

	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	done			;skip if other object now has focus...

	call	GetCurrentSelectionOptr
					;was there a selected item
					;before intermediate mode?
	jnc	doneNukePrevSel		;skip if not...

	call	OLItemGroupVupGrabFocusExclForItem
endif 			;------------------------------------------------------

doneNukePrevSel:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLIGI_moreState, not mask OLIGMS_PREV_SELECTION_VALID

done:
	ret
OLItemGroupReselectExcl	endp

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupSetUserToNext
			-- MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
FUNCTION:	OLItemGroupSetUserToPrevious
			-- MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS

DESCRIPTION:	These generic methods are sent by a GenList object to itself
		when the user presses the arrows keys. Applications can also
		send these methods for special effects.

PASS:		*ds:si	= instance data for object
		ch -- OLExtendedKbdFlags

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupSetUserToNext	method	private static OLItemGroupClass, \
					MSG_OL_IGROUP_SET_SELECTION_TO_NEXT

if _WRAP_AROUND_LIST_NAVIGATION
	mov	cl, mask GSIF_FORWARD or mask GSIF_WRAP_AROUND
else
	mov	cl, mask GSIF_FORWARD
endif
	GOTO	FinishSetUser

OLItemGroupSetUserToNext	endm

OLItemGroupSetUserToStart	method	private static OLItemGroupClass, \
					MSG_OL_IGROUP_SET_SELECTION_TO_START

	mov	cl, mask GSIF_FORWARD or mask GSIF_FROM_START
	GOTO	FinishSetUser

OLItemGroupSetUserToStart	endm

OLItemGroupSetUserToEnd	method	private static OLItemGroupClass, \
					MSG_OL_IGROUP_SET_SELECTION_TO_END

	mov	cl, mask GSIF_FROM_START
	GOTO	FinishSetUser

OLItemGroupSetUserToEnd	endm

OLItemGroupSetUserToPrevious	method	private static OLItemGroupClass, \
					MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS

if _WRAP_AROUND_LIST_NAVIGATION
	mov	cl, mask GSIF_WRAP_AROUND	;backwards, wrap
else
	clr	cl
endif

FinishSetUser	label	far
	;
	; cl -- GenScanItemsFlags; ds:di -- SpecInstance
	;
	mov	bp, 1				;number of items to skip
	FALL_THRU OLItemGroupSetUserCommon

OLItemGroupSetUserToPrevious	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemGroupSetUserCommon

SYNOPSIS:	Sets the user item.

CALLED BY:	OLItemGroupSetUserToPrevious, OLItemGroupSetUserToNext,
       		OLIGrollingListPageUp, OLIGrollingListPageDown

PASS:		*ds:si  -- item group handle
		bp -- num of entries to skip when scanning for new focus
		cl -- GenScanItemsFlags
		ch -- OLExtendedKbdFlags

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	6/11/90		Added a needed header

------------------------------------------------------------------------------@
	
OLItemGroupSetUserCommon	proc	far
	call	GetFocusItem			;dx <- current item with focus
	jc	10$				;there is one, branch
	or	cl, mask GSIF_FROM_START	;else mark this

10$:
	call	SetNoneSelectedAndWraparoundState
	;
	; Scan for an item, using the flags passed.
	;
	call	ScanItems
	jnc	exit				;skip if nothing appropriate
	tst	cx				;is the item around?
	jz	20$				;no, branch
	push	ax
	call	OLItemGroupAbortAllUserInteraction
	pop	ax
					;UN-PRESS the current item, kill
					;intermediate mode, etc.
20$:

	;if this is an exclusive list, move the ACTUAL (and/or USER) exclusive.

	call	IsJustMovingFocus
	jc	nonExcl			;skip if is non-exclusive list...

	call	IC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	nonExcl			;skip if read only(don't move selection)

	;
	; Exclusive-none list, extend selection if needed, then jump to give
	; the focus to the new guy.
	;
	call	CheckIfExtendingSelection
	jnc	excl

	;
	; Extend the selection.  We'll always be setting stuff here, rather
	; than inverting the anchor.
	;
	push	cx
	clr	cx			;Don't make a temporary change!  We need
					;  the action to be send! 8/24/93 cbh
	; Rudy: Sending a separate status message for every item in the
	;   selection is a horrible waste.  We'll send out the status
	;   message after we're done.  This should probably happen in all
	;   UI's.
RUDY <	mov	cx, mask OLIUF_TEMPORARY_CHANGE or \
		    mask OLIUF_LEAVE_EXCLUSIVE_BEHAVIOR_ALONE		>
	call	ExtendSelectionSettingItems

if _RUDY
	; Now we're done, send out one status/apply

	push	ax, dx
	clr	ax				;send no message
	clr	bl				;no special flags
	call	CallSelfWithUpdateFlagsAndSetModified
	pop	ax, dx
endif

	pop	cx
	jmp	short nonExcl

excl:

RUDY <	push	ax, cx, dx						>
	mov	cx, ax			;item in cx

	;is an exclusive list: send method to self to
	;move selection.

	push	cx
	mov	dx, 0 or (1 shl 8)	;no update flags, one selection
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	call	IC_ObjCallInstanceNoLock
	pop	cx

	;set as the anchor and extent items.

	call	IC_DerefVisDI
	mov	ds:[di].OLIGI_extentItem, cx	;set as the extent item
	call	SetAnchorItem

if _RUDY
	;
	; Rudy : If non-exclusive list acting like exclusive,
	; must force focus to move here.  Doing an unconditional
	; jmp here works fine in all cases except in certain hacks
	; (TextWithListClass) that attempt to grab the focus away
	; from the list - the list ends up grabbing the focus back.
	;
	pop	ax, cx, dx

	call	IsExtendedSelection
	jc	nonExcl
endif

exit:
	ret

nonExcl:
	;	
	; Make sure internal idea of the focus item is updated.  If the focus
	; is not really changing objects (i.e. navigating downwards in a 
	; scrolling list), the focusItem will not be updated.  In exclusive
	; lists, the focusItem will get updated in UpdateSpecificObject, since
	; the selected item moves. -cbh 5/ 7/92
	;
	; ^lcx:dx -- item, ax -- identifier
	;
	push	cx, dx
	mov	cx, ax
	mov	bl, mask OLIGS_HAS_FOCUS_ITEM	;assume there is one
	call	SetFocusItem
	call	EnsureCurrentItemVisible	;make item visible
	pop	cx, dx

	;now move the FOCUS exclusive to this new item, as long as something
	;else in this list has the focus already.
	;
	; ^lcx:dx -- new item

	call	OLItemGroupVupGrabFocusExclForItem

if _RUDY and 0	; We'll try to achieve the same effect, without an
		; entire redraw, by faking the gained/lost focus
		; in OLItemGroupVupGraBfocusExclForItem
	;
	; Since list items of non-focusable lists don't get the focus, they
	; don't change their state and redraw upon gaining/losing it.
	; So manually redraw the items.
	;
	mov	ax, HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS
	call	ObjVarFindData
	jnc	exit2
	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
	clr	cx
	GOTO	ObjCallInstanceNoLock
exit2:
endif
	ret
OLItemGroupSetUserCommon	endp





IsJustMovingFocus	proc	near
	;
	; Returns carry set if we just want to move focus in SetUserCommon.
	; Happens when XORING_SELECTION is set ONLY.
	;
if _RUDY	; non-exclusive lists may or may not just be moving
		; the focus, depending on whether we're extending
		; a selection or not.
	call	IsExtendedSelection
	jnc	exit
else
	call	IsNonExclusive
	jc	exit				;skip if is non-exclusive list
endif

	call	IC_DerefVisDI

if _RUDY
	;
	; If acting like exclusive list, then return "no"
	;
	tst	ds:[di].OLIGI_exclusiveBehavior	; carry clear
	jnz	exit	
endif

if not _RUDY
	test	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
	jz	exit				;Not in "add mode", branch
endif
	test	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
	jnz	exit				;Extending, branch
	stc
exit:
	ret
IsJustMovingFocus	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetNoneSelectedAndWraparoundState

SYNOPSIS:	Sets none selected if non-extended exclusive, and turn off 
		wraparound state if extended selection.

CALLED BY:	OLItemGroupSetUserCommon

PASS:		cl -- GenScanItemFlags
		ch -- OLExtendedKbdFlags

RETURN:		cl -- possibly updated

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 5/92	Initial version

------------------------------------------------------------------------------@

SetNoneSelectedAndWraparoundState	proc	near
	call	SetExtendingFromKbdFlags
	;
	; Remove the old selection if a) we're not extending or xoring
	;
	call	IsJustMovingFocus		;just moving focus, exit
	jc	exit

	call	CheckIfExtendingSelection	
	jnc	12$

	;
	; Extending selection, don't wrap around -- it does something 
	; reasonable, but it's pretty non-intuitive.  And if we're xoring,
	; we won't turn off other items.
	;
	and	cl, not mask GSIF_WRAP_AROUND	

;       Clearing not-selected items should be handled in update-extended-
;	selection now.
;	call	IC_DerefVisDI
;	test	ds:[di].OLIGI_moreState, mask OLIGMS_XORING_SELECTION
;	jnz	exit
	jmp	short exit

12$:
	;
	; Not extending the selection, clear the selection first.  Also,
	; invalidate any extended selection.   (Rudy -- this seems to 
	; interfere big-time with popup lists, should probably be in all
	; systems.)
	;
if _RUDY or SELECTION_BOX
	call	IsExtendedSelection
	jnc	20$
	call	IC_DerefVisDI
	clr	ds:[di].OLIGI_displayedItem	;inval selection

	;
	; this is just a temporary change, so don't change our behavior
	; from exclusive to non-exclusive.
	;
	ornf	ds:[di].OLIGI_updateFlags, mask OLIUF_LEAVE_EXCLUSIVE_BEHAVIOR_ALONE
20$:
else
	call	IC_DerefVisDI
	clr	ds:[di].OLIGI_displayedItem	;inval selection
endif

	push	cx, dx, bp
	clr	dx			;OK to nuke indeterminate status...
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	IC_ObjCallInstanceNoLock
	pop	cx, dx, bp			;restore flags
exit:
	ret
SetNoneSelectedAndWraparoundState	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	SetExtendingFromKbdFlags

SYNOPSIS:	Sets EXTENDING_SELECTION flag based on the shift key flag
		passed.

CALLED BY:	SetNonSelectedAndWraparoundState
		OLItemGroupTestForArrowKeyEvent

PASS:		*ds:si -- item group
		ch -- OLExtendedKbdFlags

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 6/92		Initial version

------------------------------------------------------------------------------@

SetExtendingFromKbdFlags	proc	near
	;
	; Let's set the EXTENDING_SELECTION state based on the shift flag.
	;
	test	ch, mask OLEKF_USE_PREVIOUS	
	jnz	10$				;leave as set previously

	call	IC_DerefVisDI
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_EXTENDING_SELECTION
if _RUDY
	test	ch, mask OLEKF_SHIFT_PRESSED or mask OLEKF_CTRL_PRESSED
else
	test	ch, mask OLEKF_SHIFT_PRESSED
endif
	jz	10$
	or	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
10$:
	ret
SetExtendingFromKbdFlags	endp

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetFocusItem

SYNOPSIS:	Returns identifier of focus item.

CALLED BY:	OLItemGroupSetUserCommon

PASS:		*ds:si -- item group

RETURN:		carry set if there is a focus item, with:
			dx -- identifier

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/20/92		Initial version

------------------------------------------------------------------------------@

if _RUDY
GetFocusItemFar	proc	far
	call	GetFocusItem
	ret
GetFocusItemFar	endp
endif

GetFocusItem	proc	near	uses	si, cx, bp
	.enter
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	exit				;no focus item, exit, C=0
	mov	dx, ds:[di].OLIGI_focusItem	;else return an item
	stc
exit:
	.leave
	ret
GetFocusItem	endp

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupToggleFocusExclItem --
			MSG_OL_IGROUP_TOGGLE_FOCUS_EXCL_ITEM

DESCRIPTION:	This generic method is sent by a GenList object to itself
		when the user presses the SPACE BAR. Applications can also
		send these methods for special effects.

PASS:		*ds:si	= instance data for object
		ch = OLExtendedKbdFlags

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupToggleFocusExclItem	method	private static \
					OLItemGroupClass, \
					MSG_OL_IGROUP_TOGGLE_FOCUS_EXCL_ITEM
	;
	; New code 6/24/93 cbh to not select the damn item if read-only!
	;
	push	di	
	call	IC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
LONG	jnz	exit			;skip if read only (don't select!)


	call	IsExtendedSelection	;not extended, normal toggling
	jnc	normalToggle

	push	cx			;
	call	GetFocusItem		;focus item in dx
;EC <	ERROR_NC	OL_ERROR	;no selection, die		>
;there may be no items in list
	pop	ax			;ah <- OLExtendedKbdFlags
	jnc	exit

if not _RUDY	; Rudy always toggles single item, and sets anchor

	call	IC_DerefVisDI		;already shifting, branch
	test	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
	jnz	10$
endif ; not _RUDY

	;
	; Not shifting, set anchor item here.  We'll do a normal toggle (which
	; does nothing if we're not xoring.  Otherwise we'll call Extend-
	; Selection in the hopes of toggling the current item.
	;
	mov	cx, dx
	call	SetAnchorItem

	call	CheckIfInAddMode	;changed from just XORING_SELECTION
	jnc	normalToggle		;   4/20/93 cbh
10$:	
	;
	; If we're not in add mode, let's clear other selections.
	;
	call	IC_DerefVisDI
	call	CheckIfInAddMode	;changed from just XORING_SELECTION
	jc	20$			;   4/20/93 cbh
	push	cx, dx, bp
	clr	dx			;OK to nuke indeterminate status...
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	IC_ObjCallInstanceNoLock
	pop	cx, dx, bp			;restore flags
20$:
	call	IC_DerefVisDI
	mov	ax, dx			;extent item

	;
	; If we're only affecting one item (anchorItem = extentItem), then
	; we'll want to toggle the item.  Otherwise we'll always select.
	;
	or	ds:[di].OLIGI_moreState, mask OLIGMS_SELECTING_ITEMS
	cmp	ax, ds:[di].OLIGI_anchorItem
	jne	30$
	call	SetToToggleAnchorItem
30$:
	;
	; Set flags: don't let the focus move here, otherwise we get things
	; like toggling an item off when there's another selection causes
	; the focus to move to that selection.
	;
	mov	cx, mask OLIUF_LEAVE_FOCUS_AND_GRAB_ALONE
if _RUDY
	; Toggling when in exclusive mode always moves the list
	; into non-exclusive mode.  If already in exclusive mode,
	; stay that way.
	;
	tst	ds:[di].OLIGI_exclusiveBehavior
	jnz	extend
	ornf	cx, mask OLIUF_LEAVE_EXCLUSIVE_BEHAVIOR_ALONE
extend:
endif
	call	ExtendSelection
	jmp	short exit

normalToggle:

	;get the optr of the GenListEntry which has the current focus excl.

	push	si
	call	GetFocusItemOptr	;^lcx:dx focus item
	movdw	bxsi, cxdx
;EC <	tst	bx			;is there a FOCUSED entry?	>
;EC <	ERROR_Z OL_ERROR						>
;there could be no items in the list:
	tst	bx			;is there a FOCUSED entry?
	jz	noItem			;if not, exit

	mov	bp, mask OIENPF_SIMULATE_PRESS_AND_RELEASE
					;simulate a press and release;
					;do not redraw item when aborting
					;intermediate mode.
	mov	ax, MSG_OL_ITEM_ENSURE_IS_RELEASED
	call	IC_ObjMessageCall
noItem:
	pop	si			;restore *ds:si!!! See caller.
exit:
	ret
OLItemGroupToggleFocusExclItem	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupGetCurrentFocusExclOrFirst

DESCRIPTION:	Get the optr of the current FOCUS exclusive, or the first item
		in the list if there is no FOCUS exclusive.

CALLED BY:	OLItemGroupNavigate, OLItemGroupGainedFocusExcl
		OLItemGroupMoveFocusToNextOrPreviousItem

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= optr of current or first item
		carry clear if no item is USABLE and ENABLED

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupGetCurrentFocusExclOrFirst	proc	near
	call	GetFocusItemOptr	;^lcx:dx <- focus item
	tst	cx
	stc				;flag: have OD
	jnz	done			;skip if have OD...

	;there is no current FOCUS exclusive. Find first usable item.

	call	OLItemGroupGetFirstItemOptr
					;returns carry clear if none
done:	
	ret
OLItemGroupGetCurrentFocusExclOrFirst	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupKbdChar -- MSG_META_KBD_CHAR handler

DESCRIPTION:	This method is sent either:
			1) directly from the Flow object, because this button
			   has the keyboard grab (was cursored earlier)
			2) from this button's ancestors up the "focus" tree.
			   This is only true if the key could be a system-level
			   shortcut.

PASS:		*ds:si	= instance data for object
		ax = MSG_META_KBD_CHAR.
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
	Eric	2/90		initial version (from John's VisKbdText)
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupKbdChar	method	private static OLItemGroupClass, \
					MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR
if _KBD_NAVIGATION	;------------------------------------------------------
	;we should not get events when the button is disabled...

	call	IC_DerefVisDI
EC <	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED			>
EC <	ERROR_Z	OL_ERROR						>

	; Turn
	call	OLItemGroupTestForShiftKeyEvent

	;Don't handle state keys (shift, ctrl, etc).
	;check for SPACE BAR (only look for press events)

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT or \
					 mask CF_RELEASE
	jnz	fupIt

	call	IC_DerefVisDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	afterSpaceCheck		;skip if not in menu...

	call	OLItemGroupTestForSelectKeyEvent
					;see if the SELECT key (space bar) or
					;RETURN is pressed, and handle specially
					;for a menu.
	jc	done			;skip if handled...

afterSpaceCheck::
	call	OLItemGroupTestForArrowKeyEvent
					;see if an ARROW key is pressed,
					;and handle according to whether in
					;menu or not.
	jc	done			;skip if handled...

	;check for non-modified alpha character here
endif	;----------------------------------------------------------------------

checkMnemonic:
	;
	; Let's try activating any item with the mnemonic.
	;

	test	dh, mask SS_RCTRL or mask SS_LCTRL
	jnz	noMatch				;don't do this if ctrl pressed!
						;  -cbh 12/31/93

	push	cx, dx, bp
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, OCCT_SAVE_PARAMS_TEST_ABORT
	call	VisCallCommon			;call children 'til match found
	pop	cx, dx, bp
	jnc	noMatch				;no match, send up
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_NULL			>
DBCS <	mov	cx, C_NOT_A_CHARACTER					>
						;else send the character up
						;  as null to pacify the ALT
						;  key

noMatch:

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_DOWN			>
DBCS <	cmp	cx, C_SYS_DOWN						>
					;this is probably an alt-down-arrow
	je	fupIt			;   allow fups, even in popup list

if not _RUDY
	;Let's send escapes upwards, even in popup lists, to allow users an
	;easier way out of them.   -cbh 1/28/93

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_ESCAPE			>
DBCS <	cmp	cx, C_SYS_ESCAPE					>
	je	fupIt			

	call	IC_DerefVisDI		
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jnz	done			;send nothing upward for popup lists
endif

fupIt:
	;this GenList does not care about this keyboard event. As a leaf object
	;in the FOCUS exclusive hierarchy, we must now initiate a FOCUS-UPWARD
	;query to see a parent object (directly) or a parent's descendants
	;(indirectly) cares about this event.
	;	cx, dx, bp = data from MSG_META_KBD_CHAR

	mov	ax, MSG_META_FUP_KBD_CHAR
	call	VisCallParent
done:
	ret
OLItemGroupKbdChar	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupTestForShiftKeyEvent

DESCRIPTION:	See if the SHIFT key (space bar) is selected, and set the
		EXTENDING_SELECTION flag on a press, clear on a release,
		and hope for the best.

CALLED BY:	OLItemGroupKbdChar

PASS:		*ds:si	= instance data for object
		ax = MSG_META_KBD_CHAR.
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if event handled.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OLItemGroupTestForShiftKeyEvent	proc	near
SBCS <	cmp	ch, VC_ISCTRL						>
DBCS <	cmp	ch, CS_CONTROL_HB					>
	jne	noMatch
SBCS <	cmp	cl, VC_LSHIFT						>
DBCS <	cmp	cl, C_SYS_LEFT_SHIFT and 0x00ff				>
	je	match
SBCS <	cmp	cl, VC_RSHIFT						>
DBCS <	cmp	cl, C_SYS_RIGHT_SHIFT and 0x00ff			>
	jne	noMatch
match:
	call	IC_DerefVisDI
	and	ds:[di].OLIGI_moreState, not mask OLIGMS_EXTENDING_SELECTION
	test	dl, mask CF_RELEASE
	jnz	done
	or	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
done:
	stc
	ret
noMatch:
	clc
	ret
OLItemGroupTestForShiftKeyEvent	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupActivateObjectWithMnemonic --
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC handler

DESCRIPTION:	Looks at its vis moniker to see if its mnemonic matches
		that key currently pressed.

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
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupActivateObjectWithMnemonic	method	OLItemGroupClass, \
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	VisCheckIfFullyEnabled
	jnc	noActivate
	;XXX: skip if menu?
	call	VisCheckMnemonic
	jnc	noActivate
	;
	; mnemonic matches, grab focus
	;
	call	IC_DerefVisDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	exit			;is a toolbox, don't grab (carry clear)
	call	MetaGrabFocusExclLow
	stc				;handled
	jmp	short exit

noActivate:
	;
	; let superclass call children, since either were are not fully
	; enabled, or our mnemonic doesn't match, superclass won't be
	; activating us, just calling our children
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLItemGroupClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
OLItemGroupActivateObjectWithMnemonic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupFindKbdAccelerator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle View and Shift-View navigation

CALLED BY:	MSG_GEN_FIND_KBD_ACCELERATOR
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		ds:bx	= OLItemGroupClass object (same as *ds:si)
		es 	= segment of OLItemGroupClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState (ModBits)
		bp low	= ToggleState
		bp high	= scan code
RETURN:		carry set if accelerator found
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ODIE

OLItemGroupFindKbdAccelerator	method dynamic OLItemGroupClass, 
					MSG_GEN_FIND_KBD_ACCELERATOR

	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	callSuper			; not "view" tab
	push	ax, bx
	mov	ax, HINT_ITEM_GROUP_TAB_STYLE
	call	ObjVarFindData
	pop	ax, bx
	jnc	callSuper			; not tab
	;
	; if View or Shift-View, navigate as necessary
	;
	test	dl, mask CF_RELEASE		; ignore release
	jnz	callSuper
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F12			>
DBCS <	cmp	cx, C_SYS_F12						>
	jne	callSuper
	push	dx				; save ShiftState
	call	GetCurrentSelection		; ax = selection ident
	pop	dx				; dx = ShiftState
EC <	ERROR_NC	OL_ERROR					>
	mov	cl, mask GSIF_FORWARD		; navigate forward
	test	dh, mask SS_LSHIFT or mask SS_RSHIFT
	jz	navigate
	clr	cx				; navigate backward
navigate:
	mov	dx, ax				; dx = selection ident
	;XXX: check wrap-around hint here
	or	cl, mask GSIF_WRAP_AROUND
	mov	bp, 1				; move one item
	call	ScanItems			; ax = identifier
	jnc	done				; nothing found
	mov	cx, ax				; cx = new selection ident
	mov	dx, (1 shl 8)			; one selection, no flags
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	call	ObjCallInstanceNoLock
	stc					; indicate kbd accel handled
	jmp	short done

callSuper:
	mov	di, offset OLItemGroupClass
	call	ObjCallSuperNoLock
done:
	ret
OLItemGroupFindKbdAccelerator	endm

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupTestForSelectKeyEvent

DESCRIPTION:	See if the SELECT key (space bar) or RETURN key is pressed,
		and handle the event correctly for the in-menu case.

CALLED BY:	OLItemGroupKbdChar

PASS:		*ds:si	= instance data for object
		ax = MSG_META_KBD_CHAR.
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if event handled.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OLItemGroupTestForSelectKeyEvent	proc	near
	push	ax
	;
	; New code 6/23/93 cbh to not select the damn item if read-only!
	; 6/23/93 cbh
	;
	push	di	
	call	IC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	clc
	jnz	exit			;skip if read only (don't select!)

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_CTRL_M			>
DBCS <	cmp	cx, C_SYS_ENTER						>
	je	toggleExclItem		;use hit return, branch to act

SBCS <	cmp	cx, (CS_BSW shl 8) or VC_BLANK				>
DBCS <	cmp	cx, C_SPACE						>
					;is SELECT key (space bar) pressed?
	clc				;assume not
	jne	exit			;skip if not...
	
toggleExclItem:
	;the SELECT key (space bar) has been pressed.

	mov	ax, MSG_OL_IGROUP_TOGGLE_FOCUS_EXCL_ITEM
	call	IC_ObjCallInstanceNoLock

	;call a utility routine to send a method to the Flow object that
	;will force the dismissal of all menus in stay-up-mode.

	call	OLReleaseAllStayUpModeMenus
	stc				;handled
exit:
	pop	ax
	ret

OLItemGroupTestForSelectKeyEvent	endp

endif	;----------------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupTestForArrowKeyEvent

DESCRIPTION:	See if the SELECT key (space bar) or RETURN key is pressed,
		and handle the event correctly for both in-menu and
		not-in-menu cases.

CALLED BY:	OLItemGroupKbdChar

PASS:		*ds:si	= instance data for object
		ax = MSG_META_KBD_CHAR.
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if event handled.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OLItemGroupTestForArrowKeyEvent	proc	near
	;see if we are in a menu or not

	push	ax, cx, dx, bp
	call	IC_DerefVisDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	inWindow		;skip if not in menu...

	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	inMenu			;list is popped up, treat as menu

	;
	; If a non-popped, non-display-selection popup list, need to do nothing
	; here.  (3/12/94)  If a display-selection popup list, we treat as
	; in a window (i.e. we cycle through selections).  Otherwise, it's
	; just a menu, we'll treat it as such.
	;
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	inMenu			;not a popup list, treat as menu

	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYING_SELECTION
	jnz	inWindow		;displaying selection, cycle items
	jmp	short ignoreKey		;not, ignore the key.

inMenu:	;list is in a menu.
	;
	; Ignore arrow keys if alt is down -- they may have another meaning.
	; -cbh 12/ 2/92
	;
	test	dh, mask SS_LALT or mask SS_RALT
	jnz	ignoreKey

	mov	bp, -1			;pass flag: scan backwards one entry
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_UP	;is UP arrow pressed?	>
DBCS <	cmp	cx, C_SYS_UP						>
	je	10$			;skip if so...

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_DOWN ;is DOWN arrow pressed? >
DBCS <	cmp	cx, C_SYS_DOWN						>
	jne	ignoreKey		;skip if not...
	mov	bp, 1			;pass flag: scan forward one entry

10$:
	call	OLItemGroupMoveFocusToNextOrPreviousItem
	jnc	successful		;skip if navigated to new item...

ignoreKey:
	pop	ax, cx, dx, bp
	clc
	ret

inWindow: ;list is in a window

if _RUDY
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	itemGroup

	clc				;no special navigation in windows!
	jmp	short done
itemGroup:

endif
	push	ds, si
	segmov	ds, cs
	mov	si, offset OLExtendedKbdBindings
	lodsw				;set ax = # of entries in table
	call	FlowCheckKbdShortcut	;search shortcut table for match
	jnc	trySecondSet		;skip if not there

	shr	si, 1			;convert into shortcut index (0-N)
	mov	cx, si			;set cl[B1:B0] = !CTRL and !SHIFT info
	not	cl			;set cl[B1:B0] = CTRL and SHIFT info
	mov	ch, cl			;now in ch, a nicer place
	and	ch, mask OLEKF_SHIFT_PRESSED or mask OLEKF_CTRL_PRESSED
	shr	si, 1			;convert index into action #
	and	si, (not 1)		;clear lowest bit
	mov	ax, ds:OLExtendedKbdMethods[si]
					;set ax = method to send to self
	pop	ds, si
	jmp	short sendMethod

trySecondSet:
	pop	ds, si

if _USE_KBD_ACCELERATORS
	push	es
	segmov	es, cs			;set es:di = table of shortcuts
					;and matching methods
	mov	di, offset OLExtended2ndKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	done			;skip if not found...
else
	jmp	short done		;carry already clear...
endif

sendMethod:
	call	ObjCallInstanceNoLock

successful:
	stc

done:
	pop	ax, cx, dx, bp
	ret
OLItemGroupTestForArrowKeyEvent	endp





;Keyboard shortcut bindings for OLItemGroupClass (do not separate tables)

if not _RUDY ;------------------------------------------------------------

OLExtendedKbdBindings	label	word
	word	length OLExtendedShortcutList
if DBCS_PCGEOS

	;P     C  S  C
	;h  A  t  h  h
	;y  l  r  f  a
	;s  t  l  t  r
OLExtendedShortcutList	KeyboardShortcut \
	<1, 0, 1, 1, C_SPACE>,				;movement key
	<1, 0, 1, 0, C_SPACE>,				;movement key
	<1, 0, 0, 1, C_SPACE>,				;movement key
	<1, 0, 0, 0, C_SPACE>,				;movement key
	<1, 0, 1, 1, C_SYS_UP and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_UP and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_UP and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;movement key
	<1, 0, 1, 1, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<1, 0, 1, 1, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<1, 0, 1, 1, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<1, 0, 1, 1, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<1, 0, 1, 1, C_SYS_END and mask KS_CHAR>,	;movement key
	<1, 0, 1, 0, C_SYS_END and mask KS_CHAR>,	;movement key
	<1, 0, 0, 1, C_SYS_END and mask KS_CHAR>,	;movement key
	<1, 0, 0, 0, C_SYS_END and mask KS_CHAR>	;movement key

else	; not DBCS, not RUDY
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r

if _JEDIMOTIF
; Jedi kbd driver uses Ctrl to access additional keys to UP, LEFT, DOWN,
; RIGHT, so we can't have entries with Ctrl-<arrow>.  Since we need to
; keep this table structured in groups of four, we'll just change these
; to be the Ctrl-Shift versions.  We'll never match these in the table since
; we'll match the real Ctrl-Shift one first.
OLExtendedShortcutList	KeyboardShortcut \
	<0, 0, 1, 1, 0x0, VC_BLANK>,	;movement key
	<0, 0, 1, 0, 0x0, VC_BLANK>,	;movement key
	<0, 0, 0, 1, 0x0, VC_BLANK>,	;movement key
	<0, 0, 0, 0, 0x0, VC_BLANK>,	;movement key
	<0, 0, 1, 1, 0xf, VC_UP>,	;movement key
	<0, 0, 1, 1, 0xf, VC_UP>,	;movement key
	<0, 0, 0, 1, 0xf, VC_UP>,	;movement key
	<0, 0, 0, 0, 0xf, VC_UP>,	;movement key
	<0, 0, 1, 1, 0xf, VC_LEFT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_LEFT>,	;movement key
	<0, 0, 0, 1, 0xf, VC_LEFT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_DOWN>,	;movement key
	<0, 0, 1, 1, 0xf, VC_DOWN>,	;movement key
	<0, 0, 0, 1, 0xf, VC_DOWN>,	;movement key
	<0, 0, 0, 0, 0xf, VC_DOWN>,	;movement key
	<0, 0, 1, 1, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 0, 1, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_HOME>,	;movement key
	<0, 0, 1, 0, 0xf, VC_HOME>,	;movement key
	<0, 0, 0, 1, 0xf, VC_HOME>,	;movement key
	<0, 0, 0, 0, 0xf, VC_HOME>,	;movement key
	<0, 0, 1, 1, 0xf, VC_END>,	;movement key
	<0, 0, 1, 0, 0xf, VC_END>,	;movement key
	<0, 0, 0, 1, 0xf, VC_END>,	;movement key
	<0, 0, 0, 0, 0xf, VC_END>	;movement key
else	; not JEDI
OLExtendedShortcutList	KeyboardShortcut \
	<1, 0, 1, 1, 0x0, VC_BLANK>,	;movement key
	<1, 0, 1, 0, 0x0, VC_BLANK>,	;movement key
	<1, 0, 0, 1, 0x0, VC_BLANK>,	;movement key
	<1, 0, 0, 0, 0x0, VC_BLANK>,	;movement key
	<1, 0, 1, 1, 0xf, VC_UP>,	;movement key
	<1, 0, 1, 0, 0xf, VC_UP>,	;movement key
	<1, 0, 0, 1, 0xf, VC_UP>,	;movement key
	<1, 0, 0, 0, 0xf, VC_UP>,	;movement key
	<1, 0, 1, 1, 0xf, VC_LEFT>,	;movement key
	<1, 0, 1, 0, 0xf, VC_LEFT>,	;movement key
	<1, 0, 0, 1, 0xf, VC_LEFT>,	;movement key
	<1, 0, 0, 0, 0xf, VC_LEFT>,	;movement key
	<1, 0, 1, 1, 0xf, VC_DOWN>,	;movement key
	<1, 0, 1, 0, 0xf, VC_DOWN>,	;movement key
	<1, 0, 0, 1, 0xf, VC_DOWN>,	;movement key
	<1, 0, 0, 0, 0xf, VC_DOWN>,	;movement key
	<1, 0, 1, 1, 0xf, VC_RIGHT>,	;movement key
	<1, 0, 1, 0, 0xf, VC_RIGHT>,	;movement key
	<1, 0, 0, 1, 0xf, VC_RIGHT>,	;movement key
	<1, 0, 0, 0, 0xf, VC_RIGHT>,	;movement key
	<1, 0, 1, 1, 0xf, VC_HOME>,	;movement key
	<1, 0, 1, 0, 0xf, VC_HOME>,	;movement key
	<1, 0, 0, 1, 0xf, VC_HOME>,	;movement key
	<1, 0, 0, 0, 0xf, VC_HOME>,	;movement key
	<1, 0, 1, 1, 0xf, VC_END>,	;movement key
	<1, 0, 1, 0, 0xf, VC_END>,	;movement key
	<1, 0, 0, 1, 0xf, VC_END>,	;movement key
	<1, 0, 0, 0, 0xf, VC_END>	;movement key
endif	; JEDI, not DBCS, not RUDY
endif	; DBCS, not RUDY

OLExtendedKbdMethods	label word
	word	MSG_OL_IGROUP_TOGGLE_FOCUS_EXCL_ITEM
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_START
	word	MSG_OL_IGROUP_SET_SELECTION_TO_END

else ; _RUDY ------------------------------------------------------------

OLExtendedKbdBindings	label	word
	word	length OLExtendedShortcutList
if DBCS_PCGEOS

	;P     C  S  C
	;h  A  t  h  h
	;y  l  r  f  a
	;s  t  l  t  r
OLExtendedShortcutList	KeyboardShortcut \
	<0, 0, 1, 1, C_SPACE>,				;movement key
	<0, 0, 1, 0, C_SPACE>,				;movement key
	<0, 0, 0, 1, C_SPACE>,				;movement key
	<0, 0, 0, 0, C_SPACE>,				;movement key
	<0, 0, 1, 1, C_SYS_UP and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_UP and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_UP and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;movement key


	<0, 0, 1, 1, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_PREVIOUS and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_PREVIOUS and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_PREVIOUS and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_PREVIOUS and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 1, 0, 1, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 1, 1, 1, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_NEXT and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_NEXT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_NEXT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_NEXT and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 1, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 1, 1, 0, C_SYS_TAB and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_HOME and mask KS_CHAR>,	;movement key
	<0, 0, 1, 1, C_SYS_END and mask KS_CHAR>,	;movement key
	<0, 0, 1, 0, C_SYS_END and mask KS_CHAR>,	;movement key
	<0, 0, 0, 1, C_SYS_END and mask KS_CHAR>,	;movement key
	<0, 0, 0, 0, C_SYS_END and mask KS_CHAR>	;movement key

else	; not DBCS, RUDY
	 ;P     C  S     C
	 ;h  A  t  h  S  h
	 ;y  l  r  f  e  a
	 ;s  t  l  t  t  r

OLExtendedShortcutList	KeyboardShortcut \
	<0, 0, 1, 1, 0x0, VC_BLANK>,	;movement key
	<0, 0, 1, 0, 0x0, VC_BLANK>,	;movement key
	<0, 0, 0, 1, 0x0, VC_BLANK>,	;movement key
	<0, 0, 0, 0, 0x0, VC_BLANK>,	;movement key
	<0, 0, 1, 1, 0xf, VC_UP>,	;movement key
	<0, 0, 1, 0, 0xf, VC_UP>,	;movement key
	<0, 0, 0, 1, 0xf, VC_UP>,	;movement key
	<0, 0, 0, 0, 0xf, VC_UP>,	;movement key
	<0, 0, 1, 1, 0xf, VC_LEFT>,	;movement key
	<0, 0, 1, 0, 0xf, VC_LEFT>,	;movement key
	<0, 0, 0, 1, 0xf, VC_LEFT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_PREVIOUS>,	;movement key
	<0, 0, 1, 0, 0xf, VC_PREVIOUS>,	;movement key
	<0, 0, 0, 1, 0xf, VC_PREVIOUS>,	;movement key
	<0, 0, 0, 0, 0xf, VC_PREVIOUS>,	;movement key
	<0, 0, 0, 1, 0xf, VC_TAB>,	;movement key
	<0, 1, 0, 1, 0xf, VC_TAB>,	;movement key
	<0, 0, 1, 1, 0xf, VC_TAB>,	;movement key
	<0, 1, 1, 1, 0xf, VC_TAB>,	;movement key
	<0, 0, 1, 1, 0xf, VC_DOWN>,	;movement key
	<0, 0, 1, 0, 0xf, VC_DOWN>,	;movement key
	<0, 0, 0, 1, 0xf, VC_DOWN>,	;movement key
	<0, 0, 0, 0, 0xf, VC_DOWN>,	;movement key
	<0, 0, 1, 1, 0xf, VC_NEXT>,	;movement key
	<0, 0, 1, 0, 0xf, VC_NEXT>,	;movement key
	<0, 0, 0, 1, 0xf, VC_NEXT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_NEXT>,	;movement key
	<0, 0, 1, 1, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 1, 0, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 0, 1, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;movement key
	<0, 0, 0, 0, 0xf, VC_TAB>,	;movement key
	<0, 1, 0, 0, 0xf, VC_TAB>,	;movement key
	<0, 0, 1, 0, 0xf, VC_TAB>,	;movement key
	<0, 1, 1, 0, 0xf, VC_TAB>,	;movement key
	<0, 0, 1, 1, 0xf, VC_HOME>,	;movement key
	<0, 0, 1, 0, 0xf, VC_HOME>,	;movement key
	<0, 0, 0, 1, 0xf, VC_HOME>,	;movement key
	<0, 0, 0, 0, 0xf, VC_HOME>,	;movement key
	<0, 0, 1, 1, 0xf, VC_END>,	;movement key
	<0, 0, 1, 0, 0xf, VC_END>,	;movement key
	<0, 0, 0, 1, 0xf, VC_END>,	;movement key
	<0, 0, 0, 0, 0xf, VC_END>	;movement key
endif	; DBCS, RUDY

OLExtendedKbdMethods	label word
	word	MSG_OL_IGROUP_TOGGLE_FOCUS_EXCL_ITEM
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	word	MSG_OL_IGROUP_SET_SELECTION_TO_START
	word	MSG_OL_IGROUP_SET_SELECTION_TO_END

endif ;_RUDY ------------------------------------------------------------


if _USE_KBD_ACCELERATORS

OLExtended2ndKbdBindings	label	word
	word	length OLExtended2ndKbdList

if _RUDY


  if DBCS_PCGEOS
  OLExtended2ndKbdList	KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>,
	<1, 0, 1, 0, C_SMALL_A >	;Ctrl-A: (de)select all items
  else
  OLExtended2ndKbdList	KeyboardShortcut \
	<1, 0, 0, 0, 0xf, VC_ESCAPE >,
	<1, 0, 1, 0, 0x0, C_SMALL_A >	;Ctrl-A: (de)select all items
  endif

  ;OLExtended2ndKbdMethods	label word
	  word	MSG_OL_IGROUP_DESELECT_ALL
	  word	MSG_OL_IGROUP_TOGGLE_ALL_SELECTED

else ; not _RUDY

  if DBCS_PCGEOS
  OLExtended2ndKbdList	KeyboardShortcut \
      <1, 0, 0, 1, C_SYS_F8 and mask KS_CHAR>,	;Shift-F8: switch to add mode
      <0, 0, 1, 0, C_BACKSLASH >		;Ctrl-\: deselect all items
  else
  OLExtended2ndKbdList	KeyboardShortcut \
	  <1, 0, 0, 1, 0xf, VC_F8>,	;Shift-F8: switch to add mode
	  <0, 0, 1, 0, 0x0, C_BACKSLASH >	;Ctrl-\: deselect all items
  endif

  ;OLExtended2ndKbdMethods	label word
	  word	MSG_OL_IGROUP_TOGGLE_ADD_MODE
	  word	MSG_OL_IGROUP_DESELECT_ALL

endif ; not _RUDY

endif ; _USE_KBD_ACCELERATORS

;pass bp = direction to move focus

OLItemGroupMoveFocusToNextOrPreviousItem	proc	near

	;get the optr of the GenListEntry which has the current focus excl,
	;or the optr of the first item which is USABLE and ENABLED.

	push	bp
	call	OLItemGroupGetCurrentFocusExclOrFirst
	pop	bp
EC <	ERROR_NC OL_ERROR_GEN_LIST_WITHOUT_USABLE_AND_ENABLED_KIDS_GIVEN_FOCUS >

	;assume there was no focus exclusive, set it now.

	call	SetFocusFromOptr		;set focus item to ^lcx:dx

	;pretend that the mouse is dragging off of the currently focused
	;item. Will redraw itself, and send a method to the list (delayed via
	;the UI queue) so that the EXCLUSIVE owner is re-selected if no other
	;item in the list is pressed on ("navigated to").

	push	si, cx, dx, bp
	mov	bx, cx
	mov	si, dx
	mov	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER or \
		    mask OIENPF_REDRAW_PRESSED_ITEM
	mov	ax, MSG_OL_ITEM_ENSURE_IS_NOT_PRESSED
	call	IC_ObjMessageCall
	pop	si, cx, dx, bp

	
	;find the optr of the object which follows this one

	push	bp				;save direction
	call	GetFocusItem			;dx <- current item with focus
EC <	ERROR_NC	-1			;just set focus above!	>
	pop	bp				;restore direction

	mov	cl, mask GSIF_FORWARD 
	tst	bp
	jns	10$				;yes, branch
	clr	cx
	neg	bp				;keep absolute
10$:
	;
	; Allow wrapping around in popup lists.  In other menus, wrapping is
	; handled in the menu code.
	;
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	20$
	or	cl, mask GSIF_WRAP_AROUND
20$:
	
	push	dx
	call	ScanItems			;scan for item
	pop	bp
	cmc					;carry now set if failed
	jc	done
	cmp	ax, bp				;did the focus move?
	stc					;assume not, we'll return fail
	je	done				;nope, exit

	;pretend that the mouse button was pressed on this item: set the
	;DEPRESSED flag, and startup INTERMEDIATE mode if this is an
	;exclusive list which cannot show depressed emphasis. This will
	;also move the focus exclusive to the item.

	push	si
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_OL_ITEM_ENSURE_IS_PRESSED
	call	IC_ObjMessageCall
	pop	si
	clc				;return flag: was successful

done:
	ret
OLItemGroupMoveFocusToNextOrPreviousItem	endp

endif	;----------------------------------------------------------------------





COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLItemGroupClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= optr of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= optr of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLItemGroupClass handler:
		NCF_IS_ROOT_NODE = FALSE
		NCF_IS_COMPOSITE = FALSE
	   	NCF_FOCUSABLE = FALSE
		if ENABLED {
		    if (USER_EXCL != 0:0) OR (FindFirstUsableChild) {
			NCF_FOCUSABLE = TRUE
		    }
		}
		NCF_MENUABLE = TRUE if is in menu
		call VisNavigateCommon to handle query

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNavigate	method	dynamic OLItemGroupClass, \
						MSG_SPEC_NAVIGATION_QUERY

if _RUDY
	;
	; Checkbox item groups (i.e. boolean groups) should just act as a 
	; transparent composite in Rudy.
	;
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jz	returnFocusedItem
	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock

returnFocusedItem:
endif
	call	OpenCheckIfKeyboard
	jnc	notEnabled		;no keyboard, can't take focus. 4/20/93

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	notEnabled		;toolbox, can't navigate here

	;other ERROR CHECKING is in VisNavigateCommon

if _KBD_NAVIGATION	;------------------------------------------------------
	;see if this GenList is enabled or not...

	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	notEnabled		;skip if not enabled...

	;get optr of current FOCUS_EXCL, or first item in list which is
	;USABLE and ENABLED.

	push	ax, cx, dx, bp		;save optr of originator
	call	OLItemGroupGetCurrentFocusExclOrFirst
	pop	ax, cx, dx, bp
	mov	bl, mask NCF_IS_FOCUSABLE
	jc	haveFlags		;skip if found item...
endif			;------------------------------------------------------

notEnabled: ;this GenList is disabled, has no usable entries, OR this specific
	    ;UI does not support keyboard navigation.

	clr	bl 			;default: not root-level node, is not
					;composite node, is not focusable
	
haveFlags:
	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and whether or not this object can
	;get the focus. This routine will check the passed NavigationFlags
	;and decide what to respond.

	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	ret
OLItemGroupNavigate	endm

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupGainedFocusExcl

DESCRIPTION:	This procedure is called when the window in which this GenList
		is located decides that this object has the focus exclusive.
		Now, GenLists are not supposed to have the focus -- their
		children are. So pass the focus on to the child which has
		the USER exclusive, or the first usable child. If do not have
		any usable children, should not have been given the focus in
		the first place!

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of object which has lost focus exclusive

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupGainedFocusExcl	method	dynamic OLItemGroupClass, \
						MSG_META_GAINED_FOCUS_EXCL

	;first set a flag indicating that this list has the focus. When
	;we tell the first child to grab the focus, it will (because of this
	;intermediate mode shit) ask this parent if it has the focus.
	;The parent must respond YES for the child to grab the focus,
	;so let's set this flag...

	ORNF	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL

	;if this item is in a menu, set the focus to the first usable
	;child. If no usable children, we shouldn't have been given the
	;focus in the first place: die horribly.

	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	inWindow		;skip if not inside menu...

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jnz	inWindow		;popup list, don't act like a menu.

inMenu:	;somewhat of a hack: see if this list gained the focus because
	;of an up-arrow, down-arrow, or other keypress. Get character
	;which was saved when navigation command was parsed.

	call	OpenGetNavigationChar
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_UP				>
DBCS <	cmp	cx, C_SYS_UP						>
	je	findLast		;skip if is UP arrow...

findFirst:

	mov	cl, mask GSIF_FORWARD or mask GSIF_FROM_START
	call	ScanItems
	jmp	short setFocusExcl

findLast:
	mov	cl, mask GSIF_FROM_START	;backward
	call	ScanItems

setFocusExcl:
	jc	pressOnItem
;EC <	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST		      >
;EC <	ERROR_Z OL_ERROR_GEN_LIST_WITHOUT_USABLE_AND_ENABLED_KIDS_GIVEN_FOCUS >

navigateToNextField:
	;Change made 6/23/92 cbh to navigate out of this thing if there are no
	;children here.

	call	OLItemGroupMoveFocusToNextField
	ret					
						
pressOnItem:
	;pretend that the mouse button was pressed on this item: set the
	;DEPRESSED flag, and startup INTERMEDIATE mode if this is an
	;exclusive list which cannot show depressed emphasis. This will
	;also move the focus exclusive to the item.

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_OL_ITEM_ENSURE_IS_PRESSED
	call	IC_ObjMessageCall
	ret

inWindow:
	call	OLItemGroupGetCurrentFocusExclOrFirst

	;
	; It's generally illegal to have a list with no enabled or usable
	; children, unless it's a dynamic list that hasn't been realized.
	;
;EC <	jc	EC10							       >
;EC <	mov	di, ds:[si]						       >
;EC <	add	di, ds:[di].Vis_offset					       >
;EC <	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC			       >
;EC <	ERROR_Z OL_ERROR_GEN_LIST_WITHOUT_USABLE_AND_ENABLED_KIDS_GIVEN_FOCUS  >
;EC <	test	ds:[di].VI_attrs, mask VA_REALIZED			       >
;EC <	ERROR_NZ OL_ERROR_GEN_LIST_WITHOUT_USABLE_AND_ENABLED_KIDS_GIVEN_FOCUS >
;EC <EC10:
	;								       >
	; Try changing this so that if a dynamic list is given the focus, and
	; doesn't yet have any children, assume that it will soon have some,
	; and will keep the focus for that eventuality.  -cbh 11/ 2/92
	;
;	jnc	navigateToNextField			;no child, try 
							;  navigating out
	jnc	exit					
	call	OLItemGroupVupGrabFocusExclForItem
exit:
	ret
OLItemGroupGainedFocusExcl	endm


OLItemGroupLostFocusExcl	method	dynamic OLItemGroupClass, \
						MSG_META_LOST_FOCUS_EXCL

	;we intercept this here to reset our state flag, so that we don't
	;think that we have the focus.

	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_LIST_HAS_FOCUS_EXCL)

	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock

OLItemGroupLostFocusExcl	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyItemGainedFocusExcl --
			MSG_OL_IGROUP_NOTIFY_ITEM_GAINED_FOCUS_EXCL
FUNCTION:	OLItemGroupNotifyItemLostFocusExcl --
			MSG_OL_IGROUP_NOTIFY_ITEM_LOST_FOCUS_EXCL

DESCRIPTION:	This method is sent from a child OLItemClass object when
		it gains the FOCUS exclusive. This is usually the result
		of navigation.

		IMPORTANT: note that this method is handled by subclasses
		such as OLDynamicList, so that this info may be stored
		in terms of an item #.

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of child

RETURN:		ds, si, cx, dx = same

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyItemGainedFocusExcl	method	private static \
				OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_ITEM_GAINED_FOCUS_EXCL

	call	SetFocusFromOptr	;set as focus item
if DISABLED_ITEMS_ARE_SELECTABLE and MENUS_HAVE_APPLY_CANCEL_BUTTONS
	call	UpdateItemGroupApplyTrigger
endif
	call	IC_DerefVisDI
	ORNF	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	ret
OLItemGroupNotifyItemGainedFocusExcl	endm

OLItemGroupNotifyItemLostFocusExcl	method	private static \
				OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_ITEM_LOST_FOCUS_EXCL

	call	IC_DerefVisDI

	;reset our state flag, but DO NOT set the focus = none,
	;because we want to resume navigation from the same place when this
	;list gains the focus again. Note that if a list item is being set
	;not usable, then OLItemReleaseAllExclusives will clear this OD.

	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_LIST_HAS_FOCUS_EXCL)
	ret
OLItemGroupNotifyItemLostFocusExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateItemGroupApplyTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the IC_APPLY (OK) trigger
		is enabled/disabled, depending on the enabled
		state of the currently selected item.

CALLED BY:	OLItemGroupNotifyItemGainedFocusExcl
		OLItemGroupNotifyItemSetNotEnabled
		OLItemGroupNotifyItemSetEnabled

PASS:		*ds:si	= OLItemGroup object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We do this on Rudy, because the IC_APPLY trigger has slightly
	different behavior than in other UIs.  If the selection bar
	is on a disabled item (as it can be, in Rudy), the OK trigger 
	should be grayed out to prevent it's actual selection.

	The preferable way to do this is just to send
	MSG_GEN_MAKE_{NOT_}APPLYABLE up the tree, but Rudy doesn't
	deal with this very well (at all), so we'll have to enable/disable
	the trigger ourselves.

	This functionality depends on both DISABLED_ITEMS_ARE_SELECTABLE
	and MENUS_HAVE_APPLY_CANCEL_BUTTONS, because it doesn't make
	sense to be disabling the OK trigger in UI's where a dialog
	might contain other gadgets besides the list object.
	MENUS_HAVE_APPLY_CANCEL_BUTTONS sort of implies that
	list objects get their very own dialogs.  If you can make
	this work in other situations, though, more power to you.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DISABLED_ITEMS_ARE_SELECTABLE and MENUS_HAVE_APPLY_CANCEL_BUTTONS

UpdateItemGroupApplyTrigger	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; Find out which item has the focus
	;

	call	GetFocusItemOptr		; ^lcx:dx = focused item
						; ax,di,bp destroyed
	jnc	disable				; no focus? disable, I guess

	;
	; Is it enabled or not?
	;

	push	si				; +1 ItemGroup
	mov	ax, MSG_GEN_GET_ENABLED
	movdw	bxsi, cxdx
	call	IC_ObjMessageCall
	pop	si				; -1 ItemGroup
	jnc	disable

	;
	;  Focus && enabled --> applyable
	;

	mov	ax, MSG_GEN_SET_ENABLED
update:

	;
	; Ask the parent dialog for it's OK trigger, so that
	; we can do nasty things to it.
	;

	push	ax				; +1 enable/disable message

	;
	; If we're not inside a dialog, then forget it.
	;

	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment OLDialogWinClass
	mov	dx, offset  OLDialogWinClass
	call	IC_ObjCallInstanceNoLock	; ^lcx:dx = object
	jnc	donePopAX			;   not in a dialog

	;
	; We're in a dialog.  Try to find it's IC_APPLY trigger
	;

	movdw	bxsi, cxdx
	mov	ax, MSG_OL_DIALOG_WIN_FIND_STANDARD_TRIGGER
	mov	cx, IC_APPLY
	call	IC_ObjMessageCall		; ^ldx:bp = trigger
	pop	ax				; -1 enable/disable message
	jnc	done

	;
	; Found the trigger.  Send it the Enable/Disable message
	;

	movdw	bxsi, dxbp
	mov	dx, VUM_NOW
	call	IC_ObjMessageCall
done:
	.leave
	ret

donePopAX:
	pop	ax
	jmp	done

disable:
	;
	; ~focus || ~enabled --> ~applyable
	;

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	update

UpdateItemGroupApplyTrigger	endp

endif ; DISABLED_ITEMS_ARE_SELECTABLE and MENUS_HAVE_APPLY_CANCEL_BUTTONS

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyItemSetNotEnabled
			-- MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_ENABLED handler

DESCRIPTION:	This method is sent when a child item is set NOT USABLE.
		We want to move the USER, ACTUAL, and FOCUS exclusives
		elsewhere if necessary.

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of object being set not USABLE
		bp = OLIS_NAVIGATE_IF_DISABLED, OLIS_NAVIGATE_BACKWARD
		     possibly set

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyItemSetNotEnabled	method	private static \
				OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_ENABLED

	;if this GenList object is NOT_ENABLED, then we should not have to
	;worry about all of this. The parent would have moved the FOCUS
	;elsewhere already, and we don't want to move the USER and ACTUAL
	;exclusives.

	call	VisCheckIfFullyEnabled
	jnc	exit			;skip if GenList is not enabled...

	;
	; If doing extended selection, let's make sure this item is deselected.
	; It's not going to get deselected through other means.
	;
	call	CheckIfExtendingSelection
	jnc	10$
	push	bp, cx, dx
	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	IC_ObjMessageCall	;returns identifier in ax
	mov	cx, ax
	pop	si
	clr	dx			;clear item's selected status
	mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
	call	IC_ObjCallInstanceNoLock
	pop	bp, cx, dx
10$:
	;
	; If we need to navigate some, let's do it.  Let's let things finish
	; up first, though.
	;
	test	bp, mask OLIS_NAVIGATE_IF_DISABLED
	jnz	navigate

if DISABLED_ITEMS_ARE_SELECTABLE
	;
	; In Responder, disabled items can have the focus, so don't worry
	; about moving the focus elsewhere.  Just worry about keeping
	; "OK" up to date.
	;
if MENUS_HAVE_APPLY_CANCEL_BUTTONS ; and DISABLED_ITEMS_ARE_SELECTABLE

	call	UpdateItemGroupApplyTrigger

endif ; MENUS_HAVE_APPLY_CANCEL_BUTTONS

	jmp	exit

else ; not DISABLED_ITEMS_ARE_SELECTABLE

	GOTO	OLItemGroupNotifyItemSetNotUsable

endif

navigate:
	;
	; Navigate to the next or previous item, depending on what flag was
	; stored with the item being disabled.
	;
	mov	ch, mask OLEKF_USE_PREVIOUS		;use old shift state
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	test	bp, mask OLIS_NAVIGATE_BACKWARD
	jz	doit
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
doit:	
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE 
	call	IC_ObjMessage
exit:	
	ret
OLItemGroupNotifyItemSetNotEnabled	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyItemSetNotUsable
			-- MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_USABLE handler

DESCRIPTION:	This method is sent when a child item is set NOT USABLE.
		We want to move the USER, ACTUAL, and FOCUS exclusives
		elsewhere if necessary.

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of object being set not USABLE

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyItemSetNotUsable	method	private static \
				OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_USABLE

	;first, if the FOCUS exclusive is on this list or its kids,
	;and this list thinks that the ^lcx:dx item has the FOCUS,
	;then move the FOCUS to the first USABLE item. If none, then navigate
	;to the next gadget in this window.

	call	IsFocusItemOptr			;see if current focus item
	jne	done				;nope, done

	clr	bx				;else clear the focus
	call	SetFocusItem
					;first reset focus OD, in case this
					;window (menu) does not have the focus.

	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	done			;skip if focus is elsewhere...

	call	OLItemGroupMoveFocusElsewhere
done:
if _ODIE
	;
	; if ODIE tab group, invalidate children as they need to redraw to
	; update overlapping tab areas
	;
	push	ax, bx, cx, dx
	mov	ax, HINT_ITEM_GROUP_TAB_STYLE
	call	ObjVarFindData
	jnc	exit
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_VIS_MARK_INVALID
	call	VisSendToChildren
exit:
	pop	ax, bx, cx, dx
endif
	ret
OLItemGroupNotifyItemSetNotUsable	endp







COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupMoveFocusElsewhere

DESCRIPTION:	This routine is called when an item in the list is set
		NOT USABLE, and that item has the focus exclusive on it.
		We try to place the focus on the first USABLE item.
		If none exists, then we request that the focus be moved
		elsewhere in the window. If this fails...

CALLED BY:	OLItemGroupNotifyItemSetNotUsable

PASS:		*ds:si	= instance data for object
		ds:di	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupMoveFocusElsewhere	proc	near
	uses	cx, dx, bp
	.enter

	;The FOCUSED item has been set NOT USABLE or NOT ENABLED.
	;Let's just move the focus to the first item in this list.

	call	OLItemGroupGetFirstItemOptr
	jc	haveOD			;skip if found one...

	;there are no usable entries in this list: navigate to the next
	;gadget in this window.

	call	IC_DerefVisDI
	call	OLItemGroupMoveFocusToNextField
	jmp	short done

haveOD:	;move the FOCUS exclusive to ^lcx:dx

	call	OLItemGroupVupGrabFocusExclForItem

done:
	.leave
	ret
OLItemGroupMoveFocusElsewhere	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupSpecSetNotUsable -- MSG_SPEC_SET_NOT_USABLE

DESCRIPTION:	This method is sent when this GenList is set not usable.
		We intercept it here, to make sure that the focus is moved
		to the NEXT object in the window.

PASS:		*ds:si	= instance data for object
		dl	= VisUpdateMode

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupSpecSetNotUsable	method	dynamic OLItemGroupClass, \
					MSG_SPEC_SET_NOT_USABLE

	;if this list (actually, any child of the list) has the focus,
	;then push it elsewhere in the window. If there are no other focusable
	;gadgets in the window, the query will land on this object again,
	;but the OLIGS_LIST_HAS_FOCUS_EXCL flag will be reset, so the window
	;will just end up with no focused object at all.

	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	callSuper		;skip if no focus here...

	;note: calling this routine will not longer ensure that
	;focus is reset.

	push	ax, dx
	call OLItemGroupMoveFocusToNextField
	pop	ax, dx

callSuper:
	mov	di, offset OLItemGroupClass
	CallSuper MSG_SPEC_SET_NOT_USABLE
	ret
OLItemGroupSpecSetNotUsable	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupMoveFocusToNextField

DESCRIPTION:	There are no usable entries in the list, so navigate to
		the next gadget in the window.

CALLED BY:	OLItemGroupSpecSetNotUsable, OLItemGroupMoveFocusElsewhere

PASS:		*ds:si	= instance data for object
		ds:di	= instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupMoveFocusToNextField	proc	far
	class	OLItemGroupClass

	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_LIST_HAS_FOCUS_EXCL)

	mov	ax, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	call	VisCallParent

	;if the focus is still on this object, forcibly release it.

	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_LIST_HAS_FOCUS_EXCL
	jz	done

	call	MetaReleaseFocusExclLow

	;in case this List is in a window which does not have the focus,
	;let's  reset our state variable, as we will not be getting
	;LOST_FOCUS_EXCL notification.

	call	IC_DerefVisDI
	ANDNF	ds:[di].OLIGI_state, not (mask OLIGS_LIST_HAS_FOCUS_EXCL)

done:
	ret
OLItemGroupMoveFocusToNextField	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGroupNotifyDoublePress --
			MSG_OL_IGROUP_NOTIFY_DOUBLE_PRESS

DESCRIPTION:	Sent by GenListEntry when the user double-clicks
		on it.

PASS:		*ds:si	= instance data for object
		^lcx:dx	= optr of GenListEntry

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemGroupNotifyDoublePress	method	dynamic OLItemGroupClass, \
				MSG_OL_IGROUP_NOTIFY_DOUBLE_PRESS
if not _JEDIMOTIF
	call	IsNonExclusive
	jc	exit			;do nothing in non-exclusive list...
	call	IC_DerefGenDI		
	cmp	ds:[di].GIGI_behaviorType, GIGBT_EXCLUSIVE_NONE
	je	exit			;nor on exclusive-none.

	mov	bp, MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
					; assume no double-click msg
	mov	di, cs
	mov	es, di
	mov	di, offset cs:DoublePressHint
	mov	ax, length (cs:DoublePressHint)
	call	ObjVarScanData		; ax changed if attr exists
	mov	ax, bp
	cmp	ax, MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
	jne	10$			; new message, branch

	call	OpenCheckDefaultRings	; not allowing default rings, no
	jnc	exit			;   doublepress default allowed

	call	IC_DerefVisDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jnz	exit			; inside menu, do nothing!
	GOTO	ObjCallInstanceNoLock	; else call self to handle default
10$:
	;
	; Send out the double press message.
	; 
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES
	jnz	sendBooleanMsg

	call	IC_DerefGenDI
	mov	cl, ds:[di].GIGI_stateFlags
	mov	di, cx				;allow closing of windows
	call	GenItemSendMsg
	jmp	short exit

sendBooleanMsg:
	call	IC_DerefGenDI
	mov	cx, ds:[di].GBGI_modifiedBooleans
	mov	di, cx				;allow closing of windows
	call 	GenBooleanSendMsg
exit:
endif	; !_JEDI
	ret

OLItemGroupNotifyDoublePress	endm

if not _JEDIMOTIF
DoublePressHint	VarDataHandler \
	<ATTR_GEN_ITEM_GROUP_CUSTOM_DOUBLE_PRESS, offset CustomDoublePress>

CustomDoublePress	proc	far
	mov	bp, {word} ds:[bx]		;get double-press message
	ret
CustomDoublePress	endp

endif	; not _JEDIMOTIF


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupActivate -- 
		MSG_GEN_ACTIVATE for OLItemGroupClass

DESCRIPTION:	If we get one, and we're a popup list, we'll send it to our
		interaction.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ACTIVATE

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
	chris	9/30/92		Initial Version

------------------------------------------------------------------------------@

OLItemGroupActivate	method dynamic	OLItemGroupClass, MSG_GEN_ACTIVATE
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	notPopupList		;get out if not popup list

if _RUDY
	mov	si, ds:[di].OLIGI_popupInteraction
	tst	si
	jz	exit
	call	ObjCallInstanceNoLock
else
	call	CallOLWin		;else send to our interaction
endif
	jmp	short exit

notPopupList:
	mov	ax, MSG_GEN_MAKE_FOCUS	;let's at least take the focus.
	call	IC_ObjCallInstanceNoLock
exit:
	ret
OLItemGroupActivate	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLItemGroupClass

DESCRIPTION:	Specific UI handler for setting the vis moniker.
		Sets OLCOF_DISPLAY_MONIKER flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@

OLItemGroupUpdateVisMoniker	method OLItemGroupClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jnz	sendToPopup

	mov	di, offset OLItemGroupClass
	GOTO	ObjCallSuperNoLock

sendToPopup:
	push	ax, cx, dx, bp
	call	SetPopupListMonikerIfNeeded
	pop	ax, cx, dx, bp
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
	jnz	done			; already updated by routine

	;
	; Used to just send a MSG_SPEC_UPDATE_VIS_MONIKER to the parent
	; window, which doesn't move any monikers around.  Let's correctly
	; replace the moniker in the parent window.  -cbh 12/22/92
	;
	mov	bp, dx				;VisUpdateMode in bp
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].GI_visMoniker	;moniker chunk to use
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR

if _RUDY
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLIGI_popupInteraction
	tst	si
	jz	done
	call	ObjCallInstanceNoLock
else
	GOTO	CallOLWin
endif

done:
	ret

OLItemGroupUpdateVisMoniker	endm

ItemCommon ends
ItemCommon segment resource

IC_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
IC_DerefGenDI	endp

IC_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
IC_DerefVisDI	endp

IC_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
IC_ObjCallInstanceNoLock	endp

IC_ObjMessageCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	IC_ObjMessage
IC_ObjMessageCall	endp

IC_ObjMessage		proc	near
	call	ObjMessage
	ret
IC_ObjMessage		endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGroupTestForRedundantIntSelection -- 
		MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION 
		for OLItemGroupClass

DESCRIPTION:	Tests for a redundant selection.  See the message header for
		more info.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	-MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION
		bp	- non-zero if we're to get info from instance data, else
			  cx	- current item being released by user

RETURN:		carry set if the selection is redundant
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/31/92		Initial Version
	chris	12/ 1/92	Rewritten to handle multiple, zero selections

------------------------------------------------------------------------------@

OLItemGroupTestForRedundantIntSelection method dynamic	OLItemGroupClass, \
			MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION

EC <	test	ds:[di].OLIGI_state, mask OLIGS_CHECKBOXES		 >
EC <	ERROR_C	OL_ERROR		;doesn't work for non-excl lists >

	mov	bx, ds:[di].OLIGI_prevSelections
	;
	; First, setup es:di to point to a list of current selections, either
	; passed in or from instance data, depending on bp.  dx holds the
	; number of selections.
	;
	sub	sp, size word		;leave room for one selection on stack
	tst	bp			;get from instance data?
	jz	selectionInCX		;no, branch

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GIGI_numSelections
	mov	cx, ds:[di].GIGI_selection
	cmp	dx, 1
	jne	instanceData		;zero or multi selections, branch

selectionInCX:
	mov	di, sp			;else ss:di points to stuff
	segmov	es, ss			;now es:di
	mov	{word} es:[di], cx	;store selection there
	mov	dx, 1
	jmp	short checkPrevSelections

instanceData:
	tst	dx			;no selection, continue on.
	jz	checkPrevSelections	
	;
	; Getting multiple selections from instance data, point to the chunk.
	;
	mov	di, cx			;chunk in *ds:di
	mov	di, ds:[di]		;now in ds:di
	segmov	es, ds			;now in es:di

checkPrevSelections:
	;
	; The prevSelections chunk is in bx.  If there's nothing, we'll 
	; compare to the current selection, if any.   We'll assume that we're
	; never comparing to instance data here, as that's only done for
	; extended selections.
	;
	tst	bx							    
	jnz	intermediateMode

EC <	tst	bp			;working with one passed sel, right? >
EC <	ERROR_NZ	OL_ERROR	;assumption failed.  Dang.           >

	push	cx, di
	call	GetCurrentSelection	;ax <- current selection
	pop	cx, di
	jnc	notRedundant		;Oh, there wasn't one, no dedundancy
	cmp	ax, es:[di]		;do we have a match?
	jmp	short comparisonMade

intermediateMode:
	ChunkSizeHandle	ds, bx, ax	;size of selections in ax
	shr	ax, 1			;halve for number of items
	mov	bx, ds:[bx]		;deref, buffer now in ds:bx
	mov	si, bx			;ds:si points to selection

compareSelections:
	;
	; Now compare our lists of selections.
	;
	cmp	ax, dx			;same number of items?
	jne	notRedundant
	mov	cx, dx			;count in cx
	repe	cmpsw			;do a comparison

comparisonMade:
	stc				;assume exactly matches (redundant)
	je	exit			;yep, exit
	
notRedundant:
	clc				;else not redundant

exit:
	lahf				;save flags
	add	sp, word
	sahf				;restore flags
	ret
OLItemGroupTestForRedundantIntSelection	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupGetActivatorBounds -- 
		MSG_META_GET_ACTIVATOR_BOUNDS for OLItemGroupClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns bounds of activator.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemGroupClass
		ax 	- MSG_META_GET_ACTIVATOR_BOUNDS

RETURN:		carry set if handled, with:
			ax, bp, cx, dx - screen bounds of object

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/24/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS

OLItemGroupGetActivatorBounds	method dynamic	OLItemGroupClass, \
				MSG_META_GET_ACTIVATOR_BOUNDS
	clr	cx
	mov	dx, cx				;assume no item
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	returnOurBounds			;no focus item, exit, carry clr
	mov	cx, ds:[di].OLIGI_focusItem
	call	GetOptr
	jnc	returnOurBounds			;no focus, exit

	movdw	bxsi, cxdx
	mov	ax, MSG_META_GET_ACTIVATOR_BOUNDS
	mov	di, mask MF_CALL
	call	ObjMessage			;take value from item

exit:
	ret

returnOurBounds:
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		;BP <- GState handle
	mov	di, bp

	call	VisGetBounds	;AX <- left edge of the object
	
	; Check if point is in window bounds.  If not, return carry clear.
	call	CheckIfPointInWinBounds
	jnc	exit
	
	call	GrTransform	;Transform AX,BX to screen coords
	call	GrDestroyState
	mov	cx, ax		;AX,CX <- left edge of obj
	mov	bp, bx		;BP,DX <- middle of obj vertically
	mov	dx, bx
	stc
	jmp	exit

OLItemGroupGetActivatorBounds	endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupPopupListApply -- 
		MSG_SPEC_POPUP_LIST_APPLY for OLItemGroupClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Popup list apply.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemGroupClass
		ax 	- MSG_SPEC_POPUP_LIST_APPLY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/26/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLItemGroupPopupListApply	method dynamic	OLItemGroupClass, \
				MSG_SPEC_POPUP_LIST_APPLY

	;
	; If non-exclusive list, assume selections are already set,
	; and just send out apply message.
	;
	call	IsExtendedSelection
	jc	apply

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	jnc	apply			;something selected, so apply

	; nothing is selected, so select the item with the focus

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	apply			;no focus item, so apply

	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	mov	cx, ds:[di].OLIGI_focusItem
	mov	dx, 0100h		;one selection, OLItemUpdateFlags = 0
	call	ObjCallInstanceNoLock
apply:
	mov	ax, MSG_GEN_APPLY
	GOTO	ObjCallInstanceNoLock

OLItemGroupPopupListApply	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemGroupChange -- 
		MSG_SPEC_CHANGE for OLItemGroupClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Does a "change" for this ItemGroup.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemGroupClass
		ax 	- MSG_SPEC_CHANGE

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 1/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLItemGroupChange	method dynamic	OLItemGroupClass, \
				MSG_SPEC_CHANGE


	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jnz	activatePopup			;all dynamic lists activate the
						;  popup.

;	mov	ax, MSG_GEN_COUNT_CHILDREN
;	call	ObjCallInstanceNoLock		;see how many items
;count only enabled children -- brianc 1/26/96
;only usable children -- brianc 2/21/96
	clr	bx, dx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx,offset CountUsableChildrenCB
	push	bx				;pass callback routine (off)
	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	cmp	dx, 2				;more than 2, branch
	pushf

	;
	; We're deciding whether to use the popup version of this
	; list, or the toggle version.  Make sure that we set the
	; delayed mode accordingly, before we let the popup pop-up
	;

	call	IC_DerefVisDI
	mov	ax, ds:[di].OLCI_rudyFlags

	;
	; Figure which Rudy delayed bit (GEN or VIS) to shift into the
	; OLBF_DELAYED_MODE position.
	;

	CheckHack <offset OLCRF_GEN_IS_DELAYED lt offset OLBF_DELAYED_MODE>
	CheckHack <offset OLCRF_GEN_IS_DELAYED - 1 eq offset OLCRF_VIS_IS_DELAYED>

	mov	cl, offset OLBF_DELAYED_MODE - offset OLCRF_GEN_IS_DELAYED
	popf
	pushf
	jna	setDelayed			; use GEN_DELAYED flag
	inc	cl				; use VIS_DELAYED flag
setDelayed:
	;
	; Now shift into OLBF_DELAYED_MODE, and set OLCI_buildFlags with it
	;
	shl	ax, cl
	andnf	ax, mask OLBF_DELAYED_MODE
	andnf	ds:[di].OLCI_buildFlags, not mask OLBF_DELAYED_MODE
	ornf	ds:[di].OLCI_buildFlags, ax

	popf					; restore child count test
	ja	activatePopup

	mov	cx, mask GSIF_FORWARD or mask GSIF_WRAP_AROUND
						; clears ch for FinishSetUser
	GOTO	FinishSetUser

activatePopup:
	mov	ax, MSG_GEN_ACTIVATE
callIt:
	GOTO	ObjCallInstanceNoLock

OLItemGroupChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountUsableChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bump count if usable child

CALLED BY:	OLItemGroupChange via ObjCompProcessChildren
PASS:		*ds:si = child
		*es:di = composite
		dx = current count
RETURN:		dx incremented if this is usable child
		carry clear to continue process children
		carry set to stop processing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		could stop if child count reaches three, as we only need
		to know if it is more than 2
		(let's go ahead and do this -- brianc 1/26/96)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountUsableChildrenCB	proc	far
	;
	; we'll just use Gen enabled flag
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	checkCount
	inc	dx				; enabled - bump count
checkCount:
	cmp	dx, 3				; carry set if count=0,1,2
	cmc					; carry clear if 0,1,2 -> cont.
						; carry set if dx > 2, stop
done:
	ret
CountUsableChildrenCB	endp

endif	; _RUDY



if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLIGSpecSetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hints on an ItemGroup according to the legos look
		requested, after removing the hints for its previous look.
		these hintes are stored in tables that each different SpecUI
		will change according to the legos looks they support.

CALLED BY:	MSG_SPEC_SET_LEGOS_LOOK
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
		cl	= legos look
RETURN:		carry	= set if the look was invalid (new look not set)
			= clear if the look was valid (new look set)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLIGSpecSetLegosLook	method dynamic OLItemGroupClass, 
					MSG_SPEC_SET_LEGOS_LOOK
	uses	ax, cx, dx, bp
	.enter
	;
	; inc cl by one as the legos users passes 0 for the first look.
	; we want 0 to be a spui, but non-component look
	; we dec the value when the user asks for it back.

	inc	cl

	clr	bx
	mov	bl, ds:[di].OLIGI_legosLook
	cmp	bx, LAST_LEGOS_CHOICE_LOOK
	jbe	validExistingLook

	clr	bx		; make the look valid if it wasn't
EC<	WARNING	WARNING_INVALID_LEGOS_LOOK		>

validExistingLook:
	clr	ch
	cmp	cx, LAST_LEGOS_CHOICE_LOOK
	ja	invalidNewLook

	mov	ds:[di].OLIGI_legosLook, cl
	;
	; remove hint from old look
	;
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosChoiceLookHintTable][bx]
	cmp	bx, 1
	jbe	noHintToRemove

	call	ObjVarDeleteData
	mov	ax, HINT_TOOLBOX
	call	ObjVarDeleteData	; all but look 0 use HINT_TOOLBOX

	;
	; add hints for new look
	;
noHintToRemove:
	mov	bx, cx
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosChoiceLookHintTable][bx]
	cmp	bx, 2			; it was shifted, so look 1 is 2
	jb	done			; no hints for look zero
	pushf				; does bx =1, radio button look
	clr	cx
	call	ObjVarAddData
	popf
	; 
	; if look 1, dont add HINT_TOOL_BOX
	je	done
	mov	ax, HINT_TOOLBOX
	clr	cx
	call	ObjVarAddData		; all but look 0 use HINT_TOOLBOX

done:
	.leave
	ret

invalidNewLook:
	stc
	jmp	done
OLIGSpecSetLegosLook	endm

	;
	; Make sure this table matches that in citemItemGroupClass.asm.
	; The only reason the table is in two places it is that I don't
	; want to be bringing in the ItemCommon resource at build time,
	; and it is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
legosChoiceLookHintTable	label word
	word	0
if _PCV
	word	HINT_ITEM_GROUP_PCV_RADIO_BUTTON_STYLE
	word	HINT_ITEM_GROUP_LOWER_LEFT_STYLE
	word	HINT_ITEM_GROUP_LOWER_RIGHT_STYLE
	word	HINT_ITEM_GROUP_UPPER_TAB_STYLE
	word	HINT_ITEM_GROUP_LOWER_TAB_STYLE
	word	HINT_ITEM_GROUP_BLANK_STYLE
endif
LAST_LEGOS_CHOICE_LOOK	equ ((($ - legosChoiceLookHintTable)/(size word)) - 1)
CheckHack<LAST_LEGOS_CHOICE_LOOK eq LAST_BUILD_LEGOS_CHOICE_LOOK>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLIGSpecGetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the legos look.

CALLED BY:	MSG_SPEC_GET_LEGOS_LOOK
PASS:		*ds:si	= OLItemGroupClass object
		ds:di	= OLItemGroupClass instance data
RETURN:		cl	= legos look
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLIGSpecGetLegosLook	method dynamic OLItemGroupClass,
					MSG_SPEC_GET_LEGOS_LOOK
	.enter
	mov	cl, ds:[di].OLIGI_legosLook
	;
	; we inc'd for fun in SET_LEGOS_LOOK.
	dec	cl
	.leave
	ret
OLIGSpecGetLegosLook	endm

endif		; if _HAS_LEGOS_LOOKS


ItemCommon ends

