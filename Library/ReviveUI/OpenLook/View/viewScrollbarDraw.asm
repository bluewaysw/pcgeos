COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/View
FILE:		viewScrollbarDraw.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/90		Split off from scrollbar file

DESCRIPTION:

	$Id: viewScrollbarDraw.asm,v 1.1 97/04/07 10:56:26 newdeal Exp $

-------------------------------------------------------------------------------@


DrawColor segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorScrollbar, UpdateColorScrollbar

DESCRIPTION:	Draw an OL Scrollbar on a color display.  Update is the same
		but passes slightly different arguments to OpenTrace.
		(Update is used to draw only the cables.)

CALLED BY:	INTERNAL
		OLScrollbarDraw

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	cl - color scheme
	ch - DrawFlags:  DF_UPDATE set if updating
	di - GState to use

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, di, si, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

------------------------------------------------------------------------------@



DrawColorScrollbar	proc	far
	mov	ax, cx
	mov	bx, dx
	segmov	es, ds, dx
	segmov	ds, cs, dx
	mov	si, offset scrollbarData	;pass our trace data
	call	OpenTrace
	segmov	ds, es, dx			;get ds restored
	ret
DrawColorScrollbar	endp

UpdateColorScrollbar	proc	far
	mov	ax, cx
	mov	bx, dx
	segmov	es, ds, dx
	segmov	ds, cs, dx
	mov	[bp].SA_elevSkip, ELEV_SKIP	;skip elevator stuff
	mov	[bp].SA_anchorSkip, ANCHOR_SKIP	;and anchors
	mov	si, offset scrollbarUpdateData	;pass our trace data
	call	OpenTrace
	ret
UpdateColorScrollbar	endp




DrawColor ends


DrawBW segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWScrollbar, UpdateBWScrollbar

DESCRIPTION:	Draw an OL Scrollbar on a black and white display.  Updates
		does the same thing as draw but passes a couple of slightly
		different arguments to OpenTrace.
		(Update is used to draw only the cables.)

CALLED BY:	OLScrollbarDraw

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ch - DrawFlags:  DF_UPDATE set if updating
	di - GState to use

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

------------------------------------------------------------------------------@



DrawBWScrollbar	proc	far
	class	OLScrollbarClass
	
	mov	ax, cx
	mov	bx, dx
	segmov	es, ds, dx
	segmov	ds, cs, dx
	tst	[bp].SA_dragAreaSkip			;see if skipping drags
	jz	10$					;no, branch
	mov	[bp].SA_dragAreaSkip, DRAG_AREA_SKIP_BW	;else use B/W constant
10$:
	tst	[bp].SA_anchorSkip			;see if skipping anchor
	jz	20$					;no, branch
	mov	[bp].SA_anchorSkip, ANCHOR_SKIP_BW	;else use B/W constant
20$:
	mov	si, offset scrollbarBWData		;pass our trace data
	call	OpenTraceBW
	segmov	ds, es, dx				;get ds restored
	ret
DrawBWScrollbar	endp


UpdateBWScrollbar	proc	far
	class	OLScrollbarClass
	
	mov	ax, cx
	mov	bx, dx
	segmov	es, ds, dx
	segmov	ds, cs, dx
	mov	[bp].SA_elevSkip, ELEV_SKIP_BW		;skip elevator stuff
	mov	[bp].SA_anchorSkip, ANCHOR_SKIP_BW	;and anchors
	
	tst	[bp].SA_dragAreaSkip			;see if skipping drags
	jz	10$					;no, branch
	mov	[bp].SA_dragAreaSkip, DRAG_AREA_SKIP_BW	;else use B/W constant
10$:
	tst	[bp].SA_anchorSkip			;see if skipping anchor
	jz	20$					;no, branch
	mov	[bp].SA_anchorSkip, ANCHOR_SKIP_BW	;else use B/W constant
20$:
	mov	si, offset scrollbarUpdateBWData	;pass our trace data
	call	OpenTraceBW
	ret
UpdateBWScrollbar	endp

			
DrawBW			ends

ScrollbarCommon	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetScrollDrawParams

SYNOPSIS:	Sets up parameters for OpenTrace.

CALLED BY:	OLScrollbarDraw

PASS:		*ds:si -- scrollbar handle
		ss:bp  -- ScrollArgs -- arguments to pass to OpenTrace

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/29/90		Initial version

------------------------------------------------------------------------------@


SetScrollDrawParams	proc	near	
	class	OLScrollbarClass
	
	push	si				;save pointer to instance
	add	si, ds:[si].Vis_offset
	mov	al, MASK_50			;assume not enabled, use 50%
	ANDNF	ds:[si].OLSBI_attrs, not mask OLSA_DRAWN_ENABLED
	test	ds:[si].OLSBI_attrs, mask OLSA_ENABLED
	jz	2$				;not enabled, branch
	or	ds:[si].OLSBI_attrs, mask OLSA_DRAWN_ENABLED
	mov	al, MASK_100			;enabled, use 100% pattern
2$:
	mov	[bp].SA_mask, al		;set overall mask
	mov	[bp].SA_downArrowArrowPat, al	;set down-arrow mask
	mov	[bp].SA_upArrowArrowPat, al	;set up-arrow mask

	mov	al, ds:[si].OLSBI_state		;get rotated flag
	clr	ah				;assume not rotated
	test	ds:[si].OLSBI_attrs, mask OLSA_VERTICAL	  ;see if vertical
	jz	3$				;nope, branch
	mov	ah, mask TRF_ROTATED		;else pass rotated flag
