COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calculator Accessory -- Calculation Engine
FILE:		calcEngine.asm

AUTHOR:		Adam de Boor, Mar 15, 1990

ROUTINES:
	Name			Description
	----			-----------
    	CalcEngineClass		Object class for the engine
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/15/90		Initial revision


DESCRIPTION:
	Code to implement the computation engine for this beastie.
		

	$Id: calcEngine.asm,v 1.1 97/04/04 14:46:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	CalcEngineClass	; Declare the class record
idata	ends

Main		segment	resource

;------------------------------------------------------------------------------
;
;			   UTILITY ROUTINES
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEnginePush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the passed number onto the register stack.

CALLED BY:	CalcEngineEnter, CalcEngineRecall
PASS:		*ds:si	= object
		ax:cx:dx:bp = DDFixed number (ax is high word of integer)
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEnginePush	proc	near	uses bx, di
		class	CalcEngineClass
		.enter
		mov	bx, ds:[si]
	;
	; Point regTop (and di) past new value, coincidentally acquiring the
	; total number of bytes needed by the stack.
	;
		mov	di, ds:[bx].CE_regTop
		add	di, size DDFixed
		mov	ds:[bx].CE_regTop, di

	;
	; Find the current size of the registers chunk and see if it's enough
	;
		mov	bx, ds:[bx].CE_registers
EC <		xchg	bx, si						>
EC <		call	ECLMemValidateHandle				>
EC <		xchg	bx, si						>

		xchg	ax, di		; ax = # bytes needed (1-byte inst)
		call	CalcEngineExpandIfNecessary
		xchg	ax, di		; di = offset into chunk past register

		add	di, ds:[bx]
		mov	ds:[di-DDFixed].DDF_frac.low, bp
		mov	ds:[di-DDFixed].DDF_frac.high, dx
		mov	ds:[di-DDFixed].DDF_int.low, cx
		mov	ds:[di-DDFixed].DDF_int.high, ax
		.leave
		ret
CalcEnginePush	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user s/he fucked up.

CALLED BY:	CalcEngineDisplayX, CalcEngineStorePlus
PASS:		ds:di	= CalcEngineInstance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineError	proc	near
		class	CalcEngineClass
		.enter
	;
	; Set the display to Error
	;
		mov	dx, cs
		mov	bp, offset overflowString
		mov	cx, length overflowString
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL
		mov	bx, ds:[di].CE_display.handle
		mov	si, ds:[di].CE_display.chunk
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CalcEngineError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineDisplayX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display and pop the top-most register

CALLED BY:	All operator routines
PASS:		*ds:si	= instance
		carry set if result is invalid (overflow occurred)
RETURN:		carry still set if result is invalid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just queues a MSG_CE_REDISPLAY method for the
		object, discarding the notification if one is already
		pending.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
overflowString	char	'Error'
CalcEngineDisplayX	proc	near	uses ax, bx, cx, dx, di, bp, si
		class	CalcEngineClass
		.enter
		mov	di, ds:[si]
		jc	overflow
		mov	bx, ds:[di].CE_registers
		mov	bx, ds:[bx]
		add	bx, ds:[di].CE_regTop
		sub	bx, size DDFixed
		call	CalcEngineDisplayDSBX
		clc
done:
		.leave
		ret
overflow:
	;
	; Reset the engine first, nuking any pending infix operators
	; and all register values.
	;
		mov	ds:[di].CE_opTop, 0
		mov	ds:[di].CE_regTop, 0
		call	CalcEngineError
		stc
		jmp	done
CalcEngineDisplayX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEnginePrepareBinary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for one of the binary operators

CALLED BY:	CalcEngineDivide, CalcEngineMultiply, CalcEngineAdd,
       		CalcEngineSubtract, CalcEngineExchange
PASS:		*ds:si	= instance
		ax	= method being executed
