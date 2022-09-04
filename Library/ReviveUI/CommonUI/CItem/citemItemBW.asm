COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC 
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemItemBW.asm

ROUTINES:
	Name			Description
	----			-----------
    INT ItemDrawBWItem          Draw an OLItemClass object on a black &
				white display.

    INT OLItemInsetIfCenteredBoolean 
				Insets moniker if a center-by-monikers
				boolean.

    INT OLItemDrawYesNoIfBoolean 
				Draws "Yes" or "No" if we're a boolean.

    INT ItemDrawBWItemHighlight Either draws or clears the inner
				highlighting rectangle.

    INT ItemDrawBWItemHighlight Either draws or clears the inner
				highlighting rectangle.

    INT ItemDrawBWRadioButton   Draws a radio button.

    INT ItemDrawBWRadioButtonPartial 
				Draws a radio button item in part.

    INT ItemDrawBWRadioButtonButton 
				Draw the actual button part.

    INT ItemDrawBWRadioButtonBitmap 
				Draws a radio button bitmap.

    INT ItemDrawBWNonExclusiveItem 
				Draws a non-exclusive item.

    INT ItemDrawBWNonExclusiveItemPartial 
				Do a partial redraw of a nonexclusive item.

    INT ItemDrawNonExclusiveCheckbox 
				Draw the checkbox & border for a
				non-exclusive item.

    INT ItemDrawBWNonExclHighlight 
				Draw the inside highlight for a
				non-exclusive item.

    INT ItemDrawBWCheckmarkInBox 
				draw the Checkmark for an OpenLook item.

    INT ItemDrawBWCheckmarkInBox 
				draw the Checkmark for an OpenLook item.

    INT ItemDrawBWInnerSquareMark 
				draw the inner square mark in a Motif
				non-exclusive item

    INT ItemDrawBWXMark         draw the inner X mark in a non-exclusive
				item.

    INT ItemDrawBWXMark         draw the inner X mark in a non-exclusive
				item.

    INT ItemDrawBWMotifItemBorderIfInMenu 
				Draws or erases border around a Motif item
				(excl or non-excl) which is in a menu,
				according to the BORDERED flag. (This flag
				is set when the item is CURSORED.)

    INT ItemBWForegroundColorIfDepressedIfInMenu 
				Returns the foreground color for an item if
				it is in a menu based upon the depressed
				bit.

    INT ItemDrawBWItemDepressedIfInMenu 
				Draws/erases or XOR's inverted background
				around item (both excl and non-excl) which
				is in a menu, according to the DEPRESSED
				flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItem.asm

DESCRIPTION:
	$Id: citemItemBW.asm,v 1.21 97/02/18 19:00:38 cthomas Exp $

------------------------------------------------------------------------------@
DrawBW segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an OLItemClass object on a black & white display.

CALLED BY:	OLItemDraw

PASS:		*ds:si	- instance data
		cl	- color scheme (from GState)
		ch	- DrawFlags:  DF_EXPOSED set if updating
		di	- GState to use

RETURN:		*ds:si	- same

DESTROYED:	ax, bx, cx, dx, di, bp

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	2/89	Initial version
	Eric	3/90	cleanup
	Chris	4/91	Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; PCV has a whole new routine.
;
if not _PCV

ItemDrawBWItem	proc	far
	class	OLItemClass

if _RUDY
	push	di			;save gstate
endif

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	
	call	OLItemGetGenAndSpecState
					;sets:	bl = OLBI_moreAttrs
					;	bh = OLBI_specState (low byte)
					;	cl = OLBI_optFlags
					;	dl = GI_states
					;	dh = OLII_state

	mov	ax, C_WHITE		;set draw colors
	call	GrSetAreaColor

	mov	ax, C_BLACK
if USE_COLOR_FOR_DISABLED_GADGETS
	call	OLItemSetUseColorIfDisabled
endif
	call	GrSetTextColor
	call	GrSetLineColor

if _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50

	;set the draw masks to 50% if this object is disabled

	mov	al, SDM_50		;Use a 50% mask 
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

	push	di
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

if _DISABLED_SCROLL_ITEMS_DRAWN_WITH_SDM_50
	call	CheckIfJustDisabled
	jnc	fullRedraw		;going enabled, branch to do it

	push	ax, cx
	mov	al, mask SDM_INVERSE or SDM_50	;Use inverse of 50% mask 
	clr	ch 			; B/W
	call	OLItemWash50Percent
	pop	ax, cx
	jmp	done			;exit now. (bx, cx, dx trashed)
endif

fullRedraw:
	;we must fully redraw this object, including the background

	mov	ch, TRUE

drawCommon:
	;regs:
	;	al = flags which have changed
	;	bl = OLBI_moreAttrs
	;	cl = OLBI_optFlags
	;	ch = TRUE if is full redraw
	;	dh = OLII_state
	;Yes, we could have plenty of optimizations here in the future, to
	;handle transitions between specific states. But since we are running
	;out of memory and not processor speed, punt!

	test	dh, mask OLIS_MONIKER_INVALID
	LONG jnz	done			;skip if invalid...

	;if is an OLCheckboxClass object, call routine to handle.

CUAS <	test	dh, mask OLIS_DRAW_AS_TOOLBOX			>
CUAS <	jnz	drawPlainItem	;skip if in toolbox...	>
	test	dh, mask OLIS_IS_CHECKBOX
	jz	drawExclusiveItem	;skip if not...

	GOTO	ItemDrawBWNonExclusiveItem

drawExclusiveItem:
	;this object is an exclusive item

CUAS <	GOTO	ItemDrawBWRadioButton	;draw a radio button	>

drawPlainItem:
	;This code is reached when:
	;	CUA:		in toolbox (which might be in menu)
	;	Motif:		B&W, in toolbox (which might be in menu)
	;	OpenLook:	B&W, all cases: menu, toolbox, or regular.

	;Check if the item is up or down. If down, draw the highlight.
	;First update the highlight
	;	bl = OLBI_moreAttrs
	;	bh = OLBI_specState (low byte)
	;	cl = OLBI_optFlags
	;	dh = OLII_state

	mov	bp, bx			;bp (high) = OLBI_specState (low byte)
	push	ds, si, dx, cx		;Save instance ptr

if _JEDIMOTIF	;-------------------------------------------------------------
	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	OpenGetLineBounds
	push	cx, dx
	sub	cx, ax			;cx, dx = width, height
	inc	cx
	sub	dx, bx
	inc	dx
	push	ds, si
	segmov	ds, cs, si
	mov	si, offset plainItemRegion
FXIP <	push	cx							>
FXIP <	mov	cx, PLAIN_ITEM_REGION_SIZE				>
FXIP <	call	SysCopyToStackDSSI					>
FXIP <	pop	cx							>
	call	GrDrawRegion
FXIP <	call	SysRemoveFromStack					>
	pop	ds, si
	pop	cx, dx
else	;--------------------------------------------------------------------
	call	OpenGetLineBounds
if DRAW_ITEM_BORDERS
if ALLOW_TAB_ITEMS and BW_TAB_ITEMS
	call	OLItemDrawBWTabBorder	;Draw the BW tab frame
	jnc	noTab

	pop	ds, si, dx, cx
	mov	ax, C_BLACK
	call	GrSetTextColor
	jmp	tabDrawn
noTab:
endif
	call	GrDrawRect		;Draw the item frame
endif
endif	;--------------------------------------------------------------------
	call	ItemDrawBWItemHighlight	;Draw/clear the highlight
	pop	ds, si, dx, cx		;Get instance ptr

	;Set the area color to be used by monochrome bitmap monikers

