COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- LogiTech serial (C7) mouse
FILE:		logiser.asm

AUTHOR:		Adam de Boor, Mar 24, 1989

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device (actually MouseClosePort in
				mouseSerCommon.asm)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/24/89		Initial revision


DESCRIPTION:
	Device-dependent support for Logitech serial mouse.
		

	$Id: logiser.asm,v 1.1 97/04/18 11:48:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		=	1	; Current module

;
MOUSE_NUM_BUTTONS	= 3	; This is the max for now...

MouseDevExit	equ	<MouseClosePort>

MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MOUSE_SET_DEVICE_DOES_NOTHING=1	; Once we're sure there's a mouse there, there's
				;  nothing else to do.

include		mouseCommon.asm	; Include common definitions/code.

MOUSE_TEST_DEVICE_NOT_CALLED				enum	FatalErrors

UseDriver Internal/serialDr.def

;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment
;
; Baud rates to try when initializing the mouse, in order of preference.
;
mouseBauds	SerialBaud	SB_9600, SB_4800, SB_2400, SB_1200

NUM_BAUDS	= length mouseBauds	; Number of bauds to try.
ACK_DELAY	= 10			; Ticks to wait for an ACK
HELLO		= 's'			; Character sent to see if mouse is
					;  alive. Returns a status byte
;
; Available report rates
;
mouseRates	byte	10, 20, 35, 50, 70, 100, 150, 255
MOUSE_NUM_RATES	equ	length mouseRates
;
; Commands to send to the mouse corresponding to the different rates.
;
mouseRateCmds	byte	'J', 'K', 'L', 'R', 'M', 'Q', 'N', 'O'
;
; DEFAULTS
;
DEF_PORT	= SERIAL_COM1		; Default port to try if none given
DEF_FORMAT	= SerialFormat <0,0,SP_ODD,1,SL_8BITS>
DEF_REPORT	= 'M'			; Report-rate command (70/s)
DEF_REPFORM	= 'S'			; MM Series format

;
; Other formats to try if two framing errors or parity errors are received.
;
otherFormats	SerialFormat <0,0,SP_ODD,1,SL_8BITS>,
			     <0,0,SP_EVEN,1,SL_8BITS>,
			     <0,0,SP_NONE,1,SL_8BITS>,
			     <0,0,SP_ODD,0,SL_8BITS>,
			     <0,0,SP_EVEN,0,SL_8BITS>,
			     <0,0,SP_NONE,0,SL_8BITS>
nextFormat	nptr.SerialFormat	otherFormats
ERRORS_BEFORE_CHANGE	= 5
errCount	byte	ERRORS_BEFORE_CHANGE
	;
	; State machine definitions
	; 
InStates 	etype byte
IS_START 	enum InStates, 1	; At start of packet -- byte
						; must have have high bit on
IS_X 		enum InStates, 2	; Expecting delta X
IS_Y 		enum InStates, 4	; Expecting delta Y
IS_ERR 		enum InStates, 8 	; Error received -- discard
					; next byte and reset
inState		InStates IS_START

		even
idata		ends

udata		segment

;
; Buffer sizes for serial connection
;
MOUSE_INBUF_SIZE= 16
MOUSE_OUTBUF_SIZE= 16

;
; Input buffer -- we use MM Series 3-byte format to make life easy, so we only
; need a 3-byte input buffer. The reading of a packet is performed by
; a state machine in MouseDevHandler. An input packet is laid out as:
;
; Byte	B7 B6 B5 B4 B3 B2 B1 B0
; 0      1  0  0 SX SY  L  M  R
; 1      0 X6 X5 X4 X3 X2 X1 X0
; 2	 0 Y6 Y5 Y4 Y3 Y2 Y1 Y0
;
; SX and SY are 1 if the corresponding delta is positive, 0 if negative.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
	;
	; Input buffers -- only two of the three bytes need saving. Ordered
	; for ease of calling MouseSendEvents, since it wants deltaX in BL.
	; 
LTButtons	record
	XPOSITIVE:1,
	YPOSITIVE:1,
	LEFT_DOWN:1,
	MIDDLE_DOWN:1,
	RIGHT_DOWN:1
LTButtons	end

deltaX		byte
buttons		LTButtons <>

mouseBaud	SerialBaud		; Baud rate decided on by
					;  MouseRealTestDevice

