COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Alps Digitizer
FILE:		alpspen.asm

AUTHOR:		Jim Guggemos, Dec  6, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	12/ 6/94   	Initial revision


DESCRIPTION:
	Device-dependent support for Alps Digitizer
		

	$Id: alpspen.asm,v 1.1 97/04/18 11:48:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		alpspenConstant.def		; Our constants

include		mouseCommon.asm			; Include common defns/code.
include		graphics.def

include		alpspenStructure.def		; Structures and enumerations
include		alpspenMacro.def		; Macros
include 	alpspenVariables.def		; idata, udata, & strings stuff.

; Use the power driver to turn on and off the digitizer.
;
UseDriver	Internal/powerDr.def

; I'm tired of pretending.. let us shift bits with a constant other than one!
.186

Resident segment resource


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

	The data format is specified in the DEF constants above, as 
	extracted from the documentation.

	Return with carry clear.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevInit	proc	far	uses ax, bx, cx, dx, si, di, ds, bp
	.enter

EC <	ASSERT_SEG_IS_DGROUP	ds					>
EC <	ASSERT_SEG_IS_DGROUP	es					>

	; Get calibration information from the ini file, or it will leave
	; the defaults in the variables as initialized.  Also, calculate
	; some extra information for the hard icon detection.
	;
	call	MouseReadCalibrationFromIniFile
	call	CalculateHardIconSpan

EC <	ASSERT_SEG_IS_DGROUP	ds					>
EC <	ASSERT_SEG_IS_DGROUP	es					>

	; Ensure that the digitizer is stopped before we enable interrupts..
	; We don't want any data until we're ready.
	;
	ALPS_STOP_DATA
	
	mov	di, offset oldVector
	mov	bx, segment MouseDevHandler
	mov	cx, offset MouseDevHandler
	mov	ax, DIGITIZER_IRQ_LEVEL
	call	SysCatchDeviceInterrupt

	;
	; Enable the controller hardware to receive necessary interrupt
	;

        mov     dx, IC1_MASKPORT        ; Assume controller 1
        in      al, dx                  ; Fetch current mask
        and     al, not DIGITIZER_IRQ_MASK	; clear necessary bit
	out     dx, al                  ; Store new mask

    	; SETTING UP THE ALPS DIGITIZER:
	;
	;  AlpsInitialize resets the digitizer and sets some of the
	;  parameters.  We need to then start the data flow and then read
	;  the data back before interrupts start.  We won't get the first
	;  interrupt if we don't read back the data after sending the start
	;  command.

	call	AlpsInitialize		; Set up the digitizer
	
	; Start the data flow
	ALPS_START_DATA
	
	call	AlpsReadRawData		; Need to call this to be sure we get
					; valid data
	
	;
	; Register with the power driver so we can stop the digitizer before
	; we suspend and restart it after we wake up
	;
	call	AlpsRegisterPowerDriver
	
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
	
EC <	ASSERT_SEG_IS_DGROUP	ds					>

	; Tell the power driver to ignore us, we're leaving!
	;
	call	AlpsUnregisterPowerDriver
	
	; Stop the device from sending data
	ALPS_STOP_DATA
	
	;
	; Close down the port...if it was ever opened, that is.
	;
	segmov	es, ds
	mov	di, offset oldVector
	mov	ax, DIGITIZER_IRQ_LEVEL
	call	SysResetDeviceInterrupt
	
	;
	; Disable the controller hardware
	;

        mov     dx, IC1_MASKPORT        ; Assume controller 1
        in      al, dx                  ; Fetch current mask
        or	al, DIGITIZER_IRQ_MASK	; set necessary bit
	out     dx, al                  ; Store new mask

	ret
MouseDevExit	endp

categoryString	char	"mouse", 0
keyString	char	"calibration", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseReadCalibrationFromIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the calibration info from the ini file and stores
		in the dgroup variables.  If the data does not exist in the
		ini file OR the data is not valid (wrong length), the
		values in dgroup will NOT be destroyed.

CALLED BY:	MouseDevInit
		MouseResetCalibration

PASS:		Nothing

RETURN:		carry	- set if values were valid
			  clear if values were hosed or didn't exist

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseReadCalibrationFromIniFile	proc	near
	uses	ds, di, bp, es, di
	.enter
	
	; Read the data from the .INI file
	;
	mov	bp, 100
	sub	sp, bp
	segmov	es, ss
	mov	di, sp
	segmov	ds, cs, cx
	mov	si, offset categoryString
	mov	dx, offset keyString
	call	InitFileReadData
	cmc					; toggle return code from
	jnc	done				; InitFileReadData because
						; it is backwards from our
						; return code.
	
	cmp	cx, size AlpsCalibrationInfo
EC <	WARNING_NE    ALPS_PEN_READ_GARBAGE_CALIBRATION_INFO_FROM_INI_FILE >
	clc					; return carry clear (error)
	jne	done				; if size was incorrect
	
	; Successful read from ini file.. store the info in the dgroup
	; variables.
	;
	segmov	ds, es
	mov	si, di
	mov	di, segment dgroup
	mov	es, di
	mov	di, offset calibration
	rep movsb
	
	stc
	
