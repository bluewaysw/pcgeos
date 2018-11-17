COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisCategory.asm

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
	CDB	12/12/91	Initial version.

DESCRIPTION:
	

	$Id: axisCategory.asm,v 1.1 97/04/04 17:45:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a category axis

CALLED BY:	MSG_CHART_OBJECT_BUILD
PASS:		*ds:si	= Category Axis object
		ds:di	= instance data
		cl - ChartType
		ch - ChartVariation
		dx - ChartFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For a category axis set a few things:
	   	tickMajorUnit = 1
	   	tickMajorUnit = 0.5
	   	minimum = 0
	   	maximum = nCategories

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CategoryAxisBuild	method	dynamic	CategoryAxisClass,
						MSG_CHART_OBJECT_BUILD
	uses	ax,cx,dx,bp
	.enter

	call	CategoryAxisChooseDefaultValues

	mov	ds:[di].AI_tickAttr, mask ATA_MAJOR_TICKS or \
				mask ATA_LABELS

	clr	al
	test	dx, mask CF_CATEGORY_MARGIN
	jz	gotMarginAmount
	mov	al, AXIS_CATEGORY_MARGIN

gotMarginAmount:
	; Set category margin
	mov	ds:[di].CAI_margin, al

	.leave
	mov	di, offset CategoryAxisClass
	GOTO	ObjCallSuperNoLock
CategoryAxisBuild	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisChooseDefaultValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Choose default values for category axis

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CategoryAxisChooseDefaultValues	proc	near
	uses	ax,bx,cx,dx,ds,es,si,di
	class	CategoryAxisClass
	.enter

	;
	; Compute nCategories
	;
	push	si				; chunk handle
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock		; cx <- # of categories
	pop	si

	; store # labels in instance data
	mov	bx, offset AI_numLabels
	call	AxisStoreWordSetState

	mov	ax, cx
	call	FloatWordToFloat		; Convert to a float number

	mov	bx, di
	; Store nCategories as MAX value
	segmov	es, ds, di
	lea	di, ds:[bx].AI_max
	call	FloatPopNumber

	; Store 0 as MIN value
	lea	di, ds:[bx].AI_min
	clr	ax
	mov	cx, size FloatNum/2
	rep	stosw

	; set tick major unit = 1
	segmov	ds, cs, si
	lea	si, cs:[float1]
	lea	di, ds:[bx].AI_tickMajorUnit
	MovMem	<size FloatNum>

	; tick minor unit = .5
	lea	si, cs:[floatHalf]
	lea	di, ds:[bx].AI_tickMinorUnit
	MovMem	<size FloatNum>

	.leave
	ret
CategoryAxisChooseDefaultValues	endp

float1		FloatNum	<0,0,0,0x8000,<0,0x3fff>>
floatHalf	FloatNum	<0,0,0,0x8000,<0,0x3ffe>>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisStoreWordSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a word in the instance data.  Set the IMAGE and
		GEOMETRY flags if the value changes

CALLED BY:

PASS:		ds:[di][bx] - location to store
		*ds:si - axis object
		cx - value to store

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisStoreWordSetState	proc near
	uses	cx
	.enter
	cmp	cx, ds:[di][bx]
	je	done
	mov	ds:[di][bx], cx
 	mov	cx, mask COS_IMAGE_INVALID or \
 			mask COS_GEOMETRY_INVALID
 	call	ChartObjectSetState

done:
	.leave
	ret
AxisStoreWordSetState	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Perform "part 1" of the geometry calculations

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

		cx, dx - suggested size

RETURN:		cx, dx - desired size

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CategoryAxisRecalcSize	method	dynamic	CategoryAxisClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax

axisSize	local	Point	push	dx, cx

	.enter

	call	CategoryAxisComputeMaxLabelSizePart1

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical

	; Horizontal Axis:  Set size
	; WIDTH = max(passed x, AXIS_MIN_PLOT_DISTANCE)

	Max	cx, AXIS_MIN_PLOT_DISTANCE
	mov	axisSize.P_x, cx

	; HEIGHT = AXIS_STANDARD_AXIS_HEIGHT + max Label height

	mov	ax, ds:[di].AI_maxLabelSize.P_y
	add	ax, AXIS_STANDARD_AXIS_HEIGHT
	mov	axisSize.P_y, ax

	; Make initial stab at plot bounds

	mov	ds:[di].AI_plotBounds.R_top, AXIS_ABOVE_HEIGHT
	mov	ds:[di].AI_plotBounds.R_bottom, AXIS_ABOVE_HEIGHT
	mov	ds:[di].AI_plotBounds.R_left, 0
	mov	ds:[di].AI_plotBounds.R_right, cx
	jmp	done

