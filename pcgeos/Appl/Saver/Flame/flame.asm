COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Lights Out
MODULE:		Flame
FILE:		flame.asm

AUTHOR:		Jim Guggemos, Aug 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94   	Initial revision


DESCRIPTION:
	Recursive fractal cosmic flames screen saver
		
   Based on flame module in xlock.
   Original code written by Scott Draves
   XLock's copyright:
 
   Copyright (c) 1988-91 by Patrick J. Naughton.
  
   Permission to use, copy, modify, and distribute this software and its
   documentation for any purpose and without fee is hereby granted,
   provided that the above copyright notice appear in all copies and that
   both that copyright notice and this permission notice appear in
   supporting documentation.
  
   This file is provided AS IS with no warranties of any kind.  The author
   shall have no liability with respect to the infringement of copyrights,
   trade secrets or any patents by this file or any part thereof.  In no
   event will the author be liable for any lost revenue or profits or
   other special, indirect and consequential damages.
  

	$Id: flame.asm,v 1.1 97/04/04 16:49:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

; ThreadBorrow/ReturnStackSpace
include	Internal/threadIn.def

UseLib	ui.def
UseLib	saver.def

include	flame.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

FlameApplicationClass	class	SaverApplicationClass

MSG_FLAME_APP_DRAW	message
;
;	Draw next batch of fractals
;
; Context:	
; Source:	Sent by timer
; Destination:  Application
; Interception: Not
;
; Pass:		Nothing
;			
; Return:	Nothing
;
;	- unchanged
;	- destroyed
;

; ============================== Instance Data ================================

; - Options ---------------

    FAI_maxLevels	word		FLAME_DEFAULT_MAX_LEVELS
    FAI_speed		word		FLAME_DEFAULT_SPEED
    FAI_maxOnScreen	word		FLAME_DEFAULT_MAX_ON_SCREEN
    FAI_sineAttrs	FlameSineAttrs	FLAME_DEFAULT_SINE_ATTRS
    FAI_maxPoints	word		FLAME_DEFAULT_MAX_POINTS
    
; - Internal variables ----
    FAI_windowWidth	word		0	; Window width & height
    FAI_windowHeight	word		0
    
    FAI_halfWidth	word		0	; Half window width & height
    FAI_halfHeight	word		0
    
    FAI_functionCounter	word		0	; Number of functions to use
    
    FAI_recursesDrawn	word		0	; # of recurses drawn on this
    						; screen (w/o erasure)
    
    ; This indicates the number of functions that are used for the current
    ; fractal drawing.
    FAI_numCurrentFuncs	word		0
    
    ; This indicates how many functions will be calculated using the sine
    ; calculation.  If sineAttrs == FSA_SOMETIMES, then this number is
    ; chosen at random, otherwise, it is specifically set.
    FAI_sineThreshold	word		0
    
    FAI_totalPoints	word		0	; Total points, this fractal
    
    ; If this is true, it forces the fractal to be drawn without using sine
    ; calculations.  It is alternated before each recursion so that there is
    ; some variety.  This is only used if the sineAttrs == FSA_SOMETIMES.
    FAI_prohibitSine	byte		0
    
    FAI_borrowStackSize	word		0	; size of stack to borrow
    
    ; The chunk that contains the function coefficients.  This is defined as
    ; a 3-dimensional array of WWFixed numbers with the following
    ; dimensions: [FLAME_NUM_FUNCTIONS][2][3].  It is laid out in memory
    ; such that the first dimension moves the slowest.  In this way, we
    ; never have to calculate an index, but rather we can just increment a
    ; pointer into the array.
    FAI_coeffChunk	lptr		0	; Chunk containing function
						; coefficients 
    
; - Timer stuff -----------
    
    FAI_timerHandle	hptr		0
    	noreloc	FAI_timerHandle
	
    FAI_timerID		word

    FAI_random		hptr		0	; Random number
	noreloc FAI_random			; generator we use

