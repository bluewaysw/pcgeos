COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyCreate.asm

AUTHOR:		Chris Boyke
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial Revision  

DESCRIPTION:
	Main module

	$Id: cbodyCreate.asm,v 1.1 97/04/04 17:48:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MsgChartBodyCreateChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	MsgChartBodyCreateChart

		call chartObj::MSG_CHART_BODY_CREATE_CHART();

C DECLARATION:

extern void
    _pascal MsgChartBodyCreateChart(ChartCreateReturnParameters *retVal,
				    optr chartObj;
				    ChartCreateParameters *params);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGCHARTBODYCREATECHART	proc	far  retVal:fptr.ChartCreateReturnParameters,
				     chartObj:optr,
				     params:fptr.ChartCreateParameters
		uses	ds,si, es,di
		.enter
	;
	; Create space on the stack so we can copy the ChartCreateParameters
	;
		mov	dx, size ChartCreateParameters
		sub	sp, dx
	;
	; Copy the ChartCreateParameters onto the stack
	;
		segmov	es, ss
		mov	di, sp
		lds	si, ss:[params]
		mov	cx, dx
		rep	movsb
	;
	; @call chartObj::MSG_CHART_BODY_CREATE_CHART()
	;
		movdw	bxsi, ss:[chartObj]

		mov	ax, MSG_CHART_BODY_CREATE_CHART
		mov	di, sp

		push	bp
		mov	bp, di
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
	;
	; Remove space allocated on the stack for ChartCreateParameters
	;
		add	sp, size ChartCreateParameters
	;
	; Setup return values
	;
		lds	si, ss:[retVal]
		mov	ds:[si].CCRP_type, al
		mov	ds:[si].CCRP_chart, cx

		.leave
		ret
MSGCHARTBODYCREATECHART	endp

	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyCreateChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= Segment of ChartBodyClass.
		ss:bp 	= ChartCreateParameters

RETURN:		al - ChartReturnType
		cx - VM handle of block containing new chart.

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyCreateChart	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_CREATE_CHART
	uses	dx,bp

	.enter

;-----------------------------------------------------------------------------
;			 Create Object Block
;-----------------------------------------------------------------------------
	;
	; Duplicate the chart block.
	;
	mov	bx, handle ChartUI		; bx <- block to duplicate
	clr	ax				; have current geode own block
	clr	cx				; have current thread run block
	call	ObjDuplicateResource		; bx <- handle of new block


	; Attach child block to the VM file

	clr	ax				; Allocate new VM block
	mov	cx, bx
	call	UtilGetVMFile			; bx <- VM file handle
	call	VMAttach			; ax <- VM block handle
	call	VMPreserveBlocksHandle
	push	ax				; save VM block handle


	; Add ChartGroup to my list of children.		

	call	ChartBodyAddChild 
	segmov	es, ds			; body block handle

	; Lock child's block

	mov	bx, cx				; bx <- new block handle
	push	bx
	call	ObjLockObjBlock
	mov	ds, ax

	; Set data in child

	mov	si, offset TemplateChartGroup

	;
	; Set position & size
	;

	CheckHack <offset CCP_position eq 0>
	mov	ax, MSG_CHART_GROUP_SET_DOC_POSITION
	call	ObjCallInstanceNoLock
	
	mov	cx, ss:[bp].CCP_size.P_x
	mov	dx, ss:[bp].CCP_size.P_y
	mov	ax, MSG_CHART_OBJECT_SET_SIZE
	call	ObjCallInstanceNoLock


	;
	; Set chart type and variation.  Do this BEFORE setting the
	; data block, because ChartGroupSetData makes use of the
	; current chart type.
	;

		CheckHack <offset CCP_variation eq offset CCP_type +1>
	mov	cx, {word} ss:[bp].CCP_type

	ECCheckEtype	cl, ChartType
	ECCheckChartVariation	ch

	mov	ax, MSG_CHART_GROUP_SET_CHART_TYPE
	call	ObjCallInstanceNoLock		; al - ChartReturnType

	;
	; Set parameters block
	;

	mov	cx, ss:[bp].CCP_data		; cx <- data handle
	mov	ax, MSG_CHART_GROUP_SET_DATA
	call	ObjCallInstanceNoLock


	;
	; Now, build the dang thing
	;

	push	bp
	clr	bp
	mov	ax, MSG_CHART_OBJECT_BUILD
	call	ObjCallInstanceNoLock
	pop	bp

	cmp	al, CRT_OK
	jne	errorDelete

	;
	; Unselect all grobjes
	;
		
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	UtilCallChartBody		

	;
	; Select the chart group's GrObject
	;

	mov	ax, MSG_GO_BECOME_SELECTED
	mov	dl, HUM_NOW
	call	ChartObjectCallGrObjFar
	mov	al, CRT_OK

afterSelect:

	;
	; Unlock child's block
	;

	pop	bp			; vm block handle of chart 
	call	VMDirty
	call	VMUnlock

	; return child's VM block handle to caller

	pop	cx			

	.leave
	ret

	;
	; Well, there was some error creating the thing, so destroy it.
	;

errorDelete:
	push	ax			; al - error code
	mov	ax, MSG_CHART_GROUP_DESTROY
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	afterSelect

ChartBodyCreateChart	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyUpdateChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the chart with new numbers

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= Segment of ChartBodyClass.
		cx - VM block handle of chart to update
	      	dx - VM block handle of new chart data

RETURN:		al - ChartReturnType

DESTROYED:	bx,si,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyUpdateChart	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_UPDATE_CHART
	uses	cx
	.enter

	mov	ax, cx			; VM handle of chart objects
	call	UtilGetVMFile		; bx <- VM file handle
	call	VMVMBlockToMemBlock
	mov	bx, ax	

	mov	ax, MSG_CHART_GROUP_SET_DATA
	mov	si, offset TemplateChartGroup
	mov	cx, dx
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bp, mask BCF_DATA
	mov	ax, MSG_CHART_OBJECT_BUILD
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	al, CRT_OK
	.leave
	ret
ChartBodyUpdateChart	endm

