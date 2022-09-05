COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButtonColor.asm (color draw routines for OLButtonClass)

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		Contents split from copenButton.asm and
				lots of cleanup work.

DESCRIPTION:

	$Id: copenButtonColor.asm,v 1.76 96/12/27 21:16:38 brianc Exp $

------------------------------------------------------------------------------@

if not _ASSUME_BW_ONLY
DrawColor segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorButton

DESCRIPTION:	This procedure draws an OLButtonClass object for a
		color display.

CALLED BY:	OLButtonDraw

PASS:		*ds:si - instance data
		cl - color scheme
		ch - DrawFlags:  DF_EXPOSED set if updating
		di - GState to use

RETURN:		carry - set

DESTROYED:	ax, bx, cx, dx, si, di, bp

STRATEGY:
	The general case is to redraw the entire button.  For now, there
	are no optimizations to this since none of the states are optimizable.

	Note that we use some region definition tables in copenButtonData.asm:

	DefaultCBR:	CBR_leftTop	->	CBRdefBorderLT
			CBR_rightBottom	->	CBRdefBorderRB
			CBR_interior	->	CBRdefInterior

	NormalCBR:	CBR_leftTop	->	CBRborderLT
			CBR_rightBottom	->	CBRborderRB
			CBR_interior	->	CBRinterior

PSEUDO CODE:		UPDATE THIS PSEUDO CODE!
	if NOT UPDATE {
		GrSetAreaColor(CS_lightColor);
		draw rectangle (background for button)
	}

	calculate width and height

	if OLBSS_DEFAULT { use DefaultCBR region table } else { use NormalCBR }

	if BORDERED or [OpenLook]&DEPRESSED {
		if (not ENABLED)	{ set draw mode = 50% }
		if DEPRESSED {
			if (PM) {
				colorLT = CS_darkColor;	colorRB = C_WHITE
			} else {
				colorLT = C_BLACK;	colorRB = C_WHITE
			}
		} else {
			colorLT = C_WHITE;	colorRB = CS_darkColor
		}
		GrSetAreaColor(colorLT);
		GrDrawRegionAt(CBR_leftTop);

		GrSetAreaColor(colorRB);
		GrDrawRegionAt(CBR_rightBottom);
		set draw mode = 100%
	}
	if DEPRESSED {
		GrSetAreaColor(CS_darkColor);
		GrDrawRegionAt(CBR_interior);
	}

	if ENABLED {
		GrSetLineColor(C_BLACK);
		GrSetAreaColor(C_BLACK);
		GrSetTextColor(C_BLACK);
	} else {
		GrSetLineColor(CS_darkColor);
		GrSetAreaColor(CS_darkColor);
		GrSetTextColor(CS_darkColor);
	}

	if [OpenLook]&MENU_DOWN_MARK {
		OLButtonDrawColorMark
	}

	DrawMoniker;


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	9/89		Lots of pseudo code, CUA color code
	Eric	2/90		broken out into a dozen routines, 3 files.
	sean	6/96		Support for Selection Boxes (Odie)

------------------------------------------------------------------------------@


DrawColorButton	proc	far
	class	OLButtonClass

EC <	call	VisCheckVisAssumption	;Make sure vis data exists	>

	;first set up a bunch of registers WHICH WILL NOT CHANGE

	mov	ax, cx			;ax = DrawFlags, ColorScheme

	call	OLButtonGetGenAndSpecState
					;set bx = OLBI_specState
					;    cl = OLBI_optFlags
					;    dl = GI_state
					;    dh = VI_attrs
   	mov	dl, dh			;put VI_attrs in dl

	;Registers which will remain constant:
	;	ax = DrawFlags, ColorScheme
	;	bx = OLBI_specState
	;	di = GState
	;	dl = VI_attrs
	;	cl = OLBI_optFlags

	push	cx			;save OLBI_optFlags (in cl)

if _MOTIF and (not _ODIE) ;----------------------------------------------------
	;if this button can get the temporary default emphasis, draw using
	;different region definitions (since we made the button bigger
	;during geometry).

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	pop	di
	jz	10$			;skip if not in reply bar...

	;Use the reply bar button regions

	mov	bp, offset ReplyNormalCBR	;assume is normal button
	test	bx, mask OLBSS_DEFAULT
	jz	20$				;skip if is normal...
	mov	bp, offset ReplyDefaultCBR	;is default button
	jmp	short 20$

10$:	;Not in a reply bar, so use regular button regions

	mov	bp, offset NormalCBR		;assume is normal button
	test	bx, mask OLBSS_DEFAULT
	jz	20$				;skip if is normal...
	mov	bp, offset DefaultCBR		;is default button
20$:

if DOUBLE_BORDERED_GADGETS

	;In toolbox, act like a system icon (i.e. single border).
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	di
	jnz	24$

 	test	bx, mask OLBSS_SYS_ICON
	jz	25$				;skip if not system icon
24$:
	mov	bp, offset SystemCBR
25$:
endif
endif ; _MOTIF and (not _ODIE) ;-----------------------------------------------

if _ODIE ;---------------------------------------------------------------------
if (not DRAW_STYLES)	; don't need button regions for draw styles
	mov	bp, offset MenuCBR
	test	bx, mask OLBSS_IN_MENU_BAR or mask OLBSS_IN_MENU
	jnz	30$

	mov	bp, offset SystemCBR
	test	bx, mask OLBSS_SYS_ICON
	jz	20$

	push	ax, bx
	mov	ax, HINT_CLOSE_BUTTON
	call	ObjVarFindData
	pop	ax, bx
	jnc	30$
20$:
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	mov	bp, offset DefaultCBR
	jnz	30$

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	mov	bp, offset ToolBoxCBR
	jnz	30$

	mov	bp, offset NormalCBR
30$:
endif ; (not DRAW_STYLES)
endif	; _ODIE ---------------------------------------------------------------

if _PM		;--------------------------------------------------------------
	mov	bp, offset NormalCBR		;assume is normal button

	;In PM, the bottom line of a menu bar button is not drawn
	test	bx, mask OLBSS_IN_MENU_BAR
	jz	10$
	mov	bp, offset MenuBarCBR
	jmp	25$

10$:	test	bx, (mask OLBSS_IN_MENU) or (mask OLBSS_SYS_ICON)
	jz	12$
	mov	bp, offset SystemCBR
	jmp	25$

12$:	test	bx, mask OLBSS_MENU_DOWN_MARK
	jz	15$
	mov	bp, offset ListBoxCBR
	jmp	25$

	;In toolbox, draw a very thick border (triple border).
15$:	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	17$			;skip if not...
	mov	bp, offset DefaultCBR		;is default button
	jmp	24$

17$:	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	24$
	mov	bp, offset ToolBoxCBR
24$:	pop	di
25$:
	
endif		; if PM -------------------------------------------------------


; Don't draw borders around triggers in a toolbox, if in keyboard-only mode.
; -- Doug 2/14/92  (Changed 7/ 1/92 cbh to draw borders for menu buttons.)
; (Nuked 7/1 change -- don't want borders after all.  12/ 9/92 cbh)  {

if	1			;get rid of border junk for all (4/28/94 Joon)
	push	di		;get rid of border junk in Redwood 6/11/93 cbh
	clr	di
	pop	di
else
	push	ax, di
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	zeroToDrawBorder
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
zeroToDrawBorder:
	pop	ax, di
endif

	pushf				;save border flag
; }

if (not DRAW_STYLES)	; no optimizations for draw styles
if (not _PM)	; no optimization for PM.  PM needs to redraw everything ------

	; do an optimization if the cursor'ed state has changed

	test	ah, mask DF_EXPOSED
	jnz	noOptimization

	mov	ch, bl			;ch = current state
	xor	ch, cl			;ch = change from drawn state

