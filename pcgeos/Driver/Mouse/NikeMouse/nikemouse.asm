COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER - NIKE PS2 mouse
FILE:		nikemouse.asm

AUTHOR:		Lulu Lin, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device 
	MouseDevHandler		Handler for interrupt
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	11/30/94   	Initial revision
	Dave	04/95		changes based on recently delivered information


DESCRIPTION:
	Device-dependent support for Nike PS2 mouse.	
		

	$Id: nikemouse.asm,v 1.8 95/05/11 18:29:46 dave Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Mouse		= 1

;DEBUG_MOUSE	=	TRUE


MOUSE_NUM_BUTTONS	= 2	; All brother mice have two buttons.
MOUSE_CANT_SET_RATE	= 1	; I don't change the report rate.
MOUSE_SEPARATE_INIT	= 1	; I use a separate Init resource
MOUSE_CANT_TEST_DEVICE	= 1	; No reliable way to test for this device.

include		mouseCommon.asm
	; Include common definitions/code.

include		timer.def



;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		length	mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	nikePS2Mouse
		lptr.char	0	; null-terminator

nikePS2Mouse	chunk.char	'Nike PS2 Mouse', 0

mouseInfoTable	MouseExtendedInfo	\
		mask	MEI_SERIAL	;nikePS2Mouse,\

CheckHack	<length mouseInfoTable eq length mouseNameTable>

MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment


;
;_______________________________________________________________________
;			RECEIVING BYTES FROM MOUSE
;
; Input buffer -- Nike PS2 Mouse input packets are structured strangely. They
; are three bytes long:
;
; Byte	B7 B6 B5 B4 B3 B2 B1 B0
; 0     yO xO yS xS R  R  rP lP
; 1      x Data
; 2	 y Data
;
;				y0 = y Data OverFlow, 1 = overflow
;				x0 = x Data OverFlow, 1 = overflow
;				yS = y Data Sign, 1 = negative
;				xS = x Data Sign, 1 = negative
;				R = Reserved
;				rP = right button pressed
;				lP = left button pressed
;
; The reading of a packet is performed by a state machine in MouseDevHandler.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
inputBuf	byte	2 dup(?)


;_____________________________________________________________________
;			MOUSE DRIVER SCHME
;
		even


mouseRates	label	byte	; To avoid assembly errors
MOUSE_NUM_RATES		equ	0
MAX_PARITY_ERROR	equ	10

mouseEnabled	byte	FALSE
inState		nptr

;
;_____________________________________________________________________
;			MOUSE HARDWARE DEFINITIONS


PSMousePacketByteOne	record
	PSMPB_Y_OVER:1		; bit 7 is y data overflow flag
	PSMPB_X_OVER:1		; bit 6 is x data overflow flag
	PSMPB_Y_SIGN:1		; bit 5 is y data sign flag
	PSMPB_X_SIGN:1		; bit 4 is x data sign flag
	:2			; bit 3, 2 reserved
	PSMPB_RIGHT_BUTTON:1	; bit 1 is Right Button status flag
	PSMPB_LEFT_BUTTON:1	; bit 0 is Left Button Status flag
PSMousePacketByteOne	end

PSMouseStatus	record
	:3			; not used
	PSMS_ENABLE:1		; bit 4 is PS circuit enable flag
	PSMS_RECEIVE:1		; bit 3 is receive flag
	PSMS_TRANSMIT:1		; bit 2 is transmit flag
	PSMS_PARITY:1		; bit 1 is parity bit
	:1			; not used
PSMouseStatus	end

MOUSE_RECEIVER_INTERRUPTS_ENABLED	equ	mask PSMS_ENABLE or \
			mask PSMS_RECEIVE or mask PSMS_PARITY

	; Locations to hold the register addresses 

MOUSE_STATUS_REG_IO_ADDRESS		equ	0x03f8
MOUSE_TRANSMIT_REG_IO_ADDRESS		equ	0x03f9
MOUSE_RECEIVE_REG_IO_ADDRESS		equ	0x03fa


