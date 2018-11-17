COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		genpcKbd.asm

AUTHOR:		Todd Stumpf, Apr 26, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/26/96   	Initial revision


DESCRIPTION:
	Keyboard handler for Generic PC GDI driver.

	$Id: genpcKbd.asm,v 1.1 97/04/04 18:04:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the keyboard hardware

CALLED BY:	GDIInitInterface
PASS:		ds	-> dgroup
RETURN:		ax	<- ErrorCode
		carry set on error
DESTROYED:	bx, cx, dx, es allowed
SIDE EFFECTS:
		Latches new interrupt vector
		Enables keyboard interrupt

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NT_DRIVER
DllName DB      "GEOSVDD.DLL",0
InitFunc  DB    "VDDRegisterInit",0
DispFunc  DB    "VDDDispatch",0
endif
HWKeyboardInit	proc	near
  	uses	si
	.enter

	;
	;  Update ES with segment
	MOV_SEG	es, ds

if not NT_DRIVER	
	;
	; See if the controller is XT- or AT-style.
	;
	call	KbdCheckControllerType		; ax, bx, cx,
							; dx, si
							; destroyed
endif ; ! NT_DRIVER
	;
	; Set the isSwapCtrl variable, we need to know this info.
	;
	call	KbdSetSwapCtrl

	;
	; Set up to catch the keyboard interrupt.
	;
	INT_OFF					;disable ints while setting

	mov	ax, SDI_KEYBOARD			; ax -> IRQ level
	mov	bx, segment KbdInterrupt		; bx:cx -> new vector
	mov	cx, offset KbdInterrupt
	mov	di, offset oldKbdVector			; es:di -> old vector
	call	SysCatchDeviceInterrupt		; ax, bx, di destroyed

if not NT_DRIVER
	;
	; Flush BIOS keyboard buffer by setting the head
	; pointer to equal tail pointer..
	;
	push	ds, ax
	mov	ax, BIOS_SEG
	mov	ds, ax
	mov	ax, ds:[BIOS_KEYBOARD_BUFFER_TAIL_POINTER]
	mov	ds:[BIOS_KEYBOARD_BUFFER_HEAD_POINTER], ax
	pop	ds, ax

	;
	; Enable keyboard interrupt in controller.
	;
	in	al, IC1_MASKPORT
	and	al, not (1 shl SDI_KEYBOARD)
	out	IC1_MASKPORT, al
else	; NT_DRIVER

	;;
	;; Register with VDD
	;;
		
	; if we have already registered, don't do it again, buddy.

	cmp	ds:[vddHandle], 0
	jne	done

	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	
	;
	; Register the dll
	;
        ; Load ioctlvdd.dll
        mov     si, offset DllName                   ; ds:si = dll name
        mov     di, offset InitFunc                  ; es:di = init routine
        mov     bx, offset DispFunc                  ; ds:bx = dispatch routine
	
        RegisterModule
	nop
	mov	bx, dgroup
	mov	ds, bx
	mov	ds:[vddHandle], ax
endif
	INT_ON					;turn interrupts back on
		;

done:

	mov	ax, EC_NO_ERROR
	clc	
	.leave
	ret
HWKeyboardInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSetSwapCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the .ini file and get the swapCtrl setting.

CALLED BY:	INTERNAL: HWKeyboardInit
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	cx, dx, si, ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSetSwapCtrl	proc	near

		.enter

		push	ds
		segmov	ds, cs, cx
		mov	si, offset GDIKeyboardCategoryStr
		mov	dx, offset keyboardSwapCtrl
		call	InitFileReadBoolean
		pop	ds
		jc	done		; => no entry

		mov	ds:[isSwapCtrl], al	; set isSwapCtrl 
done:
		.leave
		ret
KbdSetSwapCtrl	endp

if not NT_DRIVER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdResetCommandByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL: KbdExitFar
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdResetCommandByteFar	proc	far
	call	KbdResetCommandByte
	ret
KbdResetCommandByteFar	endp
KbdResetCommandByte	proc	near
	.enter

	test	ds:[kbdHotkeyFlags], mask KHF_HOTKEY_PENDING
	jnz	reset
	;
	; First check to see if the command byte has changed.  If not,
	; we're done.  The reason we do this is that the controllers
	; on some machines don't respond quickly enough.  Rather than
	; put in delay loops (which I first tried, and couldn't find
	; delays long enough that worked), this approach was used.
	; Without this, the keyboard will behave fine in PC/GEOS, but
	; locks up when exiting (and hence when back in DOS) -- eca 5/20/92
	;
	call	KbdGetCCB

	cmp	al, ds:[kbdCmdByte]		;command byte changed?
	je	done

reset:
	;
	; The command byte is actually different, so set it back.
	;
	mov	ah, KBD_CMD_SET_CCB		; Set controller command byte
	call	KbdWriteCmd

	mov	ah, ds:[kbdCmdByte]		; back the way
							; it was
	test	ds:[kbdHotkeyFlags], mask KHF_HOTKEY_PENDING
	jz	writeCmdByte
	ornf	ah, mask KCB_DISABLE_KEYBOARD	; keep it disabled