vertical:

	; Set size.  
	; HEIGHT = max(passed height, AXIS_MIN_PLOT_DISTANCE)

	Max	dx, AXIS_MIN_PLOT_DISTANCE
	mov	axisSize.P_y, dx

	; WIDTH = max label width + standard axis width

	mov	ax, ds:[di].AI_maxLabelSize.P_x
	mov	bx, ax
	add	bx, AXIS_STANDARD_AXIS_WIDTH
	mov	axisSize.P_x, bx

	; Make initial stab at plot bounds

	mov	ds:[di].AI_plotBounds.R_top, 0
	mov	ds:[di].AI_plotBounds.R_bottom, dx
	add	ax, AXIS_LEFT_WIDTH + 1		; max label size
	mov	ds:[di].AI_plotBounds.R_left, ax
	mov	ds:[di].AI_plotBounds.R_right, ax

done:
	movP	cxdx, axisSize
	.leave
	mov	di, offset CategoryAxisClass
	GOTO	ObjCallSuperNoLock
CategoryAxisRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisComputeMaxLabelSizePart1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the initial guess at the max label size

CALLED BY:	CategoryAxisRecalcSize

PASS:		*ds:si - category axis

RETURN:		nothing -- AI_maxLabelSize fields filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	VERTICAL AXIS:
		width = text size

	HORIZONTAL AXIS:
		height = text size


	Can't set the other value until later.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CategoryAxisComputeMaxLabelSizePart1	proc near
		uses	ax,bx,cx,dx,di
		class	CategoryAxisClass

		.enter

	;
	; Make sure there are labels to be displayed!
	;
		
		mov	ax, MSG_CHART_GROUP_GET_DATA_ATTRIBUTES
		call	UtilCallChartGroup
		test	al, mask CDA_HAS_CATEGORY_TITLES
		jz	noLabelSize


		DerefChartObject ds, si, di 
		test	ds:[di].AI_tickAttr, mask ATA_LABELS
		jz	noLabelSize

		call	UtilGetTextLineHeight
		clr	bx
	;
	; AX - height
	; bx - width
	; (for horizontal axis)
	;

		test	ds:[di].AI_attr, mask AA_VERTICAL
		jnz	setValues

		xchg	ax, bx

setValues:
		mov	ds:[di].AI_maxLabelSize.P_x, ax
		mov	ds:[di].AI_maxLabelSize.P_y, bx
		.leave
		ret

noLabelSize:
		clr	ax, bx
		jmp	setValues

CategoryAxisComputeMaxLabelSizePart1	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisGeometryPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Do the final geometry calculations for a category
		axis. 

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CategoryAxisGeometryPart2	method	dynamic	CategoryAxisClass, 
					MSG_AXIS_GEOMETRY_PART_2
	uses	ax,cx,dx,bp
	.enter

	; call superclass to adjust plot bounds based on related axis.

	mov	di, offset CategoryAxisClass
	call	ObjCallSuperNoLock

	;
	; Now that we've got the plot bounds of the axis (which
	; were adjusted based on the size of the related axis),
	; re-calculate the maximum width of the labels for the
	; horizontal axis. (height for vertical axis).
	;

	push	si
	DerefChartObject ds, si, di 
	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber
	pop	si

	call	AxisRelValueToRelPosition	
	call	FloatFloatToDword		; ax <- major unit
	ECMakeSureZero	dx
	
	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	horizontal

	mov	ds:[di].AI_maxLabelSize.P_y, ax
	jmp	done

horizontal:
	mov	ds:[di].AI_maxLabelSize.P_x, ax

done:
	.leave
	ret
CategoryAxisGeometryPart2	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisGetValuePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

		dx 	= category number

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CategoryAxisGetValuePosition	method	dynamic	CategoryAxisClass, 
					MSG_AXIS_GET_VALUE_POSITION
	ERROR	-1
	; caller should be using
	; MSG_CATEGORY_AXIS_GET_CATEGORY_POSITION instead
CategoryAxisGetValuePosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisGetCategoryPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

		dx 	= category number

RETURN:		FP stack:  position

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CategoryAxisGetCategoryPosition	method	dynamic	CategoryAxisClass, 
				MSG_CATEGORY_AXIS_GET_CATEGORY_POSITION
	.enter
	mov	bx, dx
	call	AxisTickToRelValue

	lea	si, ds:[di].AI_tickMinorUnit
	call	FloatPushNumber
	call	FloatAdd

	call	AxisRelValueToRelPosition
	call	AxisRelPositionToPosition

	.leave
	ret
CategoryAxisGetCategoryPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CategoryAxisGetCategoryWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= CategoryAxisClass object
		ds:di	= CategoryAxisClass instance data
		es	= Segment of CategoryAxisClass.

RETURN:		FP STACK: category width

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CategoryAxisGetCategoryWidth	method	dynamic	CategoryAxisClass, 
					MSG_CATEGORY_AXIS_GET_CATEGORY_WIDTH
	uses	ax,cx,dx,bp
	.enter

	; stick total plot distance on the fp stack

	call	AxisGetPlotDistance
	call	FloatWordToFloat

	; get number of categoryes

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
	mov	ax, cx
	call	FloatWordToFloat
	call	FloatDivide
	call	FloatDup		; FP: width width

	mov	al, ds:[di].CAI_margin
	call	FloatPushPercent
	call	FloatMultiply		; FP: width width*margin
	call	FloatSub		; FP: width-width*margin
	.leave
	ret
CategoryAxisGetCategoryWidth	endm




AxisCode	ends



