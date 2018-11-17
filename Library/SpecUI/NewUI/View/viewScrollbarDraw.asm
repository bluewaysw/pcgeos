COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CUA/View
FILE:		viewScrollbarDraw.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/90		Split off from scrollbar file

DESCRIPTION:

	$Id: viewScrollbarDraw.asm,v 1.2 98/05/04 06:19:23 joon Exp $

-------------------------------------------------------------------------------@


ScrollbarCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawScrollbar

DESCRIPTION:	Draw a motif Scrollbar.  Works on any display.

CALLED BY:	OLScrollbarDraw

PASS:
	*ds:si - scrollbar
	es - segment of MetaClass
	ch - DrawFlags:  DF_EXPOSED set if updating
	di - GState to use

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, es

REGISTER/STACK USAGE:
	di -- gstate

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version
	Joon	8/92		Changes for PM

------------------------------------------------------------------------------@

	
DrawScrollbar	proc	far			;passed instance ptr in ds:si
	class	OLScrollbarClass
	
	ltColor		local	word		;left/top color
	rbColor		local	word		;right/bottom color
	fillColor	local	word		;fill color
	fillSelColor	local	word		;fill selected color
	darkColor	local	word		;dark fill
	gstate		local	hptr.GState	;gstate
	scrPtr		local	word		;ptr to OLScrollbarInstance
	scrLen		local	word		;length of scrollbar
	selected?	local	byte		;selected flag (zero if sel)
	attrs		local	OLScrollbarAttrs

	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	
	;
	; Set up a few things right now.
	; 
	mov	gstate, di			;save away gstate

	push	si	
	mov	si, ds:[si]			;dereference scrollbar
	mov	scrPtr, si			;save scrollbar pointer
	add	si, ds:[si].Vis_offset		;ds:[di] -- SpecInstance
	mov	dx, ds:[si].OLSBI_attrs		;get attributes
	mov	attrs, dx			;save in local vars
	test	dl, mask OLSA_TWISTED
	pop	si

	jz	regularScrollbar
	call	DrawSpinGadget
	jmp	done

regularScrollbar:
	call	DrawOutline			;do this NOW.
	call	SetupDrawColors			;sets up colors
	call	SetupDrawParams			;sets up parameters

	;
	; Code added 2/ 7/92 cbh to hopefully make these things shorter in CGA.
	; Mouse press stuff should still work since we don't care about verticl
	; checking.  (We've shortened the scrollbar, so we need to fool it into
	; thinking it needs to be drawn higher.)
	;
	mov	di, scrPtr			;point to scrollbar spec inst
	add	di, es:[di].Vis_offset

	call	DrawUpArrow			;draw the up arrow

	call	DrawThumb			;draw the thumb

	;
	; Now draw page up area.
	;
	tst	es:[di].OLSBI_elevOffset	     ;see if near the top
						     ;  (or no thumb at all)
	jg	25$				     ;no, draw page up stuff
	add	si, offset vsbPageDn - offset vsbPageUp  ;else skip data
	jmp	short pageDown

25$:
	jz	pageDown			;yes, skip
	call	DrawPageUpDownArea		;else draw the page up area
pageDown:
	;
	; Switch arguments: arg0 is thumb bottom, arg1 is scrollbar bottom.
	;
	mov	cx, dx				;move thumb bottom to cx
	mov	dx, scrLen			;keep scrollbar length in dx
	;
	; Now draw page down area.
	;
	push	ax
	mov	ax, es:[di].OLSBI_scrArea	;get current scroll area
	sub	ax, es:[di].OLSBI_elevLen	;subtract height of thumb
	sub	ax, es:[di].OLSBI_elevOffset	;see if near bottom already
	tst	ax				;see if anything to draw
	pop	ax				;
	jg	45$				;yes, branch to draw 
						;else skip
	add	si, offset vsbDnArrow - offset vsbPageDn
	jmp	short downArrow

45$:
	call	DrawPageUpDownArea		;draw the page down area
	
downArrow:
	;
	; Now, draw the down arrow.
	;
	call	DrawDownArrow			;draw the down arrow	
	mov	di, gstate
	mov	ax, SDM_100			;reset to 100% pattern
	call	GrSetLineMask
	call	GrSetAreaMask

	segmov	ds, es
done:
	.leave
	ret
DrawScrollbar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpinGadget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a spin gadget.

CALLED BY:	DrawScrollbar

PASS:		*ds:si - scrollbar
		es - segment of MetaClass
		ch - DrawFlags:  DF_EXPOSED set if updating

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpinGadget	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	
	.enter	inherit

	call	SetupDrawColors

	call	OpenCheckIfBW
	jc	setupDraw
	
	mov	ax, darkColor		;set color to draw line separating
	call	GrSetLineColor		; up/down buttons

	push	bp
	mov	ah, al			;ah = al = darkColor
	mov	bp, ax			;bp.h = bp.l = darkColor
	call	VisGetBounds		;get bounds of spin gadget

	push	bx			;save top bound
	add	bx, dx
	shr	bx, 1
	dec	cx			;adjust for line drawing
	call	GrDrawHLine		;draw line separating up/down buttons

	pop	bx
	inc	cx			;cx back to normal
	call	OpenDrawRect		;draw a border around the spin gadget
	pop	bp

setupDraw:
	call	SetupDrawParams

	call	OpenCheckIfCGA
	jnc	draw
	dec	bx			;adjust for CGA

draw:
	mov	di, scrPtr		;point to scrollbar spec inst
	add	di, es:[di].Vis_offset

	call	DrawUpArrow
	call	DrawDownArrow

	.leave	
	ret
DrawSpinGadget	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDrawColors

SYNOPSIS:	Set up colors for drawing the scrollbar.

CALLED BY:	DrawScrollbar

PASS:		ss:bp  -- DrawBar_localVars
		di     -- gstate

RETURN:		nothing

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
    			color		B/W
				
       	rbColor		C_BLACK		C_BLACK
	ltColor		C_WHITE		C_BLACK
	fillColor	light		C_WHITE
	fillSelColor	dark		C_BLACK
	darkColor	dark		C_WHITE

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 5/90		Initial version

------------------------------------------------------------------------------@

SetupDrawColors	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	
	.enter	inherit
	mov	rbColor, C_BLACK
	mov	ltColor, C_BLACK
	mov	fillColor, C_WHITE
	mov	fillSelColor, C_BLACK
if	0
	mov	darkColor, C_WHITE
else
	mov	darkColor, C_BLACK