;	mov	ax, C_BW_GREY		;Use 50% pattern if disabled
	call	OLItemSetAreaColorBlackIfEnabledOrInverting
					
if	INVERT_ENTIRE_BW_ITEM_IMAGE and not _RUDY
	call	GrSetTextColor		;have text match area color
endif

if DRAW_ITEM_BORDERS and ALLOW_TAB_ITEMS and BW_TAB_ITEMS
tabDrawn:
endif
					;set AreaColor C_BLACK or dark color.

	;Left justify if in menu, otherwise center.  If we're in a toolbox
	;use small margins. (pass cl = OLBI_optFlags so knows whether
	;cursored emphasis is going away.)

	mov	al, cl			;pass al = OLBI_optFlags
	call	OLButtonSetupMonikerAttrs
					;pass info indicating which accessories
					;to draw with moniker
					;returns cx = info.
					;does not trash ax, dx, di

if _KBD_NAVIGATION	;------------------------------------------------------
;In OpenLook: may want to prevent this if is standard item in menu (not CB)

					;pass al = OLBI_optFlags
	call	OLButtonTestForCursored	;in Resident resource

	test	bx, mask OLBSS_CURSORED
	;
	; Avoid reinverting the no-longer-to-be-drawn selection cursor in full
	; invert mode -- the thing is already been redrawn.  -cbh 2/20/93
	; (Changed to be done in either mode -- the inset rect obliterates the
	; old rectangle as well.)
	;
	jnz	85$			;skip if cursored...
	andnf	cx, not mask OLMA_DISP_SELECTION_CURSOR
85$:	

	;if selection cursor is on this object, and is a checkbox, have the
	;dotted line drawn inside the bounds of the object.  

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	86$			;skip if not...

	ornf	cx, mask OLMA_USE_CHECKBOX_SELECTION_CURSOR

	;Invert the image to draw it in this full-invert mode.  -cbh 2/19/93
	;(No, do it in all modes. -cbh 2/22/93)

	ornf	cx, mask OLMA_USE_TOOLBOX_SELECTION_CURSOR

86$:
endif 			;------------------------------------------------------

	mov	ah, dh			;set ah = OLII_state

if _RUDY
	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST)
else
	mov	al, (J_CENTER shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
endif

OLS <	mov	dx, (BUTTON_INSET_Y shl 8) or BUTTON_INSET_X	>
OLS <	test	ah, mask OLIS_DRAW_AS_TOOLBOX			>
OLS <	jz	90$						>

	mov	dx, (BW_TOOLBOX_INSET_Y shl 8) or BW_TOOLBOX_INSET_X

90$:
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU
	jz	95$			;not in menu, branch

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST) 

95$:	;pass al = DrawMonikerFlags, cx = OLMonikerAttrs

if _RUDY
	call	OLItemInsetIfCenteredBoolean

	ornf	cx, mask OLMA_DRAW_SHORTCUT_TO_RIGHT
endif
	call	OLButtonDrawMoniker	;draw moniker and accessories

if _RUDY
	pop	di			;restore gstate
	push	di

	;
	; The ability to draw a cursor frame was gutted in Rudy.
	; Rather than try to re-enable it just for non-exlusive list
	; items, we'll draw our own custom frame.
	;
	call	RudyDrawItemFrameIfNotBoolean

	;
	; Now draw yes/no mark and right arrow.
	;
	call	OLItemDrawYesNoIfBoolean
endif

done:

if _RUDY
	pop	di				;restore gstate
endif

endif ;not _REDMOTIF ;------------------- Not needed for Redwood project
	ret
ItemDrawBWItem	endp

endif	; not _PCV

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudyDrawItemFrameIfNotBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a focus frame around an item, if needed.

CALLED BY:	ItemDrawBWItem
PASS:		*ds:si
		di	= gstate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	The following combinations of attributes get cursored

	behavior exclBehav CURSORED DRAW_STATE_KNOWN always_focused focusItem?
	-------- --------- -------- ---------------- -------------- ----------
	nonexcl  false     yes      yes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	10/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RudyDrawItemFrameIfNotBoolean	proc	near
	uses	ax,bx,cx,dx,es
	.enter

	call	CheckIfBoolean
	jc	reallyDone

	push	di

	;
	; If exclusive, no cursoring, period.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLII_behavior, GIGBT_EXCLUSIVE
	je	done

	;
	; If not set cursored, don't draw.
	;
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jz	done

	push	si
	call	VisSwapLockParent
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; If acting like an exclusive, no draw.
	;
	tst	ds:[di].OLIGI_exclusiveBehavior
	lahf

	call	ObjSwapUnlock
	pop	si

	sahf					; ax.z <- result of test
	jnz	done
draw:
	pop	di
	push	di
	call	OpenGetLineBounds	
	call	GrDrawRect
done:
	pop	di

reallyDone:
	.leave
	ret
RudyDrawItemFrameIfNotBoolean	endp

endif ; _RUDY


if ALLOW_TAB_ITEMS and BW_TAB_ITEMS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemDrawBWTabBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the border of the folder tab.  The tab can be
		one of three different styles:  top, left, or right.
		The tab is either selected or deselected, giving a
		total of 6 different tab types to draw.

CALLED BY:	ItemDrawBWItem
PASS:		ax, bx, cx, dx	= bounds for item border
		*ds:si		= item object
RETURN:		carry set if item is a tab, in which case it was drawn
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	9/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLItemDrawBWTabBorder	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; Check if it's a tab
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLII_extraRecord
	test	al, mask OLIER_TAB_STYLE
	jnz	drawTab
	clc
	pop	di
done:
	.leave
	ret
drawTab:
	clr	ah
	andnf	al, mask OLIER_TAB_STYLE

	Assert	etype	al, OLItemTabStyle
	;
	; It's a tab, draw the correct region, depending upon
	; orientation and selection
	;
	test	ds:[di].OLBI_specState, mask OLBSS_SELECTED
	jz	notSelected

	add	al, NUM_TAB_STYLES

notSelected:
	shl	al, 1			; word-sized table entries
	mov	bp, ax			; bp = table index
	pop	di			; di = gstate

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	call	VisGetBounds		; ax, bx, cx, dx = bounds
	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax
	call	GrFillRect		; clear the area
	sub	cx, ax			; cx = width
	sub	dx, bx			; dx = height

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	segmov	ds, cs
	mov	si, cs:[folderTabRegionTable][bp]	; ds:si = region
	call	GrDrawRegion		

	stc				; signal already drawn
	jmp	done
OLItemDrawBWTabBorder	endp


folderTabRegionTable	word\
		0,				; dummy
		offset	TopTabRegion,		; top-rounded/NOT selected
		offset	LeftTabRegion,		; left-rounded/NOT selected
		offset	RightTabRegion,		; right-rounded/NOT selected
		offset	TopSelectedTabRegion,	; top-rounded/selected
		offset	LeftSelectedTabRegion,	; left-rounded/selected
		offset	RightSelectedTabRegion 	; right-rounded/selected

TopTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,						EOREGREC
	word	1,		6, PARAM_2-7,			EOREGREC
	word	2,		4, 5, PARAM_2-6, PARAM_2-5,	EOREGREC
	word	3,		3, 3, PARAM_2-4, PARAM_2-4,	EOREGREC
	word	5,		2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	PARAM_3-2,	1, 1, PARAM_2-2, PARAM_2-2, 	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

TopSelectedTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-6,			EOREGREC
	word	1,		3, 4, PARAM_2-6, PARAM_2-4,	EOREGREC
	word	2,		2, 2, PARAM_2-4, PARAM_2-3,	EOREGREC
	word	4,		1, 1, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	PARAM_3-1,	0, 0, PARAM_2-2, PARAM_2-1,	EOREGREC
	word	EOREGREC

LeftTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		PARAM_2-1, PARAM_2-1,		EOREGREC
	word	1,		6, PARAM_2-1,			EOREGREC
	word	2,		4, 5, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	3,		3, 3, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	5,		2, 2, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-6,	1, 1, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-5,	2, 2, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	3, 3, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-3,	4, 5, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	6, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	EOREGREC

LeftSelectedTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		5, PARAM_2-1,			EOREGREC
	word	1,		3, 4,				EOREGREC
	word	2,		2, 2,				EOREGREC
	word	4,		1, 1,				EOREGREC
	word	PARAM_3-6,	0, 0,				EOREGREC
	word	PARAM_3-5,	0, 1,			 	EOREGREC
	word	PARAM_3-4,	1, 1,				EOREGREC
	word	PARAM_3-3,	1, 2,				EOREGREC
	word	PARAM_3-2,	2, PARAM_2-1,			EOREGREC
	word	PARAM_3-1,	4, PARAM_2-1,			EOREGREC
	word	EOREGREC

RightTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, 0,				EOREGREC
	word	1,		0, PARAM_2-7,			EOREGREC
	word	2,		0, 0, PARAM_2-6, PARAM_2-5,	EOREGREC
	word	3,		0, 0, PARAM_2-4, PARAM_2-4,	EOREGREC
	word	4,		0, 0, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	PARAM_3-6,	0, 0, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-5,	0, 0, PARAM_2-3, PARAM_2-3, 	EOREGREC
	word	PARAM_3-4,	0, 0, PARAM_2-4, PARAM_2-4,	EOREGREC
	word	PARAM_3-3,	0, 0, PARAM_2-6, PARAM_2-5,	EOREGREC
	word	PARAM_3-2,	0, PARAM_2-7,			EOREGREC
	word	PARAM_3-1,	0, 0,				EOREGREC
	word	EOREGREC

RightSelectedTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		0, PARAM_2-6,			EOREGREC
	word	1,		PARAM_2-5, PARAM_2-4,		EOREGREC
	word	2,		PARAM_2-3, PARAM_2-3,		EOREGREC
	word	4,		PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-6,	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-5,	PARAM_2-2, PARAM_2-1,	 	EOREGREC
	word	PARAM_3-4,	PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-3,	PARAM_2-3, PARAM_2-2,		EOREGREC
	word	PARAM_3-2,	0, PARAM_2-3,			EOREGREC
	word	PARAM_3-1,	0, PARAM_2-5,			EOREGREC
	word	EOREGREC

endif ;ALLOW_TAB_ITEMS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemInsetIfCenteredBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insets moniker if a center-by-monikers boolean.

CALLED BY:	ItemDrawBWItem

PASS:		*ds:si	= instance data for object
		di	= GState
		al	= DrawMonikerFlags (justification, clipping)
		cx	= OLMonikerAttributes (window mark, cursored)
		dl	= X inset amount
		dh	= Y inset amount

RETURN:		dl	adjusted, if needed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We'll take the parent's calculated width (if centering by monikers),
	and subtract off our moniker size to get the offset to draw the 
	moniker.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/24/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

OLItemInsetIfCenteredBoolean	proc	near		uses	ax
	.enter
	call	GetParentMonikerSpace
	tst	ax				;not centering by monikers, done
	jz	exit

	push	ax, cx, dx, di			;save passed args	
	sub	sp, size OpenMonikerArgs
	mov	bp, sp				;set up args on stack
	call	OLItemSetupMkrArgs		;set up arguments for moniker
	call	OpenGetMonikerSize		;get size of moniker
EC <	call	ECVerifyOpenMonikerArgs		;make structure still ok >

	mov	bp, cx				;keep width in bp

	add	bp, CHECK_MAGIC_EXTRA_SPACE + CHECK_LEFT_BORDER + \
					      CHECK_RIGHT_BORDER 

	add	sp, size OpenMonikerArgs	;dump args
	pop	ax, cx, dx, di

	sub	ax, bp				;subtract mkr width from overall
						;   fixed width.
	tst	ax				;went negative, exit
	js	exit

	tst	ah				
	jnz	largest				;do our best

	add	dl, al				;add to passed inset
	jnc	exit

largest:
	mov	dl, -1				;maxed out, do the best we can
exit:
	.leave
	ret
OLItemInsetIfCenteredBoolean	endp

endif

if _JEDIMOTIF
plainItemRegion	label	word
;simple rounded border
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	-1,						EOREGREC ;jedi
	word	0,		1, PARAM_2-2,			EOREGREC ;jedi
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC ;jedi
	word	PARAM_3-1,	1, PARAM_2-2,			EOREGREC ;jedi
	word	EOREGREC						 ;jedi
PLAIN_ITEM_REGION_SIZE = $-(offset plainItemRegion)
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLItemDrawYesNoIfBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws "Yes" or "No" if we're a boolean.

CALLED BY:	ItemDrawBWItem

PASS:		*ds:si -- item

RETURN:		nothing

DESTROYED:	everything, including es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 9/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if _RUDY

OLItemDrawYesNoIfBoolean	proc	near
	.enter
	call	CheckIfBoolean		;not a boolean, branch
	jnc	exit

	;
	; First, draw a right arrow.
	;
	mov	cx, (ITEM_RIGHT_MARK_Y_OFFSET shl 8) or ITEM_RIGHT_MARK_X_OFFSET
	;
	; All drawing from here out will be relative to curpos
	;
	call	GrGetCurPos			; ax,bx <- curpos

	call	RudyDrawRightArrow

	add	ax, ITEM_RIGHT_MARK_X_OFFSET + RUDY_RIGHT_MARK_WIDTH + MO_CONTROL_MKR_X_SPACING
	mov_tr	cx, ax
						  ;add room for right mark

	mov	bp, di				;keep gstate here

	mov	bx, handle StandardMonikers
	push	bx				
	push	ds:[LMBH_handle]		;save item's block
	call	ObjLockObjBlock			;ax <- StandardMonikers block

	mov	es, ax	
	pop	bx
	call	MemDerefDS			;dereference object's block

	;
	; Indeterminate use nothing, selected use "Yes", not selected use "No".
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLII_state, mask OLIS_INDETERMINATE
	jnz	doNothing

	mov	bx, offset StandardOnMoniker
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLII_state, mask OLIS_SELECTED
	jnz	drawIt				;selected, branch
	mov	bx, offset StandardOffMoniker

drawIt:
	sub	cx, ds:[di].VI_bounds.R_left
	sub	sp, size DrawMonikerArgs
	mov	di, bp				;gstate
	mov	bp, sp
	mov	ax, cx				;left-of-center
	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST)
	mov	ss:[bp].DMA_xInset, ax		;left of center
	clr	ss:[bp].DMA_yInset
	mov	ss:[bp].DMA_gState, di		
	clr	ss:[bp].DMA_textHeight

	call	VisDrawMoniker
	add	sp, size DrawMonikerArgs

doNothing:
	pop	bx				;all done
	call	MemUnlock

exit:
	.leave
	ret
OLItemDrawYesNoIfBoolean	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWItemHighlight

SYNOPSIS:	Either draws or clears the inner highlighting rectangle.

PASS:		*ds:si	- instance data of the item
		ax, bx, cx, dx - bounds of the item
		bp (high byte) - OLBI_specState (low byte)
		di	- GState to use

RETURN:		di	- preserved

DESTROYED:	ax, bx, cx, dx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _REDMOTIF

if (not _RUDY) and (not _PCV)

