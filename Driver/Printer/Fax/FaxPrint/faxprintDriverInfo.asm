COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		group3DriverInfo.asm

AUTHOR:		Jacob Gabrielson, Mar 10, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	3/10/93   	Initial revision
	AC	9/ 8/93		Changed for Group3
	jdashe	10/19/94	Modified for tiramisu

DESCRIPTION:
	
		

	$Id: faxprintDriverInfo.asm,v 1.1 97/04/18 11:53:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment lmem LMEM_TYPE_GENERAL

;------------------------------------------------------------------------------
;		Device Enumerations
;------------------------------------------------------------------------------

DefPrinter	PD_FAXPRINT, "Fax Print Driver", DeviceInfo

;------------------------------------------------------------------------------
;		Driver Info Header
;------------------------------------------------------------------------------

faxPrintDriverInfo		DriverExtendedInfoTable	< {},	; lmem hdr
					PrintDevice/2,		; # devices
					offset deviceStrings,	; devices
					offset deviceInfoTab	; info blocks
					>

public faxPrintDriverInfo

faxPrintInfo		PrintDriverInfo	< 1,			; timeout (sec)
					PR_DONT_RESEND,
					NULL,			; ISOeeeee
					asciiTransTable,
					PDT_FACSIMILE,
					BW_FALSE		; uiFeatures
					>

public faxPrintInfo

;------------------------------------------------------------------------------
;		Translations List(s)
;------------------------------------------------------------------------------

asciiTransTable		chunk.char	";;",0
				
;------------------------------------------------------------------------------
;		Create Tables
;------------------------------------------------------------------------------

PrinterTables

DriverInfo	ends



