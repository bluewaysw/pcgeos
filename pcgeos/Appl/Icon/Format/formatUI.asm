COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		formatUI.asm

AUTHOR:		Steve Yegge, Mar 27, 1993

ROUTINES:
	Name			Description
	----			-----------

VisFormatVisDraw			MSG_VIS_DRAW handler for VisFormat
VisFormatRecalcSize			MSG_VIS_RECALC_SIZE handler
VisFormatStartSelect			MSG_META_START_SELECT handler
VisFormatInvalidate			invalidates the vis-format
FormatDrawRectangle			draws the border around the vis-format

DrawFormat				Actually draws the format
DrawFormatBorder			calls FormatDrawRectangle w/ colors

FormatContentGetChildSpacing		Returns margins for vis-formats.
FormatContentGetMargins			Returns spacing for vis-formats.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93		Initial revision

DESCRIPTION:

	This file contains routines for the VisFormat and FormatContent
	class implementations.

	$Id: formatUI.asm,v 1.1 97/04/04 16:06:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFormatInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the 

CALLED BY:	MSG_VIS_FORMAT_INITIALIZE
PASS:		*ds:si	= VisFormatClass object
		ds:di	= VisFormatClass instance data
		cx	= new number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFormatInitialize	method dynamic VisFormatClass, 
					MSG_VIS_FORMAT_INITIALIZE

		mov	ds:[di].VFI_formatNumber, cx
		
		ret
VisFormatInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFormatStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes the editing to switch to this format.

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= VisFormat object
		ds:di	= VisFormatInstance

RETURN:		ax = MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if we were selected, do nothing.
	- if there was a format selected previously, cause it to redraw
	- send a switch-format message (with our number) to the process.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFormatStartSelect	method dynamic VisFormatClass, 
					MSG_META_START_SELECT
		uses	cx, dx, bp
	 	.enter
	;
	;  Our goal here is to see if we're already selected.  The
	;  DBViewer in our block holds that information, so we call
	;  it to get the info.  It's in our block so we can just
	;  call ObjCallInstanceNoLock.
	;
		push	si, di			; VisFormat chunk & instance
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_DB_VIEWER_GET_SELECTED_FORMATS
		call	ObjCallInstanceNoLock	; ax <- selected format #
		pop	si, di			; VisFormat chunk & instance

		mov	bx, ds:[di].VFI_formatNumber	; al <- our number
		cmp	ax, bx			; are we already selected?
		je	done			; yep, bail

		cmp	ax, NO_CURRENT_FORMAT	; selectedFormat
		je	switch
	;
	;  See if the old format needed saving.
	;
		push	si, di			; VisFormat chunk & instance
		mov	si, offset IconDBViewerTemplate
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset	; ds:di = DBViewerInstance
		call	CheckFormatDirtyAndDealWithIt
		pop	si, di			; VisFormat chunk & instance
		jc	done			; user cancelled the operation
