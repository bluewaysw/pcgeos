COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		bannerDraw
FILE:		bannerDraw.asm

ROUTINES:

Name				Description
----				-----------
BannerRemoveAnyTimer............If banner has a timer, remove it
BannerUpdate....................Resizes and redisplays the banner
BannerTextEditClean.............Handles the text object becoming dirtied.
BannerUpdateIfStillDirty........Causes preview to redraw by invalidating it.
BannerScreenDraw................Sets up the call to BannerDraw
BannerStringWalk................Find character just before view's origin
BannerDraw......................Draw the banner
BannerRecalcSize................Returns the size of the banner doc.
BannerStringHeight..............Calculates height of the string from font data
BannerMaximizeTextHeight........Pick a point size to fit text to desired height
BannerCalcTextWidth.............Calculate the width of the text.
DrawTractorHoles................Draws the tractor holes to the banner view
DrawPerforations................Draws perforations to the banner view
BannerDrawBorder................Draws a border and shrinks text boundaries.
DrawShadow......................Draws either a large or small shadow.
Draw3D..........................Draws the text with the 3-d effect.
DrawFog.........................Draws the text with the fog effect.

METHOD HANDLERS:

Name				Description
----				-----------

MSG_TEXT_MADE_DIRTY		 --BannerTextEditClean 		(see above)
MSG_VIS_RECALC_SIZE		 --BannerRecalcSize		(see above)
MSG_BANNER_UPDATE_IF_STILL_DIRTY --BannerUpdateIfStillDirty	(see above)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	10/10/90	Initial version, cut from banner.asm
	stevey	10/19/92	port to 2.0

DESCRIPTION:
	This file contains the code involving the preview, including all
	code for the view, when to draw, and how to draw it.  This file
	is included by banner.asm.

	Note:  I nuked all the "Draw<effect>UsingMasks" because Don &
	Jim think we don't need them anymore.  stevey 3/9/93

	$Id: bannerDraw.asm,v 1.1 97/04/04 14:37:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerRemoveAnyTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes any timer if the banner has a handle to one.

CALLED BY:	BannerUpdateIfStillDirty, BannerUpdate

PASS:		*ds:si	= instance data of a banner object
		ds:[di]	= specific instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	if BI_timerHandle isn't 0, call TimerStop to remove it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/ 2/90	Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerRemoveAnyTimer	proc	near
	class	BannerClass
	uses	ax, bx
	.enter

	;
	; remove the timer if the handle is nonzero
	;

	clr	bx
	xchg	bx, ds:[di].BI_timerHandle
	tst	bx
	jz	noTimer

	mov	ax, ds:[di].BI_timerID
	call	TimerStop				; remove it

noTimer:
	.leave
	ret
BannerRemoveAnyTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes and redisplays the banner

CALLED BY:	BannerSetFonts, BannerSetSpecialEffects, BannerTextEditClean

PASS:		*ds:si	= instance data for object
		bl = update mode (UPDATE_NOW or not UPDATE_NOW)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are two ways updating gets done: UPDATE_NOW and not UPDATE_NOW.
	Not UPDATE_NOW is for when the user is typing.  The update waits
	two seconds after the user finishes before redrawing the screen.  This
	is long enough for most hunt and peck typists to find keys and to
	edit.  UPDATE_NOW is for when a font or special effect is selected.
	The user wants to see the effects now, and then select another one.

	Even UPDATE_NOW isn't truly instaneous.  If the user is fast it's
	outrageous to make them wait for a redraw.  So we employ the following
	scheme:

	Redrawing isn't done immediately.  We want to avoid redrawing the
	preview every time a key is typed, so when a change is made we
	place the redraw at the end of the queue.  If there any other
	changes already on the queue then those will be made before the
	redraw.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerUpdate	proc	near
	class	BannerClass
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	di, ds:[si]			; dereference instance data
	add	di, ds:[di].Banner_offset

	;
	; Don't redraw just yet.  Put on the end of the queue.  If there are
	; any other changes on the queue those will be made before the redraw
	; is done.
	;

	call	BannerRemoveAnyTimer

	cmp	bl, UPDATE_NOW
	je	updateNow

	GetResourceHandleNS	TheBanner, bx
	mov	si, offset 	TheBanner	; ^lbx:si = destination
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, PREVIEW_UPDATE_DELAY
	mov	dx, MSG_BANNER_UPDATE_IF_STILL_DIRTY
	call	TimerStart

	mov	ds:[di].BI_timerHandle, bx
	mov	ds:[di].BI_timerID, ax		; needed for TimerStop

	jmp	short	done

updateNow:

	GetResourceHandleNS	TheBanner, bx
	mov	si, offset 	TheBanner
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_BANNER_UPDATE_IF_STILL_DIRTY
	call	ObjMessage
done:
	.leave
	ret
BannerUpdate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerTextEditClean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure is called by BannerTextEdit when text is
		typed and the text object becomes dirty.

CALLED BY:	MSG_META_TEXT_USER_MODIFIED

PASS:		*ds:si	= banner object
		ds:[di] = banner instance data
		cx:dx	= text object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	Act on the change by calling BannerUpdate and clean BannerTextEdit's
	dirty bit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	6/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerTextEditClean	method		BannerClass, 
				MSG_META_TEXT_USER_MODIFIED
	;
	;  Notify BannerMaximizeTextHeight that things have changed.
	;

	clr	ds:[di].BI_lastMaximizedHeight
	BitSet	ds:[di].BI_bannerState, BS_TEXT_DIRTY

	GetResourceHandleNS	BannerTextEdit, bx
	mov	si, offset	BannerTextEdit
	;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	ObjMessage

	mov	si, offset TheBanner		; restore *ds:si = banner
	mov	bl, not UPDATE_NOW
	call	BannerUpdate

	ret
BannerTextEditClean	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerUpdateIfStillDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This redraws the preview by invalidating it if the
		banner is dirty.

CALLED BY:	MSG_BANNER_UPDATE_IF_STILL_DIRTY

PASS:		*ds:si	= instance data
		ds:[di]	= instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerUpdateIfStillDirty 	method		BannerClass, 
				MSG_BANNER_UPDATE_IF_STILL_DIRTY
	uses	ax, cx, dx, bp
	.enter

	call	BannerRemoveAnyTimer

	test	ds:[di].BI_bannerState, mask BS_TEXT_DIRTY or \
		mask BS_CONTROLS_DIRTY
	LONG_EC	jz	done
	
	test	ds:[di].BI_bannerState, mask BS_CONTROLS_DIRTY
	jz	redraw

	mov	ax, ds:[di].BI_specialEffects
	cmp	ds:[di].BI_lastSpecialEffects, ax
	je	previewCorrect

	mov	ds:[di].BI_lastSpecialEffects, ax

redraw:	
	push	ds:[LMBH_handle], si
	
	mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	pop	bx, si
	call	MemDerefDS

	mov	di, ds:[si]
	add	di, ds:[di].Banner_offset

previewCorrect:
	andnf	ds:[di].BI_bannerState, not \
		(mask BS_TEXT_DIRTY or mask BS_CONTROLS_DIRTY)
done:
	.leave
	ret
BannerUpdateIfStillDirty	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerScreenDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This draws the preview by setting up the call to BannerDraw.
		The banner is drawn all in one section.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= instance data
		bp	= gstate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerScreenDraw	method	BannerClass, 		MSG_VIS_DRAW
	uses	ax, cx, dx
	.enter

	call	BannerGetTextString	; dx = block handle, cx = length
					
	tst	cx			; do we have any text?
	jnz	textExists

	mov	bx, dx			; free the text block
	call	MemFree
	jmp	done

