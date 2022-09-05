COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Win (window code specific to OpenLook)
FILE:		winDraw.asm

ROUTINES:
	Name				Description
	----				-----------
	OpenWinGetBounds		gets bounds for object
	OpenWinGetInsideShadowBounds	gets bounds inside the shadow if any
	OpenWinGetInsideLineBorderBounds
					gets bounds inside shadow and frame line
	OpenWinGetHeaderBounds		gets bounds of header
	OpenWinInitGState		sets up font, etc. info in GState
	OpenWinDraw			METHOD_DRAW handler for OLWinClass
	OpenWinDrawHeaderBackground	draws background for header area
	OpenWinDrawHeaderLine		draws line below header
	OpenWinDrawHeaderTitleBackground draws background for title area
	OpenWinDrawHeaderMarks		draws Close Mark and Pins.
	OpenWinDrawHeaderTitle		draws title in header area
	OpenWinGetHeaderColors		sets up colors to use depending on focus
	OpenWinDrawMultiPlaneBitmap	draws a Close Mark or Pin
	OpenWinDrawBitmapPlane		draws one plane of a bitmap
	OpenWinDrawShadowBackground	draws the background for a shadowed win.
	OpenWinDrawBackground		draws background for non-shadowed win.
	OpenWinDrawBorder		draws thick line border (Notice windows)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Eric	9/89		moved from CommonUI/CWin since 90% of
				file because specific-ui dependent.

DESCRIPTION:

	$Id: winDraw.asm,v 1.1 97/04/07 10:56:28 newdeal Exp $

-------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetBounds
		OpenWinGetInsideShadowBounds
		OpenWinGetInsideBorderBounds
		OpenWinGetHeaderBounds

DESCRIPTION:	These procedures return the bounds for an aspect of the window.

PASS:		*ds:si	= instance data for object
		ds:bp	= instance data for object

RETURN:		(ax, bx) - (cx, dx) = bounds
		ds, si, di, bp = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

;This procedure gets the boundary coordinates of the window, relative to itself.

OpenWinGetBounds	proc	near
	;we cannot use VisGetBounds because this object is a WINDOWED object.

	call	VisGetSize
	clr	ax
	clr	bx
	dec	cx
	dec	dx
	ret
OpenWinGetBounds	endp

;OpenLook: The bounds returned do not include the shadow area, if any.

OpenWinGetInsideShadowBounds	proc	near
	call	OpenWinGetBounds

	;(ax, bx) - (cx, dx) = bounds of window object
	;is there a shadow? (Pinned menus have shadows)

	test	ds:[bp].OLWI_attrs, mask OWA_SHADOW
	jz	noShadow		;skip if no shadow area...

	sub	cx, OLS_WIN_SHADOW_SIZE ;Yes: move bounds in from bottom right
	sub	dx, OLS_WIN_SHADOW_SIZE

noShadow:
	ret
OpenWinGetInsideShadowBounds	endp

;This procedure returns the size of the window, less the size of the shadow,
;less the size of the thin black outline framing the window.

OpenWinGetInsideLineBorderBounds	proc	near
	call	OpenWinGetInsideShadowBounds	;get window bounds, less
						;shadow area

	;assume this window has a thin-line border

	add	ax, OLS_WIN_LINE_BORDER_X_MARGIN
	add	bx, OLS_WIN_LINE_BORDER_Y_MARGIN
	sub	cx, OLS_WIN_LINE_BORDER_X_MARGIN
	sub	dx, OLS_WIN_LINE_BORDER_Y_MARGIN

	;if this window has a thick-line border, increase this margin

	test	ds:[bp].OLWI_attrs, mask OWA_THICK_LINE_BORDER
	jz	noLineBorder

	add	ax, OLS_WIN_THICK_BORDER_EXTRA_X_MARGIN
	add	bx, OLS_WIN_THICK_BORDER_EXTRA_Y_MARGIN
	sub	cx, OLS_WIN_THICK_BORDER_EXTRA_X_MARGIN
	sub	dx, OLS_WIN_THICK_BORDER_EXTRA_Y_MARGIN

noLineBorder:
	ret

OpenWinGetInsideLineBorderBounds	endp

