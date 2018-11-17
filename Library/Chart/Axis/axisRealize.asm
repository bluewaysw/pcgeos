COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisRealize.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	AxisDrawLine		Draw a large line down the center of the
				axis

	AxisDrawTicks		Draw the axis "ticks"

	DrawTicksCB		callback routine to draw ticks

	AddPosition		Add the position of the axis to the passed
				points

	AxisDrawTickLabels	Draw (category or value) labels for an axis

	AxisDrawTickLabelCB	Draw the current tick label

	TickEnum		Enumerate ticks

	GetTickUnitsLocal	Stick the (integer) major and minor tick
				units into the local variables structure

	TickEnumCommon		Common routine to enumerate major and/or
				minor ticks.

	CheckToSkipMinorTick	Skip whatever routine is being called for
				the current minor tick

	DrawGridLinesCB		Callback routine to draw grid lines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Code for realizing an axis.

	$Id: axisRealize.asm,v 1.1 97/04/04 17:45:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Realize an axis.

CALLED BY:	MSG_CHART_OBJECT_REALIZE

PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisRealize	method dynamic	AxisClass, MSG_CHART_OBJECT_REALIZE

	uses	ax,cx,dx,bp

	.enter

EC <	call	ECCheckAxisDSSI			>

	;
	; Create the GROUP object. Don't allow ungrouping the group
	;

	sub	sp, size CreateGrObjParams
	mov	bp, sp
	clr	ss:[bp].CGOP_flags

ifdef	SPIDER_CHART

	;
	; For spider charts only, the axis must be drawn BEFORE
	; the series data.
	;

	call	UtilGetChartAttributes
	cmp	cl, CT_SPIDER
	jnz	drawLast

	; Find the first series object, so we can put the axes
	; before it in draw order

	push	si
	clr	cx
	mov	si, offset TemplateSeriesGroup
	mov	ax, MSG_SERIES_GROUP_FIND_SERIES_BY_NUMBER
	call	ObjCallInstanceNoLock		; *ds:ax - series

	mov_tr	si, ax
	mov	ax, MSG_CHART_OBJECT_FIND_GROBJ
	call	ObjCallInstanceNoLock		; ^lcx:dx - grobj for series
	mov	ax, GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	jcxz	gotPosition

	mov	ax, MSG_GB_FIND_GROBJ
	call	UtilCallChartBody		; cx - draw order
	mov	ax, cx
	ornf	ax, mask GOBAGOF_DRAW_LIST_POSITION

gotPosition:
	pop	si

	mov	ss:[bp].CGOP_flags, mask CGOF_DRAW_ORDER
	mov	ss:[bp].CGOP_drawOrder, ax

drawLast:

endif	; SPIDER_CHART

	movP	ss:[bp].CGOP_position, ds:[di].COI_position, ax
	movP	ss:[bp].CGOP_size, ds:[di].COI_size, ax
	mov	ss:[bp].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS or \
				mask	GOL_UNGROUP 

	movOD	ds:[di].COI_grobj, ds:[di].AI_group, ax
	call	ChartObjectCreateOrUpdateGroup
	DerefChartObject ds, si, di 
	movOD	ds:[di].AI_group, ds:[di].COI_grobj, ax

	add	sp, size CreateGrObjParams


	mov	cx, COMT_PICTURE
	clr	dx
	call	ChartObjectMultipleGetGrObj

	; create a gstring

	call	ChartObjectCreateGString
	push	ax			; VMem handle

	; Draw horizontal (vertical) line
	;
	call	AxisDrawLine

	;
	; Draw the ticks
	;

	call	AxisDrawTicks

	mov	di, bp	
	pop	cx			; VM handle of gstring data

	sub	sp, size CreateGStringParams
	mov	bp, sp
	
	mov	ss:[bp].CGOP_flags, mask CGOF_ADD_TO_GROUP
	mov	ss:[bp].CGSP_gstring, di
	mov	ss:[bp].CGSP_vmBlock, cx
	call	AxisSetGroupInfo
	call	ChartObjectCreateOrUpdateGStringGrObj

	add	sp, size CreateGStringParams

	mov	cx, COMT_PICTURE
	clr	dx
	call	ChartObjectMultipleSetGrObj

	;
	; Draw (category or value) labels
	;

	call	AxisDrawTickLabels

	call	UtilGetChartAttributes

