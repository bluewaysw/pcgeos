COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverVector.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	Support for SaverVector structure
		

	$Id: saverVector.asm,v 1.1 97/04/07 10:44:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverVectorCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverVectorInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a vector.

CALLED BY:	GLOBAL
PASS:		es:di	= SaverVector to initialize
		ax	= SaverVectorReflectType
		cx	= minimum point value
		dx	= maximum point value
		bh	= base delta
		bl	= delta max (above base)
		si	= random number generator to use
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverVectorInit	proc	far
		uses	bx, cx, dx, ax, ds
		.enter
	;
	; Store the values we were passed into the structure.
	;
		segmov	ds, es
		mov	ds:[di].SV_min, cx
		mov	ds:[di].SV_max, dx
		mov	ds:[di].SV_reflect, ax
		mov	ds:[di].SV_deltaBase, bh
		mov	ds:[di].SV_deltaMax, bl
	;
	; Set the point to a random value between min and max
	;
		sub	dx, cx
		mov	bx, si		; bx <- RNG
		call	SaverRandom
		add	dx, cx
		mov	ds:[di].SV_point, dx
	;
	; Figure the initial delta, multiplying the max by 2 so we can subtract
	; the max from the result to get a delta that's positive or negative.
	;
		mov	dl, ds:[di].SV_deltaMax
		clr	dh
		shl	dx
		call	SaverRandom
		sub	dl, ds:[di].SV_deltaMax
		sbb	dh, 0

	;
	; Add in the base delta to the result. If the initial delta is negative,
	; we need to negate the base as well.
	;
		mov	al, ds:[di].SV_deltaBase
		jns	10$
		neg	al
10$:
		cbw
		add	dx, ax
		mov	ds:[di].SV_delta, dx
		.leave
		ret
SaverVectorInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverVectorUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a vector by the current delta, adjusting the delta
		properly when we hit the edge.

CALLED BY:	GLOBAL
PASS:		ds:si	= SaverVector to update
		bx	= random number generator to use
RETURN:		ax	= new value (MAY BE OUTSIDE MIN/MAX)
		delta will change if value hits the edge
		carry	= set if vector delta changed
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverVectorUpdate	proc	far
		uses	dx
		.enter

	;
	; If the type is STOCHASTIC, choose a random spot.
	;
		cmp	ds:[si].SV_reflect, SVRT_STOCHASTIC
		jne	nonStochastic		; jump if not STOCHASTIC.

	;
	; Set the point to a random value between min and max
	;
		mov	dx, ds:[si].SV_max
		sub	dx, ds:[si].SV_min
		call	SaverRandom
		add	dx, ds:[si].SV_min
		mov	ds:[si].SV_point, dx
		clc				; vector delta never changes...
		jmp	done

nonStochastic:
		mov	ax, ds:[si].SV_point
		mov	dx, ds:[si].SV_delta
		add	ax, dx
		mov	ds:[si].SV_point, ax

	;
	; See if the point is outside the bounds.
	;
		cmp	ax, ds:[si].SV_min
		jl	reflect
		cmp	ax, ds:[si].SV_max
		clc				;in case of branch...
		jle	done			;doesn't use carry flag
reflect:
	;
	; Point is out-of-bounds. Adjust the delta to correct this next time.
	; If SVRT_BOUNCE, we just need to negate the delta.
	;
		cmp	ds:[si].SV_reflect, SVRT_BOUNCE
		je	negate
	;
	; Not SVRT_BOUNCE. Choose another random delta between deltaBase and
	; deltaBase+max.
	;
		push	ax
		clr	dx
		mov	dl, ds:[si].SV_deltaMax
		call	SaverRandom
		add	dl, ds:[si].SV_deltaBase
		adc	dh, 0
		pop	ax
	;
	; Ensure the proper polarity of delta. If the current point is less
	; than the minimum, a positive delta is what we want. Else we need
	; it negative so we move away from the max.
	;
		cmp	ax, ds:[si].SV_min
		jl	storeDelta
negate:
		neg	dx
storeDelta:
		mov	ds:[si].SV_delta, dx
		stc				;carry <- delta changed
done:
		.leave
		ret
SaverVectorUpdate	endp

SaverVectorCode	ends
