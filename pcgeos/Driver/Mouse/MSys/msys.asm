COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Mouse Systems serial mouse
FILE:		msys.asm

AUTHOR:		Adam de Boor, August 9, 1989

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
	Device-dependent support for Mouse Systems serial mouse.
		

	$Id: msys.asm,v 1.1 97/04/18 11:47:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		= 1
;
MOUSE_NUM_BUTTONS	= 3
MOUSE_CANT_SET_RATE	=1
MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MouseDevExit	equ	<MouseClosePort>

include		mouseCommon.asm	; Include common definitions/code.

UseDriver	Internal/serialDr.def


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

mouseNameTable	lptr.char	mouseSystems,
				pcMouse,
				;pcMouseBus,\
				;pcMouseBus2,\
				msysCom,
				other3B,
				optiMouse,
				artecAM21,
				cmsMiniMouseStd,
				cmsMiniMouseHR,
				wittyMouse,
				fancyMouse,
				wittyBall,
				dms200,
				dms200H,
				focusFT100,
				trackBallPlus,
				itacMouseTrack,
				genius,
				pcTrac,
				fastTrap,
				theWhiteMouse,
				laser3B,
				mightyCat
		lptr.char	0	; null-terminator

mouseSystems	chunk.char 'Mouse Systems Serial', 0
pcMouse		chunk.char 'PC-Mouse Serial', 0
msysCom		chunk.char 'Mouse Systems-compatible Serial', 0
other3B		chunk.char 'Other 3-button Serial', 0
optiMouse	chunk.char 'IMSI OptiMouse', 0
artecAM21	chunk.char 'Artec AM-21 Plus (Mouse Systems Mode)', 0
cmsMiniMouseStd	chunk.char 'CMS Mini Mouse Serial', 0
cmsMiniMouseHR	chunk.char 'CMS Hi-res Mini Mouse Serial', 0
wittyMouse	chunk.char 'Commax Witty Mouse (Mouse Systems Mode)', 0
fancyMouse	chunk.char 'Commax Fancy Mouse (Mouse Systems Mode)', 0
wittyBall	chunk.char 'Commax Witty Ball (Mouse Systems Mode)', 0
dms200		chunk.char 'DFI DMS-200 Mouse (Mouse Systems Mode)', 0
dms200H		chunk.char 'DFI DMS-200H Mouse (Mouse Systems Mode)', 0
focusFT100	chunk.char 'Focus FT-100 Tracker (Mouse Systems Mode)', 0
trackBallPlus	chunk.char 'Fulcrum Trackball Plus (Mouse Systems Mode)', 0
itacMouseTrack	chunk.char 'ITAC Mouse-trak Serial (Mouse Systems Mode)', 0
genius		chunk.char 'Genius Serial (Mouse Systems Mode)', 0
pcTrac		chunk.char 'MicroSpeed PC-Trac Serial (Mouse Systems Mode)', 0
fastTrap	chunk.char 'MicroSpeed FastTRAP Serial (Mouse Systems Mode)', 0
theWhiteMouse	chunk.char 'The White Mouse Serial (Mouse Systems Mode)', 0
laser3B		chunk.char 'Laser 3-button Serial (Mouse Systems Mode)', 0
;pcMouseBus	chunk.char 'PC-Mouse, Bus Version (default port)', 0
;pcMouseBus2	chunk.char 'PC-Mouse, Bus Version (port 338)', 0
mightyCat	chunk.char 'Qtronix Mighty Cat', 0

