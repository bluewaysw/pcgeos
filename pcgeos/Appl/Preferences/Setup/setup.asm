COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphical Setup
FILE:		setup.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	2/90		Initial version

DESCRIPTION:
	This file contains the Setup application

	$Id: setup.asm,v 1.2 98/06/17 21:26:48 gene Exp $

------------------------------------------------------------------------------@
;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include	gstring.def
include	win.def
include lmem.def
include timer.def
include chunkarr.def

include disk.def
include file.def		; for file routines
include fileEnum.def		; for file enum routine
include initfile.def
include system.def		; for UtilHex32ToAscii
include vm.def			; for VM tests

include input.def
include thread.def
include localize.def	; for Resources file

include Objects/inputC.def

include  Internal/im.def
include  Internal/geodeStr.def
UseDriver Internal/videoDr.def
UseDriver Internal/mouseDr.def
UseDriver Internal/printDr.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib 	Objects/vTextC.def
UseLib	spool.def
UseLib	Internal/spoolInt.def
UseLib	config.def

include char.def		; for SysInfoGenerateFile
include timedate.def		; for SysInfoGenerateFile
include sysstats.def		; for SysInfoGenerateFile
include drive.def		; for SysInfoGenerateFile
include fmtool.def		; for FileQuickTransferHeader
include	cvttool.def		; for ConvertToolActivatedNoFileManager

include Internal/swap.def	; for SysInfoGenerateFile
include Internal/dos.def	; for SysInfoGenerateFile
include Internal/fileInt.def	; for SysInfoGenerateFile
UseDriver Internal/swapDr.def	; for SysInfoGenerateFile
UseDriver Internal/serialDr.def
UseDriver Internal/parallDr.def
ifdef	GPC_VERSION
UseDriver Internal/powerDr.def
endif

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
include		setupConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		setup.rdef

include		setupVariable.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

CommonCode	segment	resource

include commonUtils.asm
include setupUtils.asm
include setupScreenClass.asm
include setupPorts.asm
include setupProcess.asm
include setupVideo.asm
include setupMouse.asm
include setupPrinter.asm
include setupDispRes.asm
include setupSysInfo.asm
include setupSerialNum.asm
include setupUpgrade.asm
include setupUI.asm

include	prefPrinter.asm


CommonCode	ends

end
