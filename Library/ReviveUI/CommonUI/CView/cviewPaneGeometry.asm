COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1988-1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		SpecUI/CommonUI/CView
FILE:		cviewPaneGeometry.asm

ROUTINES:
	Name			Description
	----			-----------
 ?? INT GetPaneMargins		Returns margins for the pane.  Assumes
				there are no margins if we're not drawing a
				moniker.  Also assumes this is a vertical
				composite, currently a good assumption for
				both pane and pane.

 ?? INT LookupOpenSize		Looks for various size hints & converts
				them to pixels.

 ?? INT MoveArea		Moves one of the area objects.

 ?? INT MoveArea		Moves one of the area objects.

 ?? INT TestHolisticness	Tests to see whether an Area object is to
				be holistically placed or not.

 ?? INT MoveHolisticArea	Moves an area to the specified position,
				adjusting for holistic scrollbar
				management.

 ?? INT GetWinLeftTop		Gets left and top edge for window.

 ?? INT GetFrameWidth		Gets the width of a pane window frame.

 ?? INT CalcSizeOfPaneChildren	Given the size of a pane, does the children
				for a final solution.  Clears invalid
				geometry bits for children.

 ?? INT ChooseInitialWinSize	Chooses a good initial window size to use
				for geometry calcs.

 ?? INT TurnBarsOnOffIfNeeded	Turns scrollbars off if we're not
				scrollable, and the appropriate flag is set
				for this kind of behavior.

 ?? INT SetVisAttrs		Set attributes & mark invalid.

 ?? INT SubtractFrameFromSize	Subtracts frame from size.

 ?? INT SizeArea		Sizes an area, based on current window
				size.

 ?? INT MakeSpecificObject	Resets si to specific visual object.

 ?? INT ResizeFloaterWindow	Resize the dialog.

 ?? INT CalcWinSize		Calculates the window size, based on total
				size and various area sizes.

 ?? INT KeepBiggerThanAreaMins	Keeps the dimension passed big enough for
				area minimums. For instance, if cx is
				horizontal, it must be at least as big as
				the width of the top scrollbar and the
				width of the bottom scrollbar.

 ?? INT CalcTotalSize		Calculates the total size, based on window
				size and various area sizes.

 ?? INT GetAreaDimension	Returns a dimension for this area.

 ?? INT GetAreaDimension	Returns a dimension for this area.

 ?? INT GetSpecAndEnsureManaged	Gets specific visual object and ensures the
				thing is managed.

 ?? INT GetAreaAndMargin	Returns a dimension for this area, and
				margin as well, if applicable.

 ?? INT AddMarginToAx		Adds a margin to value in ax.  The margin
				is the typical spacing between view and
				scrollbar gadgets.

 ?? INT SizeViewWindow		Keep track of view window size.

 ?? INT CheckAspectRatio	Deals with aspect ratio stuff.

 ?? INT OLPaneCalcContentSize	Sends size to output if not scrollable in a
				direction.

 ?? INT CheckPaneMinMax		Make sure pane is staying within set
				minimums and maximums. (Or simple pane.)

 ?? INT MultByScaleFactor	Multiplies by scale factor to get screen
				dimensions.

 ?? INT RoundToIncrement	Rounds the size passed to the increment
				passed.  Actually, it just truncates.

    MTD MSG_VIS_INVALIDATE	Does invalidation of any drawn-in areas.

 ?? INT PositionFloaterWindow	Put the floater window in the correct
				position.

 ?? INT GetFloaterPosition	Return the position wrt the view's window.

 ?? INT GetRealViewBounds	Get the bounds of the view's "pane window"
				in screen coords.

 ?? INT GetFloaterPositionLow	Return the window position.

 ?? none OLPaneSetNewPageSize	Sets the page size for the scrollbars.

 ?? none OLPaneGetDocWinSize	Returns the size of the pane window, in its
				coordinate system.

 ?? INT ConvertScreenToDocCoords
				Converts screen coords to document coords,
				just using the scale as a multiplier.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/91		Started V2.0
	Joon	8/92		PM extensions

DESCRIPTION:

	This file implements pane geometry stuff.

	$Id: cviewPaneGeometry.asm,v 1.64 97/01/06 23:13:43 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
ViewGeometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneRecalcSize --
		MSG_VIS_RECALC_SIZE for OLPaneClass

DESCRIPTION:	Handles geometry manager calls.   Does pane stuff to calculate
		a base size, then does pane stuff to do the children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx	- RecalcSizeArgs: geometry args

RETURN:		cx, dx -- size
		ax, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/24/89		Initial version

------------------------------------------------------------------------------@

OLPaneRecalcSize	method OLPaneClass, MSG_VIS_RECALC_SIZE

	CallMod	SubtractReservedMonikerSpace	;make the thing narrower, if we
						;  need to make room for
						;  sibling monikers (copenCtrl)
	;
	; Subtract off margins in case we're using a moniker, before 
	; calculating the sizes of the children.  The checks for negative
	; results
	;
	push	cx, dx				;save size
	call	GetPaneMargins			;margins in ax, bp, cx, dx
	add	ax, cx
	add	bp, dx				;add them, result in ax, bp
	pop	cx, dx				;restore size in cx, dx
	push	ax, bp				;save margins

	tst	cx				;if passed a width, subtract
	js	doneWidthMargin			;  margin
	sub	cx, ax
	jns	doneWidthMargin			;result negative, reset to zero
	clr	cx
doneWidthMargin:

	tst	dx				;if passed a height, subtract
	js	doneHeightMargin		;  margin
	sub	dx, bp
	jns	doneHeightMargin		;result negative, reset to zero
	clr	dx
doneHeightMargin:

	call	CalcSizeOfPaneChildren		;size the children

	;
	; With the children returning their size, add margins back in.
	;
	pop	ax				;restore height margins
	add	dx, ax				;add back into height
	pop	ax				;restore width margins
	add	cx, ax				;add back into width

	;
	; Make sure keeping up with our minimums, if such things exist.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	jz	exit
	push	cx, dx
	mov	ax, MSG_VIS_COMP_GET_MINIMUM_SIZE
	call	ObjCallInstanceNoLock
	pop	ax, bx
	cmp	cx, ax
	jae	30$
	mov	cx, ax
30$:
	cmp	dx, bx
	jae	exit
	mov	dx, bx
exit:
	ret
OLPaneRecalcSize	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetPaneMargins

SYNOPSIS:	Returns margins for the pane.   Assumes there are no margins
		if we're not drawing a moniker.  Also assumes this is a
		vertical composite, currently a good assumption for both pane
		and pane.

CALLED BY:	OLPaneRecalcSize

PASS:		*ds:si -- handle of pane/pane

RETURN:		ax, bp, cx, dx -- left/right/top/bottom margins

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 2/89		Initial version

------------------------------------------------------------------------------@
GetPaneMargins	proc	near
	class	OLPaneClass
	
	clr	cx, dx				;assume no margins

if	_CUA or _MAC
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	jz	exit				;not doing monikers, exit
endif
	mov	ax, MSG_VIS_COMP_GET_MARGINS	
	call	ObjCallInstanceNoLock
exit:
	ret
GetPaneMargins	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LookupOpenSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for various size hints & converts them to pixels.

CALLED BY:	ChooseInitialWinSize, CheckAspectRatio

PASS:		*ds:si -- object to check

RETURN:		ax -- open width (or zero if not present)
		bx -- open height (or zero if not present)
		zero flag set if one or both are zero (i.e. not present)		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LookupOpenSize	proc	far
	class	VisClass

	desiredSize	local	SpecSizeArgs

	.enter

	call	VisSetupSizeArgs
	mov	ax, desiredSize.SSA_initWidth
	mov	bx, desiredSize.SSA_initHeight
	tst	ax
	jz	exit
	tst	bx
exit:
	.leave
	ret
LookupOpenSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPanePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Positions the pane's children.

CALLED BY:	MSG_VIS_POSITION_BRANCH

PASS:		*ds:si 	- instance data		
		cx	= left edge
		dx	= top edge

RETURN:		nothing
		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/30/90		Initial version
	Chris	11/14/92	Changed to calculate origin right and bottom 
				areas by adding winSize to winLeftTop, rather
				than subtracting from the view's overall bounds.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLPanePosition	method OLPaneClass, MSG_VIS_POSITION_BRANCH

	call	VisSetPosition				  ; move itself
	movdw	axbx, cxdx

	;
	;  Now position the top, left, right, and bottom guys if there are
	;  any.
	;
	call	GetWinLeftTop			;cx, dx <- winLeft, winTop
	push	cx, dx				;save 'em

if _RUDY
	;
	; Objects that are direct children of a bubble (list objects)
	; need to supply their own outside margins.  After setting
	; our position, we'll pretend the parent supplied margins for us.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_USE_LARGE_FONT
	jz	notIndented
	add	ax, BUBBLE_LEFT_EXTRA_MARGIN + RUDY_POPUP_CTRL_LEFT_MARGIN
notIndented:	
	;
	; also leave room for draw in box
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	noBorder
	add	ax, RUDY_TOTAL_FRAME_THICKNESS
