COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Jens-Michael Gross 1997 -- All Rights Reserved

PROJECT:	MM-Projekt
MODULE:		(MS)CDEX CDRom Driver
FILE:		CDAMain.asm

AUTHOR:		Jens-Michael Gross

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial revision
        JMG     26.11.98        Code rewritten to move the OpenDos NWCDEX bugfix
                                 from the library to the driver.
                                Now tests for correct minimum MSCDEX version
                                 before calling the CD driver through MSCDEX.

ROUTINES:
	Name			Description
	----			-----------
        CDAGetNumDrives         Get Number of CD drives.
        CDAGetVersion           Get (MS)CDEX version number
        CDAGetDrives            Get CDRom drive letters
        CDAGetDriverInfo        Get CD device driver subunit number informations
        CDACallDriver           Call the CD device drivers Strategy and Interrupt
                                routine.

DESCRIPTION:
	The code for the driver.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata		segment
	;
        ; uninitalized data segment
        ;
                headData     TYPE  26*5 dup(byte)
                letterString TYPE 26 dup(char)

		num_drives	byte       ; will be set to non-zero if there
                                           ; are any CD drives in the system

                mscdex_version  word       ; holds version number of MSCDex

                mscdex_valid    byte       ; flag if a CD driver may be called
                                           ; through MSCDEX (MSCDEX >= 2.1)


                driver_heads    headData   ; will hold the driver heads and
                                           ; subunit numbers for all drives
                                           ; to fix a bug in Caldera NWCDEX

                drive_letters   letterString; contains up to 26 drive letters


udata		ends

ResidentCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAGetNumDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of supported drives

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:		AL number of drives. Zero idicates that no drive is available.

DESTROYED:	AH

SIDE EFFECTS:	-

PSEUDO CODE/STRATEGY: This function simply gives back the value stored by
                      the init function.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial version
        JMG     26.11.98        Replaced MSCDEX call. Returning buffered
                                value instead.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAGetNumDrives	proc	near
    push ds
    mov	 ax, segment dgroup
    mov	 ds, ax
    mov  al, ds:[num_drives]
    mov  ah, 0
    pop  ds
    ret
CDAGetNumDrives endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAGetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the (MS)CDEX version and returns it in AX

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:		AX (high byte=major version number, low byte=minor version number

DESTROYED:	-

SIDE EFFECTS:	-

PSEUDO CODE/STRATEGY: This function simply gives back the value stored by
                      the init function.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial version
        JMG     26.11.98        Replaced MSCDEX call. Returning buffered
                                value instead.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAGetVersion	proc	near
    push ds
    mov	 ax, segment dgroup
    mov	 ds, ax
    mov  ax, ds:[mscdex_version]
    pop  ds
    ret
CDAGetVersion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAGetDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get drive header informations for all supported drives.
                From this information only the subunit number is needed.

CALLED BY:	Strategy Routine

PASS:		AX:BX = far pointer to a 27 bytes buffer.

RETURN:		up to 26 CD drive letters of CD rom drives stored to AX:BX.

DESTROYED:	-

SIDE EFFECTS:	-

PSEUDO CODE/STRATEGY: This function simply calls MSCDEX


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAGetDrives	proc	near
    push es, ax, bx
    mov  es, ax
    mov  al, 0x0d                          ; get CD drive letters
    mov  ah, 0x15
    int  0x2f
    pop  es, ax, bx
    ret
CDAGetDrives	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDAGetDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get drive header informations for all supported drives.
                From this information only the subunit number is needed.
                This is necessary because the OpenDos NWCDEX does not
                set the subunit numbers for device calls (as it should).
                This information is collected at driver initialisation
                so the entry in the strategy table is just for backward
                compatibility and no longer used.


CALLED BY:	Strategy Routine

PASS:		AX:BX = far pointer to an array of CD driver informations
                        This array must hold as much elements as drive
                        letters has been returned from CDAGetDrives().
                        Maximum is 26.

RETURN:		up to 26 CD driver information structures stored to AX:BX.
                Only the Subunit number information is used and valid.

DESTROYED:	-

SIDE EFFECTS:	-

PSEUDO CODE/STRATEGY: This function simply calls MSCDEX


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDAGetDriverInfo	proc	near
    push es, ax, bx
    mov  es, ax
    mov  al, 0x01                          ; get CD driver informations
    mov  ah, 0x15
    int  0x2f
    pop  es, ax, bx
    ret
CDAGetDriverInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDACallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a request to the CD driver using the (MS)CDEX API.

CALLED BY:	Strategy Routine
PASS:		AX:BX = far pointer to a properly set-up driver request
                        structure for the (MS)CDEX API.
                CL    = CD rom drive letter (for selecting the proper driver)

RETURN:		status byte in the driver request structure along with
                anything else that has been stored into this structure by
                (MS)CDEX or the CD device driver.

DESTROYED:	-

SIDE EFFECTS:	-

PSEUDO CODE/STRATEGY: This function simply calls MSCDEX


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG	28.07.97	Initial version
        JMG     27.11.98        Added test for proper MSCDEX version
                                Proper subunit number is generated

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDACallDriver	proc	near
    push es, ax, bx, cx
    mov  es, ax

    push ds,bx
    mov	 ax, segment dgroup
    mov	 ds, ax
    mov  al, ds:[mscdex_valid]

    xor  bx, bx
search:
    cmp  ds:[bx+drive_letters],cl
    je   found                             ; search drive number by letter
    inc  bx
    cmp  ds:[bx+drive_letters],0
    jne  search

found:
    mov ch,ds:[bx+driver_heads]            ; get subunit number
    pop  ds,bx

    mov es:[bx+1],ch                       ; set subunit number

    cmp  al, 0
    jz   ende                              ; is MSCDEX >= 2.1 ?

    mov  al,0x10                           ; MSCDEX Device_Request
    mov  ah,0x15
    mov  ch,0x00
    ; call SysLockBIOS                     ; *** really necessary
    int  0x2f                              ; call MSCDEX
    ; call SysUnlockBIOS                   ; *** really necessary ?

ende:
    pop  es, ax, bx, cx
    ret
CDACallDriver	endp



ResidentCode		ends



