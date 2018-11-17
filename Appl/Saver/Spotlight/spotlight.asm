COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Spotlight
FILE:		spotlight.asm

AUTHOR:		Steve Yegge, Apr 30, 1993

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/93		Initial revision

DESCRIPTION:
	This is a specific screen-saver library to move a Spotlight 
	around on the screen.
	
	$Id: spotlight.asm,v 1.1 97/04/04 16:45:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def
include hugearr.def
include Internal/im.def

UseLib	ui.def
UseLib	saver.def

include	spotlight.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

SpotlightApplicationClass	class	SaverApplicationClass

MSG_SPOTLIGHT_APP_DRAW				message
;
;	Draw the next line of the spotlight. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    SAI_size		word		SPOTLIGHT_DEFAULT_SIZE
    SAI_speed		word		SPOTLIGHT_DEFAULT_SPEED

    SAI_bitmapVMFile	word		0	; vm file handle
    SAI_screenGState	hptr.GState	0	; so we can edit the mask
    SAI_screenVMBlock	word		0	; vm block handle for big one
    SAI_eraseVMBlock	word		0	; eraser bitmap handle
    SAI_spotVMBlock	word		0	; spotlight bitmap handle
    SAI_spotGState	word		0	; spotlight bitmap gstate

    SAI_left		word		0 	; spotlight left side
    SAI_top		word		0	; spotlight top side
    SAI_dir		word		0	; current direction

    SAI_timerHandle	hptr		0
	noreloc	SAI_timerHandle

    SAI_timerID		word		0

    SAI_random		hptr		0	; Random number generator
	noreloc	SAI_random

SpotlightApplicationClass	endc

SpotlightProcessClass	class	GenProcessClass
SpotlightProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	spotlight.rdef
ForceRef SpotlightApp

udata	segment

udata	ends

idata	segment

SpotlightProcessClass	mask CLASSF_NEVER_SAVED
SpotlightApplicationClass

idata	ends

SpotlightCode	segment resource

.warn -private
spotlightOptionTable	SAOptionTable	<
	spotlightCategory, length spotlightOptions
>
spotlightOptions	SAOptionDesc	<
	spotlightSizeKey, size SAI_size, offset SAI_size
>, <
	spotlightSpeedKey, size SAI_speed, offset SAI_speed
> 
.warn @private
spotlightCategory	char	'spotlight', 0
spotlightSizeKey	char	'size', 0
spotlightSpeedKey	char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= SpotlightApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightLoadOptions	method	dynamic	SpotlightApplicationClass, 
						MSG_META_LOAD_OPTIONS
		uses	ax, es
		.enter
		
		segmov	es, cs
		mov	bx, offset spotlightOptionTable
		call	SaverApplicationGetOptions
		
		.leave
		mov	di, offset SpotlightApplicationClass
		GOTO	ObjCallSuperNoLock
SpotlightLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the screen is transparent.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= SpotlightApplicationClass object
		ds:di	= SpotlightApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightAppGetWinColor	method dynamic SpotlightApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
		uses	cx, dx, bp
		.enter
	;
	;  Call the superclass.
	;
		mov	di, offset SpotlightApplicationClass
		call	ObjCallSuperNoLock

		ornf	ah, mask WCF_TRANSPARENT

		.leave
		ret
SpotlightAppGetWinColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= SpotlightApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	We'll create 2 bitmaps:  1 that contains the contents of
	the screen (before blanking, of course), and 1 square the
	size of the spotlight.  The first one will have a filled
	circle in its mask that defines the spotlight.  This
	circle moves around, and we call GrDrawHugeBitmap, which
	only draws the pixels defined by the circle in the mask,
	thus defining the spotlight.

	To erase the crud left when the spotlight moves, we have
	another, square bitmap whose mask is the inverse of the
	spotlight bitmap's.  The data is just a black rectangle.
	When this "eraser" bitmap is drawn, it draws black over
	everything not in the current spotlight.  (We also draw
	black lines where the spotlight bounding square was
	before it moved, to clear the 1-pixel greebles that the
	eraser bitmap can't cover).


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightAppSetWin	method dynamic SpotlightApplicationClass,
							MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
		mov	di, offset SpotlightApplicationClass
		call	ObjCallSuperNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].SpotlightApplication_offset
	;
	; Create a random number generator.
	; 
		call	TimerGetCount
		mov	dx, bx		; dxax <- seed
		clr	bx		; bx <- allocate a new one
		call	SaverSeedRandom
		mov	ds:[di].SAI_random, bx
	;
	;  Create the screen bitmap & save it.
	;
		call	InitScreenBitmap		; ^vcx:dx = bitmap
		mov	ds:[di].SAI_bitmapVMFile, cx
		mov	ds:[di].SAI_screenVMBlock, dx
		mov	ds:[di].SAI_screenGState, ax
	;
	;  Create a solid black bitmap that will be used as the
	;  "eraser."
	;
		call	InitEraseBitmap
	;
	;  Create the bitmap used for drawing the spotlight.
	;
		call	InitSpotBitmap
		mov	ds:[di].SAI_spotVMBlock, ax
		mov	ds:[di].SAI_spotGState, dx
	;
	;  Clear the screen.
	;
		call	SpotlightClearScreen
	;
	;  Get a random starting position and direction.
	;
		call	InitSpotlightPosition
	;
	; We always draw in XOR mode for easy erasure.  NOT.
	;
		mov	di, ds:[di].SAI_curGState
		mov	ax, MM_COPY
		call	GrSetMixMode
	;
	; Start up the timer to draw a new line.
	;
		call	SpotlightSetTimer

		.leave
		ret
SpotlightAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitScreenBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the bitmap containing the contents of the screen.

CALLED BY:	SpotlightAppSetWin

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance

RETURN:		^vcx:dx = bitmap for drawing spotlight
		ax	= gstate to that bitmap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitScreenBitmap	proc	near
		class	SpotlightApplicationClass
		uses	bx,si,di

		bitmapFile	local	word
		bitmapBlock	local	word
		bitmapGState	local	hptr.GState
		screenGState	local	hptr.GState
		screenWidth	local	word
		screenHeight	local	word
		counter		local	word

		.enter
	;
	;  Get the root window and create a gstate to it.
	;
		call	ImGetPtrWin			; di = root window
		call	GrCreateState			; di = gstate
		mov	screenGState, di
		call	GrGrabExclusive			; make sure no change
	;
	;  Create a huge bitmap the size of the screen.
	;
		call	GrGetWinBounds
		sub	cx, ax				; cx = width
		sub	dx, bx				; dx = height
		mov	screenWidth, cx
		mov	screenHeight, dx

		call	GetBitmapFormat			; al = BMFormat
		call	ClipboardGetClipboardFile	; bx = vm file
		clr	di, si				; exposure OD
		call	GrCreateBitmap			; di = gstate
		mov	bitmapGState, di
		mov	bitmapFile, bx
		mov	bitmapBlock, ax
	;
	;  Call GrGetBitmap for each scan line and draw it to the
	;  corresponding huge array element.  cx is still the width.
	;
		mov	di, screenGState
		clr	ax, bx				; x & y pos
		mov	counter, bx			; starting scan line
		mov	dx, 1				; height to grab
elementLoop:
		call	GrGetBitmap			; bx = mem handle
		call	InitScanLine
		call	MemFree				; destroy bitmap

		inc	counter				; next scan line
		mov	bx, counter
		cmp	bx, screenHeight
		jb	elementLoop
done::
	;
	;  Release the screen gstate now that we're done with it.
	;
		mov	di, screenGState
		clr	bx				; default driver
		call	GrReleaseExclusive
		call	GrDestroyState
	;
	;  On the way out, set the bitmap mode to edit-mask, since
	;  that's all we'll be doing with it.
	;
		mov	di, bitmapGState
		mov	ax, mask BM_EDIT_MASK
		clr	dx
		call	GrSetBitmapMode

		mov	ax, di				; return gstate in ax
		mov	cx, bitmapFile
		mov	dx, bitmapBlock

		.leave
		ret
InitScreenBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the grabbed bitmap to the corresponding huge array
		element.

CALLED BY:	InitScreenBitmap

PASS:		ss:bp	= stack frame from InitScreenBitmap
		bx	= block containing grabbed bitmap slice

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitScanLine	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter inherit InitScreenBitmap
	;
	;  Lock the huge-array element for the current scan line.
	;
		push	bx			; bitmap block

		mov	bx, bitmapFile
		mov	di, bitmapBlock		; bx.di = hugebitmap
		clr	dx
		mov	ax, counter		; current scan line
		call	HugeArrayLock		; ds:si = element
	;
	;  Skip over the mask and copy the data.
	;
		pop	bx
		call	MemLock
		mov	es, ax
		mov	di, size Bitmap		; es:di = grabbed bitmap data
		segxchg	ds, es
		xchg	si, di			; swap source & dest
		call	CalcBitmapDataSize	; cx = number of bytes to copy
		rep	movsb
	;
	;  Unlock everything and bail.
	;
		segmov	ds, es, ax		; ds -> huge array element
		call	HugeArrayUnlock
		call	MemUnlock

		.leave
		ret
InitScanLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBitmapDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out how many bytes to copy.

CALLED BY:	InitScanLine

PASS:		ds	= Bitmap structure

RETURN:		cx	= #bytes to copy

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Most of this routine was grabbed from DumpCalcBMSize.
	We don't have to multiply by the height because it's
	always 1.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcBitmapDataSize	proc	near
		uses	ax,dx,di
		.enter

		mov	di, {word}ds:B_type
		mov	ax, ds:B_width
		mov	dx, ds:B_height
	;
        ; case BMT_FORMAT:
	;    BMF_MONO:   #bytes = ((width+7)>>3) * height
	;    BMF_4BIT:   #bytes = ((width+1)>>1) * height
	;    BMF_8BIT:   #bytes = width * height
	;    BMF_24BIT:  #bytes = width * height * 3
	;  
		and	di, mask BMT_FORMAT
		shl	di
		jmp	cs:{word}CBMSTable[di]
CBMSTable	label	word
		dw	mono
		dw	bit4
		dw	bit8
		dw	bit24
mono: 				; bytesPerScan = (width+7)/8
		add	ax, 7
		shr	ax
		shr	ax
		jmp	15$
bit4: 				; bytesPerScan = (width+1)/2
		inc	ax
15$:
		shr	ax
		jmp	gotIt
bit24: 				; bytesPerScan = width*3
		mov	di, ax
		shl	ax
		add	ax, di
		.assert	$-gotIt eq 0
bit8:
				; bytesPerScan = width
gotIt:
		mov_tr	cx, ax

		.leave
		ret
CalcBitmapDataSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a BMFormat appropriate for the display.

CALLED BY:	InitScreenBitmap

PASS:		*ds:si	= SpotlightApplication object

RETURN:		al	= BMFormat

DESTROYED:	ah

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapFormat	proc	near
		uses	cx,dx,bp
		.enter
	;
	;  Get the app display scheme
	;
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjCallInstanceNoLock		; ah = DisplayType

		andnf	ah, mask DT_DISP_CLASS		; ah = DisplayClass
	;
	;  Figure out the appropriate BMFormat.  Do the common cases
	;  first for speed.
	;
		cmp	ah, DC_COLOR_4
		jne	notColor4
		mov	al, BMF_4BIT
		jmp	done
notColor4:
		cmp	ah, DC_GRAY_1
		jne	notGray1
		mov	al, BMF_MONO			; 1-bit-per-pixel
		jmp	done
notGray1:
		cmp	ah, DC_COLOR_8
		jne	notColor8
		mov	al, BMF_8BIT
		jmp	done
notColor8:
		cmp	ah, DC_CF_RGB
		jne	notRGB
		mov	al, BMF_24BIT
		jmp	done
notRGB:
	;
	;  None of the following DisplayClass values have drivers
	;  for them, yet, but do have BMFormats with the correct
	;  number of bits-per-pixel.
	;
		cmp	ah, DC_GRAY_4
		jne	notGray4
		mov	al, BMF_4BIT
		jmp	done