noBorder:
endif ; _RUDY

	xchg	bx, dx				;bx <- winTop, dx <- viewTop
	mov	di, offset OLPI_topObj		;pass top object
	call	MoveArea			;move it there
	
	mov	dx, bx				;dx <- winTop
	xchg	ax, cx				;cx <- viewLeft ax <- winLeft
	mov	di, offset OLPI_leftObj
	call	MoveArea
	mov	cx, ax				;cx <- winLeft

	;	
	; Calculate origins for right and bottom stuff by adding the view
	; size, frame, and margin to the left and top already calculated.
	;
	push	cx, dx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	dx, ds:[di].OLPI_winHeight	;get win height
	pop	ax				;add win top
	add	dx, ax
	mov	cx, ds:[di].OLPI_winWidth	;get win width
	pop	ax
	add	cx, ax				;add 'em
	call	GetFrameWidth			;frame width in ax
	shl	ax, 1				;double for top/bottom lines
	call	AddMarginToAx			;and margin to use
	add	cx, ax				;add them to get right, bottom
	add	dx, ax
	movdw	bxax, dxcx
	pop	cx, dx

	;
	; cx holds winLeft, dx holds winTop, ax holds viewRight, bx holds
	; viewBottom.  
	;
	xchg	ax, cx				;  viewRight, pass in cx
						;(winLeft now in ax)
	mov	di, offset OLPI_rightObj
	call	MoveArea
	
	mov	cx, ax				;winLeft in cx
	mov	dx, bx				;viewBottom in dx
	mov	di, offset OLPI_bottomObj
	call	MoveArea

	;	
	; If the UI directly resizes the content, we'll need to position it.
	; Nothing will happen there since the geometry was validated by the
	; calc new sizes sent to it.
	;
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Gen_offset		; ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY
	jz	30$				; not directly resizing, branch

	clr	cx, dx				; contents always at origin
	mov	ax, MSG_VIS_POSITION_BRANCH	; position the children
	call	OLPaneCallApp
30$:

if _RUDY or _ODIE
	;
	; should this be for all platforms?
	;
	call	OpenCtrlCalcMonikerOffsets	;recalc moniker offsets here,
						;   based on positioning.
endif
	ret
OLPanePosition	endm
		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves one of the area objects.

CALLED BY:	OLPanePosition

PASS:		*ds:si -- view
		di     -- offset in SpecInstance to area object to move
		cx, dx -- left, top to move to

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveArea	proc	near


if HOLISTIC_SCROLLBAR_POSITIONING
	push	ax
endif
	push	si
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset

if HOLISTIC_SCROLLBAR_POSITIONING
	pop	bp				; *ds:bp = View
	push	bp
	call	TestHolisticness
	lahf
	push	di
endif ; HOLISTIC_SCROLLBAR_POSITIONING

	add	si, di
	mov	si, ds:[si]			;point to object
	call	GetSpecAndEnsureManaged		;get visual object

if HOLISTIC_SCROLLBAR_POSITIONING
	pop	di
	jnc	exit				;not managed, exit
	sahf
	jz	setPos
	call	MoveHolisticArea
setPos:
else
	jnc	exit				;not managed, exit
endif ; HOLISTIC_SCROLLBAR_POSITIONING

	call	VisSendPositionAndInvalIfNeeded	;else move, even if not managed,
						;  who really cares anyway?
exit:
	pop	si

if HOLISTIC_SCROLLBAR_POSITIONING
	pop	ax
endif
	ret
MoveArea	endp

if HOLISTIC_SCROLLBAR_POSITIONING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestHolisticness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests to see whether an Area object is to be
		holistically placed or not.

CALLED BY:	MoveArea, GetAreaDimension
PASS:		di	= offset of area variable to test
		*ds:bp	= instance data of OLPane.
		ds:si	= instance data of OLPane
RETURN:		zero flag set (jz) if not holistic
		ds:si	= updated to point to instance data

DESTROYED:	nothing
SIDE EFFECTS:	If holisticFlags not set, will set them.

		Could move Object blocks

PSEUDO CODE/STRATEGY:
	
	 Test the holistic-ness of the Area in question.  The Nth
	 bit in holisticFlags corrsponds to the Nth Area object.

	 It turns out we have to do the initial vup query here 
	 to find out which scrollbars are holistically positioned,
	 if it hasn't been done already.  I'd like to do it in the
	 SPEC_BUILD handler, but that happens before the View has
	 been put into a popup for scrolling lists, querying up the
	 wrong Vis tree.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CheckHack <(offset OLPI_leftObj - offset OLPI_leftObj)/2 eq offset HSF_LEFT>
CheckHack <(offset OLPI_rightObj - offset OLPI_leftObj)/2 eq offset HSF_RIGHT>
CheckHack <(offset OLPI_topObj - offset OLPI_leftObj)/2 eq offset HSF_TOP>
CheckHack <(offset OLPI_bottomObj - offset OLPI_leftObj)/2 eq offset HSF_BOTTOM>

TestHolisticness	proc	near
	uses	ax,cx,dx,bp
	.enter

	test	ds:[si].OLPI_holisticFlags, mask HSF_HAS_QUERIED_FOR_FLAGS
	jnz	continue

	;
	; If we've never asked to find out who will position our
	; scrollbars, do so now.
	;
	push	di				; save instance offset
	mov	si, bp				; *ds:si = View
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_SCROLLBAR_POSITION
	mov	bp, mask SPQF_IS_MANAGED_BY_VIEW
	call	ObjCallInstanceNoLock		; carry if answered

	pushf
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si = instance data
	andnf	bp, SPQF_POSITION
	popf
	jc	setFlags
	clr	bp				; nothing is holistic
setFlags:	
	ornf	bp, mask HSF_HAS_QUERIED_FOR_FLAGS
	mov	ds:[si].OLPI_holisticFlags, bp
	pop	di				; restore instance offset
continue:

	mov	cx, di
	sub	cx, offset OLPI_leftObj		; cx = 0, 2, 4, 6
	shr	cx, 1				; cx = 0, 1, 2, 3
	mov	dx, 1				
	shl	dx, cl				; dx = 0, 2, 4, 8  (hmmm)
	test	ds:[si].OLPI_holisticFlags, dx

	.leave
	ret
TestHolisticness	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveHolisticArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves an area to the specified position, adjusting
		for holistic scrollbar management.

CALLED BY:	MoveArea
PASS:		*ds:si	= Area object to move (guaranteed to exist)
		di	= offset in SpecInstance to area object to move
		cx,dx	= Coordinates the View would like us to move to.
RETURN:		cx,dx	= Coordinates we should actually move to.
DESTROYED:	nothing
SIDE EFFECTS:	

		This may move LMem blocks, invalidating pointers to
		them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MoveHolisticArea	proc	near
	class	OLPaneClass
	uses	ax,bx,bp,si,di
	.enter

	push	cx, dx

	;
	; Find out where the UI wants our scrollbars to be, given
	; the side of the view it is supposed to appear on.
	;
	mov	ax, MSG_VIS_VUP_QUERY

	mov	cx, di
	sub	cx, offset OLPI_leftObj		; cx = 0, 2, 4, 6
	shr	cx, 1				; cx = 0, 1, 2, 3
	mov	bp, 1				
	shl	bp, cl			; bp = ScrollbarPositionQueryFlags

	mov	cx, SVQT_SCROLLBAR_POSITION
	call	ObjCallInstanceNoLock		; carry if answered
	mov	ax, cx				; ax,bx <- guideline
	mov	bx, dx				; bp <- position flags
	pop	cx,dx				; get original position
	jnc	done

	;
	; Position X coordinate
	;
	push	cx,dx
	call	VisGetSize			; cx,dx <- size
	pop	si,di				; si,di <- position
	test	bp, mask SPQF_LEFT_JUSTIFY
	jz	maybeRight
	mov	cx, ax				; use X guideline
	jmp	maybeTop
maybeRight:
	test	bp, mask SPQF_RIGHT_JUSTIFY
	jz	normalX
	sub	ax, cx				; use Xguide-Xsize
	mov	cx, ax
	jmp	maybeTop
normalX:
	mov	cx, si				; use original X position
maybeTop:
	test	bp, mask SPQF_TOP_JUSTIFY
	jz	maybeBottom
	mov	dx, bx				; use Y guideline
	jmp	done
maybeBottom:
	test	bp, mask SPQF_BOTTOM_JUSTIFY
	jz	normalY
	sub	bx, dx				; use Yguide-Ysize
	mov	dx, bx
	jmp	done
normalY:
	mov	dx, di				; use original Y position
done:
	.leave
	ret
MoveHolisticArea	endp

endif ; HOLISTIC_SCROLLBAR_POSITIONING


		

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetWinLeftTop

SYNOPSIS:	Gets left and top edge for window.

CALLED BY:	OLPanePosition, GetFrameBounds

PASS:		*ds:si -- view

RETURN:		cx, dx -- window left, top

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@
GetWinLeftTop	proc	far
	uses	ax, bx
	.enter

	call	VisGetBoundsInsideMargins	; get left, top this way
	movdw	cxdx, axbx			; put in cx, dx

	mov	ax, offset OLPI_topObj		; get height of top object
	mov	bl, CSPC_VERTICAL
	call	GetAreaAndMargin	 	; ax <- height + margin
	add	dx, ax				; add to top
	mov	ax, offset OLPI_leftObj		; get width of left object

	clr	bl
	call	GetAreaAndMargin		; ax <- height + margin
	add	cx, ax				; add to left

	.leave
	ret
GetWinLeftTop	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFrameWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width of a pane window frame.

CALLED BY:	UTILITY

PASS:		*ds:si -- pane handle

RETURN:		ax -- width of frame

DESTROYED:	di

PSEUDO CODE/STRATEGY:
       		if NO_FRAME
			frame = 0
		elif content run by same thread
			frame = 2
		else
			frame = 1


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFrameWidth	proc	far
	class	OLPaneClass

if DRAW_STYLES	;==============================================================

	push	bx
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	haveTextFlag			; don't access vardata if none
	mov	ax, ds:[bx]			; *ds:ax = text object
haveTextFlag:
	pushf
	push	ax				; save text object

	clr	ax				; assume no frame
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Gen_offset		; ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jnz	noFrame
	inc	ax
noFrame:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLPI_drawStyle, DS_FLAT
	je	done
	add	ax, DRAW_STYLE_INSET_WIDTH
done:
	;
	; if view is for scrolling text object, add gutter since we want
	; margins around the view port, not the bounds of the text object
	; (which is what margins on the text object will give)
	;
	pop	bx				; *ds:bx = text object
	popf
	jnc	notText
	inc	ax
	;
	; if text object is focusable display, add room for focus indicator
	;
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	jnz	notText
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	notText
if (TEXT_DISPLAY_FOCUS_WIDTH eq 1)
	inc	ax
else
	add	ax, TEXT_DISPLAY_FOCUS_WIDTH
endif
notText:
	pop	bx
	ret
	
