COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		keyboardInit.asm

AUTHOR:		Gene Anderson, Feb  8, 1990

ROUTINES:
	Name			Description
	----			-----------
	KbdInit			initialize the keyboard driver
	KbdExit			clean up and exit the keyboard driver

	KbdWriteCmd		write a command byte to the keyboard
	KbdReadData		read a data byte from the keyboard
	KbdWriteData		write a data byte from the keyboard

	KbdSetOptions		set geos.ini file specified options

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/ 8/90		Initial revision

DESCRIPTION:
	Initialization and exit routines for keyboard driver
		
	$Id: keyboardInit.asm,v 1.1 97/04/18 11:47:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn	HARDWARE_TYPE, <PC>
Movable segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the keyboard driver
CALLED BY:	KbdStrategy

PASS:		ds - seg addr of idata
RETURN:		carry	- set on error
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
	Install our interrupt vector and initialize our state.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/8/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
keyboardCategoryStr	char	"keyboard", 0

keyboardTypematicStr	char	"keyboardTypematic", 0
keyboardDoesLEDS	char	"keyboardDoesLEDs", 0
keyboardAltGrStr	char	"keyboardAltGr", 0
keyboardShiftRelStr	char	"keyboardShiftRelease", 0
keyboardSwapCtrlStr	char	"keyboardSwapCtrl", 0
keyboardForceXT		char	"forceXT", 0
keyboardForceAT		char	"forceAT", 0

KbdInitFar	proc	far
	uses	es
	.enter
	mov	ax, ds
	mov	es, ax				;es <- seg addr of idata
EC <	test	ds:[kbdStratFlags], mask KSF_HAVE_INT_VEC	>
EC <	ERROR_NZ	KBD_NESTED_INIT		;>

						;show we have int vec now.
	or	ds:[kbdStratFlags], mask KSF_HAVE_INT_VEC
	mov	ds:[kbdOutputProcHandle],-1	;init to NO process (-1)
	;
	; See if the controller is XT- or AT-style.
	;
	call	CheckControllerType
	;
	; Set up to catch the keyboard interrupt.
	;
	INT_OFF					;disable ints while setting
	mov	ax, SDI_KEYBOARD
	mov	bx, segment Resident
	mov	cx, offset Resident:KbdInterrupt
	mov	di, offset kbdVector
	call	SysCatchDeviceInterrupt		;install our interrrupt handler

; Flush keyboard buffer by setting the head pointer to equal tail pointer
	push	ds, ax
	mov	ax, BIOS_SEG
	mov	ds, ax
	mov	ax, ds:[BIOS_KEYBOARD_BUFFER_TAIL_POINTER]
	mov	ds:[BIOS_KEYBOARD_BUFFER_HEAD_POINTER], ax
	pop	ds, ax

; Make sure keyboard interrupt enabled in 8259
	in	al, ICMASKPORT
	and	al, not (1 shl SDI_KEYBOARD)	;keyboard interrupts at level 1
	out	ICMASKPORT, al

	INT_ON					;turn interrupts back on

	;
	; See if the geos.ini file option "keyboardDoesLEDs"
	; is set.  This means this is an XT-level machine
	; that actually has a semi-intelligent keyboard controller,
	; and it won't freeze up when told to toggle the LEDs.
	;
	mov	dx, offset keyboardDoesLEDS
	mov	bl, mask KO_DOES_LEDS
	call	CheckKeyboardOption

	clr	cx				;cx <- timeout count
