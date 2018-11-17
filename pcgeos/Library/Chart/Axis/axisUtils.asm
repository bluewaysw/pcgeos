COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisUtils.asm

AUTHOR:		John Wedgwood, Oct 23, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/4/91		Initial Revision 

DESCRIPTION:
	Utilities for converting various numbers to PlotArea bounds
positions, etc.

TERMINOLOGY:

	Value = a floating point value 

	RelValue = a floating point value relative to axis coordinates
	  A Value is converted to a RelValue by subtracting the axis
 	  AI_MIN position

	RelPosition = a position relative to the plotBounds of the axis
	 -- in document coordinates. 

 	Position = a position in document coordinates relative to the
	  upper left-hand corner of the ChartGroup.  This is an actual
	  plottable position, RelPosition isn't.


EXAMPLE:

	Given the following Horizontal Axis:
		Min:	2
		Max:	5
		TickMajorUnit: .5
		PlotBounds (20, 50)	

	A Value of 3 would produce the following outputs:
		RelValue: 1   (3-2)
		RelPosition: 10   (RelValue)/(5-2)*(50-20)
		Position: 30 (RelPosition + 20)


	$Id: axisUtils.asm,v 1.1 97/04/04 17:45:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisTickToRelValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a tick number to a RelValue

CALLED BY:

PASS:		ds:di - axis
		bx - tick number

RETURN:		RelValue on FP stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	RelValue = tickNumber * tickMajorUnit

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 5/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisTickToRelValue	proc near	
	class	AxisClass 
	uses	ax,di
	.enter
	call	CheckForceLegal
	mov	ax, bx

	call	FloatWordToFloat
	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber
	call	FloatMultiply

	.leave
	ret
AxisTickToRelValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisValueToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a value to a position in the ChartGroup's
		coordinate system

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		Floating point number on FP stack

RETURN:		if error (value out of bounds, etc)
			carry set
		else
			carry clear 
			ax - position

		FP number removed from stack

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 4/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisValueToPosition	method	dynamic	AxisClass, 
					MSG_AXIS_VALUE_TO_POSITION
	uses	cx,dx,bp
	.enter
	call	AxisValueToPositionInt
	.leave
	ret
AxisValueToPosition	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisValueToPositionInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a floating-point number to a position relative
		to the ChartGroup coordinate system.
		Return it as an integer.

CALLED BY:	Internal

PASS:		ds:di - Axis instance data
		(Floating point number on FP stack)

RETURN:		if error
			carry set
		else
			carry clear
			ax - position

		Floating point number removed from stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Get RelPosition	
	add or subtract necessary offsets to convert to top-origin
	coordinates. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/25/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisValueToPositionInt	proc near	
	uses	dx
	.enter
	call	AxisValueToRelValue
	call	AxisRelValueToRelPosition
	call	AxisRelPositionToPositionInt
	.leave
	ret
AxisValueToPositionInt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisValueToRelValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an "absolute" value to a relative value.

CALLED BY:	AxisValueToPositionInt

PASS:		ds:di - axis instance data
		value on FP stack

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Add AI_min to value to get RelValue
	Leave RelValue on stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisValueToRelValue	proc near	
	class	AxisClass 
	uses	ax,si,di
	.enter
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	call	FloatSub
	.leave
	ret
AxisValueToRelValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisRelValueToRelPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a RelValue to a RelPosition

CALLED BY:	AxisValueToPositionInt

PASS:		RelValue on FP stack
		ds:di - Axis object

RETURN:		RelPosition on FP stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	RelPosition = RelValue * PlotDistance / (Max - Min)
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisRelValueToRelPosition	proc near	
	uses	ax,si,di
	class	AxisClass 
	.enter

	;
	; RelValue * PlotDistance
	;

	call	AxisGetPlotDistance
	call	FloatWordToFloat
	call	FloatMultiply

	; Divide by (max - min)

	lea	si, ds:[di].AI_max
	call	FloatPushNumber
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	call	FloatSub		; subtract
	

	call	FloatDivide		; 

	.leave
	ret
AxisRelValueToRelPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisRelPositionToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a RelPosition to a Position

CALLED BY:	AxisValueToPositionInt, AxisRelPositionToPositionInt

PASS:		ds:di - Axis
		FP stack: RelPosition

RETURN:		if error (RelPosition out of bounds)
			carry set
			FP Stack: --
		else
			carry clear 
			FP Stack:  Position


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If vertical axis:
 	   Positiion = axisPosition.y + plotBounds.R_bottom - RelPosition
	Else
	   Position =  axisPosition.x + plotBounds.R_left + RelPosition

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisRelPositionToPosition	proc near
	class	AxisClass 
	uses	ax,bx,cx,dx
	.enter

	call	FloatDup
	call	FloatFloatToDword	; get RelPos into AX

	;
	; RelPosition should be between 0 and the axis plot distance.
	; Otherwise, return an error
	;
	tst	ax
	js	error
	mov_tr	bx, ax
	call	AxisGetPlotDistance
	cmp	bx, ax
	ja	error

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	horizontal

	call	FloatNegate
	mov	ax, ds:[di].COI_position.P_y
	add	ax, ds:[di].AI_plotBounds.R_bottom
	jmp	doAdd

