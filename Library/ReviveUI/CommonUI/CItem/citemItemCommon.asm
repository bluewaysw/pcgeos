COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC 
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemItemCommon.asm

ROUTINES:
 Name			Description
 ----			-----------
    INT GenCallParentSaveRegs   Process current ptr & function state to
				determine whether a item should be up or
				down

    INT IC_GenCallParent        Process current ptr & function state to
				determine whether a item should be up or
				down

    INT SetupSelectionMsg       Sets up message to call to select or
				deselect item(s). Obviously based on the
				selection behavior of the item.

    INT OLItemTestIfInteractable 
				This procedure tests if the user can
				interact with this item object.

    INT OLItemTestIfParentHasGroupMouseGrab 
				This procedure ares the OLItemGroupClass
				object if one of its children received a
				START_SELECT event, meaning that it is OK
				for this item to handle PTR events.

    INT OLItemDoublePress       Notify the GenList that this entry has been
				double-clicked on.

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL 
				This method is sent by the OLItemGroupClass
				object when it loses the focus, and this
				item has the selection.

    MTD MSG_META_LOST_SYS_FOCUS_EXCL 
				This method is sent by the OLItemGroupClass
				object when it loses the focus, and this
				item has the selection.

    INT OLItemCheckIfAlwaysDrawsFocused 
				Checks to see if always draws as focused,
				by checking a hint on the parent item
				group.

    INT OLItemWash50Percent     If we're just being disabled, washes in a
				reverse pattern.

    INT GetCheckboxBounds       Returns the coordinates of the checkbox
				itself, since the VisBounds might include
				the moniker.

    MTD MSG_SPEC_CHANGE         Does a "change" on the gadget.

    INT ItemDrawPMCheck         Draw a simple check to represent radio
				buttons and check boxes in menus.

    INT ItemDrawJediDot         Draw a simple dot to represent radio
				buttons in menus.

    MTD MSG_OL_ITEM_NAVIGATE_IF_DISABLED 
				Sets some navigate flags.

    INT IVC_DerefGenDI          Sets some navigate flags.

    INT IVC_DerefVisDI          Sets some navigate flags.

    INT ;IVC_ObjCallInstanceNoLock 
				Sets some navigate flags.

    INT IVC_ObjMessageCall      Sets some navigate flags.

    INT IVC_ObjMessage          Sets some navigate flags.

    INT OLItemGetParentState    Get parent's state

    INT OLItemUpdateDrawState   This routine serves as an interface between
				the state flags of this OLItemClass object,
				and the drawing flags of its superclass,
				OLButtonClass.

    INT OLItemDrawIfNewState    Draw this button if its state has changed
				since the last draw.

    MTD MSG_OL_ITEM_SET_STATE   Sets item state.  Called by the list as
				part of updating the list's state.

    INT OLItemUpdateDrawStateAndDrawIfNotSuppressed 
				Updates draws state and draws if not
				suppressed. :)

    INT OLItemSetMasksIfDisabled 
				This routine sets the draw masks to n% if
				this object is not VA_FULLY_ENABLED.

    INT CheckIfJustDisabled     Sees if this item has just been disabled.

    INT OLItemSetupMkrArgs      Set up args for the moniker.

    INT UpdateItemState         This procedure copies this object's current
				draw flags OLBSS_DEPRESSED, etc) into the
				OLBI_optFlags byte, where they are archived
				so that we can later compare to see if a
				draw flag has changed.

    MTD MSG_OL_ITEM_REDRAW      Redraws an item.

    MTD MSG_GEN_ITEM_SET_INTERACTABLE_STATE 
				Marks an item as interactable or not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItem.asm

DESCRIPTION:
	$Id: citemItemCommon.asm,v 1.25 97/02/18 19:01:24 cthomas Exp $

------------------------------------------------------------------------------@
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemPtr - MSG_META_PTR for OLItemClass

DESCRIPTION:	This method is sent by the Flow Object when the user moves
		the mouse.

PASS:		*ds:si	- instance data
		cx, dx  - pointer location
		bp	- button information [ UIFunctionsActive | ButtonInfo ]

RETURN:		ax	- processing information

DESTROYED:	bx, di, si, es, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	3/90		Cleanup, mavigation work
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
OLItemPtr	method OLItemClass, MSG_META_PTR
	;test if is VA_FULLY_ENABLED, !OLIS_MONIKER_INVALID,
	;and !OLIS_DISPLAY_ONLY.

	clr	ax			;default: return MRF_NOT_PROCESSED,
					;do not upset mouse
	call	OLItemTestIfInteractable
	jnc	returnAX		;exit if not interactable

	;if the mouse button is not pressed, can ignore this event

OLS <	test	bp, (mask UIFA_SELECT or mask UIFA_FEATURES) shl 8	>
CUAS <	test	bp, (mask UIFA_SELECT) shl 8				>
	jz	returnProcessed			;skip if not...

isDragging:
	;if not in a menu, then we must be careful about whether or not to
	;handle this event. If the parent has not been notified that a child
	;was pressed on, we should ignore this event. 

	call	IC_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	handlePtrEvent		;skip if is in menu...

doTest:
	call	OLItemTestIfParentHasGroupMouseGrab
					;does not trash bp or bx
	jnc	returnProcessed		;skip if should not grab mouse...

handlePtrEvent:

	;Doing extended selection, don't do any check of outside bounds, etc.

	call	CheckIfExtendingOrNonExcl
	jz	draggingInBounds

	;We can (must) handle this pointer event. If not in bounds,
	;draw this item as NOT selected, may want to inform GenList to snap the
	;USER_EXCL back to the original owner, but DO NOT release the mouse,
	;because we don't want to interact with other controls.

	test	bp, (mask UIFA_IN) shl 8
	jnz	draggingInBounds	;skip if in bounds...

draggingOutOfBounds:
	;pointer has moved out of the bounds of this object. Release exclusives
	;and redraw item object (checks OLIS_PRESSING_ON_ITEM to see if
	;this work has already been done). Will also move focus back.

	mov	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER or \
		    mask OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER or \
		    mask OIENPF_REDRAW_PRESSED_ITEM
	call	OLItemEnsureIsNotPressed

	mov	ax, mask MRF_REPLAY	;ask the FlowObject to replay this
	ret				;PTR event, so that some other child
					;of this GenList can grab the mouse.

draggingInBounds:
	;pointer is dragging within object: handle as a START_SELECT event,
	;except do not tell parent that this child was PRESSED on.

	clr	ax			;pass flag: do not notify parent
	GOTO	OLItemMouse

returnProcessed:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
returnAX:
	ret
OLItemPtr	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemEnsureIsNotPressed --
				MSG_OL_ITEM_ENSURE_IS_NOT_PRESSED

DESCRIPTION:	This routine makes sure that this item object is
		properly NOT-PRESSED: has released exclusives, has set
		USER_EXCL flag correctly, etc.

CALLED BY:	OLItemPtr, OLItemRelease

PASS:		*ds:si	= instance data for object
		bp	= OLItemEnsureNotPressedFlags:

    OIENPF_MAINTAIN_INTERMEDIATE_MODE:1
		;set this to PREVENT exiting from intermediate mode.
		;This is useful in cases where an item is losing the FOCUS
		;exclusive, and must redraw, but we don't want to biff the
		;intermediate mode which was started by another item.

    OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER:1
		;set this to restore the OLIS_SELECTED state flag in the
		;item which had the selection before intermediate mode
		;began. This implied that the item will be redrawn also.

    OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER:1
		;set this to restore the FOCUS exclusive to the item which
		;had the exclusive before intermediate mode began.

    OIENPF_REDRAW_PRESSED_ITEM:1
		;set this to redraw the currently focused item. This is only
		;reset in cases where the exclusive is being forced
		;to the focused item via keybaord navigation or the
		;application sending the SELECT method. Since the SetExcl
		;handler routine will soon set the OLIS_SELECTED state flag
		;in this item and draw it, there is no need for us to redraw
		;the item after turning off the IS_PRESSED flag.

    OIENPF_SIMULATE_PRESS_AND_RELEASE:1
		;set this when calling this routine to handle SELECT key
		;space bar) presses on an item. Will quickly draw the item
		;as pressed, then unpressed, then will update the selected
		;state according to the type of list.

RETURN:		ds, si, cx, dx, bp = same
		carry set if PRESSING flag was already clear for this item;
			no work performed.

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
;DO NOT MAKE THIS A DYNAMIC METHOD HANDLER

OLItemEnsureIsNotPressed	method	OLItemClass, \
					MSG_OL_ITEM_ENSURE_IS_NOT_PRESSED
	call	IC_DerefVisDI

	call	CheckIfExtendingOrNonExcl
	je	5$			;extended selection, PRESSING_ON_ITEM
					;  never set but we need to release the
					;  mouse.
					;(This looks like it's causing problems
					;when scrolling and monikers are updated
					;in the same thread as the query, so
					;that a MSG_META_PTR never gets back
					;to an item.  We'll see if something 
					;still needs to release the grab when
					;the mouse is actually released.  
					;6/17/93 cbh)  (Commented back in
					;12/15/93 cbh to fix Redwood, as this
					;was never installed and causes problems
					;selecting items in geodex's merge
					;browse view.)
					
	test	ds:[di].OLII_state, mask OLIS_PRESSING_ON_ITEM
	stc
	jz	done			;skip if already know this...

5$:
	;
	; reset state flag and redraw object to show change.
	;
	andnf	ds:[di].OLII_state, not (mask OLIS_PRESSING_ON_ITEM)

	push	cx, dx, bp
	call	OLItemUpdateDrawState
	pop	cx, dx, bp

	push	bp
	test	bp, mask OIENPF_REDRAW_PRESSED_ITEM
	jz	10$			;skip if not...

	call	OLItemDrawIfNewState	;Redraw if any state flag changed
					;trashes bx, di; may move lmem chunks.

10$:
	;
	; It seems that in order to get drag-scrolling working properly, we
	; must not give up the mouse here when doing extended selection.
	; In other places, we do force-grabs to wrest the mouse away from this
	; object to make things work.  -cbh 6/17/93
	;
	push	bx, di
	push	si

if _JEDIMOTIF
	;
	; it seems OLIGMS_EXTENDING_SELECTION can be set of non-extendable
	; item groups like exclusives.  We'll just make a safe change here
	; and don't bother checking the bit if we aren't extendable
	; -- brianc 7/18/95
	;
	call	CheckIfExtendingOrNonExcl	; Z set if so
	jnz	11$				; can't be extending
endif

	call	GenSwapLockParent
	jnc	11$
	call	IC_DerefVisDI
	test	ds:[di].OLIGI_moreState, mask OLIGMS_EXTENDING_SELECTION
	call	ObjSwapUnlock
	jnz	12$			
11$:
	pop	si
	push	si
	call	VisReleaseMouse		;Release the mouse so other items
					;can grab it.
12$:
	pop	si
	pop	bx, di
	pop	bp

	;if this GenList is EXCLUSIVE, inform the GenList that we are no
	;longer in "intermediate" mode (will restore USER_EXCL flag on previous
	;owner, if not quickly notified by some other child that it has
	;grabbed the mouse)


	call	IC_DerefVisDI
	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
	je	done			;skip if non-exclusive (cy=0)...

	;see if we want to prevent exiting of intermediate mode (this is used
	;in the case where an item loses the FOCUS exclusive. We don't want
	;to fuck up the intermediate mode which was started by another item.)

	test	bp, mask OIENPF_MAINTAIN_INTERMEDIATE_MODE
	jnz	done

	;Motif, CUA/PM: exclusive items in menu can show SELECTION
	;emphasis independently of DEPRESSED(CURSORED) emphasis, so no need
	;for Intermediate mode. (IMPORTANT! will test for
	;OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER, and will only
	;cause redraws if is set. Will reset intermediate mode in any case.)
	;pass bp = OLItemEnsureNotPressedFlags.


	push	di, es							
	mov	di, segment OLScrollableItemClass			
	mov	es, di							
	mov	di, offset OLScrollableItemClass			
	call	ObjIsObjectInClass					
	pop	di, es							
	jc	endIntermediate		;don't care whether in menu	

