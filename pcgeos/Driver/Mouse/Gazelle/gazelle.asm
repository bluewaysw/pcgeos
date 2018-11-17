COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Gazelle pen digitizer
FILE:		gazelle.asm

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


DESCRIPTION:
	Device-dependent support for Gazelle pen digitizer
		

	$Id: gazelle.asm,v 1.1 97/04/18 11:48:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		=	1	; Current module

DEBUG_GAZELLE	=	0
;
MOUSE_NUM_BUTTONS	= 2

MouseDevExit	equ	<MouseClosePort>

MOUSE_SEPARATE_INIT	= 1	; We use a separate Init resource
MOUSE_SET_DEVICE_DOES_NOTHING=1	; Once we're sure there's a mouse there, there's
				;  nothing else to do.
MOUSE_USES_ABSOLUTE_DELTAS = 1

DIGITIZER_X_RES equ     95
DIGITIZER_Y_RES equ     95

;gazelle pen constants....
GazelleButtons	record
	GB_SYNC:1,		;packet sync bit.
	GB_NEAR:1,		;Pen proximity bit, active hi.
	GB_AUX:3,		;some sort of status pins on ASIC.
	GB_RESERVED:1,		;always zero.
	GB_BARREL:1,		;Barrel button state, 1= pressed.
	GB_TIP:1		;tip button state, 1= pressed.
GazelleButtons	end
	

SCREEN_MAX_X	=	255
SCREEN_MAX_Y	=	319

include		mouseCommon.asm	; Include common definitions/code.

MOUSE_TEST_DEVICE_NOT_CALLED				enum	FatalErrors

UseDriver Internal/serialDr.def

;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment
;
; DEFAULTS
;
DEF_PORT	= SERIAL_COM1		; Default port to try if none given
DEF_BAUDRATE	= SB_9600
DEF_FORMAT	= SerialFormat <0,0,SP_ODD,0,SL_8BITS>


MOUSE_NUM_RATES	=	1

	;
	; State machine definitions
	; 
InStates 	etype byte
IS_START 	enum InStates,1		; At start of packet -- byte
						; must have hi bit set
IS_X_LO		enum InStates,2
IS_X_HI		enum InStates,4
IS_Y_LO		enum InStates,8
IS_Y_HI		enum InStates,0x10
IS_ERR 		enum InStates, 0x80 	; Error received -- discard
					; next byte and reset
inState		InStates IS_START


if      DEBUG_GAZELLE
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
; Input buffer -- we use Summa MM Series format to make life easy, so we only
; need a 2-word input buffer. The reading of a packet is performed by
; a state machine in MouseDevHandler. An input packet is laid out as:
;
;	BIT7	BIT6	BIT5	BIT4	BIT3	BIT2	BIT1	BIT0
;	1	NoCare	NoCare	NoCare	NoCare	NoCare	NoCare	Button
;	0	X6	X5	X4	X3	X2	X1	X0
;	0	X13	X12	X11	X10	X9	X8	X7
;	0	Y6	Y5	Y4	Y3	Y2	Y1	Y0
;	0	Y13	Y12	Y11	Y10	Y9	Y8	Y7
;
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

offsetX		word			;offset from right
offsetY		word			;offset from bottom
scaleX		WWFixed			;scale factor for X coordinates
scaleY		WWFixed			;scale factor for Y coordinates

mouseRates	word	0

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

mouseNameTable	lptr.char	gazelle
		lptr.char	0		; null-terminator

gazelle		chunk.char	'Gazelle Pen (Serial)', 0

mouseInfoTable	MouseExtendedInfo	\
		mask MEI_SERIAL		; Gazelle

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
	set serial data format to match that for the desired format
	Point the serial driver's routines to go to the resident ones.
	Return with carry clear.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/13/92	Initial version

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
	; Switch to operational data format and baud rate 
	;
		mov	cx, DEF_BAUDRATE
		mov	ax, (SM_RAW SHL 8) OR DEF_FORMAT
		CallSer	DR_SERIAL_SET_FORMAT

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
		
		call	GazelleCalibrate	;pick up the offset and
						;scale factor.
	;
	; All's well that ends well...
	;
		clc
