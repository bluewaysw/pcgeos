COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific UIs)
FILE:		cwinGeometry.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_VIS_RECALC_SIZE     Recalc's size.

    MTD MSG_VIS_POSITION_BRANCH Positions the object.

    INT WinPassMarginInfo       Passes margin info for OpenRecalcCtrlSize.

    INT ReturnAxBpCxDx          Returns margins a certain way.

    MTD MSG_VIS_COMP_GET_MINIMUM_SIZE
				Returns the minimum size for a window.
				IMPORTANT: OLBaseWinClass subclasses this
				method to add spacing for the Workspace and
				Application icons

    MTD MSG_VIS_UPDATE_GEOMETRY Updates the geometry for the window.  If
				first time being arranged geometrically,
				then attemps to keep the thing on-screen,
				first by resizing it, then by moving it.

    INT OpenWinRefitToParent    Updates the geometry for the window.  If
				first time being arranged geometrically,
				then attemps to keep the thing on-screen,
				first by resizing it, then by moving it.

    INT CenterIfNotice          Updates the geometry for the window.  If
				first time being arranged geometrically,
				then attemps to keep the thing on-screen,
				first by resizing it, then by moving it.

    MTD MSG_OL_GET_CHILDS_TREE_POS
				Returns true if object passed is child of
				non-menu window. Also returns whether the
				child is the first child of the window
				either generically or visually (depending
				on what is passed).  This
				generic-or-specific stuff is extremely
				dubious.

    INT OpenWinCalcMinWidth     Calculate the minimum size for an OpenLook
				window.

    INT OpenWinCalcMinWidth     Calculate the minimum size for an OpenLook
				window.

    MTD MSG_VIS_RESET_TO_INITIAL_SIZE
				Resets a window to its initial size.  For
				most windows, we'll zap the size back to
				RS_CHOOSE_OWN_SIZE so the window will
				choose a completely new size again, unless
				its maximized, in which case we'll leave
				the window size alone.

    MTD MSG_OL_WIN_RECALC_DISPLAY_SIZE
				Returns size of window, after making sure
				geometry's up-to-date.

    INT OpenWinGetMonikerSize   Gets moniker size for a window.  If this is
				a GenPrimary, returns the sum of the
				visMoniker and the longTermMoniker. Ignores
				the long term moniker if we're in GCM mode.

    INT GetDividerStrLen        Gets the length of the divider before the
				long term moniker.

    INT MoveWindowToKeepOnscreen
				Moves window bounds to try to keep it
				onscreen.

    INT OpenWinCheckIfSquished  Checks to see if we're on a CGA only.

    INT OpenWinHasResizeBorder  Returns whether this thing has a resize
				border or not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version

DESCRIPTION:

	$Id: cwinGeometry.asm,v 1.7 98/07/13 10:20:31 joon Exp $

------------------------------------------------------------------------------@

Geometry segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc's size.

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		cx, dx  = size suggestions

RETURN:		cx, dx = size to use
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 1/92		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinRecalcSize	method dynamic OLWinClass, MSG_VIS_RECALC_SIZE

	call	WinPassMarginInfo
	call	OpenRecalcCtrlSize

	ret
OLWinRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinVisPositionBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Positions the object.

CALLED BY:	MSG_VIS_POSITION_BRANCH

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		cx, dx	= position

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 1/92		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinVisPositionBranch	method dynamic OLWinClass, MSG_VIS_POSITION_BRANCH

	call	WinPassMarginInfo
	call	VisCompPosition
	ret
OLWinVisPositionBranch	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	WinPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLWinRecalcSize, OLWinPositionBranch

PASS:		*ds:si -- Win bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

WinPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OpenWinGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OpenWinGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo

	.leave
	ret
WinPassMarginInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetSpacing

DESCRIPTION:	Perform MSG_VIS_COMP_GET_CHILD_SPACING given an OLWinPart

CALLED BY:	INTERNAL

PASS:		ds:*si - instance data

RETURN:		cx	- spacing between children
		dx	- spacing between lines of wrapped children

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	7/89		Motif extensions

------------------------------------------------------------------------------@

if	_CUA_STYLE		;START of MOTIF/CUA specific code ----

OpenWinGetSpacing	method OLWinClass, MSG_VIS_COMP_GET_CHILD_SPACING
					; bp = pointSize

	;top and bottom of other window types.

MO <	mov	cx, MO_BASE_WIN_CHILD_SPACING
MO <	mov	dx, MO_WIN_CHILD_WRAP_SPACING

ISU <	mov	cx, MO_BASE_WIN_CHILD_SPACING
ISU <	mov	dx, MO_WIN_CHILD_WRAP_SPACING

if	(not _MOTIF)   	;spacing provided other ways now -12/ 4/92 cbh
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	je	OWGS_doneWithSpacing		;skip if base win
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	je	OWGS_doneWithSpacing		;   or display

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	OWGS_doneWithSpacing		;skip if is menu or submenu...

MO  <	mov	cx, MO_WIN_CHILD_SPACING	;		            >
ISU <	mov	cx, MO_WIN_CHILD_SPACING	;		            >

OWGS_doneWithSpacing:
endif

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	notToolbox
	mov	cx, TOOLBOX_SPACING		;toolboxes use larger spacing
notToolbox:

	;
	; Check for custom spacing, unless we're a OLDialogWin or OLMenuedWin,
	; in which case the gadget area will handle the hint.
	;
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass
	jc	5$
		CheckHack <segment OLDialogWinClass eq segment OLMenuedWinClass>
	mov	di, offset OLMenuedWinClass
	call	ObjIsObjectInClass
	jc	5$

	call	OpenCtrlCheckCustomSpacing