NIKE_MOUSE_SET_DEFAULT_COMMAND		equ	0xf6
NIKE_MOUSE_READ_DATA_COMMAND		equ	0xeb
NIKE_MOUSE_STATUS_REQUEST_COMMAND	equ	0xe9
NIKE_MOUSE_SET_STREAM_MODE_COMMAND	equ	0xea
NIKE_MOUSE_ENABLE_COMMAND		equ	0xf4
NIKE_MOUSE_DISABLE_COMMAND		equ	0xf5
NIKE_MOUSE_RESEND_COMMAND		equ	0xfe
NIKE_MOUSE_RESET_COMMAND		equ	0xff

NIKE_MOUSE_COMMAND_ACK_1		equ	0xfa
NIKE_MOUSE_COMMAND_ACK_2		equ	0xaa
NIKE_MOUSE_COMMAND_ACK_3		equ	0
;
;______________________________________________________________________
;			SAVED INTERRUPT VECTOR
;
oldVector	fptr.far
;
;______________________________________________________________________
;			TIMER INTERRUPT SCHME
MOUSE_TIMER_PERIOD	equ	5	;seconds

timerRoutineLastCalled	byte	FALSE
timerHandle		word	?
timerID			word	?

;______________________________________________________________________
;			DEBUGGING STUFF
ifdef	DEBUG_MOUSE
HACK_BUF_SIZE   =       2000
hackPtr word    0
pbuf    byte    HACK_BUF_SIZE dup (0)
endif


idata		ends

;
;______________________________________________________________________
;			DEBUG MESSAGES
;
MOUSE_PARITY_ERROR					enum	Warnings
MOUSE_X_DELTA_OVERFLOW					enum	Warnings
MOUSE_Y_DELTA_OVERFLOW					enum	Warnings
MOUSE_BUTTONS_RECEIVED					enum	Warnings
MOUSE_X_DELTA_RECEIVED					enum	Warnings
MOUSE_Y_DELTA_RECEIVED					enum	Warnings
MOUSE_INTERRUPT_WITHOUT_RXF				enum	Warnings
MOUSE_PING_CALLED					enum	Warnings


;------------------------------------------------------------------------------
;		       INITIALIZATION/EXIT CODE
;------------------------------------------------------------------------------

;
; Include common definitions for serial mice
;
Init segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Initialize the PS Mouse

CALLED BY:	MouseInit
PASS:		DS=ES=dgroup
RETURN:		Carry clear if ok
DESTROYED:	DI

PSEUDO CODE/STRATEGY:
	
	bit	        B7   B6   B5   B4   B3   B2   B1     B0  
	name	        --   --   --   PSEN RXF  TXF  PARITY --
	read/write	--   --   --   R/W  R/W  R/W  R      --
	read default    --   --   --   0    0    1    0      --
	write default   --   --   --   0    0    0    0      --


	Set -- PSEN, RXF
	clr -- TXF, PARITY(?)

	Return with carry clear.
	
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should use error returns to determine what format the mouse is
	using. Unfortunately, I don't know if the mouse will ACCEPT any format,
	or if it requires its input to be in the same format as its output.
	We'll see.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	llin	11/29/94	Initial version
	mhussain 1/9/94		modified for NIKE 
	dave	04/13/94	fixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far	
		uses ax, bx, cx, dx, si, di
		.enter

ifdef	DEBUG_MOUSE
	 	clr     ax
        	mov     ds:hackPtr, ax
endif

        ;
        ; Install our interrupt handler
        ;
                INT_OFF
                mov     di, offset oldVector
                mov     bx, segment MouseDevHandler
                mov     cx, offset MouseDevHandler
                mov     ax, 6
                call    SysCatchDeviceInterrupt
                INT_ON

	;
	; Set the initial state we will receive data in.
	;
		mov	ds:[inState], offset Resident:MouseReceiveACK_1
	;
	; Initialize the PS Mouse control register to "disabled"
	;
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
		clr	al
		out	dx, al
	;
	; Enable IRQ6
	;
		in	al, 21h
		and	al, 0bfh
		out	21h, al
	;
	; PS Mouse control register: Parity=1, RXF=1, TXE=0, PSEN=1
	;		
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
		mov	al, MOUSE_RECEIVER_INTERRUPTS_ENABLED
		out	dx, al
	;
	; Send the "Reset" and "Enable" command to the mouse
	;
		mov	ds:[mouseEnabled], TRUE
	;


			;Send Reset________________
