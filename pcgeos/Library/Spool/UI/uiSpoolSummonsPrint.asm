COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Spool/UI
FILE:		uiSpoolSummonsPrint.asm

AUTHOR:		Don Reeves, March 30, 1990

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial revision


DESCRIPTION:
	Contains all the procedures & method handlers that retrieve
	information from the printer drivers and .INI file(s).
		
	$Id: uiSpoolSummonsPrint.asm,v 1.1 97/04/07 11:10:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsPrinterInstalledRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that a printer device was added or removed

CALLED BY:	GLOBAL (MSG_PRINTER_INSTALLED_REMOVED)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsPrinterInstalledRemoved	method dynamic	SpoolSummonsClass,
					MSG_PRINTER_INSTALLED_REMOVED

	; If there are no more printers, close the print dialog.  
	; Otherwise, just re-initialize.
	;
	or	ds:[di].SSI_flags, mask SSF_RELOAD_PRINTER_LIST

	mov	cx, PDT_ALL_LOCAL_AND_NETWORK
	call	SpoolGetNumPrinters
	tst	ax
	jz	bringDown

	call	SpoolSummonsInitialize
	jmp	exit

bringDown:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	si, offset PrinterChangeBox
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	si, offset PrintDialogBox
	call	ObjCallInstanceNoLock

exit:
	ret
SpoolSummonsPrinterInstalledRemoved	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsRequestPrinterMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker (a printer name) for a single list entry

CALLED BY:	UI (MSG_META_GEN_LIST_REQUEST_ENTRY_MONIKER)

PASS:		DS:*SI	= SpoolSummons object
		DS:DI   = SpoolSummons instance data
		CX:DX	= OD of the dynamic list
		BP	= Requested entry #

RETURN:		Nothing	(but a method is sent back)

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsRequestPrinterMoniker	method	dynamic SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_REQUEST_PRINTER_MONIKER
	.enter

	;
	; Make sure we've actually got a printer
	tst	ds:[di].SSI_printDataHan
	jz	done

	; Access the printer strings
	;
	push	si				; save the SpoolSummons chunk
	push	ds, dx				; save the GenDynamicList OD
	call	SSOpenPrintStrings		; lock the file, etc...
	mov	dx, bp				; printer number => DX
	call	SpoolSummonsGetPrinterCategory	; string => DS:SI
						; string length => CX
	; Send method to the GenDynamicList
	;
	mov	cx, ds
	mov	dx, si				; printer name => CX:DX
	pop	ds, si				; GenDynamicList OD => DS:SI
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	ObjCallInstanceNoLock		; send the message
	
	; Finally, unlock the strings block
	;
	pop	si				; restore SpoolSummons chunk
	call	SSClosePrintStrings		; close the print strings
done:
	.leave
	ret
SpoolSummonsRequestPrinterMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsLoadPrinters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load all the available printers from the .INI file

CALLED BY:	GLOBAL

PASS: 		DS:*SI	= SpoolSummons instance data
		
RETURN:		AX	= Number of VALID printers
		CX	= Number of printers
		DX	= Currently selected printer
		DS:DI	= SpoolSummonsInstance		

		Carry	= Set if need to reset everything
			= Clear if nothing has changed

DESTROYED:	BX

