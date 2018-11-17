COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendPair.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

DESCRIPTION:
	

	$Id: legendPair.asm,v 1.1 97/04/04 17:46:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendPairBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- LegendPairClass object
		ds:di	- LegendPairClass instance data
		es	- segment of LegentPairClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendPairBuild	method	dynamic	LegendPairClass, 
					MSG_CHART_OBJECT_BUILD
	uses	ax,cx,dx,bp
	.enter

	;
	; on first time build, create 2 children
	;

	test	ds:[di].COI_state, mask COS_BUILT
	jnz	callSuper

	mov	ds:[di].CCI_compType, CCT_VERTICAL
	mov	ds:[di].CCI_compFlags, mask CCF_NO_LARGER_THAN_CHILDREN
	;
	; Create PICTURE first
	;

	mov	bl, LIT_PICTURE
	call	LegendPairCreateChild

	mov	bl, LIT_TEXT
	call	LegendPairCreateChild



callSuper:
	.leave
	mov	di, offset LegendPairClass
	GOTO	ObjCallSuperNoLock
LegendPairBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendPairCreateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a child

CALLED BY:	LegendPairBuild

PASS:		bl - LegendItemType
		*ds:si - LegendPair object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendPairCreateChild	proc near
	uses	si

	.enter

	mov	di, offset LegendItemClass
	call	ChartCompCreateChild
	mov	si, dx
	mov	ax, MSG_LEGEND_ITEM_SET_TYPE
	mov	cl, bl
	call	ObjCallInstanceNoLock

	.leave
	ret
LegendPairCreateChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendPairGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that one of our grobjs is selected
		by notifying the parent

PASS:		*ds:si	- LegendPairClass object
		ds:di	- LegendPairClass instance data
		es	- segment of LegentPairClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendPairGrObjSelected	method	dynamic	LegendPairClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED,
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	call	ChartObjectCallParent
	mov	di, offset LegendPairClass
	GOTO	ObjCallSuperNoLock
LegendPairGrObjSelected	endm
