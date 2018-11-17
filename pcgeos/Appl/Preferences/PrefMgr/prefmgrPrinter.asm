COMMENT @--------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		
FILE:		prefmgrPrinter.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:

DATA STRUCTURES:
	The data structures for tracking print drivers and the devices
	they support is documented in ../Common/prefConstant.def
	
	$Id: prefmgrPrinter.asm,v 1.3 98/03/08 17:11:23 gene Exp $

----------------------------------------------------------------------------@

; Define MULTILE_PRINTER_DRIVER_TYPES in either the command line or
; or the .GP file to allow preferences to install output devices other
; than printers.
;
ifdef MULTIPLE_PRINTER_DRIVER_TYPES
	_MULTIPLE_PRINTER_DRIVER_TYPES = -1
else
	_MULTIPLE_PRINTER_DRIVER_TYPES = 0
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
TO MAKE THIS A LOADABLE MODULE:
It would be nice to make the printer section a loadable module, since
it's pretty big.  These steps are necessary:

1) Serial options DB -- this should be made a controller, since it's
shared by both the printer and modem code.  Another alternative is to
allow pref modules to contain more than one button -- then the
printer, modem, and serial code & objects could all go into one
module. 

2) Setup:  Preferences and Setup use some common code (in
Preferences/Common).  Setup should be modularized so that the printer
code/resources could all be moved into a module that could be used by
both Pref & Setup.

3) Internal changes:  Change procedures in this file to use ES as
dgroup, DS as the segment of the object blocks (since that block is
duplicated).  Other options are to store the object block's handle in
dgroup, and continue to use ObjMessage.  Right now, most messages are
sent to the process.  We'd probably want to change this to make them
go to the Dialog Box instead (PrinterDialog), and add the appropriate
messages / methods.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Main dialog box code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisOpenPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the printer dialog box has been opened

CALLED BY:	GLOBAL

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisOpenPrinter	proc	far
EC <	call	CheckDSDgroup						>
EC <	call	CheckESDgroup						>

	mov	cx, PDT_ALL_LOCAL_AND_NETWORK	; get all printer devices
	call	SpoolGetNumPrinters		; number of printers => AX
	mov	ds:[printerNumInstalled], ax	; store # of installed printers

	; Now tell the dynamic list the number of entries, and set
	; the default selection
	;
	mov	cx, ax				; number of entries => CX
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessage_PIL_send
	call	PrinterSetListSelection		; go set the list selection

	; Update any other UI state
	;
	call	UpdateDefaultPrinterUI
	ret
VisOpenPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterRequestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request a moniker for entry in the list of installed printers

CALLED BY:	GLOBAL (MSG_PRINTER_REQUEST_MONIKER)

PASS:		DS, ES	= DGroup
		CX:DX	= GenDynamicList OD
		BP	= Entry #

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterRequestMoniker	method dynamic	PrefMgrClass,
						MSG_PRINTER_REQUEST_MONIKER
	.enter

	; Get a copy of the name of the printer in a buffer
	;
	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
	segmov	es, ss
	mov	di, sp				; buffer => ES:DI
	mov	ax, bp				; printer # => AX
	call	SpoolGetPrinterString		; fill buffer with name

	; Now send a message to the list object
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, es
	mov	dx, di				; printer name => CX:DX
	call	ObjMessage_PIL_call		; call the list
	add	sp, GEODE_MAX_DEVICE_NAME_SIZE

	.leave
	ret
PrefMgrPrinterRequestMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a printer has been selected by the user.
		Status message sent out by the PrinterInstalledList.

CALLED BY:	MSG_PRINTER_SELECTED

PASS:		DS, ES	= DGroup
		CX	= Printer # selected

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterSelected	method dynamic	PrefMgrClass, MSG_PRINTER_SELECTED
	.enter

	; Set the default printer
	;
	mov	ax, MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER
	mov	si, offset PrinterUI:PrinterTest
	call	ObjMessage_printer_send

	; If multiple printer drivers are not supported, than one can
	; only perform operations on printers. Otherwise, one can only
	; make a *printer* the "default printer".
	;
	mov	ax, cx
	cmp	cx, GIGS_NONE
	je	haveSelection
	call	GetPrinterDriverType 	; PrinterDriverType => DL
	cmp	dl, PDT_PRINTER		; if a printer
	je	haveSelection		; ...we can edit it
	mov	cx, GIGS_NONE
haveSelection:
if	not _MULTIPLE_PRINTER_DRIVER_TYPES
	mov	cx, ax
endif
	;
	; The TEST and DEFAULT triggers are enabled whenever any
	; printer is selected. We only need to muck with the state
	; of the "Make Default" trigger is we don't support multiple
	; types of printers.  Not true -- the trigger is disabled by
	; default in the .ui file, so allow enabling it here.
	;
	push	ax, dx
	mov	si, offset PrinterUI:PrinterDefault
	call	PrinterEnableDisable
	pop	cx, dx
	;
	; 2/12/98 ND-000105 - Fax Driver - Test causes KR-09
	; Because fax is wacky, we disable the printer test for it.
	; It causes crashes, and this solution is most time-efficient.
	; -- eca
	;
	push	cx
	cmp	dl, PDT_FACSIMILE		;fax?
	jne	notFax				;branch if not
	mov	cx, GIGS_NONE			;cx <- else disable it...
notFax:
	mov	si, offset PrinterUI:PrinterTest
	call	PrinterEnableDisable
	pop	cx

	;
	; The EDIT & DELETE are enabled if the printer is a local printer
	;
	cmp	cx, GIGS_NONE
	je	gotSelection

	push	cx
	mov	cx, PDT_ALL		; get locals only (CX is nonzero)
	CheckHack <PDT_ALL eq -1>
	call	SpoolGetNumPrinters
	pop	cx
	cmp	cx, ax
	jb	gotSelection
	mov	cx, GIGS_NONE

gotSelection:
	;
	; Delete & Edit are only available on printer-type devices
	; if we don't support multiple types of drivers
	;
	mov	si, offset PrinterUI:PrinterEdit
	call	PrinterEnableDisable

	mov	si, offset PrinterUI:PrinterDelete
	call	PrinterEnableDisable

	.leave
	ret
PrefMgrPrinterSelected	endm

GetPrinterDriverType	proc	near
	uses	ax, cx, di, es
	.enter
	
	; Create a buffer for bogus storage
	;
	mov_tr	ax, cx			; printer # => AX
	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
	mov	di, sp
	segmov	es, ss
	call	SpoolGetPrinterString	; PrinterDriverType => DL
	add	sp, GEODE_MAX_DEVICE_NAME_SIZE

	.leave
	ret
