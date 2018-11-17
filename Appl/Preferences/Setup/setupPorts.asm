COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefPorts.asm

AUTHOR:		Cheng, 8/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/90		Initial revision

DESCRIPTION:
		
	$Id: setupPorts.asm,v 1.1 97/04/04 16:27:57 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGetDriverStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain the driver strategy routine for the passed driver,
		based on what they can tell us, etc.

CALLED BY:	SetupInitSerial, SetupInitParallel

PASS:		bx	= handle of the driver
		di	= address at which to store the driver's strategy
			  routine

RETURN:		nothing

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/90	Initial version
	don	 7/ 1/91	Changed to just store strategy routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGetDriverStrategy proc	near
		.enter
	;
	; Fetch the strategy routine and store it away.
	;
		push	ds
		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	bx, ds:[si].DIS_strategy.segment
		pop	ds
		mov	ds:[di].offset, ax
		mov	ds:[di].segment, bx

		.leave
		ret
SetupGetDriverStrategy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDisableByMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable any ports in the table that don't have their bit set
		in the device map. We also now forcefully re-enable ports
		that are valid.

CALLED BY:	SetupEnableDisableSerial, SetupEnableDisableParallel
PASS:		ax	= device map
		dx	= table in cs of optrs of list entries to disable
		cx	= number of entries in table at cs:[dx]
RETURN:		nothing
DESTROYED:	ax, cx, si, bx, di, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version
	don	 7/01/91	Added enabling of valid ports

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDisableByMap proc	near
		.enter
		mov	si, dx
portLoop:
		push	ax		; save device map
		lodsw	cs:
		xchg	bx, ax		; bx <- chunk
		lodsw	cs:

		XchgTopStack	si	; si <- device map, save table offset
		xchg	ax, bx		; ax <- chunk, bx <- handle
		xchg	ax, si		; ax <- device map, si <- chunk

		push	ax, cx		; save device map, port counter
		test	ax, 1		; port enabled?
		mov	ax, MSG_GEN_SET_ENABLED
		jnz	setPortStatus	; enabled, so send the method
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setPortStatus:
		mov	dl, VUM_MANUAL
		clr	di
		call	ObjMessage
		pop	ax, cx		; restore important data

		pop	si
		shr	ax
		shr	ax
		loop	portLoop
		.leave
		ret
SetupDisableByMap endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupInitSerial

DESCRIPTION:	Initialize our interface with the serial driver. Leave all
		serial ports for the printer port selection enabled, as they
		may have weird interrupt levels that we don't know of.

CALLED BY:	SetupOpenApplication

PASS:		ds,es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

serialPorts	optr	Com1Item, Com2Item, Com3Item, Com4Item

SetupInitSerial	proc	near
	.enter

EC <	call    CheckDSDgroup                                           >
	mov	bx, handle serial
	mov	di, offset serialDriver
	call	SetupGetDriverStrategy		; obtain & store strategy rtn

	.leave
	ret
SetupInitSerial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupEnableDisableSerial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EnableDisable all serial ports in the PrinterPortScreen

CALLED BY:	SetupPrinterSelected

PASS:		ds	= dgroup
		dx	= device map of ports to disable

RETURN:		nothing

DESTROYED:	cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version
	don	 7/02/91	Deal with re-enabling ports

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupEnableDisableSerial proc	near
		uses	ax
		.enter

EC <		call    CheckDSDgroup					>
		xchg	ax, dx
		not	ax			; mask to AND device map with
		mov	cx, length serialPorts
		mov	dx, offset serialPorts
		call	SetupDisableByMap

		.leave
		ret
SetupEnableDisableSerial endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupInitParallel

DESCRIPTION:	Initialize our interface with the parallel driver, disabling
		all ports for the printer selection that don't actually exist.

CALLED BY:	SetupOpenApplication

PASS:		ds,es - dgroup

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@
parallelPorts	optr Lpt1Item, Lpt2Item, Lpt3Item

SetupInitParallel	proc	near
	.enter

EC <     call    CheckDSDgroup                                           >
	mov	bx, handle parallel
	mov	di, offset parallelDriver
	call	SetupGetDriverStrategy		; obtain & store strategy rtn

	.leave
	ret
SetupInitParallel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupEnableDisableParallel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EnableDisable all parallel ports in the PrinterPortScreen

CALLED BY:	SetupPrinterSelected

PASS:		ds	= dgroup
		dx	= device map of ports to disable

RETURN:		nothing

DESTROYED:	cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version
	don	 7/02/91	Deal with re-enabling ports

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupEnableDisableParallel proc	near
		uses	ax
		.enter

EC <		call    CheckDSDgroup					>
		mov	di, DR_STREAM_GET_DEVICE_MAP
		call	ds:[parallelDriver]	; get the parallel device map
		not	dx			; mask to AND device map with
		and	ax, dx			; device map to enable => AX
		mov	cx, length parallelPorts
		mov	dx, offset parallelPorts
		call	SetupDisableByMap
		
		.leave
		ret
SetupEnableDisableParallel endp
