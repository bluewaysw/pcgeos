COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Motif/Win (window code specific to Motif)
FILE:		winDraw.asm

ROUTINES:
	Name				Description
	----				-----------
	OpenWinGetBounds		gets bounds for object
	OpenWinGetInsideResizeBorderBounds
					gets bounds inside the resize border
	OpenWinGetInsideBounds		gets bounds inside resize border and
						frame line
	OpenWinGetHeaderBounds		gets bounds of header
	OpenWinInitGState		sets up font, etc. info in GState
	OpenWinDraw			MSG_VIS_DRAW handler for OLWinClass
	OpenWinDrawResizeBorder		draws resizable border region
	OpenWinDrawInsideResizeBorderBackground
					draws background inside border
	OpenWinDrawThickLineBorder	draws thick line border (Notice windows)
	OpenWinDrawHeaderTitleBackground draws background behind title
	OpenWinDrawHeaderTitle		draws title text

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Eric	9/89		moved from CommonUI/CWin since 90% of
				file is specific-ui dependent.

DESCRIPTION:
	This file contains procedures for the DRAW method of OLWinClass.

	$Id: winDraw.asm,v 1.1 97/04/07 11:03:15 newdeal Exp $

-------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinDrawVLine

SYNOPSIS:	Draws vertical line in the color passed.

PASS:		ax, bx, cx, - bounds of the rectangle
		di	- GState to use
		bp	- color to use for the top/left

RETURN:		ax, bx, cx, dx, di	- preserved

DESTROYED:	nothing
		
	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinDrawVLine	proc	near
	push	ax
	mov	ax, bp
	call	GrSetLineColor			; Set the color for the line
	pop	ax
	call	GrDrawVLine			; Draw the vertical line
	ret
WinDrawVLine	endp

WinDrawHLine	proc	near
	push	ax
	mov	ax, bp
	call	GrSetLineColor			; Set the color for the line
	pop	ax
	call	GrDrawHLine			; Draw the horizontal line
	ret
WinDrawHLine	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinDrawWhiteVLineIfColor

SYNOPSIS:	Draws vertical white line in white, if on a color display.

PASS:		ax, bx, cx, - bounds of the rectangle
		di	- GState to use

RETURN:		ax, bx, cx, dx, di	- preserved

DESTROYED:	nothing
		
	Chris	3/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinDrawWhiteVLineIfColor	proc	near
	mov	bp, C_WHITE
	call	OpenCheckIfBW
	jc	exit
	call	WinDrawVLine
exit:
	ret
WinDrawWhiteVLineIfColor	endp

WinDrawWhiteHLineIfColor	proc	near
	mov	bp, C_WHITE
	call	OpenCheckIfBW
	jc	exit
	call	WinDrawHLine
exit:
	ret
WinDrawWhiteHLineIfColor	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinDrawBoxFrame

SYNOPSIS:	Draws a frame at the bounds passed.  If the display type is
		B&W, then it will just draw a frame.  If it's a color display,
		then it will draw a "shadowed" frame in 2 colors. 

PASS:		ax, bx, cx, dx	- GrFillRect-style bounds of the rectangle
		di	- GState to use
		bp-low	- <rightBottom color><topLeft color>
		bp-high	- display type

RETURN:		ax, bx, cx, dx, di	- preserved

DESTROYED:	nothing

	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinDrawBoxFrame	proc	near
	uses	ax, bx, bp
	.enter
	xchg	ax, bp				;put colors in al
	cmp	ah, DC_GRAY_1			;is this a B@W display?
	jnz	color				;skip if not...
	mov	ax, (C_BLACK shl 8) or C_BLACK	;else use all black for frame
	jmp	draw
color:
	mov	ah, al
	andnf	al, mask CS_darkColor		;al <- dark color
	andnf	ah, mask CS_lightColor		;ah <- light color
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
draw:
	xchg	bp, ax				;back in bp
	call	OpenDrawRect			;draw a framed rectangle
	.leave
	ret
WinDrawBoxFrame	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetBounds
		OpenWinGetInsideResizeBorderBounds
		OpenWinGetInsideBorderBounds

DESCRIPTION:	These procedures return the bounds for an aspect of the window.

PASS:		*ds:si	= instance data for object

RETURN:		(ax, bx) - (cx, dx) = bounds
		ds, si, di, bp = same

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

;This procedure gets the boundary coordinates of the window, relative to itself.

OpenWinGetBounds	proc	near
	;we cannot use VisGetBounds because this object is a WINDOWED object.

	call	VisGetSize
	clr	ax
	clr	bx

if	DRAW_SHADOWS_ON_BW_GADGETS
	push	bp
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	exit
	call	OpenCheckIfBW
	jnc	exit
	dec	cx				;move off shadow for others.
	dec	dx
exit:
	pop	bp
endif
	ret
OpenWinGetBounds	endp

;CUAS: the bounds returned do not include the resize border area.