;
; Timed semaphore to use when looking for the mouse. Starts out taken
; so when MousePortInit does the PTimedSem, it blocks. If MouseDevAck
; receives an acknowledgement, it does a V on the semaphore to wake the thing
; up.
;
mouseAckSem	Semaphore <0,>		; Block on P

udata		ends


;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		length mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	logiC7,
				logiC9,
				logiTM,
				logiHirez,
				beetle
		lptr.char	0		; null-terminator

logiC7		chunk.char	'Logitech C-7, 3-button Serial', 0
logiC9		chunk.char	'Logitech Series 9, 3-button Serial', 0
logiTM		chunk.char	'Logitech Serial Trackball', 0
logiHirez	chunk.char	'Logitech Hi-Rez Serial', 0
beetle		chunk.char	'NewIdea Beetle Mouse (Serial)', 0

mouseInfoTable	MouseExtendedInfo	\
		mask MEI_SERIAL,	; C-7
		mask MEI_SERIAL,	; Series 9
		mask MEI_SERIAL,	; TrackMan
		mask MEI_SERIAL,	; Hi-Rez
		mask MEI_SERIAL		; beetle

MouseExtendedInfoSeg	ends
		

;------------------------------------------------------------------------------
;		       INITIALIZATION/EXIT CODE
;
; Module may be nuked if desired. Shouldn't be swapped, though (no point).
; Must be sharable so kernel's EC code doesn't complain...
;------------------------------------------------------------------------------

;
; Include common definitions for serial mice
;
include	mouseSerCommon.asm

Init segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the com port for the mouse

CALLED BY:	MouseInit
PASS:		DS=ES=dgroup
RETURN:		Carry clear if ok
DESTROYED:	DI

PSEUDO CODE/STRATEGY:
	Else, set to report in desired mode at desired rate, altering
		serial data format to match that for the desired format
		if different from the format we assume the mouse is
		using (got that?)
	Point the serial driver's routines to go to the resident ones.
	Return with carry clear.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should use error returns to determine what format the mouse is
	using. Unfortunately, I don't know if the mouse will ACCEPT any format,
	or if it requires its input to be in the same format as its output.
	We'll see.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevInit	proc	far	uses ax, bx, cx, dx, si, bp
		.enter
if 0
	;
	; Handle port-specification here
	; BX CONTAINS UNIT NUMBER THROUGH ALL FUTURE CALLS
	;
		call	MouseOpenPort		
		jc	done
else
		mov	bx, ds:[mouseUnit]
EC <		tst	bx					>
EC <		ERROR_S	MOUSE_TEST_DEVICE_NOT_CALLED		>
endif

	;
	; Switch to operational data format baud rate determined by
	; MouseTestDevice.
	;
		mov	cx, ds:[mouseBaud]
		mov	ax, (SM_RAW SHL 8) OR DEF_FORMAT
		CallSer	DR_SERIAL_SET_FORMAT

	;
	; Now we know where the mouse is and at what baud rate it's
	; operating, tell it to report at the proper rate in the
	; format we want.
	;
		mov	ax, STREAM_BLOCK
		mov	cl, DEF_REPFORM
		CallSer	DR_STREAM_WRITE_BYTE

		mov	ax, STREAM_BLOCK
		mov	cl, DEF_REPORT
		CallSer	DR_STREAM_WRITE_BYTE
		
		INT_OFF		; Nothing until we're initialized
	;
	; Change the input and error routines to the operational
	; ones.
	;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, segment MouseDevHandler
		mov	dx, offset MouseDevHandler
		mov	bp, ds
		CallSer	DR_STREAM_SET_NOTIFY
		
		mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_ROUTINE>
		mov	cx, segment MouseDevError
		mov	dx, offset MouseDevError
		mov	bp, ds
		CallSer	DR_STREAM_SET_NOTIFY
		INT_ON
	;
	; All's well that ends well...
	;
		clc
done:
		.leave
		ret
MouseDevInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle receipt of a character during MouseRealTestDevice

CALLED BY:	Serial driver
PASS:		al	= byte read
		cx	= word stored with notifier (dgroup)
		dx	= stream token
		bp	= STREAM_READ
RETURN:		Carry set to show character read
DESTROYED:	DH, AX, BX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevAck	proc	far
		;
		; See if byte is a valid status byte
		;
		and 	al, 0bfh	; Clear out mode bit
		cmp	al, 00fh	; Is it a valid status byte?
		jne	MDARet		; Nope -- ignore
		;
		; Wake the waiter up.
		;
		push	ds
		mov	ds,cx
		VSem	ds, mouseAckSem, TRASH_AX_BX
		pop	ds
