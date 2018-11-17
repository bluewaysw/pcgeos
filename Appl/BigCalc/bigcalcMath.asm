COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcMath.asm

AUTHOR:		Christian Puscasiu, Mar  4, 1992

ROUTINES:
	Name			Description
	----			-----------
	CalcEngineChangeMode
	RPNEnginePlus, Minus, YToX, Times, Divide
	CEOneOver
	CESquare
	CESquareRoot
	CEPercent
	CalcEnginePi, ..E, ..PiOverTwo
	CalcEngineEnter
	CEPlusMinus
	CEInverse
	CEStore
	CERecall
	RPNEngineSetInfixMode
	RPNEngineSwap
	RPNEngineRollDown
	CEConvertInputToRadians
	CEConvertOutputToRadians
	CEGetDegreeUnit
	InfixEngineAllocOpStack
	InfixEngineInitInstanceData
	InfixEngineFreeHandle
	InfixEnginePushOperator
	InfixEnginePopOperator
	InfixEngineGetTopOfStack
	InfixEngineDoOperation
	InfixEnginePreOperation
	InfixEngineSaveFPNumber
	InfixEngineSaveLastOperator
	InfixEngineLeftParen
	InfixEnginePreTimes, ..PreDivide, ..PrePlus, PreMinus, PreYToX
	InfixEngineTimes, ..Divide, ..Plus, ..Minus, YToX
	InfixEngineRightParen
	InfixEngineCalcInputFieldCheckUnaryOpDone
	InfixEngineCalcInputFieldSetUnaryOpDone
	InfixEngineCalcInputFieldClearUnaryOpDone
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/ 4/92		Initial revision


DESCRIPTION:
	
		
	$Id: bigcalcMath.asm,v 1.1 97/04/04 14:38:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

udata	segment 

	engineOffset		lptr

udata	ends



MathCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	RPNEnginePlus, ..YToX, ..Minus, ..Times, ..Divide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	performs the function in the RPN engine

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		the result of the arithmetic opertion on top of the
		fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RPN_CAPABILITY

RPNEnginePlus	method dynamic RPNEngineClass, 
					MSG_CE_PLUS
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	done

	call	CEDisplayOnPaperTape
	call	FloatAdd
done:
	.leave
	ret
RPNEnginePlus	endm

RPNEngineYToX	method dynamic RPNEngineClass, 
					MSG_CE_Y_TO_X
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	done

	call	CEDisplayOnPaperTape
	call	FloatExponential
done:
	.leave
	ret
RPNEngineYToX	endm

RPNEngineMinus	method dynamic RPNEngineClass, 
					MSG_CE_MINUS
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	checkOne

	call	CEDisplayOnPaperTape
	call	FloatSub
	jmp	done

checkOne:
	cmp	ax, 0
	jz	done

	call	FloatNegate
;	call	CEDisplayTopOfStack
done:
	.leave
	ret
RPNEngineMinus	endm

RPNEngineTimes	method dynamic RPNEngineClass, 
					MSG_CE_TIMES
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	done

	call	CEDisplayOnPaperTape
	call	FloatMultiply
done:
	.leave
	ret
RPNEngineTimes	endm

RPNEngineDivide	method dynamic RPNEngineClass, 
					MSG_CE_DIVIDE
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	done

	call	CEDisplayOnPaperTape
	call	FloatDivide
done:
	.leave
	ret
RPNEngineDivide	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CEOneOver, CESquare, CESquareRoot, CEPercent, CEConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	performs the unary ops in both engines

CALLED BY:	
PASS:		*ds:si	= CalcEngineClass object
		ds:di	= CalcEngineClass instance data
		ds:bx	= CalcEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		result of operation on top of fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/19/92   	Initial version
	AS	9/12/96		added call to CEFunctionCommon for
				PENELOPE version, and ifdefed out 
				non-PENELOPE code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)

CEOneOver	method dynamic CalcEngineClass, 
					MSG_CE_ONE_OVER
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatInverse
	call	InfixEngineCalcInputFieldSetUnaryOpDone

done:
	.leave
	ret
CEOneOver	endm

endif

CESquare	method dynamic CalcEngineClass, 
					MSG_CE_SQUARE
	uses	ax, cx, dx, bp
	.enter

	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatSqr
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CESquare 	endm

CESquareRoot	method dynamic CalcEngineClass, 
					MSG_CE_SQUARE_ROOT
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatSqrt
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CESquareRoot	endm

CEPercent	method dynamic CalcEngineClass, 
					MSG_CE_PERCENT
	uses	ax, cx, dx, bp, di, si
	.enter


	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatDivide10
	call	FloatDivide10

	
	
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CEPercent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEFunctionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for PENELOPE versions of ^2, ^1/2, and % 
		functions.  

CALLED BY:	CESquare
		CESquareRoot
		CEPercent
PASS:		ax = function type
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _SCIENTIFIC_REP

CESine		method dynamic CalcEngineClass, 
					MSG_CE_SINE
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	CEConvertInputToRadians
	call	FloatSin
	call	InfixEngineCalcInputFieldSetUnaryOpDone

done:
	.leave
	ret
CESine		endm

CECosine	method dynamic CalcEngineClass, 
					MSG_CE_COSINE
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	CEConvertInputToRadians
	call	FloatCos
	call	InfixEngineCalcInputFieldSetUnaryOpDone

done:
	.leave
	ret
CECosine		endm

CETangent	method dynamic CalcEngineClass, 
					MSG_CE_TANGENT
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	CEConvertInputToRadians
	call	FloatTan
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CETangent		endm

CELn		method dynamic CalcEngineClass, 
					MSG_CE_LN
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatLn
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CELn			endm

CELog		method dynamic CalcEngineClass, 
					MSG_CE_LOG
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatLog
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CELog			endm

CEEToX		method dynamic CalcEngineClass, 
					MSG_CE_E_TO_X
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatExp
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CEEToX			endm

CETenToX	method dynamic CalcEngineClass, 
					MSG_CE_TEN_TO_X
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	Float10
	call	FloatSwap
	call	FloatExponential
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CETenToX		endm

CEFactorial		method dynamic CalcEngineClass, 
					MSG_CE_FACTORIAL
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatFactorial
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CEFactorial			endm

CEArcSine	method dynamic CalcEngineClass, 
					MSG_CE_ARC_SINE
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatArcSin
	call	CEConvertOutputFromRadians
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	call	CEResetInverse

done:
	.leave
	ret
CEArcSine			endm

CEArcTangent	method dynamic CalcEngineClass, 
					MSG_CE_ARC_TANGENT
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatArcTan
	call	CEConvertOutputFromRadians
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	call	CEResetInverse

done:
	.leave
	ret
CEArcTangent			endm

CEArcCosine	method dynamic CalcEngineClass, 
					MSG_CE_ARC_COSINE
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	call	FloatArcCos
	call	CEConvertOutputFromRadians
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	call	CEResetInverse

done:
	.leave
	ret
CEArcCosine			endm

endif ;if _SCIENTIFIC_REP

if _SCIENTIFIC_REP

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEResetInverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	resets the inverse button

CALLED BY:	
PASS:		*ds:si	calcEngine
RETURN:		nothing 
DESTROYED:	everything 

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEResetInverse	proc	near
	.enter

	mov	ax, MSG_CE_INVERSE
	call	ObjCallInstanceNoLock

	mov	bx, handle InverseBooleanGroup
	mov	si, offset InverseBooleanGroup
	mov	cx, 1
	clr	dx
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjMessage 	

	.leave
	ret