KI_Empty:
	in	al, KBD_STATUS_PORT		;wait for data buffer empty
	test	al, mask KSB_INPUT_BUFFER_FULL	;test for input buffer full
	loopnz	KI_Empty			;if full, loop & wait

	push	es
	mov	ax, BIOS_SEG			; state from BIOS. The bits
	mov	es, ax				; are in the same order in
	mov	al, es:[BIOS_KBD_STATE]		; BIOS-land as in our land,
	mov	cl, BIOS_KBD_SCROLL_LOCK_OFFSET	; but are in a different
	shr	al, cl				; place
	and	al, 7				; mask out all but three
	mov	ds:[kbdModeIndState], al	; interesting bits.
	mov	ds:[kbdToggleState], al
	pop	es

	mov	ah, al				;ah <- current state
	mov	al, KBD_CMD_SET_LED		;al <- command to send
	call	SetKbdStateFar			;set kbd LED's correctly
	;
	; See if there are settings in geos.ini file to set the
	; typematic rate and delay. Otherwise, don't mess with
	; them at all so users that set them don't get upset.
	;
	push	ds
	segmov	ds, cs, cx
	mov	si, offset keyboardCategoryStr	;ds:si <- ptr to category
	mov	dx, offset keyboardTypematicStr	;cx:dx <- ptr to key
	call	InitFileReadInteger		;ax == integer
	pop	ds
	jc	afterTypematic			;branch if no entry
	andnf	al, mask KT_TYPEMATIC_MAN \
		 or mask KT_TYPEMATIC_EXP \
		 or mask KT_DELAY
	mov	ds:[kbdTypematicState], al
	mov	ah, al				;ah <- current state
	mov	al, KBD_CMD_SET_TYPEMATIC	;al <- command
	call	SetKbdStateFar
afterTypematic:
	;
	; See if this a #$%@?! European keyboard, and make
	; the right <Alt> key behave the same as <Ctrl><Alt>
	; if it is...
	;
	call	KbdSetOptions

if PZ_PCGEOS ; Pizza
	mov	al, KBD_CMD_SET_JAPANESE_MODE
	out	KBD_COMMAND_PORT, al		; set Japanese mode
endif

	mov	bx, offset kbdMonitor
	mov	al, ML_DRIVER			; put at Processing LEVEL 20
						; (conversion to hardware
						;	independent info)
	mov	cx, segment Resident		; segment for monitor routine
	mov	dx, offset Resident:KbdMonRoutine	; routine to use
	call	ImAddMonitor			; Add Kbd driver as an
						;	input monitor
						; Returns process handle of
						; User Input manager
	mov	ds:[kbdOutputProcHandle], bx	; copy process handle

	.leave
	clc					; no error
	ret
KbdInitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKeyboardOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a keyboard driver geos.ini file option
CALLED BY:	KbdInit(), KbdSetOptions()

PASS:		cs:dx - ptr to key ASCIIZ string
		ds - seg addr of idata
		bl - KeyboardOptions to set
RETURN:		carry - clear if keyboard option set
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckKeyboardOption	proc	near
	.enter
	;
	; Check the appropriate category
	;
	push	ds
	segmov	ds, cs, cx
	mov	si, offset keyboardCategoryStr
	call	InitFileReadBoolean
	pop	ds
	jc	error				;branch if error
	tst	al				;clear carry
	jz	error				;branch if FALSE
	ornf	ds:keyboardOptions, bl		;set bit in options
done:
	.leave
	ret

error:
	stc
	jmp	done
CheckKeyboardOption	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the right <Alt> key a <Alt Gr> key and other options
CALLED BY:	KbdInit()

PASS:		ds - seg addr of idata
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdSetOptions	proc	near
	uses	cx, dx, si, di
	.enter

	;
	; See if the geos.ini file sets "keyboardAltGr = TRUE"
	;
	mov	dx, offset keyboardAltGrStr
	mov	bl, mask KO_ALT_GR
	call	CheckKeyboardOption
	jc	notAltGr			;branch if FALSE
	;
	; Set the right <Alt> key to act as <Ctrl><Alt>,
	; and return <Alt Gr> for a character value.
	;
if DBCS_PCGEOS
	mov	ds:KeyboardMap.KT_keyDefTab[\
		    (SCANCODE_RIGHT_ALT-1)*(size KeyDef)].KD_char, C_SYS_ALT_GR
else
	mov	ds:KeyboardMap.KT_keyDefTab[\
		    (SCANCODE_RIGHT_ALT-1)*(size KeyDef)].KD_char, VC_ALT_GR
endif
	mov	ds:KeyboardMap.KT_keyDefTab[\
		    (SCANCODE_RIGHT_ALT-1)*(size KeyDef)].KD_shiftChar,\
			RCTRL or RALT