FlameApplicationClass	endc

FlameProcessClass	class	GenProcessClass
FlameProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	flame.rdef
ForceRef FlameApp

udata	segment

udata	ends

idata	segment

FlameProcessClass	mask CLASSF_NEVER_SAVED
FlameApplicationClass

idata	ends

FlameCode	segment resource

.warn -private
flameOptionTable	SAOptionTable	<
	flameCategory, length flameOptions
>

flameOptions		SAOptionDesc	<
	flameMaxLevelsKey,	size FAI_maxLevels,	offset FAI_maxLevels
>,<
	flameSpeedKey,		size FAI_speed,		offset FAI_speed
>,<
	flameMaxOnScreenKey,	size FAI_maxOnScreen,	offset FAI_maxOnScreen
>,<
	flameSineAttrsKey,	size FAI_sineAttrs,	offset FAI_sineAttrs
>,<
	flameMaxPointsKey,	size FAI_maxPoints,	offset FAI_maxPoints
>

.warn @private

flameCategory		char 'flame', 0
flameMaxLevelsKey	char 'maxLevels', 0
flameSpeedKey		char 'speed', 0
flameMaxOnScreenKey	char 'maxOnScreen', 0
flameSineAttrsKey	char 'sineAttrs', 0
flameMaxPointsKey	char 'maxPoints', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= FlameApplicationClass object
		ds:di	= FlameApplicationClass instance data
		ds:bx	= FlameApplicationClass object (same as *ds:si)
		es 	= segment of FlameApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameLoadOptions	method dynamic FlameApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter
		
	segmov	es, cs
	mov	bx, offset flameOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset FlameApplicationClass
	GOTO	ObjCallSuperNoLock
	
FlameLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameSaverAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN
PASS:		*ds:si	= FlameApplicationClass object
		ds:di	= FlameApplicationClass instance data
		ds:bx	= FlameApplicationClass object (same as *ds:si)
		es 	= segment of FlameApplicationClass
		ax	= message #
RETURN:		Nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameSaverAppSetWin	method dynamic FlameApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	; 
	
	mov	di, offset FlameApplicationClass
	call	ObjCallSuperNoLock
	
	;
	; Now initialize our state.
	; 
	
	; Allocate coeffecient chunk.  This is essentially a well ordered 3
	; dimensional array.  It is defined as an array of WWFixed with the
	; dimensions: [FLAME_NUM_FUNCTIONS][2][3]
	mov	ax, FLAME_NUM_FUNCTIONS
	mov	cx, (size WWFixed) * FLAME_COEFFICIENTS_PER_FUNCTION
	mul	cx
	mov_tr	cx, ax
	mov	al, mask OCF_IGNORE_DIRTY		; who cares?
	call	LMemAlloc
EC <	ERROR_C	FLAME_SAVER_APP_LMEM_ALLOC_ERROR			>
	
	mov	di, ds:[si]
	add	di, ds:[di].FlameApplication_offset
	mov	ds:[di].FAI_coeffChunk, ax
	
	;
	; Create a random number generator.
	; 
	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].FAI_random, bx
	
	;
	; Now initialize stuff.
	; 
		
	mov	bp, di
	mov	di, ds:[di].SAI_curGState	
	call	GrGetWinBounds				; (ax, bx) - (cx, dx)
EC <	ERROR_C	FLAME_SAVER_APP_WINDOW_BOUNDS_CANNOT_FIT_INTO_16_BITS	>
	