CEResetInverse	endp
 
endif ;if _SCIENTIFIC_REP



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEnginePi, CalcEngineE, CalcEnginePiOverTwo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	puts the constant in the calculator

CALLED BY:	
PASS:		*ds:si	= CalcEngineClass object
		ds:di	= CalcEngineClass instance data
		ds:bx	= CalcEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		the constants on top of the fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (NOT FALSE)

CalcEnginePi		method dynamic CalcEngineClass, 
					MSG_CE_PI
	uses	ax, cx, dx, bp
	.enter

	call	FloatPi
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	.leave
	ret
CalcEnginePi			endm

endif

if (NOT FALSE)

CalcEngineE		method dynamic CalcEngineClass, 
					MSG_CE_E
	uses	ax, cx, dx, bp
	.enter
	
	call	Float1
	call	FloatExp
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	.leave
	ret
CalcEngineE			endm

endif

if (NOT FALSE)

CalcEnginePiOverTwo	method dynamic CalcEngineClass, 
					MSG_CE_PI_OVER_TWO
	uses	ax, cx, dx, bp
	.enter

	call	FloatPiDiv2
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	.leave
	ret
CalcEnginePiOverTwo	endm

endif 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineDisplayConstantTopOfStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays constant on top of stack

CALLED BY:	
PASS:		*ds:si	= CalcEngineClass object
		ds:di	= CalcEngineClass instance data
		ds:bx	= CalcEngineClass object (same as *ds:si)
		es 	= segment of CalcEngineClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Emulate the user entering the number sitting at stack top
		and clean things up appropriately:

		If in infix mode,
			If (user was entering a number (operation bit clear)
			    or a unary operation was just done),
			    and the FP stack depth is at least two,
				Replace it by swap and drop.
			Set the unary operation bit.
		Else (RPN mode), clear the enter bit.
		Set the operation done bit.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/28/92   	Initial version
	dhunter	9/5/2000	Changed the swap and drop rules

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineDisplayConstantTopOfStack	method dynamic CalcEngineClass, 
					MSG_CE_DISPLAY_CONSTANT_TOP_OF_STACK
	uses	ax, cx, dx, bp
	.enter

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS

	cmp	ss:[calculatorMode], CM_RPN
	je	doRPN
	
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage 
	jnc	drop			; branch if no operation
	
	call	InfixEngineCalcInputFieldCheckUnaryOpDone
	jnc	setTheBit		; branch if binary operation

drop:
	; Ensure the stack depth is at least two when we're done.
	call	FloatDepth
	cmp	ax, 2
	jle	setTheBit

	call	FloatSwap
	call	FloatDrop

setTheBit:
	call	InfixEngineCalcInputFieldSetUnaryOpDone

setTheDoneBit:
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	.leave
	ret

doRPN:
	mov	ax, MSG_CALC_IF_CLEAR_ENTER_BIT
	call	ObjMessage
	jmp	setTheDoneBit
	
CalcEngineDisplayConstantTopOfStack	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEngineEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	the ENTER in RPN mode

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	acts as the ENTER of the RPN RPNulator

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/13/92   	Initial version
	dhunter	9/11/2000	Move stack lift here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RPN_CAPABILITY
RPNEngineEnter	method dynamic RPNEngineClass, 
					MSG_CE_ENTER
	uses	ax, cx, dx, bp
	.enter

	; Done with this number, so lift the stack.
	call	FloatDup
	
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_SET_ENTER_BIT
	call	ObjMessage

	.leave
	ret
RPNEngineEnter	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEnginePlusMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Preserve the state of the operation done bit while calling
		super to change sign

CALLED BY:	MSG_CE_PLUSMINUS

PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= segment of InfixEngineClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	changes sign of floating point TOS

PSEUDO CODE/STRATEGY:
	get and save the state of the operationDone bit
	Call super to do the negate
	restore the state of the operationDone bit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/12/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEnginePlusMinus	method dynamic InfixEngineClass, 
					MSG_CE_PLUSMINUS
	uses	ax, cx, dx, bp
	.enter

	; get and save the state of the operationDone bit
	push	si
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage			; carry = operation done
	pop	si
	pushf

	; Call super to do the negate.
	mov	di, offset InfixEngineClass
	mov	ax, MSG_CE_PLUSMINUS
	call	ObjCallSuperNoLock

	; restore the state of the operationDone bit	
	; We know the operation done bit was reset by the callsuper.
	; If it was set before we did it, then set it again.
	popf
	jnc	done				; branch if operation bit clear
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage
done:
	.leave
	ret
InfixEnginePlusMinus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEnginePlusMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow user to change sign only while entering a number

CALLED BY:	MSG_CE_PLUSMINUS

PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= segment of RPNEngineClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	get the state of the operationDone bit
	Call super if the bit is clear

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/12/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RPN_CAPABILITY
RPNEnginePlusMinus	method dynamic RPNEngineClass, 
					MSG_CE_PLUSMINUS
	uses	ax, cx, dx, bp
	.enter

	; get the state of the operationDone bit
	push	si
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage			; carry = operation done
	pop	si
	jc	done				; branch if operation bit set
	
	; Call super to do the negate.
	mov	di, offset RPNEngineClass
	mov	ax, MSG_CE_PLUSMINUS
	call	ObjCallSuperNoLock
done:
	.leave
	ret
RPNEnginePlusMinus	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEPlusMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	cahnges sign of number or exponent, depending in
		whether the numebr has the 'E' in it

CALLED BY:	
PASS:		*ds:si	= CalcEngineClass object
		ds:di	= CalcEngineClass instance data
		ds:bx	= CalcEngineClass object (same as *ds:si)
		ss 	= dgroup
		ax	= message #
RETURN:		the top FP with the sign changed on the fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/18/92   	Initial version
	andres	9/25/96		ifdefed exponent related code for
				non-scientific versions. 
	andres	10/23/96	Restore CIFA_operationDone bit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEPlusMinus	method dynamic CalcEngineClass, 
					MSG_CE_PLUSMINUS
	
	uses	ax, cx, dx, bp
	.enter

	; get the current display into a buffer so that we can examine it
	push	si
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	dx, ss
	mov	bp, offset textBuffer
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage				;cx = length
	pop	si

if _SCIENTIFIC_REP
	; check wether there is an 'e' or 'E' in the string

	push	cx
	LocalLoadChar	ax, 'e'
	mov	di, bp
	LocalFindChar
	pop	cx
	jz	containsExp

	push	cx
	LocalLoadChar	ax, 'E'
	mov	di, bp
	LocalFindChar
	pop	cx
	jz	containsExp
endif

	; the number does not have an exponent -- see if it is already
	; negative

	mov	di, bp
	LocalCmpChar	 ss:[textBuffer], '-'
	jnz	insertMinusAtDI

	; the number is negative, remove the '-' at es:di

removeMinusAtDI:
SBCS<	mov	al, ss:[di+1]	>
DBCS<	mov	ax, ss:[di+2]	>
SBCS<	mov	ss:[di], al	>
DBCS<	mov	ss:[di], ax	>
	LocalNextChar	ssdi
	LocalIsNull	ax
	jnz	removeMinusAtDI
	jmp	common

	; the number contains an exponent and es:di points *after* the E

if _SCIENTIFIC_REP
containsExp:
	LocalCmpChar	ss:[di], '-'
	jz	removeMinusAtDI
