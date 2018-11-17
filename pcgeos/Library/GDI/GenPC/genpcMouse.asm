COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		genpcMouse.asm

AUTHOR:		Todd Stumpf, Apr 30, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96   	Initial revision


DESCRIPTION:
	
		

	$Id: genpcMouse.asm,v 1.1 97/04/04 18:04:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include		win.def
include		Internal/grWinInt.def
include		Internal/videoDr.def	; for gross video-exclusive hack
include		Internal/im.def
include		genpcConstant.def
include		genpcMacro.def
include	        timer.def
include		ec.def			; ec and heap needed for assert, ugh
include		heap.def
include		assert.def			

idata	segment

mouseSet	byte	0	; non-zero if device-type set

MOUSE_NUM_RATES	equ	0
idata	ends

InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWPointerInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform the hardware dependent pointer initialization here	

CALLED BY:	GDIPointerInit (GDI driver)
PASS:		nothing
RETURN:		ax -> pointer error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: mainly taken form genmouse with a few changes 
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWPointerInit	proc	near
		.enter
		dec	ds:[mouseSet]

		mov	bx, 3		; Early LogiTech drivers screw up and
					;  restore all registers, so default
					;  number of buttons to 3.
		call	MouseReset
	;
	; The mouse driver initialization returns bx == # of buttons
	; on the mouse. Some two-button drivers get upset if we request
	; events from the third (non-existent) button, so we check the
	; number of buttons available, and set the mask accordingly.
	;	mov	ds:[DriverTable].MDIS_numButtons, bx
	;
	; save mouse buttons until it is asked for in GDIPointerInfo
;		Assert	dgroup, ds		; screws up swat?
		mov	ds:[numButtons], bx
		mov	bp, bx
		mov	cx, 1fh			;cx <- all events (2 buttons)
		cmp	bx, 2
		je	twoButtons
		mov	cx, 7fh			;cx <- all events (3 buttons)
twoButtons:
		segmov	es, CallbackCode, dx	; Set up Event handler
		mov	dx, offset CallbackCode:MouseDevHandler
		mov	ax, MF_DEFINE_EVENT_HANDLER
		SendToMouseDriver

	;
	; Set the bounds over which the mouse is allowed to roam to match
	; the dimensions of the default video screen, if we can...
	;
	 	mov	ax, GDDT_VIDEO
	 	call	GeodeGetDefaultDriver	;ax <- default video
	 	tst	ax
	 	jz	done
	 	mov_tr	bx, ax
	 	
	 	push	ds
	 	call	GeodeInfoDriver
	 	mov	cx, ds:[si].VDI_pageW
	 	mov	dx, ds:[si].VDI_pageH
	 	pop	ds
	 	
	 	push	cx
	 	clr	cx		; min Y is 0, max Y in dx
	  	
	 	mov	ax, MF_SET_Y_LIMITS
		SendToMouseDriver
	 	
	 	pop	dx		; dx <- max X
	 	clr	cx		; min X is 0
	 	mov	ax, MF_SET_X_LIMITS
	 	SendToMouseDriver

if NT_DRIVER and 0
	; 
	; Create a timer for polling the mouse.
	;
		mov	al, TIMER_ROUTINE_CONTINUAL
		mov	bx, segment MousePoller
		mov	si, offset MousePoller
		mov	cx, 1			; ticks to start
		mov	di, cx			; ticks between routine calls

		call	TimerStart
	; FIXME:  I should stop this timer at some time ...
endif
		
done:
		mov	ax, EC_NO_ERROR			; no error
		.leave
		ret
HWPointerInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	HWPointerInit
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY: taken from genmouse
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FAKE_GSTATE	equ	1		; bogus GState "handle" passed to
					;  the video driver as the exclusive
					;  gstate. The driver doesn't care if
					;  the handle's legal or not. Since we
					;  can't get a legal one w/o a great
					;  deal of work, we don't bother.

bogusStrategy	fptr.far	farRet

PointerCode	segment	resource
farRet:		retf
PointerCode	ends

MouseReset	proc	far	uses cx, dx, di, ds, si, bp
		.enter
	;
	; Assume no video driver around -- makes life easier
	; 
		segmov	ds, cs
		mov	si, offset bogusStrategy - offset DIS_strategy

		push	bx
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver
		mov	bx, ax
		tst	bx
		jz	haveDriver
		call	GeodeInfoDriver