3$:
	mov	[bp].TA_flags, ah		;store
	and	al, mask OLSS_DOWN_FLAGS	;look at just the down flags
	mov	[bp].TA_state, al		;nothing selected
	;
 	; Calculate lengths of cables.  First, set defaults.
	;
	mov	[bp].SA_elevHt, ELEV_HEIGHT-2
	mov	[bp].SA_offShadow, -7
	mov	[bp].SA_offBotShadow, -6
	mov	[bp].SA_offShadowRet, 12

	clr	ax
	mov	[bp].SA_anchorSkip, al
	mov	word ptr [bp].SA_elevSkip, ax		;two bytes at once
	mov	word ptr [bp].SA_skewedPositive, ax	;two bytes at once

	inc	al
	inc	al
	mov	ah, al
	mov	word ptr [bp].SA_offGreyCable, ax	;ditto
	mov	word ptr [bp].SA_offGrey2Cable, ax	;ditto
	inc	al
	mov	[bp].SA_offElev, al

	;
	; If a twisted scrollbar, set everything up so it will work right.
	;
	test	ds:[si].OLSBI_attrs, mask OLSA_TWISTED
	jz	1999$
	mov	[bp].SA_skewedPositive, 1	;else set to 1 if twisted
	mov	[bp].SA_skewedNegative, -1	;set to -1
1999$:
	
	test	ds:[si].OLSBI_state, mask OLSS_AT_TOP
	jz	4$				 ;branch if not at top
	mov	[bp].SA_upArrowArrowPat, MASK_50 ;else grey out up-arrow
4$:
	test	ds:[si].OLSBI_state, mask OLSS_AT_BOTTOM
	jz	400$				   ;branch if not at bottom
	mov	[bp].SA_downArrowArrowPat, MASK_50 ;else grey out down-arrow
400$:
	;
	; Make adjustments if this is a horizontal scrollbar
	;
	test	[bp].TA_flags, mask TRF_ROTATED	;see if vertical (rotated)
	jnz	5$				;yes, branch
	mov	[bp].SA_offShadow, 5
	mov	[bp].SA_offShadowRet, -1
	mov	[bp].SA_offBotShadow, -5
5$:
	;
	; Now, make adjustments if we have a minimum scrollbar.
	;
	mov	cx, ds:[si].OLSBI_scrArea	  ;see how much room there is
	cmp	cx, MIN_FULL_HEIGHT-UNUSED_HEIGHT ;see if can be full scrollbar
	ja	10$				  ;yep, branch to set cables

	clr	ax
	mov	[bp].SA_greyCableHt, ax		;else clear all cable stuff
	mov	word ptr [bp].SA_offGreyCable, ax   ;does offBlackCable too
	mov	[bp].SA_blackCableHt, ax
	mov	[bp].SA_blackCable2Ht, ax
	mov	word ptr [bp].SA_offGrey2Cable, ax   ;does bottom anchor as well
	mov	[bp].SA_greyCable2Ht, ax

	cmp	cx, ABBR_HEIGHT-UNUSED_HEIGHT	;abbreviated scrollbar?
	jbe	7$
	jmp	90$				;no, branch, we're done
7$:
	sub	[bp].SA_elevHt, DRAG_AREA_HEIGHT
	mov	[bp].SA_dragAreaSkip, DRAG_AREA_SKIP

	cmp	cx, MIN_HEIGHT-UNUSED_HEIGHT	;minimum scrollbar?
	ja	90$				;no, we're done

	mov	[bp].SA_anchorSkip, ANCHOR_SKIP	;else account for no anchors
	mov	[bp].SA_offElev, 1		;need to lower space before elev
	jmp	short 90$			;and we're done
10$:
	;
	; Now.  Calculate lengths of cables.
	;
	mov	ax, ds:[si].OLSBI_propIndOffset	;get offset to prop indicator
	cmp	ax, 1				;see if 1 or 0
	ja	20$				;no, branch
	mov	[bp].SA_offGreyCable, al	;else set different spacing
20$:
	mov	bx, ax				;put propIndOffset in bx
	mov	cx, bx				;now in cx
	dec	cx				;account for space
	jns	21$				;zero if negative
	clr	cx
21$:
	mov	[bp].SA_greyCableHt, cx		;and set as length of grey cable
	mov	ax, ds:[si].OLSBI_elevOffset	;get elevator offset
	mov	cx, ax				;put in cx
	sub	cx, bx				;subtract propIndOffset
	dec	cx				;account for space
	jns	22$				;zero if negative
	clr	cx
22$:
	mov	[bp].SA_blackCableHt, cx	;that's our black cable length
	cmp	ax, 1				;see if elevOffset 1 or 0
	ja	30$				;no, branch
	mov	[bp].SA_offBlackCable, al	;else set different spacing
30$:
	add	ax, ELEV_HEIGHT			;ax now at end of elevator
	add	bx, ds:[si].OLSBI_propIndLen	;bx now at end of prop ind
	mov	cx, ds:[si].OLSBI_scrArea	;get length of working scroll
	mov	dx, cx				;use scroll length in dx
	sub	dx, ax				;see if elevator at end
	cmp	dx, 1				;is it?  (or 1 away?)
	ja	40$				;no, branch
	mov	[bp].SA_offBottomAnchor, dl	;else set new spacing