endif

insertMinusAtDI:
	LocalLoadChar	ax, '-'
insertLoop:
if DBCS_PCGEOS
	xchg	ax, ss:[di]
	add	di, (size wchar)
	tst	ax
	jnz	insertLoop
	mov	ss:[di], ax
else
	xchg	al, ss:[di]
	inc	di
	tst	al
	jnz	insertLoop
	mov	ss:[di], al
endif

common:
	mov	di, bp
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	clrdw	ss:[bp].VTRP_range.VTR_start
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, dxdi

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	mov	dx, size VisTextReplaceParameters
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	add	sp, size VisTextReplaceParameters

	.leave
	ret
CEPlusMinus	endm

if _SCIENTIFIC_REP

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEInverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	activates the arc funs of the trig funs

CALLED BY:	
PASS:		*ds:si	= CalcEngingeClass object
		ds:di	= CalcEngingeClass instance data
		ds:bx	= CalcEngingeClass object (same as *ds:si)
		ss 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/25/92   	Initial version
	andres	10/31/96	Added DOVE code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEInverse	method dynamic CalcEngineClass, MSG_CE_INVERSE
	uses	ax, cx, dx, bp
	.enter

	;
	; check which row is up
	;
	mov	bx, handle ExtensionResource
	xor	ss:[inverse], 0xff
	
	;
	; Set the state of the Sin, Cosine & Tangent buttons and
	; their related inverses
	;
	mov	si, offset ExtensionResource:ButtonArcSine
	mov	di, offset ExtensionResource:ButtonSine
	tst	ss:[inverse]
	jz	setSine
	xchg	di, si
setSine:
	call	BigCalcMathSetNotUsable
	mov	si, di
	call	BigCalcMathSetUsable
				   
	mov	si, offset ExtensionResource:ButtonArcCosine
	mov	di, offset ExtensionResource:ButtonCosine
	tst	ss:[inverse]
	jz	setCosine
	xchg	di, si
setCosine:
	call	BigCalcMathSetNotUsable
	mov	si, di
	call	BigCalcMathSetUsable

	mov	si, offset ExtensionResource:ButtonArcTangent
	mov	di, offset ExtensionResource:ButtonTangent
	tst	ss:[inverse]
	jz	setTangent
	xchg	di, si
setTangent:
	call	BigCalcMathSetNotUsable
	mov	si, di
	call	BigCalcMathSetUsable

	.leave
	ret
CEInverse	endm

endif ;if _SCIENTIFIC_REP

if _RPN_CAPABILITY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcMathResetFPStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the floating point stack

CALLED BY:	RPNEngineSetInfixMode
		InfixEngineSetRPNMode
PASS:		ax, bx things to be set non-usable
		cx, dx things to be set usable
		all of ax-dx have to be offsets into the CalcResource
		object block
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BigCalcMathResetFPStack	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	
	;
	; clear the fp stack and put a zero on top
	;
	call	FloatExit
	mov	ax, FP_STACK_LENGTH
	mov	bl, FLOAT_STACK_WRAP
	call	FloatInit
	call	Float0
	call	CEDisplayTopOfStack

	;
	; Clear the display as well
	;

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	.leave
	ret
BigCalcMathResetFPStack	endp

endif ;if _RPN_CAPABILITY





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineClearAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears the fp stack as well as the operator stack

CALLED BY:	MSG_CE_CLEAR_ALL
PASS:		*ds:si	= CalcEngineClass object
		ds:di	= CalcEngineClass instance data
		ds:bx	= CalcEngineClass object (same as *ds:si)
		es 	= segment of CalcEngineClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/24/93   	Initial version
	AS	9/23/96		Replaced
				BigCalcEnableAllButtonsAfterClear
				with
				BigCalcEnableOrDisableButtons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineClearAll	method dynamic CalcEngineClass, 
					MSG_CE_CLEAR_ALL
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_INFIX_CE_INIT_INSTANCE_DATA
	call	ObjCallInstanceNoLock

if 0	; No longer required -dhunter 9/11/00
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CLEAR_INPUT_DONE_BIT
	call	ObjMessage
endif

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	call	FloatExit
	mov	ax, FP_STACK_LENGTH
	mov	bl, FLOAT_STACK_WRAP
	call	FloatInit

	call	InfixEngineCalcInputFieldSetUnaryOpDone

	.leave
	ret
CalcEngineClearAll	endm



if _RPN_CAPABILITY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEngineSetInfixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	switches RPN back to Infix

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RPNEngineSetInfixMode	method dynamic RPNEngineClass, 
					MSG_CE_SET_INFIX_MODE
	uses	ax, cx, dx, bp
	.enter

	;
	; set global to InfixEngine
	;
	mov	ss:[engineOffset], offset BigCalcInfixEngine

	;
	; Set up the UI properly for Infix. Be careful to only
	; turn on the parens if the math extensions are turned on.
	;
	mov	bx, handle CalcResource
	mov	si, offset CalcResource:ButtonSwap
	call	BigCalcMathSetNotUsable
	mov	si, offset CalcResource:ButtonRollDown
	call	BigCalcMathSetNotUsable
	mov	si, offset CalcResource:ButtonEnter
	call	BigCalcMathSetNotUsable

	mov	si, offset CalcResource:ButtonEquals
	call	BigCalcMathSetUsable
	test	ss:[extensionState], mask EXT_MATH
	jz	setMoniker
	mov	si, offset CalcResource:ButtonLeftParen
	call	BigCalcMathSetUsable
	mov	si, offset CalcResource:ButtonRightParen
	call	BigCalcMathSetUsable

	;
	; change the moniker on the clear button
	;
setMoniker:
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset InfixClearButtonMoniker
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bx, handle ButtonClear
	mov	si, offset ButtonClear
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Reset the floating point stack
	;
	call	BigCalcMathResetFPStack

	.leave
	ret
RPNEngineSetInfixMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEngineSwap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	swaps the top two numbers on the fp stack

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		swaps top 2 number on fp stack
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RPNEngineSwap	method dynamic RPNEngineClass, 
					MSG_CE_SWAP
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	cmp	ax, 2
	jl	done

	call	FloatSwap
done:
	.leave
	ret
RPNEngineSwap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEngineRollDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"rolls down" the fp stack

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		scrolls the fp by one
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RPNEngineRollDown	method dynamic RPNEngineClass, 
					MSG_CE_ROLL_DOWN
	uses	ax, cx, dx, bp
	.enter
	
	call	FloatDepth
	
	mov	bx, ax
	call	FloatRollDown

	.leave
	ret
RPNEngineRollDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RPNEngineClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deletes top entry from fp stack in RPN mode

CALLED BY:	
PASS:		*ds:si	= RPNEngineClass object
		ds:di	= RPNEngineClass instance data
		ds:bx	= RPNEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RPNEngineClear	method dynamic RPNEngineClass, 
					MSG_CE_CLEAR
	uses	ax, cx, dx, bp
	.enter

	call	FloatDrop
	call	Float0

	call	CEDisplayTopOfStack

if 0	; No longer required -dhunter 9/11/00
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_INPUT_DONE_BIT
	call	ObjMessage
endif

	; Set operation done bit so next number pressed will clear
	; the 0 we just placed there.
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
;;	mov	ax, MSG_CALC_IF_CLEAR_OP_DONE_BIT
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT	
	call	ObjMessage

	; Set the enter bit so the next number pressed won't cause the
	; stack to be lifted.
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_ENTER_BIT
	call	ObjMessage
	
	.leave
	ret
