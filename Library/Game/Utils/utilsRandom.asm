COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsRandom.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	GameSeedRandom		Seed the random number generator, using 128
				bytes of state

	GameRandom		Return a random number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: utilsRandom.asm,v 1.1 97/04/04 18:04:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



RandomCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameSeedRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Seed the random number generator, using 128 bytes of state

CALLED BY:	
PASS:		dx:ax	= initial seed

RETURN:		nothing

DESTROYED:	dx, ax

PSEUDO CODE/STRATEGY:
		state[0] = seed;
		for (i = 1; i < RAND_DEG; i++) {
			state[i] = 1103515245*state[i-1] + 12345;
		}
		frontPtr = &state[RAND_SEP];
		rearPtr = &state[0];
		for (i = 0; i < 10*RAND_DEG; i++) {
			GameRandom();
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSeedRandom	proc	far
		uses	si, di, bx, cx, ds
		.enter
		mov	bx, handle dgroup	;Do this so there is no segment
		call	MemDerefDS		; relocs to dgroup (so the
						; dgroup resource is 
						; discardable on XIP platforms)

		mov	di, offset (randTbl[1*dword])
		mov	cx, RAND_DEG-1
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
		call	GameRandom
		loop	initLoop
		.leave
		ret
GameSeedRandom	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a random number

CALLED BY:	GLOBAL

PASS:		dx	= max for returned value

RETURN:		dx	= number between 0 and max-1

DESTROYED:	nothing 

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
GameRandom	proc	far
		uses	ds, cx, si, di, ax, bx
		.enter
		mov	bx, handle dgroup	;Do this so there is no segment
		call	MemDerefDS		; relocs to dgroup (so the
						; dgroup resource is 
						; discardable on XIP platforms)
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
		.leave
		ret
GameRandom	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAMERANDOM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a random number

C DECLARATION:
		extern word _pascal GameRandom(word maxValue);

 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
global GAMERANDOM:far
GAMERANDOM	proc	far
	C_GetOneWordArg	dx, bx,ax		;DX <- max
	call	GameRandom
	mov_tr	ax, dx				;AX <- random number
	ret
GAMERANDOM	endp


RandomCode	ends