done:
	; Preserve the flags around the stack restoration.
	;
	lahf
	add	sp, 100
	sahf
	
	.leave
	ret
MouseReadCalibrationFromIniFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseWriteCalibrationToIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the information from dgroup into the ini file.

CALLED BY:	MouseStopCalibration

PASS:		Nothing (Gets values from dgroup)

RETURN:		Nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		Clears the "calibration changed" bit.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseWriteCalibrationToIniFile	proc	near
	uses	cx, dx, es, di, ds, si, bp
	.enter
	
	mov	di, segment dgroup
	mov	es, di
	
	; Since we are now writing the stuff to the ini file, clear the
	; calibration changed bit.
	;
	andnf	es:[condFlags], not mask AF_CALIBRATION_CHANGED
	
	mov	di, offset calibration
	segmov	ds, cs, cx
	mov	si, offset categoryString
	mov	dx, offset keyString
	mov	bp, size AlpsCalibrationInfo
	call	InitFileWriteData
	call	InitFileCommit
	
	.leave
	ret
MouseWriteCalibrationToIniFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseResetCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to reset calibration from the ini file.  If none
		exists there, it restores the built-in default values.

CALLED BY:	MouseSetCalibrationPoints

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseResetCalibration	proc	near
	uses	ax,bx,cx,dx
	.enter
	
	; Try to read from ini file.
	;
	call	MouseReadCalibrationFromIniFile
	jc	okayDokey
	
	; No data stored in ini file, use built-in defaults.
	;
	mov	ds:[calibration].ACI_offset.P_x, DEFAULT_OFFSET_X
	mov	ds:[calibration].ACI_offset.P_y, DEFAULT_OFFSET_Y
	mov	ds:[calibration].ACI_scale.P_x, DEFAULT_SCALE_X
	mov	ds:[calibration].ACI_scale.P_y, DEFAULT_SCALE_Y
	
okayDokey:
	; Clear the calibration changed bit since we obviously have reset
	; this to the last saved state.
	;
	andnf	ds:[condFlags], not mask AF_CALIBRATION_CHANGED
	
	.leave
	ret
MouseResetCalibration	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the calibration points

CALLED BY:	MouseStrategy (DR_MOUSE_GET_CALIBRATION_POINTS)

PASS:		dx:si	= buffer holding up to MAX_NUM_CALIBRATION_POINTS

RETURN:		dx:si	= buffer filled with calibration points
		cx	= # of points

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
calibrationPointList	AlpsCalibrationPointList	\
	< < CALIBRATION_UL_X, CALIBRATION_UL_Y >, \
	  < CALIBRATION_LL_X, CALIBRATION_LL_Y >, \
	  < CALIBRATION_UR_X, CALIBRATION_UR_Y >, \
	  < CALIBRATION_LR_X, CALIBRATION_LR_Y > >
	
MouseGetCalibrationPoints	proc	near
	uses	si,di,es,ds
	.enter
	mov	es, dx					; es:di = destination
	mov	di, si
	
	segmov	ds, cs, si				; ds:si = source
	mov	si, offset calibrationPointList
	
	mov	cx, (size calibrationPointList)/2	; cx = size words
	rep	movsw
	
	; Return number of points
	mov	cx, (size calibrationPointList)/(size Point)

	.leave
	ret
MouseGetCalibrationPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the calibration points for the digitizer.  Calculates
		the scale and offset calibration information.  Writes these
		changes to the ini file.

CALLED BY:	MouseStrategy (DR_MOUSE_SET_CALIBRATION_POINTS)

PASS:		dx:si	= buffer holding points
			 	(AlpsCalibrationPointList)
		cx	= # of calibration points
		ds = es = dgroup (Set by MouseStrategy)
		
		(If cx = 0, then the calibration information is reset from
		 last state; either the ini file or the built-in defaults.
		 dx:si is unused in this case.)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	
		Writes to ini file

PSEUDO CODE/STRATEGY:

    (Taken from bullet pen digitizer driver.. thanks for the comments, Todd!)
    
    The passed coords are in digitizer units, of course.
    
	Determine scale factors:
	 NB: For this digitizer driver, the scale is in the following units:
		((Display Units) / (Digitizer Units)) * 2048
	
	    X Scale:
	    
		AverageLCoord == Average UL, LL x-coords
		AverageRCoord == Average UR, LR x-coords
		
		XRange = AverageRCoord - AverageLCoord
		XScale = (SCREEN_MAX_X-CALIBRATION_X_INSET*2)*2048 / XRange
	    
	    Y Scale:
	    
		AverageUCoord == Average UL, UR y-coords
		AverageLCoord == Average LL, LR y-coords
		
		YRange = AverageLCoord - AverageUCoord
		YScale = (SCREEN_MAX_Y-CALIBRATION_Y_INSET*2)*2048 / YRange
	
	Next, determine offset:
	
	    X Offset:
	    	
		DigitizerXInset = (CALIBRATION_UL_X * 2048) / XScale
		XOffset = UL-x-coordinate - DigitizerXInset
		
	    Y Offset:
		
		DigitizerYInset = (CALIBRATION_UL_Y * 2048) / YScale
		YOffset = UL-y-coordinate - DigitizerYInset

    With any luck, this should work!
    

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetCalibrationPoints	proc	near
	uses	ax,bx,cx,dx,si,di,bp