notAltGr:
	;
	; See if the geos.ini file sets "keyboardShiftRelease = TRUE"
	; Set the <Shift> keys to release the <Caps Lock> key if it is.
	;
	mov	dx, offset keyboardShiftRelStr
	mov	bl, mask KO_SHIFT_RELEASE
	call	CheckKeyboardOption

	;
	; See if geos.ini file sets "keyboardSwapCtrl = TRUE"
	;
	mov	dx, offset keyboardSwapCtrlStr
	mov	bl, mask KO_SWAP_CTRL
	;
	; Is the option already set?  If it is already set, we've
	; (theorectically) already been called.  This check is done
	; to prevent things like swapping <Ctrl> and <Caps Lock>
	; from occuring twice when task-switching to and from PC/GEOS.
	;
	test	ds:keyboardOptions, bl
	jnz	notSwapCtrl			;branch if already set
	call	CheckKeyboardOption
	jc	notSwapCtrl
	;
	; Swap the meaning of left <Ctrl> and <Caps Lock>
	;
	push	es
	lea	si, ds:KeyboardMap.KT_keyDefTab[\
		    (SCANCODE_LEFT_CTRL-1)*(size KeyDef)]
	lea	di, ds:KeyboardMap.KT_keyDefTab[\
		    (SCANCODE_CAPS_LOCK-1)*(size KeyDef)]
	mov	cx, (size KeyDef)		;cx <- # bytes to swap
ko_loop:
	lodsb					;mov al, ds:[si++]
	xchg	ds:[di], al
	mov	ds:[si][-1], al
	inc	di
	loop	ko_loop

	pop	es
notSwapCtrl:

	.leave
	ret
KbdSetOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves
CALLED BY:	KbdStrategy

PASS:		ds - seg addr of idata
RETURN:		carry	- set on error
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/8/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdExitFar	proc	far
	uses	es
	.enter

	mov	ds:kbdShiftState, 0		;no modifiers down
	call	KeyboardTrackBiosShiftFar

	mov	ax, ds
	mov	es, ax				;es <- seg addr of idata

	;
	; If this an AT, put the controller back the way we found it
	;
	test	ds:kbdStratFlags, mask KSF_USE_PC_ACK
	jnz	skipReset			; Skip this if on PC
	call	KbdResetCommandByte
skipReset:
EC <	test	ds:[kbdStratFlags], mask KSF_HAVE_INT_VEC	;>
EC <	ERROR_Z	KBD_NESTED_EXIT			;>
	;
	; Reset the interrupt vector.  NOTE: we do this after resetting
	; the command byte, because on some machines, namely those
	; with the new AMI extended BIOS, the act of reading the
	; keyboard status via KBD_CMD_GET_CCB causes a spurious keyboard
	; interrupt.  The old interrupt vector sees the status value 45h
	; as a scan code for <Num Lock>, which causes it to toggle the
	; LED.  However, because this isn't a real press, it never
	; gets a release, leaving the keyboard in a sort of <Num Lock>
	; limbo where it is neither on nor off.  Our interrupt vector
	; is already hacked to deal with spurious interrupts, and so
	; we blissfully ignore the silly thing.  -- eca 2/23/93
	;
	mov	ax, SDI_KEYBOARD
	mov	di, offset kbdVector
	call	SysResetDeviceInterrupt

	mov	bx, offset kbdMonitor	;ds:bx <- ptr to monitor
	mov	al, mask MF_REMOVE_IMMEDIATE	;al <- flags to monitor rout
	call	ImRemoveMonitor			;remove monitor

	andnf	ds:[kbdStratFlags], not mask KSF_HAVE_INT_VEC
	.leave
	clc					;no error
	ret
KbdExitFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdResetCommandByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the 8042's command byte to what it was on entry.

CALLED BY:	KbdExitFar, KbdSuspendFar
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, dx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Extracted from KbdExitFar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdResetCommandByte proc	near
	.enter
	;
	; First check to see if the command byte has changed.  If not,
	; we're done.  The reason we do this is that the controllers
	; on some machines don't respond quickly enough.  Rather than
	; put in delay loops (which I first tried, and couldn't find
	; delays long enough that worked), this approach was used.
	; Without this, the keyboard will behave fine in PC/GEOS, but
	; locks up when exiting (and hence when back in DOS) -- eca 5/20/92
	;
	test	ds:[kbdStratFlags], mask KSF_HOTKEY_PENDING
	jnz	reset				; cannot get command byte if
						;  hotkey is pending, as that
						;  would overwrite input
						;  buffer, which must contain
						;  scancode for external agent
						;  on whose behalf the hotkey
						;  was registered.

	call	KbdGetCCB

	cmp	al, ds:[kbdCmdByte]		;command byte changed?
	je	done
	