EC <	tst	ax							>
EC <	ERROR_NZ FLAME_SAVER_APP_EXPECTED_LEFT_OF_WINDOW_TO_BE_ZERO	>
EC <	tst	bx							>
EC <	ERROR_NZ FLAME_SAVER_APP_EXPECTED_TOP_OF_WINDOW_TO_BE_ZERO	>
	
	; ASSUME: ax, bx == 0.. thus cx, dx = width, height
	mov	ds:[bp].FAI_windowWidth, cx
	mov	ds:[bp].FAI_windowHeight, dx
	
	shr	cx, 1
	shr	dx, 1
	
	mov	ds:[bp].FAI_halfWidth, cx
	mov	ds:[bp].FAI_halfHeight, dx
	
	; Calculate the amount of stack space to borrow in the drawing
	; routine.  
	mov	ax, ds:[bp].FAI_maxLevels
	mov	bx, FLAME_STACK_BYTES_PER_RECURSION
	mul	bx
	add	ax, FLAME_STACK_FIXED_BYTES		; + fixed amount
	mov	ds:[bp].FAI_borrowStackSize, ax
	
	; Reset the recursion counter
	clr	ds:[bp].FAI_recursesDrawn
	
	mov_tr	di, bp
	
	;
	; Start up the timer to draw a new line.
	;
	call	FlameSetTimer
	
	.leave
	ret
FlameSaverAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameSaverAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN
PASS:		*ds:si	= FlameApplicationClass object
		ds:di	= FlameApplicationClass instance data
		ds:bx	= FlameApplicationClass object (same as *ds:si)
		es 	= segment of FlameApplicationClass
		ax	= message #

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameSaverAppUnsetWin	method dynamic FlameApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	
	clr	bx
	xchg	bx, ds:[di].FAI_timerHandle
	mov	ax, ds:[di].FAI_timerID
	call	TimerStop
	
	;
	; Nuke the random number generator.
	; 
	
	clr	bx
	xchg	bx, ds:[di].FAI_random
	call	SaverEndRandom
	
	;
	; Free up the stuff
	; 
	
	clr	ax
	xchg	ds:[di].FAI_coeffChunk, ax
	call	LMemFree
	
	;
	; Call our superclass to take care of the rest.
	; 
	    
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset FlameApplicationClass
	GOTO	ObjCallSuperNoLock

FlameSaverAppUnsetWin	endm


;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	
PASS:		*ds:si	= FlameApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameSetTimer	proc	near
	class	FlameApplicationClass
	uses	di
	.enter
	
	mov	di, ds:[si]
	add	di, ds:[di].FlameApplication_offset
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].FAI_speed
	mov	dx, MSG_FLAME_APP_DRAW
	mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

	call	TimerStart
	mov	ds:[di].FAI_timerHandle, bx
	mov	ds:[di].FAI_timerID, ax
	
	.leave
	ret
FlameSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by the timer

CALLED BY:	MSG_FLAME_APP_DRAW
PASS:		*ds:si	= FlameApplicationClass object
		ds:di	= FlameApplicationClass instance data
		ds:bx	= FlameApplicationClass object (same as *ds:si)
		es 	= segment of FlameApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, GState color
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameAppDraw	method dynamic FlameApplicationClass, 
					MSG_FLAME_APP_DRAW
	.enter
	mov	bp, di

	mov	di, ds:[di].SAI_curGState
	tst	di
   LONG	jz	done

	; Check to see if we should clear the screen
	mov	ax, ds:[bp].FAI_recursesDrawn
	cmp	ax, ds:[bp].FAI_maxOnScreen
   LONG	jae	clearWindow
	
