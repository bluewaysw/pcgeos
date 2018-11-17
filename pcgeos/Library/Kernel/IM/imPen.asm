COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		imPen.asm

AUTHOR:		Andrew Wilson, Nov 15, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/15/91	Initial revision
	lester	12/11/96  	added support for digitizer coords ink

DESCRIPTION:
	This file contains code to implement the various pen support routines.

	The pen support works like this:

	If pen mode is off, then PC/GEOS functions normally (no pen data is
	ever saved).

	If the UI has requested that the IM start monitoring Pen input, then
	whenever a START_SELECT comes in, we begin adding non-collinear points
	to the buffer supplied by the UI.

	If the UI has determined that the mouse movements should be treated as
	ink it calls ImInkReply with AX=TRUE,and the currently entered data
	will be drawn to the screen, and data entered after that will also be
	drawn until either the buffer gets full or the timeout period elapses
	(the mouse is up for INK_TIMEOUT_TICKS).

	If the UI determines that the mouse movements should *not* be ink, 
	then the IM discards the first START_SELECT to END_SELECT series.

	Note that if the mouse is not down, the IM does not save the data, 
	and that once the UI replies that the current drag series is not ink,
	the IM does not save the data either.

Exception cases:

	There are a few places where the buffer can fill up:

	1) While entering ink (the most common case).
	2) If the UI is blocked or not responding to our mouse events (in which
	   case the buffer fills up with unprocessed mouse events).

	If it fills up while entering ink, we stop allowing ink to be entered,
	terminate the current segment, and pass it off to the UI when the next
	END_SELECT is encountered.

	If it fills up while not entering ink, there are 2 cases:

	1) It fills up when processing a START_SELECT.
		In this case, we do *not* pass the START_SELECT off to the
		UI, and instead just eat the mouse events (don't pass them off
		or store them) until we get an END_SELECT.

	2) It fills up when processing a MSG_META_PTR.
		In this case, we terminate the current segment, stop storing
		data, but continue passing the mouse events off to the UI.

	$Id: imPen.asm,v 1.1 97/04/05 01:17:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMResident	segment resource
if	NO_PEN_SUPPORT
global	NoPenSupportError:far
NoPenSupportError	proc	far
EC <	ERROR	NO_PEN_SUPPORT_IN_THIS_KERNEL				>
NEC <	stc								>
NEC <	ret								>
NoPenSupportError	endp
else

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImInkReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the routine to call depending upon whether or not 
		the current routine is ink or not. It sends a method off to
		the IM thread to handle it.

CALLED BY:	GLOBAL
PASS:		AX = TRUE if the last select series was Ink
		     FALSE if it was not Ink
		BP = gstate to draw ink through (or 0 if none) (if AX=TRUE)
		BX = width/height of brush
		CX:DX = vfptr to callback routine
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImInkReply	proc	far	uses	ax, cx, di, bx, ds, si
	class	IMClass
	.enter
	tst	ax
	mov	ax, MSG_IM_INK_REPLY_NEGATIVE
	jz	sendMessage
	mov	ax, MSG_IM_INK_REPLY_POSITIVE
	mov	si, bx			;SI <- brush width/height
sendMessage:
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	LoadVarSeg	ds, bx
	mov	bx, ds:[imThread]
	call	ObjMessage
	.leave
	ret
ImInkReply	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImInkReplyMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method handler invoked when the UI determines
		whether or not the last mouse input should be ink or not.

CALLED BY:	GLOBAL
PASS:		ax - method
		BP = gstate to draw ink through (or 0 if none) (if AX=TRUE)
		SI = width/height of brush
		CX:DX = callback routine
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImInkReplyMsg	method	IMClass, MSG_IM_INK_REPLY_POSITIVE,
				 MSG_IM_INK_REPLY_NEGATIVE
	tst	ds:[inkCallVector].segment
	jz	exit
	CallToInkSegment	InkReplyHandler
exit:
	ret
ImInkReplyMsg	endp

endif	;NO_PEN_SUPPORT


IMResident	ends

ife	NO_PEN_SUPPORT
IMPenCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawInkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This callback routine draws the ink in the buffer

CALLED BY:	GLOBAL
PASS:		ax, bx - old point values
		cx, dx - new point values
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawInkCallback	proc	far	uses	ds
	.enter
	LoadVarSeg	ds, bx
	tst_clc	ax
	js	startNewSegment
10$:
	call	DrawInkLine
	mov_tr	ax, cx
	mov	bx, dx
	clc
	.leave
	ret

startNewSegment:
	mov	ds:[inkCurPoint].P_x, cx	
	andnf	ds:[inkCurPoint].P_x, 0x7fff
	mov	ds:[inkCurPoint].P_y, dx
	jmp	10$
DrawInkCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLengthOfSegmentCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine updates the count of points and returns carry
		set when the end of the segment is reached

CALLED BY:	GLOBAL
PASS:		ax - # points so far
		cx, dx - new points
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLengthOfSegmentCallback	proc	far
	inc	ax
	shl	cx		;Sets carry if end of segment
	ret
FindLengthOfSegmentCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrySaveUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine tries to do a save under of the passed height
		centered around the first point in the ink array.

CALLED BY:	GLOBAL
PASS:		dx - height of save under
		bp - max Y coord of window
		ax, cx - left and right bounds of saveunder region
		es - P-locked window
RETURN:		if save under was successful:
			carry clear
			ax, bx, cx, dx - bounds of saveunder
		else:
			carry set
			ax, bx, cx, dx - unchanged	
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TrySaveUnder	proc	near
	.enter
	push	bx, dx
	push	ds
	mov	ds, ds:[inkData]
	mov	di, ds:[CBS_start]
	mov	bx, dx
	shr	bx, 1
	neg	bx			;BX = -1/2 * height of save under
	add	bx, ds:[di].P_y		;
	jns	10$			;BX = first point in ink - 1/2 height 
	clr	bx			;If this is negative, start at top
					; of screen
10$:

;	BX <- top coordinate of screen to try to save under
;	DX <- height of the saveunder area
;	BP <- bottom coordinate of screen to try to saveunder

	mov	di, dx		;DI <- height of saveunder area
	add	dx, bx
	cmp	dx, bp
	jbe	20$		;If saveunder area is entirely on screen,
				; branch
	mov	dx, bp		;Else, have the saveunder area end at the
	mov	bx, dx		; bottom of the screen, and recalculate the
	sub	bx, di		; top of the saveunder area 
	jnc	20$
	clr	bx
20$:
	pop	ds
	push	ax

	push	ds, es, bx, cx, dx, si, bp

	mov	di, DR_VID_SAVE_UNDER
EC <	tstdw	ds:pointerDriver					>
EC <	ERROR_Z	NO_VIDEO_DRIVER_LOADED_YET				>
	call	ds:pointerDriver

	pop	ds, es, bx, cx, dx, si, bp
	jnc	saveUnderWorked

	pop	ax
	pop	bx, dx
exit:
	.leave
	ret
saveUnderWorked:
	mov	es:[W_saveUnder], al
	pop	ax
	add	sp, size word * 2	;Don't bother restoring original top/
					; bottom - return area that we saved
	jmp	exit
TrySaveUnder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSaveUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to setup a save under for the ink to be drawn.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		nada
DESTROYED:	bx, es, ax, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSaveUnder	proc	near	uses	bp
	.enter
	clr	ds:[inkWinHasSaveUnder]

	mov	ax, ds:[lockedInkGState]	;If we aren't drawing to the
	cmp	ax, ds:[inkDefaultGState]	; default gstate, then just
	jnz	exit				; exit.

	mov	bx, ds:[lockedInkWin]
	call	MemDerefES
	mov	ax, es:[W_winRect].R_left
	mov	cx, es:[W_winRect].R_right
	mov	dx, es:[W_winRect].R_bottom
	mov	bp, dx				;BP <- bottom of window
	sub	dx, ds:[W_winRect].R_top	;DX <- height of window
	mov	bx, 4				;Loop through this 4 times
loopTop:
	call	TrySaveUnder
	jnc	gotSaveUnder
	shr	dx, 1				;Cut height in half.
	dec	bx
	jnz	loopTop

exit:
	.leave
	ret

gotSaveUnder:

;	Save upper/lower bounds of the ink

	mov	ds:[saveUnderUpperBound], bx
	mov	ds:[saveUnderLowerBound], dx
	mov	ds:[inkWinHasSaveUnder], TRUE
	jmp	exit

SetupSaveUnder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreSaveUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine tries to restore any previous saveunder area.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		carry set if save under has been nuked
DESTROYED:	es, ax, di, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreSaveUnder	proc	near
	mov	bx, ds:[inkWin]
	call	MemPLock
	mov	es, ax

	; make sure that the save under was not nuked

	tst	es:[W_saveUnder]
	stc
	jz	afterRestore

	mov	di, DR_VID_RESTORE_UNDER
	call	CallPtrDriver
	clr	es:[W_saveUnder]
	clc
afterRestore:
	call	MemUnlockV
	ret
RestoreSaveUnder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkReplyHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the routine called when the UI has responded about
		the ink.

CALLED BY:	GLOBAL
PASS:		ax - MSG_IM_INK_REPLY_NEGATIVE, MSG_IM_INK_REPLY_POSITIVE
		BP = gstate to draw ink through (or 0 if none) (if AX=TRUE)
		SI = width/height of brush
		CX:DX = vfptr to callback routine
		ds - kdata
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, dp, di, es, perhaps others
 
PSEUDO CODE/STRATEGY:
	See description of states in header of InkInputMonitor()...

	When the UI tells us the status of a START_SELECT:

		If they say that the START_SELECT is INK, we create a gstate
		to draw through, and draw all the current ink. If we are
		in state 1, we start the timeout timer and go to state 4
		Else, we go to state 3. 

		If they say that the START_SELECT is not ink:

		We delete the first START_SELECT to END_SELECT pair. If we
		haven't received an END_SELECT for the first START_SELECT
		yet, then we delete what we have and goto state #1. Else, 
		we stay in the same state we were in.


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkReplyHandler	proc	far
	class	IMClass
	cmp	ax, MSG_IM_INK_REPLY_NEGATIVE
	LONG jz	notInk
EC <	cmp	ax, MSG_IM_INK_REPLY_POSITIVE				>
EC <	ERROR_NZ	INVALID_MSG_PASSED_TO_INK_REPLY_HANDLER		>

	movdw	ds:[inkGestureCallback], cxdx

	; tell the mouse driver to not combine events

	mov	cl, MCM_NO_COMBINE
	call	SetMouseCombineMode

	mov	cx, ds:[inkDefaultWidthAndHeight]
	mov	ds:[inkBrushSize], cx
	tst	si
	jz	noPassedBrushSize
	mov	ds:[inkBrushSize], si
noPassedBrushSize:
	mov	di, ds:[inkDefaultGState]
	tst	bp
	jz	doDraw
	mov	di, bp
doDraw:
	mov	ds:[lockedInkGState], di


;
;	The problem we have here is if we are drawing to an app-supplied
;	gstate - this gstate will be hooked to a window, and hence will have
;	some funky transformation associated with it. We just want to draw
;	in screen coordinates, so we lock the gstate/windows and call the
;	video driver ourselves. Since the window will be P-Locked, we don't
;	have to worry about any stupid apps trying to do things to the window
;	while we are drawing to it either...
;

	mov	bx, ds:[lockedInkGState]
	call	MemPLock
	mov	es, ax	
	mov	bx, es:[GS_window]
EC <	tst	bx							>
EC <	ERROR_Z	WIN_PASSED_GSTATE_HAS_NO_WINDOW				>
   	call	MemPLock
	mov	ds:[lockedInkWin], bx
	mov	es, ax

;	Validate the window, as it may not have valid clip regions, etc.

	push	ds
	mov	bx, ds:[lockedInkGState]
	call	MemDerefDS
	call	WinValWinStrucFar
	test	es:[W_grFlags], mask WGF_MASK_NULL
	pop	ds
	jnz	windowNull

;	Grab the graphics exclusive, so nobody will draw to the screen.

	clr	bx
	call	GrGrabExclusive

;	Try to setup save under for the root window 

	call	SetupSaveUnder

	mov	di, DR_VID_HIDEPTR
	call	CallPtrDriver

;	Draw the current ink

	mov	bp, ds:[lockedInkGState]	;BP <- gstate to draw through
EC <	tst	bp							>
EC <	ERROR_Z	NO_INK_GSTATE						>

