COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemScrollList.asm

ROUTINES:

 Name			Description
 ----			-----------

    INT AddGenericScrollers	Add a scroller to the view.

    INT ScrExpandWidth		Handles geometry hints for the scrolling
				list.

    INT ScrExpandHeight		Handles geometry hints for the scrolling
				list.

    INT ScrOrientHorizontally	Handles geometry hints for the scrolling
				list.

    INT ScrWrapCount		Handles geometry hints for the scrolling
				list.

    INT MakePopupScrollListIfNeeded 
				Makes a scroll list into a popup scroll
				list by creating a popup as a new parent of
				the scroll list.

    INT OLScrollListSetupViewOrientation 
				Sets up view orientation flag.

    INT OLScrollListHandleSizeHints 
				Handles geometry hints for scrolling list.

    INT OLScrollListSetupViewStuff 
				Handles view stuff for scrolling list.

    INT CopySizeToViewIfSpecified 
				Copies converted size hints to view if
				they're there.

    INT SetDefaultListSizeIfNeeded 
				Sets a default size for the list, if
				necessary.	 We need a default width or
				height if there wasn't anything specified
				in a corresponding hint, and the thing
				isn't expand-to-fit in that direction.
				We'll need to set a default numVisibleItems
				only if we're setting a default in the
				direction of orientation of the list.
				We'll set a default item length if one
				hasn't been set previously (via a size
				hint).

    INT SwapIfVertical		Sets a default size for the list, if
				necessary.	 We need a default width or
				height if there wasn't anything specified
				in a corresponding hint, and the thing
				isn't expand-to-fit in that direction.
				We'll need to set a default numVisibleItems
				only if we're setting a default in the
				direction of orientation of the list.
				We'll set a default item length if one
				hasn't been set previously (via a size
				hint).

    INT GetDefaultItemSize	Returns the default item size for this item
				group.

    INT MultByNumVisibleItems	Multiplies the passed size by the default
				number of items. Limits the size to some
				maximum amount.

    INT SIC_DerefVisDI		Ensures that an item is visible.

    INT SendTopItemChanged	Sends out a
				MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED so
				that monikers can be moved around, etc.

    INT SendUpdateCompleteIfAllItemsInteractable 
				Sends an update complete if we can.

    INT CalcTopItem		Returns item in upper-left corner.

    INT GetWrapCount		Returns wrap count in ax.

    INT MultByWrapCount		Multiplies passed value by the wrap count.

    INT GetMinItemSizes		Returns minimum item width and
				height.	Sinve we know this is done

    INT GetViewWinSize		Returns size of view window.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial revision

DESCRIPTION:

	$Id: citemScrollList.asm,v 1.1 97/04/07 10:55:20 newdeal Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLScrollListClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends



;-----------------------

SListBuild	segment	resource


SIB_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
SIB_DerefVisDI	endp

SIB_DerefVisSI	proc	near
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	ret
SIB_DerefVisSI	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListInitialize -- 
		MSG_META_INITIALIZE for OLScrollListClass

DESCRIPTION:	Initializes the scrolling item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/23/92		Initial Version

------------------------------------------------------------------------------@

OLScrollListInitialize	method dynamic	OLScrollListClass, \
				MSG_META_INITIALIZE
	; Set this flag in the item group.
	;
	ornf	ds:[di].OLIGI_state,  mask OLIGS_SCROLLABLE

	mov	di, offset OLScrollListClass
	CallSuper	MSG_META_INITIALIZE
	ret
OLScrollListInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListSpecBuildBranch -- 
		MSG_SPEC_BUILD_BRANCH for OLScrollListClass

DESCRIPTION:	Handles build for this object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD
		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 5/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListSpecBuildBranch  method dynamic	OLScrollListClass, \
			     MSG_SPEC_BUILD_BRANCH

;	call	VisSpecBuildSetEnabledState	; make sure this happens.

	;
	; The first order of business is to place ourselves in a view.
	; We do this in SPEC_BUILD_BRANCH so that we can build out our children
	; before doing the SPEC_SCAN_GEOMETRY_HINTS.
	;
	push	bp
	mov	di, segment GenViewClass
	mov	es, di
	mov	di, offset GenViewClass
	call	OpenCreateNewParentObject	;view in di


	mov	bx, ds:[si]			; ds:bx = list instance
	add	bx, ds:[bx].Vis_offset
	mov	ds:[bx].OLSLI_view, di		;save view handle

if _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR
	;
	;  For some specific UIs we need to be able to detect
	;  when a scroller is actually scrolling a list.
	;
	call	AddGenericScrollers
	;
	; re-deref ds:bx
	;
	mov	bx, ds:[si]			; ds:bx = list instance
	add	bx, ds:[bx].Vis_offset
endif
	;
	; While we're here, we'll avoid drawing our moniker (the view will do
	; this).
	;
	andnf	ds:[bx].OLCI_optFlags, not mask OLCOF_DISPLAY_MONIKER

	;
	; Set ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL in view if a dynamic list.
	;
	test	ds:[bx].OLIGI_state, mask OLIGS_DYNAMIC
	jz	notDynamic
	xchg	si, di				; view in *ds:si
	mov	ax, ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL
	clr	cx
	call	ObjVarAddData

	xchg	si, di				; view in *ds:di
notDynamic:
	;
	; Have the view follow the content's size, in case we need to go on
	; the widths of the items (the default behavior).
	;
	mov	bx, ds:[di]			
	add	bx, ds:[bx].Gen_offset
if ITEM_USES_BACKGROUND_COLOR
	;
	; enable color to be set below
	;
	ornf	ds:[bx].GVI_attrs, mask GVA_GENERIC_CONTENTS or \
				   mask GVA_SEND_ALL_KBD_CHARS or \
				   mask GVA_DRAG_SCROLLING or \
				   mask GVA_TRACK_SCROLLING
else
	ornf	ds:[bx].GVI_attrs, mask GVA_GENERIC_CONTENTS or \
				   mask GVA_SAME_COLOR_AS_PARENT_WIN or \
				   mask GVA_SEND_ALL_KBD_CHARS or \
				   mask GVA_DRAG_SCROLLING or \
				   mask GVA_TRACK_SCROLLING
endif

if ITEM_USES_BACKGROUND_COLOR
	;
	; The wash color for the view should be the custom background color
	; of the list, or the wash color of the list, using its generic parent
	; (its vis parent will be a content under the view)
	;	*ds:si = list
	;	ds:bx = view gen instance
	;
	clr	ax				; get unselected color
	mov	{word} ds:[bx].GVI_color.CQ_green, ax
	call	OpenGetBackgroundColor		; al = main color
	jc	gotColor
	call	OpenGetWashColorsFromGenParent	; al = main color
gotColor:
	clr	ah
	mov	{word} ds:[bx].GVI_color.CQ_redOrIndex, ax
endif

;	On no-kbd systems, we can't do navigation or mnemonics, so don't make
;	the view focusable - this will keep the floating kbd from coming
;	up automatically.

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_NO_KEYBOARD
	jz	haveKbd
	andnf	ds:[bx].GVI_attrs, not mask GVA_FOCUSABLE

haveKbd:

;	If we (possibly) have a physical keyboard, but want a floating
;	keyboard to be available as well, then add an attr to the view that
;	tells it not to force the keyboard on-screen when it gets the
;	focus, as there is nothing in the floating keyboard that should
;	be able to interact with the view.

	call	CheckIfKeyboardRequired
	jnc	noKbdRequired

	xchg	si, di
	mov	ax, ATTR_GEN_VIEW_DOES_NOT_ACCEPT_TEXT_INPUT or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData

	xchg	si, di
noKbdRequired:

	pop	ax				;restore build flags
	push	ax				;save them again
	mov	bl, 0ffh			;set view flag
	call	OpenBuildNewParentObject	;build a view, place us 
						;   underneath
	pop	bp				;restore build flags


	mov_tr	di, ax				;si = scrollList, di = view 
	call	MakePopupScrollListIfNeeded


	;
	; Call superclass to build out the children.
	;
	mov	di, segment OLScrollListClass
	mov	es, di
	mov	di, offset OLScrollListClass
	mov	ax, MSG_SPEC_BUILD_BRANCH
	CallSuper	MSG_SPEC_BUILD_BRANCH

	;
	; Scan geometry stuff after we've built our children.
	;
	GOTO	OLScrollListScanGeometryHints

OLScrollListSpecBuildBranch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyComplexMonikerInfoIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a destination object to use the complex
		moniker info of a source object.

CALLED BY:	OLScrollListSpecBuildBranch,
		MakePopupScrollListIfNeeded
			(actually, not needed to be called from there,
			 as long as unbuilding & rebuilding the
			 view doesn't wipe out the work we did from
			 OLScrollListSpecBuildBranch)

PASS:		*ds:si = Source ComplexMoniker object
		*ds:di = Object to inherit the complex moniker
			(should already be built)

RETURN:		ds pointing to same object block
DESTROYED:	nothing
SIDE EFFECTS:	LMem blocks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGenericScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a scroller to the view.

CALLED BY:	OLScrollListSpecBuildBranch

PASS:		*ds:di = view

RETURN:		nothing
DESTROYED:	nothing (ds may have moved)

PSEUDO CODE/STRATEGY:

	Add two generic scrollers to the view.  This is done
	because

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/ 2/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR
AddGenericScrollers	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Create the Y scroller.
	;
		push	di				; save view
		mov	bx, ds:[LMBH_handle]
		mov	di, segment GenValueClass
		mov	es, di
		mov	di, offset GenValueClass
		call	ObjInstantiate			; *ds:si = object
	;
	;  Give it the hint to make it a Y scroller.
	;
		mov	ax, HINT_VALUE_Y_SCROLLER
		clr	cx
		call	ObjVarAddData

		mov	ax, HINT_SEEK_RIGHT_OF_VIEW
		call	ObjVarAddData

		mov	ax, HINT_VALUE_ITEM_GROUP_GADGET
		call	ObjVarAddData
	;
	;  Add it to the view.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = scroller
		pop	si				; *ds:si = view
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_LAST
		call	ObjCallInstanceNoLock		; cx, dx unchanged
	;
	;  Set it usable.
	;
		mov	si, dx				; *ds:si = scroller
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		.leave
		ret
AddGenericScrollers	endp

endif		; _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListSpecBuild -- 
		MSG_SPEC_BUILD for OLScrollListClass

DESCRIPTION:	Builds the scroll list.  We do nothing here because we don't
		need any superclass behavior (we hope), and the necessary
		stuff we do need is handled in the MSG_SPEC_BUILD_BRANCH
		handler.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/11/92		Initial Version

------------------------------------------------------------------------------@

OLScrollListSpecBuild	method dynamic	OLScrollListClass, \
				MSG_SPEC_BUILD
	call	VisSpecBuildSetEnabledState ; set state based on SpecBuildFlags
	call	InitFocusItem		    ; moved here from OLItemGroupInit-
					    ;   ialize -10/20/92
	ret
OLScrollListSpecBuild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLScrollListClass

DESCRIPTION:	Handles geometry hints for the scrolling list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 9/92		Initial Version

------------------------------------------------------------------------------@

