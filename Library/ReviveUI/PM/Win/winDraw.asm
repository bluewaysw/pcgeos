COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PM/Win (window code specific to PM)
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
	OpenWinDrawThickLineBorder	draws thick line border (Notice window)
	OpenWinDrawMenuBorder		draw border around popup menus
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

	$Id: winDraw.asm,v 1.23 94/03/07 11:25:27 dlitwin Exp $

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

if (0)

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

endif



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
	jmp	short draw
color:
	mov	ah, al				;also in ah
	ANDNF	al, mask CS_darkColor		;ah holds dark color
	ANDNF	ah, mask CS_lightColor		;al holds light color
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
		ds:bp	= instance data for object

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
	ret
OpenWinGetBounds	endp

;CUAS: the bounds returned do not include the resize border area.

OpenWinGetInsideResizeBorderBounds	proc	near
	class	OLWinClass

	call	OpenWinGetBounds

	;If (RESIZABLE) AND NOT (MAXIMIZABLE and MAXIMIZED),
	;add in width of two resize borders

	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	OWGNSB_noResize
	test	ds:[bp].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	OWGNSB_10			;not maximizable...
	test	ds:[bp].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	OWGNSB_noResize			;is maximized, therefore
						;no resize border...
OWGNSB_10:
	push	bp, si, ds
	mov	bp, segment idata	;get segment of core blk
	mov	ds, bp
	mov	bp, ds:[resizeBarHeight]
	mov	si, ds:[resizeBarWidth]

	add	bx, bp
	sub	dx, bp

	add	ax, si
	sub	cx, si
	pop	bp, si, ds

OWGNSB_noResize:
	ret
OpenWinGetInsideResizeBorderBounds	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetInsideBounds

DESCRIPTION:	This procedure returns the bounds of the OLWinClass object,
		less the area taken up by the resize border if any, less the
		area taken up by the thin line framing the window, inside
		the resize border. Note: in many cases, this returns the
		same values as OpenWinGetInsideResizeBorderBounds, since CUA
		and Motif place objects directly on the frame line.

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

	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	mov	dx, ds:[specDisplayScheme].DS_pointSize
	pop	ds

	push	dx
	call	OpenWinGetInsideResizeBorderBounds
					;get window bounds, less resize
					;border area.

	test	ds:[bp].OLWI_type, MOWT_NOTICE_WINDOW
	jz	noAppModalBorder
	test	ds:[bp].OLPWI_flags, mask OLPWF_APP_MODAL
	jz	noAppModalBorder

appModalBorder:
	add	ax, CUAS_NOTICE_FRAME_X_SPACE
	add	bx, CUAS_NOTICE_FRAME_Y_SPACE
	sub	cx, CUAS_NOTICE_FRAME_X_SPACE
	sub	dx, CUAS_NOTICE_FRAME_Y_SPACE

noAppModalBorder:

	;Header is on top of window frame line, so don't change left, right,
	;or top coordinates here

	pop	dx			;restore font height
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	50$

	clr	dh
	add	dx, bx			;add top
	add	dx, CUAS_WIN_HEADER_Y_SPACING	;add margin
	;
	; If it's a CGA display, use a smaller header height
	test	es:[moCS_flags], mask CSF_VERY_SQUISHED
	jz	done
	sub	dx, (CUAS_WIN_HEADER_Y_SPACING - CUAS_CGA_WIN_HEADER_Y_SPACING)
	ret

50$:	;for GCM headers: ignore font size (for now)

	mov	dx, CUAS_GCM_HEADER_HEIGHT
	test	es:[moCS_flags], mask CSF_VERY_SQUISHED
	jz	done
	mov	dx, CUAS_GCM_CGA_HEADER_HEIGHT
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
	mov	di, bp			;di = GState

	call	OpenWinInitGState

	;(al = color scheme, ah = display type, cl = DrawFlags)

	;draw resize border if necessary.
	;	ds:bp = specific instance data for object
	;	di = gstate

	call	OpenWinDrawResizeBorder

	;Now ready to thick line border (for Notice windows)
	;	ds:bp = specific instance data for object
	;	di = gstate

	test	ds:[bp].OLWI_attrs, mask OWA_THICK_LINE_BORDER
	jz	noThickLineBorder	;skip if not a notice window...

	cmp	ds:[bp].OLWI_type, MOWT_MENU
	je	menu
	cmp	ds:[bp].OLWI_type, MOWT_SUBMENU
	je	menu
	cmp	ds:[bp].OLWI_type, MOWT_SYSTEM_MENU
	je	menu

	call	OpenWinDrawThickLineBorder
	jmp	short noThickLineBorder
menu:
	call	OpenWinDrawMenuBorder

noThickLineBorder:

	;draw the header area
	;	ds:bp = specific instance data for object
	;	di = gstate
	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	OWD_noHeader