ifdef	SPIDER_CHART
	; Spider charts have no category axis.
	; If category titles are present, draw them now.

	cmp	cl, CT_SPIDER
	jnz	notSpider
	call	DrawSpiderCategoryTitles
notSpider:
endif	;SPIDER_CHART

	.leave
	mov	di, offset AxisClass
	GOTO	ObjCallSuperNoLock
AxisRealize	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisSetGroupInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store information necessary for adding this object to
		a group

CALLED BY:	AxisRealize, AxisDrawTickLabels

PASS:		ss:bp - CreateGrObjParams
		*ds:si - axis object

RETURN:		ds:di - axis object (dereferenced)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisSetGroupInfo	proc near
	uses	ax,bx
	class	AxisClass 
	.enter

	DerefChartObject ds, si, di
	movOD	ss:[bp].CGOP_group, ds:[di].AI_group, ax
	movP	axbx, ds:[di].COI_size
	shr	ax
	shr	bx
	addP	axbx, ds:[di].COI_position
	movP	ss:[bp].CGOP_groupCenter, axbx

	.leave
	ret
AxisSetGroupInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a large line down the center of the axis

CALLED BY:

PASS:		ds:di - Axis object
		bp - gstate handle

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisDrawLine	proc near	
	uses 	ax,bx,cx,dx,di
	class	AxisClass
	.enter

	mov	ax, ds:[di].AI_plotBounds.R_left
	mov	cx, ds:[di].AI_plotBounds.R_right

	mov	bx, ds:[di].AI_plotBounds.R_top
	mov	dx, ds:[di].AI_plotBounds.R_bottom

	call	AddPosition

ifdef	SPIDER_CHART
	tst	ds:[di].AI_related		;Only Spider Charts have
	jnz	draw				;no related axis.
						;Should probably be
						;changed to explicitly
						;check type.
	call	AxisDrawSpiderLines
draw:
endif	;SPIDER_CHART

	mov	di, bp
	call	GrDrawLine
	.leave
	ret
AxisDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawTicks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the axis "ticks"

CALLED BY:	AxisRealize

PASS:		ds:di - Axis object
		bp - gstate handle

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	CDB	11/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisDrawTicks	proc near	
	class	AxisClass
	uses	ax,bx
locals	local	TickEnumVars
	mov	bx, bp		; put this before the .enter
	.enter 	
	mov	locals.TEV_gstate, bx
	mov	locals.TEV_callback, offset DrawTicksCB

ifdef	SPIDER_CHART
	tst	ds:[di].AI_related			; Hack - only
	jnz	callBackSet				; Spider
	mov	locals.TEV_callback, offset DrawSpiderTicksCB
							; charts have
							; no related
							; axis.

callBackSet:
endif	;SPIDER_CHART

	mov	al, ds:[di].AI_tickAttr
	mov	locals.TEV_flags, al
	call	TickEnum
	.leave
	ret
AxisDrawTicks	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTicksCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to draw ticks

CALLED BY:	AxisDrawTicks via TickEnum

PASS:		ss:bp - TickEnumVars 
		ax - position of current tick

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTicksCB	proc near	
	uses	ax,bx,cx,dx,di
locals	local	TickEnumVars
	class	AxisClass 
	.enter 	inherit 

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	horizontal

	; Vertical axis -- horizontal ticks!
	
	mov	bx, ax			; y-position
	mov	dx, ax
	mov	cx, ds:[di].COI_position.P_x
	add	cx, ds:[di].COI_size.P_x
	mov	ax, cx
	sub	ax, AXIS_STANDARD_AXIS_WIDTH

	; Make minor ticks smaller, for Mariko

	test	ss:[locals].TEV_flags, mask TEF_CURRENT_IS_MAJOR
	jnz	drawIt
	add	ax, AXIS_LEFT_WIDTH
	sub	cx, AXIS_LEFT_WIDTH/2
	jmp	drawIt

horizontal:

	mov	cx, ax
	mov	bx, ds:[di].COI_position.P_y
	mov	dx, bx
	add	dx, AXIS_STANDARD_AXIS_HEIGHT

	; Make minor ticks smaller

	test	ss:[locals].TEV_flags, mask TEF_CURRENT_IS_MAJOR
	jnz	drawIt
	add	bx, AXIS_ABOVE_HEIGHT/2
	sub	dx, AXIS_ABOVE_HEIGHT