waitForTxE:
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
		in	al, dx
		test	al, mask PSMS_TRANSMIT
		jz	waitForTxE

ifdef	DEBUG_MOUSE
		mov	al, 0ddh	;transmit marker
		call	StuffPBuff
endif

		mov	dx, MOUSE_TRANSMIT_REG_IO_ADDRESS
		mov	al, NIKE_MOUSE_RESET_COMMAND

ifdef	DEBUG_MOUSE
		call	StuffPBuff
endif

		out	dx, al

					;re-enable mouse hardware.
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
					;enable receive interrupts this time.
		mov	al, MOUSE_RECEIVER_INTERRUPTS_ENABLED
		out	dx,al


	; Finally start the watchDog timer routine
	;
		mov	al,TIMER_ROUTINE_CONTINUAL
		mov	bx,segment Resident
		mov	si,offset Resident:MousePing
		mov	cx,60*MOUSE_TIMER_PERIOD
		mov	di,cx
		mov	bp, handle 0
		call	TimerStartSetOwner
		mov	ds:[timerHandle],bx
		mov	ds:[timerID],ax

		.leave
		ret
MouseDevInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the interrupt.  Not really necessary, but...

CALLED BY:	
PASS:		es - dgroup
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	12/ 8/94    	Initial version
	mhussain		changed a bit for NIKE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevExit	proc	far
		uses	ax, di
		.enter

		mov	ds:[mouseEnabled], FALSE

	;
	; First get rid of the watchDog timer

		mov	bx,ds:[timerHandle]
		mov	ax,ds:[timerID]
		call	TimerStop
	;
	; Send a disable command to mouse 
	;
		mov	ah, NIKE_MOUSE_DISABLE_COMMAND
		call	MouseSendControlCode

	;
	; Disable IRQ6
	;
		in	al, 21h
		or	al, 40h
		out	21h, al
	;
	; Put old vector back
	;
		INT_OFF
		mov	di, offset oldVector
        	mov     ax, 6
        	call    SysResetDeviceInterrupt
		INT_ON

		.leave
		ret
MouseDevExit	endp

Init ends

;------------------------------------------------------------------------------
;		  RESIDENT DEVICE-DEPENDENT ROUTINES
;------------------------------------------------------------------------------

Resident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the device.

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just call the device-initialization routine in Init		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice	proc	near
		.enter
		call	MouseDevInit
		.leave
		ret
MouseSetDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the receipt of a byte in the packet.

CALLED BY:	hardware interrupt
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	check if RXF full
		Y: check Parity Error
			Y: Add reset/resend(in debate)Command to outputBuf,
			   Increment currentBufOffset
			   Discard the current packet data (reset
						state machine)
			   Return to Interrupt
			N: Load byte from reciever register
			   Accumulate the byte into the current packet
			   Return to Interrupt
		N: return to Interrupt

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version
	chrisb	12/94		Modified for NIKE hardware
	mhussain 1/95		more modifications for NIKE
	dave	4/5/95		added CPU to Mouse transmission.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
		uses	ax, bx, cx, dx, ds
		.enter

		call	SysEnterInterrupt
		segmov	ds, dgroup, cx

	;
	; Preload the status image with the status from the GA.
	;
	        mov     dx, MOUSE_STATUS_REG_IO_ADDRESS
                in      al, dx
                mov	ah, al
	;
	; Read status. If no data has been received, do nothing
	;
		test	ah, mask PSMS_RECEIVE	;RxF?
ifdef	DEBUG_MOUSE
		WARNING_Z MOUSE_INTERRUPT_WITHOUT_RXF 
endif
		LONG jz	exit
	;
	; Read Receive data if Receiver is FULL
	;
		mov	dx, MOUSE_RECEIVE_REG_IO_ADDRESS
		in	al, dx

ifdef	DEBUG_MOUSE
		call	StuffPBuff
endif


	; the Parity bit as active low
		
		test	ah, mask PSMS_PARITY
