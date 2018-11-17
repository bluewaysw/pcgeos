COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		openGlyphDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLGlyphDisplayClass	Open look glyph

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

DESCRIPTION:

	$Id: copenGlyphDisplay.asm,v 1.2 98/03/11 05:51:36 joon Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLGlyphDisplayClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
					;flags for this class

if NOTEBOOK_INTERACTION
	NotebookRingsClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
endif

	method	VupCreateGState, OLGlyphDisplayClass, MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends


;-------------------------

Build	segment	resource
	


COMMENT @----------------------------------------------------------------------

METHOD:		OLGlyphDisplaySpecBuild -- 
		MSG_SPEC_BUILD for OLGlyphDisplayClass

DESCRIPTION:	Visibly builds the glyph display.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/20/91		Initial version

------------------------------------------------------------------------------@

OLGlyphDisplaySpecBuild	method OLGlyphDisplayClass, MSG_SPEC_BUILD
	mov	di, offset OLGlyphDisplayClass
	call	ObjCallSuperNoLock
	call	OLGlyphDisplayScanGeometryHints
	;
	; Set a flag in the OLCtrl that we can't be overlapping objects.
	; -cbh 2/22/93
	;
	call	OpenCheckIfBW				;not B/W, don't sweat
	jnc	exit
	call	SpecSetFlagsOnAllCtrlParents		;sets CANT_OVERLAP_KIDS
exit:
	ret
			
OLGlyphDisplaySpecBuild	endm






COMMENT @----------------------------------------------------------------------

METHOD:		OLGlyphDisplayScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLGlyphDisplayClass

DESCRIPTION:	Scans for geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

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
	chris	2/ 4/92		Initial Version

------------------------------------------------------------------------------@

OLGlyphDisplayScanGeometryHints	method static OLGlyphDisplayClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS

	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLGlyphDisplayClass
	mov	es, di

	mov	di, ds:[si]			;must dereference for static
	add	di, ds:[di].Vis_offset		;   method!
	ORNF	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID or \
				     mask VGA_USE_VIS_CENTER or \
				     mask VGA_USE_VIS_SET_POSITION

	ANDNF	ds:[di].OLGDI_flags, not \
			(mask OLGDF_EXPAND_WIDTH_TO_FIT_PARENT or \
			 mask OLGDF_EXPAND_HEIGHT_TO_FIT_PARENT or \
			 mask OLGDF_CAN_CLIP_MONIKER_WIDTH or \
			 mask OLGDF_CAN_CLIP_MONIKER_HEIGHT)

	call	OpenSetupGadgetGeometryFlags		;cl <- flags
	or	ds:[di].OLGDI_flags, cl	
	.leave
	ret
OLGlyphDisplayScanGeometryHints	endm
	





COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenSetupGadgetGeometryFlags

SYNOPSIS:	Returns some geometry flags based on hints read.

CALLED BY:	OLGlyphDisplayScanGeometryHints
		OLButtonScanGeometryHints

PASS:		*ds:si -- object to search for hints
		ds:di -- VisInstance of specific object

RETURN:		cl -- OLGlyphDisplayFlags

DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/20/92		Initial version

------------------------------------------------------------------------------@

OpenSetupGadgetGeometryFlags	proc	near
	push	di
	mov	di, offset cs:OLGlyphHints
	mov	ax, length (cs:OLGlyphHints)
	mov	cx, cs
	mov	es, cx
	clr	cx				;assume no flags set
	call	OpenScanVarData			;stuff in new arguments

	;
	; Any of the expand/clip flags set, clear this flag so the object will
	; dynamically size.  (It's not necessary for center-moniker, but the
	; assumption is one of the other flags are set anyway.)
	;
	pop	di
	tst	cl				;none of these were set, branch
	jz	10$
	and	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
10$:	
	ret
OpenSetupGadgetGeometryFlags	endp


