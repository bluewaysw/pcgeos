COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VMem
FILE:		vmManager.asm

AUTHOR:		Cheng

ROUTINES:
	Name			Description
	----			-----------
   GLB
   EXT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/89		Initial version

DESCRIPTION:
	This file assembles the vm code.

	$Id: vmemManager.asm,v 1.1 97/04/05 01:15:58 newdeal Exp $

-------------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include vm.def
include dbase.def
include	hugearr.def

include lmem.def
include sem.def
include object.def
include chunkarr.def
include Objects/metaC.def

include Internal/interrup.def
include Internal/geodeStr.def
include Internal/fileInt.def		; For HF_otherInfo
include Internal/dos.def
include	Internal/debug.def
include Internal/harrint.def

;--------------------------------------

include vmemConstant.def
include vmemMacro.def

;--------------------------------------

include	vmemVariable.def

;-------------------------------------

include vmemObject.asm
include vmemHigh.asm
include vmemKernelHigh.asm
include vmemLow.asm
include vmemHeader.asm
include vmemBlkManip.asm
include vmemChain.asm
include vmemEC.asm
include	vmemHugeArray.asm

include vmemC.asm

kinit	segment
kinit	ends

end
