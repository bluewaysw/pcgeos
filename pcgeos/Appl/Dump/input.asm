COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- input tracking
FILE:		input.asm

AUTHOR:		Adam de Boor, Jan 21, 1990

ROUTINES:
	Name			Description
	----			-----------
	InputMonitor		Input snarfer
	InputThaw		Release the screen at the completion of
				a dump.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/21/90		Initial revision


DESCRIPTION:
	Functions to deal with user input in all its forms.
		
	Most commands are preceded by the magic invocation Ctrl-Shift-Tab,
	which freezes the current screen state. All input is swallowed by
	our monitor when the screen is frozen. The following commands are
	then available:
		f1	bring up the main parameters box (unfreezes screen
			first)
		f2	repeat the previous dump
		f3	dump the window under the pointer after removing
			the pointer image
		f4	dump the window under the pointer but leave the
			pointer image in place
		f5	bring up the resizable rectangle for manipulation
		f6	dump the screen rectangle bounded by the resizable
			rectangle
		f7	dump all windows completely enclosed by the rectangle
		f8	dump the entire screen.
		f10	dump the entire screen
		f11	dump the window under the pointer after
			removing the pointer image
		f12	dump the window under the pointer without
			removing the pointer image
		esc	unfreeze the screen w/o doing anything

	Commands that work w/o having to freeze the screen first:
		Shift-PrtScr	dump the entire screen.
		f10		dump the entire screen
		f11		dump the window under the pointer after
				removing the pointer image
		f12		dump the window under the pointer without
				removing the pointer image

	$Id: input.asm,v 1.1 97/04/04 15:36:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
;include mouse.def
include timer.def
;include event.def
;include keyboard.def
include timedate.def

; NEW .def files for 2.0
include Objects/inputC.def
include Internal/im.def
include Internal/videoDr.def
include Internal/grWinInt.def

InputState	record
    IS_COMMAND_SENT:1		; Set if dump command sent to process thread 
    				;  and nothing further should be processed.
    IS_LEFT_ANCHOR:1,		; Set if left edge of box is anchored, else
				;  right is.
    IS_TOP_ANCHOR:1,		; Set if top edge of box is anchored, else
				;  bottom is.
    IS_RESIZING:1,		; Non-zero if actively resizing the box with
    				;  the mouse.
    IS_FROZEN:1,		; Set if screen frozen (all input swallowed)
    IS_HAVERECT:1,		; Set if we've ever put up the rectangle
    IS_RECTDRAWN:1,		; Set if the rectangle has been xor'ed into
				;  the screen
InputState	end

udata	segment

dumpState	hptr.GState	; Graphics state that has exclusive access to
				;  the screen
driverHandle	hptr		; Handle of video driver we've frozen
driverStrategy	fptr.far	; Routine to call to shift the pointer

inState		InputState	<>

;
; Our notion of the mouse position. 
;
mousePos	Point
buttonState	byte		; <0:3> set if corresponding button down

;
; Initial values for the pointer. When the screen is released, the pointer
; image is warped back to initMousePos and BUTTON_CHANGE events are sent
; to the IM to account for the difference between buttonState and
; initButtonState. Of course, if the pointer driver generates absolute
; positions, the warping back will have little effect the next time the
; user moves the pointer, but...
;
initMousePos	Point
initButtonState	byte		; <0:3> set if corresponding button was down

;
; Screen coordinates of resizable rectangle
;
rectBox		Rectangle
;
; Bounding box of the screen.
;
screenRect	Rectangle

udata	ends

Resident	segment resource


;------------------------------------------------------------------------------
;
;			  RECTANGLE TRACKING
;
;------------------------------------------------------------------------------




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputXorRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	XOR the current rectangle into the screen regardless of its
		previous state.

CALLED BY:	InputDrawRect, InputRemoveRect
PASS:		ds	= dgroup
		dumpState opened to screen's root and set for GR_INVERT mode
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputXorRect	proc	near
		.enter
		mov	di, ds:dumpState
		mov	ax, ds:rectBox.R_left
		mov	bx, ds:rectBox.R_top
		mov	cx, ds:rectBox.R_right
		mov	dx, ds:rectBox.R_bottom
		call	GrDrawRect
		.leave
		ret
InputXorRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the rectangle appears on-screen

CALLED BY:	InputShowRect, InputPtrChange
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDrawRect	proc	near
		.enter
		test	ds:inState, mask IS_RECTDRAWN
		jnz	done
		call	InputXorRect
		ornf	ds:inState, mask IS_RECTDRAWN
done:
		.leave
		ret
InputDrawRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputRemoveRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the rectangle isn't on-screen