ScrollListScanArgs record
	SLSA_WIDTH_HINT_SPECIFIED:1
	SLSA_HEIGHT_HINT_SPECIFIED:1
	SLSA_INIT_WIDTH_HINT_SPECIFIED:1
	SLSA_INIT_HEIGHT_HINT_SPECIFIED:1
	SLSA_ENSURE_HINT_IS_NUKED_IN_VIEW:1
	SLSA_ITEM_LENGTH_CALCULATED:1
ScrollListScanArgs end

OLScrollListScanGeometryHints	method static OLScrollListClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS

	desiredSize		local	SpecSizeArgs
	uses	bx, di, es		; To comply w/static call requirements
					; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLScrollListClass
	mov	es, di
	.enter

	;
	; Clear the size-hints flag in case it's set.  We need to ensure that
	; we can extract any new geometry hints, and we set this after running
	; through this routine once.
	;
	call	SIB_DerefVisDI
	andnf	ds:[di].VI_geoAttrs,  not mask VGA_NO_SIZE_HINTS
	;
	; First, assume vertical.  Also, we can figure on doing one pass.
	; Finally, we can assume the thing should always expand to the content,
	; which is useful for dynamic lists where the children may or may not
	; fit.  (Expanding is now done via a subclassed MSG_VIS_RECALC_SIZE
	; handler, to avoid expand-while-wrapping fatal errors.)
	;
	mov	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY or \
				      mask VCGA_ONE_PASS_OPTIMIZATION
;	mov	ds:[di].VCI_geoDimensionAttrs, \
;			              mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
;			              mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT 
			
	;
	; Initialize ScrollListScanArgs to nuke any hints in the view if the
	; corresponding hint doesn't exist here.  We'll add flags as geometry
	; hints are encountered, to keep track of how much default stuff we
	; need to set up at the end.   (Hint scanning moved from below Vis-
	; SetupSizeArgs, so we can get the orientation of this thing before
	; dealing with size hints.  12/10/92 cbh)
	;
	mov	bl, mask SLSA_ENSURE_HINT_IS_NUKED_IN_VIEW
	;
	; Handle any other geometry hints that might be around, which may also
	; affect if default sizes are needed.
	;	bl -- ScrollListScanArgs
	;	ss:bp -- desiredSize
	;
	mov	cx, bx				;flags to cl
	segmov	es, cs, di
	mov	di, offset cs:OLFSHintHandlers
	mov	ax, length (cs:OLFSHintHandlers)
	call	ObjVarScanData			;cl = ScrollListScanArgs
	mov	bx, cx				;flags back in bl

	;
	; Now send any size hints to the view, after working out the pixel
	; values here.
	;
	call	VisSetupSizeArgs		;get hint arguments, converted,
						;  in local var desiredSize.

	call	OLScrollListSetupViewOrientation ;setup scrollbar direction
	call	OLScrollListHandleSizeHints	 ;handle any size hints
	;
	; If we haven't encountered any geometry hints, we'll need to set up
	; a default size for the list.
	;	bl -- ScrollListScanArgs
	;	ss:bp -- desiredSize
	;
	call	SetDefaultListSizeIfNeeded	

	;
	; While we're here, set this so that (hopefully) size hints will be 
	; ignored at this level from now on.
	;
	call	SIB_DerefVisDI
	ornf	ds:[di].VI_geoAttrs,  mask VGA_NO_SIZE_HINTS

	call	OLScrollListSetupViewStuff	;setup increment, orientation

	;
	; Set some geometry stuff that we forgot.  -11/20/92 cbh
	;
	call	SIB_DerefVisDI
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS

	.leave
	ret
OLScrollListScanGeometryHints	endm



OLFSHintHandlers	VarDataHandler \
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, offset ScrExpandWidth>,
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, offset ScrExpandHeight>,
	<HINT_ORIENT_CHILDREN_HORIZONTALLY, offset ScrOrientHorizontally>,
	<HINT_WRAP_AFTER_CHILD_COUNT, offset ScrWrapCount>


ScrExpandWidth	proc	far		;cx -- ScrollListScanArgs
	;
	; Set that a geometry hint is specified for the width.   This effect-
	; ively keeps a default width from being set in the view.  The item
	; length will still need to be set from the default if no size hint
	; is specified.
	;
	ornf	cl, mask SLSA_WIDTH_HINT_SPECIFIED
	ret
ScrExpandWidth	endp

ScrExpandHeight	proc	far		;cx -- ScrollListScanArgs
	;
	; Set that a geometry hint is specified for the width.   This effect-
	; ively keeps a default height from being set in the view. The item
	; length will still need to be set from the default if no size hint
	; is specified.
	;
	ornf	cl, mask SLSA_HEIGHT_HINT_SPECIFIED
	ret
ScrExpandHeight	endp

ScrOrientHorizontally	proc	far		;cx -- ScrollListScanArgs
	;
	; Set flag to orient the children horizontally.  Various things
	; may have to be done differently in this instance...
	;
	call	SIB_DerefVisDI
	andnf	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY
	ret
ScrOrientHorizontally	endp

ScrWrapCount		proc	far		
	;
	; Set this flag so the geometry manager will know to wrap children
	; a certain way.  We'll use it as well to see whether there's a wrap
	; count to look up.
	;
	call	SIB_DerefVisDI
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT or \
				      mask VCGA_ALLOW_CHILDREN_TO_WRAP
	andnf	ds:[di].VCI_geoAttrs, not mask VCGA_ONE_PASS_OPTIMIZATION
	ret
ScrWrapCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakePopupScrollListIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a scroll list into a popup scroll list by creating a
		popup as a new parent of the scroll list.

CALLED BY:	OLScrollListSpecBuildBranch

PASS:		*ds:si 	- instance data of scroll list
		*ds:di	- instance data of view
		es     	- segment of MetaClass
		bp	- SpecBuildFlags
		
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakePopupScrollListIfNeeded	proc	near
	uses	si, di, bp
	.enter

	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
	call	ObjVarFindData
	jc	makePopup			;found, handle
	call	OpenCheckIfVerticalScreen	;vertical screen?
	LONG jnc	done				;no, done
						;else, check if vertical screen
						;	hint
	mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE_IF_VERTICAL_SCREEN
	call	ObjVarFindData
	LONG jnc	done				;not found, done
makePopup:
	;
	; Unbuild the stuff that was built that was built while making the
	; view the new parent of the scrollable list.
	;
	push	si, di, bp
	mov	si, di				;*ds:si = view
	mov	ax, MSG_SPEC_UNBUILD
	call	ObjCallInstanceNoLock

	;
	; Create a popup, and make it the new parent of the view
	;
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass	;create GenInteraction
	mov	bx, ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty	;parent popup in *ds:si
	mov	bx, offset Gen_offset
	call	ObjInitializePart

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GII_visibility, GIV_POPUP

	mov	ax, HINT_IS_POPUP_LIST		;make sure added at this spot
	clr	cx				;no extra data
	call	ObjVarAddData

	mov	di, si				;*ds:di <- popup
	pop	si, ax				;*ds:si <- view
						;ax <- build flags
	clr	bx				;not creating a view
	call	OpenBuildNewParentObject	;build a popup, place us
						; underneath
	pop	si				;*ds:si <- scroll list

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST


if not POPUPS_ALWAYS_DISPLAY_CURRENT_SELECTION
	mov	ax, HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION
	call	ObjVarFindData
	jnc	done				;not found, exit
endif
	ornf	ds:[di].OLIGI_moreState, mask OLIGMS_DISPLAYS_CURRENT_SELECTION
done:
	.leave
	ret
MakePopupScrollListIfNeeded	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	OLScrollListSetupViewOrientation

SYNOPSIS:	Sets up view orientation flag.

CALLED BY:	OLScrollListScanGeometryHints

PASS:		*ds:si -- scrolling list

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@
OLScrollListSetupViewOrientation	proc	near
	;
	; At this point, we've determined our child orientation from any hints
	; specified, and whether there's a wrap count.  We'll set the scrollbar
	; orientation based on this.  The scrollbar orientation matches the
	; child orientation unless there's a wrap count.
	;
	call	SIB_DerefVisDI
	mov	al, mask OLSLA_VERTICAL		;assume vertical
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	10$				;vertical, branch
	clr	al				;else set horizontal
10$:
	test	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT
	jz	20$				;no wrapping, branch
	xor	al, mask OLSLA_VERTICAL		;else flip the vertical bit
20$:
	andnf	ds:[di].OLSLI_attrs, not mask OLSLA_VERTICAL
	ornf	ds:[di].OLSLI_attrs, al		;store the flag
	ret
OLScrollListSetupViewOrientation	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLScrollListHandleSizeHints

SYNOPSIS:	Handles geometry hints for scrolling list.

CALLED BY:	OLScrollListScanGeometryHints

PASS:		*ds:si -- scrolling list
		bl -- ScrollListScanArgs
		ss:bp -- desired size

RETURN:		bl -- ScrollListScanArgs, possibly updated

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@
OLScrollListHandleSizeHints	proc	near
	class	OLScrollListClass
	desiredSize		local	SpecSizeArgs
	.enter	inherit
	;
	; First, we need to do some fixup for the benefit of the view, which
	; by default will expand to fit.   If the scrolling list is not going
	; to be expanding to fit in a given direction, and an initial size is
	; specified in that direction, we need to make it a fixed size instead.
	; -cbh 10/27/92   (Copy over the number of children, regardless of the
	; expand-to-fit situation, in case it's needed.  It won't get used if
	; the other stuff is filled in, anyway.  -cbh 11/ 3/92)
	;
	test	bl, mask SLSA_WIDTH_HINT_SPECIFIED
	jnz	10$				;Width hint specified, we're
						; expand-to-fit. Skip.
	tst	desiredSize.SSA_fixedWidth	;fixed width specified?
	jnz	10$				;yes, branch
	mov	ax, desiredSize.SSA_initWidth	;else copy over init width, if
	mov	desiredSize.SSA_fixedWidth,ax	;  there's any at all
10$:
	test	bl, mask SLSA_HEIGHT_HINT_SPECIFIED
	jnz	20$				;Height hint specified, we're
						; expand-to-fit. Skip.
	tst	desiredSize.SSA_fixedHeight	;fixed height specified?
	jnz	20$				;yes, branch
	mov	ax, desiredSize.SSA_initHeight	;else copy over init height, if
	mov	desiredSize.SSA_fixedHeight,ax	;  there's any at all
20$:
	tst	desiredSize.SSA_fixedNumChildren    ;fixed height specified?
	jnz	30$				    ;yes, branch
	mov	ax, desiredSize.SSA_initNumChildren ;else copy over init count
	mov	desiredSize.SSA_fixedNumChildren,ax ;  if there's any at all
30$:
	;
	; For each HINT_FIXED_SIZE or whatever, set a corresponding hint in 
	; the view, converting beforehand to pixels to account for list
	; entry extra sizes.
	;
	mov	ax, MSG_GEN_SET_FIXED_SIZE	;what to call 
	mov	di, offset SSA_fixedWidth	
	call	CopySizeToViewIfSpecified

	mov	ax, MSG_GEN_SET_MINIMUM_SIZE	;what to call 
	mov	di, offset SSA_minWidth
	call	CopySizeToViewIfSpecified

	mov	ax, MSG_GEN_SET_MAXIMUM_SIZE	;what to call 
	mov	di, offset SSA_maxWidth
	call	CopySizeToViewIfSpecified

	mov	ax, MSG_GEN_SET_INITIAL_SIZE	;what to call 
	mov	di, offset SSA_initWidth
	call	CopySizeToViewIfSpecified

	.leave
	ret
