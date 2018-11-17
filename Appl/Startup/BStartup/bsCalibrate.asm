COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bsCalibrate.asm

AUTHOR:		Steve Yegge, Jul 15, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93		Initial revision

DESCRIPTION:
	

	$Id: bsCalibrate.asm,v 1.1 97/04/04 16:53:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalibrateCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenContentKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the message sent out on any keyboard press or release.
		Subclassed to make the a keypress restart the calibration
		sequence.

CALLED BY:	MSG_VIS_SCREEN_KBD_CHAR

PASS:		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing	

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	may restart the calibration process.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenContentKbdChar	method dynamic VisScreenContentClass, 
					MSG_META_KBD_CHAR
	;
	; See if we want the event, else pass it on.
	;
		test	dl, mask CF_RELEASE
		jnz	callSuperClass		; do nothing on release
	;		
	; Restart the calibration sequence
	;
restartCalibration::
		mov	ax, MSG_VIS_SCREEN_RESTART_CALIBRATION
		GOTO	VisCallFirstChild
callSuperClass:
		mov	di, offset VisScreenContentClass
		GOTO	ObjCallSuperNoLock
VisScreenContentKbdChar	endm


;-----------------------------------------------------------------------------
;		VisScreen methods & routines
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenFlashCalibrationPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flash the current calibration point

CALLED BY:	GLOBAL (MSG_VIS_SCREEN_FLASH_CALIBRATION_POINT)

PASS:		*DS:SI	= VisScreenClass object
		DS:DI	= VisScreenClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenFlashCalibrationPoint	method dynamic	VisScreenClass,
				MSG_VIS_SCREEN_FLASH_CALIBRATION_POINT
		.enter
	;
	;  Draw the next flash square.
	;
		test	ds:[di].VSI_state, mask VSS_ADVANCE
		jnz	done
		
		mov	bp, ds:[di].VSI_pointCurrent
		cmp	bp, NUM_CALIBRATION_POINTS
		je	done
		
		shl	bp, 1
		shl	bp, 1
		mov	cx, ds:[di].VSI_pointBufferDoc[bp].P_x
		mov	dx, ds:[di].VSI_pointBufferDoc[bp].P_y
		
		mov	si, di
		mov	di, ds:[si].VSI_gstate
		tst	di
		jz	done
	;
	;  See if we need to erase the old image.
	;
		mov	bp, ds:[si].VSI_pointState
		tst	bp
		jnz	erase
		
		mov	bp, CALIBRATION_FLASH_START
		jmp	draw
	;
	;  Erase the current flash square.
	;
erase:
		call	CalibrationClearFlash
		inc	bp
		cmp	bp, CALIBRATION_FLASH_END
		jle	draw
		mov	bp, CALIBRATION_FLASH_START
draw:
		call	CalibrationDrawFlash
		mov	ds:[si].VSI_pointState, bp
if 1
	;
	;  This is commented out because we get MSG_META_PTR
	;  events while the pen is down on the Bullet, even if
	;  it's not moving.
	;
		
	;	
	; Now check the calibration point
	;
		mov	di, si			; VisScreenInstance => DS:DI
		test	ds:[di].VSI_state, mask VSS_SELECT
		jz	done
		
		cmp	ds:[di].VSI_calCount, -1
		je	done			; if no press, do nothing
		
		mov	cx, ds:[di].VSI_calPoint.P_x
		mov	dx, ds:[di].VSI_calPoint.P_y
		clr	bp			; no override
		call	CalibrationCheckPoint
endif
		
done:
		.leave
		ret
VisScreenFlashCalibrationPoint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GState to be cached while we're visible

CALLED BY:	GLOBAL (MSG_VIS_OPEN)

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClassInstance
		bp	= Window to open on