5$:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf
	jz	10$			;if so, spacing is in correct regs
	xchg	cx, dx			;swap registers for width, height
10$:
	call	OpenCheckIfCGA		;ax zeroed on CGA's
	jnc	20$
	tst	dx
	mov	dx, -1			;use -1 rather than 0 in CGA
					;CHECK BW FOR CUA LOOK
	jz	20$			;yep, branch
	mov	dx, 1			;else use 1 for minimal spacing
20$:
	popf
	jz	30$			;if so, spacing is in correct regs
	xchg	cx, dx			;swap registers back
30$:
	ret
OpenWinGetSpacing	endp

endif		;END of MOTIF/CUA specific code -----------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetMargins

DESCRIPTION:	Perform MSG_VIS_COMP_GET_MARGINS given an OLWinPart

CALLED BY:	INTERNAL

PASS:		ds:*si - instance data

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	7/89		Motif extensions
	JimG	4/94		Added Sytlus extensions

------------------------------------------------------------------------------@

if	_CUA_STYLE		;START of MOTIF/CUA specific code ----

OpenWinGetMargins	method OLWinClass, MSG_VIS_COMP_GET_MARGINS
	push	es
	segmov	es, dgroup, bp		; es = dgroup
					; bp = pointSize
	mov	bp, es:[specDisplayScheme.DS_pointSize]
	pop	es

	mov	di,ds:[si]		;ds:si = instance
	add	di,ds:[di].Vis_offset	;ds:si = SpecificInstance

	;Start with just basic margins for left, right, top, and bottom,
	;and assume the kids overlap each other and the frame line by
	;one pixel.  Register usage:
	;	cl -- top margin
	;	ch -- bottom margin
	;	dl -- left margin
	;	dh -- right margin
	;

if _MOTIF or _ISUI
if _ISUI
	;
	; ISUI has etched borders on all sides
	;
	mov	cx, (2 shl 8) or 2
	mov	dx, (2 shl 8) or 2
elif THREE_DIMENSIONAL_BORDERS
	;
	; DUI has double borders, each with shadow.
	;
	mov	cx, (THREE_D_BORDER_THICKNESS shl 8) or THREE_D_BORDER_THICKNESS
	mov	dx, (THREE_D_BORDER_THICKNESS shl 8) or THREE_D_BORDER_THICKNESS
else
	mov	cx, (1 shl 8) + 1	;default margins are 1 in color
	mov	dx, cx
	call	OpenCheckIfCGA		; CHECK BW FOR CUA LOOK
	jnc	2$
	clr	cx, dx			; 0 for everything
2$:
endif
else
	clr	cx, dx			; 0 for everything by default
endif

	;
	; If this is a "custom window", no margins by default.
	;
if not ALL_DIALOGS_ARE_MODAL
	;
	; Removed this check, as we're in keyboard-only mode and apparently
	; because of the forced-modal nature of things the forced-modal
	; express menu has become a MOWT_NOTICE_WINDOW.
	;
	cmp	ds:[di].OLWI_type, MOWT_COMMAND_WINDOW
	jne	afterCustomWindow
endif
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jz	afterCustomWindow
	clr	cx, dx
afterCustomWindow:

	mov	bx, ds:[di].OLWI_attrs	;get attributes for window
	;
	; If RESIZABLE then add size of resize border
	;
if _MOTIF
	call	OpenWinHasResizeBorder
	jnc	OWGS_noResize			;can't have resize bars, branch
	test	bx, mask OWA_MAXIMIZABLE
	jz	addResizeBars			;not maximizable...
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	OWGS_noResize			;is maximized, therefore
						;no resize border...
addResizeBars:

elif _ISUI

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	checkResizable
	clr	cx, dx				;no margins if maximized
	jmp	OWGS_noResize
checkResizable:
	;
	; use bigger margin if resizable or titled
	;
	test	bx, mask OWA_RESIZABLE or mask OWA_TITLED
	jz	OWGS_noResize

else
	test	bx, mask OWA_RESIZABLE
	jz	OWGS_noResize			;skip if not resizable...
endif
	push	ax
	push	es
	segmov	es, dgroup, ax
	mov	al, es:[resizeBarHeight].low
	mov	ah, al
	pop	es
if _ISUI
	mov	cx, ax
else
	add	cx, ax				;add margin to top and bottom
endif

	push	es
	segmov	es, dgroup, ax
	mov	al, es:[resizeBarWidth].low
	mov	ah, al
	pop	es
if _ISUI
	mov	dx, ax
else
	add	dx, ax				;add margin to left and right
endif
	pop	ax

OWGS_noResize:
	;
	; Code added 2/ 6/92 to allow menu bar in header in maximized mode.
	;
	call	OpenWinCheckMenusInHeader	;doing menus in header?
	jc	OWGS_noHeader			;yes, no title bar then.

	test	bx, mask OWA_TITLED		;does window have a title?
	jz	OWGS_noHeader			;skip if not...

	add	cl, CUAS_WIN_HEADER_Y_SPACING-1	; add margin to top for header

if	 _ALLOW_MINIMIZED_TITLE_BARS
	;
	; If we are minimizing the title bar, then don't include the font
	; height in calculcating the header size since we aren't displaying
	; a title.
	;
	test	ds:[di].OLWI_moreFixedAttr, mask OMWFA_MINIMIZE_TITLE_BAR
	jnz	dontAddFontHeight
endif	;_ALLOW_MINIMIZED_TITLE_BARS

	add	cx, bp			;add font height
ISU <	inc	cx			;add spacing under titlebar	>
ISU <	inc	cx			;add spacing under titlebar	>

