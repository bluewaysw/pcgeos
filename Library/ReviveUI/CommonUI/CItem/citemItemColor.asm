COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC 
MODULE:		CommonUI/CItem (common code for specific UIs)
FILE:		citemItemColor.asm

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of citemItem.asm

DESCRIPTION:
	$Id: citemItemColor.asm,v 1.13 97/01/06 13:47:44 sullivan Exp $

------------------------------------------------------------------------------@
DrawColor segment resource

if not _ASSUME_BW_ONLY

COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorItem

DESCRIPTION:	Draw an OLItemClass object on a color display.

CALLED BY:	OLItemDraw (OpenLook and Motif cases only)

PASS:		*ds:si - instance data for OLItem object
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
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _PM	;-----------------------------------------------

ItemDrawColorItem	proc	far
	class	OLItemClass
	
EC <	call	VisCheckVisAssumption	;Make sure vis data exists	>

	mov	bp, cx			;Save DrawFlags and color scheme

	call	OLItemGetGenAndSpecState
					;sets:	bl = OLBI_moreAttrs
					;	bh = OLBI_specState (low byte)
					;	cl = OLBI_optFlags
					;	dl = GI_states
					;	dh = OLII_state

	;if this is a MSG_META_EXPOSED event, then force a full redraw.

	test	ch, mask DF_EXPOSED
if ITEM_USES_BACKGROUND_COLOR
	LONG jnz	fullRedraw
else
	LONG	jnz	fullRedrawNoClearBG	;skip if so...
endif

	test	cl, mask OLBOF_DRAW_STATE_KNOWN
	LONG 	jz	fullRedraw	;skip if have no old state info...

	mov	al, bh			;al = OLBI_specState (low byte)
	xor	al, cl			;al = states that changed

	test	al, mask OLBSS_SELECTED
	LONG 	jnz	fullRedraw

	;If the item is in a menu, then PM must do a full redraw.
PMAN <	push	di							>
PMAN <  mov	di, ds:[si]						>
PMAN <	add	di, ds:[di].Vis_offset					>
PMAN <  test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU		>
PMAN <	pop	di							>
PMAN <	jnz	fullRedraw						>

	; if cursor state has changed then must redraw moniker (although there
	; is an optimization done there)

	test	al, mask OLBSS_CURSORED
	jnz	cursoredStateChanged

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
	LONG jz	drawCommon		;skip if same enabled status...

if (not ITEM_USES_BACKGROUND_COLOR)	; can't optimize for color bg
deltaEnabledStatus:
	;the ENABLED status has changed. If that is all that changed,
	;then just wash over this object with a 50% pattern, making it
	;look as if we redrew it with 50% masks.

	test	al, OLBOF_STATE_FLAGS_MASK
	jnz	fullRedraw		;if any other flags changed,
					;force a full redraw...

	call	CheckIfJustDisabled
	jnc	fullRedrawNoClearBG	;going enabled, branch to do it
endif

if USE_COLOR_FOR_DISABLED_GADGETS or ITEM_USES_BACKGROUND_COLOR
	jmp	fullRedraw
else
	;If this is a specially colored item, and we're becoming disabled,
	;we can't wash with a reverse 50% pattern, owing to the two-color
	;stuff used in drawing the background.  Let's do a full redraw instead.

	push	ax
	clr	ax
	test	bh, mask OLBSS_SELECTED
	jz	3$			;skip if item is OFF...
	dec	al			;else pass selected
3$:
	call	OpenGetBackgroundColor
	cmp	al, ah
	pop	ax

	jne	fullRedraw		;using two-tone, redraw fully

	push	ax
	mov	ax, bp
	andnf	al, mask CS_lightColor	;use light color
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	clr	ah
	call	GrSetAreaColor

	;If this item was just disabled, then wash the icon in an
	;inverted HORIZONTAL pattern (as it would be drawn if disabled),
	;and the text in an inverted 50% pattern.

	call	GetCorrect50PercentMask

	push	cx
	ornf	al, mask SDM_INVERSE
	mov	ch, TRUE			; color
	call	OLItemWash50Percent
	pop	cx

	pop	ax
	jmp	done			
endif
	; cursored stated changed -- draw diamond & moniker but not background

cursoredStateChanged:
if CURSOR_ON_BACKGROUND_COLOR
	;
	; if cursor turned off, full redraw to support non-standard gadget
	; background colors
	;
	test	cl, mask OLBOF_DRAWN_CURSORED
	jz	checkCursor
	test	bh, mask OLBSS_CURSORED
	jz	fullRedraw
checkCursor:
endif
	;set the draw masks for the icon to 50% if this object is disabled
	;(Use SDM_HORIZONTAL, so that the left and rightward diagonal
	;lines look as if they are drawn in 50% pattern.)

MO <	test	dh, mask OLIS_DRAW_AS_TOOLBOX				>
MO <	jnz	fullRedraw		;skip if in toolbox...		>

PMAN <	test	dh, mask OLIS_DRAW_AS_TOOLBOX				>
PMAN <	jnz	fullRedraw		;skip if in toolbox...		>

	push	ax
	call	GetCorrect50PercentMask
	call	OLItemSetMasksIfDisabled
	pop	ax

	test	dh, mask OLIS_IS_CHECKBOX
	jnz	drawNonExcl

MO <	clr	ch			;don't optimize diamond drawing >
if not _ODIE
MO <	call	ItemDrawColorMotifDiamond	;draw "diamond"	item in Motif>
else
ODIE <	call	ItemDrawColorOdieRadioButton	;draw Odie style radio button>
endif
MO <					;returns ch = TRUE to draw moniker>
MO <	dec	ch			;redraw moniker >
MO <	jmp	short drawMoniker			>

PMAN <	clr	ch			;don't optimize radio button drawing  >
PMAN <	call	ItemDrawColorPMRadioButton
PMAN <					;returns ch = TRUE to draw moniker    >
PMAN <	dec	ch			;redraw moniker			      >
PMAN <	jmp	short drawMoniker					      >

	;must have changed from DISABLED to ENABLED: fall through
	;to force a full redraw.

fullRedraw:

if ITEM_USES_BACKGROUND_COLOR
if ALLOW_TAB_ITEMS
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	pop	di
	jnz	noCustomColor		; tab style - no colored bg
endif 	; ALLOW_TAB_ITEMS
	push	ax, bx, cx, dx
	clr	al			; not selected
	call	FillRectWithBGColors
	pop	ax, bx, cx, dx

else  	; ITEM_USES_BACKGROUND_COLOR

	call	ItemDrawColorBackground

endif 	; ITEM_USES_BACKGROUND_COLOR
noCustomColor::

	;
	; we must fully redraw this object, including the background
	;
fullRedrawNoClearBG:

	mov	ch, TRUE

drawCommon:
	;set the draw masks for the icon to 50% if this object is disabled
	;(Use SDM_HORIZONTAL, so that the left and rightward diagonal
	;lines look as if they are drawn in 50% pattern.)

if not USE_COLOR_FOR_DISABLED_GADGETS
	push	ax
	call	GetCorrect50PercentMask
	call	OLItemSetMasksIfDisabled
	pop	ax
endif

	;handle draw code common to Motif diamonds and toolbox-type items
	;	al = flags which have changed
	;	bl = OLBI_moreAttrs
	;	cl = OLBI_optFlags
	;	ch = TRUE if is full redraw
	;	dh = OLII_state

	test	dh, mask OLIS_MONIKER_INVALID
	LONG	jnz	done			;skip if invalid...

	;if is an OLCheckboxClass object, call routine to handle.

MO <	test	dh, mask OLIS_DRAW_AS_TOOLBOX				>
MO <	jnz	60$			;skip if in toolbox...		>
PMAN <	test	dh, mask OLIS_DRAW_AS_TOOLBOX				>
PMAN <	jnz	60$			;skip if in toolbox...		>
	test	dh, mask OLIS_IS_CHECKBOX
	jz	drawExclusiveItem	;skip if not...
drawNonExcl:
	call	ItemDrawColorNonExclusiveItem
	jmp	drawMoniker

drawExclusiveItem:
if not _ODIE
MO <	call	ItemDrawColorMotifDiamond	;draw "diamond"	item in Motif>
else
ODIE <	call	ItemDrawColorOdieRadioButton	;draw Odie style radio button>
endif
MO <					;returns ch = TRUE to draw moniker >
MO <	jmp	short drawMoniker					>
PMAN <	call	ItemDrawColorPMRadioButton				>
PMAN <					;returns ch = TRUE to draw moniker >
PMAN <	jmp	short drawMoniker					>

60$:	;This code is reached when:
	;	Motif:		Color, in toolbox (which might be in menu)
	;	PM:		Color, in toolbox (which might be in menu)
	;	OpenLook:	Color, all cases: menu, toolbox, or regular.

	call	ItemDrawColorTool	;returns ch = TRUE to draw moniker

drawMoniker:
	;Set the area color to be used by monochrome bitmap monikers
	;regs:	*ds:si	= object
	;	cl	= OLBI_optFlags
	;	ch	= TRUE if must redraw moniker
	;	dl	= GI_states
	;	dh	= OLII_state
	;	bp	= DrawFlags, ColorScheme
	;	di	= GState

	tst	ch			;do we have to redraw moniker?
	LONG jz	done			;skip if not...

if USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, C_BLACK		;assume C_BLACK as enabled color
	call	OLItemSetUseColorIfDisabled
	call	GrSetTextColor
	call	GrSetLineColor
	call	GrSetAreaColor
else
	mov	ax, bp
	andnf	ax, mask CS_darkColor	;assume dark color for bitmap
					;if is not enabled

	;set the draw masks for the text to 50% if this object is disabled

	mov	al, SDM_50
	call	OLItemSetMasksIfDisabled

	call	OLItemSetAreaColorBlackIfEnabled
					;set AreaColor C_BLACK or dark color.
endif					

	;call routine to determine which accessories to draw with moniker

	mov	al, cl			;pass al = OLBI_optFlags
	push	bx
	call	OLButtonSetupMonikerAttrs
	pop	bx
					;returns cx = info.
					;does not trash ax, dx, di

if _KBD_NAVIGATION	;------------------------------------------------------
	;DO NOT show selection cursor if inside a menu (this does not
	;include toolboxes which are inside a menu)

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset

	; In ODIE don't show selection cursor if we're a tab.
	;
if	_ODIE
	test	ds:[bp].OLII_extraRecord, mask OLIER_TAB_STYLE
	jz	73$
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			 mask OLMA_SELECTION_CURSOR_ON)
73$:					
endif

	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU
	jnz	86$
					;pass al = OLBI_optFlags
