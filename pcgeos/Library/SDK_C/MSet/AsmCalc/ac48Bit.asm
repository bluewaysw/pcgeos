COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990, 1993 -- All Rights Reserved

PROJECT:	PC SDK
MODULE:		Sample Library -- Mandelbrot Set Library
FILE:		calc48Bit.asm

AUTHOR:		Doug Fults, May 15, 1991

ROUTINES:
	Name			Description
	----			-----------
FP48CalcPoint	INT	Calculate one point of the MSet
FP48MultCommon	INT	Common code for multiply routines
IntNormalize	INT	Normalize result of multiply
FP48MultTimes2	INT	Multiply FixNums and shl 1
IntUMult	INT	Multiply two unsigned FixNums
FP48Mult	INT	Multiply two signed FixNums
FP48Square	INT	Square two FixNums
FP48Add		INT	Add two FixNums
FP48Sub		INT	Subtract two FixNums
FP48TOAscii	INT	Convert FixNum to ascii string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/15/91		Initial revision
	dubois	8/25/93  	Tweaked for SDK

DESCRIPTION:
	Calculation routines for in-register 48-bit fixed-point operation.
		

	$Id: ac48Bit.asm,v 1.1 97/04/07 10:43:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalcThreadResource		segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIXNUMUMULT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	c = a * b
		Note: all of the pointers must be in the same segment!

C FUNCTION:	FixNumUMult

C DECLARATION:	extern void
		_far _pascal FixNumUMult(FixNum _far* c,
					FixNum _far* a,
					FixNum _far* b);

PSEUDO CODE/STRATEGY:
	EC: check that all pointers are in same segment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention		;sets the calling conventions
FIXNUMUMULT	proc	far		c:fptr, a:fptr, b:fptr
	uses	ds, si, di
	.enter

EC<	mov	ax, a.segment				>
EC<	cmp	ax, b.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>
EC<	cmp	ax, c.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>

	mov	si, a.offset
	mov	bx, b.offset
	lds	di, c
	call	IntUMult	;destroys ax-dx

	.leave
	ret
FIXNUMUMULT	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIXNUMUMULTTIMES2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	c = a * b * 2
		Note: all of the pointers must be in the same segment!

C FUNCTION:	FixNumUMultTimes2

C DECLARATION:	extern void
		_far _pascal FixNumUMultTimes2(FixNum _far* c,
					FixNum _far* a,
					FixNum _far* b);

PSEUDO CODE/STRATEGY:
	EC: check that all pointers are in same segment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
FIXNUMUMULTTIMES2	proc	far		c:fptr, a:fptr, b:fptr
	uses	ds, si, di
	.enter

EC<	mov	ax, a.segment				>
EC<	cmp	ax, b.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>
EC<	cmp	ax, c.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>

	mov	si, a.offset
	mov	bx, b.offset
	lds	di, c
	call	FP48MultTimes2	;destroys ax-dx

	.leave
	ret
FIXNUMUMULTTIMES2	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIXNUMSUB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	c = a - b
		Note: all of the pointers must be in the same segment!

C FUNCTION:	FixNumSub

C DECLARATION:	extern void
		_far _pascal FixNumSub(FixNum _far* c,
					FixNum _far* a,
					FixNum _far* b);

PSEUDO CODE/STRATEGY:
	EC: check that all pointers are in same segment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
FIXNUMSUB	proc	far		c:fptr, a:fptr, b:fptr
	uses	ds, si, di
	.enter

EC<	mov	ax, a.segment				>
EC<	cmp	ax, b.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>
EC<	cmp	ax, c.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>

	mov	si, a.offset
	mov	bx, b.offset
	lds	di, c
	call	FP48Sub		;destroys ax

	.leave
	ret
FIXNUMSUB	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIXNUMADD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	c = a + b
		Note: all of the pointers must be in the same segment!

C FUNCTION:	FixNumAdd

C DECLARATION:	extern void
		_far _pascal FixNumAdd(FixNum _far* c,
					FixNum _far* a,
					FixNum _far* b);

