
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatGlobal.asm

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	Global routines which may go through a dispatch routine.

	$Id: floatGlobal.asm,v 1.1 97/04/05 01:23:01 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	floating point routines.

DESCRIPTION:	

CALLED BY:	GLOBAL ()

PASS:		

RETURN:		carry set on error
		    al - FloatErrorType

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Many of the common float routines have been written such that:
	    * arguments are never passed in bp
	    * they expect ds to contain the floating point stack segment
	    * they are not allowed to destroy registers except for ax and dx
	
	Since the requirements are similar, it makes sense to have a common
	dispatch routine.

	To make a routine that complies with these conditions global,

	1. assign a constant for the routine in the FloatGlobals list
	2. place an entry in the CORRESPONDING position in tableGlobals
	3. write an entry routine of the form

		RoutineName	proc	far
			push	bp
			mov	bp, ROUTINE_NAME_CONSTANT
			GOTO    FloatDispatch, bp
		RoutineName	endp

	4. add entries to float.gp, floatManager.asm and Include/math.def

	To find out more about the routines, please look up the routine headers
	of the near routines.

	I originally thought that it might be a good idea to break up the
	library into 2 code resources, one for the common routines and
	the other for the transcendental routines.  The cost
	involved (all common routines made far, and proc calls from
	the transcendental resource) seems too great though, so it's
	shelved for now.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	The routines that take no arguments and either have no return values
	or return a byte or word in ax are handled specially so that CStubs
	those routines do not have to be written, they are defined in all
	CAPS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FLOATMINUS1	proc	far
	push	bp
	mov	bp, FLOAT_MINUS1
	GOTO	FloatDispatch, bp
FLOATMINUS1	endp

FLOATMINUSPOINT5	proc	far
	push	bp
	mov	bp, FLOAT_MINUS_POINT5
	GOTO	FloatDispatch, bp
FLOATMINUSPOINT5	endp

FLOAT0	proc	far
	push	bp
	mov	bp, FLOAT_0
	GOTO	FloatDispatch, bp
FLOAT0	endp

FLOATPOINT5	proc	far
	push	bp
	mov	bp, FLOAT_POINT5
	GOTO	FloatDispatch, bp
FLOATPOINT5	endp

FLOAT1	proc	far
	push	bp
	mov	bp, FLOAT_1
	GOTO	FloatDispatch, bp
FLOAT1	endp

FLOAT2	proc	far
	push	bp
	mov	bp, FLOAT_2
	GOTO	FloatDispatch, bp
FLOAT2	endp

FLOAT5	proc	far
	push	bp
	mov	bp, FLOAT_5
	GOTO	FloatDispatch, bp
FLOAT5	endp

FLOAT10	proc	far
	push	bp
	mov	bp, FLOAT_10
	GOTO	FloatDispatch, bp
FLOAT10	endp

FLOAT3600	proc	far
	push	bp
	mov	bp, FLOAT_3600
	GOTO	FloatDispatch, bp
FLOAT3600	endp

FLOAT16384	proc	far
	push	bp
	mov	bp, FLOAT_16384
	GOTO	FloatDispatch, bp
FLOAT16384	endp

FLOAT86400	proc	far
	push	bp
	mov	bp, FLOAT_86400
	GOTO	FloatDispatch, bp
FLOAT86400	endp

FLOATADD	proc	far
	push	bp
	mov	bp, FLOAT_ADD
	GOTO	FloatDispatch, bp
FLOATADD	endp

FLOATDIV	proc	far
	push	bp
	mov	bp, FLOAT_DIV
	GOTO	FloatDispatch, bp
FLOATDIV	endp

FLOATDIVIDE	proc	far
	push	bp
	mov	bp, FLOAT_DIVIDE
	GOTO	FloatDispatch, bp
FLOATDIVIDE	endp

FLOATDIVIDE2	proc	far
	push	bp
	mov	bp, FLOAT_DIVIDE2
	GOTO	FloatDispatch, bp
FLOATDIVIDE2	endp

