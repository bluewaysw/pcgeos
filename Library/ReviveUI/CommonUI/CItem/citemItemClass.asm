COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC 
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemItemClass.asm

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItem.asm

DESCRIPTION:
	$Id: citemItemClass.asm,v 1.9 96/10/11 16:47:02 jimmy Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures	segment

	OLItemClass		mask CLASSF_DISCARD_ON_SAVE or \
					mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends

IGROUP_EXISTS 	equ	 0

;-----------------------

Resident	segment	resource




COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemIsInMenu

SYNOPSIS:	Returns whether item is in a menu.

CALLED BY:	utility

PASS:		*ds:si -- OLItem

RETURN:		zero flag clear if in menu

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 8/93       	Initial version

------------------------------------------------------------------------------@

if	0		;nuked by Brian Chin 6/93 
OLItemIsInMenu	proc	far
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	ret
OLItemIsInMenu	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLItemGetGenAndSpecState

DESCRIPTION:	This utility procedure is used by OLItemClass code
		to get the specific and generic attributes and state flags
		for this object.

PASS:		*ds:si	= instance data for object

RETURNS:	bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		dl = GI_states
		dh = OLII_state

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@
OLItemGetGenAndSpecState	proc	far
	class	OLItemClass

	push	di
	call	Res_DerefVisDI
	mov	bh, {byte} ds:[di].OLBI_specState ;LOW BYTE ONLY
	mov	cl, ds:[di].OLBI_optFlags
	mov	dh, ds:[di].OLII_state
	mov	bl, ds:[di].OLBI_moreAttrs

	call	Res_DerefGenDI
	mov	dl, ds:[di].GI_states
	pop	di
	ret
OLItemGetGenAndSpecState	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemSetAreaColorBlackIfEnabledOrInverting

SYNOPSIS:	Routine to choose area color in B/W toolbox items.

CALLED BY:	OLItemDrawBWItem

PASS:		*ds:si -- item 
		bp -- OLButtonSpecState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/28/93       	Initial version

------------------------------------------------------------------------------@

if (not _REDMOTIF) and (not _PCV) ;-------- Unneeded for Redwood/PCV projects

OLItemSetAreaColorBlackIfEnabledOrInverting	proc	far

if	INVERT_ENTIRE_BW_ITEM_IMAGE
	mov	ax, C_BLACK		;Draw black bitmap moniker
if not _RUDY	;------------------------- Rudy is black on grey text
	test	bp, (mask OLBSS_SELECTED) shl 8
	jz	10$			;use white
	mov	ax, C_WHITE		;Invert moniker if selected.
10$:
endif
	call	GrSetAreaColor		;color for b/w bitmap monikers
					;MUST return gstate in di,
	ret				;color used in ax!  -cbh 2/22/93
else
	FALL_THRU	OLItemSetAreaColorBlackIfEnabled
endif

OLItemSetAreaColorBlackIfEnabledOrInverting	endp

endif ;(not _REDMOTIF) and (not _PCV) ;---- Unneeded for Redwood/PCV projects

if not _JEDIMOTIF

OLItemSetAreaColorBlackIfEnabled	proc	far
	mov	ax, C_BLACK		;Draw black bitmap moniker
	call	GrSetAreaColor		;color for b/w bitmap monikers
					;MUST return gstate in di,
					;color used in ax!  -cbh 2/22/93
	ret
OLItemSetAreaColorBlackIfEnabled	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfExtendingOrNonExcl

SYNOPSIS:	Checks to see if we're doing either extended selection or
		non-exclusive selection, which is currently nearly identical.

CALLED BY:	utility

PASS:		*ds:si -- item

RETURN:		zero flag set if true

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/16/93       	Initial version

------------------------------------------------------------------------------@
CheckIfExtendingOrNonExcl	proc	far
	push	di

	call	CheckIfBoolean			;see if GenBoolean
	jnc	continueCheck
	tst	si				;so clear zero flag
	jmp	short exit			;and exit
	
continueCheck:
	call	Res_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	exit				;in menu, exit no match (z=0)
PMAN <	test	ds:[di].OLII_state, mask OLIS_IS_CHECKBOX		      >
PMAN <	jnz	exit				;exit (z=0) if not scroll item>
	cmp	ds:[di].OLII_behavior, GIGBT_EXTENDED_SELECTION
	je	exit
	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
