COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisGrObj.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

DESCRIPTION:
	

	$Id: axisGrObj.asm,v 1.1 97/04/04 17:45:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGrObjAttred
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Mark this axis object as invalid

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	Suspend the body, and unsuspend it via the queue, so that we
	don't get multiple actions with multiple incoming messages.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGrObjAttred	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_GROBJ_ATTRED

	mov	ax, MSG_META_SUSPEND
	call	UtilCallChartBody

	mov	ax, MSG_META_UNSUSPEND
	call	UtilCallChartBodyForceQueue

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cx, mask COS_GEOMETRY_INVALID
	GOTO	ObjCallInstanceNoLock
AxisGrObjAttred	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSendToGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisSendToGrObj	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	.enter

	;
	; Only send this to the group!
	;
	mov_tr	ax, cx

	movOD	bxsi, ds:[di].AI_group
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	.leave
	ret
AxisSendToGrObj	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetGrObjText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of either the first text object for this
		axis, or, if none, the GOAM's text object

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

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

AxisGetGrObjText	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_GET_GROBJ_TEXT
	uses	ax,si
	.enter

	;
	; See if there's a text grobject in the array
	;

	DerefChartObject ds, si, di
	mov	si, ds:[di].COMI_array2
	tst	si
	jz	callSuper

	clr	ax
	call	ChunkArrayElementToPtr
	jc	callSuper

	tst	ds:[di].handle
	jz	callSuper

	movdw	bxsi, ds:[di]
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret

callSuper:
	.leave
	mov	di, offset AxisClass
	GOTO	ObjCallSuperNoLock

AxisGetGrObjText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisFindGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the group's OD

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		^lcx:dx - group object

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisFindGrObj	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_FIND_GROBJ
		movdw	cxdx, ds:[di].AI_group	
		ret
AxisFindGrObj	endm


