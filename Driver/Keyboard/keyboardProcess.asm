COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Keyboard Driver
FILE:		keyboardProcess.asm

AUTHOR:		Adam deBoor, Doug Fults, Gene Anderson

ROUTINES:
	Name			Description
	----			-----------
	KbdStrategy		Driver strategy routine

	KbdChangeEventDest	Set process handle to send output to
	KbdXlateScan		Translate scan value to full char info
	KbdGetMap		Return ptr to keyboard map

	KbdMonRoutine		Monitor program for translating
				MSG_KBD_SCAN to MSG_META_KBD_CHAR events

	KbdInterrupt		Driver interrupt routine
	ProcessKeyElement	Processes entire key event
	FindScanCode		Looks up codes in keysDownList
	ProcessScanCode		Convert scan codes to char values
	HandleExtendedDef
	HandleNormalDef
	ProcessStateRelease	Clear state flags when shift & modifier keys
					go up
	AccentTranslation	Peforms lone-accent + char translation

	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	adam	6/8/88	Initial Revision
	doug	7/19/88 Pirated file from Adam's com43 program, reworked
			for PC GEOS
	gene	8/29/89	Added DR_KBD_GET_MAP for changing keyboard map
	gene	8/31/89	Major cleanup
	gene	9/4/89	Changed extended table to handle <shift><ctrl><alt>
	gene	2/8/90	Broke into separate files

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	The keyboard interrupt vector is being replaced here, in the
	routines SetInterrupt & ResetInterrupt. We should be calling
	something in the kernel to do this.


DESCRIPTION:
	The routines in this module manage the IBM PC keyboard. 

	$Id: keyboardProcess.asm,v 1.1 97/04/18 11:47:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keyboard driver strategy routine

CALLED BY:	EXTERNAL
-------------------------------------------------------------------------------
	PASS:	di	- DR_INIT
	RETURN: carry	- set if error
-------------------------------------------------------------------------------
	PASS:	di	- DR_EXIT
	RETURN: carry	- set if error
-------------------------------------------------------------------------------
	PASS:	di	- DR_KBD_GET_KBD_STATE
	RETURN:	al	- current shiftState
		ah	- current toggleState
		bx	- current process handle receiving METHOD_KBD_SCAN
		cl	- current xState1
		ch	- current xState2
		dl	- current kbdModeIndState
		dh	- current kbdTypematic state
		es:si	- pointer to current DownList element
			(or segment = 0 if no last element)
		carry	- set if error
-------------------------------------------------------------------------------
	PASS:	di	- DR_KBD_SET_KBD_STATE
		ah	- Flags for which Kbd state items to set:
			  Bit 7 set for new process handle
			  Bit 6 set for new modIndState
			  Bit 5 set for new typematic rate & delay

		bx	- handle of process to send output to
		cl	- new modIndState value
		ch	- new typematic rate & delay
	RETURN:	carry	- set if error
-------------------------------------------------------------------------------
	PASS:	di	- DR_KBD_XLATE_SCAN
		cx	- Scan code
	RETURN: di	- METHOD_KBD_CHAR
		cx, dx, bp, si	- keyboard char info
		al	- flags:	bit 0 set if data being returned
					bit 1 set if more to come
		carry	- set if error
-------------------------------------------------------------------------------
	PASS:	di	- DR_KBD_GET_MAP
	RETURN:	carry	- set if error
-------------------------------------------------------------------------------

DESTROYED:	???

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	???		Initial version
	Gene	9/89		Major rewrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idataSegment	word	idata			;for ease of loading

KbdStrategy	proc	far
	push	ds
EC <	cmp	di, KbdFunction		;see if legal function>
EC <	ERROR_AE	KBD_BAD_ROUTINE		;>
	mov	ds, cs:idataSegment		;ds <- seg addr of idata
	cmp	di, MIN_NON_EXCLUSIVE		;see if we need the semaphore
	jae	noExclusive			;branch if we don't
	PSem	ds, semKbdStrat			;one at a time, please
	call	cs:kbdFuncList[di]		;call appropriate function
	VSem	ds, semKbdStrat			;doesn't destroy carry...
	pop	ds
	ret

noExclusive:
	call	cs:kbdFuncList[di]		;call appropriate function
	pop	ds
	ret
KbdStrategy	endp

kbdFuncList	label	word
;
; Following require exlusive access:
;
	word	offset Resident:KbdInit		;DR_INIT
	word	offset Resident:KbdExit		;DR_EXIT
	word	offset Resident:KbdSuspend	;DR_SUSPEND
	word	offset Resident:KbdUnsuspend	;DR_UNSUSPEND
	word	offset Resident:KbdGetState	;DR_KBD_GET_STATE
	word	offset Resident:KbdSetState	;DR_KBD_SET_STATE
	word	offset Resident:KbdXlateScan	;DR_KBD_XLATE_SCAN
	word	offset Resident:KbdAddHotkeyStub;DR_KBD_ADD_HOTKEY
	word	offset Resident:KbdDelHotkeyStub;DR_KBD_REMOVE_HOTKEY
;
; Following don't require exclusive access:
;
	word	offset Resident:KbdChangeOutput	;DR_KBD_CHANGE_OUTPUT
	word	offset Resident:KbdMapKey	;DR_KBD_MAP_KEY
	word	offset Resident:KbdCheckShortcut ;DR_KBD_CHECK_SHORTCUT
	word	offset Resident:KbdPassHotkey	;DR_KBD_PASS_HOTKEY
	word	offset Resident:KbdCancelHotkey	;DR_KBD_CANCEL_HOTKEY

KbdInit	proc	near
	call	KbdInitFar
	ret
KbdInit	endp

KbdExit	proc	near
	call	KbdExitFar
	ret
KbdExit	endp

KbdSuspend proc near
	;
	; Only call far version if it'll do anything (namely resetting the
	; command byte).
	; 
	test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK
	jnz	done
	call	KbdSuspendFar
done:
	ret
KbdSuspend endp

KbdUnsuspend proc near
	test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK
	jnz	done
	call	KbdUnsuspendFar
done:
	ret
KbdUnsuspend endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets internal variable so that driver knows where to send
		output events.

CALLED BY:	EXTERNAL

PASS:		di	- DR_KBD_SET_STATE
		ah	- Flags for which Kbd state items to set:
			  Bit 7 set for new process handle
			  Bit 6 set for new modIndState
			  Bit 5 set for new typematic rate & delay

		bx	- handle of process to send output to
		cl	- new modIndState value
		ch	- new typematic rate & delay

RETURN:		carry	- clear if no error

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	if setting handle, store passed handle into kbdOutputProcHandle;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/5/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSetState	proc	near
	shl	ah, 1				;bit 7 into carry
	jnc	KSS_10				;branch if not changing dest.
						;  process
	mov	ds:[kbdOutputProcHandle], bx
KSS_10:
	shl	ah, 1				;bit 6 into carry
	jnc	KSS_20				;branch if not setting mode
						;  indicator
	mov	al, cl				;al <- new mode indicator state
	xor	al, ds:[kbdModeIndState]	;al <- differences
	mov	ds:[kbdModeIndState], cl	;store new indicator state
	xor	al, ds:[kbdToggleState]		;change toggle as well
	mov	ds:[kbdToggleState], al		;store new toggle state
	push	ax
	call	SetIndicatorState		;send to keyboard
	pop	ax
KSS_20:
	shl	ah, 1				;bit 5 into carry
	jnc	KSS_30				;branch if not setting
						;  typematic
	mov	ds:[kbdTypematicState], ch	;store new typematic rate
	call	SetTypematicState		;send to keyboard
KSS_30:
	clc					;indicate no error
	ret
KbdSetState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdMonRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description
CALLED BY:	EXTERNAL: InputManager

PASS:		di	- EVENT TYPE, or 0 if request for more data
		ds	= segment of kbdMonitor (dgroup)
RETURN:		if (di == MSG_KBD_SCAN && cx == scancode) {
		    di - MSG_META_KBD_CHAR
		    cx, dx, bp, si - keyboard char data
		    al - bit 0 set if data being returned
			 bit 1 set if more to come
		} else {
		    none
		}

DESTROYED:	ax, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/22/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdMonRoutine	proc	far
	cmp	di, MSG_IM_KBD_SCAN	; if not keyboard scan, quit
	jne	KM_done
	call	KbdXlateScan		; translate the scan
KM_done:
	ret

KbdMonRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdXlateScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description
CALLED BY:	EXTERNAL: DR_KBD_XLATE_SCAN
		INTERNAL: KbdMonRoutine

PASS:		cx	- scan code
RETURN:		di	- MSG_META_KBD_CHAR
		cx, dx, bp, si	- kbd char data
		al	- flags: bit 0 set if data being returned
				 bit 1 set if more to come
		carry	- set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/29/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdXlateScan	proc	near
	mov	ax, cx				;scan code in ax
	call	ProcessKeyElement		;process key element -- 
						;	place/update
						;	keysDownList,
						;	if new press generate
						;	charValue
	jc	XS_NoData			;exit if error in keysDownList
	test	ds:[si].KDE_charFlags, mask CF_FIRST_PRESS
	jz	XS_10				;branch if not first press
	test	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
	jnz	XS_10				;branch if already have accent
	call	AccentTranslation		;if new press, do accent
XS_10:
						;get ALL DATA from element
	mov	cx, ds:[si].KDE_charValue	;cx <- char value
	mov	dl, ds:[si].KDE_charFlags	;dl <- char flags
	mov	dh, ds:[si].KDE_shiftState	;dh <- shift state
	mov	al, ds:[si].KDE_toggleState	;al <- toggle state
	mov	ah, ds:[si].KDE_scanCode	;ah <- scan code
	mov	bp, ax				;copy to bp

	test	dl, mask CF_RELEASE		;test for release
	jz	XS_20				;branch if not release
	mov	ds:[si].KDE_scanCode, 0		;else free element
XS_20:
	test	dl, mask CF_STATE_KEY		;see if state key
	jz	XS_100				;if state key, don't repeat
	test	dl, mask CF_REPEAT_PRESS	;see if repeat
	jnz	XS_NoData			;if repeat, send no char
XS_100:
	mov	di, MSG_META_KBD_CHAR		;di <- return method
	mov	al, mask MF_DATA
	clc
	ret
XS_NoData:
	clr	al				; show no data being returned
	clc
	ret
KbdXlateScan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdChangeOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change where the keyboard driver sends its scan-code
		events

CALLED BY:	DR_KBD_CHANGE_OUTPUT
PASS:		bx	= new output handle
		ds	= dgroup (passed by KbdStrategy)
RETURN:		bx	= old output handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdChangeOutput proc	near
		.enter
		xchg	ds:[kbdOutputProcHandle], bx
		.leave
		ret
KbdChangeOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns assorted info about current keyboard state
CALLED BY:	EXTERNAL

PASS:		none
RETURN:		al	- current ShiftState
		ah	- current ToggleState
		bx	- current process handle receiving MSG_KBD_SCAN
		cl	- current xState1
		ch	- current xState2
		dl	- current kbdModeIndState
		dh	- current kbdTypematic state
		es:si	- pointer to current DownList element
			(or es = 0 if no last element)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdGetState	proc	near
	mov	al, ds:[kbdShiftState]
	mov	ah, ds:[kbdToggleState]
	mov	bx, ds:[kbdOutputProcHandle]
	mov	cl, ds:[kbdXState1]
	mov	ch, ds:[kbdXState2]
	mov	dl, ds:[kbdModeIndState]
	mov	dh, ds:[kbdTypematicState]
	les	si, ds:kbdCurDownElement
	ret
