COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	socket
MODULE:		network utilities library
FILE:		random.asm

AUTHOR:		Eric Weber, Jul 24, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT NetInitRandom           Initialize the random seed

    INT NetGenerateRandom32     Generates a 32bit random number

    INT NETGENERATERANDOM8      C stub for NetGenerateRandom8

    INT NetGenerateRandom8      Return a 8 bit random number between 0 and
				DL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/24/95   	Initial revision


DESCRIPTION:
	
		

	$Id: random.asm,v 1.1 97/04/05 01:25:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

randomSeed	word

idata	ends

AddressCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetInitRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the random seed

CALLED BY:	NetUtilsEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetInitRandom	proc	far
		uses	ax,bx,ds
		.enter
	;
	; initialize random number generator
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		call	TimerGetCount		; bxax = counter
		mov	ds:[randomSeed], ax
		
		.leave
		ret
NetInitRandom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGenerateRandom32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates a 32bit random number

CALLED BY:	Various discovery routines
PASS:		nothing  (es:[randomSeed] should be initialized)
RETURN:		dx.ax = 32bit random number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGenerateRandom32	proc	far
	.enter
	mov	dl, 255		; 2^8=256
	call	NetGenerateRandom8
	mov	al, dl
	mov	dl, 255
	call	NetGenerateRandom8
	mov	ah, dl
	mov	dl, 255
	call	NetGenerateRandom8
	mov	dh, dl
	mov	dl, 255
	call	NetGenerateRandom8

	.leave
	ret
NetGenerateRandom32	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	NetGenerateRandom8

C DECLARATION:	
	extern int _pascal NetGenerateRandom8(int limit);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	high byte of limit is ignored, so please don't try passing 256

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/24/95		Initial Revision

------------------------------------------------------------------------------@
SetGeosConvention
NETGENERATERANDOM8	proc	far	limit:word
		.enter
		mov	dl, limit.low
		call	NetGenerateRandom8	; dx = random value
		mov	ax,dx
		.leave
		ret
NETGENERATERANDOM8	endp
SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			NetGenerateRandom8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a 8 bit random number between 0 and DL

CALLED BY:	
PASS:		DL	= max for returned number
RETURN:		DL	= number between 0 and DL
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This random number generator is not a very good one; it is sufficient
	for a wide range of tasks requiring random numbers (it will work
	fine for shuffling, etc.), but if either the "randomness" or the
	distribution of the random numbers is crucial, you may want to look
	elsewhere.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/11/89		Initial version
	jon	10/90		Customized for GameClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGenerateRandom8	proc	far
		uses	ax, bx, cx, es
		.enter
	;
	; get dgroup
	;
		tst	dl
		jz	done
		mov	bx, handle dgroup
		call	MemDerefES
	;
	; get the seed and mangle it
	;
		mov	cx, dx
		mov	ax, es:[randomSeed]
		mov	dx, 4e6dh
		mul	dx
		mov	es:[randomSeed], ax
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		sar	dx, 1
		ror	ax, 1
		push	ax
		mov	al, 255
		mul	cl
		mov	dx, ax
		pop	ax
Random2:
		sub	ax, dx
		ja	Random2
		add	ax, dx
		div	cl
		clr	dx
		mov	dl, ah
done:
		.leave
		ret
NetGenerateRandom8	endp

AddressCode	ends
