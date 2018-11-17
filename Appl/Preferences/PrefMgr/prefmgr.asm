COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PrefMgr
FILE:		prefmgr.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	2/90		Initial version

DESCRIPTION:
	This file contains the PrefMgr application

	$Id: prefmgr.asm,v 1.2 98/02/15 19:24:58 gene Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;		Conditional-compilation options
;------------------------------------------------------------------------------

_SIMPLE		= 0			; this is NOT the simple version!
PREFMGR	= -1

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include	stdapp.def

include Internal/prodFeatures.def

include library.def		; for modules
include lmem.def
include timer.def
include chunkarr.def
include	assert.def

include file.def		; for file routines
include fileEnum.def		; for file enum routines
include initfile.def
include input.def
include system.def		; for UtilHex32ToAscii
include thread.def
include timedate.def

include char.def
include drive.def
include disk.def
include vm.def			; for VM tests
include localize.def		; for Resources file

include	medium.def		; for modem stuff

include Objects/inputC.def

include Internal/im.def
include Internal/geodeStr.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
UseLib 	Objects/vTextC.def
include	Objects/Text/tCtrlC.def

UseLib	spool.def
UseLib	Internal/spoolInt.def

UseLib	spell.def
UseLib	config.def

UseDriver Internal/mouseDr.def
UseDriver Internal/serialDr.def
UseDriver Internal/parallDr.def
UseDriver Internal/printDr.def

;------------------------------------------------------------------------------
;		CONSTANTS	
;------------------------------------------------------------------------------

include	prefConstant.def
include	prefmgrConstant.def
include	prefmgrClass.def
include prefmgrMacros.def
include prefmgrApplication.def


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

;	forward-declare VisOpen/VisClose handlers so .rdef will assemble...

global	VisOpenSerialOptions:far
global	VisOpenPrinter:far
global	VisOpenModem:far
global	VisOpenText:far
global	TextCloseEditBox:far
global	VisOpenChooseDictionary:far

include	prefmgr.rdef

;------------------------------------------------------------------------------
;		Definitions & ForceRef's to avoid spurious warnings
;------------------------------------------------------------------------------

include		prefmgrVariable.def
include		prefVariable.def





;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

PrinterAndModemCode	segment resource
include prefmgrModem.asm
include	prefmgrPrinter.asm
include	prefmgrSerial.asm
include	prefPrinter.asm					; common code
PrinterAndModemCode	ends

CommonCode	segment resource
include prefmgrText.asm
include prefmgrModule.asm
include prefmgrModuleList.asm
include prefmgrReboot.asm
include	prefmgrApplication.asm
include customSpin.asm
include prefmgrDialogGroup.asm
include prefmgrTitledSummons.asm
include commonUtils.asm
include	prefmgrDynamic.asm
include prefmgrFormats.asm

include	prefmgrMtdHan.asm
include	prefmgrUtils.asm
include prefmgrInitExit.asm
CommonCode	ends
