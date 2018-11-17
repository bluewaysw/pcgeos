COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		"Pieces" screen saver
FILE:		pieces.asm

AUTHOR:		David Loftesness, Sep 19, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision
	DaveL	9/20/91		made into piece hole
	stevey	12/29/92	port to 2.0

DESCRIPTION:
	Specific screen-saver library to suck the screen into oblivion

	$Id: pieces.asm,v 1.1 97/04/04 16:46:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	pieces.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

PiecesApplicationClass	class	SaverApplicationClass

MSG_PIECES_APP_DRAW				message
;
;	Draw the next line of the pieces. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    PAI_size		byte		PIECE_SMALL_SIZE
    PAI_smear		byte		0
    PAI_even		byte		0
    PAI_bounces		byte		PIECE_DEFAULT_BOUNCES
    PAI_gravity		byte		PIECE_MEDIUM_GRAVITY

    PAI_timerHandle	hptr		0
    	noreloc	PAI_timerHandle
    PAI_timerID		word

    PAI_random		hptr		0	; Random number generator
	noreloc	PAI_random

PiecesApplicationClass	endc

PiecesProcessClass	class	GenProcessClass
PiecesProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	pieces.rdef
ForceRef PiecesApp

udata	segment

winHeight	word
winWidth	word
winCheckWidth	word		; width - blitWidth
posWidth	word
posHeight	word

blitWidth	word
blitHeight	word

curPos		Point
curSpeed	Point
sourceBitmap	hptr.Bitmap	; handle of screen bitmap
underBitmap	hptr.Bitmap	; handle of saved area
underPos	Point

numBounces	byte		; number of bounces for current piece

udata	ends

idata	segment

PiecesProcessClass	mask	CLASSF_NEVER_SAVED
PiecesApplicationClass

idata	ends

;==============================================================================
;
;			CODE 'N' STUFF
;
;==============================================================================

PieceCode	segment resource

.warn -private
piecesOptionTable	SAOptionTable	<
	piecesCategory, length piecesOptions
>
piecesOptions	SAOptionDesc	<
	piecesSizeKey,	size PAI_size, offset PAI_size
>, <
	piecesSmearKey, size PAI_smear, offset PAI_smear
>, <
	piecesEvenKey, size PAI_even, offset PAI_even
>, <
	piecesBouncesKey, size PAI_bounces, offset PAI_bounces
>, <
	piecesGravityKey, size PAI_gravity, offset PAI_gravity
>
.warn @private
piecesCategory		char	'pieces', 0
piecesSizeKey		char	'size', 0
piecesSmearKey		char	'smear', 0
piecesEvenKey		char	'even', 0
piecesBouncesKey	char	'bounces', 0
piecesGravityKey	char	'gravity', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PiecesLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= PiecesApplicationClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PiecesLoadOptions	method dynamic PiecesApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax,es
	.enter

	segmov	es, cs
	mov	bx, offset piecesOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset PiecesApplicationClass
	GOTO	ObjCallSuperNoLock
PiecesLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PiecesAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the screen isn't blanked first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= PiecesApplicationClass object
		ds:di	= PiecesApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PiecesAppGetWinColor	method dynamic PiecesApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;

	mov	di, offset	PiecesApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
PiecesAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PiecesAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate to use, and get things rolling.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= PiecesApplicationClass object
		ds:di	= PiecesApplicationClass instance data
		dx	= Window
		bp	= GState
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PiecesAppSetWin	method dynamic PiecesApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset PiecesApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].PiecesApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx			; dxax <- seed
	clr	bx			; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].PAI_random, bx

	call	PieceStart

	.leave
	ret
PiecesAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieceStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	PiecesAppSetWin

