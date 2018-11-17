COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Chart Library
FILE:		axisEC.asm

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
	CDB	12/ 6/91	Initial version.

DESCRIPTION:
	Error-checking routines for Axis code	

	$Id: axisEC.asm,v 1.1 97/04/04 17:45:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckAxisDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the axis object, see if it's what we think it is.

CALLED BY:

PASS:		*ds:si - axis object

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckAxisDSSI	proc near
	uses	ax, es, di

	class	AxisClass 

	.enter

	pushf

	segmov	es, <segment AxisClass>, di
	mov	di, offset AxisClass
	call	ObjIsObjectInClass
	ERROR_NC	DS_SI_NOT_AXIS_CLASS

	DerefChartObject ds, si, di

	mov	ax, ds:[di].AI_plotBounds.R_right
	cmp	ax, ds:[di].AI_plotBounds.R_left
	ERROR_L	ILLEGAL_PLOT_BOUNDS

	mov	ax, ds:[di].AI_plotBounds.R_bottom
	cmp	ax, ds:[di].AI_plotBounds.R_top
	ERROR_L	ILLEGAL_PLOT_BOUNDS


	popf

	.leave

	ret
ECCheckAxisDSSI	endp


AxisCode	ends
