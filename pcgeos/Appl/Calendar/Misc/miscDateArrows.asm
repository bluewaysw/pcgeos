COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc
FILE:		miscDateArrows.asm

AUTHOR:		Don Reeves, Oct 19, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/19/92	Initial revision

DESCRIPTION:
	Implements the DateArrowsClass

	$Id: miscDateArrows.asm,v 1.1 97/04/04 14:48:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
		DateArrowsClass
idata		ends



DayPlanCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateArrowsIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the next range of displayed dates

CALLED BY:	GLOBAL (MSG_GEN_VALUE_INCREMENT)

PASS:		*DS:SI	= DateArrowsClass object
		DS:DI	= DateArrowsClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DateArrowsIncrement	method dynamic	DateArrowsClass, MSG_GEN_VALUE_INCREMENT
		mov	dx, DC_BACKWARD
		GOTO	DateArrowsChange
DateArrowsIncrement	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateArrowsDecrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the previous range of displayed dates

CALLED BY:	GLOBAL (MSG_GEN_VALUE_DECREMENT)

PASS:		*DS:SI	= DateArrowsClass object
		DS:DI	= DateArrowsClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DateArrowsDecrement	method dynamic	DateArrowsClass, MSG_GEN_VALUE_DECREMENT
		mov	dx, DC_FORWARD
		FALL_THRU	DateArrowsChange
DateArrowsDecrement	endm

DateArrowsChange	proc	far
		mov	ax, MSG_DP_ALTER_RANGE
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		clr	di
		GOTO	ObjMessage
DateArrowsChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateArrowsGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for this object, which is always NULL

CALLED BY:	GLOBAL (MSG_GEN_VALUE_GET_VALUE_TEXT)

PASS:		*DS:SI	= DateArrowsClass object
		DS:DI	= DateArrowsClassInstance
		CX:DX	= Buffer to fill
		BP	= GenValueType

RETURN:		CX:DX	= Filled buffer

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DateArrowsGetValueText	method dynamic	DateArrowsClass,
					MSG_GEN_VALUE_GET_VALUE_TEXT
		.enter

		; Return the shortest strig possible, which I
		; will assume is a space followed by a NULL.
		; Returning a NULL string is useless for size determination
		;
		mov	es, cx
		mov	di, dx
		mov	ax, ' '		; space followed by NULL
		stosw
DBCS <		clr	ax						>
DBCS <		stosw							>

		.leave
		ret
DateArrowsGetValueText	endm

DayPlanCode	ends