RETURN:		ds:bx	= source (former X register)
		ds:di	= destination (former Y register, now X register)
		carry clear if only one operand on the stack
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEnginePrepareBinary proc	near
		class	CalcEngineClass
		.enter
	;
	; Record the method being executed for infix's repeated-equals operation
	; 
		mov	di, ds:[si]
		mov	ds:[di].CE_lastOpcode, ax

	;
	; Fetch the top of the stack and pop the top-most element at the same
	; time.
	;
		mov	ax, ds:[di].CE_regTop
		sub	ax, size DDFixed
		jbe	error
		mov	ds:[di].CE_regTop, ax
	
	;
	; ds:bx = rhs
	;
		mov	bx, ds:[di].CE_registers
		mov	bx, ds:[bx]
		add	bx, ax
	;
	; Copy the rhs to the lastOperand instance variable for infix mode
	; and the repeated '=' operation.
	; 
		mov	ax, ds:[bx].DDF_frac.low
		mov	ds:[di].CE_lastOperand.DDF_frac.low, ax
		mov	ax, ds:[bx].DDF_frac.high
		mov	ds:[di].CE_lastOperand.DDF_frac.high, ax
		mov	ax, ds:[bx].DDF_int.low
		mov	ds:[di].CE_lastOperand.DDF_int.low, ax
		mov	ax, ds:[bx].DDF_int.high
		mov	ds:[di].CE_lastOperand.DDF_int.high, ax

	;
	; Finally, point di at the lhs for the operation, which is now the
	; top of the stack.
	;
		mov	di, bx
		sub	di, size DDFixed
		stc
done:
		.leave
		ret
error:
		clc
		jmp	done
CalcEnginePrepareBinary endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineDisplayDSBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the display for the engine to show off the number at
		ds:bx

CALLED BY:	CalcEngineRedisplay, CalcEngineRecall
PASS:		*ds:si	= engine instance
		ds:bx	= DDFixed to be displayed
RETURN:		nothing
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineDisplayDSBX	proc	near	uses bx, si
		class	CalcEngineClass
		.enter
		mov	cx, ds		; cx:dx = number to convert
		mov	dx, bx
		mov	di, ds:[si]
		mov	bx, ds:[di].CE_display.handle
		mov	si, ds:[di].CE_display.chunk
		mov	ax, MSG_CD_WRITE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CalcEngineDisplayDSBX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineExpandIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand an LMem chunk for an engine, marking the chunk as
		dirty, if there's not enough room in the chunk.

CALLED BY:	CalcEngineInfixOp, CalcEnginePush
PASS:		ax	= size needed
		bx	= chunk to expand
		ds	= object segment
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineExpandIfNecessary	proc	near	uses di
		.enter
		;
		; See if there's enough room in the stack chunk
		;
		ChunkSizeHandle ds, bx, di
		xchg	ax, cx		; cx = size needed, ax = passed cx
		cmp	di, cx
		jae	enoughRoom
		xchg	ax, bx		; ax = handle, bx = passed cx
		call	LMemReAlloc
		push	bx
		mov	bx, mask OCF_DIRTY
		call	ObjSetFlags
		pop	bx
		xchg	ax, bx		; bx = handle, ax = passed cx
enoughRoom:
		xchg	ax, cx		; cx = passed cx, ax = size needed
		.leave
		ret
CalcEngineExpandIfNecessary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineFetch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current value from the display

CALLED BY:	CalcEngineEnter, CalcEngineStore
PASS:		*ds:si	= engine instance
		cx	= non-zero if display should clear itself on
			  next keystroke
RETURN:		ax:cx:dx:bp = value in the display
		carry clear if no number fetched (displayed number is
			bogus)
DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineFetch	proc	near	uses si
		class	CalcEngineClass
		.enter
		mov	di, ds:[si]	; ^lbx:si = display object
		mov	si, ds:[di].CE_display.chunk
		mov	bx, ds:[di].CE_display.handle

		mov	ax, MSG_CD_READ
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CalcEngineFetch	endp

;------------------------------------------------------------------------------
;
;			   METHOD HANDLERS
;
;------------------------------------------------------------------------------
methodTable	CalcEngineMethods	MSG_CE_DIVIDE,
					MSG_CE_MULTIPLY,
					MSG_CE_SUBTRACT,
					MSG_CE_ADD,
					MSG_DUMMY,
					MSG_DUMMY,
					MSG_DUMMY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineInfixOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an infix operation

