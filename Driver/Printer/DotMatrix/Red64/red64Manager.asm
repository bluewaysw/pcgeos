COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon Redwood 64-jet printer driver
FILE:		red64Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/92	Initial version

DESCRIPTION:
	This file contains the source for the canon 64-pin printer driver

	$Id: red64Manager.asm,v 1.1 97/04/18 11:55:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include initfile.def
include timedate.def
include	Internal/redPrint.def


;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include red64Constant.def

include printcomMacro.def

include printcom1ASF.rdef

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
		< <Entry:DriverStrategy, 	; DIS_strategy
		  mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		  DRIVER_TYPE_PRINTER >,	; DIS_driverType
		  handle DriverInfo		; DEIS_resource
		>
public	DriverTable

idata ends

;------------------------------------------------------------------------------
;               Entry Code
;------------------------------------------------------------------------------

Entry   segment resource        ; MODULE_FIXED

include printcomEntry.asm       ; entry point, misc bookeeping routines
include printcomInfo.asm        ; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include printcomTables.asm      ; module jump table for driver calls
include red64EscapeTab.asm	; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource     ; MODULE_STANDARD

include printcomNoStyles.asm ; code to implement Style setting routines
include printcomNoColor.asm  ; code to implement Color routines
include printcomPaperOnlyDialog.asm ; code to implement UI setting

include red64Stream.asm      ; code to talk with the stream driver
include red64Cursor.asm ; code for CanonBJ Cursor routines
include red64Job.asm  ; StartJob/EndJob/SetPaperpath routines
include red64Page.asm        ; code to implement Page routines
include red64Graphics.asm ; code for Canon BJ graphics routines
include red64Text.asm		;  Text setting routines
include red64Buffer.asm ; code to deal with graphic print buffers
include red64ControlCodes.asm ;  Escape and control codes
include	red64Escapes.asm	;routines to do the escape calls

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	red64DriverInfo.asm		; overall driver info

include	red64BaseInfo.asm		; specific info for base printer

	end