if	 _ALLOW_MINIMIZED_TITLE_BARS
dontAddFontHeight:
endif	;_ALLOW_MINIMIZED_TITLE_BARS

if	 _TITLE_BARS_HAVE_WHITE_BORDER
	; Increase top margin by one.  Even though the white outline takes
	; up two pixels, we just want to make sure there is enough room for
	; descenders in the the title bar.  There is already enough space
	; above the moniker, even with the white space.
	inc	cx
endif	;_TITLE_BARS_HAVE_WHITE_BORDER

if	_MOTIF and not _ASSUME_BW_ONLY
	call	OpenCheckIfBW		;subtract a pixel in color.
	jc	25$
	dec	cx
25$:
endif
	;
	; If it's a CGA display, use a smaller header height
	;
	call	OpenWinCheckIfSquished
	jnc	OWGS_noHeader
	sub	cl, (CUAS_WIN_HEADER_Y_SPACING - CUAS_CGA_WIN_HEADER_Y_SPACING)
	jmp	OWGS_noHeader

OWGS_noHeader:
	; if this window wants its children to be physically inside
	; the frame border (instead of on it), inset them some.

if	_MOTIF
	call	OpenCheckIfBW
	jnc	OWGS_80			;not B/W, don't bother with margins.
endif
	test	bx, mask OWA_KIDS_INSIDE_BORDER
	jz	OWGS_80

	add	cx,(CUAS_WIN_LINE_BORDER_SIZE shl 8) + CUAS_WIN_LINE_BORDER_SIZE
	add	dx,(CUAS_WIN_LINE_BORDER_SIZE shl 8) + CUAS_WIN_LINE_BORDER_SIZE

	;if this window wants its children to be physically inside the frame
	;border (instead of on it), inset them some.

OWGS_80:

if (not _MOTIF)
	test	bx, mask OWA_REAL_MARGINS
	jz	OWGS_92

	add	cx, (CUAS_REAL_MARGIN_SIZE shl 8) + CUAS_REAL_MARGIN_SIZE
	add	dx, (CUAS_REAL_MARGIN_SIZE shl 8) + CUAS_REAL_MARGIN_SIZE

	; Use less of a margin in CGA.
	call	OpenCheckIfCGA
	jz	OWGS_90
	sub	cx, (CUAS_REAL_MARGIN_CGA_DIFF shl 8)+CUAS_REAL_MARGIN_CGA_DIFF
OWGS_90:

	call	OpenCheckIfNarrow
	jz	OWGS_92
	sub	dx, (CUAS_REAL_MARGIN_CGA_DIFF shl 8)+CUAS_REAL_MARGIN_CGA_DIFF
OWGS_92:
endif	; (not _MOTIF)

if (not _MOTIF)
	;
	; if this is a GenSummons (OLNoticeWin) then leave space for
	; thick inset border
	;
	cmp	ds:[di].OLWI_type, MOWT_NOTICE_WINDOW
	jne	OWGS_95			;skip if not...

	add	cx, (CUAS_NOTICE_FRAME_Y_SPACE shl 8) or \
			CUAS_NOTICE_FRAME_Y_SPACE
	add	dx, (CUAS_NOTICE_FRAME_X_SPACE shl 8) or \
			CUAS_NOTICE_FRAME_X_SPACE
if _ISUI ;-------------------------------------------------------------
	;
	; Compensate for CGA's wierd aspect ratio, if necessary

	call	OpenCheckIfCGA
	jnc	OWGS_95

	sub	cx, (MO_CGA_NOTICE_FRAME_INSET_BOTTOM_DIFF shl 8) or \
			MO_CGA_NOTICE_FRAME_INSET_TOP_DIFF
	sub	dx, (MO_CGA_NOTICE_FRAME_X_INSET_DIFF shl 8) or \
			MO_CGA_NOTICE_FRAME_X_INSET_DIFF
endif	;---------------------------------------------------------------

OWGS_95:
endif

	; FINALLY, if composite is horizontal, we have to switch registers
	; to maintain the vertical & horizontal margins that we want.
	; (Geometry manager uses width & height notions, which align with
	; direction of alignment)

	xchg	cx, dx			;assume horizontal, switch registers
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					;See if using vertical alignment
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	isHorizontal		;if so, spacing is in correct regs

	dec	ax			;will be inc'ed below
	call	OpenMinimizeIfCGA	;ax zeroed on CGA's
	inc	ax			;use spacing of 1 on CGA's

isHorizontal:
	call	ReturnAxBpCxDx		;put margins in right registers

if DIALOGS_WITH_FOLDER_TABS
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	notTabbed

	push	ax, bx
	mov	ax, HINT_INTERACTION_FOLDER_TAB_DIALOG
	call	ObjVarFindData
	pop	ax, bx
	jnc	notTabbed

	add	cx, 2 * TAB_SHADOW_SIZE
notTabbed:
endif


if	DRAW_SHADOWS_ON_BW_GADGETS
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	exit
	call	OpenCheckIfBW
	jnc	exit
	inc	cx			;leave room for shadow
	inc	dx
exit:
endif

if	_ROUND_THICK_DIALOGS
	call	OpenWinShouldHaveRoundBorderFar
	jnc	notRoundThickBorder
	add	ax, _ROUND_THICK_DIALOG_BORDER
	add	bp, _ROUND_THICK_DIALOG_BORDER
	add	cx, _ROUND_THICK_DIALOG_BORDER
	add	dx, _ROUND_THICK_DIALOG_BORDER
notRoundThickBorder:
endif

if	_THICK_MENU_BOXES
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	notMenu
	inc	ax
	inc	bp
	inc	cx
	inc	dx
notMenu:
endif	;_THICK_MENU_BOXES

