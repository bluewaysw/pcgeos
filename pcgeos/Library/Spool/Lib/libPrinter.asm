COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Lib/Spool - PC/GEOS Spool Library
FILE:		libPrinter.asm
AUTHOR:		Don Reeves, Jan 20, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB	SpoolGetNumPrinters	Gets the number of printers available
    GLB	SpoolGetPrinterString	Gets the name of a specific printer
    GLB	SpoolGetPrinterInfo	Gets information about a specific printer

    GLB	SpoolCreatePrinter	Create a new printer, adding it to the system
    GLB	SpoolDeletePrinter	Remove a printer from the system
    GLB	SpoolGetDefaultPrinter	Gets the default printer
    GLB	SpoolSetDefaultPrinter	Sets the default printer
	
    INT	GetTypeKeyString	Return pointer to proper type key string
    INT	GetInitFileCount	Get a count from .ini file, & 0 if key not found
    EXT	ReadPrinterDriverType	Read the printer driver type from the .ini file
    INT	IncInitFileCount	Increment a count in the .ini file
    INT	DecInitFileCount	Decrement a count in the .ini file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/92		Initial revision

DESCRIPTION:
	Implements the procedures that deal with printers the user has
	installed, or wants to install.

	$Id: libPrinter.asm,v 1.1 97/04/07 11:11:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPrinter	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Printer Strings used in the .INI file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; The printer category
;
printerCategoryString	char	"printer", 0

; Valid keys under the printer category
;
printersKeyString	char	"printers", 0
numberPrintersKeyString	char	"count", 0
defaultPrinterKeyString	char	"defaultPrinter", 0

; Keys that keep counts for individual printer types under the printer category
;
numTypePrinterKey	char	"numPrinters", 0
numTypePlotterKey	char	"numPlotters", 0
numTypeFacsimileKey	char	"numFacsimiles", 0
numTypeCameraKey	char	"numCameras", 0
numTypeOtherKey		char	"numOthers", 0

typeKeyStrings		nptr.char \
			numberPrintersKeyString, \
			numTypePrinterKey, \
			numTypePlotterKey, \
			numTypeFacsimileKey, \
			numTypeCameraKey, \
			numTypeOtherKey
				
; Valid keys under the specific printer category
;
printerTypeKeyString	char	"type", 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Global routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetNumPrinters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of printers currently installed

CALLED BY:	GLOBAL

PASS:		CL	= PrinterDriverType
		CH	= nonzero to fetch ONLY the number of local
			  printers. 

RETURN:		AX	= Number of printers

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetNumPrinters	proc	far
		uses	cx, dx, si, ds
		.enter
	
		; Ask the .INI file for the value
		;
		mov	al, ch			; local-only flag
EC <		clr	ch			; accept all types	>
		call	GetTypeKeyString	; key string offset => DX
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString

		tst	al
		jz	getAll

		call	SpoolReadLocalInitFileCount
		jmp	done

getAll:
		call	ReadInitFileCount	; count => AX

done::					; used for debugging
		.leave
		ret
SpoolGetNumPrinters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolReadLocalInitFileCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read an initfile integer from the LOCAL init file only

CALLED BY:	SpoolGetNumLocalPrinters, 
		IncInitFileCount, 
		DecInitFileCount

PASS:		ds:si - category
		cx:dx - key

RETURN:		ax - count (zero if not found)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
	       chrisb	2/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <	PRINTER_NUM_STRING_LENGTH equ 20		>
DBCS <	PRINTER_NUM_STRING_LENGTH equ 40		>

SpoolReadLocalInitFileCount	proc near
		uses	bx, cx, dx, di, si, bp, ds, es
		.enter

if DBCS_PCGEOS
		call	InitFileReadInteger
		jnc	done
		clr	ax
done:
else
		sub	sp,  PRINTER_NUM_STRING_LENGTH 
		mov	di, sp
		segmov	es, ss

		clr	ax
		mov	bp, mask IFRF_FIRST_ONLY or PRINTER_NUM_STRING_LENGTH
		call	InitFileReadString
		jc	done

		segmov	ds, es
		mov	si, sp
		call	UtilAsciiToHex32
		jnc	done
		clr	ax
done:
		add	sp, PRINTER_NUM_STRING_LENGTH
endif

		.leave
		ret
SpoolReadLocalInitFileCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPrinterString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a buffer with a specific printer's name