exit:
	pop	di
	ret
CheckIfExtendingOrNonExcl	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfBoolean

SYNOPSIS:	Checks to see if this is a boolean object.

CALLED BY:	utility

PASS:		*ds:si -- OLItemClass

RETURN:		carry set if a GenBoolean

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/16/93       	Initial version

------------------------------------------------------------------------------@
CheckIfBoolean	proc	far
	push	di
	mov	di, segment GenBooleanClass	;GenBooleans can't extend.
	mov	es, di
	mov	di, offset GenBooleanClass
	call	ObjIsObjectInClass
	pop	di
	ret
CheckIfBoolean	endp



Resident ends

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemInitialize -- MSG_META_INITIALIZE for OLItemClass

DESCRIPTION:	Initialize an item object.

PASS:		*ds:si - instance data
		es - segment of OLItemClass
		ax - MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	3/90		cleanup, navigation & multiple select work
	Chris	5/92		GenItemGroupClass V2.0 rewrite
	sean	5/96		Added support for tabs

------------------------------------------------------------------------------@

OLItemInitialize	method private static	OLItemClass, \
							MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	;call superclass to set default attributes

	mov	di, segment OLItemClass
	mov	es, di
	mov	di, offset OLItemClass
	CallSuper MSG_META_INITIALIZE

	;override some default flags

	call	Build_DerefVisSpecDI
	andnf	ds:[di].OLBI_specState, not (mask OLBSS_BORDERED)
	ornf	ds:[di].OLBI_specState, mask OLBSS_SETTING

	;If our parent is a toolbox, we'll set our own toolbox flag.
	;(ds:di = specific instance data)

	call	OLItemGetParentState	;Returns:
					;cl	= OLItemGroupState
					;ch     = GenAttrs
					;dl	= GenItemGroupBehaviorType
					; (tab only) dh = OLItemExtraRecord
					;carry  = set if toolbox style
	jnc	10$
	ornf	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
10$:
RUDY <	ornf	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX		>

TABS <	call	CheckIfTabItem						>

	; ds:di still valid
	
	;Save the list type in the specific instance data of the list entry
	;to avoid lots of parent calls later on.
	;(ds:di = specific instance data, dl = ListAttrs from parent)

	ornf	ds:[di].OLII_behavior, dl
	
	;
	; Set the item's editable flag based on the parent.
	;
	andnf 	ch, mask GA_READ_ONLY
	call	Build_DerefGenDI
	andnf	ds:[di].GI_attrs, not mask GA_READ_ONLY
	ornf	ds:[di].GI_attrs, ch

	.leave
	ret
OLItemInitialize	endp

if	ALLOW_TAB_ITEMS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTabItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set item instance data if it's tab-style

CALLED BY:	OLItemInitialize

PASS:		ds:di	= OLItemInstance of item object
		dh	= OLItemExtraRecord (tab bits only)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	5/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfTabItem	proc	near
	.enter

	; Should only have bits in extra record relating to tabs.
	;
EC <	test	dh, not ((mask OLIER_3D_TAB) or (mask OLIER_TAB_STYLE))	>
EC <	ERROR_NZ	OL_ERROR					>

	; Check if this item is a tab.
	;
	test	dh, mask OLIER_TAB_STYLE	; check tab-style enum
	jnz	tabStyleItem
exit:
	.leave
	ret

	; Set the tab bits of the extra record & make sure this
	; item draws as a tool.
	;
tabStyleItem:
	andnf	ds:[di].OLII_extraRecord, not ((mask OLIER_3D_TAB) or \
					       (mask OLIER_TAB_STYLE))
	ornf	ds:[di].OLII_extraRecord, dh	 ; set tab bits
	ornf	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jmp	exit

CheckIfTabItem	endp
endif		; if ALLOW_TAB_ITEMS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds the visible object

CALLED BY:	MSG_SPEC_BUILD

PASS:		*ds:si 	- instance data
		es     	- segment of OLItemClass
		ax 	- MSG_SPEC_BUILD
		ds	- pointing to an object block or other local memory
			block or a core block (the important part: ds:0 must
			be the handle of the block)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	7/89	Initial version
	Eric	3/90		cleanup, navigation & multiple select work
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemSpecBuild	method private static OLItemClass, MSG_SPEC_BUILD
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