clearWindowContinue:
	; Increment the count
	inc	ds:[bp].FAI_recursesDrawn
	
	; Select a color (won't include WHITE or BLACK)
    CheckHack <C_BLACK eq 0>
    CheckHack <C_WHITE eq 15>
	mov	dx, C_WHITE-1
	mov	bx, ds:[bp].FAI_random
	call	SaverRandom				; Destroys: ax
	inc	dx					; dx (dl) = color index

EC <	cmp	dx, C_BLACK						>
EC <	ERROR_E	FLAME_SAVER_APP_BLACK_WAS_SELECTED_AS_DRAWING_COLOR	>

    CheckHack <CF_INDEX eq 0>
	clr	ax
	mov	al, dl
	call	GrSetAreaColor
	
	; Calculate the number of functions; this number will be between
	; 2 and FLAME_NUM_FUNCTIONS.  It is not random, but rather, the
	; number is incremented each for each fractal until it wraps back to 2.
	mov	ax, ds:[bp].FAI_functionCounter
	inc	ax
	cmp	ax, FLAME_NUM_FUNCTIONS-1
	jb	gotFuncNum
	clr	ax
gotFuncNum:
    	mov	ds:[bp].FAI_functionCounter, ax
	inc	ax
	inc	ax
	mov	ds:[bp].FAI_numCurrentFuncs, ax
	
	; Calculate the sine threshold: how many functions will be
	; calculated using sine.
	clr	ds:[bp].FAI_sineThreshold
	tst	ds:[bp].FAI_sineAttrs
    CheckHack <FSA_SOMETIMES eq 0>
	jz	sineSometimes

	; If we are never supposed to do sine calculations, then leave
	; sineThreshold at zero and none will ever be done.
	cmp	ds:[bp].FAI_sineAttrs, FSA_NEVER
	je	sineThresholdSet
	
	; Otherwise, always do sine calculations.  Thus, make sineThreshold
	; really big (it is unsigned) so it will always do it.
	dec	ds:[bp].FAI_sineThreshold
	jmp	short sineThresholdSet

sineSometimes:
	tst	ds:[bp].FAI_prohibitSine
	jnz	sineThresholdSet
	mov	dx, ax					; numCurrentFuncs
	
	; EC: ensure bx is still pointing to random number generator token
EC <	cmp	bx, ds:[bp].FAI_random					>
EC < 	ERROR_NE FLAME_SAVER_APP_OOPS					>

	call	SaverRandom				; dx = result
	inc	dx
	inc	dx
	mov	ds:[bp].FAI_sineThreshold, dx

sineThresholdSet:
	
	; Calculate coefficients
	call	FlameCalcCoefficients
	
	clr	ds:[bp].FAI_totalPoints
	
	push	si					; save my handle
	
	; Call recursive routine to draw points
	clr	ax, bx, cx, dx
	mov	si, di					; save GState handle
	
	; Ensure we have enough stack
	mov	di, ds:[bp].FAI_borrowStackSize
	call	ThreadBorrowStackSpace
	push	di					; save stack token
	mov	di, si					; restore GState
	clr	si
	
	call	FlameRecursiveDraw
	
	mov	si, di					; save GState handle
	pop	di					; stack token
	call	ThreadReturnStackSpace
	mov	di, si					; restore GState
	
	pop	si					; restore my handle
	;
	; Set another timer for next time.
	; 
	call	FlameSetTimer
done:
	.leave
	ret

    	; Draws a black rectangle over the whole window to clear it.
	; Also flips the prohibit sine flag.
	; Destroys: ax, bx, cx, dx, GState area color
clearWindow:
    CheckHack <C_BLACK eq 0>
    CheckHack <CF_INDEX eq 0>
	clr	ax
	call	GrSetAreaColor
	mov	bx, ax
	mov	cx, ds:[bp].FAI_windowWidth
	mov	dx, ds:[bp].FAI_windowHeight
	dec	cx
	dec	dx
	call	GrFillRect
	not	ds:[bp].FAI_prohibitSine
	clr	ds:[bp].FAI_recursesDrawn
    	jmp	clearWindowContinue

FlameAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameCalcCoefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the function coefficients and puts them in the
		coefficient chunk.

CALLED BY:	FlameAppDraw

PASS:		ds:bp	= dereferenced pointer to instance data of FlameApp

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameCalcCoefficients	proc	near
	class	FlameApplicationClass
	uses	bp, si, di
	.enter
	
	; Get number of functions to calculate, multiply by 6 because each
	; function has 6 coefficients.
	mov	ax, ds:[bp].FAI_numCurrentFuncs
	mov	cx, FLAME_COEFFICIENTS_PER_FUNCTION
	mul	cx
	mov_tr	cx, ax
	
	; Get token of random number generator
	mov	bx, ds:[bp].FAI_random
	
	; Get pointer to chunk
	mov	bp, ds:[bp].FAI_coeffChunk
	mov	bp, ds:[bp]
	
functionLoop:
	; Generate a number in the range (-1.0, 1.0) [EXCLUSIVE].  Since
	; SaverRandom delivers an integer, we pick a number in the range
	; [1,4095] [INCLUSIVE], divide it by 2048 to get a WWFixed number
	; in the range (0.0, 2.0) and then subtract 1.0 to get the desired
	; number.
	
	; BX should still have the token of the random number generator
	mov	dx, 4095				; Max val + 1
	call	SaverRandom				; dx = random num
	inc	dx					; dx = [1,4095]
	
	; Divide the number by 2048.0 (Multiply by 1/2048)
	;
	; This is a trivial WWFixed multiply since the multiplicand is an
	; integer (from the random number generator) and the multiplier is a
	; fraction only.  It is the case of D.0 * 0.A, the result is simple
	; multiplying D*A to get the WWF answer, no shifting necessary.
	; Everything here is unsigned (until the dec).
	
	mov	ax, 0x20				; = 1/2048 (WFixed)
	mul	dx					; result: dx.ax
	
	dec	dx					; - 1
	movwwf	ds:[bp], dxax
	
	; Ensure the coefficient is valid (in range (-1.0, 1.0))!
EC <	ERROR_RANGE	dxax, FLAME_SAVER_APP_ILLEGAL_COEFFICIENT	>
	
	add	bp, size WWFixed			; advance pointer
	loop	functionLoop
	
	.leave
	ret
FlameCalcCoefficients	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameRecursiveDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws set of points

CALLED BY:	FlameAppDraw

PASS:		ds:bp	= dereferenced pointer to instance data of FlameApp
		di	= GState

		bx.ax	= WWFixed X
		dx.cx	= WWFixed Y
		si	= level of recursion

RETURN:		carry	= Set to abort recursion, clear otherwise.
		(Return value only important within the recursion).

DESTROYED:	ax, bx, cx, dx, si

SIDE EFFECTS:	
	This may take a lot of stack.  Be sure that you borrow stack space
	before you start this routine!

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameRecursiveDraw	proc	near
	class	FlameApplicationClass
	
recursionDepth	local		word			push si
passedX		local		WWFixed
passedY		local		WWFixed
nextCoeff	local		word
	
	.enter
	
	; mov instance pointer (passed as bp) into si
	mov	si, ss:[bp]
	
	movwwf	ss:[passedX], bxax
	movwwf	ss:[passedY], dxcx
	
	mov	ax, ss:[recursionDepth]
	cmp	ax, ds:[si].FAI_maxLevels
	je	atMaximumDepth
	
	mov	cx, ds:[si].FAI_numCurrentFuncs
	
	mov	bx, ds:[si].FAI_coeffChunk
	mov	bx, ds:[bx]				; get coeffecient ptr
	mov	ss:[nextCoeff], bx			; and store in local
	
recursionLoop:
	push	di					; save GState
	
	mov	di, ss:[nextCoeff]			; load coeff ptr
	
	push	cx					; save counter
	
	; Calculate X
	call	FlameCalculateNextXY			; result in dx.cx
	
	pushwwf	dxcx					; save result
	
	; Calculate Y
	call	FlameCalculateNextXY			; result in dx.cx
	
	popwwf	bxax					; X result in bx.ax
	
	mov	ss:[nextCoeff], di			; save ptr into coeff
							; array
							
	pop	di					; di <= COUNTER
	
	; Check to see if we are above the sine threshold.
	cmp	di, ds:[si].FAI_sineThreshold
	jae	noSineCalcs				; Yes, skip the sine.
	
	; No, do the sine calculation
	
	; X = sin( X )
	call	FlameQuickSine
	
	; Y = sin( Y )
	xchgwwf	bxax, dxcx
	call	FlameQuickSine
	xchgwwf	bxax, dxcx
	
noSineCalcs:
	XchgTopStack	di				; top = ctr, di = GState
	push	bp					; locals ptr
	push	si					; instance ptr
	mov	si, ss:[recursionDepth]
	inc	si					; level + 11
	pop	bp					; instance ptr
	
	; NOW: for recursive call:
	;    bx.ax, dx.cx = X, Y
	;    di = GState
	;    si = Recursive level
	;    ds:bp = instance data ptr
	
	; CALL MYSELF!
	call	FlameRecursiveDraw
	
	mov	si, bp					; restore instance ptr
	pop	bp					; restore locals ptr
	pop	cx					; restore counter
	
	jc	exitRecursion				; abort!
	
	loop	recursionLoop
	jmp	exitDontAbort
	
atMaximumDepth:
	; Make sure we don't draw too many points
    	inc	ds:[si].FAI_totalPoints
	mov	ax, ds:[si].FAI_maxPoints
	cmp	ds:[si].FAI_totalPoints, ax
	jbe	drawPoint
	stc						; abort recursion!
	jmp	short exitRecursion
	
drawPoint:
	; ax needs to be fixed up..
	mov	ax, ss:[passedX].WWF_frac
	
	; bx.ax, dx.cx = X, Y
	
	; Ensure X = (-1.0, 1.0)
	checkRange	bxax, pointOutOfBounds
	
	; Ensure Y = (-1.0, 1.0)
	checkRange	dxcx, pointOutOfBounds
	
if 0
	tst	bx
	jns	checkXGreaterThanOne
	; X < 0
	cmp	bx, -1
	jl	pointOutOfBounds			; X < -1.0
	tst	ax
	jz	pointOutOfBounds			; X = -1.0
	; -1.0 < X < 0 -- That's okay

checkXGreaterThanOne:
	cmp	bx, 1
	jge	pointOutOfBounds
	
	; Ensure Y = (-1.0, 1.0)
	tst	dx
	jns	checkYGreaterThanOne
	; Y < 0
	cmp	dx, -1
	jl	pointOutOfBounds			; Y < -1.0
	tst	cx
	jz	pointOutOfBounds			; Y = -1.0
	; -1.0 < Y < 0 -- That's okay

checkYGreaterThanOne:
	cmp	dx, 1
	jge	pointOutOfBounds
endif
	
	inc	bx
	inc	dx
	
	pushwwf	dxcx					; save Y info
	
	; Calculate X coordinate to draw
	mov	cx, ds:[si].FAI_halfWidth
	call	FlameUMulWWFByWordToWord		; cx = result
	
	popwwf	bxax					; restore Y info
	
	push	cx					; store integer X result
	
	; Now calculate Y coordinate to draw
	mov	cx, ds:[si].FAI_halfHeight
	call	FlameUMulWWFByWordToWord		; cx = result
	
	mov	bx, cx					; store int Y result
	pop	ax					; restore int X result
	
	call	GrDrawPoint				; DRAW IT!!

NEC <pointOutOfBounds:						>
exitDontAbort:
	clc						; don't abort
	
exitRecursion:
	.leave
	ret
	
	; Added so that we can break on out of bound points.
EC <pointOutOfBounds:						>
EC <	jmp	exitDontAbort					>
FlameRecursiveDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameCalculateNextXY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does the calculation needed by FlameRecursiveDraw for the
		next X and Y value.

CALLED BY:	FlameRecursiveDraw

PASS:		ds:di	= ptr to coefficient chunk
		ss:bp	= passed stack frame

RETURN:		dx.cx	= new X or Y value
		ds:di	= ptr to next set of coefficients

DESTROYED:	ax, bx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	newX = coeff0 * X + coeff1 * Y + coeff2
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameCalculateNextXY	proc	near
	.enter	inherit FlameRecursiveDraw
	
	; We KNOW that the coefficients are in the range (-1.0, 1.0), so use
	; this funky multiply which is much faster than GrMulWWFixed
	
	movwwf	bxax, ss:[passedX]
	mov	cx, ds:[di].WWF_frac
	tst	ds:[di].WWF_int				; set up SF for mult.
	call	FlameMulWWFByWFToWWF			; result in dx.cx
	
	pushwwf	dxcx
	
	add	di, size WWFixed
	
	movwwf	bxax, ss:[passedY]
	mov	cx, ds:[di].WWF_frac
	tst	ds:[di].WWF_int				; set up SF for mult.
	call	FlameMulWWFByWFToWWF			; result in dx.cx
	
	popwwf	bxax
	
	addwwf	dxcx, bxax
	
	add	di, size WWFixed
	
	addwwf	dxcx, ds:[di], ax
	
	add	di, size WWFixed
	
	.leave
	ret
FlameCalculateNextXY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameQuickSine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a quick sine calculcation, but passed parameter is
		in radians

CALLED BY:	FlameRecursiveDraw

PASS:		bx.ax	= Angle in radians

RETURN:		bx.ax	= Sine of angle

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Heck.. how accurate do we have to be?  Well, I just use 180 / Pi = 57 :)
; instead of 57.295779513.. makes the multiply about 4 times as fast.
;
FLAME_COARSE_RADIANS_TO_DEGREES	equ	57