textExists:

	push	dx			; save string handle to free later
	call	BannerSetFontDetails	; set the font size

	;
	;  Get ds:0 pointing to the string, and es:[di] pointing to instance
	;

	segmov	es, ds, ax		; es:[di] = banner object
	mov	bx, dx
	call	MemLock
	mov	ds, ax			; ds:0 = text string

	;
	;  GrDrawText draws the whole string, even parts that aren't 
	;  visible in the view.  For speed we only draw the visible parts.
	;  First we find out where the view origin is.  Then we use
	;  BannerStringWalk to find the character just before the origin.
	;  Then we walk a distance greater than the view width.  Then we
	;  pass the characters and offset to BannerDraw.
	;
	;  We used to call WinGetMaskBounds (in version 1.2).  This call
	;  no longer exists; it has been replaced with GrGetMaskBounds,
	;  and I couldn't find out whether the new routine takes the
	;  same args as the old one, and whether it returns the same
	;  stuff.  I hope it does.
	;

	xchg	di, bp			; di = gstate, bp = instance
	call	GrGetMaskBounds
	xchg	di, bp			; bp = gstate, di = instance

	;
	;  We save the left and right bounds to calculate the length later.
	;  After we calculate the character to start at, we need to know
	;  how far to walk.  The simple way to find a distance is to use
	;  the right side minus the left side.  However, if the first 
	;  character starts in the middle during a full preview update, 
	;  then the last character included will be way past the end of 
	;  the preview.  A better way is to use the right side minus the 
	;  position of the leftmost character as returned by the first 
	;  walk.  This is what we do.  Note, to ensure overhangs, we add 
	;  in an EndSpace onto each end.
	;

	push	ax			; save the left edge.  If we are at
					; the left edge then we can avoid
					; the overlap on the left side

	push	cx			; save the right side

	sub	ax, es:[di].BI_borderWidth
	sub	ax, es:[di].BI_endSpace

	;
	;  Ensure there is enough overlap to handle overhangs from LSB/RSBs
	;  for now we just use BI_endSpace for the amount.
	;

	sub	ax, es:[di].BI_endSpace

	clr	bh			; fractional section length
	mov	bl, ROUND_DOWN		; when to stop
	mov	cx, bp			; cx <- graphics state
	clr	dx			; startPtr
	call	BannerStringWalk

	add	ax, es:[di].BI_borderWidth
	add	ax, es:[di].BI_endSpace
	neg	ax

	mov	es:[di].BI_leaderWidth, ax
SBCS<	mov	es:[di].BI_charStart, dl	; store byte offset	>
DBCS<	mov	es:[di].BI_charStart, dx	; store byte offset	>

	;
	;  We want to walk the string as far as the view's width.
	;  Calculate the length of the portion to be redrawn on the screen.
	;

	pop	bx			; restore right side
	add	bx, ax			; ax is negative so this is a subtract

	;
	;  Extend the area to allow a character before and after to be 
	;  included, unless we're at the start of the string, in which case
	;  we don't need to leave room for a character of overlap before
	;  the string start.
	;

	pop	ax			; restore left side
	tst	ax
	mov	ax, es:[di].BI_endSpace
	jz	noOverlapOnLeftEdge
	shl	ax, 1			; one left, one right

noOverlapOnLeftEdge:

	shl	ax, 1			; double EndSpace into widest char
	add	ax, bx

	clr	bh
	mov	bl, ROUND_UP
	call	BannerStringWalk
if DBCS_PCGEOS
	sub	dx, es:[di].BI_charStart	; dx <- string size
	shr	dx, 1				; dx <- string length
	mov	es:[di].BI_charLength, dx
else
	sub	dl, es:[di].BI_charStart
	mov	es:[di].BI_charLength, dl
endif
	
	;
	;  We don't want to print; we want to display.
	;

	BitClr	es:[di].BI_bannerState, BS_PRINT

	mov	es:[di].BI_yOffset, HOLE_AREA	; offset for tractor holes
	clr	ax
	mov	es:[di].BI_xOffset, ax		; offset for gray space

	;
	;  The preview is drawn as one section because the graphics 
	;  system can handle it.  Therefore, both borders are drawn now.
	;

	ornf	es:[di].BI_bannerState, mask BS_DRAW_LEFT_BORDER or \
		mask BS_DRAW_RIGHT_BORDER

	call	BannerDraw

	;
	; free the text string
	;

	pop	bx			; pushed as dx - mem handle
	call	MemFree			; done with the text block

done:
	.leave
	ret
BannerScreenDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerStringWalk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the character just before the view's origin.

CALLED BY:	GLOBAL

PASS:		ds:0	= the text string
		cx 	= the graphics state
		dx	= startPtr
		ax.bh	= section length limit (in doc size, WBFixed)
		bl	= when to stop (ROUND_UP/ROUND_DOWN)

