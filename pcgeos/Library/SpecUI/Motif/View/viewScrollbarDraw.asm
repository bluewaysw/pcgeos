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

	$Id: viewScrollbarDraw.asm,v 1.1 97/04/07 11:03:12 newdeal Exp $

-------------------------------------------------------------------------------@


;	Constants for scrollbar draw params.

; 0000-3fff -> positive coordinate
; 4800-57ff - P_ARROW_WIDTH + coordinate
;	4800-4fff - P_ARROW_WIDTH + negative coordinate
;	5000-57ff - P_ARROW_WIDTH + positive coordinate
; etc. 

P_ARROW_WIDTH		=	05000h
P_ARROW_HEIGHT		=	06000h
P_BEGIN_REGION		=	07000h
P_END_REGION		=	08000h
P_ARROW_MID		=	09000h
P_END_MINUS_ARROW	=	0a000h


ScrollbarCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawScrollbar

DESCRIPTION:	Draw a motif Scrollbar.  Works on any display.

CALLED BY:	OLScrollbarDraw

PASS:
	*ds:si - scrollbar
	es - segment of MetaClass
	ch - update flag: non-zero if "minimally" updating
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

------------------------------------------------------------------------------@

	
DrawScrollbar	proc	far			;passed instance ptr in ds:si
	class	OLScrollbarClass
	
	ltColor		local	word		;left/top color
	rbColor		local	word		;right/bottom color
	fillColor	local	word		;fill color
	fillSelColor	local	word		;fill selected color
	darkColor	local	word		;dark fill
	gstate		local	hptr.GState	;gstate
	scrHan		local	word		;chunk handle of instance
	scrPtr		local	word		;ptr to OLScrollbarInstance
	scrLen		local	word		;length of scrollbar
	selected?	local	byte		;selected flag (zero if sel)
	attrs		local	OLScrollbarAttrs
	updating	local	byte
	readOnly	local	byte
	arrowSize	local	word
	
	posX		local	word
	posY		local	word
	param0		local	word		;arrow width
	param1		local	word		;arrow height
	param2		local	word		;some kind of passed start
	param3		local	word		;some kind of passed end
	param4		local	word		;1/2 arrow width
	param5		local	word		;param3 - arrow height
	
	valueText	local	GEN_VALUE_MAX_TEXT_LEN dup(TCHAR)
	valueTextPos	local	word		;x coord for drawing text
	.enter
	;
	; Set up a few things right now.
	; 
	mov	gstate, di			;save away gstate
	mov	updating, ch			;save updating flag
	tst	ch				;updating, don't draw outline
	jnz	10$
	call	DrawOutline			;do this NOW.
10$:
	mov	scrHan, si			;save chunk in case deref
						; needed
	mov	si, ds:[si]			;dereference scrollbar
	push	si
	add	si, ds:[si].Vis_offset		;ds:[di] -- SpecInstance
	mov	scrPtr, si			;save scrollbar pointer
	mov	dx, ds:[si].OLSBI_attrs		;get attributes
	mov	attrs, dx			;save in local vars
	mov	dx, ds:[si].OLSBI_arrowSize	;save arrow size
	mov	arrowSize, dx
	pop	si

	;
	; Set read-only flag as needed.
	;
	clr	readOnly
	push	si
	add	si, ds:[si].Gen_offset
	test	ds:[si].GI_attrs, mask GA_READ_ONLY
	jz	12$
	dec	readOnly
12$:
	pop	si
	call	SetupDrawColors			;sets up colors
	call	SetupDrawParams			;sets up parameters

	mov	di, scrPtr			;point to scrollbar spec inst

	;
	; Code added 2/ 7/92 cbh to hopefully make these things shorter in CGA.
	; Mouse press stuff should still work since we don't care about vertical
	; checking.  (We've shortened the scrollbar, so we need to fool it into
	; thinking it needs to be drawn higher.)  (Nuked for the new arrow size.
	; -cbh 11/10/92)
	;
;	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED			       
;	jz	20$				;not a twisty scrollbar, branch
;	call	OpenCheckIfCGA			;we'll see if this helps
;	jnc	20$
;	dec	bx				;move down arrow up a bit
;20$:
;
	call	DrawUpArrow			;draw the up arrow
	
	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED			       
	jz	testScrollable			;not a twisty scrollbar, branch
	add	ax, es:[di].OLSBI_arrowSize
						;else put down arrow to the    
						;   right of the up arrow.
	;
	; Code added 2/ 7/92 cbh to hopefully make these things shorter in CGA.
	; Mouse press stuff should still work since we don't care about vertical
	; checking.  (We've shortened the scrollbar, so we need to fool it into
	; thinking it needs to be drawn lower.)  (Nuked for new arrow size.
	; -cbh 11/10/92)
	;
;	call	OpenCheckIfCGA			;we'll see if this helps
;	jnc	testScrollable
;	add	bx, 2				;move down arrow down a bit
testScrollable:							     
	call	DrawThumb			;draw the thumb
	;
	; Now draw page up area.
	;
	push	cx
	clr	cx
	call	OpenCheckIfBW
	jnc	22$
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	22$				;slider, no arrow shadow.
	inc	cx
22$:
	cmp	es:[di].OLSBI_elevOffset, cx	;near top for B/W shadows?
	pop	cx				;or at top for color?
	jg	25$					;no, draw page up stuff

	add	si, offset vsbPageDn - offset vsbPageUp  ;else skip data
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	pageDown			    ;not a slider, branch
	add	si, (offset vsPageDn - offset vsPageUp) - \
		    (offset vsbPageDn - offset vsbPageUp)
	jmp	short pageDown

25$:
	jz	pageDown			;yes, skip
	call	DrawPageUpArea			;else draw the page up area
pageDown:
	;
	; Switch arguments: arg0 is thumb bottom, arg1 is scrollbar bottom.
	;
	mov	cx, dx				;move thumb bottom to cx
	mov	dx, scrLen			;keep scrollbar length in dx
	;
	; Now draw page down area.
	;
	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED
	jnz	40$				;twisted, skip page down
	tst	es:[di].OLSBI_elevOffset
	js	45$				;if no thumb, definitely draw
	push	ax
	mov	ax, es:[di].OLSBI_scrArea	;get current scroll area
	sub	ax, es:[di].OLSBI_elevLen	;subtract height of thumb
	sub	ax, es:[di].OLSBI_elevOffset	;see if near bottom already

	call	OpenCheckIfBW
	jnc	30$
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	30$				;slider, don't worry about shadw
	dec	ax				;one more pixel for B/W...
30$:
	cmp	ax, 0				;see if anything to draw 
	pop	ax				;
	jg	45$				;yes, branch to draw 
40$:						;else skip
	add	si, offset vsbDnArrow - offset vsbPageDn
	jmp	short downArrow

45$:
	call	DrawPageDownArea		;draw the page down area
	
downArrow:
	;
	; Now, draw the down arrow.
	;
	call	DrawDownArrow			;draw the down arrow	
	mov	di, gstate
	mov	ax, SDM_100			;reset to 100% pattern
	call	GrSetLineMask
	call	GrSetAreaMask
	.leave
	ret
DrawScrollbar	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDrawColors

SYNOPSIS:	Set up colors for drawing the scrollbar.

CALLED BY:	DrawScrollbar