writeCmdByte:
	call	KbdWriteData

done:
	.leave
	ret
KbdResetCommandByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCheckControllerType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if this keyboard communicates as an XT or AT.

CALLED BY:	HWKeyboardInit
PASS:		ds	-> seg addr of dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/12/91		Initial version
	todd	5/1/96		Stolen for GDI library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdCheckControllerType	proc	near
	.enter

	;
	;  See if the INI file tells us anything

	mov	dx, offset keyboardForceAT		; dx -> key offset
	mov	bl, mask KO_FORCE_AT			; bl -> option to set
	call	KbdCheckOption			; carry clear if set
						; si destroyed
	jnc	isAT	; => Must be AT

	mov	dx, offset keyboardForceXT		; dx -> key offset
	mov	bl, mask KO_FORCE_XT			; bl -> option to set
	call	KbdCheckOption			; carry clear if set
						; si destroyed
	jnc	isXT	; => Must be XT

	INT_OFF

	;
	; Try to determine whether we are on PC or AT to handle different
	; keyboards.  On the AT the KBD_PC_CTRL_PORT location can not
	; have its high bit changed. So we try and change it. If it
	; changes, voila, it's not an AT.
	;

	in	al, KBD_PC_CTRL_PORT		;al <- get special info
	mov	ah,al				;ah <- save info

	or	al, KBD_ACKNOWLEDGE		;set high bit 
	out	KBD_PC_CTRL_PORT, al		; 
	in	al,KBD_PC_CTRL_PORT		;al <- new special info
	xchg	al,ah				;ah <- changed? results
	out	KBD_PC_CTRL_PORT, al		;return kbd to orig state

	test	ah, KBD_ACKNOWLEDGE		;high bit changed?
	jz	isAT	; => not set

isXT:
	;
	; The controller is XT-style, so we must send ACKs.
	;
	mov	ds:[isXTKeyboard], -1

done:
	INT_ON
	.leave
	ret

isAT:
	;
	; The controller is AT-style.  Tell it to emulate
	; an XT-style controller since that's what we
	; speak to.

	INT_OFF
	clr	ds:[isXTKeyboard]

	;
	; NOTE: This causes anything already buffered to be overwritten
	;
	; For some reason, some keyboard controllers (eg. Gateway)
	; have the "disable keyboard" bit set when we read the command
	; byte. This is bad thing, so we ignore this bit.  Whether this
	; is due to timing (too little time between writing to the command
	; port and reading from the data port), cosmic rays, or what, I'm
	; not sure, but this seems a reasonable precaution -- eca 5/20/92
	;

	call	KbdGetCCB			; al <- command byte
						; ah, cx destroyed

	andnf	al, not (mask KCB_DISABLE_KEYBOARD)
	mov	ds:[kbdCmdByte], al		;save the command value

	push	ax
	mov	ah, KBD_CMD_SET_CCB		;Request setting of controller
	call	KbdWriteCmd			; ax, cx destroyed
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
	andnf	al, mask KCB_XT_KEYBOARD or mask KCB_AUX_IEN or \
			mask KCB_SYSTEM_FLAG
	or	ah, al
	call	KbdWriteData			; ax, cx destroyed
	jmp	done
KbdCheckControllerType	endp
endif	; !NT_DRIVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCheckOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a keyboard driver geos.ini file option
CALLED BY:	KbdInit(), KbdSetOptions()

PASS:		cs:dx	-> ptr to key ASCIIZ string
		ds	-> seg addr of idata
		bl	-> KeyboardOptions to set
RETURN:		carry clear if keyboard option set
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

keyboardCategoryStr	char	"keyboard", 0

keyboardForceXT		char	"forceXT", 0
keyboardForceAT		char	"forceAT", 0

GDIKeyboardCategoryStr	char	"GDI keyboard", 0
keyboardSwapCtrl	char	"swapCtrl", 0

KbdCheckOption	proc	near
	uses	ds
	.enter
	;
	; Check the appropriate category
	;

	MOV_SEG	ds, cs
	mov	cx, cs
	mov	si, offset keyboardCategoryStr
	call	InitFileReadBoolean
	jc	done	; => No entry

	tst_clc	al
	jnz	done	; => True

	stc						; false
done:
	.leave
	ret
KbdCheckOption	endp

if not NT_DRIVER
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdGetCCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the Controller Command Byte from the 8042.

CALLED BY:	(INTERNAL) KbdResetCommandByte, CheckControllerType
PASS:		nothing
RETURN:		al	<- command byte
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
	in	al, IC1_MASKPORT
	push	ax
	ornf	al, (1 shl SDI_KEYBOARD)	;keyboard interrupts at level 1
	out	IC1_MASKPORT, al

tryAgain:
	mov	ah, KBD_CMD_GET_CCB		;ah <- info requested
	call	KbdWriteCmd		; ax, cx destroyed
	call	KbdReadData		; al <- data
					; ah, cx destroyed

	cmp	al, KBD_RESP_ACK
	je	tryAgain			; don't treat ACK coming back
						;  from the keyboard (WHY IS
	cmp	al, KBD_RESP_RESEND		;  IT COMING BACK? WE DIDN'T
	je	tryAgain			;  TALK TO THE SILLY THING)
						;  as a command byte.
	;
	;	Reset the SDI_KEYBOARD bit to what it was before
	; 
	pop	cx
	xchg	ax, cx
	out	IC1_MASKPORT, al
	mov_tr	ax, cx
	.leave
	ret