;	Put ink bounds in invalid state so they will get updated by
;	DrawInkLine()

	mov	ds:[inkUpperLeftBounds].P_x, 0x7fff

;	Draw all the ink, but first munge the data so brush is centered.

	call	PointBufferModify
	mov	ah, -1
	mov	bh, ah
	mov	cx, cs
	mov	dx, offset DrawInkCallback
	call	PointBufferEnum

	clr	ds:[haveCalledGestureCallback]
	cmp	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT
	mov	ds:[inkStatus], ICS_COLLECT_AND_DRAW_UNTIL_END_SELECT
	jnz	exit

;	The user is currently between strokes 
;	so we check to see if the already-entered ink is a gesture.
;
;	If so, send off the ink and exit
;
;	If not, start up the timeout timer and await the entry of the next
;	ink stroke.

;	We treat all the data that the user has entered up to this point as
;	a single stroke, so the text object gesture routine will still try
;	to recognize it as a gesture.

	call	CheckIfGesture
	jnc	notGesture
	mov	ds:[inkStatus], ICS_SEND_CLEAR

;	We just set the im monitor finite state machine to
;	ICS_JUST_SEND_INK, now we send it message so it will send
;	the ink off to the UI.

	mov	ax, MSG_META_NOTIFY
	mov	bx, ds:[imThread]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT 
	call	ObjMessage
	jmp	exit
notGesture:
	call	StartTimeoutTimerAndWaitForStartSelect

exit:
	ret
windowNull:
;
;	The window was still in the process of coming up (or was suspended)
;	when the user tried to draw ink in it. Clean up after ourselves,
;	and pretend that the reply was "NO_INK".
;
;	This is fairly tricky, since the flow object has discarded all the
;	mouse events we've sent it up to this point. We nuke all of our
;	points, and either wait
;
EC <	WARNING	DISCARDING_MOUSE_INPUT					>

	mov	bx, ds:[lockedInkWin]
	call	MemUnlockV
	mov	bx, ds:[lockedInkGState]
	call	MemUnlockV

	mov	cl, MCM_COMBINE
	call	SetMouseCombineMode

;
;	The flow object is stupidly hanging out waiting for a MSG_INK.
;	Send it one (with BP=0), and nuke all the points we've collected.
;
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	clr	bp
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK
	mov	bx, ds:[imThread]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

;
;	Don't collect any data until the next start select.
;
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT

;
;	Nuke any and all points that we've collected.
;
	clr	bx
	mov	ds:[inkNumStrokes], bx
	xchg	ds:[inkHandle], bx
	tst	bx
	jz	clearBuffer
	call	MemFree
clearBuffer:
	call	PointBufferGetCount
	call	PointBufferDelete
if INK_DIGITIZER_COORDS
	clr	bx
	xchg	ds:[inkCoordsBlockHan], bx
	tst	bx
	jz	noInkCoords
	call	MemFree			
noInkCoords:
endif ; INK_DIGITIZER_COORDS
	jmp	exit

notInk:

	; tell the mouse driver to combine events
	mov	cl, MCM_COMBINE
	call	SetMouseCombineMode

	clr	ax
	mov	cx, cs
	mov	dx, offset FindLengthOfSegmentCallback
	call	PointBufferEnum	

		;Returns AX = # items in buffer.
		;Carry set if we've already collected an END_SELECT
	jc	30$
						;Else, we're in the middle of
						; a select, so go back to
						; "non-collecting" mode	
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT
	inc	ds:[inkNumStrokes]		;We increment the # strokes,
						; because we haven't gotten an
						; end select for this stroke
						; yet.
30$:
EC <	tst	ds:[inkNumStrokes]					>
EC <	ERROR_Z	INK_NUM_STROKES_MUST_BE_NON_ZERO			>
	mov_tr	cx, ax				;CX <- # items to delete
	call	PointBufferDelete
	dec	ds:[inkNumStrokes]
if INK_DIGITIZER_COORDS
	;
	; Delete the digitizer coords in the first segment.
	;
	clr	ax
	mov	cx, cs
	mov	dx, offset FindLengthOfSegmentCallback
	CheckHack <segment FindLengthOfSegmentCallback eq @CurSeg>
	CheckHack <segment FindLengthOfSegmentCallback eq IMPenCode>
	CheckHack <segment DigitizerCoordsEnum eq @CurSeg>
	call	DigitizerCoordsEnum
		; Returns AX = # items in first segment.
	mov_tr	cx, ax				;CX <- # items to delete
	call	DigitizerCoordsDelete
endif ; INK_DIGITIZER_COORDS
	jmp	exit
InkReplyHandler	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetMouseCombineMode

DESCRIPTION:	Set the combine mode in the mouse driver

CALLED BY:	INTERNAL

PASS:
	cl - MouseCombineMode

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/17/92		Initial version
	Don	11/13/93	Do nothing if no default driver, to
				handle problems with pen driver input
				arriving while registering interrupt handler

------------------------------------------------------------------------------@
SetMouseCombineMode	proc	near	uses ax, bx, si, di, ds
	.enter

	mov	ax, GDDT_MOUSE
	call	GeodeGetDefaultDriver
	tst	ax
	jz	done
	mov_tr	bx, ax
	call	GeodeInfoDriver
	mov	di, DR_MOUSE_SET_COMBINE_MODE
	call	ds:[si].DIS_strategy
done:
	.leave
	ret
SetMouseCombineMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPenResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the IMPenCode resource into a fixed segment.

CALLED BY:	GLOBAL
PASS:		ds - idata
RETURN:		cx - segment of block
		bx - handle of block
		  - or -
		carry set if couldn't allocate it
DESTROYED:	ax, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	not KERNEL_EXECUTE_IN_PLACE and (not FULL_EXECUTE_IN_PLACE)
EC <cat	char	'input',0					>
EC <key char	'debugInk',0					>
CopyPenResource	proc near	uses	es, ds
	.enter

if	ERROR_CHECK

	segmov	ds, cs, cx
	mov	dx, offset key
	mov	si, offset cat 
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	doCopy

	WARNING	INK_DEBUGGING_TURNED_ON
	mov	bx, handle IMPenCode
	call	MemLock
	mov	cx, ax

	clr	bx				
	clc
	jmp	exit
doCopy:
endif

;	Get the size of this resource

	mov	ax, MGIT_SIZE
	mov	bx, handle IMPenCode
	call	MemGetInfo		;AX <- size of this resource

;	Allocate a similarly-sized fixed block

	push	ax
	mov	bx, handle 0
	mov	cx,mask HF_FIXED or (mask HAF_READ_ONLY or mask HAF_CODE) shl 8
	call	MemAllocSetOwnerFar		;
	pop	cx
	jc	exit
	mov	es, ax			;ES:DI <- ptr to dest
	clr	di
	segmov	ds, cs			;DS:SI <- ptr to src
	clr	si
	shr	cx, 1			;CX is *never* odd
	rep	movsw			;Copy data over
	mov	cx, es
					;Carry should be cleared by "shr" 
					; above...
EC <	ERROR_C	SIZE_OF_PEN_CODE_BLOCK_WAS_ODD				>
exit:

	.leave
	ret
CopyPenResource	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoInvalBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine invalidates the passed bounds

CALLED BY:	GLOBAL
PASS:		ax, bx, cx, dx - bounds
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoInvalBounds	proc	near
	class	IMClass
	sub	sp, size Rectangle
	mov	bp, sp
	mov	ss:[bp].R_left, ax
	mov	ss:[bp].R_top, bx
	mov	ss:[bp].R_right, cx
	mov	ss:[bp].R_bottom, dx

	mov	dx, size Rectangle
	mov	ax, MSG_IM_REDRAW_AREA
	mov	bx, ds:[imThread]	
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	ret
DoInvalBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine erases the ink on the screen, either by restoring
		from save-under, or by generating a MSG_META_INVAL_BOUNDS...
		If we were drawing through a user-supplied gstate, don't
		erase the ink

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseInk	proc	near

;	Unlock the window/gstate

	mov	bx, ds:[lockedInkGState]
	call	MemDerefES
	mov	bx, es:[GS_window]
	call	MemUnlockV
	mov	bx, ds:[lockedInkGState]
	mov	di, bx
	call	MemUnlockV

;	Allow drawing again

	clr	bx
	call	GrReleaseExclusive	; will return bogus (offscreen) coords
					;  of no drawing operations aborted 
					;  during the time we had the exclusive

	tst	ax			
	js	20$			; if offscreen, skip invalidation
	push	di
	call	DoInvalBounds		; else do it baby
	pop	di

20$:
	cmp	di, ds:[inkDefaultGState]
	jnz	notDefaultGState

;	Bump lower right bounds as our ink is 2 pixels wide/tall...

	inc	ds:[inkLowerRightBounds].P_x
	inc	ds:[inkLowerRightBounds].P_y

;	Restore the save under area, if any

	tst	ds:[inkWinHasSaveUnder]
	jz	invalEntireInk
	call	RestoreSaveUnder
	jc	invalEntireInk

;	The ink may have been drawn outside the save under area. If so,
;	expose those areas.

	mov	bx, ds:[inkUpperLeftBounds].P_y
	cmp	bx, ds:[saveUnderUpperBound]
	jge	inkNotAboveSaveUnder
	mov	ax, ds:[inkUpperLeftBounds].P_x
	mov	cx, ds:[inkLowerRightBounds].P_x
	mov	dx, ds:[saveUnderUpperBound]
	dec	dx
	call	DoInvalBounds
inkNotAboveSaveUnder:
	mov	dx, ds:[inkLowerRightBounds].P_y
	cmp	dx, ds:[saveUnderLowerBound]
	jle	exit

	mov	bx, ds:[saveUnderLowerBound]
	inc	bx
	jmp	invalAndExit
	

invalEntireInk:

;	Get the bounds of the ink, and send a method to the UI to invalidate
;	them.

	mov	bx, ds:[inkUpperLeftBounds].P_y
	mov	dx, ds:[inkLowerRightBounds].P_y
invalAndExit:
	mov	ax, ds:[inkUpperLeftBounds].P_x
	mov	cx, ds:[inkLowerRightBounds].P_x

	call	DoInvalBounds
exit:
	
;	Draw the cursor again.

	mov	di, DR_VID_SHOWPTR
	call	CallPtrDriver
	ret

notDefaultGState:
	call	GrDestroyState
	jmp	exit
EraseInk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyInkWinAndGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine destroys the current ink window and gstate, and
		restores the screen from the ink if necessary.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax, bx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyInkWinAndGState	proc	near
	.enter
	cmp	ds:[inkStatus], ICS_COLLECT_UNTIL_END_SELECT
	jbe	noErase
	call	EraseInk
noErase:
	mov	di, ds:[inkDefaultGState]
	tst	di
	jz	noInkState
	call	GrDestroyState
noInkState:
	mov	di, ds:[inkWin]
	tst	di
	jz	noInkWin
	call	WinClose
noInkWin:
	.leave
	ret
DestroyInkWinAndGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateInkWinAndGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a root window to draw ink to and a gstate to draw
		with.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		inkWin, inkDefaultGState - set to values
DESTROYED:	ax, bx, dx, bp, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateInkWinAndGState	proc	near	uses	cx
	.enter
	mov	di, ds:[pointerWin]
	call	WinGetWinScreenBounds

	mov	bp, handle 0
	push	bp			;Layer ID
	push	bp			;Process to own window

	push	ds:[pointerDriverHandle]

	clr	bp
	push	bp
	push	bp

	push	dx			;Push bounds of window
	push	cx
	push	bx
	push	ax

	mov	ax, (mask WCF_TRANSPARENT or mask WCF_PLAIN) shl 8
	clrdw	cxdx			;No Output ODs
	clr	di			;
	mov	si, mask WPF_ROOT or WIN_PRIO_STD or mask WPF_CREATE_GSTATE
	call	WinOpen

	mov	ds:[inkWin], bx
	mov	ds:[inkDefaultGState], di

;	Init the separator, which is used when drawing line segments later

	mov	ds:[inkSeparator].P_x, 8000h
	mov	ds:[inkSeparator].P_y, 8000h	
	.leave
	ret
CreateInkWinAndGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImStartPenMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine tells the IM to begin storing ink.

CALLED BY:	GLOBAL
PASS: 		nothing
RETURN:		carry set if error (could not allocate memory to store
				    ink data)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version
	lester	11/24/96	added call to AllocateDigitizerCoordsBuffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImStartPenMode	proc	far	uses	ds, ax, bx, cx, dx, di, si
	.enter