CALLED BY:	InputThaw, InputPtrChange
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputRemoveRect	proc	near
		.enter
		test	ds:inState, mask IS_RECTDRAWN
		jz	done
		call	InputXorRect
		andnf	ds:inState, not mask IS_RECTDRAWN
done:
		.leave
		ret
InputRemoveRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputShowRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the rectangle up on the screen at the last known location.
		If no previous location, stick it at the current mouse position
		and make it small (10x10)

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si,, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputShowRect	proc	near
		.enter
		test	ds:inState, mask IS_RECTDRAWN
		jnz	done
		test	ds:inState, mask IS_HAVERECT
		jnz	drawRect
		;
		; No rectangle previously known, so put up a 10x10 rectangle
		; with upper-left corner at the mouse position, making sure
		; it doesn't stray off the side of the screen.
		;
		mov	ax, ds:mousePos.P_x
		mov	ds:rectBox.R_left, ax
		mov	bx, ds:mousePos.P_y
		mov	ds:rectBox.R_top, bx
		add	ax, 10
		cmp	ax, ds:screenRect.R_right
		jle	10$
		mov	ax, ds:screenRect.R_right
10$:
		mov	ds:rectBox.R_right, ax
		add	bx, 10
		cmp	bx, ds:screenRect.R_bottom
		jle	20$
		mov	bx, ds:screenRect.R_bottom
20$:
		mov	ds:rectBox.R_bottom, bx
		ornf	ds:inState, mask IS_HAVERECT
drawRect:
		;
		; Make sure the graphics state is XORing things
		;
		mov	di, ds:dumpState

		call	InputDrawRect
done:
		.leave
		ret
InputShowRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputNW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or two of its sides to the
		northwest one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputNW		proc	near
		mov	ax, -1
		mov	bx, ax
		lea	si, rectBox.R_left
		lea	di, rectBox.R_top
		GOTO	InputCursorCommon
InputNW		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputSW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or two of its sides to the
		southwest one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputSW		proc	near
		mov	ax, -1
		mov	bx, 1
		lea	si, rectBox.R_left
		lea	di, rectBox.R_bottom
		GOTO	InputCursorCommon
InputSW		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputNE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or two of its sides to the
		northeast one pixel.

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputNE		proc	near
		mov	ax, 1
		mov	bx, -1
		lea	si, rectBox.R_right
		lea	di, rectBox.R_top
		GOTO	InputCursorCommon
InputNE		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or two of its sides to the
		southeast one pixel.

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputSE		proc	near
		mov	ax, 1
		mov	bx, ax
		lea	si, rectBox.R_right
		lea	di, rectBox.R_bottom
		GOTO	InputCursorCommon
InputSE		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or one of its sides up one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputUp		proc	near
		mov	ax, 0
		mov	bx, -1
		lea	si, rectBox.R_left
		lea	di, rectBox.R_top
		GOTO	InputCursorCommon
InputUp		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or one of its sides down one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDown	proc	near
		mov	ax, 0
		mov	bx, 1
		lea	si, rectBox.R_right
		lea	di, rectBox.R_bottom
		GOTO	InputCursorCommon
InputDown	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or one of its sides left one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputLeft	proc	near
		mov	ax, -1
		mov	bx, 0
		lea	si, rectBox.R_left
		lea	di, rectBox.R_top
		GOTO	InputCursorCommon
InputLeft	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the current rectangle or one of its sides right one pixel

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Call InputCursorCommon with parameters set up as follows:
			ax	= change in X
			bx	= change in Y
			si	= address of x coord to modify if side
				  being altered
			di	= address of y coord to modify if side
				  being altered

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputRight	proc	near
		mov	ax, 1
		mov	bx, 0
		lea	si, rectBox.R_right
		lea	di, rectBox.R_bottom
		FALL_THRU	InputCursorCommon
InputRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputCursorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a cursor key by adjusting the current rectangle
		some amount. If the cursor key was typed unmodified, the
		rectangle itself is shifted (it is *not* constrained by the
		screen). If the cursor key was typed with a shift modifier
		but no control modifier, the appropriate side is enlarged (the
		size *is* constrained by the screen bounds). If the cursor
		key was typed with both shift and control modifiers, the
		appropriate side is shrunk.

		If the key is modified with ALT, the motion is magnified by 8
		in whatever direction.