RETURN: 	dx	= endPtr		(points one beyond end)
		ax.bh	= section_length	(WBFixed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

result BannerStringWalk(char start_ptr, WBFixed string_length_limit, byte 
	when_to_stop, var char *end_ptr, var WBFixed string_length)
{
	char    *current_ptr;

	current_ptr = space_ptr = start_ptr;
	string_length = 0;
	do {
		if (*current_ptr == '\0' or current_ptr < 0) {
			end_ptr = current_ptr + direction;
			break;
		}
		string_length += char_width(*current_ptr);
		if (string_length > string_length_limit) {
			string_length -= char_width(*current_ptr);
			end_ptr = space_ptr;
			break;
		}
		current_ptr += direction;
	} while (TRUE);
}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	8/16/90		Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerStringWalk	proc	near
	uses	cx, di, si

	stringLimit	local	WBFixed		; limit in points
	stringLength	local	WBFixed 	; length in points

	.enter

	;
	;  Set up the local vars, etc
	;

	movwbf	stringLimit, axbh
	clrwbf	stringLength
	mov	di, cx			; gstate
	mov	si, dx			; start ptr

loopStart:
	;
	;  This is the start of the loop which walks through a string 
	;  until the string width is as long as the requested width.
	;
	LocalLoadChar	ax, ds:[si]	; don't use lodsb -- sometimes no inc.
	LocalCmpChar	ax, C_NULL	; stop if we run out of characters.
	LONG_EC	je	done

	;
	;  Calculate the string length.
	;

SBCS<	clr	ah				; no double-byte chars	>
	call	GrCharWidth
	addwbf	stringLength, dxah
	mov	cx, stringLength.WBF_int

	;
	;  Check to see if we have walked far enough since adding
	;  the last character.
	;

	cmp	cx, stringLimit.WBF_int
	jl	nextChar
	jg	enoughChars
	mov	ch, stringLength.WBF_frac
	cmp	ch, stringLimit.WBF_frac
	jg	enoughChars

nextChar:
	LocalNextChar	dssi
	jmp	loopStart

enoughChars:
	;
	;  The last character added was wide enough that we now have
	;  enough characters.  Now we must determine if we want to keep
	;  the last character as part of the string to show (ROUND_UP)
	;  or just use the characters before it (ROUND_DOWN), by 
	;  subtracting its width from stringLength
	;
	;  bl is either ROUND_UP or ROUND_DOWN; it has not been changed since
	;  the beginning.  This also means that bl is not LAST_SECTION.
	;

	cmp	bl, ROUND_UP
	je	roundUp

	subwbf	stringLength, dxah
	jmp	short	done

roundUp:
	;
	;  When rounding up we want to point to the next character.
	;
	LocalNextChar	dssi

done:
	;
	;  dx points to the character after the last one on the string.
	;  This is so that the equation, (start-end), returns the number
	;  of characters and so that dx points to the character to start
	;  with the next time.
	;

	mov	dx, si
	movwbf	axbh, stringLength		; ax.bh = pixel width

	.leave
	ret
BannerStringWalk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the banner

CALLED BY:	BannerSampleOutput, BannerPrint

PASS:		*es:si	= banner object
		es:[di]	= banner instance data
		ds:0	= string
		bp	= gstate to draw to	

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Get the text string
	- if none exists exit
	- if to the screen then draw perforations and tractor holes
	- draw a border
	- draw a special effect
	- draw the text in black

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	6/27/90		Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerDraw	proc	near
	class	BannerClass
	uses	ax, bx, cx, dx, si, di
	.enter

	mov	cx, es:[di].BI_width	; the paper width
	mov	dx, es:[di].BI_height	; the paper height

	;
	;  ax	the left side of the document
	;  bx	the top side of the document
	;  ax & bx are not set yet
	;  cx	the right side of the document
	;  dx	the bottom side of the document
	;

	xchg	di, bp			; switch gstate with instance data

	;
	;  Skip the following if printing...
	;

	test	es:[bp].BI_bannerState, mask BS_PRINT
	LONG_EC	jnz	doneScreenExtras

	;
	;  Draw a white rectangle to show where the paper is.
	;

	mov	ax, (CF_INDEX shl 8 or C_WHITE)
	call	GrSetAreaColor

checkpoint1::

	mov	ax, es:[bp].BI_xOffset
	clr	bx			; ignore Y offset - make white there
	add	cx, es:[bp].BI_xOffset
	add	dx, es:[bp].BI_yOffset	; add twice - two tractor hole areas
	add	dx, es:[bp].BI_yOffset
	call	GrFillRect

	mov	cx, es:[bp].BI_width	; the paper width
	mov	dx, es:[bp].BI_height	; the paper height

	;
	;  Reset the area color to black for the text.
	;

	mov	ax, (CF_INDEX shl 8 or C_BLACK)
	call	GrSetAreaColor

	call	DrawPerforations
;	call	DrawTractorHoles

doneScreenExtras:
	;
	;  Here's the stuff we do whether printing or not.
	;

	mov	ax, (CF_INDEX shl 8 or C_BLACK)
	call	GrSetLineColor

	test	es:[bp].BI_specialEffects, mask SE_THIN_BOX \
		or mask SE_THICK_BOX \
		or mask SE_DOUBLE_BOX
	jz	doneOutline
	call	BannerDrawBorder

doneOutline:					; get ready to draw
	;
	; make rgb values legal
	;
	mov	al, CMT_DITHER
	call	GrSetTextColorMap

	;
	; ax gets the x offset of the text and bx gets the y offset
	;
	mov	ax, es:[bp].BI_xOffset		; start at the offset
	sub	ax, es:[bp].BI_leaderWidth
	
	;
	; done Left Border Width
	;
	mov	bx, es:[bp].BI_yOffset		; start at the offset
	add	bx, es:[bp].BI_borderWidth
	sub	bx, es:[bp].BI_textOffset

	;
	;  Point si at the first character of the string,
	;  (and cx gets how many to draw)
	;
if DBCS_PCGEOS
	mov	si, es:[bp].BI_charStart
	mov	cx, es:[bp].BI_charLength	; cx = string length
else
	clr	ch
	mov	cl, es:[bp].BI_charStart
	mov	si, cx
	mov	cl, es:[bp].BI_charLength
endif

	;
	;  If we're doing shadowing we draw the text twice.  The first time
	;  the text is lighter and offset down and to the right.  The 
	;  second time the text is drawn where it would normally appear.
	;

	test	es:[bp].BI_specialEffects, mask SE_SMALL_SHADOW or \
		mask SE_LARGE_SHADOW
	jz	drawThreeD

	call	DrawShadowUsingRGB	; use RGB for postscripting
	jmp	short	readyToDraw

drawThreeD:
	test	es:[bp].BI_specialEffects, mask SE_THREE_D
	jz	drawFog

	call	DrawThreeDUsingRGB	; use RGB for postscripting
	jmp	short	readyToDraw

drawFog:
	test	es:[bp].BI_specialEffects, mask SE_FOG
	jz	readyToDraw

	call	DrawFogUsingRGB		; use RGB for postscripting
	jmp	short	readyToDraw

readyToDraw:
	; (ax, bx) = (x, y) position
	; cx = # of characters
	; ds:si = string to draw
	; di = gstate
	; es = object block segment
	call	GrMoveTo
	clr	dx, ax
	mov	bx, si
loopDraw:
	jcxz	done
	mov	dl, ds:[si]
	call	BannerSetCharColor
	call	GrDrawCharAtCP
	dec	cx
	inc	si
	incdw	axbx
	jmp	loopDraw
done:
	mov	bp, di			; save the gstate

	mov	al, CMT_CLOSEST
	call	GrSetTextColorMap

	.leave
	ret
BannerDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetCharColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the character drawing color.

CALLED BY:	BannerDraw

PASS:		es	= object block segment
		dl	= character to draw
		di	= gstring

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	1/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetCharColor		proc	near
charAttr	local	VisTextCharAttr
getParams	local	VisTextGetAttrParams
diffs		local	VisTextCharAttrDiffs
	uses ax, bx, cx, dx, di, bp, si
	.enter

	movdw	getParams.VTGAP_range.VTR_start, axbx
	movdw	getParams.VTGAP_range.VTR_end, TEXT_ADDRESS_PAST_END

	lea	ax, charAttr
	movdw	getParams.VTGAP_attr, ssax
	lea	ax, diffs
	movdw	getParams.VTGAP_return, ssax
	clr	getParams.VTGAP_flags
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR

	push	es:[LMBH_handle]
	push	bp, di
	lea	bp, getParams
	mov	dx, size getParams
	mov	di,  mask MF_CALL or mask MF_STACK
	GetResourceHandleNS	BannerTextEdit, bx
	mov	si, offset BannerTextEdit
	call	ObjMessage
	pop	bp, di
	pop	bx
EC <	call	ECCheckMemHandle					>
	call	MemDerefES

	lea	si, charAttr.VTCA_color
	mov	ah, ss:[si].CQ_info
	mov	al, ss:[si].CQ_redOrIndex
	mov	bl, ss:[si].CQ_green
	mov	bh, ss:[si].CQ_blue
	call	GrSetTextColor

	clr	ax
	mov	al, charAttr.VTCA_grayScreen
	call	GrSetTextMask
	.leave
	ret
BannerSetCharColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called to calculate the size of the banner doc for
		the ui.  
	
CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	- instance data
		cx	= suggested width	(RecalcSizeArgs)
		dx	= suggested height	(RecalcSizeArgs)

RETURN:		cx	- width
		dx	- height

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:	

	Set up for the screen case and call BannerMaximizeTextHeight

	The ui passes a suggested size which we use.  This allows different-
	sized banners for different screen types.

	This takes the height passed and scales the text to be as large as 
	possible (BannerMaximizeTextHeight).  From the text's point size
	it then calculates the length needed for the banner and calculates
	the horizontal width of the banner doc which is off of the View.  
	So the height sets the width.

	The whole reason for this procedure's existence is that the
	text in the banner (on screen) needs to be drawn to be as tall
	as the view.  Since the primary is resizable, we need to call
	BannerMaximizeTextHeight to set the point size correctly.  -steve

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerRecalcSize	method	BannerClass, 	MSG_VIS_RECALC_SIZE
	.enter

	;
	;  Normally RSA_CHOOSE_OWN_SIZE will be passed in dx, and we
	;  use the passed size.  If not, we use the banner's visual
	;  height (VCNI_viewHeight).
	;

	test	dx, mask RSA_CHOOSE_OWN_SIZE
	jz	suggestedHeight

	mov	di, ds:[si]			; dereference instance data
	add	di, ds:[di].Vis_offset		; get to vis stuff
	mov	dx, ds:[di].VCNI_viewHeight	; dx <- old height
	jmp	short 	gotHeight

suggestedHeight:
	;
	;  Make sure we're no smaller than the minimum allowable size.
	;
	cmp	dx, MINIMUM_SIZE
	jge	gotHeight
	mov	dx, MINIMUM_SIZE	; don't be smaller than this

gotHeight:
	sub	dx, 2 * HOLE_AREA	; subtract space for tractor holes

	clr	di			; no window to pull from
	call	GrCreateState
	mov	bp, di			; save gstate

	mov	di, ds:[si]		; dereference instance data again
	add	di, ds:[di].Banner_offset

	call	BannerMaximizeTextHeight; dx = height
	call	BannerCalcTextWidth	; cx = width
	tst	bx			; handle to block w/ text string
	jz	textFreed
	call	MemFree

textFreed:
	;
	;  Add space for the tractor holes to the calculated height.
	;
	add	dx, 2 * HOLE_AREA

	mov	di, bp
	call	GrDestroyState

	.leave
	ret
BannerRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerStringHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the max y and min y of the string using the 
		font in the passed gstate.  Measures accent marks.
		Takes underline into account if TS_UNDERLINE is set.

CALLED BY:	INTERNAL

PASS:		*ds:si	= banner object
		ds:[bp]	= BannerInstance
		di	= gstate handle with the font and text styles set

RETURN: 	cx.bl	= max y (WBFixed)
		dx.bh	= min y (WBFixed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the text string
	- loop:
	  * get next character
	  * check highest & lowest points against stored highest & lowest,
	    & update current highest & lowest if necessary.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	12/3/90		Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerStringHeight	proc	near
	class	BannerClass
	uses	ax,si,di,bp,es
	.enter

	;
	; To avoid problems with performing calculations with bitmap
	; fonts, we perform a horrible hack. We set the point size
	; to be <integer> - 1/256, thus guaranteeing that hand-tuned
	; bitmaps will never be chosen by the font driver. We reset
	; the value at the bottom of this routine.
	;

	call	GrGetFont		; FontID -> cx, pointsize -> dx.ah
	pushdw	dxax			; save the pointsize
	dec	dx
	dec	ah			; subtract 1/256 of a point
	call	GrSetFont		; reset font size

	push	ds:[LMBH_handle]

	call	BannerGetTextString	; to determine the width

	segmov	es, ds, ax		; es:[bp] = instance
	mov	si, bp 			; es:[si] = instance
	mov	bx, dx
	call	MemLock
	mov	ds, ax			; ds:0 = text string

	tst	cx			; cx = string length
	jnz	textExists

	;
	;  no text => set the values to zero and leave
	;

	clr	bx, cx, dx
	jmp	done

textExists:
	push	dx			; save the text handle to free later

	clr	bx
	mov	cx, MIN_COORD		; current maximum
	mov	bp, MAX_COORD		; current minimum

	test	es:[si].BI_specialEffects, mask TS_UNDERLINE
	jz	noUnderline

	;
	; make the underline the minumum position
	; GFMI_UNDER_POSITION returns the distance from the top of the
	; character box.  We want the position in reference to the 
	; baseline.
	;

	mov	si, GFMI_BASELINE
	call	GrFontMetrics			; dx.ah = baseline offset
	mov	bh, ah
	mov	bp, dx

	mov	si, GFMI_UNDER_POS		; offset to underline
	call	GrFontMetrics
	sub	bh, ah
	sbb	bp, dx

	mov	si, GFMI_UNDER_THICKNESS 	; thickness of underline
	call	GrFontMetrics
	sub	bh, ah
	sbb	bp, dx				; bp = current minimum

noUnderline:

	clr	si			; start at the first character

loopStart:
	LocalLoadChar	ax, ds:[si]	; al = current character

	;
	;  stop if we run out of characters and signal the end.
	;
	LocalCmpChar	ax, C_NULL	; EOS if '\0' character
	je	loopDone

	push	si			; save pointer into string
	mov	si, GCMI_MAX_Y		; get maximum height into
SBCS<	clr	ah			; ax = character		>
DBCS <	push	ax			; save DBCS char		>
	call	GrCharMetrics		; dx.ah = height
EC <	ERROR_C	NO_FONT_OR_DRIVER_AVAILABLE_FOR_METRICS_CALC		>
DBCS <	pop	si			; si = DBCS char		>
	cmp	cx, dx			; cx is current max.  is dx greater?
	jg	notNewMax		; nope, cx is still the max
	jl	newMax			; yep, dx is greater
	cmp	bl, ah			; equal integer parts...test fractions
	jge	notNewMax		; cx.bl > dx.ah
newMax:
	mov	cx, dx
	mov	bl, ah

notNewMax:

DBCS <	mov	ax, si			; ax = DBCS character		>
	mov	si, GCMI_MIN_Y
SBCS<	clr	ah			; ax = character		>
	call	GrCharMetrics		; dx.ah = minimum y
EC <	ERROR_C	NO_FONT_OR_DRIVER_AVAILABLE_FOR_METRICS_CALC		>
	cmp	bp, dx
	jl	notNewMin
	jg	newMin
	cmp	bh, ah
	jle	notNewMin

newMin:
	mov	bp, dx
	mov	bh, ah

notNewMin:

	pop	si			; restore pointer into string,
	LocalNextChar	dssi		;  and increment it for next char
	jmp	loopStart

loopDone:
	;
	; put the values where they are expected to be returned
	;
	mov	dx, bp			; min height

	;
	; free the message string
	;
	mov_tr	ax, bx			; save fractional heights
	pop	bx			; bx <- text block handle
	call	MemFree			; (the block can be locked)

done:
	pop	bx			; pushed at top, as ds:[LMBH_handle]
	call	MemDerefDS		; *ds:si = banner, on return
	mov_tr	bx, ax			; restore fractional heights

	;
	; Now clean up after our pointsize hack. We need to preserve
	; BX, CX & DX, as they hold valuable information, but we cannot
	; use the stack.
	;

	mov	si, cx
	mov	bp, dx
	clr	cx			; use current font
	popdw	dxax			; font size -> dx.ah
	call	GrSetFont		; return size to previous
	mov	cx, si
	mov	dx, bp

	.leave
	ret
BannerStringHeight	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerMaximizeTextHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a desired height for the text, set the point size so
		that the TextEdit string just fits in the desired size.

CALLED BY:	BannerRecalcSize

PASS:		*ds:si	= instance data for object
		ds:[di]	= specific instance data for the object
		dx	= desired height
		bp	= gstate handle

		BI_fontID = the font ID to use

RETURN:		dx	= the banner height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- calculate the border's width
		- to do this, calculate what a quarter inch is
	- make the point size smaller if using fog or 3D effect
	- scale to fit
		- calculate ratio of text height at current point size to
		  desired height to calculate a new point size

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Initializes:

	BI_lastMaximizedHeight
	BI_height
	BI_pointSize	=	the point size
	BI_borderWidth
	BI_borderLineWidth
	BI_quarterInch

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	7/90		initial version
	roger	10/2/90		Updated for speed
	stevey	10/19/92	port to 2.0
	witt	11/4/93		Added division overflow protection

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerMaximizeTextHeight	proc	near
	class	BannerClass
	uses	ax, bx, cx, si, es
	.enter

	;
	;  Save the passed paper size (that is, the size of the paper
	;  as seen on the screen...it could be very small).  Then check
	;  to make sure it's not the same as last time, and if it is,
	;  just quit.
	;

	mov	ds:[di].BI_height, dx		; save the paper's size

	cmp	dx, ds:[di].BI_lastMaximizedHeight
	LONG	je	done			; don't bother if same

	;
	;  Actually maximize the height...
	;
	mov	ds:[di].BI_lastMaximizedHeight, dx
	mov	ax, dx

	;
	;  ax is the page height.  If we were called by BannerRecalcSize
	;  then it's the view height minus space for the tractor holes.
	;  Otherwise we were called by BannerPrint and it's the actual
	;  page height (with the page turned sideways, so it should be
	;  8 inches, not 11.)  We use this height for the text's point
	;  size, but need to make the point size slightly smaller to 
	;  adjust for the border and possibly an outline.  See BORDERS 
	;  in the header of banner.asm for the widths of the different 
	;  border types.
	;

	mov	cl, 34			; a QUARTER_INCH is 1/34th 
	div	cl			;  of the page height. 
	clr	ah			; ax = QUARTER_INCH; clear remainder

	;
	;  if no border, then BorderWidth is 2 * QUARTER_INCH (and we
	;  skip the other calculations).
	;

	test	ds:[di].BI_specialEffects, \
			mask SE_THIN_BOX or \
			mask SE_THICK_BOX or \
			mask SE_DOUBLE_BOX
	jz	doneBorderSpace

	mov	ds:[di].BI_quarterInch, ax
	mov	bx, ax			; bx = QUARTER_INCH

	;
	; set the line thickness based on the current border
	;

	mov	cl, 3
	test	ds:[di].BI_specialEffects, mask SE_THIN_BOX
	jnz	calcBorderSpace
	mul	cl			; both are 3/4" thick, so ax *= 3
					; ax = border line thickness
calcBorderSpace:

	mov	ds:[di].BI_borderLineWidth, ax

	;
	; we need a 1/4" for a space outside the border and 1/2" for the space
	; between the border and the text area
	;

	xchg	ax, bx			; prep for mul quarter inch * 3
	mul	cl			; borderspace 3/4"
	add	ax, bx			; plus borderline width = borderwidth

doneBorderSpace:

	mov	ds:[di].BI_borderWidth, ax

	sub	dx, ax			; subtract top border from height
	sub	dx, ax			; subtract bottom border from height

	;
	;  dx is the height between the borders where the text appears.  
	;  This is what we use for the text's point size.
	;

	xchg	di, bp			; swap the gstate with instance data

	push	dx			; save the specified point size
	push	dx			; ...twice

	;
	;  Set the gstate's font and point size so we can get the
	;  height of the tallest character at these settings
	;

	clr	ah			; clear the point size fraction
	mov	cx, ds:[bp].BI_fontID	; typeface
	call	GrSetFont		; sets the font & size

	;
	;  Set the text style.  Only the following three styles may be
	;  set from here.  All other bits must be masked out because they
	;  are used differently by banner.
	;

	mov	ax, ds:[bp].BI_specialEffects
	andnf	al, mask TS_BOLD or mask TS_ITALIC or mask TS_UNDERLINE
	mov	ah, al			; unset the other bits
	not	ah
	call	GrSetTextStyle

	;
	;  From here to scale for effects, we find a point size at which 
	;  the banner message exactly fills the height allotted.  We start
	;  by measuring the string's height using the current font &
	;  text style.
	;

	call	BannerStringHeight	; cx.bl = max y, dx.bh = min y
	subwbf	cxbl, dxbh		; subtract min from max
	jnz	textExists		; or if only spaces are returned

noText::
	;
	;  I believe that the returned value of the text height is 
	;  supposed to be the same as that passed.  So, pass the value 
	;  right on through even though there isn't any text
	;
	pop	cx			; no text!  Is this visible?
	push	cx

textExists:
	;
	;  At this point we want bx.ah to be the height of the string in 
	;  the current font and dx.ch to be the point size.  Remember that 
	;  the actual font height != the point size.  So we use the ratio 
	;  between the two to calculate what point size is needed to print 
	;  out at a specific text height.
	;

	mov	ah, bl
	clr	al
	mov	bx, cx			; the font height
	pop	dx			; the point size
	clr	cx

	call	GrUDivWWFixed
	pop	bx			; the point size
	clr	ax			; no fraction
	call	GrMulWWFixed

	;
	;  dx is the now scaled point size. From here until knowTextArea 
	;  we rescale for any special effects
	;

	test	ds:[bp].BI_specialEffects, mask SE_SMALL_SHADOW or \
		mask SE_LARGE_SHADOW
	jz	checkOtherEffects

	mov	ax, dx
	test	ds:[bp].BI_specialEffects, mask SE_SMALL_SHADOW 
	jz	setLargeShadow

	mov	cl, SMALL_SHADOW_OFFSET_RATIO + 1	
	jmp	short	divide

setLargeShadow:

	mov	cl, LARGE_SHADOW_OFFSET_RATIO + 1

divide:
DBCS<	cmp	ah, cl							>
DBCS<	jnb	tooBigDivision		; abort, divide will overflow!	>
	div	cl
	clr	ah
DBCS< recoverDivide:						>
	sub	dx, ax

	;
	;  The code can sometimes lose a pixel.  Play safe and chop a pixel.
	;

	dec	dx
	jmp	knowTextArea

if DBCS_PCGEOS
	;
	;	Something is wrong, like the font height isn't big enough
	;	and the division isn't large enough.  This is really hacked
	;	in the case that the only font is Berkeley 10pt (fixed
	;	width, bitmap font) that just won't scale.
	;					--- brian witt, Dec 1993
	;
tooBigDivision:
	WARNING	MAXIMIZE_TEXT_TOOK_DIVIDE_OVERFLOW
	mov	ax, 00feh		; very big, but not overflowing..
	jmp	recoverDivide
endif

checkOtherEffects:
	;
	;  If we have fog or a threeD effect we need to leave room for
	;  these so they don't overwrite the borders.
	;

	test	ds:[bp].BI_specialEffects, mask SE_FOG or mask SE_THREE_D
	jz	knowTextArea

	;
	;  When text is drawn with fog or 3D, the effect extends below the 
	;  text, so the text should be shrunk to make room for the effect.  
	;  If p is the pointsize and r is FOG_AND_3D_OFFSET_RATIO then 
	;  8(p/r + 1) is the height of the effect (8 shades) (+1 at least 1!)
	;  If we also have y as the current height available then
	;  p + 8(p/r + 1) = y.
	;
	;  rearrange to get p = r(y - 8) / (r+8)
	;

	sub	dx, SHADES_COUNT
	clr	cx				; dx = height available
	mov	bx, FOG_AND_3D_OFFSET_RATIO + SHADES_COUNT
	clr	ax
	call	GrUDivWWFixed

	mov	bx, FOG_AND_3D_OFFSET_RATIO	; ax already clr
	call	GrMulWWFixed

	;
	;  The code can sometimes lose a pixel.  Play safe and chop a pixel.
	;
	dec	dx

knowTextArea:
	;
	;  Make sure the calculated point size doesn't overflow the 
	;  graphics system.
	;

	cmp	dx, MAX_POINT_SIZE * 4	; maximum point size assuming
	jb	pointSizeSafe		; low-res printing
	mov	dx, MAX_POINT_SIZE * 4

pointSizeSafe:

	mov	ds:[bp].BI_pointSize, dx	; new point size

	;
	;  When drawing the text we draw from the top of the font box,
	;  instead of from the top of the tallest character.  So calculate 
	;  the distance between the two and save it in TextOffset, which
	;  is factored in BannerDraw.
	;
	;  The font's point size has changed, so set the gstate's font 
	;  and point size, so we can get the height of the tallest 
	;  character at these settings.  The text styles remain set 
	;  from earlier in this routine.
	;

	clr	ah			; set the point size fraction
	mov	cx, ds:[bp].BI_fontID
	call	GrSetFont		; set the font size

	call	BannerStringHeight	; cx.bl = max y, dx.bh = min y

	push	cx			; save integer height
	subwbf	cxbl, dxbh
	cmp	bl, 0x80
	jb	dontRoundUp
	inc	cx

dontRoundUp:
	mov	ds:[bp].BI_messageHeight, cx
	pop	cx			; cx = integer string height

	mov	si, GFMI_BASELINE or GFMI_ROUNDED
	call	GrFontMetrics		; dx = baseline offset
	sub	dx, cx
	mov	ds:[bp].BI_textOffset, dx

	xchg	di, bp
	mov	dx, ds:[di].BI_lastMaximizedHeight
done:
	.leave
	ret
BannerMaximizeTextHeight	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerCalcTextWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given BI_pointSize calculate the width of the text.

CALLED BY:	internal

PASS:		*ds:si	= Banner object
		ds:[di] = instance data
		bp	= gstate handle

RETURN: 	bx	= text handle	(0 if no text)
		cx	= BI_width

		BI_width	- initialized
		BI_endSpace	- initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/ 2/90	Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerCalcTextWidth	proc	near
	class	BannerClass
	uses	ax, dx, si, es
	.enter

	push	ds:[LMBH_handle]		; to get *ds:si back later

	call	BannerGetTextString		; dx = handle, cx = length
	tst	cx				; any text?
	jnz	textExists

	mov	bx, dx
	call	MemFree				; free the block
 	clr	ax, cx				; no text, so scram
	segmov	es, ds				; es:[bp] = instance, *es:si = banner
	jmp	short 	done

textExists:

	push	dx			; save the text handle for return

	;
	;  Reset the gstate's font and point size so GrTextWidth and 
	;  GrFontMetrics are still accurate
	;

	call	BannerSetFontDetails

	xchg	bp, di			; ds:[bp] = instance, di = gstate

	segmov	es, ds, ax		; es:[bp] = instance, *es:si = banner
	mov	bx, dx			; bx = text block handle
	call	MemLock
	mov	ds, ax			; ds:0 = text
	clr	si			; ds:si = text	
	call	GrTextWidth		; dx = string width (points)

	;
	;  At this point dx contains the text width but the text may 
	;  actually be longer because some letters extend beyond their 
	;  bounds.  To ensure that the last character is completely 
	;  printed we add the width of the widest character in the font.
	;

	mov	cx, es:[bp].BI_fontID	; cx = font ID
	mov_tr	ax, dx			; save the text width in ax
	mov	si, GFMI_MAX_WIDTH or GFMI_ROUNDED
	call	GrFontMetrics		; dx = max possible char width

	shr	dx, 1			; halve the end space
	mov	es:[bp].BI_endSpace, dx
	add	dx, es:[bp].BI_borderWidth ; add room for left border
	shl	dx, 1			; (since there are two ends)
	add	ax, dx			; add in the text width
	mov_tr	cx, ax			; cx = computed width

	pop	ax			; restore text handle
	xchg	bp, di			; bp = gstate, di = instance

	;
	;  Check the computed width to ensure that it is smaller 
	;  than the graphics space maximum.
	;

	cmp	cx, MAX_COORD
	jl	done
	mov	cx, MAX_COORD

done:
	;
	;  Set the width of the banner.
	;

	mov	es:[di].BI_width, cx	; save the width

	pop	bx
	call	MemDerefDS		; ds = banner object block
	mov_tr	bx, ax			; bx = text handle

	.leave
	ret
BannerCalcTextWidth	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTractorHoles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This draws the tractor feed holes within the banner offset.
		The holes are defined as a region just after this routine.
		They are not scaled.

CALLED BY:	BannerDraw

PASS:		es:[bp]	= specific instance data for object
		cx	= view width (I think -- steve)
		di	= gstate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- calculate how many holes will fit on the document
	- draw a hole on top and then on the bottom until done

IMPROVEMENTS:
	We could clip the drawing of holes to not draw them outside of the
	view.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0
DrawTractorHoles	proc	near
	class	BannerClass
	uses	ax, bx, cx, dx, si, bp, ds
	.enter

	;
	;  Determine if we're in black and white mode.  If so, draw black
	;  tractor-feed holes.  If not, draw them in light gray.
	;

	push	cx, di, si
	GetResourceHandleNS	BannerApp, bx
	mov	si, offset	BannerApp
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	ObjMessage
	pop	cx, di, si

	mov	bp, es:[si]
	add	bp, es:[bp].Banner_offset

	mov	al, ah
	andnf	ax, mask DT_DISP_CLASS	; and ax because mov to si in two lines
	cmp	al, DC_COLOR_4 shl offset DT_DISP_CLASS
	mov	si, ax			; save if we're in two color mode
	jb	isBW

	mov	al, C_LIGHT_GREY
	jmp	short	setHolesColor

isBW:
	mov	al, C_BLACK

setHolesColor:

	mov	ah, CF_INDEX
	call	GrSetAreaColor		; the holes show the background color

	;
	; calculate how many holes to draw
	;

	mov_tr	ax, cx			; ax = width
	clr	dx
	mov	cx, HOLE_AREA
	div	cx			; # holes =  paper_width/HOLE_AREA
	cmp	si, DC_COLOR_4
	jb	dontAddExtraHoleBecauseDoesntBlendIn
	inc	ax			; add an extra; at worst it clips

dontAddExtraHoleBecauseDoesntBlendIn:

	mov	bx, ax			; counter
	mov	ax,-(HOLE_AREA * 2 / 3)	; fudge factor - should scale
	add	ax, es:[bp].BI_xOffset	; skip over background

	;
	; load in the hole region
	;

	segmov  ds, cs, si		; ds:si = fptr to region definition
	mov     si, offset BannerRegion_tractorHole

drawHole:

	tst	bx				; done yet?
	jz	holesDrawn
	push	bx				; save counter

	;
	; draw a top hole
	;

	add	ax, HOLE_AREA
	mov	cx, ax
	add	cx, HOLE_WIDTH
	mov	bx, HOLE_OFFSET
	mov	dx, HOLE_OFFSET + HOLE_WIDTH
        call    GrMoveTo                        ; place pen there
	call    GrDrawRegionAtCP 

	;
	; draw a bottom hole
	;

	mov	dx, es:[bp].BI_height
	add	dx, es:[bp].BI_yOffset
	mov	bx, dx
	add	bx, HOLE_OFFSET
	add	dx, HOLE_OFFSET + HOLE_WIDTH
        call    GrMoveTo                        ; place pen there
	call    GrDrawRegionAtCP
	pop	bx				; restore counter
	dec	bx
	jmp	short drawHole

holesDrawn:

	.leave
	ret
DrawTractorHoles	endp

; this is the region for a tractor hole.
	word	$			; DO NOT REMOVE THIS

; normal button border

BannerRegion_tractorHole	label   Region
        word    0, 0, PARAM_2-1, PARAM_3-1      ;bounds
        word    -1,					EOREGREC
        word    0,	1, 2,				EOREGREC
        word    2,	0, 3,				EOREGREC
        word    3,	1, 2,				EOREGREC
        word    EOREGREC
endif	; if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPerforations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the page boundaries to the Banner preview.

CALLED BY:	BannerDraw

PASS:		*es:bp	= specific instance data for object
		ax	=	left
		bx	=	top
		cx	=	right
		dx	=	bottom
		di	=	handle of a graphics state

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	
	- draw the top & bottom lines to show the tractor-feed tearoffs

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	nukes the gstate line color.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPerforations	proc	near
	class	BannerClass
	uses	ax, bx, cx, dx
	.enter

	;
	;  Draw the perforations between pages in light gray.  Light gray
	;  is less distracting than dark gray.
	;

	mov	ah, CF_INDEX
	mov	al, C_LIGHT_GRAY
	call	GrSetLineColor

	push	ax, bx, cx, dx, si

	;
	;  Draw the vertical lines between pages (every 11")
	;  treat the paper height as 8.5".  Calculate half an inch.  
	;  Calculate 11".  Do the two calculations in reverse order 
	;  to minimize rounding errors.
	;

	add	cx, es:[bp].BI_xOffset
	push	cx
	mov	ax, dx
	push	dx
	mov	cx, 22
	mul	cx				; 22 half inches in 11"

	;
	;  dx should be zero.  This will not be true if the banner height
	;  is >= 2979.  If there were an ec gcm version, this would be a 
	;  thing to check.
	;

	mov	cx, 17
	div	cx				; calc half inch = 8.5i/17
	pop	dx
	test	es:[bp].BI_specialEffects, mask SE_DOUBLE_HEIGHT
	jz	noDoublePrint
	shr	ax, 1				; twice as many lines

noDoublePrint:

	mov	si, ax
	pop	cx
	add	ax, es:[bp].BI_xOffset
	mov	bx, es:[bp].BI_yOffset
	add	dx, es:[bp].BI_yOffset

drawVerticalLine:

	push	cx
	mov	cx, ax
	call	GrDrawLine		; draw the top paper line
	pop	cx
	add	ax, si
	cmp	ax, cx
	jle	drawVerticalLine

	pop	ax, bx, cx, dx, si

	;
	;  In black and white mode a line needs to be drawn at the end of 
	;  the white paper to visually seperate it from the rest of the 
	;  view when the paper is smaller than the view.
	;

	push	ax, cx, dx
	add	cx, es:[bp].BI_xOffset
	inc	cx			; draw line just outside of the paper
	mov	ax, cx
	add	dx, es:[bp].BI_yOffset
	add	dx, es:[bp].BI_yOffset
	call	GrDrawLine
	pop	ax, cx, dx

	;
	; draw the horizontal lines 
	;

	add	cx, es:[bp].BI_xOffset
	mov	ax, es:[bp].BI_xOffset

	;
	;  If SE_DOUBLE_HEIGHT then we need to draw a line horizontally
	;  down the center to show that the printout will be two pages high.
	;

	test	es:[bp].BI_specialEffects, mask SE_DOUBLE_HEIGHT
	jz	doneMiddleLine

	push	dx
	shr	dx, 1			; position in the middle of the page
	add	dx, es:[bp].BI_yOffset
	mov	bx, dx
	call	GrDrawLine		; draw the top paper line
	pop	dx

doneMiddleLine:

	push	dx
	mov	dx, es:[bp].BI_yOffset
	mov	bx, dx
	call	GrDrawLine		; draw the top paper line
	pop	dx
	add	dx, es:[bp].BI_yOffset
	mov	bx, dx
	call	GrDrawLine		; draw the bottom paper line

	.leave
	ret
DrawPerforations	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerDrawBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a box and shrinks the boundary for the text.

CALLED BY:	BannerDraw

PASS:		*es:bp	= specific instance data for object
		ax	=	left
		bx	=	top
		cx	=	right	(paper width)
		dx	=	bottom	(paper height)
		di	=	handle to a graphics state

RETURN:		ax	=	new border width
		es:[bp].BI_borderWidth  =  new border width

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	Roger	10/2/90		now uses instance data to improve size/speed
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerDrawBorder		proc	near
	class	BannerClass
	uses	cx, dx
	.enter

	;
	;  Well, it's like this:  GrSetLineWidth takes dx.ax as a WWFixed
	;  width, instead of ax as an integer width, but ol' Roger didn't
	;  kno that, so we fixed it 4 him.
	;

	push	dx				; save bottom
	mov	dx, es:[bp].BI_borderLineWidth
	clr	ax				; dx.ax = line width (WWFixed)
	call	GrSetLineWidth
	mov	ax, dx				; ax <- line width (int)
	pop	dx				; restore bottom

	;
	; ax is half the line width plus a quarter inch
	;

	shr	ax, 1
	add	ax, es:[bp].BI_quarterInch

	;
	;  Now we place the box just inside the 1/4" borders we leave for
	;  the printer and tractors on the screen.  Note that we move in 
	;  an extra amount equal to half the line width, because the line 
	;  routine spills fat lines on both sides.  ax is set up with the 
	;  value.
	;
	;  Subtract a quarter inch from each edge.
	;

	mov	bx, ax
	sub	cx, ax
	sub	dx, ax

	;
	;  Adjust for the offsets.
	;

	add	ax, es:[bp].BI_xOffset
	add	bx, es:[bp].BI_yOffset
	add	cx, es:[bp].BI_xOffset
	add	dx, es:[bp].BI_yOffset

	;
	;  If we are printing we have to know if the left or the right
	;  side of the border should appear in this section.  If the
	;  left or right border should not appear, we move the border
	;  outside of the print section so that they are clipped away.
	;  This still leaves the top and bottom borders.
	;

	test	es:[bp].BI_bannerState, mask BS_DRAW_LEFT_BORDER
	jnz	leftEdgeKnown
	sub	ax, es:[bp].BI_borderWidth
	sub	ax, es:[bp].BI_xOffset

leftEdgeKnown:

	call	GrDrawRect

	test	es:[bp].BI_specialEffects, mask SE_DOUBLE_BOX
	jz	borderDrawn

	;
	;  For a double line we draw a white rectangle a quarter inch 
	;  thick in the center of the thick border.
	;
		
	push	ax			; a thin line is a QUARTER_INCH
	push	bx

	;
	;  If the second, inner line is as big as the whole border than the
	;  border will get whited out and not appear.  Don't do this.
	;

	mov	ax, es:[bp].BI_quarterInch
	mov	bx, es:[bp].BI_borderLineWidth
	cmp	ax, bx
	pop	bx
	jge	dontDrawBorder

	;
	;  Here we have another fix for ye olde GrSetLineWidth.  -stevey
	;
	
	push	dx				; save dx coordinate
	mov	dx, ax				; whatever he had in ax -> dx
	clr	ax				; fractional part
	call	GrSetLineWidth
	pop	dx				; restore dx coordinate

	mov	ah, CF_INDEX
	mov	al, C_WHITE
	call	GrSetLineColor
	pop	ax
	call	GrDrawRect
	
	;
	; restore the line color
	;

	push	ax
	mov	ah, CF_INDEX
	mov	al, C_BLACK
	call	GrSetLineColor

dontDrawBorder:
	pop	ax

borderDrawn:

	.leave
	ret
BannerDrawBorder		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawShadow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This draws either the small or the large shadows of the text

CALLED BY:	BannerDraw

PASS:		*es:bp	= specific instance data for object
		ds:si	=	text string
		ax	=	text's x position
		bx	=	text's y position
		di	=	graphics state

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	roger	9/17/90		rewrote to live with new borders, also smaller
	rsf	9/6/91		drawing shades changed to rgb values
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawShadowUsingRGB		proc	near
	class	BannerClass
	uses	ax, bx, dx
	.enter

	push	ax, bx

	;
	; calculate the offset size as ratio to the message height
	;

	mov	ax, es:[bp].BI_messageHeight
	test	es:[bp].BI_specialEffects, mask SE_SMALL_SHADOW 
	jz	setLargeShadow

	mov	dl, SMALL_SHADOW_OFFSET_RATIO
	jmp	short divide

setLargeShadow:

	mov	dl, LARGE_SHADOW_OFFSET_RATIO

divide:
	div	dl
	clr	ah
	mov	dx, ax

	;
	;  Next we set the shadow intensity based on whether we're 
	;  printing (skip the following if not printing)
	;

	test	es:[bp].BI_bannerState, mask BS_PRINT
	jz	setDarkerShade

	mov	al, RGB_PRINTER_SHADOW	; (37.5%) shadow during printing
	jmp	short setShade

setDarkerShade:

	mov	al, RGB_SCREEN_SHADOW	; (25%) shadow is lighter on screen

setShade:
	mov	bl, al			; make all the RGB colors equal (grey)
	mov	bh, al
	mov	ah, CF_RGB
	call	GrSetTextColor		; shadow...

	pop	ax, bx
	add	ax, dx
	add	bx, dx

	call	GrDrawText		; draw the shadow

	mov	ah, CF_INDEX		; restore to black
	mov	al, C_BLACK
	call	GrSetTextColor

	.leave
	ret
DrawShadowUsingRGB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Draw3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This draws the text with a three dimensional effect

CALLED BY:	BannerDraw

PASS:		*es:bp	= specific instance data for object
		ds:si	=	text string
		ax	=	text's x position
		bx	=	text's y position
		cx	-	string length (0 - null terminated)
		di	=	graphics state

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The text is built up from dark to light and then a final layer
	of dark again.  There is a problem however.  Since the text is
	drawn with masks, blacks pixels already there remain.  The effect then
	is that when text is written with a lesser mask the black pixels
	there from a darker image show through.  This is because masks
	simply specify what pixels can be written to.  Pixels not masked
	are left alone.  The solution then is to write the text out in white
	to wipe out the previous build up.  This results in the text being
	drawn 16 times!

	9/6/91  The shading is now done using rgb value instead of masks
	so that printing with postscript is faster.

DrawThreeD(int x_offset, y_offset)
{
	int	single_layer_offset, total_offset;
	byte	shade;

	single_layer_offset = (MessageHeight / 100) + 1; must be at least one!
	total_offset = single_layer_offset * 8;
	x_offset += total_offset;
	y_offset += total_offset;
	shade = 100%
	
	do {
		draw_text(white, x_offset, y_offset);
		draw_text(shade, x_offset, y_offset);

		x_offset -= single_layer_offset;
		y_offset -= single_layer_offset;
		next(shade);
	} while (shade > 0%);
}


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	roger	9/17/90		rewrote to live with new borders, also smaller
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawThreeDUsingRGB		proc	near
	class	BannerClass
	uses	dx, bp
	.enter

	push	ax			; save the text offset

	;
	; calculate the offset size as ratio to the Message Height
	;

	mov	ax, es:[bp].BI_messageHeight
	mov	dl, FOG_AND_3D_OFFSET_RATIO
	div	dl
	clr	ah			; ax is the depth
	inc	ax			; also view as pixels per shade

	;
	; calculate the offset to add the passed text offset
	;

	mov	dx, ax
	pop	ax
	push	cx, dx
	mov	cl, 3
	shl	dx, cl			; dl * 8
	add	ax, dx
	add	bx, dx
	pop	cx, dx

	;
	; next we set the shadow intensity based on whether we're printing
	;

	mov	bp, RGB_BLACK			; start with RGB C_BLACK

drawLayer:
	;
	; draw the text in the current shade
	;

	push	ax, bx
	mov	ax, bp			; the current RGB shade 
	mov	bl, al			; copy to the other RGB values
	mov	bh, al
	mov	ah, CF_RGB
	call	GrSetTextColor
	pop	ax, bx

	call	GrDrawText		; draw the shadow

	;
	; advance to the next position and shade.  loop.
	;

	sub	ax, dx
	sub	bx, dx
	add	bp, RGB_NEXT_SHADE	; up the rgb shade by 1/8th
	cmp	bp, RGB_WHITE
	jl	drawLayer

	push	ax, bx
	mov	al, RGB_BLACK		; restore to black
	mov	bl, al
	mov	bh, al
	mov	ah, CF_RGB
	call	GrSetTextColor
	pop	ax, bx			; The original offsets

	.leave
	ret
DrawThreeDUsingRGB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This draws the text which fades away

CALLED BY:	BannerDraw

PASS:		*es:bp	= specific instance data for object
		*ds:si	-	string
		ax	-	text's x position
		bx	-	text's y position
		cx	-	string length (0 - null terminated)
		di	-	graphics state

RETURN:		nothing

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

	Draw from the bottom right to the normal position using successively
	darker rgb values.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	roger	9/17/90		rewrote to live with new borders, also smaller
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFogUsingRGB			proc	near
	class	BannerClass
	uses	bp
	.enter

	push	ax, cx			; save the text offset

	;
	; calculate the offset size as ratio to the message height
	;

	mov	ax, es:[bp].BI_messageHeight
	mov	dl, FOG_AND_3D_OFFSET_RATIO
	div	dl
	clr	ah			; ax is the depth
	inc	ax			; also view as pixels per shade

	;
	; calculate the offset to add the passed text offset
	;

	mov	dx, ax
	mov	cl, 7			; there are seven shades to print
	mul	cl
	mov	bp, ax			; total offset
	pop	ax, cx

	add	ax, bp
	add	bx, bp

	;
	; next we set the shadow intenisty based on whether we're printing
	;

	mov	bp, 0xe0		; 12.5% grey

drawLayer:
	;
	; set the text shade
	;

	push	ax, bx
	mov	ax, bp
	mov	bl, al
	mov	bh, al
	mov	ah, CF_RGB
	call	GrSetTextColor		; shadow...
	pop	ax, bx

	call	GrDrawText		; draw the shadow

	sub	ax, dx
	sub	bx, dx
	sub	bp, RGB_NEXT_SHADE	; next shade
	cmp	bp, RGB_BLACK
	jg	drawLayer

	push	ax, bx
	mov	ax, bp
	mov	bl, al
	mov	bh, al
	mov	ah, CF_RGB
	call	GrSetTextColor		; restore to black text
	pop	ax, bx

	.leave
	ret
DrawFogUsingRGB			endp