OLScrollListHandleSizeHints	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLScrollListSetupViewStuff

SYNOPSIS:	Handles view stuff for scrolling list.

CALLED BY:	OLScrollListScanGeometryHints

PASS:		*ds:si -- scrolling list
		ss:bp -- desired size

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@
OLScrollListSetupViewStuff	proc	near
	uses	si
	class	OLScrollListClass
	desiredSize		local	SpecSizeArgs
	.enter	inherit
	;
	; Set the content's width to follow the view.  If horizontal, we'll
	; set the height to follow the view.  If dynamic, we'll have both
	; directions follow the view.
	;
	push	bp				;save stack pointer
	mov	cl, mask VCNA_SAME_WIDTH_AS_VIEW
						;cl <- VCNI_attrs to set
	clr	dx				;dl <- OLCI_attrs to set
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	pushf					;save vertical flag
	jnz	60$				;vertical, branch
	mov	cl, mask VCNA_SAME_HEIGHT_AS_VIEW
60$:
	;
	; If dynamic, we'll have both directions follow the view.  We'll
	; also keep a minimum height based on the number of items.   We also
	; will go to a large document model in this case, since the dynamic
	; list will get very LONG (and also won't be based on the height of
	; the list).
	;
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	65$
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	mov	cl, mask VCNA_SAME_WIDTH_AS_VIEW or \
		    mask VCNA_SAME_HEIGHT_AS_VIEW or \
		    mask VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY or \
		    mask VCNA_VIEW_DOES_NOT_WIN_SCROLL
65$:
	push	si
	call	VisFindParent
	call	SIB_DerefVisSI
	mov	ds:[si].VCNI_attrs, cl		
	pop	si

	;
	; In the direction of orientation of the view, we'll make the view
	; scrollable, set the increment amount, and have the size dependent
	; on that increment amount.  Nothing need be set in the other direction.
	;
	call	SIB_DerefVisDI
	mov	cx, ds:[di].OLSLI_itemLength		;assume vertical, 
							;  increment amt to set
	clr	dx					;0 in the other (to not
							;  affect size)
	mov	bx, mask GVDA_SCROLLABLE or \
		    mask GVDA_SIZE_A_MULTIPLE_OF_INCREMENT
							;assume we'll set these
							;  in vertical bar
	mov	ax, bx
	xchg	al, ah					;and clear in horiz bar

	mov	si, ds:[di].OLSLI_view
EC <	tst	si				>
EC <	ERROR_Z 	OL_ERROR		>
	popf						;restore vertical flag
	jnz	70$					;vertical, branch
	xchg	cx, dx					;horiz, switch these
	xchg	bx, ax					;and these
70$:
	;
	; Having set up our registers correctly, set all appropriate things:
	;	*ds:si -- view
	;	cx -- y increment
	;	dx -- x increment
	;	bl, bh -- bits to set and clear in vertical bar
	;	al, ah -- bits to set and clear in horizontal bar
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GVI_increment.PD_y.low, cx	
	mov	ds:[di].GVI_increment.PD_x.low, dx	
	clrdw	ds:[di].GVI_docBounds.RD_right
	clrdw	ds:[di].GVI_docBounds.RD_bottom

	mov	cx, ax
	mov	dx, bx
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	call	ObjCallInstanceNoLock

	;
	; Keep the view from taking the focus away from text objects.
	;
	mov	cx, mask OLPF_DONT_TAKE_FOCUS_FROM_TEXT_OBJECTS
	mov	ax, MSG_SPEC_VIEW_SET_PANE_FLAGS
	call	ObjCallInstanceNoLock

	;
	; Sets a moniker position for the view, if needed.  -cbh 11/15/92
	;
OLS <	mov	cx, SCROLL_ITEM_INSET_X					>
CUAS <	mov	cx, MO_SCROLL_ITEM_INSET_X				>
OLS <	mov	dx, SCROLL_ITEM_INSET_X					>
CUAS <	mov	dx, MO_SCROLL_ITEM_INSET_Y				>

	mov	ax, MSG_SPEC_CTRL_SET_MONIKER_OFFSET
	call	ObjCallInstanceNoLock
	pop	bp				;restore locals pointer

	.leave
	ret
OLScrollListSetupViewStuff	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CopySizeToViewIfSpecified

SYNOPSIS:	Copies converted size hints to view if they're there.

CALLED BY:	OLScrollListScanGeometryHints

PASS:		*ds:si -- scrolling list
		desiredSize[di] -- local vars containing size args to send
		ax -- message to send
		bl -- ScrollListScanArgs

RETURN:		carry set if hint specified
		bl -- ScrollListScanArgs, updated

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 9/92		Initial version

------------------------------------------------------------------------------@

CSTV_width	 equ	offset SSA_fixedWidth - offset SSA_fixedWidth
CSTV_height	 equ	offset SSA_fixedHeight - offset SSA_fixedWidth
CSTV_numChildren equ	offset SSA_fixedNumChildren - offset SSA_fixedWidth

CopySizeToViewIfSpecified	proc	near		
	desiredSize		local	SpecSizeArgs
	.enter	inherit

	push	bp
	mov	cx, ({word} ss:desiredSize[di])+CSTV_width
	mov	dx, ({word} ss:desiredSize[di])+CSTV_height
	mov	di, ({word} ss:desiredSize[di])+CSTV_numChildren
	mov	bp, cx
	or	bp, dx
	or 	bp, di
	jnz	hasHints			;hint specified, branch

	test	bl, mask SLSA_ENSURE_HINT_IS_NUKED_IN_VIEW
	clc					;either way, no hint found
	jnz	finishUp			;need to nuke the hint, branch
	jmp	short exit			;and exit

hasHints:
	;
	; Mark hints specified to we'll avoid specifying a default fixed size
	; later.
	;	bl -- ScrollListScanArgs
	;	cx -- converted width
	;	dx -- converted height
	;	di -- converted count
	;	ax -- message we'll be sending to the view
	;
	jcxz	10$
	ornf	bl, mask SLSA_WIDTH_HINT_SPECIFIED
	cmp	ax, MSG_GEN_SET_INITIAL_SIZE
	jne	10$
	ornf	bl, mask SLSA_INIT_WIDTH_HINT_SPECIFIED
10$:
	tst	dx
	jz	20$
	ornf	bl, mask SLSA_HEIGHT_HINT_SPECIFIED
	cmp	ax, MSG_GEN_SET_INITIAL_SIZE
	jne	20$
	ornf	bl, mask SLSA_INIT_HEIGHT_HINT_SPECIFIED
20$:
	stc					;set the found-hint flag
finishUp:
	pushf					;save carry to return

	;
	; Setup arguments for the setting the appropriate hint in the view.
	;
	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_width, cx
	mov	ss:[bp].SSA_height, dx
	mov	ss:[bp].SSA_count, 0		;don't need a count for the view
	mov	ss:[bp].SSA_updateMode, VUM_MANUAL

	;
	; Set the item length if we've got a value in the direction of 
	; orientation of the list.
	;	ax -- message to send to view
	;	bl -- ScrollListScanArgs
	;	ss:bp -- SetSizeArgs (for sending to the view)
	;	cx -- spec'ed desired width
	;	dx -- spec'ed desired height
	;	di -- spec'ed desired count
	;
	push	si				;save list obj
	call	SIB_DerefVisSI
	test	ds:[si].OLSLI_attrs, mask OLSLA_VERTICAL
	pop	si
	jnz	30$				;vertical, branch
	mov	dx, cx				;else use width for item length
30$:
	tst	dx				;is there anything specified?
	jz	50$				;no, skip setting of item length
	test	bl, mask SLSA_ITEM_LENGTH_CALCULATED	;already calc'ed, exit
	jnz	50$
	ornf	bl, mask SLSA_ITEM_LENGTH_CALCULATED    ;say calc'ed

	push	ax				;save message
	mov_tr	ax, dx				;length in ax
	clr	dx				;in dx:ax
	mov	cx, di				;numVisibleItems in cx
	jcxz	40$				;no numVisibleItems, branch
	div	cx				;divide by numVisibleItems, 
						;   result in ax
40$:
	push	si
	call	SIB_DerefVisSI
	mov	ds:[si].OLSLI_itemLength, ax	;store
	pop	si
	pop	ax				;restore message
50$:
	;
	; Now (finally) set the hint.
	;	ax -- message to send
	;	ss:bp -- SetSizeArgs
	;
	mov	dx, size SetSizeArgs		;send to view
	push	si
	call	SIB_DerefVisSI
	mov	si, ds:[si].OLSLI_view
	call	ObjCallInstanceNoLock
	pop	si
	add	sp, size SetSizeArgs
	popf					;restore carry to return
exit:
	pop	bp
	.leave
	ret
CopySizeToViewIfSpecified	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetDefaultListSizeIfNeeded

SYNOPSIS:	Sets a default size for the list, if necessary.  We need a
		default width or height if there wasn't anything specified
		in a corresponding hint, and the thing isn't expand-to-fit
		in that direction.  We'll need to set a default numVisibleItems
		only if we're setting a default in the direction of orientation
		of the list.  We'll set a default item length if one hasn't 
		been set previously (via a size hint).

CALLED BY:	OLScrollListScanGeometryHints

PASS:		*ds:si -- scrolling list
		bl -- ScrollListScanArgs

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/10/92		Initial version

------------------------------------------------------------------------------@
SetDefaultListSizeIfNeeded	proc	near
	desiredSize		local	SpecSizeArgs
	.enter	inherit

	push	bx				;save ScrollListScanArgs
	push	bp				;save bp
	call	GetDefaultItemSize		;cx, dx <- default item size
	pop	bp				;restore stack pointer
	pop	ax				;restore flags
	;
	; We've now calculated a default item height (in dx) and a default
	; width for the scrolling list (in cx).  We'll use these for a 
	; default desired size for the view if no other hint has been
	; specified.
	;	cx -- default item width
	;	dx -- default item height
	;
	;
	; Before doing anything, we'll set up the default item length if not
	; already set up.
	;
	test	al, mask SLSA_ITEM_LENGTH_CALCULATED
	jnz	itemLengthSpecified
	call	SIB_DerefVisDI
	mov	ds:[di].OLSLI_itemLength, dx	;assume vertical, store height
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	itemLengthSpecified
	mov	ds:[di].OLSLI_itemLength, cx	;horizontal, store width

itemLengthSpecified:
	call	SwapIfVertical			;ignore orientation

	;
	; cx = default along length of list, dx = width of list.
	;
	; Multiply the length value by numVisibleItems, width value by wrap
	; count.
	;
	push	ax				;save ScrollListScanArgs
	push	dx
	call	MultByNumVisibleItems		;ax <- result	
	pop	dx
	push	ax, bx				;save result, num visible items
	mov	cx, dx
	call	MultByWrapCount
	mov	dx, cx
	pop	cx, bx				;restore length value, numVItems
	clr	ax				;numChildren if width stored
	call	SwapIfVertical			;xchg cx/dx
	jnz	10$				;was vertical, branch
	xchg	ax, bx				;else swap num children args
