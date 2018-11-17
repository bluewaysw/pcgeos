COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Viewer
FILE:		viewerVisIcon.asm

AUTHOR:		Steve Yegge, Jun 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT SetVisIconHighlightBounds 
				Sets instance data for drawing
				highlight(s).

    INT CalcTextBounds		Sets the bounds of the icon name's text in
				instance data. Will only do the left &
				right.  The top & bottom were set by
				VisIconInitialize.  Also changes truncates
				the icon name in instance data and adds an
				ellipsis, if necessary.

    INT AlignText		Aligns the text if it is smaller than the
				max length so it will appear centered.  The
				function will also truncate any text that
				is longer than the max length and return
				the position at which to draw an ellipsis
				(...)

    INT GetClippedPosition	Clipps text so it will fit into a space of
				specified size.

    INT GetClippedPositionCharAttrCallback 
				Character attribute callback routine for
				text position.

    INT VisIconDrawBitmap	Draws the bitmap part of the icon.

    INT VisIconDrawName		Draws the name of the icon under the
				bitmap.

    INT TestIntersectingRectangles 
				See if rubberband is stretched across our
				bounds.

    INT TestPointInRect		See if a point is in the rubberband.

    INT TestPointInBounds	See if a given point is in our bounds
				(VisIconClass)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/17/94		Initial revision

DESCRIPTION:

	Implementation of VisIcon class.

	$Id: viewerVisIcon.asm,v 1.1 97/04/04 16:07:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ViewerCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size the vis-icon wants to be.

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data
		es 	= dgroup
		cx 	= suggested width
		dx	= suggested height

RETURN:		cx	= width to use
		dx	= height to use

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return the dimensions of the first format for this icon
	- if the first format is too narrow, we return a minimum
	  width (for use in drawing the name)
	- same 4 d height

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconRecalcSize	method  VisIconClass, 
						MSG_VIS_RECALC_SIZE
		uses	ax, bp
		.enter
	;
	;  For now we'll just use the first format in the database
	;  until I can think of something better.
	;
		mov	ax, MSG_DB_VIEWER_GET_DATABASE	; returns in bp
		call	VisCallParent

		mov	ax, ds:[di].VII_iconNumber
		clr	bx
		call	IdGetFormatDimensions
	;
	;  Just for kickers (and to fix several bugs) we'll use
	;  the height & width we just got to set the highlight
	;  bounds.  Slow but accurate.
	;
		call	SetVisIconHighlightBounds	; nukes ax
	;
	;  Now figure out whether the height & width are less than
	;  the minimum required values.  If so, beef them up a little.
	;
		cmp	cx, VIS_ICON_MINIMUM_WIDTH
		jae	doneWidth
		
		mov	cx, VIS_ICON_MINIMUM_WIDTH
doneWidth:
		cmp	dx, VIS_ICON_MINIMUM_HEIGHT
		jae	taller
		
		mov	dx, VIS_ICON_MINIMUM_HEIGHT + VIS_ICON_SPACER + \
				VIS_ICON_TEXT_HEIGHT
		jmp	short	done
taller:
		add	dx, VIS_ICON_SPACER + VIS_ICON_TEXT_HEIGHT
done:
		.leave
		ret
VisIconRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the instance data for the vis-icon.

CALLED BY:	MSG_VIS_ICON_INITIALIZE

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data
		cx	= icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- set the icon number in instance data
	- figure out how long the icon name is (in points)
	- figure out how big the bitmap is
	- initialize the instance data appropriately

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconInitialize	method dynamic VisIconClass, 
					MSG_VIS_ICON_INITIALIZE
		uses	ax, cx, dx, bp
		.enter
		
		mov	ds:[di].VII_iconNumber, cx
		
		mov	ax, MSG_DB_VIEWER_GET_DATABASE	; returns in bp
		call	VisCallParent
		
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
	;
	;  Get the name of the icon into instance data.
	;
		mov_tr	ax, cx				; ax = icon number
		mov	bx, ds
		lea	dx, ds:[di].VII_iconName	; bx:dx = name buffer
		call	IdGetIconName
	;
	;  Get the bitmap bounds and use them to set up the highlights.
	;
		mov	ax, ds:[di].VII_iconNumber
		clr	bx
		call	IdGetFormatDimensions	; cx = width, dx = height

		call	SetVisIconHighlightBounds
		push	ax
	;
	;  Get a gstate and set the font to the one we'll be using
	;  when we draw. Then set up the call to AlignText.
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		
		clr	ah
		mov	dx, VIS_ICON_FONT_SIZE
		mov	cx, VIS_ICON_FONT_ID
		xchg	di, bp
		call	GrSetFont
		xchg	di, bp
		
		pop	ax			; restore width to use for text
		call	CalcTextBounds

		xchg	di, bp			; di = gstate
		call	GrDestroyState
		xchg	di, bp			; di = instance
	;
	;  Force an update of our visual selves.
	;
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		.leave
		ret
VisIconInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetVisIconHighlightBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets instance data for drawing highlight(s).

CALLED BY:	VisIconRecalcSize, VisIconInitialize

PASS:		ds:di	= VisIconInstance
		cx	= bitmap width
		dx	= bitmap height

RETURN:		ax	= height to use for calculating text bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVisIconHighlightBounds	proc	near
		class	VisIconClass
		uses	cx,dx
		.enter
	;
	;  Examine passed width.  If it's wider than the minimum
	;  vis-icon width, we start drawing the bitmap at the
	;  upper-left corner of the VisIcon.
	;
		cmp	cx, VIS_ICON_MINIMUM_WIDTH
		jae	wider
	;
	;  The bitmap is narrower than the minimum.  Center the
	;  bitmap between the left & right vis-bounds.
	;
		mov	ax, VIS_ICON_MINIMUM_WIDTH
		sub	ax, cx
		shr	ax				; divide remainder by 2
		mov	ds:[di].VII_bitmapBounds.R_left, ax
		mov	ds:[di].VII_bitmapBounds.R_right, ax
		add	ds:[di].VII_bitmapBounds.R_right, cx
		
		mov	ax, VIS_ICON_MINIMUM_WIDTH	; width to use for text
		
		jmp	short	doneWidth
wider:
	;
	;  The bitmap is wider than the minimum.  The vis-icon will
	;  be as wide as the bitmap, so clear the left offset and use
	;  the bitmap's width for the right one.
	;
		clr	ds:[di].VII_bitmapBounds.R_left
		mov	ds:[di].VII_bitmapBounds.R_right, cx
		
		mov	ax, cx			; bitmap width (to use for text)
doneWidth:
		push	ax			; save width to use for text
		
		cmp	dx, VIS_ICON_MINIMUM_HEIGHT
		jae	taller
	;
	;  The bitmap is shorter than the minimum height.  Subtract
	;  the bitmap height from the minimum-height line to get
	;  the y-offset for drawing the bitmap.  Set the text y-
	;  offset to the (minimum bitmap height + the spacer).
	;
		mov	ax, VIS_ICON_MINIMUM_HEIGHT
		sub	ax, dx
		mov	ds:[di].VII_bitmapBounds.R_top, ax
		mov	ds:[di].VII_bitmapBounds.R_bottom, \
				VIS_ICON_MINIMUM_HEIGHT
		mov	ds:[di].VII_textBounds.R_top, \
				VIS_ICON_MINIMUM_HEIGHT + VIS_ICON_SPACER
		mov	ds:[di].VII_textBounds.R_bottom, \
				VIS_ICON_TEXT_HEIGHT + \
				VIS_ICON_MINIMUM_HEIGHT + VIS_ICON_SPACER
		jmp	short	doneHeight
taller:
	;
	;  The bitmap is taller than the minimum.  The bitmap height
	;  will determine the text offset.
	;
		clr	ds:[di].VII_bitmapBounds.R_top
		mov	ds:[di].VII_bitmapBounds.R_bottom, dx
		
		mov	ds:[di].VII_textBounds.R_top, dx
		add	ds:[di].VII_textBounds.R_top, VIS_ICON_SPACER
		mov	ds:[di].VII_textBounds.R_bottom, dx
		add	ds:[di].VII_textBounds.R_bottom, VIS_ICON_SPACER + \
					VIS_ICON_TEXT_HEIGHT
doneHeight:
		pop	ax			; restore height for text

		.leave
		ret
SetVisIconHighlightBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the bounds of the icon name's text in instance data.
		Will only do the left & right.  The top & bottom were set 
		by VisIconInitialize.  Also changes truncates the icon
		name in instance data and adds an ellipsis, if necessary.

CALLED BY:	VisIconInitialize

PASS:		ds:[di] = VisIconInstance
		ax	= width to use for centering/truncating.
		bp	= gstate to draw to

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- call skarpi's ultra-nifty routine to center/truncate the text
	- deal with it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/23/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcTextBounds	proc	near
		class	VisIconClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ax				; save max width
		lea	si, ds:[di].VII_iconName	; ds:si = text
		xchg	di, bp
		call	AlignText			; ax <- x offset
							; cx = num chars
		jc	clipped
	;
	;  The text wasn't clipped, so we don't have to draw an
	;  ellipsis (clear this field).  AlignText returned the
	;  x-offset (R_left), but we have to get the text length
	;  to find the R_right part.
	;
		mov	ds:[bp].VII_textBounds.R_left, ax
		mov	ds:[bp].VII_textBounds.R_right, ax ; add width to this
		mov	ds:[bp].VII_numChars, cx
		clr	ds:[bp].VII_ellipsis
		
		mov	cx, size FileLongName
		call	GrTextWidth			; dx = width (points)
		add	ds:[bp].VII_textBounds.R_right, dx
		
		jmp	short	done
