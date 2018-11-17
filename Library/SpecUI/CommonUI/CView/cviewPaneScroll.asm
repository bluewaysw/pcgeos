COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/View
FILE:		viewPaneScroll.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OLPaneScroll            Scrolls the pane.

    INT ScrollIntoOneDimension  Scrolls object into view, in one direction.

    INT GetLargeObjOnscreen     Gets an object larger than the window
				onscreen vertically.

    INT GetSmallObjOnscreen     Gets an object smaller than the window
				onscreen vertically.

    INT CalcNewOrigin           Calculates a new origin for scrolling an
				object onscreen.

    INT DNegate                 Negates a double precision number.

    INT OLPaneScrollAbsolute    Scrolls to a specified location.

    MTD MSG_GEN_VIEW_SET_ORIGIN_LOW 
				Low level scroll.  Doesn't normalize or
				propagate to other views.

    INT KeepOriginInBounds      Keeps origin within document's bounds.
				Also sets pane flags if we're at the right
				or bottom edge.

    INT KeepValueInBounds       Keeps an x or y value in bounds.

    INT StoreNewOrigin          Stores a new origin.

    INT SendNewOriginToOD       Sends new origin to OD.

    INT MakeRelativeToOrigin    Makes the value passed in relative to the
				current origin

    INT MakeRelativeWWFixed     Makes the value passed in relative to the
				current origin

    INT MakeScrollAmountAbsolute 
				Get an absolute scroll amount.

    INT SendTrackScrollingMethod 
				Sends out scroll tracking method for the
				pane.

    MTD MSG_GEN_VIEW_SETUP_TRACKING_ARGS 
				Sets up bounds in TrackScrollingParams.
				Called by a
				MSG_META_CONTENT_TRACK_SCROLLING handler to
				fill out missing arguments. Also gets the
				value in bounds, for the hell of it.

    INT GetNewOrigin            Gets new origin.

    INT MakeRelativeToOldOrigin Makes scroll values relative to the
				oldOrigin.

    INT SetupOldOrigin          Sets up old and new origins, looking at
				instance data and suggested change.

    INT SetupNewOrigin          Sets up new origin based on old origin and
				change.

    INT GetXOrigin              Returns x or y origin.

    INT GetYOrigin              Returns x or y origin.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/91		Started V2.0

DESCRIPTION:
	This file implements the pane scrolling.


	$Id: cviewPaneScroll.asm,v 1.1 97/04/07 10:51:42 newdeal Exp $
-------------------------------------------------------------------------------@

ViewScroll	segment resource




		
COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneScroll

SYNOPSIS:	Scrolls the pane.

CALLED BY:	utility

PASS:		*ds:si -- instance data
		bx:ax     -- amount in x direction to scroll
		dx:cx     -- amount in y direction to scroll
		bp     	  -- OLPaneScrollFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/27/90		Initial version

------------------------------------------------------------------------------@

OLPaneScroll	proc	far		uses 	si
	.enter
	call	ObjMarkDirty			;make sure things are dirtied
	
	call	MakeScrollAmountAbsolute	;get an absolute value
	call	KeepOriginInBounds		;keep in bounds	
	call	MakeRelativeToOrigin		;make the origin relative
	
	test	bp, mask OLPSF_DONT_NORMALIZE	;any normalize action?
	jnz	scrollem			;no, none needed
	test	bp, mask OLPSF_SCROLL_ACTION	;any normalize action?
	jz	scrollem			;no, none needed
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- view GenInstance
	tst	ds:[di].GVI_content.handle	;see if there's a content
	jz	scrollem			;no, continue to scroll normally
						;  until there is one
	
	test	ds:[di].GVI_attrs, mask GVA_TRACK_SCROLLING	
	jz	scrollem			;just scroll if not normalizing
	call	SendTrackScrollingMethod	;send it on its way
	jmp	exit				;normalize-complete will do
						;  window, range later
scrollem:
	test	bp, mask OLPSF_DONT_SEND_TO_LINKS
	jnz	scrollNow			;not doing links, branch
	
callLinks:
	push	ax, bx, cx, dx, bp
	sub	sp, size PointDWord
	mov	bp, sp
						; decide which
	mov	di, -1				; directions the
	tstdw	bxax				; scroll is in
	jnz	$10
	inc	di
$10:
	tstdw	dxcx
	jz 	$20
	inc	di
$20:
	push	di
	call	MakeScrollAmountAbsolute
	mov	ss:[bp].PD_x.low, ax
	mov	ss:[bp].PD_x.high, bx
	mov	ss:[bp].PD_y.low, cx
	mov	ss:[bp].PD_y.high, dx
	mov	dx, size PointDWord
	mov	di, mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SET_ORIGIN_LOW
	pop	bx
	call	GenViewSendToLinksIfNeededDirection	;propagate the message
	jc	popUndExit			;das vas handelt
	add	sp, size PointDWord
	pop	ax, bx, cx, dx, bp
	jmp	short scrollNow
	
popUndExit:
	add	sp, size PointDWord + 10	;throw away PointDWord,
						; ax, bx, cx, dx, bp
	jmp	exit
	
scrollNow:
	;
	; Let's check to see if anything's happening, and save the result.
	;
	mov	di, cx
	or	di, dx				
	push	di				;di = 0 if no vert scroll
	clr	di
	or	di, ax				
	or	di, bx
	push	di				;di = 0 if no horiz scroll
	or 	di, cx
	or	di, dx
	push	di				;di will be zero if no scrolling
	;
	; Now, set the new instance data value and scroll the window.
	;
	call	MakeScrollAmountAbsolute	;make this absolute again
	call	KeepOriginInBounds		;this is just to set right/
						;   bottom flags
	push	bx
	mov	bx, di				;flags in bl
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLPI_flags, not (mask OLPF_AT_RIGHT_EDGE or \
				          mask OLPF_AT_BOTTOM_EDGE)
	or	ds:[di].OLPI_flags, bl		;or in some flags
	pop	bx				;restore bx

	push	bp				;always send origin to OD on
	and	bp, mask OLPSF_SCROLL_ACTION	;  the initial positioning
	cmp	bp, SA_INITIAL_POS
	pop	bp
	pop	di				;restore scrolling flag
	je	storeAndNotify			;always send on initial pos
	
	tst	di				;any scrolling going on?
	jz	justScroll			;not scrolling, move on...
	