PASS:		ds:[di] = PiecesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	dl	12/6/91		yeah, so?
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PieceStart	proc	near
	class	PiecesApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	push	si				; save object

	;
	; We're dull - we always draw in black
	;

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	pop	di

	;
	; Save the window and gstate we were given for later use.
	;

	mov	si, ds:[di].SAI_bounds.R_right
	sub	si, ds:[di].SAI_bounds.R_left
	mov	es:[winWidth], si

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[winHeight], dx

	mov	es:[winCheckWidth], si
	mov	es:[posWidth], si
	mov	es:[posHeight], dx

	;
	; Figure out piece size
	;

	inc	si				; width
	mov	cl, ds:[di].PAI_size		; cl <- lg2(8) or lg2(16)
	shr	si, cl				; si <- (width / (8 or 16)
	andnf	si, 0xfff8			; si <- % 8
	mov	es:[blitWidth], si
	shr	dx, cl				; dx <- (height / (8 or 16)
	mov	es:[blitHeight], dx

	;
	; Adjust special bounds
	;

	sub	es:[winCheckWidth], si
	sub	es:[posWidth], si
	sub	es:[posHeight], dx

	;
	; If doing even size pieces, adjust the size
	;

	tst	ds:[di].PAI_even
	jz	skipEven

	clr	dx
	mov	ax, es:[winWidth]		;dx:ax <- width
	mov	cx, es:[blitWidth]
	div	cx				;cx <- window / piece
	tst	dx				;any remainder?
	jz	widthOK				;branch if no remainder
	inc	ax				;adjust for remainder

widthOK:
	mov	es:[posWidth], ax		;save width
	clr	dx
	mov	ax, es:[winHeight]		;dx:ax <- height
	mov	cx, es:[blitHeight]
	div	cx				;cx <- window / piece
	tst	dx				;any remainder?
	jz	heightOK			;branch if no remainder
	inc	ax				;adjust for remainder

heightOK:
	mov	es:[posHeight], ax		;save height

skipEven:
	;
	; Set up starting points
	;
	mov	es:[curSpeed.P_y], PIECES_DONE_FLAG
	clr	es:[sourceBitmap]
	clr	es:[underBitmap]

	;
	; If smearing pieces, clear the top part of the screen
	;

	tst	ds:[di].PAI_smear
	jz	skipClear

	clr	ax
	clr	bx
	mov	cx, es:[winWidth]
	mov	dx, es:[blitHeight]
	mov	di, ds:[di].SAI_curGState
	call	GrFillRect

skipClear:
	;
	; Start up the timer to do the first spot
	;
	pop	si				; *ds:si = PieceApp
	call	PieceSetTimer

	.leave
	ret
PieceStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PiecesAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= PiecesApplicationClass object
		ds:di	= PiecesApplicationClass instance data

RETURN:		dx	= old Window
		bp	= old GState
		es	= dgroup

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PiecesAppUnsetWin	method dynamic PiecesApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].PAI_timerHandle
	mov	ax, ds:[di].PAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].PAI_random
	call	SaverEndRandom

	clr	bx
	xchg	bx, es:[sourceBitmap]
	tst	bx				;any old bitmap?
	jz	skipFree			;branch if no old bitmap
	call	MemFree

skipFree:
	clr	bx
	xchg	bx, es:[underBitmap]
	tst	bx				;any old bitmap?
	jz	skipUnderFree			;branch if no old bitmap
	call	MemFree

skipUnderFree:
	;
	; Call our superclass to take care of the rest.
	;
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset PiecesApplicationClass
	GOTO	ObjCallSuperNoLock
PiecesAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PieceSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	PiecesAppSetWin, PiecesAppDraw

PASS:		*ds:si = PiecesApplicationObject
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PieceSetTimer	proc	near
	class	PiecesApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PiecesApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, PIECE_TIMER_SPEED
	mov	dx, MSG_PIECES_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination

	call	TimerStart

	mov	ds:[di].PAI_timerHandle, bx
	mov	ds:[di].PAI_timerID, ax

	.leave
	ret
PieceSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PiecesAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of the screen Pieceing

CALLED BY:	MSG_PIECES_APP_DRAW

PASS:		*ds:si	= PiecesApplication object
		ds:[di]	= PiecesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version
	dl	12/6/91		Who's eca?
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PiecesAppDraw	method	dynamic	PiecesApplicationClass,
						MSG_PIECES_APP_DRAW
	.enter

	;
	; Make sure there is a GState to draw with
	;		

	tst	ds:[di].SAI_curGState
	jz	quit				; branch if no GState

	push	ds:[LMBH_handle], si

	;
	; See if we're currently falling
	;

	cmp	es:[curSpeed.P_y], PIECES_DONE_FLAG
	jne	drawFall			; branch if still falling

	call	SetupSource