if	 BUBBLE_DIALOGS
	; Add in extra margins that comes with bubble popups, if any.

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	doneWithBubbleMargin

	push	ax, bx
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarFindData
	mov	di, bx
	pop	ax, bx
	jnc	doneWithBubbleMargin

	add	ax, ds:[di].P_x
if _DUI
	add	bp, ds:[di].P_y
endif

doneWithBubbleMargin:
endif	;BUBBLE_DIALOGS

	ret
OpenWinGetMargins	endp

endif		;END of MOTIF/CUA specific code -----------------------


COMMENT @----------------------------------------------------------------------

ROUTINE:	ReturnAxBpCxDx

SYNOPSIS:	Returns margins a certain way.

CALLED BY:	OpenWinGetMargins, OpenWinGetSpacing

PASS:		cl/ch/dl/dh -- Top/Bottom/Left/Right margins

RETURN:		bp/dx/ax/cx -- Top/Bottom/Left/Right margins

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/16/91		Initial version

------------------------------------------------------------------------------@

ReturnAxBpCxDx	proc	near
	;
	; Move margins from dl/dh/cl/ch to bp/dx/ax/cx.
	;
	clr	ax
	mov	al, dl
	tst	al
	jns	1$
	dec	ah
1$:
	mov	bp, ax

	mov	dl, dh
	clr	dh
	tst	dl
	jns	2$
	dec	dh
2$:
	clr	ax
	mov	al, cl
	tst	al
	jns	3$
	dec	ah
3$:
	mov	cl, ch
	clr	ch
	tst	cl
	jns	4$
	dec	ch
4$:
	ret
ReturnAxBpCxDx	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinGetMinSize

SYNOPSIS:	Returns the minimum size for a window.
		IMPORTANT: OLBaseWinClass subclasses this method to add
		spacing for the Workspace and Application icons

PASS:		*ds:si -- object

RETURN:		cx -- minimum width
		dx -- minimum height

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/1/89		Initial version

------------------------------------------------------------------------------@

OpenWinGetMinSize	method dynamic	OLWinClass,
			MSG_VIS_COMP_GET_MINIMUM_SIZE

	mov	di, offset OLWinClass		;call superclass for desired
	call	ObjCallSuperNoLock		;   size stuff
	push	dx				;save return height
	push	cx				;save returned width

	call	OpenWinCalcMinWidth	;cx <- minimum allowable width for
					;this window, taking into account the
					;header area if any.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jnz	10$				;resizable, don't add moniker
if _ISUI
	; allow clipping of moniker for non-resizable primaries (i.e. AddrBook)
	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW
	je	10$
endif
	;
	; if maximized, don't want overly large min-size to confuse us, so
	; we ignore the moniker
	;
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	10$
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	addMoniker			;not a menu, use moniker...
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	10$				;not pinned, don't use moniker

addMoniker:
	push	cx				;save width so far

	call	ViewCreateCalcGState		;create a gstate in bp
	call	OpenWinGetMonikerSize		;get moniker size of window
	mov	di, bp				;pass gstate
	call	GrDestroyState			;destroy the gstate

	pop	dx				;get current width back
	add	cx, dx				;and add in
CUAS <	add	cx, CUAS_TITLE_TEXT_MARGIN*2	;add in title margins      >

10$:
	pop	ax				;extra width from superclass
	pop	dx				;extra height from superclass

	cmp	ax, cx				;larger than window's result?
	jb	20$				;no, exit
	mov	cx, ax				;else use it instead
20$:
	mov	ax, ABSOLUTE_WIN_MIN_SIZE	;don't get smaller than this
						;  (mostly for the benefit of
						;   popup list buttons)
	cmp	cx, ax
	jae	30$
	mov	cx, ax
30$:
	cmp	dx, ax
	jae	40$
	mov	dx, ax
40$:
	ret
OpenWinGetMinSize	endp
	public	OpenWinGetMinSize


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateGeometry -- MSG_VIS_UPDATE_GEOMETRY for OLWinClass

DESCRIPTION:	Updates the geometry for the window.  If first time being
		arranged geometrically, then attemps to keep the thing
		on-screen, first by resizing it, then by moving it.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_UPDATE_GEOMETRY

RETURN:		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		save current bounds
		call parent to update the geometry
		get size of parent window

		;
		; If window is coming up for the first time, first resize to
		; try to keep it onscreen.  If that fails, try moving it.
		;
		if originally passed mask RSA_CHOOSE_OWN_SIZE for either
		dimension...

		    ; Try to do easy things to keep onscreen.

		    ;save original left, top edge

		    get current window origin in cx, dx
		    if right > parentWidth, cx = cx - (right - parentWidth)
		    if bottom > parentBottom, dx = dx - (bottom - parentBottom)
		    if cx negative, cx = 0
		    if dx negative, dx = 0
		    call VisSetPosition

		    ; Now, bring in right or bottom edge and do new geometry
		    ; stuff to keep onscreen.

		    if right > parentWidth, right = parentWidth
		    if bottom > parentHeight, bottom = parentHeight

		    update window's geometry

		    ; Move the object back to its original position, in case
		    ; it can be there again with the new geometry.

		    ;restore original left, top edge
		    ;call VisSetPosition

		    ; Now, one last feeble attempt to move the window onscreen.

		    if right > parentWidth, cx = cx - (right - parentWidth)
		    if bottom > parentBottom, dx = dx - (bottom - parentBottom)
		    if cx negative, cx = 0
		    if dx negative, dx = 0
		    call VisSetPosition

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/30/89		Initial version
	Doug	6/89		Modifications to get working, on screen stuff
				moved to MSG_VIS_SET_POSITION handler.

------------------------------------------------------------------------------@

