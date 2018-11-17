COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusMul.asm

AUTHOR:		Gene Anderson, May 26, 1990

ROUTINES:
	Name			Description
	----			-----------
	IndexOf			Return index of value in array
	Scale			Multiply number and scale result

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/26/90		Initial revision

DESCRIPTION:
	My rewrite of Nimbus routines from mul.c

	$Id: nimbusMul.asm,v 1.1 97/04/18 11:45:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndexOf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return index of value in array.
CALLED BY:	UTILITY

PASS:		ds:di - ptr to array to scan
		ax - value to find
		cx - # of entries in array
RETURN:		if found:
			carry - set
			di - offset (from start) of entry
		else:
			carry - clear
			di - offset (from start) of empty entry
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IndexOf	proc	near
	uses	bx, cx, es
	.enter

	mov	bx, di				;bx <- start index
	jcxz	notFound			;branch if table empty
	segmov	es, ds				;es:di <- ptr to array
	repne	scasw				;scan for value
	je	foundValue			;branch if we found it
notFound:
	sub	di, bx				;di <- offset from start
done:
	.leave
	ret

foundValue:
	sub	di, size word			;back up to entry found
	sub	di, bx
	stc					;indicate found
	jmp	done
IndexOf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply number and scale result to correct units.
CALLED BY:	UTILITY

PASS:		ax - outline coordinate -- a simple integer
		dx - scale factor -- numerator of 32768-based fraction
RETURN:		ax - result
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	do 16x16 signed multiply and keep all 32 bits of result
	result is in sub_pixels -- numerator of 16-based fraction
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sp	1989		Initial version
	eca	5/27/90		No C-grossness

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Scale	proc	near
	uses	dx
	.enter

	;SIGNED multiply of the shorts, 32 bit result
	imul	dx
	; add 1024 as a long to effect round to nearest sub_pixel
	add	ax, 1024
	adc	dx, 0
	; long right shift by 3
	ror	dx, 1
	rcr	ax, 1
	ror	dx, 1
	rcr	ax, 1
	ror	dx, 1
	rcr	ax, 1
	; long right shift by 8 (using byte registers)
	mov	al, ah
	mov	ah, dl
	; fortunately <dh> will be zero and result is in <ax>

	.leave
	ret
Scale	endp
