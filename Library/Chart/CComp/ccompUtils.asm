COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompUtils.asm

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
	CDB	12/13/91	Initial version.

DESCRIPTION:
	

	$Id: ccompUtils.asm,v 1.1 97/04/04 17:47:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke all the grobjes for this object and its children

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= segment of ChartCompClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompClearAllGrObjes	method	dynamic	ChartCompClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	call	ChartCompCallChildren
	mov	di, offset ChartCompClass
	GOTO	ObjCallSuperNoLock
ChartCompClearAllGrObjes	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartCompClass object
		ds:di	- ChartCompClass instance data
		es	- segment of ChartCompClass

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

ChartCompSetType	method	dynamic	ChartCompClass, 
					MSG_CHART_COMP_SET_TYPE
	mov	ds:[di].CCI_compType, cl
	ret
ChartCompSetType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompSetMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	set the margin

PASS:		*ds:si	- ChartCompClass object
		ds:di	- ChartCompClass instance data
		es	- segment of ChartCompClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompSetMargin	method	dynamic	ChartCompClass, 
					MSG_CHART_COMP_SET_MARGIN
	uses	cx
	.enter
	lea	di, ds:[di].CCI_margin
	segmov	es, ds
	segmov	ds, ss
	mov	si, bp
	mov	cx, (size Rectangle)/2
	rep	movsw
	.leave
	ret
ChartCompSetMargin	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompCountChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the # of kids

CALLED BY:	UTILITY

PASS:		*ds:si - ChartComp

RETURN:		ax - number of kids

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompCountChildren	proc far

	class	ChartCompClass

	uses	bx,dx,di

	.enter

	clr	dx, di
	push	di, di			; First child
	mov	di, offset COI_link
	push	di
	clr	bx
	push	bx			; code segment (0)
	mov	di, OCCT_COUNT_CHILDREN
	push	di			; offset
	mov	di, offset CCI_comp
	call	ObjCompProcessChildren
	mov_tr	ax, dx

	.leave
	ret
ChartCompCountChildren	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke all of this object's children before nuking this
		object. 

PASS:		*ds:si	- ChartCompClass object
		ds:di	- ChartCompClass instance data
		es	- segment of ChartCompClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompFree	method	dynamic	ChartCompClass, 
					MSG_META_OBJ_FREE,
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	call	ChartCompCallChildren
	mov	di, offset ChartCompClass
	GOTO	ObjCallSuperNoLock
ChartCompFree	endm