OLGlyphHints	VarDataHandler \
	<HINT_EXPAND_WIDTH_TO_FIT_PARENT, offset ExpandWidth>, 
	<HINT_EXPAND_HEIGHT_TO_FIT_PARENT, offset ExpandHeight>,
	<HINT_CAN_CLIP_MONIKER_WIDTH, offset ClipMonikerWidth>,
	<HINT_CAN_CLIP_MONIKER_HEIGHT, offset ClipMonikerHeight>,
	<HINT_CENTER_MONIKER, offset CenterMoniker>,
	<HINT_GLYPH_SEPARATOR, offset GlyphSeparator>

ExpandWidth	proc	far
	ORNF	cl, mask OLGDF_EXPAND_WIDTH_TO_FIT_PARENT
	ret
ExpandWidth	endp
		
ExpandHeight	proc	far
	ORNF	cl, mask OLGDF_EXPAND_HEIGHT_TO_FIT_PARENT
	ret
ExpandHeight	endp
		
ClipMonikerWidth	proc	far
	ORNF	cl, mask OLGDF_CAN_CLIP_MONIKER_WIDTH
	ret
ClipMonikerWidth	endp

ClipMonikerHeight	proc	far
	ORNF	cl, mask OLGDF_CAN_CLIP_MONIKER_HEIGHT
	ret
ClipMonikerHeight	endp

CenterMoniker	proc	far
	ORNF	cl, mask OLGDF_CENTER_MONIKER
	ret
CenterMoniker	endp

GlyphSeparator	proc	far
	ORNF	cl, mask OLGDF_SEPARATOR
	ret
GlyphSeparator	endp
		
Build	ends
	
	
Geometry segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLGlyphDisplaySpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLGlyphDisplayClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLGlyphDisplayClass

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
OLGlyphDisplaySpecVisOpenNotify	method dynamic	OLGlyphDisplayClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLGlyphDisplaySpecVisOpenNotify	endm

;---

OLGlyphDisplaySpecVisCloseNotify	method dynamic	OLGlyphDisplayClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLGlyphDisplaySpecVisCloseNotify	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLGlyphDisplayRecalcSize -- MSG_VIS_RECALC_SIZE
		for OLGlyphDisplayClass

DESCRIPTION:	Returns the size of the glyph.

PASS:
	*ds:si - instance data
	es - segment of OLGlyphDisplayClass
	di - MSG_VIS_RECALC_SIZE
	cx - width info for choosing size
	dx - height info

RETURN:
	cx - width to use
	dx - height to use

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:
	       
PSEUDO CODE/STRATEGY:
        apply size hints (to get initial hints)
	width, height = size of moniker;
	if (expand width to fit parent) and (width < passedWidth) and
	    not (passedWidth & RCS_CHOOSE_OWN_SIZE)
	    
		width = passedWidth
		
	if (expand height to fit parent) and (height < passedHeight) and
	    not (passedWidth & RCS_CHOOSE_OWN_SIZE)
	    
		height = passed height
		
	if (can clip moniker)
		if width > passedWidth
			width = passedWidth
		if height > passedHeight
			height = passedHeight
	apply size hints
	
	if (cannot clip moniker)
		if returnWidth < width
			returnWidth = width
		if returnHeight < height
			returnHeight = height
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLGlyphDisplayRecalcSize  method  OLGlyphDisplayClass, MSG_VIS_RECALC_SIZE
	CallMod	VisApplySizeHints		;apply any initial hints
	;
	; Get the moniker size, and assume we'll use that.
	;
	push	cx
	push	dx
	call	ViewCreateCalcGState		;Get gstate for calculation
if	ASSUME_BOLD_STYLE_FOR_MONIKERS
	mov	ax, mask TS_BOLD
	call	GrSetTextStyle