RPNEngineClear	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEDisplayTopOfStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	display the top of fp stack on the main display

CALLED BY:	every procedure that alters the top of the stack
PASS:		nothing
RETURN:		dx:bp - fptr to the text that was just replaced
		cx    - length of that text
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		displays the top of the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/11/92		Initial version
	andres	9/27/96		added printedSomething
	andres	10/18/96	PENELOPE version uses numbers rounded
				to user-specified setting for 
				calculations
	andres	10/29/96	DOVE doesn't have a Customize Box

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEDisplayTopOfStack	proc	far

	uses	ax,bx,si,di
	.enter


	;
	; duplicates the result it just got, becasue the call to 
	; FloatFloatToAscii_StdFormat will pop the top off the stack
	;
	call	BigCalcProcessPreFloatDup
	call	FloatDup

	mov	bx, handle CustomizeBox
	mov	si, offset CustomizeBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CUST_BOX_GET_SETTINGS
	call	ObjMessage 
	mov	bx, cx			; bh/bl <- char counts


	;es	== dgroup
	GetResourceSegmentNS	dgroup, es
	mov	di, offset textBuffer
	call	FloatFloatToAscii_StdFormat

if (NOT FALSE)
	jcxz	convertToUpper
dispplayResult:
endif

	mov	dx, es
	mov	bp, di


	;
	; save the text for papartape and its length
	;
	push	dx, bp, cx 

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	dx, bp, cx


	.leave
	ret

if (NOT FALSE)
convertToUpper:
	call	BigCalcProcessConvertToUpper
	jmp	dispplayResult
endif


CEDisplayTopOfStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcCheckIfPrintToPaperTape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current number should be printed
		to the paper tape

CALLED BY:	CEDisplayTopOfStack
PASS:		nothing
RETURN:		if OK to print to paper tape
		  carry is cleared
		else
		  carry is set
		  dx is cleared
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	9/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcFixNumberIfTooLong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find the max length [varies from 12 to 14] and adjust the
		length if the number string is too long

CALLED BY:	CEDisplayTopOfStack
PASS:		dx:bp - number string
		es:di - same as dx:bp
		cx - string length
RETURN:		cx - new length
		set carry if length is the same or the input is longer 
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	* set initial max length be 12
	* increase the max if '-' or '.' is in the string
	* return length of string to be displayed in cx	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EC	8/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcDisplayTooLargeError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	display error msg on digital display and
		prepare error string for paper roll display

CALLED BY:	CEDisplayTopOfStack
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	* get error string and put it on digital display
	* copy the error string to buffer for paper roll display	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EC	7/ 8/96    	Initial version
	AS	9/23/96		Replaced
				BigCalcDisableAllButClearButtons
				with
				BigCalcEnableOrDisableButtons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEDisplayOnPaperTapeWithDXBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays the numebr stored in dx:bp on the papertape
		If the paper tape is active, display text with an added
		CR after it.  If tape is too long, call routine to truncate.

CALLED BY:	BigCalcProcessOperation
PASS:		dx:bp	farptr to the text
RETURN:		cx	length of that text
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/ 1/92		Initial version
	AS	9/12/96		check for zero dx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)
CEDisplayOnPaperTapeWithDXBP	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	

	;
	; save the text and length
	;
	push	dx, bp, cx

	;
	; check if papertape is on
	;

	mov	bx, handle BigCalcPaperRoll
	mov	si, offset BigCalcPaperRoll
	

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_GET_USABLE
	call	ObjMessage 

	pop	es, bp, di			
				
	jnc	done		
				

if DBCS_PCGEOS
	shl	di, 1			; di <- byte offset
	mov	{wchar} es:[bp][di], C_ENTER
else
	mov	{char}  es:[bp][di], C_ENTER
endif
	mov	dx, es
DBCS<	shr	di, 1			; back to char offset		>
	mov	cx, di
	inc	cx		; for the CR
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_APPEND
	call	ObjMessage 
	
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_PAPER_ROLL_CHECK_LENGTH
	call	ObjMessage   

	done:

	.leave
	ret
CEDisplayOnPaperTapeWithDXBP	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CECorrectNumDecPlacesForPaperTape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the number to have correct # of decimal places
		so it'll line up on the papertape display	
CALLED BY:	CEDisplayOnPaperTape
PASS:		es:di - text string
		cx    - # of chars in string 
RETURN:		text buffer changed in es:di
		cx    - new string length
DESTROYED:	nothing
PROBLEMS/SIDE EFFECTS:	
	This will require more work if '2E5', '2.2E4', etc., are
	to be handled correctly. Right now, they line up like this:

		       4.0000
	2E5   --->   2E5.0000
	2.2E4 --->     2.2E40
 
	It would also be nice to prepend the operator: '+', '*', etc.

PSEUDO CODE/STRATEGY:
	Get position of decimal place
	if # of chars following decimal is enough, then truncate
	else append the correct number of zeroes.  Also appends
	the return character.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	9/27/94    	Initial version
	andres	10/29/96	DOVE doesn't have a CustomBox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ((NOT FALSE) and (NOT FALSE))

CECorrectNumDecPlacesForPaperTape	proc	near
	uses	ax,bx,dx,si,di,bp
textLength 	local	word	push cx			
returnLength	local	word	push cx	; final text length
numDecs		local	word		; number of decimal places
	.enter

	push	di

	mov	bx, handle CustomizeBox
	mov	si, offset CustomizeBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_CUST_BOX_GET_SETTINGS
	call	ObjMessage 		; cl <- # of decimal places

	clr	ch
	mov	ss:[numDecs], cx
;
;	Find position of decimal (if there) and # of digits following
;
	pop	di
;
;	If no trailing zeros needed, then we're done
;

	test	ax, mask FFAF_NO_TRAIL_ZEROS
	jz	decsOK

	mov	cx, ss:[textLength]
	add	di, cx			; point past text
DBCS <	add	di, cx							>
	jmp	exit			; append the return and exit
decsOK:
;	Find the decimal
;
	call	LocalGetNumericFormat
	mov	dx, cx			; save decimal char for later
	mov	ax, cx			; ax - decimal character
	mov	cx, ss:[textLength]
	LocalFindChar			; cx - pos of decimal
	mov	ax, cx
	jcxz	noDecimal		; add decimal and zeroes

	mov	cx, ss:[numDecs]	; how many do we want?
	sub	cx, ax			; number of decs to add
	jb	truncate		; we have more than enough!
DBCS <	shl	ax, 1			; db chars			>
	add	di, ax			; point after last char
	jmp	addZeroes		; add cx # of zeroes
noDecimal:
	;
	; Add a decimal and then add the correct number of zeroes.
	;
SBCS <	cmp	es:[di-1], dl	; could be there if last char	 	>
DBCS <	cmp	es:[di-1], dx						>
	je	justZeroes
	LocalPutChar	esdi, dx
	inc	ss:[returnLength]	; length grows because of decimal
justZeroes:
	mov	cx, ss:[numDecs]	; add this many zeroes
addZeroes:
	jcxz	noZeros			; exactly the right # of decs
	add	ss:[returnLength], cx	; length of final text to return
	LocalLoadChar	ax, '0'
loopTop:
	LocalPutChar	esdi, ax	; store the zero and advance
	loop	loopTop
noZeros:
	mov	cx, ss:[returnLength]
	jmp	exit