KbdGetState	endp

ifidn	HARDWARE_TYPE, <PC>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	keyboard interrupt routine
CALLED BY:	EXTERNAL

PASS: 		keysDownList
		kbdStateFlags
		kbdLastChar
RETURN:		none
DESTROYED:	Nothing at all -- we're interrupt code!

PSEUDO CODE/STRATEGY:
		save registers we can't trash at interrupt time;
		if data waiting in keyboard buffer [
		    read data;
		    if keyboard response (ACK or above) [
			If RESEND, resend else [
			    move queue up to remove last byte;
			    send next byte if queue not empty;
			]
		    ] else [
			send event containing scan code;
		] else error;
		signal interrupt controller that interrupt is complete;
		restore registers;
		return (from interrupt);

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/29/88		Initial version
	Doug	8/19/88		Changed so that int routine sends scan code
				only, moving translation code to IOCTL routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdInterrupt	proc	far
	push	ax, bx, cx, dx, si, di, bp, ds, es
	call	SysEnterInterrupt
	cld					;clear direction flag
	INT_ON

	mov	ax, segment idata
	mov	ds,ax				;ds <- seg addr of driver
	mov	es, ax				; es too, for KbdCheckHotkey

	;
	; 12/15/92: HACK added to deal with bogus BIOS in IBM PS/2 Model 40SX,
	; which disables the both the keyboard and aux device interfaces in
	; the 8042 before requesting the command byte, then loops waiting for
	; KSB_OUTPUT_BUFFER_FULL to become set. Unfortunately, with the
	; keyboard interface disabled (in some configurations), it ends up
	; never setting the bit. This doesn't happen all the time, but it
	; happens regularly enough. Since this doesn't seem to perturb its
	; operation, this might all be ok, except it also likes to generate
	; a keyboard interrupt, with the KSB_OUTPUT_BUFFER_FULL clear, and the
	; keyboard command byte (which looks like garbage [77h]) sitting in
	; the output buffer for us to read and misinterpret.
	;
	; To get around this brain-damage, if the thing's an AT, and the
	; output-buffer-full bit isn't set, we hand control off to the old
	; handler. -- a&g
	;
	; Furthermore, it will continue to interrupt until we read the
	; *(&*(U&^Y data port, so we do that...
	; 
	test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK
	jnz	getData

	in	al, KBD_STATUS_PORT
	test	al, mask KSB_OUTPUT_BUFFER_FULL
	jnz	getData
	in	al, KBD_DATA_PORT
	jmp	KINT_Done

getData:
	in	al, KBD_DATA_PORT		;read in from KBD_DATA_PORT

	

	or	al, al	
	jz	KINT_40				;if KBD_RESP_OVERRUN done
	cmp	al, KBD_RESP_ACK		;see if scancode (<ACK)
	jb	KINT_ScanCode

	test	ds:[kbdStratFlags], mask KSF_SENDING
	jz	KINT_ScanCode			;if not sending, medium rare

	cmp	al, KBD_RESP_RESEND		;resend command?
	je	KINT_20				;branch to handle resend
						;INTS are OFF here
						;ELSE assume is ACK, move up Q
	dec	ds:[kbdSQSize]			;dec # of items left to send
	je	KINT_30				;if none left, done sending
	mov	cx, size kbdSendQueue - 1	;else move items left up
	mov	bx, offset kbdSendQueue
KINT_10:
	mov	al, ds:[bx] + 1
	mov	ds:[bx] + 0, al
	inc	bx
	loop	KINT_10
KINT_20:
;
;send next byte
;
	mov	al, ds:[kbdSendQueue + 0] 	;get next char
	out	KBD_DATA_PORT, al		;out to KBD_DATA_PORT
	jmp	KINT_40
KINT_30:
	andnf	ds:[kbdStratFlags], not mask KSF_SENDING	;clear bit
KINT_40:
	jmp	short KINT_Done


KINT_ScanCode:
						; AL = SCAN CODE
	cmp	al, ds:KbdExtendedScanCodes[0]
	je	KINT_Extension			;branch if PS/2 extension
	cmp	al, ds:KbdExtendedScanCodes[1]
	je	KINT_Extension			;branch if PS/2 extension
	cmp	al, ds:KbdExtendedScanCodes[2]
	je	KINT_Extension			;branch if PS/2 extension
	cmp	al, ds:KbdExtendedScanCodes[3]
	je	KINT_Extension			;branch if PS/2 extension


	mov	ah, ds:[kbdScanExtension]	;get high byte of scan code
	tst	ah
	jnz	mustBeOurs
	mov	dl, al
	and	dl, not (KBD_RELEASE_FLAG)	;high bit set on release
	cmp	dl, KBD_MAX_SCAN		;if the scan code is outside
	jae	passOffToOldDriver		; the range of legal ones,
						; there's nothing we can do,
						; but there might be something
						; the previous driver can do,
						; so we pass the buck. (e.g.
						; the mouse buttons on this
						; *&!*UY! French PC we got in
						; are sent as out-of-bounds
						; keyboard scan codes)
mustBeOurs:
	mov	ds:[kbdScanExtension], 0	;clear for next time
						; stuff scan code into event
	call	KbdCheckHotkey
	jc	KINT_Done			; => hotkey was taken, so don't
						;  do anything else here.

	mov	cx, ax				;cx <- key event
	mov	bx, ds:[kbdOutputProcHandle]	;bx <- handle of proc
	cmp	bx, 0ffffh			;see if no recipient defined.
	je	KINT_Done			;branch if no proc

	clr	dx
	clr	bp
	clr	si				;don't send driver handle

	mov	ax, MSG_IM_KBD_SCAN
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage			;send kbd message to proc
	jmp	KINT_Done

KINT_Extension:
	mov	ds:[kbdScanExtension], al	;store scan extension
KINT_Done:
	test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK ;see if sending to kbd
	jz	noAck
;
; On a PC so we need to acknowledge/reset the latches by
; strobing the high bit of port 61h
;
	in	al, KBD_PC_CTRL_PORT
	mov	ah, al
	or	al, KBD_ACKNOWLEDGE
	out	KBD_PC_CTRL_PORT, al
	mov	al, ah
	out	KBD_PC_CTRL_PORT, al

noAck:
	mov	al, ICEOI
	out	ICEOIPORT,al			;signal general end-interrupt

done:
	call	SysExitInterrupt		;Allow pending context switch
	pop	ax, bx, cx, dx, si, di, bp, ds, es
	iret

passOffToOldDriver:
	;
	; Pass the scan code off to the previous driver (note we have not and
	; will not acknowledge the scan code we got. Presumably the earlier
	; [BIOS-internal] driver will do the right thing with it...if it
	; doesn't, we're hosed). We call, rather than jump, to maintain our
	; lock on context-switching.
	;
	pushf
	call	ds:kbdVector
	jmp	done
KbdInterrupt	endp
endif


if	VG230SCAN

	.186

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	keyboard interrupt routine for Jedi Device
CALLED BY:	EXTERNAL

PASS: 		keysDownList
		kbdStateFlags
		kbdLastChar

RETURN:		none
DESTROYED:	Nothing at all -- we're interrupt code!

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/29/88		Initial version
	Doug	8/19/88		Changed so that int routine sends scan code
				only, moving translation code to IOCTL routine
	Todd	11/21/94	Updates for Jedi

	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdInterrupt	proc	far
	uses	ds, es
	.enter
	pusha
	call	SysEnterInterrupt
	cld					;clear direction flag
	INT_ON

	mov	ax, segment idata
	mov	ds, ax				;ds <- seg addr of driver
	mov	es, ax				; es too, for KbdCheckHotkey

	;
	;  Read the character in from io 60h.  On the
	;  Jedi this generates a hardware interrupt that
	;  BIOS catches, and then reads in the character,
	;  translates it to the expected character and
	;  returns it to us.
	clr	ax
	in	al, KBD_DATA_PORT		;read in from KBD_DATA_PORT
	mov_tr	cx, ax				;cx <- key event


	mov	bx, ds:[kbdOutputProcHandle]	;bx <- handle of proc
	cmp	bx, 0ffffh			;see if no recipient defined.
	je	KINT_Done			;branch if no proc

	clr	dx, bp, si			; don't send driver handle

	mov	ax, MSG_IM_KBD_SCAN
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage			;send kbd message to proc

KINT_Done:
	;
	;  For some reason, you need to twiddle bits before
	;  the VG-230 is happy.  Why?  I dunno.  He's on
	;  third, and I don't give a darn...
	;
	in	al, KBD_PC_CTRL_PORT
	mov	ah, al
	or	al, KBD_ACKNOWLEDGE
	out	KBD_PC_CTRL_PORT, al
	mov_tr	al, ah
	out	KBD_PC_CTRL_PORT, al

	mov	al, ICEOI
	out	ICEOIPORT,al			;signal general end-interrupt

	call	SysExitInterrupt		;Allow pending context switch
	popa
	.leave
	iret
KbdInterrupt	endp

	.8086
endif

if		_E3G_KBD_SCAN

	.386

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keyboard interrupt routine for E3G Device
CALLED BY:	EXTERNAL

PASS: 		keysDownList
		kbdStateFlags
		kbdLastChar

RETURN:		none
DESTROYED:	Nothing at all -- we're interrupt code!

PSEUDO CODE/STRATEGY:
		Responders differs from other hardware platform since there
		is no BIOS support for keyboard processing.  What we have
		to do when we receive this interrupt is to scan a 8x10
		matrix to detect which key was pressed.  The scan will give
		us the row and column number of the key depressed.
		We plug the row and column number into the KeyScanCodeTable
		which will give us a scan code that corrisponds to the
		PC Extended Keyboard scan code.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/29/88		Initial version
	SH	5/9/95		Responder Version
	JimG	6/20/96		E3G common version

	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 E3G_KBD_COUNT_INTS
kbdIntCounter	word	0
kbdEvents	word	0
endif	;E3G_KBD_COUNT_INTS

KbdInterrupt	proc	far
if	 E3G_KBD_COUNT_INTS
		inc	cs:[kbdIntCounter]
endif	;E3G_KBD_COUNT_INTS
		
		uses	ds, es
		.enter
	;
	; Setup for processing the interrupt and disallow context switching.
	;
		pusha

		call	SysEnterInterrupt
		cld					;clear direction flag
		
	; Attempt to lock the keyboard/digitizer interlock.  If it fails,
	; don't do anything except acknowledge interrupt.  The interlock
	; mechanism should've turned off this interrupt so it won't happen
	; again until the other device is done with the kbd lines.
	;
PENE <		mov	cl, PKDID_KEYBOARD				>
PENE <		call	PeneKDILock					>
PENE <		jc	quickExit					>

		mov	ax, segment idata
		mov	ds, ax			;ds <- seg addr of driver
		mov	es, ax

    	; See if the special timer for the digitizer is running.  If so, it
	; means that another keypress came in before the timer expired after
	; the last keypress.  No big deal, just disable it so the callback
	; routine isn't actually called.
	;
PENE <		tst	ds:[kbdDigTimerRunning]				>
PENE <		jz	noTimerRunning					>
PENE <		clr	ds:[kbdDigTimerRunning]				>
PENE <		call	PeneTimerDisable				>
PENE <noTimerRunning:							>

		INT_ON
	;
	; Get the row interrupts.
	;
		KbdE3G_GetIntEnable		;ax = E3G_KBIntEnFlags
						; (or KBINTENFlag for Resp)
		push	ax
	;
	; Disable all row interrupts.
	;
		mov	ax, 0x0000
		KbdE3G_SetIntEnable
	;
	; Scan the 8x10 matrix to find the keys pressed.
	;
		mov	dx, offset ds:[kbdIntCols]
		call	KbdScanKeyMatrix
	;
	; All the pressed keys are now stored by row in KbdRows.  We now
	; take that vector, translate any pressed key to a scancode and
	; queue the scancode for the InputManager.
	;
		call	KbdQueueScanCodes
	;
	; Drive all lines to 0
	;
		mov	al, 0x00
		KbdE3G_SetScanOut
	;
	; Setup the scanmode and the debounce time (KBCTRL).
	;
		mov	al, KBD_POLL_MODE
		KbdE3G_SetCtrl
	;
	; Read the high keyboard return register (KBIN) to clear interrupt.
	;
		KbdE3G_GetInput
	;
	; Set the new interraupt handler vector.
	;
		mov	bx, segment Resident
		mov	cx, offset  Resident:KbdPoll
		mov	di, offset kbdInt

PENE <		mov	ax, PENE_KEYBOARD_IRQ				>
PENE <		call	SysCatchDeviceInterrupt				>
	;
	; Signal general end-interrupt.
	;
		mov	al, IC_GENEOI
		out	IC1_CMDPORT, al
	;
	; Enable all the row interrupts.
	;
		pop	ax
		KbdE3G_SetIntEnable
	;
	; Allow pending context switch
	;
quickExit2::
		call	SysExitInterrupt	
		popa
		.leave
		iret

PENE <quickExit:							>
PENE <		mov	al, IC_GENEOI					>
PENE <		out	IC1_CMDPORT, al					>
PENE <		jmp	quickExit2					>
KbdInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdScanKeyMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scans the 8x10 key matrix and stores each row value in the
		row array.

CALLED BY:	KbdInterupt, KbdPoll
PASS:		ds - dgroup
		dx - offset of column array in dgroup.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Column array updated in dgroup.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	5/ 9/95    	Initial version
	JimG	6/20/96		E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdScanKeyMatrix	proc	near
	;
	; Initalize the column counter.
	;
		mov	cx, KBD_NUM_COLS-1	; cx <- columns to drive
colLoop:
	;
 	; Enable the column to drive.
	;
		mov	al, 1
		shl	al, cl			; 1 = enabled
	; 
  	; Drive the column.
	;		
		xor	al, KBD_SCAN_ALL_MASK		; Invert the bits

	push	dx						
	mov	dx, E3G_KBOUT					
	out	dx, al						

	; 
	; Delay for out lines to be set
	;
	jmp	$+2						
	jmp	$+2						
	jmp	$+2						

	;
	; Apparently, for Penelope (at least OP1), this needs to be a longer
	; delay.
	;
	; Well, the delay is different for OP1 and Olga.  Olga appears to
	; be even longer, really.  We haven't measured what it is yet,
	; though, so just make it a long time for now.
	;
_PAUSE::
PENE	<	push	cx						>

ifdef PENELOPE_OP1
PENE	<	mov	cx, 16						>
else	; OLGA----
PENE < PrintMessage <-- JimG: Determine delay needed for Olga KB lines >>
PENE	<	mov	cx, 1000					>
endif

PENE	<xxxx:	loop	xxxx						>
PENE	<	pop	cx						>
	;
	; Read the sensed row.
	;

	mov	dx, E3G_KBIN					
	in	ax, dx						
	and	ax, KBD_INT_ALL_MASK	; clear top 6 and other 
	pop	dx			; unused bits		
	;
 	; Store the row
	;
		mov	bx, cx				; bx <- column
		shl	bx				; size word
		add	bx, dx				; ds:di <- offset
		mov	ds:[bx], ax
	;
	; Loop around until cx is -1.
	;
		dec	cx
		cmp	cx, 0
		jge	colLoop
	;
	; RESPONDER ONLY:
	; Since keyboard hardware can not detect correctly if three keys are
	; held down we need to check for that case.  If one of the three keys
	; is the SHIFT key then we allow the keys else we discard all keys.
	;
	
	; 
	; PENELOPE: What hardware limitations are there for the penelope kbd?
	;
PENE < PrintMessage <-- JimG: Figure out h/w limits for penelope kbd>>
		ret
KbdScanKeyMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCheckKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Runs though all the columns and rows of the keyboard vector
		and checks if one of the keys is the SHIFT key or a function
		key.

CALLED BY:	KbdScanKeyMatrix
PASS:		ds - dgroup
		dx - offset of column array in dgroup.

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Column array updated if more than three keys are pressed and
		one of them is not the SHIFT key.

		Column array updated if two keys are pressed and one of them
		is a function key.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdQueueScanCodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a scancode from the row,col of the pressed key and
		queue the scancode to the input manager.

CALLED BY:	KbdInterrupt
PASS:		ds	- dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	5/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdQueueScanCodes	proc	near
	;
	; Bail if we don't have a valid proc handle.
	;
		mov	bx, ds:[kbdOutputProcHandle]		
		cmp	bx, 0ffffh		;see if no recipient defined.
		je	done			;branch if no proc
	;
	; Setup the offset into the KeyScanCodeTable.  We'll let the loop
	; take care of maintaining the correct offset.
	;
		mov	si, (KBD_NUM_COLS-1) * size KeyMatrixColumn
		mov	dx, KBD_NUM_COLS-1
colLoop:		
		mov	bx, dx
		shl	bx
		add	bx, offset ds:[kbdIntCols]
		mov	ax, ds:[bx]		; ax <- Row mask
	;
	; A key press was found, we have the column number in cx and
	; the row number in ax.
	;
		xor	ax, KBD_INT_ALL_MASK	; invert the bits
		tst	ax
		jz	cont
rowLoop:
		push	ax
	;
	; Convert the row bitvector to a corrisponding integer
	;
		mov	cx, 17
10$:
		shl	ax, 1
		loopne	10$
	;
	; Get the scan code from the 8x10 KeyScanCodeTable matrix.
	;
		mov	bx, si
		add	bx, offset ds:[KeyScanCodeTable]
		dec	cx			; First row at 0
		push	cx
		add	bx, cx			; add row number
		mov	cx, ds:[bx]		; cx <- scan code
		clr	ch
	;
	; Give the scan code to the input manager.
	;
		push	dx, si
		clr	dx, bp, si			; don't send driver hdl
		mov	bx, ds:[kbdOutputProcHandle]	; bx <- handle of proc
		mov	ax, MSG_IM_KBD_SCAN
		mov	di, mask MF_FORCE_QUEUE
if	 E3G_KBD_COUNT_INTS
		inc	cs:[kbdEvents]
endif	;E3G_KBD_COUNT_INTS
		call	ObjMessage			; send kbd msg to proc
		pop	dx, si
	;
	; Remove the row bit we have processed by xor'ing the bit out of
	; the bitvector.  If the bitvector is 0 when there are no more keys
	; in that row.
	;
		pop	ax, cx		; cx <- bit pos, ax <- bitvector
		mov	di, 1
		shl	di, cl
		xor	ax, di
		tst	ax
		jnz	rowLoop
cont:
	;
	; Loop until dx = -1
	;
		sub	si, size KeyMatrixColumn
		dec	dx
		cmp	dx, 0
		jge	colLoop
done:	
		ret		
KbdQueueScanCodes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdPoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called every 25 milliseconds when key is down.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	5/ 9/95    	Initial version
	JimG	6/20/96		Made into general purpose E3G version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdPoll	proc	far
		uses	es, ds
		.enter
	;
	; Setup for processing the interrupt and disallow context switching.
	;
		pusha
		call	SysEnterInterrupt
		cld					;clear direction flag
		INT_ON

		mov	ax, segment idata
		mov	ds, ax			;ds <- seg addr of driver
		mov	es, ax
	;
	; Get the row interrupts.
	;
		KbdE3G_GetIntEnable		;ax = E3G_KBIntEnFlags
						; (or KBINTENFlag for Resp)
		push	ax
	;
	; Disable all row interrupts.
	;
		mov	ax, 0x0000
		KbdE3G_SetIntEnable
	;
	; Update the counters.  
	;
		inc	ds:[kbdPollCount]
		inc	ds:[kbdRateCount]
	;
	; Scan the 8x10 key matrix to find what keys are pressed.
	;
		mov	dx, offset ds:[kbdPollCols]
		call	KbdScanKeyMatrix
	;
	; If a key is missing in the kbdPollRows that was present in
	; kbdIntRows then the key as been released so we send "release"
	; scancode to the imput manager.
	;
		call	KbdCompareColumns
	;
	; Drive all lines to 0
	;
		mov	al, 0x0
		KbdE3G_SetScanOut
	;
	; Copy the contents of kbdPollCols to kbdIntCols.
	;
		mov	di, offset es:[kbdIntCols]
		mov	si, offset es:[kbdPollCols]
		mov	cx, (size kbdPollCols/size word)
		rep	movsw
	;
	; If kbdPollCols says that there is no key down we have to re-enable
	; the key-down interupt.
	;
		mov	di, offset es:[kbdPollCols]
		mov	cx, (size kbdPollCols/size word)
		mov	ax, KBD_INT_ALL_MASK
		repe	scasw
		jnz	exit

	;
	; Reset the poll counter.  
	;
		clr	ds:[kbdPollCount]
	;
	; Setup the scanmode and the debounce time (KBCTRL).
	;
		mov	al, KBD_INT_MODE
		KbdE3G_SetCtrl
	;
	; Read the high keyboard return register (KBIN) to clear interrupt.
	;
		KbdE3G_GetInput
	;
	; Set the new interrupt handler vector.
	;
		mov	di, offset kbdInt
		
PENE <		mov	ax, PENE_KEYBOARD_IRQ				>
PENE <		call	SysResetDeviceInterrupt				>

	;
	; Set a flag indicating that this timer is running.
	;
PENE <		mov	ds:[kbdDigTimerRunning], TRUE			>

	; 
	; Run a timer to unmask the digitizer interrupt a short amount of
	; time later to allow the filter caps to discharge.
	;
PENE <		mov	cl, PKDID_KEYBOARD				>
PENE <		mov	ch, PTT_ONE_SHOT				>
PENE <		mov	ax, 4000		; about 3.34 msec	>
PENE <		call	PeneTimerStart					>

exit:
	;
	; Signal general end-interrupt.
	;
		mov	al, IC_GENEOI
		out	IC1_CMDPORT, al
	;
	; Enable all the row interrupts.
	;
		pop	ax
		KbdE3G_SetIntEnable
	;
	; Allow pending context switch
	;
		call	SysExitInterrupt	
		popa
		.leave
		iret
KbdPoll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdPeneTimerCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PENELOPE ONLY
		
		This is the callback for a special timer that indicates
		that the interrupt for the digitizer can safely be
		unmasked.  This is all done because we have these
		extra caps on the digitizer circuit which are necessary
		to filter the digitizer noise BUT they also charge up while
		doing a keyscan.  So after the keyscan completes, they
		hold the TOUCHINT line up for a while which will cause
		a false digitzer interrupt if the interrupt were unmasked
		immediately after the keyscan.

		Note that interrupts remain off during this function.

CALLED BY:	PeneTimerInt

PASS:		INTS OFF

RETURN:		nothing

DESTROYED:	everything

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCompareColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the kbdIntCols and kbdPollCols arrays.  If there
		is any change between the two arrays 

CALLED BY:	KbdPoll
PASS:		ds	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Let's say kbdIntRows gives us a row mask of 0110 and
		kbdPollRows gives us 1010.  0 means that a key is down.

		The first thing we do is check if a key has been released
		we do this by AND'ing the int row and the inverted poll row:

				1001
			AND	1010
				----
				1000		1 <- released key

		Next we have to check if a new key has been pressed.  We do
		that by AND'ing the inverted int row and the poll row:

				0110
			AND	0101
				----
				0100		1 <- new key

		Last we have we check to see if there is a repeated key, this
		is done by AND'ing the inverted int and poll rows:

				1001
			AND	0101
				----
				0001		1 <- repeated key

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdCompareColumns	proc	near
	;
	; Bail if we don't have a valid proc handle.
	;
		mov	bx, ds:[kbdOutputProcHandle]		
		cmp	bx, 0ffffh		;see if no recipient defined.
		LONG je	done			;branch if no proc
	;
	; Check if the poll counter has reached the typematic delay value.
	; if it has not then we don't have to send "key down" scan codes.
	; This is best done outside the loop to save cycles.
	;
		clr	bp			; assume no "key down"
		clr	ax
		mov	al, {byte} ds:[kbdTypematicValue+1]
		cmp	ds:[kbdPollCount], ax
		jl	afterTypematic
	;
	; The typematic delay is OK.  Now check we should send the according
	; to the typematic rate.  Only so many characters/sec should be
	; allowed.
	;
		mov	al, {byte} ds:[kbdTypematicValue]
		cmp	ds:[kbdRateCount], al
		jl	afterTypematic
		mov	bp, -1			; send key
		clr	ds:[kbdRateCount]	; reset rate counter
afterTypematic:
	;
	; Setup the offset into the KeyScanCodeTable.  We'll let the loop
	; take care of maintaining the correct offset.
	;
		mov	si, (KBD_NUM_COLS-1) * size KeyMatrixColumn
		mov	dx, KBD_NUM_COLS-1
colLoop:
	;
	; Get the row mask of the interrupt column. In the mask 0 means
	; key pressed.
	;
		mov	bx, dx
		shl	bx
		add	bx, offset ds:[kbdIntCols]
		mov	ax, ds:[bx]		; ax <- Row mask
		push	ax
	;
	; Get the row mask of the poll column. In the mask 0 means key pressed.
	;
		mov	bx, dx
		shl	bx
		add	bx, offset ds:[kbdPollCols]
		mov	bx, ds:[bx]
		push	bx
	;
	; AND the two together, this gives us a mask of the keys we need
	; to send a "release" scancode.
	;
		xor	ax, KBD_INT_ALL_MASK	; invert the bits (1 = pressed)
		and	ax, bx
		tst	ax
		jz	checkNewKey
		mov	di, KBD_RELEASE_FLAG
		call	SendKbdIMScan
checkNewKey:
	;
	; Get from the mask what keys are new.  We do this be AND'ing the
	; invert of the poll row to the int row.
	;
		pop	ax, bx
		push	ax, bx
		xor	bx, KBD_INT_ALL_MASK	; invert the bits
		and	ax, bx
		tst	ax
		jz	checkRepeatKey
		clr	di
		call	SendKbdIMScan
	;
	; Reset the typematic delay counter to zero since we want a new delay
	; period when a new key is pressed.
	;
		clr	ds:[kbdPollCount]
checkRepeatKey:
	;
	; If bp is non-zero we send the scan code.
	;
		pop	ax, bx		
		tst	bp
		jz	cont
	;	
	; AND the inverted int row and the inverted poll row.  This will
	; give us a mask of repeated keys that are pressed down.
	;
		xor	ax, KBD_INT_ALL_MASK	; invert the bits
		xor	bx, KBD_INT_ALL_MASK	; invert the bits
		and	ax, bx
		tst	ax
		jz	cont
		clr	di
		call	SendKbdIMScan
cont:		
	;
	; Loop until dx = -1
	;
		sub	si, size KeyMatrixColumn
		dec	dx
		cmp	dx, 0
		jge	colLoop
done:	
		ret
KbdCompareColumns	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendKbdIMScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the corrisponding scan code to the input manager for
		all keys in a given row mask.

CALLED BY:	KbdCompareColumns
PASS:		ds	- dgroup
		ax	- row mask
		dx	- column number
		si	- offset into KeyScanCodeTable
		di	- KBD_RELEASE_FLAG to send "release" scan code.
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendKbdIMScan	proc	near
rowLoop:
		push	ax
	;
	; Convert the row bitvector to a corrisponding integer
	;
		mov	cx, 17
10$:
		shl	ax, 1
		loopne	10$
	;
	; Get the scan code from the 8x10 KeyScanCodeTable matrix.
	;
		mov	bx, si
		add	bx, offset ds:[KeyScanCodeTable]
		dec	cx			; First row at 0
		push	cx
		add	bx, cx			; add row number
		mov	cx, ds:[bx]		; cx <- scan code
		clr	ch
		or	cx, di			; add/clear the release bit
	;
	; Give the scan code to the input manager.
	;
		push	dx, si, di, bp
		clr	dx, bp, si			; don't send driver hdl
		mov	bx, ds:[kbdOutputProcHandle]	; bx <- handle of proc
		mov	ax, MSG_IM_KBD_SCAN
		mov	di, mask MF_FORCE_QUEUE
if	 E3G_KBD_COUNT_INTS
		inc	cs:[kbdEvents]
endif	;E3G_KBD_COUNT_INTS
		call	ObjMessage			; send kbd msg to proc
		pop	dx, si, di, bp
	;
	; Remove the row bit we have processed by xor'ing the bit out of
	; the bitvector.  If the bitvector is 0 when there are no more keys
	; in that row.
	;
		pop	ax, cx		; cx <- bit pos, ax <- bitvector
		mov	bx, 1
		shl	bx, cl
		xor	ax, bx
		tst	ax
		jnz	rowLoop
		ret
SendKbdIMScan	endp

	.8086
endif		; _E3G_KBD_SCAN


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToSendQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a byte to the kbdSendQueue of bytes to be sent to the
		keyboard.  If first byte, start sending it.
NOTE:		ONLY call this routine w/INTS OFF.  If multiple
		byte command being send, turn ints off around group of
		bytes being added.
CALLED BY:	UTILITY

PASS:		al	- byte to send to keyboard
RETURN:		carry	- set if queue is full
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		Add byte to end of queue, if room;
		If queue was empty [
			send out new byte;
			set sending flag to show something going out;
		]
		inc size count to show new byte;
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Uses boring data queue which moves all data in queue.  I'm doing
	it this way because the queue size is small, & code is smaller
	this way.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn	HARDWARE_TYPE, <PC>
AddToSendQueue	proc	near
EC <	mov	bx, ds							>
EC <	cmp	bx, idata						>
EC <	ERROR_NE	KBD_ATSQ_DS_NOT_IDATA				>

	mov	bl, ds:[kbdSQSize]		;bl <- queue size (bytes)
	cmp	bl, size kbdSendQueue		;see if it will fit
	stc
	je	done				;branch if queue full

	clr	bh
	mov	ds:kbdSendQueue[bx], al		;put byte in queue
	tst	bl				;see if first element in queue
	jne	ATS_10				;branch if not
	ornf	ds:[kbdStratFlags], mask KSF_SENDING	;indicate sending

; here to track down a bug, left just for the hell of it -- ardeb 1/11/91
EC <	mov	ah, al							>
EC <	in	al, KBD_STATUS_PORT					>
EC <	test	al, mask KSB_INPUT_BUFFER_FULL or mask KSB_OUTPUT_BUFFER_FULL>
EC <	ERROR_NZ	KBD_ATSQ_BUFFER_FULL				>
EC <	mov	al, ah							>

	out	KBD_DATA_PORT, al		;out to KBD_DATA_PORT
ATS_10:
	inc	bl				;inc size of queue
	mov	ds:[kbdSQSize], bl		;store new size
;	(carry cleared by OR or TST)		;indicate queue not full
				
done:
	ret
AddToSendQueue	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetIndicatorState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of the keyboard LED's to match reality
CALLED BY:	INTERNAL: ?

PASS:		kbdIndModeState - status of LED's
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	??/??		Initial version
	eca	9/1/89		added routine header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetIndicatorState	proc	near
ifidn	HARDWARE_TYPE, <PC>
	push	ax				;save char1 code
	mov	al, KBD_CMD_SET_LED		;al <- command to send
	mov	ah, ds:[kbdModeIndState]	;ah <- current state
	;
	; these are the only things supported by the keyboard hardware
	;
	andnf	ah, (mask TS_CAPSLOCK or mask TS_NUMLOCK or mask TS_SCROLLLOCK)
	call	SetKbdState
	pop	ax				;restore char1 code
endif


	ret
SetIndicatorState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTypematicState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set delay and repeat rates for the keyboard
CALLED BY:	INTERNAL: KbdSetState, KbdInit

PASS:		kbdTypematicState - delay and repeat rate
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	for typematic state -
		bit 7   : 0
		bit 6-5 : DELAY = delay
		bit 4-3 : PEXP = period (exponent)
		bit 2-0 : PMAN = period (mantissa)
	delay = 1 + DELAY * 250 milliseconds +/- 20%
	period = (8 + PMAN) * (2 ^ PEXP) * 0.00417 seconds

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	?/??/??		Initial version
	gene	9/1/89		added routine header, comments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTypematicState	proc	near
ifidn	HARDWARE_TYPE, <PC>
	push	ax				;save char1 code
	mov	al, KBD_CMD_SET_TYPEMATIC	;al <- command
	mov	ah, ds:[kbdTypematicState]	;ah <- current state
	call	SetKbdState
	pop	ax				;restore char1 code
endif
	ret
SetTypematicState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetKbdState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add commands to the keyboard command queue
CALLED BY:	INTERNAL: SetIndicatorState, SetTypematicState

PASS:		al, ah - command bytes to add
RETURN:		none
DESTROYED:	bx, al

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	??/??		Initial version
	eca	9/1/89		added routine header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn		HARDWARE_TYPE, <PC>
SetKbdStateFar	proc	far
	call	SetKbdState
	ret
SetKbdStateFar	endp

SetKbdState	proc	near
	test	ds:keyboardOptions, mask KO_DOES_LEDS
	jz	done
	INT_OFF					;add commands with ints off
	push	ax
	call	AddToSendQueue			;add command in al
	pop	ax
	mov	al, ah				;al <- 2nd command to add
	call	AddToSendQueue
	INT_ON
done:
	ret
SetKbdState	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessKeyElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	keyboard scan processing code -- determines whether code is
		a press, release, or repeat press.  Manages keysDownList to
		ensure that status state is preserved throughout press,
		repeat & release of any given key.  Calls routine to convert
		scan code to char value.  Copies end resulting key event
		to kbdEvent variable structure.

CALLED BY:	INTERNAL: HandleScanCode

PASS:		ax		- scan code (high byte non-zero only if
				  extended scan codes (from PS/2 keyboards))
		keysDownList	- keys to be processed
RETURN:		ds:si		- pointer to KeyDownElement, if no error
		ds:di		- pointer to KeyDef, if no error
		carry		- set if overflow error in keysDownList
		keysDownList	- updated to modify old element or include new
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		Calculate pointer to KeyDef for scan code;
		if press [
		    if scan code found in keysDownList [
			change flag to show REPEAT;
		    ] else new press [
			allocate new entry in keysDownList;
			if overflow, exit w/error else [
			    copy scan code into scanCode;
		    	    copy kbdStateFlags into charFlags;
		    	    set kbdStateFlags for PRESS only;
			    processScanCode;
		    	    copy new char over kbdLastChar;
		 	]
		    ]
		] else is release [
		    find entry in keysDownList;
		    if entry not found exit with error else [
		    	change info flag to show RELEASE;
			clear REPEAT flag;
		    ]
		]


KNOWN BUGS/SIDE EFFECTS/IDEAS:

	ASSUMES that size of KeyDef = 4

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/29/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessKeyElement	proc	near
	tst	ah				;see if extended code
	jz	PKE_notExtended			;branch if not extended

	call	ConvertExtCodes			;convert 16 bit codes to 8 bit
	LONG jc	PKE_KeysDownListError		;not really, but it's convienent

PKE_notExtended:
	mov	dh, al				;dh <- scan code
	mov	dl, ah				;dl <- non-zero if extended

	and	al, not (KEY_RELEASE)		;clear release bit
	mov	bl, al
	clr	bh
if DBCS_PCGEOS
				CheckHack <size KeyDef eq 8>
	shl	bx, 1
else
				CheckHack <size KeyDef eq 4>
endif
	shl	bx, 1				;assume KeyDef is 4 bytes
	shl	bx, 1				;bx <- offset of KeyDef entry
	mov	di, offset KbdKeyDefTable - size KeyDef
	add	di, bx				;di <- ptr to KeyDef entry

	;
	; See if key is already down.
	;
	call	FindScanCode			;see if scan code in table
	jz	PKE_ScanFound			;branch if scan code found

	;
	; Key wasn't down, so it's a new keypress. Make sure
	; it is a press and not a release.
	;
	test	dh, KEY_RELEASE			;make sure a press
	jnz	PKE_KeysDownListError		;branch if error
	mov	si, bx				;si <- element address
	cmp	si, 0ffffh			;see if list full
	je	PKE_KeysDownListError		;if list is full, return error
	mov	ds:[si].KDE_scanCode, al	;copy scan code into element
	mov	ds:[si].KDE_charFlags, mask CF_FIRST_PRESS

if	SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT
	push	{word} ds:[kbdToggleState]
endif	; SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT

	call	ProcessScanCode			;convert scan code to char 
	mov	ds:[si].KDE_charValue, ax	;store character value
	mov	bh, ds:[kbdShiftState]

if	SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT
	pop	ax				;al = old kbdToggleState

if	SHIFT_STICK_IMPLIES_SHIFT
if	IGNORE_SHIFT_STATE_FOR_PGUP_PGDOWN
	;
	; On Responder we don't want SS_LSHIFT if the character value is
	; VC_NEXT or VC_PERVIOUS.  SH 10/26/95
	;
	cmp	ds:[si].KDE_charValue,(CS_CONTROL shl 8) or VC_NEXT
	je	PKE_noShiftStick
	cmp	ds:[si].KDE_charValue,(CS_CONTROL shl 8) or VC_PREVIOUS
	je	PKE_noShiftStick
endif	; IGNORE_SHIFT_STATE_FOR_PGUP_PGDOWN
	;
	; Set SS_LSHIFT in this KeyDownElement if TS_SHIFTSTICK was on before.
	;
	test	al, mask TS_SHIFTSTICK
	jz	PKE_noShiftStick
	BitSet	bh, SS_LSHIFT
PKE_noShiftStick:
endif	; SHIFT_STICK_IMPLIES_SHIFT
if	ALT_STICK_IMPLIES_ALT
	;
	; Set SS_LALT on in this KeyDownElement if TS_ALTSTICK was on before.
	;
	test	al, mask TS_ALTSTICK
	jz	PKE_noAltStick
	BitSet	bh, SS_LALT
PKE_noAltStick:
endif	; ALT_STICK_IMPLIES_ALT
endif	; SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT

	not	ch				;ch <- not (shift usage)
	and	bh, ch				;use as mask w/ kbdShiftState

	mov	cl, ds:[kbdToggleState]		;cl <- keyboard tobble state

if	SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT
	;
	; Set TS_CTRLSTICK on in this KeyDownElement if it was on before.
	;
	andnf	al, mask TS_CTRLSTICK
	or	cl, al
endif	; SHIFT_STICK_IMPLIES_SHIFT or ALT_STICK_IMPLIES_ALT

	mov	ch, ds:[kbdXState1]
	mov	dl, ds:[kbdXState2]
	mov	ds:[si].KDE_shiftState, bh	;store shift state
	mov	ds:[si].KDE_toggleState, cl	;store toggle state
	mov	ds:[si].KDE_xState1, ch		;
	mov	ds:[si].KDE_xState2, dl		;
	jmp	short PKE_ElementDone

	;
	; Key was already down. See if it's a release
	; or a repeated press.
	;
PKE_ScanFound:	
	test	dh, KEY_RELEASE			;see if release
	jnz	PKE_Release			;branch if release
	mov	bl, ds:[si].KDE_charFlags	;bl <- char flags
	and	bl, not (mask CF_FIRST_PRESS)	;clear PRESS flag
	or	bl, mask CF_REPEAT_PRESS	;set REPEAT PRESS flag
	mov	ds:[si].KDE_charFlags, bl	;store to KDE_charFlags
	jmp	short PKE_ElementDone

	;
	; Event is a key release. If it is a state key
	; (eg. SHIFT) being released, handle it specially.
	;
PKE_Release:
	mov	bl, ds:[si].KDE_charFlags	;bl <- char flagsn
						;clear all PRESS flags
	and	bl, not (mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS)
	or	bl, mask CF_RELEASE		;set RELEASE
	mov	ds:[si].KDE_charFlags, bl	;store to KDE_charFlags

	call	ProcessStateRelease		;handle releases of modifiers

PKE_ElementDone:
						;store ptr to current key
	mov	ds:[kbdCurDownElement.segment], ds
	mov	ds:[kbdCurDownElement.offset], si
	clc					;indicate NO error
	ret

PKE_KeysDownListError:
						;indicate no key
	mov	ds:[kbdCurDownElement.segment], 0
	stc					;indicate error
	ret

ProcessKeyElement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertExtCodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert extended keyboard scan codes.
CALLED BY:	INTERNAL: ProcessKeyElement

PASS:		ax	- 16 bit scan code value
RETURN:		al	- 8 bit scan code value
		carry	- set if extended shift
DESTROYED:	bx, cx, dl

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/1/88		Initial version
	Gene	2/27/90		Added extended shift checks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertExtCodes	proc	near
	;
	; Some keyboards have separate arrow and navigation keys
	; in addition to the ones on the numeric keypad. When the
	; keyboard is in the lowest emulation level that we use,
	;	<shift><ext-arrow>
	; comes through as:
	;	<shift><ext-unshift><ext-arrow><ext-shift>
	; This means that we would normally not be able to get
	; an extended arrow key with <shift> being down. This is
	; bad because some UIs specify <shift><arrow> as being a
	; shortcut (distinct from just <arrow>). To get around this
	; problem, we simply ignore extended shifts presses and
	; releases, and the rest of the keyboard driver does the
	; right thing...
	;
	mov	dl, al				;save press/release status
	and	al, not (KEY_RELEASE)		;ignore status for map

	cmp	ax, EXT_LSHIFT_PRESS
	je	extendedShift
	cmp	ax, EXT_RSHIFT_PRESS
	je	extendedShift

	;
	; The <Break> key is an extended key similar to the separate
	; arrow keys mentioned above, except it sents out <ext-ctrl>
	; and the like.
	;
	cmp	ax, EXT_LCTRL_PRESS
	je	extendedCtrl
afterCtrl:

	mov	bx, offset KbdExtendedScanTable
	mov	cx, KBD_NUM_EXTSCANMAPS		;cx <- number of entries
CEC_10:
	cmp	ax, ds:[bx].EMD_extScanCode
	je	CEC_30				;branch if match
	add	bx, size ExtendedScanDef	;move to next entry
	loop	CEC_10				;loop to try all entries
	jmp	short CEC_90			;exit w/same code if no match
CEC_30:
	mov	al, ds:[bx].EMD_mappedScanCode	;al <- translated char
CEC_90:
	and	dl, KEY_RELEASE			;get press/release flag
	or	al, dl				;set back to original value
	clc
	ret
extendedShift:
	stc
	ret

	;
	; Here's the story: the <Break> character is on a variety
	; of different keys on different types of keyboards, and is
	; accessed by <ctrl>+<key>.  On extended keyboards, it is on
	; a special key with <Pause>. This key sends out an <ext-unctrl>
	; the way the extended arrow keys send out <ext-unshift>, and
	; then sends out the same scan code as <Num Lock>.  On
	; non-extended keyboards, the <Break> character is on the
	; <Scroll Lock> key.
	;
	; Given the above, if the "swap <Ctrl> and <Caps Lock>" option
	; is selected, and an <ext-Ctrl> comes through, it should actually
	; be treated as <Caps Lock> since that's where the <Ctrl> actually
	; is now.  -- eca 2/22/91
	;
extendedCtrl:
	test	ds:keyboardOptions, mask KO_SWAP_CTRL
	jz	afterCtrl
	mov	ax, SCANCODE_CAPS_LOCK
	jmp	afterCtrl
ConvertExtCodes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindScanCode	- 815 cycles maximum if list is 16 elements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	INTERNAL: ProcessKeyElement

PASS:		al	- scan code (KEY_RELEASE bit clear)
		keysDownList
RETURN:		si	- ptr to element in keysDownList, if found
		bx	- ptr to empty element if element not found,
			  or 0ffffh if element not found & list full
		z flag	- set if element found
DESTROYED:	ah, cx

PSEUDO CODE/STRATEGY:
		init di = ffff;
		for each element [
		    if element is empty & di = ffff, copy ptr to di;
		    if element has matching scan code
			    exit with/address & flag showing found element;
		]
		exit with flag showing element not found.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/5/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindScanCode	proc	near

	mov	si, offset keysDownList - size KeyDownElement
	mov	bx, -1				;bx <- init: no empty element
	mov	cx, MAX_KEYS_DOWN		;cx <- # of elements to check
FSC_loop1:
	add	si, size KeyDownElement		;move up to next element
	mov	ah, ds:[si].KDE_scanCode	;ah <- scan code of element
	tst	ah				;see if empty element
	jz	FSC_Empty			;branch if empty slot
	cmp	ah, al				;see if matches search value
	loopne	FSC_loop1			;loop while no branch
	ret
FSC_Empty:
	mov	bx, si				;bx <- ptr to empty element
	jmp	short FSC_20
FSC_loop2:
	add	si, size KeyDownElement		;move up to next element
FSC_20:
	cmp	ds:[si].KDE_scanCode, al	;see if matches search value
	loopne	FSC_loop2			;branch while no match
	ret

FindScanCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessScanCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts scan code to char value on new press only
CALLED BY:	ProcessKeyElement

PASS:		dl		- != 0 iff extended scan code
		ds:si		- ptr to KeyDownElement
		ds:di		- ptr to KeyDef entry in kbd xlation tab
		kbdXlateTab	- keyboard translation table
		kbdShiftState
		kbdToggleState
		kbdXState1
		kdbLastChar

RETURN:		ax		- character value
		ch		- modifier bits used in translation
		ds:si		- .KDE_charFlags may be changed
		ds:di		- unchanged
		kbdLastChar	- unchanged
		kbdShiftState	- updated only if modifier char
		kbdToggleState	- updated only if toggle char
		kbdXState1	- updated only if xtended state/toggle char

DESTROYED:	bx, cl, dl

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/5/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessScanCode	proc	near
	tst	dl				;see if extended scan code
	jnz	extendedScan			;branch if extended scan
afterExtendedScan:
	clr	ch				;ch <- init: no modifiers
	mov	dh, ds:[di].KD_keyType		;dh <- key type
	test	dh, KD_STATE_KEY		;see if a state key
	jz	PSC_3				;branch if not
	or	ds:[si].KDE_charFlags, mask CF_STATE_KEY ;set flag for state
PSC_3:
	mov	dl, dh				;dl <- key type & flags
	and	dl, KD_TYPE			;keep type bits only

	test	dh, KD_EXTENDED			;EXTENDED keyDef?
	jz	PSC_NotExtended			;branch if not extended case

ifdef PZ_PCGEOS_84J ; Pizza for 84J keybard
	call	Toshiba84JTenkey		; check tenkey mode
	jc	PSC_done
endif

	call	HandleExtendedDef		;handle extended case
	jc	PSC_NormalXlate			;if no extension, handle normal


						;clear shift on extended key
	andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
					  TOGGLE_CTRLSTICK or \
					  TOGGLE_ALTSTICK or \
					  TOGGLE_FNCTSTICK)
	andnf	ds:[kbdModeIndState], not (TOGGLE_SHIFTSTICK or \
					   TOGGLE_CTRLSTICK or \
					   TOGGLE_ALTSTICK or \
					   TOGGLE_FNCTSTICK)
PSC_done:
	ret

extendedScan:
	ornf	ds:[si].KDE_charFlags, mask CF_EXTENDED
	jmp	afterExtendedScan

PSC_NotExtended:
	call	HandleNormalDef			;handle normal KeyDef
	jnc	PSC_done			;branch if ALT translation
PSC_NormalXlate:

if DBCS_PCGEOS
	mov	ax, ds:[di].KD_char		;ax <- unshifted char
	mov	bx, ds:[di].KD_shiftChar	;bx <- shifted char
else
	mov	al, ds:[di].KD_char		;al <- unshifted char
	mov	bl, ds:[di].KD_shiftChar	;bl <- shifted char
endif

	cmp	dl, KEY_ALPHA
	je	PSC_CaseAlpha
	cmp	dl, KEY_NONALPHA
LONG	je	PSC_Shift
	cmp	dl, KEY_SOLO
	je	PSC_CaseSolo
	cmp	dl, KEY_PAD
	je	PSC_CasePad	
	cmp	dl, KEY_SHIFT
	je	PSC_CaseShift
	cmp	dl, KEY_TOGGLE
LONG	je	PSC_CaseToggle
	cmp	dl, KEY_MISC
	je	PSC_Shift
	cmp	dl, KEY_SHIFT_STICK
	je	PSC_CaseStick
	cmp	dl, KEY_XSHIFT
LONG	je	PSC_CaseXShift
	cmp	dl, KEY_XTOGGLE
	LONG je	PSC_CaseXToggle

	;
	; Something unknown happened -- signal an error
	;
if DBCS_PCGEOS
	mov	ax, C_NOT_A_CHARACTER		;put out "invalid" key code
else
	mov	ax, (0ffh shl 8) or VC_INVALID_KEY ; put out invalid key code
endif

	ret


PSC_CaseSolo:
	;
	;  Clear shift state
	andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
					  TOGGLE_CTRLSTICK or \
					  TOGGLE_ALTSTICK or \
					  TOGGLE_FNCTSTICK)
	andnf	ds:[kbdModeIndState], not (TOGGLE_SHIFTSTICK or \
					   TOGGLE_CTRLSTICK or \
					   TOGGLE_ALTSTICK or \
					   TOGGLE_FNCTSTICK)

if DBCS_PCGEOS
						;shiftChar is unused
else
	mov	ah, bl				;shiftChar is really high byte
endif
	ret

PSC_CaseAlpha:
	test	ds:[kbdToggleState], TOGGLE_CAPSLOCK
	jz	PSC_75				;branch if no CAPSLOCK
	xchg	ax, bx				;swap if CAPSLOCK
PSC_75:
	jmp	short PSC_Shift

PSC_CasePad:
	test	ds:[si].KDE_charFlags, mask CF_EXTENDED
	jnz	PSC_85				;don't toggle extended chars
	test	ds:[kbdToggleState], TOGGLE_NUMLOCK
	jz	PSC_85				;branch if no NUMLOCK
	xchg	ax, bx				;swap if NUMLOCK
PSC_85:
	jmp	short PSC_Shift

PSC_ShiftStick:
	xornf	ds:[kbdToggleState], TOGGLE_SHIFTSTICK
	xornf	ds:[kbdModeIndState], TOGGLE_SHIFTSTICK

PSC_CaseShift:

ifdef PZ_PCGEOS_84J ; Pizza for 84J keyboard
	;
	; Switch Right Shift key to KANA "RO" key
	;
	test	ds:[kbdToggleState], mask TS_SCROLLLOCK
	je	PSC_noKana			; check KANA mode
	cmp	ax, C_SYS_RIGHT_SHIFT		; check right shift key
	jne	PSC_noKana
	test	ds:[kbdShiftState], mask SS_LSHIFT
	je	PSC_noShiftKana			; check left shift is pressed
	mov	ax, C_FULLWIDTH_VERTICAL_BAR	; set Shift KANA "|"
	jmp	PSC_doneKana
PSC_noShiftKana:
	mov	ax, C_KATAKANA_LETTER_RO	; set KANA "RO"
PSC_doneKana:
	and	ds:[si].KDE_charFlags, not mask CF_STATE_KEY
	jmp	afterShiftRelease		; not work as shift key
PSC_noKana:
endif
						;ax == <0xff><char> code
	or	ds:[kbdShiftState], bl		;show modifier key depressed
	call	KeyboardTrackBiosShift
	test	ds:[keyboardOptions], mask KO_SHIFT_RELEASE
	jnz	handleShiftRelease		;branch if special option
afterShiftRelease:
	ret

PSC_Shift:
	test	ds:[kbdToggleState], TOGGLE_SHIFTSTICK
	jnz	PSC_125				;branch if shifted
	mov	cl, SHIFT_KEYS			;cl <- shift mask
	test	ds:[kbdShiftState], cl		;see if SHIFT pressed
	jz	PSC_afterShift			;branch if no shift

PSC_125:
	xchg	ax, bx				;swap is shifted

PSC_afterShift:
	;
	;  Now that shift state has been taken care of,
	;  clear any sticky settings
	andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
					  TOGGLE_CTRLSTICK or \
					  TOGGLE_ALTSTICK or \
					  TOGGLE_FNCTSTICK)
	andnf	ds:[kbdModeIndState], not (TOGGLE_SHIFTSTICK or \
					   TOGGLE_CTRLSTICK or \
					   TOGGLE_ALTSTICK or \
					   TOGGLE_FNCTSTICK)