if CURSOR_ON_BACKGROUND_COLOR
	;
	; At this point, bl is OLBI_moreAttrs, and bh is the low byte of
	; OLBI_specState.  We need bx to be OLBI_specState for
	; OLButtonTestForCursored and our code below.  Yes,
	; OLButtonTestForCursored needs bx for all SPUIs, but it doesn't
	; really matter.  We only really need bx for our code below.
	;
	mov	bx, ds:[bp].OLBI_specState
endif
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
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			mask OLMA_SELECTION_CURSOR_ON)
notCursorOff:
endif

	;if selection cursor is on this object, and is a checkbox, have the
	;dotted line drawn inside the bounds of the object.

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	86$			;skip if not...

	;Motif: Pass color info in OLMonikerFlags so that OpenDrawMoniker
	;knows how to draw the selection cursor. Then, special-case non-
	;checkbox items: draw cursor around text.

MO <	ornf	cx, mask OLMA_LIGHT_COLOR_BACKGROUND			>
PMAN <	ornf	cx, mask OLMA_LIGHT_COLOR_BACKGROUND			>

	test	dh, mask OLIS_DRAW_AS_TOOLBOX
	jz	nonToolbox		;skip if is regular item..

toolbox:
	;toolbox: if erasing the cursor, let's assume the tool already
	;has been redrawn.

	test	cx, mask OLMA_SELECTION_CURSOR_ON
	jz	toolboxOff

toolboxOn:
	ornf	cx, mask OLMA_USE_TOOLBOX_SELECTION_CURSOR
	jmp	short 86$

toolboxOff:
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			 mask OLMA_LIGHT_COLOR_BACKGROUND)
	jmp	short 86$

nonToolbox:
	;is not a toolbox. If not in Motif or PM, draw moniker for checkbox.
if (not _MOTIF) and (not _PM)	;----------------------------------------------
	ornf	cx, mask OLMA_USE_CHECKBOX_SELECTION_CURSOR
endif		;--------------------------------------------------------------

86$:

if CURSOR_ON_BACKGROUND_COLOR	;----------------------------------------------

	mov	ax, (1 shl 8)		; ah = non-zero -- use parent color
					; al = 0 -- unselected
	call	OpenSetCursorColorFlags	; cx = update OLMonikerAttrs

endif	; CURSOR_ON_BACKGROUND_COLOR	;--------------------------------------

endif 			;------------------------------------------------------

	mov	ah, dh			;set ah = OLII_state


OLS <	mov	al, (J_CENTER shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)			>
OLS <	mov	dx, (BUTTON_INSET_Y shl 8) or BUTTON_INSET_X		>

MO <	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)			>
MO <	mov	dx, CHECK_BOX_WIDTH					>

PMAN <	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)			>
PMAN <	mov	dx, CHECK_BOX_WIDTH					>

	test	ah, mask OLIS_IS_CHECKBOX
	jz	87$			;skip if not...

	;setup specific justification and width info for Checkboxes.

	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)
OLS <	mov	dx, 3			;xoffset = 3, yoffset = 0	>
MO <	mov	dx, CHECK_BOX_WIDTH					>
PMAN <	mov	dx, CHECK_BOX_WIDTH					>

87$:	;Use small insets for toolbox items.

	test	ah, mask OLIS_DRAW_AS_TOOLBOX
	jz	checkInMenu

	mov	dx, (TOOLBOX_INSET_Y shl 8) or TOOLBOX_INSET_X

checkInMenu:
OLS <	mov	bp, ds:[si]						>
OLS <	add	bp, ds:[bp].Vis_offset					>
OLS <	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU		>
OLS <	jz	90$			;skip if not in menu...		>
OLS <	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		(J_CENTER shl offset DMF_Y_JUST)			>

PMAN <	test	bh, mask OLBSS_BORDERED					>
PMAN <	jz	90$
PMAN <	add	dx, 0101h	;shift moniker down and to the right	>

90$:
	;
	; pass al = DrawMonikerFlags, cx = OLMonikerAttrs
	;
	clr	ah
	call	OLButtonDrawMoniker	;draw moniker and accessories
done:
	ret
ItemDrawColorItem	endp

endif		;OL STYLE or MOTIF ---------------------------------------------


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetCorrect50PercentMask

SYNOPSIS:	Chooses the 50% washing mask apprporiate for this gadget.

CALLED BY:	ItemDrawColorItem, elsewhere

PASS:		dh -- OLItemState

RETURN:		al -- StandardDrawMask

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For color motif exclusives, return SDM_HORIZONTAL
	else return SDM_50

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 9/92       	Initial version

------------------------------------------------------------------------------@

GetCorrect50PercentMask	proc	near
if _MOTIF and (not _ODIE)
	; Odie does not have diamod shaped radio buttons so always return
	; SDM_50 for Odie. -lester, 29 July 96

;	call	OpenCheckIfBW				;changed over to diams
;	jc	3$					;  -cbh 3/ 8/93
	mov	al, SDM_HORIZONTAL					
	test	dh, mask OLIS_DRAW_AS_TOOLBOX
	jnz	3$					;toolbox, 50%
	test	dh, mask OLIS_IS_CHECKBOX		;checkbox, 50%
	jz	4$					;diamonds, horizontal
3$:									
endif

	mov	al, SDM_50

if _MOTIF and (not _ODIE)
4$:
endif
	ret
GetCorrect50PercentMask	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorMotifDiamond

DESCRIPTION:	This procedure draws a color Motif "diamond" item,
		which is used for exclusive items which are in menus
		or on a window. This DOES NOT include toolbox items.

CALLED BY:	ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is required
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		ds, si, di, ax, bx, dx, bp = same
		ch = TRUE if must redraw moniker

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		some code from old ItemDrawColorDiamond
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if _MOTIF and (not _ODIE)	;---------------------------------------------

ItemDrawColorMotifDiamond	proc	near
	;if is in a menu in MOTIF, then see if the BORDERED (CURSORED)
	;status has been reset. Force full redraw if so.

if	0
MO <	tst	ch							>
MO <	jnz	testForFullRedraw					>
MO <	test	bh, mask OLBSS_BORDERED ;is it bordered?		>
MO <	jnz	testForFullRedraw	;skip if so...			>
MO <	test	cl, mask OLBOF_DRAWN_BORDERED ;was it bordered?		>
MO <	jz	testForFullRedraw	;skip if not...			>
MO <	mov	ch, TRUE		;FORCE FULL REDRAW		>
MO <	call	ItemDrawColorBackground	;Draw the background		>

testForFullRedraw:
endif

	push	ax, bx, cx, dx, bp

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the diamond image according to the new SELECTED state.

MO <	call	ItemDrawColorMotifItemBorderIfInMenu			>
					;draws border around item if in menu
					;and BORDERED (meaning cursored) is set

	test	bh, mask OLBSS_SELECTED
	jz	notSelected		;skip if item is OFF...

selected:
	clr	ch			;don't optimize ItemDrawColorDiamond
	andnf	bp, mask CS_darkColor	;assume dark color
	mov	al, C_BLACK		;Top color of diamond
	mov	ah, C_WHITE		;Bottom color of diamond
	call	ItemDrawColorDiamond	;Draw exclusive diamond "on"
	jmp	short finishUp

notSelected:
	ANDNF	bp, mask CS_lightColor	;use light color
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	mov	al, C_WHITE		; Top color of diamond
	mov	ah, C_BLACK		; Bottom color of diamond
	call	ItemDrawColorDiamond	; Draw exclusive diamond "off"

finishUp:
	pop	ax, bx, cx, dx, bp

done:
	ret
ItemDrawColorMotifDiamond	endp

endif		;_MOTIF and (not _ODIE)	--------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorOdieRadioButton

DESCRIPTION:	This procedure draws a color Odie radio button item,
		which is used for exclusive items which are in menus
		or on a window. This DOES NOT include toolbox items.

CALLED BY:	(INTERNAL) ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is required
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		ds, si, di, ax, bx, dx, bp = same
		ch = TRUE if must redraw moniker

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	draw border if in menu
	get radio button bounds
	
	if (not FLAT_STYLE) {
	    get top and bottom colors
	    set area color to top color
	    fill top-left region
	    set area color to bottom color
	    fill bottom-right region

	    get background colors (selected/unselected)
	    use light color by default if no custom colors found
	    fill interior square with background colors (selected/unselected)
	} 
	else /* FLAT_STYLE */ {
	    fill background except one pixel bounding square with C_WHITE

	    is (selected) {
		get selected background color 
		fill interior square with selected background color
	    }
	}

	set line color to black
	draw the black one pixel bounding square


Default button color of a 3D radio button = light color
Default button color of a Flat radio button = dark color
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	7/25/96		Initial version

------------------------------------------------------------------------------@


if _ODIE	;--------------------------------------------------------------

ItemDrawColorOdieRadioButton	proc	near
	uses	ds, si, ax, bx, cx, dx

colorScheme	local	word	push	bp ;(low byte) ColorScheme
textColors	local	word	; text colors
selected	local	byte	; non-zero if item is selected

	.enter

	;
	; Draw border if item is in a menu and BORDERED is set.
	;
	push	bp			; save locals
	mov	bp, ss:colorScheme
	call	ItemDrawColorMotifItemBorderIfInMenu
					; draws border around item if in menu
					; and BORDERED (meaning cursored) is set
	pop	bp			; restore locals

	;
	; Initialize the notSelected flag.
	;
	clr	al			; assume item is selected
	test	bh, mask OLBSS_SELECTED	; is item selected?
	jz	saveFlag		; nope -> save the flag
	dec	al			; item is selected
saveFlag:
	mov	ss:selected, al

	;
	; initialize text colors, default to black for both unselected
	; and selected
	;
	mov	textColors, (C_BLACK shl 8) or C_BLACK
	call	OpenGetParentTextColor	; ax = colors
	jnc	noTextColors		; didn't find any custom colors
	mov	textColors, ax		; else, use custom colors
noTextColors:

	;
	; Get the radio button bounds.
	;	We get the radio button bounds by getting the check box
	;	bounds and then shrinking the bounds by two pixels since 
	;	an Odie check box (24x24) is two pixels taller and wider
	;	than an Odie radio button (22x22).
	;
	call	GetCheckboxBounds	; ax, bx, cx, dx = Check box bounds
.assert ((CHECK_HEIGHT - RADIO_HEIGHT) eq 2)
.assert ((CHECK_WIDTH_REAL - RADIO_WIDTH_REAL) eq 2)
	inc	ax
	inc	bx
	dec	cx
	dec	dx			; ax, bx, cx, dx = Radio button bounds

	;
	; Check if we should draw the item in the FLAT style.
	;
	push	ax, bx
	mov	ax, HINT_DRAW_STYLE_FLAT
	call	ObjVarFindData		; does item have the flat style hint?
	pop	ax, bx
	jc	flatStyle		; yes -> draw item in flat style

	;
	; Draw button in 3D style.
	;
	call	ItemDrawColorOdieRadioButton3DShading
	call	ItemDrawColorOdieRadioButton3DInterior
	jmp	common

	;
	; Draw button in FLAT style.
	;
