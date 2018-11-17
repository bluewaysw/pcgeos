COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Microsoft serial mouse
FILE:		msser.asm

AUTHOR:		Adam de Boor, April 11, 1989

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device (actually MouseClosePort in
				mouseSerCommon.asm)
	MouseDevHandler		Handler for serial interrupt
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/24/89		Initial revision


DESCRIPTION:
	Device-dependent support for Microsoft serial mouse.
		
	DO NOT DEFINE CHECK_FOR_MOUSE UNLESS A MouseTestDevice ROUTINE IS
	DEFINED.

	$Id: msser.asm,v 1.1 97/04/18 11:48:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		= 1

;
MOUSE_NUM_BUTTONS	= 2	; All microsoft mice have two buttons.
MOUSE_CANT_SET_RATE	=1	; I don't know how to change the report rate.
MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MOUSE_CANT_TEST_DEVICE	= 1	; No reliable way to test for this device.
MouseDevExit	equ	<MouseClosePort>

include		mouseCommon.asm	; Include common definitions/code.
include		timer.def

UseDriver	Internal/serialDr.def


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

if PZ_PCGEOS
mouseNameTable	lptr.char	micCom
		lptr.char	0	; null-terminator

LocalDefString micCom <'Microsoft-compatible Serial', 0>

mouseInfoTable	MouseExtendedInfo	\
		mask	MEI_SERIAL	;micCom,\

else
mouseNameTable	lptr.char	msSer,
				kraft,
				genius,
				acer,
				tandy,
				dexxa,
				micCom,
				other2B,
				logi2B,
				msys2B,
				msysTB,
				kensingtonTB,
				laserSerial,
				artecAM21,
				rollerMouse,
				wittyMouse,
				fancyMouse,
				wittyBall,
				dell,
				dms200,
				dms200H,
				focusFT100,
				trackballPlus,
				imcsMousePen,
				imsiMech,
				itacMouseTrak,
				marconi,
				marconi306,
				microspeedTrac,
				microspeedFTrap,
				omnimouse,
				theWhiteMouse,
				pcTrackball,
				mouseMan,
				logiTrackManSer,
				logiFirstMouseSer,
				philipsSer
		lptr.char	0	; null-terminator

LocalDefString msSer <'Microsoft Serial', 0>
LocalDefString kraft <'Kraft Serial Mouse (Microsoft Mode)', 0>
LocalDefString genius <'Genius Serial (Microsoft Mode)', 0>
LocalDefString acer <'Acer Serial', 0>
LocalDefString tandy <'Tandy Serial', 0>
LocalDefString dexxa <'Dexxa Serial', 0>
LocalDefString micCom <'Microsoft-compatible Serial', 0>
LocalDefString other2B <'Other 2-button Serial', 0>
LocalDefString logi2B <'Logitech 2-button Serial', 0>
LocalDefString msys2B <'Mouse Systems 2-button Serial', 0>
LocalDefString msysTB <'Mouse Systems Serial Trackball', 0>
LocalDefString kensingtonTB <'Kensington Serial Trackball', 0>
LocalDefString laserSerial <'Laser 3-button (Microsoft Mode)', 0>
LocalDefString artecAM21 <'Artec AM-21 Plus (Microsoft Mode)', 0>
LocalDefString rollerMouse <'CH Products RollerMouse', 0>
LocalDefString wittyMouse <'Commax Witty Mouse (Microsoft Mode)', 0>
LocalDefString fancyMouse <'Commax Fancy Mouse (Microsoft Mode)', 0>
LocalDefString wittyBall <'Commax Witty Ball (Microsoft Mode)', 0>
LocalDefString dell <'Dell Serial Mouse', 0>
LocalDefString dms200 <'DMS-200 Mouse (Microsoft Mode)', 0>
LocalDefString dms200H <'DMS-200H Mouse (Microsoft Mode)', 0>
LocalDefString focusFT100 <'Focus FT-100 Tracker (Microsoft Mode)', 0>
LocalDefString trackballPlus <'Fulcrum Trackball Plus (Microsoft Mode)', 0>
LocalDefString imcsMousePen <'IMCS The MousePen (Serial)', 0>
LocalDefString imsiMech <'IMSI Mechanical Mouse (Microsoft Mode)', 0>
LocalDefString itacMouseTrak <'ITAC Mouse-trak Serial (Microsoft Mode)', 0>
LocalDefString marconi <'Marconi Marcus RB2-305', 0>
LocalDefString marconi306 <'Marconi Marcus RB2-306', 0>
LocalDefString microspeedTrac <'MicroSpeed PC-Trac Serial (Microsoft Mode)', 0>
LocalDefString microspeedFTrap <'MicroSpeed FastTRAP Serial (Microsoft Mode)',0>
LocalDefString omnimouse <'Mouse Systems OmniMouse II Serial', 0>
LocalDefString theWhiteMouse <'The White Mouse Serial (Microsoft Mode)', 0>
LocalDefString pcTrackball <'Mouse Systems PC Trackball Serial',0>
LocalDefString mouseMan <'Logitech MouseMan (Serial)',0>
LocalDefString logiTrackManSer <'Logitech TrackMan Portable (Serial)',0>
LocalDefString logiFirstMouseSer <'Logitech First Mouse (Serial)',0>
LocalDefString philipsSer <'Philips Serial', 0>