MDARet:
		stc		; Character munched
		ret
MouseDevAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseRealTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Real routine to see if the device is present.

CALLED BY:	MouseTestDevice
PASS:		dx:si	= null-terminated device name for which to test.
			  we support only one type of device, so we ignore
			  this.
RETURN:		ax	= DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Figure out which port to use.
       	Open it.
       	For each possible baud rate:
       		- set the port to the baud rate using the format we assume the
		  mouse will be using
		- request the mouse's status
		- wait ACK_DELAY clock ticks for a valid status byte to come in
		- if status arrived, break out
	If found no mouse, return DP_NOT_PRESENT
	Else return DP_PRESENT
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseRealTestDevice	proc	far	uses bx, cx, si
		.enter
	;
	; Open the proper port.
	;
		segmov	ds, dgroup, bx
		call	MouseOpenPort
	;
	; Not sure what modes to assume here. For now, we assume
	; the thing is in the MM Series mode (8 data bits, 2 stop
	; bits, odd parity). We could employ some sort of heuristic
	; to notice the type of error we get back, but it's unclear
	; whether the mouse will ever send anything if any byte
	; we send it is garbled.
	; 
INIT_FORMAT= SerialFormat <0,0,SP_ODD,1,SL_8BITS>

	;
	; Now have the device open. What we want to do here is cycle
	; through the possible baud rates, sending a HELLO character
	; to the mouse each time, hoping to get an ACK byte back.
	;
	; First set the stream to be unbufferred and call MouseDevAck
	; on each character...
	;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, cs
		mov	dx, offset MouseDevAck
		mov	bp, ds
		CallSer	DR_STREAM_SET_NOTIFY

		mov	ax, STREAM_READ
		CallSer	DR_STREAM_FLUSH

		mov	si, offset mouseBauds
		cld
baudLoop:
	;
	; Use next baud rate.
	;
		lodsw			; Baud rate in AX
		mov	cx, ax		; xfer to CX...
	;
	; Slap it into raw mode with the default format...
	;
		mov	ax, (SM_RAW SHL 8) OR INIT_FORMAT
		CallSer	DR_SERIAL_SET_FORMAT

	;
	; Make sure we block...
	;
		mov	ds:mouseAckSem.Sem_value, 0
		
	;
	; Send the HELLO character to the mouse at this baud rate
	;
		mov	ax, STREAM_BLOCK
		mov	cl, HELLO
		CallSer	DR_STREAM_WRITE_BYTE
		
	;
	; Block on the ack semaphore. Save BX around the P (no need to save AX
	; and CX)
	;
		push	bx
		PTimedSem ds, mouseAckSem, ACK_DELAY, TRASH_AX_BX_CX
		pop	bx
	;
	; If carry, timed out (not acked) -- try the next baud rate.
	;
		jnc	found
		cmp	si, offset mouseBauds+size mouseBauds
		jb	baudLoop
	;
	; Close the port since we're not going to use it...
	;
		call	MouseClosePort
		mov	ax, DP_NOT_PRESENT
		clc		; Signal no error
done:
		.leave
		ret
found:
	;
	; Record mouse's baud rate so MouseDevInit can find it.
	;
		mov	ax, ds:[si-2]
		mov	ds:[mouseBaud], ax
		mov	ax, DP_PRESENT
		jmp	done		; carry already clear
MouseRealTestDevice	endp

Init ends

;------------------------------------------------------------------------------
;		  RESIDENT DEVICE-DEPENDENT ROUTINES
;------------------------------------------------------------------------------

Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the device. Loader must have called
		DRE_TEST_DEVICE before this routine is called.

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just call the device-initialization routine

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
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the device specified is present.

CALLED BY:	DRE_TEST_DEVICE	
PASS:		dx:si	= null-terminated name of device
RETURN:		ax	= DevicePresent enum
		carry set if string invalid, clear otherwise
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice	proc	near
		.enter
		call	MouseRealTestDevice
		.leave
		ret
MouseTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an error on our serial line

