COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
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

DESCRIPTION:
	
		

	$Id: group3DriverInfo.asm,v 1.1 97/04/18 11:52:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment lmem LMEM_TYPE_GENERAL

;------------------------------------------------------------------------------
;		Device Enumerations
;------------------------------------------------------------------------------

DefPrinter	PD_GROUP3, "Fax Driver", DeviceInfo

;------------------------------------------------------------------------------
;		Driver Info Header
;------------------------------------------------------------------------------

group3DriverInfo		DriverExtendedInfoTable	< {},		; lmem hdr
					PrintDevice/2,		; # devices
					offset deviceStrings,	; devices
					offset deviceInfoTab	; info blocks
					>

public group3DriverInfo

group3Info		PrintDriverInfo	< 1,			; timeout (sec)
					PR_DONT_RESEND,
					NULL,			; ISOeeeee
					asciiTransTable,
					PDT_FACSIMILE,
					BW_FALSE		; uiFeatures
					>

public group3Info

;------------------------------------------------------------------------------
;		Translations List(s)
;------------------------------------------------------------------------------

asciiTransTable		chunk.char	";;",0
				
;------------------------------------------------------------------------------
;		Create Tables
;------------------------------------------------------------------------------

PrinterTables

DriverInfo	ends