endif
	call	SpecGetGenMonikerSize		;calc moniker size
	call	GrDestroyState 			;destroy the graphics state
	pop	bx				;restore passed width/height
	pop	ax				;   in ax, bx

	; Make sure we have enough room for the separator

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLGDI_flags, mask OLGDF_SEPARATOR
	jz	afterSeparator

	test	ds:[di].OLGDI_flags, mask OLGDF_EXPAND_WIDTH_TO_FIT_PARENT
	jz	checkVertSep
	cmp	dx, 2				;need 2 pixels for separator
	jae	afterSeparator
	mov	dx, 2

checkVertSep:
	test	ds:[di].OLGDI_flags, mask OLGDF_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	afterSeparator
	cmp	cx, 2				;need 2 pixels for separator
	jae	afterSeparator
	mov	cx, 2

afterSeparator:
	;
	; Changed to pass bp high = 0 (not a system icon).  7/20/94 cbh
	;
	push	cx				
	clr	cx
	mov	cl, ds:[di].OLGDI_flags	
	mov	bp, cx
	pop	cx

	call	OpenChooseNewGadgetSize		;choose a gadget size
	CallMod	VisApplySizeHints		;apply any size hints
	ret

OLGlyphDisplayRecalcSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenChooseNewGadgetSize

SYNOPSIS:	Chooses a gadget size based on passed size, moniker size, and
		geometry attributes.

CALLED BY:	OLGlyphDisplayRerecalcSize
		OLButtonRerecalcSize
		OLItemRerecalcSize

PASS:		*ds:si -- object instance data
		ax, bx -- passed size
		cx, dx -- moniker size
		bp low -- OLGlyphDisplayFlags
		bp high-- non-zero if system icon

RETURN:		cx, dx -- size to use

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/20/92		Initial version

------------------------------------------------------------------------------@

OpenChooseNewGadgetSize	proc	near		uses	di
	.enter
	test	bp, mask OLGDF_EXPAND_WIDTH_TO_FIT_PARENT
	jz	10$
	cmp	ax, cx				;passed width smaller than
	jle	10$				;  moniker width, (or passed
						;  width negative) branch
	mov	cx, ax				;else use passed width