40$:
	mov	dx, cx				;get working scroll area again
	sub	dx, bx				;see if prop ind at end
	cmp	dx, 1				;is it?  (or 1 away?)
	ja	50$				;no, branch
	mov	[bp].SA_offGrey2Cable, dl	;else set new spacing
50$:
	mov	dx, bx				;get prop ind len
	sub	dx, ax				;subtract end of elevator
	dec	dx				;account for space
	jns	60$				;zero if negative
	clr	dx
60$:
	mov	[bp].SA_blackCable2Ht, dx	;and store as cable length
	mov	dx, cx				;get scroll len
	sub	dx, bx				;subtract prop ind len
	dec	dx				;account for space
	jns	70$				;zero if negative
	clr	dx
70$:
	mov	[bp].SA_greyCable2Ht, dx	;and store
90$:
	mov	bx, ds:[si].OLSBI_attrs		;get attributes byte
	pop	si				;restore pointer to instance
	add	si, ds:[si].Vis_offset
	mov	cx, ds:[si].VI_bounds.R_left	;where to draw
	mov	dx, ds:[si].VI_bounds.R_top
	test	bx, mask OLSA_VERTICAL
	jnz	92$
	mov	dx, ds:[si].VI_bounds.R_bottom	;and bottom
92$:
	ret
SetScrollDrawParams	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimally updates the scrollbar, blitting and sparingly
		redrawing.

CALLED BY:	DoScrollAppearance

PASS:		*ds:si -- handle of scrollbar
		di -- graphics state
		al -- color scheme

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:   (assumes vertical scrollbar)
       ;
       ; First, blit the elevator.
       ;
       BitBlit (left, oldElevOffset, left,
       		newElevOffset, SCROLLBAR_WIDTH, ELEV_HEIGHT)
       ;
       ; Then, white out the portion that is being vacated by the proportion
       ; indicator and will become grey.
       ;
       if newElevOffset > oldElevOffset
            ;
	    ; Moving down. White out the proportion indicator between
	    ; oldPropIndOffset and newPropIndOffset.
	    ;
	    GrRect (left+CABLE_XOFF, oldPropIndOffset,
	    	    left+CABLE_XOFF+CABLE_WIDTH, newPropIndOffset)
	    ;
	    ; White out area of old elevator, except for parts where it
	    ; overlaps with the new one.
	    ;
	    GrRect (left, oldElevOffset, right,
	    	    min (oldElevOffset+ELEV_HEIGHT, newElevOffset))
       else
       	    ;
       	    ; Moving up. White out the proportion indicator between
	    ; newPropIndOffset+newPropIndLen and oldPropIndOffset+oldPropIndLen.
	    ;
	    GrRect (left+CABLE_XOFF,
	    	    newPropIndOffset+newPropIndLen,
		    left+CABLE_XOFF+CABLE_WIDTH,
		    oldPropIndOffset+oldPropIndLen)
	    ;
	    ; White out area of old elevator, except for parts where it
	    ; overlaps with the new one.
	    ;
	    GrRect (left,
	    	    max (oldElevOffset, newElevOffset+ELEV_HEIGHT),
		    right, oldElevOffset+ELEV_HEIGHT)
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


US_Local	struc
	US_newElevStart	sword			;new top of elevator
	US_oldElevStart	sword			;old top of elevator
	US_newPropStart	sword			;new top of black cable
	US_newPropEnd	sword			;new bottom of black
	US_oldPropStart	sword			;old top of black cable
	US_oldPropEnd	sword			;old bottom of black
	US_left		sword			;left edge of scrollbar
	US_attrs	word OLScrollbarAttrs	;save state here
	US_foreColor	Color			;foreground color to use
	US_backColor	Color			;background color to use
US_Local	ends

US_local	equ	<[bp - (size US_Local)]>


UpdateScroll	proc	near
	class	OLScrollbarClass
	
	mov	bp, sp				;make room for stack
	sub	sp, size US_Local

	push	si
	mov	bx, ax
	and	bh, mask DF_DISPLAY_TYPE	;see if color or BW display
	cmp	bh, DC_GRAY_1
	jnz	5$
	mov	US_local.US_foreColor, C_BLACK	;Use as the foreground color
	mov	US_local.US_backColor, C_WHITE	;Use as the background color
	jmp	short 6$
5$:
	push	ax
	and	ax, mask CS_darkColor		;Get the dark color
	mov	US_local.US_foreColor, al 	;Use as the foreground color
	pop	ax
	and	ax, mask CS_lightColor
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1				;Get the light color
	mov	US_local.US_backColor, al ;Use as the background color
6$:

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		;vis stuff in bx
	;
	; If not a full scrollbar, this stuff is unnecessary.
	;
	cmp	ds:[bx].OLSBI_scrArea, MIN_FULL_HEIGHT-UNUSED_HEIGHT
	ja	10$				;if full, branch
	push	di
	mov	di, bx
	call	SetTopBottomFlags		;else make sure these are set
	pop	di
	clc					;no blit happened
	jmp	90$				;and exit