drawIt:
	mov	di, locals.TEV_gstate
	call	GrDrawLine
	.leave
	ret
DrawTicksCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the position of the axis to the passed points

CALLED BY:	DrawTicksCB

PASS:		ax,bx,cx,dx - 2 coordinate pairs
		ds:di - axis object

RETURN:		ax,bx,cx,dx - with position added

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPosition	proc near
	class	AxisClass 
	.enter
	addP	axbx, ds:[di].COI_position
	addP	cxdx, ds:[di].COI_position
	.leave
	ret
AddPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawTickLabels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw (category or value) labels for an axis

CALLED BY:	AxisRealize

PASS:		ds:di - axis object
		*ds:si = axis object

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Save registers destroyed by callback routine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 2/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisDrawTickLabels	proc near	
	uses ax,bx,cx,dx
	class	AxisClass 

locals	local	TickEnumVars

	.enter

	DerefChartObject ds, si, di

	clr	dx			; assume no labels
	test	ds:[di].AI_tickAttr, mask ATA_LABELS
	jz	removeExtras


	;
	; Fetch the attributes of the first text object, and use it in
	; all subsequent ones.  NOTE:  if there's no first text
	; object, we'll just be fetching attrs from the GOAM text,
	; which is kind of redundant, but it would be more coding to
	; check for that case, so...
	;

	lea	ax, locals.TEV_charAttr
	mov	locals.TEV_ctp.CTP_charAttr, ax
	lea	ax, locals.TEV_paraAttr
	mov	locals.TEV_ctp.CTP_paraAttr, ax

	push	si			; Axis

	mov	ax, MSG_CHART_OBJECT_GET_GROBJ_TEXT
	call	ObjCallInstanceNoLock	; ^lcx:dx - grobj text
	movOD	bxsi, cxdx

	lea	di, locals.TEV_charAttr
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	call	getAttr

	lea	di, locals.TEV_paraAttr
	mov	ax, MSG_VIS_TEXT_GET_PARA_ATTR
	call	getAttr


	pop	si			; Axis

	;
	; Well, I lied -- we DO want to know if there're any
	; preexisting text objects.  If there are, then we just pass
	; the structures as is.  If not, then we adjust the paragraph
	; attributes so that the text is right-justified.
	;
	; The array's chunk handle is stored at COMI_array2 -- just
	; check whether the array exists or not -- this should be safe
	; enough. 

	DerefChartObject ds, si, di
	tst	ds:[di].COMI_array2
	jnz	gotAttrs

	mov	ax, locals.TEV_paraAttr.VTPA_attributes
	andnf	ax, not mask VTPAA_JUSTIFICATION
	ornf	ax, (J_CENTER shl offset VTPAA_JUSTIFICATION)
	mov	locals.TEV_paraAttr.VTPA_attributes, ax

gotAttrs:


	;
	; Set the ROTATED bit properly. -- only for vertical category axis
	;

	mov	cx, mask CGOF_ADD_TO_GROUP
	mov	al, ds:[di].AI_attr
	test	al, mask AA_VERTICAL 
	jz	setFlags
	test	al, mask AA_VALUE
	jnz	setFlags
	ornf	cx, mask CGOF_ROTATED

setFlags:
	mov	locals.TEV_ctp.CTP_common.CGOP_flags, cx

	push	bp
	lea	bp, locals.TEV_ctp
	call	AxisSetGroupInfo
	pop	bp


	mov	locals.TEV_callback, offset AxisDrawTickLabelCB
	mov	locals.TEV_flags, mask TEF_MAJOR
	call	TickEnum

	;
	; remove any extras lying around...
	;

	mov	dx, ds:[di].AI_numLabels

removeExtras:

	mov	cx, COMT_TEXT
	call	ChartObjectRemoveExtraGrObjs

	.leave
	ret

