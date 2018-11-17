COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Scriptel pen digitizer
FILE:		scripen.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device (actually MouseClosePort in
				mouseSerCommon.asm)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/14/92		Initial revision from pqpen.asm

CAUTION! there are various ugly tweaks in this to get the lousy digitizer
working for shows, presumably it should be cleaned up when a production
digitizer is available. DONT SAY YOU WEREN'T WARNED!


DESCRIPTION:
	Device-dependent support for Scriptel pen digitizer
		

	$Id: scripen.asm,v 1.1 97/04/18 11:48:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		=	1	; Current module

DEBUG_SCRIPTEL	=	0
;
MOUSE_NUM_BUTTONS	= 1

MouseDevExit	equ	<MouseClosePort>

MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MOUSE_SET_DEVICE_DOES_NOTHING=1	; Once we're sure there's a mouse there, there's
				;  nothing else to do.
MOUSE_USES_ABSOLUTE_DELTAS = 1

DIGITIZER_X_RES		equ	96
DIGITIZER_Y_RES		equ	60


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
HELLO		= 'P'			; Character sent to see if mouse is
					;  alive. Returns a status byte
;
; Available report rates
;
mouseRates	byte	1, 5, 10, 20, 40, 75, 100, 200
MOUSE_NUM_RATES	equ	length mouseRates
PAD_Y_SCALE_FACTOR	=	40375	;fraction to mult by in y.
;
; Commands to send to the mouse corresponding to the different rates.
;
mouseRateCmds	byte	'0', '1', '2', '3', '4', '5', '6', '7'
;
; DEFAULTS
;
DEF_PORT	= SERIAL_COM1		; Default port to try if none given
DEF_FORMAT	= SerialFormat <0,0,SP_NONE,1,SL_8BITS>

rateCommand	byte	"R1="
crlfCommand	byte	C_CR,C_LF

		;Initialization stuff for the digitizer interface.
initBlock	label	byte
	byte	"R2=0",C_CR,C_LF	;Emmulation = Scriptel Std.
	byte	"R0=4",C_CR,C_LF	;Mode =  stream absolute incremental
	byte	"R1=2",C_CR,C_LF	;Rate = 10 CPPS
	byte	"R3=0",C_CR,C_LF	;Units in English
	byte	"R4=1",C_CR,C_LF	;return coordinates in ascii format
	byte	"RA=0",C_CR,C_LF	;Stop transmitting coordinates off pad
	byte	"RB=94",C_CR,C_LF	;use the hand scaling mode 94 dpi.
	byte	"RC=1",C_CR,C_LF	;1 dot/increment.
endinitBlock	label	byte
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
IS_START 	enum InStates		; At start of packet -- byte
						; must be a LF char.
IS_X1		enum InStates
IS_X2		enum InStates
IS_X3		enum InStates
IS_X4		enum InStates
IS_X5		enum InStates
IS_FIRST_COMMA	enum InStates
IS_Y1		enum InStates
IS_Y2		enum InStates
IS_Y3		enum InStates
IS_Y4		enum InStates
IS_Y5		enum InStates
IS_LAST_COMMA	enum InStates
IS_PB		enum InStates
IS_ERR 		enum InStates, 0x80 	; Error received -- discard
					; next byte and reset
inState		InStates IS_START


if      DEBUG_SCRIPTEL
TEMP_BUF_SIZE   =       2000
tempPtr word    0
tempbuf    byte    TEMP_BUF_SIZE dup (0)
COORD_BUF_SIZE   =       0x400
coordPtr word    0
coordbuf    word    COORD_BUF_SIZE dup (0)
endif
		even
idata		ends

udata		segment

;
; Buffer sizes for serial connection
;
MOUSE_INBUF_SIZE= 16
MOUSE_OUTBUF_SIZE= 16

;
; Input buffer -- we use Scriptel ASCII format to make life hard, so we only
; need a 2-word input buffer. The reading of a packet is performed by
; a state machine in MouseDevHandler. An input packet is laid out as:
;
;
;
; XS and YS are 0 if the corresponding delta is positive, 1 if negative.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
LTButtonByte	record
	BUTTON_DOWN:1
LTButtonByte	end
;
	;
	; Input buffers -- accumulate bits in the x and y words.
	; 
LTButtons	record
	XNEGATIVE:1,
	YNEGATIVE:1,
	LEFT_DOWN:1,
	MIDDLE_DOWN:1,
	RIGHT_DOWN:1
LTButtons	end

coordX		word
coordY		word
buttons		LTButtons		;last transmitted button value.

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

mouseNameTable	lptr.char	scripTel
		lptr.char	0		; null-terminator

scripTel	chunk.char	'Scriptel Pen (Serial)', 0

mouseInfoTable	MouseExtendedInfo	\
		mask MEI_SERIAL		; Scriptel

MouseExtendedInfoSeg	ends
		