EC <	push	ax, cx, dx, bp, di, es					>
EC < 	call	CheckIfBoolean						>
EC <	jc	ecIsBoolean						>
EC <	mov	cx, segment GenItemGroupClass				>
EC <	mov	dx, offset GenItemGroupClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	GenCallParent						>
EC <	ERROR_NC	OL_ERROR_ITEM_NOT_CHILD_OF_ITEM_GROUP		>
EC <	jmp	short ecDone						>
EC <ecIsBoolean:							>
EC <	mov	cx, segment GenBooleanGroupClass			>
EC <	mov	dx, offset GenBooleanGroupClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	GenCallParent						>
EC <	ERROR_NC	OL_ERROR_BOOLEAN_NOT_CHILD_OF_BOOLEAN_GROUP	>
EC <ecDone:								>
EC <	pop	ax, cx, dx, bp, di, es					>

	;do superclass init

	mov	di, segment OLItemClass
	mov	es, di
	mov	di, offset OLItemClass
	CallSuper	MSG_SPEC_BUILD

	;
	; Check to see if we're in a menu, and set an optimization flag if so.
	;
	push	si
	call	SwapLockOLWin
	jnc	10$
if _RUDY
	;
	; if in bubble, expand to fit parent
	;
	mov	al, 0			;assume not in bubble
	push	es
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass
	pop	es
	jnc	haveBubbleResult	;not in bubble
	call	Build_DerefVisSpecDI
	mov	al, ds:[di].OLPWI_flags
haveBubbleResult:
endif
	call	Build_DerefVisSpecDI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	call	ObjSwapUnlock
	jz	10$			;not in menu, branch (carry clear)
	stc				;set carry if in menu
10$:
	pop	si
	jnc	notInMenu		;skip if not in menu...

	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	ornf	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT
RUDY <	jmp	short afterMenu						>
	
notInMenu:

if _RUDY
	;
	; Rudy -- all non-menu items are toolbox style.
	;
	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
afterMenu:
	test	al, mask OLPWF_IS_POPUP
	jz	notInPopup
	call	Build_DerefVisSpecDI
	andnf	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
	ornf	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT
notInPopup:
endif

	;
	; Get the state for this item from the parent, in order to initialize
	; the selected and indeterminate state of the item.
	;
	call	Build_DerefGenDI
	mov	cx, ds:[di].GII_identifier
	mov	ax, MSG_OL_IGROUP_GET_ITEM_STATE
	call	GenCallParent			;returns OLIS_SELECTED, etc.
EC <	test	al, not (mask OLIS_SELECTED or mask OLIS_INDETERMINATE)   >
EC <	ERROR_NZ	OL_ERROR		;bad flags returned!	  >
	call	Build_DerefVisSpecDI
	andnf	ds:[di].OLII_state, not (mask OLIS_SELECTED or \
					 mask OLIS_INDETERMINATE)
	ornf	ds:[di].OLII_state, al

	;
	; If the item is in a toolbox, let's set the OLIS_DRAW_AS_TOOLBOX
	; flag.
	;
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	80$
	ornf	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
80$:
	;
	; If this item is coming up as the selection, let's update the
	; item group's popup list moniker, if there is any.
	;
	tst	al
	jz	90$			;not selected, branch
	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
	je	90$			;skip if non-exclusive...
	mov	ax, MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER
	call	VisCallParent
90$:
	;
	; I think this is a good idea
	;
	CallMod	OLItemUpdateDrawState	;trashes ax, bx, cx, dx, bp
EC <	call	ECScrollableItemCompField				>

	.leave
	ret
OLItemSpecBuild	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemSpecNotifyNotEnabled -- MSG_SPEC_NOTIFY_NOT_ENABLED