OpenWinGetInsideResizeBorderBounds	proc	near
	class	OLWinClass

	push	bp
	call	OpenWinGetBounds

	;If (RESIZABLE) AND NOT (MAXIMIZABLE and MAXIMIZED),
	;add in width of two resize borders

	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset

if _MOTIF
	call	OpenWinHasResizeBorder
	jnc	OWGNSB_noResize			;can't have resize bars, branch
else
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	OWGNSB_noResize
endif

	test	ds:[bp].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	OWGNSB_10			;not maximizable...
	test	ds:[bp].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	OWGNSB_noResize			;is maximized, therefore
						;no resize border...
OWGNSB_10:
	push	si, ds
	mov	bp, segment idata	;get segment of core blk
	mov	ds, bp
	mov	bp, ds:[resizeBarHeight]
	mov	si, ds:[resizeBarWidth]

	add	bx, bp
	sub	dx, bp

	add	ax, si
	sub	cx, si
	pop	si, ds
OWGNSB_noResize:
	pop	bp

	ret
OpenWinGetInsideResizeBorderBounds	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetInsideBounds

DESCRIPTION:	This procedure returns the bounds of the OLWinClass object,
		less the area taken up by the resize border if any, less the
		area taken up by the thin line framing the window, inside
		the resize border. Note: in many cases, this returns the
		same values as OpenWinGetInsideResizeBorderBounds, since CUA and Motif
		place objects directly on the frame line.

CALLED BY:	utility

PASS:		ds:*si	- handle of instance data
		ds:bp	- pointer to instance data

RETURN:		(ax, bx, cx, dx) = bounds		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		split from OpenLook code.

------------------------------------------------------------------------------@

;ERIC: add code to handle thick border used in Summons boxes.

if	0	;Not used

OpenWinGetInsideBounds	proc	near
	call	OpenWinGetInsideResizeBorderBounds	;get window bounds, less
						;shadow area
	ret

OpenWinGetInsideBounds	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetHeaderBounds

DESCRIPTION:	This procedure returns the bounds of the header area of
		an OLWinClass object. Note that in CUA and Motif we place the
		header ON the frame line of the window.

CALLED BY:	utility

PASS:		ds:*si	- handle of instance data
		ds:bp	- pointer to instance data

RETURN:		(ax, bx, cx, dx) = bounds		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		split from OpenLook code.
	Chris	4/91		Updated for new graphics, bounds conventions
	
------------------------------------------------------------------------------@

OpenWinGetHeaderBounds	proc	near
	class	OLWinClass

if	 _ALLOW_MINIMIZED_TITLE_BARS
	; If we are minimizing title bar size, then don't include the font
	; height in calculating the header size since we aren't displaying a
	; title.
	clr	dx
	test	ds:[bp].OLWI_moreFixedAttr, mask OMWFA_MINIMIZE_TITLE_BAR
	jnz	dontIncludeFontHeight
endif	;_ALLOW_MINIMIZED_TITLE_BARS

	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	mov	dx, ds:[specDisplayScheme].DS_pointSize
	pop	ds

if	 _ALLOW_MINIMIZED_TITLE_BARS
dontIncludeFontHeight:
endif	;_ALLOW_MINIMIZED_TITLE_BARS
	push	dx
	call	OpenWinGetInsideResizeBorderBounds
					;get window bounds, less resize
					;border area.

	;Header is on top of window frame line, so don't change left, right,
	;or top coordinates here

	pop	dx			;restore font height
if _GCM
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	50$
endif
	clr	dh
	add	dx, bx			;add top
	add	dx, CUAS_WIN_HEADER_Y_SPACING	;add margin
	;
	; If it's a CGA display, use a smaller header height

	call	OpenWinCheckIfSquished
	jnc	done
	sub	dx, (CUAS_WIN_HEADER_Y_SPACING - CUAS_CGA_WIN_HEADER_Y_SPACING)
	ret

if _GCM
50$:	;for GCM headers: ignore font size (for now)

	mov	dx, CUAS_GCM_HEADER_HEIGHT
	call	OpenWinCheckIfSquished
	jnc	done
	mov	dx, CUAS_GCM_CGA_HEADER_HEIGHT
endif
done:
	ret

OpenWinGetHeaderBounds	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinDraw -- MSG_VIS_DRAW for OLWinClass

DESCRIPTION:	This procedure is called when

PASS:		ds:*si	- instance data
		es	- segment of zzzClass
		ax	- MSG_
		cx, dx	- ?
		bp	- handle of GState

RETURN:		cl - DrawFlags: DF_EXPOSED set if updating
		ch - ?
		dx - ?
		bp - GState to use

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	7/89		more documentation, Motif extensions

------------------------------------------------------------------------------@

OpenWinDraw	method dynamic	OLWinClass, MSG_VIS_DRAW

	;
	; Treat anything drawn in the window as enabled.  12/10/92 -cbh
	;
	push	{word} ds:[di].VI_attrs
	or	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

	mov	di, bp			;di = GState
	call	OpenWinInitGState

	;(al = color scheme, ah = display type, cl = DrawFlags)

	;draw resize border if necessary.
	;	ds:bp = specific instance data for object
	;	di = gstate