;	and	ch, mask OLBOF_DRAWN_DEFAULT or mask OLBOF_DRAWN_BORDERED or \
;		    mask OLBOF_DRAWN_SELECTED or mask OLBOF_DRAWN_DEPRESSED \
;		    or mask OLBOF_DRAWN_CURSORED

	; if only BORDERED state changed then redraw border

	test	ch, mask OLBOF_DRAWN_BORDERED
	jz	noOptimization

	; even if only BORDERED state changed, we can't do optimization if
	; we are in keyboardOnly mode because the border erases the double
	; mnemonic underline drawn as part of the moinker - brianc 12/11/92

	test	bx, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR
	jz	optimize		;not in menu or menu bar, optimize
	call    OpenCheckIfKeyboardOnly
	jc	noOptimization		;keyboard only, can't do optimization
optimize:

	call	OLButtonMovePenCalcSize	;position pen, (cx, dx) = size of button
; {
	popf				;get border flag
	jnz	afterBorderDrawn
; }
	call	DrawColorButtonBorder	;draw border region
afterBorderDrawn:
	pop	ax
	ret

noOptimization:

endif		; if (not _PM) ------------------------------------------------
endif ; (not DRAW_STYLES)

MO <	call	DrawColorButtonBackground ;if not an UPDATE, then flush BG >
PMAN <	call	DrawColorButtonBackground ;if not an UPDATE, then flush BG >

	call	OLButtonMovePenCalcSize	;position pen, (cx,dx) = size of button

if DRAW_STYLES ;===============================================================

SBOX <	call	CheckIfSelectionBox					>
SBOX <	jnz	selectionBox						>
	call	DrawButtonBorderAndInterior
SBOX <selectionBox:							>

else ; ========================================================================

;--------------------------------------------------------------
					;pass cx,dx = size of button

; {
	popf				;get border flag
	pushf				;save border flag again
	jnz	afterBorderDrawn2
; }

	call	DrawColorButtonBorder	;draw border region
afterBorderDrawn2:
	call	DrawColorButtonInterior	;draw interior of button if depressed
					;or if background is garbage

endif ; DRAW_STYLES ===========================================================

SBOX <	call	DrawSelectionBoxIfNecessary	; if selection box--draw it >

	call	OLButtonSetDrawColors	;set line, area, and text color
					;according to GS_ENABLED status

	call	AdjustCurPosIfReplyPopup	
					;do horrible things to popups in reply
					;  bars here.
	call	InsetBoundsIfReplyPopup	;do horrible things to reply popups



	popf				;restore border flag
	jnz	afterMarkDrawn		;not drawing border (or mark), branch

if (not NO_MENU_MARKS)
	call	DrawColorButtonMenuMark	;if button has menu mark then draw it
endif

afterMarkDrawn:
	ANDNF	ax, mask CS_darkColor	;pass color to use if disabled
	push	si
	push	ax			;save color AND color index flag
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	mov	al, ds:[si].VI_attrs
	clr	ah
	mov	si, ax			;si = VI_attrs (low byte, high byte=0)
	pop	ax			;restore color AND color index flag
if (not DRAW_STYLES)	; don't set mono bitmap color
if (not _PM)
	call	OLButtonSetMonoBitmapColor ;set Area color in case bitmap
endif
endif
	pop	si

	pop	ax			;get OLBI_optFlags (in al)

	;determine which accessories to draw with object

	call	OLButtonSetupMonikerAttrs
					;pass info indicating which accessories
					;to draw with moniker

if CURSOR_OUTSIDE_BOUNDS
	;
	; no cursor around moniker if cursor outside bounds
	;
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			mask OLMA_SELECTION_CURSOR_ON)
elseif CURSOR_ON_BACKGROUND_COLOR
	;
	; Since we redraw the background if the cursor has turned off, we
	; don't need to erase the selection cursor in this case.
	;
	test	al, mask OLBOF_DRAWN_CURSORED
	jz	notCursorOff
	test	bx, mask OLBSS_CURSORED
	jnz	notCursorOff
	andnf	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			mask OLMA_SELECTION_CURSOR_ON)
notCursorOff:
endif

if _MOTIF or _PM	;------------------------------------------------------

	;if we are going to ERASE the selection cursor, indicate that the
	;background is light-grey instead of white.

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	45$			;skip if not...

	test	cx, mask OLMA_SELECTION_CURSOR_ON
	jnz	45$			;skip if drawing cursor...

	;Before we do anything here, let's forget about drawing the selection
	;cursor if we're a toolbox (i.e. when the cursor is inverted when drawn)
	;since we've clearly already nuked the old cursor by drawing the
	;interior.  -cbh 12/ 8/92

	test	cx, mask OLMA_USE_TOOLBOX_SELECTION_CURSOR
	jz	43$
	and	cx, not (mask OLMA_DISP_SELECTION_CURSOR or \
			 mask OLMA_SELECTION_CURSOR_ON or \
		         mask OLMA_USE_LIST_SELECTION_CURSOR or \
		         mask OLMA_USE_CHECKBOX_SELECTION_CURSOR)
	jmp	short 45$
43$:

	;Motif: Pass color info in OLMonikerFlags so that OpenDrawMoniker
	;knows how to draw the selection cursor.

	ORNF	cx, mask OLMA_LIGHT_COLOR_BACKGROUND

45$:
endif		;--------------------------------------------------------------

if CURSOR_ON_BACKGROUND_COLOR and (not CURSOR_OUTSIDE_BOUNDS)	;--------------

	push	di, si			; save gstate, object chunk
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax			; use obj color, use unsel color
	test	bx, mask OLBSS_DEPRESSED	; al non-zero if depressed
	jz	3$
	dec	al
3$:
	mov	si, ds:[di].OLBI_genChunk	; si = chunk handle of gen part
	call	OpenSetCursorColorFlags		; cx = updated OLMA
	pop	di, si			; di = gstate, *ds:si = button

endif	; CURSOR_ON_BACKGROUND_COLOR and (not CURSOR_OUTSIDE_BOUNDS) ----------

	;Draw moniker offset in X and centered in Y

if _MOTIF	;--------------------------------------------------------------
	push	di