truncate:
	add	ax, cx			; # to advance to place return
	add	di, ax			; advance to end of string
DBCS <	add	di, ax							>
	mov	ax, ss:[textLength]
	add	cx, ax			; decrease length 
exit:
	LocalLoadChar	ax, C_ENTER	; append the return char
	LocalPutChar	esdi, ax
	inc	cx

	.leave
	ret
CECorrectNumDecPlacesForPaperTape	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEDisplayOnPaperTape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	display the number in the display to the papertape

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should call CEDisplayOnPaperTapeWithDXBP
		once the value from NumberDisplay is extracted.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ((NOT FALSE) and (NOT FALSE))

CEDisplayOnPaperTape	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; check if papertape is on
	;

	mov	bx, handle BigCalcPaperRoll
	mov	si, offset BigCalcPaperRoll
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_GET_USABLE
	call	ObjMessage

	jnc	done

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	push	ds
	GetResourceSegmentNS	dgroup, ds
	mov	dx, ds
	pop	ds
	mov	bp, offset textBuffer
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	movdw	esdi, dxbp
	call	CECorrectNumDecPlacesForPaperTape

	mov	si, offset BigCalcPaperRoll
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_VIS_TEXT_APPEND
	call	ObjMessage 
	
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_PAPER_ROLL_CHECK_LENGTH
	call	ObjMessage

done:
	.leave
	ret
CEDisplayOnPaperTape	endp
endif

if _SCIENTIFIC_REP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEConvertInputToRadians
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts top of stck to radian

CALLED BY:	the trig functions
PASS:		degrees on top of fp stack
RETURN:		degrees in radians on top of fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEConvertInputToRadians	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	call	CEGetDegreeUnit

	cmp	dx, DU_DEGREES
	je	degrees

	cmp	dx, DU_RADIANS
	je	radians


;gradians:
	;
	; multiply the top of the stack by pi/200
	;
	mov	ax, 200
	jmp	compute
degrees:
	;
	; multiply the top of the stack by pi/180
	;
	mov	ax, 180
compute:
	call	FloatWordToFloat
	call	FloatDivide

	call	FloatPi
	call	FloatMultiply
radians:
	;
	; do nothing, fp takes radians
	;
	.leave
	ret
CEConvertInputToRadians	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEConvertOutputFromRadians
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts out pur of top of fp stack to radians

CALLED BY:	trig funs
PASS:		result in radians on top of fp stack
RETURN:		result in picked degrees
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEConvertOutputFromRadians	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	call	CEGetDegreeUnit

	cmp	dx, DU_RADIANS
	je	radians

	cmp	dx, DU_DEGREES
	je	degrees

;gradians:
	;
	; multiply the top of the stack by 200/pi
	;
	mov	ax, 200
	jmp	compute
degrees:
	;
	; multiply the top of the stack by 180/pi
	;
	mov	ax, 180

compute:
	call	FloatWordToFloat
	call	FloatMultiply
	
	call	FloatPi
	call	FloatDivide
radians:
	.leave
	ret
CEConvertOutputFromRadians	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEGetDegreeUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	CEConvertInput/OutputTo/FromRadians
PASS:		nothing
RETURN:		dx -- DegreeUnit	(see bigcalcMath.def)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEGetDegreeUnit	proc	near
	uses	ax,bx,cx,si,di,bp,ds,es
	.enter

	;
	; get what degree unit is selected from the DegreeItemGroup
	;
	mov	bx, handle DegreeItemGroup
	mov	si, offset DegreeItemGroup
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage

	mov	dx, ax

	.leave
	ret
CEGetDegreeUnit	endp
endif ;if _SCIENTIFIC_REP

if _RPN_CAPABILITY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineSetRPNMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	switches from Infix to RPN mode

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineSetRPNMode	method dynamic InfixEngineClass, 
					MSG_CE_SET_RPN_MODE
	uses	ax, cx, dx, bp
	.enter

	;
	; set global to InfixEngine
	;
	mov	ss:[engineOffset], offset BigCalcRPNEngine

	;
	; Set up the UI properly for RPN
	;
	mov	bx, handle CalcResource
	mov	si, offset CalcResource:ButtonLeftParen
	call	BigCalcMathSetNotUsable
	mov	si, offset CalcResource:ButtonRightParen
	call	BigCalcMathSetNotUsable
	mov	si, offset CalcResource:ButtonEquals
	call	BigCalcMathSetNotUsable

	mov	si, offset CalcResource:ButtonSwap
	call	BigCalcMathSetUsable
	mov	si, offset CalcResource:ButtonRollDown
	call	BigCalcMathSetUsable
	mov	si, offset CalcResource:ButtonEnter
	call	BigCalcMathSetUsable

	;
	; change the moniker on the clear button
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset RPNClearButtonMoniker
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bx, handle ButtonClear
	mov	si, offset ButtonClear
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
		
	;
	; Reset the floating point stack
	;
	call	BigCalcMathResetFPStack

	.leave
	ret
InfixEngineSetRPNMode	endm

endif ;if _RPN_CAPABILITY




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineInitInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the operator stack

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		ss 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	puts a zero on the bottom of the operator stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineInitInstanceData	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_INIT_INSTANCE_DATA
	uses	ax, cx, dx, bp
	.enter

	; free the old stack -- 3/21/93 -- tony

	mov	bx, ds:[di].ICEI_operatorStackHandle
	tst	bx
	jz	afterFree
	call	MemFree
afterFree:

	mov	ax, INFIX_OPERATOR_STACK_SIZE
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc

	mov	ds:[di].ICEI_operatorStackHandle, bx

	call	MemLock

	mov	es, ax
	clr	ax
	mov	{word} es:[0], ax

	call	MemUnlock

	mov	ds:[di].ICEI_operatorStackIndex, ax
	mov	ds:[di].ICEI_lastOperator, ax

	call	Float0
	
	segmov	es, ds
	add	di, offset ICEI_lastFloatingPointNumber
	call	FloatPopNumber
	
	.leave
	ret
InfixEngineInitInstanceData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEnginePushOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pushes an infix operator on the ops stack

CALLED BY:	
PASS:		cx -- the operator
			cl -- InfixOperator
			ch -- InfixOperatorPrority
		ds -- locked block of the InfixEngine
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	pushes operator on the stack	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEnginePushOperator	proc	near
	class	InfixEngineClass
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

	mov	si, offset BigCalcInfixEngine
	mov	di, ds:[si]
	mov	bp, ds:[di].ICEI_operatorStackIndex

	;
	; make space for new operator on the stack
	;
	cmp	bp, INFIX_OPERATOR_STACK_SIZE
	ja	outOfSpace

	add	bp, 2

	mov	bx, ds:[di].ICEI_operatorStackHandle
	call	MemLock

	mov	es, ax
	mov	es:[bp], cx
	call	MemUnlock

	;
	; update the index
	;
	mov	ds:[di].ICEI_operatorStackIndex, bp

	jmp	done

outOfSpace:
	;
	; show the user that we discarded his input
	;
	mov	ax, SST_NO_INPUT
	call	UserStandardSound

done:
	.leave
	ret
InfixEnginePushOperator	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEnginePopOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pops opertaor off the stack