CUAS <	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX		>
CUAS <	jnz	endIntermediate		;toolbox-style, doing intmdte	>
CUAS <	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU		>
CUAS <	jnz	done			;Skip if excl in menu (cy=0)...	>

endIntermediate:
	mov	ax, MSG_OL_IGROUP_END_INTERMEDIATE_MODE
	call	GenCallParent		;End the intermediate mode
					;does not trash bp
	clc

done:
	ret
OLItemEnsureIsNotPressed	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemStartSelect OLItemMouse

DESCRIPTION:	Process current ptr & function state to determine whether
		a item should be up or down

CALLED BY:	OLItemPtr (when is legal DRAG event inside the bounds)
		MSG_META_START_SELECT
				
PASS:		*ds:si 	- instance data
		es     	- segment of OLItemClass
		ax 	- method number (or 0 if called from some other proc.)
		cx, dx  - pointer location
		bp	- button information [ UIFunctionsActive | ButtonInfo ]

RETURN:
	ax - 0 if ptr not in item, MRF_PROCESSED if ptr is inside

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	3/90		cleanup, navigation work.
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLItemStartSelect	method OLItemClass, MSG_META_START_SELECT

if SHORT_LONG_TOUCH
	;
	; Start short/long touch in the parent item group.  Also save the
	; lptr of the item so we don't send out the short/long touch message
	; if the start and end select messages are received by different
	; items within this item group.
	;
	push	ax, cx, si
	mov	di, si			;*ds:di = OLItemClass object
	call	GenSwapLockParent
	call	StartShortLongTouch	;start short/long touch in parent
	jnc	unlock

	push	bx
	mov	ax, TEMP_OL_ITEM_GROUP_START_SELECT_ITEM
	mov	cx, size lptr
	call	ObjVarAddData
	mov	ds:[bx], di		;save lptr of start select item
	pop	bx
unlock:
	call	ObjSwapUnlock
	pop	ax, cx, si
endif

OLItemMouse	label	far
	;
	; test if is VA_FULLY_ENABLED, !OLIS_MONIKER_INVALID,
	; and !OLIS_DISPLAY_ONLY.
	;
	mov_tr	bx, ax			;bx = 0 or METHOD #
	clr	ax			;default: return MRF_NOT_PROCESSED

	call	OLItemTestIfInteractable
	;skip if not interactable...
if	 _CASCADING_MENUS
	LONG	jnc returnAX
else	;_CASCADING_MENUS is FALSE
	jnc	returnAX
endif	;_CASCADING_MENUS

	test	bp, mask BI_DOUBLE_PRESS
	jz	10$			;skip if not double-press...

if	_ODIE
	call	IC_DerefVisDI
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	jnz	10$			; no double-click if tab
endif
	call	OLItemDoublePress	;Process the double click
	;skip to end
if	 _CASCADING_MENUS
	jmp	returnProcessed
else	;_CASCADING_MENUS is FALSE
	jmp	short returnProcessed
endif	;_CASCADING_MENUS

10$:	
	tst	bx
	jz	20$			;skip if called from MSG_META_PTR

	call	OpenDoClickSound
	
	;
	; If this is an extended selection list, start it up.
	;
	call	CheckIfExtendingOrNonExcl
	jne	15$			;branch if not extending

	push	cx
	call	IC_DerefGenDI
	mov	cx, ds:[di].GII_identifier
	mov	ax, MSG_OL_IGROUP_START_EXTENDED_SELECTION
	call	GenCallParentSaveRegs
	pop	cx
	
	;
	; And, while we're add it, set the item's modified state correctly
	; based on the function that is happening.  (For better or worse, now
	; handled by new code in END_EXTENDED_SELECTION.  This was bad anyway,
	; as it causes an apply to go out on the press.  -cbh 12/ 1/92)
	;
;	push	cx, dx, bp
;	mov	al, GIGBT_EXCLUSIVE	;assume we're acting like an exclusive
;	test	bp, (mask UIFA_PREF_A) shl 8
;	jz	12$
;	mov	al, GIGBT_NON_EXCLUSIVE
;12$:
;	call	SetupSelectionMsg
;	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_AND_APPLY_IF_NEEDED	
;	call	IC_GenCallParent
;	pop	cx, dx, bp
15$:
	;If this is a START_*** event, inform parent that this GenList has	
	;the group mouse grab.

	mov	ax, MSG_OL_IGROUP_NOTIFY_GROUP_HAS_MOUSE_GRAB
	call	GenCallParentSaveRegs

20$:	;Grab the Gadget and FOCUS exclusives if necessary. (Will update
	;the OLButtonClass draw flags; focus changes will force redraws.)
	;Note that if is an exclusive-none list where no item is selected,
	;(meaning intermediate mode is not in use), this routine will also
	;move the USER exclusive to this item, so that if the user releases
	;the mouse button, he can then navigate from THIS item.

if BUBBLE_HELP and _ODIE
	;
	; display bubble help for tabs (on start-select, or ptr re-entry)
	;
	call	IC_DerefVisDI
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	jz	noTabHelp
	test	ds:[di].OLII_extraRecord, mask OLIER_HELP_UP
	jnz	noTabHelp
	call	OLButtonCreateBubbleHelp
	ornf	ds:[di].OLII_extraRecord, mask OLIER_HELP_UP
noTabHelp:
endif

	push	bx
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_WILL_GRAB_FOCUS_EXCL
	call	GenCallParentSaveRegs	;first have parent update its
	pop	bx			;"HAS_FOCUS_EXCL" flag according to
					;whether this window has the FOCUS,
					;so that we know whether to rely
					;upon focus changes for redraws.

	;
	; GenBooleans change their state on the press now.  But not if they're
	; in menus.  -cbh 2/16/93
	;
	tst	bx			;not original press, branch
	jz	25$			
	call	CheckIfBoolean		;not a boolean, branch
	jnc	25$
	call	IC_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	25$			;in menu, don't do anything.

	mov	al, ds:[di].OLII_behavior
	call	SetupSelectionMsg	;set up message to use
	jnc	25$
	call	IC_GenCallParent	;call it baby.
	call	OLItemDrawIfNewState	;and redraw if needed.
25$:
	;
	; Just extending from the old anchor point, do that now.
	;
	call	CheckIfExtendingOrNonExcl
	jne	ensurePressed		;branch if not extending 

	call	VisForceGrabMouse	;grab mouse now rather than later 
					;(This is now necessary since the 
					; EnsureNotPressed code no longer 
					; releases the mouse in extended mode.
					; 6/17/93 cbh)
					
	mov	bp, bx			;if bx=0, message is from MSG_META_PTR,
					; not our first time through, set
					; bp as such.
	mov	ax, MSG_OL_IGROUP_EXTEND_SELECTION
	call	GenCallParentSaveRegs
	jmp	short returnProcessed

ensurePressed:
if	 _CASCADING_MENUS
	; if this item is in a menu and is in the process of being "pressed"
	; (i.e., it is not yet depressed and/or bordered, but it is going to
	; be since it is calling OLItemEnsureIsPressed next) then send a message
	; to the menu window indicating that this item (since it is just a
	; item) will not cause the menu to cascade.
	
	call	IC_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	dontSendMessage
	
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED or \
					mask OLBSS_DEPRESSED
	jnz	dontSendMessage
	; Flags passed in cl: Not cascading, don't start grab.
	clr	cx
	call	OLButtonSendCascadeModeToMenuFar
	
dontSendMessage:
endif	;_CASCADING_MENUS

	call	OLItemEnsureIsPressed
30$:
	;Now grab the mouse events & specify you only want enter/leave

	call	VisGrabMouse		; Grab the mouse

returnProcessed:	
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
					;Say processed if ptr in bounds
returnAX:
	ret
OLItemStartSelect	endp


GenCallParentSaveRegs	proc	near
	push	cx, dx, bp
	call	IC_GenCallParent
	pop	cx, dx, bp
	ret
GenCallParentSaveRegs	endp

IC_GenCallParent	proc	near
	call	GenCallParent
	ret
IC_GenCallParent	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemEnsureIsPressed -- MSG_OL_ITEM_ENSURE_IS_PRESSED

DESCRIPTION:	This procedure is called by OLButtonMouse when the user
		is pressing the mouse button over this item object.

CALLED BY:	OLItemMouse

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

;DO NOT MAKE THIS A DYNAMIC METHOD HANDLER.