;This procedure returns the bounds of the header area.

OpenWinGetHeaderBounds	proc	far
	push	di

	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	mov     dx, ds:[specDisplayScheme].DS_pointSize
	pop	ds

	mov	di, dx

	call	OpenWinGetInsideLineBorderBounds ;get window bounds, less shadow
						;area and thin black frame.
	mov	dx, bx

	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	50$

	add	dx, OLS_WIN_HEADER_Y_SPACING	;add margin for top and bottom
	add	dx, di				;add height of font
	jmp	short done

50$:	;for GCM headers: ignore font size (for now)

OLS <	mov	dx, OLS_GCM_HEADER_HEIGHT + \
			OLS_WIN_HEADER_BOTTOM_LINE_HEIGHT + \
			OLS_WIN_HEADER_BELOW_LINE_MARGIN >
CUAS <	mov	dx, CUAS_GCM_HEADER_HEIGHT + \
			OLS_WIN_HEADER_BOTTOM_LINE_HEIGHT + \
			OLS_WIN_HEADER_BELOW_LINE_MARGIN >

done:
	pop	di
	ret
OpenWinGetHeaderBounds	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDraw

DESCRIPTION:	Perform METHOD_DRAW given an OLWinPart

CALLED BY:	METHOD_DRAW

PASS:
	*ds:si - instance data
	bp - handle of graphics state
RETURN:		
	cl - DrawFlags: DF_UPDATE set if updating
	ch - ?
	dx - ?
	bp - GState to use

DESTROYED:
	ax, bx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	7/89		more documentation, Motif extensions

------------------------------------------------------------------------------@


OpenWinDraw	method	OLWinClass, MSG_VIS_DRAW
	push	es
	push	cx
	mov	di, bp			;di = GState

	call	OpenWinInitGState

	;(al = color scheme, ah = display type, cl = DrawFlags; ax on stack
	;ds:*si = instance, ds:bp = SpecificInstance, di = GState)

	;draw shadow (OpenLook), or resize border (Motif/CUA) if necessary.

	test	ds:[bp].OLWI_attrs, mask OWA_SHADOW			
	jz	noShadow

	call	OpenWinDrawShadowBackground				
	jmp	short afterBackground

noShadow:
	call	OpenWinDrawBackground	;draw flat background without OL shadow

afterBackground:
	;Draw header background first, since border sits over it somewhat
	;	ds:*si = object
	;	ds:bp = specific instance data for object
	;	di = gstate

	call	OpenWinDrawHeaderBackground
	call	OpenWinDrawBorder	;draw resizable frame region def.
	call	OpenWinDrawHeaderLine	;draw 2-pixel wide line BELOW header
	call	OpenWinDrawHeaderMarks	;draw close mark, pushpin
	call	OpenWinDrawHeaderTitle	;draw title moniker

	;draw long term message

	;draw status message

	;draw mode message

	;call superclass, to do children

	pop	cx
	pop	es
	mov	bp, di			;bp = GState
	mov	ax, MSG_VIS_DRAW
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock
OpenWinDraw	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinInitGState

DESCRIPTION:	Initialize graphics state for an OpenLook window.

PASS:
	*ds:si - object
	di - gstate

RETURN:
	bp - offset to Spec data in object
	al = color scheme, ah = display type
	bx, dx - private info

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

OpenWinInitGState	proc	near

	mov	bp, ds:[si]		;ds:bp = instance
	add	bp, ds:[bp].Vis_offset	;ds:bp = SpecificInstance

	;get display scheme data

	push	cx
	mov	ax, GIT_PRIVATE_DATA
	call	GrGetInfo		;ax = <display scheme><display type>
	push	ax
	clr	ah			;no fractional pointsize
	call	GrSetFont
	pop	ax
	pop	cx

	and	ah, mask DF_DISPLAY_TYPE
	cmp	ah, DC_GRAY_1		;is this a B@W display?
	jnz	color			;skip if not...

	mov	al, (C_WHITE shl 4) or C_BLACK	;use black and white
color:

	ret
OpenWinInitGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderBackground

DESCRIPTION:	Draw header for an OL window

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	di - gstate
	bp - offset to Spec data in object
	al = color scheme, ah = display type

