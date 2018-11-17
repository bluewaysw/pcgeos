COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific UIs)
FILE:		copenScrollableItem.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLScrollableItemClass	Scrollableing list item class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Clayton	7/89		Initial version
	Eric	4/90		New USER/ACTUAL exclusive usage, extended
				selection, cleanup.

DESCRIPTION:
	$Id: citemScrollableItem.asm,v 1.2 98/03/11 05:54:40 joon Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

OLScrollableItemClass:

Synopsis
--------
	NOTE: The section between "Declaration" and "Methods declared" is
	      copied into uilib.def by "pmake def"

State Information
-----------------

Declaration
-----------

OLScrollableItemClass	class OLItemClass
	uses	GenItemClass

OLScrollableItemClass	endc

Methods declared
----------------

Methods inherited
-----------------

Additional documentation
------------------------

------------------------------------------------------------------------------@
;USE_VIS_ATTR_FLAGS	= 0

CommonUIClassStructures segment resource

	OLScrollableItemClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------


GadgetBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemInitialize -- MSG_META_INITIALIZE for
			OLScrollableItemClass

DESCRIPTION:	Initialize item ctrl from a Generic Group object

PASS:
	*ds:si - instance data
	es - segment of OlMenuClass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
OLScrollableItemInitialize	method private static OLScrollableItemClass, \
							MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
					; Grow out vis

					; Do superclass init
	mov	di, segment OLScrollableItemClass
	mov	es, di
	mov	di, offset OLScrollableItemClass
	CallSuper MSG_META_INITIALIZE

	;Set ScrollableItem instance data

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; This single object becomes entire
					; visual representation, so set
					; optimization bit.
	ornf	ds:[di].VI_specAttrs, mask SA_SIMPLE_GEN_OBJ

if SCROLL_LIST_GRID_LINES_AND_SPACING
	; Check for grid line hints on parent and set item flags

	push	si
	call	GenSwapLockParent
	push	bx

	mov	ax, HINT_ITEM_GROUP_GRID_LINES
	call	ObjVarFindData
	jnc	unlock

	mov	ax, {ScrollListGridState}ds:[bx]
	mov	ds:[di].OLSII_gridState, ax
unlock:
	pop	bx
	call	ObjSwapUnlock
	pop	si
endif	; SCROLL_ITEM_GRID_LINES_AND_SPACING

done:
EC<	call	ECScrollableItemCompField	; Make sure there's no junk in comp >
	.leave
	ret
OLScrollableItemInitialize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemSpecBuild -- 
		MSG_SPEC_BUILD for OLScrollableItemClass

DESCRIPTION:	Builds out an item.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/13/92		Initial Version

------------------------------------------------------------------------------@

