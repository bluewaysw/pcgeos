COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesColumn.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

DESCRIPTION:
	

	$Id: seriesColumn.asm,v 1.1 97/04/04 17:47:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Realize a column object

PASS:		*ds:si	= ColumnClass object
		ds:di	= ColumnClass instance data
		es	= Segment of ColumnClass.

RETURN:		

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnRealize	method	dynamic	ColumnClass, 
					MSG_CHART_OBJECT_REALIZE

locals	local	SeriesDrawLocalVars
	.enter	inherit
	
	mov	locals.SDLV_callback, offset ColumnRealizeCB
	.leave
	GOTO	ColumnBarRealizeCommon
ColumnRealize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BarRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Realize a Bar object

PASS:		*ds:si	= BarClass object
		ds:di	= BarClass instance data
		es	= Segment of BarClass.

RETURN:		

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BarRealize	method	dynamic	BarClass, 
					MSG_CHART_OBJECT_REALIZE
locals	local	SeriesDrawLocalVars
	.enter	inherit 
	mov	locals.SDLV_callback, offset BarRealizeCB
	.leave
	FALL_THRU	ColumnBarRealizeCommon
BarRealize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnBarRealizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common "realize" routine for bar & column class.
		callback routine is set by caller

CALLED BY:	ColumnRealize, BarRealize

PASS:		ss:bp - SeriesDrawLocalVars frame
		ax - MSG_CHART_OBJECT_REALIZE

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnBarRealizeCommon	proc far
	uses	ax
		
	class	ColumnClass

locals	local	SeriesDrawLocalVars
	.enter	inherit

	mov	cl, locals.SDLV_seriesNum

	; draw each category	

	call	SeriesDrawEachCategory


	; Nuke extra grobjs if necessary
	mov	cx, COMT_PICTURE
	mov	dx, locals.SDLV_categoryCount
	call	ChartObjectRemoveExtraGrObjs

	mov	cx, COMT_TEXT
	call	ChartObjectRemoveExtraGrObjs

	inc	locals.SDLV_seriesNum



	; SERIOUS HACK!  call superclass of ColumnClass, whether
	; handling Bar or ColumnClass currently!

	mov	di, offset ColumnClass
	.leave
	GOTO	ObjCallSuperNoLock
ColumnBarRealizeCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnRealizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a column for the current series/category

CALLED BY:

PASS:		cl - series #
		dx - category #
		ss:bp - SeriesDrawLocalVars
		*ds:si - series object
		ds:di - series instance data

RETURN:		nothing 

DESTROYED:	ax,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 4/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnRealizeCB	proc near	

locals local	SeriesDrawLocalVars
	.enter inherit


	; get the top position

	call	ColumnBarGetValuePosition
	jc	done

	push	ax				; value position

	call	SeriesGetZeroPosition
	push	ax

	call	ColumnGetPosition	; ax = left, cx = right

	pop	dx		; zero  position
	pop	bx		; value position

	call	SeriesSetGrObjRectangle

	test	locals.SDLV_flags, mask CF_VALUES
	jz	done

	;
	; Draw value label on top of (or below) value position,
	; depending on whether value position is above or below zero
	; position. 
	; 

	cmp	bx, dx
	jl	above

	;
	; Text is below the column
	;

	add	bx, COLUMN_VALUE_LABEL_MARGIN
	add	ax, cx
	shr	ax
	mov	cl, TAT_TOP
	jmp	gotPosition

above:
	add	ax, cx
	shr	ax
	mov	cl, TAT_BOTTOM
gotPosition:
	call	DrawColumnOrBarValue

done:

	.leave
	ret
ColumnRealizeCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnBarGetValuePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common part of ColumnRealizeCB and BarRealizeCB --
		fetch the value position, and if not available, nuke
		the grobj, if any, at this position.

CALLED BY:	ColumnRealizeCB, BarRealizeCB

PASS:		*ds:si - ColumnClass object
		cl - series
		dx - category

RETURN:		ax - value position

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnBarGetValuePosition	proc near
		uses	bx,cx,dx,di

