COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV
FILE:		libManager.asm

AUTHOR:		Ted Kim, June 8, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial revision

DESCRIPTION:
	
	This is the main include file for the library module of the 
	CSV translation library.

	$Id: libManager.asm,v 1.1 97/04/07 11:42:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Lib = 1

;-----------------------------------------------------------------------------
;       Include common definitions
;-----------------------------------------------------------------------------

include dbCommonGeode.def

;-----------------------------------------------------------------------------
;	Constants/Variables
;-----------------------------------------------------------------------------

include csvGlobal.def
include csvConstant.def
include libMain.rdef

; REENTRANT_CODE must be set either TRUE or FALSE before transLibEntry.asm
; is included.

REENTRANT_CODE		equ	TRUE

; IMPORT_OPTIONS_EXIST and EXPORT_OPTIONS_EXIST must be set either
; TRUE or FALSE before transUI.asm is included.

IMPORT_OPTIONS_EXIST	equ	TRUE
EXPORT_OPTIONS_EXIST	equ	TRUE
MAP_CONTROL_EXIST	equ	TRUE

;-----------------------------------------------------------------------------
;       Include code
;-----------------------------------------------------------------------------

include	libFormat.asm			; csv format info
include	libMain.asm			; contains GetExport/Import/Options
include	transLibEntry.asm		; library entry point
include	transUI.asm			; TransGetImportUI & TransGetExportUI
include dbCommonUtil.asm

end