clipped:
	;
	;  AlignText told us that the text has to be clipped.  This
	;  means that the text will fill the entire width of the VisIcon,
	;  which happens to be in bx right now (look at the first line
	;  of this routine if you don't believe me.  Go ahead.  Look.)
	;  	AlignText also gave us a pixel offset at which to begin 
	;  drawing the ellipsis, and the number of characters to draw 
	;  (0 if null-terminated), which is exactly what we need to pass 
	;  to GrDrawText in the vis-draw message handler.  So we save 
	;  all that hooey in instance data.
	;
		clr	ds:[bp].VII_textBounds.R_left
		mov	ds:[bp].VII_textBounds.R_right, bx
		mov	ds:[bp].VII_numChars, cx
		mov	ds:[bp].VII_ellipsis, dx
done:
		.leave
		ret
CalcTextBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlignText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aligns the text if it is smaller than the max length so it
		will appear centered.  The function will also truncate any
		text that is longer than the max length and return the
		position at which to draw an ellipsis (...)

CALLED BY:	DrawText

PASS:		ax	= max length of text (in pixels)
		ds:si	= text
		di	= gstate

RETURN:		ax	= x offset to start drawing at
		cx	= number of chars to draw (0 if null terminated)
			
		if carry set:  text was clipped
		dx	= offset to draw ellipsis (pixels)
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	10/22/92	Initial version
	stevey	12/10/92	made adjustments for use in vis-icons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlignText	proc	near
		uses	bx
		.enter
		
		mov	cx, size FileLongName
		call	GrTextWidth		; dx <- text width in points
		
		cmp	dx, ax			; is text longer than max value
		jg	textIsLonger		; if so we have to truncate
		
		sub	ax, dx			; diff in space
		shr	ax, 1			; div by 2
		
		clr	cx			; null terminated
done:
		.leave
		ret
textIsLonger:
	;
	; subtract the size of an ellipsis from the max length
	;
		push	ax			; save total field size
		mov_tr	cx, ax			; cx <- size of the field
		mov	ax, C_ELLIPSIS
		call	GrCharWidth		; dx:ah <- char width
		sub	cx, dx
		mov	ax, cx			; ax = field size - width of ...
		push	dx			; save ellipsis size
	;
	; since the text is longer than the total space we have to draw it in
	; we have to truncate it
	;
		call	GetClippedPosition	; cx - num characters to draw
						; dx - Nearest valid position
		
		mov	bx, dx			; len string in points
		pop	ax			; size of ellipses
		add	bx, ax			; bx <- len of string + ellipsis
		
		pop	ax			; ax <- total field len
		sub	ax, bx
		shr	ax, 1				   
	;
	; if the space is only 2 pixels don't bother
	;
		cmp	ax, 2
		jle	short noSpace
		
		add	dx, ax			; add the starting offset to the
		stc	
		jmp	done
noSpace:
		clr	ax			; ellipsis offset
		stc	
		jmp	done
		
AlignText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetClippedPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clipps text so it will fit into a space of specified size.
				
CALLED BY:	AlignText

PASS:		ax	- Size of clip region (in points)
		ds:si	- Text to clip
		di	- gstate handle

RETURN:		cx	- Number of characters to draw
		dx	- Neares valid position (position to draw ellipsis)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	10/22/92	Initial version
	stevey	12/10/92	stole it from skarpi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetClippedPosition	proc	near
		uses	ax,bx,si,di,es
		.enter
		
		push	bp
		sub	sp, size GTP_vars
		mov	bp, sp
		
		movcb	ss:[bp].GTPL_style.TMS_styleCallBack,\
		GetClippedPositionCharAttrCallback
		
		clrdw	ss:[bp].GTPL_style.TMS_graphicCallBack
		
		movdw	ss:[bp].GTPL_object, dssi	; save ptr to text
		clr	ss:[bp].GTPL_startPosition
		clr	ss:[bp].GTPL_charCount
	;
	; get the string size
	;
		mov	dx, di		; dx <- gstate
		segmov	es, ds, di
		mov	di, si
		call	LocalStringSize	; cx <- string size
		mov	di, dx		; di <- gstate
		
		mov	dx, ax		; max length
		call	GrTextPosition	; cx <- nearest character
					; dx <- nearest valid position
	;
	; if the nearest valid position is one passed the total width we have
	; to dec the character count by one and sub that charecters width from
	; the nearest valid position
	;
		cmp	dx, ax
		jle	done
		
		dec	cx		; new character count
		mov_tr	bx, dx		; bx <- nearest valid position
		add	si, cx		; offset to char
		clr	ah
		mov	al, {byte} ds:[si]	; ax <- char to check width
		call	GrCharWidth	; dx:ah <- char width
		sub	bx, dx		; bx <- nwp - char width
		mov_tr	dx, bx		; dx <- new nearest valid position
done:
		add	sp, size GTP_vars
		pop	bp
		
		.leave
		ret
GetClippedPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetClippedPositionCharAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Character attribute callback routine for text position.

CALLED BY:	GrTextPosition

PASS:		ss:bp	= pointer to GTP_vars structure on stack
		ds	= Segment address of old text pointer
		di	= Offset from field start

RETURN:		TMS_textAttr filled in
		ds:si	= Pointer to the text
		cx	= # of valid characters

DESTROYED:	nothing

SIDE EFFECTS:	TextAttr

PSEUDO CODE/STRATEGY:
 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	10/22/92	Initial version
	stevey	12/10/92	stole it from skarpi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetClippedPositionCharAttrCallback	proc	far
		uses	ax,bx,dx,di,bp,es
		.enter
		
		mov	ss:[bp].GTPL_style.TMS_textAttr.TA_fontWidth, FWI_MEDIUM
		mov	ss:[bp].GTPL_style.TMS_textAttr.TA_fontWeight, FW_NORMAL
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_trackKern
		
		mov	ss:[bp].GTPL_style.TMS_textAttr.TA_font, 
		VIS_ICON_FONT_ID
		mov	ss:[bp].GTPL_style.TMS_textAttr.TA_size.WBF_int,
		VIS_ICON_FONT_SIZE
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_size.WBF_frac
		
		clrwbf	ss:[bp].GTPL_style.TMS_textAttr.TA_spacePad
		
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_modeClear
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_modeSet
		
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_styleClear
		clr	ss:[bp].GTPL_style.TMS_textAttr.TA_styleSet
		
		movdw	dssi, ss:[bp].GTPL_object	; ds:si <- ptr to text
		segmov	es, ds, di
		mov	di, si
		call	LocalStringSize		; cx <- string size
		
		.leave
		ret
GetClippedPositionCharAttrCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw method for VisIconClass.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data
		bp	= GState to draw to.

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- draw a white rectangle first, to clear greebles
	- get the parent's icon database file handle
	- query the database for our moniker
	- draw the bitmap
	- if we're selected, draw an inverted rectangle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconVisDraw	method  VisIconClass, MSG_VIS_DRAW
		uses	ax, cx, dx, bp
		.enter
		
	;
	;  Erase whatever was there before (just in case)
	;
		xchg	di, bp		; di = GState, bp = instance data

		mov	ah, CF_INDEX
		mov	al, C_WHITE
		call	GrSetAreaColor
	;
	;  make sure to erase the dotted rectangle for the current icon 
	;  That is what the sub's and inc's are for.
	;
		mov	ax, ds:[bp].VI_bounds.R_left
		sub	ax, 2
		mov	bx, ds:[bp].VI_bounds.R_top
		sub	bx, 2
		mov	cx, ds:[bp].VI_bounds.R_right
		add	cx, 2
		mov	dx, ds:[bp].VI_bounds.R_bottom
		add	dx, 2	

		call	GrFillRect

		xchg	di, bp		; bp = GState, di = instance data
		
		call	VisIconDrawBitmap
		call	VisIconDrawName

		.leave
		ret
VisIconVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the bitmap part of the icon.

CALLED BY:	VisIconVisDraw

PASS:		*ds:si  = VisIcon
		ds:[di] = VisIconInstance
		bp	= GState to draw to

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- draw the bitmap starting at the bitmap upper-left corner
	  (as specified in instance data).
	
	- if the icon currently being edited, draw a dashed rectangle around
	  the VisIcon moniker

	- if selected, draw an inverted rectangle over the bitmap.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/23/92		initial version
	lester	 1/12/94		modified to indicate the current icon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconDrawBitmap	proc	near
		class	VisIconClass
		uses	ax,bx,cx,dx,di,bp
		.enter
	;
	;  Just get the first format from the database
	;
		push	bp				; save gstate
		mov	ax, MSG_DB_VIEWER_GET_DATABASE
		call	VisCallParent			; bp = vm file handle
		
		mov	ax, ds:[di].VII_iconNumber
		clr	bx
		call	IdGetFormat			; returns ^vcx:dx
		pop	bp				; restore gstate
		
		tst	dx				; valid bitmap?
		LONG	jz	done
	;
	;  Draw the bitmap starting at our upper-left corner.
	;
		mov	ax, ds:[di].VI_bounds.R_left
		add	ax, ds:[di].VII_bitmapBounds.R_left
		mov	bx, ds:[di].VI_bounds.R_top
		add	bx, ds:[di].VII_bitmapBounds.R_top
		xchg	di, bp			; di = gstate, bp = instance
		xchg	cx, dx
		call	GrDrawHugeBitmap
	;
	;  If we're the current icon (ie the one being edited in the fatbits,
	;  not the one selected in the DBViewer) draw a dashed rectangle 
	;  around the VisIcon moniker
	;
		mov	ax, MSG_DB_VIEWER_GET_CURRENT_ICON
		call	VisCallParent			; ax = current icon
		
		cmp	ax, ds:[bp].VII_iconNumber
		jne	doneCurrentTest

		; draw dashed rectangle around the VisIcon moniker

		mov	al, MM_INVERT
		call	GrSetMixMode

		mov	al, SDM_50
		call	GrSetLineMask

		mov	ax, ds:[bp].VI_bounds.R_left
		mov	cx, ax
		add	ax, ds:[bp].VII_bitmapBounds.R_left
		add	cx, ds:[bp].VII_bitmapBounds.R_right
		sub	ax, 2
		inc	cx

		mov	bx, ds:[bp].VI_bounds.R_top
		mov	dx, bx
		add	bx, ds:[bp].VII_bitmapBounds.R_top
		add	dx, ds:[bp].VII_bitmapBounds.R_bottom
		sub	bx, 2
		inc	dx

		call	GrDrawRect

		mov	al, MM_COPY			; restore mix mode
		call	GrSetMixMode

		mov	al, SDM_100
		call	GrSetLineMask

