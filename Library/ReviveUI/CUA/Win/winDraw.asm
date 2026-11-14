COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CUA/Win (window code specific to CUA specific UI)
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
	Eric	1/90		copied from Motif/Win/winDraw.asm

DESCRIPTION:
	This file contains procedures for the DRAW method of OLWinClass.

	$Id: winDraw.asm,v 1.1 97/04/07 10:56:52 newdeal Exp $

-------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetBounds
		OpenWinGetInsideResizeBorderBounds
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

;CUAS: the bounds returned do not include the resize border area.

OpenWinGetInsideResizeBorderBounds	proc	near
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
	add	ax, CUAS_WIN_RESIZE_BORDER_SIZE
	add	bx, CUAS_WIN_RESIZE_BORDER_SIZE
	sub	cx, CUAS_WIN_RESIZE_BORDER_SIZE
	sub	dx, CUAS_WIN_RESIZE_BORDER_SIZE
OWGNSB_noResize:

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

OpenWinGetInsideBounds	proc	near
	call	OpenWinGetInsideResizeBorderBounds	;get window bounds, less
						;shadow area
	ret

OpenWinGetInsideBounds	endp


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

------------------------------------------------------------------------------@

OpenWinGetHeaderBounds	proc	near
	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	mov     dx, ds:[specDisplayScheme].DS_pointSize
	pop	ds

	push	dx
	call	OpenWinGetInsideResizeBorderBounds
					;get window bounds, less resize
					;border area.

	;Header is on top of window frame line, so don't change left, right,
	;or top coordinates here

	pop	dx			;restore font height
	test	ds:[bp].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	50$

	clr	dh
	add	dx, bx			;add top
	add	dx, CUAS_WIN_HEADER_Y_SPACING-1	;add margin
	jmp	short done

50$:	;for GCM headers: ignore font size (for now)

	mov	dx, CUAS_GCM_HEADER_HEIGHT

done:
	ret

OpenWinGetHeaderBounds	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinDraw -- MSG_VIS_DRAW for OLWinClass

DESCRIPTION:	This procedure is called when

PASS:		ds:*si	- instance data
		es	- segment of zzzClass
		ax	- METHOD_
		cx, dx	- ?
		bp	- handle of GState

RETURN:		cl - DrawFlags: DF_UPDATE set if updating
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

OpenWinDraw	method	OLWinClass, MSG_VIS_DRAW
	mov	di, bp			;di = GState

	call	OpenWinInitGState

	;(al = color scheme, ah = display type, cl = DrawFlags)

	;draw resize border if necessary.
	;	ds:bp = specific instance data for object
	;	di = gstate

if _MOTIF or _CUA	;(1.x: MOTIF/CUA code, see the endif)
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	OWOW_10				;not resizable...

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

if _DESKMATE	;START of DESKMATE specific code -------------------------------
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jz	OWOW_20
	call	OpenWinDrawResizeBorder
endif		;END of DESKMATE specific code ---------------------------------

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

	call	OpenWinDrawHeaderTitleBackground
	call	OpenWinDrawHeaderTitle ;Draw window title

OWD_noHeader:
	mov	bp, di			;bp = GState
					;Then call parent class, to do children
	mov	ax, MSG_VIS_DRAW
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock

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
	cmp	ah, DC_GRAY_1		;is this a B@W display?
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

------------------------------------------------------------------------------@

OpenWinDrawResizeBorder	proc	near
	push	ax, cx			;preserve color scheme

	;grab color value from color scheme variables in idata

	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_activeBorder]
	call	GrSetAreaColor
	mov	al, ds:[moCS_windowFrame]
	call	GrSetLineColor
	pop	ds

	call	OpenWinGetBounds	;(ax, bx) - (cx, dx) = bounds

	call	GrDrawRect		;draw black frame outside resize border
	inc	ax
	inc	bx
	dec	cx
	dec	dx

	;draw resizable border

	push	dx			;TOP RESIZE BORDER
	mov	dx, bx
	add	dx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	FillRectInclusive	;draw 50% background
	pop	dx

	push	bx			;BOTTOM RESIZE BORDER
	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	FillRectInclusive	;draw 50% background
	pop	bx

	push	bx, dx
	add	bx, CUAS_WIN_RESIZE_BORDER_SIZE-1
	sub	dx, CUAS_WIN_RESIZE_BORDER_SIZE-1

	push	cx			;LEFT RESIZE BORDER
	mov	cx, ax
	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	FillRectInclusive	;draw 50% background
	pop	cx

	push	ax			;RIGHT RESIZE BORDER
	mov	ax, cx
	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-2
	call	FillRectInclusive	;draw 50% background

;	push	ax
;	mov	ax, GR_PSOLID		;restore to 100% mask
;	call	GrSetAreaMask
;	pop	ax

