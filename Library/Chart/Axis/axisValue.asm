COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		chart library
FILE:		axisValue.asm

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
	

	$Id: axisValue.asm,v 1.1 97/04/04 17:45:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisGetValuePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the position (in PlotArea bounds) of a number
		in the parameters block

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.
		cx 	= series #
		dx	= category #

RETURN:		if value exists:
			ax 	= position (either X or Y) of number
			carry clear
		else
			carry set -- that position is EMPTY
			

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 4/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ValueAxisGetValuePosition	method	dynamic	AxisClass, 
					MSG_AXIS_GET_VALUE_POSITION
	uses	cx, dx, bp
	.enter
	push	si
	mov	ax, MSG_CHART_GROUP_GET_VALUE
	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
	pop	si
	jc	done
	call	AxisValueToPositionInt
done:
	.leave
	ret
ValueAxisGetValuePosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Build a value axis

PASS:		*ds:si	= ValueAxisClass object
		ds:di	= ValueAxisClass instance data
		es	= Segment of ValueAxisClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ValueAxisBuild	method	dynamic	ValueAxisClass, MSG_CHART_OBJECT_BUILD

	uses	ax,cx,dx,bp
	.enter

	BitSet	ds:[di].AI_attr, AA_VALUE
	
	mov	cx, mask ATA_MAJOR_TICKS	; clr ch

	; Don't do tick labels if there are VALUES in the chart
	
	push	cx
	call	UtilGetChartAttributes
	pop	cx

	test	dx, mask CF_VALUES
	jnz	noTickLabels
	or	cl, mask ATA_LABELS
	jmp	gotAttrs

noTickLabels:
	mov	ch, mask ATA_LABELS

gotAttrs:

	;
	; Call the common routine that doesn't care whether we're an X
	; or Y axis (unlike the method)
	;

	call	AxisSetTickAttributesCommon

	; Will set GEOMETRY and IMAGE flags if range changes

	call	ComputeDefaultRange

	.leave
	mov	di, offset ValueAxisClass
	GOTO	ObjCallSuperNoLock
ValueAxisBuild	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeDefaultRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the default range for the axis to cover.

CALLED BY:	ValueAxisBuild

PASS:		ds:di	= ValueAxis object
		*ds:si - ValueAxis object

RETURN:		Instance updated to reflect new AI_max/min fields

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (Sign(minVal) == Sign(maxVal)) {
	    if (Sign(minVal) == Sign(-1)) {
	        ** Both negative
		firstMax = maxVal + (maxVal-minVal)/2
		if (firstMax > 0) {
		    firstMax = 0
		}
		firstMin = minVal
	    } else {
	        ** Both postive
	        firstMax = maxVal
		firstMin = minVal - (maxVal-minVal)/2
		if (firstMin < 0) {
		    firstMin = 0
		}
	    }
	} else {
	    firstMax = maxVal
	    firstMin = minVal
	}
	diffO	 = Int(Log10(firstMax-firstMin))

	rDiff = diffO-1	

	max	 = Ceil(firstMax/10^rDiff)*10^rDiff
	min	 = Floor(firstMin/10^rDiff)*10^rDiff

	In the comments below:
		m	= Minimum
		M	= Maximum
		d	= The difference (max-min)
		f	= First minimum
		F	= First maximum
		o	= Order of the difference
		O	= 10 ^ Order of the difference

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeDefaultRange	proc	near
	class	ValueAxisClass
	uses	ax, cx, dx, bp, di, es
	.enter
	call	UtilGetChartAttributes
	andnf	dx, mask CF_PERCENT or mask CF_FULL
	cmp	dx, mask CF_PERCENT or mask CF_FULL
	jne	calcRange

fullPercent:
	call	SetRangeForFullPercent
	jmp	done

calcRange:

	;
	; Get the max and min onto the floating point stack.
	;
	push	si
	mov	ax, MSG_CHART_GROUP_GET_SERIES_MAX_MIN
	mov	si, offset TemplateChartGroup
	mov	cl, ds:[di].VAI_firstSeries
	mov	ch, ds:[di].VAI_lastSeries
	call	ObjCallInstanceNoLock
	pop	si

	; If we couldn't get a max and min for this series, then just
	; use 0 and 1 and leave it at that.

	jc	fullPercent

;-----------------------------------------------------------------------------
;		       Get Signs of Max and Min
;-----------------------------------------------------------------------------
	;
	; fp: M, m
	;
	call	FloatDup			; fp: M, m, m
	mov	bx, 3
	call	FloatPick			; fp: M, m, m, M
	
	call	FloatLt0			; carry set if Max < 0
	mov	al, 0				; al <- Sign(max)
	jnc	gotMaxSign
	mov	al, 1
