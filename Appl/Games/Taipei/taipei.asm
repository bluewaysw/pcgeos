COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Taipei Mahjongg
FILE:		taipei.asm

AUTHOR:		Jason Ho, Jan 23, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/23/95		Initial revision

DESCRIPTION:
	Implementation of the Taipei class

	$Id: taipei.asm,v 1.1 97/04/04 15:14:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TaipeiClassStructures 	segment resource
	TaipeiTileClass		; have to put the class definition somewhere...
TaipeiClassStructures	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tile

CALLED BY:	via MSG_VIS_DRAW

PASS:		*ds:si	= Instance
		ds:di	= Instance
		bp	= GState to use

RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileDraw	method	dynamic TaipeiTileClass, MSG_VIS_DRAW
	;
	; Make sure we got passed a valid gstate to use.
	;
EC <		Assert	gstate, bp					>

		mov	si, di			; es:si <- our instance data
		mov	di, bp			; di <- gstate
		call	TaipeiTileDrawShape	; ax <- VI_bounds.R_left 
						; bx <- VI_bounds.R_top
						; cx, dx destroyed
	;
	; See if we can cheat and get away with drawing the bitmap.
	; The condition is: TTI_tileTop2 == NO_TILE and TTI_tileTop1
	; is in content
	;
		cmp	ds:[si].TTI_tileTop2, NO_TILE
		jne	dohhh
		mov	cx, ds:[si].TTI_tileTop1
		cmp	cx, NO_TILE
		je	dohhh
		push	ax, si
		mov	ax, MSG_TAIPEI_CONTENT_IS_TILE_IN
		mov	si, offset TaipeiViewContent
		call	ObjCallInstanceNoLock	; ax <- TRUE if in
		tst	ax
		pop	ax, si
		jnz	shortCut
dohhh:

		push	ax, bx
	;
	; Set up to draw tile bitmap.
	;
		mov	si, ds:[si].TTI_type
		shl	si			; word sized offset
		mov	si, cs:[tileBitmapOffsetTable][si]

		GetResourceHandleNS	BitmapResource, bx
		mov	cx, bx			; cx <- handle to bitmap
		
		call	MemLock			; ax <- segment
		mov	ds, ax			; ds:si <- pointer to bitmap
		mov	si, ds:[si]

		pop	ax, bx
		inc	ax
		inc	bx
		clr	dx
		call	GrDrawBitmap
	;
	; Draw an inverted rectangle
	;
	;
	; Unlock memory
	;
		mov_tr	bx, cx
		call	MemUnlock		; ax <- segment
quit:
		ret
shortCut:
		jmp	quit
		
TaipeiTileDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileDrawShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tile without the bitmap picture, but with fancy
		shadow and tile face background

CALLED BY:	via TaipeiTileDraw

PASS:		ds:si	= Instance
		di	= GState to use

RETURN:		ax	= VI_bounds.R_left
		bx	= VI_bounds.R_top

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileDrawShape	proc	near
	class	TaipeiTileClass

EC <		Assert	gstate, di					>
	;
	; Set up the color of dark shadow (bottom/right)
	;
		mov	ah, CF_INDEX
		mov	al, TILE_DARK_SHADOW
		call	GrSetLineColor		
	;
	; Set up the color of tile background
	; 	(ah 	= CF_INDEX)
	;
		mov	al, TILE_BACKGROUND
		test	ds:[si].TTI_miscFlags, mask TTF_SELECTED
		jz	normal
		mov	al, TILE_HILITE_COLOR