CALLED BY:	All operator buttons in an infix calculator
PASS:		cx	= CalcOps giving operation desired
		dx	= method to invoke to perform the operation (currently
			  unused)
		*ds:si	= instance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
precTable	word	3,		; DIVIDE
			3,		; MULTIPLY
			2,		; MINUS
			2,		; PLUS
			0,		; OPEN
			0,		; START
			1,		; CLOSE
			4		; PERCENT

CalcEngineInfixOp	method	dynamic CalcEngineClass, MSG_CE_INFIX_OP
		.enter
		test	ds:[di].CE_flags, mask CEF_REPLACE_OP
		jz	normalOp
		
	;
	; Hit an operator after having hit an operator just before (w/o
	; entering a new number). If the top of the operator stack contains
	; anything but an open-paren or the start of the expression (XXX:
	; how did the CEF_REPLACE_OP flag get set then?), just nuke the top-most
	; operator from the stack and handle the operator we got in the normal
	; fashion. This brings it closer to the behaviour of real calculators...
	; 
		mov	bx, ds:[di].CE_opStack
EC <		tst	bx						>
EC <		ERROR_Z		NO_OPERATOR_STACK_PROVIDED		>
		mov	bx, ds:[bx]
		add	bx, ds:[di].CE_opTop
		cmp	{word}ds:[bx], CALC_OP_OPEN
		je	normalOp
		cmp	{word}ds:[bx], CALC_OP_START
		je	normalOp
		sub	ds:[di].CE_opTop, 2
		jmp	handlePrecedence

normalOp:
	;
	; Convert the number in the display and push it onto the stack.
	;
		push	cx
		mov	ax, MSG_CE_ENTER
		call	ObjCallInstanceNoLock
		pop	cx
		cmc
		jc	displayAndExit

handlePrecedence:
	;
	; Evaluate any operators on the stack of the same or higher precendence.
	;
		mov	bx, cx		; First get current operator's
					;  precedence
		mov	ax, cs:precTable[bx]
EC <		cmp	bx, CalcOps					>
EC <		ERROR_AE	OPERATOR_OUT_OF_RANGE			>
		mov	di, ds:[si]
		mov	bx, ds:[di].CE_opStack
EC <		tst	bx						>
EC <		ERROR_Z		NO_OPERATOR_STACK_PROVIDED		>
		mov	bx, ds:[bx]
		mov	di, ds:[di].CE_opTop
		push	cx		; Save operator for later pushing
precLoop:
		mov	bp, ds:[bx][di]
		cmp	ax, cs:precTable[bp]
		jg	done

		push	ax
		mov	ax, cs:methodTable[bp]
		call	ObjCallInstanceNoLock
		pop	ax
		jc	overFlow

		mov	bx, ds:[si]
		mov	bx, ds:[bx].CE_opStack
		mov	bx, ds:[bx]
		dec	di		; pop that operator
		dec	di
		jge	precLoop
done:
	;
	; All equal- or higher-precedence operators have been processed.
	; Push the new operator onto the operator stack.
	;
		pop	cx		; Recover operator to push
		cmp	cx, CALC_OP_CLOSE
		je	isClose
		cmp	cx, CALC_OP_PERCENT
		je	isPercent
		;
		; Figure the new CE_opTop. di points to the first operator to
		; be left on the stack.
		;
		xchg	ax, di		; (1-byte inst)
		inc	ax		; skip over remaining operator
		inc	ax
		mov	di, ds:[si]
		ornf	ds:[di].CE_flags, mask CEF_REPLACE_OP	; flag operator
								; replacement
								; req'd if no
								; number given
		mov	ds:[di].CE_opTop, ax	; store new top
		mov	bx, ds:[di].CE_opStack
		add	ax, 2		; ax = size needed
		call	CalcEngineExpandIfNecessary
		mov	bx, ds:[bx]
		add	bx, ax
		mov	ds:[bx-2], cx
		clc
