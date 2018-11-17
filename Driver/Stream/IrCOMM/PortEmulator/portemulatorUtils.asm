COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		portemulatorUtils.asm

AUTHOR:		Greg Grisco, Dec  6, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	ECValidateUnitNumber	Checks the IrSerialPortData index
INT	UtilsGetPortData	Get offset to IrSerialPortData
INT	IrCommInitThread	Creates event thread for handling timer
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95   	Initial revision


DESCRIPTION:
	Utility routines for the Port Emulator module


	$Id: portemulatorUtils.asm,v 1.1 97/04/18 11:46:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetPortData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the offset of the IrSerialPortData for the
		port number.

CALLED BY:	INTERNAL
PASS:		bx	= port number
		ds	= dgroup
RETURN:		bx	= ptr to IrSerialPortData
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetPortData	proc	near
	.enter

	test	bx, SERIAL_PASSIVE
	mov	bx, offset irPort		; bx = offset to ISPD
	jz	done

	mov	ds:[bx].ISPD_passive, mask SPS_PASSIVE
done:
	.leave
	ret
UtilsGetPortData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateUnitNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for a valid unit number

CALLED BY:	EXTERNAL
PASS:		bx	= unit number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Currently, we only allow for one ircomm connection

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

ECValidateUnitNumber	proc	far
	uses	ax,bx,dx
	.enter

	cmp		bx, offset irPort
	ERROR_NE	IRCOMM_ILLEGAL_UNIT_NUMBER

	.leave
	ret
ECValidateUnitNumber	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommInitThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the event queue to which we'll send timer
		messages.

CALLED BY:	INTERNAL (SetupOutputStream)
PASS:		bx	= process handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommInitThread	proc	far
	uses	ax,bx,cx,dx,di,ds,es
	.enter

	call	IrCommGetDGroupDS			; ds = dgoup
	segmov	es, ds, ax

	tst	es:[threadHandle]
	jnz	exit					; already exists

	mov	bp, 0x400				; 1K stack size

	push	bx, es
	mov	bx, handle IrCommClassStructure
	call	MemDerefES
	mov	cx, es					; cx = class segment
	pop	bx, es

	mov	dx, offset IrCommProcessClass		; run by IrCommClass
	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	di, mask MF_CALL
	call	ObjMessage				; ax = thread handle
	jc	exit					; can't create thread
		
	mov	es:[threadHandle], ax			; save thread handle
	clc						; indicate success
exit:
	.leave
	ret
IrCommInitThread	endp

ResidentCode	ends
