COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupManager.asm

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

	$Id: sgroupManager.asm,v 1.1 97/04/04 17:46:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def

ChartClassStructures	segment	resource
	SeriesGroupClass

	method	SeriesGroupRealize, SeriesGroupClass, 
				MSG_CHART_OBJECT_REALIZE
ChartClassStructures	ends


ChartCompCode	segment resource

include sgroupBuild.asm
include sgroupGeometry.asm
include sgroupSelect.asm
include sgroupFind.asm
include sgroupRelocate.asm

if ERROR_CHECK
include sgroupEC.asm
endif

ChartCompCode	ends