reset:
	;
	; The command byte is actually different, so set it back.
	;
	mov	ah, KBD_CMD_SET_CCB		; Set controller command byte
	call	KbdWriteCmd

	mov	ah, ds:[kbdCmdByte]		; back the way it was
	test	ds:[kbdStratFlags], mask KSF_HOTKEY_PENDING
	jz	writeCmdByte
	ornf	ah, mask KCB_DISABLE_KEYBOARD	; keep it disabled
writeCmdByte:
	call	KbdWriteData

done:
	.leave
	ret
KbdResetCommandByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdGetCCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the Controller Command Byte from the 8042.

CALLED BY:	(INTERNAL) KbdResetCommandByte, CheckControllerType
PASS:		nothing
RETURN:		al	= command byte
DESTROYED:	ah, cx
SIDE EFFECTS:	any received ACK or RESEND from the keyboard is *dropped*

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdGetCCB proc	near
	.enter
	;
	; Disable keyboard interrupts for the duration, so the command byte
	; is not interpreted as a keystroke (the command byte we use happens
	; to also be the scan code for the NumLock key; reading the byte as
	; a keystroke results in the set-LED sequence being sent, the ACKs for
	; which overwrite the command byte and we, and the keyboard, get mighty
	; confused).
	; 
	in	al, ICMASKPORT
	push	ax
	ornf	al, (1 shl SDI_KEYBOARD)	;keyboard interrupts at level 1
	out	ICMASKPORT, al

tryAgain:
	mov	ah, KBD_CMD_GET_CCB		;ah <- info requested
	call	KbdWriteCmd			;get controller command byte
	call	KbdReadData

	cmp	al, KBD_RESP_ACK
	je	tryAgain			; don't treat ACK coming back
						;  from the keyboard (WHY IS
	cmp	al, KBD_RESP_RESEND		;  IT COMING BACK? WE DIDN'T
	je	tryAgain			;  TALK TO THE SILLY THING)
						;  as a command byte.
	;
	; Reset the SDI_KEYBOARD bit to what it was before
	; 
	pop	cx
	xchg	ax, cx
	out	ICMASKPORT, al
	mov_tr	ax, cx
	.leave
	ret
KbdGetCCB endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the 8042 to its original state.

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer for error message
		ds	= dgroup (from KbdStrategy)
RETURN:		carry set on error
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSuspendFar	proc	far
		uses	cx
		.enter
		call	KbdResetCommandByte
		clc
		.leave
		ret
KbdSuspendFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdUnsuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the 8042 to the state we want it in.

CALLED BY:	DR_UNSUSPEND
PASS:		ds	= dgroup (from KbdStrategy)
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdUnsuspendFar	proc	far
		uses	cx
		.enter
		mov	ah, KBD_CMD_SET_CCB
		call	KbdWriteCmd
		
		mov	ah, ds:[kbdCmdByte]
	;
	; Keep only these bits.
	; 
		andnf	ah, mask KCB_XT_KEYBOARD or mask KCB_AUX_IEN or \
				mask KCB_SYSTEM_FLAG
	;
	; If KCB_XT_KEYBOARD set, don't set KCB_XLATE_SCAN_CODES...just in
	; case.
	; 
		mov	al, mask KCB_XLATE_SCAN_CODES or \
				mask KCB_INTERRUPT_ENABLE
; see comment of 7/16/92, below.
;		test	ah, mask KCB_XT_KEYBOARD
;		jz	setCmd
;		mov	al, mask KCB_INTERRUPT_ENABLE
;setCmd:
		ornf	ah, al
 		call	KbdWriteData
		.leave
		ret
KbdUnsuspendFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdWriteCmd, KbdWriteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a byte to the keyboard controller command or
		data port, making sure the buffer is empty first.  Since
		the controller provides no interrupt for its input buffer
		being empty, we have to busy wait (generally a very small
		amount of time, if any, fortunately).
CALLED BY:	INTERNAL
PASS:		ah	- CMD/data to send
RETURN:		none
DESTROYED:	ax, cx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdWriteCmd	proc	near
	call	WaitABit			;cx <- timeout count = 0