OLScrollableItemSpecBuild	method dynamic	OLScrollableItemClass, 
				MSG_SPEC_BUILD
	mov	di, offset OLScrollableItemClass
	call	ObjCallSuperNoLock

	; Turn off this fine optimization, since the item's size sometimes
	; depends on the size of the window.  If the item group does not pass
	; a new size to the item, MSG_VIS_RECALC_SIZE won't get called anyway.
	; (Always recalc size has to be turned on for the same reason, it 
	;  seems.  Otherwise, when the window is resized, the item group 
	;  passes desired, gets the old size back, and is never motivated to
	;  change.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
	ornf	ds:[di].VI_geoAttrs, mask VGA_ALWAYS_RECALC_SIZE

	; Calculate the size of the item, in case we're in a dynamic list and
	; will never receive a geometry update.
	;
	mov	ax, MSG_OL_SLIST_RECALC_ITEM_SIZE
	call	VisCallParent
	call	VisSetSize
	ret
OLScrollableItemSpecBuild	endm

GadgetBuild ends

Geometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLScrollableItemClass

DESCRIPTION:	Returns the size of the item.  This is always determined by
		the scroll list, unless passed zeros by the scroll list to get
		its minimum size (zeroes are passed to differentiate it from 
		normal geometry manager functions.)

PASS:		*ds:si - instance data
		es - segment of OLScrollableItemClass
		di - MSG_VIS_GET_SIZE
		cx - width info for choosing size
		dx - height info

RETURN:		cx - width to use
		dx - height to use

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version (button?)
	Clayton	8/89		Initial version

------------------------------------------------------------------------------@
OLScrollableItemRecalcSize	method private static 	OLScrollableItemClass, 
							MSG_VIS_RECALC_SIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	tst	cx			; both cx and dx are zero, choose
	jnz	getFromParent		;  our own size.  Else get from the
	tst	dx			;  parent list, who knows all.
	jz	calcDesired		

getFromParent:				; else let scroll list determine size
	mov	ax, MSG_OL_SLIST_RECALC_ITEM_SIZE
	call	VisCallParent		
	jmp	short exit

calcDesired:
	segmov	es, ds
EC <	call	GenCheckGenAssumption	; Make sure gen data exists 	>
	call	Geo_DerefGenDI
	mov	di, ds:[di].GI_visMoniker	; fetch moniker
	clr	bp			;get have no GState...
	call	SpecGetMonikerSize	;get size of moniker
OLS <	add	cx, SCROLL_ITEM_INSET_X*2				>
OLS <	add	dx, SCROLL_ITEM_INSET_X*2				>

if _CUA_STYLE
	add	cx, MO_SCROLL_ITEM_INSET_X*2
	add	dx, MO_SCROLL_ITEM_INSET_Y*2
endif

CUAS <	call	AddExtraSpaceIfInMenu	;add extra to cx if menu	>
CUAS <	call	AddExtraSpaceIfInMenu					>

if SCROLL_LIST_GRID_LINES_AND_SPACING
	call	AddGridLineSpacingIfNeeded
endif
   
OLS <	mov	ax, BUTTON_MIN_WIDTH	;minimum width		        >
CUAS <	mov	ax, CUAS_SCROLL_ITEM_MIN_WIDTH				>

	cmp	cx, ax			;avoid making too small
	jae	exit
	mov_tr	cx, ax
exit:
	.leave
	ret

OLScrollableItemRecalcSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLScrollableItemClass

DESCRIPTION:	Returns the extra size of the object (without the moniker).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx  - extra size of scroll item

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@
OLScrollableItemGetExtraSize	method	OLScrollableItemClass, \
					MSG_SPEC_GET_EXTRA_SIZE
if _CUA_STYLE
	mov	cx, MO_SCROLL_ITEM_INSET_X*2
	mov	dx, MO_SCROLL_ITEM_INSET_Y*2
endif

CUAS <	call	AddExtraSpaceIfInMenu	;add extra to cx if menu	>
CUAS <	call	AddExtraSpaceIfInMenu					>

if SCROLL_LIST_GRID_LINES_AND_SPACING
	call	AddGridLineSpacingIfNeeded
endif
	ret
OLScrollableItemGetExtraSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGridLineSpacingIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this scrolling list has grid lines, then we may need to
		add some additional spacing
CALLED BY:	OLScrollableItemRecalcSize, OLScrollableItemGetExtraSize
PASS:		*ds:si	= OLScrollableItemClass
		cx, dx	= size
RETURN:		cx, dx	= with gridline spacing added if needed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

AddGridLineSpacingIfNeeded	proc	near
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLSII_gridState
	mov	ax, di
	andnf	di, mask SLGS_VGRID_SPACING
	add	cx, di
	andnf	ax, mask SLGS_HGRID_SPACING
	xchg	al, ah
	add	dx, ax

	.leave
	ret
AddGridLineSpacingIfNeeded	endp

endif

Geometry ends

ItemCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLScrollableItemClass

DESCRIPTION:	Returns the position of its moniker.

PASS:		*ds:si - instance data
		es - segment of OLScrollableItemClass
		ax - MSG_GET_FIRST_MKR_POS
		
RETURN:		carry set, saying method was handled
		ax, cx -- position of moniker

DESTROYED:	dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 1/89	Initial version 

------------------------------------------------------------------------------@
OLScrollableItemMkrPos	method	OLScrollableItemClass, MSG_GET_FIRST_MKR_POS

	test	ds:[di].VI_attrs, mask VA_VISIBLE	; test clears carry
	jz	exit					; not visible, get out.
	
	segmov	es, ds, cx
	mov	cx, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST) 
	clr	bp				;no gstate
	
if _CUA_STYLE	;--------------------------------------------------------------
	mov	bx, si		;pass gen chunk in es:bx (same as ds:si here)

	;yes, this takes time, but we MUST now pass OpenMonikerArgs on the
	;stack to OpenGetMonikerPos

	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	call	OLItemSetupMkrArgs		;set up arguments for moniker

	mov	dx, (MO_MENU_BUTTON_INSET_Y shl 8) or MO_MENU_BUTTON_INSET_X
	mov	ss:[bp].OMA_drawMonikerFlags, (J_LEFT shl offset DMF_X_JUST) or \
		    			 (J_CENTER shl offset DMF_Y_JUST) 
	call	OpenGetMonikerPos
EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>
	add	sp, size OpenMonikerArgs
endif		;--------------------------------------------------------------

	mov	cx, bx				;return y pos in cx
	tst	ax
	jz	exit				;no moniker, exit (c = 0)
	stc					;say handled
exit:
	ret

OLScrollableItemMkrPos	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemDraw -- MSG_VIS_DRAW for OLScrollableItemClass

DESCRIPTION:	Draw the scroll item.