10$:
	mov	di, ax
	pop	ax				;restore ScrollListScanArgs
	;
	; Okay.  For the height, width, and nunber of children, if we haven't
	; yet specified a width or height, we'll store default values for 
	; setting a HINT_FIXED_SIZE on the view.  For those that have already
	; been specified, we'll still use the defaults on a HINT_INITIAL_SIZE
	; on the view, so the view won't use its own default open size.
	; (But of course, only if there hasn't been one set previously.)
	; 
	;
	; ax -- ScrollListScanArgs
	; cx -- total default width
	; dx -- total default height
	; bx -- num children if default height used in HINT_FIXED_SIZE
	; di -- num children if default width used in HINT_FIXED_SIZE
	;
	test	al, mask SLSA_HEIGHT_HINT_SPECIFIED
	jz	useDefaultHeight		;no height hint yet, branch
	test	al, mask SLSA_INIT_HEIGHT_HINT_SPECIFIED
	jnz	checkWidth			;init height exists, skip
	mov	desiredSize.SSA_initHeight, dx	;else store init height
	ornf	desiredSize.SSA_initNumChildren, bx
	jmp	short checkWidth

useDefaultHeight:
	mov	desiredSize.SSA_fixedHeight, dx	;store fixed height
	ornf	desiredSize.SSA_fixedNumChildren, bx

checkWidth:
	test	al, mask SLSA_WIDTH_HINT_SPECIFIED
	jz	useDefaultWidth			;no width hint yet, branch
	test	al, mask SLSA_INIT_WIDTH_HINT_SPECIFIED
	jnz	setView				;init width exists, skip
	mov	desiredSize.SSA_initWidth, cx	;else store init width
	ornf	desiredSize.SSA_initNumChildren, di
	jmp	short setView

useDefaultWidth:
	mov	desiredSize.SSA_fixedWidth, cx	;store fixed width
	ornf	desiredSize.SSA_fixedNumChildren, di

setView:	
	;
	; Based on our calculations, we'll put the HINT_FIXED_SIZE and 
	; HINT_INITIAL_SIZE in the view as needed.
	;
	mov	bl, al				;get scan args
	andnf	bl, not mask SLSA_ENSURE_HINT_IS_NUKED_IN_VIEW
						;don't nuke any existing hint
	mov	ax, MSG_GEN_SET_FIXED_SIZE	;what to call 
	mov	di, offset SSA_fixedWidth	
	call	CopySizeToViewIfSpecified

	mov	ax, MSG_GEN_SET_INITIAL_SIZE	;what to call 
	mov	di, offset SSA_initWidth	
	call	CopySizeToViewIfSpecified


exit:
	.leave
	ret
SetDefaultListSizeIfNeeded	endp



SwapIfVertical	proc	near
	;
	; Swaps cx and dx if scrolling list is vertical.  Returns zero flag
	; cleared if list is vertical.
	;
	call	SIB_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	exit
	xchg	cx, dx
exit:
	ret
SwapIfVertical	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDefaultItemSize

SYNOPSIS:	Returns the default item size for this item group.

CALLED BY:	SetDefaultListSizeIfNeeded

PASS:		*ds:si -- item group

RETURN:		cx, dx -- default item size

DESTROYED:	di, bp, ax

PSEUDO CODE/STRATEGY:
	if dynamic list
		use some preset values for default item width and height
	else
		use largest item height and width of the children available

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/15/92		Initial version

------------------------------------------------------------------------------@
GetDefaultItemSize	proc	near

	call	SIB_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	calcItemSize			;not dynamic, calc item size

calcOwnDefaultSize:
	;
	; In a dynamic or empty list, we'll use our own default size.
	;
	call	ViewCreateCalcGState	; Get GState for poss use
	mov	ax, SpecWidth <SST_LINES_OF_TEXT, 1>
	call	VisConvertSpecVisSize	
	mov_tr	dx, ax				; typical item height in bx
	mov	ax, SpecWidth <SST_AVG_CHAR_WIDTHS, 15>
	call	VisConvertSpecVisSize		; typical width in ax
	mov_tr	cx, ax
	call	GrDestroyState
OLS <	add	cx, SCROLL_ITEM_INSET_X*2	; add in extra margins,	   >
OLS <	add	dx, SCROLL_ITEM_INSET_X*2	; in a rather presumptuous >

if _CUA_STYLE
	add	cx, MO_SCROLL_ITEM_INSET_X*2	; way...
	add	dx, MO_SCROLL_ITEM_INSET_Y*2
endif



	jmp	short exit

calcItemSize:
	;
	; Take the largest width and height from the children.
	;
	clr	cx, dx				; initialize to nothing
	mov	bx, offset GetMinItemSizes
	call	OLResidentProcessGenChildrenClrRegs
	jcxz	calcOwnDefaultSize		; no items answered, use our
						;    default
exit:
	ret
GetDefaultItemSize	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	MultByNumVisibleItems

SYNOPSIS:	Multiplies the passed size by the default number of items.
		Limits the size to some maximum amount.

CALLED BY:	SetDefaultListSizeIfNeeded

PASS:		cx -- size to multiply

RETURN:		ax -- result
		bx -- number of visible items, or zero if not doing anything

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@
MultByNumVisibleItems	proc	near
	uses	di
	.enter

	mov	ax, SLIST_DEFAULT_ITEMS_SHOWN	;default number of items
	call	SIB_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	horizontal
	call	OpenCheckIfCGA
	jnc	gotDefaultNumItems
fewerItems:
	mov	ax, CGA_SLIST_DEFAULT_ITEMS_SHOWN
	jmp	gotDefaultNumItems

horizontal:
	call	OpenCheckIfNarrow
	jc	fewerItems

gotDefaultNumItems:
	clr	bx
	jcxz	exit				;not doing default fixed width
	mov	bx, ax				; keep in bx
10$:
	mov	ax, bx				; num visible items in ax
	mul	cx				; multiply item by #items
EC <	tst	dx							>
EC <	ERROR_NZ	OL_ERROR					>
	cmp	ax, SLIST_MAXIMUM_DEFAULT_SIZE	;don't let it get too big
	jbe	exit
	cmp	bx, 1				;have we gone as far as we can?
	je	exit
	inc	bx
	shr	bx, 1				;else adjust 5->2, 2->1
	jmp	short 10$
exit:
	.leave
	ret
MultByNumVisibleItems	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListViewWinOpened

DESCRIPTION:	Handles a view win created message sent down from the 
		GenContent, after a MSG_META_CONTENT_VIEW_SIZE_CHANGED has been
		sent.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_WIN_OPENED
		^hbp	- Window

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Note: assumes the current peculiar behavior of GenContents, that in
	response to a view window being started up, sends a MSG_VIS_CONTENT_-
	VIEW_SIZE_CHANGED to the first visible child, before also sending
	a MSG_META_CONTENT_VIEW_WIN_OPENED to the child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/31/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListViewWinOpened	method dynamic	OLScrollListClass, \
				MSG_META_CONTENT_VIEW_WIN_OPENED

	;Check for OLBF_TOOLBOX set it parent.  Set ourselves if so.

	call	OpenGetParentBuildFlagsIfCtrl	
	and	cx, mask OLBF_TOOLBOX or mask OLBF_DELAYED_MODE
	call	SIB_DerefVisDI
	ornf	ds:[di].OLCI_buildFlags, cx

	;
	; If this is a dynamic list, sufficient generic children should have
	; been created by now.  Let's get the focus object onscreen, if 
	; possible.
	;
	call	IsNonExclusive
	jc	exit			;skip if is non-exclusive list...
	call	EnsureCurrentSelectionVisible
exit:
	ret
OLScrollListViewWinOpened	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListVisUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure text object releases focus & exclusive
		grabs, since text object is being visually unbuilt.
		Then do see if we need to set an associated view or
		composite as well.

CALLED BY:	via MSG_SPEC_UNBUILD_BRANCH
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_SPEC_UNBUILD
		bp	- SpecBuildFlags
				SBF_VIS_PARENT_UNBUILDING	- set if
				we're being called only because visible parent,
				not generic, is unbuilding.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version
	jcw	10/13/89	2d Initial version
	Doug	1/90		Converted from SPEC_SET_NOT_USABLE handler
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
OLScrollListVisUnbuild	method dynamic OLScrollListClass, MSG_SPEC_UNBUILD

	push	bp
	call	RemoveDynamicListItems		;if dynamic list, go remove 'em
	pop	bp
						; bp = SpecBuildFlags
	call	SIB_DerefVisDI
 	mov	di, ds:[di].OLSLI_view		;get parent object
	mov	bl, -1				;mark parent as a view
	mov	ax, bx				;destroy parent moniker
	call	OpenUnbuildCreatedParent	;unbuild parent, then unbuild
						;   ourselves
	call	SIB_DerefVisDI
	clr	ds:[di].OLSLI_view
	ret
	
OLScrollListVisUnbuild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListGetSpecVisObj --
		MSG_SPEC_GET_SPECIFIC_VIS_OBJECT for OLScrollListClass

DESCRIPTION:	Returns specific object used for this generic object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
		bp	- SpecBuildFlags

RETURN:		cx:dx	- the specific object (or null if caller is querying
			  for the win group part)
		carry set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/25/89	Initial version  (did I write this code?  I
						  didn't write this. I didn't
						  know what it did until I
						  asked Doug.)

------------------------------------------------------------------------------@

OLScrollListGetSpecVisObj	method dynamic OLScrollListClass, \
				MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
	clr	cx, dx				;assume querying for win group
	test	bp, mask SBF_WIN_GROUP		;doing win group
	jnz	exit				;exit if so

	mov	cx, ds:[0]			;else assume we return ourselves
	mov	dx, si

	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	returnViewIfNeeded
	mov	di, offset OLScrollListClass
	GOTO	ObjCallSuperNoLock
	
returnViewIfNeeded:
	tst	ds:[di].OLSLI_view
	jz	exit				;not in a view, we're done
	mov	dx, ds:[di].OLSLI_view		;else return view object
exit:
	stc					;return carry set
	ret
OLScrollListGetSpecVisObj	endm


SListBuild	ends

ItemCommon	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListMakeItemVisible -- 
		MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE for OLScrollListClass

DESCRIPTION:	Ensures that an item is visible.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
		cx	- item

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/13/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListMakeItemVisible	method dynamic	OLScrollListClass, \
				MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE

	mov	bp, cx				;assume dynamic, pos in bp
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jnz	havePosition			;dynamic list, already passed
						;  position, branch

	call	GetItemOptr			;cx:dx <- optr of item
	LONG jnc exit
	mov	ax, MSG_GEN_FIND_CHILD		;get position of item in bp
	call	IC_ObjCallInstanceNoLock
	LONG jc	exit				;can't find it, exit

	call	IC_DerefVisDI
	
havePosition:
	;
	; If obviously already onscreen, exit.
	;	bp -- position
	;
	mov	ax, ds:[di].OLSLI_topItem	
	cmp	bp, ax				;see if above top item
	jb	needToScroll			;yes, need to scroll
	add	ax, ds:[di].OLSLI_numVisibleItems 
	cmp	bp, ax				;below bottom?
	jb	exit				;no, exit

needToScroll:
	;
	; Calculate the theoretical position of the child, rather than counting
	; on the item's bounds.  The position is as follows:
	;
	; itemWidth, itemHeight = MSG_SPEC_RECALC_ITEM_SIZE();
	; If OLSLA_VERTICAL
	;	xPos = itemWidth * (position mod wrapCount)
	;	yPos = itemLength * (position div wrapCount)
	; else
	;	xPos = itemWidth * (position div wrapCount)
	;	yPos = itemLength * (position mod wrapCount) 
	;
	; bp -- position
	;
	call	GetWrapCount			;wrap count in ax
	xchg	ax, bp
	clr	dx				;position in dx:ax, wrap in bp
	div	bp				;div value now in ax,
						;mod value in dx
	call	IC_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	10$				
	xchg	dx, ax				;horizontal, swap the values
10$:
	;
	; Value to apply to width now in dx.  Value to apply to height now
	; in ax.
	;
	push	dx, ax
	call	OLScrollListRecalcItemSize	;item width, height in cx, dx
	mov	bp, dx				;height in bp
	pop	ax				;restore height multiple
	mul	bp				;multiply, top now in dx:ax
	mov	bx, bp				;height in bx
	pop	di				;width multiple now in di
		
	sub	sp, size MakeRectVisibleParams
	mov	bp, sp

	movdw	ss:[bp].MRVP_bounds.RD_top, dxax	;store top
	add	ax, bx					;add height
	adc	dx, 0
	movdw	ss:[bp].MRVP_bounds.RD_bottom, dxax	;store as bottom

	mov	ax, di					;width multiple
	mul	cx					;left edge now in dx:ax
	movdw	ss:[bp].MRVP_bounds.RD_left, dxax	;store left edge
	add	ax, cx					;add width
	adc	dx, 0
	movdw	ss:[bp].MRVP_bounds.RD_right, dxax	;store right edge

	clr	ax
	mov	ss:[bp].MRVP_xMargin, ax
	mov	ss:[bp].MRVP_yMargin, ax
	mov	ss:[bp].MRVP_xFlags, ax
	mov	ss:[bp].MRVP_yFlags, ax

	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	call	IC_DerefVisDI
	mov	si, ds:[di].OLSLI_view
	call	IC_ObjCallInstanceNoLock
	add	sp, size MakeRectVisibleParams
exit:
	ret
OLScrollListMakeItemVisible	endm

ItemCommon 	ends




ScrItemCommon	segment resource

SIC_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret	
SIC_DerefVisDI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLScrollListKbdChar -- MSG_META_KBD_CHAR handler

DESCRIPTION:	This method is sent from one of the GenListEntries when
		is is cursored.

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
	Eric	5/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

OLScrollListKbdChar	method	dynamic OLScrollListClass, \
					MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR
if _KBD_NAVIGATION	;------------------------------------------------------
	;we should not get events when the list is disabled...

EC <	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED			>
EC <	ERROR_Z	OL_ERROR						>

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper		;quit if not character.

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

	push	es
	segmov	es, cs, di		;set es:di = table of shortcuts
					;and matching methods
	mov	di, offset ScrollListKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	callSuper		;send on to superclass if no match.

sendMethod:
	GOTO	ObjCallInstanceNoLock

endif	;----------------------------------------------------------------------

callSuper:
	CallSuper MSG_META_KBD_CHAR
	ret
OLScrollListKbdChar	endm

if _KBD_NAVIGATION	;------------------------------------------------------

if SCROLL_LISTS_CAN_BE_LINKED	;----------------------------------------------

ScrollListKbdBindings	label	word
	word	length ScrollListKbdBindingsList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r

if DBCS_PCGEOS
ScrollListKbdBindingsList	KeyboardShortcut \
		<0, 0, 0, 0, C_SYS_PREVIOUS and mask KS_CHAR>,	;Page-up
		<0, 0, 0, 0, C_SYS_NEXT and mask KS_CHAR>,	;Page-down
		<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;Left-arrow
		<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;Right-arrow
		<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;Up-arrow
		<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>	;Down-arrow
else
ScrollListKbdBindingsList	KeyboardShortcut \
		<0, 0, 0, 0, 0xf, VC_PREVIOUS>,	;Page-up
		<0, 0, 0, 0, 0xf, VC_NEXT>,	;Page-down
		<0, 0, 0, 0, 0xf, VC_LEFT>,	;Left-arrow
		<0, 0, 0, 0, 0xf, VC_RIGHT>,	;Right-arrow
		<0, 0, 0, 0, 0xf, VC_UP>,	;Up-arrow
		<0, 0, 0, 0, 0xf, VC_DOWN>	;Down-arrow
endif

;ScrollListKbdBindingsMethods	label word
	word	MSG_OL_SLIST_PAGE_UP
	word	MSG_OL_SLIST_PAGE_DOWN
	word	MSG_OL_SLIST_LEFT_ARROW
	word	MSG_OL_SLIST_RIGHT_ARROW
	word	MSG_OL_SLIST_UP_ARROW
	word	MSG_OL_SLIST_DOWN_ARROW

else	; not SCROLL_LISTS_CAN_BE_LINKED --------------------------------------

ScrollListKbdBindings	label	word
	word	length ScrollListKbdBindingsList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r

if DBCS_PCGEOS


    ScrollListKbdBindingsList	KeyboardShortcut \
		<0, 0, 0, 0, C_SYS_PREVIOUS and mask KS_CHAR>,	;Page-up
		<0, 0, 0, 0, C_SYS_NEXT and mask KS_CHAR>	;Page-down


else ; not DBCS_PCGEOS


    ScrollListKbdBindingsList	KeyboardShortcut \
		<0, 0, 0, 0, 0xf, VC_PREVIOUS>,	;Page-up
		<0, 0, 0, 0, 0xf, VC_NEXT>	;Page-down


endif ; not DBCS_PCGEOS

;ScrollListKbdBindingsMethods	label word
	word	MSG_OL_SLIST_PAGE_UP
	word	MSG_OL_SLIST_PAGE_DOWN

endif	; SCROLL_LISTS_CAN_BE_LINKED ------------------------------------------

endif	; _KBD_NAVIGATION -----------------------------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListPageUp -- 
		MSG_SLIST_PAGE_UP for OLScrollListClass

DESCRIPTION:	Scrolls up a page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SLIST_PAGE_UP

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/11/90		Initial version

------------------------------------------------------------------------------@

OLScrollListPageUp	method dynamic OLScrollListClass, \
							MSG_OL_SLIST_PAGE_UP
	clr	cl				;no flags
	GOTO	FinishPage

OLScrollListPageUp	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListPageDown -- 
		MSG_SLIST_PAGE_DOWN for OLScrollListClass

DESCRIPTION:	Scrolls down a page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SLIST_PAGE_DOWN

RETURN:		

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Apologies for depending so heavily on copenSettingCtrl code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/11/90		Initial version

------------------------------------------------------------------------------@

OLScrollListPageDown	method dynamic OLScrollListClass, \
							MSG_OL_SLIST_PAGE_DOWN
	mov	cl, mask GSIF_FORWARD		;scan forwards

FinishPage	label	far
	;
	; cl -- GenScanItemsFlags; ds:di -- SpecInstance
	;
	mov	bp, ds:[di].OLSLI_numVisibleItems 
	dec	bp				;number of items to skip
	CallMod	OLItemGroupSetUserCommon

	ret
OLScrollListPageDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select item in list

CALLED BY:	MSG_OL_SLIST_SET_SELECTION
PASS:		*ds:si	= OLScrollListClass object
		ds:di	= OLScrollListClass instance data
		ds:bx	= OLScrollListClass object (same as *ds:si)
		es 	= segment of OLScrollListClass
		ax	= message #
		bp	= position of item to select
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LISTS_CAN_BE_LINKED

OLScrollListSetSelection	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_SET_SELECTION
	mov	cx, mask GSIF_FORWARD or mask GSIF_FROM_START or \
			mask GSIF_INITIAL_ITEM_FOUND
					; no OLExtendedKbdFlags
	CallMod	OLItemGroupSetUserCommon
	ret
OLScrollListSetSelection	endm

endif	; SCROLL_LISTS_CAN_BE_LINKED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListLeftArrow, OLScrollListRightArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move selection to the left or right

CALLED BY:	MSG_OL_SLIST_LEFT_ARROW, MSG_OL_SLIST_RIGHT_ARROW

PASS:		*ds:si	= OLScrollListClass object
		ds:di	= OLScrollListClass instance data
		ds:bx	= OLScrollListClass object (same as *ds:si)
		es 	= segment of OLScrollListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LISTS_CAN_BE_LINKED

OLScrollListLeftArrow	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_LEFT_ARROW
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	prev			; go to prev link

	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	clr	ch			; no OLExtendedKbdFlags
	GOTO	ObjCallInstanceNoLock
prev:
	mov	ax, HINT_ITEM_GROUP_PREV_LINK
	GOTO	OLScrollListLeftRightArrowCommon

OLScrollListLeftArrow	endm
	
OLScrollListRightArrow	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_RIGHT_ARROW
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	next			; go to next link

	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	clr	ch			; no OLExtendedKbdFlags
	GOTO	ObjCallInstanceNoLock
next:
	mov	ax, HINT_ITEM_GROUP_NEXT_LINK
	FALL_THRU OLScrollListLeftRightArrowCommon

OLScrollListRightArrow	endm

OLScrollListLeftRightArrowCommon	proc	far

	call	ObjVarFindData
	jnc	done			; skip if not found

	push	bx
	call	GetFocusItemOptr
	pop	bx
	jnc	done			; skip if no focus item

	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjCallInstanceNoLock	; bp = child position (0..n-1)
	jc	done			; skip if focus item not found

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	sub	bp, ds:[di].OLSLI_topItem ; bp = distance from topItem

	push	bp
	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle
	mov	ax, MSG_OL_SLIST_GET_TOP_ITEM
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx
	jcxz	done

	add	bp, dx			; bp = child position

	mov	ax, MSG_OL_SLIST_SET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
done:
	ret
OLScrollListLeftRightArrowCommon	endp

endif	; SCROLL_LISTS_CAN_BE_LINKED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListUpArrow, OLScrollListDownArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move selection up or down, or send message

CALLED BY:	MSG_OL_SLIST_UP_ARROW, MSG_OL_SLIST_DOWN_ARROW

PASS:		*ds:si	= OLScrollListClass object
		ds:di	= OLScrollListClass instance data
		ds:bx	= OLScrollListClass object (same as *ds:si)
		es 	= segment of OLScrollListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_NOTIFY_ON_SCROLL_OUT_OF_BOUNDS

OLScrollListUpArrow	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_UP_ARROW
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	prevItem		; just go to previous item if not vert

	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	prevItem		; let igroup deal with it

	clr	cl			; scan backwards
	mov	dx, ds:[di].OLIGI_focusItem
	mov	bp, 1			; number of items to skip
	push	dx
	call	ScanItems
	pop	dx
	jnc	prevLink		; goto to prev link if item not found

	cmp	ax, dx			; if scanned item == focus item
	je	prevLink		;  then goto prev link

prevItem:
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_PREVIOUS
	clr	ch			; no OLExtendedKbdFlags
	GOTO	ObjCallInstanceNoLock

prevLink:
	; go to bottom of prev link list

	mov	ax, HINT_ITEM_GROUP_PREV_LINK
	call	ObjVarFindData
	jnc	sendMessage

	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_END
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage	

sendMessage:
	mov	ax, HINT_ITEM_GROUP_SCROLL_OUT_OF_BOUNDS_MSGS
	call	ObjVarFindData
	jnc	done

	mov	ax, ds:[bx].SOOBM_upMessage
	clr	cx, di			; no state flags, don't close window!
	call	GenItemSendMsg
done:
	ret
OLScrollListUpArrow	endm
	
OLScrollListDownArrow	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_DOWN_ARROW
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	nextItem		; just go to next item if not vertical

	test	ds:[di].OLIGI_state, mask OLIGS_HAS_FOCUS_ITEM
	jz	nextItem		; let igroup deal with it

	mov	cl, mask GSIF_FORWARD	; scan forward
	mov	dx, ds:[di].OLIGI_focusItem
	mov	bp, 1			; number of items to skip
	push	dx
	call	ScanItems
	pop	dx
	jnc	nextLink		; go to next link if item not found

	cmp	ax, dx			; if scanned item == focus item
	je	nextLink		;  then next link

nextItem:
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_NEXT
	clr	ch			; no OLExtendedKbdFlags
	GOTO	ObjCallInstanceNoLock

nextLink:
	mov	ax, HINT_ITEM_GROUP_NEXT_LINK
	call	ObjVarFindData
	jnc	sendMessage

	; go to top of next link list

	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle
	mov	ax, MSG_OL_IGROUP_SET_SELECTION_TO_START
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage	

sendMessage:
	mov	ax, HINT_ITEM_GROUP_SCROLL_OUT_OF_BOUNDS_MSGS
	call	ObjVarFindData
	jnc	done			; skip if vardata not found

	mov	ax, ds:[bx].SOOBM_downMessage
	clr	cx, di			; no state flags, don't close window!
	call	GenItemSendMsg
done:
	ret
OLScrollListDownArrow	endm

endif	; SCROLL_LIST_NOTIFY_ON_SCROLL_OUT_OF_BOUNDS


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for OLScrollListClass

DESCRIPTION:	Sent to object to update its visual enabled state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		carry set if visual state changed

DESTROYED:	ax, cx, dx, bp

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
OLScrollListNotifyEnabled	method dynamic OLScrollListClass, \
				MSG_SPEC_NOTIFY_ENABLED

	mov	di, MSG_GEN_NOTIFY_ENABLED	
	mov	bp, MSG_GEN_SET_ENABLED

FinishNotify	label	far			;message in ax
						;gen message in bp
						;gen notify message in di
	push	dx, ax, bp, di
	mov	di, offset OLScrollListClass
	call	ObjCallSuperNoLock
	pop	dx, ax, bp, di
	jnc	exit				;nothing special happened, exit

	;
	; Set the parent view or composite enabled, if applicable.
	;
	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- SpecInstance
	mov	bx, ds:[bx].OLSLI_view
	tst	bx
	jz	exit				;not in view or composite
	push	si
	mov	si, bx	
	mov	ax, bp
	call	ObjCallInstanceNoLock		;sets GS_ENABLED
	mov	ax, di
	call	ObjCallInstanceNoLock		;sets VA_FULLY_ENABLED if needed
	pop	si
	stc					;say handled
exit:
	ret
OLScrollListNotifyEnabled	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLScrollListClass

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

OLScrollListNotifyNotEnabled method dynamic OLScrollListClass, \
			      MSG_SPEC_NOTIFY_NOT_ENABLED

	mov	bp, MSG_GEN_SET_NOT_ENABLED
	mov	di, MSG_GEN_NOTIFY_NOT_ENABLED
	GOTO	FinishNotify

OLScrollListNotifyNotEnabled	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLScrollListClass

DESCRIPTION:	Specific UI handler for setting the vis moniker.
		Sets OLCOF_DISPLAY_MONIKER flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

		dl	- VisUpdateMode
		cx, bp	- width, height of moniker

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version
	Chris	2/11/93		Changed to deal with a null moniker.

------------------------------------------------------------------------------@
OLScrollListUpdateVisMoniker	method OLScrollListClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; Nothing to be done but to have the moniker set on the view.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	bp, dx				; pass update mode in bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].GI_visMoniker
	tst	dx
	jnz	10$
	mov	cx, dx				; pass null for moniker
	mov	dx, bp
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	jmp	short 20$
10$:
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
20$:
	call	SIC_DerefVisDI
	mov	si, ds:[di].OLSLI_view
	tst	si
	jz	done				; no view yet, done
						; (will use new moniker when
						;	built)
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLScrollListUpdateVisMoniker	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListTrackScrolling -- 
		MSG_META_CONTENT_TRACK_SCROLLING for OLScrollListClass