KSC10:
	in	al, KBD_STATUS_PORT		;wait for buffer empty
	test	al, mask KSB_INPUT_BUFFER_FULL	;test for input buffer full
	loopnz	KSC10				;if full, loop & wait
	mov	al,ah				;al <- command byte
	out	KBD_COMMAND_PORT, al		;out to KBD_COMMAND_PORT
	ret
KbdWriteCmd	endp

KbdWriteData	proc	near
	call	WaitABit			;cx <- timeout count = 0
KSD10:
	in	al, KBD_STATUS_PORT		;wait for buffer empty
	test	al, mask KSB_INPUT_BUFFER_FULL	;test for input buffer full
	loopnz	KSD10				;if full, loop & wait
	mov	al,ah				;al <- data byte
	out	KBD_DATA_PORT, al		;out to KBD_DATA_PORT
	ret
KbdWriteData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WaitABit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait a small amount of time for hardware to catch up...
CALLED BY:	(F)UTILITY

PASS:		none
RETURN:		cx = 0
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine exists simply because PC keyboard hardware is
	sometimes scrod.  This routine waits a little bit, the idea
	being allowing the keyboard hardware some time to do what it
	was told to do.
	This is only called during DR_INIT and DR_EXIT when we are
	writing to and reading from the keyboard controller, so the
	concept of a delay loop isn't as horrendous as it may sound.
							-- eca 5/20/92
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WaitABit	proc	near
	mov	cx, 0xeca
waitLoop:
	jmp	$+2				;clear ye olde pre-fetch queue
	loop	waitLoop
	ret
WaitABit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves a data byte from the keyboard controller, waiting
		for it to be available
CALLED BY:	UTILITY

PASS:		none
RETURN:		al	- Data byte
DESTROYED:	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since this routine busy-waits, it should not be used in
	cases where the data is not expected to be available
	immediately.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdReadData	proc	near
	call	WaitABit			;cx <- timeout count = 0
KGD10:
	in	al, KBD_STATUS_PORT		;wait for buffer full
	test	al, mask KSB_OUTPUT_BUFFER_FULL	;test for ouput buffer full
	loopz	KGD10				;if not, loop & wait
	in	al, KBD_DATA_PORT		;al <- byte from KBD_DATA_PORT
	ret
KbdReadData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckControllerType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if this keyboard communicates as an XT or AT.
CALLED BY:	KbdInitFar()

PASS:		ds - seg addr of dgroup
RETURN:		ds:kbdStratFlags - set to KSF_USE_PC_ACK if appropriate
		carry - set if XT
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckControllerType	proc	near
	uses	ax
	.enter

	
	mov	dx, offset keyboardForceAT
	mov	bl, mask KO_FORCE_AT
	call	CheckKeyboardOption
	jnc	isAT				;branch if TRUE
	mov	dx, offset keyboardForceXT
	mov	bl, mask KO_FORCE_XT
	call	CheckKeyboardOption
	INT_OFF
	jnc	isXT				;branch if TRUE
	;
	; Determine whether we are on PC or AT to handle different
	; keyboards.  On the AT the KBD_PC_CTRL_PORT location can not
	; have its high bit changed. So we try and change it. If it
	; changes, voila, it's not an AT.
	;
	; NOTE: attempting to base this decision based on the
	; CPU type is a bad idea, since the usage of keyboard
	; controllers is not consistent between XT- and AT-level
	; machines.  This test seems to generate better results.
	;
	in	al, KBD_PC_CTRL_PORT		;al <- get special info
	mov	ah,al				;ah <- save info
	or	al, KBD_ACKNOWLEDGE		;set high bit 
	out	KBD_PC_CTRL_PORT, al		; 
	in	al,KBD_PC_CTRL_PORT		;al <- new special info
	xchg	al,ah				;ah <- changed? results
	out	KBD_PC_CTRL_PORT, al		;return kbd to orig state
	test	ah, KBD_ACKNOWLEDGE		;high bit changed?
	jz	isAT				;branch if unchanged (ie. AT)
	;
	; The controller is XT-style, so we must send ACKs.
	;
isXT:
	ornf	ds:kbdStratFlags, mask KSF_USE_PC_ACK