PSEUDO CODE/STRATEGY:
		Should be called each time the SpoolSummons comes on screen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsLoadPrinters	proc	near
	class	SpoolSummonsClass
	uses	bp, es
	.enter

	; See if we need to reload our data
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	test	ds:[di].SSI_flags, mask SSF_RELOAD_PRINTER_LIST
	jz	exit				; if no changes, do nothing

	; First remove the old UI, if necessary
	;
	andnf	ds:[di].SSI_flags, not (mask SSF_RELOAD_PRINTER_LIST)
	mov	cx, ds:[di].SSI_currentPrinter	; printer # => CX
	call	RemovePrinterUIBoth		; remove all current UI

	; Load all the names of the printer devices into a block
	;
	call	SpoolSummonsLoadPrinterNames	; # of devices => AX
						; memory block => BX
						; memory block size => CX
						; default system printer => DI

	; Store away the data
	;
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].SpoolSummons_offset	; access my instance data
	mov	ds:[bp].SSI_numPrinters, ax	; store number of printers
	xchg	ds:[bp].SSI_printDataHan, bx	; and the printers data handle
	mov	ds:[bp].SSI_printDataLen, cx	; and the length of the data
	mov	ds:[bp].SSI_sysDefPrinter, di	; store the system's default
	mov	dx, ds:[bp].SSI_appDefPrinter	; application default => DX
	mov	cx, ax				; number of printers => CX & AX
	tst	bx				; was there an old data handle
	jz	done				; no, so go on
	call	MemFree				; else free this block handle

	; Exit here
done:
	call	SpoolSummonsLoadInfo		; load all the information
	call	SpoolSummonsAssignDefault	; assign the default printer
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access my instance data
	mov	ax, ds:[di].SSI_numValidPrinters
	mov	ds:[di].SSI_currentPrinter, -1	; reset the current printer
	stc					; must reset everything
exit:
	.leave
	ret
SpoolSummonsLoadPrinters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsLoadPrinterNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the printer names for the current driver type

CALLED BY:	SpoolSummonsLoadPrinters

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		AX	= Number of devices
		BX	= Handle of block holding device strings (NULL if none)
		CX	= Size of memory block
		DI	= Default system printer

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsLoadPrinterNames	proc	near
		class	SpoolSummonsClass
		uses	si, es
		.enter
	
		; Get the number of device available
		;
		mov	di, ds:[si]
		add	di, ds:[di].SpoolSummons_offset
		mov	cl, ds:[di].SSI_driverType
		mov	dh, cl
		clr	ch
		call	SpoolGetNumPrinters	; number of printers => AX
		tst	ax
		jz	error

		; Allocate a block large enough to hold the device strings
		;
		push	ax
		mov	cl, GEODE_MAX_DEVICE_NAME_SIZE
		mul	cl			; # of byte => AX
		mov	si, ax
		mov	bx, ds:[LMBH_handle]
		call	MemOwner		; owner (app process) => BX
		mov	cx, mask HF_SHARABLE or mask HF_SWAPABLE or \
				((mask HAF_LOCK) shl 8)
		call	MemAllocSetOwner
		pop	bp			; max # of printers => BP
		jc	error			; if no memory, fail

		; Load the printer names, one by one. Register usage:
		;	AX	= Printer #
		;	CX	= Valid # of printers
		;	DH	= PrinterDeviceType we want
		;	BP	= Total # of printers
		;	ES:DI	= Buffer for printer names
		;
		mov	es, ax
		clr	ax, cx, di
stringLoop:
		push	cx
		call	SpoolGetPrinterString	; fill buffer with string
		pop	cx
		jc	noMore
		inc	ax
		cmp	dh, PDT_ALL		; if looking for all devices
		je	havePrinter		; ...then skip none
		cmp	dl, dh			; else compare device types
		jne	stringLoop		; ...and skip mismatches
havePrinter:
		inc	cx
		cmp	cx, bp
		je	noMore
		add	di, GEODE_MAX_DEVICE_NAME_SIZE
		jmp	stringLoop

		; OK, we've loaded all of the printers. Clean up &
		; choose the default printer. If we have PDT_ALL or
		; PDT_PRINTER, use the value in the .INI file. Else,
		; choose the first device.
noMore:
		call	MemUnlock		; unlock device strings block
		call	SpoolGetDefaultPrinter	; default printer => AX
		cmp	dh, PDT_PRINTER		; if device = printer
		je	done			; ...use returned value
		clr	ax			; else use first device
done:
		mov_tr	di, ax			; default => DI
		mov_tr	ax, cx			; # of devices => AX
		mov	cx, si			; size of block => CX
