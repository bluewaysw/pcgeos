COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		faxprintManager.asm

AUTHOR:		Jacob Gabrielson, Mar 10, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	3/10/93   	Initial revision
	AC	9/8/93		Changed for Group3
	jdashe	10/10/94	Modified for Tiramisu

DESCRIPTION:
	The main manager file for the tiramisu fax print driver.
		

	$Id: faxprintManager.asm,v 1.1 97/04/18 11:53:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;				 Include files
;------------------------------------------------------------------------------

include printcomInclude.def
include Objects/vTextC.def
include char.def
include initfile.def
include	assert.def
include	localize.def
include timedate.def

UseLib	faxfile.def


;------------------------------------------------------------------------------
;			     Constants and Macros
;------------------------------------------------------------------------------

include	printcomConstant.def
include	printcomMacro.def

include fax.def					; Fax constants
include	faxprintConstant.def			; global constants
include	Internal/faxOutDr.def			; more fax constants

include	faxprint.rdef				; UI for this driver

;------------------------------------------------------------------------------
;			       Driver Info Table
;------------------------------------------------------------------------------

idata	segment					; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
                < <Entry:DriverStrategy,        ; DIS_strategy
                  mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
                  DRIVER_TYPE_PRINTER >,        ; DIS_driverType
                  handle DriverInfo	        ; DEIS_resource
                >

public	DriverTable

idata	ends

;------------------------------------------------------------------------------
;				   Data Area
;------------------------------------------------------------------------------

udata	segment					; MODULE_FIXED

udata	ends

;------------------------------------------------------------------------------
;				  Entry Code
;------------------------------------------------------------------------------

Entry	segment resource			; MODULE_FIXED

include printcomEntry.asm       ; entry point, misc bookeeping routines
include printcomTables.asm      ; jump table for some driver esc calls
include faxprintTables.asm	; table for esc routine
include printcomInfo.asm        ; various info getting/setting routines
include	printcomAdmin.asm
include printcomNoEscapes.asm   ; no escapes here, hombre

Entry   ends

;------------------------------------------------------------------------------
;				  Driver Code
;------------------------------------------------------------------------------

CommonCode	segment resource		; MODULE_STANDARD

include	printcomNoText.asm
include	printcomNoStyles.asm
include	printcomNoColor.asm			; no color faxing

include Stream/streamWrite.asm

include	faxprintPrintSwath.asm			
include faxprintStartPage.asm
include	faxprintEndPage.asm

;
; Routines called whenever a new print job starts
;
include Job/jobPaperInfo.asm
include	faxprintStartJob.asm
include	faxprintEndJob.asm

;
; Routines that add or evaluate UI to the print dialog box
;
;include	UI/uiGetMain.asm
;include	UI/uiEval.asm

;
; Routines that aren't needed for this driver.  They all return clc,
; so that if the spooler calls any of these routines, it won't
; think an error has occurred
;
PrintSetCursor		proc	far
PrintGetCursor		label	far
PrintSetPaperPath	label	far
PrintGetOptionsUI	label	far
PrintGetMainUI		label	far
PrintEvalUI		label	far
PrintStuffUI		label	far
	clc
	ret
PrintSetCursor		endp

;
; Include routines to handle UI routines
;

include	faxprintOffsetTables.asm
include	faxprintCommon.asm

CommonCode		ends

;------------------------------------------------------------------------------
;		  Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	faxprintDriverInfo.asm			; info about this driver
include	faxprintDeviceInfo.asm			; info about this device

;------------------------------------------------------------------------------
;			 Get Rid of Annoying Messages
;------------------------------------------------------------------------------

ForceRef	PrintSetSymbolSet
ForceRef	PrintLoadSymbolSet
ForceRef	PrintClearStyles
ForceRef	SetNextCMYK
ForceRef	SetFirstCMYK














