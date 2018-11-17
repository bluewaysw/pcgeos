COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT: Breadbox Home Automation
FILE:    X10Init.asm

AUTHOR:     Fred Goya

ROUTINES:
	Name           Description
	----           -----------
	X10Init        Initialize controller
	X10ExitDriver  Deal with leaving GEOS
	X10Suspend     Deal with task-switching
	X10Unsuspend   Deal with waking up after task switch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode segment  resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Initialize the X-10 controller

CALLED BY:  Strategy Routine, X10Unsuspend

PASS:    ds -> driver's dgroup

RETURN:     carry set if no controller found
DESTROYED:  nothing

PSEUDO CODE/STRATEGY:
		Read .INI file for port and settings to use.
		If no port set, return with no error. (Allows software to configure)
		Call the appropriate interface-specific initialization routine.
		Return the results in carry flag.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		.INI settings will be cleared if no controller found so next load
		attempt will succeed by default.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Init  proc  far
	.enter
	call	ReadIniFileSettings  ; gets base port and settings

	cmp		ds:[X10Settings], SETTINGS_NONE
	je		done
	
	cmp		ds:[X10Settings], SETTINGS_DIRECT
	jne		doSerial
	
	; Test for direct interface
	call  	X10TestPort ; test port to see if there's a controller there
	jnc		done				; controller found (or no port set)
	jmp		reset				; no controller
	
	; Test for serial interface
doSerial:
	call	X10SerialInit		; test serial interface for response
	jnc		done				; controller found (or no port set)
	jmp		reset				; no controller
	
reset:
	clr		bx					; no controller on that port, clear it out
	mov		ds:[X10Port], bx
	mov		ds:[X10Settings], bx
	call	WriteIniFileSettings	; erase setting
	stc
done:
	.leave
	ret
X10Init     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadIniFileSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Read the base hardware settings from the .ini file

CALLED BY:  X10Init
PASS:    nothing
RETURN:     nothing
DESTROYED:  nothing
SIDE EFFECTS:
		Sets the port and things

PSEUDO CODE/STRATEGY:
		Read category/key from .ini file.
		If it doesn't exist, create it using current values.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadIniFileSettings  proc  far
	uses ax, cx, dx, bp, si
	.enter
	mov   si, offset x10DriverCategory  ; ds:si <- category asciiz
	mov   cx, ds                        ; cx:dx <- key asciiz
	mov   dx, offset x10DriverKey
	call  InitFileReadInteger           ; get base port address in ax
	jc    noCategory                    ; carry set if error
	mov   bp, ax
	mov   dx, offset x10SettingsKey		; cx:dx <- key asciiz
	call  InitFileReadInteger			; get settings in ax
	jc	  noCategory
	mov   ds:[X10Port], bp
	mov	  ds:[X10Settings], ax
	jmp   done

noCategory:                            ; if we get here, we have to make them.
	call WriteIniFileSettings

done:
	.leave
	ret
ReadIniFileSettings  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteIniFileSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Write the base hardware settings to the .ini file

CALLED BY:  X10Init, X10ChangePort
PASS:    nothing
RETURN:     nothing
DESTROYED:  nothing
SIDE EFFECTS:
		.INI file setting is changed and committed

PSEUDO CODE/STRATEGY:
		Write or create category/keys in .ini file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteIniFileSettings  	proc  far
	uses ax, cx, dx, bp, si
	.enter
	mov   bp, ds:[X10Port]      ; bp <- integer to write to .ini file
	mov   si, offset x10DriverCategory  ; ds:si <- category asciiz
	mov   cx, ds                        ; cx:dx <- key asciiz
	mov   dx, offset x10DriverKey
	call  InitFileWriteInteger          ; write port to file
	mov	  bp, ds:[X10Settings]
	mov   dx, offset x10SettingsKey
	call  InitFileWriteInteger			; write settings to file
	call  INITFILECOMMIT				; commit changes
	.leave
	ret
WriteIniFileSettings	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10TestPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Test the port to see if there's a controller there.

CALLED BY:  X10Init, X10ChangePort
PASS:    ds -> dgroup of driver
RETURN:     carry set if error
DESTROYED:  nothing
SIDE EFFECTS:
		Sets base port level
		Clears base port level on error, so rest of code doesn't lock