RETURN:		Nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenVisOpen	method dynamic	VisScreenClass, MSG_VIS_OPEN
		.enter
	;
	;  First call my superclass.
	;
		mov	di, offset VisScreenClass
		call	ObjCallSuperNoLock
	;
	;  Now create the GState.
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallSuperNoLock
		LONG	jnc	done			;If no gstate available
		mov	di, ds:[si]
		add	di, ds:[di].VisScreen_offset
		mov	ds:[di].VSI_gstate, bp
	;
	;  Make sure the only the correct state bits are set.
	;
		clr	ds:[di].VSI_state
	;
	; Get the handle of the current mouse/pen driver, and
	; grab the calibration points. We assume that the driver
	; is already loaded, and hence we can unload it once
	; we've found the handle of the geode.
	;
		push	ds, si
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver

		mov_tr	bx, ax
		call	GeodeInfoDriver
		movdw	dxcx, ds:[si].DIS_strategy
		pop	ds, si
		mov	di, ds:[si]
		add	di, ds:[di].VisScreen_offset
		movdw	ds:[di].VSI_driverStrategy, dxcx
	;
	;  Set up the initial calibration points.
	;
		call	SetFakeCalibrationPoints
	;		
	;  Create a timer for calibration point flashing
	; 
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:[LMBH_handle]	; OD => BX:SI
		mov	cx, FLASH_INTERVAL	; time till 1st timeout
		mov	dx, MSG_VIS_SCREEN_FLASH_CALIBRATION_POINT
		mov	di, cx			; time interval
		call	TimerStart
		mov	di, ds:[si]
		add	di, ds:[di].VisScreen_offset
		movdw	ds:[di].VSI_timer, bxax
done:
		.leave
		ret
VisScreenVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up any cached data

CALLED BY:	MSG_VIS_CLOSE

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClassInstance

RETURN:		Nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenVisClose	method dynamic	VisScreenClass, MSG_VIS_CLOSE
		uses	ax
		.enter
	;
	;  Destroy the GState.
	;
		clr	ax
		xchg	ax, ds:[di].VSI_gstate
		tst	ax
		jz	timer
		xchg	di, ax	
		call	GrDestroyState
		mov_tr	di, ax			; ds:di = VisScreenInstance
timer:
	;		
	;  Create a timer for calibration point flashing.
	;
		clr	cx
		movdw	bxax, ds:[di].VSI_timer
		movdw	ds:[di].VSI_timer, cxcx
		tst	bx
		jz	done
		call	TimerStop
done:
	;		
	; We're done, so call our superclass
	;
		clr	ds:[di].VSI_pointCurrent
		
		.leave
		mov	di, offset VisScreenClass
		GOTO	ObjCallSuperNoLock
VisScreenVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the screen

CALLED BY:	GLOBAL (MSG_VIS_DRAW)

PASS:		*DS:SI	= VisScreenClass object
		DS:DI	= VisScreenClassInstance
		BP	= GState handle
		CL	= DrawFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenVisDraw	method dynamic	VisScreenClass, MSG_VIS_DRAW
		.enter
	;
	; First draw the screen
	;
		mov	si, di			; VisScreenInstance => DS:SI
		mov	di, bp			; GState => DI
		call	StringDraw
		call	CalibrationDraw

		.leave
		ret
VisScreenVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenRestartCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the whole thing over from the first point.

CALLED BY:	MSG_VIS_SCREEN_RESTART_CALIBRATION

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenRestartCalibration	method dynamic VisScreenClass, 
					MSG_VIS_SCREEN_RESTART_CALIBRATION
		.enter

		ornf	ds:[di].VSI_state, mask VSS_IGNORE_NEXT_END_SELECT
		call	RestartCalibrationCommon

		.leave
		ret
VisScreenRestartCalibration	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestartCalibrationCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for restarting calibration

CALLED BY:	VisScreenRestartCalibration, VisScreenRedoCalibration