getAttr:

	;
	; Fill in the attr structure pointed to by ss:di
	;	message is in AX
	;

	push	bp, bx, si
	mov	dx, size VisTextGetAttrParams
	sub	sp, dx
	mov	bp, sp
	clrdw	ss:[bp].VTGAP_range.VTR_start
	movdw	ss:[bp].VTGAP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTGAP_attr.segment, ss
	mov	ss:[bp].VTGAP_attr.offset, di
	mov	ss:[bp].VTGAP_return.segment, ss
	mov	ss:[bp].VTGAP_return.offset, di
	clr	ss:[bp].VTGAP_flags
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size VisTextGetAttrParams
	pop	bp, bx, si
	retn
	
AxisDrawTickLabels	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawTickLabelCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current tick label

CALLED BY:	TickEnum

PASS:		*ds:si - axis instance
		ax - current tick position
		cx - current label #
		ss:bp - TickEnumVars

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 2/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisDrawTickLabelCB	proc near	
	class	AxisClass
	uses	es, di

locals	local	TickEnumVars
	.enter	inherit

	sub	sp, CHART_TEXT_BUFFER_SIZE

	segmov	es, ss, di
	mov	di, sp

	mov	locals.TEV_ctp.CTP_text.segment, ss
	mov	locals.TEV_ctp.CTP_text.offset, di

	mov	bx, cx			; label #
	call	AxisGetLabel
	LONG	jc done

	push	cx			; label #
	mov	dx, cx			
	mov	cx, COMT_TEXT
	call	ChartObjectMultipleGetGrObj
	
	DerefChartObject ds, si, di 
	
	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical

	;
	; Horizontal:
	;

	test	ds:[di].AI_attr, mask AA_VALUE
	jz	horizontalCategory


	; HORIZONTAL VALUE AXIS
	; 	left = tick - 1/2 maxLabelSize.P_x
	; 	right = tick + 1/2 maxLabelSize.P_x

	mov	bx, ds:[di].AI_maxLabelSize.P_x
	shr	bx
	mov	cx, ax
	add	cx, bx
	sub	ax, bx
	jmp	setTopBottomForHorizontalAxis

horizontalCategory:

	; left = tick
	; right = tick + tickMajorUnit

	mov	cx, ax
	add	cx, locals.TEV_tickMajorUnit

setTopBottomForHorizontalAxis:
	mov	bx, ds:[di].AI_plotBounds.R_top
	add	bx, AXIS_ABOVE_HEIGHT
	add	bx, ds:[di].COI_position.P_y
	mov	dx, bx
	add	dx, ds:[di].AI_maxLabelSize.P_y
	jmp	drawIt

vertical:

	test	ds:[di].AI_attr, mask AA_VALUE
	jz	verticalCategory
	
	; VERTICAL VALUE AXIS:
	; top = tick - 1/2 maxLabelSize.P_y
	; bottom = tick + 1/2 maxLabelSize.P_y

	mov	bx, ax				; tick position
	mov	dx, bx
	mov	ax, ds:[di].AI_maxLabelSize.P_y
	shr	ax
	sub	bx, ax
	add	dx, ax
	jmp	setLeftRightForVerticalAxis

verticalCategory:
	; top = tick - tickMajorUnit
	; bottom = tick

	mov	dx, ax
	mov	bx, dx
	sub	bx, locals.TEV_tickMajorUnit

setLeftRightForVerticalAxis:

	; Set the left/right bounds for the vertical axis

	mov	cx, ds:[di].AI_plotBounds.R_left
	sub	cx, AXIS_LEFT_WIDTH
	add	cx, ds:[di].COI_position.P_x
	mov	ax, cx
	sub	ax, ds:[di].AI_maxLabelSize.P_x