PSEUDO CODE/STRATEGY:
		Check for 2 or 3 zero crossings.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10TestPort proc  far
	uses  ax, bx, cx, dx, di, si, es
	.enter
	clc								 ; no error if port is zero
	mov   dx, ds:[X10Port]   ; get base port
	tst   dx
	jz    done                       ; in case port is zero (i.e., we're debugging)

	cmp	dx, 4							; only allow COM1 to COM4
	ja	error

	mov	  si, dx
	dec	  si
	shl	  si, 1						 ; use port as index into address table
	mov	  dx, cs:PortAddresses[si]   ; get the address
	mov	  ds:[basePortAddress], dx	 ; store address in memory

	add   dx, 4                      ; why? 'cause the source code says so!
	mov   al, 1                      ; to initialize controller
	out   dx, al
	mov   ax, 15                     ; wait 1/4 sec. for power-up
	call  TimerSleep
	call  X10TestZeroCrossing        ; to clear status of zeroFlag

	call  SysEnterInterrupt          ; prevent context switching while we test
	mov   bx, 0                      ; count zero crossings found.
	mov   cx, 18                     ; 20 for Europe--18 for USA
testCrossings:
	push  cx
	mov   cx, DELAY1000
	call  X10Sleep          ; in 18ms, we should find 2 or 3 crossings.
	pop   cx
	call  X10TestZeroCrossing
	jnc   nextLoop                   ; no crossing here
	inc   bx                         ; found one--increment counter
nextLoop:
	loop  testCrossings
	call  SysExitInterrupt           ; enable context switching again.

	cmp   bx, 2                      ; did we find 2 or 3 crossings?
	jb    error					     ; less than 2 is bad
	cmp   bx, 3
	ja    error						 ; more than 3 is bad

	clc								 ; yes, found them!
	jmp   done

error:
	clr	ds:[basePortAddress]		 ; clear that address
	stc								 ; or lockup will happen!
		
done:
	.leave
;	clc                              ; for Lysle--trial version never returns error
	ret
X10TestPort endp

PortAddresses		dw 03f8h, 02f8h, 03e8h, 02e8h

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Close
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Close the port used by the X-10 controller

CALLED BY:  X10ChangePort, X10ExitDriver, X10Suspend

PASS:    ds -> driver's dgroup

RETURN:     nothing
DESTROYED:  nothing

PSEUDO CODE/STRATEGY:
		Call the appropriate interface-specific close routine.
		Return the results.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Close  proc  far
	cmp		ds:[X10Settings], SETTINGS_SERIAL_CM11
	jne		done				; Nothing to do for the direct interface.

	call	X10CloseSerial		; Serial, however, must close port.

done:
	.leave
	ret
X10Close	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10ExitDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   We are being unloaded.  Clean up after ourselves

CALLED BY:  Strategy Routine
PASS:    ds -> dgroup
RETURN:     nothing
DESTROYED:  allowed: ax, bx, cx, dx, si, di, ds, es

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Call the close routine to close any open ports.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10ExitDriver  proc  far
	uses ax, bx, es, di
	.enter
	call X10Close

	.leave
	ret
X10ExitDriver  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Suspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Prepare driver to go into task-switch

CALLED BY:  Strategy Routine

PASS:    cx:dx -> buffer in which to place reason for refusal, if
			suspension refused.
		ds -> dgroup
RETURN:     carry set on refusal
			cx:dx <- buffer null terminate reason
		carry clear if accept suspend
DESTROYED:  allowed: ax, di
SIDE EFFECTS:  

PSEUDO CODE/STRATEGY:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Suspend  proc  far
	.enter
	.leave
	ret
X10Suspend  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Unsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Return from a task switch.

CALLED BY:  Strategy Routine

PASS:    nothing
RETURN:     nothing
DESTROYED:  allowed: ax, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

NOTE: Due to timer issues, we cannot call the initialization routine
      for the serial interface.  There is no real gain in closing and
      reopening the port anyway, since the serial driver will restore its
      state on unsuspend, and our state doesn't change during the suspend;
      if the interface uninitialized, too bad. DH 3/11/99

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Unsuspend   proc  far
	.enter
	.leave
	ret
X10Unsuspend   endp

InitCode ends
