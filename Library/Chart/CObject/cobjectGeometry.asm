COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectGeometry.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Geometry method handler for Chart objects.

	$Id: cobjectGeometry.asm,v 1.1 97/04/04 17:46:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of a chart object.

CALLED BY:	via MSG_CHART_OBJECT_SET_SIZE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Width
		dx	= Height

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	If the new size is different than the old one, assume the
	geometry has become invalid.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectSetSize	method dynamic	ChartObjectClass,
					MSG_CHART_OBJECT_SET_SIZE
	mov	ds:[di].COI_size.P_x, cx
	mov	ds:[di].COI_size.P_y, dx
	ret
ChartObjectSetSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.
		cx, dx  = new size

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Assume that subclass has recalculated size before calling this
	routine.  If new size is different than old size, then send a
	SET_POSITION to the ChartGroup, causing all objects to adjust
	their positions.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectRecalcSize	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax,cx,dx,bp
	.enter
	mov	ax, cx
	mov	bx, dx
	xchg	cx, ds:[di].COI_size.P_x
	xchg	dx, ds:[di].COI_size.P_y


	cmp	ax, cx
	jne	newSize
	cmp	bx, dx
	je	done

newSize:
	mov	cl, mask COS_IMAGE_INVALID
	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	call	ObjCallInstanceNoLock

done:

	.leave
	ret
ChartObjectRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of a chart object

CALLED BY:	

PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		cx	= Width
		dx	= Height
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectGetSize	method dynamic	ChartObjectClass,
			MSG_CHART_OBJECT_GET_SIZE
	mov	cx, ds:[di].COI_size.P_x
	mov	dx, ds:[di].COI_size.P_y
	ret
ChartObjectGetSize	endm

ChartObjectCode	ends