if DRAW_STYLES
	;
	; center sys icon monikers
	;
	mov	al, (J_CENTER shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
else
	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
endif

;	mov	dx, MO_BUTTON_INSET_Y shl 8	
	clr	dx				;Maximize moniker space to
						;allow express menu buttons
						;to draw themselves completely.
						;-cbh 11/ 3/92
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = specificInstance
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	55$				;system icon, branch
						;(ignore toolbox flag! 12/21/92

if _ODIE
	;
	; if IC_OK trigger, center moniker as we made button wider than
	; necessary
	;
	push	bx
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData
	mov	ax, {InteractionCommand}ds:[bx]
	pop	bx
	jnc	notOK
	cmp	ax, IC_OK
	mov	al, (J_CENTER shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
	je	55$				; use centered moniker
notOK:
endif

if DRAW_STYLES
	;
	; left justify non-sys icon monikers
	;
	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
endif

ODIE <	mov	dl, MO_MENU_ITEM_INSET_X				>
ODIE <	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU		>
ODIE <	jnz	55$				;use menu item inset	>

if DRAW_STYLES
	;
	; moniker X inset for regular, focusable buttons
	;
EC <	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
			mask OLBSS_IN_MENU_BAR or mask OLBSS_SYS_ICON	>
EC <	ERROR_NZ	OL_ERROR					>
	mov	dl, OUTSIDE_CURSOR_MARGIN
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	jz	noXBorder
	add	dl, BUTTON_MONIKER_X_MARGIN+DRAW_STYLE_FRAME_WIDTH
noXBorder:
	cmp	ds:[di].OLBI_drawStyle, DS_FLAT
	je	noXInset
	add	dl, DRAW_STYLE_INSET_WIDTH
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	jnz	noXInset			; margin already added
	add	dl, BUTTON_MONIKER_X_MARGIN
noXInset:
else
	mov	dl, MO_BUTTON_INSET_X		;If not system icon, use margin
endif

50$:
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	55$
if DRAW_STYLES
	;
	; moniker X and Y insets for toolbox buttons
	;
	mov	dx, (BUTTON_MONIKER_Y_TOOLBOX_MARGIN shl 8) or \
						BUTTON_MONIKER_X_TOOLBOX_MARGIN
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	jz	noToolBorder
	add	dx, (DRAW_STYLE_FRAME_WIDTH shl 8) or DRAW_STYLE_FRAME_WIDTH
noToolBorder:
	cmp	ds:[di].OLBI_drawStyle, DS_FLAT
	je	noToolInset
	add	dx, (DRAW_STYLE_INSET_WIDTH shl 8) or DRAW_STYLE_INSET_WIDTH
noToolInset:
else
	mov	dx, (BUTTON_TOOLBOX_Y_INSET shl 8) or BUTTON_TOOLBOX_X_INSET
endif
55$:

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	60$				;skip if not...

	;Compensate for larger margins
if DRAW_STYLES
	;
	; increase moniker X and Y insets for default ring
	;
	add	dx, (DRAW_STYLE_DEFAULT_WIDTH shl 8) or \
					DRAW_STYLE_DEFAULT_WIDTH
else
	add	dx, (MO_REPLY_BUTTON_INSET_Y shl 8) or MO_REPLY_BUTTON_INSET_X
endif
60$:
	pop	di
endif		;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------
	push	di
	mov	al, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
	mov	dx, 2				;assume system icon, INSET_X=2
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = specificInstance
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	50$

	mov	dl, MO_BUTTON_INSET_X		;If not system icon, use margin

50$:	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	55$
	mov	dx, (BUTTON_TOOLBOX_Y_INSET shl 8) or BUTTON_TOOLBOX_X_INSET

55$:	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	60$				;skip if not...

	; Compensate for larger margins
	add	dx, (MO_REPLY_BUTTON_INSET_Y shl 8) or  MO_REPLY_BUTTON_INSET_X

60$:	test	bx, mask OLBSS_MENU_DOWN_MARK	; Don't shift moniker if we
	jnz	70$				; have a menu down mark.

65$:	test	bx, mask OLBSS_DEPRESSED	; If depressed, we shift the
	jz	70$				; moniker to the right
	inc	dl				; one pixel.

70$:	pop	di
endif		;--------------------------------------------------------------
					;pass al = DrawMonikerFlags,
					;cx = OLMonikerAttrs
	call	OLButtonDrawMoniker
	ret
DrawColorButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawButtonBorderAndInterior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw button border and wash interior

CALLED BY:	INTERNAL
			DrawColorButton
PASS:		*ds:si = button
		di = gstate
		bx = OLButtonSpecState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DRAW_STYLES

DrawButtonBorderAndInterior	proc	near
	uses	ax, bx, cx, dx
specState	local	OLButtonSpecState	push	bx
fixedAndMore	local	word			; low byte = OLButtonFixedAttrs
						; high byte = OLButtonMoreAttrs
drawStyle	local	word			; check low byte only
	.enter
	;
	; wash button interior
	;
	push	di				; save gstate
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
.assert (offset OLBI_moreAttrs eq (offset OLBI_fixedAttrs)+1)
	mov	ax, {word}ds:[di].OLBI_fixedAttrs
	mov	fixedAndMore, ax
	mov	al, ds:[di].OLBI_drawStyle
	mov	drawStyle, ax
	clr	ax				; not selected, etc.
;allow 3D buttons to use selected color if we've got custom colors
;-- brianc 9/10/96
	push	ax, bx, si
	mov	si, ds:[di].OLBI_genChunk
	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData
	pop	ax, bx, si
	jc	checkSelected
	cmp	drawStyle.low, DS_FLAT		; not custom colors, only
	jne	notSelected			;	flat inverts
checkSelected:
	test	specState, mask OLBSS_DEPRESSED
	jz	notSelected
	dec	al				; flat depressed button, use
						;	selected color
notSelected:
	test	specState, mask OLBSS_SYS_ICON
	jnz	haveColorFlag			; sys icon, always dark grey
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	haveColorFlag
	dec	ah				; use selBkgdColor in this case
haveColorFlag:
	push	si				; save button chunk
	mov	si, ds:[di].OLBI_genChunk
	call	OpenGetBackgroundColor		; colors in ax
	pop	si				; *ds:si = button
	pop	di				; di = gstate
	push	ax				; save one color
	call	fillInterior
	pop	ax				; get color back
	cmp	al, ah				; same color?
	je	washDone			; yes, we're done.
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	al, ah
	call	fillInterior
	mov	al, SDM_100
	call	GrSetAreaMask
washDone:
	;
	; draw border
	;
	mov	ax, ((mask DIAFF_NO_WASH or mask DIAFF_FRAME or \
			mask DIAFF_FRAME_OUTSIDE) shl 8) or DS_FLAT
	cmp	drawStyle.low, DS_FLAT
	je	haveDrawStyle
	mov	ax, ((mask DIAFF_NO_WASH or mask DIAFF_FRAME or \
			mask DIAFF_FRAME_OUTSIDE) shl 8) or \
				DS_RAISED
	test	specState, mask OLBSS_DEPRESSED
	jz	haveDrawStyle
	mov	ax, ((mask DIAFF_NO_WASH or mask DIAFF_FRAME or \
			mask DIAFF_FRAME_OUTSIDE) shl 8) or \
				DS_LOWERED
haveDrawStyle:
	test	specState, mask OLBSS_BORDERED
	jnz	haveBordered
	andnf	ah, not mask DIAFF_FRAME
haveBordered:
	push	ax
	mov	ax, (DRAW_STYLE_FRAME_WIDTH shl 8) or DRAW_STYLE_INSET_WIDTH
	test	specState, mask OLBSS_DEFAULT
	jz	noDefaultRing
	mov	ax, ((DRAW_STYLE_FRAME_WIDTH+DRAW_STYLE_DEFAULT_WIDTH) shl 8) or DRAW_STYLE_INSET_WIDTH
noDefaultRing:
	test	specState, mask OLBSS_SYS_ICON
	jz	notSysIcon
						; the only sys icon we'll
	mov	al, DRAW_STYLE_THIN_INSET_WIDTH	;	draw is close button
notSysIcon:
	push	ax
	call	getVisBounds
	test	fixedAndMore.low, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	afterDefault
	test	specState, mask OLBSS_DEFAULT
	jnz	afterDefault
	call	insetForDefault
afterDefault:
	call	OpenDrawInsetAndFrame
	;
	; draw focus indicator (cursor) if needed
	;	*ds:si = button
	;	di = gstate
	;
if CURSOR_OUTSIDE_BOUNDS
	test	specState, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR or \
						mask OLBSS_SYS_ICON
	jnz	done
	test	specState, mask OLBSS_CURSORED
	jz	done
	call	getVisBounds			; bounds around which to draw
						;	cursor
	;
	; if in reply bar but cannot be default, inset to avoid two-pixel
	; gutter for focus ring, as we've left room for the non-existant
	; default ring
	;
	test	fixedAndMore.low, mask OLBFA_IN_REPLY_BAR
	jz	drawCursor
	test	fixedAndMore.low, mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jnz	drawCursor
	call	insetForDefault
drawCursor:
	call	OpenDrawOutsideCursor
done:
endif
	.leave
	ret

getVisBounds	label	near
	call	VisGetBounds
if CURSOR_OUTSIDE_BOUNDS
	test	fixedAndMore.high, mask OLBMA_IN_TOOLBOX
	jnz	notFocusable
	test	specState, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR or \
					mask OLBSS_SYS_ICON
	jnz	notFocusable
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
notFocusable:
endif
	;
	; if we are a sys icon and bordered, then bump out the bounds
	; so the border overlaps the title bar border
	;
	test	specState, mask OLBSS_SYS_ICON
	jz	returnBounds
	test	specState, mask OLBSS_BORDERED
	jz	returnBounds
	dec	ax
	dec	bx
	inc	cx
	inc	dx
returnBounds:
	retn

insetForDefault	label	near
	add	ax, DRAW_STYLE_DEFAULT_WIDTH
	add	bx, DRAW_STYLE_DEFAULT_WIDTH
	sub	cx, DRAW_STYLE_DEFAULT_WIDTH
	sub	dx, DRAW_STYLE_DEFAULT_WIDTH
	retn

;
; pass:	al = color
;
fillInterior	label	near
	clr	ah
	call	GrSetAreaColor
	call	getVisBounds
	test	fixedAndMore.low, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	cantBeDefault
	call	insetForDefault
cantBeDefault:
	call	GrFillRect
	retn
DrawButtonBorderAndInterior	endp

endif ; DRAW_STYLES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionBoxIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a selection box, let's draw it here.

CALLED BY:	DrawColorButton

PASS:		*ds:si	= OLButton
		^hdi	= GState

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
      if(selection box)
	Draw black inset border
	Draw white background selection field
	Draw selection arrows	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawSelectionBoxIfNecessary	proc	near
	.enter

	call	CheckIfSelectionBox
	jz	exit
	call	DrawSelectionBox
exit:
	.leave
	ret

DrawSelectionBoxIfNecessary	endp

DrawSelectionBox		proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	call	DrawSelectionBoxBorder

	call	DrawSelectionBoxOutline		; ax,bx,cx,dx = center bounds

	; Draw white background of the box in between the two
	; arrow boxes.  This center box is where the moniker lies.
	;
	call	DrawSelectionBoxMonikerBackground

	; Draw selection box arrows.  First we find out the bounds of
	; these arrow boxes, and then draw them either depressed or
	; not.
	;
	call	SelectionBoxGetPrevArrowBoundsFar  ; ax,bx,cx,dx = bounds
	push	di				; save GState
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	bp, ((AT_ARROW_DEPRESSED shl 8) or AT_PREV_ARROW)
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_PREV_ARROW_DOWN
	jnz	prevArrowDepressed	
	mov	bp, ((AT_ARROW_NOT_DEPRESSED shl 8) or AT_PREV_ARROW)	
prevArrowDepressed:
	pop	di
	call	DrawSelectionBoxArrow	

	call	SelectionBoxGetNextArrowBoundsFar  ; ax,bx,cx,dx = bounds
	push	di				; save GState
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	bp, ((AT_ARROW_DEPRESSED shl 8) or AT_NEXT_ARROW)
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_NEXT_ARROW_DOWN
	jnz	nextArrowDepressed
	mov	bp, ((AT_ARROW_NOT_DEPRESSED shl 8) or AT_NEXT_ARROW)
nextArrowDepressed:	
	pop	di
	call	DrawSelectionBoxArrow
if CURSOR_OUTSIDE_BOUNDS
	;
	; draw focus indicator (cursor) for selection box if needed
	;	*ds:si = selection box
	;	di = gstate
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLBI_specState, mask OLBSS_CURSORED
	jz	done
	call	VisGetBounds
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
	call	OpenDrawOutsideCursor
done:
endif
	
	.leave
	ret

DrawSelectionBox	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionBoxBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws lowered 3-D border for selection box if 
		selection box is bordered (i.e. no HINT_DRAW_STYLE_FLAT)

CALLED BY:	DrawSelectionBox

PASS:		*ds:si	= OLMenuButton
		^hdi	= GState

RETURN:		nothing	

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawSelectionBoxBorder	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLMBI_odieFlags, mask OLMBOF_BORDERED_SELECTION_BOX
	jnz	drawBorder
exit:
	.leave
	ret

drawBorder:
	mov	ax, (mask DIAFF_NO_WASH shl 8) or DS_LOWERED
	push	ax
	mov	ax, DRAW_STYLE_INSET_WIDTH		; 2 pixels
	push	ax
	call	VisGetBounds
if CURSOR_OUTSIDE_BOUNDS
	;
	; adjust selection box bounds for outside cursor
	;
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
endif
	call	OpenDrawInsetAndFrame
	jmp	exit

DrawSelectionBoxBorder	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionBoxOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws outline of selection box, as well as the outline
		of the selection box's arrow boxes.

CALLED BY:	DrawSelectionBox

PASS:		*ds:si	= OLMenuButton
		^hdi	= GState

RETURN:		ax,bx,cx,dx = bounds of center moniker box

DESTROYED:	nothing

SIDE EFFECTS:	Sets the line color in the GState

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawSelectionBoxOutline	proc	near

verticalFlag	local	BooleanByte	
borderedFlag	local	BooleanByte

	uses	si,di,bp
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass			>
EC <	Assert	gstate		di					>

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor

	mov	ss:[verticalFlag], BB_TRUE
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	checkBorder
	mov	ss:[verticalFlag], BB_FALSE

checkBorder:
	mov	ss:[borderedFlag], BB_TRUE
	test	ds:[bx].OLMBI_odieFlags, mask OLMBOF_BORDERED_SELECTION_BOX
	jnz	getBounds
	mov	ss:[borderedFlag], BB_FALSE	

getBounds:
	call	VisGetBounds			; ax,bx,cx,dx = bounds
if CURSOR_OUTSIDE_BOUNDS
	;
	; adjust selection box bounds for outside cursor
	;
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bx, OUTSIDE_CURSOR_MARGIN
	sub	cx, OUTSIDE_CURSOR_MARGIN
	sub	dx, OUTSIDE_CURSOR_MARGIN
endif
	dec	cx
	dec	dx				; ax,bx,cx,dx = drawing bounds

	cmp	ss:[borderedFlag], BB_TRUE
	jne	noBorder			

	add	ax, SELECTION_BOX_BORDER
	add	bx, SELECTION_BOX_BORDER
	sub	cx, SELECTION_BOX_BORDER
	sub	dx, SELECTION_BOX_BORDER

noBorder:
	call	GrDrawHLine			; draw top line
	call	GrDrawVLine			; draw left line
	push	bx				; save top coordinate
	mov	bx, dx				; bx = bottom
	call	GrDrawHLine			; draw bottom line
	pop	bx				; restore top coordinate
	push	ax				; save left coordinate
	mov	ax, cx				; ax = right coordinate
	call	GrDrawVLine			; draw right line
	pop	ax				; restore left coordinate

	cmp	ss:[verticalFlag], BB_TRUE
	je	arrowsTopAndBottom

	; Horizontal selection boxes have their arrow boxes on the
	; left & right.  So we draw the outline of these arrow boxes.
	;
	push	ax				; save left coordinate
	sub	cx, SELECTION_BOX_ARROW_WIDTH + 1 
	mov	ax, cx
	call	GrDrawVLine			; draw right arrow box line
	pop	ax				; restore left coordinate
	add	ax, SELECTION_BOX_ARROW_WIDTH + 1  
	call	GrDrawVLine			; draw left arrow box line
	jmp	exit

arrowsTopAndBottom:
	push	bx				; save top coordinate
	sub	dx, SELECTION_BOX_ARROW_HEIGHT + 1
	mov	bx, dx
	call	GrDrawHLine			; draw bottom arrow box line
	pop	bx				; restore top coordinate
	
	add	bx, SELECTION_BOX_ARROW_HEIGHT + 1
	call	GrDrawHLine			; draw top arrow box line
exit:
	.leave
	ret
DrawSelectionBoxOutline	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionBoxMonikerBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the selection box white background for 
		the center moniker box in between the two arrow boxes.

CALLED BY:	DrawSelectionBoxIfNecessary

PASS:		ax,bx,cx,dx	= bounds for center moniker box
		^hdi	= GState

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	sets the area color in the gstate

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawSelectionBoxMonikerBackground	proc	near
	.enter

EC <	Assert	gstate		di				>

	push	ax			; save left coordinate
	mov	al, SBBG_MONIKER_BACKGROUND
	call	GetSelectionBoxBackgroundColor	; ax = color
	call	GrSetAreaColor		; set area color white
	pop	ax			; restore left coordinate

	inc	ax			
	inc	bx			; fudge bounds
	call	GrFillRect		; fill background

	.leave
	ret
DrawSelectionBoxMonikerBackground	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionBoxArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the arrow boxes at the ends of the selection box.

CALLED BY:	DrawSelectionBoxIfNecessary

PASS:		*ds:si		= menu button
		ax,bx,cx,dx 	= rectangular bounds of selection arrow box
		^hdi		= GState
		bp (high)	= ArrowType enum for depressed status
		bp (low)	= ArrowType enum for next/prev arrow

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Sets area color & line color in GState

PSEUDO CODE/STRATEGY:
		Wash background arrow box color
		Draw arrow bitmap within box
		Draw raised/lowered outline

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawSelectionBoxArrow	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass			>
EC <	Assert	gstate		di					>

	push	ax, bx			; save left/top coordinate

	; wash the background of the arrow box with the 
	; correct color.
	;
	mov	bx, bp			
	mov	al, SBBG_ARROW_BOX
	cmp	bh, AT_ARROW_NOT_DEPRESSED
	je	setBackgroundColor
	mov	al, SBBG_ARROW_BOX_SELECTED
setBackgroundColor:
	call	GetSelectionBoxBackgroundColor	; ax = background color
	call	GrSetAreaColor		; set area color 
	pop	ax, bx			; restore left coordinate

	call	GrFillRect		; fill background

	call	DrawArrow			; draw arrow bitmap

	push	bx				; save top coordinate
	mov	bx, bp				; bx = arrow info
EC <	Assert	etype	bh, ArrowType				>
EC <	Assert	etype	bl, ArrowType				>	
	mov	bp, (mask DIAFF_NO_WASH shl 8) or DS_LOWERED
	cmp	bh, AT_ARROW_DEPRESSED	
	je	setTLColor			
	mov	bp, (mask DIAFF_NO_WASH shl 8) or DS_RAISED
setTLColor:
	pop	bx				; restore top coordinate
	push	bp
	mov	bp, DRAW_STYLE_FRAME_WIDTH		; 1 pixels
	push	bp
	call	OpenDrawInsetAndFrame


	.leave
	ret

DrawSelectionBoxArrow	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionBoxBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns background color for various parts of the
		selection box.

CALLED BY:	DrawSelectionBoxArrow

PASS:		*ds:si	= OLMenuButton object
		al	= SelectionBoxBackground

RETURN:		ax	= color of background

DESTROYED:	none

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	9/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
GetSelectionBoxBackgroundColor	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass			>
EC <	Assert	etype 	al, SelectionBoxBackground			> 

	mov	cl, al			; cl = SelectionBoxBackground

	call	GetMenuButtonsItemGroupFar	; *ds:si = item group parent
	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData		; carry set = hint found
	jc	customBackgroundColors

defaultColors:
	mov	ax, (CF_INDEX shl 8) or C_WHITE		; moniker
	cmp	cl, SBBG_MONIKER_BACKGROUND
	je	exit
	mov	ax, (CF_INDEX shl 8) or C_LIGHT_GREY	; arrow box

exit:
EC <	Assert	etype	al, Color					>

	.leave
	ret

	; There are two BackgroundColor structs in the extra
	; data for the selection box.  The first struct is for the 
	; moniker background color.  The second is for the arrow
	; boxes.  If there is only one BackgroundColor struct, then
	; the programmer is only specifying the moniker background
	; color.
	;
customBackgroundColors:
	mov	ah, CF_INDEX
	mov	al, ds:[bx].BC_unselectedColor1
	cmp	cl, SBBG_MONIKER_BACKGROUND
	je	exit
	VarDataSizePtr	ds, bx, dx
	cmp	dx, size BackgroundColors
	je	defaultColors
EC <	cmp	dx, (2 * (size BackgroundColors))		>
EC <	ERROR_NE	WRONG_NUMBER_OF_BACKGROUND_COLORS	>
	add	bx, size BackgroundColors		; go to second struct
	mov	al, ds:[bx].BC_unselectedColor1
	cmp	cl, SBBG_ARROW_BOX
	je	exit
	mov	al, ds:[bx].BC_selectedColor1
	jmp	exit
	
GetSelectionBoxBackgroundColor	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws arrow bitmap for selection box.

CALLED BY:	DrawSelectionBoxArrow

PASS:		*ds:si	= menu button
		^hdi	= GState
		ax,bx,cx,dx	= bounds of box that arrow is drawn in
		bp (high)	= ArrowType enum for depressed status
		bp (low)	= ArrowType enum for next/prev arrow

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Calculate x,y position for drawing arrow bitmap
		Determine which bitmap to use
		Draw bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
DrawArrow	proc	near
	uses	ax, bx, cx, dx, si, bp, ds
	.enter

EC <	Assert	objectPtr	dssi, OLMenuButtonClass			>
EC <	Assert	gstate		di					>

	call	CheckIfDrawingDisabled		
	
	call	CalculateArrowBitmapCoordinates	; cx, dx = bitmap coordinates

	mov	ax, bp				; ax = arrow info
EC <	Assert	etype	ah, ArrowType				>
EC <	Assert	etype	al, ArrowType				>

	; Get bitmap.
	;
	mov	bx, handle	UArrowMoniker	
	push	di				; save GState
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	verticalBox

	; We know it's horizontal, but we have to check if we're
	; drawing the previous (left arrow) or next (right arrow).
	;
	mov	si, offset	LArrowMoniker	; horizontal/prev arrow
	cmp	al, AT_PREV_ARROW		; prev arrow
	je	loadBitmap			; yes--load bitmap
	mov	si, offset	RArrowMoniker	; horizontal/next arrow
	jmp	loadBitmap

verticalBox:
	mov	si, offset	UArrowMoniker	; vertical/prev arrow
	cmp	al, AT_PREV_ARROW		; prev arrow
	je	loadBitmap			; yes--load bitmap
	mov	si, offset	DArrowMoniker	; vertical/next arrow

loadBitmap:
	pop	di				; restore GState

	call	MemLock				; lock bitmap block
	mov	ds, ax
	mov	si, ds:[si]			; ds:si	= bitmap
	push	bx				; save handle
	movdw	axbx,cxdx			; ax, bx = bitmap coordinates
	clr	dx				; no callback
	call	GrDrawBitmap
	
	pop	bx				; restore handle
	call	MemUnlock			; unlock bitmap block

	mov	al, SDM_100		
	call	GrSetAreaMask			; restore area mask

	.leave
	ret

DrawArrow	endp
endif		; if SELECTION_BOX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfDrawingDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set draw mask if we're drawing this button disabled

CALLED BY:	DrawArrow

PASS:		*ds:si	= OLMenuButton
		^hdi	= GState
		bp (high)	= ArrowType enum for depressed status
		bp (low)	= ArrowType enum for next/prev arrow

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	Can set area mask of GState

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
CheckIfDrawingDisabled	proc	near
	uses	ax,si
	.enter

	mov	ax, bp				; ax = arrow info
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	cmp	al, AT_PREV_ARROW
	je	prevArrow

	; Next arrow--see if next arrow is disabled.
	;	
	test	ds:[si].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_NEXT_DISABLED
	jnz	drawDisabled
exit:
	.leave
	ret

	; Previous arrow--see if previous arrow is disabled
	;
prevArrow:
	test	ds:[si].OLMBI_odieFlags, mask OLMBOF_SELECTION_BOX_PREV_DISABLED
	jz	exit

	; Set area mask for drawing disabled
	;
drawDisabled:
	mov	al, SDM_VERTICAL
	test	ds:[si].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jz	setMask
	mov	al, SDM_HORIZONTAL
setMask:
	call	GrSetAreaMask
	jmp	exit

CheckIfDrawingDisabled	endp
endif		; if SELECTION_BOX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateArrowBitmapCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns coordinates to draw arrow

CALLED BY:	DrawArrow

PASS:		*ds:si		= menu button
		ax,bx,cx,dx 	= arrow box bounds

RETURN:		cx, dx	= (x,y) coordinate to draw bitmap

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
CalculateArrowBitmapCoordinates	proc	near
	uses	ax,bx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_VERTICAL_SELECTION_BOX
	jnz	vertical

	mov	cx, ax
	add	cx, 2				; cx = x-coordinate

	sub	dx, bx				; dx = height
	shr	dx, 1				; divide by 2 = midpoint
	add	dx, bx
	sub	dx, (HORIZONTAL_ARROW_BITMAP_HEIGHT / 2)
	jmp	exit
	
vertical:
	mov	dx, bx
	inc	dx				; add 1, dx = y-coordinate

	sub	cx, ax				; cx = width
	shr	cx, 1				; divide by 2 = midpoint
	add	cx, ax
	sub	cx, (VERTICAL_ARROW_BITMAP_WIDTH / 2)
exit:
	.leave
	ret
CalculateArrowBitmapCoordinates	endp

endif		; if SELECTION_BOX


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorButtonBackground

DESCRIPTION:	Draw the background of the button.

CALLED BY:	DrawColorButton

PASS:		*ds:si	= instance data for OLButtonClass object
		ax	= DrawFlags, ColorScheme
		bx	= OLBI_specState (attributes for button)
		di	= GState
		cs:bp	= region set for button

		if _MOTIF
			cl	= OLBI_optFlags
			dl 	= VI_attrs
		endif

		if _PM
			cl	= OLBI_optFlags
			dl 	= VI_attrs
		endif

		if _OPEN_LOOK
			cx, dx	= size of button
		endif

RETURN:		ax, bx, cx, dx, si, di = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:
	if not an update then clear to background color

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

DrawColorButtonBackground	proc	near
	push	ax, bx, cx, dx

	test	ah, mask DF_EXPOSED	;is this an update?
	jnz	done			;skip if so...

if _MOTIF or _PM;--------------------------------------------------------------
	;the button has just changed state: if the only difference is that
	;it is no longer CURSORED, then do not redraw the background.

	test	cl, mask OLBOF_DRAW_STATE_KNOWN
	jz	redrawBackground

	mov	ch, dl			;ch = VI_attrs
	xor	ch, cl			;ch = VI_attrs XOR OLBI_optFlags
	test	ch, mask OLBOF_ENABLED
	jnz	redrawBackground	;skip if ENABLED status changed...

if CURSOR_ON_BACKGROUND_COLOR and (not CURSOR_OUTSIDE_BOUNDS)
	;
	; If cursor turned off, redraw to support non-standard gadget
	; background colors.
	;
	test	ch, mask OLBOF_DRAWN_CURSORED
	jz	notCursorOff
	test	bx, mask OLBSS_CURSORED
	jz	redrawBackground
notCursorOff:
endif
	
	mov	dl, bl
	xor	dl, cl
if CURSOR_OUTSIDE_BOUNDS
	;
	; if cursor state changed, must redraw background to show new
	; cursor state
	;
	test	dl, mask OLBOF_DRAWN_CURSORED
	jnz	redrawBackground	; redraw if cursor status changed
endif
	test	dl, mask OLBSS_BORDERED or mask OLBSS_DEFAULT or \
		    mask OLBSS_DEPRESSED or mask OLBSS_SELECTED

	jz	done			;skip if none of these changed (i.e.
					;OLBSS_CURSORED may have changed)...
endif		;--------------------------------------------------------------

redrawBackground:
	;In OpenLook, if this button sits on the header area of the focused
	;application, then we know it sits on a dark-grey area. If the
	;button is not selected, draw interior using a region, so that
	;we don't erase outside the border.

if CURSOR_OUTSIDE_BOUNDS
	;
	; deal with background color on parent, etc.
	;
	call	OpenGetWashColors		; ax = wash colors
	push	ax				; save mask color
	clr	ah
	call	GrSetAreaColor			; set main color
	call	VisGetBounds
	call	GrFillRect
	pop	ax
	cmp	al, ah				; any mask color?
	je	done
	mov	al, ah
	clr	ah
	call	GrSetAreaColor			; set mask color
	mov	al, SDM_50
	call	GrSetAreaMask
	call	VisGetBounds
	call	GrFillRect
	mov	al, SDM_100
	call	GrSetAreaMask
else
	ANDNF	al, mask CS_lightColor	;use light color
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	clr	ah
	call	GrSetAreaColor
MO <	call	VisGetBounds						>
MO <	call	GrFillRect						>
PMAN <	call	VisGetBounds						>
PMAN <	call	GrFillRect						>
endif
   
done:
	pop	ax, bx, cx, dx
	ret
DrawColorButtonBackground	endp

if (not DRAW_STYLES)	; not needed with draw styles border/interior drawing


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorButtonBorder

DESCRIPTION:	Draw the border of the button.

CALLED BY:	DrawColorButton

PASS:		ax	= DrawFlags, ColorScheme
		bx	= OLBI_specState (attributes for button)
		cx, dx	= size of button
		*ds:si	= object
		di	= GState
		cs:bp	= region set for button

RETURN:		ax, bx, cx, dx, si, di = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	sean	7/96		Changes for selection boxes (Odie)

------------------------------------------------------------------------------@

DrawColorButtonBorder	proc	near

	; If we're a selection box, then don't draw the borders, since
	; we do this manually.  This seems to be much easier than
	; trying to keep track of all the hacks & places where
	; OLBSS_BORDERED is messed with.  sean 7/23/96.
	;
if	SELECTION_BOX 
	call	CheckIfSelectionBox
	jnz	exit
endif	; if SELECTION_BOX

	push	si, ax
	test	bx, mask OLBSS_BORDERED
	jnz	isBordered

	; Optimization by tony, 10/2/90

	test	ah, mask DF_EXPOSED
	jnz	afterBorder
	ANDNF	al, mask CS_lightColor		;use light color
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	mov	ah, al
	jmp	short drawBorder		;pass al = colors to use
isBordered:

if (not _DRAW_DISABLED_BUTTONS_WITH_SOLID_BORDER)
	;button is bordered

	call	OpenButtonCheckIfFullyEnabled
	jc	isBorderedAndEnabled		;skip if enabled...

	mov	al, SDM_50			;not enabled: set for 50%
	call	GrSetAreaMask			;pattern drawing
endif

isBorderedAndEnabled: ;assume button is depressed, set colors for edges, etc.

MO   <	mov	ax, (C_BLACK shl 8) or C_WHITE	;ah = colorLT, al = colorRB  >
PMAN <	mov	ax, (MO_ETCH_COLOR shl 8) or C_WHITE ;ah=colorLT, al=colorRB >

	test	bx, mask OLBSS_DEPRESSED
	jnz	drawBorder			;skip if depressed...

	;button is not depressed: set colors for edges, etc.

	pop	ax				; get color scheme passed
	push	ax
	ANDNF	ax, mask CS_darkColor		;use dark color		
	ORNF	ax, (C_WHITE shl 8)		;bh = colorLT, bl = colorRB

drawBorder:
	;registers:
	;	cs:bp = region set for button
	;	ah = color for left and top edges
	;	al = color for right and bottom edges
	;	cx, dx	= size of button
	;	di	= GState
	;	pen position set at top-left of button

	call	DrawColorButtonBorderEtchLines

	mov	al, SDM_100
	call	GrSetAreaMask

afterBorder:
	pop	si, ax
exit::
	ret
DrawColorButtonBorder	endp

;draw the left, top, bottom, and right etch lines that make up a color
;button's border. Also used by OLSettingClass, for non-excl and excl settings
;in menus.

DrawColorButtonBorderEtchLines	proc	near
	;registers:
	;	cs:bp = region set for button
	;	ah = color for left and top edges
	;	al = color for right and bottom edges
	;	cx, dx	= size of button
	;	di	= GState
	;	pen position set at top-left of button

	push	ds

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	push	ax
	mov	al, ah			;ax = colorLT
	and	al, 0xf			; isolate color 
	clr	ah
	call	GrSetAreaColor

	mov	si, ds:[bp].CBR_leftTop	;pass ds:si = region
	
	call	GrDrawRegionAtCP
	pop	ax

	and	al, 0xf			; isolate color 
	clr	ah			;ax = colorRB
	call	GrSetAreaColor
	mov	si, ds:[bp].CBR_rightBottom
	call	GrDrawRegionAtCP

if _PM or _ODIE	;--------------------------------------------------------------
if _ODIE
	mov	al, C_BLACK
else
	mov	al, MO_ETCH_COLOR
endif
	call	GrSetAreaColor
	mov	si, ds:[bp].CBR_exterior	;a dark-grey border around
	call	GrDrawRegionAtCP		; the button

	;
	; we draw an additional black line border around default and toolbox
	; buttons.
	;
	test	bx, mask OLBSS_DEFAULT
	jnz	drawExtraBorder

	cmp	bp, offset ToolBoxCBR
	jne	done

drawExtraBorder:
	mov	al, C_BLACK		;draw an additional black border
	call	GrSetAreaColor		; around default buttons
	mov	si, offset CBRdefExtraExterior
	call	GrDrawRegionAtCP
done:

endif		; PM or ODIE --------------------------------------------------

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	pop	ds
	ret
DrawColorButtonBorderEtchLines	endp

endif ; (not DRAW_STYLES)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSelectionBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks an OLButton to see if it is a selection box.

CALLED BY:	DrawColorButtonBorder

PASS:		*ds:si	= OLButton

RETURN:		zero NOT set (jnz) -- button is a selection box
		zero set -- button is not a selection box

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	6/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SELECTION_BOX
CheckIfSelectionBoxFar	proc	far
	call	CheckIfSelectionBox
	ret
CheckIfSelectionBoxFar	endp

CheckIfSelectionBox	proc	near
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_MENU_DOWN_MARK
	jz	exit
	test	ds:[di].OLMBI_odieFlags, mask OLMBOF_IS_SELECTION_BOX
exit:	
	.leave
	ret
CheckIfSelectionBox	endp
endif		; if SELECTION_BOX


if (not DRAW_STYLES)	; not needed with draw styles border/interior drawing


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorButtonInterior

DESCRIPTION:	Draw the interior of the button.

CALLED BY:	DrawColorButton

PASS:		ax	= DrawFlags, ColorScheme
		bx	= OLBI_specState (attributes for button)
		cx, dx	= size of button
		*ds:si	= object
		di	= GState
		cs:bp	= region set for button

RETURN:		ax, bx, cx, dx, si, di = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

DrawColorButtonInterior	proc	near

if	SELECTION_BOX 
	call	CheckIfSelectionBox
	jnz	exit
endif	; if SELECTION_BOX

	push	si, ax
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset

	clr	ax				;ah = 0 -- default to darkColor

	test	ds:[si].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	2$				;sys icon, always dark grey
	test	ds:[si].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	2$
	dec	ah				;use selBkgdColor in this case
2$:

if	(not _PM)
	test	bx, mask OLBSS_DEPRESSED	;al non-zero if depressed
	jz	3$
	dec	al
3$:
endif
	mov	si, ds:[si].OLBI_genChunk	;si = chunk handle of gen part
	call	OpenGetBackgroundColor		;color in ax

ifdef	TOOLBOX_PIXEL_INSET_ON_BKGD
	jnc	5$				;no special colors, branch
	call	ShrinkRegionParams		;else leave a border
5$:
	pushf
endif
	push	ds
	push	ax				;save one color
	clr	ah
	call	GrSetAreaColor
	
FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs							>
	
	mov	si, ds:[bp].CBR_interior
	call	GrDrawRegionAtCP
	
	pop	ax				;get color back
	cmp	al, ah				;same color?
	je	10$				;yes, we're done.
	mov	al, ah
	clr	ah
	call	GrSetAreaColor
	mov	al, SDM_50
	call	GrSetAreaMask			;in case bitmap
	call	GrDrawRegionAtCP
	mov	al, SDM_100
	call	GrSetAreaMask			
10$:
	pop	ds

ifdef	TOOLBOX_PIXEL_INSET_ON_BKGD
	popf	
	jnc	done
	call	ExpandRegionParams		;fix stuff back up
endif

done:
FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>	
	
	pop	si, ax
exit::
	ret
DrawColorButtonInterior	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ShrinkRegionParams, ExpandRegionParams

SYNOPSIS:	Shrinks params of regions by a pixel on all sides.  Expand
		does the opposite thing.

CALLED BY:	DrawColorButtonInterior

PASS:		*ds:si -- button
		cx, dx -- width, height
		di -- gstate

RETURN:		cx, dx -- 2 subtracted from each

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/13/92		Initial version

------------------------------------------------------------------------------@

ifdef	TOOLBOX_PIXEL_INSET_ON_BKGD
ExpandRegionParams	proc	near
	push	bp
	mov	bp, -1				;expands
	jmp	AdjustRegionParams
ExpandRegionParams	endp

ShrinkRegionParams	proc	near	
	push	bp
	mov	bp, 1				;shrinks

AdjustRegionParams	label	near
	push	ax, bx, cx, dx
	mov	bx, bp
	clr	ax
	movdw	dxcx, bxax
	call	GrRelMoveTo
	pop	ax, bx, cx, dx
	shl	bp, 1
	sub	cx, bp				;adjust size
	sub	dx, bp
	pop	bp
	ret
ShrinkRegionParams	endp
endif

endif ; (not DRAW_STYLES)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawColorButtonMenuMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure draws a portion of a button, when
		a MSG_VIS_DRAW is received.

CALLED BY:	DrawColorButton

PASS:		ax	= DrawFlags, ColorScheme
		bx	= OLBI_specState (attributes for button)
		cx, dx	= size of button
		*ds:si	= object
		di	= GState

RETURN:		nothing

DESTROYED:	bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawColorButton,
				added motif stuff.
	joon	8/92		added pm stuff
	chris	2/10/93		Changed motif stuff to be 2 color.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not NO_MENU_MARKS)	;------------------------------------------------------

DrawColorButtonMenuMark	proc	near
	class	OLButtonClass
	
	test	bx, mask OLBSS_MENU_DOWN_MARK or mask OLBSS_MENU_RIGHT_MARK 
	LONG	jz	done			;skip if no menu mark...

	;
	; First, set up the correct color to draw with.  (Nuked -- set up
	; with text color.)
	;
if _MOTIF   	;--------------------------------------------------------
	push	ax
	ANDNF	ax, mask CS_darkColor	;  & use the dark color
	test	bx, mask OLBSS_DEPRESSED ;   if not depressed
	jz	20$
	mov	ax, C_BLACK		; else use black
20$:
	call	GrSetAreaColor
	pop	ax
endif		;--------------------------------------------------------------

	push	ds, bx, cx, dx, si
	push	ax			; Save the DrawFlags & color scheme

	;Have ^lax:si point to the light colored portion of the mark bitmap
	;and ^lax:bp point to the dark colored portion of the mark bitmap

MO <	mov	si, offset MenuDownMarkLightBitmap	;assume menu down mark>
	mov	bp, offset MenuDownMarkDarkBitmap	;		       

	test	bx, mask OLBSS_MENU_DOWN_MARK
PMAN <	push	bx			;need to check for depressed later    >
	pushf
	jnz	10$							       

MO <	mov	si, offset MenuRightMarkLightBitmap	;assme menu right mark>
	mov	bp, offset MenuRightMarkDarkBitmap	;

10$:

if _MOTIF
	test	bx, mask OLBSS_DEPRESSED
	jnz	12$
	xchg	si, bp			;swap bitmaps if not depressed.
12$:
endif
	; Calculate the position to draw the mark bitmap
	;	cs:si = bitmap
	;	cs:bp = bitmap

	call	GrGetCurPos		;ax, bx = pen position

					;Use only OL_MARK_WIDTH cbh 2/10/93
	popf				;doing menu down mark?
	jz	15$			;no, branch
	add	ax, OL_EXTRA_DOWN_MARK_SPACING
					;else adjust position for smaller bitmp
15$:

	sub	dx, OL_MARK_HEIGHT	;compute extra in Y
	shr	dx, 1
	add	bx, dx			;now centered in Y
	add	ax, cx			;compute X position
	sub	ax, OL_MARK_WIDTH + BUTTON_INSET_X

if _MOTIF		;------------------------------------------------------
	;Draw the lighter colored part of the bitmap (always in white)

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP< segmov	ds, cs			;to access the bitmaps		>
	
	clr	dx			; No callback routine.
	call	GrFillBitmap		; Draw the white part of bitmap

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	push	ax, bx			;Save the bitmap position
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax, bx			; Recover the bitmap position

	pop	cx			;get DrawFlags, ColorScheme
	push	cx
endif		;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------
	; Shift mark down and to the right if the button has been depressed
	inc	bx			;shift down
	pop	cx			;cx = OLBI_specState
	test	cx, mask OLBSS_DEPRESSED
	jz	notDepressed
depressed:
	inc	ax			;shift right
notDepressed:
	test	cx, mask OLBSS_MENU_RIGHT_MARK
	jz	frequent

	; I assume that this buttons is a menu button since it has a menu mark.
	; And since it has a right arrow mark, it must open a sub-menu.
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].OLBI_genChunk	;get gen chunk of button
	mov	si, ds:[si]			; which is the sub-menu
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLMWI_specState, mask OMWSS_INFREQUENT_USAGE
	jz	frequent
infrequent:
	; Menu buttons for INFREQUENT_USAGE sub-menus have a border around
	; the menu mark.
FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP< segmov	ds, cs			;to access the bitmaps		>

	sub	bx, 3			;the top of the border is 3 pixels
					; above the mark
	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax
	mov	si, offset MenuRightMarkLightBorder
	call	GrFillBitmap

	push	ax
	mov	ax, MO_ETCH_COLOR
	call	GrSetAreaColor
	pop	ax
	mov	si, offset MenuRightMarkDarkBorder
	call	GrFillBitmap

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	add	bx, 3			;restore y-position of the mark
frequent:

endif		;--------------------------------------------------------------

	;Draw the darker colored part of the bitmap

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP< segmov	ds, cs			;to access the bitmaps		>

	mov	si, bp
	call	GrFillBitmap		; Draw the dark part of bitmap

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>

	pop	ax			; Recover the DrawFlags & color scheme
	pop	ds, bx, cx, dx, si

done:
	ret
DrawColorButtonMenuMark	endp

endif	; not NO_MENU_MARKS ---------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSetDrawColors

DESCRIPTION:	set the line, area, and text colors according to the
		GS_ENABLED status for this button.

CALLED BY:	DrawColorButton, DrawBWButton

PASS:		ax	= DrawFlags, ColorScheme
		bx	= OLBI_specState (attributes for button)
		cx, dx	= size of button
		*ds:si	= object
		di	= GState

RETURN:		ax, si = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonSetDrawColors	proc	near
	push	ax
	ANDNF	ax, mask CS_darkColor		;assume dark color
	call	OpenButtonCheckIfFullyEnabled
	jc	isDisabled			;button is enabled, branch
if USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, SDM_100
else
	mov	al, SDM_50
endif	
	call	GrSetAreaMask			;in case bitmap
	call	GrSetTextMask			;in case text
	call	GrSetLineMask			;for mnemonics
isDisabled:
	;
	; Check for HINT_GADGET_TEXT_COLOR in gen part (C=0)
	;
	push	si
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset	
	mov	si, ds:[si].OLBI_genChunk
	tst	si				;nothing there, branch (C=0)
	jz	5$
EC <	call	ECCheckLMemObject					>
	call	OpenGetTextColor		;text color, if in hint...
5$:
	pop	si
	jc	textColor			;found the color, branch.

	mov	al, C_BLACK			;always use black
if USE_COLOR_FOR_DISABLED_GADGETS
	call	OpenButtonCheckIfFullyEnabled
	jc	enableOK
	mov	al, DISABLED_COLOR
enableOK:
endif

if DRAW_STYLES
	;
	; default text color is black for both selected and unselected
	;
	mov	ah, C_BLACK
else
if (not _PM) and (not _OL_STYLE)	; Button text color is never white in PM

	mov	ah, C_BLACK			;assume selected color black

;	Restored whiting of popup list text. -cbh 1/21/93
;	test	bx, mask OLBSS_MENU_DOWN_MARK or mask OLBSS_MENU_RIGHT_MARK 
;	jnz	textColor			;don't invert text with menu
						;  marks (really we only care
						;  about popups here).
	;
	; Only worry about inverting the color of the text, unless background
	; color is dark grey or black.  -cbh 11/14/92  (Changed 11/20/92 cbh
	; to not do this stuff if not in a toolbox, when we're just using the
	; darkColor.)
	;
	push	si
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	si
	jz	white				;not in toolbox, use white

	push	ds, ax
	mov	ax, segment moCS_selBkgdColor
	mov	ds, ax
	cmp	ds:moCS_selBkgdColor, C_DARK_GREY
	je	10$
	cmp	ds:moCS_selBkgdColor, C_BLACK
10$:
	pop	ds, ax
	jne	textColor
white:
	mov	ah, C_WHITE			; Invert text, if so

endif		;_PM
endif ; DRAW_STYLES

textColor:

if (not _PM)
	test	bx, mask OLBSS_DEPRESSED	;is button pressed?
	jz	useUnselected			;skip if not...
	mov	al, ah				;use selected color
useUnselected:
endif

	clr	ah
	call	GrSetTextColor
	call	GrSetLineColor
	call	GrSetAreaColor			;Added 1/21/93 cbh so arrow
						;  matches whatever text is.
	pop	ax
	ret
OLButtonSetDrawColors	endp

DrawColor ends
endif		; if not _ASSUME_BW_ONLY