;	Before we add the input monitor to collect the ink data, allocate
;	and initialize the buffer. We allocate the buffer "FIXED" so we don't
;	have the overhead of locking the block with every ptr event, and so
;	it never gets swapped (which would be a bad thing).

	LoadVarSeg	ds, cx
	mov	bx, handle 0
	mov	cx, mask HF_FIXED
	mov	ax, INK_DATA_BUFFER_SIZE
	call	MemAllocSetOwnerFar
	jc	exit

EC <	tst	ds:[inkData]						>
EC <	ERROR_NZ	IM_START_PEN_MODE_WAS_CALLED_TWICE		>

	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT

	mov	ds:[inkData], ax
	mov	ds:[inkDataHan], bx
	call	PointBufferInit	;Init the buffer passed in AX

if INK_DIGITIZER_COORDS
;	Allocate circular buffer for absolute digitizer coordinates
;	if the appropriate ini entry is set.
	call	AllocateDigitizerCoordsBuffer	; carry set on failure
	jc	freeExit
endif ; INK_DIGITIZER_COORDS

;	Input monitors and the associated pen code must be in a fixed block,
;	so copy this resource into one.

AXIP<	mov	cx, cs							>
NOAXIP<	call	CopyPenResource		;Returns CX <- segment of fixed >
					; copy of pen resource
NOAXIP<	jc	freeExit						>

NOAXIP<	mov	ds:[inkCodeBlock], bx					>
	mov	ds:[inkCallVector].segment, cx

;	Create a window and a gstate to draw ink to

	call	CreateInkWinAndGState

;	Add an input monitor to collect ink data.


	mov	bx, offset inkMonitor	;DS:BX <- ptr to Monitor<> structure

					;CX:DX <- fptr to monitor routine
	mov	dx, offset InkInputMonitor

	mov	al, ML_INK		;AL <- Monitor level (Ink comes after
					; everything but before the data is
					; sent through the OD)
	call	ImAddMonitor
	clc
exit:
	.leave
	ret

if	(not KERNEL_EXECUTE_IN_PLACE and not FULL_EXECUTE_IN_PLACE) \
	or INK_DIGITIZER_COORDS
freeExit:
	clr	bx
	mov	ds:[inkData], bx
	xchg	bx, ds:[inkDataHan]
	tst	bx
	jz	noInk
	call	MemFree
noInk:
if INK_DIGITIZER_COORDS
	clr	bx
	mov	ds:[inkCoordsBuffer], bx
	xchg	bx, ds:[inkCoordsBufferHan]
	tst	bx
	jz	noInkCoords
	call	MemFree
noInkCoords:
endif ; INK_DIGITIZER_COORDS
	stc
	jmp	exit
endif
ImStartPenMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImExitPenMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This exits pen mode. We do this on the IM thread to ensure
		that nobody is running in the copied code resource when we
		free it.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version
	lester	11/25/96	added call to RemoveDigitizerCoordsBuffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImExitPenMode	method	IMClass, MSG_IM_EXIT_PEN_MODE

	mov	al, mask MF_REMOVE_IMMEDIATE
	mov	bx, offset inkMonitor
	call	ImRemoveMonitor

	mov	bx, ds:[inkDataHan]
	tst	bx
	jz	noInk
	call	MemFree
noInk:

if INK_DIGITIZER_COORDS
	mov	bx, ds:[inkCoordsBufferHan]
	tst	bx
	jz	noInkCoords
	call	RemoveDigitizerCoordsBuffer
noInkCoords:
endif ; INK_DIGITIZER_COORDS

NOAXIP<	mov	bx, ds:[inkCodeBlock]					>
NOAXIP<	tst	bx							>
NOAXIP< jz	noFree							>
NOAXIP<	call	MemFree							>
NOAXIP<noFree:								>

	mov	bx, ds:[inkTimerHan]
	mov	ax, ds:[inkTimerID]
	tst	bx
	jz	10$
	call	TimerStop
	clr	bx
10$:
	mov	ds:[inkTimerHan], bx
	mov	ds:[inkTimerID], bx
	mov	ds:[inkDataHan], bx
	mov	ds:[inkData], bx
	mov	ds:[inkCodeBlock], bx
	mov	ds:[inkCallVector].segment, bx

;	Free up any gstate we may have been using to draw ink

	call	DestroyInkWinAndGState
	ret
ImExitPenMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImRedrawArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler forces a redraw of a portion of the screen

CALLED BY:	GLOBAL
PASS:		ss:bp - Bounds of area to invalidate (in screen coords)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImRedrawArea	method	IMClass, MSG_IM_REDRAW_AREA
	mov	ax, MSG_META_INVAL_BOUNDS
	mov	bx, ds:[uiHandle]
	mov	cx, ds:[pointerWin]		;CX <- root window to inval
	mov	di, mask MF_STACK
	GOTO	ObjMessage
ImRedrawArea	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImEndPenMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes the input manager out of the mode where
		it captures ink and into its normal mode.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImEndPenMode	proc	far	uses	ax, bx, cx, dx, bp, di, ds
	class	IMClass
	.enter

;	Send a message to the IM thread to do this, so we can be certain that
;	nobody is doing anything in the copied code block when we free it.

	LoadVarSeg	ds, bx
	mov	ax, MSG_IM_EXIT_PEN_MODE
	mov	bx, ds:[imThread]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	.leave
	ret
ImEndPenMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreInkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that stores ink points

CALLED BY:	GLOBAL
PASS:		cx, dx - ink point
		es:bp - ptr to store it
RETURN:		carry clear
		bp updated to point to where to store next point
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreInkCallback	proc	far
	mov	es:[bp].P_x, cx
	mov	es:[bp].P_y, dx
	add	bp, size Point		;Should never set carry
EC <	ERROR_C	INK_ENUM_EXCEEDED_END_OF_BUFFER			>
	ret
StoreInkCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LimitPtrToScreenLimits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Limits the pointer event to the limits of the screen.

CALLED BY:	GLOBAL
PASS:		ds - dgroup
		cx, dx - point
RETURN:		cx, dx - changed to lie onscreen, if necessary
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LimitPtrToScreenLimits	proc	near
	.enter
	cmp	cx, ds:[screenXMin]
	jl	setXMin

	cmp	cx, ds:[screenXMax]
	jg	setXMax
checkY:
	cmp	dx, ds:[screenYMin]
	jl	setYMin
	cmp	dx, ds:[screenYMax]
	jg	setYMax
exit:
	.leave
	ret
setXMin:
	mov	cx, ds:[screenXMin]
	jmp	checkY
setXMax:
	mov	cx, ds:[screenXMax]
	jmp	checkY

setYMin:
	mov	dx, ds:[screenYMin]
	jmp	exit
setYMax:
	mov	dx, ds:[screenYMax]
	jmp	exit
LimitPtrToScreenLimits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkInputMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the routine through which all mouse events travel and
		are converted into ink.

CALLED BY:	GLOBAL
PASS:		di - event type (method)
		cx, dx, bp, si - event data
		ss:sp - IM stack frame
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	There are a number of ink-collection states that we can be in:

	1) We can be doing nothing, and waiting for a START_SELECT
		When a START_SELECT comes in, we store it and go to state #2

		In the meantime, we just pass on all events.

	2) We can be collecting possible ink and waiting until an END_SELECT
		We hang around and collect ink until the UI tells us the
		status of the START_SELECTs we've collected or until
		we've received an END_SELECT.

		When we receive an END_SELECT, we go back to state #1

If the UI replies that the user is entering ink, we can move to these states:

	3) We can be collecting ink and waiting for an END_SELECT
		If a START_SELECT comes in here, we crash, as you can't get
		multiple START_SELECTs...

		If a MSG_META_PTR comes in, we draw to the screen, and buffer it up.

		When an END_SELECT comes in, we start our timeout timer and
		goto state 4.

	4) We can be waiting for a START_SELECT
		When a START_SELECT comes in, we kill the current timeout
		timer, draw a point at the current position, and goto state 3

	When the timeout timer hits:

		We compare it to the current timeout timer, and if it doesn't
		match (it's been killed but somehow managed to squeak into
		the queue) we ignore it.

		Otherwise, we grab all the ink data we've collected so far,
		send it off to the UI, and go back to state #1


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkInputMonitor	proc	far
	class	IMClass

	LoadVarSeg	ds, bx

;	Determine our status, and call through the associated handler routine

	cmp	di, MSG_IM_INK_TIMEOUT
	je	timeout


	mov	bx, ds:[inkStatus]

	cmp	bx, ICS_SEND_CACHED_START_SELECT
	je	noCheckBounds		;Don't trash inkPenSavedXX values if
					; we are sending a cached start select.
if INK_DIGITIZER_COORDS
	cmp	bx, ICS_SEND_INK_AND_THEN_SEND_CACHED_START_SELECT
	je	noCheckBounds		;Don't trash inkPenSavedXX values if
					; we are sending the ink prior to 
					; sending a cached start select.
endif
	mov	ds:[inkPenSavedCX], cx
	mov	ds:[inkPenSavedDX], dx
	mov	ds:[inkPenSavedBP], bp

	cmp	bx, ICS_COLLECT_AND_DRAW_AFTER_START_SELECT
	jae	noCheckBounds


	cmp	di, MSG_META_MOUSE_PTR
	je	checkBounds
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	callHandler
checkBounds:

;	The event hasn't been restricted to the screen limits yet (this
;	happens in OutputMonitor). We want to restrict them here, for our
;	uses.

	call	LimitPtrToScreenLimits


callHandler:
	call	cs:[inputFSMTable][bx]
	cmp	di, MSG_META_NOTIFY_WITH_DATA_BLOCK	;Don't restore cx,dx
	je	exit					; if we are sending
							; ink off.
	mov	cx, ds:[inkPenSavedCX]
	mov	dx, ds:[inkPenSavedDX]
exit:

;	Check for illegal flags being set

EC <	test	al, not (mask MF_MORE_TO_DO or mask MF_DATA)		>
EC <	ERROR_NZ	IM_BAD_FLAGS_RETURNED_FROM_MONITOR		>
	ret
noCheckBounds:
	call	cs:[inputFSMTable][bx]
	jmp	exit


timeout:
	clr	al				;Assume that we don't want
						; to process this message...
	cmp	bp, ds:[inkTimerID]		;If this isn't the current 
	jne	exit				; timer, exit
	clr	ds:[inkTimerID]
	clr	ds:[inkTimerHan]
if INK_DIGITIZER_COORDS
	call	SendInkCoords
else
	call	SendInk
endif
	jmp	exit
InkInputMonitor	endp

inputFSMTable	label	nptr
	nptr	SkipUntilStartSelect
	nptr	CollectUntilEndSelect
	nptr	CollectAndDrawUntilEndSelect
	nptr	CollectAndDrawAfterStartSelect
	nptr	EatEventsUntilEndSelect
	nptr	SendInkOnEndSelect
	nptr	SendInk
	nptr	SendCachedStartSelect
	nptr	SendClear
if INK_DIGITIZER_COORDS
	nptr	SendInkCoords
	nptr	SendInkAndThenSendCachedStartSelect
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendPointsToInkBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine appends all the current points in the ink
		buffer to the ink block.	

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		carry set if error, bp=0
			-else-
		bx, bp = handle of locked ink block
		cx - # points just added
		es - segment of locked ink block	
DESTROYED:	ax, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendPointsToInkBlock	proc	near
	.enter
	call	PointBufferGetCount
	tst	ds:[inkHandle]
	jnz	haveInkHandle

;	Get the # points in the ink, and allocate a buffer big enough to hold
;	it. This is pretty bad to do (allocate memory on the IM thread), but
;	there isn't much to be done about it (sigh).

	mov_tr	ax, cx				;AX <- # points to allocate
	shl	ax, 1				;AX <- # bytes
	shl	ax, 1
	add	ax, size InkHeader		;
	mov	bx, handle 0
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAllocSetOwnerFar
	jc	exit
	mov	ds:[inkHandle], bx
	mov	es, ax
	clr	es:[IH_count]
common:
	mov	es, ax
	mov	bp, es:[IH_count]
	shl	bp, 1
	shl	bp, 1
	add	bp, offset IH_data		;ES:BP <- ptr to store next pt

	push	ds:[inkHandle]
	clr	ds:[inkHandle]			;We only care about the ink
	mov	cx, cs				; in the local buffer, not
						; the ink in the global buffer,
						; so temporarily nuke handle 
	mov	dx, offset StoreInkCallback
	call	PointBufferEnum
	pop	ds:[inkHandle]

	call	PointBufferGetCount		;CX <- # points in the buffer

	add	es:[IH_count], cx		;Clears carry