PASS:		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_VIS_DRAW
		cl - DrawFlags:  DF_EXPOSED set if updating
		bp - GState to use

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
	Call the correct draw routine based on the display type:

	if (black & white) {
		DrawBWItem();
	} else {
		DrawColorItem();
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@
OLScrollableItemDraw	method OLScrollableItemClass, MSG_VIS_DRAW

EC <	call	VisCheckVisAssumption	; Make sure vis data exists >
EC <	call	GenCheckGenAssumption	; Make sure gen data exists >
EC<	call	ECScrollableItemCompField	; Make sure there's no junk in comp >
	call	ClearNavigateFlagsIfValid	;clear this if needed

	;If not realized, don't try & draw. This is needed because ScrollList
	;calls children to draw directly, not through VisCompDraw.

	call	IC_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	drawItem
exit:
	ret

drawItem:

if SCROLL_LIST_GRID_LINES_AND_SPACING
	; Ugly hack.  We temporarily adjust the item bounds so it'll draw
	; inside the grid lines with the grid spacing we want for the item.

	push	ds:[di].VI_bounds.R_left
	push	ds:[di].VI_bounds.R_top
	push	ds:[di].VI_bounds.R_right
	push	ds:[di].VI_bounds.R_bottom
	call	OLScrollableItemSetGridBounds
endif

	; SAVE BYTES: have color flag already!
	; get display scheme data

	segmov	es, ds, di
	push	bp			;Save the GState
	mov	di, bp			;put GState in di

if not _ASSUME_BW_ONLY	;------------------------------------------------------

	push	cx			;save DrawFlags
	mov	ax, GIT_PRIVATE_DATA
	call	GrGetInfo		;returns ax, bx, cx, dx
	pop	cx

	; al = color scheme, ah = display type, cl = update flag
	; *ds:si = OLItem object

	andnf	ah, mask DF_DISPLAY_TYPE
	cmp	ah, DC_GRAY_1
	mov	ch, cl			;Pass DrawFlags in ch
	mov	cl, al			;Pass color scheme in cl

OLS <	jne	color			;skip if on color screen...	>
MO <	jne	color			;skip if on color screen...	>
ISU <	jne	color			;skip if on color screen...	>

endif	; not _ASSUME_BW_ONLY	-----------------------------------------------

	; draw black & white

	CallMod	DrawBWScrollableItem

if _OL_STYLE or _MOTIF or _ISUI ;---------------------------------------------
	jmp	short common

if not _ASSUME_BW_ONLY
color:	;draw color item
	CallMod	DrawColorScrollableItem
endif
endif	; _OL_STYLE or _MOTIF or _ISUI ---------------------------------------

;SAVE BYTES here. Do calling routines do this work for us?

common:
	pop	di				; Restore the GState
	mov	bx, ds:[si]			; Check if the item is 
	add	bx, ds:[bx].Vis_offset		;    enabled.

if SCROLL_LIST_GRID_LINES_AND_SPACING
	; undo the vis bounds adjustment we made for grid lines and spacing

	pop	ds:[bx].VI_bounds.R_bottom
	pop	ds:[bx].VI_bounds.R_right
	pop	ds:[bx].VI_bounds.R_top
	pop	ds:[bx].VI_bounds.R_left
endif

	test	ds:[bx].VI_attrs, mask VA_FULLY_ENABLED
	jnz	updateState			; If so, exit

	mov	al, SDM_100			; If not, reset the draw masks
	call	GrSetAreaMask			;    to solid
	call	GrSetLineMask
	call	GrSetTextMask

updateState:
	call	UpdateItemState

	ret
OLScrollableItemDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollableItemSetGridBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bounds of this object adjusted for grid spacing

CALLED BY:	DrawColorScrollableItemGridLines
PASS:		*ds:si	= OLScrollableItemClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

OLScrollableItemSetGridBounds	proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].OLSII_gridState	; bp <- ScrollListGridState
	tst	bp				; anything to adjust?
	jz	done				; exit if nothing

	call	VisGetBounds			; get item bounds

	push	ax
	mov	ax, bp				; ax <- ScrollListGridState
	andnf	ax, mask SLGS_HGRID_SPACING	; ah <- horiz grid spacing
	xchg	al, ah				; ax <- horiz grid spacing
	shr	ax, 1				; ax <- 1/2 horiz grid spacing
	pushf
	sub	dx, ax				; move bottom up by 1/2 horiz
	popf
	adc	bx, ax				; move top down by 1/2 horiz
	pop	ax

	andnf	bp, mask SLGS_VGRID_SPACING	; bp <- vert grid spacing
	shr	bp, 1				; bp <- 1/2 vert grid spacing
	pushf
	sub	cx, bp				; move right over by 1/2 vert
	popf
	adc	ax, bp				; move left over by 1/2 vert

	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_top, bx
	mov	ds:[di].VI_bounds.R_right, cx
	mov	ds:[di].VI_bounds.R_bottom, dx
done:
	.leave
	ret
OLScrollableItemSetGridBounds	endp

endif	; SCROLL_LIST_GRID_LINES_AND_SPACING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawScrollableItemGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw grid lines around the item

CALLED BY:	DrawColorScrollableItem
PASS:		*ds:si	= OLItemClass object
		di	= GState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SCROLL_LIST_GRID_LINES_AND_SPACING

DrawScrollableItemGridLines	proc	far
	uses	ax, bx, cx, dx, bp
	.enter

	; Draw grid lines if needed

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	mov	bp, ds:[bp].OLSII_gridState
	test	bp, mask SLGS_HGRID_LINES or mask SLGS_VGRID_LINES
	jz	done

	mov	ax, C_BLACK
	call	GrSetLineColor			; grid lines are always black

	; We need to deal with the case where the grid lines of adjacent items
	; are suppose to overlap each other.  So we make each item draw the
	; top or left grid line one pixel up or to the left.  But we can't do
	; that for the topItem because moving up one pixel will put us outside
	; the bounds of the scrolling view.

	mov	ax, MSG_OL_SLIST_GET_SLIST_ATTRS
	call	VisCallParent			; cl = OLScrollListAttrs

	mov	ax, bp				; al = vGrid, ah = hGrid
	test	cl, mask OLSLA_VERTICAL
	jz	checkSpacing
	mov	al, ah				; al = hGrid

checkSpacing:
	test	al, mask SLGS_VGRID_SPACING	; grid line spacing ?= 0
	jnz	drawNormal			; draw normal if !overlapping

	push	cx, bp
	mov	ax, MSG_OL_SLIST_GET_TOP_ITEM
	call	VisCallParent
	mov	ax, ds:[LMBH_handle]
	cmpdw	axsi, cxdx			; are we the topItem?
	pop	cx, bp
	je	drawTopItem			; draw topItem

drawNormal:
	test	cl, mask OLSLA_VERTICAL
	pushf
	call	OpenGetLineBounds		; (ax,bx) - (cx,dx)
	popf
	jnz	verticalList