notGray4:
		cmp	ah, DC_GRAY_8
		jne	notGray8
		mov	al, BMF_8BIT
		jmp	done
notGray8:
	;
	;  The rest of the values are too weird to have a corresponding
	;  BMFormat; we'll just stick BMF_4BIT in there and pray.
	;
		mov	al, BMF_4BIT
done:
		.leave
		ret
GetBitmapFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightClearScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen before starting the spotlight.

CALLED BY:	SpotlightAppSetWin

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We have stored the contents of the screen in a huge bitmap,
	so we can clear the passed gstate with impunity.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightClearScreen	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,di
		.enter

		mov	di, ds:[di].SAI_curGState

		mov	ax, (CF_INDEX shl 8) or C_BLACK
		call	GrSetAreaColor

		call	GrGetWinBounds
		call	GrFillRect

		.leave
		ret
SpotlightClearScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitEraseBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates & initializes the eraser bitmap.

CALLED BY:	SpotlightAppSetWin

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance

RETURN:		nothing
		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This bitmap will be FUDGE_FACTOR pixels wider & taller than
	the square that defines the spotlight.  I'm screwing around
	with the fudge factor so much that I've made it a constant.
	The circle in the middle, however, will be the same size
	as the spotlight.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitEraseBitmap	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Create the bitmap.
	;
		mov	bp, di
		mov	al, BMF_4BIT or mask BMT_MASK
		mov	bx, ds:[bp].SAI_bitmapVMFile
		mov	cx, ds:[bp].SAI_size
		add	cx, 2*FUDGE_FACTOR	; F_F wider on each side
		mov	dx, cx
		clr	di, si			; exposure OD
		call	GrCreateBitmap		; ax = block handle
		mov	ds:[bp].SAI_eraseVMBlock, ax
	;
	;  Set bitmap mode for editing the mask.
	;
		push	dx			; height
		mov	ax, mask BM_EDIT_MASK
		clr	dx
		call	GrSetBitmapMode
		pop	dx			; height
	;
	;  Set all the mask bits (cx & dx are still width & height).
	;
		mov	al, MM_SET
		call	GrSetMixMode
		clr	ax, bx
		call	GrFillRect
	;
	;  Clear a circle out of the center.
	;
		mov	al, MM_CLEAR		; clear thum babies
		call	GrSetMixMode
		mov	ax, FUDGE_FACTOR
		mov	bx, ax
		sub	cx, FUDGE_FACTOR
		sub	dx, FUDGE_FACTOR
		call	GrFillEllipse		; set mask circle to 0's
	;
	;  Clear all the data bits (they got set on creation somehow).
	;
		clr	ax, dx			; edit data
		call	GrSetBitmapMode

		mov	cx, ds:[bp].SAI_size
		add	cx, 2*FUDGE_FACTOR
		mov	dx, cx
		clr	ax, bx
		call	GrFillRect
	;
	;  Nuke the gstate & window structures, now that we're done
	;  editing the beastie.
	;
		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap

		.leave
		ret
InitEraseBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSpotBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the spotlight bitmap.

CALLED BY:	SpotlightAppSetWin

PASS:		*ds:si	= SpolightApplication object
		ds:di	= SpotlightApplicationInstance

RETURN:		dx	= bitmap block handle
		ax	= bitmap gstate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/29/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitSpotBitmap	proc	near
		class	SpotlightApplicationClass
		uses	bx,cx,si,di,bp
		.enter
	;
	;  Get the BMType for the spotlight bitmap.
	;
		push	ds
		mov	bp, di
		mov	bx, ds:[bp].SAI_bitmapVMFile
		mov	di, ds:[bp].SAI_screenVMBlock
		call	HugeArrayLockDir
		mov	ds, ax
		mov	al, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		call	HugeArrayUnlockDir
	;
	;  Create the bitmap.
	;
		pop	ds
		mov	cx, ds:[bp].SAI_size
		add	cx, 2*FUDGE_FACTOR	; F_F wider on each side
		mov	dx, cx
		clr	di, si			; exposure OD
		call	GrCreateBitmap		; ax = block handle

		mov	dx, di			; return dx = gstate

		.leave
		ret
InitSpotBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSpotlightPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the starting position and direction.

CALLED BY:	SpotlightAppSetWin

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance

RETURN:		nothing (SAI_left, SAI_top & SAI_dir initialized)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitSpotlightPosition	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,dx
		.enter
	;
	;  Get random values for left & top, and store them.
	;
		mov	bx, ds:[di].SAI_random
		mov	dx, ds:[di].SAI_bounds.R_right
		sub	dx, ds:[di].SAI_size
		call	SaverRandom		; dx <- left side
		mov	ds:[di].SAI_left, dx

		mov	dx, ds:[di].SAI_bounds.R_bottom
		sub	dx, ds:[di].SAI_size
		call	SaverRandom		; dx <- top side
		mov	ds:[di].SAI_top, dx
	;
	;  Get a random direction and store it.
	;
		mov	dx, 4
		call	SaverRandom
		shl	dx			; word-sized etype
		mov	ds:[di].SAI_dir, dx
		
		.leave
		ret
InitSpotlightPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance
		ax	= the message

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	cx

PSEUDO CODE/STRATEGY:

	- stop the draw timer
	- kill the random number generator
	- destroy the bitmaps

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightAppUnsetWin	method dynamic SpotlightApplicationClass,
						MSG_SAVER_APP_UNSET_WIN
		uses	ax, bp
		.enter
	;
	;  Stop the draw timer.
	; 
		clr	bx
		xchg	bx, ds:[di].SAI_timerHandle
		mov	ax, ds:[di].SAI_timerID
		call	TimerStop
	;
	;  Nuke the random number generator.
	; 
		clr	bx
		xchg	bx, ds:[di].SAI_random
		call	SaverEndRandom
	;
	;  Nuke the screen bitmap.
	;
		push	di
		mov	di, ds:[di].SAI_screenGState
		mov	al, BMD_KILL_DATA
		call	GrDestroyBitmap
		pop	di
	;
	;  Nuke the spotlight bitmap.
	;
		mov	bx, ds:[di].SAI_bitmapVMFile
		mov	ax, ds:[di].SAI_spotVMBlock
		clr	bp
		call	VMFreeVMChain
	;
	;  Nuke the eraser bitmap.
	;
		mov	bx, ds:[di].SAI_bitmapVMFile
		mov	ax, ds:[di].SAI_eraseVMBlock
		clr	bp				; no db items
		call	VMFreeVMChain
	;
	;  Call our superclass to take care of the rest.
	;
		.leave
		mov	di, offset SpotlightApplicationClass
		GOTO	ObjCallSuperNoLock
SpotlightAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	SpotlightAppSetWin, SpotlightAppDraw
PASS:		*ds:si	= SpotlightApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightSetTimer	proc	near
		class	SpotlightApplicationClass
		uses	di
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].SpotlightApplication_offset
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, 1
		mov	dx, MSG_SPOTLIGHT_APP_DRAW
		mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination
		
		call	TimerStart
		mov	ds:[di].SAI_timerHandle, bx
		mov	ds:[di].SAI_timerID, ax

		.leave
		ret
SpotlightSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpotlightAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Spotlight line.

CALLED BY:	MSG_SPOTLIGHT_APP_DRAW

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplicationInstance

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
	stevey	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpotlightAppDraw	method	dynamic SpotlightApplicationClass, 
						MSG_SPOTLIGHT_APP_DRAW
		.enter
		
		mov	bp, di			; save instance
		segmov	es, ds, ax		; es:[bp] = instance data
	;
	;  See if we have a valid gstate.
	;
		mov	di, ds:[di].SAI_curGState
		tst	di
		LONG	jz	done
	;		
	;  Calculate the new position of the spotlight, and update
	;  the data offscreen.
	;
		call	CalcNewPosition
		call	UpdateSpotlight
	;
	;  Draw the bitmap.
	;
		mov	ax, ds:[bp].SAI_left
		mov	bx, ds:[bp].SAI_top
		mov	dx, ds:[bp].SAI_bitmapVMFile
		mov	cx, ds:[bp].SAI_spotVMBlock
		call	GrDrawHugeBitmap
	;
	; Set another timer for next time.
	;
		call	SpotlightSetTimer
