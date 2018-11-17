COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisPosition.asm

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
	CDB	1/ 3/92   	Initial version.

DESCRIPTION:
	

	$Id: axisPosition.asm,v 1.1 97/04/04 17:45:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


AxisCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Notify title of new position

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		cx, dx - position

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisSetPosition	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_SET_POSITION
	uses	ax
	.enter

EC <	call	ECCheckAxisDSSI		>

	mov	di, offset AxisClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_TITLE_NOTIFY_AXIS_POSITION
	call	AxisCallTitle
	
	.leave
	ret
AxisSetPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisCallTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a message to the title

CALLED BY:	AxisSetPosition, AxisSetSize

PASS:		*ds:si - axis object
		ax - message to send

RETURN:		nothing 

DESTROYED:	si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisCallTitle	proc near
	class	AxisClass

	DerefChartObject ds, si, di
	mov	si, ds:[di].AI_title
	tst	si
	jz	done
	call	ObjCallInstanceNoLock
done:
	ret
AxisCallTitle	endp

AxisCode	ends
