COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Jens-Michael Gross 1997 -- All Rights Reserved

PROJECT:	MM-Projekt
MODULE:		(MS)CDEX CDRom Driver
FILE:		CDAStrat.asm

AUTHOR:		Jens-Michael Gross

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial revision
        JMG     26.11.98        Improved init code


DESCRIPTION:
        This is a simple 'pass through' driver that passes requests for
        a CDRom drive that is supported by (MS)CDEX to the MSCDex API.
        It contains a check for the minimum requirements (MSCDEX >= 2.1)
        and a fix for the OpenDos NWCDEX subunit number bug.
        The driver will never fail to load, even if there is no MSCDEX.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;		dgroup DATA
;-----------------------------------------------------------------------------

idata	segment

DriverTable	DriverInfoStruct <CDAStrategy, 0, DRIVER_TYPE_OUTPUT>

public	DriverTable		; verhindert Warning durch Esp

idata	ends

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for driver-template

CALLED BY:	GLOBAL
PASS:		di	-> command to execute
		others <see routine>
		INTERRUPTS_OFF

RETURN:		<see routine>

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		call appropriate routine and return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	17.07.97	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CDAStrategy	proc	far
	.enter
	call	 cs:DriverRoutineJumpTable[di]
	.leave
	ret
CDAStrategy	endp

DriverRoutineJumpTable		nptr	CDAInit,		; DR_INIT
					CDAExit,		; DR_EXIT
					CDASuspend,		; DR_SUSPEND
					CDAUnsuspend,		; DR_UNSUSPEND
                                        CDAGetNumDrives,        ; get number of supported drives
                                        CDAGetVersion,          ; get MSCDEX (or driver) version number
                                        CDAGetDrives,           ; get supported CD drives
                                        CDAGetDriverInfo ,      ; get DOS driver infos
                                                                ; internal (!), see description
                                        CDACallDriver           ; execute DOS driver call
                                                                ; (this may be a switch tree later)

;-----------------------------------------------------------------------------
;
;		Standard Driver Routines
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with driver initialization

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Driver has been started and initializes itself

                it will read the number of CD drives in the system
                (if any) and the MSCDEX version number (if any).
                Loading always succeeds, the calling application has
                to check for available drives and go into no-CD-mode
                if there are none.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97    	Initial version
        JMG     26.11.98        Improved INIT-Code and OpenDos Bugfix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAInit	proc	near
	uses	ax, dx, ds, si
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

        mov  al,0x00        ; get number of CD drives
        mov  bx,0x0000
        mov  ah,0x15
        int  0x2f
        mov  ds:[num_drives],bl

        cmp  bl,0           ; no MSCDEX?
        jz ende

        mov  al,0x0c        ; get MSCDEX version number
        mov  ah,0x15
        mov  bx,0x0100
        int  0x2f
        mov  ds:[mscdex_version],bx

        cmp  bh,2
        jl   ende
        cmp  bl,0           ; Version at least 2.1 ?
        jz   ende

        mov  ds:[mscdex_valid],1 ; driver calls allowed

        mov  ax, segment dgroup
        mov  bx, OFFSET [drive_letters]
        call CDAGetDrives   ; get drive letters (for NWCDEX bugfix)

        mov  ax, segment dgroup
        mov  bx, OFFSET [driver_heads]
        call CDAGetDriverInfo ; get subunit numbers (for NWCDEX bugfix)

        mov  bx,1
        mov  si,5

copy:   mov  cl, ds:[si+driver_heads]
        mov  ds:[bx+driver_heads],cl
        inc  bx
        add  si,5
        cmp  bx,26
        jne  copy           ; copy subunit numbers to top of data area


ende:   clc
	.leave
	ret
CDAInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End driver

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		Driver is being detached and has to remove all of its links

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAExit	proc	near
	ret
CDAExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDASuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	System suspends (task switch)

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDASuspend	proc	near
	ret
CDASuspend	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	System is returning from suspend (task switch)

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAUnsuspend	proc	near
	ret
CDAUnsuspend	endp

ResidentCode		ends

