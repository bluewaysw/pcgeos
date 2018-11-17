COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Lights out
MODULE:		String
FILE:		string.asm

AUTHOR:		Jim Guggemos, Sep 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/15/94   	Initial revision


DESCRIPTION:
	String art screen saver
		

	$Id: string.asm,v 1.1 97/04/04 16:49:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

; ThreadBorrow/ReturnStackSpace
include	Internal/threadIn.def

UseLib	ui.def
UseLib	saver.def

include	string.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

StringApplicationClass	class	SaverApplicationClass

MSG_STRING_APP_DRAW	message
;
;	Draw next line of the art
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

    SAI_speed		word		STRING_DEFAULT_SPEED
    SAI_numLines	word		STRING_DEFAULT_NUM_LINES
    SAI_numCurves	word		STRING_DEFAULT_NUM_CURVES
    SAI_eraseMethod	StringEraseMethod	STRING_DEFAULT_ERASE_METHOD
    SAI_colorSelection	StringColorSelection	STRING_DEFAULT_COLOR_SELECTION
    SAI_pauseTime	word		STRING_DEFAULT_PAUSE
    
; - Internal variables ----
    SAI_windowRect	Rectangle		; Window coords
    
    SAI_piChunk		lptr		0	; Chunk containing "pi" info
    					; This data actually is in degrees,
					; not radians, so pi isn't really used.
    
    SAI_paramChunk	lptr		0	; Chunk holding parameter info
    
    ; Current line we are drawing
    SAI_currentLine	word		0
    
    SAI_maxColorCount	word		0	; Max consecutive lines to be
    						; same color
						
    SAI_colorCount	word		0	; How many lines for current col
    
    SAI_colorInfo	byte		0	; Used to hold a color depending
    						; upon mode
    
    SAI_tempColorSel	StringColorSelection	; In RANDOM mode, hold what the
    						; current color sel mode is
						
    SAI_currentMode	StringCurrentMode	SCM_DRAWING
    
; - Timer stuff -----------
    
    SAI_timerHandle	hptr		0
    	noreloc	SAI_timerHandle
	
    SAI_timerID		word

    SAI_random		hptr		0	; Random number
	noreloc SAI_random			; generator we use

StringApplicationClass	endc

StringProcessClass	class	GenProcessClass
StringProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	string.rdef
ForceRef StringApp

udata	segment

udata	ends

idata	segment

StringProcessClass	mask CLASSF_NEVER_SAVED
StringApplicationClass

idata	ends

StringCode	segment resource

.warn -private
stringOptionTable	SAOptionTable	<
	stringCategory, length stringOptions
>

stringOptions		SAOptionDesc	<
	stringSpeedKey,		size SAI_speed,		offset SAI_speed
>,<
	stringNumLinesKey,	size SAI_numLines,	offset SAI_numLines
>,<
	stringNumCurvesKey,	size SAI_numCurves,	offset SAI_numCurves
>,<
	stringEraseMethodKey,	size SAI_eraseMethod,	offset SAI_eraseMethod
>,<
	stringColorSelectionKey,size SAI_colorSelection,\
					offset SAI_colorSelection
>,<
	stringPauseTimeKey,	size SAI_pauseTime,	offset SAI_pauseTime
>

.warn @private

stringCategory		char 'string art', 0
stringSpeedKey		char 'speed', 0
stringNumLinesKey	char 'numLines', 0
stringNumCurvesKey	char 'numCurves', 0
stringEraseMethodKey	char 'eraseMethod', 0
stringColorSelectionKey	char 'colorSelection', 0
stringPauseTimeKey	char 'pauseTime', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= StringApplicationClass object
		ds:di	= StringApplicationClass instance data
		ds:bx	= StringApplicationClass object (same as *ds:si)
		es 	= segment of StringApplicationClass
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
StringLoadOptions	method dynamic StringApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter
		
	segmov	es, cs
	mov	bx, offset stringOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset StringApplicationClass
	GOTO	ObjCallSuperNoLock
	
StringLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringSaverAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN
PASS:		*ds:si	= StringApplicationClass object
		ds:di	= StringApplicationClass instance data
		ds:bx	= StringApplicationClass object (same as *ds:si)
		es 	= segment of StringApplicationClass
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
StringSaverAppSetWin	method dynamic StringApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	; 
	
	mov	di, offset StringApplicationClass
	call	ObjCallSuperNoLock
	
	;
	; Now initialize our state.
	; 
	
	; Ensure that the number of curves is even.
	mov	di, ds:[si]
	add	di, ds:[di].StringApplication_offset
	test	ds:[di].SAI_numCurves, 1
	jz	allocatePIs
	inc	ds:[di].SAI_numCurves

allocatePIs:
	; Calculate the base number we use to fill the pi table.
	; The base number we use to fill the table is pi / numLines, but
	; since we are using degrees, we use 180.0 / numLines.
	mov	dx, 180
	clr	ax
	mov	cx, ds:[di].SAI_numLines
	
	; We better have more than 180 lines, otherwise our division will
	; have a non-zero integer part.. bummer..
EC <	cmp	cx, 180							>
EC <	ERROR_LE STRING_SAVER_APP_NUM_LINES_HAS_TO_BE_GREATER_THAN_180	>

	div	cx					; 0.ax = pibase
	mov	bx, ax					; 0.bx = pibase
	
	; Allocate parameter chunk
	mov	cx, 4 * (size StringParameterData)
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc
EC <	ERROR_C	STRING_SAVER_APP_LMEM_ALLOC_ERROR			>
	mov	di, ds:[si]
	add	di, ds:[di].StringApplication_offset
	mov	ds:[di].SAI_paramChunk, ax
	
	; Allocate the area for the "PI" information.. it's size is:
	; numCurves/2 * (size WWFixed)
	mov	ax, ds:[di].SAI_numCurves
	shr	ax, 1
	mov	bp, ax					; save numCurves/2
	mov	cx, size WWFixed
	mul	cx
	mov_tr	cx, ax
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc
EC <	ERROR_C	STRING_SAVER_APP_LMEM_ALLOC_ERROR			>
	mov	di, ds:[si]
	add	di, ds:[di].StringApplication_offset
	mov	ds:[di].SAI_piChunk, ax
	
	; Calculate the data for the piChunk.
	
	mov	cx, bp					; = numCurves/2
	mov	bp, ax					; = piChunk
	mov	bp, ds:[bp]
	
	mov	ax, cx					; size of array
	dec	ax					; - 1
	mov	dx, size WWFixed
	mul	dx					; offset to last item
	
	add	bp, ax					; advance bp to end
	
	; NOTE: This fills in the data from the end to the front.
fillPILoop:
	mov	ax, bx					; 0.ax = pibase
	mov	dx, cx					; multiply by:
	and	dx, 0xfffe				; even(counter) + 2
	inc	dx
	inc	dx
	
	mul	dx					; dx.ax = result
	
	movwwf	ds:[bp], dxax
	sub	bp, size WWFixed
	
	loop	fillPILoop
	
	;
	; Create a random number generator.
	; 
	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].SAI_random, bx
	
	;
	; Now initialize stuff.
	; 
		
	mov	bp, di					; hold onto instance ptr
	call	StringClearAngles			; expects ds:bp
	
	mov	di, ds:[di].SAI_curGState	
	call	GrGetWinBounds				; (ax, bx) - (cx, dx)
EC <	ERROR_C	STRING_SAVER_APP_WINDOW_BOUNDS_CANNOT_FIT_INTO_16_BITS	>

	mov	di, bp					; restore instance ptr
	
	; Store window coords
	mov	ds:[di].SAI_windowRect.R_left, ax
	mov	ds:[di].SAI_windowRect.R_top, bx
	mov	ds:[di].SAI_windowRect.R_right, cx
	mov	ds:[di].SAI_windowRect.R_bottom, dx
	
	; Get pointer to parameter data
	mov	bp, ds:[di].SAI_paramChunk
	mov	bp, ds:[bp]
	
	; Calculate window center and store it in the parameter data
	add	ax, cx
	shr	ax, 1
	mov	ds:[bp][SPDI_X1].SPD_midCoord, ax
	mov	ds:[bp][SPDI_X2].SPD_midCoord, ax
	
	add	bx, dx
	shr	bx, 1
	mov	ds:[bp][SPDI_Y1].SPD_midCoord, bx
	mov	ds:[bp][SPDI_Y2].SPD_midCoord, bx
	
	clr	ds:[di].SAI_currentLine
	
	; Calculate max color count based on number of lines
	mov	ax, ds:[di].SAI_numLines
	clr	dx
	mov	bx, STRING_MIN_COLOR_CHANGES
	div	bx
	mov	ds:[di].SAI_maxColorCount, ax
	
	; Reset mode
	mov	ds:[di].SAI_currentMode, SCM_DRAWING
	
	;
	; Start up the timer to draw a new line.
	;
	call	StringSetTimer
	
	.leave
	ret
StringSaverAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringSaverAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN
PASS:		*ds:si	= StringApplicationClass object
		ds:di	= StringApplicationClass instance data
		ds:bx	= StringApplicationClass object (same as *ds:si)
		es 	= segment of StringApplicationClass
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
StringSaverAppUnsetWin	method dynamic StringApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	
	clr	bx
	xchg	bx, ds:[di].SAI_timerHandle
	mov	ax, ds:[di].SAI_timerID
	call	TimerStop
	
	;
	; Nuke the random number generator.
	; 
	
	clr	bx
	xchg	bx, ds:[di].SAI_random
	call	SaverEndRandom
	
	;
	; Free up the stuff
	; 
	
	clr	ax
	xchg	ds:[di].SAI_piChunk, ax
	call	LMemFree
	
	clr	ax
	xchg	ds:[di].SAI_paramChunk, ax
	call	LMemFree
	
	;
	; Call our superclass to take care of the rest.
	; 
	    
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset StringApplicationClass
	GOTO	ObjCallSuperNoLock

StringSaverAppUnsetWin	endm


;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	
PASS:		*ds:si	= StringApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringSetTimer	proc	near
	class	StringApplicationClass
	uses	di
	.enter
	
	mov	di, ds:[si]
	add	di, ds:[di].StringApplication_offset
	
	; If we are pausing, use the pause time; otherwise use the speed
	mov	cx, ds:[di].SAI_speed
	cmp	ds:[di].SAI_currentMode, SCM_PAUSING
	jne	gotTime
	mov	cx, ds:[di].SAI_pauseTime
gotTime:
	
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_STRING_APP_DRAW
	mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

	call	TimerStart
	mov	ds:[di].SAI_timerHandle, bx
	mov	ds:[di].SAI_timerID, ax
	
	.leave
	ret
StringSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by the timer

CALLED BY:	MSG_STRING_APP_DRAW
PASS:		*ds:si	= StringApplicationClass object
		ds:di	= StringApplicationClass instance data
		ds:bx	= StringApplicationClass object (same as *ds:si)
		es 	= segment of StringApplicationClass
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
StringAppDraw	method dynamic StringApplicationClass, 
					MSG_STRING_APP_DRAW
	.enter
	mov	bp, di

	mov	di, ds:[di].SAI_curGState
	tst	di
   LONG	jz	done

	cmp	ds:[bp].SAI_currentMode, SCM_PAUSING
	jne	notPausing
	
	; We were pausing.. this we just finished drawing.  Now either erase
	; the screen, or decide to undraw the art
	
	; Clear the angles in the param data
	call	StringClearAngles

EC <	tst	ds:[bp].SAI_currentLine					>
EC <	ERROR_NZ STRING_SAVER_APP_OOPS					>
	
	; If we are to undraw the lines, set the mode to erasing, and skip
	; right to the "drawOne" label.  DON'T call StringPrepareForDrawing!!
	; We want to redraw the same art.
	mov	ds:[bp].SAI_currentMode, SCM_ERASING
	cmp	ds:[bp].SAI_eraseMethod, SEM_UNDRAW_LINES
	je	drawOne
	
    	; Clear the window and resume drawing
    CheckHack <C_BLACK eq 0>
    CheckHack <CF_INDEX eq 0>
	clr	ax
	call	GrSetAreaColor
	mov	ax, ds:[bp].SAI_windowRect.R_left
	mov	bx, ds:[bp].SAI_windowRect.R_top
	mov	cx, ds:[bp].SAI_windowRect.R_right
	mov	dx, ds:[bp].SAI_windowRect.R_bottom
	call	GrFillRect
	
	mov	ds:[bp].SAI_currentMode, SCM_DRAWING

notPausing:
	tst	ds:[bp].SAI_currentLine
	jnz	drawOne
	call	StringPrepareForDrawing