KbdGetCCB endp
endif	;!NT_DRIVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdClearShiftState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL: HWKeyboardShutdown
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdClearShiftStateFar	proc	far
	call	KbdClearShiftState
	ret
KbdClearShiftStateFar	endp
KbdClearShiftState	proc	near
	.enter
	.leave
	ret
KbdClearShiftState	endp

if not NT_DRIVER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdWriteCmd, KbdWriteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a byte to the keyboard controller command or
		data port, making sure the buffer is empty first.  Since
		the controller provides no interrupt for its input buffer
		being empty, we have to busy wait (generally a very small
		amount of time, if any, fortunately).
CALLED BY:	INTERNAL
PASS:		ah	-> CMD/data to send
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
		WaitABit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait a small amount of time for hardware to catch up...
CALLED BY:	(F)UTILITY

PASS:		none
RETURN:		cx	<- 0
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
endif		; not NT_DRIVER
InitCode		ends

ShutdownCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up

CALLED BY:	INTERNAL: GDIShutdownInterface
PASS:		ds	-> dgroup
RETURN:		ax	<- KeyboardErrorCodes
		carry set if error
DESTROYED:	es, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardShutdown	proc	near
	.enter
		
	MOV_SEG	es, ds			; ds, es = dgroup

if not NT_DRIVER
	;
	;  Set keyboard back to "boring" state
	call	KbdClearShiftStateFar
endif	; ! NT_DRIVER

	INT_OFF
if NT_DRIVER
	pushf
	push	ax, ds
	mov	ax, dgroup
	mov	ds, ax
	mov	ax, ds:[vddHandle]
	UnRegisterModule
	pop	ax, ds
	popf
endif		; NT_DRIVER	

if not NT_DRIVER	
	;
	; If this an AT, put the controller back the way we found it
	;
	tst	ds:[isXTKeyboard]
	jnz	skipReset	; => no need
	
	call	KbdResetCommandByteFar

skipReset:
endif	; !NT_DRIVER
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
	mov	di, offset oldKbdVector
	call	SysResetDeviceInterrupt
	INT_ON

	mov	ax, EC_NO_ERROR
	clc					;no error

	.leave
	ret
HWKeyboardShutdown	endp

ShutdownCode		ends

CallbackCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKbdInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generic keyboard interrupt routine
CALLED BY:	IRQ2

PASS:		nothing
RETURN:		nothing
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
	Todd	4/26/96		Steal for GDI code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdInterrupt	proc	far
	uses	ds, es
	pusha
	.enter

	;
	;  Be a nice little interrupt...
	call	SysEnterInterrupt
	cld					;clear direction flag
	INT_ON


	;  Get handls on dgroup
	mov	ax, segment dgroup
	mov	ds, ax				;ds <- seg addr of driver
	mov	es, ax				; es too, for KbdCheckHotkey

if not NT_DRIVER	
	;
	;  See if we're on an AT or XT keyboard
	tst	ds:[isXTKeyboard]
	jnz	handleScancode

	;
 	;  Look for screwy PS/2 Model 40SX BIOS
	in	al, KBD_STATUS_PORT			; get kbd state
	test	al, mask KSB_OUTPUT_BUFFER_FULL		; possible problem?
	in	al, KBD_DATA_PORT			; get scan code
	jz	sendEOI	; => PS/2 BIOS jerking us around

	;
	;  We've grabbed a byte off the keyboard.
	;  It's either a scan-code, or status update.
	tst	al				; what did we get?
	jz	sendPCAck	; => buffer is overflowing
	cmp	al, KBD_RESP_ACK
	jae	handleFunkyCode	; => kbd controller code

handleScancode:
	;
	;  See if we've got an extended scan code here...
	mov	ah, al					; assume we do

	cmp	al, ds:kbdExtendedScanCodes[0]
	je	handleExtension
	cmp	al, ds:kbdExtendedScanCodes[1]
	je	handleExtension
	cmp	al, ds:kbdExtendedScanCodes[2]
	je	handleExtension
	cmp	al, ds:kbdExtendedScanCodes[3]
	je	handleExtension

	;
	;  Nope.  We're fine.  Make sure next extension
	;  is clear for the next scancode.
		clr	ah

handleExtension:
	tst	ah				; do we have an extension?
	xchg	ah, ds:[kbdScanExtension]	; get/clear scan code ext.
	jnz	sendPCAck	; => extended scan


	;
	;  Okay, we've got the complete scancode in AX.
	;  Now we need to tell everyone about it

	mov	cx, -1					; assume press 
	test	al, 080h				; is it release?
	jz	tellEm	; => release

	clr	cx					; actualyl release
	andnf	al, not (080h)				; clear release bit

tellEm:

	;
	;	Before telling them, we now handle the extended scan
	;	in here. For PC, we are converting the 16 bit extended scan to
	;	8 bit before handing that to the GDI driver.
	;
	tst	ah
	jz	callCallback
	call	ConvertExtCodes		; al = converted scan
						; bx, dl destroyed
	clr	ah