PASS:		*ds:si	= VisScreen object
		ds:di	= VisScreenInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestartCalibrationCommon	proc	near
		class	VisScreenClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get out of calibrating mode.
	;
		mov	si, di			; VisScreenInstance => DS:SI
		andnf	ds:[di].VSI_state, not (mask VSS_SELECT or mask VSS_QUIT or mask VSS_ADVANCE or mask VSS_CALIBRATE)
	;
	;  Clear the current flash point.
	;
		mov	di, ds:[si].VSI_gstate
		clr	bp
		xchg	bp, ds:[si].VSI_pointCurrent
		shl	bp, 1
		shl	bp, 1			; since a Point is size 4
		mov	cx, ds:[si].VSI_pointBufferDoc[bp].P_x
		mov	dx, ds:[si].VSI_pointBufferDoc[bp].P_y
		clr	bp
		xchg	bp, ds:[si].VSI_pointState
		call	CalibrationClearFlash
		mov	ds:[si].VSI_calCount, -1
	;
	;  Reset the initial default calibration points.
	;
		push	di			; gstate
		mov	di, si			; di = instance
		call	SetFakeCalibrationPoints
		pop	di
if 0
		
	;		
	; Invalidate the rectangle that bounds the strings
	;
		clr	ax
		mov	bx, SCREEN_STRING1_TOP
		mov	cx, SCREEN_WIDTH
		mov	dx, SCREEN_STRING4_BOTTOM
		call	GrInvalRect		; request re-draw
endif
		call	GrGetWinBounds
		call	GrInvalRect

		.leave
		ret
RestartCalibrationCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFakeCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put in some reasonable default values.

CALLED BY:	RestartCalibrationCommon, VisScreenVisOpen

PASS:		ds:di	= VisScreenInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFakeCalibrationPoints	proc	near
		class	VisScreenClass
		uses	ax
		.enter
	;
	;  Write some fake calibration points to prevent the
	;  calibration from being REALLY screwed up, which can
	;  cause the penpresses to be over in the hard-icon bar,
	;  so we don't get any pointer events at all...
	;
		mov	ds:[di+0].VSI_pointBufferRaw.P_x, 64*4096/640
		mov	ds:[di+0].VSI_pointBufferRaw.P_y, 40*4096/400
		mov	ds:[di+4].VSI_pointBufferRaw.P_x, 576*4096/640
		mov	ds:[di+4].VSI_pointBufferRaw.P_y, 40*4096/400
		mov	ds:[di+8].VSI_pointBufferRaw.P_x, 64*4096/640
		mov	ds:[di+8].VSI_pointBufferRaw.P_y, 360*4096/400
		mov	ds:[di+12].VSI_pointBufferRaw.P_x, 576*4096/640
		mov	ds:[di+12].VSI_pointBufferRaw.P_y, 360*4096/400
		call	CalibrationSetPoints
	;
	;  Now clear the point buffer...
	;
		clr	ax
		czr	ax, ds:[di+0].VSI_pointBufferRaw.P_x
		czr	ax, ds:[di+0].VSI_pointBufferRaw.P_y
		czr	ax, ds:[di+4].VSI_pointBufferRaw.P_x
		czr	ax, ds:[di+4].VSI_pointBufferRaw.P_y
		czr	ax, ds:[di+8].VSI_pointBufferRaw.P_x
		czr	ax, ds:[di+8].VSI_pointBufferRaw.P_y
		czr	ax, ds:[di+12].VSI_pointBufferRaw.P_x
		czr	ax, ds:[di+12].VSI_pointBufferRaw.P_y
	;
	;  Get the points we need into VSI_pointBufferDoc.
	;
		call	CalibrationGetPoints

		.leave
		ret
SetFakeCalibrationPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a pen selection

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClassInstance
		(cx,dx)	= Mouse position

RETURN:		ax	= MouseReturnFlags

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenStartSelect	method dynamic	VisScreenClass,
						MSG_META_START_SELECT
		.enter

		ornf	ds:[di].VSI_state, mask VSS_SELECT
	;
	;  Set a timer for restarting calibration.
	;
		push	cx, dx				; mouse position
		mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, RESTART_CALIBRATION_TIMEOUT	; 5 seconds or so
		mov	dx, MSG_VIS_SCREEN_RESTART_CALIBRATION
		call	TimerStart
		pop	cx, dx				; mouse position

		mov	ds:[di].VSI_timerHandle, bx
		mov	ds:[di].VSI_timerID, ax
	;
	;  Grab the mouse.
	;
		push	cx, dx
		mov	ax, MSG_VIS_TAKE_GADGET_EXCL
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; our OD => CX:DX
		call	VisCallParent		; tell parent we want excl
		call	VisGrabMouse		; grab the mouse

		pop	cx, dx			; mouse coordinates
		clr	bp			; no override
		call	CalibrationCheckPoint

		mov	ax, mask MRF_PROCESSED

		.leave
		ret
VisScreenStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow the mouse around the screen

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClassInstance
		(cx,dx)	= Mouse position

RETURN:		ax	= MouseReturnFlags

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenPtr	method dynamic	VisScreenClass, MSG_META_PTR
		.enter

		test	bp, (mask UIFA_SELECT shl 8)
		jz	done

		clr	bp			; no override
		call	CalibrationCheckPoint
done:		
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
VisScreenPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Track the mouse pointer around the screen

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= VisScreenClass object
		ds:di	= VisScreenClassInstance
		(cx,dx)	= Mouse position

RETURN:		ax	= MouseReturnFlags

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisScreenEndSelect	method dynamic	VisScreenClass,
					MSG_META_END_SELECT
		uses	cx, dx, bp
		.enter

		test	ds:[di].VSI_state, mask VSS_SELECT
		jz	exit
		andnf	ds:[di].VSI_state, not (mask VSS_SELECT)
	;
	;  Kill the restart-calibration timer, if any.
	;
		clr	bx
		xchg	bx, ds:[di].VSI_timerHandle
		mov	ax, ds:[di].VSI_timerID
		call	TimerStop
	;
	;  If we're supposed to be ignoring this end-select, then
	;  do so, but only once.
	;
		test	ds:[di].VSI_state, mask VSS_IGNORE_NEXT_END_SELECT
		lahf
		andnf	ds:[di].VSI_state, not (mask VSS_IGNORE_NEXT_END_SELECT)
		sahf
		jnz	done
	;
	;  If we're on the final screen (we've got all the points),
	;  then we either quit or restart calibration.
	;
		test	ds:[di].VSI_state, mask VSS_QUIT
		jz	notDone

		call	CheckIfTheyQuit
		jnc	restart

		call	BringDownTheDialog
		jmp	done
restart:
		andnf	ds:[di].VSI_state, mask VSS_QUIT
		call	RestartCalibrationCommon
		jmp	done
notDone:
	;
	;  Check this point.  If CalibrationCheckPoint returns
	;  VSS_ADVANCE set, go to the next point.
	;
		mov	bp, TRUE		; override point count rule
		call	CalibrationCheckPoint

		test	ds:[di].VSI_state, mask VSS_ADVANCE
		jnz	advance
	;
	;  If VSS_CALIBRATE is not set at this point, then we have
	;  finished the calibration and are probably bringing down
	;  the dialog.
	;
		test	ds:[di].VSI_state, mask VSS_CALIBRATE
		jz	done
doCalibration:
		call	CalibrationSetPoints
		andnf	ds:[di].VSI_state, not (mask VSS_CALIBRATE)
		jmp	invalRegion
advance:
	;		
	;  Advance to the next point.
	;
		andnf	ds:[di].VSI_state, not (mask VSS_ADVANCE)
		clr	ds:[di].VSI_pointState

		mov	ds:[di].VSI_calCount, -1
		inc	ds:[di].VSI_pointCurrent

		cmp	ds:[di].VSI_pointCurrent, NUM_CALIBRATION_POINTS
		jne	invalRegion
	;
	;  We've got all the points, so do the calibration.
	;
		jmp	doCalibration
invalRegion:
	;		
	;  Invalidate the entire screen (not just the rectangle
	;  that bounds the strings) to get rid of spurious garbage
	;  that appears on the screen (such as leftover messages).
	;
		mov	di, ds:[di].VSI_gstate
		call	GrGetWinBounds
		call	GrInvalRect		; request re-draw
done:
		call	VisReleaseMouse		; release the mouse
exit:
		mov	ax, mask MRF_PROCESSED		

		.leave
		ret
VisScreenEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the appropriate strings

CALLED BY:	ScreenDraw

PASS:		ds:si	= VisScreenInstance
		di	= GState handle