ItemDrawBWItemHighlight	proc	near
	uses	ax, bx, cx, dx
	.enter

	push	ax
	mov	ax, C_WHITE		;Assume no highlight

if FOCUSED_GADGETS_ARE_INVERTED
	test	bp, (mask OLBSS_CURSORED) shl 8
else
	test	bp, (mask OLBSS_SELECTED) shl 8
endif
	jz	60$
	mov	ax, C_BLACK
60$:

if	INVERT_ENTIRE_BW_ITEM_IMAGE
	call	GrSetAreaColor
else
	call	GrSetLineColor
endif
	pop	ax
	;
	; move in one pixel from the bounds
	;
	inc	ax			;Move in to the highlight bounds
	inc	bx
	dec	cx
	dec	dx

if	INVERT_ENTIRE_BW_ITEM_IMAGE
	inc	cx			;Get out to fill params
	inc	dx
	call	GrFillRect
	dec	cx			;Reset these
	dec	dx
else
	call	GrDrawRect		; Draw/erase the highlight
endif

	mov	ax, C_BLACK		; Reset to using solid black
	call	GrSetLineColor

	.leave
	ret
ItemDrawBWItemHighlight	endp


elseif (not _PCV)	;_RUDY

ItemDrawBWItemHighlight	proc	near
	uses	ax, bx, cx, dx
	.enter

	push	ax
	mov	ax, C_WHITE		;Assume no highlight

if _RUDY
	; non-exclusive lists
	; always show what is
	; selected
	;
	call	CheckIfExtendingOrNonExcl
	jz	checkSelected
endif ; _RUDY

	call	OLItemCheckIfAlwaysDrawsFocused
	jc	checkSelected		;check selected state if so

	test	bp, (mask OLBSS_CURSORED) shl 8	
					;for other cases check cursored state.
	jz	setColor
	jmp 	short selected

checkSelected:
	test	bp, (mask OLBSS_SELECTED) shl 8
	jz	setColor
selected:
	mov	ax, SELECTED_TEXT_BACKGROUND
setColor:
	call	GrSetAreaColor
	pop	ax

if not _RUDY ; On Rudy, this is slightly inconsistent with the way OLCtrls draw
	;
	; move in one pixel from the bounds
	;
	inc	ax			;Move in to the highlight bounds
	inc	bx
		
		;The moniker size returned from GrTextWidth is correct
		;but by subtracting off these extra pixels, we go too far.
		; --JimG 8/11/95
  ;	dec	cx			;Don't do this unless we do the
					; funky subtraction because on some
					; item monikers, this draws one pixel
					; too short on the right.
	dec	dx
endif ; not _RUDY

if _RUDY
	;
	; Booleans in properties boxes, only invert the left-of-center areas.
	;
	call	CheckIfBoolean		;not a boolean, branch
	jnc	noWeirdSubtraction

;	dec	cx			;The dec from above moved here.

	push	cx
	push	bx, dx, bp
	push	ax
	mov	ax, MSG_VIS_GET_CENTER
	call	ObjCallInstanceNoLock		  ;cx <- left-of-center space

	sub	cx, CHECK_MAGIC_EXTRA_SPACE + CHECK_LEFT_BORDER + \
					      CHECK_RIGHT_BORDER 
	pop	ax
	add	cx, ax				  ;get relative to left edge
	pop	bx, dx, bp
	call	fillIndented			  ;draw it

	;
	; Do the right-of-center in white, and let's avoid the right arrow.
	;
	mov	ax, C_WHITE			  ;do right-of-center in white
	call	GrSetAreaColor

	mov	ax, cx				  
	pop	cx

noWeirdSubtraction:

endif

if	INVERT_ENTIRE_BW_ITEM_IMAGE
	call	fillIndented
else
	call	GrDrawRect		; Draw/erase the highlight
endif

	mov	ax, C_BLACK		; Reset to using solid black
	call	GrSetLineColor

	.leave
	ret


fillIndented	label	near
	inc	cx			;Get out to fill params
	inc	dx
	call	GrFillRect
	dec	cx			;Reset these
	dec	dx
	retn

ItemDrawBWItemHighlight	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWRadioButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a radio button.

CALLED BY:	ItemDrawBWItem (is JUMPED to)

PASS:		*ds:si -- instance data
		al = flags which have changed
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		bl = OLII_state
		dl = GI_states
		dh = OLII_state

		al = flags which have changed
		ch = TRUE if full redraw is requested

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/4/90		Initial version
	Eric	3/90		cleanup
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA_STYLE	;--------------------------------------------------------------

ItemDrawBWRadioButton	proc	far
	class	OLItemClass

if _PM	; We draw a simple check mark if the item is in a menu ----------------
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	notInMenu

	call	ItemDrawPMCheck

	test	al, mask OLBSS_BORDERED
	jz	drawMoniker		;skip if not...

	call	ItemDrawBWMotifItemBorderIfInMenu
	jmp	drawMoniker
notInMenu:
endif	; _PM -----------------------------------------------------------------

	tst	ch			;is this a full redraw?
	jnz	fullRedraw		;skip if so...

	;
	; Only part needs to be redrawn.
	;
	call	ItemDrawBWRadioButtonPartial

updateCursored:
	;if the CURSORED state has changed, update the selection cursor
	;image (future optimization: it is possible to call OpenDrawMoniker,
	;passing flags so that just the selection cursor is drawn.)
	;(pass cl = OLBI_optFlags, so OLButtonSetupMonikerDrawFlags knows
	;whether to draw or erase cursor)

	test	al, mask OLBSS_CURSORED
	jnz	drawMoniker		;skip if changed...
	jmp	done			;skip (long) to end if no change...

fullRedraw:
	push	si, ds, dx
	
if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Stylus: Draw the depressed background, if necessary.
	;
	clr	ah			; redraw depressed background
	call	ItemDrawBWItemDepressedIfInMenu

endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	
if not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Motif: draw the border if necessary
	;
	; Not done if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED because we don't
	; care about bordered we are going to inverse the button.
	;

MO <	call	ItemDrawBWMotifItemBorderIfInMenu			>
PMAN <	call	ItemDrawBWMotifItemBorderIfInMenu			>

endif	;not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	;
	; Draw the button.
	;
	call	ItemDrawBWRadioButtonButton
	pop	si, ds, dx

	clr	cl		;pass flag to OLButtonSetupMonikerDrawFlags:
				;if not cursored, no need to erase cursor image
drawMoniker:
	;
	; Draw the item moniker.
	;
if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	ItemBWForegroundColorIfDepressedIfInMenu
	call	GrSetAreaColor	
	call	GrSetLineColor
	call	GrSetTextColor

else	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	OLItemSetAreaColorBlackIfEnabled

	;
	; Needed for mnemonics. -cbh 3/ 9/93
	;
	mov	ax, C_BLACK
	call	GrSetLineColor		; for mnemonics			

endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	mov	al, cl		;pass OLBI_optFlags or 0
	push	bx
	call	OLButtonSetupMonikerAttrs
	pop	bx			;pass info indicating which accessories
					;to draw with moniker
					;returns cx = info.

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
	;
	; Since this moniker is going to be left justified and centered
	; vertically, we only need to worry about left inset.
	;
	mov	dx, MO_ITEM_INSET_LEFT
	call	OLButtonDrawMoniker
done:
	ret
ItemDrawBWRadioButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWRadioButtonPartial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a radio button item in part.

CALLED BY:	ItemDrawBWRadioButton

PASS:		*ds:si -- instance data
		al = flags which have changed
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		bl = OLII_state
		dl = GI_states
		dh = OLII_state

		al = flags which have changed
		ch = TRUE if full redraw is requested

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the DOT image according to the new SELECTED state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/95		Pulled from ItemDrawBWRadioButton

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawBWRadioButtonPartial	proc	near
	.enter