mouseInfoTable	MouseExtendedInfo	\
		mask	MEI_SERIAL,	;mouseSystems \
		mask	MEI_SERIAL,	;pcMouse \
		;3 shl offset MEI_IRQ or 2,;pcMouseBus \
		;3 shl offset MEI_IRQ or 3,;pcMouseBus2 \
		mask	MEI_SERIAL,	;msysCom \
		mask	MEI_SERIAL,	;other3B \
		mask	MEI_SERIAL,	;optiMouse \
		mask	MEI_SERIAL,	;artecAM21 \
		mask	MEI_SERIAL,	;cmsMiniMouseStd \
		mask	MEI_SERIAL,	;cmsMiniMouseHR \
		mask	MEI_SERIAL,	;wittyMouse \
		mask	MEI_SERIAL,	;fancyMouse \
		mask	MEI_SERIAL,	;wittyBall \
		mask	MEI_SERIAL,	;dms200 \
		mask	MEI_SERIAL,	;dms200H \
		mask	MEI_SERIAL,	;focusFT100 \
		mask	MEI_SERIAL,	;trackBallPlus \
		mask	MEI_SERIAL,	;itacMouseTrack \
		mask	MEI_SERIAL,	;genius \
		mask	MEI_SERIAL,	;pcTrac \
		mask	MEI_SERIAL,	;fastTrap \
		mask	MEI_SERIAL,	;theWhiteMouse \
		mask	MEI_SERIAL,	;laser3B
		mask	MEI_SERIAL	;mightyCat

CheckHack <length mouseInfoTable eq length mouseNameTable>
MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment

;
; DEFAULTS
;
; This format is specified in the OptiMouse reference manual on page 65
;
DEF_PORT	= SERIAL_COM1		; Default port to try if none given
DEF_FORMAT	= SerialFormat <0,0,SP_NONE,0,SL_8BITS>
DEF_MODEM	= mask SMC_OUT2		; OR mask SMC_RTS OR mask SMC_DTR

;
; Buffer sizes for serial connection
;
MOUSE_INBUF_SIZE= 16
MOUSE_OUTBUF_SIZE= 16

;
; Input buffer -- Mouse Systems packets are kind of bizarre. They consist
; of five bytes, beginning with a sync byte whose high 5 bits are 10000.
; Apparently, no delta will begin that way, or something. The low three bits
; of the sync byte contain the button information (0 => pressed). The next two
; are delta X and delta Y since last report, then come delta X and delta Y
; since start of report. Very strange.
;
; The reading of a packet is performed by a state machine in MouseDevHandler.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
; The mouse motion is accumulated in deltaX and deltaY, while the packet's
; button info is stored in 'buttons'
;
; deltaX is a word as we may need to accumulate a delta greater than
; one byte can hold. With deltaY, however, we need only store a byte,
; as the addition comes just before the packet is sent on.
; 
deltaX		word
deltaY		word
buttons		byte
;
; Permissible values for sync bytes.
;
SYNC_MIN	= 80h
SYNC_MAX	= 87h

	;
	; State machine definitions
	; 
InStates 	etype byte
IS_START 	enum InStates, 1	; At start of packet -- byte
						; must have have high bit on
IS_X1 		enum InStates, 2	; Expecting first delta X
IS_Y1 		enum InStates, 4	; Expecting first delta Y
IS_X2 		enum InStates, 8	; Expecting second delta X
IS_Y2 		enum InStates, 16	; Expecting second delta Y
IS_ERR 		enum InStates, 128 	; Error received -- discard
					; until sync byte (not actually
					; used since IS_START state
					; discards until sync)
inState		InStates IS_START

		even
mouseRates	label	byte	; Needed to avoid assembly errors.
MOUSE_NUM_RATES	equ	0	; We can't change the report rate.

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the com port for the mouse

CALLED BY:	MouseInit
PASS:		DS=ES=dgroup
RETURN:		Carry clear if ok
DESTROYED:	DI

PSEUDO CODE/STRATEGY:
	Figure out which port to use.
       	Open it.

	The data format is specified in the DEF constants above, as 
	extracted from the documentation.

	Return with carry clear.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
irqKey		char	MOUSE_IRQ, 0
MouseDevInit	proc	far	uses ax, bx, cx, dx, si, bp
		.enter
		call	MouseMapDevice
		assume	es:MouseExtendedInfoSeg
		mov	ax, es:mouseInfoTable[di]
		call	MemUnlock
		assume	es:nothing
		test	ax, mask MEI_SERIAL
		jz	isBus

	;
	; Handle port-specification here
	; BX CONTAINS UNIT NUMBER THROUGH ALL FUTURE CALLS
	;
		Call	MouseOpenPort
		jc	MDIRet
		
