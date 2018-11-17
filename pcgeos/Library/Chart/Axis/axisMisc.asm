COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisMisc.asm

AUTHOR:		John Wedgwood, Oct 20, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/20/91	Initial revision

DESCRIPTION:
	Misc axis method handlers.

	$Id: axisMisc.asm,v 1.1 97/04/04 17:45:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is above the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_TOP
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on top
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Assumes that the geometry is valid.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideTop	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_TOP
	mov	ax, ds:[di].AI_plotBounds.R_top
	ret
AxisGetOutsideTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is below the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_BOTTOM
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on the bottom

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Assumes that the geometry is valid.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideBottom	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_BOTTOM
	.enter
	mov	ax, ds:[di].COI_size.P_y
	sub	ax, ds:[di].AI_plotBounds.R_bottom
	.leave
	ret
AxisGetOutsideBottom	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is left of the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_LEFT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Amount of space that is outside on the left
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes that the geometry is valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideLeft	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_LEFT
	mov	ax, ds:[di].AI_plotBounds.R_left
	ret
AxisGetOutsideLeft	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetOutsideRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the amount of an axis that is right of the plottable area.

CALLED BY:	via MSG_AXIS_GET_OUTSIDE_RIGHT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		cx	= Amount of space that is outside on the right
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes that the geometry is valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetOutsideRight	method dynamic	AxisClass,
			MSG_AXIS_GET_OUTSIDE_RIGHT
	.enter
	mov	ax, ds:[di].COI_size.P_x
	sub	ax, ds:[di].AI_plotBounds.R_right
	.leave
	ret
AxisGetOutsideRight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetRelatedAndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the related and other fields of an axis.

CALLED BY:	via MSG_AXIS_SET_RELATED_AND_OTHER
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Related axis
		dx	= Other axis
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisSetRelatedAndOther	method dynamic	AxisClass,
			MSG_AXIS_SET_RELATED_AND_OTHER
	mov	ds:[di].AI_related, cx
	mov	ds:[di].AI_other, dx
	ret
AxisSetRelatedAndOther	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlottableHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the plottable area.

CALLED BY:	via MSG_AXIS_GET_PLOTTABLE_HEIGHT
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Height of plottable area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetPlottableHeight	method dynamic	AxisClass,
			MSG_AXIS_GET_PLOTTABLE_HEIGHT
	.enter
	mov	ax, ds:[di].AI_plotBounds.R_bottom
	sub	ax, ds:[di].AI_plotBounds.R_top
	.leave
	ret
AxisGetPlottableHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlottableWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of the plottable area.

CALLED BY:	via MSG_AXIS_GET_PLOTTABLE_WIDTH
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		ax	= Width of plottable area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetPlottableWidth	method dynamic	AxisClass,
			MSG_AXIS_GET_PLOTTABLE_WIDTH
	mov	ax, ds:[di].AI_plotBounds.R_right
	sub	ax, ds:[di].AI_plotBounds.R_left
	ret
AxisGetPlottableWidth	endm

AxisCode	ends
