COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupGeometry.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	SeriesGroupSizeAndPosition Set size -- set all children same size &
				position

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 3/92   	Initial version.

DESCRIPTION:
	

	$Id: sgroupGeometry.asm,v 1.1 97/04/04 17:46:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupSizeAndPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set size -- set all children same size & position

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= Segment of SeriesGroupClass.
		cx, dx  = size to set

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupSizeAndPosition	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_RECALC_SIZE,
					MSG_CHART_OBJECT_SET_POSITION
	.enter

	; send same data to all children

	call	ChartCompCallChildren

	; skip normal ChartCompClass behavior, and do ChartObject
	; instead.

	.leave
	mov	di, offset ChartCompClass
	GOTO	ObjCallSuperNoLock
SeriesGroupSizeAndPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- SeriesGroupClass object
		ds:di	- SeriesGroupClass instance data
		es	- segment of SeriesGroupClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupMarkInvalid	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_MARK_INVALID
	uses	ax,cx,dx,bp
	.enter

	mov	di, offset SeriesGroupClass
	call	ObjCallSuperNoLock

	test	cl, mask COS_IMAGE_PATH
	jz	done

	
	;
	; If IMAGE_PATH, then one of the children has marked its image
	; invalid.  If one series is given a REALIZE, then they all
	; must get it, so mark all the other children invalid as well.
	;

	mov	cl, mask COS_IMAGE_INVALID
	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
	call	ObjCallInstanceNoLock


done:
	.leave
	ret
SeriesGroupMarkInvalid	endm