done:
		.leave
		ret
MouseDevInit	endp



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
;		mov	ax, STREAM_READ
;		CallSer	DR_STREAM_FLUSH

		mov	ax, DP_PRESENT

		clc		; Signal no error
		.leave
		ret
MouseRealTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GazelleCalibrate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	routine to correct for the digitizer's inaccuracies

CALLED BY:	MouseDevInit
PASS:		ds	= dgroup
RETURN:		calibration stuff loaded.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		read .ini file to get the scale factors, and the offsets
		for X and Y.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
gazelleCategory		byte	"mouse", 0
gazelleScaleXInt	byte	"scaleX", 0
gazelleScaleXFrac	byte	"scaleXfrac", 0
gazelleScaleYInt	byte	"scaleY", 0
gazelleScaleYFrac	byte	"scaleYfrac", 0
gazelleOffsetX		byte	"offsetX", 0
gazelleOffsetY		byte	"offsetY", 0

GazelleCalibrate	proc	near	uses ax,dx,cx,si
	.enter
	mov	si,offset gazelleCategory ;init file category string.
	mov	ax,7			;set up a default...
	mov	dx,offset gazelleScaleXInt ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:scaleX.WWF_int,ax	;stuff it.
	mov	ax,8192
	mov	dx,offset gazelleScaleXFrac ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:scaleX.WWF_frac,ax
	mov	ax,7			;set up a default...
	mov	dx,offset gazelleScaleYInt ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:scaleY.WWF_int,ax
	mov	ax,26214
	mov	dx,offset gazelleScaleYFrac ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:scaleY.WWF_frac,ax
	mov	ax,0x2a0
	mov	dx,offset gazelleOffsetX ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:offsetX,ax
	mov	ax,0x2f0
	mov	dx,offset gazelleOffsetY ;init file key string.
	call	GazelleFetchIniData	;see if its in the init file...
	mov	ds:offsetY,ax
	.leave
	ret
GazelleCalibrate	endp

GazelleFetchIniData	proc	near
	uses	ds
	.enter
	segmov	ds,cs,cx		;stuff cx, and ds with the code seg
	call	InitFileReadInteger	;grab the value.
	.leave
	ret
GazelleFetchIniData	endp





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
	dave	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevError	proc	far
		;
		; Switch into an error state and record yet another packet
		; lost.
		;
		push	ds
		mov	ds, ax
		mov	ds:inState, IS_ERR
		pop	ds
		ret
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
	Dave	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far
	uses	bx,ds
	.enter

	mov	ds, cx

	mov	ah, ds:inState
	cmp	ah, IS_START
	jne	checkForXLo
		;
		; Make sure byte has sync and near bits set.
		;
	test	al, mask GB_SYNC
	je	exitForNextByte
	test	al, mask GB_NEAR
	je	exitForNextByte
		;
		; Record button value, change states and return.
		;
if      DEBUG_GAZELLE
	call	SavePortData		;stuff raw port buffer.
endif
	mov	ds:inState, IS_X_LO	;set the state to next byte.
	mov	bh,0xff			;assume no presses currently.
	test	al, mask GB_TIP		;check button 1.
	jz	checkButton2
	and	bh,not mask LEFT_DOWN	;make the left button go...
checkButton2:
	test	al, mask GB_BARREL	;test for button 2.
	jz	stuffButtons
	and	bh,not mask RIGHT_DOWN
stuffButtons:
	mov	ds:buttons,bh	;asve the last button state.
	jmp	exitForNextByte		;exit, and wait for another byte.	

checkForXLo:
	test	al,mask GB_SYNC		;see if the hi bit is zero.....
	jne	setErrorOut		;if one, then packet is bad.
	test	ah, IS_X_LO		;see if we are on the correct state.
	jz	checkForXHi		;if not, check next state.
		;
		; Record first x value, change states and return.
		;