endif
	
	;
	; Set up colors otherwise.
	; 
	push	ds
	mov	ax, segment moCS_flags
	mov	ds, ax

	test	ds:[moCS_flags], mask CSF_BW	; see if doing b/w	      
	jnz	notColor			; not color, branch
		
	clr	ah	
	mov	al, ds:[moCS_dsLightColor]
	mov	fillColor, ax			; store as the fill color
	mov	al, ds:[moCS_dsDarkColor]
	mov	fillSelColor, ax
	mov	darkColor, ax			; store as right/bot color
	mov	rbColor, ax
	mov	ltColor, C_WHITE		; l/t color is white
	
notColor:
	pop	ds

	.leave
	ret
SetupDrawColors	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawOutline

SYNOPSIS:	Draws an inset rect, using the specific UI routines.

CALLED BY:	DrawScrollbar

PASS:		ds:si -- object 
		di -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 5/90		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

DrawOutline	proc	near		uses	bp, es
	.enter
	mov	ax, segment moCS_dsLightColor	;set up es
	mov	es, ax
	call	OpenSetInsetRectColors		;setup normal colors
	call	VisGetBounds			;get normal bounds
	push	bp
	;
	; Use the "width" of the scrollbar to determine where the right edge
	; of a vertical scrollbar or bottom edge of a horizontal scrollbar
	; should be drawn.  Only when a slider, to be safe.
	;
	mov	bp, ds:[si]			;don't do it if not slider
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLSBI_attrs, mask OLSA_SLIDER
	jz	draw				;not slider, branch

	call	SwapVert			;allow horizontal assumption
	mov	dx, bx				;get top edge
	jnz	normalWidth			;vertical, branch
if TV_SCROLLERS
	call	OpenCheckIfTV
	jnc	10$
	mov	bp, ds:[si]
	add	bp, ds:[bp].Gen_offset
	test	ds:[bp].GI_attrs, mask GA_READ_ONLY	; no change for gauge
	jnz	10$
	add	dx, TV_SCROLLER_INCREASE
10$:
endif
	call	OpenCheckIfCGA			;not CGA, branch
	jnc	normalWidth			;else we'll use CGA width
	sub	dx, MO_SCROLLBAR_WIDTH - CGA_HORIZ_SCROLLBAR_WIDTH

normalWidth:
	add	dx, MO_SCROLLBAR_WIDTH
	call	SwapVert			;restore proper reg order
draw:
	pop	bp

	call	OpenDrawRect			;draw the inset rect
						;  (clears inside, which is a
						;   problem)
	.leave
	ret
DrawOutline	endp


SwapVert	proc	near
	test	ds:[bp].OLSBI_attrs, mask OLSA_VERTICAL
	jz	10$
	xchgdw	axcx, bxdx
10$:
	ret
SwapVert	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDrawParams

SYNOPSIS:	Sets up initial parameters for drawing the scrollbar.

CALLED BY:	DrawBWScrollbar

PASS:		ds     -- scrollbar segment

RETURN:		ds:si  -- pointing at start of graphics string
		es     -- scrollbar's block handle
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

SetupDrawParams	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	
	.enter	inherit
	segmov	es, ds, ax			;es points to data
	segmov	ds, cs, ax			;ds points to
	mov	di, scrPtr			;point to SpecInstance
	add	di, es:[di].Vis_offset
	mov	cx, es:[di].OLSBI_elevOffset	;pass elev offset in cx
	
	call	TestReadOnly			;gauge, no arrows
	jnz	5$
	add	cx, MO_SCR_AREA_MARGIN		;add arrow height for thumb top
if TV_SCROLLERS
	call	OpenCheckIfTV
	jnc	4$
	add	cx, TV_SCROLLER_INCREASE
4$:
endif
5$:
	mov	dx, cx				;now add elevLen for thumb bot
	add	dx, es:[di].OLSBI_elevLen	;
	jz	skipDec				;don't dec to -1
	dec	dx
skipDec:
	;	
	; Hell, why not do this now?
	;
	or	es:[di].OLSBI_attrs, mask OLSA_DRAWN_ENABLED
	test	es:[di].OLSBI_attrs, mask OLSA_ENABLED
	jnz	10$				;enabled, branch
	
	and	es:[di].OLSBI_attrs, not mask OLSA_DRAWN_ENABLED
10$:
	push	cx				;save scroller offset
	test	es:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	horiz				;nope, branch

	mov	si, offset vertScrollbar	;assume we use scrollable data 
if TV_SCROLLERS
	call	OpenCheckIfTV
	jnc	15$
	mov	si, offset TVVertScrollbar
15$:
endif
	mov	cx, offset vertGauge
	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED
	jz	afterTwisted
	mov	si, offset spinGadget
	mov	dx, NUI_SPIN_ARROW_HEIGHT*2+3	;dx = height of spin gadget
if TV_SCROLLERS
	call	OpenCheckIfTV
	jnc	17$
	mov	si, offset TVSpinGadget
	add	dx, TV_SCROLLER_INCREASE*2
17$:
endif

afterTwisted:
	;
	; First load ax, bx, cx, dx with left, top, elevOffset and height
	;
	mov	ax, es:[di].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[di].VI_bounds.R_top	;pass top in bx
	mov	di, es:[di].VI_bounds.R_bottom	;pass height in scrLen
	dec	di				;one less, for new graphics
	sub	di, bx
	mov	scrLen, di
	jmp	short 30$

horiz:
	mov	si, offset horizScrollbar	;assume we use scrollable data 
	mov	cx, offset horizGauge

	call	OpenMinimizeIfCGA		;see if on CGA
	jnc	20$				;no, branch
	mov	si, offset CGAHorizScrollbar	;else use CGA strings
	mov	cx, offset CGAHorizGauge
20$:
if TV_SCROLLERS
	call	OpenCheckIfTV
	jnc	25$
	mov	si, offset TVHorizScrollbar
25$:
endif
	mov	ax, es:[di].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[di].VI_bounds.R_top	;pass top in bx
	mov	di, es:[di].VI_bounds.R_right	;pass width in scrLen
	dec	di				;one less, for new graphics
	sub	di, ax				;
	mov	scrLen, di
30$:
	call	TestReadOnly			;read-only, assume gauge
	jz	exit
	mov	si, cx
exit:
	pop	cx				;restore scroller offset
	.leave
	ret
SetupDrawParams	endp


TestReadOnly	proc	near			;takes es:scrPtr = object
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit
	push	di				;read-only, assume gauge
	mov	di, scrPtr
	add	di, es:[di].Gen_offset
	test	es:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	.leave
	ret
TestReadOnly	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawUpArrow

SYNOPSIS:	Draws the scrollbar's up arrow.

CALLED BY:	DrawBWScrollbar

PASS:		es:di -- scrollbar SpecInstance
		ds:si  -- pointing to up-arrow gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- top of thumb
		dx     -- bottom of thumb

