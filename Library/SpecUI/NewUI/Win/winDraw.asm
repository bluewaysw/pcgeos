COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NewUI/Win (window code specific to NewUI)
FILE:		winDraw.asm

ROUTINES:
	Name				Description
	----				-----------
	WinDrawBoxFrame			draw 2 color LT/RB frame
	OpenWinCheckIfBordered		test if window has a border
	OpenWinGetBounds		gets bounds for object
	OpenWinGetInsideBorderBounds	gets bounds inside the border
	OpenWinGetHeaderBounds		gets bounds of header
	OpenWinInitGState		sets up font, etc. info in GState
	OpenWinDraw			MSG_VIS_DRAW handler for OLWinClass
	OpenWinDrawWindowBorder		draws window border
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

	$Id: winDraw.asm,v 1.2 98/05/04 06:15:03 joon Exp $

------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinDrawBoxFrame

DESCRIPTION:	Draws a frame at the bounds passed.  If the display type is
		B&W, then it will just draw a frame.  If it's a color display,
		then it will draw a "shadowed" frame in 2 colors.

PASS:		ax, bx, cx, dx	- GrFillRect-style bounds of the rectangle
		di	- GState to use
		bp-low	- <rightBottom color><topLeft color>
		bp-high	- display type

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

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

FUNCTION:	OpenWinCheckIfBordered

DESCRIPTION:	Check if window is bordered

PASS:		*ds:si	= OLWinClass object
		ds:bp	= OLWinClass instance data
RETURN:		carry set if bordered
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/4/98		Initial version

------------------------------------------------------------------------------@

OpenWinCheckIfBordered	proc	near

	; If window is maximized, then no border

	test	ds:[bp].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	done		; exit with carry clear

	; If custom window, then no border

	test	ds:[bp].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	done		; exit with carry clear

	stc			; window has border
done:
	ret
OpenWinCheckIfBordered	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGetBounds
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

;This procedure gets the boundary coordinates of the window, relative to itself

OpenWinGetBounds	proc	near
	;we cannot use VisGetBounds because this object is a WINDOWED object.

	call	VisGetSize
	clr	ax
	clr	bx
	ret
OpenWinGetBounds	endp

;CUAS: the bounds returned do not include the border area.

OpenWinGetInsideBorderBounds	proc	near
	class	OLWinClass

	call	OpenWinGetBounds
	call	OpenWinCheckTVBorder
	jc	tvBorder
	call	OpenWinCheckIfBordered
	jnc	done

	; 4 pixel border for all other windows

	add	ax, 4
	add	bx, 4
	sub	cx, 4
	sub	dx, 4
done:	
	ret

tvBorder:
	push	ds
	segmov	ds, <segment dgroup>
	add	ax, ds:[tvBorderWidth]
	add	bx, ds:[tvBorderHeight]
	sub	cx, ds:[tvBorderWidth]
	sub	dx, ds:[tvBorderHeight]
	pop	ds
	ret
OpenWinGetInsideBorderBounds	endp


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

	call	OpenWinGetInsideBorderBounds

	push	ds
	segmov	ds, <segment dgroup>, dx
	mov	dx, ds:[specDisplayScheme].DS_pointSize
	pop	ds

	;Header is on top of window frame line, so don't change left, right,
	;or top coordinates here

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
	mov	di, bp			;di = GState

	call	OpenWinInitGState

	;(al = color scheme, ah = display type, cl = DrawFlags)

	call	OpenWinDrawWindowBorder

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
	push	bp, cx
	mov	ax, MSG_VIS_DRAW
	mov	di, segment VisCompClass
	mov	es, di
	mov	di, offset VisCompClass
	call	ObjCallClassNoLock
	pop	di, cx

	; If we didn't draw children, at least draw title bar children
	test	cl, mask DF_DONT_DRAW_CHILDREN
	jz	gotChildren
	call	DrawTitleChildren
gotChildren:

	; Darken background if necessary

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLWI_moreFixedAttr, mask OMWFA_DRAW_DISABLED
	jz	done

	call	OpenWinDarkenWindow
done:
	ret
OpenWinDraw	endp

