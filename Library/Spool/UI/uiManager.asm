COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/90		Initial version

DESCRIPTION:
	This file contains the user interface definition for the spooler.

	$Id: uiManager.asm,v 1.1 97/04/07 11:10:29 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include spoolGeode.def

;------------------------------------------------------------------------------
;			Module Dependent stuff
;------------------------------------------------------------------------------

include uiConstant.def
include uiGlobal.def
include	initfile.def				; for the InitFile routines
include input.def				; character definitions
include	system.def				; localization entry point
include	geoworks.def				; GCN/controller definitions
include Objects/inputC.def			; for MSG_META_KBD_CHAR
include medium.def				; for PC <-> MSAC interaction

UseLib mailbox.def				; for PC <-> MSAC interaction
UseLib Internal/mboxInt.def			; for PC <-> MSAC interaction

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiMain.rdef

ForceRef	SpoolVerifyDocSize
ForceRef	SpoolVerifyBoth

ForceRef	HackGlyph1
ForceRef	HackGlyph2
ForceRef	HackGlyph3
ForceRef	HackGlyph4

if _POSTCARDS
ForceRef	HackGlyphPC1
ForceRef	HackGlyphPC2
endif

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

idata segment
	PrintControlClass
	SpoolSummonsClass
	SpoolChangeClass

	PageSizeControlClass

	SizeVerifyDialogClass
idata ends

include uiPrintControl.asm			; SpoolPrintControlClass
include uiPrintControlUtils.asm			; other utilities

include uiSpoolSummons.asm			; SpoolSummonsClass
include uiSpoolSummonsExternal.asm		; external method handlers
include uiSpoolSummonsPrint.asm			; printer routines
include	uiSpoolSummonsUtils.asm			; other utilities

include	uiPageSizeCtrl.asm			; PageSizeControlClass

include uiC.asm					; C stub declarations

end


