portOpen:
	;
	; Switch to 1200-baud, default format in raw mode
	;
		mov	cx, SB_1200
		mov	ax, (SM_RAW SHL 8) OR DEF_FORMAT
		CallSer	DR_SERIAL_SET_FORMAT

		mov	al, DEF_MODEM
		CallSer	DR_SERIAL_SET_MODEM

		INT_OFF		; Nothing until we're initialized
	;
	; Change the input and error routines to the operational
	; ones (as opposed to the initialization ones).
	;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, segment MouseDevHandler
		mov	dx, offset MouseDevHandler
		mov	bp, ds			; pass cx = dgroup
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
MDIRet:
		.leave
		ret
isBus:
	;
	; Locate the serial driver's strategy routine since we're not
	; calling MouseOpenPort.
	;
		push	ax, ds
		mov	bx, handle serial
		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	bx, ds:[si].DIS_strategy.segment
		pop	ds
		
		mov	ds:[driver].offset, ax
		mov	ds:[driver].segment, bx
	;
	; Now extract the IRQ level from the ini file. If it's not given,
	; we refuse to load.
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset portCategory
		mov	dx, offset irqKey
		call	InitFileReadInteger
		mov	cx, ax
		pop	ax, ds
		jc	MDIRet

	;
	; IRQ now in CL. Use low byte of info word as high byte of base port
	; (see MouseDevTest, below), with 0x38 as the low byte and get the
	; serial driver to run the port for us.
	; 
		mov	ah, al
		mov	al, 0x38
		mov	bx, -1		; not PCMCIA
		CallSer	DR_SERIAL_DEFINE_PORT
		jc	MDIRet
		mov	ds:[mouseUnit], bx
	;
	; Open the port given in BX without blocking or timing out.
	; The buffer sizes used are specified by the includer of
	; this file.
	; 
		clr	ax		; block, no timeout
		mov	cx, MOUSE_INBUF_SIZE
		mov	dx, MOUSE_OUTBUF_SIZE
		mov	si, handle 0	; We own this thing...
		CallSer	DR_SERIAL_OPEN_FOR_DRIVER
		jmp	portOpen
MouseDevInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseMapDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a device string to its device index

CALLED BY:	MouseDevTest, MouseDevInit
PASS:		dx:si	= device string
RETURN:		carry set if string invalid
			ax	= DP_INVALID_DEVICE
		carry clear if string valid
			di	= device index (offset into mouseNameTable
				  and mouseInfoTable)
			es	= locked info block
			bx	= handle of same
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseMapDevice	proc	near	uses cx, ds
		.enter
		EnumerateDevice	MouseExtendedInfoSeg
		.leave
		ret
MouseMapDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the device.

CALLED BY:	MouseTestDevice
PASS:		dx:si	= null-terminated device name string
RETURN:		carry set if string is invalid, etc. etc. etc.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevTest	proc	far	uses bx, es, di, dx
		.enter
		call	MouseMapDevice
		jc	done
		assume	es:MouseExtendedInfoSeg
	;
	; If we've been told to support our regular serial persona, we can't
	; tell if it's there.
	;
		test	es:mouseInfoTable[di], mask MEI_SERIAL
		mov	ax, DP_CANT_TELL
		jnz	done

	;
	; Make sure an interrupt has been defined for us to use. If not,
	; there's nothing we can do...
	;
		push	ds, cx, si
		segmov	ds, cs, cx
		mov	si, offset portCategory
		mov	dx, offset irqKey
		call	InitFileReadInteger
		pop	ds, cx, si
		mov	ax, DP_INVALID_DEVICE
		jc	done
	;
	; Else we figure which port it's supposed to be on. The two
	; options are 0x238 and 0x338. We've "cleverly" placed 2 or 3 in the
	; low byte of the info word for our nefarious purposes, so...
	; This is similar to SerialCheckExists, which see. The interrupt ID
	; register for the port is 2 off the base and should have all but
	; the low three bits (the ID portion of the register) as 0. Since a
	; non-existent port usually reads as FF, we can take any of these
	; bits being 1 as a sign that the device isn't there.
	;
		mov	dh, {byte}es:mouseInfoTable[di]
		mov	dl, 0x3a
