COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mouse Driver -- Casio Zoomer pen mouse driver
FILE:		casiopen.asm

AUTHOR:		Don Reeves, November 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Intialize the device, registering a handler
				with the DOS Mouse driver
	MouseDevExit		Deinitialize the device, nuking our handler.
	MouseDevHandler		Handler for DOS driver to call.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/4/92		Initial revision

DESCRIPTION:
	Mouse driver to support the Casio Zoomer pen.

	$Id: casiopen.asm,v 1.1 97/04/18 11:48:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse			= 1

MOUSE_NUM_BUTTONS 		=	1
MOUSE_CANT_SET_RATE		=	1
MOUSE_SEPARATE_INIT		=	1
MOUSE_DONT_ACCELERATE		=	1
MOUSE_USES_ABSOLUTE_DELTAS    	=	1
MOUSE_CAN_BE_CALIBRATED		=	1

RECORD_PEN_EVENTS		equ	FALSE

; Assumes .30 dot pitch
;
DIGITIZER_X_RES			=	84	;84 DPI
DIGITIZER_Y_RES			=	84	;84 DPI

HARDWARE_TYPE			equ	<ZOOMER>
.186					; allow NEC V20 instructions

MOUSE_PTR_FLAGS = mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE

include		mouseCommon.asm		; Include common definitions/code.
include		timer.def
include		graphics.def
include		system.def

;------------------------------------------------------------------------------
;			Casio Zoomer Constants
;------------------------------------------------------------------------------

CASIO_DISPLAY_X		equ	256
CASIO_DISPLAY_Y		equ	320

; The CasioPenFunction's are accessed via interrupt 15h, with the
; function number passed in AL
;
CASIO_INTERRUPT		equ	0x15
CASIO_FUNCTION		equ	0x70

CallCasio	macro	function
		mov	ax, function or (CASIO_FUNCTION shl 8)
		int	CASIO_INTERRUPT
endm

CasioPenFunction		etype	byte
    CPF_RETURN_CALLBACKS	enum	CasioPenFunction, 00h
    CPF_GET_PEN_MODE		enum	CasioPenFunction, 01h
    CPF_READ_PEN_STATUS		enum	CasioPenFunction, 02h
    CPF_GET_PEN_HANDLER		enum	CasioPenFunction, 03h
    CPF_GET_CALIBRATION_POINTS	enum	CasioPenFunction, 04h
    CPF_GET_CALIBRATION_RESULTS	enum	CasioPenFunction, 05h

CPF_SET_PEN_MODE		equ	CPF_GET_PEN_MODE
CPF_SET_PEN_HANDLER		equ	CPF_GET_PEN_HANDLER
CPF_SET_CALIBRATION_RESULTS	equ	CPF_GET_CALIBRATION_RESULTS

HardIcon		struct
    HI_leftEdge		word		; left edge of hard icon (inclusive)
    HI_dataCX		word		; data to pass back in CX
    HI_dataDX		word		; data to pass back in DX
    HI_dataBP		word		; data to pass back in BP
HardIcon		ends

;------------------------------------------------------------------------------
;			Other constants
;------------------------------------------------------------------------------

PEN_GET_MODE		equ	00h
PEN_SET_MODE		equ	01h

PEN_GET_HANDLER		equ	00h
PEN_SET_HANDLER		equ	01h

PEN_MODE_DISABLE	equ	00h
PEN_MODE_ENABLE		equ	01h

CasioPenStatus		etype	byte
    CPS_PEN_SCAN	enum	CasioPenStatus, 00h
    CPS_PEN_ON		enum	CasioPenStatus, 01h
    CPS_PEN_OFF		enum	CasioPenStatus, 02h
    CPS_RESERVED	enum	CasioPenStatus, 03h

CasioPenReturn		etype	byte
    CPR_CONTINUE	enum	CasioPenReturn, 00h
    CPR_DISCONTINUE	enum	CasioPenReturn, 01h

CasioPenCalibration	etype	byte
    CPC_GET_CALIBRATION	enum	CasioPenCalibration, 00h
    CPC_SET_CALIBRATION	enum	CasioPenCalibration, 01h

PenHistory		struct
    PH_status		CasioPenStatus
    PH_penX		word
    PH_penY		word
PenHistory		ends

BAD_MOUSE_COORDINATE					enum	FatalErrors

;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------

MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},				; lmem header added by Esp
		length mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	casioPenName
		lptr.char	0	; null-terminator