if _MOTIF or _CUA	;(1.x: MOTIF/CUA code, see the endif)
	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	ax, C_BLACK
	call	GrSetLineColor
endif			;END of MOTIF/CUA specific code ------------------------
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	ax, C_YELLOW
	call	GrSetLineColor
endif		;END of DESKMATE specific code ---------------------------------
	pop	ax

	pop	bx, dx			;restore original size

	;draw short line segments in resize border to show where resize
	;boxes are
						;VERTICAL LINES
	push	ax, cx
	add	ax, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_WIDTH-2 ;left column
	mov	cx, ax

	push	dx
	mov	dx, bx
	add	dx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;top segment
	call	GrDrawLine
	pop	dx

	push	bx
	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;bottom segment
	call	GrDrawLine
	pop	bx
	pop	ax, cx

	push	ax, cx
	sub	cx, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_WIDTH-2 ;right column
	mov	ax, cx

	push	dx
	mov	dx, bx
	add	dx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;top segment
	call	GrDrawLine
	pop	dx

	push	bx
	mov	bx, dx
	sub	bx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;bottom segment
	call	GrDrawLine
	pop	bx
	pop	ax, cx

						;HORIZONTAL LINES
;	DoPush	bx, dx
;	add	bx, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_HEIGHT-2 ;top row
;	mov	dx, bx

;	push	cx
;	mov	cx, ax
;	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;left segment
;	call	GrDrawLine
;	pop	cx

;	push	ax
;	mov	ax, cx
;	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-2	;right segment
;	call	GrDrawLine
;	pop	ax
;	DoPopRV	bx, dx

	;
	; Top row, revived: the 1.x code above is commented out because
	; the header height follows the font, not CUAS_WIN_ICON_HEIGHT, so the
	; marks landed inside the title bar.  Put them at the bottom of the
	; header instead, as CUA does.
	;
	push	bx, dx
	push	ax, cx
	call	OpenWinGetHeaderBounds	;dx = bottom of the header
	mov	bx, dx
	pop	ax, cx
	push	cx
	mov	cx, ax
	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;left segment
	mov	dx, bx
	call	GrDrawLine
	pop	cx
	push	ax
	mov	ax, cx
	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-2	;right segment
	call	GrDrawLine
	pop	ax
	pop	bx, dx

;	DoPush	bx, dx
	sub	dx, CUAS_WIN_RESIZE_BORDER_SIZE+CUAS_WIN_ICON_HEIGHT-2 ;bottom row
	mov	bx, dx

	push	cx
	mov	cx, ax
	add	cx, CUAS_WIN_RESIZE_BORDER_SIZE-2	;left segment
	call	GrDrawLine
	pop	cx

;	push	ax
	mov	ax, cx
	sub	ax, CUAS_WIN_RESIZE_BORDER_SIZE-2	;right segment
	call	GrDrawLine
;	pop	ax
;	DoPopRV	bx, dx

	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax, cx
	ret
OpenWinDrawResizeBorder	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FillRectInclusive

DESCRIPTION:	GrFillRect with the 1.x coordinates: fills the right and
		bottom edge too (GrFillRect doesn't since 2.0).

PASS:		ax, bx, cx, dx	- rectangle, inclusive
		di		- gstate

RETURN:		nothing

DESTROYED:	nothing

------------------------------------------------------------------------------@
FillRectInclusive	proc	near
	inc	cx
	inc	dx
	call	GrFillRect
	dec	cx
	dec	dx
	ret
FillRectInclusive	endp


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

------------------------------------------------------------------------------@

if	0		;not needed, causes problems -cbh
OpenWinDrawInsideResizeBorderBackground	proc	near
	push	ax, cx			;reserve color scheme, draw flags

					; If pinnable, then tranparent,
					; redraw anyway

	;if not update then draw background

	test	cl, mask DF_UPDATE	;is this an update?
	jnz	OWDNSB_update		;skip if so (no need to draw - this
					;is an expose event, so the window
					;system drew C_WHITE already)...

OWDNSB_10:
	;CUA/Motif: grab color value from color scheme variables in idata
	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_windowBG]	;C_WHITE
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

------------------------------------------------------------------------------@

OpenWinDrawThickLineBorder	proc	near
	push	ax, cx			;preserve color scheme, draw flags

if _MOTIF or _CUA	;(1.x: CUA/MOTIF code, see the endif)
	;CUA/Motif: grab color value from color scheme variables in idata

	push	ds
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_windowFrame]
	pop	ds
	call	GrSetLineColor
	call	GrSetAreaColor
endif 			;END of CUA/MOTIF specific code ------------------------

if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	ax, C_YELLOW
	test	ds:[bp].OLWI_attrs, mask OWA_RESIZABLE
	jnz	OWDWF_10
	mov	ax, DK_RED