RETURN:		si     -- pointing past the gstring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@

DrawUpArrow	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit

	call	TestReadOnly
	jnz	exit

	push	ax
	mov	ah, es:[di].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	sub	ah, OLSS_INC_UP			;check increment up selected
	mov	selected?, ah			;store as selected flag
	pop	ax

	push	di
	mov	di, gstate
	call	DrawSBPart			; draw part of the scrollbar
	pop	di
exit:
	.leave
	ret
DrawUpArrow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawThumb

SYNOPSIS:	Draws the scrollbar's thumb.

CALLED BY:	DrawBWScrollbar

PASS:		es:di -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- top of thumb
		dx     -- bottom of thumb

RETURN:		si     -- pointing past the gstring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@

DrawThumb	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit

	call	TestReadOnly
	jnz	done

	tst	es:[di].OLSBI_elevOffset	;if negative, no thumb
	jns	setEdgeColor			;using thumb, draw it

skipThumb:
	add	si, offset vsbPageUp - offset vsbThumb
	jmp	short done			;else skip it

setEdgeColor:
	push	ltColor
	push	rbColor
	push	ax
	mov	ax, es:[di].OLSBI_scrArea	;get current scroll area
	sub	ax, es:[di].OLSBI_elevLen	;subtract height of thumb
	pop	ax
	jnz	short notFullSize
	mov	ltColor, C_LIGHT_GREY
	mov	rbColor, C_LIGHT_GREY
	jmp	drawThumb

notFullSize:
	mov	selected?, 0ffh			;assume not selected

drawThumb:
	push	di
	mov	di, gstate
	call	DrawSBPart			; draw part of the scrollbar
	pop	di
	pop	rbColor
	pop	ltColor
done:
	.leave
	ret
DrawThumb	endp

		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawPageUpDownArea

SYNOPSIS:	Draws the scrollbar's page up/down area.

CALLED BY:	DrawBWScrollbar

PASS:		es:di -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- top of thumb
		dx     -- bottom of thumb

RETURN:		si     -- pointing past the gstring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@
	
DrawPageUpDownArea	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	
	.enter	inherit
	push	di
	mov	di, gstate
	call	DrawSBPart			; draw part of the scrollbar
	pop	di
	.leave
	ret
DrawPageUpDownArea	endp
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawDownArrow

SYNOPSIS:	Draws the scrollbar's down arrow. 

CALLED BY:	DrawBWScrollbar

PASS:		*es:di -- scrollbar instance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- bottom of thumb
		dx     -- bottom of scrollbar (relative to top)

RETURN:		si     -- pointing past the gstring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@
	
DrawDownArrow	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit

	call	TestReadOnly
	jnz	exit

	push	ax
	mov	ah, es:[di].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	sub	ah, OLSS_INC_DOWN		;check increment up selected
	mov	selected?, ah			;store as selected flag
	pop	ax

	push	di
	mov	di, gstate
	call	DrawSBPart			; draw part of the scrollbar
	pop	di
exit:
	.leave
	ret
DrawDownArrow	endp
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetLTColor, SetRBColor, SetFillColor, SetDarkColor

SYNOPSIS:	Sets the appropriate color in this situation, according
		to the selected? flag.

CALLED BY:	utility

PASS:		di -- gstate

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
       What we want:
       			SetLTColor	SetRBColor	SetFillColor	SetDark
			
	color		C_WHITE lines	dark lines	light area	dark a.
	color, sel	C_BLACK lines	C_WHITE lines	dark area	dark a.
	B/W		C_BLACK lines	C_BLACK lines	C_WHITE area	C_WHITE
	B/W, sel	C_BLACK lines	C_BLACK lines	C_BLACK area	C_WHITE

	Where we get it:
       			SetLTColor	SetRBColor	SetFillColor	SetDark
			
	color		ltColor 	rbColor 	fillColor	darkCol
	color, sel	C_BLACK 		ltColor 	fillSelColor	darkCol
	B/W		ltColor 	rbColor		fillColor	darkCol
	B/W, sel	C_BLACK 		ltColor		fillSelColor	dorkCol
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/90		Initial version

------------------------------------------------------------------------------@

SetLTColor	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	
	.enter	inherit
	push	ax

	mov	ax, ltColor			;assume not selected
	tst	selected?			;see if selected
	jnz	10$				;not selected, branch
	mov	ax, rbColor			;selected ltColor is rbColor
10$:
	call	GrSetLineColor
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	20$				;yes, branch
	mov	al, SDM_50			;else set draw mask
	call	GrSetLineMask
20$:
	pop	ax
	.leave
	ret
SetLTColor	endp
		
;------------------------
		
SetRBColor	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit
	push	ax

	mov	ax, rbColor			;assume not selected
	tst	selected?			;see if selected
	jnz	10$				;not selected, branch
	mov	ax, ltColor
10$:
	call	GrSetLineColor
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	20$				;yes, branch
	mov	al, SDM_50			;else set draw mask
	call	GrSetLineMask
20$:
	pop	ax
	.leave
	ret
SetRBColor	endp

;--------------------------
	
SetFillColor	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit
	push	ax
	mov	ax, fillColor			;use fill color if not
	call	GrSetAreaColor
	pop	ax
	.leave
	ret
SetFillColor	endp
		
SetDarkColor	proc	near
	ltColor		local	word
	rbColor		local	word
	fillColor	local	word
	fillSelColor	local	word
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word

	.enter	inherit
	push	ax
	mov	ax, darkColor			;use dark color if selected
	call	GrSetAreaColor
	pop	ax
	.leave
	ret
SetDarkColor	endp

SetWhiteColor	proc	near
	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax
	ret
SetWhiteColor	endp

SetBlackColor	proc	near
	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor	
	pop	ax
	ret
SetBlackColor	endp

; Note:	These routines were originally static graphics strings, and were 
;	converted when GrPlayString went away.  

	; vertical scrollbar code
vertScrollbar	label	word
	nptr	offset HVUpDownArrow	; left, top, right, then bottom
	word	1, 2, 1, MO_ARROW_HEIGHT
	word	1, 1, MO_ARROW_WIDTH-1, 1
	word	MO_ARROW_WIDTH, 2, MO_ARROW_WIDTH, MO_ARROW_HEIGHT
	word	2, MO_ARROW_HEIGHT+1, MO_ARROW_WIDTH, MO_ARROW_HEIGHT+1
	word	1, 1, offset VUpInside
	word	1, 1, offset VUpOutside
	word	1, 1, offset VUpDepressedInside
	word	1, 1, offset VUpDepressedOutside	

