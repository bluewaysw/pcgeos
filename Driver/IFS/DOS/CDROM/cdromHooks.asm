COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		cdromHooks.asm

AUTHOR:		Adam de Boor, Nov 21, 1992

ROUTINES:
	Name			Description
	----			-----------
	CDROMIdleHook		Let the network know the system is idle
	CDROMCriticalError	Catch network-related critical errors
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/21/92	Initial revision


DESCRIPTION:
	Interrupt hooks
		

	$Id: cdromHooks.asm,v 1.1 97/04/10 11:55:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CDROMCriticalError

DESCRIPTION:	Handle critical error from network

CALLED BY:	EXTERNAL
		INT 24h

PASS:
	ah - bit 7: 0 if disk error, otherwise 1
	al - drive number, if ah<7> is 0
	bp:si - address of device header control block
	di - lower byte - error code
	
	on stack:
		iret frame to caller of DOS
		es
		ds
		bp
		di
		si
		dx
		cx
		bx
		ax
		iret frame from "int 24h"	<- sp


RETURN:
	al - action code:
		0 - ignore error
		1 - retry operation
		2 - terminate program through INT 23h
		3 - Fail system call in progress

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/92		Initial version
-------------------------------------------------------------------------------@
CDROMCriticalError	proc	far
		push	bx, ax, ds
		call	LoadVarSegDS
	;
	; Check the DeviceHeader pointer against those we know about.
	; 
		push	cx
		mov	cx, ds:[numDrives]
		mov	bx, offset cdromDrives

checkOursLoop:
		test	ah, 80h			; character device?
		jnz	checkDeviceHeader	; yes

		cmp	ds:[bx].CDRD_number, al
		je	itsOurs
next:
		add	bx, size CDROMDrive
		loop	checkOursLoop
		
passItOn:
	;
	; Either not one of ours, or we want the user to know about it, so
	; pass it on to the previous handler.
	; 
		pop	cx
		mov	bx, offset cdromOldInt24
		jmp	CDROMPassOnInterrupt

checkDeviceHeader:
		cmp	bp, ds:[bx].CDRD_device.segment
		jne	next
		cmp	si, ds:[bx].CDRD_device.offset
		jne	next

itsOurs:
	; see if locking disk and fail request if so, else pass it on
		tst	ds:[failOnError]
		jz	passItOn

		pop	cx
		mov	ax, di
		add	ax, ERROR_WRITE_PROTECTED
		mov	bx, 1		; return carry set (primary driver will
					;  get extended error info, even on an
					;  FCB call, so...)
		call	FSDRecordError
		pop	bx, ax, ds
		mov	al, CR_FAIL
		iret
CDROMCriticalError	endp

Resident	ends
		