OWDWF_10:
	call	GrSetLineColor
	call	VisGetSize		;get size of actual window from instance
					;data of visual part
	dec	cx
	dec	dx
	clr	ax
	clr	bx
	call	GrDrawRect
endif		;END of DESKMATE specific code ---------------------------------

	call	OpenWinGetInsideResizeBorderBounds
	call	GrDrawRect

if _MOTIF or _CUA	;(1.x: CUA/MOTIF code, see the endif)
	;CUA/Motif: if this is a GenSummons (OLNoticeClass),
	;then draw the thick inset frame line

	cmp	ds:[bp].OLWI_type, MOWT_NOTICE_WINDOW
	jne	OWDWF_80			;skip if not...

	call	OpenWinGetInsideResizeBorderBounds
	add	ax, CUAS_NOTICE_FRAME_INSET
	sub	cx, CUAS_NOTICE_FRAME_INSET
	add	bx, CUAS_NOTICE_FRAME_INSET
	sub	dx, CUAS_NOTICE_FRAME_INSET

	push	cx				;left vertical line
	mov	cx, ax
	add	cx, CUAS_WIN_THICK_BORDER_EXTRA_X_MARGIN-1
	call	FillRectInclusive
	mov	ax, cx
	inc	ax
	pop	cx

	push	ax				;right vertical line
	mov	ax, cx
	sub	ax, CUAS_WIN_THICK_BORDER_EXTRA_X_MARGIN-1
	call	FillRectInclusive
	mov	cx, ax
	dec	cx
	pop	ax

	push	dx				;top horizontal line
	mov	dx, bx
	add	dx, CUAS_WIN_THICK_BORDER_EXTRA_Y_MARGIN-1
	call	FillRectInclusive
	pop	dx

	mov	bx, dx				;bottom horizontal line
	sub	bx, CUAS_WIN_THICK_BORDER_EXTRA_Y_MARGIN-1
	call	FillRectInclusive

OWDWF_80:
endif 			;END of CUA/MOTIF specific code ------------------------

	mov	ax, C_BLACK
	call	GrSetLineColor
CUAS <	call	GrSetAreaColor						>
	pop	ax, cx			;get color scheme, draw flags
	ret

OpenWinDrawThickLineBorder	endp


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

------------------------------------------------------------------------------@

;will SAVE BYTES here eventually

OpenWinDrawHeaderTitleBackground	proc	near
	push	ax, cx			;preserve color scheme and draw flags

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.

	mov	cl, mask OLWHS_HEADER_AREA_INVALID or mask OLWHS_FOCUS_AREA_INVALID or mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	;see if this window has a title

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	LONG	jz done

	;see if this is a pinned menu

	push	ds			;save segment
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
	jmp	short setColorsPopDS	;skip ahead to set colors and pop ds...

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
	popf
	jnz	setColorsPopDS		;skip if so...

	mov	al, ds:[moCS_inactiveTitleBar] ;is inactive (C_WHITE)
;???	mov	al, ds:[moCS_menuBar]	;LT_CYAN

setColorsPopDS:
	call	GrSetAreaColor
	mov	al, ds:[moCS_windowFrame]	;get color from line
	call	GrSetLineColor			;above and below title
	pop	ds

	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data
						
	push	ax, cx				;save left and top of header
	
	push	di
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	clr	ax				;my apologies for this ill-	
	mov	cx, ds:[di].VI_bounds.R_right	;  behaved code!  Should live
	sub	cx, ds:[di].VI_bounds.R_left	;  elsewhere and take resize
	pop	di		 		;  borders into account. -cbh
	
;Optimization: assume window with title bar has a LINE_BORDER
;	push	dx
;	mov	dx, bx			;draw top C_BLACK line
;	call	GrDrawLine
;	pop	dx

if _MOTIF or _CUA	;(1.x: MOTIF/CUA code, see the endif)
	push	bx			;draw bottom C_BLACK line
	mov	bx, dx			;   all the way across to make up for
	call	GrDrawLine		;   the lack of bottom lines on buttons.
	pop	bx
endif		;END of MOTIF/CUA/OPEN LOOK specific code ----------------------

	DoPop	cx, ax			;restore header left and right
	
	inc	bx			;colored portion is inside
				;top and bottom lines (2.x: the title bounds are
				;OLWI_titleBarBounds, right edge exclusive, and the
				;bottom is the line row: GrFillRect stops above it)
	call	GrFillRect		;draw colored background

if _DESKMATE	;START of DESKMATE specific code -------------------------------
	test	ds:[bp].OLWI_focusExcl.HG_flags, mask HGF_SYS_EXCL
	jz	done			;skip if inactive...

	push	ax
	mov	ax, C_YELLOW
	call	GrSetAreaColor
	mov	ax, GR_PGREY50
	call	GrSetAreaMask
	pop	ax
	inc	dx
	call	GrFillRect		;draw colored background
	mov	ax, GR_PSOLID		;restore to 100% mask
	call	GrSetAreaMask
