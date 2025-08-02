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

		; do any device-specific initialization

		;call	VidSetVESAFar
		mov	al, ds:[cursorCount]
		push	ax
		mov	dx, cs
		mov	si, 0
		mov	di, DRE_SET_DEVICE
		call	VidCallMod

		; now that device-specific initialization is out of the way,
		; do some common stuff, like showing the cursor

		;mov	ds:[cursorCount],1	;start hidden
		;mov	si, -1			; start with default cursor
		;call	VidSetPtrFar
		;mov	ds:[videoEnabled], 1	; video is ON
		pop	ax
		mov	ds:[cursorCount], al
done:
		.leave
		mov	di, 0		; function executed
		ret
VidEscSetDeviceAgain 	endp