flatStyle:

	;
	; Fill the background of the radio button with C_WHITE.
	;
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	pop	ax
	call	GrFillRect
	
	;
	; Check if the item is selected.
	;
	tst	ss:selected		; is item selected?
	jz	common			; nope -> skip interior button

	;
	; Draw the interior button for a Flat Odie radio button.
	;
	call	ItemDrawColorOdieRadioButtonFlatInterior

common:
	;
	; Draw the black one pixel bounding square.
	;
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor
	pop	ax
	call	GrDrawRect

	;
	; set line and text colors for moniker
	;
	mov	ax, ss:textColors
	tst	ss:selected
	jz	haveMonikerColor		; use unselected color
	mov_tr	al, ah				; use selected color
haveMonikerColor:
	clr	ah
	call	GrSetLineColor
	call	GrSetTextColor

	.leave
	ret
ItemDrawColorOdieRadioButton	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorOdieRadioButtonGetShadingColors

DESCRIPTION:	Sets up colors used to draw Odie radio button 3D shading.

CALLED BY:	(INTERNAL) ItemDrawColorOdieRadioButton3DShading

PASS:		ss:bp	= Inheritable stack frame

RETURN:		al = top color
		ah = bottom color

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	item selected
		top (al)	= dark color
		bottom (ah)	= C_WHITE

	item not selected
		top (al)	= C_WHITE
		bottom (ah)	= dark color

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	7/25/96		Initial version

------------------------------------------------------------------------------@
ItemDrawColorOdieRadioButtonGetShadingColors	proc	near
	.enter inherit ItemDrawColorOdieRadioButton

	;
	; Assume item is selected.
	;	top (al)	= dark color
	;	bottom (ah)	= C_WHITE
	;
	mov	ax, ss:colorScheme
	andnf	ax, mask CS_darkColor	; al <- dark color index
	mov	ah, C_WHITE		; ah <- C_WHITE

	tst	ss:selected		; is item selected?
	jnz	done			; yes -> we're done

	;
	; Item is not selected so we need to swap the colors.
	;	top (al)	= C_WHITE
	;	bottom (ah)	= dark color
	; 
	xchg	ah, al
done:
	.leave
	ret
ItemDrawColorOdieRadioButtonGetShadingColors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorOdieRadioButton3DShading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the 3D shading for a 3D Odie radio button.

CALLED BY:	(INTERNAL) ItemDrawColorOdieRadioButton
PASS:		ax, bx, cx, dx = radio button bounds
		di	= GState
		ss:bp	= Inheritable stack frame

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawColorOdieRadioButton3DShading	proc	near
	.enter inherit ItemDrawColorOdieRadioButton

	push	ds, si
FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>

	; Place the pen at the top-left corner
	call	GrMoveTo

	;
	; Fill the top-left region with the top color.
	;	
	push	ax			; #2 save left coordinate
	call	ItemDrawColorOdieRadioButtonGetShadingColors
					; al = top color, ah = bottom color
	push	ax			; #1 save the bottom color
	clr	ah			; ah <- CF_INDEX (0)
	call	GrSetAreaColor
	mov	si, offset odieRadioButtonTopLeftCornerRegion
	call	GrDrawRegionAtCP

	;
	; Fill the bottom-right region with the bottom color.
	;
	pop	ax			; #1 ah <- bottom color
	mov	al, ah			; al <- bottom color
	clr	ah			; ah <- CF_INDEX (0)
	call	GrSetAreaColor
	mov	si, offset odieRadioButtonBottomRightCornerRegion
	call	GrDrawRegionAtCP
	pop	ax			; #2 restore left coordinate

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	pop	ds, si

	.leave
	ret
ItemDrawColorOdieRadioButton3DShading	endp

if _FXIP		; regions must be in separate resource for xip
DrawColor	ends
DrawColorRegions segment resource
endif

if not _ASSUME_BW_ONLY
odieRadioButtonTopLeftCornerRegion	label	word
	word	0, 0, 22, 22			; bounds
	word	0,				EOREGREC
	word	1, 1, 20,			EOREGREC
	word	2, 1, 19,			EOREGREC
	word	3, 1, 18,			EOREGREC
	word	18, 1, 3,			EOREGREC
	word	19, 1, 2,			EOREGREC
	word	20, 1, 1,			EOREGREC
	word	EOREGREC

odieRadioButtonBottomRightCornerRegion	label	word
	word	0, 0, 22, 22			; bounds
	word	1,				EOREGREC
	word	2, 20, 20,			EOREGREC
	word	3, 19, 20,			EOREGREC
	word	17, 18, 20,			EOREGREC
	word	18, 4, 20,			EOREGREC
	word	19, 3, 20,			EOREGREC
	word	20, 2, 20,			EOREGREC
	word	EOREGREC

endif	; not _ASSUME_BW_ONLY

if _FXIP	; regions must be in separate resource for xip
DrawColorRegions ends
DrawColor	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorOdieRadioButton3DInterior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the interior button for a 3D Odie radio button.

CALLED BY:	(INTERNAL) ItemDrawColorOdieRadioButton
PASS:		*ds:si	= object being drawn
		ax, bx, cx, dx = radio button bounds
		di	= GState
		ss:bp	= Inheritable stack frame

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawColorOdieRadioButton3DInterior	proc	near
	.enter inherit ItemDrawColorOdieRadioButton

	;
	; Fill the interior square with the radio button's secondary 
	; background color or use the light color by default if no
	; custom background colors are found.
	;
	push	ax, bx, cx, dx, bp
	push	ax			; save left coordinate
	mov	ah, ss:selected
	mov	al, 2			; get secondary background colors
	call	OpenGetExtraBackgroundColor ; al & ah <- background colors
	jc	gotColors
	;
	;	Use light color since no custom colors were found.
	;
	mov	ax, ss:colorScheme	; al <- ColorScheme
	andnf	al, mask CS_lightColor	; use light color 
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1			; al <- light color index
	mov	ah, al			; ah <- light color index
gotColors:
	mov	bp, ax			; bp <- background colors
	pop	ax			; restore left coordinate

	add	ax, 4			; the interior square of a 3D radio
	add	bx, 4			;   button is 4 pixels smaller than
	sub	cx, 3 			;   the radio button bounds
	sub	dx, 3	
	call	FillRectWithTwoColors	; fill the interior of the button
	pop	ax, bx, cx, dx, bp

	.leave
	ret
ItemDrawColorOdieRadioButton3DInterior	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorOdieRadioButtonFlatInterior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the interior button for a Flat Odie radio button.

CALLED BY:	(INTERNAL) ItemDrawColorOdieRadioButton
PASS:		*ds:si	= object being drawn
		ax, bx, cx, dx = radio button bounds
		di	= GState
		ss:bp	= Inheritable stack frame

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ItemDrawColorOdieRadioButtonFlatInterior	proc	near
	.enter inherit ItemDrawColorOdieRadioButton

	;
	; Fill the interior square with the button's background color.
	;
	push	ax, bx, cx, dx, bp
	push	ax			; save left coordinate
	mov	ah, -1			; use selected color
	mov	al, 2			; get secondary background colors
	call	OpenGetExtraBackgroundColor ; al & ah <- background colors
	jc	gotColors
	;
	;	Use dark color since no custom colors were found.
	;
	mov	ax, ss:colorScheme	; al <- ColorScheme
	andnf	al, mask CS_darkColor	; use dark color 
	mov	ah, al			; al & ah <- dark color index
gotColors:

	mov	bp, ax			; bp <- background colors
	pop	ax			; restore left coordinate

	add	ax, 5			; the interior square of a FLAT radio
	add	bx, 5			;   button is 5 pixels smaller than
	sub	cx, 4			;   the radio button bounds
	sub	dx, 4
	call	FillRectWithTwoColors	; fill the interior of the button
	pop	ax, bx, cx, dx, bp

	.leave
	ret
ItemDrawColorOdieRadioButtonFlatInterior	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillRectWithTwoColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills the rectangle with the passed colors using a 50%
		pattern if the colors are different.

CALLED BY:	(INTERNAL) 
PASS:		*ds:si		= object being drawn
		ax, bx, cx, dx	= rectangle bounds
		bp (low byte)	= color to drawn at reverse 50% pattern
		bp (high byte)	= color to drawn at 50% pattern
		di		= GState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		area color and area mask are changed
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/13/96    	Initial version
				some code taken from FillRectWithBGColors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillRectWithTwoColors	proc	near
	uses	si
	.enter

	push	ax				;save left coordinate
	mov	ax, bp
	clr	ah
	call	GrSetAreaColor			;first color
	pop	ax				;restore left coordinate

	call	GrFillRect			;draw rect in first color
	
	push	ax				;save left coordinate
	mov	ax, bp
	cmp	al, ah				;are first and 2nd colors same?
	pop	ax				;restore left coordinate
	jz	exit				;yes -> exit
	call	VisCheckIfFullyEnabled		;not fully enabled, one color!
	jnc	exit

	mov	si, ax				;save left coordinate
	mov	ax, bp
	mov	al, ah
	clr	ah
	call	GrSetAreaColor			;second color
	mov	al, SDM_50
	call	GrSetAreaMask			;set area mask
	mov	ax, si				;restore left coordinate
	call	GrFillRect			;draw rect in second color
	mov	al, SDM_100
	call	GrSetAreaMask			;reset area mask
	mov	ax, si				;restore left coordinate

exit:
	.leave
	ret
FillRectWithTwoColors	endp

endif		;_ODIE --------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorPMRadioButton

DESCRIPTION:	This procedure draws a color PM radio button item,
		which is used for exclusive items which are in menus
		or on a window. This DOES NOT include toolbox items.

CALLED BY:	ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = TRUE if full redraw is required
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		ds, si, di, ax, bx, dx, bp = same
		ch = TRUE if must redraw moniker

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/92		some code from old ItemDrawColorMotifDiamond

------------------------------------------------------------------------------@

if _PM

ItemDrawColorPMRadioButton	proc	near
	push	ax, bx, cx, dx, bp

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the diamond image according to the new SELECTED state.

	call	ItemDrawColorMotifItemBorderIfInMenu
					;draws border around item if in menu
					;and BORDERED (meaning cursored) is set

	push	bp
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU
	pop	bp
	jz	notBordered
	call	ItemDrawPMCheck		;radio buttons in menus are check marks
	jmp	done

notBordered:
	test	bh, mask OLBSS_SELECTED
	jz	notSelected		;skip if item is OFF...

selected:
	clr	ch			;don't optimize ItemDrawColorDiamond
	andnf	bp, mask CS_darkColor	;assume dark color
	jmp	short draw