drawFall:
	;
	; If we're dropping, recover any old piece
	;
	call	RecoverUnderPiece

	;
	; Set up new (x,y) offset
	;

	call	CheckXBounces
	call	CheckYBounces
	jc	doneBouncing			; branch if done bouncing

	mov	cx, es:[curPos.P_x]
	add	cx, es:[curSpeed.P_x]		; cx <- new x offset
	mov	es:[curPos.P_x], cx
	mov	dx, es:[curPos.P_y]
	add	dx, es:[curSpeed.P_y]		; dx <- new y offset
	mov	es:[curPos.P_y], dx

	;
	; If we're dropping, save under the new piece
	;

	call	SaveUnderPiece

	;
	; Lock and draw the bitmap
	;

	mov	bx, es:[sourceBitmap]		; bx <- handle of bitmap
	call	LockAndDrawBitmap

doneBouncing:
	;
	; Set another timer for next time.
	; 

	pop	bx, si
	call	MemDerefDS
	call	PieceSetTimer

quit:
	.leave
	ret
PiecesAppDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockAndDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock and draw a bitmap, given a handle

CALLED BY:	INTERNAL

PASS:		ds:[di]	= PiecesApplicationInstance
		bx	= handle of bitmap
		(cx,dx)	= (x,y) position

RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockAndDrawBitmap	proc	near
	class	PiecesApplicationClass
	uses	si,di,ds
	.enter

	mov	di, ds:[di].SAI_curGState

	push	bx
	call	MemLock
	mov	ds, ax
	clr	si				; ds:si <- ptr to bitmap
	mov	ax, cx
	mov	bx, dx				; (ax,bx) <- (x,y) to draw at
	call	GrDrawBitmap
	pop	bx				; bx <- handle of bitmap
	call	MemUnlock

	.leave
	ret
LockAndDrawBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up source and initial speed for blit

CALLED BY:	PiecesAppdraw

PASS:		ds:[di] = PiecesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 9/92		Initial revision
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSource	proc	near
	class	PiecesApplicationClass
	.enter

	clr	es:[numBounces]			;no bounces yet

getRandomSlideDistance:
	;
	; Get sliding speed
	;

	mov	dx, MAX_SLIDE_DISTANCE*2
	mov	bx, ds:[di].PAI_random
	call	SaverRandom

	sub	dx, MAX_SLIDE_DISTANCE		; dx <- +/- signed value
	tst	dx				; non-zero?
	jz	getRandomSlideDistance		; don't bounce straight up&down

	mov	es:[curSpeed.P_x], dx
	mov	es:[curSpeed.P_y], 1

	;
	; Get source y
	;

	mov	dx, es:[posHeight]		; bx is still PAI_random
	call	SaverRandom
	mov	bx, dx				; bx <- source y

	;
	; Get source x
	;

	mov	dx, es:[posWidth]
	push	bx
	mov	bx, ds:[di].PAI_random
	call	SaverRandom
	pop	bx
	mov	ax, dx				;ax <- source x

	;
	; Deal with rounding to even pieces, if necessary
	;

	tst	ds:[di].PAI_even
	jz	gotPosition

	mov	cx, es:[blitWidth]
	mul	cx				; ax <- x position * width
	xchg	ax, bx				; bx <- x position * width
	mov	cx, es:[blitHeight]
	mul	cx				; ax <- y position * height
	xchg	ax, bx				; ax <- x position * width

gotPosition:
	mov	es:[curPos.P_x], ax
	mov	es:[curPos.P_y], bx

	;
	; Get a bitmap of the source
	;

	mov	cx, es:[blitWidth]		; cx <- width
	mov	dx, es:[blitHeight]		; dx <- height
	push	di
	mov	di, ds:[di].SAI_curGState
	call	GrGetBitmap
	pop	di

	;
	; Erase the source rectangle, if appropriate
	;

	tst	ds:[di].PAI_smear
	jnz	skipErase

	push	bx
	mov	ax, es:[curPos].P_x
	mov	cx, ax
	add	cx, es:[blitWidth]		; cx <- right of source
	mov	bx, es:[curPos.P_y]
	mov	dx, bx
	add	dx, es:[blitHeight]		; dx <- bottom of source

	push	di
	mov	di, ds:[di].SAI_curGState
	call	GrFillRect
	pop	di
	pop	bx