exit:
		.leave
		ret

		; Some sort of error was returned. Abort, abort.
error:
		clr	ax, bx, cx, di
		jmp	exit
SpoolSummonsLoadPrinterNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsLoadInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load all the information about every printer

CALLED BY:	SpoolSummonsLoadPrinters
	
PASS:		DS:*SI	= SpoolSummonsClass instance data

RETURN:		AX	= Chunk handle to the PrinterInfoTable
			= 0 if no printers

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/90		Initial version
	Don	4/18/91		Only initialize structures - load no printers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsLoadInfo	proc	near
	class	SpoolSummonsClass
	uses	cx, dx, di
	.enter

	; Destroy the old handle, allocate a new buffer
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset
	mov	cx, ds:[di].SSI_numPrinters	; number of printers => CX 
	clr	ax
	xchg	ax, ds:[di].SSI_printInfoChunk
	mov	ds:[di].SSI_numValidPrinters, 0	; assume no valid printers
	tst	ax				; invalid handle ??
	jz	getNew				; yes, so jump
	call	LMemFree			; free the chunk
	clr	ax				; now there's no handle
getNew:
	jcxz	done				; no printers (AX = 0)
	push	cx				; save the number if printers
	mov	al, size PrinterInfoStruct
	mul	cl				; assume < 256 printers
	mov	cx, ax				; size => CX
	mov	al, mask OCF_IGNORE_DIRTY	; ignore dirty
	call	LMemAlloc			; allocate the chunk
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	mov	ds:[di].SSI_printInfoChunk, ax	; store the new chunk
	pop	cx				; number of printers => CX

	; Initialize all the PrinterInfoStructs
	;
	mov	di, ax				; information chunk => DI
	mov	di, ds:[di]			; dereference handle
initLoop:
	mov	ds:[di].PIS_info, 0		; not initialized
	add	di, size PrinterInfoStruct	; go to the next structure
	loop	initLoop
done:
	.leave
	ret
SpoolSummonsLoadInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsAssignDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign the default printer, based upon the application's
		desires and what printers are valid

CALLED BY:	SpoolSummonsLoadPrinters
	
PASS:		DS:*SI	= SpoolSummonClass instance data
		AX	= PrinterInfoChunk handle
		CX	= Number of printers
		DX	= Application default printer
		DI	= System default printer

RETURN:		DX	= Default printer

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/18/90		Initial version
	Don	4/18/91		Call standard routine to load printer info

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsAssignDefault	proc	near
	uses	cx
	.enter

	; Test the default case
	;
	tst	ax				; any information chunk
	jz	done
	cmp	dx, -1				; no application default ??
	jne	defaultLoop
	mov	dx, di				; else use system default
	jmp	defaultLoop

	; Find a default printer
startLoop:
	clr	ax, dx				; start at printer zero
defaultLoop:
	xchg	cx, dx
	call	AccessPrinterInfoStruct
	xchg	cx, dx
	jc	tryAnother			; if invalid, try another
	test	ds:[di].PIS_info, mask SSPI_VALID
	jnz	done
tryAnother:
	tst	ax
	jnz	startLoop
	inc	dx				; go to the next printer
	loop	defaultLoop
	mov	dx, -1				; no default found = ouch!
done:
	.leave
	ret
SpoolSummonsAssignDefault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrinterCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the appropriate printer category string

CALLED BY:	GLOBAL

PASS:		DS:DI	= Printer data strings
		CX	= Number of bytes in the strings block
		DX	= Number of string to access (0 is the first)
		
RETURN:		DS:SI	= Requested string
		CX	= Length of the string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSGetPrinterCategory	proc	far
	call	SpoolSummonsGetPrinterCategory
	ret
SSGetPrinterCategory	endp

SpoolSummonsGetPrinterCategory	proc	near
	uses	ax, di, es
	.enter

	; Now that the printer names are stored in an array, this is simple
	;