OLItemEnsureIsPressed	method	OLItemClass,
					MSG_OL_ITEM_ENSURE_IS_PRESSED

	;indicate that user is interacting with this item
	;(DO NOT test this flag, to see if this work is necessary, because
	;will introduce a bug: navigate to an exclusive-none item in menu,
	;the press on it. Since OLIS_PRESSING_ON_ITEM is already TRUE,
	;the mouse press will not cause the GADGET exclusive or mouse grabs
	;to be taken, so we never get the release event!

	call	IC_DerefVisDI
	ornf	ds:[di].OLII_state, mask OLIS_PRESSING_ON_ITEM

	;update the OLButtonClass drawing flags (OLBSS_SELECTED,
	;OLBSS_DEPRESSED) because we will soon be dealing with the focus
	;exclusive, which will force changes to OLBSS_CURSORED, and redraw
	;this object.

	call	OLItemUpdateDrawState

	;First, take gadget exclusive for UI window
	;(carry = clear if a double click was processed)

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent

	;
	;If this is an exclusive list: see if should enter intermediate mode.
	;Motif and CUA/PM: exclusive items in menu can show
	;SELECTED emphasis independently of DEPRESSED emphasis, so no need
	;for Intermediate mode. This item will be drawn as DEPRESSED (CUA/PM)
	;or BORDERED (Motif) for now. If the user releases on it, the GenList
	;will be told to move the USER_EXCL.
	;
	;Notify the list that it can now operate in intermediate mode,
	;if not already. This will not affect the GenList's USER_EXCL OD value,
	;but will temporarily de-select the item which USER_EXCL points to.
	;This new item will draw as "on" only because it is DEPRESSED,
	;as will any other item the pointer moves on top of. The exclusive
	;will be set again upon leaving the list or upon releasing the mouse
	;button. If this new item is the USER_EXCL item, then the
	;GenList will decide NOT to enter intermediate mode. Also, if this
	;is an exclusive-none list and all items are off, the GenList will
	;not enter intermediate mode.

	
	call	IC_DerefGenDI
	mov	cx, ds:[di].GII_identifier
	mov	ax, MSG_OL_IGROUP_START_INTERMEDIATE_MODE
	call	IC_GenCallParent	;returns carry set if parent or kids
					;do not have the focus exclusive,
					;(MAY NOT be allowed to grab the focus)
					;and so we must redraw this item

afterIntMode:

if _KBD_NAVIGATION	;------------------------------------------------------
	;grab the FOCUS exclusive for this item. Will redraw object
	;with the cursor. (Do this AFTER starting intermediate mode, because
	;parent will update the PRESSING state on this item and the SELECTED
	;state on the other item, and then we reach this code, which forces
	;a redraw of both objects. As always, there are exceptions:
	;if this list is inside a menu, the parent will see that it or its
	;children do not have the FOCUS exclusive, and will make sure that the
	;items are redrawn).

	jc	redraw			;skip if focus will NOT move, so must
					;redraw now...

	;
	; If we're in a toolbox, we'll go straight to redrawing now.  Toolbox
	; objects can't have the focus anyway.
	;
	call	IC_DerefVisDI
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	redraw

	;
	; Extended-selection lists put the focus on the extent item while
	; extending the selection.  Let's not do that here.
	;
	call	CheckIfExtendingOrNonExcl
	je	redraw			;branch if extending


	;remember: parent has already called OpenTestIfFocusOnTextEditObject,
	;so just go ahead and grab the focus. BUT: if we ALREADY have the
	;focus, we know that we will not get a GAINED notification, so
	;go ahead and redraw!

	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	pushf
	call	MetaGrabFocusExclLow	;see OLItemGainedSystemFocusExcl
	popf
	jz	done			;skip if did not have focus...
					;(We are trusting that we will gain the
					;focus. I had error checking here once
					;to make sure of this, but it failed in
					;the case where the focus was temp-
					;orarily on a menu, and there the 
					;GenList said "don't worry: you got it",
					;but this entry would not gain focus
					;until the menu dropped. EDS 7/3/90.
endif 			;------------------------------------------------------

redraw:
	call	OLItemDrawIfNewState	;Redraw if any state flag changed

done:
	ret
OLItemEnsureIsPressed	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemRelease

DESCRIPTION:	This method is sent by the Flow Object when the user moves
		the mouse.

PASS:		*ds:si	- instance data
		cx, dx  - pointer location
		bp	- button information [ UIFunctionsActive | ButtonInfo ]

RETURN:		ax	- processing information

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	3/90		Cleanup, navigation work.
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemRelease	method OLItemClass, MSG_META_END_SELECT

	;Check if this release should be processed (both buttons must be
	;released)

	test	bp, (mask UIFA_SELECT) shl 8
	jnz	returnNotProcessed	;skip if a button is still pressed...

	;test if is VA_FULLY_ENABLED, !OLIS_MONIKER_INVALID,
	;and !OLIS_DISPLAY_ONLY.

;
; 	This causes problems with extended selection releases outside the view 
;	bounds, where the thing isn't totally interactable at the moment of 
; 	the release.   I hope this doesn't screw up anything else, but it seems
; 	benign to allow releases and stuff on a non-interactable item.  
;	Substituted the non-moniker-invalid parts of the test.  6/15/93 cbh
;
;	call	OLItemTestIfInteractable
;	jnc	returnNotProcessed	;skip if not interactable...
;
	call	VisCheckIfFullyEnabled
	jnc	returnNotProcessed		;skip if not enabled...

	call	IC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	returnNotProcessed

	;
	; If doing extended selection, treat all releases as being in bounds.
	; -cbh 1/25/93
	;
	call	CheckIfExtendingOrNonExcl
	je	releaseInBounds			

	test	bp, (mask UIFA_IN) shl 8
	jnz	releaseInBounds

releaseOutOfBounds:
	;In case the user is spazzing out and we have not yet received a
	;PTR event informing us that the mouse pointer was dragged out of
	;the item, let's make sure that the OLIS_PRESSING_ON_ITEM flag
	;is reset. If still set, reset some state flags and redraw the item.

	mov	cx, bp			;pass mouse flags in cx
	mov	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER or \
		    mask OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER or \
		    mask OIENPF_REDRAW_PRESSED_ITEM
	call	OLItemEnsureIsNotPressed

returnNotProcessed:
	clr	ax			;return MRF_NOT_PROCESSED
	ret

releaseInBounds:
	;All appropriate buttons are released & pointer inside:
	;toggle/reset the USER exclusive, inform the parent of Double-click
	;related events. Then redraw this object to reflect the changes.

	push	cx, dx, bp		;save mouse info in case must return

	mov	cx, bp			;pass mouse flags in cx
	clr	bp			;pass flags: minimal exit of Int. mode,
					;because will change USER state and
					;redraw (we know this is the focused
					;item.)
	call	OLItemEnsureIsReleased

	;
	; Since an item was selected, we need to close the popup.
	;
	pushf								
	push	si							
	call	GenSwapLockParent

if SHORT_LONG_TOUCH
	;
	; Check to make sure that we are the same item that got the initial
	; start select.  If we are, then send out the short/long touch message.
	; Otherwise, just ignore this end select.
	;
	pop	di			;*ds:di = OLItemClass object
	push	di

	push	bx
	mov	ax, TEMP_OL_ITEM_GROUP_START_SELECT_ITEM
	call	ObjVarFindData
	jnc	endTouch

	mov	ax, ds:[bx]		;di = lptr of start select item
	call	ObjVarDeleteDataAt

	cmp	di, ax			;end select item ?= start select item
	jne	endTouch

	call	EndShortLongTouch	;end short/long touch
endTouch:
	pop	bx
endif

	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset					
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST		
	call	ObjSwapUnlock						
	pop	si							
	jz	after							

	;
	; Call OLWin to close the popup.
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND			
	mov	cx, IC_INTERACTION_COMPLETE				
	call	CallOLWin						
after:								
	popf								

	pop	cx, dx, bp
	jc	returnProcessed		;skip if was already released...

	call	VisReleaseMouse		;Release the mouse

	;
	; Turn off extended selection, if we're running it..
	;
	call	CheckIfExtendingOrNonExcl
	jne	returnProcessed

	mov	ax, MSG_OL_IGROUP_END_EXTENDED_SELECTION
	call	IC_GenCallParent
	
returnProcessed:
	mov	ax, mask MRF_PROCESSED	;Say processed if ptr in bounds
	ret
OLItemRelease	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemEnsureIsReleased --
					MSG_OL_ITEM_ENSURE_IS_RELEASED

DESCRIPTION:	This procedure is used by OLItemRelease. The user has
		just finished interacting with a item by releasing the
		mouse button on the item. We have to decide if the
		item is now considered "ON" or "OFF", and inform the
		parent

PASS:		*ds:si	= instance data for object
		bp	= OLItemEnsureNotPressedFlags:
		cx	- button information [ UIFunctionsActive | ButtonInfo ]

    OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER:1
                ;set this to restore the OLIS_SELECTED state flag in the
                ;item which had the USER exclusive before intermediate mode
                ;began. This implied that the item will be redrawn also.

    OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER:1
                ;set this to restore the FOCUS exclusive to the item which
                ;had the selection before intermediate mode began.

    OIENPF_REDRAW_PRESSED_ITEM:1
                ;set this to redraw the currently focused item. This is only
                ;reset in cases where the exclusive is being forced
                ;to the focused item via keybaord navigation or the
                ;application sending the SELECT method. Since the SetExcl
                ;handler routine will soon set the OLIS_SELECTED state flag
                ;in this item and draw it, there is no need for us to redraw
                ;the item after turning off the IS_PRESSED flag.

    OIENPF_SIMULATE_PRESS_AND_RELEASE:1
		;set this when calling this routine to handle SELECT key
		;space bar) presses on an item. Will quickly draw the item
		;as pressed, then unpressed, then will update the selected
		;state according to the type of list.

RETURN:		ds, si = same
		carry set if PRESSING flag was already clear for this item;

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemEnsureIsReleased	method	OLItemClass, \
					MSG_OL_ITEM_ENSURE_IS_RELEASED
	class	OLItemClass

	;see if we want to simulate a press and release
	;(THIS CODE could be in a separate method handler, which the parent
	;would invoke directly, and that method handler would call
	;OLItemEnsureIsPressed and then OLItemEnsureIsReleased in order.)

	push	cx			;save button flags
	test	bp, mask OIENPF_SIMULATE_PRESS_AND_RELEASE
	jz	10$

	push	bp
	call	OLItemEnsureIsPressed
	pop	bp
					;redraw item as PRESSED, temporarily
					;(may attempt to grab focus again,
					;but will be ok)

10$:	;First, let's make sure that the OLIS_PRESSING_ON_ITEM flag
	;is reset. If still set, abort intermediate mode, cleaning up
	;as specified by bp.

	call	OLItemEnsureIsNotPressed
	mov	cx, bp			;OLItemEnsureNotPressedFlags
	pop	bp			;restore button flags
	LONG	jc	done		;skip if already handled (cy=1)...


	call	IC_DerefVisDI		;get behavior to use
	mov	al, ds:[di].OLII_behavior

	;
	; Now, do an action here if:
	;	We're not a GenBoolean, or
	;	We're simulating a press and release, or
	;	We're in a menu.
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	30$			;in menu, do an action
	test	cx, mask OIENPF_SIMULATE_PRESS_AND_RELEASE
	jnz	20$			;press simulated, don't skip selection
	call	CheckIfBoolean		;GenBoolean, branch, handled on press
	jc	releaseCommon		;(2/16/93 cbh)
	jmp	short 30$		;not GenBoolean, go handle selection
20$:
	;
	; Simulating press and release, set special flag for non-exclusives to
	; guarantee their toggling.
	;
	cmp	al, GIGBT_NON_EXCLUSIVE
	jne	30$
	inc	al			;make SSMBT_NON_EXCLUSIVE_ALWAYS_TOGGLE

				CheckHack <(SSMBT_NON_EXCLUSIVE_ALWAYS_TOGGLE \
				eq (GIGBT_NON_EXCLUSIVE + 1))>
30$:
	call	SetupSelectionMsg	;set up message to use
	jnc	releaseCommon
	call	IC_GenCallParent	;call it baby.

redrawExcl:
	;now, in case this item had the selection, and we are selecting
	;it again, let's make sure that the item is redrawn.

	call	OLItemDrawIfNewState	;Redraw if any state flag changed
					;trashes bx, di; may move lmem chunks.

releaseCommon:
	clc				;return flag: work was done

done:	;return carry set if no work done
	ret
OLItemEnsureIsReleased	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupSelectionMsg

SYNOPSIS:	Sets up message to call to select or deselect item(s).
		Obviously based on the selection behavior of the item.

CALLED BY:	OLItemEnsureIsReleased

PASS:		*ds:si -- item
		al -- behavior to apply

RETURN:		ax -- message to call
		dl -- OLItemUpdateFlags
		cx, dh -- arguments to message
		carry set if anything should happen

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/92		Initial version

------------------------------------------------------------------------------@

; Special flag for non-exclusives that should always toggle coming into
; this routine.  Usually non-exclusives are treated like extended selection
; and nothing is done in this routine, as selection is handled elsewhere.
;
SSMBT_NON_EXCLUSIVE_ALWAYS_TOGGLE	=	GIGBT_NON_EXCLUSIVE + 1


SetupSelectionMsg	proc	near
	call	IC_DerefGenDI
	mov	cx, ds:[di].GII_identifier  ;assume will pass ID of this item

	;
	; Before going on, get selected/indeterminate state to keep in ah.
	;
	push	ax
	push	cx
	mov	ax, MSG_OL_IGROUP_GET_ITEM_STATE
	call	GenCallParent		;item state in al
	pop	cx
	mov	ah, al			;now in ah
	pop	dx
	mov	al, dl			;passed behavior in al

	mov	dh, 1			;assume selecting one item

	cmp	al, GIGBT_EXCLUSIVE
	je	exclReleaseCommon	;exclusive, branch to select item

	;
	; Hack added to treat as a non-exclusive press, regardless of whether
	; we do extended selection, if SSMBT_NON_EXCLUSIVE_ALWAYS_TOGGLE.
	;
	cmp	al, SSMBT_NON_EXCLUSIVE_ALWAYS_TOGGLE
	je	nonExclRelease

	call	CheckIfExtendingOrNonExcl
	clc				;assume exiting
	je	exit			;extended selection, do nothing
	cmp	al, GIGBT_EXCLUSIVE_NONE
	je	exclNoneRelease		;exclusive-none, go toggle item

nonExclRelease:
	;non-exclusive list: toggle this item

	clr	dh			;assume we're deselecting
	test	ah, mask OLIS_INDETERMINATE
	jnz	nonExclSelect		;for now, always select if indeterminate
	test	ah, mask OLIS_SELECTED
	jnz	nonExclDeselect		;deselect if currently on

nonExclSelect:
	dec	dh			;else select

nonExclDeselect:	
	clr	dl			;for now, assume no special flags
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_ITEM_STATE
	stc				;signal that something should happen
	jmp	short exit		;skip to end


exclNoneRelease:
	;is an exclusive-none list: if the USER_EXCL is currently set,
	;we want to toggle OFF by reitem parent's USER exclusive to nil,
	;and by reitem our USER exclusive flag.

	test	ah, mask OLIS_SELECTED
	jz	exclReleaseCommon	;skip if is off, to select ourself
	mov	dh, 0			;no selection
	jmp	short selectNoFlags	;skip to deselect

exclReleaseCommon:
	;inform the parent that this item has the selection now, if it's 
	;actually changing, or if we have MSG_GEN_ITEM_GROUP_SET_MODIFIED_ON-
	;REDUNDANT_SELECTION set.

	test	ah, mask OLIS_INDETERMINATE
	jnz	selectNoFlags		;indeterminate, definitely select
	;
	; Lock down our generic parent -- we may not be visibly built
	; yet, and hence not have a visible parent yet so doing a
	; VisSwapLockParent() is a bad thing.
	;
	push	si
	call	GenSwapLockParent	;lock down parent
	push	bx

;	cmp	al, GIGBT_EXCLUSIVE_NONE
;	stc				
;	je	unlockParent		;exclusive-none, never redundant
;					; (cbh 10/27/92)  (Removed 12/ 1/92 cbh
;					;  as we need to check for dragging off
;					;  then on case!  A fix made in 
;					;  redundant checking that should fix
;					;  the old problems.

	push	bp, cx, dx
	clr	bp			;item passed in cx
	mov	ax, MSG_OL_IGROUP_TEST_FOR_REDUNDANT_INTERMEDIATE_SELECTION
	call	ObjCallInstanceNoLock
	pop	bp, cx, dx
	cmc				;set not-carry if redundant...
	jc	unlockParent		;selection not redundant, branch

	mov	ax, ATTR_GEN_ITEM_GROUP_SET_MODIFIED_ON_REDUNDANT_SELECTION
	call	ObjVarFindData		;carry set if found

unlockParent:
	;
	; Carry is set here is we can set modified.
	;
	pop	bx
	call	ObjSwapUnlock
	pop	si
	jc	selectNoFlags		;carry set, set modified
	mov	dl, mask OLIUF_TEMPORARY_CHANGE
	jmp	short select		;this avoids modification

selectNoFlags:
	clr	dl			;for now, assume no special flags

select:
	mov	ax, MSG_OL_IGROUP_SET_MODIFIED_SELECTION
	stc				;something should happen
exit:
	ret
SetupSelectionMsg	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemTestIfInteractable

DESCRIPTION:	This procedure tests if the user can interact with this
		item object.

CALLED BY:	OLItemPtr, OLItemMouse, OLItemRelease

PASS:		*ds:si	= instance data for object

RETURN:		ax, bx, cx, dx, bp = same
		carry set if can interact with object

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

;SAVE BYTES here...

OLItemTestIfInteractable	proc	near
	call	VisCheckIfFullyEnabled
	jnc	done			;skip if not enabled...

	;In a dynamic list, all the visible entries are allocated.  However,
	;some may not have monikers, or they're not quite up-to-date.  Don't 
	;allow them to be selected. 

	call	IC_DerefVisDI
	test	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
	jnz	done			;skip if no moniker
					;  (cy=0)...
	call	IC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	done
	stc

done:
	ret
OLItemTestIfInteractable	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemTestIfParentHasGroupMouseGrab

DESCRIPTION:	This procedure ares the OLItemGroupClass object if one
		of its children received a START_SELECT event, meaning that
		it is OK for this item to handle PTR events.

CALLED BY:	OLItemPtr

PASS:		*ds:si	= instance data for object

RETURN:		cx, dx, bp = same
		carry set if parent has mouse grab

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemTestIfParentHasGroupMouseGrab	proc	near
	push	cx, dx, bp
	call	OLItemGetParentState
	test	cl, mask OLIGS_GROUP_HAS_MOUSE_GRAB
	jz	10$			;skip if not (cy=0)...
	stc
10$:
	pop	cx, dx, bp
	ret
OLItemTestIfParentHasGroupMouseGrab	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemDoublePress

DESCRIPTION:	Notify the GenList that this entry has been double-clicked on.

CALLED BY:	OLItemMouse

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
OLItemDoublePress	proc	far
	;
	; notify parent
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_OL_IGROUP_NOTIFY_DOUBLE_PRESS
	call	IC_GenCallParent

	ret
OLItemDoublePress	endp

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGainedSystemFocusExcl
FUNCTION:	OLItemLostSystemFocusExcl

DESCRIPTION:	This method is sent by the OLItemGroupClass object when
		it loses the focus, and this item has the selection.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _CUA_STYLE	;--------------------------------------------------------------

OLItemGainedSystemFocusExcl	method	dynamic OLItemClass, \
					MSG_META_GAINED_SYS_FOCUS_EXCL

if _RUDY
	ORNF	ds:[di].OLBI_specState, mask OLBSS_CURSORED or \
					mask OLBSS_DEPRESSED
else
if ALLOW_TAB_ITEMS and _DUI
	;
	; Tab items should not have the dotted outline cursor for
	; Dove.
	;
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	jnz	noCursor
endif
	ORNF	ds:[di].OLBI_specState, mask OLBSS_CURSORED
if ALLOW_TAB_ITEMS
noCursor:
endif
endif

;NEW
	call	OLItemUpdateDrawState ;update OLBI_specState flags

	call	OLItemDrawIfNewState	;Redraw if any state flag changed

	;inform parent that this item now has the FOCUS excl

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_GAINED_FOCUS_EXCL
	call	IC_GenCallParent

	ret
OLItemGainedSystemFocusExcl	endm





OLItemLostSystemFocusExcl	method	dynamic OLItemClass, \
					MSG_META_LOST_SYS_FOCUS_EXCL

if BUBBLE_HELP and _ODIE
	;
	; stop bubble help on LOST_SYS_FOCUS_EXCL
	;
	call	IC_DerefVisDI
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	jz	notTab

	call	OLButtonDestroyBubbleHelp
	andnf	ds:[di].OLII_extraRecord, not mask OLIER_HELP_UP
notTab:
endif

	;IMPORTANT: ignore the "gainer OD" information which is passed,
	;because we don't want to ignore this method. In all cases
	;(i.e.) regardless of whether focus is grabbed by another object),
	;we want to reset our state, redraw, AND release the mouse grab.

if _RUDY
if 0	; No longer do this in Lizzy, 'cause we manually send gain/lost
	; focus messages to items to get the CURSORED flag set correctly

	call	OLItemCheckIfAlwaysDrawsFocused
	jc	drawStateOK
	call	IC_DerefVisDI
endif
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_CURSORED or \
					     mask OLBSS_DEPRESSED)

