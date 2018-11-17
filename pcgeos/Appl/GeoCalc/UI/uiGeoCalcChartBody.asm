COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 19XX.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	PC GEOS
MODULE:	        
FILE:		uiGeoCalcChartBody.asm

AUTHOR:		Cassie Hartzog, May 17, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	5/17/95		Initial revision


DESCRIPTION:
	Methods for GeoCalcChartBodyClass.

	$Id: uiGeoCalcChartBody.asm,v 1.1 97/04/04 15:48:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0					; this doesn't work right...

if _CHARTS

GeoCalcClassStructures	segment	resource
	GeoCalcChartBodyClass	
GeoCalcClassStructures	ends

endif


UICode		segment resource

if _CHARTS andFALSE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcChartBodyAddGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a grobj, then set its action notification output to
		be the GeoCalcChartBody

CALLED BY:	MSG_GB_ADD_GROBJ

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcChartBodyClass
		ax - the message
		cx:dx - object
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcChartBodyAddGrObj	method dynamic GeoCalcChartBodyClass,
						MSG_GB_ADD_GROBJ
		uses	cx, dx
		.enter
	;
	; Add the child
	;
		pushdw	cxdx
		mov	di, offset GeoCalcChartBodyClass
		call	ObjCallSuperNoLock	
		popdw	cxdx
	;
	; If we're in the middle of creating the chart, we want
	; the notification to go to us, else to the document
	;
		mov	ax, TEMP_CREATING_CHART
		call	ObjVarFindData			; carry set if found

		mov	bx, ds:[LMBH_handle]
		mov	ax, si				; ^lbx:ax <- ChartBody
		xchgdw	bxax, cxdx			; ^lbx:ax <- new GrObj
		jc	haveOD				; set output to me
	;
	; We're not creating a chart. Get the OD of the document
	; (my Vis parent). 
	;
		push	bx, ax
		mov	cx, segment GeoCalcDocumentClass
		mov	dx, offset GeoCalcDocumentClass
		mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
		call	VisCallParent			; ^lcx:dx <- document
EC <		ERROR_NC -1						>
		pop	bx, ax
haveOD:
	; Pass:
	; 	^lcx:dx = optr of ChartBody or document
	; 	^lbx:si = optr of new grobj
	;
		mov	si, ax				; ^lbx:si <- new grobj
		mov	ax, MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
		clr	di
		call	ObjMessage

		.leave
		ret
GeoCalcChartBodyAddGrObj		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcChartBodyActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some action has been performed on a GrObj, and it has
		sent this notification.

CALLED BY:	MSG_GROBJ_ACTION_NOTIFICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcChartBodyClass
		ax - the message
		bp - GrObjActionNotificationType

RETURN:		bp - based on GrObjActionNotificationType
	     	GOANT_PRE_DELETE - zero to abort the deletion

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcChartBodyActionNotification	method dynamic GeoCalcChartBodyClass,
						MSG_GROBJ_ACTION_NOTIFICATION
	;
	; If there is a chart object, pass this notification on to it.
	;
		tst	ds:[di].CBI_comp.CP_firstChild.handle
EC <		WARNING_Z -1						>
		jz	noChart
	
		push	si, bp
		movdw	bxsi, ds:[di].CBI_comp.CP_firstChild
		clr	di
		call	ObjMessage
		pop	si, bp
		
noChart:
	;
	; Only need to redraw in certain cases.
	;
		cmp	bp, GOANT_SELECTED
		jb	done
		cmp	bp, GOANT_WRAP_CHANGED
		ja	done
	;
	; Tell the document to invalidate the locked parts of the
	; spreadsheet, if it is locked.
	;
		mov	ax, MSG_GEOCALC_DOCUMENT_INVALIDATE_LOCKED_AREAS
		call	VisCallParent
		
done:		
		ret
GeoCalcChartBodyActionNotification		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcChartBodyCreateChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_CHART_BODY_CREATE_CHART
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcChartBodyClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcChartBodyCreateChart		method dynamic GeoCalcChartBodyClass,
						MSG_CHART_BODY_CREATE_CHART

		clr	cx
		mov	ax, TEMP_CREATING_CHART
		call	ObjVarAddData

		mov	ax, MSG_CHART_BODY_CREATE_CHART
		mov	di, offset GeoCalcChartBodyClass
		call	ObjCallSuperNoLock

		push	ax, cx				; save return values
		
		mov	ax, TEMP_CREATING_CHART
		call	ObjVarDeleteData

		pop	ax, cx				; return al, cx
		
		ret
GeoCalcChartBodyCreateChart		endm

endif

UICode		ends

endif