CALLED BY:	Input{Up,Down,Left,Right}
PASS:		ax	= delta X
		bx	= change in Y
		si	= address of x coord to modify if side
			  being altered
		di	= address of y coord to modify if side
			  being altered
		dh	= ShiftState
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputCursorCommon proc	near
		.enter
		push	ax, bx, dx, di
		call	InputRemoveRect
		pop	ax, bx, dx, di
		test	dh, mask SS_LALT or mask SS_RALT
		jz	noMagnify
		shl	ax
		shl	ax
		shl	ax
		shl	bx
		shl	bx
		shl	bx
noMagnify:
		test	dh, mask SS_LSHIFT or mask SS_RSHIFT
		jz	moveRect
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	enlarge
		neg	ax
		neg	bx
enlarge:
		add	ds:[si], ax
		add	ds:[di], bx
		;
		; Constrain the box to be completely on-screen
		;
		mov	ax, ds:screenRect.R_left
		cmp	ax, ds:rectBox.R_left
		jle	10$
		mov	ds:rectBox.R_left, ax
10$:
		mov	ax, ds:screenRect.R_top
		cmp	ax, ds:rectBox.R_top
		jle	20$
		mov	ds:rectBox.R_top, ax
20$:
		mov	ax, ds:screenRect.R_right
		cmp	ax, ds:rectBox.R_right
		jge	30$
		mov	ds:rectBox.R_right, ax
30$:
		mov	ax, ds:screenRect.R_bottom
		cmp	ax, ds:rectBox.R_bottom
		jge	40$
		mov	ds:rectBox.R_bottom, ax
40$:
		;
		; Deal with shrinking so sides are flipped by exchanging
		; the inverted sides.
		;
		mov	ax, ds:rectBox.R_left
		cmp	ax, ds:rectBox.R_right
		jle	50$
		xchg	ax, ds:rectBox.R_right
		mov	ds:rectBox.R_left, ax
50$:
		mov	ax, ds:rectBox.R_top
		cmp	ax, ds:rectBox.R_bottom
		jle	60$
		xchg	ax, ds:rectBox.R_bottom
		mov	ds:rectBox.R_top, ax
60$:
		jmp	drawIt
moveRect:
		;
		; Just shift the rectangle. Note there is no constraining to the
		; screen as we don't want to nuke the size of the rectangle the
		; user has specified. We just trust the user won't try and dump
		; something that's off-screen.
		;
		add	ds:rectBox.R_left, ax
		add	ds:rectBox.R_top, bx
		add	ds:rectBox.R_right, ax
		add	ds:rectBox.R_bottom, bx
drawIt:
		call	InputDrawRect
		.leave
		ret
InputCursorCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputMovePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the pointer image to the indicated position

CALLED BY:	INTERNAL
PASS:		cx	= mouse X position
		dx	= mouse Y position
		ds	= dgroup
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputMovePtr	proc	near
		.enter
		mov	ds:mousePos.P_x, cx
		mov	ds:mousePos.P_y, dx
		push	ds, es, bx, cx, dx, si, di, bp
		mov	di, DR_VID_MOVEPTR
		mov	ax, cx
		mov	bx, dx
		call	ds:driverStrategy
		pop	ds, es, bx, cx, dx, si, di, bp
		.leave
		ret
InputMovePtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputPtrChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a PTR_CHANGE event

CALLED BY:	InputMonitor
PASS:		cx	= X position/change
		dx	= Y position/change
		bp<15>	= X-is-absolute flag
		bp<14>	= Y-is-absolute flag
		bp<0:13>= time stamp
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Eventually, this will see if currently adjusting/placing
		rectangle and call InputCursorCommon, but for now it just
		moves the pointer image to compensate.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputPtrChange	proc	near
		.enter
		test	bp, mask PI_absX
		jnz	10$
		add	cx, ds:mousePos.P_x
10$:
		test	bp, mask PI_absY
		jnz	20$
		add	dx, ds:mousePos.P_y
20$:
		cmp	cx, ds:screenRect.R_left
		jge	30$
		mov	cx, ds:screenRect.R_left
30$:
		cmp	cx, ds:screenRect.R_right
		jle	40$
		mov	cx, ds:screenRect.R_right
40$:
		cmp	dx, ds:screenRect.R_top
		jge	50$
		mov	dx, ds:screenRect.R_top
50$:
		cmp	dx, ds:screenRect.R_bottom
		jle	60$
		mov	dx, ds:screenRect.R_bottom
60$:
		call	InputMovePtr

		test	ds:[inState], mask IS_RESIZING
		jz	done
		
		push	cx, dx
		call	InputRemoveRect
		pop	cx, dx
		
		mov	al, ds:[inState]

		test	al, mask IS_LEFT_ANCHOR
		jz	checkRight
		cmp	cx, ds:[rectBox].R_left
		jge	storeRight
		andnf	al,not  mask IS_LEFT_ANCHOR
		xchg	ds:[rectBox].R_left, cx
