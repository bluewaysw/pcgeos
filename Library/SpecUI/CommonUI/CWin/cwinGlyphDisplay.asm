COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinGlyphDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
	OLWinGlyphDisplayClass	Windowed GlyphDisplay object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

DESCRIPTION:
	$Id: cwinGlyphDisplay.asm,v 1.1 97/04/07 10:53:10 newdeal Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLWinGlyphDisplayClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	method	VupCreateGState, OLWinGlyphDisplayClass, \
					MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends


;---------------------------------------------------


WinIconCode	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayStartSelect -- MSG_META_START_SELECT

DESCRIPTION:	Handler for SELECT button pressed on Window Icon.
		If this is a double-click, we want to open the GenPrimary
		associated with this icon. Otherwise, we just call the
		superclass (OLWinClass) so it can handle as usual.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinGlyphDisplayStartSelect	method dynamic	OLWinGlyphDisplayClass,
							MSG_META_START_SELECT

	test	bp, mask BI_DOUBLE_PRESS
	jz	notDoublePress

	push	si
	mov	si, ds:[di].OLWGDI_icon
	call	ObjCallInstanceNoLock
	pop	si
notDoublePress:

	;Bring this object to the front...

	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication

	push	si
	call	WinIcon_DerefVisSpec_DI
	mov	si, ds:[di].OLWGDI_icon
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	pop	si

	mov	ax, MSG_OL_WIN_GLYPH_BRING_TO_TOP
	GOTO	ObjCallInstanceNoLock

OLWinGlyphDisplayStartSelect	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayBringToTop -- MSG_OL_WIN_GLYPH_BRING_TO_TOP
		for OLWinGlyphDisplayClass

DESCRIPTION:	Bring windowed GlyphDisplay object to top of window layer.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - MSG_OL_WIN_GLYPH_BRING_TO_TOP
		cx, dx, bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/6/92		Initial version

------------------------------------------------------------------------------@
OLWinGlyphDisplayBringToTop	method	dynamic	OLWinGlyphDisplayClass, \
						MSG_OL_WIN_GLYPH_BRING_TO_TOP
	;if this window is not opened then abort: the user or application
	;caused the window to close before this method arrived via the queue.

	call	VisQueryWindow
	or	di, di
	jz	done			; Skip if window not opened...

	clr	ax
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority
done:
	ret
OLWinGlyphDisplayBringToTop	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayInitialize -- MSG_META_INITIALIZE
		for OLWinGlyphDisplayClass

DESCRIPTION:	Initialize a windowed GlyphDisplay object

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - MSG_META_INITIALIZE
		cx, dx, bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinGlyphDisplayInitialize	method dynamic OLWinGlyphDisplayClass, \
				MSG_META_INITIALIZE

	CallMod	VisCompInitialize

	;Initialize visible characteristics

	call	WinIcon_DerefVisSpec_DI
					;Mark this object as being a win group
					;Mark as being a win group & a window
	ORNF	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP or \
					mask VTF_IS_WINDOW
	;set this object NOT VISIBLE for now: will be set VISIBLE after is
	;positioned (do not use MSG_VIS_SET_ATTRS, because will cause
	;SPEC_BUILD on object.)

	ANDNF	ds:[di].VI_attrs, not (mask VA_VISIBLE)
	ret

OLWinGlyphDisplayInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplaySetMoniker --
		MSG_OL_WIN_GLYPH_DISP_SET_MONIKER for OLWinGlyphDisplayClass

DESCRIPTION:	Set the moniker for this OLWinGlyphDisplay object.

PASS:		*ds:si - instance data
		es - segment of OLWinGlyphDisplayClass
		ax - MSG_OL_WIN_GLYPH_DISP_SET_MONIKER
		*ds:dx - handle of visMoniker to use (is in same block)
		*ds:bp - icon object

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version

------------------------------------------------------------------------------@


OLWinGlyphDisplaySetMoniker	method dynamic OLWinGlyphDisplayClass, \
				MSG_OL_WIN_GLYPH_DISP_SET_MONIKER

	mov	ds:[di].OLWGDI_glyph, dx
	mov	ds:[di].OLWGDI_icon, bp

	;update geometry NOW, so that we have a size before we are positioned
	;(This does nothing if this window is not yet visible)

	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	ret
OLWinGlyphDisplaySetMoniker	endm

WinIconCode	ends

;-------------------------------

Geometry	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayRerecalcSize -- MSG_VIS_RECALC_SIZE
			for OLWinGlyphDisplayClass

DESCRIPTION:	Returns the size of the button.

PASS:
	*ds:si - instance data
	es - segment of OLWinGlyphDisplayClass
	ax - MSG_VIS_RECALC_SIZE
	cx - width info for choosing size
	dx - height info

RETURN:
	cx - width to use
	dx - height to use

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@


WIN_ICON_GLYPH_MARGIN_X		= 4
WIN_ICON_GLYPH_MARGIN_Y		= 4