horizontalList:					; horizontal list
	dec	ax				; move left over one pixel
	jmp	drawGridLines

verticalList:					; vertical list
	dec	bx				; move up one pixel
	jmp	drawGridLines

drawTopItem:
	call	OpenGetLineBounds

drawGridLines:
	test	bp, mask SLGS_HGRID_LINES	; check horiz grid lines
	jz	doVert

	call	GrDrawHLine			; draw grid line
	xchg	bx, dx
	call	GrDrawHLine			; draw grid line
	xchg	bx, dx
doVert:
	test	bp, mask SLGS_VGRID_LINES	; check vert grid lines
	jz	done

	call	GrDrawVLine			; draw grid line
	mov	ax, cx
	call	GrDrawVLine			; draw grid line
done:
	.leave
	ret
DrawScrollableItemGridLines	endp

endif	; SCROLL_LIST_GRID_LINES_AND_SPACING


COMMENT @----------------------------------------------------------------------

ROUTINE:	ClearNavigateFlagsIfValid

SYNOPSIS:	Turns off navigate flags if our object's moniker has become 
		valid.

CALLED BY:	OLScrollableItemDraw

PASS:		*ds:si -- item

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/24/92		Initial version

------------------------------------------------------------------------------@
ClearNavigateFlagsIfValid	proc	near

	call	IC_DerefVisDI
	test	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
	jnz	exit				;moniker still invalid, branch

	andnf	ds:[di].OLII_state, not (mask OLIS_NAVIGATE_IF_DISABLED or \
					 mask OLIS_NAVIGATE_BACKWARD)
exit:
	ret
ClearNavigateFlagsIfValid	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLScrollableItemClass

DESCRIPTION:	Handles update of monikers.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER
		dx	- VisUpdateMode

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/14/92		Initial Version

------------------------------------------------------------------------------@
OLScrollableItemUpdateVisMoniker	method dynamic	OLScrollableItemClass, 
				MSG_SPEC_UPDATE_VIS_MONIKER
	call	VisCheckIfSpecBuilt
	jnc	done

	;
	; Only consider the no-update optimization if the moniker is currently
	; invalid, and we're guaranteed to get a mass redraw later. 5/25/93 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLII_state, mask OLIS_MONIKER_INVALID
	jz	doUpdate			
	;
	; This seems to improve performance dramatically, but who knows if
	; it really works.  -cbh 5/13/93
	;
	call	VisCheckIfFullyEnabled
	jc	done				;done, redraw after all items
						;  are invalidated will catch
						;  the draw.
doUpdate:
	;
	; Avoid nasty geometry being redone.  (Disabled items seem to need
	; the invalidate to guarantee the old moniker is fully erased.)
	;
	mov	dl, VUM_NOW			;we can update things NOW
	mov	cl,mask VOF_IMAGE_INVALID	;CL <- what to mark invalid
	GOTO	VisMarkInvalid			; Mark object image as invalid
done:
	ret
OLScrollableItemUpdateVisMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemSetUseColorIfDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets AX = the appropriate color for the object if it is
		disabled.

CALLED BY:	DrawColorScrollableItem
PASS:		*ds:si - instance data for OLScrollableItem object
		ax = enabled color
RETURN:		ax = new disabled color, if disabled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Currently distinguishes 3 states of the item, resulting
	in 3 distinct color schemes:

		1) Enabled
		2) Disabled & cursored
		3) Disabled & not cursored


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	12/29/94    	Initial version
	cthomas	5/16/96		Distinguish selected/non-selected cases

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if USE_COLOR_FOR_DISABLED_GADGETS

OLItemSetUseColorIfDisabled	proc	far
	uses	di
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	exit			;skip if is enabled...
	mov	ax, DISABLED_COLOR	; assume not selected

	;
	; Distinguish non-enabled + selected vs. non-enabled non-selected
	;
	test	ds:[di].OLII_state, mask OLIS_SELECTED
	jz	exit
	mov	ax, DISABLED_CURSORED_COLOR
exit:
	.leave
	ret
OLItemSetUseColorIfDisabled	endp

endif	; USE_COLOR_FOR_DISABLED_GADGETS

ItemCommon	ends

DrawBW segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWScrollableItem

DESCRIPTION:	Draw an OLScrollableItemClass object on a black & white display.

CALLED BY:	OLScrollableItemDraw

PASS:		*ds:si	- instance data
		ch	- DrawFlags:  DF_EXPOSED set if updating
		di	- GState to use

RETURN:		*ds:si	- same

DESTROYED:	ax, bx, cx, dx, di, bp

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	2/89	Initial version
	Eric	3/90	cleanup

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _ISUI

DrawBWScrollableItem	proc	far
	class	OLScrollableItemClass
	
EC <	call	VisCheckVisAssumption	;Make sure vis data exists	>

	call	OLItemGetGenAndSpecState
					;sets:	bh = OLBI_specState (low byte)
					;	cl = OLBI_optFlags
					;	dl = GI_states
					;	dh = OLII_state

	mov	ax, C_WHITE
	call	GrSetAreaColor
	mov	ax, C_BLACK
if USE_COLOR_FOR_DISABLED_GADGETS
	call	OLItemSetUseColorIfDisabled
endif
	call	GrSetTextColor		; DrawBWScrollableItemBackground sets
	call	GrSetLineColor		;   these later.  What's the point?

if _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50

	;set the draw masks to 50% if this object is disabled

	mov	al, SDM_50		;Use a 50% mask 
	call	OLItemSetMasksIfDisabled
