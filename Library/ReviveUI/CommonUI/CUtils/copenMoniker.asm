COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen
FILE:		copenMoniker.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/89		Initial version
	Eric	3/90		Expanded OpenMonikerArgs structure,
				made routines using it more consistent in
				terms of passed arguments. Added some EC
				to make sure stack is cool.

DESCRIPTION:
	This file contains utility routines for drawing monikers.  These 
	routines are basically front ends for VisDrawMoniker and
	VisGetMonikerSize which take care of various other work that you
	may need to do.  Some of the extra things OpenDrawMoniker handles:
	
		1.  It handles drawing "..." if the object leads to a
		    dialog box.
		2.  It leaves space for a menu mark if it brings up a menu.
		3.  It calculates the area to allow drawing to if your object
		    wants to clip its moniker.
		4.  It handles drawing of a keyboard shortcut, if there is one.
		5.  It will draw the selection cursor (dotted box) around the
		    object. The size of this box depends on the object type.
		    
	If you decide this is useful to you,  there are routines for calculating
	the size, center, and moniker position of the object as well.

	$Id: copenMoniker.asm,v 2.120 97/03/28 02:38:08 joon Exp $

------------------------------------------------------------------------------@

Utils segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDrawMoniker

SYNOPSIS:	Draws the visual and keyboard monikers, and other tidbits.
		For now, does NOT draw the window marks and assumes that
		one will not try to draw a window mark and a keyboard
		moniker simultaneously.  Also, if the object is to clip
		to the width of the object minus its insets.

CALLED BY:	utility

WARNING: usage of ds and es is inconsistent throughout these routines.
	 Pass es = ds to be safe. -eds

PASS:
	*ds:si - object which contains visible part to use (for positions)
	*es:bx - object which contains generic part to use (for moniker
			and keyboard moniker)
	ss:bp  - OpenMonikerArgs

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx		ACCURATE 3/90

PSEUDO CODE/STRATEGY:
	if centering in x direction	;force an inset amount.
		dl = dl + (GetSize(si) - OpenGetMonikerSize(si)) / 2
		monikerFlags = left_x
	VisDrawMoniker(si)
	if OLMA_DISP_WIN_MARK && moniker not gstring
		GrDrawText(winMark)
	if OLMA_DISP_SUBMENU_MARK
		monikerFlags = right_x
		GenDrawMoniker(subMenuMoniker)
	elif OLMA_DISP_KBD_MONIKER and kbdMoniker
		monikerFlags = right_x
		GenDrawMoniker(MonikerToString(kbdAccelerator));


KNOWN BUGS/SIDE EFFECTS/IDEAS:
      Expects moniker to be either left justified or center justified. Will
      probably cause problems if it is right justified or the caller wants
      no justification (the flag is not available).  Also assumes that any
      object that wants to draw a keyboard moniker has a Gen part.  That is,
      it's assumed that OLMenuButtons will not pass OLMA_DISP_KBD_MONIKER.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 8/89		Initial version
	Eric	3/90		More navigation work, lots of cleanup

------------------------------------------------------------------------------@
 
NPZ <WINDOW_DOT_TEXT_WIDTH	= 10					>
PZ <WINDOW_DOT_TEXT_WIDTH	= 24					>

OpenDrawVisMoniker proc far		;*ds:di is VisMoniker
	push	si, di
	jmp	startDraw
OpenDrawVisMoniker endp
	
	
OpenDrawMoniker	proc	far
	class	VisClass

	push	si, di 			;save object handle and ???

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	;make sure that es=ds
EC <	push	ds							>
EC <	push	es							>
EC <	pop	ax							>
EC <	pop	di							>
EC <	cmp	ax, di							>
EC <	ERROR_NZ OL_ERROR						>


	;make sure that if selection cursor info flags are passed, that we
	;have been asked to draw the selection cursor in the first place.

if ERROR_CHECK	;--------------------------------------------------------------
	mov	cx, ss:[bp].OMA_monikerAttrs

	;Motif: also check this flag.
MO <	test	cx, mask OLMA_DARK_COLOR_BACKGROUND			>
MO <	jnz	2$							>

PMAN <	test	cx, mask OLMA_DARK_COLOR_BACKGROUND			>
PMAN <	jnz	2$							>

	test	cx, mask OLMA_SELECTION_CURSOR_ON or \
		    mask OLMA_USE_LIST_SELECTION_CURSOR or \
		    mask OLMA_USE_CHECKBOX_SELECTION_CURSOR
	jz	5$			;skip if NO flags set...

2$:
	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	ERROR_Z OL_ERROR_BAD_OL_MONIKER_ATTRS
5$:
endif		;--------------------------------------------------------------

	;see if there is a VisMoniker

	mov	di, ds:[bx]
	add	di, ds:[di].Gen_offset	;ds:bx = GenInstance
	mov	di, ds:[di].GI_visMoniker
	tst	di
	LONG	jz exit			;skip if not...

startDraw	label	far	;*ds:di has VisMoniker
			
	;If we're centering the moniker, let's actually calculate an inset
	;and use that. Also set max width.

	push	di
	call	FixupCenteredMonikers	;make left justified
					;(updates ss:[bp].OMA_drawMonikerFlags)

	call	SetupMaxWidth		;setup maximum width
	pop	di			;set *ds:di = VisMoniker

	;draw the moniker
	;	*ds:si = visible object
	;	*ds:bx = generic object
	;	*ds:di = VisMoniker
	;	ss:bp = OpenMonikerArgs

	;
	; If this is in a menu, we'll draw any accelerator to the right, so
	; we can draw the moniker first.  But if this is not in a menu, we
	; want to draw the accelerator to the left, so we have to draw the
	; accelerator first.  If we are drawing the accelerator below, we can
	; draw the moniker first.
	;	*ds:si = visible object
	;	*ds:bx = generic object
	;	*ds:di = VisMoniker
	;	ss:bp = OpenMonikerArgs
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM or \
					mask OLMA_DRAW_SHORTCUT_BELOW or \
					mask OLMA_DRAW_SHORTCUT_TO_RIGHT
	jnz	drawMonikerFirst
	;
	; draw keyboard accelerator first
	;
	push	di			; save *ds:di = VisMoniker
	push	bx			; save *ds:bx = gen object
	call	OpenGetMonikerPos	; ax, bx = position to draw accelerator
	mov	cx, ax			; cx, bx = position
	pop	di			; *ds:di = gen object

if _USE_KBD_ACCELERATORS
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_KBD_MONIKER
	jz	afterKbdAccel		;skip if not...
	call	OpenDrawKbdAccelerator	; draw kbd accelerator
afterKbdAccel:
endif

	;
	; Before drawing the moniker, modify the leftInset so that it draws to
	; the right of the accelerator we've just drawn, with a little extra
	; space.  
	;	*ds:si = vis object
	;	*ds:di = gen object
	;	on stack: VisMoniker
	;
	pop	bx			; *ds:bx = VisMoniker
	push	di			; save *ds:di = gen object
	push	bx			; save *ds:bx = Vis Moniker
	mov	bx, di			; *ds:bx = gen object

	push	ss:[bp].OMA_monikerAttrs ;save real attributes
	and	ss:[bp].OMA_monikerAttrs, not (mask OLMA_DISP_DOWN_ARROW or \
					       mask OLMA_DISP_RT_ARROW)
	call	GetMonikerSizes		; dx = accel width (with space), without
					;    any arrows added in.
	pop	ss:[bp].OMA_monikerAttrs ;restore attributes

	add	ss:[bp].OMA_leftInset, dx
	pop	di			; *ds:di = VisMoniker
	pop	bx			; *ds:bx = gen object

drawMonikerFirst:
	push	bx			;save *ds:bx = gen object
	push	di			;save *ds:di = VisMoniker
	;
	; If drawing below, let's check if we need to center the moniker
	; (needed if kbd accelerator is wider than moniker).  If so, we
	; temporarily modify the leftInset.
	;	*ds:si = visible object
	;	*ds:bx = generic object
	;	*ds:di = VisMoniker
	;	ss:bp = OpenMonikerArgs
	;
	push	ss:[bp].OMA_leftInset	; in case we modify leftInset
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_BELOW
	jz	notBelow
	push	bx, di			; save gen object and moniker
	call	GetMonikerSizes		; cx = width of moniker (with insets)
					; dx = width of kbd accel (with space)
	cmp	cx, dx			; moniker wider?
	jae	leaveMkrPosAlone	; yes, leave alone
	mov	ax, dx			; else, adjust moniker position
	sub	ax, cx
	shr	ax, 1
	add	ss:[bp].OMA_leftInset, ax ; add in half the difference (centers)
leaveMkrPosAlone:
	pop	bx, di			; retreive gen object and moniker
notBelow:
	; ax = centering adjustment for moniker
	mov	bx, di			;pass *ds:bx = VisMoniker
	mov	cx, ss:[bp].OMA_drawMonikerFlags ;set cl = justification flags
if (not _JEDIMOTIF)	; DMF_UNDERLINE_ACCELERATOR set by caller in JEDI
CUAS <	ORNF	cl, mask DMF_UNDERLINE_ACCELERATOR			>
endif
	call	SpecDrawMoniker		;draw the moniker
					;(returns draw position in ax, bx)
	mov	ss:[bp].OMA_drawMonikerFlags, cx	
					;save flags returned (changes clip flag
					;  if clipping was really needed)
	pop	ss:[bp].OMA_leftInset	;restore leftInset
	pop	di			;get *ds:di = VisMoniker

	push	ax, bx, bp		;save draw position, stack ptr
	mov	bp, ss:[bp].OMA_gState	;pass gstate
	call	SpecGetMonikerSize	;get the size of the moniker (cx,dx)
	pop	ax, bx, bp
if _JEDIMOTIF	;-------------------------------------------------------------
	;
	; draw menu bar item menu mark, if needed
	;	(ax, bx) position moniker drawn at
	;	cx - moniker width
	;
	; note that we depend on DMF_UNDERLINE_ACCELERATOR to be *clear* for
	; menu bar buttons since OLMA_DISP_DOWN_ARROW is also set for popup
	; lists
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_DOWN_ARROW
	jz	noMenuMark
	test	ss:[bp].OMA_drawMonikerFlags, mask DMF_UNDERLINE_ACCELERATOR
	jnz	noMenuMark
	push	ax, bx, dx, di, si, ds
	add	ax, cx				; draw to right of moniker
	inc	ax				; moniker/mark spacing
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	bx, ds:[si].VI_bounds.R_bottom
	sub	bx, ds:[si].VI_bounds.R_top	; bx = object height
	sub	bx, OL_MARK_HEIGHT
	shr	bx, 1				; top offset needed to center
	add	bx, ds:[si].VI_bounds.R_top	; bx = Y position
	add	bx, 2				; mystery adjustment
	; check max X position to deal with long monikers that are clipped
	mov	dx, ds:[si].VI_bounds.R_right
	sub	dx, OL_MARK_WIDTH+2		; dx = max X position
	cmp	ax, dx
	jbe	XOkay
	mov	ax, dx				; else, use max X position
XOkay:
FXIP <	push	ax, bx				; save draw pos		>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx				; restore draw pos	>
NOFXIP<	segmov	ds, cs, dx						>
	mov	si, offset MenuAppMenuBitmap	; ds:si = menu mark bitmap
	clr	dx				; No callback routine.
	mov	di, ss:[bp].OMA_gState		; di = gstate
	call	GrFillBitmap
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
	pop	ax, bx, dx, di, si, ds
noMenuMark:
	;
	; JEDI: don't draw underline mnemonic if not told to
	;
	test	ss:[bp].OMA_drawMonikerFlags, mask DMF_UNDERLINE_ACCELERATOR
	jz	noUnderline
