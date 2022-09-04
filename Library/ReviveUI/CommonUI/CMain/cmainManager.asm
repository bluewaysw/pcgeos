COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Main
FILE:		mainManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	9/26/89		Updated documentation

DESCRIPTION:
	This file assembles the Main/ module of the Open Look library

	$Id: cmainManager.asm,v 2.36 95/03/20 09:52:52 tony Exp $

------------------------------------------------------------------------------@

	; Unlike the rest of CommonUI, we play by the rules...

	.warn +private
	.warn +unref_local

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		cMacro.def
include		cGeode.def
include		cGlobal.def

include		vm.def
include		disk.def
include		initfile.def
include		timer.def
include		gcnlist.def
include		font.def
include		ieCommon.def

UseDriver	Internal/videoDr.def
include		Internal/diskInt.def	; for UIDC error-checking
include		sysstats.def		; for SGIT_SYSTEM_DISK
include		Internal/heapInt.def	; for HE_method in cmainKeyboard.asm
include		Internal/fileInt.def

UseLib		dbase.def
UseLib		spool.def
UseLib		ui.def

ifdef WIZARDBA
  UseLib	iclas.def
endif

if _GRAFFITI_UI
  UseLib	Objects/keyControl.def
endif
;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		cmainMacro.def
include		cmainConstant.def
include		cmainVariable.def
include		cmainPenInputControl.def

if INITFILE_KEYBOARD or STANDARD_KEYBOARD
include		cmainStandardKbd.def
endif
if INITFILE_KEYBOARD or ZOOMER_KEYBOARD
include		cmainZoomerKbd.def
endif
if STYLUS_KEYBOARD
include		cmainStylusKbd.def
include		cmainBigKeyKmp.def
include		cmainNumbersKmp.def
include		cmainPunctuationKmp.def
include		cmainHWRGridKmp.def
endif


;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		cmainManager.rdef

include		cmainCode.asm
include		cmainUIDocumentControl.asm
include		cmainUIDocOperations.asm
include		cmainAppDocumentControl.asm

include		cmainDocumentMisc.asm
include		cmainDocumentCommon.asm
include		cmainDocumentNew.asm
include		cmainDocumentRedwood.asm	;special WP versions of stuff

include		cmainDocObscure.asm
include		cmainDocPhysical.asm
include		cmainDocDialog.asm
include		cmainDocLowDisk.asm
include		cmainUtils.asm

;
; Floating keyboard code
;
include		cmainPenInputControl.asm
include		cmainHWRGrid.asm
include		cmainKeyboard.asm

if INCLUDE_VIS_CHARTABLE_CLASS
include		cmainCharTable.asm
endif

if INCLUDE_VIS_KEYMAP_CLASS
include		cmainKeymap.asm
endif
end
