COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsGroup.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

DESCRIPTION:
	Utilities for dealing with the ChartGroup object

	$Id: utilsGroup.asm,v 1.1 97/04/04 17:47:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetSeriesAndCategoryCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	global within chart

PASS:		ds - segment of chart objects

RETURN:		cl - series count
		dx - category count

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetSeriesAndCategoryCount	proc far
	uses	ax,si
	.enter

	mov	ax, MSG_CHART_GROUP_GET_SERIES_COUNT
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
	push	cx

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	mov	dx, cx
	pop	cx

	.leave
	ret
UtilGetSeriesAndCategoryCount	endp

