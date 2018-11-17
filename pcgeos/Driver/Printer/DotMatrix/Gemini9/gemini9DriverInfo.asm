COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star Gemini 9-pin printer driver
FILE:		gemini9DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	Driver info for the Star Gemini 9-pin printer driver

	The file "printDr.def" should be included before this one
		

	$Id: gemini9DriverInfo.asm,v 1.1 97/04/18 11:54:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Info Resource

	This part of the file contains the information that pertains to
	all device supported by the driver.  It includes device names and
	a table of the resource handles for the specific device info.  A
	pointer to this info is provided by the DriverInfo function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment	lmem LMEM_TYPE_GENERAL

;----------------------------------------------------------------------------
;	Device Enumerations
;----------------------------------------------------------------------------


DefPrinter	PD_STAR_GEMINI_10_128,"Star Gemini-10",geminiInfo
DefPrinter	PD_STAR_GEMINI_15_128,"Star Gemini-15",geminiwInfo

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

gemini9DriverInfo	DriverExtendedInfoTable <  {},
					   PrintDevice/2, ; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					 >

gemini9Info		PrintDriverInfo	<	30,
						PR_RESEND,
						asciiTransTable
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------


asciiTransTable	chunk.char ";;",0


;Create the actual tables now....
PrinterTables

DriverInfo	ends