gotMaxSign:

	call	FloatLt0			; carry set if min < 0
	mov	ah, 0				; al <- Sign(min)
	jnc	gotMinSign
	mov	ah, 1
gotMinSign:

;-----------------------------------------------------------------------------
;		       Call Appropriate Handler
;-----------------------------------------------------------------------------
	;
	; al	= 0 if max is positive
	; ah	= 0 if min is positive
	; fp: M, m
	;
	cmp	al, ah				; Check for same sign
	je	sameSign			; Branch if same sign
	
	call	ComputeFirstMinMaxDifferentSign
	jmp	gotFirstMinMax

sameSign:
	;
	; The maximum and minimum are same sign (al = non-zero if negative)
	;
	tst	al				; Check for postive
	jz	samePositive
	
	call	ComputeFirstMinMaxBothNegative
	jmp	gotFirstMinMax

samePositive:
	call	ComputeFirstMinMaxBothPositive

;-----------------------------------------------------------------------------
;		     Compute Order of Difference
;-----------------------------------------------------------------------------
gotFirstMinMax:
	;
	; fp: M, m, f, F
	;
	; Compute the order of the difference
	;
	call	FloatDup			; fp: M, m, f, F, F
	mov	bx, 3
	call	FloatPick			; fp: M, m, f, F, F, f
	call	FloatSub			; fp: M, m, f, F, (F-f)
	call	FloatLog			; fp: M, m, f, F, l10(d)
	call	FloatFloatToDword
	mov	ds:[di].VAI_diffOrder, ax
	dec	ax
	call	Float10ToTheX			; fp: M, m, f, F, O

;-----------------------------------------------------------------------------
;			   Compute Maximum
;-----------------------------------------------------------------------------
	call	FloatSwap			; fp: M, m, f, O, F
	mov	bx, 2
	call	FloatPick			; fp: M, m, f, O, F, O
	call	FloatDivide			; fp: M, m, f, O, F/O
	CallCheckTrash	FloatCeiling, si	; fp: M, m, f, O, !F/O!
	mov	bx, 2
	call	FloatPick			; fp: M, m, f, O, !F/O!, O
	call	FloatMultiply			; fp: M, m, f, O, !F/O!*O
	
	mov	bx, offset AI_max
	call	AxisFloatPopNumber		; fp: M, m, f, O
	
;-----------------------------------------------------------------------------
;			   Compute Minimum
;-----------------------------------------------------------------------------
	call	FloatSwap			; fp: M, m, O, f
	mov	bx, 2
	call	FloatPick			; fp: M, m, O, f, O
	call	FloatDivide			; fp: M, m, O, f/O
	call	FloatFloor			; fp: M, m, O, |f/O|
	call	FloatMultiply			; fp: M, m, |f/O|*O
	
	mov	bx, offset AI_min
	call	AxisFloatPopNumber		; fp: M, m 
	;
	; Discard the partial results
	;
	call	FloatDrop			; fp: M
	call	FloatDrop			; fp: 

done:
	.leave
	ret
ComputeDefaultRange	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisFloatPopNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop a # off the FP stack.  If the number is different
		than the number already stored in the instance data,
		then set the COS_IMAGE_INVALID and
		COS_GEOMETRY_INVALID flags.

CALLED BY:

PASS:		*ds:si - axis object
		ds:di - axis instance
		bx - offset to instance data to address to store #
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisFloatPopNumber	proc near
	uses	ax,cx,di,si,es

chunkHandle	local	word	push	si
locals	local	FloatNum

; Assuming even-sized
CheckHack	<(size FloatNum and 1) eq 0>

	.enter
	lea	si, ds:[di][bx]		; point to float in instance
					; data. 

	segmov	es, ss
	lea	di, locals
	call	FloatPopNumber

	push	si, di
	mov	cx, size FloatNum/2
	repe	cmpsw
	pop	di, si			; exchange si, di
	je	done

	segxchg	ds, es
	MovMem	<size FloatNum>
	segxchg	ds, es

 	mov	si, chunkHandle
 	mov	cl, mask COS_IMAGE_INVALID or \
 			mask COS_GEOMETRY_INVALID
 	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
 	call	ObjCallInstanceNoLock
	
done:
	.leave
	ret
AxisFloatPopNumber	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisComputeTickUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose default values for a value axis

CALLED BY:	

PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

	- The increment should be some power of 10 times:
			1, 2, 5
	  because people likes these sorts of numbers.

	- The value axis labels should not be crowded.

	- When all values are positive the position of the category
	  axis should be at the base (bottom) of the value axis.

	- When all values are negative the position of the category
	  axis should be at the top of the value axis.

	- When values are both negative and positive the position of
	  the category axis should be at zero.

	- If all values are positive then the range should include only
	  positive numbers.
	  
	- If all values are negative then the range should include only
	  negative numbers.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValueAxisComputeTickUnits	proc	near
	class	ValueAxisClass
	.enter
	;
	; First mark that the user hasn't set values for this axis
	;
	and	ds:[di].AI_attr, not mask AA_USER_SET_BOUNDS
	
	;
	; Compute the maximum number of labels
	;
	call	ComputeMaxLabelCount		; cx <- max # of labels
	
	;
	; Compute the major tick unit.
	;
	call	ComputeMajorTickUnit

	; Compute number of labels based on tick unit, Max/Min
	;
	call	ComputeNumLabels
	
	;
	; Figure the best minor tick unit.
	;
	call	ComputeMinorTickUnit

	.leave
	ret
ValueAxisComputeTickUnits	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRangeForFullPercent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the range of this axis to 0, 1

CALLED BY:	ComputeDefaultRange

PASS:		ds:di - axis

RETURN:		AI_min, AI_max filled in

DESTROYED:	es

PSEUDO CODE/STRATEGY:	
	Store 0 in AI_min, and 1 in AI_max	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRangeForFullPercent	proc near	
	uses	bx

	class	ValueAxisClass

	.enter

	mov	ds:[di].VAI_diffOrder, 0

	call	Float0
	mov	bx, offset AI_min
	call	AxisFloatPopNumber

	call	Float1
	mov	bx, offset AI_max
	call	AxisFloatPopNumber

	.leave
	ret
SetRangeForFullPercent	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeFirstMinMaxBothPositive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the firstMin and firstMax when both the min and
		max series values are positive.

CALLED BY:	ComputeDefaultRange
PASS:		fp stack contains:
			Minimum		<- top of stack
			Maximum
