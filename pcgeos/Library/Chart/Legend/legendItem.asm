COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendItem.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

DESCRIPTION:
	

	$Id: legendItem.asm,v 1.1 97/04/04 17:46:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- LegendItemClass object
		ds:di	- LegendItemClass instance data
		es	- segment of LegendItemClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendItemSetType	method	dynamic	LegendItemClass, 
					MSG_LEGEND_ITEM_SET_TYPE
	mov	ds:[di].LII_type, cl
	ret
LegendItemSetType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- LegendItemClass object
		ds:di	- LegendItemClass instance data
		es	- segment of LegendItemClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendItemGrObjSelected	method	dynamic	LegendItemClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED,
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	call	ChartObjectCallParent
	mov	di, offset LegendItemClass
	GOTO	ObjCallSuperNoLock
LegendItemGrObjSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemGetGrObjText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of the grobj text object

PASS:		*ds:si	- LegendItemClass object
		ds:di	- LegendItemClass instance data
		es	- segment of LegentItemClass

RETURN:		^lcx:dx - text object

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendItemGetGrObjText	method	dynamic	LegendItemClass, 
					MSG_CHART_OBJECT_GET_GROBJ_TEXT
	tst	ds:[di].COI_grobj.handle
	jz	callSuper

	cmp	ds:[di].LII_type, LIT_TEXT
	jne	callSuper


	movOD	bxsi, ds:[di].COI_grobj
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

callSuper:
	mov	di, offset LegendItemClass
	GOTO	ObjCallSuperNoLock

LegendItemGetGrObjText	endm