mouseInfoTable	MouseExtendedInfo	\
		mask	MEI_SERIAL,	;msSer,\
		mask	MEI_SERIAL,	;kraft,\
		mask	MEI_SERIAL,	;genius,\
		mask	MEI_SERIAL,	;acer,\
		mask	MEI_SERIAL,	;tandy,\
		mask	MEI_SERIAL,	;dexxa,\
		mask	MEI_SERIAL,	;micCom,\
		mask	MEI_SERIAL,	;other2B,\
		mask	MEI_SERIAL,	;logi2B,\
		mask	MEI_SERIAL,	;msys2B,\
		mask	MEI_SERIAL,	;msysTB,\
		mask	MEI_SERIAL,	;kensingtonTB,\
		mask	MEI_SERIAL,	;laserSerial,\
		mask	MEI_SERIAL,	;artecAM21,\
		mask	MEI_SERIAL,	;rollerMouse,\
		mask	MEI_SERIAL,	;wittyMouse,\
		mask	MEI_SERIAL,	;fancyMouse,\
		mask	MEI_SERIAL,	;wittyBall,\
		mask	MEI_SERIAL,	;dell,\
		mask	MEI_SERIAL,	;dms200,\
		mask	MEI_SERIAL,	;dms200H,\
		mask	MEI_SERIAL,	;focusFT100,\
		mask	MEI_SERIAL,	;trackballPlus,\
		mask	MEI_SERIAL,	;imcsMousePen,\
		mask	MEI_SERIAL,	;imsiMech,\
		mask	MEI_SERIAL,	;itacMouseTrak,\
		mask	MEI_SERIAL,	;marconi,\
		mask	MEI_SERIAL,	;marconi306,\
		mask	MEI_SERIAL,	;microspeedTrac,\
		mask	MEI_SERIAL,	;microspeedFTrap,\
		mask	MEI_SERIAL,	;omnimouse,\
		mask	MEI_SERIAL,	;theWhiteMouse,\
		mask	MEI_SERIAL,	;pcTrackball,\
		mask	MEI_SERIAL,	;mouseMan,\
		mask	MEI_SERIAL,	;logiTrackManSer,\
		mask	MEI_SERIAL,	;logiFirstMouseSer, \
		mask	MEI_SERIAL	;philipsSer
endif

CheckHack	<length mouseInfoTable eq length mouseNameTable>

MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment

;
; DEFAULTS
;
DEF_PORT	= SERIAL_COM1		; Default port to try if none given
DEF_FORMAT	= SerialFormat <0,0,SP_NONE,0,SL_7BITS>
DEF_MODEM	= mask SMC_RTS or mask SMC_DTR

ACK_DELAY	= 10			; Ticks to wait for an ACK

;
; Other formats to try if two framing errors or parity errors are received.
;
otherFormats	SerialFormat <0,0,SP_NONE,0,SL_8BITS>,
			     <0,0,SP_ODD,0,SL_7BITS>,
			     <0,0,SP_EVEN,0,SL_7BITS>,
			     <0,0,SP_NONE,1,SL_7BITS>,
			     <0,0,SP_NONE,1,SL_8BITS>,
			     <0,0,SP_ODD,1,SL_7BITS>,
			     <0,0,SP_EVEN,1,SL_7BITS>