;	jnz	10$
;10$:
endif

	;if this is a MSG_META_EXPOSED event, then force a full redraw.

	test	ch, mask DF_EXPOSED
	jnz	fullRedraw		;skip if so...

	test	cl, mask OLBOF_DRAW_STATE_KNOWN
	jz	fullRedraw		;skip if have no old state info...

	;this is not a MSG_META_EXPOSED event. So some status flag(s) in this
	;item object have changed. Compare old vs. new state to see what
	;has changed

	clr	ch			;default flag: is not FULL REDRAW
	mov	al, bh			;get OLBI_specState
	xor	al, cl			;compare to OLBI_optFlags

	push	di			;can I trash this?  Who knows.
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	mov	ah, ds:[di].VI_attrs	;get VI_attrs
	xor	ah, cl			;compare to OLBI_optFlags
	test	ah, mask VA_FULLY_ENABLED	
	pop	di
	jz	drawCommon		;skip if same enabled status...

deltaEnabledStatus:
	;the ENABLED status has changed. If that is all that changed,
	;then just wash over this object with a 50% pattern, making it
	;look as if we redrew it with 50% masks.

	test	al, OLBOF_STATE_FLAGS_MASK
	jnz	fullRedraw		;if any other flags changed,
					;force a full redraw...

if _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50
	call	CheckIfJustDisabled
	jnc	fullRedraw		;going enabled, branch to do it

	push	ax
	mov	al, mask SDM_INVERSE or SDM_50	;Use inverse of 50% mask 
	mov	ch, TRUE
	call	OLItemWash50Percent
	pop	ax
	jmp	short done		;skip if washed object...
					;(bx, cx, dx trashed if so)
endif

fullRedraw:
	;we must fully redraw this object, including the background

	mov	ch, TRUE

drawCommon:
	;regs:
	;	al = flags which have changed
	;	bh = OLBI_specState (low byte)
	;	cl = OLBI_optFlags
	;	ch = TRUE if is full redraw
	;	dh = OLII_state
	;Yes, we could have plenty of optimizations here in the future, to
	;handle transitions between specific states. But since we are running
	;out of memory and not processor speed, punt!

	call	DrawBWScrollableItemBackground

drawMoniker:
	test	dh, mask OLIS_MONIKER_INVALID
	jnz	abort			;skip if invalid...

	test	dl, mask GS_USABLE
	jz	abort			;skip if not usable...
	;
	; Set the area color to be used by monochrome bitmap monikers
	;
	mov	ax, C_BW_GREY		;Use 50% pattern if disabled
	call	OLScrollableItemSetAreaColorBlackIfEnabled
					;set AreaColor C_BLACK or dark color.
	;
	; call routine to determine which accessories to draw with moniker
	;
	mov	al, cl			;pass al = OLBI_optFlags
	mov	dh, bh			;set dh = OLBI_specState
	call	OLButtonSetupMonikerAttrs
					;returns cx = OLMonikerAttrs
					;does not trash ax, dx, di

if _KBD_NAVIGATION	;------------------------------------------------------
	;
	; if selection cursor is on this object, have the dotted line drawn
	; just inside the bounds of the object (taking clipping into account).
	;	(cx = OLMonikerAttrs)

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	90$			;skip if not...

	ornf	cx, mask OLMA_USE_LIST_SELECTION_CURSOR

	;
	; CUA/Motif: Pass color info in OLMonikerFlags so that 
	; OpenDrawMoniker knows how to draw the selection cursor.
	;
	test	dh, mask OLBSS_SELECTED	;is item ON?
	jz	90$			;skip if not...

	ornf	cx, mask OLMA_BLACK_MONOCHROME_BACKGROUND
					; pass flag indicating that we are
					; drawing over a C_BLACK area, so to 
					; draw selection cursor, use C_WHITE. 
					; To erase, use C_BLACK.
90$:
endif	; _KBD_NAVIGATION ------------------------------------------------------

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST) or \
		mask DMF_CLIP_TO_MAX_WIDTH

OLS <	mov	dx, SCROLL_ITEM_INSET_X		;left and right inset	>
						;(top and bottom = 0)
CUAS <	mov	dx, MO_SCROLL_ITEM_INSET_X	;left and right inset	>
						;(top and bottom = 0)

CUAS <	xchg	cx, dx							>
CUAS <	call	AddExtraSpaceIfInMenu		;adds space to cx	>
CUAS <	xchg	cx, dx							>

					;pass al = DrawMonikerFlags,
					;cx = OLMonikerAttrs
	call	OLButtonDrawMoniker	;draw moniker
done:
	ret

;NOTE: CLAYTON: IS THIS OK WHEN OBJECT IS NOT USABLE?

abort:	;Moniker isn't valid, so erase the entry.
OLS <	mov	ax, C_WHITE						>
CUAS<	mov	ax, C_WHITE						>
	call	GrSetAreaColor
	call	VisGetBounds			; Get bounds to draw everything
	call	GrFillRect

	ret
DrawBWScrollableItem	endp

endif	; _OL_STYLE or _MOTIF or _ISUI


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWScrollableItemBackground

DESCRIPTION:	This procedure draws a black and white scroll item.

CALLED BY:	DrawBWScrollableItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if must redraw item
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		some code from old DrawBWScrollItem
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _ISUI

DrawBWScrollableItemBackground	proc	near
	uses	ax, bx, cx, dx, bp
	.enter
	;
	; The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	; update the item image according to the new SELECTED state.
	;
	test	dh, mask OLIS_MONIKER_INVALID
	jnz	notSelected		;draw in white if moniker is invalid

	test	bh, mask OLBSS_SELECTED
	jz	notSelected		

