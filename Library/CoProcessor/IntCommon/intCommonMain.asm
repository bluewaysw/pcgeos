COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		intCommonMain.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/15/92		Initial version.

DESCRIPTION:
	contains 80X87 code to do the same thing for each routine
	found in our floating point emulation library	

	$Id: intCommonMain.asm,v 1.1 97/04/04 17:48:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87SetChop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the coprocessor to chop results

CALLED BY:	(INTERNAL) Intel80X87Frac, Intel80X87Round,
       		Intel80X87_2ToTheX, Intel80X87TruncInternal
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87SetChop proc	near
control	local	word
	.enter
	fstcw	control
	fwait			; wait for it to arrive
	CheckHack <RC_CHOP eq 3 and width CW_ROUND_CONTROL eq 2>
	ornf	ss:[control], RC_CHOP shl offset CW_ROUND_CONTROL
	fldcw	control
	.leave
	ret
Intel80X87SetChop endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87SetNearest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the coprocessor to round results to nearest

CALLED BY:	(INTERNAL) Intel80X87Frac, Intel80X87Round,
       		Intel80X87_2ToTheX, Intel80X87TruncInternal
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87SetNearest proc	near
control	local	word
	.enter
	fstcw	control
	fwait			; wait for it to arrive
	CheckHack <RC_NEAREST_OR_EVEN eq 0 and width CW_ROUND_CONTROL eq 2>
	andnf	ss:[control], not mask CW_ROUND_CONTROL
	fldcw	control
	.leave
	ret
Intel80X87SetNearest endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87RestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore the hardware state

CALLED BY:	Math Library

PASS:		si = handle of state block

RETURN:		si = same handle

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87RestoreState	proc	far
	uses	ds, bx, ax
	.enter
	mov	bx, si
	call	MemLock
	mov	ds, ax
	frstor	ds:[0]
	fwait
	call	MemUnlock
	.leave
	ret
Intel80X87RestoreState	endp
	public	Intel80X87RestoreState

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87SaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save the chips state

CALLED BY:	Math Library

PASS:		si = handle of block to save state to

RETURN:		si = same handle

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87SaveState	proc	far
	uses	ds, bx, ax
	.enter
	mov	bx, si
	call	MemLock
	mov	ds, ax	
	fsave	ds:[0]
	fwait
	call	MemUnlock
	.leave
	ret
Intel80X87SaveState	endp
	public	Intel80X87SaveState

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetHardwareStackSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the size of the hardware stack

CALLED BY:	Math Library

PASS:		nothing

RETURN:		cx = size of hardware stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetHardwareStackSize	proc	far
	.enter
	mov	cx, INTEL_STACK_SIZE
	.leave
	ret
Intel80X87GetHardwareStackSize	endp
	public	Intel80X87GetHardwareStackSize


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetEnvSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the size of the environment (state) of the coprocessor

CALLED BY:	Math Library

PASS:		nothing

RETURN:		cx = size in bytes

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetEnvSize	proc	far
	.enter
	mov	cx, INTEL_ENV_SIZE
	.leave
	ret
Intel80X87GetEnvSize	endp
	public	Intel80X87GetEnvSize

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DoHardwareInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do an actual hardware init

CALLED BY:	Math Library

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DoHardwareInit	proc	far
	.enter
	finit
	fwait
	.leave
	ret
Intel80X87DoHardwareInit	endp
	public Intel80X87DoHardwareInit



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87SetStackSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the stack size

CALLED BY:	GLOBAL

PASS:		ax

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/19/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87SetStackSize	proc	far
	.enter
	cmp	ax, INTEL_STACK_SIZE
	jle	done
	sub	ax, INTEL_STACK_SIZE
	call	FloatSetStackSizeInternal
done:
	.leave
	ret
Intel80X87SetStackSize	endp
	public	Intel80X87SetStackSize

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Minus1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a negative one on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		return carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Minus1	proc	far
	
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld1
	fchs
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Minus1	endp
	public	Intel80X87Minus1


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87MinusPoint5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a -.5 on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		return carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

int87PointFive	dword	0x3f000000

Intel80X87MinusPoint5	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	cs:[int87PointFive]
	fchs
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87MinusPoint5 	endp
	public	Intel80X87MinusPoint5


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87LoadFPUConst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Co-routine to load a constant that's stored in the
		coprocessor.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87LoadFPUConst	proc	near
	push	bp
	mov	bp, sp
	push	ax
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	
	push	cs
	call	{word}ss:[bp+2]
	
	clr	ax
	call	FloatHardwareLeave
done:
	pop	ax
	pop	bp
	inc	sp
	inc	sp
	retf
Intel80X87LoadFPUConst		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Zero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a zero on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		return carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Zero	proc	far
	call	Intel80X87LoadFPUConst
	fldz
	ret
Intel80X87Zero	endp
	public	Intel80X87Zero


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Point5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a .5 on the FP stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Point5	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	cs:[int87PointFive]
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Point5	endp
	public	Intel80X87Point5


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87One
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a 1 on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87One	proc	far
	call	Intel80X87LoadFPUConst
	fld1
	ret
Intel80X87One	endp
	public	Intel80X87One



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87LoadIntConst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an integer constant onto the FP stack

CALLED BY:	(INTERNAL)
PASS:		at return address: word constant to load
RETURN:		carry set on overflow:
			ax	= error code
		carry clear if ok:
			ax	= destroyed
			constant on stack
		RETURNS TO CALLER'S CALLER
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87LoadIntConst proc near
		on_stack	retn
	pop	ax
		on_stack	ret=ax
	push	bx
	mov_tr	bx, ax
		on_stack	ret=bx
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fild	{word}cs:[bx]
	dec	ax		; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	pop	bx
	retf
Intel80X87LoadIntConst		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Two
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a two on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Two	proc	far
	call	Intel80X87LoadIntConst
	.unreached
int87Two	word	2
Intel80X87Two	endp
	public	Intel80X87Two



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Five
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a five on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Five	proc	far
	call	Intel80X87LoadIntConst
	.unreached
	word	5
Intel80X87Five	endp
	public	Intel80X87Five



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Ten
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a ten on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Ten	proc	far
	call	Intel80X87LoadIntConst
	.unreached
int87Ten	word	10
Intel80X87Ten	endp
	public	Intel80X87Ten



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87_3600
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a 3600 on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87_3600	proc	far
	call	Intel80X87LoadIntConst
	.unreached
	word	3600
Intel80X87_3600	endp
	public	Intel80X87_3600


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87_16384
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a 16384 pn the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87_16384	proc	far
	call	Intel80X87LoadIntConst
	.unreached
	word	16384
Intel80X87_16384	endp
	public	Intel80X87_16384


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87_86400
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a 86400 on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