locals	local	SeriesDrawLocalVars
		.enter	inherit 

		call	SeriesGetValuePosition
		jnc	done

	;
	; Nuke the grobj(es)
	;
		mov	cx, COMT_PICTURE
		mov	dx, locals.SDLV_categoryNum
		call	ChartObjectMultipleClearGrObj

		test	locals.SDLV_flags, mask CF_VALUES
		jz	afterNukeValue

		mov	cx, COMT_TEXT
		mov	dx, locals.SDLV_categoryNum
		call	ChartObjectMultipleClearGrObj

afterNukeValue:
		stc
done:
		.leave
		ret
ColumnBarGetValuePosition	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BarRealizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw series for a bar chart

CALLED BY:	DrawSingleSeries

PASS:		ss:bp - SeriesDrawLocalVars
		dx	- category #
		ds:di - Series instance data

RETURN:		nothing 

DESTROYED:	ax,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BarRealizeCB	proc near	

locals	local	SeriesDrawLocalVars
	.enter	inherit

	mov	cl, locals.SDLV_seriesNum


	call	ColumnBarGetValuePosition
	jc	done
		
	push	ax			; value position

	call	SeriesGetZeroPosition	; ax <- zero position

	call	BarGetPosition		; bx <- bottom, dx <- top

	pop	cx			; 
	xchg	ax, cx			; ax <- value position
					; cx <- zero position

	call	SeriesSetGrObjRectangle

	test	locals.SDLV_flags, mask CF_VALUES
	jz	done

	;
	; Draw value label to right (or left) of value position
	; 
	; if value position (ax) > zero position, then draw label to
	; the right.  

	cmp	ax, cx
	jg	toTheRight

	sub	ax, BAR_VALUE_LABEL_MARGIN
	mov	cl, TAT_RIGHT
	jmp	gotHorizontalPosition

toTheRight:
	add	ax, BAR_VALUE_LABEL_MARGIN
	mov	cl, TAT_LEFT

gotHorizontalPosition:
	add	bx, dx		; calc midpoint of top/bottom
	shr	bx, 1
	call	DrawColumnOrBarValue
done:

	.leave
	ret
BarRealizeCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawColumnOrBarValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and set a text object for this series

CALLED BY:	ColumnRealizeCB, BarRealizeCB

PASS:		ax, bx	- position
		cl - TextAnchorType

		*ds:si - column or bar object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawColumnOrBarValue	proc near

	uses	ax,bx,cx,dx

locals	local	SeriesDrawLocalVars

	.enter	inherit 

	;
	; Convert the value to text
	;

	call	SeriesGetValueText

	push	cx, dx
	mov	cx, COMT_TEXT
	mov	dx, locals.SDLV_categoryNum
	call	ChartObjectMultipleGetGrObj
	pop	cx, dx

	call	SeriesCreateOrUpdateText

	mov	cx, COMT_TEXT
	mov	dx, locals.SDLV_categoryNum
	call	ChartObjectMultipleSetGrObj

	.leave
	ret
DrawColumnOrBarValue	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesSetGrObjRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a GrObj rectangle.  Add it to the current array
		of grobjects

CALLED BY:	ColumnRealizeCB, BarRealizeCB

PASS:		ax, bx,cx,dx - coordinates

		ss:bp - SeriesDrawLocalVars 
		*ds:si - Column object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesSetGrObjRectangle	proc near
	uses	ax,bx,cx,dx,di
locals	local	SeriesDrawLocalVars

	.enter	inherit

	sort	ax, cx
	sort	bx, dx

	sub	sp, size CreateRectParams
	mov	di, sp

	call	SeriesSetCreateGrObjParams


	ornf	ss:[di].CGOP_flags, mask CGOF_AREA_MASK or \
					mask CGOF_AREA_COLOR
	movP	ss:[di].CGOP_position, axbx

	; calculate size

	sub	cx, ax
	sub	dx, bx
	movP	ss:[di].CGOP_size, cxdx

	call	SeriesGetAreaAttributes
	
	mov	ss:[di].CGOP_areaColor, al
	mov	ss:[di].CGOP_areaMask, ah

	; Set move/resize locks

	mov	ss:[di].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	mov	cx, COMT_PICTURE
	mov	dx, locals.SDLV_categoryNum
	call	ChartObjectMultipleGetGrObj

	xchg	di, bp
	call	ChartObjectCreateOrUpdateRectangle
	xchg	di, bp

	call	ChartObjectMultipleSetGrObj

	add	sp, size CreateRectParams

	.leave
	ret