OLWinGlyphDisplayRerecalcSize	method OLWinGlyphDisplayClass,
				MSG_VIS_RECALC_SIZE

	call	ViewCreateCalcGState	;create GState for geometry

	mov     di, ds:[si]
	add     di, ds:[di].Vis_offset		; ds:di = SpecInstance
	mov     di, ds:[di].OLWGDI_glyph	;*ds:di = VisMoniker
	segmov	es, ds				;*es:di = VisMoniker
					;pass bp = GState
	call	SpecGetMonikerSize	;returns cx, dx = size of moniker
	add	cx, WIN_ICON_GLYPH_MARGIN_X
	add	dx, WIN_ICON_GLYPH_MARGIN_Y
	mov	di, bp			;pass di = GState
	call	GrDestroyState		;nuke graphics state
	ret

OLWinGlyphDisplayRerecalcSize	endm
			
Geometry	ends

;---------------------------------------

WinIconCode	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayMove --
		MSG_OL_WIN_GLYPH_DISP_MOVE for OLWinGlyphDisplayClass

DESCRIPTION:	Reposition this glyph window underneath the specified point.

PASS:		*ds:si - instance data
		es - segment of OLWinGlyphDisplayClass
		ax - MSG_OL_WIN_GLYPH_DISP_MOVE
		cx, dx	- position on screen to center this object under

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@


WIN_ICON_GLYPH_Y_SPACING	= 3	;position the glyph 4 pixels below icon

OLWinGlyphDisplayMove	method dynamic OLWinGlyphDisplayClass, \
				MSG_OL_WIN_GLYPH_DISP_MOVE

	;calculate size of OLWinGlyphDisplay object

	mov	ax, cx				;set ax, bx = position
	mov	bx, dx

	call	VisGetSize			;returns cx, dx = size
	tst	cx
	jne	haveSize

	push	ax, bx
	call	OLWinGlyphDisplayRerecalcSize	;get size of moniker
	pop	ax, bx

haveSize:
	push	cx				;save width
	shr	cx, 1				;find offset to center
	sub	ax, cx				;move left by 1/2 width
	add	bx, WIN_ICON_GLYPH_Y_SPACING	;move down for spacing

	;position OLWinGlyphDisplay at (ax, bx)

	call	WinIcon_DerefVisSpec_DI
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_top, bx
	pop	cx				;get width
	add	ax, cx
	mov	ds:[di].VI_bounds.R_right, ax
	add	bx, dx
	mov	ds:[di].VI_bounds.R_bottom, bx

	;pass cx, dx = width and height of window (amount to keep visible)

	call	EnsureWindowInParentWin		;ensure that window is visible

	;mark window as invalid so will be moved

	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	ret

OLWinGlyphDisplayMove	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinGlyphDisplayOpenWin

DESCRIPTION:	Perform MSG_VIS_OPEN_WIN given an OLWinPart

CALLED BY:	VisOpen

PASS:
	*ds:si - instance data
RETURN:		
	cl - DrawFlags: DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

DESTROYED:
	ax, bx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Lifted from OLWinClass

------------------------------------------------------------------------------@


OLWinGlyphDisplayOpenWin	method dynamic OLWinGlyphDisplayClass, \
				MSG_VIS_OPEN_WIN

EC <	cmp	ds:[di].VCI_window, 0	; already have a window?	>
EC <	ERROR_NZ	OPEN_WIN_ON_OPEN_WINDOW				>

	push	si			; save chunk


	call	GeodeGetProcessHandle	; Get owner for window

if (0)	; Don't use Layer_ID_FOR_ICONS.  So icons for desk accessories can
	; stay on top. - Joon (7/18/94)

	mov	dx, LAYER_ID_FOR_ICONS	;Push layer ID for all windows
	push	dx
else		
	push	bx			; Push layer ID		
endif

	push	bx			; Push owner
	push	bp			; pass parent window handle

	;Save segment and offset of window region to use

	clr	ax			; default: use rectangular region
	push	ax			; save segment and offset of region
	push	ax

	;save visible bounds of window

	clr	cl			; normal bounds
	call	OpenGetLineBounds	; pass bounds, as screen coords
	push	dx
	push	cx
	push	bx
	push	ax

	;set up AH = window type flags, AL = window background color

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	push	es
	segmov	es, dgroup, ax
	mov	al, es:[moCS_dsLightColor]
	pop	es
endif		;END of OPEN LOOK specific code -------------------------------

if	_CUA_STYLE	;START of MOTIF specific code --------------------------
	;CUA/Motif: grab color value from color scheme variables in idata

;	push	ds
;	GetResourceSegment idata, ax		;get segment of core blk
;	mov	ds, ax
	mov	al, C_WHITE		;assume is not a menu