OpenWinUpdateGeometry	method dynamic	OLWinClass, MSG_VIS_UPDATE_GEOMETRY
	;first see if this is the first UPDATE_GEOMETRY:

if 0
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di
endif

	call	VisGetSize			;get current size, OR-ed
						;with RSA_CHOOSE_OWN_SIZE flag
	or	cx, dx				;check in X or Y
	push	cx				;save value

	;SAVE on stack whether geometry is invalid or not, and current width

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	pushf					;save invalid flags

CUAS <	mov	bx, ds:[di].VI_bounds.R_right				>
CUAS <	sub	bx, ds:[di].VI_bounds.R_left				>
CUAS <	push	bx				;save width		>

	push	es
	mov	di, offset OLWinClass
	call	ObjCallSuperNoLock		;do regular UpdateGeometry
	pop	es

	call	OpenGetParentWinSize		;window is on

if TOOL_AREA_IS_TASK_BAR

	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.

	call	GetTaskBarSizeAdjustment
	sub	dx, di			; subtract off taskbar adjustment

endif

CUAS <	pop	bx				;get previous width	>
	popf					;restore invalid flags
OLS <	jz	OWUG_afterGeoUpdate		;skip if was not INVALID... >

CUAS <	jnz	OWUG_isResizing			;skip if was INVALID...     >

	;check if width has changed: sometimes objects can be added to
	;a window and GEOMETRY_INVALID won't be set. (See Doug.)

CUAS <	mov	di, ds:[si]						>
CUAS <	add	di, ds:[di].Vis_offset					>
CUAS <	add	bx, ds:[di].VI_bounds.R_left				>
CUAS <	cmp	bx, ds:[di].VI_bounds.R_right				>
CUAS <	je	OWUG_afterGeoUpdate		;skip if no width change... >

OWUG_isResizing:
OLS <	call	CenterIfNotice		    	; Center window on screen   >

	push	cx, dx, bp
	CallMod	OpenWinCalcWinHdrGeometry	;determine which sys menu
	pop	cx, dx, bp			;icons are needed and place

OWUG_afterGeoUpdate:
	pop	ax				;get DSA_CHOOSE_OWN_SIZE flag

if (0)	; We should check even if not first time since we might have grown
	; too big. - Joon (7/27/94)
	test	ax, mask RSA_CHOOSE_OWN_SIZE	;sizing for first time?
	jz	done				;skip if not...
endif

	;check attribute flag to see if we want to test for window being
	;clipped by parent.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_winPosSizeFlags, \
			mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
	jz	done
checkIt::
	call	OpenWinRefitToParent		;Levi's 501 if necessary

done:
if 0
	pop	di
	call	ThreadReturnStackSpace
endif
	ret					;else done

OpenWinUpdateGeometry	endp




OpenWinRefitToParent	proc	near		;cx, dx are parent width & ht
	class	OLWinClass

	mov	ax, cx				;keep parent width in ax
	mov	bp, dx				;keep parent height in bp

	clr	bx
	call	VisGetSize			;see if our window too big
	cmp	cx, ax				;width too big?
	jbe	10$				;no, branch
	mov	cx, ax				;else use screen value
	inc	bx				;mark as needing geometry
10$:
	cmp	dx, bp				;width too big?
	jbe	20$				;no, branch
	mov	dx, bp				;else use screen value
	inc	bx				;mark as needing geometry
20$:
	tst	bx				;no size changed needed, branch
	jz	checkPosition
	call	VisSetSize			;else try out new size for
						;  the window
	;
	; If the window is bigger than the screen, we'll first try redoing
	; geometry so the thing will fit.  In popup list cases, we'll try
	; reorienting the menu, and all of its visible children.
	;
	push	ax, bp
	mov	ax, ds:[di].OLCI_buildFlags
	and	ax, mask OLBF_TARGET
	cmp	ax, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	jne	stayOnscreen			;not popup list, too dangerous

	;
	; Already vertical, don't try making as such, because we will want to
	; try to wrap instead.  -cbh 3/26/93
	;
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	stayOnscreen

	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY

	mov	cx, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	clr	dx
	mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS
	call	VisSendToChildren

	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	call	ObjCallInstanceNoLock
	jmp	short update

stayOnscreen:
	mov	dl, VUM_MANUAL
	mov	ax, MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN
	call	ObjCallInstanceNoLock		;reset geometry on this thing

update:
	mov	ax, MSG_VIS_UPDATE_GEOMETRY
	push	es
	mov	di, offset OLWinClass		;call parent again
	call	ObjCallSuperNoLock		;do regular UpdateGeometry
	pop	es
	pop	ax, bp				;restore parent width, height

checkPosition:
	call	MoveWindowToKeepOnscreen	;try to move the window onscreen

	;update title bar size and icon positions also

	tst	bx
	jz	exit				;no changes needed
	push	cx, dx, bp
	CallMod	OpenWinCalcWinHdrGeometry	;determine which sys menu
	pop	cx, dx, bp			;icons are needed and place
exit:
	ret
OpenWinRefitToParent	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGetChildsTreePos --
		MSG_OL_GET_CHILDS_TREE_POS for OLWinClass

DESCRIPTION:	Returns true if object passed is child of non-menu window.
		Also returns whether the child is the first child
		of the window either generically or visually (depending on
		what is passed).  This generic-or-specific stuff is
		extremely dubious.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_GET_CHILDS_TREE_POS
		cx:dx	- handle of child
		bp      - offset to generic or visual part