RETURN:
	none

DESTROYED:
	bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

OpenWinDrawHeaderBackground	proc	near
	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_HEADER_AREA_INVALID or mask OLWHS_FOCUS_AREA_INVALID or mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	test	ds:[bp].OLWI_attrs, mask OWA_HEADER
	jz	done			;skip if no header...

	push	ax			;preserve color scheme
					;pass al = color scheme
	call	OpenWinGetHeaderColors	;sets ax = text color, bx = BG color
	mov	ax, bx
	call	GrSetAreaColor

	call	OpenWinGetHeaderBounds	;(ax, bx) - (cx, dx) = header bounds

	;if this window is resizable, then draw the top line of the header
	;area separately, since the resize mark overlaps the top line of the
	;header.

	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	20$			;skip if not resizable...

	inc	bx
	call	GrFillRect		;draw header minus top line

	dec	bx			;prepare to draw top line (only)
	mov	dx, bx
	add	ax, OLS_WIN_RESIZE_SEGMENT_LENGTH - OLS_WIN_LINE_BORDER_X_MARGIN
	sub	cx, OLS_WIN_RESIZE_SEGMENT_LENGTH - OLS_WIN_LINE_BORDER_X_MARGIN

20$:
	call	GrFillRect		;draw dark background

	pop	ax

done:
	ret
OpenWinDrawHeaderBackground	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderLine

DESCRIPTION:	This procedure draws a thin distinguishing line at the
		bottom of an OpenLook header area, in order to set OpenLook
		apart from those "other" user interfaces.

CALLED BY:	OpenWinDraw

PASS:		*ds:si	= instance data for object
		ds:bp	= instance data
		ax	= color scheme
		di	= GState

RETURN:		ds, si, bp, ax, di = same

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinDrawHeaderLine	proc	near
	push	ax			;preserve color scheme
					;See if we should draw a header line
	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	done

	and	ax, mask CS_darkColor
	call	GrSetLineColor

	call	OpenWinGetHeaderBounds
	inc	dx			;start on line below the header
	mov	bx, dx

	call	GrDrawLine
	inc	bx
	inc	dx

	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax

	call	GrDrawLine

	mov	ax, C_BLACK		; & set back
	call	GrSetLineColor

done:
	pop	ax			;get display scheme
	ret
OpenWinDrawHeaderLine	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderTitleBackground

DESCRIPTION:	This routine is an optimization used when just the title
		is being redrawn.

PASS:		*ds:si - object
		di - gstate
		bp - offset to Spec data in object
		al = color scheme, ah = display type

RETURN:		none

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@


OpenWinDrawHeaderTitleBackground	proc	near
	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	;see if this window has a title

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	done

	push	ax			;preserve color scheme
					;pass al = color scheme
	call	OpenWinGetHeaderColors	;sets ax = text color, bx = BG color
	mov	ax, bx
	call	GrSetAreaColor

	call	OpenWinGetHeaderTitleBounds ;(ax, bx) - (cx, dx) = header bounds
	call	GrFillRect		;draw background
	pop	ax
done:
	ret
OpenWinDrawHeaderTitleBackground	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderMarks

DESCRIPTION:	Draw the pseudo-icons which appear on the OpenLook window
		header.

PASS:		*ds:si - object
		ds:bp - specific instance data in object
		di = gstate
		al = color scheme, ah = display type

RETURN:		ds, si, di, bp, ax = same

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@


OpenWinDrawHeaderMarks	proc	near
	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	push	ax
	mov	cl, mask OLWHS_HEADER_MARK_IMAGES_INVALID
	call	OpenWinHeaderResetInvalid

	;get bounds

	call	OpenWinGetHeaderBounds
	pop	cx			;set cx = color scheme

	add	ax, OLS_WIN_HEADER_MARK_X_POSITION
	add	bx, OLS_WIN_HEADER_MARK_Y_POSITION
					;move inside left-top margin for header

	test	ds:[bp].OLWI_attrs, mask OWA_CLOSABLE
	jz	checkPinnable		;skip if not closable...

	push	ds
	push	bp
	segmov	ds, cs			;set ds:bp = BitmapPlaneDefs structure
	mov	bp, offset CloseMarkBitmapPlaneDefs
	call	OpenWinDrawMultiPlaneBitmap
	pop	bp
	pop	ds
	add	ax, OLS_CLOSE_MARK_WIDTH + OLS_CLOSE_MARK_SPACING

