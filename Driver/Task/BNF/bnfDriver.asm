COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfDriver.asm

AUTHOR:		Adam de Boor, Oct  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	TaskDRInit		verify switcher is present and initialize it
	TaskDRExit		close down our control of the switcher
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/4/91		Initial revision


DESCRIPTION:
	Switcher-specific driver routines.
		

	$Id: bnfDriver.asm,v 1.1 97/04/18 11:58:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing initialization routine. All the real work is done
		during DRE_TEST_DEVICE and DRE_SET_DEVICE now.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrInit	proc	near
		.enter
		clc
		.leave
		ret
TaskDrInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the switcher we're supposed to drive is loaded

CALLED BY:	TaskStrategy
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		ax	= DevicePresent
		carry set if DP_INVALID_DEVICE, clear otherwise
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrTestDevice proc	near
		uses	bx, cx, dx, ds
		.enter
		segmov	ds, dgroup, ax
	;
	; See if the beast is installed. This is valid for all versions of
	; DOS as int 12h is just the memory-size determination interrupt...
	; 
		mov	cx, BNF_MAGIC
		mov	ax, cx
		mov	bx, BNFAPI_CHECK_INSTALL
		int	12h
		
		cmp	ax, BNF_IS_LOADED
		jne	error

		mov	ds:[taskProcessStartupOK], TRUE
		mov	ax, DP_PRESENT
done:
	;
	; Let our process thread go, now that taskProcessStartupOK is set
	; properly.
	; 
		VSem	ds, taskProcessStartupSem
		clc
		.leave
		ret
error:
		mov	ax, DP_NOT_PRESENT
		jmp	done
TaskDrTestDevice endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Now put our hooks into TaskMax

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		We might, at some point, need to use the DOS 5 API call to
		suspend the switcher, in case the user has gotten B&F Pro
		and installed their little whats-it that allows the beast to
		keep control of the hotkeys.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrSetDevice proc	near
		.enter
		clc
		.leave
		ret
TaskDrSetDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves.

CALLED BY:	TaskStrategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrExit	proc	near
		.enter
		clc
		.leave
		ret
TaskDrExit	endp

Resident	ends