10$:
	push	di				;save gstate
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;di points to vis
	mov	dX, ds:[bx].OLSBI_attrs  	;need to keep orientation
	mov	US_local.US_attrs, dX
	mov	dx, ds:[di].VI_bounds.R_left	;get left
	mov	cx, ds:[di].VI_bounds.R_top	;save top + anchor height
	mov	di, bx				;now di points to specific
	call	SwapIfHorizontal		;flip these if horiz
	mov	US_local.US_left, dx		;store as width offset
	add	cx, ANCHOR_HEIGHT+1
	mov	ax, cx				;put length offset in ax
	add	cx, ds:[di].OLSBI_elevOffset	;get current elevator offset
	mov	US_local.US_oldElevStart, cx	;store
	push	cx				;save, will use to compare
	mov	cx, ds:[di].OLSBI_propIndOffset	;get current propIndOffset
	add	cx, ax				;add offset to scroll top
	mov	US_local.US_oldPropStart, cx	;store
	add	cx, ds:[di].OLSBI_propIndLen	;add length to get end
	mov	US_local.US_oldPropEnd, cx	;store
	push	ax
	;mov	ax, ds:[di].OLSBI_docOffset	;get true doc offset
	;mov	ds:[di].OLSBI_drawnDocOff, ax	;and set as drawn offset
        call	SetElevOffset			;set position of elevator
OLS <	call	SetPropIndLen			;maybe resize the prop ind >
	call	SetPropIndOffset		;set proportion indicator pos
 	pop	ax
	mov	cx, ds:[di].OLSBI_propIndOffset	;get current propIndOffset
	add	cx, ax				;add offset to scroll top
	mov	US_local.US_newPropStart, cx	;store
	add	cx, ds:[di].OLSBI_propIndLen	;add length to get end
	mov	US_local.US_newPropEnd, cx	;store
	mov	cx, ds:[di].OLSBI_elevOffset	;get current elevator offset
	add	cx, ax				;add offset to scroll top
	mov	US_local.US_newElevStart, cx	;store
	pop	dx				;get old elevator offset
	pop	di				;restore gstate
	;
	; We must update if the elevator has moved, the top of the proportion
	; indicator has moved, or the bottom of the proportion indicator has
	; moved.
	;
	mov	si, US_local.US_oldPropStart	;old area above elevator
	cmp	si, US_local.US_newPropStart	;if tops differ, must update
	jne	16$

	mov	bx, US_local.US_oldPropEnd	;old area below elevator
	cmp	bx, US_local.US_newPropEnd	;if it changed, must update...
	jne	16$

	cmp	cx, dx				;the same elevator offset?
	clc					;assume so, no blit happened
	jne	16$				;no, must update
	jmp	90$				;else, exit
	;
	; First, blit the elevator, along with as much of the proportion
	; indicator as possible.
	;
16$:
	cmp	cx, dx				;same elevator offset
	je	191$				;if so, skip elev blit

	mov	bx, US_local.US_oldElevStart	;top
	mov	cx, bx				;keep top here as well
	sub	cx, si				;keep old top here (set above)
	mov	dx, US_local.US_newElevStart	;dest top
	mov	ax, dx				;keep here as well
	sub	ax, US_local.US_newPropStart	;new area above elevator
	cmp	ax, cx				;take the smaller in ax
	jb	17$
	mov	ax, cx				;use old length
17$:
	tst	ax
	jnz	170$
	inc	ax				;keep space above elev
170$:
	sub	bx, ax				;subtract from source top
	sub	dx, ax				;subtract from dest top
	push	di
	mov	si, US_local.US_oldPropEnd	;old area below elevator
	mov	di, si
	sub	si, US_local.US_oldElevStart	;  plus height of elevator
	mov	cx, US_local.US_newPropEnd
	sub	cx, US_local.US_newElevStart
	cmp	cx, si				;smallest in cx
	jb	18$
	mov	cx, si				;use old length
18$:
	tst	di				;keep space below elevator
	jnz	19$
	inc	di
19$:
	pop	di
	add	cx, ax				;add extra calc'ed above elev
	mov	ax, US_local.US_left		;left edge
	push	bp				;do let's save this
	test	US_local.US_attrs, mask OLSA_VERTICAL	;see if vertical now
	mov	bp, cx				;put height to blit in bp
	mov	cx, ax				;dest left
	mov	si, SCROLLBAR_WIDTH		;width to blit

	jnz	190$				;not horiz, branch
	xchg	ax, bx				;else xchg everything
	xchg	cx, dx
	xchg	bp, si
190$:
	push	bp				;pass height on stack
	clr	bp				;don't invalidate source
	push	bp				;passed on stack
	call	GrBitBlt
	pop	bp				;restore
191$:
	mov	al, US_local.US_backColor	; Use as the background color
	clr	ah
	call	GrSetAreaColor
	
	mov	al, SET_CUSTOM_PATTERN
	mov	al, MASK_50 or mask SDM_INVERSE	;use inverse 50% pattern
	call	GrSetAreaMask

	mov	ax, US_local.US_oldElevStart	;see if moving up
	cmp	ax, US_local.US_newElevStart
	ja	20$				;moving up, branch
	jb	192$				;moving down, branch
	mov	ax, US_local.US_oldPropEnd	;not moving, see if prop ind is
	cmp	ax, US_local.US_newPropEnd	;  shrinking upward
	ja	20$				;yes, branch, the moving up
						;  code updates bottom of stuff
192$:
	;
	; Moving down. White out the proportion indicator between
	; oldPropIndOffset and newPropIndOffset.  This is only for the purpose
	; of drawing 50% pattern where black used to be, so we'll just
	; wipe out the pixels that are white in a 50% pattern.
	;
	mov	ax, US_local.US_left		;get left edge
	push	ax
	add	ax, CABLE_XOFF			;get to cable
	mov	cx, ax
	add	cx, CABLE_WIDTH			;right edge
	mov	bx, US_local.US_oldPropStart	;top
	mov	dx, US_local.US_newPropStart	;bottom
	cmp	bx, dx				;anything to do?
	jz	193$				;no, branch
	dec	dx
	call	TwoSwapIfHoriz			;swap ax-bx, cx-dx
	call	GrFillRect