doneCurrentTest:
	;
	;  If we're selected draw an inverted rectangle over the
	;  bitmap.
	;
		tst	ds:[bp].VII_selected
		jz	done
		
		mov	al, MM_INVERT
		call	GrSetMixMode
		
		mov	ax, ds:[bp].VI_bounds.R_left
		mov	cx, ax
		add	ax, ds:[bp].VII_bitmapBounds.R_left
		add	cx, ds:[bp].VII_bitmapBounds.R_right
		
		mov	bx, ds:[bp].VI_bounds.R_top
		mov	dx, bx
		add	bx, ds:[bp].VII_bitmapBounds.R_top
		add	dx, ds:[bp].VII_bitmapBounds.R_bottom
		
		call	GrFillRect
		
		mov	al, MM_COPY			; restore mix mode
		call	GrSetMixMode
done:
		.leave
		ret
VisIconDrawBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconDrawName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the name of the icon under the bitmap.

CALLED BY:	VisIconVisDraw

PASS:		*ds:si = VisIcon object
		ds:[di] = instance data
		bp 	= gstate to draw to

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- set the font in the gstate
	- draw the text starting at the text upper-left corner, as
	  specified in instance data.
	- if selected, draw an inverted rectangle over the text.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconDrawName	proc	near
		class	VisIconClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; set the text font  (same as GeoManager uses)
	;
		clr	ah
		mov	dx, VIS_ICON_FONT_SIZE
		mov	cx, VIS_ICON_FONT_ID
		xchg	di, bp
		call	GrSetFont
		xchg	di, bp
	;
	;  Draw the text
	;
		mov	ax, ds:[di].VI_bounds.R_left
		add	ax, ds:[di].VII_textBounds.R_left
		mov	bx, ds:[di].VI_bounds.R_top
		add	bx, ds:[di].VII_textBounds.R_top
		mov	cx, ds:[di].VII_numChars
		lea	si, ds:[di].VII_iconName	; ds:si = text
		xchg	di, bp				; di = gstate
		call	GrDrawText
	;
	;  If necessary, draw the ellipsis
	;
		tst	ds:[bp].VII_ellipsis
		jz	noEllipsis
		
		mov	ax, ds:[bp].VI_bounds.R_left
		add	ax, ds:[bp].VII_ellipsis	; offset to ellipsis
		mov	bx, ds:[bp].VI_bounds.R_top
		add	bx, ds:[bp].VII_textBounds.R_top
		mov	dx, C_ELLIPSIS
		call	GrDrawChar