vsbThumb	label	word
	nptr	offset HVThumb
	word	1, PARAM_2, 1, PARAM_3-1
	word	1, PARAM_2, MO_SCROLLBAR_WIDTH-3, PARAM_2
	word	MO_SCROLLBAR_WIDTH-2, PARAM_2, MO_SCROLLBAR_WIDTH-2, PARAM_3
	word	1, PARAM_3, MO_SCROLLBAR_WIDTH-2, PARAM_3
	word	2, PARAM_2+1, MO_SCROLLBAR_WIDTH-2, PARAM_3

vsbPageUp	label	word
	nptr	offset HVPageUpDn
	word	1, MO_ARROW_HEIGHT+2, MO_SCROLLBAR_WIDTH-1, PARAM_2

vsbPageDn	label	word
	nptr	offset HVPageUpDn
	word	1, PARAM_2+1, MO_SCROLLBAR_WIDTH-1, PARAM_3-MO_ARROW_HEIGHT-1

vsbDnArrow	label	word
	nptr	offset HVUpDownArrow
	word	1, PARAM_3-MO_ARROW_HEIGHT, 1, PARAM_3-2
	word	1, PARAM_3-MO_ARROW_HEIGHT-1, \
		MO_ARROW_WIDTH-1, PARAM_3-MO_ARROW_HEIGHT-1
	word	MO_ARROW_WIDTH, PARAM_3-MO_ARROW_HEIGHT, \
		MO_ARROW_WIDTH, PARAM_3-2
	word	2, PARAM_3-1, MO_ARROW_WIDTH, PARAM_3-1
	word	1, PARAM_3-MO_ARROW_HEIGHT-1, offset VDownInside
	word	1, PARAM_3-MO_ARROW_HEIGHT-1, offset VDownOutside
	word	1, PARAM_3-MO_ARROW_HEIGHT-1, offset VDownDepressedInside
	word	1, PARAM_3-MO_ARROW_HEIGHT-1, offset VDownDepressedOutside

if TV_SCROLLERS
	; TV vertical scrollbar code
TVVertScrollbar	label	word
	nptr	offset HVUpDownArrow	; left, top, right, then bottom
	word	1, 2, 1, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE
	word	1, 1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1, 1
	word	MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, 2, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE
	word	2, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+1
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset VUpInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset VUpOutside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset VUpDepressedInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset VUpDepressedOutside	

TVvsbThumb	label	word
	nptr	offset HVThumb
	word	1, PARAM_2, 1, PARAM_3-1
	word	1, PARAM_2, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-3, PARAM_2
	word	MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-2, PARAM_2, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-2, PARAM_3
	word	1, PARAM_3, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-2, PARAM_3
	word	2, PARAM_2+1, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-2, PARAM_3

;vsbPageUp	label	word
	nptr	offset HVPageUpDn
	word	1, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+2, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1, PARAM_2

;vsbPageDn	label	word
	nptr	offset HVPageUpDn
	word	1, PARAM_2+1, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1

;vsbDnArrow	label	word
	nptr	offset HVUpDownArrow
	word	1, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE, 1, PARAM_3-2
	word	1, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, \
		MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1
	word	MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE, \
		MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, PARAM_3-2
	word	2, PARAM_3-1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, PARAM_3-1
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset VDownInside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset VDownOutside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset VDownDepressedInside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset VDownDepressedOutside
endif

	; Horizontal scrollbars, on all but CGA
horizScrollbar	label	word
	nptr	offset HVUpDownArrow
	word	1, 2, 1, MO_ARROW_WIDTH-1
	word	1, 1, MO_ARROW_HEIGHT, 1
	word	MO_ARROW_HEIGHT+1, 2, MO_ARROW_HEIGHT+1, MO_ARROW_WIDTH-1
	word	1, MO_ARROW_WIDTH, MO_ARROW_HEIGHT+1, MO_ARROW_WIDTH
	word	1, 1, offset HUpInside
	word	1, 1, offset HUpOutside
	word	1, 1, offset HUpDepressedInside
	word	1, 1, offset HUpDepressedOutside

hsbThumb	label	word
	nptr	offset HVThumb
	word	PARAM_2, MO_SCROLLBAR_WIDTH-1-1, PARAM_2, 1
	word	PARAM_2, 1, PARAM_3-1, 1
	word	PARAM_3, MO_SCROLLBAR_WIDTH-1-1, PARAM_3, 2
	word	PARAM_2+1,MO_SCROLLBAR_WIDTH-1-1,PARAM_3,MO_SCROLLBAR_WIDTH-1-1
	word	PARAM_2+1, MO_SCROLLBAR_WIDTH-1-1, PARAM_3, 2

	nptr	offset HVPageUpDn
	word	MO_ARROW_HEIGHT+2, MO_SCROLLBAR_WIDTH-1, PARAM_2, 1

	nptr	offset HVPageUpDn
	word	PARAM_2+1, MO_SCROLLBAR_WIDTH-1, PARAM_3-MO_ARROW_HEIGHT-1, 1

	nptr	offset HVUpDownArrow
	word	PARAM_3-MO_ARROW_HEIGHT-1, 2, \
		PARAM_3-MO_ARROW_HEIGHT-1, MO_ARROW_WIDTH-1
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, \
		PARAM_3-2, 1
	word	PARAM_3-1, 2, \
		PARAM_3-1, MO_ARROW_WIDTH-1
	word	PARAM_3-MO_ARROW_HEIGHT-1, MO_ARROW_WIDTH, \
		PARAM_3-1, MO_ARROW_WIDTH
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset HDownInside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset HDownOutside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset HDownDepressedInside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset HDownDepressedOutside


	; Horizontal scrollbars on CGA
CGAHorizScrollbar label	word
	nptr	offset	HVUpDownArrow
	word	1, 2, 1, CGA_HORIZ_ARROW_WIDTH-1
	word	1, 1, MO_ARROW_HEIGHT+1, 1
	word	MO_ARROW_HEIGHT+1, 2, \
		MO_ARROW_HEIGHT+1, CGA_HORIZ_ARROW_WIDTH-1
	word	1, CGA_HORIZ_ARROW_WIDTH, \
		MO_ARROW_HEIGHT+1, CGA_HORIZ_ARROW_WIDTH
	word	1, 1, offset CGAHUpInside
	word	1, 1, offset CGAHUpOutside
	word	1, 1, offset CGAHUpDepressedInside
	word	1, 1, offset CGAHUpDepressedOutside