SeriesSetGrObjRectangle	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current left/right position for a column, 

CALLED BY:	ColumnRealizeCB

PASS:		ss:bp - SeriesDrawLocalVars 
		cl - series #
		dx - category number

RETURN:		ax - left, cx - right

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColumnGetPosition	proc near	
	uses	bx,dx,ds,si
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	;
	; get category position (left edge)
	;
	mov	si, locals.SDLV_categoryAxis
	mov	ax, MSG_CATEGORY_AXIS_GET_CATEGORY_POSITION
	call	ObjCallInstanceNoLock	

	segmov	ds, ss
	lea	si, ColumnLocals.CV_width
	call	FloatPushNumber
	call	FloatDivide2
	call	FloatSub			; FP: left edge

	test	locals.SDLV_flags, mask CF_STACKED
	jnz	gotPosition

	; Multiply series number by series width and add to current
	; position 

	call	MultiplySeriesNumByWidth

	call	FloatAdd		

gotPosition:

	call	FloatDup
	lea	si, ColumnLocals.CV_seriesWidth
	call	FloatPushNumber
	call	FloatAdd

	call	FloatFloatToDword
	ECMakeSureZero	dx

	mov_tr	cx, ax			; right edge
	call	FloatFloatToDword
	ECMakeSureZero	dx		; left edge


	.leave
	ret
ColumnGetPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BarGetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return vertical position for the current bar

CALLED BY:

PASS:		ss:bp - SeriesDrawLocalVars 
		cl - series #
		dx - category #

RETURN:		bx, dx - bottom and top positions

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BarGetPosition	proc near	
	uses	ax,cx,ds,si
locals	local	SeriesDrawLocalVars
	.enter	inherit 

	;
	; get category position (edge)
	;

	call	SeriesGetCategoryPosition	; middle (top/bottom)
	call	FloatWordToFloat

	segmov	ds, ss
	lea	si, ColumnLocals.CV_width
	call	FloatPushNumber
	call	FloatDivide2
	call	FloatAdd

	test	locals.SDLV_flags, mask CF_STACKED
	jnz	gotPosition

	; Multiply series number by series width and subtract
	; from current position

	call	MultiplySeriesNumByWidth
	call	FloatSub

gotPosition:
	call	FloatDup
	lea	si, ColumnLocals.CV_seriesWidth
	call	FloatPushNumber
	call	FloatSub
	call	FloatFloatToDword
	ECMakeSureZero	dx
	push	ax			; top

	call	FloatFloatToDword
	mov_tr	bx, ax			; bottom
	pop	dx			; top

	.leave
	ret
BarGetPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultiplySeriesNumByWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply the series number by the series width,
		subtracting off overlap amount, if any

CALLED BY:	ColumnGetPosition, BarGetPosition

PASS:		ss:bp - inherited local vars 
		ds = ss

RETURN:		(on fp stack): series # * series width

DESTROYED:	ax 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultiplySeriesNumByWidth	proc near

locals	local	SeriesDrawLocalVars

		.enter	inherit

		mov	al, locals.SDLV_seriesNum
		cbw
		call	FloatWordToFloat

		lea	si, ColumnLocals.CV_seriesWidth
		call	FloatPushNumber
		lea	si, ColumnLocals.CV_overlap
		call	FloatPushNumber
		call	FloatSub
		call	FloatMultiply

		.leave
		ret
MultiplySeriesNumByWidth	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle selection/unselection of grobjes