nextFormat	nptr.SerialFormat	otherFormats
ERRORS_BEFORE_CHANGE	= 15
errCount	byte	ERRORS_BEFORE_CHANGE

;
; Buffer sizes for serial connection
;
MOUSE_INBUF_SIZE= 16
MOUSE_OUTBUF_SIZE= 16

;
; Input buffer -- Microsoft input packets are structured strangely. They
; are three bytes long:
;
; Byte	B6 B5 B4 B3 B2 B1 B0
; 0      1  L  R Y7 Y6 X7 X6
; 1      0 X5 X4 X3 X2 X1 X0
; 2	 0 Y5 Y4 Y3 Y2 Y1 Y0
;
; The reading of a packet is performed by a state machine in MouseDevHandler.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
inputBuf	byte	2 dup(?)

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

mouseRates	label	byte	; To avoid assembly errors
MOUSE_NUM_RATES	equ	0

ifdef CHECK_FOR_MOUSE
;
; Timed semaphore to use when looking for the mouse. Starts out taken
; so when MouseDevInit does the PTimedSem, it blocks. If MouseDevAck
; receives an acknowledgement, it does a V on the semaphore to wake the thing
; up.
;
mouseAckSem	Semaphore <0,>		; Block on P
endif

idata		ends


;------------------------------------------------------------------------------
;		       INITIALIZATION/EXIT CODE
;
;------------------------------------------------------------------------------

;
; Include common definitions for serial mice
;
include	mouseSerCommon.asm

Init segment resource

ifdef CHECK_FOR_MOUSE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle receipt of a character during initialization

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
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevAck	proc	far
		and	al, 7fh
		cmp	al, 'M'		; MS mouse should respond with capital
					;  M when DTR is toggled.
		jne	MDARet
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
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the com port for the mouse

CALLED BY:	MouseInit
PASS:		DS=ES=dgroup
RETURN:		Carry clear if ok
DESTROYED:	DI

PSEUDO CODE/STRATEGY:
	Figure out which port to use.
       	Open it.

	Since we don't know the commands a microsoft mouse expects, we rely
	on the documentation for the microsoft-compatible mode of the
	logitech mouse, which states the thing runs at 1200 baud mode using
	7 data bits and lord knows how many stop bits. We assume 2 since
	that's what the logitech uses and it wouldn't be compatible if the
	microsoft mouse used only 1, would it?

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

		;
		; HandleMem port-specification here
		; BX CONTAINS UNIT NUMBER THROUGH ALL FUTURE CALLS
		;
		call	MouseOpenPort
		jc	MDIRet		

		;
		; Switch to 1200-baud, default format in raw mode
		;
		mov	cx, SB_1200
		mov	ax, (SM_RAW SHL 8) OR DEF_FORMAT
		CallSer	DR_SERIAL_SET_FORMAT
		
ifdef CHECK_FOR_MOUSE
		;
		; Drop both DTR and RTS to tell the mouse to reset. We wait
		; a tick of the clock to make sure it's clear to the thing...
		; Any input goes to MouseDevAck, which should V the semaphore
		; should the mouse send the expected 'M' back to us.
		;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, cs
		mov	dx, offset MouseDevAck
		mov	bp, ds		; pass dgroup in cx
		CallSer	DR_STREAM_SET_NOTIFY

		;
		; Make sure DTR is down.
		;
		clr	al
		CallSer	DR_SERIAL_SET_MODEM
		
		mov	ax, 5		; Wait a tick or 5
		call	TimerSleep

		;
		; Raise DTR and RTS again -- the mouse should respond with a
		; capital M within a reasonable time (ACK_DELAY). If it doesn't,
		; the semaphore will time-out and we'll refuse to run.
		;
		mov	al, DEF_MODEM
		CallSer	DR_SERIAL_SET_MODEM

		push	bx
		PTimedSem	ds, mouseAckSem, ACK_DELAY, TRASH_AX_BX_CX
		pop	bx
		jc	error
	