cgahThumb	label	word
	nptr	HVThumb
	word	PARAM_2, CGA_HORIZ_SCROLLBAR_WIDTH-1-1, PARAM_2, 1
	word	PARAM_2, 1, PARAM_3-1, 1
	word	PARAM_3, CGA_HORIZ_SCROLLBAR_WIDTH-1-1, PARAM_3, 2
	word	PARAM_2+1, CGA_HORIZ_SCROLLBAR_WIDTH-1-1, \
		PARAM_3, CGA_HORIZ_SCROLLBAR_WIDTH-1-1
	word	PARAM_2+1, CGA_HORIZ_SCROLLBAR_WIDTH-1-1, PARAM_3, 2

	nptr	HVPageUpDn
	word	MO_ARROW_HEIGHT+2, CGA_HORIZ_SCROLLBAR_WIDTH-1, PARAM_2, 1

	nptr	HVPageUpDn
	word  PARAM_2+1,CGA_HORIZ_SCROLLBAR_WIDTH-1,PARAM_3-MO_ARROW_HEIGHT-1,1

	nptr	HVUpDownArrow
	word	PARAM_3-MO_ARROW_HEIGHT-1, 2, \
		PARAM_3-MO_ARROW_HEIGHT-1, CGA_HORIZ_ARROW_WIDTH-1
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, \
		PARAM_3-1, 1
	word	PARAM_3-1, 2, \
		PARAM_3-1, CGA_HORIZ_ARROW_WIDTH-1
	word	PARAM_3-MO_ARROW_HEIGHT-1, CGA_HORIZ_ARROW_WIDTH, \
		PARAM_3-1, CGA_HORIZ_ARROW_WIDTH
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset CGAHDownInside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset CGAHDownOutside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset CGAHDownDepressedInside
	word	PARAM_3-MO_ARROW_HEIGHT-1, 1, offset CGAHDownDepressedOutside



if TV_SCROLLERS
	; TV Horizontal scrollbars
TVHorizScrollbar	label	word
	nptr	offset HVUpDownArrow
	word	1, 2, 1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1
	word	1, 1, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE, 1
	word	MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+1, 2, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1
	word	1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset HUpInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset HUpOutside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset HUpDepressedInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset HUpDepressedOutside

TVhsbThumb	label	word
	nptr	offset HVThumb
	word	PARAM_2, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1-1, PARAM_2, 1
	word	PARAM_2, 1, PARAM_3-1, 1
	word	PARAM_3, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1-1, PARAM_3, 2
	word	PARAM_2+1,MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1-1,PARAM_3,MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1-1
	word	PARAM_2+1, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1-1, PARAM_3, 2

	nptr	offset HVPageUpDn
	word	MO_ARROW_HEIGHT+TV_SCROLLER_INCREASE+2, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1, PARAM_2, 1

	nptr	offset HVPageUpDn
	word	PARAM_2+1, MO_SCROLLBAR_WIDTH+TV_SCROLLER_INCREASE-1, PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, 1

	nptr	offset HVUpDownArrow
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, 2, \
		PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, 1, \
		PARAM_3-2, 1
	word	PARAM_3-1, 2, \
		PARAM_3-1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE-1
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE, \
		PARAM_3-1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, 1+TV_SCROLLER_INCREASE/2, offset HDownInside
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, 1+TV_SCROLLER_INCREASE/2, offset HDownOutside
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, 1+TV_SCROLLER_INCREASE/2, offset HDownDepressedInside
	word	PARAM_3-MO_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, 1+TV_SCROLLER_INCREASE/2, offset HDownDepressedOutside
endif

	; Spin gadget (a.k.a TWISTED scrollbar)
spinGadget	label word
	nptr	offset HVUpDownArrow	; left, top, right, then bottom
	word	1, 2, 1, NUI_SPIN_ARROW_HEIGHT
	word	1, 1, MO_ARROW_WIDTH+1, 1
	word	MO_ARROW_WIDTH+1, 2, MO_ARROW_WIDTH+1, NUI_SPIN_ARROW_HEIGHT-1
	word	2, NUI_SPIN_ARROW_HEIGHT, \
		MO_ARROW_WIDTH+1, NUI_SPIN_ARROW_HEIGHT
	word	1, 1, offset spinUpInside
	word	1, 1, offset spinUpOutside
	word	1, 1, offset spinUpDepressedInside
	word	1, 1, offset spinUpDepressedOutside

spinDnArrow	label	word
	nptr	offset HVUpDownArrow
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT, 1, PARAM_3-2
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1, \
		MO_ARROW_WIDTH+1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1
	word	MO_ARROW_WIDTH+1, PARAM_3-NUI_SPIN_ARROW_HEIGHT, \
		MO_ARROW_WIDTH+1, PARAM_3-3
	word	2, PARAM_3-2, MO_ARROW_WIDTH+1, PARAM_3-2
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1, offset spinDownInside
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1, offset spinDownOutside
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1, \
		offset spinDownDepressedInside
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-1, \
		offset spinDownDepressedOutside

if TV_SCROLLERS
	; TV Spin gadget (a.k.a TWISTED scrollbar)
TVSpinGadget	label word
	nptr	offset HVUpDownArrow	; left, top, right, then bottom
	word	1, 2, 1, NUI_SPIN_ARROW_HEIGHT+TV_SCROLLER_INCREASE
	word	1, 1, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, 1
	word	MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, 2, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, NUI_SPIN_ARROW_HEIGHT+TV_SCROLLER_INCREASE-1
	word	2, NUI_SPIN_ARROW_HEIGHT+TV_SCROLLER_INCREASE, \
		MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, NUI_SPIN_ARROW_HEIGHT+TV_SCROLLER_INCREASE
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset spinUpInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset spinUpOutside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset spinUpDepressedInside
	word	1+TV_SCROLLER_INCREASE/2, 1+TV_SCROLLER_INCREASE/2, offset spinUpDepressedOutside

TVSpinDnArrow	label	word
	nptr	offset HVUpDownArrow
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE, 1, PARAM_3-2
	word	1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1, \
		MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE-1
	word	MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE, \
		MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, PARAM_3-3
	word	2, PARAM_3-2, MO_ARROW_WIDTH+TV_SCROLLER_INCREASE+1, PARAM_3-2
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset spinDownInside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, offset spinDownOutside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, \
		offset spinDownDepressedInside
	word	1+TV_SCROLLER_INCREASE/2, PARAM_3-NUI_SPIN_ARROW_HEIGHT-TV_SCROLLER_INCREASE+TV_SCROLLER_INCREASE/2-1, \
		offset spinDownDepressedOutside
endif

VUpInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001100b, 00000000b
	byte	00011110b, 00000000b
	byte	00110011b, 00000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte 	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000110b, 00000000b
	byte	00001111b, 00000000b
	byte	00011111b, 10000000b
	byte	00111111b, 11000000b
endif
endif

VUpOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01110011b, 10000000b
	byte	01100001b, 10000000b
	byte	01001100b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte 	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111001b, 11100000b
	byte	01110000b, 11100000b
	byte	01100000b, 01100000b
	byte	01000000b, 00100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