RETURN:		Nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

	Regretfully I am reduced to pushing in one place
	and popping in two places, because Don used all the
	index registers.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringDraw	proc	near
		class	VisScreenClass
		uses	si
		.enter

		push	si
		mov	si, ds:[si].VSI_pointCurrent
		mov	bp, TRUE		; draw the sucker

		cmp	si, NUM_CALIBRATION_POINTS
		je	calibrationThanks	; if done, say thank you.
	;
	;  Draw the two calibration strings.
	;
		mov	bx, SCREEN_STRING1_TOP
		shl	si, 1
		add	si, offset calibrate1String
		call	DrawCenteredString
		
		mov	bx, SCREEN_STRING2_TOP
		mov	si, offset flashingString
		call	DrawCenteredString
		jmp	short calibrationRestart

calibrationThanks:
	;
	;  Draw the quit button.
	;
		pop	si
		or	ds:[si].VSI_state, mask VSS_QUIT
		mov	di, ds:[si].VSI_gstate
		mov	ax, C_BLACK or (CF_INDEX shl 8)
		call	GrSetAreaColor
		mov	ax, QUIT_BUTTON_LEFT
		mov	bx, QUIT_BUTTON_TOP
		mov	cx, QUIT_BUTTON_RIGHT
		mov	dx, QUIT_BUTTON_BOTTOM
		call	GrDrawRect
	;
	;  Draw the calibration thanks strings.
	;
		mov	bx, SCREEN_STRING1_TOP
		mov	si, offset calibrateThanks1String
		call	DrawCenteredString
		
		mov	bx, SCREEN_STRING2_TOP
		mov	si, offset calibrateThanks2String
		call	DrawCenteredString
		jmp	done
		
calibrationRestart:
		mov	bx, SCREEN_STRING3_TOP
		mov	si, offset restart1String;
		call	DrawCenteredString
		
		mov	bx, SCREEN_STRING4_TOP
		mov	si, offset restart2String;
		call	DrawCenteredString

		pop	si			; restore stack pointer
done:
		.leave
		ret
StringDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCenteredString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a string centered horizontally

CALLED BY:	UTILITY

PASS:		SI	= Chunk handle of string
		DI	= GState handle
		BP	= TRUE (draw) or FALSE (don't draw)
		BX	= Top of string

RETURN:		AX	= Left
		CX	= Right
		DX	= Top

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCenteredString	proc	far
		uses	si, ds
		.enter
	;		
	; Lock the done string
	;
		push	bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]		; string => DS:SI
		pop	bx
	;
	; Set the GState state properly
	;
		mov	cx, FID_BERKELEY
		mov	dx, SCREEN_FONT_SIZE
		clr	ah
		call	GrSetFont
	;
	; Calculate the text width
	;
		clr	cx			; NULL-terminated
		call	GrTextWidth
		mov	ax, SCREEN_WIDTH
		mov	cx, ax
		sub	ax, dx
		shr	ax, 1			; left => AX
		sub	cx, ax			; right => CX
		mov	dx, bx
		add	dx, SCREEN_FONT_SIZE	; bottom => DX
	;
	; Now draw the sucker
	;
		cmp	bp, TRUE
		jne	done			; don't draw if not TRUE
		push	cx, dx
		clr	cx			; NULL-terminated
		call	GrDrawText		; draw the text
		pop	cx, dx
done:
	;
	; Clean up
	;
		push	bx
		mov	bx, handle Strings
		call	MemUnlock
		pop	bx
		
		.leave
		ret
DrawCenteredString	endp


;-----------------------------------------------------------------------------
;		*** Calibration Stuff
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationGetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the points used for calibration

CALLED BY:	VisScreenVisOpen

PASS:		DS:DI	= VisScreenInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationGetPoints	proc	near
		class	VisScreenClass
		uses	di, si
		.enter
	;		
	; Call the pen digitizer driver
	;
		mov	bx, di			; ds:bx = instance
		mov	dx, ds
		mov	si, di
		add	si, offset VSI_pointBufferDoc
		mov	di, DR_MOUSE_GET_CALIBRATION_POINTS
		call	ds:[bx].VSI_driverStrategy
		mov	di, bx			; ds:di = VisScreenInstance
		jcxz	emulateZoomer		; if no calibration, emulate
	;
	; Now un-translate all of the points
	;