GetPrinterDriverType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterAttemptInstall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to install a new printer, by bringing up the
		printer edit dialog box.

CALLED BY:	GLOBAL (MSG_PRINTER_ATTEMPT_INSTALL)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterAttemptInstall	method dynamic	PrefMgrClass,
						MSG_PRINTER_ATTEMPT_INSTALL

	or	ds:[printerState], mask PS_INSTALL
	mov	cx, offset PrinterNewMoniker
	GOTO	PrefMgrPrinterInitiateInstallEdit
PrefMgrPrinterAttemptInstall	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterAttemptEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Edit the currently selected printer

PASS:		*ds:si	= PrefMgrClass object
		ds:di	= PrefMgrClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/10/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterAttemptEdit	method dynamic	PrefMgrClass,
						MSG_PRINTER_ATTEMPT_EDIT

	and	ds:[printerState], not (mask PS_INSTALL)
	mov	cx, offset PrinterEditMoniker
	GOTO	PrefMgrPrinterInitiateInstallEdit
PrefMgrPrinterAttemptEdit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an installed printer

CALLED BY:	GLOBAL (MSG_PRINTER_DELETE)

PASS:		*DS:SI	= PrefMgrClass object
		DS:DI	= PrefMgrClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterDelete	method	PrefMgrClass, MSG_PRINTER_DELETE
	.enter

	; Get the current selection. If none, we're done
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage_PIL_call		; selection => AX
	cmp	ax, GIGS_NONE			; a valid selection ??
	je	done				; nope, so we're done
	
	; Delete the printer, and then reset some UI
	;
	call	SpoolDeletePrinter		; delete the printer
	dec	ds:[printerNumInstalled]	; decrement installed count
	mov	cx, ds:[printerNumInstalled]
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessage_PIL_send
	call	PrinterSetListSelection		; go reset the list selection
	call	UpdateDefaultPrinterUI		; update the default printer UI
done:
	.leave
	ret
PrefMgrPrinterDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterMakeDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current printer the default printer

CALLED BY:	UI (MSG_MAKE_DEFAULT_PRINTER)
	
PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterMakeDefault	method	PrefMgrClass,
				MSG_PRINTER_MAKE_DEFAULT
	.enter

	; Grab the current printer number
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage_PIL_call		; selection => AX
	cmp	ax, GIGS_NONE			; a valid selection ??
	je	done				; nope, so we're done
	tst	ax
	jz	setDefault

	; Convert the device number into the printer number (the
	; default printer count needs to ignore all non-printer
	; types of devices)
	;
	call	ConvertToPrinterNumber


	; Set the new default printer, & update the UI
setDefault:
	call	SpoolSetDefaultPrinter
	call	UpdateDefaultPrinterUI
done:
	.leave
	ret
PrefMgrPrinterMakeDefault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToPrinterNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from device # to printer #

CALLED BY:	PrefMgrPrinterMakeDefault()

PASS:		AX	= device #
RETURN:		AX	= printer #

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ND-000499 - Preferences, Printer can display wrong default printer
	The problem with the old code was if there were printers followed
	by non-printers followed by a printer, and that was the requested
	printer. 2/13/98 -- eca
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/28/94		Initial version
	gene	2/14/98		Rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC_VERSION
ConvertToPrinterNumber	proc	far
else
ConvertToPrinterNumber	proc	near
endif
	uses	cx, dx, di, si, es
	.enter

	;
	; Subtract one for each non-printer-type device
	;
	mov	cx, ax				; loop count => CX
	mov	si, ax				; printer/device count => SI
	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
	segmov	es, ss
	mov	di, sp
	clr	ax				; start with printer 0
printerLoop:
	call	IsPrinter?
	je	nextPrinter			; branch if a printer
	dec	si				; si <- one less printer
nextPrinter:
	inc	ax				; go to next installed device
	dec	cx				; can't use "loop" instruction
	jg	printerLoop			; ...as CX could be zero
	add	sp, GEODE_MAX_DEVICE_NAME_SIZE
	mov_tr	ax, si

	.leave
	ret
ConvertToPrinterNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToDeviceNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from printer # to device #

CALLED BY:	PrefMgrPrinterMakeDefault()

PASS:		AX	= printer #
RETURN:		AX	= device #

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/14/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertToDeviceNumber	proc	near
	uses	cx, dx, di, si, es
	.enter

	mov	si, ax				;si <- printer #
	mov	dx, ax				;dx <- printer #
	mov	cx, PDT_ALL_LOCAL_AND_NETWORK	;cx <- all printer devices
	call	SpoolGetNumPrinters
	mov	cx, ax				;cx <- total # of devices
	jcxz	noPrinters			;branch if no printers
	;
	; Add one for each non-printer-type device
	;
	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
	segmov	es, ss
	mov	di, sp
	clr	ax				;ax <- start with device #0
printerLoop:
	call	IsPrinter?
	je	nextPrinter			;branch if a printer
	;
	; If not a printer, see if it is before our device number
	;
	cmp	ax, dx
	ja	nextPrinter			;branch if not before
	inc	dx				;dx <- one more device
nextPrinter:
	inc	ax				;ax <- next device
	loop	printerLoop			;loop while more

	mov_tr	ax, dx				;ax <- device #
noPrinters:
	add	sp, GEODE_MAX_DEVICE_NAME_SIZE

	.leave
	ret
ConvertToDeviceNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPrinter?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a specified device is a printer

CALLED BY:	ConvertToPrinterNumber(), ConverrToDeviceNumber()

PASS:		ax - device #
		es:di - ptr to buffer
RETURN:		z flag - set if == PDT_PRINTER

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/14/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsPrinter?	proc	near
	uses	cx, dx
	.enter

	call	SpoolGetPrinterString
EC <	ERROR_C	PREF_ILLEGAL_PRINTER_COUNT				>
	cmp	dl, PDT_PRINTER			; if not a printer, then

	.leave
	ret
IsPrinter?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterInitiateTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a test of an installed printer.

CALLED BY:	GLOBAL (MSG_PRINTER_INITIATE_TEST)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterInitiateTest	method dynamic	PrefMgrClass,
						MSG_PRINTER_INITIATE_TEST
	.enter

	; Set all the list entries etc. that VerifyPortSelection
	; looks at so it gets everything right...
	;
	call	PrinterSetThingsForInstalledPrinter


	mov	si, ds:[printerPort]
EC <	call	ECCheckPrinterPort		>
	test	ds:[si].PPPI_type, mask PC_RS232C
	jz	verify
	call	SerialLoadOptions	; load options from initfile

	; Verify the port.  If it isn't kosher, don't try to print
