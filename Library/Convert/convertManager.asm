COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
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
	Main assembly file for a library to convert 1.X documents to 2.0
	documents.
		

	$Id: convertManager.asm,v 1.1 97/04/04 17:52:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include stdapp.def
include library.def

UseLib	Objects/vTextC.def
UseLib	dbase.def

DefLib	Internal/convert.def

include vm.def
include fmtool.def
include file.def
include fileEnum.def
include system.def
include sysstats.def
include Internal/fileStr.def
include Internal/dbaseInt.def
include Internal/heapInt.def
include Internal/fileInt.def
include Internal/threadIn.def

include convertConstant.def
include convertDrawDocument.def
include convertGeoWrite.def
include convertText.def
include convertGString.def
include convertScrapbook.def
include convertGeoDex.def

include convertVM.asm
include convertDrawDocument.asm
include convertGString.asm
include convertGStringTables.asm
include convertVMUtils.asm
include convertGeoWrite.asm
include convertText.asm
include convertScrapbook.asm
include convertGeoDex.asm
