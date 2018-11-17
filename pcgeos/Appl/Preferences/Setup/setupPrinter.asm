COMMENT @--------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Graphical Setup -- Printer selection
FILE:		setupPrinter.asm

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
		
	$Id: setupPrinter.asm,v 1.1 97/04/04 16:28:11 newdeal Exp $

----------------------------------------------------------------------------@

idata	segment

; Buffer into which the printer category name is built.
;
SBCS <printerCategoryString char	GEODE_MAX_DEVICE_NAME_LENGTH dup(0)>
DBCS <printerCategoryString wchar	GEODE_MAX_DEVICE_NAME_LENGTH dup(0)>

idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the selection of a printer by the user.

CALLED BY:	MSG_SETUP_PRINTER_SELECTED
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

serialPortToMap	word	(mask SDM_COM1), \
			(mask SDM_COM2), \
			(mask SDM_COM3), \
			(mask SDM_COM4), \
			(mask SDM_COM5), \
			(mask SDM_COM6), \
			(mask SDM_COM7), \
			(mask SDM_COM8)

SetupPrinterSelected	method	SetupClass, MSG_SETUP_PRINTER_SELECTED
		.enter
	;
	; Find the printer the user selected.
	;
		mov	bx, handle PrinterSelectList
		mov	si, offset PrinterSelectList
		call	UtilGetSelection
		cmp	cx, -1		; => errant ENTER pressed
		je	nothingSelected
		
		mov	ds:[printerDevice], cx
		mov	ds:[ptestState], 0
	;
	; Fetch the extra word of info for the device so we know what ports
	; to enable/disable.
	;

		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ds:[printerInfo], al	; 1 byte only...

		test	ax, mask PC_RS232C or mask PC_CENTRONICS
		jz	noPrinter
	;
	; Now enable/disable the serial port selections. No ports should
	; be available if it's not a serial port, else all ports except
	; for the one occupied by the mose should be available
	;
		mov	dx, 0xffff		; assume no serial conenction
		test	ax, mask PC_RS232C
		jz	doSerial
		clr	dx			; assume all serial ports avail
		test	ds:[mouseInfo], mask MEI_SERIAL
		jz	doSerial		; not a serial mouse - good!
		mov	bx, ds:[mousePort]	; else mask out this port
		mov	dx, cs:[serialPortToMap][bx]
doSerial:
		call	SetupEnableDisableSerial
	;
	; Now enable/disable the parallel port selections, depending on
	; whether or not a parallel connection is found
	;
		mov	dx, 0xffff		; assume no parallel connection
		test	ax, mask PC_CENTRONICS	; is a conenction there ??
		jz	doParallel
		clr	dx			; else enable all ports
doParallel:
		call	SetupEnableDisableParallel

		mov	bx, handle PrinterPortScreen
		mov	si, offset PrinterPortScreen
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		clr	di
		call	ObjMessage

	;
	; Finally, choose a default printer port, and show the screen
	;
		call	ChooseDefaultPort
		mov	bx, handle PrinterPortScreen
		mov	si, offset PrinterPortScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
sendMessage:
		clr	di
		call	ObjMessage
done:
		.leave
		ret

noPrinter:
	;
	; If user selected "None" conclude this test of the emergency
	; printing network...
	; 
		mov	ax, MSG_SETUP_PRINTER_TEST_COMPLETE
		mov	bx, handle 0
		jmp	sendMessage

nothingSelected:
	;
	; User hit enter without first selecting a printer.
	; Nice try, but it won't work.  Tell them to try again.
	;
		mov	si, offset NoPrinterSelectedError
		mov	bp,
			 CustomDialogBoxFlags<1,CDT_ERROR,GIT_NOTIFICATION,0>
		call	SetupPrinterDoDialog	; ax <- InteractionCommand
		jmp	done

SetupPrinterSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseDefaultPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose the default printer port, with preference towards
		the first parallel port available

CALLED BY:	SetupPrinterSelected
	
PASS:		ds - dgroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/2/91		Initial version
	dloft	5/14/92		GenList->GenItemGroup changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

portList	nptr	Lpt1Item, Lpt2Item, Lpt3Item, \
		 	Com1Item, Com2Item, Com3Item, Com4Item;

ChooseDefaultPort	proc	near
		.enter