RETURN:		carry set if this is a non-menu window
		cx 	- FALSE if child is not the first child

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      		This assumes child used VisCallParent to get here, so we
		can assume that the object passed is in fact a child of
		this object.

		This is all kind of hacked.  This problem is that composites
		need to find out if they're the immediate children of a
		window, and if they are, if they're the first or last item in
		the window.  The problem is that we have objects that are
		only in the visual linkage, so we can't use the generic;  we
		have the text object calling this when being vis built that
		can't use the visual;  and we have objects that are the last
		children in the visual tree, but don't really show up there,
		meaning some object before them is actually at the bottom,
		in which case we check generic linkage.  So we have:

			  Parent linkage    First child	   Last child

		Ctrls	  Visual	    Visual 	   Generic
		Text	  Generic	    Generic 	   Generic

		Pretty bad, eh?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/23/89	Initial version

------------------------------------------------------------------------------@

OLWinGetChildsTreePos	method dynamic	OLWinClass,
					MSG_OL_GET_CHILDS_TREE_POS

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	GCTP_exit			;skip if menu or submenu (cy=0)

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di][bp]			;add offset
	cmp	bp, Gen_offset			;see if doing generic
	jne	GCTP_visual			;no, branch
	add	di, GI_comp			;else get offset to comp part
	jmp	short GCTP_checkFirst

GCTP_visual:
	add	di, VCI_comp			;get offset to comp part

GCTP_checkFirst:
	cmp	cx, ds:[di].CP_firstChild.handle
	mov	cx, FALSE			;assume not first child
	jne	GCTP_returnCarrySet		;not first, exit
	cmp	dx, ds:[di].CP_firstChild.chunk
	jne	GCTP_returnCarrySet		;chunk doesn't match, exit
	dec	cx				;else set cx true

GCTP_returnCarrySet:
	stc					;return parent is non-menu win

GCTP_exit:
	ret
OLWinGetChildsTreePos	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinCalcMinWidth

DESCRIPTION:	Calculate the minimum size for an OpenLook window.

PASS:		*ds:si	= instance data for object

RETURN:		cx = min width

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		Sum up sizes of header bar gadgets, slop from 1-pixel overlap
		of gadgets will allow for a small sliver of title bar to show
		through, allowing the user to grab and move the window.  How
		convenient!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	?	1/90		initial version

------------------------------------------------------------------------------@

if 	_CUA_STYLE	;START of MOTIF specific code -------------------------

OpenWinCalcMinWidth	proc	near
	class	OLWinClass
	uses	ax, dx, di, bp
	.enter

NOT_MO<	clr	cx				;objects touch edges in CUA  >
MO<	mov	cx, CUAS_WIN_LINE_BORDER_SIZE*2	;start with thin line borders>
ISU<	mov	cx, CUAS_WIN_LINE_BORDER_SIZE*2	;start with thin line borders>
ISU<	add	cx, 4				;it seems we have extra border>

	mov	di, ds:[si]			;point to specific instance
	add	di, ds:[di].Vis_offset

	;If RESIZABLE add in width of two resize borders

if _MOTIF
	call	OpenWinHasResizeBorder
	jnc	notResizable			;can't have resize bars, branch
else
	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jz	notResizable			;skip if not resizable...
endif

	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	mov	ax, ds:[resizeBarWidth]
	sal	ax, 1			; calc resize border width * 2

	add	cx, ax
	pop	ds

notResizable:

if	 BUBBLE_DIALOGS
	; Add in extra left margin that comes with bubble popups, if any.

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	doneWithBubbleMargin

	push	bx
	mov	ax, TEMP_OL_WIN_BUBBLE_MARGIN
	call	ObjVarFindData
	mov	ax, ds:[bx]			; ax = left margin
	pop	bx
	jnc	doneWithBubbleMargin

	add	cx, ax				; add left margin

doneWithBubbleMargin:
endif	;BUBBLE_DIALOGS

	;If has a system menu, add in room for three icons

	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU
	jz	noSysMenu

if _ISUI
	call	CheckSysMenuButton
	jnc	afterSysMenuButton
endif

;	add	cx, CUAS_WIN_ICON_WIDTH		;add room for System Icon
;deal with sys menu button with kdb accelerator shown
	mov_tr	ax, cx
	call	OpenWinGetSysMenuButtonWidth	;cx = width of sys menu button
ISU <	add	cx, 6				;match other adjustments >
	add	ax, cx
	mov_tr	cx, ax
afterSysMenuButton::

	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jz	9$
	add	cx, CUAS_WIN_ICON_WIDTH		;add room for Close button

9$:
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	10$

	add	cx, CUAS_WIN_ICON_WIDTH		;add room for Maximize button

10$:
	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	noSysMenu

	add	cx, CUAS_WIN_ICON_WIDTH		;add room for Minimize button

noSysMenu:
	;
	; add in sizes of left and right title bar groups
	;	cx = min width so far
	;
	mov_tr	ax, cx				;ax = width so far
	mov	bp, offset OLWI_titleBarLeftGroup
	call	OpenWinGetTitleBarGroupSize	;cx = width or 0, dx = height
						;(destroys di)
	add	ax, cx
	mov	bp, offset OLWI_titleBarRightGroup
	call	OpenWinGetTitleBarGroupSize	;cx = width or 0, dx = height
						;(destroys di)
	add	ax, cx
	mov_tr	cx, ax				;cx = total min width

	.leave
	ret

OpenWinCalcMinWidth	endp

endif		;END of MOTIF specific code -----------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinResetToInitialSize --
		MSG_VIS_RESET_TO_INITIAL_SIZE for OLWinClass

DESCRIPTION:	Resets a window to its initial size.   For most windows,
		we'll zap the size back to RS_CHOOSE_OWN_SIZE so the window
	 	will choose a completely new size again, unless its maximized,
		in which case we'll leave the window size alone.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RESET_TO_INITIAL_SIZE
		dl	- VisUpdateMode

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
	chris	2/18/92		Initial Version