displayAndExit:
		call	CalcEngineDisplayX
exeuntOmnes:
		.leave
		ret
overFlow:
		pop	cx		; Discard operator
		jmp	displayAndExit
isClose:
	;
	; Close paren has to be handle specially. It's got a precedence just
	; above the open paren it's supposed to close, so the open doesn't
	; get popped for us (keeping a single close from closing more than
	; one level), so we have to do it ourselves. Also, nothing gets pushed.
	;
		cmp	{word}ds:[bx][di], CALC_OP_OPEN
		xchg	ax, di
		jne	storeCloseTop	; Do not pop if not OPEN
		dec	ax
		dec	ax
storeCloseTop:
		mov	di, ds:[si]
		mov	ds:[di].CE_opTop, ax
	;
	; We also need to display the result and pop that sucker off the stack.
	; Otherwise, when the user chooses his/her next operation, the result
	; would be pushed again, which would not be good.
	;
		clc
displayAndPop:
		call	CalcEngineDisplayX
		jc	exeuntOmnes		; engine already reset
		mov	di, ds:[si]
		mov	ax, ds:[di].CE_regTop
		sub	ax, size DDFixed
		mov	ds:[di].CE_regTop, ax
		jmp	exeuntOmnes
isPercent:
	;
	; Deal with the percent operator. Divide the TOS by 100, then display
	; and pop the thing, leaving the operator stack untouched.
	;
		clr	ax		; ax:cx:dx:bp = DDFixed 100
		mov	dx, ax
		mov	bp, ax
		mov	cx, 100
		call	CalcEnginePush
		
		mov	ax, MSG_CE_DIVIDE
		call	ObjCallInstanceNoLock

		jmp	displayAndPop
CalcEngineInfixOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineOpenParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a parenthetical expression for an infix calculator.

CALLED BY:	MSG_CE_OPEN_PAREN
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineOpenParen	method	dynamic CalcEngineClass, MSG_CE_OPEN_PAREN
		.enter
		andnf	ds:[di].CE_flags, not mask CEF_REPLACE_OP
		mov	bx, ds:[di].CE_opStack
EC <		tst	bx						>
EC <		ERROR_Z	NO_OPERATOR_STACK_PROVIDED			>
	;
	; Need to push CALC_OP_OPEN on the operator stack. First adjust the
	; opTop pointer.
	;
		mov	ax, ds:[di].CE_opTop
		inc	ax
		inc	ax
		mov	ds:[di].CE_opTop, ax
	;
	; Now make sure the chunk has enough room
	;
		add	ax, 2
		call	CalcEngineExpandIfNecessary
	;
	; Stuff the OPEN operator on the top of the stack.
	;
		mov	bx, ds:[bx]
		add	bx, ax
		mov	{word}ds:[bx-2], CALC_OP_OPEN
		.leave
		ret
CalcEngineOpenParen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineFinishInfix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the '=' operator when operated in infix mode. If
		an expression is currently pending, all pending operators
		are evaluated after pushing the current value on the stack.
		
		If no expression remains open, the last-performed operation
		is performed again.

CALLED BY:	MSG_CE_FINISH_INFIX
PASS:		*ds:si	= engine instance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineFinishInfix	method	dynamic CalcEngineClass, MSG_CE_FINISH_INFIX
		.enter
		andnf	ds:[di].CE_flags, not mask CEF_REPLACE_OP
		cmp	ds:[di].CE_opTop, 0
		jne	easy
		cmp	ds:[di].CE_lastOpcode, MSG_DUMMY
		je	done
	;
	; Enter the previous result (which we popped off the stack when we
	; handled the initial = operator).
	;
		mov	ax, MSG_CE_ENTER
		call	ObjCallInstanceNoLock
		jnc	done
	;
	; Push the last operand on the register stack
	;
		mov	di, ds:[si]
		mov	bp, ds:[di].CE_lastOperand.DDF_frac.low
		mov	dx, ds:[di].CE_lastOperand.DDF_frac.high
		mov	cx, ds:[di].CE_lastOperand.DDF_int.low
		mov	ax, ds:[di].CE_lastOperand.DDF_int.high
		call	CalcEnginePush
	;
	; Re-execute the last operation.
	;
		mov	ax, ds:[di].CE_lastOpcode
		call	ObjCallInstanceNoLock
	;
	; Display the result.
	;
		call	CalcEngineDisplayX
		jc	done		; engine already reset
