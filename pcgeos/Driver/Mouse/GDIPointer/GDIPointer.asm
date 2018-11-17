COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		GDIPointer.asm

AUTHOR:		Mary Ann Joy, Apr 18, 1996

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
	configuration constants that control how code is compiled

for now, since only LogiSer and Scripen handle this, we set this to TRUE always
	MOUSE_CANT_SET_RATE	If defined, MouseSetRate will return an
				error, so MouseDevSetRate needn't be defined.
Digitizer's don't handle this.  absgen and kbmouse dosomething funky,
not clear what. Might be able to find some general way of doing this.
	MOUSE_DONT_ACCELERATE	If defined, MouseSendEvents will not apply
				acceleration to the mouse deltas.
hardware independent, so leave as is.  Value set in INI file. At present used
by only GenMouse & KBMouse
	MOUSE_COMBINE_DISCARD	If defined,causes MouseCombineEvent to just
				discard any new event if a IM_PTR_CHANGE event
				is already in the IM's queue.
Not needed anymore.  At present this will tell the caller the driver can not
determine if the device is present.  But want to improve this, to check for
the presence of the library. maybe.
	MOUSE_CANT_TEST_DEVICE	If defined, this file will define a trivial
				MouseTestDevice that tells the caller the
				driver is unable to determine if the device
				is present.	
Set in INI file...  (PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_KIND)
	MOUSE_PTR_FLAGS		PtrFlags that mouse driver wants to
				set when starting up.

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	mjoy		4/18/96   	Initial revision


DESCRIPTION:  Mouse Driver that will work with the GDI library.  All
the hardware dependent routines are handled by the library. mainly reuses
code in mouseCommon.asm.
NOTE: I never really got to test this driver with a device that uses a
digitize. Therefore the functions MouseSetCalibrationPoints and
MouseSetCalibrationPoints didn't get tested.  
		

	$Id: GDIPointer.asm,v 1.1 97/04/18 11:48:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			  SYSTEM DEFINITIONS
;------------------------------------------------------------------------------


_MouseDriver		=	1

;--------------------------------------
;	Include files
;--------------------------------------

include geos.def
include heap.def
include lmem.def		; for extended driver info segment
include geode.def
include resource.def
include ec.def
include driver.def
include initfile.def
include char.def
include timer.def

include input.def
include timedate.def
include sem.def
include	assert.def

include Internal/im.def
include Internal/heapInt.def
include Internal/interrup.def
UseDriver Internal/kbdMap.def
UseDriver Internal/kbdDr.def
DefDriver Internal/mouseDr.def

include	GDIPointer.def
UseLib	gdi.def
	.ioenable	; Tell Esp to let us use I/O instructions
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


mouseNameTable	lptr.char	GDIPointer
		lptr.char	0	; null-terminator

GDIPointer	chunk.char	'GDI Pointer', 0
		;
		;  Is not a serial mouse
		;  Is not a generic mouse
		;  Does not need to be told its interrupt level
		;  Can not be calibrated from within PC/GEOS
mouseInfoTable	MouseExtendedInfo <0,0,0,0>


MouseExtendedInfoSeg	ends
		
ForceRef	mouseExtendedInfo



Resident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse driver strategy routine

CALLED BY:	EXTERNAL