untranslate:
		mov	cx, NUM_CALIBRATION_POINTS
		mov	si, ds:[di].VSI_gstate
		xchg	si, di
		clr	bp
nextPoint:
		mov	ax, ds:[si].VSI_pointBufferDoc[bp].P_x
		mov	bx, ds:[si].VSI_pointBufferDoc[bp].P_y
		call	GrUntransform
		mov	ds:[si].VSI_pointBufferDoc[bp].P_x, ax
		mov	ds:[si].VSI_pointBufferDoc[bp].P_y, bx
		add	bp, (size Point)	; go to the next Point
		loop	nextPoint
		mov	ds:[si].VSI_calCount, -1
		
		.leave
		ret
	;
	; Emulate the Zoomer on the PC
	;
emulateZoomer:
		or	ds:[di].VSI_state, mask VSS_EMULATE
		mov	ds:[di+0].VSI_pointBufferDoc.P_x, 64
		mov	ds:[di+0].VSI_pointBufferDoc.P_y, 40
		mov	ds:[di+4].VSI_pointBufferDoc.P_x, 576
		mov	ds:[di+4].VSI_pointBufferDoc.P_y, 40
		mov	ds:[di+8].VSI_pointBufferDoc.P_x, 64
		mov	ds:[di+8].VSI_pointBufferDoc.P_y, 360
		mov	ds:[di+12].VSI_pointBufferDoc.P_x, 576
		mov	ds:[di+12].VSI_pointBufferDoc.P_y, 360
		jmp	untranslate

CalibrationGetPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationCheckPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the mouse is over the correct point

CALLED BY:	UTILITY

PASS:		DS:DI	= VisScreenInstance
		(CX,DX)	= Dcoument coordinate
		BP	= Override point-count requirement (TRUE or FALSE)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		* Grab the un-calibrated mouse position
		* Compare it against the desired point
		* If equal
			save point
			turn off hilite
			switch to next point

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationCheckPoint	proc	near
		class	VisScreenClass
		uses	di, si, bp
		.enter
	;		
	;  Get the current raw pen position.
	;
		call	CalibrationGetPoint	; returns ds:si = instance
		jc	startCount		; invalid point

		cmp	bp, TRUE		; override point-count rqmt?
		je	acceptPoint		; accept the point (pen release)
	;
	;  The user must hold the pen in the same location for
	;  CALIBRATION_POINT_COUNT number of points, unless the
	;  pen was released (then we assume the user knows what
	;  s/he wants).
	;
		mov	bp, ds:[si].VSI_pointCurrent
		shl	bp, 1
		shl	bp, 1			; multiply by size of a Point
		
		cmp	ds:[si].VSI_calCount, -1
		je	restartCount
		
		cmp	cx, ds:[si].VSI_calPoint.P_x
		jne	restartCount
		
		cmp	dx, ds:[si].VSI_calPoint.P_y
		jne	restartCount
		
		inc	ds:[si].VSI_calCount
		cmp	ds:[si].VSI_calCount, CALIBRATION_POINT_COUNT
		jne	done			; if not done, continue		
	;
	; Store the raw point away (AX, BX)
	;
acceptPoint:
		mov	bp, ds:[si].VSI_pointCurrent
		shl	bp, 1
		shl	bp, 1			; multiply by (size Point)
		mov	ds:[si].VSI_pointBufferRaw[bp].P_x, ax
		mov	ds:[si].VSI_pointBufferRaw[bp].P_y, bx
		or	ds:[si].VSI_state, mask VSS_ADVANCE
	;
	; Clear the current flash mark, for user feedback
	;
		mov	cx, ds:[si].VSI_pointBufferDoc[bp].P_x
		mov	dx, ds:[si].VSI_pointBufferDoc[bp].P_y
		mov	bp, ds:[si].VSI_pointState
		mov	di, ds:[si].VSI_gstate
		call	CalibrationClearFlash