selected:
	;
	; draw background in dark (selected) color
	;
	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect

	mov	ax, C_WHITE		; Use white as text color 
if USE_COLOR_FOR_DISABLED_GADGETS
	call	OLItemSetUseColorIfDisabled
endif
	call	GrSetTextColor		;   for item that are "on"
	call	GrSetLineColor
	jmp	short done

notSelected:
	mov	ax, C_WHITE
	call	GrSetAreaColor
OLS <	call	GrSetLineColor						>
	call	VisGetBounds
	call	GrFillRect
OLS <	dec	cx				;adjust for lines	>
OLS <	dec	dx							>
OLS <	call	GrDrawRect						>

done:
	.leave
	ret
DrawBWScrollableItemBackground	endp

endif	; _OL_STYLE or _MOTIF or _ISUI

DrawBW ends

DrawColor segment resource

if not _ASSUME_BW_ONLY


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorScrollableItem

DESCRIPTION:	Draw an OLScrollableItemClass object on a color display.

CALLED BY:	OLScrollableItemDraw (OpenLook and Motif cases only)

PASS:		*ds:si - instance data for OLScrollableItem object
		cl - color scheme
		ch - DrawFlags:  DF_EXPOSED set if updating
		di - GState to use

RETURN:		*ds:si = same

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	3/90		cleanup

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _ISUI	;-------------------------------

DrawColorScrollableItem	proc	far
	class	OLScrollableItemClass
	
EC <	call	VisCheckVisAssumption	;Make sure vis data exists	>

	mov	bp, cx			;Save DrawFlags and color scheme

	call	OLItemGetGenAndSpecState
					;sets:	bl = OLBI_behavior
					;	bh = OLBI_specState (low byte)
					;	cl = OLBI_optFlags
					;	dl = GI_states
					;	dh = OLII_state

	push	bx
if ITEM_USES_BACKGROUND_COLOR
	;
	; use parent text color, as we do for background color
	;
	call	OpenGetParentTextColor
else
	call	OpenGetTextColor	; use hint text color if there
endif
	mov	bx, C_BLACK
	jnc	10$
	clr	bx
	mov	bl, al
10$:
	mov	ax, bx
	pop	bx

if USE_COLOR_FOR_DISABLED_GADGETS
	call	OLItemSetUseColorIfDisabled
