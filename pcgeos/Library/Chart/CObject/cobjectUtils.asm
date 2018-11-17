COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectUtils.asm

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
	CDB	1/29/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectUtils.asm,v 1.1 97/04/04 17:46:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	detach myself from the Chart linkage

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectRemove	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_REMOVE
	uses	ax,cx,dx
	.enter

	mov	ax, MSG_CHART_COMP_REMOVE_CHILD
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ChartObjectCallParent

 	; Mark the entire tree invalid
 
 	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
 	mov	cl, mask COS_GEOMETRY_INVALID
 	call	UtilCallChartGroup

	.leave
	ret
ChartObjectRemove	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke the grobj for this object.	

PASS:		*ds:si	= ChartObjectClass object

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Called as both a METHOD and a PROCEDURE

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectClearAllGrObjes	method	ChartObjectClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	uses	bx,si,di
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	DerefChartObject ds, si, di
	clrdw	bxsi
	xchgdw	bxsi, ds:[di].COI_grobj
	call	UtilClearGrObj

	.leave
	ret
ChartObjectClearAllGrObjes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the grobject and myself

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectFree	method	dynamic	ChartObjectClass, 
					MSG_META_OBJ_FREE
	uses	ax
	.enter
	mov	ax, MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	call	ObjCallInstanceNoLock
	.leave

	mov	di, offset ChartObjectClass
	GOTO	ObjCallSuperNoLock
ChartObjectFree	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCallParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the parent

CALLED BY:	ChartObjectSetState, UTILITY

PASS:		*ds:si - chart object
		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	If this object is the ChartGroup -- then only pass ChartMeta
	messages up to the parent.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCallParent	proc far

	class	ChartObjectClass

	uses	bx,di
	.enter

if ERROR_CHECK
	push	di
	call	ECCheckChartObjectDSSI
	DerefChartObject ds, si, di
	tst	ds:[di].COI_link.handle
	ERROR_Z	OBJECT_NOT_IN_COMPOSITE
	pop	di
endif

	cmp	si, offset TemplateChartGroup
	je	done

	clr	bx
	mov	di, offset COI_link
	call	ObjLinkCallParent
done:
	.leave
	ret
ChartObjectCallParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectFindParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the parent's OD

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjecClass

RETURN:		*ds:cx - parent

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectFindParent	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_FIND_PARENT
	clr	bx
	mov	di, offset COI_link
	call	ObjLinkFindParent
	mov	cx, si
	ret
ChartObjectFindParent	endm