tempXScale	local	word
tempYScale	local	word
	.enter
	
	; If CX=0, then reset the calibration to the last stored calibration
	; in the ini file or to the built-in defaults.
	;
	tst	cx
	jnz	noReset
	
	; Read the defaults back from the ini file or use built-in defaults.
	;
	call	MouseResetCalibration
	jmp	done

noReset:
	; If we don't have the number of points we expect, then blow this
	; whole thing off.. in EC, give an error, otherwise just don't do
	; anything since the driver API doesn't specify an error return
	; value.
	;
	cmp	cx, (size calibrationPointList)/(size Point)
EC <	ERROR_NE	ALPS_PEN_INCORRECT_NUMBER_OF_POINTS_IN_CALIBRATION >
NEC <	LONG jne	done						   >

	mov	es, dx				; es:si = buffer
	
    ;
    ; (1) Calculate X Scale
    ;
    
	; ax = AverageLCoord
	mov	ax, es:[si].ACPL_UL.P_x
	add	ax, es:[si].ACPL_LL.P_x
	shr	ax, 1
	
	; bx = AverageRCoord
	mov	bx, es:[si].ACPL_UR.P_x
	add	bx, es:[si].ACPL_LR.P_x
	shr	bx, 1
	
	; bx = XRange (in digitizer coordinates, you know)
	sub	bx, ax
	
	; Sanity check: DigitizerMaxX / 4 <= XRange < DigitizerMaxX
	;   Prevent overflow, divide by zero, etc, etc..
	;
	cmp	bx, DIGITIZER_MAX_X/4
EC <	WARNING_L 	ALPS_PEN_CALIBRATION_POINTS_WAY_OUT_OF_RANGE	>
   LONG	jl	done
	cmp	bx, DIGITIZER_MAX_X
EC <	WARNING_GE 	ALPS_PEN_CALIBRATION_POINTS_WAY_OUT_OF_RANGE	>
   LONG	jge	done
	
	mov	ax, SCREEN_MAX_X - (CALIBRATION_X_INSET * 2)
	mov	dx, ax
	shl	ax, 11
	shr	dx, 5				; dx:ax = dpy width * 2048
	
	div	bx				; divide by XRange
	
	; Store XScale in temp variable
	mov	ss:[tempXScale], ax
	
    ;
    ; (2) Calculate Y Scale
    ;
    
	; ax = AverageUCoord
	mov	ax, es:[si].ACPL_UL.P_y
	add	ax, es:[si].ACPL_UR.P_y
	shr	ax, 1
	
	; bx = AverageLCoord (L as in lower, that is)
	mov	bx, es:[si].ACPL_LL.P_y
	add	bx, es:[si].ACPL_LR.P_y
	shr	bx, 1
	
	; bx = YRange (in digitizer coordinates, you know)
	sub	bx, ax
	
	; Sanity check: DigitizerMaxY / 4 <= YRange < DigitizerYaxX
	;   Prevent overflow, divide by zero, etc, etc..
	;
	cmp	bx, DIGITIZER_MAX_Y/4
EC <	WARNING_L 	ALPS_PEN_CALIBRATION_POINTS_WAY_OUT_OF_RANGE	>
	jl	done
	cmp	bx, DIGITIZER_MAX_Y
EC <	WARNING_GE 	ALPS_PEN_CALIBRATION_POINTS_WAY_OUT_OF_RANGE	>
	jge	done
	
	mov	ax, SCREEN_MAX_Y - (CALIBRATION_Y_INSET * 2)
	mov	dx, ax
	shl	ax, 11
	shr	dx, 5				; dx:ax = dpy height * 2048
	
	div	bx				; divide by YRange
	
	; Store YScale in temp variable
	mov	ss:[tempYScale], ax
    
    ;
    ; (3) Calculate X Offset
    ;
    	mov	ax, CALIBRATION_UL_X
	mov	dx, ax
	shl	ax, 11
	shr	dx, 5				; dx:ax = UL_X * 2048
	div	ss:[tempXScale]			; ax = DigitizerXInset
	mov	bx, es:[si].ACPL_UL.P_x
	sub	bx, ax				; bx = XOffset
    
    ;
    ; (4) Calculate Y Offset
    ;
    	mov	ax, CALIBRATION_UL_Y
	mov	dx, ax
	shl	ax, 11
	shr	dx, 5				; dx:ax = UL_Y * 2048
	div	ss:[tempYScale]			; ax = DigitizerYInset
	neg	ax
	add	ax, es:[si].ACPL_UL.P_y		; ax = YOffset
    	
    ;
    ; (5) Store calibration info in dgroup
    ;
    	mov	ds:[calibration].ACI_offset.P_x, bx
	mov	ds:[calibration].ACI_offset.P_y, ax
	mov	ax, ss:[tempXScale]
	mov	ds:[calibration].ACI_scale.P_x, ax
	mov	ax, ss:[tempYScale]
	mov	ds:[calibration].ACI_scale.P_y, ax
	
    ;
    ; (6) Mark the calibration data as changed so it will be written out
    ;     to the ini file when we stop calibration mode.
    ;
	ornf	ds:[condFlags], mask AF_CALIBRATION_CHANGED
    	