ifdef	DEBUG_MOUSE
		WARNING_Z MOUSE_PARITY_ERROR 
endif
		LONG jz	error		;if we got a parity error resend...

		
		mov	bx, ds:[inState]	;get this service routine.
		call	bx			;call it
		mov	ds:[inState], bx	;stuff next service routine
	;
	; Initialize the PS Mouse control register,
	; re enable receive to interrupt
	;		
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
		mov	al, MOUSE_RECEIVER_INTERRUPTS_ENABLED
		out	dx, al
exit:
		mov	ds:[timerRoutineLastCalled],FALSE
	;
	; Send an EOI
	;
		mov	al, 20h
		out	20h, al
		call	SysExitInterrupt

		.leave
		iret

error:
		mov	ah, NIKE_MOUSE_RESEND_COMMAND
		call	MouseSendControlCode
		jmp	exit

MouseDevHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReceiveButtons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Service routine for the buttons State
CALLED BY:
	MouseDevHandler 

PASS:
	al	- byte from mouse
	ah	- status byte for this transmission
	bx	- address of the service routine called for this state
	ds	- Segment of dgroup

RETURN:
	bx	- address of next routine to call.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReceiveButtons	proc	near
	;
	; We're starting a new packet -- record button state and return.
	;
ifdef	DEBUG_MOUSE
		WARNING_NZ MOUSE_BUTTONS_RECEIVED ;always true from above
endif
		mov	ds:[inputBuf], al

ifdef   DEBUG_MOUSE
	;
	; For debug versions, warn when the mouse overflows positions
	;
		test	al,mask PSMPB_Y_OVER	;Y position overflow?
		WARNING_NZ MOUSE_Y_DELTA_OVERFLOW
		test	al,mask PSMPB_X_OVER	;X position overflow?
		WARNING_NZ MOUSE_X_DELTA_OVERFLOW
endif

		mov	bx,offset MouseReceiveXDelta	; advance to next state
		ret
MouseReceiveButtons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReceiveXDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Service routine for the X delta State
CALLED BY:
	MouseDevHandler 

PASS:
	al	- byte from mouse
	ah	- status byte for this transmission
	bx	- address of the service routine called for this state
	ds	- Segment of dgroup

RETURN:
	bx	- address of next routine to call.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReceiveXDelta	proc	near
ifdef	DEBUG_MOUSE
		WARNING_NZ MOUSE_X_DELTA_RECEIVED ;always true from above
endif
	;
	; We'e expecting X delta -- record it and return
	;
		mov	ds:[inputBuf+1], al
		mov	bx,offset MouseReceiveYDelta	; advance to next state
		ret
MouseReceiveXDelta	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReceiveYDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Service routine for the Y Delta State
CALLED BY:
	MouseDevHandler 

PASS:
	al	- byte from mouse
	ah	- status byte for this transmission
	bx	- address of the service routine called for this state
	ds	- Segment of dgroup

RETURN:
	bx	- address of next routine to call.

DESTROYED:
	cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReceiveYDelta	proc	near
ifdef	DEBUG_MOUSE
		WARNING_NZ MOUSE_Y_DELTA_RECEIVED ;always true from above
endif
	;
	; We're expecting Y delta -- record it and send off mouse event
	; Shift the things into their proper registers for MouseSendEvents
	;	buttons in BH
	;	deltaX in CX
	;	deltaY in DX
	;
		push	si, di, bp		; save for MouseSendEvents
		clr	ch, dh
		mov	bh, ds:[inputBuf]
		mov	cl, ds:[inputBuf+1]
		mov	dl, al			; the current buffer (last byte)
if 0
	;DONT HANDLE OVERFLOWS, SINCE THE MOUSE PASSES FFh ON AN OVERFLOW
	;	
	; Check for overflow flag and add 256 to cx, dx if
	; need be.
	;
		test	bh, mask PSMPB_Y_OVER
		jz	dxNoOver
		mov	dh, 1
dxNoOver:
		test	bh, mask PSMPB_X_OVER
		jz	cxNoOver
		mov	ch, 1
cxNoOver:

endif
	;
	; Sign-extend the deltas. Note that deltaY is opposite of our
	; coordinate conventions, so we'll take a jump opposite of what you
	; would expect based upon the status flag
	;
		test	bh, mask PSMPB_Y_SIGN
		jz	doneYDelta
		not	dh		;make sign extended
doneYDelta:
		neg	dx		;opposite coordinate system

		test	bh, mask PSMPB_X_SIGN
		jz	doneXDelta
		not	ch		;make sign extended
doneXDelta:

		mov	bl, 0ffh
		test	bh, mask PSMPB_RIGHT_BUTTON
		jz	afterRightButton
		mov	bl, not mask MOUSE_B2 
afterRightButton:
		test	bh, mask PSMPB_LEFT_BUTTON
		jz	afterLeftButton
		and	bl, not mask MOUSE_B0
afterLeftButton:
		mov	bh, bl
		clr	bp
		call	MouseSendEvents
ifdef	DEBUG_MOUSE
			;ADD TEST MARKER FOR MOUSE SEND EVENTS
		push	ax
       	 	mov     al, 055h
		call	StuffPBuff
       	 	mov     al, 0aah
		call	StuffPBuff
        	pop     ax
endif

		pop	si, di, bp
		
		mov	bx, offset MouseReceiveButtons
		ret
MouseReceiveYDelta	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReceiveACK_1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Service routines for the reset ack (0FAh 0AAh 00h) States
CALLED BY:
	MouseDevHandler 

PASS:
	al	- byte from mouse
	ah	- status byte for this transmission
	bx	- address of the service routine called for this state
	ds	- Segment of dgroup

RETURN:
	bx	- address of next routine to call.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReceiveACK_1	proc	near
			;We can get EITHER an FAh or an AAh in this state...
			;We always have to get an ACK_2 to leave this state.
			;al could be NIKE_MOUSE_COMMAND_ACK_1 or...
		cmp	al, NIKE_MOUSE_COMMAND_ACK_2
		jne	done		;if not, keep waiting for ACK_2
		mov	bx, offset MouseReceiveACK_3
done:
		ret
MouseReceiveACK_1	endp

MouseReceiveACK_3	proc	near
		cmp	al, NIKE_MOUSE_COMMAND_ACK_3
		jne	done		;if not, keep waiting for ACK
		mov	ah, NIKE_MOUSE_ENABLE_COMMAND
		call	MouseSendControlCode
		mov	bx, offset MouseReceiveSingleACK_1
done:
		ret
MouseReceiveACK_3	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReceiveSingleACK_1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Service routine for the single ack FAh State
CALLED BY:
	MouseDevHandler 

PASS:
	al	- byte from mouse
	ah	- status byte for this transmission
	bx	- address of the service routine called for this state
	ds	- Segment of dgroup

RETURN:
	bx	- address of next routine to call.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseReceiveSingleACK_1	proc	near
		cmp	al, NIKE_MOUSE_COMMAND_ACK_1
		jne	done		;if not, keep waiting for ACK
		mov	bx, offset MouseReceiveButtons
done:
		ret
MouseReceiveSingleACK_1	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSendControlCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Send a command byte to the mouse, and reset the state machine to look
	for a single ACK from the mouse.

CALLED BY:
	MouseDevInit,MouseDevHandler

PASS:
	ah	=	control code to be sent
	ds	=	dgroup

RETURN:
	nothing

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:
	Check the TxE. If empty, then load the first byte, if not, exit
	and let the calling routine re call later.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine pre-empts any currently transmitting control code
	if there is an unfinished transmission in progress

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseSendControlCode	proc	far
	uses	dx
	.enter

	push	ax

ifdef	DEBUG_MOUSE
	mov	al, 0ddh		;stuff in a marker byte
	call	StuffPBuff
endif

;--------------------------------------------------------------------------
if 0					;I TOOK OUT WAIT FOR TxE BIT PER
					;BROTHER TEST CODE.....DJD 05/10/95
waitForTxE:				;we should never wait in this loop.
	mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
	in	al, dx
	test	al, mask PSMS_TRANSMIT
	jz	waitForTxE