storeAndNotify:
	call	OLPaneSuspendUpdate		;suspend the window 3/19/93
	call	OLPaneWindowScroll		;scroll the window
	call	SendNewOriginToOD		;send off new origin (moved
						; before OLPaneWindowScroll
						; to get correct origin -cbh
						; 3/19/93
	call	OLPaneUnSuspendUpdate		;unsuspend the window  3/19/93


	call	StoreNewOrigin			;now store the new origin
						;  (after OLPaneWindowScroll!)
	jmp	short checkScrollbars

justScroll:
	call	OLPaneWindowScroll		;why is this necessary?  I'm
						;  not sure.
	
checkScrollbars:
	;
	; Update the ranges, if necessary.
	;
	test	bp, mask OLPSF_DONT_SEND_TO_SCROLLBARS
	jz 	scroll
	pop	di, di
	jmp	exit				;exit if not doing scrollbars
scroll:
	pop	di				;check for vert scroll
if FLOATING_SCROLLERS
	;
	; for floating scrollers, always update if requested
	;
	test	bp, mask OLPSF_ALWAYS_UPDATE_SCROLLBARS
	jnz	updateHoriz
endif
	tst	di
	jz 	noHoriz
updateHoriz::
	push	cx, dx
	movdw	dxcx, bxax
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call 	CallHorizScrollbar
	pop	cx, dx

;	call	OLPaneCallScrollbarsWithDWords	;update each scrollbar

noHoriz:
	pop	di				;check for horiz scroll
if FLOATING_SCROLLERS
	;
	; for floating scrollers, always update if requested
	;
	test	bp, mask OLPSF_ALWAYS_UPDATE_SCROLLBARS
	jnz	updateVert
endif
	tst	di
	jz	noVert
updateVert::
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	CallVertScrollbar
	
noVert:
exit:
	.leave
	;
	; Clear the keyboard scroll flag for all cases.  6/15/94 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and 	ds:[di].OLPI_optFlags, not mask OLPOF_KBD_CHAR_SCROLL

	call	SendNotifyCommon
EC <	Destroy	ax, cx, dx, bp				;destroy things	    >
	ret
	
OLPaneScroll	endp


ViewScroll	ends


ViewBuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneInitOrigin -- 
		MSG_SPEC_VIEW_INIT_ORIGIN for OLPaneClass

DESCRIPTION:	The point of this handler is to
		scroll the pane window after it has been created.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_INIT_ORIGIN

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/90		Initial version
	Jim	7/28/90		Added support for fixed point GVI_origin

------------------------------------------------------------------------------@

OLPaneInitOrigin	method OLPaneClass, MSG_SPEC_VIEW_INIT_ORIGIN
	clr	cx				;reset scrollbars
	clr	dx
	mov	ax, MSG_GEN_VALUE_SET_VALUE	
	call	OLPaneCallScrollbars		
	
	call	GetXOrigin			;get x origin in bx:ax
	call	GetYOrigin			;get y origin in dx:cx

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance

	;
	; Added 5/10/93 cbh to avoid scrolling the pane if not necessary.
	; cbh 5/10/93
	;
	test	ds:[di].GVI_attrs, mask GVA_TRACK_SCROLLING
	jnz	10$
	mov	bp, ax
	or	bp, bx
	or	bp, cx
	or	bp, dx
	jz	exit				;no scrolling needed, branch
10$:
	clr	bp
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.high, bp ;clear what's there, 
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.low, bp  ; make things scroll
	mov	ds:[di].GVI_origin.PDF_x.DWF_frac, bp	  ;
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.high, bp ;    
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.low, bp  ;    
	mov	ds:[di].GVI_origin.PDF_y.DWF_frac, bp	  ;
	mov	bp, SA_INITIAL_POS or mask OLPSF_ABSOLUTE or mask \
		  OLPSF_ALWAYS_SEND_NORMALIZE or mask OLPSF_DONT_SEND_TO_LINKS
	call	OLPaneScroll			;scroll, if need be...
exit:
	ret
OLPaneInitOrigin	endm


ViewBuild	ends

ActionObscure	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneMakeRectVisible --
		MSG_GEN_VIEW_MAKE_RECT_VISIBLE for OLPaneClass

DESCRIPTION:	Scrolls so a certain rectangular region will appear on the
		screen.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

		ss:[bp].MRVP_rect   - rectangle to get onscreen
		ss:[bp].MRVP_margin  - how far to scroll on

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, di, es, ds, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		Pure magic.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/17/89		Initial version

------------------------------------------------------------------------------@
	
OLPaneMakeRectVisible	method OLPaneClass, MSG_GEN_VIEW_MAKE_RECT_VISIBLE

	;
	; copy R/O stack data into chunk
	;
	mov	al, 0
	mov	cx, size MakeRectVisibleParams
	call	LMemAlloc			; ax = chunk
	push	ds, es, si
	mov	di, ax				; es:di = buffer in chunk
	mov	di, ds:[di]
	segmov	es, ds
	segmov	ds, ss				; ds:si = data on stack
	mov	si, bp
	rep movsb
	pop	ds, es, si

	mov	di, 1100			; blech. dynamic lists often
						;  require this much to scroll
						;  back to the top.
	call	ThreadBorrowStackSpace
	push	di

	;
	; copy R/O stack data from chunk onto new stack, if any
	;	*ds:ax = chunk
	;
	sub	sp, size MakeRectVisibleParams	; allocate space regardless
	tst	di
	jz	noNewStack
	mov	bp, sp				; ss:bp = MRVP on new stack
	push	es, si
	mov	si, ax
	mov	si, ds:[si]			; ds:si = data in chunk
	segmov	es, ss
	mov	di, bp				; es:di = buffer on new stack
	mov	cx, size MakeRectVisibleParams
	rep movsb
	pop	es, si
noNewStack:
	call	LMemFree

	clr	bx				;first do horizontal
	call	ScrollIntoOneDimension		
	push	cx, dx				;save horizontal results
	mov	bx, SIOD_VERTICAL		;now do vertical
	call	ScrollIntoOneDimension		;vertical results in dx:cx
	pop	ax, bx				;horizontal results in bx:ax
	mov	bp, SA_SCROLL_INTO or mask OLPSF_ABSOLUTE
	call	OLPaneScrollAbsolute		;go scrolling
	
	add	sp, size MakeRectVisibleParams

	pop	di
	call	ThreadReturnStackSpace
	ret
OLPaneMakeRectVisible	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	ScrollIntoOneDimension

SYNOPSIS:	Scrolls object into view, in one direction.

CALLED BY:	OLPaneScrollIntoPane

PASS:		*ds:si -- pane
		bx     -- 0 if horizontal
			  SIOD_VERTICAL if vertical
		ss:bp  -- MakeRectVisibleParams

RETURN:		dx:cx  -- new origin

DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@
SIOD_VERTICAL	equ	size OLPI_pageWidth	;offset to pass in
		
CheckHack <(offset OLPI_pageHeight - offset OLPI_pageWidth) eq SIOD_VERTICAL>
CheckHack <(offset GVI_docBounds.RD_top - offset GVI_docBounds.RD_left) \
	eq (SIOD_VERTICAL * 2)>
CheckHack <(offset MRVP_bounds.RD_top.low - offset MRVP_bounds.RD_left.low) \
	eq (SIOD_VERTICAL * 2)>
CheckHack <(offset MRVP_yFlags - offset MRVP_xFlags) \
	eq (SIOD_VERTICAL * 2)>
CheckHack <(offset MRVP_yMargin - offset MRVP_xMargin) \
	eq (SIOD_VERTICAL * 2)>

CheckHack <(offset GVI_origin.PDF_y - offset GVI_origin.PDF_x) \
	eq (SIOD_VERTICAL * 3)>

ScrollIntoOneDimension	proc	near
	uses	bp
	.enter
EC <	cmp	bx, SIOD_VERTICAL					>
EC <	ERROR_A	OL_BAD_FLAG_PASSED_TO_SCROLL_ROUTINE			>
   
	add	bp, bx				;adjust SIS to look at correct
	add	bp, bx				;   dimension
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	add	di, bx				;adjust for dimension
	add	di, bx
	add	di, bx				;size(DWFixed) = 3 words
	
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.low ;get current origin
	mov	dx, ds:[di].GVI_origin.PDF_x.DWF_int.high
	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	jns	checkY
	add	cx, 1				; round origin
	adc	dx, 0
checkY:
	;
	; Now do vertical.
	;
	push	ax				        ;save margin
	mov	ax, ss:[bp].MRVP_bounds.RD_right.low    ;get low word of size
	sub	ax, ss:[bp].MRVP_bounds.RD_left.low
EC <	push	bx					;check high word  >
EC <	mov	bx, ss:[bp].MRVP_bounds.RD_right.high			  >
EC <	sbb	bx, ss:[bp].MRVP_bounds.RD_left.high			  >
EC <	tst	bx							  >
EC <	pop	bx							  >
EC <	ERROR_S	 OL_VIEW_RECT_TO_MAKE_VISIBLE_HAS_NEGATIVE_SIZE		  >
EC <	ERROR_NZ OL_VIEW_RECT_TO_MAKE_VISIBLE_TOO_LARGE			  >
	
	mov	di, ds:[si]			;point to pane instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	add	di, bx				;correct for dimension
	cmp	ax, ds:[di].OLPI_pageWidth	;bigger than height of a page?
	pop	ax				;restore margin
	jae	tallObj				;yes, branch to handle
	call	GetSmallObjOnscreen		;else handle short object
	jmp	short exit			;and branch
	
tallObj:
	call	GetLargeObjOnscreen		;keep it onscreen vertically
exit:	
	.leave
	ret
ScrollIntoOneDimension	endp
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetLargeObjOnscreen

SYNOPSIS:	Gets an object larger than the window onscreen vertically.

CALLED BY: 	OLPaneScrollIntoPane

PASS:		ds:di -- OLPane spec instance, adjust for dimension
		ss:bp -- MakeRectVisibleParams, adjusted for dimension
		dx:cx -- current origin

RETURN:		dx:cx -- new scroll origin

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/23/90		Initial version

------------------------------------------------------------------------------@

GetLargeObjOnscreen	proc	near
	push	cx, dx
	test	ss:[bp].MRVP_xFlags, mask MRVF_ALWAYS_SCROLL
	jnz	scrollIt			;always scrolling, do it
	
	cmp	dx, ss:[bp].MRVP_bounds.RD_right.high
	jg	scrollIt
	jl	10$
	cmp	cx, ss:[bp].MRVP_bounds.RD_right.low 
	jae	scrollIt			;offscreen, branch to scroll
10$:
	add	cx, ds:[di].OLPI_pageWidth	;get to bottom of window
	adc	dx, 0
	
	cmp	dx, ss:[bp].MRVP_bounds.RD_left.high
	jg	exitOriginalArgs
	jl	scrollIt
	cmp	cx, ss:[bp].MRVP_bounds.RD_left.low
	ja	exitOriginalArgs		;not offscreen, exit
	jmp	short scrollIt
	
GetLargeObjOnscreen	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSmallObjOnscreen

SYNOPSIS:	Gets an object smaller than the window onscreen vertically.

CALLED BY: 	OLPaneScrollIntoPane

PASS:		ds:di -- OLPane spec instance, adjust for dimension
		ss:bp -- MakeRectVisibleParams, adjusted for dimension
		dx:cx -- current origin

RETURN:		dx:cx -- new scroll origin

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/23/90		Initial version

------------------------------------------------------------------------------@

GetSmallObjOnscreen	proc	near
	push	cx, dx				;save origin
	test	ss:[bp].MRVP_xFlags, mask MRVF_ALWAYS_SCROLL
	jnz	scrollIt			;always scrolling, do it
	
	cmp	dx, ss:[bp].MRVP_bounds.RD_left.high
	jg	scrollIt
	jl	10$
	cmp	cx, ss:[bp].MRVP_bounds.RD_left.low	;see if left of window
	ja	scrollIt			;yes, go scroll back on
10$:	
	add	cx, ds:[di].OLPI_pageWidth	;get bottom edge of window
	adc	dx, 0
	
	cmp	dx, ss:[bp].MRVP_bounds.RD_right.high
	jg	exitOriginalArgs
	jl	scrollIt
	cmp	cx, ss:[bp].MRVP_bounds.RD_right.low ;get to bottom of "point"
	jae	exitOriginalArgs		;not to right of window, exit
	
scrollIt		label 	near
	;
	; New pane origin = cursorY - winLen/2 - cursorHeight/2
	; In other words, center it.
	;
	pop	cx, dx				;restore original origin
	GOTO	CalcNewOrigin
	
exitOriginalArgs	label	near
	pop	cx, dx
	ret
GetSmallObjOnscreen	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcNewOrigin

SYNOPSIS:	Calculates a new origin for scrolling an object onscreen.

CALLED BY:	OLPaneScrollIntoPane

PASS:		ss:[bp] 	    -- MakeRectVisibleParams, adjusted for
		ds:di		    -- view SpecInstance
		dx:cx		    -- origin

RETURN:		dx:cx 		    -- new origin

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

if origin < MRVP_bounds.RD_left.low
   ; Scrolling down.
   cx = MRVP_bounds.RD_left - MRVP_margin * 
			      (MRVP_bounds.RD_right-MRVP_bounds.RD_left-winLen) 
   	         + (MRVP_bounds.RD_right-MRVP_bounds.RD_left.low-winLen)
else
   ; Scrolling up
   cx = MRVP_bounds.RD_left + MRVP_margin * 
			      (MRVP_bounds.RD_right-MRVP_bounds.DB_left.low-winLen)
endif

The proof is left as an exercise.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
      MRVP_bounds.RD_right-MRVP_bounds.RD_left must fit in 16 bits.  
	Won't work if right-left > winLen.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/14/89		Initial version

------------------------------------------------------------------------------@

CalcNewOrigin	proc	near
	class	OLPaneClass
	
	mov	bx, ds:[di].OLPI_pageWidth	;get window height
	mov	di, bx				;save bx
	shr	bx, 1				;divide page width by 2
	add	cx, bx				;add to page left
	adc	dx, 0
	mov	bx, di				;restore page width to bx
	mov	di, ss:[bp].MRVP_bounds.RD_right.low
	sub	di, ss:[bp].MRVP_bounds.RD_left.low
	shr	di, 1				;divide rect width by 2
	sub	cx, di				;account in direction calc...
	sbb	dx, 0
	
	mov	ax, ss:[bp].MRVP_bounds.RD_right.low 
		;get MRVP_bounds.DB_right.low-MRVP_bounds.RD_left.low-winLen
	sub	ax, ss:[bp].MRVP_bounds.RD_left.low	;result in ax
	sub	ax, bx				;subtract page width
	mov	bx, ax				;keep in bx
	clr	di				;now in di:bx
	tst	bx	
	jns	3$
	dec	di				
3$:
	test	ss:[bp].MRVP_xFlags, mask MRVF_USE_MARGIN_FROM_TOP_LEFT
	jnz	10$				;don't care about current
						;  position, branch to calc
						;  from left edge.
	cmp	dx, ss:[bp].MRVP_bounds.RD_left.high
	jg	10$
	jl	5$
	cmp	cx, ss:[bp].MRVP_bounds.RD_left.low	;see if scrolling up
	jae	10$				;no, branch
5$:
	;
	; Scrolling down (whatever that means.)
	;
	mov	cx, ss:[bp].MRVP_bounds.RD_left.low 
	mov	dx, ss:[bp].MRVP_bounds.RD_left.high
					;(use dx:cx to accumulate result)
	add	cx, bx				;add right-left-pageWidth
	adc	dx, di				
	neg	bx				;negate our right-left-pageWidth
	jmp	short 15$			;and branch to finish
10$:
	;
	; Scrolling up
	;
	mov	cx, ss:[bp].MRVP_bounds.RD_left.low 
	mov	dx, ss:[bp].MRVP_bounds.RD_left.high
15$:
	mov	ax, ss:[bp].MRVP_xMargin	;get the desired margin
	push	cx, dx				;save our current sum
	;
	; NOTE: because the percentage is unsigned 16-bit, but the
	; margin is signed 16-bit, we cannot use imul here.  Sign-extending
	; the result after using mul here is fraught with peril as well...
	;
	mov	cx, ax
	clr	dx				;dx.cx <- % of margin
	clr	ax				;bx.ax <- margin
	call	GrMulWWFixed			;dx.cx <- result
	mov	ax, dx				;ax <- result (sword)
	cwd					;sign-extend
	mov	bx, dx				;bx:ax <- result (sdword)

	pop	cx, dx				;restore current sum
	
	add	cx, ax				;add things
	adc	dx, bx
	ret
CalcNewOrigin	endp

ActionObscure	ends


ViewUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollUp -- 
		MSG_GEN_VIEW_SCROLL_UP for OLPaneClass

DESCRIPTION:	Scrolls document up one increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_UP

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollUp		method OLPaneClass, MSG_GEN_VIEW_SCROLL_UP
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	clr	bx				;no left-right scroll
	clr	ax
	mov	dx, ds:[di].GVI_increment.PD_y.high	;get vertical increment
	mov	cx, ds:[di].GVI_increment.PD_y.low
	call	DNegate					;make negative 
	mov	bp, SA_INC_BACK or mask OLPSF_VERTICAL 
	call	OLPaneScroll			;and scroll
	ret
OLPaneScrollUp		endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	DNegate

SYNOPSIS:	Negates a double precision number.

CALLED BY:	utility

PASS:		dx:cx -- number to negate

RETURN:		dx:cx -- negated number

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@

DNegate	proc	near
	negdw	dxcx
	ret
DNegate	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollDown -- 
		MSG_GEN_VIEW_SCROLL_DOWN for OLPaneClass

DESCRIPTION:	Scrolls document down one increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_DOWN

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@
	
OLPaneScrollDown	method OLPaneClass, MSG_GEN_VIEW_SCROLL_DOWN
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	clr	ax				;no left-right scroll
	clr	bx
	mov	dx, ds:[di].GVI_increment.PD_y.high	;get vertical increment
	mov	cx, ds:[di].GVI_increment.PD_y.low
	mov	bp, SA_INC_FWD or mask OLPSF_VERTICAL
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollDown	endp
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollLeft -- 
		MSG_GEN_VIEW_SCROLL_LEFT for OLPaneClass

DESCRIPTION:	Scrolls document left one increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_LEFT

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollLeft	method OLPaneClass, MSG_GEN_VIEW_SCROLL_LEFT
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	cx, ds:[di].GVI_increment.PD_x.low ;get horizontal increment
	mov	dx, ds:[di].GVI_increment.PD_x.high
	call	DNegate
	mov	ax, cx				;put in bx:ax
	mov	bx, dx
	clr	cx				;no vertical scroll
	clr	dx
	mov	bp, SA_INC_BACK			;horizontal
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollLeft	endm
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollRight -- 
		MSG_GEN_VIEW_SCROLL_RIGHT for OLPaneClass

DESCRIPTION:	Scrolls document right one increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_RIGHT

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollRight	method OLPaneClass, MSG_GEN_VIEW_SCROLL_RIGHT
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	clr	dx				;no up-down scroll
	clr	cx
	mov	ax, ds:[di].GVI_increment.PD_x.low ;get horizontal increment
	mov	bx, ds:[di].GVI_increment.PD_x.high
	mov	bp, SA_INC_FWD
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollRight	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollPageUp -- 
		MSG_GEN_VIEW_SCROLL_PAGE_UP for OLPaneClass

DESCRIPTION:	Scrolls document up one page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_PAGE_UP

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollPageUp	method OLPaneClass, MSG_GEN_VIEW_SCROLL_PAGE_UP
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	cx, ds:[di].OLPI_pageHeight	;get current page height
	clr	dx				;  in dx:cx
	call	DNegate				;make negative
	clr	ax				;no left-right scroll
	clr	bx
	mov	bp, SA_PAGE_BACK or mask OLPSF_VERTICAL
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollPageUp	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollPageDown -- 
		MSG_GEN_VIEW_SCROLL_PAGE_DOWN for OLPaneClass

DESCRIPTION:	Scrolls document down one page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_PAGE_DOWN

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@
	
OLPaneScrollPageDown	method OLPaneClass, MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	cx, ds:[di].OLPI_pageHeight	;get current page height
	clr	dx				;   in dx:cx
	clr	bx				;no left-right scroll
	clr	ax			
	mov	bp, SA_PAGE_FWD or mask OLPSF_VERTICAL
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollPageDown	endp
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollPageLeft -- 
		MSG_GEN_VIEW_SCROLL_PAGE_LEFT for OLPaneClass

DESCRIPTION:	Scrolls document left one page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_PAGE_LEFT

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollPageLeft	method OLPaneClass, MSG_GEN_VIEW_SCROLL_PAGE_LEFT
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	cx, ds:[di].OLPI_pageWidth	;get current page width
	clr	dx				;  in dx:cx
	call	DNegate
	mov	ax, cx				;now in bx:ax
	mov	bx, dx
	clr	dx				;no up-down scroll
	clr	cx
	mov	bp, SA_PAGE_BACK
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollPageLeft	endm
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollPageRight -- 
		MSG_GEN_VIEW_SCROLL_PAGE_RIGHT for OLPaneClass

DESCRIPTION:	Scrolls document right one page.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_PAGE_RIGHT

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollPageRight	method OLPaneClass, MSG_GEN_VIEW_SCROLL_PAGE_RIGHT
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	cx, ds:[di].OLPI_pageWidth	;get current page width
	clr	dx				;  in dx:cx
	mov	ax, cx				;now in bx:ax
	mov	bx, dx
	clr	dx				;no up-down scroll
	clr	cx
	mov	bp, SA_PAGE_FWD
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollPageRight	endp
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollTop -- 
		MSG_GEN_VIEW_SCROLL_TOP for OLPaneClass

DESCRIPTION:	Scrolls document to the top.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_TOP.

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollTop		method OLPaneClass, MSG_GEN_VIEW_SCROLL_TOP
	clr	ax
	mov	bx, DONT_SCROLL			;x position won't change
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GVI_docBounds.RD_top.high
	mov	cx, ds:[di].GVI_docBounds.RD_top.low

	mov	bp, SA_TO_BEGINNING or mask OLPSF_VERTICAL or \
				       mask OLPSF_ABSOLUTE
	GOTO	OLPaneScrollAbsolute
OLPaneScrollTop		endm
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollBottom -- 
		MSG_GEN_VIEW_SCROLL_BOTTOM for OLPaneClass

DESCRIPTION:	Scrolls document to the bottom

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_BOTTOM

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@
			
OLPaneScrollBottom	method OLPaneClass, MSG_GEN_VIEW_SCROLL_BOTTOM
	clr	ax
	mov	bx, DONT_SCROLL			;x position won't change
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GVI_docBounds.RD_bottom.high
	mov	cx, ds:[di].GVI_docBounds.RD_bottom.low
						;  will get fixed up to account
						;  for window size later...
	mov	bp, SA_TO_END or mask OLPSF_VERTICAL or mask OLPSF_ABSOLUTE
	GOTO	OLPaneScrollAbsolute		;do it
OLPaneScrollBottom		endm
				

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollLeftEdge -- 
		MSG_GEN_VIEW_SCROLL_LEFT_EDGE for OLPaneClass

DESCRIPTION:	Scrolls document to left edge.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_LEFT_EDGE

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@

OLPaneScrollLeftEdge		method OLPaneClass, MSG_GEN_VIEW_SCROLL_LEFT_EDGE
	clr	cx
	mov	dx, DONT_SCROLL			;y position won't change
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	bx, ds:[di].GVI_docBounds.RD_left.high
	mov	ax, ds:[di].GVI_docBounds.RD_left.low
	mov	bp, SA_TO_BEGINNING or mask OLPSF_ABSOLUTE
	GOTO	OLPaneScrollAbsolute		;do it
OLPaneScrollLeftEdge		endm
				

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollRightEdge -- 
		MSG_GEN_VIEW_SCROLL_RIGHT_EDGE for OLPaneClass

DESCRIPTION:	Scrolls document to the bottom

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_RIGHT_EDGE

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/11/89	Initial version

------------------------------------------------------------------------------@
			
OLPaneScrollRightEdge	method OLPaneClass, MSG_GEN_VIEW_SCROLL_RIGHT_EDGE
	clr	cx
	mov	dx, DONT_SCROLL			;y position won't change
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	bx, ds:[di].GVI_docBounds.RD_right.high
	mov	ax, ds:[di].GVI_docBounds.RD_right.low
	mov	bp, SA_TO_END or mask OLPSF_ABSOLUTE
	GOTO	OLPaneScrollAbsolute		;do it
OLPaneScrollRightEdge	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollSetXOrigin -- 
		MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN for OLPaneClass

DESCRIPTION:	Sets the x origin.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN
		dx:cx	- new x origin

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/91		Initial version

------------------------------------------------------------------------------@

OLPaneScrollSetXOrigin	method OLPaneClass, \
				MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN
	mov	ax, cx			;pass x value in bx:ax
	mov	bx, dx
	mov	dx, DONT_SCROLL		;say no change in y direction
	clr	cx
	mov	bp, SA_DRAGGING or mask OLPSF_ABSOLUTE 
	GOTO	OLPaneScrollAbsolute
OLPaneScrollSetXOrigin	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollSetYOrigin -- 
		MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN for OLPaneClass

DESCRIPTION:	Sets the y origin.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN
		dx:cx	- new y origin

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/91		Initial version

------------------------------------------------------------------------------@

OLPaneScrollSetYOrigin	method OLPaneClass, \
				MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN
	mov	bx, DONT_SCROLL			;say no change in x direction
	clr	ax
	mov	bp, SA_DRAGGING or mask OLPSF_ABSOLUTE 
	GOTO	OLPaneScrollAbsolute
OLPaneScrollSetYOrigin	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetOrigin --
		MSG_GEN_VIEW_SET_ORIGIN for OLPaneClass

DESCRIPTION:	Sets the 16-bit origin of the pane.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ss:bp   - DocOrigin

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/17/89		Initial version

------------------------------------------------------------------------------@

OLPaneSetOrigin	method OLPaneClass, MSG_GEN_VIEW_SET_ORIGIN
	mov	ax, ss:[bp].PD_x.low
	mov	bx, ss:[bp].PD_x.high
	mov	cx, ss:[bp].PD_y.low
	mov	dx, ss:[bp].PD_y.high
	
	mov	bp, SA_SCROLL or mask OLPSF_ABSOLUTE
	FALL_THRU	OLPaneScrollAbsolute
OLPaneSetOrigin	endm
	
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneScrollAbsolute

SYNOPSIS:	Scrolls to a specified location.

CALLED BY:	utility

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

		bx:ax	- 16-bit x origin (or DONT_SCROLL if keeping old value)
		dx:cx	- 16-bit y origin (or DONT_SCROLL if keeping old value)
		bp	- OLPortScrollFlags

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

DESTROYED:	ax,bx,cx,dx,bp,es,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/27/90		Initial version

------------------------------------------------------------------------------@

OLPaneScrollAbsolute	proc	far
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	;
	; If DONT_SCROLL has been passed, we keep the old scroll 
	; value in this direction.    10/19/90 cbh
	;
	cmp	bx, DONT_SCROLL
	jne	10$
	tst	ax
	jnz	10$
	mov	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high
	mov	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low
	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	jns	10$
	add	ax, 1				;round result appropriately
	adc	bx, 0
10$:
	cmp	dx, DONT_SCROLL		
	jne	30$
	tst	cx
	jnz	30$
	mov	dx, ds:[di].GVI_origin.PDF_y.DWF_int.high
	mov	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low
	tst	ds:[di].GVI_origin.PDF_y.DWF_frac.high
	jns	30$
	add	cx, 1				;round result appropriately
	adc	dx, 0
30$:
	call	MakeRelativeToOrigin		;make values relative
	call	OLPaneScroll			;and scroll
	ret
OLPaneScrollAbsolute	endp

ViewUncommon	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSpecPan -- 
		MSG_SPEC_VIEW_PAN for OLPaneClass

DESCRIPTION:	Pans the subview.  Basically a scroll with a different
		normalize scroll type.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_PAN
		cx, dx  - scroll amount

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/30/90		Initial version

------------------------------------------------------------------------------@

OLPaneSpecPan	method OLPaneClass, MSG_SPEC_VIEW_PAN
	mov	ax, cx
	clr	bx
	tst	ax
	jns	5$
	dec	bx
5$:
	mov	cx, dx
	clr	dx
	tst	cx
	jns	10$
	dec	dx
10$:
	mov	bp, SA_PAN			;panning
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneSpecPan	endm

ActionObscure	ends


ViewScroll	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSpecDragScroll -- 
		MSG_SPEC_VIEW_DRAG_SCROLL for OLPaneClass

DESCRIPTION:	Pans the subview.  Basically a scroll with a different
		normalize scroll type.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_DRAG_SCROLL
		cx, dx  - scroll amount

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/30/90		Initial version

------------------------------------------------------------------------------@

OLPaneSpecDragScroll	method OLPaneClass, MSG_SPEC_VIEW_DRAG_SCROLL
	mov	ax, cx
	clr	bx
	tst	ax
	jns	5$
	dec	bx
5$:
	mov	cx, dx
	clr	dx
	tst	cx
	jns	10$
	dec	dx
10$:
	
	mov	bp, SA_DRAG_SCROLL
	GOTO	OLPaneScroll			;and scroll, no special flags
OLPaneSpecDragScroll	endm

ViewScroll	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollMtd --
		MSG_GEN_VIEW_SCROLL for OLPaneClass

DESCRIPTION:	Scrolls a pane.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL
		ss:bp	- PointDWord:  amount to scroll

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/17/89		Initial version

------------------------------------------------------------------------------@

OLPaneScrollMtd		method OLPaneClass, MSG_GEN_VIEW_SCROLL
	mov	ax, ss:[bp].PD_x.low	
	mov	bx, ss:[bp].PD_x.high
	mov	cx, ss:[bp].PD_y.low	
	mov	dx, ss:[bp].PD_y.high	
	mov	bp, SA_SCROLL			;generic scroll
	call	OLPaneScroll			;and scroll, no special flags
	ret
OLPaneScrollMtd	endm

ActionObscure	ends


ViewScroll	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScrollLow -- 
		MSG_GEN_VIEW_SET_ORIGIN_LOW for OLPaneClass

DESCRIPTION:	Low level scroll.  Doesn't normalize or propagate to other
		views.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_ORIGIN_LOW
		
		ss:bp	- PointDWord: absolute new origin

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
	chris	10/16/91		Initial Version

------------------------------------------------------------------------------@

OLPaneScrollLow	method dynamic	OLPaneClass, MSG_GEN_VIEW_SET_ORIGIN_LOW
	mov	ax, ss:[bp].PD_x.low	
	mov	bx, ss:[bp].PD_x.high

	cmpdw	bxax, GVSOL_NO_CHANGE	;substitute cur value in certain
	jne	10$			;  circumstances
	call	GetXOrigin	
10$:
	mov	cx, ss:[bp].PD_y.low	
	mov	dx, ss:[bp].PD_y.high	

	cmpdw	dxcx, GVSOL_NO_CHANGE
	jne	20$
	call	GetYOrigin	
20$:
	call	MakeRelativeToOrigin

	mov	bp, SA_SCROLL or mask OLPSF_DONT_SEND_TO_LINKS or \
				 mask OLPSF_DONT_NORMALIZE
	GOTO	OLPaneScroll			;and scroll
	
OLPaneScrollLow	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	KeepOriginInBounds

SYNOPSIS:	Keeps origin within document's bounds.  Also sets pane flags
		if we're at the right or bottom edge.

CALLED BY:	OLPaneScroll, SetNewOrigin

PASS:		*ds:si -- pane handle
		bx:ax  -- x origin to check
		dx:cx  -- y origin to check

RETURN:		bx:ax  -- possibly updated x origin 
		dx:cx  -- possibly updated y origin
		di     -- right/bottom flags to "or" in, if caller wants to

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/27/90		Initial version

------------------------------------------------------------------------------@

KeepOriginInBounds	proc	near		uses	bp
	;
	; Do vertical dimension first.
	;
	.enter
	push	bx
	mov	bx, KVIB_VERTICAL		;pass vertical flag
	call	KeepValueInBounds		;keep y origin in bounds
	pop	bx				
	push	di				;save right/bot flag returned
	;
	; Now do horizontal.
	;
	xchg	ax, cx				;y origin in bx:ax
	xchg	bx, dx				;x origin in dx:cx
	push	bx
	clr	bx				;pass horizontal flag now
	call	KeepValueInBounds		;keep x origin in bounds
	pop	bx				
	xchg	ax, cx				;y origin back in dx:cx
	xchg	bx, dx				;x origin back in bx:ax
	pop	bp				;restore flag from vertical
	or	di, bp				;or into di
EC <	test	di, not (mask OLPF_AT_RIGHT_EDGE or mask OLPF_AT_BOTTOM_EDGE) >
EC <	ERROR_NZ	OL_VIEW_KEEP_ORIGIN_IN_BOUNDS_BAD_FLAGS_RETURNED      >
   	.leave
	ret
KeepOriginInBounds	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	KeepValueInBounds

SYNOPSIS:	Keeps an x or y value in bounds.

CALLED BY:	OLPaneKeepOriginInBounds

PASS:		*ds:si -- pane handle
		dx:cx -- value
		bx    -- 0 if value is horizontal,
			 KVIB_VERTICAL if value is vertical

RETURN:		cx:dx -- value, possibly update to keep in bounds
		di -- OLPaneFlags flags to "or" in (top/bottom flags)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@
KVIB_VERTICAL	equ	2

CheckHack <(offset OLPI_pageHeight - offset OLPI_pageWidth) eq KVIB_VERTICAL>
CheckHack <(offset GVI_docBounds.RD_top - offset GVI_docBounds.RD_left) \
	eq (KVIB_VERTICAL * 2)>

KeepValueInBounds	proc	near
	uses	ax, bx, bp
	clr	di				;no flags set yet
	.enter
EC <	cmp	bx, KVIB_VERTICAL			>
EC <	ERROR_A	OL_VIEW_BAD_FLAG_PASSED_TO_KEEP_VALUE_IN_BOUNDS >
   
	push	bx				;save our vertical flag
 	mov	bp, ds:[si]			;point to instance
	add	bp, ds:[bp].Vis_offset		;ds:[di] -- SpecInstance
	add	bp, bx
	mov	ax, ds:[bp].OLPI_pageWidth	;get current page dimension
	neg	ax				;make size negative
	shl	bx, 1				;multiply vertical flag by 2
	mov	bp, ds:[si]			;point to SpecInstance
	add	bp, ds:[bp].Gen_offset		;point to generic pane
	add	bp, bx				;add vertical offset, if any
	mov	bx, 0ffffh			;sign extend ax to dword bx:ax

	;
	; Subtract window height from maximum before checking it with the 
	; value passed.  If the document is too small to fit onscreen, we'll
	; return the minimum.
	;
	add	ax, ds:[bp].GVI_docBounds.RD_right.low
	adc	bx, ds:[bp].GVI_docBounds.RD_right.high
	
	cmp	bx, ds:[bp].GVI_docBounds.RD_left.high
	jl	returnMinAndExit		;high word <> minimum, exit
	jg	10$
	cmp	ax, ds:[bp].GVI_docBounds.RD_left.low
	jbe	returnMinAndExit		;yes, return min and exit
10$:
	xchg	ax, cx				;max now in dx:cx,
	xchg	bx, dx				;value now in bx:ax
	
	cmp	bx, ds:[bp].GVI_docBounds.RD_left.high
	jg	checkMax
	jl	returnMinAndExit
	cmp	ax, ds:[bp].GVI_docBounds.RD_left.low
	jae	checkMax			;everything cool, go check max
	
returnMinAndExit:
	mov	bx, ds:[bp].GVI_docBounds.RD_left.high
	mov	ax, ds:[bp].GVI_docBounds.RD_left.low
	jmp	short done			;return minimum, in bx:ax
	
checkMax:
	cmp	bx, dx				;see if past maximum - pageWidth
	jl	done
	jg	returnMax
	cmp	ax, cx
	jb	done				;not over max, we're done
	
returnMax:
	mov	bx, dx				;return maximum - page width
	mov	ax, cx
	mov	di, mask OLPF_AT_RIGHT_EDGE	;assume setting horizontal flag
	pop	dx				;restore vertical flag
	tst	dl				;doing horizontal?
	jz	doneFlagPopped			;yes, done
	mov	di, mask OLPF_AT_BOTTOM_EDGE	;set vertical equivalent
	jmp	short doneFlagPopped		;exit, (bx already popped)
done:
	pop	dx				;unload vertical flag
	
doneFlagPopped:
	mov	cx, ax				;return in dx:cx
	mov	dx, bx		
	.leave
	ret
KeepValueInBounds	endp

		


COMMENT @----------------------------------------------------------------------

ROUTINE:	StoreNewOrigin

SYNOPSIS:	Stores a new origin.

CALLED BY:	OLPaneScroll, SetNewOrigin

PASS:		*ds:si -- pane
		bx:ax  -- x origin to store
		dx:cx  -- y origin to store

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 6/91		Initial version

------------------------------------------------------------------------------@

StoreNewOrigin	proc	near
	mov	di, ds:[si]			 ;point to instance
	add	di, ds:[di].Gen_offset		 ;ds:[di] -- GenInstance
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.low, ax ;store new abs values
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.high, bx
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.low, cx 
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.high, dx 
	ret
StoreNewOrigin	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SendNewOriginToOD

SYNOPSIS:	Sends new origin to OD.

CALLED BY:	OLPaneScroll

PASS:		*ds:si -- pane
		bx:ax  -- x origin (the integer portion only)
		dx:cx  -- y origin (the integer portion only)

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@

SendNewOriginToOD	proc	far		uses	bp, cx, dx, ax, bx
	.enter

	;
	; Round the integer values based on the fraction, in an attempt to
	; make things better.  They've already been set if they changed during
	; a WinScroll.  -cbh 3/30/93
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GVI_origin.PDF_x.DWF_frac
	jns	10$
	incdw	bxax
10$:	
	tst	ds:[di].GVI_origin.PDF_y.DWF_frac
	jns	20$
	incdw	dxcx
20$:	
	sub	sp, size OriginChangedParams	;tell OD our origin changed
	mov	bp, sp
	mov	ss:[bp].OCP_origin.PD_x.low, ax		;origin in ss:bp
	mov	ss:[bp].OCP_origin.PD_x.high, bx
	mov	ss:[bp].OCP_origin.PD_y.low, cx
	mov	ss:[bp].OCP_origin.PD_y.high, dx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_window
	mov	ss:[bp].OCP_window, di
	mov	dx, size OriginChangedParams
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
;	mov	di, mask MF_STACK 
	mov	ax, MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
	call	ToAppCommon
	add	sp, size OriginChangedParams
	.leave
	ret
SendNewOriginToOD	endp

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	MakeRelativeToOrigin

SYNOPSIS:	Makes the value passed in relative to the current origin

CALLED BY:	OLPaneScroll

PASS:		*ds:si -- pane
		bx:ax  -- proposed x origin
		dx:cx  -- proposed y origin

RETURN:		bx:ax  -- relative x change from current origin
		dx:cx  -- relative y change from current origin

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@

MakeRelativeToOrigin	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset

	; want to round appropriately.  

	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	jns	subX
	decdw	bxax
subX:
	sub	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low	;use rel values
	sbb	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high

	tst	ds:[di].GVI_origin.PDF_y.DWF_frac.high
	jns	subY
	decdw	dxcx
subY:
	sub	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low
	sbb	dx, ds:[di].GVI_origin.PDF_y.DWF_int.high
	ret
MakeRelativeToOrigin	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	MakeRelativeWWFixed

SYNOPSIS:	Makes the value passed in relative to the current origin

CALLED BY:	OLPaneScroll

PASS:		*ds:si -- pane
		bx:ax  -- proposed x origin
		dx:cx  -- proposed y origin

RETURN:		dx.cx  -- neg relative x change from current origin (WWFixed)
		bx.ax  -- neg relative y change from current origin (WWFixed)

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: This routine assumes that the relative scroll will be
		      less than 64K

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/ 5/91		Initial version

------------------------------------------------------------------------------@

MakeRelativeWWFixed	proc	near
	uses	di
	.enter
	mov	dx, ax			; setup WWFixed values
	mov	bx, cx
	clr	ax			; clear fractions
	clr	cx

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset

	; the math is easy now...

	sub	cx, ds:[di].GVI_origin.PDF_x.DWF_frac
	sbb	dx, ds:[di].GVI_origin.PDF_x.DWF_int.low	;use rel values
	sub	ax, ds:[di].GVI_origin.PDF_y.DWF_frac
	sbb	bx, ds:[di].GVI_origin.PDF_y.DWF_int.low

	; negate the result -- it is only being passed to WinScroll 
	; and WinApplyTranslation

	neg	cx			; NegateFixed dx, cx
	not	dx
	cmc
	adc	dx, 0
	neg	ax			; NegateFixed bx, ax
	not	bx
	cmc
	adc	bx, 0
	.leave
	ret
MakeRelativeWWFixed	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	MakeScrollAmountAbsolute

SYNOPSIS:	Get an absolute scroll amount.

CALLED BY:	OLPortScroll

PASS:		*ds:si -- pane
		bx:ax  -- relative x amount
		dx:cx  -- relative y amount

RETURN:		bx:ax  -- absolute x value, based on current origin
		dx:cx  -- absolute y value, based on current origin

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@

MakeScrollAmountAbsolute	proc	near
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance

	; we want to round appropriately

	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	jns	addX
	add	ax, 1				;fixed 10/21/91 cbh
	adc	bx, 0		
addX:
	add	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low	;make absolute 
	adc	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high	

	tst	ds:[di].GVI_origin.PDF_y.DWF_frac.high
	jns	addY
	add	cx, 1				;fixed 10/21/91 cbh
	adc	dx, 0
addY:
	add	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low
	adc	dx, ds:[di].GVI_origin.PDF_y.DWF_int.high
	ret
MakeScrollAmountAbsolute	endp








COMMENT @----------------------------------------------------------------------

ROUTINE:	SendScrollTrackingMethod

SYNOPSIS:	Sends out scroll tracking method for the pane.

CALLED BY:	OLPaneScrollIntoPane

PASS:		*ds:si -- pane handle
		bx:ax  -- suggested amount to scroll horizontally
		dx:cx  -- suggested amount to scroll vertically
		bp     -- OLPortScrollFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/90		Initial version

------------------------------------------------------------------------------@

SendTrackScrollingMethod	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GVI_content.handle	;is there a content?
	LONG	jz	exit			;no, just exit

	xchg	ax, bp				;flags in ax, x scroll in bp
	mov	ah, al				;put lower 8 bits in ah
	and	al, mask OLPSF_SCROLL_ACTION    ;scroll action in al
	and	ah, mask SF_VERTICAL or mask SF_ABSOLUTE or \
		    mask SF_DOC_SIZE_CHANGE	;scroll flags in ah
	
	call	OLPaneSuspendUpdate		;suspend window drawing...
	LONG	jnc	exit			;couldn't suspend, get out
						;  (couldn't-flag set)

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	inc	ds:[di].OLPI_normalizeCount	;one more normalize happening
	
	mov	di, ax				;flags in di
	mov	ax, bp				;x scroll back in bp
	
	sub	sp, size TrackScrollingParams	;set up args on stack
	mov	bp, sp				;bp points to bottom of struct
	mov	ss:[bp].TSP_change.PD_x.low, ax
	mov	ss:[bp].TSP_change.PD_x.high, bx
	mov	ss:[bp].TSP_change.PD_y.low, cx
	mov	ss:[bp].TSP_change.PD_y.high, dx
	
	mov	ax, di				;flags in ax
	mov	ss:[bp].TSP_action, al		;store action
	mov	ss:[bp].TSP_flags, ah		;store flags
	
	  	;
	; Assume we want to pass this as destroyed.
	;
EC <	mov	ss:[bp].TSP_newOrigin.PD_x.high, 8000h 			       >
EC <	mov	ss:[bp].TSP_newOrigin.PD_y.high, 8000h			       >
   	;
   	; If this is an absolute scroll, we'll set up the newOrigin with the
	; correct args.
	;
	test	ss:[bp].TSP_flags, mask SF_ABSOLUTE
	jz	10$				;not absolute, we're set
	segmov	es, ss
	call	SetupOldOrigin			;set up old origin from instdata
	call	SetupNewOrigin			;set up new origin from change
	
EC <	mov	ss:[bp].TSP_change.PD_x.high, 8000h ;not valid for abs scr  >
EC <	mov	ss:[bp].TSP_change.PD_y.high, 8000h		            >
10$:
	;
	; Set up some garbage, as some of these are returned invalid and not
	; set until we reach the application thread and call GenSetupNormalize-
	; Args.
	;
EC <	mov	ss:[bp].TSP_oldOrigin.PD_x.high, 8000h 			       >
EC <	mov	ss:[bp].TSP_oldOrigin.PD_y.high, 8000h			       >
EC <	mov	ss:[bp].TSP_viewWidth, 8000h			      	       >
EC <	mov	ss:[bp].TSP_viewHeight, 8000h			      	       >
	;
	; Set this flag now so no more select-scrolls will be started while
	; we're off normalizing the position.
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; get ptr to SpecificInstance
	or	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_PENDING
	
	;
	; Set the kbd char flag appropriately.   6/15/94 cbh
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_KBD_CHAR_SCROLL
	jz	20$
	or	ss:[bp].TSP_flags, mask SF_KBD_RELATED_SCROLL
20$:

	mov	cx, ds:[LMBH_handle]		;store block handle
	mov	ss:[bp].TSP_caller.handle, cx
	mov	ss:[bp].TSP_caller.chunk, si
	mov	ax, MSG_META_CONTENT_TRACK_SCROLLING 
						;send to ourselves, which by
	call	ObjCallInstanceNoLock		;  default will go to OD...
	add	sp, size TrackScrollingParams	;unload arguments

	pop	di
	call	ThreadReturnStackSpace

exit:
	ret
SendTrackScrollingMethod	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetupTrackingArgs -- 
		MSG_GEN_VIEW_SETUP_TRACKING_ARGS for OLPaneClass

DESCRIPTION:	Sets up bounds in TrackScrollingParams.  Called by a
		MSG_META_CONTENT_TRACK_SCROLLING handler to fill out missing arguments.
		Also gets the value in bounds, for the hell of it.

PASS:		*ds:si 	- instance data
		cx:dx   - TrackScrollingParams
		
RETURN:		cx:[bp].TSP_oldOrigin -- updated
		cx:[bp].TSP_viewWidth -- updated
		cx:[bp].TSP_viewHeight -- updated
		ax, dx -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/26/90		Initial version

------------------------------------------------------------------------------@

OLPaneSetupTrackingArgs	method dynamic OLPaneClass,
					MSG_GEN_VIEW_SETUP_TRACKING_ARGS
	mov	bp, dx
	mov	es, cx				;es:bp points to track scrolling
	
	mov	ax, ds:[di].OLPI_pageWidth	;get current page width
	mov	es:[bp].TSP_viewWidth, ax
	
	mov	ax, ds:[di].OLPI_pageHeight	;get current page height
	mov	es:[bp].TSP_viewHeight, ax
	
	call	SetupOldOrigin			;set up based on instance data
	test	es:[bp].TSP_flags, mask SF_ABSOLUTE	
	jnz	10$				; absolute, new origin set up
	call	SetupNewOrigin			; else set up based on change
10$:
	call	GetNewOrigin			; new origin in bx.ax, dx.cx
	push	bp
	call	KeepOriginInBounds		;do bounds checking
	pop	bp
	mov	es:[bp].TSP_newOrigin.PD_x.low, ax
	mov	es:[bp].TSP_newOrigin.PD_x.high, bx
	mov	es:[bp].TSP_newOrigin.PD_y.low, cx
	mov	es:[bp].TSP_newOrigin.PD_y.high, dx

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_SCALE_TO_FIT
	jz	noScaleToFit
	ornf	es:[bp].TSP_flags, mask SF_SCALE_TO_FIT
noScaleToFit:

	;
	; Update change based on the keeping in bounds.
	;
	call	MakeRelativeToOldOrigin
	ornf	es:[bp].TSP_flags, mask SF_SETUP_HAPPENED		    
EC <	Destroy	ax, dx					;destroy things	    >
	ret
OLPaneSetupTrackingArgs	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetNewOrigin

SYNOPSIS:	Gets new origin.

CALLED BY:	OLPaneSetupTrackingArgs, OLPaneTrackingComplete

PASS:		es:bp -- TrackScrollingParams

RETURN:		bx.ax -- new x origin from args
		dx.cx -- new y origin from args

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

GetNewOrigin	proc	near
	mov	ax, es:[bp].TSP_newOrigin.PD_x.low
	mov	bx, es:[bp].TSP_newOrigin.PD_x.high
	mov	cx, es:[bp].TSP_newOrigin.PD_y.low
	mov	dx, es:[bp].TSP_newOrigin.PD_y.high
	ret
GetNewOrigin	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	MakeRelativeToOldOrigin

SYNOPSIS:	Makes scroll values relative to the oldOrigin.

CALLED BY:	OLPaneSetupTrackingArgs, OLPaneReturnTrackingArgs

PASS:		es:bp -- TrackScrollingParams
		cx.dx -- y origin to make relative to old origin
		bx.ax -- x origin to make relative to old origin

RETURN:		es:[bp].TSP_change -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/23/92		Initial version

------------------------------------------------------------------------------@

MakeRelativeToOldOrigin	proc	near
	sub	cx, es:[bp].TSP_oldOrigin.PD_y.low
	mov	es:[bp].TSP_change.PD_y.low, cx
	sbb	dx, es:[bp].TSP_oldOrigin.PD_y.high
	mov	es:[bp].TSP_change.PD_y.high, dx
	
	sub	ax, es:[bp].TSP_oldOrigin.PD_x.low
	mov	es:[bp].TSP_change.PD_x.low, ax
	sbb	bx, es:[bp].TSP_oldOrigin.PD_x.high
	mov	es:[bp].TSP_change.PD_x.high, bx
	ret
MakeRelativeToOldOrigin	endp


		


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupOldOrigin

SYNOPSIS:	Sets up old and new origins, looking at instance data and 
		suggested change.

CALLED BY:	OLPaneGetInfo

PASS:		*ds:si  -- view
		es:[bp] -- TrackScrollingParams

RETURN:		TrackScrollingParams updated
		bx:ax -- old x origin
		dx:cx -- old y origin

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/91		Initial version

------------------------------------------------------------------------------@

SetupOldOrigin	proc	near
	call	GetXOrigin			;in bx:ax
	call	GetYOrigin			;in dx:cx
	mov	es:[bp].TSP_oldOrigin.PD_x.low, ax
	mov	es:[bp].TSP_oldOrigin.PD_x.high, bx
	mov	es:[bp].TSP_oldOrigin.PD_y.low, cx
	mov	es:[bp].TSP_oldOrigin.PD_y.high, dx
	ret
SetupOldOrigin	endp	
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupNewOrigin

SYNOPSIS:	Sets up new origin based on old origin and change.

CALLED BY:	OLPaneGetInfo, SendTrackScrollingMethod

PASS:		ss:bp -- TrackScrollingParams
		bx:ax -- old x origin
		dx:cx -- old y origin

RETURN:		ss:[bp].TSP_newOrigin -- updated
		bx:ax -- new x origin
		dx:cx -- new y origin

DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/91		Initial version

------------------------------------------------------------------------------@

SetupNewOrigin	proc	near
	add	cx, es:[bp].TSP_change.PD_y.low
	mov	es:[bp].TSP_newOrigin.PD_y.low, cx
	adc	dx, es:[bp].TSP_change.PD_y.high
	mov	es:[bp].TSP_newOrigin.PD_y.high, dx
	
	add	ax, es:[bp].TSP_change.PD_x.low
	mov	es:[bp].TSP_newOrigin.PD_x.low, ax
	adc	bx, es:[bp].TSP_change.PD_x.high
	mov	es:[bp].TSP_newOrigin.PD_x.high, bx
	ret
SetupNewOrigin	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneNormalizeComplete -- 
		MSG_GEN_VIEW_TRACKING_COMPLETE for OLPaneClass

DESCRIPTION:	Finishes normalizes for initial position and scroll into
		subview.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_TRACKING_COMPLETE
		ss:bp   - TrackScrollingParams
		dx	- size TrackScrollingParams

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/90		Initial version

------------------------------------------------------------------------------@

OLPaneTrackingComplete	method OLPaneClass, MSG_GEN_VIEW_TRACKING_COMPLETE

EC <	test	ss:[bp].TSP_flags, mask SF_EC_SETUP_CALLED		>
EC <	ERROR_Z	OL_VIEW_TRACK_SCROLLING_HANDLER_DID_NOT_CALL_SETUP	>
   
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	tst	ds:[di].OLPI_normalizeCount	;if currently zero, we'll assume
	jz	done				;  this normalize complete is
						;  from a previous incarnation.
	dec	ds:[di].OLPI_normalizeCount	;else decrement the counter
	
	call	OLPaneUnSuspendUpdate		;suspend redraws

	;
	; Setup did not occur (probably the View hadn't been built or something)
	; so we'll throw away the message.  -cbh 2/18/93
	;
	test	ss:[bp].TSP_flags, mask SF_SETUP_HAPPENED		
	jz	done

	;
	; If an absolute scroll, we'll use the newOrigin passed back, rather
	; than the change, because of the problem of consecutive absolute
	; scrolls that might come back together, the first one screwing up
	; the second one.  (Imagine two vertical scrolls from 60 to 45, both
	; get tracked by the content consecutively, both returning a change of
	; -15 because the oldOrigin doesn't change until the first one 
	; completes.)  -cbh 3/23/92
	;
	segmov	es, ss
	test	es:[bp].TSP_flags, mask SF_ABSOLUTE	
	jz	10$				; relative, just use change
	call	SetupOldOrigin			; old origin <- doc bounds
	call	GetNewOrigin			; new origin in bx.ax, dx.cx
	call	MakeRelativeToOldOrigin		; make relative
10$:
	mov	ax, ss:[bp].TSP_change.PD_x.low	;get relative scroll amount
	mov	bx, ss:[bp].TSP_change.PD_x.high
	mov	cx, ss:[bp].TSP_change.PD_y.low
	mov	dx, ss:[bp].TSP_change.PD_y.high
20$:	
	test	ss:[bp].TSP_flags, mask SF_DOC_SIZE_CHANGE
	push	bp
	;
	; For some reason we always want to update the scrollbars.  I know that
	; in the case of SetDocSize, the scrollbar will need to be redrawn
	; even though the document offset doesn't change because it probably
	; didn't redrawn when the MSG_SET_DOC_BOUNDS was sent because the
	; offsets were made invalid.  Right.  We also don't want to normalize,
	; so we don't pass a scroll type.
	;
	mov	bp, mask OLPSF_ALWAYS_UPDATE_SCROLLBARS	   
	call	OLPaneScroll			;scroll 'em
	pop	bp
	
	test	ss:[bp].TSP_flags, mask SF_DOC_SIZE_CHANGE
	jz	afterDocSize			;not changing doc size, branch
	push	bp
	call	OLPaneFinishSetDocSize		;else finish the job
	pop	bp
afterDocSize:

	; Finally, check to see if this was the INITIAL_POS method that we've
	; been waiting for.  If so, UnSuspendUpdate the window.
	;
	cmp	ss:[bp].TSP_action, SA_INITIAL_POS
	jne	done

	mov	ax, MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN
	call	ScrollPaneGetWindowID
	mov	bx, ds:[LMBH_handle]
	mov	cx, mask MF_FORCE_QUEUE		; Send via queue to
						; force same
	xchg	cx, di		
	call	ObjMessage			;   ordering with content 
						;   messages whether content
						;   run by UI or not (they are
						;   also sent FORCE_QUEUE)
						;   7/15/92 -cbh 
done:
EC <	Destroy	ax, cx, dx, bp			;destroy things	    >
	ret
	
OLPaneTrackingComplete	endm

					
ScrollPaneGetWindowID	proc	near
	mov	di, ds:[si]			;can be called directly
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_windowID
	ret
ScrollPaneGetWindowID	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneTrackScrolling -- 
		MSG_META_CONTENT_TRACK_SCROLLING for OLPaneClass

DESCRIPTION:	Track the pane scrolling.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_TRACK_SCROLLING
		ss:bp   - TrackScrollingParams, with
				suggested scroll values in TSP_change
		dx	- size TrackScrollingParams
		cx	- scrollbar handle

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/13/90		Initial version

------------------------------------------------------------------------------@

OLPaneTrackScrolling	method OLPaneClass, MSG_META_CONTENT_TRACK_SCROLLING
	;
	; Even if we're not going between different threads, we will force the
	; call to the queue, since we're doing that elsewhere.
	;
	mov	dx, size TrackScrollingParams	;pass size of struct in dx
	mov	ax, MSG_META_CONTENT_TRACK_SCROLLING
;	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	di, mask MF_STACK 
	call	ToAppCommon
	ret
OLPaneTrackScrolling	endm

ViewScroll	ends
			

InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetDocBounds -- 
		MSG_GEN_VIEW_SET_DRAG_BOUNDS for OLPaneClass

DESCRIPTION:	Sets new document bounds.  Generic handler will set instance
		data, then pass on the specific UI for processing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_DRAG_BOUNDS
		ss:bp   - RectDWord: new scrollable bounds

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

OLPaneSetDragBounds	method OLPaneClass, MSG_GEN_VIEW_SET_DRAG_BOUNDS
if	ERROR_CHECK
	push	cx
	mov	cx, ss:[bp].RD_left.high
	cmp	cx, ss:[bp].RD_right.high
	ERROR_G	OL_VIEW_BAD_DRAG_BOUNDS
	jl	EC10
	mov	cx, ss:[bp].RD_left.low
	cmp	cx, ss:[bp].RD_right.low 
	ERROR_A	OL_VIEW_BAD_DRAG_BOUNDS
EC10:
	mov	cx, ss:[bp].RD_top.high
	cmp	cx, ss:[bp].RD_bottom.high
	ERROR_G	OL_VIEW_BAD_DRAG_BOUNDS
	jl	EC20
	mov	cx, ss:[bp].RD_top.low
	cmp	cx, ss:[bp].RD_bottom.low 
	ERROR_A	OL_VIEW_BAD_DRAG_BOUNDS
EC20:
	pop	cx
endif
	
	clr	bx				;keep offset into instance data
	clr	cx				;keep a bounds flag
10$:
	mov	ax, {word} ss:[bp]		;store bounds word
	tst	ax				;word is zero, branch
	jz	15$
	inc	cx				;else signal that we have bounds
15$:
	mov	{word} ds:[di].OLPI_dragBounds, ax
20$:
	add	bx, 2				;bump counter
	add	bp, 2				;and stack buffer pointer
	add	di, 2				;and instance data pointer
	cmp	bx, size RectDWord		;done everything?
	jb	10$				;no, loop
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLPI_optFlags, not mask OLPOF_LIMIT_DRAG_SCROLLING
	tst	cx				;see if any bounds set
	jz	exit				;nope, done
	or	ds:[di].OLPI_optFlags, mask OLPOF_LIMIT_DRAG_SCROLLING
exit:
	Destroy	ax, cx, dx, bp			;trash things	    
	ret
OLPaneSetDragBounds	endm

InstanceObscure	ends

Resident	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetXOrigin, GetYOrigin

SYNOPSIS:	Returns x or y origin.

CALLED BY:	utility

PASS:		*ds:si -- pane

RETURN:		bx:ax -- current x origin  (for GetXOrigin)
		dx:cx -- current y origin  (for GetYOrigin)

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
			 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/91		Initial version

------------------------------------------------------------------------------@

GetXOrigin	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low		
	mov	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high	

	; round integer result appropriately

	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	jns	done
	add	ax, 1
	adc	bx, 0
done:
	ret
GetXOrigin	endp

GetYOrigin	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low		
	mov	dx, ds:[di].GVI_origin.PDF_y.DWF_int.high	

	; round integer result appropriately

	tst	ds:[di].GVI_origin.PDF_y.DWF_frac.high
	jns	done
	add	cx, 1
	adc	dx, 0
done:
	ret
GetYOrigin	endp


Resident	ends
