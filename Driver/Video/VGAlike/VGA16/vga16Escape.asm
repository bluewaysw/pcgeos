COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Cyber16 Video Driver
FILE:		cyber16Escape.asm

AUTHOR:		Allen Yuen, Mar 25, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99   	Initial revision


DESCRIPTION:
		
	Escape functions specifically for Cyber16

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidEscSetDeviceAgain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new video mode for the driver.

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		none

RETURN:		none

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		This function sets the current device and initializes it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidEscSetDeviceAgain 	proc	near
		uses	ax, bx, cx, ds, bp, si, ds
		.enter
		mov	ax, dgroup
		mov	ds, ax
		mov	di, ds:[DriverTable].VDI_device	; save it
		cmp	di, 0xFFFF
		je	done

		;
		; Keep the pointer off-screen while the mode is reset.
		; VidMovePtr balances this hide after the new pointer window
		; has been established.
		;
		mov	al, cs:[cursorCount]
		push	ax
		call	VidHidePtr

		; do any device-specific initialization
		mov	dx, cs
		mov	si, 0
		mov	di, DRE_SET_DEVICE
		call	VidCallMod

		pop	ax
		inc	al
		mov	cs:[cursorCount], al
		mov	cs:[updateHideCount], al
done:
		.leave
		mov	di, 0		; function executed
		ret
VidEscSetDeviceAgain 	endp
