COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsObject.asm

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
	

	$Id: utilsObject.asm,v 1.1 97/04/04 17:47:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCreateTitleObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an object of TitleClass

CALLED BY:

PASS:		ds - segment in which to create object
		es - segment of ChartClassStructures block
		cl - ChartGrObjRotationType
		al - TitleType

RETURN:		^lcx:dx - new object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCreateTitleObject	proc far
	uses	ax,bx,di,si
	.enter
	;
	; we want to make sure es is pointing to the class structures 's
	; block.
	;
EC <	push	ax, bx							>
EC <	mov	ax, es							>
EC <	mov	bx, segment TitleClass					>
EC <	cmp	ax, bx							>
EC <	ERROR_NE	INVALID_CLASS_SEGMENT				>
EC <	pop	ax, bx							>

	push	ax			; TitleType
	mov	di, offset TitleClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate

	mov	ax, MSG_TITLE_SET_ROTATION
	call	ObjCallInstanceNoLock

	pop	cx			; TitleType
	mov	ax, MSG_TITLE_SET_TYPE
	call	ObjCallInstanceNoLock

	mov	cx, bx
	mov	dx, si
	.leave
	ret
UtilCreateTitleObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDetachAndKill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach an object from the tree and kill it.

CALLED BY:	AxisDestroyTitle, ChartGroupCreateOrDestroyLegend

PASS:		ds:di - address where chunk handle of object is stored

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDetachAndKill	proc far
	uses	ax,cx,dx,bp,si

	.enter

	clr	si
	xchg	si, ds:[di]
	tst	si
	jz	done

	; Detach the object
	mov	ax, MSG_CHART_OBJECT_REMOVE
	call	ObjCallInstanceNoLock

	; Free it
	mov	ax, MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
UtilDetachAndKill	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetChartAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the chart's attributes into CX and DX

CALLED BY:	global to chart library

PASS:		DS - segment of chart objects

RETURN:		cl - chart type
		ch - chart variation
		dx - chart flags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Don't bother sending a message to ChartGroup, 'cause this should
	be FAST

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetChartAttributes	proc far
	uses	si
	class	ChartGroupClass
	.enter
	assume	ds:ChartUI
	mov	si, ds:[TemplateChartGroup]
	mov	cx, {word} ds:[si].CGI_type
	mov	dx, ds:[si].CGI_flags
	assume	ds:dgroup
	.leave
	ret
UtilGetChartAttributes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallChartGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the ChartGroup

CALLED BY:

PASS:		ax,cx,dx,bp - message data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallChartGroup	proc far
	uses	si
	.enter
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock 
	.leave
	ret
UtilCallChartGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallChartBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a CALL to the chart body

CALLED BY:

PASS:		ax,cx,dx,bp - message data
		ds - segment of chart objects

RETURN:		ax,cx,dx,bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallChartBody	proc far

	uses	bx,si,di

	.enter

	clr	bx
	mov	di, offset COI_link
	mov	si, offset TemplateChartGroup
	call	ObjLinkCallParent

;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjBlockGetOutput
;	call	ObjMessage


	.leave
	ret
UtilCallChartBody	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallChartBodyForceQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a message to the body via the queue.

CALLED BY:	UTILITY

PASS:		ds - segment of chart objects

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallChartBodyForceQueue	proc far
	uses	bx,si,di
	.enter

	clr	bx
	mov	di, offset COI_link
	mov	si, offset TemplateChartGroup
	call	ObjLinkFindParent
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


	.leave
	ret
UtilCallChartBodyForceQueue	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallAxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the axes

CALLED BY:

PASS:		ds - data segment of chart objects
		ax, cx, dx, bp - message data to send
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallAxes	proc far
	uses	si
	class	PlotAreaClass		; !
	.enter
	assume	ds:ChartUI
	mov	di, ds:[TemplatePlotArea]
	mov	si, ds:[di].PAI_xAxis
	tst	si
	jz	afterX
	push	ax,cx,dx,bp
	call	ObjCallInstanceNoLock
	pop	ax,cx,dx,bp

afterX:
	mov	si, ds:[di].PAI_yAxis
	tst	si
	jz	done
	push	ax,cx,dx,bp
	call	ObjCallInstanceNoLock
	pop	ax,cx,dx,bp

done:
	.leave
	ret
UtilCallAxes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallLegend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call the legend object

CALLED BY:	

PASS:		ds - segment of chart stuff
		ax,cx,dx,bp - message data to send

RETURN:		ax,cx,dx,bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallLegend	proc far
	uses	si
	class	ChartGroupClass

	.enter

	assume	ds:ChartUI
	mov	si, ds:[TemplateChartGroup]
	assume 	ds:dgroup
	mov	si, ds:[si].CGI_legend
	tst	si
	jz	done
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
UtilCallLegend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallSeriesGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallSeriesGroup	proc far
	uses	si
	.enter

	mov	si, offset TemplateSeriesGroup
	call	ObjCallInstanceNoLock
	.leave
	ret
UtilCallSeriesGroup	endp