if _MOTIF

if _MOTIF
	call	OpenWinHasResizeBorder
	jnc	OWOW_10			;can't have resize bars, branch
else
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	OWOW_10				;not resizable...
endif

	;is resizable: prohibit border if maximized

	test	ds:[bp].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	OWOW_5			;not maximizable...

	test	ds:[bp].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	OWOW_10			;is maximized, therefore
					;no resize border...
OWOW_5:
	call	OpenWinDrawResizeBorder
	jmp	short OWOW_20
endif			;END of MOTIF/CUA specific code ------------------------

OWOW_10:
;	call	OpenWinDrawInsideResizeBorderBackground
					;draw flat background inside of resize
					;border area if any
OWOW_20:
	;Now ready to thick line border (for Notice windows)
	;	ds:bp = specific instance data for object
	;	di = gstate

	test	ds:[bp].OLWI_attrs, mask OWA_THICK_LINE_BORDER
	jz	noThickLineBorder	;skip if not a notice window...

	call	OpenWinDrawThickLineBorder

noThickLineBorder:

	;draw the header area
	;	ds:bp = specific instance data for object
	;	di = gstate
	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	OWD_noHeader

if not NORMAL_HEADERS_ON_DISABLED_WINDOWS	; only 50% if disabling headers
	test	ds:[bp].VI_attrs, mask VA_FULLY_ENABLED
	jnz	OWD_drawHeader
	mov	al, SDM_50			; else draw everything 50%
	call	GrSetTextMask
	call	GrSetLineMask
	
OWD_drawHeader:
endif
	call	OpenWinDrawHeaderTitleBackground
	call	OpenWinDrawHeaderTitle ;Draw window title
	mov	al, SDM_100			; else draw everything 100%
	call	GrSetTextMask
	call	GrSetLineMask
	
OWD_noHeader:
	mov	bp, di			;bp = GState
					;Then call parent class, to do children

	mov	di, ds:[si]		;restore VA_FULLY_ENABLED cbh 12/10/92
	add	di, ds:[di].Vis_offset
	pop	{word} ds:[di].VI_attrs

	mov	ax, MSG_VIS_DRAW
	mov	di, segment VisCompClass
	mov	es, di
	mov	di, offset VisCompClass
	GOTO	ObjCallClassNoLock

OpenWinDraw	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinInitGState

DESCRIPTION:	Initialize the current GState before using it to draw

CALLED BY:	OpenWinDraw, OLBaseWinDrawHeaderIcons

PASS:		*ds:si - object
		di - gstate

RETURN:		bp - offset to Spec data in object
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
					;cx = font to use
					;ah:dx = point size
	push	ax
	clr	ah			;no fractional pointsize
	call	GrSetFont
	pop	ax			;get display info
	pop	cx

	and	ah, mask DF_DISPLAY_TYPE
	cmp	ah, DC_GRAY_1		;is this a B&W display?
	jnz	color			;skip if not...

	mov	al, (C_WHITE shl 4) or C_BLACK	;use black and white
color:

	ret
OpenWinInitGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawResizeBorder

DESCRIPTION:	This procedure draws the resize border for an OLWinClass
		object if necessary.

CALLED BY:	OpenWinDraw

PASS:		ds:*si	- instance data
		ds:bp	- pointer to instance data
		es	- segment of OLWinClass
		ax	- color scheme, display type
		cx	- draw flags
		dx	- ?
		di	- handle of GState

RETURN:		nothing	

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OpenWinDrawResizeBorder	proc	near
	class	OLWinClass

	push	ax, cx, bp		;preserve color scheme & draw flags
					; Set colors for "depressed" frame
	mov	al, ColorScheme <MO_ETCH_COLOR, C_WHITE>
	mov	bp, ax

	;grab color value from color scheme variables in idata

if 0
	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	mov	ah, CF_INDEX
	mov	al, ds:[moCS_activeBorder]
	call	GrSetAreaColor
;	mov	al, ds:[moCS_windowFrame]
;	mov	bp, ax			; Pass this color to edge drawing code
	pop	ds
endif

	call	OpenWinGetBounds	;(ax, bx) - (cx, dx) = bounds

	call	WinDrawBoxFrame		;draw frame of outside resize border

if	DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenCheckIfBW
	jnc	notBW

;	inc	ax			;this is for a better 3D effect
;	inc	bx
	xchg	ax, cx
	call	WinDrawVLine		;Draw R/B shadow
	xchg	ax, cx
	xchg	bx, dx
	call	WinDrawHLine
	xchg	bx, dx
;	dec	ax
;	dec	bx
notBW:
endif
	inc	ax
	inc	bx

	dec	cx
	dec	dx