PASS:		ds:si  -- object pointer
		ss:bp  -- DrawBar_localVars
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
	.enter	inherit	DrawScrollbar

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
		
	mov	al, ds:[moCS_dsLightColor]
	clr	ah	
	mov	fillColor, ax			; store as the fill color
	mov	al, ds:[moCS_dsDarkColor]
	clr	ah	
	mov	fillSelColor, ax
	mov	rbColor, ax
	mov	ltColor, C_WHITE			; l/t color is white
	mov	fillSelColor, ax
	mov	darkColor, ax			; store as right/bot color
	mov	rbColor, ax
	mov	ltColor, C_WHITE			; l/t color is white
	
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
	; should be drawn.
	;
	mov	bp, ds:[si]			;don't do it if slider
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLSBI_attrs, mask OLSA_TWISTED
	jnz	draw				;twisted, use bounds.

	call	SwapVert			;allow horizontal assumption
	mov	dx, bx				;get top edge
	add	dx, ds:[bp].OLSBI_arrowSize
	add	dx, 2
	call	SwapVert			;restore proper reg order

draw:
	pop	bp
	call	OpenDrawRect			;draw the inset rect
						;  (clears inside, which is a
						;   problem)
exit:
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

PASS:		ds:si -- scrollbar ptr

RETURN:		ds:si  -- pointing at start of graphics string
		es     -- scrollbar's segment
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
	.enter	inherit	DrawScrollbar
	segmov	es, ds, ax			;es points to data
	segmov	ds, cs, ax			;ds points to
	mov	di, scrPtr			;point to SpecInstance
	mov	cx, es:[di].OLSBI_elevOffset	;pass elev offset in cx
	clr	ax
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	5$
	add	cx, es:[di].OLSBI_arrowSize
	add	cx, 3

	mov	ax, es:[di].OLSBI_arrowSize	;for checking for too large...
	add	ax, 3
	jmp	short 6$
5$:
	inc	cx				;slider, adjust so we're not
						;  against the edge.  4/ 9/93 
6$:
	mov	dx, cx				;now add elevLen for thumb bot
	add	dx, es:[di].OLSBI_elevLen	;

	;	
	; New code 3/21/93 cbh to limit the thumb bottom, in case the scrollbar
	; is dealing with an illegal value situation, as can (sigh) still
	; arise when scaling a view.
	;
	add	ax, es:[di].OLSBI_scrArea	;ax <- scr area + any arrow
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	65$
	inc	ax				;beats me why I need this. 4/ 9
65$:
	cmp	dx, ax				;limit length of thumb
	jbe	7$
	mov	dx, ax
7$:
	dec	dx				;this is needed regardless of
						;  above code.

	or	es:[di].OLSBI_attrs, mask OLSA_DRAWN_ENABLED
	test	es:[di].OLSBI_attrs, mask OLSA_ENABLED
	jnz	10$				;enabled, branch
	
	and	es:[di].OLSBI_attrs, not mask OLSA_DRAWN_ENABLED
10$:
	push	cx, dx
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	pushf					;save whether slider for later

	test	es:[di].OLSBI_attrs, mask OLSA_VERTICAL	or mask OLSA_TWISTED
	jz	horiz				;nope, branch

	mov	si, offset vertScrollbar	;assume we use scrollable data 
	mov	cx, offset vertSlider		;in case we're a slider
	mov	dx, offset vertGauge		;in case we're a gauge
	;
	; First load ax, bx, cx, dx with left, top, elevOffset and height
	;
	mov	ax, es:[di].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[di].VI_bounds.R_top	;pass top in bx
	mov	di, es:[di].VI_bounds.R_bottom	;pass height in scrLen

	dec	di				;one less, for new graphics
	sub	di, bx
	mov	scrLen, di
	jmp	short checkSlider		;and go check for sliders

horiz:
	mov	si, offset horizScrollbar	;assume we use scrollable data 
	mov	cx, offset horizSlider		;in case we're a slider
	mov	dx, offset horizGauge		;in case we're a gauge

	test	es:[di].OLSBI_attrs, mask OLSA_TEXT_TOO
	jz	getHorizBounds
	mov	dx, offset horizTextGauge
getHorizBounds:

	mov	ax, es:[di].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[di].VI_bounds.R_top	;pass top in bx
	mov	di, es:[di].VI_bounds.R_right	;pass width in scrLen
	dec	di				;one less, for new graphics
	sub	di, ax				;
	mov	scrLen, di

checkSlider:
	popf					;see if slider
	jz	exit				;no, exit
	mov	si, cx				;else use slider stuff
	tst	readOnly			;read-only, use gauge stuff
	jz	exit
	mov	si, dx
	mov	di, scrPtr
	test	es:[di].OLSBI_attrs, mask OLSA_TEXT_TOO
	jnz	getText
exit:
	pop	cx, dx
	.leave
	ret

getText:
	;
	; Need to fetch the value text
	;
	push	ds, ax, bx, si
	segmov	ds, es
	mov	si, scrHan
	;
	; Ask ourselves for the text.
	; 
	push	bp
	lea	dx, ss:[valueText]
	mov	cx, ss
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	ObjCallInstanceNoLockES
	pop	bp
	;
	; Compute the width of the value text so we can center the thing
	;
	mov	di, gstate
	push	ds
	lea	si, ss:[valueText]
	segmov	ds, ss
	mov	cx, GEN_VALUE_MAX_TEXT_LEN
	call	GrTextWidth
	pop	ds
	;
	; Compute the left edge of the text to center it
	;
	mov	ax, scrLen			; ax <- sb "length"
	sub	ax, dx
	sar	ax
	mov	valueTextPos, ax

	pop	ds, ax, bx, si
	jmp	exit
	
SetupDrawParams	endp



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
	.enter	inherit	DrawScrollbar
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	exit

	;
	; If updating, skip the up arrow.
	;
	tst	updating
	jz	5$
	add	si, offset vsbThumb - offset vertScrollbar
	jmp	short exit
5$:
	push	ax
	mov	ah, es:[di].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	sub	ah, OLSS_INC_UP			;check increment up selected
	mov	selected?, ah			;store as selected flag
	pop	ax
	
	call	DrawSBPart			; draw part of the scrollbar
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
	.enter	inherit	DrawScrollbar
	;
	; Draw the thumb
	;
	tst	readOnly			;see if read-only
	jnz	20$				;yep, no thumb

	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED
	jnz	5$
	tst	es:[di].OLSBI_elevOffset	;if negative, no thumb
	jns	10$				;using thumb, draw it
5$:
	add	si, offset vsbPageUp - offset vsbThumb
	jmp	short 20$			;else skip it
10$:
if	0					;not inverting thumb for now...
	push	ax
	mov	ah, es:[di].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	sub	ah, OLSS_DRAG_AREA		;check increment up selected
	mov	selected?, ah			;store as selected flag
	pop	ax
else
	mov	selected?, 1			;not selected
endif

	;
	; New code to do weird things if we're a slider.  -cbh 4/ 8/93
	;
	push	cx
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	15$

	push	si, dx		
	sub	dx, cx				; halve the elevator length
	shr	dx, 1		
	add	dx, cx		
	call	DrawSBPart			; draw top half
	inc	dx
	mov	cx, dx				; prepare to draw bottom half.
	pop	si, dx
15$:
	call	DrawSBPart			; draw part of the scrollbar
	pop	cx
20$:
	.leave
	ret
DrawThumb	endp
		
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawPageUpArea

SYNOPSIS:	Draws the scrollbar's page up area.

CALLED BY:	DrawBWScrollbar

PASS:		es:di -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- region start
		dx     -- region end

RETURN:		si     -- pointing past the gstring

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@
	
DrawPageUpArea	proc	near
	.enter	inherit	DrawScrollbar

	call	DrawSBPart		; draw part of the scrollbar
	.leave
	ret
