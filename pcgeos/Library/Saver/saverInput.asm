COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Lights Out
MODULE:		Input filtering
FILE:		saverInput.asm

AUTHOR:		Adam de Boor, Dec  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 9/92	Initial revision


DESCRIPTION:
	Functions for coping with the various wakeup and input options
		
	Perhaps we need a semaphore to protect these things? There's only
	supposed to be one master saver around, but you never know...

	$Id: saverInput.asm,v 1.1 97/04/07 10:44:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

siWakeupMonitor	Monitor	<>
siWakeupOptions	SaverWakeupOptions
siInputOptions	SaverInputOptions

idata	ends


SaverAppCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SIStartWakeupMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start monitor for wakeup

CALLED BY:	(EXTERNAL) SAStart

PASS:		ds:di	= SaverApplicationInstance
		al	= SaverWakeupOptions
		ah	= SaverInputOptions

RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SIStartWakeupMonitor	proc	near
		uses	ds
		.enter
	;
	; Insist on some means of waking the thing up...
	; 
		test	al, mask SaverWakeupOptions
		jnz	optionsOK
		ornf	al, mask SWO_KEY_PRESS
optionsOK:
		segmov	ds, dgroup, bx
	;
	; Install an input monitor to check for wakeup
	;
			CheckHack <siInputOptions-siWakeupOptions eq 1 and \
				   size siInputOptions eq 1>
		mov	{word}ds:[siWakeupOptions], ax

		mov	bx, offset siWakeupMonitor
		mov	al, ML_DRIVER		; after the driver but before
						;  Welcome
		mov	cx, segment SIWakeupRoutine
		mov	dx, offset SIWakeupRoutine
		call	ImAddMonitor

		.leave
		ret
SIStartWakeupMonitor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SIRemoveWakeupMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill monitor for monitoring wakeup

CALLED BY:	(INTERNAL) SAStop

PASS:		ds:di	= SaverApplicationInstance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SIRemoveWakeupMonitor	proc	near
		uses	ax, bx, ds
		.enter

		mov	al, mask MF_REMOVE_IMMEDIATE
		segmov	ds, <segment siWakeupMonitor>, bx
		mov	bx, offset siWakeupMonitor	;ds:bx <- ptr to monitor
		call	ImRemoveMonitor

		.leave
		ret
SIRemoveWakeupMonitor	endp

SaverAppCode	ends

SaverFixedCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SIWakeupRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we should wake up or not

CALLED BY:	im::ProcessUserInput

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		MSG_IM_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data
		ds 	= seg addr of monitor

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)
		
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SIWakeupRoutine	proc	far
		.enter

		test	al, mask MF_DATA
		jz	done
	;
	; A mouse move?
	;
		cmp	di, MSG_IM_PTR_CHANGE
		jne	notMouseMove
	;
	; Special case null ptr events, since we probably sent them.
	; Null ptr events are relative (0,0).
	;
		test	bp, mask PI_absX or mask PI_absY
		jnz	isMouseMove			;branch if not relative
		push	cx
		or	cx, dx
		pop	cx
		jz	notMouseMove			;branch if (0,0)
isMouseMove:
		test	ds:[siWakeupOptions], mask SWO_MOUSE_MOVE
		jz	consumeMe
notMouseMove:
	;
	; A mouse button press?
	;
		cmp	di, MSG_IM_BUTTON_CHANGE
		jne	notMousePress
		test	ds:[siWakeupOptions], mask SWO_MOUSE_PRESS
		jz	consumeMe
notMousePress:
	;
	; A key press?
	;
		cmp	di, MSG_META_KBD_CHAR
		jne	notKeypress

		test	ds:[siWakeupOptions], mask SWO_KEY_PRESS
		jnz	maybeConvertKbdToPtr
consumeMe:
	;
	; We don't want to wake up, so consume the event
	; 
		clr	al			; gulp...
notKeypress:
done:

		.leave
		ret

maybeConvertKbdToPtr:
	;
	; If told to consume keypresses on wakeup, we still want to wakeup,
	; so consume this event and send the appropriate message to the IM.
	; (Can't just use a 0,0 relative ptr message as in 1.x, as that
	; no longer causes a wakeup, it being judged (rightly) to not have been
	; generated by the user...)
	; 
		test	ds:[siInputOptions], mask SIO_CONSUME_KEYPRESSES
		jz	done
		
		call	ImInfoInputProcess	; bx = IM handle
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_IM_DEACTIVATE_SCREEN_SAVER
		call	ObjMessage

		jmp	short	consumeMe		

SIWakeupRoutine	endp

SaverFixedCode	ends