CALLED BY:	Serial driver
PASS:		AX	= dgroup
		CX	= error flags
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata		segment
mouseErrors	word	0
idata		ends
MouseDevError	proc	far
		;
		; Switch into an error state and record yet another packet
		; lost.
		;
		push	ds
		mov	ds, ax
		mov	ds:inState, IS_ERR
		inc	ds:mouseErrors
	;
	; If error was in framing or parity, try the next format
	;
		test	cx, mask SE_FRAME or mask SE_PARITY
		jz	10$
		dec	ds:errCount
		jnz	10$
		push	cx, bx, ax, di
		;
		; Fetch the address of the next format to try. If last time was
		; really the last time, die horribly.
		;
		mov	bx, ds:nextFormat
		cmp	bx, offset otherFormats + length otherFormats
		je	bigTimeChoke
		;
		; Set to raw mode with the given data format.
		;
		mov	ah, SM_RAW
		mov	al, ds:[bx]
		;
		; Advance to next for next time...
		;
		inc	bx
		mov	ds:nextFormat, bx
		
		mov	cx, ds:[mouseBaud]
		mov	bx, ds:mouseUnit
		CallSer	DR_SERIAL_SET_FORMAT
ohWell:
		pop	cx, bx, ax, di
		;
		; Reset error counter.
		;
		mov	ds:errCount, ERRORS_BEFORE_CHANGE
10$:
		pop	ds
		ret
bigTimeChoke:
	;
	; Can't really exit at interrupt time, so we just go back and
	; cycle for ever and ever...
	;
		mov	ds:nextFormat, offset otherFormats
		jmp	ohWell
MouseDevError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the receipt of a byte in the packet.

CALLED BY:	Serial driver
PASS:		AL	= character read
		CX	= dgroup
		DX	= stream token (ignored)
		BP	= STREAM_READ (ignored)
RETURN:		Carry set (character consumed)
DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far	uses ds
		.enter
		mov	ds, cx

		mov	ah, ds:inState
		test	ah, IS_START
		jz	MDH2
		;
		; Make sure byte has high bit set
		;
		test	al, 80h
		jz	MDHRet
		;
		; Record button state, change states and return.
		;
		mov	ds:buttons, al
		mov	ds:inState, IS_X
		jmp	short MDHRet
MDH2:
		test 	ah, IS_X
		jz	MDH3
		;
		; Expecting X delta -- record it and return
		;
		mov	ds:deltaX, al
		mov	ds:inState, IS_Y
		jmp	short MDHRet
MDH3:
		test	ah, IS_Y
		jz	MDH6
		;
		; Expecting Y delta -- packet complete.
		;
		push	si, di	; Save for MouseSendEvents
		
		;
		; Fetch deltaX and button state at once
		;
		mov	bx, word ptr ds:deltaX

		;
		; Set proper sign on deltaX and deltaY
		;
		test	bh, MASK XPOSITIVE
		jnz	MDH4
		neg	bl	; X negative -- negate it
MDH4:
		;
		; This one's a little weirder -- the mouse sends us deltaY
		; positive to the north, but MouseSendEvents wants it
		; positive to the south, so we negate it if the mouse says
		; deltaY is positive...
		;
		test	bh, MASK YPOSITIVE
		jz	MDH5
		neg	al
MDH5:
		and	bh,111b	; Make sure b3-7 are 1 when we call
		not	bh	; MouseSendEvents expects 0 => down..
		
		;
		; Now sign-extend the deltas in CX and DX (currently in
		; BL and AL, respectively).
		;
		cbw
		xchg	dx, ax		; deltaY (1-byte inst)
		mov	al, bl		; deltaX
		cbw
		xchg	cx, ax
		
		call	MouseSendEvents

		pop	si, di
		;
		; Go back to waiting for the start byte (Fall Through)
		;
MDH6:
		;
		; Error -- discard byte but reset state machine
		;
		mov	ds:inState, IS_START
MDHRet:
		stc			; Byte munched
		.leave
		ret
MouseDevHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevSetRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the report rate for the mouse.

CALLED BY:	MouseSetRate
PASS:		CX	= index into mouseRates of desired rate
		DS	= dgroup
RETURN:		Carry clear
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevSetRate	proc	near
		push	si, bx
		;
		; Fetch character to change the report rate.
		;
		mov	si, cx
		mov	cl, ds:mouseRateCmds[si]
		mov	bx, ds:mouseUnit
		;
		; Ship it off to the mouse.
		;
		mov	ax, STREAM_BLOCK
		CallSer	DR_STREAM_WRITE_BYTE

		pop	si, bx
		clc			; No error.
		ret
MouseDevSetRate	endp

Resident ends

		end
