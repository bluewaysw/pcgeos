COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		titleManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager for the Title module.

	$Id: titleManager.asm,v 1.1 97/04/04 17:47:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include chartGeode.def


ChartClassStructures	segment	resource
	TitleClass
ChartClassStructures	ends


ChartMiscCode	segment resource

include titleBuild.asm
include	titleGeometry.asm
include	titleRealize.asm
include titleGrObj.asm

ChartMiscCode	ends
