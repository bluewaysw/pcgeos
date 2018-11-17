COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupGrObj.asm

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
	CDB	2/18/92   	Initial version.

DESCRIPTION:
	
	$Id: cgroupGrObj.asm,v 1.1 97/04/04 17:45:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGrObjMoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Deal with the fact that the grobj has moved

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

		^lcx:dx = OD of grobj

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGrObjMoved	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_GROBJ_MOVED
	uses	ax,cx,dx,bp
locals	local	RectDWord
	.enter


	push	bp, si			; local frame, group
					; chunk handle

	; Get the GrObj's new position

	movOD	bxsi, cxdx
	mov	ax, MSG_GO_GET_DW_PARENT_BOUNDS

	lea	bp, locals
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp, si

	DerefChartObject ds, si, di 

	movdw	ds:[di].CGI_docPosition.PD_x, locals.RD_left, ax

	movdw	ds:[di].CGI_docPosition.PD_y, locals.RD_top, ax

	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
	mov	cl, mask COS_IMAGE_INVALID
	call	ChartCompCallChildren

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cl, mask COS_IMAGE_PATH
	call	ObjCallInstanceNoLock

	.leave
	ret
ChartGroupGrObjMoved	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGrObjDeleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke everything in sight.

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= segment of ChartGroupClass

RETURN:		bp - non-zero to really delete the object

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGrObjDeleted	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_GROBJ_DELETED
		.enter

	;
	; Free our grobj OD, as it's no longer valid.
	;

		clrdw	ds:[di].COI_grobj

		mov	ax, MSG_CHART_GROUP_DESTROY
		call	ObjCallInstanceNoLock

		mov	bp, 1			; really delete the object

		.leave
		ret
ChartGroupGrObjDeleted	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroy the chart group, and all its children & grobjes

PASS:		*ds:si	- ChartGroupClass object
		ds:di	- ChartGroupClass instance data
		es	- segment of ChartGroupClass

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 3/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupDestroy	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_DESTROY
		uses	cx,dx,bp
		.enter

		mov	ax, MSG_CHART_BODY_NOTIFY_CHART_DELETED
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	UtilCallChartBody

	;
	; Nuke all the grobjes
	;

		mov	ax, MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
		call	ObjCallInstanceNoLock

	;
	; Free the block
	;

		mov	ax, MSG_META_BLOCK_FREE
		call	ObjCallInstanceNoLock

		.leave
		ret
ChartGroupDestroy	endm


