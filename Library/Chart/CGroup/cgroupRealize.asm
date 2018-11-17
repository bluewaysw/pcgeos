COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupRealize.asm

AUTHOR:		John Wedgwood, Oct 10, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/10/91	Initial revision

DESCRIPTION:

	$Id: cgroupRealize.asm,v 1.1 97/04/04 17:45:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Realize the Chart Group.

CALLED BY:	via MSG_CHART_OBJECT_REALIZE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
	draw a big white rectangle and then call kids

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/19/92		Initial version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupRealize	method dynamic	ChartGroupClass, 
			MSG_CHART_OBJECT_REALIZE

		uses	ax,cx,dx,bp

		.enter	

		mov	bl, ds:[di].COI_state		; get original state

		mov	di, 1200
		call	ThreadBorrowStackSpace
		push	di

		mov	cl, mask COS_IMAGE_PATH
		call	CheckToUpdate
LONG		jc	done

	;
	; Suspend the body
	;

		mov	ax, MSG_META_SUSPEND
		call	UtilCallChartBody


	;
	; Undraw the grobj's handles
	;
		mov	ax, MSG_GO_UNDRAW_HANDLES
		clr	dx
		call	ChartObjectCallGrObjFar

	;
	; If the image is OK, then skip this object
	;

		test	bl, mask COS_IMAGE_INVALID
		jz	afterRectangle

	;
	; create (or reposition) the rectangle
	;
		sub	sp, size CreateRectParams
		mov	bp, sp
		mov	[bp].CGOP_flags, mask CGOF_AREA_MASK or \
					mask CGOF_AREA_COLOR

		DerefChartObject ds, si, di
		movP	[bp].CGOP_position, ds:[di].COI_position, ax
		movP	[bp].CGOP_size, ds:[di].COI_size, ax
		mov	[bp].CGOP_areaColor, C_WHITE
		mov	[bp].CGOP_locks, mask GOL_ROTATE or mask GOL_SKEW or \
					mask GOL_GROUP
		mov	[bp].CGOP_areaMask, SDM_100
		call	ChartObjectCreateOrUpdateRectangle
		add	sp, size CreateRectParams


afterRectangle:


	;
	; Inval this grobj
	;
		mov	ax, MSG_GO_INVALIDATE
		call	ChartObjectCallGrObjFar


	;
	; Redraw the handles, if they were drawn before, and if the
	; body has the target
	;
		mov	ax, MSG_CHART_BODY_GET_GROBJ_FILE_STATUS
		call	UtilCallChartBody
		test	al, mask GOFS_TARGETED
		jz	drawChildren
		
		mov	ax, MSG_GO_DRAW_HANDLES_MATCH
		clr	dx
		call	ChartObjectCallGrObjFar

drawChildren:

	;
	; Now, draw the kids.  First, get the position of the top
	; grobject in the chart
	;
		
		call	ChartGroupGetTopGrObj

	;
	; Set type and variation for children
	;
		DerefChartObject ds, si, di
		mov	cx, {word} ds:[di].CGI_type
		mov	dx, ds:[di].CGI_flags

		mov	ax, MSG_CHART_OBJECT_REALIZE
		mov	di, offset ChartGroupClass
		call	ObjCallSuperNoLock

	;
	; Nuke the "top" vardata
	;
		
		mov	ax, TEMP_CHART_GROUP_TOP_GROBJ
		call	ObjVarDeleteData
		
		mov	ax, MSG_META_UNSUSPEND
		call	UtilCallChartBody	; destroys ax,cx,dx,bp

		call	ChartGroupEndUpdate
done:
		pop	di
		call	ThreadReturnStackSpace

		.leave
		ret
ChartGroupRealize	endm


