COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeDriver.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GeodeFreeDriver		Free a driver
   GLB	GeodeInfoDriver		Return information about a driver
   GLB	GeodeInfoDefaultDriver	Return information about default drivers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle drivers.

	$Id: geodesDriver.asm,v 1.1 97/04/05 01:11:57 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GeodeGetDefaultDriver

DESCRIPTION:	Return information about default drivers

CALLED BY:	GLOBAL

PASS:
	ax - GeodeDefaultDriverType

RETURN:
	ax - handle default driver

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	mike	2/89		added code for serial driver
-------------------------------------------------------------------------------@

GeodeGetDefaultDriver	proc	far
	push	ds

EC<	cmp	ax, GeodeDefaultDriverType				>
EC<	ERROR_AE	GEODE_GET_DEF_DRIVER_BAD_TYPE			>
EC<	test	ax, 1							>
EC<	ERROR_NZ	GEODE_GET_DEF_DRIVER_BAD_TYPE			>

	LoadVarSeg	ds
	xchg	ax, bx
	mov	bx, {word} ds:[defaultDrivers][bx]
	xchg	ax, bx
	pop	ds
	ret

GeodeGetDefaultDriver	endp

GLoad	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GeodeSetDefaultDriver

DESCRIPTION:	Sets the specified default driver

CALLED BY:	GLOBAL

PASS:		ax - GeodeDefaultDriverType
		bx - handle

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

GeodeSetDefaultDriver	proc	far
	uses	di, si, ds
	.enter
	LoadVarSeg	ds

EC<	cmp	ax, GeodeDefaultDriverType				>
EC<	ERROR_AE	GEODE_SET_DEF_DRIVER_BAD_TYPE			>
EC<	test	ax, 1							>
EC<	ERROR_NZ	GEODE_SET_DEF_DRIVER_BAD_TYPE			>

	; If the driver is of type video, task, or keyboard, we need to also
	; store the address of the strategy routine.

	mov	di, offset defaultVideoStrategy
	cmp	ax, GDDT_VIDEO		; for video, set the default strategy
	je	storeStrategy

	mov	di, offset taskDriverStrategy
	cmp	ax, GDDT_TASK
	je	storeStrategy

	mov	di, offset kbdStrategy
	cmp	ax, GDDT_KEYBOARD
	jne	setDefaultDriver

	; If the driver is a video driver, set the defaultVideoStrategy variable
	; in idata. (ds already pointing there)

storeStrategy:
	push	ax
	call	GeodeInfoDriver		; get pointer to info struct
	mov	ax, ds:[si].DIS_strategy.offset ; copy the routine address
	mov	si, ds:[si].DIS_strategy.segment
	LoadVarSeg ds
	mov	ds:[di].offset, ax
	mov	ds:[di].segment, si
	pop	ax

setDefaultDriver:
	mov	si, ax
	mov	{word} ds:[defaultDrivers][si], bx

	.leave
	ret
GeodeSetDefaultDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeUseDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to GeodeUseLibrary, dynamically loads a driver
		given its file name.

CALLED BY:	GLOBAL
PASS:		ds:si	= filename of driver to load.
			(file name *can* be in movable XIP code resource)
		ax	= expected major protocol number (0 => any ok)
		bx	= expected minor protocol number
RETURN:		if carry set:
			ax = GeodeLoadError describing problem
		else
			bx = handle of library/driver
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <CopyStackCodeXIP	segment						>
GeodeUseDriver	proc	far
		push	dx
		clr	dx			; indicate ds:si is file name
		FALL_THRU	GeodeUseDriverCommon, dx
GeodeUseDriver	endp

GeodeUseDriverCommon	proc	far
		push	cx
		mov	cx, mask GA_DRIVER
		call	UseLibraryDriverCommon
		pop	cx
		FALL_THRU_POP	dx
		ret
GeodeUseDriverCommon	endp
FXIP <CopyStackCodeXIP	ends						>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeUseDriverPermName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to GeodeUseLibraryPermName, dynamically uses a
		driver given its permanent name.

CALLED BY:	GLOBAL
PASS:		ds:si	= driver permanent geode name (GEODE_NAME_SIZE)
			  (*can* be in movable XIP code resource)
RETURN:		if carry set:
			ax = GeodeLoadError describing problem
		else
			bx = handle of library/driver
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Call UseLibraryDriverCommon, passing dx = nonzero


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Administrator	8/10/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <CopyStackCodeXIP	segment						>
GeodeUseDriverPermName	proc	far
		push	dx
		mov	dx, TRUE	; indicate ds:si is permanent name
		GOTO	GeodeUseDriverCommon, dx
GeodeUseDriverPermName	endp
FXIP <CopyStackCodeXIP	ends						>
GLoad	ends

