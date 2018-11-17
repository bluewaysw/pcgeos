COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tocManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

DESCRIPTION:
	Routines to deal with the TOC file	

	$Id: tocManager.asm,v 1.1 97/04/04 17:50:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	configGeode.def

include	tocVariables.def
include tocConstants.def

TocCode	segment resource

include tocCategory.asm
include tocDB.asm
include tocDisk.asm
include tocSortedNameArray.asm
include tocOpenClose.asm
include tocUtils.asm

TocCode	ends