horizontal:

	mov	ax, ds:[di].AI_plotBounds.R_left
	add	ax, ds:[di].COI_position.P_x

doAdd:
	call	FloatWordToFloat		; ax -> FP stack
	call	FloatAdd
	clc
done:
	.leave
	ret

error:
	call	FloatDrop
	stc
	jmp	done
AxisRelPositionToPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisRelPositionToPositionInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a RelPosition to a Position, returning the
		value as an integer

CALLED BY:	

PASS:		FP Stack:  RelPosition

RETURN:		if error (RelPosition out of bounds)
			carry set 
		else
			carry clear
			ax - position

		In both cases, RelPosition popped of FP stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/25/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisRelPositionToPositionInt	method AxisClass,
					MSG_AXIS_REL_POSITION_TO_POSITION 
	uses	cx, dx, bp
	.enter
	call	AxisRelPositionToPosition
	jc	done
	call	FloatFloatToDword
	ECMakeSureZero	dx
	clc
done:
	.leave
	ret
AxisRelPositionToPositionInt	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlotDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get plot distance -- vertical for vertical axis,
		horiz for horiz

CALLED BY:

PASS:		ds:di - Axis object

RETURN:		ax - plot distance

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 3/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetPlotDistance	proc near	
	class	AxisClass
	.enter
	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	horizontal
	
	mov	ax, ds:[di].AI_plotBounds.R_bottom
	sub	ax, ds:[di].AI_plotBounds.R_top
	jmp	done

horizontal:

	mov	ax, ds:[di].AI_plotBounds.R_right
	sub	ax, ds:[di].AI_plotBounds.R_left

done:
	ECMakeSureNonZero	ax

	.leave
	ret
AxisGetPlotDistance	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetIntersectionPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the position on this axis at which the related
		axis intersects it.

PASS:		ds:di	= AxisClass instance data

RETURN:		ax 	= position

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	NOT DYNAMIC - must save all regs, and don't assume SI points
	to anything!

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 5/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetIntersectionPosition	method	AxisClass, 
				MSG_AXIS_GET_INTERSECTION_POSITION
	uses	si
	.enter
	lea	si, ds:[di].AI_intersect
	call	FloatPushNumber
	call	AxisValueToPositionInt
	.leave
	ret
AxisGetIntersectionPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetIntersectionRelPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the intersection RelPosition

CALLED BY:

PASS:		ds:di - axis object

RETURN:		ax - RelPosition of intersect

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	called as both a METHOD and a PROCEDURE

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetIntersectionRelPosition	method	AxisClass,
				MSG_AXIS_GET_INTERSECTION_REL_POSITION
	uses	si,dx
	.enter

	lea	si, ds:[di].AI_intersect
	call	FloatPushNumber
	call	AxisValueToRelValue
	call	AxisRelValueToRelPosition

	;
	; If there's an error for some reason, belch a warning rather
	; than an error, so that people can continue to get their work done.
	;

	call	FloatFloatToDword
	jnc	done
	clr	ax
done:
	.leave
	ret
AxisGetIntersectionRelPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetRelatedAxis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get related axis

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

RETURN:		cx - handle of related axis

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 5/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetRelatedAxis	method	dynamic	AxisClass, MSG_AXIS_GET_RELATED_AXIS
	mov	cx, ds:[di].AI_related
	ret
AxisGetRelatedAxis	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlotBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the plot bounds in ChartGroup coordinates

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

RETURN:		ax, bp, cx, dx - left, top, right, bottom

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetPlotBounds	method	dynamic	AxisClass, 
					MSG_AXIS_GET_PLOT_BOUNDS

	call	AxisGetPlotBoundsInternal
	
	mov	di, ds:[si]
	add	ax, ds:[di].COI_position.P_x
	add	cx, ds:[di].COI_position.P_x
	add	bp, ds:[di].COI_position.P_y
	add	dx, ds:[di].COI_position.P_y

	ret
AxisGetPlotBounds	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetPlotBoundsInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	get plot bounds in internal coordinates.

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

RETURN:		ax,bp,cx,dx - plot bounds

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetPlotBoundsInternal	method	AxisClass, 
					MSG_AXIS_GET_PLOT_BOUNDS_INTERNAL
	.enter

	mov	ax, ds:[di].AI_plotBounds.R_left
	mov	cx, ds:[di].AI_plotBounds.R_right
	mov	bp, ds:[di].AI_plotBounds.R_top
	mov	dx, ds:[di].AI_plotBounds.R_bottom
	.leave
	ret
AxisGetPlotBoundsInternal	endm






AxisCode	ends