done:
		.leave
		ret
	;
	; Re-start the calibration point count, only if the
	; adjusted point in within reasonable proximity to
	; the actual point
	;
restartCount:
		clc
startCount:
		mov	ds:[si].VSI_calCount, -1
		jc	done			; if invalid, wait some more
		mov	ds:[si].VSI_calPoint.P_x, cx
		mov	ds:[si].VSI_calPoint.P_y, dx
		clr	ds:[si].VSI_calCount
		jmp	done
CalibrationCheckPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationGetPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get & store the current calibration point

CALLED BY:	UTILITY

PASS:		DS:DI	= VisScreenInstance
		(CX,DX)	= Document coordinate

RETURN:		DS:SI	= VisScreenInstance
		(AX,BX)	= Raw coordinate
		Carry	= Clear (valid point)
			- or -
			= Set (invalid point)

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;PROXIMITY_HORIZONTAL	equ	40
;PROXIMITY_VERTICAL	equ	40

CalibrationGetPoint	proc	near
		class	VisScreenClass
		uses	bp
		.enter
	;		
	;  Grab the un-calibrated mouse position.
	;
		mov	si, di				; ds:si = instance
		mov	bx, di
		mov	di, DR_MOUSE_GET_RAW_COORDINATE
		call	ds:[bx].VSI_driverStrategy
		jc	emulateZoomer
	;
	;  Ensure the point is valid.
	;	adj	= (CX, DX)
	;	raw	= (AX, BX)
	;
checkProximity:
		push	cx, dx
		mov	bp, ds:[si].VSI_pointCurrent
		shl	bp, 1
		shl	bp, 1
		sub	cx, ds:[si].VSI_pointBufferDoc[bp].P_x
		sub	dx, ds:[si].VSI_pointBufferDoc[bp].P_y
if 0
	;
	;  We've commented this part out because Todd (in his
	;  nearly infinite pen-driver wisdom) has noted that
	;  if the calibration starts out Really Screwed Up,
	;  it's unlikely that the adjusted point will be 
	;  within 40 pixels of the document coordinate.
	;
		cmp	cx, PROXIMITY_HORIZONTAL
		jg	invalid
		cmp	cx, -PROXIMITY_HORIZONTAL
		jl	invalid
		cmp	dx, PROXIMITY_VERTICAL
		jg	invalid
		cmp	dx, -PROXIMITY_VERTICAL
		jl	invalid
endif
		clc
		jmp	short done
invalid::
	;		stc
done:
		pop	cx, dx
		
		.leave
		ret
	;
	; Emulate the Zoomer hardware
	;
emulateZoomer:
		mov	ax, cx
		mov	bx, dx
		dec	ax
		dec	bx
		jmp	short checkProximity
CalibrationGetPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationSetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the calibration points

CALLED BY:	CalibrationCheckPoint

PASS:		DS:DI	= VisScreenInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationSetPoints	proc	near
		class	VisScreenClass
		uses	bx, cx, di, si, bp
		.enter
	;	
	; Set the calibration points
	;
		mov	cx, NUM_CALIBRATION_POINTS
		mov	bx, di
		mov	si, di
		add	si, offset VSI_pointBufferRaw
		mov	dx, ds			; point array => DX:SI
		mov	di, DR_MOUSE_SET_CALIBRATION_POINTS
		call	ds:[bx].VSI_driverStrategy

		.leave
		ret
CalibrationSetPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the calibration points

CALLED BY:	ScreenDraw

PASS:		DS:SI	= VisScreenInstance
		DI	= GState handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationDraw	proc	near
		class	VisScreenClass
		uses	si
		.enter
	;	
	; Draw the calibration points
	;
		mov	cx, NUM_CALIBRATION_POINTS
		add	si, offset VSI_pointBufferDoc
pointLoop:
		mov	ax, ds:[si].P_x
		mov	bx, ds:[si].P_y
		call	CalibrationDrawPoint
		add	si, (size Point)
		loop	pointLoop				

		.leave
		ret
CalibrationDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationDrawPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single calibration point

CALLED BY:	CalibrationDraw

PASS:		DI	= GState handle
		(AX,BX)	= Calibration point