else ;=========================================================================

if _CUA_STYLE or _OL_STYLE	;-------------------------------------------------------------
	clr	ax				;assume no frame
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jnz	exit				;no win frame, exit

if _JEDIMOTIF
	push	bx
	mov	ax, ATTR_OL_PANE_DOUBLE_BORDER
	call	ObjVarFindData
	pop	bx
	mov	ax, 1
	jnc	singleBorder
	inc	ax				;double border
singleBorder:
else
      	mov	ax, 1				;always one pixel border
endif
exit:
	ret
endif	; _CUA_STYLE ----------------------------------------------------------

endif ; DRAW_STYLES ===========================================================

GetFrameWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfScrollingTextEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this is a view for a scrolling text edit

CALLED BY:	EXTERNAL
PASS:		*ds:si = OLPane
RETURN:		carry set if view for scrolling text edit
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This'll be used to fix the extra l/r gutter needed to
		make the I-beam text cursor appear correct at the l/r
		edges of a scrolling text edit.  It should be used to
		decrease the l/r frame width of the view to remove the
		view gutter.  The gutter is provided by the text
		object via its VTI_lrMargin.  This allows the cursor to
		draw correctly.  Call it just after calling GetFrameWidth
		to determine whether an frame width adjustment is necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if I_BEAM_TEXT_CURSOR and 0
CheckIfScrollingTextEdit	proc	near
	uses	ax, bx
	.enter
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	done				; not text, carry clear
	mov	bx, ds:[bx]			; *ds:bx = text
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	jz	done				; not editable, carry clear
	stc					; indicate scrolling text edit
done:
	.leave
	ret
CheckIfScrollingTextEdit	endp
endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcSizeOfPaneChildren

SYNOPSIS:	Given the size of a pane, does the children for a final
		solution.  Clears invalid geometry bits for children.

CALLED BY:	OLPaneRecalcSize

PASS:		*ds:si -- handle of pane
		cx, dx -- desired size args

RETURN:		cx, dx -- size to use

DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:
       	initialize total size to cx, dx
	get previously stored win size, (or initial size hint if total size
		is RSA_CHOOSE_OWN_SIZE)
	repeat
		for each area
			calculate size based on current window size
		calculate new window size based on total size, leaving room
			for each area and keeping large enough to fill in the
			available space (minimums will be limited to area's
			minimums)
		make various adjustments on window size (content geometry,
			subclassed calc-win-size, aspect ratio, mins/maxes, 
			etc.)
		calculate a final total size based on window size.
	until window size stops changing (maybe never?)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/24/89		Initial version

------------------------------------------------------------------------------@
CSPC_VERTICAL	=	2
       
CalcSizeOfPaneChildren	proc	near
	class	OLPaneClass
	
	totalHeight	local	sword	;total size
	totalWidth	local	sword
	winHeight	local	sword	;win size, including frame
	winWidth 	local	sword	;leave in this order!
	
       CheckHack <CSPC_VERTICAL eq (offset winHeight - offset winWidth)>
       CheckHack <CSPC_VERTICAL eq (offset totalHeight - offset totalWidth)>
       CheckHack <CSPC_VERTICAL eq (offset OLPI_topObj-offset OLPI_leftObj)>
       CheckHack <CSPC_VERTICAL eq (offset OLPI_bottomObj-offset OLPI_rightObj)>
       
	.enter
	mov	totalHeight, dx			;init totals to what is pased.
	mov	totalWidth, cx

	call	ChooseInitialWinSize		;choose a starting winSize
	clr	ax				;say we're doing a first pass
geoLoop:
	;
	; The standard loop for calculating things. Register usage is al =
	; loop count, ah is non-zero for
	; if we've tried to expand the window to match the area mins before.
	;
	push	ax							
	;
	; Get sizes of each area around the view window, based on the current
	; size of the view window.
	;
	mov	ax, offset OLPI_leftObj		;do left area
	mov	bl, CSPC_VERTICAL
	call	SizeArea			
	
	mov	ax, offset OLPI_topObj		;do top area
	clr	bl
	call	SizeArea			
	
	mov	ax, offset OLPI_rightObj	;do right area
	mov	bl, CSPC_VERTICAL
	call	SizeArea			
	
	mov	ax, offset OLPI_bottomObj	;do bottom area
	clr	bl
	call	SizeArea			
	
	;
	; Calculate the proposed size of the window, subtracting various
	; area dimensions from the total size.  We will not be keeping the
	; window bigger than the widths of the areas until the second pass.
	;
	clr	bl
	call	CalcWinSize			;calc size of window 
	mov	bl, CSPC_VERTICAL		;   based on total size and
	call	CalcWinSize			;   size of each area
	
	;
	; Now do various adjustments on the window size.
	; cx, dx hold suggested size of window.
	;
	call	SubtractFrameFromSize		;remove frame width
	push	bp				;save frame pointer
	call	CheckAspectRatio		;deal with aspect ratio stuff
	
	test	ds:[di].GVI_attrs, mask GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY
	jz	doneContent			;not following, skip calc size
	call	OLPaneCalcContentSize		;send size through output
doneContent:
EC <	tst	cx							>
EC <	ERROR_Z OL_VIEW_BAD_WINDOW_SIZE_ADJUSTMENTS			>
EC <	ERROR_S OL_VIEW_BAD_WINDOW_SIZE_ADJUSTMENTS			>
EC <	tst	dx							>
EC <	ERROR_Z OL_VIEW_BAD_WINDOW_SIZE_ADJUSTMENTS			>
EC <	ERROR_S OL_VIEW_BAD_WINDOW_SIZE_ADJUSTMENTS			>
	
	mov	ax, MSG_GEN_VIEW_CALC_WIN_SIZE
	call	ObjCallInstanceNoLock		;allow win class to be subclassd
	
EC <	tst	cx							>
EC <	ERROR_Z OL_VIEW_CALC_WIN_SIZE_BAD_WIDTH				>
EC <	ERROR_S OL_VIEW_CALC_WIN_SIZE_BAD_WIDTH				>
EC <	tst	dx							>
EC <	ERROR_Z OL_VIEW_CALC_WIN_SIZE_BAD_HEIGHT			>
EC <	ERROR_S OL_VIEW_CALC_WIN_SIZE_BAD_HEIGHT			>
	
	call	CheckPaneMinMax			;keep within mins & maxs
						;also returns if scrollable

if (not FLOATING_SCROLLERS)
	call	TurnBarsOnOffIfNeeded		;based on scrollability
endif

	call	GetFrameWidth			;get width of pane win frame
	shl	ax, 1				;double for two sides
	add	cx, ax				;add pane win frame back in
	add	dx, ax				;  for final size
	pop	bp				;restore frame pointer

checkForWinSizeChange:	
	cmp	cx, winWidth			;see if size has changed
	jne	50$
	cmp	dx, winHeight
50$:
	mov	winWidth, cx			;store as new window width
	mov	winHeight, dx			;  in any case
	pop	ax				;restore loop count	
	jne	loopEm				;window width changed, branch