endif
endif

VUpDepressedInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000110b, 00000000b
	byte	00001111b, 00000000b
	byte	00011001b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,10,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte 	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 00000000b
	byte	00000111b, 10000000b
	byte	00001111b, 11000000b
	byte	00011111b, 11100000b
endif
endif

VUpDepressedOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111001b, 10000000b
	byte	01110000b, 10000000b
	byte	01100110b, 00000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte 	01111111b, 11100000b
	byte 	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111100b, 11100000b
	byte	01111000b, 01100000b
	byte	01110000b, 00100000b
	byte	01100000b, 00000000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
endif
endif


VDownInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00110011b, 00000000b
	byte	00011110b, 00000000b
	byte	00001100b, 00000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00111111b, 11000000b
	byte	00011111b, 10000000b
	byte	00001111b, 00000000b
	byte	00000110b, 00000000b
endif
endif

VDownOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01001100b, 10000000b
	byte	01100001b, 10000000b
	byte	01110011b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01000000b, 00100000b
	byte	01100000b, 01100000b
	byte	01110000b, 11100000b
	byte	01111001b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
endif
endif

VDownDepressedInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00011001b, 10000000b
	byte	00001111b, 00000000b
	byte	00000110b, 00000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,10,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00011111b, 11100000b
	byte	00001111b, 11000000b
	byte	00000111b, 10000000b
	byte	00000011b, 00000000b
endif
endif

VDownDepressedOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01100110b, 00000000b
	byte	01110000b, 10000000b
	byte	01111001b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
	byte	01111111b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_WIDTH,MO_ARROW_HEIGHT,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01100000b, 00000000b
	byte	01110000b, 00100000b
	byte	01111000b, 01100000b
	byte	01111100b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
endif
endif

	
HUpInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT-1,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 00000000b
	byte	00000110b, 00000000b
	byte	00001100b, 00000000b
	byte	00001100b, 00000000b
	byte	00000110b, 00000000b
	byte	00000011b, 00000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT-1,10,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 00000000b
	byte	00000011b, 00000000b
	byte	00000111b, 00000000b
	byte	00001111b, 00000000b
	byte	00001111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000011b, 00000000b
	byte	00000001b, 00000000b
endif
endif

HUpOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT-1,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111100b, 11110000b
	byte	01111001b, 11110000b
	byte	01110011b, 11110000b
	byte	01110011b, 11110000b
	byte	01111001b, 11110000b
	byte	01111100b, 11110000b
	byte	01111111b, 11110000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT-1,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111110b, 11110000b
	byte	01111100b, 11110000b
	byte	01111000b, 11110000b
	byte	01110000b, 11110000b
	byte	01110000b, 11110000b
	byte	01111000b, 11110000b
	byte	01111100b, 11110000b
	byte	01111110b, 11110000b
	byte	01111111b, 11110000b
endif
endif

HUpDepressedInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT-1,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 10000000b
	byte	00000011b, 00000000b
	byte	00000110b, 00000000b
	byte	00000110b, 00000000b
	byte	00000011b, 00000000b
	byte	00000001b, 10000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT-1,11,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 10000000b
	byte	00000001b, 10000000b
	byte	00000011b, 10000000b
	byte	00000111b, 10000000b
	byte	00000111b, 10000000b
	byte	00000011b, 10000000b
	byte	00000001b, 10000000b
	byte	00000000b, 10000000b
endif
endif

HUpDepressedOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT-1,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111111b, 11110000b
	byte	01111110b, 01110000b
	byte	01111100b, 11110000b
	byte	01111001b, 11110000b
	byte	01111001b, 11110000b
	byte	01111100b, 11110000b
	byte	01111110b, 01110000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT-1,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111111b, 11110000b
	byte	01111111b, 01110000b
	byte	01111110b, 01110000b
	byte	01111100b, 01110000b
	byte	01111000b, 01110000b
	byte	01111000b, 01110000b
	byte	01111100b, 01110000b
	byte	01111110b, 01110000b
	byte	01111111b, 01110000b
endif
endif


HDownInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <8,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b
	byte	00000000b
	byte	00001100b
	byte	00000110b
	byte	00000011b
	byte	00000011b
	byte	00000110b
	byte	00001100b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <9,10,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000100b, 00000000b
	byte	00000110b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 10000000b
	byte	00000111b, 10000000b
	byte	00000111b, 00000000b
	byte	00000110b, 00000000b
	byte	00000100b, 00000000b
endif
endif

HDownOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte	01110011b, 11100000b
	byte	01111001b, 11100000b
	byte	01111100b, 11100000b
	byte	01111100b, 11100000b
	byte	01111001b, 11100000b
	byte	01110011b, 11100000b
	byte	01111111b, 11100000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111011b, 11110000b
	byte	01111001b, 11110000b
	byte	01111000b, 11110000b
	byte	01111000b, 01110000b
	byte	01111000b, 01110000b
	byte	01111000b, 11110000b
	byte	01111001b, 11110000b
	byte	01111011b, 11110000b
	byte	01111111b, 11110000b
endif
endif

HDownDepressedInside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <9,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000110b, 00000000b
	byte	00000011b, 00000000b
	byte	00000001b, 10000000b
	byte	00000001b, 10000000b
	byte	00000011b, 00000000b
	byte	00000110b, 00000000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <10,11,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000010b, 00000000b
	byte	00000011b, 00000000b
	byte	00000011b, 10000000b
	byte	00000011b, 11000000b
	byte	00000011b, 11000000b
	byte	00000011b, 10000000b
	byte	00000011b, 00000000b
	byte	00000010b, 00000000b
endif
endif

HDownDepressedOutside	label	byte
if MO_ARROW_WIDTH eq 10
	Bitmap <MO_ARROW_HEIGHT,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11100000b
	byte	01111111b, 11100000b
	byte	01111001b, 11100000b
	byte	01111100b, 11100000b
	byte	01111110b, 01100000b
	byte	01111110b, 01100000b
	byte	01111100b, 11100000b
	byte	01111001b, 11100000b
else
if MO_ARROW_WIDTH eq 12
	Bitmap <MO_ARROW_HEIGHT,MO_ARROW_WIDTH-1,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111111b, 11110000b
	byte	01111101b, 11110000b
	byte	01111100b, 11110000b
	byte	01111100b, 01110000b
	byte	01111100b, 00110000b
	byte	01111100b, 00110000b
	byte	01111100b, 01110000b
	byte	01111100b, 11110000b
	byte	01111101b, 11110000b
endif
endif