normal:		
		call	GrSetAreaColor		
	;
	; Load up the coordinates for drawing shadows
	;
		mov	ax, ds:[si].VI_bounds.R_left
		mov	bx, ds:[si].VI_bounds.R_top
		add	ax, TILE_SHADOW_AMOUNT	; farthest shadow off
						; by 3 pixels
		add	bx, TILE_SHADOW_AMOUNT
		mov	cx, ax
		add	cx, TILE_WIDTH
		mov	dx, bx
		add	dx, TILE_HEIGHT
		dec	cx
		dec	dx
	;
	; Draw the shadows for the tile
	;
		call	GrDrawRect
		dec	ax
		dec	bx
		dec	cx
		dec	dx
	;
	; Change to light shadow
	;
		push	ax
		mov	ah, CF_INDEX
		mov	al, TILE_BOTTOM_RIGHT_COLOR
		call	GrSetLineColor
		pop	ax
		
		call	GrDrawRect
		dec	ax
		dec	bx
		dec	cx
		dec	dx
		call	GrDrawRect
		dec	ax
		dec	bx
		dec	cx
		dec	dx
		call	GrDrawRect
		
	;
	; Draw the tile bitmap background
	;
		inc	ax
		inc	bx
		call	GrFillRect
		dec	ax
		dec	bx
	;
	; Set up the color of shadow (top/left)
	;
		push	ax
		mov	ah, CF_INDEX
		mov	al, TILE_TOP_LEFT_COLOR
		call	GrSetLineColor		
		pop	ax
	;
	; Draw the top / left shadow (white)
	;
		call	GrDrawVLine
		call	GrDrawHLine
		ret
TaipeiTileDrawShape	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the object.

CALLED BY:	via MSG_META_INITIALIZE

PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= Segment containing class

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiInitialize	method	dynamic TaipeiTileClass, MSG_META_INITIALIZE

	;
	; Call superclass to do initialization.
	;
	;	mov	di, offset es:TaipeiTileClass
		mov	di, offset TaipeiTileClass
		call	ObjCallSuperNoLock
	;
	; Clear some bits so our object will come up in the way that the
	; system expects...
	;
	; Yeah, this is mystery-bits stuff.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
	
		andnf	ds:[di].VI_attrs, not mask VA_REALIZED
		andnf	ds:[di].VI_optFlags, not mask VOF_IMAGE_INVALID

	;
	; Make sure the flags are valid.
	;
EC <		Assert	record, ds:[di].VI_attrs, VisAttrs		>
EC <		Assert	record, ds:[di].VI_optFlags, VisOptFlags	>

		clr	ds:[di].TTI_miscFlags
		ret
TaipeiInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileSetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNONSIS:	Set the type of tile (bamboo, crak, ...)
		the index of tile (0..143 INITIAL_NUMBER_OF_TILES-1)
		the level of tile (level 0 = ground)
		the position of tile
		index of 2 tiles on top (for drawing optimization)

CALLED BY:	MSG_TAIPEI_TILE_SET_INFO

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		ss:bp	= BoardConfigBlock

RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileSetInfo	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_SET_INFO
	;
	; Save the type in instance data
	;
		mov	cx, ss:[bp].BCT_type
EC <		Assert	etype, cx, TaipeiTileType			>
		mov	ds:[di].TTI_type, cx
	;
	; Save the index
	;
		mov	cx, ss:[bp].BCT_index
EC <		Assert	srange, cx, 0, MAX_TILE_INDEX			>
		mov	ds:[di].TTI_index, cx
	;
	; Save the level
	;
		mov	cx, ss:[bp].BCT_level
EC <		Assert	etype, cx, TaipeiLevelType			>
		mov	ds:[di].TTI_level, cx
	;
	; Save the top1
	;
		mov	cx, ss:[bp].BCT_top1
EC <		Assert	srange, cx, 0, MAX_TILE_INDEX			>
		mov	ds:[di].TTI_tileTop1, cx
	;
	; Save the top2
	;
		mov	cx, ss:[bp].BCT_top2
EC <		Assert	srange, cx, 0, MAX_TILE_INDEX			>
		mov	ds:[di].TTI_tileTop2, cx
	;
	; Save the position in instance data
	;
		mov	cx, ss:[bp].BCT_position.P_x
EC <		Assert	srange, cx, 0, MAX_GRID_X_POSITION		>
		mov	ds:[di].TTI_position.P_x, cx

		mov	cx, ss:[bp].BCT_position.P_y
EC <		Assert	srange, cx, 0, MAX_GRID_Y_POSITION		>
		mov	ds:[di].TTI_position.P_y, cx

		ret
TaipeiTileSetInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Meta start select message.

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass
		cx	= X position of mouse
		dx 	= Y position of mouse