FlameQuickSine	proc	near
	uses	cx,dx
	.enter

	mov	cx, FLAME_COARSE_RADIANS_TO_DEGREES
	call	FlameMulWWFByUWordToWWF			; result in dx.cx
	
	mov	ax, cx					; angle in dx.ax
	call	GrQuickSine				; sine in dx.ax
	
	mov	bx, dx					; sine in bx.ax
	.leave
	ret
FlameQuickSine	endp

;
; The following routines are quicker versions of GrMulWWFixed that take
; advantage of certain qualities about the multiplicand, multiplier, and the
; product to speed up the operation (do at most HALF of the multiplies that
; GrMulWWFixed would do).
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameUMulWWFByWordToWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies an unsigned WWFixed by an unsigned word integer
		and returns a unsigned word integer.

CALLED BY:	FlameRecursiveDraw

PASS:		bx.ax	= multiplicand
		cx	= multiplier
		
RETURN:		cx	= result

DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
			B.A
		    *     C
		    -------
		  C*B + C*A
	  
	  But, we only care about 16-bit integer results, so we do the
	  following:
	  
	  (1) Calculate C*A, save only the high word (integer part) of the
	  	multiply.
	
	  (2) Calculate C*B, save only the low word of the result (16-bit
		answer only!).
		
	  (3) Add results of (1) and (2).
		
		
	  Timing: if B = 0, this function takes from 161 to 176 cycles.
	              else, this function takes from 272 to 302 cycles.
	  
	       	  There was an added cost of 7 cycles for the case where
		  B != 0, but a savings of 104-119 cycles for the B = 0
		  case.  If this is called 50% of the time with B = 0,
		  the average time is 216.5 (this is the case in flame where
		  it is expected that 0 < B.A < 2.0).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameUMulWWFByWordToWord	proc	near
	
				; Cycles  Bytes
				
	mul	cx		; 118-133 2	dx.ax = C*A
	xchg	dx, cx		; 4       2	dx = C
				;		cx = integer result of C*A
						
			; *SUB*   122-137	First multiply time
						
	tst	bx		; 3	  2     (OR) check if B is zero
	jz	done		; 4N 16Y  2	Jump to save time if so.
	
			; *SUB*   7/19		test and branch time false/true
	
	mov	ax, bx		; 2	  2
	mul	dx		; 118-133 2	dxax.0 = C*B
	
	add	cx, ax		; 3	  2	cx = C*B + int(C*A)
	
			; *SUB*   123-138	Second multiply & add time
	
