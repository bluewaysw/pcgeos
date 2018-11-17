COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved.

PROJECT:	GEOS
MODULE:		OpenLook/Open
FILE:		copenTextCommon.asm

ROUTINES:
  Name				Description
  ----				-----------
    MTD MSG_VIS_DRAW            Draw a text display object.

    MTD MSG_VIS_DRAW            Draw a text display object.

    MTD MSG_VIS_DRAW            Draw a text display object.

    INT ECCheckGenTextObject    Checks if this is a GenText.

    INT MaybeClearTitleBarArea  If we're in the title bar do special
				drawing.

    MTD MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS 
				This broadcast method is used to find the
				object within a window which has
				HINT_DEFAULT_FOCUS{_WIN}.

    MTD MSG_META_GRAB_FOCUS_EXCL 
				Force the focus to this object.

    MTD MSG_META_GRAB_TARGET_EXCL 
				Force the target to this object.

    MTD MSG_SPEC_NOTIFY_ENABLED Sent to object to update its visual enabled
				state.

    MTD MSG_SPEC_NOTIFY_NOT_ENABLED 
				Disables the text object and its cohorts,
				if needed.

    INT OLTextNavigateIfHaveFocus 
				Navigates if we currently have the focus.
				Special version for OLTextClass which will
				check at the view level if there is one
				(rather than finding out we have the focus
				under the view, which we already know.)

    MTD MSG_SPEC_NAVIGATION_QUERY 
				This method is used to implement the
				keyboard navigation within-a-window
				mechanism. See method declaration for full
				details.

    MTD MSG_VIS_TEXT_SCROLL_PAGE_UP 
				Scrolls the text object up.

    MTD MSG_VIS_TEXT_SCROLL_PAGE_DOWN 
				Scrolls the text object up.

    INT OLTextScroll            Scrolls the text object up.

    MTD MSG_META_TEXT_USER_MODIFIED 
				Handle the text object becoming dirty

    MTD MSG_META_TEXT_NOT_USER_MODIFIED 
				Handle the text object becoming clean.

    MTD MSG_GEN_TEXT_SET_MODIFIED_STATE 
				Sets modified state of text object.

    MTD MSG_GEN_APPLY           Handle APPLY by setting the object clean
				again

    MTD MSG_SPEC_VIS_OPEN_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    MTD MSG_SPEC_VIS_CLOSE_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    GLB GetTextObjectLineHeight Gets the line height of a multi-line text
				object. We can't query the text object for
				this information, as it won't generate it
				until its geometry is valid, so calculate
				it ourself: LineHeight =
				GFMI_MAX_ADJUSTED_HEIGHT - GFMI_ABOVE_BOX -
				GFMI_BELOW_BOX

    MTD MSG_VIS_RECALC_SIZE     Calculate a size for a text object. Does
				nothing if the text is in a view.

    INT OLTextDerefVis          Calculate a size for a text object. Does
				nothing if the text is in a view.

    INT OLTextDerefGen          Calculate a size for a text object. Does
				nothing if the text is in a view.

    INT ObjCallInstanceSaveBp   Calculate a size for a text object. Does
				nothing if the text is in a view.

    MTD MSG_VIS_NOTIFY_GEOMETRY_VALID 
				Notification of valid geometry.  We'll take
				this moment to pop our text object into a
				view, if the text no longer fits in the
				area allocated.

    INT recalcSizeInView        Calc's a new size for text objects in a
				view.

    MTD MSG_SPEC_GET_EXTRA_SIZE Returns the extra size in the text object.

    MTD MSG_VIS_TEXT_HEIGHT_NOTIFY 
				Invoked when the text object changes size.

    MTD MSG_GET_FIRST_MKR_POS   Returns starting position of the text.

    MTD MSG_VIS_TEXT_SHOW_SELECTION 
				If in a view, make sure that the selection
				is scrolled on screen.

				If a single line object, invoke a method in
				the vis instance to scroll the selection on
				screen horizontally.

    MTD MSG_META_CONTENT_TRACK_SCROLLING 
				Normalizes a position to be used for
				scrolling.  The idea is to make sure whole
				lines get scrolled on or off.

    MTD MSG_VIS_TEXT_UPDATE_GENERIC 
				Update the generic instance data

    INT TextUpdateCharParaAttrs Updates generic versions of the para attrs.

    INT UpdateItemGroupIfNeeded Updates an item group if we're running one.

    MTD MSG_SPEC_TEXT_SET_FROM_ITEM_GROUP 
				Sets the text object from the moniker of
				the item passed.

    INT SetTextFromItem         Sets text based on item's moniker.

    INT CallSaveBp              Sets text based on item's moniker.

    MTD MSG_GEN_FIND_KBD_ACCELERATOR 
				Finds the kbd accelerator and gives the
				text object the focus.

    MTD MSG_SPEC_TEXT_UPDATE_CHANGE_TRIGGER 
				Sends a message to the IC_CHANGE trigger to
				update it's state.

    INT OLTextChangeAlterExclIfSingleLineDefault 
				Sends a message to the IC_CHANGE trigger to
				update it's state.

    MTD MSG_GEN_MAKE_APPLYABLE  Makes the dialog box applyable if needed.

    MTD MSG_META_TEXT_EMPTY_STATUS_CHANGED 
				Handle
				ATTR_GEN_TEXT_SET_OBJECT_ENABLED_WHEN_TEXT_EXISTS

    GLB SpecGetTextKbdBindings  Return a pointer to the table of keyboard
				bindings

    GLB SpecGetTextPointerImage Return an optr to the pointer image for
				text

    GLB SpecDrawTextCursor      Draw the text cursor

    GLB SpecDrawTextCursor      Draw the text cursor

    INT GetPreviousCursor       Get the old cursor, and if necessary, set
				the new one.

    INT Draw3DCursor            Draws the 3D text cursor, required by RUDY

    MTD MSG_GEN_TEXT_SET_INDETERMINATE_STATE 
				Specific UI handler for setting
				indeterminate state.  We revert the text
				object to drawing in a 50% pattern if
				indeterminate. This *should* only get
				called if there were an actual change in
				the indeterminate state.

    MTD MSG_META_GET_ACTIVATOR_BOUNDS 
				Gets bounds of activator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenText.asm

DESCRIPTION:
	Implementation of the OpenLook text display class (OLTextClass).

	$Id: copenTextCommon.asm,v 1.2 98/03/11 05:51:49 joon Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	; Class definition

	OLTextClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE

CommonUIClassStructures ends

CommonFunctional segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a text display object.

CALLED BY:	via MSG_VIS_DRAW.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_VIS_DRAW.
		bp	= gstate to use.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version
	cbh	1/26/90		Changed to draw chiseled lines
	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_OL_STYLE
OLTextDraw	method dynamic OLTextClass, MSG_VIS_DRAW
	push	cx				;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	LONG	jnz	drawText		; in view, no borders!

	push	es
	segmov	es, dgroup, ax			;es = dgroup
	mov	al, es:[moCS_dsLightColor]
	mov	ah, es:[moCS_dsDarkColor]
	pop	es
	push	ax				; save it		      
	
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	mov	di, bp				; gstate in di
	jnz	10$				; text is enabled, branch
	
	;
	; Clear a two pixel swath around the outside in case we're making the
	; transition from enabled to disabled.
	;
	pop	ax				; restore colors             
	push	ax				; save them again            
	clr	ah				; use light color	     
	call	GrSetLineColor			; clear area around text
	mov	ax, SDM_50 or mask SDM_INVERSE	; clear out offending pixels
	call	GrSetLineMask
	call	OpenGetLineBounds		; get bounds
	call	GrDrawRect			; clear frame around the outside
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrDrawRect
	
	;
	; The new lines will be drawn in a 50% pattern.
	;
	mov	al, SDM_50			; else draw everything 50%
	call	GrSetTextMask	
	call	GrSetLineMask
10$:

	;
	; See if drawing inside of a frame
	;
	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME
	pop	ax				; dark color in ah, wash in al
	jz	noFrame				; skip if not

	test	ds:[di].OLTDI_specState, mask TDSS_COLOR_SET
	jz	40$				; using bg color, branch
	mov	ax, (C_BLACK shl 8) or C_WHITE	; dark color in ah, wash in al
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:[di] -- VisInstance
	cmp	ds:[di].VTI_washColor.SCP_index.SCPI_info, CF_INDEX
	jne	40$				; some RGB color, forget it
						; else use as wash color here
	mov	al, ds:[di].VTI_washColor.SCP_index.SCPI_index
	cmp	al, C_BLACK			; is the wash color black?
	jne	40$				; no, branch
	mov	ah, C_WHITE			; else we'll use a white frame

40$:								      
	push	ax							      
	clr	ah				; mask to get wash color only 
	mov	di, bp				; di = GState
	call	GrSetAreaColor			;			      
	pop	ax
	mov	al, ah
	clr	ah				; get dark color
	call	GrSetLineColor			; set as line color

	call	VisGetBounds			;
	call	GrFillRect			;
	
	push	es
	segmov	es, dgroup, di			;es = dgroup
	test	es:[moCS_flags], mask CSF_BW
	pop	es
	jnz	42$				; b/w, branch		      

	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:[di] -- SpecInstance
	test	ds:[di].OLTDI_specState, mask TDSS_COLOR_SET
	jnz	42$				; color specific branch      
	
	sub	cx, 2				; one less on right/bottom,
	sub	dx, 2				;  and adjust for line drawing
	mov	di, bp				; di = GState
	call	GrDrawRect			; draw dark frame
	push	ax
	mov	ax, C_WHITE			; now we'll draw in white
	call	GrSetLineColor
	pop	ax
	inc	ax				; move right and down
	inc	bx
	inc	cx
	inc	dx
42$:						;
	mov	di, bp				; gstate in di
	call	GrDrawRect			; draw the frame
	jmp	drawText			; and branch to draw the text
	
noFrame:
	;
	; No frame in this case.  Draw a outward underline in open look.
	;
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jnz	doIt				; editable, go do it, dammit

PrintMessage <THIS IS AN OPENLOOK BUG!>
;NUKED 10/26/90 by Eric because causes stack under-flow
;	pop	dx				; else this is an incredible

	jmp	short drawText			;   failure, get out while you
						;   still can!
doIt:
   	mov	al, ah				; dark color in ax
	clr	ah
	mov	di, bp				; di = GState
	mov	bp, ax				; save color
	mov	ax, C_WHITE			
	call	GrSetLineColor			; set line color
	call	OpenGetLineBounds		; get the bounds   	
	mov	bx, dx				; draw at bottom
	dec	bx				; move up for top line
	
	pop	dx				; restore draw mode
	cmp	dh,DC_GRAY_1			; see if doing b/w	      
	jz	44$				; b/w, branch to do single line

	call	GrDrawHLine			; draw a line
	inc	bx				; move down
44$:
	mov	dx, ax				; save left
	mov	ax, bp				; use dark color
	mov	bp, di				; restore gstate in bp
	call	GrSetLineColor			; set a white line
	mov	ax, dx				; restore left
	call	GrDrawHLine			; draw white line
	
drawText:
	pop	cx				; restore draw mode
	mov	ax, MSG_VIS_DRAW			;
	mov	di, offset OLTextClass
	push	bp
	CallSuper	MSG_VIS_DRAW
	pop	bp

	mov	di, bp
	mov	al, SDM_100			; fix up everything
	call	GrSetTextMask	
	call	GrSetLineMask
	ret

OLTextDraw	endm

endif
	
if	_MOTIF or _ISUI
	
OLTextDraw	method dynamic OLTextClass, MSG_VIS_DRAW
	.enter
	mov	di, bp				; gstate in di
	push	cx				; save draw mode
	mov	bx, ds:[si]			; point to instance
	add	bx, ds:[bx].Vis_offset		; ds:[di] -- SpecInstance
	test	ds:[bx].OLTDI_specState, mask TDSS_IN_VIEW 
	LONG	jnz	drawText		; in view, no borders!

if (not DRAW_STYLES)
	test	ds:[bx].OLTDI_specState, mask TDSS_IN_FRAME
	jz	drawText			; no frame, branch
endif
	
setColors:
	mov	bp, (C_BLACK shl 8) or C_BLACK	; assume frame is all black
	
	test	ds:[bx].OLTDI_specState, mask TDSS_COLOR_SET
	jz	setNormalColors			; text using window's BG, branch
		
washColorSet:
	mov	bx, ds:[si]			; point to instance
	add	bx, ds:[bx].Vis_offset		; ds:[di] -- VisInstance
	cmp	ds:[bx].VTI_washColor.CQ_info, CF_RGB
	jz	drawFrame			; some RGB color, use black
	mov	al, ds:[bx].VTI_washColor.CQ_redOrIndex
	clr	ah
	call	GrSetAreaColor			;			      

	cmp	al, C_BLACK			; is the wash color black?
	jne	drawFrame			; no, branch
	mov	bp, (C_WHITE shl 8) or C_WHITE	; else we'll use a white frame
	jmp	short drawFrame			; go draw it
	
setNormalColors:
	call	OpenSetInsetRectColors		; setup typical colors in bp

drawFrame:

if DRAW_STYLES	;--------------------------------------------------------------

	;
	; get frame flag, draw style, frame thickness, inset thickness
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLTDI_moreState
	andnf	ax, mask TDSS_DRAW_STYLE
rept (offset TDSS_DRAW_STYLE)
	shr	ax, 1				; al = draw style
endm
	test	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME
	jz	haveFrameFlag			; no frame
	ornf	ah, mask DIAFF_FRAME		; else, set frame flag
haveFrameFlag:
	pop	di
	push	ax				; pass flags, draw style
	mov	ax, (DRAW_STYLE_FRAME_WIDTH shl 8) or DRAW_STYLE_INSET_WIDTH
	push	ax				; pass frame, inset widths
	call	VisGetBounds			; pass bounds
	;
	; draw frame and inset
	;
	call	OpenDrawInsetAndFrame

else ;-------------------------------------------------------------------------

	call	VisGetBounds			; use object bounds
	call	OpenDrawAndFillRect		; draw an inset rect, filled

endif ; DRAW_STYLES -----------------------------------------------------------

drawText:	

if TEXT_DISPLAY_FOCUSABLE
	;
	; if focused text display, show focus
	;
	call	ShowTextDisplayFocus