DESCRIPTION:	Checks if the state bit is set for this child.  If it is
		and the list is not nonexclusive, then it will make this entry
		the current or user exclusive, depending on what is set.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/7/90		Initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemSpecNotifyNotEnabled	method	OLItemClass, \
						MSG_SPEC_NOTIFY_NOT_ENABLED

	;FIRST call superclass, to reset the VA_FULLY_ENABLED flag in our
	;Vis instance data. BUT we must skip the OLButtonClass handler,
	;as it will screw up FOCUS handling.

	mov	di, offset OLButtonClass ;THIS IS CORRECT!
	mov	ax, MSG_SPEC_NOTIFY_NOT_ENABLED
	call	MSG_SPEC_NOTIFY_NOT_ENABLED, super OLButtonClass

	;send a method to the GenList, so it can update accordingly.
	;This involves moving FOCUS exclusive off of this object, and scrolling
	;the list if this is a scrolling list item.

	call	Build_DerefVisSpecDI
	mov	bp, {word} ds:[di].OLII_state
	and	bp, mask OLIS_NAVIGATE_IF_DISABLED or \
		    mask OLIS_NAVIGATE_BACKWARD
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_ENABLED
	call	OLItemNotifyList

	;release mouse and default exclusives.  kbd exclusive should have been
	;taken care of by the notification above.

	call	OLButtonReleaseMouseGrab	
	call	OLButtonReleaseDefaultExclusive
	ret
OLItemSpecNotifyNotEnabled	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemSetUsable -- 
		MSG_SPEC_SET_USABLE for OLItemClass

DESCRIPTION:	Checks if the state bit is set for this child.  If it is
		and the list is not nonexclusive, then it will make this entry
		the current or user exclusive, depending on what is set.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SET_USABLE
		dl	- VisUpdateMode

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/14/89	Initial version
	Eric	6/90	updated to handle both class levels fully.
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemSetUsable	method	dynamic OLItemClass, \
						MSG_SPEC_SET_USABLE

	mov	di, offset OLItemClass
	CallSuper MSG_SPEC_SET_USABLE

	;send a method to the GenList, so it can update accordingly.
	;This includes moving the USER, ACTUAL, and FOCUS exclusives onto
	;this object if it's the selection.  We need to do this after calling 
	;superclass so that we're in the visible tree by the time our parent 
	;receive the message, and hence will be able to get the focus.  
	;-cbh 3/ 3/92

	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_SET_USABLE
	call	OLItemNotifyList
	ret
OLItemSetUsable	endp


OLItemNotifyEnabled	method	dynamic OLItemClass, \
						MSG_SPEC_NOTIFY_ENABLED

	;
	; Code added to avoid doing stuff if we're in a menu and not yet
	; realized.  The intent is to avoid doing extra work in popup lists.
	; Hopefully it will only do good things to items in menus as well.
	; The superclass stuff (redrawing, checking for master default) 
	; shouldn't be needed unless visible.  -cbh 2/22/93
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	doStuff				;not in menu continue
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	doStuff				;realized, be normal

	mov	di, offset OLButtonClass
	call	MSG_SPEC_NOTIFY_ENABLED, super OLButtonClass
	ret

doStuff:
	mov	di, offset OLItemClass
	CallSuper MSG_SPEC_NOTIFY_ENABLED

	;send a method to the GenList, so it can update accordingly.
	;This includes moving the USER, ACTUAL, and FOCUS exclusives onto
	;this object if it's the selection.  We need to do this after calling 
	;superclass so that we're in the visible tree by the time our parent 
	;receive the message, and hence will be able to get the focus.  
	;-cbh 3/ 3/92

	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_SET_USABLE
	call	OLItemNotifyList
exit:
	ret
OLItemNotifyEnabled	endp

Build	ends


ActionObscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemSetNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent out when a MSG_GEN_SET_NOT_USABLE is sent to an
		object.  This will be used to remove the item visually as
		well as actually perform any needed specific-UI behavior.
		If this is an exclusive list, it will check if you're 
		removing one of the exclusives.  If so, then it sets a new one.
		If it's a nonexclusive or exclusive-none list, you don't
		need to do this.

CALLED BY:	MSG_SPEC_SET_NOT_USABLE

PASS:		ax	- MSG_SPEC_SET_NOT_USABLE
		ds:*si	- segment, little mem handle of instance data
		es	- segment of Class
		dl	- VisUpdateMode