done:
	.leave
	ret
MouseSetCalibrationPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStartCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts calibration.  Basically this mode disables hard icons
		and stores the mouse points in dgroup to be returned by
		MouseGetRawCoordinates.

CALLED BY:	MouseStrategy (DR_MOUSE_START_CALIBRATION)

PASS:		ds = es = dgroup (Set by MouseStrategy)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStartCalibration	proc	near
	.enter
	
	; Turn on calibration mode
	ornf	ds:[condFlags], mask AF_CALIBRATING
	
	; Clear the calibration changed bit since it hasn't yet changed.
	andnf	ds:[condFlags], not mask AF_CALIBRATION_CHANGED

	.leave
	ret
MouseStartCalibration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStopCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops calibration mode.  Returns you to your regularly
		scheduled program.  Also writes out calibration data to ini
		file if it has changed.

CALLED BY:	MouseStrategy (DR_MOUSE_STOP_CALIBRATION)

PASS:		ds = es = dgroup (Set by MouseStrategy)

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStopCalibration	proc	near
	.enter
	
	andnf	ds:[condFlags], not mask AF_CALIBRATING
	
	; If the calibration information has changed, then write out the new
	; data to the ini file for "permanent storage".
	;
	test	ds:[condFlags], mask AF_CALIBRATION_CHANGED
	jz	done
	
	; Write out the new calibration data to ini file.  This clears the
	; "calibration changed" bit.
	;
	call	MouseWriteCalibrationToIniFile

done:
	.leave
	ret
MouseStopCalibration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRawCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the raw coordinates for calibration

CALLED BY:	MouseStrategy (DR_MOUSE_GET_RAW_COORDINATE)

PASS:		ds = es = dgroup (Set by MouseStrategy)

RETURN:		carry:
    	    	    set	  ==> No point returned
		     -- or --
		    clear ==> Point returned in:
		      (ax, bx)	= raw (uncalibrated) coordinates
		      (cx, dx)	= adjusted (calibrated) coordinates
				  (unfortunately, if they are "off-screen",
				   they are truncated).

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If not calibration, no point will be returned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetRawCoordinate	proc	near
	.enter
	
	; Are we calibration? If not, set carry and return -- point isn't
	; valid.
	;
	test	ds:[condFlags], mask AF_CALIBRATING
	stc
	jz	done
	
	mov	ax, ds:[lastRawPoint].P_x
	mov	bx, ds:[lastRawPoint].P_y
	
	mov	cx, ds:[lastDpyPoint].P_x
	mov	dx, ds:[lastDpyPoint].P_y
	
	clc
done:
	.leave
	ret
MouseGetRawCoordinate	endp


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

SYNOPSIS:	Handle the digitizer interrupt

CALLED BY:	Digitizer interrupt (currently IRQ1)
PASS:		Unknown
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/28/95		The version you see here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	; Prevent thread switch for the duration of this routine.
	;
	call	SysEnterInterrupt

	cld

	mov	dx, segment dgroup
	mov	ds, dx

if ERROR_CHECK
	; Check to make sure that:
	;   1) The 8259 has this IRQ marked "IN SERVICE"
	;   2) That we are not entering this routine while in the process
	;      of handling a previous interrupt.
	;
	push	ax
	
	mov	al, IC_READ_ISR
	out	IC1_CMDPORT, al
	jmp	$+2			; Courteous delay
	jmp	$+2
	in	al, IC1_CMDPORT
	test	al, DIGITIZER_IRQ_MASK
	ERROR_Z	ALPS_PEN_EXPECTED_IRQ_TO_BE_MARKED_IN_SERVICE
	
	tst	ds:[reentryToHandler]
	ERROR_NZ	ALPS_PEN_RECEIVED_INT_WHILE_PROCESSING_CURRENT_INT
	inc	ds:[reentryToHandler]

	pop	ax
endif ;ERROR_CHECK
	
	INT_ON

	; If the digitizer is stopped, or in calibrate mode or resetting, then
	; this is garbage.
	;
	mov	dx, DIGITIZER_STATUS
	in	al, dx
	test	al, mask APS_STOP or mask APS_CALIBRATE_MODE or mask APS_RESET
	jnz	exit

	; Load the information from the I/O registers.
	;
    	call	AlpsReadRawData
	
	; Calculate the penCondition variable.  Temporarily use ch to hold
	; the value.
	;
	clr	ch			; Assume condition is pen up
	
	test	cl, mask ASI_PEN_DOWN
	jz	storePenCondition	; it is.. store pen up (0) in dgroup
	
	mov	ch, ds:[penCondition]	; otherwise, get current value
	inc	ch			; and increment it
	cmp	ch, ACPC_PEN_STILL_DOWN	; If it is greater than PEN_STILL_DOWN,
	jle	storePenCondition	; then don't set it, otherwise store
					; the new value.
	
