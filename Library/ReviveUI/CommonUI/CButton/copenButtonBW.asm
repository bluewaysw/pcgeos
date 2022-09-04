COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButtonBW.asm (B&W draw routines for OLButtonClass)

ROUTINES:
    INT DrawBWButton		This procedure draws an OLButtonClass
				object for a black and white display.

    INT DrawBWRegionAtCP	Draws the region passed at the current
				point.  It basically assumes that the
				region definition is in the same segment as
				CS.

    INT DrawBWRegion		Draws the region passed at the given
				coords.  It basically assumes that the
				region definition is in the same segment as
				CS.  Width and height are passed to region
				as PARAM_2 and PARAM_3.  The origin of the
				region is drawn at the (left, top)
				coordinates passed.

    INT UpdateBWButtonBorder	This procedure updates the border of a
				button, when an UPDATE event is received.

    INT DrawTopBottomLinesIfNeeded 
				Hacks to draw top and bottom lines of a
				menu bar button if they are needed (i.e. if
				it isn't already drawn by the menu itself).

    INT UpdateBWButtonDepressed This procedure updates the interior portion
				of a button, when an UPDATE event is
				received.

    INT DrawInvertedTitleCloseButton 
				Draw a special bitmap for the title-bar
				close button.

    INT UpdateBWButtonSelected	This procedure updates the checkmark
				portion of an OLSetting object which is in
				a menu.

    INT ReDrawBWButton		This procedure redraws a button objects
				from scratch.

    INT DecreaseSizeIfDrawingShadow 
				Decreases the button size if we're drawing
				a shadow, so stuff will be centered
				properly.

    INT DrawBWButtonBackground	This procedure clears the background for a
				button, when a MSG_VIS_DRAW is received.

    INT ShouldDrawRoundedTopCorner 
				Determines if the button should draw
				background with a rounded corner.	If
				so, returns region to use.

    INT ShouldButtonNotDrawBorder 
				Figures out whether this button should draw
				its border.

    INT DrawBWButtonBorder	This procedure draws a portion of a button,
				when a MSG_VIS_DRAW is received.

    INT DrawBWButtonDepressedInterior 
				Draw the interior portion of the button.

    INT DrawBWButtonMenuMark	This procedure draws a portion of a button,
				when a MSG_VIS_DRAW is received.

    INT DrawBWButtonCheckMark	This procedure draws a portion of a button,
				when a MSG_VIS_DRAW is received.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		Contents split from copenButton.asm and
				lots of cleanup work.

DESCRIPTION:
	$Id: copenButtonBW.asm,v 1.87 96/10/07 15:56:20 grisco Exp $

------------------------------------------------------------------------------@

DrawBW segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWButton

DESCRIPTION:	This procedure draws an OLButtonClass object for a
		black and white display.

CALLED BY:	OLButtonDraw

PASS:		*ds:si - instance data
		cl - color scheme (NOT USED)
		ch - DrawFlags:  DF_EXPOSED set if updating
		di - GState to use

RETURN:		carry - set

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	For speed, draw differently depending on state:

	plain -> bordered (draw up border)
	plain -> depressed (highlight, draw depressed border)
	bordered -> plain (unhighlight, {draw up border or invert border})
	bordered -> depressed (highlight)
	depressed -> plain (unhighlight, remove border)
	depressed -> bordered (unhighlight)

	Note: "DEFAULT", "BORDER", and "MARK" are OpenLook-specific state info.

	if (update) {
		Draw entire button:
			(assume background drawn by MSG_EXPOSE)
			if (not ENABLED)	{ set draw mode = 50% }
			if (BORDER)	{ draw border }
			if (DEPRESSED) {
				draw interior in black
				set moniker to draw in C_WHITE
			} else {
				draw interior in C_WHITE
				set moniker to draw in C_BLACK
			}
			if (HAS MARK)	{ draw mark }
			draw moniker
			restore draw mode

	} else if (ENABLED changed or STATE_UNKNOWN or DEFAULT changed) {
		Draw background (C_WHITE)
		Draw entire button (see above)
	} else {
		if (border changed)	{ Draw border }
		if (depressed state changed) { Invert interior of button }
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	7/89		pseudo-code, additional commenting

------------------------------------------------------------------------------@

if _RUDY
	COMMAND_BUTTONS_ARE_BOLD	=	TRUE
else
	COMMAND_BUTTONS_ARE_BOLD	=	FALSE
endif
	

DrawBWButton	proc	far
	class	OLButtonClass
	uses	ds, es
	.enter

if COMMAND_BUTTONS_ARE_BOLD
	call	GrSaveState
	;
	; Use bold text if in a reply or menu bar.  (Changed to always 
	; use bold if we get here.)
	;
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jnz	inABar
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
inABar:
	pop	di
	jz	dontSetBold
	push	cx
	mov	dx, FOAM_LARGE_FONT_SIZE
	clr	ax
	clr	cx
	call	GrSetFont
	mov	ax, mask TS_BOLD		;for all reply bar buttons...
	call	GrSetTextStyle
	pop	cx
dontSetBold:

endif

if not _REDMOTIF ;----------------------- Not needed for Redwood project

	;first set up a bunch of registers WHICH WILL NOT CHANGE

	push	ds, si

	segmov	es, ds			;keep object block in es 2/12/93

	call	OLButtonGetGenAndSpecState
					;set bx = OLBI_specState
					;    cl = OLBI_optFlags
					;    dl = GI_state
					;    dh = VI_attrs
	mov	al, cl			;set al = OLBI_optFlags
	mov	ah, dh			;set ah = VI_attrs

	push	ax			;save VI_attrs, OLBI_optFlags

	test	ch, mask DF_EXPOSED	;if this is an UPDATE (MSG_META_EXPOSED)
	pushf

	;Registers which will remain constant:
	;	ax = VI_attrs, OLBI_optFlags
	;	bx = OLBI_specState
	;	di = GState
	;(We do not need DrawFlags or ColorScheme)

	call	OLButtonMovePenCalcSize	; position pen,
					; (cx, dx) = size of button

	call 	OLButtonChooseBWRegionSet	; pass: *ds:si = object

	;sets ds:bp = region table to use (has offsets to region definitions)

	;now decide if we need to completely redraw the button, or just toggle/
	;redraw a portion of it.

	;If this redraw is caused by an expose event, be sure to set the
	;draw state unknown so that the background will redraw.
	popf					;Is this caused by an EXPOSE?
	jnz	setDrawStateUnknownAndRedraw	;Then force redraw of button

	;CUA/Motif: check monitor type, if color, pretend we are
	;doing an UPDATE and redraw everything (WE KNOW THAT DS = IDATA)

CUAS <	test	ds:[moCS_flags], mask CSF_BW	;check boolean		>
CUAS <	jz	clearRedraw			;skip if is COLOR...	>

	;compare old state to new state to see if can simply invert something

	test	al, mask OLBOF_DRAW_STATE_KNOWN	;if state not known then
	jz	clearRedraw			;skip for full redraw...

;OLD
;	push	ax
;	test	ah, mask VA_FULLY_ENABLED	;see if enabled
;	mov	ah, 0				;assume not, clear all bits
;	jz	10$				;no, branch
;
;	not	ah				;else invert all bits
;10$:
;	xor	ah, al				;look OLBI_optFlags' enabled bit
;	test	ah, mask OLBOF_ENABLED		;has enabled status changed?
;	pop	ax				;restore ah = VI_attrs
;NEW
	push	ax
	xor	ah, al			;ah = VA_attr XOR OLBI_optFlags,
					;to see if ENABLED status changed
	test	ah, mask OLBOF_ENABLED
	pop	ax
	jnz	clearRedraw		;skip if so...

;MOVED ABOVE ENABLED TEST... 7/19/90 EDS.
;	test	al, mask OLBOF_DRAW_STATE_KNOWN	;if state not known then
;	jz	clearRedraw			;skip for full redraw...

	xor	al, bl				;compare OLBI_optFlags to
						;OLBI_specState. al = what chgd.
	test	al, mask OLBOF_DRAWN_DEFAULT	;if default changed then
	jnz	clearRedraw			;skip for full redraw...

	;if the CURSORED status changed, we must fall through to fullRedraw,
	;because that is the only way to call OpenDrawMoniker at this point.
	;(Don't worry about this in menus.  -cbh 3/ 9/93)

if (not _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING)
MO <	test	bx, mask OLBSS_IN_MENU_BAR	;buttons in menus are	>
MO <	jnz	updateBorder		 	; never inverted	>
MO <	test	bx, mask OLBSS_IN_MENU					>
MO <	jnz	updateBorder						>
endif

if	(not _STYLUS) and (not _PCV)
	; Stylus does not have a cursored look, so skip this since it
	; just causes extra redraws.
	; PCV doesn't draw selection cursors so skip this.
	
	test	al, mask OLBOF_DRAWN_CURSORED
	jnz	clearRedraw
endif	;(not _STYLUS) and (not _PCV)

updateBorder:
	;No need for full redraw - we can simply redraw the aspect(s) of the
	;button which have changed.
	;	al = OLBI_optFlags XOR OLBI_specState (what has changed)
	;	bx = OLBI_specState (OBLSS_BORDERED, etc)
	;	cx = button width
	;	dx = button height
	;	di = handle of graphics state
	;	ds:bp = region table

	test	al, mask OLBOF_DRAWN_BORDERED	;did border state change ?
	jz	updateDepressed			;skip if not...

	push	ax
if _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING
	call	UpdateBWButtonDepressed
else
	call	UpdateBWButtonBorder		;draw border again
endif
	pop	ax

updateDepressed:
	test	al, mask OLBOF_DRAWN_DEPRESSED	;did depressed state change ?
	jz	updateSelected			;skip if not...

	push	ax
	call	UpdateBWButtonDepressed		;invert interior of button
	pop	ax

updateSelected:

if _CUA or _MAC	;----------------------------------------------
	;CUA: if is OLSettingClass object which is inside
	;a menu, must redraw the checkmark which is to the left
	;of the moniker.

	test	al, mask OLBOF_DRAWN_SELECTED	;did selected state change?
	jz	done				;skip if not...

	call	UpdateBWButtonSelected		;draw/erase checkmark if
						;is OLSettingClass object
						;inside a menu.
endif		;--------------------------------------------------------------

	jmp	short done

clearRedraw:
	;Button requires a complete redraw, including background. Oh well!
	;	ax = VI_attrs, OLBI_optFlags
	;	bx = OLBI_specState
	;	cx, dx = button size
	;	di = GState
	;	ds:bp = region table (in idata)

	pop	ax				;get VI_attrs, OLBI_optFlags

clearRedrawAfterPopAX:
	pop	es, si				;pass *es:si = object
	call	ReDrawBWButton
if COMMAND_BUTTONS_ARE_BOLD
	call	GrRestoreState
endif
	.leave
	ret					;returns *ds:si = object

setDrawStateUnknownAndRedraw:
	;This really forces the button to do a full redraw, INCLUDING
	;redrawing the background.  This is important especially if the
	;button is on a non-white background.  Note that we aren't really
	;changing the instance data here, just the local copy of the
	;instance data.  There's no reason to do the former.
	
	pop	ax				;get VI_attrs, OLBI_optFlags
    	andnf	al, mask OLBOF_DRAW_STATE_KNOWN
	jmp	short clearRedrawAfterPopAX
	
done:
	pop	ax			;clean up stack
	pop	ds, si

endif ;not _REDMOTIF -------------------- Not needed for Redwood project

if COMMAND_BUTTONS_ARE_BOLD
	mov	ax, (mask TS_BOLD) shl 8		;turn off BOLD if on...
	call	GrSetTextStyle
endif

	.leave
	ret
DrawBWButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWRegionAtCP

SYNOPSIS:	Draws the region passed at the current point.  It basically
		assumes that the region definition is in the same segment
		as CS.

PASS:		ax, bx, cx, dx 	- paramters to region (if needed)
		si	- offset to region
		di	- handle of graphics state (locked)

RETURN:		nothing

DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _REDMOTIF ;----------------------- Not needed for Redwood project

DrawBWRegionAtCP	proc	near
	push	ds


FXIP <	push	bp						>
FXIP <	push	ax, bx						>
FXIP <	mov	bx, handle DrawBWRegions			>
FXIP <	call	MemLock						>
FXIP <	mov	ds, ax						>
FXIP <	mov	bp, bx			; bp = resource handle  >
FXIP <	pop	ax, bx						>

NOFXIP<	segmov	ds, cs						>

	call	GrDrawRegionAtCP

FXIP <	push	bx						>
FXIP <	mov	bx, bp			; bx = resource handle  >
FXIP <	call	MemUnlock					>
FXIP <	pop	bx						>
FXIP <	pop	bp						>

	pop	ds
	ret
DrawBWRegionAtCP	endp

			
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the region passed at the given coords.  It basically
		assumes that the region definition is in the same segment
		as CS.  Width and height are passed to region as PARAM_2
		and PARAM_3.  The origin of the region is drawn at the
		(left, top) coordinates passed.

CALLED BY:	BWButton drawing routines.  Internal.
PASS:		ax	- Left
		bx	- Top
		cx	- Right
		dx	- Bottom
		si	- offset to region
		di	- handle of gstate
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_ROUND_THICK_DIALOGS

DrawBWRegion	proc	near
	uses	cx,dx,ds
	.enter

FXIP <	push	bp						>
FXIP <	push	ax, bx						>
FXIP <	mov	bx, handle DrawBWRegions			>
FXIP <	call	MemLock						>
FXIP <	mov	ds, ax						>
FXIP <	mov	bp, bx			; bp = resource handle  >
FXIP <	pop	ax, bx						>

NOFXIP<	segmov	ds, cs						>
	
	sub	cx, ax
	sub	dx, bx
	call	GrDrawRegion
	
FXIP <	push	bx						>
FXIP <	mov	bx, bp			; bx = resource handle  >
FXIP <	call	MemUnlock					>
FXIP <	pop	bx						>
FXIP <	pop	bp						>
	
	.leave
	ret
DrawBWRegion	endp

endif	;_ROUND_THICK_DIALOGS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateBWButtonBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure updates the border of a button, when
		an UPDATE event is received.

CALLED BY:	DrawBWButton
		DrawBWMotifSettingBorderIfInMenu	

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table (in idata)
		*es:si = menu button

RETURN:		bx, cx, dx, di, ds, bp, si = SAME

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		cleanup
	Eric	6/90		now used for Motif BW settings in menus also.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateBWButtonBorder	proc	near
	class	OLButtonClass

	push	si
	mov	ax, C_WHITE			;assume not bordered, draw white
	test	bx, mask OLBSS_BORDERED
	jz	bordered			;skip if not bordered...

	mov	ax, C_BLACK

bordered:
	call	GrSetAreaColor
	call	GrSetLineColor
	mov	si, ds:[bp].BWBRSS_borderPtr ;point to region definition
	tst	si
	jz	done				;skip if no region definition...

	call	DrawBWRegionAtCP

;	Not needed if inverting the menu button.  -cbh 3/11/93
;	pop	si
;MO <	call	DrawTopBottomLinesIfNeeded	;fill in missing lines	>
;	push	si				;to match pop
done:
	pop	si

	ret
UpdateBWButtonBorder	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawTopBottomLinesIfNeeded

SYNOPSIS:	Hacks to draw top and bottom lines of a menu bar button
		if they are needed (i.e. if it isn't already drawn by the 
		menu itself).

CALLED BY:	?

PASS:		*es:si -- menu button
		di -- gstate, with line color set to black to draw, 
						     white to erase

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/11/93       	Initial version
	Chris	3/11/93		Retired in favor of menu button inversion.

------------------------------------------------------------------------------@

if	0	;not needed if inverting menu bar buttons

DrawTopBottomLinesIfNeeded 	proc	near		uses ds, bx, cx, dx, bp
	parentTop    local word
	parentBottom local word

	.enter
	segmov	ds, es				;*ds:si <- button

	push	di				;not in menu bar, exit
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	pop	di
	jz	exit

	call	GrGetCurPos			;save pen position (cbh 3/11/93)
	push	ax, bx

	push	si
	call	VisSwapLockParent		;get parent bounds, store
	jnc	exitPopSI

	push	bx
	call	OpenGetLineBounds
	mov	parentTop, bx
	mov	parentBottom, dx
	pop	bx
	call	ObjSwapUnlock
	pop	si				;*ds:si = menu button

	call	OpenGetLineBounds		;get our bounds

	call	OpenCheckIfCGA			;CGA, must raise top edge by a
	jnc	5$				;  pixel, due to bounds hacks
	dec	bx
5$:
	cmp	bx, parentTop
	je	10$
	call	GrDrawHLine			;not touching top of bar, draw
10$:	
	inc	dx				;(menu is not quite on bottom)
	cmp	dx, parentBottom
	je	20$
	dec	dx				;(restore our bottom)
	mov	bx, dx
	call	GrDrawHLine			;not touching bottom, draw
20$:
	push	si				;to match pop below

exitPopSI:	
	pop	si

	pop	ax, bx				;restore pen pos (3/11/93 cbh)
	call	GrMoveTo
exit:
	.leave
	ret
DrawTopBottomLinesIfNeeded	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateBWButtonDepressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure updates the interior portion of a button, when
		an UPDATE event is received.

CALLED BY:	DrawBWButton

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table (in idata)
		*es:si = object

RETURN:		bx, cx, dx, di, ds, bp = SAME

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		cleanup
	JimG	4/94		Added Stylus stuff for rounded top corners

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateBWButtonDepressed	proc	near
	class	OLButtonClass

if _RUDY
	;
	; In menus, invert the background; otherwise don't bother (parent
	; interaction is generally inverted instead).
	;
	call	CheckIfInMenu
	mov	ax, UNSELECTED_TEXT_BACKGROUND
	jnc	setColor
	mov	ax, SELECTED_TEXT_BACKGROUND
setColor:
	call	GrSetAreaColor
	mov	al, MM_AND
else
	mov	al, MM_INVERT		;set draw mode = INVERT
endif
	call	GrSetMixMode

if _JEDIMOTIF
	push	si				; save object
endif
	
if	_ROUND_THICK_DIALOGS	;----------------------------------------------
	;
	; Check to see if this button should have a rounded top corner
	; because it is in the title bar on the left or right edge.  If
	; so, this routine will return a new region that overrides the 
	; region specified in the Region Set structure.
	;
	call	ShouldDrawRoundedTopCorner
	jc	doDraw
endif	;_ROUND_THICK_DIALOGS -------------------------------------------------
	mov	si, ds:[bp].BWBRSS_interiorPtr	;draw button interior

doDraw::

if _JEDIMOTIF
	;
	;  If this is the title bar close button, draw a special
	;  bitmap to indicate it's depressed.  (Carry clear if normal).
	;
	pop	ax
	push	ds, si, bx, ax
	segmov	ds, es, si		
	mov_tr	si, ax				; *ds:si = object
	mov	ax, HINT_CLOSE_BUTTON
	call	ObjVarFindData			; carry set if found
	pop	ds, si, bx, ax
	jnc	notCloseButton
	;
	;  OK, this is the window close trigger.  If it's being
	;  depressed, draw the sad picture, otherwise draw the
	;  happy picture.
	;
	call	DrawInvertedTitleCloseButton
	jmp	doneDraw
notCloseButton:
	call	DrawBWRegionAtCP

else	; not _JEDIMOTIF ------------------------------------------------------

if	 _POPUP_MARK_DRAWN_IN_REVERSE_VIDEO
	
	; Only for buttons with a menu-down mark (pop-up buttons)
	test	bx, mask OLBSS_MENU_DOWN_MARK				    
	jz	doTheDrawing
	
	; Only invert the region up until the reversed-video mark.  The
	; width passed in takes into account the border width whereas the
	; constant for the offset of the reversed-video region does not, so
	; we have to take it into account again here.. isn't this fun?
	; --JimG
	
if	 _THICK_DROP_MENU_BW_BUTTONS
    	sub	cx, _REVERSE_RECTANGLE_OFFSET_FROM_RIGHT_EDGE - 2
else	;_THICK_DROP_MENU_BW_BUTTONS is FALSE
    	sub	cx, _REVERSE_RECTANGLE_OFFSET_FROM_RIGHT_EDGE - 1
endif	;_THICK_DROP_MENU_BW_BUTTONS
	
endif	;_POPUP_MARK_DRAWN_IN_REVERSE_VIDEO

doTheDrawing::
	call	DrawBWRegionAtCP

endif	; _JEDIMOTIF ----------------------------------------------------------

doneDraw::
	;
	;  Restore the gstate to its usual grumpy self.
	;
	mov	al, MM_COPY		; restore draw mode
	call	GrSetMixMode

	ret
UpdateBWButtonDepressed	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfInMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Painfully check to see if we're in a "menu" (i.e. GIV_POPUP)

CALLED BY:	UpdateBWButtonDepressed, DrawBWButtonDepressedInterior

PASS:		*es:di -- object

RETURN:		carry set if in menu

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 7/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

CheckIfInMenu	proc	near		uses	ds, es, si, di, bx
	.enter
	segmov	ds, es
	call	SwapLockOLWin
	jnc	exit

	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jnc	unlockExit

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_POPUP
	clc
	jne	unlockExit			;not a popup, exit c=0
	stc

unlockExit:
	call	ObjSwapUnlock
exit:
	.leave
	ret
CheckIfInMenu	endp

endif

if _JEDIMOTIF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawInvertedTitleCloseButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a special bitmap for the title-bar close button.

CALLED BY:	UpdateBWButtonDepressed

PASS:		di = gstate
		*es:ax = object
		bx = OLButtonSpecState

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/25/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawInvertedTitleCloseButton	proc	near
		uses	ax,bx,cx,dx,si,bp,ds,es
		.enter
	;
	;  The gstate's in MM_INVERT right now -- fix it.
	;
		mov	si, ax
		segmov	ds, es, ax		; *ds:si = object
		mov	al, MM_COPY
		call	GrSetMixMode
	;
	;  Get the position at which to draw.
	;
		push	bx			; spec state
		call	VisGetBounds		; ax,bx,cx,dx = l, t, r, b
		add	bx, 3			; why?  dunno...
	;
	; slightly different position for modals
	;
		push	bx, si, di		; top, our chunk, gstate
		call	SwapLockOLWin		; *ds:si = OLWin, bx
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
.warn -private
		cmp	ds:[di].OLWI_type, MOWT_COMMAND_WINDOW
		jb	notModal		; (carry set)
		cmp	ds:[di].OLWI_type, MOWT_HELP_WINDOW+1
		jae	flipModality		; (carry clear)
		test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
					mask OLPWF_SYS_MODAL
.warn @private
		stc				; assume not modal
		jz	notModal
flipModality:
		cmc
notModal:
		call	ObjSwapUnlock		; (flags preserved)
		pop	bx, si, di		; top, our chunk, gstate
		jc	havePosition		; not modal
		dec	bx			; get modal position
havePosition:

FXIP <		movdw	cxdx, axbx		; save draw pos		>
FXIP <		mov	bx, handle DrawBWRegions			>
FXIP <		call	MemLock						>
FXIP <		mov	ds, ax						>
FXIP <		mov	bp, bx			; save handle		>
FXIP <		movdw	axbx, cxdx					>

NOFXIP <	segmov	ds, cs, dx					>
		
		pop	cx			; specstate
	;
	;  If we're depressed, pick the inverted bitmap,
	;  otherwise pick the not-inverted one.
	;
		mov	si, offset StartNotInvertBitmap
		test	cx, mask OLBSS_DEPRESSED
		jz	drawBitmap
		mov	si, offset StartInvertBitmap
drawBitmap:
		clr	dx			; no callback
		call	GrDrawBitmap

FXIP <		mov	bx, bp						>
FXIP <		call	MemUnlock					>
		
		stc				; say that we did something
done:
		.leave
		ret
DrawInvertedTitleCloseButton	endp


FXIP <	DrawBW	ends					>
FXIP <  DrawBWRegions	segment	resource		>

StartInvertBitmap	label	byte
	Bitmap < 16, 14, BMC_UNCOMPACTED, <BMF_MONO> >
	db      00000111b, 10000000b
	db      00011111b, 11100000b
	db      00111111b, 11110000b
	db      01111111b, 00111000b
	db	01111111b, 00111000b
	db      11111110b, 01111100b
	db	11111110b, 01111111b
	db	11111110b, 01111111b
	db      11110010b, 11111100b
	db	01111000b, 11111000b
	db	01111100b, 11111000b
	db      00111111b, 11110000b
	db	00011111b, 11100000b
	db	00000111b, 10000000b

StartNotInvertBitmap	label	byte
	Bitmap < 16, 14, BMC_UNCOMPACTED, <BMF_MONO> >
	db      00000111b, 10000000b
	db      00011000b, 01100000b
	db      00100000b, 00010000b
	db      01000000b, 11001000b
	db	01000000b, 11001000b
	db      10000001b, 10000100b
	db	10000001b, 10000111b
	db	10000001b, 10000111b
	db      10001101b, 00000100b
	db	01000111b, 00001000b
	db	01000011b, 00001000b
	db      00100000b, 00010000b
	db	00011000b, 01100000b
	db	00000111b, 10000000b

FXIP <  DrawBWRegions	ends				>
FXIP <	DrawBW	segment	resource			>

endif	; _JEDIMOTIF ---------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateBWButtonSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure updates the checkmark portion of an OLSetting
		object which is in a menu.

CALLED BY:	DrawBWButton

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table (in idata)

RETURN:		bx, cx, dx, di, ds, bp = SAME

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA or _MAC	;----------------------------------------------

UpdateBWButtonSelected	proc	near
	class	OLButtonClass

	test	bx, mask OLBSS_SETTING
	jz	done
	test	bx, mask OLBSS_IN_MENU
	jz	done

	push	ds, bx, cx, dx, bp	;SAVE BYTES
	mov	al, MM_INVERT		;set draw mode = INVERT
	call	GrSetMixMode

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	mov	bp, bx				; bp = resource handle  >
FXIP <	pop	ax, bx							>
	
NOFXIP<	segmov	ds, cs							>

	mov	si, offset CUASMenuSettingCheckmarkBM
	clr	dx
	call	GrFillBitmapAtCP

FXIP <	mov	bx, bp				; bx = resource handle	>
FXIP <	call	MemUnlock						>

20$:
	mov	al, MM_COPY		;restore draw mode
	call	GrSetMixMode
	pop	ds, bx, cx, dx, bp

done:
	ret
UpdateBWButtonSelected	endp

endif		;--------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReDrawBWButton

DESCRIPTION:	This procedure redraws a button objects from scratch.

CALLED BY:	DrawBWButton

PASS:		*es:si	= object
		ax	= VI_attrs, OLBI_optFlags
		bx	= OLBI_specState
		cx, dx	= button size
		di	= GState
		ds:bp	= region table (has offsets to region definitions
				in the DrawBW resource)

RETURN:		*ds:si	= object

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	stevey	8/94		rewrote completely
	VL	7/6/95		draw black buttons if
				_BLACK_NORMAL_BUTTON is true.

------------------------------------------------------------------------------@
ReDrawBWButton	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds,es

	optFlags	local	word	push	ax
	specState	local	OLButtonSpecState	push	bx
	buttonWidth	local	word	push	cx
	buttonHeight	local	word	push	dx
	thisObject	local	word	push	si
	regionTable	local	fptr
	drawPos		local	dword	; used by called routines
if _PCV
	usesGraphic	local	word	; store flags here
endif
	.enter

ForceRef	drawPos

	;
	;  Set up remaining locals.
	;
	mov	ax, ss:[bp]		; pointer to region table
	mov	ss:regionTable.offset, ax
	mov	ss:regionTable.segment, ds

	push	ds
	segmov	ds, es, ax		; *ds:si = object
	call	InsetBoundsIfReplyPopup
if _PCV
	push	ax, bx
	call	CheckForCompressedMoniker
	pushf
	pop	ax
	mov	ss:usesGraphic, ax
	pop	ax, bx
endif	
	pop	ds

	;
	; This HACK is used to draw the background behind a button which 
	; sits on the header area, such as the Workspace and Applications
	; icons.

OLS <	test	bx, mask OLBSS_SYS_ICON		;is this an icon?	>
OLS <	jz	standardErase			;skip if not...		>
OLS <	call	DrawBWButtonNormalInteriorForHeaderIcons		>
OLS <	jmp	short drawBorder					>

standardErase:

if _MOTIF or _PM	;------------------------------------------------------
	;
	; the button has just changed state: if the only difference 
	; is that it is no longer CURSORED, then do not redraw the 
	; background.
	;
	mov	ax, ss:optFlags		; get ah = VI_attrs, al = OLBI_optFlags

	test	al, mask OLBOF_DRAW_STATE_KNOWN
	jz	1$			;skip if don't have history...

	xor	ah, al			;ah = VI_attrs XOR OLBI_optFlags
	test	ah, mask OLBOF_ENABLED
	jnz	1$			;skip if ENABLED status changed...

	xor	al, bl
	test	al, mask OLBSS_BORDERED or mask OLBSS_DEFAULT or \
		    mask OLBSS_DEPRESSED or mask OLBSS_SELECTED

	jz	drawBorder		;skip if none of these changed (i.e.
					;OLBSS_CURSORED may have changed)...
1$:
endif	; _MOTIF or _PM -------------------------------------------------------

	push	bp			; locals
	mov	ax, C_WHITE		; draw C_WHITE as background color
if	_BLACK_NORMAL_BUTTON
	;
	;	Draw the background in black or set 50% mask for
	;	disabled button (make background grey) if conditions
	;	are satisfied.
	;
	call	BWButtonInvertColorIfNeeded
	push	ax			; ax = color
	jnc	drawBackground
	;
	; Check for GS_ENABLED, and set mask
	;
	mov	ax, ss:[optFlags]	;VI_attrs in high byte
	test	ah, mask VA_FULLY_ENABLED	
	jnz	drawBackground		;skip if fully enabled...
	mov	al, SDM_50
	call	GrSetTextMask		;in case text
	call	GrSetLineMask		;for mnemonics
	call	GrSetAreaMask		;in case bitmap	
drawBackground:
	pop	ax			; ax = color
endif	; _BLACK_NORMAL_BUTTON

	mov	si, ss:[thisObject]		; *es:si = object
	mov	bp, regionTable.offset	; ds:bp = table
	call	DrawBWButtonBackground	; erase background
	pop	bp			; locals
if _JEDIMOTIF
	stc				; indicate background redrawn
	jmp	short drawBorderCommon

drawBorder:
	clc				; background not redraw
drawBorderCommon:
	pushf				; save draw border flag
else
drawBorder:
endif
	;
	; Check for GS_ENABLED, and draw border.
	;
	mov	ax, ss:[optFlags]
	test	ah, mask VA_FULLY_ENABLED	
	jnz	10$			;skip if fully enabled...
if	_BLACK_NORMAL_BUTTON
	;
	;	If this is a normally black disabled button, 50% mask
	;	has already been set, therefore no need to set it again.
	;
	call	CheckForConditionsOfBlackNormalButton
	jc	10$
endif	; _BLACK_NORMAL_BUTTON

if USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, DISABLED_COLOR
	call	GrSetAreaColor
	mov	al, SDM_100
else
	mov	al, SDM_50
endif	
	call	GrSetTextMask		;in case text
	call	GrSetLineMask		;for mnemonics
	call	GrSetAreaMask		;in case bitmap

10$:
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, C_BLACK
	call	GrSetAreaColor
endif

if not DRAW_BUTTON_BORDERS
	;
	; No borders in Rudy UI.
	;
	stc
else
	;
	; Don't draw borders around triggers in a toolbox, if in keyboard-only 
	; mode.  -- Doug 2/14/92 (Changed 7/ 1/92 cbh to draw border in menu 
	; buttons.)   (Removed again.  Sometimes my ideas aren't too bright.  
	; -cbh 12/ 8/92) 
	;
if (0)	; We always want to draw borders around triggers. (4/28/94 - Joon)
	call	ShouldButtonNotDrawBorder
	jc	afterBorder		;not drawing border, branch
endif

if _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING
	;
	;  If it's in a menu and bordered, we need to invert
	;  it -- but we have to wait until after the moniker
	;  is drawn.  So for now do nothing.
	;
	test	bx, mask OLBSS_IN_MENU
	jz	notMenuItem
	test	bx, mask OLBSS_BORDERED
	jnz	doneBorder		; bordered menu item -- skip draw
notMenuItem:
	push	bp
	mov	bp, regionTable.offset
	call	DrawBWButtonBorder
	pop	bp
doneBorder:
	clc				;border is normal
else	; not _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING
	push	bp
	mov	bp, regionTable.offset
	call	DrawBWButtonBorder	;draw border region
	pop	bp
	clc				;border is normal
endif	; _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING

if	_BLACK_NORMAL_BUTTON
	;
	;	If this is a normally black disabled button, reset
	;	mask to 100% so that text will be drawn without mask.
	;	
	call	CheckForConditionsOfBlackNormalButton
	jnc	afterBorder
	;	If it is a black button, restore mask.
	mov	al, SDM_100
	call	GrSetTextMask
	call	GrSetLineMask
	call	GrSetAreaMask
endif	; _BLACK_NORMAL_BUTTON	

endif	

afterBorder:
	;
	; Carry set if we're nuking the border and the arrows.
	;
	pushf

	mov	ax, C_BLACK		 ;default: C_BLACK text
if USE_COLOR_FOR_DISABLED_GADGETS
	push	bx
	mov	bx, ss:optFlags
	test	bh, mask VA_FULLY_ENABLED	
	pop	bx
	jnz	20$			;skip if fully enabled...
	mov	ax, DISABLED_COLOR
20$:
endif

PMAN <	test	bx, mask OLBSS_IN_MENU_BAR	; buttons in menus are	>
PMAN <	jnz	notDepressed		 	; never inverted	>
PMAN <	test	bx, mask OLBSS_IN_MENU					>
PMAN <	jnz	notDepressed						>

	test	bx, mask OLBSS_DEPRESSED ;is button depressed?
	jz	notDepressed		 ;skip if not depressed...

	push	bp				; locals
	mov	bp, regionTable.offset		; ds:bp = region table
	call	DrawBWButtonDepressedInterior	; draw C_BLACK interior, set
if _RUDY
	mov	ax, SELECTED_TEXT_FOREGROUND
else
	mov	ax, C_WHITE			; use C_WHITE text
endif
	pop	bp				; locals

notDepressed:
if	_BLACK_NORMAL_BUTTON
	;
	;	If conditions are satisfied for the normally black
	;	button, draw everything inside the button in white.
	;
	call	BWButtonInvertColorIfNeeded
endif	; _BLACK_NORMAL_BUTTON

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	call	DecreaseSizeIfDrawingShadow	; if we have a shadow, decrease
						;  effective button size so 
						;  stuff centers properly. 
endif

	call	AdjustCurPosIfReplyPopup	; change curPos if there's
						;  reply bar space, for the
						;  arrow's benefit.

	call	GrSetTextColor			; set color for moniker -
	call	GrSetAreaColor			; no matter what it is
	call	GrSetLineColor

	;
	; if button has a mark then draw it (don't draw menu down marks if
	; toolbox and keyboard-only. -cbh 12/ 8/92)
	;
	popf				;drawing outline and mark?
	jc	afterMark		;nope, branch

if _JEDIMOTIF
	mov	si, ss:[thisObject]	; *es:si = instance data
	mov	si, es:[si]
	add	si, es:[si].Vis_offset
	mov	ax, es:[si].VI_bounds.R_left
	mov	bx, es:[si].VI_bounds.R_top
	inc	bx			; should really center the mark
	inc	bx			; independent of the moniker height,
	inc	bx			; but we hack it for now...
	movdw	drawPos, axbx
	mov	ax, optFlags
	mov	bx, specState
endif

if (not NO_MENU_MARKS)
	call	DrawBWButtonMenuMark	;moved from just under notDepressed
					;  12/ 8/92 cbh
endif

afterMark:

NOT_MO< call	DrawBWButtonCheckMark	;if setting in menu, draw checkmark >

	mov	ax, optFlags
	mov	al, ah
	mov	si, ax			;set si = VI_attrs

OLS <	mov	ax, C_BW_GREY		;pass color to use if disabled	>
CUA <	mov	ax, C_BLACK		;pass color to use if disabled	>
MO <	mov	ax, C_BW_GREY		;pass color to use if disabled	>
PMAN <	mov	ax, C_BW_GREY		;pass color to use if disabled	>
if USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, DISABLED_COLOR
endif

if (not _PM)
if _BLACK_NORMAL_BUTTON
	;
	;	Need to pass in *es:dx (object) to OLButtonSetMonoBitmapColor
	;	if _BLACK_NORMAL_BUTTON is true.
	;
	mov	dx, ss:[thisObject]		; *es:dx = object
endif ;_BLACK_NORMAL_BUTTON
	call	OLButtonSetMonoBitmapColor ;set Area color in case bitmap
endif					;does not trash bx, bp
	;
	; set up some arguments for the draw routine
	;
	mov	si, regionTable.offset
	mov	dl, ds:[si].BWBRSS_monikerXInset ;X inset value
	mov	dh, ds:[si].BWBRSS_monikerYInset ;Y inset value
if _PCV
	push	ss:[usesGraphic]
	popf
	jnc	textMoniker
	mov	dl, ds:[si].BWBRSS_graphicXInset
	mov	dh, ds:[si].BWBRSS_graphicXInset
textMoniker:
endif	; PCV
	call	OpenCheckIfCGA			 ;check if CGA
	jnc	28$				 ;it's not, branch
	mov	dh, ds:[si].BWBRSS_monikerYInsetCGA
28$:
	call	OpenCheckIfNarrow		 ;check if narrow
	jnc	285$				 ;it's not, branch
	mov	dl, ds:[si].BWBRSS_monikerXInsetNarrow
285$:
	mov	al, ds:[si].BWBRSS_monikerFlags	; get DrawMonikerFlags

	segmov	ds, es, si
	mov	si, ss:thisObject		; *ds:si = object
	
	;
	;  Do funky things if we're in a toolbox.
	;
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	29$
	mov	dx, (BUTTON_TOOLBOX_Y_INSET shl 8) or BUTTON_TOOLBOX_X_INSET

if	(BUTTON_BW_TOOLBOX_X_INSET ne BUTTON_TOOLBOX_X_INSET)
	call	OpenCheckIfBW			;color, done
	jnc	29$
	mov	dx, (BUTTON_BW_TOOLBOX_Y_INSET shl 8) or \
		    BUTTON_BW_TOOLBOX_X_INSET
endif

29$:
	mov	si, ss:thisObject		; *ds:si = object

;-----------------------------------------------------------------
;NOTE: DrawBWButton has a hack to push text up 4 pixels in buttons

	sub	dh, 4				;may go negative!
	jnc	30$

	clr	dh
30$:
	push	ax
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData
	pop	ax
	jnc	31$
	mov	dl, 1			;hack for BW title bar buttons
31$:
if _JEDIMOTIF
	push	ax
	mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
	call	ObjVarFindData
	pop	ax
	jnc	32$
	mov	dl, 1			;similiar hack for App menu button
32$:
endif
;-----------------------------------------------------------------

if _JEDIMOTIF
	;
	; if we have HINT_FIXED_SIZE, then return no extra size to allow
	; the hint full control of the size
	;
	push	ax
	mov	ax, HINT_FIXED_SIZE
	call	ObjVarFindData
	jnc	notFixed
	cmp	{SpecWidth}ds:[bx], 0
	je	leaveWidth
	clr	dl
leaveWidth:
	cmp	{SpecHeight}ds:[bx][(size SpecWidth)], 0
	je	leaveHeight
	clr	dh
leaveHeight:
notFixed:
	pop	ax
endif

	mov	cx, ss:optFlags		; set cl = OLBI_optFlags

	;determine which accessories to draw with moniker

	push	ax			; save DrawMonikerFlags
	mov	al, cl

;	clr	al			;pass flag to OLButtonSetupMonikerAttrs:
;					;if not cursored, no need to erase
;					;cursor image

	call	OLButtonSetupMonikerAttrs
					;pass info indicating which accessories
					;to draw with moniker.
					;Returns cx = OLMonikerAttrs
if _JEDIMOTIF
	;
	; always draw tight fitting cursor in Jedi
	;
	ornf	cx, mask OLMA_DRAW_CURSOR_INSIDE_BOUNDS
endif

	pop	ax			;pass al = DrawMonikerFlags,
					;cx = OLMonikerAttrs

if _JEDIMOTIF
	;
	; to match some code above, where if the cursored state wasn't the
	; only state to change, we will redraw the whole button, we want to
	; clear the OLMA_DISP_SELECTION_CURSOR bit set in
	; OLButtonSetupMonikerAttrs if we aren't cursored and if the cursored
	; state wasn't the only state to change
	;	(on stack) = redraw flag
	;
	popf
	jnc	noClear				;didn't redraw
	test	specState, mask OLBSS_CURSORED
	jnz	noClear				;is cursored, leave alone
						;else, clear flag
	andnf	cx, not mask OLMA_DISP_SELECTION_CURSOR
noClear:
endif

	push	bp				; locals
	call	OLButtonDrawMoniker		; draw moniker
	pop	bp				; locals
	;
	;  OK, now's the time to invert the moniker if we're
	;  bordered...
	;
if _MENU_BUTTONS_SHOW_FOCUS_BY_INVERTING
	;
	;  If it's in a menu and bordered, we need to invert
	;  it -- but we have to wait until after the moniker
	;  is drawn.  So for now do nothing.
	;
	mov	bx, ss:specState
	test	bx, mask OLBSS_IN_MENU
	jz	notMenuItem2
	test	bx, mask OLBSS_BORDERED
	jz	notMenuItem2			; not precisely true, but...

	call	OLButtonMovePenCalcSize		; cx, dx = width, height
	push	bp
	mov	ds, regionTable.segment
	mov	bp, regionTable.offset		; can we use lds here?
	mov	si, ds:[bp].BWBRSS_interiorPtr
	call	GrGetMixMode			; save current mix mode
	push	ax
	mov	ax, MM_INVERT
	call	GrSetMixMode
	call	DrawBWRegionAtCP		; Intervert le bouton!
	pop	ax
	call	GrSetMixMode			; restore mix mode
	pop	bp				; locals
notMenuItem2:
endif
	mov	al, SDM_100			; restore draw mask,
	call	GrSetTextMask			; in case we were 50%
	call	GrSetAreaMask
	call	GrSetLineMask

	.leave
	ret
ReDrawBWButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BWButtonInvertColorIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If _BLACK_NORMAL_BUTTON, check for conditions and see
		if need to change color. If yes, change to white if incoming
		color is black, switch to black if the incoming color 
		is white.

CALLED BY:	ReDrawBWButton
PASS:		*es:si	= OLButtonClass object
		bx	= OLBI_specState
		ax	= color
RETURN:		carry set if color is changed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
OLBI_moreAttrs	OLButtonMoreAttrs		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VL	7/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_BLACK_NORMAL_BUTTON ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BWButtonInvertColorIfNeeded	proc	far

EC <	Assert	objectPtr, essi, OLButtonClass>
	;
	;	Don't change color if it is neither black nor white.
	;
	cmp	ax, C_BLACK
	je	continueCheck
	cmp	ax, C_WHITE
	jne	exit

continueCheck:	
	call	CheckForConditionsOfBlackNormalButton
	jnc	exit		; doesn't need to change color if
				; carry is clear.
	;
	;	Invert the color.
	;	
CheckHack <C_BLACK eq 0 and C_WHITE eq 15>
	xor	al, 0fh
	stc

exit:
	ret
BWButtonInvertColorIfNeeded	endp
endif	; _BLACK_NORMAL_BUTTON


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForConditionsOfBlackNormalButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for conditions and see if button needed to be
		changed if _BLACK_NORMAL_BUTTON is true.

CALLED BY:	BWButtonInvertColorIfNeeded
		ReDrawBWButton
PASS:		*es:si	= OLButtonClass object
		bx	= OLBI_specState
RETURN:		carry set if button needed to be changed
		carry clear otherwise.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VL	7/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_BLACK_NORMAL_BUTTON ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckForConditionsOfBlackNormalButton	proc	near

EC <	Assert	objectPtr, essi, OLButtonClass>
	;
	;	Don't change if it is in a menu or is a system icon
	;	or border is not set.
	;
	test	bx, mask OLBSS_BORDERED
	jz	exit
	test	bx, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR or \
		    mask OLBSS_MENU_DOWN_MARK or mask OLBSS_MENU_RIGHT_MARK \
		    or mask OLBSS_SYS_ICON
	jnz	exit

	;
	;	Don't change if it is in ToolBox.
	;
	push	di
	mov	di, es:[si]
	add	di, es:[di].Vis_offset
	test	es:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	di
	jnz	exit

	stc
exit:
	ret
CheckForConditionsOfBlackNormalButton	endp
endif	; _BLACK_NORMAL_BUTTON


COMMENT @----------------------------------------------------------------------

ROUTINE:	DecreaseSizeIfDrawingShadow

SYNOPSIS:	Decreases the button size if we're drawing a shadow,
		so stuff will be centered properly.

CALLED BY:	ReDrawBWButton

PASS:		*es:si -- button
		cx, dx -- size

RETURN:		cx, dx -- possibly updated

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 8/93       	Initial version

------------------------------------------------------------------------------@
if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY

DecreaseSizeIfDrawingShadow	proc	near
	;
	; If we're doing shadows on the border, let's decrement the size
	; so everything draws within the real "border."   -cbh 2/19/93
	;
	push	di				;not in menu bar, exit
	mov	di, es:[si]			
	add	di, es:[di].Vis_offset
	test	es:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
					mask OLBSS_IN_MENU_BAR
	jnz	noShadow
	test	es:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	noShadow
	dec	cx
	dec	dx
noShadow:
	pop	di
	ret
DecreaseSizeIfDrawingShadow	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWButtonBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure clears the background for a button, when
		a MSG_VIS_DRAW is received.

CALLED BY:	DrawBWButton

PASS:		ax = color to clear background to
		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table (in idata) (we do use DS here)
		*es:si	= object

RETURN:		bx, cx, dx, di, ds, bp = SAME

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		cleanup
	chris	7/24/91		updated for new bounds conventions
	JimG	4/94		Added Stylus stuff for rounded top corners and
				for non-rectangular "background" region.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBWButtonBackground	proc	near
	class	OLButtonClass
	
	; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	; CAUTION! - Do not change the order of items on the stack.
	; There is a hack below which depends on bp being where it is.
	; Search for the word "HACK" to find this code.
	; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	
	push	bx, cx, dx	;save width and height
	push	bp		;save region ptr in a SPECIFIC
				;POSITION on the stack

CUAS <	mov	bp, bx							>
	call	GrSetAreaColor

	call	GrGetCurPos		;(ax, bx) = pen position
	push	ax, bx			;save pen position

	add	cx, ax			;(cx, dx) = lower-right corner of button
	add	dx, bx
;	dec	cx			;removed for new bounds conventions
;	dec	dx

if _CUA_STYLE	;---------------------------------------------------------------
	test	bp, mask OLBSS_SYS_ICON	;is this a system icon?
	jz	40$			;skip if not...

	dec	dx			;don't draw bottom line
	jmp	short 50$

40$:
if _CUA_STYLE and (not _MOTIF)	;----------------------------------------------
	test	bp, mask OLBSS_IN_MENU_BAR
	jz	45$

	;CUA/PM: since menu buttons are the full size of the menu bar,
	;and the menu bar overlaps the title area, don't erase the outer
	;edge of the button.

;	inc	ax		;DO erase the left edge
	inc	bx
;	dec	cx		;DO erase the right edge
	dec	dx
endif				;----------------------------------------------

45$:
	test	bp, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR
	jz	50$			;skip if regular button...

	;menu item or menu button: BLUE BG, regular bounds
	;CUA/Motif: grab color value from color scheme variables in idata
	;this is a menu button or icon. WE KNOW THAT DS = idata.

	push	ax
	clr	ah
	mov	al, ds:[moCS_menuBar]	;use same interior color as BG of menu
	call	GrSetAreaColor
	pop	ax
50$:
endif		;CUA_STYLE -----------------------------------------------------

	;	
	; If we're a regular button, and we're in keyboard only mode, don't
	; erase the very edge of the button, since there's nothing there and
	; in B/W there's the possibility that the area is being shared with a
	; possibly bordered object right next to us.  -cbh 1/22/93  (A 
	; specific case of this problem was the trigger next to the geoCalc
	; data entry text object.)
	;
	call	ShouldButtonNotDrawBorder
	jnc	60$			;draws border, branch
	inc	ax			;leave border alone, there isn't one
	inc	bx		
	dec	cx
	dec	dx
60$:

	;(ax, bx, cx, dx) = bounds. Color has been set

if _ROUND_THICK_DIALOGS
	;Check to see if this button should have a rounded top corner
	;because it is in the title bar on the left or right edge.
	
	push	si
	call	ShouldDrawRoundedTopCorner
	jnc	dontDrawButtonWithRoundedTopCorner
	inc	dx			;Need to draw region 1 pixel taller
					;since region is also used as interior??
	call	DrawBWRegion
	pop	si
	jmp	afterDraw

dontDrawButtonWithRoundedTopCorner:
	pop	si			;not popped above
endif ;_ROUND_THICK_DIALOGS

if _ROUND_NORMAL_BW_BUTTONS
	; Check if this should draw with a region instead of a rectangle.
	
	; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	; HACK - retrieve value of the passed bp (the pointer to the
	; current region set) from the stack.  This depends upon the
	; order of the pushes at the beginning of this routine.
	; Please BE CAREFUL.
	; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
	
	mov	bp, sp
	mov	bp, ss:[bp+4]		;Third word on stack.
	
	tst	ds:[bp].BWBRSS_backgroundPtr
	jz	dontDrawBackgroundWithRegion
	
	push	si
	mov	si, ds:[bp].BWBRSS_backgroundPtr
	call	DrawBWRegion
	pop	si
	jmp	afterDraw
	
dontDrawBackgroundWithRegion:
endif ;_ROUND_NORMAL_BW_BUTTONS

	call	GrFillRect		;draw background rectangle

if _ROUND_THICK_DIALOGS or _ROUND_NORMAL_BW_BUTTONS
afterDraw:
endif ;_ROUND_THICK_DIALOGS or _ROUND_NORMAL_BW_BUTTONS

	pop	ax, bx
	call	GrMoveTo		;restore pen position to top-left

	pop	bp			;restore region ptr
	pop	bx, cx, dx		;get width and height again
	ret
DrawBWButtonBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShouldDrawRoundedTopCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the button should draw background with
		a rounded corner.  If so, returns region to use.

CALLED BY:	UpdateBWButtonDepressed, DrawBWButtonBackground
PASS:		*es:si	= object

RETURN:		carry	= set if should draw with a rounded top corner
		si	= if carry set
		    	    Region to draw (cs:si = ptr to region)
			  if carry clear
			    Unchanged			    
			    
DESTROYED:	none

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	If we are asked for round thick dialogs, then we need to
	make sure that this button doesn't have a "rounded top corner"
	which means that the button is in the title bar and is on
	either end - thus it has to have a rounded corner.
	If this is the case, then a region needs to be drawn, not a
	rectangle.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_ROUND_THICK_DIALOGS

ShouldDrawRoundedTopCorner	proc	near
	uses	ds,ax,bx,di
	.enter
	
	mov	di, es:[si]
	add	di, es:[di].Vis_offset
	test	es:[di].OLBI_optFlags, mask OLBOF_HAS_ROUNDED_TOP_CORNER
	jz	done					; carry clear
	
	; Use a region, not a rectangle
	; Look for left corner attribute
	segmov	ds, es, ax
	mov	ax, ATTR_OL_BUTTON_ROUNDED_TOP_LEFT_CORNER
	call	ObjVarFindData				; modifies ds, bx
	
	; Assume right corner is special
	mov	si, offset STBWButton_titleRightInterior
	jnc	rightCorner
	
	; Was left corner.
	mov	si, offset STBWButton_titleLeftInterior

rightCorner:
	stc
done:
	.leave
	ret
ShouldDrawRoundedTopCorner	endp

endif	;_ROUND_THICK_DIALOGS



COMMENT @----------------------------------------------------------------------

ROUTINE:	ShouldButtonNotDrawBorder

SYNOPSIS:	Figures out whether this button should draw its border.

CALLED BY:	ReDrawBWButton, DrawBWButtonBackground

PASS:		*es:si -- button

RETURN:		carry set if button should not draw its border.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/22/93       	Initial version

------------------------------------------------------------------------------@

ShouldButtonNotDrawBorder	proc	near
	push	ax
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	pop	ax
	jz	exit				;not keyboard only, exit (c=0)
	push	si
	mov	si, es:[si]			
	add	si, es:[si].Vis_offset
	test	es:[si].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	si
	jz	exit				;not in toolbox, exit
	stc					;else don't draw border.
exit:
	ret
ShouldButtonNotDrawBorder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWButtonBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure draws a portion of a button, when
		a MSG_VIS_DRAW is received.

CALLED BY:	DrawBWButton

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table
		*es:si = OLButton

RETURN:		bx, di, ds:bp = SAME
		cx, dx - maybe updated

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		cleanup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DRAW_BUTTON_BORDERS

DrawBWButtonBorder	proc	near
	class	OLButtonClass
	push	bx, cx, dx, ds, bp	;SAVE BYTES
	
	push	si

	test	bx, mask OLBSS_BORDERED
	jz	done			;skip if not bordered...

OLS <	mov	ax, C_BLACK						>
OLS <	call	GrSetAreaColor						>

	;CUA/Motif: grab color value from color scheme variables in idata
	;WE KNOW THAT DS = IDATA

;not	clr	ah
;used	mov	al, ds:[moCS_iconFG]

if	 _WINDOW_CLOSE_BUTTON_IS_BIG_X
	; Check if this is the close button
	push	ds
	segmov	ds, es
	mov	ax, HINT_CLOSE_BUTTON
	call	ObjVarFindData
	pop	ds
	
	mov	si, offset STBWButton_closeButtonBorder
	jc	drawDaButton		; if so, draw the special border
endif	;_WINDOW_CLOSE_BUTTON_IS_BIG_X
	
	mov	si, ds:[bp].BWBRSS_borderPtr ;point to region definition

	tst	si
	jz	done			;skip if none...

drawDaButton::				; conditional

if _DRAW_DISABLED_BUTTONS_WITH_SOLID_BORDER
	mov	al, GMT_ENUM
	call	GrGetAreaMask
	push	ax
	mov	al, SDM_100
	call	GrSetAreaMask
endif
	
	call	DrawBWRegionAtCP

if _DRAW_DISABLED_BUTTONS_WITH_SOLID_BORDER
	pop	ax
	call	GrSetAreaMask
endif

;	Not needed if inverting B/W menu bar buttons.  -cbh 3/11/93
;	pop	si
;MO <	call	DrawTopBottomLinesIfNeeded				>
;	push	si			;push to match pop below
done:
	pop	si

	pop	bx, cx, dx, ds, bp
	ret
DrawBWButtonBorder	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWButtonDepressedInterior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the interior portion of the button.

CALLED BY:	DrawBWButton, ItemDrawBWItemDepressedIfInMenu

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table
		*es:si = object

RETURN:		bx, cx, dx, di, ds, bp = SAME

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		cleanup
	VL	7/7/95		Check to see if need to invert color
				in _BLACK_NORMAL_BUTTON.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBWButtonDepressedInterior	proc	near
	class	OLButtonClass
	
	push	bx, cx, dx, bp			;SAVE BYTES
if _RUDY
	;
	; In menus, invert the background; otherwise don't bother (parent
	; interaction is generally inverted instead).
	;
	call	CheckIfInMenu
	mov	ax, UNSELECTED_TEXT_BACKGROUND
	jnc	setColor
	mov	ax, SELECTED_TEXT_BACKGROUND
setColor:
else
	mov	ax, C_BLACK			;depressed means C_BLACK
endif

if	_BLACK_NORMAL_BUTTON
	;
	;	If this is a normally black button, depressed means C_WHITE.
	;				
	call	BWButtonInvertColorIfNeeded
endif	; _BLACK_NORMAL_BUTTON

if _CUA_STYLE	;---------------------------------------------------------------
	;CUA: see if C_BLACK is not appropriate for this button

	test	bx, mask OLBSS_IN_MENU_BAR or mask OLBSS_IN_MENU
	jz	10$				;skip if not in menu/bar...

	;CUA/Motif: grab color value from color scheme variables in idata
	;WE KNOW THAT DS = IDATA

	clr	ah
	mov	al, ds:[moCS_menuSelection]
10$:
endif		;---------------------------------------------------------------
	call	GrSetAreaColor

if	_BLACK_NORMAL_BUTTON
	push	si			; Need to save si for calling 
					; BWButtonInvertColorIfNeeded
endif	; _BLACK_NORMAL_BUTTON
	mov	si, ds:[bp].BWBRSS_interiorPtr
	call	DrawBWRegionAtCP
if	_BLACK_NORMAL_BUTTON
	pop	si
endif	; _BLACK_NORMAL_BUTTON
	pop	bx, cx, dx, bp

	mov	ax, C_BLACK
if	_BLACK_NORMAL_BUTTON
	;
	;	Need to set area color to white for depressed button's
	;	backgroud if it is a normally black button.
	;
	call	BWButtonInvertColorIfNeeded
endif	; _BLACK_NORMAL_BUTTON
	call	GrSetAreaColor
	ret
DrawBWButtonDepressedInterior	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWButtonMenuMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure draws a portion of a button, when
		a MSG_VIS_DRAW is received.

CALLED BY:	DrawBWButton

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ss:bp = caller's stack frame

RETURN:		bx, cx, dx, di, ds, bp = same

DESTROYED:	ax, si

PSEUDO-CODE/STRATEGY:

	Under Jedi, we have to draw right-marks to the left of
	the moniker.  Otherwise it's the same as for Motif, etc.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	Eric	2/90		Cleanup
	stevey	8/94		rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not NO_MENU_MARKS)