CALLED BY:	
PASS:		ds -- locked block that contains the BigCalcInfixEngine
RETURN:		cx -- the operator
			cl -- InfixOperator
			ch -- InfixOperatorPrority
		cx == 0 if stack was empty
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pops operator off the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEnginePopOperator	proc	near
	class	InfixEngineClass
	uses	ax,bx,dx,si,di,bp,es
	.enter

	;
	; check if stack`s empty
	;
	mov	si, offset BigCalcInfixEngine
	mov	di, ds:[si]
	mov	bp, ds:[di].ICEI_operatorStackIndex
	cmp	bp, 0
	je	stackEmpty

	mov	bx, ds:[di].ICEI_operatorStackHandle
	call	MemLock
	jc	stackEmpty	; on error just pretend it's empty

	mov	es, ax
	mov	cx, es:[bp]

	call	MemUnlock
	
	;
	; update index
	;
	sub	bp, 2
	mov	ds:[di].ICEI_operatorStackIndex, bp

	jmp	done

stackEmpty:
	clr	cx

done:
	.leave
	ret
InfixEnginePopOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineGetTopOfStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the tope of the opertor stack w/out popping

CALLED BY:	
PASS:		ds -- locked block that BigCalcInfixEngine
RETURN:		cx -- top of stack
			cl -- InfixOperator
			ch -- InfixOperatorPriority
		cx == 0 if empty
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	peaks at the top of the stack without altering it

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92		Initial version
	andres	10/21/96	check if stack is empty, and return 0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineGetTopOfStack	proc	near
	class	InfixEngineClass
	uses	ax,bx,dx,si,di,bp,es
	.enter

	mov	si, offset BigCalcInfixEngine
	mov	di, ds:[si]

	mov	bp, ds:[di].ICEI_operatorStackIndex


	mov	bx, ds:[di].ICEI_operatorStackHandle
	call	MemLock

	mov	es, ax

	;
	; looks at top of stack
	;
	mov	cx, es:[bp]

	call	MemUnlock

	.leave
	ret

InfixEngineGetTopOfStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineChangeTopOfStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the operator on top of the stack.

CALLED BY:	InfixEnginePreBinOpCommon
PASS:		xc	= operator
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	8/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineDoOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does the infix operation

CALLED BY:	
PASS:		cx  -- Operator
			cl - InfixOperator
			ch - InfixOperatorPriority
		ds -- locked block that contains BigCalcInfixEngine
RETURN:		result on fp stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineDoOperation	proc	near
	class	InfixEngineClass
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

	call	InfixEngineSaveFPNumber
	mov	bx, cx
	call	InfixEngineSaveLastOperator

	;
	; check if we have 2 args on the fp stack
	;
	call	FloatDepth
	cmp	ax, 3		; zero is always bottom of stack

	;
	; too few args so we use our 
	;
	jl	useMemory

calculate:
	;
	; transforming cl into a MSG_INFIX_CE_.. msg in ax
	;
	mov	si, offset BigCalcInfixEngine
	clr	ch
	add	cx, MSG_INFIX_CE_LEFT_PAREN - IO_LEFT_PAREN
	mov	ax, cx
	call	ObjCallInstanceNoLock

	call	InfixEnginePopOperator

	.leave
	ret

useMemory:
	;
	; use the last FP number saved (will be on top of fp stack)
	;

	call	FloatDup

	jmp	calculate

InfixEngineDoOperation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEnginePreOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	preparation for infix operation

CALLED BY:	
PASS:		ds -- locked block that contains the BigCalcInfixEngine
		bx - operator
			bl -- InfixOperator
			bh -- InfixOperatorPriority
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	if opertionDone is not set then there was a new number and
	everything is fine

	if operationDone is set, then the number can either come from
	a unary opertion or the user just wanted to change his
	operation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEnginePreOperation	proc	near
	class	InfixEngineClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	
	call	InfixEngineGetTopOfStack
	
	push	bx

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL\
		or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage

	pop	bx
	mov	si, offset BigCalcInfixEngine
	mov	di, ds:[si]
	
	;
	; not set --> check for the operation
	;
	jnc	checkOperator

	;
	; equal and right parens will not replace operator on stack;
	; do normal stuff in this case.
	;
;	cmp	bh, IOP_RIGHT_PAREN
;	je	checkOperator

	;
	; check wether we are right after a unary operation
	; 
	call	InfixEngineCalcInputFieldCheckUnaryOpDone
	jnc	replaceOperator

checkOperator:
	; Save last #/op moved to InfixEngineDoOperation -dhunter 3/17/2000

	cmp	ch, bh
	jl	justPush


goDownStack:
	;
	; check wether we found an open, close parens pair.
	; if we did we'll go down the stack and pop off the
	; left paren
	;
	cmp	bh, IOP_RIGHT_PAREN
	jne	normalBusiness

	cmp	cl, IO_LEFT_PAREN
	jle	openParen

normalBusiness:
	;
	; do the operation on the top of the stack, the new operation
	; not being on the stack yet
	;
	call	InfixEngineDoOperation

	call	InfixEngineGetTopOfStack

	cmp	ch, bh
	jl	justPush

	jmp	goDownStack

replaceOperator:
	call	InfixEnginePopOperator

justPush:
	cmp	bh, IOP_RIGHT_PAREN
	jne	pushNow

	cmp	cl, IO_LEFT_PAREN
	jle	openParen


pushNow:
	mov	cx, bx
	call	InfixEnginePushOperator
	; Nothing happened, so clear the unary op flag. Also, save the top of
	; the fp stack in case the user follows this with an equals. -dhunter 3/17/2000
	call	InfixEngineCalcInputFieldClearUnaryOpDone
	call	InfixEngineSaveFPNumber
	jmp	done

openParen:
	;
	; get rid of the left paren that sits on top of the stack
	;
	call	InfixEnginePopOperator
	
	call	InfixEngineGetTopOfStack

	;
	; if  we're at the bottom of the stack so we're done
	;
	cmp	cl, 0
	je	done

	cmp	bl, IO_EQUALS
	je	goDownStack

done:
	.leave
	ret
InfixEnginePreOperation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineSaveFPNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	saves the last fp number in the engines instance data
		for the ability to repeat the last opertation

CALLED BY:	InfixEnginePreOperation
PASS:		ds - locked block that contains the BigCalcInfixEngine
RETURN:		puts the last fp number into the instance data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineSaveFPNumber	proc	near
	class	InfixEngineClass
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

	call	BigCalcProcessPreFloatDup
	call	FloatDup

	segmov	es, ds
	mov	si, offset BigCalcInfixEngine
	mov	di, ds:[si]
	add	di, offset ICEI_lastFloatingPointNumber
	call	FloatPopNumber
	
	.leave
	ret
InfixEngineSaveFPNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineSaveLastOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	saves last opertor in the engines instance data
		for the ability to repeat the last opertation

CALLED BY:	
PASS:		ds - locked block that contains the BigCalcInfixEngine
		bx -- the operator
			bl -- InfixOperator
			bh -- InfixOperatorPriority
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineSaveLastOperator	proc	near
	class 	InfixEngineClass
	uses	si
	.enter

	cmp	bh, IOP_RIGHT_PAREN
	je	doNothing

	mov	si, offset BigCalcInfixEngine
	mov	si, ds:[si]
	mov	ds:[si].ICEI_lastOperator, bx

doNothing:
	.leave
	ret
InfixEngineSaveLastOperator	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineLeftParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pushes a left paren on the stack

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 8/92   	Initial version
	dhunter	9/11/00		Handle this after unary or no operation
				Treat as binary operation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineLeftParen	method dynamic InfixEngineClass, 
					MSG_CE_LEFT_PAREN
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	;
	; Following a unary operation or no operation, drop floating TOS
	; and show the new TOS.
	;
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL\
		or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage
	jnc	dropTOS			; branch if no operation

	call	InfixEngineCalcInputFieldCheckUnaryOpDone
	jnc	pushOp			; branch if binary operation

dropTOS:
	call	FloatDepth
	cmp	ax, 2
	jl	skipDrop
	call	FloatDrop
skipDrop:
	call	CEDisplayTopOfStack

pushOp:
	mov	cx, IO_LEFT_PAREN or (IOP_LEFT_PAREN shl 8)
	call	InfixEnginePushOperator

	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave
	ret
InfixEngineLeftParen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InfixEnginePreTimes, ..PreDivide, ..PrePlus, PreMinus, PreYToX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prepares the InfixEngine for the operation

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	sets up the arithmetic operations

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 6/92   	Initial version
	AS	9/13/96		added call to
				InfixEnginePreBinOpCommon for PENELOPE
				version, and ifdefed out non-PENELOPE
				code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEnginePreTimes	method dynamic InfixEngineClass, 
					MSG_CE_TIMES
	uses	ax, cx, dx, bp
	.enter

	mov	bx, IO_TIMES or (IOP_TIMES shl 8)

	call	InfixEnginePreOperation

	.leave
	ret

InfixEnginePreTimes	endm

InfixEnginePreDivide	method dynamic InfixEngineClass, 
					MSG_CE_DIVIDE
	uses	ax, cx, dx, bp
	.enter

	mov	bx, IO_DIVIDE or (IOP_DIVIDE shl 8)

	call	InfixEnginePreOperation

	.leave
	ret
InfixEnginePreDivide	endm

InfixEnginePrePlus	method dynamic InfixEngineClass, 
					MSG_CE_PLUS
	uses	ax, cx, dx, bp
	.enter

	mov	bx, IO_PLUS  or (IOP_PLUS shl 8)

	call	InfixEnginePreOperation

	.leave
	ret
InfixEnginePrePlus	endm

InfixEnginePreMinus	method dynamic InfixEngineClass, 
					MSG_CE_MINUS
	uses	ax, cx, dx, bp
	.enter

	mov	bx, IO_MINUS  or (IOP_MINUS shl 8)

	call	InfixEnginePreOperation

	.leave
	ret
InfixEnginePreMinus	endm

if (NOT FALSE)

InfixEnginePreYToX	method dynamic InfixEngineClass, 
					MSG_CE_Y_TO_X
	uses	ax, cx, dx, bp
	.enter
	
	mov	bx, IO_Y_TO_X or (IOP_Y_TO_X shl 8)
	call	InfixEnginePreOperation

	.leave
	ret
InfixEnginePreYToX	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEnginePreBinOpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for PENELOPE version of the four handlers

CALLED BY:	InfixEnginePreTimes
		InfixEnginePreDivide
		InfixEnginePrePlus
		InfixEnginePreMinus
PASS:		ax	= the binary operation
		bx	= priority
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	9/13/96    	Initial version
	andres	9/17/96		change lastOperation to LOT_NONE if
				replacing the operator
	andres	10/17/96	Test for PFR_replaceOp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InfixEngineTimes, ..Divide, ..Plus, ..Minus, YToX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	executes the operation

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		result of the fp operation on top of the fp stack
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 7/92   	Initial version
	AS	9/13/96		added calls to
				InfixEngineBinOpCommon for PENELOPE
				version, and ifdefed out non-PENELOPE
				code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineTimes	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_TIMES
	uses	ax, cx, dx, bp
	.enter

if (NOT FALSE)
	call	CEDisplayOnPaperTape
endif

	call	FloatMultiply
	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave
	ret
InfixEngineTimes	endm

InfixEngineDivide	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_DIVIDE
	uses	ax, cx, dx, bp
	.enter

if (NOT FALSE)
	call	CEDisplayOnPaperTape
endif

	call	FloatDivide
	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave
	ret
InfixEngineDivide	endm

InfixEnginePlus		method dynamic InfixEngineClass, 
					MSG_INFIX_CE_PLUS
	uses	ax, cx, dx, bp
	.enter

if (NOT FALSE)
	call	CEDisplayOnPaperTape
endif
	call	FloatAdd
	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave	
	ret
InfixEnginePlus		endm

InfixEngineMinus		method dynamic InfixEngineClass, 
					MSG_INFIX_CE_MINUS
	uses	ax, cx, dx, bp
	.enter

if (NOT FALSE)
	call	CEDisplayOnPaperTape
endif

	call	FloatSub
	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave
	ret
InfixEngineMinus	endm

if (NOT FALSE)

InfixEngineYToX		method dynamic InfixEngineClass, 
					MSG_INFIX_CE_Y_TO_X
	uses	ax, cx, dx, bp
	.enter

if (NOT FALSE)
	call	CEDisplayOnPaperTape
endif
	call	FloatExponential
	call	InfixEngineCalcInputFieldClearUnaryOpDone

	.leave
	ret
InfixEngineYToX		endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineBinOpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for binary operators for the PENELOPE
		version.  Determines whether to display the operand
		on the paper tape.

CALLED BY:	InfixEnginePlus
		InfixEngineMinus
		InfixEngineTimes
		InfixEngineDivide
PASS:		nothing
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	9/12/96    	Initial version
	andres	10/17/96	If last key was +/-, print the
				operator

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineRightParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prepares op with a right paren

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing 	
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/10/92   	Initial version
	dhunter	9/12/00		Clear last saved operator

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (NOT FALSE)

InfixEngineRightParen	method dynamic InfixEngineClass, 
					MSG_CE_RIGHT_PAREN
	uses	ax, cx, dx, bp
	.enter

	mov	bx, IO_RIGHT_PAREN or (IOP_RIGHT_PAREN shl 8)
	call	InfixEnginePreOperation
	clr	bx
	call	InfixEngineSaveLastOperator
	call	InfixEngineCalcInputFieldSetUnaryOpDone

	.leave
	ret
InfixEngineRightParen	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If an operation was just finished, then clear all.
		Otherwise, just zero the current entry.

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		clears fp stack and puts 0 on top
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	If an operation was just finished, then clear
			all.  Otherwise, 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/14/92   	Initial version
	AS	9/23/96		Replaced
				BigCalcEnableAllButtonsAfterClear
				with
				BigCalcEnableOrDisableButtons
	andres	9/30/96		ifdefed FloatDrop for PENELOPE version
	dhunter	9/11/2000	Check for operation done instead of clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineClear	method dynamic InfixEngineClass, 
					MSG_CE_CLEAR
	uses	ax, cx, dx, bp
	.enter

	;
	; We would like to do a clear all if the user just cleared the
	; display or performed an operation, as otherwise they had
	; just entered one or more numbers and would like to clear them.
	; 
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_CALC_IF_CHECK_OP_DONE_BIT
	call	ObjMessage		; carry set if operation performed
	
	jc	clearAll

if (NOT FALSE)
	call	FloatDrop
endif

if 0	; No longer required -dhunter 9/11/00
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_INPUT_DONE_BIT
	call	ObjMessage
endif
	
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
;;	mov	ax, MSG_CALC_IF_CLEAR_OP_DONE_BIT
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	jmp	cleanup


clearAll:

	mov	si, offset BigCalcInfixEngine
	mov	ax, MSG_INFIX_CE_INIT_INSTANCE_DATA
	call	ObjCallInstanceNoLock

if 0	; No longer required -dhunter 9/11/00
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_CLEAR_INPUT_DONE_BIT
	call	ObjMessage
endif

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CALC_IF_SET_OP_DONE_BIT
	call	ObjMessage

	call	FloatExit
	mov	ax, FP_STACK_LENGTH
	mov	bl, FLOAT_STACK_WRAP
	call	FloatInit

cleanup:
	call	Float0	
	call	CEDisplayTopOfStack
	call	InfixEngineCalcInputFieldSetUnaryOpDone
	.leave
	ret 
InfixEngineClear	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineEquals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	executes equals key in the Infix calculator

CALLED BY:	
PASS:		*ds:si	= InfixEngineClass object
		ds:di	= InfixEngineClass instance data
		ds:bx	= InfixEngineClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The equals key will first execute the operation.  When hit
	again it will repeat the last binary operation

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/13/92   	Initial version
	dhunter	9/11/00		Set unaryOp after it's all over

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineEquals	method dynamic InfixEngineClass, 
					MSG_CE_ENTER
	uses	ax, cx, dx, bp
	.enter

	;
	; see if there are still operations around
	;
	call	InfixEngineGetTopOfStack
	jcxz	repeatLastOp

	mov	bx, IO_EQUALS or (IOP_EQUALS shl 8)

	call	InfixEnginePreOperation
	jmp	clearAllButLast

repeatLastOp:

	;
	; get cx the last operation which needs to be transformed
	; into a MSG_INFIX_CE_REPEAT_..
	;
	mov	di, ds:[si]			; ds:di = InfixEngine
	mov	cx, ds:[di].ICEI_lastOperator
	jcxz	done				; branch if no last operation
	clr	ch
	add	cx, MSG_INFIX_CE_REPEAT_PLUS - IO_PLUS
	mov	ax, cx

	;
	; push the last fp number on the stack
	;
	add	di, offset ICEI_lastFloatingPointNumber
	xchg	si, di				; di <- si, si = &float
	call	FloatPushNumber
	mov_tr	si, di				; restore si
	
	call	ObjCallInstanceNoLock

clearAllButLast:
	
	call	BigCalcProcessPreFloatDup
	GetResourceSegmentNS	dgroup, es
	mov	di, offset textBuffer
	call	FloatPopNumber

	call	FloatExit
	mov	ax, FP_STACK_LENGTH
	mov	bl, FLOAT_STACK_WRAP
	call	FloatInit

	call	Float0
	segmov	ds, es
	mov	si, di
	call	FloatPushNumber

	;	
	; equals is a unary operation
	;	
	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
InfixEngineEquals	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineRepeatPlus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	repeats the opertion, i.e. bin op with fp # in
		instance data

CALLED BY:	
PASS:		*ds:si	= InfixEngineRepeatPlus object
		ds:di	= InfixEngineRepeatPlus instance data
		ds:bx	= InfixEngineRepeatPlus object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/14/92   	Initial version
	AS	9/12/96		added caalls to 
				InfixEngineRepeatBinOpCommon for 
				PENELOPE version, and ifdefed out 
				non-PENELOPE code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineRepeatPlus	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_REPEAT_PLUS
	uses	ax, cx, dx, bp
	.enter

	call	FloatAdd
if (NOT FALSE)
	call	CEDisplayTopOfStack
endif
	.leave
	ret
InfixEngineRepeatPlus	endm

InfixEngineRepeatMinus	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_REPEAT_MINUS
	uses	ax, cx, dx, bp
	.enter


	call	FloatSub
if (NOT FALSE)
	call	CEDisplayTopOfStack
endif
	.leave
	ret
InfixEngineRepeatMinus	endm

InfixEngineRepeatTimes	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_REPEAT_TIMES
	uses	ax, cx, dx, bp
	.enter


	call	FloatMultiply
if (NOT FALSE)
	call	CEDisplayTopOfStack
endif

	.leave
	ret
InfixEngineRepeatTimes	endm

InfixEngineRepeatDivide	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_REPEAT_DIVIDE
	uses	ax, cx, dx, bp
	.enter


	call	FloatDivide
if (NOT FALSE)
	call	CEDisplayTopOfStack
endif

	.leave
	ret
InfixEngineRepeatDivide	endm

if (NOT FALSE)
InfixEngineRepeatYToX	method dynamic InfixEngineClass, 
					MSG_INFIX_CE_REPEAT_Y_TO_X
	uses	ax, cx, dx, bp
	.enter

	call	FloatExponential
	call	CEDisplayTopOfStack

	.leave
	ret
InfixEngineRepeatYToX	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineRepeatBinOpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Code common to all binary operator repeat message
		handlers for PENELOPE.  Displays the repeated operator
		and the operands.

CALLED BY:	InfixEngineRepeatPlus
		InfixEngineRepeatMinus
		InfixEngineRepeatTimes
		InfixEngineRepeatDivide
PASS:		ax	= operation
RETURN:		nothing
DESTROYED:	ax, es
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andres	9/12/96    	Initial version
	andres	9/23/96		added code to handle cases when both 
				operands need to be printed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineCalcInputFieldCheckUnaryOpDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks the unaryOpDone bit

CALLED BY:	
PASS:		nothing 
RETURN:		carry set if UnaryOpDoneBit set in the CalcInputFieldInstance
		Data
		carry not set if bit unset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineCalcInputFieldCheckUnaryOpDone	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	si

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL\
		or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_CHECK_UNARY_OP_DONE
	call	ObjMessage

	pop	si
	mov	di, ds:[si]

	.leave
	ret
InfixEngineCalcInputFieldCheckUnaryOpDone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineCalcInputFieldSetUnaryOpDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the unaryOpDone bit

CALLED BY:	
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		sets the unaryOpDone bit in the BigCalcNumberDisplay

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineCalcInputFieldSetUnaryOpDone	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	si

	segmov	es, ss, si
	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL\
		or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_SET_UNARY_OP_DONE
	call	ObjMessage

	pop	si
	mov	di, ds:[si]

	.leave
	ret
InfixEngineCalcInputFieldSetUnaryOpDone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InfixEngineCalcInputFieldClearUnaryOpDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears the unaryOpDone bit

CALLED BY:	
PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	clears the unaryOpDone bit in the BigCalcNumberDisplay

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InfixEngineCalcInputFieldClearUnaryOpDone	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	si

	mov	bx, handle BigCalcNumberDisplay
	mov	si, offset BigCalcNumberDisplay
	mov	di, mask MF_CALL\
		or mask MF_FIXUP_DS ; or mask MF_FIXUP_ES
	mov	ax, MSG_CALC_IF_CLEAR_UNARY_OP_DONE
	call	ObjMessage

	pop	si
	mov	di, ds:[si]

	.leave
	ret
InfixEngineCalcInputFieldClearUnaryOpDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcMathSetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the object that's passed in bx:si usable


CALLED BY:	
PASS:		ds	= object block segment (any)
		bx:si	= object
RETURN:		ds	= fixed up (maybe)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcMathSetUsable	proc	near
	uses	ax,cx,dx,di,bp
	.enter

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
BigCalcMathSetUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcMathSetNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the object in bx:si not usable

CALLED BY:	
PASS:		ds	= object block segment (any)
		bx:si	= object
RETURN:		ds	= fixed up (maybe)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcMathSetNotUsable	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
BigCalcMathSetNotUsable	endp

MathCode	ends