CALLED BY:	GLOBAL

PASS:		ES:DI	= Buffer to fill (of size GEODE_MAX_DEVICE_NAME_SIZE)
		AX	= Printer #

RETURN:		CX	= Length of string (w/o NULL)
		DL	= PrinterDriverType
		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPrinterString	proc	far
		uses	ax, bx, si, bp, ds
		.enter
	
		; Fill the buffer with a string from the .INI file
		;
		push	dx
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString
		mov	dx, offset printersKeyString
		mov	bp, InitFileReadFlags<IFCC_INTACT, \
						1,,
			                     GEODE_MAX_DEVICE_NAME_LENGTH>
		call	InitFileReadStringSection
		jc	done			; if error, we're done

		; Now also get the printer driver type
		;
		push	cx			; save the string length
		segmov	ds, es
		mov	si, di			; category => DS:SI
		ConvPrinterNameToIniCat
		call	ReadPrinterDriverType	; PrinterDriverType => AL
		ConvPrinterNameDone
		pop	cx			; restore string length
done:		
		pop	dx
		mov	dl, al			; PrinterDriverType => DL

		.leave
		ret
SpoolGetPrinterString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	- currently not implemented -

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPrinterInfo	proc	far
		.enter
	
		.leave
		ret
SpoolGetPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreatePrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new printer, appending it onto the end of the
		printer list

CALLED BY:	GLOBAL

PASS:		ES:DI	= Printer name (of length GEODE_MAX_DEVICE_NAME_SIZE)
		CL	= Printer driver type

RETURN:		AX	= # for new printer
		Carry	= Clear
			- or -
		Carry	= Set if printer already exists

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note that this only adds the printer to the list of currently
		installed printers. It does not (yet) write out the various
		pieces of information expected for an installed printer.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCreatePrinter	proc	far
		uses	cx, dx, bp, di, si, ds
		.enter
	
		; Check to see that this printer doesn't already exist
		;
		push	cx
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString
		mov	dx, offset printersKeyString
		mov	bx, di			; printer name => ES:BX
		mov	ax, offset CheckForDuplicateName
		mov	di, cx			; fptr of callback => DI:AX
		mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT or \
			    mask IFRF_READ_ALL
		call	InitFileEnumStringSection
		pop	cx
		jc	error

		; Add the string onto the end of the current print blob
		;
		mov	di, bx			; printer name => ES:DI
		push	cx, cx
		mov	cx, cs			; key string => CX:DX
		call	InitFileWriteStringSection
		
		; Update the printer counts
		;	es:di = printer name (converted to SBCS)
		;
		pop	cx			; PrinterDriverType => CL
EC <		mov	ch, 1			; minimum value		>
		call	GetTypeKeyString	; type key => CX:DX
		call	IncInitFileCount	; increment count
		mov	dx, offset numberPrintersKeyString
		call	IncInitFileCount	; increment count, count => AX
		dec	ax			; zero-based printer # => AX

		; Write out the PrinterDriverType
		;	es:di = printer name (converted to SBCS)
		;
		segmov	ds, es
		mov	si, di			; printer category => DS:SI
		pop	bp			; PrinterDriverType => BP (low)
		push	ax
		ConvPrinterNameToIniCat
		and	bp, 0x00ff		; clear high byte
EC <		cmp	bp, PrinterDriverType	; check against maximum	>
EC <		ERROR_AE SPOOL_PASSED_ILLEGAL_PRINTER_DRIVER_TYPE	>
		mov	dx, offset printerTypeKeyString
		call	InitFileWriteInteger	; write the value
		ConvPrinterNameDone

		; Let the medium subsystem know about this thing being
		; available.
		; 
		call	SpoolPrinterNameToMedium
		
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_AVAILABLE or mask SNT_BX_MEM
		call	SysSendNotification

		; Now send notifcation that we've changed stuff
		;
		call	SendNotificationToGCNList
		pop	ax			; ax <- printer #
		clc				; no errors for now
error:
		.leave
		ret
SpoolCreatePrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForDuplicateName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A callback routine that checks to see that a printer of
		the same name doesn't already exist.

CALLED BY:	SpoolCreatePrinter, via InitFileEnumStringSection

PASS:		DS:SI	= Installed printer name
		CX	= Length of string
		ES:BX	= New printer name

RETURN:		Carry	= Set if match (stop enumeration)