drawOne:
	call	StringPickColor
	call	StringDrawOne
	
	; Increment line counter, or reset it
	mov	ax, ds:[bp].SAI_currentLine
	inc	ax
	cmp	ax, ds:[bp].SAI_numLines
	jle	setCurrentLine
	clr	ax
	
	; END OF THIS ART
	
	; Should only be drawing or erasing if here, never pausing
EC <	cmp	ds:[bp].SAI_currentMode, SCM_PAUSING			>
EC <	ERROR_E STRING_SAVER_APP_OOPS					>

	; If we were erasing, then we should start drawing immediately.
	; Otherwise, if we were drawing, so the pause.
	mov	bl, SCM_DRAWING
	cmp	ds:[bp].SAI_currentMode, SCM_ERASING
	je	setMode
	mov	bl, SCM_PAUSING

setMode:
	mov	ds:[bp].SAI_currentMode, bl

setCurrentLine:
	mov	ds:[bp].SAI_currentLine, ax
	
	;
	; Set another timer for next time.
	; 
	call	StringSetTimer
done:
	.leave
	ret

StringAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringPickColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Picks color according to color selection method

CALLED BY:	StringAppDraw
PASS:		ds:bp	= pointer to instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	
	Possibly changes color, some instance data

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringPickColor	proc	near
	class	StringApplicationClass
	
	.enter
	
	; DL should hold the color to set if you jmp to setColor.
	
	; Let CX hold the current line number -- it is used by many of these
	; routines anyway.. only modify cx if you are on the way out (not
	; falling thru to any other cases)
	mov	cx, ds:[bp].SAI_currentLine
	
	; Let BX hold the random token
	mov	bx, ds:[bp].SAI_random
	    
    	; If we are in erasing mode, always draw black
	cmp	ds:[bp].SAI_currentMode, SCM_ERASING
	jne	notErasing
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; ERASING
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	
	; ERASE MODE: If this is not the 1st line, don't bother.
	tst	cx
   LONG	jnz	dontSetColor
	
	; Otherwise, always set black.
    CheckHack <C_BLACK eq 0>
	clr	dx
	jmp	setColor
	
notErasing:
	; Let AL hold the color selection.
	mov	al, ds:[bp].SAI_colorSelection
	
	cmp	al, SCS_RANDOM
	jne	notRandom
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; RANDOM
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	
	tst	cx
	jnz	dontNeedNewOne
	
	mov	dx, SCS_RANDOM				; Max + 1
	call	SaverRandom
	mov	ds:[bp].SAI_tempColorSel, dl

dontNeedNewOne:
	mov	al, ds:[bp].SAI_tempColorSel
	; AX has now been re-loaded with the current color selection chosen
	; by random.  Let it continue through the cases below.
	