drawStateOK:
	call	IC_DerefVisDI
else
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_CURSORED)
					;set not cursored
endif

	ORNF	ds:[di].OLII_state, mask OLIS_PRESSING_ON_ITEM
					;hack so that this routine WIL
					;update the state, redraw this object,
					;and release the mouse grab, BUT WILL
					;NOT affect intermediate mode!

	;
	; In Redwood (actually on any keyboard-only system), the mnemonic 
	; interferes with the outline.   Let's make sure the item is completely
	; redrawn when erased.  (Changed for all systems 6/20/94 cbh)
	;
	call	OpenCheckIfKeyboardOnly
	jnc	10$
	ANDNF	ds:[di].OLBI_optFlags, not mask OLBOF_DRAW_STATE_KNOWN
10$:

	mov	bp, mask OIENPF_REDRAW_PRESSED_ITEM or \
		    mask OIENPF_MAINTAIN_INTERMEDIATE_MODE
	call	OLItemEnsureIsNotPressed

	;inform parent that this item has lost the FOCUS excl (if
	;no other child has the FOCUS, then parent will reset its state
	;flag, indicating that no item in group has the focus)

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_LOST_FOCUS_EXCL
	call	IC_GenCallParent

done:
	ret
OLItemLostSystemFocusExcl	endm

endif		;--------------------------------------------------------------





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemCheckIfAlwaysDrawsFocused
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if always draws as focused, by checking
		a hint on the parent item group.

CALLED BY:	OLItemGainedSystemFocusExcl, OLItemLostSystemFocusExcl

PASS:		*ds:si -- item

RETURN:		carry set if always showing.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/10/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLItemCheckIfAlwaysDrawsFocused	proc	far	uses	si, ax, bx
	.enter

	call	GenSwapLockParent
EC <	ERROR_NC 	OL_ERROR		;shouldn't happen	>

	push	bx
	mov	ax, HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS
	call	ObjVarFindData
	pop	bx
	call	ObjSwapUnlock
	.leave
	ret
OLItemCheckIfAlwaysDrawsFocused	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemLostGadgetExclusive -- MSG_VIS_LOST_GADGET_EXCL handler

DESCRIPTION:	This method is received when some other object has grabbed
		the GADGET exclusive for this level in the visual tree.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemClass
		ax 	- method number

RETURN:		Nothing

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	6/89		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemLostGadgetExcl	method OLItemClass, MSG_VIS_LOST_GADGET_EXCL

if BUBBLE_HELP and _ODIE
	;
	; stop bubble help on LOST_GADGET_EXCL
	;
	call	IC_DerefVisDI
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	jz	notTab

	call	OLButtonDestroyBubbleHelp
	andnf	ds:[di].OLII_extraRecord, not mask OLIER_HELP_UP
notTab:
endif

	;DO NOT CALL SUPERCLASS! OLItemClass and OLCheckboxClass each have
	;their own handler for this method, so improving this one will not
	;help the other.

	mov	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER or \
		    mask OIENPF_REDRAW_PRESSED_ITEM
	call	OLItemEnsureIsNotPressed
	ret
OLItemLostGadgetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemBubbleTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bubble help time out, close bubble help

CALLED BY:	MSG_OL_BUTTON_BUBBLE_TIME_OUT
PASS:		*ds:si	= OLItemClass object
		ds:di	= OLItemClass instance data
		ds:bx	= OLItemClass object (same as *ds:si)
		es 	= segment of OLItemClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_HELP and _ODIE

OLItemBubbleTimeOut	method dynamic OLItemClass, 
					MSG_OL_BUTTON_BUBBLE_TIME_OUT
	;
	; let OLButtonClass handle
	;
	mov	di, offset OLItemClass
	call	ObjCallSuperNoLock
	;
	; clear our local flag
	;
	call	IC_DerefVisDI
	andnf	ds:[di].OLII_extraRecord, not mask OLIER_HELP_UP
	ret
OLItemBubbleTimeOut	endm

endif

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemKbdChar -- MSG_META_KBD_CHAR handler

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

RETURN:		ax, cx, dx, bp