RETURN:		nothing

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	11/89	Initial version
	Eric	6/90	updated to handle both class levels fully.
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLItemSetNotUsable	method	dynamic OLItemClass, \
						MSG_SPEC_SET_NOT_USABLE

	;if our moniker is invalid, send a message to the list to bump down
	;its non-interactable count, since this item won't be around anymore.
 	; 6/7/93 cbh
	;
	test	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
	jz	10$

	push	dx
	call	GetItemPosition			;returns position in dx
	mov	cx, si				;pass non-zero, pretend item is
						;  now interactable so it won't
						;  be counted now that it's gone
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_CHANGED_INTERACTABLE_STATE
	call	OLItemNotifyList
	pop	dx
10$:

	;send a method to the GenList, so it can update accordingly.
	;This includes moving the USER, ACTUAL, and FOCUS exclusives off
	;of this object, and scrolling the list if this is a
	;scrolling list item.

	push	dx
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_SET_NOT_USABLE
	call	OLItemNotifyList
	pop	dx

	;call superclass (es = segment of class)

	mov	ax, MSG_SPEC_SET_NOT_USABLE
	mov	di, offset OLItemClass
	CallSuper MSG_SPEC_SET_NOT_USABLE
	ret
OLItemSetNotUsable	endp

ActionObscure	ends


Build	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLItemNotifyList

SYNOPSIS:	Notifies parent, via queue, of change in state of the item.

CALLED BY:	OLItemSetEnabled, OLItemSetNotEnabled, OLItemSetUsable

PASS:		*ds:si -- item
		cx -- message to send to parent item group
		di -- message flags to use

RETURN:		nothing

DESTROYED:	cx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/24/92		Initial version

------------------------------------------------------------------------------@
OLItemNotifyList	proc	far
	uses	ax, dx
	.enter
	;
	; send a method to the GenList, so it can update accordingly.
	; This includes moving the USER, ACTUAL, and FOCUS exclusives off
	; of this object, and scrolling the list if this is a
	; scrolling list item.  
	;
	mov	cx, ds:[LMBH_handle]	;pass ^lcx:dx = this item
	mov	dx, si
	call	GenCallParent
	.leave
	ret
OLItemNotifyList	endp

Build ends

Geometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemRerecalcSize -- MSG_VIS_RECALC_SIZE for OLItemClass

DESCRIPTION:	Returns the size of the item.

PASS:		*ds:si	- instance data
		es	- segment of OLItemClass
		ax 	- method number
		cx	- RerecalcSizeArgs: width info for choosing size
		dx	- RerecalcSizeArgs: height info

RETURN:		cx - width to use
		dx - height to use

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@
OLItemRerecalcSize	method dynamic OLItemClass, MSG_VIS_RECALC_SIZE

	CallMod	VisApplySizeHints		;deal with any size hints
	call	CalcSizeWithoutHints		;do size calculations
	CallMod	VisApplySizeHints		;apply them again

	ret
OLItemRerecalcSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcSizeWithoutHints

SYNOPSIS:	Calculates a size, disregarding hints.

CALLED BY:	OLItemRerecalcSize, OLItemGetExtraSize

PASS:		cx, dx -- desired size

RETURN:		cx, dx -- calculated size

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/21/92		Initial version

------------------------------------------------------------------------------@
CalcSizeWithoutHints	proc	near
	uses	bx, di, es		
	.enter				
EC <	call	GenCheckGenAssumption		;make sure gen data exists >

	push	cx, dx				;save passed args	
	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	call	OLItemSetupMkrArgs		;set up arguments for moniker
	call	OpenGetMonikerSize		;get size of moniker
if _PCV
	; adjust size according to PCV look
	push	ax, di, bx
	push	cx, dx, bp

	; first ask our vis parent, the ItemGroup, if it has a graphic
	; moniker or not
	mov	dx, size GetVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GVDP_bufferSize, 0
	mov	ss:[bp].GVDP_dataType, HINT_USE_COMPRESSED_INSETS_FOR_MONIKER
	mov	ax, MSG_META_GET_VAR_DATA
	call	VisCallParent
	add	sp, size GetVarDataParams
	cmp	ax, -1
	pop	cx, dx, bp
	; ax != 1 means it has a graphic, so no adjustment needed
	jne	afterAdjust

	; ok, it has a graphic, so now lets get the specific look and do
	; the right thing
	mov	ax, MSG_SPEC_GET_LEGOS_LOOK
	push	cx, dx, bp
	call	VisCallParent
	mov_tr	ax, cx
	pop	cx, dx, bp
	cmp	ax, 3 ; UPPER_TAB
	je	adjustTab
	cmp	ax, 4 ; LOWER_TAB
	jne	afterAdjust
