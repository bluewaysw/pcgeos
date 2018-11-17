COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Tools/ProtoBiffer
FILE:		protoManager.asm

AUTHOR:		Don Reeves: July 29, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial revision


DESCRIPTION:
	File to include everything else.
		
	$Id: protoManager.asm,v 1.1 97/04/04 17:15:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	

;------------------------------------------------------------------------------
;	Common include files
;------------------------------------------------------------------------------

include geos.def
include geode.def
include resource.def
include ec.def
include object.def
include system.def
include heap.def
include disk.def
ACCESS_FILE_STRUC = 1				; for GFH_SIG_1_2 & GFH_SIG_3_4
include	fileEnum.def				; for FileEnum()
include Internal/fileStr.def			; for GeosFileHeader
include Internal/fileInt.def			; for FileFullAccessFlags
include Internal/geodeStr.def			; for ExecutableFileHeader
	
	
;------------------------------------------------------------------------------
;	Common libraries
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def


;------------------------------------------------------------------------------
;	Application definitions
;------------------------------------------------------------------------------

include	protoConstant.def
include protoMacro.def
include	protoVariable.def

	
;------------------------------------------------------------------------------
;	UI definitions
;------------------------------------------------------------------------------
	
include	proto.rdef

	
;------------------------------------------------------------------------------
;	Source code
;------------------------------------------------------------------------------

include	protoMain.asm
