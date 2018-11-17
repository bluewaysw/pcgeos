COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processTables.asm

AUTHOR:		Jim DeFrisco, 15 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/15/90		Initial revision


DESCRIPTION:
	This file contains various tables required for the process module
	of the print spooler.
		

	$Id: processTables.asm,v 1.1 97/04/07 11:11:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintInit	segment	resource

		; This table contains the offsets to the permanent name strings
if	DBCS_PCGEOS
portNameTable	nptr.wchar \
		NameSerialPort,			 	; PPT_SERIAL
		NameParallelPort,		 	; PPT_PARALLEL
		NameFilePort,				; PPT_FILE
		NameNothingPort,			; PPT_NOTHING
		0					; PPT_CUSTOM
else
portNameTable	nptr.char \
		NameSerialPort,			 	; PPT_SERIAL
		NameParallelPort,		 	; PPT_PARALLEL
		NameFilePort,				; PPT_FILE
		NameNothingPort,			; PPT_NOTHING
		0					; PPT_CUSTOM
endif

.assert (size portNameTable eq PrinterPortType)

;-------------------------------------------------------------------------
;		I/O Driver Permanent Names
;-------------------------------------------------------------------------

if	DBCS_PCGEOS
if	ERROR_CHECK
NameSerialPort		wchar	"serialec.geo",0
NameParallelPort	wchar	"parallel.geo",0
NameFilePort		wchar	"filestre.geo",0
NameNothingPort		wchar	0

else

NameSerialPort		wchar	"serial.geo",0
NameParallelPort	wchar	"parallel.geo",0
NameFilePort		wchar	"filestr.geo",0
NameNothingPort		wchar	0

endif
else
if	ERROR_CHECK
NameSerialPort		char	"serialec.geo",0
NameParallelPort	char	"parallee.geo",0
NameFilePort		char	"filestre.geo",0
NameNothingPort		char	0

else

NameSerialPort		char	"serial.geo",0
NameParallelPort	char	"parallel.geo",0
NameFilePort		char	"filestr.geo",0
NameNothingPort		char	0

endif
endif

		; This table contains the offsets to the verify routines
		; for all the types of ports supported by the spooler
portVerifyTable	nptr.near \
		VerifySerialPort,			; PPT_SERIAL
		VerifyParallelPort, 			; PPT_PARALLEL
		VerifyFilePort,				; PPT_FILE
		VerifyNothingPort,			; PPT_NOTHING
		VerifyCustomPort			; PPT_CUSTOM

.assert (size portVerifyTable eq PrinterPortType)

		; This table contains the offsets to the
		; initialization routines for all the types of ports
		; supported by the spooler

portInitTable	nptr.near \
		InitSerialPort, 			; PPT_SERIAL
		InitParallelPort, 			; PPT_PARALLEL
		InitFilePort,				; PPT_FILE
		InitNothingPort,			; PPT_NOTHING
		InitCustomPort				; PPT_CUSTOM

.assert (size portInitTable eq PrinterPortType)

		; This table contains the offsets to the exit routines
		; for all the types of ports supported by the spooler
portExitTable	nptr.near \
		ExitSerialPort,			 	; PPT_SERIAL
		ExitParallelPort,		 	; PPT_PARALLEL
		ExitFilePort,				; PPT_FILE
		ExitNothingPort,			; PPT_NOTHING
		ExitCustomPort				; PPT_CUSTOM

.assert (size portExitTable eq PrinterPortType)

		; This is a table of the parallel port names, that we use
		; in order to modify the .ini file (SBCS)
parallelPortNames	nptr.char \
		portName1,				; port1
		portName2,				; port2
		portName3,				; port3
		portName4				; port4

portName1	char	"port1",0
portName2	char	"port2",0
portName3	char	"port3",0
portName4	char	"port4",0
PrintInit	ends



PrintError	segment	resource

		; This table contains the offsets to the error routines
		; for all the types of ports supported by the spooler
portErrorTable	nptr.near \
		ErrorSerialPort,		 	; PPT_SERIAL
		ErrorParallelPort,		 	; PPT_PARALLEL
		ErrorFilePort,				; PPT_FILE
		ErrorNothingPort,			; PPT_NOTHING
		ErrorCustomPort				; PPT_CUSTOM

.assert (size portErrorTable eq PrinterPortType)


; This table is used by CommPortErrorHandler (spool thread 0) to close
; a port when an error occurs on a print job that has already been
; aborted (this can happen if a user deletes a print job, and then
; turns off the printer, for example).  Since most stream drivers will
; probably crash if another thread tries to close the port, most of
; the entries in this table do nothing.  If the other stream drivers
; are made more robust, then the proper entries should be added to
; this table.

portCloseTable	nptr.near \
		DoNothing,			 	; PPT_SERIAL
		CloseParallelPort,		 	; PPT_PARALLEL
		DoNothing,				; PPT_FILE
		DoNothing,				; PPT_NOTHING
		CloseCustomPort				; PPT_CUSTOM

DoNothing	proc	near
		ret
DoNothing	endp

.assert (size portCloseTable eq PrinterPortType)



		; This table contains the offsets to the input routines
		; for all the types of ports supported by the spooler
portInputTable	nptr.near \
		InputSerialPort,		 	; PPT_SERIAL
		InputNothingPort,		 	; PPT_PARALLEL
		InputNothingPort,			; PPT_FILE
		InputNothingPort,			; PPT_NOTHING
		InputNothingPort			; PPT_CUSTOM

.assert (size portInputTable eq PrinterPortType)

		; This table contains the chunk handles of the strings that
		; describe what type of port is being used.  These strings
		; are used as part of dialog box code, so the actual strings
		; are in the ErrorBoxesUI resource, so they can be localized.
		; If you add support for a new port type, be sure to add
		; a string to ErrorBoxesUI.

portStrings	nptr.char	\
		offset ErrorBoxesUI:SerialString,	; PPT_SERIAL
		offset ErrorBoxesUI:ParallelString,	; PPT_PARALLEL
		offset ErrorBoxesUI:FileString,		; PPT_FILE
		offset ErrorBoxesUI:NothingString,	; PPT_NOTHING
		offset ErrorBoxesUI:CustomString	; PPT_CUSTOM

.assert (size portStrings eq PrinterPortType)

PrintError	ends