PSEUDO CODE/STRATEGY:
	EC: check that all pointers are in same segment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
FIXNUMADD	proc	far		c:fptr, a:fptr, b:fptr
	uses	ds, si, di
	.enter

EC<	mov	ax, a.segment				>
EC<	cmp	ax, b.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>
EC<	cmp	ax, c.segment				>
EC<	ERROR_NE ERROR_FIXNUMS_NOT_IN_SAME_SEGMENT	>

	mov	si, a.offset
	mov	bx, b.offset
	lds	di, c
	call	FP48Add		;destroys ax

	.leave
	ret
FIXNUMADD	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIXNUMTOASCII
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a fixed-point number to a null-terminated, ascii
		string of the form -n.mmmmm.

C FUNCTION:	FixNumToAscii

C DECLARATION:	extern void
		_far _pascal FixNumUMult(FixNum _far*	num,
					FixNum _far*	buffer,
					word		bufSiz);

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
FIXNUMTOASCII	proc	far		num:fptr,
					buffer:fptr,
					bufSiz:word
	uses	es, ds, si, di
	.enter

	lds	si, num
	les	di, buffer
	mov	cx, bufSiz

	call	FP48TOAscii

	.leave
	ret
FIXNUMTOASCII	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48CalcPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine count value for point in the set

CALLED BY:	MSCalcThread

PASS:		ds		- ptr to locked MSSetState block
		ds:[MSS_vars].M48_A, M48_B
				- point to determine value for

RETURN:		ax		- value of point

DESTROYED:	bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Starts  with x, y at (0,0), then calculates new point as
	(x^2 - y^2 + a, 2xy + b), until x^2 + y^2 >= 4 or a maximum # of
	iterations is reached:

	X = A;
	Y = B;
	count = 1;
	loop {
		xSquared = X * X;
		ySquared = Y * Y;
		distanceSquared = xSquared + ySquared;
		if distanceSquared >=4, DONE;
		product	= X * Y;
		product = 2 * product;
		X = xSquared - ySquared;
		X = X + A;
		Y = product + B;
		count ++;
		if count >= maxCount, DONE;
	}


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/93  	Tweaked for SDK
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FP48CalcPoint	proc	near
				;	X = A;
		mov	si, offset MSCP_vars.MN_A.MSN_48bit
		mov	di, offset MSCP_vars.MN_X.MSN_48bit
		call	FP48Copy
				;	Y = B;
		mov	si, offset MSCP_vars.MN_B.MSN_48bit
		mov	di, offset MSCP_vars.MN_Y.MSN_48bit
		call	FP48Copy
				;	count = 1;
		mov	ds:[MSCP_count], 1
				;	loop {
MI_10:
				;		xSquared = X * X;
		mov	si, offset MSCP_vars.MN_X.MSN_48bit
		mov	di, offset MSCP_vars.MN_x2.MSN_48bit
		call	FP48Square
		jc	MI_90	; If overflow, we must be done
				;		ySquared = Y * Y;
		mov	si, offset MSCP_vars.MN_Y.MSN_48bit
		mov	di, offset MSCP_vars.MN_y2.MSN_48bit
		call	FP48Square
		jc	MI_90	; If overflow, we must be done
				;	distanceSquared = xSquared + ySquared;
			;in-line expanded to avoid extra moves and cycles
			;caused by indexing, and to avoid need for
			;distanceSquared variable itself
		add	cx, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_low
		adc	bx, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_middle
		adc	ax, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_high
				;		if distanceSquared >=4, DONE;
	;
	; Just look at the integer part of the result, which is in the
	; high four bits of AH. Since the result must be positive, we
	; treat the numbers as unsigned, giving us an extra bit of
	; integer. If the final addition generated a carry, or the
	; highest byte is unsignedly greater than 40h, the distance
	; is big enough that we can say it's gone.
	; 
		jc	MI_90
		cmp	ah, 4 SHL 4
		jae	MI_90
				;		product	= 2 * X * Y;
		mov	si, offset MSCP_vars.MN_X.MSN_48bit
		mov	bx, offset MSCP_vars.MN_Y.MSN_48bit
		mov	di, offset MSCP_vars.MN_prod.MSN_48bit
		call	FP48MultTimes2
				;		Y = product + B
		add	cx, ds:[MSCP_vars].MN_B.MSN_48bit.FN_low
		adc	bx, ds:[MSCP_vars].MN_B.MSN_48bit.FN_middle
		adc	ax, ds:[MSCP_vars].MN_B.MSN_48bit.FN_high
		mov	ds:[MSCP_vars].MN_Y.MSN_48bit.FN_low, cx
		mov	ds:[MSCP_vars].MN_Y.MSN_48bit.FN_middle, bx
		mov	ds:[MSCP_vars].MN_Y.MSN_48bit.FN_high, ax
			;		X = xSquared - ySquared + A;
			;in-line expanded to avoid extra moves and extra cycles
			;caused by indexing.
		mov	ax, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_low
		sub	ax, ds:[MSCP_vars].MN_y2.MSN_48bit.FN_low
		mov	bx, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_middle
		sbb	bx, ds:[MSCP_vars].MN_y2.MSN_48bit.FN_middle
		mov	cx, ds:[MSCP_vars].MN_x2.MSN_48bit.FN_high
		sbb	cx, ds:[MSCP_vars].MN_y2.MSN_48bit.FN_high
		add	ax, ds:[MSCP_vars].MN_A.MSN_48bit.FN_low
		adc	bx, ds:[MSCP_vars].MN_A.MSN_48bit.FN_middle
		adc	cx, ds:[MSCP_vars].MN_A.MSN_48bit.FN_high
		mov	ds:[MSCP_vars].MN_X.MSN_48bit.FN_low, ax
		mov	ds:[MSCP_vars].MN_X.MSN_48bit.FN_middle, bx
		mov	ds:[MSCP_vars].MN_X.MSN_48bit.FN_high, cx
				;		count ++;
		mov	ax, ds:[MSCP_count]
		inc	ax
		mov	ds:[MSCP_count], ax
				;		if count >= maxDwell, DONE;
		cmp	ax, ds:[MSCP_maxDwell]
		jae	MI_93
				;	} loop
		jmp	MI_10
