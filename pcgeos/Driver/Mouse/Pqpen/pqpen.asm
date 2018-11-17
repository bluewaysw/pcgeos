COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Mouse Systems serial mouse
FILE:		pqpen.asm

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
		

	$Id: pqpen.asm,v 1.1 97/04/18 11:48:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		= 1
;
MOUSE_CANT_SET_RATE	= 1
MOUSE_NUM_BUTTONS	= 1
MOUSE_USES_ABSOLUTE_DELTAS = 1

DIGITIZER_X_RES		=	96	;96 DPI
DIGITIZER_Y_RES		=	72	;72 DPI

DEBUG_POQET_PEN		= 0

include		mouseCommon.asm	; Include common definitions/code.


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

mouseNameTable	lptr.char	poqetPad
		lptr.char	0	; null-terminator

poqetPad	chunk.char 'PoqetPad Pen', 0

mouseInfoTable	MouseExtendedInfo	\
		0			;poqetPad

CheckHack <length mouseInfoTable eq length mouseNameTable>
MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment

oldVector	fptr.far

;
; Packet format
;
; The reading of a packet is performed by a state machine in MouseDevHandler.
; On any input error, we reset the state machine to discard whatever packet
; we were reading.
;
; The mouse motion is accumulated in newX and newY, while the packet's
; button info is stored in 'buttons'
;
newX		word
newY		word
buttons		byte

	;
	; State machine definitions
	; 
InStates 	etype byte
IS_START 	enum InStates		; At start of packet -- byte
						; must have have high bit on
IS_X_LOW 	enum InStates		; Expecting X low
IS_X_HIGH 	enum InStates		; Expecting X high
IS_Y_LOW 	enum InStates		; Expecting Y low
IS_Y_HIGH 	enum InStates		; Expecting Y high
IS_ERR 		enum InStates	 	; Error received -- discard
					; until sync byte (not actually
					; used since IS_START state
					; discards until sync)
inState		InStates IS_START

mouseRates	label	byte	; Needed to avoid assembly errors.
MOUSE_NUM_RATES	equ	0	; We can't change the report rate.


if	DEBUG_POQET_PEN
HACK_BUF_SIZE	=	2000
hackPtr	word	0
pbuf	byte	HACK_BUF_SIZE dup (0)
endif

idata		ends


Resident segment resource


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
MouseDevInit	proc	far	uses ax, bx, cx, dx, si, di, bp
	.enter

	mov	di, offset oldVector
	mov	bx, segment MouseDevHandler
	mov	cx, offset MouseDevHandler
	mov	ax, 2
	call	SysCatchDeviceInterrupt

	;
	; All's well that ends well...
	;
	clc

	.leave
	ret

MouseDevInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down.

CALLED BY:	MousePortExit
PASS:		DS	= dgroup
RETURN:		Carry set if couldn't close the port (someone else was
			closing it (!)).
DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevExit	proc	far
	;
	; Close down the port...if it was ever opened, that is.
	;
	segmov	es, ds
	mov	di, offset oldVector
	mov	ax, 2
	call	SysResetDeviceInterrupt

	ret
MouseDevExit	endp

;------------------------------------------------------------------------------
;		  RESIDENT DEVICE-DEPENDENT ROUTINES
;------------------------------------------------------------------------------



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
		clc
;;;		call	MouseDevTest
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
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem the receipt of a byte in the packet.

CALLED BY:	INT2
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	call	SysEnterInterrupt

	mov	dx, dgroup
	mov	ds, dx

	; loop reading bytes and calling FSM

readLoop:
	mov	dx, 0x3e8
	in	al, dx
	call	FSMByte
	mov	dx, 0x3ea
	in	al, dx
	test	al, 1
	jz	readLoop

	mov	al, IC_GENEOI
	out	IC1_CMDPORT, al

	call	SysExitInterrupt

	.leave
	iret

MouseDevHandler	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FSMByte

