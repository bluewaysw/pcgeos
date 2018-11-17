COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Config -- Utils
FILE:		utilsManager.asm

AUTHOR:		Chris Boyke, October 26, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cb      10/26/92        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: utilsManager.asm,v 1.1 97/04/04 17:51:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	TOC_ONLY
include	configGeode.def

Utils	segment	resource

include	utilsPrefMgr.asm

Utils	ends
endif