storeRight:
		mov	ds:[rectBox].R_right, cx
checkTop:
		test	al, mask IS_TOP_ANCHOR
		jz	checkBottom
		cmp	dx, ds:[rectBox].R_top
		jge	storeBottom
		andnf	al, not mask IS_TOP_ANCHOR
		xchg	ds:[rectBox].R_top, dx
storeBottom:
		mov	ds:[rectBox].R_bottom, dx
redrawBox:
		mov	ds:[inState], al
		call	InputDrawRect
done:		
		.leave
		ret
checkRight:
		cmp	cx, ds:[rectBox].R_right
		jle	storeLeft
		ornf	al, mask IS_LEFT_ANCHOR
		xchg	cx, ds:[rectBox].R_right
storeLeft:
		mov	ds:[rectBox].R_left, cx
		jmp	checkTop

checkBottom:
		cmp	dx, ds:[rectBox].R_bottom
		jle	storeTop
		ornf	al, mask IS_TOP_ANCHOR
		xchg	dx, ds:[rectBox].R_bottom
storeTop:
		mov	ds:[rectBox].R_top, dx
		jmp	redrawBox
InputPtrChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputButtonChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a BUTTON_CHANGE event

CALLED BY:	InputMonitor
PASS:		cx:dx	= time stamp (ignored)
		bp low	= ButtonInfo
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		Eventually this will take note of B0 vs. B2 presses and either
		lay down a new or adjust the existing rectangle. For now,
		this just takes note of the transition so the proper events
		can be sent through the IM when the dump is finished.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputButtonChange proc	near
		.enter
		mov	al, 1			; Assume press
		test	bp, mask BI_PRESS
		lahf
		jnz	10$
		mov	al, not 1
10$:
		mov	cx, bp
		andnf	cx, mask BI_BUTTON
		rol	al, cl
		sahf
		jnz	isPress
		and	ds:buttonState, al
		jnz	done
		andnf	ds:[inState], not mask IS_RESIZING
		jmp	done
isPress:
		test	ds:[inState], mask IS_RESIZING
		jnz	markPressed
		push	ax
		cmp	cl, BUTTON_0
		mov	cx, ds:[mousePos].P_x		
		mov	dx, ds:[mousePos].P_y
		jne	adjust

		push	cx, dx
		call	InputRemoveRect
		pop	cx, dx
startAfresh:
		mov	ds:[rectBox].R_left, cx
		mov	ds:[rectBox].R_right, cx
		mov	ds:[rectBox].R_top, dx
		mov	ds:[rectBox].R_bottom, dx
		ornf	ds:[inState],
			mask IS_LEFT_ANCHOR or mask IS_TOP_ANCHOR
startResize:
	;
	; Make sure graphics state is XORing things.
	; 
		mov	di, ds:[dumpState]

		ornf	ds:[inState], mask IS_RESIZING or mask IS_HAVERECT
		mov	bp, mask PI_absX or mask PI_absY
		call	InputPtrChange
		pop	ax
markPressed:
		ornf	ds:buttonState, al
done:
		.leave
		ret
adjust:
	;
	; If no rectangle existed before, don't start adjusting from (0,0),
	; but from where we clicked, as if button 0 had been clicked.
	;
		test	ds:[inState], mask IS_HAVERECT
		jz	startAfresh
		jmp	startResize
