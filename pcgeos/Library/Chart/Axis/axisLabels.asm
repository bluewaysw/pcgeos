COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisLabels.asm

AUTHOR:		John Wedgwood, Oct 23, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/23/91	Initial revision

DESCRIPTION:
	Utility routines for processing axis labels.

	$Id: axisLabels.asm,v 1.1 97/04/04 17:45:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text of a label for an axis.

CALLED BY:	AxisForeachLabel
PASS:		*ds:si	= Axis instance
		bx	= Label number
		es:di	= Buffer to put the label text into
RETURN:		carry set if the label requested is beyond the legal range.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are two possibilities here:
	    Category axis:
		Get the label from the data buffer stored with the Chart Group.
	    Value axis:
	    	Compute the label ourselves...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	When the label requested is beyond the legal range, the text for the
	last label is placed in the buffer.

	This allows you do write code like:
		mov	bx, -1
		call	AxisGetLabel		; Get text for last label

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetLabel	proc	near
	class	AxisClass
	uses	ax, cx, si
	.enter
	call	CheckForceLegal			; Force request legal

	mov	si, ds:[si]			; ds:si <- instance ptr

	pushf					; Save "out of bounds" flag

	test	ds:[si].AI_attr, mask AA_VALUE
	jz	category
	call	GetValueLabel
	jmp	afterCall
category:
	call 	GetCategoryLabel
afterCall:
	popf					; Restore "out of bounds" flag
	.leave
	ret
AxisGetLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForceLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a label request is legal and force it to be ok.

CALLED BY:	AxisGetLabel
PASS:		*ds:si	= Axis instance
		bx	= Label number
RETURN:		bx	= Legal label number
		carry set if the requested label isn't legal.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Valid label numbers are in the range (0 .. numLabels-1)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/91	Initial version
	cdb	12/3/91		removed floating point

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForceLegal	proc	near
	class	AxisClass
	uses	ax, cx, di, si
	.enter
	mov	di, ds:[si]
	mov	ax, ds:[di].AI_numLabels
	cmp	ax, bx
	ja	ok				; carry clear if
						; branch taken.
	mov	bx, ax
	dec	bx
	stc		

ok:	
	.leave
	ret

CheckForceLegal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetValueLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for a value label.

CALLED BY:	AxisGetLabel
PASS:		ds:si	= Axis instance
		es:di	= Buffer to put text into
		bx	= Label number
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The expression is:
		labelNum * tickMajor + axisMin

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetValueLabel	proc	near
	class	AxisClass
	uses	ax, bx, cx, dx, si
	.enter
	push	di				; Save buffer ptr
	mov	di, si				; ds:di <- instance ptr

	;
	; Push label number.
	;
	mov	ax, bx
	call	FloatWordToFloat

	;
	; Push major tick unit.
	;
	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber

	call	FloatMultiply		
	
	;
	; Push axisMin.
	;
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	
	call	FloatAdd
	
	pop	di				; Restore buffer ptr
	;
	; Convert result (on fp stack) into text in the buffer.
	;
	; es:di	= Destination buffer
	;
	call	AxisFloatToAscii
	.leave
	ret
GetValueLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCategoryLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a category axis label.

CALLED BY:	AxisGetLabel
PASS:		ds:si	= Instance ptr
		es:di	= Buffer for label
		bx	= Label number
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Get the label from the parameters block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCategoryLabel	proc	near
	uses	ax, cx, dx, bp, si
	.enter
	mov	dx, es				; dx:bp <- ptr to buffer
	mov	bp, di
	
	mov	cx, bx				; cx <- category number

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock		; Fill the buffer
	.leave
	ret
GetCategoryLabel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisFloatToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a floating point number to ascii

CALLED BY:

PASS:		ds - segment of axis object
		es:di - buffer in which to store text data
		FP stack: number to convert

RETURN:		es:di - buffer filled in, number popped off stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisFloatToAscii	proc near	
	uses	ax,bx,dx
	.enter
	mov	ax, mask FFAF_USE_COMMAS or mask FFAF_NO_TRAIL_ZEROS

	call	UtilGetChartAttributes
	test	dx, mask CF_PERCENT
	jz	gotFlags
	ornf	ax, mask FFAF_PERCENT
gotFlags:
	mov	bh, MAX_DIGITS
	mov	bl, DECIMAL_DIGITS
	call	FloatFloatToAscii_StdFormat	; Do the conversion

	.leave
	ret
AxisFloatToAscii	endp



AxisCode	ends
