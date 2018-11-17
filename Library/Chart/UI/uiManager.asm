COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager file for the UI part of the chart library.

	$Id: uiManager.asm,v 1.1 97/04/04 17:47:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include chartGeode.def
include	gstring.def

include uiManager.rdef


ChartClassStructures	segment	resource
	ChartTypeControlClass
	ChartGroupControlClass
	ChartAxisControlClass
	ChartGridControlClass
ChartClassStructures	ends



ChartMiscCode	segment resource

include uiControl.asm
include uiType.asm
include uiGroup.asm
include uiAxis.asm
include uiGrid.asm

ChartMiscCode	ends
