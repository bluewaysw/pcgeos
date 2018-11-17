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
udata    segment

	X10Settings    word     ; Settings for sending X-10 codes

udata    ends


InitCode segment  resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Initialize the X-10 controller

CALLED BY:  Strategy Routine

PASS:    ds -> driver's dgroup

RETURN:     nothing
DESTROYED:  carry set if no controller found

PSEUDO CODE/STRATEGY:
		Read .INI file for port and settings to use.
		Check port for zero crossings(to see if there's a controller there).

KNOWN BUGS/SIDE EFFECTS/IDEAS:


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Init  proc  far
	.enter
	call  ReadIniFileSettings  ; gets base port and settings

	call  X10TestPort ; test port to see if there's a controller there

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
		Sets the base port level and things

PSEUDO CODE/STRATEGY:
		Read category/key from .ini file.
		If it doesn't exist, create it.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadIniFileSettings  proc  near
	uses ax, cx, dx, bp, si
	.enter
	mov   si, offset x10DriverCategory  ; ds:si <- category asciiz
	mov   cx, ds                        ; cx:dx <- key asciiz
	mov   dx, offset x10DriverKey
	call  InitFileReadInteger           ; get base port address in ax
	jc    noCategory                    ; carry set if error
	mov   ds:[basePortAddress], ax
	jmp   done

noCategory:                            ; if we get here, we have to make one.
	mov   bp, ds:[basePortAddress]      ; bp <- integer to write to .ini file
	call  InitFileWriteInteger          ; write default port to file

done:
	.leave
	ret
ReadIniFileSettings  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10TestPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   Test the port to see if there's a controller there.

CALLED BY:  X10InitBoard, X10ChangePort
PASS:    ds -> dgroup of driver
RETURN:     carry set if error
DESTROYED:  nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Check for 2 or 3 zero crossings.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10TestPort proc  far
	uses  ax, bx, cx, dx, di, si, es
	.enter
	clc
	mov   dx, ds:[basePortAddress]   ; get base port
	tst   dx
	jz    done                       ; in case port is zero (i.e., we're debugging)

	add   dx, 4                      ; why? 'cause the source code says so!
	mov   al, 1                      ; to initialize controller
	out   dx, al
	mov   ax, 15                     ; wait 1/4 sec. for power-up
	call  TimerSleep
	call  X10TestZeroCrossing        ; to clear status of zeroFlag

	call  SysEnterInterrupt          ; prevent context switching while we test
	mov   bx, 0                      ; count zero crossings found.
	mov   cx, 20                     ; 20 for Europe--18 for USA
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

	stc                              ; set error (carry) flag
	cmp   bx, 2                      ; did we find 2 or 3 crossings?
	jne   try3  
	clc                              ; yes! found 2!
	jmp   done

try3:
	cmp   bx, 3                      ; how about 3?
	jne   done                       ; nope--no such luck. return error
	clc                              ; yes! found 3!
		
done:
	.leave
	ret
X10TestPort endp

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10ExitDriver  proc  far
	uses ax, bx, es, di
	.enter


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
SIDE EFFECTS:  none

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

SYNOPSIS:   Return from a task switch.  Re-initialize controller

CALLED BY:  Strategy Routine

PASS:    nothing
RETURN:     nothing
DESTROYED:  allowed: ax, di
SIDE EFFECTS:
		sets up controller to where it was after we last left it.

PSEUDO CODE/STRATEGY:
		Call X10Init.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10Unsuspend   proc  far
	.enter
	call  X10Init
	.leave
	ret
X10Unsuspend   endp

InitCode ends
