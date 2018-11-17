COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial version

DESCRIPTION:
	This file contains the user interface definition for the impex.

	$Id: uiManager.asm,v 1.1 97/04/04 21:53:33 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include impexGeode.def
include impexThreadProcess.def

;------------------------------------------------------------------------------
;			Module Dependent stuff
;------------------------------------------------------------------------------

include	uiConstant.def
include Objects/inputC.def

; Needed for floppy-based libraries, as well as the changes made for
; GlobalPC to combine the Impex functionality with the DocControl.
;
include Internal/heapInt.def

; Needed to borrow stack space in low-level stack-intensive routine
;
include Internal/threadIn.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiMain.rdef

ImpexClassStructures	segment	resource
	ImportExportClass
	ImportControlClass
	ExportControlClass
	FormatListClass
	MaskTextClass
ImpexClassStructures	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiFormatList.asm
include uiFormatListLow.asm

if not ALLOW_FLOPPY_BASED_LIBS
include uiExportCtrl.asm
include	uiImportCtrl.asm
else
include uiExportCtrlRed.asm
include	uiImportCtrlRed.asm
endif

include uiImportExport.asm
include uiUtils.asm

include uiC.asm
