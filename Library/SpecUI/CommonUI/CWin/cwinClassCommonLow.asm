COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinClassCommonLow.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OpenWinCreateTabbedWindowRegion
				Create a tabbed window region

    INT OpenWinCreateWindowRegion
				Create a window region

    INT BubbleGetOriginalBounds Returns the bounds of the bubble without
				considering the spout.

    INT BubbleForceRecalcSizeIfNeeded
				Determines if the window's geometry needs
				to be recalculcated because of the spout.
				It really attempts to not do recalculations
				more than needed.  If there is a spout,
				this routine guarentees that the left edge
				of the window is equal to the spoutOriginX.

    INT OpenWinCreateWindowRegion
				Determines if the window's geometry needs
				to be recalculcated because of the spout.
				It really attempts to not do recalculations
				more than needed.  If there is a spout,
				this routine guarentees that the left edge
				of the window is equal to the spoutOriginX.

    INT OpenWinCreateWindowRegion
				Determines if the window's geometry needs
				to be recalculcated because of the spout.
				It really attempts to not do recalculations
				more than needed.  If there is a spout,
				this routine guarentees that the left edge
				of the window is equal to the spoutOriginX.

    INT CalcCurvePoints         Calculate a set if points to create a
				simple curve.

    INT GetWinColor             Fetches color info for call to WinOpen

    INT GetCoreWinOpenParams    Fetches core info needed for WinOpen

    INT OpenWinModifyWithNearestWinGroupPriority
				Raise the layer and window priority of the
				new window to be at least as high as the
				nearest win group up the generic tree.

    INT GetScreenWin            Returns Screen Window in di

    INT OpenWinGetState         This procedure checks if there is saved
				state information for this window.

    INT ConvertPixelBoundsToSpecWinSizePairs
				Convert this windowed object's bounds into
				ratio values. This is done before the data
				is saved.

    MTD MSG_META_UPDATE_WINDOW  *ds:si - instance data es - segment of
				OLWinClass

				ax - MSG_META_UPDATE_WINDOW cx -
				UpdateWindowFlags dl - VisUpdateMode

    INT OpenWinAttaching        *ds:si - instance data es - segment of
				OLWinClass

				ax - MSG_META_UPDATE_WINDOW cx -
				UpdateWindowFlags dl - VisUpdateMode

    MTD MSG_GEN_BRING_TO_TOP    This function brings the window to the top
				of its window priority group, & and if
				using a point & click kbd focus model, &
				the window is capable of being the focus
				window, then sends in a request to the
				application object to make this happen.  If
				the application is active, the request will
				be obliged, & this window will receive a
				MSG_META_GAINED_FOCUS_EXCL.  If the app
				isn't active, this window will still be
				remembered, so that it will be given kbd
				focus, if there is a choice when the app is
				active again.

    MTD MSG_VIS_MOVE_RESIZE_WIN Intercepts the method which does final
				positioning & resizing of a window, in
				order to handle final positioning requests,
				amd to make sure that the window is not
				lost off-screen, or even too close to the
				edge of the screen.

    MTD MSG_OL_WIN_SHOULD_TITLE_BUTTON_HAVE_ROUNDED_CORNER
				Check if a given title button should have a
				round corner in this particular window.
				Assumes that the button is in the title
				bar.

    INT OpenWinShouldHaveRoundBorderFar
				Checks appropriate instance data flags and
				returns if this window should have round
				thick windows. (Basically just calls
				OpenWinShouldHaveRoundBorder.)

    INT OpenWinShouldHaveRoundBorder
				Checks appropriate instance data flags and
				returns if this window should have round
				thick windows.

    INT OpenWinCheckVisibleConstraints
				This procedure ensure's that a window's
				visiblility constraints are met as it is
				opened or moved on the screen.

    INT OpenWinCheckMenuWinVisibilityConstraints
				This procedure is called after we have
				adjusted a menu window so that it is
				on-screen. If the menu is now obscuring the
				menu button which opens it, we will push
				the menu above the menu button.

    INT TryAgainInOtherDirection
				This procedure is called after we have
				adjusted a menu window so that it is
				on-screen. If the menu is now obscuring the
				menu button which opens it, we will push
				the menu above the menu button.

    INT KeepMenuOnscreen        This procedure is called after we have
				adjusted a menu window so that it is
				on-screen. If the menu is now obscuring the
				menu button which opens it, we will push
				the menu above the menu button.

    MTD MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
				Returns widths of icons left and right of
				title bar.

    MTD MSG_OL_WIN_GET_TITLE_BAR_HEIGHT
				Returns height of title bar

    INT OpenWinGetHeaderBoundsFar
				Returns height of title bar

    INT OpenWinDrawMoniker      Draws complete moniker, including long term
				moniker, unless we're running in GCM mode.

    INT OpenWinGCMSetTitleFontSize
				(Great documentation, EDS) That's why we
				don't let him code any more...

    INT OpenWinGCMResetTitleFontSize
				(Great documentation, EDS) That's why we
				don't let him code any more...

    INT OpenWinFlushMonikerSize (Great documentation, EDS) That's why we
				don't let him code any more...

    INT OpenWinUpdateWindowMenuItems
				This OpenLook specific procedure
				enables/disables the appropriate menu items
				in the WindowMenu (popup menu) for this
				window.

    INT OpenWinEnableOrDisableWindowMenuItem
				This OpenLook specific procedure
				enables/disables the appropriate menu items
				in the WindowMenu (popup menu) for this
				window.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinClassCommon.asm

DESCRIPTION:
	This file contains "WinCommon" procedures for OLWinClass
	See cwinClass.asm for class declaration and method table.

	$Id: cwinClassCommonLow.asm,v 1.3 98/05/04 07:22:56 joon Exp $

------------------------------------------------------------------------------@

WinCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinCreateTabbedWindowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a tabbed window region

CALLED BY:	OpenWinOpenWin
PASS:		*ds:si = OLWinClass object
RETURN:		^hbx = region (NULL if no region created)

		if bx != NULL
			region block is locked
			dx:ax = address of region

DESTROYED:	cx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DIALOGS_WITH_FOLDER_TABS	;----------------------------------------------

MAX_REGION_SIZE		equ	(NUMBER_OF_TABS+1) * 2 * 40 * (size word)

OpenWinCreateTabbedWindowRegion	proc	near
titleY	local	word
tabSize	local	NUMBER_OF_TABS dup (word)
bounds	local	Rectangle

	uses	si, di, es
	.enter

	clr	bx				; assume no region
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	LONG jz	done

	push	bx
	mov	ax, HINT_INTERACTION_FOLDER_TAB_DIALOG
	call	ObjVarFindData
	pop	bx
	LONG jnc done

	andnf	ds:[di].OLWI_attrs, not mask OWA_MOVABLE	; not movable

	mov	ax, ds:[di].OLWI_titleBarBounds.R_bottom
	sub	ax, ds:[di].OLWI_titleBarBounds.R_top
	sub	ax, 2
	mov	ss:[titleY], ax

	clr	di
	call	GrCreateState

	clr	cx
	call	getChildMonikerWidth
	mov	tabSize[0], cx
	mov	cx, 1
	call	getChildMonikerWidth
	mov	tabSize[2], cx
	mov	cx, 2
	call	getChildMonikerWidth
	mov	tabSize[4], cx

	call	GrDestroyState

	mov	ax, TEMP_OL_WIN_TAB_INFO
	call	ObjVarFindData
	jc	doneVardata			; if we already have tab info,
						;  don't change it
	mov	ax, TEMP_OL_WIN_TAB_INFO
	mov	cx, size OLWinFolderTabStruct
	call	ObjVarAddData

	mov	ds:[bx].OLWFTS_tabPosition[0], 0
	mov	ds:[bx].OLWFTS_tabPosition[2], 1
	mov	ds:[bx].OLWFTS_tabPosition[4], 2

	push	di
	segmov	es, ds
	lea	di, ds:[bx].OLWFTS_tabs
	mov	cx, (size OLWFTS_tabs) / 2
	clr	ax
	rep	stosw
	pop	di

	push	si
	mov	cx, NUMBER_OF_TABS
	clr	si
tabPositionLoop:
	mov	dx, tabSize[si]
	tst	dx
	jz	popSI

	add	ax, FIRST_TAB_OFFSET	; used as spacing between tabs
	shl	si, 1
	mov	ds:[bx].OLWFTS_tabs[si].LS_start, ax
	add	ax, titleY
	add	ax, dx
	add	ax, titleY
	dec	ax
	mov	ds:[bx].OLWFTS_tabs[si].LS_end, ax
	inc	ax
	shr	si, 1
	add	si, size word
	loop	tabPositionLoop
popSI:
	pop	si

doneVardata:
	push	bx
	call	VisGetBounds
	dec	cx
	dec	dx
	mov	ss:[bounds].R_left, ax
	mov	ss:[bounds].R_top, bx
	mov	ss:[bounds].R_right, cx
	mov	ss:[bounds].R_bottom, dx
	pop	si				; ds:si <= vardata extra data

	mov	ax, MAX_REGION_SIZE
	mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8 or \
		    (mask HF_SWAPABLE or mask HF_SHARABLE)
	call	MemAlloc
	LONG jc	done				; return bx = 0

	push	bx
	mov	es, ax
	clr	di

	mov	cx, titleY
	mov	ax, ss:[bounds].R_top
	mov	dx, ax
	dec	ax
	stosw					; store top-1 scanline
	mov	ax, EOREGREC
	stosw					; end of scanline

tabScanLineLoop:
	mov	ax, dx
	stosw					; store scanline

	clr	bx
tabLoop:
	mov	ax, ds:[si].OLWFTS_tabs[bx].LS_start
	tst	ax
	jz	10$
	add	ax, ss:[bounds].R_left
	add	ax, cx
	stosw
	mov	ax, ds:[si].OLWFTS_tabs[bx].LS_end
	add	ax, ss:[bounds].R_left
	sub	ax, cx
	stosw
10$:
	add	bx, (size LineSegment)
	cmp	bx, (size LineSegment) * NUMBER_OF_TABS
	jl	tabLoop

	mov	ax, EOREGREC
	stosw					; end of scanline

	inc	dx
	dec	cx
	cmp	cx, (NUMBER_OF_TABS-1) * TAB_SHADOW_SIZE
	jg	tabScanLineLoop

	mov	cx, (NUMBER_OF_TABS-1) * TAB_SHADOW_SIZE
	dec	dx				; dx <= previous scanline
	add	dx, TAB_SHADOW_SIZE

cardTopLoop:
	mov	ax, dx
	stosw					; store scanline

	mov	ax, ss:[bounds].R_left
	add	ax, cx
	stosw
	mov	ax, ss:[bounds].R_right
	stosw
	mov	ax, EOREGREC
	stosw

	add	dx, TAB_SHADOW_SIZE		; increment scanline
	sub	cx, TAB_SHADOW_SIZE
	jg	cardTopLoop

	mov	dx, ss:[bounds].R_bottom
	sub	dx, (NUMBER_OF_TABS-1) * TAB_SHADOW_SIZE

cardBottomLoop:
	mov	ax, dx
	stosw					; store scanline

	mov	ax, ss:[bounds].R_left
	stosw
	mov	ax, ss:[bounds].R_right
	sub	ax, cx
	stosw
	mov	ax, EOREGREC
	stosw

	add	dx, TAB_SHADOW_SIZE		; increment scanline
	add	cx, TAB_SHADOW_SIZE
	cmp	cx, (NUMBER_OF_TABS-1) * TAB_SHADOW_SIZE
	jle	cardBottomLoop

	mov	ax, EOREGREC
	stosw

	mov	dx, es
	clr	ax				; dx:ax <= address of region
	pop	bx				; bx <= handle of region
done:
	.leave
	ret


getChildMonikerWidth:
	push	si, di, bp
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
	jc	notFound

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_GET_MONIKER_SIZE
	mov	bp, di
	clr	dx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	cx, TAB_EXTRA_SIZE
notFound:
	pop	si, di, bp
	retn

OpenWinCreateTabbedWindowRegion	endp

endif	; if DIALOGS_WITH_FOLDER_TABS -----------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinCreateWindowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a Odie style bubble dialog region

CALLED BY:	OpenWinOpenWin
PASS:		*ds:si	= OLWinClass object
RETURN:		^hbx	= region (NULL if no region created)
DESTROYED:	cx, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS and (_DUI)

OpenWinCreateWindowRegion	proc	near
winCenter	local	Point
activator	local	Point
oldMargins	local	Point
newMargins	local	Point
if DIALOG_SHADOWS
.assert (NUM_DIALOG_SHADOW_REGION_POINTS gt NUM_WINDOW_REGION_POINTS)
polygon		local 	NUM_DIALOG_SHADOW_REGION_POINTS dup (Point)
else
polygon		local 	NUM_WINDOW_REGION_POINTS dup (Point)
endif
if BUBBLE_DIALOG_SHADOW
winRegion	local	hptr
shadowRegion	local	hptr
winSize		local	word
shadowSize	local	word
orSize		local	word
endif
	uses	ax,di,bp,es
	.enter

	; We only create bubble dialogs for dialogs.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	LONG jz	notPopup

	; Setup margin info

	clr	cx, dx
	mov	newMargins.P_x, cx
	mov	newMargins.P_y, dx

	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarFindData
	jnc	saveOldMargins

	mov	cx, ds:[bx].P_x
	mov	dx, ds:[bx].P_y
saveOldMargins:
	mov	oldMargins.P_x, cx
	mov	oldMargins.P_y, dx

	; And we need to know what activated the dialog.

	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
	LONG jnc noRegion
	;
	; See if the activator position is being overridden with the
	; following hint.
	;
	push	bx
	mov	ax, HINT_INTERACTION_ACTIVATOR_POINT
	call	ObjVarFindData
	pop	di
	jnc	getBounds
	mov	cx, ds:[bx].P_x
	mov	dx, ds:[bx].P_y
	jmp	gotPoint
getBounds:
	mov	bx, di				; ^lbx:si = activator
	push	si, bp
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_META_GET_ACTIVATOR_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, bp
	pop	si, bp
	LONG jnc noRegion

	add	cx, ax
	shr	cx, 1
	add	dx, di
	shr	dx, 1
gotPoint:

if POSITION_BUBBLE_WRT_ACTIVATOR
	call	PositionBubbleDialog