DrawBWButtonMenuMark	proc	near
	class	OLButtonClass
	uses	ds, bx, cx, dx, bp
	;
	;  Do this here for speed, since everybody and their uncle
	;  calls this routine when drawing.
	;
	test	bx, mask OLBSS_MENU_DOWN_MARK or mask OLBSS_MENU_RIGHT_MARK 
	jz	exit				;skip if no mark...	    
if _JEDIMOTIF
	;
	; if OLBSS_MENU_DOWN_MARK and OLBSS_IN_MENU_BAR, use app menu icon
	; and draw later in OpenDrawMoniker
	; (assumes OLBSS_IN_MENU_BAR won't be set with OLBSS_MENU_RIGHT_MARK)
	;
	test	bx, mask OLBSS_IN_MENU_BAR
	jnz	exit
endif

	;
	;  Inherit caller's stack frame, so we can still
	;  get at the goodies after we've trashed all our
	;  registers...
	;
	.enter	inherit ReDrawBWButton
	
	mov	si, offset MenuDownMarkBitmap	; assume menu down mark
	test	bx, mask OLBSS_MENU_DOWN_MARK				    
	jnz	10$							    

	mov	si, offset MenuRightMarkBitmap	; use menu right mark
10$:								    
	call	GrGetCurPos			; (ax, bx) = CurPos
	
if	 _POPUP_MARK_DRAWN_IN_REVERSE_VIDEO
	push	ax, bx, cx, dx			; save coords & size for
						; rectangle to reverse image
endif	;_POPUP_MARK_DRAWN_IN_REVERSE_VIDEO

	test	ss:specState, mask OLBSS_MENU_DOWN_MARK
	jz	15$				; no, branch

if	 _POPUP_MARK_DRAWN_IN_REVERSE_VIDEO
	; When drawing the mark in reverse video, move it over a little more
	; so that the text appears centered.  This wired-in numerical
	; constant is not used anywhere else, so I didn't make it a constant
	; in cConstant.def. --JimG
	add	ax, OL_EXTRA_DOWN_MARK_SPACING + 2
	
else	;_POPUP_MARK_DRAWN_IN_REVERSE_VIDEO is FALSE
	add	ax, OL_EXTRA_DOWN_MARK_SPACING
endif	;_POPUP_MARK_DRAWN_IN_REVERSE_VIDEO

15$:
if _JEDIMOTIF	;--------------------------------------------------------------
	test	ss:specState, mask OLBSS_MENU_RIGHT_MARK
	jz	notRightMark
	;
	;  For right-marks, we draw on the left side.
	;
	movdw	axbx, drawPos
	jmp	drawBitmap	
notRightMark:
endif	; _JEDIMOTIF ----------------------------------------------------------

	sub	dx, OL_MARK_HEIGHT		; compute extra in Y
	shr	dx, 1
	add	bx, dx				; now centered in Y

	add	ax, cx
	sub	ax, OL_MARK_WIDTH + BUTTON_INSET_X
	movdw	drawPos, axbx

drawBitmap::
	;
	;  Draw the bitmap
	;
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	push	bx				; save resource handle  >

NOFXIP<	segmov	ds, cs, dx						>

	movdw	axbx, drawPos
	clr	dx				; No callback routine.
	call	GrFillBitmap

FXIP <	pop	bx				; bx = resource handle	>
FXIP <	call	MemUnlock						>

if	 _POPUP_MARK_DRAWN_IN_REVERSE_VIDEO
	pop	ax, bx, cx, dx			; restore coords & size
	test	ss:[specState], mask OLBSS_MENU_DOWN_MARK
	jz	skipReverse
	
	push	bp
	
	push	ax
	call	GrGetMixMode
	mov_tr	bp, ax
	
	mov	al, MM_INVERT
	call	GrSetMixMode
	pop	ax
	
	; Calculate left and right edges
	add	cx, ax
	mov	ax, cx
	sub	ax, _REVERSE_RECTANGLE_OFFSET_FROM_RIGHT_EDGE

	; Calculate left and right edges
	add	dx, bx

	; Take border into account
	dec	dx				; 1-pixel border
	dec	cx
	inc	bx
if	 _THICK_DROP_MENU_BW_BUTTONS
	dec	dx				; 2-pixel border
	dec	cx
	inc	bx
endif	;_THICK_DROP_MENU_BW_BUTTONS

	call	GrFillRect
	
	; Restore mix mode.
	mov_tr	ax, bp
	call	GrSetMixMode
	
	pop	bp

skipReverse:	
endif	;_POPUP_MARK_DRAWN_IN_REVERSE_VIDEO

	.leave
exit:
	ret
DrawBWButtonMenuMark	endp

endif	; (not NO_MENU_MARKS)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBWButtonCheckMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure draws a portion of a button, when
		a MSG_VIS_DRAW is received.

CALLED BY:	DrawBWButton

PASS:		bx = OLBI_specState (what to draw)
		cx = button width
		dx = button height
		di = handle of graphics state
		ds:bp = region table

RETURN:		bx, cx, dx, di, ds, bp = same

DESTROYED:	ax, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	?	9/89		initial version
	Eric	2/90		cleanup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA or _MAC	;----------------------------------------------

DrawBWButtonCheckMark	proc	near
	push	ds, bx, cx, dx, bp	;SAVE BYTES

	mov	dx, bx			;get OLBI_specState
	ANDNF	dx, mask OLBSS_SETTING or mask OLBSS_IN_MENU or \
				mask OLBSS_SELECTED
	cmp	dx, mask OLBSS_SETTING or mask OLBSS_IN_MENU or \
				mask OLBSS_SELECTED
	jne	20$

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	mov	bp, bx				; bp = resource handle  >
FXIP <	pop	ax, bx							>
	
NOFXIP<	segmov	ds, cs							>

	mov	si, offset CUASMenuSettingCheckmarkBM
	clr	dx
	call	GrFillBitmapAtCP

FXIP <	mov	bx, bp				; bx = resource handle	>
FXIP <	call	MemUnlock						>

20$:
	pop	ds, bx, cx, dx, bp
	ret
DrawBWButtonCheckMark	endp

endif		;--------------------------------------------------------------

endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

DrawBW ends