InputButtonChange endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputFreeze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Freeze the screen on which the pointer currently resides

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		carry clear if freeze successful:
			inState.IS_FROZEN set
		carry set if freeze unsuccessful
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputFreeze	proc	near	uses bx
		.enter
		call	DumpPreFreeze
		LONG	jc	done

		call	ImGetPtrWin	; di = root win, bx = driver handle
		;
		; Open an unattached root window on the screen so we can draw
		; the box wherever we damn well want to. As a side-effect, save
		; the bounds of the window so created so we can constrain the
		; rectangle when we want to.
		;
		clr	ax
		push	ax		; layer ID doesn't matter
		mov	cx, handle 0
		push	cx		; Request win be owned by screen
					;  dumper, not IM thread...
		push	bx		; pass driver handle
		mov	ds:driverHandle, bx	; and save it for later too
		push	ax		; Window is rectangular (no region
		push	ax		;  passed)
		call	WinGetWinScreenBounds
		push	dx		; Pass dimensions of new window
		push	cx
		push	bx
		push	ax
		mov	ds:screenRect.R_left, ax
		mov	ds:screenRect.R_top, bx
		mov	ds:screenRect.R_right, cx
		mov	ds:screenRect.R_bottom, dx
		mov	si, mask WPF_CREATE_GSTATE or mask WPF_ROOT
		clr	di	; No one to receive exposures
		mov	bp, di
		mov	cx, di	; No one to receive enter/leave
		mov	dx, di
		mov	ax, (mask WCF_TRANSPARENT or mask WCF_PLAIN) shl 8
		call	WinOpen
		mov	ds:dumpState, di	; Save created state
	;
	; Switch the state into invert mode, as we never draw anything
	; through it unless we want to invert it.
	; 
		mov	al, MM_INVERT
		call	GrSetMixMode
		;
		; Make the window sharable so our process thread can make use
		; of it.
		;
		mov	ax, mask HF_SHARABLE	; Set sharable bit, reset none
		call	MemModifyFlags
		push	bx			; Save window for ImGetMousePos
		;
		; Record info about the driver so we can shift the pointer
		; image around if we need to.
		;
		mov	bx, ds:driverHandle
		push	ds, si
		call	GeodeInfoDriver
		mov	cx, ds:[si].DIS_strategy.offset
		mov	dx, ds:[si].DIS_strategy.segment 
		mov	bx, si
		mov	ax, ds
		pop	ds, si
		mov	ds:driverStrategy.offset, cx
		mov	ds:driverStrategy.segment, dx
		mov	ds:[vidDriver].segment, ax
		mov	ds:[vidDriver].offset, bx

		;
		; Get exclusive access to the screen.
		;
		mov	bx, ds:[driverHandle]	; use this video driver
		call	GrGrabExclusive
		ornf	ds:inState, mask IS_FROZEN
		;
		; Fetch the current state of the pointer so we can restore it
		; (sort of) when we thaw the screen.
		;
		pop	di
		call	ImGetMousePos
		mov	ds:mousePos.P_x, cx
		mov	ds:mousePos.P_y, dx
		mov	ds:initMousePos.P_x, cx
		mov	ds:initMousePos.P_y, dx

		call	ImGetButtonState
		mov	cl, offset BI_B0_DOWN
		shr	al, cl
		mov	ds:buttonState, al
		mov	ds:initButtonState, al
		clc
done:
		.leave
		ret
InputFreeze	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                InputSendButtonEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Send a button event to the IM

CALLED BY:      InputThaw
PASS:           BL      = button number for event:
                                0 = left
                                1 = middle
                                2 = right
                                3 = fourth button
                ZF      = Clear if button now down
RETURN:         Nothing
DESTROYED:      CX, DX, BP, DI

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   3/10/89         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputSendButtonEvent proc    near	uses ax, bx
		.enter
                jz     SBE_10                  	; See if press bit set
                or      bl, MASK BI_PRESS       ; Set press flag
SBE_10:
                                                ; store button #/press flag
                clr     bh
                mov     bp, bx
                                                ; Get current time NOW
                call    TimerGetCount           ; Fetch <bx><ax> = system time
                mov     cx, ax                  ; set <dx><cx> = system time
                mov     dx, bx

		call	ImInfoInputProcess
                mov     di, mask MF_FORCE_QUEUE
                mov     ax, MSG_IM_BUTTON_CHANGE
                call    ObjMessage              ; Send the event

		.leave
                ret
InputSendButtonEvent endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputThaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the screen and let all input go back to its proper
		channel.

CALLED BY:	InputCommon
PASS:		ds	= dgroup
RETURN:		inState.IS_FROZEN reset, previous exclusive re-established
DESTROYED:	dumpState

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Macro to test if a button has changed state and call SendButtonEvent to
; generate the proper MSG_BUTTON_CHANGE event.
;
CheckAndSend    macro   num
                local   noSend
                test    ah, 1 shl num     	; Changed?
                jz      noSend                  ; No
                mov     bl, num                 ; Load bl with button #
                test    al, 1 shl num     	; Set ZF true if button now
                                                ;  down
                call    InputSendButtonEvent
noSend:
                endm

InputThaw	proc	far	uses di, bx, ax, cx, dx, bp, si
		.enter
		;
		; Make sure the rectangle isn't showing
		;
		call	InputRemoveRect
		;
		; Shift the pointer image back to where it was before
		;
		mov	cx, ds:initMousePos.P_x
		mov	dx, ds:initMousePos.P_y
		call	InputMovePtr
		;
		; Now end our exclusive. If there was one active when we froze
		; the screen, we replace it by breaking our exclusive, otherwise
		; we can just quietly end our exclusive and have done.
		;
		mov	bx, ds:driverHandle
		mov	di, ds:dumpState
		call	GrReleaseExclusive
		cmp	cx, ax		; X coordinates the same
		jle	done		; yes, or they cross, so nothing
					;  changed
	;
	; Something changed and we have to redraw the affected area. Sigh.
	;		
		push	bx
		call	ImGetPtrWin	; di <- root win
		pop	bx
		clr	bp, si		; => rectangular region
		call	WinInvalTree