popResult:
		mov	di, ds:[si]
		mov	ds:[di].CE_regTop, 0
done:
		.leave
		ret
easy:
	;
	; It's easy when there are pending operators, as we can just use
	; the normal INFIX_OP method with operator CALC_OP_START to
	; process everything as usual.
	;
		mov	ax, MSG_CE_INFIX_OP
		mov	cx, CALC_OP_START
		call	ObjCallInstanceNoLock
		jmp	popResult
CalcEngineFinishInfix	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineExecuteOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute an operation after pushing the current value onto
		the stack.

CALLED BY:	MSG_CE_EXECUTE_OP
PASS:		*ds:si	= instance
		cx	= CalcOps for operation to perform
		dx	= method to use to execute the operation
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineExecuteOp	method	CalcEngineClass, MSG_CE_EXECUTE_OP
		.enter
	;
	; Convert the number in the display and push it onto the stack.
	;
		push	dx
		mov	ax, MSG_CE_ENTER
		call	ObjCallInstanceNoLock
		pop	ax
		cmc
		jc	display
	;
	; Now execute the operation
	;
		call	ObjCallInstanceNoLock
	;
	; Display the result
	;
display:
		call	CalcEngineDisplayX
		jc	done		; Engine already reset...
	;
	; Pop the result and flag an implicit enter as pending.
	;
		mov	di, ds:[si]
		mov	ax, ds:[di].CE_regTop
		sub	ax, size DDFixed
		mov	ds:[di].CE_regTop, ax
		ornf	ds:[di].CE_flags, mask CEF_ENTER_PENDING
done:
		.leave
		ret
CalcEngineExecuteOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the currently-displayed number onto the register stack

CALLED BY:	MSG_CE_ENTER
PASS:		*ds:si	= instance
RETURN:		carry set if number entered
DESTROYED:	Anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineEnter	method	CalcEngineClass, MSG_CE_ENTER
		.enter

	;
	; Read the current value from the display.
	;
		mov	cx, TRUE		; Display should clear on next
						;  keystroke
		call	CalcEngineFetch
		jnc	error
	;
	; Push the result onto the register stack.
	;
		call	CalcEnginePush

	;
	; Mark the engine dirty here (this is a pretty central function for
	; the engine, so it seems a good place to mark the thing dirty)
	;
		mov	bx, mask OCF_DIRTY
		xchg	ax, si
		call	ObjSetFlags
		xchg	ax, si
		stc
error:
		.leave
		ret
CalcEngineEnter	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineDivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Divide y by x and pop

CALLED BY:	MSG_CE_DIVIDE
PASS:		*ds:si	= instance
RETURN:		carry set on overflow (i.e. carry always clear)
DESTROYED:	top register is popped

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineDivide method	CalcEngineClass, MSG_CE_DIVIDE
		.enter
		call	CalcEnginePrepareBinary
		jnc	doNothing
		call	CalcDivide
doNothing:
		.leave
		ret
CalcEngineDivide endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineMultiply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply y & x and pop

CALLED BY:	MSG_CE_MULTIPLY
PASS:		*ds:si	= instance
RETURN:		carry set on overflow
DESTROYED:	top register is popped

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineMultiply method CalcEngineClass, MSG_CE_MULTIPLY
		.enter
		call	CalcEnginePrepareBinary
		jnc	doNothing
		call	CalcMultiply
doNothing:
		.leave
		ret
CalcEngineMultiply endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add y & x and pop

CALLED BY:	MSG_CE_ADD
PASS:		*ds:si	= instance
RETURN:		carry set on overflow
DESTROYED:	top register is popped

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineAdd 	method CalcEngineClass, MSG_CE_ADD
		.enter
		call	CalcEnginePrepareBinary
		jnc	doNothing
		call	CalcAdd