done:
	ret			; 20	  1
				
			; TOTAL   161-176	Time if B = 0
			; TOTAL   272-302	Time if B != 0
	
FlameUMulWWFByWordToWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameMulWWFByUWordToWWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies a signed WWFixed by an unsigned word int to get a
		signed WWFixed.

CALLED BY:	FlameQuickSine

PASS:		bx.ax	= multiplicand
		cx	= multiplier
		
RETURN:		dx.cx	= result

DESTROYED:	ax, bx, dx

DESTROYED:	nothing

SIDE EFFECTS:	
	

PSEUDO CODE/STRATEGY:
		B.A
	     *  C.0
	     ------
	     LOW(C*B)+HIGH(C*A).LOW(C*A)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameMulWWFByUWordToWWF	proc	near
	
	; Check to see if the first argument is signed or not.  If so, negate
	; the argument and save this information so we can negate the answer.
	; NOTE: the second argument is UNSIGNED, so we do not need to check
	; its sign bit.
	
	tst	bx
	
	clc						; do not negate result
	jns	doMultiply
	
	negwwf	bxax
	stc						; negate result

doMultiply:
	; Save the information about the result's sign
	pushf
	
	; Do the unsigned multiply
	push	di
	
	mul	cx					; dx.ax = C*A
	mov	di, ax
	mov	ax, bx
	mov	bx, dx					; bx.di = C*A
	
	; Check and see if B = 0.  If so, we can save a multiply and add.
	tst	ax
	jz	doneWithUnsignedMult
	
	mul	cx					; dxax.0 = C*B
	
	; Add low word of C*B to WWF result of C*A
	add	bx, ax
	