endif		;END of DESKMATE specific code ---------------------------------

done:
	pop	ax, cx			;get color scheme and draw flags
	ret
OpenWinDrawHeaderTitleBackground	endp


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

------------------------------------------------------------------------------@

OpenWinDrawHeaderTitle	proc	near
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
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_windowFrame]	;get general purpose C_BLACK
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	al, DK_BLUE
endif		;END of DESKMATE specific code ---------------------------------
	call	GrSetAreaColor			;for rect behind text
	mov	al, ds:[moCS_titleBarText]
	call	GrSetTextColor
	pop	ds
	call	OpenWinGetHeaderTitleBounds	;get title bounds from
						;instance data
	inc	bx				;move inside top and bottom
	dec	dx				;C_BLACK lines
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	sub	dx, 2
endif		;END of DESKMATE specific code ---------------------------------

	mov	bp, di				;bp = gstate

	;(ax, bx), (cx, dx) = coordinates for title area.
	;Calculate size of text moniker.
	
	sub	cx, ax			;save width of title area 
	push	cx			;

	push	dx			;save bottom bound of title area
	push	bx			;save top bound of title area
	push	ax			;save left bound of title area
	push	cx			;save width of title area again

	;point to generic instance data and grab textual(?) moniker

	mov	di, ds:[si]		; ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker ; fetch moniker
	tst	di			;is there a moniker?
	jz	OWDHC_abort		;skip if not...

	segmov	es, ds			;es:di = moniker
					;pass bp = gstate
	call	OpenWinGetMonikerSize	;get size of moniker (cx, dx)

	pop	bx			;bx = width of title area		
	push	bx			;save again...
	sub	bx, cx			;find amount of space around text

	sub	bx, (CUAS_TITLE_TEXT_MARGIN*2)+2
					;see +2 note below...
					;account for margins around text,

	tst	bx			;did it go negative? 
	jns	OWDHC_10		;skip if not...
	clr	bx			;use offset of 0
OWDHC_10:
	sar	bx, 1			;convert total space into offset

	;bx = offset from the left side of the title area to the text margin
	;(text margin = 3 pixel area to left of text)

	pop	di			;restore width of title area
	pop	ax			;get left bound of title area
	add	ax, bx			;add offset to text margin
					;ax = left bounds of text area

	pop	bx			;get top bound of title area
	pop	dx			;get bottom bound of title area

	add	cx, (CUAS_TITLE_TEXT_MARGIN*2)+2
					;+2 fixes inexplicable problem
					;with right margin...

					;cx = right bound of text area
	cmp	cx, di			;wider than title area?
	jbe	OWDHC_15		;no, branch
	mov	cx, di			;else keep to title width
OWDHC_15:
	add	cx, ax			;cx = left bound + offset + text width
	
	mov	di, bp			;pass di = gstate
	call	FillRectInclusive		;draw a white rectangle

	add	ax, CUAS_TITLE_TEXT_MARGIN
					;move inside margin area
	mov	dx, ax			;dl = X offset from OLWinClass bounds
	
	add	bx, 2			;push text down a bit

	pop	cx			;restore width of title area
	push	bp
	sub	sp, size DrawMonikerArgs		;make room for args
	mov	bp, sp					;pass pointer in bp
	mov	ss:[bp].DMA_gState, di			;pass gstate
	push	di					;save it
	mov	ss:[bp].DMA_xInset, dx			;pass x inset
	mov	ss:[bp].DMA_yInset, bx			;and y inset
	mov	ss:[bp].DMA_xMaximum, cx		;title area is max width
	mov	ss:[bp].DMA_yMaximum, MAX_COORD		;don't clip Y
	
	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST) or \
		    mask DMF_CLIP_TO_MAX_WIDTH
		    
	call	OpenWinDrawMoniker			;draw it
	pop	di					;restore gstate
	add	sp, size DrawMonikerArgs		;dump args
	pop	bp

	mov	di, bp			;pass di = gstate
if _MOTIF or _CUA	;(1.x: MOTIF/CUA code, see the endif)
	mov	ax, C_BLACK		;reset text color
endif			;END of MOTIF/CUA specific code ------------------------
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	ax, C_YELLOW		;reset text color
endif		;END of DESKMATE specific code ---------------------------------
	call	GrSetTextColor

done:

	pop	ax, cx, bp, es		;get color scheme, draw flags
					;and pointer to instance data
	ret

OWDHC_abort:
	mov	di, bp			;return di = gstate
	add	sp, 10			;clean up stack
	jmp	short done		;branch back to finish up

OpenWinDrawHeaderTitle	endp

WinCommon ends