DESTROYED:	bx, si, ds, es, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version (from John's VisKbdText)
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemKbdChar	method	OLItemClass, \
					MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR

	;this GenListEntry does not care about this keyboard event.
	;As a leaf object in the FOCUS exclusive hierarchy, we must now
	;initiate a FOCUS-UPWARD query to see a parent object (directly)
	;or a parent's descendants (indirectly) cares about this event.
	;	cx, dx, bp = data from MSG_META_KBD_CHAR

	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
OLItemKbdChar	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemNavigate - MSG_SPEC_NAVIGATION_QUERY handler for
			OLItemClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLItemClass handler:
	    This object is not really a part of the navigation circuit; the
	    GenList is. But this child gets the navigation query, because
	    this child has the focus. Send this method up to the parent,
	    so it can decide what to do.

	WARNING:
	 This handler is important!
	 If one were to allow the GenItem to initiate the query,
	 you run the risk of the query coming all the way around
	 to the list again, finding no items to navigate to (because
	 they've all been removed from a DynamicList), continuing
	 around the loop again, forever, or until EC code flags it down.

	 On Rudy, since TAB doesn't have any navigation functionality,
	 this means that you can't navigate out of a list, but that's
	 OK, since there shouldn't be anything else to navigate to
	 anyway.  -ChrisT 12/1/95

	If you really want Items to be part of the navigation circuit,
	you should do something at the OLItemGroup level to make sure
	it knows that the query started from a possibly missing child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemNavigate	method	OLItemClass, MSG_SPEC_NAVIGATE
			
if _RUDY
	;
	; In Responder, GenBooleanGroup's _can_ be mixed with
	; other navigable gadgets on the screen.  Don't let the
	; parent handle navigation for us, cause it will do the wrong
	; thing: and navigate completely out of the entire group.
	;
	push	es
	call	CheckIfBoolean			; destroys es
	pop	es
	jnc	sendToParent
	mov	di, offset @CurClass
	GOTO	ObjCallSuperNoLock

sendToParent:
endif ; _RUDY

	;pass this method up to our parent: it will act as if the method had
	;come from the window also (NF_INITIATE_QUERY set will ensure this)

	call	GenFindParent
	call	IC_ObjMessageCall
	ret
	
OLItemNavigate	endm

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemWash50Percent

SYNOPSIS:	If we're just being disabled, washes in a reverse pattern.

CALLED BY:	ItemDrawColorItem, ItemDrawBWItem

PASS:		*ds:si -- item
		cl -- OLButtonOptFlags
		ch - zero if B/W, nonzero if color

RETURN:		carry set if just disabled

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/15/92		Initial version

------------------------------------------------------------------------------@

if (not _ASSUME_BW_ONLY) or _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50

OLItemWash50Percent	proc	far
	call	CheckIfJustDisabled
	jnc	done			

	;This item has just been disabled: wash the icon area in the
	;passed mask; wash the text area in a 50% mask.

	call	GrSetAreaMask

	tst	ch
	jnz	drawCheckbox
	;
	; In B/W, if it's an exclusive item (with a diamond), then
	; don't wash out the diamond with a 50% mask, as this will erase
	; it some of the time. 
	;

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset 
	mov	al, ds:[di].OLII_state
	pop	di
	;
	; If non-exclusive, or a toolbox item, then it's OK
	;
	test	al, mask OLIS_IS_CHECKBOX or mask OLIS_DRAW_AS_TOOLBOX
	jnz	drawCheckbox


	test	al, mask OLIS_SELECTED
	jz	dontWash

	;
	; If it's indeterminate, then it's also unsafe
	; wash out the diamond.
	;
	test	al, mask OLIS_INDETERMINATE
	jz	drawCheckbox


dontWash:
	;
	; Don't wash the diamond.  Set up parameters to just
	; wash out the text portion	
	;
	call	VisGetBounds
	push	cx
	mov_tr	cx, ax
	add	cx, CHECK_BOX_WIDTH
	jmp	drawText

drawCheckbox:
	call	VisGetBounds
	push	cx			;save right edge
	mov	cx, ax
	add	cx, CHECK_BOX_WIDTH	;right edge = right edge of icon
	call	GrFillRect

drawText:	
	mov	ax, SDM_50 or mask SDM_INVERSE
	call	GrSetAreaMask
	mov_tr	ax, cx			;right edge becomes left edge
	pop	cx			;restore overall right edge
	call	GrFillRect
	stc
done:
	ret
OLItemWash50Percent	endp

endif ; (not _ASSUME_BW_ONLY) or _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50



ItemCommon ends
ItemCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCheckboxBounds

SYNOPSIS:	Returns the coordinates of the checkbox itself, since the
		VisBounds might include the moniker.

PASS:		*ds:si	- instance data

RETURN:		ax, bx, cx, dx	- rectangular bounds of the checkbox

DESTROYED:	nothing

	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCheckboxBounds	proc	far
	call	OpenGetLineBounds		; Get entire bounds

OLS <	sub	cx, CHECK_RIGHT_BORDER + CHECK_REAL_RIGHT_BORDER
OLS <	mov	ax, cx				;    edges		>
OLS <	sub	ax, CHECK_BOX_WIDTH-1		;			>

MO <	add	ax, CHECK_LEFT_BORDER					>
PMAN <	add	ax, CHECK_LEFT_BORDER					>
CUAS <	mov	cx, ax				;    edges		>
CUAS <	add	cx, CHECK_WIDTH_REAL-1					>
     						; get top edge by
	sub	dx, bx				; subtracting top from bottom
OLS <	sub	dx, CHECK_HEIGHT-1		; and subtracting button height>
CUAS <	sub	dx, CHECK_HEIGHT-2		; (center box portion)         >
	shr	dx, 1				; and dividing by 2
OLS <	inc	dx				; add one to match dubious     >
						;   moniker "centering"
	add	bx, dx				; add to top edge
	mov	dx, bx				; calculate bottom
	add	dx, CHECK_HEIGHT-1					

	ret
GetCheckboxBounds	endp

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemActivate -- 
		MSG_GEN_ACTIVATE for OLItemClass

DESCRIPTION:	Activates the item.  Basically simulates a press and
		release.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ACTIVATE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 4/90		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemActivate	method OLItemClass, MSG_GEN_ACTIVATE
	;simulate a press and release, do not redraw item if aborting
	;intermediate mode.

	mov	bp, mask OIENPF_SIMULATE_PRESS_AND_RELEASE
	call	OLItemEnsureIsReleased
	ret
OLItemActivate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemChange -- 
		MSG_SPEC_CHANGE for OLItemClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Does a "change" on the gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemClass
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
	chris	12/ 1/94         	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLItemChange	method dynamic	OLItemClass, \
				MSG_SPEC_CHANGE
	call	CheckIfBoolean		;not a boolean, branch
	jnc	item
	mov	ax, MSG_GEN_ACTIVATE
	GOTO	ObjCallInstanceNoLock
item:
	GOTO	VisCallParent

OLItemChange	endm

endif

ItemCommon ends

ItemCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawPMCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a simple check to represent radio buttons and check boxes
		in menus.

CALLED BY:	ItemDrawColorPMRadioButton
		ItemDrawColorCheckBox
		ItemDrawBWRadioButton
		ItemDrawBWNonExclusiveItem

PASS:		*ds:si	= instance data for object
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = true if total redraw (can optimize)
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM		;--------------------------------------------------------------

ItemDrawPMCheck	proc	far
	uses	ds, si, ax, bx, cx, dx
	.enter

	mov	ax, C_WHITE				; assume not selected
	call	OpenCheckIfBW
	jnc	notBW

	test	bh, mask OLBSS_SELECTED			; if not selected
	jz	setColor				;  use white to erase
notBW:
	test	bh, mask OLBSS_SELECTED
	jz	done

	mov	ax, C_BLACK
setColor:
	call	GrSetAreaColor				; Set check color

	push	cx
	test	bh, mask OLBSS_BORDERED
	pushf
	call	GetCheckboxBounds			; Get X & Y coord
	popf
	jz	setpen

	call	OpenCheckIfBW
	jc	setpen					; If not BW and
	inc	ax					; bordered, move to
							; the right one pixel
setpen:
	call	GrMoveTo				; Place the pen
	pop	cx

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	mov	si, offset itemCheck
	call	GrFillBitmap

FXIP <	push	bx							>
FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

done:
	.leave
	ret
ItemDrawPMCheck	endp

if _FXIP			; bitmap must be in separate resource for xip
ItemCommon		ends
RegionResourceXIP	segment resource
endif

itemCheck	label	word
	word	CHECK_WIDTH
	word	CHECK_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00001000b
	byte	00000000b, 00011000b
	byte	00000000b, 00110000b
	byte	00010000b, 01100000b
	byte	00011000b, 11000000b
	byte	00001101b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

if _FXIP			; bitmap must be in separate resource for xip
RegionResourceXIP	ends
ItemCommon		segment resource
endif

endif		; if _PM ------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawJediDot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a simple dot to represent radio buttons in menus.

CALLED BY:	ItemDrawBWRadioButton

PASS:		*ds:si	= instance data for object
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = true if total redraw (can optimize)
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

ItemDrawJediDot	proc	far
		uses	ax, bx, cx, dx, si, ds
		.enter
		
		mov	ax, C_WHITE			; assume not selected
		
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	bx, ds:[di].OLBI_specState
		pop	di

		test	bx, mask OLBSS_SELECTED
		jz	checkColor

		mov	ax, C_BLACK
checkColor:
	;
	;  Whatever color we chose, we have to draw the opposite
	;  if we're bordered.
	;
		test	bx, mask OLBSS_DEPRESSED
		jz	setColor
	;
	;  Toggle color in a manner independent of the values of the enums.
	;
		cmp	ax, C_BLACK
		je	whiteOut
		mov	ax, C_BLACK
		jmp	setColor
whiteOut:
		mov	ax, C_WHITE
setColor:		
		call	GrSetAreaColor			; Set check color
		
		call	GetCheckboxBounds		; Get X & Y coord
		call	GrMoveTo			; Place the pen
		
FXIP <		push	ax, bx						>
FXIP <		mov	bx, handle RegionResourceXIP			>
FXIP <		call	MemLock						>
FXIP <		mov	ds, ax						>
FXIP <		pop	ax, bx						>

NOFXIP <	segmov	ds, cs						>
		
		mov	si, offset itemDot
		call	GrFillBitmap
		
FXIP <		push	bx						>
FXIP <		mov	bx, handle RegionResourceXIP			>
FXIP <		call	MemUnlock					>
FXIP <		pop	bx						>
		
done:
		.leave
		ret
ItemDrawJediDot	endp

if _FXIP		; bitmap must be in separate resource for xip
ItemCommon		ends
RegionResourceXIP	segment resource
endif

itemDot	label	word
	word	RADIO_WIDTH
	word	RADIO_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 00000000b
	byte	00000111b, 10000000b
	byte	00000111b, 10000000b
	byte	00000011b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

if _FXIP		; bitmap must be in separate resource for xip
RegionResourceXIP	ends
ItemCommon		segment resource
endif

endif		; if _JEDIMOTIF -----------------------------------------------

ItemCommon ends
ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemNavigateIfDisabled -- 
		MSG_OL_ITEM_NAVIGATE_IF_DISABLED for OLItemClass

DESCRIPTION:	Sets some navigate flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_ITEM_NAVIGATE_IF_DISABLED
		cl	- OLIS_NAVIGATE_BACKWARD to go backward

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/24/92		Initial Version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemNavigateIfDisabled	method dynamic	OLItemClass, \
				MSG_OL_ITEM_NAVIGATE_IF_DISABLED

EC <	test	cl, not mask OLIS_NAVIGATE_BACKWARD			>
EC <	ERROR_NZ	OL_ERROR					>

	andnf	ds:[di].OLII_state, not mask OLIS_NAVIGATE_BACKWARD

	ornf	cl, mask OLIS_NAVIGATE_IF_DISABLED
	ornf	ds:[di].OLII_state, cl
	;
	; We'll assume that this has been called after items have been scanned.
	; If our moniker is currently valid, but we're disabled, we'll assume
	; that we're in a dynamic list, and the moniker has been fetched already
	; and any MSG_SPEC_NOTIFY_NOT_ENABLED has come down the pike.  We'll
	; simulate that message.
	;
	test	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
	jnz	exit				;moniker still invalid, branch
	call	GenCheckIfFullyEnabled
if 0
	jc	exit
else
;
; code to fix navigation bug in dynamic list with no enabled items
; - brianc 1/14/93
;
	jnc	disabled			;disabled, branch
	;
	; we are enabled, we've been selected elsewhere, just clean up
	;
	call	GenSwapLockParent
	mov	ax, TEMP_OL_ITEM_GROUP_NAVIGATE_IF_DISABLED_ITEM
	call	ObjVarDeleteData
	call	ObjSwapUnlock
	jmp	short exit

disabled:
	;
	; we are disabled, if our parent OLItemGroup has already tried to
	; navigate to us, then give up
	;
	push	si
	call	IC_DerefGenDI
	mov	dx, ds:[di].GII_identifier	;cx = item identifier
	call	GenSwapLockParent
	push	bx
	mov	ax, TEMP_OL_ITEM_GROUP_NAVIGATE_IF_DISABLED_ITEM
	call	ObjVarFindData
	jnc	notFound
	cmp	dx, ds:[bx]			;tried us already?
	stc					;indicate no
	jne	common
	call	ObjVarDeleteDataAt
	clc					;indicate that we tried already
	jmp	short common

notFound:
	mov	cx, size word
	call	ObjVarAddData
	mov	ds:[bx], dx			;store item chunk
	stc					;indicate not tried yet
common:
	pop	bx
	call	ObjSwapUnlock
	pop	si
	jnc	exit				;if already tried, give up
endif

	call	OLItemSpecNotifyNotEnabled	;else handle this
exit:
	ret
OLItemNavigateIfDisabled	endm

ItemCommon	ends
ItemVeryCommon segment resource

IVC_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
IVC_DerefGenDI	endp

IVC_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
IVC_DerefVisDI	endp

;IVC_ObjCallInstanceNoLock	proc	near
;	call	ObjCallInstanceNoLock
;	ret
;IVC_ObjCallInstanceNoLock	endp

IVC_ObjMessageCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	IVC_ObjMessage
IVC_ObjMessageCall	endp

IVC_ObjMessage		proc	near
	call	ObjMessage
	ret
IVC_ObjMessage		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGetParentState

DESCRIPTION:	Get parent's state

PASS:		*ds:si	= instance data for OLItem object

RETURNS:	cl	= OLItemGroupState:
				OLIGS_COLOR
				OLIGS_GROUP_HAS_MOUSE_GRAB
				OLIGS_INTERMEDIATE
		ch	= GenAttrs:
				GA_READ_ONLY
		dl	= GenItemGroupBehaviorType
    (Tab only)	dh	= OLItemExtraRecord
		carry set if toolbox hint present

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite
	sean	5/6/96		Support for tabs

------------------------------------------------------------------------------@
OLItemGetParentState	proc	far
	uses ax, bx, si, di, es
	.enter

	call	GenSwapLockParent
EC <	ERROR_NC	OL_ERROR					>

EC <	call	VisCheckVisAssumption					>

	push	bx
	mov	ax, HINT_ITEM_GROUP_TOOLBOX_STYLE
	call	ObjVarFindData
	pop	bx
	pushf

TABS <	call	CheckForTabs		; dh = OLItemExtraRecord	>

	mov	di, segment GenBooleanGroupClass
	mov	es, di
	mov	di, offset GenBooleanGroupClass
	call	ObjIsObjectInClass
	mov	dl, GIGBT_NON_EXCLUSIVE		;assume boolean group, non-excl
	jc	10$
	call	IVC_DerefGenDI
	mov	dl, ds:[di].GIGI_behaviorType
10$:
	call	IVC_DerefGenDI
	mov	ch, ds:[di].GI_attrs

	call	IVC_DerefVisDI
	mov	cl, ds:[di].OLIGI_state

	call	ObjSwapUnlock
	popf

	.leave
	ret
OLItemGetParentState	endp

if	ALLOW_TAB_ITEMS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForTabs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the tab portion of the OLItemExtraRecord
		which describes what type of tab to draw
		if any.

CALLED BY:	OLItemGetParentState

PASS:		*ds:si	= Item object

RETURN:		dh	= tab stuff of OLItemExtraRecord
	
DESTROYED:	ax, di, es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		if(tab style)
		  assume top-tab/flat
		  if(orient children vertically)
		    assume left-tab
		    if(right justify children)
		      right-tab
		  if(3-D raised)
		    set 3-D bit 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	5/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForTabs	proc	near
	uses	bx
	.enter

	; Look for tab style hint
	;
	clr	dh			; assume no tab style
	mov	ax, HINT_ITEM_GROUP_TAB_STYLE
	call	ObjVarFindData		; find hint ?
	jc	tabStyle
exit:
	.leave
	ret

	; If we're a tab group then look for other hints to
	; tell us what way to draw the tabs.
	;
tabStyle:
	ornf	dh, OLITS_TAB_TOP
	segmov	es, cs				; Point to segment w/ hint
	mov	di, offset cs:OLItemGroupTabHints	
	mov	ax, length (cs:OLItemGroupTabHints)	
	call	OpenScanVarData			; dh = OLItemExtraRecord
	jmp	exit

CheckForTabs	endp

OLItemGroupTabHints	VarDataHandler \
	 <HINT_ORIENT_CHILDREN_VERTICALLY, \
			 offset ItemVeryCommon:OLItemGroupTabHintVertical>,
	 <HINT_DRAW_STYLE_3D_RAISED, \
 			 offset ItemVeryCommon:OLItemGroupTabHint3D>
	 

OLItemGroupTabHintVertical	proc	far

	; Assume tabs are to the left.
	;
	andnf	dh, not (mask OLIER_TAB_STYLE)	; clear tab style bits
	ornf	dh, OLITS_TAB_LEFT		; set tab left		
	mov	ax, HINT_RIGHT_JUSTIFY_CHILDREN
	call	ObjVarFindData
	jc	rightTabs
exit:	
	ret

	; Tabs are to the right.
	;
rightTabs:
	andnf	dh, not (mask OLIER_TAB_STYLE)	; clear tab style bits
	ornf	dh, OLITS_TAB_RIGHT		; set tab right
	jmp	exit

OLItemGroupTabHintVertical	endp

OLItemGroupTabHint3D	proc	far

	ornf	dh, mask OLIER_3D_TAB		; set 3-D bit
	ret

OLItemGroupTabHint3D	endp
endif		; if ALLOW_TAB_ITEMS 

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemUpdateDrawStateAndRedraw

DESCRIPTION:	This routine serves as an interface between the state flags
		of this OLItemClass object, and the drawing flags of
		its superclass, OLButtonClass.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemUpdateDrawState	proc	far
	class	OLItemClass

	;get specific OLButtonClass state, and reset all
	;drawing-related flags (except OLBSS_CURSORED!)

	call	IVC_DerefVisDI
	mov	al, {byte}ds:[di].OLBI_specState
	andnf	al, (not OLBOF_STATE_FLAGS_MASK) or mask OLBSS_CURSORED

;------------------------------------------------------------------------------

;	test	ds:[di].OLII_state, mask OLIS_DEFAULT ; Is this the default?
;	jz	10$

;	ornf	al, mask OLBSS_DEFAULT

;------------------------------------------------------------------------------
10$:	;See if this object should be drawn as SELECTED.

	test	ds:[di].OLII_state, mask OLIS_INDETERMINATE
	jnz	12$			;is indeterminate, check other things

	test	ds:[di].OLII_state, mask OLIS_SELECTED
	jnz	15$			;skip if so...
12$:
	;if PM and IS_SCROLL_ITEM, then we ARE using intermediate mode -
	; even in menus.

	push	di, es
	mov	di, segment OLScrollableItemClass
	mov	es, di
	mov	di, offset OLScrollableItemClass
	call	ObjIsObjectInClass
	pop	di, es
	jc	13$

	;if (Motif, CUA) AND in menu, ignore PRESSING status,
	;since we ARE NOT using intermediate mode.  (Do do if drawing as a
	;toolbox.  -cbh 10/26/92)

	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jnz	13$
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	20$			;skip if CUA and in menu...	>
13$:
	;if is non-exclusive item, ignore PRESSING status

	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
	je	20$			;skip if non-exclusive...

	;the PRESSING status also drives the SELECTED emphasis: check
	;if currently PRESSING on item.

	test	ds:[di].OLII_state, mask OLIS_PRESSING_ON_ITEM
	jz	20$			;skip if not...

15$:
	ornf	al, mask OLBSS_SELECTED

;------------------------------------------------------------------------------
20$:	;See if this object should be drawn as DEPRESSED

	test	ds:[di].OLII_state, mask OLIS_PRESSING_ON_ITEM
	jz	30$			;skip if not...

	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, the item buttons
	; are depressed if we are in B&W.  If _ASSUME_BW_ONLY is true, then
	; we do not check confirm that we are in B&W mode, but just assume
	; that is the case. --JimG 5/5/94
	
if  _BW_MENU_ITEM_SELECTION_IS_DEPRESSED	;-----------------------
	;is pressing on item:
	;We are told that it should be drawn DEPRESSED.. so do it.
	
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	24$			;skip if not in menu...
	
	ornf	al, mask OLBSS_DEPRESSED

24$:	;not in menu: do not set DEPRESSED, because drawing code cannot
	;yet handle it.
endif ; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED	;-----------------------

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)
	call	OpenCheckIfBW
	jc	30$				; if BW, we are done..
	ornf	al, not mask OLBSS_DEPRESSED	; color, remove depressed bit.
						; let code below set it.
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)