EC <		call    CheckDSDgroup					>
	;
	; Loop through the table, looking for an enabled port (GenListEntry)
	;
		mov	bx, handle Interface
		clr	bp
portLoop:
		mov	si, cs:[portList][bp]	; OD of GenListEntry => BX:SI
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjMessage		; is it ENABLE'd ??
		jc	found			; yes, so we are home free
		add	bp, size nptr
		cmp	bp, (length portList) * (size nptr)
		jl	portLoop
	;
	; Make the enabled port the exclusive
	;
found:
	;
	; Get the identifier of the thang and save it in printerPort
	;
		mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax <- identifier, and offset
		mov	ds:[printerPort], ax	;   to a PrefPrinterPortInfo
						;   structure
		mov	cx, ax
		clr	dx
		mov	si, offset PrinterPortList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	di
		call	ObjMessage
		.leave
		ret
ChooseDefaultPort	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	UpdateInitFileForPrinter

DESCRIPTION:	Update the ini file to contain all the parameters for the
		selected printer/port.

CALLED BY:	INTERNAL (SetupPrinterTestComplete, SetupInitiatePrinterTest)

PASS:		ds,es - dgroup

RETURN:		nothing

DESTROYED:	bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	Adam	10/90		Changed to use new PrefDevice common code.

---------------------------------------------------------------------------@

UpdateInitFileForPrinter	proc	near	uses bp
	.enter
EC<	call	CheckDSDgroup						>
EC<	call	CheckESDgroup						>

	; If printerInfo contains neither serial nor parallel support,
	; user must not want to install any printer. 

	test	ds:[printerInfo], mask PC_RS232C or mask PC_CENTRONICS
	jz	noPrinter	

	; If a printer has already been added, delete it before continuing.

	mov	di, offset printerCategoryString
	tst	{byte}ds:[di]
	jz	firstPrinter
	call	SetupNoPrinter		; delete the old printer

firstPrinter:
	mov	bp, size printerCategoryString
	call	CreatePrinterName	; create name for printer (& category)

	; Now write out the driver, device, & port information

	call	InitPrinterCategory	; initialize the category

	; Now add the printer to the installed list

	mov	di, offset printerCategoryString
	mov	cl, PDT_PRINTER		; we're installing a printer
	call	SpoolCreatePrinter	; ax <- new printer number

	; update the serial options if needed

	mov	bp, ds:[printerPort]
	test	ds:[bp].PPPI_type, mask PC_RS232C
	jz	done

	mov	si, offset printerCategoryString
	mov	cx, ds
	mov	dx, offset baudRateKeyString
	mov	bp, 9600
	call	InitFileWriteInteger

	mov	dx, offset wordLengthKeyString
	mov	bp, 8
	call	InitFileWriteInteger

	mov	dx, offset stopBitsKeyString
	mov	bp, 1
	call	InitFileWriteInteger

	mov	dx, offset parityKeyString
	mov	di, offset defaultParityString
	call	InitFileWriteString
	
	mov	dx, offset handshakeKeyString
	mov	di, offset defaultHandshakeString
	call	InitFileWriteString
done:
	ornf	ds:[ptestState], mask PTS_INSTALLED;flag printer as installed

	.leave
	ret

noPrinter:
	call	SetupNoPrinter
	jmp	done

UpdateInitFileForPrinter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePrinterName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the name for the printer

CALLED BY:	UpdateInitFileForPrinter

PASS:		DS	= DGroup
		ES:DI	= Buffer in which to place string
		BP	= Buffer size

RETURN:		ES:DI	= Filled buffer, NULL-terminated

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:
		Get the device name
		Append the " on " string, unless we're printing to a file
		Append the port string, which is a localized string

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreatePrinterName	proc	near
	uses	di
	.enter

	; Get the selected name
	;
EC<	call	CheckDSDgroup			; verfiy DGroup		>
	mov	cx, es
	mov	dx, di				; buffer => CX:DX
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	mov	si, offset Interface:PrinterSelectList
	call	ObjMessage_interface_call
	mov	di, dx				; name buffer => ES:DI
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
	mov	si, ds:[printerPort]		; PrefPrinterPortInfo => DS:SI
	mov	bx, handle lpt1String
	mov	si, ds:[si].PPPI_string
	call	PrinterLockAndCopy		; lock & copy string

	.leave
	ret