doNothing:
		.leave
		ret
CalcEngineAdd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineSubtract
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract x from y and pop

CALLED BY:	MSG_CE_SUBTRACT
PASS:		*ds:si	= instance
RETURN:		carry set on overflow
DESTROYED:	top register is popped

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineSubtract method CalcEngineClass, MSG_CE_SUBTRACT
		.enter
		call	CalcEnginePrepareBinary
		jnc	doNothing
		call	CalcSubtract
doNothing:
		.leave
		ret
CalcEngineSubtract endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy top of stack to storage

CALLED BY:	MSG_CE_STORE
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	Anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineStore	method	CalcEngineClass, MSG_CE_STORE
		.enter
		mov	di, ds:[si]
		add	di, offset CE_memory
		mov	cx, TRUE			; set clearPending
		call	CalcEngineFetch
		jnc	error
		mov	di, ds:[si]
		mov	ds:[di].CE_memory.DDF_frac.low, bp
		mov	ds:[di].CE_memory.DDF_frac.high, dx
		mov	ds:[di].CE_memory.DDF_int.low, cx
		mov	ds:[di].CE_memory.DDF_int.high, ax
		; flag item in memory
error:	; XXX
		.leave
		ret
CalcEngineStore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineRecallAndEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push memory contents onto the stack

CALLED BY:	MSG_CE_RECALL_AND_ENTER
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineRecallAndEnter method	CalcEngineClass, MSG_CE_RECALL_AND_ENTER
		.enter
	;
	; First put the stored value up in the display.
	;
		mov	ax, MSG_CE_RECALL
		call	ObjCallInstanceNoLock
	;
	; Now set the enterPending flag for the object so if the user
	; starts to enter a new number, we will be called to enter the value
	; recalled.
	;
		mov	di, ds:[si]
		ornf	ds:[di].CE_flags, mask CEF_ENTER_PENDING
	;
	; Tell the display to clear if the user adds a digit.
	;
		mov	si, ds:[di].CE_display.chunk
		mov	bx, ds:[di].CE_display.handle
		mov	ax, MSG_CD_CLEAR_PENDING
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
CalcEngineRecallAndEnter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineRecall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the stored value in the display area.

CALLED BY:	MSG_CE_RECALL
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineRecall method	CalcEngineClass, MSG_CE_RECALL
		.enter
	;
	; Tell ourselves we're clearing the display so any pending enter
	; happens.
	;
		mov	ax, MSG_CE_CLEARING
		call	ObjCallInstanceNoLock
	;
	; This counts as entering a number, so clear the REPLACE_OP flag.
	; 
		andnf	ds:[di].CE_flags, not mask CEF_REPLACE_OP
	;
	; Now show the value.
	; 
		mov	bx, ds:[si]
		add	bx, offset CE_memory
		call	CalcEngineDisplayDSBX
		.leave
		ret
CalcEngineRecall endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineStorePlus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the current value into the stored one

CALLED BY:	MSG_CE_STORE_PLUS
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineStorePlus method	CalcEngineClass, MSG_CE_STORE_PLUS
		.enter
	;
	; Allocate a chunk in our object block for the current value since
	; the two operands must be in the same segment (ds)
	;
		mov	cx, size DDFixed
		mov	al, mask OCF_IGNORE_DIRTY
		call	LMemAlloc
		
	;
	; Read the current number from the display.
	; XXX: set clearPending flag?
	;
		push	ax
		mov	cx, TRUE	; set clearPending
		call	CalcEngineFetch
		mov	di, ds:[si]	; ds:di <- CE_memory for error
		lea	di, ds:[di].CE_memory	; and for the add (don't nuke
		jnc	error			; carry, please)

	;
	; Store the result in the chunk we created.
	;
		pop	bx
		push	bx
		mov	bx, ds:[bx]
		mov	ds:[bx].DDF_int.high, ax
		mov	ds:[bx].DDF_int.low, cx
		mov	ds:[bx].DDF_frac.high, dx
		mov	ds:[bx].DDF_frac.low, bp
	;
	; ds:bx already points at the source, and ds:di at the dest, so
	; perform the addition
	;
		call	CalcAdd
		jnc	done
	;
	; Free the chunk used for the source.
	; XXX: flag something as stored.
	;
