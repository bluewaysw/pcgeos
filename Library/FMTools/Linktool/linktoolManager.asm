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
	

	$Id: linktoolManager.asm,v 1.1 97/04/04 18:01:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include stdapp.def
include library.def

UseLib	shell.def
UseLib	Objects/vTextC.def

include fmtool.def
include file.def
include localize.def

include linktoolConstant.def
include linktoolVariable.def


include linktool.rdef

CommonCold segment resource

include linktoolTool.asm
include linktoolText.asm
include linktoolEntry.asm

CommonCold ends