done:
	INT_ON
	.leave
	ret

	;
	; The controller is AT-style.  Tell it to emulate
	; an XT-style controller since that's what we
	; speak to.
	; This controller can handle LEDs.
	; This controller does not need ACKs.
	;
isAT:
	INT_OFF
	ornf	ds:keyboardOptions, mask KO_DOES_LEDS
	andnf	ds:kbdStratFlags, not (mask KSF_USE_PC_ACK)

	;
	; NOTE: This causes anything already buffered to be overwritten
	;
	call	KbdGetCCB
	;
	; For some reason, some keyboard controllers (eg. Gateway)
	; have the "disable keyboard" bit set when we read the command
	; byte. This is bad thing, so we ignore this bit.  Whether this
	; is due to timing (too little time between writing to the command
	; port and reading from the data port), cosmic rays, or what, I'm
	; not sure, but this seems a reasonable precaution -- eca 5/20/92
	;
	andnf	al, not (mask KCB_DISABLE_KEYBOARD)
	mov	ds:[kbdCmdByte], al		;save the command value

	push	ax
	mov	ah, KBD_CMD_SET_CCB		;Request setting of controller
	call	KbdWriteCmd			;	command byte
	pop	ax
	;
	; Set our version of the command byte. If the controller is set
	; to support an XT keyboard or to interrupt on its auxiliary port, we
	; maintain those settings. We always tell it to xlate from AT to XT
	; scan codes (in theory, this should not conflict with KCB_XT_KEYBOARD)
	; and to interrupt when data are available.
	; 
	mov	ah, mask KCB_XLATE_SCAN_CODES or \
			mask KCB_INTERRUPT_ENABLE
	;
	; If KCB_XT_KEYBOARD set, don't set KCB_XLATE_SCAN_CODES...just in
	; case.
	;
	; 7/16/92: there's a Compaq laptop (2810) on which the KCB_XT_KEYBOARD
	; doesn't seem to indicate what we think it indicates. If we don't
	; set both KCB_XT_KEYBOARD and KCB_XLATE_SCAN_CODES, we get hosed.
	; So we set them both, since it seems to do no harm on other machines;
	; we were just being cautious when we coded this -- ardeb
	; 
;	test	al, mask KCB_XT_KEYBOARD
;	jz	setCmd
;	mov	ah, mask KCB_INTERRUPT_ENABLE
;setCmd:
	andnf	al, mask KCB_XT_KEYBOARD or mask KCB_AUX_IEN or \
			mask KCB_SYSTEM_FLAG
	or	ah, al
	call	KbdWriteData
	jmp	done
CheckControllerType	endp

Movable	ends
endif



if	VG230SCAN

Movable segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the keyboard driver

CALLED BY:	KbdInit

PASS:		DS	= DGroup

RETURN:		Carry	= Set if error

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		Install interrupt vector & initialize state
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		Todd	12/19/94	Stolen for Jedi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdInitFar	proc	far
	.enter
	;
	;  Intercept that-there Keyboard IRQ, and turn off 
	;  INT's so we don't get a char while we're partially
	;  dressed.  Yeek!
	mov	ax, SDI_KEYBOARD
	mov	bx, segment Resident
	mov	cx, offset  Resident:KbdInterrupt
	mov	di, offset kbdVector
	INT_OFF
	call	SysCatchDeviceInterrupt	;install our interrrupt handler

	;
	; Add ourselves to the input monitor chain
	mov	al, ML_DRIVER
	mov	bx, offset kbdMonitor
	mov	cx, segment KbdMonRoutine
	mov	dx, offset  KbdMonRoutine
	call	ImAddMonitor		; input manager hande => BX

	mov	ds:[kbdOutputProcHandle], bx


	;
	; Re-enable INT's.  We're decent.
	INT_ON

	.leave
	ret
KbdInitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdExitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	KbdExit

PASS:		DS	= DGroup

RETURN:		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We leave keyboard scanning disabled

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		Todd	12/19/94	Stolen for Jedi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdExitFar	proc	far
	.enter
	; Replace the interrupt vector
	;
	mov	ax, SDI_KEYBOARD
	mov	di, offset kbdVector
	call	SysResetDeviceInterrupt

	;
	; Remove the keyboard monitor
	mov	bx, offset kbdMonitor	; Monitor => DS:BX
	mov	al, mask MF_REMOVE_IMMEDIATE
	call	ImRemoveMonitor		; remove monitor

	clc

	.leave
	ret
KbdExitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend keyboard input

CALLED BY:	KbdSuspend

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		Todd	12/19/94	Stolen for Jedi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSuspendFar	proc	far
		clc
		ret
KbdSuspendFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdUnsuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend keyboard input

CALLED BY:	KbdUnsuspend

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		Todd	12/19/94	Stolen for Jedi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdUnsuspendFar	proc	far
		clc
		ret
KbdUnsuspendFar	endp

Movable	ends
endif

if	_E3G_KBD_SCAN

    ;
    ; All of the I/O for Responder is done in the responder library.  For
    ; Penelope, since we don't plan on all the I/O changing as it did
    ; Responder, the I/O is done directly in this driver.  I'd expect any
    ; future products with the E3G to do the same.
    ;

Movable segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the E3G keyboard driver

CALLED BY:	KbdInit

PASS:		DS	= DGroup

RETURN:		Carry	= Set if error

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		Install interrupt vector & initialize state
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		SSH	05/02/95	Responder version
		JimG	06/11/96	E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
keyboardCategoryStr	char	"keyboard", 0
keyboardTypematicStr	char	"keyboardTypematic", 0
KbdInitFar	proc	far
		.enter
	;
	; This keyboard driver loads the KeyDefTable's and
	; ExtendedDefTable's from a resource. This is done so that we can
	; localize the keyboard driver without having to compile a new
	; version.
	; 
		call	KbdKeyTableInit		
	;
	;  Intercept that-there Keyboard IRQ, and turn off 
	;  INT's so we don't get a char while we're partially
	;  dressed.  Yeek!
	;
		INT_OFF
	;
	; For Penelope, enable the scanning keyboard.  On the OP1
	; prototypes, the default is to use the standard PC keyboard.
	;
PENE <		mov	dx, E3G_GLOBALDIS				>
PENE <		in	ax, dx						>
PENE <		and	ax, not mask EGDF_DISKS	; Enable Kbd Scan	>
PENE <		out	dx, ax						>
	;
	; Enable the key scanner and mask the IRQ.
	;


	    ; Enables keyboard IRQ and registers with the keyboard/digitizer
	    ; interlock mechanism.
	    ;
PENE <		mov	cl, PKDID_KEYBOARD				>
PENE <		call	PeneKDIRegister					>

    	    ; Register a callback for a timer for Penelope which is used to
	    ; pause before unmasking the digitizer interrupt because of
	    ; these annoying capacitors that effectively hold the touchint
	    ; line high for a certain amount of time after a keyscan.
	    ;
PENE <		push	di						>
PENE <		mov	dx, segment KbdPeneTimerCB			>
PENE <		mov	di, offset KbdPeneTimerCB			>
PENE <		call	PeneTimerRegister				>
PENE <		pop	di						>
	;
	; Setup the scanmode and the debounce time (KBCTRL).
	;
		mov	al, KBD_INT_MODE
		KbdE3G_SetCtrl
	;
	; Enable all the row sense inputs by setting the keyboard interrupt
	; enabled register (KBINTEN).
	;
		mov	ax, KBD_INT_ALL_MASK
		KbdE3G_SetIntEnable
	;
	; Drive out on all columns (KBOUT).
	;
		mov	al, 0x00
		KbdE3G_SetScanOut
	;
	; Enable all the keyboard scan columns (KBENABLE).
	;
		mov	al, KBD_SCAN_ALL_MASK
		KbdE3G_SetScanEnable
	;
	; Read the high keyboard return register (KBIN) to clear interrupt.
	;
		KbdE3G_GetInput
	;
	; Set the new interraupt handler vector.
	;
		push	es
		mov	bx, segment Resident
		mov	cx, offset  Resident:KbdInterrupt
		segmov	es, ds, di		
		mov	di, offset kbdVector