OpenWinDarkenWindow	proc	far
	uses	si
	.enter

	mov	si, WIT_COLOR
	call	WinGetInfo
	ornf	ah, mask WCF_DRAW_MASK or mask WCF_MASKED
	call	WinSetInfo

	push	ax, bx
	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	GrGetMaskBounds
	call	GrFillRect
	pop	ax, bx

	andnf	ah, not mask WCF_DRAW_MASK
	call	WinSetInfo
done:
	.leave
	ret
OpenWinDarkenWindow	endp

;
; stripped down version of VisCompClass MSG_VIS_DRAW
;
DTC_frame	struct
    DTC_theBottom	word
DTC_frame	ends

DTC_vars	equ	<ss:[bp-(size DTC_frame)]>
DTC_bottom	equ	<DTC_vars.DTC_theBottom>

DrawTitleChildren	proc	near
	class	VisCompClass
	uses	bx, cx, si, di, es
	.enter
	mov	bp, di		; bp = gstate
	andnf	cl, not mask DF_DONT_DRAW_CHILDREN
	mov	di, ds:[si]	; get offset to composite in si
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
				; make sure composite is drawable
	test	ds:[di][VI_attrs], mask VA_DRAWABLE
	jz	VCD_done	; if it isn't, skip drawing altogether
	test	cl, mask DF_PRINT
	jnz	10$
				; make sure composite is realized
	test	ds:[di][VI_attrs], mask VA_REALIZED
	jz	VCD_done	; if it isn't, skip drawing altogether
	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	10$		; IMAGE_INVALID only covers margins, must
				;   continue -cbh 12/17/91
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID 
	jnz	VCD_done	; if not, skip drawing it
10$:
	; allocate frame on the stack to hold update bounds
	push	bp			;save gstate
	mov	di,bp			;di = gstate
	mov	bp,sp
	sub	sp, size DTC_frame
	push	cx
	call	OpenWinGetHeaderTitleBounds	; dx = title bottom
	mov	DTC_bottom,dx
	pop	cx
	mov	dx,di			; pass gstate in dx
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset VI_link	;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset DTC_callBack
	push	bx

	mov	di,offset VCI_comp
	mov	bx,offset Vis_offset
	mov	ax, MSG_VIS_DRAW
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
VCD_noDraw:
	mov	sp,bp
	pop	bp			;gstate
VCD_done:
	.leave
	ret
DrawTitleChildren	endp

DTC_callBack	proc	far
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	done
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	done
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	5$			; not a composite, check invalid
	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	10$			; must skip invalid check in case one or
					;   more of our children are valid.
5$:
					; make sure that image is valid
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jnz	done			; if not, skip drawing it
10$:
					; make sure child isn't a window
					; (makes no sense. removed.cbh 12/13/91)
;	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
;	jnz	noDraw			; if it is, skip sending draw to it
	; IF bounds still in initial state, & haven't been set, don't draw
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_right
	cmp	ax,bx
	jge	done			; skip if width 0 or less
	; test the bounds
	mov	ax, ds:[di].VI_bounds.R_bottom
	cmp	ax, DTC_bottom		; if obj.bottom > title.bottom
	jg	done
	push	cx			; preserve DrawFlags
	push	dx			; preserve GState handle
	push	bp
	mov	bp,dx			; pass gstate in bp
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLockES	; send DRAW
	pop	bp
	pop	dx
	pop	cx
done:
	clc
	ret
DTC_callBack	endp


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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinDrawWindowBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a border around window

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
	Joon	2/27/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinDrawWindowBorder	proc	near
	class	OLWinClass
	uses	ax, cx, si, bp		;preserve color scheme, draw flags
	.enter

	; Nothing to draw if window doesn't have a border

	call	OpenWinCheckTVBorder
	jc	tvBorder
	call	OpenWinCheckIfBordered
	jnc	done

	; Determine the color scheme to use

	mov	bx, ax
	mov	al, ColorScheme <C_BLACK, C_LIGHT_GRAY>
	mov	bl, ColorScheme <C_DARK_GRAY, C_WHITE>

	push	bx			;Save display type/inner border color
	push	ax			;save display type/outer border color
	call	OpenWinGetBounds

	pop	bp			;restore outer border color
	call	WinDrawBoxFrame		;draw outer border

	inc	ax			;adjust bounds for inner border
	inc	bx			;adjust bounds for inner border
	dec	cx			;adjust bounds for inner border
	dec	dx			;adjust bounds for inner border

	pop	bp			;restore inner border color
	call	WinDrawBoxFrame		;draw inner border

	mov	ax, C_BLACK
	call	GrSetLineColor
