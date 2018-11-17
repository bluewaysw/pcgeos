COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3Manager.asm

AUTHOR:		Jacob Gabrielson, Mar 10, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	3/10/93   	Initial revision
	AC	9/8/93		Changed for Group3


DESCRIPTION:
	
		

	$Id: group3Manager.asm,v 1.1 97/04/18 11:52:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; PASTA-only geode
PASTA equ -1

;----------------------------------------------------------------------
;	CONDITIONAL ASSEMBLY	
;----------------------------------------------------------------------


_PEN_BASED = -1
_NIKE = 0
_NIKE_EUROPE = 0
_USE_SUBJECT = 0
_FLOPPY_BASED_FAX = 0


_USE_PALM_ADDR_BOOK = -1

if _USE_PALM_ADDR_BOOK
; Constants which are used in the .gp file are either defined / not defined
GP_USE_PALM_ADDR_BOOK equ -1
endif

if _PEN_BASED
GP_PEN_BASED equ -1
endif

;------------------------------------------------------------------------------
;				 Include files
;------------------------------------------------------------------------------

include printcomInclude.def
include Objects/vTextC.def


if _PEN_BASED
include	pen.def					; for ink object
endif

include char.def
include initfile.def
include assert.def

;------------------------------------------------------------------------------
;			     Constants and Macros
;------------------------------------------------------------------------------

include	printcomConstant.def
include	printcomMacro.def

include timedate.def

if _USE_PALM_ADDR_BOOK
UseLib	pabapi.def
endif

UseLib	faxfile.def
include group3CoverPage.def			; constants for cover page 
						; and class defs
include	group3AddrBook.def			; class def's for the
						; addr book

include	group3DialAssist.def			; constants and class
						; defintions for the 
						; dial assist box
include	group3Constant.def			; gloabal constants and 
						; class defs
include	group3.rdef


;------------------------------------------------------------------------------
;			       Driver Info Table
;------------------------------------------------------------------------------

idata	segment					; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
                < <Entry:DriverStrategy,        ; DIS_strategy
                  mask DA_HAS_EXTENDED_INFO,    ; DIS_driverAttributes
                  DRIVER_TYPE_PRINTER >,        ; DIS_driverType
                  handle DriverInfo             ; DEIS_resource
                >

public	DriverTable

CoverPageTextClass
CoverPageReceiverTextClass
CoverPageSenderInteractionClass
FaxInfoClass
QuickNumbersListClass
Group3OptionsTriggerClass
if _PEN_BASED
InkDeleteTriggerClass
endif

QuickRetrieveListClass
DeleteTriggerClass

if _USE_PALM_ADDR_BOOK
AddressBookListClass
AddressBookListItemClass
AddrBookTriggerClass
endif

DialAssistInteractionClass

if _USE_PALM_ADDR_BOOK
AddressBookFileSelectorClass
endif

Group3ClearTriggerClass

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
include group3Tables.asm	; table for esc routine
include printcomInfo.asm        ; various info getting/setting routines
include	printcomAdmin.asm
;;include	printcomNoEscapes.asm

Entry   ends

;------------------------------------------------------------------------------
;				  Driver Code
;------------------------------------------------------------------------------

CommonCode	segment resource		; MODULE_STANDARD

include	printcomNoText.asm
include	printcomNoStyles.asm
include	printcomNoColor.asm			; no color faxing

	;include printcomStream.asm
include Stream/streamWrite.asm
	;include Stream/streamWriteByte.asm

include	group3PrintSwath.asm			

	;include Cursor/cursorDotMatrixCommon.asm
	;include Cursor/cursorPrLineFeedDumb6LPI.asm
	;include Cursor/cursorPrFormFeedGuess.asm
	;include Cursor/cursorConvert48.asm

	;include	printcomASFOnlyPage.asm
include group3StartPage.asm
include	group3EndPage.asm

;
; Routines called whenever a new print job starts
;
include Job/jobPaperInfo.asm
include	group3StartJob.asm
include	group3EndJob.asm

;
; Routines that add or evaluate UI to the print dialog box
;
include	UI/uiGetMain.asm
include group3EvalFaxUI.asm

;
; Code for printer esc routines. 
;
include group3CoverSheet.asm

;
; Routines that aren't needed for this driver.  They all return clc,
; so that if the spooler calls any of these routines, it won't
; think an error has occurred
;
PrintSetCursor		proc	far
PrintGetCursor		label	far
PrintSetPaperPath	label	far
PrintGetOptionsUI	label	far
	clc
	ret
PrintSetCursor		endp

;
; Include routines to handle UI routines
;

include	group3CoverPage.asm
include group3QuickNumber.asm
include	group3UI.asm

if _PEN_BASED
include	group3InkDelete.asm
endif

include group3DialAssist.asm
include group3DeleteTrigger.asm

if _USE_PALM_ADDR_BOOK
include group3AddrBook.asm
endif

include	group3Strings.asm
include	group3OffsetTables.asm
include group3IACP.asm
include group3Common.asm

CommonCode		ends

;------------------------------------------------------------------------------
;		  Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	group3DriverInfo.asm			; info about thise driver
include	group3DeviceInfo.asm			; info about this device

;------------------------------------------------------------------------------
;			 Get Rid of Annoying Messages
;------------------------------------------------------------------------------

ForceRef	PrintSetSymbolSet
ForceRef	PrintLoadSymbolSet
ForceRef	PrintClearStyles
ForceRef	SetNextCMYK
ForceRef	SetFirstCMYK