if 0
	;draw resizable border

	push	dx			;TOP RESIZE BORDER
	mov	dx, bx
	add	dx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	GrFillRect		;draw 50% background
	pop	dx

	push	bx			;BOTTOM RESIZE BORDER
	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	GrFillRect		;draw 50% background
	pop	bx

	push	bx, dx
	add	bx, CUAS_WIN_RESIZE_BORDER_SIZE-1
	sub	dx, CUAS_WIN_RESIZE_BORDER_SIZE-1

	push	cx			;LEFT RESIZE BORDER
	mov	cx, ax
	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	GrFillRect		;draw 50% background
	pop	cx

	push	ax			;RIGHT RESIZE BORDER
	mov	ax, cx
	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	GrFillRect		;draw 50% background
	pop	ax
	pop	bx, dx			;restore original size
endif

if	_MOTIF
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	LONG	jz	exit
endif

	;draw short line segments in resize border to show where resize
	;boxes are
						;
	push	ax, ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	mov	bp, ds:[resizeBarHeight]
	sub	bp, 2
	pop	ax, ds
						;VERTICAL LINES (TOP)
	push	ax, dx, bp
	mov	dx, bx
	add	dx, bp				; top segment

	add	ax, CUAS_WIN_ICON_WIDTH-2 	;left side

	push	ds
	push	ax
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	pop	ax
	add	ax, ds:[resizeBarWidth]
	pop	ds

;	call	OpenCheckIfBW			;added 2/ 2/93 cbh
;	jnc	12$
;	dec	ax				;magic difference for B/W
;12$:
	mov	bp, MO_ETCH_COLOR
	call	WinDrawVLine				;top left vert segment
	inc	ax
	mov	bp, C_WHITE
	call	WinDrawWhiteVLineIfColor		; & etch mark

	mov	ax, cx
	sub	ax, CUAS_WIN_ICON_WIDTH-1 	;right 

	push	ds
	push	ax
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	pop	ax
	sub	ax, ds:[resizeBarWidth]
	pop	ds

	call	OpenCheckIfBW			;added 2/ 2/93 cbh
	jnc	14$
	inc	ax				;magic difference for B/W
14$:
	mov	bp, C_WHITE
	call	WinDrawWhiteVLineIfColor		;top right vert segment
	dec	ax
	mov	bp, MO_ETCH_COLOR
	call	WinDrawVLine				; & etch mark
	pop	ax, dx, bp
							;
							;VERTICAL LINES (BOTTOM)
	push	ax, bx
	dec	dx					;adjust for line drawing
	mov	bx, dx
	sub	bx, bp					;bottom segment

	add	ax, CUAS_WIN_ICON_WIDTH-2 		;left side

	push	ds
	push	ax
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	pop	ax
	add	ax, ds:[resizeBarWidth]
	pop	ds

	call	OpenCheckIfBW			;added 2/ 2/93 cbh
	jnc	16$
	dec	ax				;magic difference for B/W
16$:

	mov	bp, MO_ETCH_COLOR
	call	WinDrawVLine				;bottom left vert 
	inc	ax
	call	WinDrawWhiteVLineIfColor		; & etch mark

	mov	ax, cx
	sub	ax, CUAS_WIN_ICON_WIDTH-1 	;right 

	push	ds
	push	ax
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	pop	ax
	sub	ax, ds:[resizeBarWidth]
	pop	ds

;	call	OpenCheckIfBW			;added 2/ 2/93 cbh
;	jnc	18$
;	inc	ax				;magic difference for B/W
;18$:

	call	WinDrawWhiteVLineIfColor		;bottom right vert
	dec	ax
	mov	bp, MO_ETCH_COLOR
	call	WinDrawVLine				; & etch mark
	pop	ax, bx
						;
						;LEFT HORIZONTAL LINES
	push	ax, ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	mov	bp, ds:[resizeBarWidth]
	sub	bp, 2
	pop	ax, ds

	push	bp
	push	cx
	mov	cx, ax
	add	cx, bp				;left segment
	
	;
	; Upper left and right marks are now drawn even with the bottom
	; of the window header, although the button handling code still thinks
	; the resize borders are fixed sizes.  
	;
	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- SpecInstance
	mov	bx, ds:[bx].OLWI_titleBarBounds.R_bottom
	dec	bx				;account for new graphics stuff
	call	OpenCheckIfBW
	jc	20$
	dec	bx				;color, bump up again. Sorry.
20$:
	push	bx
	mov	bp, MO_ETCH_COLOR
	call	WinDrawHLine				;top left horizontal
	inc	bx
	mov	bp, C_WHITE
	call	WinDrawWhiteHLineIfColor		; & etch mark

	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_HEIGHT+2 ;bottom 
	call	WinDrawWhiteHLineIfColor		;bottom left horizontal
	dec	bx
	mov	bp, MO_ETCH_COLOR
	call	WinDrawHLine				; & etch mark
	pop	bx
	pop	cx
	pop	bp
						;
						;RIGHT HORIZONTAL LINES
	dec	cx					;adjust for new bounds
	mov	ax, cx
	sub	ax, bp				;right segment

	mov	bp, MO_ETCH_COLOR
	call	WinDrawHLine				;top right horizontal
	inc	bx
	call	WinDrawWhiteHLineIfColor		; & etch mark

	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_HEIGHT+2 ;bottom 
	call	WinDrawWhiteHLineIfColor		;bottom right horizontal
	dec	bx
	mov	bp, MO_ETCH_COLOR
	call	WinDrawHLine				; & etch mark