10$:
	test	bp, mask OLGDF_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	20$
	cmp	bx, dx				;passed height smaller than
	jle	20$				;  moniker height (or passed
						;  height negative), branch

	;
	; If we're in a toolbox, we'll limit the amount of height expansion
	; that we do.   7/18/94 cbh  (Not if we're a system icon.  7/20/94 cbh)
	; (And not if we explicitly have an expand-height hint.  7/25/94 cbh)
	;
	test	bp, 0ff00h			;bp high non-zero?
	jnz	15$				;yes, system icon, expand!

	test	bp, mask OLGDF_IN_TOOLBOX
	jz	15$				;not in toolbox, expand!

	push	bx
	sub	bx, dx				;get passed minus moniker size
	cmp	bx, dx				;asking to expand to twice its
						;   height?
	pop	bx
	jle	15$				;not expanding to twice size, OK

	push	ax, bx
	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	call	ObjVarFindData
	pop	ax, bx
	jnc	20$				;hint not explicit, don't
						;  expand height at all
15$:	
	mov	dx, bx				;else use passed height
20$:
	test	bp, mask OLGDF_CAN_CLIP_MONIKER_WIDTH
	jz	30$				;can't clip moniker, branch
	
	cmp	cx, ax				;moniker width <= passed width,
	jbe	30$				;   branch
	mov	cx, ax				;else use smaller passed width
30$:
	test	bp, mask OLGDF_CAN_CLIP_MONIKER_HEIGHT
	jz	40$				;can't clip moniker, branch
	
	cmp	dx, bx				;moniker height <= passed height
	jbe	40$				;   then branch
	mov	dx, bx				;else use smaller passed height
40$:
	.leave
	ret
OpenChooseNewGadgetSize	endp

				


COMMENT @----------------------------------------------------------------------

METHOD:		OLGlyphDisplayGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLGlyphDisplayClass

DESCRIPTION:	Returns extra size for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx, - extra size
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 7/91		Initial version

------------------------------------------------------------------------------@

OLGlyphDisplayGetExtraSize	method dynamic	OLGlyphDisplayClass, MSG_SPEC_GET_EXTRA_SIZE
	clr	cx
	clr	dx
	ret
OLGlyphDisplayGetExtraSize	endm

Geometry ends

;---------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLGlyphDisplayDraw -- MSG_VIS_DRAW for OLGlyphDisplayClass

DESCRIPTION:	Draw this object

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_DRAW
	cl - DrawFlags:  DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@


OLGlyphDisplayDraw	method	OLGlyphDisplayClass, MSG_VIS_DRAW
if (not GLYPH_USES_BACKGROUND_COLOR)
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	pushf					;we'll want to test this again
	;
	; In PCV, label might be on black group so clear background.
	;					-jmagasin 6/26/96
	;
	jnz	OLGDD_15			;enabled, skip background draw
endif ; (not GLYPH_USES_BACKGROUND_COLOR)

	;
	; Be sure to white out the area of the glyph, if it's disabled, so
	; that if it's going from enabled to disabled it redraws correctly.
	; (11/ 5/90 cbh)
	;
if GLYPH_USES_BACKGROUND_COLOR
	;
	; use glyph background color, or wash color (i.e. parent bg color)
	;
	mov	ax, 0				; use unselected color
	call	OpenGetBackgroundColor
	jc	haveColor			; found glyph bg color
	call	OpenGetWashColors		; else, use wash color
haveColor:
						; al = main color
else
	mov	di, es				;save es in di
	segmov	es, dgroup, ax			;es = dgroup
	mov	al, es:[moCS_dsLightColor]
	mov	es, di				;restore es from di
endif
	clr	ah
	mov	di, bp				;pass gstate
	call	GrSetAreaColor			;set as area color
	call	VisGetBounds			;get bounds
	call	GrFillRect			;clear the area

if GLYPH_USES_BACKGROUND_COLOR
	;
	; always do background draw for JEDI as these things could be in the
	; title bar and we need to clear the title bar line
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	pushf					;we'll want to test this again
	jnz	OLGDD_15			;enabled, skip background draw
endif

	
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	di, bp
	mov	al, SDM_50			;and draw in a 50% pattern
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask
endif
OLGDD_15:
	;
	; draw separator if needed
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLGDI_flags, mask OLGDF_SEPARATOR
	jz	afterSeparator

	call	OLGlyphDisplayDrawSeparator

afterSeparator:
	mov	di, bp				;gstate in di
if	_MOTIF or _ISUI or _OL_STYLE
	mov	ax, C_BLACK
endif
if USE_COLOR_FOR_DISABLED_GADGETS
	popf					; recover enabled flags
	pushf					; save it again
	jnz	5$
	mov	ax, DISABLED_COLOR
5$:
endif
	call	GrSetAreaColor
	call	GrSetLineColor
	call	GrSetTextColor

	call	VisGetSize			; get visual object size
	mov	ax, cx				; width in ax

	clr	cl				; no moniker flags
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLGDI_flags, mask OLGDF_CAN_CLIP_MONIKER_WIDTH or \
				     mask OLGDF_CAN_CLIP_MONIKER_HEIGHT
	jz	10$				;not clipping moniker, branch
	or	cl, mask DMF_CLIP_TO_MAX_WIDTH
10$:
	test	ds:[di].OLGDI_flags, mask OLGDF_CENTER_MONIKER
	jz	20$
	or	cl, (J_CENTER shl offset DMF_X_JUST) or \
		    (J_CENTER shl offset DMF_Y_JUST)
20$:
	mov	di, bp				; gstate in di 
	push	bp
	mov	bx, si				; bx is gen chunk
	sub	sp, size DrawMonikerArgs	; make room for args
	mov	bp, sp				; pass pointer in bp
	mov	ss:[bp].DMA_gState, di		; pass gstate
	mov	ss:[bp].DMA_xMaximum, ax	; pass maximum size
	mov	ss:[bp].DMA_yMaximum, dx
	clr	ss:[bp].DMA_xInset		; no x inset
	clr	ss:[bp].DMA_yInset		; no y inset
	segmov	es, ds
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset		; ds:bx = GenInstance
	mov	bx, ds:[bx].GI_visMoniker	;*ds:bx = visMoniker
	call	SpecDrawMoniker
	add	sp, size DrawMonikerArgs	;dump args
	pop	bp
	popf
	jnz	exit				; if was fully enabled, don't

	mov	di, bp
if USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, MM_OR
	call	GrSetMixMode
	mov	ax, DISABLED_COLOR
	call	GrSetAreaColor			;set as area color
	call	VisGetBounds			;get bounds
	call	GrFillRect			;clear the area
	mov	al, MM_COPY
	call	GrSetMixMode
else
						; need to restore masks
	mov	al, SDM_100
	call	GrSetAreaMask			; make sure this is restored
	call	GrSetLineMask
	call	GrSetTextMask
endif
exit:
	ret

OLGlyphDisplayDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLGlyphDisplayDrawSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw separator

CALLED BY:	OLGlyphDisplayDraw
PASS:		*ds:si	= OLGlyphDisplayClass object
		ds:di	= OLGlyphDisplayClass instance data
		bp	= gstate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon   	1/03/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLGlyphDisplayDrawSeparator	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	VisGetBounds

	mov	si, offset drawHorizontal
	test	ds:[di].OLGDI_flags, mask OLGDF_EXPAND_WIDTH_TO_FIT_PARENT
	jnz	drawSeparator
	mov	si, offset drawVertical
	test	ds:[di].OLGDI_flags, mask OLGDF_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	done

drawSeparator:
	mov	di, bp
	mov	bp, C_BLACK
	call	drawLine
	mov	bp, C_WHITE
	call	drawLine
done:
	.leave
	ret

drawLine:
	xchg	ax, bp
	call	GrSetLineColor
	xchg	ax, bp
	call	si
	retn

drawHorizontal:
	call	GrDrawHLine
	inc	bx
	retn

drawVertical:
	call	GrDrawVLine
	inc	ax
	retn

OLGlyphDisplayDrawSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLGlyphDisplayGetActivatorBounds -- 
		MSG_META_GET_ACTIVATOR_BOUNDS for OLGlyphDisplayClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Gets bounds of activator.

PASS:		*ds:si 	- instance data
		es     	- segment of OLGlyphDisplayClass
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

OLGlyphDisplayGetActivatorBounds	method dynamic	OLGlyphDisplayClass, \
				MSG_META_GET_ACTIVATOR_BOUNDS
	.enter
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		;BP <- GState handle

	call	VisGetBounds	;AX <- left edge of the object

	; Have the arrow draw to the *right* edge

	mov_tr	ax, cx

	sub	dx, bx
	shr	dx, 1
	add	bx, dx		;BX <- middle of the object (vertically)

	mov	di, bp		;DI <- GState handle
	
	; Check if point is in window bounds.  If not, return carry clear.
	call	CheckIfPointInWinBounds
	jnc	done
	
	call	GrTransform	;Transform AX,BX to screen coords
	call	GrDestroyState
	mov	cx, ax		;AX,CX <- left or right edge of obj
	mov	bp, bx		;BP,DX <- middle of obj vertically
	mov	dx, bx
	stc

done:
	.leave
	ret
OLGlyphDisplayGetActivatorBounds	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookRingsRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get size of notebook rings

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= NotebookRingsClass object
		ds:di	= NotebookRingsClass instance data
		ds:bx	= NotebookRingsClass object (same as *ds:si)
		es 	= segment of NotebookRingsClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width to use
		dx	= height to use
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookRingsRecalcSize	method dynamic NotebookRingsClass, 
					MSG_VIS_RECALC_SIZE
	mov	bx, handle NotebookRingsMoniker
	call	MemLock
	mov	ds, ax
	mov	si, offset NotebookRingsMoniker
	mov	si, ds:[si]
	mov	cx, ds:[si].B_width
	test	dx, mask RSA_CHOOSE_OWN_SIZE
	jz	gotHeight
	mov	dx, ds:[si].B_height
gotHeight:
	GOTO	MemUnlock

NotebookRingsRecalcSize	endm

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookRingsDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the notebook rings rings

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= NotebookRingsClass object
		ds:di	= NotebookRingsClass instance data
		ds:bx	= NotebookRingsClass object (same as *ds:si)
		es 	= segment of NotebookRingsClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState to draw through.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookRingsDraw	method dynamic NotebookRingsClass, 
					MSG_VIS_DRAW
	mov	di, bp
	call	GrSaveState

	; Set clip area to draw only within the bounds of the NotebookRings

	call	VisGetBounds
	mov	si, PCT_INTERSECTION
	call	GrSetClipRect

	; Lock down NoteBookRingsMoniker (bitmap)

	push	ax, bx
	mov	bx, handle NotebookRingsMoniker
	call	MemLock
	mov	ds, ax
	mov	si, offset NotebookRingsMoniker
	mov	si, ds:[si]	
	pop	ax, bx

	; Center bitmap vertically within the NotebookRings object

	sub	cx, ax			; cx = width of notebook rings
	sub	cx, ds:[si].B_width	; cx = ringsWidth - bitmapWidth
	sar	cx, 1			; cx = (ringsWidth-bitmapWidth) / 2
	add	ax, cx			; ax = x draw position

	sub	dx, bx			; dx = height of notebook rings
	sub	dx, ds:[si].B_height	; dx = ringsHeight - bitmapHeight
	sar	dx, 1			; dx = (ringsHeight-bitmapHeight) / 2
	add	bx, dx			; bx = y draw position

	; Now draw the bitmap

	clr	dx
	call	GrDrawBitmap

	; Unlock and restore

	mov	bx, handle NotebookRingsMoniker
	call	MemUnlock

	GOTO	GrRestoreState

NotebookRingsDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookRingsVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set menu center point

CALLED BY:	MSG_VIS_OPEN, MSG_VIS_CLOSE
PASS:		*ds:si	= NotebookRingsClass object
		ds:di	= NotebookRingsClass instance data
		ds:bx	= NotebookRingsClass object (same as *ds:si)
		es 	= segment of NotebookRingsClass
		ax	= message #
		MSG_VIS_OPEN:
			bp	= 0 if top window, else window for
					object to open on
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if MENU_BAR_IS_A_MENU

NotebookRingsVisOpenClose	method dynamic NotebookRingsClass, 
					MSG_VIS_OPEN,
					MSG_VIS_CLOSE
	;
	; tell menued win about us
	;
	clr	cx
	cmp	ax, MSG_VIS_CLOSE
	je	haveMenuCenter
	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left
	shr	cx, 1
	add	cx, ds:[di].VI_bounds.R_left
haveMenuCenter:
	push	ax, bp
	push	si
	mov	bx, segment OLMenuedWinClass
	mov	si, offset OLMenuedWinClass
	mov	ax, MSG_OL_MENUED_WIN_SET_MENU_CENTER
	mov	di, mask MF_RECORD
	call	ObjMessage				; di = event
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	;
	; let superclass do its thing
	;
	pop	ax, bp
	mov	di, offset NotebookRingsClass
	call	ObjCallSuperNoLock
	ret
NotebookRingsVisOpenClose	endm

endif

endif	; NOTEBOOK_INTERACTION

CommonFunctional ends
