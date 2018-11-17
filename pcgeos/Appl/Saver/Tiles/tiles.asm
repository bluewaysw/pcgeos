COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Tiles
FILE:		tiles.asm

AUTHOR:		Gene Anderson, Mar 31, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/31/92		Initial revision
	stevey	12/20/92	port to 2.0

DESCRIPTION:
	Tiles screen saver

	$Id: tiles.asm,v 1.1 97/04/04 16:48:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	tiles.def

;=============================================================================
;
;				OBJECT CLASSES
;
;=============================================================================

TilesApplicationClass	class	SaverApplicationClass

MSG_TILES_APP_DRAW			message
;
;	Move a tile.  Sent by timer.
;
;	Pass:	nothing
;	Return:	nothing
;

	TAI_speed	word	TILES_MEDIUM_SPEED
	TAI_size	byte	TILES_MEDIUM_PIECE
	TAI_bevel	word	TILES_NO_BEVEL
	TAI_timerHandle	hptr	0
		noreloc	TAI_timerHandle
	TAI_timerID	word	0
	TAI_random	hptr	0
		noreloc	TAI_random

TilesApplicationClass	endc

TilesProcessClass	Class	GenProcessClass
TilesProcessClass	endc

;==============================================================================
;
;				VARIABLES
;
;==============================================================================

include	tiles.rdef
ForceRef TilesApp

udata	segment

winWidth	word
winHeight	word
ourHeight	word
ourWidth	word

pieceSize	word				; size of a piece (pixels)
numRows		word				; # of pieces high
numColumns	word				; # of piece wide
openRow		word				; row of open piece
openColumn	word				; column of open piece
lastDirection	byte				; last direction traveled
maxBlit		word				; maximum blit amount

udata	ends

idata	segment

TilesProcessClass	mask CLASSF_NEVER_SAVED
TilesApplicationClass

idata	ends

TilesCode	segment resource

.warn	-private
tilesOptionTable	SAOptionTable	<
	tilesCategory, length tilesOptions
>
tilesOptions	SAOptionDesc	<
	tilesSpeedKey, size TAI_speed, offset TAI_speed
>, <
	tilesSizeKey, size TAI_size, offset TAI_size
>, <
	tilesBevelKey, size TAI_bevel, offset TAI_bevel
>

.warn	@private
tilesCategory	char	'tiles', 0
tilesSpeedKey	char	'speed', 0
tilesSizeKey	char	'size', 0
tilesBevelKey	char	'bevel', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= TilesApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesLoadOptions	method dynamic TilesApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset	tilesOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset	TilesApplicationClass
	GOTO	ObjCallSuperNoLock
TilesLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the screen isn't blanked first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= TilesApplicationClass object
		ds:di	= TilesApplicationInstance

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesAppGetWinColor	method dynamic TilesApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset	TilesApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
TilesAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate, and get things rolling.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= TilesApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesAppSetWin	method dynamic TilesApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset TilesApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].TilesApplication_offset

	;
	; Create a random number generator.
	; 

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].TAI_random, bx

	;
	;  Do all our specific initialization.
	;

	call	TilesStart

	;
	; Start up the timer to draw a new line.
	;

	call	TilesSetTimer

	ret
TilesAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= TilesApplicationClass object
		ds:di	= TilesApplicationInstance

RETURN:		dx	= old Window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesAppUnsetWin	method dynamic TilesApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 

	clr	bx
	xchg	bx, ds:[di].TAI_timerHandle
	mov	ax, ds:[di].TAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	; 

	clr	bx
	xchg	bx, ds:[di].TAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	; 

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset TilesApplicationClass
	GOTO	ObjCallSuperNoLock
TilesAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	TilesAppSetWin