if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED	;--------------------------------------

	;
	; Check if DEPRESSED state changed.
	;
	test	al, mask OLBSS_DEPRESSED
	jz	updateSelected		;skip if not
	
	mov	ah, TRUE		;update depressed background
	call	ItemDrawBWItemDepressedIfInMenu

endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED --------------------------------

updateSelected:
	push	ds, si, cx, ax, bx
	mov	ax, C_BLACK

if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	; If item selection is indicated by depression (which is represented
	; by reverse video), then the radio button should be drawn black
	; ONLY IF (SELECTED xor DEPRESSED) is true.
	
	
	mov	ch, bh			; move specState (low byte) into ch
	
    	; ensure that the shift operand is positive
CheckHack <((offset OLBSS_SELECTED) - (offset OLBSS_DEPRESSED)) gt 0>
    
	; shift the depressed bit over into the selected bit position
    	mov	cl, (offset OLBSS_SELECTED) - (offset OLBSS_DEPRESSED)
	shl	ch, cl
	
	xor	ch, bh
	
	; ch and OLBSS_SELECTED == OLBSS_DEPRESSED xor OLBSS_SELECTED
	test	ch, mask OLBSS_SELECTED

else	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED is FALSE

	; Otherwise, just simply check if the item is selected.
	test	bh, mask OLBSS_SELECTED	;is item selected?
	
endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	jnz	60$			;skip if so...

	mov	ax, C_WHITE
60$:
	call	GrSetAreaColor
	call	OpenGetLineBounds

MO <	inc	ax			;move over 1 pixel, so selection >
					;cursor does not eat it
PMAN <	inc	ax			;move over 1 pixel, so selection >
					;cursor does not eat it
if _JEDIMOTIF		
	;
	; Jedi -- don't draw radio button if in menu; draw dot.
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jnz	drawDot
	;
	;  Draw radio button bitmap.
	;
	mov	si, offset itemRadioInBM
	call	ItemDrawBWRadioButtonBitmap
	jmp	doneDraw
drawDot:
	call	ItemDrawJediDot
doneDraw:
else
	mov	si, offset itemRadioInBM
	call	ItemDrawBWRadioButtonBitmap
endif
	pop	ds, si, cx, ax, bx

if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if _MOTIF or _PM	;------------------------------------------------------

updateBordered:
	;Motif/PM: if in menu, then BORDERED flag might be set.
	;see if BORDERED state changed.

	test	al, mask OLBSS_BORDERED
	jz	done			;skip if not...

	call	ItemDrawBWMotifItemBorderIfInMenu	; draw or erase border

done:
endif	; _MOTIF or _PM
endif	;not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	.leave
	ret
ItemDrawBWRadioButtonPartial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWRadioButtonButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the actual button part.

CALLED BY:	ItemDrawBWRadioButton

PASS:		*ds:si -- instance data
		al = flags which have changed
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		bl = OLII_state
		dl = GI_states
		dh = OLII_state

		al = flags which have changed
		ch = TRUE if full redraw is requested

RETURN:		nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/95		Pulled out of ItemDrawBWRadioButton

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawBWRadioButtonButton	proc	near
	.enter

if _JEDIMOTIF	; We draw a simple dot if the item is in a menu ---------------
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	notInMenu

	call	ItemDrawJediDot

	jmp	done
notInMenu:
endif	; _JEDIMOTIF -----------------------------------------------------------

	test	bh, mask OLBSS_SELECTED		; is item selected?
	pushf

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	call	ItemBWForegroundColorIfDepressedIfInMenu ; select drawing color
else	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED is FALSE
	mov	ax, C_BLACK
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	GrSetAreaColor
	call	OpenGetLineBounds

MO <	inc	ax			;move over 1 pixel, so selection >
					;cursor does not eat it
PMAN <	inc	ax			;move over 1 pixel, so selection >
					;cursor does not eat it

	push	si
	mov	si, dx				; center the radio button
	sub	si, bx				; by subtracting top from bottom
if _MOTIF					; and subtracting button height
	sub	si, DIAMOND_HEIGHT-1
else
	sub	si, RADIO_HEIGHT-1
endif	; _MOTIF

	shr	si, 1				; and dividing by 2
	add	bx, si				; add to top edge
	clr	dx
	pop	si

;commented out so outline *does* draw when unselected - brianc 6/3/93
;MO <	call	OLItemIsInMenu		;Don't draw outline if B/W menu  >
	
FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>

;MO <	jnz	noOutline		;  -cbh 3/ 8/93			 >

	;
	; Since the bitmap consists of some 1-pixel wide lines, it
	; might not draw at all on mono systems if we draw it with a
	; 50% mask.  Therefore, set the mask to 100% temporarily.  
	;
	push	ax
	mov	al, GMT_ENUM
	call	GrGetAreaMask
	clr	ah
	mov_tr	bp, ax			; save old mask

	cmp	bp, SDM_100
	je	afterSet
	mov	al, SDM_100
	call	GrSetAreaMask
afterSet:

	pop	ax

	mov	si, offset itemRadioOutBM
	call	GrFillBitmap

	;
	; restore original mask, unless it was SDM_100.
	;
	cmp	bp, SDM_100
	je	noOutline

	push	ax
	mov_tr	ax, bp
	call	GrSetAreaMask
	pop	ax

noOutline:
	popf
	jz	80$			;skip if not...

	mov	si, offset itemRadioInBM
	call	GrFillBitmap

80$:	;Set the area color to be used by monochrome bitmap monikers

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

done:
	.leave
	ret
ItemDrawBWRadioButtonButton	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWRadioButtonBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a radio button bitmap.

CALLED BY:	ItemDrawBWItem

PASS:		si = offset of bitmap to draw.
		ax = left
		bx = top
		dx = bottom

RETURN:		nothing

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/4/90		Initial version
	Eric	3/90		cleanup
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ItemDrawBWRadioButtonBitmap	proc	near
	push	si
	mov	si, dx				; center the radio button
	sub	si, bx				; by subtracting top from bottom

if _MOTIF					; and subtracting button height
	sub	si, DIAMOND_HEIGHT-1
else
	sub	si, RADIO_HEIGHT-1
endif	; _MOTIF

	shr	si, 1				; and dividing by 2
	add	bx, si				; add to top edge
	
FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	clr	dx
	pop	si
	call	GrFillBitmap

FXIP <	push	bx							>	
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	ret
ItemDrawBWRadioButtonBitmap	endp

;Bitmap to use when checkmark item set

if _FXIP		; bitmaps in separate resource for xip
DrawBW	ends
DrawBWRegions	segment resource
endif


if	_MOTIF

if _JEDIMOTIF
itemRadioOutBM	label	word
	word    11			; width
	word	11                      ; height 
	byte	0, BMF_MONO	        ; compaction, color scheme
	byte	00000000b, 00000000b				  
        byte    00001100b, 00000000b
	byte	00010010b, 00000000b
	byte	00100001b, 00000000b
	byte	01000000b, 10000000b
	byte	01000000b, 10000000b
	byte	00100001b, 00000000b
	byte	00010010b, 00000000b
	byte    00001100b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b		        	    

itemRadioInBM	label   word	    
	word	11     		    
	word	10     		    
	byte	0, BMF_MONO	    
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001000b, 00000000b
	byte    00011100b, 00000000b
	byte	00111110b, 00000000b
	byte	00111110b, 00000000b
	byte	00011100b, 00000000b
	byte	00001000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

