COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		lmManager.asm

AUTHOR:		John Wedgwood, Apr 12, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	4/12/89		Initial revision

DESCRIPTION:
	Manager file for the local-memory stuff.

	$Id: lmemManager.asm,v 1.1 97/04/05 01:14:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;		Definitions
;----------------------------------------------------------------------------

_KernelLMem	=	1	;Identify this module

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include lmem.def
include chunkarr.def
include object.def		; Need access to ObjGetFlags
include gcnlist.def
include localize.def
include profile.def

include Internal/debug.def

;--------------------------------------

include lmemConstants.def	;LMEM constants
include lmemMacros.def		;LMEM macros

;-------------------------------------

include	lmemVariable.def

;-------------------------------------

kcode	segment
include lmemErrorCheck.asm
include lmemCode.asm
include lmemTemp.asm
include lmemChunkArray.asm
include lmemElementArray.asm
include lmemNameArray.asm
include lmemGCNList.asm
kcode	ends

include lmemC.asm

end
