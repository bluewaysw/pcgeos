COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomremManager.asm

AUTHOR:		Adam de Boor, Feb  1, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 1/91		Initial revision
	Don	4/26/91		Made into a printer driver

DESCRIPTION:
	Manager for CCom FAX driver.
		

	$Id: ccomremManager.asm,v 1.1 97/04/18 11:52:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;--------------------------------------
;	Include files
;--------------------------------------

include	printcomInclude.def
include	ccomremInclude.def


;--------------------------------------
;	Libraries we depend upon
;--------------------------------------

;UseLib	ui.def
;UseLib	spool.def

UseLib Objects/vTextC.def
include	rolodex.def			; to allow calls to rolodex for phone #


;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include	printcomConstant.def
include	ccomremConstant.def

include	printcomMacro.def
include	ccomremMacro.def


;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata	segment

DriverTable	DriverExtendedInfoStruct \
		<
			<
			  Entry:DriverStrategy,		; DIS_strategy
			  mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
			  DRIVER_TYPE_PRINTER		; DIS_driverType
			>,
		  handle DriverInfo			; DEIS_resource
		>

public	DriverTable
				
idata	ends


;------------------------------------------------------------------------------
;		Data Area
;------------------------------------------------------------------------------

include	ccomremVariable.def


;------------------------------------------------------------------------------
;		User Interface Definitions
;------------------------------------------------------------------------------

include ccomremFax.rdef		; include the UI definitions

idata	segment
	FaxInfoClass
	FaxServerListClass
idata	ends
;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include printcomTables.asm	; jump table for some driver calls
include ccomremTables.asm		; module jump table for all driver escape calls

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomInfo.asm	; various info getting/setting routines
include	ccomremAdmin.asm		; misc admin routines

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

.warn -unref

include	printcomStream.asm	; code to talk with the stream driver
include	printcomNoText.asm	; dummy Text routines to satisfy jump tables
include	printcomNoStyles.asm	; dummy Styles routines to satisfy jump tables
include	printcomNoColor.asm	; dummy Color routines to satisfy jump tables

.warn @unref

include	UI/uiGetMain.asm	; pass tree for Main box
include	UI/uiGetOptions.asm	; pass tree for Options box

include	ccomremSetup.asm		; misc setup/cleanup routines
include	ccomremGraphics.asm	; code to implement graphics routines
include	ccomremCursor.asm		; code to implement Cursor routines
include	ccomremPage.asm		; code to implement Page routines
include	jobPaperFaxInfo.asm	; code to get print area and margins
include ccomremUI.asm		; UI interaction code

if ERROR_CHECK
include ccomremEC.asm
endif

include	ccomremPDL.asm

CommonCode ends


;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	ccomremDriverInfo.asm		; overall driver info

include	ccomremInfo.asm			; specific info for this fax board


;------------------------------------------------------------------------------
;		Miscellaneous ForceRef's to clean up compilation
;------------------------------------------------------------------------------

ForceRef	DriverTable		; specific driver information
ForceRef	ccomDriverInfo

ForceRef	ccomInfo		; specific information tables
ForceRef	ccomInfoStruct

ForceRef	SendCodeOut		; due to common code

end