;------------------------------------------------------------------------------
;		       INITIALIZATION/EXIT CODE
;
; Module may be nuked if desired. Shouldn't be swapped, though (no point).
; Must be sharable so kernel's EC code doesn't barf...
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
		push	si
		mov	ax, STREAM_BLOCK
		mov	si,offset initBlock
		mov	cx, (offset endinitBlock - offset initBlock - 1)
		CallSer	DR_STREAM_WRITE
		pop	si

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

	;
	; Now have the device open. What we want to do here is cycle
	; through the possible baud rates, sending a HELLO character
	; to the mouse each time, hoping to get an ACK byte back.
	;
	; First set the stream to be unbufferred and call MouseDevAck
	; on each character...
	;
;		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
;		mov	cx, cs
;		mov	dx, offset MouseDevAck
;		mov	bp, ds
;		CallSer	DR_STREAM_SET_NOTIFY
;
;		mov	ax, STREAM_READ
;		CallSer	DR_STREAM_FLUSH

		mov	ax,SB_9600
		mov	ds:[mouseBaud], ax

		mov	ax, DP_PRESENT
		clc
		;assume that the baud rate is 
		;correct.

		clc		; Signal no error
done:
		.leave
		ret
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
	This routine grew out of control when ASCII packets were used. The
reason that ASCII format is used, is that for some unknown reason, the binary
format gives VERY jittery non-debounced values.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
	uses	bx,ds
	.enter
	mov	ds, cx

	mov	ah, ds:inState
	cmp	ah, IS_START
	jne	checkForX1
		;
		; Make sure byte is LF
		;
	cmp	al, C_LF
	jne	exitForNextByte
		;
		; Record first x value, change states and return.
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	ds:inState, IS_X1
	clr	ax		;init the coord locations in dgroup
	mov	ds:coordX,ax
	mov	ds:coordY,ax
	jmp	exitForNextByte
checkForX1:
	cmp 	ah, IS_X1
	jne	checkForX2
		;
		; Expecting X1 ASCII digit coord -- record it and return
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	bx,10000	;factor for the high ascii digit.
	mov	ds:inState, IS_X2
	jmp	recordXAndReturn
checkForX2:
	cmp 	ah, IS_X2
	jne	checkForX3
		;
		; Expecting X2 ASCII digit coord -- record it and return
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	bx,1000		;factor for the ascii digit.
	mov	ds:inState, IS_X3
	jmp	recordXAndReturn
checkForX3:
	cmp 	ah, IS_X3
	jne	checkForX4
		;
		; Expecting X3 ASCII digit coord -- record it and return
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	bx,100		;factor for the ascii digit.
	mov	ds:inState, IS_X4
	jmp	recordXAndReturn
checkForX4:
	cmp 	ah, IS_X4
	jne	checkForX5
		;
		; Expecting X4 ASCII digit coord -- record it and return
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	bx,10		;factor for the ascii digit.
	mov	ds:inState, IS_X5
	jmp	recordXAndReturn
checkForX5:
	cmp 	ah, IS_X5
	jne	checkForFirstComma
		;
		; Expecting X5 ASCII digit coord -- record it and return
		;
if      DEBUG_SCRIPTEL
	call	SavePortData
endif
	mov	bx,1		;factor for the ascii digit.
	mov	ds:inState, IS_FIRST_COMMA

recordXAndReturn:
	sub	al,'0'		;do ASCII to binary conversion.
	cmp	al,10
	jnc	setErrorOut	;if not an ASCII digit, error, and set to
				;start.
	clr	ah		;get set to multiply by factor passed in bx
	mul	bx		;get the factor to adjust by.
	add	ds:coordX,ax	;add in to the total x position.
	jmp	exitForNextByte

checkForFirstComma:
	cmp	ah, IS_FIRST_COMMA
	jne	checkForY1
                ;
                ; Expecting comma ASCII digit coord -- check it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
	cmp	al,','		;see if valid comma char.
	jne	setErrorOut	;if not a comma, then packet is bad, exit.
	mov	ds:inState, IS_Y1 ;set next state.
	jmp	exitForNextByte

checkForY1:
        cmp     ah, IS_Y1
        jne     checkForY2
                ;
                ; Expecting Y1 ASCII digit coord -- record it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        mov     bx,10000        ;factor for the high ascii digit.
        mov     ds:inState, IS_Y2
        jmp     recordYAndReturn
checkForY2:
        cmp     ah, IS_Y2
        jne     checkForY3
                ;
                ; Expecting Y2 ASCII digit coord -- record it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        mov     bx,1000         ;factor for the ascii digit.
        mov     ds:inState, IS_Y3
        jmp     recordYAndReturn
checkForY3:
        cmp     ah, IS_Y3
        jne     checkForY4
                ;
                ; Expecting Y3 ASCII digit coord -- record it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        mov     bx,100          ;factor for the ascii digit.
        mov     ds:inState, IS_Y4
        jmp     recordYAndReturn