haveDriver:
		mov	bx, FAKE_GSTATE
		mov	di, DR_VID_START_EXCLUSIVE
		call	ds:[si].DIS_strategy
		
	;
	; Reset the DOS-level driver, now the system is protected from its
	; potential for messing with video card registers.
	;
		pop	bx		; recover default # buttons (in
					;  some cases)

		mov	ax, MF_RESET
		SendToMouseDriver
if NT_DRIVER
		mov	bx, 2		; assume two button mouse
endif
		
	;
	; Release the video driver now the mouse driver reset is accomplished
	; 
		push	ax, bx
		mov	di, DR_VID_END_EXCLUSIVE
		mov	bx, FAKE_GSTATE
		call	ds:[si].DIS_strategy

		tst	ax		; any operation interrupted?
		jz	invalDone	; no

		mov	ax, si		; ax <- left
		push	di		; save top
		call	ImGetPtrWin	; bx <- driver, di <- root win
		pop	bx		; bx <- top

		tst	di
		jz	invalDone

	;	segmov	ds, dgroup, si
	;	test	ds:[mouseStratFlags], mask MOUSE_SUSPENDING
	;	jnz	invalDone
		
	  	clr	bp, si		; rectangular region, thanks
	 	call	WinInvalTree
invalDone:
		pop	ax, bx
		.leave
		ret
MouseReset	endp



InitCode		ends

CallbackCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse handler routine to take the event and pass it to
		MouseSendEvents

CALLED BY:	EXTERNAL

PASS:		ax	- mask of events that occurred:
				b0	pointer motion
				b1	left down
				b2	left up
				b3	right down
				b4	right up
				b5	middle down
				b6	middle up
		bx	- button state
				b0	left
				b1	right
				b2	middle
			  1 => pressed
		cx	- X position
		dx	- Y position

RETURN:		Nothing

DESTROYED:	Anything (Logitech driver saves all)

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	7/19/89		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
if NT_DRIVER
	.enter
endif
if not NT_DRIVER
	  	clr	cx		; Assume not motion
	 	clr	dx
	  	test	ax, mask ME_MOTION
	 	jz	mangleButtons
endif
		mov	ax, MF_READ_MOTION
		SendToMouseDriver
if NT_DRIVER
		mov	bx, ax
endif
		
	mangleButtons:
		;
		; Load dgroup into ds. We pay no attention to the event
		; mask we're passed, since MouseSendEvents just works from the
		; data we give it. So we trash AX here.
		;
		mov	ax, dgroup
		mov	ds, ax
if not NT_DRIVER
		;
		; Now have to transform the button state. We're given
		; <M,R,L> with 1 => pressed, which is just about as bad as
		; we can get, since MouseSendEvents wants <L,M,R> with
		; 0 => pressed. The contortions required to perform the
		; rearrangement are truly gruesome.
		;
		andnf	bx, 7		; Make sure high bits are clear (see
					; below)
		shr	bl, 1		; L => CF
		rcl	bh, 1		; L => BH<0>
		shl	bh, 1		; L => BH<1>
		shl	bh, 1		; L => BH<2>
		or	bh, bl		; Merge in M and R
		not	bh		; Invert the sense (want 0 => pressed)
					; and make sure uncommitted bits all
					; appear as UP.
	; gemmouse passed delta values so set bit to pass on this info
	  	ornf	bx, 255
endif
		;	
		; Ship the events off.
		;
	; pass on pointer info to GDI driver
		mov	di, offset pointerCallbackTable
		mov	bp, offset GDINoCallback
	;		call	GDICallCallbacks
		;; Eventually, this calls GDIPtrCallback.
		call	GDIHWGenerateEvents
if NT_DRIVER
	.leave
;		VDDUnSimulate16
		nop
endif
		ret
MouseDevHandler	endp

if NT_DRIVER
MousePoller	proc	far
	.enter
		mov	ax, 100
		SendToMouseDriver
	.leave
	ret
MousePoller	endp
endif
CallbackCode	ends

ShutdownCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWPointerShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWPointerShutdown	proc	near
	.enter
		tst	ds:[mouseSet]
		jz	done
		call	MouseReset

		clr	dx
		mov	es, dx			; NULL event handler address
		mov	ax, MF_DEFINE_EVENT_HANDLER
		clr	cx			; No events
		SendToMouseDriver

	; 	segmov	ds, dgroup, bx
	; 	mov	bx, offset mouseMonitor
	; 	mov	al, mask MF_REMOVE_IMMEDIATE
	; 	call	ImRemoveMonitor
		clc				; No errors
done:

	.leave
	ret
HWPointerShutdown	endp

ShutdownCode		ends