penConditionHandled:
	; Test to see if we the first pen down started in the hard icon bar.
	; If so, then send all events to the hard icon handler part of this
	; function.
	;
	test	ds:[condFlags], mask AF_START_IN_HARD_ICON_BAR
	jnz	handlingHardIconEvent
	
	; Convert raw coordinates to display coordinates.
	; Will return:
	;  AX, BX = Raw coordinates X, Y (Preserved)
	;  DX, BP = Display coordinates X, Y (truncated to dpy min/max)
	;  Carry  = Clear if on-screen, set if off-screen.
	;
	call	AlpsConvertRawToDisplay	; returns display coords in AX,BX
	pushf				; store carry flag for later
	
	; If we are calibrating, then stash away the values for
	; MouseGetRawCoordinate.  Otherwise, there's no point in storing
	; these values.
	;
	test	ds:[condFlags], mask AF_CALIBRATING
	jnz	stashAwayValues
	
afterStash:

	popf				; Carry flag from AlpsConvertRaw..
	
	jc	checkHardIcons		; Not on screen, check the hard icons
	
hardIconsRejected:
	; The pen is assumed to be the left button.
	; Check if the pen is DOWN or UP.
	;
	mov	bh, not mask SB_LEFT_DOWN	; assume DOWN
	test	cl, mask ASI_PEN_DOWN
	jnz	sendMouseEvent	
	mov	bh, MouseButtonBits<1,1,1,1>	; Nope, it was UP
	
sendMouseEvent:
	mov	cx, dx			; cx = X display coord
	mov	dx, bp			; dx = Y display coord
	
	; Send the event
	; CX = X, DX = Y, BH = MouseButtonBits
	call	MouseSendEvents

exit:					; <<-- EXIT POINT
	INT_OFF
	
if ERROR_CHECK
	dec	ds:[reentryToHandler]
	tst	ds:[reentryToHandler]
	ERROR_NZ	ALPS_PEN_RECEIVED_INT_WHILE_PROCESSING_CURRENT_INT
endif ;ERROR_CHECK
	
	mov	al, IC_GENEOI		;send the end of interrupt.
	mov	dx, IC1_CMDPORT
	out	dx, al

	call	SysExitInterrupt

	.leave
	iret

	; Called to store the current pen condition.
	; Pass:	ch = AlpsCurrentPenCondition
	; Return: nothing
	; Destroys: nothing
	;
storePenCondition:
	mov	ds:[penCondition], ch
	jmp	penConditionHandled

	; Called to store away data for MouseGetRawCoordinate
	; Pass:	ax = Raw X, bx = Raw Y
	;	dx = Dpy X, bp = Dpy Y
	; Return: nothing
	; Destroys: nothing
	;
stashAwayValues:
	movdw	ds:[lastRawPoint], bxax
	movdw	ds:[lastDpyPoint], bpdx
	jmp	afterStash

    	; This is reached whenever the pen moves off-screen.  So, we need to
	; decide if it is valid for a hard icon event.  It can only be valid
	; if:
	;	1) It is a "first pen down" event, we are not calibrating and
	;	   the pen press's X coordinate is less than the X Offset.
	;	2) If the first pen down event occurred in the hard icon
	;	   area, then every event after that will be sent to
	;	   handlingHardIconEvent.
	;
checkHardIcons:
	; If first pen down, we need to see if we can select a hard icon.
	;
	cmp	ds:[penCondition], ACPC_FIRST_PEN_DOWN
	je	checkHardFirstPenDown
	
	; Not first pen down.  We know that we don't want this event for
	; hard icons because if we were in "hard icon" mode, we would have
	; jumped to handlingHardIconEvent and skipped this code.  So, just
	; return this as a mouse event.
	; Since the routine that converts raw to dpy coords will truncate
	; the values at display min/max, we can safely send it off as a normal
	; mouse event.
	;
	jmp	hardIconsRejected
	
	
	; NOTE that you should only depend on AX, BX being the raw coordinates
	; from this point forward (DX, BP will not be set).
	;	
handlingHardIconEvent:
	; If we started in the hard icon bar and this is not a pen up event,
	; then we just ignore it because we are waiting for the user to let
	; up on the pen.
	cmp	ds:[penCondition], ACPC_PEN_UP
	jne	exit
	
	; Well then, send the hard icon event.
	call	SendHardIconEvent

	; Clear the hard icon processing bit.
	and	ds:[condFlags], not mask AF_START_IN_HARD_ICON_BAR
	
	; And... we're done
	jmp	exit


checkHardFirstPenDown:
	; If we are calibrating, no hard icons allowed.
	test	ds:[condFlags], mask AF_CALIBRATING
	jnz	hardIconsRejected
	
	; If not in the hard icon area, this is just some random off-screen
	; event.. forward to the mouse event system.
	call	PenInHardIconArea
	jnc	hardIconsRejected
	
	; Okay.. we will be handling a hard icon event.  Set the bit to
	; indicate that condition.
	or	ds:[condFlags], mask AF_START_IN_HARD_ICON_BAR
	jmp	exit
	

MouseDevHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PenInHardIconArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests digitizer coordinate to see if it falls within the
		hard icon area.

CALLED BY:	MouseDevHandler
		SendHardIconEvent

PASS:		ds	= dgroup
		ax, bx	= raw digitizer coordinates (X, Y)

RETURN:		carry	= clear if point is NOT in hard icon area
			  set if point is in hard icon area

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PenInHardIconArea	proc	near
	.enter
	
EC <	ASSERT_SEG_IS_DGROUP	ds					>
	
	; X < Xoffset
	cmp	ax, ds:[calibration].ACI_offset.P_x
	jge	notInHardIconArea
	
	; Y >= Yoffset
	cmp	bx, ds:[calibration].ACI_offset.P_y
	jl	notInHardIconArea
	
	; Y < Ymax
	cmp	bx, ds:[digitizerMaxY]
	jge	notInHardIconArea
	
	; We are in the hard icon area..
	stc
	
done:
	.leave
	ret
	
notInHardIconArea:
	clc
	jmp	done
	
PenInHardIconArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendHardIconEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the appropriate hard icon event if the digitizer
		coordinates passed were in the hard icon area.

CALLED BY:	MouseDevHandler

PASS:		ds	= dgroup
		ax, bx	= raw digitizer coordinates (X, Y)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendHardIconEvent	proc	near
	uses	si, di, bp
	.enter

EC <	ASSERT_SEG_IS_DGROUP	ds					>
	
	; Make sure we are still in the hard icon area
	call	PenInHardIconArea
	jnc	done				; nope.. no hard icon event
	
	; Determine which hard icon the user clicked on.
	mov	cx, NUMBER_HARD_ICONS	; counter
	sub	bx, ds:[calibration].ACI_offset.P_y
	mov	di, offset hardIconTable
	mov	si, ds:[digitizerHardIconSpan]
	
tryNextOne:
	sub	bx, si				; subtract one hard icon span
	js	gotIt				; if we went negative, we've
						; got it
	add	di, size AlpsHardIcon		; otherwise, move to next
	loop	tryNextOne			; hard icon and continue
	
	; Hmm.. out of icon range.  If we get here, it is because of
	; round-off error in the calculation of digitizerHardIconSpan.  So,
	; since we are the bottom of the screen, just assume the user
	; clicked on the last hard icon.  (We know we are in the range of
	; the display since that was checked at the very beginning.)
	;
	sub	di, size AlpsHardIcon

gotIt:
	; If dataCX == 0ffffh then this is an empty icon.  do nothing.
	cmp	cs:[di].AHI_dataCX, 0ffffh
	je	done				; NOP icon
	
	; Dispatch the hard icon event
	mov	ax, MSG_META_NOTIFY
	mov	bx, ds:[mouseOutputHandle]
	mov	cx, cs:[di].AHI_dataCX
	mov	dx, cs:[di].AHI_dataDX
	mov	bp, cs:[di].AHI_dataBP
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	
done:
	.leave
	ret
SendHardIconEvent	endp

;
; Hard icon table.  But wasn't that obvious?
;
hardIconTable	AlpsHardIcon \
	< \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_STARTUP_INDEXED_APP,
		0
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_STARTUP_INDEXED_APP,
		1
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_STARTUP_INDEXED_APP,
		2
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_STARTUP_INDEXED_APP,
		3
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_HARD_ICON_BAR_FUNCTION,
		HIBF_DISPLAY_FLOATING_KEYBOARD
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_HARD_ICON_BAR_FUNCTION,
		HIBF_DISPLAY_HELP
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_STARTUP_INDEXED_APP,
		4
	>, < \
		MANUFACTURER_ID_GEOWORKS,
		GWNT_HARD_ICON_BAR_FUNCTION,
		HIBF_TOGGLE_EXPRESS_MENU
	>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateHardIconSpan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the digitizerHardIconSpan and digitizerMaxY
		values.

CALLED BY:	MouseDevInit
		MouseSetCalibrationPoints

PASS:		ds	= dgroup

RETURN:		nothing.
		digitizerHardIconSpan, digitizerMaxY set.

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateHardIconSpan	proc	near
	.enter

EC <	ASSERT_SEG_IS_DGROUP	ds					>
	
	; Calculate the maximum Y value (in digitizer coordinates) to be
	; "on-screen" and the Y span (length in digitizer coordinates of the
	; valid "on-screen" region) of each hard icon.
	;
	; TotalYSpan = (ScreenMaxY * 2048)/ACI_scale_Y
	; MaxY = TotalYSpan + Offset_Y
	; HardIconSpan = TotalYSpan / NumHardIcons
	;
	mov	ax, SCREEN_MAX_Y
	mov	dx, ax
	shl	ax, 11
	shr	dx, 5					; dx:ax = ax*2048
	mov	cx, ds:[calibration].ACI_scale.P_y
	div	cx					; ax = result (span)
	mov	bx, ax					; save span in bx
	
	; Calculate max Y and store it
	add	ax, ds:[calibration].ACI_offset.P_y
	mov	ds:[digitizerMaxY], ax
	
	; Calculate hard icon span
	mov_tr	ax, bx
	clr	dx
	mov	cx, NUMBER_HARD_ICONS
	div	cx
	mov	ds:[digitizerHardIconSpan], ax
	
	.leave
	ret