EC <	cmp	dx, MAXIMUM_NUMBER_OF_PRINTERS				>
EC <	ERROR_A	SPOOL_SUMMONS_TOO_MANY_PRINTERS				>
	mov	al, GEODE_MAX_DEVICE_NAME_SIZE
	mul	dl
	mov	si, ax				; printer name => DS:SI

	; Now calculate the length of the string
	;
	segmov	es, ds
	mov	di, ax				; start of string => ES:DI
	call	LocalStringLength		; cx <- length w/o NULL

	.leave
	ret
SpoolSummonsGetPrinterCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the printer information for a specific printer

CALLED BY:	SpoolSummonsPrinterSelected
	
PASS:		DS:*SI	= SpoolSummonsClass instance data
		CX	= Printer number

RETURN:		CL	= PaperInputOptions
		CH	= Maximum PaperSizes
		DL	= Printer attributes
		DH	= SpoolSummonsPrinterInfo
			  (If not valid, CX contains the PRINT_CONTROL_ERROR
			   enumerated type to use in an error box)

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPrinterInfo	proc	near
	uses	ax
	.enter

	; Now get out the information
	;
	clr	dx				; assume no printers
	call	AccessPrinterInfoStruct
	mov	cx, PCERR_NO_PRINTERS		; assume no printers
	jc	done				; fail if error
	mov	dl, ds:[di].PIS_POM
	mov	dh, ds:[di].PIS_info
	mov	cx, ds:[di].PIS_error		; error, just in case
done:
	.leave
	ret
SpoolSummonsGetPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPrinterInfoStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns pointer to the proper PrinterInfoStruct

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= SpoolSummonsClass specific instance data
		CX	= Printer number (0 to MAXIMUM_NUMBER_OF_PRINTERS)

RETURN:		DS:DI	= PrinterInfoStruct
		Carry	= Set if no such printer

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AccessPrinterInfoStruct	proc	near
	class	SpoolSummonsClass
	uses	ax, cx
	.enter

	; Access the correct PrinterInfoStruct
	;
EC <	cmp	cx, MAXIMUM_NUMBER_OF_PRINTERS				>
EC <	ERROR_A	SPOOL_SUMMONS_TOO_MANY_PRINTERS				>
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	cmp	cx, ds:[di].SSI_numPrinters	; if printer # too large, error
	jae	error				; printer # too large!
	push	cx				; save printer number
	mov	di, ds:[di].SSI_printInfoChunk	; table chunk => DI
	mov	di, ds:[di]			; dereference the chunk
	mov	al, size PrinterInfoStruct
	mul	cl
	add	di, ax				; DS:DI => PrinterInfoStruct
	pop	cx				; printer number => CX
	test	ds:[di].PIS_info, mask SSPI_INITIALIZED
	jnz	done
	call	LoadPrinterInfo			; load printer information
done:
	.leave
	ret

error:
	stc
	jmp	done
AccessPrinterInfoStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the printer information for a specific printer

CALLED BY:	AccessPrinterInfoStruct
	
PASS:		DS:*SI	= SpoolSummonClass instance data
		DS:DI	= PrinterInfoStruct
		CX	= Printer number

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadPrinterInfo	proc	near
	uses	ax, bx, cx, dx, di, es
	class	SpoolSummonsClass
	.enter

	; Some set-up work
	;
	push	si				; save the SpoolSummons chunk
	segmov	es, ds				; PrinterInfoStruct => ES:DI
	or	es:[di].PIS_info, mask SSPI_INITIALIZED
	push	di, cx
	call	SSOpenPrintStrings		; open the print strings
	pop	dx				; printer number => DX
	call	SpoolSummonsGetPrinterCategory	; device name => DS:SI
	pop	di				; PrinterInfoStruct => ES:DI
	ConvPrinterNameToIniCat
	; Now grab all the specific information
	;
	call	GrabPrinterInfo			; grab the printer information
	ConvPrinterNameDone

	; Now clean up
	;
	segmov	ds, es				; PrinterInfoStruct => DS:DI
	pop	si				; restore the chunk handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access my instance data
	test	dl, mask SSPI_VALID		; valid printer ??
	jz	done	
	inc	ds:[di].SSI_numValidPrinters
