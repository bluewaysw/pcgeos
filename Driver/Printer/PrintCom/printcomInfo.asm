COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Printer drivers
FILE:		printcomInfo.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	PrintDriverInfo		Get handle to driver info table
	PrintDeviceInfo		Get handle to device info table
	PrintTestDevice		Test for the device
	PrintSetDevice		Set the device to use
	PrintSetMode		Set the print mode to use
	PrintSetStream		Setup stream-related info

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	2/90	initial verison

DESCRIPTION:
	This file contains the entry point routine for the printer drivers.
		
	$Id: printcomInfo.asm,v 1.1 97/04/18 11:50:09 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a pointer to the driver info block

CALLED BY:	GLOBAL

PASS:		bp	- PState segment

RETURN:		dx:si	- handle:offset to info block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just stuff the handle and offset;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
PrintGetDriverInfo proc	near
		mov	dx, handle DriverInfo	; return handle of info block
		clr	si			; starts at beginning of block
		clc				; no errors
		ret
PrintGetDriverInfo endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDeviceInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a pointer to the device info block

CALLED BY:	GLOBAL

PASS:		bp	- PState segment

RETURN:		dx:si	- handle:offset to device info block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the PState;
		Get the device type;
		lock the DriverInfo block;
		Get the handle to the device info block;
		Unlock the PState and Driver Info blocks;
		return the handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
PrintDeviceInfo	proc	near
		uses	ds
		.enter

		mov	ds, bp			; ds -> PState
		mov	dx, ds:[PS_deviceInfo]	; get handle to info
		clr	si			; at offset zero in block
		clc				; no errors
		
		.leave
		ret
PrintDeviceInfo	endp


ifndef PRINTER_CAN_TEST_DEVICE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Trivial routine to inform the caller that this driver has
		no *idea* whether there's a printer of the given type out
		there.

CALLED BY:	DRE_TEST_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		ax	= DevicePresent code (always DP_CANT_TELL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version (in mouse driver)
	jim	12/4/90		Copied from mouse driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintTestDevice	proc	near
		.enter
		mov	ax, DP_CANT_TELL
		clc
		.leave
		ret
PrintTestDevice	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a specific device to use in the PState

CALLED BY:	GLOBAL

PASS:		bp	- PState segment	
		dx:si	- pointer to null-terminated device name string

RETURN:		ax	- DP_INVALID_DEVICE if bad string passed
			  DP_PRESENT if device set correctly

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		Set the handle and enum into the PState

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version
	Jim	12/90		Updated for extended driver format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetDevice	proc	near
		uses	es, ds, ax
		.enter

		EnumerateDevice DriverInfo	; map string to device enum
		jc	done			; does not exist
		mov	ds, bp			; ds -> PState
		mov	ds:[PS_device], di	; set the device enum
		mov	bx, es:[DEIT_infoTable] ; get pointer to info table
		mov	ax, es:[bx][di]		; get handle
		mov	ds:[PS_deviceInfo], ax	; store handle to info block
		mov	bx, handle DriverInfo	; get handle to table
		call	MemUnlock
		mov	ax, DP_PRESENT		; 
		clc				; no errors
done:
		.leave
		ret
PrintSetDevice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a specific printing mode

CALLED BY:	GLOBAL

PASS:		bp	- PState segment	
		cl	- mode to set (one of PrinterModes enum)
		ax	= paper width  (points)
		si	= paper height (points)
		
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set the mode in the PState

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetMode	proc	near
		uses	ds
		.enter

		mov	ds, bp			; ds -> PState
		mov	ds:[PS_mode], cl	; set the device mode

		mov	ds:[PS_customWidth], ax	; set width and height
		mov	ds:[PS_customHeight], si

		; check for text mode printing and do some initialization
		cmp	cl, PM_FIRST_TEXT_MODE	; are we there ?
		jb	done			;  no init needed
		
		; Init the translation buffer in the pstate

		push	ax,bx,es,ds,di		; save another segment
		mov	es, bp			; es -> PState
		clr	ax			; init to all zeroes
		mov	cx, 128			; asciiTrans/2 words to init
		mov	di, PS_asciiTrans	; es:di -> trans table
		rep	stosw			; clear out table
		mov	bx, handle DriverInfo	; get handle to resource
		call	MemLock	; lock it down
		mov	ds, ax			; ds -> resource
		mov	si, size DriverExtendedInfoTable
		mov	si, ds:[si].PDI_asciiTransChars ; get chunk handle
		mov	si, ds:[si]		; get pointer to chunk
		ChunkSizePtr ds, si, cx		; cx = chunk size
		shr	cx, 1			; see how many pairs
		shr	cx, 1
		jcxz	doneTransChars
transCharLoop:
		lodsw				; get next translation pair
		mov	di, ax			; set up dest index
		and	di, 0xff
		mov	es:[PS_asciiTrans][di], ah ; store translation byte
		add	si, 2			; bump past delimiter
		loop	transCharLoop
doneTransChars:
		call	MemUnlock			; free the resource
		pop	ax,bx,es,ds,di			; save another segment
done:
		clc				; no errors
		.leave
		ret
PrintSetMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a specific printing mode

CALLED BY:	GLOBAL

PASS:		bp	- PState segment	
		cx	- stream token
		dx	- stream device driver handle
		si	- stream device type (PrinterPortType enum)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Store the token;
		Call to get the address of the strategy routine for the 
		stream driver, and store it too;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetStream  proc	near
	 	uses	ds, bx, si
		.enter

		; just set the pstate variable

		mov	ds, bp			; ds -> PState
		mov	ds:[PS_streamToken], cx	; set the token
		mov	ds:[PS_streamType], si	; set the type

		; call to get the address of the strategy routine.  If 
		; handle is zero, skip the call (the stream type is not one
		; that has a driver attached)

		tst	dx			; test handle
		jz	done
		push	ds			; save PState address
		mov	bx, dx			; bx = driver handle
		call	GeodeInfoDriver		; get pointer to info block
		mov     bx, ds:[si].DIS_strategy.offset
		mov     si, ds:[si].DIS_strategy.segment
		pop	ds			; restore PState ptr
		mov	ds:[PS_streamStrategy].offset, bx ; set up pointer
		mov	ds:[PS_streamStrategy].segment, si 

		; call a driver-specific routine to do any other initialization
		; required.
done:
		call	PrintInitStream		; driver specific

		.leave
		ret
PrintSetStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintHomeCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HomeCursor sets the PSTATE cursor position to zero.

CALLED BY: 	GLOBAL
		PrintStartPage

PASS: 		bp	- Segment of PSTATE

RETURN: 	nothing

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintHomeCursor	proc	far
		uses	es
		.enter
		mov	es, bp		;get PSTATE segment
		mov	es:[PS_cursorPos].P_x, 0
		mov	es:[PS_cursorPos].P_y, 0
		clc				; no errors
		.leave
		ret
PrintHomeCursor	endp
