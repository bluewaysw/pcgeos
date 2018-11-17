COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupPosition.asm

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
	CDB	1/30/92   	Initial version.

DESCRIPTION:
	

	$Id: cgroupPosition.asm,v 1.1 97/04/04 17:45:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetDocPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the 32-bit position

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		ss:bp	= PointDWord position

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupSetDocPosition	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_SET_DOC_POSITION
	uses	ax,cx
	.enter
	segmov	es, ds
	segmov	ds, ss
	mov	si, bp
 	lea	di, es:[di].CGI_docPosition
	MovMem	<size PointDWord>
	
	.leave
	ret
ChartGroupSetDocPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetDocPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the position of the chart group in document
		coordinates 

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

		ss:bp = buffer of size PointDWord

RETURN:		ss:bp - buffer filled in

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGetDocPosition	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_GET_DOC_POSITION
	uses	cx

	.enter
	segmov	es, ss, si
 	lea	si, es:[di].CGI_docPosition
	mov	di, bp
	MovMem	<size PointDWord>
	
	.leave
	ret
ChartGroupGetDocPosition	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	This method is NOT used to set the position -- position for
ChartGroup is always 0,0.  This method is used to set the position of
all children.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupSetPosition	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_SET_POSITION
	uses	cx,dx
	.enter
	clr	cx, dx
	mov	di, offset ChartGroupClass
	call	ObjCallSuperNoLock

	.leave
	ret
ChartGroupSetPosition	endm