done:
	.leave
	ret

tvBorder:
	call	GrSaveState
	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	OpenWinGetBounds
	push	ds
	segmov	ds, <segment dgroup>
	;top
	push	dx
	mov	dx, bx
	add	dx, ds:[tvBorderHeight]
	dec	dx
	call	GrFillRect
	pop	dx
	;bottom
	push	bx
	mov	bx, dx
	sub	bx, ds:[tvBorderHeight]
	inc	bx
	call	GrFillRect
	pop	bx
	;left
	push	cx
	mov	cx, ax
	add	cx, ds:[tvBorderWidth]
	dec	cx
	call	GrFillRect
	pop	cx
	;right
	mov	ax, cx
	sub	ax, ds:[tvBorderWidth]
	inc	ax
	call	GrFillRect
	call	GrRestoreState
	pop	ds
	jmp	done

OpenWinDrawWindowBorder	endp


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

OpenWinDrawHeaderTitleBackground	proc	near
	class	OLWinClass
	uses	bp, ax, cx, bp
	.enter

	;
	; Code added 2/ 6/92 to get rid of title on maximized windows.
	; 
	call	OpenWinCheckMenusInHeader
	jc	done			;menus in header, don't draw title

	;reset some invalid flags for this window, to indicate that draw
	;has occurred.  

	mov	cl, mask OLWHS_HEADER_AREA_INVALID or \
		    mask OLWHS_FOCUS_AREA_INVALID or \
		    mask OLWHS_TITLE_AREA_INVALID
	call	OpenWinHeaderResetInvalid

	;see if this window has a title

	test	ds:[bp].OLWI_attrs, mask OWA_TITLED
	jz	done			;skip if not...

	;depending upon whether this window has the focus, choose one
	;of two TitleBarBackground colors

	push	ds			;save segment of object block
	mov	bx, segment idata	;get segment of core blk
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

	call	OpenWinGetBounds
	call	OpenWinCheckTVBorder
	jnc	notTVBorder
	push	ds, bx
	mov	bx, segment idata
	mov	ds, bx
	add	ax, ds:[tvBorderWidth]
	sub	cx, ds:[tvBorderWidth]
	pop	ds, bx
	jmp	short 10$
notTVBorder:
	call	OpenWinCheckIfBordered
	jnc	10$

	add	ax, 4			;4 pixel offset 
	sub	cx, 4			;4 pixel offset
10$:
	push	ax, cx 
	call	OpenWinGetHeaderTitleBounds
	pop	ax, cx

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
	call	GrFillRect
afterDraw:
	popf
	jnz	done

	call	OpenCheckIfBW
	jnc	done

	dec	cx
	dec	dx
	call	GrDrawRect		;draw rect for BW if not target  
done:
	.leave
	ret

drawGradient:
	popf
	pushf
	push	si, ax
	call	DrawGradientTitle
	pop	si, ax
	jmp	afterDraw
OpenWinDrawHeaderTitleBackground	endp

DrawGradientTitle	proc	near
	uses	bx, cx, dx, ds

locs	local	GradientLocals

	mov_tr	si, ax				;si <- left bound
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
	jnz	haveColor
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
	mov	al, C_LIGHT_GREY
10$:	clr	ah
	call	GrSetTextColor
	pop	ds

	xchg	bp, di				;bp = GState, di = inst. data
;zFix;	call	OpenWinGCMSetTitleFontSize
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
;zFix;	call	OpenWinGCMResetTitleFontSize
done:
	pop	ax, cx, bp, es		;get color scheme, draw flags
exit:					;and pointer to instance data
	ret

OpenWinDrawHeaderTitle	endp

WinCommon ends