193$:
	;
	; White out area of old elevator, except for parts where it
	; overlaps with the new one.
	;
	pop	ax				;restore left edge
	mov	cx, ax
	add	cx, CABLE_XOFF-1
	mov	bx, US_local.US_oldElevStart	;top
	mov	dx, bx
	add	dx, ELEV_HEIGHT			;assume using old bottom
	mov	si, US_local.US_newElevStart	;see about overlap

	cmp	bx, si				;did the elevator move?
	jz	80$				;no, skip last update
	dec	si
	cmp	dx, si				;take the min here
	jbe	30$
	mov	dx, si
	jmp	short	30$			;go do the next thing
20$:
	;
	; Moving up. White out the proportion indicator between
	; newPropIndEnd and oldPropIndEnd.
	;
	mov	ax, US_local.US_left		;get left edge
	push	ax
	add	ax, CABLE_XOFF			;get to cable
	mov	cx, ax
	add	cx, CABLE_WIDTH			;right edge
	mov	bx, US_local.US_newPropEnd	;top
	mov	dx, US_local.US_oldPropEnd	;bottom
	call	TwoSwapIfHoriz			;swap ax-bx, cx-dx
	call	GrFillRect
	;
	; White out area of old elevator, except for parts where it
	; overlaps with the new one.
	;
	pop	ax				;restore left edge
	mov	cx, ax
	add	cx, CABLE_XOFF-1
	mov	dx, US_local.US_oldElevStart	;bottom
	mov	bx, dx
	add	dx, ELEV_HEIGHT
	mov	si, US_local.US_newElevStart	;see about overlap
	add	si, ELEV_HEIGHT

	cmp	dx, si				;did the elevator even move?
	je	80$				;no, we're done

	cmp	bx, si				;take the max here
	jae	30$
	mov	bx, si
30$:
	mov	si, ax				;save ax
	mov	al, MASK_100			;restore solid draw mask
	call	GrSetAreaMask
	mov	ax, si				;restore ax
	call	TwoSwapIfHoriz			;swap ax-bx, cx-dx
	call	GrFillRect			;blank it out
	call	TwoSwapIfHoriz
	add	ax, CABLE_XOFF+CABLE_WIDTH
	add	cx, CABLE_XOFF+CABLE_WIDTH
	call	TwoSwapIfHoriz
	call	GrFillRect
80$:
	stc					;return carry set (we blitted)
90$:
	pop	si
	mov	sp, bp				;destroy locals
	ret
UpdateScroll	endp

		
		
		
TwoSwapIfHoriz	proc	near
	test	US_local.US_attrs, mask OLSA_VERTICAL	;see if horizontal
	jnz	10$					;no, branch
	xchg	ax, bx
	xchg	cx, dx
10$:
	ret
TwoSwapIfHoriz	endp



ScrollbarCommon	ends

			
			
DrawBW segment resource

;
; Entry point for BW data if we're just updating.  Updating exludes anchors,
; and this adjusts the starting position accordingly.
;
scrollbarUpdateBWData	label	byte
	byte	HORIZ_MOVE, 	ANCHOR_HEIGHT-1

;
; Entry point for complete draw of BW scrollbars.
;
scrollbarBWData	label	byte		;normal draw
UPDATE_DATA_LEN_BW = offset scrollbarBWData - offset scrollbarUpdateBWData
	;
	; First, to the top anchor.
	;
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	SET_DX,			-SCROLLBAR_WIDTH
	byte	SKIP,			BYTE_BP.SA_anchorSkip
TD_topAnchorStartBW:			;skipped if updating
	byte	FRECT,			ANCHOR_HEIGHT
	byte	VERT_MOVE,		-1
	byte	HORIZ_MOVE,		1
	byte	SET_SELECTED, 		OLSS_BEG_ANCHOR
	byte	SET_DX,			-(SCROLLBAR_WIDTH-3)
	byte	FILL_IF_SELECTED,	ANCHOR_HEIGHT-3
	byte	HORIZ_MOVE,		3
	byte	VERT_MOVE,		1
TD_topAnchorEndBW:
ANCHOR_SKIP_BW	=	offset TD_topAnchorEndBW - offset TD_topAnchorStartBW
	;
	; First piece of grey cable
	;
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	HORIZ_MOVE,		BYTE_BP.SA_offGreyCable
	byte	VERT_MOVE,		-CABLE_XOFF
	byte	AREA_PATTERN,		MASK_50
	byte	SET_DX,			-CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_greyCableHt
	;
	; First piece of black cable
	;
	byte	HORIZ_MOVE,		1
	byte	SET_DX,			2
	byte	FILL_IF_SELECTED,   	BYTE_BP.SA_offBlackCable	;2 or 0
	byte	HORIZ_MOVE,		-1
	byte	HORIZ_MOVE,		BYTE_BP.SA_offBlackCable	;2 or 0

	byte	AREA_PATTERN,		BYTE_BP.SA_mask
	byte	SET_DX,			CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_blackCableHt
	byte	HORIZ_MOVE,		BYTE_BP.SA_offElev		;3 or 1
 	byte	SKIP,			BYTE_BP.SA_elevSkip