sizeJelled:
	;
	; Window size *seems* to have jelled here.  Let's make sure that
	; we're actually big enough to hold the minimum sizes of the area
	; gadgets.  It's possible that the area gadgets will be bigger, and 
	; the window may as well expand to fit these things.  We'll only try
	; this once, though.
	;	
	tst	ah				;have we don't this before?
	jnz	done				;yes, we're done.

	push	ax
	clr	bx				;adjust width to gadget minimum
	call	KeepBiggerThanAreaMins		;

	xchg	cx, dx				;adjust height to gadget minimum
	mov	bx, CSPC_VERTICAL		
	call	KeepBiggerThanAreaMins		
	xchg	cx, dx				
	pop	ax

	dec	ah				;say we've tried this once
	push	ax				;save the new value
	jmp	short checkForWinSizeChange	;we'll loop some more if this
						;   causes a change.

	;
	; Increment pass. (Added 10/18/91 cbh; the lack of this kept the 
	; pane window from expanding to fill area left by minimal size
	; scrollbars in very small width/height situations.
	;
loopEm:
	inc	al							
	cmp	al, VIEW_MAX_GEOMETRY_PASSES	;done a lot of passes, give up
	jae	sizeJelled			;	(12/27/92 cbh)
	jmp	geoLoop				;else loop 'em

done:	
	;
	; Now calculate what the total size will actually be, based on this
	; window size.  Total size will end up in cx, dx.
	;
	clr	bl
	call	CalcTotalSize			;calc size of window 
	mov	bl, CSPC_VERTICAL		;   based on total size and
	call	CalcTotalSize			;   size of each area

	push	cx, dx				;save args to return
	mov	cx, winWidth
	mov	dx, winHeight
	call	SizeViewWindow			;set view window size
	pop	cx, dx

	.leave
	ret
CalcSizeOfPaneChildren	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	ChooseInitialWinSize

SYNOPSIS:	Chooses a good initial window size to use for geometry calcs.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- pane

RETURN:		winHeight, winWidth -- set appropriately

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/15/92		Initial version

------------------------------------------------------------------------------@

ChooseInitialWinSize	proc	near		uses	cx, dx
	totalHeight	local	sword	;total size
	totalWidth	local	sword
	winHeight	local	sword	;win size, including frame
	winWidth 	local	sword	;leave in this order!

	.enter	inherit

	mov	di, ds:[si]			;point to pane instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- pane SpecInstance
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jnz	beenThereDoneThat		;have yet to use initial size

	;
	; Start off window with any initial size hint, or failing that, our
	; rather weak initial window size.
	;
	call	LookupOpenSize			;ax, bx <- initial size
	movdw	cxdx, axbx			;now cx, dx

	tst	cx				;is there something for width?
	jnz	10$
	mov	cx, VS_TYPICAL_HORIZONTAL
10$:
	tst	dx
	jnz	20$
	mov	dx, VS_TYPICAL_VERTICAL
20$:
	call	GetFrameWidth			;add in frame border
	shl	ax, 1
	add	cx, ax
	add	dx, ax
	jmp	short done

beenThereDoneThat:
	;
	; Use current values for the window size initially.  The idea is,
	; on the first pass, to keep areas from resizing unnecessarily if
	; they've been resized before, but to at least get some size from them 
	; if they haven't ever been resized.  We can then set a win size
	; based on the total size minus the area sizes, and do another pass.
	;
	call	GetFrameBounds			;get previous bounds
	sub	cx, ax				;make into screen coord size
	inc	cx
	sub	dx, bx
	inc	dx
done:
	mov	winWidth, cx			;save the fine values
	mov	winHeight, dx
	.leave	
	ret
ChooseInitialWinSize	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	TurnBarsOnOffIfNeeded

SYNOPSIS:	Turns scrollbars off if we're not scrollable, and the 
		appropriate flag is set for this kind of behavior.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- pane
		al     -- non-zero if vertically not scrollable
		ah     -- non-zero if horizontally not scrollable

RETURN:		nothing

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/15/92		Initial version

------------------------------------------------------------------------------@

if (not FLOATING_SCROLLERS)

TurnBarsOnOffIfNeeded	proc	near
	uses	cx, dx
	.enter

EC <	call	VisCheckVisAssumption		;make sure OK		 >
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_attrs, \
			mask OLPA_REMOVE_SCROLLBARS_WHEN_NOT_SCROLLABLE

if _DISABLE_SCROLLERS_WHEN_NOT_SCROLLABLE
	;
	; Assume the scrollers are fully enabled (UNLESS the view
	; is not fully enabled).
	;
	mov	cx, mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE
	jnz	setScrollers			; zero to remove scrollers
	;
	; We're not supposed to remove scrollers when not scrollable,
	; so we'll disable the scrollers instead.  First, if the view
	; is not fully enabled, then don't set the child fully enabled.
	; This code assumes that the view will disable the scrollers
	; when it becomes disabled itself; I think that's a valid
	; assumption.  -stevey 5/9/95
	;
	clr	cx				; assume not fully enabled
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	jz	setScrollers			; no change whatsoever
	mov	cx, mask VA_FULLY_ENABLED
setScrollers:
else
	jz	exit
	mov	cx, mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE
endif
	push	cx
	test	ds:[di].OLPI_flags, mask OLPF_LEAVE_ROOM_FOR_VERT_SCROLLER
	jnz	20$
	tst	al					;zero if scrollable
	jz	10$					;scrollable, branch
	xchg	cl, ch					;we'll turn these off
10$:
	mov	dx, ds:[di].OLPI_vertScrollbar
	tst	dx
	jz	20$
	push	di
	call	SetVisAttrs
	pop	di
20$:
	pop	cx
	test	ds:[di].OLPI_flags, mask OLPF_LEAVE_ROOM_FOR_HORIZ_SCROLLER
	jnz	exit
	tst	ah
	jz	30$					;scrollable, branch
	xchg	cl, ch					;we'll turn these off
30$:
	mov	dx, ds:[di].OLPI_horizScrollbar
	tst	dx
	jz	exit
	call	SetVisAttrs
exit:
	.leave
	ret
TurnBarsOnOffIfNeeded	endp

endif	;(not FLOATING_SCROLLERS)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetVisAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set attributes & mark invalid.

CALLED BY:	TurnBarsOnOffIfNeeded

PASS:		*ds:dx = scroller
		cl	= attrs to set
		ch	= attrs to clear

RETURN:		nothing

DESTROYED:	al, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	Chris	9/15/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not FLOATING_SCROLLERS)

SetVisAttrs	proc	near
	uses	si				;trashes al, cx, dx
	.enter

	mov	si, dx
EC <	call	VisCheckVisAssumption		;make sure OK		 >

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].VI_attrs
	or	al, cl
	not	ch
	and	al, ch

if _DISABLE_SCROLLERS_WHEN_NOT_SCROLLABLE
	;
	; If we're not VA_FULLY_ENABLED at this point, turn off
	; the GS_ENABLED bit as well, to allow people to turn the
	; bars back on if they want.
	;
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	doneEnabled

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GI_states, not mask GS_ENABLED
	pop	di		
doneEnabled:
endif
	;
	; Changed to only set vis attrs if actually changing, and more 
	; importantly, to mark the scrollbar's image invalid, as it is in
	; a state of flux and we don't need redraws when its page size changes
	; and stuff.    -cbh 11/ 6/92
	;
	cmp	al, ds:[di].VI_attrs		;no change, exit
	jz	exit
	mov	ds:[di].VI_attrs, al

	mov	dl, VUM_MANUAL			;play it safe here.
	mov	cl, mask VOF_IMAGE_INVALID	;(better not move chunks!)
	call	VisMarkInvalid
exit:
	.leave
	ret
SetVisAttrs	endp

endif	;(not FLOATING_SCROLLERS)
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	SubtractFrameFromSize

SYNOPSIS:	Subtracts frame from size.	

CALLED BY:	CalcSizeOfPaneChildren, SizeViewWindow

PASS:		*ds:si -- view
		cx, dx -- size

RETURN:		cx, dx -- new size

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/23/91		Initial version

------------------------------------------------------------------------------@

SubtractFrameFromSize	proc	near
	call	GetFrameWidth			;ax <- width of frame
	shl	ax, 1				;double for two sides
	cmp	cx, ax				;see if small width
	jbe	21$				;yes, don't subtract for frame
	sub	cx, ax				;leave pane frame out for this
21$:
	cmp	dx, ax				;see if small height
	jbe	22$				;yes, don't subtract for frame
	sub	dx, ax				;leave pane frame out for this
22$:
	ret
SubtractFrameFromSize	endp

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	SizeArea

SYNOPSIS:	Sizes an area, based on current window size.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- view
		local vars from CalcSizeOfPaneChildren
		bl     -- vertical flag (CSPC_VERTICAL or 0)
		ax     -- area offset (offset OLPI_leftObj, etc.)

RETURN:		nothing

DESTROYED:	di, ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@
SizeArea	proc	near		
	totalHeight	local	sword
	totalWidth	local	sword
	winHeight	local	sword
	winWidth 	local	sword	;leave in this order!
	
	.enter	inherit
	
	push	si
	clr	bh				;make bx an index
	push	bp
	add	bp, bx
	mov	cx, winWidth			;use a window dimension here
	pop	bp
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	tst	bx				;see if vertical
	jz	gotOrientation
	xchg	cx, dx				;if so, exchange cx, dx
gotOrientation:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	add	di, ax				;get to area chunk (scroller)
	mov	si, ds:[di]

	tst	si				;new code 4/15/93 cbh
	jz	exit				;  (we'll check managed later)

	;
	; Usually a VisRecalcSizeAndInvalIfNeeded would be in order here, but 
	; the nature of our geometry calculations causes images to be too
	; easily invalidated (we try several different sizes.)  Because
	; we are (hopefully) sure that any change in the scrollbar will
	; mean a change in the view as well, we won't ever invalidate
	; at this level.  Actually, if the areas geometry had been marked
	; invalid, we'll mark the view's image invalid right now, and hopefully
	; that will cover the cases where something in one of the control areas
	; changes but the view doesn't change size.
	;
	push	bp
if	0
	mov	ax, MSG_VIS_RECALC_SIZE	;make assumptions about our
	call	ObjCallInstanceNoLock		;  scrollbar...
else
	call	VisRecalcSizeAndInvalIfNeeded		;else do the usual stuff
endif
	call	VisSetSize			;set in instance data
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_optFlags, mask VOF_GEO_UPDATE_PATH or \
				     mask VOF_GEOMETRY_INVALID
	jz	20$				;geometry wasn't invalid, branch
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
					 or mask VOF_GEO_UPDATE_PATH)
	mov	dl, VUM_MANUAL
	mov	cl, mask VOF_IMAGE_INVALID
	call	VisMarkInvalidOnParent		;mark the view invalid
20$:
	pop	bp
exit:
	pop	si				
	.leave
	ret
SizeArea	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	MakeSpecificObject

SYNOPSIS:	Resets si to specific visual object.

CALLED BY:	SizeArea, MoveArea, ChooseAreaForObject

PASS:		*ds:si -- object

RETURN:		*ds:si -- visual object, or null if none
		zero flag set and carry clear if none

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       Assumes visual specific object in same block as generic.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/16/91		Initial version

------------------------------------------------------------------------------@
MakeSpecificObject	proc	far
	uses	ax, bx, cx, dx, bp
	.enter

EC <	call	VisCheckVisAssumption		;make sure OK		 >
   	clr	bp
   	CallMod	VisGetSpecificVisObject		;get correct object
   	mov	si, dx				;return spec object here
	
EC <	tst	dx				;is there one?
EC <	jz	exit				;no, skip error checking >
EC <	cmp	cx, ds:[LMBH_handle]					 >
EC <	ERROR_NE	OL_VIEW_CHILDREN_MUST_BE_IN_SAME_BLOCK		 >
EC <	call	VisCheckVisAssumption		;make sure OK		 >
EC <exit:								 >

   	tst	si				;set zero flag accordingly

   	.leave
	ret
MakeSpecificObject	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcWinSize

SYNOPSIS:	Calculates the window size, based on total size and various
		area sizes.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- view
		local vars from CalcSizeOfPaneChildren
		bl     -- vertical flag (CSPC_VERTICAL or 0)
		al     -- pass counter: if zero, don't allow scrollbars to 
				push out the size of the window

RETURN:		cx or dx -- returned window dimension, depending on bl

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@
CalcWinSize	proc	near

	totalHeight	local	sword
	totalWidth	local	sword
	winHeight	local	sword
	winWidth 	local	sword	;leave in this order!
	
	.enter	inherit

	clr	bh
	tst	bx				;see if vertical
	jz	gotOrientation			;no, we're done			
	xchg	cx, dx				;if so, exchange cx, dx
gotOrientation:					;we'll pretend horizontal now.

	;
	; If the total width is RSA_CHOOSE_OWN_SIZE (i.e. negative), we'll
	; keep the current winWidth.  Otherwise, we'll use the totalWidth
	; minus any calculated areas that we currently know of.
	;
	push	bp
	add	bp, bx
	mov	cx, totalWidth			;start with this
	tst	cx				;if totalWidth = desired, use
						;  winWidth instead
	jns	12$
	mov	cx, winWidth