callCallback:

	;
	;	Hack for now...if scan code is 0 don't bother sending it
	;
	tst	ax
	jz	sendPCAck	

	;
	;	We can pass the scan code now

	mov	bx, ax					; bx -> scancode
	mov	ax, EC_NO_ERROR				; ax -> ErrorCode
	mov	di, offset keyboardCallbackTable	; di -> table to use
	mov	bp, offset GDINoCallback		; bp -> update routine
	;	call	GDICallCallbacks
	call	GDIHWGenerateEvents

sendPCAck:
	;
	;  We're done if we're an AT keyboard...
	tst	ds:[isXTKeyboard]
	jz	sendEOI

	;
	;  Strove msb to send ACK for XT keyboard
	in	al, KBD_PC_CTRL_PORT		; get state
	or	al, KBD_ACKNOWLEDGE		; set high bit
	out	KBD_PC_CTRL_PORT, al		; set state
	xor	al, KBD_ACKNOWLEDGE		; clear high bit
	out	KBD_PC_CTRL_PORT, al		; set state

else		;  NT_DRIVER
	
	mov	ax, ds:[vddHandle]
	;;
	;; Decide if this is caused be a keyboard event or a mouse event
	mov	bx, VDD_FUNC_GET_EVENT_TYPE
	DispatchCall
	jcxz	sendEOI
	cmp	cx, EVENT_KEYBD
	je	isKeyboard
	; must be a mouse event

	mov	bx, si		; buttonState
	mov	ax, 1
	call	MouseDevHandler
	jmp	sendEOI


isKeyboard:
	mov	bx, VDD_FUNC_GET_LAST_KEY	; get event type and arguments
	DispatchCall
	nop
	;;
	;; Get key from windows
	;;
	; bx <- trashed
	; cx <- scancode
	; dx <- 0 for release, -1 for press

NTcallCallback:
	;
	;	We can pass the scan code now
	mov	bx, cx					; bx -> scancode
	mov	cx, dx					; cx -> press/release
	mov	ax, EC_NO_ERROR				; ax -> ErrorCode
	mov	di, offset keyboardCallbackTable	; di -> table to use
	mov	bp, offset GDINoCallback		; bp -> update routine
	;	call	GDICallCallbacks
	;;
	;; See args fo KbdCallback in gdi keyboard driver
	call	GDIHWGenerateEvents
endif
sendEOI:
	mov	al, IC_GENEOI				; al <- Interrupt ACK
	out	IC1_CMDPORT,al				; set to controller

	call	SysExitInterrupt
	.leave
	popa
	iret

if not NT_DRIVER
handleFunkyCode:
	;
	;  See if we're sending stuff TO the keyboard...
	tst	ds:[kbdSQSize]				; anything in buffer?
	jz	handleScancode	; => Nope.

	cmp	al, KBD_RESP_RESEND			; should we send again?
	je	sendAgain	; => Yup.

	;
	;  Send next byte of outgoing packet
	dec	ds:[kbdSQSize]				; got any more left?
	jz	sendPCAck	; => Nope.

	;
	;  Shuffle everything left one char
	mov	cx, size kbdSendQueue - 1
	mov	bx, offset kbdSendQueue
sidestepLeft:
	mov	al, ds:[bx] + 1
	mov	ds:[bx] + 0, al
	inc	bx
	loop	sidestepLeft

sendAgain:
	mov	al, ds:[kbdSendQueue + 0] 	;get next char
	out	KBD_DATA_PORT, al		;out to KBD_DATA_PORT
	jmp	sendPCAck
endif
KbdInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardGetKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get any additional scancodes for interrupt

CALLED BY:	GDIKeyboardGetKey
PASS:		ds	-> dgroup
RETURN:		bx	<- scancode
		cx	<- TRUE if press, FALSE if release
		ax	<- KeyboardErrorCode
DESTROYED:	nothing
SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		We only report one scancode per interrupt.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardGetKey	proc	near
		.enter
		mov	ax, KEC_NO_ADDITIONAL_SCANCODES
		.leave
  		ret
HWKeyboardGetKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertExtCodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert extended keyboard scan codes.
CALLED BY:	INTERNAL: ProcessKeyElement

PASS:		ax	-> 16 bit scan code value
RETURN:		al	<- 8 bit scan code value
		carry set if extended shift
DESTROYED:	bx, dl

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/1/88		Initial version
	Gene	2/27/90		Added extended shift checks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertExtCodes	proc	near
		push	cx
	;
	;	Some keyboards have separate arrow and navigation keys
	;	in addition to the ones on the numeric keypad. When the
	;	keyboard is in the lowest emulation level that we use,
	;		<shift><ext-arrow>
	;	comes through as:
	;		<shift><ext-unshift><ext-arrow><ext-shift>
	;	This means that we would normally not be able to get
	;	an extended arrow key with <shift> being down. This is
	;	bad because some UIs specify <shift><arrow> as being a
	;	shortcut (distinct from just <arrow>). To get around this
	;	problem, we simply ignore extended shifts presses and
	;	releases, and the rest of the keyboard driver does the
	;	right thing...
	;

		cmp	ax, EXT_LSHIFT_PRESS
		je	extendedShift
		cmp	ax, EXT_RSHIFT_PRESS
		je	extendedShift

	;
	;	The <Break> key is an extended key similar to the separate
	;	arrow keys mentioned above, except it sents out <ext-ctrl>
	;	and the like.
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
		jmp	short CEC_100		;exit w/same code if no match