done:
	call	SSClosePrintStrings		; unlock the string block

	.leave
	ret
LoadPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab specific information from the printer

CALLED BY:	LoadPrinterInfo

PASS:		DS:SI	= Printer name string
		ES:DI	= PrinterInfoStruct

RETURN:		DL	= SpoolSummonsPrinterInfo
				SSPI_VALID is important

DESTROYED:	AX, CX, DH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/11/90		Initial version
	Don	5/9/90		Perform some wonderful error checking
	Don	2/22/91		Cleaned up the code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ssPortString	byte	'port', 0

GrabPrinterInfo	proc	near
	uses	bx, bp, ds, es, si
SBCS <	deviceName	local	(MAX_DEVICE_NAME_SIZE) dup (char)	>
DBCS <	deviceName	local	(MAX_DEVICE_NAME_SIZE) dup (wchar)	>
	driverStrategy	local	fptr.far
	printInfo	local	SpoolSummonsPrinterInfo
	.enter

	; Determine if we are printing to a file or not
	;
	mov	printInfo, 0			; initalize to zero
	push	es, di, bp			; save local variable staff
	mov	cx, cs
	mov	dx, offset SpoolSummonsCode:ssPortString
	segmov	es, ss	
	lea	di, ss:[deviceName]		; ES:DI is the buffer (temp)
SBCS <	mov	bp,(MAX_DEVICE_NAME_SIZE) or INITFILE_UPCASE_CHARS>
DBCS <	mov	bp,(MAX_DEVICE_NAME_SIZE*(size wchar)) or INITFILE_UPCASE_CHARS>
	call	InitFileReadString
	pop	bp				; local variables => BP
	jc	getDriverName			; if failure, give up
SBCS <	cmp	{char} es:[di], 'F'		; F as in "FILE" ??	>
DBCS <	cmp	{wchar} es:[di], 'F'		; F as in "FILE" ??	>
	jne	getDriverName
	or	printInfo, mask SSPI_PRINT_TO_FILE

	; Get the driver name (SpoolSummonsPrinterInfo in AL)
getDriverName:
	call	SpoolLoadDriverLow		; load the printer driver
	pop	es, di				; restore saved data
	jc	fail

	; Access the PrintDriverInfo block
	;
	mov	driverStrategy.offset, cx
	mov	driverStrategy.segment, dx	; store the FAR address
	push	bx				; save the Driver handle
	xchg	ax, bx				; PState handle => BX
	push	di				; save the PrinterInfoStruct
	mov	di, DR_PRINT_DRIVER_INFO
	call	driverStrategy			; PrintDriverInfo => DX:SI
	xchg	bx, dx
	call	MemLock
	add	si, size DriverExtendedInfoTable
	mov	ds, ax				; PrintDriverInfo => DS:SI
	pop	di				; PrinterInfoStruct => ES:DI
	push	di
	call	CopyDriverInfo			; copy the driver information
	call	MemUnlock
	mov	bx, dx				; PState handle => BX

	; Access the PrinterInfo block for this specific printer
	;
	mov	di, DR_PRINT_DEVICE_INFO	; get the print device info
	call	driverStrategy			; PrinterInfo => DX:SI
	call	MemFree				; free the PState
	mov	bx, dx				; PrinterInfo handle => BX
	tst	bx				; if null handle returned,
	jz	deviceInvalid			; ...device is bogus
	call	MemLock				; lock the handle
	mov	ds, ax				; DS:SI => PrinterInfo
	pop	di				; ES:DI => PrinterInfoStruct
	call	CopyPrinterInfo			; copy all the data over
	call	MemUnlock			; unlock the PrinterInfo
	mov	dl, mask SSPI_VALID
