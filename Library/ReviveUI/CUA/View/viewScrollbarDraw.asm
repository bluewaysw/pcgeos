COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

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

	$Id: viewScrollbarDraw.asm,v 1.1 97/04/07 10:56:49 newdeal Exp $

-------------------------------------------------------------------------------@


;------------------------------------------------------------------------------
;	Scrollbar draw strings
;------------------------------------------------------------------------------
;
; The 1.x code drew the scrollbar with static graphics strings played with
; GrPlayString, which took the draw position in ax, bx and two parameters
; in cx, dx (PARAM_2, PARAM_3: top of the thumb and the scrollbar length),
; and returned si pointing past the string.  GrPlayString and string
; parameters went away in 2.0; Motif converted its strings to tables of
; draw routines then (see "These routines were originally static graphics
; strings, and were converted when GrPlayString went away" in the 2.x
; Motif/View/viewScrollbarDraw.asm, jim 4/23/92).
;
; Here the strings are kept as data in the same layout, written with the
; SB* macros below instead of the GS* macros, and drawn by PlaySBString,
; which has GrPlayString's old register interface.  So the drawing code
; and its "add si, offset eX - offset sX" skips are unchanged.  Coordinates
; are relative to the draw position; PARAM_2 + n and PARAM_3 + n (still
; defined in graphics.def) stand for cx + n and dx + n.
;
SBStringOp	etype	word, 0, 2
	SBO_END		enum	SBStringOp	; end of a string
	SBO_FILL_RECT	enum	SBStringOp	; x1, y1, x2, y2 (inclusive)
	SBO_DRAW_RECT	enum	SBStringOp	; x1, y1, x2, y2
	SBO_FILL_BITMAP	enum	SBStringOp	; x, y, size, Bitmap (mono)
	SBO_AREA_MASK	enum	SBStringOp	; SystemDrawMask
	SBO_AREA_COLOR	enum	SBStringOp	; color index
	SBO_LINE_COLOR	enum	SBStringOp	; color index

SBBeginString	macro
endm

SBEndString	macro
	word	SBO_END
endm

SBFillRect	macro	x1, y1, x2, y2
	word	SBO_FILL_RECT, x1, y1, x2, y2
endm

SBDrawRect	macro	x1, y1, x2, y2
	word	SBO_DRAW_RECT, x1, y1, x2, y2
endm

SBFillBitmap	macro	x, y, bsize
	word	SBO_FILL_BITMAP, x, y, bsize
endm

SBSetAreaMask	macro	dmask
	word	SBO_AREA_MASK, dmask
endm

SBSetAreaColorIndex	macro	color
	word	SBO_AREA_COLOR, color
endm

SBSetLineColorIndex	macro	color
	word	SBO_LINE_COLOR, color
endm


DrawBW segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWScrollbar, UpdateBWScrollbar

DESCRIPTION:	Draw an OL Scrollbar on a black and white display.  Updates
		does the same thing as draw but passes a couple of slightly
		different arguments to OpenTrace.
		(Update is used to draw only the cables.)

CALLED BY:	OLScrollbarDraw

PASS:
	*ds:si - scrollbar 
	ch - 0 if drawing, -1 if updating (2.x: the whole scrollbar is
	     drawn either way; UpdateScroll is no longer called)
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
	;
	; 2.x: OLScrollbarDraw passes the chunk in *ds:si (the 1.x code
	; expected the instance data at the chunk start).  Find out first
	; whether the document can be scrolled at all, which was the 1.x
	; OLSBI_winLen < OLSBI_docRange test.
	;
	call	CheckIfDocScrollable		;carry set if scrollable
	pushf
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset		;ds:bp = SpecInstance
	segmov	es, ds, ax			;es:bp = SpecInstance
	segmov	ds, cs, ax			;ds = draw strings
	popf
	pushf					;keep flag for testScrollable
	call	SetupDrawParams			;sets up parameters
	call	DrawUpArrow			;draw the up arrow
	
	test	es:[bp].OLSBI_attrs, mask OLSA_TWISTED			       
	jz	testScrollable			;not a twisty scrollbar, branch
	popf					;(flag not needed)
	add	ax, MO_SCROLLBAR_WIDTH-1	;else put down arrow to the    
						;   right of the up arrow.
	jmp	continue
	
testScrollable:							     
	popf					;carry set if scrollable doc
	jc	continue			;scrollable doc, branch
	add	si, offset ePageDn - offset sThumb
	jmp	downArrow			;else skip to down arrow
	
continue:
	call	DrawThumb			;draw the thumb
	;
	; Now draw page up area.
	;
	cmp	es:[bp].OLSBI_elevOffset, 1	     ;see if near the top
						     ;  (or no thumb at all)
	jg	25$				     ;no, draw page up stuff
	add	si, offset ePageUp - offset sPageUp  ;else skip data
	jmp	short pageDown

