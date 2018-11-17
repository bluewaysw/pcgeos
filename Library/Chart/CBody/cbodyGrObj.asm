COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyGrObj.asm

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
	CDB	2/19/92   	Initial version.

DESCRIPTION:
	

	$Id: cbodyGrObj.asm,v 1.1 97/04/04 17:48:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyGetGOAMText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	return the OD of the GOAM's text object

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		^lcx:dx - GOAM text

DESTROYED:	ax,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyGetGOAMText	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_GET_GOAM_TEXT
	movdw	bxsi, ds:[di].GBI_goam
	mov	ax, MSG_GOAM_GET_TEXT_OD
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
ChartBodyGetGOAMText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyFindGrObjByNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the optr of a grobj given its position in the
		draw list.

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		same as ObjCompFindGrObj

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyFindGrObjByNumber	method	dynamic	ChartBodyClass, 
				MSG_CHART_BODY_FIND_GROBJ_BY_NUMBER

	;
	; Assume that GrObj and GrObjBody are at same master level.
	; Whee! 
	;
		
CheckHack <(offset GrObj_offset) eq (offset GrObjBody_offset)>

		mov	dx, cx
		clr	cx				; dx - # of child
		mov	ax, offset GOI_drawLink
		mov	bx, offset GrObj_offset		;grobj is master
		mov	di, offset GBI_drawComp
		call	ObjCompFindChild
		
		ret
ChartBodyFindGrObjByNumber	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyGetGrObjFileStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the GrObjFileStatus

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		al 	- GrObjFileStatus

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyGetGrObjFileStatus	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_GET_GROBJ_FILE_STATUS
		mov	di, ds:[si]
		add	di, ds:[di].GrObjBody_offset
		mov	al, ds:[di].GBI_fileStatus
		ret
ChartBodyGetGrObjFileStatus	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyArrange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Change depth for all chart grobjes

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
		Instead of intercepting MSG_GB_CHANGE_GROBJ_DEPTH and
		bailing on all depth changes for chart objects, we handle
		the higher level messages here and make sure that all the
		chart objects are affected by any depth changes made when
		any of the chart objects are selected.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodyArrange	method	dynamic	ChartBodyClass, 
					MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT,
					MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK,
					MSG_GB_SHUFFLE_SELECTED_GROBJS_UP,
					MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN

	push	ax, cx, dx, bp

	;
	; "SelectedCharts" is any chart group with a selected chart object
	;
	mov	ax, MSG_CHART_OBJECT_SET_STATE
	mov	cx, mask COS_UPDATING
	call	ChartBodySendToSelectedCharts

	;
	; select all chart objects (including top-level rect) in any chart
	; groups that have any chart objects selected
	;
	mov	cx, MSG_GO_BECOME_SELECTED
	mov	dl, HUM_MANUAL
	mov	bx, offset SendToAllChartGrObjes
	call	ChartBodyProcessChildren

	;
	; arrange as desired, but affecting all chart objects (because we've
	; selected them above)
	;
	pop	ax, cx, dx, bp
	mov	di, offset ChartBodyClass
	call	ObjCallSuperNoLock

	;
	; unselect all chart grobjes except top level rect (that's the
	; difference between SendToChartGrObjes and SendToAllChartGrObjes)
	;
	mov	cx, MSG_GO_BECOME_UNSELECTED
	mov	bx, offset SendToChartGrObjes
	call	ChartBodyProcessChildren

	;
	; after above, we have top-level rect selected, so "SelectedCharts"
	; is non-zero
	;
	mov	ax, MSG_CHART_OBJECT_SET_STATE
	mov	cx, mask COS_UPDATING shl 8
	call	ChartBodySendToSelectedCharts

	;
	; back to reality: a hack to force handles to redraw for selected
	; top-level rect
	;
	mov	ax, MSG_GO_DRAW_HANDLES
	clr	bx, dx				; no gstate
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon
	ret
ChartBodyArrange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAllChartGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to all the children of this
		chart group

CALLED BY:	ChartBodyArrange

PASS:		*ds:si - chart group
		cx - message to send

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/5/94   	Modified from SendToChartGrObjes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAllChartGrObjes	proc far

	class	ChartGroupClass

	DerefChartObject ds, si, di
	tst	ds:[di].COI_selection
	jz	done

	;
	; send to our children
	;
	push	cx
	mov	ax, MSG_CHART_OBJECT_SEND_TO_GROBJ
	call	ChartCompCallChildren
	pop	cx

	;
	; ...and to ourselves
	;
	push	es
	mov	ax, MSG_CHART_OBJECT_SEND_TO_GROBJ
	mov	di, segment ChartCompClass
	mov	es, di
	mov	di, offset ChartCompClass
	call	ObjCallSuperNoLock
	pop	es

done:
	clc
	ret
SendToAllChartGrObjes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyChangeGrObjDepth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Don't change this grobj's depth if its a grobj that
		has an action notification pointing to a chart object.

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass
		^lcx:dx	- grobj
		bp	- GrObjBodyAddGrObjFlags

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
;
; handle at higher level (see above) to allow arrange charts
;
ChartBodyChangeGrObjDepth	method	dynamic	ChartBodyClass, 
					MSG_GB_CHANGE_GROBJ_DEPTH
		uses	ax,cx,dx,si
		
notifData	local	GrObjActionNotificationStruct
vdParams	local	GetVarDataParams
		
		.enter

	;
	; Fetch the ATTR_GO_ACTION_NOTIFICATION from the grobj
	;
		mov	ss:[vdParams].GVDP_buffer.segment, ss
		lea	ax, ss:[notifData]
		mov	ss:[vdParams].GVDP_buffer.offset, ax
		mov	ss:[vdParams].GVDP_bufferSize, size vdParams
		mov	ss:[vdParams].GVDP_dataType,
					ATTR_GO_ACTION_NOTIFICATION 
		push	bp
		lea	bp, ss:[vdParams]
		mov	ax, MSG_META_GET_VAR_DATA
		mov	bx, cx
		mov	si, dx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		cmp	ax, size notifData
		jne	gotoSuper
		
		mov	cx, segment ChartObjectClass
		mov	dx, offset ChartObjectClass
		movdw	bxsi, ss:[notifData].GOANS_optr
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jnc	gotoSuper

		.leave					; <- EXIT
		ret
		
		
		
gotoSuper:
		.leave
		mov	di, offset ChartBodyClass
		GOTO	ObjCallSuperNoLock		; <- EXIT
ChartBodyChangeGrObjDepth	endm
endif