MI_90:
		mov	ax, ds:[MSCP_count]
MI_93:
		ret
FP48CalcPoint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48MultCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer multiply
		Multiplies two three-word unsigned integers.
		Caller MUST set up local variables.

CALLED BY:	GLOBAL
		IntUMult, FP48Mult, FP48MultTimes2

PASS:		dx	= low word of factor1
		inherited locals:
			factor1		local	FixNum
			factor2		local	FixNum
			remlow		local	word			

RETURN:		DI:BX:CX:SI:remlow	= unnormalized result.

DESTROYED:	DX, AX

PSEUDO CODE/STRATEGY:
	the .enter inherit directive allows the procedure to use the local
	variables of the preceding stack frame.  These locals are assumed to
	be set up exactly as FP48Mult sets them up.
	
	Note that one may not inherit and define new local variables in the
	same stack frame -- any locals that might be needed should be
	declared in the inherited frame.  The ForceRef macro is useful in
	getting rid of the "unreferenced symbol" warnings that esp will give
	as a result.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	Adam	4/1/89		Optimized by keeping result in registers
	dubois	8/25/93  	Added .enter inherit support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP48MultCommon	proc	near

	.enter inherit FP48Mult

	;
	; In the following multiplications, DX contains one factor,
	; AX the other. The result is kept in DI:BX:CX:SI:remlow
	;
	;
	; low1 * low2
	;
		mov	ax, ss:factor2.FN_low
		mul	dx
	;
	; No need to store AX since it can't possibly affect the
	; result (nothing gets added to it or shifted out of it)
	; 
		mov	ss:remlow, dx
		clr	si
		mov	cx, si
		mov	bx, si
		mov	di, si
		
	;
	; low1 * middle2
	; 
		mov	ax, ss:factor2.FN_middle
		mov	dx, ss:factor1.FN_low
		mul	dx
		add	ss:remlow, ax
		adc	si, dx
		adc	cx, 0
		adc	bx, 0
		adc	di, 0
		
	;
	; low1 * high2
	; 
		mov	ax, ss:factor2.FN_high
		mov	dx, ss:factor1.FN_low
		mul	dx
		add	si, ax
		adc	cx, dx
		adc	bx, 0
		adc	di, 0
		
	;
	; middle1 * low2
	; 
		mov	ax, ss:factor2.FN_low
		mov	dx, ss:factor1.FN_middle
		mul	dx
		add	ss:remlow, ax
		adc	si, dx
		adc	cx, 0
		adc	bx, 0
		adc	di, 0

	;
	; middle1 * middle2
	; 
		mov	ax, ss:factor2.FN_middle
		mov	dx, ss:factor1.FN_middle
		mul	dx
		add	si, ax
		adc	cx, dx
		adc	bx, 0
		adc	di, 0
		
	;
	; middle1 * high2
	;
		mov	ax, ss:factor2.FN_high
		mov	dx, ss:factor1.FN_middle
		mul	dx
		add	cx, ax
		adc	bx, dx
		adc	di, 0
		
	;
	; high1 * low2
	;
		mov	ax, ss:factor2.FN_low
		mov	dx, ss:factor1.FN_high
		mul	dx
		add	si, ax
		adc	cx, dx
		adc	bx, 0
		adc	di, 0
		
	;
	; high1 * middle2
	;
		mov	ax, ss:factor2.FN_middle
		mov	dx, ss:factor1.FN_high
		mul	dx
		add	cx, ax
		adc	bx, dx
		adc	di, 0
		
	;
	; high1 * high2
	;
		mov	ax, ss:factor2.FN_high
		mov	dx, ss:factor1.FN_high
		mul	dx
		add	bx, ax
		adc	di, dx
	.leave
	ret