DrawPageUpArea	endp
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawPageDownArea

SYNOPSIS:	Draws the scrollbar's page down area.

CALLED BY:	DrawBWScrollbar

PASS:		es:di -- scrollbar SpecInstance
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
	
DrawPageDownArea	proc	near
	.enter	inherit	DrawScrollbar

	push	cx, dx
	;
	; Shadow avoidance code moved out of the low level code so we can
	; fix the bug of avoiding a shadow that isn't there if there's no
	; thumb.  Also cleaner to have the code here.  -cbh 4/ 8/93
	;
	call	OpenCheckIfBW		; see if B/W
	jnc	10$			; nope, branch

	inc	dx			; always draw one more pixel in B/W

	test	es:[di].OLSBI_attrs, mask OLSA_TWISTED	;any thumb?
	jnz	10$					;no, branch
	tst	es:[di].OLSBI_elevOffset	
	js	10$					;no, branch
	inc	cx			; else avoid the shadow
10$:

	call	DrawSBPart		; draw part of the scrollbar
	pop	cx, dx
	.leave
	ret
DrawPageDownArea	endp
		

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
	.enter	inherit	DrawScrollbar
	test	es:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	exit

	;
	; If updating, skip the down arrow.  We won't worry about si, since
	; this is the last thing to draw.
	;
	tst	updating
	jnz	exit

	push	ax
	mov	ah, es:[di].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	sub	ah, OLSS_INC_DOWN		;check increment up selected
	mov	selected?, ah			;store as selected flag
	pop	ax

	call	DrawSBPart			; draw part of the scrollbar
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
	.enter	inherit	DrawScrollbar
	push	ax
	tst	selected?			;see if selected
	jnz	10$				;not selected, branch
	mov	ax, C_BLACK			;use black if selected
	jmp	short 20$
10$:	
	mov	ax, ltColor			;use white if not selected
20$:
	call	GrSetLineColor
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	30$				;yes, branch
	mov	al, SDM_50			;else set draw mask
	call	GrSetLineMask
30$:
	pop	ax
	.leave
	ret
SetLTColor	endp
		
;------------------------
		
SetRBColor	proc	near
	.enter	inherit	DrawScrollbar
	push	ax
	tst	selected?			;see if selected
	jnz	10$				;not selected, branch
	mov	ax, ltColor			;selected, same as LT unselected
	jmp	short 20$
10$:	
	mov	ax, rbColor			;use r/b color
20$:
	call	GrSetLineColor
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	30$				;yes, branch
	mov	al, SDM_50			;else set draw mask
	call	GrSetLineMask
30$:
	pop	ax
	.leave
	ret
SetRBColor	endp

;--------------------------
	
SetFillColor	proc	near
	.enter	inherit	DrawScrollbar
	push	ax
	tst	selected?			;see if selected
	jnz	10$				;not selected, branch
	mov	ax, fillSelColor		;use fill sel color if selected
	jmp	short 20$
10$:	
	mov	ax, fillColor			;use fill color if not
20$:
	call	GrSetAreaColor
	mov	al, SDM_100
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	30$				;yes, branch
	mov	al, SDM_50			;else set draw mask
30$:
	call	GrSetAreaMask
	pop	ax
	.leave
	ret
SetFillColor	endp
		
SetDarkColor	proc	near
	.enter	inherit	DrawScrollbar
	push	ax
	mov	ax, darkColor			;use dark color if selected
	call	GrSetAreaColor

	mov	al, SDM_0			; assume not enabled
	test	attrs, mask OLSA_ENABLED
	jz	30$				; draw nothing if not enabled

	mov	al, SDM_100			; assume doing funky text thing,
						; so we want solid
	test	attrs, mask OLSA_TEXT_TOO
	jnz	30$
	mov	al, SDM_50 or mask SDM_INVERSE ;we do inverse so that when
						;  we disable, the dots go away
30$:
	call	GrSetAreaMask
	pop	ax
	.leave
	ret
SetDarkColor	endp
		
SetRevDarkColor	proc	near
	;
	; Uses light color to fill in the dots that the dark color missed.
	;
	.enter	inherit	DrawScrollbar
	push	ax
	mov	ax, fillColor			;use fill color
	call	GrSetAreaColor
	mov	al, SDM_50 			
	test	attrs, mask OLSA_ENABLED	;see if we're enabled
	jnz	30$				;yes, branch
	mov	al, SDM_0			;else set no mask
30$:
	call	GrSetAreaMask
	pop	ax
	.leave
	ret
SetRevDarkColor	endp
		

ArrowBitmaps	etype	word, 0, 2
	AB_INSIDE_UP_ARROW	enum	ArrowBitmaps
	AB_OUTSIDE_UP_ARROW	enum	ArrowBitmaps
	AB_INSIDE_DOWN_ARROW	enum	ArrowBitmaps
	AB_OUTSIDE_DOWN_ARROW	enum	ArrowBitmaps
	AB_INSIDE_LEFT_ARROW	enum	ArrowBitmaps
	AB_OUTSIDE_LEFT_ARROW	enum	ArrowBitmaps
	AB_INSIDE_RIGHT_ARROW	enum	ArrowBitmaps
	AB_OUTSIDE_RIGHT_ARROW	enum	ArrowBitmaps


; Note:	These routines were originally static graphics strings, and were 
;	converted when GrPlayString went away.  


	; vertical scrollbar code
vertScrollbar	label	word
	nptr	offset HVUpArrow
	word	1, P_ARROW_WIDTH+1, P_ARROW_MID, 2
	word	P_ARROW_MID+1, 2, P_ARROW_WIDTH, P_ARROW_HEIGHT
	word	P_ARROW_MID+2, 2, P_ARROW_WIDTH+1, P_ARROW_HEIGHT
	word	2, P_ARROW_HEIGHT, P_ARROW_WIDTH, P_ARROW_HEIGHT
	word	2, P_ARROW_HEIGHT+1, P_ARROW_WIDTH+1, P_ARROW_HEIGHT+1
	word	1, 1, AB_INSIDE_UP_ARROW
	word	1, 1, AB_OUTSIDE_UP_ARROW

vsbThumb	label	word
	nptr	offset HVThumb
	word	1, P_BEGIN_REGION, (P_ARROW_WIDTH+2)-3, P_BEGIN_REGION
	word	1, P_BEGIN_REGION, 1, P_END_REGION-1
	word	(P_ARROW_WIDTH+2)-2, P_BEGIN_REGION, (P_ARROW_WIDTH+2)-2, P_END_REGION
	word	1, P_END_REGION, (P_ARROW_WIDTH+2)-2, P_END_REGION
	word	2, P_END_REGION+1, (P_ARROW_WIDTH+2)-2, P_END_REGION+1  ;shadow

	word	2, P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-2, P_END_REGION   

startHackPixel	label	word
	;This is to draw in the single pixel next to the bottom line in B/W
	;if needed in the 50% mask.  This hopefully will do nothing in color.
	word	1, P_END_REGION+1, 1, P_END_REGION+1 ;color or B/W
endHackPixel	label	word

vsbPageUp	label	word
	nptr	offset HVPageUpDnAvoidShadow
	word	1, P_ARROW_HEIGHT+1, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION  ;color
	word	1, P_ARROW_HEIGHT+2, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION  ;B/W

vsbPageDn	label	word
	nptr	offset HVPageUpDn
	word	1, P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1, P_END_MINUS_ARROW-1 

