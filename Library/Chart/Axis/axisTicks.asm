COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisTicks.asm

AUTHOR:		John Wedgwood, Oct 23, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/23/91	Initial revision

DESCRIPTION:
	Tick related utilities

	$Id: axisTicks.asm,v 1.1 97/04/04 17:45:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetTickPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the position of a major tick value

CALLED BY:	internal

PASS:		ds:di - axis object
		bx - tick number

RETURN:		ax - position, offset from upper left-hand corner of
		chart group.
		(X-value for horizontal, Y-value for vertical axis). 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	multiply tick number * tick increment
	add min tick amount, 
	if CATEGORY axis, add minor tick position


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 2/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisGetTickPosition	proc near	
	class	AxisClass
	uses	si
	.enter
	call	CheckForceLegal
	mov	ax, bx

	call	FloatWordToFloat
	lea	si, ds:[di].AI_tickMajorUnit
	call	FloatPushNumber
	call	FloatMultiply

	lea	si, ds:[di].AI_min
	call	FloatPushNumber
	call	FloatAdd

	test	ds:[di].AI_attr, mask AA_VALUE
	jnz	afterAdd

	; For category axis, add in the minor tick position
	lea	si, ds:[di].AI_tickMinorUnit
	call	FloatPushNumber
	call	FloatAdd

afterAdd:
	call	AxisFloatToPosition

	.leave
	ret
AxisGetTickPosition	endp


AxisCode	ends