verify:
	clr	ax			; don't put up verify box
	call	VerifyPortSelection
	tst	ax			; did the port check out ?
	jnz	exit			;  no, boogie

	; Looks like everything is OK.  Start printing away.
	;
	mov	ax, MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI
	mov	cl, PDT_ALL
	mov	si, offset PrinterUI:PrinterTest
	call	ObjMessage_printer_send
exit:
	.leave
	ret
PrefMgrPrinterInitiateTest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection for the list of installed printers. Will
		set it to zero unles there are no installed printers, and
		then will set it to none.

CALLED BY:	INTERNAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterSetListSelection	proc	near
	.enter
	
	; Set the selection, and then send status message back
	;	
	clr	cx, dx				; select 1st entry
	tst	ds:[printerNumInstalled]
	jnz	sendMsg
	dec	cx				; GIGS_NONE => CX
sendMsg:
	mov	si, offset PrinterUI:PrinterInstalledList
	call	PrinterSetSelectionSendStatus

	.leave
	ret
PrinterSetListSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDefaultPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set usable/not the UI gadgetry involved with the default
		printer.

CALLED BY:	INTERNAL
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateDefaultPrinterUI	proc	near
	.enter

	; Determine whether or not to make gadgetry available
	;
	mov	ax, MSG_GEN_SET_USABLE
	cmp	ds:[printerNumInstalled], 1
	ja	setStatus
	mov	ax, MSG_GEN_SET_NOT_USABLE	; normal case

	; Now perform the actions
setStatus:
	mov	si, offset PrinterUI:PrinterDefaultText
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_printer_send		; registers are preserved
	mov	si, offset PrinterUI:PrinterDefault
	call	ObjMessage_printer_send	

	; Update the printer text, if necessary
	;
	cmp	ax, MSG_GEN_SET_USABLE
	jne	done
	;
	;  Tell PrinterDefault to check if it needs to be enable/disable
	clr	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	si, offset PrinterInstalledList
	call	ObjMessage_printer_send	

SBCS <	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE				>
DBCS <	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE*(size wchar)		>
	segmov	es, ss
	mov	di, sp				; buffer => ES:DI
	call	SpoolGetDefaultPrinter		; printer # => AX
	call	ConvertToDeviceNumber		; convert to device number
	call	SpoolGetPrinterString		; fill buffer with name
	mov	dx, es
	mov	bp, di				; text => DX:BP
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset PrinterUI:PrinterDefaultText
	call	ObjMessage_printer_call		; set the text
SBCS <	add	sp, GEODE_MAX_DEVICE_NAME_SIZE				>
DBCS <	add	sp, GEODE_MAX_DEVICE_NAME_SIZE*(size wchar)		>
done:
	.leave
	ret
UpdateDefaultPrinterUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Test printing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a test file

CALLED BY:	GLOBAL (MSG_PRINT_START_PRINTING)

PASS:		DS, ES	= DGroup
		CX:DX	= PrintControl OD
		BP	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COLOR_TEST_COLS		= 8
COLOR_TEST_ROWS		= 4
COLOR_TEST_CUBE_SIZE	= 40

PrefMgrPrintStartPrinting	method dynamic	PrefMgrClass,
						MSG_PRINT_START_PRINTING
	.enter

	; Check to see if a job is already spooled. If so, notify the
	; user and cancel the spool job
	;
	push	dx				; save the PrintControl chunk
	call	CheckSpoolEmpty			; already printing ??
	jnc	doTest				; no, so print document
	mov	bx, handle spoolBusyString
	mov	si, offset spoolBusyString
	call	DoError
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	jmp	done				; we're outta here

	; We must print the test page. Set-up the defaults
doTest:
	call	PrintTestDrawCornerMarks	; setup page; draw corner marks
						; page width => CX
	push	cx, di
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage_PIL_call		; selected printer => AX
	pop	cx, di
	push	ax				; save the selected printer
	
ifdef GPC_ONLY
	; Draw the GlobalPC logo
	;
	push	si, ds
	mov	bx, handle gpcLogoBitmap
	mov	si, offset gpcLogoBitmap
	call	StringLock			; Bitmap => DX:BP
	movdw	dssi, dxbp
	mov	ax, cx
	sub	ax, 430				; subtract bitmap width
	sar	ax, 1				; left position => AX
	mov	bx, 200 - 92 - 15		; top position => BX
	call	GrDrawBitmap
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	si, ds
else
	; Print string #1
	;
	mov	bx, handle testPrinterString1
	mov	si, offset testPrinterString1
	call	StringLock			; string => DX:BP
	mov	ax, 150				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	call	MemUnlock			; unlock resource handle in BX