checkPinnable: ;draw push-pin: ax, bx = position, cx = color scheme
	test	ds:[bp].OLWI_attrs,mask OWA_PINNABLE
	jz	done

	test	ds:[bp].OLWI_specState, mask OLWSS_DRAWN_PINNED or \
					mask OLWSS_PINNED
	push	ds
	push	bp
	mov	bp, offset PushpinBitmapPlaneDefs
	jz	drawPin			;skip if is unpinned...

	mov	bp, offset PinnedPushpinBitmapPlaneDefs

drawPin:
	segmov	ds, cs			;set ds:bp = BitmapPlaneDefs structure
	call	OpenWinDrawMultiPlaneBitmap
	pop	bp
	pop	ds

done:
	mov	ax, cx			;return ax = color scheme
	ret
OpenWinDrawHeaderMarks	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderTitle

DESCRIPTION:	Draw the title for an OpenLook window.

PASS:		*ds:si	= instance data for object
		di - gstate
		bp - offset to Spec data in object
		al = color scheme, ah = display type

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinDrawHeaderTitle	proc	near
	push	ax			;preserve color scheme

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
	call	OpenWinHeaderResetInvalid

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	done			;skip if not titled...

					;pass al = color scheme
	call	OpenWinGetHeaderColors	;sets ax = title text color
	call	GrSetTextColor
	mov	ax, mask TM_DRAW_ACCENT
	call	GrSetTextMode

;	call	OpenSetGCMTitleFontInfo	;if in GCM mode, set font, etc.

	call	OpenWinGetHeaderTitleBounds
	sub	cx, ax			;set cx = width of title area
	inc	cx

	;point to generic instance data and grab textual(?) moniker

	mov	bp, di			;gstate in bp 
	push	bp			;save GState
	push	ax			;save left bound for title area
	mov	ax, cx			;ax = max width for moniker
	call	OpenWinGetMonikerSize	;get overall moniker size (cx, dx)
					;(note size check below)

	add	bx, 2			;push text down two lines line
					;(font sizes are slightly misleading)

;Removed for now. -Eric
;	call	ChrisFontHack		;lower title if font size = 12

	mov	dx, ax			;dx = width of title area		
	sub	dx, cx			;dx = amount of space around text (in X)
	tst	dx			;did it go negative? 
	jns	10$			;skip if not...

	clr	dx			;use offset of 0

10$:	;divide amount of X space around text by 2 to get offset to text
	;(No need to consider Close mark, pins, or Field Icons - since we
	;are using HeaderTitleBounds.)

	sar	dx, 1			;convert total space into offset
	pop	cx			;get left bound for title
	add	dx, cx

	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		(J_LEFT shl offset DMF_Y_JUST) or \
		mask DMF_CLIP_TO_MAX_WIDTH				      
	pop	di			 ;restore gstate
		
	push	bp
	sub	sp, size DrawMonikerArgs		;make room for args
	mov	bp, sp					;pass pointer in bp
	mov	ss:[bp].DMA_gState, di			;pass gstate
	push	di					;save it
	mov	ss:[bp].DMA_xInset, dx			;pass x inset
	mov	ss:[bp].DMA_yInset, bx			;and y inset
	sub	cx, (CUAS_TITLE_TEXT_MARGIN*2)		;allow for margins
	tst	cx					;did it do negative?
	jns	45$					;no, branch
	clr	cx
45$:
	mov	ss:[bp].DMA_xMaximum, cx		;title area is max width
	mov	ss:[bp].DMA_yMaximum, MAX_COORD		;don't clip Y
	
	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST) or \
		    mask DMF_CLIP_TO_MAX_WIDTH or \
		    mask DMF_TEXT_ONLY
		    
	call	OpenWinDrawMoniker			;draw it
	pop	di					;restore gstate
	add	sp, size DrawMonikerArgs		;dump args
	pop	bp

	mov	ax,(mask TM_DRAW_ACCENT) shl 8
	call	GrSetTextMode