DESTROYED:	CX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckForDuplicateName	proc	far
		.enter
	
		; Compare the strings
		;
		mov	di, bx
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		clc
		jnz	done			; no match, so continue
SBCS <		cmp	es:[di], cl		; check for end of new string >
DBCS <		cmp	es:[di], cx		; check for end of new string >
		clc
		jne	done			; not NULL, so no match
		stc				; else, we have a match
done:
		.leave
		ret
CheckForDuplicateName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDeletePrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an existing printer from the currently installed list.

CALLED BY:	GLOBAL

PASS:		AX	= Printer # to delete

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolDeletePrinter	proc	far
		uses	ax, cx, dx, di, si, ds, es
		.enter
	
		; First delete the specific-printer category
		;
		sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
		mov	di, sp
		mov	si, sp
		segmov	ds, ss, cx		; buffer => DS:SI
		mov	es, cx			; buffer => ES:DI
		call	SpoolGetPrinterString	; PrinterDriverType => DL
		jc	error			; if printer not found, abort
		ConvPrinterNameToIniCat
		call	InitFileDeleteCategory
		ConvPrinterNameDone

		push	ax, dx
		call	SpoolPrinterNameToMedium
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_NOT_AVAILABLE or mask SNT_BX_MEM
		call	SysSendNotification
		pop	ax, dx

		add	sp, GEODE_MAX_DEVICE_NAME_SIZE
		push	dx			; save the PrinterDriverType
		push	ax			; save the printer string
		push	dx			; save the PrinterDriverType


		; Then delete the string from the current print blob
		;
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString
		mov	dx, offset printersKeyString
		call	InitFileDeleteStringSection

		; Update the printer counts
		;
		pop	cx			; PrinterDriverType => CL
EC <		mov	ch, 1			; minimum value		>
		call	GetTypeKeyString	; type key => CX:DX
		call	DecInitFileCount	; decrement count
		mov	dx, offset numberPrintersKeyString
		call	DecInitFileCount	; decrement count

		; Finally, fix up the default printer, if needed
		;
		pop	cx			; deleted printer => CX
		pop	dx			; PrinterDriverType => DL
		cmp	dl, PDT_PRINTER		; if not printer
		jne	done			; ...then do nothing
		call	SpoolGetDefaultPrinter	; default printer => AX
		cmp	ax, cx			; is default < deleted ??
		jl	done			; if so, we're fine
		jg	reset			; if greater, back up one
		mov	ax, 1			; else use printer #0 (1 - 1)
reset:
		dec	ax			; back up one printer
		call	SpoolSetDefaultPrinter	; set the new default printer
done:
		; Now send notifcation that we've changed stuff
		call	SendNotificationToGCNList
exit:
		.leave
		ret
error:
		add	sp, GEODE_MAX_DEVICE_NAME_SIZE
		jmp	exit
SpoolDeletePrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current system-default printer

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		AX	= Printer #

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPOOLGETDEFAULTPRINTER	proc	far
		uses	cx, dx, si, ds
		.enter
	
		; Ask the .INI file for the value
		;
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString
		mov	dx, offset defaultPrinterKeyString
		call	InitFileReadInteger
		jnc	done			; if no error, we're done
		clr	ax			; else there are no errors
done:
		.leave
		ret
SPOOLGETDEFAULTPRINTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the system-default printer to be used

CALLED BY:	GLOBAL

PASS:		AX	= Printer # for default

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSetDefaultPrinter	proc	far
		uses	cx, dx, si, bp, ds
		.enter
	
		; Set the value in the .INI file
		;
		mov	bp, ax			; new default printer => BP
EC <		push	ax, cx						>
EC <		mov	cx, PDT_ALL_LOCAL_AND_NETWORK			>
EC <		call	SpoolGetNumPrinters	; # of printers => AX	>
EC <		tst	ax			; any printers ??	>
EC <		jz	doneEC			; nope, so don't worry	>
EC <		cmp	bp, ax			; check our printer #	>
EC <		ERROR_AE SPOOL_ILLEGAL_DEFAULT_PRINTER_NUMBER_PASSED	>
EC <doneEC:								>
EC <		pop	ax, cx						>
		segmov	ds, cs, cx
		mov	si, offset printerCategoryString
		mov	dx, offset defaultPrinterKeyString
		call	InitFileWriteInteger
	;
	; Warn the world that we've changed printer configuration
	;
		call	SendNotificationToGCNList

		.leave
		ret
SpoolSetDefaultPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTypeKeyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the offset to the request PrinterDriverType key

CALLED BY:	INTERNAL

PASS:		CL	= PrinterDriverType or PDT_ALL
		CH	= 0 (all) or 1 (not PDT_ALL) (EC-only)

RETURN:		CX:DX	= Init file Key string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTypeKeyString	proc	near
		uses	si
		.enter
	
		inc	cl
EC <		cmp	cl, PrinterDriverType+1	; check against maximum	>
EC <		ERROR_AE SPOOL_PASSED_ILLEGAL_PRINTER_DRIVER_TYPE	>
EC <		tst	ch						>
EC <		jz	doneEC						>
EC <		tst	cl						>
EC <		ERROR_E	SPOOL_CANNOT_PASS_PDT_ALL_TO_THIS_FUNCTION	>
EC <doneEC:								>
		shl	cl, 1
		clr	ch
		mov	si, cx
		mov	cx, cs
		mov	dx, cs:[typeKeyStrings][si]	; key => CX:DX

		.leave
		ret
GetTypeKeyString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInitFileCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a count out of the .INI file. If it is undefined, return 0

CALLED BY:	INTERNAL

PASS:		DS:SI	= Category string
		CX:DX	= Key string

RETURN:		AX	= Count

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadInitFileCount	proc	near
		uses	bp, di, bx
		.enter

SBCS <		mov	bp, mask IFRF_READ_ALL				>
DBCS <		clr	bp						>
		mov	di, cs
		mov	ax, offset ReadInitFileCountCB
		clr	bx			; initial count=0
SBCS <		call	InitFileEnumStringSection			>
DBCS <		call	InitFileReadAllInteger				>
		mov_tr	ax, bx			; return count

		.leave
		ret
ReadInitFileCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInitFileCountCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to sum up the initfile counts in
		(possible) multiple init files

CALLED BY:	ReadInitFileCount via InitFileEnumStringSection

PASS:		SBCS:
		bx - old count
		ds:si - string section
		cx - length of section
		DBCS: 
		ax - integer

RETURN:		bx - updated
		DBCS:
		carry clear to continue enumeration

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadInitFileCountCB	proc far
if DBCS_PCGEOS
	add	bx, ax
	clc				; continue enumeration
else
	uses	dx,ax
	.enter
	call	UtilAsciiToHex32
	jc	done
	add	bx, ax
done:
	clc
	.leave
endif
	ret
ReadInitFileCountCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadPrinterDriverType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the printer driver type for an installed printer

CALLED BY:	INTERNAL

PASS:		DS:SI	= Printer category name

RETURN:		AL	= PrinterDriverType

DESTROYED:	AH, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadPrinterDriverType	proc	far
		.enter
	
NEC <		clr	al			; assume PDT_PRINTER	>
		mov	cx, cs
		mov	dx, offset printerTypeKeyString
		call	InitFileReadInteger
EC <		ERROR_C	SPOOL_COULD_NOT_FIND_PRINTER_DRIVER_TYPE	>
EC <		cmp	al, PrinterDriverType	; check against maximum	>
EC <		ERROR_AE SPOOL_PASSED_ILLEGAL_PRINTER_DRIVER_TYPE	>
EC <		clc							>

		.leave
		ret
ReadPrinterDriverType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncInitFileCount, DecInitFileCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment or decrement a count in the .INI file

CALLED BY:	INTERNAL

PASS:		DS:SI	= Category string
		CX:DX	= Key string

RETURN:		AX, BP	= New count

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	DON'T use ReadInitFileCount, because that sums up the counts
	over all init files.  We're only interested here in modifying
	the values stored in the first init file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IncInitFileCount	proc	near
		clr	ax
		call	SpoolReadLocalInitFileCount
		inc	ax

initfileCommon	label	near
		mov	bp, ax
		call	InitFileWriteInteger
		ret
IncInitFileCount	endp

DecInitFileCount	proc	near
		clr	ax
		call	SpoolReadLocalInitFileCount
EC <		cmp	ax, 0						>
EC <		ERROR_L	SPOOL_INIT_FILE_COUNT_MUST_BE_POSITIVE		>
		dec	ax
		GOTO	initfileCommon
DecInitFileCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotificationToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify members of the GCN list that we just changed the
		list of installed printers.