switch:
	;
	;  Now we can do the actual switch-format thing.
	;
		mov	cx, ds:[di].VFI_formatNumber	; cx <- us 
		mov	bx, ds:[LMBH_handle]
		mov	si, offset IconDBViewerTemplate
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjMessage
done:
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
VisFormatStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFormatVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a format.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= VisFormatClass object
		ds:di	= VisFormatClass instance data
		bp 	= GState to draw to.

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- draw the appropriate border around the format
	- get the bitmap
	- see if it's valid (not a perfect test, but works sometimes)
	- if it's valid, draw it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFormatVisDraw	method dynamic VisFormatClass, 
					MSG_VIS_DRAW
	;
	;  Our document object is storing the current icon, selected
	;  format and last-selected format, so we get them before
	;  continuing. (Get the file handle while we're at it.)
	;
		push	si, di			; object & instance data
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_DB_VIEWER_GET_CURRENT_ICON
		call	ObjCallInstanceNoLock	; ax = current icon
		mov	dx, ax			; dx = current icon

		mov	ax, MSG_DB_VIEWER_GET_SELECTED_FORMATS
		call	ObjCallInstanceNoLock	; ax <- selected format #

		push	ax, bp			; save formats & gstate
		mov	ax, MSG_DB_VIEWER_GET_DATABASE
		call	ObjCallInstanceNoLock	; bp = database
		mov	cx, bp			; cx = database
		pop	ax, bp			; formats & gstate

		pop	si, di
		cmp	dx, NO_CURRENT_ICON
		je	done			; don't draw if no icon.
	;
	;  Draw the snifty border around the vis-format.
	;
		call	DrawFormatBorder
	;
	;  Find our upper-left coordinates
	;
		mov	ax, ds:[di].VI_bounds.R_left
		mov	bx, ds:[di].VI_bounds.R_top
		push	ax, bx			; save upper-left corner
	;
	;  Find out which number we are, and get the corresponding bitmap
	;
		mov	ax, dx			; ax <- icon number
		mov	bx, ds:[di].VFI_formatNumber	
						; bx <- our format number	
		push	bp			; save gstate
		mov	bp, cx			; bp = vm file handle
		call	IdGetFormat		; returns ^vcx:dx = format
		pop	bp			; restore gstate

		pop	ax, bx			; restore upper-left corner
		tst	dx			; valid bitmap?
		jz	done
	;
	;  Draw the bitmap into the format area.  We draw it indented
	;  3 pixels from the top and left sides, to make room for the
	;  3-pixel border that gets drawn around the perimeter.  (Hence 
	;  we increment ax & bx just before drawing the bitmap.)
	;
		add	ax, 3			; make room for border
		add	bx, 3			; make room for border
		mov	di, bp			; di <- gstate
		xchg	cx, dx			; ^vdx:cx = bitmap
		call	GrDrawHugeBitmap
done: 
		ret
VisFormatVisDraw	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFormatInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	forces a redraw of the visformat 

CALLED BY:	MSG_VIS_FORMAT_INVALIDATE

PASS:		ds:di	= VisFormatClass instance data
		es = dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFormatInvalidate	method  VisFormatClass, 
					MSG_VIS_FORMAT_INVALIDATE

		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
		mov	ax, MSG_VIS_MARK_INVALID
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		ret
VisFormatInvalidate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFormatBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a slick-looking border around the vis-format.

CALLED BY:	VisFormatVisDraw

PASS:		*ds:si	= VisFormatClass object
		ds:di	= VisFormatClass instance data
		bp 	= GState to use.
		ax	= selected format

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	The border around a format consists of a 3-pixel-wide
	rectangle around the perimeter of the format itself.
	If the format is highlighted we'll draw the format
	as if it were a depressed trigger, sort of, and if
	not we'll draw it as if it were a really happy trigger.
	(i.e. not depressed).


	if we have Hightlight:
		- draw top & left in dark gray
		- draw bottom & right in white
		- draw inner 2 rectangles as light gray
	otherwise:
		- draw top & left in white
		- draw bottom & right in dark gray
		- draw inner 2 rectangles as light gray

	bp stores the "highlight" boolean throughout the routine.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFormatBorder	proc	near
		class	VisFormatClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  See if we have the highlight.
	;
		push	bp				; save gstate
		cmp	ax, ds:[di].VFI_formatNumber	; are we selected?
		je	selected
		clr	bp				; nope
		jmp	short	bounds
selected:
		mov	bp, 1				; yep
bounds:
	;
	;  initialize the bounds for the outer rectangle
	;
		mov	si, ds:[di].VI_bounds.R_left	; si <- left
		mov	bx, ds:[di].VI_bounds.R_top
		mov	cx, ds:[di].VI_bounds.R_right
		mov	dx, ds:[di].VI_bounds.R_bottom
		dec	cx
		dec	dx			; why? Dunno. I just had to.
	;
	;  Draw the outer rectangle (actually 4 lines).
	;
		tst	bp				; are we selected?
		jz	noHighlight1
	;
	;  we have the highlight...dark gray for top & left
	;
		mov	al, C_DARK_GRAY			; al <- color 1
		mov	ah, C_WHITE			; ah <- color 2
		jmp	short	draw1
noHighlight1:
		mov	al, C_WHITE
		mov	ah, C_DARK_GRAY
draw1:
		pop	di				; restore gstate
		call	FormatDrawRectangle
	;
	;  Draw 2nd rectangle	(shrink it in by 1 pixel all around)
	;
		inc	si
		inc	bx
		dec	cx
		dec	dx
		mov	ah, C_LIGHT_GRAY
		mov	al, ah
		call	FormatDrawRectangle
	;
	;  Draw 3rd rectangle (shrink it in again)
	;
		inc	si
		inc	bx
		dec	cx
		dec	dx
		mov	ah, C_LIGHT_GRAY
		mov	al, ah
		call	FormatDrawRectangle

		.leave
		ret
DrawFormatBorder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatDrawRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a rectangle of the specified color and dimensions	
		to the passed gstate.

CALLED BY:	DrawFormatBorder

PASS:		di 	= gstate
		si, bx 	= coordinates for upper-left corner
		cx, dx 	= coordinates for lower-right corner
		al	= color 1
		ah	= color 2

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Draw the top & left sides of the rectangle in color 1,
	and the bottom & right sides in color 2.  If the passed
	colors (si & bp) are the same, skip the rest & draw
	a rectangle.

	I use bp for temp storage instead of pushing & popping
	in this routine, since at most one thing will be on
	the stack at any given time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatDrawRectangle	proc	near
		uses	ax,si,bp
		.enter
	;
	;  First some setup work that happens whether the passed
	;  colors were the same or not.  Set line color to (al).
	;
		mov	bp, ax			; save passed colors
		mov	ah, CF_INDEX
		call	GrSetLineColor
		mov	ax, bp			; restore colors
	;
	; compare the colors...if they're the same, draw a rectangle.
	;
		cmp	ah, al
		je	sameColor
	;
	;  The colors passed in were different.  Draw the top & left in
	;  the first color, and the bottom & right in the second.
	;  (Note that we've already set the line color to color 1).
	;  I realize this routine isn't incredibly intuitive, but
	;  I think if you look at it for a while you'll get it :)
	;
		xchg	ax, si				; ax <- coordinate,
							; si <- colors
		mov	bp, dx				; save dx coord in bp
		mov	dx, bx
		inc	cx				; bug in GrDrawLine
		call	GrDrawLine			; draw top
		dec	cx
		mov	dx, bp				; restore dx coord

		mov	bp, cx				; save cx coord in bp
		mov	cx, ax
		call	GrDrawLine			; draw left
		mov	cx, bp				; restore cx coord

		xchg	ax, si				; ax <- colors
		mov	al, ah				; al <- color 2
		mov	ah, CF_INDEX
		call	GrSetLineColor
		xchg	ax, si				; ax <- coordinate

		mov	bp, bx				; save bx coord in bp
		mov	bx, dx
		inc	cx				; bug in GrDrawLine
		call	GrDrawLine			; draw bottom
		dec	cx	
		mov	bx, bp				; restore bx coord

		mov	ax, cx
		call	GrDrawLine			; draw right
		jmp	short	done
sameColor:
	;
	;  If the passed-in colors were the same, we may as well just
	;  call GrDrawRect.
	;
		xchg	ax, si				; ax <- coordinate
		call	GrDrawRect
done:
		.leave
		ret
FormatDrawRectangle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFormatRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size the vis-object wants to be.

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= VisFormat object
		ds:di	= VisFormatInstance
		cx = suggested width
		dx = suggested height

RETURN:		cx = width to use	(0 if the format's not in use)
		dx = height to use	(0 if the format's not in use)

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFormatRecalcSize	method dynamic VisFormatClass, 
					MSG_VIS_RECALC_SIZE
	;
	;  Our document object stores the current icon and file handle,
	;  so we get that information before continuing.
	;
		push	si, di				; VisFormat 
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_DB_VIEWER_GET_DATABASE
		call	ObjCallInstanceNoLock		; bp = file handle
		mov	ax, MSG_DB_VIEWER_GET_CURRENT_ICON
		call	ObjCallInstanceNoLock		; ax = current icon
		pop	si, di				; *ds:si = VisFormat

		cmp	ax, NO_CURRENT_ICON
		je	noBitmap
	;
	;  Find out which format we are and get its width and height.
	;
		mov	bx, ds:[di].VFI_formatNumber
		call	IdGetFormatDimensions		; returns cx & dx
		tst	dx				; valid format?
		jz	noBitmap
	;
	;  We'll be drawing a black rectangle around the outer
	;  perimeter of the visformat.  We have to make room in
	;  the size for 3-pixel-wide lines on top, bottom, left & right.
	;
		add	cx, 6
		add	dx, 6
		jmp	short	done
noBitmap:
		clrdw	cxdx
done:
		ret
VisFormatRecalcSize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentRescanList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a bunch of vis-icons (removes existing ones first).

CALLED BY:	MSG_FORMAT_CONTENT_RESCAN_LIST

PASS:		*ds:si	= FormatContentClass object
		ds:di	= FormatContentClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentRescanList	method dynamic FormatContentClass, 
					MSG_FORMAT_CONTENT_RESCAN_LIST
		uses	ax, cx, dx, bp
		.enter
	;
	;  Get rid of any existing vis-formats.
	;
		mov	ax, MSG_FORMAT_CONTENT_DISABLE_LIST
		call	ObjCallInstanceNoLock
		push	ds:[LMBH_handle], si		; save block, chunk
	;
	;  Get the format count for the current icon.
	;
		push	si
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_DB_VIEWER_GET_DATABASE
		call	ObjCallInstanceNoLock		; bp = file handle
		mov	ax, MSG_DB_VIEWER_GET_CURRENT_ICON
		call	ObjCallInstanceNoLock		; ax = icon
		pop	si
		
		call	IdGetFormatCount		; bx = format count
		mov_tr	ax, bx
		tst	ax				; if no formats, then
		jz	doneLoop			; don't add any children
	;
	;  For each format, add a vis-child.
	;
		clr	cx				; cx = counter
formatLoop:
		call	AddVisFormat
		
		inc	cx
		cmp	cx, ax
		jl	formatLoop
doneLoop:
		pop	bx, si				; pop block, chunk
		call	MemDerefDS			; *ds:si = us
	;
	;  Redraw.
	;
		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
		.leave
		ret
FormatContentRescanList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVisFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a vis-format to the format viewer.

CALLED BY:	DBViewerRescanDatabase

PASS:		es = dgroup (segment of VisFormatClass)
		*ds:si = FormatContent object
		cx = format number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- instantiate a new VisFormat
	- add it to the vis tree
	- tell the child its number

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVisFormat	proc	near
		class	FormatContentClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		push	cx				; save icon number
		push	si				; our chunk
		
		mov	bx, ds:[LMBH_handle]		; our block
		mov	di, offset es:VisFormatClass
		call	ObjInstantiate			; si = new object
		mov	ax, si				; *ds:ax = vis-icon
		
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bp, CCO_LAST
		pop	si				; *ds:si = content
		
		push	ax				; save vis-icon chunk
		mov	ax, MSG_VIS_ADD_CHILD
		call	ObjCallInstanceNoLock
		
		pop	si				; *ds:si = vis-icon
		pop	cx				; restore icon number
		mov	ax, MSG_VIS_FORMAT_INITIALIZE
		call	ObjCallInstanceNoLock
		
		.leave
		ret
AddVisFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentDisableList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	removes all the vis-formats from the list, so there's
		nothing to draw.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- destroy all our vis-children

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentDisableList	method	dynamic	FormatContentClass,
					MSG_FORMAT_CONTENT_DISABLE_LIST
		uses	ax,cx,dx,bp
		.enter
	;
	;  Send a destroy event to each child.
	;
		push	ds:[LMBH_handle], si
		
		GetResourceSegmentNS	VisFormatClass, es
		mov	bx, es
		mov	si, offset VisFormatClass
		mov	di, mask MF_RECORD
		mov	ax, MSG_VIS_REMOVE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		pop	bx, si
		call	MemDerefDS		; *ds:si = FormatContent
		mov	cx, di			; ^hcx = classed event
		mov	ax, MSG_VIS_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock
	
		.leave
		ret
FormatContentDisableList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentRedrawFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws a specific vis-format.

CALLED BY:	MSG_FORMAT_CONTENT_REDRAW_FORMAT
PASS:		*ds:si	= FormatContentClass object
		ds:di	= FormatContentClass instance data
		cx	= child to redraw

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentRedrawFormat	method dynamic FormatContentClass, 
					MSG_FORMAT_CONTENT_REDRAW_FORMAT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Find the child to redraw.
	;
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock
		jc	done
	;
	;  Redraw the darn thing.
	;
		mov	si, dx			; *ds:si = format to redraw
		mov	ax, MSG_VIS_FORMAT_INVALIDATE
		call	ObjCallInstanceNoLock
done:		
		.leave
		ret
FormatContentRedrawFormat	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentGetChildSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the spacing desired for the children.

CALLED BY:	MSG_VIS_COMP_GET_CHILD_SPACING

PASS:		nothing

RETURN:		cx = spacing between children
		dx = spacing between lines of wrapping children

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentGetChildSpacing	method dynamic FormatContentClass, 
					MSG_VIS_COMP_GET_CHILD_SPACING

		mov	cx, FORMAT_CONTENT_CHILD_SPACING
		mov	dx, FORMAT_CONTENT_CHILD_SPACING

		ret
FormatContentGetChildSpacing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the margins in which children will be placed.

CALLED BY:	MSG_VIS_COMP_GET_MARGINS

PASS:		nothing

RETURN:		ax = left margin
		bp = top margin
		cx = right margin
		dx = bottom margin

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentGetMargins	method dynamic FormatContentClass, 
					MSG_VIS_COMP_GET_MARGINS

		mov	ax, FORMAT_CONTENT_MARGIN_WIDTH
		mov	bp, ax
		mov	cx, ax
		mov	dx, ax

		ret
FormatContentGetMargins	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatContentKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the message along to the viewer.

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= FormatContentClass object
		ds:di	= FormatContentClass instance data

		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatContentKbdChar	method dynamic FormatContentClass, 
					MSG_META_KBD_CHAR
		.enter
	;
	;  Send it to the viewer.
	;
		mov	si, offset IconDBViewerTemplate
		call	ObjCallInstanceNoLock
	;
	;  Kill the selection ants, if any...
	;
		mov	si, offset BMO
		mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
		call	ObjCallInstanceNoLock
		
		.leave
		ret
FormatContentKbdChar	endm


FormatCode	ends