doneWithUnsignedMult:
	; Store back into cool registers.
	movwwf	dxcx, bxdi
	
	pop	di
	
	; Negate the result if necessary
	popf
	jnc	done
	
	negwwf	dxcx
	
done:
	ret
FlameMulWWFByUWordToWWF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlameMulWWFByWFToWWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies a signed WWFixed by an signed WWFixed in the range
		(-1.0, 1.0) to return a signed WWFixed value

CALLED BY:	FlameCalculateNextXY

PASS:		bx.ax	= WWF multiplicand
		cx	= fractional part of WWF multiplier
		SF	= set if multiplier is negative, clear if positive
		
RETURN:		dx.cx	= result

DESTROYED:	ax, bx, dx

RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		B.A
	      * 0.C
	      -----
	     HIGH(C*B).LOW(C*B)+HIGH(C*A)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlameMulWWFByWFToWWF	proc	near
	
	; DX will indicate if we should negate the result
	mov	dx, 0					; PRESERVE REGS
	
	; Check and possibly negate arg(s)
	jns	checkArg2
	
	not	dx
	neg	cx
	
checkArg2:
	tst	bx
	jns	doMultiply
	
	not	dx
	negwwf	bxax

doMultiply:
	; The Z flag will indicate if we have to negate the result
	tst	dx
	pushf
	
	; Do the multiply on A first (only care about high word result)
	mul	cx					; 0.dxax = A*C
	mov	ax, bx					; ax = B
	mov	bx, dx					; 0.bx = A*C
	clr	dx					; dx.bx = A*C
	
	; Check and see if B = 0.  If so, we can save a multiply and add.
	tst	ax
	jz	doneWithUnsignedMult
	
	mul	cx					; dx.ax = B*C
	clr	cx					; cx.bx = A*C
	addwwf	dxax, cxbx				; dx.ax = result
	mov	bx, ax					; dx.bx = result
	
doneWithUnsignedMult:
	; At this point, dx.bx should be the result.  So we need to
	; move the result into dx.cx, what this function returns.
	mov	cx, bx					; dx.cx = result
	
	; Negate the result if necessary
	popf
	jz	done
	
	negwwf	dxcx
	
done:
	ret
FlameMulWWFByWFToWWF	endp

FlameCode	ends
