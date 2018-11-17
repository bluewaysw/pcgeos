COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompManager.asm

AUTHOR:		John Wedgwood, Oct 11, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/11/91	Initial revision

DESCRIPTION:
	Manager for the series area class.

	$Id: ccompManager.asm,v 1.1 97/04/04 17:48:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def

ChartClassStructures	segment	resource
	ChartCompClass
ChartClassStructures	ends

ChartCompCode	segment resource

include ccompComposite.asm
include	ccompGeometry.asm	
include	ccompPosition.asm	
include ccompUtils.asm		
include ccompBuild.asm
include ccompRealize.asm
include ccompState.asm

ChartCompCode	ends