25$:
	jz	pageDown			;yes, skip
	call	DrawPageUpArea			;else draw the page up area
pageDown:
	;
	; Now draw page down area.
	;
	push	ax
	mov	ax, es:[bp].OLSBI_scrArea	;get current scroll area
	sub	ax, MO_THUMB_HEIGHT		;subtract height of thumb
	sub	ax, es:[bp].OLSBI_elevOffset	;see if near bottom already
	cmp	ax, 1				;(don't draw if 0 or 1 away)
	pop	ax				;
	jg	45$				;not near (and not negative), 
						;  draw page down stuff
	add	si, offset ePageDn - offset sPageDn
	jmp	short downArrow

45$:
	call	DrawPageDownArea		;draw the page down area
	
downArrow:
	;
	; Now, draw the down arrow.
	;
	call	DrawDownArrow			;draw the down arrow	
	mov	ax, SDM_100			;reset to 100% pattern
	call	GrSetLineMask
	call	GrSetAreaMask

	segmov	ds, es
	ret
DrawBWScrollbar	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDrawParams

SYNOPSIS:	Sets up initial parameters for drawing the scrollbar.

CALLED BY:	DrawBWScrollbar

PASS:		es:bp  -- scrollbar SpecInstance
		ds     -- segment of the draw strings (cs)
		di     -- gstate
		carry  -- set if the document can be scrolled

RETURN:		ds:si  -- pointing at start of draw string
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		cx     -- top of thumb (PARAM_2)
		dx     -- "length" of scrollbar, the long way (PARAM_3)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/90		Initial version

------------------------------------------------------------------------------@

SetupDrawParams	proc	near
	class	OLScrollbarClass
	pushf					;carry set if scrollable doc
	mov	cx, es:[bp].OLSBI_elevOffset	;pass elev offset in cx
	add	cx, MO_SCR_AREA_MARGIN		;add arrow height
	
	or	es:[bp].OLSBI_attrs, mask OLSA_DRAWN_ENABLED
	test	es:[bp].OLSBI_attrs, mask OLSA_ENABLED
	jnz	10$				;enabled, branch
	and	es:[bp].OLSBI_attrs, not mask OLSA_DRAWN_ENABLED
	mov	ax, SDM_50			;else draw 50% pattern
	call	GrSetLineMask
	call	GrSetAreaMask
10$:
	;
	; The next bunch of code figures out if the scrollbar is scrollable,
	; and sets things up so the middle is whited out if it is.  If the
	; scrollbar has no thumb, we won't bother.
	;
	popf					;carry set if scrollable doc
	jc	20$				;scrollable, branch
	cmp	es:[bp].OLSBI_elevOffset, NO_THUMB_ELEV_OFFSET
	stc					;assume no thumb, will not white
	je	20$				;no thumb, branch
	clc					;else white out the middle
20$:
	pushf					;will jc if not whiting out
	
	test	es:[bp].OLSBI_attrs, mask OLSA_VERTICAL	or mask OLSA_TWISTED
	jz	horiz				;nope, branch

	mov	si, offset vertScrStr		;assume we use scrollable data 
	popf
	jc	30$
	mov	si, offset whiteOutVertStr	;else white out center first
30$:
	;
	; First load ax, bx, dx with left, top and height.  The bounds
	; are exclusive at the bottom and right since 2.0; dx is the
	; offset of the last pixel, as in 1.x.
	;
	mov	ax, es:[bp].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[bp].VI_bounds.R_top	;pass top in bx
	mov	dx, es:[bp].VI_bounds.R_bottom	;pass height in dx
	sub	dx, bx
	dec	dx
	ret

horiz:
	mov	si, offset horizScrStr		;assume we use scrollable data 
	popf
	jc	40$
	mov	si, offset whiteOutHorizStr	;else white out center first
40$:
	mov	ax, es:[bp].VI_bounds.R_left	;pass left in ax
	mov	bx, es:[bp].VI_bounds.R_top	;pass top in bx
	mov	dx, es:[bp].VI_bounds.R_right	;pass width in dx
	sub	dx, ax				;
	dec	dx
	ret
SetupDrawParams	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawUpArrow

SYNOPSIS:	Draws the scrollbar's up arrow.

CALLED BY:	DrawBWScrollbar

PASS:		es:bp -- scrollbar SpecInstance
		ds:si  -- pointing to up-arrow gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way
		di     -- gstate

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
	class	OLScrollbarClass
	push	ax
	mov	al, C_WHITE
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_INC_UP			;see if incrementing up
	jne	10$
	mov	al, C_BLACK			;black background if so
10$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString
	
	push	ax
	mov	al, C_BLACK
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_INC_UP			;see if incrementing up
	jne	20$
	mov	al, C_WHITE			;white bitmap if so
20$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString
	ret
DrawUpArrow	endp

		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawThumb

SYNOPSIS:	Draws the scrollbar's thumb.

CALLED BY:	DrawBWScrollbar

PASS:		es:bp -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way
		di     -- gstate

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
	class	OLScrollbarClass
	;
	; Draw the thumb
	;
	tst	es:[bp].OLSBI_elevOffset	;if negative, no thumb
	jns	10$				;using thumb, draw it
	add	si, offset eThumb - offset sThumb
	jmp	short 20$			;else skip it
10$:
	call	PlaySBString
20$:
	ret
DrawThumb	endp
		
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawPageUpArea

SYNOPSIS:	Draws the scrollbar's page up area.

CALLED BY:	DrawBWScrollbar

PASS:		es:bp -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way
		di     -- gstate

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
	class	OLScrollbarClass
	push	ax
	mov	al, C_WHITE			;assume not selected
	mov	ah, es:[bp].OLSBI_state		;get current state

	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_PAGE_UP		;see if paging up
	jne	30$
	mov	al, C_BLACK			;blacken 25% if so
30$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString

	push	ax
	mov	al, C_BLACK			;assume not selected
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_PAGE_UP		;see if paging up
	jne	40$
	mov	al, C_WHITE			;blacken 75% if so
40$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString
	ret
DrawPageUpArea	endp
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawPageDownArea

SYNOPSIS:	Draws the scrollbar's page down area.

CALLED BY:	DrawBWScrollbar

PASS:		es:bp -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way
		di     -- gstate

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
	class	OLScrollbarClass
	push	ax
	mov	al, C_WHITE			;assume not selected
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_PAGE_DOWN		;see if paging down
	jne	50$
	mov	al, C_BLACK			;blacken 25% if so
50$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString

	push	ax
	mov	al, C_BLACK			;assume not selected
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_PAGE_DOWN		;see if paging down
	jne	60$
	mov	al, C_WHITE			;blacken 75% if so
60$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString
	ret
DrawPageDownArea	endp
		

COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawDownArrow

SYNOPSIS:	Draws the scrollbar's down arrow. 

CALLED BY:	DrawBWScrollbar

PASS:		es:bp -- scrollbar SpecInstance
		ds:si  -- pointing to thumb gstring
		ax     -- left edge of scrollbar
		bx     -- top of scrollbar
		dx     -- "length" of scrollbar, the long way
		di     -- gstate

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
	class	OLScrollbarClass
	test	es:[bp].OLSBI_attrs, mask OLSA_ENABLED
	jz	60$				;not enabled, branch
	push	ax
	mov	al, SDM_100			;else set back to 100% pattern
	call	GrSetAreaMask		    
	pop	ax
60$:
	push	ax
	mov	al, C_WHITE
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_INC_DOWN		;see if incrementing up
	jne	70$
	mov	al, C_BLACK			;black background if so
70$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString

	push	ax
	mov	al, C_BLACK
	mov	ah, es:[bp].OLSBI_state		;get current state
	and	ah, mask OLSS_DOWN_FLAGS
	cmp	ah, OLSS_INC_DOWN		;see if incrementing up
	jne	80$
	mov	al, C_WHITE			;white bitmap if so
80$:
	clr	ah
	call	GrSetAreaColor
	pop	ax
	call	PlaySBString
	ret
DrawDownArrow	endp
		
		
COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfDocScrollable

SYNOPSIS:	Sees if the document can be scrolled at all (1.x: the window
		was shorter than the document, OLSBI_winLen < OLSBI_docRange).

CALLED BY:	DrawBWScrollbar

PASS:		*ds:si -- scrollbar

RETURN:		carry set if scrollable
		ds -- updated if the block moved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		(maximum - minimum) - range length > 0, as the 2.x Rudy
		code in SetTopBottomFlags checks it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (revived CUA)

------------------------------------------------------------------------------@

CheckIfDocScrollable	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	ax, MSG_GEN_VALUE_GET_MINIMUM
	call	ObjCallInstanceNoLock		;dx.cx = minimum
	pushdw	dxcx
	mov	ax, MSG_GEN_VALUE_GET_MAXIMUM
	call	ObjCallInstanceNoLock		;dx.cx = maximum
	popdw	bxax				;bx.ax = minimum
	subwwf	dxcx, bxax			;dx.cx = maximum - minimum
	pushdw	dxcx
	mov	ax, MSG_GEN_VALUE_GET_RANGE_LENGTH
	call	ObjCallInstanceNoLock		;dx.cx = range length
	popdw	bxax				;bx.ax = maximum - minimum
	subwwf	bxax, dxcx			;bx.ax = what can be scrolled
	tst	bx
	js	notScrollable			;negative, not scrollable
	jnz	scrollable
	tst	ax
	jz	notScrollable			;zero, not scrollable
scrollable:
	stc
	jmp	short done
notScrollable:
	clc
done:
	.leave
	ret
CheckIfDocScrollable	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	PlaySBString

SYNOPSIS:	Draws one scrollbar draw string (see SBStringOp); takes
		the place of the 1.x GrPlayString.

CALLED BY:	DrawUpArrow, DrawThumb, DrawPageUpArea, DrawPageDownArea,
		DrawDownArrow

PASS:		ds:si  -- draw string
		ax, bx -- draw position
		cx     -- PARAM_2 (top of the thumb)
		dx     -- PARAM_3 (length of the scrollbar, last pixel)
		di     -- gstate

RETURN:		si     -- pointing past the string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The coordinates are the 1.x ones: GrFillRect fills the
		right and bottom edge too, as in 1.x (it doesn't since
		2.0), GrDrawRect is unchanged.  Mono bitmaps are drawn in
		the area color, with GrFillBitmap.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (revived CUA)

------------------------------------------------------------------------------@

PlaySBString	proc	near	uses	ax, bx, cx, dx, bp
originX	local	word
originY	local	word
param2	local	word
param3	local	word
	.enter
	mov	originX, ax
	mov	originY, bx
	mov	param2, cx
	mov	param3, dx
nextOp:
	lodsw					;ax <- SBStringOp
	cmp	ax, SBO_END
	je	done
	cmp	ax, SBO_FILL_RECT
	je	fillRect
	cmp	ax, SBO_DRAW_RECT
	je	drawRect
	cmp	ax, SBO_FILL_BITMAP
	je	fillBitmap
	cmp	ax, SBO_AREA_MASK
	je	areaMask
	cmp	ax, SBO_AREA_COLOR
	je	areaColor
EC <	cmp	ax, SBO_LINE_COLOR					>
EC <	ERROR_NE OL_ERROR			;bad draw string	>
	lodsw					;al <- color index
	mov	ah, CF_INDEX
	call	GrSetLineColor
	jmp	nextOp

areaColor:
	lodsw					;al <- color index
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	jmp	nextOp

areaMask:
	lodsw					;al <- SystemDrawMask
	call	GrSetAreaMask
	jmp	nextOp

fillRect:
	call	GetSBPoint			;ax, bx <- first corner
	push	ax, bx
	call	GetSBPoint			;ax, bx <- opposite corner
	mov	cx, ax
	mov	dx, bx
	pop	ax, bx
	inc	cx				;fill right and bottom edge
	inc	dx				;  too, as 1.x did
	call	GrFillRect
	jmp	nextOp

drawRect:
	call	GetSBPoint			;ax, bx <- first corner
	push	ax, bx
	call	GetSBPoint			;ax, bx <- opposite corner
	mov	cx, ax
	mov	dx, bx
	pop	ax, bx
	call	GrDrawRect
	jmp	nextOp

fillBitmap:
	call	GetSBPoint			;ax, bx <- position
	mov	dx, ds:[si]			;dx <- size of the bitmap
	inc	si
	inc	si
	push	si, dx
	clr	cx, dx				;no callback
	call	GrFillBitmap			;ds:si = Bitmap
	pop	si, dx
	add	si, dx				;skip the bitmap
	jmp	nextOp

done:
	.leave
	ret
PlaySBString	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSBPoint

SYNOPSIS:	Reads a coordinate pair of a draw string, applies the
		parameters and the draw position.

CALLED BY:	PlaySBString

PASS:		ds:si -- x, y
		inherits PlaySBString's frame

RETURN:		ax, bx -- coordinates
		si     -- pointing past them

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (revived CUA)

------------------------------------------------------------------------------@

GetSBPoint	proc	near
	.enter	inherit	PlaySBString
	lodsw					;x
	call	ApplySBParam
	add	ax, originX
	mov	bx, ax
	lodsw					;y
	call	ApplySBParam
	add	ax, originY
	xchg	ax, bx				;ax = x, bx = y
	.leave
	ret
GetSBPoint	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	ApplySBParam

SYNOPSIS:	Applies what used to be a graphics string parameter.

CALLED BY:	GetSBPoint

PASS:		ax -- coordinate: PARAM_2 + n, PARAM_3 + n, or a plain
		      coordinate (-4000h..3fffh)
		inherits PlaySBString's frame

RETURN:		ax -- coordinate relative to the draw position

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (revived CUA)

------------------------------------------------------------------------------@

ApplySBParam	proc	near
	.enter	inherit	PlaySBString
	cmp	ax, PARAM_2 - 1000h		;below PARAM_2 range?
	jae	notPositive
EC <	cmp	ax, PARAM_0 - 1000h		;PARAM_0/1 not supported >
EC <	ERROR_AE OL_ERROR						>
	jmp	short done			;plain positive coordinate

notPositive:
	cmp	ax, PARAM_3 + 1000h		;above PARAM_3 range?
	jae	done				;plain negative coordinate
	cmp	ax, PARAM_3 - 1000h
	jae	isParam3
	sub	ax, PARAM_2			;PARAM_2 + n
	add	ax, param2
	jmp	short done

isParam3:
	sub	ax, PARAM_3			;PARAM_3 + n
	add	ax, param3
done:
	.leave
	ret
ApplySBParam	endp


DrawBW ends

ScrollbarCommon	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimally updates the scrollbar, blitting and sparingly
		redrawing.

CALLED BY:	DoScrollAppearance

PASS:		*ds:si -- handle of scrollbar
		di -- graphics state
		al -- color scheme

RETURN:		carry set if blit happened

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


if (0)
       ;
       ; First, blit the elevator.  Actually, we'll just draw a new vator.
       ;
       Draw a thumb at newElevOffset
       ;
       ; Then, grey out the portion that is being vacated by the thumb
       ;
       if newElevOffset > oldElevOffset
            ;
	    ; Moving down. Grey out the scrollbar between
	    ; oldElevStart and newElevStart.
	    ;
       else
       	    ;
       	    ; Moving up. Grey out the scrollbar between
	    ; newElevStart+MO_THUMB_HEIGHT and oldElevStart+MO_THUMB_HEIGHT
	    ;
       endif
endif

US_Local	struc
	US_newElevStart	sword			;new top of thumb
	US_oldElevStart	sword			;old top of thumb
	US_left		sword			;left edge
	US_top		sword			;top
	US_bottom	sword			;bottom
	US_attrs	OLScrollbarAttrs	;save state here
US_Local	ends

US_local	equ	<[bp - (size US_Local)]>


UpdateScroll	proc	near
	class	OLScrollbarClass
	
	mov	bp, sp
	sub	sp, size US_Local

	push	si
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		;vis stuff in bx
	push	di				;save gstate
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;di points to vis
	mov	dx, ds:[bx].OLSBI_attrs  	;need to keep orientation
	mov	US_local.US_attrs, dx
	mov	dx, ds:[di].VI_bounds.R_left	;get left
	mov	cx, ds:[di].VI_bounds.R_top	;save top + anchor height
	mov	di, bx				;now di points to specific
	call	SwapIfHorizontal		;flip these if horiz
	mov	US_local.US_left, dx		;store as width offset
	add	cx, MO_SCR_AREA_MARGIN
	mov	US_local.US_top, cx		;top might come in useful...
	mov	ax, cx				;put length offset in ax
	add	cx, ds:[di].OLSBI_elevOffset	;get current elevator offset
	mov	US_local.US_oldElevStart, cx	;store
	push	cx				;save, will use to compare
	push	ax
	;
	; 2.x: OLScrollbarDraw sets OLSBI_drawnDocRatio before drawing, and
	; UpdateScroll is no longer called (the whole scrollbar is redrawn).
	;
	;mov	ax, ds:[di].OLSBI_docOffset	;get true doc offset
	;mov	ds:[di].OLSBI_drawnDocOff, ax	;and set as drawn offset
        call	SetElevOffset			; set position of elevator
	pop	ax
	mov	cx, ds:[di].OLSBI_elevOffset	;get current elevator offset
	add	cx, ax				;add offset to scroll top
	mov	US_local.US_newElevStart, cx	;store
	add	ax, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	dec	ax				;not quite absolute bottom
	mov	US_local.US_bottom, ax		;and keep around for later
	tst	ds:[di].OLSBI_elevOffset	;is there a thumb?
	pop	dx				;get old elevator offset
	pop	di				;restore gstate
	clc					;assume no blit happening
	LONG	js	90$			;no thumb, just exit
	
	cmp	cx, dx				;the same elevator offset?
	clc					;assume so, return no blit done
	LONG	je	90$			;yes, exit
	;
	; First, redraw the elevator.
	;
	mov	ax, C_WHITE			;draw white inside
	call	GrSetAreaColor
	mov	ax, C_BLACK
	call	GrSetLineColor
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	ax, DK_BLUE			;draw white inside
	call	GrSetAreaColor
	mov	ax, YELLOW
	call	GrSetLineColor
endif		;END of DESKMATE specific code ---------------------------------
	mov	bx, US_local.US_newElevStart	;dest top
	mov	dx, bx				;bottom
	add	dx, MO_THUMB_HEIGHT-1
	mov	ax, US_local.US_left		;left edge
	mov	cx, ax				;right edge
	add	cx, MO_SCROLLBAR_WIDTH-1
	test	US_local.US_attrs, mask OLSA_VERTICAL	;see if vertical now
	jnz	191$				;not horiz, branch
	xchg	ax, bx				;else xchg everything
	xchg	cx, dx
191$:
	call	GrDrawRect			;draw a frame
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	GrFillRect			;draw inside

	mov	al, SDM_50 or mask SDM_INVERSE	;use inverse 50% pattern
	call	GrSetAreaMask
	mov	ax, US_local.US_left		;get left edge
	mov	cx, ax
	add	cx, (MO_SCROLLBAR_WIDTH-1)-1	;and right edge - 1
	inc	ax				;left edge + 1

	mov	bx, US_local.US_oldElevStart	;see if moving up
	mov	dx, US_local.US_newElevStart
	cmp	bx, dx
	ja	20$				;moving up, branch
	;
	; Moving down. White out the scrollbar between
	; oldElevOffset and newElevOffset.  This is only for the purpose
	; of drawing 25% pattern where black used to be, so we'll just
	; rewrite pixels in a 75% pattern.
	;
	cmp	bx, US_local.US_top		;see if old thumb at the top
	jne	192$				;no, branch
	inc	bx				;else avoid greying arrow bottom
192$:
	dec	dx
	jmp	short	30$			;go do the next thing
20$:
	;
	; Moving up. Redraw the elevator between
	; newElevOffset and oldElevOffset.
	;
	xchg	bx, dx				;switch old and new
	add	bx, MO_THUMB_HEIGHT		;make bottom of new elevator
	add	dx, MO_THUMB_HEIGHT-1		;make bottom of old elevator
	cmp	dx, US_local.US_bottom		;see if at bottom of scrollbar
	jne	30$				;no, branch
	dec	dx				;else avoid greying arrow top
30$:
	cmp	bx, dx				;is there something to grey?
	ja	40$				;no, skip it
	call	TwoSwapIfHoriz			;swap ax-bx, cx-dx
	call	GrFillRect
	push	ax
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, C_BLACK
	call	GrSetAreaColor
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	mov	ax, YELLOW			;draw white inside
	call	GrSetAreaColor
endif		;END of DESKMATE specific code ---------------------------------
	pop	ax
	call	GrFillRect
40$:
	mov	al, SDM_100			;restore solid draw mask
	call	GrSetAreaMask
	stc					;say blit was done
90$:
	pop	si
	mov	sp, bp				;destroy locals
	ret
UpdateScroll	endp


TwoSwapIfHoriz	proc	near
	class	OLScrollbarClass
	
	test	US_local.US_attrs, mask OLSA_VERTICAL	;see if horizontal
	jnz	10$					;no, branch
	xchg	ax, bx
	xchg	cx, dx
10$:
	ret
TwoSwapIfHoriz	endp



ScrollbarCommon	ends

DrawBW segment resource

;---------------------------------
; Motif Vertical Scrollbar String 
;		PARAM_2 - top of thumb
;		PARAM_3 - bottom of scrollbar
;---------------------------------

; Start here if unscrollable
  
whiteOutVertStr	label	byte		
	SBBeginString
if 	_DESKMATE
	SBSetAreaColorIndex	C_WHITE
endif
if	_MOTIF
	SBSetAreaColorIndex	LT_GREY
endif
	SBFillRect 1, MO_ARROW_HEIGHT,(MO_SCROLLBAR_WIDTH-1)-1,PARAM_3-(MO_ARROW_HEIGHT-1)-1
	;FALL_THROUGH
	
; Start here if scrollable
  
vertScrStr	label	byte
	SBFillBitmap	1, 1, <(offset UAVBM_end - offset UAVBM_start)>
UAVBM_start	label	byte
	Bitmap <MO_SCROLLBAR_WIDTH-2,MO_ARROW_HEIGHT-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
	byte	11111101b, 11111111b
	byte	11111000b, 11111111b
	byte	11110000b, 01111111b
	byte	11100000b, 00111111b
	byte	11000000b, 00011111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
UAVBM_end	label 	byte
	SBEndString

	SBBeginString
	SBFillBitmap	1, 1, <(offset UAVB_end - offset UAVB_start)>
UAVB_start	label	byte
	Bitmap <MO_SCROLLBAR_WIDTH-2,MO_ARROW_HEIGHT-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000010b, 00000000b
	byte	00000111b, 00000000b
	byte	00001111b, 10000000b
	byte	00011111b, 11000000b
	byte	00111111b, 11100000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
UAVB_end	label 	byte
if _MOTIF	;START of MOTIF/CUA specific code ----------------------
	    SBSetAreaColorIndex	DK_GREY
	    SBSetLineColorIndex	DK_GREY
endif			;END of MOTIF/CUA specific code ------------------------
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	    SBSetAreaColorIndex	YELLOW
	    SBSetLineColorIndex	YELLOW
endif		;END of DESKMATE specific code ---------------------------------
	SBDrawRect 0, 0,MO_SCROLLBAR_WIDTH-1,MO_ARROW_HEIGHT-1
	SBDrawRect 0, MO_ARROW_HEIGHT-1, MO_SCROLLBAR_WIDTH-1,PARAM_3-(MO_ARROW_HEIGHT-1)
	SBEndString

sThumb	label	byte
	SBBeginString
	SBDrawRect 0,PARAM_2,MO_SCROLLBAR_WIDTH-1,PARAM_2+MO_THUMB_HEIGHT-1
	SBSetAreaColorIndex	C_WHITE
	SBFillRect 1,PARAM_2+1,MO_SCROLLBAR_WIDTH-2,PARAM_2+MO_THUMB_HEIGHT-2
	SBEndString
eThumb	label	byte

sPageUp	label	byte
	SBBeginString
	SBSetAreaMask	<SDM_50 or mask SDM_INVERSE>
	SBFillRect 1, MO_ARROW_HEIGHT,(MO_SCROLLBAR_WIDTH-1)-1,PARAM_2-1
	SBEndString

	SBBeginString
	SBSetAreaMask	SDM_50
	SBFillRect 1, MO_ARROW_HEIGHT,(MO_SCROLLBAR_WIDTH-1)-1,PARAM_2-1
	SBEndString
ePageUp	label	byte

sPageDn	label	byte
	SBBeginString
	SBSetAreaMask	<SDM_50 or mask SDM_INVERSE>
	SBFillRect 1, PARAM_2+MO_THUMB_HEIGHT,(MO_SCROLLBAR_WIDTH-1)-1,PARAM_3-(MO_ARROW_HEIGHT-1)-1
	SBEndString

	SBBeginString
	SBSetAreaMask	SDM_50
	SBFillRect 1, PARAM_2+MO_THUMB_HEIGHT,(MO_SCROLLBAR_WIDTH-1)-1,PARAM_3-(MO_ARROW_HEIGHT-1)-1
	SBEndString
ePageDn	label	byte

	SBBeginString
	SBFillBitmap	1, PARAM_3-(MO_ARROW_HEIGHT-1)+1, <(offset DAVBM_end- offset DAVBM_start)>
DAVBM_start	label	byte
	Bitmap <MO_SCROLLBAR_WIDTH-2,MO_ARROW_HEIGHT-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11111000b, 11111111b
	byte	11000000b, 00011111b
	byte	11100000b, 00111111b
	byte	11110000b, 01111111b
	byte	11111000b, 11111111b
	byte	11111101b, 11111111b
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
DAVBM_end	label	byte
	SBEndString

	SBBeginString
	SBFillBitmap	1, PARAM_3-(MO_ARROW_HEIGHT-1)+1, <(offset DAVB_end- offset DAVB_start)>
DAVB_start	label	byte
	Bitmap <MO_SCROLLBAR_WIDTH-2,MO_ARROW_HEIGHT-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00000111b, 00000000b
	byte	00111111b, 11100000b
	byte	00011111b, 11000000b
	byte	00001111b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
DAVB_end	label	byte
	SBDrawRect 0, PARAM_3-(MO_ARROW_HEIGHT-1),MO_SCROLLBAR_WIDTH-1,PARAM_3
	SBEndString
	
;---------------------------------
; Motif Horizontal Scrollbar String
;	PARAM_2 - offset to left of thumb
;	PARAM_2 - width
;---------------------------------
	
;
; Start here if unscrollable
;
whiteOutHorizStr	label	byte		
	SBBeginString
if 	_DESKMATE
	SBSetAreaColorIndex	C_WHITE
endif
if	_MOTIF
	SBSetAreaColorIndex	LT_GREY
endif
	SBFillRect MO_ARROW_HEIGHT,1,PARAM_3-(MO_ARROW_HEIGHT-1)-1, (MO_SCROLLBAR_WIDTH-1)-1
	;FALL THROUGH

;
; Start here if scrollable
;
horizScrStr	label	byte
	SBFillBitmap	1, 1, <(offset UAHBM_end - offset UAHBM_start)>
UAHBM_start	label	byte
	Bitmap <MO_ARROW_HEIGHT-2,MO_SCROLLBAR_WIDTH-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
	byte	11111101b, 11111111b
	byte	11111001b, 11111111b
	byte	11110001b, 11111111b
	byte	11100000b, 00000111b
	byte	11000000b, 00000111b
	byte	11100000b, 00000111b
	byte	11110001b, 11111111b
	byte	11111001b, 11111111b
	byte	11111101b, 11111111b
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
UAHBM_end	label 	byte
	SBEndString

	SBBeginString
	SBFillBitmap	1, 1, <(offset UAHB_end - offset UAHB_start)>
UAHB_start	label	byte
	Bitmap <MO_ARROW_HEIGHT-2,MO_SCROLLBAR_WIDTH-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000010b, 00000000b
	byte	00000110b, 00000000b
	byte	00001110b, 00000000b
	byte	00011111b, 11110000b
	byte	00111111b, 11110000b
	byte	00011111b, 11110000b
	byte	00001110b, 00000000b
	byte	00000110b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
UAHB_end	label 	byte
if _MOTIF 	;START of MOTIF/CUA specific code ----------------------
	SBSetAreaColorIndex	DK_GREY
	SBSetLineColorIndex	DK_GREY
endif			;END of MOTIF/CUA specific code ------------------------
if _DESKMATE	;START of DESKMATE specific code -------------------------------
	SBSetAreaColorIndex	YELLOW
	SBSetLineColorIndex	YELLOW
endif		;END of DESKMATE specific code ---------------------------------
	SBDrawRect 0, 0,PARAM_3,MO_SCROLLBAR_WIDTH-1
	SBDrawRect MO_ARROW_HEIGHT-1, 0,PARAM_3-(MO_ARROW_HEIGHT-1),MO_SCROLLBAR_WIDTH-1
	SBEndString

sThumbH	label	byte
	SBBeginString
	SBDrawRect PARAM_2, 0,PARAM_2+MO_THUMB_HEIGHT-1,MO_SCROLLBAR_WIDTH-1
	SBSetAreaColorIndex	C_WHITE
	SBFillRect PARAM_2+1,1,PARAM_2+MO_THUMB_HEIGHT-2,MO_SCROLLBAR_WIDTH-2
	SBEndString

eThumbH	label	byte
sPageUpH	label	byte
	SBBeginString
	SBSetAreaMask	<SDM_50 or mask SDM_INVERSE>
	SBFillRect MO_ARROW_HEIGHT,1,PARAM_2-1, (MO_SCROLLBAR_WIDTH-1)-1
	SBEndString

	SBBeginString
	SBSetAreaMask	SDM_50
	SBFillRect MO_ARROW_HEIGHT,1,PARAM_2-1, (MO_SCROLLBAR_WIDTH-1)-1
	SBEndString

ePageUpH	label	byte
sPageDnH	label	byte
	SBBeginString
	SBSetAreaMask	<SDM_50 or mask SDM_INVERSE>
	SBFillRect PARAM_2+MO_THUMB_HEIGHT,1,PARAM_3-(MO_ARROW_HEIGHT-1)-1, (MO_SCROLLBAR_WIDTH-1)-1
	SBEndString

	SBBeginString
	SBSetAreaMask	SDM_50
	SBFillRect PARAM_2+MO_THUMB_HEIGHT,1,PARAM_3-(MO_ARROW_HEIGHT-1)-1, (MO_SCROLLBAR_WIDTH-1)-1
	SBEndString

ePageDnH	label	byte
	SBBeginString
	SBFillBitmap	PARAM_3-(MO_ARROW_HEIGHT-1)+1, 1, <(offset DAHBM_end- offset DAHBM_start)>
DAHBM_start	label	byte
	Bitmap <MO_ARROW_HEIGHT-2,MO_SCROLLBAR_WIDTH-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
	byte	11111110b, 11111111b
	byte	11111110b, 01111111b
	byte	11111110b, 00111111b
	byte	11000000b, 00011111b
	byte	11000000b, 00001111b
	byte	11000000b, 00011111b
	byte	11111110b, 00111111b
	byte	11111110b, 01111111b
	byte	11111110b, 11111111b
	byte	11111111b, 11111111b
	byte	11111111b, 11111111b
DAHBM_end	label	byte
	SBEndString

	SBBeginString
	SBFillBitmap	PARAM_3-(MO_ARROW_HEIGHT-1)+1, 1, <(offset DAHB_end- offset DAHB_start)>
DAHB_start	label	byte
	Bitmap <MO_ARROW_HEIGHT-2,MO_SCROLLBAR_WIDTH-2,BMC_UNCOMPACTED,BMF_MONO>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 00000000b
	byte	00000001b, 10000000b
	byte	00000001b, 11000000b
	byte	00111111b, 11100000b
	byte	00111111b, 11110000b
	byte	00111111b, 11100000b
	byte	00000001b, 11000000b
	byte	00000001b, 10000000b
	byte	00000001b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
DAHB_end	label	byte
	SBEndString

;
; DrawBWScrollbar skips parts of the vertical and horizontal strings with
; the same offsets.
;
.assert (offset eThumbH - offset sThumbH) eq (offset eThumb - offset sThumb)
.assert (offset ePageUpH - offset sPageUpH) eq (offset ePageUp - offset sPageUp)
.assert (offset ePageDnH - offset sPageDnH) eq (offset ePageDn - offset sPageDn)
.assert (offset ePageDnH - offset sThumbH) eq (offset ePageDn - offset sThumb)

DrawBW ends

