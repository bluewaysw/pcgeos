COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Spell Checker
FILE:		geos_opts.asm

AUTHOR:		Andrew Wilson, Apr 22, 1991

ROUTINES:
	Name			Description
	----			-----------
	ICSUFMAT		Optimized version of ICsufmat().
	GEOSICDECODEOPT1	Optimized version of part of ICdecode.
	SLFUN			Optimized version of SLfun().
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/22/91		Initial revision

DESCRIPTION:
	This file contains C routines we re-wrote in assembly for speed.

	$Id: geos_opts.asm,v 1.1 97/04/07 11:04:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixedCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SLfun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is an optimized version of SLfun(). The name is
		misleading.

CALLED BY:	GLOBAL
C DECLARATION:	RETCODE SLfun (PUCHAR letter, INT2B first, INT2B last, PUINT2B code, PUINT2B index);

 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef __BORLANDC__
global	SLFUN:far
SLFUN	proc	far letterp:fptr.char,
else
global	SLfun:far
SLfun	proc	far letterp:fptr.char,
endif
		    firstI:word,
		    lastI:word,
		    code:fptr.word,
		    index:fptr.word
	uses	ds, di, si
	.enter		
	lds	si, letterp
	add	si, firstI		;
	clr	ax			;
	lodsb				;*code = *(letter + firstI)
	mov	cx, ax
	mov	dx, lastI
	sub	dx, firstI

	dec	dx			;(for k=firstI+1;k<=lastI;k++)
	js	exit
15$:
;
;	AX = *code
;	CX = *index
;	DS:SI = letter+k
;	DX = lastI-k
;
	mov	bx,ax			;
	rol	bx, 1			;alpha = *code >> 7
	xchg	bl, bh			;
	and	bh, 0x1			;

	mov	di, bx			;DI <- alpha
	shl	bx, 1			;
	add	di, bx			;
	shl	bx, 1			;
	shl	bx, 1			;
	shl	bx, 1			;alpha = alpha + alpha<<1 + alpha<<4
	add	di, bx			;

	mov	ah, al			;
	and	ah, 0x7F		;AX <- *code & 0x7f << 8
	lodsb				;AX <- (UINT2B) (*(letter+k))
					;    + ((*code & 0x007F) << 8);
	add	ax, di	
	cmp	ax, 32748		;if (*code > 32748)
	jbe	30$			;
	sub	ax, 32749		;    *code -= 32749
30$:
	xor	cx, ax			;*index ^= *code
	dec	dx
	jns	15$
exit:
	and	cx, 0x7FFF		;*index &= 0x7FFF
	lds	si, code		;Store local versions of code/index.
	mov	ds:[si], ax		; 
	lds	si, index
	mov	ds:[si], cx
	mov	ax, IC_RET_OK		;return (OKRET)
	.leave
	ret
ifdef __BORLANDC__
SLFUN	endp
else
SLfun	endp
endif
FixedCode	ends