notSelected:
	andnf	bp, mask CS_lightColor	;use light color
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
draw:
	mov	ax, (MO_ETCH_COLOR shl 8) or C_WHITE
	test	bh, mask OLBSS_DEPRESSED
	jz	notDepressed
depressed:
	xchg	ah, al
notDepressed:
	call	ItemDrawColorRadioButton
done:
	pop	ax, bx, cx, dx, bp
	ret
ItemDrawColorPMRadioButton	endp

endif		; if _PM ------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorTool

DESCRIPTION:	This procedure draws a color Toolbox-type item,
		for Motif or OpenLook only. In Motif, this procedure is
		used for toolbox exclusive items; in OpenLook it is
		used for items in a windowm, menu, or toolbox.

CALLED BY:	ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
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
	Eric	4/90		some code from old ItemDrawColorItem
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite
	sean	5/15/96		Added support for tabs

------------------------------------------------------------------------------@

if _OL_STYLE or _MOTIF or _PM	;-----------------------------------------------

ItemDrawColorTool	proc	near

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the tool image according to the new SELECTED state.

	push	ax, bx, cx, dx, bp
TABS <	call	CheckIfTabStyleItem			>
TABS <	LONG	jc	finishUp			>
	test	bh, mask OLBSS_SELECTED
	jz	notSelected		;skip if item is OFF...

selected:

	;draw background in dark (selected) color

	clr	ax

if	(not _PM)			;background color never black in PM
	tst	si
	jz	0$
	dec	ax			;al non-zero if selected
0$:
endif	

	call	FillRectWithBGColors
	dec	cx			;now do for lines
	dec	dx	

	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax

	call	GrDrawHLine		;Draw the top/left edges
	call	GrDrawVLine

	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	call	ItemDrawBottomRightEdges

if (not _PM)		;text color never black in PM?
	;
	; Code added 11/20/92 to choose between a black or white select color,
	; depending on whether we're in a toolbox or not and what the toolbox
	; background color is (dark-gray or black background, we use white).
	;
	mov	ax, C_BLACK		;assume we're sticking with black
	push	si
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	si
	jz	white

	push	ds, ax
	mov	ax, segment moCS_selBkgdColor
	mov	ds, ax
	cmp	ds:moCS_selBkgdColor, C_DARK_GREY
	je	10$
	cmp	ds:moCS_selBkgdColor, C_BLACK
10$:
	pop	ds, ax
	jne	black			;not either color, use black.
white:
endif

	mov	ax, C_WHITE		;Use white text over dark bg
black:
	mov	bx, si			;use selected text color 
	jmp	short finishUp

notSelected:
	clr	ax
	call	FillRectWithBGColors
	dec	cx			;now do for lines
	dec	dx	

	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	call	GrDrawHLine		;Draw the top/left edges
	call	GrDrawVLine

	push	ax
	andnf	bp, mask CS_darkColor	;assume dark color
	mov	ax, bp
	call	GrSetLineColor
	pop	ax
	call	ItemDrawBottomRightEdges
	
	mov	ax, C_BLACK		;Use black text when not selected
	clr	bx			;use unselected text color

finishUp:
	mov	cx, bx			;selected flag in cx
	mov_tr	bx, ax			;color in bx
if ITEM_USES_BACKGROUND_COLOR
	;
	; use parent text color, as we do for background color
	;
	call	OpenGetParentTextColor
else
	call	OpenGetTextColor	;check for text color hint
endif
	jnc	nothingSpecial
	mov_tr	bx, ax			;returned colors in bx

if	(not _PM)
	jcxz	notSelectedCustom
	mov	bl, bh			;use selected color returned
notSelectedCustom:
endif

	clr	bh			;clear high byte

nothingSpecial:
	mov	ax, bx			;color in ax now
	call	GrSetTextColor
	call	GrSetLineColor		;for mnemonics

	pop	ax, bx, cx, dx, bp

if _MOTIF	;--------------------------------------------------------------
	;Motif: only redraw moniker if is TOOLBOX, or if is FULL REDRAW,
	;or if CURSORED status changed.

	tst	ch			;is this a full redraw?
	jnz	done			;skip if is full redraw (ch = TRUE)...

	test	dh, mask OLIS_DRAW_AS_TOOLBOX ;in toolbox?
	jnz	doRedrawMoniker		  ;redraw moniker, because sits
					  ;inside toolbox...

	test	al, mask OLBSS_CURSORED
	jz	done			;skip if cursored did not change...
endif		;--------------------------------------------------------------

doRedrawMoniker:
	mov	ch, TRUE
done:
	ret
ItemDrawColorTool	endp



FillRectWithBGColors	proc	near
	;
	; Pass: al -- non-zero for selected color. 
	;	*ds:si -- object
	; Returns:	ax, bx, cx, dx -- fill bounds
	;
	push	bp

	;
	; Added 12/10/92 cbh to avoid using toolbox colors if we're only 
	; drawing like a toolbox, but not actually in a toolbar.  -cbh 12/10/92
	;
	clr	ah				;assume no toolbox color
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	di
	jz	10$				;not in toolbar, branch
	dec	ah				;use toolbox color
10$:

if ITEM_USES_BACKGROUND_COLOR
	;
	; if item group has custom color, use it
	; otherwise, if in-menu or a scrolling list item, use default
	;	bg color (light grey)
	; otherwise (radio buttons and checkboxes), use wash color as we
	;	have bg wash areas showing
	;
	call	OpenGetParentBackgroundColor	; ax = bg colors
	jc	haveBGColor
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jnz	haveBGColor			; in menu, use default bg color
	push	es, di
	mov	di, segment OLScrollableItemClass
	mov	es, di
	mov	di, offset OLScrollableItemClass
	call	ObjIsObjectInClass
	pop	es, di
	jc	haveBGColor			; if scrollable item, use
						;	default bg color
						; else, use wash color
	call	OpenGetWashColors		; ax = wash colors
haveBGColor:
else
	call	OpenGetBackgroundColor
endif
	push	ax
	clr	ah
	call	GrSetAreaColor			;first color
	call	VisGetBounds
	call	GrFillRect			;draw rect in first color
	mov	bp, ax				;save left edge
	pop	ax
	cmp	al, ah				;first and 2nd colors same, exit
	jz	exit
if (not ITEM_USES_BACKGROUND_COLOR)
; If ITEM_USES_BACKGROUND_COLOR is set, we need to draw both colors 
; even if the item is disabled.  --Thomas Lester, 15 Aug 96
	call	VisCheckIfFullyEnabled		;not fully enabled, one color!
	jnc	exit
endif
	mov	al, ah
	clr	ah				;second color
	call	GrSetAreaColor	
	mov	al, SDM_50
	call	GrSetAreaMask			;in case bitmap
	mov	ax, bp				;restore left edge
	call	GrFillRect
	mov	al, SDM_100
	call	GrSetAreaMask			;in case bitmap
exit:
	mov	ax, bp
	pop	bp
	ret
FillRectWithBGColors	endp


if	ALLOW_TAB_ITEMS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTabStyleItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the item is tab-style, this routine draws it.

CALLED BY:	ItemDrawColorTool

PASS:		*ds:si	= instance data for object
		bh 	= OLBI_specState (low byte)
		^hdi	= GState

RETURN:		carry clear 	= NOT tab style item
		carry set 	= tab style item, drawing done here
			ax = color for selected/non-selected text
			bx = non-zero if selected
 
DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	5/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfTabStyleItem	proc	near
	.enter

	Assert	objectPtr	dssi, OLItemClass		
	Assert	gstate		di				

	; Dereference Item object & check if it's tab style
	;
	push	di			; save GState
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLII_extraRecord, mask OLIER_TAB_STYLE
	pop	di			; restore GState
	clc				; assume not tab style
	jnz	tabStyle
exit:
	.leave
	ret

	; It is tab style, so draw it
	;
tabStyle:
	call	DrawItemTab
	stc
	jmp	exit

CheckIfTabStyleItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawItemTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws item as a tab, depending on what type of tab
		(i.e. top,left,selected, etc.)

CALLED BY:	CheckIfTabStyleItem

PASS:		*ds:si	= Item object
		^hdi	= GState
		bh 	= OLBI_specState (low byte)

RETURN:		ax	= moniker text color (black--selected)
		bx	= non-zero if selected tab

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		CreateTableIndex
		Fill tab interior
		Draw tab shading
		Draw tab outline
		return selected color registers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	5/ 6/96    	Initial version
	sean	9/16/96		Changed regions to draw entire outline
				Got rid of 3-D tabs
	sean	12/16/96	Changes to regions, re-organization

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawItemTab	proc	near

	uses	cx,dx,si,bp,ds
	.enter

	; Get the tab style in the extra record and manipulate it to 
	; become an index into the tables for regions.
	;
	call	CreateTableIndex	; bp = table index

	; Fill background
	;
	call	FillInteriorTab		

	; Draw tab shading
	;
	call	DrawTabShading

	; Draw tab's outline
	;
	call	DrawTabOutline

	; Return colors for moniker
	;
	mov	ch, bh

	mov	ax, (CF_INDEX shl 8) or C_WHITE 
	mov	bx, 1

	test	ch, mask OLBSS_SELECTED	; selected ?
	jnz	finish
	
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	clr	bx
finish:
	.leave
	ret
DrawItemTab	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTableIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns table index for drawing correct tab regions

CALLED BY:	DrawItemTab

PASS:		*ds:si 	= OLItem object
		bh	= OLIS_specState (low byte)
		^hdi	= GState

RETURN:		bp	= table index

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Tab Table structure
		  1) Top-rounded
		  2) Left-rounded
		  3) Right-rounded
		  4) Top-rounded/last
		  5) Left-rounded/selected
		  6) Right-rounded/selected		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	12/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTableIndex	proc	near
	uses	ax, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ah
	mov	al, ds:[di].OLII_extraRecord
	andnf	al, mask OLIER_TAB_STYLE	; mask off non-tab-style bits

	Assert	etype	al, OLItemTabStyle

	cmp	al, OLITS_TAB_TOP
	je	checkIfLast

	test	bh, mask OLBSS_SELECTED
	jz	finishIndex		; item selected ?
	add	al, NUM_TAB_STYLES
	
finishIndex:
	shl	al, 1			; multiply by 2
	mov	bp, ax			; bp = table index

	.leave
	ret

checkIfLast:
	test	ds:[di].VI_link.chunk, LP_IS_PARENT
	jz	finishIndex		; last item in item group ?
	add	al, NUM_TAB_STYLES
	jmp	finishIndex

CreateTableIndex	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInteriorTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills the interior of the tab with the correct color

CALLED BY:	DrawItemTab