drawIt:

	movP	locals.TEV_ctp.CTP_common.CGOP_position, axbx


	sub	cx, ax
	sub	dx, bx
	movP	locals.TEV_ctp.CTP_common.CGOP_size, cxdx

	;
	; The locks are the same as normal, except this object CAN be
	; grouped, but it CAN'T be ungrouped.  Also, set the ATTR bit,
	; as this prevents grobj (line) attributes from being set, but
	; seems to allow text attributes through.  (this is a bug, but
	; it's a good bug :)
	;

	mov	locals.TEV_ctp.CTP_common.CGOP_locks,
			STANDARD_CHART_GROBJ_LOCKS and \
			(not mask GOL_GROUP) or mask GOL_UNGROUP or \
			mask GOL_ATTRIBUTE


	mov	locals.TEV_ctp.CTP_flags, mask CTF_MAX_HEIGHT or \
				mask CTF_USE_CHAR_AND_PARA_ATTRS 


	push	bp
	lea	bp, locals.TEV_ctp
	call	ChartObjectCreateOrUpdateText
	pop	bp

	mov	cx, COMT_TEXT
	pop	dx			; label #
	call	ChartObjectMultipleSetGrObj

done:
	add	sp, CHART_TEXT_BUFFER_SIZE
	.leave
	ret
AxisDrawTickLabelCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDrawGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw grid lines 

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		cl 	= GridFlags
		bp	= gstate handle

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack <offset GF_MINOR_Y eq offset TEF_MINOR>
CheckHack <offset GF_MAJOR_Y eq offset TEF_MAJOR>
CheckHack <offset GF_MINOR_X eq offset TEF_MINOR+2>
CheckHack <offset GF_MAJOR_X eq offset TEF_MAJOR+2>

AxisDrawGridLines	method	dynamic	AxisClass, 
					MSG_AXIS_DRAW_GRID_LINES
	mov	bx, bp
locals	local	TickEnumVars
	.enter

	; Want to convert the passed GridFlags record to
	; TickEnumFlags.  For vertical axis, this is easy -- the
	; necessary flags are already in place.  For horizontal axis,
	; shift right by 2.

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	gotFlags
	shr	cl, 1
	shr	cl, 1
gotFlags:
	mov	locals.TEV_flags, cl

	mov	locals.TEV_gstate, bx
	mov	locals.TEV_callback, offset DrawGridLinesCB

	; get related axis' plot bounds

	push	bp, si
	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS
	mov	si, ds:[di].AI_related
	call	ObjCallInstanceNoLock
	mov	bx, bp
	pop	bp, si

	mov	locals.TEV_relatedPlotBounds.R_left, ax
	mov	locals.TEV_relatedPlotBounds.R_top, bx
	mov	locals.TEV_relatedPlotBounds.R_right, cx
	mov	locals.TEV_relatedPlotBounds.R_bottom, dx

	call	TickEnum
	.leave
	ret
AxisDrawGridLines	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate ticks

CALLED BY:

PASS:		ss:bp - TickEnumVars 
		CALLER MUST FILL IN:
			TEV_callback
			TEV_flags (TickEnumFlags)

		*ds:si - axis object

	CALLBACK:
		PASS:
			*ds:si - Axis object
			cx - tick #
			ax - tick position

		RETURN:
			nothing 

		CAN DESTROY:
			ax,bx,cx,dx,di

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Use the TickEnumFlags to decide whether to enumerate major,
	minor, or both

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickEnum	proc near	
	class	AxisClass 
locals	local	TickEnumVars
	.enter 	inherit 

EC <	call	ECCheckAxisDSSI			>

	mov	di, ds:[si]
	push	si

	; Put the major tick unit into the local frame

	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber
	call	AxisRelValueToRelPosition
	call	FloatFloatToDword
	ECMakeSureZero	dx
	mov	locals.TEV_tickMajorUnit, ax

	; put the minor tick unit into the frame

	lea	si, ds:[di].AI_tickMinorUnit
	call	FloatPushNumber
	call	AxisRelValueToRelPosition
	call	FloatFloatToDword
	ECMakeSureZero	dx
	mov	locals.TEV_tickMinorUnit, ax
	pop	si

	; Now, enumerate the desired type of ticks

	test	locals.TEV_flags, mask TEF_MAJOR
	jz	minor
	ornf	locals.TEV_flags, mask TEF_CURRENT_IS_MAJOR

	lea	bx, ds:[di].AI_tickMajorUnit
	call	TickEnumCommon

minor:
	test	locals.TEV_flags, mask TEF_MINOR
	jz	done
	andnf	locals.TEV_flags, not mask TEF_CURRENT_IS_MAJOR
	
	lea	bx, ds:[di].AI_tickMinorUnit
	call	TickEnumCommon
done:
	.leave
	ret
TickEnum	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickEnumCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to enumerate major ticks, minor ticks,
		or both.

CALLED BY:

PASS:		*ds:si - axis object
		ds:bx - tick unit (either major or minor)
		ss:bp - TickEnumVars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickEnumCommon	proc near	
	uses	ax,bx,cx,dx,di,si
	class	AxisClass
locals	local	TickEnumVars
	.enter 	inherit 

EC <	call	ECCheckAxisDSSI		>

	;
	; Calculate the number of iterations.  Assumes iterating over
	; major axis.
	;
	mov	di, ds:[si]
	mov	dx, ds:[di].AI_numLabels	; dx = num major ticks
	test	locals.TEV_flags, mask TEF_CURRENT_IS_MAJOR
	jnz	gotLoopCount			; jmp if currently major
	test	locals.TEV_flags, mask TEF_MINOR
	jz	gotLoopCount			; jmp if don't enum minor
	;
	; Get minor tick counts
	;
	call	ComputeNumMinorTicks		; dx = num minor ticks
gotLoopCount:

	; push (passed) tick unit on stack

	push	si
	mov	si, bx		
	call	FloatPushNumber			; FP: incr
	call	AxisRelValueToRelPosition

	call	Float0
	call	AxisRelValueToRelPosition	; FP: incr cur
	pop	si				; axis chunk handle

	clr	cx				; current tick #
startLoop:
	push	cx				; current tick #

	mov	di, ds:[si] 
	call	CheckToSkipMinorTick
	jc	afterCallback

	call	FloatDup			; FP: incr cur cur

	call	AxisRelPositionToPosition  	; FP: incr cur cur(P)

	push	dx				; save number of labels
	call	FloatFloatToDword
	ECMakeSureZero dx

	; call callback routine

	call	locals.TEV_callback
	pop	dx

afterCallback:
	mov	bx, 2
	call	FloatPick			; FP <= incr cur incr
	call	FloatAdd			; FP <= incr (newCur)
	pop	cx				; tick #
	inc	cx
	cmp	cx, dx				; dx = num labels
	jb	startLoop

	call	FloatDrop
	call	FloatDrop

	.leave
	ret
TickEnumCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckToSkipMinorTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip whatever routine is being called for the current
		minor tick

CALLED BY:

PASS:		*ds:si - Axis object
		FP stack:  end incr cur

RETURN:		carry set to skip

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If we're enumerating both MAJOR and MINOR ticks,
	divide current relPosition by AI_majorTickUnit,
	if remainder is close to zero, then its a perfect multiple,
	so don't draw it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckToSkipMinorTick	proc near	
	uses	ax,bx,dx
	class	AxisClass 
locals	local	TickEnumVars
	.enter 	inherit 

	; If we're CURRENTLY enumerating major ticks, or we're not
	; enumerating major ticks at all, then done.
	
	test	locals.TEV_flags, mask TEF_CURRENT_IS_MAJOR
	jnz	done
	test	locals.TEV_flags, mask TEF_MAJOR
	jz	done
		
	call	FloatDup		; FP: end incr cur cur
	call	FloatFloatToDword
	ECMakeSureZero	dx		; ax - current RelPos

	adddw	dxax, SKIP_MINOR_TOLERANCE/2

	mov	bx, locals.TEV_tickMajorUnit
	div	bx
	
	cmp	dx, SKIP_MINOR_TOLERANCE
	jle	skip
	; carry is clear here!

done:
	.leave
	ret
skip:
	stc
	jmp	done
CheckToSkipMinorTick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGridLinesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to draw grid lines

CALLED BY:	AxisDrawGridLines via TickEnum

PASS:		ds:di - axis object
		cl - GridFlags
		ax - position along axis at which to draw
		ss:bp - TickEnumVars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGridLinesCB	proc near	

	class	AxisClass 
	uses	ax,bx,cx,dx,di 
locals	local	TickEnumVars
	.enter 	inherit

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical
	mov	cx, ax
	mov	bx, locals.TEV_relatedPlotBounds.R_top
	mov	dx, locals.TEV_relatedPlotBounds.R_bottom
	jmp	drawIt

vertical:
	mov	bx, ax
	mov	dx, ax
	mov	ax, locals.TEV_relatedPlotBounds.R_left
	mov	cx, locals.TEV_relatedPlotBounds.R_right
drawIt:
	mov	di, locals.TEV_gstate
	call	GrDrawLine
	jmp	done

done:
	.leave
	ret
DrawGridLinesCB	endp

  