FLOATDIVIDE10	proc	far
	push	bp
	mov	bp, FLOAT_DIVIDE10
	GOTO	FloatDispatch, bp
FLOATDIVIDE10	endp

FloatDwordToFloatFar	proc	far
	push	bp
	mov	bp, FLOAT_DWORD_INT_TO_FLOAT
	GOTO	FloatDispatch, bp
FloatDwordToFloatFar	endp

FLOATEPSILON	proc	far
	push	bp
	mov	bp, FLOAT_EPSILON
	GOTO	FloatDispatch, bp
FLOATEPSILON	endp

FLOATFACTORIAL	proc	far
	push	bp
	mov	bp, FLOAT_FACTORIAL
	GOTO	FloatDispatch, bp
FLOATFACTORIAL	endp

FLOATFRAC	proc	far
	push	bp
	mov	bp, FLOAT_FRAC
	GOTO	FloatDispatch, bp
FLOATFRAC	endp

FLOATINT	proc	far
	push	bp
	mov	bp, FLOAT_INT
	GOTO	FloatDispatch, bp
FLOATINT	endp

FLOATINTFRAC	proc	far
	push	bp
	mov	bp, FLOAT_INT_FRAC
	GOTO	FloatDispatch, bp
FLOATINTFRAC	endp

FLOATINVERSE	proc	far
	push	bp
	mov	bp, FLOAT_INVERSE
	GOTO	FloatDispatch, bp
FLOATINVERSE	endp

FLOATMAX	proc	far
	push	bp
	mov	bp, FLOAT_MAX
	GOTO	FloatDispatch, bp
FLOATMAX	endp

FLOATMIN	proc	far
	push	bp
	mov	bp, FLOAT_MIN
	GOTO	FloatDispatch, bp
FLOATMIN	endp

FLOATMOD	proc	far
	push	bp
	mov	bp, FLOAT_MOD
	GOTO	FloatDispatch, bp
FLOATMOD	endp

FLOATMULTIPLY	proc	far
	push	bp
	mov	bp, FLOAT_MULTIPLY
	GOTO	FloatDispatch, bp
FLOATMULTIPLY	endp

FLOATMULTIPLY2	proc	far
	push	bp
	mov	bp, FLOAT_MULTIPLY2
	GOTO	FloatDispatch, bp
FLOATMULTIPLY2	endp

FLOATMULTIPLY10	proc	far
	push	bp
	mov	bp, FLOAT_MULTIPLY10
	GOTO	FloatDispatch, bp
FLOATMULTIPLY10	endp

FLOATNEGATE	proc	far
	push	bp
	mov	bp, FLOAT_NEGATE
	GOTO	FloatDispatch, bp
FLOATNEGATE	endp

FLOATOVER	proc	far
	push	bp
	mov	bp, FLOAT_OVER
	GOTO	FloatDispatch, bp
FLOATOVER	endp

FLOATRANDOM	proc	far
	push	bp
	mov	bp, FLOAT_RANDOM
	GOTO	FloatDispatch, bp
FLOATRANDOM	endp

FLOATRANDOMN	proc	far
	push	bp
	mov	bp, FLOAT_RANDOM_N
	GOTO	FloatDispatch, bp
FLOATRANDOMN	endp

FloatRollFar	proc	far
	push	bp
	mov	bp, FLOAT_ROLL
	GOTO	FloatDispatch, bp
FloatRollFar	endp

FloatRollDownFar	proc	far
	push	bp
	mov	bp, FLOAT_ROLL_DOWN
	GOTO	FloatDispatch, bp
FloatRollDownFar	endp

FLOATROT	proc	far
	push	bp
	mov	bp, FLOAT_ROT
	GOTO	FloatDispatch, bp
FLOATROT	endp

FloatRoundFar	proc far
	push	bp
	mov	bp, FLOAT_ROUND
	GOTO	FloatDispatch, bp
FloatRoundFar	endp