PASS:		*ds:si	= object
		bh	= OLIS_specState (low byte)
		bp	= index into tables for regions

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInteriorTab	proc	near

	uses	ax,bx,cx,dx,si,ds
	.enter
	
	; ax = non-zero if tab is selected, zero otherwise
	;
	mov	ax, 1				; assume selected
	test	bh, mask OLBSS_SELECTED
	jnz	selected
	clr	ax				; not selected
selected:

if ITEM_USES_BACKGROUND_COLOR
	;
	; use parent background color for item
	;
	call	OpenGetParentBackgroundColor	; al = color
else
	call	OpenGetBackgroundColor		
endif
	clr	ah				; ah = CF_INDEX
	call	GrSetAreaColor			
	call	VisGetBounds			; ax, bx, cx, dx = rect bounds
	segmov 	ds, cs, si
	mov	si, cs:[interiorTabRegionTable][bp]	; ds:si = region
	sub	dx, bx				; dx = height
	sub 	cx, ax				; cx = width
	call	GrDrawRegion			
	
	.leave
	ret
FillInteriorTab		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabShading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tab's shading

CALLED BY:	DrawItemTab

PASS:		*ds:si 	= Item object
		bh	= OLIS_specState (low byte)
		di	= GState
		bp	= index into region tables

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Sets line color of GState

PSEUDO CODE/STRATEGY:
		if(not selected)
		  Set line color (lt. grey)
		  Get object bounds
		  if(vertical tab)
		    draw vertical shading
		  else
		    draw horizontal shading

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabShading	proc	near
	uses	ax,bx,cx,dx
	.enter

	test	bh, mask OLBSS_SELECTED	; selected ?
	jnz	exit

	; Horizontal tab--draw light grey line at bottom of tab
	;
	mov	ax, (CF_INDEX shl 8) or C_LIGHT_GREY
	call	GrSetLineColor

	call	VisGetBounds

	tst	cs:[orientationTable][bp]
	jz	verticalTab

	mov	bx, dx
	sub	bx, 2
	inc	ax
	dec	cx
	call	GrDrawHLine
exit:
	.leave
	ret

	; Vertical tab--draw dark grey & light grey lines on foot of
	; tab.  Draw selected color at base of tab.
	;
verticalTab:
	mov	ax, cx
	sub	ax, 4
	dec	dx
	call	GrDrawVLine

	push	ax
	mov	ax, (CF_INDEX shl 8) or C_DARK_GREY
	call	GrSetLineColor
	pop	ax

	inc	ax
	call	GrDrawVLine

	push	ax				; save x-coordinate
	mov	ax, 1				; we want selected color
	call	OpenGetParentBackgroundColor
	clr	ah				; ah = CF_INDEX
	call	GrSetLineColor			; set to selected color
	pop	ax				; restore x-coordinate

	add	ax, 2
	call	GrDrawVLine

	jmp	exit

DrawTabShading	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws outline of tab item

CALLED BY:	DrawItemTab

PASS:		*ds:si	= OLItem object
		bp	= table index for outline regions

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Sets area color for GState

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	12/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabOutline	proc	near
	uses	ax,bx,cx,dx,si,ds
	.enter

	; Set color for outline
	;
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	call	VisGetBounds
	
	segmov	ds, cs
	mov	si, cs:[outlineTabRegionTable][bp]	; ds:si = region
	sub	cx, ax			; cx = region width
	sub	dx, bx			; dx = region height
	call	GrDrawRegion		

	.leave
	ret
DrawTabOutline	endp


; Non-zero if the tab is horzontal, zero for vertical tabs
;
orientationTable	word\
	0,				; dummy 
	1, 0, 0, 1, 0, 0 

; Table of top-left tab regions
;
outlineTabRegionTable	word\
		0,				; dummy
		offset	TopTabRegion,		; top-rounded
		offset	LeftTabRegion,		; left-rounded
		offset	RightTabRegion,		; right-rounded
		offset	TopLastTabRegion,	; top-rounded/last
		offset	LeftSelectedTabRegion,	; left-rounded/selected
		offset	RightSelectedTabRegion  ; right-rounded/selected

; Table of interior tab regions
;
interiorTabRegionTable	word\
		0,				; dummy
		offset	TopInteriorTabRegion,	; top-rounded
		offset	LeftInteriorTabRegion,	; left-rounded
		offset	RightInteriorTabRegion,	; right-rounded
		offset	TopInteriorTabRegion,	; top-rounded/last
		offset	LeftInteriorTabRegion,	; left-rounded/selected
		offset	RightInteriorTabRegion	; right-rounded/selected

; Top-rounded tab regions  -----------------------------------------
;
TopTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		4, PARAM_2-4,			EOREGREC
	word	1,		2, 3, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	3,		1, 1, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-2,	0, 0,				EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

TopLastTabRegion		label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	word	-1,						EOREGREC
	word	0,		4, PARAM_2-5,			EOREGREC
	word	1,		2, 3, PARAM_2-4, PARAM_2-3,	EOREGREC
	word	3,		1, 1, PARAM_2-2, PARAM_2-2,	EOREGREC
	word	PARAM_3-2,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	0, PARAM_2-1,			EOREGREC
	word	EOREGREC

TopInteriorTabRegion		label 	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,					EOREGREC
	 word	0, 					EOREGREC
	 word	1, 		4, PARAM_2-4,		EOREGREC
	 word	3, 		2, PARAM_2-2,		EOREGREC
	 word	PARAM_3-2,	1, PARAM_2-1,		EOREGREC
	 word	EOREGREC


; Left-rounded tab regions --------------------------------------------
;
LeftTabRegion		label	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

   word	-1,						EOREGREC
   word	0, 	   4, 5, PARAM_2-2, PARAM_2-2, 			EOREGREC
   word	1,	   3, 3, PARAM_2-2, PARAM_2-2, 			EOREGREC
   word	3,	   2, 2, PARAM_2-2, PARAM_2-2,			EOREGREC
   word	PARAM_3-6, 1, 1, PARAM_2-2, PARAM_2-2, 			EOREGREC
   word	PARAM_3-4, 2, 2, PARAM_2-2, PARAM_2-2, 			EOREGREC
   word	PARAM_3-3, 3, 3, PARAM_2-2, PARAM_2-2,			EOREGREC
   word	PARAM_3-2, 4, 5, PARAM_2-2, PARAM_2-2, 			EOREGREC
   word	PARAM_3-1, 6, PARAM_2-2,				EOREGREC
   word	EOREGREC

LeftSelectedTabRegion		label	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,						EOREGREC
	 word	0,		4, 5, 				EOREGREC
	 word	1,		3, 3, 				EOREGREC
	 word	3,		2, 2, 				EOREGREC
	 word	PARAM_3-6,	1, 1, 				EOREGREC
	 word	PARAM_3-4,	2, 2, 				EOREGREC
	 word	PARAM_3-3,	3, 3, 				EOREGREC
	 word	PARAM_3-2,	4, 5, 				EOREGREC
	 word	PARAM_3-1,	6, PARAM_2-2, 			EOREGREC
	 word	EOREGREC


LeftInteriorTabRegion		label 	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,					EOREGREC
	 word	0, 		5, PARAM_2-1,		EOREGREC
	 word	1, 		3, PARAM_2-1,		EOREGREC
	 word	3, 		2, PARAM_2-1,		EOREGREC
	 word	PARAM_3-6,	1, PARAM_2-1,		EOREGREC
	 word	PARAM_3-4,	2, PARAM_2-1,		EOREGREC
	 word	PARAM_3-3,	3, PARAM_2-1,		EOREGREC
	 word	PARAM_3-2,	5, PARAM_2-1,		EOREGREC
	 word	PARAM_3-1,	PARAM_2-1, PARAM_2-1,		EOREGREC
	 word	EOREGREC

; Right-rounded tab regions -------------------------------------------
;

RightTabRegion		label	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,						EOREGREC
	 word	0,		0, PARAM_2-6,			EOREGREC
	 word	1, 		0, 0, PARAM_2-5, PARAM_2-4,	EOREGREC
	 word	2,		0, 0, PARAM_2-3, PARAM_2-3,	EOREGREC
	 word	3,		0, 0, PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	4,		0, 0, PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	PARAM_3-5,	0, 0, PARAM_2-1, PARAM_2-1,	EOREGREC
	 word	PARAM_3-3,	0, 0, PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	PARAM_3-2,	0, 0, PARAM_2-3, PARAM_2-3,	EOREGREC
	 word	PARAM_3-1,	0, 0, PARAM_2-5, PARAM_2-4,	EOREGREC
	 word	EOREGREC

RightSelectedTabRegion		label	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,					EOREGREC
	 word	0,		0, PARAM_2-6,		EOREGREC
	 word	1, 		PARAM_2-5, PARAM_2-4,	EOREGREC
	 word	2,		PARAM_2-3, PARAM_2-3,	EOREGREC
	 word	3,		PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	4,		PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	PARAM_3-5,	PARAM_2-1, PARAM_2-1,	EOREGREC
	 word	PARAM_3-3,	PARAM_2-2, PARAM_2-2,	EOREGREC
	 word	PARAM_3-2,	PARAM_2-3, PARAM_2-3,	EOREGREC
	 word	PARAM_3-1,	PARAM_2-5, PARAM_2-4,	EOREGREC
	 word	EOREGREC

RightInteriorTabRegion		label 	Region
	 word	0, 0, PARAM_2-1, PARAM_3-1	;bounds

	 word	-1,						EOREGREC
	 word	0,						EOREGREC
	 word	1, 		0, PARAM_2-6,			EOREGREC
	 word	2,		0, PARAM_2-4, 			EOREGREC
	 word	4,		0, PARAM_2-3, 			EOREGREC
	 word	PARAM_3-5, 	0, PARAM_2-2, 			EOREGREC
	 word	PARAM_3-3, 	0, PARAM_2-3,			EOREGREC
	 word	PARAM_3-2, 	0, PARAM_2-4,			EOREGREC
	 word	PARAM_3-1, 	0, PARAM_2-6, 			EOREGREC
	 word	EOREGREC

endif		; if ALLOW_TAB_ITEMS  -----------------------------------------
endif		;OL STYLE or MOTIF ---------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorNonExclusiveItem

DESCRIPTION:	This procedure draws a color Non-Exclusive item,
		for Motif or OpenLook only. This item looks like a
		wide toolbox (moniker inside), or a checkmark in a box.

CALLED BY:	ItemDrawColorItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
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
	Eric	4/90		some code from old copenCheckbox.asm
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

;NOTE: <FINISH: OpenLook and Motif checkbox draw methods>

if _OL_STYLE or _MOTIF	;------------------------------------------------------

ItemDrawColorNonExclusiveItem	proc	near

	;The CURSORED, DEPRESSED, SELECTED, or DEFAULT flag(s) have changed
	;update the tool image according to the new SELECTED state.