if	 (not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

if _MOTIF	;-----------------------
	;is pressing on item:
	;Motif: if in a menu, set BORDERED

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	25$			;skip if not in menu...

	ORNF	al, mask OLBSS_BORDERED
;	jmp	short 30$

25$:	;Motif: not in menu: do not set DEPRESSED, because drawing code cannot
	;yet handle it.

elseif _PM	;------------------------
	;is pressing on item:
	;PM: if in a menu, set BORDERED; else set DEPRESSED

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	25$			;skip if not in menu...
	ornf	al, mask OLBSS_BORDERED
	jmp	short 30$
25$:
	ornf	al, mask OLBSS_DEPRESSED

else		;-----------------------

	;is pressing on item:
	;CUA/OpenLook: if in a menu, set depressed, because drawing
	;code can handle it: will invert the entire item region.

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	25$			;skip if not in menu...

	ornf	al, mask OLBSS_DEPRESSED
;	jmp	short 30$

25$:	;CUA/OpenLook: not in a menu: do not set DEPRESSED,
	;because drawing code cannot handle it yet.

endif		;-----------------------

endif	;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

;------------------------------------------------------------------------------
30$:	;See if this object should be drawn as BORDERED

if	 not (_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and _ASSUME_BW_ONLY)
if _MOTIF or _PM	;-----------------------
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jz	40$			;skip if not cursored...

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	call	OpenCheckIfBW
	jc	40$			;B&W, skip this
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	40$			;skip if not in menu...

	ornf	al, mask OLBSS_BORDERED
endif		;-----------------------
endif	;not (_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and _ASSUME_BW_ONLY)

;------------------------------------------------------------------------------
40$:	;save new state flags into OLButtonClass instance data

	mov	{byte}ds:[di].OLBI_specState, al
	ret
OLItemUpdateDrawState	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemDrawIfNewState

DESCRIPTION:	Draw this button if its state has changed since the last draw.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemDrawIfNewState	proc	far
	push	ax
	call	OLItemGetGenAndSpecState
					;sets:	bl = OLBI_moreAttrs
					;       bh = OLBI_specState (low byte)
					;	cl = OLBI_optFlags
					;	dl = GI_states
					;	dh = OLII_state

	;
	; Moniker is invalid, nothing to draw, exit.
	;
	test	dh, mask OLIS_MONIKER_INVALID
	jnz	done

	push	di, dx			;can I trash di?
	call	IVC_DerefVisDI
	mov	ax, ds:[di].OLBI_specState ;ax = OLBI_specState (entire word)
	mov	dl, ds:[di].VI_attrs	;dl holds VisAttrs
	xor	dl, cl			;compare new VA_FULLY_ENABLED state
	test	dl, mask VA_FULLY_ENABLED	;   to new state
	DoPop	dx, di
	jnz	drawObject		;skip if different...

;------------------------------------------------------------------------------
considerDefaultSelected:
	xor	bh, cl			;compare new state to old state
	test	bh, mask OLBSS_DEFAULT or mask OLBSS_SELECTED
	jnz	drawObject		;skip if state change...

;------------------------------------------------------------------------------

if _MOTIF or _PM	;------------------------------------------------------

considerBordered:
	;if BORDERED has changed, but is an object which cannot show
	;bordered emphasis (i.e. is not in menu), then do not redraw.

	test	ax, mask OLBSS_IN_MENU
	jz	considerDepressed	;skip if not in menu...

testBordered:
	;see if BORDERED has changed
	
	test	bh, mask OLBSS_BORDERED
	jnz	drawObject		;skip if BORDERED changed...
endif 		;(_MOTIF) ---------------------------------------------

;------------------------------------------------------------------------------
considerDepressed:

	;if DEPRESSED has changed, but is an object which cannot show
	;depressed emphasis, do not redraw.

	call	IVC_DerefVisDI
	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
	je	considerDepressedNonExcl ;skip if non-exclusive...

considerDepressedExcl:
	;CUA:		in menu:	can show depressed emphasis (inverts
	;				entire item region)
	;		in window:	cannot yet show depressed emphasis (1)
	;
	;PM:		in menu:	cannot show depressed emphasis
	;		in window:	can show depressed emphasis
	;
	;Motif:		in menu:	cannot yet show depressed emphasis (2)
	;		in window:	cannot yet show depressed emphasis (2)
	;
	;Stylus:  (if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE)
	;		in menu:	can show depressed emphasis (inverts
	;				entire item region)
	;		in window:	cannot yet show depressed emphasis
	;
	;Notes:
	;	(1): in this case, depressed emphasis would be a fatter black
	;		ring around the item item (in both B&W and
	;		color modes).
	;	(2): in this case, in B&W, see note (1). In color, depressed
	;		emphasis might be a fatter etch line for the diamond.

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if	 not _ASSUME_BW_ONLY
	call	OpenCheckIfBW
	jnc	considerCursored		; color.. do not check depressed
endif	;not _ASSUME_BW_ONLY

	test	ax, mask OLBSS_IN_MENU
	jnz	testDepressed		;skip if in menu...
	
else	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED is FALSE

NOT_MO<	test	ax, mask OLBSS_IN_MENU					>
NOT_MO<	jnz	testDepressed		;skip if in menu...		>
PMAN  <	test	ax, mask OLBSS_IN_MENU					>
PMAN  <	jz	testDepressed		;test if not in menu		>

endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	jmp	short considerCursored	;move on

considerDepressedNonExcl:
	;all non-exclusives (except those in scrolling lists) can show
	;depressed emphasis.

	push	di, es
	mov	di, segment OLScrollableItemClass
	mov	es, di
	mov	di, offset OLScrollableItemClass
	call	ObjIsObjectInClass
	pop	di, es
	jc	considerCursored

testDepressed:
	;see if DEPRESSED has changed
	
	test	bh, mask OLBSS_DEPRESSED
	jnz	drawObject		;skip if DEPRESSED changed...

;------------------------------------------------------------------------------
considerCursored:
	;if CURSORED is only flag which changed, but is in menu, ignore it.
	;(also ignore if noKeyboard is set -cbh 2/ 9/93)

	call	OpenCheckIfKeyboard
	jnc	done

	test	ax, mask OLBSS_IN_MENU
	jnz	done			;skip if is in menu...

	; In Rudy, we want to redraw the object if the cursored mode
	; changes.
if not _RUDY
testCursored:
	test	bh, mask OLBSS_CURSORED
	jz	done			;skip if no state change...
endif

drawObject:
	call	OpenDrawObject		;draw object and save new state

done:
	pop	ax
	ret
OLItemDrawIfNewState	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemDraw -- MSG_VIS_DRAW for OLItemClass

DESCRIPTION:	Draw the item

PASS:		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_VIS_DRAW
		cl - DrawFlags:  DF_EXPOSED set if updating
		bp - GState to use

RETURN:		nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Call the correct draw routine based on the display type:

	if (black & white) {
		ItemDrawBWItem();
	} else {
		ItemDrawColorItem();
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
OLItemDraw	method OLItemClass, MSG_VIS_DRAW

EC <	call	VisCheckVisAssumption	; Make sure vis data exists >
EC <	call	GenCheckGenAssumption	; Make sure gen data exists >

	;
	; Clear the navigate flags.  We didn't need them here anyway.
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	and	ds:[bx].OLII_state, not (mask OLIS_NAVIGATE_IF_DISABLED or \
					 mask OLIS_NAVIGATE_BACKWARD)

	test	ds:[bx].VI_attrs, mask VA_REALIZED
	jz	Exit			; if not realized, Exit
	test	ds:[bx].VI_optFlags, mask VOF_IMAGE_INVALID
	jz	drawItem		; If image invalid, Exit.

Exit:
	ret

drawItem:

if _CUA or _MAC	;----------------------------------------------

	;CUA: if in a menu, let OLButtonClass handle the
	;drawing for this object. (This DOES NOT include toolbox items
	;inside a menu.)

	call	IVC_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	20$

EC <	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX		>
EC <	ERROR_NZ OL_ERROR						>

	mov	di, offset OLItemClass
	CallSuper	MSG_VIS_DRAW
	jmp	short updateState	;skip to update state
20$:
endif			;------------------------------------------------------

;SAVE BYTES: have color flag already!

	;get display scheme data

	segmov	es, ds
	push	bp			;Save the GState
	mov	di, bp			;put GState in di
	push	cx			;save DrawFlags
	mov	ax,GIT_PRIVATE_DATA
	call	GrGetInfo		;returns ax, bx, cx, dx
	pop	cx

	;al = color scheme, ah = display type, cl = update flag
	;*ds:si = OLItem object

	andnf	ah, mask DF_DISPLAY_TYPE
	cmp	ah, DC_GRAY_1
	mov	ch, cl			;Pass DrawFlags in ch
	mov	cl, al			;Pass color scheme in cl
ife _JEDIMOTIF
OLS <	jne	color			;skip if on color screen...	>
MO <	jne	color			;skip if on color screen...	>
PMAN <	jne	color			;skip if on color screen...	>
else
	jne	color1
endif
bw::
	;
	; draw black & white
	;
	CallMod	ItemDrawBWItem
ife _JEDIMOTIF

if _OL_STYLE or _MOTIF or _PM	;----------------------------------------------
	jmp	short common

color:	;draw color item

if _HAS_LEGOS_LOOKS
	;
	; PCV draw components with BW regions, not color regions.
	;
	; It would be nice to check if this is a component or a non-component
	; object in the spui.  I don't know how to do that now I'll just
	; assume it is a component
	jmp	bw
	
endif ; HAS_LEGOS_LOOK
if not _ASSUME_BW_ONLY
	CallMod	ItemDrawColorItem
endif			;------------------------------------------------------
endif	; not _ASSUME_BW_ONLY

else
	jmp	short common

color1:	;draw color item

if not _ASSUME_BW_ONLY
	CallMod	ItemDrawColorItem
endif			;------------------------------------------------------
endif
		
;SAVE BYTES here. Do calling routines do this work for us?

common:
	pop	di				; Restore the GState
	mov	bx, ds:[si]			; Check if the item is 
	add	bx, ds:[bx].Vis_offset		;    enabled.
	test	ds:[bx].VI_attrs, mask VA_FULLY_ENABLED
	jnz	updateState			; If so, exit

	mov	al, SDM_100			; If not, reset the draw masks
	call	GrSetAreaMask			;    to solid
	call	GrSetLineMask
	call	GrSetTextMask

updateState:
	GOTO	UpdateItemState
OLItemDraw	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemSetState -- 
		MSG_OL_ITEM_SET_STATE for OLItemClass

DESCRIPTION:	Sets item state.  Called by the list as part of updating the
		list's state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_ITEM_SET_STATE
		cl	- mask OLIS_SELECTED if selected
			  mask OLIS_INDETERMINATE if indeterminate
		dl	- OLItemUpdateFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/27/92		Initial Version

------------------------------------------------------------------------------@


OLItemSetState	method dynamic	OLItemClass, MSG_OL_ITEM_SET_STATE
	andnf	cl, mask OLIS_SELECTED or mask OLIS_INDETERMINATE
	;
	; Set new selected flag, if it's changing.  Then update the sucker
	; if the OLItemUpdateFlags allow.
	;
	mov	ch, cl
	mov	dh, ds:[di].OLII_state		;get current state
	xor	ch, dh				;see if anything changed
	test	ch, mask OLIS_SELECTED or mask OLIS_INDETERMINATE
	jz	exit				;nope, exit
	andnf	dh, not (mask OLIS_SELECTED or mask OLIS_INDETERMINATE)
	ornf	dh, cl				;or in new flag
	mov	ds:[di].OLII_state, dh		;and store
	
	call	OLItemUpdateDrawStateAndDrawIfNotSuppressed  ;delSesto land...
exit:
	ret
OLItemSetState	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemUpdateDrawStateAndDrawIfNotSuppressed

SYNOPSIS:	Updates draws state and draws if not suppressed. :)

CALLED BY:	OLItemSetState

PASS:		*ds:si -- object
		dl     -- OLItemUpdateFlags

RETURN:		nothing

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/92		Initial version

------------------------------------------------------------------------------@

OLItemUpdateDrawStateAndDrawIfNotSuppressed	proc	near
	push	bx, cx, dx, bp
	call	OLItemUpdateDrawState

	test	dl, mask OLIUF_SUPPRESS_DRAW
	jnz	done

	test	dl, mask OLIUF_SUPPRESS_DRAW_IF_CURSORED
	jz	attemptToRedraw

	call	IVC_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jnz	done

attemptToRedraw:
	call	OLItemDrawIfNewState	;Redraw if any state flag changed
					;trashes bx, di; may move lmem chunks.

done:
	pop	bx, cx, dx, bp
	ret
OLItemUpdateDrawStateAndDrawIfNotSuppressed	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemSetMasksIfDisabled

DESCRIPTION:	This routine sets the draw masks to n% if this object
		is not VA_FULLY_ENABLED.

CALLED BY:	ItemDrawBWitem, ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		dl	= GI_states
		al	= MASK value to use

RETURN:		ds, si, dl = same
		zero flag set if disabled

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if (not _ASSUME_BW_ONLY) or _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50 or (not USE_COLOR_FOR_DISABLED_GADGETS)

OLItemSetMasksIfDisabled	proc	far
	push	di
	call	IVC_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	pop	di
	jnz	done			;skip if is enabled...

	;Item is not enabled. Draw the disabled item by simply drawing
	;a mask over the drawn item.

	pushf	
	call	GrSetLineMask
	call	GrSetTextMask
	call	GrSetAreaMask
	popf
done:
	ret
OLItemSetMasksIfDisabled	endp

endif


ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfJustDisabled

SYNOPSIS:	Sees if this item has just been disabled.

CALLED BY:	OLItemWash50Percent
		ItemDrawColorItem

PASS:		*ds:si -- item
		cl -- OLButtonOptFlags

RETURN:		carry set if just disabled

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/15/92		Initial version

------------------------------------------------------------------------------@

if (not _ASSUME_BW_ONLY) or _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50 or (not USE_COLOR_FOR_DISABLED_GADGETS)

CheckIfJustDisabled	proc	far
	push	di
	call	IVC_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	pop	di
	jnz	exit			;skip if so (cy=0)...

	test	cl, mask OLBOF_ENABLED	;was this object just ENABLED?
	jz	exit			;skip if not (has been disabled for a
					;while. Return Carry clear)..
	stc
exit:
	ret
CheckIfJustDisabled	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemSetupMkrArgs

SYNOPSIS:	Set up args for the moniker.

CALLED BY:	OLItemRerecalcSize, OLItemGetExtraSize, OLItemGetCenter

PASS:	*ds:si -- handle of object
	ss:bp  - OpenMonikerArgs

RETURN:		OpenMonikerArgs set up
		*es:bx -- handle of object

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/21/89	Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemSetupMkrArgs	proc	far
	class	OLItemClass

EC <	call	ECInitOpenMonikerArgs	;save IDs on stack for testing	>
   
	clr	ss:[bp].OMA_gState			;no gstate
	clr	ss:[bp].OMA_monikerAttrs
	
	;if moniker is in a menu, display the keyboard moniker.
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLBI_specState, mask OLBSS_IN_MENU
	jz	1$				;not in menu, branch
	ornf	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM
1$:
	;
	; If shortcuts turned off, either because in no-keyboard mode, or
	; by user, force shortcuts to be *NOT* drawn.
	; If in keyboard-only mode, force shortcuts to be drawn
	; If hints desires shortcut, force shorcuts to be drawn
	; Else, set according to in-menu status
	;
	call	OpenCheckIfKeyboardNavigation
	jnc	afterShortcut		; skip if not providing kbd nav

	test	ds:[bx].OLBI_fixedAttrs, mask OLBFA_FORCE_NO_SHORTCUT	; ?
	jnz	afterShortcut			; yes, no shortcuts
						; assume shortcuts drawn
	ORNF	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_KBD_MONIKER
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	afterShortcut			; yes, force shortcuts
	test	ds:[bx].OLBI_fixedAttrs, mask OLBFA_FORCE_SHORTCUT
	jnz	afterShortcut			; yes, force shortcuts
if (not _JEDIMOTIF)	; JEDI menu items don't show shortcut by default
	test	ds:[bx].OLBI_specState, mask OLBSS_IN_MENU	; in menu?
	jnz	afterShortcut				; yes, use shortcuts
endif
						; else, turn it off again
	ANDNF	ss:[bp].OMA_monikerAttrs, not mask OLMA_DISP_KBD_MONIKER
afterShortcut:

if _RUDY
	;
	; All accelerators are drawn to right in Rudy.
	;
	ORNF	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_TO_RIGHT
endif
	;
	; if we want to draw shortcuts below, set OLMA_DRAW_SHORTCUT_BELOW
	;
	test	ds:[bx].OLBI_moreAttrs, mask OLBMA_DRAW_SHORTCUT_BELOW
	jz	3$
	test	ds:[bx].OLBI_specState, mask OLBSS_IN_MENU	; in menu?
	jnz	3$				; yes, don't allow below
	ORNF	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_BELOW
3$:
	
if _OL_STYLE	;---------------------------------------------------------------
   	mov	ss:[bp].OMA_leftInset, BUTTON_INSET_X
   	mov	ss:[bp].OMA_rightInset, BUTTON_INSET_X
   	mov	ss:[bp].OMA_topInset, BUTTON_INSET_Y
   	mov	ss:[bp].OMA_bottomInset, BUTTON_INSET_Y

	mov	ss:[bp].OMA_drawMonikerFlags, (J_CENTER shl offset DMF_X_JUST) or \
					 (J_CENTER shl offset DMF_Y_JUST)
endif		;---------------------------------------------------------------

if _CUA_STYLE	;---------------------------------------------------------------
	mov	ss:[bp].OMA_drawMonikerFlags, (J_LEFT shl offset DMF_X_JUST) or \
					 (J_CENTER shl offset DMF_Y_JUST)

	mov	ss:[bp].OMA_leftInset, MO_ITEM_INSET_LEFT
   	mov	ss:[bp].OMA_rightInset, MO_ITEM_INSET_RIGHT
	mov	ax, MO_ITEM_INSET_Y
	call	OpenMinimizeIfCGA			;zeroes ax if CGA
   	mov	ss:[bp].OMA_topInset, ax
	mov	ss:[bp].OMA_bottomInset, ax
endif		;---------------------------------------------------------------

	test	ds:[bx].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jz	10$

   	mov	ss:[bp].OMA_leftInset, TOOLBOX_INSET_X
   	mov	ss:[bp].OMA_rightInset, TOOLBOX_INSET_X
   	mov	ss:[bp].OMA_topInset, TOOLBOX_INSET_Y
   	mov	ss:[bp].OMA_bottomInset, TOOLBOX_INSET_Y

	call	OLItemGetParentState


if (BW_TOOLBOX_INSET_X - TOOLBOX_INSET_X)
   	CheckHack <((BW_TOOLBOX_INSET_X - TOOLBOX_INSET_X) eq 1)>

	call	OpenCheckIfBW
	jnc	10$				;not BW, exit
	inc	ss:[bp].OMA_leftInset		;else leave an extra pixel
	inc	ss:[bp].OMA_rightInset
	inc	ss:[bp].OMA_topInset
	inc	ss:[bp].OMA_bottomInset
endif
10$:
	mov	cx, ss:[bp].OMA_drawMonikerFlags	;return cl = DrawMonikerFlags
						;in case some old code needs it

SBOX <	call	SetSelectionBoxInsets					>

if _ODIE
	;
	; set insets for alphanumeric tabs
	;
	call	SetAlphaTabInsets
endif

	;set bx = chunk of generic object which has VisMoniker for this
	;OLItemClass object (in most cases, will be same object).

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx].OLBI_genChunk	;get chunk holding gen data
	segmov	es, ds
EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>

	ret
OLItemSetupMkrArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectionBoxInsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker insets in the OpenMonikerArgs 
		struct on stack if the item group parent is a
		selection box.

CALLED BY:	OLItemSetupMkrArgs

PASS:		*ds:si	= GenItem object
		ss:bp	= OpenMonikerArgs 
		
RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	can set OpenMonikerArgs struct on stack

PSEUDO CODE/STRATEGY:
		if(parent == selection box)
		  set selection box insets for moniker

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	9/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
SetSelectionBoxInsets	proc	near
	uses	ax,bx,si
	.enter

	call	GenSwapLockParent		; *ds:si = Item group
	push	bx				; save our block handle
	
	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
	call	ObjVarFindData			; is it a selection box ?
	jnc	exit

	; Use the selection box insets
	;
	mov	ss:[bp].OMA_leftInset, VERTICAL_SELECTION_BOX_LEFT_INSET
	mov	ss:[bp].OMA_rightInset, VERTICAL_SELECTION_BOX_RIGHT_INSET

	mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
	call	ObjVarFindData
	jc	exit
	
	mov	ss:[bp].OMA_leftInset, HORIZONTAL_SELECTION_BOX_LEFT_INSET
	mov	ss:[bp].OMA_rightInset, HORIZONTAL_SELECTION_BOX_RIGHT_INSET