ifdef PZ_PCGEOS_US_106J ; Pizza for US 106J keybard
	; Support CapsLock key of Toshiba US and 106J keyboard
	;
	cmp	ax, C_SYS_CAPS_LOCK
	jne	PSC_noCapsLock
	or	ds:[si].KDE_charFlags, mask CF_STATE_KEY ;set flag for state
	mov	bl, mask TS_CAPSLOCK
	jmp	PSC_CaseToggle
PSC_noCapsLock:
endif
	;
	; If the character generated with or without <Shift> is the
	; same, then don't add <Shift> in as a modifier used.  This
	; allows <Shift> to go through as a modifier for the space
	; bar (or for any such keys on foreign keyboards).  This
	; will normally be ignored anyway, but allows using modifiers
	; with spacebar as shortcuts (eg. <Shift>-spacebar) -- eca 11/30/92
	;
	cmp	ax, bx				;same key w/ or w/o <Shift>?
	je	PSC_done2			;branch if same
	or	ch, cl				;show modifiers used
PSC_done2:
	ret

PSC_CaseStick:
if DBCS_PCGEOS
	; ax <- character to send
	; bx <- ShiftState to change
	cmp	ax, C_SYS_LEFT_SHIFT
	je	PSC_ShiftStick			;branch if shift
	cmp	ax, C_SYS_LEFT_CTRL
	je	PSC_CtrlStick			;branch if ctrl