;	pop	ds
endif		;END of MOTIF specific code -----------------------------------

	mov	ah, mask CMM_ON_BLACK or CMT_CLOSEST

	mov	cx, ds:[LMBH_handle]	; pass obj descriptor of this object
	mov	dx, si 
					; Doing a shadow?
	call	WinIcon_DerefVisSpec_DI

	mov	di, cx			; pass enter/leave OD
	mov	bp, dx			; set up chunk of this object in bp

	mov	si, WIN_PRIO_STD+1	; no other flags, let win-system
					;	set layer priority to default
					; (set slightly lower than STD prio,
					;  see comment in winPriorityTable -
					;  brianc 3/17/93)

				; pass handle of video driver
	call	WinOpen

	pop	si
	call	WinIcon_DerefVisSpec_DI
	mov	ds:[di].VCI_window, bx	; store window handle

	;DO NOT place this object on the ActiveList
	ret

OLWinGlyphDisplayOpenWin	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinGlyphDisplayDraw -- MSG_VIS_DRAW for OLWinGlyphDisplayClass

PASS:
	*ds:si - instance data
	bp - handle of graphics state
RETURN:		
	cl - DrawFlags: DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinGlyphDisplayDraw	method dynamic OLWinGlyphDisplayClass, MSG_VIS_DRAW

	;
	; check if our icon is the focus at it's focus level
	;
	call	WinIcon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWGDI_icon
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLWI_focusExcl.FTVMC_flags, mask HGF_SYS_EXCL

	;draw black frame border

	mov	di, bp			; get gstate in di

	jz	notFocused

	pushf
	call	VisGetSize
	mov	ax, C_BLACK		; inverted --> black background
	call	GrSetAreaColor
	clr	ax
	clr	bx
	call	GrFillRect
	popf

notFocused:
	mov	ax, C_BLACK
	jz	haveColor
	mov	ax, C_WHITE		; inverted for focused
haveColor:
	call	GrSetAreaColor
	call	GrSetLineColor
	call	GrSetTextColor

	call	VisGetSize		;get size of actual window from instance
					;data of visual part
	dec	cx			;(ax, bx) - (cx, dx) = bounds
	dec	dx
	clr	ax
	clr	bx
	call	GrDrawRect		;draw frame outside resize border

	push	di			;save GState

	sub	sp, size DrawMonikerArgs
	mov	bp, sp			;ss:bp holds DrawMonikerArgs
	mov	ss:[bp].DMA_gState, di

	;draw moniker

	call	WinIcon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWGDI_glyph	;*ds:bx = VisMoniker
	segmov	es, ds				;*es:bx = VisMoniker
	mov	cl,    (J_CENTER shl offset DMF_X_JUST) \
		    or (J_CENTER shl offset DMF_Y_JUST)
					;draw at pen position, no just.

	mov	ss:[bp].DMA_xMaximum, dx
	mov	ss:[bp].DMA_yMaximum, MAX_COORD
	clr	ss:[bp].DMA_xInset
	clr	ss:[bp].DMA_yInset
	call	SpecDrawMoniker		;draw moniker onto our window
	add	sp, size DrawMonikerArgs
	pop	bp
	ret
OLWinGlyphDisplayDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinGlyphDisplayGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update task entry list

CALLED BY:	MSG_META_GAINED_SYS_TARGET_EXCL

PASS:		*ds:si	= OLWinGlyphDisplayClass object
		ds:di	= OLWinGlyphDisplayClass instance data
		es 	= segment of OLWinGlyphDisplayClass
		ax	= MSG_META_GAINED_SYS_TARGET_EXCL

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/29/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinGlyphDisplayGainedSysTargetExcl	method	dynamic	OLWinGlyphDisplayClass,
					MSG_META_GAINED_SYS_TARGET_EXCL

	mov	di, offset OLWinGlyphDisplayClass
	call	ObjCallSuperNoLock

	call	UpdateAppMenuItemCommon
	ret
OLWinGlyphDisplayGainedSysTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinGlyphDisplayTestWinInteractibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	respond that we are interactible

CALLED BY:	MSG_META_TEST_WIN_INTERACTIBILITY

PASS:		*ds:si	= OLWinGlyphDisplayClass object
		ds:di	= OLWinGlyphDisplayClass instance data
		es 	= segment of OLWinGlyphDisplayClass
		ax	= MSG_META_TEST_WIN_INTERACTIBILITY

		^lcx:dx	= InputOD of window to check
		^hbp	= Window to check

RETURN:		carry	= set if mouse allowed in window, clear if not.

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinGlyphDisplayTestWinInteractibility	method	dynamic	OLWinGlyphDisplayClass,
					MSG_META_TEST_WIN_INTERACTIBILITY
	tst_clc	cx
	jz	done			; no window, not allow
	cmp	cx, ds:[LMBH_handle]
	jne	notSelf
	cmp	dx, si
	stc				; assume is us
	je	done
notSelf:
	clc				; else, not allowed
done:
	ret
OLWinGlyphDisplayTestWinInteractibility	endm

WinIconCode ends