if _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS
    PrintMessage <Disable _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS before shipping>
	;
	; convert to field coords (to deal with fake screen size and hard
	; icon bars
	;
	push	ax, bx, di
	movdw	axbx, cxdx
	call	VisQueryParentWin	; di = window
	call	WinUntransform
	movdw	cxdx, axbx
	pop	ax, bx, di
endif	;_NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS
endif	;POSITION_BUBBLE_WRT_ACTIVATOR

	mov	activator.P_x, cx
	mov	activator.P_y, dx

	; Get window bounds and window center

	call	VisGetBounds
	add	ax, oldMargins.P_x
	add	bx, oldMargins.P_y

	mov	polygon[0].P_x, ax
	mov	polygon[0].P_y, bx	; polygon[0] = left, top
	mov	polygon[4].P_x, cx
	mov	polygon[4].P_y, bx	; polygon[1] = right, top
	mov	polygon[8].P_x, cx
	mov	polygon[8].P_y, dx	; polygon[2] = right, bottom
	mov	polygon[12].P_x, ax
	mov	polygon[12].P_y, dx	; polygon[3] = left, bottom

	push	cx, dx
	add	cx, ax
	shr	cx, 1
	mov	winCenter.P_x, cx
	add	dx, bx
	shr	dx, 1
	mov	winCenter.P_y, dx
	pop	cx, dx

	; Now find out which side the wedge should come out from the dialog

	cmp	ax, activator.P_x
	LONG jg	checkLeftRight
	cmp	cx, activator.P_x
	LONG jl	checkLeftRight

checkTopBottom::
	; Enlarge bounds to include size of wedge

	sub	bx, BUBBLE_WEDGE_SIZE
	add	dx, BUBBLE_WEDGE_SIZE

	cmp	bx, activator.P_y
	LONG jg	topWedge
	cmp	dx, activator.P_y
	LONG jge noRegion

bottomWedge::
	; The wedge is on the bottom.

	movdw	polygon[24], polygon[12], ax	; Make room for 3 pts.

	mov	ax, polygon[8].P_y		; ax = bottom
	mov	polygon[12].P_y, ax
	mov	polygon[20].P_y, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[16].P_y, ax

	mov	ax, activator.P_x
	cmp	ax, winCenter.P_x
	jl	bottomLeft

bottomRight::
	; The wedge is on the bottom right

	mov	polygon[12].P_x, ax
	mov	polygon[16].P_x, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[20].P_x, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decBottomRight
	call	addOLWinInsetPoints
	call	decBottomRight
	mov	bx, dx
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_X1 or mask WWIF_DEC_Y1
bottomCommon:
	mov	bx, dx
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_Y1
	mov	ax, (C_DARK_GREY shl 8) or C_WHITE
	mov	ds:[bx+0*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+1*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+2*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+3*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+5*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_color, al
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_x
	dec	ds:[bx+16].P_y
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
endif
	jmp	createRegion

if BUBBLE_DIALOG_INSET
decBottomRight	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_x
	dec	ds:[bx+16].P_y
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
endif

bottomLeft:
	; The wedge is on the bottom left

	mov	polygon[20].P_x, ax
	mov	polygon[16].P_x, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[12].P_x, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decBottomLeft
	call	addOLWinInsetPoints
	call	decBottomLeft
	inc	ds:[bx+16].P_x			; move spout left in
	inc	ds:[bx+20].P_x
	dec	ds:[bx+16].P_y			; bring in spout tip
	jmp	bottomCommon

decBottomLeft	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	jmp	createRegion
endif

topWedge:
	; The wedge is on the top.

	mov	newMargins.P_y, BUBBLE_WEDGE_SIZE-1

	movdw	polygon[24], polygon[12], ax	; Make room for 3 pts.
	movdw	polygon[20], polygon[8], ax	; Make room for 3 pts.
	movdw	polygon[16], polygon[4], ax	; Make room for 3 pts.

	mov	ax, polygon[0].P_y		; ax = top
	mov	polygon[4].P_y, ax
	mov	polygon[12].P_y, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[8].P_y, ax

	mov	ax, activator.P_x
	cmp	ax, winCenter.P_x
	jl	topLeft

topRight::
	; The wedge is on the top right

	mov	polygon[12].P_x, ax
	mov	polygon[8].P_x, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[4].P_x, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decTopRight
	call	addOLWinInsetPoints
	call	decTopRight
	inc	ds:[bx+8].P_y			; lower spout tip
topCommon:
	inc	ds:[bx+12].P_y			; lower second top segment
	inc	ds:[bx+16].P_y
	mov	bx, dx
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_Y1
	mov	ax, (C_DARK_GREY shl 8) or C_WHITE
	mov	ds:[bx+0*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+1*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+2*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+3*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+5*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_color, al
else
	dec	ds:[bx+8].P_x
	inc	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
endif
	jmp	createRegion

if BUBBLE_DIALOG_INSET
decTopRight	label	near
	dec	ds:[bx+8].P_x
	inc	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
endif

topLeft:
	; The wedge is on the top left

	mov	polygon[4].P_x, ax
	mov	polygon[8].P_x, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[12].P_x, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decTopLeft
	call	addOLWinInsetPoints
	call	decTopLeft
	inc	ds:[bx+4].P_x		; bring spout left in
	inc	ds:[bx+8].P_x
	inc	ds:[bx+8].P_y		; move spout tip down
	inc	ds:[bx+12].P_x		; move spout right base out
	jmp	topCommon

decTopLeft	label	near
	inc	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
else
	inc	ds:[bx+8].P_y
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	jmp	createRegion
endif

checkLeftRight:
	; Check if the wedge should come out from the left or right of dialog

	cmp	bx, activator.P_y	; if activator is above
	LONG jg	noRegion		;  then no wedge
	cmp	dx, activator.P_y	; if activator is below
	LONG jl	noRegion		;  then no wedge

	; Enlarge bounds to include size of wedge

	sub	ax, BUBBLE_WEDGE_SIZE
	add	cx, BUBBLE_WEDGE_SIZE

	cmp	ax, activator.P_x
	LONG jg	leftWedge
	cmp	cx, activator.P_x
	LONG jge noRegion

rightWedge::
	; The wedge is on the right

	movdw	polygon[24], polygon[12], ax	; Make room for 3 pts.
	movdw	polygon[20], polygon[8], ax	; Make room for 3 pts.

	mov	ax, polygon[4].P_x		; ax = right
	mov	polygon[8].P_x, ax
	mov	polygon[16].P_x, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[12].P_x, ax

	mov	ax, activator.P_y
	cmp	ax, winCenter.P_y
	jl	rightTop

rightBottom::
	; The wedge is on the right bottom

	mov	polygon[16].P_y, ax
	mov	polygon[12].P_y, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[8].P_y, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decRightBottom
	call	addOLWinInsetPoints
	call	decRightBottom
rightCommon:
	mov	bx, dx
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_Y1
	mov	ax, (C_DARK_GREY shl 8) or C_WHITE
	mov	ds:[bx+0*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+1*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+2*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+3*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+5*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_color, al
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_x
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
endif
	jmp	createRegion

if BUBBLE_DIALOG_INSET
decRightBottom	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_x
	dec	ds:[bx+16].P_y
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
endif

rightTop:
	; The wedge is on the right top

	mov	polygon[8].P_y, ax
	mov	polygon[12].P_y, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[16].P_y, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decRightTop
	call	addOLWinInsetPoints
	call	decRightTop
	inc	ds:[bx+8].P_y			; lower spout top
	inc	ds:[bx+12].P_y
	dec	ds:[bx+12].P_x			; move spout tip right
	jmp	rightCommon

decRightTop	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	retn
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+12].P_x
	dec	ds:[bx+16].P_x
	dec	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	dec	ds:[bx+24].P_y
	jmp	createRegion
endif

leftWedge:
	; The wedge is on the left.

	mov	ax, polygon[12].P_x		; ax = left
	mov	polygon[16].P_x, ax
	mov	polygon[24].P_x, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[20].P_x, ax

	mov	ax, activator.P_y
	cmp	ax, winCenter.P_y
	jl	leftTop

leftBottom::
	; The wedge is on the left bottom

	mov	newMargins.P_x, BUBBLE_WEDGE_SIZE-1

	mov	polygon[16].P_y, ax
	mov	polygon[20].P_y, ax
	sub	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[24].P_y, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decLeftBottom
	call	addOLWinInsetPoints
	call	decLeftBottom
	inc	ds:[bx+20].P_x			; bring in spout tip
	push	bx
	mov	bx, dx
	mov	ds:[bx+5*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_INC_X1 or mask WWIF_DEC_Y1
	pop	bx
leftCommon:
	inc	ds:[bx+12].P_x			; move first left segment right
	inc	ds:[bx+16].P_x
	mov	bx, dx
	mov	ds:[bx+3*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_Y1
	mov	ax, (C_DARK_GREY shl 8) or C_WHITE
	mov	ds:[bx+0*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+1*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+2*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+3*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_color, ah
	mov	ds:[bx+5*(size WedgeWinColorInfo)].WWCI_color, al
	mov	ds:[bx+6*(size WedgeWinColorInfo)].WWCI_color, al
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_y
	inc	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
endif
	jmp	createRegion

if BUBBLE_DIALOG_INSET
decLeftBottom	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
	dec	ds:[bx+16].P_y
	inc	ds:[bx+20].P_x
	dec	ds:[bx+20].P_y
	retn
endif

leftTop:
	; The wedge is on the left top

	mov	newMargins.P_x, BUBBLE_WEDGE_SIZE	; why?????

	mov	polygon[24].P_y, ax
	mov	polygon[20].P_y, ax
	add	ax, BUBBLE_WEDGE_SIZE
	mov	polygon[16].P_y, ax

	call	addOLWinBorderPoints
if BUBBLE_DIALOG_INSET
	call	decLeftTop
	call	addOLWinInsetPoints
	call	decLeftTop
	inc	ds:[bx+20].P_y			; lower spout top
	inc	ds:[bx+24].P_y
	add	ds:[bx+20].P_x, 2		; move spout tip in
	push	bx
	mov	bx, dx
	mov	ds:[bx+4*(size WedgeWinColorInfo)].WWCI_flags, \
				mask WWIF_DEC_X1 or mask WWIF_DEC_Y1
	pop	bx
	jmp	leftCommon

decLeftTop	label	near
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
;	dec	ds:[bx+16].P_y
;	inc	ds:[bx+20].P_x
	retn
else
	dec	ds:[bx+4].P_x
	dec	ds:[bx+8].P_x
	dec	ds:[bx+8].P_y
	dec	ds:[bx+12].P_y
;	dec	ds:[bx+16].P_y
;	inc	ds:[bx+20].P_x
endif

createRegion:
	clr	di
	call	GrCreateState

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	push	ds, si
	segmov	ds, ss
	lea	si, polygon
	mov	cx, NUM_WINDOW_REGION_POINTS
	call	GrDrawPolygon
	pop	ds, si

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion

if BUBBLE_DIALOG_SHADOW ;------------------------------------------------------
	;
	; check if shadow desired
	;	*ds:si = OLWin
	;	bx = handle of original region
	;
	push	bx
	mov	ax, HINT_DRAW_SHADOW
	call	ObjVarFindData
	pop	bx
	LONG jnc	noShadow
	;
	; make shadow by shifting polygon down and to the right and or'ing
	; that region with the original region
	;	*ds:si = OLWin
	;	bx = handle of original region
	;	di = gstate
	;
	push	ds, es, si, di			; save OLWin, gstate
	mov	winRegion, bx			; save window region block
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	winSize, ax			; save window region size

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	segmov	ds, ss
	lea	si, polygon
	mov	cx, NUM_WINDOW_REGION_POINTS
makeShadow:
	add	ds:[si].P_x, DIALOG_SHADOW_OFFSET
	add	ds:[si].P_y, DIALOG_SHADOW_OFFSET
	add	si, size Point
	loop	makeShadow

	lea	si, polygon
	mov	cx, NUM_WINDOW_REGION_POINTS
	call	GrDrawPolygon

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion			; bx = shadow region block
	mov	shadowRegion, bx

	mov	bx, winRegion			; lock original region
	call	MemLock
	mov	ds, ax
	mov	bx, shadowRegion		; lock shadow region
	call	MemLock
	mov	es, ax

	mov	ax, MGIT_SIZE
	call	MemGetInfo			; ax = shadow region size
	mov	shadowSize, ax

	add	ax, winSize
	shl	ax, 1				; double for OR operation
tryAgain:
	add	ax, size Rectangle		; make room for bounds
	mov	orSize, ax
	add	ax, shadowSize			; plus size of existing reg
	mov	bx, shadowRegion
	clr	cx
	call	MemReAlloc			; make room for OR'ed region
	mov	es, ax
	mov	di, shadowSize			; es:di = OR'ed region buffer
	add	di, size Rectangle
	mov	cx, orSize			; cx = size of buffer
	mov	ax, mask ROF_OR_OP		; OR, please
	mov	si, size Rectangle		; ds:si = original region
	mov	bx, si				; es:bx = shadow region
	call	GrPtrRegOp
	jnc	gotRegion
	mov	ax, cx				; ax = new OR'ed region size
	jmp	short tryAgain

gotRegion:
	;
	; get bounds of and move OR'ed region to beginning of buffer
	;	cx = size of OR'ed region
	;
	add	cx, size Rectangle		; include bounds
	push	cx
	segmov	ds, es				; ds:si = OR'ed region
	mov	si, shadowSize
	push	si
	add	si, size Rectangle		; ds:si = actual region
	call	GrGetPtrRegBounds		; get bounds
	pop	si				; ds:si = OR'ed region + bounds
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	clr	di				; es:di = dest for OR'ed region
	pop	cx				; size of OR'ed region + bounds
	push	cx				; save again
	rep	movsb
	pop	ax				; size of OR'ed region + bounds
	mov	bx, shadowRegion
	clr	cx
	call	MemReAlloc
	mov	bx, winRegion
	call	MemFree
	mov	bx, shadowRegion		; return with OR'ed region
	call	MemUnlock
	pop	ds, es, si, di			; *ds:si = OLWin, di = gstate
noShadow:
endif ;------------------------------------------------------------------------

regionCommon::
	call	GrDestroyState

	movdw	dxcx, newMargins
	cmpdw	dxcx, oldMargins
	LONG je	done

	push	bx
	push	cx, dx
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	mov	cx, size Point
	call	ObjVarAddData
	pop	ds:[bx].P_x, ds:[bx].P_y
	pop	bx

	call	recalcGeometry
	jmp	done

noRegion:
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	call	ObjVarDeleteData
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarDeleteData

if DIALOG_SHADOWS ;------------------------------------------------------------
	;
	; if we want a shadow, we need to create a region
	;
	mov	ax, HINT_DRAW_SHADOW
	call	ObjVarFindData
	jnc	noNormalShadow

	;       0		1
	;	+---------------+
	;	|		|
	;	|	      2 +--+ 3
	;	|		   |
	;	|		   |
	;     7 +--+ 6		   |
	;	   |		   |
	;	 5 +---------------+ 4
	;
	call	VisGetBounds
	mov	polygon[0*(size Point)].P_x, ax
	mov	polygon[0*(size Point)].P_y, bx
	mov	polygon[1*(size Point)].P_x, cx
	mov	polygon[1*(size Point)].P_y, bx
	mov	polygon[2*(size Point)].P_x, cx
	mov	polygon[6*(size Point)].P_y, dx
	mov	polygon[7*(size Point)].P_x, ax
	mov	polygon[7*(size Point)].P_y, dx
	add	ax, DIALOG_SHADOW_OFFSET
	add	bx, DIALOG_SHADOW_OFFSET
	add	cx, DIALOG_SHADOW_OFFSET
	add	dx, DIALOG_SHADOW_OFFSET
	mov	polygon[2*(size Point)].P_y, bx
	mov	polygon[3*(size Point)].P_x, cx
	mov	polygon[3*(size Point)].P_y, bx
	mov	polygon[4*(size Point)].P_x, cx
	mov	polygon[4*(size Point)].P_y, dx
	mov	polygon[5*(size Point)].P_x, ax
	mov	polygon[5*(size Point)].P_y, dx
	mov	polygon[6*(size Point)].P_x, ax

	clr	di
	call	GrCreateState

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	push	ds, si
	segmov	ds, ss
	lea	si, polygon
	mov	cx, NUM_DIALOG_SHADOW_REGION_POINTS
	call	GrDrawPolygon
	pop	ds, si

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion

	jmp	regionCommon

noNormalShadow:
endif ;------------------------------------------------------------------------

	tstdw	oldMargins
	jz	notPopup

	call	recalcGeometry
notPopup:
	clr	bx			; no window region
done:
	.leave
	ret

; Add the TEMP_OL_WIN_BORDER_POINTS vardata and copy in the polyogn points
; Pass:  *ds:si = OLWinClass object
; Return: ds:bx = vardata
;
addOLWinBorderPoints:
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	mov	cx, size WedgeWinBorderStruct
	call	ObjVarAddData

	push	ds, si, bx
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, polygon
	mov	bx, polygon[0].P_x
	sub	bx, newMargins.P_x
	mov	dx, polygon[0].P_y
	sub	dx, newMargins.P_y
	mov	cx, NUM_WINDOW_REGION_POINTS
pointLoop:
	lodsw
	sub	ax, bx			; adjust for extra left margin
	stosw
	lodsw
	sub	ax, dx			; adjust for extra top margin
	stosw
	loop	pointLoop
	pop	ds, si, bx
	retn

if BUBBLE_DIALOG_INSET
;
; Pass: ds:bx = border points
; Return: ds:bx = vardata for inset points
;	  ds:dx = vardata for inset line segment color info
;
addOLWinInsetPoints:
	mov	dx, bx			; ds:dx = border points
	mov	ax, TEMP_OL_WIN_INSET_POINTS
	mov	cx, size WedgeWinBorderStruct
	call	ObjVarAddData
	push	si
	segmov	es, ds			; es:di = inset points
	mov	di, bx
	mov	si, dx			; ds:si = border points
	mov	cx, (NUM_WINDOW_REGION_POINTS*(size Point))/(size word)
	rep	movsw
	pop	si
	inc	ds:[bx].P_x		; always inset start point
	inc	ds:[bx].P_y
	inc	ds:[bx+4].P_y		; inset first top line
	inc	ds:[bx+24].P_x		; inset second right line
	mov	ax, TEMP_OL_WIN_INSET_COLORS
	mov	cx, size WedgeWinInsetColorInfo
	call	ObjVarAddData
	mov	dx, bx			; ds:dx = color info
	;
	; deref since adding TEMP_OL_WIN_INSET_COLORS could move object
	;
	mov	ax, TEMP_OL_WIN_INSET_POINTS
	call	ObjVarFindData		; ds:bx = inset points
EC <	ERROR_NC	OL_ERROR					>
	retn
endif

; Pass:  *ds:si = OLWinClass object
; Return: nothing
;
recalcGeometry:
	push	bp
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_UPDATE_GEOMETRY
	call	ObjCallInstanceNoLock
	pop	bp
	retn

OpenWinCreateWindowRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionBubbleDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the dialog according to the activator bounds

CALLED BY:	OpenWinCreateWindowRegion
PASS:		cx, dx		= activator center
		*ds:si		= dialog
		ds:di		= dialog instance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if POSITION_BUBBLE_WRT_ACTIVATOR
PositionBubbleDialog	proc	near

activatorX	local	word	push	cx
activatorY	local	word	push	dx
dialogWidth	local	word
dialogHeight	local	word
screenWidth	local	word
screenHeight	local	word

	uses	ax,bx,cx,dx,bp
	.enter

	call	GetFieldDimensionsFar
	mov	ss:[screenWidth], cx
	mov	ss:[screenHeight], dx

	call	VisGetSize
	mov	ss:[dialogWidth], cx
	mov	ss:[dialogHeight], dx

	mov	cx, ss:[activatorX]
	mov	dx, ss:[activatorY]
	call	PositionBubbleVertically	; dx = y position
	jc	leftOrRight
	call	CenterBubbleHorizontally	; cx = x position
gotPosition:

if _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS
    PrintMessage <Disable _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS before shipping>
	;
	; convert to field coords (to deal with fake screen size and hard
	; icon bars
	;
	push	di
	movdw	axbx, cxdx
	call	VisQueryParentWin		; di = window
	call	WinUntransform
	movdw	cxdx, axbx
	tst	cx
	jns	onScreen
	clr	cx
onScreen:
	pop	di
endif	;_NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS

	mov	ax, MSG_VIS_SET_POSITION
	call	ObjCallInstanceNoLock

	.leave
	ret
leftOrRight:
	call	PositionBubbleLeftOrRight
	jmp	gotPosition
PositionBubbleDialog	endp
endif	;if POSITION_BUBBLE_WRT_ACTIVATOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterBubbleHorizontally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the dialog horizontally so that it is centered
		with the activator.

CALLED BY:	PositionBubbleDialog
PASS:		cx, dx		= activator center
		*ds:si		= dialog
RETURN:		cx		= x position to place dialog
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if POSITION_BUBBLE_WRT_ACTIVATOR
CenterBubbleHorizontally	proc	near
	uses	ax,bx,dx,di
	.enter	inherit	PositionBubbleDialog

	mov	cx, ss:[dialogWidth]	; cx = dialog width
	shr	cx, 1			; cx = width / 2
	mov	ax, ss:[activatorX]

	sub	ax, cx			; ax = new dialog x pos
	js	atLeft
gotPos:
	;
	; Should check to make sure right edge stays in bounds
	;
	mov	cx, ss:[screenWidth]
if _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS
    PrintMessage <Disable _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS before shipping>
	push	ax
	call	VisQueryParentWin	; di = window
	mov	ax, cx
	call	WinUntransform
	mov	cx, ax
	pop	ax
endif
	mov	bx, ss:[dialogWidth]
	mov	dx, ax			; dx = new dialog x pos

	add	dx, bx			; dx = right edge of dialog
	xchg	ax, cx			; ax = scrn width; cx = x pos
	cmp	dx, ax
	jbe	done
	;
	; Position the dialog to the left so right edge stays on
	; screen.
	;
	mov_tr	cx, ax
	sub	cx, bx
done:
	.leave
	ret
atLeft:
if _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS
    PrintMessage <Disable _NASTY_HACK_FOR_MENUS_WITH_VERTICAL_HARD_ICONS before shipping>
	clr	ax
	call	VisQueryParentWin	; di = window
	call	WinTransform
	mov_tr	cx, ax
else
	clr	cx
endif
	jmp	done
CenterBubbleHorizontally	endp
endif	;if POSITION_BUBBLE_WRT_ACTIVATOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionBubbleVertically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the dialog vertically so that it is either above
		or below the activator...not too close or the pointer
		will not draw.  If the dialog is too tall to fit,
		center it vertically.

CALLED BY:	PositionBubbleDialog
PASS:		cx, dx		= activator center
		*ds:si		= dialog
RETURN:		dx		= new y pos of dialog
		carry clear	= dialog placed above or below activator
		carry set	= dialog too tall, being centered
				  vertically.  Place left or right.

DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if POSITION_BUBBLE_WRT_ACTIVATOR

SPOUT_HEIGHT_COMPENSATION	equ	20

PositionBubbleVertically	proc	near
	uses	ax,bx,cx,di
	.enter	inherit	PositionBubbleDialog

	mov	bx, dx			; bx = y center of activator
	;
	; If middle of activator is below middle of screen, then
	; bubble dialog should go above.  Otherwise, bubble dialog
	; goes below.
	;
	mov	dx, ss:[screenHeight]
	shr	dx, 1			; cx = center of window
	cmp	bx, dx
	mov	dx, bx			; dx = y center of activator
	ja	above
below:
	;
	; Dialog should go below the activator
	;
	add	dx, SPOUT_HEIGHT_COMPENSATION
	;
	; Does it still fit on screen?
	;
	mov	bx, dx			; bx = new y position
	add	bx, ss:[dialogHeight]
	cmp	bx, ss:[screenHeight]
	ja	tooTall
	clc
	jmp	done
above:
	;
	; Bubble dialog should go above activator.  Get the height of
	; the dialog and subtract from y pos of activator and subtract
	; a little extra for the pointer.
	;
	mov	dx, ss:[dialogHeight]
	sub	bx, dx
	js	tooTall
	sub	bx, SPOUT_HEIGHT_COMPENSATION
	js	tooTall
	mov	dx, bx
	clc
done:
	.leave
	ret
tooTall:
	mov	bx, dx			; bx = dialogHeight
	mov	dx, ss:[screenHeight]
	shr	dx, 1			; dx = vert screen center

	shr	bx, 1			; 1/2 height of dialog
	sub	dx, bx			; dx = new vert dialog pos

	stc
	jmp	done
PositionBubbleVertically	endp
endif	;if POSITION_BUBBLE_WRT_ACTIVATOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionBubbleLeftOrRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The dialog is being centered vertically.  Place it to
		the left or right of the activator (whatever fits
		best).
CALLED BY:	PositionBubbleDialog
PASS:		cx, dx		= center of activator
		*ds:si		= dialog
RETURN:		cx		= new x position of dialog
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if POSITION_BUBBLE_WRT_ACTIVATOR

SPOUT_WIDTH_COMPENSATION	equ	20

PositionBubbleLeftOrRight	proc	near
	uses	ax, dx
	.enter	inherit	PositionBubbleDialog

	mov	ax, ss:[activatorX]
	mov	cx, ss:[screenWidth]
	shr	cx, 1			; cx = x center of screen
	cmp	ax, cx			; is button on left or right?
	ja	posLeft

	add	ax, SPOUT_WIDTH_COMPENSATION
	mov_tr	cx, ax
done:
	.leave
	ret

posLeft:
	sub	ax, ss:[dialogWidth]
	mov_tr	cx, ax
	sub	cx, SPOUT_WIDTH_COMPENSATION
	jns	done
	clr	cx			; force to left edge
willFit:
	jmp	done
PositionBubbleLeftOrRight	endp

endif

endif	; BUBBLE_DIALOGS and (_DUI)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinCreateWindowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a window region

CALLED BY:	OpenWinOpenWin

PASS:		*ds:si = OLWinClass object

RETURN:		^hbx = region (NULL if no region created)
    NOT IN CURRENT RUDY VERSION: (cx,dx) = difference Win origin and Vis origin

DESTROYED:	ax, cx, dx

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/ 8/94    	Initial version
	Chris	7/25/94		Changed to only do bubbles when object is
				on the left

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS and (not (_DUI))

if not CURVED_BUBBLE_DIALOG

WIN_LEFT		= 0001b
WIN_RIGHT		= 0010b
WIN_TOP			= 0100b
WIN_BOTTOM		= 1000b
WEDGE_SIZE		= 34
MINIMUM_WEDGE_WIDTH	= 42
MAXIMUM_WEDGE_WIDTH	= 72
WEDGES_TO_LEFT_ONLY	= TRUE		;no wedge if activator not to left

if WEDGES_TO_LEFT_ONLY

;===========================================================================
;===========================================================================
;                        BEGIN BUBBLE CODE CURRENTLY USED IN RUDY
;
; There is a correlated comment below that says "END BUBBLE CODE...".  I
; added these comment because I really got tired of trying to figure out
; which constants were true or false or whatever... --JimG 7/24/95
;===========================================================================
;===========================================================================

OpenWinCreateWindowRegion	proc	near
	class	OLWinClass

self		local	word		push	si
side		local	word
points		local	8 dup (Point)
activatorBounds	local	Rectangle
spoutOriginX	local	word
	uses	si, di, bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	LONG	jz	noRegionNotPopup

	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
	LONG	jnc	noRegion

	push	bp, si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_META_GET_ACTIVATOR_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, bp
	pop	bp, si
	LONG	jnc	noRegion

	; Coordinates are in (ax, di) - (cx, dx)

	;
	; Make sure that the upper-left coords are positive (on the screen!)
	;
	tst	ax
	LONG	js	noRegion
	tst	di
	LONG	js	noRegion

	mov	activatorBounds.R_left, ax
	mov	activatorBounds.R_top, di

	;
	; Make sure that the lower-right coords are within the screen's
	; dimensions.
	;
	mov_tr	ax, cx			  ; Move LR coords into (ax,di)
	mov_tr	di, dx
if _DUI
	call	GetFieldDimensionsFar
else
	call	OpenGetScreenDimensions	  ; cx=width, dx=height
endif
	cmp	ax, cx
	LONG	jge	noRegion
	cmp	di, dx
	LONG	jge	noRegion

	mov	activatorBounds.R_right, ax
	mov	activatorBounds.R_bottom, di

	call	BubbleGetOriginalBounds	  ; pass bounds, as screen coords

	;
	; No spout if the activator is completely underneath us (activator
	; left > window left).    (7/12/95 cbh)
	;
	; First, we'll see if a minimum wedge will overlap the moniker
	; (in a settings dialog) -- brianc 1/22/96
	;
	cmp	activatorBounds.R_left, ax
	LONG	jg	tryMinWedge

	clr	si
	push	ax
	sub	ax, MINIMUM_WEDGE_WIDTH	  ; make sure wedges at least this wide
	cmp	activatorBounds.R_right, ax
	LONG jge	stubbySpout

	;
	; Make sure wedges not longer than max
	;
	sub	ax, (MAXIMUM_WEDGE_WIDTH-MINIMUM_WEDGE_WIDTH)
	cmp	activatorBounds.R_right, ax
	jl	useThisOrigin

	;
	; Regular spout
	;
	mov	ax, activatorBounds.R_right
useThisOrigin:
	mov	ss:[spoutOriginX], ax
	jmp	afterSpout

keepGoingVup:
	;
	; keep going up the vis tree as long as we have non-OLCRF_RIGHT_ARROW
	; OLCtrls
	;	*ds:si = non-OLCRF_RIGHT_ARROW OLCtrl
	;	bx = child handle
	;
	pushdw	bxsi
	call	VisFindParent		; ^lbx:si = vis parent
	movdw	axdi, bxsi		; ^lax:di = vis parent
	popdw	bxsi
	call	ObjSwapUnlock		; unlock child
	movdw	bxsi, axdi		; ^lbx:si = vis parent
	jmp	short tryAgain

tryMinWedge:
	;
	; if activator is OLButton whose vis parent is a settings
	; "draw right arrow" OLCtrl, and its left bound will allow a
	; minimal spout, use it
	;
	push	bp, bx, si, es, di
	mov	bp, ax			; save bubble left bound
	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
EC <	ERROR_NC	OL_ERROR					>
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	call	ObjSwapLock		; *ds:si = activator, bx = OLWin han
	mov	di, segment OLButtonClass
	mov	es, di
	mov	di, offset OLButtonClass
	call	ObjIsObjectInClass
	jnc	stillNoGo		; not OLButtonClass, forget it
	push	bx			; save OLWin handle
	call	VisFindParent		; ^lbx:si = parent
	tst	bx
	jz	stillNoGoPop		; (carry clear)
tryAgain:
	call	ObjSwapLock		; *ds:si = parent, bx = activator han
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	jnc	stillNoGoPopUnlock	; parent not OLCtrl, forget it
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_DRAW_RIGHT_ARROW
;	jz	stillNoGoPopUnlock	; not right arrow, forget it (C clr)
;keep going up -- brianc 2/20/96
	jz	keepGoingVup
	push	bp
	sub	bp, MINIMUM_WEDGE_WIDTH	; bp = left position of spout
;	cmp	bp, ds:[di].VI_bounds.R_left	; will spout fit?
;need to translate to screen coords -- brianc 2/20/96
	mov	ax, ds:[di].VI_bounds.R_left	; ax = object left
	call	VisQueryWindow		; di = object window
	push	bx
	clr	bx			; Y coord to transform
	call	WinTransform		; ax = screen object left
	pop	bx
	cmp	bp, ax			; will spout fit?
;----------------------------------------------------
	pop	bp
	stc				; assume so
	jge	stillNoGoPopUnlock	; !(S^O)
	clc				; else, forget it
stillNoGoPopUnlock:
	call	ObjSwapUnlock		; *ds:si = activator (saves flags)
stillNoGoPop:
	pop	bx			; restore OLWin handle
stillNoGo:
	mov	ax, bp
	call	ObjSwapUnlock		; *ds:si = OLWin
	pop	bp, bx, si, es, di
	LONG jnc	noRegion
	push	ax			; restore left bound
	; FALL THRU to use minimum spout

stubbySpout:
	pop	ax			;ax = left bound
	push	ax
	sub	ax, WEDGE_SIZE
	mov	ss:[spoutOriginX], ax

afterSpout:
	pop	ax			;ax = left bound

	call	BubbleForceRecalcSizeIfNeeded

	mov	ss:points[0].P_x, ax
	push	ax
	mov	ax, activatorBounds.R_right
	sub	ss:points[0].P_x, ax
	pop	ax

	cmp	activatorBounds.R_bottom, dx
	LONG jge noRegion
	cmp	activatorBounds.R_top, bx
	LONG jle noRegion

	mov	ss:[side], WIN_LEFT
	movdw	ss:points[0], bxax	; 0------------>1
	movdw	ss:points[4], bxcx	; ^		|
	movdw	ss:points[8], dxcx	; |		v
	movdw	ss:points[12], dxax	; 3<------------2

	call	GetWedgeYoffsets

	movdw	ss:points[16], dxax

	mov	cx, ss:[spoutOriginX]
	mov	ss:points[20].P_x, cx
	mov	ss:points[24].P_x, cx

	; I thought I'd go ahead and document this little fact so future
	; generations could benefit.  It turns out that the polygon used for
	; the window region is slightly different from the polygon used to
	; draw the window border.  This is because we need to ensure that
	; the apex of the spout is inside the region and also because border
	; is drawn with two pixels.  So the region contains two points at
	; the apex whereas the border only has one point.  Here we calculate
	; those two points by taking the average of the activator Y bounds
	; and then use two pixels above and below that point.
	;
	; (This used to be only a one pixel deviation, but it was clipping
	; part of the two pixel border and so it looked bad..) --JimG 7/25/95
	;
	mov	cx, activatorBounds.R_top
	add	cx, activatorBounds.R_bottom
	shr	cx, 1
	inc	cx
	inc	cx			; go two up
	mov	ss:points[20].P_y, cx
	sub	cx, 4			; go two down (from middle)
	mov	ss:points[24].P_y, cx

	movdw	ss:points[28], bxax

	clr	di
	call	GrCreateState

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	push	ds
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 8
	call	GrDrawPolygon
	pop	ds

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion
	call	GrDestroyState

adjustForLineBounds::
	dec	ss:points[4].P_x
	dec	ss:points[8].P_x
	dec	ss:points[8].P_y
	dec	ss:points[12].P_y
	dec	ss:points[16].P_y
	sub	ss:points[20].P_y, 2
	inc	ss:points[28].P_y
	movdw	ss:points[24], ss:points[28], ax

	push	bx			; save region handle

	; Allocate vardata and store the points to be drawn in
	; RudyDrawBubbleBorder.
	;
	mov	si, ss:[self]
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	mov	cx, size WedgeWinBorderStruct
	call	ObjVarAddData

	push	ds, es
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 7

	; Copy the points into the vardata structure, but transform the x
	; coordinate from screen coordinates to the origin of the popup
	; window which is, of course, the X origin of the spout.
	; The transform in the Y direction is just subtracting off the Y
	; origin of the region so that it starts on the very top of the window.
	;
	mov	bx, ss:[spoutOriginX]	; X adjustment
	mov	dx, ss:points[0].P_y	; Y adjustment

nextPoint:
	lodsw				; borderX = regionX - spoutOriginX
	sub	ax, bx
	stosw
	lodsw				; borderY = regionY - Yorigin
	sub	ax, dx
	stosw
	loop	nextPoint
	pop	ds, es

	pop	bx			; restore region handle
done:
	.leave
	ret

noRegion:
	;
	; Make sure to delete the vardata in case it previously existed and
	; now the region cannot be drawn.
	;
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	mov	si, ss:[self]
	call	ObjVarDeleteData

	mov	ss:[spoutOriginX], -1
	call	BubbleForceRecalcSizeIfNeeded

noRegionNotPopup:			; not a popup, don't bother with above
					; stuff...
	clr	bx
	jmp	done

if (0) ; Wedges only go to left, so we don't need this.
GetWedgeXoffsets:
	push	bx
	mov	bx, activatorBounds.R_left
	add	bx, activatorBounds.R_right
	shr	bx, 1

	sub	bx, WEDGE_SIZE / 2
	cmp	ax, bx
	jl	101$

	mov	cx, ax
	add	cx, WEDGE_SIZE
	jmp	103$
101$:
	add	bx, WEDGE_SIZE
	cmp	cx, bx
	jg	102$

	mov	ax, cx
	sub	ax, WEDGE_SIZE
	jmp	103$
102$:
	mov	cx, bx
	mov	ax, bx
	sub	ax, WEDGE_SIZE
103$:
	pop	bx
	retn
endif

GetWedgeYoffsets:
	push	ax
	mov	ax, activatorBounds.R_top
	add	ax, activatorBounds.R_bottom
	shr	ax, 1

	sub	ax, WEDGE_SIZE / 2
	cmp	bx, ax
	jl	201$

	mov	dx, bx
	add	dx, WEDGE_SIZE
	jmp	203$
201$:
	add	ax, WEDGE_SIZE
	cmp	dx, ax
	jg	202$

	mov	bx, dx
	sub	bx, WEDGE_SIZE
	jmp	203$
202$:
	mov	dx, ax
	mov	bx, ax
	sub	bx, WEDGE_SIZE
203$:
	pop	ax
	retn

OpenWinCreateWindowRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BubbleGetOriginalBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bounds of the bubble without considering the
		spout.

CALLED BY:	OpenWinCreateWindowRegion

PASS:		*ds:si	= OLWinClassObject

RETURN:		ax,bx,cx,dx	= bounds of bubble without spout

DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	    This is a pretty simple idea.  Get the vis bounds of the
	    window but check for the existence of TEMP_OL_WIN_BUBBLE_MARGIN.
	    If this exists, the code in OpenWinGetMargins just straight up
	    adds this value into the left margin (thereby subtracting the
	    left bounds by this amount) and thus we have to just add that
	    value back in to get the real bounds.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BubbleGetOriginalBounds	proc	near
	uses	bp
	.enter

	clr	bp
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarFindData
	jnc	notTouchedYet
	mov	bp, {word}ds:[bx]

notTouchedYet:
	call	VisGetBounds
	add	ax, bp

	.leave
	ret
BubbleGetOriginalBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BubbleForceRecalcSizeIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the window's geometry needs to be
		recalculcated because of the spout.  It really attempts to
		not do recalculations more than needed.

		If there is a spout, this routine guarentees that the
		left edge of the window is equal to the spoutOriginX.

CALLED BY:	OpenWinCreateWindowRegion

PASS:		ss:bp	= OpenWinCreateWindowRegion stack frame
			  (uses spoutOriginX and self)

		If spoutOriginX >= 0, then

		    ax	= left margin of window NOT INCLUDING any spout

		else this function assumes that there will be no spout and
		may force the window's geometry to be recalculated if
		necessary.  I.e., it does the "right thing."

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	    If there is a spout, then recalculate the margin and force geometry
	    recalculation of the window (and its children) IF any of the
	    following is true:
		    If there is no vardata containing the extra margin
		    (TEMP_OL_WIN_BUBBLE_MARGIN).
		    	This covers initial condition or if the popup's
			spout origin changes to where it is now visible.

		    If the margin isn't the same as the margin calculated
		    by taking the passed AX (left bound without spout)
		    and subtracting spoutOriginX.
		    	This covers the case of the window content's size
			changing or the spout origin changing so that the
			margin is different.

		    If the true left bound of the window isn't the same as
		    spoutOriginX.
		    	This, basically, just CYA in case all else fails.
			This fact, that the left bound should be equal to
			the spoutOriginX, needs to be true.

	    If there is NO SPOUT, then recalculate the margin and force
	    geometry recalculation of the window (and its children) if
	    there the extra margin vardata exists.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BubbleForceRecalcSizeIfNeeded	proc	near
	uses	di, bp, bx, si
	.enter	inherit OpenWinCreateWindowRegion

	; load my own chunk handle
	mov	si, ss:[self]

	; Check for temporary margin vardata.  If it doesn't exist, and we
	; have a valid spout X origin, then we need to force recalculation.
	; If there isn't a spout, deal with cleaning up any vardata.
	;
	clr	di
	push	ax
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarFindData
	pop	ax

	pushf
	cmp	ss:[spoutOriginX], 0		; if < 0, no spout.
	jl	noSpout				;   clean up.
	popf

	jnc	forceRecalc
	mov	di, {word}ds:[bx]		; load di with stored margin

	; If left margin of window WITHOUT SPOUT - spout origin X does NOT
	; equal our current margin, then we need to recalculate the margin
	; and thus the geometry.
	;
	push	ax
	sub	ax, ss:[spoutOriginX]
	cmp	di, ax
	pop	ax
	jne	forceRecalc

	; If the left bounds of the window itself does not equal the spout
	; origin X coordinate, then we again need to recalculate.
	;
	call	WinCommon_DerefVisSpec_DI
	mov	di, ds:[di].VI_bounds.R_left
	cmp	ss:[spoutOriginX], di
	jne	forceRecalc

exit:

if ERROR_CHECK
    	cmp	ss:[spoutOriginX], 0
	jl	_EC_noSpout
	push	di
	call	WinCommon_DerefVisSpec_DI
	mov	di, ds:[di].VI_bounds.R_left
	cmp	ss:[spoutOriginX], di
	ERROR_NE	OL_BUBBLE_DIALOG_BOUNDS_MISMATCH__INTERNAL_ERROR
	    ;
	    ; At this point, the bounds of the window should have been
	    ; recalculated and the left bound of the window SHOULD be
	    ; equal to the spout origin X.  This is a real bummer if this is
	    ; not the case.  --JimG 7/24/95.
	    ;
	pop	di

_EC_noSpout:
endif ;ERROR_CHECK

	.leave
	ret

	; Add the vardata with the correct margin and force the
	; recalculation of the window's geometry.
	;
forceRecalc:
	push	ax, cx, dx			; save registers
	mov	dx, ax				; save left bounds
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	mov	cx, 2
	call	ObjVarAddData

	sub	dx, ss:[spoutOriginX]		; new margin
	mov	{word}ds:[bx], dx

forceRecalcOnly:
	;; NOTE: At this point we expect (AX CX DX) to be on the stack.
	;; PLEASE BE CAREFUL.
	;;
	push	bp				; save local pointer

	;
	; Okay.. so I wrote ugly code.. so sue me.  I can't convince the
	; silly geometry manager to actually move the damn left bounds over
	; to shrink the width of the window in the case of a popup no longer
	; drawing a spout when it used to.  So this forces the left bound
	; to be the right bound-1 and then we reset the geometry on the
	; whole tree and then force it to update its geometry.
	;
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	call	WinCommon_DerefVisSpec_DI
	mov	ax, ds:[di].VI_bounds.R_right
	dec	ax
	mov	ds:[di].VI_bounds.R_left, ax

	mov	ax, MSG_VIS_UPDATE_GEOMETRY
	call	ObjCallInstanceNoLock

	pop	bp

	pop	ax, cx, dx
	jmp	exit

noSpout:
	; No spout.. clean up as needed.
	;
	popf					; carry set if vardata exists
	jnc	exit				; no vardata, no recalc needed

	; Otherwise, vardata exists, but there's no spout so we need to zap
	; that vardata and force the recalculation.

	push	ax, cx, dx			; save registers just like
						; expected in forceRecalc

	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarDeleteData
EC <	ERROR_C	OL_ERROR			; vardata should be here>
	jmp	forceRecalcOnly

BubbleForceRecalcSizeIfNeeded	endp


;===========================================================================
;===========================================================================
;                        END BUBBLE CODE CURRENTLY USED IN RUDY
;===========================================================================
;===========================================================================

else	;wedges can go in any direction



OpenWinCreateWindowRegion	proc	near
	class	OLWinClass

self	local	word		push	si
side	local	word
points	local	8 dup (Point)
activatorBounds	local	Rectangle
	uses	si, di, bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	LONG	jz	noRegion

	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
	LONG	jnc	noRegion

	push	bp, si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_META_GET_ACTIVATOR_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, bp
	pop	bp, si
	LONG	jnc	noRegion

	mov	activatorBounds.R_left, ax
	mov	activatorBounds.R_top, di
	mov	activatorBounds.R_right, cx
	mov	activatorBounds.R_bottom, dx

	call	VisGetBounds		; pass bounds, as screen coords

	clr	si
	push	ax
	add	ax, MINIMUM_SPOUT_SIZE	; make sure spouts at least this big
	cmp	activatorBounds.R_right, ax
	pop	ax

	jge	checkRight
	ornf	si, WIN_LEFT
	mov	ss:points[0].P_x, ax
	push	ax
	mov	ax, activatorBounds.R_right
	sub	ss:points[0].P_x, ax
	pop	ax
	jmp	checkTop

checkRight:
	cmp	activatorBounds.R_left, cx
	jle	checkTop
	ornf	si, WIN_RIGHT
	push	cx
	mov	cx, activatorBounds.R_left
	mov	ss:points[0].P_x, cx
	pop	cx
	sub	ss:points[0].P_x, cx

checkTop:
	cmp	activatorBounds.R_bottom, bx
	jge	checkBottom
	ornf	si, WIN_TOP
	mov	ss:points[0].P_y, bx
	push	bx
	mov	bx, activatorBounds.R_bottom
	sub	ss:points[0].P_y, bx
	pop	bx
	jmp	chooseSide

checkBottom:
	cmp	activatorBounds.R_top, dx
	jle	chooseSide
	ornf	si, WIN_BOTTOM
	push	dx
	mov	dx, activatorBounds.R_top
	mov	ss:points[0].P_y, dx
	pop	dx
	sub	ss:points[0].P_y, dx

chooseSide:
	xchg	ax, si
	mov	ah, al
	xchg	si, ax

	tst	si
	jz	noRegion

	test	si, WIN_LEFT or WIN_RIGHT
	jz	haveSide

	test	si, WIN_TOP or WIN_BOTTOM
	jz	haveSide

	push	ax
	mov	ax, ss:points[0].P_x
	cmp	ax, ss:points[0].P_y
	pop	ax
	jge	leftRight

	andnf	si, not (WIN_LEFT or WIN_RIGHT)
	jmp	haveSide

leftRight:
	andnf	si, not (WIN_TOP or WIN_BOTTOM)

haveSide:
	mov	ss:[side], si
	movdw	ss:points[0], bxax	; 0------------>1
	movdw	ss:points[4], bxcx	; ^		|
	movdw	ss:points[8], dxcx	; |		v
	movdw	ss:points[12], dxax	; 3<------------2

	test	si, WIN_LEFT
	jz	tryRight
	call	GetWedgeYoffsets

	movdw	ss:points[16], dxax

	mov	cx, activatorBounds.R_right
	mov	ss:points[20].P_x, cx
	mov	ss:points[24].P_x, cx
	mov	cx, activatorBounds.R_top
	add	cx, activatorBounds.R_bottom
	shr	cx, 1
	inc	cx
	mov	ss:points[20].P_y, cx
	dec	cx
	dec	cx
	mov	ss:points[24].P_y, cx

	movdw	ss:points[28], bxax


	jmp	makeRegion
tryRight:
	test	si, WIN_RIGHT
	jz	tryTop

	call	GetWedgeYoffsets

	movdw	ss:points[28], ss:points[12], ax
	movdw	ss:points[24], ss:points[8], ax
	movdw	ss:points[8], bxcx

	mov	ax, activatorBounds.R_left
	mov	ss:points[12].P_x, ax
	mov	ss:points[16].P_x, ax
	mov	ax, activatorBounds.R_top
	add	ax, activatorBounds.R_bottom
	shr	ax, 1
	dec	ax
	mov	ss:points[12].P_y, ax
	inc	ax
	inc	ax
	mov	ss:points[16].P_y, ax

	movdw	ss:points[20], dxcx
	jmp	makeRegion

tryTop:
	test	si, WIN_TOP
	jz	doBottom

	call	GetWedgeXoffsets

	movdw	ss:points[28], ss:points[12], dx
	movdw	ss:points[24], ss:points[8], dx
	movdw	ss:points[20], ss:points[4], dx
	movdw	ss:points[4], bxax

	mov	dx, activatorBounds.R_left
	add	dx, activatorBounds.R_right
	shr	dx, 1
	dec	dx
	mov	ss:points[8].P_x, dx
	inc	dx
	inc	dx
	mov	ss:points[12].P_x, dx
	mov	dx, activatorBounds.R_bottom
	mov	ss:points[8].P_y, dx
	mov	ss:points[12].P_y, dx

	movdw	ss:points[16], bxcx
	jmp	makeRegion

doBottom:
	call	GetWedgeXoffsets

	movdw	ss:points[28], ss:points[12], bx
	movdw	ss:points[12], dxcx

	mov	bx, activatorBounds.R_left
	add	bx, activatorBounds.R_right
	shr	bx, 1
	inc	bx
	mov	ss:points[16].P_x, bx
	dec	bx
	dec	bx
	mov	ss:points[20].P_x, bx
	mov	bx,  activatorBounds.R_top
	mov	ss:points[16].P_y, bx
	mov	ss:points[20].P_y, bx

	movdw	ss:points[24], dxax
makeRegion:

	clr	di
	call	GrCreateState

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	push	ds
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 8
	call	GrDrawPolygon
	pop	ds

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion
	call	GrDestroyState

adjustForLineBounds::
	test	ss:[side], WIN_LEFT
	jz	tryRightAdjust
leftAdjust::
	dec	ss:points[4].P_x
	dec	ss:points[8].P_x
	dec	ss:points[8].P_y
	dec	ss:points[12].P_y
	dec	ss:points[16].P_y
	dec	ss:points[20].P_y
	inc	ss:points[28].P_y
	movdw	ss:points[24], ss:points[28], ax
	jmp	storePoints

tryRightAdjust:
	test	ss:[side], WIN_RIGHT
	jz	tryTopAdjust
rightAdjust:
	dec	ss:points[4].P_x
	dec	ss:points[8].P_x
	inc	ss:points[8].P_y
	dec	ss:points[12].P_x
	inc	ss:points[12].P_y
	dec	ss:points[20].P_x
	dec	ss:points[20].P_y
	dec	ss:points[24].P_x
	dec	ss:points[24].P_y
	dec	ss:points[28].P_y
	movdw	ss:points[16], ss:points[20], ax
	movdw	ss:points[20], ss:points[24], ax
	movdw	ss:points[24], ss:points[28], ax
	jmp	storePoints

tryTopAdjust:
	test	ss:[side], WIN_TOP
	jz	bottomAdjust
topAdjust:
	inc	ss:points[4].P_x
	inc	ss:points[8].P_x
	dec	ss:points[16].P_x
	dec	ss:points[20].P_x
	dec	ss:points[24].P_x
	dec	ss:points[24].P_y
	dec	ss:points[28].P_y
	movdw	ss:points[12], ss:points[16], ax
	movdw	ss:points[16], ss:points[20], ax
	movdw	ss:points[20], ss:points[24], ax
	movdw	ss:points[24], ss:points[28], ax
	jmp	storePoints

bottomAdjust:
	dec	ss:points[4].P_x
	dec	ss:points[8].P_x
	dec	ss:points[8].P_y
	dec	ss:points[12].P_x
	dec	ss:points[12].P_y
	dec	ss:points[16].P_x
	dec	ss:points[16].P_y
	inc	ss:points[24].P_x
	dec	ss:points[24].P_y
	dec	ss:points[28].P_y
	movdw	ss:points[16], ss:points[20], ax
	movdw	ss:points[20], ss:points[24], ax
	movdw	ss:points[24], ss:points[28], ax

storePoints:
	push	bx
	call	MemLock
	push	ds
	mov	ds, ax
	mov	cx, ds:[R_left]
	mov	dx, ds:[R_top]
	pop	ds
	call	MemUnlock

	sub	cx, ss:points[0].P_x
	sub	dx, ss:points[0].P_y

	test	ss:[side], WIN_LEFT or WIN_RIGHT
	jz	noWorry
	test	ss:[side], WIN_TOP shl 8
	jz	noWorry

	inc	dx

noWorry:
	push	cx, dx
	mov	si, ss:[self]
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	mov	cx, size WedgeWinBorderStruct
	call	ObjVarAddData
	pop	cx, dx

	mov	ds:[bx].WWBS_windowAdj.P_x, cx
	mov	ds:[bx].WWBS_windowAdj.P_y, dx

	push	cx, dx
	push	ds, es
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 7

	mov	bx, ss:points[0].P_x
	mov	dx, ss:points[0].P_y

nextPoint:
	lodsw
	sub	ax, bx
	stosw
	lodsw
	sub	ax, dx
	stosw
	loop	nextPoint
	pop	ds, es
	pop	cx, dx

	pop	bx
done:
	.leave
	ret

noRegion:
	clr	bx
	jmp	done


GetWedgeXoffsets:
	push	bx
	mov	bx, activatorBounds.R_left
	add	bx, activatorBounds.R_right
	shr	bx, 1

	sub	bx, WEDGE_SIZE / 2
	cmp	ax, bx
	jl	101$

	mov	cx, ax
	add	cx, WEDGE_SIZE
	jmp	103$
101$:
	add	bx, WEDGE_SIZE
	cmp	cx, bx
	jg	102$

	mov	ax, cx
	sub	ax, WEDGE_SIZE
	jmp	103$
102$:
	mov	cx, bx
	mov	ax, bx
	sub	ax, WEDGE_SIZE
103$:
	pop	bx
	retn

GetWedgeYoffsets:
	push	ax
	mov	ax, activatorBounds.R_top
	add	ax, activatorBounds.R_bottom
	shr	ax, 1

	sub	ax, WEDGE_SIZE / 2
	cmp	bx, ax
	jl	201$

	mov	dx, bx
	add	dx, WEDGE_SIZE
	jmp	203$
201$:
	add	ax, WEDGE_SIZE
	cmp	dx, ax
	jg	202$

	mov	bx, dx
	sub	bx, WEDGE_SIZE
	jmp	203$
202$:
	mov	dx, ax
	mov	bx, ax
	sub	bx, WEDGE_SIZE
203$:
	pop	ax
	retn

OpenWinCreateWindowRegion	endp

endif 	;WEDGES_TO_LEFT_ONLY


else	;CURVED_BUBBLE_DIALOG

WIN_LEFT	= 0001b
WIN_RIGHT	= 0010b
WIN_TOP		= 0100b
WIN_BOTTOM	= 1000b
WEDGE_SIZE	= 24

OpenWinCreateWindowRegion	proc	near
	class	OLWinClass

self	local	word		push	si
side	local	word
points	local	20 dup (Point)
activatorBounds	local	Rectangle
	uses	si, di, bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	LONG	jz	noRegion

	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarFindData
	LONG	jnc	noRegion

	push	bp, si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_META_GET_ACTIVATOR_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, bp
	pop	bp, si
	LONG	jnc	noRegion

	mov	activatorBounds.R_left, ax
	mov	activatorBounds.R_top, di
	mov	activatorBounds.R_right, cx
	mov	activatorBounds.R_bottom, dx

	call	VisGetBounds		; pass bounds, as screen coords

	clr	si
	cmp	activatorBounds.R_right, ax
	jge	checkRight
	ornf	si, WIN_LEFT
	mov	ss:points[0].P_x, ax
	push	ax
	mov	ax, activatorBounds.R_right
	sub	ss:points[0].P_x, ax
	pop	ax
	jmp	checkTop

checkRight:
	cmp	activatorBounds.R_left, cx
	jle	checkTop
	ornf	si, WIN_RIGHT
	push	cx
	mov	cx, activatorBounds.R_left
	mov	ss:points[0].P_x, cx
	pop	cx
	sub	ss:points[0].P_x, cx

checkTop:
	cmp	activatorBounds.R_bottom, bx
	jge	checkBottom
	ornf	si, WIN_TOP
	mov	ss:points[0].P_y, bx
	push	bx
	mov	bx, activatorBounds.R_bottom
	sub	ss:points[0].P_y, bx
	pop	bx
	jmp	chooseSide

checkBottom:
	cmp	activatorBounds.R_top, dx
	jle	chooseSide
	ornf	si, WIN_BOTTOM
	push	dx
	mov	dx, activatorBounds.R_top
	mov	ss:points[0].P_y, dx
	pop	dx
	sub	ss:points[0].P_y, dx

chooseSide:
	xchg	ax, si
	mov	ah, al
	xchg	si, ax

	tst	si
	LONG	jz	noRegion

	test	si, WIN_LEFT or WIN_RIGHT
	LONG	jz	haveSide

	test	si, WIN_TOP or WIN_BOTTOM
	jz	haveSide

	push	ax
	mov	ax, ss:points[0].P_x
	cmp	ax, ss:points[0].P_y
	pop	ax
	jge	leftRight

	andnf	si, not (WIN_LEFT or WIN_RIGHT)
	jmp	haveSide

leftRight:
	andnf	si, not (WIN_TOP or WIN_BOTTOM)

haveSide:
	add	ax, 10		;10 points reserved for curve
	mov	ss:[side], si
	movdw	ss:points[0], bxax	; 0------------>1
	movdw	ss:points[4], bxcx	; ^		|
	movdw	ss:points[8], dxcx	; |		v
	movdw	ss:points[12], dxax	; 3<------------2
	sub	ax, 10		;10 points reserved for curve

	test	si, WIN_LEFT
	LONG	jz	noRegion		;can't do left, no bubble.

	call	GetWedgeYoffsets

	mov	cx, 12 or CCP_COUNTING_UP	;last point offset
	call	CalcCurvePoints

	movdw	ss:points[40], dxax

	mov	cx, activatorBounds.R_right
	mov	ss:points[44].P_x, cx
	mov	ss:points[48].P_x, cx
	mov	cx, activatorBounds.R_top
	add	cx, activatorBounds.R_bottom
	shr	cx, 1
	inc	cx
	mov	ss:points[44].P_y, cx
	dec	cx
	dec	cx
	mov	ss:points[48].P_y, cx

	movdw	ss:points[52], bxax

	movdw	dxax, ss:points[0]	;our destination
	mov	cx, 52 or CCP_COUNTING_DOWN
	call	CalcCurvePoints

	clr	di
	call	GrCreateState

	mov	cx, PCT_REPLACE
	call	GrBeginPath

	push	ds
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 20
	call	GrDrawPolygon
	pop	ds

	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrGetPathRegion
	call	GrDestroyState

	inc	ss:points[0].P_x	;match up with top curve?

	dec	ss:points[4].P_x
	dec	ss:points[8].P_x
	dec	ss:points[8].P_y

	dec	ss:points[12].P_y
	inc	ss:points[12].P_x

	dec	ss:points[16].P_y
	inc	ss:points[16].P_x

	dec	ss:points[20].P_y
	inc	ss:points[20].P_x

	dec	ss:points[24].P_y
	inc	ss:points[24].P_x

	dec	ss:points[28].P_y
	inc	ss:points[28].P_x

	dec	ss:points[32].P_y
	inc	ss:points[32].P_x

	dec	ss:points[36].P_y
	inc	ss:points[36].P_x

	dec	ss:points[40].P_y
	inc	ss:points[40].P_x

	inc	ss:points[48].P_x		;point
	inc	ss:points[48].P_y
	movdw	ss:points[44], ss:points[48], ax

	inc	ss:points[52].P_y
	inc	ss:points[52].P_x

	inc	ss:points[56].P_x
	inc	ss:points[60].P_x
	inc	ss:points[64].P_x
	inc	ss:points[68].P_x
	inc	ss:points[72].P_x
	inc	ss:points[76].P_x

	push	bx
	call	MemLock
	push	ds
	mov	ds, ax
	mov	cx, ds:[R_left]
	mov	dx, ds:[R_top]
	pop	ds
	call	MemUnlock

	sub	cx, ss:points[0].P_x
	sub	dx, ss:points[0].P_y

	test	ss:[side], WIN_LEFT or WIN_RIGHT
	jz	noWorry
	test	ss:[side], WIN_TOP shl 8
	jz	noWorry

	inc	dx

noWorry:
	push	cx, dx
	mov	si, ss:[self]
	mov	ax, TEMP_OL_WIN_BORDER_POINTS
	mov	cx, size WedgeWinBorderStruct
	call	ObjVarAddData
	pop	cx, dx

	mov	ds:[bx].WWBS_windowAdj.P_x, cx
	mov	ds:[bx].WWBS_windowAdj.P_y, dx

	push	cx, dx
	push	ds, es
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, ss:[points]
	mov	cx, 19

	mov	bx, ss:points[0].P_x
	mov	dx, ss:points[0].P_y

nextPoint:
	lodsw
	sub	ax, bx
	stosw
	lodsw
	sub	ax, dx
	stosw
	loop	nextPoint
	pop	ds, es
	pop	cx, dx

	pop	bx
done:
	.leave
	ret

noRegion:
	clr	bx
	jmp	done


GetWedgeXoffsets:
	push	bx
	mov	bx, activatorBounds.R_left
	add	bx, activatorBounds.R_right
	shr	bx, 1

	sub	bx, WEDGE_SIZE / 2
	cmp	ax, bx
	jl	101$

	mov	cx, ax
	add	cx, WEDGE_SIZE
	jmp	103$
101$:
	add	bx, WEDGE_SIZE
	cmp	cx, bx
	jg	102$

	mov	ax, cx
	sub	ax, WEDGE_SIZE
	jmp	103$
102$:
	mov	cx, bx
	mov	ax, bx
	sub	ax, WEDGE_SIZE
103$:
	pop	bx
	retn

GetWedgeYoffsets:
	push	ax
	mov	ax, activatorBounds.R_top
	add	ax, activatorBounds.R_bottom
	shr	ax, 1

	sub	ax, WEDGE_SIZE / 2
	cmp	bx, ax
	jl	201$

	mov	dx, bx
	add	dx, WEDGE_SIZE
	jmp	203$
201$:
	add	ax, WEDGE_SIZE
	cmp	dx, ax
	jg	202$

	mov	bx, dx
	sub	bx, WEDGE_SIZE
	jmp	203$
202$:
	mov	dx, ax
	mov	bx, ax
	sub	bx, WEDGE_SIZE
203$:
	pop	ax
	retn


OpenWinCreateWindowRegion	endp

endif   ; CURVED_BUBBLE_DIALOG
endif	; if BUBBLE_DIALOGS and (not (_DUI)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCurvePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a set if points to create a simple curve.

CALLED BY:	OpenWinCreateWindowRegion

PASS:		cl   -- offset to last point stored in points structure
		ch   -- 0 if starting curve, 5 if ending curve (table index)
		dxax -- next point we're supposed to curve to
		ss:bp-- OpenWinCreateWindowRegion locals

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Register usage:
		si -- index into point table
		di -- table index
		cx -- increment (-1 or 1)
		ax -- current x position
		dx -- starting y position
		bx -- distance
		bp -- local variables

	endpoint is x1, y1
	x0,y0 (starting point) = points[last point index]
	dist = y1 - y0
	for i = 0 to 5 (or 5 to 0) {
		x = x = xChangeTable[i]
		points[last point index + (i*4)] = (x, y-distance*curveTable[i]
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	the curveTable and xChangeTable are not rocket science, they're just
	derived from making a 10 x 10 point curve on a piece of graph paper

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/21/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS
if CURVED_BUBBLE_DIALOG

CCP_COUNTING_UP	  equ	0
CCP_COUNTING_DOWN equ	(offset curveTableEnd - offset curveTableDown) shl 8

CalcCurvePoints	proc	near		uses	ax,bx,cx,dx,si,di
	.enter inherit OpenWinCreateWindowRegion
	clr	bx
	mov	bl, cl
	mov	si, bx				;si <- point index

	sub	dx, points[si].P_y		;see y distance to go
	neg	dx
	mov	bx, dx
	movdw	dxax, points[si]		;keep around starting point
	add	si, size Point			;advance to next point

	mov	cl, ch
	clr	ch
	mov	di, cx				;table index
	mov	cx, size word			;assume counting up
	tst	di
	jz	ptLoop				;starting from zero, branch
	neg	cx				;else counting down
	add	di, offset curveTableDown - offset curveTable
ptLoop:
	push	cx
	sub	ax, cs:xChangeTable[di]		;change x position

	push	ax, dx
	mov	ax, cs:curveTable[di]		;get curve fraction
	clr	dx				;  in dx.ax
	mul	bx				;multiply by dist -> dx.ax
	tst	ax
	jns	10$
	inc	dx
10$:						;OK, value to subtract in dx.
	mov	cx, dx				;now in cx
	pop	ax, dx				;restore our registers
	push	dx				;save y value again
	sub	dx, cx				;calculate the y for this point
	movdw	points[si], dxax		;store the point
	pop	dx				;restore y point start
	pop	cx

	add	si, size Point			;advance to next point
	add	di, cx				;inc or dec table count
	cmp	di, offset curveTableMiddle - offset curveTable
						;have we gone negative or
						;  past the end of the table?
	jne	ptLoop				;nope, do another point
	.leave
	ret

CalcCurvePoints	endp

curveTable	label	word
	word	0ffffh*10/100		;10% of curve
	word	0ffffh*20/100		;10%
	word	0ffffh*30/100		;10%
	word	0ffffh*40/100		;10%
	word	0ffffh*50/100		;10%
	word	0ffffh*70/100		;20%

curveTableMiddle	label	word
	word	0ffffh			;30%  (unused)

curveTableDown	label 	word
	word	0ffffh*90/100		;10%
	word	0ffffh*80/100		;10%
	word	0ffffh*70/100		;10%
	word	0ffffh*60/100		;10%
	word	0ffffh*50/100		;20%
curveTableEnd	label	word
	word	0ffffh*30/100		;30%

xChangeTable		word	 3,  2,  1,  1,  1,  1
			word	 0 				;unused
			word	-3, -2, -1, -1, -1, -1
endif
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetWinColor

DESCRIPTION:	Fetches color info for call to WinOpen

CALLED BY:	INTERNAL
		OpenWinOpenWin

PASS:		*ds:si	- OLWinClass object

RETURN:		al	- color index
		ah	- WinColorFlags
		bx	- WinPassFlags

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@
GetWinColor	proc	near
	uses	cx
	.enter

	;
	; set up AH = window type flags, AL = window background color
	;
	; Choose a COLOR for the window
	;

if WINDOW_WASH_COLOR
	mov	ax, HINT_WINDOW_WASH_COLOR
	call	ObjVarFindData
	jnc	noWashColor
	mov	al, ds:[bx]
	jmp	afterColor
noWashColor:
endif

if _CUA_STYLE	;START of CUA_STYLE specific code -----------------------------
	push	ds
	call	WinCommon_DerefVisSpec_DI
	mov	cl, ds:[di].OLWI_type
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU

	;
	; CUA/Motif: grab color value from color scheme variables in idata
	;
	mov	ax, dgroup			;get segment of core block
	mov	ds, ax
	mov	al, ds:[moCS_menuBar]		;assume is menu
	jnz	OWOW_haveColor			;skip if is menu...

	mov	al, ds:[moCS_screenBG]		;assume is icon
	cmp	cl, MOWT_WINDOW_ICON
	je	OWOW_haveColor			;skip if is icon...

	;is not menu or icon: is fixed color
	;(changed 2/15/91 cbh to use real light color)

MO <	mov	al, C_WHITE		;assume B&W display		>
MO <	test	ds:[moCS_flags], mask CSF_BW ; is this a B&W display?	>
MO <	jnz	OWOW_haveColor		;   skip if so...		>
MO <	mov	al, ds:[moCS_dsLightColor]	;else use light color	>
ISU <	mov	al, C_WHITE		;assume B&W display		>
ISU <	test	ds:[moCS_flags], mask CSF_BW ; is this a B&W display?	>
ISU <	jnz	OWOW_haveColor		;   skip if so...		>
ISU <	mov	al, ds:[moCS_dsLightColor]	;else use light color	>
OWOW_haveColor:
	pop	ds
endif		;END of CUA_STYLE specific code -------------------------------

afterColor::
	mov	ah, mask CMM_ON_BLACK or CMT_CLOSEST
afterWinColorFlagsSet::

	clr	bx			; no green or blue colors

	.leave
	ret
GetWinColor	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetCoreWinOpenParams

DESCRIPTION:	Fetches core info needed for WinOpen

CALLED BY:	INTERNAL
		OpenWinOpenWin

PASS:		*ds:si	- OLWinClass object
		di	- default parent window

RETURN:		cx	- WinPassFlags
		dx	- LayerID
		di	- parent Window

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
			WinPrio		LayerPrio	parent	layerID
			-------		---------	------  -------
Primarys, Displays	WIN_PRIO_STD	default (NULL)	default	geode handle
command windows		WIN_PRIO_COMMANDdefault (NULL)	default	geode handle
app modal dialog	WIN_PRIO_MODAL	default (NULL)	default geode handle
popup windows		WIN_PRIO_POPUP	default (NULL)	default	geode handle
sys modal dialog	WIN_PRIO_MODAL	LAYER_PRIO_MODALscreen	handle of block

Custom Win prio		custom
Custom Layer prio			custom
Custom LayerID							custom
	Sys menu/popup of above					""
Custom parent window					custom
	Sys menu/popup of above				""


NOTES:
	1) It is imperative that all windows of a given layer have the same
	   Layer priority passed, as the window system cannot deal with any
	   other scenario.
	2) At this time, ATTR_GEN_WINDOW_CUSTOM_PARENT(0) may NOT be placed
	   on an app modal dialog.  Reason?  The app wouldn't be able to find
	   it to move the focus on down to the next dialog in a series.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	(2) above.  With a little work, OLApplication might be able to deal
	with this, if people would find the option useful.

	Does NOT deal w/popup windows (other than the system menu) which
	belong to a window having been placed on the screen.  These windows
	should be placed on the screen as well, & given the same LayerID &
	LayerPrio as the dialog they come from.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@
LAYER_ID_FOR_ICONS	equ	10171	; A Unique layer ID for all icons

GetCoreWinOpenParams	proc	near
	uses	ax, bx, bp
	.enter

	clr	cx			; Init WinPassFlags

	call	GeodeGetProcessHandle	; Init LayerID to app default -- geode
	mov	dx, bx			;	handle

	;
	; Icons should have the same low priority, regardless of
	; what the application priorities are, so give them a unique
	; layer ID.
	;

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset

if (0)	; Don't give unique layer ID, so icons for desk -----------------------
	; accessories will stay on top. - Joon (7/18/94)

if _CUA_STYLE
	cmp	ds:[bx].OLWI_type, MOWT_WINDOW_ICON
else
	.err	<Must choose either CUA_STYLE or MAC>
endif
	jne	notWinIcon
	mov	dx, LAYER_ID_FOR_ICONS
notWinIcon:
endif	; if (0) --------------------------------------------------------------

	;
	; MODALITY
	;
	; First, check to see if of OLPopupWinClass -- if not, can't be modal.
	;
	test	ds:[bx].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	lookupPriority

	test	ds:[bx].OLPWI_flags, mask OLPWF_APP_MODAL or \
							mask OLPWF_SYS_MODAL
	jz	lookupPriority

modal::
	mov	cl, WIN_PRIO_MODAL	; Use modal window priority
	ornf	cx, mask WPF_SAVE_UNDER	; Use save-under for all modal windows

					; see if system modal or not
	test	ds:[bx].OLPWI_flags, mask OLPWF_SYS_MODAL
	LONG	jz	haveBasicDefaults  ; if just app modal, have priority

	; Place sys-modal layer at "MODAL" level, to be above
	; "screen-floating" windows
	;
	ornf	cl, (LAYER_PRIO_MODAL shl offset WPD_LAYER)
	call	GetScreenWin		; Fetch screen window, in di
	mov	dx, ds:[LMBH_handle]	; For windows placed on screen, set
					; LayerID = handle of block object
					; lies in.
	jmp	haveBasicDefaults

lookupPriority:				; Othewise, look up in table.
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bl, ds:[bx].OLWI_type	; get window type
	clr	bh			; fetch priority based on type
	mov	cl, cs:[bx].winPriorityTable

	; If this is a pinned menu, use lower WIN_PRIO_COMMAND priority level
	;
	cmp	cl, WIN_PRIO_POPUP	; see if a menu
	jne	afterPinnedMenuCheck	; if not, skip
	ornf	cx, mask WPF_SAVE_UNDER	; Use save-under for menus
					; If a menu, see if it is pinned
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLWI_specState, mask OLWSS_PINNED
	jz	afterPinnedMenuCheck	; skip if not

	mov	cl, WIN_PRIO_COMMAND	; BUT, if it IS a pinned menu, lower
					; priority.  (Make same as command win)
	andnf	cx, not mask WPF_SAVE_UNDER	; & clear save-under as well
afterPinnedMenuCheck:

haveBasicDefaults:
;----------------------------------------
	;
	; Check to see if windows of this application have a special
	; layer priority, as is the case with application launched in
	; "desk accessory" mode.
	;
	;	cl = default priority
	;	ch = mask WPF_SAVE_UNDER, if needed
	;	di = default window
	;
	mov	al, cl
	andnf	al, mask WPD_LAYER
	cmp	al, (LAYER_PRIO_MODAL shl offset WPD_LAYER)
	je	afterDeskAccessoryCheck	; sys modal, leave layer priority

if (0)	; We'll let icons for desk accessories stay on top as well ------------

	mov	bx, ds:[si]
	add	bx, ds:[bx].OLWin_offset

if _CUA_STYLE
	cmp	ds:[bx].OLWI_type, MOWT_WINDOW_ICON
else
	.err	<Must choose either CUA_STYLE or MAC>
endif
	je	afterDeskAccessoryCheck
endif	; if (0) --------------------------------------------------------------

	; Fetch LayerPriority to use from app object
	;
	push	si
	clr	bx
	call	GeodeGetAppObject
	call	ObjSwapLock
	push	bx
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarFindData
	jnc	afterCustomLayerPrio
	mov	al, ds:[bx]		; fetch layer priority to use
	shl	al, 1			; Shift up to layer prio area
	shl	al, 1
	shl	al, 1
	shl	al, 1
	and	cl, not mask WPD_LAYER
	ornf	cl, al			; OR in layer priority
afterCustomLayerPrio:
	pop	bx
	call	ObjSwapUnlock
	pop	si

afterDeskAccessoryCheck:
;----------------------------------------
	;
	; OK, at this point we've got the standard win parent, priority &
	; LayerID to use.  Before we get into custom attributes on this object
	; itself, we need to adjust the defaults to accomodate the case of
	; this being a system menu (or ideally any popup), which springs from
	; a window that itself has been tampered with by the programmer, in
	; either which parent window it is using, or what LayerID it is in.
	; For those case, we need to copy those same values from the parent,
	; so that the popups stay with the source window.
	;
	;	cl = default priority
	;	ch = mask WPF_SAVE_UNDER, if needed
	;	di = default parent window

	call	OpenWinModifyWithNearestWinGroupPriority

;----------------------------------------
	;
	; OK, now we *really* have default window parent, priority, & LayerID,
	; as the specific UI would have it.  Now, we'll check the various
	; "custom window" attributes that a programmer might have stuck on
	; this window.
	;
	;	cl = default priority
	;	ch = mask WPF_SAVE_UNDER, if needed
	;	di = default window
;----------------------------------------
	;
	; Check for custom window priority
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	call	ObjVarFindData
	jnc	afterWinPrio
EC <	test	{WinPriorityData} ds:[bx], not mask WPD_WIN		>
EC <	ERROR_NZ	OL_BAD_WIN_PRIORITY				>
	and	cl, not mask WPD_WIN
	or	cl, ds:[bx]
afterWinPrio:
;----------------------------------------
	;
	; Check for custom layer priority
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarFindData
	jnc	afterLayerPrio
	mov	al, ds:[bx]
	shl	al, 1			; Shift up to layer prio area
	shl	al, 1
	shl	al, 1
	shl	al, 1
	and	cl, not mask WPD_LAYER
	or	cl, al
afterLayerPrio:
;----------------------------------------
	mov	bx, ds:[si]
	add	bx, ds:[bx].OLWin_offset

if _CUA_STYLE
	cmp	ds:[bx].OLWI_type, MOWT_WINDOW_ICON
else
	.err	<Must choose either CUA_STYLE or MAC>
endif
	je	afterAttrSetLayerID
	;
	; Check for ATTR_GEN_WINDOW_CUSTOM_LAYER_ID layerID override on this
	; object itself
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	call	ObjVarFindData
	jnc	afterAttrSetLayerID
	mov	dx, ds:[bx]
	tst	dx			; if zero, use block handle
	jnz	afterAttrSetLayerID
	mov	dx, ds:[LMBH_handle]
afterAttrSetLayerID:
;----------------------------------------
	;
	; Check for custom parent window
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_PARENT
	call	ObjVarFindData
	jnc	afterCustomParent
	mov	di, ds:[bx]		; get window handle
	tst	di
	jnz	afterCustomParent
	call	GetScreenWin		; Fetch screen window, in di
afterCustomParent:

EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	; ensure good window		>
;----------------------------------------
	;
	; Figure out whether to place in front or behind, both window & layer
	;
					; If bit set to open on top, then do
					; so -- otherwise open behind other
					; windows.
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLWI_fixedAttr, mask OWFA_OPEN_ON_TOP
	jnz	afterOpenOnTop
	ornf	cx, mask WPF_PLACE_BEHIND
afterOpenOnTop:
					; Fetch launch flags from application
					; object (tells us layer info)
	push	cx, dx
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	GenCallApplication
	test	ax, mask ALF_OPEN_IN_BACK
	pop	cx, dx
	jz	afterOpenLayerOnTop
	ornf	cx, mask WPF_PLACE_LAYER_BEHIND
afterOpenLayerOnTop:

	.leave
	ret
GetCoreWinOpenParams	endp


if _CUA_STYLE	;START of MOTIF specific code ---------------------------------
winPriorityTable WinPriorityData \
	< 0, WIN_PRIO_STD >,	; MOWT_PRIMARY_WINDOW
	< 0, WIN_PRIO_STD >,	; MOWT_DISPLAY_WINDOW
	< 0, WIN_PRIO_COMMAND >,; MOWT_COMMAND_WINDOW
	< 0, WIN_PRIO_COMMAND >,; MOWT_PROPERTIES_WINDOW
	< 0, WIN_PRIO_COMMAND >,; MOWT_NOTICE_WINDOW
	< 0, WIN_PRIO_COMMAND >,; MOWT_HELP_WINDOW
	< 0, WIN_PRIO_POPUP >,	; MOWT_MENU
	< 0, WIN_PRIO_POPUP >,	; MOWT_SUBMENU
	< 0, WIN_PRIO_POPUP >,	; MOWT_SYSTEM_MENU
	< 0, WIN_PRIO_STD+1 >	; MOWT_WINDOW_ICON
				;  slightly lower priority so we can
				;  distinguish icons in EnsureActiveFTCommon
				;  has acceptable side-effect of placing icon
				;  below WIN_PRIO_STD windows that remain open
				;  when the app is iconified - brianc 3/17/93
endif		;END of MOTIF specific code -----------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinModifyWithNearestWinGroupPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the layer and window priority of the new window
		to be at least as high as the nearest win group up the
		generic tree.

CALLED BY:	(INTERNAL) GetCoreWinOpenParams
PASS:		*ds:si	= windowed object
		cx	= WinPassFlags
		di	= parent window
		dx	= layer ID
RETURN:		cl, ch, di, dx = modified according to values of nearest
				 wingroup
DESTROYED:	ax
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinModifyWithNearestWinGroupPriority proc	near
passFlags	local	WinPassFlags 	push cx
parentWin	local	hptr.Window	push di
layerID		local	word		push dx
		uses	bx, si
		.enter
	;
	; Only do this for popups
	;
		call	WinCommon_DerefVisSpec_DI
		test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
		jz	toReload
	;
	; But not for modal dialogs
	;
		test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL
		jnz	toReload
		test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
		jnz	toReload
	;
	; Locate the generically-closest win group using our internal query.
	;
		mov	ax, MSG_SPEC_GUP_QUERY
		mov	cx, SGQT_WIN_GROUP
		push	bp
		call	GenCallParent
		mov_tr	ax, bp
		pop	bp
		jc	haveWinGroup
toReload:
		jmp	reload

haveWinGroup:
		mov_tr	di, ax
	;
	; Always use the same layer ID
	;
   		mov	si, WIT_LAYER_ID
		call	WinGetInfo
		mov	ss:[layerID], ax
	;
	; Inherit any custom window parent the win group has.
	;
		push	di
		movdw	bxsi, cxdx
		call	ObjSwapLock
		push	bx
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_PARENT
		call	ObjVarFindData
		jnc	afterParentCheckedForCustomWinParent
		mov	di, ds:[bx]		; get window handle
		tst	di
		jnz	setNewParent
		call	GetScreenWin		; Fetch screen window, in di
setNewParent:
		mov	ss:[parentWin], di

afterParentCheckedForCustomWinParent:
		pop	bx
		call	ObjSwapUnlock
		pop	di
	;
	; Compare the current parentWin against the parent of the nearest
	; wingroup and use the one that is higher in the tree. This ensures
	; that popups that are generically within a sysmodal box will be on
	; the same window (i.e. the screen) as the sysmodal box, while still
	; allowing menus within displays to be on the field, not the display
	; group. I tried to give the thing a proper vis parent by transforming
	; the query for a popup's vis parent to that for a sysmodal when the
	; query passed through a sysmodal interaction, but OLApplication
	; thwarted that gallant attempt by returning itself & the screen (as
	; opposed to its usual return of itself & the field), but no one was
	; ready to receive the window there, so... -- ardeb
	;
		mov	si, WIT_PARENT_WIN
		call	WinGetInfo
		xchg	ss:[parentWin], ax	; assume ancestral and ok
		push	di, ax		; save former parent for possible
					;  restoration, and wingroup for further
					;  interrogation.
checkAncestorLoop:
		cmp	ss:[parentWin], ax
		je	parentWinOK
		mov_tr	di, ax
		mov	si, WIT_PARENT_WIN
		call	WinGetInfo
	    ;
	    ; win group's parent not an ancestor, so restore previous parentWin
	    ;
		tst	ax
		jnz	checkAncestorLoop
		pop	ax
		mov	ss:[parentWin], ax
		push	ax
parentWinOK:
		pop	di, ax
	;
	; Use parent priority for layer & window only if higher (numerically
	; lower) than our own.
	;
		mov	si, WIT_PRIORITY
		call	WinGetInfo

		mov	ah, al
		CheckHack <offset WPF_PRIORITY eq 0 and width WPF_PRIORITY eq 8>
		mov	bl, ss:[passFlags].low
		mov	bh, bl
	;
	; Set the high bytes of ax and bx to hold the respective layer
	; priorities, while the low bytes hold the respective window
	; priorities. Set cl to the highest of each in their respective
	; fields.
	;
		andnf	ax, (mask WPD_LAYER shl 8) or mask WPD_WIN
		andnf	bx, (mask WPD_LAYER shl 8) or mask WPD_WIN
	    ;
	    ; Map passed priorities of 0 to their standard counterparts to
	    ; avoid throwing off the comparison.
	    ;
		tst	bh
		jnz	havePassedLayerPrio
		mov	bh, LAYER_PRIO_STD shl offset WPD_LAYER
havePassedLayerPrio:
		tst	bl
		jnz	havePassedWinPrio
		mov	bl, WIN_PRIO_STD shl offset WPD_WIN
havePassedWinPrio:

		cmp	ah, bh		; assume parent win group's layer
					;  prio is "higher"
		jbe	checkWinPrio	; right
		mov	ah, bh		; no -- use existing layer prio
checkWinPrio:
		cmp	al, bl		; assume parent win group's win prio
					;  is "higher"
		jbe	setWinPrio	; yes
		mov	al, bl		; no -- use existing win prio
setWinPrio:
		or	al, ah		; merge layer & window prio
		CheckHack <offset WPF_PRIORITY eq 0 and width WPF_PRIORITY eq 8>
		mov	ss:[passFlags].low, al	; and store them away
reload:
		mov	cx, ss:[passFlags]
		mov	di, ss:[parentWin]
		mov	dx, ss:[layerID]
		.leave
		ret
OpenWinModifyWithNearestWinGroupPriority endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetScreenWin

DESCRIPTION:	Returns Screen Window in di

CALLED BY:	INTERNAL
		GetCoreWinOpenParams

PASS:		*ds:si	- OLWinCLass

RETURN:		di	- screen window

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

if BUBBLE_HELP
GetScreenWinFar	proc	far
	call	GetScreenWin
	ret
GetScreenWinFar	endp
endif ; BUBBLE_HELP

GetScreenWin	proc	near	uses ax, bx, cx, dx, bp
	.enter
	push	si
EC <	clr	cx			; assume no window		>
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	bx, segment OLScreenClass
	mov	si, offset OLScreenClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di		; Get handle to ClassedEvent in cx
	pop	si		; Get object
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	GenCallApplication	; returns window in cx
	mov	di, cx
EC <	tst	di							>
EC <	ERROR_Z	OL_CANT_GET_SCREEN_WINDOW_HANDLE			>
	.leave
	ret
GetScreenWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetState

DESCRIPTION:	This procedure checks if there is saved state information
		for this window.

CALLED BY:	OpenWinAttach

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		Make sure any changes here are also made in OLWinIconSpecBuild.
		This is only called for non-OLWinIcon objects.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

	; called from AppAttach

OpenWinGetState	proc	far
	class	OLWinClass
	;This object is specified in the application .UI file as "on the active
	;list", meaning it should open when the application is launched,
	;OR this window was open when the application was shut-down.

	;We now check if any additional data was saved for us.

	mov	ax, TEMP_GEN_SAVE_WINDOW_INFO
	call	ObjVarFindData
	jnc	removeFromList		;skip if no data saved...

;==============================================================================

	;This object has data on the active list: the window must have
	;been moved or resized by the application or user, OR the
	;window had "STAGGERED" behavior, when it was closed.

	;We have to recover its stagger slot #, and query the
	;Field/DisplayControl to see if this slot is available.
	;	ds:bx = data

	push	es, si

	call	WinCommon_DerefVisSpec_DI
	segmov	es, ds			;set es:di = VisSpec instance data

	;get data in ds:si

	mov	si, bx

	;now copy some info straight from the saved data

	mov	ax, ds:[si].GSWI_winPosSizeState
	mov	es:[di].OLWI_winPosSizeState, ax

	;(while we have es:di = specific part, set flags so that SPEC_BUILD
	;knows that we pulled % bounds values from the saved data.
	;It will still check the state flags to see if this data is needed.)
	;We are also indicating that the stagger slot info came from
	;a previous session, and should change if there is a conflict with
	;an object present in this session.
	;DO NOT want to set geometry invalid here. Caller must ensure that
	;UpdateWinPosSize will run soon, to check these (possibly) new flags,
	;update visbounds, and set geometry invalid.

;don't do this as the correct flags are saved in OpenWinSaveState (hopefully
;fixes bug where CGA's outdented (-1, -1) windows are restored correctly when
;saved in iconified form (i.e. pixel bounds CAN be saved to state, bleah)
;-- brianc 4/2/92
;	ORNF	es:[di].OLWI_winPosSizeState, mask WPSS_VIS_POS_IS_SPEC_PAIR \
;			or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT

	;the only data remaining in the chunk is the bounds of this window -
	;saved as a % of the parent window. Grab this info now.

					;ds:si = window Rect structure
					;saved in extra data chunk

.assert (offset VI_bounds eq 0), \
			"ERROR: VI_bounds is not 1st field in VisClass!"
;add this code if necessary:
;	add	di, offset VI_bounds

	mov	cx, size VI_bounds
	cld
	rep	movs es:[di], ds:[si]	;copy from extra data chunk to VI_bounds

	pop	es, si

	mov	ax, TEMP_GEN_SAVE_WINDOW_INFO
	call	ObjVarDeleteData

;==============================================================================
removeFromList:
	;Remove this window from the active list. (Will be added back in
	;when it comes up). Exception: if this window is a GenPrimary which
	;is minimized, KEEP it on the window, so that it will get UPDATE_WINDOW
	;if the system shuts down before the Primary opens.

;WHO commented this code out, and WHY? Please explain yourself! -Eric 10/90.

;one possible reason is that you don't want to remove window list entrys
;defined in .ui/.goc files? - brianc 5/27/92

if	0
	push	es
	mov	di, segment GenDisplayClass
	mov	es, di
	mov	di, offset GenDisplayClass
	call	ObjIsObjectInClass
	pop	es
	jnc	removeFromActive	;can't be minimized
	mov	ax, MSG_GEN_DISPLAY_GET_MINIMIZED
	call	ObjCallInstanceNoLock
	jc	done			;skip if minimized...
removeFromActive:
	call	OLWinTakeOffWindowList	;take ourselves off active list
done:
endif
	ret
OpenWinGetState	endp


WinCommon	ends
WinCommon	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertPixelBoundsToSpecWinSizePairs

DESCRIPTION:	Convert this windowed object's bounds into ratio values.
		This is done before the data is saved.

CALLED BY:	OpenWinSaveState

PASS:		*ds:si - object
		ss:bp - GenSaveWinInfo structure on stack (contains
			Rectangle (copied from VI_bounds) in lowest 4 words)

RETURN:		ax, cx, dx, ds, si, bp = same

DESTROYED:	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial Version

------------------------------------------------------------------------------@


ConvertPixelBoundsToSpecWinSizePairs	proc	far	uses	ax, cx, dx
	class	OLWinClass

	.enter

if ERROR_CHECK	;--------------------------------------------------------------
	;error check: if position is ratio but size is not (or vice-versa),
	;give up.

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_winPosSizeState, mask WPSS_VIS_POS_IS_SPEC_PAIR
	jz	10$

	test	ds:[di].OLWI_winPosSizeState, \
		  mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT or \
		  mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	ERROR_Z OL_ERROR
	jmp	20$

10$:
	test	ds:[di].OLWI_winPosSizeState, \
		  mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT or \
		  mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD
	ERROR_NZ OL_ERROR

20$:
endif		;--------------------------------------------------------------

	;first: if this window's bounds are already expressed as a
	;SpecWinSizePair value, then DO NOT convert to one!

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_winPosSizeState, \
		    (mask WPSS_VIS_POS_IS_SPEC_PAIR \
		  or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT \
		  or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_FIELD)
	jnz	done

	;mark this thing as storing percent coordinates - brianc 4/2/92

	ORNF	ss:[bp].GSWI_winPosSizeState, mask WPSS_VIS_POS_IS_SPEC_PAIR \
			or mask WPSS_VIS_SIZE_IS_SPEC_PAIR_PARENT

	;convert size into ratio of parent window (DO THIS FIRST)
	;(bounds values have been copied into the GenSaveWindowInfo structure,
	;so we have to refer to them using "winPosition" and "winSize"
	;field names, but remember they are still organized as a Rectangle <>.)

	mov	ax, ss:[bp].GSWI_winSize.SWSP_x
	sub	ax, ss:[bp].GSWI_winPosition.SWSP_x
;	inc	ax				;bounds changes! 12/ 8/92 cbh

	mov	bx, ss:[bp].GSWI_winSize.SWSP_y
	sub	bx, ss:[bp].GSWI_winPosition.SWSP_y
;	inc	bx

	clr	cx					;compare to parent win
	call	VisConvertCoordsToRatio ;returns SpecWinSizePair in ax, bx
	mov	ss:[bp].GSWI_winSize.SWSP_x, ax	;save size values
	mov	ss:[bp].GSWI_winSize.SWSP_y, bx

	;convert position into ratio of parent window

	mov	ax, ss:[bp].GSWI_winPosition.SWSP_x
	mov	bx, ss:[bp].GSWI_winPosition.SWSP_y
	;
	; we will bump out the bounds here before saving as a ratio, as
	; when bump them in when we restore (see
	; ConvertSpecWinSizePairsToPixels) - brianc 1/29/93
	;
	inc	ax
	inc	bx

	clr	cx					;compare to parent win
	call	VisConvertCoordsToRatio ;returns SpecWinSizePair in ax, bx
	mov	ss:[bp].GSWI_winPosition.SWSP_x, ax	;save position values
	mov	ss:[bp].GSWI_winPosition.SWSP_y, bx
done:
	.leave
	ret
ConvertPixelBoundsToSpecWinSizePairs	endp

WinCommon ends
WinCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateWindow -- MSG_META_UPDATE_WINDOW for OLWinClass

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - MSG_META_UPDATE_WINDOW
	cx - UpdateWindowFlags
	dl - VisUpdateMode

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/9/92		Initial version

------------------------------------------------------------------------------@

OpenWinUpdateWindow	method dynamic	OLWinClass, MSG_META_UPDATE_WINDOW

	push	ax, cx, dx

	test	cx, mask UWF_ATTACHING
	jz	notAttaching
	call	OpenWinAttaching
	jmp	callSuper		; all done for ATTACH

notAttaching:
	test	cx, mask UWF_DETACHING
	jz	notDetaching
	call	OpenWinDetaching

notDetaching:

callSuper:
	pop	ax, cx, dx

	push	cx
	mov	di,offset OLWinClass
	call	ObjCallSuperNoLock
	pop	cx
;new code to deal with this in GenAppOpenComplete - brianc 3/8/93
;	;
;	; if we were attaching, deal with modal window (allows modal windows
;	; that are saved to state to correctly regain focus when they come
;	; up again) - brianc 1/11/93
;	;
;	test	cx, mask UWF_ATTACHING
;	jz	done
;	call	OpenWinUpdateModalStatus
done:
	ret
OpenWinUpdateWindow	endp

OpenWinAttaching	proc	near

EC <	;Make sure we are actually attaching				>
EC <	mov	ax, MSG_GEN_APPLICATION_GET_STATE			>
EC <	call	UserCallApplication	; ax = ApplicationStates	>
EC <	test	ax, mask AS_ATTACHING					>
EC <	ERROR_Z	OL_ERROR						>

	push	cx			; preserve UpdateWindowFlags
	call	OpenWinGetState		;get saved position and size state data
	pop	cx

	;set flag so that we are not assertive about getting the same
	;staggered slot # (see UpdateWinPos).

	call	WinCommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_RESTARTED

	;If this object is marked as BRANCH_MINIMIZED, then do not set
	;realizable or update - this will be done by
	;OLMenuedWinGenSetNotMinimized later on.

	test	ds:[di].VI_specAttrs, mask SA_BRANCH_MINIMIZED
	jz	checkVisible

EC <	push	es, di							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	es, di							>
EC <	ERROR_NC	OL_ERROR					>

	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	call	ObjCallInstanceNoLock
	jmp	done		;skip to end...

checkVisible:

	; Presume visible if on window list (other than special case for
	; GenInteraction below)
	;
	; NOTE:  A proposed change for V2.0 would have displays & primarys
	; always coming up if USABLE & ATTACHED.  If this were the case,
	; then this bit would already have been set in OLDisplayWinInitialize,
	; so it would not need to be done here.	-- Doug 12/10/91
	;
;done - brianc 3/3/92
;	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

	; See if window should be on screen or not
	;
	push	di, es
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	pop	di, es
					; If not GenInteraction, rely on
					; initialization handlers
					; to set realizability up correctly.
	jnc	afterInteraction

;genInteraction:
	; cx = UpdateWindowFlags

	; Special case for GenInteraction -- if coming up for first time,
	; depends on UWF_FROM_WINDOWS_LIST.  If re-attaching, look at
	; HINT_INITIATED instead.
	;
					;assume not desired on screen
	ANDNF	ds:[di].VI_specAttrs, not mask SA_REALIZABLE

	test	cx, mask UWF_RESTORING_FROM_STATE
	jnz	useState
					;if not, use UWF_FROM_WINDOWS_LIST
	test	cx, mask UWF_FROM_WINDOWS_LIST
	jnz	realizable		;direct update from GAGCNLT_WINDOWS
					;GCN list, make realizable
	jmp	short notRealizable	;else, not realizable

useState:
	mov	ax, HINT_INITIATED	;re-attaching: check state
	call	ObjVarFindData
	jnc	afterInteraction	;skip if not found
					;switch if hint exists
realizable:
	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

if _MENUS_PINNABLE 	;-----------------------------------------------------

	; IF menu - must have been pinned when was closed (see OpenWinCloseWin)
	; mark as OLWSS_NOTIFY_TRIGGERS_IS_PINNED so that during SPEC_BUILD
	; we will tell our triggers to get borders.
	;
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	10$			;skip if not a menu or submenu...
	ORNF	ds:[di].OLWI_specState, mask OLWSS_PINNED \
				     or mask OLWSS_NOTIFY_TRIGGERS_IS_PINNED
10$:
endif			;------------------------------------------------------

notRealizable:

afterInteraction:

;==============================================================================
afterSetVisible:
	ForceRef afterSetVisible

	;NOW, do spec build & visual update
					; Mark display as Attached only.
					; If specific objects want themselves
					; to be visible when the ensuing
					; update happens, they should subclass
					; this method & or in the
					; SA_REALIZABLE bit before calling
					; this superclass method.
					; Note that if any generic parent
					; is MINIMIZED, then the specific UI
					; may set a bit which prevents
					; the children (such as this one)
					; from actually being made visible.

	mov	cl, mask SA_ATTACHED
	clr	ch
					; Do visual update. If attached,
					; usable & visible, it will come up
					; on screen.
	; XXX: use passed update mode?
	mov	dl, VUM_NOW
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock
done:
	ret
OpenWinAttaching	endp


WinCommon	ends
WinCommon	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinBringToTop -- MSG_GEN_BRING_TO_TOP

DESCRIPTION:	This function brings the window to the top of its window
		priority group, & and if using a point & click kbd focus
		model, & the window is capable of being the focus window,
		then sends in a request to the application object to make this
		happen.  If the application is active, the request will be
		obliged, & this window will receive a
		MSG_META_GAINED_FOCUS_EXCL.  If the app isn't active, this
		window will still be remembered, so that it will be given
		kbd focus, if there is a choice when the app is active again.

PASS:		*ds:si 	- instance data

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/29/89		Initial version

------------------------------------------------------------------------------@

;NOTE: OLMenuWinClass handles this method and does not call superclass.

OpenWinBringToTop	method dynamic	OLWinClass, MSG_GEN_BRING_TO_TOP
	;if this window is not opened then abort: the user or application
	;caused the window to close before this method arrived via the queue.

	call	VisQueryWindow
	or	di, di
	jz	setGenState		; Skip if window not opened...

	clr	ax, dx			; Leave LayerID unchanged
	call	WinChangePriority

	; If this is a modal window, notify app object, & sys object if
	; SYS_MODAL, that one of these types of windows has either opened,
	; closed, or changed in priority.
	;
	; First, check to see if really of OLPopupWinClass
	;
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	10$
	call	OpenWinUpdateModalStatus
10$:
	;
	; Handle toolboxes specially, by giving them the focus.
	;
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	setGenState
	;
	; if keyboard-only, ignore OWMFA_NO_DISTURB
	; XXX: might need to do this for OLBF_TOOLBOX (above) also
	;
	call	OpenCheckIfKeyboardOnly
	jc	afterNoDisturbCheck
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_NO_DISTURB
	jnz	setGenState
afterNoDisturbCheck:

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

if FIND_HIGHER_LAYER_PRIORITY
	;
	; check if we should grab focus
	;
	call	CheckFocusGrab
	jnc	setGenState		; don't grab focus
endif

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

setGenState:
					; Raise the window list entry to
					; the top, to reflect new/desired
					; position in window hierarchy.
					; (If no window list entry, window
					; isn't up & nothing will be done)
	mov	ax, MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GenCallApplication
	ret
OpenWinBringToTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFocusGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this OLWin should grab focus

CALLED BY:	INTERNAL
			OpenWinBringToTop
PASS:		*ds:si = OLWin
RETURN:		carry set to grab focus
		carry clear to not grab focus
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Must be top-most system modal window or top-most
		app modal window if no system modal window to grab
		focus.

		If not top-most system modal window and top-most system
		modal window is owned by different geode, must grab focus
		within our field.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FIND_HIGHER_LAYER_PRIORITY

CheckFocusGrab	proc	near
	;
	; if there's a system modal win, we need to be the topmost one to
	; grab focus
	;
	mov	cx, GUQT_SCREEN
	mov	ax, MSG_SPEC_GUP_QUERY
	call	UserCallApplication	; bp = screen window
	mov	di, bp			; di = screen window
	clr	ax, bx			; any owner, any LayerID,
					; anything above standard priority,
					;	no focus/target restrictions
	mov	cx, (LAYER_PRIO_STD-1) shl offset WPD_LAYER
	call	FindHigherLayerPriorityWinOnWin
					; bp = top screen window, if any
	mov	dx, di			; dx = screen window
	call	VisQueryWindow		; di = our window
	cmp	di, bp
	LONG je	grabIt			; we are top screen win, grab focus
	tst	bp
	jz	checkModal		; no screen win, check modal
	;
	; Have topmost screen window.  If we are sys-modal, check if in same
	; app as topmost screen window.  If not, grab focus within our field's
	; window hierarchy.  Else, no need to grab focus as closing the topmost
	; screen window will restore focus to us automatically via the app's
	; modal window mechanism.
	;	*ds:si = our OLWin object
	;	di = our window
	;	bp = topmost screen window
	;
	mov	dx, di			; dx = our window
	push	es
	mov	di, segment OLPopupWinClass
	mov	es, di
	mov	di, offset OLPopupWinClass
	call	ObjIsObjectInClass
	pop	es
	jnc	dontGrab		; not sys-modal, don't grab focus
	call	WinCommon_DerefVisSpec_DI
;	test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
; We want to check owners if we are either sys-modal *or* app-modal.  If
; someone else has a sys-modal up, and we put up an app-modal, we need to
; grab within our app's focus heirarchy. -- brianc 3/8/96
;
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL
	jz	dontGrab		; not sys-modal, don't grab focus
	;
	; sys-modal window, check if same owner as topmost screen window
	;	dx = our window
	;	bp = topmost screen window
	;	*ds:si = our OLWin object
	;
	mov	di, dx			; di = our window
	push	si			; save OLWin object
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo		; ^lcx:dx = our win input obj
EC <	ERROR_C	OL_ERROR						>
	mov	bx, cx			; bx = handle
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo		; ax = our input obj owner
	mov	di, bp			; di = topmost screen win
	mov	bp, ax			; bp = our input obj owner
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo		; ^lcx:dx = topmost win input obj
EC <	ERROR_C	OL_ERROR						>
	pop	si			; *ds:si = OLWin object
	mov	bx, cx			; bx = handle
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo		; ax = topmost input obj owner
	cmp	bp, ax			; same owner?
	jne	grabIt			; nope, grab focus within field
dontGrab:
	clc				; signal don't grab focus
	jmp	short done

checkModal:
	;
	; else if there's any modal win, we need to be the topmost one to
	; grab focus
	;
	mov	ax, MSG_VIS_QUERY_WINDOW
	call	UserCallApplication	; cx = app window
	mov	di, cx			; di = app window
	mov	bx, ds:[LMBH_handle]
	call	MemOwner		; current geode
	clr	ax			; any LayerID
					; anything above standard priority,
					;	no focus/target restrictions
	mov	cx, (LAYER_PRIO_STD-1) shl offset WPD_LAYER
	call	FindHigherLayerPriorityWinOnWin
					; bp = top app win, if any
	call	VisQueryWindow		; di = our window
	cmp	di, bp
	je	grabIt			; we are top app win, grab focus
	tst	bp
	jnz	dontGrab		; have other app win, don't grab focus
					; else, grab focus
grabIt:
	stc				; signal grab focus
done:
	.leave
	ret
CheckFocusGrab	endp

endif	; FIND_HIGHER_LAYER_PRIORITY

WinCommon	ends
WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN for OLWinClass

DESCRIPTION:	Intercepts the method which does final positioning & resizing
		of a window, in order to handle final positioning requests,
		amd to make sure that the window is not lost off-screen,
		or even too close to the edge of the screen.

PASS:		*ds:si 	- instance data
		es     	- segment of OLWinClass

		ax 	- MSG_VIS_MOVE_RESIZE_WIN

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/30/89		Initial version
	Doug	11/13/89	Changed to subclass off of MoveResizeWin
				instead of VisSetPosition.
	Eric	11/20/89	adapted to new window positioning/sizing
				scheme.
	JimG	4/94		Added code for Stylus' rounded windows.

------------------------------------------------------------------------------@

WIN_VISIBLE_MARGIN	equ	10	;arbitrary

OpenWinMoveResizeWin	method dynamic	OLWinClass, MSG_VIS_MOVE_RESIZE_WIN

	;first check for general window positioning preferences
	;(most can be handled at SPEC_BUILD, but some have to be handled here,
	;because now we have size information.)

	;if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(Note: if parent geometry is not yet valid, this does nothing)

	call	ConvertSpecWinSizePairsToPixels
	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until MSG_VIS_MOVE_RESIZE_WIN to
					;do this.

	;check for window visibility preferences

	call	OpenWinCheckVisibleConstraints

	; Do the move/resize.

	; If either shadows or round thick dialogs is selected, then
	; check to see if the window has the special shape, and call WinResize
	; directly with the special region that defines the window.

	; If either of these options is selected, but the window does
	; not have the special shape, then WinResize is called to
	; resize a rectangular shape.

	; If these options aren't selected, then call the superclass
	; to do the move/resize.

if DIALOGS_WITH_FOLDER_TABS or BUBBLE_DIALOGS
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	mov	di, ds:[bp].VCI_window	; di <= window handle
	tst	di
	jz	afterMoveResize		; if no window, done

if DIALOGS_WITH_FOLDER_TABS
	call	OpenWinCreateTabbedWindowRegion	; ^hbx = region, dx:ax = addr
else ; BUBBLE_DIALOGS
	call	OpenWinCreateWindowRegion	; ^hbx = region
endif
	tst	bx
	jz	notTabbed

	push	si
if DIALOGS_WITH_FOLDER_TABS
	movdw	bpsi, dxax			; bp:si = tab region
else ; BUBBLE_DIALOGS
	call	MemLock
	mov	bp, ax
	mov	si, size Rectangle		; bp:si = bubble region
endif
doResize::
	;
	;  OK.  It doesn't matter how we got here.  We should have bp:si
	;  pointing to the region to use, with ax,bx,cx,dx as the params.
	;
	mov	ax, mask WPF_ABS	; resize absolute (i.e. move)
	push	ax
	call	WinResize

	;
	;  Clean up after ourselves.
	;
	call	MemFree
	pop	si				; *ds:si = base win

	jmp	afterMoveResize
notTabbed:
endif	;DIALOGS_WITH_FOLDER_TABS or BUBBLE_DIALOGS

if	DRAW_SHADOWS_ON_BW_GADGETS or _ROUND_THICK_DIALOGS
	push	si
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset	; ds:bp = VisInstance
	mov	di, ds:[bp].VCI_window	; di <= window handle
	tst	di
	pop	si			; restore stack for error handling
	jz	afterMoveResize		; if no window, done
	push	si			; save it again

	; ds:si must still point to object for VisGetBounds
	clr	cl			; normal bounds
	call	VisGetBounds
	dec	cx			; use screen pixel bounds
	dec	dx

if _ROUND_THICK_DIALOGS
	; ds:si must still point to object for this procedure
	call	OpenWinShouldHaveRoundBorder
endif ;_ROUND_THICK_DIALOGS

	mov	si, mask WPF_ABS	; resize absolute (i.e. move)
	push	si			; must be top item on stack!
					; removed by WinResize

if _ROUND_THICK_DIALOGS
	jnc	rectWindow		; not a round window!
endif ;_ROUND_THICK_DIALOGS

	; ds:bp still is VisInstance
if DRAW_SHADOWS_ON_BW_GADGETS
	test	ds:[bp].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	rectWindow		;custom window, branch

	call	OpenCheckIfBW
	jnc	rectWindow
endif ;DRAW_SHADOWS_ON_BW_GADGETS

NOFXIP<	mov	bp, cs						>
FXIP <	push	bx, ax						>
FXIP <	mov	bx, handle RegionResourceXIP			>
FXIP <	call	MemLock						>
FXIP <	mov	bp, ax						>
FXIP <	pop	bx, ax						>

	mov	si, offset windowRegionBW

NOFXIP < jmp	short resizeEm					>
FXIP <	jmp	short resizeEm2					>

rectWindow:
	clrdw	bpsi			; rectangular region
resizeEm::
	call	WinResize	; Pops one word off stack
	pop	si
FXIP <	jmp	fin						>
resizeEm2:
FXIP <	call	WinResize					>
FXIP <	push	bx						>
FXIP <	mov	bx, handle RegionResourceXIP			>
FXIP <	call	MemUnlock					>
FXIP <	pop	bx						>
FXIP <	pop	si						>
fin::
else
	mov	ax, MSG_VIS_MOVE_RESIZE_WIN
	call	WinCommon_ObjCallSuperNoLock_OLWinClass_Far
endif	;DRAW_SHADOWS_ON_BW_GADGETS or _ROUND_THICK_DIALOGS

afterMoveResize::

if PLACE_EXPRESS_MENU_ON_PRIMARY
	;
	; Then, update the express tool area location, to match new window
	; location & size.
	; RUNTIME
	;
	call	WinCommon_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
	jne	afterExpressToolArea
	call	OLBaseWinUpdateExpressToolArea
afterExpressToolArea:
endif ; PLACE_EXPRESS_MENU_ON_PRIMARY

	ret
OpenWinMoveResizeWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinTitleButtonRoundedCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if a given title button should have a round corner
		in this particular window.  Assumes that the button is
		in the title bar.

CALLED BY:	MSG_OL_WIN_SHOULD_TITLE_BUTTON_HAVE_ROUNDED_CORNER
PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		ds:bx	= OLWinClass object (same as *ds:si)
		es 	= segment of OLWinClass
		ax	= message #
		cx	= button left position
		dx	= button right position

RETURN:		carry 	- set if button should have a round corner
		ax	- if carry is set:
			    true if top-left corner should be round, false
			    if top-right corner should be round
			  if carry is clear:
			    destroyed

DESTROYED:	ax (if carry is clear), cx, dx, bp

SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
	Assumes B&W - Stylus UI.
	Uses the window edge (+ thick border) to determine if this
	button is on the left or right edge.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _ROUND_THICK_DIALOGS
OpenWinTitleButtonRoundedCorner	method dynamic OLWinClass,
			    MSG_OL_WIN_SHOULD_TITLE_BUTTON_HAVE_ROUNDED_CORNER
	.enter

	; Check if window has a round border first of all.
	call	OpenWinShouldHaveRoundBorder
	jnc	done				; carry clear

	; OK - window has round border.
	push	cx, dx

	; assume ds:di is still instance ptr
	mov	bp, di				; ds:bp = ptr to instance data

	; Get inside border (the titleBarBounds include the sys icons,
	; but here we need the real boundaries of the window to check
	; if this button is on the edge).
	call	OpenWinGetHeaderBounds
	add	ax, _ROUND_THICK_DIALOG_BORDER
	sub	cx, _ROUND_THICK_DIALOG_BORDER
	mov	dx, ax

	pop	ax, bx

	; ax = button left pos, bx = button right pos
	; dx = left inside edge of window border
	; cx = right inside edge of window border

	cmp	ax, dx
	jne	notLeftEdge
	mov	ax, TRUE			; left corner!
	jmp	hasRoundCorner

notLeftEdge:
	cmp	bx, cx
	clc
	jne	done				; ignores C flag

	mov	ax, FALSE			; right corner!

hasRoundCorner:
	stc

done:
	.leave
	ret
OpenWinTitleButtonRoundedCorner	endm
endif	;_ROUND_THICK_DIALOGS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinShouldHaveRoundBorderFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks appropriate instance data flags and returns if
		this window should have round thick windows.
		(Basically just calls OpenWinShouldHaveRoundBorder.)

CALLED BY:	Various internal functions.

PASS:		*ds:si - object

RETURN:		carry - set if should have round thick windows.

DESTROYED:	nothing
SIDE EFFECTS:	none.

PSEUDO CODE/STRATEGY:
	Window must be a popup, not a menu, not have a custom window,
	and must not be resizable.  ASSUME B&W - Stylus UI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _ROUND_THICK_DIALOGS
OpenWinShouldHaveRoundBorderFar	proc	far
	call	OpenWinShouldHaveRoundBorder
	ret
OpenWinShouldHaveRoundBorderFar	endp
endif	;_ROUND_THICK_DIALOGS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinShouldHaveRoundBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks appropriate instance data flags and returns if
		this window should have round thick windows.

CALLED BY:	Various internal functions.

PASS:		*ds:si - object

RETURN:		carry - set if should have round thick windows.

DESTROYED:	nothing
SIDE EFFECTS:	none.

PSEUDO CODE/STRATEGY:
	Window must be a popup, not a menu, not have a custom window,
	and must not be resizable.  ASSUME B&W - Stylus UI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _ROUND_THICK_DIALOGS
OpenWinShouldHaveRoundBorder	proc	near
	uses	di
	.enter
	call	WinCommon_DerefVisSpec_DI

	; NOTE: test clears carry flag.

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	done				; Is a menu, skip this

	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jnz	done				; Is resizable, skip this

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	done				; Has custom window, skip this

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	checkForNonMaxPrimary		; Not a popup, skip this

setDone:
	stc					; Should be round.. set carry

done:
	.leave
	ret					; << RETURN

	; We know that this is NOT a menu, NOT resizable, and does NOT have
	; a custom window.  But it is also NOT a popup.  So check to see if
	; this is a primary, and if it is not maximizable.  If so, this is
	; like a desk accessory and should have a round border.
checkForNonMaxPrimary:
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	jne	done				; Not a primary.. done

	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jnz	done				; Maximizable.. done

	; Fits requirements.. set the carry and exit
	jmp	short setDone

OpenWinShouldHaveRoundBorder	endp
endif	;_ROUND_THICK_DIALOGS


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinCheckVisibleConstraints

DESCRIPTION:	This procedure ensure's that a window's visiblility
		constraints are met as it is opened or moved on the screen.

CALLED BY:	OpenWinOpenWin, OpenWinMoveResizeWin

PASS:		*ds:si -- window

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

	.assert	(offset WPSF_CONSTRAIN_TYPE) lt 8
	.assert (WCT_NONE eq 0)

OpenWinCheckVisibleConstraints	proc	far
	class	OLWinClass

	call	WinCommon_DerefVisSpec_DI
	mov	cl, byte ptr ds:[di].OLWI_winPosSizeFlags ;get LOW byte
	and	cl, mask WPSF_CONSTRAIN_TYPE
	jz	done			 ;skip if WCT_NONE....

	cmp	cl, (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE)
	jne	checkOther		;skip if not...

	;want to keep window partially visible. This means different things
	;depending on the specific UI:

	mov	cx, WIN_VISIBLE_MARGIN	;default margins for most UIs
	mov	dx, WIN_VISIBLE_MARGIN

	;Motif/CUA: if window has a title bar, make sure it stays visible

CUAS <	test	ds:[di].OLWI_attrs, mask OWA_TITLED			>
CUAS <	jz	keepThisMarginVisible					>
CUAS <	call	EnsureTitleBarInParentWin				>
CUAS <	jmp	done							>

checkOther:
	;must be WCT_KEEP_VISIBLE or WCT_KEEP_VISIBLE_WITH_MARGIN

	cmp	cl, (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE)
	pushf
	call	VisGetSize		;get size of this window (cx, dx)
	popf
	je	short keepThisMarginVisible

	add	cx, WIN_VISIBLE_MARGIN
	add	dx, WIN_VISIBLE_MARGIN

keepThisMarginVisible:
	call	EnsureWindowInParentWin

testForMenuCase:
	;if this window is a system menu (Control or Express menu), and it
	;is close enough to the bottom of the screen that it has been pushed
	;upwards to cover up the menu button, then push it upwards some more,
	;until it is completely over the menu button. This allows double-
	;clicking to continue to work.

	call	OpenWinCheckMenuWinVisibilityConstraints

done:
	ret
OpenWinCheckVisibleConstraints	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinCheckMenuWinVisibilityConstraints

DESCRIPTION:	This procedure is called after we have adjusted a menu window
		so that it is on-screen. If the menu is now obscuring the
		menu button which opens it, we will push the menu above
		the menu button.

CALLED BY:	OpenWinCheckVisibleConstraints

PASS:		*ds:si	= menu window

RETURN:		ds, si	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	1/20/93		Rewritten to work for all horizontal and
				vertical menus.


------------------------------------------------------------------------------@
OpenWinCheckMenuWinVisibilityConstraints	proc	near
	uses si, di
	.enter

	clr	cx				;default bounds check in X
	dec	ch				;default as submenu

	mov	ax, TEMP_POPUP_OPENING_TO_RIGHT	;keep whether opening to right
	call	ObjVarFindData			;  if so, go deal with it.
	jc	doit

	clr	ch				;not opening to right
	call	WinCommon_DerefVisSpec_DI
	mov	cl, ds:[di].VCI_geoAttrs	;use orientation for check

	cmp     ds:[di].OLWI_type, MOWT_SYSTEM_MENU	;menus are always a
	je      doit					;  vertical check
	cmp     ds:[di].OLWI_type, MOWT_MENU		;other types of
	jne     exit					;  windows, exit
doit:
	;let's make sure this is a menu before we go screwing with instance data

EC <	push	di							>
EC <	mov	bx, segment OLMenuWinClass				>
EC <	mov	es, bx							>
EC <	mov	di, offset OLMenuWinClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		;die if not correct class	>
EC <	pop	di							>

	;now, dip into the OLPopupWin instance data for this object,
	;and grab the handle of the menu button
	;	*ds:si= menu window instance data
	;	ds:di = menu window VisSpec instance data

	call	WinCommon_DerefVisSpec_DI

	.warn	-private
	mov	di, ds:[di].OLPWI_button ;set *ds:di = menu button
	.warn	@private

	tst	di			;is there a button?
	jz	exit			;skip if not...

	xchg	di, si			;menu in *ds:di, button in *ds:si

	;
	; Another hack for ISUI: if the menu is not pressed, then don't worry
	; about overlapping the button.
	;
ISU <	push	di							>
ISU <	call	WinCommon_DerefVisSpec_DI				>
ISU <	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED		>
ISU <	pop	di							>
ISU <	jz	exit							>

	;since we know the button is in the same ObjectBlock, and we've
	;already violated OOP rules, let's go look at its instance data

EC <	push	di							>
EC <	mov	bx, segment OLMenuButtonClass				>
EC <	mov	es, bx							>
EC <	mov	di, offset OLMenuButtonClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		;die if not correct class	>
EC <	pop	di							>

	;
	; cl holds orientation as direction to check, ch non-zero if window is
	; opening to the right.
	;
	clr	bx			;assume not vertical
	test	cl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	10$			;good assumption, go celebrate
	mov	bl, AMO_VERTICAL	;else set this baby
10$:
	clr	cl			;cx now non-zero if submenu.
	call	AvoidMenuOverlap	;check the overlap situation
	jnc	exit			;nothing strange happened, done

	call	TryAgainInOtherDirection	;try again
	jnc	exit				;OK, done
						;still here?  Then:
	clr	ch				;give up on submenu limitations
	call	TryAgainInOtherDirection	;and try one last time.
	jnc	exit

	call	KeepMenuOnscreen		;total failure, at least keep
						;  onscreen.
exit:
	.leave
	ret
OpenWinCheckMenuWinVisibilityConstraints	endp


TryAgainInOtherDirection	proc	near
	;
	; Menu was moved from under the button to the right, or vice versa.
	; Force it back onscreen and make another pass to avoid menu overlap.
	;
	call	KeepMenuOnscreen

	xor	bl, AMO_VERTICAL	;else we've switched directions
	call	AvoidMenuOverlap	;make sure things work in the other dir
	ret
TryAgainInOtherDirection	endp

KeepMenuOnscreen	proc	near
	xchg	si, di			;*ds:si -- menu
	push	bx, di, cx
EC <	call	ECCheckLMemObject					>
	call	OpenGetParentWinSize

if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	hasNoTaskbar				; skip if no taskbar

	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.
	call	GetTaskBarSizeAdjustment
	sub	dx, di			; subtract off taskbar adjustment

hasNoTaskbar:
endif
	movdw	axbp, cxdx		;put size values in weird places
	call	MoveWindowToKeepOnscreen
	pop	bx, di, cx
	xchg	si, di
	ret
KeepMenuOnscreen	endp


WinCommon	ends
WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGetHeaderTitleBounds --
		MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS for OLWinClass

DESCRIPTION:	Returns widths of icons left and right of title bar.

PASS:		*ds:si 	- instance data
		ds:di	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS

RETURN:		ax 	- width of icons left of title
		bp	- width of icons right of title
		cx, dx	- preserved

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 7/92		Initial Version

------------------------------------------------------------------------------@

OLWinGetHeaderTitleBounds	method dynamic	OLWinClass, \
				MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
	uses	cx, dx
	.enter
if _ISUI
	mov	cx, 0				;in case no sys menu button
	call	CheckSysMenuButton
	jnc	5$
endif
	call	OpenWinGetSysMenuButtonWidth	;cx = width
	call	OpenCheckIfCGA
	jnc	5$				;CHECK BW FOR CUA LOOK
	dec	cx				;needed for correct menu bar
5$:						; position now (cbh 2/15/92)
	mov	ax, cx				;ax = left icon width
						; (system menu icon only,
						;  OLBaseWin adds in express
						;  menu)
						; (no overlap btwn icon and
						;  title bar, OLBaseWin handles
						;  overlap if there is express
						;  menu)
	;
	; account for title bar left group
	;
	mov	bp, offset OLWI_titleBarLeftGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	dec	cx				; (overlap)
	add	ax, cx

;haveLeftWidth:

	clr	bp				; Start with no buttons on right

	call	OpenCheckIfKeyboardOnly		; Check for no keyboard
	jc	haveRightWidth			; if no keyboard, no gadgets to
						; right.

	; Add in width of minimize & maximize/restore buttons, if present.
	;
	call	OpenWinCheckIfMinMaxRestoreControls
	jnc	afterAdjustments
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	afterMinimizable
	add	bp, CUAS_WIN_ICON_WIDTH-1
afterMinimizable:
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	maximized
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	afterMaxRestore
haveMaxOrRestoreIcon:
	add	bp, CUAS_WIN_ICON_WIDTH-1
	jmp	short afterMaxRestore
maximized:
	test	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE
	jnz	haveMaxOrRestoreIcon
afterMaxRestore:
afterAdjustments:

	; Make minor spacing adjustment for color
	;
	call	OpenCheckIfBW
	jc	15$				;skip if B/W..
	tst	bp				; don't dec below zero
	jz	15$
	dec	bp				; Else make adjustment to right
15$:						;   icon width, who knows why

haveRightWidth:

	;
	; account for title bar right group
	;
	push	bp				; save current right width
	mov	bp, offset OLWI_titleBarRightGroup
	call	OpenWinGetTitleBarGroupSize	; cx = width, dx = height
	dec	cx				; overlap
	pop	bp				; restore current right width
	add	bp, cx

	.leave
	ret
OLWinGetHeaderTitleBounds	endm

WinCommon	ends
WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGetTitleBarHeight --
		MSG_OL_WIN_GET_TITLE_BAR_HEIGHT for OLWinClass

DESCRIPTION:	Returns height of title bar

PASS:		*ds:si 	- instance data
		ds:di	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_GET_TITLE_BAR_HEIGHT

RETURN:		dx 	- height to title bar

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/92		Initial Version

------------------------------------------------------------------------------@

OLWinGetTitleBarHeight	method dynamic	OLWinClass, \
				MSG_OL_WIN_GET_TITLE_BAR_HEIGHT
	mov	bp, di				; ds:bp - instance data
	call	OpenWinGetHeaderBounds		; (ax, bx, cx, dx) = bounds
	sub	dx, bx				; dx = height
if _ISUI
	call	OpenCheckIfBW			; that's all for BW
	jc	done
	sub	dx, 4				; margins = 2 above / 2 below
else
	call	OpenCheckIfBW			; that's all for BW
	jc	done
	dec	dx				; small adjustment for color
	dec	dx
endif
done:
	ret
OLWinGetTitleBarHeight	endm

OpenWinGetHeaderBoundsFar	proc	far
	call	OpenWinGetHeaderBounds
	ret
OpenWinGetHeaderBoundsFar	endp

WinCommon	ends
WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinDrawMoniker

SYNOPSIS:	Draws complete moniker, including long term moniker, unless
		we're running in GCM mode.

CALLED BY:	OpenWinDrawHeaderTitle

PASS:
	*ds:si - instance data
	cl - how to draw moniker: DrawMonikerFlags
	ss:bp  - DrawMonikerArgs

RETURN:
	bp - preserved
	ax, bx - position the moniker was drawn at

DESTROYED:
	cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/90		Initial version

------------------------------------------------------------------------------@

OpenWinDrawMoniker	proc	near
	class	OLWinClass
	segmov	es, ds
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >

	;
	; check if we're a base window
	;
	call	WinCommon_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW		>
OLS  <  cmp	ds:[di].OLWI_type, OLWT_BASE_WINDOW		>
	jne	normalDraw			; is not base window, do normal
						;	stuff
	;
	; check if this base window has a long term moniker, if so
	; if both normal and long term monikers don't fit, just draw long
	; term moniker
	;
if _ISUI
	call	WinCommon_DerefGen_DI
	.warn -private
	mov	di, ds:[di].GPI_longTermMoniker
	.warn @private
	tst	di
	jz	noLongTerm
	push	ax, bx
	mov	ax, HINT_SHOW_ENTIRE_MONIKER
	call	ObjVarFindData			; C set if found
	pop	ax, bx
	jc	noLongTerm
	push	ax, cx, dx, es
	push	bp
	mov	bp, ss:[bp].DMA_gState
if _ISUI
	call	getWinMonikerSize		; cx <- width
else
	call	SpecGetGenMonikerSize		; cx = width
endif
	push	cx
	segmov	es, ds				; *es:di = long term moniker
	clr	ax				; use font height from gstate
	call	VisGetMonikerSize		; cx = width of long term mkr
	pop	ax				; ax = moniker width
	add	ax, cx				; ax = total moniker width
	mov	di, bp				; di = gstate
	call	GetDividerStrLen		; dx = divider len
	add	ax, dx				; ax = complete len
	pop	bp
	cmp	ax, ss:[bp].DMA_xMaximum
	pop	ax, cx, dx, es
	ja	drawLongTerm			; too long, just draw long term
noLongTerm:
endif
	;
	; check if we are on a tiny width screen
	;
	push	cx, dx
	call	OpenGetScreenDimensions		; cx, dx = dimensions
	cmp	cx, TINY_SCREEN_WIDTH_THRESHOLD
	pop	cx, dx
	ja	normalDraw			; not tiny screen, do normal
						;	stuff
	;
	; on horizontally tiny screens, just draw long term moniker, if any
	;
drawLongTerm::
	call	WinCommon_DerefGen_DI
	.warn	-private
	mov	bx, ds:[di].GPI_longTermMoniker	; *es:bx = long-term moniker
	.warn	@private
	tst	bx
	jz	normalDraw			; no long-term, do normal stuff
if _ISUI
	call	drawMoniker
else
	call	SpecDrawMoniker			; else, just draw it
endif
	jmp	exit

normalDraw:
	push	cx, bp
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset		; ds:bx = GenInstance
	mov	bx, ds:[bx].GI_visMoniker	;*ds:bx = visMoniker
if _ISUI
	call	drawMoniker
else
	call	SpecDrawMoniker			;draw the VisMoniker, position in ax,bx
endif
	pop	cx, bp

	;
	; Exit if we're not a base window.
	;
	call	WinCommon_DerefVisSpec_DI
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW		>
OLS  <  cmp	ds:[di].OLWI_type, OLWT_BASE_WINDOW		>
     	jne	exit				;not a primary, we're done

if _GCM
	;
	; Exit if using GCM headers
	;
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	exit
endif
	;
	; Else move past the drawn vis moniker and draw the long term moniker.
	;
	push	cx			;save moniker flags
	push	bp			;save struct pointer
	push	ax
	mov	bp, ss:[bp].DMA_gState	;get gstate in bp
if _ISUI
	call	getWinMonikerSize	;cx <- moniker width
else
	call	SpecGetGenMonikerSize	;get moniker width in cx
endif
	pop	ax
	pop	bp			;restore struct pointer
	add	ax, cx			;add width to left edge
	call	WinCommon_DerefGen_DI

	.warn	-private

	mov	di, ds:[di].GPI_longTermMoniker

	.warn	@private

	tst	di			;is there a long term moniker?
	jz	drawLongTermMoniker	;no, let's "draw" a blank moniker
					;   (makes code simpler)

	mov	dx, 0			;in case no moniker
	push	di
	call	WinCommon_DerefGen_DI
	tst	ds:[di].GI_visMoniker
	pop	di
	jz	drawLongTermMoniker	;no moniker, skip divider

	push	di			;else save ptr to the long term moniker
	mov	di, ss:[bp].DMA_gState	;gstate in di
	call	GetDividerStrLen	;length of divider in dx
	add	dx, cx			;add length of gen moniker
	cmp	ss:[bp].DMA_xMaximum, dx   ;any room left for the divider?
	jb	afterDivider		;no, skip it

	;
	; Draw the separator between the gen and long-term monikers.
	;
	push	ds, si
	clr	cx			;draw all characters
SBCS <	segmov	ds, cs			;ds:si points to middle string	>
SBCS <	mov	si, offset longTermStr					>
DBCS <	segmov	ds, <segment resLongTermStr>, si			>
DBCS <	mov	si, offset resLongTermStr				>
FXIP <	call	SysCopyToStackDSSI					>
	call	GrDrawText
FXIP <	call	SysRemoveFromStack					>
	DoPop	si, ds

afterDivider:
	pop	di			;restore pointer to long term moniker

drawLongTermMoniker:
	mov	bx, di			;pass long term moniker in es:bx
	pop	cx			;pop draw moniker flags
	add	ss:[bp].DMA_xInset, dx	;add gen and div size to our x inset
	sub	ss:[bp].DMA_xMaximum, dx  ;subtract from size to clip
	js	exit			;no room left, exit
	segmov	es, ds			;have es:bx point to our long term mkr
if _ISUI
	call	drawMoniker
else
	call	SpecDrawMoniker		;draw the moniker
endif
exit:
	ret

if _ISUI
	;
	; this is kinda gross, but I can't figure out any way
	; to get the moniker code to use bold just for the title bar
	; when calculating the width.
	;

getWinMonikerSize:
	push	ax, dx, di
	push	si
	mov	di, bp			;di <- GState
	mov	ax, mask TS_BOLD	;al <- set bold
	call	GrSetTextStyle
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GI_visMoniker
	mov	si, ds:[si]		;ds:si <- VisMoniker
	test	ds:[si].VM_type, mask VMT_GSTRING
	jnz	notText
	add	si, offset VM_data.VMT_text	;ds:si <- moniker text
	call	GrTextWidth
	mov	cx, dx				;cx <- width
	mov	ax, (mask TS_BOLD) shl 8	;ah <- reset bold
	call	GrSetTextStyle
	pop	si
gotSize:
	pop	ax, dx, di
	retn

notText:
	pop	si
	call	SpecGetGenMonikerSize	;get moniker width in cx
	jmp	gotSize

drawMoniker:
	push	ax, di
	mov	ax, mask TS_BOLD			;al <- set bold
	mov	di, ss:[bp].DMA_gState
	call	GrSetTextStyle
	pop	ax, di
	call	SpecDrawMoniker
	push	ax
	mov	ax, (mask TS_BOLD) shl 8		;ah <- reset bold
	mov	di, ss:[bp].DMA_gState
	call	GrSetTextStyle
	pop	ax
	retn
endif

OpenWinDrawMoniker	endp

SBCS <longTermStr	db	" - ",0					>

WinCommon	ends