vsbDnArrow	label	word
	nptr	offset HVDnArrow
	word	P_ARROW_WIDTH, P_END_MINUS_ARROW, P_ARROW_MID+1, P_END_REGION-2
	word	P_ARROW_WIDTH+1, P_END_MINUS_ARROW, P_ARROW_MID+2, P_END_REGION-2
	word	1, P_END_MINUS_ARROW, P_ARROW_WIDTH-1, P_END_MINUS_ARROW
	word	1, P_END_MINUS_ARROW, P_ARROW_MID, P_END_REGION-2
	word	1, P_END_MINUS_ARROW+1, AB_INSIDE_DOWN_ARROW
	word	1, P_END_MINUS_ARROW-1, AB_OUTSIDE_DOWN_ARROW


	; Horizontal scrollbars
horizScrollbar	label	word
	nptr	offset HVUpArrow
	word	2, (P_ARROW_MID+2)-1-1, P_ARROW_HEIGHT, 1
	word	P_ARROW_HEIGHT, (P_ARROW_WIDTH+2)-1-1, 2, (P_ARROW_MID+2)-1
	word	P_ARROW_HEIGHT, (P_ARROW_WIDTH+2)-1, 2, (P_ARROW_MID+2)
	word	P_ARROW_HEIGHT, (P_ARROW_WIDTH+2)-1-2, P_ARROW_HEIGHT, 2
	word	P_ARROW_HEIGHT+1, (P_ARROW_WIDTH+2)-1-1, P_ARROW_HEIGHT+1, 2
	word	1, 1, AB_INSIDE_LEFT_ARROW
	word	1, 1, AB_OUTSIDE_LEFT_ARROW

	nptr	offset HVThumb
	word	P_BEGIN_REGION, (P_ARROW_WIDTH+2)-1-2, P_BEGIN_REGION, 1
	word	P_BEGIN_REGION, 1, P_END_REGION-1, 1
	word	P_BEGIN_REGION,(P_ARROW_WIDTH+2)-1-1,P_END_REGION, (P_ARROW_WIDTH+2)-1-1
	word	P_END_REGION, (P_ARROW_WIDTH+2)-1-1, P_END_REGION, 1
	word	P_END_REGION+1, (P_ARROW_WIDTH+2)-1-1, P_END_REGION+1, 2

	word	P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1-1, P_END_REGION, 2   
	word	P_END_REGION+1, 1, P_END_REGION+1, 1		;pixel

	nptr	offset HVPageUpDnAvoidShadow
	word	P_ARROW_HEIGHT+1, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION, 1  ;color
	word	P_ARROW_HEIGHT+2, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION, 1  ;B/W

	nptr	offset HVPageUpDn
	word	P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1, P_END_MINUS_ARROW-1, 1 

	nptr	offset HVDnArrow
	word	P_END_MINUS_ARROW, (P_ARROW_WIDTH+2)-1-1, P_END_REGION-2, (P_ARROW_MID+2)-1
	word	P_END_MINUS_ARROW, (P_ARROW_WIDTH+2)-1, P_END_REGION-2, (P_ARROW_MID+2)
	word	P_END_MINUS_ARROW, (P_ARROW_WIDTH+2)-1-2, P_END_MINUS_ARROW, 1
	word	P_END_MINUS_ARROW, 1, P_END_REGION-2, (P_ARROW_MID+2)-1-1
	word	P_END_MINUS_ARROW+1, 1, AB_INSIDE_RIGHT_ARROW
	word	P_END_MINUS_ARROW-1, 1, AB_OUTSIDE_RIGHT_ARROW



;
; Slider code
;
vertSlider	label	word
	nptr	offset HVThumb
	word	1, P_BEGIN_REGION, (P_ARROW_WIDTH+2)-3, P_BEGIN_REGION
	word	1, P_BEGIN_REGION, 1, P_END_REGION-1
	word	(P_ARROW_WIDTH+2)-2, P_BEGIN_REGION, (P_ARROW_WIDTH+2)-2, P_END_REGION
	word	1, P_END_REGION, (P_ARROW_WIDTH+2)-2, P_END_REGION
	word	2, P_END_REGION+1, (P_ARROW_WIDTH+2)-2, P_END_REGION+1  ;shadow

	word	2, P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-2, P_END_REGION   

	;This is to draw in the single pixel next to the bottom line in B/W
	;if needed in the 50% mask.  This hopefully will do nothing in color.
	word	1, P_END_REGION+1, 1, P_END_REGION+1 ;color or B/W

vsPageUp	label	word
	nptr	offset HVPageUpDn
	word	1, 1, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION  

vsPageDn	label	word
	nptr	offset HVPageUpDn
	word	1, P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1, P_END_REGION-1

	; Horizontal sliders

horizSlider	label	word
	nptr	offset HVThumb
	word	P_BEGIN_REGION, (P_ARROW_WIDTH+2)-1-2, P_BEGIN_REGION, 1
	word	P_BEGIN_REGION, 1, P_END_REGION-1, 1
	word	P_BEGIN_REGION,(P_ARROW_WIDTH+2)-1-1,P_END_REGION, (P_ARROW_WIDTH+2)-1-1
	word	P_END_REGION, (P_ARROW_WIDTH+2)-1-1, P_END_REGION, 1
	word	P_END_REGION+1, (P_ARROW_WIDTH+2)-1-1, P_END_REGION+1, 2

	word	P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1-1, P_END_REGION, 2   
	word	P_END_REGION+1, 1, P_END_REGION+1, 1		;pixel

	nptr	offset HVPageUpDn
	word	1, (P_ARROW_WIDTH+2)-1, P_BEGIN_REGION, 1  

	nptr	offset HVPageUpDn
	word	P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-1, P_END_REGION-1, 1

;
; Gauge drawing commands
;


vertGauge	label	word
	nptr	offset HVPageUpDnLight
	word	3, 1, (P_ARROW_WIDTH+2)-3, P_BEGIN_REGION

	nptr	offset HVPageUpDn
	word	3, P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-3, P_END_REGION-1


horizGauge	label	word
	nptr	offset HVPageUpDn
	word	1, (P_ARROW_WIDTH+2)-3, P_BEGIN_REGION, 3

	nptr	offset HVPageUpDnLight
	word	P_BEGIN_REGION+1, (P_ARROW_WIDTH+2)-3, P_END_REGION-1, 3

horizTextGauge	label	word
	nptr	HTextPageUp		; page-up routine
	word	1, 1, P_BEGIN_REGION, (P_ARROW_WIDTH+2)-1
	nptr	HTextPageDn		; page-down routine
	word	P_BEGIN_REGION+1, 1, P_END_REGION, (P_ARROW_WIDTH+2)-1
	
ScrollbarCommon ends



ScrollbarBitmaps10	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		si	- ArrowBitmap	
		cx, dx  - position to draw bitmap
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillBitmap

		XIP - copy bitmap to stack before calling GrFillBitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version
	chris	11/10/92	Broken out into separate segments
	jwu	4/22/94		XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBBitmap10	proc	far			uses	bp, ds, es
		.enter 
		segmov	ds, cs
		mov	si, ds:scrollbarBitmap10Table[si]
						; pull bitmap address out
		movdw	bxax, dxcx		; draw position in ax, bx
		
FXIP <		mov	cx, ds:[si].B_height				      >
FXIP <		shl	cx, 1						      >
FXIP <		add	cx, size Bitmap		; cx = size of bitmap in bytes>
FXIP <		sub	sp, cx						      >
FXIP <		mov	dx, sp			; ss:dx = space on stack      >

FXIP <		push	cx			; save for restoring stack    >
FXIP <		push	di			; save gstate handle 	      >