EC <	ERROR_C	-1							>
EC <	tst	es:[IH_count]						>
EC <	ERROR_Z	NUM_INK_POINTS_IS_ZERO					>

exit:
	mov	bp, ds:[inkHandle]
	.leave
	ret
haveInkHandle:
	mov	bx, ds:[inkHandle]
	call	MemLock
	mov	es, ax
	add	cx, es:[IH_count]
	mov_tr	ax, cx				;AX <- # points to allocate
	shl	ax, 1
	shl	ax, 1
	add	ax, size InkHeader		;AX <- new size of block
	clr	ch
	call	MemReAlloc
	jnc	common

	clr	bx				;If we couldn't resize the
	xchg	bx, ds:[inkHandle]		; block, return an error.
	call	MemFree
	stc
	jmp	exit
AppendPointsToInkBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send an empty ink message off to the flow object, so
		that it clears the  FF_PROCESSING_INK flag.  This is
		needed because sending a gesture should not clear
		the FF_PROCESSING_INK flag because more than one
		gesture might have to be sent.  So after all of the
		gestures are sent, SendClear is called to clear
		FF_PROCESSING_INK flag.

CALLED BY:	
PASS:		ds - kdata
RETURN:		di - MSG_META_NOTIFY_WITH_DATA_BLOCK to send to output
		bp - 0
		al - MF_DATA
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendClear	proc	near
	.enter
if INK_DIGITIZER_COORDS
EC <	cmp	di, MSG_IM_READ_DIGITIZER_COORDS			>
EC <	ERROR_E	INK_RECEIVED_UNEXPECTED_MSG_IM_READ_DIGITIZER_COORDS	>
endif
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT

	clr	bp
	mov	di, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK
	mov	al, mask MF_DATA
	.leave
	ret
SendClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the ink off to the UI.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		di - MSG_META_NOTIFY_WITH_DATA_BLOCK to send to output
		bp - data to send with MSG_META_NOTIFY_WITH_DATA_BLOCK
		al - MF_DATA
DESTROYED:	es, ah, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInk	proc	near
if INK_DIGITIZER_COORDS
EC <	cmp	di, MSG_IM_READ_DIGITIZER_COORDS			>
EC <	ERROR_E	INK_RECEIVED_UNEXPECTED_MSG_IM_READ_DIGITIZER_COORDS	>
endif
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT

	call	AppendPointsToInkBlock		;es<- segment locked
						;ink block
						;bx <- handle ink block
	pushf	
	clr	ds:[inkHandle]
	clr	ds:[inkNumStrokes]
	call	PointBufferGetCount
	call	PointBufferDelete		;Delete the data from the 
						; buffer.
	popf
	jc	sendMessage			;If error, branch to pass bp=0

;	Init InkHeader<>

	mov	ax, 1
	call	MemInitRefCount			; Init ref count to one,
						; for usage of sending out
						; MSG_META_NOTIFY_WITH_DATA_BLOCK
						; (recipient must dec count)

EC <	tst	es:[IH_count]						>
EC <	ERROR_Z	NUM_INK_POINTS_IS_ZERO					>
	mov	ax, ds:[inkUpperLeftBounds].P_x
	mov	es:[IH_bounds].R_left, ax
	mov	ax, ds:[inkUpperLeftBounds].P_y
	mov	es:[IH_bounds].R_top, ax
	mov	ax, ds:[inkLowerRightBounds].P_x
	mov	es:[IH_bounds].R_right, ax
	mov	ax, ds:[inkLowerRightBounds].P_y
	mov	es:[IH_bounds].R_bottom, ax
	
	call	MemUnlock			;Unlock the data block
sendMessage:

	push	bp
	call	EraseInk		;Erase the ink...
	pop	bp

;	Pass the MSG_META_NOTIFY_WITH_DATA_BLOCK to the output...

	mov	di, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK
	mov	al, mask MF_DATA
	ret
SendInk	endp

if INK_DIGITIZER_COORDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInkCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the ink digitizer coords notification off to the UI
		and then switches to the ICS_JUST_SEND_INK state to send 
		the ink screen points notification.

CALLED BY:	(INTERNAL) InkInputMonitor, CollectAndDrawAfterStartSelect
PASS:		ds - kdata
RETURN:		di - MSG_META_NOTIFY_WITH_DATA_BLOCK to send to output
		bp - data to send with MSG_META_NOTIFY_WITH_DATA_BLOCK
		al - mask MF_DATA or mask MF_MORE_TO_DO
DESTROYED:	ah, bx

SIDE EFFECTS:	
	inkStatus changed to ICS_JUST_SEND_INK.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInkCoords	proc	near
	mov	ds:[inkStatus], ICS_JUST_SEND_INK

	clr	bp
	xchg	bp, ds:[inkCoordsBlockHan]
	tst	bp
	jz	sendNotification

	mov	bx, bp
	mov	ax, 1
	call	MemInitRefCount		; Init ref count to one,
					; for usage of sending out
					; MSG_META_NOTIFY_WITH_DATA_BLOCK
					; (recipient must dec count)

;	Pass the MSG_META_NOTIFY_WITH_DATA_BLOCK to the output...

sendNotification:
	mov	di, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK_DIGITIZER_COORDS
	mov	al, mask MF_DATA or mask MF_MORE_TO_DO

	ret
SendInkCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInkAndThenSendCachedStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the ink screen points notification off to the UI and
		then switches to the ICS_SEND_CACHED_START_SELECT state to 
		send the cached start select.

CALLED BY:	(INTERNAL) InkInputMonitor
PASS:		ds - kdata
RETURN:		di - MSG_META_NOTIFY_WITH_DATA_BLOCK to send to output
		bp - data to send with MSG_META_NOTIFY_WITH_DATA_BLOCK
		al - mask MF_DATA or mask MF_MORE_TO_DO
DESTROYED:	es, ah, bx

SIDE EFFECTS:	
	inkStatus changed to ICS_SEND_CACHED_START_SELECT

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInkAndThenSendCachedStartSelect	proc	near
	;
	; Send off the screen points notification.
	;
	call	SendInk

	;
	; Switch to the ICS_SEND_CACHED_START_SELECT state to send 
	; the cached start select.
	;
	ornf	al, mask MF_MORE_TO_DO
	mov	ds:[inkStatus], ICS_SEND_CACHED_START_SELECT

	ret
SendInkAndThenSendCachedStartSelect	endp

endif ; INK_DIGITIZER_COORDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipUntilStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This monitor routine skips all ptr events until a START_SELECT
		is encountered.

CALLED BY:	GLOBAL
PASS:		same as an InputMonitor routine
		if MSG_META_MOUSE_BUTTON or MSG_META_MOUSE_PTR
			cx,dx - ptr position
			bp - ButtonInfo
		if MSG_IM_READ_DIGITIZER_COORDS
			bp = ReadDigitizerCoordsFlags
			If RDCF_STROKE_DROPPED is clear:
			    cx = number of coordinates to read (may be zero)
		ds - kdata
RETURN:		same as an InputMonitor routine
DESTROYED:	bx?
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipUntilStartSelect	proc	near
if INK_DIGITIZER_COORDS
	cmp	di, MSG_IM_READ_DIGITIZER_COORDS
	je	eatCoords