PASS:		di	- DR_MOUSE?  command code.  Operation & other data
		passed, returned depends on command.  Current operations are:


	-----------------------------------------------------------
	PASS:	di	- DR_INIT
		cx:dx	- parameter string

	RETURN: carry clear, for no error

	-----------------------------------------------------------
	PASS:	di	- DR_EXIT

	RETURN: carry clear, for no error


	-----------------------------------------------------------
	PASS:	di	- DR_TEST_DEVICE
		dx:si	- pointer to null-terminated device name string

	RETURN: ax	- DriverPresent code


	-----------------------------------------------------------
	PASS:	di	- DR_SET_DEVICE
		dx:si	- pointer to null-terminated device name string

	RETURN: nothing



	-----------------------------------------------------------
	PASS:	di	- DR_MOUSE_SET_RATE
		cx	- desired report rate (# reports per second)
		
	RETURN:	carry clear, for no error
		cx	- actual report rate for mouse.

	-----------------------------------------------------------
	PASS:	di	- DR_MOUSE_GET_RATES
	
	RETURN:	carry clear, for no error
		es:di	- table of available rates (bytes)
		cx	- length of table

DESTROYED:	Depends on function, though best to assume all registers
		that are not returning a value
		(Segment registers are preserved)
		Only BP, DS, ES are preserved.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/89		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseStrategy	proc	far
		push	bp, ds, es
		mov	bp, dgroup
		mov	ds, bp
		mov	es, bp


		cmp	di, MouseFunction	; Beyond last mouse function?
		ja	MS_Unknown		; yup

		;
		; Call the handler...
		;
		call	ds:mouseHandlers[di]
MS_Done:
		pop	bp, ds, es
		ret

MS_Unknown:
;EC <		ERROR	COMMAND_UNKNOWN					>
;NEC <		stc			; error -- undefined command	>
;NEC <		jmp	MS_Done						>
		stc
		jmp	MS_Done
MouseStrategy	endp

accelThresholdStr	char	"mouseAccelThreshold", 0
accelMultiplierStr	char	"mouseAccelMultiplier", 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the module

CALLED BY:	MouseStrategy

PASS:		es=ds=dgroup

RETURN:		carry	- set on error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Initialize device-independent state.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/28/96		Initial rivision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseInit	proc	near
		uses	bp
		.enter
	;
	; See if we've already been initialized.
	;
		test	ds:mouseStratFlags, MASK MOUSE_ON
		jnz	MIError
		
	; register callback routine
		mov	dx, segment GDIPtrCallback
		mov	si, offset GDIPtrCallback
		call 	GDIPointerRegister
	;
	; check error code
	;
		test	ax, EC_NO_ERROR
		jne	MIError
	
		mov	ax, MOUSE_PTR_FLAGS
		call	ImSetPtrFlags
		mov	ds:[oldPtrFlags], al
	;
	; fetch the table defining the hard icon regions and the hard icon
	; actions and save it away.
	; Also get the number of mouse buttons.
	;	
		sub	sp, size PointerInfo
		mov	bp, sp
		movdw	cxdx, ssbp
	; default number of buttons (1)
		mov	ss:[bp].PI_numButtons, MOUSE_NUM_BUTTONS
		call	GDIPointerInfo
		jc	MIErrorFixSP
		Assert	dgroup, ds
	; It would be smaller to just pop these off the stack than
	; move them to regs first.
		movdw	ds:[hirTable], ss:[bp].PI_hirTable, bx
		movdw	ds:[hiaTable], ss:[bp].PI_hiaTable, dx
		mov	dx, ss:[bp].PI_hiCount
		mov	ds:[hiCount], dx
		mov	dx, ss:[bp].PI_numButtons
		mov	ds:[DriverTable].MDIS_numButtons, dx
		add	sp, size PointerInfo
	;
	; Fetch the process handle of the input manager and squirrel
	; it away.
	;
		call	ImInfoInputProcess
		mov	ds:mouseOutputHandle, bx
	;
	; Make sure mouseButtons is initialized to all UP
	;
		mov	ds:mouseButtons, MouseButtonBits

		mov	si,offset gdiCategory ;init file category string.
		mov	dx, offset cs:[accelThresholdStr]
		call	GDIFetchIniInteger
		jc	afterAccelThreshold
		mov	ds:[mouseAccelThreshold], ax
afterAccelThreshold:
		mov	dx, offset cs:[accelMultiplierStr]
		call	GDIFetchIniInteger
		jc	afterAccelMultiplier
		mov	ds:[mouseAccelMultiplier], ax
afterAccelMultiplier:
	
		;
		; Note that the driver's initialized
		;
		or	ds:mouseStratFlags, MASK MOUSE_ON	; (clc)

		call	GDICalibrate
	.leave
		ret
MIErrorFixSP:
		add	sp, size PointerInfo
MIError:
		ERROR	ALREADY_INITIALIZED
PrintMessage	<Do you really want to unconditonally DIE here?>

MouseInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDICalibrate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	routine to correct for the digitizer's inaccuracies
		shamelessly stolen from gazelle.asm
CALLED BY:	MouseInit
PASS:		ds	= dgroup
RETURN:		calibration stuff loaded.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		read .ini file to get the scale factors, and the X & Y offset

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	11/13/92	Initial version
	mjoy	8/9/96		adapted for GDI driver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
gdiCategory		byte	"mouse", 0
gdiScaleX		byte	"scaleX", 0
gdiScaleY		byte	"scaleY", 0
gdiOffsetX		byte	"offsetX", 0
gdiOffsetY		byte	"offsetY", 0

GDICalibrate	proc	near	uses ax,dx,cx,si
	.enter
	mov	si,offset gdiCategory ;init file category string.
	mov	ax,DEFAULT_SCALEX	
	mov	dx,offset gdiScaleX	 ;init file key string.
	call	GDIFetchIniInteger	;see if its in the init file...
	mov	ds:Xscale, ax	;stuff it.
	mov	ax, DEFAULT_SCALEY	
	mov	dx,offset gdiScaleY ;init file key string.
	call	GDIFetchIniInteger	;see if its in the init file...
	mov	ds:Yscale, ax
	mov	ax,DEFAULT_OFFSETX	
	mov	dx,offset gdiOffsetX ;init file key string.
	call	GDIFetchIniInteger	;see if its in the init file...
	mov	ds:offsetX,ax
	mov	ax, DEFAULT_OFFSETY
	mov	dx,offset gdiOffsetY ;init file key string.
	call	GDIFetchIniInteger	;see if its in the init file...
	mov	ds:offsetY,ax
	clc
	.leave
	ret
GDICalibrate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIFetchIniInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches an integer value from .ini file

CALLED BY:	MouseInit

PASS:		cs:dx	- ptr to integer field string

RETURN:		carry	- clear if integer found
		ax	- integer

DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
	calls InitFileReadInteger

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	6/28/96		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GDIFetchIniInteger	proc	near
						;cs:dx is ptr to field string
		push	ds
		segmov	ds, cs, cx		; ds, cx <- cs
		call	InitFileReadInteger	;ax <- integer value
		pop	ds
		ret
GDIFetchIniInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn on the device.

CALLED BY:	DRE_SET_DEVICE
PASS:		ds:si = pointer to null-terminated device name string (ignored)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	 configure the driver to support the indicated device. 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice	proc	near
		.enter
	;
	; initialize device dependent part
	;
		call	GDIPointerInit
	; TODO: do something about error code returned in ax
	;
		.leave
		ret
MouseSetDevice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves	

CALLED BY:	MouseStrategy
PASS:		ds- dgroup
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		call GDI library routines to unregister call back and
		shutdown device

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseExit	proc	near
		;
		; Make sure we've been initialized
		;
		test	ds:mouseStratFlags, MASK MOUSE_ON
		jz	MEError		; Choke

		; Set the ptr flags to what they were initially
		;
		mov	al, ds:[oldPtrFlags]
		mov	ah, al
		not	ah
		call	ImSetPtrFlags
		
	;
	;unregister callback
	;
		mov	dx, segment GDIPtrCallback
		mov	si, offset GDIPtrCallback
		call	GDIPointerUnregister
	;
	;	shutdown the device
	;
		call	GDIPointerShutdown
		;
		; Note that the driver is off
		;
		and	ds:mouseStratFlags, NOT MASK MOUSE_ON
		clc				; No errors
		ret
MEError:
		stc
		ret
MouseExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the mouse for the duration of our stasis

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer to fill with error message
		ds	= dgroup (from MouseStrategy)
RETURN:		carry set if couldn't suspend
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/28/96		Initial rivision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSuspend	proc	near
	;figure out if anything is distroyed and save regs
		.enter

		BitSet	ds:[mouseStratFlags], MOUSE_SUSPENDING
	;
	;unregister call back
	;
		mov	dx, handle GDIPtrCallback
		mov	si, offset GDIPtrCallback
		call	GDIPointerUnregister
		

		BitClr	ds:[mouseStratFlags], MOUSE_SUSPENDING

		.leave
		ret
MouseSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn the mouse back on again

CALLED BY:	MouseStrategy (DR_UNSUSPEND)
PASS:		ds	= dgroup	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: nothing intense, leave it to the GDI library
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	5/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseUnsuspend	proc	near
		.enter
	;
	; register callback routine
	;
		mov	dx, segment GDIPtrCallback
		mov	si, offset GDIPtrCallback
		call 	GDIPointerRegister		
		
		.leave
		ret
MouseUnsuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find available report rates for the mouse

CALLED BY:	MouseStrategy (DR_MOUSE_GET_RATES)
PASS:		DS 	= dgroup
		ES:DI	= address byte table containing available rates
			  (in reports/sec)
		CX	= length of table	
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: most of the drivers don't handle this, so do nothing
		      for now
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetRates	proc	near
		.enter
		.leave
		ret
MouseGetRates	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetAcceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set acceleration for mouse

CALLED BY:	MouseStrategy (DR_MOUSE_SET_ACCELERATION)
PASS:		DS	= dgroup
		CX	= threshold
		DX	= multiplier
RETURN:
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetAcceleration	proc	near
		mov	ds:[mouseAccelThreshold], cx
		mov	ds:[mouseAccelMultiplier], dx
		clc
		ret
MouseSetAcceleration	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetAcceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current acceleration info from driver

CALLED BY:	MouseStrategy (DR_MOUSE_GET_ACCELERATION)
PASS:		DS	= dgroup
RETURN:		CX	= threshold
		DX	= multiplier
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetAcceleration	proc	near
		mov	cx, ds:[mouseAccelThreshold]
		mov	dx, ds:[mouseAccelMultiplier]
		clc
		ret
MouseGetAcceleration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCombineMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set combine mode for mouse

CALLED BY:	MouseStrategy (DR_MOUSE_SET_ACCELERATION)
PASS:		DS	= dgroup
		CL	= MouseCombineMode
RETURN:
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetCombineMode	proc	near
		mov	ds:[mouseCombineMode], cl
		clc
		ret
MouseSetCombineMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCombineMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get combine mode

CALLED BY:	MouseStrategy (DR_MOUSE_GET_ACCELERATION)
PASS:		DS	= dgroup
RETURN:		CL	= MouseCombineMode
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetCombineMode	proc	near
		mov	cl, ds:[mouseCombineMode]
		clc
		ret
MouseGetCombineMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Trivial routine to inform the caller that this driver has
		no *idea* whether there's a mouse of the given type out
		there.
		TODO change this to test if the library is present atleast
CALLED BY:	MouseStrategy (DRE_TEST_DEVICE)
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		ax	= DevicePresent code (always DP_CANT_TELL)
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
	 	mov	ax, DP_CANT_TELL
		clc
		.leave
		ret
MouseTestDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPtrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends appropriate events to the system	

CALLED BY:	Device handler
PASS:		cx	-> x value
		dx	-> y value
		bh	-> event mask of button state, (0 in bit => pressed)
		bl	-> msb = 1 , delta event
			   else absolute event
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	Send as output to Input Manager:

		di	- MSG_IM_PTR_CHANGE
		cx	- mouse X change
		dx	- mouse Y change
		bp	- PtrInfo
		si	- unused


		di	- MSG_IM_BUTTON_CHANGE
		cx	- timestamp LO
		dx	- timestamp HI
		bp	- <0>:<buttonInfo>
			   buttonInfo:
				Bit     7 = set for press, clear for release
				Bits  2-0 = button #
					B0 = 0
					B1 = 1
					B2 = 2
		si	- unused
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	5/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Macro to test if a button has changed state and call MouseSendButtonEvent to
; generate the proper MSG_IM_BUTTON_CHANGE event. 
;
CheckAndSend	macro	bit, num
		local	noSend
		test	al, MASK MOUSE_&bit	; Changed?
		jz	noSend			; No
		mov	bl, num			; Load bl with button #
		test	bh, MASK MOUSE_&bit	; Set ZF true if button now
						;  down
		call	MouseSendButtonEvent
noSend:
		endm


GDIPtrCallback	proc	far
		uses	ax,bx,cx,dx,bp,si,di,ds,es
  		.enter
 	;
 	; make ds point to gdiptr dgroup
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx
	;
	; check if x & y values are abs or delta vals
	;
		clr	ax, di
		test	bx, mask MB_DELTA
		jz	checkPosChange
	; cx, dx have delta values
		add	cx, ds:[digiXPos]
		add	dx, ds:[digiYPos]

		
checkPosChange:
	;
	; see if there was any position change
	;
		cmp	ds:[digiXPos], cx
		jne	calibCoords
		cmp	ds:[digiYPos], dx
		jne	calibCoords
afterSendEvent:
		; Check for changes in the button state. XOR the current
		; and previous states together to find any button bits that
		; changed. A bit is 0 if the button is pressed.
		;
		and	bh, MouseButtonBits	; Make sure only defined
						; bits are around...
		mov	al, bh
		xor	al, ds:mouseButtons
		jz	exit			; Nothing changed -- all done.
		;
		; Save current button state (do it now since we don't
		; reference it again and we want to avoid doubled events in 
		; the case of our event sending being interrupted)
		;

		mov	ds:mouseButtons, bh

		push	bp		; Preserve passed BP

		CheckAndSend B0, 0
		CheckAndSend B1, 1
		CheckAndSend B2, 2
		CheckAndSend B3, 3
		pop	bp		; Restore passed BP
exit:
		jmp	done
	;
	; store old raw coords to pass back in DR_MOUSE_GET_RAW_COORD
	;
calibCoords:
		mov	ds:[digiXPos], cx
		mov	ds:[digiYPos], dx
	;
	; calibrate the mouse coordinates to screen coordinates
	;
		mov_tr	ax, cx
		sub	ax, ds:[offsetX]
		jns	scaleX
		clr	ax
scaleX:
		push	dx
		mul	ds:[Xscale]
		mov_tr	cx, ax		;ax <- imp part of screen
					;coord
	; scale y coord
		pop	ax
		sub	ax, ds:[offsetY]
		jns	scaleY
		clr	ax
scaleY:
		mul	ds:[Yscale]
		mov_tr	dx, ax
	;
	; cx <- scaled x coord, dx <- scaled y coord
	; save calibrated points to pass back in DR_MOUSE_GET_RAW_COORD
	;
		mov	ax, cx
		sub	ax, ds:[ptrXPos]
		mov	ds:[deltaX], ax
		mov	ax, dx
		sub	ax, ds:[ptrYPos]
		mov	ds:[deltaY], ax
	;
	; see if we are currently handling a hard-icon press
	;
		tst	ds:[hardIconPress]
		jz	continue
		cmp	bh, PEN_UP	; ON_HARD_ICON & pen release
		jnz	done
	; actually released the pen, start up app
		mov	ds:[hardIconPress], OFF_HARD_ICON
		call	ReleaseOnHardIcon
	;	jmp	done
done:
		.leave
		ret
	; we need to constrain coordinates to lcd limits, if it
	; is outside lcd limits and PEN_DOWN, set hardIconPress, and
	; do not constrain cx, dx, instead store unconstrained values
	; and continue
continue:		
	; check if we have strayed outside the LCD screen
	;
		clr	di
		movdw	essi, ds:[hirTable]
		add	si, size HardIconRegion
		cmp	cx, es:[si].HIR_left
		jge	checkXMax
		ornf	di,(mask CONSTRAIN_X_MIN)
checkXMax:
		cmp	cx, es:[si].HIR_right
		jle	checkYMin
		ornf	di, (mask CONSTRAIN_X_MAX)
checkYMin:
		cmp	dx, es:[si].HIR_top
		jge	checkYMax
		mov 	di, mask CONSTRAIN_Y_MIN
checkYMax:
		cmp	dx, es:[si].HIR_bottom
		jle	checkButtonPress
		mov 	di, mask CONSTRAIN_Y_MAX
checkButtonPress:
		tst	di
		jz	saveCoords
		cmp	ds:[calibrating], TRUE
		je	constrainAndSend
		cmp	bh, PEN_DOWN	;TODO first pen press
		jne	constrainAndSend
		mov	ds:[hardIconPress], ON_HARD_ICON
		jmp	saveCoords
constrainAndSend:
		test	di, mask CONSTRAIN_X_MIN
		jz	constrainXMax
		mov	ax, es:[si].HIR_left
		sub	ax, cx
		sub	ds:[deltaX], ax
		mov	cx, es:[si].HIR_left
constrainXMax:
		test	di, mask CONSTRAIN_X_MAX
		jz	constrainYMin
		sub	cx, es:[si].HIR_right
		sub	ds:[deltaX], cx
		mov	cx, es:[si].HIR_right
constrainYMin:
		test	di, mask CONSTRAIN_Y_MIN
		jz	constrainYMax
		mov	ax, es:[si].HIR_top
		sub	ax, dx
		sub	ds:[deltaY], ax
		mov	dx, es:[si].HIR_top
constrainYMax:
		test	di, mask CONSTRAIN_Y_MAX
		jz	saveCoords
		sub	dx, es:[si].HIR_bottom
		sub	ds:[deltaY], dx
		mov	dx, es:[si].HIR_bottom
saveCoords:
		mov	ds:[ptrXPos], cx
		mov	ds:[ptrYPos], dx
		test	bx, mask MB_DELTA
		jz	sendPtr
	; this is crazy, in the case of pointers that pass back delta
	; changes in mouse pos, I keep adding it to digi[X/Y]Pos, with
	; the  obvious result that will keep increasing to
	; infinity. THerefore need to have a bounds check. But what
	; are the uncalibrated digitizer screen bounds ? It's a
	; resonable assumption that digitizers always pass abs
	; coordinates and mice may pass either abs or delta
	; changes. So if it's a delta value, we are dealing with a mouse
	; and so it's ok to compare the uncalibrated coordinated
	; against the calibrated screen limits
		mov	ds:[digiXPos], cx
		mov	ds:[digiYPos], dx
sendPtr:
	;                                   
	; Send IM_PTR_CHANGE event...
	; 
					; But first, perform any mouse
					; acceleration needed
 		push	bp		; Preserve passed BP
	
		clr	bl		; ignore info about abs or delta 
		push	bx		; Save button state
		call	TimerGetCount   ; why are we doing this ?
	;
	; we always pass absoulte values
	;
	  	ornf	ax, (mask PI_absX or mask PI_absY)
		xchg	bp, ax

		call	MousePreparePtrEvent
		;
		; Push address of routine onto the stack
		;
		mov	di, mask MF_FORCE_QUEUE
		cmp	ds:[mouseCombineMode], MCM_NO_COMBINE
		jz	sendEvent
		
		push	cs
		mov	ax, offset Resident:MouseCombineEvent
		push	ax
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE or \
			    mask MF_CUSTOM or \
			    mask MF_CHECK_LAST_ONLY
sendEvent:
		mov	bx, ds:[mouseOutputHandle]
		mov	ax, MSG_IM_PTR_CHANGE
		call	ObjMessage
		pop	bx		; and button state.
		pop	bp		; Restore passed BP
		jmp	afterSendEvent
GDIPtrCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseOnHardIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	released pen after pressing on the region outside the
lcd screen. Determine if press was on a hard icon and if so start up
corresponding app.	

CALLED BY:	GDIPtrCallback
PASS:		cx - X position
		dx - Y position
		ds - dgroup
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	7/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseOnHardIcon	proc	near
		hiaSize	local	word
		uses ax,bx,cx,dx,di,si,es,bp,ds
		.enter
		movdw	essi, ds:[hirTable]
		mov	hiaSize, size HardIconRegion
		mov	cx, 2	;# entries in hirTable two less tha n hiCount
searchLoop:
		inc	cx
		cmp	ds:[hiCount], cx
		jb	notFound
		add	si, hiaSize
	
		cmp	es:[si].HIR_left, dx
		jb	searchLoop
		cmp	es:[si].HIR_right, dx
      		ja	searchLoop
		cmp	es:[si].HIR_top, di
		jb	searchLoop
		cmp	es:[si].HIR_bottom, di
		ja	searchLoop
	; if we are here then it we've found the hardicon region
	; inside which the pointer release took place, so try and
	; start up app
		movdw	essi, ds:[hiaTable]
		mov_tr	ax, cx
		mul	hiaSize
		add	si, ax
	;see if there is anything associated with this hard cion
	;before sending it off
		cmp	es:[si].HIA_cx, NO_HARD_ICON_ENTRY
		je	notFound
		mov	cx, es:[si].HIA_cx
		mov	dx, es:[si].HIA_dx
		mov	bp, es:[si].HIA_bp
		mov	ax, MSG_META_NOTIFY
		mov	bx, ds:[mouseOutputHandle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
notFound:
		.leave
		ret
ReleaseOnHardIcon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MouseAccelerate

DESCRIPTION:	Accelerate passed mouse differential

CALLED BY:	INTERNAL
		GDIPtrCallback

PASS:
	ds - driver's data segment
	ax - value to accelerate

RETURN:
	ax - new value

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@

MouseAccelerate	proc	near
	push	dx
	mov	di, ds:[mouseAccelThreshold]
	mov	dx, ax
	tst	ax
	jns	checkThreshold
	neg	di		; use negative threshold for negative delta

checkThreshold:
	sub	ax, di

	mov	dl, ah		; save high byte of result...
	lahf			; sign change?
	xor	ah, dh
	mov	ah, dl		; recover high byte of result
	js	afterMultiplier	; SF set => sign change => motion too small to
				;  accelerate
	
	imul	ds:[mouseAccelMultiplier]	; Amplify amount over threshold
afterMultiplier:
	add	ax, di		; add threshold back in to possibly amplified
				;  delta
	pop	dx
	ret
MouseAccelerate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSendButtonEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for MouseHandler

CALLED BY:	MouseHandler
PASS:		BL	= button number for event:
				0 = left
				1 = middle
				2 = right
				3 = fourth button
		ZF	= Set if button now down
RETURN:		Nothing
DESTROYED:	CX, DX, BP, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSendButtonEvent	proc	near
		push	ax
		push	bx
		jnz	SBE_10			; See if press bit set
      		or	bl, MASK BI_PRESS	; Set press flag
SBE_10:
						; store button #/press flag
		clr	bh
		mov	bp, bx
						; Get current time NOW
		call	TimerGetCount		; Fetch <bx><ax> = system time
		mov	cx, ax			; set <dx><cx> = system time
		mov	dx, bx

		mov	bx, ds:mouseOutputHandle
      		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_IM_BUTTON_CHANGE
		call	ObjMessage		; Send the event

		pop	bx
		pop	ax
		ret
MouseSendButtonEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MousePreparePtrEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the registers for sending out a IM_PTR_CHANGE event

CALLED BY:	GDIPtrCallback, drivers that define MOUSE_DONT_ACCELERATE
PASS:		cx	= delta X
		dx	= delta Y
		bp	= PtrInfo w/timestamp
		ds	= dgroup
RETURN:		cx, dx, bp properly massaged
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 1/90	Initial version
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MousePreparePtrEvent	proc	near
		.enter
	;
	; If the events occurred close enough together (within
	; MOUSE_ACCEL_THRESH ticks of each other), perform any needed
	; acceleration on the two.
	; 
		push	bp
		sub	bp, ds:[mouseLastTime]
		andnf	bp, mask PI_time	; deal with timer wrap-around
						;  by clearing insignificant
						;  bits.
		cmp	bp, MOUSE_ACCEL_THRESH
		pop	bp			; restore new timestamp for
						;  event.
		ja	notCloseEnough

	;
	; Add the new deltas to the previous raw deltas and save that.
	;
		add	cx, ds:[mouseRawDeltaX]
		add	dx, ds:[mouseRawDeltaY]
		mov	ds:[mouseRawDeltaX], cx
		mov	ds:[mouseRawDeltaY], dx
		
	;
	; Accelerate the resulting cumulative raw deltas, then trim the results
	; back by the previous accelerated deltas, providing us with continuous
	; time-based acceleration. We save the new accelerated deltas for the
	; next time, of course.
	; 
		xchg	ax, cx
		call	MouseAccelerate
		mov	cx, ax
		xchg	ax, ds:[mouseAccDeltaX]
		sub	cx, ax

		xchg	ax, dx
		call	MouseAccelerate
		mov	dx, ax
		xchg	ax, ds:[mouseAccDeltaY]
		sub	dx, ax

done:
		.leave
		ret

notCloseEnough:
	;
	; Perform single-event acceleration and setup the state variables for
	; the next IM_PTR_CHANGE event.
	; 
		mov	ds:[mouseLastTime], bp
		mov	ds:[mouseRawDeltaX], cx
		mov	ds:[mouseRawDeltaY], dx
		xchg	ax, cx
		call	MouseAccelerate
		mov	ds:[mouseAccDeltaX], ax	; (smaller than mov from cx)
		xchg	ax, cx
		
		xchg	ax, dx
		call	MouseAccelerate
		mov	ds:[mouseAccDeltaY], ax	; (smaller than mov from dx)
		xchg	ax, dx
		jmp	done
MousePreparePtrEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCombineEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for GDIPtrCallback via ObjMessage

CALLED BY:	ObjMessage
PASS:		DS:BX	= address of event to check
		AX	= method from event being sent
		CX	= CX from event being sent
		DX	= DX from event being sent
		BP	= BP from event being sent
		
RETURN:		DI	= PROC_SE_EXIT if combined with existing event
			  PROC_SE_STORE_AT_BACK if should stop scan and just
			  	store the event. Since we can only be called
				for the last event in the queue, we return
				PROC_SE_STORE_AT_BACK unless we actually
				have combined things.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/89		Initial version
	Steve	12/7/89		Added combining of time stamps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef MOUSE_USES_ABSOLUTE_DELTAS
deltaerr equ <ERROR_NZ>
else
deltaerr equ <ERROR_Z>
endif

MouseCombineEvent proc	far
		mov	ax, ds:[bx].HE_method	; get event type of entry
		cmp	ax, MSG_IM_PTR_CHANGE; see if we should update
		LONG jne noCombine

ifndef MOUSE_COMBINE_DISCARD
	;
	; Check for colinear mode
	;
		push	es
		mov	di, dgroup
		mov	es, di
		cmp	es:[mouseCombineMode], MCM_COMBINE
		jz	combine
	;
	; Do colinear check -- for now just toss things one pixel apart
	;

		push	ax, bx, cx, dx
		sub	cx, ds:[bx].HE_cx
		sub	dx, ds:[bx].HE_dx
		mov	ax, es:deltaX
		mov	bx, es:deltaY
	;
	; ax, bx = delta1 = delta from last position to position before that
	; cx, dx = delta2 = delta from last position
	;
	; add deltas in (assuming that we will combine)
	;
		add	es:deltaX, cx
		add	es:deltaY, dx
	;
	; if (delta1 == delta2) then combine
	;
		cmp	ax, cx
		jnz	10$
		cmp	bx, dx
		jz	popAndCombine
10$:
	;
	; if (delta1.X ==0) and (delta2.X == 0) then combine  /* vertical */
	; if (delta1.Y ==0) and (delta2.Y == 0) then combine  /* horizontal */
	;
		tst	ax
		jnz	20$
		jcxz	popAndCombine
20$:
		tst	bx
		jnz	30$
		tst	dx
		jz	popAndCombine
30$:
	;
	; if (delta1 is one unit) and (delta2 is one unit) then combine
	;
		tst	ax
		jns	40$
		neg	ax			;ax = abs(ax)
40$:
		tst	bx
		jns	50$
		neg	bx			;bx = abs(bx)
50$:
		tst	cx
		jns	60$
		neg	cx			;cx = abs(cx)
60$:
		tst	dx
		jns	70$
		neg	dx			;dx = abs(dx)
70$:
		add	ax, bx
		cmp	ax, 1
		ja	popNoCombine
		add	cx, dx
		cmp	cx, 1
		ja	popNoCombine

popAndCombine:
if	DEBUG_COMBINE
		inc	es:[combineCount]
endif
		pop	ax, bx, cx, dx
		mov	es:[noStoreDeltasFlag], 1
combine:
		pop	es

	;ifndef MOUSE_USES_ABSOLUTE_DELTAS
	;
	; Sum the two events.
	;
	;	add	cx, ds:[bx].HE_cx
	;	add	dx, ds:[bx].HE_dx
	;ndif
		mov	ds:[bx].HE_cx, cx
		mov	ds:[bx].HE_dx, dx

endif
		mov	ds:[bx].HE_bp, bp	; update time stamp
		mov	di, PROC_SE_EXIT	; show we're done
		ret

ifndef MOUSE_COMBINE_DISCARD
popNoCombine:
 if	DEBUG_COMBINE
		inc	es:[noCombineCount]
 endif
		pop	ax, bx, cx, dx
		pop	es
endif
noCombine:
		mov	di, PROC_SE_STORE_AT_BACK
		ret

MouseCombineEvent endp

categoryString	char	"mouse", 0
keyString	char	"calibration", 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the screen coordinates that will be used for calibration.

CALLED BY:	MouseStrategy

PASS:		DX:SI	= Buffer holding up to MAX_NUM_CALIBRATION_POINTS
			  calibration points

RETURN:		DX:SI	= Buffer filled with calibration points
		CX	= # of calibration points

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY: 	the no of points used for calibration and also the
			actual points will be stored in the ini file. read
			these values and return in dx:si

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		mjoy	24/4/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetCalibrationPoints	proc	near
		.enter
	; read data from .INI file
 		segmov	es, dx
		mov	di, si
		mov	bp, cx		; # of calibration pts
		clr	ax
		rep	stosw
		mov	di, si
		segmov	ds, cs, cx
		mov	si, offset categoryString
		mov	dx, offset keyString
		call	InitFileReadData
		segmov	dx, es
		mov	si, di
		jnc	done
	;
	; there is no calibration info in the ini file so, assume device can
	; not be calibrated
	;
		WARNING	MOUSE_DEVICE_CANNOT_BE_CALIBRATED
		clr	cx
done:
		.leave
	 	ret
MouseGetCalibrationPoints	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetCalibrationPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the calibration points for the current device	

CALLED BY:	MouseStrategy
PASS:		dx:si	= Buffer holding the calibraton points
		cx	= # of calibration points
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	basic idea similar to bulletpen.asm
			x-scale = (XLscreenCoord - XRscreenCoord) /
				   (XLdigiCoord	- XR digiCoord)

			y-scale = (YTscreenCoord - YBscreenCoord) /
				   (YTdigiCoord	- YBdigiCoord)
	Next determine the offset:
To make this as general as possible, to accomadate the diff devices, I'm
doing some stuff , which is not ready for a code review, so for now lets
assume that we read the values from the ini file


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetCalibrationPoints	proc	near
		screenX	local	word
		screenY	local	word
		digiX	local	word
		digiY	local	word
		.enter

	;	call	MouseReadCalibrationFromIniFile

	 	segmov	es, dx
	 	mov	di, si
	;
	; allocate space to store uncalibrated ptr coords
	; TODO, remove magic no 100
	;
	 	mov	si, 100
		sub	sp, si
	; temp: write out data that is to be read from ini file
		segmov	es, ss
		mov	di, sp
		mov	dx, di
		mov	ax, 0
		stosw
		mov	ax, 0
                                                               
		mov	ax, 640
		stosw
		mov	ax, 0
		stosw
		mov	ax, 0
		stosw
		mov	ax, 480
		stosw
		mov	ax, 640
		stosw
		mov	ax, 480
		stosw
	; restore di
		push	bp
		
		mov	di, dx
		segmov	ds, cs, cx
		mov	si, offset categoryString
		mov	dx, offset keyString
		mov	bp, 50
	  	call	InitFileWriteData
		call	InitFileCommit	
		segmov	dx, es
		mov	si, di
	 	mov	cx, 50		
	  	call	MouseGetCalibrationPoints		
		pop	bp
		jcxz	cantCalib
	 	segmov	ds, dx
	;
	; es:di digitizer coordinates
	; ds:si screen coordinates
	;
		clr	dx
		push	cx
calibLoop:
		mov	ax, ds:[si]
	 	mov_tr	screenX, ax
	 	inc	si
	 	mov	ax, ds:[si]
	 	mov_tr	screenY, ax
	 	mov	ax, es:[di]
	 	mov_tr	digiX, ax
	 	inc	di
	 	mov	ax, es:[di]
	 	mov_tr	digiY, ax
	;
	; diff in screen x coords for the two points
	;
		inc	si
		mov	ax, ds:[si]
		sub	screenX, ax
	;
	; diff in corresponding digi x coords for the two points
	;
		inc	di
		mov	bx, es:[di]
		sub	digiX, bx
	;
	; Xscale = screen range / digi range
	;
		xchg	ax, screenX
		div	digiX
		mov	digiX, bx
		add	ds:[Xscale], ax
	;
	; diff in screen Y coords for the two points
	;
		inc	si
		mov	cx, ds:[si]
		sub	screenY, cx
	;
	; diff in corresponding digi Y coords for the two points
	;
		inc	di
		mov	bx, es:[di]
		sub	digiY, bx
	;
	; Yscale = diff in Y screen coord / diff in Y digi coord
	;
		mov	ax, screenY
		div	digiY
		add	ds:[Yscale], ax

		loop	calibLoop
		pop	cx
	;
	; calculate average
	;
		mov	ax,ds:[ Xscale]
		div	cx
		mov	ds:[Xscale], ax

		mov	ax, ds:[Yscale]
		div	cx
		mov	ds:[Yscale], ax
		jmp	done	
		
cantCalib:
		WARNING MOUSE_DEVICE_CANNOT_BE_CALIBRATED

done:
		add	sp, 100
		.leave
		ret
MouseSetCalibrationPoints	endp

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


MouseReadCalibrationFromIniFile	proc	near
	uses	ds, di, bp, es, di
	.enter
	;
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
		jc	done				
	;
	; Successful read from ini file.. store the info in the dgroup
	; variables.
	;
		mov	ax, es:[di]
		mov	ds:[Xscale], ax
		inc	di
		mov	ax, es:[di]
		mov	ds:[Yscale], ax
		inc	di
		mov	ax, es:[di]
		mov 	ds:[offsetX], ax
		inc	di
		mov	ax, es:[di]
		mov	ds:[offsetY], ax

		clc
	
done:
	; Preserve the flags around the stack restoration.
	;
	lahf
	add	sp, 100
	sahf
	
	.leave
	ret
MouseReadCalibrationFromIniFile	endp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetRawCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get current calibrated and un calibrated coordinate

CALLED BY:	MouseStrategy
PASS:		nothing
RETURN:		ax, bx -> digitizer coords
		cx, dx -> calibrated screen coords
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: return values stored by GDIPtrCallback
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseGetRawCoordinate	proc	near
		.enter
	;TODO some kind of error checking
		mov	ax, ds:[digiXPos]
		mov	bx, ds:[digiYPos]

		mov	cx, ds:[ptrXPos]
		mov	dx, ds:[ptrYPos]

		clc
		.leave
		ret
MouseGetRawCoordinate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStartCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start the calibration process	

CALLED BY:	MouseStrategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: pretty obvious
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStartCalibration	proc	near
		uses	ax, ds
		.enter

		segmov	ds, dgroup, ax
		mov	ds:[calibrating], TRUE

		.leave
		ret
MouseStartCalibration	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStopCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MouseStartegy
PASS:		nothing	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mjoy	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseStopCalibration	proc	near
		uses	ax, ds
		.enter

		segmov	ds, dgroup, ax
		mov	ds:[calibrating], FALSE
		
		.leave
		ret
MouseStopCalibration	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseChangeOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the destination of the Mouse events

CALLED BY:	Strategy Routine

PASS:		bx	-> handle of queue where to send to
RETURN:		bx	<- handle of previous queue
DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Swap out the destination queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseChangeOutput	proc	near
	xchg	ds:[mouseOutputHandle], bx
	ret
MouseChangeOutput	endp
Resident ends