FP48MultCommon	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntNormalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize the result of FP48MultCommon

CALLED BY:	FP48MultTimes2, FP48Mult, IntUMult
PASS:		DI:BX:CX:SI	= four-word result
RETURN:		DI:BX:CX	= three-word normalized/rounded FixNum
DESTROYED:	SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IntNormalize	proc	near
	;
	; The multiplication gives us 8 bits of integer when we
	; only need four. Lose the top four bits of the result by
	; shifting the whole thing left four bits. Note that even
	; though these shifts drain the prefetch queue, they're still
	; faster than using multi-bit rotates and the masking they
	; would make necessary (this result was found empirically).
	;
		shl	si, 1
		rcl	cx, 1
		rcl	bx, 1
		rcl	di, 1
	
		shl	si, 1
		rcl	cx, 1
		rcl	bx, 1
		rcl	di, 1
			
		shl	si, 1
		rcl	cx, 1
		rcl	bx, 1
		rcl	di, 1	
		
		shl	si, 1
		rcl	cx, 1
		rcl	bx, 1
		rcl	di, 1	
		
		shl	si, 1	; Get rounding bit into CF
		adc	cx, 0	; Ripple it up through...
		adc	bx, 0
		adc	di, 0
		ret
IntNormalize	endp
		

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48MultTimes2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer multiply

		Multiplies two signed integers, then times 2
		Decimal point is 4 bits into mantissa value.

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C

RETURN:		C = 2 * A * B
		C also in AX:BX:CX

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
	Set up parameters on the stack for FP48MultCommon, which uses the
	.enter inherit directive.  For details, see that procedure.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	Adam	4/1/89		Optimized by keeping one factor in registers.
	dubois	8/25/93  	Added local variable support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FP48MultTimes2	proc	near

	factor1		local	FixNum		; Factor 1
	factor2		local	FixNum		; Factor 2
	remlow		local	word		; Low word of result

	ForceRef	remlow		; keep esp from complaining about
					; unreferenced symbols

	.enter
	;
	; Take absolute value of [SI], saving the sign away
	; 
		mov	dx, ds:[si].FN_low
		mov	cx, ds:[si].FN_middle
		mov	si, ds:[si].FN_high
		mov	ax, si	; Preserve sign bit
		tst	si
		jns	IMT2_10
	;
	; Negate the whole thing. NEG gives the opposite carry from
	; what we need, that's why they invented the CMC instruction.
	; 
		neg	dx
		not	cx
		not	si
		cmc
		adc	cx, 0
		adc	si, 0