DESCRIPTION:	Tracks scrolling, so that the origin is always aligned with
		the items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_TRACK_SCROLLING
		ss:bp	- TrackScrollingParams

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/10/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListTrackScrolling	method dynamic	OLScrollListClass, \
				MSG_META_CONTENT_TRACK_SCROLLING

	call	GenSetupTrackingArgs
	;
	; In the direction of our orientation, we'll change the new origin
	; to stay on item boundaries.
	;
	push	bp				; save buffer pointer
	call	SIC_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	10$				; no, branch
	add	bp, offset PD_y - offset PD_x	; else access vertical stuff
10$:
	;
	; Now pointing to proper axis, take the new origin and adjust it be
	; a multiple of the itemLength
	;
	movdw	dxcx, ss:[bp].TSP_newOrigin.PD_x
EC < 	tst	dx				; negative, die		>
EC <	ERROR_S	OL_ERROR						>
	mov_tr	ax, cx				; operand now in dx.ax
	mov	cx, ds:[di].OLSLI_itemLength
	jcxz	30$				; no item length yet -> skip
	div	cx				; integer in ax, remainder in dx
	tst	dx				; remainder not large, branch
	jns	20$
	inc	ax				; else round up
20$:
	mul	cx				; re-multiply, result in dx.ax
	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_x ;make relative to old origin
	movdw	ss:[bp].TSP_change.PD_x, dxax	; and store the change