adjustTab:
	; tab looks need to be a little bigger than the moniker, so adjust
	; the value manually here
	add	cx, 2
	add	dx, 2
afterAdjust:
	pop	ax, di, bx
endif

EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>
	add	sp, size OpenMonikerArgs	;dump args

if _CUA_STYLE	;---------------------------------------------------------------
	call	Geo_DerefVisDI
	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jnz	10$

if _ODIE
	; The Odie check box is bigger than the Odie radio button (the
	; reverse of standard Motif) so allow enough room for the 
	; check box. -lester, 26 July 96
	cmp	dx, CHECK_HEIGHT+(MO_ITEM_INSET_Y*2)
	jg	10$				; Enough room for check box?
						; Allow for check box
	mov	dx, CHECK_HEIGHT+(MO_ITEM_INSET_Y*2)
else
	cmp	dx, RADIO_HEIGHT+(MO_ITEM_INSET_Y*2)
	jg	10$				; Enough room for radio button?
						; Allow for radio button
	mov	dx, RADIO_HEIGHT+(MO_ITEM_INSET_Y*2)
endif
10$:

	; Put inside of _CUA_STYLE in _STYLUS is _CUA_SYTLE, and here
	; we are guarenteed that ds:di = VisInstance.
	
if	 _ADDITIONAL_VERTICAL_SPACE_IN_MENUS
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	dontAddVerticalSpace		; Not in menu.. skip it.
	add	dx, _HEIGHT_OF_ADDITIONAL_VERTICAL_SPACE_IN_MENUS

dontAddVerticalSpace:
endif	;_ADDITIONAL_VERTICAL_SPACE_IN_MENUS

endif		;---------------------------------------------------------------

	pop	ax, bx				;restore passed args
	push	cx				;clear bp high now 7/20/94 cbh
	clr	cx
	mov	cl, ds:[di].OLBI_moreAttrs
	mov	bp, cx
	pop	cx
	call	OpenChooseNewGadgetSize

	;
	; not a hack!  Return title bar height if this button is in title bar
	;
	push	bx
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData
	pop	bx
	jnc	notInTitleBar
if _JEDIMOTIF
	;
	; title bar objects in JEDI are 16 pixel high
	;
	mov	dx, 16
else
	push	cx			; save width
	mov	ax, MSG_OL_WIN_GET_TITLE_BAR_HEIGHT
	call	CallOLWin		; dx = height
	pop	cx			; restore width
endif
notInTitleBar:

	.leave
	ret
CalcSizeWithoutHints	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLItemClass

DESCRIPTION:	Returns size without the moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx - size without moniker

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@

OLItemGetExtraSize	method OLItemClass, MSG_SPEC_GET_EXTRA_SIZE
	clr	cx, dx				;get the minimum size
	call	CalcSizeWithoutHints		;returns size in cx, dx
	mov_tr	ax, cx				;save in ax, bx
	mov	bx, dx
	
	clr	bp				;no gstate
	call	SpecGetGenMonikerSize		;get size of just the moniker
	sub	ax, cx				;subtract from overall size
	sub	bx, dx
	tst	ax
	jns	10$
	clr	ax				;hopefully this won't be needed
10$:
	tst	bx
	jns	20$
	clr	bx				;hopefully this won't be needed
20$:
	movdw	cxdx, axbx			;and return in cx, dx

	ret
OLItemGetExtraSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLItemClass

DESCRIPTION:	Returns the position of the item's moniker.

PASS:		*ds:si - instance data
		es - segment of OLItemClass
		ax - MSG_GET_FIRST_MKR_POS
		
RETURN:		carry set (method handled) if there's a moniker
		ax, cx -- position of the moniker

DESTROYED:	dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89	Initial version

------------------------------------------------------------------------------@
OLItemMkrPos	method	OLItemClass, MSG_GET_FIRST_MKR_POS

	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	call	OLItemSetupMkrArgs		;set up arguments for moniker
	call	OpenGetMonikerPos		;get position of moniker