notRandom:
	cmp	al, SCS_ONE_COLOR
	jne	notOneColor
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; ONE COLOR
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	
	; ONE COLOR: See if this is the first line to be drawn.. if not,
	; skip this.
	tst	cx
   LONG	jnz	dontSetColor
	
	; Next, pick a nice color (won't include BLACK)
    CheckHack <C_BLACK eq 0>
    CheckHack <C_WHITE eq 15>
    	mov	dx, C_WHITE				; Max + 1
	call	SaverRandom				; Destroys ax
	inc	dx					; dx (dl) = color index
	jmp	setColor
	
notOneColor:
	cmp	al, SCS_TWO_INTENSITY
	jne	notTwoIntensity
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; TWO INTENSITY
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	
	; TWO INTENSITY: If this is the first line, pick base color:
	tst	cx
	jnz	gotBase
	
    CheckHack <C_LIGHT_GRAY eq 7>
	mov	dx, C_LIGHT_GRAY			; Max + 1
	call	SaverRandom
	inc	dx					; dx = [1,C_LIGHT_GRAY]
	mov	ds:[bp].SAI_colorInfo, dl		; store base
	clr	ds:[bp].SAI_colorCount

gotBase:
	; If the color count doesn't go negative, go to the next line.
	dec	ds:[bp].SAI_colorCount
   LONG	jns	dontSetColor
	
	; Okay.. pick new intensity:
	mov	dx, 2					; Max + 1
	call	SaverRandom
	mov	cl, 3
	shl	dx, cl					; intensity bit..
    	or	dl, ds:[bp].SAI_colorInfo
	jmp	setColorAndCount
    
notTwoIntensity:
    	cmp	al, SCS_RANDOM_COLORS
	jne	notRandomColor
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; RANDOM COLOR
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	jcxz	needNewColor
	
	dec	ds:[bp].SAI_colorCount
    	jns	dontSetColor
	
needNewColor:
    	mov	dx, C_WHITE				; Max + 1
	call	SaverRandom				; Destroys ax
	inc	dx					; dx (dl) = color index
	jmp	setColorAndCount

notRandomColor:
EC <	cmp	al, SCS_DARK_OR_LIGHT					>
EC <	ERROR_NE STRING_SAVER_APP_OOPS					>
	
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	; DARK OR LIGHT
	; * * * * * * * * * * * * * * * * * * * * * * * * *
	tst	cx
	jnz	haveDarkOrLight
	
	mov	dx, 2					; Max + 1
	call	SaverRandom
	mov	cl, 3
	shl	dx, cl
	mov	ds:[bp].SAI_colorInfo, dl
	clr	ds:[bp].SAI_colorCount

haveDarkOrLight:
	dec	ds:[bp].SAI_colorCount
	jns	dontSetColor
	
	mov	dx, C_LIGHT_GRAY			; Max + 1
	call	SaverRandom
	inc	dl
	add	dl, ds:[bp].SAI_colorInfo
    	; Set color and count...
    
setColorAndCount:
	; Set color count
	push	dx
	mov	dx, ds:[bp].SAI_maxColorCount
	call	SaverRandom
	mov	ds:[bp].SAI_colorCount, dx
	pop	dx
	
setColor:
	; Color should be in dx (dl) at this time
    CheckHack <CF_INDEX eq 0>
    	clr	ax
	mov	al, dl
	call	GrSetLineColor
	
dontSetColor:
	.leave
	ret
StringPickColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringPrepareForDrawing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up info to draw the art.  This is called
		whenever new art is to be drawn.  It clears the screen
		and initializes things.

CALLED BY:	StringAppDraw
PASS:		ds:bp	= pointer to instance data
		di	= GState
		
RETURN:		Nada
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringPrepareForDrawing	proc	near
	class	StringApplicationClass
	uses	si, di

params		local	StringPrepareLocalData

	.enter
    
	; Move instance pointer (passed as bp) into si
    	mov	si, ss:[bp]
	mov	bx, ds:[si].SAI_random			; load random token

	; Pick parameters for this art
	
	mov	dx, ds:[si].SAI_numCurves		; Max + 1
	call	SaverRandom				; dx = result
	mov	ss:[params].SPLD_param1.P_x, dx
	
pickX2Again:
	mov	dx, ds:[si].SAI_numCurves		; Max + 1
	call	SaverRandom				; dx = result
	cmp	dx, ss:[params].SPLD_param1.P_x		; NOT EQUAL TO X1
	je	pickX2Again
	mov	ss:[params].SPLD_param2.P_x, dx
	
pickY1Again:
	mov	dx, ds:[si].SAI_numCurves		; Max + 1
	call	SaverRandom				; dx = result
	cmp	dx, ss:[params].SPLD_param1.P_x		; NOT EQUAL TO X1
	je	pickY1Again
	mov	ss:[params].SPLD_param1.P_y, dx
	
pickY2Again:
	mov	dx, ds:[si].SAI_numCurves		; Max + 1
	call	SaverRandom				; dx = result
	cmp	dx, ss:[params].SPLD_param2.P_x		; NOT EQUAL TO X2
	je	pickY2Again
	cmp	dx, ss:[params].SPLD_param1.P_y		; NOT EQUAL TO Y1
	je	pickY2Again
	mov	ss:[params].SPLD_param2.P_y, dx
	
	; Set up the parameter data!
	mov	di, ds:[si].SAI_paramChunk
	mov	di, ds:[di]				; ds:di pts to params
	mov	si, ds:[si].SAI_piChunk
	mov	si, ds:[si]				; ds:si ptrs to pi's
	
	push	bp
	
	lea	bp, ss:[params]
	mov	cx, 4

paramLoop:
	push	cx
	call	StringCalculateOneParam
	inc	bp					; advance once word
	inc	bp	
	pop	cx
	
	loop	paramLoop
	
	pop	bp
	
	.leave
	ret
StringPrepareForDrawing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringClearAngles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zero's the angles in the param data

CALLED BY:	StringAppDraw
PASS:		ds:bp	= ptr to instance data
RETURN:		nothing
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringClearAngles	proc	near
	class	StringApplicationClass
	
	.enter
	mov	bx, ds:[bp].SAI_paramChunk
	mov	bx, ds:[bx]
	mov	cx, 4

clearLoop:
	clrwwf	ds:[bx].SPD_currentAngle
	add	bx, size StringParameterData
	loop	clearLoop
	
	.leave
	ret
StringClearAngles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringCalculateOneParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate parameter data for one parameter

CALLED BY:	StringPrepareForDrawing

PASS:		ds:di	= ptr to parameter data to set
		ds:si	= ptr to pi chunk
		ss:bp	= ptr to parameter
		
RETURN:		parameter data set, ds:di incremented to next data set
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringCalculateOneParam	proc	near
	.enter
	clr	bx					; options
	
	mov	ax, ss:[bp]				; get parameter
	clc
	rcr	ax, 1					; divide by 2
	jnc	dontNegate				; carry hold old bit 0
	ornf	bl, mask SPO_NEGATE

dontNegate:
	test	ax, 1					; check odd/even
	jnz	useCosine
	ornf	bl, mask SPO_USE_SINE

useCosine:
	mov	ds:[di].SPD_options, bl			; store options
	
	mov	cx, size WWFixed
	mul	cx					; ax now is offset
							; into pi table
	
	mov	bx, si
	add	bx, ax					; ds:bx pts to pi
	
	movwwf	ds:[di].SPD_pi, ds:[bx], ax		; store pi in data
	
	clrwwf	ds:[di].SPD_currentAngle
	
	; Advance ds:di to next param data
	add	di, size StringParameterData
	
	.leave
	ret
StringCalculateOneParam	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringDrawOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws one line of the art

CALLED BY:	StringAppDraw
PASS:		ds:bp	= pointer to instance data
		di	= GState
		
RETURN:		Nada
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringDrawOne	proc	near
	class	StringApplicationClass
	uses	si
	.enter
	
	mov	si, ds:[bp].SAI_paramChunk
	mov	si, ds:[si]
	
	mov	cx, 4
	
calculateLoop:
	push	cx
	movwwf	dxax, ds:[si].SPD_currentAngle
	
	; Calculate next angle and store it.
	movwwf	bxcx, ds:[si].SPD_pi
	addwwf	ds:[si].SPD_currentAngle, bxcx
	
	test	ds:[si].SPD_options, mask SPO_USE_SINE
	jz	useCosine
	call	GrQuickSine
	jmp	short doneWithTrig

useCosine:
	call	GrQuickCosine

doneWithTrig:
	; Result of trig in dx.ax
	test	ds:[si].SPD_options, mask SPO_NEGATE
	jz	doneWithNegate
	negwwf	dxax

doneWithNegate:
	mov	bx, dx					; result in bx.ax
	mov	cx, ds:[si].SPD_midCoord
	call	StringMulWWFByUWordToWWF		; result in dx.cx
	rndwwf	dxcx					; result in dx only
	add	dx, ds:[si].SPD_midCoord
	inc	dx
	mov	ds:[si].SPD_coordinate, dx
	
	pop	cx					; restore counter
	add	si, size StringParameterData
	loop	calculateLoop
	
	mov	si, ds:[bp].SAI_paramChunk
	mov	si, ds:[si]
	
	mov	ax, ds:[si][SPDI_X1].SPD_coordinate
	mov	bx, ds:[si][SPDI_Y1].SPD_coordinate
	mov	cx, ds:[si][SPDI_X2].SPD_coordinate
	mov	dx, ds:[si][SPDI_Y2].SPD_coordinate
	call	GrDrawLine
	
	.leave
	ret
StringDrawOne	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringMulWWFByUWordToWWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies a signed WWFixed by an unsigned word int to get a
		signed WWFixed.

CALLED BY:	StringCalculation

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
StringMulWWFByUWordToWWF	proc	near
	
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
StringMulWWFByUWordToWWF	endp

StringCode	ends