endif

		INT_OFF		; Nothing until we're initialized
		;
		; Change the input and error routines to the operational
		; ones (as opposed to the initialization ones) and flush the
		; input stream.
		;
		mov	ax, STREAM_READ
		CallSer	DR_STREAM_FLUSH
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, segment MouseDevHandler
		mov	dx, offset MouseDevHandler
		mov	bp, ds		; pass dgroup in cx
		CallSer	DR_STREAM_SET_NOTIFY

		mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_ROUTINE>
		mov	cx, segment MouseDevError
		mov	dx, offset MouseDevError
		mov	bp, ds		; pass dgroup in cx
		CallSer	DR_STREAM_SET_NOTIFY
		INT_ON

		;
		; All's well that ends well...
		;
		clc
MDIRet:
		.leave
		ret
ifdef CHECK_FOR_MOUSE
error:
		;
		; Close the port again and leave with the carry still set.
		;
		mov	ax, STREAM_DISCARD
		CallSer	DR_STREAM_CLOSE
		stc
		jmp	MDIRet
endif
MouseDevInit	endp


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
		MouseDevError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an error on our serial line

CALLED BY:	Serial driver
PASS:		ax	= dgroup
		cx	= error flags
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
		push	ds
	;
	; Switch into an error state and record yet another packet
	; lost.
	;
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
		
		mov	cx, SB_1200		; Always 1200 baud
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
PASS:		al	= character read
		cx	= dgroup
		dx	= stream token (ignored)
		bp	= STREAM_READ (ignored)
RETURN:		Carry set (character consumed)
DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far 	uses ds
		.enter
		mov	ds, cx

		mov	ah, ds:inState
		test	ah, IS_START
		jz	MDH2
		;
		; Make sure byte has high bit set (7-bit byte...)
		;
		test	al, 40h
		jz	MDHRet
		;
		; Record button state, change states and return.
		;
		mov	ds:inputBuf, al
		mov	ds:inState, IS_X
		jmp	MDHRet
MDH2:
		;
		; Make sure high bit isn't set (7-bit byte).
		;
		test	al, 40h
		jnz	error

		test 	ah, IS_X
		jz	MDH3
		;
		; Expecting X delta -- record it and return
		;
		mov	ds:inputBuf+1, al
		mov	ds:inState, IS_Y
		jmp	MDHRet
MDH3:
		test	ah, IS_Y
		jz	MDH6
		;
		; Expecting Y delta -- packet complete.
		;
		push	si, di	; Save for MouseSendEvents
		
		;
		; Shift first two bytes of packet into BX for later use
		;
		mov	bx, word ptr ds:inputBuf
	
		mov	dh, al

		clr	ax
		mov	al, bl
		;
		; Get buttons into bits 2 and 0
		;
		shl	ax, 1	; l -> b6
		shl	ax, 1	; l -> b7
		shl	ax, 1	; l -> b0
		stc		; middle always up,
		rcl	ah, 1	; l -> b1
		shl	ax, 1	; l -> b2, r -> b0
		xor	ah, 101b; want 1 => up, not down...
		
		;
		; Merge top two bits of deltaX in by first shifting
		; bits 0->5 up to bits 2->7, then rotate X7 and X6 into place
		;
		shl	bh, 1	; Shift X5 up to b7
		shl	bh, 1	; ...
		ror	bx, 1	; Shift X7 and X6 into place
		ror	bx, 1

		;
		; Y7 and Y6 now in b1 and b0 of BL. Do unto deltaY as we did
		; unto deltaX
		;
		shl	dh, 1
		shl	dh, 1
		mov	dl, bl
		ror	dx, 1
		ror	dx, 1
		;
		; Shift the things into their proper registers for M.S.E:
		;	buttons in BH
		;	deltaX in CX
		;	deltaY in DX
		;
		mov	al, bh		; deltaX -> AL
		mov	bh, ah		; buttons -> BH
		cbw			; extend deltaX
		mov	cx, ax		;  and transfer
		mov	al, dh		; deltaY -> AL
		cbw			; extend
		mov	dx, ax		;  and transfer
		
		or	bh, NOT 101b	; Mark unsupported buttons as UP
		call	MouseSendEvents

		pop	si, di
		;
		; Go back to waiting for the start byte (Fall Through)
		;
MDH6:
error:
		;
		; Error -- discard byte but reset state machine
		;
		mov	ds:inState, IS_START
MDHRet:
		stc			; Byte munched
		.leave
		ret
MouseDevHandler	endp

Resident ends

		end