MO <	call	ItemDrawColorMotifItemBorderIfInMenu			>
MO <	jnc	noOpt							>

	; in menu and BORDERED state changed, we can't do optimization if
	; we are in keyboardOnly mode because the border erases the double
	; mnemonic underline drawn as part of the moinker - brianc 12/11/92

MO <	call    OpenCheckIfKeyboardOnly					>
MO <	jc	noOpt			;keyboard only, can't do opt	>

MO <	tst	ch							>
MO <	jz	done							>
MO <noOpt:								>

					;draws border around item if in menu
					;and BORDERED (meaning cursored) is set
if not _ODIE
MO <	call	ItemDrawColorMotifNonExclBox				>
else
ODIE <	call	ItemDrawColorOdieNonExclBox				>
endif
OLS  <	call	ItemDrawColorOpenLookNonExclBox				>

finishUp:

doRedrawMoniker:
	mov	ch, TRUE

done:
	ret
ItemDrawColorNonExclusiveItem	endp

endif		;OL STYLE or MOTIF --------------------------------------------


if _PM		;--------------------------------------------------------------

ItemDrawColorNonExclusiveItem	proc	near

	call	ItemDrawColorMotifItemBorderIfInMenu
	jnc	noOpt
	tst	ch
	jz	done
noOpt:
	push	bp
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_specState, mask OLBSS_IN_MENU
	pop	bp
	jz	notInMenu
	call	ItemDrawPMCheck		; non-exclusive in menu is a check mark
	jmp	short done
notInMenu:
	call	ItemDrawColorPMNonExclBox
	mov	ch, TRUE		; redraw moniker
done:
	ret
ItemDrawColorNonExclusiveItem	endp

endif		;PM -----------------------------------------------------------


if _OL_STYLE	;--------------------------------------------------------------

ItemDrawColorOpenLookNonExclBox	proc	near
	push	bx, cx, dx, bp, si

	push	bx
	call	GetCheckboxBounds
	pop	si			;set si (high byte) = OLBI_specS

	;	At this point:
	;	ax, bx, cx, dx = Checkbox bounds
	;	di = GState
	;	si = <OLBI_specState><OLII_state>
	;	bp = <DrawFlags><color scheme>

	push	bp

	test	si, (mask OLBSS_DEPRESSED) shl 8
	jz	notDepr

	push	ax
	andnf	bp, mask CS_darkColor		;assume dark color
	mov	ax, bp
	call	GrSetAreaColor
	pop	ax

	call	GrFillRect

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

	call	ItemDrawBottomRightEdges
	jmp	short drawInterior

notDepr:
	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	call	GrDrawHLine			; Draw the top/left edges
	call	GrDrawVLine

	push	ax
	andnf	bp, mask CS_darkColor		;assume dark color
	mov	ax, bp	
	call	GrSetLineColor
	pop	ax

	call	ItemDrawBottomRightEdges

drawInterior:
	pop	bp

	test	si, (mask OLBSS_SELECTED) shl 8
	jz	done

isSelected:
	clr	dx
	inc	ax
	sub	bx, CHECK_TOP_BORDER

	push	ax
	mov	ax, bp
	andnf	ax, mask CS_lightColor		;use light color
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	call	GrSetAreaColor
	pop	ax

	push	ds

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	mov	si, offset checkOutBM		; Clear out the part where the
	call	GrFillBitmap			;  check extends over box

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	mov	si, offset checkBM		; Draw the checkmark
	call	GrFillBitmap
	
FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	pop	ds

done:
	mov	ax, C_BLACK			; Make sure these get set
	call	GrSetTextColor
	call	GrSetLineColor
	pop	bx, cx, dx, bp, si

	ret
ItemDrawColorOpenLookNonExclBox	endp

if _FXIP		; bitmaps must be in separate resource for xip
DrawColor ends
DrawColorRegions segment resource
endif

;Bitmap to use when checkmark item set

checkBM	label	word
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

checkOutBM	label	word
	word	CHECK_WIDTH
	word	5
	byte	0, BMF_MONO
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b
	byte	00000000b, 11111000b

if _FXIP		; bitmaps must be in separate resource for xip
DrawColorRegions ends
DrawColor	segment resource
endif

endif		;OL STYLE -----------------------------------------------------

if _PM		;--------------------------------------------------------------

ItemDrawColorPMNonExclBox	proc	near
	push	bx, cx, dx, si

	mov	ax, MO_ETCH_COLOR
	call	GrSetLineColor

	push	bx
	call	GetCheckboxBounds
	pop	si			;set si (high byte) = OLBI_specState

	;	At this point:
	;	ax, bx, cx, dx = Checkbox bounds
	;	di = GState
	;	si = <OLBI_specState><OLII_state>
	;	bp = <DrawFlags><color scheme>

	call	GrDrawRect		;draw outer bounds of checkbox
	inc	ax
	inc	bx
	dec	cx
	dec	dx

	test	si, (mask OLBSS_DEPRESSED) shl 8
	jz	notDepr

	dec	cx
	dec	dx
	call	GrDrawHLine			; Draw the top/left edges
	call	GrDrawVLine
	inc	cx
	inc	dx

	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	inc	bx
	call	ItemDrawBottomRightEdges
	dec	bx
	jmp	short drawInterior

notDepr:
	inc	bx
	call	ItemDrawBottomRightEdges
	dec	bx

	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	dec	cx
	dec	dx
	call	GrDrawHLine			; Draw the top/left edges
	call	GrDrawVLine
	inc	cx
	inc	dx

drawInterior:
	test	si, (mask OLBSS_SELECTED) shl 8
	jz	done

isSelected:
	clr	dx
	dec	ax
	dec	bx

	push	ax
	mov	ax, MO_ETCH_COLOR
	call	GrSetAreaColor
	pop	ax

	push	ds

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>

	mov	si, offset checkGreyBM		; Draw the dark-grey portion
	call	GrFillBitmap			;  of the checkmark

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	mov	si, offset checkBlackBM		; Draw the black portion
	call	GrFillBitmap			;  of the checkmark

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	pop	ds

done:
	mov	ax, C_BLACK			; Make sure these get set
	call	GrSetTextColor
	call	GrSetLineColor
	pop	bx, cx, dx, si
	ret
ItemDrawColorPMNonExclBox	endp

if _FXIP		; bitmaps must be in separate resource for xip
DrawColor ends
DrawColorRegions segment resource
endif

;Bitmap to use when checkmark item set

checkBlackBM	label	word
	word	CHECK_WIDTH
	word	CHECK_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 01100000b
	byte	00000000b, 01000000b
	byte	00000000b, 11000000b
	byte	00000000b, 10000000b
	byte	00000001b, 10000000b
	byte	00111001b, 00000000b
	byte	00001111b, 00000000b
	byte	00000110b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

checkGreyBM	label	word
	word	CHECK_WIDTH
	word	CHECK_HEIGHT
	byte	0, BMF_MONO
	byte	00000000b, 00000000b
	byte	00000000b, 10100000b
	byte	00000000b, 00000000b
	byte	00000001b, 01000000b
	byte	00000000b, 00000000b
	byte	00000010b, 10000000b
	byte	00010000b, 00000000b
	byte	00001001b, 00000000b
	byte	00000100b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

if _FXIP		; bitmaps must be in separate resource for xip
DrawColorRegions ends
DrawColor segment resource
endif

endif		; if _PM ------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorMotifItemBorderIfInMenu

DESCRIPTION:	Draws border around a Motif item (excl or non-excl)
		which is in a menu, IF the BORDERED flag is set.
		(This flag is set when the item is CURSORED.)

		Important: this routine will not erase the border if it is off.
		The caller must force a full redraw of the object if the
		bordered state has just been reset.

CALLED BY:	ItemDrawColorNonExclusiveItem

PASS:		*ds:si	= instance data for object
		al = drawing flags which have changed
		bl = OLBI_moreAttrs
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
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if not _ASSUME_BW_ONLY
if _MOTIF or _PM	;-------------------------------------------------------
ItemDrawColorMotifItemBorderIfInMenu	proc	near
	;if this item is inside a menu...

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	pop	di
	jz	done			;skip if not... (carry clear)

	;if this is a FULL redraw, then don't check the delta info.

	tst	ch			;full redraw?
	jnz	10$			;skip if so...

	;partial redraw: see if BORDERED state changed

	test	al, mask OLBSS_BORDERED
	jz	done			;skip if not... (carry clear)

10$:	;the BORDERED state has changed, or this is a full redraw

	;draw the left, top, bottom, and right etch lines that make up
	;this item's border.

if DRAW_STYLES ;---------------------------------------------------------------
	;
	; draw items in menu with common routine
	;
	push	ax, bx, cx, dx
	mov	ax, ((mask DIAFF_FRAME or mask DIAFF_NO_WASH) shl 8) or \
							DS_FLAT
	test	bh, mask OLBSS_BORDERED
	jz	haveFlags
	mov	ax, ((mask DIAFF_FRAME or mask DIAFF_NO_WASH) shl 8) or \
							DS_RAISED
haveFlags:
	push	ax
	mov	ax, (DRAW_STYLE_FRAME_WIDTH shl 8) or \
					DRAW_STYLE_THIN_INSET_WIDTH
	push	ax
	call	VisGetBounds
	call	OpenDrawInsetAndFrame
	pop	ax, bx, cx, dx

else ;-------------------------------------------------------------------------

	push	ds, ax, bx, cx, dx, bp, di, si	;I am a wimp!
	call	OLButtonMovePenCalcSize	;position pen, (cx, dx) = size of button

	mov	ax, bp
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	ah, al
	test	bh, mask OLBSS_BORDERED	;is it bordered now?
	jz	20$			;skip if not... (carry clear)
MO   <	mov	ax, (C_WHITE shl 8) or MO_ETCH_COLOR			>
PMAN <	mov	ax, (MO_ETCH_COLOR shl 8) or C_WHITE			>
20$:

					;use button region definition

MO   <	mov	bp, offset NormalCBR	>
PMAN <	mov	bp, offset SystemCBR	>

	call	DrawColorButtonBorderEtchLines
	pop	ds, ax, bx, cx, dx, bp, di, si

endif ;------------------------------------------------------------------------

	stc
done:
	ret	
ItemDrawColorMotifItemBorderIfInMenu	endp

endif		;_MOTIF -------------------------------------------------------

endif		; not _ASSUME_BW_ONLY

COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorMotifNonExclBox

DESCRIPTION:	Draw Motif color non-exclusive item (small etched square)

CALLED BY:	ItemDrawColorNonExclusiveItem

PASS:		*ds:si	= instance data for object
		bp	= color scheme
		ch	= true if total redraw
		bh	= low byte of OLBI_specState
		di	= GState

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if not _ASSUME_BW_ONLY