exit:
	pop	ax, cx, bp		;recover color scheme & draw flags
	ret
OpenWinDrawResizeBorder	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawInsideResizeBorderBackground

DESCRIPTION:	This procedure draws the background for an OLWinClass
		object - the area inside the resize border if any.

CALLED BY:	OpenWinDraw

PASS:		ds:*si	- instance data
		ds:bp	- pointer to instance data
		es	- segment of OLWinClass
		ax	- color scheme, display type
		cx	- draw flags
		dx	- ?
		di	- handle of GState

RETURN:		nothing	

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Chris	5/90		COMMENTED OUT!! Not necessary.
	
------------------------------------------------------------------------------@
if	0		
	
OpenWinDrawInsideResizeBorderBackground	proc	near
	push	ax, cx			;reserve color scheme, draw flags

					; If pinnable, then tranparent,
					; redraw anyway

	;if not update then draw background

	test	cl, mask DF_EXPOSED	;is this an update?
	jnz	OWDNSB_update		;skip if so (no need to draw - this
					;is an expose event, so the window
					;system drew C_WHITE already)...

OWDNSB_10:
	;CUA/Motif: grab color value from color scheme variables in idata
	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_windowBG]
	pop	ds
	call	GrSetAreaColor

	call	OpenWinGetInsideResizeBorderBounds
	call	GrFillRect		;draw a filled rectangle

OWDNSB_update:
	pop	ax, cx			;get color scheme, draw flags
	ret
OpenWinDrawInsideResizeBorderBackground	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawThickLineBorder

DESCRIPTION:	This procedure draws the window frame for an OLWinClass
		object if necessary - the thin frame line which sits
		just inside the resize border.

CALLED BY:	OpenWinDraw

PASS:		ds:*si	- instance data
		ds:bp	- pointer to instance data
		es	- segment of OLWinClass
		ax	- color scheme, display type
		cx	- draw flags
		dx	- ?
		di	- handle of GState

RETURN:		nothing	

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OpenWinDrawThickLineBorder	proc	near
	class	OLWinClass

	push	ax, cx, si, bp		;preserve color scheme, draw flags
	;
	; Determine the color scheme to use
	mov	al, ColorScheme <MO_ETCH_COLOR, C_WHITE>

if _MOTIF
	call	OpenWinHasResizeBorder
	jnc	20$			; can't have resize bars, branch
else
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	20$
endif
	mov	al, ColorScheme <C_WHITE, MO_ETCH_COLOR>
20$:
	push	ax			; Save display type/border color scheme
	push	ax			; Save display type/border color scheme

	call	OpenWinGetInsideResizeBorderBounds

	pop	bp			; Get display type/border color scheme
	call	WinDrawBoxFrame		; draw frame of outside resize border

if	DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenWinHasResizeBorder
	jc	notBW			; has resize border, branch
	call	OpenCheckIfBW
	jnc	notBW

;	inc	ax
;	inc	bx
	xchg	ax, cx
	mov	bp, C_BLACK		; Make sure drawn in black (2/ 4/93)
	call	WinDrawVLine		; Draw R/B shadow
	xchg	ax, cx
	mov	bx, dx
	call	WinDrawHLine
notBW:
endif

	;CUA/Motif: if this is a GenSummons (OLNoticeClass),
	;then draw the thick inset frame line

	pop	ax			; Recover thick border color scheme
	mov	al, ColorScheme <C_WHITE, C_BLACK>

if	not _MOTIF
	mov	bp, ds:[si]		;ds:bp = instance
	add	bp, ds:[bp].Vis_offset	;ds:bp = SpecificInstance
	cmp	ds:[bp].OLWI_type, MOWT_NOTICE_WINDOW
	jne	OWDWF_80			;skip if not...

	push	ax				; save display type
	call	OpenWinGetInsideResizeBorderBounds
	pop	bp				; restore display type

	add	ax, CUAS_NOTICE_FRAME_INSET-1
	sub	cx, CUAS_NOTICE_FRAME_INSET-1
	add	bx, CUAS_NOTICE_FRAME_INSET-1
	sub	dx, CUAS_NOTICE_FRAME_INSET-1
	;
	; Compensate for CGA's wierd aspect ratio, if necessary
	call	OpenCheckIfCGA
	jnc	drawThickBorder