endif
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	exit
	test	bp, mask BI_B0_DOWN	;First, make sure button 0 is down
	jz	exit			;Exit if not.

					;If any other mouse buttons down,
					; exit (isn't a START_SELECT)
	test	bp, mask BI_B1_DOWN or mask BI_B2_DOWN or mask BI_B3_DOWN
	jnz	exit

	; tell the mouse driver to not combine events (so that we don't
	; lose any)

	push	cx
	mov	cl, MCM_NO_COMBINE
	call	SetMouseCombineMode
	pop	cx

	test	bp, mask BI_BUTTON	;Now, check if it had changed from last
	jnz	exit			; time. Exit if not (this was not a
					; start select)
EC <	tst	cx							>
EC <	ERROR_S	PTR_EVENT_WITH_NEGATIVE_COORDINATE			>
EC <	tst	dx							>
EC <	ERROR_S	PTR_EVENT_WITH_NEGATIVE_COORDINATE			>

	call	PointBufferAppend
	jc	isError
	mov	ds:[inkStatus], ICS_COLLECT_UNTIL_END_SELECT
exit:
	ret
isError:

;	If this is an error, put us in error mode. We eat all ptr events from
;	the start select to the end select.

	clr	bx
	xchg	bx, ds:[inkHandle]
	tst	bx
	jz	noBlock
	call	MemFree
noBlock:
	mov	ds:[inkStatus], ICS_EAT_EVENTS_UNTIL_END_SELECT
	and	al, not mask MF_DATA
	jmp	exit

if INK_DIGITIZER_COORDS
eatCoords:
;	Eat the digitizer coords since we're not currently collecting ink.
	call	DigitizerCoordsEat
	clr	al		; Indicate data consumed
	jmp	exit
endif

SkipUntilStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollectUntilEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Collects data until an END_SELECT is reached.

CALLED BY:	GLOBAL
PASS:		di - event type
		if MSG_META_MOUSE_BUTTON or MSG_META_MOUSE_PTR
			cx,dx - ptr position
			bp - ButtonInfo
		if MSG_IM_READ_DIGITIZER_COORDS
			bp = ReadDigitizerCoordsFlags
			If RDCF_STROKE_DROPPED is clear:
			    cx = number of coordinates to read (may be zero)
		ds - kdata
RETURN:		same as monitor
DESTROYED:	bx?
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CollectUntilEndSelect	proc	near
	cmp	di, MSG_META_MOUSE_PTR
	je	addPoint
if INK_DIGITIZER_COORDS
	cmp	di, MSG_IM_READ_DIGITIZER_COORDS
	je	storeCoords
endif
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	exit
EC <	tst	cx							>
EC <	ERROR_S	PTR_EVENT_WITH_NEGATIVE_COORDINATE			>
EC <	tst	dx							>
EC <	ERROR_S	PTR_EVENT_WITH_NEGATIVE_COORDINATE			>
	test	bp, mask BI_B0_DOWN
	jne	addPoint
	ornf	cx, 0x8000			;If this is an END_SELECT,
						; then set high bit in coord 
						; to signify that it is the
						; end of a stroke.
	inc	ds:[inkNumStrokes]
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT
addPoint:
	call	PointBufferAppend
	jnc	noError
	call	PointBufferTerminate
noError:
	andnf	cx, 0x7fff
exit:
	ret

if INK_DIGITIZER_COORDS
storeCoords:
;	Store the digitizer coords in the notification block

	clr	al		; Indicate data consumed
	call	DigitizerCoordsStore
	; ignore any error
	jmp	exit
endif

CollectUntilEndSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCachedStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns the cached start select msg.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		di, ax, cx, dx, bp - appropriate data to return.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCachedStartSelect	proc	near
if INK_DIGITIZER_COORDS
EC <	cmp	di, MSG_IM_READ_DIGITIZER_COORDS			>
EC <	ERROR_E	INK_RECEIVED_UNEXPECTED_MSG_IM_READ_DIGITIZER_COORDS	>
endif
	mov	di, MSG_META_MOUSE_BUTTON
	mov	cx, ds:[inkPenSavedCX]
	mov	dx, ds:[inkPenSavedDX]
	mov	bp, ds:[inkPenSavedBP]
	call	LimitPtrToScreenLimits
	mov	al, mask MF_DATA
	GOTO	SkipUntilStartSelect
SendCachedStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawInkLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine draws a line from the old "inkCurPoint" to the
		point passed in.

CALLED BY:	GLOBAL
PASS:		cx, dx - new point to draw to
		ds - kdata
		inkCurPoint - old point to draw from
RETURN:		inkCurPoint - updated to point to this
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Setting the bounds of the ink was changed to include the width
	of the ink.  This has the advantage of allowing anyone who
	uses the ink, to use the bounds of the ink to invalidate the
	ink.  However, it has the disadvantage of having the bound be
	slightly larger then the actual ink.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version
	IP	05/04/94	modified to handle ink width

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawInkLine	proc	near		uses	ax, bx, cx, dx, di, si
	.enter
	
EC <	call	AssertDSKdata						>

	shl	cx			;Sign-extend the 15-bit value in CX
	sar	cx			; to be 16 bits

;	Update the bounds of the ink
; 	add ink width/2 + 1 and height/2 + 1 to ink bounds
;
	mov	ax, ds:[inkBrushSize]
	clr	bx
	mov	bl, ah
	shr	bx, 1
	inc	bx

	clr	ah
	shr	ax, 1
	inc	ax


	cmp	ds:[inkUpperLeftBounds].P_x, 0x7fff
	je	doSet

	sub	cx, bx
	cmp	cx, ds:[inkUpperLeftBounds].P_x
	jg	3$
	mov	ds:[inkUpperLeftBounds].P_x, cx
3$:
	sub	dx, ax
	cmp	dx, ds:[inkUpperLeftBounds].P_y
	jg	5$
	mov	ds:[inkUpperLeftBounds].P_y, dx
5$:
	shl	bx, 1
	add	cx, bx
	cmp	cx, ds:[inkLowerRightBounds].P_x
	jl	7$
	mov	ds:[inkLowerRightBounds].P_x, cx
7$:
	shl	ax, 1
	add	dx, ax
	cmp	dx, ds:[inkLowerRightBounds].P_y
	jl	20$
	mov	ds:[inkLowerRightBounds].P_y, dx

20$:
	shr	bx, 1
	sub	cx, bx
	shr	ax, 1
	sub	dx, ax

;	Update the inkCurPoint and inkOldPoint variables

	mov	ax, ds:[inkCurPoint].P_x
	mov	ds:[inkOldPoint].P_x, ax
	mov	ax, ds:[inkCurPoint].P_y
	mov	ds:[inkOldPoint].P_y, ax
	mov	ds:[inkCurPoint].P_x, cx
	mov	ds:[inkCurPoint].P_y, dx

;	Draw this line segment

	push	ds, bp
	mov	si, offset inkOldPoint	;
	mov	ax, ds:[inkBrushSize]	;AX <- width/height of brush
	mov	bx, ds:[lockedInkWin]
	call	MemDerefES		;ES <- locked window	
	push	ds
	mov	bx, ds:[lockedInkGState] ;DS <- locked gstate
	call	MemDerefDS
	pop	bx			;BX:SI <- array of points

	mov	di, DR_VID_POLYLINE
	call	es:[W_driverStrategy]	;Call video driver
	pop	ds, bp

	.leave
	ret
doSet:
	;
	; add ink width and height to ink bounds
	;
	mov	ds:[inkUpperLeftBounds].P_x, cx
	sub	ds:[inkUpperLeftBounds].P_x, bx
	mov	ds:[inkUpperLeftBounds].P_y, dx
	sub	ds:[inkUpperLeftBounds].P_y, ax
	mov	ds:[inkLowerRightBounds].P_x, cx
	add	ds:[inkLowerRightBounds].P_x, bx
	mov	ds:[inkLowerRightBounds].P_y, dx
	add	ds:[inkLowerRightBounds].P_y, ax

	jmp	20$
DrawInkLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartTimeoutTimerAndWaitForStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine starts the timeout timer and goes to the
		COLLECT_AND_DRAW_AFTER_START_SELECT state

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		inkTimer* variables set
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartTimeoutTimerAndWaitForStartSelect	proc near uses	ax, cx, dx
	class	IMClass
	.enter
EC <	call	AssertDSKdata						>
	mov	ds:[inkStatus], ICS_COLLECT_AND_DRAW_AFTER_START_SELECT
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[imThread]
	mov	cx, ds:[penTimeout]
	mov	dx, MSG_IM_INK_TIMEOUT
	call	TimerStart
	mov	ds:[inkTimerHan], bx
	mov	ds:[inkTimerID], ax
	.leave
	ret
StartTimeoutTimerAndWaitForStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWidthAndHeightAdjustment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width and height to subtract from the current
		position to center the brush drawing on the pen.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		ah - width, al - height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWidthAndHeightAdjustment	proc	near
	.enter
EC <	call	AssertDSKdata						>
	mov	ax, ds:[inkBrushSize]		; ah = width, al = height
	sub	ax, 101h			; round down
	shr	ah, 1				; 
	shr	al, 1				; 
	.leave
	ret
GetWidthAndHeightAdjustment	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollectAndDrawUntilEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Collect points as they come in and draw them.

CALLED BY:	GLOBAL
PASS:		same as InputMonitor Routine
		if MSG_META_MOUSE_BUTTON or MSG_META_MOUSE_PTR
			cx,dx - ptr position
			bp - ButtonInfo
		if MSG_IM_READ_DIGITIZER_COORDS
			bp = ReadDigitizerCoordsFlags
			If RDCF_STROKE_DROPPED is clear:
			    cx = number of coordinates to read (may be zero)
RETURN:		nada
DESTROYED:	bx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CollectAndDrawUntilEndSelect	proc	near
	cmp	di, MSG_META_MOUSE_BUTTON
	je	noIgnore
if INK_DIGITIZER_COORDS
	cmp	di, MSG_IM_READ_DIGITIZER_COORDS
	je	storeCoords
endif
	cmp	di, MSG_META_MOUSE_PTR
	jne	exit
noIgnore:

	push	ax
	call	GetWidthAndHeightAdjustment	;AH = width, al = height
	sub	cl, ah
	sbb	ch, 0
	sub	dl, al
	sbb	dh, 0
	pop	ax

	call	DrawInkLine

EC <	test	ch, 0xc0						>
EC <	ERROR_PO	COORDINATE_VALUE_OVERFLOW			>
	andnf	cx, 0x7fff			;Convert 16-bit signed x coord
						; to 15 bit signed x coord
	cmp	di, MSG_META_MOUSE_PTR
	je	addPoint
	test	bp, mask BI_B0_DOWN
	jnz	addPoint		;Branch if was not end select
	ornf	cx, 0x8000
	inc	ds:[inkNumStrokes]
addPoint:

	call	PointBufferAppend
	jc	isError

	tst	cx
	js	wasEndSelect
exit:
	ret

wasEndSelect:
;	This is an END_SELECT, so terminate the current segment, start a
;	timeout timer, and move into "wait until the next start select and
;	then continue collecting ink" mode.

	call	CheckIfGesture
	jc	sendClear

	call	StartTimeoutTimerAndWaitForStartSelect
	jmp	exit

isError:
	call	PointBufferTerminate
	mov	ds:[inkStatus], ICS_SEND_INK_ON_END_SELECT
	tst	cx			;We've run out of memory. Send the ink
	jns	exit			; off at the next end select.

;	All the ink was recognized as a gesture and therefore
;   	deleted... However, we still need to send a message to the
;	flow object so that is will stop processing ink.

sendClear:
	ornf	al, mask MF_MORE_TO_DO
	mov	ds:[inkStatus], ICS_SEND_CLEAR
	jmp	exit

if INK_DIGITIZER_COORDS
storeCoords:
;	Store the digitizer coords in the notification block

	clr	al		; Indicate data consumed
	call	DigitizerCoordsStore
	jc	stopCollecting	; store failed so stop collecting and
				;  drawing ink

	; Check if digitizer coords circular buffer is full 
	test	bp, mask RDCF_STROKE_TRUNCATED or mask RDCF_STROKE_DROPPED
	jz	exit		; not full, so continue collecting

stopCollecting:
	mov	ds:[inkStatus], ICS_SEND_INK_ON_END_SELECT
	jmp	exit
endif ; INK_DIGITIZER_COORDS

CollectAndDrawUntilEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current data is a gesture.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		carry set if gesture
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/18/93   	Initial version
	lester	12/16/96  	Fixed bug where PointBufferGetNumStrokes
				was being called with # points just deleted 
				not the # points left after the delete.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfGesture	proc	near
	.enter
	tst_clc	ds:[inkGestureCallback].high
	jz	noCallback		;Exit with carry clear if no gesture
					; callback.

;	Move all of the points from the local buffer to the global buffer

	push	ax, bx, cx, dx, bp, di, si, es
	clr	di			;Force a bunch of stack to be free
	call	ThreadBorrowStackSpace
	push	di

	call	AppendPointsToInkBlock
	cmc
	jnc	popExit			;Exit no-gesture if couldn't copy
					; points to buffer.

	clr	ds:[inkHandle]
	call	PointBufferGetCount
	call	PointBufferDelete
	mov	ds:[inkHandle], bx

	mov	ax, offset IH_data
	pushdw	esax			;These args are popped by the callback
	push	es:[IH_count]		; routine
	mov	ax, ds:[inkNumStrokes]
	cmp	ax, 1
	je	10$
	tst	ds:[haveCalledGestureCallback]
	jnz	10$
	ornf	ax, mask GCF_FIRST_CALL
10$:
	push	ax

	movdw	bxax, ds:[inkGestureCallback]
	call	ProcCallFixedOrMovable
	mov	ds:[haveCalledGestureCallback], TRUE
	tst_clc	ax
	jnz	deleteGestures		; delete found gestures
unlock:	
	mov	bx, ds:[inkHandle]
	call	MemUnlock
popExit:
	;
	; we've likely just unlocked the ES block above, and we'll be pop'ing
	; ES from the stack anyway so let's defeat the damn EC segment
	; checking
	;
EC <	mov	di, NULL_SEGMENT					>
EC <	mov	es, di							>
	pop	di
	call	ThreadReturnStackSpace
	pop	ax, bx, cx, dx, bp, di, si, es
noCallback:
	.leave
	ret

deleteGestures:
	; ax = # points recognized as a gesture by the gesture callback
	cmp	ax, es:[IH_count]
	jne	cont
	push	ax, dx, es
	call	EraseInk
	pop	ax, dx, es
cont:
if INK_DIGITIZER_COORDS
if ERROR_CHECK
	; This code expects that the points recognized as a gesture 
	; by the gesture callback will always be a full stroke or 
	; multiple full strokes.
	push	di
	mov	di, ax
	Assert	ne	di, 0
	dec	di
	CheckHack <size Point eq 4>
	shl	di
	shl	di
	test	es:[di].IH_data.P_x, mask IXC_TERMINATE_STROKE
	WARNING_Z	WARNING_INK_GESTURE_NOT_FULL_STROKE
	pop	di
endif ; ERROR_CHECK
	;
	; Delete the digitizer coords that correspond to the 
	; screen coords recognized as a gesture.
	;
	; Note that there is not a one-to-one correspondence between the 
	; screen points and the digitizer coords so we need to delete the
	; digitizer coords based on the number of strokes recognized as a 
	; gesture.
	;
	mov	cx, ax
	call	PointBufferGetNumStrokes ; dx <- # strokes recognized as gesture
	call	DigitizerCoordsDeleteStrokes
endif ; INK_DIGITIZER_COORDS
	mov	cx, ax
	call	PointBufferDelete	; delete all the points
					; recognized as a gesture

	mov	cx, es:[IH_count]	; cx <- # points left after delete
	call	PointBufferGetNumStrokes
	mov	ds:[inkNumStrokes], dx
	tst_clc	dx
	jnz 	unlock		;It was not all gestures
	stc			
	jmp	popExit		;It was all gestures so inkHandle is null

CheckIfGesture	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferGetNumStrokes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes through the list of points in the global buffer
		and returns the number of strokes

CALLED BY:	CheckIfGesture
PASS:		cx -  num of points
		ds	idata
RETURN:		dx -  num of strokes
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	for all points in the global buffer
		if x coord has high bit set (indicates end of stroke)
			increment count of strokes

	return count of strokes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferGetNumStrokes	proc	near
	uses	 di, ax, cx, es
	.enter
	clr	dx
	mov	bx, ds:[inkHandle];
	tst	bx
	jz 	exit
	call	MemLock
	jc	exit
	mov	es, ax
	mov	di, offset IH_data
	sub	di, size Point

	jcxz	done
loopPoints:
	add	di, size Point
	test 	es:[di], mask IXC_TERMINATE_STROKE
	loopz	loopPoints
	inc	dx
	jcxz	done
	jmp	loopPoints

done:
	call	MemUnlock
exit:
	.leave
	ret
PointBufferGetNumStrokes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPointInVisibleRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed point is in the visible region of the
		window associated with the passed gstate.

CALLED BY:	GLOBAL
PASS:		ds - kdata
		cx, dx - point to test
RETURN:		carry set if point is in the region.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPointInVisibleRegion	proc	near		uses	ax, bx, ds, si
	.enter
	mov	bx, ds:[lockedInkWin]
	call	MemDerefDS
	mov	si, ds:[W_visReg]
	mov	si, ds:[si]		;DS:SI <- visible region
	call	GrTestPointInReg
	.leave
	ret
CheckIfPointInVisibleRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollectAndDrawAfterStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine waits for a START_SELECT to come in. If one does,
		it kills the timeout timer, stores the point, draws it, 
		and goes to the COLLECT_AND_DRAW_UNTIL_END_SELECT.

CALLED BY:	GLOBAL
PASS:		same as InputMonitor Routine
		if MSG_META_MOUSE_BUTTON or MSG_META_MOUSE_PTR
			cx,dx - ptr position
			bp - ButtonInfo
RETURN:		nada
DESTROYED:	ax, bx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CollectAndDrawAfterStartSelect	proc	near
if INK_DIGITIZER_COORDS
EC <	cmp	di, MSG_IM_READ_DIGITIZER_COORDS			>
EC <	ERROR_E	INK_RECEIVED_UNEXPECTED_MSG_IM_READ_DIGITIZER_COORDS	>
endif
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	exit
	test	bp, mask BI_B0_DOWN	;If the button isn't down, branch
	jz	exit

;	The user just continued drawing ink before the timeout period.
;	Stop the timeout timer.

	clr	bx
	xchg	bx, ds:[inkTimerHan]
	clr	ax
	xchg	ax, ds:[inkTimerID]
	call	TimerStop

;	If we are drawing through an app-supplied gstate, then any clicks
;	outside of the associated window should terminate the ink.

	mov	di, ds:[lockedInkGState]
	cmp	di, ds:[inkDefaultGState]
	je	continue
	call	CheckIfPointInVisibleRegion
	jnc    	pointOutsideRegion
continue:

;	Save the point and draw it.

	mov	ds:[inkStatus], ICS_SEND_INK_ON_END_SELECT
	

	call	GetWidthAndHeightAdjustment
	sub	cl, ah
	sbb	ch, 0
	sub	dl, al
	sbb	dh, 0
	andnf	cx, 0x7fff			;Turn into a 15-bit signed 
						; value
	call	PointBufferAppend		;
	jc	exit				;
	mov	ds:[inkStatus], ICS_COLLECT_AND_DRAW_UNTIL_END_SELECT

	mov	ds:[inkCurPoint].P_x, cx	;Draw a point at this coord.
	mov	ds:[inkCurPoint].P_y, dx
	call	DrawInkLine	       ;
exit:
	ret

pointOutsideRegion:
if INK_DIGITIZER_COORDS
	;
	; Send off the ink digitizer coordinates notification and then 
	; switch to the ICS_SEND_INK_AND_THEN_SEND_CACHED_START_SELECT
	; state to send off the ink screen points notification and then
	; send the cached start select.
	;
	call	SendInkCoords
	Assert	bitSet	al, MF_MORE_TO_DO
	mov	ds:[inkStatus], ICS_SEND_INK_AND_THEN_SEND_CACHED_START_SELECT
else
	call	SendInk
	ornf	al, mask MF_MORE_TO_DO
	mov	ds:[inkStatus], ICS_SEND_CACHED_START_SELECT
endif ; INK_DIGITIZER_COORDS
	jmp	exit
	
CollectAndDrawAfterStartSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EatEventsUntilEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine eats all events until the next "end select".

CALLED BY:	GLOBAL
PASS:		ds - kdata
		if MSG_IM_READ_DIGITIZER_COORDS
			bp = ReadDigitizerCoordsFlags
			If RDCF_STROKE_DROPPED is clear:
			    cx = number of coordinates to read (may be zero)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EatEventsUntilEndSelect	proc	near
	cmp	di, MSG_META_MOUSE_PTR		;Eat all ptr events
	je	eat
	cmp	di, MSG_META_MOUSE_DRAG		;Eat all drag events
	je	eat
if INK_DIGITIZER_COORDS
	cmp	di, MSG_IM_READ_DIGITIZER_COORDS
	je	eatCoords
endif
	cmp	di, MSG_META_MOUSE_BUTTON	;Eat all button events until
	jne	exit				; button 0 goes up
	test	bp, mask BI_B0_DOWN	
	jnz	eat
	mov	ds:[inkStatus], ICS_SKIP_UNTIL_START_SELECT
eat:
	clr	al	; Indicate data consumed
exit:
	ret

if INK_DIGITIZER_COORDS
eatCoords:
;	Eat the digitizer coords since we're not currently collecting ink.
	call	DigitizerCoordsEat
	jmp	eat
endif ; INK_DIGITIZER_COORDS

EatEventsUntilEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInkOnEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine waits until an end select happens, then sends
		the ink off.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInkOnEndSelect	proc	near
if INK_DIGITIZER_COORDS
	cmp	di, MSG_IM_READ_DIGITIZER_COORDS
	je	storeCoords
endif
	cmp	di, MSG_META_MOUSE_BUTTON
	jne	exit
	test	bp, mask BI_B0_DOWN	;Wait until button 0 goes back up
	jne	exit			; (an END_SELECT).
	ornf	al, mask MF_MORE_TO_DO
if INK_DIGITIZER_COORDS
	mov	ds:[inkStatus], ICS_SEND_INK_COORDS
else
	mov	ds:[inkStatus], ICS_JUST_SEND_INK
endif
exit:
	ret

if INK_DIGITIZER_COORDS
storeCoords:
;	We're in this state because either the screen points block is full
;	or the digitizer coords block is full. It would be nice to only
;	store the digitizer coordinates that correspond to screen points
;	that we have collected but we don't know what digitizer correspond
;	to what screen points, so we'll just store all the digitizer
;	coordinates we can and ignore any error. 

	call	DigitizerCoordsStore
	; ignore any error
	clr	al		; Indicate data consumed
	jmp	exit
endif ; INK_DIGITIZER_COORDS

SendInkOnEndSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the point buffer so it is ready to get data.

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferInit	proc	near	uses	ax, es
	.enter
EC <	call	AssertDSKdata						>
	mov	es, ds:[inkData]
	clr	es:[CBS_count]
	clr	ds:[inkNumStrokes]
EC <	mov	es:[CBS_start], -1					>
EC <	mov	es:[CBS_last], -1					>
	.leave
	ret
PointBufferInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends a point to the point buffer.

CALLED BY:	GLOBAL
PASS:		cx, dx - point to append
		ds - idata
RETURN:		carry set if points could not fit
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferAppend	proc	near	uses	ax, di, es
	.enter

EC <	call	AssertDSKdata						>

;	Check if too many points, or no points yet

	mov	es, ds:[inkData]
	cmp	es:[CBS_count], MAX_INK_POINTS
	je	bufferFull
EC <	ERROR_A	TOO_MANY_INK_POINTS					>
	tst	es:[CBS_count]
	jz	noPoints

;	Point to the next place to blast points.

	mov	di, es:[CBS_last]

	add	di, size Point
	cmp	di, INK_DATA_BUFFER_SIZE
	je	doWrap
EC <	ERROR_A	INK_DATA_EXCEEDED_BOUNDS_OF_BUFFER			>
doStoreAndInc:
	mov	es:[CBS_last], di
	inc	es:[CBS_count]

	mov	es:[di].P_x, cx
	mov	es:[di].P_y, dx
	clc
exit:
	.leave
	ret


doWrap:
	mov	di, offset CBS_data
	jmp	doStoreAndInc

bufferFull:

;	Our local buffer is full, so append the points to the global block

	push	es
	push	cx, dx, bp
	call	AppendPointsToInkBlock
	pop	cx, dx, bp
	jc	popESExit		;If we couldn't alloc the global 
					; block, branch to exit

	cmp	es:[IH_count], TOTAL_MAX_INK_POINTS
	pop	es
	call	MemUnlock		;Unlock the block
	mov	es:[CBS_count], 0
	jae	tooManyPoints		;If we already have a huge # of
					; pts in the buffer, branch to stop
					; storing any.
noPoints:
	mov	di, offset CBS_data
	mov	es:[CBS_start], di
	jmp	doStoreAndInc

tooManyPoints:
	stc
	jmp	exit
popESExit:
	pop	es
	jmp	exit
	
PointBufferAppend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns the # points in the point buffer
		(the circular buffer)

CALLED BY:	GLOBAL
PASS:		ds - idata
RETURN:		cx - # points
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferGetCount	proc	near	uses	es
	.enter
EC <	call	AssertDSKdata						>
	mov	es, ds:[inkData]
	mov	cx, es:[CBS_count]
	.leave
	ret
PointBufferGetCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine deletes the first cx points from the
		point buffer if inkHandle is not 0 then from inkHandle
		buffer, otherwise from the inkdata buffer and then any
		leftovers from the inkHandle buffer.
		Shifting the remaining points to the beginning of the
		buffer 	

CALLED BY:	GLOBAL
PASS:		cx - # points to delete
		ds - idata
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferDelete	proc	near	uses	es, bx, cx
	.enter
EC <	call	AssertDSKdata						>
	tst	cx
	LONG jz	exit
	tst	ds:[inkHandle]
	jz	noGlobalBuffer
	mov	bx, ds:[inkHandle]
	call	MemLock
	mov	es, ax
	cmp	cx, es:[IH_count]
	jae	freeBlock

	sub	es:[IH_count], cx

;
;	Move the points from the end of the point buffer to the current point.
;

	push	ds, si, di, cx
	segmov	ds, es					
	mov	si, cx
	shl	si, 1
	shl	si, 1
	mov	di, offset IH_data	;ES:DI <- ptr to place for first point
	add	si, di			;DS:SI <- ptr to new first point (after
					; delete)
	mov	cx, es:[IH_count]
	shl	cx, 1			;CX <- size of points (in words)
EC <	call	ECCheckBounds						>
	rep	movsw
EC <	dec	si							>
EC <	call	ECCheckBounds						>
	pop	ds, si, di, cx
	call	MemUnlock
	jmp	exit
freeBlock:
	sub	cx, es:[IH_count]			;CX <- # points left to
							; delete
	clr	ds:[inkHandle]
	call	MemFree
       	jcxz	exit
noGlobalBuffer:
	mov	es, ds:[inkData]
	cmp	cx, es:[CBS_count]
	je	justClearCount
EC <	ERROR_A	CANNOT_DELETE_MORE_POINTS_THAN_EXIST			>
	push	cx
	shl	cx, 1		;CX <- size of a Point
	shl	cx, 1
	add	es:[CBS_start], cx
	cmp	es:[CBS_start], INK_DATA_BUFFER_SIZE
	jb	10$
	sub	es:[CBS_start], (INK_DATA_BUFFER_SIZE - size CircularBufferStruct)
10$:
	pop	cx
justClearCount:
	sub	es:[CBS_count], cx
exit:
	.leave
	ret
PointBufferDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine calls the passed callback routine with each
		point in the buffer.

CALLED BY:	GLOBAL
PASS:		ds - idata
		cx:dx - vfptr to routine to call
		AX, BX, BP,ES - data for routine

		Callback routine gets passed:

		CX, DX - Point values
		AX,BX,BP,ES - data passed in to PointBufferEnum
				(possibly modified by previous callback
				 routines)

		Callback routine returns:

		AX,BX,BP - modified if desired
		carry set if we want to stop the enumeration

		Can destroy: cx, dx

RETURN:		AX, BX, BP, ES - data returned.
		carry set if enumeration was aborted
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PointBufferEnum	proc	near	uses	ds, di, si
	.enter
EC <	call	AssertDSKdata						>
	pushdw	cxdx
	mov	si, sp

	tst	ds:[inkHandle]
	jz	afterOverflow

;
;	Some of the collected points have been moved to a global block. 
;	Process them first.
;
	push	ds
	push	bx, ax
	mov	bx, ds:[inkHandle]
	call	MemLock
	mov	ds, ax
	pop	bx, ax

	push	ds:[IH_count]
	mov	di, offset IH_data
	;Carry should always be clear from MemLock above
EC <	ERROR_C	-1							>
nextPoint:
	dec	ds:[IH_count]
	js	unlock

	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	add	di, size Point
	;  We need to call the callback with ProcCallFixedOrMovable,
	;  since we can be XIP'ed.
	;				-- todd
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, ss:[si]
	call	ProcCallFixedOrMovable
	jnc	nextPoint

unlock:
	pop	ds:[IH_count]

	pop	ds
	push	bx
	mov	bx, ds:[inkHandle]
	call	MemUnlock
	pop	bx
	jc	exit

afterOverflow:
	mov	ds, ds:[inkData]
	tst	ds:[CBS_count]
	je	exit

;	Set up a call vector on the stack

	mov	di, ds:[CBS_start]
loopTop:

;
;	Loop variables:
;	ES:DI - ptr to next point to pass to callback routine
;	ES:0 - CircularBufferStruct
;	SS:SI - ptr to callback routine
;
	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y

	;  We need to call the callback with ProcCallFixedOrMovable,
	;  since we can be XIP'ed.
	;				-- todd
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, ss:[si]
	call	ProcCallFixedOrMovable
	jc	exit

	cmp	di, ds:[CBS_last]
	je	exit			;This clears the carry
	add	di, size Point
	cmp	di, INK_DATA_BUFFER_SIZE
EC <	ERROR_A	INK_ENUM_EXCEEDED_END_OF_BUFFER				>
   	jne	loopTop
	mov	di, offset CBS_data
	jmp	loopTop
exit:
	popdw	cxdx
	.leave
	ret


PointBufferEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferTerminate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine terminates the most-recently-appended point. This
		is only called if there was an error. If so, we terminate the
		ink data that has been stored in the global block. 

CALLED BY:	GLOBAL
PASS:		ds - kdata
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/27/91	Initial version
	lester	12/15/96  	Fixed to terminate the last point in the 
				global block not the point after the last one.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferTerminate	proc	near	uses	es, di, bx
	.enter

;	Change this to terminate the ink buffer.

	mov	bx, ds:[inkHandle]
	tst	bx
	jz	noGlobalBlock

	push	ax
	call	MemLock
	mov	es, ax
	mov	di, es:[IH_count]
	Assert	ne	di, 0
	dec	di
	shl	di, 1
	shl	di, 1
	ornf	es:[di].IH_data.P_x, 0x8000
	call	MemUnlock
	pop	ax
exit:
	.leave		
	ret

noGlobalBlock:
	mov	es, ds:[inkData]
	tst	es:[CBS_count]
	jz	exit
	mov	di, es:[CBS_last]
	ornf	es:[di].P_x, 0x8000
	jmp	exit

PointBufferTerminate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointBufferModify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the points in the buffer

CALLED BY:	INTERNAL
		InkReplyHandler
PASS:		ds - idata
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine centers each of the data points around the 
		digitized point, by subtracting half of the Brush size from
		each point, in both X and Y.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointBufferModify	proc	near
		uses	ax, bx, cx, dx, di, ds
		.enter

EC <		call	AssertDSKdata					>

		; Some of the collected points have been moved to a global 
		; block.  Process them first.

		call	GetWidthAndHeightAdjustment
		tst	ax			; if nothing to do, exit
		LONG jz	exit			

		mov	dl, ah			; setup ax and dx as mod
		clr	ah, dh			;  values.
		xchg	dx, ax			; ax = width, dx = height

		tst	ds:[inkHandle]		; see if there is an extra
		jz	afterOverflow		;  data block

		; lock the block and modify those values first.

		push	ds
		push	bx, ax
		mov	bx, ds:[inkHandle] 
		call	MemLock
		mov	ds, ax
		pop	bx, ax

		mov	cx, ds:[IH_count]
		jcxz	unlock
		mov	di, offset IH_data	; ds:di -> Points
nextPoint:
		call	modifyPoint

		add	di, size Point
		jc	unlock			; shouldn't wrap around
		loop	nextPoint

		; done modifying the block, unlock it.
unlock:
		pop	ds			; restore ds -> kdata

		push	bx			; release the block
		mov	bx, ds:[inkHandle]
		call	MemUnlock
		pop	bx
		jc	exit			; bail on strange errors

		; done with block, so do the circular buffer.
afterOverflow:
		mov	ds, ds:[inkData]	; ds -> circular buffer
		tst	ds:[CBS_count]		; if no points there, done
		jz	exit
		mov	di, ds:[CBS_start]	; start at beginning  :-)