IMT2_10:
	;
	; Save the result away
	; 
		mov	ss:factor2.FN_high, si
		mov	ss:factor2.FN_middle, cx
		mov	ss:factor2.FN_low, dx
		
	;
	; Do the same for [BX]
	;
		mov	dx, ds:[bx].FN_low
		mov	cx, ds:[bx].FN_middle
		mov	si, ds:[bx].FN_high

		xor	ax, si	; Figure sign bit of result
		push	ax	;  and save it for later

		tst	si
		jns	IMT2_20
		neg	dx
		not	cx	; Doesn't nuke CF
		not	si
		cmc
		adc	cx, 0
		adc	si, 0
IMT2_20:
		mov	ss:factor1.FN_high, si
		mov	ss:factor1.FN_middle, cx
		mov	ss:factor1.FN_low, dx

		push	di	; Save destination address

	;
	; Perform the multiplication
	;
		call	FP48MultCommon
	;
	; Here's the extra multiply by 2
	;
		shl	si, 1
		rcl	cx, 1
		rcl	bx, 1
		rcl	di, 1	

		call	IntNormalize		

		mov	ax, di		; Shift high word into ax and...
		pop	di		;  recover destination
		
		pop	dx		; Fetch desired sign 
		tst	dx
		jns	IMT2_90		; Already positive -- do nothing
	;
	; Need to negate the number. To remind you, NEG gives
	; us the opposite CF than we want, hence the CMC. Also,
	; NOT doesn't nuke the carry.
	;
		neg	cx
		not	bx
		not	ax
		cmc
		adc	bx, 0
		adc	ax, 0
IMT2_90:
	;
	; Store the significant words
	; 
		mov	ds:[di].FN_low, cx
		mov	ds:[di].FN_middle, bx
		mov	ds:[di].FN_high, ax

	.leave		
	ret
FP48MultTimes2	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntUMult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer multiply

		Multiplies two unsigned integers.

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C

