COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Driver
FILE:		nimbusUtils.asm

AUTHOR:		Gene Anderson, Feb 20, 1990

ROUTINES:
	Name			Description
	----			-----------
UTIL	DoMult			Multiply (short) by scale factor.
UTIL	MulWWFixedES		Multiply WWFixed in *es:di by WWFixed in dx:cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/20/90	Initial revision

DESCRIPTION:
	Contains utility routines used in
		
	$Id: nimbusUtils.asm,v 1.1 97/04/18 11:45:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Mul100WWFixedES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a number by a percentage scale factor
CALLED BY:	AddGraphicsTransform

PASS:		cl <- muliplier (percentage)
		es:di <- current value (WWFixed)
RETURN:		es:di <- current * multiplier (WWFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Mul100WWFixedES		proc	far
	uses	ax, bx, cx, dx
	.enter

	mov	dl, cl
	clr	dh
	clr	cx, ax				;dx.cx <- percentage
	mov	bx, 100				;bx.ax <- convert % to WWFixed
	call	GrUDivWWFixed
	call	MulWWFixedES

	.leave
	ret
Mul100WWFixedES		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulWWFixedES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a number by a scale factor.
CALLED BY:	AddGraphicsTransform

PASS:		dx.cx <- muliplier (WWFixed)
		es:di <- current value (WWFixed)
RETURN:		es:di <- current * multiplier (WWFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MulWWFixedES	proc near	uses ds, si
	.enter

	push	dx
	push	cx
	mov	si, sp
	segmov	ds, ss				;ds:si <- ptr to multiplier
	call	GrMulWWFixedPtr
	mov	es:[di].WWF_int, dx
	mov	es:[di].WWF_frac, cx
	pop	cx
	pop	dx

	.leave
	ret
MulWWFixedES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulWWFixedDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	

PASS:		dx.cx <- multiplier (WWFixed)
		ds:si <- current value (WWFixed)
RETURN:		bx.ax <- current * multiplier (WWFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MulWWFixedDS	proc	near	uses	es, di
	.enter
	push	dx
	push	cx
	mov	di, sp
	segmov	es, ss
	call	GrMulWWFixedPtr
	mov	bx, dx
	mov	ax, cx
	pop	cx
	pop	dx
	.leave
	ret
MulWWFixedDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleShortWBFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply given number by scale factor, round to WBFixed
CALLED BY:	INTERNAL: ConvertHeader

PASS:		bx - number to convert (short)
		ax:si - ptr to scale factor (WWFixed)
		ax:di - scratch register
RETURN:		dx:ch - scaled number (WBFixed)
DESTROYED:	cl

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleShortWBFixed	proc	near
	uses	ds, es
	.enter
	mov	es, ax
	mov	ds, ax
	mov	es:[di].WWF_int, bx
	mov	es:[di].WWF_frac, 0
	call	GrMulWWFixedPtr			;dx.cx == scale * number
	rndwwbf	dxcx				;dx.ch <- rounded to WBFixed
	.leave
	ret
ScaleShortWBFixed	endp