loopTop:
		call	modifyPoint
		cmp	di, ds:[CBS_last]	; if done, bail.
		je	exit
		add	di, size Point
		cmp	di, INK_DATA_BUFFER_SIZE ; if last, wrap around
	   	jne	loopTop
		mov	di, offset CBS_data
		jmp	loopTop
exit:
		.leave
		ret
modifyPoint:
	;
	;	DS:DI - ptr to Point structure
	;	AX - value to modify X coord
	;		(high bit is end-of-stroke flag)
	;	DX - value to modify Y coord
	;
		sub	ds:[di].P_y, dx

;	Convert the 15-bit signed value in AX (the high bit is set if the
;	point ends a stroke) to a 16-bit signed value, perform the
;	modification, and restore the end-of-stroke flag.

		shl	ds:[di].P_x		;CARRY <- end of stro
		pushf
		sar	ds:[di].P_x		;Sign extend X coord	
		sub	ds:[di].P_x, ax
EC <		test	ds:[di].P_x.high, 0xc0				>
EC <		ERROR_PO	COORDINATE_VALUE_OVERFLOW		>

;	Set the high bit (end of stroke flag) appropriately

   		shl	ds:[di].P_x		;
		popf
		rcr	ds:[di].P_x
		retn
PointBufferModify	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImSetMouseBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the mouse driver to start storing digitizer
		coordinates in the digitizer coords circular buffer 
		if it exists.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if mouse driver does not support storing
		digitizer coordinates
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImSetMouseBuffer	proc	far

