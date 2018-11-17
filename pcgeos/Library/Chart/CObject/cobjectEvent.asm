COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectEvent.asm

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
	CDB	1/15/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectEvent.asm,v 1.1 97/04/04 17:46:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Deal with a classed event.  Only send it on to
		superclass if this object is selected, otherwise nuke
		the event.

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

		cx 	- event handle
		dx	- travel option

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectSendClassedEvent	method	dynamic	ChartObjectClass, 
					MSG_META_SEND_CLASSED_EVENT
	tst	ds:[di].COI_selection
	jz	destroy

	mov	di, offset ChartObjectClass
	GOTO	ObjCallSuperNoLock

destroy:
	mov	bx, cx
	call	ObjFreeMessage
	ret
ChartObjectSendClassedEvent	endm