FXIP <		shr	cx, 1			; convert to word size	      >
FXIP <		segmov	es, ss, di					      >
FXIP <		mov	di, dx			; es:di = space on stack      >
FXIP <		rep	movsw						      >

FXIP <		segmov	ds, ss, si					      >
FXIP <		mov	si, dx			; ds:si = bitmap on stack     >

FXIP <		pop	di			; di = gstate handle	      >

		clr	cx, dx			; no callback
		call	GrFillBitmap		; and call the graphics system
		
FXIP <		pop	cx			; cx = size of bitmap in words>
FXIP <		add	sp, cx						      >

		.leave
		ret
FillSBBitmap10	endp


scrollbarBitmap10Table	label	word
	word	offset	UpInside10
	word	offset	UpOutside10
	word	offset	DownInside10
	word	offset	DownOutside10
	word	offset	LeftInside10
	word	offset	LeftOutside10
	word	offset	RightInside10
	word	offset	RightOutside10

UpInside10	label	Bitmap
	Bitmap	<10, 10, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte 	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00001100b, 00000000b
	byte	00001100b, 00000000b
	byte	00011110b, 00000000b
	byte	00011110b, 00000000b
	byte	00111111b, 00000000b
	byte	00111111b, 00000000b
	byte	01111111b, 10000000b

UpOutside10	label	Bitmap
	Bitmap <10, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11000000b
	byte 	11110011b, 11000000b
	byte	11110011b, 11000000b
	byte	11100001b, 11000000b
	byte	11100001b, 11000000b
	byte	11000000b, 11000000b
	byte	11000000b, 11000000b
	byte	10000000b, 01000000b
	byte	10000000b, 01000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	11111111b, 11000000b

DownInside10	label	Bitmap
	Bitmap <10, 7 ,BMC_UNCOMPACTED, BMF_MONO>
	byte	01111111b, 10000000b
	byte	00111111b, 00000000b
	byte	00111111b, 00000000b
	byte	00011110b, 00000000b
	byte	00011110b, 00000000b
	byte	00001100b, 00000000b
	byte	00001100b, 00000000b

DownOutside10	label	Bitmap
	Bitmap <10, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	10000000b, 01000000b
	byte	10000000b, 01000000b
	byte	11000000b, 11000000b
	byte	11000000b, 11000000b
	byte	11100001b, 11000000b
	byte	11100001b, 11000000b
	byte	11110011b, 11000000b
	byte 	11110011b, 11000000b
	byte	11111111b, 11000000b

LeftInside10	label	Bitmap	
	Bitmap  <11, 10, BMC_UNCOMPACTED, BMF_MONO>
   	byte	00000000b, 00000000b
	byte	00000000b, 01000000b
	byte	00000001b, 11000000b
	byte	00000111b, 11000000b
	byte	00011111b, 11000000b
	byte	00011111b, 11000000b
	byte	00000111b, 11000000b
	byte	00000001b, 11000000b
	byte	00000000b, 01000000b
	byte	00000000b, 00000000b

LeftOutside10	label	Bitmap
	Bitmap <12, 10, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 10010000b
	byte	11111110b, 00010000b
	byte	11111000b, 00010000b
	byte	11100000b, 00010000b
	byte	10000000b, 00010000b
	byte	10000000b, 00010000b
	byte	11100000b, 00010000b
	byte	11111000b, 00010000b
	byte	11111110b, 00010000b
	byte	11111111b, 10010000b

RightInside10	label	Bitmap
	Bitmap <7, 10, BMC_UNCOMPACTED, BMF_MONO>
   	byte	00000000b
   	byte	10000000b
   	byte	11100000b
   	byte	11111000b
   	byte	11111110b
   	byte	11111110b
   	byte	11111000b
   	byte	11100000b
   	byte	10000000b
   	byte	00000000b

RightOutside10	label	Bitmap
	Bitmap <12, 10, BMC_UNCOMPACTED, BMF_MONO>
	byte	10011111b, 11110000b
	byte	10000111b, 11110000b
	byte	10000001b, 11110000b
	byte	10000000b, 01110000b
	byte	10000000b, 00010000b
	byte	10000000b, 00010000b
	byte	10000000b, 01110000b
	byte	10000001b, 11110000b
	byte	10000111b, 11110000b
	byte	10011111b, 11110000b


ScrollbarBitmaps10	ends

ScrollbarBitmaps12	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		si	- ArrowBitmap	
		cx, dx  - position to draw bitmap
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillBitmap

		XIP - copy bitmap to stack before calling GrFillBitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version
	chris	11/10/92	Broken out into separate segments
	jwu	4/22/94		XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBBitmap12	proc	far			uses	bp, ds, es
		.enter 
		segmov	ds, cs
		mov	si, ds:scrollbarBitmap12Table[si]
						; pull bitmap address out
		movdw	bxax, dxcx		; draw position in ax, bx
		
FXIP <		mov	cx, ds:[si].B_height				      >
FXIP <		shl	cx, 1						      >
FXIP <		add	cx, size Bitmap		; cx = size of bitmap in bytes>
FXIP <		sub	sp, cx						      >
FXIP <		mov	dx, sp			; ss:dx = space on stack      >
		
FXIP <		push	cx			; save for restoring stack    >
FXIP <		push	di			; save gstate handle          >
		
FXIP <		shr	cx, 1			; convert to word size        >
FXIP <		segmov	es, ss, di					      >
FXIP <		mov	di, dx			; es:di = space on stack      >
FXIP <		rep	movsw						      >
	
FXIP <		segmov	ds, ss, si  				              >
FXIP <		mov	si, dx			; ds:si = bitmap on stack     >
		
FXIP <		pop	di			; di = gstate handle          >
		
		clr	cx, dx			; no callback
		call	GrFillBitmap		; and call the graphics system
		
FXIP <		pop	cx			; cx = size of bitmap in words>
FXIP <		add	sp, cx						      >

		.leave
		ret
FillSBBitmap12	endp


scrollbarBitmap12Table	label	word
	word	offset	UpInside12
	word	offset	UpOutside12
	word	offset	DownInside12
	word	offset	DownOutside12
	word	offset	LeftInside12
	word	offset	LeftOutside12
	word	offset	RightInside12
	word	offset	RightOutside12

UpInside12	label	Bitmap
	Bitmap <12, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte 	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000110b, 00000000b
	byte	00000110b, 00000000b
	byte	00001111b, 00000000b
	byte	00001111b, 00000000b
	byte	00011111b, 10000000b
	byte	00011111b, 10000000b
	byte	00111111b, 11000000b
	byte	00111111b, 11000000b
	byte	01111111b, 11100000b

UpOutside12	label	Bitmap
	Bitmap <12, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11110000b
	byte 	11111001b, 11110000b
	byte	11111001b, 11110000b
	byte	11110000b, 11110000b
	byte	11110000b, 11110000b
	byte	11100000b, 01110000b
	byte	11100000b, 01110000b
	byte	11000000b, 00110000b
	byte	11000000b, 00110000b
	byte	10000000b, 00010000b
	byte	10000000b, 00010000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	11111111b, 11110000b

DownInside12	label	Bitmap
	Bitmap <12, 9, BMC_UNCOMPACTED, BMF_MONO>
	byte	01111111b, 11100000b
	byte	00111111b, 11000000b
	byte	00111111b, 11000000b
	byte	00011111b, 10000000b
	byte	00011111b, 10000000b
	byte	00001111b, 00000000b
	byte	00001111b, 00000000b
	byte	00000110b, 00000000b
	byte	00000110b, 00000000b