30$:
	pop	bp				; restore real buffer pointer

	;
	; Let dynamic list (if this is one) adjust monikers as necessary to
	; reflect the new scroll position.  We can't do this in the ORIGIN_-
	; CHANGED handler because we need it to occur before MAKE_ITEM_VISIBLE
	; message returns, and the view does some MF_FORCE_QUEUE's.
	;	
	movdw	dxax, ss:[bp].TSP_newOrigin.PD_x
	movdw	cxbx, ss:[bp].TSP_newOrigin.PD_y
	call	SendTopItemChanged		; set new top item

	call	GenReturnTrackingArgs
;	mov	si, ss:[bp].TSP_caller.chunk
;	mov	ax, MSG_GEN_VIEW_TRACKING_COMPLETE
;	call	ObjCallInstanceNoLock		; Send it off

	ret
OLScrollListTrackScrolling	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendTopItemChanged

SYNOPSIS:	Sends out a MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED so that
		monikers can be moved around, etc.  

CALLED BY:	OLScrollListTrackScrolling

PASS:		*ds:si -- dynamic list
		dx.ax  -- x origin
		cx.bx  -- y origin

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@
SendTopItemChanged	proc	near
	uses	bp
	.enter

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	call	CalcTopItem			;calculate a new top item
	call	SIC_DerefVisDI
	mov	dx, ds:[di].OLSLI_topItem	  ;save old top item
	mov	ds:[di].OLSLI_topItem, cx	  ;store a new top item
	mov	bp, ds:[di].OLSLI_numVisibleItems ;pass num items visible

if SCROLL_LIST_GRID_LINES_AND_SPACING
	call	InvalTopItemsIfNecessary
endif
	;
	; We'll send a message to ourselves, in case a dynamic list needs to
	; do some stuff.
	;
	call	SIC_DerefVisDI
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exit				;not dynamic, exit

	;
	; Before we do anything, let's try turning off intermediate mode.
	; There are problems moving the items around, where intermediate mode
	; is purposely not turned off, then the item with the focus doesn't
	; get the focus events from the drag scrolling.  -cbh 11/17/92
	;
	test	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE
	jz	10$
	push	cx, dx, bp
	mov	bp, mask OIENPF_RESTORE_SELECTION_TO_ORIGINAL_OWNER or \
		    mask OIENPF_RESTORE_FOCUS_EXCL_STATE_TO_ORIGINAL_OWNER or \
		    mask OIENPF_REDRAW_PRESSED_ITEM
	mov	ax, MSG_OL_IGROUP_END_INTERMEDIATE_MODE
	call	ObjCallInstanceNoLock		;End the intermediate mode
	pop	cx, dx, bp
10$:
	;
	; Send notification to the dynamic list.
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED
	call	ObjCallInstanceNoLock

	;
	; Ensure that correct object has the focus.
	;
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_SET_USABLE
	call	ObjCallInstanceNoLock
exit:
	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
SendTopItemChanged	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalTopItemsIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're drawing grid lines that are suppose to overlap,
		we run into a little problem.  In order to draw	overlapping
		grid lines, I had to have each item draw their top (or left)
		grid line 1 pixel higher.  But then the top grid line of the
		top item would draw above the top of the view.  To fix that,
		I had the top item draw it's top grid line one pixel lower
		than the other items.  But then when we scroll, we need to
		change the position of the top grid line for the new and old
		top item.  So, we make them redraw whenever the top item
		changes.

CALLED BY:	SendTopItemChanged
PASS:		*ds:si	= OLScrollListClass
		cx	= new topItem
		dx	= old topItem
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

InvalTopItemsIfNecessary	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	cmp	cx, dx				;do we have a new topItem?
	je	done				;skip if topItem unchanged

	; we only need to redraw the top items if grid lines are overlapping

	mov	ax, HINT_ITEM_GROUP_GRID_LINES
	call	ObjVarFindData
	jnc	done				;no vardata, then nothing to do

	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	verticalList
						;check vert grid for horiz list
	test	{ScrollListGridState}ds:[bx], mask SLGS_VGRID_SPACING
	jnz	done				; exit if grid spacing != 0
	jmp	invalTopItems

verticalList:					;check horiz grid for vert list
	test	{ScrollListGridState}ds:[bx], mask SLGS_HGRID_SPACING
	jnz	done				; exit if grid spacing != 0

invalTopItems:
	push	dx, si
	call	invalidateChildImage		;invalidate new top item
	pop	cx, si
	call	invalidateChildImage		;invalidate old top item
done:
	.leave
	ret

invalidateChildImage:
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock		;find child
	jc	afterInval			;exit if not found

	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_IMAGE_INVALID	;invalidate image
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;update later
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
afterInval:
	retn

InvalTopItemsIfNecessary	endp

endif	; SCROLL_LIST_GRID_LINES_AND_SPACING


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListViewSizeChanged -- 
		MSG_META_CONTENT_VIEW_SIZE_CHANGED for OLScrollListClass