freeDriver:
	pop	bx				; restore the Driver Handle
	push	ds
	segmov	ds,es
	call	SpoolFreeDriver			; free up the driver
	pop	ds
	jmp	done				; and we're done

	; Assume after this point that PrinterInfoStruct is in ES:DI
fail:
	mov	es:[di].PIS_error, ax		; store cause of error
	clr	dl
done:
	or	dl, printInfo			; include earlier information
	or	es:[di].PIS_info, dl		; store SSPI_VALID or not

	.leave
	ret

	; Handle invalid device case (SpoolLoadDriverLow will never
	; catch this case because UserLoadExtendedDriver does not)
deviceInvalid:
	pop	di				; ES:DI => PrinterInfoStruct
	mov	es:[di].PIS_error, PCERR_PRINTER_NOT_KNOWN
	clr	dl				; don't set SSPI_VALID
	jmp	freeDriver
GrabPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolLoadDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a printer driver

CALLED BY:	EXTERNAL

PASS:		*DS:SI	= SpoolSummonsClass object
		DX	= Printer number

RETURN:		see SpoolLoadDriverLow

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolLoadDriver	proc	near
	uses	di
	.enter
	
	; Set up for lower-level call
	;
	push	ds, dx				; save segment, printer number
	call	SSOpenPrintStrings
	pop	dx
	call	SpoolSummonsGetPrinterCategory	; printer category => DS:SI
	ConvPrinterNameToIniCat
	call	SpoolLoadDriverLow		; load the printer driver
	ConvPrinterNameDone

	; Clean up
	;
	pop	ds
	pushf					; save carry result
	mov	si, offset PrintDialogBox	; SpoolSummonsClass => DS:*SI
	call	SSClosePrintStrings

	popf					; restore carry

	.leave
	ret
SpoolLoadDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolFreeDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a driver

CALLED BY:	UTILITY

PASS:		DS	= Segment of SpoolSummons object
		BX	= Handle of driver or FREE_DRIVER_IMMEDIATELY

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolFreeDriver	proc	near
		class	SpoolSummonsClass
		uses	bx, si
		.enter
	
		; We cache this driver, and free the currently cached driver
		;
		mov	si, offset PrintDialogBox
EC <		call	ECCheckObject					>
		mov	si, ds:[si]
		add	si, ds:[si].SpoolSummons_offset
		xchg	bx, ds:[si].SSI_cachedDriver
		tst	bx
		jz	done

		; See if drivers should be freed immediately, in case
		; this object is getting destroyed. Make sure we handle
		; a case where FREE_DRIVER_IMMEDIATELY is passed more
		; than once.
		;
		cmp	bx, FREE_DRIVER_IMMEDIATELY
		jne	freeDriver
		xchg	bx, ds:[si].SSI_cachedDriver
		cmp	bx, FREE_DRIVER_IMMEDIATELY
		je	done		
freeDriver:
		call	GeodeFreeDriver
done:
		.leave
		ret
SpoolFreeDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolFreeDriverAndUIBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a driver and a memory block that was duplicated from
		a resource in that driver

CALLED BY:	UTILITY

PASS:		DS	= Segment of SpoolSummons object
		BX	= Handle of driver
		CX:DX	= OD of object in duplicated tree

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolFreeDriverAndUIBlock	proc	near
		class	SpoolSummonsClass
		uses	ax, cx, dx, di, si, bp
		.enter
	
		; Record an event we will send to ourselves
		;
		mov	ax, MSG_SPOOL_SUMMONS_FREE_UI_BLOCK_AND_DRIVER
		mov	bp, bx			; driver handle => BP
		mov	bx, ds:[LMBH_handle]
		mov	si, offset PrintDialogBox
		mov	di, mask MF_RECORD
		call	ObjMessage

		; Now flush the input queue for the block
		;
		mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		mov	dx, cx			; handle of block to be freed
		mov	cx, di			; event to send ourselves
		clr	bp			; start the flush process
		call	ObjCallInstanceNoLock

		.leave
		ret
SpoolFreeDriverAndUIBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsFreeUIBlockAndDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent back after flusing UI queue

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_FREE_UI_BLOCK_AND_DRIVER)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		CX:DX	= OD of object in duplicated block
		BP	= Handle of driver to free

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/16/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsFreeUIBlockAndDriver	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_FREE_UI_BLOCK_AND_DRIVER
		.enter

		; First free the block
		;
		push	bp
		mov	ax, MSG_META_BLOCK_FREE
		mov	bx, cx
		mov	si, dx			; duplicated tree => BX:SI
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		; Now free the driver
		;
		pop	bx
		call	SpoolFreeDriver

		.leave
		ret
SpoolSummonsFreeUIBlockAndDriver	endm

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolLoadDriverLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a printer driver

CALLED BY:	SpoolLoadDriver(), GrabPrinterInfo()
	
PASS:		DS:SI	= Printer category name
		ES	= Segment holding SpoolSummons object

RETURN:		AX	= PState handle
		BX	= Driver handle
		DX:CX	= Driver Strategy
		Carry	= Clear (success)

			- or -

		AX	= PrinterControlErrors
		BX	= garbage
		DX:CX	= garbage
		Carry	= Set (failure)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Call SpoolFreeDriver instead of GeodeFreeDriver to
		free the just-loaded printer driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolLoadDriverLow	proc	near
	uses	ds, si
	.enter	

	; First allocate a PState
	;
	mov	ax, (size PState)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or ((mask HAF_ZERO_INIT) shl 8)
	call	MemAlloc			; handle => BX (PState)
	push	bx				; save PState handle

	; Access this driver, please
	;
	mov	ax, SP_PRINTER_DRIVERS
	mov	cx, PRINT_PROTO_MAJOR
	mov	dx, PRINT_PROTO_MINOR
	call	UserLoadExtendedDriver		; driver handle => BX
	jc	error				; if error, abort

	; The driver is loaded. Now set up a few things
	;
	call	GeodeInfoDriver			; to get strategy routine
	mov	cx, ds:[si].DIS_strategy.offset
	mov	dx, ds:[si].DIS_strategy.segment
	pop	ax				; PState handle => AX
	clc					; indicate success
done:
	.leave
	ret

	; We couldn't set device. Fail & clean up
error:
	pop	bx				; PState handle => BX
	call	MemFree				; free the PState
	mov	ax, PCERR_PRINTER_NOT_KNOWN	; error type => AX
	stc					; set carry for failure
	jmp	done				; we're outta here
SpoolLoadDriverLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDriverInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the driver-dependent information

CALLED BY:	GrabPrinterInfo
	
PASS:		DS:SI	= PrintDriverInfo
		ES:DI	= PrinterInfoStruct

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyDriverInfo	proc	near
	.enter

	mov	ax, ds:[si].PDI_timeoutValue
	mov	es:[di].PIS_timeout, ax
	mov	al, ds:[si].PDI_driverType	; PrinterDriverType => AL
	mov	es:[di].PIS_driverType, al

	.leave
	ret
CopyDriverInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the needed information out of the PrinterInfo table
		into my own PrinterInfoStruct

CALLED BY:	GrabPrinterInfo
	
PASS:		DS:SI	= PrinterInfo
		ES:DI	= PrinterInfoStruct

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyPrinterInfo	proc	near
	.enter

	; Determine what printer modes this beast supports
	;
	clr	al				; initially no printer modes
	tst	ds:[si].PI_lowRes		; low resolution graphics
	jz	mode1
	or	al, mask POM_GRAPHICS_LOW
mode1:
	tst	ds:[si].PI_medRes		; medium resolution graphics
	jz	mode2
	or	al, mask POM_GRAPHICS_MEDIUM