else
	; al <- character to send
	; bl <- ShiftState to change
	cmp	al, VC_LSHIFT
	je	PSC_ShiftStick			;branch if shift
	cmp	al, VC_LCTRL
	je	PSC_CtrlStick			;branch if ctrl
endif
	xornf	ds:[kbdToggleState], TOGGLE_ALTSTICK
	xornf	ds:[kbdModeIndState], TOGGLE_ALTSTICK
	jmp	short PSC_CaseShift

PSC_CaseToggle:
	xor	ds:[kbdToggleState], bl		;toggle toggle key
	call	KeyboardTrackBiosToggle

PSC_HandleToggle:
	test	dh, KD_SET_LED			;see if we should change LED
	jz	PSC_done2			;branch if not

	xor	ds:[kbdModeIndState], bl	;toggle indicator state
	jmp	SetIndicatorState		;change LEDs

PSC_CaseXShift:
	or	ds:[kbdXState1], bl		;show x modifier key depressed
	ret					;return <0xff><char> code

PSC_CaseXToggle:
	xor	ds:[kbdXState1], bl		;toggle modifier state
	jmp	short PSC_HandleToggle

PSC_CtrlStick:
	xornf	ds:[kbdToggleState], TOGGLE_CTRLSTICK
	xornf	ds:[kbdModeIndState], TOGGLE_CTRLSTICK
	jmp	short PSC_CaseShift

	;
	; The Europeans want the <Caps Lock> key to behave as such:
	;     <Caps Lock> key turns CAPSLOCK on
	;     <Shift> turns CAPSLOCK off
	;