CreatePrinterName	endp

PrinterLockAndCopy	proc	near
	uses	ds
	.enter

	call	SetupLockString			; string => DS:SI
	ChunkSizePtr	ds, si, cx		; length => CX
	rep	movsb				; copy the string (w/ NULL)
	call	MemUnlock			; unlock Strings block

	.leave
	ret
PrinterLockAndCopy	endp	

ObjMessage_interface_call	proc	near
	mov	di, mask MF_CALL
	GOTO	ObjMessage_interface_common
ObjMessage_interface_call	endp

ObjMessage_interface_send	proc	near
	clr	di
	FALL_THRU	ObjMessage_interface_common
ObjMessage_interface_send	endp

ObjMessage_interface_common	proc	near
	mov	bx, handle Interface
	call	ObjMessage
	ret
ObjMessage_interface_common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrinterCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the installed printer category information.

CALLED BY:	UpdateInitFileForPrinter

PASS:		DS, ES	= DGroup
			  printerCategoryString filled
			
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Write out the:
			driver name
			device name
			port string

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPrinterCategory	proc	near
	.enter
	
EC<	call	CheckDSDgroup						>
EC<	call	CheckESDgroup						>

	; Set the initfile category for UI objects
	;
		mov	cx, ds
		mov	dx, offset printerCategoryString
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	si, offset Interface:PrinterSelectList
		call	ObjMessage_interface_send

		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	si, offset Interface:PrinterPortList
		call	ObjMessage_interface_send

	; Write out the driver & device name
	;
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	si, offset PrinterSelectList
		call	ObjMessage_interface_send

	; Write out the port to use.
	;
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	si, offset PrinterPortList
		call	ObjMessage_interface_send

	.leave
	ret
InitPrinterCategory	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSetPrinterPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the port chosen by the user.

CALLED BY:	MSG_SETUP_SET_PRINTER_PORT
PASS:		ds	= dgroup
		cx	= offset of SetupPrinterPort structure of chosen port
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSetPrinterPort method	SetupClass, MSG_SETUP_SET_PRINTER_PORT
		.enter
	;
	; First record the selected port.
	;
		mov	ds:[printerPort], cx
	;
	; Set the ptestState flags to 0 to make sure we verify the chosen
	; port.
	; 
		mov	ds:[ptestState], 0
		.leave
		ret
SetupSetPrinterPort endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterPortSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the selection of a port for the printer by the
		user.

CALLED BY:	MSG_SETUP_PRINTER_PORT_SELECTED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupPrinterPortSelected method SetupClass, MSG_SETUP_PRINTER_PORT_SELECTED
		.enter
		mov	si, ds:[printerPort]
		test	ds:[si].PPPI_type, mask PC_RS232C
		jnz	doSerialStuff
		mov	si, offset PrinterTestScreen
		mov	bx, handle PrinterTestScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
done:
		.leave
		ret
doSerialStuff:
		mov	ax, ds:[si].PPPI_portNum
		mov	si, offset PrinterSerialScreen
		mov	bx, handle PrinterSerialScreen
		mov	dx, offset PrinterSerialIntScreen
		mov	cx, handle PrinterSerialIntScreen
		call	SetupNextSerialScreen
		jmp	done
SetupPrinterPortSelected endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterIntSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the setting of the interrupt for the serial
		port into which the printer's been plugged.

CALLED BY:	MSG_SETUP_PRINTER_INT_SELECTED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupPrinterIntSelected method SetupClass, MSG_SETUP_PRINTER_INT_SELECTED
		.enter
		mov	bx, handle PrinterSerialIntRange
		mov	si, offset PrinterSerialIntRange
		call	GetRange
		
		mov	si, ds:[printerPort]
		mov	ax, ds:[si].PPPI_portNum
		call	SetupDefineSerialPort
		jc	backToPortSelect

	; Make sure that the given port/interrupt combination is tested.

		mov	ds:[ptestState], 0

		mov	bx, handle PrinterSerialScreen
		mov	si, offset PrinterSerialScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
sendMethod:
		clr	di
		call	ObjMessage
		.leave
		ret