CalculateHardIconSpan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsReadRawData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the I/O addresses for the Alps digitizer and returns
		the raw X,Y position and the switch status.  These ports
		needs to be read for the next point to be returned.

CALLED BY:	Internal

PASS:		nothing

RETURN:		ax	= X (0-1023)
		bx	= Y (0-1023)
		cl	= AlpsSwitchInfo

DESTROYED:	ch, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsReadRawData	proc	near
	.enter
	clr	ax, bx, cx
	
	mov	dx, DIGITIZER_X_HIGH
	in	al, dx
	mov	ch, al
	and	ch, 07fh			; mask off bit 7 which is
						; always set for high X byte
	
	shr	cx, 1
	mov	dx, DIGITIZER_X_LOW
	in	al, dx
	or	cl, al				; cx = X
	
	mov	dx, DIGITIZER_Y_HIGH
	in	al, dx
	mov	bh, al
	shr	bx, 1
	mov	dx, DIGITIZER_Y_LOW
	in	al, dx
	or	bl, al				; bx = Y
	
	mov	dx, DIGITIZER_SWITCH_INFO
	in	al, dx
	xchg	ax, cx				; ax = X, cl = switch info
	
	
	.leave
	ret
AlpsReadRawData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsConvertRawToDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts Alps raw digitizer coords to display coords

CALLED BY:	

PASS:		ax	= X raw coord
		bx	= Y raw coord 
		ds	= DGROUP

RETURN:		Carry:	Clear if coordinates are ON-SCREEN.
		Carry:	Set if coordinates are OFF-SCREEN.
		    
		dx	= X display coord
		bp	= Y display coord
		
		If either coordinate is off-screen, the display coordinate
		is truncated to the max or min value.

DESTROYED:	None

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsConvertRawToDisplay	proc	near
	uses	ax, bx, cx, si, di
	.enter

EC <	ASSERT_SEG_IS_DGROUP	ds					>
	
	; We need to play register shuffle here since we are doing math and
	; shifts and they need specific registers.. sigh.. so anyway, we
	; will use:
	;    DI = Value to be returned as the X Display Value
	;    SI = Value to be returned as the Y Display Value
	;    BP = Zero if on screen, between 0fffeh and 0ffffh if off screen
	;
	; Initially clear bp -- assume we are on screen.
	; Initially clear di in case the value is off screen.
	clr	di, bp
	sub	ax, ds:[calibration].ACI_offset.P_x	; subtract off inset
	js	notInScreenRangeX		; uh oh, went negative..
	
	mov	cx, ds:[calibration].ACI_scale.P_x
	mul	cx				; dx:ax = result * 2048
	
	; Divide by 2048
	shr	ax, 11				; 2048 = 2^11
	shl	dx, 5				; clears low bits
	or	ax, dx				; stick in top five bits
						; from high word
	; AX = display coord X
	mov	di, SCREEN_MAX_X-1		; set di to max in case
						; out of bounds
	cmp	ax, di				; upper bounds check on X
	jg	notInScreenRangeX
	mov	di, ax				; store calc'ed value in di
	
returnFromOutOfBoundsX:
	xchg	ax, bx				; store dpy X in bx, ax=raw Y
	
	; Do Y coord (ax = Y coord now)
	clr	si				; assume Y is off screen
	sub	ax, ds:[calibration].ACI_offset.P_y	; subtract off inset
	js	notInScreenRangeY		; uh oh, went negative..
	
	mov	cx, ds:[calibration].ACI_scale.P_y
	mul	cx				; dx:ax = result * 2048
	
	; Divide by 2048
	shr	ax, 11				; 2048 = 2^11
	shl	dx, 5				; clears low bits
	or	ax, dx				; stick in top five bits
						; from high word
	; AX = display coord Y
	mov	si, SCREEN_MAX_Y-1		; set si to max in case out
						; of bounds
	cmp	ax, si				; upper bounds check on Y
	jg	notInScreenRangeY
	mov	si, ax				; store calc'ed value in si
	
returnFromOutOfBoundsY:
	; Set carry flag correctly.  This is done by adding bp to itself.
	; If bp was 0fxxxh, then this will result in a carry, which means it
	; was out of bounds.. otherwise, carry will be clear.  Pretty cool,
	; huh? And I didn't even plan this!
	;
	add	bp, bp
	
	mov	dx, di				; store dpy X in return reg
	mov	bp, si				; store dpy Y in return reg
	
	.leave
	ret

notInScreenRangeX:
	dec	bp
	jmp	returnFromOutOfBoundsX

notInScreenRangeY:
	dec	bp
	jmp	returnFromOutOfBoundsY

AlpsConvertRawToDisplay	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the Alps Digitizer

CALLED BY:	

PASS:		nothing

RETURN:		nothing