done:
	mov	ax, C_BLACK		; reset text color
	call	GrSetTextColor

	pop	ax			;restore color
	ret

OpenWinDrawHeaderTitle	endp

;ChrisFontHack	proc	near
;	; temporary hack (cbh) -- the 10 point font has slightly strange 
;	; dimensions, and getting the font's size (rather than its true box
;	; height) to calculate the header height exasperates things.  For now,
;	; we'll add a pixel to the y position of the text in this case.
;	
;	cmp	dx, 12			;the 10 point font has box ht of 12
;	jne	5$			;not the droid we're looking for, branch
;	inc	bx			;else bump the height
;5$:
;	ret
;ChrisFontHack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetHeaderColors

DESCRIPTION:	This procedure returns the correct color values to use
		for the header area background and the title text.

PASS:		ds:bp	= instance data for object
		al	= color scheme

RETURN:		ax	= text color
		bx	= background color

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinGetHeaderColors	proc	near
	push	cx
	mov	bx, ax			;set bx = color scheme
	call	OpenWinTestForFocusAndTarget
	test	ax, mask HGF_SYS_EXCL
					;get FOCUS || TARGET exclusive status
	jnz	hasFocus		;skip if has focus or target...

	and	bx, mask CS_lightColor	;set to light color		
	mov	cl, 4							
	shr	bl, cl							
	mov	ax, C_BLACK		;default: black text on light-grey
	jmp	short done

hasFocus:
	and	bx, mask CS_darkColor	;set to dark color
	mov	ax, C_WHITE		;draw white text on dark-grey

done:
	pop	cx
	ret
OpenWinGetHeaderColors	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawMultiPlaneBitmap

DESCRIPTION:	This procedure does what the name says, stupid!

PASS:		ds:bp	= BitmapPlaneDefs structure, which contains an offset
				to a bitmap for each color plane.
		di 	= GState
		cx	= color scheme
		ax, bx	= (X, Y) position

RETURN:		ax, bx, cx, ds, di, bp = same.

DESTROYED:	dx (ONLY)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinDrawMultiPlaneBitmap	proc	near
	push	ax
	push	bx
	push	si			;save bounds info

	mov	dx, ax			;pass dx = x position

	mov	ax, cx			;ax = color scheme
	and	ax, mask CS_lightColor
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	mov	si, ds:[bp].BPD_light	;set ds:si = light color/B&W bitmap
	call	OpenWinDrawBitmapPlane

	;assume we are drawing the B&W version, and setup some args

	mov	ax, cx			;get color scheme
	and	ax, mask CS_darkColor
	mov	si, ds:[bp].BPD_bwDark	;set ds:si = dark B&W bitmap

	cmp	ch, DC_GRAY_1		;check color scheme
	jz	drawLastPlane		;skip if is Black and White...

	;Draw color image

	mov	si, ds:[bp].BPD_colorDark ;set ds:si = dark color bitmap
	call	OpenWinDrawBitmapPlane

	mov	ax, C_WHITE
	mov	si, ds:[bp].BPD_colorWhite ;set ds:si = white color bitmap
	call	OpenWinDrawBitmapPlane

	mov	ax, C_BLACK
	mov	si, ds:[bp].BPD_colorBlack ;set ds:si = black color bitmap

drawLastPlane:
	call	OpenWinDrawBitmapPlane

	mov	ax, C_BLACK		;set back to black
	call	GrSetAreaColor

	pop	si
	pop	bx
	pop	ax			;get top and bottom bounds
	ret
OpenWinDrawMultiPlaneBitmap	endp

;pass ds:si = bitmap, (dx, bx = position), ax = color to use

OpenWinDrawBitmapPlane	proc	near
	tst	si			;is there a bitmap for this plane?
	jz	done			;skip if not...

	call	GrSetAreaColor		;set color to draw with
	push	cx			;save color scheme
	mov	ax, dx			;get X position
	clr	cx
	clr	dx
	call	GrDrawBitmap		;draw dark plane of bitmap
	mov	dx, ax			;restore X position value
	pop	cx
done:
	ret
OpenWinDrawBitmapPlane	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawShadowBackground

DESCRIPTION:	This procedure draws the background for an OpenLook window
		which has a shadow.

CALLED BY:	OpenWinDraw

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		cleanup

------------------------------------------------------------------------------@

OpenWinDrawShadowBackground	proc	near
	push	ax			;preserve color scheme

	;Draw background (use nearly-square region definition)

	and	ax, mask CS_lightColor
	mov	cl, 4
	shr	al, cl
	call	GrSetAreaColor

	call	OpenWinGetBounds

	push	ds
	push	si
	segmov	ds, cs
	mov	si, offset MenuSolidRegion
					;region = VisBounds minus room
					;for shadow at right and bottom
	call	GrDrawRegionAtCP
	pop	si
	pop	ds

	;Draw thin black frame around the menu region. (Shadow will
	;be drawn outside of this border).

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax
	push	ds
	push	si
	segmov	ds, cs
	mov	si, offset MenuBorderRegion
	call	GrDrawRegionAtCP
	pop	si
	pop	ds

	;Draw shadow
	push	ax
	mov	ax, MASK_50		;draw 50% mask
	call	GrSetAreaMask
	pop	ax

	mov	ax, cx
	mov	bx, dx
	sub	ax, OLS_WIN_SHADOW_SIZE-1
	sub	bx, OLS_WIN_SHADOW_SIZE-1
	push	ds
	push	si
	segmov	ds, cs
	mov	si, offset ShadowRegion
	call	GrDrawRegionAtCP
	pop	si
	pop	ds

	mov	ax, MASK_100		;restore to 100% mask
	call	GrSetAreaMask
	pop	ax			;restore color scheme
	ret
OpenWinDrawShadowBackground	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawBackground

DESCRIPTION:	This procedure draws the background for an OpenLook window
		which DOES NOT have a shadow.

CALLED BY:	OpenWinDraw

PASS:		*ds:si	= instance data for object
		ds:bp	= instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinDrawBackground	proc	near
	push	ax			; reserve color scheme

					; If pinnable, then tranparent,
					; redraw anyway
	test	ds:[bp].OLWI_attrs, mask OWA_PINNABLE			
	jz	update			; Changed to never white out! -cbh
	
;	jnz	10$						
	;if not update then draw background
;	test	cl, mask DF_UPDATE	;is this an update?
;	jnz	update			;skip if so (no need to draw - this
					;is an expose event, so the window
					;system drew WHITE already)...

10$:	;use lighter color

	and	ax, mask CS_lightColor					
	mov	cl, 4							
	shr	al, cl							
	call	GrSetAreaColor

	call	OpenWinGetBounds	;get true bounds for window
	call	GrFillRect		;draw a filled rectangle

update:
	pop	ax
	ret
OpenWinDrawBackground	endp
			

COMMENT @----------------------------------------------------------------------

FUNCTION:	

DESCRIPTION:	

CALLED BY:	

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@
;This procedure draws the border for a window or menu.

OpenWinDrawBorder	proc	near
	push	ax		;preserve color scheme
	mov	ax, C_BLACK
	call	GrSetAreaColor

	;See if doing shadowed window

	test	ds:[bp].OLWI_attrs,mask OWA_SHADOW
	jz	50$		;skip if so...

	;DRAW Shadowed border here

	jmp	short done

50$:
	;draw non-shadowed border

	call	OpenWinGetInsideShadowBounds
				;get window bounds (inside shadow if any)

	;See if using resize corners, if any

	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	noResize

	;Draw resize border, from region def

	push	si
	push	ds
	segmov	ds,cs
	mov	si,offset ResizeRegionBlack
	call	GrDrawRegionAtCP
	pop	ds
	pop	si
	jmp	short afterResize

noResize:	;Draw basic line border (2 thick)
	call	GrDrawRect
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrDrawRect

afterResize:
	;If this is a notice window, draw a thick inset border.

	test	ds:[bp].OLWI_attrs,mask OWA_THICK_LINE_BORDER
	jz	done

	call	OpenWinGetInsideShadowBounds
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrDrawRect
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrDrawRect

done:
	pop	ax
	ret
OpenWinDrawBorder	endp

WinCommon ends