endif
	; Print string #2
	;
	mov	bx, handle testPrinterString2
	mov	si, offset testPrinterString2
	call	StringLock			; string => DX:BP
	mov	ax, 200				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	call	MemUnlock			; unlock resource handle in BX

	; Print name of printer (#3)
	;
	pop	bx				; printer # => BX
	sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
	segmov	es, ss
	mov	bp, sp				; printer name buffer => ES:BP
	push	cx				; save paper width
NPZ <	mov	cx, FID_DTC_URW_ROMAN					>
PZ <	mov	cx, FID_BITSTREAM_KANJI_HON_MINCHO			>
	mov	dx, 24				; font size => DX:AH
	clr	ah
	call	GrSetFont			; use smaller point size
	xchg	bp, di				; GState => BP
	mov_tr	ax, bx				; printer # => AX
	call	SpoolGetPrinterString		; fill buffer with printer name
	mov	dx, es
	xchg	bp, di				; string => DX:BP, GState => DI
	pop	cx				; paper width => CX
	mov	ax, 250				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	add	sp, GEODE_MAX_DEVICE_NAME_SIZE

	; Now test the color capabilities by drawing a little table
	;
	mov	ax, cx
	sub	ax, COLOR_TEST_COLS * COLOR_TEST_CUBE_SIZE
	sar	ax, 1				; starting left position => AX
	mov	bx, 350				; starting top position => BX
	push	ax, bx
	mov	bp, 0				; starting color index => BP
	mov	cx, COLOR_TEST_ROWS
colLoop:
	mov	dx, cx
	mov	cx, COLOR_TEST_COLS
rowLoop:
	call	drawColorTestCube
	add	ax, COLOR_TEST_CUBE_SIZE	; move one column over
	inc	bp				; go to the next color
	loop	rowLoop
	add	bx, COLOR_TEST_CUBE_SIZE
	sub	ax, COLOR_TEST_CUBE_SIZE * COLOR_TEST_COLS
	mov	cx, dx
	loop	colLoop
	pop	ax, bx
	mov	cx, ax
	mov	dx, bx
	add	cx, COLOR_TEST_CUBE_SIZE * COLOR_TEST_COLS
	add	dx, COLOR_TEST_CUBE_SIZE * COLOR_TEST_ROWS
	call	GrDrawRect			; draw an outline around it all

	; We're done - so end the page properly
	;
	mov	al, PEC_FORM_FEED		; put out the form feed
	call	GrNewPage

	; Now clean up and leave (expect method in AX at "done" label)
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
done:
	pop	si
	call	ObjMessage_printer_send		; send the notification

	.leave
	ret

	; Draw the color test cube (actually a square)
	;
drawColorTestCube:
	push	cx, dx
	push	ax
	mov	ax, bp
	call	GrSetAreaColor
	pop	ax
	mov	cx, ax		
	add	cx, COLOR_TEST_CUBE_SIZE
	mov	dx, bx		
	add	dx, COLOR_TEST_CUBE_SIZE
	call	GrFillRect
	pop	cx, dx
	retn	
PrefMgrPrintStartPrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrintGetDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the test document

CALLED BY:	INTERNAL (MSG_PRINT_GET_DOC_NAME)

PASS:		CX:DX	= PrintControl OD
		BP 	= MSG_PRINT_CONTROL_SET_DOC_NAME

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrintGetDocName	method dynamic	PrefMgrClass, MSG_PRINT_GET_DOC_NAME
	.enter

	; Send the method back to the PrintControl
	;
	push	dx				; save the chunk handle
	mov_tr	ax, bp				; method => AX
	mov	bx, handle PrefMgrStrings
	mov	si, offset printDocNameString
	call	StringLock			; string => DX:BP
	mov	cx, dx
	mov	dx, bp				; string => CX:DX
	pop	si				; PrintControl chunk => SI
	call	ObjMessage_printer_call		; call the PrintControl

	; Clean up
	;
	mov	bx, handle PrefMgrStrings
	call	MemUnlock

	.leave
	ret
PrefMgrPrintGetDocName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpoolEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the spooler has any job waiting on the queue
		for the appropriate port

CALLED BY:	INTERNAL (PrefMgrPrintStartPrinting)

PASS:		DS	= DGroup

RETURN:		Carry	= Clear if queue is empty
			= Set if not

DESTROYED:	AX, BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckSpoolEmpty	proc	near
	uses	cx, dx, bp
	.enter

	; Allocate a PrintPortInfo struct, and initialize it
	;
	sub	sp, size PrintPortInfo		; allocate structure on stack
	mov	si, sp
	mov	bx, ds:[printerPort]

EC <	xchg	si, bx			>
EC <	call	ECCheckPrinterPort	>
EC <	xchg	si, bx			>

	mov	ax, PPT_SERIAL
	test	ds:[bx].PPPI_type, mask PC_RS232C
	jnz	setPortType
	mov	ax, PPT_PARALLEL
	test	ds:[bx].PPPI_type, mask PC_CENTRONICS
	jnz	setPortType
	mov	ax, PPT_FILE
setPortType:
	mov	ss:[si].PPI_type, ax		; store the port type
	mov	ax, ds:[bx].PPPI_portNum	; get and store the port number
	mov	ss:[si].PPI_params.PP_serial.SPP_portNum, ax

	; Now call the spooler
	;
	mov	cx, SIT_QUEUE_INFO
	mov	dx, ss				; PrintPortInfo => DX:SI
	call	SpoolInfo			; data handle => BX (maybe)
	cmp	ax, SPOOL_QUEUE_EMPTY		
	je	done
	cmp	ax, SPOOL_QUEUE_NOT_FOUND
	je	done
	stc					; indicate port is busy
done:
	lahf					; save the carry
	add	sp, size PrintPortInfo		; free structure from stack
	sahf					; restore the carry

	.leave
	ret
CheckSpoolEmpty	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Edit/Install dialog box code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterInitiateInstallEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the install/edit dialog box has been opened, and
		perform some set-up work as needed.

CALLED BY:	INTERNAL (MtdHanVisOpen)

PASS:		DS, ES	= DGroup
		CX	= Moniker to use for dialog box

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterInitiateInstallEdit	proc	far

EC <		call	CheckDSDgroup					>
EC <		call	CheckESDgroup					>

	;
	; Set the moniker for the dialog box
	;
		LoadBXSI PrinterInstallEditDialog
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		clr	di
		call	ObjMessage
	;
	; Either initialize the list, or set the default for the printer
	; being edited.
	;
		test	ds:[printerState], mask PS_INSTALL
		jz	editing
		call	PrinterInitEditList
		jmp	initiate
editing:
		call	PrinterSetThingsForInstalledPrinter

initiate:
		LoadBXSI PrinterInstallEditDialog
		call	MyInitiateInteraction
		ret
		
PrefMgrPrinterInitiateInstallEdit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetThingsForInstalledPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the device and port lists for an installed printer

CALLED BY:	PrefMgrPrinterInitiateInstallEdit, 
		PrefMgrInitiatePrinterTest

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/90	Initial version
	don	 5/19/92	Lots of changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterSetThingsForInstalledPrinter	proc	near
	.enter


		sub	sp, GEODE_MAX_DEVICE_NAME_SIZE

	;	
	; Get selected printer from PrinterInstalledList
	;

		mov	si, offset PrinterUI:PrinterInstalledList
		call	PrinterGetSelection	; selected printer => AX
		cmp	ax, GIGS_NONE		; any printer selected ??
		je	done


	;
	; Fetch the printer name and the driver type from the spool
	; library. 
	;
		
		segmov	es, ss
		mov	di, sp				; buffer => ES:DI
		call	SpoolGetPrinterString
		jc	done

	;
	; Set the driver type list.  have it send its status message
	; so that we also update the device list with the proper token
	; chars.  Whee!
	;
if	_MULTIPLE_PRINTER_DRIVER_TYPES
		push	cx
		mov	cl, dl
		mov	si, offset PrinterTypeList
		call	PrinterSetSelectionSendStatus
		pop	cx
endif
		
	;
	; Set the category for all UI objects, including the serial
	; port options box, and then have them load their options.
	;

		mov	cx, es
		mov	dx, sp
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	si, offset PrinterInstallEditDialog
		call	ObjMessage_printer_send

		mov	ax, MSG_META_LOAD_OPTIONS
		mov	si, offset PrinterInstallEditDialog
		call	ObjMessage_printer_send
		
if PZ_PCGEOS
else
		mov	ax, MSG_META_LOAD_OPTIONS
		mov	si, offset PrinterConnectedItemGroup
		call	ObjMessage_printer_send
endif

		call	SerialSetOptionsCategory
		call	SerialLoadOptions

	;
	; Set the PrinterNameText to the specified printer name (moved after
	; MSG_META_LOAD_OPTIONS call to make sure name doesn't get changed
	; to default by setting the port & driver -- ardeb 11/6/94)
	;

		mov	dx, ss
		mov	bp, sp
		mov	si, offset PrinterNameText
		call	PrinterSetText

	;
	; Enable & disable the various entries in the Ports list, and
	; the "Serial Port Options" dialog.
	;

		call	PrinterSetPortsStatus	
		call	PrinterSetSerialStatus	

done:
		add	sp, GEODE_MAX_DEVICE_NAME_SIZE
		clc

		.leave
		ret
PrinterSetThingsForInstalledPrinter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterChangeDriverType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the type of displayed printer drivers

PASS:		DS, ES	= DGroup
		CL	= PrinterDriverType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_MULTIPLE_PRINTER_DRIVER_TYPES
driverTypeTable	TokenChars	\
	<'P', 'R', 'D', 'R'>,
	<'P', 'L', 'D', 'R'>,
	<'F', 'X', 'D', 'R'>,
	<'C', 'A', 'D', 'R'>,
	<'O', 'T', 'D', 'R'>
	
PrefMgrPrinterChangeDriverType	method	PrefMgrClass,\
				MSG_PRINTER_CHANGE_DRIVER_TYPE

		mov	ds:[printerDevice], cl
		
		segmov	es, ss
		sub	sp, size TokenChars
		mov	di, sp

		segmov	ds, cs
		mov	bl, cl
		clr	bh

		shl	bx
		shl	bx
DBCS <		shl	bx		>
		lea	si, cs:driverTypeTable[bx]
		mov	cx, size TokenChars/2
		rep	movsw

		mov	dx, size TokenChars
		mov	bp, sp
		mov	ax, MSG_PREF_TOC_LIST_SET_TOKEN_CHARS
		mov	di, mask MF_CALL or mask MF_STACK
		LoadBXSI PrinterList
		call	ObjMessage

		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx, di
		call	ObjMessage

		
		add	sp, size TokenChars
		ret
PrefMgrPrinterChangeDriverType	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterInitEditList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer list

CALLED BY:	VisOpenPrinterInstallEdit, PrefMgrPrinterChangeDriverType
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterInitEditList	proc	near
	
if	_MULTIPLE_PRINTER_DRIVER_TYPES
	;
	; have the list default to "printer" when it comes up
	;
	mov	si, offset PrinterTypeList
	mov	cx, PDT_PRINTER
	call	PrinterSetSelectionSendStatus
endif

	; Set the new selection, set it dirty, and send status message
	;
	mov	si, offset PrinterUI:PrinterList
	clr	cx
	call	PrinterSetSelection
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	dec	cx				; non-zero to indicate modified
	call	ObjMessage_printer_send
	GOTO	PrinterSendStatusMsg

PrinterInitEditList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterDeviceSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Responds to the status message sent by the PrinterList
		(printer device list)

CALLED BY:	MSG_PRINTER_DEVICE_SELECTED

PASS:		ds, es	= DGroup
		cx	= Selected printer #
		dl	- GenItemGroupStateFlags

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterDeviceSelected	method dynamic	PrefMgrClass,
					MSG_PRINTER_DEVICE_SELECTED

		test	dl, mask GIGSF_MODIFIED
		jz	afterSetName
		call	PrinterStuffName

afterSetName:

	;
	; Set the printer port to be selected, and re-draw the printer name
	;

		call	PrinterSetPortsStatus		; enable/disable ports
		mov	bx, ds:[printerPort]

EC <		push	si			>
EC <		mov	si, bx			>
EC <		call	ECCheckPrinterPort	>
EC <		mov	si, di			>
EC <		call	ECCheckPrinterPort	>
EC <		pop	si			>

		mov	ah, ds:[bx].PPPI_type

	;
	; See if the printer port is still usable (carry SET if
	; usable).  If not, then reset it
	;

		call	PrinterGetPortStatus		; port still enabled ??
		jc	done

	;
	; We need to reset the port, as the old one became unusable
	;
		
		mov	cx, di				; port offset => CX
		mov	si, offset PrinterPortList
		call	PrinterSetSelectionSendStatus	; set selection
							; & send status

done:
		ret
PrefMgrPrinterDeviceSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetPortsStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable the ports based on the printer's connection
		capabilities

CALLED BY:	INTERNAL

PASS:		DS	= DGroup

RETURN:		DI	= Offset to 1st available port's PrefPrinterPortInfo

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

printerPortHandles	word	\
	offset	Lpt1Item,		; LPT1
	offset	Lpt2Item,		; LPT2
	offset	Lpt3Item,		; LPT3
	offset	Com1Item,		; COM1
	offset	Com2Item,		; COM2
	offset	Com3Item,		; COM3
	offset	Com4Item,		; COM4
	offset	FileItem,		; FILE
	offset	UnknownItem		; NOTHING

.assert (length printerPortHandles eq NUM_PRINTER_PORTS)

PrinterSetPortsStatus	proc	near
		.enter

EC <		call	CheckDSDgroup					>
	
	; Determine the ports this driver supports
	;
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		mov	si, offset PrinterUI:PrinterList
		call	ObjMessage_printer_call		; ax - info
							; field (actually AL)

	;
	; Enable/disable the port list entries as appropriate
	;

		clr	di				; no port available
		mov	bx, offset FIRST_PRINTER_PORT
		mov	cx, NUM_PRINTER_PORTS

portList:
		mov	ah, es:[bx].PPPI_type
		mov	si, NUM_PRINTER_PORTS
		sub	si, cx
		shl	si, 1
		mov	si, cs:[printerPortHandles][si]
		call	PrinterEnableDisablePort
		jnc	next
		tst	di
		jnz	next
		mov	di, bx
next:
		add	bx, size PrefPrinterPortInfo
		loop	portList

	;
	; Don't return 0, as it's a bogus value.
	;
		
		tst	di
		jnz	done
		mov	di, offset nothingInfo
done:		
		.leave
		ret
PrinterSetPortsStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterPortSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record what printer port has been chosen by the user

CALLED BY:	MSG_PRINTER_PORT_SELECTED

PASS:		ds, es	= dgroup
		cx	= identifier of selected item 
			(Offset to PrefPrinterPortInfo structure)
		dl	- GIGSF_MODIFIED, set or clear

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterPortSelected	method	PrefMgrClass, MSG_PRINTER_PORT_SELECTED

	;
	; Enable/disable the "Serial Port Options" trigger based on the port
	; selected.
	;
EC <		xchg	cx, si			>
EC <		call	ECCheckPrinterPort	>
EC <		xchg	cx, si			>

		mov	ds:[printerPort], cx

		push	dx
		call	PrinterSetSerialStatus
		pop	dx

	; Only stuff the name if modified by the user (as opposed to
	; set initially)

		test	dl, mask GIGSF_MODIFIED
		jz	done

	; Adjust the printer name accordingly.
	;
		call	PrinterStuffName
done:
		ret

PrefMgrPrinterPortSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetSerialStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the serial options trigger

CALLED BY:	INTERNAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterSetSerialStatus	proc	near

	; Enable or disable the serial options trigger
	;
	mov	si, ds:[printerPort]

EC <	call	ECCheckPrinterPort		>

	mov	ax, MSG_GEN_SET_ENABLED
	test	ds:[si].PPPI_type, mask PC_RS232C
	jnz	doSet
	mov	ax, MSG_GEN_SET_NOT_ENABLED
doSet:
	mov	dl, VUM_NOW
	mov	si, offset PrinterUI:SerialPortOptions
	GOTO	ObjMessage_printer_call
PrinterSetSerialStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterInstallEditApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A user has selected a printer to be installed or edited

CALLED BY:	GLOBAL (MSG_PRINTER_INSTALL_EDIT)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		get entries from PrinterList and PrinterPortList
		combine the two and add it to the 'printers' category
		inc 'numberOfPrinters' value in the init file
		create a category for the printer and store:
		    the printer name
		    the driver name
		    the device name
		    the port
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrPrinterInstallEditApply	method dynamic	PrefMgrClass,
					MSG_PRINTER_INSTALL_EDIT_APPLY
	.enter

	; First, check to see if a printer in the list has been
	; selected. If not, display an error message and abort.
	;
	mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
	mov	si, offset PrinterList
	call	ObjMessage_printer_call
	jnc	checkName			; carry clear, so we're fine
	LoadBXSI	PrinterNotSelectedErrorString
	call	DoError	
	jmp	exit

	; Check converted-to-ini-category printer name length
checkName:
	push	ds
	mov	si, offset PrinterUI:PrinterNameText
	call	PrinterGetText			; bx = block, cx = length
	jcxz	lengthOK
	tst	bx
	jz	lengthOK
	call	MemLock
	mov	ds, ax
	clr	si
	clr	dx				; dx = converted length
lengthLoop:
	inc	dx				; at least one byte
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, 0x80		; ASCII?
	jbe	lengthNext			; regular ASCII, one byte
SBCS <	add	dx, 1				; non-ASCII char, two bytes>
DBCS <	add	dx, 3				; non-ASCII wchar, four bytes>
lengthNext:
	loop	lengthLoop
	cmp	dx, MAX_INITFILE_CATEGORY_LENGTH
	jb	lengthOKFree
	mov	cx, ds				; cx:dx = name
	clr	dx
	pop	ds				; restore
	push	bx				; save name block
	LoadBXSI	PrinterNameTooLongErrorString
	call	DoError
	jmp	done

lengthOKFree:
	call	MemFree
lengthOK:
	pop	ds

	; Delete the current printer, if we're not installing a new one
	;
	test	ds:[printerState], mask PS_INSTALL
	jnz	install
	call	PrefMgrPrinterDelete		; delete the current printer

	; Install the new printer
install:
	mov	ax, -1				; put up verify dialog box
	call	VerifyPortSelection		; verify port selection
	tst	ax				; if any error, don't install
	jnz	exit

	; Create the category & basic information
	;
	call	PrinterCreateCategory		; printer name => ES:DI
	push	bx				; save memory handle
	mov	cl, ds:[printerDevice]		; PrinterDriverType => CL
	call	SpoolCreatePrinter		; install into printer list
	movdw	cxdx, esdi			; printer name => CX:DX
	jc	createError			; jump if error

	; Write out all of the data stored with the printer
	;
	push	ax				; save the new printer #
	inc	ds:[printerNumInstalled]	; increment installed count

	; Set the initfile category for all UI objects.  These
	; messages are a SEND, 'cause we're under one thread and we
	; don't want to trash CX or DX.
	;
	mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
	LoadBXSI	PrinterInstallEditDialog
	call	ObjMessage_printer_send

	; Send save-options list to both the PrinterList and the
	; PrinterPortList 
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	LoadBXSI	PrinterInstallComp1
	call	ObjMessage_printer_send
	
if PZ_PCGEOS
else
	mov	ax, MSG_META_SAVE_OPTIONS
	LoadBXSI	PrinterConnectedItemGroup
	call	ObjMessage_printer_send
endif

	; Write all of the port options out, as needed
	;
	mov	si, ds:[printerPort]
EC <	call	ECCheckPrinterPort		>
	cmp	ds:[si].PPPI_port, PPT_SERIAL
	jne	updateUI
	call	SerialSetOptionsCategory	; set the options category
	call	SerialSaveOptions		; save serial port options

	; Finally, update all of the UI gadgetry
updateUI:
	mov	cx, ds:[printerNumInstalled]
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessage_PIL_send
	pop	cx				; printer #
	call	PrinterSetSelectionSendStatus	; set new selection & send msg
	call	UpdateDefaultPrinterUI		; update default printer UI

	; Clean up
done:
	pop	bx
	call	MemFree				; free block holding name
exit:
	.leave
	ret

	; Error in creating the printer, so delete the category
createError:
	LoadBXSI	PrinterNameExistsErrorString
	call	DoError	
	jmp	done
PrefMgrPrinterInstallEditApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterEnableDisablePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable or enable the passed port, depending on masks passed

CALLED BY:	PrefMgrPrinterDeviceSelected

PASS:		DS	= DGroup
		SI	= Chunk handle of PrefStringItem in PrinterUI
		AL	= PrinterConnections (for device)
		AH	= PrinterConnections (for specific port entry)

RETURN:		Carry	= Clear (not available)
			= Set (available)

DESTROYED:	DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterEnableDisablePort	proc	near
	uses	ax, bx, cx, di
	.enter

	; Determine if type of port is supported
	;
	mov	bp, MSG_GEN_SET_NOT_ENABLED
	call	PrinterGetPortStatus
	jnc	setStatus
	mov	bp, MSG_GEN_SET_ENABLED
setStatus:
	pushf
	xchg	ax, bp
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_printer_send
	popf

	.leave
	ret
PrinterEnableDisablePort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetPortStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a port can be used by this device

CALLED BY:	PrinterEnableDisablePort
	
PASS:		ds	= dgroup
		si	- chunk handle of PrefStringItem
		al	= PrinterConnections (for device)
		ah	= PrinterConnections (for specific port entry)

RETURN:		Carry	= Clear (not enabled)
			= Set (enabled)

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetPortStatus	proc	near
		uses	di
		.enter

	; Determine if type of port is supported
	;
		test	al, ah			; test port against device
		jz	done			; if device can't handle, jump
	
	; Type is selected. Now check for specifics
	;
		test	ah, not (mask PC_RS232C or mask PC_CENTRONICS)
		jnz	enable

		mov	ax, MSG_PREF_PORT_ITEM_GET_STATUS
		mov	bx, handle PrinterPortList
		mov	di, mask MF_CALL
		call	ObjMessage

		tst	ax
		jz	done
enable:
		stc
done:
		.leave
		ret
PrinterGetPortStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterStuffName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs name of printer into text object

CALLED BY:	INTERNAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterStuffName	proc	far
	.enter

	; Create the string in a buffer, and then stuff the text object
	;
	mov	di, offset printerNameBuf
	mov	bp, length printerNameBuf
	call	PrinterCreateName
	mov	dx, es
	mov	bp, di				; string => DX:BP
	mov	si, offset PrinterUI:PrinterNameText
	push	dx, bp
	call	PrinterSetText			; set NULL-terminated text

	;
	; Also, set the category of the serial DB
	;
	pop	cx, dx
	call	SerialSetOptionsCategory

	.leave
	ret
PrinterStuffName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterCreateName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a printer name by tacking on the port name to the
		device name.  If no device exists (ie. no printer drivers
		present), a string stating that such is the case will be used.

CALLED BY:	INTERNAL

PASS:		ES:DI	= Buffer to hold name
		BP	= Size of buffer (# chars)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterCreateName	proc	near
	uses	di
	.enter

	;
	; Try to get the selected name from the device list
	;
	mov	cx, es
	mov	dx, di				; buffer => CX:DX
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	mov	si, offset PrinterList
	call	ObjMessage_printer_call
	mov	di, dx				; name buffer => ES:DI
	tst	bp				; name found ??
	jz	noName				; nope, so use generic no-name
ifdef GPC_VERSION
	jmp	done
else		
	add	di, bp				; ES:DI => end of string

	; Add the " on " string, if it is needed
	;
	mov	si, ds:[printerPort]		; PrefPrinterPortInfo => DS:SI
	test	ds:[si].PPPI_type, mask PC_FILE
	jnz	portName
	mov	bx, handle printerOnString
	mov	si, offset printerOnString
	call	PrinterLockAndCopy		; lock & copy string
	LocalPrevChar	esdi			; position ES:DI over NULL

	; tack on port name
portName:
	call	PrinterGetPortName		; port name => BX:SI
endif
common:
	call	PrinterLockAndCopy		; lock & copy string
done::
	.leave
	ret

	; A printer is not selected, so use the "no name" string
noName:
	mov	bx, handle noPrinterNameString
	mov	si, offset noPrinterNameString
	jmp	common				; copy in string
PrinterCreateName	endp

PrinterLockAndCopy	proc	near
	uses	ds
	.enter

	call	StringLock
	mov	ds, dx
	mov	si, bp				; string => DS:SI
	LocalCopyString
	call	MemUnlock

	.leave
	ret
PrinterLockAndCopy	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetPortName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of a port

CALLED BY:	PrinterCreateName

PASS:		DS	= DGroup

RETURN:		BX:SI	= OD of string chunk

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC_VERSION
PrinterGetPortName	proc	near
	uses	di
	.enter

EC <	call	CheckDSDgroup						>
	
	mov	si, offset PrinterPortList
	call	PrinterGetSelection		; selection => AX
	mov	si, ax				; PrefPrinterPortInfo => DS:SI
	mov	bx, handle lpt1String
	mov	si, ds:[si].PPPI_string

	.leave
	ret
PrinterGetPortName	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterCreateCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create & initialize a new print category

CALLED BY:	PrefMgrPrinterInstallEdit

PASS:		Nothing

RETURN:		ES:DI	= Pointer to name string
		BX	= Block handle holding name (locked)

DESTROYED:	AX, CX, DX, BP, SI

PSEUDO CODE/STRATEGY:
		Creates values for:
			driver name
			device name
			port

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterCreateCategory	proc	near
	.enter

	; Grab the name of the printer
	;
	mov	si, offset PrinterUI:PrinterNameText
	call	PrinterGetText			; text handle => BX
	call	MemLock
	mov	es, ax
	clr	di				; name of printer => ES:DI

	.leave
	ret
PrinterCreateCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyPortSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the port is OK

CALLED BY:	PrinterInstallEditApply

PASS:		es	- dgroup
		ax	- zero to suppress putting up dialog box indicating
				  verification in progress
			- 1 to indicate printer being installed, so box
				  and queries should be posted
		PrinterPortList & SerialPortOptions lists set up for printer
		being verified.

RETURN:		ax	- non-zero if port is not verified

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Verify the printer port (using the handy 
		SpoolVerifyPrinterPort function) 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


VerifyPortSelection proc near
	uses	bx,cx,dx,si,di, ds, es

installing	local	word 		push	ax
portParams	local	PrintPortInfo

	.enter

EC <	call	CheckDSDgroup		; verfiy DS			>

	;
	; get which port we're sending this to, so we can set up
	; the right parameters for SpoolVerifyPrinterPort
	;

	mov	si, ds:[printerPort]	; offset to PrefPrinterPortInfo
	mov	ax, ds:[si].PPPI_port	; printer type => AX
	mov	cx, ds:[si].PPPI_portNum
	mov	portParams.PPI_type, ax
	mov	parallelParams.PPP_portNum, cx
	cmp	ax, PPT_SERIAL
	jne	verifyPort
	call	SerialObtainSettings

	;
	; verify it using the spooler function.  But first, we
	; should let the user know what we're doing
	;

verifyPort:
	tst	ss:[installing]		; put up the box ?
	jz	callSpooler
	mov	di, MSG_GEN_INTERACTION_INITIATE
	call	OpenCloseVerifyStatusDB

	;
	; call spooler to verify the port
	;

callSpooler:
	segmov	ds, ss, si		; get ds:si -> portParams
	lea	si, portParams
	call	SpoolVerifyPrinterPort
	tst	ss:[installing]		; do we need to take it down?
	jz	checkSuccess
	mov	di, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	OpenCloseVerifyStatusDB
checkSuccess:
	sub	ax, SPOOL_OPERATION_SUCCESSFUL
	je	portVerified
	
	; if not installing, don't ask the user about anything.

	mov	ax, -1
	xor	ax, ss:[installing]	; invert installing flag
	jnz	portVerified		; not installing, so don't
					; ask questions

	; something is wrong.  Let the user know.  The strings are
	; in a resource, so lock it down

	push	bp			; save frame pointer
	mov	bx, handle Strings
	push	bx			; save the handle
	call	MemLock

	; display first error box

	mov	ds, ax			; di -> resource
	xchg	di, ax			; di -> resource
	assume	ds:Strings
	mov	bp, ds:[VerifyErrorString]
	mov	ax, CustomDialogBoxFlags<1, CDT_QUESTION, GIT_AFFIRMATION,0>
	call	PrefMgrUserStandardDialog

	; if user still wants to install, even though port could
	; not be verified, then confirm this

	cmp	ax, IC_YES		; if he says yes...
	mov	ax, -1			; assume he said no...
	jne	unlockResource
	mov	bp, ds:[VerifyInstallBadString]
	assume	ds:dgroup
	mov	ax, CustomDialogBoxFlags<1,CDT_NOTIFICATION,\
					 GIT_NOTIFICATION,0>
	call	PrefMgrUserStandardDialog
	clr	ax
unlockResource:
	pop	bx			; restore handle
	call	MemUnlock		; release the resource
	pop	bp			; restore frame pointer
portVerified:
	.leave
	ret
VerifyPortSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenCloseVerifyStatusDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display or bring down the VerifyStatus dialog box

CALLED BY:	VerifyPortSelection
	
PASS:		DI	= Method to send
		CX	= Data to send

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenCloseVerifyStatusDB	proc	near
	uses	ax, bp
	.enter

	xchg	ax, di
	mov	bx, handle VerifyStatusBox
	mov	si, offset VerifyStatusBox
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
OpenCloseVerifyStatusDB	endp


	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Paper & Document Size defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrPrinterSetDefaultSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the default document & paper size

CALLED BY:	GLOBAL (MSG_PRINTER_SET_DEFAULT_SIZE)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, DX, BP, SI, DS

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrPrinterSetDefaultSize	method dynamic	PrefMgrClass,
						MSG_PRINTER_SET_DEFAULT_SIZE
	.enter

	;
	; First complete the apply
	;

	mov	ax, MSG_GEN_APPLY
	mov	si, offset PrinterSizeSummons
	call	ObjMessage_printer_send

	;	
	; Get the default page size information
	;

	sub	sp, size PageSizeReport
	mov	dx, ss
	mov	bp, sp				; PageSizeReport => DX:BP
	mov	ax, MSG_PZC_GET_PAGE_SIZE
	mov	si, offset PSPageSizeControl
	call	ObjMessage_printer_call

	;
	; Store the new defaults
	;

	segmov	ds, ss
	mov	si, bp				; PageSizeReport => DS:SI
	call	SpoolSetDefaultPageSizeInfo
	add	sp, size PageSizeReport

	.leave
	ret
PrefMgrPrinterSetDefaultSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Basic utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_printer_[send, call]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send (or call) a message to an object in the printer resource

CALLED BY:	INTERNAL

PASS:		AX	= Message
		SI	= Chunk handle in PrinterDndModemUI resource
		CX,DX,BP= Parameters

RETURN:		BX	= Handle PrinterUI

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_printer_send	proc	near
	clr	di
	GOTO	OMCommon
ObjMessage_printer_send	endp


ObjMessage_printer_call	proc	near
	mov	di, mask MF_CALL
	FALL_THRU	OMCommon
ObjMessage_printer_call	endp

OMCommon	proc	near
	mov	bx, handle PrinterUI
	call	ObjMessage
	ret
OMCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_PIL_[send, call]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send (or call) a message to the PrinterInstalledList object

CALLED BY:	INTERNAL

PASS:		AX	= Message
		CX,DX,BP= Parameters

RETURN:		see ObjMessage

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_PIL_send	proc	near
	clr	di
	GOTO	OMPILCommon
ObjMessage_PIL_send	endp

ObjMessage_PIL_call	proc	near
	mov	di, mask MF_CALL
	FALL_THRU	OMPILCommon
ObjMessage_PIL_call	endp

OMPILCommon		proc	near
	mov	bx, handle PrinterInstalledList
	mov	si, offset PrinterInstalledList
	GOTO	OMCommon
OMPILCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetSelection, PrinterSetSelectionSendStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection of a GenItemGroup in the printer UI resource
		The "SendStatus" will, of course, send the status message.

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle in PrinterUI resource
		CX	= Selection

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterSetSelectionSendStatus	proc	near
	call	PrinterSetSelection
	FALL_THRU	PrinterSendStatusMsg
PrinterSetSelectionSendStatus	endp

PrinterSendStatusMsg	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	GOTO	ObjMessage_printer_send
PrinterSendStatusMsg	endp

PrinterSetSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; have a determinate selection
	GOTO	ObjMessage_printer_send
PrinterSetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection of a GenItemGroupClass object

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle in PrinterUI resource

RETURN:		AX	= Selection

DESTROYED:	BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GOTO	ObjMessage_printer_call
PrinterGetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a text object with a null-terminated text string

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle for object in PrinterUI resource
		DX:BP	= Text string (null-terminated)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterSetText	proc	near
	uses	di
	.enter
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	call	ObjMessage_printer_call
	.leave
	ret
PrinterSetText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the text from a text object, storing it in an block

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle for object in PrinterUI resource

RETURN:		BX	= Block handle holding text
		CX	= Length of text in block

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetText	proc	near
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	call	ObjMessage_printer_call
	mov	bx, cx
	mov_tr	cx, ax
	ret
PrinterGetText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable a UI object, based on passed value

CALLED BY:	INTERNAL

PASS:		SI	= Chunk handle of object in PrinterUI resource
		cx	- GIGS_NONE -- diable
			  any other value -- enable

RETURN:		Nothing

DESTROYED:	AX, BX, dx, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterEnableDisable	proc	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	cx, GIGS_NONE
	je	setStatus
	mov	ax, MSG_GEN_SET_ENABLED

setStatus:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	GOTO	ObjMessage_printer_send
PrinterEnableDisable	endp




if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPrinterPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that ds:si is a pointer to a PrintPortInfo
		structure. 

CALLED BY:	internal

PASS:		ds:si - pointer to check
		(allow SI = GIGS_NONE as well)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ptrTable	nptr	lpt1Info,
	lpt2Info,	
	lpt3Info,	
	com1Info,	
	com2Info,	
	com3Info,	
	com4Info,	
	fileInfo,	
	nothingInfo	

ECCheckPrinterPort	proc near
	uses	bx,cx

	.enter
EC <	call	CheckDSDgroup			>

	pushf

	mov	bx, offset ptrTable
	mov	cx, length ptrTable
startLoop:
	cmp	cs:[bx], si
	je	done
	add	bx, size word
	loop	startLoop
	ERROR	ILLEGAL_VALUE
done:

	popf

	.leave
	ret
ECCheckPrinterPort	endp

endif