if      DEBUG_GAZELLE
        call    SavePortData            ;stuff raw port buffer.
endif
        mov     ds:inState, IS_X_HI     ;set the state to next byte.
	clr	ah			;init the position word.
	mov	ds:coordX,ax	;stuff the low 7 bits in.
	jmp	exitForNextByte

checkForXHi:
	test	ah, IS_X_HI		;see if we are on the correct state.
	jz	checkForYLo		;if not, check next state.
		;
		; Record second x value, change states and return.
		;
if      DEBUG_GAZELLE
        call    SavePortData            ;stuff raw port buffer.
endif
        mov     ds:inState, IS_Y_LO     ;set the state to next byte.
	clr	ah			;init the hi byte.
	mov	cl,7			;shift the 7 bits left 7 bits.
	shl	ax,cl
	or	ds:coordX,ax		;or the hi 7 bits in.
	jmp	exitForNextByte

checkForYLo:
	test	ah, IS_Y_LO		;see if we are on the correct state.
	jz	checkForYHi		;if not, check next state.
		;
		; Record first y value, change states and return.
		;
if      DEBUG_GAZELLE
        call    SavePortData            ;stuff raw port buffer.
endif
        mov     ds:inState, IS_Y_HI     ;set the state to next byte.
	clr	ah			;init the position word.
	mov	ds:coordY,ax		;stuff the low 7 bits in.
	jmp	exitForNextByte

checkForYHi:
	test	ah, IS_Y_HI		;see if we are on the correct state.
	jz	setErrorOut		;if not, bad packet, exit.
		;
		; Record second y value, change states and return.
		;
if      DEBUG_GAZELLE
        call    SavePortData            ;stuff raw port buffer.
endif
	clr	ah			;init the hi byte.
	mov	cl,7			;shift the 7 bits left 7 bits.
	shl	ax,cl
	or	ds:coordY,ax		;or the hi 7 bits in.

	call	GazelleCorrectCoords

	mov	bh,ds:buttons



if      DEBUG_GAZELLE
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
		GazelleCorrectCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the coordinates to ones PC/GEOS can use.

CALLED BY:	MouseDevHandler
PASS:		DS	= dgroup
RETURN:		cx = x coordinate
		dx = y coordinate
DESTROYED:	AX,BX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		REMEMBER: the pad is rotated so x and y are switched

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GazelleCorrectCoords	proc	near
	clr	cx
	mov	dx,ds:coordY		;really X coordinate.
	sub	dx,ds:offsetX		;translate....
	jns	xPositive
	clr	dx			;zero if it went neg.
xPositive:
	mov	bx,ds:scaleX.WWF_int
	mov	ax,ds:scaleX.WWF_frac
	call	GrUDivWWFixed		;do the scale down
					;dx = x position, backwards.
	mov	ax,SCREEN_MAX_X
	sub	ax,dx			;now we're pointing the right way...
	jns	correctedXPositive
	clr	ax
correctedXPositive:
	mov	ds:coordY,ax		;stuff away (remember it's X)
	clr	cx
	mov	dx,ds:coordX		;really Y coordinate.
	sub	dx,ds:offsetY		;translate....
	jns	yPositive
	clr	dx			;zero if it went neg.
yPositive:
	mov	bx,ds:scaleY.WWF_int
	mov	ax,ds:scaleY.WWF_frac
	call	GrUDivWWFixed		;do the scale down
					;dx = y position, backwards.
	mov	ax,SCREEN_MAX_Y
	sub	ax,dx			;now we're pointing the right way...
	jns	correctedYPositive
	clr	ax
correctedYPositive:
	mov	dx,ax			;put corrected Y Pos in correct reg
	mov	cx,ds:coordY		;get back the corrected X Pos.
	ret
GazelleCorrectCoords	endp

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
	Dave	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevSetRate	proc	near
		clc			; No error.
		ret
MouseDevSetRate	endp
if      DEBUG_GAZELLE


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