CheckHack <((mask MouseExtendedInfo) and 0x3f) eq 0>
		call	MemUnlock	; release the info block
		assume	es:nothing
		in	al, dx
		test	al, not 0x7
		mov	ax, DP_NOT_PRESENT
		jnz	done
		mov	ax, DP_PRESENT
done:
		.leave
		ret
MouseDevTest	endp

Init ends

;------------------------------------------------------------------------------
;		  RESIDENT DEVICE-DEPENDENT ROUTINES
;------------------------------------------------------------------------------

Resident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a device

CALLED BY:	DRE_TEST_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		carry set if string is invalid
		carry clear if string is valid
		ax	= DevicePresent enum in either case
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice	proc	near
		.enter
		call	MouseDevTest
		.leave
		ret
MouseTestDevice	endp



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

SYNOPSIS:	HandleMem an error on our serial line

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
MouseDevError	proc	far	uses ds
		.enter
		mov	ds, ax
		;
		; Switch into an error state and record yet another packet
		; lost.
		;
		mov	ds:inState, IS_ERR
		inc	ds:mouseErrors
		.leave
		ret
MouseDevError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem the receipt of a byte in the packet.

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
MouseDevHandler	proc	far	uses ds
		.enter
		mov	ds, cx

		mov	ah, ds:inState
		test	ah, IS_START
		jz	MDH2
	;
	; Make sure byte has 10000 in the high bits.
	;
		cmp	al, SYNC_MIN
		jb	MDHRet
		cmp	al, SYNC_MAX
		ja	MDHRet
	;
	; Record button state, change states and return.
	;
		mov	ds:buttons, al
		mov	ds:inState, IS_X1
		jmp	MDHRet
MDH2:
		test 	ah, IS_X1
		jz	MDH3
	;
	; Expecting first X delta -- record it and return
	;
		cbw
		mov	ds:deltaX, ax
		mov	ds:inState, IS_Y1
		jmp	MDHRet
MDH3:
		test	ah, IS_Y1
		jz	MDH4
	;
	; Expecting first Y delta -- record it and return.
	;
		cbw
		mov	ds:deltaY, ax
		mov	ds:inState, IS_X2
		jmp	MDHRet
MDH4:
		test	ah, IS_X2
		jz	MDH5
	;
	; Expecting second X delta -- add it to the first and return
	;
		cbw
		add	ds:deltaX, ax
		mov	ds:inState, IS_Y2
		jmp	MDHRet
MDH5:
		test	ah, IS_Y2
		jz	MDH6
	;
	; Expecting second Y delta -- packet complete
	;
		push	si, di	; Save for MouseSendEvents
		
	;
	; Load deltaX into CX for MouseSendEvents
	;
		mov	cx, ds:deltaX
	;
	; Shift buttons into BH for later manipulation.
	;
		mov	bh, ds:buttons
		or	bh, not 7	; Set all non-button bits
					;  to make sure no strange reports
					;  get sent (sorry for the magic
					;  number, but can't use
					;  MouseButtonBits as that might
					;  change in the future and we really
					;  want to prevent buttons we don't
					;  have from being recorded as down)
	;
	; Accumulate second Y delta in DX.
	; The mouse counts up to be positive, but we say it's the other way
	; round, so negate the final delta.
	;
		cbw			; sign-extend
		add	ax, ds:deltaY	; add in previous delta
		neg	ax
		xchg	ax, dx		; dx = deltaY (1-byte inst)
	
	;
	; Deliver whatever events are required.
	;
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

Resident ends

		end