12$:
	pop	bp
	js	20$				;using old winSize, branch

	mov	ax, offset OLPI_leftObj		;ax <- width of left area,
	add	ax, bx				;  including a margin
	call	GetAreaAndMargin		
	sub	cx, ax				;subtract from width

	mov	ax, offset OLPI_rightObj	;ax <- width of right area,
	add	ax, bx				;  including a margin
	call	GetAreaAndMargin		
	sub	cx, ax				;subtract from width

	tst	cx				;did we go negative?
	jz	15$				;no, but zero's bad too
	jns	20$				;no, relax, you're paranoid...
15$:
	mov	cx, 1				;else let's get small.
20$:
	tst	bx				;see if vertical
	jz	40$				;no, we're done			
	xchg	cx, dx				;if so, exchange cx, dx
40$:	
	.leave
	ret
CalcWinSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	KeepBiggerThanAreaMins

SYNOPSIS:	Keeps the dimension passed big enough for area minimums.
		For instance, if cx is horizontal, it must be at least as
		big as the width of the top scrollbar and the width of the
		bottom scrollbar.

CALLED BY:	CalcWinSize, CalcTotalSize

PASS:		*ds:si -- view
		cx -- dimension to check
		bl -- vertical flags (CSPC_VERTICAL or 0)

RETURN:		cx -- dimension, possibly updated

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@
KeepBiggerThanAreaMins	proc	near		;comments assume horiz

	clr	bh
EC <	cmp	bx, CSPC_VERTICAL					>
EC <	ERROR_A	-1							>
	mov	ax, offset OLPI_topObj		;ax <- width of top area
	sub	ax, bx				;account for direction
	call	GetAreaDimension		
	cmp	cx, ax				;see if top area too big
	jae	20$				
	mov	cx, ax				;if so, use as win width
20$:
	mov	ax, offset OLPI_bottomObj	;ax <- width of right area,
	sub	ax, bx				;account for direction
	call	GetAreaDimension		
	cmp	cx, ax				;see if bottom area too big
	jae	30$				
	mov	cx, ax				;if so, use as win width
30$:
	ret
KeepBiggerThanAreaMins	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcTotalSize

SYNOPSIS:	Calculates the total size, based on window size and various
		area sizes.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- view
		local vars from CalcSizeOfPaneChildren
		bl     -- vertical flag (CSPC_VERTICAL or 0)

RETURN:		cx or dx -- returned window dimension, depending on bl

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@
CalcTotalSize	proc	near

	totalHeight	local	sword
	totalWidth	local	sword
	winHeight	local	sword
	winWidth 	local	sword		; leave in this order!
	
	.enter	inherit

	clr	bh
	tst	bx				;see if vertical
	jz	gotOrientation			;no, we're done			
	xchg	cx, dx				;if so, exchange cx, dx
gotOrientation:					;we'll pretend horizontal now.
	push	bp
	add	bp, bx
	mov	cx, winWidth			;start with this
	pop	bp
	
	call	KeepBiggerThanAreaMins		;make sure bigger than top
						;  and bottom's widths -- 
						;  actual window may not stay
						;  this big, if it can't.
	mov	ax, offset OLPI_leftObj		;ax <- width of left area,
	add	ax, bx				;  including a margin
	call	GetAreaAndMargin		
	add	cx, ax				;add to width
	
	mov	ax, offset OLPI_rightObj	;ax <- width of right area,
	add	ax, bx				;  including a margin
	call	GetAreaAndMargin		
	add	cx, ax				;add to width
30$:
	tst	bx				;see if vertical
	jz	40$				;no, we're done			
	xchg	cx, dx				;if so, exchange cx, dx
40$:					
	.leave
	ret
CalcTotalSize	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetAreaDimension

SYNOPSIS:	Returns a dimension for this area.

CALLED BY:	CalcWinSize, CalcTotalSize

PASS:		*ds:si -- view
		ax -- the guy we want (offset OLPI_leftObj, etc.)
		bl -- the dimension we want (CSPC_VERTICAL or 0)

RETURN:		ax -- the dimension

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version

------------------------------------------------------------------------------@

GetAreaDimension	proc	near
	uses	cx, dx, si
	class	OLPaneClass
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

if HOLISTIC_SCROLLBAR_POSITIONING
	;
	; If scrollbar positions aren't determined by the view,
	; return 0 size for relevant dimensions.
	;
	push	bp, si
	mov	bp, si				; shuffle registers
	mov	si, di				;  so TestHolisticness is
	mov	di, ax				;  happy
	call	TestHolisticness
	mov	di, si				; ds:si = instance data on exit
	pop	bp, si
	jz	notHolistic

	tst	bl
	jnz	vertHolistic

	;
	; If asked for width of left/right objects, return 0
	;
	cmp	ax, offset OLPI_leftObj
	je	noWidth
	cmp	ax, offset OLPI_rightObj
	je	noWidth
	jmp	notHolistic

vertHolistic:
	;
	; If asked for height of top/bottom objects, return 0
	;
	cmp	ax, offset OLPI_topObj
	je	noWidth
	cmp	ax, offset OLPI_bottomObj
	je	noWidth
notHolistic:
endif ; HOLISTIC_SCROLLBAR_POSITIONING

	add	di, ax	
	mov	si, ds:[di]			;get object chunk
	clr	ax				;assume nothing, return 0
	call	GetSpecAndEnsureManaged
	jnc	exit				;not managed, exit
	call	VisGetSize			;get dimension
	mov	ax, cx				;assume we want width
	tst	bl				;see if vertical
	jz	exit				;no, we're done			
	mov	ax, dx				;if so, return vertical
exit:					
	.leave	
	ret

if HOLISTIC_SCROLLBAR_POSITIONING
noWidth:
	clr	ax
	jmp	exit
endif ; HOLISTIC_SCROLLBAR_POSITIONING

GetAreaDimension	endp
			

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSpecAndEnsureManaged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets specific visual object and ensures the thing is managed.

CALLED BY:	GetAreaDimension, SizeArea

PASS:		*ds:si -- generic object

RETURN:		carry clear if not managed, doesn't exist, etc.
		else *ds:si -- visual object

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSpecAndEnsureManaged	proc	near

	tst	si				;any object?
	jz	exit				;no, exit, carry should be clear
	call	MakeSpecificObject		;*ds:si - visual object   
	jz	exit				;there isn't one, exit carry clr
	call	VisCheckIfSpecBuilt		;no longer in visual tree, exit
	jnc	exit				;not there, exit carry clear
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_MANAGED
	jz	exit				;not managed, exit carry clear
	stc					;else return carry set
exit:
	ret
GetSpecAndEnsureManaged	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetAreaAndMargin

SYNOPSIS:	Returns a dimension for this area, and margin as well, if
		applicable.

CALLED BY:	CalcWinSize, CalcTotalSize

PASS:		*ds:si -- view
		ax -- the guy we want (offset OLPI_leftObj, etc.)
		bx -- the dimension we want (CSPC_VERTICAL or 0)

RETURN:		ax -- the dimension

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 8/91		Initial version
	Joon	8/92		PM extensions

------------------------------------------------------------------------------@
GetAreaAndMargin	proc	near	

	call	GetAreaDimension		;ax <- dimension asked for
	tst	ax
	jz	exit				;nothing returned, exit
	call	AddMarginToAx
exit:
	ret
GetAreaAndMargin	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	AddMarginToAx

SYNOPSIS:	Adds a margin to value in ax.  The margin is the typical
		spacing between view and scrollbar gadgets.

CALLED BY:	GetAreaAndMargin, OLPanePosition

PASS:		ax -- value to add to

RETURN:		ax -- updated

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/14/92       	Initial version

------------------------------------------------------------------------------@
AddMarginToAx	proc	near
	uses	bx
	.enter

	mov	bx, SCROLLBAR_MARGIN		;probably want to add this

						;CHECK BW FOR CUA LOOK
MO <	call	OpenCheckIfCGA			;see if CGA	       	      >
MO <	jnc	10$				;not CGA, branch	      >
MO <	mov	bx, CGA_SCROLLBAR_MARGIN		      		      >
MO <10$:								      >
	; There are problems with -1 spacing if there's no win frame, so use
	; zero spacing in those cases.

	tst	bx				;positive margins always OK
	jns	marginOK

	mov	di, ds:[si]						      
	add	di, ds:[di].Gen_offset					      
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME		      
	jnz	exit				;if noWinFrame, don't add margin

marginOK:
	add	ax, bx

exit:
	.leave
	ret
AddMarginToAx	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SizeViewWindow

SYNOPSIS:	Keep track of view window size.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		cx, dx -- size of window area, including frame

RETURN:		nothing

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 3/91		Initial version

------------------------------------------------------------------------------@
SizeViewWindow	proc	near
	uses	cx, dx
	;
	; Size the window now.  If the size changes, let's guarantee that its
	; image and window are invalidated.  It could be that the window's size
	; changes (from removing or adding scrollbars, for instance) without
	; the overall view size changing.  In that case, the geometry manager
	; won't mark the object's image and window as invalid on it's own.
	;
	.enter
	call	SubtractFrameFromSize		;get real window size
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLPI_winWidth, cx	;see if pane size is changing
	jne	55$				;yes, go invalidate window
	cmp	ds:[di].OLPI_winHeight, dx
	je	done
55$:
	push	cx, dx
	mov	cl, mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid
	pop	cx, dx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLPI_winWidth, cx	;save size of pane window
	mov	ds:[di].OLPI_winHeight, dx
done:
	.leave
	ret
SizeViewWindow	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckAspectRatio

SYNOPSIS:	Deals with aspect ratio stuff.

CALLED BY:	CalcSizeOfPaneChildren
       
PASS:		cx, dx -- suggested view size, including frame	

RETURN:		cx, dx -- new size, accounting for aspect ratio adjustments

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 3/91		Initial version

