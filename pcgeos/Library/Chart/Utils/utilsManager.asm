COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsManager.asm

AUTHOR:		John Wedgwood, Oct 22, 1991

ROUTINES:
	Name			Description
	----			-----------
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/22/91	Initial revision

DESCRIPTION:
	Manager file for chart utility routines.

	$Id: utilsManager.asm,v 1.1 97/04/04 17:47:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include chartGeode.def

ChartCompCode	segment resource

include utilsFile.asm
include utilsFloat.asm
include utilsGrObj.asm
include utilsGroup.asm
include utilsObject.asm
include utilsStrings.asm
include utilsText.asm
include utilsUI.asm

if ERROR_CHECK

include utilsEC.asm

endif


ChartCompCode	ends