checkForY4:
        cmp     ah, IS_Y4
        jne     checkForY5
                ;
                ; Expecting Y4 ASCII digit coord -- record it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        mov     bx,10           ;factor for the ascii digit.
        mov     ds:inState, IS_Y5
        jmp     recordYAndReturn
checkForY5:
        cmp     ah, IS_Y5
        jne     checkForLastComma
                ;
                ; Expecting Y5 ASCII digit coord -- record it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        mov     bx,1            ;factor for the ascii digit.
        mov     ds:inState, IS_LAST_COMMA

recordYAndReturn:
        sub     al,'0'          ;do ASCII to binary conversion.
        cmp     al,10
        jnc     setErrorOut     ;if not an ASCII digit, error, and set to
                                ;start.
        clr     ah              ;get set to multiply by factor passed in bx
        mul     bx              ;get the factor to adjust by.
        add     ds:coordY,ax    ;add in to the total x position.
        jmp     exitForNextByte

checkForLastComma:
        cmp     ah, IS_LAST_COMMA
        jne     checkForPB
                ;
                ; Expecting comma ASCII digit coord -- check it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        cmp     al,','          ;see if valid comma char.
        jne     setErrorOut     ;if not a comma, then packet is bad, exit.
        mov     ds:inState, IS_PB ;set next state.
        jmp     exitForNextByte

checkForPB:
	cmp	ah,IS_PB
        jne     setErrorOut     ;if not , then packet is bad, exit.
                ;
                ; Expecting button ASCII digit -- save it and return
                ;
if      DEBUG_SCRIPTEL
        call    SavePortData
endif
        sub     al,'0'          ;do ASCII to binary conversion.
        cmp     al,2
        jnc     setErrorOut     ;if not an ASCII 1, or 0, error, and set to
                                ;start.
	mov	bh,not mask LEFT_DOWN	;assume a press happened.
	test	al,1		;see if the button is pressed.
	jnz	buttonCorrect
	test	ds:buttons,mask LEFT_DOWN	;if last button state was not
	jnz	setErrorOut		;pressed, just exit , no event.
	or	bh,mask LEFT_DOWN
buttonCorrect:
	mov	ds:buttons,bh	;asve the last button state.
		;scale the Y position, the x is done already in hwdwr.
	push	bx		;save away the used regs.
	mov	dx,ds:coordY	;integer position.
	clr	cx
	mov	bx,cx
	mov	ax,PAD_Y_SCALE_FACTOR
	call	GrMulWWFixed	;scale the y position.
	pop	bx
	mov	cx,ds:coordX	;load the positions for send event.



if      DEBUG_SCRIPTEL
	call	SaveCoordData
endif
	push	si, di
		


	call	MouseSendEvents


	pop	si, di
		;
		; Go back to waiting for the start byte (Fall Through)
		;
setErrorOut:
		;
		; Error -- discard byte but reset state machine
		;
	mov	ds:inState, IS_START
exitForNextByte:
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

		mov	bx, ds:mouseUnit
		;
		; Fetch character to change the report rate.
		;	(its in cx)
		add	cl,'0'		;convert to ascii to get command
		push	cx

		mov	cx,3		;length of command
		mov	si,offset rateCommand
		mov	ax, STREAM_BLOCK
		CallSer	DR_STREAM_WRITE
		;
		; Ship it off to the mouse.
		;
		mov	ax, STREAM_BLOCK
		pop	cx		;command argument
		CallSer	DR_STREAM_WRITE_BYTE

		mov	cx,2		;length of command
		mov	si,offset crlfCommand
		mov	ax, STREAM_BLOCK
		CallSer	DR_STREAM_WRITE

		pop	si, bx
		clc			; No error.
		ret
MouseDevSetRate	endp
if      DEBUG_SCRIPTEL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Diagnostic routines for debugging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
PASS:	

RETURN:		
DESTROYED:

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SavePortData	proc	near
	uses	bx
	.enter
	mov	bx,ds:tempPtr		;get the ptr to the buffer
	mov	ds:[tempbuf].[bx],al
	inc	bx
	cmp	bx,TEMP_BUF_SIZE	;roll the counter over at end.
	jne	exit
	clr	bx
exit:
	mov	ds:tempPtr,bx
	.leave
	ret
SavePortData	endp
SaveCoordData	proc	near
	uses	ax,bx
	.enter
	xchg	bh,bl
	mov	ax,bx			;save the buttons
	mov	ah,0xff			;mark this packet.
	mov	bx,ds:coordPtr		;get the ptr to the buffer
	mov	ds:[coordbuf].[bx],ax
	add	bx,2
	and	bx,0x3ff
	mov	ds:[coordbuf].[bx],cx
	add	bx,2
	and	bx,0x3ff
	mov	ds:[coordbuf].[bx],dx
	add	bx,2
	and	bx,0x3ff
	mov	ds:coordPtr,bx
	.leave
	ret
SaveCoordData	endp

endif

Resident ends

		end