CEC_30:
		mov	al, ds:[bx].EMD_mappedScanCode	;al <- translated char
CEC_90:
		clc
		pop	cx
		ret

CEC_100:
	;
	;	New scheme that we use, we map the code to the new extension
	;
		add	al, EXT_CODE_OFFSET
		jmp	CEC_90
		
extendedShift:
		clr	al
		stc
		pop	cx
		ret

	;
	;	Here's the story: the <Break> character is on a variety
	;	of different keys on different types of keyboards, and is
	;	accessed by <ctrl>+<key>.  On extended keyboards, it is on
	;	a special key with <Pause>. This key sends out an <ext-unctrl>
	;	the way the extended arrow keys send out <ext-unshift>, and
	;	then sends out the same scan code as <Num Lock>.  On
	;	non-extended keyboards, the <Break> character is on the
	;	<Scroll Lock> key.
	;
	;	Given the above, if the "swap <Ctrl> and <Caps Lock>" option
	;	is selected, and an <ext-Ctrl> comes through, it should actually
	;	be treated as <Caps Lock> since that's where the <Ctrl> actually
	;	is now.  -- eca 2/22/91
	;
extendedCtrl:
		tst	ds:[isSwapCtrl]
		jz	afterCtrl
		mov	ax, SCANCODE_CAPS_LOCK
		jmp	afterCtrl
ConvertExtCodes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardPassHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass control to the previous keyboard-interrupt
		handler so it can recognize the hotkey
		
CALLED BY:	GDIKeyboardPassHotkey
PASS:		ds	-> dgroup
RETURN:		ax	<- KeyboardErrorCode
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardPassHotkey	proc	near

		.enter
	;
	;	Pass control off as if it were an interrupt
	;
		pushf
		cli
		call	ds:[oldKbdVector]

	;
	;	Flush keyboard buffer on return, in case no one was actually
	;	interested in the keystroke we just passed on.
	;
		INT_OFF
		push	ds
		mov	ax, BIOS_SEG
		mov	ds, ax
		mov	ax, ds:[BIOS_KEYBOARD_BUFFER_TAIL_POINTER]
		mov	ds:[BIOS_KEYBOARD_BUFFER_HEAD_POINTER], ax
		pop	ds		
		INT_ON

	;
	;	Re-enable the keyboard interface
	;
		call	HWKeyboardCancelHotkey

		mov	ax, EC_NO_ERROR
		clc
		
		.leave		
		ret
HWKeyboardPassHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardCancelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've decided not to hand off the keypress afterall,
		so re-enable the keyboard interface

CALLED BY:	GDIKeyboardCancelHotkey
PASS:		ds	-> dgroup
RETURN:		ax	<- KeyboardErrorCode
		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardCancelHotkey	proc	near

		.enter
if not NT_DRIVER		
		andnf	ds:[kbdHotkeyFlags], not mask KHF_HOTKEY_PENDING

	;
	;	Now enable the interface. For an 8042, we send just
	;	the appropiate command to its command port
	;
		tst	ds:isXTKeyboard
		jnz	enableXT

		mov	al, KBD_CMD_ENABLE_INTERFACE
		out	KBD_COMMAND_PORT, al
		jmp	done

enableXT:
	;
	;	For an XT, set the appropiate bit in the KBD_PC_CTRL_PORT
	;
		in	al, KBD_PC_CTRL_PORT
		ornf	al, mask XP61_KBD_DISABLE
		out	KBD_PC_CTRL_PORT, al
done:
endif
		mov	ax, EC_NO_ERROR
		clc
		
		.leave
		ret
HWKeyboardCancelHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardAddHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a hotkey to watch for. 

CALLED BY:	GDIKeyboardAddHotkey
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl =
				Chars/VChars)
		^lbx:si -> object to notify when the key is pressed
		bp	-> message to send it
		ds	-> dgroup 
RETURN:		ax	<- KeyboardErrorCode
		carry set if error
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardAddHotkey	proc	near
		uses	dx
		.enter
		mov	dx, offset KbdAddHotkeyLow
		call	KbdAddDelHotkeyCommon

		mov	ax, EC_NO_ERROR
		clc
		.leave
		ret
HWKeyboardAddHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardDelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a hotkey being watched for.

CALLED BY:	GDIKeyboardDelHotkey
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl =
			Chars/VChars)
		ds	-> dgroup
RETURN:		ax	<- KeyboardErrorCode
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:																              
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardDelHotkey	proc	near
		uses	dx
		.enter

		mov	dx, offset KbdDelHotkeyLow
		call	KbdAddDelHotkeyCommon		; nothing destroyed

		mov	ax, EC_NO_ERROR
		clc
		.leave
		ret
HWKeyboardDelHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAddHotkeyLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another entry into the hotkey table, if possible.

CALLED BY:	KbdAddHotkey via KbdAddDelHotkeyCommon
PASS:		ax	-> ShiftState/scan code pair
		ds:di	-> existing entry in table with same pair; di = 0 if
			  none
		^lbx:si	-> object to notify when typed
		bp	-> message to send it.
RETURN:		carry set if no room
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAddHotkeyLow	proc	near
		uses	cx, di
		.enter
		tst	di
		jnz	haveSlot
	;
	; Not passed a slot, so we have to find one that contains 0.
	; 
		mov	cx, MAX_HOTKEYS
		mov	di, offset keyboardHotkeys
		push	ax
		clr	ax
		repne	scasw
		pop	ax
		jne	error
	;
	; Found a slot. Figure what index it is in the array and set 
	; keyboardNumHotkeys as appropriate..
	; 
		dec	di
		dec	di
		sub	cx, MAX_HOTKEYS
		neg	cx
		cmp	cx, ds:[keyboardNumHotkeys]
		jbe	haveSlot
		mov	ds:[keyboardNumHotkeys], cx
haveSlot:
	;
	; Set flag indicating that we have hotkey
	;
		cmp	ax, SCANCODE_ILLEGAL
		jne	haveHotkey
		ORNF	ds:[kbdHotkeyFlags], mask KHF_ALL_HOTKEY
haveHotkey:
		ORNF	ds:[kbdHotkeyFlags], mask KHF_HAVE_HOTKEY

	;
	; Store the combination and the action descriptor in their respective
	; arrays.
	; 
		INT_OFF
		mov	ds:[di], ax
		mov	ds:[di][keyboardADHandles-keyboardHotkeys], bx
		mov	ds:[di][keyboardADChunks-keyboardHotkeys], si
		mov	ds:[di][keyboardADMessages-keyboardHotkeys], bp
		INT_ON
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
KbdAddHotkeyLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdDelHotkeyLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke a hotkey from the table

CALLED BY:	KbdDelHotkey via KbdAddDelHotkeyCommon
PASS:		ax	-> ShiftState/scanc code pair
		ds:di	-> slot i table where it may be found;
				di = 0 if not there.
RETURN:		carry set to stop enumerating scan codes
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdDelHotkeyLow	proc	near
		.enter
		tst	di
		jz	done			; not in table

		cmp	ax, SCANCODE_ILLEGAL
		jne	numHotkeys
		ANDNF	ds:[kbdHotkeyFlags], not (mask KHF_ALL_HOTKEY)
numHotkeys:
		dec	ds:[keyboardNumHotkeys]
		jnz	done
		ANDNF	ds:[kbdHotkeyFlags], not (mask KHF_HAVE_HOTKEY)
done:
		.leave
		ret
KbdDelHotkeyLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAddDelHotkeyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure all the various modifier/scancode combinations
		required to watch for a given modifier/character pair and
		call a callback function for each one, after seeing if
		the m/s combination is already in the table of known ones.

CALLED BY:	KbdAddHotkey, KbdDelHotkey
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl = Chars/VChars)
		ds 	-> dgroup
		cs:dx	-> near routine to call:
RETURN:		carry set if callback returned carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		figure out where we should look for the character (KeyDef or
			ExtendedDef) based on the modifiers
		foreach entry in the keymap:
			if KD_char matches character, ShiftState+current scan
				is a combination
			else if KD_keyType != KEY_PAD, KEY_SHIFT, KEY_TOGGLE,
					KEY_XSHIFT or KEY_XTOGGLE and
				appropriate char matches chararcter,
				ShiftState+current scan is a combination

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAddDelHotkeyCommon proc	near
		uses	ds, es, di
		.enter
	;
	;	If we get CharacterSet = VC_ISCTRL, and VChars =
	;	VC_INVALID_KEY, we redirect all keys.
	;
SBCS <		cmp	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY		>
DBCS <		cmp	cx, C_NOT_A_CHARACTER				>
		jne	normalAddDel

		push	ax
		clr	ah			; say we have no ShiftState
		call	KbdHKFoundScan
		pop	ax
		jmp	short done

normalAddDel:
		call	KbdFigureModifiedCharOffset
		MOV_SEG	es, ds			es <- dgroup
		push	ax
		mov	ax, segment InfoResource
		mov	ds, ax
		pop	ax
		mov	di, offset keyDefs
scanLoop:
		call	KbdHKCheckScan
		jnc	nextScan
		call	KbdHKFoundScan
		jc	done			; => callback returned
						;  carry set, so stop
nextScan:
		add	di, size KeyDef
		cmp	di, offset keyDefs + length keyDefs *size KeyDef
		jb	scanLoop
done:
		.leave
		ret
KbdAddDelHotkeyCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKCheckScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the character matches this scan code's character.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		al	-> second offset to check in key definition
		cx	-> character against which to match
		ds:di	-> KeyDef to check
		es	-> dgroup