endif

	pop	cx				; restore draw mode
	mov	bp, di				; pass gstate in bp
if CLIP_SINGLE_LINE_TEXT
	push	bp				; save gstate
endif
	mov	ax, MSG_VIS_DRAW			;
	mov	di, offset OLTextClass
	CallSuper	MSG_VIS_DRAW
if CLIP_SINGLE_LINE_TEXT
	pop	di				; di = gstate
	call	ClipSingleLineText
endif
	.leave
	ret
OLTextDraw	endm
			
if DRAW_STYLES or TEXT_DISPLAY_FOCUSABLE

InsetBounds	proc	near
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	ret
InsetBounds	endp

endif ; DRAW_STYLES or TEXT_DISPLAY_FOCUSABLE

endif ; _MOTIF or _ISUI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowTextDisplayFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	indicate focus for text display

CALLED BY:	OLTextDraw
PASS:		*ds:si = OLText object
		di = gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TEXT_DISPLAY_FOCUSABLE

ShowTextDisplayFocus	proc	near
if DRAW_STYLES
	uses	si
endif
	.enter
	;
	; if we have focus, show it
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLTDI_specState, mask TDSS_EDITABLE
	jnz	notFocus
	test	ds:[bp].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	notFocus
	test	ds:[bp].OLTDI_specState, mask TDSS_IN_VIEW
	jnz	notFocus			; scrolling text focus drawn
						;	in view
	test	ds:[bp].VTI_intSelFlags, mask VTISF_IS_FOCUS
	pushf					; save focus state
	test	ds:[bp].OLTDI_specState, mask TDSS_IN_FRAME
	pushf					; save frame state
	movdw	bxax, ds:[bp].VTI_washColor
if DRAW_STYLES
	push	ds:[bp].OLTDI_moreState
endif
	mov	bp, ax				; save wash color info
	call	GrSetAreaColor
	call	VisGetBounds
if DRAW_STYLES
	pop	si				; si OLTDI_moreState
endif
	popf					; get frame state
	jz	noFrame				; no frame
if DRAW_STYLES
rept (DRAW_STYLE_FRAME_WIDTH)
	call	InsetBounds			; inset frame width
endm
else
	call	InsetBounds			; inset frame width
endif
noFrame:
if DRAW_STYLES
	andnf	si, mask TDSS_DRAW_STYLE
	cmp	si, DS_FLAT shl offset TDSS_DRAW_STYLE
	je	noInset
rept (DRAW_STYLE_INSET_WIDTH)
	call	InsetBounds
endm
noInset:
endif ; DRAW_STYLES
	call	GrFillRect			; clear area out
	popf					; get focus state
	jz	notFocus
	dec	cx				; adjust for line drawing
	dec	dx
	push	ax
	mov	ax, C_WHITE			; assume white cursor
	cmp	bp, C_BLACK
	je	haveCursorColor			; white cursor for black
	cmp	bp, C_DARK_GREY
	je	haveCursorColor			; white cursor for dark grey
	mov	ax, C_BLACK			; black cursor for any other
haveCursorColor:
	call	GrSetLineColor
	mov	al, SDM_50
	call	GrSetLineMask
	pop	ax
	call	GrDrawRect			; draw focus indicator
	mov	al, SDM_100
	call	GrSetLineMask
notFocus:
	.leave
	ret
ShowTextDisplayFocus	endp

endif ; TEXT_DISPLAY_FOCUSABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipSingleLineText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clip text off end

CALLED BY:	OLTextDraw
PASS:		*ds:si = OLText object
		di = gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Just draw ellipsis in system font
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CLIP_SINGLE_LINE_TEXT

idata	segment
ellipsisString	TCHAR	C_ELLIPSIS, 0
idata	ends

ClipSingleLineText	proc	near
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_state, mask VTS_ONE_LINE
	LONG jz	done
	test	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	jz	checkClip			; not editable, check clipping
	test	ds:[bx].VTI_intSelFlags, mask VTISF_IS_FOCUS
	LONG jnz	done			; editable has focus, no clip
checkClip:
	;
	; don't have focus, show ellipses if text is wider than text object
	;
	call	CheckTextOverflow
	LONG jnc	done			; object wide enough
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	ornf	ds:[bp].OLTDI_moreState, mask TDSS_CLIPPED
	;
	; make sure we are showing the beginning of the text (this'll have
	; happened for text edits in gained-focus, for text displays we need
	; to do it here to support newly appended text)
	;
	mov	cx, ds:[bp].VTI_leftOffset
	jcxz	noScroll			; already at beginning
	add	cx, ds:[bp].VI_bounds.R_left
	add	cl, ds:[bp].VTI_lrMargin
	adc	ch, 0
	mov	ax, MSG_VIS_TEXT_SCROLL_ONE_LINE
	call	ObjCallInstanceNoLock
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset		; can lmem move?
noScroll:
	;
	; set up gstate
	;
	movdw	bxax, ds:[bp].VTI_washColor
	call	GrSetAreaColor
	test	ds:[bp].VI_attrs, mask VA_FULLY_ENABLED
	jnz	haveEnabled			; text is enabled, branch
	mov	al, SDM_50
	call	GrSetTextMask
	call	GrSetAreaMask
haveEnabled:
	mov	ax, mask TM_DRAW_BOTTOM
	call	GrSetTextMode

	call	VisGetBounds
	mov	al, ds:[bp].VTI_tbMargin
	clr	ah
	add	bx, ax				; adjust top/bottom
	sub	dx, ax
	mov	al, ds:[bp].VTI_lrMargin
	sub	cx, ax				; adjust right
	push	ds, si				; save text object
	push	cx, dx				; save bounds
	segmov	ds, dgroup, ax
	mov	si, offset ellipsisString
	clr	cx				; null-terminated
	call	GrTextWidth			; dx = width
	mov	bp, dx				; bp = width
	pop	cx, dx				; restore bounds
	mov	ax, cx
	sub	ax, bp				; ax = ellipsis left
	pop	ds, si				; *ds:si = text object
	call	FindClosestCharPosition		; ax = closest char pos to left
	call	GrFillRect
	push	ds, si				; save text object
	segmov	ds, dgroup, bx
	mov	si, offset ellipsisString
	mov	bx, dx				; drawing from bottom
	clr	cx				; null-terminated
	call	GrDrawText			; draw ellipis
	pop	ds, si				; *ds:si = text object
	mov	al, SDM_100
	call	GrSetTextMask
	call	GrSetAreaMask
	mov	ax, (mask TM_DRAW_BOTTOM) shl 8
	call	GrSetTextMode
done:
	ret
ClipSingleLineText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindClosestCharPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find closest char position to the left of the passed
		coordinate

CALLED BY:	INTERNAL
			ClipSingleLineText
PASS:		*ds:si = text object
		ax = coordinate to check
		bx, dx = top/bottom to check
RETURN:		ax = coordinate of closest char bounds to the left
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindClosestCharPosition	proc	near
	uses	bx, cx, dx
point		local	PointDWFixed
offsetParams	local	VisTextConvertOffsetParams
	.enter
	mov	point.PDF_x.DWF_int.low, ax
	shr	bx, 1				; divide first to avoid
	shr	dx, 1				;	overflow
	add	dx, bx				; use Y midpoint
	mov	point.PDF_y.DWF_int.low, dx
	clr	ax
	mov	point.PDF_x.DWF_int.high, ax
	mov	point.PDF_x.DWF_frac, ax
	mov	point.PDF_y.DWF_int.high, ax
	mov	point.PDF_y.DWF_frac, ax
	push	bp
	lea	bp, point
	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	ObjCallInstanceNoLock
;	pop	bp
;	mov	ax, point.PDF_x.DWF_int.low
;this gives us the closest to the right of the passed point, use the closest
;char offset and decrement to get the point to the left:
	decdw	dxax				; ignore high word of pos.
	pop	bp
	movdw	offsetParams.VTCOP_offset, dxax
	push	bp
	mov	dx, ss				; dx:bp = params
	lea	bp, offsetParams
	mov	ax, MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE
	call	ObjCallInstanceNoLock
	pop	bp
	mov	ax, offsetParams.VTCOP_xPos.low
	.leave
	ret
FindClosestCharPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTextOverflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if text overflows single line text object

CALLED BY:	INTERNAL
			ClipSingleLineText
			OLTMetaGainedLostSysFocusExcl
PASS:		*ds:si = text object
RETURN:		carry set if text overflow
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTextOverflow	proc	far
	call	VisGetSize
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	al, ds:[bx].VTI_lrMargin
	shl	al, 1
	clr	ah
	sub	cx, ax
	push	cx				; save text object width
	mov	dx, cx
	clr	cx				; use all text
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	call	ObjCallInstanceNoLock		; cx = text width
	pop	ax				; ax = object with
	cmp	ax, cx				; sizes are unsigned
						; C set if text wider
	ret
CheckTextOverflow	endp

endif	; CLIP_SINGLE_LINE_TEXT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckGenTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if this is a GenText.

CALLED BY:	EC utility

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

ECCheckGenTextObject	proc	far	uses	es, di
	.enter
	pushf
	mov	di, segment GenTextClass
	mov	es, di
	mov	di, offset GenTextClass
	call	ObjIsObjectInClass
	ERROR_NC OL_INTERNAL_ERROR_CANT_ACCESS_GEN_TEXT_INSTANCE
	popf
	.leave
	ret
ECCheckGenTextObject	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLTextBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLTextBroadcastForDefaultFocus	method dynamic	OLTextClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	;
	; Added so that non-selectable text edit objects won't just take
	; the focus, even if the magic hint is there.
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jz	done

	test	ds:[di].OLTDI_moreState, mask TDSS_MAKE_DEFAULT_FOCUS
	jz	done				;skip if not...

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	clr	bp
done:
	ret
OLTextBroadcastForDefaultFocus	endm
	
CommonFunctional ends

;-----------------------------------

GadgetCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextGrabFocusExcl
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
	jcw	10/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextGrabFocusExcl	method dynamic OLTextClass, \
						MSG_META_GRAB_FOCUS_EXCL
if TEXT_DISPLAY_FOCUSABLE
	;
	; if text display focusable, don't check selectable state
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jnz	grabFocus
endif
					; Quit if object not selectable
					; (May NOT have focus if not so)
	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jz	done
grabFocus::

	;
	; Have the view grab the focus if there is one.
	;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	10$				;not in view or composite
	mov	si, ds:[di].OLTDI_viewObj	;else point into the object
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
10$:
	call	MetaGrabFocusExclLow	; else call default VisClass handler
done:
	ret
OLTextGrabFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextGrabTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the target to this object.

PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_META_GRAB_TARGET_EXCL.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextGrabTargetExcl	method dynamic OLTextClass, \
						MSG_META_GRAB_TARGET_EXCL
					; Quit if object not selectable
					; (May NOT have target if not so)
	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jz	done

	;
	; Have the view grab the target if there is one.
	;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	10$				;not in view or composite
	mov	si, ds:[di].OLTDI_viewObj	;else point into the object
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
10$:
	call	MetaGrabTargetExclLow	; else call default VisClass handler
done:
	ret
OLTextGrabTargetExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLTextNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for OLTextClass

DESCRIPTION:	Sent to object to update its visual enabled state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		carry set if visual state changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

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

OLTextNotifyEnabled	method dynamic OLTextClass, \
				MSG_SPEC_NOTIFY_ENABLED
	push	dx, ax
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	DoPop	ax, dx
	jnc	exit				;nothing special happened, exit

	;
	; If normally editable and enabled, reset the object editable.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	5$				;not enabled in any case,branch

	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	5$

	push	ax, dx
	mov	cx, mask VTS_EDITABLE or mask VTS_SELECTABLE
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	call	ObjCallInstanceNoLock
	pop	ax, dx
				   
5$:
	;
	; Set the parent view or composite enabled, if applicable.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE or \
					 mask TDSS_IN_VIEW
	jz	10$				;not in view or composite
	push	si
	mov	si, ds:[di].OLTDI_viewObj	;else point into the object
	push	dx
	mov	ax, MSG_GEN_SET_ENABLED
	call	ObjCallInstanceNoLock		;sets GS_ENABLED
	pop	dx
	mov	ax, MSG_GEN_NOTIFY_ENABLED	
	call	ObjCallInstanceNoLock		;sets VA_FULLY_ENABLED if needed
	pop	si
if TEXT_DISPLAY_FOCUSABLE
	;
	; re-grab focus and target for text object under content
	;	*ds:si = text
	;
	call	MetaGrabFocusExclLow
	call	MetaGrabTargetExclLow
endif
10$:
	;
	; Set the selectable flag, if appropriate.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jz	notSelectable			; skip if not selectable.
	or	ds:[di].VTI_state, mask VTS_SELECTABLE
notSelectable:					;
						
	stc					;return state changed
exit:
	ret
OLTextNotifyEnabled	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLTextNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLTextClass

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

OLTextNotifyNotEnabled method dynamic OLTextClass, \
			      MSG_SPEC_NOTIFY_NOT_ENABLED

	call	OLTextNavigateIfHaveFocus	;get rid of focus if we have it
	push	dx
 	call	MetaReleaseFocusExclLow	 	;release focus (shouldn't be
						;  necessary)
 	call	MetaReleaseTargetExclLow	;release target
	call	VisReleaseMouse

	; Note that there is no need to unhilite the text object at this
	; point since releasing the focus will do this
	;
	; Turn off editable and selectable flags.
	;

	mov	cx, (mask VTS_EDITABLE or mask VTS_SELECTABLE) shl 8
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	call	ObjCallInstanceNoLock
					
	mov	ax, MSG_SPEC_NOTIFY_NOT_ENABLED
	mov	di, offset OLTextClass	;call superclass
	call	ObjCallSuperNoLock
	pop	dx
	jnc	exit				;nothing special happened, exit

	;
	; Set the parent view or composite enabled, if applicable.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE or \
					 mask TDSS_IN_VIEW
	jz	exit				;not in view or composite
	push	si
	mov	si, ds:[di].OLTDI_viewObj	;else point into the object
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjCallInstanceNoLock		;clears GS_ENABLED
	mov	ax, MSG_GEN_NOTIFY_NOT_ENABLED
	call	ObjCallInstanceNoLock		;clears VA_FULLY_ENABLED if nece
	pop	si
	stc