else	; else of if _JEDIMOTIF 
;
; PCV uses a round radio button, but smaller than the non-Motif
; round radio button so we can't reuse that bitmap.
;
if _PCV
itemRadioOutBM	label Bitmap
	Bitmap<11, 11, BMC_UNCOMPACTED, BMF_MONO>
	byte	00001110b, 00000000b
	byte	00110001b, 10000000b
	byte	01000000b, 01000000b
	byte	01000000b, 01000000b
	byte	10000000b, 00100000b
	byte	10000000b, 00100000b
	byte	10000000b, 00100000b
	byte	01000000b, 01000000b
	byte	01000000b, 01000000b
	byte	00110001b, 10000000b
	byte	00001110b, 00000000b

itemRadioInBM	label Bitmap
	Bitmap<11, 11, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001110b, 00000000b
	byte	00010011b, 00000000b
	byte	00010111b, 00000000b
	byte	00011111b, 00000000b
	byte	00001110b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

else	; else of if _PCV

itemRadioOutBM	label	word	    
	word	11		    
	word	11		    
	byte	0, BMF_MONO	    
	byte	00000100b, 00000000b
	byte	00001010b, 00000000b
	byte	00010001b, 00000000b
	byte	00100000b, 10000000b
	byte	01000000b, 01000000b
	byte	10000000b, 00100000b
	byte	01000000b, 01000000b
	byte	00100000b, 10000000b
	byte	00010001b, 00000000b
	byte	00001010b, 00000000b
	byte	00000100b, 00000000b

itemRadioInBM	label	word
	word	11
	word	11
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000100b, 00000000b
	byte	00001110b, 00000000b
	byte	00011111b, 00000000b
	byte	00111111b, 10000000b
	byte	01111111b, 11000000b
	byte	00111111b, 10000000b
	byte	00011111b, 00000000b
	byte	00001110b, 00000000b
	byte	00000100b, 00000000b
	byte	00000000b, 00000000b
endif	; endif of else of if _PCV
endif	; endif of else of if _JEDIMOTIF
		       		    
else	; else of if _MOTIF

itemRadioOutBM	label	word
	word	RADIO_WIDTH
	word	RADIO_HEIGHT
	byte	0, BMF_MONO
	byte	00001110b, 00000000b
	byte	00110001b, 10000000b
	byte	01000000b, 01000000b
	byte	10000000b, 00100000b
	byte	10000000b, 00100000b
	byte	10000000b, 00100000b
	byte	10000000b, 00100000b
	byte	01000000b, 01000000b
	byte	00110001b, 10000000b
	byte	00001110b, 00000000b

itemRadioInBM	label	word
	word	RADIO_WIDTH
	word	RADIO_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001110b, 00000000b
	byte	00011111b, 00000000b
	byte	00111111b, 10000000b
	byte	00111111b, 10000000b
	byte	00011111b, 00000000b
	byte	00001110b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
endif	; endif of else of if _MOTIF

if _FXIP		; bitmaps in separate resource for xip
DrawBWRegions	ends		
DrawBW	segment resource
endif

endif		;CUA STYLE -----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWNonExclusiveItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a non-exclusive item.

CALLED BY:	ItemDrawBWItem (is JUMPED to)

PASS:		*ds:si -- instance data
		al = flags which have changed
		bl = OLII_state
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is requested
		dl = GI_states
		dh = OLII_state

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawBWNonExclusiveItem	proc	far
	class	OLItemClass

if _PM	; We draw a simple checkmark if the item is in a menu -----------------
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	notInMenu

	call	ItemDrawPMCheck

	test	al, mask OLBSS_BORDERED
	LONG	jz	drawMoniker		;skip if not...

	call	ItemDrawBWMotifItemBorderIfInMenu
	jmp	drawMoniker
notInMenu:
endif	; _PM -----------------------------------------------------------------

if _CUA_STYLE	;--------------------------------------------------------------
	;
	; Motif, CUA: some optimizations are possible, because the
	; checkmark or X-mark can be redrawn in black or white to flip
	; its state. In OpenLook, a full redraw is required because the 
	; checkmark is a two-color bitmap.
	;
	tst	ch			; is this a full redraw?
	jnz	fullRedraw		; skip if so...

	call	ItemDrawBWNonExclusiveItemPartial

updateCursored::
	;
	; if the CURSORED state has changed, update the selection cursor
	; image (future optimization: it is possible to call OpenDrawMoniker,
	; passing flags so that just the selection cursor is drawn.)
	; (pass cl = OLBI_optFlags, so OLButtonSetupMonikerDrawFlags knows
	; whether to draw or erase cursor)
	;
	test	al, mask OLBSS_CURSORED
	jnz	drawMoniker			; skip if changed
	jmp	done				; skip to end if no change

fullRedraw:
endif	; _CUA_STYLE ----------------------------------------------------------

;-----------------------------------------------------------------------------
;		MSG_META_EXPOSED:  draw whole item
;-----------------------------------------------------------------------------

	;
	; Draw the checkbox and border (if any).
	;
	call	ItemDrawNonExclusiveCheckbox

	;
	;  Set the area color to be used by monochrome bitmap monikers.
	;  pass flag to OLButtonSetupMonikerDrawFlags:
	;  if not cursored, no need to erase cursor image.
	;
	clr	cl

drawMoniker:

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	ItemBWForegroundColorIfDepressedIfInMenu
	call	GrSetAreaColor	
	call	GrSetLineColor
	call	GrSetTextColor

else	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	call	OLItemSetAreaColorBlackIfEnabled
					;set AreaColor C_BLACK or dark color.
	;
	; Needed for mnemonics. -cbh 3/ 9/93
	;
	mov	ax, C_BLACK
	call	GrSetLineColor		;for mnemonics			

endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	mov	al, cl		;pass OLBI_optFlags or 0
	push	bx
	call	OLButtonSetupMonikerAttrs
	pop	bx			;pass info indicating which accessories
					;to draw with moniker
					;returns cx = info.

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)

OLS <	clr	dx			; dl=xoffset, dh=yoffset	>
CUAS <	mov	dx, CHECK_BOX_WIDTH

					;pass al = DrawMonikerFlags,
					;cx = OLMonikerAttrs
	call	OLButtonDrawMoniker	;draw moniker, using OpenDrawMoniker
					;so that accessories can be drawn.
done:
	ret
ItemDrawBWNonExclusiveItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWNonExclusiveItemPartial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a partial redraw of a nonexclusive item.

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		*ds:si -- instance data
		al = flags which have changed
		bl = OLII_state
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is requested
		dl = GI_states
		dh = OLII_state

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

	 If the CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have 
	 changed; update the image according to the new SELECTED state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/95		Pulled out of ItemDrawBWNonExclusiveItem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA_STYLE	;--------------------------------------------------------------

ItemDrawBWNonExclusiveItemPartial	proc	near
	.enter

updateDepressed::
	;
	; First: update DEPRESSED state
	;
	test	al, mask OLBSS_DEPRESSED	; has depressed state changed?
	jz	updateSelected			; skip if not...

	;
	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, then 
	; depressed is indicated by a reversed background, not a 
	; highlighted mark (if in a menu - if not in a menu, depressed
	; is not indicated).
	;
if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	mov	ah, TRUE			; update depressed background
	call	ItemDrawBWItemDepressedIfInMenu

else	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Otherwise, draw the "highlighted" exclusive mark.
	;
	push	ax, bx, cx, dx
	mov	ax, C_BLACK
	test	bh, mask OLBSS_DEPRESSED	; is item depressed?
	jnz	10$				; skip if so...

	mov	ax, C_WHITE