if not NORMAL_HEADERS_ON_DISABLED_WINDOWS	; only 50% if disabling headers
	test	ds:[bp].VI_attrs, mask VA_FULLY_ENABLED
	jnz	OWD_drawHeader
	mov	al, SDM_50		; else draw everything 50%
	call	GrSetTextMask
	call	GrSetLineMask
	
OWD_drawHeader:
endif
	call	OpenWinDrawHeaderTitleBackground
	call	OpenWinDrawHeaderTitle ;Draw window title
	mov	al, SDM_100		; else draw everything 100%
	call	GrSetTextMask
	call	GrSetLineMask
	
OWD_noHeader:
	mov	bp, di			;bp = GState
					;Then call parent class, to do children
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

	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	done			;not resizable...

	test	ds:[bp].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	done			;is maximized, therefore
					;no resize border...

	push	ax, cx, bp		;preserve color scheme & draw flags
					; Set colors for "depressed" frame

	mov	cx, ax			;color scheme, save display type

	;grab color value from color scheme variables in idata

	push	es
	mov	ax, segment idata	;get segment of core blk
	mov	es, ax

	call	OpenWinTestForFocusAndTarget
	test	ax, mask HGF_SYS_EXCL
	jnz	active
	mov	al, es:[moCS_inactiveBorder]
	jmp	color
active:	mov	al, es:[moCS_activeBorder]
color:	clr	ah			;ah = CF_INDEX
	call	GrSetAreaColor

	mov	al, ColorScheme <MO_ETCH_COLOR, MO_ETCH_COLOR>
	cmp	ch, DC_GRAY_1
	je	haveColorScheme
	mov	al, ColorScheme <MO_ETCH_COLOR, C_WHITE>
haveColorScheme:
	mov	bp, ax			; Pass this color to edge drawing code
	pop	es

	pushf				;save whether we are DC_GRAY_1
	call	OpenWinGetBounds	;(ax, bx) - (cx, dx) = bounds
	call	WinDrawBoxFrame		;draw frame of outside resize border
	popf				;if we are DC_GRAY_1
	je	almostDone		; skip filling in the resize border

	inc	ax
	inc	bx
	dec	cx
	dec	dx

	;draw resizable border

	push	dx			;TOP RESIZE BORDER
	mov	dx, bx
	add	dx, CUAS_WIN_RESIZE_BORDER_SIZE-1
	call	GrFillRect		;draw 50% background
	pop	dx

	push	bx			;BOTTOM RESIZE BORDER
	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE-1
	call	GrFillRect		;draw 50% background
	pop	bx

	push	cx			;LEFT RESIZE BORDER
	mov	cx, ax
	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-1
	call	GrFillRect		;draw 50% background
	pop	cx

	mov	ax, cx
	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-1
	call	GrFillRect		;draw 50% background

almostDone:
	pop	ax, cx, bp		;recover color scheme & draw flags
done:
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



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinDrawMenuBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a border around a menu

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
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinDrawMenuBorder	proc	near
	class	OLWinClass

	push	ax, cx, si		;preserve color scheme, draw flags

	mov	ax, MO_ETCH_COLOR
	push	ax

	mov	ax, C_WHITE
	call	GrSetLineColor

	call	OpenWinGetBounds
	dec	cx			;adjust for line drawing
	dec	dx			;adjust for line drawing

	inc	ax
	call	GrDrawVLine		;draw left border
	pop	ax
	call	GrSetLineColor		;set new color
	clr	ax
	call	GrDrawVLine		;draw left border
	mov	ax, cx
	call	GrDrawVLine		;draw right border
	clr	ax
	mov	bx, dx
	call	GrDrawHLine		;draw bottom border

	tst	ds:[bp].OLPWI_button	;test for existence of a button
	jz	drawTop

	; If submenu, draw all of the top border
	cmp	ds:[bp].OLWI_type, MOWT_SUBMENU
	je	drawTop

if _MENUS_PINNABLE
	test	ds:[bp].OLWI_specState, mask OLWSS_PINNED
	jnz	drawTop
endif

	; else draw the portions of the top border which are not directly
	; beneath the menu button.
	call	VisGetBounds		;returns bounds = (ax, bx, cx, dx)
	push	cx, ax, bx

	mov	si, ds:[bp].OLPWI_button;get the menu button for this menu
	call	VisGetBounds		;returns bounds = (ax, bx, cx, dx)

	mov	bx, dx			;(ax,bx) = bottom-left corner of button
	sub	cx, ax			;cx = width(menuButton)
	push	di
	call	VisQueryWindow
	tst	di			;make sure window has been realized
	jnz	continue

	pop	di			;no button associated with menu
	pop	cx, ax, bx		; draw all of the top border
	jmp	drawTop