RETURN:		ax	= MouseReturnFlags (ui.def)
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		if (I was selected before) {
			mark that I am not anymore
			redraw
			notify content
			(quit)
		}
		
		if (left is clear) or (right is clear)
			Check Upper is clear
		else	quit

		if (Upper is not clear) quit

		Redraw (so that a yellow background is used)

		Notify content that I am being selected

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileStartSelect	method dynamic TaipeiTileClass, 
					MSG_META_START_SELECT
	;
	; check if I was selected before
	;
		test	ds:[di].TTI_miscFlags, mask TTF_SELECTED
		jz	firstTime

		mov	ax, MSG_TAIPEI_TILE_UNSELECTED
		call	ObjCallInstanceNoLock
		jmp	notifyContent
		
	;
	; check if the tile is free
	;
firstTime:
		mov	ax, MSG_TAIPEI_TILE_CHECK_STATUS
		call	ObjCallInstanceNoLock		; cx <- TRUE
							; if free, else FALSE
		jcxz	quit
	;
	; Mark that I am being selected 
	;
		BitSet	ds:[di].TTI_miscFlags, TTF_SELECTED
	;
	; Draw a shaded box
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock	; Force it to redraw
	;
	; Notify the content that I am being selected
	;
notifyContent:
		mov	cx, si
		mov	dx, ds:[di].TTI_type
		mov	ax, MSG_TAIPEI_CONTENT_ONE_TILE_SELECTED
		call	VisCallParent
quit:
	;
	; Let the caller know that we've actually handled something
	;
		mov	ax, mask MRF_PROCESSED
		
		ret
TaipeiTileStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide itself from the TaipeiViewContent

CALLED BY:	MSG_TAIPEI_TILE_HIDE

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass

RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Notify the content that I am leaving, and
		invalidate the view, so that the view redraws.
		Then hide itself from the content by setting
		bits (become undrawable, undetectable)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileHide	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_HIDE
	;
	; Notify content that it is leaving the content
	;
		mov	ax, MSG_TAIPEI_CONTENT_TILE_GONE
		mov	cx, ds:[di].TTI_index
		call	VisCallParent			; ax, bx, cx destroyed
	;
	; Mark that I am not being selected (in case user undo, I
	; would not be selected anymore)
	;
		BitClr	ds:[di].TTI_miscFlags, TTF_SELECTED
	;
	; Leave the content
	;
		andnf	ds:[di].VI_attrs, not mask VA_DETECTABLE
		andnf	ds:[di].VI_attrs, not mask VA_DRAWABLE

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock

		ret
		
TaipeiTileHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileUnhide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unide itself from the TaipeiViewContent

CALLED BY:	MSG_TAIPEI_TILE_UNHIDE

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass

RETURN:		nothing
DESTROYED:	everything except bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Notify the content that I am coming back, and
		invalidate the view, so that the view redraws.
		Then set the bits so that it redraws and receives
		mouse msg again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileUnhide	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_UNHIDE
	;
	; Notify content that it is entering the content
	;
		mov	ax, MSG_TAIPEI_CONTENT_TILE_COME_BACK
		mov	cx, ds:[di].TTI_index
		call	VisCallParent			; ax, bx, cx destroyed
	;
	; Enter the content (in fact, unhide from the content)
	;
		ornf	ds:[di].VI_attrs, mask VA_DETECTABLE
		ornf	ds:[di].VI_attrs, mask VA_DRAWABLE

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock

		ret
TaipeiTileUnhide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileUnselected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The tile was selected before, but it's no longer
		selected.

CALLED BY:	MSG_TAIPEI_TILE_UNSELECTED

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass

RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:
		lmem might move

PSEUDO CODE/STRATEGY:
		Draw the shadow rectangle over the drawn one, and mark
		that I am no longer selected.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileUnselected	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_UNSELECTED
		BitClr	ds:[di].TTI_miscFlags, TTF_SELECTED
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock	; Force it to redraw

		ret
TaipeiTileUnselected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileNewRestartGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requests new game, and each tile gets this message
		from the content.

CALLED BY:	MSG_TAIPEI_TILE_ANOTHER_GAME
		MSG_TAIPEI_TILE_RESTART_GAME

PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		clear the bits instance data.
		Keep the position.
		Get the new TTI_type.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileNewRestartGame	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_ANOTHER_GAME,
					MSG_TAIPEI_TILE_RESTART_GAME
		infoBlock	local	BoardConfigBlock
		uses	ax, cx, dx, bp
		.enter
		
		clr	ds:[di].TTI_miscFlags
		ornf	ds:[di].VI_attrs, mask VA_MANAGED or \
    					  mask VA_DRAWABLE or \
					  mask VA_DETECTABLE or \
					  mask VA_FULLY_ENABLED
		cmp	ax, MSG_TAIPEI_TILE_RESTART_GAME
		je	quit
		
		segmov	es, ds
		
		GetResourceHandleNS DataResource, bx	; bx <- handle of
							; DataResource 
		call	MemLock				; ax <- segment of
							; lmem block
		mov_tr	ds, ax				; ds <- segment lmem
		mov	si, offset BoardInfo		; *ds:si <- chunk
							; array 

		mov	ax, es:[di].TTI_index		; ax <- index
		mov	cx, ss
		lea	dx, ss:[infoBlock]
		call	ChunkArrayGetElement		; cx:dx <- element
							; caray set
							; if out of bound
		call	MemUnlock
		mov	ax, ss:[infoBlock].BCT_type
		mov	es:[di].TTI_type, ax
quit:		
		.leave
		ret
TaipeiTileNewRestartGame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileCheckFreeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request from the content or itself to check if it is free.
		(nothing at left OR right, and nothing above it)

CALLED BY:	MSG_TAIPEI_TILE_CHECK_STATUS
PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass
		ax	= message #
RETURN:		cx	= TRUE if free
		cx	= FALSE if not free
DESTROYED:	everything
SIDE EFFECTS:	ds:[di].TTI_miscFlags mask TTF_CURRENTLY_FREE status
		is updated. MSG_TAIPEI_CONTENT_TYPE_FREE is called if
		this tile is free.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileCheckFreeStatus	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_CHECK_STATUS
	;
	; if I am not visible, don't bother
	;
		test	ds:[di].VI_attrs, mask VA_DETECTABLE
		jz	notFree
	;
	; call content to see if I am free
	;
		mov	cx, ds:[di].TTI_index
		mov	ax, MSG_TAIPEI_CONTENT_IS_TILE_FREE
		call	VisCallParent		; ax = 1 if tile is free
		tst	ax
		jz	notFree
	;
	; so the tile is free. Update instance data, call
	; MSG_TAIPEI_CONTENT_TYPE_FREE, and quit
	;
if _GIVE_HINT
		BitSet	ds:[di].TTI_miscFlags, TTF_CURRENTLY_FREE
		mov	ax, MSG_TAIPEI_CONTENT_TYPE_FREE
		mov	cx, ds:[di].TTI_type
		call	VisCallParent
endif
		mov	cx, TRUE
		jmp	quit
		
notFree:
if _GIVE_HINT
		BitClr	ds:[di].TTI_miscFlags, TTF_CURRENTLY_FREE
endif
		mov	cx, FALSE
quit:		ret

TaipeiTileCheckFreeStatus	endm


if _GIVE_HINT
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiTileHintFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by content: invert if it is free and there is
		matching free tiles in the content.

CALLED BY:	MSG_TAIPEI_TILE_HINT_FLASH
PASS:		*ds:si	= TaipeiTileClass object
		ds:di	= TaipeiTileClass instance data
		es 	= segment of TaipeiTileClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:
		if ds:[di].TTI_miscFlags mask TTF_CURRENTLY_FREE, get
		the # of free compatible tiles in the content.
		if number > 1, invert.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiTileHintFlash	method dynamic TaipeiTileClass, 
					MSG_TAIPEI_TILE_HINT_FLASH
		
		test	ds:[di].TTI_miscFlags, mask TTF_CURRENTLY_FREE
		jz	quit
	;
	; just in case user takes away me between flashes
	;
		test	ds:[di].VI_attrs, mask VA_DETECTABLE
		jz	quit
		mov	ax, MSG_TAIPEI_CONTENT_NUM_OF_FREE_WITH_TYPE
		mov	cx, ds:[di].TTI_type
		call	VisCallParent			; cx <- # of free
							; compatible tiles
		cmp	cx, 1
		je	quit
	;
	; invert the tile
	;

		xor	ds:[di].TTI_miscFlags, not mask TTF_SELECTED
		xor	ds:[di].TTI_miscFlags, mask TTF_SELECTED or \
			mask TTF_CURRENTLY_FREE
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		
quit:		ret

TaipeiTileHintFlash	endm

endif
CommonCode	ends