RETURN:		carry set if matches
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKCheckScan 	proc	near
		uses	ax
		.enter
	;
	; Check modified form first.
	; 
		call	KbdHKCheckChar
		jc	done
	;
	; No match. Try unmodified form.
	; 
		mov	al, KD_char
		call	KbdHKCheckChar
done:
		.leave

		ret
KbdHKCheckScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKCheckChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the character matches that generated from a particular
		slot within a key definition.

CALLED BY:	KbdHKCheckScan
PASS:		al	-> if b7=0: offset within KeyDef to check
			  if b7=1: offset within ExtendedDef to check
		cx	-> character to compare
		ds:di	-> KeyDef to use
RETURN:		carry set if matches
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKCheckChar	proc	near
		uses	ax, bx, dx, di
		.enter
		mov	ah, ds:[di].KD_keyType
		tst	ah
		jz	done		; => scan not valid (carry clear)
	;
	; If the key is KEY_SOLO, it can never produce any char but
	; what's in KD_char (Chars/VChars) and KD_shiftChar (CharacterSet)
	; 
		mov	dh, ah
		andnf	dh, mask KDF_TYPE
		cmp	dh, KEY_SOLO
		jne	fetchChar
	
		mov	ax, {word}ds:[di].KD_char
		jmp	compare

fetchChar:
	;
	; State keys don't good hotkeys make...
	; 
		test	ah, mask KDF_STATE_KEY
		jnz	mismatch
	;
	; We'll need the offset in bx for fetching a byte...
	; 
		mov	bx, ax
		andnf	bx, 0x7f
	;
	; Fetch the character from the KeyDef or the ExtendedDef.
	; 
		test	al, 0x80	; requires extended def?
		jnz	checkExtended
	;
	; Fetch the char from the key def.
	; 
		mov	al, ds:[di][bx]
	;
	; Figure if it's virtual (ah <- CS_CONTROL) or normal (ah <- CS_BSW):
	; 	KEY_PAD, KEY_MISC
	; 
SBCS <			CheckHack <CS_BSW eq 0>				>
		clr	ah		; assume not virtual
		cmp	dh, KEY_PAD
		je	makeVirtual
		cmp	dh, KEY_MISC
		jne	compare
makeVirtual:
SBCS <		mov	ah, CS_CONTROL					>
DBCS <		mov	ah, CS_CONTROL_HB				>
		jmp	compare

checkExtended:
	;
	; If key has no extended definition, there's nowhere to check.
	; 
		test	ah, mask KDF_EXTENDED
		jz	mismatch
		
	;
	; Figure offset of extended entry in KbdExtendedDefTable
	; 
		mov	al, ds:[di].KD_extEntry
		clr	ah
		shl	ax
		shl	ax
		shl	ax
if DBCS_PCGEOS
			CheckHack <size ExtendedDef eq 16>
		shl	ax
else
			CheckHack <size ExtendedDef eq 8>
endif
		add	ax, offset extendedKeyDefs
	;
	; Fetch the bit that must be set in EDD_charSysFlags for the character
	; to be virtual and that must not be set in EDD_charAccents for the
	; character to be valid....?
	; 
		mov	dl, cs:[hkVirtBits-EDD_ctrlChar][bx]
		mov	dh, dl
		xchg	ax, bx
SBCS <		and	dx, {word}ds:[bx].EDD_charSysFlags		>
		add	bx, ax		; ds:bx <- &char
		mov	al, ds:[bx]
SBCS <			CheckHack <CS_BSW eq 0>				>
		clr	ah		; assume not virtual
		tst	dl
		jnz	makeVirtual
compare:
	;
	; AX is now the Chars/VChars + CharacterSet that would be generated
	; from the provided slot in the definition. See if it matches what we
	; were asked about.
	; 
		cmp	ax, cx
		je	flipCarry	; => yes; carry is clear, but want it
					;  set
mismatch:
		stc			; ensure carry will be clear when we
					;  complement it, signalling a mismatch
flipCarry:
		cmc
done:
		.leave
		ret
hkVirtBits	ExtVirtualBits	mask EVB_CTRL,		; EDD_ctrlChar
				mask EVB_SHIFT_CTRL,	; EDD_shiftCtrlChar
				mask EVB_ALT,		; EDD_altChar
				mask EVB_SHIFT_ALT,	; EDD_shiftAltChar
				mask EVB_CTRL_ALT,	; EDD_ctrlAltChar
				mask EVB_SHIFT_CTRL_ALT ; EDD_shiftCtrlAltChar
KbdHKCheckChar	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKFoundScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
SYNOPSIS:	Found a scan code that's acceptable. See if it's in the
		table of known hotkeys and call the callback appropriately.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl = Chars/VChars)
		ds:di	-> KeyDef
		cs:dx	-> callback routine
		es	-> dgroup
RETURN:		carry set if callback returned carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		callback is called:
			Pass:	ax	= ShiftState/scan code pair
				ds:di	= slot in table where pair is
					  located. di is 0 if not already
					  in the table
				es	= ds
				bx, si, bp as passed to KbdAddDelHotkeyCommon
			Return:	carry set to stop going through the table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKFoundScan	proc	near
		uses	ax, cx, di
		.enter
	;
	; Check character to see if all characters need to be redirected
	;
		mov	al, SCANCODE_ILLEGAL