;CGA:
	sub	ax, MO_CGA_NOTICE_FRAME_X_INSET_DIFF
	add	cx, MO_CGA_NOTICE_FRAME_X_INSET_DIFF
	sub	bx, MO_CGA_NOTICE_FRAME_INSET_TOP_DIFF
	add	dx, MO_CGA_NOTICE_FRAME_INSET_TOP_DIFF

drawThickBorder:
    rept	CUAS_WIN_THICK_BORDER_EXTRA_X_MARGIN
	call	WinDrawThickBorder		; Draw thick border w/ diagonal
    endm

OWDWF_80:

endif
	mov	ax, C_BLACK
	call	GrSetLineColor
CUAS <	call	GrSetAreaColor						>
	pop	ax, cx, si, bp		;get color scheme, draw flags
	ret

OpenWinDrawThickLineBorder	endp

if	not _MOTIF
WinDrawThickBorder	proc	near
	inc	ax				; Give it diagonal corners by
	inc	bx				;    bringing it in one pixel
	dec	cx				;    each time you draw this
	dec	dx
	call	WinDrawBoxFrame		;draw frame of outside resize border
	ret
WinDrawThickBorder	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderTitleBackground

DESCRIPTION:	This procedure draws the background for the header area.

CALLED BY:	OpenWinDraw

PASS:		ds:*si	- instance data
		ds:bp	- pointer to instance data
		es	- segment of OLWinClass
		ax	- color scheme, display type
		cx	- draw flags
		dx	- ?
		di	- handle of GState

RETURN:		nothing	

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

;will SAVE BYTES here eventually

OpenWinDrawHeaderTitleBackground	proc	near
	class	OLWinClass
	;
	; Code added 2/ 6/92 to get rid of title on maximized windows.
	; 
	call	OpenWinCheckMenusInHeader
	LONG	jc	exit		;menus in header, don't draw title

	push	bp			; Save instance data pointer
	push	ax, cx			;preserve color scheme and draw flags
	push	si

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.  

	mov	cl, mask OLWHS_HEADER_AREA_INVALID or \
		    mask OLWHS_FOCUS_AREA_INVALID or \
		    mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	;see if this window has a title

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	LONG	jz done			;skip if not...

	mov	al, ColorScheme <MO_ETCH_COLOR, C_WHITE>
	push	ax			;Save display type (AH), 
					;and background color scheme (AL=C_WHITE)

	;see if this is a pinned menu

	push	ds			;save segment of object block
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	afterMenu		;skip with cy=0 if not menu...
	test	ds:[bp].OLWI_specState, mask OLWSS_PINNED
	jz	afterMenu		;skip (cy=0)...

;NOTE: SAVE BYTES here.
	;is a pinned menu (clean this up later)

	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_inactiveTitleBar]
					;Draw inactive background
	mov	bp, 8000h		;set high bit (no addition highlighting)
	jmp	setColorsPopDS		;skip ahead to set colors and pop ds...

afterMenu:
	;depending upon whether this window has the focus, choose one
	;of two TitleBarBackground colors
	;carry set if is pinned menu

	call	OpenWinTestForFocusAndTarget
	test	ax, mask HGF_SYS_EXCL
	pushf				;save FOCUS || TARGET exclusive status

	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_activeTitleBar]	;assume is active
	mov	bp, ax				;Save it for later
	mov	al, ds:[moCS_inactiveTitleBar]  ;Draw inactive background 1st
	popf
	jnz	setColorsPopDS		;skip if FOCUS || TARGET...

	;window does not have focus or target

	mov	bp, 8000h		;No addition highlighting
	mov	al, ds:[moCS_inactiveTitleBar]	;set inactive (C_WHITE)

setColorsPopDS:
	;registers:
	;	al = background color to use
	;	bp = highlight color to use, or 8000h for none.

	call	GrSetAreaColor
	mov	al, ds:[moCS_windowFrame]	;get color from line
	call	GrSetLineColor			;above and below title
	pop	ds

	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data

if	_MOTIF					;new code 12/ 1/92 cbh
	call	OpenCheckIfBW
	jc	dontScootUp
	dec	dx				;move bottom line up a pixel
dontScootUp:	
endif

	;Draw the horizontal line below the header

;	push	ax, cx				;save left and top of header

if	_MOTIF
;	push	di
;	mov	di, ds:[si]			;point to instance
;	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
;	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
;	pop	di		 		;  
	call	OpenCheckIfBW			;color, skip line drawing
	jnc	dontDrawIntoBorders
endif
	push	ax, cx				;save left and top of header

;	clr	ax				;this probably should draw into
;	inc	ax
;	push	di
;	mov	di, ds:[si]			;point to instance
;	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
;	mov	cx, ds:[di].VI_bounds.R_right	;  resize borders anymore.
;	sub	cx, ds:[di].VI_bounds.R_left	;  
;	pop	di

	push	bx			;draw bottom C_BLACK line
	mov	bx, dx			;all the way across to make up for
	dec	cx			;adjust for line drawing
	dec	bx
	dec	dx
	call	GrDrawLine		;the lack of bottom lines on buttons.
	inc	bx			;(restore bx, dx)