PENE <		mov	ax, PENE_KEYBOARD_IRQ				>
PENE <		call	SysCatchDeviceInterrupt				>
		pop	es
	;
	; Add ourselves to the input monitor chain
	;
		mov	al, ML_DRIVER
		mov	bx, offset kbdMonitor
		mov	cx, segment KbdMonRoutine
		mov	dx, offset  KbdMonRoutine
		call	ImAddMonitor		; input manager hande => BX
		mov	ds:[kbdOutputProcHandle], bx
	;
	; Re-enable INT's.  We're decent.
	;
		INT_ON
	;
	; Send a non-specific EOI to the interraupt controler.
	;
		mov	al, IC_GENEOI
		out	IC2_CMDPORT, al
		out	IC1_CMDPORT, al
	;
	; See if there are settings in geos.ini file to set the
	; typematic rate and delay.
	;
	; The typematic is stored the following way:
	;
	; High byte: Typematic delay (value * 25ms = delay).
	; Low byte:  Typematic rate  (1000/(value * 25ms) = rate).
	; 	
	; If there is no entry we use the default value KBD_TYPEMATIC.
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset keyboardCategoryStr
		mov	dx, offset keyboardTypematicStr
		call	InitFileReadInteger	; ax == integer
		pop	ds
		jc	done			; branch if no entry
	;
	; Store the typematic value in dgroup.
	;
		mov	ds:[kbdTypematicValue], ax	
done:
		.leave
		clc
		ret
KbdInitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdKeyTableInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the KeyDef tables from the keyboard data file into
		dgroup.

CALLED BY:	KbdInitFar
PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		dgroup's KbdKeyDefTable and KbdExtendedDefTable Initialized.


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		SH	5/11/95    	Initial version
		JimG	06/11/96	E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdKeyTableInit	proc	near
		uses	ds
		.enter
	;
	; Change to the current language privdata directory.
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
	;
	; Open the keyboard data file.  If FileOpen returns an error
	; then we bail and use the English version as default.
	;
		push	ds
		mov	al, FILE_ACCESS_R or FILE_DENY_RW
		segmov	ds, cs
		mov	dx, offset cs:[kbdDataFile]
		call	FileOpen	; ax <- FileHandle
		pop	ds
		jc	done
	;
	; Copy the KeyDef's from the file into dgroup.
	;
		mov	bx, ax		; bx <- FileHandle
		clr	al
		mov	cx, KBD_MAX_KEY_DEF * (size KeyDef)
		mov	dx, offset KbdKeyDefTable
		call	FileRead
	;
	; Copy the ExtendedDef's from the file into dgroup.
	;
		clr	al
		mov	cx, KBD_MAX_EXTENDED_DEF * (size ExtendedDef)
		mov	dx, offset KbdExtendedDefTable
		call	FileRead
	;
	; Close the file and be on our marry way.
	;
		call	FileClose
done:
		call	FilePopDir	
		.leave
		ret
KbdKeyTableInit	endp

kbdDataFile	char "KBD\\keymap.dat",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdExitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	KbdExit

PASS:		DS	= DGroup

RETURN:		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We leave keyboard scanning disabled

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		SSH	05/02/95	Responder version
		JimG	06/11/96	E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdExitFar	proc	far
		uses	es
		.enter
	;
	; Disable the scan logic and IRQ.
	;

	    ; Disables keyboard IRQ and unregisters with the keyboard/digitizer
	    ; interlock mechanism.
	    ;
PENE <		mov	cl, PKDID_KEYBOARD				>
PENE <		call	PeneKDIUnregister				>
	;
	; Replace the interrupt vector
	;
		segmov	es, ds
		mov	di, offset kbdVector
		
PENE <		mov	ax, PENE_KEYBOARD_IRQ				>
PENE <		call	SysResetDeviceInterrupt				>
	
	;
	; Remove the keyboard monitor
	;
		mov	bx, offset kbdMonitor	; Monitor => DS:BX
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor		; remove monitor
		clc

		.leave
		ret
KbdExitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend keyboard input

CALLED BY:	KbdSuspend

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		SSH	05/02/95	Responder version
		JimG	06/11/96	E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSuspendFar	proc	far
		clc
		ret
KbdSuspendFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdUnsuspendFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend keyboard input

CALLED BY:	KbdUnsuspend

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/17/92	Initial version
		SSH	05/02/95	Responder version
		JimG	06/11/96	E3G common version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdUnsuspendFar	proc	far
		clc
		ret
KbdUnsuspendFar	endp

Movable	ends
endif	; _E3G_KBD_SCAN