CGAHUpInside	label	byte
	Bitmap <9,6,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 10000000b
	byte	00001111b, 10000000b
	byte	00001111b, 10000000b
	byte	00000011b, 10000000b
	
CGAHUpOutside	label	byte
	Bitmap <12,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111100b, 01110000b
	byte	01110000b, 01110000b
	byte	01110000b, 01110000b
	byte	01111100b, 01110000b
	byte	01111111b, 11110000b
	
CGAHUpDepressedInside	label	byte
	Bitmap <10,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 11000000b
	byte	00000111b, 11000000b
	byte	00000111b, 11000000b
	byte	00000001b, 11000000b
	
CGAHUpDepressedOutside	label	byte
	Bitmap <12,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111111b, 11110000b
	byte	01111110b, 00110000b
	byte	01111000b, 00110000b
	byte	01111000b, 00110000b
	byte	01111110b, 00110000b
	
CGAHDownInside	label	byte
	Bitmap <9,6,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001110b, 00000000b
	byte	00001111b, 10000000b
	byte	00001111b, 10000000b
	byte	00001110b, 00000000b
		
CGAHDownOutside	label	byte
	Bitmap <12,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01110001b, 11110000b
	byte	01110000b, 01110000b
	byte	01110000b, 01110000b
	byte	01110001b, 11110000b
	byte	01111111b, 11110000b
		
CGAHDownDepressedInside	label	byte
	Bitmap <10,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 11000000b
	byte	00000111b, 11000000b
	byte	00000111b, 00000000b
		
CGAHDownDepressedOutside	label	byte
	Bitmap <12,7,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111111b, 11110000b
	byte	01111000b, 11110000b
	byte	01111000b, 00110000b
	byte	01111000b, 00110000b
	byte	01111000b, 11110000b
		
spinUpInside	label	byte
	Bitmap <10,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000010b, 00000000b
	byte	00000111b, 00000000b
	byte	00001111b, 10000000b
	byte	00011111b, 11000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b

spinUpOutside	label	byte
	Bitmap <12,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111101b, 11110000b
	byte	01111000b, 11110000b
	byte	01110000b, 01110000b
	byte	01100000b, 00110000b
	byte	01111000b, 11110000b
	byte	01111000b, 11110000b
	byte	01111000b, 11110000b
	byte	01111111b, 11110000b

spinUpDepressedInside	label	byte
	Bitmap <11,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 00000000b
	byte	00000011b, 10000000b
	byte	00000111b, 11000000b
	byte	00001111b, 11100000b
	byte	00000011b, 10000000b
	byte	00000011b, 10000000b
	byte	00000011b, 10000000b

spinUpDepressedOutside	label	byte
	Bitmap <12,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111110b, 11110000b
	byte	01111100b, 01110000b
	byte	01111000b, 00110000b
	byte	01110000b, 00010000b
	byte	01111100b, 01110000b
	byte	01111100b, 01110000b
	byte	01111100b, 01110000b

spinDownInside	label	byte
	Bitmap <10,8,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00011111b, 11000000b
	byte	00001111b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b

spinDownOutside	label	byte
	Bitmap <12,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111000b, 11110000b
	byte	01111000b, 11110000b
	byte	01111000b, 11110000b
	byte	01100000b, 00110000b
	byte	01110000b, 01110000b
	byte	01111000b, 11110000b
	byte	01111101b, 11110000b
	byte	01111111b, 11110000b

spinDownDepressedInside	label	byte
	Bitmap <11,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 10000000b
	byte	00000011b, 10000000b
	byte	00000011b, 10000000b
	byte	00001111b, 11100000b
	byte	00000111b, 11000000b
	byte	00000011b, 10000000b
	byte	00000001b, 00000000b

spinDownDepressedOutside	label	byte
	Bitmap <12,9,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	01111111b, 11110000b
	byte	01111100b, 01110000b
	byte	01111100b, 01110000b
	byte	01111100b, 01110000b
	byte	01110000b, 00010000b
	byte	01111000b, 00110000b
	byte	01111100b, 01110000b
	byte	01111110b, 11110000b


;
; Gauge drawing commands
;


vertGauge	label	word
	nptr	offset HVPageUpDnLight
	word	3, 1, MO_SCROLLBAR_WIDTH-3, PARAM_2

	nptr	offset GaugePageUpDn
	word	3, PARAM_2+1, MO_SCROLLBAR_WIDTH-3, PARAM_3-1


horizGauge	label	word
	nptr	offset GaugePageUpDn
	word	1, MO_SCROLLBAR_WIDTH-3, PARAM_2, 3

	nptr	offset HVPageUpDnLight
	word	PARAM_2+1, MO_SCROLLBAR_WIDTH-3, PARAM_3-1, 3

CGAHorizGauge	label	word
	nptr	offset GaugePageUpDn
	word	1, CGA_HORIZ_SCROLLBAR_WIDTH-2, PARAM_2, 2

	nptr	offset HVPageUpDnLight
	word	PARAM_2+1, CGA_HORIZ_SCROLLBAR_WIDTH-2, PARAM_3-1, 2




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSBPart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to draw a part of a scrollbar

CALLED BY:	INTERNAL
PASS:		ax,bx	- position to draw
		cx,dx	- parameters
		si	- offset to routine to draw
RETURN:		si	- offset of next routine to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSBPart		proc	far
	uses	ax, bx, cx, dx
	ltColor		local	word		;need to match these up with
	rbColor		local	word		;  above routines so we can
	fillColor	local	word		;  call SetScrollbarColors,
	fillSelColor	local	word		;  and DrawThumb.
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local OLScrollbarAttrs	;save state here
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	.enter	inherit

	; save away the draw position and parameter, and call the routine

	mov	ss:posX, ax
	mov	ss:posY, bx
	mov	ss:param2, cx
	mov	ss:param3, dx
	lodsw
	call	ax

	.leave
	ret
DrawSBPart		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVUpDownArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the up or down arrow

CALLED BY:	INTERNAL
		indirectly through DrawUpArrow
PASS:		ds:si	- points to table of coords
RETURN:		si	- points directly after table
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HVUpDownArrow	proc	near
	ltColor		local	word		;need to match these up with
	rbColor		local	word		;  above routines so we can
	fillColor	local	word		;  call SetScrollbarColors,
	fillSelColor	local	word		;  and DrawThumb.
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local	OLScrollbarAttrs	;save state here
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
	.enter	inherit

	call	SetLTColor		; set color for left/top
	call	DrawSBLine
	call	DrawSBLine

	call	SetRBColor		; set color for bottom edge
	call	DrawSBLine		; draw bottom edge
	call	DrawSBLine

	tst	selected?
	jnz	notsel

	add	si, 12
	call	SetBlackColor		; set fill color
	call	FillSBBitmap
	call	SetFillColor		; set fill color
	call	FillSBBitmap
	jmp	done