DownOutside12	label	Bitmap
	Bitmap <12, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11110000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	10000000b, 00010000b
	byte	10000000b, 00010000b
	byte	11000000b, 00110000b
	byte	11000000b, 00110000b
	byte	11100000b, 01110000b
	byte	11100000b, 01110000b
	byte	11110000b, 11110000b
	byte	11110000b, 11110000b
	byte	11111001b, 11110000b
	byte 	11111001b, 11110000b
	byte	11111111b, 11110000b

LeftInside12	label	Bitmap	
	Bitmap  <13, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00010000b
	byte	00000000b, 01110000b
	byte	00000001b, 11110000b
	byte	00000111b, 11110000b
	byte	00011111b, 11110000b
	byte	00011111b, 11110000b
	byte	00000111b, 11110000b
	byte	00000001b, 11110000b
	byte	00000000b, 01110000b
	byte	00000000b, 00010000b
	byte	00000000b, 00000000b

LeftOutside12	label	Bitmap
	Bitmap <14, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11100100b
	byte	11111111b, 10000100b
	byte	11111110b, 00000100b
	byte	11111000b, 00000100b
	byte	11100000b, 00000100b
	byte	10000000b, 00000100b
	byte	10000000b, 00000100b
	byte	11100000b, 00000100b
	byte	11111000b, 00000100b
	byte	11111110b, 00000100b
	byte	11111111b, 10000100b
	byte	11111111b, 11100100b

RightInside12	label	Bitmap
	Bitmap <9, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	10000000b, 00000000b
	byte	11100000b, 00000000b
	byte	11111000b, 00000000b
	byte	11111110b, 00000000b
	byte	11111111b, 10000000b
	byte	11111111b, 10000000b
	byte	11111110b, 00000000b
	byte	11111000b, 00000000b
	byte	11100000b, 00000000b
	byte	10000000b, 00000000b
	byte	00000000b, 00000000b

RightOutside12	label	Bitmap
	Bitmap <14, 12, BMC_UNCOMPACTED, BMF_MONO>
	byte	10011111b, 11111100b
	byte	10000111b, 11111100b
	byte	10000001b, 11111100b
	byte	10000000b, 01111100b
	byte	10000000b, 00011100b
	byte	10000000b, 00000100b
	byte	10000000b, 00000100b
	byte	10000000b, 00011100b
	byte	10000000b, 01111100b
	byte	10000001b, 11111100b
	byte	10000111b, 11111100b
	byte	10011111b, 11111100b


ScrollbarBitmaps12	ends

ScrollbarBitmaps14	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		si	- ArrowBitmap	
		cx, dx  - position to draw bitmap
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillBitmap

		XIP - copy bitmap to stack before calling GrFillBitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version
	chris	11/10/92	Broken out into separate segments
	jwu	4/22/94		XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBBitmap14	proc	far			uses	bp, ds, es
		.enter 
		segmov	ds, cs
		mov	si, ds:scrollbarBitmap14Table[si]
						; pull bitmap address out
		movdw	bxax, dxcx		; draw position in ax, bx
		
FXIP <		mov	cx, ds:[si].B_height				      >
FXIP <		shl	cx, 1						      >
FXIP <		add	cx, size Bitmap  	; cx = size of bitmap in bytes>
FXIP <		sub	sp, cx						      >
FXIP <		mov	dx, sp			; ss:dx = space on stack      >

FXIP <		push	cx			; save for restoring stack    >
FXIP <		push	di			; save gstate handle          >

FXIP <		shr	cx, 1			; convert to word size        >
FXIP <		segmov	es, ss, di 					      >
FXIP <		mov	di, dx			; es:di = space on stack      >
FXIP <		rep	movsw						      >

FXIP <		segmov	ds, ss, si					      >
FXIP <		mov	si, dx			; ds:si = bitmap on stack     >

FXIP <		pop	di			; di = gstate handle          >

		clr	cx, dx			; no callback
		call	GrFillBitmap		; and call the graphics system

FXIP <		pop	cx			; cx = size of bitmap in words>
FXIP <		add	sp, cx						      >

		.leave
		ret
FillSBBitmap14	endp


scrollbarBitmap14Table	label	word
	word	offset	UpInside14
	word	offset	UpOutside14
	word	offset	DownInside14
	word	offset	DownOutside14
	word	offset	LeftInside14
	word	offset	LeftOutside14
	word	offset	RightInside14
	word	offset	RightOutside14

UpInside14	label	Bitmap
	Bitmap <14, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte 	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000011b, 00000000b
	byte	00000011b, 00000000b
	byte	00000111b, 10000000b
	byte	00000111b, 10000000b
	byte	00001111b, 11000000b
	byte	00001111b, 11000000b
	byte	00011111b, 11100000b
	byte	00011111b, 11100000b
	byte	00111111b, 11110000b
	byte	00111111b, 11110000b
	byte	01111111b, 11111000b

UpOutside14	label	Bitmap
	Bitmap <14, 16, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11111100b
	byte	11111100b, 11111100b
	byte	11111100b, 11111100b
	byte 	11111000b, 01111100b
	byte	11111000b, 01111100b
	byte	11110000b, 00111100b
	byte	11110000b, 00111100b
	byte	11100000b, 00011100b
	byte	11100000b, 00011100b
	byte	11000000b, 00001100b
	byte	11000000b, 00001100b
	byte	10000000b, 00000100b
	byte	10000000b, 00000100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	11111111b, 11111100b

DownInside14	label	Bitmap
	Bitmap <14, 11, BMC_UNCOMPACTED, BMF_MONO>
	byte	01111111b, 11111000b
	byte	00111111b, 11110000b
	byte	00111111b, 11110000b
	byte	00011111b, 11100000b
	byte	00011111b, 11100000b
	byte	00001111b, 11000000b
	byte	00001111b, 11000000b
	byte	00000111b, 10000000b
	byte	00000111b, 10000000b
	byte	00000011b, 00000000b
	byte	00000011b, 00000000b

DownOutside14	label	Bitmap
	Bitmap <14, 16, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11111100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	10000000b, 00000100b
	byte	10000000b, 00000100b
	byte	11000000b, 00001100b
	byte	11000000b, 00001100b
	byte	11100000b, 00011100b
	byte	11100000b, 00011100b
	byte	11110000b, 00111100b
	byte	11110000b, 00111100b
	byte	11111000b, 01111100b
	byte 	11111000b, 01111100b
	byte 	11111100b, 11111100b
	byte 	11111100b, 11111100b
	byte	11111111b, 11111100b

LeftInside14	label	Bitmap	
	Bitmap  <15, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000100b
	byte	00000000b, 00011100b
	byte	00000000b, 01111100b
	byte	00000001b, 11111100b
	byte	00000111b, 11111100b
	byte	00011111b, 11111100b
	byte	00011111b, 11111100b
	byte	00000111b, 11111100b
	byte	00000001b, 11111100b
	byte	00000000b, 01111100b
	byte	00000000b, 00011100b
	byte	00000000b, 00000100b
	byte	00000000b, 00000000b

LeftOutside14	label	Bitmap
	Bitmap <16, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b, 11111001b
	byte	11111111b, 11100001b
	byte	11111111b, 10000001b
	byte	11111110b, 00000001b
	byte	11111000b, 00000001b
	byte	11100000b, 00000001b
	byte	10000000b, 00000001b
	byte	10000000b, 00000001b
	byte	11100000b, 00000001b
	byte	11111000b, 00000001b
	byte	11111110b, 00000001b
	byte	11111111b, 10000001b
	byte	11111111b, 11100001b
	byte	11111111b, 11111001b