casioPenName	chunk.char	'Zoomer Pen', 0

mouseInfoTable	MouseExtendedInfo	\
		mask MEI_CALIBRATE		; can be calibrated

ForceRef	mouseExtendedInfo

MouseExtendedInfoSeg	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata		segment

mouseRates	label	byte			; to avoid assembly errors
MOUSE_NUM_RATES	equ	0

if		RECORD_PEN_EVENTS
historyLoc	word		offset history
endif

idata		ends



udata		segment

oldHandler	fptr.far			; old handler fptr
lastPosAdj	Point				; last adjusted point
lastPosRaw	Point				; last raw point
hardIconDown	BooleanByte			; pen down in hard-icon area

if		RECORD_PEN_EVENTS
history		PenHistory 	1000 dup (<>)
historyEnd	label		byte
endif

udata		ends



Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the device

CALLED BY:	MouseSetDevice()

PASS:		DS, ES	= DGroup

RETURN:		carry	= set on error (s/b nothing)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/4/92		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevInit	proc	far
		uses	ax, bx, cx, dx, di, si
		.enter

		; Attempt to calibrate the digitizer based upon settings
		; in the .INI file
		;
		mov	cx, 4			; # of calibration points
		call	ReadCalibrationDataFromIni

		; Turn the pen scan off
		;
		mov	bx, (PEN_SET_MODE shl 8) or PEN_MODE_DISABLE
		CallCasio	CPF_SET_PEN_MODE

		; Set up the pen handler, saving the old one
		;
		mov	bh, PEN_GET_HANDLER
		CallCasio	CPF_GET_PEN_HANDLER
		movdw	ds:[oldHandler], dxcx

		mov	bh, PEN_SET_HANDLER
		mov	dx, segment MouseDevHandler
		mov	cx, offset MouseDevHandler
		CallCasio	CPF_SET_PEN_HANDLER

		; Turn the pen scan on
		;
		mov	bx, (PEN_SET_MODE shl 8) or PEN_MODE_ENABLE
		CallCasio	CPF_SET_PEN_MODE

		; Finally, position cursor in middle of screen
		; (all buttons are up)
		;
		mov	bh, MouseButtonBits<1,1,1,1>
		mov	cx, CASIO_DISPLAY_X / 2
		mov	dx, CASIO_DISPLAY_Y / 2
		call	MouseSendEventsFar
		clc

		.leave
		ret
MouseDevInit	endp

categoryString	char	"mouse", 0
keyString	char	"calibration", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadCalibrationDataFromIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the calibration data from the .INI file, and reset
		the calibration if valid values are found

CALLED BY:	MouseDevInit

PASS:		CX	= # of points expected to be found

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadCalibrationDataFromIni	proc	near
		uses	di, si, bp, ds, es
		.enter
	
		; Read the data from the .INI file
		;
		mov	bp, 100
		sub	sp, bp
		segmov	es, ss
		mov	di, sp
		push	cx
		segmov	ds, cs, cx
		mov	si, offset categoryString
		mov	dx, offset keyString
		call	InitFileReadData

		; If error or if amount of data doesn't match, ignore
		;
		pop	bp
		jc	done
		shr	cx, 2			; 4 bytes per point
		cmp	cx, bp
		jne	done

		; Else re-calibrate the digitzer
		;
		movdw	dxsi, esdi		; point buffer => DX:SI
		mov	ax, CPF_SET_CALIBRATION_RESULTS or \
			    (CASIO_FUNCTION shl 8)
		mov	bh, CPC_SET_CALIBRATION
		call	CalibrationBIOSCommon
done:
		add	sp, 100

		.leave
		ret
ReadCalibrationDataFromIni	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCalibrationDataToIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the calibration points to the .INI file

CALLED BY:	MouseSetCalibrationPoints

PASS:		DX:SI	= Point buffer
		CX	= # of points

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteCalibrationDataToIni	proc	far
		uses	cx, dx, bp, di, si, ds, es
		.enter
	
		movdw	esdi, dxsi
		shl	cx, 2			; each point is 4 bytes
		mov	bp, cx
		segmov	ds, cs, cx
		mov	si, offset categoryString
		mov	dx, offset keyString
		call	InitFileWriteData

		.leave
		ret
WriteCalibrationDataToIni	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrationCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either set or get the calibration data

CALLED BY:	UTILITY