endif	;---------------------------------------------------------------------
	call	DrawMnemonicUnderline	;draw the underline
					;	(does nothing for gstring
					;	 moniker)
noUnderline::
	
	pop	di			;get *ds:di = gen object

checkForWinMark::
	;see if we must draw the window mark ("...")
	;	*ds:si = visible object
	;	*ds:di = generic object
	;	ax, bx = draw position (top left of moniker)
	;	cx, dx = (actual) moniker size (no accel, etc.)
	;	ss:bp = OpenMonikerArgs

CUAS <	push	ax, bx			;save top-left of moniker, may need >
					;below to draw a box.
	add	ax, cx			;set (ax, bx) = position to draw at

if DRAW_WINDOW_MARK_IN_MONIKERS		;skip win mark here

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_WIN_MARK
	jz	checkForCursored	;skip if not...

	push	ds, si, di, dx

if	DBCS_PCGEOS and _FXIP
	mov	cx, size winMark	;pass size of string, since we know it
else
	mov	cx, length winMark	;pass length of string, since we know it
endif
	segmov	ds, cs			;set ds:si = winMark text (null term.)
	mov	si, offset winMark
FXIP <	call	SysCopyToStackDSSI					>
	mov	di, ss:[bp].OMA_gState	;pass gstate
if	DBCS_PCGEOS and _FXIP
	shr	cx			; cx =  length of string, since we know it
endif
	call	GrDrawText		;draw it
FXIP <	call	SysRemoveFromStack					>
;NOTE: should use font info to get width
	add	ax, WINDOW_DOT_TEXT_WIDTH ;move right width of "..."

	pop	ds, si, di, dx
endif

checkForCursored:
	;	*ds:si = visible object
	;	*ds:di = generic object
	;	ss:bp  = OpenMonikerArgs
	;	ax, bx = top-right of moniker and "..."
	;	dx     = height of (actual) moniker (no accel, etc.)
	;stack:	ax, bx = draw position (top left of moniker)
	;	(only pushed in CUAS)

if _CUA_STYLE	;--------------------------------------------------------------
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_SELECTION_CURSOR
					;will we display the selection cursor?
	jz	10$			;skip if not...

	;this is ugly but necessary. No more registers!

	mov	cx, ax			;cx = right side of moniker
	add	dx, bx			;dx = bottom of moniker + 1
	dec	dx			;dx = bottom of moniker
	pop	ax, bx			;get top-left of moniker

	push	ax, dx			;save bottom-left

if DRAW_SELECTION_CURSOR_FOR_FOCUSED_GADGETS
	call	OpenDrawSelectionCursor	;draw/erase the cursor image
					;will return ax,bx = top-right of text 
endif

	pop	cx, dx			;retreive bottom-left

	jmp	short 20$

10$:	;do not draw or erase selection cursor
	pop	cx			;retreive top
	add	cx, dx			;cx = (bottom = top + height - 1)
	dec	cx
	mov	dx, cx			;dx = bottom
	pop	cx			;retrieve left
20$:
endif		;--------------------------------------------------------------

checkForKbdAccelerator::
	;	*ds:si = visible object
	;	*ds:di = generic object
	;	ax, bx = draw position (top right of moniker plus "...")
	;	cx, dx = bottom-left (draw position for DRAW_SHORTCUT_BELOW)
	;	ss:bp = OpenMonikerArgs

if _CUA_STYLE	;--------------------------------------------------------------
	;
	; If we've already drawn the accelerator to the left of the moniker,
	; we're done.
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM or \
						mask OLMA_DRAW_SHORTCUT_TO_RIGHT
	jnz	drawToRight		; menu item or right --> draw to right
					; (overrides draw-below)
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_BELOW
	jz	exit			; not menu or right, not below,
					;	already drawn

drawBelow::
	;
	; handle drawing kbd moniker below
	;
	push	dx, di			; save Y position (dx)
	push	cx			; save X position
	mov	bx, di			; es:bx = gen object
	push	bx
	call	GetMonikerSizes		; cx = width of moniker
					; dx = width of kbd accelerator
	pop	bx
	cmp	dx, cx			; kbd accelerator wider?
	jae	accelWider		; yes, branch
	mov	ax, cx			; else, adjust accel position
	sub	ax, dx
	shr	ax, 1
	pop	cx
	add	cx, ax			; add in half the difference (centers)
	push	cx
	jmp	short accelCommon

accelWider:
	call	OpenGetMonikerPos	; ax, bx = position
	add	ax, CLOSE_SHORTCUT_SPACING/2	; make X position adjustments
	add	ax, ss:[bp].OMA_leftInset
	pop	cx			; retrieve old X position
	push	ax			; use new X position
accelCommon:
	pop	cx			; get X position
	pop	bx, di			; retrieve Y position (bx)
	add	bx, CGA_BELOW_SHORTCUT_SPACING	; give it a little room (CGA)
	call	OpenCheckIfCGA
	jc	drawKbdAccel
	add	bx, (BELOW_SHORTCUT_SPACING - CGA_BELOW_SHORTCUT_SPACING)
	jmp	short drawKbdAccel

drawToRight:
	;
	; override passed Y position by centering kbd accel vertically
	; in object
	;	*ds:si = vis object instance data
	;	*ds:di = Gen object
	;	ax, bx = X, Y position
	;	cx, dx = bottom-left (draw position for DRAW_SHORTCUT_BELOW)
	;	ss:bp = OpenMonikerArgs
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = vis instance
	mov	bx, ds:[di].VI_bounds.R_bottom
	sub	bx, ds:[di].VI_bounds.R_top
	sub	bx, ss:[bp].OMA_textHeight
if _RUDY
	tst	bx			; avoid negative situations
	jns	heightOK
	clr	bx
heightOK:
endif
	shr	bx, 1			; /2
	add	bx, ds:[di].VI_bounds.R_top
	pop	di

	mov	cx, ax			;put position in cx