RightInside14	label	Bitmap
	Bitmap <11, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b, 00000000b
	byte	10000000b, 00000000b
	byte	11100000b, 00000000b
	byte	11111000b, 00000000b
	byte	11111110b, 00000000b
	byte	11111111b, 10000000b
	byte	11111111b, 11100000b
	byte	11111111b, 11100000b
	byte	11111111b, 10000000b
	byte	11111110b, 00000000b
	byte	11111000b, 00000000b
	byte	11100000b, 00000000b
	byte	10000000b, 00000000b
	byte	00000000b, 00000000b

RightOutside14	label	Bitmap
	Bitmap <16, 14, BMC_UNCOMPACTED, BMF_MONO>
	byte	10011111b, 11111111b
	byte	10000111b, 11111111b
	byte	10000001b, 11111111b
	byte	10000000b, 01111111b
	byte	10000000b, 00011111b
	byte	10000000b, 00000111b
	byte	10000000b, 00000001b
	byte	10000000b, 00000001b
	byte	10000000b, 00000111b
	byte	10000000b, 00011111b
	byte	10000000b, 01111111b
	byte	10000001b, 11111111b
	byte	10000111b, 11111111b
	byte	10011111b, 11111111b


ScrollbarBitmaps14	ends

ScrollbarBitmaps8	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		si	- ArrowBitmap	
		cx, dx  - position to draw bitmap
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		add the draw position and call GrFillBitmap

		XIP - copy bitmap to stack before calling GrFillBitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version
	chris	11/10/92	Broken out into separate segments
	jwu	4/22/94		XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSBBitmap8	proc	far			uses	bp, ds, es
		.enter 
		segmov	ds, cs
		mov	si, ds:scrollbarBitmap8Table[si]
						; pull bitmap address out
		movdw	bxax, dxcx		; draw position in ax, bx
		
FXIP <		mov	cx, ds:[si].B_height				      >
FXIP <		shl	cx, 1						      >
FXIP <		add	cx, size Bitmap 	; cx = size of bitmap in bytes>
FXIP <		sub	sp, cx						      >
FXIP <		mov	dx, sp			; ss:dx = space on stack      >
		
FXIP <		push	cx			; save for restoring stack    >
FXIP <		push	di			; save gstate handle          >

FXIP <		shr	cx, 1			; convert to word size	      >
FXIP <		segmov	es, ss, di					      >
FXIP <		mov	di, dx			; es:di = space on stack      >
FXIP <		rep	movsw						      >

FXIP <		segmov	ds, ss, si					      >
FXIP <		mov	si, dx			; ds:si = bitmap on stack     >
		
FXIP <		pop	di			; di = gstate handle          >

		clr	cx, dx			; no callback
		call	GrFillBitmap		; and call the graphics system
		
FXIP <		pop	cx			; cx = size of bitmap in words>
FXIP <		add	sp, cx						      >

		.leave
		ret
FillSBBitmap8	endp


scrollbarBitmap8Table	label	word
	word	offset	UpInside8
	word	offset	UpOutside8
	word	offset	DownInside8
	word	offset	DownOutside8
	word	offset	LeftInside8
	word	offset	LeftOutside8
	word	offset	RightInside8
	word	offset	RightOutside8

UpInside8	label	Bitmap
	Bitmap	<8, 8, BMC_UNCOMPACTED, BMF_MONO>
	byte	00000000b
	byte 	00000000b
	byte	00000000b
	byte	00011000b
	byte	00011000b
	byte	00111100b
	byte	00111100b
	byte	01111110b

UpOutside8	label	Bitmap
	Bitmap <8, 10, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b
	byte	11100111b
	byte	11100111b
	byte	11000011b
	byte	11000011b
	byte	10000001b
	byte	10000001b
	byte	00000000b
	byte	00000000b
	byte	11111111b

DownInside8	label	Bitmap
	Bitmap <8, 5 ,BMC_UNCOMPACTED, BMF_MONO>
	byte	01111110b
	byte	00111100b
	byte	00111100b
	byte	00011000b
	byte	00011000b

DownOutside8	label	Bitmap
	Bitmap <8, 10, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111111b
	byte	00000000b
	byte	00000000b
	byte	10000001b
	byte	10000001b
	byte	11000011b
	byte	11000011b
	byte	11100111b
	byte	11100111b
	byte	11111111b

LeftInside8	label	Bitmap	
	Bitmap  <8, 8, BMC_UNCOMPACTED, BMF_MONO>
   	byte	00000000b
	byte	00000001b
	byte	00000111b
	byte	00011111b
	byte	00011111b
	byte	00000111b
	byte	00000001b
	byte	00000000b

LeftOutside8	label	Bitmap
	Bitmap <10, 8, BMC_UNCOMPACTED, BMF_MONO>
	byte	11111110b, 01000000b
	byte	11111000b, 01000000b
	byte	11100000b, 01000000b
	byte	10000000b, 01000000b
	byte	10000000b, 01000000b
	byte	11100000b, 01000000b
	byte	11111000b, 01000000b
	byte	11111110b, 01000000b

RightInside8	label	Bitmap
	Bitmap <5, 8, BMC_UNCOMPACTED, BMF_MONO>
   	byte	00000000b
   	byte	10000000b
   	byte	11100000b
   	byte	11111000b
   	byte	11111000b
   	byte	11100000b
   	byte	10000000b
   	byte	00000000b

RightOutside8	label	Bitmap
	Bitmap <10, 8, BMC_UNCOMPACTED, BMF_MONO>
	byte	10011111b, 11000000b
	byte	10000111b, 11000000b
	byte	10000001b, 11000000b
	byte	10000000b, 01000000b
	byte	10000000b, 01000000b
	byte	10000001b, 11000000b
	byte	10000111b, 11000000b
	byte	10011111b, 11000000b
	
ScrollbarBitmaps8	ends

ScrollbarCommon segment resource


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
	uses	ax, bx, cx, dx, di

	.enter	inherit	DrawScrollbar

	; save away the draw position and parameter, and call the routine

	mov	ss:posX, ax
	mov	ss:posY, bx
	
	mov	ax, ss:arrowSize		;width
	mov	bx, ax				
	inc	bx				;height
	mov	ss:param0, ax
	mov	ss:param1, bx
	mov	ss:param2, cx
	mov	ss:param3, dx
	shr	ax, 1
	mov	ss:param4, ax

	mov	ss:param5, dx
	sub	ss:param5, bx

	mov	di, ss:gstate
	lodsw
	call	ax

	.leave
	ret
DrawSBPart		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVUpArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the up arrow

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

HVUpArrow	proc	near

		call	SetLTColor		; set color for left/top
		call	DrawSBLine

		call	SetRBColor		; set color for bottom edge
		call	DrawSBLine		; draw bottom edge
		call	DrawSBLineShadow
		call	DrawSBLine	
		call	DrawSBLineIfNotTwisted	; shadow only appears sometimes

		call	SetFillColor		; set fill color
		call	FillSBBitmap

		call	OpenCheckIfBW		; not necessary in B/W (only
		jc	10$			;  here to deal with weird
						;  background colors)
		push	si
		call	SetRevDarkColor		; repeat, with light color
		call	FillSBBitmap
		pop	si
10$:
		call	SetDarkColor		; 50% dark color for outside
		call	FillSBBitmap
		ret		
HVUpArrow	endp





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
	call	DrawSBLineShadow

	call	SetFillColor			;set fill color
	call	FillSBRect

	call	OpenCheckIfBW
	jnc	color
	call	SetFillColor			;fill that extra pixel (sigh)
	GOTO	HVPageUpDn
