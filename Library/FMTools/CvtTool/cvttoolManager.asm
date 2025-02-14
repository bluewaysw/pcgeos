COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	File Manager Tools
MODULE:		1.X VM File Conversion
FILE:		convertManager.asm

AUTHOR:		Adam de Boor, Aug 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/26/92		Initial revision


DESCRIPTION:
	Main assembly file for a tool for file managers to convert 1.x
	documents from 1.x VM files to 2.0 VM files.
	

	$Id: cvttoolManager.asm,v 1.1 97/04/04 18:00:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include stdapp.def
include library.def

UseLib	Objects/vTextC.def

UseLib	Internal/convert.def

;
;  Library being defined
;
DefLib cvttool.def

include vm.def
include fmtool.def
include file.def
include fileEnum.def
;include system.def
;include sysstats.def

;include cvttoolConstant.def
include cvttoolVariable.def

include cvttool.rdef

include cvttoolTool.asm