exit:	
	pop	bx				; bx = our block handle
	call	ObjSwapUnlock			; ds = our segment
	.leave
	ret
SetSelectionBoxInsets	endp
endif	; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAlphaTabInsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set insets for alphanumeric tabs

CALLED BY:	OLItemSetupMkrArgs
PASS:		*ds:si = GenItem
		ss:bp = OpenMonikerArgs
RETURN:		insets updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ODIE

SetAlphaTabInsets	proc	near
	uses	ax, bx, si
	.enter
	;
	; check for Gen object
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VI_typeFlags, mask VTF_IS_GEN
	jz	done
	;
	; check for gstring moniker
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	mov	bx, ds:[bx].GI_visMoniker
	mov	bx, ds:[bx]			; ds:bx = VisMoniker
	test	ds:[bx].VM_type, mask VMT_GSTRING
	jz	done				; not gstring
	;
	; check for alphanumeric tab
	;
	call	GenSwapLockParent		; *ds:si = parent
	tst	si
	jz	done				; no parent?
	push	bx				; save our block
	mov	ax, HINT_ITEM_GROUP_TAB_STYLE
	call	ObjVarFindData
	jnc	notAlphaTab
	mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
	call	ObjVarFindData
	jc	notAlphaTab			; alpha tab not vertical
	mov	ax, ALPHA_TAB_INSET_X
	mov	ss:[bp].OMA_leftInset, ax
	mov	ss:[bp].OMA_rightInset, ax
if (ALPHA_TAB_INSET_Y ne ALPHA_TAB_INSET_X)
	mov	ax, ALPHA_TAB_INSET_Y
endif
	mov	ss:[bp].OMA_topInset, ax
	mov	ss:[bp].OMA_bottomInset, ax
notAlphaTab:
	pop	bx				; bx = our block
	call	ObjSwapUnlock
done:
	.leave
	ret
SetAlphaTabInsets	endp

endif

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateItemState

DESCRIPTION:	This procedure copies this object's current draw flags
		OLBSS_DEPRESSED, etc) into the OLBI_optFlags byte, where
		they are archived so that we can later compare to see if
		a draw flag has changed.

CALLED BY:	OLItemDraw (ListGadgetCommon resource)

PASS:		*ds:si - object

RETURN:		carry set

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/89		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

UpdateItemState	proc	far
	class	OLItemClass

	call	IVC_DerefVisDI
	mov	dl, ds:[di].VI_attrs
	ANDNF	dl, mask VA_FULLY_ENABLED

	;get specific state flags

	mov	bl, {byte} ds:[di].OLBI_specState ;get low byte only
	ANDNF	bl, OLBOF_STATE_FLAGS_MASK	;keep only state flags

	ORNF	bl, dl				;calc new specific state
	ORNF	bl, mask OLBOF_DRAW_STATE_KNOWN	;set draw state known

	ANDNF	ds:[di].OLBI_optFlags, not (OLBOF_STATE_FLAGS_MASK \
						or mask OLBOF_ENABLED)
						;clear old state flags
	ORNF	ds:[di].OLBI_optFlags, bl	;and or new flags in
	stc
	ret
UpdateItemState	endp

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemRedraw -- 
		MSG_OL_ITEM_REDRAW for OLItemClass

DESCRIPTION:	Redraws an item.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_REDRAW
		bp 	- gstate to use, or null if none

		if USE_REDRAW_ITEMS_OPTIMIZATION
			cx	- child # of this object
			dx	- last child # to draw

RETURN:		nothing
		ax, cx, dx, bp - destroyed

		if USE_REDRAW_ITEMS_OPTIMIZATION
			Carry set if cx >= dx
			cx =	cx + 1
			dx, bp	unchanged
			ax	destroyed
ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/17/92		Initial Version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLItemRedraw	method dynamic	OLItemClass, MSG_OL_ITEM_REDRAW
if USE_REDRAW_ITEMS_OPTIMIZATION
	uses	cx, dx, bp
	.enter
endif
	push	si				;no longer connected to parent,
	call	GenFindParent			;  exit
	tst	si
	pop	si
	jz	exit

	;
	; First, let's ensure that our enabled state is correct.  The
	; dynamic list may have mucked with the generic instance data.
	;
	push	bp				;save gstate
	clr	cx				; steady state, so opt. OK
	call	GenCheckIfFullyEnabled
	jnc	notEnabled			;not enabled, branch

	call	IVC_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	enabledStateOK
	mov	ax, MSG_SPEC_NOTIFY_ENABLED
	jmp	short adjustEnabledState

notEnabled:
	call	IVC_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	enabledStateOK
	mov	ax, MSG_SPEC_NOTIFY_NOT_ENABLED

adjustEnabledState:
	mov	dx, VUM_NOW or (mask NEF_STATE_CHANGING shl 8)	
	mov	di, offset OLButtonClass	;do VisClass stuff
	call	ObjCallSuperNoLock

enabledStateOK:
	;
	; First, get our current state from our parent, and set ourselves to
	; be internally correct.  We'll avoid redrawing for the moment.
	;
	call	IVC_DerefGenDI
	mov	cx, ds:[di].GII_identifier
	mov	ax, MSG_OL_IGROUP_GET_ITEM_STATE
	call	GenCallParent			;returns OLItemState in al
if _RUDY
						; carry set if is focus
	;
	; In Rudy's non-focused lists, items don't get the lost
	; focus exclusive message, so don't turn off their OLBSS_CURSORED
	; flag.  We'll turn it off here manually if our item isn't
	; currently the focus item.
	;
	jc	keepCursored
	call	IVC_DerefVisDI
	andnf	ds:[di].OLBI_specState, not mask OLBSS_CURSORED
keepCursored:
endif ; _RUDY

	mov	cl, al
	push	ax				;push the item state
	mov	dl, mask OLIUF_SUPPRESS_DRAW	;we'll redraw below for sure
	mov	ax, MSG_OL_ITEM_SET_STATE
	call	ObjCallInstanceNoLock
	pop	ax				;restore item state
	;
	; Redraw the item.  We'll clear the DRAW_STATE_KNOWN flag so that
	; the item completely redraws.
	;
	call	IVC_DerefVisDI
	andnf	ds:[di].OLBI_optFlags, not mask OLBOF_DRAW_STATE_KNOWN
	pop	bp				;restore gstate
	clr	cl				;no update
	mov	ax, MSG_VIS_DRAW
if USE_REDRAW_ITEMS_OPTIMIZATION
	call	ObjCallInstanceNoLock
else
	GOTO	ObjCallInstanceNoLock
endif
exit:

if USE_REDRAW_ITEMS_OPTIMIZATION
	.leave
	inc	cx				; count one more child
	cmp	dx, cx				; set carry if max<current
endif
	ret

OLItemRedraw	endm

ItemVeryCommon ends
ItemVeryCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemSetInteractableState -- 
		MSG_GEN_ITEM_SET_INTERACTABLE_STATE for OLItemClass

DESCRIPTION:	Marks an item as interactable or not.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_SET_INTERACTABLE_STATE
		cx	- non-zero for interactable

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/19/92		Initial Version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
OLItemSetInteractableState	method static	OLItemClass, \
				MSG_GEN_ITEM_SET_INTERACTABLE_STATE

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLII_state, not mask OLIS_MONIKER_INVALID
	tst	cx
	jnz	exit
	ornf	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
exit:
	Destroy	ax, cx, dx, bp
	ret
OLItemSetInteractableState	endm

ItemVeryCommon ends
