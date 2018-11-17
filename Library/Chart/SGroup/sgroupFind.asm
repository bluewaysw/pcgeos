COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupFind.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: sgroupFind.asm,v 1.1 97/04/04 17:46:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupFindSeriesByNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of a series object

CALLED BY:

PASS:		cx - series number
		*ds:si - SeriesGroup

RETURN:		*ds:ax - series object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	can be called as both a METHOD and a PROCEDURE

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGroupFindSeriesByNumber	method	SeriesGroupClass,
				MSG_SERIES_GROUP_FIND_SERIES_BY_NUMBER
	uses	cx,dx,bp
	.enter
	mov	dx, cx
	clr	cx
	call	ChartCompFindChild
	ERROR_C ILLEGAL_VALUE
	mov_tr	ax, cx
	.leave
	ret
SeriesGroupFindSeriesByNumber	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupFindSeriesByOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the # of a series given its OD

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= segment of SeriesGroupClass
		^lcx:dx = child to find

RETURN:		ax - series number

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupFindSeriesByOD	method	dynamic	SeriesGroupClass, 
					MSG_SERIES_GROUP_FIND_SERIES_BY_OD
	uses	cx, dx, bp
	.enter
	call	ChartCompFindChild
	mov_tr	ax, bp			; number of child
	.leave
	ret
SeriesGroupFindSeriesByOD	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupFindSeriesGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of a grobj for the given series

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= segment of SeriesGroupClass

RETURN:		^lcx:dx - OD of grobj

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupFindSeriesGrObj	method	dynamic	SeriesGroupClass, 
					MSG_SERIES_GROUP_FIND_SERIES_GROBJ
	uses	bp
	.enter
	call	SeriesGroupFindSeriesByNumber
	mov_tr	si, ax			;  *ds:si series object

	mov	ax, MSG_CHART_OBJECT_FIND_GROBJ
	call	ObjCallInstanceNoLock

	.leave
	ret
SeriesGroupFindSeriesGrObj	endm