skipErase:
	;
	; Free any old source bitmap
	;
	xchg	bx, es:[sourceBitmap]
	tst	bx				; any old bitmap?
	jz	skipSourceFree			; branch if no old bitmap

	call	MemFree

skipSourceFree:
	;
	; Free any save under bitmap
	;
	clr	bx
	xchg	bx, es:[underBitmap]
	tst	bx				; any old bitmap?
	jz	skipUnderFree			; branch if no old bitmap

	call	MemFree

skipUnderFree:

	.leave
	ret
SetupSource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckXBounces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if piece should bounce off a wall

CALLED BY:	PiecesAppDraw

PASS:		ds:[di]	= PiecesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 9/92		broken out from PieceDraw()
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckXBounces	proc	near
	.enter

	mov	ax, es:[curPos.P_x]
	add	ax, es:[curSpeed.P_x]

	;
	; Check the right wall
	;

	cmp	ax, es:[winCheckWidth]		; hit right wall?
	jge	doBounce

	;
	; Check the left wall
	;
	cmp	ax, 0				; hit left wall?
	jge	done

doBounce:
	neg	es:[curSpeed.P_x]		; bounce off left wall
done:

	.leave
	ret
CheckXBounces	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckYBounces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for vertical bounce

CALLED BY:	PiecesAppDraw

PASS:		es	= dgroup
		ds:[di] = PiecesApplicationInstance

RETURN:		carry set if done bouncing, clear otherwise

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckYBounces	proc	near
	class	PiecesApplicationClass
	.enter

	mov	ax, es:[curPos.P_y]
	add	ax, es:[curSpeed.P_y]
	mov	dl, ds:[di].PAI_gravity
	clr	dh				; dx <- gravity

	;
	; Check to see if we're done bouncing this piece
	;

	cmp	ax, es:[winHeight]
	jl	stillBouncing			; branch if not at bottom

	;
	; We're bouncing off the bottom
	;

	cmp	es:[curSpeed.P_y], dx		; going too slow?
	jl	doneBouncing			; branch if stopped

	inc	es:[numBounces]
	mov	al, es:[numBounces]
	cmp	al, ds:[di].PAI_bounces
	jae	doneBouncing			; branch if enough bounces
	neg	es:[curSpeed.P_y]		; bounce off the bottom

stillBouncing:
	add	es:[curSpeed.P_y], dx		; add gravity
	clc					; carry <- still bouncing
done:
	.leave
	ret

doneBouncing:
	mov	es:[curSpeed.P_y], PIECES_DONE_FLAG
	stc					; carry <- done bouncing
	jmp	done
CheckYBounces	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecoverUnderPiece
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recover any area under the piece

CALLED BY:	PiecesAppDraw

PASS:		ds:[di] = PiecesApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecoverUnderPiece	proc	near
	class	PiecesApplicationClass
	.enter

	tst	ds:[di].PAI_smear
	jnz	done

	clr	bx
	xchg	bx, es:[underBitmap]		; bx <- handle of saved area
	tst	bx
	jz	done

	mov	cx, es:[underPos.P_x]
	mov	dx, es:[underPos.P_y]		; (cx,dx) <- position
	call	LockAndDrawBitmap
	call	MemFree				; free the bitmap

done:
	.leave
	ret
RecoverUnderPiece	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveUnderPiece
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the area under the piece

CALLED BY:	PiecesAppDraw

PASS:		ds:[di] = Pieces
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveUnderPiece	proc	near
	class	PiecesApplicationClass
	uses	cx, dx, di
	.enter

	tst	ds:[di].PAI_smear
	jnz	done

	mov	ax, es:[curPos.P_x]
	mov	bx, es:[curPos.P_y]		; (ax,bx) <- (x,y) position
	cmp	bx, es:[winHeight]		; off bottom of screen?
	jae	done				; branch if off bottom

	mov	es:[underPos.P_x], ax
	mov	es:[underPos.P_y], bx
	mov	cx, es:[blitWidth]		; cx <- width
	mov	dx, es:[blitHeight]		; dx <- height

	mov	di, ds:[di].SAI_curGState
	call	GrGetBitmap
	mov	es:[underBitmap], bx

done:
	.leave
	ret
SaveUnderPiece	endp

PieceCode	ends