handleShiftRelease:
	test	bl, SHIFT_KEYS			;shift keys?
	jz	afterShiftRelease		;branch if not shift keys
	andnf	ds:[kbdToggleState], not (TOGGLE_CAPSLOCK)
	call	KeyboardTrackBiosToggle
	andnf	ds:[kbdModeIndState], not (TOGGLE_CAPSLOCK)
	jmp	SetIndicatorState

ProcessScanCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle case of KeyDef containing extended definition.  If
		Alt, Ctrl, or Alt Ctrl pressed & charValue exists for that
		case, use it.  Otherwise, just determine virtual/char
		orientation of base & shift case.
CALLED BY:	INTERNAL:

PASS:		ch	- shift modifiers used in translation so far
		dh	- First byte of KeyDef for this scan code, complete
		dl	- keyType only, for this scan code

		ds:[di] - pointer to KeyDef for scan code being processed

RETURN:
		if (carry clear) {
		/* scan code translated */
		ax	- charValue
		ch	- updated w/any modifier bits involved w/translation
		bx, cl	- destroyed
		} else {
		/* scan code not translated */
		ah	- 0xff or 00, based on vrt/char flag for key base case
		bh	- 0xff or 00, based on vrt/char flag for key shift case
		al, bl, cx - destroyed

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/19/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	.assert offset kbdToggleState eq (offset kbdShiftState + 1)
HandleExtendedDef	proc	near
	push	di
	mov	bl, ds:[di].KD_extEntry		;bl <- # of extended entry
	clr	bh
	mov	di, bx				;di <- # of ext entry
if DBCS_PCGEOS
		CheckHack <(size ExtendedDef) eq 16>
	shl	di, 1
else
		CheckHack <(size ExtendedDef) eq 8>
endif
	shl	di, 1				;*8 to get entry offset
	shl	di, 1
	shl	di, 1
	mov	ax, {word}ds:[kbdShiftState]	;al <- kbd shift state
						;ah <- toggle state
SBCS <	clr	bl							>
DBCS <	clr	bx							>
	test	ax, SHIFT_KEYS or (TOGGLE_SHIFTSTICK shl 8)
	jz	HED_noShift
	ornf	bl, EXT_SHIFT_MASK		;use shifted key
HED_noShift:
	test	ax, CTRL_KEYS or (TOGGLE_CTRLSTICK shl 8)
	jz	HED_noCtrl
	ornf	bl, EXT_CTRL_MASK		;use ctrl key
HED_noCtrl:
	test	ax, ALT_KEYS or (TOGGLE_ALTSTICK shl 8)
	jz	HED_noAlt
	ornf	bl, EXT_ALT_MASK		;use alt key
HED_noAlt:

if PZ_PCGEOS ; Pizza for all keyboard
	; Support Kana of Toshiba keyboard
	;
	cmp	bl, (mask EO_SHIFT or mask EO_CTRL)
	je	notExtended			; ignore <shift><ctrl>-key
	cmp	bl, (mask EO_SHIFT or mask EO_ALT)
	je	notExtended			; ignore <shift><alt>-key
	test	ds:[kbdToggleState], mask TS_SCROLLLOCK
	je	HED_noKana			; check Kana mode
	tst	bl				; check kana or shift+kana
	jne	HED_noOnlyKana
	mov	bl, (mask EO_SHIFT or mask EO_CTRL)	; set <kana> code
	jmp	HED_noKana
HED_noOnlyKana:
	cmp	bl, EXT_SHIFT_MASK
	jne	HED_noKana
	mov	bl, (mask EO_SHIFT or mask EO_ALT)	; set <shift+kana> code
HED_noKana:
endif

DBCS <	cmp	bl, EXT_SHIFT_MASK		;see if key or <shift>-key >
DBCS <	jbe	notExtended			;if so, not really extended >
SBCS <	clr	bh				;bx <- offset		>
	mov	cl, ds:bitTable[bx]		;cl <- mask for offset
DBCS <	shl	bx							>
SBCS <	tst	{byte}ds:KbdExtendedDefTable[di][bx]			>
DBCS <	tst	{Chars}ds:KbdExtendedDefTable[di][bx][-3]		>
	je	notExtended			;branch if no extenstion
SBCS <	cmp	bl, EXT_SHIFT_MASK		;see if key or <shift>-key >
SBCS <	jbe	notExtended			;if so, not really extended >


	test	ds:KbdExtendedDefTable[di].EDD_charAccents, cl
	jnz	doAccent			;branch if an accent char
afterAccent:
SBCS <	mov	ah, VC_ISANSI			;ah <- flag: assume not virtual>
SBCS <	test	ds:KbdExtendedDefTable[di].EDD_charSysFlags, cl		>
SBCS <	jz	notVirtual			;branch if bit was clear >
SBCS <	mov	ah, VC_ISCTRL			;ah <- flag: virtual char >

if DO_EXTENDED_CHARACTER_SET
SBCS <	call	HandleExtendedSet	;ah <- correct char set		>
endif

SBCS < notVirtual:							>
	or	ch, al				;set CTRL, ALT, & SHIFT info,
						; clears carry (to indicate
						; translation)
SBCS <	mov	al, {byte}ds:KbdExtendedDefTable[di][bx]		>
DBCS <	mov	ax, {Chars}ds:KbdExtendedDefTable[di][bx][-3]		>

finishUp:
	pop	di				;al <- char value
	ret

notExtended:
if DBCS_PCGEOS
else
	clr	ah
	clr	bh
	test	ds:KbdExtendedDefTable[di].EDD_charSysFlags, EV_KEY
	je	baseNotVirtual			;branch if base key not virtual
	dec	ah				;ah <- 0xff: base is virtual
baseNotVirtual:
	test	ds:KbdExtendedDefTable[di].EDD_charSysFlags, EV_SHIFT
	je	shiftNotVirtual			;branch if shifted not virtual
	dec	bh				;bh <- 0xff: shifted is virtual
shiftNotVirtual:
endif
	stc					;indicate no translation
	jmp	finishUp

doAccent:
	push	ax, bx
SBCS <	mov	al, {byte}ds:KbdExtendedDefTable[di][bx]		>
						;al <- char value
DBCS <	mov	ax, {Chars}ds:KbdExtendedDefTable[di][bx][-3]		>
	clr	bx
accentLoop:
SBCS <	cmp	{byte}ds:KbdAccentTable[bx], al				>
DBCS <	cmp	{Chars}ds:KbdAccentTable[bx], ax			>
	je	foundAccent			;branch if match
	inc	bx				;inc ptr into table
DBCS <	inc	bx							>
EC <	cmp	bx, KBD_NUM_ACCENTS		;>
EC <	ERROR_AE	KBD_BAD_ACCENT_TABLE	;>
	jmp	accentLoop			;branch while more
foundAccent:
SBCS <	mov	ds:kbdAccentPending, al		;indicate accent pending >
DBCS <	mov	ds:kbdAccentPending, ax		;indicate accent pending >
	mov	ds:kbdAccentOffset, bl		;store offset in table
	or	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
	pop	ax, bx
	jmp	afterAccent

HandleExtendedDef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if extended char should be in non-ctrl set

CALLED BY:	HandleExtendedDef

PASS:		di	-> offset into table
		bx	-> offset into ExtendedDef struct
		ds	-> dgroup
		ah	-> VC_ISCTRL

RETURN:		ah	<- char set for key
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Search ExtendedExtendedCharTable for matching offset

		If located, return correct type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DO_EXTENDED_CHARACTER_SET
if	not DBCS_PCGEOS

HandleExtendedSet	proc	near
	uses	si
	.enter

	;
	;  Scan table for matching Def
	mov	si, offset KbdExtendedExtendedTable

topOfLoop:
	cmp	di, ds:[si].EED_di			; does DI match?
	je	checkBX		; => matches!
afterCheck:
	add	si, size ExtendedExtendedDef		; go to next def
	cmp	si, offset KbdExtendedExtendedTableEnd
	jb	topOfLoop	; => check next def

done:
	.leave
	ret

checkBX:
	cmp	bx, ds:[si].EED_bx			; does BX match?
	jne	afterCheck	; => no match...

	mov	ah, ds:[si].EED_charSet			; get correct set
	jmp	done
HandleExtendedSet	endp

endif ; not DBCS_PCGEOS
endif ;	DO_EXTENDED_CHARACTER_SET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedCapsLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip the case of the extended char if the caps lock is on and
		a different case of this char exists.

CALLED BY:	HandleExtendedDef
PASS:		ds	= segment of tables
		di	= offset into kbdExtendedDefTable of extended key entry
		SBCS:
			bx	= ExtOffsets (offset into ExtendedDef for this
				  char)
			ah	= char set (VC_ISxx)
		DBCS:
			bx	= ExtOffsets shl 1 (offset+3 into ExtendedDef
				  for this char)
RETURN:		bx	= modified offset pointing to the char with the
			  right case
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNormalDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle case of normal KeyDef, checking for use of the ALT
		translation.

CALLED BY:	INTERNAL:

PASS:		ch	- Modifiers used in translation so far
		dh	- First byte of KeyDef for this scan code, complete
		dl	- keyType only, for this scan code

		ds:[di] - pointer to KeyDef for scan code being processed

RETURN:
		If carry clear:   Scan code has been translated.

		ax	- charValue
		ch	- Updated to show any new modifiers involved in
			  translation
		bh, cl	- destroyed

		If carry set:	  Scan code not translated.

		ah	- FF or 00, based on if keyType
		bh	- FF or 00, " "
		cl	- destroyed

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/19/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandleNormalDef	proc	near
	clr	ah, bh				;ah <- char options
						;bh <- char options
	cmp	dl, MIN_VIRTUAL_KEY_TYPE	;see if normal or virtual
	jb	HND_50				;branch if normal
	dec	ah				;ah <- 0xff: virtual
	dec	bh				;bh <- 0xff: virtual
HND_50:
	mov	cl, ds:[di].KD_keyType		;cl <- key type
	test	cl, KD_ACCENT			;see if an accent char
	je	HND_notAccent			;branch if not an accent
	mov	ah, 0ffh			;ah <- 0xff: virtual
HND_notAccent:
	test	cl, KD_EXTENDED			;see if extended
	je	HND_90				;branch if normal
		CheckHack <kbdShiftState + size byte eq kbdToggleState>
	test	{word} ds:[kbdShiftState], \
			(CTRL_KEYS) or (TOGGLE_CTRLSTICK) shl 8
						;see if CTRL mode on
	jnz	HND_90				;if so, can't use ALT value 
	test	ds:[kbdShiftState], ALT_KEYS	;see if ALT pressed
	jz	HND_90				;if no ALT press, exit
	or	ch, ALT_KEYS			;ch <- modifiers used
	mov	al, ds:[di].KD_extEntry		;al <- extended entry
	clc					;indicate translation
	ret
HND_90:
	stc					;indicate no translation
	ret
HandleNormalDef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessStateRelease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monitors SHIFT & MODIFIER key releases
CALLED BY:	ProcessKeyElement

PASS:		ds:di		- pointer to KeyDef entry
		kbdShiftState
		kbdXState1
RETURN:		ds:si		- unchanged
		ds:di		- unchanged
		ax, bx, & cx	- untouched
		kbdShiftState	- updated only if modifier char
		kbdXState1	- updated only if extended modifier char
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		get pointer to char entry in kbdTabUSExtd;
		if KEY_SHIFT {
		    AND kbdShiftState w/(0ffh XOR data2);
		} else if KEY_XSHIFT {
		    AND kbdXState1 w/(0ffh XOR data2);
		}
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/5/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessStateRelease	proc	near
	mov	dl, ds:[di].KD_keyType		;dl <- key type
	and	dl, KD_TYPE			;keep only type bits
if DBCS_PCGEOS
	mov	dh, {byte}ds:[di].KD_shiftChar	;dh <- shifted char / data2
else
	mov	dh, ds:[di].KD_shiftChar	;dh <- shifted char / data2
endif

	;
	; Ironically, if the keyboard is handling the toggle keys, we have
	; to do more work to toggle the state bits on the release as well
	; as on the press.
	;
	test	ds:[KbdHeader].KCH_flags, mask KCF_KBD_HANDLES_TOGGLES
	jz	lookForShift
	cmp	dl, KEY_TOGGLE
	je	PSR_CaseToggle
	cmp	dl, KEY_XTOGGLE
	je	PSR_CaseXToggle

lookForShift:
	not	dh				;dh <- inverse

	cmp	dl, KEY_SHIFT
	je	PSR_CaseShift			;branch if shift case
	cmp	dl, KEY_SHIFT_STICK
	je	PSR_CaseShift			;branch if sticky shift
	cmp	dl, KEY_XSHIFT
	je	PSR_CaseXShift			;branch if xshift case

done:
	ret

PSR_CaseShift:
	and	ds:[kbdShiftState], dh		;indicate key up
	call	KeyboardTrackBiosShift
	ret
PSR_CaseXShift:
	and	ds:[kbdXState1], dh		;indicate key up
	ret

PSR_CaseXToggle:
	xor	ds:[kbdXState1], dh		;toggle modifier state
	jmp	short PSR_HandleToggle
PSR_CaseToggle:
	xor	ds:[kbdToggleState], dh		;toggle toggle key
	call	KeyboardTrackBiosToggle
PSR_HandleToggle:
	test	ds:[di].KD_keyType, KD_SET_LED	;see if we should change LED
	jz	done				;done if not

	xor	ds:[kbdModeIndState], dh	;toggle indicator state
	push	bx				; can't touch this...
	call	SetIndicatorState		;change LEDs
	pop	bx
	jmp	done
ProcessStateRelease	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccentTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description
CALLED BY:	EXTERNAL

PASS:		ds:[si] - pointer to KeyDown entry
		ds:[di] - pointer to keyDef entry
RETURN:		KeyDownEntry modified to have new charValue if translation
		possible

DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/19/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AccentTranslation	proc	near
DBCS <	tst	ds:[kbdAccentPending]		;see if pending accent	>
SBCS <	mov	al, ds:[kbdAccentPending]	;see if pending accent	>
SBCS <	tst	al							>
	jz	AT_SeeIfAccent			;branch if none pending
	test	ds:[di].KD_keyType, (KD_ACCENTABLE or KD_ACCENT)
	jz	AT_SeeIfAccent			;branch if not accentable
DBCS <	mov	ax, ds:[si].KDE_charValue				>
DBCS <	cmp	ax, ds:[kbdAccentPending]	;see if accent hit twice >
SBCS <	mov	ah, byte ptr ds:[si].KDE_charValue			>
SBCS <	cmp	ah, al				;see if accent hit twice >
	je	AT_80				;branch if two accents
	clr	bx
	mov	cl, _NUM_ACCENTABLES		;cl <- # entries to check
AT_30:
DBCS <	cmp	ds:KbdAccentables[bx], ax				>
SBCS <	cmp	ds:KbdAccentables[bx], ah				>
	je	AT_40				;branch if a match
DBCS <	inc	bx							>
	inc	bx
	dec	cl
	jnz	AT_30				;loop to check all entries
	jz	AT_90				;if not found, quit
AT_40:
if DBCS_PCGEOS
		CheckHack <(size AccentDef) eq 16>
else
		CheckHack <(size AccentDef) eq 8>
endif
	shl	bx, 1				;*8
	shl	bx, 1
	shl	bx, 1				;bx <- offset of entry
	mov	al, ds:[kbdAccentOffset]	;al <- accent offset
	clr	ah				;
	add	bx, ax				;bx <- ptr to entry
SBCS <	mov	al, ds:KbdAccentables[bx] + _NUM_ACCENTABLES		>
SBCS <	or	al, al							>
DBCS <	mov	ax, ds:KbdAccentables[bx] + _NUM_ACCENTABLES*2		>
DBCS <	tst	ax							>
	je	AT_90				;branch if no translation
AT_80:
SBCS <	mov	byte ptr ds:[si].KDE_charValue, al			>
DBCS <	mov	ds:[si].KDE_charValue, ax				>
	mov	ds:[kbdAccentPending], 0	;indicate no pending accent
	ret

AT_90:

AT_SeeIfAccent:
	test	ds:[si].KDE_charFlags, mask CF_STATE_KEY
	jnz	ATHA_90				;branch if state key
	;
	; Having a <Shift> key pressed is OK for an accent, but nothing
	; else is.
	;
	test	ds:[si].KDE_shiftState, not (mask SS_LSHIFT or mask SS_RSHIFT)
	jnz	AT_NoTempAccent
	test	ds:[di].KD_keyType, KD_ACCENT	;see if an accent char
	jnz	AT_HaveAccent			;branch if accent
AT_NoTempAccent:
	mov	ds:[kbdAccentPending], 0	;indicate no pending accent
	ret
AT_HaveAccent:
SBCS <	mov	al, byte ptr ds:[si].KDE_charValue	 ;al <- char	>
DBCS <	mov	ax, ds:[si].KDE_charValue	 ;ax <- char	>
	clr	bx
ATHA_10:
SBCS <	cmp	ds:KbdAccentTable[bx], al	;see if char matches	>
DBCS <	cmp	{Chars}ds:KbdAccentTable[bx], ax ;see if char matches	>
	je	ATHA_20				;branch if match
	inc	bx				;inc ptr into table
DBCS <	inc	bx							>
	cmp	bx, KBD_NUM_ACCENTS
	jb	ATHA_10
	ret
ATHA_20:
SBCS <	mov	ds:[kbdAccentPending], al	;indicate accent pending >
DBCS <	mov	ds:[kbdAccentPending], ax	;indicate accent pending >
	mov	ds:[kbdAccentOffset], bl	;store offset in table
	or	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
ATHA_90:
	ret
AccentTranslation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardTrackBiosShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Track the state of the shift keys in the BIOS data area

CALLED BY:	ProcessScanCode, ProcessStateRelease
PASS:		ds	= dgroup
		kbdShiftState = new state of shift modifiers
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <PC>
KeyboardTrackBiosShiftFar	proc	far
	call	KeyboardTrackBiosShift
	ret
KeyboardTrackBiosShiftFar	endp

KeyboardTrackBiosShift	proc	near	uses ax, es, bx
		.enter
	;
	; Set ax & bh to contain the BiosKbdState and BiosAltKbdState records
	; without any shift modifiers set. bl contains the current ShiftState
	; record for the driver.
	;
		mov	ax, BIOS_SEG
		mov	es, ax
		mov	ax, es:[BIOS_KBD_STATE]
		mov	bl, ds:[kbdShiftState]
		mov	bh, es:[BIOS_ALT_KBD_STATE]
		andnf	ax, not (mask BKS_LEFT_ALT or mask BKS_LEFT_CTRL or \
				 mask BKS_ALT_ACTIVE or mask BKS_CTRL_ACTIVE or\
				 mask BKS_LEFT_SHIFT or mask BKS_RIGHT_SHIFT)
		andnf	bh, not (mask BAKS_RIGHT_ALT or mask BAKS_RIGHT_CTRL)

	;
	; Set the ALT modifiers appropriately.
	;
		test	bl, ALT_KEYS
		jz	ctrl
		ornf	ax, mask BKS_ALT_ACTIVE
		test	bl, mask SS_LALT
		jz	rightAlt
		ornf	ax, mask BKS_LEFT_ALT
rightAlt:
		test	bl, mask SS_RALT
		jz	ctrl
		ornf	bh, mask BAKS_RIGHT_ALT

ctrl:
	;
	; Set the CTRL modifiers appropriately.
	;
		test	bl, CTRL_KEYS
		jz	shift
		ornf	ax, mask BKS_CTRL_ACTIVE
		test	bl, mask SS_LCTRL
		jz	rightCtrl
		ornf	ax, mask BKS_LEFT_CTRL
rightCtrl:
		test	bl, mask SS_RCTRL
		jz	shift
		ornf	bh, mask BAKS_RIGHT_CTRL

shift:
	;
	; Set the SHIFT modifiers appropriately.
	;
		shr	bl		; they're both in the same word, so
		shr	bl		;  it's easier...
		andnf	bl, 3
		ornf	al, bl
		
		mov	es:[BIOS_KBD_STATE], ax
		mov	es:[BIOS_ALT_KBD_STATE], bh
		.leave
		ret
KeyboardTrackBiosShift	endp
else
KeyboardTrackBiosShift	proc	near
		ret
KeyboardTrackBiosShift	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardTrackBiosToggle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Track the changes to our kbdToggleState record in the
		BIOS data area.

CALLED BY:	ProcessScanCode
PASS:		ds	= dgroup
		kbdToggleState = new state of toggle keys
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn		HARDWARE_TYPE, <PC>
KeyboardTrackBiosToggle	proc	near	uses es, ax, cx
		.enter
		mov	ax, BIOS_SEG
		mov	es, ax
		mov	al, es:[BIOS_KBD_STATE]
		andnf	al, not (mask BKS_CAPS_LOCK_ACTIVE or \
				 mask BKS_NUM_LOCK_ACTIVE or \
				 mask BKS_SCROLL_LOCK_ACTIVE)
		mov	ah, ds:[kbdToggleState]
		mov	cl, offset BKS_SCROLL_LOCK_ACTIVE
		shl	ah, cl
		ornf	al, ah
		mov	es:[BIOS_KBD_STATE], al
		.leave
		ret
KeyboardTrackBiosToggle	endp
else
KeyboardTrackBiosToggle	proc	near
		ret
KeyboardTrackBiosToggle	endp
endif



ifdef PZ_PCGEOS_84J ; Pizza for 84J keybard

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Toshiba84JTenkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a character code for tenkey mode

CALLED BY:	ProcessScanCode

PASS:		ds:si		- ptr to KeyDownElement
		kbdToggleState

RETURN:		if (carry clear) {
		/* tenkey code translated */
		ax	- charValue
		ch	- NULL
		} else {
		/* tenkey code not translated */
		}

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/13/93	Initial version
	Tera	11/22/93	Change char value to C_SYS_NUMPAD_*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Toshiba84JTenkey	proc	near
	.enter

	test	ds:[kbdToggleState], mask TS_NUMLOCK
	je	TJT_noTenkey

	mov	al, ds:[si].KDE_scanCode		; set scan code
	cmp	al, TT_SCAN_SEVEN
	jne	next1
	mov	ax, C_SYS_NUMPAD_7
	jmp	TJT_findTenkey
next1:
	cmp	al, TT_SCAN_EIGHT
	jne	next2
	mov	ax, C_SYS_NUMPAD_8
	jmp	TJT_findTenkey
next2:
	cmp	al, TT_SCAN_NINE
	jne	next3
	mov	ax, C_SYS_NUMPAD_9
	jmp	TJT_findTenkey
next3:
	cmp	al, TT_SCAN_ASTERISK
	jne	next4
	mov	ax, C_SYS_NUMPAD_MULTIPLY
	jmp	TJT_findTenkey
next4:
	cmp	al, TT_SCAN_FOUR
	jne	next5
	mov	ax, C_SYS_NUMPAD_4
	jmp	TJT_findTenkey
next5:
	cmp	al, TT_SCAN_FIVE
	jne	next6
	mov	ax, C_SYS_NUMPAD_5
	jmp	TJT_findTenkey
next6:
	cmp	al, TT_SCAN_SIX
	jne	next7
	mov	ax, C_SYS_NUMPAD_6
	jmp	TJT_findTenkey
next7:
	cmp	al, TT_SCAN_MINUS
	jne	next8
	mov	ax, C_SYS_NUMPAD_MINUS
	jmp	TJT_findTenkey
next8:
	cmp	al, TT_SCAN_ONE
	jne	next9
	mov	ax, C_SYS_NUMPAD_1
	jmp	TJT_findTenkey
next9:
	cmp	al, TT_SCAN_TWO
	jne	next10
	mov	ax, C_SYS_NUMPAD_2
	jmp	TJT_findTenkey
next10:
	cmp	al, TT_SCAN_THREE
	jne	next11
	mov	ax, C_SYS_NUMPAD_3
	jmp	TJT_findTenkey
next11:
	cmp	al, TT_SCAN_PLUS
	jne	next12
	mov	ax, C_SYS_NUMPAD_PLUS
	jmp	TJT_findTenkey
next12:
	cmp	al, TT_SCAN_ZERO
	jne	next13
	mov	ax, C_SYS_NUMPAD_0
	jmp	TJT_findTenkey
next13:
	cmp	al, TT_SCAN_COMMA
	jne	next14
	mov	ax, C_COMMA
	jmp	TJT_findTenkey
next14:
	cmp	al, TT_SCAN_PERIOD
	jne	next15
	mov	ax, C_SYS_NUMPAD_PERIOD
	jmp	TJT_findTenkey
next15:
	cmp	al, TT_SCAN_SLASH
	jne	next16
	mov	ax, C_SYS_NUMPAD_DIVIDE
	jmp	TJT_findTenkey
next16:
	jmp	TJT_noTenkey

TJT_findTenkey:
	clr	ch
	stc						; set carry
	jmp	done
TJT_noTenkey:
	clc						; clear carry	
done:
	.leave
	ret
Toshiba84JTenkey	endp
endif

Resident	ends