mode2:
	tst	ds:[si].PI_hiRes		; high-resolution graphics
	jz	mode3
	or	al, mask POM_GRAPHICS_HIGH
mode3:
	tst	ds:[si].PI_draft		; text draft
	jz	mode4
	or	al, mask POM_TEXT_DRAFT
mode4:
	tst	ds:[si].PI_nlq			; near letter quality
	jz	modeDone
	or	al, mask POM_TEXT_NLQ

	; Now copy all the information we need
modeDone:
	mov	es:[di].PIS_POM, al		; store the PrinterOutputModes

	; Set some information flags
	;
	mov	ax, ds:[si].PI_paperWidth
	mov	es:[di].PIS_maxWidth, ax
	test	ds:[si].PI_connect, mask PC_FILE
	jz	mainUI
	or	es:[di].PIS_info, mask SSPI_CAPABLE_TO_FILE	
mainUI:
	tst	ds:[si].PI_mainUI.chunk
	jz	optionUI
	or	es:[di].PIS_info, mask SSPI_UI_IN_DIALOG_BOX
optionUI:
	tst	ds:[si].PI_optionsUI.chunk
	jz	done
	or	es:[di].PIS_info, mask SSPI_UI_IN_OPTIONS_BOX
done:
	.leave
	ret
CopyPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrinterStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provides a copy of the block containing the print strings

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PRINTER_STRINGS)

PASS:		DS:*SI	= SpoolSummons instance data

RETURN:		CX	= Length of the buffer
		DX	= Handle to block holding the strings
		BP	= Currently selected printer

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPrinterStrings	method	SpoolSummonsClass, \
				MSG_SPOOL_SUMMONS_GET_PRINTER_STRINGS
	.enter

	push	ds, si				; save the SpoolSummons handle
	call	SSOpenPrintStrings		; get some important data
	mov	bp, dx				; current printer => BP
	inc	cx				; leave room for NULL
	mov	dx, cx				; store in DX
	mov	ax, cx				; bytes to allocate
	mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
		    ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8))
	call	MemAlloc			; allocate a block
	mov	si, di				; DS:SI is the string buffer
	mov	es, ax
	clr	di				; ES:DI is the blank buffer
	mov	cx, dx				; bytes to copy => CX
	rep	movsb				; copy the bytes
	mov	cx, dx				; string size => CX
	dec	cx				; without NULL, actually
	mov	dx, bx				; block handle => DX
	call	MemUnlock			; unlock the block
	pop	ds, si				; restore the SpoolSummons obj
	call	SSClosePrintStrings		; unlock the strings block

	.leave
	ret
SpoolSummonsGetPrinterStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSOpenPrintStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the print strings block and lock it

CALLED BY:	GLOBAL

PASS:		DS:*SI	= SpoolSummons instance data

RETURN:		DS:DI	= Printer strings
		CX	= Length of the strings buffer
		DX	= Current printer (0 -> N-1)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSOpenPrintStrings	proc	near
	class	SpoolSummonsClass
	uses	ax, bx
	.enter

	mov	di, ds:[si]			; derference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	mov	bx, ds:[di].SSI_printDataHan
	mov	cx, ds:[di].SSI_printDataLen
	mov	dx, ds:[di].SSI_currentPrinter
	call	MemLock
	mov	ds, ax
	clr	di
	
	.leave
	ret
SSOpenPrintStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSClosePrintStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the print strings block and unlock it

CALLED BY:	GLOBAL

PASS:		DS:*SI	= SpoolSummons instance data

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSClosePrintStrings	proc	near
	class	SpoolSummonsClass
	uses	bx, di
	.enter

	mov	di, ds:[si]			; derference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	mov	bx, ds:[di].SSI_printDataHan	; block handle => BX
	call	MemUnlock			; unlock the block

	.leave
	ret
SSClosePrintStrings	endp

SpoolSummonsCode	ends