endif
	call	GrSetTextColor
	call	GrSetLineColor

	;set the draw masks to 50% if this object is disabled
	;(Experimentation 9/ 7/93 cbh:  move this further down so background
	; draws aren't done in a 50% pattern.)  (Integrated for V2.1 1/24/94)

if 0			
	mov	al, SDM_50
	call	OLItemSetMasksIfDisabled
endif

	;if this is a MSG_META_EXPOSED event, then force a full redraw.

	test	ch, mask DF_EXPOSED
	jnz	fullRedraw		;skip if so...

	test	cl, mask OLBOF_DRAW_STATE_KNOWN
	jz	fullRedraw		;skip if have no old state info...

	;this is not a MSG_META_EXPOSED event. So some status flag(s) in this
	;item object have changed. Compare old vs. new state to see what
	;has changed

	clr	ch			;default flag: is not FULL REDRAW
	mov	al, bh			;get OLBI_specState
	xor	al, cl			;compare to OLBI_optFlags

	push	di			;can I trash this?  Who knows.
	mov	di, ds:[si]		;point to instance
	add	di, ds:[di].Vis_offset
	mov	ah, ds:[di].VI_attrs	;get VI_attrs	
	xor	ah, cl			;compare to OLBI_optFlags
	test	ah, mask VA_FULLY_ENABLED
	pop	di
	jz	drawCommon		;skip if same enabled status...

deltaEnabledStatus:
	;the ENABLED status has changed. If that is all that changed,
	;then just wash over this object with a 50% pattern, making it
	;look as if we redrew it with 50% masks.

	test	al, OLBOF_STATE_FLAGS_MASK
	jnz	fullRedraw		;if any other flags changed,
					;force a full redraw...

if (not USE_COLOR_FOR_DISABLED_GADGETS) and (not ITEM_USES_BACKGROUND_COLOR)
				; not-enabled custom colors need full redraw
	call	CheckIfJustDisabled
	jnc	fullRedraw		;going enabled, branch to do it

	push	ax
	call	GetLightColor		;ax <- use light color
	call	GrSetAreaColor
	mov	al, mask SDM_INVERSE or SDM_50	;Use inverse of 50% mask 
	mov	ch, TRUE		; signal color item
	call	OLItemWash50Percent
	pop	ax
	jmp	done		;exit
endif

	;must have changed from DISABLED to ENABLED: fall through
	;to force a full redraw.

fullRedraw:
	;we must fully redraw this object, including the background

	mov	ch, TRUE

drawCommon:
	;draw the background for the list item
	;	al = flags which have changed
	;	bh = OLBI_specState (low byte)
	;	cl = OLBI_optFlags
	;	ch = TRUE if is full redraw
	;	dh = OLII_state

	call	DrawColorScrollableItemBackground

if SCROLL_LIST_GRID_LINES_AND_SPACING
	call	DrawScrollableItemGridLines
endif

	;set the draw masks to 50% if this object is disabled
	;(Moved here  9/ 7/93 cbh)  (Integrated for V2.1 1/24/94 cbh)

if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, SDM_50
	call	OLItemSetMasksIfDisabled
endif

drawMoniker:
	;Set the area color to be used by monochrome bitmap monikers
	;regs:	*ds:si	= object
	;	bh	= OLBI_specState (low byte)
	;	cl	= OLBI_optFlags
	;	dl	= GI_states
	;	dh	= OLII_state
	;	bp	= DrawFlags, ColorScheme
	;	di	= GState

	test	dh, mask OLIS_MONIKER_INVALID
	LONG jnz	done

	test	dl, mask GS_USABLE
	LONG jz	done

	;Set the area color to be used by monochrome bitmap monikers

if USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, DISABLED_COLOR	;assume DISABLED_COLOR for
					;bitmap if not enabled
else
	call	GetDarkColor		;assume dark color for bitmap
					;if is not enabled
endif
	call	OLScrollableItemSetAreaColorBlackIfEnabled
					;set AreaColor C_BLACK or dark color.

	;call routine to determine which accessories to draw with moniker

	mov	al, cl			;pass al = OLBI_optFlags
	mov	dh, bh			;set dh = OLBI_specState
	call	OLButtonSetupMonikerAttrs
					;returns cx = info.
					;does not trash ax, dx, di

if _KBD_NAVIGATION	;------------------------------------------------------
	;decide whether selection cursor must be drawn
	;(al = OLBI_optFlags)

	call	OLButtonTestForCursored	;in Resident resource (does not trash dx

if CURSOR_ON_BACKGROUND_COLOR
	;
	; Since we do a full redraw if the cursor turns off, we don't
	; need to erase cursor in this case.
	;
	test	al, mask OLBOF_DRAWN_CURSORED
	jz	notCursorOff
	test	bx, mask OLBSS_CURSORED
	jnz	notCursorOff
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR and \
			mask OLMA_SELECTION_CURSOR_ON)
notCursorOff:
endif

	;if selection cursor is on this object, have the dotted line drawn
	;just inside the bounds of the object (taking clipping into account).

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	90$			;skip if not...

	ornf	cx, mask OLMA_USE_LIST_SELECTION_CURSOR

	;CUA/Motif: Pass color info in OLMonikerFlags so that OpenDrawMoniker
	;knows how to draw the selection cursor.

	test	dh, mask OLBSS_SELECTED	;is item ON?
	jnz	85$			;skip if so...
	ornf	cx, mask OLMA_LIGHT_COLOR_BACKGROUND
	jmp	short 90$
85$:
	ornf	cx, mask OLMA_DARK_COLOR_BACKGROUND
90$:

if CURSOR_ON_BACKGROUND_COLOR	;----------------------------------------------

	mov	ax, (1 shl 8)		; use parent unselected color
	test	dh, mask OLBSS_SELECTED	; al non-zero if selected
	jz	3$
	dec	al
3$:
	call	OpenSetCursorColorFlags	; cx = update OLMonikerAttrs

endif	; CURSOR_ON_BACKGROUND_COLOR	;--------------------------------------

endif	; _KBD_NAVIGATION -----------------------------------------------------

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST) or \
		mask DMF_CLIP_TO_MAX_WIDTH

OLS <	mov	dx, SCROLL_ITEM_INSET_X		;pass 4 inset values	>
CUAS <	mov	dx, MO_SCROLL_ITEM_INSET_X	;pass 4 inset values	>

CUAS <	xchg	cx, dx							>
CUAS <	call	AddExtraSpaceIfInMenu		;adds space to cx	>
CUAS <	xchg	cx, dx							>

	;
	; pass al = DrawMonikerFlags, cx = OLMonikerAttrs
	;
	call	OLButtonDrawMoniker	;draw moniker and accessories
done:
	ret
DrawColorScrollableItem	endp

endif	; _OL_STYLE or _MOTIF or _ISUI	---------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorScrollableItemBackground

DESCRIPTION:	This procedure draws a color Toolbox-type item,
		for Motif or OpenLook only. In Motif, this procedure is
		used for toolbox exclusive items; in OpenLook it is
		used for items in a windowm, menu, or toolbox.

CALLED BY:	DrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLII_behavior
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if must redraw item
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		ds, si, di, ax, bx, dx, bp = same
		ch = TRUE if must redraw moniker

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		some code from old DrawColorItem

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _ISUI	;-------------------------------

DrawColorScrollableItemBackground	proc	near
	uses	ax, bx, cx, dx, bp
	.enter

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the item image according to the new SELECTED state.

	;
	; If the moniker is invalid, then erase whatever is there by
	; clearing to the background color.  Also, if it's disabled, we won't
	; show emphasis.   (Can't really do this and avoid blinking when 
	; changing enabled state.  We'll find another way to solve the navigate
	; to disabled item in dynamic list problem.)
	;
;	push	di
;	mov	di, ds:[si]			
;	add	di, ds:[di].Vis_offset
;	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
;	pop	di
;	jz	notSelected
	test	dh, mask OLIS_MONIKER_INVALID
	jnz	drawBackground		; if so, clear out to bg color
	test	bh, mask OLBSS_SELECTED
	jz	notSelected		;skip if item is OFF...

selected:
	;draw background in dark (selected) color.  (Rewrit 2/15/93 cbh)

	mov	al, -1				;pass al non-zero for selected
	call	FillRectWithBGColors

if _OL_STYLE	;--------------------------------------------------------------
   	dec	cx				; adjust for lines
	dec	dx
	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax
	call	GrDrawHLine			; Draw the top/left edges
	call	GrDrawVLine
	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax
	call	DrawBottomRightEdges	; Draw bottom/right edges