if INK_DIGITIZER_COORDS
	uses	cx,di,ds
	.enter

	;
	; Tell the mouse driver to start storing digitizer coordinates 
	; in the circular buffer.
	;
	LoadVarSeg	ds, cx
	mov	cx, ds:[inkCoordsBuffer]	; cx - buffer segment
	tst_clc	cx
	jz	exit				; no buffer, exit w/carry clear

	mov	di, DR_MOUSE_ESC_SET_MOUSE_COORD_BUFFER
	call	CallMouseStrategy
EC <	WARNING_C	WARNING_MOUSE_DR_DOES_NOT_SUPPORT_SET_BUFFER	>
	jc	error

exit:
	.leave
	ret
error:
	;
	; Error, free the buffer
	;
	push	bx
	clr	bx
	mov	ds:[inkCoordsBuffer], bx
	xchg	bx, ds:[inkCoordsBufferHan]	; bx - buffer handle
	call	MemFree
	pop	bx
	jmp	exit

else
	; Ink digitizer coords not supported
	stc
	ret

endif ; INK_DIGITIZER_COORDS
ImSetMouseBuffer	endp


if INK_DIGITIZER_COORDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateDigitizerCoordsBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the appropriate ini entry is true, allocate a circular
		buffer which we'll share with the mouse driver to store
		digitizer coordinates.

CALLED BY:	(INTERNAL) ImStartPenMode
PASS:		ds - kdata
RETURN:		carry set if couldn't allocate buffer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	It would be nice to call the mouse driver with MOUSE_ESC_SET_BUFFER
	in this routine but the mouse driver is not loaded at this point in
	time. So, we provide a global routine, ImSetMouseBuffer, that the 
	UI can call after it loads the mouse driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
inkCoordsCategory	char	"system",0
inkCoordsKey		char	"inkDigitizerCoords",0

AllocateDigitizerCoordsBuffer	proc	near
	uses	ax,bx,cx,dx,si
	.enter
	;
	; Check if ini flag is set
	;
	push	ds
	segmov	ds, cs, cx	; ds, cx <= cs
	mov	si, offset inkCoordsCategory
	mov	dx, offset inkCoordsKey
	clr	ax
	call	InitFileReadBoolean
	pop	ds
	tst_clc	ax
	jnz	allocateBuffer

exit:
	.leave
	ret

allocateBuffer:
	;
	; Allocate fixed circular buffer
	;
EC <	call	AssertDSKdata						>
	mov	bx, handle 0
	mov	cx, mask HF_FIXED
	mov	ax, size MouseCoordsCircularBufferStruct
	call	MemAllocSetOwnerFar
	jc	exit

EC <	tst_clc	ds:[inkCoordsBuffer]					>
EC <	ERROR_NZ	IM_SETUP_DIGITIZER_COORDS_BUFFER_WAS_CALLED_TWICE>

	mov	ds:[inkCoordsBuffer], ax
	mov	ds:[inkCoordsBufferHan], bx

	Assert carryClear
	jmp	exit
AllocateDigitizerCoordsBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveDigitizerCoordsBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the mouse driver to stop collecting digitizer 
		coordinates and then free the circular buffer.

CALLED BY:	(INTERNAL) ImExitPenMode
PASS:		ds - kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveDigitizerCoordsBuffer	proc	near
	uses	bx,di
	.enter
EC <	call	AssertDSKdata						>

	;
	; Tell the mouse driver to stop using the buffer
	;
	mov	di, DR_MOUSE_ESC_REMOVE_MOUSE_COORD_BUFFER
	call	CallMouseStrategy
EC <	ERROR_C	ERROR_REMOVING_DIGITIZER_COORDS_BUFFER			>

	;
	; Now, free the buffer
	;
	clr	bx
	mov	ds:[inkCoordsBuffer], bx
	xchg	bx, ds:[inkCoordsBufferHan]	; bx - buffer handle
	call	MemFree

	.leave
	ret
RemoveDigitizerCoordsBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMouseStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the mouse driver strategy

CALLED BY:	(INTERNAL) AllocateDigitizerCoordsBuffer, 
			   RemoveDigitizerCoordsBuffer
PASS:		di - MouseFunction to call
		others - arguments to pass MouseFunction
RETURN:		carry set if no mouse driver loaded
		whatever MouseFunction returns
DESTROYED:	whatever MouseFunction destroys

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMouseStrategy	proc	near
		uses	ds, si
		.enter
	;
	; save the args to the strategy call
	;
		push	ax, bx
	;
	; get the mouse handle
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
	;
	; bail if there's none
	;
		tst	ax
		jz	noMouseDriver
	;
	; get the strategy and call it
	;
		mov_tr	bx, ax
		call	GeodeInfoDriver
		pop	ax, bx
		call	ds:[si].DIS_strategy

exit:
		.leave
		ret
noMouseDriver:
		pop	ax, bx
		stc
		jmp	exit

CallMouseStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsEat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the circular buffer to indicate that we've read the
		coordinates but don't store them in the notification block.

CALLED BY:	(INTERNAL) SkipUntilStartSelect
PASS:		bp - ReadDigitizerCoordsFlags
		     If RDCF_STROKE_DROPPED is clear:
			cx = number of coordinates to read (may be zero)
		ds - kdata
		ds:[inkCoordsBuffer] - segment of fixed circular buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	The MCCBS_nextRead field of the digitizer coordinates circular
	buffer is updated to indicate the coordinates have been read.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsEat	proc	near
	uses	cx,es
	.enter
EC <	call	AssertDSKdata						>

	test	bp, mask RDCF_STROKE_DROPPED
	jnz	exit

	;
	; Calculate the new MCCBS_lastRead offset
	;	
	Assert	ne	ds:[inkCoordsBuffer], 0
	Assert	segment ds:[inkCoordsBuffer]
	mov	es, ds:[inkCoordsBuffer] ; es - segemnt of circular buffer

	Assert	be	cx, MAX_MOUSE_COORDS	; sanity check
	CheckHack <MAX_MOUSE_COORDS lt 0xc000>	; ok to shift left twice
	CheckHack <size InkPoint eq 4>
				; cx - # coords to read
if ERROR_CHECK
	; Replace the eaten coords with 0x1111 for your debugging pleasure
	; cx - # coords to eat
	push	bx, cx
	mov	bx, es:[MCCBS_nextRead]
loopTop:	
	mov	es:[bx].IP_x, 0x1111	; eat X coord
	mov	es:[bx].IP_y, 0x1111	; eat Y coord

	add	bx, size InkPoint
	cmp	bx, offset MCCBS_data + size MCCBS_data
	jb	noWrap
EC <	ERROR_A	ASSERTION_FAILED					>
	mov	bx, offset MCCBS_data	; wrap to front of circular buffer
noWrap:
	loop	loopTop		; still hungry?
	pop	bx, cx
endif ; ERROR_CHECK

	shl	cx, 1
	shl	cx, 1		; cx - # bytes to read
	add	cx, es:[MCCBS_nextRead] ; cx - new next read offset

	; wrap around end of circular buffer if necessary
	cmp	cx, offset MCCBS_data + size MCCBS_data
	jb	storeOffset
	sub	cx, size MCCBS_data ; wrap to the buffer front