if _MOTIF or _PM
	;
	; It appears that the x offset is bogus at this point (or, rather, not
	; really representing reality for some reason :), so let's stuff
	; the correct thing in for these purposes.  -cbh 11/16/92
	;
	call	Geo_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	20$
	mov	ax, ds:[di].VI_bounds.R_left	;get left edge
	add	ax, CHECK_BOX_WIDTH		;<256.  I guarantee it.
	test	ds:[di].OLII_state, mask OLIS_DRAW_AS_TOOLBOX
	jz	20$
	add	ax, TOOLBOX_INSET_X		;only a byte, anyway.
20$:
endif

EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>
	add	sp, size OpenMonikerArgs	;dump args
	mov	cx, bx				;return y pos in cx
	tst	ax
	jz	exit				;no moniker, exit (c=0)
	stc					;method handled
exit:
	ret
OLItemMkrPos	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGetCenter --
		MSG_VIS_GET_CENTER for OLItemClass

DESCRIPTION:	Returns center of a item.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_CENTER

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 6/89		Initial version

------------------------------------------------------------------------------@

OLItemGetCenter	method OLItemClass, MSG_VIS_GET_CENTER

	sub	sp, size OpenMonikerArgs
	mov	bp, sp			;set up args on stack
	call	OLItemSetupMkrArgs	;set up arguments for moniker
	call	OpenGetMonikerCenter	;get center of moniker (cx, dx)
	add	sp, size OpenMonikerArgs	;unload args

	ret
OLItemGetCenter	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemGetMenuCenter --
		MSG_SPEC_GET_MENU_CENTER for OLItemClass

DESCRIPTION:	Returns center of a setting.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_MENU_CENTER
		cx	- monikers space found, so far
		dx	- accel space found, so far
		bp	- non-zero if any items found so far are marked as 
				having valid geometry

RETURN:		cx, dx, bp - possibly updated

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/92		Initial version

------------------------------------------------------------------------------@
OLItemGetMenuCenter	method OLItemClass, MSG_SPEC_GET_MENU_CENTER

	push	bp
	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	push	cx, dx
	call	OLItemSetupMkrArgs		;set up arguments for moniker
	pop	cx, dx
	call	OpenGetMonikerMenuCenter	;get center of moniker (cx, dx)
	add	sp, size OpenMonikerArgs	;unload args
	pop	bp

	mov	di, ds:[si]			;geometry already invalid, exit
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	checkWrapping
	ornf	bp, mask SGMCF_NEED_TO_RESET_GEO ;else need to reset geometry
						 ; (previously a dec bp 1/18/93)

checkWrapping:
	;
	; Now see if whether ourselves or one of our children is allowing 
	; wrapping.  If so, clear the only-recalc-size flag.  -cbh 1/18/93
	;
	test	bp, mask SGMCF_ALLOWING_WRAPPING
	jz	exit
	andnf	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
	ornf	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT
exit: 
	ret
OLItemGetMenuCenter	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLItemUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLItemClass

DESCRIPTION:	Updates moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/10/92		Initial Version

------------------------------------------------------------------------------@
OLItemUpdateVisMoniker	method dynamic	OLItemClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER

	mov	di, offset OLItemClass
	CallSuper	MSG_SPEC_UPDATE_VIS_MONIKER

	call	Geo_DerefVisDI
	test	ds:[di].OLII_state, mask OLIS_SELECTED
	jz	exit				;we're not selected, exit
	cmp	ds:[di].OLII_behavior, GIGBT_NON_EXCLUSIVE
	je	exit			;skip if non-exclusive...

	mov	ax, MSG_OL_IGROUP_RESET_POPUP_LIST_MONIKER
	call	VisCallParent
exit:
	ret
OLItemUpdateVisMoniker	endm

Geometry ends


;-------------------


Resident 	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetItemsPosition

SYNOPSIS:	Returns item's position.

CALLED BY:	FAR

PASS:		*ds:si -- item

RETURN:		bp -- generic position of item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/21/93       	Initial version

------------------------------------------------------------------------------@
GetItemPosition	proc	far
	uses	ax, cx, bp
	.enter

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_FIND_CHILD
	call	GenCallParent
	mov	dx, bp

	.leave
	ret
GetItemPosition	endp


Resident	ends