10$:	call	GrSetLineColor
	call	ItemDrawBWNonExclHighlight
	pop	ax, bx, cx, dx

	;
 	; CUA: if the DEPRESSED state just went to FALSE, MUST redraw
	; checkmark because the highlight overlaps the X-mark.
	;
NOT_MO<	test	bh, mask OLBSS_DEPRESSED ;is item depressed?		>
NOT_MO<	jz	doUpdateSelected	 ;skip if not...		>

endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

updateSelected:
	test	al, mask OLBSS_SELECTED		; has selected state changed?
	jz	updateBordered			; skip if not...

doUpdateSelected:
	;
	; Now: update SELECTED state
	;
	push	ax, bx, cx, dx
	mov	ax, C_BLACK
	
if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED ;--------------------------------------
	;
	; If item selection is indicated by depression (which is 
	; represented by reverse video), then the radio button should 
	; be drawn black ONLY IF (SELECTED xor DEPRESSED) is true.
	;
	
	mov	ch, bh			; move specState (low byte) into ch
	
	;
	; ensure that the shift operand is positive
	;
	CheckHack <((offset OLBSS_SELECTED) - (offset OLBSS_DEPRESSED)) gt 0>

	;
	; shift the depressed bit over into the selected bit position
	;
    	mov	cl, (offset OLBSS_SELECTED) - (offset OLBSS_DEPRESSED)
	shl	ch, cl
	
	xor	ch, bh

	;
	; ch and OLBSS_SELECTED == OLBSS_DEPRESSED xor OLBSS_SELECTED
	;
	test	ch, mask OLBSS_SELECTED

else	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Simply check if the item is selected.
	;
	test	bh, mask OLBSS_SELECTED		; is item selected?
	
endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	jnz	drawIt				; skip if so...

	mov	ax, C_WHITE
drawIt:
	call	GrSetAreaColor
	call	GrSetLineColor

if _JEDIMOTIF	;---------------------------------------------------------------
	push	bx
	call	ItemDrawBWXMark
	pop	bx		
	test	bh, mask OLBSS_SELECTED
	jnz	jDoneDraw
	;
	;  If we're not selected, we just erased ourselves,
	;  so draw the outline again.
	;
	mov	ax, C_BLACK
	call	GrSetLineColor
	call	GetCheckboxBounds
	dec	cx
	call	GrDrawRect
jDoneDraw:

else	; not _JEDIMOTIF

if _PCV
	call	ItemDrawBWCheckmarkInBox
else
MO <	call	ItemDrawBWInnerSquareMark				>
endif
PMAN <	call	ItemDrawBWCheckmarkInBox				>
NOT_MO<	call	ItemDrawBWXMark						>

endif	; _JEDIMOTIF ----------------------------------------------------------

	pop	ax, bx, cx, dx

updateBordered:

if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
if _MOTIF or _PM	;------------------------------------------------------
	;
	; Motif: if in menu, then BORDERED flag might be set.
	; see if BORDERED state changed.

	test	al, mask OLBSS_BORDERED
	jz	done				; skip if not...

	;
	;  Draw or erase BORDER according to state.
	;
	call	ItemDrawBWMotifItemBorderIfInMenu

endif 	; _MOTIF or _PM -------------------------------------------------------
endif	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

done:
	.leave
	ret
ItemDrawBWNonExclusiveItemPartial	endp

endif	; _CUA_STYLE ----------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawNonExclusiveCheckbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the checkbox & border for a non-exclusive item.

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		*ds:si -- instance data
		al = flags which have changed
		bl = OLII_state
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is requested
		dl = GI_states
		dh = OLII_state

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/95		Pulled from ItemDrawBWNonExclusiveItem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawNonExclusiveCheckbox	proc	near
	.enter

	push	ax, bx, cx, dx

	;
	; Stylus: Draw the depressed background, if necessary.
	;
if	_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	clr	ah				; redraw depressed background
	call	ItemDrawBWItemDepressedIfInMenu
	call	ItemBWForegroundColorIfDepressedIfInMenu	; choose color

else	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED is FALSE

	mov	ax, C_BLACK

endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	GrSetAreaColor
	call	GrSetLineColor

;commented out so outline *does* draw when unselected - brianc 6/3/93
;MO <	call	OLItemIsInMenu		;no outline in menus (cbh 3/ 8/93) >
;MO <	jnz	noCheckboxOutline					   >

	call	GetCheckboxBounds

if _JEDIMOTIF
	dec	cx			; we're slightly squished on Jedi
endif
	call	GrDrawRect

	;
	;  Draw the border or highlight if necessary.
	;
;MO <noCheckboxOutline:							   >
	pop	ax, bx, cx, dx
	;
	; Motif: draw the border if necessary
	;
if not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Not done if _BW_MENU_ITEM_SELECTION_IS_DEPRESSED because we 
	; don't care about bordered:  we are going to invert the button.
	;
if _MOTIF or _PM
	call	ItemDrawBWMotifItemBorderIfInMenu
endif
endif	;not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	call	ItemBWForegroundColorIfDepressedIfInMenu	; choose color
else
	mov	ax, C_BLACK
endif	; _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

	call	GrSetAreaColor

	;
	; Do not represent depressed with a highlight.
	;
if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	;
	; Draw the highlight.
	;
	test	bh, mask OLBSS_DEPRESSED 	; is item depressed?
	jz	50$				; skip if not...


	push	ax, bx, cx, dx
	call	ItemDrawBWNonExclHighlight
	pop	ax, bx, cx, dx

endif	; not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

50$:
	;
	;  Draw the X or checkmark.
	;
	test	bh, mask OLBSS_SELECTED	;is item selected?
	jz	60$			;skip if not...

	push	ax, bx, cx, dx

if _JEDIMOTIF
	call	ItemDrawBWXMark
else
OLS <	call	ItemDrawBWCheckmarkInBox				>
if _PCV
	call	ItemDrawBWCheckmarkInBox
else
MO <	call	ItemDrawBWInnerSquareMark				>
endif
PMAN <	call	ItemDrawBWCheckmarkInBox				>
NOT_MO<	call	ItemDrawBWXMark						>
endif

	pop	ax, bx, cx, dx

60$:
	.leave
	ret
ItemDrawNonExclusiveCheckbox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWNonExclHighlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the inside highlight for a non-exclusive item.

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		di = gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; Don't need this if represent depressed with reverse video
if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

ItemDrawBWNonExclHighlight	proc	near
	call	GetCheckboxBounds
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrDrawRect

	ret
ItemDrawBWNonExclHighlight	endp

endif	;not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWCheckmarkInBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw the Checkmark for an OpenLook item.

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		di = gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _OL_STYLE	;--------------------------------------------------------------

ItemDrawBWCheckmarkInBox	proc	near
	uses	ds, si
	.enter
		
	call	GetCheckboxBounds
	clr	dx
	inc	ax
	sub	bx, CHECK_TOP_BORDER

	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	mov	si, offset bwCheckOutBM
	call	GrFillBitmap

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	mov	si, offset bwCheckBM
	call	GrFillBitmap
	
FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	.leave
	ret
ItemDrawBWCheckmarkInBox	endp

endif	; _OL_STYLE ----------------------------------------------------------

if _PM or _PCV	;--------------------------------------------------------------

ItemDrawBWCheckmarkInBox	proc	near
	uses	ds, si
	.enter

	call	GetCheckboxBounds

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>	
	
	mov	si, offset checkBM
	call	GrFillBitmap
	
FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	.leave
	ret
ItemDrawBWCheckmarkInBox	endp	

if _FXIP
DrawBW	ends
DrawBWRegions	segment resource
endif