DESCRIPTION:	Handle a byte from the digitizer

CALLED BY:	INTERNAL

PASS:
	al - byte
	ds - idata

RETURN:
	none

DESTROYED:
	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/15/92		Initial version

------------------------------------------------------------------------------@
FSMByte	proc	near

if	DEBUG_POQET_PEN
	push	si
	mov	si, ds:hackPtr
	mov	ds:[pbuf][si], al
	inc	si
	cmp	si, HACK_BUF_SIZE
	jnz	1$
	clr	si
1$:
	mov	ds:hackPtr, si
	pop	si
endif

	mov	ah, ds:inState
	cmp	ah, IS_START
	jnz	notFirst
	;
	; Make sure start byte is legal (high bit must be set)
	;
	test	al, 0x80
	jnz	5$
toError:
	jmp	error
5$:

	; treat 0x98 as error (always has data 0)

	cmp	al, 0x98
	jz	toError

	;
	; Record button state, change states and return.
	;
	mov	ds:buttons, al
	mov	ds:inState, IS_X_LOW
	jmp	done

notFirst:
	test	al, 0x80
	jnz	toError

	cmp	ah, IS_X_LOW
	jnz	notXLow
	;
	; Expecting X low -- record it and return.
	;
	shl	al
	mov	ds:newX.low, al
	mov	ds:inState, IS_X_HIGH
	jmp	done
notXLow:

	cmp 	ah, IS_X_HIGH
	jnz	notXHigh
	;
	; Expecting X high -- record it and return
	;
	mov	ds:newX.high, al
	shr	ds:newX
	mov	ds:inState, IS_Y_LOW
	jmp	done
notXHigh:

	cmp	ah, IS_Y_LOW
	jnz	notYLow
	;
	; Expecting Y low -- record it and return.
	;
	shl	al
	mov	ds:newY.low, al
	mov	ds:inState, IS_Y_HIGH
	jmp	done
notYLow:

	cmp 	ah, IS_Y_HIGH
	jnz	error
	;
	; Expecting X high -- record it and return
	;
	mov	ds:newY.high, al
	shr	ds:newY

	; packet complete -- send it

DIGITIZER_MAX_X	=	4096
DIGITIZER_MAX_Y	=	4096

X_MULTIPLIER	=	30800 ; 31018
Y_MULTIPLIER	=	25000 ; 28560

	mov	ax, ds:newX
	cmp	ax, DIGITIZER_MAX_X
	jbe	10$
	clr	ax
10$:
	mov	bx, X_MULTIPLIER
	mul	bx
	mov	cx, dx				;cx = x pos
	mov	ax, ds:newY
	cmp	ax, DIGITIZER_MAX_Y
	jbe	20$
	clr	ax
20$:
	mov	bx, Y_MULTIPLIER
	mul	bx				;dx = y pos

MAX_POSITION_X	=	639
MAX_POSITION_Y	=	207

	cmp	cx, MAX_POSITION_X
	jbe	notOutOfRangeX
	mov	cx, MAX_POSITION_X
notOutOfRangeX:
	cmp	dx, MAX_POSITION_Y
	jbe	notOutOfRangeY
	mov	dx, MAX_POSITION_Y
notOutOfRangeY:
	;
	; Shift buttons into BH for later manipulation.
	;
	mov	bh, mask MOUSE_B0 or mask MOUSE_B1 or mask MOUSE_B2 \
			or mask MOUSE_B3
	cmp	ds:buttons, 0x82
	jz	notPress
	mov	bh, mask MOUSE_B1 or mask MOUSE_B2 or mask MOUSE_B3
notPress:

	;
	; Deliver whatever events are required.
	;
	call	MouseSendEvents

	;
	; Go back to waiting for the start byte (Fall Through)
	;
error:
	;
	; Error -- discard byte but reset state machine
	;
	mov	ds:inState, IS_START
done:
	ret

FSMByte	endp

Resident ends
