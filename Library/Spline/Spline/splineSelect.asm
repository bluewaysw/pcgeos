COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:		
FILE:		splineSelect.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version


METHODS:
	SplineStartSelect
	SplineEndSelect

GLOBAL 
ROUTINES:
	SplineModifySelection
	SplineUnselectAll
	SplineSelectPoint

LOCAL
ROUTINES:
	SplineFixupActionPoint
	SplineFixupLists
	SplineMakeActionPoint

DESCRIPTION:	This file contains the routines for manipulating the
		selection list, etc.

	$Id: splineSelect.asm,v 1.1 97/04/07 11:09:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSelectCode	segment


SplineSelectCode	ends
