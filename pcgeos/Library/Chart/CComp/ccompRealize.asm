COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompRealize.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/17/92   	Initial version.

DESCRIPTION:
	

	$Id: ccompRealize.asm,v 1.1 97/04/04 17:48:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	send the message to the kids

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= Segment of ChartCompClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompRealize	method	dynamic	ChartCompClass, 
					MSG_CHART_OBJECT_REALIZE

	andnf	ds:[di].COI_state, not mask COS_IMAGE_PATH

	mov	di, offset ChartCompClass
	call	ObjCallSuperNoLock

	mov	bx, offset ChartCompRealizeCB
	call	ChartCompProcessChildren
	ret
ChartCompRealize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompRealizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a "realize" to the child if the child's
		IMAGE_INVALID or IMAGE_PATH bits are set

CALLED BY:	ChartCompRealize via ChartCompProcessChildren

PASS:		*ds:si - child

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompRealizeCB	proc far
	class	ChartObjectClass
	.enter

	DerefChartObject ds, si, di
	test	ds:[di].COI_state, mask COS_IMAGE_INVALID or \
				mask COS_IMAGE_PATH 
	jz	done
	push	ax
	mov	di, 1200
	call	ThreadBorrowStackSpace
	call	ObjCallInstanceNoLock
	call	ThreadReturnStackSpace
	pop	ax
done:

	clc
	.leave
	ret
ChartCompRealizeCB	endp