eightysixThousandFourHundred	dword	86400
Intel80X87_86400	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fild	cs:[eightysixThousandFourHundred]
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87_86400	endp
	public	Intel80X87_86400


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Abs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = abs(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Abs	proc	far
	uses	ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fabs
	call	FloatHardwareLeave	; (ax still 0)
done:
	.leave
	ret
Intel80X87Abs	endp
	public	Intel80X87Abs


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Add
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st + st(1)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if any bad values
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Add	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
	fadd
	dec	ax		; ax <- -1 (one value popped)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Add	endp
	public	Intel80X87Add


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcCos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arccos(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if st a NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
	; the hardware only does an arctan so we must convert
	; arccos(x) = arctan(sqrt((1-x^2)/x^2))

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcCos	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
	
	; compute the arcsin
	call	Intel80X87ArcSinInternal
	
	; arccos(x) = pi/2 - arcsin(x)...

	fldpi
	fidiv	cs:[int87Two]
	fsubrp

	neg	ax 			; (ax still 2)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret						
Intel80X87ArcCos	endp
	public	Intel80X87ArcCos



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcCosh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arccosh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
	; the hardware only does ln, so convert
	;arccosh(x) = ln(x+sqrt(x^2 - 1))

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
 
Intel80X87ArcCosh	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld	st
	fmul	st		; st <- st^2
	fld1
	fsubp			; st <- st^2-1
	fsqrt
	faddp			; st <- x+sqrt(x^2 - 1)

	fldln2				
	fxch	st(1)
	fyl2x
	neg	ax		; (ax still 2)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcCosh	endp
	public	Intel80X87ArcCosh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcTanInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do an partial arctan making sure both args are positive

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	if neither or both args rae positive just do it
			else do it to the absolute values and change the sign
			of the answer

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/12/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcTanInternal	proc	near
	uses	bx, ax
	.enter
	clr	bx
	ftst
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_0	; see if its negative
	jz	tstTwo
	fabs
	inc	bx
tstTwo:
	fxch
	ftst
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_0	; see if its negative
	jz	unswap
	fabs
	dec	bx
unswap:
	fxch
	fpatan
	tst	bx
	jz	done
	fchs
done:
	.leave
	ret
Intel80X87ArcTanInternal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcSinInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the arcsin of st

CALLED BY:	(INTERNAL) Intel80X87ArcSin, Intel80X87ArcCos
PASS:		st	= number of which to take arcsin
		2 slots in fpu stack reserved
RETURN:		st	= arcsin(st)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87ArcSinInternal proc	near
	.enter
EC <	call	Intel80X87Check1Arg				>
   	fld	st			; (fp: x x)
	fmul	st, st(1)		; (fp: x x^2)
	fld1				; (fp: x x^2 1)
	fsubrp				; (fp: x 1-x^2)
	fsqrt				; (fp: x sqrt(1-x^2))
	call	Intel80X87ArcTanInternal
;	fpatan				; (fp: arctan(x/sqrt(1-x^2)))

	.leave
	ret
Intel80X87ArcSinInternal endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcSin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arcsin(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
		arcsin(x) = arctan(x/sqrt(1-x^2))
		the fpatan instruction nicely performs the divide for us,
		so take advantage of it by saving x, then computing just
		sqrt(1-x^2) and using fpatan

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcSin	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done

	call	Intel80X87ArcSinInternal

	neg	ax			; (ax still 2)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcSin	endp
	public	Intel80X87ArcSin



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcSinh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arcsinh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
	; arcsinh(x) = ln(x+sqrt(x^2+1))

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcSinh	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld	st		; FloatDup
	fmul	st, st(1)	; FloatSqr
	fld1
	faddp			; x x^2+1
	fsqrt
	faddp			; x+sqrt(x^2+1)

	fldln2			; now figure the natural log of that
	fxch	st(1)
	fyl2x
	neg	ax		; (ax still 2)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcSinh	endp
	public	Intel80X87ArcSinh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcTan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arctan(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcTan	proc	far
	.enter	
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld1
	call	Intel80X87ArcTanInternal
;	fpatan
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcTan endp
	public	Intel80X87ArcTan


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcTan2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arctan(st(1)/st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
				x	y	 result
			       ---     ---	---------
				+	+	0 to PI/2
				-	+	PI/2 to PI
				-	-	-PI to -PI/2
				+	-	-PI/2 to 0
				
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcTan2	proc	far
	uses	bx, cx
	.enter
	clr	ax
	mov	cx, ax			; cx will be the quadrant
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	fxch			; must match software interface

	; we need to check the four cases so as to return an answer in the
	; proper quadrant
	ftst
	StatusToAX
	mov_tr	bx, ax			; save status in bx
	fxch
	ftst
	StatusToAX
	fxch				; swap back
	test	bx, mask SW_CONDITION_CODE_0
	jnz	xneg
	test	ax, mask SW_CONDITION_CODE_0
	jnz	xpos_yneg

	; ok, both non-negative, if both zero return error
	test	bx, mask SW_CONDITION_CODE_3
	jz	arcTan
	test	ax, mask SW_CONDITION_CODE_3
	jz	arcTan
	fdivp			; creates an error value on the stack
	jmp	leaveHardware

xpos_yneg:
	mov	cx, 3		; 3rd quadrant
	jmp	arcTan

xneg:
	test	ax, mask SW_CONDITION_CODE_0
	jnz	xneg_yneg
	
	; xneg_ypos
	mov	cx, 1
	jmp	arcTan

xneg_yneg:
	mov	cx, 2

arcTan:
	call	Intel80X87ArcTanInternal
	jcxz	leaveHardware
	cmp	cx, 1
	jne	try2
	fldpi
	faddp	; add PI to get into proper quadrant
	jmp	leaveHardware
try2:
	cmp	cx, 2
	jne	leaveHardware	; if in last quadrant, answer already OK
	fldpi
	fsubp		; subract PI to get into proper quadrant
	jmp	leaveHardware
leaveHardware:
	mov	ax, -1
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcTan2	endp
	public	Intel80X87ArcTan2



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ArcTanh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = arctanh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
	;	arctanh(x) = ln((1+x)/(1-x))/2

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ArcTanh	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld1
	fxch
	fsub	st(1), st	; ( 1-x x )
	fld1
	faddp			; ( 1-x 1+x )
	fdivrp			; ( 1+x/1-x )

	fldln2
	fxch	st(1)
	fyl2x			; ( ln(1-x/1+x) )

	fild	cs:[int87Two]	; divide that by 2
	fdivp

	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87ArcTanh	endp
	public	Intel80X87ArcTanh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87CompAndDrop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare st(1), st

CALLED BY:	GLOBAL

PASS:		X1, X2 on the fp stack (X2 = top)

RETURN:		flags set by what you may consider to be a cmp X1,X2
		both numbers are popped off

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87CompAndDrop	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	fxch
	fcompp
	StatusToAX
	push	ax
	mov	ax, -2
	call	FloatHardwareLeave
	pop	ax
	call	Intel80X87DoFlags
done:
	.leave
	ret
Intel80X87CompAndDrop	endp
	public	Intel80X87CompAndDrop


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Comp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare st, st(1)

CALLED BY:	GLOBAL

PASS:		X1, X2 on the fp stack (X2 = top)

RETURN:		flags set by what you may consider to be a cmp X1,X2
		numbers are left intact

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Comp	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	fxch	
	fcom
	StatusToAX
	fxch
	push	ax
	clr	ax
	call	FloatHardwareLeave
	pop	ax
	call	Intel80X87DoFlags
done:
	.leave
	ret
Intel80X87Comp	endp
	public	Intel80X87Comp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87CompESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare the top number on the fp stack to a floating
		point number located as es:di
CALLED BY:	GLOBAL

PASS:		nothing

RETUN:		if ax = 0, regs set as if a normal compare was done
		else error

DESTROYED:	ax	

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/30/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87CompESDI	proc	far
	.enter
	mov	ax, 1		; need one slot
	call	FloatHardwareEnter
	jc	done
	
	fld	{FloatNum}es:[di]	; push the beast
	fcomp
	StatusToAX
	call	Intel80X87DoFlags
	pushf
	mov	ax, -1
	call	FloatHardwareLeave
	clr	ax
	popf
done:
	.leave
	ret
Intel80X87CompESDI	endp
	public	Intel80X87CompESDI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Cosh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = cosh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
	; cosh(x) = (exp(x) + exp(-x)) /2

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Cosh	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fldl2e
	fmulp
	call	Intel80X87_2ToTheX	; ( e^x )
	
	fld1				; ( e^x 1 )
	fld	st(1)			; ( e^x 1 e^x )
	fdivp				; ( e^x 1/e^x )
	faddp				; ( e^x+1/e^x )
	fild	cs:[int87Two]		; ( e^x+1/e^x 2 )
	fdivp

	neg	ax		; (ax still 2)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Cosh	endp
	public	Intel80X87Cosh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Depth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the stack depth

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = depth

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Depth	proc	far
	uses	cx
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	call	FloatGetStackDepth
	clr	cx
	xchg	ax, cx
	call	FloatHardwareLeave
	xchg	ax, cx
done:
	.leave
	ret
Intel80X87Depth	endp
	public	Intel80X87Depth


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DIV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do an integer divide (ie divide and truncate)

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
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DIV	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	fdiv
	call	Intel80X87TruncInternal
	dec	ax			; 1 popped (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87DIV	endp
	public	Intel80X87DIV


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87CheckNormalNumberAndLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sees if a number is normal or not

CALLED BY:	GLOBAL

PASS:		number to check on top of FP stack

RETURN:		carry set on a NON normal number
		al = FloatErrorType

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

		from The Processor and CoProcessor page 715:

		condition flags: c3 c2 c1 c0
				  0  0  0  0	+Unnormal
				  0  0  1  0	-Unnormal
				  0  0  0  1	+Nan
				  0  0  1  1	-Nan
				  0  1	0  0	+Normal
				  0  1  1  0	-Normal
				  0  1  0  1	+INFINITY
				  0  1  1  1	-INFINITY
				  1  0  0  0	+0.0
				  1  0  1  0	-0.0
				  1  0  0  1	Empty
				  1  0  1  1	Empty
				  1  1  0  0	+Denormal
				  1  1  1  0	-Denormal
				  1  1  0  1    Empty 8087, 80187 only
				  1  1  1  1    Empty 8087, 80187 only

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/14/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87CheckNormalNumberAndLeave	proc	far
	uses	bx
	.enter
	mov_tr	bx, ax
	fxam
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_3
	jnz	c3_on	
	test	ax, mask SW_CONDITION_CODE_2
	jz	genErr
	test	ax, mask SW_CONDITION_CODE_0
	jz	normal
	test	ax, mask SW_CONDITION_CODE_1
	jz	posINF
	mov	al, FLOAT_NEG_INFINITY
	jmp	notNormal
posINF:
	mov	al, FLOAT_POS_INFINITY
	jmp	notNormal
c3_on:
	test	ax, mask SW_CONDITION_CODE_2
	jnz	genErr
	test	ax, mask SW_CONDITION_CODE_0
	jnz	genErr
normal:
	clc
done:
	pushf
	xchg	ax, bx
	call	FloatHardwareLeave
	mov_tr	ax, bx
	popf
	.leave
	ret
genErr:
	mov	al, FLOAT_GEN_ERR
notNormal:
	stc
	jmp	done
Intel80X87CheckNormalNumberAndLeave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Divide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st(1) / st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error info in carry set
DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Divide	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
	fdiv
	dec	ax		; one popped (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Divide	endp
	public	Intel80X87Divide


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Divide2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st/2

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Divide2	proc	far
	uses	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fild	cs:[int87Two]
	fdivp
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Divide2	endp
	public	Intel80X87Divide2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Divide10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st/10

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error info if carry set
DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Divide10	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fild	cs:[int87Ten]
	fdivp
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Divide10	endp
	public	Intel80X87Divide10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Drop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pop off top of fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing (flags preserved)

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Drop	proc	far
	uses	ax
	.enter
	pushf
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fstp	st
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
done:
	popf
	.leave
	ret
Intel80X87Drop	endp
	public	Intel80X87Drop


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Dup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	duplicate the top of the fp stack 

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on overflow

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Dup	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld	st
	clr	ax
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87Dup	endp
	public	Intel80X87Dup


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Eq0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare the top of the fp stack to zero

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		flags set to appropriate values
		should check jp first, if on non comparable

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Eq0	proc	far
status	local	word
	uses	ax
	.enter
	mov	ax, 0
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	ftst				
	fstsw	status
	fstp	st			; pop the number
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
	mov	ax, status
	sahf
	stc
	je	done
	clc	
done:
	.leave
	ret
Intel80X87Eq0	endp
	public	Intel80X87Eq0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Exp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = e^st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		return carry in result NAN or Infinity

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Exp	proc	far
	
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fldl2e
	fmulp
	call	Intel80X87_2ToTheX
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Exp	endp
	public	Intel80X87Exp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Exponential
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st(1)^st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error
		ax = error info if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	
			st(1)^st = 2^(st*lg(st(1)))

		if the base is a negative number then the exponent must be
		an integer...
		if the base is zero we must also have it as a special case
		
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Exponential	proc	far
temp	local	word
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	fxch				; st =  base, st(1) = exponent
	ftst
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_2
	jnz	error		; => it's NaN or
	test	ax, mask SW_CONDITION_CODE_0		; is it negative
	jnz	doBaseNegative
	test	ax, mask SW_CONDITION_CODE_3
	jnz	doBaseZero
	fyl2x
	call	Intel80X87_2ToTheX
done:
	mov	ax, -3		; 
	call	Intel80X87CheckNormalNumberAndLeave
exit:
	.leave
	ret
error:
	; on an error we still need to clean up and release the coprocessor
	mov	ax, -3
	call	FloatHardwareLeave
	mov	ax, FLOAT_GEN_ERR
	stc
	jmp	exit
doBaseZero:
	; if the exponent is a NAN or negative report an error
	; if the exponent is 0, the result is 1
	; if the exponent is > 0 then the result is zero
	fxch
	ftst
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_2 or mask SW_CONDITION_CODE_0
	jnz	error		; => it's NaN or
	test	ax, mask SW_CONDITION_CODE_3		; is it zero
	jnz	doOne
	fstp	st
	fstp	st
	fldz			; 0^X for X > 0 = 0
	jmp	done
doOne:
	fstp	st
	fstp	st
	fld1			; load 1 onto the stack
	jmp	done
doBaseNegative:
	fxch			; get the exponent back on top
	; if the base is negative, then the exponent must be an integer
	fld	st		; dupluicate
	frndint			; round the number and see ifs equal
	fcomp			; comapare and pop off extra value
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_2
	jnz	error
	test	ax, mask SW_CONDITION_CODE_3
	jz	error

	; what needs to happen here is that we do a x^y with negative x
	; and then just change the sign of the final answer depending on
	; whether y was even or odd...
	fld	st
	mov	temp, 2
	fild	temp
	fdivp			; divide by two and see if we get an integer
	fld	st
	frndint
	fcompp
	StatusToAX
	mov	temp, ax	; save away 
	fxch			; unswap things
	fchs			; change the sign to positive
	fyl2x
	call	Intel80X87_2ToTheX
	test	temp, mask SW_CONDITION_CODE_3
	jnz	done
	fchs
	jmp	done
Intel80X87Exponential	endp
	public	Intel80X87Exponential

COMMENT @-----------------------------------------------------------------------

FUNCTION:	Intel80X87FloatToAscii

DESCRIPTION:	Converts the floating point number into an ASCII string.

		This routine requires that you initialize the FFA_stackFrame.

CALLED BY:	GLOBAL ()

PASS:		ss:bp - FFA_stackFrame stack frame
		es:di - destination address of string
		    this buffer must either be FLOAT_TO_ASCII_NORMAL_BUF_LEN or
		    FLOAT_TO_ASCII_HUGE_BUF_LEN in size (see math)
		If FFA_stackFrame.FFA_FROM_ADDR = 1
		    ds:si - location of number to convert

		NOTE:
		-----

		* Numbers are rounded away from 0.
		  eg. if number of fractional digits desired = 1,
		      0.56 will round to 1
		      -0.56 will round to -1

		* Commas only apply to the integer portion of fixed and
		  percentage format numbers.
		  ie. scientific formats, the fractional and exponent portions
		  of numbers will have no commas even if FFAF_USE_COMMAS is
		  passed.

RETURN:		cx - number of characters in the string
		     (excluding the null terminator)
		some useful fields in the stack frame, see math.def

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	FloatFloatToAscii is a big body of code!

	A FloatFloatToAsciiFixed routine exists to format fixed format numbers
	quickly. Some demands may exceed its ability, so once this is detected,
	it bails and the generalized (& significantly slower) FloatFloatToAscii
	routine takes over.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/92		Initial version

-------------------------------------------------------------------------------@

Intel80X87FloatToAscii	proc	far
	FFA_local	local	FFA_stackFrame
	.enter	inherit far
	push	ax, bx, ds, si
	mov	ax, 0
	call	FloatHardwareEnter
	jc	done

	sub	sp, size FloatNum
	test	FFA_local.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	jnz	cont
	mov	bx, sp
	fstp	{FloatNum}ss:[bx]
	fwait
	segmov	ds, ss, si
	mov	si, sp
	or	FFA_local.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	mov	ax, -1
cont:
	call	FloatFloatToAsciiInternal
	add	sp, size FloatNum
	call	FloatHardwareLeave
done:
	pop	ax, bx, ds, si
	.leave
	ret
Intel80X87FloatToAscii	endp
	public	Intel80X87FloatToAscii


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Intel80X87FloatToAscii_StdFormat

DESCRIPTION:	Converts the floating point number into an ASCII string
		in the format specified by al.
		
		This routine provides a way to obtain an ASCII string from
		a floating point number without having to deal with the
		FFA_stackFrame.

		!!! NOTE !!!
		Rounding is based on decimalDigits and not total Digits.

CALLED BY:	GLOBAL ()

PASS:		ax - FloatFloatToAsciiFormatFlags

		    Flags permitted:

		    FFAF_FROM_ADDR - source of number
			If FFAF_FROM_ADDR=1,
			    Use the number at the given address
			    ds:si - location
			If FFAF_FROM_ADDR=0,
			    Use number from the fp stack.
			    Number will be popped
		    FFAF_SCIENTIFIC - scientific format
			If FFAF_SCIENTIFIC=1,
			    Returns numbers in the form x.xxxE+xxx
			    in accordance with bh and bl
			    Numbers are normalized ie. the mantissa m satisfies
				1 <= m < 10
			If FFAF_SCIENTIFIC=0,
			    Returns numbers in the form xxx.xxx
			    in accordance with bh and bl
		    FFAF_PERCENT - percentage format
			Returns numbers in the form xxx.xxx%
			in accordance with bh and bl
		    FFAF_USE_COMMAS
		    FFAF_NO_TRAIL_ZEROS

		bh - number of significant digits desired (>=1)
		     (A significant digit is a decimal digit derived from
		     the floating point number's mantissa and it may preceed
		     or follow a decimal point).

		     Fixed format numbers that require more digits than limited
		     will be forced into scientific notation.

		bl - number of fractional digits desired (ie. number of
		     digits following the decimal point)

		es:di - destination address of string
		    this buffer must either be FLOAT_TO_ASCII_NORMAL_BUF_LEN or
		    FLOAT_TO_ASCII_HUGE_BUF_LEN in size (see math.def)

		NOTE:
		-----

		* Numbers are rounded away from 0.
		  eg. if number of fractional digits desired = 1,
		      0.56 will round to 1
		      -0.56 will round to -1

		* Commas only apply to the integer portion of fixed and
		  percentage format numbers.
		  ie. scientific formats, the fractional and exponent portions
		  of numbers will have no commas even if FFAF_USE_COMMAS is
		  passed.

RETURN:		cx - number of characters in the string
		     (excluding the null terminator)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
			if from address than just call the routine
			otherwise take the top of the hardware stack
			put in memory and then call the routine

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/92		Initial version

-------------------------------------------------------------------------------@

Intel80X87FloatToAscii_StdFormat	proc	far
myfloat	local	FloatNum
doLeave	local	word
	uses	ds, si, ax
	.enter
	clr	doLeave
	test	ax, mask FFAF_FROM_ADDR
	jnz	cont
	mov	doLeave, 1
	push	ax
	clr	ax
	call	FloatHardwareEnter
	pop	ax
	jc	done
	fstp	myfloat
	segmov	ds, ss, si
	lea	si, myfloat
	or	ax, mask FFAF_FROM_ADDR	
	fwait
cont:	
	call	FloatFloatToAscii_StdFormatInternal
	tst	doLeave
	jz	done
	mov	ax, -1
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87FloatToAscii_StdFormat	endp
	public	Intel80X87FloatToAscii_StdFormat



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Factorial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st!

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Factorial	proc	far
myint32	local	dword
	uses	cx
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fistp	myint32
	fwait
	tst	myint32.high
	jnz	error

	mov	ax, myint32.low
	cmp	ax, FACTORIAL_LIMIT
	jg	error
	tst	ax
	jnz	cont
	fld1
	jmp	checkStatus
cont:
	mov	cx, ax
	call	Intel80X87DoFactorial
checkStatus:
	mov	ax, -2
	call	Intel80X87CheckNormalNumberAndLeave	
done:
	.leave
	ret
error:
	call	Intel80X87Err			
	jmp	checkStatus
Intel80X87Factorial	endp
	public	Intel80X87Factorial


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DoFactorial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do the actual factorial function

CALLED BY:	INTERNAL

PASS:		cx = integer form of value on top of stack

RETURN:		Void.

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DoFactorial	proc	near
	.enter
	fld1					; partial result
	fld1					; start from 1
factorialloop:
	fmul	st(1)				; st(1) = partial result
	fld1					; st += 1
	faddp					
	loop	factorialloop	
	fstp	st				; get rid of temp value
	.leave
	ret
Intel80X87DoFactorial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Frac
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = fractionalpart(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on bad value
		ax = error info if bad value

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Frac	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld	st
	call	Intel80X87TruncInternal
	fsubp
	fabs
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Frac	endp
	public	Intel80X87Frac

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetNumDigitsInIntegerPart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get number of digits of integer part on number on fp stack
		number gets pooped off

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = number of digits in integer part

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetNumDigitsInIntegerPart	proc	far
myfloat	local	FloatNum
	uses	bx, es, ds, si
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	fstp	myfloat
	segmov	ds, ss, si
	lea	si, myfloat
	fwait
	call	FloatPushNumberInternal
	segmov	ds, es		; ds <- FP stack
	call	FloatGetNumDigitsInIntegerPartInternal
	call	MemUnlock
	push	ax
	mov	ax, -1
	call	FloatHardwareLeave
	pop	ax
done:
	.leave
	ret
Intel80X87GetNumDigitsInIntegerPart	endp
	public	Intel80X87GetNumDigitsInIntegerPart



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Gt0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	test top of fp stack against zero

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		flags set to appropriate values

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Gt0	proc	far
status	local	word
	uses	ax	
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	ftst				
	fstsw	status
	fstp	st
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
	jc	done
	mov	ax, status
	sahf	
	cmc	; invert the sense (was set if neg, clear if non-neg)
	jne	done	; this means we have to deal with eq 0 specially...
	clc		; it ain't > 0
done:
	.leave
	ret
Intel80X87Gt0	endp
	public	Intel80X87Gt0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Int
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = INT(st) 

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	round towards -Infinity so:
				6.7 -> 6
				-6.7 -> -7

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Int	proc	far
control	local	word
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fstcw	control
	fwait			; wait for it to arrive
	mov	ax, control
	andnf	ax, not mask CW_ROUND_CONTROL
	ornf	ax, RC_DOWN shl offset CW_ROUND_CONTROL
	mov	control, ax
	fldcw	control
	frndint
	call	Intel80X87SetNearest
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Int	endp
	public	Intel80X87Int


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87IntFrac
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	leaves integer and fractional part of top of fp stack
		on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87IntFrac	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld	st
	call	Intel80X87TruncInternal
	fsub	st(1), st	; st(1) <- frac
	fxch	st(1)		; st <- frac, st(1) <- int
	fabs
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87IntFrac	endp
	public	Intel80X87IntFrac


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Inverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = 1/st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on bad values
		ax = error info if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Inverse	proc	far
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld1
	fdivrp
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	ret
Intel80X87Inverse	endp
	public	Intel80X87Inverse


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Lg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = lg(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on bad values
		ax = error info if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Lg	proc	far
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fld1
	fxch	st(1)
	fyl2x
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	ret
Intel80X87Lg	endp
	public	Intel80X87Lg



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Lg10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = lg(10)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Lg10	proc	far
	call	Intel80X87LoadFPUConst
	fldl2t
	ret
Intel80X87Lg10	endp
	public	Intel80X87Lg10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Ln
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = ln(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Ln	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fldln2
	fxch	st(1)
	fyl2x
	neg	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Ln	endp
	public	Intel80X87Ln


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Ln1plusX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = ln(st+1)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	
		used to use the fyl2xp1 instruction, but its domain is
		too restrictive (-(1-sqrt(2)/2) <= st <= sqrt(2)-1), so
		we just perform the addition and take the natural log
		in the usual way.

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Ln1plusX	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
   	fld1
	faddp
	fldln2
	fxch	st(1)
	fyl2x
	neg	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Ln1plusX	endp
	public	Intel80X87Ln1plusX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Ln2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = ln(2)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Ln2	proc	far
	call	Intel80X87LoadFPUConst
	fldln2
	ret
Intel80X87Ln2	endp
	public	Intel80X87Ln2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Ln10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a ln(10) on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Ln10	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
	fldln2
	fldl2t
	fmulp
	mov	ax, -1
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87Ln10	endp
	public	Intel80X87Ln10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = log(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Log	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fldlg2
	fxch	st(1)
	fyl2x
	neg	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Log	endp
	public	Intel80X87Log


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Lt0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sees if top of fp stack is less than zero

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if true, clear if otherwise
		top of stack popped off

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/21/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Lt0	proc	far
status	local	word
	uses	ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	ftst				
	fstsw	status
	fstp	st			; pop the number
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
	mov	ax, status
	sahf			
	jb	done			; => negative (carry already set)
	clc	
done:
	.leave
	ret
Intel80X87Lt0	endp
	public	Intel80X87Lt0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Max
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do max of top two stack elements

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Max	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	exit
EC <	call	Intel80X87Check2Args			>
	fcom
	StatusToAX
	sahf
	jp	error
	jb	dropTop
	fxch
dropTop:
	fstp	st

	clc
done:
	mov	ax, -1
	call	Intel80X87CheckNormalNumberAndLeave
exit:
	.leave
	ret
error:
	stc
	jmp	done
Intel80X87Max	endp
	public	Intel80X87Max


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Min
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes min of top two elements of fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Min	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	exit
EC <	call	Intel80X87Check2Args			>
	fcom
	StatusToAX
	sahf
	jp	error
	ja	dropTop
	fxch
dropTop:
	fstp	st

	clc
done:
	mov	ax, -1
	call	Intel80X87CheckNormalNumberAndLeave
exit:
	.leave
	ret
error:
	stc
	jmp	done
Intel80X87Min	endp
	public	Intel80X87Min


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	Float2Scale (originally /2SCALE)

DESCRIPTION:	Multiply the topmost fp num by the given factor of 2.
		( N --- )( fp: X --- X*2^N )

CALLED BY:	INTERNAL (FloatSqrt, FloatExpC, FloatExp)

PASS:		bx - factor of 2 to multiply number by
		X on fp stack

RETURN:		X*2^N on fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Intel80X87_2Scale	proc	near	
factor	local	word	push	bx
	.enter
EC<	call	Intel80X87Check1Arg					 >
	fild	ss:[factor]
	fxch
	fscale
	fstp	st(1)		; pop st(1) (the scale factor)
	.leave
	ret
Intel80X87_2Scale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	FloatSign (originally /FSIGN)

DESCRIPTION:	Returns the exponent of the topmost fp number.
		This exponent has these convenient properties:
		    * positive if the number is positive
		    * 0 if the number is zero (+ or - 0)
		    * negative  if the number is negative
		( fp: X --- X )

CALLED BY:	INTERNAL (many)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X unchanged on fp stack
		bx - negative if fp number is negative
		     non-negative otherwise
		flags set by a "cmp bx, 0"

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sign	proc	near
myfloat	local	FloatNum
	uses	si
	.enter
EC<	call	Intel80X87Check1Arg		 >

	fstp	myfloat
	fld	myfloat
	mov	bx, myfloat.F_exponent	; get exponent
	cmp	bx, 8000h		; negative 0?
	jne	done

	clr	bx			; change -0 to 0

done:
	cmp	bx, 0
	fwait			; make sure FPU done with myfloat before
				;  destroying it
	.leave
	ret
Intel80X87Sign	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Mod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = MOD(st, ST(1))

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
the algorithm is effectively:

	for (n = exponent(div)-exponent(mod); n >= 0; n--) {
		if (div >= mod*2**n) {
			div -= mod*2**n;
		}
	}

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Mod	proc	far
	uses	di, bx, cx
	.enter
	mov	ax, 2		; need two extra slots (one for copy of
				;  mod, and one for 2Scale)
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args				>
	;
	; Fetch exponent of modulus after making modulus non-negative.
	; 
	fabs
	call	Intel80X87Sign
	je	cleanStack		; error if exponent (i.e. modulus) is 0

	;
	; Fetch exponent of dividend, saving the sign away for proper
	; adjustment of the result.
	;
	; NOTE: in these comments exp(x) means the exponent word of the number
	; x, not e^x.
	; 
	mov	cx, bx			; cx <- exp(abs(X2))
	fxch
	call	Intel80X87Sign
	mov	di, bx			; di <- exp(X1)
	fabs
	andnf	bx, not mask FE_SIGN	; bx <- exp(abs(X1))
	;
	; bx = exp(abs(X1)), di = exp(X1), cx = exp(abs(X2))
	;
	cmp	cx, bx			; X2 > X1 ?
	jg	modGotten		; branch if so (X1/X2 < 1, so X1 is
					;  remainder)
	;
	; cx <= bx, exp(abs(X2)) <= exp(abs(X1))
	;
	sub	cx, bx
	neg	cx
modLoop:
	fld	st(1)

	mov	bx, cx
	call	Intel80X87_2Scale	; scale modulus by 2^n
	fcom				; cmp mod*2^n, div
	StatusToAX
	sahf
	jbe	doSub			; subtract mod*2^n from div if it's
					;  less than div. results are
	fstp	st			; else discard scaled modulus
	jmp	over			;  and loop
doSub:
	fsub
over:
	dec	cx
	cmp	cx, 0
	jge	modLoop

modGotten:
	tst	di			; exp X1 < 0 ?
	jge	signOK
	fchs
signOK:
	fxch
	fstp	st
	clc
done:
	pushf
	mov	ax, -3			; extra slots, plus modulus now
					;  gone
	call	Intel80X87CheckNormalNumberAndLeave
	jc	nonnormal
	popf
exit:
	.leave
	ret

nonnormal:
	inc	sp
	inc	sp
	jmp	exit

cleanStack:
	fstp	st
	fstp	st
	stc
	jmp	short done
Intel80X87Mod	endp
	public	Intel80X87Mod


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Multiply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st(1) = st*st(1)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 4/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Multiply	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
	fmul
	dec	ax		; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Multiply	endp
	public	Intel80X87Multiply


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Multiply2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = 2 * st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if any problems

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Multiply2	proc	far
	uses	ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fimul	cs:[int87Two]
			; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave	
	ret
Intel80X87Multiply2	endp
	public	Intel80X87Multiply2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Multiply10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = 10*st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set if an problems

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Multiply10	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fimul	cs:[int87Ten]
			; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave	
	ret
Intel80X87Multiply10	endp
	public	Intel80X87Multiply10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Negate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = -st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Negate	proc	far
	uses	ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fchs
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Negate	endp
	public	Intel80X87Negate

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Over
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy the second number on the fp stack onto the
		top of the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Over	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
   	fld	st(1)
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
	.leave
done:
	ret
Intel80X87Over	endp
	public	Intel80X87Over

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Pi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push pi onto fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 4/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Pi	proc	far
	call	Intel80X87LoadFPUConst
	fldpi
	ret
Intel80X87Pi	endp
	public	Intel80X87Pi


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87PiDiv2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	puts a pi/2 on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87PiDiv2	proc	far
	call	Intel80X87LoadFPUConst
	fldpi
	fidiv	cs:[int87Two]
	ret
Intel80X87PiDiv2	endp
	public	Intel80X87PiDiv2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Pick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes the nth stack element and copies it onto the
		top of the stack

CALLED BY:	GLOBAL

PASS:		bx = which element (n) to select

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Pick	proc	far
myfloat		local	FloatNum
	uses	cx, bx
	.enter
EC <	tst	bx					>
EC <	ERROR_Z	MUST_BE_GREATER_THAN_ZERO		>
EC <	call	FloatGetStackDepth			>
EC <	cmp	bx, ax					>
EC <	ERROR_G	INSUFFICIENT_ARGUMENTS_ON_STACK		>
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done

	cmp	bx, INTEL_STACK_SIZE
	jge	getFromSoftware

	dec	bx		; start from 0
	shl	bx
	jmp	cs:[fpRegisters][bx]
reg0:
	fld	st
	jmp	done
reg1:
	fld	st(1)
	jmp	done
reg2:
	fld	st(2)
	jmp	done
reg3:
	fld	st(3)
	jmp	done
reg4:
	fld	st(4)
	jmp	done
reg5:
	fld	st(5)
	jmp	done
reg6:
	fld	st(6)
	jmp	done
reg7:
	fld	st(7)

done:	
	clr	ax
	call	FloatHardwareLeave
	.leave
	ret
fpRegisters	nptr	 reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7
getFromSoftware:
	; if it's in the software stack, copy it to the top
	; of the software stack using FloatPick and
	; then pop it off the software stack and push it
	; onto the hardware stack
	push	ds, es, di
	mov	cx, bx
	; we need to increment cx because we slid one of the numbers down
	; from hardware to software to make room for the new one
	inc	cx
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	ds, ax
	sub	cx, INTEL_STACK_SIZE
	xchg	bx, cx			; bx <- number to pick, cx = mem handle
	call	FloatPickInternal
	segmov	es, ss
	lea	di, myfloat
	call	FloatPopNumberInternal
	mov_tr	bx, cx			; bx <- mem handle
	call	MemUnlock
	fld	myfloat
	pop	ds, es, di
	jmp	done	
Intel80X87Pick	endp
	public	Intel80X87Pick


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87PopNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pops the top off of the fp stack

CALLED BY:	GLOBAL

PASS:		es:di = location to write number to (10 bytes)

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87PopNumber	proc	far
	uses	ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fstp	{FloatNum}es:[di]
	fwait
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87PopNumber	endp
	public	Intel80X87PopNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87PushNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a number onto the fp stack

CALLED BY:	GLOBAL

PASS:		ds:si = number to push

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87PushNumber	proc	far
	uses	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	{FloatNum}ds:[si]
	dec	ax		; (ax still 0)
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87PushNumber	endp
	public	Intel80X87PushNumber


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Random
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a random number on the fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	We want to generate a number such that a list of such generated numbers
	will satisfy all of the statistical tests that a random sequence
	would satisfy.

	Algorithm taken from Knuth Vol 2 Chapter 3 - Random Numbers
	-----------------------------------------------------------

	The linear congruential method:

	The detailed investigations suggest that the following procedure
	will generate "nice" and "simple" random numbers.  At the beginning
	of the program, set an integer variable X to some value Xo.  This
	variable X is to be used only for the purpose of random number
	generation. Whenever a new random number is required by the program,
	set
		X <- (aX + c) mod m
	
	and use the new value of X as the random value.  It is necessary to
	choose Xo, a, c, and m properly, according to the following principles:

	1)  The "seed" number Xo may be chosen arbitrarily.  We use the
	    current date and time since that is convenient.
	
	2)  The number m should be large, say at least 2^30.  The computation
	    of (aX + c)mod m must be done exactly, with no roundoff error.
	
	3)  If m is a power of 2, pick a so that a mod 8 = 5.
	    If m is a power of 10, choose a so that a mod 200 = 21.

	    The choice of a together with the choice of c given below
	    ensures that the random number generator will produce all
	    m different possible values of X before it starts to repeat
	    and ensures high "potency".

	4)  The multiplier a should preferably be chosen between 0.01m
	    0.99m, and its binary or decimal digits should not have a simple
	    regular pattern.  By choosing a = 314159261 (which satisfies
	    both of the conditions in 3), one almost always obtains a
	    reasonably good multiplier.  There are several tests that can
	    be performed before it is considered to have a truly clean
	    bill of health.
	
	5)  The value of c is immaterial when a is a good multiplier,
	    except that c must have no factor in common with m.
	    Thus we may choose c=1 or c=a.
	
	6)  The least significant digits of X are not very random, so
	    decisions based on the number X should always be influenced
	    primarily by the most significant digits.

	    It is generally best to think of X as a random fraction
	    between 0 and 1.  To compute a random integer between 0
	    and k-1, one should multiply by k and truncate the result.
	
	Implementation notes:
	---------------------

	Desirable properties:

	* the same seed generates the same sequence of random numbers

	* 2 different threads accessing the routine will not lose
	  their "place" in the random number sequence.  This is important
	  because the property of Uniform Distribution will be adversely
	  affected if one thread's behaviour can alter the next number
	  seen by another thread.

	  This "state" is wholly represented by X since the other
	  parameters a, c, and m are hardwired in the code.  The
	  question then is where to save X.  We can force the user
	  to preserve X on the floating point stack but that may
	  be inconvenient because the caller will then have to
	  place calls to FloatDup to duplicate the number and pop
	  it off when done.

	  We instead save X in the floating point stack header.
	  This costs 5 words and it seems affordable.
	
KNOWN BUGS/SIDEFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Random	proc	far
myfloat	local	FloatNum
	uses	es, bx, di, ds
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	ds, ax
	call	FloatRandomInternal
	segmov	es, ss
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:		
	.leave
	ret
Intel80X87Random	endp
	public	Intel80X87Random


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Randomize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Prime the random number generator. The caller may choose to
		pass a seed or have the routine generate one. 

		If the seed is small ( << 2^32 ), the random number
		generator needs to be primed before use by calling
		FloatRandom and discarding the results.


CALLED BY:	GLOBAL

PASS:		al - RandomGenInitFlags
		     RGIF_USE_SEED
		     RGIF_GENERATE_SEED
		cx:dx - seed if RGIF_USE_SEED

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Randomize	proc	far
	uses	ds, bx
	.enter
	push	ax
	clr	ax
	call	FloatHardwareEnter
	pop	ax
	jc	done
	push	ax
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	ds, ax
	pop	ax
	call	FloatRandomizeInternal
	call	MemUnlock
	clr	ax
	call	FloatHardwareLeave
done:		
	.leave
	ret
Intel80X87Randomize	endp
	public	Intel80X87Randomize


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87RandomN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns a random number between 1 and N-1

CALLED BY:	GLOBAL

PASS:		N on fp stack, 0 <= N < 2^31
		ds - fp stack seg

RETURN:		return carry set on error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87RandomN	proc	far
myfloat	local	FloatNum
	uses	es, ds, si, bx, di, ax
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fstp	myfloat
	fwait
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	es, ax
	segmov	ds, ss, si
	lea	si, myfloat
	call	FloatPushNumberInternal
	mov	ds, ax
	call	FloatRandomNInternal
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:		
	.leave
	ret
Intel80X87RandomN	endp
	public	Intel80X87RandomN


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Roll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move Nth element to top of stack

CALLED BY:	GLOBAL

PASS:		bx = N (which element to bring up)

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Roll	proc	far
tempStack	local	INTEL_STACK_SIZE dup(FloatNum)
	uses	ds, di, cx, es, si, bx
	.enter
EC <	pushf							>
EC <	tst	bx						>
EC <	ERROR_LE	ROLL_MUST_BE_POSITIVE			>
EC <	call	FloatGetStackDepth				>
EC <	cmp	ax, bx						>
EC <	ERROR_L	INSUFFICIENT_ARGUMENTS_ON_STACK			>
EC <	popf							>
	clr	ax
	call	FloatHardwareEnter
	jc	done

	; if bl <= INTEL_STACK_SIZE we don't have to worry about the
	; software stack at all
	cmp	bl, INTEL_STACK_SIZE		
	jg	doSoftwareRoll

	; only hardware....
	; what I do, is pop off all the relavent elements into memory
	; and then push them back on in the right order
	clr	ch
	mov	cl, bl
	lea	di, tempStack
	add	di, FPSIZE		; start at position 1, not 0
	dec	cx
	jcxz	myleave
	; this loop pops the first N-1 elements off and into memory
	; and writing them to memory starting from position 1 rather than
	; position 0
storeloop:
	fstp	{FloatNum}ss:[di]		; store number
	add	di, FPSIZE			; advance pointer
	loop	storeloop	
	; now write Nth element in 0 poisition
	lea	di, tempStack
	fstp	{FloatNum}ss:[di]		
	mov	al, FPSIZE
	mul	bl		
	add	di, ax
	sub	di, FPSIZE
	mov	cl, bl
	; because I have popped them off in the right order, I can
	; just push them all back on from bottom to top
loadloop:
	fld	{FloatNum}ss:[di]	; push number back on
	sub	di, FPSIZE		; advance pointer
	loop	loadloop
myleave:
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
doSoftwareRoll:
	; for the software case, I must do the following
	; first pop the bottom of the hardware stack off
	; and push it onto the top of the softwares stack
	; then do a Roll of (N-(INTELSTACK_SIZE-1)) on the
	; software stack, then pop of the top of the software
	; stack and push in onto the top of the hardware stack
	; trust me, it works...;)
	mov	cx, bx
	call	FloatGetSoftwareStackHandle
	call	MemLock			; lock down the software stack
	push	bx
	mov	es, ax
	fdecstp				; mov hardware pointer to the bottom
	fstp	{FloatNum}tempStack	; pop off bottom element
	fwait
	segmov	ds, ss, si
	lea	si, tempStack
	call	FloatPushNumberInternal	; push it onto software stack
	segxchg	ds, es
	mov	bx, cx
	sub	bl, (INTEL_STACK_SIZE - 1)
	call	FloatRollInternal	; Roll software stack
	lea	di, tempStack
	call	FloatPopNumberInternal	; pop off top number
	fld	{FloatNum}tempStack	; push it onto hardware stack
	pop	bx
	call	MemUnlock
	jmp	myleave
Intel80X87Roll	endp
	public	Intel80X87Roll


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87RollDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	to a roll of top N elements (opposite direction of Roll

CALLED BY:	GLOBAL

PASS:		bl = N, number of elements to Roll

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87RollDown	proc	far
tempStack	local	INTEL_STACK_SIZE	dup(FloatNum)
	uses	bx, es, ds, di, si, cx
	.enter
EC <	tst	bx						>
EC <	ERROR_LE	ROLL_MUST_BE_POSITIVE			>
EC <	call	FloatGetStackDepth				>
EC <	cmp	ax, bx						>
EC <	ERROR_L	INSUFFICIENT_ARGUMENTS_ON_STACK			>
	clr	ax
	call	FloatHardwareEnter
	jc	done
	; if N < the hardware stack size we don't have to deal with
	; the software stack at all, just pop off the top N elements
	; into memory and then push them back on in the right order
	cmp	bl, INTEL_STACK_SIZE
	jg	doSoftwareRoll
	cmp	bl, 1
	je	myleave		; do nothing to roll 1 element
	; push the first one onto the bottom position in memory
	; then push the rest starting from position 0 down to N-2
	mov	al, FPSIZE
	mul	bl
	lea	di, tempStack
	add	di, ax
	sub	di, FPSIZE
	; store the first one at the bottom
	fstp	{FloatNum}ss:[di]
	lea	di, tempStack
	dec	bl
	clr	ch
	mov	cl, bl
	; now store the rest on the current order
storeloop:
	fstp	{FloatNum}ss:[di]
	add	di, FPSIZE
	loop	storeloop
	mov	cl, bl
	inc	cl
	; since we stored them in the right order, we can just push
	; them back on in the order they lie in memory starting from the
	; bottom
loadloop:
	fld	{FloatNum}ss:[di]			
	sub	di, FPSIZE
	loop	loadloop
myleave:
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
doSoftwareRoll:
	; for the case in which N > the hardware stack size...
	; first pop off the top element, push in onto the software
	; stack, RollDown the software stack by (N - (INTEL_STACK_SIZE-1))
	; pop the top element off the software stack and push it onto the
	; top of the hardware stack
	fstp	{FloatNum}tempStack	; pop off the top element
	fwait
	mov	cx, bx
	call	FloatGetSoftwareStackHandle
	call	MemLock			; lock down the software stack
	push	bx
	mov	es, ax
	segmov	ds, ss, si
	lea	si, tempStack
	call	FloatPushNumberInternal	; push old top element onto software
	segxchg	ds, es			; stack
	mov	bx, cx
	sub	bx, (INTEL_STACK_SIZE - 1)
	call	FloatRollDownInternal	; now roll softeware stack
	lea	di, tempStack
	call	FloatPopNumberInternal	; pop top element off of software
	fld	{FloatNum}tempStack	; push it onto hardware stack
	fincstp
	pop	bx
	call	MemUnlock		; unlock software stack
	jmp	myleave		
Intel80X87RollDown	endp
	public	Intel80X87RollDown


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Rot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rotates first three numbers on fp stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Rot	proc	far
	.enter
EC <	call	FloatGetStackDepth				>
EC <	cmp	ax, 3						>
EC <	ERROR_L	INSUFFICIENT_ARGUMENTS_ON_STACK			>
	clr	ax
	call	FloatHardwareEnter
	jc	done

				; start: fp: x1 x2 x3 (x3 = top)
	fxch			; 	 fp: x1 x3 x2
	fxch	st(2)		; 	 fp: x2 x3 x1
	call	Intel80X87CheckNormalNumberAndLeave
done: 
	.leave
	ret
Intel80X87Rot	endp
	public	Intel80X87Rot


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Round
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	round off number on top of FP stack

CALLED BY:	GLOBAL

PASS:		al = number of decimal places to round to

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Round	proc	far
int16	local	word	push	ax
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	
	; now multiply by 10^ax
	and	int16, 00ffh
	fild	int16		; st = ax


	fldl2t
	fmulp
	call	Intel80X87_2ToTheX	; st = 10^ax
	fxch
	fld	st(1)			; dup 10^ax
	fmulp				; st = st*10^ax	
	frndint				; round to nearest int
	fdivrp				; st = st(1)/10^ax
	mov	ax, -2
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Round	endp
	public	Intel80X87Round


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sinh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = sinh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry flag set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	
	; sinh(x) = (e^x - e^-x)/2

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Intel80X87Sinh	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fldl2e
	fmulp
	call	Intel80X87_2ToTheX
	fld1
	fdivr	st, st(1)
	fsubp
	fidiv	cs:[int87Two]
	mov	ax, -1
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sinh	endp
	public	Intel80X87Sinh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sqr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st*st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sqr	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fmul	st, st
			; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sqr	endp
	public	Intel80X87Sqr


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sqrt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = st^1/2

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sqrt	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fsqrt
			; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sqrt	endp
	public	Intel80X87Sqrt


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sqrt2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = square root of 2

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
int87Sqrt2   FloatNum <0x6485, 0xF9DE, 0xF333, 0xB504, 0x3FFF>

Intel80X87Sqrt2	proc	far
	uses	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	cs:[int87Sqrt2]
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:	
	.leave
	ret
Intel80X87Sqrt2	endp
	public	Intel80X87Sqrt2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87AsciiToFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Given a parsed string, convert it into a floating point
		number.

CALLED BY:	GLOBAL ()

PASS:		al - FloatAsciiToFloatFlags
		    FAF_PUSH_RESULT - place result onto the fp stack
		    FAF_STORE_NUMBER - store result into the location given by
			es:di
		cx - number of characters in the string that the routine
		    should concern itself with
		ds:si - string in this format:

		    "[+-] dddd.dddd [Ee] [+-] dddd"

		    Notes:
		    ------

		    * The string is assumed to be legal because duplicating
		    the error checking that is done in the parser seems
		    unnecessary.

		    * There can be at most a single decimal point.

		    * Spaces and thousands seperators are ignored.

RETURN:		carry clear if successful
		carry set if error

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87AsciiToFloat	proc	far
myfloat	local	FloatNum
	uses	ds, es, di, bx, ax
	.enter
	mov_tr	bx, ax
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	mov_tr	ax, bx
	call	FloatAsciiToFloatInternal
	jc	error				;branch if error
	test	al, mask FAF_PUSH_RESULT
	jz	error		; not really an error but same code
	call	FloatGetSoftwareStackHandle
	call	MemLock
	mov	ds, ax
	segmov	es, ss, di
	lea	di, myfloat
	call	FloatPopNumberInternal
	call	MemUnlock
	fld	myfloat
finish:
	clr	ax
leaveHardware:
	pushf
	call	FloatHardwareLeave		;clears carry (no error)
	popf
done:
	.leave
	ret
error:
	mov	ax, -1
	jmp	leaveHardware
Intel80X87AsciiToFloat	endp
	public	Intel80X87AsciiToFloat


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st(1) = st(1) - st, st popped off

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sub	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
	fsub
	dec	ax	; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sub	endp
	public	Intel80X87Sub


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Swap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	swap top two stack registers

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Swap	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check2Args			>
	fxch	
			; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Swap	endp
	public	Intel80X87Swap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Tan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = tan(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Tan	proc	far
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fptan
	fdivp
	neg	ax	; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Tan	endp
	public	Intel80X87Tan


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Tanh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = tanh(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

	; tanh(x)  = (e^x - e^-x) / (e^x + e^-x)

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Tanh	proc	far
	.enter
	mov	ax, 3
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
   	fld	st			; FloatDup  	(fp: z z)

	fldl2e				; FloatExp
	fmulp				;  ...
	call	Intel80X87_2ToTheX	;  ...	    	(fp: z a)

	fxch				; FloatSwap	(fp: e^z z)

	fchs				; FloatNegate	(fp: e^z -z)

	fldl2e				; FloatExp	(fp: e^z -z l2e)
	fmulp				;  ...		(fp: e^z -z*l2e)
	call	Intel80X87_2ToTheX	;  ...		(fp: e^z e^-z)
	
	; a = e^z, b = e^-z

	fld	st(1)			; FloatOver	(fp: a b a)
	fld	st(1)			; FloatOver	(fp: a b a b)
	
	fsubp				; FloatSub	(fp: a b a-b)

	fxch	st(2)			; FloatRot/	(fp: a-b b a)
	fxch				; FloatRot	(fp: a-b a b)
	faddp				; FloatAdd	(fp: a-b a+b)
	fdivp				; FloatDivide	(fp: tanh)
	neg	ax		; (ax still 3)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Tanh	endp
	public	Intel80X87Tanh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87_2ToTheX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = 2^st

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	
		because the only thing we get in hardware is
		2^x - 1 when 0 <= x <= .5 we must do some silly things

		since 2^x = (2^integerpart(x))(2^fractionalpart(x))
		
		first, if x is negative, set sign = minus, x = -x;

		we can do the following :
			let y = integerpart(x)
			let z = fractionalpart(x)
			
			now to get s = 2^y do the following
			s = 1;
			while (y--)
				s*=2;

			now if z <= .5 we can just call 2xm1 and add 1
			else let z = z - .5, and do a 2xm1 and add 1
				and the do another 2xm1 add 1 on remaining z


			if (sign == minus) we must invert the answer

KNOWN BUGS/SIDEFFECTS/IDEAS:
		the routine increases the stack by up to ONE
		element at the most at any one time

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/21/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87_2ToTheX	proc	near
sign		local	word
fractPart	local	FloatNum		; fractional part
tempFloat	local	FloatNum
	uses	 ax, bx, cx, dx, di, si
	.enter

	; first, get the sign of the operand (stored in SW_CONDITION_CODE_0 of
	; status, which is 1 if the thing is negative)
	ftst
	StatusToAX
	mov	sign, ax
	test	ax, mask SW_CONDITION_CODE_2
	jnz	error		; => it's NaN or something similarly evil
	test	ax, mask SW_CONDITION_CODE_3
	jz	notZero		; see if the exponent is zero
	fstp	st		; pop off zero
	mov	sign, 1
	fild	sign		; load in a 1 as anything^0 = 1
	jmp	done		
notZero:
;	test	ax, mask SW_CONDITION_CODE_3
;	jnz	error		; => it's NaN or something similarly evil

	; now that we have the sign, make it positive
	fabs
	; get the fractional and integer parts

	; now to get the integer part of x, chop x
	fld	st					; first save x
	call	Intel80X87TruncInternal			; chop x
		
	; now to get fractional part, subtract chopped part from original
	fsub	st(1)		; st <- int, st(1) <- frac
	fxch
	fstp	fractPart	; save fractional
	fld1
	fscale			; st <- 2^int

	fstp	tempFloat
	fstp	st		; drop int

	; now see if the fractional part is <= .5
	fld	fractPart 
	fld	cs:[int87PointFive]
	fcom
	StatusToAX
	sahf
	jp	error
	jae	doRest

	; if so then jump ahead and finish up
	; otherwise, do 2^.5, and then do 2^(fractPart-.5) and
	; muliply the two halves together
	; 2^.5 is just sqrt(2), of course, so...

	fsub			; st <- st(1)-.5
	f2xm1
	fld1
	faddp
	fld	cs:[int87Sqrt2]	; want full precision, so load treal...
	fmulp
	jmp	combineAnswer
doRest:
	fstp	st		; pop the .5
	f2xm1
	fld1
	faddp				; st = 2^fractPart
combineAnswer:
	fld	tempFloat	; recover 2^int
	fmulp	
	; if negative, 2^(-x) = 1/(2^x), so do st = 1/st
	test	sign, mask SW_CONDITION_CODE_0
	jz	done
	fld1
	fdivrp
done:
	.leave
	ret
error:
	stc
	jmp	done
Intel80X87_2ToTheX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X8710ToTheX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = 10^st

CALLED BY:	GLOBAL

PASS:		ax = exponent

RETURN:		carry set on error

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
	; 10ToTheX(x) = 2^(x*lg(10))

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X8710ToTheX	proc	far
myint	local	word	push	ax
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
	fild	myint
	fldl2t
	fmulp
	call	Intel80X87_2ToTheX
	mov	ax, -1
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X8710ToTheX	endp
	public	Intel80X8710ToTheX


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Trunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = trucn(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on error

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/12/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Trunc	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	call	Intel80X87TruncInternal
		; (ax still 0)
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Trunc	endp
	public	Intel80X87Trunc


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87TruncInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = trunc(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87TruncInternal	proc	near
	uses	ax
	.enter
	call	Intel80X87SetChop
	frndint
	call	Intel80X87SetNearest
	.leave
	ret
Intel80X87TruncInternal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87FloatToDword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pop off st and put it into dx:ax

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		dx:ax = top of stack which is then popped off

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 1/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87FloatToDword	proc	far
int32	local	dword
	.enter
	mov	ax, 0
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fistp	int32
	fwait
	dec	ax	; (ax still 0)
	call	FloatHardwareLeave
	movdw	dxax, int32
done:	
	.leave
	ret
Intel80X87FloatToDword	endp
	public	Intel80X87FloatToDword


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87FloatToDword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pop off st and put it into dx:ax

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		dx:ax = top of stack which is then popped off

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 1/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87FloatToUnsigned	proc	far
int32b	local	dword
int32	local	dword
	.enter
	mov	ax, 0
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
	fistp	{qword} int32
	fwait
	dec	ax	; (ax still 0)
	call	FloatHardwareLeave
	movdw	dxax, int32
done:	
	.leave
	ret
Intel80X87FloatToUnsigned	endp
	public	Intel80X87FloatToUnsigned


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87DwordToFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a dword integer on the fp stack

CALLED BY:	GLOBAL

PASS:		dx:ax dword integer

RETURN:		integer on top of fp stack

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87DwordToFloat	proc	far
int32	local	dword	push	dx, ax
	uses	dx
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fild	int32
	fwait
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87DwordToFloat	endp
	public	Intel80X87DwordToFloat

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87UnsignedToFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a dword integer on the fp stack

CALLED BY:	GLOBAL

PASS:		dx:ax dword integer

RETURN:		integer on top of fp stack

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87UnsignedToFloat	proc	far
int32b	local	dword
int32	local	dword
	uses	dx
	.enter
	mov	int32b.low, 0
	mov	int32b.high, 0
	mov	int32.low, ax
	mov	int32.high, dx

	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fild	{qword} int32
	fwait
	clr	ax
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87UnsignedToFloat	endp
	public	Intel80X87UnsignedToFloat

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87WordToFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put a word integer onto the fp stack

CALLED BY:	GLOBAL

PASS:		ax = word integer

RETURN:		integer on top of fp stack

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87WordToFloat	proc	far
int16	local	word	push	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fild	int16
	fwait
	dec	ax		; (ax still 1)
	call	Intel80X87CheckNormalNumberAndLeave
done:	
	.leave
	ret
Intel80X87WordToFloat	endp
	public	Intel80X87WordToFloat


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87GetStackPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the top of the fp stack pointer

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = top of stack pointer

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:
		Primarily for use by applications for error recovery.
		Applications can bail out of involved operations by saving
		the stack pointer prior to commencing operations and
		restoring the stack pointer in the event of an error.

		NOTE:
		-----
		If you set the stack pointer, the current stack pointer
		must be less than or equal to the value you pass. Ie.
		you must be throwing something (or nothing) away.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87GetStackPointer	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	call	FloatGetStackDepth
	push	ax
	clr	ax
	call	FloatHardwareLeave
	pop	ax
done:
	.leave
	ret
Intel80X87GetStackPointer	endp
	public	Intel80X87GetStackPointer


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87SetStackPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the top of the fp stack pointer

CALLED BY:	GLOBAL

PASS:		ax = new value for top of stack pointer

RETURN:		carry set on error

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

		the new value passes must be >= current value of top of stack

KNOWN BUGS/SIDEFFECTS/IDEAS:
		Primarily for use by applications for error recovery.
		Applications can bail out of involved operations by saving
		the stack pointer prior to commencing operations and
		restoring the stack pointer in the event of an error.

		NOTE:
		-----
		If you set the stack pointer, the current stack pointer
		must be greater than or equal to the value you pass. Ie.
		you must be throwing something (or nothing) away.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87SetStackPointer	proc	far
dummy		local	FloatNum
stackDepth	local	word
newDepth	local	word
poppedOffH	local	word
memHandle	local	hptr
	uses	bx, cx, es, di, ds, ax
	.enter
	mov	newDepth, ax
	clr	ax
	call	FloatHardwareEnter
	LONG jc	done
	; first, get rid of stuff on hardware stack that is not needed
	; calculate how many numbers to pop off
	mov	bx, newDepth
	call	FloatGetStackDepth	; ax = current depth	
	; if we are already at the depth we want to set do nothing
	mov	stackDepth, ax
	sub	ax, bx
	LONG je	done2	; we are already there, so go home
	cmp	ax, INTEL_STACK_SIZE
	jge	initializeHardware
	mov	cx, ax
	; pop off numbers
poploopHardware:
	fstp	st
	loop 	poploopHardware
	mov	poppedOffH, ax
	clr	ax
	jmp	clearSoftware
initializeHardware:
	; if more than INTEL_STACK_SIZE things are popped off,
	; then just do an finit, and pop the rest off the
	; software stack
	finit
	sub	ax, INTEL_STACK_SIZE	
	mov	poppedOffH, INTEL_STACK_SIZE
clearSoftware:
	mov	bx, stackDepth
	cmp	bx, INTEL_STACK_SIZE
	jle	done	
	push	ax

	; set up the software stack block
	call	FloatGetSoftwareStackHandle
	mov	memHandle, bx
	call	MemLock	
	mov	ds, ax
	segmov	es, ss
	lea	di, dummy		; es:di <- dummy
	pop	cx
	jcxz	swapIn

	; pop off numbers off the software stack
poploopSoftware:
	call	FloatPopNumberInternal
	loop	poploopSoftware
swapIn:
	mov	cx, INTEL_STACK_SIZE	; used a lot here so put in cx
	; no figure out how much room is left on the hardware stack
	; to move things up from the software stack, and see how many
	; numbers are left on the software stack to move up
	mov	bx, cx
	sub	bx, poppedOffH	; bx = actual depth of hardware stack now
	mov	ax, cx
	sub	ax, bx
	mov	bx, newDepth
	cmp	bx, cx
	jg	doSwap
	sub	bx, cx
	add	ax, bx
	tst	ax
	jz	doneMemUnlock
doSwap:
	mov	cx, poppedOffH
	dec	cx
	tst	cx
	jz	afterSetUp

	; set up stack pointer in hardware so that the numbers get
	; pushed on in the right order, they have to be pushed on in
	; reverse order from how they come off the softwares stack, so	
	; set up pointer, push one, and then increment the pointer
	; twice so that the next one goes in "before" the one just
	; pushed...
setUpPointer:
	fdecstp
	loop	setUpPointer
afterSetUp:
	mov	cx, ax
swapLoop:
	call	FloatPopNumberInternal
	fld	dummy
	fincstp
	fincstp
	loop	swapLoop

	; now we need to make sure that the hardware pointer is put
	; back to point and the correct top number	
;restore:
	mov	ax, newDepth
	cmp	ax, INTEL_STACK_SIZE
	jl	restoreLess
	mov	cx, 1
	jmp	restoreLoop
restoreLess:
	mov	cx, newDepth
	inc	cx
restoreLoop:
	fdecstp
	loop	restoreLoop	
doneMemUnlock:
	mov	bx, memHandle
	call	MemUnlock
done:
	mov	ax, newDepth
	call	FloatSetStackDepth
done2:
	clr	ax
	call	FloatHardwareLeave
	.leave
	ret
Intel80X87SetStackPointer	endp
	public	Intel80X87SetStackPointer


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87IEEE64ToGeos80
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a floating point number in IEEE 64 bit format into an
		fp number in Geos 80 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.
		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.

CALLED BY:	INTERNAL ()

PASS:	
		ds:si - IEEE 64 bit number

RETURN:		float number on the fp stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/15/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87IEEE64ToGeos80	proc	far
	uses	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	{qword}ds:[si]
	dec	ax		; (ax still 1)
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87IEEE64ToGeos80	endp
	public	Intel80X87IEEE64ToGeos80

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87IEEE32ToGeos80
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a floating point number in IEEE 32 bit format into an
		fp number in Geos 80 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		A 64 bit number has a 23 bit mantissa and a 9 bit exponent.
		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.

CALLED BY:	GLOBAL

PASS:	
		ds:ax = IEEE32 number

RETURN:		float number on the fp stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/15/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87IEEE32ToGeos80	proc	far
myfloat	local	dword	push	dx, ax
	uses	ax
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
	fld	myfloat
	fwait
	dec	ax		; (ax still 1)
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87IEEE32ToGeos80	endp
	public	Intel80X87IEEE32ToGeos80


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Geos80ToIEEE64
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a floating point number in Geos 80 bit format into an
		fp number in IEEE 64 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.
		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg
		es:di - location to store the IEEE 64 bit number

RETURN:		carry clear if successful
		carry set otherwise
		float number popped off stack in either case

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/15/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Geos80ToIEEE64	proc	far
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	{qword}es:[di]
	fwait
	mov	ax, -1
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87Geos80ToIEEE64	endp
	public Intel80X87Geos80ToIEEE64

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Geos80ToIEEE32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a floating point number in Geos 80 bit format into an
		fp number in IEEE 32 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.
		A 64 bit number has a 23 bit mantissa and a 9 bit exponent.

CALLED BY:	GLOBAL

PASS:		number on fp stack

RETURN:		carry clear if successful
		carry set otherwise
		dx:ax = IEEE32 number
		float number popped off stack in either case

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/15/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Geos80ToIEEE32	proc	far
myfloat	local	dword
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstp	myfloat
	fwait
	dec	ax	; (ax still 0)
	call	FloatHardwareLeave
	jc	done
	movdw	dxax, myfloat
done:
	.leave
	ret
Intel80X87Geos80ToIEEE32	endp
	public Intel80X87Geos80ToIEEE32


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Epsilon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	produces an epsilon value based on the top fp number

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/30/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Epsilon	proc	far
myfloat local	FloatNum
	.enter
	mov	ax, 1
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>
   	fld	st		; duplicate, as it must remain on the
				;  stack.
	fstp	myfloat
	clr	ax
	mov	myfloat.F_mantissa_wd3, ax
	mov	myfloat.F_mantissa_wd2, ax
	mov	myfloat.F_mantissa_wd1, ax
	mov	myfloat.F_mantissa_wd0, 1
	fld	myfloat
	call	FloatHardwareLeave
done:
	.leave
	ret
Intel80X87Epsilon	endp
	public Intel80X87Epsilon


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		INTEL80X87FSTSW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the status word of the coprocessor

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = status word

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/24/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global INTEL80X87FSTSW:far
INTEL80X87FSTSW	proc	far
status	local	StatusWord
	.enter
	clr	ax
	call	FloatHardwareEnter
	jc	done
	fstsw	status
	fwait
	call	FloatHardwareLeave
	mov	ax, status
done:
	.leave
	ret
INTEL80X87FSTSW	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Err
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push an ERROR NAN on the stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/16/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Err	proc	near
	.enter
	fld	{FloatNum}tableErr
	.leave
	ret
Intel80X87Err	endp


tableErr	label	word
	word	0, 0, 0, 0c000h, FP_NAN
CommonCode	ends