continue:
	call	WinTransform
	pop	di
	add	cx, ax			;cx = right(menuButton)
	mov	si, cx			;si = right(menuButton)

	pop	dx			;dx = top(menu)
	sub	bx, dx
	je	drawTopLeft		;if equal, draw the portions of the top
					; border which are not directly beneath
					; the menu button

	pop	cx, ax			;else draw the entire top border
	sub	cx, ax
drawTop:
	clr	ax
	clr	bx
	call	GrDrawHLine
	jmp	short done

drawTopLeft:
	pop	dx			;dx = left(menu)
	sub	ax, dx			;ax = left(menuButton) - left(menu)
	jle	drawTopRight		;if < or =, check right side of button

	mov	cx, ax
	clr	ax
	call	GrDrawHLine		;draw left-end of top border
drawTopRight:
	mov	ax, si			;ax = right(menuButton)
	sub	ax, dx			;ax = right(menuButton) - left(menu)
	pop	cx			;cx = right(menu)
	sub	cx, si			;cx = right(menu) - right(menuButton)
	jle	done

	add	cx, ax
	dec	ax			;one more to close the gap
	call	GrDrawHLine
done:
	pop	ax, cx, si
	ret
OpenWinDrawMenuBorder	endp



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
	mov	al, ColorScheme <MO_ETCH_COLOR, MO_ETCH_COLOR>
	cmp	ah, DC_GRAY_1
	je	20$
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	20$
	mov	al, ColorScheme <C_WHITE, MO_ETCH_COLOR>
20$:
	push	ax			; Save display type/border color scheme
	call	OpenWinGetInsideResizeBorderBounds
	pop	bp
	call	WinDrawBoxFrame

	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax, cx, si, bp		;get color scheme, draw flags
	ret

OpenWinDrawThickLineBorder	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDrawHeaderTitleBackground

DESCRIPTION:	This procedure draws the background for the header area.
		It also draws the border for app modal dialogs.

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

	uses	bp, ax, cx
	.enter

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.  

	mov	cl, mask OLWHS_HEADER_AREA_INVALID or \
		    mask OLWHS_FOCUS_AREA_INVALID or \
		    mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	;see if this window has a title

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	LONG	jz done			;skip if not...

	mov	dx, ax				;save display type

	;depending upon whether this window has the focus, choose one
	;of two TitleBarBackground colors

	push	ds				;save segment of object block
	mov	bx, segment idata		;get segment of core blk
	mov	ds, bx
	mov	bh, ds:[moCS_inactiveTitleBar]
	mov	bl, ds:[moCS_activeTitleBar]
	pop	ds

	call	OpenWinTestForFocusAndTarget
	test	ax, mask HGF_SYS_EXCL
	pushf

	mov	al, bl
	jnz	haveColor
	mov	al, bh
haveColor:
	clr	ah
	call	GrSetAreaColor

	test	ds:[bp].OLWI_type, MOWT_NOTICE_WINDOW
	jz	afterAppModal
	test	ds:[bp].OLPWI_flags, mask OLPWF_APP_MODAL
	jz	afterAppModal

	push	dx				;save display type
	call	WinDrawAppModalBorder		;draw app modal border
	pop	dx				;restore display type

afterAppModal:
	popf
	jnz	drawActive

	mov	bp, dx
	call	OpenWinGetHeaderTitleBounds
	inc	bx
	call	GrFillRect

	xchg	ax, bp
	mov	al, ColorScheme <MO_ETCH_COLOR, C_WHITE>
	cmp	ah, DC_GRAY_1
	xchg	ax, bp
	je	drawBottomBorder

	call	WinDrawBoxFrame			;draw title frame
	jmp	short done

drawBottomBorder:
	dec	cx				;adjust for line drawing
	dec	dx
	mov	bx, dx
	mov	dx, ax
	mov	ax, MO_ETCH_COLOR
	call	GrSetLineColor
	mov	ax, dx
	call	GrDrawHLine
	jmp	short done

drawActive:
	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data
	inc	bx
	call	GrFillRect			;draw basic colored background

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	ax, SDM_50
	call	GrSetAreaMask
	pop	ax

	call	GrFillRect

	test	ds:[bp].OLWI_type, MOWT_NOTICE_WINDOW
	jz	afterAppModal2
	test	ds:[bp].OLPWI_flags, mask OLPWF_APP_MODAL
	jz	afterAppModal2
	call	WinDrawAppModalBorder

afterAppModal2:
	mov	ax, SDM_100
	call	GrSetAreaMask
done:
	.leave
exit:
	ret
OpenWinDrawHeaderTitleBackground	endp