------------------------------------------------------------------------------@

CheckAspectRatio	proc	near		
	;
	; We now have coordinates all set for the window, except we might
	; have to:  a) change the aspect ratio of the window to match the view
	; open size, and/or b) call the view's OD to adjust the window's size
	; somewhat.   Depending, of course, on what flags are set.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_vertAttrs, mask GVDA_KEEP_ASPECT_RATIO
	jz	42$				;skip if not doing aspect ratio
	;
	; Replace height by width*vertOpenSize/horizOpenSize to keep ratio.
	;
	call	LookupOpenSize			;open size in ax, bx
	jz	exit				;not complete, exit
	
	push	dx				;save old height
	push	ax				;save horiz open size
	mov	ax, cx				;passed width in ax
	mul	bx				;passed width * vertOpenSize
	pop	bx				;(restore horiz open size)
	div	bx				;divided by vert open size
	mov	dx, ax				;result is height
	;
	; Don't allow resultant height to go to zero.  11/ 5/92 cbh
	;
	tst	dx
	jnz	40$
	inc	dx
40$:

	pop	ax				;restore old height
	test	ds:[di].GVI_horizAttrs, mask GVDA_KEEP_ASPECT_RATIO
	jz	exit				;only vertical set, done
	;
	; If both vertical and horizontal are set, we'll take the maximum
	; of the two rectangles defined by the two resize dimensions passed
	; in.  If the new height was made smaller above, get back
	; old height and replace the width accordingly.
	;
	cmp	dx, ax				;see if new height is smaller
	jae	exit				;it's not, we're done
	mov	dx, ax				;else get old height back
						;fall thru to replace width
42$:
	test	ds:[di].GVI_horizAttrs, mask GVDA_KEEP_ASPECT_RATIO
	jz	exit				;skip if not doing aspect ratio
	;
	; Replace width by width*horizOpenSize/vertOpenSize to keep ratio.
	;
	call	LookupOpenSize			;open size in ax, bx
	jz	exit				;incomplete, exit
	
	push	dx				;save height
	push	bx				;save vert open size
	mov	bx, ax				;horiz open size
	mov	ax, dx				;passed height in ax now
	mul	bx				;mult by horizOpenSize
	pop	bx	
	div	bx				;div by vertOpenSize
	pop	dx				;restore height
	mov	cx, ax				;result is width
	;
	; Don't allow width to go to zero.  -cbh 11/ 5/92
	;
	tst	cx
	jnz	exit
	inc	cx
exit:
	ret
CheckAspectRatio	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneCalcContentSize

SYNOPSIS:	Sends size to output if not scrollable in a direction.

CALLED BY:	CalcSizeOfPaneChildren

PASS:		*ds:si -- GenView handle
		cx, dx -- height we're planning to use

RETURN:		cx, dx -- height after the output gets done with it

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:
       		if vertAttrs & SCROLLABLE
			dx = mask RSA_CHOOSE_OWN_SIZE
		if horizAttrs & SCROLLABLE
			cx = mask RSA_CHOOSE_OWN_SIZE
		send CALC_NEW_SIZE and RESIZE methods to OD
       		if vertAttrs & SCROLLABLE
			restore dx
		if horizAttrs & SCROLLABLE
			restore dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 5/89		Initial version

------------------------------------------------------------------------------@

OLPaneCalcContentSize	proc	near
	class	OLPaneClass
	
	push	bx
	;
	; See if we need to pass the pane's dimension along to the object.
	; We do if the thing is not scrollable.
	;
	push	cx, dx
	mov	di, ds:[si]			;point to instance of View
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_vertAttrs, mask GVDA_SCROLLABLE
	jz	checkHoriz			;can't scroll vertically, branch
	mov	dx, mask RSA_CHOOSE_OWN_SIZE	;else pass desired width

checkHoriz:
	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	send				;can't scroll horiz, branch
	mov	cx, mask RSA_CHOOSE_OWN_SIZE	;else pass desired height

send:
	mov	ax, MSG_VIS_RECALC_SIZE
	call	OLPaneCallApp
	mov	ax, MSG_VIS_SET_SIZE
	call	OLPaneCallApp
	;
	; Use the return value if the view is not scrollable in that direction.
	;
	DoPop	bx, ax				;restore old values
	mov	di, ds:[si]			;point to instance of View
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_vertAttrs, mask GVDA_SCROLLABLE
	jz	checkHoriz2			;can't scroll vertically, branch
	mov	dx, bx				;else restore width

checkHoriz2:
	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	exit				;can't scroll horiz, branch
	mov	cx, ax				;else restore height
exit:
	pop	bx
	ret
OLPaneCalcContentSize	endp
			


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckPaneMinMax

SYNOPSIS:	Make sure pane is staying within set minimums and maximums.
		(Or simple pane.)

CALLED BY:	CalcPaneSizeFromParent, OLPaneRecalcSize

PASS:		*ds:si -- handle of pane
		cx, dx -- currently desired size of pane window area

RETURN:		cx, dx -- size to use for pane window area
		al     -- non-zero if not vertically scrollable
		ah     -- non-zero if not horizontally scrollable

DESTROYED:	ax, bp, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/25/89		Initial version
	Chris	11/ 5/92	No longer constrains to zero content sizes

------------------------------------------------------------------------------@

CheckPaneMinMax	proc	near
	class	OLPaneClass
	
	push	bx
	CallMod	VisApplySizeHints		;use size hints to limit
						;  to min and max
if FLOATING_SCROLLERS
	;
	; Make pane large enough so scrollers remain inside the pane boundary
	; and don't overlap each other.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_vertAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	checkHoriz
	test	ds:[di].GVI_vertAttrs, mask GVDA_SCROLLABLE
	jz	checkHoriz

	test	ds:[di].GVI_horizAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	vertOnly
	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	vertOnly

	; Set minimum width/height so both vert/horiz scrollers fit.

	mov	ax, (2 * FLOATING_X_SCROLLER_WIDTH) + \
		    (3 * FLOATING_SCROLLER_MARGIN) + \
		    (1 * FLOATING_SCROLLER_EXTRA_MARGIN)
	mov	bx, (2 * FLOATING_Y_SCROLLER_HEIGHT) + \
		    (3 * FLOATING_SCROLLER_MARGIN) + \
		    (1 * FLOATING_SCROLLER_EXTRA_MARGIN)
	call	VisHandleMinResize
	jmp	afterScrollerMin

vertOnly:
	; Set minimum width/height so only vertical scrollers fit.

	mov	ax, FLOATING_Y_SCROLLER_WIDTH + \
		    (2 * FLOATING_SCROLLER_MARGIN)
	mov	bx, (2 * FLOATING_Y_SCROLLER_HEIGHT) + \
		    (3 * FLOATING_SCROLLER_MARGIN)
	call	VisHandleMinResize
	jmp	afterScrollerMin

checkHoriz:
	test	ds:[di].GVI_horizAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	afterScrollerMin
	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	afterScrollerMin

	; Set minimum width/height so only horizontal scrollers fit.

	mov	ax, (2 * FLOATING_X_SCROLLER_WIDTH) + \
		    (3 * FLOATING_SCROLLER_MARGIN)
	mov	bx, FLOATING_X_SCROLLER_HEIGHT + \
		    (2 * FLOATING_SCROLLER_MARGIN)
	call	VisHandleMinResize

afterScrollerMin:
endif	; FLOATING_SCROLLERS

	;
	; First, calculate the "size" of the document, based on its minimum
	; and maximum.  Actually, we'll calculate the screen size.
	;
	push	cx, dx
	mov	di, ds:[si]			
 	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GVI_docBounds.RD_right.low
	mov	dx, ds:[di].GVI_docBounds.RD_right.high
	sub	cx, ds:[di].GVI_docBounds.RD_left.low
	sbb	dx, ds:[di].GVI_docBounds.RD_left.high
	tst	dx				;rather wide?
	jz	10$				;not > 16 bits, branch
	mov	cx, 0ffffh			;else use a huge width
10$:
	mov	ax, cx				;pass width in ax
	mov	cx, ds:[di].GVI_docBounds.RD_bottom.low
	mov	dx, ds:[di].GVI_docBounds.RD_bottom.high
	sub	cx, ds:[di].GVI_docBounds.RD_top.low
	sbb	dx, ds:[di].GVI_docBounds.RD_top.high
	tst	dx				;rather high?
	jz	20$				;not > 16 bits, branch
	mov	cx, 0ffffh			;else use a huge height
20$:
	mov	bx, cx				;pass height in bx
	call	MultByScaleFactor		;multiply by scale factor
	pop	cx, dx
	
	; If the view has GVA_NO_SMALLER_THAN_DOC_SIZE set, we'll apply the
	; document size as the minimum size of the view window.
	;
	push	ax, bx				;save the doc size values
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_horizAttrs, mask GVDA_NO_SMALLER_THAN_CONTENT
	jnz	haveHorizMin			
30$:
	clr	ax				;else don't use as minimum

haveHorizMin:
	test	ds:[di].GVI_vertAttrs, mask GVDA_NO_SMALLER_THAN_CONTENT
	jnz	haveVertMin			
40$:
	clr	bx				;else don't use as minimum

haveVertMin:
EC <	cmp	ax, 4000			;this is rather large	>
EC <	ERROR_A	OL_VIEW_DOC_TOO_BIG_TO_NOT_BE_SCROLLABLE		>
EC <	cmp	bx, 4000			;this is rather large	>
EC <	ERROR_A	OL_VIEW_DOC_TOO_BIG_TO_NOT_BE_SCROLLABLE		>
   
	call	VisHandleMinResize		
	pop	ax, bx
	
	;
	; If our view is already at the maximums, we'll note it, regardless
	; of whether the pane needs to constrained to the max'es.
	;
	clr	bp
        cmp     cx, ax                  ; check against maximum width
        jb     	42$                     ; not bigger, branch
	or	bp, 0ff00h
42$:
        cmp     dx, bx                  ; check against maximum height
        jb     44$                      ; not bigger, branch
	or	bp, 0ffh		; set horizontal
