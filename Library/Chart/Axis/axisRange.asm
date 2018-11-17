COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisRange.asm

AUTHOR:		John Wedgwood, Nov  7, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/ 7/91	Initial revision

DESCRIPTION:
	Methods for setting/getting the ranges.

	$Id: axisRange.asm,v 1.1 97/04/04 17:45:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the max and min for the axis on the stack

CALLED BY:	via MSG_AXIS_GET_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		Max and min pushed on floating point stack (in that order)
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetRange	method dynamic	AxisClass, MSG_AXIS_GET_RANGE
	;
	; Push maximum then minimum
	;
	lea	si, ds:[di].AI_max	; ds:si <- max
	call	FloatPushNumber		; Push it
	
	lea	si, ds:[di].AI_min	; ds:si <- min
	call	FloatPushNumber		; Push it
	ret
AxisGetRange	endm


AxisCode	ends