done:
		;
		; Nuke the state we created in InputFreeze
		;
		mov	di, ds:dumpState
		call	WinClose		; Biff root window and state
		andnf	ds:inState, not (mask IS_FROZEN or mask IS_COMMAND_SENT)
		;
		; Send required BUTTON_CHANGE events to bring the IM and the UI
		; up-to-speed on where things are now.
		;
		mov	al, ds:buttonState
		mov	ah, ds:initButtonState
		xor	ah, al

		CheckAndSend	BUTTON_0
		CheckAndSend	BUTTON_1
		CheckAndSend	BUTTON_2
		CheckAndSend	BUTTON_3

		.leave
		ret
InputThaw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputShowParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our primary parameters box is visible on-screen

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputShowParameters proc near
		.enter
	;
	; Just need to tell the app to come to the top. It'll take care of
	; bringing the primary back to reality.
	; 
		mov	bx, handle DumpApp
		mov	si, offset DumpApp
		mov	ax, MSG_GEN_BRING_TO_TOP
		clr	di
		call	ObjMessage
		call	InputThaw
		.leave
		ret
InputShowParameters endp

;------------------------------------------------------------------------------
;
;		DUMP COMMANDS -- VARIATIONS ON A THEME
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputReDump
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the same rectangle as before (XXX: same windows as
		before?)

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputReDump	proc	near
		mov	ax, MSG_DUMP_AGAIN
		GOTO	InputDumpCommon
InputReDump	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpWindowNoPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the window under the pointer after removing the pointer
		image from the screen.

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpWindowNoPtr	proc	near
		mov	ax, MSG_DUMP_WINDOW_NO_PTR
		GOTO	InputDumpCommon
InputDumpWindowNoPtr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the window under the pointer, but leave the pointer
		image there.

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpWindow	proc	near
		mov	ax, MSG_DUMP_WINDOW
		GOTO	InputDumpCommon
InputDumpWindow	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the current rectangle.

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpRect	proc	near
		mov	ax, MSG_DUMP_RECT
		GOTO	InputDumpCommon
InputDumpRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpWindowsInRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the windows enclosed by the current rectangle

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpWindowsInRect	proc	near
		mov	ax, MSG_DUMP_WINDOWS_IN_RECT
		GOTO	InputDumpCommon
InputDumpWindowsInRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the current screen

CALLED BY:	InputMonitor
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpScreen	proc	near
		mov	ax, MSG_DUMP_SCREEN
		FALL_THRU	InputDumpCommon
InputDumpScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDumpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to send a method to ourselves

CALLED BY:	InputReDump, InputDumpWindowNoPtr, InputDumpWindow,
       		InputDumpRect, InputDumpWindowsInRect, InputDumpScreen
PASS:		ax	= method to send
		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx, si, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDumpCommon	proc	near
		.enter
		;
		; Make sure the rectangle is gone from the screen. This will
		; also force the user to bring the thing up again once the dump
		; is complete.
		;
		push	ax
		call	InputRemoveRect
		pop	ax
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		ornf	ds:[inState], mask IS_COMMAND_SENT
		.leave
		ret
InputDumpCommon	endp

;------------------------------------------------------------------------------
;
;			    INPUT MONITOR
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Watch for commands and send the proper method to our process
		when they come in.

CALLED BY:	im::ProcessUserInput
PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high	= scan code
		MSG_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data
RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event
DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Under DBCS, there are five conditional jumps converted to
		longs.  These should be taken out of the main logic flow.
		However, leaving the LONG directive out, lets `esp' produce
		the best code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
funcTable	nptr	InputShowParameters,	; VC_F1
			InputReDump,		; VC_F2
			InputDumpWindowNoPtr,	; VC_F3
			InputDumpWindow,	; VC_F4
			InputShowRect,		; VC_F5
			InputDumpRect,		; VC_F6
			InputDumpWindowsInRect,	; VC_F7
			InputDumpScreen,	; VC_F8
			0,			; VC_F9
			InputDumpScreen,	; VC_F10
			InputDumpWindowNoPtr,	; VC_F11
			InputDumpWindow		; VC_F12

cursorTable	nptr	InputUp,		; VC_UP\
			InputDown,		; VC_DOWN\
			InputRight,		; VC_RIGHT\
			InputLeft,		; VC_LEFT\
			InputNW,		; VC_HOME\
			InputSW,		; VC_END\
			InputNE,		; VC_PREVIOUS\
			InputSE			; VC_NEXT
keypadTable	nptr	InputSW,		; VC_NUMPAD_1\
			InputDown,		; VC_NUMPAD_2\
			InputSE,		; VC_NUMPAD_3\
			InputLeft,		; VC_NUMPAD_4\
			0,			; VC_NUMPAD_5\
			InputRight,		; VC_NUMPAD_6\
			InputNW,		; VC_NUMPAD_7\
			InputUp,		; VC_NUMPAD_8\
			InputNE			; VC_NUMPAD_9

InputMonitor	proc	far
		test	al, mask MF_DATA
		jz	done
		test	ds:inState, mask IS_FROZEN
		jnz	frozen
		;
		; If not frozen, we respond to four sequences:
		;	VC_PRINTSCREEN		quick way to dump the current
		;				screen.
		;	Ctrl-Shift-Tab		freeze screen and wait for
		;				further commands.
		;	F10			quicker way to dump full screen
		;	F11			quick way to dump window w/o ptr
		;	F12			quick way to dump window w/ptr
		;
		;	fire button		quick way to dump the screen
		;
		cmp	di, MSG_META_KBD_CHAR
		jne	done
		test	dl, mask CF_RELEASE	; don't care about releases
		jnz	done
		mov	bx, offset InputDumpScreen
if DBCS_PCGEOS
		cmp	cx, C_SYS_FIRE_BUTTON_1	
		je	doQuick
		cmp	cx, C_SYS_FIRE_BUTTON_2
		je	doQuick
		;  control attr (VC_) is builtin to Unicode chars..

		cmp	cx, C_SYS_PRINT_SCREEN	; fullscreen?
		je	doQuick
		tst	dh
		jnz	testFreeze		; any modifier down => ignore
						;  these keys
		cmp	cx, C_SYS_F10
		je	doQuick
		mov	bx, offset InputDumpWindowNoPtr
		cmp	cx, C_SYS_F11		; window w/o ptr?
		je	doQuick
		mov	bx, offset InputDumpWindow
		cmp	cx, C_SYS_F12		; window w/ptr?
		jne	testFreeze		; no -- see if freeze command
else
		cmp	ch, CS_CONTROL		; if not CTRL, can't be
						;  interesting
		jne	done
		cmp	cl, VC_FIRE_BUTTON_1	
		je	doQuick
		cmp	cl, VC_FIRE_BUTTON_2
		je	doQuick
		cmp	cl, VC_PRINTSCREEN	; fullscreen?
		je	doQuick
		tst	dh
		jnz	testFreeze		; any modifier down => ignore
						;  these keys
		cmp	cl, VC_F10
		je	doQuick
		mov	bx, offset InputDumpWindowNoPtr
		cmp	cl, VC_F11		; window w/o ptr?
		je	doQuick
		mov	bx, offset InputDumpWindow
		cmp	cl, VC_F12		; window w/ptr?
		jne	testFreeze		; no -- see if freeze command
endif
		;
		; Quick key hit: send a method to ourselves so the dumping
		; happens on our time and, more importantly, in our context,
		; with all that implies...bx is the function to call to
		; send the appropriate method.
		;
doQuick:
		call	InputFreeze		; So quick function has a state
						;  and the screen is frozen
		jc	consumed
		ornf	ds:[inState], mask IS_COMMAND_SENT
		call	bx
		jmp	consumed
testFreeze:
		; Looking for Ctrl-Shift-Tab...
SBCS<		cmp	cl, VC_TAB				>
DBCS<		cmp	cx, C_SYS_TAB				>
		jne	done
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	done
		test	dh, mask SS_LSHIFT or mask SS_RSHIFT
		jz	done
		;
		; Freeze all input and drawing, waiting for a command to be
		; delivered in another call to us.
		;
		call	InputFreeze
consumed:
		clr	al		; Indicate data consumed
done:
		ret
checkState:
		;
		; Let all state-change keys pass through. Shouldn't affect
		; any UI objects and makes sure the IM tracks the state of
		; the modifiers correctly, since it insists on keeping a
		; local copy of the modifier state...
		;
		test	dl, mask CF_STATE_KEY
		jnz	done
		jmp	consumed
frozen:
		;
		; First check for keyboard commands.
		;
		cmp	di, MSG_META_KBD_CHAR
		jne	notKbdChar
		test	ds:[inState], mask IS_COMMAND_SENT
		jnz	checkState		; do nothing if command already
						;  sent to process thread.
		test	dl, mask CF_RELEASE	; Only interested in presses.
		jnz	checkState
if DBCS_PCGEOS
		tst	dh
		jne	checkCursor	; Control/Shift? Try arrows!
		cmp	ch, CS_CONTROL_HB
		jne	consumed	; Not custom => not interesting, but
					;  don't let the event through.
		cmp	cx, C_SYS_ESCAPE
		jne	checkFuncs
else
		cmp	ch, CS_CONTROL
		jne	consumed	; Not ctrl => not interesting, but don't
					;  let the event through.
		cmp	cl, VC_ESCAPE
		jne	checkFuncs
endif
		;
		; Escape hit while frozen => thaw the screen and get out
		;
		call	InputThaw
		jmp	consumed
checkFuncs:
		;
		; See if the event is for one of the function keys we handle.
		;
if DBCS_PCGEOS
		cmp	cx, C_SYS_F1
		jb	checkPrtScr
		cmp	cx, C_SYS_F1 + length funcTable
		jae	checkCursor
		mov	bx, offset funcTable
		sub	cx, C_SYS_F1
CheckHack< (C_SYS_F2 - C_SYS_F1) eq 1 >
else
		cmp	cl, VC_F1
		jb	checkCursor
		cmp	cl, VC_F1 + length funcTable
		jae	checkCursor
		mov	bx, offset funcTable
		sub	cl, VC_F1
CheckHack< (VC_F2 - VC_F1) eq 1 >
endif
		;
		; Turn key into index into table (bx) and call the proper
		; handler (cl already has base key value removed)
		;
callTable:
		clr	ch
		shl	cx
		add	bx, cx
		mov	bx,cs:[bx]
		tst	bx
		jz	consumed
		call	bx
		jmp	consumed

checkCursor:
		test	ds:inState, mask IS_RECTDRAWN
		jz	checkPrtScr	; rect not drawn, so can't do anything
					;  with any cursor key that might be
					;  hit... PrtScr ignored if rect up
if DBCS_PCGEOS
		cmp	cx, C_SYS_UP
		jb	checkKeypad
		cmp	cx, C_SYS_UP + length cursorTable
		jae	checkKeypad
else
		cmp	cl, VC_UP
		jb	checkKeypad
		cmp	cl, VC_UP + length cursorTable
		jae	checkKeypad
endif
		;
		; See if we got the arrow key with the shift (we assume we did
		; if NUMLOCK is set). If so, add SS_LSHIFT into the shift state
		; so the handler knows this.
		;
		test	bp, mask TS_NUMLOCK
		jz	10$
		or	dh, mask SS_LSHIFT
10$:
		mov	bx, offset cursorTable
SBCS<		sub	cl, VC_UP				>
DBCS<		sub	cx, C_SYS_UP				>
		jmp	callTable
checkKeypad:
		;
		; Deal with dual value for cursor keys. If the key is any
		; numeric on the keypad but 5, treat it as a cursor
		; key. Note that the reverse check for setting the shift
		; bit in dh is true here -- if NUMLOCK is set, we got this
		; key w/o a shift.
		;
if DBCS_PCGEOS
		cmp	cx, C_SYS_NUMPAD_1
		jb	checkState
		cmp	cx, C_SYS_NUMPAD_9
		ja	checkState
		cmp	cx, C_SYS_NUMPAD_5
		je	consumed
		sub	cx, C_SYS_NUMPAD_1
else
		cmp	cl, VC_NUMPAD_1
		jb	checkState
		cmp	cl, VC_NUMPAD_9
		ja	checkState
		cmp	cl, VC_NUMPAD_5
		je	consumed
		sub	cl, VC_NUMPAD_1
endif
		mov	bx, offset keypadTable
		test	bp, mask TS_NUMLOCK
		jnz	callTable
		or	dh, mask SS_LSHIFT
		jmp	callTable
notKbdChar:
		;
		; Must be a PTR_CHANGE or BUTTON_CHANGE event.
		;
		cmp	di, MSG_IM_PTR_CHANGE
		jne	checkButton
		call	InputPtrChange
		jmp	consumed
checkButton:
		cmp	di, MSG_IM_BUTTON_CHANGE
		jne	notButton
		call	InputButtonChange
notButton:
toConsumed:
		jmp	consumed

checkPrtScr:
SBCS<		cmp	cl, VC_PRINTSCREEN			>
DBCS<		cmp	cx, C_SYS_PRINT_SCREEN			>
		jne	toConsumed
		call	InputDumpScreen
		jmp	consumed
InputMonitor	endp



Resident	ends
