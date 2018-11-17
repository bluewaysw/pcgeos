COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		intx87.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 2/92		Initial version.

DESCRIPTION:
	code speicific to the 387

	$Id: intx87.asm,v 1.1 97/04/04 17:48:25 newdeal Exp $

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

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Cos	proc	far
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fcos
	call	Intel80X87CheckNormalNumberAndLeave
done:
	ret
Intel80X87Cos	endp
	public	Intel80X87Cos


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = sin(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if any problems

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sin	proc	far	
	.enter
	mov	ax, 0
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fsin
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sin	endp
	public	Intel80X87Sin

CommonCode ends