------------------------------------------------------------------------------@

OLWinResetToInitialSize	method dynamic	OLWinClass,
				MSG_VIS_RESET_TO_INITIAL_SIZE

	;
	; Hopefully, this will allow max'ed windows that are too large to
	; shrink.
	;
	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID

	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	nukeSize
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	finishSize

nukeSize:
	push	dx
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, cx
	call	VisSetSize
	pop	dx

finishSize:
	push	ax, dx
	call	UpdateWinPosSize	;update window position and size if
	pop	ax, dx			;have enough info. If not, then wait
					;until OpenWinOpenWin to do this.
					;(VisSetSize call will set window
					;invalid)
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock

OLWinResetToInitialSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinRecalcDisplaySize --
		MSG_OL_WIN_RECALC_DISPLAY_SIZE for OLWinClass

DESCRIPTION:	Returns size of window, after making sure geometry's up-to-date.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_RECALC_DISPLAY_SIZE

RETURN:		carry	- set (size returned)
		cx, dx  - size to use
			- or -
		carry	- clear (no size returned)
		ax, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/15/92		Initial Version

------------------------------------------------------------------------------@

OLWinRecalcDisplaySize	method dynamic	OLWinClass,
					MSG_OL_WIN_RECALC_DISPLAY_SIZE
	;
	; If we are not maximizable, then don't return a size, as our
	; size does not change. This will prevent the DisplayGroup from
	; shrinking to fit our size. If this code backfires, one could
	; add this logic to a method for OLDisplayWinClass.
	;
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	done				; carry is clear, which is
						; exactly what we want

	test	ds:[di].VI_attrs, mask VA_VISIBLE
	pushf

	;
	; Ensure the thing is spec built, so we can run the geometry
	; manager over it.
	;
	push	cx, dx
	mov	cl, mask SA_ATTACHED
	clr	ch
	mov	dl, VUM_MANUAL
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock	; Hopefully get the thing built

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;try to make it not flash
	mov	cl, mask VOF_GEOMETRY_INVALID	;  -cbh 11/17/92
	call	VisMarkInvalid
	pop	cx, dx

	call	VisSetSize			;set as size to start with
	;
	; Run the geometry over it, and get the resulting size.  (Have the
	; VOF_UPDATING flag set so any resulting image invalidations are
	; saved in a region, rather than immediate VisInvalRects. -cbh 3/ 7/93)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_UPDATING
	pushf
	or	ds:[di].VI_optFlags, mask VOF_UPDATING

	mov	ax, MSG_VIS_UPDATE_GEOMETRY
	call	ObjCallInstanceNoLock
	call	VisGetSize			;get size in cx, dx

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; We want to clear the VOF_UPDATING flag if it wasn't set coming in.
	; -cbh 3/ 7/93
	;
	popf
	jnz	10$
	and	ds:[di].VI_optFlags, not mask VOF_UPDATING
10$:
	;
	; Clear this flag -- we don't want to be visible if we weren't coming
	; in.
	;
	popf
	jnz	done				;was already VA_VISIBLE, done
	and	ds:[di].VI_attrs, not mask VA_VISIBLE
done:
	stc
exit:
	ret
OLWinRecalcDisplaySize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinUpdatePositionForTaskBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update window position to account for taskbar position change

CALLED BY:	MSG_OL_WIN_UPDATE_POSITION_FOR_TASK_BAR

PASS:		*ds:si	= OLWinClass object
		es 	= segment of OLWinClass
		ax	= message #
		cx	= TRUE if only minimized windows are to be updated
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	7/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR
OLWinUpdatePositionForTaskBar	method dynamic OLWinClass,
					MSG_OL_WIN_UPDATE_POSITION_FOR_TASK_BAR
	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	done					; skip if no taskbar

	jcxz	doUpdate

	; check if window is minimized

	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jz	done			; skip if not minimized

doUpdate:
	push	ds
	segmov	ds, dgroup
	test	ds:[taskBarPrefs], mask TBF_AUTO_HIDE
	pop	ds
	mov	dx, 1			; assume auto-hide is on (dx = 1)
	jnz	gotSize
	call	OLWinGetToolAreaSize

gotSize:
	push	ds, bx					; save ds
	segmov	ds, dgroup				; get dgroup
	mov	bx, ds:[taskBarPrefs]			; load taskBarPrefs in ax
	andnf	bx, mask TBF_POSITION			; mask out everything but the position bits
	shr	bx, offset TBF_POSITION
	cmp	bx, TBP_TOP
	pop	ds, bx					; restore ds
	je	update					; skip if top position

	neg	dx
update:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	ds:[di].VI_bounds.R_top, dx
	add	ds:[di].VI_bounds.R_bottom, dx

	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid
done:
	ret
OLWinUpdatePositionForTaskBar	endm
endif

Geometry	ends

Resident	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinGetMonikerSize

SYNOPSIS:	Gets moniker size for a window.  If this is a GenPrimary,
		returns the sum of the visMoniker and the longTermMoniker.
		Ignores the long term moniker if we're in GCM mode.

CALLED BY:	OpenWinGetMinSize

PASS:		*ds:si -- object handle
		bp	- GState to use

RETURN:		cx -- width of the moniker
		dx -- bigger height of the monikers
		bp -- same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       	Could/should be in a movable module, with CallMod to reach it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/90		Initial version

------------------------------------------------------------------------------@