PASS:		AX	= BIOS function
		BH	= Sub-function		
		DX:SI	= Buffer

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalibrationBIOSCommon	proc	far
		uses	cx
		.enter

		mov	cx, si			; point buffer => DX:CX
		call	SysLockBIOS
		int	CASIO_INTERRUPT
		call	SysUnlockBIOS
		
		.leave
		ret
CalibrationBIOSCommon	endp

Init		ends



Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	MouseExit()

PASS:		DS	= DGroup

RETURN:		carry	= set on error

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/4/92		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseDevExit	proc	near

		; Tell the pen to stop reporting
		;
		mov	bx, (PEN_SET_MODE shl 8) or PEN_MODE_DISABLE
		CallCasio	CPF_SET_PEN_MODE

		; Restore the previous handler
		;
		mov	bh, PEN_SET_HANDLER
		movdw	dxcx, ds:[oldHandler]
		CallCasio	CPF_SET_PEN_HANDLER

		clc
		ret
MouseDevExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the device specified is present.

CALLED BY:	DRE_TEST_DEVICE	

PASS:		dx:si	= null-terminated name of device (ignored, here)

RETURN:		ax	= DevicePresent enum
		carry set if string invalid, clear otherwise

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseTestDevice	proc	near
		.enter

		; Check the pen status
		;
		CallCasio	CPF_READ_PEN_STATUS
		mov	ax, DP_NOT_PRESENT
		cmp	bl, 1
		jae	done			; if not 0 or 1, error
		mov	ax, DP_PRESENT
done:
		clc
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
		Don	11/4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseSetDevice	proc	near
		call	MouseDevInit
		ret
MouseSetDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse handler routine to take the event and pass it to
		MouseSendEvents()

CALLED BY:	EXTERNAL (Pen BIOS)

PASS:		AL	= CasioPenStatus
		(CX,DX)	= Adjusted coordinate
		(SI,DI) = Raw coordinate

RETURN:		AL	= CasioPenReturn

DESTROYED:	AH, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/4/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

inHandler	byte	1

MouseDevHandler	proc	far
		dec	cs:inHandler
		jns	notInHandler
		mov	al, CPR_CONTINUE	; branch if already in routine 
		jmp	endInterrupt		; & continue scan
notInHandler:
		uses	ds
		.enter

		; Pass the information on to the system
		;
		segmov	ds, dgroup, bx		; dgroup => DS
		and	al, CPS_RESERVED	; clear high bits
		cmp	al, CPS_RESERVED
		je	discontinue		; if reserved, abort
		cmp	dx, CASIO_DISPLAY_Y
		jg	hardIconCheck		; if beyond length, do hard icon
screenEvent:
		tst	ds:[hardIconDown]	; if pen down in hard icon area
		jnz	done			; ...then no normal pen input
		mov	bh, 0xff		; assume mouse is up
		cmp	al, CPS_PEN_OFF		; check assumption
		je	penUp
		mov	bh, not (mask MOUSE_B0)	; else mark b0 down, others up
sendMouseEvent:
if		RECORD_PEN_EVENTS
		push	si
		mov	si, ds:[historyLoc]
		cmp	si, offset historyEnd
		je	doneHistory
		mov	ds:[si].PH_status, al
		mov	ds:[si].PH_penX, cx
		mov	ds:[si].PH_penY, dx
		add	ds:[historyLoc], size PenHistory
doneHistory:
		pop	si
endif
		push	ax
		call	MouseSendEvents
		pop	ax

		; We're done. Determine if pen scan should continue.
done:
		cmp	al, CPS_PEN_OFF		; if pen is not OFF, continue
		mov	al, CPR_CONTINUE	; assume that we continue
		jne	exit
discontinue:
		mov	ds:[hardIconDown], BB_FALSE
		mov	al, CPR_DISCONTINUE	; discontinue scan
exit:
		.leave
endInterrupt:
		inc	cs:inHandler
		ret

		; Record pen position on pen-up, so we can avoid brain-dead
		; BIOS bugs for when we want to query the pen position
		; (needed for calibration)
penUp:
		mov	ds:[lastPosAdj].P_x, cx
		mov	ds:[lastPosAdj].P_y, dx
		mov	ds:[lastPosRaw].P_x, si
		mov	ds:[lastPosRaw].P_y, di
		jmp	sendMouseEvent		

		; Hard icon events may only be generated if the user
		; starts the pen down in the hard icon area. Else, we
		; just constrain the input to the screen