if _MOTIF	;--------------------------------------------------------------

if not _ODIE	;--------------------------------------------------------------

ItemDrawColorMotifNonExclBox	proc	near
	push	ax, bx, cx, dx, bp, si
	call	ItemDrawColorMotifNonExclGetColors
					;returns: ah = top color,
					;al = bottom color, dl = interior color
	push	dx			; Save the interior color
	push	ax			; Save the edge colors
	clr	ah
	call	GrSetLineColor		; Set color for bottom/right
	call	GetCheckboxBounds	; Get the bounds for checkbox

	inc	ax			; Account for new smallness of box
	inc	cx			; -cbh 3/10/93

	call	ItemDrawBottomRightEdges	; Draw the bottom/right of box
	pop	bp			; Recover edge colors
	xchg	ax, bp
	xchg	al, ah			; Get the color for top/left
	clr	ah
	call	GrSetLineColor		;    and set it
	xchg	ax, bp
	dec	cx			; don't draw top line to right edge
	dec	dx			; don't draw left line to bottom
	call	GrDrawHLine		; Draw the top/left edges
	call	GrDrawVLine
	inc	dx			; restore these
	inc	cx

	pop	bp			; Recover the interior color
	xchg	ax, bp
	cmp	al, -1
	jz	done

	call	GrSetAreaColor		;    and set it
	xchg	ax, bp

	inc	ax			; used to inset 2 everywhere (3/10/93)
	inc	bx
;	dec	cx			; non needed in new graphics stuff
;	dec	dx			; 
	call	GrFillRect		; Draw the interior
done:
					; Who would know if this could be
	mov	ax, C_BLACK		;    trashed, anyway?  Not by looking
	call	GrSetLineColor		;    at the header, you couldn't.
	call	GrSetTextColor

	pop	ax, bx, cx, dx, bp, si

	ret
ItemDrawColorMotifNonExclBox	endp

else


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorOdieNonExclBox

DESCRIPTION:	Draw Odie color non-exclusive item (check box)

CALLED BY:	(INTERNAL) ItemDrawColorNonExclusiveItem

PASS:		*ds:si	= instance data for object
		bp	= color scheme
		ch	= true if total redraw
		bh	= low byte of OLBI_specState
		di	= GState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We can ignore the "ch = true if total redraw" flag since the
	interior of the Odie check box is not the same color as the
	background window so we always need to draw everything.


	get check box bounds

	set the line color to black
	draw the black one pixel bounding square

	get background colors (selected/unselected)
	use white by default if no custom colors found
	fill interior square with background colors (selected/unselected)

	if (not FLAT_STYLE) {
	    set area color to the dark color
	    fill the top-left corner region with the dark color

	    set area color to white
	    fill the bottom-right corner region with white
	}

	if (selected) {
	    set area color to the dark color
	    draw the check mark
	}


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	7/25/96		Initial revision

------------------------------------------------------------------------------@
;
; ODIE_CHECK_BOX_SUPPORTS_CUSTOM_BACKGROUND_COLORS enables support of having
; the application programmer specify custom background colors for the box 
; of a check box by using the HINT_GADGET_SECONDARY_BACKGROUND_COLORS hint.
;
; This feature is not currently desired but I'm leaving the code here 
; in case it's desired in the future.
;
ODIE_CHECK_BOX_SUPPORTS_CUSTOM_BACKGROUND_COLORS	equ	FALSE

ItemDrawColorOdieNonExclBox	proc	near
	uses	ds, si, ax, bx, cx, dx

colorScheme	local	word	push	bp ;(low byte) ColorScheme
textColors	local	word	; text colors
selected	local	byte	; non-zero if item is selected

	.enter

	;
	; Initialize the notSelected flag.
	;
	clr	al			; assume item is selected
	test	bh, mask OLBSS_SELECTED	; is item selected?
	jz	saveFlag		; nope -> save the flag
	dec	al			; item is selected
saveFlag:
	mov	ss:selected, al

	;
	; initialize text colors, default to black for both unselected
	; and selected
	;
	mov	textColors, (C_BLACK shl 8) or C_BLACK
	call	OpenGetParentTextColor	; ax = colors
	jnc	noTextColors		; didn't find any custom colors
	mov	textColors, ax		; else, use custom colors
noTextColors:

	;
	; Get the Check Box bounds.
	;
	call	GetCheckboxBounds	; ax, bx, cx, dx = Check box bounds

	;
	; Draw the one pixel black square in the interior.
	;
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor
	pop	ax
	push	ax, bx, cx, dx
	add	ax, 2
	add	bx, 2
	sub	cx, 2
	sub	dx, 2
	call	GrDrawRect
	pop	ax, bx, cx, dx

if ODIE_CHECK_BOX_SUPPORTS_CUSTOM_BACKGROUND_COLORS
	;
	; Fill the interior of the box with the background colors or use 
	; white if no custom background colors are found.
	;
	push	bp			; save locals
	push	ax			; save left coordinate
	mov	ah, ss:selected
	mov	al, 2			; get secondary background colors
	call	OpenGetExtraBackgroundColor ; al & ah <- background colors
	jc	gotColors
	;	Use white since no custom colors were found.
	mov	ax, (C_WHITE shl 8) or C_WHITE	; al & ah <- C_WHITE
gotColors:
	mov	bp, ax			; bp <- background colors
	pop	ax			; restore left coordinate

	push	ax, bx, cx, dx
	add	ax, 3
	add	bx, 3
	sub	cx, 2
	sub	dx, 2	
	call	FillRectWithTwoColors	; fill the interior of the box
	pop	ax, bx, cx, dx
	pop	bp			; restore locals
else
	;
	; Fill the interior of the box with white.
	;
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	pop	ax
	push	ax, bx, cx, dx
	add	ax, 3
	add	bx, 3
	sub	cx, 2
	sub	dx, 2	
	call	GrFillRect	; fill the interior of the box
	pop	ax, bx, cx, dx
endif	; ODIE_CHECK_BOX_SUPPORTS_CUSTOM_BACKGROUND_COLORS

	;
	; Check if we should draw the check box in the FLAT style.
	;
	push	ax, bx			; save left & top coordinates
	mov	ax, HINT_DRAW_STYLE_FLAT
	call	ObjVarFindData		; does item have the flat style hint?
	pushf				; save carry flag

FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>

NOFXIP<	segmov	ds, cs							>

	popf				; restore carry flag
	pop	ax, bx			; restore left & top coordinates
	jc	common			; yes -> skip 3D edges

	;
	; Fill the top-left corner region with the dark color.
	;
	push	ax
	mov	ax, ss:colorScheme
	andnf	ax, mask CS_darkColor
	call	GrSetAreaColor
	pop	ax
	mov	si, offset odieCheckBoxTopLeftCornerRegion
	call	GrDrawRegion

	;
	; Fill the bottom-right corner region with white.
	;
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	pop	ax
	mov	si, offset odieCheckBoxBottomRightCornerRegion
	call	GrDrawRegion

common:
	;
	; Draw the X bitmap if the item is selected.
	;
	tst	ss:selected		; is item selected?
	jz	done			; no -> skip drawing the check mark
	push	ax
	mov	ax, ss:colorScheme
	andnf	ax, mask CS_darkColor
	call	GrSetAreaColor
	pop	ax

	add	ax, 4			; draw the bitmap at the 
	add	bx, 4			;   correct location

	clr	dx			; no callback routine
	mov	si, offset checkMarkBM	; Draw the check mark
	call	GrFillBitmap

done:
	
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>

	;
	; Set the Line and Text colors as desired
	;	I'm not sure why this needs to be done but the Motif and 
	;	Open Look versions of this routine do it, so I'll do it.
	;
	mov	ax, ss:textColors
	tst	ss:selected
	jz	haveMonikerColor		; use unselected color
	mov_tr	al, ah				; use selected color
haveMonikerColor:
	clr	ah
	call	GrSetLineColor	
	call	GrSetTextColor			

	.leave
	ret
ItemDrawColorOdieNonExclBox	endp

if _FXIP		; bitmaps must be in separate resource for xip
DrawColor ends
DrawColorRegions segment resource
endif

; Region for the top-left corner of the Odie check box.
odieCheckBoxTopLeftCornerRegion	label	word
	word	0, 0, 24, 24			; bounds
	word	-1,				EOREGREC
	word	0, 0, 22,			EOREGREC
	word	1, 0, 21,			EOREGREC
	word	21, 0, 1,			EOREGREC
	word	22, 0, 0,			EOREGREC
	word	EOREGREC

; Region for the bottom-right corner of the Odie check box.
odieCheckBoxBottomRightCornerRegion	label	word
	word	0, 0, 24, 24			; bounds
	word	-1,				EOREGREC
	word	0, 23, 23,			EOREGREC
	word	21, 22, 23,			EOREGREC
	word	22, 1, 23,			EOREGREC
	word	23, 0, 23,			EOREGREC
	word	EOREGREC

; Check mark bitmap for Odie check box.
checkMarkBM	label	word
	Bitmap<16, 16, BMC_UNCOMPACTED, BMF_MONO>
	byte	11000000b, 00000011b
	byte	11100000b, 00000111b
	byte	01110000b, 00001110b
	byte	00111000b, 00011100b
	byte	00011100b, 00111000b
	byte	00001110b, 01110000b
	byte	00000111b, 11100000b
	byte	00000011b, 11000000b
	byte	00000011b, 11000000b
	byte	00000111b, 11100000b
	byte	00001110b, 01110000b
	byte	00011100b, 00111000b
	byte	00111000b, 00011100b
	byte	01110000b, 00001110b
	byte	11100000b, 00000111b
	byte	11000000b, 00000011b

if _FXIP		; bitmaps must be in separate resource for xip
DrawColorRegions ends
DrawColor	segment resource
endif

endif		; not _ODIE ---------------------------------------------------

endif		;_MOTIF -------------------------------------------------------
endif		; not _ASSUME_BW_ONLY


COMMENT @----------------------------------------------------------------------

FUNCTION:	ItemDrawColorMotifNonExclGetColors

DESCRIPTION:	Sets up colors to use to draw Motif non-exclusive items
		(small etched square)

CALLED BY:	ItemDrawColorMotifNonExclBox

PASS:		*ds:si	= instance data for object (not used)
		bp = color scheme
		ch = true if total redraw (can optimize)
		bh = low byte of OLBI_specState

RETURN:		ds, si, bx, bp = same
		ah = top color
		al = bottom color
		dx = interior color

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Chris	5/92		GenItemGroupClass V2.0 rewrite

------------------------------------------------------------------------------@

if not _ASSUME_BW_ONLY
if _MOTIF and (not _ODIE) ;----------------------------------------------------