color:
	add	si, offset endHackPixel - offset startHackPixel
	ret

HVThumb	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVPageUpDn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw "page up" part of scrollbar

CALLED BY:	INTERNAL
		indirectly, via DrawPageUpArea
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
	push	si
	call	SetDarkColor		;dark dots
	call	FillSBRect	
	pop	si
	call	SetRevDarkColor		;light dots
	call	FillSBRect	
	ret
HVPageUpDn	endp

HVPageUpDnAvoidShadow	proc	near
	push	si
	call	SetDarkColor		;dark dots
	call	FillSBRectCustomBW
	pop	si
	call	SetRevDarkColor		;light dots
	call	FillSBRectCustomBW
	ret
HVPageUpDnAvoidShadow	endp

HVPageUpDnLight	proc	near	;really drawing nothing, for gauges
	.enter inherit	DrawScrollbar
	mov	selected?, 1			;Added 3/1/94 - atw, to use
						; light color
	call	SetFillColor
	call	FillSBRect
	.leave
	ret
HVPageUpDnLight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTextPageUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTextPageUp	proc	near
		.enter	inherit	DrawScrollbar
		call	SetDarkColor
		call	GetSBRect
		push	si, ds
		mov	si, PCT_REPLACE
		call	GrSetClipRect
		call	GrFillRect
		mov	ax, C_WHITE
		call	GrSetTextColor
		mov	ax, valueTextPos
		add	ax, posX
					; (y coord is same as rect)
		clr	cx
		segmov	ds, ss
		lea	si, ss:[valueText]
		call	GrDrawText
		pop	si, ds
		.leave
		ret
HTextPageUp 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTextPageDn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTextPageDn	proc	near
		.enter	inherit	DrawScrollbar
		call	SetFillColor
		call	GetSBRect
		push	si, ds
		mov	si, PCT_REPLACE
		call	GrSetClipRect
		call	GrFillRect
		mov	ax, darkColor
		call	GrSetTextColor
		mov	ax, valueTextPos
		add	ax, posX
					; (y coord is same as rect)
		clr	cx
		segmov	ds, ss
		lea	si, ss:[valueText]
		call	GrDrawText
		mov	si, PCT_NULL
		call	GrSetClipRect
		pop	si, ds
		.leave
		ret
HTextPageDn 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HVDnArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the "down arrow" part of the scrollbar

CALLED BY:	INTERNAL
		
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HVDnArrow	proc	near

	call	SetRBColor			
	call	DrawSBLine
	call	DrawSBLineShadow

	call	SetLTColor		;left/top color
	call	DrawSBLine
	call	DrawSBLine

	call	SetFillColor
	call	FillSBBitmap

	call	OpenCheckIfBW		; not necessary in B/W (only
	jc	10$			;  here to deal with weird
						;  background colors)
	push	si
	call	SetRevDarkColor		; repeat, with light color
	call	FillSBBitmap
	pop	si
10$:
	call	SetDarkColor		; 50% dark color for outside
	call	FillSBBitmap
	ret
HVDnArrow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSBLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		ax,bx,cx,dx	- increments to left/top position
		inherit	DrawScrollbars draw position and parameters
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
DrawSBLineIfNotTwisted	proc	near
		.enter inherit	DrawScrollbar
		
		test	attrs, mask OLSA_TWISTED
		jz	DrawSBLineShadow	; not twisted, draw if shadow
		add	si, 8		; throw away command when twisted
		.leave
		ret
DrawSBLineIfNotTwisted	endp


DrawSBLineShadow	proc	near
	
		call	OpenCheckIfBW
		jc	DrawSBLine
		add	si, 8		; throw away command in color
		ret
DrawSBLineShadow	endp


DrawSBLine	proc	near

		; add the draw position to all the coordinates
		call	GetSBRect
		call	GrDrawLine	; and call the graphics system

		ret
DrawSBLine	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSBBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by scrollbar drawing code

CALLED BY:	INTERNAL
PASS:		ds:si	- offset to bitmap to draw
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
FillSBBitmap	proc	far
		.enter inherit	DrawScrollbar

		; add the draw position to all the coordinates

		lodsw				; get x value
		mov	bx, ax
		lodsw
		call	ApplySBParam
		xchg	ax, bx
		call	ApplySBParam
		movdw	cxdx, axbx
		add	cx, ss:posX		; setup coords
		add	dx, ss:posY
		push	si
		mov	si, ds:[si]		; get ptr to bitmap

		cmp	ss:arrowSize, 14
		jne	check12
		CallMod	FillSBBitmap14
		jmp	short exit
check12:
		cmp	ss:arrowSize, 12
		jne	check10
		CallMod	FillSBBitmap12
		jmp	short exit
check10:
		cmp	ss:arrowSize, 10
		jne	check8
		CallMod	FillSBBitmap10
		jmp	short exit
check8:
		CallMod	FillSBBitmap8
exit:
		pop	si			; restore table pointer
		add	si, 2			; bump past bitmap ptr
		.leave
		ret
FillSBBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSBRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a rectangle from a drawing data definition, applying
		the appropriate parameters to the coordinates

CALLED BY:	(INTERNAL) FillSBRect
PASS:		ds:si	= first of the four coordinates
RETURN:		ax	= left
		bx	= top
		cx	= right
		dx	= bottom
		ds:si	= past the rectangle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSBRect	proc	near
		.enter
		lodsw			; get ax
		mov	dx, ax		; save for later
		lodsw
		mov	bx, ax
		lodsw
		mov	cx, ax
		lodsw
		xchg	dx, ax
		call	ApplySBParams	; apply parameters, if needed
		.leave
		ret
GetSBRect 	endp

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

		call	GetSBRect
		call	GrFillRect	; and call the graphics system

		ret
FillSBRect	endp

FillSBRectCustomBW	proc	near
		call	OpenCheckIfBW
		jnc	10$
		add	si, 8		; avoid first set of args for B/W
10$:

		; add the draw position to all the coordinates

		call	GetSBRect
		call	GrFillRect	; and call the graphics system

		call	OpenCheckIfBW
		jc	20$
		add	si, 8		; avoid second set of args for color
20$:
		ret
FillSBRectCustomBW	endp


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
		.enter inherit	DrawScrollbar
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
		.enter inherit	DrawScrollbar
		ForceRef posX, posY

		cmp	ax, P_ARROW_WIDTH - 100	; do bounds check
		jb	done
		cmp	ax, P_END_MINUS_ARROW + 100	; check high end
		jb	applySomething
done:
		.leave
		ret

		; we need to apply a parameter
applySomething:
		cmp	ax, P_ARROW_WIDTH + 100
		jae	applyP1
		sub	ax, P_ARROW_WIDTH
		add	ax, ss:param0
		ret
applyP1:
		cmp	ax, P_ARROW_HEIGHT + 100
		jae	applyP2
		sub	ax, P_ARROW_HEIGHT
		add	ax, ss:param1
		ret
applyP2:
		cmp	ax, P_BEGIN_REGION + 100
		jae	applyP3
		sub	ax, P_BEGIN_REGION
		add	ax, ss:param2
		ret
applyP3:
		cmp	ax, P_END_REGION + 100
		jae	applyP4
		sub	ax, P_END_REGION
		add	ax, ss:param3
		ret
applyP4:
		cmp	ax, P_ARROW_MID + 100
		jae	applyP5
		sub	ax, P_ARROW_MID
		add	ax, ss:param4
		ret
applyP5:
		sub	ax, P_END_MINUS_ARROW
		add	ax, ss:param5
		ret
ApplySBParam	endp

ScrollbarCommon ends