DESTROYED:	al, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	12/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsInitialize	proc	near
	.enter
	mov	al, APC_INITIALIZE
	mov	dx, DIGITIZER_COMMAND
	out	dx, al
	
	mov	dx, DIGITIZER_STATUS
	
	; Make sure that the device has completed initialization.
waitForReset:	
	call	AlpsIOPause
	in	al, dx
	test	al, mask APS_RESET
	jnz	waitForReset
	
	call	AlpsIOPause
	mov	al, APC_READ_RATE_100_CPPS
	mov	dx, DIGITIZER_COMMAND
	out	dx, al
	
	call	AlpsIOPause
	mov	al, APC_NOISE_CANCELLATION_2_DOTS
	out	dx, al
	
if ERROR_CHECK
	call	AlpsIOPause
    	mov	dx, DIGITIZER_STATUS
	in	al, dx
	
	cmp	al, AlpsPenStatus <1, 2, APRR_100_CPPS, 0, 0>
	ERROR_NE	ALPS_PEN_INITIALIZATION_FAILURE
endif ;ERROR_CHECK
	
	.leave
	ret
AlpsInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsIOPause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pauses about 38 ticks + 7 for the near call for a total of
		about 45 ticks.

CALLED BY:	Various functions.

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing, flags preserved.

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsIOPause	proc	near
	
	pushf
	push	cx
	mov	cx, 16384
	
loopTop:
	jmp	$+2
	jmp	$+2
	jmp	$+2
	jmp	$+2
	loop	loopTop
	pop	cx
	popf
	
	ret
AlpsIOPause	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsRegisterPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with the power driver, if possible.

CALLED BY:	MouseDevInit

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsRegisterPowerDriver	proc	near
	uses	di
	.enter
	
EC <	ASSERT_SEG_IS_DGROUP	ds					>

	mov	di, DR_POWER_ON_OFF_NOTIFY
	call	AlpsPowerDriverCommon
	jc	done				; error: Not registered
	
	; Keep track of the fact that we are indeed registered.
	;
	ornf	ds:[condFlags], mask AF_REGISTERED_WITH_POWER_DRIVER
	
done:
	.leave
	ret
AlpsRegisterPowerDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsUnregisterPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister with the power driver if we were registered.

CALLED BY:	MouseDevExit

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsUnregisterPowerDriver	proc	near
	uses	di
	.enter

EC <	ASSERT_SEG_IS_DGROUP	ds					>
	
	test	ds:[condFlags], mask AF_REGISTERED_WITH_POWER_DRIVER
	jz	done
	
	andnf	ds:[condFlags], not mask AF_REGISTERED_WITH_POWER_DRIVER
	
	; We full well expect the power driver to unregister us.
	;
	mov	di, DR_POWER_ON_OFF_UNREGISTER
	call	AlpsPowerDriverCommon
EC <	ERROR_C	ALPS_PEN_POWER_DRIVER_FAILED_TO_UNREGISTER_US		>
	
done:
	.leave
	ret
AlpsUnregisterPowerDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsPowerDriverCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register or Unregister with the power driver

CALLED BY:	AlpsRegisterPowerDriver
		AlpsUnregisterPowerDriver

PASS:		di	= DR_POWER_ON_OFF_NOTIFY or
			  DR_POWER_ON_OFF_UNREGISTER

RETURN:		carry	= SET if operation failed.
			  CLEAR if operation successful

DESTROYED:	di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsPowerDriverCommon	proc	near
	uses	ds, si, ax, bx, cx, dx
	.enter
	
	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver		; ax = driver handle
	
	tst	ax
	stc					; No driver? set carry
	jz	noPowerDriver
	
	mov_tr	bx, ax				; bx = driver handle
	
	; bx = driver handle
	; di = power function
	
	call	GeodeInfoDriver
	mov	dx, segment AlpsPowerCallback
	mov	cx, offset AlpsPowerCallback
	call	ds:[si].DIS_strategy
	
	;; PRESERVE FLAGS from the strategy routine!
	
noPowerDriver:
	.leave
	ret
AlpsPowerDriverCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlpsPowerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are powering the device off, then disable the
		digitizer.  Likewise, enable the digitizer if powering on.

CALLED BY:	Power driver

PASS:		ax	= PowerNotifyChange

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlpsPowerCallback	proc	far
	uses	ax, bx, cx, dx
	.enter
	
	; For PNC_POWER_SHUTTING_OFF, stop data from the digitizer.
	; For PNC_POWER_TURNING_ON and PNC_POWER_TURNED_OFF_AND_ON, start
	;	data from the digitizer.
	
	mov	dl, APC_STOP_DATA
	cmp	ax, PNC_POWER_SHUTTING_OFF
	je	sendToDigitizer
	
	mov	dl, APC_START_DATA

sendToDigitizer:
	mov	al, dl
	mov	dx, DIGITIZER_COMMAND
	out	dx, al
	
	call	AlpsReadRawData		; Need to call this to be sure we get
					; valid data
					; Returns/Trashes: ax, bx, cx, dx
	
	.leave
	ret
AlpsPowerCallback	endp


Resident ends