WinDrawAppModalBorder	proc	near
	call	OpenWinGetBounds
	inc	ax
	inc	bx
	dec	cx
	dec	dx

	push	dx			;TOP BORDER
	mov	dx, bx
	add	dx, CUAS_NOTICE_FRAME_INSET
	call	GrFillRect
	pop	dx

	push	bx			;BOTTOM BORDER
	mov	bx, dx
	sub	bx, CUAS_NOTICE_FRAME_INSET
	call	GrFillRect
	pop	bx

	push	cx			;LEFT BORDER
	mov	cx, ax
	add	cx, CUAS_NOTICE_FRAME_INSET
	call	GrFillRect
	pop	cx

	push	ax			;RIGHT BORDER
	mov	ax, cx
	sub	ax, CUAS_NOTICE_FRAME_INSET
	call	GrFillRect
	pop	ax

	ret
WinDrawAppModalBorder	endp


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
	Joon	8/92		No GStrings in title

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

;	Nuked -- this handled by VisDrawMoniker now.  -cbh 12/15/92
;	;point to generic instance data and grab textual(?) moniker
;	push	di
;	call	WinCommon_DerefGen_DI
;	mov	di, ds:[di].GI_visMoniker ; fetch moniker - *ds:[di] = moniker
;	tst	di			;is there a moniker?
;	jz	abort
;
;	mov	di, ds:[di]			;ds:[di] = moniker
;	mov	di, {word} ds:[di].VM_type	;get moniker type
;	test	di, mask VMT_GSTRING		;is a GString?
;	jz	drawTitle
;abort:
;	pop	di
;	jmp	exit			;skip if not...
;
;drawTitle:
;	pop	di

	push	ax, cx, bp, es		;preserve color scheme, draw flags
					;and pointer to instance data

EC <	call	GenCheckGenAssumption	;Make sure gen data exists 	>

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID or \
		    mask OLWHS_FOCUS_AREA_INVALID
	call	OpenWinHeaderResetInvalid
   
	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	LONG	jz done			;skip if not titled...

	;CUA/Motif: grab color values from color scheme variables in idata

	call	OpenWinTestForFocusAndTarget
	test	ax, mask HGF_SYS_EXCL
	push	ds
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	mov	al, ds:[moCS_titleBarText]
	jnz	10$
	mov	al, C_DARK_GREY
10$:	clr	ah
	call	GrSetTextColor
	pop	ds

	xchg	bp, di				;bp = GState, di = inst. data
	call	OpenWinGCMSetTitleFontSize
	xchg	bp, di				;di = GState, bp = inst. data
	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data
	inc	bx				;move inside top and bottom
	dec	dx				;C_BLACK lines

	;(ax, bx), (cx, dx) = coordinates for title area.
	;Calculate size of text moniker.

	add	ax, CUAS_TITLE_TEXT_MARGIN	;leave margin on left side
	sub	cx, CUAS_TITLE_TEXT_MARGIN	;leave margin on right side
	sub	cx, ax				;width of title area
	jns	20$
	clr	cx

;HACK
20$:	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jz	30$			;If not GCM, branch	
	mov	bx, GCM_TITLE_TEXT_Y_OFFSET-TITLE_TEXT_Y_OFFSET
	call	OpenCheckIfCGA		;see if on CGA
	jnc	30$			;not CGA, branch
	mov	bx, GCM_CGA_TITLE_TEXT_Y_OFFSET-CGA_TITLE_TEXT_Y_OFFSET
;END HACK

30$:	add	bx, TITLE_TEXT_Y_OFFSET

	;
	; If it's a CGA display, compensate for a smaller header height
	push	ax
	call	OpenMinimizeIfCGA	;zeroes ax, sets CF if CGA
	pop	ax
	jnc	notCGA
	sub	bx, (TITLE_TEXT_Y_OFFSET - CGA_TITLE_TEXT_Y_OFFSET) - 1
notCGA:

	sub	sp, size DrawMonikerArgs		;make room for args
	mov	bp, sp					;pass pointer in bp
	mov	ss:[bp].DMA_gState, di			;pass gstate
	push	di					;save it
	mov	ss:[bp].DMA_xInset, ax			;pass x inset
	mov	ss:[bp].DMA_yInset, bx			;and y inset
	mov	ss:[bp].DMA_xMaximum, cx		;titlearea is max width
	mov	ss:[bp].DMA_yMaximum, MAX_COORD		;don't clip Y
	
	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST) or \
		    mask DMF_CLIP_TO_MAX_WIDTH or \
		    mask DMF_TEXT_ONLY
		    
	call	OpenWinDrawMoniker			;draw it
	pop	di					;restore gstate
	add	sp, size DrawMonikerArgs		;dump args

	mov	ax, C_BLACK		;reset text color
	call	GrSetTextColor

	;restore original point size

	mov	bp, di
	call	OpenWinGCMResetTitleFontSize
done:
	pop	ax, cx, bp, es		;get color scheme, draw flags
exit:					;and pointer to instance data
	ret

OpenWinDrawHeaderTitle	endp

WinCommon ends