DESCRIPTION:	Notification of a view size change.  Geometry has already been
		redone.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_SIZE_CHANGED
		cx, dx  - size of window the content is in

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
	if OLSLA_VERTICAL
		numVisibleItems = view height / item length * wrapCount
	else
		numVisibleItems = view width / item length * wrapCount

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Note: assumes the current peculiar behavior of GenContents, that in
	response to a view window being started up, sends a MSG_VIS_CONTENT_-
	VIEW_SIZE_CHANGED to the first visible child, before also sending
	a MSG_META_CONTENT_VIEW_WIN_OPENED to the child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/11/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListViewSizeChanged	method dynamic	OLScrollListClass, \
				MSG_META_CONTENT_VIEW_SIZE_CHANGED

	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	10$				;not vertical, branch
	mov	cx, dx				;else use view height
10$:
	mov	ax, cx				;set up size in dx:ax
	clr	dx
	div	ds:[di].OLSLI_itemLength	;divide by item length
	tst	dx				;any remainder? (shouldn't be)
	jz	20$				;nope, branch
	inc	ax				;else bump the numVisibleItems
20$:
	mov_tr	cx, ax				;result in cx
	call	MultByWrapCount			;multiply by wrap count
	call	SIC_DerefVisDI
	mov	ds:[di].OLSLI_numVisibleItems, cx ;store as the numVisibleItems
	mov	bp, ds:[di].OLSLI_topItem	  ;get the current top item

	;
	; We'll send a message to ourselves, in case a dynamic list needs to
	; do some stuff.
	;
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exit
	mov	dx, FALSE			; validate any new children
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
	call	ObjCallInstanceNoLock
	;
	; If this is a dynamic list, let's set the proper bounds for the view 
	; as well.
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	call	ObjCallInstanceNoLock			;num items in cx
	mov	ax, MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED
	call	ObjCallInstanceNoLock
exit:
	;
	; ensure selection visible
	;
	call	EnsureCurrentSelectionVisible

	ret
OLScrollListViewSizeChanged	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListViewOriginChanged -- 
		MSG_META_CONTENT_VIEW_ORIGIN_CHANGED for OLScrollListClass

DESCRIPTION:	View's origin changed. 

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLScrollListViewOriginChanged	method dynamic	OLScrollListClass, \
				MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
	;
	; Inform the view that our "update" is complete, so it can continue
	; to scroll if it cares to.
	;
	call	SendUpdateCompleteIfAllItemsInteractable

	;
	; If we're a dynamic, extended list extending the selection, let's
	; make sure we've got the proper selection.  -cbh 2/23/93
	; Augh!  Stupid, stupid.   This totally breaks extended selection	
	; keyboard navigation.  Lets make sure a button is down before we
	; do this hack.   We'll just look for anything, that should be
	; sufficient.  -cbh 4/20/93
	;
	call	ImGetButtonState		;no buttons down, get out!
	test	ax, mask IB_BUTTON_0
	jz	exit

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exit
	call	CheckIfExtendingSelection
	jnc	exit

	mov	di, ds:[di].VCI_window
	call	ImGetMousePos
	clr	bp				;not initial selection
	mov	ax, MSG_OL_IGROUP_EXTEND_SELECTION
	call	ObjCallInstanceNoLock
exit:
	ret
OLScrollListViewOriginChanged	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendUpdateCompleteIfAllItemsInteractable

SYNOPSIS:	Sends an update complete if we can. 

CALLED BY:	OLScrollListViewOriginChanged,
		OLScrollList

PASS:		

RETURN:		carry set if everything now interactable

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/23/93       	Initial version
	Chris	5/20/93		Changed to return carry set

------------------------------------------------------------------------------@
SendUpdateCompleteIfAllItemsInteractable	proc	near
	uses	si
	.enter

	mov	di, ds:[si]			;still someone interactable,exit
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLSLI_nonInteractables	; tst clears carry
	jnz	exit

	mov	si, ds:[di].OLSLI_view
	tst	si				; tst clears carry
	jz	exit
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_META_WIN_UPDATE_COMPLETE
	mov	di, mask MF_FORCE_QUEUE	or mask MF_INSERT_AT_FRONT
						;make sure another repeat scroll
						;  doesn't happen in the midst
						;  of the original scroll!
						;  5/19/93 cbh   (was clr di)
	call	ObjMessage
	stc					;everything interactable	
exit:
	.leave
	ret
SendUpdateCompleteIfAllItemsInteractable	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListItemChangedInteractableState -- 
		MSG_OL_IGROUP_NOTIFY_ITEM_CHANGED_INTERACTABLE_STATE 
		for OLScrollListClass

DESCRIPTION:	Item changes interactable state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_NOTIFY_ITEM_CHANGED_INTERACTABLE_STATE
		cx	- non-zero for item made interactable, zero if made
			  not-interactable.
		dx	- generic position of child changing

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/23/93         	Initial Version

------------------------------------------------------------------------------@
OLScrollListItemChangedInteractableState	\
			method dynamic	OLScrollListClass, \
			MSG_OL_IGROUP_NOTIFY_ITEM_CHANGED_INTERACTABLE_STATE

	jcxz	newNonInteractable
	dec	ds:[di].OLSLI_nonInteractables

	call	SendUpdateCompleteIfAllItemsInteractable
	jnc	exit				; still stuff to make 
						;   interactable, exit 5/20/93
	;
	; If this is a dynamic list, we'll draw the items now.  We haven't
	; redrawn anything yet on an initialize, scroll, or num visible items
	; changed.  -cbh 5/20/93  (Only redraw those items that have been
	; non-interactable.  6/21/93 cbh)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC
	jz	exit

if USE_REDRAW_ITEMS_OPTIMIZATION
	;
	; To avoid changing the API for M_G_I_G_R_I, we'll store
	; the bottomInvalidItem in Vardata, to be picked up
	; when this message is received.
	;
	mov	ax, TEMP_OL_ITEM_GROUP_LAST_ITEM_TO_REDRAW
	mov	cx, 2
	call	ObjVarAddData
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLSLI_bottomInvalidItem
	mov	ds:[bx], cx
endif ; USE_REDRAW_ITEMS_OPTIMIZATION

	mov	cx, ds:[di].OLSLI_topInvalidItem
	mov	ax, MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
	call	ObjCallInstanceNoLock

if USE_REDRAW_ITEMS_OPTIMIZATION
	mov	ax, TEMP_OL_ITEM_GROUP_LAST_ITEM_TO_REDRAW
	call	ObjVarDeleteData
endif ; USE_REDRAW_ITEMS_OPTIMIZATION
exit:
	ret

newNonInteractable:
	inc	ds:[di].OLSLI_nonInteractables
	;
	; Keep track of the lowest invalid item, so we can optimize our redraw
	; later.  6/21/93 cbh
	;
	cmp	ds:[di].OLSLI_topInvalidItem, dx
	jbe	10$
	mov	ds:[di].OLSLI_topInvalidItem, dx
10$:
if USE_REDRAW_ITEMS_OPTIMIZATION
	cmp	ds:[di].OLSLI_bottomInvalidItem, dx
	jge	setBottom			; (signed compare against -1)
	mov	ds:[di].OLSLI_bottomInvalidItem, dx
setBottom:	
endif ; USE_REDRAW_ITEMS_OPTIMIZATION
	ret
OLScrollListItemChangedInteractableState	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListRedrawItems -- 
		MSG_GEN_ITEM_GROUP_REDRAW_ITEMS for OLScrollListClass

DESCRIPTION:	Redraws items.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
		cx 	- place to draw from

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/22/93         	Initial Version

------------------------------------------------------------------------------@
OLScrollListRedrawItems	method dynamic	OLScrollListClass, \
				MSG_GEN_ITEM_GROUP_REDRAW_ITEMS
	;
	; If all our items are valid, we'll reset the topInvalidItem for
	; the next draw.
	;
	tst	ds:[di].OLSLI_nonInteractables
	jnz	10$
	mov	ds:[di].OLSLI_topInvalidItem, 0ffffh
if USE_REDRAW_ITEMS_OPTIMIZATION
	mov	ds:[di].OLSLI_bottomInvalidItem, 0ffffh
endif ; USE_REDRAW_ITEMS_OPTIMIZATION
10$:
	mov	di, offset OLScrollListClass
	GOTO	ObjCallSuperNoLock	

OLScrollListRedrawItems	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcTopItem

SYNOPSIS:	Returns item in upper-left corner.

CALLED BY:	OLScrollListViewOriginChanged

PASS:		*ds:si -- scroll list
		dx.ax  -- x origin
		cx.bx  -- y origin

RETURN:		cx -- top item

DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:
	if OLSLA_VERTICAL
		topItem = docOriginX / itemLength * wrapCount
	else
		topItem = docOriginY / itemLength * wrapCount

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/16/92		Initial version

------------------------------------------------------------------------------@

CalcTopItem	proc	near
	call	SIC_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jz	horiz				;vertical, we'll use width
	movdw	dxax, cxbx			;else we'll use height
horiz:
	div	ds:[di].OLSLI_itemLength	;divide by item length,
	mov_tr	cx, ax				; result in cx
	call	MultByWrapCount			; result in cx
	ret
CalcTopItem	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListReselectExcl -- 
		MSG_OL_IGROUP_RESELECT_EXCL for OLScrollListClass

DESCRIPTION:	Sees about reselecting the previous exclusive, as a part of
		ending intermediate mode.  We subclass here so that if we're
		a popup scrolling list, we can direct the view to do some
		drag scrolling (hopefully).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_IGROUP_RESELECT_EXCL

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
	chris	11/23/92         	Initial Version

------------------------------------------------------------------------------@
OLScrollListReselectExcl	method dynamic	OLScrollListClass, \
				MSG_OL_IGROUP_RESELECT_EXCL

	;make sure we don't get this in non-exclusive cases.

	push	bp
EC <	call	IsNonExclusive						>
EC <	ERROR_C OL_ERROR						>

	;if we have entered intermediate mode again, it means that some other
	;child GenListEntry has grabbed the mouse. Abort this handler,
	;saving the previous selection for later.

	test	ds:[di].OLIGI_state, mask OLIGS_INTERMEDIATE
	jnz	callSuper		;skip if again in intermediate mode...

	;
	; No window, do nothing special.
	;
	call	VisQueryWindow			;returns window in di
	tst	di
	jz	callSuper

	;	
	; If we're a popup list, direct our view to force a drag scroll.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	jz	callSuper
	push	si
	mov	si, ds:[di].OLSLI_view
EC <	tst	si				>
EC <	ERROR_Z 	OL_ERROR		>
	mov	ax, MSG_SPEC_VIEW_FORCE_INITIATE_DRAG_SCROLL
	call	ObjCallInstanceNoLock
	pop	si

callSuper:
	pop	bp
	mov	di, offset OLScrollListClass
	mov	ax, MSG_OL_IGROUP_RESELECT_EXCL
	GOTO	ObjCallSuperNoLock

OLScrollListReselectExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListGetTopItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the optr and child # of top item

CALLED BY:	MSG_OL_SLIST_GET_TOP_ITEM
PASS:		*ds:si	= OLScrollListClass object
		ds:di	= OLScrollListClass instance data
		ds:bx	= OLScrollListClass object (same as *ds:si)
		es 	= segment of OLScrollListClass
		ax	= message #
RETURN:		^lcx:dx	= optr of topItem (cx=0 if no topItem)
		bp	= child # of topItem
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

OLScrollListGetTopItem	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_GET_TOP_ITEM
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, ds:[di].OLSLI_topItem
	push	cx
	call	ObjCallInstanceNoLock
	pop	bp
	jnc	done

	clr	cx			; couldn't find topItem
done:
	ret
OLScrollListGetTopItem	endm

endif	; SCROLL_LIST_GRID_LINES_AND_SPACING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListGetSListAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the OLScrollListAttrs

CALLED BY:	MSG_OL_SLIST_GET_SLIST_ATTRS
PASS:		*ds:si	= OLScrollListClass object
		ds:di	= OLScrollListClass instance data
		ds:bx	= OLScrollListClass object (same as *ds:si)
		es 	= segment of OLScrollListClass
		ax	= message #
RETURN:		cl	= OLScrollListAttrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

OLScrollListGetSListAttrs	method dynamic OLScrollListClass, 
					MSG_OL_SLIST_GET_SLIST_ATTRS
	mov	cl, ds:[di].OLSLI_attrs
	ret
OLScrollListGetSListAttrs	endm

endif	; SCROLL_LIST_GRID_LINES_AND_SPACING

ScrItemCommon	ends


Resident	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetWrapCount

SYNOPSIS:	Returns wrap count in ax.

CALLED BY:	utility

PASS:		*ds:si -- our glorious object

RETURN:		ax -- wrap count

DESTROYED:	nothing
		can potentially move chunks, leaving dangling instance pointers

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@

GetWrapCount	proc	far
	mov	ax, 1				;assume wrap count of 1
	call	Res_DerefVisDI
	test	ds:[di].VCI_geoAttrs, mask VCGA_WRAP_AFTER_CHILD_COUNT
	jz	exit
	push	cx, dx, bp
	mov	ax, MSG_VIS_COMP_GET_WRAP_COUNT	
	call	Res_ObjCallInstanceNoLock
	mov_tr	ax, cx				;return wrap count
	pop	cx, dx, bp
exit:
	ret
GetWrapCount	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	MultByWrapCount

SYNOPSIS:	Multiplies passed value by the wrap count.

CALLED BY:	SetDefaultListSizeIfNeeded

PASS:		*ds:si -- object
		cx -- value to multiply
	
RETURN:		cx -- result

DESTROYED:	ax
		can potentially move chunks, leaving dangling instance pointers

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/12/92		Initial version

------------------------------------------------------------------------------@
MultByWrapCount	proc	far
	uses	dx
	.enter

	call	GetWrapCount			;wrap count in ax
	mul	cx				;result in dx:ax
	mov_tr	cx, ax				;return in cx
EC <	tst	dx							>
EC <	ERROR_NZ	OL_ERROR					>

	.leave
	ret
MultByWrapCount	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMinItemSizes

SYNOPSIS:	Returns minimum item width and height.  Sinve we know this
		is done

CALLED BY:	ObjCompProcessChildren (via SetDefaultListSizeIfNeeded)

PASS:		*ds:si -- item
		cx, dx -- minimum width, height so far

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/10/92		Initial version

------------------------------------------------------------------------------@
GetMinItemSizes	proc	far
	class	OLItemClass

	call	Res_DerefGenDI
	tst	ds:[di].GI_visMoniker		
	jz	20$				;no moniker yet, don't bother

	push	cx, dx
	clr	cx, dx				;pass zeroes, so items will know
						;  to calc their own min size
	mov	ax, MSG_VIS_RECALC_SIZE
	call	Res_ObjCallInstanceNoLock	;size returned in cx, dx
	pop	ax, bx
	
	cmp	cx, ax				;take width if larger
	ja	10$
	mov	cx, ax
10$:
	cmp	dx, bx				;take height if larger
	ja	20$
	mov	dx, bx
20$:
	ret
GetMinItemSizes	endp


Resident	ends

LessUsedGeometry	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListVisRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLScrollListClass

DESCRIPTION:	Recalculates the size of the scrolling list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - suggested size

RETURN:		cx, dx, - size to use

DESTROYED:	ax, bp


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/ 6/92		Initial Version

------------------------------------------------------------------------------@

if (0)	; Removed since this handler does nothing now.

OLScrollListVisRecalcSize	method dynamic	OLScrollListClass, \
				MSG_VIS_RECALC_SIZE
	push	cx, dx
	mov	di, offset OLScrollListClass
	CallSuper	MSG_VIS_RECALC_SIZE
	pop	ax, bx
	;
	; Expand-to-fit content, unless passed desired size.
	; (This is very bad, as the item group and items don't get a passed
	;  width in the geometry first pass, then because of this, think they
	;  match the width on the second pass and don't get any geometry
	;  calculated as a result, so the items never see the correct width.)
	;
;	tst	ax
;	js	10$
;	mov	cx, ax
;10$:
;	tst	bx
;	js	20$
;	mov	dx, bx
;20$:
	ret
OLScrollListVisRecalcSize	endm

endif	; if (0)


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLScrollListClass

DESCRIPTION:	Returns extra size for item group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/ 1/92		Initial Version

------------------------------------------------------------------------------@

if	0		;not finished!
OLScrollListGetExtraSize	method dynamic	OLScrollListClass, \
			MSG_SPEC_GET_EXTRA_SIZE
	
	mov	di, offset OLScrollListClass
	call	ObjCallSuperNoLock

	call	Geo_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	pushf
	jnz	10$				;vertical, branch
	mov	dx, cx				;else swap arguments
10$:
	;
	;
	;
	popf
	jnz	20$				;vertical, branch
	mov	dx, cx				;else rewrap
20$:
	ret
OLScrollListGetExtraSize	endm
endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListRecalcItemSize -- 
		MSG_OL_SLIST_RECALC_ITEM_SIZE for OLScrollListClass

DESCRIPTION:	Calcs a size for an item.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_SLIST_RECALC_ITEM_SIZE

RETURN:		cx, dx  - item size

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
		if OLSLS_VERTICAL
			size = contentWidth/wrapCount, itemLength
		else
			size = itemLength, contentHeight/wrapCount

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/11/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListRecalcItemSize	method OLScrollListClass, \
				MSG_OL_SLIST_RECALC_ITEM_SIZE

	call	GetViewWinSize			;returns win size in cx, dx
	call	LUG_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	horiz				;vertical, we'll use width
	mov	cx, dx				;else we'll use height
horiz:

	;
	; Content dimension to use in cx.  We'll divide it by the wrap count.
	;
	call	GetWrapCount			;ax <- wrap count
	mov_tr	bx, ax				;leave in bx
	mov_tr	ax, cx				;content size in ax
	clr	dx				;now in dx:ax
	div	bx				;result in ax
	mov_tr	cx, ax				;move back to cx

	call	LUG_DerefVisDI
	mov	dx, ds:[di].OLSLI_itemLength	;get item length in dx

	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	exit				;vertical, done, content width
						;  in cx, item length in dx

	xchg	cx, dx				;content height in dx, item
						;  length in dx for horizontal
exit:
	ret
OLScrollListRecalcItemSize	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetViewWinSize

SYNOPSIS:	Returns size of view window.

CALLED BY:	OLScrollListRecalcItemSize, OLScrollListNumItemsChanged

PASS:		*ds:si -- scrolling list

RETURN:		cx, dx -- view window size

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/18/92		Initial version

------------------------------------------------------------------------------@
GetViewWinSize	proc	near

	push	si
	call	VisFindParent			;content in *ds:si
EC <	cmp	bx, ds:[LMBH_handle]		;assumption of content	>
EC <	ERROR_NE	OL_ERROR		;   in same block	>

	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	mov	cx, ds:[si].VCNI_viewWidth
	mov	dx, ds:[si].VCNI_viewHeight	
	pop	si				;*ds:si = scroll list

	ret
GetViewWinSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollListNumItemsChanged -- 
		MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED for OLScrollListClass

DESCRIPTION:	Returns minimum size. 

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED
		cx	- number of items in dynamic list

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/17/92		Initial Version

------------------------------------------------------------------------------@
OLScrollListNumItemsChanged	method dynamic	OLScrollListClass, \
				MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED

EC <	test	ds:[di].OLIGI_state, mask OLIGS_DYNAMIC			>
EC <	ERROR_Z	OL_ERROR						>

	tst	ds:[di].VCI_window		;no gwin yet, exit
	jz	exit

	;
	; Divide total of items by the wrap count, rounding up if any remainder,
	; to get the "length" of the list (it still remains to be seen whether
	; this is a width or a length).
	;
	mov	bp, cx
	call	GetWrapCount			;wrap count in ax
	xchg	ax, bp
	clr	dx				;num items in dx:ax, wrap in bp
	div	bp				;num lines of items now in ax

	tst	dx				;see if remainder
	jz	5$
	inc	ax
5$:

	;
	; The "width" of the list is the size of the window.  On vertical lists,
	; we'll actually use the window width; on horizontal lists, the window
	; height.
	;
	mov	bp, ds:[di].OLSLI_itemLength	;get length of an item
	mul	bp				;multiply, result in dx:ax
	mov	bp, dx				;now in bp:ax
	call	GetViewWinSize			;returns win size in cx, dx

	;
	; If vertical we're set; otherwise we put the "length" of the list in
	; the right place.
	;
	clr	bx				;assume vertical:
						;  width in bx.cx
						;  height in bp.ax
	call	LUG_DerefVisDI
	test	ds:[di].OLSLI_attrs, mask OLSLA_VERTICAL
	jnz	10$				;vertical, branch
;horiz:
	mov	cx, dx				;use content height, not width
	xchgdw	bxcx, bpax			;and swap stuff
10$:
	mov	dx, bp				;height now in dx.ax

	;
	; Got our list dimensions.  Set the view's doc bounds appropriately.
	;
	sub	sp, size RectDWord		;set up parameters
	mov	bp, sp
	movdw	ss:[bp].RD_right, bxcx		;right edge
	movdw	ss:[bp].RD_bottom, dxax		;bottom 
	clrdw	ss:[bp].RD_left			;origin at 0,0
	clrdw	ss:[bp].RD_top
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS	;set new document size
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].OLSLI_view
	call	ObjCallInstanceNoLock
	add	sp, size RectDWord
exit:
	ret
OLScrollListNumItemsChanged	endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollListGrabFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the focus to this object.

PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_META_GRAB_FOCUS_EXCL.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/89	Initial version
	chris	8/31/93		Changed so we *and* our view grab the focus.
				Previously only the view grabbed the focus.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLScrollListGrabFocusExcl	method dynamic OLScrollListClass, \
						MSG_META_GRAB_FOCUS_EXCL

	;
	; We'll grab it first.	
	;
	call	MetaGrabFocusExclLow

	;
	; Have the view grab the focus if there is one.
	;
	call	LUG_DerefVisDI
	mov	si, ds:[di].OLSLI_view	; any view?
	tst	si
	jz	exit			
	call	MetaGrabFocusExclLow	
exit:
	ret
OLScrollListGrabFocusExcl	endm

LessUsedGeometry	ends