error:
		clr	ax
		mov	ds:[di].DDF_int.high, ax
		mov	ds:[di].DDF_int.low, ax
		mov	ds:[di].DDF_frac.high, ax
		mov	ds:[di].DDF_frac.low, ax

		mov	di, ds:[si]		; ds:di <- CalcEngineInstance
		call	CalcEngineError
done:
		pop	ax
		call	LMemFree
		.leave
		ret
CalcEngineStorePlus endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the calculation engine

CALLED BY:	MSG_CE_RESET
PASS:		*ds:si	= engine instance
RETURN:		nothing
DESTROYED:	the register and operator stacks are reset

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineReset	method	CalcEngineClass, MSG_CE_RESET
		.enter
		mov	di, ds:[si]
		mov	ds:[di].CE_regTop, 0
		mov	ds:[di].CE_opTop, 0	; Leave CALC_OP_START
		andnf	ds:[di].CE_flags, not (mask CEF_ENTER_PENDING or \
					       mask CEF_REPLACE_OP)
		mov	ds:[di].CE_lastOpcode, MSG_DUMMY

if 0		; display now responsible for reseting the machine
		mov	ax, MSG_CD_CLEAR
		mov	si, ds:[di].CE_display.chunk
		mov	bx, ds:[di].CE_display.handle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
endif

		.leave
		ret
CalcEngineReset	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineClearing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with implicit enter of a recalled number if the user
		types a number instead of an operator after performing a
		recall.

CALLED BY:	MSG_CE_CLEARING
PASS:		*ds:si	= instance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineClearing	method	dynamic CalcEngineClass, MSG_CE_CLEARING
		.enter
		test	ds:[di].CE_flags, mask CEF_ENTER_PENDING
		jz	noEnter
		
		andnf	ds:[di].CE_flags, not mask CEF_ENTER_PENDING
		mov	ax, MSG_CE_ENTER
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
noEnter:
		andnf	ds:[di].CE_flags, not mask CEF_REPLACE_OP
		jmp	done
CalcEngineClearing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEngineExchange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exchange the top two stack elements

CALLED BY:	MSG_CE_EXCHANGE
PASS:		*ds:si	= engine instance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcEngineExchange method CalcEngineClass, MSG_CE_EXCHANGE
		.enter
	;
	; First enter the current value.
	;
		mov	ax, MSG_CE_ENTER
		call	ObjCallInstanceNoLock
	;
	; Now swap the two.
	;
		call	CalcEnginePrepareBinary
		jnc	error
		;
		; Push the former Y in the right order for sending to the
		; display.
		;
		push	ds:[di].DDF_int.high
		push	ds:[di].DDF_int.low
		push	ds:[di].DDF_frac.high
		push	ds:[di].DDF_frac.low
		;
		; Copy the former X to the former Y
		;
		push	si
		segmov	es, ds, si
		mov	si, bx
		movsw
		movsw
		movsw
		movsw
		pop	si
		;
		; Recover the former Y and display it, setting the enterPending
		; flag so we get it back if we need it..
		;
displayY:
		mov	di, ds:[si]
		ornf	ds:[di].CE_flags, mask CEF_ENTER_PENDING
		
		mov	bx, ds:[di].CE_display.handle
		mov	si, ds:[di].CE_display.chunk
		mov	cx, ss
		mov	dx, sp
		mov	ax, MSG_CD_WRITE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		;
		; Pop the former Y
		;
		add	sp, size DDFixed
		.leave
		ret
error:
	;
	; Emulate something that doesn't have a limitless stack by pretending
	; Y contained 0...
	;
		clr	ax
		push	ax
		push	ax
		push	ax
		push	ax
		jmp	displayY
CalcEngineExchange endp

Main		ends