if _PCV
checkBM	label	Bitmap
	Bitmap<10, 7, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 01000000b
	byte	01100001b, 00000000b
	byte	01110011b, 00000000b
	byte	01111110b, 00000000b
	byte	00111100b, 00000000b
	byte	00011000b, 00000000b

else	; else of if _PCV

checkBM	label	word
	word	CHECK_WIDTH
	word	CHECK_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 01110000b
	byte	00000000b, 01100000b
	byte	00000000b, 11100000b
	byte	00000000b, 11000000b
	byte	00000001b, 11000000b
	byte	00111001b, 10000000b
	byte	00011111b, 10000000b
	byte	00001111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
endif	; endif of else of if _PCV

if _FXIP
DrawBWRegions	ends
DrawBW	segment resource
endif

endif	; endif of if _PM or _PCV --------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWInnerSquareMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw the inner square mark in a Motif non-exclusive item

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		di = gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _MOTIF and (not _JEDIMOTIF) and (not _PCV)	;------------------------------

ItemDrawBWInnerSquareMark	proc	near
	call	GetCheckboxBounds
	add	ax, 1		;inset less nowadays.
	add	bx, 1
	sub	cx, 0		;used to be 2, adjusted for new graphics stuff
	sub	dx, 0		;ditto
	call	GrFillRect
	ret
ItemDrawBWInnerSquareMark	endp

endif	; _MOTIF and (not _JEDIMOTIF) and (not _PCV) ;-------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWXMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw the inner X mark in a non-exclusive item.

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		di = gstate

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

ItemDrawBWXMark	proc	near
	uses	si, ds
	.enter

	call	GetCheckboxBounds

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs, si						>	
	
	mov	si, offset JediBWXBM
	call	GrFillBitmap
	
FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	.leave
	ret
ItemDrawBWXMark	endp

if _FXIP
DrawBW	ends
DrawBWRegions	segment resource
endif

JediBWXBM	label	word
	word	CHECK_WIDTH_REAL
	word	CHECK_HEIGHT	    
	byte	0, BMF_MONO 	    
	byte	11111111b, 00000000b
	byte	10011001b, 00000000b
        byte    10000001b, 00000000b
	byte	11000011b, 00000000b
	byte	11100111b, 00000000b
	byte	11000011b, 00000000b
	byte	10000001b, 00000000b
	byte	10011001b, 00000000b
	byte	11111111b, 00000000b

if _FXIP
DrawBWRegions	ends
DrawBW	segment resource
endif

endif	; _JEDIMOTIF ----------------------------------------------------------

if _CUA or _MAC	;--------------------------------------------------------------

ItemDrawBWXMark	proc	near

	call	GetCheckboxBounds
	inc	ax
	inc	bx		; new
	dec	cx
	dec	dx		; new
	call	GrDrawLine
	xchg	bx, dx
	call	GrDrawLine

	ret
ItemDrawBWXMark	endp

endif	; _CUA or _MAC  -------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWMotifItemBorderIfInMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws or erases border around a Motif item (excl or non-excl)
		which is in a menu, according to the BORDERED flag.
		(This flag is set when the item is CURSORED.)

CALLED BY:	ItemDrawBWNonExclusiveItem

PASS:		*ds:si -- instance data
		al = flags which have changed
		bl = OLII_state
			bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is requested
		dl = GI_states
		dh = OLII_state
		di = GState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if     (not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) and (_MOTIF or _PM) ;--------

ItemDrawBWMotifItemBorderIfInMenu	proc	near
	;if this item is inside a menu...

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	done			;skip if not...

	push	ds, ax, bx, cx, dx, bp	;I am a wimp!

	call	OLButtonMovePenCalcSize ;position pen, (cx, dx) = 
					   ;size of button

	;pass bx = OLBI_specState (only tests OLBSS_BORDERED, so only
	;pass lower byte of word value)

	mov	ax, segment idata
	mov	ds, ax			;point to BWButtonRegionSetStruct
					;structure, which points to region
					;definition we can use.
	mov	bp, offset MOBWButtonRegionSet_menuItem

	mov	bl, bh			;set bl = OLBI_specState (low byte)
	call	UpdateBWButtonBorder
	pop	ds, ax, bx, cx, dx, bp
done:
	ret	
ItemDrawBWMotifItemBorderIfInMenu	endp

endif ;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) and (_MOTIF or _PM) ;--------

endif ;not _REDMOTIF ;------------------- Not needed for Redwood project


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemBWForegroundColorIfDepressedIfInMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the foreground color for an item if it is in a menu
		based upon the depressed bit.

CALLED BY:	ItemDrawBWRadioButton, ItemDrawBWNonExclusiveItem
PASS:		*ds:si = item object ptr
RETURN:		ax = color
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED

ItemBWForegroundColorIfDepressedIfInMenu	proc	near
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, C_BLACK
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	done
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED
	jz	done
	mov	ax, C_WHITE
done:	
	.leave
	ret
ItemBWForegroundColorIfDepressedIfInMenu	endp

endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBWItemDepressedIfInMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws/erases or XOR's inverted background around item (both
		excl and non-excl) which is in a menu, according to the
		DEPRESSED flag.

CALLED BY:	ItemDrawBWRadioButton, ItemDrawBWNonExclusiveItem

PASS:		*ds:si	= instance data
		di	= gstate
		ah	= TRUE to Update (XOR), FALSE to ReDraw (COPY)
				background
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
ItemDrawBWItemDepressedIfInMenu	proc	near
	
	push	bp
	
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU
	jz	doReturn			; skip if not in menu
	
	push	ax, bx, cx, dx, si, ds

	; need whole word of data.. only lower byte available in args, so
	; ignore that.
	mov	bx, ds:[bp].OLBI_specState
	
	call	OLButtonMovePenCalcSize		; position pen
						; (cx,dx) = button size
							
	segmov	es, ds, bp			; update requires *es:si=object
	
	mov	bp, segment idata
	mov	ds, bp				; point to BWButtonRegionSetStr
						; structure, which has a region
						; def'n we can use.. in dgroup
	mov	bp, offset MOBWButtonRegionSet_menuItem
	
	tst	ah				; update or redraw
	jz	redrawBackground
	
	; update background
	call	UpdateBWButtonDepressed		; destroys ax, si
	
done:
	pop	ax, bx, cx, dx, si, ds

doReturn:
	pop	bp
	ret
	
redrawBackground:
	; clear background
	mov	ax, C_WHITE
	call	DrawBWButtonBackground		; destroys ax, si
	
	; check if we need to draw the interior depressed
	test	bx, mask OLBSS_DEPRESSED
	jz	done				; dont need to draw interior
	call	DrawBWButtonDepressedInterior	; destroys ax, si
	jmp	done
	
ItemDrawBWItemDepressedIfInMenu	endp
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if _FXIP
DrawBW	ends
DrawBWRegions	segment resource
endif

if _OL_STYLE	;---------------------------------------------------------------
;Bitmap to use when checkmark item set

bwCheckBM	label	word
	word	CHECK_WIDTH
	word	CHECK_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00001000b
	byte	00000000b, 00110000b
	byte	00000000b, 01100000b
	byte	00000000b, 11000000b
	byte	00010001b, 10000000b
	byte	00111011b, 10000000b
	byte	01111111b, 00000000b
	byte	00111111b, 00000000b
	byte	00011110b, 00000000b
	byte	00001110b, 00000000b
	byte	00000100b, 00000000b

bwCheckOutBM	label	word
	word	CHECK_WIDTH
	word	5
	byte	0, BMF_MONO
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
endif		;---------------------------------------------------------------

if _FXIP
DrawBWRegions	ends
else
DrawBW	ends
endif