FLOATSUB	proc	far
	push	bp
	mov	bp, FLOAT_SUB
	GOTO	FloatDispatch, bp
FLOATSUB	endp

FLOATSWAP	proc	far
	push	bp
	mov	bp, FLOAT_SWAP
	GOTO	FloatDispatch, bp
FLOATSWAP	endp

FLOAT10TOTHEX	proc	far
	push	bp
	mov	bp, FLOAT_10_TO_THE_X
	GOTO	FloatDispatch, bp
FLOAT10TOTHEX	endp

FLOATTRUNC	proc	far
	push	bp
	mov	bp, FLOAT_TRUNC
	GOTO	FloatDispatch, bp
FLOATTRUNC	endp

FloatWordToFloatFar	proc	far
	push	bp
	mov	bp, FLOAT_WORD_INT_TO_FLOAT
	GOTO	FloatDispatch, bp
FloatWordToFloatFar	endp

;
; transcendental routines follow
;

FLOATARCCOS	proc	far
	push	bp
	mov	bp, FLOAT_ARC_COS
	GOTO	FloatDispatch, bp
FLOATARCCOS	endp

FLOATARCCOSH	proc	far
	push	bp
	mov	bp, FLOAT_ARC_COSH
	GOTO	FloatDispatch, bp
FLOATARCCOSH	endp

FLOATARCSIN	proc	far
	push	bp
	mov	bp, FLOAT_ARC_SIN
	GOTO	FloatDispatch, bp
FLOATARCSIN	endp

FLOATARCSINH	proc	far
	push	bp
	mov	bp, FLOAT_ARC_SINH
	GOTO	FloatDispatch, bp
FLOATARCSINH	endp

FLOATARCTAN	proc	far
	push	bp
	mov	bp, FLOAT_ARC_TAN
	GOTO	FloatDispatch, bp
FLOATARCTAN	endp

FLOATARCTAN2	proc	far
	push	bp
	mov	bp, FLOAT_ARC_TAN2
	GOTO	FloatDispatch, bp
FLOATARCTAN2	endp

FLOATARCTANH	proc	far
	push	bp
	mov	bp, FLOAT_ARC_TANH
	GOTO	FloatDispatch, bp
FLOATARCTANH	endp

FLOATCOS	proc	far
	push	bp
	mov	bp, FLOAT_COS
	GOTO	FloatDispatch, bp
FLOATCOS	endp

FLOATCOSH	proc	far
	push	bp
	mov	bp, FLOAT_COSH
	GOTO	FloatDispatch, bp
FLOATCOSH	endp

FLOATEXP	proc	far
	push	bp
	mov	bp, FLOAT_EXP
	GOTO	FloatDispatch, bp
FLOATEXP	endp

FLOATEXPONENTIAL	proc	far
	push	bp
	mov	bp, FLOAT_EXPONENTIAL
	GOTO	FloatDispatch, bp
FLOATEXPONENTIAL	endp

FLOATLG	proc	far
	push	bp
	mov	bp, FLOAT_LG
	GOTO	FloatDispatch, bp
FLOATLG	endp

FLOATLG10	proc	far
	push	bp
	mov	bp, FLOAT_LG10
	GOTO	FloatDispatch, bp
FLOATLG10	endp

FLOATLN	proc	far
	push	bp
	mov	bp, FLOAT_LN
	GOTO	FloatDispatch, bp
FLOATLN	endp

FLOATLN1PLUSX	proc	far
	push	bp
	mov	bp, FLOAT_LN1PLUSX
	GOTO	FloatDispatch, bp
FLOATLN1PLUSX	endp

FLOATLN2	proc	far
	push	bp
	mov	bp, FLOAT_LN2
	GOTO	FloatDispatch, bp
FLOATLN2	endp

FLOATLN10	proc	far
	push	bp
	mov	bp, FLOAT_LN10
	GOTO	FloatDispatch, bp
FLOATLN10	endp

FLOATLOG	proc	far
	push	bp
	mov	bp, FLOAT_LOG
	GOTO	FloatDispatch, bp