44$:
	push	bp

	;
	; Now we'll check to make sure the view doesn't get bigger than the
	; document, if either of the NO_LARGER_THAN_CONTENT flags are set.
	; (If we're in scale-to-fit mode then ignore the "no larger
	; than content" flags)

	test	ds:[di].GVI_attrs, mask GVA_SCALE_TO_FIT
	jz	notScaleToFit

	; if ATTR_GEN_VIEW_SCALE_TO_FIT_BOTH_DIMENSIONS then allow both
	; dimensions free reign

	mov	bp, ATTR_GEN_VIEW_SCALE_TO_FIT_BOTH_DIMENSIONS
	call	testVarData
	jc	freeBothWays
	mov	bp, ATTR_GEN_VIEW_SCALE_TO_FIT_BASED_ON_X
	call	testVarData
	jc	freeWidth

	;
	; Scale to fit based on Y.  We leave Y alone and change X so that
	; X/Y = docWidth/pageHeight or X = Y * (docWidth/pageHeight)
	; (We use docWidth instead of pageWidth because GeoWrite has
	; docWidth > pageWidth causing weird problems with the scrollbar.)
	; - Joon (7/18/94)
	;

	push	cx, dx
	movdw	dxcx, ds:[di].GVI_docBounds.RD_right
	subdw	dxcx, ds:[di].GVI_docBounds.RD_left

	mov	ax, ATTR_GEN_VIEW_PAGE_SIZE
	call	ObjVarFindData
	jnc	noPageSize

	mov	ax, ds:[bx].XYS_height
	clr	bx
	jmp	haveSizes

noPageSize:
	movdw	bxax, ds:[di].GVI_docBounds.RD_bottom
	subdw	bxax, ds:[di].GVI_docBounds.RD_top

haveSizes:
	call	GrUDivWWFixed			; dx.cx = docWidth/pageHeight
EC <	ERROR_C	-1				; did we overflow?	>

	pop	ax, bx
	push	bx, ax
	clr	ax				; bx.ax = Y.0
	call	GrMulWWFixed			; X = Y * (docWidth/pageHeight)
	shl	cx
	adc	dx, 0				; round up
	mov	cx, dx
	pop	dx				; dx = original X
	cmp	cx, dx				; don't make new X larger
	jl	okX				;  then original X
	mov	cx, dx				;
okX:
	pop	dx

freeBothWays:
	mov	bx, 0ffffh
freeWidth:
	mov	ax, 0ffffh
	jmp	haveMax

notScaleToFit:
	tst	ax				;content has no width yet, don't
	jz	noMax				;  constrain to it at all
						;  (cbh 11/ 5/92)
	test	ds:[di].GVI_horizAttrs, mask GVDA_NO_LARGER_THAN_CONTENT
	jnz	haveHorizMax			;branch if has a maximum
noMax:
	mov	ax, 0ffffh			;else have no maximum

haveHorizMax:
	tst	bx				;content has no height, don't
	jz	freeHeight			;  contrain to it at all
						;  (cbh 11/ 5/92)

	test	ds:[di].GVI_vertAttrs, mask GVDA_NO_LARGER_THAN_CONTENT
	jnz	haveVertMax			;branch if has a maximum
freeHeight:
	mov	bx, 0ffffh			;else have no maximum
haveVertMax:

haveMax:
	call 	VisHandleMaxResize		;check if cx, dx, below max
	
	;
	; Now round the values to the increment amounts, if necessary.
	;
	test	ds:[di].GVI_vertAttrs, mask GVDA_SIZE_A_MULTIPLE_OF_INCREMENT
	jz	50$				;branch if not rounding
	tst	ds:[di].GVI_increment.PD_x.high
	jnz	50$				;huge increment, forget this!
	mov	ax, dx				;else put current size in ax
	mov	bx, ds:[di].GVI_increment.PD_y.low
	call	RoundToIncrement
	mov	dx, ax				;store rounded value
50$:
	test	ds:[di].GVI_horizAttrs, mask GVDA_SIZE_A_MULTIPLE_OF_INCREMENT
	jz	60$				;branch if not rounding
	tst	ds:[di].GVI_increment.PD_x.high
	jnz	60$				;huge increment, forget this!
	mov	ax, cx				;else put current size in ax
	mov	bx, ds:[di].GVI_increment.PD_x.low
	call	RoundToIncrement
	mov	cx, ax				;store rounded value
60$:
	tst	cx
	jnz	70$
	inc	cx
70$:
	tst	dx
	jnz	80$
	inc	dx
80$:
	pop	ax				;restore scrollable flags
	pop	bx
	ret

testVarData:
	push	ax, bx
	mov_tr	ax, bp
	call	ObjVarFindData
	pop	ax, bx
	retn

CheckPaneMinMax	endp
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	MultByScaleFactor

SYNOPSIS:	Multiplies by scale factor to get screen dimensions.

CALLED BY:	CheckPaneMinMax

PASS:		*ds:si -- handle of pane
		ax, bx -- values to multiply

RETURN:		ax, bx -- result wrt. screen

DESTROYED:	cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      	Won't do conversion if doc coordinate is > 33000.  This could 
	cause a problem with huge scale values.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 7/90		Initial version

------------------------------------------------------------------------------@

MultByScaleFactor	proc	near
	tst	bx				;height is rather large, don't
	js	doWidth				;  bother with conversion
	push	ax				;save ax value
	clr	ax				;bx.ax is height
	mov	di, ds:[si]			;dx.cx is y scale factor
	add	di, ds:[di].Gen_offset		
	mov	dx, ds:[di].GVI_scaleFactor.PF_y.WWF_int
	mov	cx, ds:[di].GVI_scaleFactor.PF_y.WWF_frac
	call	GrMulWWFixed			;divide, result in dx.cx
	tst	cx				;round result if necessary
	jns	10$
	inc	dx
10$:
	mov	bx, dx				;put height back in bx
	pop	ax				;restore ax value
	
doWidth:
	tst	ax				;width rather large, skip
	js	exit				;   conversion
	push	bx				;save bx result
	mov	bx, ax				;put value in bx
	clr	ax				;bx.ax is width
						;dx.cx is x scale factor
	mov	dx, ds:[di].GVI_scaleFactor.PF_x.WWF_int
	mov	cx, ds:[di].GVI_scaleFactor.PF_x.WWF_frac
	call	GrMulWWFixed			;divide, result in dx.cx
	tst	cx				;round result if necessary
	jns	20$
	inc	dx
20$:
	mov	ax, dx				;return width in ax
	pop	bx				;restore bx result
exit:
	ret
MultByScaleFactor	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	RoundToIncrement

SYNOPSIS:	Rounds the size passed to the increment passed.  Actually,
		it just truncates.

CALLED BY:	CheckPaneMinMax

PASS:		ax -- size
		bx -- value to round to

RETURN:		ax -- new size

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/24/90		Initial version

------------------------------------------------------------------------------@

RoundToIncrement	proc	near
	uses	dx
	.enter
	tst	bx				;any increment?
	jz	exit				;no, leave size alone
	clr	dx				;clear high word
	div	bx				;integer result in ax
	tst	ax				;don't round to zero
	jnz	10$
	inc	ax
10$:
	mul	bx				;new value in ax
exit:
	.leave
	ret
RoundToIncrement	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneVisInvalidate -- 
		MSG_VIS_INVALIDATE for OLPaneClass

DESCRIPTION:	Does invalidation of any drawn-in areas.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_INVALIDATE

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
	Chris	7/31/91		Initial version

------------------------------------------------------------------------------@

OLPaneVisInvalidate	method dynamic	OLPaneClass, MSG_VIS_INVALIDATE
	mov	di, offset OLCtrlClass	;avoid OLCtrl's weird inval
	call	ObjCallSuperNoLock
	ret
OLPaneVisInvalidate	endm

ViewGeometry	ends

ViewCommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGeometryValid -- 
		MSG_VIS_NOTIFY_GEOMETRY_VALID for OLPaneClass

DESCRIPTION:	Tells us that our geometry is valid.  At this point, we see
		if we're in need of a redraw.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_NOTIFY_GEOMETRY_VALID

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/17/90		Initial version

------------------------------------------------------------------------------@

OLPaneGeometryValid	method OLPaneClass, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, offset OLPaneClass		;call super
	call	ObjCallSuperNoLock

	call	OLPaneSetNewPageSize		;get page size up to date
	
	;
	; Suspend updates, so that no MSG_EXPOSE events will come in until
	; after the WinResize and the MSG_META_CONTENT_VIEW_SIZE_CHANGED.
	; The unsuspend happens in OLPaneMoveResizeWin.  (cbh 10/23/91)
	;
	jnc	10$				;no change in page size, branch
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_flags, mask OLPF_SUSPENDED_FOR_SIZE_CHANGE
	jnz	10$				;already suspended, branch

	;
	; If the window isn't marked invalid, probably the geometry didn't
	; change.  In any case, we don't need to suspend things in this case.
	; -cbh 1/19/93
	;
	test	ds:[di].VI_optFlags, mask VOF_WINDOW_INVALID or \
				     mask VOF_WINDOW_UPDATE_PATH	
	jz	10$	
			
	call	PaneGetWindow			;get window in di
	jz	10$				;no window yet, branch
	call	WinSuspendUpdate		;suspend things for awhile
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_flags, mask OLPF_SUSPENDED_FOR_SIZE_CHANGE
10$:
	;
	; If we're in "scale to fit" mode then adjust the scale factor.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_SCALE_TO_FIT
	jz	notScaleToFit
	call	UpdateScale			;invalidates geometry, if needed

notScaleToFit:
	;
	; Trying something new here.  The idea is to do a WinSuspendUpdate 
	; at the start of the scale handler.  We'll set the suspend-for-scale
	; flag so that we know that we did it.  If the flag is set here, we'll
	; unsuspend the update.   This will be separate from the window
	; changing size's suspend/unsuspend pair.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_flags, mask OLPF_SUSPENDED_FOR_SCALING
	jz	adjustOrigin			;no inval needed, exit
	and	ds:[di].OLPI_flags, not mask OLPF_SUSPENDED_FOR_SCALING

	; This doesn't really work if a WinMoveResize is going to happen, as
	; un update will be generated from here *and* the WinMoveResize,
	; resulting in two redraws.  We'll queue an unsuspend instead. 
	; There shouldn't be any problems with another NOTIFY_GEOMETRY_VALID
	; coming through beforehand.  Can't do insert-at-front either, because
	; the size change comes from the parent invalidating, which is still
	; on the queue.  Sigh.  -cbh 3/27/93   (Commented out again, after
	; receiving a "mysterious" suspend underflow exiting geodex. 
	; -cbh 4/19/93)
	;
	call	PaneGetWindow			;get window in di
	jz	adjustOrigin
	call	WinUnSuspendUpdate
	
;	mov	ax, MSG_GEN_VIEW_UNSUSPEND_UPDATE
;	mov	bx, ds:[LMBH_handle]
;	mov	di, mask MF_FORCE_QUEUE 
;	call	ObjMessage
	
adjustOrigin:
	;
	; It may be that because of the new size, we'll have to scroll
	; to keep the document entirely in the view.  Also things may need
	; to stay tail oriented.  (Scrollbars will be drawn in VisUpdate)
	;
	call	PaneGetWindow			;get window in di
	jz	exit
	mov	bp, mask OLPSF_DONT_REDRAW_SCROLLBARS or \
		    SA_SCROLL_FOR_SIZE_CHANGE
	call	OLPaneAdjustOrigin
exit:
	ret
OLPaneGeometryValid	endm

ViewCommon	ends


Obscure	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPaneRedrawContent -- MSG_GEN_VIEW_REDRAW_CONTENT
						for OLPaneClass

DESCRIPTION:	Redraw the content

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass
	ax - The message

RETURN:	(internal) carry set if there was a window to invalidate.

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 2/91		Initial version
	Tony	6/ 3/92		Initial version of message handler
	Chris	7/27/92		Made the message handler, so will work with
				large contents

------------------------------------------------------------------------------@
InvalViewWindow	method OLPaneClass, MSG_GEN_VIEW_REDRAW_CONTENT
	uses	ds, si, ax, bx, cx, dx
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_window		;get window in di
	tst	di
	clc					;assume no window
	jz	exit				;no window yet, exit now

	;
	; get a pointer to the bounds to invalidate, and create a gstate 
	; New code to simply invalidate a very large area, regardless of bounds,
	; so that when the document gets smaller than the window, the areas
	; around the document get invalidated.  10/21/91 cbh
	;
	sub	sp, size RectDWord
	mov	bp, sp
	
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low
	mov	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high
	mov	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low
	mov	dx, ds:[di].GVI_origin.PDF_y.DWF_int.high
	
	mov	ss:[bp].RD_right.high, bx
	mov	ss:[bp].RD_left.high, bx
	mov	ss:[bp].RD_right.low, ax
	mov	ss:[bp].RD_left.low, ax
	mov	ss:[bp].RD_bottom.high, dx
	mov	ss:[bp].RD_top.high, dx
	mov	ss:[bp].RD_bottom.low, cx
	mov	ss:[bp].RD_top.low, cx
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLPI_pageWidth
	add	dx, ds:[di].OLPI_pageHeight
	add	ss:[bp].RD_right.low, cx
	adc	ss:[bp].RD_right.high, 0
	add	ss:[bp].RD_bottom.low, dx
	adc	ss:[bp].RD_bottom.high, 0
	pop	di
	
	segmov	ds, ss
	mov	si, bp	
	call	GrCreateState
	call  	GrInvalRectDWord			;invalidate the window
	call	GrDestroyState
	add	sp, size RectDWord
	stc					;say window invalidated
exit:
	.leave
	ret
InvalViewWindow	endp

Obscure	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneSetNewPageSize 

CALLED BY:	OLPaneScalePane, OLPaneGeometryValid
		
DESCRIPTION:	Sets the page size for the scrollbars.

PASS:		*ds:si 	- instance data

RETURN:		carry set if pane size changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/90		Initial version

------------------------------------------------------------------------------@

OLPaneSetNewPageSize	proc	far
	call	OLPaneGetDocWinSize		;get window size in cx, dx
	;
	; We have a new subview size in terms of document coordinates.  Store
	; them.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	cmp	cx, ds:[di].OLPI_pageWidth
	jne	10$
	cmp	dx, ds:[di].OLPI_pageHeight
if not (_NIKE or FLOATING_SCROLLERS)
	je	exit
endif

10$:

if _NIKE or FLOATING_SCROLLERS
	pushf	; Nike must always set range length, because adding a
		; horizontal scrollbar doesn't always change page size.
		; Joon (10/25/94)
endif

	mov	ds:[di].OLPI_pageWidth, cx	;set new values locally
	mov	ds:[di].OLPI_pageHeight, dx
	
	mov	di, cx
	clr	bx				;bx.di holds horizontal size
	mov	cx, dx				;dx.cx holds vertical size
	clr	dx

	mov	ax, MSG_GEN_VALUE_SET_RANGE_LENGTH	;set the page size
	call	OLPaneCallScrollbarsWithDWords

if _NIKE or FLOATING_SCROLLERS
	popf
	je	exit				;exit if no change
endif

	;
	; Moved to OLPaneScale and OLPaneMoveResizeWin, where it is 
	; guaranteed to be to be sent *after* the window is resized, which
	; is more correct.  (cbh 10/23/91)
	;
;	call	PaneGetWindow			;get window in di
;	jz	exit				;no window yet, exit
;	mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
;	call	SendPaneSizeMethod		;else size notification
	stc					;say size changed
exit:
	ret

OLPaneSetNewPageSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetDocWinSize --

DESCRIPTION:	Returns the size of the pane window, in its coordinate system.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

RETURN:		cx, dx  - dimensions of the pane window, in document coordinates

DESTROYED:	bx, si, di, ds, es, ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/20/89		Initial version

------------------------------------------------------------------------------@

OLPaneGetDocWinSize		proc	near
	call	GetPaneWinBounds		;get bounds of window, 
						;  minus frame
	sub	dx, bx				;make into size
	inc	dx
	sub	cx, ax
	inc	cx
	call	ConvertScreenToDocCoords	;convert, using scale factor
	ret
OLPaneGetDocWinSize	endp

	
COMMENT @----------------------------------------------------------------------

ROUTINE:	ConvertScreenToDocCoords

SYNOPSIS:	Converts screen coords to document coords, just using the 
		scale as a multiplier.

CALLED BY:	OLPaneGetDocWinSize

PASS:		*ds:si -- pane handle
		cx, dx -- screen coords

RETURN:		cx, dx -- document coords

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/90		Initial version

------------------------------------------------------------------------------@

ConvertScreenToDocCoords	proc	near
	push	cx				;first, save width
	clr	cx				;pad to make dx.cx a WWFixed
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	bx, ds:[di].GVI_scaleFactor.PF_y.WWF_int	
						;bx.ax gets y scale amount
	mov	ax, ds:[di].GVI_scaleFactor.PF_y.WWF_frac
	call	GrSDivWWFixed			;divide, result in dx.cx
	tst	cx				;see if fraction over 0.5
	jns	10$				;no, branch
	inc	dx				;else round up
10$:
	mov	bp, dx				;save integer part in bp
	
	pop	dx				;restore width
	clr	cx				;pad to make dx.cx. a WWFixed
	mov	bx, ds:[di].GVI_scaleFactor.PF_x.WWF_int	
						;bx.ax gets x scale amount
	mov	ax, ds:[di].GVI_scaleFactor.PF_x.WWF_frac
	call	GrSDivWWFixed			;divide, result in dx.cx
	tst	cx				;see if fraction over 0.5
	jns	20$				;no, branch
	inc	dx				;else round up integer part
20$:
	mov	cx, dx				;return width in cx
	mov	dx, bp				;return height in dx
	ret
ConvertScreenToDocCoords	endp

ViewCommon	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetFirstMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLPaneClass

DESCRIPTION:	Returns moniker position of "first child."   In the case of
		the view, this could be all sorts of bizarre places, so we'll
		elect not to return anything.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_FIRST_MKR_POS

RETURN:		carry set if something to return
		ax, cx	- position of first child's vis moniker

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/91		Initial version

------------------------------------------------------------------------------@

OLPaneGetFirstMkrPos	method OLPaneClass, MSG_GET_FIRST_MKR_POS
if _ODIE
	;
	; if scrolling text, adjust bounds by frame width
	;
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	done				; not, return carry clear
	call	GetFrameWidth			; ax = frame width
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VI_bounds.R_top
	add	cx, ax				; shift down by frame width
	mov	ax, ds:[di].VI_bounds.R_left	; no adjustment
	stc
	jmp	short done

done::
else
	clc					;return nothing
endif
	ret
OLPaneGetFirstMkrPos	endm

ActionObscure	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneConvertDesiredSizeHint -- 
		MSG_SPEC_CONVERT_DESIRED_SIZE_HINT for OLPaneClass

DESCRIPTION:	Converts a desired size appropriately.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CONVERT_DESIRED_SIZE
		cx -- width of the composite (SpecSizeSpec)
		dx -- child height to reserve (SpecSizeSpec)
		bp -- number of children to reserve space for

RETURN:		cx, dx -- converted size
		ax, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Initial version

------------------------------------------------------------------------------@

OLPaneConvertDesiredSizeHint	method OLPaneClass, \
				MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
	mov	di, offset OLCtrlClass
	GOTO	ObjCallSuperNoLock		;call superclass of parent
	
OLPaneConvertDesiredSizeHint	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLPaneClass

DESCRIPTION:	Returns extra size, in our purposes, zero.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx  - extra size
		ax, bp  - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/91		Initial version

------------------------------------------------------------------------------@
OLPaneGetExtraSize	method OLPaneClass, MSG_SPEC_GET_EXTRA_SIZE

	clr	cx, dx

	ret
OLPaneGetExtraSize	endm

ViewCommon	ends