ItemDrawColorMotifNonExclGetColors	proc	near
	mov	ax, (C_WHITE shl 8) or C_BLACK
					;Assume checkbox is "off"
					;top = C_WHITE, bottom = C_BLACK

	clr	dx
	dec	dx
	tst	ch
	jnz	canOptimize

	mov	dx, bp
	andnf	dx, mask CS_lightColor
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
canOptimize:

	test	bh, mask OLBSS_SELECTED	;is item ON?
	jz	done			;skip if not...

	xchg	al, ah			;Swap the top/bottom colors
	mov	dx, bp
	andnf	dx, mask CS_darkColor	;use dark color for interior
done:
	ret
ItemDrawColorMotifNonExclGetColors	endp

endif		;_MOTIF and (not _ODIE) ---------------------------------------
endif		; not _ASSUME_BW_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorBackground

SYNOPSIS:	Clears out the background by drawing a rectangle in the
		background color.

PASS:		bp - color scheme

RETURN:		nothing

DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ((not _ASSUME_BW_ONLY) and (not ALLOW_TAB_ITEMS))
if _OL_STYLE or _MOTIF or _PM	;-----------------------------------------------

ItemDrawColorBackground	proc	near	
	class	OLItemClass
	uses	ax, bx, cx, dx
	.enter

	mov	ax, bp
	andnf	al, mask CS_lightColor	;use light color
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	clr	ah
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect

	.leave
	ret
ItemDrawColorBackground	endp

endif		;OL STYLE or MOTIF ---------------------------------------------
endif		; not _ASSUME_BW_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawBottomRightEdges

SYNOPSIS:	Draws lines at the right vertical and bottom horizontal 
		edges.  These lines move in one pixel on the left and
		the top in order to create the effect the the top/left
		edges are the dominant edges (i.e. they are the ones drawn
		at the corner pixels).

PASS:		ax, bx, cx, dx	- bounds of the rectangle
		di - GState

RETURN:		ax, bx, cx, dx, di - preserved

DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _OL_STYLE or _MOTIF or _PM	;-------------------------------

ItemDrawBottomRightEdges	proc	near
	class	OLItemClass
	uses	ax, bx
	.enter

	inc	ax				; 
	xchg	bx, dx
	call	GrDrawHLine
	xchg	bx, dx
	mov	ax, cx
	call	GrDrawVLine

	.leave
	ret
ItemDrawBottomRightEdges	endp

endif	 ;---------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorDiamond

SYNOPSIS:	Draws the

PASS:		*ds:si	= instance data for object
		al = top color
		ah = bottom color
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = true if total redraw (can optimize)
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		nothing

DESTROYED:	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _MOTIF and (not _ODIE)	;---------------------------------------------
if not _ASSUME_BW_ONLY

;SAVE BYTES

ItemDrawColorDiamond	proc	near
	push	ds, si, ax, bx, cx, dx

	push	bp					; Save the "on" flag
	push	ax					; Save the bottom color

	clr	ah
	call	GrSetAreaColor				; Set the top color
	push	cx
	call	GetCheckboxBounds			; Get X & Y coord
	dec	bx					; Move up, to make up
	dec	ax					;  for size diff between
							;  diamonds and chkbxs?
							;  -cbh 3/10/93

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>

	call	GrMoveTo				; Place the pen
	pop	cx

	mov	si, offset itemDiamondTopRegion
	call	GrDrawRegionAtCP

	pop	ax					; Recover bottom color
	mov	al, ah					; Get bottom color
	clr	ah
	call	GrSetAreaColor				; Set the bottom color
	mov	si, offset itemDiamondBottomRegion	; Go draw the bottom
	call	GrDrawRegionAtCP			;   of the diamond

	pop	ax					; Get the "on" flag

	tst	ch
	jnz	done

	clr	ah
	call	GrSetAreaColor				; Set the bottom color
	mov	si, offset itemDiamondInRegion		; Go draw the interior
	call	GrDrawRegionAtCP			;   of the diamond
done:

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	mov	ax, C_BLACK				;    
	call	GrSetLineColor				; reset these
	call	GrSetTextColor
	pop	ds, si, ax, bx, cx, dx
	ret
ItemDrawColorDiamond	endp

endif		; not _ASSUME_BW_ONLY

if _FXIP		; regions must be in separate resource for xip
DrawColor	ends
DrawColorRegions segment resource
endif

if not _ASSUME_BW_ONLY
itemDiamondTopRegion	label	word
	word	1, 0, 10, 5				; bounds
	word	-1,				EOREGREC
	word	0, 6, 6,			EOREGREC
	word	1, 5, 5, 7, 7,			EOREGREC
	word	2, 4, 4, 8, 8,			EOREGREC
	word	3, 3, 3, 9, 9,			EOREGREC
	word	4, 2, 2, 10, 10,		EOREGREC
	word	5, 1, 1,				EOREGREC
	word	EOREGREC

itemDiamondBottomRegion	label	word
	word	2, 5, 11, 10			; bounds
	word	4,				EOREGREC
	word	5, 11, 11,			EOREGREC
	word	6, 2, 2, 10, 10,		EOREGREC
	word	7, 3, 3, 9, 9,			EOREGREC
	word	8, 4, 4, 8, 8,			EOREGREC
	word	9, 5, 5, 7, 7,			EOREGREC
	word	10, 6, 6,			EOREGREC
	word	EOREGREC

itemDiamondInRegion	label	word
	word	2, 1, 12, 9			; bounds
	word	0,				EOREGREC
	word	1, 6, 6,			EOREGREC
	word	2, 5, 7,			EOREGREC
	word	3, 4, 8,			EOREGREC
	word	4, 3, 9,			EOREGREC
	word	5, 2, 10,			EOREGREC
	word	6, 3, 9,			EOREGREC
	word	7, 4, 8,			EOREGREC
	word	8, 5, 7,			EOREGREC
	word	9, 6, 6,			EOREGREC
	word	EOREGREC

endif	; not _ASSUME_BW_ONLY

if _FXIP	; regions must be in separate resource for xip
DrawColorRegions ends
DrawColor	segment resource
endif

endif		;_MOTIF and (not _ODIE) ---------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ItemDrawColorRadioButton

SYNOPSIS:	Draws the

PASS:		*ds:si	= instance data for object
		al = top color
		ah = bottom color
		bl = OLBI_moreAttrs
		bh = OLBI_specState (low byte)
		cl = OLBI_optFlags
		ch = true if total redraw (can optimize)
		dl = GI_states
		dh = OLII_state
		bp = color scheme (from GState)
		di = GState

RETURN:		nothing

DESTROYED:	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM		;--------------------------------------------------------------

ItemDrawColorRadioButton	proc	near
	uses	ds, si
	.enter

	push	ax
	test	bh, mask OLBSS_DEPRESSED
	pushf

	mov	ax, C_LIGHT_GRAY
	call	GrSetAreaColor				;Set the bottom color
	call	GetCheckboxBounds			;Get X & Y coord
	call	GrMoveTo				;Set pen position

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>

	popf
	jnz	depressed
	mov	si, offset itemRadioButtonInRegionDepressed
	call	GrDrawRegionAtCP			;erase depressed bullet
	mov	si, offset itemRadioButtonInRegion
	jmp	short drawBullet
depressed:
	mov	si, offset itemRadioButtonInRegion	;erase undepresd bullet
	call	GrDrawRegionAtCP
	mov	si, offset itemRadioButtonInRegionDepressed
drawBullet:
	mov	ax, bp
	clr	ah
	call	GrSetAreaColor
	call	GrDrawRegionAtCP			;Go draw the interior
	pop	ax					; of the RadioButton

	mov	bx, ax					;save colors in bx
	clr	ah
	call	GrSetAreaColor				;Set the top color

	mov	si, offset itemRadioButtonTopRegion
	call	GrDrawRegionAtCP

	xchg	al, bh					;Get bottom color
	cmp	al, MO_ETCH_COLOR			;If the color we are
	pushf						;about to set is not
	jne	after					;MO_ETCH_COLOR,
	call	GrSetAreaColor				;draw the button border
after:							;before we set the
	mov	si, offset itemRadioButtonBorder	;color
	call	GrDrawRegionAtCP

	popf
	je	drawBottom
	call	GrSetAreaColor
drawBottom:
	mov	si, offset itemRadioButtonBottomRegion	;Go draw the bottom
	call	GrDrawRegionAtCP			; of the RadioButton
done:

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	mov	ax, C_BLACK
	call	GrSetAreaColor				;reset area color
	.leave
	ret
ItemDrawColorRadioButton	endp

if _FXIP 		; regions must be in separate resource for xip
DrawColor	ends
DrawColorRegions segment resource
endif

itemRadioButtonBorder		label	word
	word	0, 0, 11, 11			; bounds
	word	-1,				EOREGREC
	word	0, 3, 8,			EOREGREC
	word	1, 2, 2, 9, 9,			EOREGREC
	word	3, 1, 1, 10, 10,		EOREGREC
	word	7, 0, 0, 11, 11,		EOREGREC
	word	9, 1, 1, 10, 10,		EOREGREC
	word	10, 2, 2, 9, 9,			EOREGREC
	word	11, 3, 8,			EOREGREC
	word	EOREGREC

itemRadioButtonTopRegion	label	word
	word	1, 1, 7, 7			; bounds
	word	0,				EOREGREC
	word	1, 3, 6,			EOREGREC
	word	2, 2, 4,			EOREGREC
	word	3, 2, 3,			EOREGREC
	word	4, 1, 2,			EOREGREC
	word	7, 1, 1,			EOREGREC
	word	EOREGREC

itemRadioButtonBottomRegion	label	word
	word	4, 4, 10, 10			; bounds
	word	3,				EOREGREC
	word	6, 10, 10,			EOREGREC
	word	7, 9, 10,			EOREGREC
	word	8, 8, 9,			EOREGREC
	word	9, 7, 9,			EOREGREC
	word	10, 5, 8,	 		EOREGREC
	word	EOREGREC

itemRadioButtonInRegion	label	word
	word	3, 3, 7, 7			; bounds
	word	2,				EOREGREC
	word	3, 4, 6,			EOREGREC
	word	6, 3, 7,			EOREGREC
	word	7, 4, 6,			EOREGREC
	word	EOREGREC

itemRadioButtonInRegionDepressed	label	word
	word	4, 4, 8, 8			; bounds
	word	3,				EOREGREC
	word	4, 5, 7,			EOREGREC
	word	7, 4, 8,			EOREGREC
	word	8, 5, 7,			EOREGREC
	word	EOREGREC

if _FXIP			; regions must be in separate resource for xip
DrawColorRegions	ends
DrawColor segment resource
endif

endif		; if _PM -------------------------------------------------------

endif		; not _ASSUME_BW_ONLY

DrawColor	ends