FLOATLOG	endp

FLOATPI	proc	far
	push	bp
	mov	bp, FLOAT_PI
	GOTO	FloatDispatch, bp
FLOATPI	endp

FLOATPIDIV2	proc	far
	push	bp
	mov	bp, FLOAT_PI_DIV_2
	GOTO	FloatDispatch, bp
FLOATPIDIV2	endp

FLOATSIN	proc	far
	push	bp
	mov	bp, FLOAT_SIN
	GOTO	FloatDispatch, bp
FLOATSIN	endp

FLOATSINH	proc	far
	push	bp
	mov	bp, FLOAT_SINH
	GOTO	FloatDispatch, bp
FLOATSINH	endp

FLOATSQR	proc	far
	push	bp
	mov	bp, FLOAT_SQR
	GOTO	FloatDispatch, bp
FLOATSQR	endp

FLOATSQRT	proc	far
	push	bp
	mov	bp, FLOAT_SQRT
	GOTO	FloatDispatch, bp
FLOATSQRT	endp

FLOATSQRT2	proc	far
	push	bp
	mov	bp, FLOAT_SQRT2
	GOTO	FloatDispatch, bp
FLOATSQRT2	endp

FLOATTAN	proc	far
	push	bp
	mov	bp, FLOAT_TAN
	GOTO	FloatDispatch, bp
FLOATTAN	endp

FLOATTANH	proc	far
	push	bp
	mov	bp, FLOAT_TANH
	GOTO	FloatDispatch, bp
FLOATTANH	endp

;
; mr. dispatch routine
;

FloatDispatch	proc	far

	push	dx,ds	; save registers that routines can destroy
	mov	bp, cs:tableGlobals[bp]	; get addr of routine
	call	FloatEnter	; ds <- fp stack seg
	call	bp		; call routine

	call	FloatIsNoNAN1	; is the result an error code?
	cmc			; carry is a boolean, so flip bit

	jnc	done

	call	FloatIsInfinity	; al <- error code
	stc			; FloatIsInfinity clears carry if non-inf

done:
	call	FloatOpDone	; unlock the fp stack
	pop	dx,ds	; restore registers
	FALL_THRU_POP bp
	ret
FloatDispatch	endp

FloatGlobals	etype byte, 0, 2
FLOAT_MINUS1			enum	FloatGlobals
FLOAT_MINUS_POINT5		enum	FloatGlobals
FLOAT_0				enum	FloatGlobals
FLOAT_POINT5			enum	FloatGlobals
FLOAT_1				enum    FloatGlobals
FLOAT_2				enum    FloatGlobals
FLOAT_5				enum    FloatGlobals
FLOAT_10			enum    FloatGlobals
FLOAT_3600			enum    FloatGlobals
FLOAT_16384			enum    FloatGlobals
FLOAT_86400			enum    FloatGlobals

