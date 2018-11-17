COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverRandom.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	Functions to generate random numbers.
		

	$Id: saverRandom.asm,v 1.1 97/04/07 10:44:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverRandomTemplate	segment	resource
;
; State for the random-number generator. This beast comes from the
; BSD random-number generator, which is supposed to be random in all 31
; bits it produces...
;
RAND_DEG	equ	31
RAND_SEP	equ	3
RAND_MULT	equ	1103515245
RAND_ADD	equ	12345

frontPtr	nptr.dword	randTbl[(RAND_SEP+1)*dword]
rearPtr		nptr.dword	randTbl[1*dword]
endPtr		nptr.dword	randTbl[(RAND_DEG+1)*dword]

randTbl		dword	3,	; generator type
			0x9a319039, 0x32d9c024, 0x9b663182, 0x5da1f342, 
			0xde3b81e0, 0xdf0a6fb5, 0xf103bc02, 0x48f340fb, 
			0x7449e56b, 0xbeb1dbb0, 0xab5c5918, 0x946554fd, 
			0x8c2e680f, 0xeb3d799f, 0xb11ee0b7, 0x2d436b86, 
			0xda672e2a, 0x1588ca88, 0xe369735d, 0x904f35f7, 
			0xd7158fd6, 0x6fa6f051, 0x616e6b96, 0xac94efdc, 
			0x36413f93, 0xc622c298, 0xf5a42ab8, 0x8a88d77b, 
				    0xf5ad9d0e, 0x8999220b, 0x27fb47b9

SaverRandomTemplate	ends

SaverRandomCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a random number

CALLED BY:	GLOBAL
PASS:		dx	= max for returned value
		bx	= token for random number generator
RETURN:		dx	= number between 0 and max-1
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		We assume we're using a type 3 random number generator here,
		so the code looks like this:
			*frontPtr += *rearPtr;
			i = (*frontPtr >> 1)&0x7fffffff;
			if (++frontPtr >= endPtr) {
				frontPtr = state;
				rearPtr += 1;
			} else if (++rearPtr >= endPtr) {
				rearPtr = state;
			}
			
			return(i % DL);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverRandom	proc	far
		uses	ds, cx, si, di
		.enter
		call	MemLock
		mov	ds, ax
		assume	ds:SaverRandomTemplate

		mov	si, ds:[frontPtr]
		mov	di, ds:[rearPtr]
		mov	ax, ({dword}ds:[di]).low
		mov	cx, ({dword}ds:[di]).high
		add	ax, ({dword}ds:[si]).low
		adc	cx, ({dword}ds:[si]).high
		mov	({dword}ds:[si]).low, ax
		mov	({dword}ds:[si]).high, cx
		
		shr	cx
		rcr	ax
		
		add	si, size dword
		add	di, size dword
		cmp	si, ds:[endPtr]
		jb	adjustRear
		mov	si, offset (randTbl[1*dword])
		jmp	storePtrs
adjustRear:
		cmp	di, ds:[endPtr]
		jb	storePtrs
		mov	di, offset (randTbl[1*dword])
storePtrs:
		mov	ds:[frontPtr], si
		mov	ds:[rearPtr], di

		mov	cx, dx		; ignore high word, to avoid painful
					;  divide. Since all the bits are
					;  random, we just make do with the
					;  low sixteen, thereby avoiding
					;  quotient-too-large faults
		clr	dx
		div	cx
		call	MemUnlock
		assume	ds:nothing
		.leave
		ret
SaverRandom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverSeedRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Seed the random number generator, using 128 bytes of state

CALLED BY:	(GLOBAL)
PASS:		dx:ax	= initial seed
		bx	= generator to change, or 0 to create new one
RETURN:		bx	= token to pass to SaverRandom
DESTROYED:	dx, ax

PSEUDO CODE/STRATEGY:
		state[0] = seed;
		for (i = 1; i < RAND_DEG; i++) {
			state[i] = 1103515245*state[i-1] + 12345;
		}
		frontPtr = &state[RAND_SEP];
		rearPtr = &state[0];
		for (i = 0; i < 10*RAND_DEG; i++) {
			SaverRandom();
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverSeedRandom	proc	far
		uses	si, di, cx, ds, es
		.enter
		tst	bx
		jnz	haveGenerator
		mov	bx, handle SaverRandomTemplate
		call	GeodeDuplicateResource

haveGenerator:
		push	ax
		call	MemLock
		mov	ds, ax
		mov	es, ax
		pop	ax

		assume	ds:SaverRandomTemplate
		
		mov	di, offset (randTbl[1*dword])
		mov	cx, RAND_DEG-1
		push	bx
seedLoop:
		mov	({dword}ds:[di]).low, ax
		mov	({dword}ds:[di]).high, dx
		add	di, size dword

	;
	; Perform a 32-bit unsigned multiply by RAND_MULT, leaving the result
	; in si:bx:
	;
	; 			h	mh	ml	l
	;ax*low(RAND_MULT)			x	x
	;dx*low(RAND_MULT)		x	x
	;ax*high(RAND_MULT)		x	x
	;dx*high(RAND_MULT)	x	x
	;
	; The highest two words are discarded, which means we don't even have
	; to multiply dx by high(RAND_MULT).
	; 
		push	ax
		push	dx
		mov	dx, RAND_MULT AND 0xffff
		mul	dx
		xchg	bx, ax		; bx <- low(result)
		mov	si, dx		; si <- partial high(result)

		pop	ax		; ax <- original dx
		mov	dx, RAND_MULT AND 0xffff
		mul	dx
		add	si, ax		; high(result) += low(dx*low(RAND_MULT))

		pop	ax		; ax <- original ax
		mov	dx, RAND_MULT / 65536
		mul	dx
		add	si, ax		; high(result)+=low(high(RAND_MULT)*ax)
	;
	; Place result in the proper registers and add in the additive factor.
	; 
		mov	dx, si
		mov	ax, bx
		add	ax, RAND_ADD
		adc	dx, 0
		loop	seedLoop
		pop	bx
	;
	; Store the final result.
	; 
		mov	({dword}ds:[di]).low, ax
		mov	({dword}ds:[di]).high, dx

	;
	; Initialize the pointers.
	; 
		mov	ds:[frontPtr], offset (randTbl[(RAND_SEP+1)*dword])
		mov	ds:[rearPtr], offset (randTbl[1*dword])
		
	;
	; Now randomize the state according to the degree of the
	; polynomial we're using.
	; 
		mov	cx, 10*RAND_DEG
initLoop:
		mov	dx, 0xffff
		call	SaverRandom
		loop	initLoop
		
		call	MemUnlock
		.leave
		ret
SaverSeedRandom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverEndRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish using a random-number generator.

CALLED BY:	(GLOBAL)
PASS:		bx	= token returned by SaverSeedRandom
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverEndRandom	proc	far
		.enter
		call	MemFree
		.leave
		ret
SaverEndRandom	endp


SaverRandomCode	ends