PASS:		*ds:si	= ColumnClass object
		ds:di	= ColumnClass instance data
		es	= Segment of ColumnClass.

		^lcx:dx = OD of grobj that's become
		selected/unselected 

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

	IF the UPDATING bit is set
		just up the selection 
	ELSE
		set the UPDATING, and send messages to all grobjes to
		select themselves.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnGrObjSelected	method	dynamic	ColumnClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED,
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	uses	ax,cx
	.enter

	;
	; If the object becoming selected is a text guardian, then ignore it
	;

	push	ax, cx, dx, si, di
	movdw	bxsi, cxdx
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, dx, si, di
	jc	done


	test	ds:[di].COI_state, mask COS_UPDATING
	jnz	done
	ornf	ds:[di].COI_state, mask COS_UPDATING

	mov	bx, ax				; message

	call	SeriesGetSeriesNumber		; ax <- number
	mov	cx, ax

	mov	ax, MSG_CHART_OBJECT_SELECT
	cmp	bx, MSG_CHART_OBJECT_GROBJ_SELECTED
	je	callLegend
	mov	ax, MSG_CHART_OBJECT_UNSELECT

callLegend:
	call	UtilCallLegend

	cmp	bx, MSG_CHART_OBJECT_GROBJ_SELECTED
	call	SelectOrUnselectGrObjArray
	andnf	ds:[di].COI_state, not mask COS_UPDATING
done:
	.leave
	mov	di, offset ColumnClass
	GOTO	ObjCallSuperNoLock
ColumnGrObjSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Select or unselect this column (all rectangles)

PASS:		*ds:si	= ColumnClass object
		ds:di	= ColumnClass instance data
		es	= Segment of ColumnClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnSelect	method	dynamic	ColumnClass, 
					MSG_CHART_OBJECT_SELECT,
					MSG_CHART_OBJECT_UNSELECT
	uses	dx,bp
	.enter

EC <	test	ds:[di].COI_state, mask COS_UPDATING	>
EC <	ERROR_NZ	ILLEGAL_STATE			>

	ornf	ds:[di].COI_state, mask COS_UPDATING
	mov	bx, ax
	clr	dx, bp		; don't skip any grobjs
	cmp	bx, MSG_CHART_OBJECT_SELECT
	call	SelectOrUnselectGrObjArray
	andnf	ds:[di].COI_state, not mask COS_UPDATING

	.leave
	ret
ColumnSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectOrUnselectGrObjArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select or unselect an array of grobjes

CALLED BY:	

PASS:		ZERO FLAG SET -- select
		ZERO FLAG CLEAR -- unselect

		dx:bp - grobj to compare against

		*ds:si - ChartObject

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectOrUnselectGrObjArray	proc near
	uses	ax,bx,cx,dx,di
	.enter
	mov	dl, HUM_NOW
	mov	ax, MSG_GO_BECOME_SELECTED
	jz	callGrObj
	mov	ax, MSG_GO_BECOME_UNSELECTED

callGrObj:
NOFXIP<	mov	bx, cs							>
	mov	di, offset CallGrObjCB
	mov	cx, COMT_PICTURE
	call	ChartObjectArrayEnum

	.leave
	ret
SelectOrUnselectGrObjArray	endp




if FULL_EXECUTE_IN_PLACE
ChartObjectCode	segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallGrObjCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to call a bunch of grobjes,
		except for the one whose OD matches the passed value.

CALLED BY:

PASS:		*ds:si - chunk array
		ds:di - current element
		dx:bp - OD of grobj NOT to call
		ax - message number

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallGrObjCB	proc far
	uses	si
	.enter

	mov	si, ds:[di].chunk
	mov	bx, ds:[di].handle

	; Don't select the object that started all the trouble in the
	; first place.

	cmpdw	bxsi, dxbp
	je	done

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:	

	.leave
	ret
CallGrObjCB	endp

if FULL_EXECUTE_IN_PLACE
ChartObjectCode	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnFindGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ColumnClass object
		ds:di	= ColumnClass instance data
		es	= segment of ColumnClass

RETURN:		

DESTROYED:	ax 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColumnFindGrObj	method	dynamic	ColumnClass, 
					MSG_CHART_OBJECT_FIND_GROBJ
	uses	bp
	.enter
	mov	cx, COMT_PICTURE
	clr	dx
	call	ChartObjectMultipleFindGrObjByNumber
	.leave
	ret
ColumnFindGrObj	endm