;	inc	dx			;(cancels 'dec dx' below)
	pop	bx
	pop	ax, cx			;restore header left and right
dontDrawIntoBorders:
	
	inc	bx			;colored portion is inside
;	dec	dx			;top and bottom lines
	;
	; see if we should draw a gradient or not
	;
	push	ax, ds
	mov	ax, segment idata
	mov	ds, ax
	mov	al, ds:[moCS_activeTitleBar]
	cmp	al, ds:[moCS_titleBar2]
	pop	ax, ds
	jne	drawGradient
normalDraw::
	call	GrFillRect		;draw basic colored background
afterDraw:

	mov	si, bp
	pop	bp			;Get display type/backgrd color scheme

	xchg	ax, bp
	cmp	ah, DC_GRAY_1		;is this a B&W display?
	xchg	ax, bp
	je	bw			;skip if so...

	XchgTopStack	si		;get object handle, save highlight flag
	call	WinDrawBoxFrame		;draw frame of outside resize border
	XchgTopStack	si		;restore highlight flag, object handle
					;   again on stack.
	jmp	drawHighlight

bw:	;B&W display: restore vertical bounds (WHY?)

	dec	bx
	inc	dx

drawHighlight:
	tst	si			; Is there any highlighting
	js	done			;   If not, skip...

	xchg	ax, si			;ax = highlight color, si = left coord.
	call	GrSetAreaColor

	mov	ax, bp
	cmp	ah, DC_GRAY_1		;is this a B&W display?
	je	drawHighlight2		;skip if so...

	;color display: draw inside the etch area

	add	si, MO_WIN_HIGHLIGHT_INSET_X				
	sub	cx, MO_WIN_HIGHLIGHT_INSET_X				

drawHighlight2:
	mov	ax, si			;ax = left coord
	add	bx, MO_WIN_HIGHLIGHT_INSET_Y				
	sub	dx, MO_WIN_HIGHLIGHT_INSET_Y				
	push	ax, ds
	mov	ax, segment idata
	mov	ds, ax
	mov	al, ds:[moCS_activeTitleBar]
	cmp	al, ds:[moCS_titleBar2]
	pop	ax, ds
	jne	drawGradient2
normalDraw2::
	call	GrFillRect		;draw the highlighted background
afterDraw2:

done:
	pop	si			;restore handle
	pop	ax, cx			;get color scheme and draw flags
	pop	bp			; Recover instance data pointer
exit:
	ret

drawGradient:
	test	bp, 0x8000
	push	si, ax
	call	DrawGradientTitle
	pop	si, ax
	jmp	afterDraw

drawGradient2:
	test	bp, 0x8000
	push	si, ax
	call	DrawGradientTitle
	pop	si, ax
	jmp	afterDraw2

OpenWinDrawHeaderTitleBackground	endp


DrawGradientTitle	proc	near
	uses	bx, cx, dx, ds

locs	local	GradientLocals

	mov	si, ax				;si <- left bound
	lahf					;ah <- flags

	.enter

	mov	ss:locs.GL_bounds.R_left, si
	mov	ss:locs.GL_bounds.R_top, bx
	mov	ss:locs.GL_bounds.R_right, cx
	mov	ss:locs.GL_bounds.R_bottom, dx

	sahf

	mov	ax, segment idata
	mov	ds, ax
	mov	al, ds:[moCS_activeTitleBar]
	jz	haveColor
	mov	al, ds:[moCS_inactiveTitleBar]
haveColor:
	mov	dh, ds:[moCS_titleBar2]
	call	DrawGradient

	.leave
	ret
DrawGradientTitle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderTitle

DESCRIPTION:	This procedure draws the title for an OLWinClass object.

CALLED BY:	OpenWinDraw

PASS:		ds:*si	- instance data
		ds:bp	- pointer to instance data
		es	- segment of OLWinClass
		ax	- color scheme, display type
		cx	- draw flags
		dx	- ?
		di	- handle of GState

RETURN:		nothing	

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

CGA_TITLE_TEXT_Y_OFFSET	=	-1
GCM_CGA_TITLE_TEXT_Y_OFFSET = 	-1
			    
TITLE_TEXT_Y_OFFSET	=	2
GCM_TITLE_TEXT_Y_OFFSET	=	6	;for non CGA only

OpenWinDrawHeaderTitle	proc	near
	class	OLWinClass

	;
	; Code added 2/ 6/92 to get rid of title on maximized windows.
	; 
	call	OpenWinCheckMenusInHeader
	LONG	jc	exit		;menus in header, don't draw title

if	 _ALLOW_MINIMIZED_TITLE_BARS
	; If minimizing title bar, then don't draw the title - won't fit.
	
	test	ds:[bp].OLWI_moreFixedAttr, mask OMWFA_MINIMIZE_TITLE_BAR
	LONG	jnz	exit