PASS:		ds:[di] = TilesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	 3/24/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesStart	proc	near
	class	TilesApplicationClass
	uses	ax,bx,cx,dx
	.enter

	mov	es:[lastDirection], -1

	;
	; Save the window and gstate we were given for later use.
	;

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	inc	dx
	mov	es:[winHeight], dx
	mov	es:[ourHeight], dx

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	inc	dx
	mov	es:[winWidth], dx
	mov	es:[ourWidth], dx

	;
	; We're dull - we always draw in black
	;

	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	mov	al, mask CMM_ON_BLACK
	call	GrSetAreaColorMap

	mov	di, ds:[si]
	add	di, ds:[di].TilesApplication_offset

	;
	; Initalize the board and pieces
	;

	call	InitTiles

	;
	; Initialize the maximum blit amount, based on the speed and
	; size of the pieces.  We also round it up to the next byte
	; multiple, since that will generally be faster to blit.
	;

	clr	dx
	mov	ax, es:[pieceSize]		;dx:ax <- size of pieces
	div	ds:[di].TAI_speed		;/speed (low speed # = fast)
	inc	ax				;zero is truly evil
	add	ax, 0x7
	andnf	ax, 0xfff8			;round to next byte multiple
	mov	es:[maxBlit], ax

	.leave
	ret
TilesStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the tiles

CALLED BY:	TilesStart

PASS:		es:winWidth	= width of window
		es:winHeight 	= height of window
		ds:[di]		= TilesApplicationInstance

RETURN:		es:pieceSize	= size of a piece (pixels)
		es:numRows	= number of rows
		es:numColumns	= number of columns
		es:openRow	= open row (0 to r-1)
		es:openColumn	= open column (0 to c-1)

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitTiles	proc	near
	class	TilesApplicationClass
	.enter

	;
	; Initialize the piece size.  If we're on a weird screen like
	; CGA or HGC, using 1/4,1/8 or 1/16 of the screen width may
	; result in a single row.  To avoid this, we check the large
	; size to make sure it won't have a problem.  If it will, we
	; use 1/4,1/8 or 1/16 of the screen height instead.
	;

	mov	bx, es:[winWidth]
	mov	cl, TILES_LARGE_PIECE
	shr	bx, cl				; bx <- large piece size
	clr	dx
	mov	ax, es:[winHeight]
	div	bx				; ax <- # of rows
	cmp	ax, 1				; need at least one row
	mov	ax, es:[winHeight]		; in case we branch
	jbe	useHeight			; branch if only one row
	mov	ax, es:[winWidth]		; ax <- width of Window

useHeight:
	mov	cl, ds:[di].TAI_size		; cl <- size
	shr	ax, cl				; width / {4,8 or 16}
	mov	es:[pieceSize], ax		; save piece size

	;
	; Calculate the number of rows of pieces
	;

	mov	ax, es:[winHeight]		; ax <- height of Window
	clr	dx
	div	es:[pieceSize]			; ax <- # of rows
	mov	es:[numRows], ax		; save # of rows
	tst	dx				; any remainder?
	jz	rowsOK				; branch if no remainder

	;
	; If there is a partial row, erase it -- blitting partial pieces
	; eventually nukes part of every piece on the screen.
	;

	mov	ax, es:[numRows]
	clr	bx				; (ax,bx) <- (r,c)
	call	GetScreenPos			; (ax,bx) <- upper left
	mov	cx, es:[winWidth]
	mov	dx, es:[winHeight]		; (cx,dx) <- lower right
	mov	bp, di
	mov	di, ds:[di].SAI_curGState
	call	GrFillRect
	mov	di, bp
	mov	es:[ourHeight], bx

rowsOK:
	;
	; Calculate the number of columns of pieces
	;
	mov	ax, es:[winWidth]		; ax <- width of Window
	clr	dx
	div	es:[pieceSize]			; ax <- # of columns
	mov	es:[numColumns], ax		; save # of columns
	tst	dx				; any remainder?
	jz	columnsOK			; branch if no remainder

	;
	; If there is a partial column, erase it -- blitting partial pieces
	; eventually nukes part of every piece on the screen.
	;

	mov	bx, ax
	clr	ax				; (ax,bx) <- (r,c)
	call	GetScreenPos			; (ax,bx) <- upper left
	mov	cx, es:[winWidth]
	mov	dx, es:[winHeight]		; (cx,dx) <- lower right
	mov	bp, di
	mov	di, ds:[di].SAI_curGState
	call	GrFillRect
	mov	di, bp
	mov	es:[ourWidth], ax

columnsOK:
	;
	; Calculate the initial open spot
	;
	mov	dx, es:[numColumns]		; dx <- # of columns
	mov	bx, ds:[di].TAI_random
	call	SaverRandom

	mov	es:[openColumn], dx		; save x open
	mov	dx, es:[numRows]		; dx <- # of rows
	call	SaverRandom
	mov	es:[openRow], dx		; save y open

	;
	; Erase the initial tile
	;

	call	EraseOpenTile

	;
	; Initalize grid lines
	;

	call	InitGridLines

	.leave
	ret
InitTiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize grid lines

CALLED BY:	InitTiles

PASS:		ds:[di]		= TilesApplicationInstance
		es:[numRows]	= number of rows
		es:[numColumns]	= number of columns
		es:[winHeight]	= height of screen
		es:[winWidth] 	= width of screen

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitGridLines	proc	near
	class	TilesApplicationClass
	.enter

	;
	; Frame each piece
	;

	clr	bx				; bx <- y1

rowLoop:
	;
	; For each row...
	;

	clr	ax				; ax <- x position
	mov	dx, bx
	add	dx, es:[pieceSize]		; dx <- bottom of rectangle

columnLoop:
	;
	; For each column...
	;

	mov	bp, di				; bp = instance data
	mov	di, ds:[di].SAI_curGState

	push	ax
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetLineColor
	pop	ax

	mov	cx, ax
	add	cx, es:[pieceSize]		; cx <- right of rectangle
	call	GrDrawRect			; draw me jesus
	mov	di, bp				; di = instance data

	tst	ds:[di].TAI_bevel		; any beveled edge?
	jz	noBevel
	call	InitBevel

noBevel:
	;
	; More columns?
	;

	add	ax, es:[pieceSize]		; ax <- next x position
	cmp	ax, es:[ourWidth]		; to right side yet?
	jb	columnLoop			; loop while more

	;
	; More rows?
	;

	add	bx, es:[pieceSize]		; bx <- next y position
	cmp	bx, es:[ourHeight]		; to bottom yet?
	jb	rowLoop				; loop while more

	.leave
	ret
InitGridLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw bevel for pieces

CALLED BY:	InitGridLines

PASS:		ds:[di]		= TilesApplicationInstance
		es		= dgroup
		(ax,bx,cx,dx)	= bounds of piece to bevel

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/92		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitBevel	proc	near
	class	TilesApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	mov	si, ds:[di].TAI_bevel		; si <- # of lines
	mov	di, ds:[di].SAI_curGState

bevelLoop:
	inc	ax
	inc	bx
	dec	cx
	dec	dx				; (ax,bx,cx,dx) <- inset bounds

	;
	; Draw the top left in white
	;
	push	ax
	mov	ax, C_WHITE or (CF_INDEX shl 8)
	call	GrSetLineColor
	pop	ax
	call	GrDrawHLine
	call	GrDrawVLine

	;
	; Draw the bottom right in gray
	;
	push	ax
	mov	ax, C_DARK_GRAY or (CF_INDEX shl 8)
	call	GrSetLineColor
	pop	ax

	push	bx
	mov	bx, dx
	call	GrDrawHLine
	pop	bx
	push	ax
	mov	ax, cx
	call	GrDrawVLine
	pop	ax

	;
	; Loop while more bevel lines
	;

	dec	si
	jnz	bevelLoop

	.leave
	ret
InitBevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver

CALLED BY:	MSG_TILES_APP_DRAW

PASS:		*ds:si	= TilesApplicationClass object
		ds:di	= TilesApplicationClass instance data
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesAppDraw	method dynamic TilesApplicationClass, 
					MSG_TILES_APP_DRAW
	;
	; Make sure there is a GState to draw with
	;		

	tst	ds:[di].SAI_curGState
	jz	quit

	;
	; Get the screen position of the source -- current open piece
	;

	mov	ax, es:[openRow]
	mov	bx, es:[openColumn]
	call	GetScreenPos
	mov	cx, ax
	mov	dx, bx				; (cx,dx) <- (x,y) pos

	;
	; Get a random adjacent square -- new open piece
	;

	call	GetRandomAdjacent
	mov	es:[openRow], ax
	mov	es:[openColumn], bx
	call	GetScreenPos			; (ax,bx) <- (x,y) pos

	;
	; Slide the piece into the adjacent square
	;

	push	si
	mov	si, {word}es:[lastDirection]
	shl	si, 1
	andnf	si, 0x00ff
	call	cs:slideFuncs[si]		;call correct routine

	;
	; Set another timer for next time.
	;

	pop	si
	call	TilesSetTimer
quit:

	ret

slideFuncs	nptr	\
	offset	SlideDown,
	offset	SlideLeft,
	offset	SlideUp,
	offset	SlideRight

TilesAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slide a piece down into open slot

CALLED BY:	TilesDraw

PASS:		ds:[di]		= TilesApplicationInstance
		es		= dgroup
		(ax,bx) 	= source (x,y)
		(cx,dx) 	= dest (x,y)
		es:[maxBlit]	= maximum amount to blit

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/27/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideDown	proc	near
	class	TilesApplicationClass
	uses	si, di
	.enter

	mov	di, ds:[di].SAI_curGState

	mov	si, dx				; si <- dest y
	mov	dx, bx				; dx <- source y

slideDownLoop:
	mov	bp, dx
	add	bp, es:[maxBlit]		; bp <- next position
	cmp	bp, si				; too far?
	jle	amountOK
	mov	bp, si				; bp <- limit to edge

amountOK:
	mov	dx, bp				; dx <- new dest y
	call	CallBitBlt
	push	cx
	add	cx, es:[pieceSize]		; cx <- right side
	call	GrFillRect			; obliterate old stuff
	pop	cx
	add	bx, es:[maxBlit]		; bx <- new source y
	cmp	dx, si				; reached the bottom?
	jl	slideDownLoop			; branch while more

	.leave
	ret
SlideDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slide a piece right into open slot
CALLED BY:	TilesDraw

PASS:		ds:[di]	= TilesApplicationInstance
		es	= dgroup
		(ax,bx) = source (x,y)
		(cx,dx) = dest (x,y)

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/27/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideRight	proc	near
	class	TilesApplicationClass
	uses	si, di
	.enter

	mov	di, ds:[di].SAI_curGState

	mov	si, cx				; si <- dest x
	mov	cx, ax				; cx <- source x

slideRightLoop:
	mov	bp, cx
	add	bp, es:[maxBlit]		; bp <- next position
	cmp	bp, si				; too far?
	jle	amountOK
	mov	bp, si				; bp <- limit to edge

amountOK:
	mov	cx, bp				; cx <- new dest x
	call	CallBitBlt
	push	dx
	add	dx, es:[pieceSize]		; dx <- bottom
	call	GrFillRect			; obliterate old stuff
	pop	dx
	add	ax, es:[maxBlit]		; ax <- new source x
	cmp	cx, si				; reached the right?
	jl	slideRightLoop			; branch while more

	.leave
	ret
SlideRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slide a piece up into open slot

CALLED BY:	TilesDraw

PASS:		ds:[di] = TilesApplicationInstance
		es	= dgroup
		(ax,bx) = source (x,y)
		(cx,dx) = dest (x,y)

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/27/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideUp	proc	near
	class	TilesApplicationClass
	uses	si, di
	.enter

	mov	di, ds:[di].SAI_curGState

	mov	si, dx				; si <- dest y
	mov	dx, bx				; dx <- source y

slideUpLoop:
	mov	bp, dx
	sub	bp, es:[maxBlit]		; bp <- next position
	cmp	bp, si				; too far?
	jge	amountOK
	mov	bp, si				; bp <- limit to edge

amountOK:
	mov	dx, bp				; dx <- new dest y
	call	CallBitBlt
	push	cx, bx, dx
	add	cx, es:[pieceSize]		; cx <- right side
	add	bx, es:[pieceSize]
	add	dx, es:[pieceSize]
	call	GrFillRect			; obliterate old stuff
	pop	cx, bx, dx
	sub	bx, es:[maxBlit]		; bx <- new source y
	cmp	dx, si				; reached the top?
	jg	slideUpLoop			; branch while more

	.leave
	ret
SlideUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlideLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slide a piece left into open slot

CALLED BY:	TilesDraw

PASS:		ds:[di] = TilesApplicationInstance
		es	= dgroup
		(ax,bx) = source (x,y)
		(cx,dx) = dest (x,y)

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/27/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlideLeft	proc	near
	class	TilesApplicationClass
	uses	si, di
	.enter

	mov	di, ds:[di].SAI_curGState

	mov	si, cx				; si <- dest x
	mov	cx, ax				; cx <- source x

slideLeftLoop:
	mov	bp, cx
	sub	bp, es:[maxBlit]		; bp <- next position
	cmp	bp, si				; too far?
	jge	amountOK
	mov	bp, si				; bp <- limit to edge

amountOK:
	mov	cx, bp				; cx <- new dest x
	call	CallBitBlt
	push	dx, ax, cx
	add	dx, es:[pieceSize]		; dx <- bottom
	add	ax, es:[pieceSize]
	add	cx, es:[pieceSize]
	call	GrFillRect			; obliterate old stuff
	pop	dx, ax, cx
	sub	ax, es:[maxBlit]		; ax <- new source x
	cmp	cx, si				; reached the left?
	jg	slideLeftLoop			; branch while more

	.leave
	ret
SlideLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallBitBlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up params and call GrBitBlt

CALLED BY:	SlideLeft, SlideRight, SlideDown, SlideUp

PASS:		di		= SAI_curGState
		es		= dgroup
		es:pieceSize 	= size of pieces to blt
		(ax,bx) 	= source (x,y)
		(cx,dx)		= dest (x,y)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/27/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallBitBlt	proc	near
	class	TilesApplicationClass
	uses	si
	.enter

	push	es:[pieceSize]			; pass height of block
	mov	si, BLTM_COPY
	push	si				; pass BLTMode
	mov	si, es:[pieceSize]		; si = width of block
	call	GrBitBlt			; bit-blit me jesus

	.leave
	ret
CallBitBlt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRandomAdjacent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get random square adjacent to current open one

CALLED BY:	TilesDraw

PASS:		ds:[di]			= TilesApplicationInstance
		es			= dgroup
		es:openRow,openColumn	= open (r,c)
		es:numRows,numColumns	= number of (r,c)
		es:lastDirection	= last direction traveled (0-3)

RETURN:		(ax,bx) - adjacent (r,c)
		ds:lastDirection - new direction (0-3)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRandomAdjacent	proc	near
	class	TilesApplicationClass
	uses	dx, si
	.enter

randomLoop:
	mov	dx, 4
	mov	bx, ds:[di].TAI_random
	call	SaverRandom			; dx <- random 0,1,2,3

	mov	si, dx
	mov	dh, dl
	add	dl, 2				; dl <- opposite direction
	andnf	dl, 0x3				; dl <- mod 4
	cmp	dl, es:[lastDirection]		; opposite of last time?
	je	randomLoop			; don't back up
	shl	si, 1				; si <- table of words
	mov	ax, es:[openRow]
	mov	bx, es:[openColumn]		; (ax,bx) <- open (r,c)
	jmp	cs:directionFunc[si]		; call correct stub

done:
	mov	es:[lastDirection], dh		; save direction

	.leave
	ret

adjacentUp:
	cmp	ax, 0
	je	randomLoop
	dec	ax				; ax <- up one row
	jmp	done

adjacentDown:
	inc	ax				; ax <- down one row
	cmp	ax, es:[numRows]
	je	randomLoop
	jmp	done

adjacentLeft:
	cmp	bx, 0
	je	randomLoop
	dec	bx				; bx <- left one column
	jmp	done

adjacentRight:
	inc	bx				; bx <- right one column
	cmp	bx, es:[numColumns]
	je	randomLoop
	jmp	done

directionFunc nptr \
	offset	adjacentUp,
	offset	adjacentRight,
	offset	adjacentDown,
	offset	adjacentLeft

GetRandomAdjacent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseOpenTile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the open tile

CALLED BY:	TilesDraw, TilesStart

PASS:		ds:[di]			= TilesApplicationInstance
		es:openRow, openColumn	= open (r,c)
		es:pieceSize		= size of each piece

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseOpenTile	proc	near
	class	TilesApplicationClass
	uses	di
	.enter

	mov	di, ds:[di].SAI_curGState

	mov	ax, es:[openRow]
	mov	bx, es:[openColumn]
	call	GetScreenPos			; (ax,bx) <- (x,y) pos

	mov	cx, ax
	add	cx, es:[pieceSize]		; cx <- right x
	dec	cx				; don't overlap
	mov	dx, bx
	add	dx, es:[pieceSize]		; dx <- bottom y
	dec	dx				; don't overlap
	call	GrFillRect			; paint it black

	.leave
	ret
EraseOpenTile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScreenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get screen position for (r,c) position

CALLED BY:	TilesAppDraw, EraseOpenTile, InitTiles

PASS:		(ax,bx)		= (r,c) position
		es		= dgroup
		es:[pieceSize] 	= size of each piece

RETURN:		(ax,bx) - (x,y) screen position

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScreenPos	proc	near
	uses	dx
	.enter

	mul	es:[pieceSize]
	push	ax				; save y position
	mov	ax, bx				; ax <- column
	mul	es:[pieceSize]			; ax <- x position
	pop	bx				; bx <- y position

	.leave
	ret
GetScreenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilesSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	TilesAppSetWin, TilesAppDraw
PASS:		*ds:si = TilesApplicationObject
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/28/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TilesSetTimer	proc	near
	class	TilesApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].TilesApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].TAI_speed
	mov	dx, MSG_TILES_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	call	TimerStart

	mov	ds:[di].TAI_timerHandle, bx
	mov	ds:[di].TAI_timerID, ax

	.leave
	ret
TilesSetTimer	endp

TilesCode	ends

