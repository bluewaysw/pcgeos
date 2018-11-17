COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsFloat.asm

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
	CDB	12/ 9/91	Initial version.

DESCRIPTION:
	

	$Id: utilsFloat.asm,v 1.1 97/04/04 17:47:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatPushPercent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a number between 0 and 100 and divide by 100

CALLED BY:	internal

PASS:		al - percentage (0 to 100)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Would be a lot faster with FloatPushWWFixed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/ 5/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatPushPercent	proc far
	uses	ds, si
	.enter
	cbw
	call	FloatWordToFloat
	call	Float100
	call	FloatDivide
	.leave
	ret
FloatPushPercent	endp


float100 	FloatNum	<0,0,0,0xC800,<0,0x4005>>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Float100
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push 100 on the stack

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Float100	proc far
	uses	ds, si
	.enter
	segmov	ds, cs, si
	lea	si, cs:[float100]
FXIP<	push	cx							>
FXIP<	mov	cx, size FloatNum		; cx = size of data	>
FXIP<	call	SysCopyToStackDSSI		; ds:si = floatNum on stack >
FXIP<	pop	cx				; restore cx		>
	call	FloatPushNumber
FXIP<	call	SysRemoveFromStack		; release stack space	>
	.leave
	ret
Float100	endp





ChartCompCode	ends