OpenWinGetMonikerSize	proc	far		uses bx, di, bp, ax
	class	OLWinClass

	.enter
	mov	di, ds:[si]			;ptr to instance data
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker 	;fetch moniker
	segmov	es, ds				;es:di = moniker
	call	SpecGetMonikerSize		;get size of moniker in cx, dx

	;
	; If not a base window, we're done.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
CUAS <	cmp	ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW		>
OLS  <  cmp	ds:[di].OLWI_type, OLWT_BASE_WINDOW		>
     	jne	exit				;not a primary, we're done

	;
	; No long term moniker, we're done.
	;
	mov	di, ds:[si]			;ptr to instance data
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance

	.warn	-private

	mov	di, ds:[di].GPI_longTermMoniker ;fetch long term moniker

	.warn	@private

	tst	di				;is there one?
	jz	exit				;no, we're done

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
	; on horizontally tiny screens, we just draw long term moniker, if any
	; so let's do the same here for the width
	;	*es:di = long term moniker
	;	bp = gstate
	;
	call	SpecGetMonikerSize		;cx = width, dx = height
	jmp	exit

normalDraw:
	;
	; Add in space for the " - "
	;
	push	dx				;save height
	xchg	di, bp				;di holds gstate, bp holds mkr
	call	GetDividerStrLen		;returns length of " - " in dx
	add	cx, dx				;add the total to visMkr size
	push	cx				;save width that comes back

	xchg	di, bp				;es:di holds mkr, bp <- gstate
	call	SpecGetMonikerSize		;get its size in cx
	mov	bx, dx				;keep height in bx
	pop	dx				;restore GenMoniker width
	add	cx, dx				;add into long term moniker size
	pop	dx				;restore GenMoniker height
	cmp	dx, bx				;see if this height is bigger
	ja	exit				;no, branch
	mov	dx, bx				;else use that height instead
exit:
	.leave
	ret
OpenWinGetMonikerSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDividerStrLen

SYNOPSIS:	Gets the length of the divider before the long term moniker.

CALLED BY:	OpenWinGetMonikerSize, OpenWinDrawMoniker

PASS:		di -- gstate

RETURN:		dx -- length

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/27/90		Initial version

------------------------------------------------------------------------------@

GetDividerStrLen	proc	far	uses ds, si, cx
	.enter
	segmov	ds, cs, si
	mov	si, offset resLongTermStr	;ds:si points to string
	clr	cx				;all chars
	call	GrTextWidth			;return width
	.leave
	ret
GetDividerStrLen	endp


SBCS <resLongTermStr	db	" - ",0					>
DBCS <resLongTermStr	wchar	" - ",0					>


COMMENT @----------------------------------------------------------------------

ROUTINE:	MoveWindowToKeepOnscreen

SYNOPSIS:	Moves window bounds to try to keep it onscreen.

CALLED BY: 	OpenWinRefitToParent

PASS:		*ds:si -- window
		ax, bp -- parent width and height, respectively
		bx     -- flag to indicate new geometry needs doing
				(zero if not, non-zero if so)

RETURN:		bx updated
		ds:di -- pointer to VisInstance

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		    get current window origin in cx, dx
		    if right > parentWidth, cx = cx - (right - parentWidth)
		    if bottom > parentBottom, dx = dx - (bottom - parentBottom)
		    if cx negative, cx = 0
		    if dx negative, dx = 0
		    call VisSetPosition

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/24/91		Initial version

------------------------------------------------------------------------------@

MoveWindowToKeepOnscreen	proc	far	uses	ax, bp
	.enter
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_top
	sub	ax, ds:[di].VI_bounds.R_right	;see if past right edge
	jae	10$				;no, branch
	add	cx, ax				;else try to move window left
	inc	bx				;say an update necessary
10$:						;
	sub	bp, ds:[di].VI_bounds.R_bottom	;see if past bottom edge
	jae	20$				;no, branch
	add	dx, bp				;else try to move window up
	inc	bx				;say an update necessary
20$:						;
	tst	cx				;keep left edge positive
	jns	30$
	clr	cx
29$::
	inc	bx				;say an update necessary
30$:
	tst	dx				;keep top edge positive
	jns	40$
	clr	dx
39$:
	inc	bx				;say an update necessary
40$:

	call	VisSetPosition			;affect change in window origin

	.leave
	ret
MoveWindowToKeepOnscreen	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinCheckIfSquished

SYNOPSIS:	Checks to see if we're on a CGA only.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if CGA

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/16/93		Initial version

------------------------------------------------------------------------------@

OpenWinCheckIfSquished	proc	far	uses ax, ds
	.enter

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[moCS_flags], mask CSF_VERY_SQUISHED
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenWinCheckIfSquished	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWinHasResizeBorder

SYNOPSIS:	Returns whether this thing has a resize border or not.

CALLED BY:	utility

PASS:		*ds:si -- OLWinClass object

RETURN:		carry set if has resize border

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/10/93       	Initial version

------------------------------------------------------------------------------@

if	_MOTIF

OpenWinHasResizeBorder	proc	far		uses	bx, di
	.enter
	call	Res_DerefVisDI
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	exit				;pinned, forget border (c=0)
						; -cbh 2/17/93

	mov	bx, ds:[di].OLWI_attrs		;get attributes for window

	call	OpenCheckIfCGA			;CGA is based on resizable only
	jc	checkResizable
	call	OpenCheckIfNarrow		;so is tiny
	jc	checkResizable

	test	bx, mask OWA_TITLED
	jz	exit				;skip if not titled (c=0)
	jmp	short hasResizeBorder

checkResizable:
	test	bx, mask OWA_RESIZABLE
	jz	exit				;skip if not resizable (c=0)

hasResizeBorder:
	stc
exit:
	.leave
	ret
OpenWinHasResizeBorder	endp

endif

Resident	ends