backToPortSelect:
		mov	bx, handle PrinterSerialIntScreen
		mov	si, offset PrinterSerialIntScreen
		mov	ax, MSG_SETUP_SCREEN_DISMISS
		jmp	sendMethod
SetupPrinterIntSelected	endp




COMMENT @--------------------------------------------------------------------

FUNCTION:	SetupTestPrinter

DESCRIPTION:	Generate the test page for the spooler to print.

CALLED BY:	MSG_SETUP_TEST_PRINTER

PASS:		cx:dx - OD to which to send MSG_PRINTING_COMPLETE
		bp - handle of gstate to use when printing

RETURN:		Nothing

DESTROYED:	ax, bx, cx, dx, si, di, es, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version
	Adam	10/90		Changed to use gstring in lmem resource
	Don	2/91		Changed to use common code & separate strings

----------------------------------------------------------------------------@

SetupTestPrinter	method	SetupClass, MSG_SETUP_TEST_PRINTER

	; We must print the test page. Set-up the defaults
	;
	push	cx, dx				; save the SPC OD
	call	PrintTestDrawCornerMarks	; setup page; draw corner marks
	
	; Print string #1
	;
	mov	si, offset printString1
	call	SetupLockString			; string => DS:SI
	mov	dx, ds
	mov	bp, si				; string => DX:BP
	mov	ax, 150				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	mov	bx, handle Strings
	call	MemUnlock			; unlock resource handle in BX

	; Print string #2
	;
	mov	si, offset printString2
	call	SetupLockString			; string => DS:SI
	mov	dx, ds
	mov	bp, si				; string => DX:BP
	mov	ax, 200				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	mov	bx, handle Strings
	call	MemUnlock			; unlock resource handle in BX

	; Print name of printer (#3)
	;
	push	cx				; save paper width
	mov	cx, FID_DTC_URW_ROMAN
	mov	dx, 18				; font size => DX:AH
	clr	ah
	call	GrSetFont			; use smaller point size
	mov	dx, dgroup			; printer name => DX:BP
	mov	bp, offset printerCategoryString
	pop	cx				; paper Width => CX
	mov	ax, 250				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
 	;
	; Tell the spooler we've sent all we're going to send
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	pop	bx, si
	clr	di
	call	ObjMessage
	ret
SetupTestPrinter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupVerifyPortSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the port is OK

CALLED BY:	SetupInitiatePrinterTest, SetupPrinterTestComplete

PASS:		ds	= dgroup

RETURN:		ax	- PVR_OK if port is ok
			- PVR_BAD_IGNORE if port is not ok, but user doesn't
			  care. PTS_INSTALL_ANYWAY in ptestState tells whether
			  to install the printer anyway.
			- PVR_BAD if port is not ok and user wants to make
			  another choice.

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

parallelParams		equ	<portParams.PPI_params.PP_parallel>
serialParams		equ	<portParams.PPI_params.PP_serial>

SetupVerifyPortSelection proc near
		uses	bx,cx,dx,si,di
portParams		local	PrintPortInfo
		.enter

		mov	si, ds:[printerPort]
		test	ds:[si].PPPI_type, mask PC_RS232C
		LONG	jnz	handleSerialPort

		; it's a parallel port.  just need to set up the port number

		mov	ss:[portParams].PPI_type, PPT_PARALLEL; save port type
		mov	ax, ds:[si].PPPI_portNum
		mov	ss:[parallelParams].PPP_portNum, ax

verifyPort:
		; verify it using the spooler function. 

		push	ds
		segmov	ds, ss, si
		lea	si, ss:[portParams]
		call	SpoolVerifyPrinterPort
		pop	ds

			CheckHack <SPOOL_OPERATION_SUCCESSFUL eq PVR_OK>

		tst	ax
		jz	portVerified

		; something is wrong.  Let the user know.  
		
		ornf	ds:[ptestState], mask PTS_VERIFY_FAILED
		push	bp,ds			; save frame pointer

		mov	si, offset VerifyErrorString
		mov	bp, CustomDialogBoxFlags<1,CDT_QUESTION,GIT_AFFIRMATION,0>
		call	SetupPrinterDoDialog	; ax <- InteractionCommand
		
		mov	bp, PVR_BAD		; assume user wants to not
		cmp	ax, IC_NO		;  advance.
		je	unlockResource

		mov	bp, PVR_BAD_IGNORE 	; flag caller should install
						;  anyway
EC <		call	CheckESDgroup					>
		ornf	es:[ptestState], mask PTS_INSTALL_ANYWAY

unlockResource:
		xchg	ax, bp			; ax <- return value
		pop	bp, ds			; restore frame pointer

portVerified:
		.leave
		ret

		; for serial ports, we need to fetch a whole lot more data.
handleSerialPort:
		mov	portParams.PPI_type, PPT_SERIAL ; save the port type
		mov	ax, ds:[si].PPPI_portNum
		mov	ss:[serialParams].SPP_portNum, ax
    
		; fill in the other parts to the structure.  they are fixed.

		mov	ss:[serialParams].SPP_baud, SB_9600 ; save baud rate
		mov	ss:[serialParams].SPP_format,
			 SerialFormat <0,0,SP_NONE,0,SL_8BITS>
		mov	ss:[serialParams].SPP_mode, SM_RAW ; assume raw
		mov	ss:[serialParams].SPP_flow, mask SFC_SOFTWARE
		mov	ss:[serialParams].SPP_stopRem, 0
		mov	ss:[serialParams].SPP_stopLoc, 0
		
		jmp	verifyPort

SetupVerifyPortSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupInitiatePrinterTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the testing of a printer

CALLED BY:	MSG_SETUP_START_PRINTER_TEST

PASS:		ds = es = dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check to see if the printer port is ok
		if so
		    send the test document

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupInitiatePrinterTest	method	SetupClass, MSG_SETUP_START_PRINTER_TEST
		.enter

	; Before doing anything else, make sure that a printer test has
	; not already been initiated. If any printer info is changed
	; while a test is underway, bad things can happen. ptestState 
	; is cleared when a printer or port is selected.

		test	ds:[ptestState], mask PTS_TESTED
		jnz	exit		

	; Now verify that the port is ok.

		call	SetupVerifyPortSelection
		cmp	ax, PVR_BAD		; did the port check out ?
		je	exit			;  no, don't test it

	; if port's ok, or user wants to install anyway, store the
	; printer in the ini file so the spooler can find it.
		
		ornf	ds:[ptestState], mask PTS_TESTED ; printer is tested
		call	UpdateInitFileForPrinter 

	; if the port's ok, send the message to start the test
	
		test	ds:[ptestState], mask PTS_VERIFY_FAILED
		jnz	exit
                push    bp                      ; save frame pointer
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_ENABLED
		mov	bx, handle PrinterTest
		mov	si, offset PrinterTest
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage              ; let the PrintControl know

		mov     ax, MSG_PRINT_CONTROL_INITIATE_PRINT
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage              ; let the PrintControl know
		pop     bp                      ; restore frame pointer

exit:
		.leave
		ret
SetupInitiatePrinterTest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGetDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a document name for the test page to the spooler

CALLED BY:	MSG_PRINT_GET_DOC_NAME
PASS:		ds	= dgroup
		cx:dx	= PrintControl
		bp	= message to send in return
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure commented out due to changes in the
	PrintControl object	DL 2/9/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGetDocName	method	SetupClass, MSG_PRINT_GET_DOC_NAME
		.enter
	;
	; Lock down the name of our document thingy.
	;
		mov	si, offset PTestDocumentName
		call	SetupLockString
		
	;
	; Return the string to whoever requested it. We have to use MF_CALL
	; so we can safely unlock the string after the call returns...
	; 
		mov	bx, cx
		xchg	si, dx
		mov	cx, ds
		mov	di, mask MF_CALL
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
		call	ObjMessage
	;
	; Let the strings resource done...
	;		
		mov	bx, handle Strings
		call	MemUnlock
		.leave
		ret
SetupGetDocName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vSYNOPSIS:	Print a test file

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

SetupPrinterStartPrinting	method dynamic	SetupClass,
						MSG_PRINT_START_PRINTING
	.enter

	; Check to see if a job is already spooled. If so, notify the
	; user and cancel the spool job
	;
	push	cx, dx				; save the PrintControl chunk
	call	CheckSpoolEmpty			; already printing ??
	jnc	doTest				; no, so print document
	mov	si, offset spoolBusyString
	mov	bp, CustomDialogBoxFlags<1,CDT_ERROR,GIT_NOTIFICATION,0>
	call	SetupPrinterDoDialog
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	jmp	done				; we're outta here

	; We must print the test page. Set-up the defaults
doTest:
	call	PrintTestDrawCornerMarks	; setup page; draw corner marks
	
	; Print string #1
	;
	mov	bx, handle printString1
	mov	si, offset printString1
	call	StringLock			; string => DX:BP
	mov	ax, 150				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	call	MemUnlock			; unlock resource handle in BX

	; Print string #2
	;
	mov	bx, handle printString2
	mov	si, offset printString2
	call	StringLock			; string => DX:BP
	mov	ax, 200				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	call	MemUnlock			; unlock resource handle in BX

	; Print name of printer (#3)
	;
	push	cx				; save paper width
	mov	cx, FID_DTC_URW_ROMAN
	mov	dx, 18				; font size => DX:AH
	clr	ah
	call	GrSetFont			; use smaller point size
	mov	dx, dgroup
	mov	bp, offset printerCategoryString ; printer name buffer => dx:bp
	pop	cx				; paper width => CX
	mov	ax, 250				; vertical offset => AX
	call	PrintTestDrawCenteredString	; draw the damm string
	mov	al, PEC_FORM_FEED		; put out the form feed
	call	GrNewPage

	; Now clean up and leave (expect method in AX at "done" label)
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
done:
	pop	bx, si	
	clr	di
	call	ObjMessage			; send the notification

	.leave
	ret
SetupPrinterStartPrinting	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterTestComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to proceed from the PrinterTestScreen. Do so
		after cleaning up.

CALLED BY:	MSG_SETUP_PRINTER_TEST_COMPLETE
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupPrinterTestComplete method SetupClass, MSG_SETUP_PRINTER_TEST_COMPLETE

	;
	; If printer's been tested, it's been installed and we're fine.
	; If printer's been installed but not tested, the port was not
	; verified, but the user decided to install anyways.
	;
		test	ds:[ptestState], mask PTS_INSTALLED or mask PTS_TESTED
		jnz	nextScreen
		
	;
	; If printerInfo contains neither serial nor parallel support,
	; user must not want to install any printer. We still must call
	; UpdateInitFileForPrinter so the numberOfPrinters gets set to 0...
	; 
		test	ds:[printerInfo], mask PC_RS232C or mask PC_CENTRONICS
		jz	update
	
	;
	; Else, user has chosen a printer, but hasn't tried to test it. Verify
	; the port, at least. If the verify fails, proceed to the next screen,
	; as the user has bailed on the current printer.
	; 
		call	SetupVerifyPortSelection
		cmp	ax, PVR_BAD	; bad printer/port combination?
		je	done		; yes, don't install it.

update:
	;
	; Verify succeeded, or user decided to install the printer anyway,
	; or user did not select any printers.
	;
		call	UpdateInitFileForPrinter

nextScreen:

	;
	; In case this is an upgrade from 1.X:
	;   See if there are any 1.X documents or backgrounds which
	;   were copied to this installation by the install program.
	;
		
		call	SetupFindOldDocuments

		jc	noUpgrade			; directory not found?
		tst	dx				; any 1.X files?
		jz	noUpgrade			; no, skip the upgrade

		mov	bx, handle DocumentUpgradeScreen	
		mov	si, offset DocumentUpgradeScreen
		jmp	initiate

noUpgrade:

		mov	si, offset InstallDoneText	; assume don't ask
		call	SetupAskForSerialNumber?	
		jnc	setupComplete			; don't ask, done

		mov	bx, handle SerialNumberScreen	; else ask for serial#
		mov	si, offset SerialNumberScreen

initiate:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage

	;
	; if we are going to the serial number screen, we're done
	;
		cmp	si, offset SerialNumberScreen
		je	done

	;
	; Else there are documents that need upgrading.  Do it now.
	;
		call	SetupUpgradeAllDocuments

	;
	; Initiate the 'upgrade complete' screen, dismiss the upgrade screen.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	bx, handle DocumentUpgradeCompleteScreen	
		mov	si, offset DocumentUpgradeCompleteScreen
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov	bx, handle DocumentUpgradeScreen	
		mov	si, offset DocumentUpgradeScreen
		clr	di
		call	ObjMessage

		jmp	done
		
setupComplete:
	;
	; Advance to the...DoneScreen! Da daaaaa!
	;
		mov	si, offset InstallDoneText
		call	SetupComplete

done:
		ret

SetupPrinterTestComplete endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupFindOldDocuments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for 1.X files in document directory, or sub-dirs??

CALLED BY:	SetupPrinterTestComplete
PASS:		nothing
RETURN:		dx - 0 if no old VM files
		   - non-zero if old VM files

		carry set if error changing or reading directories

DESTROYED:	ax,bx,cx,dx,ds,si,es,di,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <noDir		char 	0					>
SBCS <backgrndDir	char 	'BACKGRND', 0				>
DBCS <noDir		wchar 	0					>
DBCS <backgrndDir	wchar 	'BACKGRND', 0				>
oldVM		word	GFT_OLD_VM

SetupFindOldDocuments		proc	near
		.enter

		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		call	callApp

	;
	; Push to the document directory.
	; 
		call	FilePushDir
		mov	bx, SP_DOCUMENT
		segmov	ds, cs, di
		mov	dx, offset noDir
		call	FileSetCurrentPath
		jc	done

	;
	; Allocate the matchAttrs array with 2 real entries and 
	; 1 dummy entry to mark the end of the array.
	; 
		sub	sp, (size FileExtAttrDesc * 2)
		segmov	es, ss, di
		mov	di, sp
		push	di

	; 
	; The first two matchAttrs entries say to look for files that are 
	; old VM files or directories.
	;
		mov	es:[di].FEAD_attr, FEA_FILE_TYPE
		mov	es:[di].FEAD_value.segment, cs
		mov	es:[di].FEAD_value.offset, offset oldVM
		mov	es:[di].FEAD_size, size word

		add	di, size FileExtAttrDesc
		mov	es:[di].FEAD_attr, FEA_END_OF_LIST
		pop	di				; es:di <- matchAttrs

		call	SetupFindOldDocumentsLow
		mov	dx, ax
		jc	popDir

		tst	dx			; were old VM files found?
		jnz	popDir			; yes, exit now

	;
	; Now documents were found, check if there are any old background
	; files.  Push to the backgrnd directory.
	; 
		mov	bx, SP_USER_DATA
		segmov	ds, cs, ax
		mov	dx, offset backgrndDir
		call	FileSetCurrentPath
		jc	popDir

		mov	dx, offset noDir	; no dir change on first pass
		call	SetupFindOldDocumentsLow
		mov	dx, ax

popDir:
		lahf
		add	sp, (size FileExtAttrDesc * 2)
		call	FilePopDir
		sahf

done:
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		call	callApp
		.leave
		ret

callApp:
		pushf
		clr	bx
		call	GeodeGetAppObject
		clr	di
		call	ObjMessage
		popf
		retn
SetupFindOldDocuments		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupFindOldDocumentsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate a directory looking for old VM files

CALLED BY:	SetupFindOldDocuments

PASS:		es:di	- matchAttrs
		ds:dx	- directory to change to 

RETURN:		ax	- 0 if no old VM files in this directory
			- non-zero if there are old VM files 

		carry set if error setting path or reading directory

DESTROYED:	dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupFindOldDocumentsLow		proc	near
		uses	bx,cx,si,ds
		.enter

	;
	; move to the next sub directory
	;
		clr	bx			; path is relative 
		call	FileSetCurrentPath
		jc	done

	; 
	; construct the FileEnumParams to pass to FileEnum
	; 
		sub	sp, size FileEnumParams
		mov	bp, sp

	;
	; return longnames of sub-dirs and GEOS non-exec files which 
	; match the attrs in matchAttrs.
	;
		mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_NON_EXECS or \
			mask FESF_DIRS	
		clr	ss:[bp].FEP_skipCount	; don't skip any files
		movdw	ss:[bp].FEP_matchAttrs, esdi
		clr	ss:[bp].FEP_returnAttrs.segment
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME_AND_ATTR
		mov	ss:[bp].FEP_returnSize, size FENameAndAttr
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED

		call	FileEnum		; cx <- count of names returned
						; ^hbx <- buffer

		jc	done			; carry set if error
		clr	ax			; no VM files found yet
		tst	bx			; anything returned?
		clc
		jz	done			; no, we're done
		
		call	MemLock			; lock the returned buffer
		mov	ds, ax

	; 
	; Were any of the file names returned for real files, not 
	; subdirectories?
	;

		clr	si			; ds:si <- first FENameAndAttr
		mov	dx, cx				; save count in dx
		clr	ax				; no files found yet
fileLoop:
		test	ds:[si].FENAA_attr, mask FA_SUBDIR; is it a subdir?
		jz	doneDir				; no, it's a VM file!
		add	si, size FENameAndAttr		; point to next entry
		loop	fileLoop			

	; 
	; No old VM files were found in this directory.  
	; If there are subdirectories, look for old VM files there.
	;	
		clr	si			; ds:si <- first FENameAndAttr
		mov	cx, dx			; cx <- # FENameAndAttr in buf
dirLoop:
		test	ds:[si].FENAA_attr, mask FA_SUBDIR ; is it a subdir?
		jz	continue			; no, continue
		lea	dx, ds:[si].FENAA_name		; ds:dx <- dir name
		call	FilePushDir			; save current dir
		call	SetupFindOldDocumentsLow	; recurse...
		call	FilePopDir			; restore curent dir
		jc	error				; abort if error
		tst	ax				; any VM files found?
		jnz	doneDir				; yes, found one!
continue:
		add	si, size FENameAndAttr		; ds:si <- next entry
		loop	dirLoop						
		mov	ax, -1				; none found	

doneDir:
		inc	ax				; ax = 0 if none found
		call	MemFree				; free FileEnum buffer
		clc					; signal no errors
done:
		.leave
		ret

error:
		call	MemFree				; free FileEnum buffer
		stc					; signal error
		jmp	done
SetupFindOldDocumentsLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupPrinterDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An error has occurred, put up a dialog box to inform
		the user.

CALLED BY:	INTERNAL ()

PASS:		si - chunk handle of string in Strings resource
		cx - chunk handle of 1st string argmunet, if any 
		dx - chunk handle of 2nd string argument, if any
		bp - CustomDialogBoxFlags

RETURN:		nothing

DESTROYED:	ax,bx,si,di,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupPrinterDoDialog		proc	near

	; push on stack: StandardDialogParams structure
	;
		clr	ax
		pushdw	axax			; SDP_helpContext
		pushdw	axax			; SDP_customTriggers

	; Lock the error message strings (all should be in Strings resource)
	;
		mov	bx, handle Strings	; ^lbx:si <- error string
		call	SetupLockString		; ds:si <- error string

		mov	di, dx
		mov	di, ds:[di]
		pushdw	dsdi			; SDP_stringArg2
		mov	di, cx
		mov	di, ds:[di]
		pushdw	dsdi			; SDP_stringArg1
		pushdw	dssi			; SDP_customString

		push	bp			; SDP_customFlags
		call	UserStandardDialog

		call	MemUnlock		; unlock Strings
		ret
SetupPrinterDoDialog	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	StringLock

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx - resource handle
		si - chunk handle

RETURN:		dx:bp - string

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/90		Initial version

------------------------------------------------------------------------------@
StringLock	proc	near
	uses	ax, ds
	.enter

	call	MemLock		;ax,bx <- seg addr of resource
	mov	ds, ax
	xchg	dx, ax                          ;dx = segment of string
        mov	bp, ds:[si]                     ;deref string chunk

	.leave
	ret
StringLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpoolEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the spooler has any job waiting on the queue
		for the appropriate port

CALLED BY:	INTERNAL (SetupPrinterStartPrinting)

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

;EC <	xchg	si, bx			>
;EC <	call	ECCheckPrinterPort	>
;EC <	xchg	si, bx			>

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
		SetupNoPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the printer previously installed, if there was
		one.  (this will be called if user selects "None", or
		if changing the printer selections.)

CALLED BY:	INTERNAL  (UpdateInitFileForPrinter)

PASS:		ds - dgroup
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupNoPrinter		proc	near

EC<	call	CheckDSDgroup						>

	; Delete the printer, remove its ini file category string	
		clr	ax
		call	SpoolDeletePrinter

	; Reinitialize the printerCategoryString

		clr	{byte}ds:[printerCategoryString]
		ret
SetupNoPrinter		endp