TD_elevStartBW:
	;
	; Special shadows
	;
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	VERT_MOVE,		BYTE_BP.SA_offShadow	;h5, -7
	byte	HORIZ_LINE,		BYTE_BP.SA_elevHt	;39, 39-13
	byte	VERT_MOVE,		BYTE_BP.SA_offShadowRet	;h-1, 12
	;
	; Up arrow
	;
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT
	byte	DIAG_MOVE,		-1
	byte	VERT_LINE_MOVE,		-(SCROLLBAR_WIDTH-2)
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT+1
	byte	DIAG_MOVE,		1



	byte	SET_SELECTED,		OLSS_INC_UP
	byte	SET_DX,			(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	SCR_BUTTON_HEIGHT-2
	;
	; Arrow portion of up arrow
	;
	byte	VERT_MOVE,		(ARROW_XOFF-1) +1
	byte	HORIZ_MOVE,		ARROW_YOFF-1 +1
	byte	VERT_MOVE,		BYTE_BP.SA_skewedNegative
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte 	HORIZ_MOVE,		-1
	byte	VERT_MOVE,		-1
	byte	LINE_PATTERN,		BYTE_BP.SA_upArrowArrowPat
	byte	VERT_LINE,		(ARROW_WIDTH-4)
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		(ARROW_WIDTH-2)
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		ARROW_WIDTH
	byte	HORIZ_MOVE,		1
	byte	VERT_LINE,		ARROW_WIDTH
	byte	VERT_MOVE, 		3
	byte	HORIZ_MOVE,		-2
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	VERT_MOVE,		BYTE_BP.SA_skewedPositive
	byte	VERT_MOVE,		(ARROW_XOFF+3) -3
	byte	HORIZ_MOVE,		SCR_BUTTON_HEIGHT-ARROW_YOFF-3  +2
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		-(SCROLLBAR_WIDTH-2)
	byte	VERT_MOVE,		1
	;
	; Drag area
	;
	byte	SKIP,			BYTE_BP.SA_dragAreaSkip
TD_dragAreaStartBW:
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	SET_DX, 		-(SCROLLBAR_WIDTH-1)
	byte	FRECT,			SCR_BUTTON_HEIGHT+1
	byte	HORIZ_MOVE, 		1
	byte	VERT_MOVE,		-1
	byte	SET_SELECTED,		OLSS_DRAG_AREA
	byte	SET_DX,			-(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	SCR_BUTTON_HEIGHT-2
	byte	VERT_MOVE, 		1
	byte	HORIZ_MOVE,		(SCR_BUTTON_HEIGHT-1)
TD_dragAreaEndBW:
DRAG_AREA_SKIP_BW =  offset TD_dragAreaEndBW - offset TD_dragAreaStartBW
	;
	; Bottom arrow
	;
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	SET_DX,			-(SCROLLBAR_WIDTH-1)
	byte	FRECT,			SCR_BUTTON_HEIGHT+1
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	SET_SELECTED,		OLSS_INC_DOWN
	byte	SET_DX,			-(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	SCR_BUTTON_HEIGHT-2
	;
	; Arrow portion of down arrow
	;
	byte	HORIZ_MOVE,		ARROW_YOFF-1  +2
	byte	HORIZ_MOVE,		BYTE_BP.SA_skewedNegative
	byte	VERT_MOVE,		-2  -2
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	HORIZ_MOVE,		-2
	byte	VERT_MOVE,		2
	byte	LINE_PATTERN,		BYTE_BP.SA_downArrowArrowPat
	byte	VERT_LINE,		-ARROW_WIDTH
	byte	HORIZ_MOVE,		1
	byte	VERT_LINE,		-ARROW_WIDTH
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		-(ARROW_WIDTH-2)
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		-(ARROW_WIDTH-4)
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	HORIZ_MOVE,		-1
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	HORIZ_MOVE,		BYTE_BP.SA_skewedPositive
	byte	HORIZ_MOVE,		6  +1
	byte	VERT_MOVE,		BYTE_BP.SA_offBotShadow  ;h-5, -6
	byte	VERT_LINE,		SCROLLBAR_WIDTH-2
	byte	VERT_MOVE,		6
	byte	HORIZ_MOVE,		2
	byte	SKIP,			2
TD_elevEndBW:
ELEV_SKIP_BW = offset TD_elevEndBW - offset TD_elevStartBW
 	byte	HORIZ_MOVE,		ELEV_HEIGHT	;skipped in normal draw
	;
	; Second black cable
	;
	byte	SET_DX,			-CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_blackCable2Ht
	;
	; Second grey cable
	;
	byte	HORIZ_MOVE,		1
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	SET_DX,			2
	byte	FILL_IF_SELECTED,   	BYTE_BP.SA_offGrey2Cable	;2 or 0
	byte	HORIZ_MOVE,		-1

	byte	HORIZ_MOVE,		BYTE_BP.SA_offGrey2Cable	;2 or 0
	byte	AREA_PATTERN,		MASK_50
	byte	SET_DX,			CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_greyCable2Ht
	byte	HORIZ_MOVE,		BYTE_BP.SA_offBottomAnchor ;2 or 0
	byte	VERT_MOVE,		CABLE_XOFF
	byte	AREA_PATTERN,		BYTE_BP.SA_mask
	;
	; Bottom anchor
	;
	byte	SKIP,			BYTE_BP.SA_anchorSkip
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	SET_DX,			-(SCROLLBAR_WIDTH)
	byte	FRECT,			ANCHOR_HEIGHT
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	SET_SELECTED, 		OLSS_END_ANCHOR
	byte	SET_DX,			-(SCROLLBAR_WIDTH-3)
	byte	FILL_IF_SELECTED,	ANCHOR_HEIGHT-3
	byte	0
DrawBW ends

DrawColor segment resource

;
; Color scrollbar update.  Adjust position for no anchors.
;
scrollbarUpdateData	label	byte
	byte	HORIZ_MOVE, 	ANCHOR_HEIGHT-1

;
; Color scrollbar draw.
;
scrollbarData	label	byte
UPDATE_DATA_LEN	= offset scrollbarData - offset scrollbarUpdateData
	;
	; First, to the top anchor.
	;
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	SKIP,			BYTE_BP.SA_anchorSkip
TD_topAnchorStart:
	byte	SET_SELECTED, 		OLSS_BEG_ANCHOR
	byte	HORIZ_LINE, 		ANCHOR_HEIGHT,	   BOTTOM_EDGE_COLOR
	byte	VERT_LINE_MOVE,		-SCROLLBAR_WIDTH,  LEFT_EDGE_COLOR
	byte	HORIZ_LINE_MOVE,	ANCHOR_HEIGHT,	   TOP_EDGE_COLOR
	byte	VERT_LINE_MOVE,		SCROLLBAR_WIDTH-1, RIGHT_EDGE_COLOR
	byte	HORIZ_MOVE, 		-1
	byte	SET_DX,			-(SCROLLBAR_WIDTH-3)
	byte	FILL_IF_SELECTED,	-(ANCHOR_HEIGHT-3)
	byte	DIAG_MOVE,		1
TD_topAnchorEnd:
ANCHOR_SKIP = offset TD_topAnchorEnd - offset TD_topAnchorStart
	;
	; First piece of grey cable
	;
	byte	HORIZ_MOVE,	BYTE_BP.SA_offGreyCable
	byte	VERT_MOVE,	-CABLE_XOFF
	byte	AREA_PATTERN,	MASK_50
	byte	SET_DX,		-CABLE_WIDTH
	byte	RECT_MOVE,	WORD_BP.SA_greyCableHt,	   BLACK_COLOR
	;
	; First piece of black cable
	;
	byte	HORIZ_MOVE,	1
	byte	SET_SELECTED,	NOTHING_SELECTED
	byte	SET_DX,		2
	byte	FILL_IF_SELECTED,   BYTE_BP.SA_offBlackCable	;2 or 0
	byte	HORIZ_MOVE,	-1
	byte	HORIZ_MOVE,	BYTE_BP.SA_offBlackCable	;2 or 0
	;??
	byte	AREA_PATTERN,	BYTE_BP.SA_mask
	byte	SET_DX,		CABLE_WIDTH
	byte	RECT_MOVE,	WORD_BP.SA_blackCableHt,  BLACK_COLOR
	byte	HORIZ_MOVE,	BYTE_BP.SA_offElev		;3 or 1
	byte	SKIP,		BYTE_BP.SA_elevSkip
TD_elevStart:
	;
	; Special shadows
	;
	byte	VERT_MOVE,	BYTE_BP.SA_offShadow 	        ;h5, -7
	byte	HORIZ_LINE,	BYTE_BP.SA_elevHt, BLACK_COLOR	;(39, 39-13)
	byte	VERT_MOVE,	BYTE_BP.SA_offShadowRet         ;h-1, 12
	;
	; Up arrow
	;
	byte	SET_SELECTED,		OLSS_INC_UP
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT,    BOTTOM_EDGE_COLOR
	byte	DIAG_MOVE,		-1
	byte	VERT_LINE_MOVE,		-(SCROLLBAR_WIDTH-2), LEFT_EDGE_COLOR
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT+1,  TOP_EDGE_COLOR
	byte	DIAG_MOVE,		1
	byte	SET_DX,			(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	SCR_BUTTON_HEIGHT-1
	;
	; Arrow portion of up arrow
	;
	byte	VERT_MOVE,		(CABLE_XOFF-1) +1
	byte	HORIZ_MOVE,		ARROW_YOFF-1 +1
	byte	VERT_MOVE,		BYTE_BP.SA_skewedNegative
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte 	HORIZ_MOVE,		-1
	byte	VERT_MOVE,		-1
	byte	LINE_PATTERN,		BYTE_BP.SA_upArrowArrowPat
	byte	VERT_LINE,		(ARROW_WIDTH-4),	TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		(ARROW_WIDTH-2),	TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		ARROW_WIDTH,		TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_LINE,		ARROW_WIDTH,		TEXT_COLOR
	byte	VERT_MOVE, 		3
	byte	HORIZ_MOVE,		-2
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	VERT_MOVE,		BYTE_BP.SA_skewedPositive
	byte	VERT_MOVE,		(ARROW_XOFF+3) -3
	byte	HORIZ_MOVE,		ARROW_YOFF     +2
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	VERT_MOVE,		-1
;	byte	VERT_LINE,		-(SCROLLBAR_WIDTH-2), JOIN_EDGE_COLOR
	byte	VERT_LINE,		-(SCROLLBAR_WIDTH-2), RIGHT_EDGE_COLOR
	byte	VERT_MOVE,		1
	;
	; Drag area
	;
	byte	SKIP,			BYTE_BP.SA_dragAreaSkip
TD_dragAreaStart:
	byte	SET_SELECTED,		OLSS_DRAG_AREA
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT+1,   BOTTOM_EDGE_COLOR
	byte	VERT_MOVE,		-1
	byte	VERT_LINE_MOVE,		-(SCROLLBAR_WIDTH-2),  LEFT_EDGE_COLOR
	byte	HORIZ_LINE_MOVE,	SCR_BUTTON_HEIGHT+1,   TOP_EDGE_COLOR
	byte	VERT_LINE,		(SCROLLBAR_WIDTH-2),   RIGHT_EDGE_COLOR
	byte	HORIZ_MOVE,		-1
	byte	VERT_MOVE,		1
	byte	SET_DX,			(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	-(SCR_BUTTON_HEIGHT-2)
	byte	VERT_MOVE, 		(SCR_BUTTON_HEIGHT-3)
	byte	HORIZ_MOVE,		1
TD_dragAreaEnd:
DRAG_AREA_SKIP	= offset TD_dragAreaEnd - offset TD_dragAreaStart
	;
	; Bottom arrow
	;
	byte	SET_SELECTED,		OLSS_INC_DOWN
	byte	HORIZ_LINE,		SCR_BUTTON_HEIGHT+1,  BOTTOM_EDGE_COLOR
	byte	VERT_MOVE,		-(SCROLLBAR_WIDTH-2)
	byte	HORIZ_LINE_MOVE,	SCR_BUTTON_HEIGHT+1,   TOP_EDGE_COLOR
	byte	VERT_LINE,		(SCROLLBAR_WIDTH-2),   RIGHT_EDGE_COLOR
	byte	VERT_MOVE,		1
	byte	HORIZ_MOVE,		-1
	byte	SET_DX,			(SCROLLBAR_WIDTH-4)
	byte	FILL_IF_SELECTED,	-(SCR_BUTTON_HEIGHT-2)
	;
	; Arrow portion of down arrow
	;
	byte	HORIZ_MOVE,		-(ARROW_XOFF+2) +2
	byte	HORIZ_MOVE,		BYTE_BP.SA_skewedNegative
	byte	VERT_MOVE,		(ARROW_XOFF+2) -2
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	HORIZ_MOVE,		-2
	byte	VERT_MOVE,		2
	byte	LINE_PATTERN,		BYTE_BP.SA_downArrowArrowPat
	byte	VERT_LINE,		-ARROW_WIDTH,		TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_LINE,		-ARROW_WIDTH,		TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,	 	-(ARROW_WIDTH-2),	TEXT_COLOR
	byte	HORIZ_MOVE,		1
	byte	VERT_MOVE,		-1
	byte	VERT_LINE,		-(ARROW_WIDTH-4),	TEXT_COLOR
	byte	LINE_PATTERN,		BYTE_BP.SA_mask
	byte	HORIZ_MOVE,		-1
	byte	FLIP_ORIENTATION,	BYTE_BP.SA_skewedNegative
	byte	HORIZ_MOVE,		BYTE_BP.SA_skewedPositive
	byte	HORIZ_MOVE,		6 + 1
	byte	SET_SELECTED,		NOTHING_SELECTED
	byte	VERT_MOVE,		BYTE_BP.SA_offBotShadow  ;h-5, -6
	byte	VERT_LINE,		SCROLLBAR_WIDTH-2,  BLACK_COLOR
	byte	VERT_MOVE,		6
	byte	HORIZ_MOVE,		2
	byte	SKIP,			2
TD_elevEnd:
ELEV_SKIP = offset TD_elevEnd - offset TD_elevStart
	byte	HORIZ_MOVE,		ELEV_HEIGHT	;skipped in normal draw
	;
	; Second black cable
	;
	byte	SET_DX,			-CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_blackCable2Ht, BLACK_COLOR
	;
	; Second grey cable
	;
	byte	HORIZ_MOVE,		1
	byte	SET_DX,			2
	byte	FILL_IF_SELECTED,	BYTE_BP.SA_offGrey2Cable
	byte	HORIZ_MOVE,		-1
	byte	HORIZ_MOVE,		BYTE_BP.SA_offGrey2Cable	;2 or 0

	byte	AREA_PATTERN,		MASK_50
	byte	SET_DX,			CABLE_WIDTH
	byte	RECT_MOVE,		WORD_BP.SA_greyCable2Ht, BLACK_COLOR

	byte	HORIZ_MOVE,		BYTE_BP.SA_offBottomAnchor ;2 or 0
	byte	VERT_MOVE,		CABLE_XOFF
	byte	AREA_PATTERN,		BYTE_BP.SA_mask
	;
	; Bottom anchor (must have same # bytes skipped as top anchor)
	;
	byte	SKIP,			BYTE_BP.SA_anchorSkip
	byte	SET_SELECTED,		OLSS_END_ANCHOR
	byte	HORIZ_LINE, 		ANCHOR_HEIGHT,	      BOTTOM_EDGE_COLOR
	byte	VERT_LINE_MOVE,		-SCROLLBAR_WIDTH,     LEFT_EDGE_COLOR
	byte	HORIZ_LINE_MOVE,	ANCHOR_HEIGHT,	      TOP_EDGE_COLOR
	byte	VERT_LINE,		(SCROLLBAR_WIDTH-1),  RIGHT_EDGE_COLOR
	byte	HORIZ_MOVE,		-1
	byte	VERT_MOVE,		1
	byte	SET_DX,			(SCROLLBAR_WIDTH-3)
	byte	FILL_IF_SELECTED,	-(ANCHOR_HEIGHT-3)
	byte	0

DrawColor ends