noEllipsis:
	;
	;  If we're selected, draw a rectangle over the text.
	;
		tst	ds:[bp].VII_selected
		jz	done
		
		mov	al, MM_INVERT
		call	GrSetMixMode
		
		mov	ax, ds:[bp].VI_bounds.R_left
		mov	cx, ax
		add	ax, ds:[bp].VII_textBounds.R_left
		add	cx, ds:[bp].VII_textBounds.R_right
		
		mov	bx, ds:[bp].VI_bounds.R_top
		mov	dx, bx
		add	bx, ds:[bp].VII_textBounds.R_top
		add	dx, ds:[bp].VII_textBounds.R_bottom
		call	GrFillRect
		
		mov	al, MM_COPY
		call	GrSetMixMode
done:
		.leave
		ret
VisIconDrawName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconSetSelectedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets us selected (if not already) and redraws.
		This message is only sent when the VisIcon is
		selected via MSG_META_START_SELECT to the parent,
		not if it was selected with a rubberband.

CALLED BY:	MSG_VIS_ICON_SET_SELECTED_STATE

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data
		bp.high	= UIFunctionsActive
		cx	= number of child to set
			  (if it's not our number, then deselect)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if the control key is down, let the end-select handler
	  take care of things.  (DBViewerEndSelect)

	- if we aren't selected already, select ourselves, redraw,
	  and call the content (our parent) back and mention it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconSetSelectedState	method  VisIconClass, 
					MSG_VIS_ICON_SET_SELECTED_STATE
		uses	ax, cx, dx, bp
		.enter		

		mov	ax, bp
		test	ah, mask UIFA_ADJUST		; control key pressed?
		jnz	quit
		
		cmp	cx, ds:[di].VII_iconNumber
		je	selectMe
	;
	;  We're getting a de-select message.  We were already deselected?
	;
		tst	ds:[di].VII_selected		; were we already?
		jz	quit				; yep, bail
		
		clr	ds:[di].VII_selected
		jmp	short	draw
		
selectMe:
		
		tst	ds:[di].VII_selected		; were we already?
		jnz	quit
		
		mov	ds:[di].VII_selected, 1
draw:
	;
	;  redraw ourselves immediately to prevent rubberband greebles.
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		push	bp
		
		clr	cl				; flags for vis-draw
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
		
		pop	di
		call	GrDestroyState
	;
	;  Our state changed.  Call the content.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		clr	ch
		mov	cl, ds:[di].VII_selected	; nonzero or whatever
		
		mov	ax, MSG_DB_VIEWER_ICON_TOGGLED
		call	VisCallParent
quit:
		.leave
		ret
VisIconSetSelectedState		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns it on or off.

CALLED BY:	MSG_VIS_ICON_SET_SELECTION

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data
		dx	= nonzero if turning on
			  zero if turning off

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if we're already selected, and selecting, bail
	- if we're already unselected, and turning off, bail
	- select or deselect ourselves
	- redraw
	- notify our parent that we toggled

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconSetSelection	method  VisIconClass, MSG_VIS_ICON_SET_SELECTION
		uses	ax, cx, dx, bp
		.enter
		
		tst	dx
		jz	notSelected
		
		tst	ds:[di].VII_selected		; selected already?
		jnz	done				; yep, bail
		
		mov	ds:[di].VII_selected, 1
		jmp	short	redraw
notSelected:
		tst	ds:[di].VII_selected		; unselected already?
		jz	done				; yep, bail
		
		clr	ds:[di].VII_selected
redraw:
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		push	bp
		
		clr	cl				; flags for vis-draw
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
		
		pop	di
		call	GrDestroyState
	;
	;  Our state changed.  Call the content.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		clr	ch
		mov	cl, ds:[di].VII_selected	; nonzero or whatever
		
		mov	ax, MSG_DB_VIEWER_ICON_TOGGLED
		call	VisCallParent
done:
		.leave
		ret
VisIconSetSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconCheckInRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're selected by virtue of being in the rubberband.

CALLED BY:	MSG_VIS_ICON_CHECK_IN_RECTANGLE

PASS:		*ds:si	= VisIconClass object
		ds:di   = VisIconClass instance data
		ss:[bp]	= CheckInRectangleStruct

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- make sure that in the passed rubberband rectangle, the
	  top, left corner is in R_left and R_top.
	- see if the rubberband is selecting us:

		* if any of our corners is in the rubberband
				-- OR --
		* if any of the rubberband's corners are in our bounds
				-- OR --
		* if they cross each other like a tic-tac-toe board

		...then we're selected.

	- see if the control key is down (it affects whether we're
	  getting selected or deselected:

		* if we're already selected, and the rubberband
		  isn't selecting us, and the control key is down,
		  we stay selected

		* if we're selected, and the rubberband is selecting
		  us, and the control key is down, we become unselected

	- if our state changed, send a message to the content


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconCheckInRectangle	method  VisIconClass, 
					MSG_VIS_ICON_CHECK_IN_RECTANGLE
		uses	ax, cx, dx, bp
		.enter
		
		mov	ss:[bp].CIRS_chunk, si		; save our object offset
		
		mov	ax, ss:[bp].CIRS_rect.R_left
		mov	bx, ss:[bp].CIRS_rect.R_top
		mov	cx, ss:[bp].CIRS_rect.R_right
		mov	dx, ss:[bp].CIRS_rect.R_bottom
	;
	;  First make sure the Rectangle points are in the correct
	;  order (R_top is really R_top, etc).
	;
		cmp	cx, ax
		jge	noSwap1
		xchg	cx, ax
noSwap1:
		cmp	dx, bx
		jge	noSwap2
		xchg	dx, bx
noSwap2:
		mov	ss:[bp].CIRS_rect.R_left, ax
		mov	ss:[bp].CIRS_rect.R_top, bx
		mov	ss:[bp].CIRS_rect.R_right, cx
		mov	ss:[bp].CIRS_rect.R_bottom, dx
	;
	;  Check if any of our 4 corners are in the rubberband-rectangle,
	;  in this order:  upper-left, upper-right, lower-right, lower-left
	;
		mov	ax, ds:[di].VI_bounds.R_left
		mov	bx, ds:[di].VI_bounds.R_top		; upper-left
		call	TestPointInRect
		jc	yes
		
		mov	ax, ds:[di].VI_bounds.R_right		; upper-right
		call	TestPointInRect
		jc	yes
		
		mov	bx, ds:[di].VI_bounds.R_bottom
		call	TestPointInRect				; lower-right
		jc	yes
		
		mov	ax, ds:[di].VI_bounds.R_left
		call	TestPointInRect				; lower-left
		jc	yes
	;
	;  Now check to see if any corner of the rubberband is in
	;  our bounds.  (ax, bx) and (cx, dx) define the rubberband.
	;
		mov	ax, ss:[bp].CIRS_rect.R_left
		mov	bx, ss:[bp].CIRS_rect.R_top
		call	TestPointInBounds
		jc	yes
		
		mov	ax, ss:[bp].CIRS_rect.R_right
		call	TestPointInBounds
		jc	yes
		
		mov	bx, ss:[bp].CIRS_rect.R_bottom
		call	TestPointInBounds
		jc	yes
		
		mov	ax, ss:[bp].CIRS_rect.R_left
		call	TestPointInBounds
		jc	yes
	;
	;  Now check to see if the rubberband is stretched across
	;  our bounds, like so:
	;		---------
	;		|	|
	;	-------------------------
	;	|	|	|	|
	;	|	|	|	|
	;	-------------------------
	;		|	|
	;		---------
	;		
		mov	ax, ss:[bp].CIRS_rect.R_left
		mov	bx, ss:[bp].CIRS_rect.R_top
		mov	cx, ss:[bp].CIRS_rect.R_right
		mov	dx, ss:[bp].CIRS_rect.R_bottom
		call	TestIntersectingRectangles
		jc	yes
	;
	;  At this point, if we're selected AND we were already
	;  selected, we bail.  Same for if we weren't selected
	;  and we already weren't selected.  Otherwise we set our
	;  selected-bit appropriately and redraw.
	;
no::
		tst	ds:[di].VII_selected
		jz	done			; already not selected (bail)
	;
	;  OK, we are transitioning to unselected, unless the control
	;  key is down.
	;
		test	ss:[bp].CIRS_flags, mask UIFA_ADJUST	; control key
		jnz	done
		
		clr	ds:[di].VII_selected
		jmp	short	redraw
yes:
	;
	;  If we got here, we're being selected by the rubberband.
	;  If we were already selected, we check the state of the
	;  control key, and if it's down, we deselect and redraw.
	;
		tst	ds:[di].VII_selected
		jnz	alreadySelected
	;		
	; we weren't selected, so select ourselves no matter what.
	;		
		mov	ds:[di].VII_selected, 1
redraw:
		mov	si, ss:[bp].CIRS_chunk
		
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		push	bp
		
		clr	cl
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
		
		pop	di
		call	GrDestroyState
	;
	;  Our state changed.  Send a message to the content.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		
		tst	ds:[di].VII_selected
		jz	deselected
		mov	cx, 1
		jmp	short	sendToContent
deselected:
		clr	cx
sendToContent:
		mov	ax, MSG_DB_VIEWER_ICON_TOGGLED
		call	VisCallParent
		
		jmp	short	done
alreadySelected:
	;
	;  If the control key is down, we deselect and redraw, else quit.
	;
		test	ss:[bp].CIRS_flags, mask UIFA_ADJUST	; control key
		jz	done
		
		clr	ds:[di].VII_selected
		jmp	short	redraw
done:	
		.leave
		ret
VisIconCheckInRectangle	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestIntersectingRectangles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if rubberband is stretched across our bounds.

CALLED BY:	VisIconCheckInRectangle

PASS: 		ax, bx	= upper-left corner
		cx, dx	= lower-right corner
		ds:[di]	= instance data

RETURN:		carry set if they intersect

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	if (ax < left) AND
	   (cx > right) AND
	   (bx > top) AND
	   (dx < bottom) then it's crossing

	if (bx < top) AND
	   (dx > bottom) AND
	   (ax > left) AND 
	   (cx < right) then it's crossing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/9/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestIntersectingRectangles	proc	near
		class	VisIconClass
	;
	;  Check if the rubberband is crossing us horizontally.
	;
		cmp	ax, ds:[di].VI_bounds.R_left
		jge	notHorizontally
		
		cmp	cx, ds:[di].VI_bounds.R_right
		jle	notHorizontally
		
		cmp	bx, ds:[di].VI_bounds.R_top
		jle	notHorizontally
		
		cmp	dx, ds:[di].VI_bounds.R_bottom
		jl	yep
notHorizontally:
	;
	;  Check if rubberband's crossing vertically.
	;
		cmp	bx, ds:[di].VI_bounds.R_top
		jge	nope
		
		cmp	dx, ds:[di].VI_bounds.R_bottom
		jle	nope
		
		cmp	ax, ds:[di].VI_bounds.R_left
		jle	nope
		
		cmp	cx, ds:[di].VI_bounds.R_right
		jl	yep
		
		jmp	short	nope
yep:
		stc
		jmp	short	done
nope:
		clc
done:
		ret
TestIntersectingRectangles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestPointInRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a point is in the rubberband.

CALLED BY:	VisIconCheckInRectangle

PASS:		ss:[bp] = CheckInRectangleStruct
		ax, bx	= point

RETURN:		carry set if it's inside the rectangle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return carry set if the point falls inside the rectangle

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/9/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestPointInRect	proc	near
		.enter	inherit
		
		cmp	ax, ss:[bp].CIRS_rect.R_left
		jl	nope
		
		cmp	ax, ss:[bp].CIRS_rect.R_right
		jg	nope
		
		cmp	bx, ss:[bp].CIRS_rect.R_top
		jl	nope
		
		cmp	bx, ss:[bp].CIRS_rect.R_bottom
		jg	nope
		
		stc
		jmp	short	done
nope:
		clc
done:
		.leave
		ret
TestPointInRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestPointInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a given point is in our bounds (VisIconClass)

CALLED BY:	VisIconCheckInRectangle

PASS:		ds:[di] = instance data
		ax, bx	= point to test

RETURN:		carry set if it's in our bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return carry set if point lies inside rectangle

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/9/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestPointInBounds	proc	near
		class	VisIconClass
		.enter	inherit
		
		cmp	ax, ds:[di].VI_bounds.R_left
		jl	nope
		
		cmp	bx, ds:[di].VI_bounds.R_top
		jl	nope
		
		cmp	ax, ds:[di].VI_bounds.R_right
		jg	nope
		
		cmp	bx, ds:[di].VI_bounds.R_bottom
		jg	nope
		
		stc
		jmp	short	done
nope:
		clc
done:
		.leave
		ret
TestPointInBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconGetNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the icon-number for this VisIcon.

CALLED BY:	MSG_VIS_ICON_GET_NUMBER

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data

RETURN:		cx	= number
		ax	= MouseReturnFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the number from instance data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconGetNumber	method  VisIconClass, 
					MSG_VIS_ICON_GET_NUMBER
		
		mov	cx, ds:[di].VII_iconNumber
		mov	ax, mask MRF_PROCESSED
		
		ret
VisIconGetNumber	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisIconGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns whether the VisIcon is selected or not.

CALLED BY:	MSG_VIS_ICON_GET_SELECTION

PASS:		*ds:si	= VisIconClass object
		ds:di	= VisIconClass instance data

RETURN:		bp	= nonzero if the icon is selected
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return whether we're selected or not (from instance data)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisIconGetSelection	method  VisIconClass, 
					MSG_VIS_ICON_GET_SELECTION
		
		push	ax
		clr	ah
		mov	al, ds:[di].VII_selected
		mov	bp, ax
		pop	ax
		
		ret
VisIconGetSelection	endm

ViewerCode	ends