storeOffset:
	; store the new MCCBS_lastRead offset
	mov	es:[MCCBS_nextRead], cx

exit:
	.leave
	ret
DigitizerCoordsEat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the digitizer coordinates from the circular buffer 
		and appends them to the notification block. Terminates the
		last digitizer coordinates if the block is full or if the 
		ReadDigitizerCoordsFlags indicate the circular buffer has 
		filled up.

CALLED BY:	(INTERNAL) CollectUntilEndSelect,
			   CollectAndDrawUntilEndSelect,
			   SendInkOnEndSelect
PASS:		bp - ReadDigitizerCoordsFlags
		     If RDCF_STROKE_DROPPED is clear:
			cx = number of coordinates to read (may be zero)
		ds - kdata
		ds:[inkCoordsBuffer] - segment of fixed circular buffer
		ds:[inkCoordsBlockHan] - handle of notification block or 0

RETURN:		carry set if error
		    if allocation failure, bx=0
		    if coords could not fit, bx=handle of notification block
			-else-
		bx = handle of notification block
DESTROYED:	nothing
SIDE EFFECTS:	
	If there is no notification block, one is created and the handle
	is stored in ds:[inkCoordsBlockHan]. Otherwise, the notification
	block is expanded to hold the new coordinates.

	If the coords could not fit in the notification block, they are 
	eaten.

	The MCCBS_nextRead field of the digitizer coordinates circular
	buffer is update to indicate the coordinates have been read.

PSEUDO CODE/STRATEGY:

KNOWN BUGS: 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsStore	proc	near
	uses	ax,cx,si,di,ds,es
	.enter

	test	bp, mask RDCF_STROKE_DROPPED
	LONG	jnz	exit

EC <	call	AssertDSKdata						>
	; sanity check on the number of coords
	Assert	be	cx, MAX_MOUSE_COORDS

	; Check if we have a notification block
	mov	bx, ds:[inkCoordsBlockHan]
	tst	bx
	LONG jz	allocateNewBlock
				; bx - handle of notification block

	; Lock the notification block
	call	MemLock
	mov	es, ax		; es - segemnt of notification block

	;
	; Check if the block is already full
	;
	mov	ax, es:[IDCH_count]	; ax - old count
	cmp	ax, TOTAL_MAX_INK_COORDS; already full?
	LONG jae blockFull
	add	ax, cx			; ax - new count

	;
	; Expand the block to hold the new coords
	;
	; ax - # coords block should hold
	; bx - handle of notification block
	push	cx, ax
	CheckHack <size InkPoint eq 4>
	shl	ax, 1				
	shl	ax, 1				; ax - # bytes for coords
	add	ax, size InkDigitizerCoordsHeader ; ax - new size of block
	clr	ch
	call	MemReAlloc
	mov_tr	es, ax		; es - segment of notification block
	pop	cx, ax		; cx - # coords to read, ax - total # of coords
	jc	reallocFailed

	;
	; Copy the coordinates into the notification block
	;
copyCoords:
	; es - segment of notification block
	; ds - kdata
	; cx - # coords to copy
	; ax - # coords block will hold after copy

	; Get segment of circular buffer
	Assert	ne	ds:[inkCoordsBuffer], 0
	Assert	segment ds:[inkCoordsBuffer]
	mov	ds, ds:[inkCoordsBuffer] ; ds - segemnt of circular buffer

	; setup for copy
	mov	si, ds:[MCCBS_nextRead]	; ds:si - ptr to source

	mov	di, es:[IDCH_count]	; di - # coords in notification block
	shl	di, 1	
	shl	di, 1			; di - # bytes of coords in block
	add	di, offset IDCH_data	; es:di - ptr to dest

	; save the new coord count
	mov_tr	es:[IDCH_count], ax

loopTop:
	; cx - # coords to copy
	; ds:si - ptr to source
	; es:di - ptr to dest
	movsw			; copy X coord
	movsw			; copy Y coord


	; Replace the read coords with a special value to indicate
	; that they have been read for your debugging pleasure
EC <	mov	ds:[si-4].IP_x, 0x4444	; replace read X coord		>
EC <	mov	ds:[si-4].IP_y, 0x4444	; replace read Y coord		>

	cmp	si, offset MCCBS_data + size MCCBS_data
	jb	noWrap
EC <	ERROR_A	ASSERTION_FAILED					>
	mov	si, offset MCCBS_data	; wrap to front of circular buffer
noWrap:
	loop	loopTop		; go back for more...

afterLoop::
	; Update MCCBS_lastRead
	mov	ds:[MCCBS_nextRead], si

	; Unlock notification block
	call	MemUnlock

	; If circular buffer is full, terminate the last digitizer coords
	test	bp, mask RDCF_STROKE_TRUNCATED or mask RDCF_STROKE_DROPPED
	jz	circularBufferNotFull
	call	DigitizerCoordsTerminate		
circularBufferNotFull:

	clc			; return success
	; bx - handle of notification block
exit:
	.leave
	ret



reallocFailed:
	; bx - handle of notification block
	clr	ds:[inkCoordsBlockHan]
	call	MemFree
allocFailed:
EC <	WARNING	WARNING_INK_DIGITIZER_COORDS_BLOCK_ALLOC_FAILED		>
	clr	bx		; indicate allocation failure
stcExit:
	stc			; return failure
	jmp	exit

blockFull:
	; bx - handle of notification block
	; cx - # coords to read
	; ds - kdata
EC <	WARNING	WARNING_INK_DIGITIZER_COORDS_BLOCK_FULL			>
	call	MemUnlock	; unlock the notification block

	; eat the coordinates since they would not fit
	call	DigitizerCoordsEat
	call	DigitizerCoordsTerminate
	jmp	stcExit

	;
	; Allocate new notification block and initialize it
	;
allocateNewBlock:
	; cx - number of coordinates to read

	push	cx
	mov_tr	ax, cx				; ax - # coords to allocate
	CheckHack <size InkPoint eq 4>
	shl	ax, 1
	shl	ax, 1				; ax - # bytes
	add	ax, size InkDigitizerCoordsHeader ; ax - size of block
	mov	bx, handle 0
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAllocSetOwnerFar ; ax - segment, bx - handle
	pop	cx
	jc	allocFailed

	mov	ds:[inkCoordsBlockHan], bx
	mov_tr	es, ax		; es - segment of notification block
	clr	es:[IDCH_count]	; initialize count
	mov	ax, cx		; ax, cx - # coords

	jmp	copyCoords
DigitizerCoordsStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsReplaceDummyCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the dummy digitizer coords that were just stored
		in the ink digitizer coords notification block with values
		based on the last X and Y screen positions.

CALLED BY:	(INTERNAL) DigitizerCoordsStore
PASS:		ds:si - ptr just after source coords
		es:di - ptr just after dest coords
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsTerminate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminates the most-recently-stored digitizer coords.

CALLED BY:	(INTERNAL) DigitizerCoordsStore
PASS:		ds - kdata
		ds:[inkCoordsBlockHan] - handle of notification block or 0
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsTerminate	proc	near
	uses	bx
	.enter
EC <	call	AssertDSKdata						>

	; Check if we have a notification block
	mov	bx, ds:[inkCoordsBlockHan]
	tst	bx
	jz	exit

	;
	; Terminate the last InkPoint
	;
	push	ax, es, di
	call	MemLock
	mov	es, ax
	mov	di, es:[IDCH_count]
	Assert	ne	di, 0
	dec	di
	shl	di, 1
	shl	di, 1		; di <- offset to last coords
	ornf	es:[di].IDCH_data.IP_x, mask IXC_TERMINATE_STROKE
	call	MemUnlock
	pop	ax, es, di

exit:
	.leave
	ret
DigitizerCoordsTerminate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the first CX digitizer coordinates from the 
		notification block and shift the remaining points to 
		the beginning of the block.

CALLED BY:	(INTERNAL) InkReplyHandler, CheckIfGesture
PASS:		cx - # coords to delete
		ds - kdata
		ds:[inkCoordsBlockHan] - handle of notification block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/26/96    	Initial version (copied from PointBufferDelete)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsDelete	proc	near
	uses	ax, bx, cx, es
	.enter
EC <	call	AssertDSKdata						>
	tst	cx
	jz	exit
	mov	bx, ds:[inkCoordsBlockHan]
	tst	bx
	jz	exit

	call	MemLock
	mov	es, ax
	cmp	cx, es:[IDCH_count]
	jae	freeBlock

	sub	es:[IDCH_count], cx

	;
	; Move the points from the end of the block to the front.
	;
	push	ds, si, di, cx
	segmov	ds, es					
	mov	si, cx
	shl	si, 1
	shl	si, 1
	mov	di, offset IDCH_data	;ES:DI <- ptr to place for first point
	add	si, di			;DS:SI <- ptr to new first point (after
					; delete)
	mov	cx, es:[IDCH_count]
	shl	cx, 1			;CX <- size of points (in words)
EC <	call	ECCheckBounds						>
	rep	movsw
EC <	dec	si							>
EC <	call	ECCheckBounds						>
	pop	ds, si, di, cx
	call	MemUnlock

exit:
	.leave
	ret

freeBlock:
	clr	ds:[inkCoordsBlockHan]
	call	MemFree
	jmp	exit
DigitizerCoordsDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine calls the passed callback routine with each
		digitizer coord in the notification block.

CALLED BY:	(INTERNAL)
PASS:		ds - idata
		cx:dx - vfptr to routine to call
		AX, BX, BP,ES - data for routine

		Callback routine gets passed:

		CX, DX - Point values
		AX,BX,BP,ES - data passed in to DigitizerCoordsEnum
				(possibly modified by previous callback
				 routines)

		Callback routine returns:

		AX,BX,BP - modified if desired
		carry set if we want to stop the enumeration

		Can destroy: cx, dx

RETURN:		AX, BX, BP, ES - data returned.
		carry set if enumeration was aborted
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Some code in the IMPenCode resource calls this routine with a fptr
	instead of a vfptr which is an optimization that is possible
	because the caller, callback, and this routine are all in the 
	IMPenCode resource which is fixed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/15/96    	Initial version (copied from PointBufferEnum)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsEnum	proc	near
	uses	ds, di, si
	.enter
EC <	call	AssertDSKdata						>
	pushdw	cxdx
	mov	si, sp

	tst	ds:[inkCoordsBlockHan]
	clc
	jz	exit

	push	ds
	push	bx, ax
	mov	bx, ds:[inkCoordsBlockHan]
	call	MemLock
	mov	ds, ax
	pop	bx, ax

	push	ds:[IDCH_count]
	mov	di, offset IDCH_data
	;Carry should always be clear from MemLock above
EC <	ERROR_C	-1							>
nextPoint:
	dec	ds:[IDCH_count]
	js	unlock

	mov	cx, ds:[di].IP_x
	mov	dx, ds:[di].IP_y
	add	di, size InkPoint

	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, ss:[si]
	call	ProcCallFixedOrMovable
	jnc	nextPoint

unlock:
	pop	ds:[IDCH_count]

	pop	ds
	push	bx
	mov	bx, ds:[inkCoordsBlockHan]
	call	MemUnlock
	pop	bx

exit:
	popdw	cxdx
	.leave
	ret
DigitizerCoordsEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DigitizerCoordsDeleteStrokes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the first DX strokes of digitizer coordinates 
		from the notification block and shift the remaining
		points to the beginning of the block.

CALLED BY:	(INTERNAL) CheckIfGesture
PASS:		dx - # strokes to delete
		ds - kdata
		ds:[inkCoordsBlockHan] - handle of notification block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DigitizerCoordsDeleteStrokes	proc	near
	uses	ax,bx,cx,dx
	.enter

	tst	dx
	jz	exit
	mov	bx, dx		; bx <- # strokes to delete

loopTop:
	clr	ax
	mov	cx, cs
	mov	dx, offset FindLengthOfSegmentCallback
	CheckHack <segment FindLengthOfSegmentCallback eq @CurSeg>
	CheckHack <segment FindLengthOfSegmentCallback eq IMPenCode>
	CheckHack <segment DigitizerCoordsEnum eq @CurSeg>
	call	DigitizerCoordsEnum
		; Returns AX = # items in first segment.

	mov_tr	cx, ax				; cx <- # coords to delete
	call	DigitizerCoordsDelete

	dec	bx
	jnz	loopTop

exit:
	.leave
	ret
DigitizerCoordsDeleteStrokes	endp

endif ; INK_DIGITIZER_COORDS

IMPenCode	ends
endif		;NO_PEN_SUPPORT
