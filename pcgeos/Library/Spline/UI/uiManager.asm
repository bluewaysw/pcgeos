COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VisSpline library	
FILE:		uiManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 5/92   	Initial version.

DESCRIPTION:
	

	$Id: uiManager.asm,v 1.1 97/04/07 11:09:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include splineGeode.def

SplineClassStructures	segment resource
	SplineMarkerControlClass
	SplinePointControlClass
	SplinePolylineControlClass
	SplineSmoothnessControlClass
	SplineOpenCloseControlClass
SplineClassStructures	ends

include uiMain.rdef

SplineControlCode	segment resource

include uiControl.asm
include uiMarker.asm
include uiPoint.asm
include uiPolyline.asm
include uiSmoothness.asm
include uiOpenClose.asm

SplineControlCode	ends