done:
		.leave
		ret
SpotlightAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSpotlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sticks the new data in the spotlight.

CALLED BY:	SpotlightAppDraw

PASS:		*ds:si	= SpotlightApplication object
		ds:bp	= SpotlightApplicationInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- the first step of this routine could maybe be replaced
	  by GrGetBitmap, but (I think) this is faster, and GrGetBitmap
	  at the time of this writing is hosed beyond belief.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/29/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSpotlight	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,di
		.enter
	;
	;  Draw the screen bitmap to the spotlight bitmap.
	;
		mov	di, ds:[bp].SAI_spotGState
		mov	ax, ds:[bp].SAI_left
		mov	bx, ds:[bp].SAI_top
		neg	ax
		neg	bx
		mov	dx, ds:[bp].SAI_bitmapVMFile
		mov	cx, ds:[bp].SAI_screenVMBlock
		call	GrDrawHugeBitmap
	;
	;  Now the spotlight bitmap contains a square piece of
	;  the screen.  Use the eraser bitmap to make everything
	;  outside the spotlight black.
	;
		clr	ax, bx
		mov	cx, ds:[bp].SAI_eraseVMBlock
		call	GrDrawHugeBitmap

		.leave
		ret
UpdateSpotlight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNewPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the spotlight.

CALLED BY:	SpotlightAppDraw

PASS:		*ds:si	= SpotlightApplication object
		ds:bp	= SpotlightApplicationInstance

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNewPosition	proc	near
		class	SpotlightApplicationClass
		uses	di,bx
		.enter
	;
	;  Call the appropriate movement routine.
	;
		mov	di, bp
		mov	bx, ds:[di].SAI_dir
		call	cs:[dirTable][bx]
		
		.leave
		ret

dirTable	nptr	offset NWHandler,
			offset NEHandler,
			offset SEHandler,
			offset SWHandler

CalcNewPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NEHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the right wall, top wall, or both.

CALLED BY:	CalcNewPosition

PASS: 		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplication instance

RETURN:		nothing (SAI_dir initialized)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEHandler	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the upper-left corner.
	;
		mov	ax, ds:[di].SAI_left
		add	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_left, ax

		mov	ax, ds:[di].SAI_top
		sub	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_top, ax
	;
	;  Put spotlight right & top sides in cx & dx.
	;
		mov	cx, ds:[di].SAI_left
		mov	dx, ds:[di].SAI_top
		add	cx, ds:[di].SAI_size		; check other side
		add	cx, 2*FUDGE_FACTOR		; cx = right
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_right	; right wall
		mov	bx, ds:[di].SAI_bounds.R_top	; top wall
		cmp	cx, ax				; check right
		jl	doneRight

		ornf	si, mask WH_RIGHT
doneRight:		
		cmp	dx, bx				; check top
		jg	doneTop

		ornf	si, mask WH_TOP
doneTop:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_RIGHT or mask WH_TOP)
		je	hitBoth
		cmp	si, mask WH_RIGHT
		je	hitRight
		cmp	si, mask WH_TOP
		je	hitTop
		jmp	short	gotNewDir		; didn't hit a wall
hitRight:
		mov	ds:[di].SAI_dir, SD_NW
		jmp	short	gotNewDir
hitTop:
		mov	ds:[di].SAI_dir, SD_SE
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].SAI_dir, SD_SW
gotNewDir:
		.leave
		ret
NEHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the left wall, top wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplication instance

RETURN:		SAI_dir initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWHandler	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the upper-left corner
	;
		mov	ax, ds:[di].SAI_left
		sub	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_left, ax

		mov	ax, ds:[di].SAI_top
		sub	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_top, ax
	;
	;  Put spotlight right & top sides in cx & dx.
	;
		mov	cx, ds:[di].SAI_left
		mov	dx, ds:[di].SAI_top
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_left	; left wall
		mov	bx, ds:[di].SAI_bounds.R_top	; top wall
		cmp	cx, ax				; check left
		jg	doneLeft

		ornf	si, mask WH_LEFT		; hit left