endif	;_ALLOW_MINIMIZED_TITLE_BARS

	push	ax, cx, bp, es		;preserve color scheme, draw flags
					;and pointer to instance data

EC <	call	GenCheckGenAssumption	;Make sure gen data exists 	>

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID or mask OLWHS_FOCUS_AREA_INVALID
	call	OpenWinHeaderResetInvalid
   
	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	LONG	jz done			;skip if not titled...

	;CUA/Motif: grab color values from color scheme variables in idata

	push	ds
MO <	call	OpenWinTestForFocusAndTarget				>
MO <	test	ax, mask HGF_SYS_EXCL					>
MO <	pushf								>
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_windowFrame]	;get general purpose C_BLACK
	call	GrSetAreaColor			;for rect behind text
	mov	al, ds:[moCS_titleBarText]
MO <	popf								>
MO <	jz	10$							>
MO <	mov	al, C_WHITE						>
MO <10$:								>
	call	GrSetTextColor
	pop	ds
	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data
	inc	bx				;move inside top and bottom
	dec	dx				;C_BLACK lines

	;(ax, bx), (cx, dx) = coordinates for title area.
	;Calculate size of text moniker.
	
	sub	cx, ax			;save width of title area 
	push	cx			;

;HACK
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	pushf				; Save the test results
;END HACK
	mov	bp, di				;bp = gstate

	push	dx			;save bottom bound of title area
	push	bx			;save top bound of title area
	push	ax			;save left bound of title area
	push	cx			;save width of title area again

	;point to generic instance data and grab textual(?) moniker

	call	WinCommon_DerefGen_DI
	mov	di, ds:[di].GI_visMoniker ; fetch moniker
	tst	di			;is there a moniker?
	LONG	jz	OWDHC_abort	;skip if not...

	mov	di, bp			;pass GState in di
if	0
	call	OpenWinGCMSetTitleFontSize
endif
	segmov	es, ds			;es:di = moniker
					;pass bp = gstate
	call	OpenWinGetMonikerSize	;get size of moniker (cx, dx)
					;does not trash ax, bp

	pop	bx			;bx = width of title area		
	push	bx			;save again...
	sub	bx, cx			;find amount of space around text

	sub	bx, (CUAS_TITLE_TEXT_MARGIN*2)
					;see +2 note below...
					;account for margins around text,

	tst	bx			;did it go negative? 
	jns	20$			;skip if not...
	clr	bx			;use offset of 0
20$:
	sar	bx, 1			;convert total space into offset

	;bx = offset from the left side of the title area to the text margin
	;(text margin = 3 pixel area to left of text)

	pop	di			;restore width of title area
	pop	ax			;get left bound of title area
	add	ax, bx			;add offset to text margin
					;ax = left bounds of text area

	pop	bx			;get top bound of title area
	pop	dx			;get bottom bound of title area

;HACK
	popf
	jz	30$			;If not GCM, branch	
	mov	bx,GCM_TITLE_TEXT_Y_OFFSET-TITLE_TEXT_Y_OFFSET
	call	OpenWinCheckIfSquished		;see if on CGA
	jnc	30$			;not CGA, branch
	mov	bx,GCM_CGA_TITLE_TEXT_Y_OFFSET-CGA_TITLE_TEXT_Y_OFFSET
30$:
;END HACK

	add	cx, (CUAS_TITLE_TEXT_MARGIN*2)+2
					;+2 fixes inexplicable problem
					;with right margin...

					;cx = right bound of text area
	cmp	cx, di			;wider than title area?
	jbe	40$			;no, branch
	mov	cx, di			;else keep to title width
40$:
	add	cx, ax			;cx = left bound + offset + text width
	
	mov	di, bp			;pass di = gstate

	add	ax, CUAS_TITLE_TEXT_MARGIN
					;move inside margin area
	mov	dx, ax			;dl = X offset from OLWinClass bounds
	
	add	bx, TITLE_TEXT_Y_OFFSET	;push text down a bit
	;
	; If it's a CGA display, compensate for a smaller header height
	call	OpenWinCheckIfSquished		;zeroes ax, sets CF if CGA
	jnc	notCGA
	sub	bx, (TITLE_TEXT_Y_OFFSET - CGA_TITLE_TEXT_Y_OFFSET) - 1
notCGA:
	pop	cx			;restore width of title area
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

	mov	di, bp			;pass di = gstate
if _MOTIF
	mov	ax, C_BLACK		;reset text color
endif			;END of MOTIF/CUA specific code ------------------------
	call	GrSetTextColor

	;restore original point size

if	0
	call	OpenWinGCMResetTitleFontSize
endif


done:

	pop	ax, cx, bp, es		;get color scheme, draw flags
exit:					;and pointer to instance data
	ret

OWDHC_abort:
	mov	di, bp			;return di = gstate
	add	sp, 12			;clean up stack
	jmp	done			;branch back to finish up

OpenWinDrawHeaderTitle	endp

WinCommon ends