RETURN:		C = A * B
		C also in AX:BX:CX

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	Adam	4/1/89		Optimized by keeping one factor in registers.
	dubois	8/25/93  	Added local variable support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IntUMult	proc	near

	factor1		local	FixNum		; Factor 1
	factor2		local	FixNum		; Factor 2
	remlow		local	word		; Low word of result

	ForceRef	remlow		; keep esp from complaining about
					; unreferenced symbols

	.enter

	;
	; Set up stack for FP48MultCommon. We use DX for the copies
	; as FP48MultCommon expects DX to contain the low word of
	; factor 1 (there's no advantage to using AX either)
	;
		mov	dx, ds:[si].FN_low
		mov	ss:factor2.FN_low, dx
		mov	dx, ds:[si].FN_middle
		mov	ss:factor2.FN_middle, dx
		mov	dx, ds:[si].FN_high
		mov	ss:factor2.FN_high, dx
		
		mov	dx, ds:[bx].FN_high
		mov	ss:factor1.FN_high, dx
		mov	dx, ds:[bx].FN_middle
		mov	ss:factor1.FN_middle, dx
		mov	dx, ds:[bx].FN_low
		mov	ss:factor1.FN_low, dx
		
		push	di		; Save destination
		call	FP48MultCommon	; Multiply
		call	IntNormalize	; Normalize and round
		mov	ax, di		; Shift high word into ax and...
		pop	di		;  recover destination
		
	;
	; Store the significant words
	; 
		mov	ds:[di].FN_low, cx
		mov	ds:[di].FN_middle, bx
		mov	ds:[di].FN_high, ax
		
	.leave
	ret
IntUMult	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48Mult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	FixNum multiply

		Multiplies two signed FixNums

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C

RETURN:		C = A * B
		C also in AX:BX:CX

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	Adam	4/1/89		Optimized by keeping one factor in registers.
	dubois	8/25/93  	Added local variable support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
FP48Mult		proc	near

	factor1		local	FixNum		; Factor 1
	factor2		local	FixNum		; Factor 2
	remlow		local	word		; Low word of result

	ForceRef	remlow		; keep esp from complaining about
					; unreferenced symbols

	.enter

	;
	; Take absolute value of [SI], saving the sign away
	; 
		mov	dx, ds:[si].FN_low
		mov	cx, ds:[si].FN_middle
		mov	si, ds:[si].FN_high
		mov	ax, si	; Preserve sign bit
		tst	si
		jns	IM_10
	;
	; Negate the whole thing. NEG gives the opposite carry from
	; what we need, that's why they invented the CMC instruction.
	; 
		neg	dx
		not	cx
		not	si
		cmc
		adc	cx, 0
		adc	si, 0
IM_10:
	;
	; Save the result away
	; 
		mov	ss:factor2.FN_high, si
		mov	ss:factor2.FN_middle, cx
		mov	ss:factor2.FN_low, dx
		
	;
	; Do the same for [BX]
	;
		mov	dx, ds:[bx].FN_low
		mov	cx, ds:[bx].FN_middle
		mov	si, ds:[bx].FN_high

		xor	ax, si	; Figure sign bit of result
		push	ax	;  and save it for later

		tst	si
		jns	IM_20
		neg	dx
		not	cx	; Doesn't nuke CF
		not	si
		cmc
		adc	cx, 0
		adc	si, 0
IM_20:
		mov	ss:factor1.FN_high, si
		mov	ss:factor1.FN_middle, cx
		mov	ss:factor1.FN_low, dx

		push	di	; Save destination address
		call	FP48MultCommon
		call	IntNormalize
		mov	ax, di		; Shift high word into ax and...
		pop	di		;  recover destination
		
		pop	dx		; Fetch desired sign 
		tst	dx
		jns	IM_90		; Already positive -- do nothing
	;
	; Need to negate the number. To remind you, NEG gives
	; us the opposite CF than we want, hence the CMC. Also,
	; NOT doesn't nuke the carry.
	;
		neg	cx
		not	bx
		not	ax
		cmc
		adc	bx, 0
		adc	ax, 0
IM_90:
	;
	; Store the significant words
	; 
		mov	ds:[di].FN_low, cx
		mov	ds:[di].FN_middle, bx
		mov	ds:[di].FN_high, ax
		
		mov	sp, bp
		pop	bp

	.leave
	ret
FP48Mult	endp
ForceRef FP48Mult		;no other proc currently uses FP48Mult

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48Square
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Square a three-word fixed point number

CALLED BY:	MSCalcIterate
PASS:		DS:SI	= FixNum to square
		DS:DI	= Place to store resulting FixNum
RETURN:		DS:[DI]	= ds:[SI]**2
		AX:BX:CX also contain result
		Carry set on overflow
DESTROYED:	AX, BX, CX, DX, SI

PSEUDO CODE/STRATEGY:
       In a normal multiplication, we'd need to multiply each word of the
       number by each other word, giving a total of 9 multiplications.
       However, three of them (low * middle, low * high, middle * high) are
       repeated in the case of a square, so we just multiply the result
       of each of these multiplications by 2 (via a shift) before adding
       them to the final result.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/26/89		Initial version
	ardeb	4/ 1/89		Optimized to keep result in registers
	dubois	8/25/93  	Added local variable support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP48Square	proc	near

	absFac	local	FixNum		;abs(factor)
	remlow	local	word		;low word of result
	
	.enter

	;
	; Load number into registers.
	;
		mov	dx, ds:[si].FN_low
		mov	bx, ds:[si].FN_middle
		mov	si, ds:[si].FN_high

	;
	; Make sure the number is positive (don't need to remember
	; what sign it was, since all squares are positive)
	; 
		tst	si
		jns	IS_10		; skip if not
					; Negate the number
		neg	dx
		not	bx
		not	si
		cmc			; NEG sets carry exactly opposite of
					; what we want (sets clear if operand
					; is 0)
		adc	bx, 0		; Ripple carry
		adc	si, 0		; ...
IS_10:
		mov	ss:absFac.FN_low, dx
		mov	ss:absFac.FN_middle, bx
		mov	ss:absFac.FN_high, si

	;
	; In the following multiplications, DX contains one factor,
	; AX the other. The result is kept in DI:BX:CX:SI:remlow
	;
		push	di	; Save destination address

	;
	; First low * low
	;
		
		mov	ax, dx			; Multiply by low word
		mul	dx			; multiply to dx:ax
	;
	; Just store this result to initialize the dest. Note
	; we don't store AX as it can't possibly affect the result
	; since nothing gets added to it and nothing gets shifted
	; out of it.
	;
		mov	ss:remlow, dx
		clr	si
		mov	cx, si
		mov	bx, si
		mov	di, si

	;
	; Now low * middle
	;
		mov	dx, ss:absFac.FN_low
		mov	ax, ss:absFac.FN_middle
		mul	dx
	; times 2 since term occurs twice
		shl	ax, 1
		rcl	dx, 1
		adc	cx, 0	; Add in carry from shift while we've got it.
		
		add	ss:remlow, ax
		adc	si, dx
		adc	cx, 0
		adc	bx, 0
		adc	di, 0

	;
	; Now low * high
	;
		mov	dx, ss:absFac.FN_low
		mov	ax, ss:absFac.FN_high
		mul	dx
	; times 2 since term occurs twice
		shl	ax, 1
		rcl	dx, 1
		adc	bx, 0	; Add in carry from shift while we've got it
		add	si, ax
		adc	cx, dx
		adc	bx, 0
		adc	di, 0

	;
	; Now middle * middle -- we've not done that one yet :)
	;
		mov	dx, ss:absFac.FN_middle
		mov	ax, dx
		mul	dx
		add	si, ax
		adc	cx, dx
		adc	bx, 0
		adc	di, 0

	;
	; middle * high
	;
		mov	dx, ss:absFac.FN_middle
		mov	ax, ss:absFac.FN_high
		mul	dx
	; times 2 since term occurs twice
		shl	ax, 1
		rcl	dx, 1
		adc	di, 0	; Add in carry from shift while we've got it
		add	cx, ax
		adc	bx, dx
		adc	di, 0

	;
	; high * high
	;
		mov	dx, ss:absFac.FN_high
		mov	ax, dx
		mul	dx
		add	bx, ax
		adc	di, dx

	;
	; Check for overflow. Since the high four bits are going to
	; be lost, overflow occurs if they aren't the same as bit
	; 11 of di, hence the comparisons being performed...At the
	; end of the tests, al indicates if the carry should be
	; set when we return.
	; 
		mov	dx, di
		and	dx, 0f800h	; Clear AL at the same time...
		jz	IS_ok
		cmp	dh, 0f8h
		je	IS_ok
		inc	dx		; Badness
IS_ok:
		call	IntNormalize

		mov	ax, di		; Place high word in ax
		pop	di		;  and recover destination
		
		mov	ds:[di].FN_low, cx
		mov	ds:[di].FN_middle, bx
		mov	ds:[di].FN_high, ax
		
	;
	; Set carry flag if overflow occurred
	; 
		shr	dx, 1

	.leave
	ret
FP48Square	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48Add
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer Addition

		Adds two signed integers.  Decimal point is 4 bits
		into mantissa value.

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C


RETURN:		C = A + B

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FP48Add		proc	near
		mov	ax, ds:[si].FN_low		; Add values
		add	ax, ds:[bx].FN_low
		mov	ds:[di].FN_low, ax		; & store
		mov	ax, ds:[si].FN_middle		; Add values
		adc	ax, ds:[bx].FN_middle
		mov	ds:[di].FN_middle, ax		; & store
		mov	ax, ds:[si].FN_high		; Add values
		adc	ax, ds:[bx].FN_high
		mov	ds:[di].FN_high, ax		; & store
		ret
FP48Add		endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48Sub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer Subtraction

		Subtracts two signed integers.  Decimal point is 4 bits
		into mantissa value.

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C

	mantissaSize	- # of words in mantissa we're multiplying

RETURN:		C = A - B

DESTROYED:	reg	- description

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FP48Sub		proc	near
		mov	ax, ds:[si].FN_low		; Add values
		sub	ax, ds:[bx].FN_low
		mov	ds:[di].FN_low, ax		; & store
		mov	ax, ds:[si].FN_middle		; Add values
		sbb	ax, ds:[bx].FN_middle
		mov	ds:[di].FN_middle, ax		; & store
		mov	ax, ds:[si].FN_high		; Add values
		sbb	ax, ds:[bx].FN_high
		mov	ds:[di].FN_high, ax		; & store
		ret
FP48Sub		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48Copy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a fixed-point number

CALLED BY:	EXTERNAL
PASS:		DS:[SI]	= FixNum to copy
		DS:[DI]	= FixNum to which to copy it
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP48Copy		proc	near
		mov	ax, ds:[si].FN_low	; copy integer
		mov	ds:[di].FN_low, ax
		mov	ax, ds:[si].FN_middle
		mov	ds:[di].FN_middle, ax
		mov	ax, ds:[si].FN_high
		mov	ds:[di].FN_high, ax
		ret
FP48Copy		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP48TOAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a fixed-point number to a null-terminated, ascii
		string of the form -n.mmmmm.

CALLED BY:	EXTERNAL
PASS:		DS:SI	= number to convert
		ES:DI	= address of buffer for result. Should be
			  18 characters long, but may be shorter.
		CX	= size of the buffer - 1 (1 is for null byte)
RETURN:		Nothing
DESTROYED:	AX, BX, CX, DX, SI, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP48TOAscii	proc	near

	curFixNum	local	FixNum
	.enter

		cld

	;
	; Figure sign of number and make non-negative
	;
		mov	bx, ds:[si].FN_high
		mov	dx, ds:[si].FN_middle
		mov	si, ds:[si].FN_low
		tst	bx
		jns	afterNegate
	;
	; Store a leading - sign
	;
		mov	al, '-'
		stosb
		dec	cx
		jz	ITADone
	;
	; Negate the number
	;
		neg	si
		not	dx
		not	bx
		cmc
		adc	dx, 0
		adc	bx, 0
afterNegate:
	;
	; Deal with integer part and decimal point
	;
		mov	al, bh
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		add	al, '0'
		stosb
		dec	cx
		jz	ITADone
		mov	al, '.'
		stosb
		dec	cx
		jz	ITADone
ITALoop:
	;
	; For this loop, since we're always multiplying by 10, which
	; has no fractional part, life is much simpler than it ought
	; to be.
	;
		and	bh, 0fh		; Trim off integer portion
		
	
	;
	; If all words now 0, stop right where we are.
	;
		mov	ax, si
		or	ax, dx
		or	ax, bx
		jz	ITADone

	;
	; Save current number for addition
	;
		mov	curFixNum.FN_low, si
		mov	curFixNum.FN_middle, dx
		mov	curFixNum.FN_high, bx
		
		shl	si, 1	; *2
		rcl	dx, 1
		rcl	bx, 1
		
		shl	si, 1	; *4
		rcl	dx, 1
		rcl	bx, 1
		
		add	si, curFixNum.FN_low	; *5
		adc	dx, curFixNum.FN_middle
		adc	bx, curFixNum.FN_high
		
		shl	si, 1	; *10
		rcl	dx, 1
		rcl	bx, 1

	;
	; Convert integer portion to ascii
	;
		mov	al, bh
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		add	al, '0'
		stosb

		loop	ITALoop
ITADone:
		clr	al
		stosb

	.leave
	ret
FP48TOAscii	endp

CalcThreadResource		ends