FLOAT_ADD			enum    FloatGlobals
FLOAT_DIV			enum    FloatGlobals
FLOAT_DIVIDE			enum    FloatGlobals
FLOAT_DIVIDE2			enum    FloatGlobals
FLOAT_DIVIDE10			enum    FloatGlobals
FLOAT_DWORD_INT_TO_FLOAT	enum    FloatGlobals
FLOAT_EPSILON			enum    FloatGlobals
FLOAT_FACTORIAL			enum    FloatGlobals
FLOAT_FRAC			enum    FloatGlobals
FLOAT_INT			enum    FloatGlobals
FLOAT_INT_FRAC			enum    FloatGlobals
FLOAT_INVERSE			enum    FloatGlobals
FLOAT_MAX			enum    FloatGlobals
FLOAT_MIN			enum    FloatGlobals
FLOAT_MOD			enum    FloatGlobals
FLOAT_MULTIPLY			enum    FloatGlobals
FLOAT_MULTIPLY2			enum    FloatGlobals
FLOAT_MULTIPLY10		enum    FloatGlobals
FLOAT_NEGATE			enum    FloatGlobals
FLOAT_OVER			enum    FloatGlobals
FLOAT_RANDOM			enum    FloatGlobals
FLOAT_RANDOM_N			enum    FloatGlobals
FLOAT_ROLL			enum    FloatGlobals
FLOAT_ROLL_DOWN			enum    FloatGlobals
FLOAT_ROT			enum    FloatGlobals
FLOAT_ROUND			enum    FloatGlobals
FLOAT_SUB			enum    FloatGlobals
FLOAT_SWAP			enum    FloatGlobals
FLOAT_10_TO_THE_X		enum    FloatGlobals
FLOAT_TRUNC			enum    FloatGlobals
FLOAT_WORD_INT_TO_FLOAT		enum    FloatGlobals
;
; transcendental routines follow
;
FLOAT_ARC_COS			enum    FloatGlobals
FLOAT_ARC_COSH			enum    FloatGlobals
FLOAT_ARC_SIN			enum    FloatGlobals
FLOAT_ARC_SINH			enum    FloatGlobals
FLOAT_ARC_TAN			enum    FloatGlobals
FLOAT_ARC_TAN2			enum    FloatGlobals
FLOAT_ARC_TANH			enum    FloatGlobals
FLOAT_COS			enum    FloatGlobals
FLOAT_COSH			enum    FloatGlobals
FLOAT_EXP			enum    FloatGlobals
FLOAT_EXPONENTIAL		enum    FloatGlobals
FLOAT_LG			enum    FloatGlobals
FLOAT_LG10			enum    FloatGlobals
FLOAT_LN			enum    FloatGlobals
FLOAT_LN1PLUSX			enum    FloatGlobals
FLOAT_LN2			enum    FloatGlobals
FLOAT_LN10			enum    FloatGlobals
FLOAT_LOG			enum    FloatGlobals
FLOAT_PI			enum    FloatGlobals
FLOAT_PI_DIV_2			enum    FloatGlobals
FLOAT_SIN			enum    FloatGlobals
FLOAT_SINH			enum    FloatGlobals
FLOAT_SQR			enum    FloatGlobals
FLOAT_SQRT			enum    FloatGlobals
FLOAT_SQRT2			enum    FloatGlobals
FLOAT_TAN			enum    FloatGlobals
FLOAT_TANH			enum    FloatGlobals

tableGlobals	label	word
	word	offset FloatMinus1
	word	offset FloatMinusPoint5
	word	offset Float0
	word	offset FloatPoint5
	word	offset Float1
	word	offset Float2
	word	offset Float5
	word	offset Float10
	word	offset Float3600
	word	offset Float16384
	word	offset Float86400
	word	offset FloatAdd
	word	offset FloatDIV
	word	offset FloatDivide
	word	offset FloatDivide2
	word	offset FloatDivide10
	word	offset FloatDwordToFloat
	word	offset FloatEpsilon
	word	offset FloatFactorial
	word	offset FloatFrac
	word	offset FloatInt
	word	offset FloatIntFrac
	word	offset FloatInverse
	word	offset FloatMax
	word	offset FloatMin
	word	offset FloatMod
	word	offset FloatMultiply
	word	offset FloatMultiply2
	word	offset FloatMultiply10
	word	offset FloatNegate
	word	offset FloatOver
	word	offset FloatRandom
	word	offset FloatRandomN
	word	offset FloatRoll
	word	offset FloatRollDown
	word	offset FloatRot
	word	offset FloatRound
	word	offset FloatSub
	word	offset FloatSwap
	word	offset Float10ToTheX
	word	offset FloatTrunc
	word	offset FloatWordToFloat
	;
	; transcendental routines follow
	;
	word	offset FloatArcCos
	word	offset FloatArcCosh
	word	offset FloatArcSin
	word	offset FloatArcSinh
	word	offset FloatArcTan
	word	offset FloatArcTan2
	word	offset FloatArcTanh
	word	offset FloatCos
	word	offset FloatCosh
	word	offset FloatExp
	word	offset FloatExponential
	word	offset FloatLg
	word	offset FloatLg10
	word	offset FloatLn
	word	offset FloatLn1plusX
	word	offset FloatLn2
	word	offset FloatLn10
	word	offset FloatLog
	word	offset FloatPi
	word	offset FloatPiDiv2
	word	offset FloatSin
	word	offset FloatSinh
	word	offset FloatSqr
	word	offset FloatSqrt
	word	offset FloatSqrt2
	word	offset FloatTan
	word	offset FloatTanh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDepthFar

DESCRIPTION:	

CALLED BY:	GLOBAL ()

PASS:		nothing

RETURN:		ax - depth

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATDEPTH	proc	far	uses	bx,ds
	.enter
	call	FloatEnter

	mov	ax, ds:FSV_bottomPtr
	sub	ax, ds:FSV_topPtr
	mov	bl, FPSIZE
	div	bl

	call	FloatOpDone
	.leave
	ret
FLOATDEPTH	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatEnterFar

DESCRIPTION:	Lock the fp stack prior to access.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		ds - fp stack seg

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatEnterFar	proc	far
	call	FloatEnter
	ret
FloatEnterFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToDwordFar

DESCRIPTION:	

CALLED BY:	GLOBAL ()

PASS:		nothing

RETURN:		carry clear if successful
		    dx:ax - dword
		set otherwise
		    al - error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Can't use the dispatch routine because a result is returned in dx:ax.
	Also, don't want FloatDispatch to call FloatIsNoNAN1 on what remains.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATFLOATTODWORD	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatFloatToDword		; dx:ax <- dword
	jnc	done

	mov	al, FLOAT_GEN_ERR

done:
	call	FloatOpDone
	.leave
	ret
FLOATFLOATTODWORD	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatOpDoneFar

DESCRIPTION:	This routine unlocks the fp stack.  Called by the global
		routines when they are done accessing the fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		nothing

DESTROYED:	nothing, flags are preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatOpDoneFar	proc	far
	call	FloatOpDone
	ret
FloatOpDoneFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSetStackPointer

DESCRIPTION:	Primarily for use by applications for error recovery.
		Applications can bail out of involved operations by saving
		the stack pointer prior to commencing operations and
		restoring the stack pointer in the event of an error.

		NOTE:
		-----
		If you set the stack pointer, the current stack pointer
		must be less than or equal to the value you pass. Ie.
		you must be throwing something (or nothing) away.

CALLED BY:	GLOBAL ()

PASS:		ax - desired value of the stack pointer

RETURN:		carry clear if successful, set otherwise
		(dies in EC code if unsuccessful)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
			the only reason we bother to divide out and
			the multiply FPSIZE back in is so that the
		 	value that gets returned by GetStackPointer will
			then be the same as in the coprocesor case
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatSetStackPointer	proc	far	uses	ds, bx, dx
	.enter
	call	FloatEnter

	; ax = bottom-top/FPSZIE
	mov	bx, FPSIZE
	mul	bx		; ax = bottom-top
	; 
EC <	tst	dx							>
EC <	ERROR_NZ	FLOAT_BAD_STACK_POINTER				>
		
	sub	ax, ds:FSV_bottomPtr		
	; ax = (bottom-top)-bottom = -top
	neg	ax				; ax = top

	cmp	ax, ds:FSV_topPtr		; see that ax >= stkTop
	jb	err

	cmp	ax, ds:FSV_bottomPtr		; see that ax <= stkBot
	ja	err

	mov	ds:FSV_topPtr, ax		; stuff it
	
EC<	call	FloatCheckStack >
	clc
	jmp	short done

err:
	stc
EC<	ERROR	FLOAT_BAD_STACK_POINTER >

done:
	call	FloatOpDone
	.leave
	ret
FloatSetStackPointer	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLt0Far, FloatEq0Far, FloatGt0Far

DESCRIPTION:	( FP: X --- )

CALLED BY:	GLOBAL ()

PASS:		X on fp stack