doneLeft:		
		cmp	dx, bx				; check top
		jg	doneTop

		ornf	si, mask WH_TOP			; hit top
doneTop:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_LEFT or mask WH_TOP)
		je	hitBoth
		cmp	si, mask WH_LEFT
		je	hitLeft
		cmp	si, mask WH_TOP
		je	hitTop
		jmp	short	gotNewDir		; didn't hit a wall
hitLeft:
		mov	ds:[di].SAI_dir, SD_NE
		jmp	short	gotNewDir
hitTop:
		mov	ds:[di].SAI_dir, SD_SW
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].SAI_dir, SD_SE
gotNewDir:
		.leave
		ret
NWHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SEHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the right wall, bottom wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplication instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SEHandler	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the left & top position.
	;
		mov	ax, ds:[di].SAI_left
		add	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_left, ax

		mov	ax, ds:[di].SAI_top
		add	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_top, ax
	;
	;  Put spotlight right & top sides in cx & dx.
	;
		mov	cx, ds:[di].SAI_left
		mov	dx, ds:[di].SAI_top
		add	cx, ds:[di].SAI_size
		add	dx, ds:[di].SAI_size
		add	cx, 2*FUDGE_FACTOR		; cx = right
		add	dx, 2*FUDGE_FACTOR		; dx = bottom
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_right
		mov	bx, ds:[di].SAI_bounds.R_bottom
		cmp	cx, ax				; check right
		jl	doneRight

		ornf	si, mask WH_RIGHT		; hit right
doneRight:		
		cmp	dx, bx				; check bottom
		jl	doneBottom

		ornf	si, mask WH_BOTTOM		; hit bottom
doneBottom:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_RIGHT or mask WH_BOTTOM)
		je	hitBoth
		cmp	si, mask WH_RIGHT
		je	hitRight
		cmp	si, mask WH_BOTTOM
		je	hitBottom
		jmp	short	gotNewDir		; didn't hit a wall
hitRight:
		mov	ds:[di].SAI_dir, SD_SW
		jmp	short	gotNewDir
hitBottom:
		mov	ds:[di].SAI_dir, SD_NE
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].SAI_dir, SD_NW
gotNewDir:
		.leave
		ret
SEHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SWHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the left wall, bottom wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= SpotlightApplication object
		ds:di	= SpotlightApplication instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SWHandler	proc	near
		class	SpotlightApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the left & top position.
	;
		mov	ax, ds:[di].SAI_left
		sub	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_left, ax

		mov	ax, ds:[di].SAI_top
		add	ax, ds:[di].SAI_speed
		mov	ds:[di].SAI_top, ax
	;
	;  Put spotlight right & top sides in cx & dx.
	;
		mov	cx, ds:[di].SAI_left
		mov	dx, ds:[di].SAI_top
		add	dx, ds:[di].SAI_size
		add	dx, 2*FUDGE_FACTOR		; dx = bottom
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_left
		mov	bx, ds:[di].SAI_bounds.R_bottom
		cmp	cx, ax				; check left
		jg	doneLeft

		ornf	si, mask WH_LEFT		; hit left
doneLeft:		
		cmp	dx, bx				; check bottom
		jl	doneBottom

		ornf	si, mask WH_BOTTOM		; hit bottom
doneBottom:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_LEFT or mask WH_BOTTOM)
		je	hitBoth
		cmp	si, mask WH_LEFT
		je	hitLeft
		cmp	si, mask WH_BOTTOM
		je	hitBottom
		jmp	short	gotNewDir		; didn't hit a wall
hitLeft:
		mov	ds:[di].SAI_dir, SD_SE
		jmp	short	gotNewDir
hitBottom:
		mov	ds:[di].SAI_dir, SD_NW
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].SAI_dir, SD_NE
gotNewDir:
		.leave
		ret
SWHandler	endp


SpotlightCode	ends