SBCS <		cmp	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY		>
DBCS <		cmp	cx, C_NOT_A_CHARACTER				>
		je	haveScanCode
	;
	; Figure the scan code. We subtract size KeyDef from the start of
	; KbdKeyDefTable since scan codes start at 1.
	; 
		sub	di, offset keyDefs-size KeyDef
		shr	di
		shr	di
if DBCS_PCGEOS
			CheckHack <size KeyDef eq 8>
		shl	di
else
			CheckHack <size KeyDef eq 4>
endif
	;
	; Put the scan code into al.
	; 
		mov	cx, di
		mov	al, cl

haveScanCode:
	;
	; Now see if the thing's already in the table.
	; 
		mov	di, offset keyboardHotkeys
		segmov	ds, es
		mov	cx, ds:[keyboardNumHotkeys]
		jcxz	notInTable
		repne	scasw
		lea	di, ds:[di-2]
		je	callCallback
notInTable:
		clr	di
callCallback:
		call	dx
		.leave
		ret
KbdHKFoundScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdFigureModifiedCharOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the offset of the place to look for the character 
		within a key definition, given the set of modifiers to
		be applied.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		ah	-> ShiftState
RETURN:		al	<- if b7 is 0:
				offset of slot in KeyDef to check
			  if b7 is 1:
				offset of slot in ExtendedDef to check
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdFigureModifiedCharOffset proc near
		.enter
	;
	; Assume no modifiers.
	; 
		mov	al, offset KD_char
		tst	ah
		jz	done
		
		test	ah, mask SS_LSHIFT or mask SS_RSHIFT
		jz	notShifted
		
		mov	al, offset KD_shiftChar	; assume just shift
		test	ah, mask SS_LCTRL or mask SS_RCTRL
		jz	notShiftCtrl
		
		mov	al, offset EDD_shiftCtrlChar or 0x80
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done
		
		mov	al, offset EDD_shiftCtrlAltChar or 0x80
		jmp	done

notShiftCtrl:
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done		; => just shift
		
		mov	al, offset EDD_shiftAltChar or 0x80
		jmp	done

notShifted:
		mov	al, offset EDD_altChar or 0x80
		test	ah, mask SS_LCTRL or mask SS_RCTRL
		jz	done
		
		mov	al, offset EDD_ctrlChar or 0x80
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done

		mov	al, offset EDD_ctrlAltChar or 0x80
done:
		.leave
		ret
KbdFigureModifiedCharOffset endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWKeyboardCheckHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GDIKeyboardCheckHotkey
PASS:		al	-> ShiftState
		bx	-> scancode
RETURN:		ax	<- KeyboardErrorCode
		carry set if key processed
		carry clear if key not processed
DESTROYED:	bx, ds, es, dx, cx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWKeyboardCheckHotkey	proc	near

		.enter

if not NT_DRIVER
		mov	ah, al		; ah <- ShiftState	
		mov_tr	al, bl		; al <- scancode (PC's
				  	; scancode is a byte)
		mov	bl, ah		; store shiftState in bl

		mov	dx, segment dgroup
		mov	ds, dx			; ds <- dgroup
		MOV_SEG	es, ds	
		
		test	ds:[kbdHotkeyFlags], mask KHF_HAVE_HOTKEY
		jz	done

		push	ax
		mov	cx, ds:[keyboardNumHotkeys]
		mov	di, offset keyboardHotkeys

		test	ds:[kbdHotkeyFlags], mask KHF_ALL_HOTKEY
		jz	search
		mov	ax, SCANCODE_ILLEGAL	; search for special
						; key
search:
		repne	scasw
		pop	ax
		clc		
		jne	done

	;
	;	Pass the scan code and shift state in the message.
	;
		mov	ah, bl
		mov_tr	cx, ax			; cx = <ShiftState,
						; scan code>
	;
	;	Found a match. Disable the keyboard interface so the keyboard
	;	continues to store scan codes, but can't send them to
	;	us, thereby keeping the scancode in the keyboard data
	;	latch for the interested external party to read.
	; 
		tst	ds:[isXTKeyboard]
		jnz	disableXT

		mov	al, KBD_CMD_DISABLE_INTERFACE
		out	KBD_COMMAND_PORT, al
		jmp	sendNotification

disableXT:
		in	al, KBD_PC_CTRL_PORT
		andnf	al, not mask XP61_KBD_DISABLE
		out	KBD_PC_CTRL_PORT, al

sendNotification:
	;
	;	Flag the hotkey as pending so we know to keep tht
	;	interface disabled if we suspend
	;
		ornf	ds:[kbdHotkeyFlags], mask KHF_HOTKEY_PENDING

	;
	;	Load up the notification message and queue it.
	;
		mov	bx, ds:[di-2][keyboardADHandles-keyboardHotkeys]
		mov	si, ds:[di-2][keyboardADChunks-keyboardHotkeys]
		mov	ax, ds:[di-2][keyboardADMessages-keyboardHotkeys]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		stc
done:
endif
		mov	ax, EC_NO_ERROR
		clc
		.leave
		ret
HWKeyboardCheckHotkey	endp

CallbackCode		ends




