endif
;--------------------------------------------------------------------------

	mov	al, ah			;pick up the byte.

ifdef	DEBUG_MOUSE
	call	StuffPBuff
endif

	mov	dx, MOUSE_TRANSMIT_REG_IO_ADDRESS
	out	dx, al			;stuff it to the GA
					;re-enable stuff
	mov	al, MOUSE_RECEIVER_INTERRUPTS_ENABLED
	mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
	out	dx, al
	mov	ds:[inState], offset MouseReceiveSingleACK_1
	pop	ax
	cmp	ah, NIKE_MOUSE_RESEND_COMMAND	;re-send doesnt ACK
	jne	testForReset			
	mov	ds:[inState], offset MouseReceiveButtons
	jmp	exit
testForReset:
	cmp	ah, NIKE_MOUSE_RESET_COMMAND	;Reset needs Special ACK.
	jne	exit			
	mov	ds:[inState], offset MouseReceiveACK_1
exit:
	.leave
	ret
MouseSendControlCode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MousePing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Send the mouse an Enable byte to wake it up after some ressetting
	event . (unplugging, power glitch, etc.)

CALLED BY:
	Timer Interrupt

PASS:
	nothing

RETURN:
	nothing

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:
	check to see if the mouse is alive, if it has not moved in the last
	call period, check if the last report included a button press, if so,
	do nothing, else ping the mouse.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MousePing	proc	far
	uses	si, ds
	.enter
	segmov	ds, dgroup, si
	cmp	ds:[mouseEnabled],TRUE		;is mouse on?
	jne	reallyExit
ifdef	DEBUG_MOUSE
	WARNING_E MOUSE_PING_CALLED
endif
	cmp	ds:[timerRoutineLastCalled],TRUE	;was the DevHandler
						;called after the time this
						;routine was last called?
	jne	exit				;if so, just exit, still alive.

		;This next test makes sure we are on a packet boundary
		;in case the mouse has sent a spurious reset acknowledge byte
		;after being plugged in, or re-powered.
	cmp	ds:[inState],offset MouseReceiveButtons ;at packet start?
	jne	resetTheRodent			;if not, we are in a bad state

						;get last state of the buttons
	test	ds:[inputBuf],mask PSMPB_LEFT_BUTTON or mask PSMPB_RIGHT_BUTTON
						;buttons pressed?
	jnz	exit				;if so, no ping, user is
						;holding a button down
						;without moving.

resetTheRodent:
						;reset the enable bits in the
	mov	dx, MOUSE_STATUS_REG_IO_ADDRESS	;gate array. Brother says that
	clr	al				;this will reset the gate
	out	dx, al				;array mouse port.
	mov	al, MOUSE_RECEIVER_INTERRUPTS_ENABLED
	out	dx, al

						;now send the enable to the 
						;mouse itself.
	mov	ah,NIKE_MOUSE_RESET_COMMAND	;get reset code.
	call	MouseSendControlCode

exit:
	mov	ds:[timerRoutineLastCalled],TRUE
reallyExit:
	.leave
	ret
MousePing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffPBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Debug Code

PASS:
	al	- data to stuff in the rotating buffer
	ds	- Segment of dgroup

RETURN:
	nothing

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	DEBUG_MOUSE
StuffPBuff	proc	far
	        push    si
       	 	mov     si, ds:hackPtr
       	 	mov     ds:[pbuf][si], al
       	 	inc     si
		cmp     si, HACK_BUF_SIZE
	 	jnz     1$
	 	clr     si
1$:
        	mov     ds:hackPtr, si
        	pop     si
		ret
StuffPBuff	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseWaitForRxE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Wait for the Receive data full bit to go away

CALLED BY:
	Internal

PASS:
	nothing

RETURN:
	nothing

DESTROYED:
	dx,al

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	DEBUG_MOUSE
MouseWaitForRxE	proc	far
		mov	dx, MOUSE_STATUS_REG_IO_ADDRESS
loadIt:
		in	al, dx
		test	al, mask PSMS_RECEIVE
		jnz	loadIt
		ret
MouseWaitForRxE	endp
endif

Resident ends

		end
