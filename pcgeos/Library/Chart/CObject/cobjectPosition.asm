COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectPosition.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Positioning handler for the Chart Object class.

	$Id: cobjectPosition.asm,v 1.1 97/04/04 17:46:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of a chart object.

CALLED BY:	vis MSG_CHART_OBJECT_GET_POSITION

PASS:		*ds:si	= Chart object
		ds:di	= Instance data 

RETURN:		cx, dx - x, y coordinates

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectGetPosition	method dynamic	ChartObjectClass,
			MSG_CHART_OBJECT_GET_POSITION

	movP	cxdx, ds:[di].COI_position
	ret
ChartObjectGetPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position of a chart object.

CALLED BY:	via MSG_CHART_OBJECT_SET_POSITION
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

		cx, dx - position

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectSetPosition	method dynamic	ChartObjectClass,
			MSG_CHART_OBJECT_SET_POSITION

	uses	ax,cx,dx
	.enter

	mov	ax, cx
	mov	bx, dx
	xchg	cx, ds:[di].COI_position.P_x
	xchg	dx, ds:[di].COI_position.P_y
	cmp	ax, cx
	mov	cx, 0		; preserve ZF
	jne	posChanged
	cmp	bx, dx
	je	done

posChanged:

	; Set the image invalid flag.
	mov	cx, mask COS_IMAGE_INVALID

done:
	; RESET the geometry invalid flag

	ornf	cx, mask COS_GEOMETRY_INVALID shl 8
	call	ChartObjectSetState
	.leave
	ret
ChartObjectSetPosition	endm

ChartObjectCode	ends