if NO_SPACE_BETWEEN_GSTRING_MONIKERS_AND_ACCELERATORS
	push	di			; save *ds:di = gen object
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_TO_RIGHT
	jz	addSpacing		; HACK: no space for draw-to-right
	mov	di, ds:[di]		;	gstring monikers
	add	di, ds:[di].Gen_offset	;	(doesn't include menu items)
	mov	di, ds:[di].GI_visMoniker
	tst	di
	jz	addSpacing		; no moniker, add spacing
	mov	di, ds:[di]		; deref moniker
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	afterSpacingTest	; gstring -> no spacing
addSpacing:
	add	cx, CLOSE_SHORTCUT_SPACING ;add a little spacing
afterSpacingTest:
	pop	di

else
	add	cx, CLOSE_SHORTCUT_SPACING ;add a little spacing
endif   ;NO_SPACE_BETWEEN_GSTRING_MONIKERS_AND_ACCELERATORS


drawKbdAccel:
if _USE_KBD_ACCELERATORS
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_KBD_MONIKER
	jz	exit			;skip if not...
	call	OpenDrawKbdAccelerator	;draw accelerator text at (cx, bx)
endif		;_USE_KBD_ACCELERATORS

endif		;CUA_STYLE

exit:
	pop	si, di
	ret
OpenDrawMoniker	endp

if DRAW_WINDOW_MARK_IN_MONIKERS
SBCS <winMark	char	"..."						>
DBCS <winMark	wchar	"..."						>
endif

if _JEDIMOTIF
if _FXIP
DrawBWRegions	segment resource
endif
MenuAppMenuBitmap	label	word
	word	OL_MARK_WIDTH		;width
	word	OL_MARK_HEIGHT		;height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	01111111b
	byte	01000001b
	byte	01011101b
	byte	01000001b
	byte	01011101b
	byte	01000001b
	byte	01111111b
	byte	00001111b
if _FXIP
DrawBWRegions	ends
endif
endif
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawMnemonicUnderline

SYNOPSIS:	Draws the underline, if any.  Also draws the mnemonic at
		the end of the moniker if it didn't appear in the moniker.

CALLED BY:	OpenDrawMoniker

PASS:		*ds:di -- VisMoniker
		ax, bx -- beginning draw position of vis moniker
		cx     -- width of vis moniker
		ss:bp  -- DrawMonikerArgs

RETURN:		cx     -- width of vis moniker, possibly updated if we had to
			  add a mnemonic in parentheses after the moniker.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/18/91		Initial version

------------------------------------------------------------------------------@

DrawMnemonicUnderlineFar	proc	far
	call	DrawMnemonicUnderline
	ret
DrawMnemonicUnderlineFar	endp

DrawMnemonicUnderline	proc	near	uses ax, bx, dx, di, bp, si, es
	.enter

if DRAW_MNEMONIC_UNDERLINES
	call	OpenCheckIfKeyboardNavigation	;if not providing kbd nav,
	LONG jnc	reallyExit		;	don't draw mnemonic
						;	underline
	push	cx				;save vis moniker width
	mov	dx, cx				;keep moniker width in dx
	segmov	es, ds				;es has segment of moniker
	mov	si, ds:[di]			;ds:si = visMoniker
	mov	cx, {word} ds:[si].VM_type	;get moniker type
	test	cx, mask VMT_GSTRING		;is a GString?
	mov	di, ss:[bp].DMA_gState		;(pass gstate)
	mov	bp, 0				;(assume gstring,no extra width)
	LONG	jnz exit			;exit if a gstring, no mnemonic

	add	si, VM_data + VMT_text		;point at the data
	;
	; Get the mnemonic for this moniker. si is pointing at the text.
	;
	mov	cl, ds:[si].VMT_mnemonicOffset-VMT_text
	
	;
	; If the moniker is not in the text, we'll have to do some special
	; stuff here.  We'll go to the end of the text so we're pointing
	; at the mnemonic (should be after the null byte).  We'll draw a space,
	; draw a '(', draw the mnemonic, draw the ')', and while pointing at
	; the mnemonic get the underline code to underline at offset 0.
	;
	cmp	cl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	10$
	
	xchg	di, si				;get to the mnemonic
	mov	cx, -1				
	add	dx, ax				;dx <- width of mkr + x pos
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	mov	ax, dx				;restore end of moniker
	xchg	si, di
	
	push	ax				;save current x position
	clr	dh
	mov	dl, ' '
	call	GrDrawChar
	mov	dl, '('
	call	GrDrawCharAtCP
	
	call	GrGetCurPos			;mnemonic; we'll use it for the
						;underline
	mov	dl, ds:[si]
	call	GrDrawCharAtCP
	mov	dl, ')'
	call	GrDrawCharAtCP
   	;
	; Calculate how much space we need to add to the moniker width for
	; all of this that we've done.
	;
   	push	ax				;save the pen pos to be used
						;  for the underline
	call	GrGetCurPos			
	mov	bp, ax				;put in cx for now
	pop	ax				;restore underline pen pos
   	pop	cx				;restore original pen pos
	sub	bp, cx				;calculate the extra amount
	clr	cx				;underline goes under first
	jmp	short doUnderline		;   character in ds:si
	
10$:
   	clr	bp				;no extra width
	cmp	cl, VMO_CANCEL			;anything to underline?
	je	exit				;no, branch
	cmp	cl, VMO_NO_MNEMONIC
	je	exit
	clr	ch				;clear high byte
EC <	call	CheckOffsetInLength		;verify that offset is in mkr >
   
doUnderline:
	;
	; Draw an underline.  ds:[si][cx] points to the character we're going
	; to underline.   
	;
	;	ax = X position
	;	bx = Y position
	;	ds:[si][cx] = mnemonic character
	;	bp = extra width for mnemonic
	;

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	;
	; if doing keyboard only mode, use highlight for mnemonic, instead of
	; underline
	;
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	useHighlight			; yes
endif	;----------------------------------------------------------------------

   	push	ax				;save x position
	
	push	si				;get offset to underline
	mov	si, GFMI_ROUNDED or GFMI_UNDER_POS
	call	GrFontMetrics
	pop	si
if _JEDIMOTIF
	;
	; Ugh...hack underline pos for JEDI to tighten things up
	;
	dec	dx
endif
	
	add	bx, dx				;add to y position
	clr	dx				;assume no char before underline
	tst	cx				;any chars before underline?
	jz	20$
	call	GrTextWidth			;get width of text before line
20$:
	add	ax, dx				;add to x position
	inc	cx				;move to next character
	call	GrTextWidth			;get width of text after line
	pop	cx				;restore x position
	add	cx, dx				;add width of text after line

	sub	cx, 2				;shorten underline some
	sub	cx, ax
	cmp	cx, MIN_UNDERLINE_WIDTH-1	;make sure at least 2 pixels
	jge	30$				;(changed from 1 pixel 12/20/92)
	mov	cx, MIN_UNDERLINE_WIDTH-1
30$:
	add	cx, ax

	call	GrDrawHLine			;draw a horizontal underline
;temporary measure to enhance mnemonic visibility
	call	OpenCheckIfCGA
	jc	noDoubleUnderline
	call	OpenCheckIfKeyboardOnly
	jnc	noDoubleUnderline
	inc	bx				;if not CGA, draw another one
						;	1 pixel down
	call	GrDrawHLine
noDoubleUnderline:

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	jmp	short exit

useHighlight:
	;
	; for keyboard only mode, use highlight for mnemonic
	;
	push	si				;get offset to highlight base
	mov	si, GFMI_ROUNDED or GFMI_UNDER_POS
	call	GrFontMetrics
	pop	si

	push	bp				; save extra width
	add	dx, bx				; bx = top, dx = bottom
	push	dx				; save bottom

	clr	dx				;assume no char before underline
	tst	cx				;any chars before underline?
	jz	40$
	call	GrTextWidth			;get width of text before line
40$:
	add	ax, dx				;add to x position
	push	ax				; save left
	call	GrGetMixMode			; al = current draw mode
	mov	bp, ax				; bp(low) = current draw mode 
	mov	al, MM_INVERT
	call	GrSetMixMode
	push	bx				; save top
	mov	bx, cx
SBCS <	clr	ah							>
SBCS <	mov	al, ds:[bx][si]			; al = mnemonic character >
DBCS <	mov	ax, ds:[bx][si]			; ax = mnemonic character >
	call	GrCharWidth			; dx.ah = width
	pop	bx				; restore top
	pop	ax				; restore left
	mov	cx, dx				; cx = right
	add	cx, ax
	pop	dx				; restore bottom
	call	GrFillRect
	mov	ax, bp
	call	GrSetMixMode
	pop	bp				; restore extra width
endif	;----------------------------------------------------------------------
	
exit:
	pop	cx				;restore vis moniker width
	add	cx, bp				;add any extra width
reallyExit:
endif	;DRAW_MNEMONIC_UNDERLINES

	.leave
	ret
DrawMnemonicUnderline	endp


if	ERROR_CHECK and DRAW_MNEMONIC_UNDERLINES

CheckOffsetInLength	proc	near		uses cx, ax, di
	.enter
	pushf
	push	cx
	mov	di, si
	mov	cx, -1				;get the length of the string
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	not	cx				;cx holds the length, plus null
	dec	cx
	pop	ax				;restore offset to underline
	cmp	ax, cx				;make sure within our length
	ERROR_AE OL_MNEMONIC_OFFSET_LARGER_THAN_MONIKER
	popf
	.leave
	ret
CheckOffsetInLength	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenDrawSelectionCursor

DESCRIPTION:	This routine draws or erases the selection cursor.

CALLED BY:	OpenDrawMoniker

PASS:		*ds:si	= instance data for object
		*ds:di = generic object
		ax, bx	= top-left of moniker
		cx, dx	= bottom-right of moniker
		ss:bp  = OpenMonikerArgs:

RETURN:		ds, si, di, bp = same
		ax, bx	= top-right of moniker and "..." text if any

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version
	sean	7/96		Odie selection box changes

------------------------------------------------------------------------------@

if DRAW_SELECTION_CURSOR_FOR_FOCUSED_GADGETS
if _CUA_STYLE	;--------------------------------------------------------------

OpenDrawSelectionCursor	proc	near

;
; PCV doesn't draw selection cursors, comment out the whole thing
;
if not _PCV

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	call	OpenCheckIfKeyboard		; no keyboard, don't draw.
	LONG jnc	done			;  (cbh 2/ 8/93)

	; If this is a selection box erasing the focus cursor, then
	; don't do anything.  Otherwise, a light grey focus cursor is drawn
	; over a white background when we lose the focus.
	;
if	SELECTION_BOX ;------------------------------------------------------
if (not CURSOR_OUTSIDE_BOUNDS)
	call	CheckIfSelectionBoxFar	; zero flag set
	jz	continue

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_LIGHT_COLOR_BACKGROUND
LONG	jnz	done			; yes--exit

continue:
endif
endif	; if SELECTION_BOX---------------------------------------------------

if _JEDIMOTIF
	;
	;  If this is a list item and we're erasing the focus cursor
	;  selection mark, just don't do anything.  Hopefully this
	;  won't dork other objects.
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_LIST_SELECTION_CURSOR
	jz	carryOnLad
	
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_SELECTION_CURSOR_ON
	LONG	jz	done

carryOnLad:
endif	; _JEDIMOTIF

	push	cx, bx, di, ds			; save top-right for return
						; (not top-left!)
	mov	di, ss:[bp].OMA_gState	;pass gstate

if ERROR_CHECK
	;make sure that the B&W and color info flags are mutually exclusive

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jz	1$

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DARK_COLOR_BACKGROUND or \
				       mask OLMA_LIGHT_COLOR_BACKGROUND
	ERROR_NZ OL_ERROR

1$:
endif

	;
	; Rewrote code here to do something better for clipped objects.
	; -cbh 11/23/92.  (Added a new flag to always draw inside bounds.
	; -cbh 12/ 8/92)
	;
	test	ss:[bp].OMA_monikerAttrs, \
			mask OLMA_DRAW_CURSOR_INSIDE_BOUNDS
	jnz	drawInsideBounds

	test	ss:[bp].OMA_monikerAttrs, \
			mask OLMA_USE_LIST_SELECTION_CURSOR or \
			mask OLMA_USE_CHECKBOX_SELECTION_CURSOR or \
			mask OLMA_USE_TOOLBOX_SELECTION_CURSOR
					;draw cursor according to bounds?
	jnz	useBoundsForRect	;branch if so

	test	ss:[bp].OMA_drawMonikerFlags, mask DMF_CLIP_TO_MAX_WIDTH
	jz	useTightFitCursor	;not forced to clip, use moniker bounds

drawInsideBounds:
	clr	cl
	call	OpenGetLineBounds

	;
	; For PM we need to shrink the selection rectangle a bit so it doesn't
	; extend over the little fake down arrow button.
	;
PMAN <	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_DOWN_ARROW	>
PMAN <	jz	haveLineBounds	   	       ;not doing arrows, branch>
PMAN <	sub	cx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING - 1		>
PMAN <haveLineBounds:							>

if _JEDIMOTIF
	;
	; I hate myself and want to die -- if default button, inset two pixels
	; so we don't overlap the double-width default ring
	;
	push	es, di
	mov	di, segment OLButtonClass
	mov	es, di
	mov	di, offset OLButtonClass
	call	ObjIsObjectInClass
	jnc	notDefault		;not default, carry clear
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jnz	insetTwo
	test	ds:[di].OLBI_specState, mask OLBSS_DEFAULT
	jz	notDefault		;not default, carry clear
insetTwo:
	stc				;indicate is default
notDefault:
	pop	es, di
	jc	insetTwoPixels		;is default, inset two pixels
endif

	call	OpenCheckIfCGA		;inset two pixels on non-CGA
	jnc	insetTwoPixels
	call	InsetRect		;inset one pixel in CGA

if	DRAW_SHADOWS_ON_BW_GADGETS
	dec	cx			;bump up from shadow a little. Shouldn't
	dec	dx			;  have to worry about the buttons that
					;  don't have shadows, as they either
					;  won't take the focus (toolbar) or
					;  won't be insetting from bounds.
endif
	jmp	short haveBounds
	
useBoundsForRect:

	;is scrolling list, toolbox, or checkbox object: draw box inside
	;bounds of object

	clr	cl
	call	OpenGetLineBounds

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_TOOLBOX_SELECTION_CURSOR
	jz	10$			;skip if not a toolbox...

	;is a toolbox: MUST invert image to draw it, because can have
	;color background.

	push	ax
	mov	ax, MM_INVERT
	call	GrSetMixMode
	pop	ax

	call	InsetRect
;MO <	dec	dx			;move bottom line up one	>
    					;whoever put this in must have been
					;  asleep at the wheel...
	jmp	short drawRect

10$:
if _ODIE	; always inset at least one pixels
	test	ss:[bp].OMA_monikerAttrs, \
			mask OLMA_USE_CHECKBOX_SELECTION_CURSOR
	jz	insetOnePixel		;one if not a checkbox...
else
	test	ss:[bp].OMA_monikerAttrs, \
			mask OLMA_USE_CHECKBOX_SELECTION_CURSOR
	jz	haveBounds		;skip if not a checkbox...
endif

insetTwoPixels:
	call	InsetRect
insetOnePixel::
	call	InsetRect
	jmp	short haveBounds

useTightFitCursor: ;is non-list object: draw box around moniker
if _JEDIMOTIF
	dec	ax			;one pixel to the left
	inc	cx			;one pixel to the right
					;nothing up
					;nothing down
else
MO <	sub	ax, 3			;HACK: push all bounds out 3 pixel >
PMAN <	sub	ax, 3			;HACK: push all bounds out 3 pixel >
NOT_MO <sub	ax, 2			;HACK: push all bounds out 1 pixel >
	inc	cx
MO <	inc	dx			;push bottom out, even on CGA 2/12/92 >
PMAN <	inc	dx			;push bottom out, even on CGA 2/12/92 >

;MO <	call	OpenCheckIfCGA						      >
;MO <	jc	haveBounds		;on CGA, don't expand selector out    >
;MO <	dec	bx			;push top and bottom out -cbh 7/24/90 >
					; (bottom push always happens 2/12/92)
;PMAN <	call	OpenCheckIfCGA						      >
;PMAN <	jc	haveBounds		;on CGA, don't expand selector out    >
;PMAN <	dec	bx			;push top and bottom out -cbh 7/24/90 >
					; (bottom push always happens 2/12/92)

	dec	bx			;have top push always happen, cursor is
					; cutting off top of help trigger
					; (cbh 3/ 9/93)
endif

haveBounds: ;(ax, bx, cx, dx) = bounds of rectangle to draw
	push	ax			;save left X coordinate

	mov	ax, idata		; have ds point to idata for
	mov	ds, ax			;  the remainder of this voyage

	;assume selection cursor is ON. Get color.

if _PM
	clr	ah
	mov	al, ds:[moCS_dsDarkColor] ;default draw color = darkColor
else
	mov	ax, C_BLACK		;default draw color = C_BLACK
endif

if CURSOR_ON_BACKGROUND_COLOR	;==============================================

	;
	; white background -> black cursor
	; light background -> black cursor
	; dark background -> white cursor
	; black background -> white cursor
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_LIGHT_COLOR_BACKGROUND
	jnz	useBlack
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DARK_COLOR_BACKGROUND or \
					mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jz	useBlack
useWhite::
	mov	ax, C_WHITE
useBlack:

else	;======================================================================

if _CUA_STYLE and (not _MOTIF) and (not _PM)	;------------------------------
;	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_LIST_SELECTION_CURSOR
;	jz	20$			;skip if not scroll list item...

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jz	20$			;skip if on C_WHITE background...

	mov	ax, C_WHITE		;draw C_WHITE dots on C_BLACK background
20$:
elseif _PM or _ODIE	;------------------------------------------------------
	;
	; As long as the background is dark, we use light color for the
	; selection rectangle.  JS 7/22/92
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DARK_COLOR_BACKGROUND or \
					  mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jz	useDarkColor

useLightColor:
	mov	al, ds:[moCS_dsLightColor]
useDarkColor:

else	; _MOTIF --------------------------------------------------------------
	;
	; Let's do this right.  Selection rectangle is white if one of the
	; funny background bits is set, OR the system has a non-white 
	; background.  -cbh 2/12/92
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DARK_COLOR_BACKGROUND or \
				       mask OLMA_LIGHT_COLOR_BACKGROUND or \
				       mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jnz	useWhite			

	cmp	ds:[moCS_dsLightColor], C_WHITE
	je	useBlack		;background is white, use black
useWhite:
if _JEDIMOTIF
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_LIST_SELECTION_CURSOR
	jnz	useBlack
endif
	mov	ax, C_WHITE		;else draw in C_WHITE 
useBlack:

endif	;----------------------------------------------------------------------

endif	;======================================================================

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_SELECTION_CURSOR_ON
	jnz	haveColor		;skip to draw cursor...


	;selection cursor is OFF. get color

if _CUA_STYLE and (not _MOTIF) and (not _PM)	;------------------------------
;	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_LIST_SELECTION_CURSOR
;	jz	60$			;skip if not list item...

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jz	60$			;skip if on C_WHITE background...

	mov	ax, C_BLACK		;draw C_BLACK dots on C_BLACK
	jmp	short haveColor		;skip with color...

60$:
else		;--------------------------------------------------------------
	;Motif/PM: if on black background, OFF means C_BLACK

	mov	ax, C_BLACK		;set draw color = C_BLACK
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_BLACK_MONOCHROME_BACKGROUND
	jnz	haveColor		;skip if on C_BLACK background...

	;Motif/PM: if on light background, OFF means C_LIGHT_GREY
	;(Changed  2/15/91  cbh to use real light color)

	clr	ax
	mov	al, ds:[moCS_dsLightColor]	;use light color
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_LIGHT_COLOR_BACKGROUND
	jnz	haveColor

	;Motif/PM: if on dark background, OFF means C_DARK_GREY
	mov	ax, C_DARK_GREY		;set draw color = C_DARK_GREY
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DARK_COLOR_BACKGROUND
	jnz	haveColor
endif		;--------------------------------------------------------------

	mov	ax, C_WHITE		;set draw color = C_WHITE

haveColor:
	call	GrSetLineColor
	pop	ax

drawRect:
	push	ax
if _ODIE	;------------------------------------------------------------
	;
	; use custom line mask for ODIE
	;
	call	OpenSetFocusPattern
else	;---------------------------------------------------------------------
if not SOLID_FOCUS_OUTLINE
	mov	al, SDM_50		;set for dotted line
else
	;
	;For SOLID_FOCUS_OUTLINE we'll use a solid line.   But first, we'll 
	;   also invert the pixels that are there, in the hopes that graphic 
	;   monikers show up better.   -cbh 12/19/93
	;
	push	ax
	mov	ax, MM_XOR
	call	GrSetMixMode
	pop	ax

	mov	al, SDM_0		;set for dotted line
endif
	call	GrSetLineMask
endif	;---------------------------------------------------------------------
	pop	ax

if _JEDIMOTIF
	;
	;  Assume that the only time OLMA_USE_LIST_SELECTION_CURSOR
	;  will be set is if it's really in a scrolling list, as the
	;  documentation suggests.  In this case, invert the object.
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_USE_LIST_SELECTION_CURSOR
	jz	doNormalDraw

	push	ax
	mov	ax, MM_INVERT
	call	GrSetMixMode
	pop	ax

	inc	cx
	inc	dx
	call	GrFillRect	
	jmp	doneDraw

doNormalDraw:
endif
	call	GrDrawRect

doneDraw::

	;
	; Enhance selection cursor for non-CGA keyboard-only mode
	; (For SOLID_FOCUS_OUTLINE, really enhance by alternating black and white dots.)
	;
	call	OpenCheckIfCGA
	jc	noEnhance		;CGA, no enhance
	call	OpenCheckIfKeyboardOnly
	jnc	noEnhance		;not keyboard-only, no enhance

if SOLID_FOCUS_OUTLINE
	push	bp
	push	ax

	push	bx
	call	GrGetLineColor		;get current line color index in ax
	push	di
	clr	di
	call	GrMapColorRGB		
	pop	di
	mov	al, ah
	clr	ah
	pop	bx

	mov	bp, ax			;save current color in bp
	mov	ax, C_LIGHT_GREY	;just always xor with this color,
					;  and hope for the best.
	call	GrSetLineColor
70$:
	mov	ax, SDM_100
	call	GrSetLineMask
	pop	ax
	call	GrDrawRect
endif
	call	InsetRect
	call	GrDrawRect

if SOLID_FOCUS_OUTLINE
	push	ax
	mov	ax, bp			;restore old draw color
	call	GrSetLineColor
	mov	ax, SDM_0
	call	GrSetLineMask
	pop	ax
	call	GrDrawRect
	pop	bp
endif

noEnhance:

	mov	al, SDM_100		;restore to solid line
	call	GrSetLineMask
	mov	ax, MM_COPY
	call	GrSetMixMode

	pop	ax, bx, di, ds		;ax = right side of moniker
					;bx = top of moniker
done:
	ret

InsetRect	label	near
	inc	ax
	inc	bx
	dec	cx
	dec	dx	
endif	; NOT PCV (from beg of routine)
	retn

OpenDrawSelectionCursor	endp

if _ODIE
idata	segment
focusPattern	label	byte
	byte	11001100b
	byte	11001100b
	byte	00110011b
	byte	00110011b
	byte	11001100b
	byte	11001100b
	byte	00110011b
	byte	00110011b
idata	ends

OpenSetFocusPattern	proc	far
	push	ds, si
	mov	al, SDM_CUSTOM
	mov	si, segment focusPattern
	mov	ds, si
	mov	si, offset focusPattern
	call	GrSetLineMask
	pop	ds, si
	ret
OpenSetFocusPattern	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenDrawOutsideCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw cursor outside bounds

CALLED BY:	EXTERNAL
			SliderDrawFocus
			DrawButtonBorderAndInterior
			DrawSelectionBox
PASS:		*ds:si = object
		di = gstate
		ax, bx, cx, dx = bounds outside of which border will be
					drawn
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CURSOR_OUTSIDE_BOUNDS

OpenDrawOutsideCursor	proc	far
	push	bp
	sub	sp, size OpenMonikerArgs
	mov	bp, sp
EC <	call	ECInitOpenMonikerArgs					>
	mov	ss:[bp].OMA_gState, di
	push	ax, bx, cx			; save bounds
	call	OpenGetWashColors		; al = main wash color
	mov	cx, mask OLMA_DISP_SELECTION_CURSOR or \
			mask OLMA_SELECTION_CURSOR_ON
if CURSOR_ON_BACKGROUND_COLOR
	call	OpenSetCursorColorFlagsFromColor
endif
	mov	ss:[bp].OMA_monikerAttrs, cx
	pop	ax, bx, cx			; restore bounds
	mov	ss:[bp].OMA_drawMonikerFlags, 0
	push	di				; save gstate
	mov	di, si				; *ds:di = *ds:si = spin gadget
	add	ax, 1				; set bounds for adjustment
	dec	bx				;	by ODSC
	call	OpenDrawSelectionCursor
	pop	di				; di = gstate
	add	sp, size OpenMonikerArgs
	pop	bp
	ret
OpenDrawOutsideCursor	endp

endif ; CURSOR_OUTSIDE_BOUNDS

endif		;--------------------------------------------------------------
endif ; DRAW_SELECTION_CURSOR_FOR_FOCUSED_GADGETS


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenDrawKbdAccelerator

DESCRIPTION:	This routine draws the keyboard accelerator for this object.

CALLED BY:	OpenDrawMoniker

PASS:		*ds:si	= instance data for object
		*es:di = generic object
		cx	= X position to draw accelerator
		bx	= Y position to draw accelerator
		ss:bp  = OpenMonikerArgs

RETURN:		ds, si, di, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/90		initial version
	Chris 	5/15/91		Updated for new bounds scheme
	
------------------------------------------------------------------------------@

if _CUA_STYLE and _USE_KBD_ACCELERATORS ;-------------------------------------
		  
OpenDrawKbdAccelerator	proc	near

	;now create the text for the keyboard moniker.
	;	*ds:si = visible object
	;	*es:di = generic object
	;	bx     = draw Y position
	;	cx	= draw X position
	;	ss:bp = OpenMonikerArgs

;DUBIOUS DS
	push	di, si, bp, ds
EC <	call	CheckForDamagedES	; Make sure *es still object block >
	push	es:[LMBH_handle]

	mov	ax, bx			;ax = draw Y position
	mov	bx, di			;bx = gen part
	mov	di, ss:[bp].OMA_gState	;di = gstate

					;dx = monikerAttrs
	mov	dx, ss:[bp].OMA_monikerAttrs

	sub	sp, MAX_KBD_MONIKER_LEN	;make room for a moniker string
	mov	bp, sp			;pass in bp

	push	ax			;save Y pos
	mov	ax, dx			;pass menu item flag in al
	push	ax			;save menu item flag
	call	GetKbdAcceleratorString	;string put in ss:bp, size in dx
	pop	dx			;recover menu item flag (dont need size)
	pop	bx			;recover Y pos
	jnc	noKbdAccelerator		;no moniker, exit

	;if menu item, get info from parent for centering
	;(don't do this for draw-to-right)

	test	dx, mask OLMA_IS_MENU_ITEM	;check menu item flag
	jz	noCentering			;not menu item, no centering

menuCentering::
	push	bx, si			
	call	SwapLockOLWin		;get to parent menu win
EC <	ERROR_NC OL_ERROR						>
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	mov	cx, ds:[si].VI_bounds.R_right
	sub	cx, ds:[si].VI_bounds.R_left
	sub	cx, ds:[si].OLMWI_accelSpace
	call	ObjSwapUnlock
	pop	bx, si			;bx = draw Y position

noCentering:
	segmov	ds, ss
	mov	si, bp
	mov	ax, cx			;set ax = draw X position

if _NIKE_EUROPE
	call	DrawKbdAcceleratorBitmaps
endif

	clr	cx			;null terminated
	call	GrDrawText		;draw it

noKbdAccelerator:
	add	sp, MAX_KBD_MONIKER_LEN		;restore
	pop	bx
	call	MemDerefES
EC <	call	CheckForDamagedES	; Make sure *es still object block >
	pop	di, si, bp, ds
	ret
OpenDrawKbdAccelerator	endp

endif		;--------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawKbdAcceleratorBitmaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw bitmap portion of kbd accelerators

CALLED BY:	OpenDrawKbdAccelerator
PASS:		ds:si	= keyboard accel string
		ax	= draw X position
		di	= handle of graphics state
RETURN:		ds:si	= keyboard accel string adjusted for bitmaps
		ax	= draw X position adjusted for bitmaps
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE_EUROPE

; Don't change this table without checking the moniker strings in cspecFile.ui.

kbdAcceleratorBitmapTable	word \
	offset ctrlBitmap, 			; ctrlString = "\\1";
	offset altBitmap,			; altString = "\\2";
	offset shiftBitmap,			; shiftString = "\\3";
	offset tabBitmap,			; tabString = "\\4";
	offset backspaceBitmap,			; backspaceString = "\\5";
	offset enterBitmap,			; enterString = "\\6";
	offset escBitmap,			; escString = "\\7";
	offset delBitmap,			; delString = "\\10";
	offset insBitmap,			; insString = "\\11";
	offset pageUpBitmap,			; pageUpString = "\\12";
	offset pageDownBitmap,			; pageDownString = "\\13";
	offset homeBitmap,			; homeString = "\\14";
	offset endBitmap,			; endString = "\\15";
	offset helpBitmap,			; helpString = "\\16";
	offset inkChangeBitmap,			; inkChangeString = "\\17";
	offset paperInsertBitmap		; paperInsertString = "\\20";

LAST_KBD_ACCELERATOR_BITMAP	equ	<length kbdAcceleratorBitmapTable>

DrawKbdAcceleratorBitmaps	proc	near
	uses	dx,bp,ds,es
	.enter

	segmov	es, ds
	mov	bp, si			; es:bp = keyboard accelerator string
	segmov	ds, cs
	clr	dx

bitmapLoop:
	mov	dl, es:[bp]
	tst	dl
	jz	noMoreBitmaps
	cmp	dl, LAST_KBD_ACCELERATOR_BITMAP
	ja	noMoreBitmaps

	mov	si, dx
	dec	si
	shl	si, 1
	mov	si, ds:kbdAcceleratorBitmapTable[si]
	clr	dx
	call	GrFillBitmap
	add	ax, ds:[si].B_width
	inc	bp
	jmp	bitmapLoop

noMoreBitmaps:
	mov	si, bp			; si = offset to keyboard accel string

	.leave
	ret
DrawKbdAcceleratorBitmaps	endp

endif	; _NIKE_EUROPE


COMMENT @----------------------------------------------------------------------

ROUTINE:	FixupCenteredMonikers

SYNOPSIS:	Makes all monikers left justified.

CALLED BY:	OpenDrawMoniker, OpenGetMonikerPos

PASS:		
	*ds:si - handle of object's vis part (for positions)
	*es:bx - handle of object's gen part (for vis and kbd monikers)

	ss:bp  - OpenMonikerArgs

RETURN:	ss:[bp].OMA_drawMonikerFlags possibly adjusted for left justification

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89	Initial version

------------------------------------------------------------------------------@

FixupCenteredMonikers	proc	near
	class	VisClass

	uses	bx
	.enter

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	mov	ax, ss:[bp].OMA_drawMonikerFlags
	and	al, mask DMF_X_JUST		;look at x justification
	cmp	al, J_CENTER shl offset DMF_X_JUST
	jne	FCM_checkVert			;not H centering, move on

	push	bp
	call	OpenGetMonikerSize		;get overall size of stuff
	pop	bp

	mov	ax, cx				;keep in ax
	call	VisGetSize			;get current object size
	sub	cx, ax				;subtract calced from real size
	jnc	10$				;skip if still >= 0...

	clr	cx				;set margin to 0
10$:
	mov	ax, cx				;put in ax
	shr	ax, 1				;divide by two

	add	ss:[bp].OMA_leftInset, ax	;and make a new x inset amount

	;Make left justified.  We know it's currently centered.

	sub	ss:[bp].OMA_drawMonikerFlags, \
			(J_CENTER shl offset DMF_X_JUST) - \
			(J_LEFT shl offset DMF_X_JUST)

;
; We must really optimize this - combine with above somehow.
; Though this is space-intensive, it is somewhat time-optimized as
; we only call OpenGetMonikerSize and VisGetSize twice if both H and V
; centering, which, unfortunately, is probably most of the time.
;
FCM_checkVert:
	;
	; If we are drawing a keyboard accelerator below the normal moniker,
	; instead of to the right, we'll need to override centering, if any,
	; and compute the topInset ourselves because the VisDrawMoniker
	; doesn't know about the keyboard-accelerator-below when it deals with
	; centering.  (Also when drawing shadows on the triggers, so that we
	; can deal correctly with topInset <> bottomInset.  -cbh 2/ 2/93)
	;
if	DRAW_SHADOWS_ON_BW_GADGETS
	call	OpenCheckIfBW			
	jc	doVert			
endif	
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM or \
						mask OLMA_DRAW_SHORTCUT_TO_RIGHT
	jnz	FCM_exit			;menu overrides shortcut-below
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_BELOW
	jz	FCM_exit			;not drawing below, move on
doVert:
	mov	ax, ss:[bp].OMA_drawMonikerFlags
	and	al, mask DMF_Y_JUST		;look at y justification
	cmp	al, J_CENTER shl offset DMF_Y_JUST
	jne	FCM_exit			;not V centering, move on
	push	bp
	call	OpenGetMonikerSize		;get overall size of stuff
	pop	bp

	mov	bx, dx				;keep in bx
	call	VisGetSize			;get current object size
	sub	dx, bx				;subtract calced from real size
	dec	dx				;match VisGetMonikerPos hack.
;	sub	dx, ss:[bp].OMA_topInset	;not added in OpenGetMonikerSize
;	sub	dx, ss:[bp].OMA_bottomInset
	mov	bx, dx				;put in bx
	sar	bx, 1				;divide by two
	inc	bx				;match VisGetMonikerPos hack.

	add	ss:[bp].OMA_topInset, bx	;and make a new y inset amount

	;Make top justified.  We know it's currently centered.

	sub	ss:[bp].OMA_drawMonikerFlags, \
			(J_CENTER shl offset DMF_Y_JUST) - \
			(J_LEFT shl offset DMF_Y_JUST)

FCM_exit:
	.leave
	ret
FixupCenteredMonikers	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupMaxWidth

SYNOPSIS:	Sets up a maximum width for objects that have their 
		CLIP_TO_MAX_WIDTH bit set.  The maximum width is the
		width of the object minus its insets.

CALLED BY:	OpenDrawMoniker

PASS:		
	*ds:si - handle of object's vis part (for positions)
	*es:bx - handle of object's gen part (for vis and kbd monikers)
	ss:bp  - OpenMonikerArgs

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89	Initial version
	Eric	4/90		updated passed args

------------------------------------------------------------------------------@
SetupMaxWidth	proc	near
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	test	ss:[bp].OMA_drawMonikerFlags, mask DMF_CLIP_TO_MAX_WIDTH
						;see if we'll clip
	jz	exit				;no, exit
	
	call	VisGetSize			;get object width in cx
	sub	cx, ss:[bp].OMA_rightInset	;subtract right inset
	sub	cx, ss:[bp].OMA_leftInset	;and left inset.  Duh. 10/14/92
	;
	; Subtract right or down arrows.  Probably still need to subtract
	; win mark, kbd-moniker.
	;
if (not _JEDIMOTIF)
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_RT_ARROW
	jz	5$	   	       			; not doing arrows
	sub	cx, OL_MARK_WIDTH + OL_MARK_SPACING 	; leave room for it
	jmp	short storeMax
5$:
endif
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_DOWN_ARROW
	jz	storeMax	   	       ;not doing arrows, branch
if _JEDIMOTIF
	;
	; 2 pixel spacing for JEDI (see DrawBWButtonMenuMark)
	; (unfortunately, we have to use 1 as it gives the correctly looking
	;  results, I can't explain why)
	;
;	sub	cx, OL_MARK_WIDTH + 2
	sub	cx, OL_MARK_WIDTH + 1
else
	sub	cx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING
endif

storeMax:
	mov	ss:[bp].OMA_xMaximum, cx	;and store as maximum length
if (not _JEDIMOTIF)	; no Y clipping for JEDI (a hack, I admit)
	sub	dx, ss:[bp].OMA_bottomInset
	sub	dx, ss:[bp].OMA_topInset	
endif
	mov	ss:[bp].OMA_yMaximum, dx
exit:
	ret
SetupMaxWidth	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetMonikerPos

SYNOPSIS:	Returns position of the moniker.

CALLED BY:	utility

PASS:		
	*ds:si - handle of object's vis part (for positions)
	*es:bx - handle of object's gen part (for vis and kbd monikers)

	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state

RETURN:		
	ax, bx - moniker position

DESTROYED:	
	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 8/89		Initial version

------------------------------------------------------------------------------@

OpenGetMonikerPos	proc	far
	class	VisClass
	
EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	call	FixupCenteredMonikers	;make all monikers left justified

	mov	cx, ss:[bp].OMA_drawMonikerFlags
	ANDNF	cl, mask DMF_Y_JUST or mask DMF_X_JUST	;only pass these
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Gen_offset		;ds:bx = GenInstance
	mov	bx, ds:[bx].GI_visMoniker
	call	SpecGetMonikerPos		;return the moniker position
	ret
OpenGetMonikerPos	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetKbdAcceleratorString

SYNOPSIS:	Creates a string from a moniker value.  Adds parentheses if
		not an object in a vertical menu.

CALLED BY:	OpenDrawMoniker, OpenGetMonikerSize

PASS:		ds:si -- handle of object's vis part
		es:bx -- handle of object's gen part
		ss:bp -- place for string to live(MAX_KBD_MONIKER_LEN allocated)
		di -- graphics state
		ax -- monikerAttrs

RETURN:		carry set if there is a moniker, with:
			dx    -- length of string
		else
			dx    -- zero

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/11/89		Initial version

------------------------------------------------------------------------------@

if _USE_KBD_ACCELERATORS

GetKbdAcceleratorString	proc	near	uses cx, si, ds, es
	class	VisClass
	.enter

	push	di				;save gstate	
	mov	di, es:[bx]			;point to instance
	add	di, es:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	dx, es:[di].GI_kbdAccelerator	;get the keyboard moniker

	test	dx, mask KS_CHAR		;is there a moniker at all?
	LONG	jz	GKMS_exit		;exit if not with carry clear

	segmov	es, ss				;set es to destination buffer
	mov	di, bp				;point with es:di
	
if _RUDY
	;
	; Parenthesize all accelerators.
	;
	push	ax
SBCS <	mov	al, '(' 			;add prefix 		>
SBCS <	stosb								>
DBCS <	mov	ax, '('				;add prefix		>
DBCS <	LocalPutChar esdi, ax						>
	pop	ax

endif

	call	ExpandKbdAccelerator		;expand the moniker

	push	ax				; save monikerAttrs

if _RUDY
	;
	; Parenthesize all accelerators.
	;
SBCS <	mov	al, ')' 			;add prefix 		>
SBCS <	stosb								>
DBCS <	mov	ax, ')'				;add prefix		>
DBCS <	LocalPutChar esdi, ax						>

else
	test	ax, mask OLMA_IS_MENU_ITEM or mask OLMA_DRAW_SHORTCUT_BELOW or \
						mask OLMA_DRAW_SHORTCUT_TO_RIGHT
	jnz	GKMS_storeNull

SBCS <	mov	ax, ' ' or ('-' shl 8)		;add prefix 		>
SBCS <	stosw								>
DBCS <	mov	ax, ' '							>
DBCS <	LocalPutChar esdi, ax						>
DBCS <	mov	ax, '-'				;add prefix		>
DBCS <	LocalPutChar esdi, ax						>

endif		;if _RUDY

GKMS_storeNull:
	mov	dx, segment idata		;ds points at idata
	mov	ds, dx

SBCS <	mov	dx, di				;put end of string in dx >
SBCS <	sub	dx, bp				;subtract start to get #chars >
SBCS <	clr	al				;store a null terminator>
SBCS <	stosb								>
DBCS <	clr	ax				;store a null terminator>
DBCS <	LocalPutChar esdi, ax						>

	;
	; es:bp = start of accelerator string
	; es:di = pointer past accelerator string
	; on stack: monikerAttrs, gstate
	;
	pop	ax				; get monikerAttrs
	pop	di				; get gstate
	push	di				; save again
	push	ax				; save again
	segmov	ds, es, si			; ds:si = kbd accel string
	mov	si, bp

if _NIKE_EUROPE
	push	bp
	clr	ax, dx

bitmapLoop:
	mov	al, ds:[si]
	tst	al
	jz	noMoreBitmaps
	cmp	al, LAST_KBD_ACCELERATOR_BITMAP
	ja	noMoreBitmaps

	mov	bp, ax
	dec	bp
	shl	bp, 1
	mov	bp, cs:kbdAcceleratorBitmapTable[bp]
	add	dx, cs:[bp].B_width
	inc	si
	jmp	bitmapLoop

noMoreBitmaps:
	mov	bp, dx				; bp = width of bitmaps
	mov	cx, -1				; check till null-term
	call	GrTextWidth			; dx = width
	add	dx, bp				; add bitmap widths
	pop	bp

else	; not _NIKE_EUROPE

	mov	cx, -1				; check till null-term
	call	GrTextWidth			; dx = width

endif	; if _NIKE_EUROPE

	pop	ax				;restore monikerAttrs
	test	ax, mask OLMA_IS_MENU_ITEM	;menu item?
						;(don't check draw-to-right)
	jz	GKMS_stc			;no, branch
					;include menu spacing to shortcut
	add	dx, SHORTCUT_SPACING - CLOSE_SHORTCUT_SPACING

GKMS_stc:
	add	dx, CLOSE_SHORTCUT_SPACING	;include spacing
	stc					;say we found a moniker

GKMS_exit:
	pop	di				;recover gstate
	.leave
	ret

GetKbdAcceleratorString	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ExpandKbdAccelerator

SYNOPSIS:	Expands keyboard moniker into a non-null terminated string.  

CALLED BY:	GetKbdAcceleratorString

PASS:		es:di -- pointer to buffer for string
		dx    -- keyboard moniker

RETURN:		es:di -- pointing past end of string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
       Expands the following:
       		Alt key:				"Alt "
		Ctrl key:				"Ctrl "
		Shift key (or uppercase letter:		"Shift "
		Function key:				"F3", etc.		
		Escape:					"Esc"
		Space:					"Space"
		Insert:					"Ins"
		Delete:					"Del"
		Enter:					"Enter"
		Page Up:				"Page Up"
		Page Down:				"Page Down"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/90		Initial version

------------------------------------------------------------------------------@

ExpandKbdAccelerator	proc	near		uses ax, bx
	.enter
	mov	bx, handle altString		;point to resource block
	call	MemLock				;  containing expansion text 
EC <	ERROR_C	OL_ERROR			;shouldn't have failed the lock! >

	mov	ds, ax
	push	bx				;save block handle
	push	dx				;save original char

	test	dx, mask KS_ALT			;see if alt pressed
	jz	checkShift			;no alt pressed, branch
	mov	si, offset altString		;else point ds:si <- alt string
	call	CopyStringFromChunk

checkShift:
	test	dx, mask KS_SHIFT		;see if shifted char
	jnz	addShift			;if so, add the shift string
DBCS <			CheckHack <CS_LATIN_1 eq 0>
DBCS <	test	dh, mask KS_CHAR shr 8					>
DBCS <	jnz	checkCtrl						>
	cmp	dl, 'A'				;see if in capitals
	jb	checkCtrl			;no, branch
	cmp	dl, 'Z'
	ja	checkCtrl
	
addShift:
	mov	si, offset shiftString		;else copy the string
	call	CopyStringFromChunk

checkCtrl:
	test	dx, mask KS_CTRL		;see if a control char
	jz	checkFKeys			;no, branch
	
	mov	si, offset ctrlString		;else add ctrl in
	call	CopyStringFromChunk
	
;	cmp	dl, VC_CTRL_Z			;see if in ctrl-alpha range
;	ja	checkFKeys			;no, branch
;	add	dl, 'A'- VC_CTRL_A		;convert char to ascii
;	jmp	short storeChar			;and go store the character

checkFKeys:
SBCS <	and	dh, (mask KS_CHAR_SET shr 8)	;clear all but char set bits >
SBCS <	cmp	dh, 0fh				;see if in control char set >
SBCS <	jne	checkEsc			;branch if not		>
DBCS <	andnf	dx, (mask KS_CHAR)		;clear all but character bits
DBCS <	cmp	dh, CS_CONTROL_HB and (mask KS_CHAR shr 8)		>
DBCS <	jne	makeUpper			;branch if not		>

SBCS <	cmp	dl, VC_F1			;see if in range of func keys >
DBCS <	cmp	dl, C_SYS_F1 and 0x00ff		;see if in range of func keys >
	jb	checkEsc			;no, branch
SBCS <	cmp	dl, VC_F16			;above range?		>
DBCS <	cmp	dl, C_SYS_F16 and 0x00ff	;above range?		>
	ja	checkEsc			;yes, branch

if _NIKE
	; for NIKE project the kbdaccelerator for the following has to change
	mov	si, offset SaveAccStr
SBCS <	cmp	dl, VC_F2						>
DBCS <	cmp	dl, C_SYS_F2 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset ExitAccStr
SBCS <	cmp	dl, VC_F3						>
DBCS <	cmp	dl, C_SYS_F3 and 0x00ff					>
	LONG je	copyStringAndQuit
	
	mov	si, offset PrintAccStr
SBCS <	cmp	dl, VC_F4						>
DBCS <	cmp	dl, C_SYS_F4 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset SpellCheckAccStr
SBCS <	cmp	dl, VC_F5						>
DBCS <	cmp	dl, C_SYS_F5 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset CutAccStr
SBCS <	cmp	dl, VC_F6						>
DBCS <	cmp	dl, C_SYS_F6 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset CopyAccStr
SBCS <	cmp	dl, VC_F7						>
DBCS <	cmp	dl, C_SYS_F7 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset PasteAccStr
SBCS <	cmp	dl, VC_F8						>
DBCS <	cmp	dl, C_SYS_F8 and 0x00ff					>
	LONG je	copyStringAndQuit	
endif	; if _NIKE

if _NIKE_EUROPE
	mov	si, offset helpString
SBCS <	cmp	dl, VC_F1						>
DBCS <	cmp	dl, C_SYS_F1 and 0x00ff					>
	LONG je	copyStringAndQuit

	mov	si, offset inkChangeString
SBCS <	cmp	dl, VC_F11						>
DBCS <	cmp	dl, C_SYS_F11 and 0x00ff				>
	LONG je	copyStringAndQuit

	mov	si, offset paperInsertString
SBCS <	cmp	dl, VC_F12						>
DBCS <	cmp	dl, C_SYS_C12 and 0x00ff				>
	LONG je	copyStringAndQuit
endif	; if _NIKE_EUROPE

	LocalLoadChar ax, 'F'			;else store an 'F'
	LocalPutChar esdi, ax
SBCS <	cmp	dl, VC_F10			;see if double digits	>
DBCS <	cmp	dl, C_SYS_F10 and 0x00ff	;see if double digits	>
	jb	10$				;no, branch
	LocalLoadChar ax, '1'			;else store tens digit
	LocalPutChar esdi, ax
	sub	dl, 10				;and subtract ten from our fkey
10$:
SBCS <	sub	dl, VC_F1-'1'			;make VC_F1=1, VC_F2=2, etc. >
DBCS <	sub	dl, C_SYS_F1-'1' and 0x00ff	;make VC_F1=1, VC_F2=2, etc. >
DBCS <	clr	dh							>
	jmp	short storeChar			;and we're done

checkEsc:

if _NIKE_EUROPE
SBCS <	cmp	dl, VC_TAB						>
DBCS <	cmp	dl, C_SYS_TAB and 0x00ff				>
	jne	checkHome
	mov	si, offset tabString
	jmp	short copyStringAndQuit

checkHome:
SBCS <	cmp	dl, VC_HOME						>
DBCS <	cmp	dl, C_SYS_HOME and 0x00ff				>
	jne	checkEnd
	mov	si, offset homeString
	jmp	short copyStringAndQuit

checkEnd:
SBCS <	cmp	dl, VC_END						>
DBCS <	cmp	dl, C_SYS_END and 0x00ff				>
	jne	realCheckEsc
	mov	si, offset endString
	jmp	short copyStringAndQuit

realCheckEsc:
endif

SBCS <	cmp	dl, VC_ESCAPE			;see if escape char	>
DBCS <	cmp	dl, C_SYS_ESCAPE and 0x00ff				>
	jne	checkDel			;no, check space
	mov	si, offset escString
	jmp	short copyStringAndQuit		;copy string and exit
	
checkDel:
SBCS <	cmp	dl, VC_DEL			;check for delete	>
DBCS <	cmp	dl, C_SYS_DELETE and 0x00ff	;check for delete	>
	jne	checkIns
	mov	si, offset delString
	jmp	short copyStringAndQuit
	
checkIns:
SBCS <	cmp	dl, VC_INS						>
DBCS <	cmp	dl, C_SYS_INSERT and 0x00ff				>
	jne	checkBackspace
	mov	si, offset insString
	jmp	short copyStringAndQuit

checkBackspace:
SBCS <	cmp	dl, VC_BACKSPACE		;check for backspace	>
DBCS <	cmp	dl, C_SYS_BACKSPACE and 0x00ff	;check for backspace	>
	jne	checkEnter			;no, branch

	pop	si				;get original char back
	push	si
	test	si, mask KS_ALT	or mask KS_CTRL	;see if alt pressed
	mov	si, offset ctrlHString		;use ctrl-H if alt not pressed
	jz	copyStringAndQuit		;no alt pressed, branch
	mov	si, offset backspaceString	;else copy in backspace
	jmp	short copyStringAndQuit		;and exit
	
checkEnter:
SBCS <	cmp	dl, VC_ENTER			;check for enter	>
DBCS <	cmp	dl, C_SYS_ENTER	and 0x00ff	;check for enter	>
	jne	checkPageUp			;no, branch
	mov	si, offset enterString		;else copy in enter
	jmp	short copyStringAndQuit		;and exit
	
checkPageUp:
SBCS <	cmp	dl, VC_PREVIOUS			;check for page up	>
DBCS <	cmp	dl, C_SYS_PREVIOUS and 0x00ff	;check for page up	>
	jne	checkPageDown			;no, branch
	mov	si, offset pageUpString		;else copy in enter
	jmp	short copyStringAndQuit		;and exit
	
checkPageDown:
if DBCS_PCGEOS
EC <	cmp	dl, C_SYS_NEXT and 0x00ff	;check for page down	>
EC <	ERROR_NE OL_ERROR_ILLEGAL_KEY_FOR_SHORTCUT			>
	mov	si, offset pageDownString	;else copy in enter
else
 	cmp	dl, VC_NEXT			;check for page down
	jne	checkSpace			;no, branch
	mov	si, offset pageDownString	;else copy in enter
	jmp	short copyStringAndQuit		;and exit

checkSpace:
	cmp	dl, C_SPACE			;see if a space
	jne	makeUpper			;no, store the character
	mov	si, offset spaceString		;else store "Space"
endif
	
copyStringAndQuit:
	call	CopyStringFromChunk
	jmp	short done			;and we're done
	

if DBCS_PCGEOS
makeUpper:
	cmp	dx, 'a'				;if lowercase, make uppercase
	jb	storeChar
	cmp	dx, 'z'
	ja	storeChar
	andnf	dx, not 20h			;clear this bit to make upper
		CheckHack <'a'-'A' eq 20h>
storeChar:
	mov	ax, dx
	stosw
else
makeUpper:
	cmp	dl, 'a'				;if lowercase, make uppercase
	jb	storeChar
	cmp	dl, 'z'
	ja	storeChar
	and	dl, not 20h			;clear this bit to make upper

storeChar:
	mov	al, dl				;put in al
	stosb					;and store it
endif

done:
	pop	dx				;restore original char
	pop	bx				;restore resource block handle
	call	MemUnlock
	.leave
	ret
ExpandKbdAccelerator	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CopyStringFromChunk

SYNOPSIS:	Copies a string.

CALLED BY:	GetKbdAcceleratorString, 
		ExpandKbdAccelerator  <--- only when it's NIKE product

PASS:		ds:si -- source chunk containing string
		es:di -- destination

RETURN:		ds:si -- at end of string
		es:di -- at end of string

DESTROYED:	al

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/14/89		Initial version

------------------------------------------------------------------------------@

CopyStringFromChunk	proc	near
	class	VisClass
	mov	si, ds:[si]			;dereference chunk
copy:
	LocalGetChar ax, dssi			;get a char
	LocalIsNull ax
	jz	exit				;if null, exit
	LocalPutChar esdi, ax
	jmp	short copy
exit:
	ret
CopyStringFromChunk	endp

endif ; _USE_KBD_ACCELERATORS


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetMonikerSize

SYNOPSIS:	Returns a size for the visual and keyboard monikers.

CALLED BY:	OLButtonRecalcSize, OLSettingRecalcSize,
		FixupCenteredMonikers

PASS:
	*ds:si - handle of object's visual part
	*es:bx - handle of object's generic part

	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state

RETURN:
	cx -- total moniker width
	dx -- total moniker height

DESTROYED:
	ax, di

PSEUDO CODE/STRATEGY:
	cx, dx = SpecGetMonikerSize;
	cx = cx + (xInset * 2)
	dx = dx + (yInset * 2)
	if OLMA_DISP_WIN_MARK
		cx = cx + GenGetMonikerSize(winMark);

	if OLMA_DISP_UP_ARROW_MARK or OLMA_DISP_RT_ARROW_MARK
		cx = cx + SUBMENU_MARK_WIDTH + xInset
	if OLMA_DISP_KBD_MONIKER if there's a kbdMoniker
		;
		; Add size of a built keyboard moniker, and use inset amount
		; as a minimum amount of space between the visMoniker and
		; the keyboard moniker.
		;
		size = size + StringLen(MonikerToString(kbdAccelerator) + xInset
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 8/89		Initial version

------------------------------------------------------------------------------@

OpenGetMonikerSize	proc	far
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	push	bx				;save bx
	push	bp				;save args
	call	OpenGetMonikerSizeLow		;cx - width of vis moniker
						;dx - width of kbd accelerator
						;ax - height of monikers
	pop	bp				;retrieve args
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_BELOW
	jz	monikerToRightOrLeft
	;
	; we want moniker below, do that size calcuation
	;
EC <	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_TO_RIGHT >
EC <	ERROR_NZ	OL_ERROR					>
	tst	dx				;0 if no kbd moniker
	jz	monikerToRightOrLeft		;if none, use regular calc.

	add	dx, ss:[bp].OMA_leftInset	;add in side insets
	add	dx, ss:[bp].OMA_rightInset
	cmp	cx, dx
	jge	monikerWider			;actual moniker wider, keep it
	mov	cx, dx				;else, use kbd mkr width
monikerWider:
	push	ax				;save actual moniker height
	call	GetSystemFontHeight		;ax = kbd accel height
	pop	dx				;retrieve actual moniker height
	add	dx, CGA_BELOW_SHORTCUT_SPACING	;give it some room (assume CGA)
	call	OpenCheckIfCGA
	jc	isCGA
	add	dx, (BELOW_SHORTCUT_SPACING - CGA_BELOW_SHORTCUT_SPACING)
isCGA:
	add	dx, ax				;add in kbd accel height
	jmp	short exit

monikerToRightOrLeft:
	add	cx, dx				;add right part to left part
						;   for the width
	mov	dx, ax				;return height
exit:
	pop	bx				;restore bx
	ret
OpenGetMonikerSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMkrSizeWithInsets

SYNOPSIS:	Returns size of vis moniker with insets added.

CALLED BY:	OpenGetMonikerSize, OpenGetMonikerCenter, OpenDrawMoniker

PASS:
	*ds:si - handle of object's vis part
	*es:bx - handle of object's gen part

	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state


RETURN:		cx, dx -- size
		ax -- moniker flags
		bx -- insets
		*es:di -- handle of gen part

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/12/89		Initial version

------------------------------------------------------------------------------@

GetMkrSizeWithInsets	proc	near
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	push	bx				;save gen handle
	mov	di, ds:[bx]			;ds:di = moniker handle
	add	di, ds:[di].Gen_offset		;
	mov	di, ds:[di].GI_visMoniker

	push	bp
	mov	bp, ss:[bp].OMA_gState		;pass handle of gstate
	call	SpecGetMonikerSize		;returns moniker size in cx,dx
	pop	bp

	;
	; If doing a down arrow, I've decided that we'll make sure we're at
	; least as high as the system text at all times, to facilitate 
	; no-moniker popup list buttons.  -cbh 5/18/92
	;
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_DOWN_ARROW
	jz	1$		   	        ;not doing down arrows, branch
	call	GetSystemFontHeight		;ax <- system font height
	cmp	dx, ax				;make sure at least that high.
	jae	1$
	mov	dx, ax
1$:

	;
	; If this moniker requires a mnemonic stuck on the end of the text,
	; let's figure in our typical width for such a thing.
	;
	push	es
	tst	di
	jz	afterAddMnemonic		;skip if no moniker
	mov	di, ds:[di]			;deref moniker
	mov	ax, {word} ds:[di].VM_type	;get moniker type
	test	ax, mask VMT_GSTRING		;is a GString?
	jnz	afterAddMnemonic		;yes, branch
	mov	al, ds:[di].VM_data + VMT_mnemonicOffset 
	cmp	al, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	afterAddMnemonic		;no mnemonic to add on, branch

	; Let's figure out how wide a typical add-on is if we haven't done so 
	; previously.

	push	dx
	mov	dx, segment idata		;ds points at idata
	mov	es, dx
	
	tst	es:addOnMnemonicWidth		;is there mnemonic width around?
	jnz	gotMnemonicWidth		;yes, branch

	push	bp, ds, cx, si
	call	ViewCreateCalcGState		;returns gstate in di
	mov	si, offset sampleAddOnMnemonic
SBCS <	mov	cx, size sampleAddOnMnemonic				>
DBCS <	mov	cx, length sampleAddOnMnemonic				>
	segmov	ds, cs
FXIP <	; copy string to stack						>
FXIP <	sub	sp, cx							>
FXIP <	mov	ax, sp							>
FXIP <	push	es, di				; save regs used in copy>
FXIP <	segmov	es, ss, di						>
FXIP <	mov	di, ax				; es:di = buffer on stack>
FXIP <	push	cx							>
FXIP <	LocalCopyNString						>
FXIP <	pop	cx							>
FXIP <	pop	es, di							>
FXIP <	segmov	ds, ss, si						>
FXIP <	mov	si, sp				; ds:si = string	>
	call	GrTextWidth			;width returned in dx
FXIP <	add	sp, cx							>
	call	GrDestroyState			;daddy, make the gstate go away!
	mov	es:addOnMnemonicWidth, dx	;store it
	pop	bp, ds, cx, si
	
gotMnemonicWidth:	
	add	cx, es:addOnMnemonicWidth	;add extra width in
	pop	dx
	
afterAddMnemonic:
	pop	es
	call	AddInsetsAndWinMark		;add in extra stuff to size
	pop	di				;restore gen handle
	ret
GetMkrSizeWithInsets	endp

			
SBCS <sampleAddOnMnemonic	char	" (w)"				>
DBCS <sampleAddOnMnemonic	wchar	" (w)"				>
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	AddInsetsAndWinMark

SYNOPSIS:	Adds in the size of the moniker insets, and window mark if any.

CALLED BY:	GetMkrSizeWithInsets, OpenGetMonikerExtraSize

PASS:	cx, dx - size before adding insets	
	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state


RETURN:		cx, dx - size after adding insets

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@

AddInsetsAndWinMark	proc	near
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	; Let's figure out how wide a period is if we haven't done so 
	; previously.

	push	es
	push	dx
	mov	dx, segment idata		;ds points at idata
	mov	es, dx
	
	tst	es:winMarkWidth			;is there a char width around?
	jnz	gotWinMarkWidth			;yes, branch

	push	bp				;save these
	mov	ax, '.'				;get width of typical char
	call	ViewCreateCalcGState		;returns gstate in di
	call	GrCharWidth			;width returned in dx
	call	GrDestroyState			;daddy, make the gstate go away!
	mov	dh, dl				;multiply by 3
	shl	dl, 1
	add	dl, dh
	mov	es:winMarkWidth, dl		;store it
	pop	bp
	
gotWinMarkWidth:	
	pop	dx
	add	cx, ss:[bp].OMA_leftInset		;add inset to width
	add	cx, ss:[bp].OMA_rightInset		;add for each side
	add	dx, ss:[bp].OMA_topInset		;add inset to width
	add	dx, ss:[bp].OMA_bottomInset		;add inset to width

if DRAW_WINDOW_MARK_IN_MONIKERS
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_WIN_MARK
						;see if we're doing this...
	jz	AIAWM_exit			;nope, exit

	add	cl, es:winMarkWidth		;probably more than enough
	adc	ch, 0
endif

AIAWM_exit:
	pop	es
	ret
AddInsetsAndWinMark	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetMonikerCenter

SYNOPSIS:	Returns offset to end of moniker (start of shortcuts).

CALLED BY:	utility

PASS:	
	*ds:si - instance data of object
	*es:bx - gen object
	ss:bp  - OpenMonikerArgs

RETURN:		
	cx 	- minimum amount needed left of center
	dx	- minimum amount needed right of center
	ax 	- minimum amount needed above center
	bp      - minimum amount needed below center

DESTROYED:
	ax, bx, di

PSEUDO CODE/STRATEGY:
	size = SpecGetMonikerSize;
	cx = size + (xInset * 2)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 8/89		Initial version

------------------------------------------------------------------------------@

OpenGetMonikerCenter	proc	far
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	test	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM
	pushf
	call	VisGetCenter			;do normal
	popf
	jz	exit

	push	si, bx
	call	SwapLockOLWin
EC <	ERROR_NC	OL_ERROR				>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLMWI_monikerSpace	
	mov	dx, ds:[di].OLMWI_accelSpace	
	call	ObjSwapUnlock
	pop	si, bx
exit:
	ret
OpenGetMonikerCenter	endp


OpenGetMonikerSizeLow	proc	far		;returns cx: moniker width
						;        dx: accel width
						;	 ax: moniker height
EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>
	call	GetMonikerSizes
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_IS_MENU_ITEM
	jz	done

	push	si, bx, ax
	call	SwapLockOLWin
EC <	ERROR_NC	OL_ERROR				>
EC <	push	es, di						>
EC <	mov	di, segment OLMenuWinClass			>
EC <	mov	es, di						>
EC <	mov	di, offset OLMenuWinClass			>
EC <	call	ObjIsObjectInClass				>
EC <	pop	es, di						>
EC <	ERROR_NC	OL_ERROR				>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLMWI_monikerSpace	
	mov	dx, ds:[di].OLMWI_accelSpace	
	call	ObjSwapUnlock
	pop	si, bx, ax
done:
	ret
OpenGetMonikerSizeLow	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetMonikerMenuCenter

SYNOPSIS:	Returns area left and right of center.

CALLED BY:	utility

PASS:	
	*ds:si - instance data of object
	*es:bx - gen object
	ss:bp  - OpenMonikerArgs
	cx	- amoung left of center, so far
	dx	- amoung right of center, so far

RETURN:		
	cx 	- minimum amount needed left of center
	dx	- minimum amount needed right of center

DESTROYED:
	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 8/89		Initial version

------------------------------------------------------------------------------@

OpenGetMonikerMenuCenter	proc	far
	push	cx, dx
	call	GetMonikerSizes			;vis moniker width in cx
						;kbd accelerator width in dx
	;
	; Replace the passed values if bigger.
	;
	pop	ax, bx
	cmp	cx, ax
	jae	10$
	mov	cx, ax
10$:
	cmp	dx, bx
	jae	20$
	mov	dx, bx
20$:
	ret
OpenGetMonikerMenuCenter	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMonikerSizes

SYNOPSIS:	Returns sizes of vis and keyboard monikers.

CALLED BY:	OpenGetMonikerCenter, OpenGetMonikerSize

PASS:	       
	*ds:si - instance data of object
	*es:bx - gen object

	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state

RETURN:		
	cx 	- width of visual moniker
	dx	- width of keyboard moniker
	ax 	- height of both

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/10/89	Initial version
	Chris	12/ 2/92	Changed to allow right arrows *and* kbd accels

------------------------------------------------------------------------------@

GetMonikerSizes	proc	near
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	call	GetMkrSizeWithInsets	;size of vis moniker in cx,dx
					;insets in bx
					;returns *es:di = handle of gen part
					;trashes bx

	push	dx			;save height

	;check for arrow marks

	clr	dx			;assume nothing right of center
if not _JEDIMOTIF
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_RT_ARROW
	jz	5$	   	       ;not doing arrows, branch
	mov	dx, OL_MARK_WIDTH+OL_MARK_SPACING   ;else leave room for it
	jmp	short tryKbdAccelerator		
5$:
endif
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_DOWN_ARROW
	jz	tryKbdAccelerator   	       ;not doing arrows, branch
	mov	dx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING
	jmp	short tryKbdAccelerator		;no kbd moniker, exit

tryKbdAccelerator:

if _USE_KBD_ACCELERATORS
	test	ss:[bp].OMA_monikerAttrs, mask OLMA_DISP_KBD_MONIKER
					;see if drawing kbd moniker
	jz	finishUp		;nope, exit

	push	bx			;optimize by doing a quick check first
	mov	bx, es:[bx]
	add	bx, es:[bx].Gen_offset
	test	es:[bx].GI_kbdAccelerator, mask KS_CHAR
	pop	bx
	jz	finishUp

	push	cx, dx, si, ds, bp
	mov	bx, di				;pass gen handle in bx
	mov	di, ss:[bp].OMA_gState		;pass gstate in di
	tst	di
	jnz	gotGState			;branch with carry clear
	push	bp
	call	ViewCreateCalcGState		;di = gstate
	pop	bp
	stc
gotGState:
	; carry - set to destroy gstate
	pushf
	mov	ax, ss:[bp].OMA_monikerAttrs
	sub	sp, MAX_KBD_MONIKER_LEN		;make room for a moniker string
	mov	bp, sp				;pass in bp
	call	GetKbdAcceleratorString		;else get a string lengh in dx
	add	sp, MAX_KBD_MONIKER_LEN		;restore
	popf
	jnc	noDestroy
	call	GrDestroyState
noDestroy:
	mov	bx, dx				;moniker width in bx
	pop	cx, dx, si, ds, bp
	add	dx, bx				;add to previous stuff

finishUp:
endif		;_USE_KBD_ACCELERATORS
	
	pop	ax				;restore height
	ret
GetMonikerSizes	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetMonikerExtraSize

SYNOPSIS:	Returns size of object without the moniker. 

CALLED BY:	OLButtonGetExtraSize, OLSettingGetExtraSize

PASS:	*ds:si = instance data for object
	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state


RETURN:		
	cx, dx - size of non-moniker object

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version
	Eric	4/90		no longer necessary to pass al or ah.

------------------------------------------------------------------------------@

OpenGetMonikerExtraSize	proc	far
	class	VisClass

EC <	call	ECVerifyOpenMonikerArgs	;make sure passed structure	>

	clr	cx			;start with zero width
	clr	dx			;and height
	call	AddInsetsAndWinMark	;add extra things in
	ret
OpenGetMonikerExtraSize	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECVerifyOpenMonikerArgs

DESCRIPTION:	This error checking routine makes sure that the
		OpenMonikerArgs structure has been passed on the stack.

CALLED BY:	Any routine which expects this structure on the stack

PASS:		*ds:si	= instance data for object
		ss:bp	= OpenMonikerArgs on stack

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

if ERROR_CHECK

ECVerifyOpenMonikerArgs	proc	far
	cmp	ss:[bp].OMA_EC_id1, EC_OPEN_MONIKER_ARGS_ID1
	ERROR_NE OL_ERROR_BAD_OPEN_MONIKER_ARGS_STRUCTURE_PASSED_ON_STACK

	cmp	ss:[bp].OMA_EC_id2, EC_OPEN_MONIKER_ARGS_ID2
	ERROR_NE OL_ERROR_BAD_OPEN_MONIKER_ARGS_STRUCTURE_PASSED_ON_STACK
	ret
ECVerifyOpenMonikerArgs	endp

ECInitOpenMonikerArgs	proc	far
	mov	ss:[bp].OMA_EC_id1, EC_OPEN_MONIKER_ARGS_ID1
	mov	ss:[bp].OMA_EC_id2, EC_OPEN_MONIKER_ARGS_ID2
	ret
ECInitOpenMonikerArgs	endp

endif

	


COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecDrawMoniker

SYNOPSIS:	Like VisGetMoniker, except fills in specific UI's text height.

CALLED BY:	utility

PASS:	ss:bp -- DrawMonikerArgs
	*ds:si - instance data
	*es:bx - moniker to draw   (if bx = 0, then nothing drawn)
	cl     - how to draw moniker: DrawMonikerFlags
		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/22/91		Initial version

------------------------------------------------------------------------------@

SpecDrawMoniker	proc	far
	call	GetSystemFontHeight		;pass system font height
	mov	ss:[bp].DMA_textHeight, ax		
	call	VisDrawMoniker
	ret
SpecDrawMoniker	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecGetGenMonikerSize

SYNOPSIS:	Like GenGetMonikerSize, except passes the specific UI's text 
		height.

CALLED BY:	utility

PASS:	
	*ds:si - instance data for object
	bp - graphics state (containing font and style) to use
		
RETURN:		cx, dx -- size

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/22/91		Initial version

------------------------------------------------------------------------------@

SpecGetGenMonikerSize	proc	far		uses	ax
	.enter
	call	GetSystemFontHeight		;pass system font height
	call	GenGetMonikerSize

afterSize:

	;
	; If this moniker requires a mnemonic stuck on the end of the text,
	; let's figure in our typical width for such a thing.  (Stuck in 
	; here, not just in OpenGetMonikerSize - cbh 4/12/93)
	;
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker
	push	es
	tst	di
	jz	afterAddMnemonic		;skip if no moniker
	mov	di, ds:[di]			;deref moniker
	mov	ax, {word} ds:[di].VM_type	;get moniker type
	test	ax, mask VMT_GSTRING		;is a GString?
	jnz	afterAddMnemonic		;yes, branch
	mov	al, ds:[di].VM_data + VMT_mnemonicOffset 
	cmp	al, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	afterAddMnemonic		;no mnemonic to add on, branch

	; Let's figure out how wide a typical add-on is if we haven't done so 
	; previously.

	push	dx
	mov	dx, segment idata		;ds points at idata
	mov	es, dx
	
	tst	es:addOnMnemonicWidth		;is there mnemonic width around?
	jnz	gotMnemonicWidth		;yes, branch

	push	bp, ds, cx, si
	call	ViewCreateCalcGState		;returns gstate in di
	mov	si, offset sampleAddOnMnemonic
SBCS <	mov	cx, size sampleAddOnMnemonic				>
DBCS <	mov	cx, length sampleAddOnMnemonic				>
	segmov	ds, cs
FXIP <	; copy string to stack						>
FXIP <	sub	sp, cx							>
FXIP <	mov	ax, sp							>
FXIP <	push	es, di				; save regs used in copy>
FXIP <	segmov	es, ss, di						>
FXIP <	mov	di, ax				; es:di = buffer on stack>
FXIP <	LocalCopyString							>
FXIP <	pop	es, di							>
FXIP <	segmov	ds, ss, si						>
FXIP <	mov	si, sp				; ds:si = string	>	
	call	GrTextWidth			;width returned in dx
	call	GrDestroyState			;daddy, make the gstate go away!
	mov	es:addOnMnemonicWidth, dx	;store it
	pop	bp, ds, cx, si
	
gotMnemonicWidth:	
	add	cx, es:addOnMnemonicWidth	;add extra width in
	pop	dx
	
afterAddMnemonic:
	pop	es
	pop	di

	.leave
	ret
SpecGetGenMonikerSize	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecGetMonikerPos

SYNOPSIS:	Like VisGetMonikerPos, except fills in specific UI's text 
		height.

CALLED BY:	utility

PASS:	*ds:si - instance data
	*es:bx - moniker to draw   (if bx = 0, then nothing drawn)
	cl - how to draw moniker: MatrixJustifications
	ss:bp  - DrawMonikerArgs
	
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/22/91		Initial version

------------------------------------------------------------------------------@

SpecGetMonikerPos	proc	far
	call	GetSystemFontHeight		;pass system font height
	mov	ss:[bp].DMA_textHeight, ax		
	call	VisGetMonikerPos
	ret
SpecGetMonikerPos	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSystemFontHeight

SYNOPSIS:	Returns system font height.

CALLED BY:	SpecDrawMoniker, SpecGetMonikerSize, SpecGetMonikerPos

PASS:		*ds:si -- some kind of object, hopefully.

RETURN:		ax -- system text height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/23/91		Initial version
	Doug	4/92		Split out CalcAndCacheSystemFontHeight so
				could be called from other resource if cached
				value not around

------------------------------------------------------------------------------@

GetSystemFontHeightFar	proc	far
	call	GetSystemFontHeight
	ret
GetSystemFontHeightFar	endp

GetSystemFontHeight	proc	near
	push	es
	mov	ax, segment idata		;ds points at idata
	mov	es, ax
	mov	ax, es:[systemFontHeight]	;is there a char width around?
	tst	ax
	pop	es
	jz	initCache
	ret

initCache:
	call	CalcAndCacheSystemFontHeight
	ret
GetSystemFontHeight	endp



CalcAndCacheSystemFontHeight	proc	far	uses	cx, dx, bp, si, di, es
	.enter
	call	ViewCreateCalcGState
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED	;si <- info to return, rounded
	call	GrFontMetrics			;dx -> height
	mov	ax, dx				;return in ax
	call	GrDestroyState
	mov	dx, segment idata
	mov	es, dx
	mov	es:systemFontHeight, ax		;and set in instance data
	.leave
	ret
CalcAndCacheSystemFontHeight	endp

Utils ends

;----------

Resident segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecGetMonikerSize

SYNOPSIS:	Like VisGetMonikerSize, except passes the specific UI's text 
		height.

CALLED BY:	utility

PASS:	
	*ds:si - instance data for object
	*es:di - moniker (if di=0, returns size of 0)
	bp - graphics state (containing font and style) to use

		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/22/91		Initial version
	Doug	4/92		Moved to Resident after discovering >1000
				calls here when launching planner, using menus

------------------------------------------------------------------------------@

SpecGetMonikerSize	proc	far
	push	es
	mov	ax, segment idata		;ds points at idata
	mov	es, ax
	mov	ax, es:[systemFontHeight]	;check for cached height
	tst	ax
	pop	es
	jz	initCache
gotIt:
	call	VisGetMonikerSize
	ret

initCache:
	call	CalcAndCacheSystemFontHeight
	jmp	short gotIt

SpecGetMonikerSize	endp

Resident ends