endif		;--------------------------------------------------------------

	push	bx
if ITEM_USES_BACKGROUND_COLOR
	;
	; use parent text color, as we do for background color
	;
	call	OpenGetParentTextColor
else
	call	OpenGetTextColor	; use hint text color if there
endif
	mov	bx, C_WHITE
	jnc	10$
	clr	bx
	mov	bl, ah
10$:
	mov	ax, bx
	pop	bx
	call	GrSetTextColor		;   for item that are "on"
	call	GrSetLineColor		; For mnemonics
	jmp	short finishUp

notSelected:
	tst	ch			;is this a full redraw?
	jnz	drawBackground		;skip if not...

	test	cl, mask OLBOF_DRAW_STATE_KNOWN
	jz	70$			;skip if have no old state info...
if CURSOR_ON_BACKGROUND_COLOR
	;
	;
	; If cursor turned off, redraw to support non-standard gadget
	; background colors.
	;
	test	cl, mask OLBOF_DRAWN_CURSORED
	jz	notCursorOff
	test	bh, mask OLBSS_CURSORED
	jz	drawBackground
notCursorOff:
endif
	test	cl, mask OLBOF_DRAWN_SELECTED
	jz	70$			;skip if it wasn't drawn selected

drawBackground:
	;is not an EXPOSE event: clear to background color (Rewrit 2/15/93 cbh)

	clr	ax			;pass ax zero for non-selected
	call	FillRectWithBGColors

70$:	;set up colors to draw moniker

finishUp:
	.leave
	mov	ch, TRUE		; return flag: must redraw moniker
done:
	ret
DrawColorScrollableItemBackground	endp

endif	; _OL_STYLE or _MOTIF or _ISUI  --------------------------------------

endif	; not _ASSUME_BW_ONLY -------------------------------------------------

DrawColor ends

Resident segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECScrollableItemCompField

SYNOPSIS:	Error checking routine that makes sure that nothing appears
		in the GI_comp field of the Scrollableing list item, since it
		never has any children.

PASS:		*ds:si	- instance data of Scrollable item

RETURN:		FATAL ERROR IF GI_comp FIELD IS NONZERO

DESTROYED:	di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

ECScrollableItemCompField	proc	far

	push	ax
	call	Res_DerefGenDI
	mov	ax, ds:[di].GI_comp.handle
	or	ax, ds:[di].GI_comp.chunk
	ERROR_NZ	OL_ERROR_ITEMS_CANNOT_HAVE_GENERIC_CHILDREN
	pop	ax

	ret
ECScrollableItemCompField	endp

endif

OLScrollableItemSetAreaColorBlackIfEnabled	proc	far

	push	di
	call	Res_DerefVisDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	pop	di
	jz	80$			;skip if not enabled
	mov	ax, C_WHITE		;Draw white bitmap moniker, if selected
	test	bh, mask OLBSS_SELECTED
	jnz	80$			;skip if item is ON...
	mov	ax, C_BLACK		;Draw black bitmap moniker
80$:
	call	GrSetAreaColor		;color for b/w bitmap monikers

	ret
OLScrollableItemSetAreaColorBlackIfEnabled	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	AddExtraSpaceIfInMenu

SYNOPSIS:	Adds extra space to cx to compensate for being a popup list.

CALLED BY:	utility

PASS:		*ds:si -- item
		cx -- value to add to

RETURN:		cx -- value, possibly updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/23/92       	Initial version

------------------------------------------------------------------------------@
AddExtraSpaceIfInMenu	proc	far
	uses	di
	.enter

	call	Res_DerefVisDI
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	exit
	add	cx, MO_SCROLL_POPUP_ITEM_EXTRA_SPACE
exit:
	.leave
	ret
AddExtraSpaceIfInMenu	endp


Resident ends


ItemVeryCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollableItemSetInteractableState -- 
		MSG_GEN_ITEM_SET_INTERACTABLE_STATE for OLScrollableItemClass

DESCRIPTION:	Marks an item as interactable or not.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_SET_INTERACTABLE_STATE
		cx	- non-zero for interactable

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/23/93		Initial Version

------------------------------------------------------------------------------@
OLScrollableItemSetInteractableState	method dynamic	OLScrollableItemClass, \
				MSG_GEN_ITEM_SET_INTERACTABLE_STATE
	;
	; If we're not changing anything, don't do anything, but especially
	; don't send out the notify message!  It breaks repeat scrolling.
	; 5/13/93 cbh
	;
	mov	dl, mask OLIS_MONIKER_INVALID	;set dl if cx is zero
	jcxz	10$
	clr	dx
10$:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	xor	dl, ds:[di].OLII_state		;xor against current
	and	dl, mask OLIS_MONIKER_INVALID	
	tst	dl				;not dx! 5/24/93 cbh
	jz	exit				;not changing, exit

	push	cx
	mov	di, offset OLScrollableItemClass
	CallSuper	MSG_GEN_ITEM_SET_INTERACTABLE_STATE
	pop	cx

	;
	; Send to parent so it knows when to do an update-complete.
	;
	call	GetItemPosition			;returns position in dx
	mov	ax, MSG_OL_IGROUP_NOTIFY_ITEM_CHANGED_INTERACTABLE_STATE
	call	VisCallParent	
exit:
	ret

OLScrollableItemSetInteractableState	endm

ItemVeryCommon ends