exit:
	ret
OLTextNotifyNotEnabled	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	OLTextNavigateIfHaveFocus

SYNOPSIS:	Navigates if we currently have the focus.  Special version for
		OLTextClass which will check at the view level if there is
		one (rather than finding out we have the focus under the view,
		which we already know.)

CALLED BY:	FAR

PASS:		*ds:si -- OLTextClass

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 9/93       	Initial version

------------------------------------------------------------------------------@

OLTextNavigateIfHaveFocus	proc	far		uses	si
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	10$
	mov	si, ds:[di].OLTDI_viewObj
	tst	si				;can't find view, exit
	jz	exit
10$:
	call	OpenNavigateIfHaveFocus
exit:
	.leave
	ret
OLTextNavigateIfHaveFocus	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLTextNavigate - MSG_SPEC_NAVIGATION_QUERY handler for
			OLTextClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLTextClass handler:
	    call utility routine, passing flags to indicate the status
	    of this node: is not root, is not composite, may be focusable,
	    is not menu-related.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLTextNavigate	method dynamic	OLTextClass, MSG_SPEC_NAVIGATION_QUERY
	;ERROR CHECKING is in VisNavigateCommon

	clr	bl			;default: not root-level node, is not
					;composite node, is not focusable,
					;not menu-related.

if _KBD_NAVIGATION or _CR_NAVIGATION
					;can navigate to this item?
	;see if this TextDisplayObject is enabled and is FOCUSABLE.  This thing
	;is always generic, believe me.  (Changed to have all text in views
	;be focusable.  -cbh 2/17/93)

if TEXT_DISPLAY_FOCUSABLE
	;
	; if text display focusable, don't check editable
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jnz	tryNavigate
endif
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE or mask TDSS_IN_VIEW
	jz	haveFlags		;not editable, not focusable
	
tryNavigate::
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	haveFlags		;skip if not...

	ORNF	bl, mask NCF_IS_FOCUSABLE ;indicate that node is focusable
endif

haveFlags:
	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and whether or not this object can
	;get the focus. This routine will check the passed NavigationFlags
	;and decide what to respond.

	mov	di, si			;if is a generic object, gen hints
					;will be in same object.
	call	VisNavigateCommon
	ret
OLTextNavigate	endm


			


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextPageUp -- 
		MSG_VIS_TEXT_SCROLL_PAGE_UP for OLTextClass

DESCRIPTION:	Scrolls the text object up.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_TEXT_SCROLL_PAGE_UP

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/26/90		Initial version

------------------------------------------------------------------------------@

OLTextPageUp	method dynamic OLTextClass, MSG_VIS_TEXT_SCROLL_PAGE_UP
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_UP
	GOTO	OLTextScroll
OLTextPageUp	endm
			
OLTextPageDown	method dynamic OLTextClass, MSG_VIS_TEXT_SCROLL_PAGE_DOWN
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	GOTO	OLTextScroll
OLTextPageDown	endm

OLTextScroll	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	exit				;not in view, exit
	mov	si, ds:[di].OLTDI_viewObj
	GOTO	ObjCallInstanceNoLock
exit:
	ret
OLTextScroll	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLTextTextUserModified -- MSG_META_TEXT_USER_MODIFIED
					for OLTextClass

DESCRIPTION:	Handle the text object becoming dirty

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/11/92		Initial version

------------------------------------------------------------------------------@
OLTextTextUserModified	method dynamic	OLTextClass, MSG_META_TEXT_USER_MODIFIED

	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	;
	; The thing is no longer indeterminate, and is now modified.  Setting
	; the thing modified will set the dialog box applyable as well.
	;
	clr	cx
	mov	ax, MSG_GEN_TEXT_SET_INDETERMINATE_STATE
	call	ObjCallInstanceNoLock

	mov	cx, si
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	call	ObjCallInstanceNoLock

	;
	; Since our actions may cause an object with HINT_DEFAULT_DEFAULT
	; on it to become enabled, we have to steal the default back.  Sigh.
	; cbh 8/30/93
	;
	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	GOTO	OLTextChangeAlterExclIfSingleLineDefault

OLTextTextUserModified	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLTextTextNotUserModified -- MSG_META_TEXT_NOT_USER_MODIFIED
					for OLTextClass

DESCRIPTION:	Handle the text object becoming clean.

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/16/92	Initial version

------------------------------------------------------------------------------@
OLTextTextNotUserModified method dynamic	OLTextClass, MSG_META_TEXT_NOT_USER_MODIFIED

	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	;
	; Set the text object not modified.
	;
	clr	cx
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	GOTO	ObjCallInstanceNoLock

OLTextTextNotUserModified	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLTextSetModifiedState -- 
		MSG_GEN_TEXT_SET_MODIFIED_STATE for OLTextClass

DESCRIPTION:	Sets modified state of text object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_MODIFIED_STATE

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
	chris	4/20/93        	Initial Version

------------------------------------------------------------------------------@

OLTextSetModifiedState	method dynamic	OLTextClass, \
				MSG_GEN_TEXT_SET_MODIFIED_STATE

	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	tst	cx				
	jz	10$				;not setting modified, branch
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
10$:
	GOTO	ObjCallInstanceNoLock

OLTextSetModifiedState	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLTextApply -- MSG_GEN_APPLY for OLTextClass

DESCRIPTION:	Handle APPLY by setting the object clean again

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/12/92		Initial version

------------------------------------------------------------------------------@
OLTextApply	method dynamic	OLTextClass, MSG_GEN_APPLY
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	GOTO	ObjCallInstanceNoLock

OLTextApply	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLTextUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLTextClass

DESCRIPTION:	Specific UI handler for setting the vis moniker.
		Sets OLCOF_DISPLAY_MONIKER flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

		dl	- VisUpdateMode
		cx, bp  - old moniker size

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

OLTextUpdateVisMoniker	method OLTextClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW or \
					 mask TDSS_IN_COMPOSITE
	jz	callSuper			;not in view, do superclass
	;
	; Nothing to be done but to have the moniker set on the view or 
	; composite.
	;
	mov	ax, ds:[di].OLTDI_viewObj	

	mov	bp, dx				;VisUpdateMode in bp
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].GI_visMoniker	;moniker chunk to use

	mov	si, ax				;*ds:si = view or comp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	GOTO	ObjCallInstanceNoLock

callSuper:
	mov	di, offset OLTextClass
	GOTO	ObjCallSuperNoLock
OLTextUpdateVisMoniker	endm

		
GadgetCommon ends

;--------------------------

Geometry segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLTextSpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLTextClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
OLTextSpecVisOpenNotify	method dynamic	OLTextClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLTextSpecVisOpenNotify	endm

;---

OLTextSpecVisCloseNotify	method dynamic	OLTextClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLTextSpecVisCloseNotify	endm

Geometry	ends

LessUsedGeometry	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextObjectLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the line height of a multi-line text object. We can't
		query the text object for this information, as it won't 
		generate it until its geometry is valid, so calculate it
		ourself:
		
		LineHeight = GFMI_MAX_ADJUSTED_HEIGHT
			   - GFMI_ABOVE_BOX
			   - GFMI_BELOW_BOX

CALLED BY:	GLOBAL
PASS:		*ds:si - OLTextClass object
RETURN:		bx - line height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextObjectLineHeight	proc	far	uses	ax, cx, dx, bp, di, si	
	.enter	

;	Get the font and point size for the text object
;
;	We can't just use the point size as the line height, as Berkeley 10
;	point is 12 pixels tall.
;

	sub	sp, size VisTextCharAttr + size VisTextGetAttrParams + size VisTextCharAttrDiffs
	mov	bp, sp
	clrdw	ss:[bp].VTGAP_range.VTR_start
	clrdw	ss:[bp].VTGAP_range.VTR_end
	clr	ss:[bp].VTGAP_flags
	lea	bx, ss:[bp + size VisTextGetAttrParams]
	movdw	ss:[bp].VTGAP_attr, ssbx
	movdw	ss:[bp].VTGAP_return, ssbx
	add	ss:[bp].VTGAP_return.offset, size VisTextCharAttr
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	call	ObjCallInstanceNoLock
	movwbf	dxah, ss:[bx].VTCA_pointSize ;DX.AH <- pt size of the text obj
	mov	al, ss:[bx].VTCA_textStyles
	mov	cx, ss:[bx].VTCA_fontID ;CX <- font ID
	add	sp, size VisTextCharAttr + size VisTextGetAttrParams + size VisTextCharAttrDiffs

	clr	di
	call	GrCreateState
	call	GrSetFont
	
	clr	ah
	call	GrSetTextStyle

	mov	si, GFMI_MAX_ADJUSTED_HEIGHT
	call	GrFontMetrics
	movwbf	bxch, dxah		;BX.CH = GFMI_MAX_ADJUSTED_HEIGHT
	mov	si, GFMI_ABOVE_BOX	;      - GFMI_ABOVE_BOX
	call	GrFontMetrics
	subwbf	bxch, dxah
	mov	si, GFMI_BELOW_BOX	;      - GFMI_BELOW_BOX
	call	GrFontMetrics
	subwbf	bxch, dxah
	
	shl	ch
	adc	bx, 0			;Round BX to the nearest integer
	call	GrDestroyState
	.leave
	ret
GetTextObjectLineHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextRerecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a size for a text object.
		Does nothing if the text is in a view.

CALLED BY:	via MSG_VIS_RECALC_SIZE.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_VIS_RECALC_SIZE.
		cx	= suggested width.
		dx	= suggested height.
RETURN:		nothing
		
DESTROYED:

PSEUDO CODE/STRATEGY:
       lookup desired size args
       apply init width, init height immediately
       calcWidth = MSG_TEXT_ONE_LINE_TEXT_WIDTH(obj)
       if singleLine and not allowTextOffEnd and width not DSA_CHOOSE_OWN_SIZE
       		width = max (width, calcWidth)
       if not expandWidthToFit or width = DSA_CHOOSE_OWN_SIZE
		(assumes a desired width is large, and won't be the min)
		if (editable or multi-line) ;and width not DSA_CHOOSE_OWN_SIZE
			width = min (DEFAULT_WIDTH, width)
		else
			width = min (calcWidth, width)
		endif
       limit width to min and max
       if singleLine
		height = oneLine
       else if not expandHeightToFit
		(assumes a desired height is large, and won't be the min)
		if editable
			height = min (DEFAULT_HEIGHT, height)
		else
			height = min (calcHeight, height)
       limit height to min and max
       Make height an even multiple of lines
       if calcHeight > originalPassedHeight
		MSG_OL_PLACE_IN_VIEW(obj)
	 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version
	cbh	6/18/91		Rewritten completely for V2.0.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEFAULT_TEXT_WIDTH		=	220		;arbitrary
DEFAULT_NARROW_TEXT_WIDTH	=	200		;arbitrary
DEFAULT_TEXT_HEIGHT		=	4
DEFAULT_TEXT_MIN_WIDTH		=	20
			
			
OLTextRerecalcSize	method dynamic OLTextClass, MSG_VIS_RECALC_SIZE
				
	desiredSize		local	SpecSizeArgs
	.enter
	
if	 BUBBLE_DIALOGS and (not (_DUI))
	;
	; If we are in a bubble dialog, then check to see if the "suggested"
	; width is less that the DEFAULT_TEXT_MIN_WIDTH.  If so, then be a
	; "tough guy" and ignore that suggested width.
	;
	; We do this because popup's now shrink-to-fit and eventually the
	; geometry manager suggests that this text object be about 2 pixels
	; wide and this text object is a wimp and just says "OK.. I'll be 2
	; pixels wide".  But that's bad because a 2-pixel wide text object
	; just isn't that useful.
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_WIN_IS_POPUP
	jz	noToughGuy
	test	cx, mask RSA_CHOOSE_OWN_SIZE
	jnz	noToughGuy
	cmp	cx, DEFAULT_TEXT_MIN_WIDTH
	jge	noToughGuy
	
	; Ignoring suggested width because it sucks.
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	
noToughGuy:
endif	;BUBBLE_DIALOGS and (not (_DUI))

	call	VisSetupSizeArgs		;set up size args
	call	OLTextDerefVis
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	notInView			; Not in view, branch
	
	call	recalcSizeInView			; else do view stuff
	jmp	exit				; and exit
	
notInView:	
	;
	; Replace any passed CHOOSE_OWN_SIZE values with an initial value,
	; if specified.
	;
	call	VisApplyInitialSizeArgs
	;
	; Next, calculate the width of the current text if it were to all
	; be on one line.
	;
	; If the text empty?  If so it does not take a genius to figure that
	; the width is 0
	;
	push	cx, dx				; save passed width, height
	clr	bx
	mov	di, ds:[di].VTI_text
	mov	di, ds:[di]
SBCS <	cmp	{char} ds:[di], 0					>
DBCS <	cmp	{wchar} ds:[di], 0					>
	jz	gotWidth
	;
	clr	cx				; all the text
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	call	ObjCallInstanceSaveBp
	mov	bx, cx				; keep width in bx
gotWidth:
	;
	; One more requirement, the width cannot be less than the text objects
	; own minimum width.
	;
	; A HACK FOR SPEED -- Make the min width a constant
	;
	mov	cx, DEFAULT_TEXT_MIN_WIDTH
if 0
	mov	ax, MSG_VIS_TEXT_GET_SIMPLE_MIN_WIDTH
	call	ObjCallInstanceSaveBp		; returns min width in cx
endif

	mov	ax, bx				; text width in ax
	cmp	ax, cx				; is the min width smaller?
	jae	30$				; no, branch
	mov	ax, cx				; else use the min width
30$:
	pop	cx, dx
						;
	;
	; ax holds minimum width to hold the text currently there.
	; cx holds the passed width.
	;
	; If single line, can't go off ends, and passed a fixed size,
	; we'll won't let the width get smaller than the width of the 
	; text.
	;
if GEN_VALUES_ARE_TEXT_ONLY
	call	OLTextDerefVis
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
else
	call	OLTextDerefGen
	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
endif
	jz	checkExpandWidth		; multi-line, won't do this

	push	di				; all editable text allowed off
						;   end. -cbh 2/18/93
	call	OLTextDerefVis
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	pop	di
	jnz	checkExpandWidth			

if GEN_VALUES_ARE_TEXT_ONLY
	mov	di, segment GenTextClass	; No GenText, assume GenValue
	mov	es, di				;  where text shouldn't be
	mov	di, offset GenTextClass		;  clipped.  (?)
	call	ObjIsObjectInClass
	jnc	noTextOffEnd
		
	call	OLTextDerefGen			
endif

if CLIP_SINGLE_LINE_TEXT
	;
	; ALLOW_TEXT_OFF_END is the default for CLIP_SINGLE_LINE_TEXT
	;
	jmp	checkExpandWidth
else
	test	ds:[di].GTXI_attrs, mask GTA_ALLOW_TEXT_OFF_END
	jnz	checkExpandWidth		; can have text off end, branch
endif

noTextOffEnd::
	tst	cx				; we can choose own width?
	js	checkExpandWidth		; yes, branch	
	cmp	cx, ax				; else keep at least big enough
	jae	checkExpandWidth		;  to hold the text that's there
	mov	cx, ax

checkExpandWidth:
	;
	; If we cannot expand the text's width to fit parent, then
	; we'll want to limit the width of the text object to the calc'ed
	; size in non-editable text objects, and to an arbitrary default
	; width in editable text objects.
	;
	call	OLTextDerefVis

	tst	cx				; if passed desired
	js	limitWidth
;	js	finishLimitWidth		; then we'll definitely use
						; passed width (taking advantage
						; of the largeness of this cx)
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT
	jnz	limitWidthToDesired		; can expand, don't limit width
						;   to calc'ed value
limitWidth:

if GEN_VALUES_ARE_TEXT_ONLY
	call	OLTextDerefVis
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
else
	push	di
	call	OLTextDerefGen
	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
	pop	di
endif
	jz	limitWidthToDefault		; multi-line, must have been 
						;   passed desired,will limit to
						;   default width
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	finishLimitWidth		; not editable, limit to
						;   calc'ed width

;	Don't use calc'ed width, even if bigger than default width, when 
; 	the text is editable and we're looking for some kind of minimum width.
;	If there's lots of text in an expand-to-fit text editable text object,
;	the size of the text will force the text object (and its win group)
;	to be very wide, and the expand-to-fit attributes will prevent either
;	from shrinking.  -cbh 5/24/93
;
;	cmp	ax, DEFAULT_TEXT_WIDTH		; calc'ed bigger than default?
;	jae	finishLimitWidth		; yes, don't use default
	
limitWidthToDefault:
	mov	ax, DEFAULT_TEXT_WIDTH		; else use a default
	call	OpenCheckIfNarrow
	jnc	finishLimitWidth
	mov	ax, DEFAULT_NARROW_TEXT_WIDTH
	
finishLimitWidth:
	cmp	cx, ax				; use the smaller of the two
	jb	limitWidthToDesired
	mov	cx, ax
	
limitWidthToDesired:
	call	VisApplySizeArgsToWidth

doHeight:

	;	
	; Based on the width we've got, calculate how tall the text would
	; need to be, and keep it in ax.
	;
	push	cx, dx				; save our running size
	mov	dx, -1				; cache the computed height
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	ObjCallInstanceSaveBp
	mov	ax, dx				; keep calcHeight in ax
	pop	cx, dx				; restore passed size	

if GEN_VALUES_ARE_TEXT_ONLY
	call	OLTextDerefVis
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
else
	call	OLTextDerefGen
	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
endif
	jz	8$				; multi-line, continue

	;
	; Expand height to fit, do the right thing.  -cbh 1/21/93
	;
	tst	dx				; passed desired height, use
	js	6$				;   calculated height.
	call	OLTextDerefVis
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	6$
	cmp	dx, ax				; expanding, big passed height,
	jae	7$				;   use it
6$:
	mov	dx, ax				; use computed height
7$:
	call	VisApplySizeArgsToHeight	; apply size args, if any
	jmp	short exit			; and get out.

8$:
	;
	; Keep the height of a line.  We'll use it for various things.
	;

;	We can't do this, as MSG_VIS_TEXT_GET_LINE_HEIGHT should only be
;	used for single-line objects (it returns a value that is larger
;	than the line height of multi-line objects). We'll do something
;	trickier instead, although we still lose if the text object has
;	a non-integer line height.

;	push	cx, dx
;	mov	ax, MSG_VIS_TEXT_GET_LINE_HEIGHT
;	call	ObjCallInstanceSaveBp
;	mov	bx, dx
;	pop	cx, dx

	call	GetTextObjectLineHeight		;BX <- pixel height

	;
	; Added so text that can't, or shouldn't be placed into a view can
	; grow, no matter what.
	;
	call	OLTextDerefVis
	test	ds:[di].OLTDI_moreState, mask TDSS_STAY_OUT_OF_VIEW
	jz	10$				; not in gen content, branch
	mov	dx, mask RSA_CHOOSE_OWN_SIZE	; else ignore passed height
10$:
	tst	dx				; if passed desired
	js	limitHeight			; then we'll definitely use
						; calced height(taking advantage
						; of the largeness of this dx)
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT
						; can expand, don't limit height
	jnz	limitHeightToDesiredAndUseComputedIfLarger
	
limitHeight:
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	limitHeight2			; not editable, branch

;	Skip all this if we have a HINT_MINIMUM_SIZE specified

	push	ax, bx
	mov	ax, HINT_MINIMUM_SIZE
	call	ObjVarFindData
	pop	ax, bx
	jc	limitHeight2

	push	bx
	shl	bx, 1				; else 4 lines is a minimum
	shl	bx, 1
					CheckHack <DEFAULT_TEXT_HEIGHT eq 4>
	call	OLTextDerefVis			; plus the margins, of course..
	add	bl, ds:[di].VTI_tbMargin
	adc	bh, 0
	add	bl, ds:[di].VTI_tbMargin
	adc	bh, 0
	cmp	bx, ax				; if larger than calc'ed size,
	jbe	20$				;    use it.
	mov	ax, bx
20$:
	pop	bx
	
limitHeight2:
	cmp	dx, ax				; use the smaller of the two
	jb	limitHeightToDesired		; OK, branch
	mov	dx, ax				; calc'ed height was smaller

limitHeightToDesiredAndUseComputedIfLarger:
	cmp	dx, ax
	jae	limitHeightToDesired
	mov	dx, ax				; use computed height
	
limitHeightToDesired:
	call	VisApplySizeArgsToHeight
	;
	; Let's take a moment to truncate our height to be a multiple of the 
	; line height.
	;

;	It's unclear why we do this, but Chris thinks that we might want to do
;	this in case the user specified a bogus HINT_FIXED_SIZE or
;	HINT_MINIMUM_SIZE - atw 12/29/94

	mov	ax, dx				; height in ax
	clr	dx
	call	OLTextDerefVis
	mov	dl, ds:[di].VTI_tbMargin
	shl	dx				; extra border in dx
	sub	ax, dx				; subtract off border
	jns	101$				; don't go below zero...
	clr	ax
101$:
	push	dx
	clr	dx
	div	bx				; divide by pixels per line
	
	; HACK for non-berkeley fonts, until we figure out why MSG_GET_LINE_
	; HEIGHT ain't returning the same thing as MSG_CALC_HEIGHT...

;	With my fix to no longer use MSG_VIS_TEXT_GET_LINE_HEIGHT (which only
;	works on single line objects), this should no longer be necessary,
;	but I'll leave it in, as I'm afraid to change anything else in this
;	venerable old workhorse - atw 12/29/94
	
	tst	ax
	jnz	11$				;Branch if at least one line hi
	inc	ax				; make at least one line high
11$:
	mul	bx				; then multiply again
	pop	dx
	add	dx, ax				; back in dx, adding borders
exit:					
	.leave
	ret					
OLTextRerecalcSize	endm

OLTextDerefVis	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
OLTextDerefVis	endp

OLTextDerefGen	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
OLTextDerefGen	endp

ObjCallInstanceSaveBp	proc	near
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	ret
ObjCallInstanceSaveBp	endp
			
			


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextNotifyGeometryValid -- 
		MSG_VIS_NOTIFY_GEOMETRY_VALID for OLTextClass

DESCRIPTION:	Notification of valid geometry.  We'll take this moment
		to pop our text object into a view, if the text no longer
		fits in the area allocated.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_NOTIFY_GEOMETRY_VALID

RETURN:		nothing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/14/91		Initial version

------------------------------------------------------------------------------@

OLTextNotifyGeometryValid	method dynamic OLTextClass, \
				MSG_VIS_NOTIFY_GEOMETRY_VALID

	;
	; Before we call our superclass, set the GEOMETRY_ALREADY_VALID
	; flag, so that if we get HEIGHT_NOTIFY while the superclass
	; rebuilds line structures, we won't go into an infinte loop
	; of geometry invalidations (see handler for HEIGHT_NOTIFY).
	; - cct 12/27/95
	;
EC <	test	ds:[di].OLTDI_moreState, mask TDSS_GEOMETRY_ALREADY_VALID  >
EC <	ERROR_NZ OL_ERROR						   >
	ornf	ds:[di].OLTDI_moreState, mask TDSS_GEOMETRY_ALREADY_VALID

	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

	;
	; reset the flag.
	;
	andnf	ds:[di].OLTDI_moreState, not mask TDSS_GEOMETRY_ALREADY_VALID
	
	;
	; If we've create a line structure (hopefully we have), we'll mark
	; it ignore-dirty so it's not saved to state.   The chunk is being
	; left around in state once we shut down and our Vis part is destroyed.
	;
	mov	ax, ds:[di].VTI_lines
	tst	ax
	jz	10$
	mov	bx, mask OCF_IGNORE_DIRTY
	call	ObjSetFlags
10$:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

	; If a one-line text object, already in a view, or is free to choose
	; own size without being popped into view, then there's nothing more for
	; us to do -- exit
	;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW or \
					 mask TDSS_GOING_INTO_VIEW	
	jnz	exit
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jnz	exit
	test	ds:[di].OLTDI_moreState, mask TDSS_STAY_OUT_OF_VIEW
	jnz	exit


EC <	call	ECCheckGenTextObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
						; pop into a view if requested
	test	ds:[di].GTXI_attrs, mask GTA_INIT_SCROLLING
	jnz	forceIntoView			; 
	
	;	
	; Based on the width we've got, calculate how tall the text needs
	; to be, and keep it in ax.
	;
	call	VisGetSize			; get width in cx
	push	cx, dx				; save our running size
	clr	dx				; can use cached values, I think
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	ObjCallInstanceSaveBp
	mov	ax, dx				; keep calcHeight in ax
	pop	cx, dx				; restore running size	
	cmp	dx, ax				; is our return height big
						;   enough to hold the text?
	jae	exit				; yup, branch
	
forceIntoView:
	;
	; OK, we're about to pop into a view.  Stop to consider -- will the
	; system actually let us do this?
	;
	mov	dx, offset GenViewClass
	mov	cx, segment GenViewClass
	mov	ax, MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	jc	cannotBePoppedIntoView		; If below a GenView, NO.

	;	
	; Not enough room to hold the text.  Time to pop into a view.
	;
	mov	di, ds:[si]			; Say we're about to put this
	add	di, ds:[di].Vis_offset		;    in a view.
	or	ds:[di].OLTDI_specState, mask TDSS_GOING_INTO_VIEW	

	mov	ax, MSG_OL_PLACE_IN_VIEW	;

forceQueueMessageExit:
	mov	bx, ds:LMBH_handle		;
	mov	di,mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage			;
exit:					
	ret

cannotBePoppedIntoView:
	; Set flag to indicate this object should be sized so as to always
	; display all the text
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLTDI_moreState, mask TDSS_STAY_OUT_OF_VIEW

	;
	; Now that we've set the flag so that geometry will be calculated
	; correctly, redo geometry.  We'll only need to do this the first
	; time, as the above bit will take care of us later.
	;
	mov	ax, MSG_VIS_MARK_INVALID	;
	mov	cl, mask VOF_GEOMETRY_INVALID	; mark the thing invalid
	mov	dl, VUM_NOW			;
	jmp	short forceQueueMessageExit	; do it!

OLTextNotifyGeometryValid	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	recalcSizeInView

SYNOPSIS:	Calc's a new size for text objects in a view.

CALLED BY:	OLTextRerecalcSize

PASS:		*ds:si -- handle
		cx, dx -- size args

RETURN:		cx, dx -- new size

DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

recalcSizeInView	proc	near
	;
	; Code added 6/ 9/92 cbh to keep very tiny (i.e. 0 width) sizing from
	; blowing up the text object.
	;
	mov	ax, DEFAULT_TEXT_MIN_WIDTH
	cmp	cx, ax				; is the passed width too small?
	jae	5$				; no, branch
	mov	cx, ax				; else use the min width
5$:
	push	cx				; save width
	mov	dx, -1				; Cache the computed height.
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	;
	call	ObjCallInstanceSaveBp		;
	pop	cx				; restore width
	call	VisFindParent			; get parent content in same blk
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:[di] -- VisInstance
	cmp	dx, ds:[di].VCNI_viewHeight	; see if smaller than view ht
	jae	10$				; it's not, we're done
	mov	dx, ds:[di].VCNI_viewHeight	; else size as big as view
10$:
	tst	cx				; see if desired width passed
	jns	exit				; no, branch
	mov	cx, ds:[di].VCNI_viewWidth	; else start with content width
exit:
	ret
recalcSizeInView	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLTextGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLTextClass

DESCRIPTION:	Returns the extra size in the text object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx  - extra size

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		return lrMargin in cx
		return tbMargin + (lineSpacing * (numLines - 1)) in dx

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@

OLTextGetExtraSize	method dynamic OLTextClass, \
				MSG_SPEC_GET_EXTRA_SIZE

	clr	cx
	mov	cl,ds:[di].VTI_lrMargin
	shl	cx,1

	clr	dx
	mov	dl,ds:[di].VTI_tbMargin
	shl	dx,1
	ret

OLTextGetExtraSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invoked when the text object changes size.

CALLED BY:	via MSG_VIS_TEXT_HEIGHT_NOTIFY.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_VIS_TEXT_HEIGHT_NOTIFY.
		dx	= new height.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version
	cbh	5/15/91		Fixed for new bounds convention

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
OLTextHeightNotify	method dynamic OLTextClass, MSG_VIS_TEXT_HEIGHT_NOTIFY

EC <	call	ECCheckGenTextObject				>

	; If NOT in view, then see if we're heading there already.  If so,
	; then we don't need to do anything now, as it will be taken care
	; of once we're in the view.  
	;
	test	ds:[di].OLTDI_specState, mask TDSS_GOING_INTO_VIEW	
	LONG	jnz	Done			; if going into view, no
						; more work need be done here.

	mov	di, ds:[si]			;
	add	di, ds:[di].Gen_offset		; ds:di <- ptr to gen instance.
	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
	LONG	jnz	Done			; single line text object, never
						; recalculate! (3/15/93 cbh)

	test	ds:[di].GTXI_attrs, mask GTA_ALLOW_TEXT_OFF_END
	LONG	jnz	Done			; if allowing text off end, size
						; of text object will not change
						;
	mov	bx, ds:[si]			;
	add	bx, ds:[bx].Vis_offset		; ds:bx <- ptr to vis instance.
						;
						; Get current visual height.
	mov	ax, ds:[bx].VI_bounds.R_bottom	; ax <- visual height.
	sub	ax, ds:[bx].VI_bounds.R_top	;
	
	mov	bx, ds:[si]			; point to instance
	add	bx, ds:[bx].Vis_offset		; ds:[di] -- SpecInstance
	test	ds:[bx].OLTDI_specState, mask TDSS_IN_VIEW
	jz	TDHN_NotInView			; branch if not in view.
	
	;
	; Special code for text in views.  If the currently stored text height
	; if smaller than the height of the view, we need only make sure that
	; the height passed in here is smaller than or equal to the current 
	; height (we keep the text object expanded to the height of the view
	; if it is smaller, so we can click anywhere in it.) If the currently
	; stored text height is bigger than the height of the view, the height
	; passed should match exactly.
	;
	; Changed 8/21/90 cbh:
	;	dx <- max (new height, view height)
	;	if dx <> ax, set new height to dx
	;
	push	si
	call	VisFindParent			; get parent content in same blk
	mov	di, ds:[si]			; point to instance
	pop	si
	add	di, ds:[di].Vis_offset		; ds:[di] -- VisInstance
	cmp	dx, ds:[di].VCNI_viewHeight	; make sure at least view height
	jae	10$				; 
	mov	dx, ds:[di].VCNI_viewHeight	; 
10$:
	cmp	dx, ax				; matches current height?
	je	Done				; yes, nothing to do
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left
	call	VisSetSize			;resize ourselves
	call	VisFindParent			;find content
	call	VisSetSize			;resize the parent
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	si, ds:[di].VCNI_view.chunk
	tst	si				;no window, get out
	jz	Done
	mov	bx, ds:[di].VCNI_view.handle
	clr	di				;don't sweat ds fix-up
	call	GenViewSetSimpleBounds
	jmp	short Done
	
TDHN_NotInView:					
	cmp	dx, ax				; see if text fits EXACTLY
	je	Done				;
	jne	TDHN_redo			;
	
TDHN_JustHasToFit:					;
	cmp	dx, ax				; see if text fits
	jbe	Done				; If it fits, then no action
						;	 needs to be taken.
TDHN_redo:					;
	;
	; Has object been specifically built yet?
	; if not, skip invalidation & update, we're not in a legal tree yet.
	; User is just setting text while not visible.
	;
	call	VisCheckIfSpecBuilt
	jnc	Done				; if not visbuilt, then done

	call	OLTextDerefVis
	test	ds:[di].OLTDI_moreState, mask TDSS_GEOMETRY_ALREADY_VALID
	jnz	Done				; if currently handling
						; geometry_valid, no more
						; work need be done here.
	;
	; Mark geometry invalid, so that we can resize text box to be bigger,
	; or force the text object into a view.  (That decision may only
	; be made by RecalcSize for text object)
	;
	;
	mov	dl, VUM_NOW			; put this off until later...
	mov	cl, mask VOF_GEOMETRY_INVALID	;
	mov	ax, MSG_VIS_MARK_INVALID		;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE		;
	call	ObjMessage			;
Done:
	ret					;
	
OLTextHeightNotify	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLTextClass

DESCRIPTION:	Returns starting position of the text.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_FIRST_MKR_POS

RETURN:		ax, cx  - position of the text

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89		Initial version

------------------------------------------------------------------------------@

OLTextMkrPos	method dynamic OLTextClass, MSG_GET_FIRST_MKR_POS
	mov	ax, ds:[di].VI_bounds.R_left	;get left
	mov	cx, ds:[di].VI_bounds.R_top	;get top

	add	al, ds:[di].VTI_lrMargin
	adc	ah, 0

	add	cl, ds:[di].VTI_tbMargin
	adc	ch, 0

;	mov	bp, ds:[di].VTI_height.WBF_int	;get text height
;	sub	bp, 2				;some magical amount, who knows.

	;
	; Adjust for font size, if necessary, so baselines have a change of
	; lining up.  -cbh 12/ 1/92  (Can't get it to work.  Need to search
	; for baseline in system and text font, i.e. the hard way.)
	;
;	mov	dx, segment specDisplayScheme
;	mov	ds, dx
;	mov	dx, ds:[specDisplayScheme.DS_pointSize]
;	sub	cx, dx				;add difference to height
;	add	cx, bp

exit:
	stc
	ret
OLTextMkrPos	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If in a view, make sure that the selection is scrolled on
		screen.

		If a single line object, invoke a method in the vis instance
		to scroll the selection on screen horizontally.

CALLED BY:	via MSG_VIS_TEXT_SHOW_SELECTION.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ss:bp	= VisTextShowSelectionArgs
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextShowSelection	method dynamic OLTextClass, \
				MSG_VIS_TEXT_SHOW_SELECTION

EC <	call	ECCheckGenTextObject				>
	add	bx, ds:[bx].Gen_offset		;ds:[bx] -- GenInstance
						;
	test	ds:[bx].GTXI_attrs, mask GTA_DONT_SCROLL_TO_CHANGES
	jnz	exit				;user doesn't want to, exit
	
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	notInView			;skip if not in view

	test	ss:[bp].VTSSA_flags, mask VTSSF_DRAGGING
						;if dragging, exit (handled by
	jnz	exit				;  port window)

 	mov	si, ds:[di].OLTDI_viewObj	;get handle of view object

	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	GOTO	ObjCallInstanceNoLock

notInView:
	;
	; Not in a view, check to see if it is a one line edit object.
	; if it is, then we can handle scrolling.
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	callSuper				; quit if not one line.
	;
	; It is a one line object.
	;
	mov	ax, MSG_VIS_TEXT_SCROLL_ONE_LINE
	GOTO	ObjCallInstanceNoLock
callSuper:
	mov	di, offset OLTextClass
	GOTO	ObjCallSuperNoLock
exit:
	ret
OLTextShowSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextNormalizePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalizes a position to be used for scrolling.  The idea
		is to make sure whole lines get scrolled on or off.

CALLED BY:
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_META_CONTENT_TRACK_SCROLLING
		ss:bp   = TrackScrollingParams
		dx      - size TrackScrollingParams
		cx      - chunk handle of subview window
		
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	10/13/89	Initial version
	jcw	19-Dec-89	Changed to work with new text object.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextNormalizePosition	method dynamic OLTextClass, \
				MSG_META_CONTENT_TRACK_SCROLLING
	;
	; For now we only bother to normalize the scroll in the vertical
	; direction. For horizontal scrolling we just use the values
	; passed in.
	;
	call	GenSetupTrackingArgs		; set up all the arguments
	mov	bl, ss:[bp].TSP_action
	cmp	bl, SA_INITIAL_POS
	je	OLTDNP_return			; no normalizing on initial pos
	cmp	bl, SA_SCROLL_INTO
	je	OLTDNP_return			; no normalize on scroll-into
	cmp	bl, SA_SCROLL
	je	OLTDNP_return			; no normalize on scroll-into
	cmp	bl, SA_DRAG_SCROLL
	je	OLTDNP_return			; no normalize on scroll-into
	test	ss:[bp].TSP_flags, mask SF_VERTICAL ; see if vertical
	jz	OLTDNP_return			; no, no change necessary
	;
	; We are scrolling vertically.
	;
	push	cx				; Save scrollbar chunk handle.
	mov	ax, MSG_VIS_TEXT_GET_SCROLL_AMOUNT	;
	call	ObjCallInstanceNoLock		; dx <- amount to scroll.
	pop	cx				; Restore scrollbar chunk.
	mov	ss:[bp].TSP_change.PD_y.low, dx	; return scroll amount
	tst	dx				; sign extend to dword
	jns	OLTDNP_return
	mov	ss:[bp].TSP_change.PD_y.high, -1
	
OLTDNP_return:					;
	call	GenReturnTrackingArgs		; return arguments
	ret					;
OLTextNormalizePosition	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLTextUpdateGeneric --
		MSG_VIS_TEXT_UPDATE_GENERIC for OLTextClass

DESCRIPTION:	Update the generic instance data

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The method

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

OLTextUpdateGeneric	method dynamic	OLTextClass,
					MSG_VIS_TEXT_UPDATE_GENERIC

EC <	call	ECCheckGenTextObject				>
	call	ObjMarkDirty

	add	bx, ds:[bx].Gen_offset

	; ds:di = vis
	; ds:bx = gen

	mov	ax, ds:[di].VTI_maxLength
	mov	ds:[bx].GTXI_maxLength, ax

	mov	ax, ds:[di].VTI_text
	mov	ds:[bx].GTXI_text, ax

	; deal with char attr runs

	call	TextUpdateCharParaAttrs

	; copy vardata stuff if it exists

	mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
	mov	di, ATTR_GEN_TEXT_TYPE_RUNS
	call	copyVarData
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	mov	di, ATTR_GEN_TEXT_GRAPHIC_RUNS
	call	copyVarData
	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY
	mov	di, ATTR_GEN_TEXT_STYLE_ARRAY
	call	copyVarData
	mov	ax, ATTR_VIS_TEXT_NAME_ARRAY
	mov	di, ATTR_GEN_TEXT_NAME_ARRAY
	call	copyVarData
	mov	ax, ATTR_VIS_TEXT_EXTENDED_FILTER
	mov	di, ATTR_GEN_TEXT_EXTENDED_FILTER
	call	copyVarData
	mov	ax, ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	mov	di, ATTR_GEN_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	call	copyVarData

	ret

copyVarData:
	call	ObjVarFindData
	jnc	doesNotExist
	mov	dx, ds:[bx]
	mov	cx, size word
	mov_tr	ax, di
	call	ObjVarAddData
	mov	ds:[bx], dx
doesNotExist:
	retn

OLTextUpdateGeneric	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	TextUpdateCharParaAttrs

SYNOPSIS:	Updates generic versions of the para attrs.

CALLED BY:	OLTextUpdateGeneric

PASS:		*ds:si -- text
		ds:di -- Vis instance
		ds:bx -- Gen instance

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/28/92		Initial version

------------------------------------------------------------------------------@

TextUpdateCharParaAttrs	proc	near
	;
	; First, do char attrs.
	;
EC <	call	ECCheckGenTextObject				>
	clr	bp				;assume no special hints.

	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	jz	notDefault

	cmp	ds:[di].VTI_charAttrRuns, VIS_TEXT_INITIAL_CHAR_ATTR
	je	setCharAttrHints		;same as default, done.

	mov	bp, ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR
	jmp	short setCharAttrHints

notDefault:
	mov	bp, ATTR_GEN_TEXT_CHAR_ATTR
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	setCharAttrHints
	
	mov	bp, ATTR_GEN_TEXT_MULTIPLE_CHAR_ATTR_RUNS

setCharAttrHints:
	mov	dx, ds:[di].VTI_charAttrRuns
	mov	ax, ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR
	call	setOrClearHint
	mov	ax, ATTR_GEN_TEXT_MULTIPLE_CHAR_ATTR_RUNS
	call	setOrClearHint
	mov	ax, ATTR_GEN_TEXT_CHAR_ATTR
	call	setOrClearHint

	;
	; Now, do para attrs.
	;
	clr	bp				;assume no special hints.

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_PARA_ATTR
	jz	notDefaultPara

	cmp	ds:[di].VTI_paraAttrRuns, VIS_TEXT_INITIAL_PARA_ATTR
	je	setParaAttrHints		;same as default, done.

	mov	bp, ATTR_GEN_TEXT_DEFAULT_PARA_ATTR
	jmp	short setParaAttrHints

notDefaultPara:
	mov	bp, ATTR_GEN_TEXT_PARA_ATTR
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	setParaAttrHints
	
	mov	bp, ATTR_GEN_TEXT_MULTIPLE_PARA_ATTR_RUNS

setParaAttrHints:
	mov	dx, ds:[di].VTI_paraAttrRuns
	mov	ax, ATTR_GEN_TEXT_DEFAULT_PARA_ATTR
	call	setOrClearHint
	mov	ax, ATTR_GEN_TEXT_MULTIPLE_PARA_ATTR_RUNS
	call	setOrClearHint
	mov	ax, ATTR_GEN_TEXT_PARA_ATTR
	call	setOrClearHint
	ret


setOrClearHint:
	;
	; Takes hint to set/clear in ax, hint we want set in bp.
	; Hint data (if used) in dx.
	;
	cmp	ax, bp				;do we want this hint?
	je	addHint				;yes, add
	call	ObjVarDeleteData		;no nuke
	retn
addHint:
	mov	cx, size word
	or	ax, mask VDF_SAVE_TO_STATE	;added 4/23/93 cbh
	call	ObjVarAddData			;create a one-word hint
	mov	{word} ds:[bx], dx		;store hint data
	retn

TextUpdateCharParaAttrs	endp


LessUsedGeometry ends


GadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextKbdChar -- MSG_META_KBD_CHAR for OLTextClass

DESCRIPTION:	Pre-process keyboard input, looking for navigation stuff

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The method

	cx = charValue
	dl = CharFlags
		CF_RELEASE - set if release
		CF_STATE - set if shift, ctrl, etc.
		CF_TEMP_ACCENT - set if accented char pending
	dh = ShiftState
	bp low = ToggleState (unused)
	bp high = scan code (unused)

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@


OLTextKbdChar	method	OLTextClass, MSG_META_KBD_CHAR

EC <	call	ECCheckGenTextObject				>

	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	navigate			;not editable, send up.

	;
	; For RUDY we will do the optimization after testing for
	; C_ENTER.. because we don't want CF_RELEASE-ENTER to reach
	; the text object if text is GTA_SINGLE_LINE_TEXT -- text
	; object is keeping count of pressed keys.	-- kho, 6/23/95
	;
	; oh, C_TAB too.. otherwise TAB in contact card gives a minor
	; warning in VisTextClass. So the conclusion.. we cannot do this
	; neat optimization	-- kho, 9/14/95
	;
	test	dl, mask CF_RELEASE		;ignore releases
	jnz	noNavigate
		
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

SBCS <	cmp	cl, C_ENTER						>
DBCS <	cmp	cx, C_SYS_ENTER						>
	jz	enterKey

SBCS <	cmp	cl, C_TAB						>
DBCS <	cmp	cx, C_SYS_TAB						>
	jnz	noNavigate

	; if the character is a C_TAB and GTA_USE_TAB_FOR_NAVIGATION
	;					-> navigate

	test	ds:[di].GTXI_attrs, mask GTA_USE_TAB_FOR_NAVIGATION
	jnz	navigate
	jmp	noNavigate

enterKey:

	; if the character is a C_ENTER and this we're 
	; 	the method stored is 0 -> navigate

	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
	jz	noNavigate			;not single line, no navigate
						;   or action method
	;
	; Send CR to action descriptor, telling application to deal with the
	; default action request if it wants.
	;
	push	cx, dx, bp
	call	UpdateItemGroupIfNeeded		;updates item group if need be

	mov	ax, MSG_GEN_ACTIVATE
	call	ObjCallInstanceNoLock		;send out apply msg, etc.
	pop	cx, dx, bp
	jmp	short navigate

noNavigate:
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset OLTextClass
	GOTO	ObjCallSuperNoLock

navigate:
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
OLTextKbdChar	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateItemGroupIfNeeded

SYNOPSIS:	Updates an item group if we're running one.

CALLED BY:	OLTextKbdChar

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/19/92		Initial version

------------------------------------------------------------------------------@

UpdateItemGroupIfNeeded	proc	near		uses	si
	.enter
EC <	call	ECCheckGenTextObject				>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_moreState, mask TDSS_RUNS_ITEM_GROUP
	jz	exit				;not running item grop, exit

	mov	di, ds:[di].VTI_text
	mov	di, ds:[di]
SBCS <	cmp	{char} ds:[di], 0					>
DBCS <	cmp	{wchar} ds:[di], 0					>
	jz	exit
	mov	dx, di
	mov	cx, ds

	mov	ax, ATTR_GEN_TEXT_RUNS_ITEM_GROUP
	call	ObjVarFindData
EC <	ERROR_NC	OL_ERROR		;Should have found data!  >
	mov	si, ds:[bx].chunk		;setup to talk to object
	mov	bx, ds:[bx].handle

	clr	bp				;don't need exact match
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
UpdateItemGroupIfNeeded	endp






COMMENT @----------------------------------------------------------------------

METHOD:		OLTextSetFromItemGroup -- 
		MSG_SPEC_TEXT_SET_FROM_ITEM_GROUP for OLTextClass

DESCRIPTION:	Sets the text object from the moniker of the item passed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_TEXT_SET_FROM_ITEM_GROUP
		cx	- identifier of item group

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
	chris	5/19/92		Initial Version

------------------------------------------------------------------------------@

OLTextSetFromItemGroup	method dynamic	OLTextClass, \
				MSG_SPEC_TEXT_SET_FROM_ITEM_GROUP

EC <	call	ECCheckGenTextObject				>
	mov	ax, ATTR_GEN_TEXT_RUNS_ITEM_GROUP
	call	ObjVarFindData
EC <	ERROR_NC	OL_ERROR		;Should have found data!  >
	mov	bp, si				;save object chunk handle
	FALL_THRU	SetTextFromItem
OLTextSetFromItemGroup	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetTextFromItem

SYNOPSIS:	Sets text based on item's moniker.

CALLED BY:	OLTextSetFromItemGroup, OLRangeSetFromItemGroup

PASS:		*ds:si -- text object
		ds:bx -- far pointer to item group's optr
		cx    -- item identifier

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/19/92		Initial version

------------------------------------------------------------------------------@
SetTextFromItem		proc	far
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle		;set up to talk to object

	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	CallSaveBp			;item in ^lcx:dx
	
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	CallSaveBp			;returns moniker ^lbx:ax

	call	ObjSwapLock			;now in *ds:ax
	mov	si, ax
	mov	si, ds:[si]			;now pointing at moniker
EC <	test	ds:[si].VM_type, mask VMT_GSTRING			>
EC <	ERROR_NZ	OL_ERROR		;shouldn't be a gstring >
	add	si, VM_data + VMT_text		;point at the data

	;
	; Pointer to source text in ds:si.  Let's store the text on the stack,
	; then set our text appropriately.  bp holds our object handle.
	;
	push	si
	clr	cx
10$:
	inc	cx
	cmp	{byte} ds:[si], 0
	pushf
	inc	si
	popf
	jne	10$
	pop	si

	sub	sp, cx
	mov	di, sp				;place for text in ss:di
	push	di
	segmov	es, ss				;now es:di
	push	cx
	rep	movsb				;copy the string, including null
	pop	cx				;  to stack destination
	mov	si, bp				;restore object chunk handle

	call	ObjSwapUnlock			;text chunk back in ds
	pop	bp				;es:bp <- text
	mov	dx, es				;dx:bp <- text
	push	cx
	clr	cx				;null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock		;do it
	pop	cx
	add	sp, cx				;restore stack
	ret
SetTextFromItem	endp

CallSaveBp proc near
	push	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	ret
CallSaveBp endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLTextActivateObjectWithMnemonic --
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

------------------------------------------------------------------------------@

OLTextActivateObjectWithMnemonic	method	OLTextClass, \
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	VisCheckIfFullyEnabled
	jnc	noActivate
	;XXX: skip if menu?
	call	VisCheckMnemonic
	jnc	noActivate
	;
	; mnemonic matches, grab focus
	;
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
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
OLTextActivateObjectWithMnemonic	endm






COMMENT @----------------------------------------------------------------------

METHOD:		OLTextFindKbdAccelerator -- 
		MSG_GEN_FIND_KBD_ACCELERATOR for OLTextClass

DESCRIPTION:	Finds the kbd accelerator and gives the text object the
		focus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_FIND_KBD_ACCELERATOR

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
	chris	8/26/93         Initial Version

------------------------------------------------------------------------------@

OLTextFindKbdAccelerator	method dynamic	OLTextClass, \
				MSG_GEN_FIND_KBD_ACCELERATOR
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	exit				;exit if disabled, carry clear

	;
	; Check for a keyboard accelerator.
	;
	call	GenCheckKbdAccelerator		;check kbd accelerator
	jnc	exit				;nothing found, exit

	call	MetaGrabFocusExclLow

	;	
	; Grab focus on view too, if needed.   (cbh 9/22/93)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	10$
	mov	si, ds:[di].OLTDI_viewObj
	tst	si
	jz	10$
	call	MetaGrabFocusExclLow
10$:
	
	stc					;handled
exit:
	ret
OLTextFindKbdAccelerator	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLTextGainedFocusExcl -- 
		MSG_META_GAINED_FOCUS_EXCL for OLTextClass

DESCRIPTION:	Handles gained focus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_GAINED_FOCUS_EXCL
		^lcx:dx	- OD of object which has lost focus exclusive

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/22/90		Initial version

------------------------------------------------------------------------------@

OLTextGainedFocusExcl	method OLTextClass, MSG_META_GAINED_FOCUS_EXCL

	; HACK! due to lack of HINT_DEFAULT_TARGET handling
	;
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	call	OLTextChangeAlterExclIfSingleLineDefault

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	mov	cx, MSG_META_GAINED_SYS_FOCUS_EXCL
	mov	dx, 1 or (1 shl 8)
	mov	ax, MSG_SPEC_NOTIFY_CHILD_CHANGING_FOCUS
	call	VisCallParent
endif
	ret

OLTextGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redraw text display to show focus change
		redraw text display to show clipped text

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL,
		MSG_META_LOST_SYS_FOCUS_EXCL
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TEXT_DISPLAY_FOCUSABLE or CLIP_SINGLE_LINE_TEXT

OLTextGainedLostSysFocusExcl	method dynamic OLTextClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL,
					MSG_META_LOST_SYS_FOCUS_EXCL

if CLIP_SINGLE_LINE_TEXT
	mov	bx, ax				; save msg
endif
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

if CLIP_SINGLE_LINE_TEXT
	;
	; if display object, redraw to show focus state
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	redraw		; not editable, just redraw to show focus state
				;	(no need to check TDSS_FOCUSABLE as we
				;	 acutally gaining/losing focus)
	;
	; if single-line editable object, and lost focus, and overflow,
	; scroll to beginning then redraw to show clipping
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	done
	push	bx		; save message
	call	CheckTextOverflow
	pop	bx		; bx = message
	jnc	done		; no scrolling needed

	clr	cx		; scroll from start
	cmp	bx, MSG_META_LOST_SYS_FOCUS_EXCL
	je	scrollAndRedraw
	;
	; gained focus, just ensure selection (or cursor) is visible
	;
	mov	cx, ds:[di].VTI_cursorPos.P_x
scrollAndRedraw:
	add	cx, ds:[di].VI_bounds.R_left
	add	cx, ds:[di].VTI_leftOffset
	add	cl, ds:[di].VTI_lrMargin
	adc	ch, 0		; show left edge
	mov	ax, MSG_VIS_TEXT_SCROLL_ONE_LINE
	call	ObjCallInstanceNoLock
else
	;
	; if text display object, show new focus state
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jnz	done
endif ; CLIP_SINGLE_LINE_TEXT

redraw::
if TEXT_DISPLAY_FOCUSABLE
	;
	; if we are in a view, tell view to redraw, as it shows focus for us
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	notInView
	mov	si, ds:[di].OLTDI_viewObj		; *ds:si = view
notInView:
	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock
	pop	si
else
	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock
endif

if CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP
	;
	; if clipped display object, show bubble text on gained focus
	; close bubble text on lost focus
	;
	call	OLTextDoBubbleText
endif

done:
	ret
OLTextGainedLostSysFocusExcl	endm

endif ; TEXT_DISPLAY_FOCUSABLE or CLIP_SINGLE_LINE_TEXT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set floating keyboard type

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUI

if TEXT_DISPLAY_FOCUSABLE or CLIP_SINGLE_LINE_TEXT
PrintMessage <TEXT_DISPLAY_FOCUSABLE or CLIP_SINGLE_LINE_TEXT not supported for DUI>
endif

OLTextGainedSysFocusExcl	method dynamic OLTextClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL
	.enter
	;
	; call superclass for default handling
	;
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	;
	; set keyboard type, if doing keyboard
	;
	call	CheckIfKeyboardRequired
	jnc	done
	call	SetKeyboardType
done:
	.leave
	ret
OLTextGainedSysFocusExcl	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextDoBubbleText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle bubble text

CALLED BY:	OLTMetaGainedLostSysFocusExcl
PASS:		*ds:si = OLText
		bx = MSG_META_GAINED/LOST_SYS_FOCUS_EXCL
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP

OLTextDoBubbleText	proc	near

	push	ds
	mov	di, segment olBubbleOptions
	mov	ds, di
	mov	bp, ds:[olBubbleDisplayTime]	; bp = time out
	test	ds:[olBubbleOptions], mask BO_DISPLAY
	pop	ds
	jz	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jnz	done
	test	ds:[di].OLTDI_moreState, mask TDSS_CLIPPED
	jz	done
	cmp	bx, MSG_META_GAINED_SYS_FOCUS_EXCL
	jne	lostFocus
	mov	cx, ds
	mov	di, ds:[di].VTI_text
	mov	dx, ds:[di]			; cx:dx = text
	mov	ax, TEMP_OL_TEXT_BUBBLE_TEXT
	mov	bx, MSG_OL_TEXT_BUBBLE_TIME_OUT
	call	OpenCreateBubbleHelp
	jmp	short done

lostFocus:
	mov	ax, TEMP_OL_TEXT_BUBBLE_TEXT
	call	OpenDestroyBubbleHelp
done:
	ret
OLTextDoBubbleText	endp

endif	; CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextBubbleTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bubble text time out, close bubble text

CALLED BY:	MSG_OL_TEXT_BUBBLE_TIME_OUT
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
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

if CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP

OLTextBubbleTimeOut	method dynamic OLTextClass, 
					MSG_OL_TEXT_BUBBLE_TIME_OUT
	mov	ax, TEMP_OL_TEXT_BUBBLE_TEXT
	call	ObjVarFindData
	jnc	done
	mov	ds:[bx].BHD_timer, 0
	call	OpenDestroyBubbleHelp
done:
	ret
OLTextBubbleTimeOut	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update bubble text

CALLED BY:	MSG_META_EXPOSED
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
		cx	= window
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP

OLTextExposed	method dynamic OLTextClass, MSG_META_EXPOSED
	mov	di, cx
	call	GrCreateState
	call	GrBeginUpdate

	mov	ax, TEMP_OL_TEXT_BUBBLE_TEXT
	call	ObjVarFindData
	jnc	endUpdate

	push	si
	mov	si, ds:[bx].BHD_borderRegion
	mov	si, ds:[si]
	clr	ax, bx
	call	GrDrawRegion
	pop	si

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	bx, ds:[si].VTI_text
	tst	bx
	jz	endUpdate

	mov	si, ds:[bx]		; ds:si = text
	mov	ax, BUBBLE_HELP_TEXT_X_MARGIN
	mov	bx, BUBBLE_HELP_TEXT_Y_MARGIN
	clr	cx
	call	GrDrawText
endUpdate:
	call	GrEndUpdate
	GOTO	GrDestroyState

OLTextExposed	endm

endif ; CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If text is redrawn, update bubble text

CALLED BY:	MSG_VIS_TEXT_SCREEN_UPDATE
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/ 2/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP

OLTextScreenUpdate	method dynamic OLTextClass, 
					MSG_VIS_TEXT_SCREEN_UPDATE
	;
	; let superclass do the update
	;
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	;
	; update bubble text, if active
	;
	mov	ax, TEMP_OL_TEXT_BUBBLE_TEXT
	call	ObjVarFindData
	jnc	done
	;
	; bring down bubble text
	;
	mov	bx, MSG_META_LOST_SYS_FOCUS_EXCL
	call	OLTextDoBubbleText
	;
	; put up bubble text (restarts timer, oh well...)
	;
	mov	bx, MSG_META_GAINED_SYS_FOCUS_EXCL
	call	OLTextDoBubbleText
done:
	ret
OLTextScreenUpdate	endm

endif ; CLIP_SINGLE_LINE_TEXT and BUBBLE_HELP


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextLostFocusExcl -- 
		MSG_META_LOST_FOCUS_EXCL for OLTextClass

DESCRIPTION:	Gives up the default if we took it earlier.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_LOST_FOCUS_EXCL

RETURN:		

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/22/90		Initial version

------------------------------------------------------------------------------@

OLTextLostFocusExcl	method OLTextClass, MSG_META_LOST_FOCUS_EXCL

	mov	cx, SVQT_RELEASE_DEFAULT_EXCLUSIVE
	call	OLTextChangeAlterExclIfSingleLineDefault

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	mov	cx, MSG_META_LOST_SYS_FOCUS_EXCL
	mov	dx, 1 or (1 shl 8)
	mov	ax, MSG_SPEC_NOTIFY_CHILD_CHANGING_FOCUS
	call	VisCallParent
endif
	ret
OLTextLostFocusExcl	endm

OLTextChangeAlterExclIfSingleLineDefault	proc	far

if not GEN_VALUES_ARE_TEXT_ONLY
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
else
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- GenInstance
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
endif
	jz	keepDefaultHere			;not single line, keep default
						;  here, rather than on some
						;  reply bar button 2/ 9/93 cbh

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_moreState, \
			mask TDSS_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
	jz	exit				;no need to take/release default

keepDefaultHere:
	mov	ax, MSG_VIS_VUP_QUERY
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	VisCallParent
exit:
	ret
OLTextChangeAlterExclIfSingleLineDefault	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextActivate -- 
		MSG_GEN_ACTIVATE for OLTextClass

DESCRIPTION:	Activates the text object.

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
	Chris	2/22/90		Initial version

------------------------------------------------------------------------------@

OLTextActivate	method OLTextClass, MSG_GEN_ACTIVATE

EC <	call	ECCheckGenTextObject				>
	mov	cx, -1
	mov	ax, MSG_GEN_TEXT_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock

	;
	; If we're in delayed mode, send an apply and mark the dialog as
	; applyable.  There shouldn't be a reason to mark a non-delayed dialog
	; as applyable, so I've changed the code.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
;	jnz	makeApplyable			;in delayed mode, branch
	jnz	exit				;in delayed mode, exit

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
	call	ObjMessage

	;Shouldn't have to make applyable.  If the user dirtied the text, it's
	;already happened, and otherwise it shouldn't.  -cbh 9/ 8/92

;	jmp	short	exit			;exit now, don't need applyable
;
;makeApplyable:
;	mov	ax, MSG_OL_VUP_MAKE_APPLYABLE
;	call	VisCallParent			;does not trash BX
exit:
	ret
	
OLTextActivate	endm






COMMENT @----------------------------------------------------------------------

METHOD:		OLTextGenMakeApplyable -- 
		MSG_GEN_MAKE_APPLYABLE for OLTextClass

DESCRIPTION:	Makes the dialog box applyable if needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_MAKE_APPLYABLE

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
	chris	2/ 1/93         	Initial Version

------------------------------------------------------------------------------@

OLTextGenMakeApplyable	method dynamic	OLTextClass, \
				MSG_GEN_MAKE_APPLYABLE

	;
	; Not a property, do not make dialog boxes applyable!
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
	jz	exit
	
	;
	; Send straight to view if we're in one.  We may be getting this
	; before we're fully opened.  -cbh 2/18/93
	;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	callParent
	mov	si, ds:[di].OLTDI_viewObj
callParent:
	call	VisCallParentEnsureStack
exit:
	ret
OLTextGenMakeApplyable	endm




COMMENT @----------------------------------------------------------------------

MESSAGE:	OLTextEmptyStatusChanged --
			MSG_META_TEXT_EMPTY_STATUS_CHANGED for OLTextClass

DESCRIPTION:	Handle ATTR_GEN_TEXT_SET_OBJECT_ENABLED_WHEN_TEXT_EXISTS

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - The message

	cx:dx - text object (this object)
	bp - non-zero if text is becoming non-empty

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/20/92		Initial version

------------------------------------------------------------------------------@
OLTextEmptyStatusChanged	method dynamic	OLTextClass,
					MSG_META_TEXT_EMPTY_STATUS_CHANGED

EC <	call	ECCheckGenTextObject				>
	push	ax, cx, dx, si, bp
	mov	ax, ATTR_GEN_TEXT_SET_OBJECT_ENABLED_WHEN_TEXT_EXISTS
	call	ObjVarFindData
	jnc	toSuper

	; ds:bx is object to change -- if handle 0 then same block

	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	tst	bx
	jnz	10$
	mov	bx, ds:[LMBH_handle]
10$:
	mov	ax, MSG_GEN_SET_ENABLED
	tst	bp
	jnz	20$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
20$:
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

toSuper:
	pop	ax, cx, dx, si, bp
	mov	di, offset OLTextClass
	GOTO	ObjCallSuperNoLock

OLTextEmptyStatusChanged	endm

GadgetCommon ends

;--------------------

CommonFunctional segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	override default VisTextClass behavior, allow giving
		focus to text display object

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
RETURN:		ax	= MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TEXT_DISPLAY_FOCUSABLE or SHORT_LONG_TOUCH
OLTextStartSelect	method dynamic OLTextClass, 
					MSG_META_START_SELECT
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

if SHORT_LONG_TOUCH
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jnz	noTouch
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	noTouch

	; If selectable, then VisText will take gadget and grab mouse.

	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jnz	startTouch

	push	ax
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	call	VisGrabMouse		; ~selectable, grab mouse here
	pop	ax

startTouch:
	call	StartShortLongTouch
noTouch:
endif

if TEXT_DISPLAY_FOCUSABLE
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jnz	done
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	done
	push	ax
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	pop	ax
endif

done:
	ret
OLTextStartSelect	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTVisTextModifyEditableSelectable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	update our flags, as well

CALLED BY:	MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
		cl	= VisTextStates to set
		ch	= VisTextStates to clear
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	12/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TEXT_DISPLAY_FOCUSABLE or _ISUI
OLTVisTextModifyEditableSelectable	method dynamic OLTextClass, 
					MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	.enter
	;
	; call superclass for default handling
	;
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	;
	; update our flags
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	
	andnf	ds:[di].OLTDI_moreState, not mask TDSS_SELECTABLE
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	haveSelectable
	ornf	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
haveSelectable:
	andnf	ds:[di].OLTDI_specState, not mask TDSS_EDITABLE
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	haveEditable
	ornf	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
haveEditable:
	.leave
	ret
OLTVisTextModifyEditableSelectable	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= OLTextClass object
		ds:di	= OLTextClass instance data
		ds:bx	= OLTextClass object (same as *ds:si)
		es 	= segment of OLTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SHORT_LONG_TOUCH
OLTextEndSelect	method dynamic OLTextClass, 
					MSG_META_END_SELECT,
					MSG_META_LARGE_END_SELECT
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jnz	done
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	done

	; If selectable, then VisText will release mouse

	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jnz	endTouch

	call	VisReleaseMouse		; ~selectable, release mouse here

endTouch:
	call	EndShortLongTouch
done:
	ret
OLTextEndSelect	endm
endif

CommonFunctional ends

;--------------------

Utils segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetTextKbdBindings

DESCRIPTION:	Return a pointer to the table of keyboard bindings

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ds:si - binding table

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/24/92		Initial version

------------------------------------------------------------------------------@
global SpecGetTextKbdBindings:far
SpecGetTextKbdBindings	proc	far
	mov	si, segment textKbdBindings
	mov	ds, si
	mov	si, offset textKbdBindings
	ret

SpecGetTextKbdBindings	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetTextPointerImage

DESCRIPTION:	Return an optr to the pointer image for text

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	cxdx - pointer image

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/24/92		Initial version

------------------------------------------------------------------------------@
global SpecGetTextPointerImage:far
SpecGetTextPointerImage	proc	far
	mov	cx, handle textEditCursor
	mov	dx, offset textEditCursor
	ret

SpecGetTextPointerImage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecDrawTextCursor

DESCRIPTION:	Draw the text cursor

CALLED BY:	GLOBAL

PASS:
	*ds:si - VisText object
	di - gstate to draw in with:
	     x position - in the middle of the white area between characters
	     y position - the baseline
	     font, text style - set for character before cursor

RETURN:
	none

DESTROYED:
	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/24/92		Initial version
	stevey	12/20/95	Jedi version

------------------------------------------------------------------------------@
global SpecDrawTextCursor:far

if not GRAFFITI_TEXT_CURSORS
SpecDrawTextCursor	proc	far	uses ax, bx, cx, dx, si
	class	VisTextClass
	.enter
	;
	; See if we should draw the cursor regardless of whether it is
	; the focus or not
	;
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	jc	drawRegardless
	;
	; only draw if target or focus
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_intSelFlags,
				mask VTISF_IS_FOCUS or mask VTISF_IS_TARGET
	LONG jz	done

drawRegardless:
	mov	al, SDM_100
	call	GrSetAreaMask

if XOR_TEXT_CURSOR
	mov	al, MM_XOR
else
	mov	al, MM_INVERT
endif
	call	GrSetMixMode

if I_BEAM_TEXT_CURSOR
	push	si
endif

if _ISUI
	; instead of using GFMI_ASCENT, base ascent on GFMI_HEIGHT
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics				;dx = height
	sub	dx, 2					;fudge factor
	mov	cx, dx
	mov	si, GFMI_DESCENT or GFMI_ROUNDED
	call	GrFontMetrics				;dx = descent
	sub	cx, dx					;ascent = h-2-descent
else
	mov	si, GFMI_ASCENT or GFMI_ROUNDED
	call	GrFontMetrics				;dx = ascent
	mov	cx, dx					;cx = ascent
	mov	si, GFMI_DESCENT or GFMI_ROUNDED
	call	GrFontMetrics				;dx = descent
endif

	call	GrGetCurPos				;(ax,bx) = (x,y) pos
	add	dx, bx					;bottom = y + descent

	sub	bx, cx					;top = y - ascent
if I_BEAM_BEVEL
	dec	dx				; adjust bounds for bevel
endif
	mov	cx, ax
	inc	cx					;right = left + 1

if I_BEAM_TEXT_CURSOR
	pop	si				; *ds:si = text object

if I_BEAM_BEVEL
	add	bx, I_BEAM_TEXT_CURSOR_WIDTH/2
	sub	dx, I_BEAM_TEXT_CURSOR_WIDTH/2
	call	GrFillRect
	sub	bx, I_BEAM_TEXT_CURSOR_WIDTH/2
	add	dx, I_BEAM_TEXT_CURSOR_WIDTH/2
else
	inc	bx				; make room on top for I-beam
	dec	dx				; make room on bottom for
						;	I-beam
	call	GrFillRect
endif
	;
	; draw I-beam cursor, must make a bad hack to remove clip rect
	; to allow the horizontal pieces to draw completely when at
	; ends of the text object
	;
	call	GrSaveState			; save current clip rect
if not I_BEAM_BEVEL  ; bevel is too big to override clipping
	push	ax, bx, cx, dx			; save cursor coords
	call	VisGetSize			; cx = width, dx = height
	jcxz	noClip				; no size, leave clip
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	sub	dl, ds:[si].VTI_tbMargin
	sbb	dh, 0
	sub	dl, ds:[si].VTI_tbMargin	; dx = actual height
	sbb	dh, 0
	test	ds:[si].OLTDI_specState, mask TDSS_IN_VIEW
	mov	si, PCT_NULL
	jnz	inView				; view will clip
	mov	ax, -1				; as far left as possible
	clr	bx
	mov	si, PCT_REPLACE			; remove old clip rect
inView:
	call	GrSetClipRect
noClip:
	pop	ax, bx, cx, dx			; restore cursor coords
endif
	sub	ax, I_BEAM_TEXT_CURSOR_WIDTH/2
	add	cx, I_BEAM_TEXT_CURSOR_WIDTH/2
if I_BEAM_BEVEL
crossBarLoop:
	push	bx, dx
endif
	push	dx				; save bottom
	mov	dx, bx				; bottom = top
	dec	bx				; top--
	call	GrFillRect			; draw top line
	pop	dx				; dx = bottom
	mov	bx, dx				; top = bottom
	inc	dx				; bottom++
	call	GrFillRect			; draw bottom line
if I_BEAM_BEVEL
	pop	bx, dx
	dec	dx
	inc	bx
	inc	ax
	dec	cx
	cmp	ax, cx
	jl	crossBarLoop
endif
	call	GrRestoreState
else
	call	GrFillRect
endif ; I_BEAM_TEXT_CURSOR
	mov	al, MM_COPY
	call	GrSetMixMode
done:
	.leave
	ret
SpecDrawTextCursor	endp

else	; GRAFFITI_TEXT_CURSORS

JEDI_CURSOR_WIDTH	equ	6

SpecDrawTextCursor	proc	far
		class	VisTextClass
		uses	ax, bx, cx, dx, si, bp

		oldState	local	VisTextCursorType
		newState	local	VisTextCursorType
		drawPos		local	Rectangle
		selFlags	local	VisTextIntSelFlags
		textBlock	local	hptr

		.enter
	;
	; only draw if target or focus
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset
		test	ds:[bx].VTI_intSelFlags,
		mask VTISF_IS_FOCUS or mask VTISF_IS_TARGET
		LONG	jz	done

		mov	al, ds:[bx].VTI_intSelFlags
		mov	selFlags, al			; store for later
	;
	;  Save block for dereferencing later.
	;
		mov	ax, ds:[LMBH_handle]
		mov	textBlock, ax
	;
	;  Set up gstate to do an inverted cursor.
	;
		mov	al, SDM_100
		call	GrSetAreaMask

		mov	al, MM_INVERT
		call	GrSetMixMode
	;
	;  Get HWR lock state.  If no HWR library, or locked state can't
	;  be found, use the normal text cursor.
	;
		call	UserGetHWRLibraryHandle
		tst	ax				; use normal if no HWR
		jz	setNewState

		mov_tr	bx, ax				; bx = lib handle
		mov	ax, HWRR_GET_LOCKED_STATE
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable		; ax = HWRLockState
setNewState:
	;
	;  Convert the HWRLockState into a VisTextCursorType and save it.
	;  Is there an easier way to do this?
	;
		mov	newState, VTCT_NORMAL_CURSOR	; assume normal
		tst	al
		jz	getDrawPos
		mov	newState, VTCT_NUMLOCK_CURSOR
		test	al, mask HWRLS_NUM_LOCK
		jnz	getDrawPos
		mov	newState, VTCT_CAPLOCK_CURSOR
		test	al, mask HWRLS_CAP_LOCK
		jnz	getDrawPos
		mov	newState, VTCT_EQNLOCK_CURSOR
		test	al, mask HWRLS_EQN_LOCK
		jnz	getDrawPos
		mov	newState, VTCT_NORMAL_CURSOR	; error => use normal
getDrawPos:
	;
	;  Set up oldState variable.
	;
		call	GetPreviousCursor		; also sets vardata
	;
	;  Get position at which to draw.
	;
		mov	si, GFMI_ASCENT or GFMI_ROUNDED
		call	GrFontMetrics			; dx = ascent
		mov	cx, dx				; cx = ascent
		
		mov	si, GFMI_DESCENT or GFMI_ROUNDED
		call	GrFontMetrics			; dx = descent
		add	dx, cx				; width = ascent+descent

		call	GrGetCurPos			; (ax, bx) = (x, y) pos
		sub	bx, cx				; top = y - ascent

		sub	ax, (JEDI_CURSOR_WIDTH/2)	; center around x pos
if 1
	;
	;  Don't let ax get negative; the cursor disappears.  This hack
	;  can remain in place until someone figures out how to make the
	;  cursor draw outside the bounds of the passed gstate.
	;
		cmp	ax, -1
		jge	gotCoords
		mov	ax, -1				; OK, maybe a little...
gotCoords:
endif
		mov	drawPos.R_left, ax
		mov	drawPos.R_top, bx
	;
	;  Set up the bitmap segment.
	;
		mov	bx, handle DrawBWRegions
		call	MemLock
		mov	ds, ax
	;
	;  if we're turning ON:
	;	draw new cursor no matter what
	;  if we're turning OFF:
	;	if state has changed, draw old cursor,
	;	else draw new cursor
	;
		mov	bx, newState
		test	selFlags, mask VTISF_CURSOR_ON	; set if turning ON
		jnz	drawCursor
	;
	;  We only need to erase the old one if the state has changed.
	;
		mov	ax, newState
		cmp	ax, oldState
		je	drawCursor			; hasn't changed
		mov	bx, oldState
drawCursor:
	;
	;  The parameters passed to GrDrawRegion are height & width,
	;  not right & bottom absolute coordinates.
	;
		mov	si, offset graffitiCursorTable
		mov	si, ds:[si][bx]			; si = region offset
		mov	ax, drawPos.R_left
		mov	bx, drawPos.R_top
		mov	cx, JEDI_CURSOR_WIDTH		; fixed width 4 now
		call	GrDrawRegion
	;
	;  Clean up.
	;
		mov	bx, handle DrawBWRegions
		call	MemUnlock

		mov	al, MM_COPY
		call	GrSetMixMode

		mov	bx, textBlock
		call	MemDerefDS
done:
		.leave
		ret
SpecDrawTextCursor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviousCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the old cursor, and if necessary, set the new one.

CALLED BY:	SpecDrawTextCursor (GRAFFITI_TEXT_CURSORS version)

PASS:		ss:bp	= SpecDrawTextCursor stack frame
		*ds:si	= VisTextInstance
		ss:newState must be initialized

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:

	sets ss:oldState
	may add or remove vardata

PSEUDO CODE/STRATEGY:

	if no cursor vardata exists, oldState = VTCS_NORMAL_CURSOR,
	  otherwise read it from the vardata

	if newState differs from oldState, set vardata to reflect new state.

	Note:  we remove the vardata when we've got a normal cursor,
	rather than keeping it around, primarily to save space under
	normal circumstances.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 3/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPreviousCursor	proc	near
		uses	ax,bx
		.enter	inherit	SpecDrawTextCursor
	;
	;  Check for vardata.
	;
		mov	ax, TEMP_VIS_TEXT_CURSOR_TYPE
		call	ObjVarFindData			; carry set if found
		mov	ax, VTCT_NORMAL_CURSOR
		jnc	normal
	;
	;  Read type from varData
	;
		mov	ax, ds:[bx]
EC <		cmp	ax, VisTextCursorType				>
EC <		ERROR_AE -1			; argh!			>
normal:
	;
	;  Store in oldState.  See if oldState differs from newState.
	;
		mov	oldState, ax
		cmp	newState, ax
		je	exit			; no different; we're done
	;
	;  newState is different:  change vardata on object.
	;
		cmp	newState, VTCT_NORMAL_CURSOR
		mov	ax, TEMP_VIS_TEXT_CURSOR_TYPE
		je	removeData

		mov	cx, size word
		call	ObjVarAddData		; will use existing vardata
		mov	ax, newState
		mov	{word}ds:[bx], ax
		jmp	exit
removeData:
		call	ObjVarDeleteData
exit:
		.leave
		ret
GetPreviousCursor	endp

Utils		ends
DrawBWRegions	segment	resource

;
;  The regions look like this:
;
;				   Alex-	            Steve-
;      Normal        NumLock      EqnLock       CAPS       EqnLock
; 							
;      ..###.        ######       ######       ......      ...###	        
;      ..###.        ###.##       ######       ......	   ..##..	
;      ..###.        ##..##       ......       ......	   ..##..	
;      ..###.        #...##       #.###.       ......	   ..##..	
;      ..###.        ##..##       ##.###       ......	   ..##..	
;      ..###.        ##..##       ###.##       ..##..	   ..##..	
;      ..###.        ##..##       ####.#       ..##..	   ..##..	
;      ..###.        ##..##       ####.#       ..##..	   ..##..	
;      ..###.        ##..##       ###.##       .####.	   ..##..	
;      ..###.        ##..##       ##.###       .####.	   ..##..	
;      ..###.        ##..##       #.###.       .####.	   ..##..	
;      ..###.        ##..##       ......       ######	   ..##..	
;      ..###.        #....#       ######       ######	   ..##..	
;      ..###.        ######       ######       ######	   ###...	 
;     							
;   New cursor definitions... (sigh)
;
;   +------+       +------+      +------+      +------+
;   |..###.|       |######|      |######|      |..##..|
;   |..###.|       |###.##|      |###...|      |.####.|
;   |..###.|       |#...##|      |##..##|      |######|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |##..##|      |##..##|      |..##..|
;   |..###.|       |#....#|      |...###|      |.####.|
;   |..###.|       |######|      |######|      |######|
;   +------+       +------+      +------+      +------+ 
;
;  PARAM_2 is specified in the region definitions, instead of a fixed
;  width, in case someone decides to make them variable-width or whatever.
;  We could just as easily have used JEDI_CURSOR_WIDTH-1, etc.
;

graffitiCursorTable	nptr	\
	offset	NormalCursor,			; VTCT_NORMAL_CURSOR
	offset	CapsCursor,			; VTCT_CAPLOCK_CURSOR
	offset	NumberCursor,			; VTCT_NUMLOCK_CURSOR
	offset	EqLockCursor			; VTCT_EQNLOCK_CURSOR

NormalCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	; left, top, right, bottom
	word	PARAM_3-1, 2, PARAM_2-2,		EOREGREC
	word	EOREGREC

NumberCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	; left, top, right, bottom
	word	0, 0, PARAM_2-1,	 		EOREGREC
	word	1, 0, 2, 4, PARAM_2-1,			EOREGREC
	word	2, 0, 1, 4, PARAM_2-1,			EOREGREC
	word	3, 0, 0, 4, PARAM_2-1,			EOREGREC
	word	PARAM_3-3, 0, 1, 4, PARAM_2-1,		EOREGREC
	word	PARAM_3-2, 0, 0, 5, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, 0, PARAM_2-1,		EOREGREC
	word	EOREGREC

if 0
;
;  This is a pointer like the one in the Omnigo 100's annunciator area.
;
CapsCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	; left, top, right, bottom
	word	4, 					EOREGREC
	word	7, 2, 3,				EOREGREC
	word	10, 1, PARAM_2-2,			EOREGREC
	word	PARAM_3-1, 0, PARAM_2-1,		EOREGREC
	word	EOREGREC

else
;
;  This is an "up-arrow".
;
CapsCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	; left, top, right, bottom
	word	0, 2, 3,				EOREGREC
	word	1, 1, 4,				EOREGREC
	word	2, 0, 5,				EOREGREC
	word	PARAM_3-3, 2, 3,			EOREGREC
	word	PARAM_3-2, 1, 4,			EOREGREC
	word	PARAM_3-1, 0, 5,			EOREGREC
	word	EOREGREC
endif

if 0	
;
;  This is the non-inverted integral sign.
;
EqLockCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1
	word	0, 		3, PARAM_2-1,		EOREGREC
	word	PARAM_3-2, 	2, 3,			EOREGREC
	word	PARAM_3-1, 	0, 2,			EOREGREC
	word	EOREGREC

DrawBWRegions	ends
else
;
;  This is the inverted integral sign.
;
EqLockCursor	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1
	word	0, 0, 5,				EOREGREC
	word	1, 0, 2,				EOREGREC
	word	PARAM_3-3, 0, 1, 4, 5,			EOREGREC
	word	PARAM_3-2, 3, 5,			EOREGREC
	word	PARAM_3-1, 0, 5,			EOREGREC
	word	EOREGREC

DrawBWRegions	ends
endif

Utils		segment	resource

endif		; GRAFFITI_TEXT_CURSORS

Utils ends

;---------------------------------

GadgetCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextSetHWRContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the HWR context for the text object based on where
		the object is on screen.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextSetHWRContext	method	OLTextClass, MSG_VIS_TEXT_SET_HWR_CONTEXT

	context		local	HWRContext
	libHandle	local	hptr
	.enter

;	If this is a one-line text edit object, get the bounds of the 
;	reference lines and pass them to the object.

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	je	exit


	call	UserGetHWRLibraryHandle
	mov	libHandle, ax

	call	VisQueryWindow
	call	VisGetBounds
	call	WinTransform
	mov	context.HWRC_boxed.HWRBD_mode, HM_BOX
	mov	context.HWRC_boxed.HWRBD_top, bx

	mov	bx, dx
	call	WinTransform
	mov	context.HWRC_boxed.HWRBD_bottom, bx


	lea	di, context
	pushdw	ssdi
	mov	ax, HWRR_SET_CONTEXT
	mov	bx, libHandle
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
exit:
	.leave
	ret
OLTextSetHWRContext	endp

GadgetCommon ends

ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextSetIndeterminateState -- 
		MSG_GEN_TEXT_SET_INDETERMINATE_STATE for OLTextClass

DESCRIPTION:	Specific UI handler for setting indeterminate state.  We revert
		the text object to drawing in a 50% pattern if indeterminate.
		This *should* only get called if there were an actual change
	 	in the indeterminate state.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_TEXT_SET_INDETERMINATE_STATE
		cx	- flag for indeterminate state

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
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

OLTextSetIndeterminateState	method dynamic	OLTextClass, \
				MSG_GEN_TEXT_SET_INDETERMINATE_STATE

	;
	; Set the 50-pct flag as appropriate.
	;
	tst	cx				

	mov	cx, mask VTF_USE_50_PCT_TEXT_MASK	;bit to set
	mov	dx, 0					;bit to clear
	
	jnz	10$					;indeterminate, set bit
	xchg	cx, dx					;Not! Clear bit
10$:
	not	dx
	and	ds:[di].VTI_features, dx
	or	ds:[di].VTI_features, cx

	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock

	;
	; We'll set the text object clean, so we can mark it not indeterminate
	; on the next text change.  The modified state has not been changed,
	; so the set-clean shouldn't cause any problems.
	;
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	ObjCallInstanceNoLock
	ret
OLTextSetIndeterminateState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextGetActivatorBounds -- 
		MSG_META_GET_ACTIVATOR_BOUNDS for OLTextClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Gets bounds of activator.

PASS:		*ds:si 	- instance data
		es     	- segment of OLTextClass
		ax 	- MSG_META_GET_ACTIVATOR_BOUNDS

RETURN:		carry set if an activating object found
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

OLTextGetActivatorBounds	method dynamic	OLTextClass, \
				MSG_META_GET_ACTIVATOR_BOUNDS
	.enter
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		;BP <- GState handle
	mov	di, bp

	call	VisGetBounds	;AX <- left edge of the object
	mov	dx, bx
	call	GetTextObjectLineHeight	;BX <- height of text object lines
	shr	bx, 1
	add	bx, dx		;BX <- middle of first line of object 

	;
	; We're going to make sure that this point is within the visible
	; bounds of the window we are in.  If it isn't, then return carry
	; clear which indicates that "the activator object couldn't be found".
	;
	call	CheckIfPointInWinBounds
	jnc	done

	call	GrTransform	;Transform AX,BX to screen coords
	call	GrDestroyState

	mov	cx, ax		;AX,CX <- left edge of obj
	mov	bp, bx		;BP,DX <- middle of obj vertically
	mov	dx, bx

	;
	; If we're in a composite, pass the left edge as the left edge of
	; the composite.   It's an important distinction, for showing the
	; window whether we're completely underneath it or not.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE
	jz	notInComp
	call	VisFindParent
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_left
notInComp:

	stc			;found an object.
done:
	.leave
	ret
OLTextGetActivatorBounds	endm

endif

ActionObscure 		ends