notsel:
	call	SetBlackColor
	call	FillSBBitmap
	call	SetFillColor
	call	FillSBBitmap
	add	si, 12
done:
	.leave
	ret		
HVUpDownArrow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVThumb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to draw a scrollbar thumb

CALLED BY:	INTERNAL
		indirectly, from DrawThumb
PASS:		ax,bx	- position to draw
		cx,dx	- parameters (used to be PlayString parameters)
RETURN:		si	- offset to next routine to call
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HVThumb	proc	near

	call	SetLTColor			;set left/top
	call	DrawSBLine
	call	DrawSBLine

	call	SetRBColor			;set right/bottom color
	call	DrawSBLine
	call	DrawSBLine

	call	SetFillColor			;set fill color
	call	FillSBRect

	ret
HVThumb	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVPageUpDn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw "page up" part of scrollbar

CALLED BY:	INTERNAL
		indirectly, via DrawPageUpDownArea
PASS:		ax,bx	- position to draw
		cx,dx	- parameters
RETURN:		si	- points to next section to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HVPageUpDn	proc	near
	push	si			;we need to push and pop si because
					; we are drawing the same thing twice

	mov	al, SDM_50 or mask SDM_INVERSE
	call	GrSetAreaMask
	call	SetFillColor		;Once using light color
	call	FillSBRect

	pop	si

	mov	al, SDM_50
	call	GrSetAreaMask
	call	SetWhiteColor		;And again using white
	call	FillSBRect

	mov	al, SDM_100		;reset draw mask
	call	GrSetAreaMask
	ret
HVPageUpDn	endp

HVPageUpDnLight	proc	near	;really drawing nothing, for gauges
	call	SetFillColor
	call	FillSBRect
	ret
HVPageUpDnLight	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GaugePageUpDn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw "page up" & "page down" part of gauge (read-only GenValue)

CALLED BY:	INTERNAL
		indirectly, via DrawPageUpDownArea
PASS:		ax,bx	- position to draw
		cx,dx	- parameters
RETURN:		si	- points to next section to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/3/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GaugePageUpDn	proc	near
	push	ds
	mov	ax, segment moCS_flags
	mov	ds, ax
	mov	al, ds:moCS_activeTitleBar
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	pop	ds
	call	FillSBRect
	ret
GaugePageUpDn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSBLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		ax,bx,cx,dx	- increments to left/top position
		inherits draw position and parameters
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		add the draw position and call GrDrawLine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSBLine	proc	near

		; add the draw position to all the coordinates

		lodsw			; get ax
		mov	dx, ax		; save for later
		lodsw
		mov	bx, ax
		lodsw
		mov	cx, ax
		lodsw
		xchg	dx, ax
		call	ApplySBParams
		call	GrDrawLine	; and call the graphics system

		ret
DrawSBLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		ax,bx,cx,dx	- increments to left/top position
		inherits draw position and parameters
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillRect

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBRect	proc	near

		; add the draw position to all the coordinates

		lodsw			; get ax
		mov	dx, ax		; save for later
		lodsw
		mov	bx, ax
		lodsw
		mov	cx, ax
		lodsw
		xchg	dx, ax
		call	ApplySBParams	; apply parameters, if needed
		call	GrFillRect	; and call the graphics system

		ret
FillSBRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		ax,bx	- increments to position
		ds:si	- offset to bitmap to draw
		inherits draw position and parameters
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillBitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBBitmap	proc	near
	ltColor		local	word		;need to match these up with
	rbColor		local	word		;  above routines so we can
	fillColor	local	word		;  call SetScrollbarColors,
	fillSelColor	local	word		;  and DrawThumb.
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local OLScrollbarAttrs	;save state here
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
		.enter inherit
		ForceRef param2, param3

		; add the draw position to all the coordinates

		lodsw				; get x valuer
		mov	bx, ax
		lodsw
		call	ApplySBParam
		xchg	ax, bx
		call	ApplySBParam
		add	ax, ss:posX		; setup coords
		add	bx, ss:posY
		push	si
		mov	si, ds:[si]		; get ptr to bitmap
		clr	cx, dx			; no callback
		call	GrFillBitmap		; and call the graphics system
		pop	si			; restore table pointer
		add	si, 2			; bump past bitmap ptr

		.leave
		ret
FillSBBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplySBParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used to apply what used to be GString params

CALLED BY:	INTERNAL
PASS:		ax,bx,cx,dx	- coordinates to modify
		inherits frame with parameters
RETURN:		ax,bx,cx,dx	- modified coords
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplySBParams	proc	near
	ltColor		local	word		;need to match these up with
	rbColor		local	word		;  above routines so we can
	fillColor	local	word		;  call SetScrollbarColors,
	fillSelColor	local	word		;  and DrawThumb.
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local OLScrollbarAttrs	;save state here
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
		.enter inherit
		ForceRef param2, param3

		call	ApplySBParam
		xchg	ax, bx
		call	ApplySBParam
		xchg	ax, cx
		call	ApplySBParam
		xchg	ax, dx
		call	ApplySBParam
		xchg	ax, bx
		xchg	bx, cx
		xchg	cx, dx
		add	ax, ss:posX	; setup coords
		add	bx, ss:posY
		add	cx, ss:posX
		add	dx, ss:posY

		.leave
		ret
ApplySBParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplySBParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine, modifies one parameter

CALLED BY:	INTERNAL
PASS:		ax	- coord to modify
		inherits frame with param info
RETURN:		ax	- modified coord
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplySBParam	proc	near
	ltColor		local	word		;need to match these up with
	rbColor		local	word		;  above routines so we can
	fillColor	local	word		;  call SetScrollbarColors,
	fillSelColor	local	word		;  and DrawThumb.
	darkColor	local	word
	gstate		local	hptr.GState
	scrPtr		local	word
	scrLen		local	word
	selected?	local	byte
	attrs		local OLScrollbarAttrs	;save state here
	posX		local	word
	posY		local	word
	param2		local	word
	param3		local	word
		.enter inherit
		ForceRef posX, posY

		cmp	ax, PARAM_1 + 1000h	; do bounds check
		jb	done
		cmp	ax, PARAM_3 + 1000h	; check high end
		jb	applySomething
done:
		.leave
		ret

		; we need to apply a parameter
applySomething:
		cmp	ax, PARAM_2 + 1000
		jae	applyP3
		sub	ax, PARAM_2
		add	ax, ss:param2
		jmp	done
applyP3:
		sub	ax, PARAM_3
		add	ax, ss:param3
		jmp	done
ApplySBParam	endp

ScrollbarCommon ends