hardIconCheck:
		cmp	al, CPS_PEN_ON
		je	hardIconEvent
		tst	ds:[hardIconDown]
		jz	screenEvent

		; Deal with events in the hard icon area. Each area is
		; 256 / 10 = 25.6 = 26 pixels wide. We make the leftmost
		; & rightmost icons two pixels smaller than the rest
hardIconEvent:
		mov	ds:[hardIconDown], BB_TRUE
		cmp	al, CPS_PEN_OFF
		jne	done			; if not PEN_OFF, do nothing
		mov	ds:[hardIconDown], BB_FALSE
			
		mov	di, offset hardIconTableEnd
tableLoop:
		sub	di, (size HardIcon)
		cmp	cx, cs:[di].HI_leftEdge
		jl	tableLoop

		; Found the correct hard icon - send off the message
		;
		mov	ax, MSG_META_NOTIFY
		mov	bx, ds:[mouseOutputHandle]
		mov	cx, cs:[di].HI_dataCX
		mov	dx, cs:[di].HI_dataDX
		mov	bp, cs:[di].HI_dataBP
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	discontinue
MouseDevHandler	endp

hardIconTable	HardIcon < \
			8000h,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_HARD_ICON_BAR_FUNCTION,
			HIBF_TOGGLE_EXPRESS_MENU
		>, < \
			24,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			0
		>, < \
			50,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			1
		>, < \
			76,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			2
		>, < \
			102,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			3
		>, < \
			128,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			4
		>, < \
			154,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_STARTUP_INDEXED_APP,
			5
		>, < \
			180,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_HARD_ICON_BAR_FUNCTION,
			HIBF_TOGGLE_MENU_BAR
		>, < \
			206,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_HARD_ICON_BAR_FUNCTION,
			HIBF_DISPLAY_FLOATING_KEYBOARD
		>, < \
			232,
			MANUFACTURER_ID_GEOWORKS,
			GWNT_HARD_ICON_BAR_FUNCTION,
			HIBF_DISPLAY_HELP
		>
hardIconTableEnd	label	byte
ForceRef		hardIconTable


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the calibration points for the current device

CALLED BY:	MouseStrategy

PASS:		DX:SI	= Buffer holding up to MAX_NUM_CALIBRATION_POINTS
			  calibration points

RETURN:		DX:SI	= Buffer filled with calibration points
		CX	= # of calibration points

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseGetCalibrationPoints	proc	near
		uses	ax
		.enter

		; Call BIOS, asking for points
		;
		mov	ax, CPF_GET_CALIBRATION_POINTS or (CASIO_FUNCTION shl 8)
		call	CalibrationBIOSCommon
		mov	cx, 4			; 4 points were returned

		.leave
		ret
MouseGetCalibrationPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the calibration points for the current device

CALLED BY:	MouseStrategy

PASS:		DX:SI	= Buffer holding up the calibration points
		CX	= # of calibration points

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseSetCalibrationPoints	proc	near
		uses	ax, bx
		.enter

		; Call BIOS, asking for points
		;
		mov	ax, CPF_SET_CALIBRATION_RESULTS or \
			    (CASIO_FUNCTION shl 8)
		mov	bh, CPC_SET_CALIBRATION
		call	CalibrationBIOSCommon
		call	WriteCalibrationDataToIni

		.leave
		ret
MouseSetCalibrationPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRawCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current calibrated & non-calibrated coordinate

CALLED BY:	MouseStrategy

PASS:		Nothing

RETURN:		(AX,BX)	= raw (uncalibrated) coordinate
		(CX,DX)	= adjusted (calibrated) coordinate
		Carry	= Clear (point returned)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseGetRawCoordinate	proc	near
		uses	di, si
		.enter

		; Lock down BIOS, make the call, and return
		;
		call	SysLockBIOS
		CallCasio	CPF_READ_PEN_STATUS
		tst	bl
		jz	penOff
		movdw	axbx, sidi		; raw Point => (AX, BX)
done:
		call	SysUnlockBIOS
		clc				; point always returned

		.leave
		ret

		; Pen is off the screen - return the last coordinate
penOff:
		mov	ax, ds:[lastPosRaw].P_x
		mov	bx, ds:[lastPosRaw].P_y
		mov	cx, ds:[lastPosAdj].P_x
		mov	dx, ds:[lastPosAdj].P_y
		jmp	done
MouseGetRawCoordinate	endp

MouseSendEventsFar	proc	far
		call	MouseSendEvents
		ret
MouseSendEventsFar	endp

Resident 	ends

end