CALLED BY:	SpoolCreatePrinter(), SpoolDeletePrinter(),
		SpoolSetDefaultPrinter()

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendNotificationToGCNList	proc	near
		uses	ax, bx, cx, dx, di, bp
		.enter
	
		; First record the message to send
		;
		mov	ax, MSG_PRINTER_INSTALLED_REMOVED
		mov	di, mask MF_RECORD
		call	ObjMessage		; recorded message => DI

		; Now send it to the GCN list
		;
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_INSTALLED_PRINTERS
		mov	cx, di			; recorded message => CX
		clr	dx			; no extra data block
		mov	bp, mask GCNLSF_FORCE_QUEUE
		call	GCNListSend		; send the notification
		
		.leave
		ret
SendNotificationToGCNList	endp

if	DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterNameToIniCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a printer name (DBCS) to a .INI category name (SBCS)

CALLED BY:	EXTERNAL (ConvPrinterNameToIniCat macro)
PASS:		ds:si	= Printer name
RETURN:		ds:si 	= .INI category
		cx	= length (PrinterNameToIniCatLen())
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Users of ConvPrinterNameToIniCat must also have a corresponding
	incantation of ConvPrinterNameDone.

	If you change this, see also PrinterNameToIniCat() in:
		Library/Config/Pref/prefClass.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	12/ 7/93    	Initial version
	eca	7/8/94		re-named, re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterNameToIniCat	proc	far
		uses	cx
		.enter

		call	PrinterNameToIniCatLen

		.leave
		ret
PrinterNameToIniCat	endp

PrinterNameToIniCatLen	proc	far
		uses	ax, bx, dx, es, di
		.enter
	;
	; Allocate a buffer for the .INI category
	;
		mov	ax, (size PrinterNameStruct)
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		push	bx
		mov	es, ax
		clr	di
			CheckHack <(offset PNS_blockHandle) eq 0>
		mov	ax, bx			;ax <- block handle
		stosw
			CheckHack <(offset PNS_namePtr.low) eq 2>
		mov	ax, si
		stosw
			CheckHack <(offset PNS_namePtr.high) eq 4>
		mov	ax, ds
		stosw
			CheckHack <(offset PNS_iniCat) eq 6>
	;
	; Convert the string into SBCS
	;
		clr	cx			;cx <- length (SBCS)
		push	di
charLoop:
		LocalGetChar ax, dssi		;ax <- character
		LocalCmpChar ax, 0x80		;ASCII?
		jbe	gotChar			;branch if so
	;
	; For non-ASCII, stick in a couple of hex digits.  The digits aren't
	; in the correct order and they aren't all there, but it doesn't
	; matter as long as they are consistent
	;
		call	toHexDigits
DBCS <		mov	al, ah			;al <- high byte	>
DBCS <		call	toHexDigits					>
		jmp	charLoop

gotChar:
		stosb				;store SBCS character
		inc	cx			;cx <- one more character
		tst	al
		jnz	charLoop
	;
	; Return ds:si as a ptr to the .INI category name
	;
		segmov	ds, es			;ds:si <- ptr to category name
		pop	si
		pop	bx			;bx <- buffer handle

		.leave
		ret

toHexDigits:
		push	ax
	;
	; Second hex digit
	;
		push	ax
		andnf	al, 0x0f		;al <- low nibble
		call	convHexDigit
		pop	ax
	;
	; First hex digit
	;
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1			;al <- high nibble
		call	convHexDigit

		pop	ax
		retn

convHexDigit:
		add	al, '0'
		cmp	al, '9'
		jbe	gotDig
		add	al, 'A'-'9'-1
gotDig:
		stosb
		inc	cx			;cx <- one more character
		retn
PrinterNameToIniCatLen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterNameDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done with printer .INI category name from PrinterNameToIniCat()

CALLED BY:	EXTERNAL (ConvPrinterNameDone macro)
PASS:		ds:si - .INI category
RETURN:		ds - seg addr returned from PrinterNameToIniCat()
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrinterNameDone		proc	far
		uses	bx
		.enter

		pushf
		mov	bx, ds:PNS_blockHandle		;bx <- our handle
		mov	si, ds:PNS_namePtr.low
		mov	ds, ds:PNS_namePtr.high		;ds:si <- ori. ptr
		call	MemFree
		popf

		.leave
		ret
PrinterNameDone		endp

endif
SpoolPrinter	ends