RETURN:		carry - set if TRUE
			clear otherwise
		X is popped off

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLt0Far	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatLt0
	call	FloatOpDone
	.leave
	ret
FloatLt0Far	endp


FloatEq0Far	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatEq0
	call	FloatOpDone
	.leave
	ret
FloatEq0Far	endp


FloatGt0Far	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatGt0
	call	FloatOpDone
	.leave
	ret
FloatGt0Far	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRandomizeFar

DESCRIPTION:	Force the use of the given seed for random number generation.
		If the seed is small ( << 2^32 ), prime the random number
		generator before use by calling FloatRandom 3 or 4 times
		and discarding the results.

CALLED BY:	GLOBAL ()

PASS:		al - RandomGenInitFlags
		     RGIF_USE_SEED
		     RGIF_GENERATE_SEED
		cx:dx - seed if RGIF_USE_SEED

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatRandomizeFar	proc	far	uses	dx,ds
	.enter
	call	FloatEnter
	call	FloatRandomize
	call	FloatOpDone
	.leave
	ret
FloatRandomizeFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIEEE64ToGeos80Far

DESCRIPTION:	Convert a floating point number in IEEE 64 bit format into an
		fp number in Geos 80 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.
		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.

CALLED BY:	GLOBAL ()

PASS:		ds:si - IEEE 64 bit number

RETURN:		float number on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatIEEE64ToGeos80Far	proc	far	uses	es
	.enter
	call	FloatEnter_ES		; es <- fp stack seg
	call	FloatIEEE64ToGeos80
	call	FloatOpDone_ES		; unlock the fp stack
	.leave
	ret
FloatIEEE64ToGeos80Far	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGeos80ToIEEE64Far

DESCRIPTION:	Convert a floating point number in Geos 80 bit format into an
		fp number in IEEE 64 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.
		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.

CALLED BY:	INTERNAL ()

PASS:		es:di - location to store the IEEE 64 bit number

RETURN:		carry clear if successful
		carry set otherwise
		float number popped off stack in either case

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatGeos80ToIEEE64Far	proc	far	uses	ds
	.enter
	call	FloatEnter		; ds <- fp stack seg
	call	FloatGeos80ToIEEE64
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FloatGeos80ToIEEE64Far	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIEEE32ToGeos80Far

DESCRIPTION:	Convert a floating point number in IEEE 32 bit format into an
		fp number in Geos 80 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		A 32 bit number has a 23 bit mantissa and a 8 bit exponent.
			and a sign bit

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.

CALLED BY:	GLOBAL ()

PASS:		dx:ax = 32 bit number

RETURN:		float number on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatIEEE32ToGeos80Far	proc	far	uses	es
	.enter
	call	FloatEnter_ES		; es <- fp stack seg
	call	FloatIEEE32ToGeos80
	call	FloatOpDone_ES		; unlock the fp stack
	.leave
	ret
FloatIEEE32ToGeos80Far	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGeos80ToIEEE32Far

DESCRIPTION:	Convert a floating point number in Geos 80 bit format into an
		fp number in IEEE 32 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.
		A 32 bit number has a 23 bit mantissa and a 8 bit exponent
			and a sign bit.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		dx:ax = number popped off from stack into 32bit format

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatGeos80ToIEEE32Far	proc	far	uses	ds
	.enter
	call	FloatEnter		; ds <- fp stack seg
	call	FloatGeos80ToIEEE32
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FloatGeos80ToIEEE32Far	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetNumDigitsInIntegerPart

DESCRIPTION:	As routine says, eg. with 5678.956, routine returns 4.

CALLED BY:	INTERNAL ()

PASS:		X on the fp stack

RETURN:		ax - number of digits in the integer part
		X is popped off the stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FLOATGETNUMDIGITSININTEGERPART	proc	far	uses	dx,ds
	.enter
	call	FloatEnter		; ds <- fp stack seg
	call	FloatGetNumDigitsInIntegerPart
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FLOATGETNUMDIGITSININTEGERPART	endp
