COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		int8087.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 2/92		Initial version.

DESCRIPTION:
	specifi code to the 8087 chip

	$Id: int8087.asm,v 1.1 97/04/04 17:48:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Cos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = cos(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

		since there is only a fptan

		fptan gives us st = adjacent (a)
			       st(1) = opposite (o)

		so cos = a/sqrt(o*o + a*a)
 
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Cos	proc	far
myfloat	local FloatNum
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
;	fcos
	fptan
	fstp	myfloat		; myfloat = a
	fld	st		; st = st(1) = o
	fmulp			; st = o*o
	fld	myfloat		; st = a
	fld	st
	fmulp			; st = a*a
	faddp			; st = o*o + a*a
	fsqrt			; st = sqrt (o*o + a*a)
	fld	myfloat
	fdivrp			; st = a/sqrt(o*o + a*a)
	mov	ax, -2	
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Cos	endp
	public	Intel80X87Cos


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = sin(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

		since there is only a fptan

		fptan gives us st = adjacent (a)
			       st(1) = opposite (o)

		so sin = o/sqrt(o*o + a*a)
 
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sin	proc	far
myfloat	local FloatNum
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
;	fcos
	fptan
	fxch
	fstp	myfloat		; myfloat =o
	fld	st		; st = st(1) = a
	fmulp			; st = a*a
	fld	myfloat		; st = o
	fld	st
	fmulp			; st = o*o
	faddp			; st = o*o + a*a
	fsqrt			; st = sqrt (o*o + a*a)
	fld	myfloat
	fdivrp			; st = o/sqrt(o*o + a*a)
	mov	ax, -2	
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sin	endp
	public	Intel80X87Sin

CommonCode	ends	