RETURN:		fp stack contains:
			First maximum	<- top of stack
			First minimum
			Minimum
			Maximum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
        firstMax = maxVal
	firstMin = minVal - (maxVal-minVal)/2
	if (firstMin < 0) {
	    firstMin = 0
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeFirstMinMaxBothPositive	proc	near
	uses	ax, bx, dx
	.enter

	call	SeeIfMaxEqualsMin
	jc	done

	call	FloatDup			; fp: M, m, m
	mov	bx, 3
	call	FloatPick			; fp: M, m, m, M
	call	FloatPick			; fp: M, m, m, M, m
	call	FloatSub			; fp: M, m, m, (M-m)
	call	FloatDivide2			; fp: M, m, m, (M-m)/2
	call	FloatSub			; fp: M, m, m-(M-m)/2

	;
	; If the firstMin is negative we have a problem. If we allow this
	; then we have all our data above zero but our axis base will be
	; less than zero. In this situation we force firstMin to 0.
	;
	; fp: M, m, f
	;
	call	FloatDup			; fp: M, m, f, f
	call	FloatLt0			; Check for negative
						; fp: M, m, f
	jnc	gotFirstMin			; Branch if positive
	call	FloatDrop			; fp: M, m
	call	Float0				; fp: M, m, 0
						; fp: M, m, f
gotFirstMin:
	mov	bx, 3
	call	FloatPick			; fp: M, m, f, F
done:
	.leave
	ret
ComputeFirstMinMaxBothPositive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfMaxEqualsMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special case for both the "both positive" and "both
		negative" case -- if the numbers are the same, then
		set FirstMax = Max+1
		    FirstMin = Min-1
	

CALLED BY:

PASS:		FP stack:	M, m

RETURN:		IF SAME:
			carry set
			FP stack:
				M, m, f, F
		ELSE:
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfMaxEqualsMin	proc near
	.enter
	call	FloatComp
	jne	notSame

	call	FloatDup		; M, m, m
	call	Float1
	call	FloatSub		; M, m, f
	call	FloatDup		; M, m, f, f
	call	Float2
	call	FloatAdd		; m, M, f, F
	stc
done:
	.leave
	ret
notSame:
	clc	
	jmp	done
SeeIfMaxEqualsMin	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeFirstMinMaxBothNegative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the firstMin and firstMax when both the min and
		max series values are negative.

CALLED BY:	ComputeDefaultRange
PASS:		fp stack contains:
			Minimum		<- top of stack
			Maximum
RETURN:		fp stack contains:
			First maximum	<- top of stack
			First minimum
			Minimum
			Maximum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	firstMax = maxVal + (maxVal-minVal)/2
	if (firstMax > 0) {
	    firstMax = 0
	}
	firstMin = minVal

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeFirstMinMaxBothNegative	proc	near
	uses	ax, bx, dx
	.enter
	call	SeeIfMaxEqualsMin
	jc	done

	mov	bx, 2
	call	FloatPick			; fp: M, m, M
	mov	bx, 3
	call	FloatPick			; fp: M, m, M, M
	call	FloatPick			; fp: M, m, M, M, m
	call	FloatSub			; fp: M, m, M, (M-m)
	call	FloatDivide2			; fp: M, m, M, (M-m)/2
	call	FloatAdd			; fp: M, m, M+(M-m)/2
						; fp: M, m, F
	mov	bx, 2
	call	FloatPick			; fp: M, m, F, f
	
	;
	; Check for firstMax being positive
	;
	call	FloatSwap			; fp: M, m, f, F
	call	FloatDup			; fp: M, m, f, F, F
	call	FloatLt0			; Check for less than 0
						; fp: M, m, f, F
	jc	done				; Branch if not less than zero

	call	FloatDrop			; fp: M, m, f
	call	Float0				; fp: M, m, f, 0
						; fp: M, m, f, F
done:
	.leave
	ret
ComputeFirstMinMaxBothNegative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeFirstMinMaxDifferentSign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the firstMin and firstMax when the min and
		max series values have different signs.

CALLED BY:	ComputeDefaultRange
PASS:		fp stack contains:
			Minimum		<- top of stack
			Maximum
RETURN:		fp stack contains:
			First maximum	<- top of stack
			First minimum
			Minimum
			Maximum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	    firstMax = maxVal
	    firstMin = minVal

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeFirstMinMaxDifferentSign	proc	near
	uses	ax, bx, dx
	.enter
	call	FloatDup			; fp: M, m, f
	mov	bx, 3
	call	FloatPick			; fp: M, m, f, F
	.leave
	ret
ComputeFirstMinMaxDifferentSign	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMaxLabelCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the maximum desirable number of labels to
		place on the axis.

CALLED BY:	ValueAxisComputeTickUnits

PASS:		*ds:si	= Axis instance
		ds:di	= Axis instance

RETURN:		cx	= Maximum number of labels.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMaxLabelCount	proc	near
	class	AxisClass
	uses	ax, dx, bp, di, si
	.enter
	call	AxisGetPlotDistance
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; ax	= Width (or height) of axis
	;
	; The amount of space we allow for a label depends on the orientation
	; of the axis and on whether or not the text is rotated.
	;

	mov	cx, ax		; total axis distance

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jz	horizontal

	mov	dx, ds:[di].AI_maxLabelSize.P_y

	jmp	gotMaxLabelSize

horizontal:
	mov	dx, ds:[di].AI_maxLabelSize.P_x

gotMaxLabelSize:
	tst	dx
	jz	noLabels
	
	mov	ax, cx				; dx.ax <- space on axis
	mov	cx, dx				; cx <- space for each label
	clr	dx
	div	cx				; ax <- max number of labels
	mov	cx, ax				; cx <- max number of labels

	;
	; Always have at least one label
	;

	Max	cx, 1
	;
	; And at most 8
	;

	Min	cx, 8

done:
	.leave
	ret

noLabels:
	mov	cx, 8
	jmp	done

ComputeMaxLabelCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMajorTickUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the major tick unit for an axis.

CALLED BY:	ValueAxisComputeTickUnits

PASS:		ds:di	= Axis instance
		cx	= Maximum number of labels

RETURN:		Axis instance with AI_tickMajorUnit set
		bx	= The tickMultTable index that we used

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	** Compute the tick-mark increment
	tickO   = diffO-1
	multIdx = 0

	do {
	    if (multIdx > (length multTable) {
	    	tickO += 1
		multIdx = 0
	    }
	    curTick = tickMultTable[multIdx]*(10^tickO)
	} while ((max-min)/curTick > maxLabels)

	** The tick multiplier table
	tickMultTable	FloatNum	1 2 5
	
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMajorTickUnit	proc	near
	class	ValueAxisClass
	uses	ax, cx, dx, di, si, es
	.enter
	;
	; In the computations below:
	;	l	= max number of labels
	;	p	= diffO (order of difference MAX-MIN)
	;	P	= 10^(diffO-1)
	;	m	= (max-min)
	;	t	= Current multiplier entry
	;	x	= Current tick unit
	;
	; Compute (max-min) since we'll be using it a lot
	;

	; Push diffO 
	mov	ax, ds:[di].VAI_diffOrder
	call	FloatWordToFloat

	
	; push max
	lea	si, ds:[di].AI_max
	call	FloatPushNumber

	; push min
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	
	call	FloatSub			; fp: m
	
	;
	; Put the maximum number of labels on the stack
	;
	mov	ax, cx				; dx.ax <- max labels
	call	FloatWordToFloat		; fp: m, l

	;
	; Compute 10^(diffO-1) since that will be the root of many computations
	;
	mov	ax, ds:[di].VAI_diffOrder
	dec	ax
	call	Float10ToTheX			; fp: m, l, P
	
	;
	; Get started figuring out the tick unit.
	;
	clr	bx		; offset into major tick table
tickLoop:
	;
	; fp: m, l, P
	;
	cmp	bx, size FloatNum * (length MajorTickTable-1)
	jle	gotOffset

	; We have run out of entries. Try increasing exponent.
	;
	call	FloatMultiply10			; Multiply exponent part by 10
	clr	bx
gotOffset:
	;
	; cs:MajorTickTable[bx] = Next multiplier to try
	;
	push	bx				; Save table index
	call	FloatDup			; fp: m, l, P, P

	push	ds				; Save instance segment
	segmov	ds, cs, si			; ds:si <- multiplier
	lea	si, cs:MajorTickTable[bx]
FXIP<	push	cx							>
FXIP<	mov	cx, size FloatNum		; # of bytes to copy	>
FXIP<	call	SysCopyToStackDSSI		; ds:si = floatNum on stack >
	call	FloatPushNumber			; fp: m, l, P, P, t
FXIP<	call	SysRemoveFromStack		; release stack space	>
FXIP<	pop	cx							>
	pop	ds				; Restore instance segment

	call	FloatMultiply			; fp: m, l, P, (t*P)
						; fp: m, l, P, x
	call	FloatDup			; fp: m, l, P, x, x
	mov	bx, 5
	call	FloatPick			; fp: m, l, P, x, x, m
	call	FloatSwap			; fp: m, l, P, x, m, x
	call	FloatDivide			; fp: m, l, P, x, m/x
	mov	bx, 4
	call	FloatPick			; fp: m, l, P, x, m/x, l

	call	FloatCompAndDrop		; Compare m/x, l
						; fp: m, l, P, x
	pop	bx				; Restore table index
	jle	foundTick			; Branch if this will work

	call	FloatDrop			; fp: m, l, P
	add	bx, size FloatNum
	jmp	tickLoop			; Loop to try another

foundTick:
	;
	; We've found the tick-unit to use. Save it to the instance
	; fp: m, l, P, x
	;
	segmov	es, ds, ax			; es:di <- destination
	lea	di, ds:[di].AI_tickMajorUnit
	call	FloatPopNumber			; Save result away

	;
	; We need to drop the remaining numbers from the stack
	; fp: m, l, P
	;
	call	FloatDrop			; Drop 10^x
	call	FloatDrop			; Drop max labels
	call	FloatDrop			; Drop (max-min)
	call	FloatDrop			; drop diffO
	
	.leave
	ret
ComputeMajorTickUnit	endp

MajorTickTable	FloatNum <0,0,0,0x8000,<0,0x3fff>>,			; 1
			 <0,0,0,0x8000,<0,0x4000>>,			; 2
			 <0,0,0,0xA000,<0,0x4001>>			; 5


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMinorTickUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the minor tick unit for an axis.

CALLED BY:	ValueAxisComputeTickUnits
PASS:		ds:di	= Axis instance

RETURN:		Axis instance with AI_tickMinorUnit set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For now, just go with (majorUnit/2)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMinorTickUnit	proc	near
	class	AxisClass
	uses	ax, dx, di, si, es
	.enter
	lea	si, ds:[di].AI_tickMajorUnit	; Push major unit
	call	FloatPushNumber

	call	Float2
	call	FloatDivide			; Compute major/divisor
	
	segmov	es, ds, ax			; es:di <- destination
	lea	di, ds:[di].AI_tickMinorUnit
	
	call	FloatPopNumber			; Pop major/2
	.leave
	ret
ComputeMinorTickUnit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeIntersectionPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position of the related axis.

CALLED BY:	ValueAxisBuild

PASS:		ds:di	= Axis instance

RETURN:		Axis instance with AI_intersect set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (Sign(axis.min) != Sign(axis.max)) {
	    ** Different signs. Place the related axis at 0
	    axis.intersect = 0
	} else if (Sign(axis.min) == Sign(-1)) {
	    ** Both negative. Place related axis at the top
	    axis.intersect = axis.max
	} else {
	    ** Both positive. Place related axis at the bottom
	    axis.intersect = axis.min
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeIntersectionPosition	proc	near
	class	AxisClass
	uses	ax, cx, si, di, ds, es
	.enter
	;
	; Get the sign of the minimum.
	;
	lea	si, ds:[di].AI_min		; Push minimum
	call	FloatPushNumber
	call	FloatLt0			; carry set if (min < 0)
	mov	al, 0				; Assume positive
	jnc	gotMinSign
	mov	al, 1
gotMinSign:
	
	;
	; Get the sign of the maximum
	;
	lea	si, ds:[di].AI_max		; Push maximum
	call	FloatPushNumber
	call	FloatLt0			; carry set if (max < 0)
	mov	ah, 0				; Assume positive
	jnc	gotMaxSign
	mov	ah, 1
gotMaxSign:
	
	segmov	es, ds, si			; es:di <- instance ptr
	;
	; al	= Sign of minimum (0 for positive)
	; ah	= Sign of maximum (0 for positive)
	; es:di	= Instance ptr
	;
	cmp	al, ah				; Check for same sign
	je	sameSign			; Branch if same sign
	
	;
	; Different signs. Place a zero in the AI_intersect field
	;
	segmov	ds, cs, si			; ds:si <- source
	mov	si, offset cs:crapZeroNum
	jmp	copyNum

sameSign:
	tst	al				; Check for positive
	jz	bothPositive			; Branch if both positive

	;
	; Both are negative. Put the max into the intersection position
	;
	lea	si, ds:[di].AI_max
	jmp	copyNum

bothPositive:
	;
	; Both are positive. Put the min into the intersection position
	;
	lea	si, ds:[di].AI_min

copyNum:
	;
	; ds:si	= Pointer to the number to copy
	; es:di	= Instance ptr
	;
	lea	di, es:[di].AI_intersect	; es:di <- destination
	MovMem	<size FloatNum>
	.leave
	ret
ComputeIntersectionPosition  endp

crapZeroNum	FloatNum <0,0,0,0,<0,0>>	; zero



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNumLabels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of labels for a value axis

CALLED BY:	ValueAxisComputeTickUnits

PASS:		*ds:si - axis object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	numLabels = FLOOR((Max - Min)/tickMajorUnit) + 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 3/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNumLabels	proc near	
	class	AxisClass
	uses ax,di,si
	.enter
	mov	di, ds:[si]
	lea	si, ds:[di].AI_max
	call	FloatPushNumber
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	call	FloatSub
	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber
	call	FloatDivide
	call	FloatFloor
	call	FloatFloatToDword
	inc	ax
	mov	ds:[di].AI_numLabels, ax

	.leave
	ret
ComputeNumLabels	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNumMinorTicks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will compute the number of minor ticks.

CALLED BY:	TickEnumCommon

PASS:		*ds:si - axis object

RETURN:		dx

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	numMinorTicks = FLOOR((Max - Min)/tickMinorUnit) + 1
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNumMinorTicks	proc	near

	class	AxisClass
	uses ax,di,si
	.enter

	mov	di, ds:[si]
	lea	si, ds:[di].AI_max
	call	FloatPushNumber
	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	call	FloatSub		; fp = max - min
	lea	si, ds:[di].AI_tickMinorUnit
	call	FloatPushNumber
	call	FloatDivide		; fp = fp/minorUnits
	call	FloatFloor		; fp = floor(fp)
	call	FloatFloatToDword
	inc	ax			; fp = fp + 1
	mov_tr	dx, ax			; numMinorTicks

	.leave
	ret
ComputeNumMinorTicks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Begin geometry calculations for this axis

PASS:		*ds:si	= ValueAxisClass object
		ds:di	= ValueAxisClass instance data
		es	= Segment of ValueAxisClass.
		cx, dx  = suggested size

RETURN:		cx, dx - axis size

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	For a VERTICAL axis:
		calc left/right distances
		guess top/bottom distances

	For a HORIZONTAL axis:
		calc top/bottom distances
		guess left/right distances

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ValueAxisRecalcSize	method	dynamic	ValueAxisClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax

axisSize	local	Point	push	dx, cx

	.enter

	;
	; Figure the best position for the related axis.
	;
	call	ComputeIntersectionPosition

	call	ValueAxisComputeMaxLabelSize

	test	ds:[di].AI_attr, mask AA_VERTICAL
	jnz	vertical

	; HORIZONTAL:

	; SET SIZE
	; WIDTH = max(MIN_PLOT_DISTANCE + maxLabelWidth, passed width)

	mov	ax, ds:[di].AI_maxLabelSize.P_x
	add	ax, AXIS_MIN_PLOT_DISTANCE
	Max	cx, ax
	mov	axisSize.P_x, cx

	; HEIGHT = AXIS_STANDARD_AXIS_HEIGHT + maxLabelHeight

	mov	ax, AXIS_STANDARD_AXIS_HEIGHT
	add	ax, ds:[di].AI_maxLabelSize.P_y
	mov	axisSize.P_y, ax

	; SET PLOT BOUNDS:
	;	Left = labelWidth/2
	; 	Right = axis width - labelWidth/2
	; 	Top = AXIS_ABOVE_HEIGHT
	;	Bottom = AXIS_ABOVE_HEIGHT

	mov	ax, ds:[di].AI_maxLabelSize.P_x
	shr	ax		
	sub	cx, ax

	mov	ds:[di].AI_plotBounds.R_left, ax
	mov	ds:[di].AI_plotBounds.R_right, cx
	mov	ds:[di].AI_plotBounds.R_top, AXIS_ABOVE_HEIGHT
	mov	ds:[di].AI_plotBounds.R_bottom, AXIS_ABOVE_HEIGHT
	jmp	done

vertical:
	; Set size:
	; HEIGHT = max(MIN_PLOT_DISTANCE + maxLabelHeight, passed height)


	mov	ax, ds:[di].AI_maxLabelSize.P_y
	add	ax, AXIS_MIN_PLOT_DISTANCE
	Max	dx, ax
	mov	axisSize.P_y, dx

	; WIDTH = maxLabelWidth + tick width

	mov	ax, ds:[di].AI_maxLabelSize.P_x
	mov	bx, ax
	add	ax, AXIS_STANDARD_AXIS_WIDTH
	mov	axisSize.P_x, ax

	; Set plot bounds
	; Left = maxLabelSize.P_x + tickWidth/2
	; Right = Left
	; Top = maxLabelHeight/2
	; Bottom = (axis height) - maxLabelHeight/2

	mov	ax, ds:[di].AI_maxLabelSize.P_y
	shr	ax, 1
	sub	dx, ax

	mov	ds:[di].AI_plotBounds.R_top, ax
	mov	ds:[di].AI_plotBounds.R_bottom, dx
	add	bx, AXIS_LEFT_WIDTH
	mov	ds:[di].AI_plotBounds.R_left, bx
	mov	ds:[di].AI_plotBounds.R_right, bx

done:
	;
	; Pass new size up to superclass
	;
	movP	cxdx, axisSize

	.leave
	mov	di, offset ValueAxisClass
	GOTO	ObjCallSuperNoLock
ValueAxisRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisComputeMaxLabelSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the maximum x/y size of a label

CALLED BY:	ValueAxisRecalcSize

PASS:		*ds:si - axis

RETURN:		nothing -- AI_maxLabelSize fields filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValueAxisComputeMaxLabelSize	proc near
	uses	ax,bx,cx,dx,si,di,bp
	class	ValueAxisClass
	.enter

	DerefChartObject ds, si, di

	test	ds:[di].AI_tickAttr, mask ATA_LABELS
	jz	noLabels

	call	UtilCreateGStateForTextCalculations	; bp - gstate

	lea	bx, ds:[di].AI_max

	call	AxisGetNumberWidth
	mov	cx, ax			; width of "MAX"

	lea	bx, ds:[di].AI_min
	call	AxisGetNumberWidth
	Max	ax, cx
	mov	ds:[di].AI_maxLabelSize.P_x, ax

	push	di
	mov	di, bp
	call	GrDestroyState
	pop	di

	;
	; For height -- use font height
	;
	call	UtilGetTextLineHeight
	mov	ds:[di].AI_maxLabelSize.P_y, ax

done:
	.leave
	ret

noLabels:
	clr	ds:[di].AI_maxLabelSize.P_x
	clr	ds:[di].AI_maxLabelSize.P_y
	jmp	done

ValueAxisComputeMaxLabelSize	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisGeometryPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Finish the geometry for this axis.

PASS:		*ds:si	= ValueAxisClass object
		ds:di	= ValueAxisClass instance data
		es	= Segment of ValueAxisClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ValueAxisGeometryPart2	method	dynamic	ValueAxisClass, 
					MSG_AXIS_GEOMETRY_PART_2
	uses	ax,cx,dx,bp
	.enter
	push	di
	mov	di, offset	ValueAxisClass
	call	ObjCallSuperNoLock
	pop	di

	call	ValueAxisComputeTickUnits

	.leave
	ret
ValueAxisGeometryPart2	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetNumberWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of a number on the floating-point stack. 

CALLED BY:	ValueAxisComputeMaxLabelSize

PASS:		ds:bx - floating point number
		*ds:si - axis object
		^hbp - gstate handle
	
RETURN:		ax - width

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Create a gstate
	fetch the text attributes from the first text object (or the
		GOAM text if none exist)
	apply them to the gstate

	If necessary:
		Concatenate a ".5" at then end, because the purpose of
		this routine is to deal with maximum widths.

	get the width
	destroy the gstate

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetNumberWidth	proc near	
	uses	bx,cx,dx,di,si,ds,es,bp
	.enter

	push	si
	mov	si, bx
	call	FloatPushNumber
	pop	si


	sub	sp, CHART_TEXT_BUFFER_SIZE
	segmov	es, ss
	mov	di, sp

	;
	; Convert number to ascii
	;

	call	AxisFloatToAscii
	segmov	ds, es, si
	mov	si, di

	;
	; Create gstate, and get width of string
	;

	mov	di, bp			; gstate
	clr	cx			; null-term text
	call	GrTextWidth
	push	dx

	; get width of ".5"

	mov	bx, handle StringUI
	call	MemLock
	mov	ds, ax
	assume	ds:StringUI
	mov	si, ds:[Point5]
	assume	ds:dgroup

	call	GrTextWidth

	call	MemUnlock

	;
	; Add the widths together
	;

	pop	ax
	add	ax, dx

	add	ax, NUMBER_WIDTH_FUDGE_FACTOR

	;
	; clean up
	;

	add	sp, CHART_TEXT_BUFFER_SIZE

	.leave
	ret
AxisGetNumberWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisCombineNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Combine notification data for value axis

PASS:		*ds:si	= ValueAxisClass object
		ds:di	= ValueAxisClass instance data
		es	= Segment of ValueAxisClass.
		cx	= handle of AxisNotificationBlock

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ValueAxisCombineNotificationData	method	dynamic	ValueAxisClass, 
					MSG_AXIS_COMBINE_NOTIFICATION_DATA
	uses	ax,dx,bp
	.enter

	mov	di, offset ValueAxisClass
	call	ObjCallSuperNoLock

	mov	bx, cx
	call	MemLock
	mov	es, ax
	push	bx		; save notification handle

	DerefChartObject ds, si, bx

	test	es:[CNBH_flags], mask CCF_FOUND_VALUE_AXIS
	jz	firstOne

	; calculate diffs for min/max/major/minor
	mov	al, mask AFD_MIN
	lea	si, ds:[bx].AI_min
	lea	di, es:[ANB_min]
	call	CalcFloatDiff	

	mov	al, mask AFD_MAX
	lea	si, ds:[bx].AI_max
	lea	di, es:[ANB_max]
	call	CalcFloatDiff	

	mov	al, mask AFD_TICK_MAJOR_UNIT
	lea	si, ds:[bx].AI_tickMajorUnit
	lea	di, es:[ANB_tickMajorUnit]
	call	CalcFloatDiff	

	mov	al, mask AFD_TICK_MINOR_UNIT
	lea	si, ds:[bx].AI_tickMinorUnit
	lea	di, es:[ANB_tickMinorUnit]
	call	CalcFloatDiff	
done:
	pop	bx
	call	MemUnlock
	.leave
	ret

firstOne:
	; hack!  min/max/major/minor are in same order and
	; contiguous in both the instance data and the notification
	; block. 
	
CheckHack <offset ANB_max eq offset ANB_min + size FloatNum>
CheckHack <offset ANB_tickMajorUnit eq offset ANB_max + size FloatNum>
CheckHack <offset ANB_tickMinorUnit eq offset ANB_tickMajorUnit + size FloatNum>
	
CheckHack <offset AI_max eq offset AI_min + size FloatNum>
CheckHack <offset AI_tickMajorUnit eq offset AI_max + size FloatNum>
CheckHack <offset AI_tickMinorUnit eq offset AI_tickMajorUnit + size FloatNum>

	lea	si, ds:[bx].AI_min
	mov	di, offset ANB_min
	MovMem	<size FloatNum>
	BitSet	es:[CNBH_flags], CCF_FOUND_VALUE_AXIS
	jmp	done

ValueAxisCombineNotificationData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFloatDiff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if 2 floats are different (just does a repe
		cmpsw, which might not be the best way...)

CALLED BY:	ValueAxisCombineNotificationData

PASS:		ds:si - float #1
		es:di - float #2
		(es - AxisNotifyBlock)
		al - mask in AxisFloatDiffs record of floating point
		number to check

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcFloatDiff	proc near	
	uses	cx
	.enter
	mov	ah, es:[ANB_floatDiffs]
	and	ah, al			; only check this one bit
	jnz	done			; bit is already set.

	mov	cx, size FloatNum/2
	repe	cmpsw
	jz	done
	or	es:[ANB_floatDiffs], al

done:
	.leave
	ret
CalcFloatDiff	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValueAxisSetSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the range of series that this axis covers

PASS:		*ds:si	= ValueAxisClass object
		ds:di	= ValueAxisClass instance data
		es	= Segment of ValueAxisClass.
		cl 	= first series
		ch	= last series

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ValueAxisSetSeries	method	dynamic	ValueAxisClass, 
					MSG_VALUE_AXIS_SET_SERIES
	.enter
	mov	ds:[di].VAI_firstSeries, cl
	mov	ds:[di].VAI_lastSeries, ch
	.leave
	ret
ValueAxisSetSeries	endm




AxisCode	ends