RETURN:		AX, BX, DX

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationDrawPoint	proc	near
		uses	cx
		.enter
	;	
	; Draw a cross-hair at the point
	;
		mov	cx, ax
		mov	dx, bx
		sub	ax, CROSSHAIR_LENGTH
		add	cx, CROSSHAIR_LENGTH + 1
		call	GrDrawLine

		mov	al, MM_INVERT
		call	GrSetMixMode
		
		sub	cx, CROSSHAIR_LENGTH + 1
		mov	ax, cx
		sub	bx, CROSSHAIR_LENGTH
		add	dx, CROSSHAIR_LENGTH + 1
		call	GrDrawLine

		mov	al, MM_COPY
		call	GrSetMixMode

		.leave
		ret
CalibrationDrawPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationDrawFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the flash for a single calibration point

CALLED BY:	UTILITY

PASS:		DS:SI	= VisScreenInstance
		DI	= GState
		BP	= Flash radius
		(CX,DX)	= Calibration point

RETURN:		Nothing

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalibrationClearFlash	proc	near
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetLineColor
		call	CalibrationDrawFlash
		mov	ax, C_BLACK or (CF_INDEX shl 8)
		call	GrSetLineColor
		ret
CalibrationClearFlash	endp				

CalibrationDrawFlash	proc	near
		uses	cx, dx
		.enter
	
		mov	ax, cx
		mov	bx, dx
		sub	ax, bp
		sub	bx, bp
		add	cx, bp
		add	dx, bp
		call	GrDrawRect

		.leave
		ret
CalibrationDrawFlash	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringDownTheDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismiss the calibration dialog.

CALLED BY:	VisScreenStartSelect

PASS:		*ds:si	= VisScreen object
		ds:di	= VisScreenInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/29/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BringDownTheDialog	proc	near
		class	VisScreenClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  Kill the restart-calibration timer, if any.
	;
		clr	bx
		xchg	bx, ds:[di].VSI_timerHandle
		mov	ax, ds:[di].VSI_timerID
		call	TimerStop		
	;
	; Tell the system the pen is calibrated
	;
		mov	ax, TRUE
		call	BSSetCalibration
	;
	;  Call our parent (the content) telling it to deal with this.
	;
		mov	ax, MSG_VIS_SCREEN_CONTENT_DISMISS_DIALOG
		call	VisCallParent

		.leave
		ret
BringDownTheDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisScreenContentDismissDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the dialog we're in.

CALLED BY:	MSG_VIS_SCREEN_CONTENT_DISMISS_DIALOG

PASS:		*ds:si	= VisScreenContentClass object
		ds:di	= VisScreenContentClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisScreenContentDismissDialog	method dynamic VisScreenContentClass, 
					MSG_VIS_SCREEN_CONTENT_DISMISS_DIALOG

	;
	;  Get the block our view is in (this is the same block
	;  as the main dialog).
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	bx, ds:[di].VCNI_view.handle
		mov	si, offset CalibrationDialog
		mov	cx, IC_DISMISS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	;  Tell the primary to go on to the next screen.
	;
		mov	bx, handle MyBSPrimary
		mov	si, offset MyBSPrimary
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_BS_PRIMARY_DO_THE_TIME_DATE_THING
		GOTO	ObjMessage

VisScreenContentDismissDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTheyQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the user clicked in the quit-button area.

CALLED BY:	VisScreenStartSelect

PASS:		ds:di	= VisScreenInstance
		(cx,dx)	= mouse position

RETURN:		carry set if they quit, clear to restart calibration

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/ 6/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfTheyQuit	proc	near
		.enter

		cmp	cx, QUIT_BUTTON_LEFT
		jb	nope

		cmp	cx, QUIT_BUTTON_RIGHT
		ja	nope

		cmp	dx, QUIT_BUTTON_TOP
		jb	nope

		cmp	dx, QUIT_BUTTON_BOTTOM
		ja	nope

		stc
		jmp	done
nope:
		clc
done:
		.leave
		ret
CheckIfTheyQuit	endp

CalibrateCode	ends
