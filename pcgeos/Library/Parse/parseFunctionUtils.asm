COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseFunctionUtils.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	InitFunctionEnv
	ProcessListOfArgs
	DoRangeEnum
	RangeEnumCallback
	DerefCell
	DoOperation
	FunctionCheck0Args
	FunctionCheckNArgs
	FunctionCheck1NumericArg
	FunctionCheckNNumericArgs
	FunctionCheck1RangeArg
	FunctionCheckArgType
	FunctionCheckIntermediateResultCount
	FunctionCleanUpNumOpWithFunctionEnv
	FunctionCleanUpBooleanOp
	FunctionChangeArgToBoolean
	FunctionReturnFalse
	FunctionReturnTrue
	FunctionCleanUpDateOp
	FunctionCleanUpNumOp
	ArgStackPopAndLeaveNumber
	ArgStackPopAndLeaveArgType
	FunctionCheck1StringArg
	StringOpGetIntArg
	GetByteArg
	GetWordArg
	ReplaceWithString
	InitRangeInfo
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	This file contains utility routines for the various function routines
	in parseFunctions.asm.
		
	$Id: parseFunctionUtils.asm,v 1.2 98/03/14 21:51:31 gene Exp $

-------------------------------------------------------------------------------@


EvalCode        segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFunctionEnv

DESCRIPTION:	Sets up the functionEnv stack frame.

CALLED BY:	INTERNAL ()

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:ax	- pointer to EvalParameters on the stack.

RETURN:		stack frame with some fields initialized

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

InitFunctionEnv	proc	near

	IFE_local	local	functionEnv

	.enter inherit near

	mov	IFE_local.FE_argStack.segment, es
	mov	IFE_local.FE_argStack.offset, bx
	mov	IFE_local.FE_numArgs, cx
	mov	IFE_local.FE_evalParams, ax

	clr	ax
	mov	IFE_local.FE_argsReqForProcRoutine, ax	; default to 0 args required
	mov	IFE_local.FE_returnSingleArg, al
						; don't return single arg
	mov	IFE_local.FE_nearRoutine, al	; default to handle, offset
	mov	IFE_local.FE_argProcessingRoutine.handle, ax
	mov	IFE_local.FE_cellRef, al	; default to ignore new cells
	mov	IFE_local.FE_cellCount, ax	; init count
	mov	IFE_local.FE_numCount, ax	; init count
	mov	IFE_local.FE_errorCode, al	; init error code
	mov	IFE_local.FE_errorPropagated, al; error not propagated
	mov	IFE_local.FE_ignoreEmpty, al	; default to process empty cells
	mov	IFE_local.FE_nonNumsOK, al	; non numbers not OK

	.leave
	ret
InitFunctionEnv	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessListOfArgs

DESCRIPTION:	Process a list of arguments of type NUMBER or RANGE.
		A callback routine to process the cells in a range is
		stored in a field in the functionEnv stack frame.

CALLED BY:	INTERNAL ()

PASS:		functionEnv stack frame
		es:bx   - pointer to top of argument stack
		cx      - number of arguments passed to the function

RETURN:		es:bx   - pointer to top of argument stack
		carry set on error
		    al - error code
		carry clear otherwise
		    result on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

ProcessListOfArgs	proc	near	uses	cx
	PLA_local	local	functionEnv
	.enter inherit near

	mov	al, PSEE_BAD_ARG_COUNT	; al <- error code

;
; inappropriate as single argument may be a range
; delaying check till after all cells have been processed
; check will be done against the number of cells processed
;
;	cmp	cx, PLA_local.FE_argsReqForProcRoutine
;	jl	error			; branch if wrong # of arguments
	jcxz	done

	;-----------------------------------------------------------------------
	; loop to process arguments

getNextArg:
	;
	; what type of argument is it?
	;
	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	jnz	argIsNumeric				; branch if so

	test	es:[bx].ASE_type, mask ESAT_RANGE	; range?
	jz	propagateErrIfNecessary			; error if not

	call	DoRangeEnum
	jc	error
	jmp	short argDone

propagateErrIfNecessary:
	mov	al, PSEE_WRONG_TYPE
	test	es:[bx].ASE_type, mask ESAT_ERROR	; error?
	jz	error					; branch if not error

	;
	; propagate error
	;
	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode
	mov	PLA_local.FE_errorPropagated, 0ffh
	jmp	short error

argIsNumeric:
	call	DoOperation
	jc	error

argDone:
	les	bx, PLA_local.FE_argStack	; update bx

;	push	bp			; save offset to functionEnv
;	mov	bp, PLA_local.FE_evalParams
	call    Pop1Arg                 ; remove cell data from the arg-stack
;	pop	bp			; retrieve offset to functionEnv

	mov	PLA_local.FE_argStack.offset, bx
	loop	getNextArg
	
	;-----------------------------------------------------------------------
	; processing complete

done:
	;
	; error if FE_cellCount < FE_argsReqForProcRoutine
	;
	mov	ax, PLA_local.FE_cellCount
	cmp	ax, PLA_local.FE_argsReqForProcRoutine
	jge	noErr

	cmp	ax, 1				; cell count = 1?
	mov	al, PSEE_BAD_ARG_COUNT
	jne	error				; not special case if not

	cmp	PLA_local.FE_returnSingleArg, 0	; single arg ok?
	je	error				; branch if not, al = err code

noErr:
	clc

quit:
	mov	PLA_local.FE_numArgs, cx	; num args now present
	.leave
	ret

error:
	;
	; errors encountered
	; al = error code
	;
	mov	PLA_local.FE_errorCode, al
	stc
	jmp	quit			; Branch to quit
ProcessListOfArgs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CountNonEmptyInListOfArgs, modified from ProcessListOfArgs

DESCRIPTION:	Process a list of ranges and count the number of non empty
		cells.  A callback routine to process the cells in a range is
		stored in a field in the functionEnv stack frame.

CALLED BY:	INTERNAL (FunctionCount)

PASS:		functionEnv stack frame
		es:bx   - pointer to top of argument stack
		cx      - number of arguments passed to the function

RETURN:		es:bx   - pointer to top of argument stack
		carry set on error
		    al - error code
		carry clear otherwise
		    result on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

CountNonEmptyInListOfArgs	proc	near	uses	cx
	PLA_local	local	functionEnv
	.enter inherit near

EC<	cmp	PLA_local.FE_numCount, 0 >
EC<	ERROR_NE	0 >

	mov	al, PSEE_BAD_ARG_COUNT	; al <- error code
	jcxz	done

	;-----------------------------------------------------------------------
	; loop to process arguments

getNextArg:
	test	es:[bx].ASE_type, mask ESAT_RANGE	; range?
	jnz	doRange

	test	es:[bx].ASE_type, mask ESAT_ERROR	; error?
	jne	propagateError

	test	es:[bx].ASE_type, mask ESAT_EMPTY	; empty?
	jnz	short argDone

	inc	PLA_local.FE_numCount
	jmp	short argDone

propagateError:
	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode
	mov	PLA_local.FE_errorPropagated, 0ffh
	jmp	short error

doRange:
	call	DoRangeEnum
	jnc	argDone

error:
	;
	; errors encountered
	; al = error code
	;
	mov	PLA_local.FE_errorCode, al
	stc
	jmp	quit			; Branch to quit

argDone:
	les	bx, PLA_local.FE_argStack	; update bx
	call	ConsumeOneNumericArg
	call    Pop1Arg                 ; remove cell data from the arg-stack
	mov	PLA_local.FE_argStack.offset, bx
	loop	getNextArg
	
	;-----------------------------------------------------------------------
	; processing complete

done:
	;
	; error if FE_cellCount < FE_argsReqForProcRoutine
	;
	mov	ax, PLA_local.FE_cellCount
	cmp	ax, PLA_local.FE_argsReqForProcRoutine
	jge	noErr

	cmp	ax, 1				; cell count = 1?
	mov	al, PSEE_BAD_ARG_COUNT
	jne	error				; not special case if not

	cmp	PLA_local.FE_returnSingleArg, 0	; single arg ok?
	je	error				; branch if not, al = err code

noErr:
	clc

quit:
	mov	PLA_local.FE_numArgs, cx	; num args now present
	.leave
	ret
CountNonEmptyInListOfArgs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoRangeEnum

DESCRIPTION:	Argument on the argument stack is a range.  Enumerate it by
		setting up a callback routine to handle each cell.

CALLED BY:	INTERNAL (ProcessListOfArgs, FunctionNPV)

PASS:		ss:bp - pointer to FunctionEnv on the stack.
		es:bx - top of the argument stack

RETURN:		es:bx - top of the argument stack
		carry - set if enumeration aborted
		    al - error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

DoRangeEnum	proc	near	uses	dx,ds,si

	DRE_local	local	functionEnv

	.enter inherit near

	sub	sp, size RangeEnumParams
	mov	si, sp

	;
	; set up the bounds
	;
	mov     dx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	and	dx, mask CRC_VALUE
	mov	ss:[si].REP_bounds.R_top, dx
	mov     dx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	and	dx, mask CRC_VALUE
	mov	ss:[si].REP_bounds.R_left, dx

	mov     dx, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	and	dx, mask CRC_VALUE
	mov	ss:[si].REP_bounds.R_bottom, dx
	mov     dx, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	and	dx, mask CRC_VALUE
	mov	ss:[si].REP_bounds.R_right, dx

	;
	; set up callback routine
	;
	mov	ss:[si].REP_callback.segment, SEGMENT_CS
	mov	ss:[si].REP_callback.offset, offset RangeEnumCallback

	;
	; Save pointer to CellFunctionParameters
	;
	mov	bx, si			; ss:bx <- ptr to RangeEnumParams
	
	mov	si, DRE_local.FE_evalParams
					; ds:si <- ptr to CellFunctionParameters
	lds	si, ss:[si].CP_cellParams

	;
	; set up cell reference behavior
	;
	mov	dl, DRE_local.FE_cellRef

	call	RangeEnum

	les	bx, DRE_local.FE_argStack	; update bx

	mov	al, DRE_local.FE_errorCode
	tst	al
	clc
	je	done

	stc

done:
	lahf					; save carry
	add	sp, size RangeEnumParams
	sahf					; restore carry
	.leave
	ret
DoRangeEnum	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RangeEnumCallback

DESCRIPTION:	The callback routine that processes cells from a range.

CALLED BY:	INTERNAL (RangeEnum)

PASS:           ds:si - Pointer to CellFunctionParameters
		(ax,cx) - current cell (r,c)
		ss:bp - functionEnv stack frame
		es:*di - ptr to cell data if any
		carry - set if cell has data
		dl - RangeEnumFlags

RETURN:         carry - set to abort enumeration
		es - seg addr of cell (updated)
		dl - RangeEnumFlags (unchanged)

DESTROYED:	dh

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	dereference the cell
	call the floating point operation

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

RangeEnumCallback	proc	far	uses	ax
	REC_local	local	functionEnv
	ForceRef	REC_local
	.enter inherit near

	call	DerefCell		; place fp number on stack
	jc	exit			; exit if error

	;
	; OK, fp number is on stack, operate on it
	;
	call	DoOperation
exit:
	.leave
	ret
RangeEnumCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DerefCell

DESCRIPTION:	Dereference the cell.

CALLED BY:	INTERNAL (RangeEnumCallback, FunctionN)

PASS:           ds:si - Pointer to CellFunctionParameters
		(ax,cx) - current cell (r,c)
		ss:bp - functionEnv structure on the stack

RETURN:		fp number on the fp stack
		no corresponding place holder in argument stack
		carry set if error
		    al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

DerefCell	proc	near	uses	bx,dx,es

	DC_local	local	functionEnv

	.enter inherit near

;	cmp	DC_local.FE_argProcessingRoutine.handle, 0
;					; anything to work on cell?
;	je	done			; done if not

	mov	dx, ax			; dx <- row

	;
	; restore the parser's environment
	;
	les	bx, DC_local.FE_argStack
	push	bp			; save offset to functionEnv
	mov	bp, DC_local.FE_evalParams

	;***********************************************************************
	; don't use DC_local between here...

	mov	ch, mask DF_DONT_POP_ARGUMENT
        mov     al, CT_DEREF_CELL	; push the cell data
FXIP <	pushdw	ss:[bp].EP_common.CP_callback				>
FXIP <	call	PROCCALLFIXEDORMOVABLE_PASCAL				>
NOFXIP< call    ss:[bp].EP_common.CP_callback	; call the application	>

	jc	derefErr

	;
	; deref successful
	;
	clr	al			; al <- no error
	mov	dl, es:[bx].ASE_type	; dl <- type
	mov	dh, es:[bx].ASE_data.ESAD_error.EED_errorCode	; dh <- error
	test	dl, mask ESAT_NUMBER	; number?
	jne	popArg			; branch if number

	mov	al, PSEE_WRONG_TYPE	; assume error
	stc

popArg:
	pushf				; save z flag
	call	Pop1Arg			; drop the place holder
	popf				; restore z flag

derefErr:
	; ...and here.
	;***********************************************************************

	pop	bp			; restore offset to functionEnv
	mov	DC_local.FE_curArgType, dl
	jnc	updateNumCount

	;
	; to confirm the error, we need to check if the caller wants to
	; ignore non-numbers
	;
	cmp	DC_local.FE_nonNumsOK, 0	; non numbers OK?
	je	err				; error if non-nums are not OK

	;
	; non numbers OK, count everything except errors
	;
	test	dl, mask ESAT_ERROR		; but is it an error?
	jnz	dontCountError			; branch if error

	clr	al				; clear error code and carry
	jmp	short updateNumCount

dontCountError:
	mov	al, dh				; propagate error
	mov	DC_local.FE_errorPropagated, 0ffh

err:
	mov	DC_local.FE_errorCode, al
	stc
	jmp	short updateArgStack

updateNumCount:
EC<	ERROR_C	0 >
	test	dl, mask ESAT_EMPTY
	jne	updateArgStack

	inc	DC_local.FE_numCount
	clc

updateArgStack:
	mov	DC_local.FE_argStack.segment, es
	mov	DC_local.FE_argStack.offset, bx

	.leave
	ret
DerefCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoOperation

DESCRIPTION:	

CALLED BY:	INTERNAL (ProcessListOfArgs, RangeEnumCallback)

PASS:		functionEnv stack frame

RETURN:		cell count upped in functionEnv
		carry set on error
		    al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	up the cell count
	if enough arguments exist then
	    if there is a routine to work on the arguments then
		call the callback routine
		if there is an error
		    save the error code
		endif
	    endif
	endif

!!! IMPORTANT !!!
	Since DoOperation is called by RangeEnumCallback, any change to
	bx cannot be propagated back to the caller of RangeEnum.
	The caller MUST do a
		les	bx, XXX_local.FE_argStack
	after the call to DoOperation.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

DoOperation	proc	near	uses	bx

	DFO_local	local	functionEnv

	.enter inherit near

	;
	; see if cell is empty
	;

	push	es,bx
	les	bx, DFO_local.FE_argStack
	test	es:[bx].ASE_type, mask ESAT_EMPTY	; empty?
	stc					; assume not
	je	doneCheckEmpty			; branch if assumption correct

	cmp	DFO_local.FE_ignoreEmpty, 0	; else process empty cells?
	stc					; assume so
	je	doneCheckEmpty			; branch if assumption correct

	clc					; signal ignore

doneCheckEmpty:
	pop	es,bx

	;
	; carry clear if cell is empty and we are going to ignore it
	;
	jc	proceed

	call	FloatDrop			; flags are preserved
	jmp	short done

proceed:
	inc	DFO_local.FE_cellCount		; up cell count

	mov	ax, DFO_local.FE_argsReqForProcRoutine	; do we have enough args?
	cmp	ax, DFO_local.FE_cellCount
	ja	doneNoErr			; done if not

	;
	; we have enough arguments to work on,
	; is there a routine to work on the data?
	; (this routine can be called on just to COUNT the number of cells)
	;
	mov	bx, DFO_local.FE_argProcessingRoutine.handle
	tst	bx				; any operation to perform?
	je	done				; done if not

	cmp	DFO_local.FE_nearRoutine, 0	; near call?
	je	doProcCall			; branch if not
	
	call	bx
	jnc	done

storeErr:
	; carry flag set
;	mov	al, PSEE_WRONG_TYPE		; al <- error code
	mov	DFO_local.FE_errorCode, al
	jmp	short done

doProcCall:
	mov	ax, DFO_local.FE_argProcessingRoutine.offset
	call	ProcCallModuleRoutine
	jc	storeErr

doneNoErr:
	clc

done:
	.leave
	ret
DoOperation	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheck0Args

DESCRIPTION:	Checks to see that no arguments have been passed

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry clear if ok
		set if error
			al - error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheck0Args	proc	near
	mov     al, PSEE_BAD_ARG_COUNT	; error code

	tst	cx			; OR clears the carry flag
	je	done			; no error if 0

	stc				; else signal error
done:
	ret
FunctionCheck0Args	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheckNArgs

DESCRIPTION:	Checks to see that the right number of arguments have
		been passed.

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		al - expected number of arguments

RETURN:		carry clear if ok
		set if error
			al - error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheckNArgs	proc	near

	cmp	cl, al
	jne	err
	
	tst	ch
	clc
	je	done

err:
	mov     al, PSEE_BAD_ARG_COUNT	; error code
	stc				; else signal error
done:
	ret
FunctionCheckNArgs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheck1NumericArg

DESCRIPTION:	Checks to see that only 1 argument has been passed and
		that it is numeric.

CALLED BY:	INTERNAL ()

PASS:		cx	- number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry set if error
			al - error code (PSEE_BAD_ARG_COUNT / PSEE_WRONG_TYPE)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheck1NumericArg	proc	near

	mov	ax, 1
	FALL_THRU	FunctionCheckNNumericArgs

FunctionCheck1NumericArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheckNNumericArgs

DESCRIPTION:	Checks to see that only N arguments has been passed and
		that they are numeric.

CALLED BY:	INTERNAL ()

PASS:		ax - N (N > 0)
		cx	- number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry set if error
			al - error code (PSEE_BAD_ARG_COUNT / PSEE_WRONG_TYPE)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheckNNumericArgs	proc	near	uses	bx,cx
	.enter

	cmp	cx, ax				; expected number of args?
	mov     al, PSEE_BAD_ARG_COUNT		; return this if wrong
	stc					; assume error
	jne	done				; branch if error

checkArg:
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType		; go check type
	jc	done

	call	Pop1Arg
	loop	checkArg

done:
	.leave
	ret
FunctionCheckNNumericArgs	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FunctionCheckNNonNegativeNumericArgs

DESCRIPTION:	Checks to see that only N arguments has been passed and
		that they are non-negative numeric.

CALLED BY:	INTERNAL ()

PASS:		ax - N (N > 0)
		cx	- number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry set if error
			al - error code (PSEE_BAD_ARG_COUNT,
					 PSEE_WRONG_TYPE,
					 PSEE_NUMBER_OUT_OF_RANGE)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	7/06		Initial version

------------------------------------------------------------------------------@

FunctionCheckNNonNegativeNumericArgs	proc	near	uses	bx,cx
	.enter

	call	FunctionCheckNNumericArgs
	jc	done

pickLoop:
	mov	bx, cx
	call	FloatPick		; copy the cx'th arg to top of stack
	call	FloatLt0		; carry set if < 0
	mov	ax, PSEE_NUMBER_OUT_OF_RANGE	; assume error
	jc	done
	loop	pickLoop
		
done:		
	.leave
	ret
FunctionCheckNNonNegativeNumericArgs	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FunctionCheck1RangeArg

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx	- number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry set if error
			al - error code (PSEE_BAD_ARG_COUNT / PSEE_WRONG_TYPE)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

------------------------------------------------------------------------------@

FunctionCheck1RangeArg	proc	near
	mov     al, PSEE_BAD_ARG_COUNT		; return this if not 1 arg
	cmp	cx, 1
	stc					; assume error
	jne	done				; branch if error

	mov	al, mask ESAT_RANGE
	call	FunctionCheckArgType		; else go check type

done:
	ret
FunctionCheck1RangeArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheckArgType

DESCRIPTION:	Check to see that the top-most argument is of the given type.

CALLED BY:	INTERNAL ()

PASS:		al - type of argument to check for (EvalStackArgumentType)
		es:bx - pointer to top of argument stack

RETURN:		carry set if argument is non-numeric
			al = error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheckArgType	proc	near
	test	es:[bx].ASE_type, al		; do types match?
	clc					; assume yes
	jnz	done				; branch if assumption correct

	mov	al, PSEE_WRONG_TYPE		; return this if no match
	test	es:[bx].ASE_type, mask ESAT_ERROR	; error?
	stc					; flag error
	jz	done				; branch if not error

	;
	; propagate error
	;
	mov	al, es:[bx].ASE_data.ESAD_error.EED_errorCode
	stc					; flag error
done:
	ret
FunctionCheckArgType	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheckIntermediateResultCount

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		al - minimum number of arguments on the fp stack necessary
		     to proceed

RETURN:		carry set if fp stack has fewer arguments than required
		    al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheckIntermediateResultCount	proc	near	uses	dx
	.enter
	mov	dl, al
	clr	dh			; dx <- args required

	call	FloatDepth		; ax <- depth

	cmp	dx, ax			; req - depth
	jbe	ok			; branch depends on carry

	mov	al, PSEE_BAD_ARG_COUNT
	stc
	jmp	short done

ok:
	clc

done:
	.leave
	ret
FunctionCheckIntermediateResultCount	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCleanUpNumOpWithFunctionEnv

DESCRIPTION:	The functionEnv was used with means bp is incorrect for
		a ParserEvalPopNArgs and cx may possibly be incorrect from a
		call to ProcessListOfArgs.

CALLED BY:	INTERNAL ()

PASS:		carry flag set if error
			al - error code

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCleanUpNumOpWithFunctionEnv	proc	near	uses	cx

	FCU_local	local	functionEnv

	.enter inherit near

	mov	cx, FCU_local.FE_numArgs
	push	bp
	mov	bp, FCU_local.FE_evalParams
	call	FunctionCleanUpNumOp
	pop	bp

	.leave
	ret
FunctionCleanUpNumOpWithFunctionEnv	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCleanUpBooleanOp

DESCRIPTION:	The FunctionXXX boolean routines all have common code that
		must be executed once the Float routine has been called.
		This is it.

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		carry flag set if error
			al - error code

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCleanUpBooleanOp	proc	near
	jnc	noErr

	GOTO	PropogateError

noErr:
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	GOTO	ArgStackPopAndLeaveArgType
FunctionCleanUpBooleanOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionChangeArgToBoolean

DESCRIPTION:	Utility routine that converts a numeric argument into a boolean.
		Assumes that a floating point result and its corresponding
		argument descriptor exist.

CALLED BY:	INTERNAL (FunctionAnd, FunctionOr)

PASS:		X on fp stack
		es:bx - pointer to top of argument stack
		carry flag set if error
			al - error code

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionChangeArgToBoolean	proc	near
	jc	done			; done if there's an error to propogate

	test	es:[bx].ASE_type, mask ESAT_ERROR
	jne	done			; done if there's an error

	;
	; only numbers allowable at this point
	;
EC<	test	es:[bx].ASE_type, mask ESAT_NUMBER >
EC<	ERROR_E BOOLEAN_FUNCTION_EXPECTED_A_NUMBER >

	call	FloatEq0		; 0?, argument is popped off
	jc	false			; branch if so

	call	Float1			; else push a 1
	jmp	short modifyArgDesc

false:
	call	Float0

modifyArgDesc:
	;
	; force a boolean now
	;
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	mov	es:[bx].ASE_type, al

	; carry is clear

done:
	ret
FunctionChangeArgToBoolean	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionReturnFalse, FunctionReturnTrue

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		carry flag set if error
			al - error code

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionReturnFalse	proc	near
	jnc	noErr

	GOTO	PropogateError

noErr:
	call	Float0
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	GOTO	ArgStackPopAndLeaveArgType
FunctionReturnFalse	endp


FunctionReturnTrue	proc	near
	jnc	noErr

	GOTO	PropogateError

noErr:
	call	Float1
	mov	al, (NT_BOOLEAN shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	GOTO	ArgStackPopAndLeaveArgType
FunctionReturnTrue	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCleanUpDateOp

DESCRIPTION:	The FunctionXXX date routines all have common code that
		must be executed once the Float routine has been called.
		This is it.

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		carry flag set if error
			al - error code

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCleanUpDateOp	proc	near
	jnc	noErr

	GOTO	PropogateError

noErr:
	mov	al, (NT_DATE_TIME shl offset ESAT_NUM_TYPE) or mask ESAT_NUMBER
	GOTO	ArgStackPopAndLeaveArgType
FunctionCleanUpDateOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCleanUpNumOp

DESCRIPTION:	The FunctionXXX numeric routines all have common code that must
		be executed once the Float routine has been called. This is it.

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments
		carry flag set if error
			al - error code

		es:bx	= Arg stack
		es:di	= Operator stack
		ss:bp	= EvalParameters

RETURN:		carry flag and al intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCleanUpNumOp	proc	near
	jnc	noErr

	GOTO	PropogateError

noErr:
	FALL_THRU	ArgStackPopAndLeaveNumber

FunctionCleanUpNumOp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ArgStackPopAndLeaveArgType

DESCRIPTION:	Pops the given number of arguments off the argument stack
		and creates a place holder of the given type.

CALLED BY:	INTERNAL ()

PASS:		es:bx = Arg stack
		es:di = Operator stack
		ss:bp = EvalParameters
		cx - number of arguments to pop
		al - EvalStackArgumentType

RETURN:		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
	NOTE: FALL_THRU from FunctionCleanUpNumOp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

ArgStackPopAndLeaveNumber	proc	near
	mov	al, mask ESAT_NUMBER
	FALL_THRU	ArgStackPopAndLeaveArgType
ArgStackPopAndLeaveNumber	endp


ArgStackPopAndLeaveArgType	proc	near	uses	cx
	.enter
	push	ax			; save type
	call    ParserEvalPopNArgs	; pop args, leaving one place-holder
	pop	ax			; retrieve type

	clr	cx			; no additional space needed
	call	ParserEvalPushArgument	; destroys ax

	.leave
	ret
ArgStackPopAndLeaveArgType	endp

ArgStackPopAndLeaveArgTypeWithFunctionEnv	proc	near
	uses	cx
FCU_local	local	functionEnv
	.enter inherit near

	mov	cx, FCU_local.FE_numArgs

	push	bp
	mov	bp, FCU_local.FE_evalParams
	call	ArgStackPopAndLeaveArgType
	pop	bp
	.leave
	ret
ArgStackPopAndLeaveArgTypeWithFunctionEnv	endp




COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCheck1StringArg

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx	- number of arguments
		es:bx	- pointer to top of argument stack

RETURN:		carry set if error
			al - error code (PSEE_BAD_ARG_COUNT / PSEE_WRONG_TYPE)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCheck1StringArg	proc	near
	mov     al, PSEE_BAD_ARG_COUNT		; return this if not 1 arg

	cmp	cx, 1
	stc					; assume error
	jne	done				; branch if error

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType		; else go check type

done:
	ret
FunctionCheck1StringArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StringOpGetIntArg

DESCRIPTION:	Get the numeric argument for the string operator.

CALLED BY:	INTERNAL ()

PASS:		es:bx   - pointer to top of argument stack
		cx	- number of arguments

RETURN:		carry clear if argument is legal
		    (legal if 0 <= # <= MAX_STRING_LENGTH)
		    ax - int
		carry set if argument is illegal
		    al - error code
		cx - decremented
		argument popped off

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StringOpGetIntArg	proc	near
	call	GetWordArg		; ax <- int, cx decremented
	jc	done

	cmp	ax, MAX_STRING_LENGTH
	ja	error
	clc					;carry <- no error
done:
	ret

error:
	mov	al, PSEE_GEN_ERR		;al <- error code
	stc					;carry <- error
	jmp	done
StringOpGetIntArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetByteArg

DESCRIPTION:	Get the numeric argument. It is expected to fit in a byte.

CALLED BY:	INTERNAL ()

PASS:		es:bx   - pointer to top of argument stack
		cx	- number of arguments

RETURN:		carry clear if argument is legal
		    ax - int
		carry set if argument is illegal
		    al - error code
		cx - decremented
		argument popped off

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

GetByteArg	proc	near
	call	GetWordArg		; ax <- int, cx decremented
	jc	done

	tst	ah
	clc
	je	done

	mov	al, PSEE_GEN_ERR
	stc

done:
	ret
GetByteArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetWordArg

DESCRIPTION:	Get the numeric argument. It is expected to fit in a word.

CALLED BY:	INTERNAL ()

PASS:		es:bx   - pointer to top of argument stack
		cx	- number of arguments

RETURN:		carry clear if argument is legal
		    ax - int
		carry set if argument is illegal
		    al - error code
		cx - decremented
		argument popped off

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

GetWordArg	proc	near	uses	dx
	.enter
	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	jc	done

	call	FloatFloatToDword		; dx:ax <- int
	tst	dx			; this will catch -ve and large #s
	clc
	je	done

	mov	al, PSEE_GEN_ERR
	stc

done:
	pushf
	push	ax
	call	Pop1Arg			; destroys ax
	dec	cx			; dec number of args
	pop	ax
	popf
	.leave
	ret
GetWordArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsWhiteSpace

DESCRIPTION:	Utility

CALLED BY:	FunctionTrim

PASS:		al - char

RETURN:		carry clear if so, set if not

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		replace with library function in DBCS.

-------------------------------------------------------------------------------@

if  DBCS_PCGEOS
	; calls to LocalIsSpace instead   (witt, 11/93)
else
IsWhiteSpace    proc    near
        cmp     al, ' '
        je      whiteSpace
        cmp     al, '\t'
        je      whiteSpace
        stc
        ret
whiteSpace:
        clc
        ret
IsWhiteSpace    endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReplaceWithString

DESCRIPTION:	Replace the argument on the top of the argument stack with
		the one in the strBuf stack frame.

CALLED BY:	INTERNAL (FunctionDoMid, FunctionRepeat, FunctionTrim)

PASS:		strBuf stack frame
		es:bx - pointer to top of argument stack
		cx - length of string

RETURN:		es:bx - updated
		carry set if error
		    al - error code

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/16/93	DBCS-ized

-------------------------------------------------------------------------------@

ReplaceWithString	proc	near	uses	bp,ds,si
	RS_local	local	strBuf
	.enter inherit near

EC <	cmp	cx, MAX_STRING_LENGTH					>
EC <	ERROR_A	PARSE_STRING_TOO_LONG					>
	segmov	ds, ss, si		; point ds:si at new string
	lea	si, RS_local.SB_buf

	mov	bp, RS_local.SB_saveBP	; restore bp for the Push and Pop ops

	call	Pop1Arg			; lose the current string

DBCS<	shl	cx, 1			; cx <- string size		>
	;
	; ds:si	= String
	; cx	= Size
	; ss:bp	= EvalParameters
	; es:di	= Top of op/func stack
	; es:bx	= Top of arg stack
	;
	call	ParserEvalPushStringConstant ; carry set on error, al <- code
done::
	.leave
	ret
ReplaceWithString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitRangeInfo

DESCRIPTION:	Initialize the rangeInfoStruct stack frame.

CALLED BY:	INTERNAL (FunctionIndex)

PASS:		es:bx - pointer to a range argument
		ss:ax - pointer to EvalParameters on the stack
		rangeInfoStruct stack frame

RETURN:		rangeInfoStruct stack frame initialized

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

InitRangeInfo	proc	near
	IRI_local	local	rangeInfoStruct
	.enter	inherit near

EC<	test	es:[bx].ASE_type, mask ESAT_RANGE >
EC<	ERROR_E	FUNCTION_ASSERTION_FAILED >

	mov	IRI_local.RIS_saveBP, ax

	mov     ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	and	ax, mask CRC_VALUE
	mov	IRI_local.RIS_rowTop, ax

	mov     ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	and	ax, mask CRC_VALUE
	mov	IRI_local.RIS_columnLeft, ax

	mov     ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_row
	and	ax, mask CRC_VALUE
	mov	IRI_local.RIS_rowBot, ax

	mov     ax, es:[bx].ASE_data.ESAD_range.ERD_lastCell.CR_column
	and	ax, mask CRC_VALUE
	mov	IRI_local.RIS_columnRight, ax

	.leave
	ret
InitRangeInfo	endp

EvalCode	ends

ParseMonikerCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserGetNumberOfFunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of functions of a particular type

CALLED BY:	GLOBAL
PASS:		ax - FunctionType to match
RETURN:		cx - # of functions of FunctionType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version
	gene	9/26/92		Added FunctionType

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserGetNumberOfFunctions		proc	far
	uses	si
	.enter

	clr	si				;si <- ptr in table
	clr	cx				;cx <- count
funcLoop:
	test	ax, cs:funcTypeTable[si].FE_type
	jz	noMatch				;branch if wrong type
	inc	cx				;cx <- one more match
noMatch:
	add	si, (size FuncEntry)		;cs:si <- ptr to next
	cmp	si, (size funcTypeTable)	;end of table?
	jb	funcLoop			;branch if not end

	.leave
	ret
ParserGetNumberOfFunctions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserGetFunctionMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of the "cx"th function

CALLED BY:	GLOBAL
PASS:		cx - item #
		ax - FunctionType to match
		es:di - ptr to buffer
RETURN:		cx - length of string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The dgroup:funcTable[] is always in SBCS.  So under DBCS,
		we have to expand it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version
	gene	9/26/92		Added FunctionType
	witt	11/16/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserGetFunctionMoniker		proc	far
	uses	ax, ds, si
	.enter

	call	FuncTypeToNum			;cx <- Nth match

	mov	si, cx				;si <- Nth #
	shl	si, 1				;si <- offset into funcTable

NOFXIP<	mov	ax, segment dgroup					>
NOFXIP<	mov	ds, ax				;ds <- seg addr of dgroup >
FXIP <	mov	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov	bx, ax							>
	mov	si, ds:funcTable[si]		;ds:si <- size & string
	lodsb					;al <- size
	mov	cl, al
	clr	ch				;cx <- SBCS length

SBCS<	call	CopyNString					>
DBCS<	call	CopySBCSToDBCSNString				>

	.leave
	ret
ParserGetFunctionMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserGetFunctionArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the arguments for a specified function

CALLED BY:	GLOBAL
PASS:		cx - item #
		ax - FunctionType to match
		es:di - buffer for string
RETURN:		cx - # of SBCS chars (w/o NULL terminator)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		string table is SBCS always.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version
	witt	11/16/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FuncEntry	struct
    FE_type	FunctionType		;type of function
    FE_args	lptr			;chunk of argument list
FuncEntry	ends

if PZ_PCGEOS
funcTypeTable FuncEntry \
	<mask FT_MATH,		ValueArgs>,		;ABS
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ACOS
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ACOSH
	<mask FT_LOGICAL,	LogicalArgs>,		;AND
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ASIN
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ASINH
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ATAN
	<mask FT_TRIGONOMETRIC,	ATAN2Args>,		;ATAN2
	<mask FT_TRIGONOMETRIC, ValueArgs>,		;ATANH
	<mask FT_STATISTICAL,	ListArgs>,		;AVG
	<mask FT_STRING,	ValueArgs>,		;CHAR
	<mask FT_INFORMATION,	CHOOSEArgs>,		;CHOOSE
	<mask FT_STRING,	StringArgs>,		;CLEAN
	<mask FT_STRING,	StringArgs>,		;CODE
	<mask FT_INFORMATION,	RangeArgs>,		;COLS
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;COS
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;COSH
	<mask FT_INFORMATION,	ListArgs>,		;COUNT
	<mask FT_FINANCIAL,	CTERMArgs>,		;CTERM
	<mask FT_TIME_DATE,	DATEArgs>,		;DATE
	<mask FT_TIME_DATE,	StringArgs>,		;DATEVALUE
	<mask FT_TIME_DATE,	DateArgs>,		;DAY
	<mask FT_FINANCIAL,	DDBArgs>,		;DDB
	<mask FT_INFORMATION,	NoneArgs>,		;ERR
	<mask FT_STRING,	EXACTArgs>,		;EXACT
	<mask FT_MATH,		ValueArgs>,		;EXP
	<mask FT_MATH,		ValueArgs>,		;FACT
	<mask FT_LOGICAL,	NoneArgs>,		;FALSE
	<mask FT_STRING,	FINDArgs>,		;FIND
	<mask FT_FINANCIAL,	FVArgs>,		;FV
	<mask FT_INFORMATION,	LookupArgs>,		;HLOOKUP
	<mask FT_TIME_DATE,	TimeArgs>,		;HOUR
	<mask FT_LOGICAL,	IFArgs>,		;IF
	<mask FT_INFORMATION,	INDEXArgs>,		;INDEX
	<mask FT_MATH,		ValueArgs>,		;INT
	<mask FT_FINANCIAL,	IRRArgs>,		;IRR
	<mask FT_INFORMATION,	ValueArgs>,		;ISERR
	<mask FT_INFORMATION,	ValueArgs>,		;ISNUMBER
	<mask FT_INFORMATION,	ValueArgs>,		;ISSTRING
	<mask FT_STRING,	StringNArgs>,		;LEFT
	<mask FT_STRING,	StringArgs>,		;LENGTH
	<mask FT_MATH,		ValueArgs>,		;LN
	<mask FT_MATH,		ValueArgs>,		;LOG
	<mask FT_STRING,	StringArgs>,		;LOWER
	<mask FT_STATISTICAL,	ListArgs>,		;MAX
	<mask FT_STRING,	MIDArgs>,		;MID
	<mask FT_STATISTICAL,	ListArgs>,		;MIN
	<mask FT_TIME_DATE,	TimeArgs>,		;MINUTE
	<mask FT_MATH,		MODArgs>,		;MOD
	<mask FT_TIME_DATE,	DateArgs>,		;MONTH
	<mask FT_INFORMATION,	RangeArgs>,		;N
	<mask FT_INFORMATION,	NoneArgs>,		;NA
	<mask FT_TIME_DATE,	NoneArgs>,		;NOW
	<mask FT_FINANCIAL,	NPVArgs>,		;NPV
	<mask FT_LOGICAL,	LogicalArgs>,		;OR
	<mask FT_TRIGONOMETRIC,	NoneArgs>,		;PI
	<mask FT_FINANCIAL,	PMTArgs>,		;PMT
	<mask FT_MATH,		ListArgs>,		;PRODUCT
	<mask FT_STRING,	StringArgs>,		;PROPER
	<mask FT_FINANCIAL,	PVArgs>,		;PV
	<mask FT_STATISTICAL,	ValueArgs>,		;RANDOMN
	<mask FT_STATISTICAL,	NoneArgs>,		;RANDOM
	<mask FT_FINANCIAL,	RATEArgs>,		;RATE
	<mask FT_STRING,	StringNArgs>,		;REPEAT
	<mask FT_STRING,	REPLACEArgs>,		;REPLACE
	<mask FT_STRING,	StringNArgs>,		;RIGHT
	<mask FT_MATH,		ROUNDArgs>,		;ROUND
	<mask FT_INFORMATION,	RangeArgs>,		;ROWS
	<mask FT_TIME_DATE,	TimeArgs>,		;SECOND
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;SIN
	<mask FT_TRIGONOMETRIC, TrigArgs>,		;SINH
	<mask FT_FINANCIAL,	SLNArgs>,		;SLN
	<mask FT_MATH,		ValueArgs>,		;SQRT
	<mask FT_STATISTICAL,	ListArgs>,		;STD
	<mask FT_STATISTICAL,	ListArgs>,		;STDP
	<mask FT_STRING,	STRINGArgs>,		;STRING
	<mask FT_MATH,		ListArgs>,		;SUM
	<mask FT_FINANCIAL,	SYDArgs>,		;SYD
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;TAN
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;TANH
	<mask FT_FINANCIAL,	TERMArgs>,		;TERM
	<mask FT_TIME_DATE,	TIMEArgs>,		;TIME
	<mask FT_TIME_DATE,	StringArgs>,		;TIMEVALUE
	<mask FT_TIME_DATE,	NoneArgs>,		;TODAY
	<mask FT_STRING,	StringArgs>,		;TRIM
	<mask FT_LOGICAL,	NoneArgs>,		;TRUE
	<mask FT_MATH,		ValueArgs>,		;TRUNC
	<mask FT_STRING,	StringArgs>,		;UPPER
	<mask FT_STRING,	StringArgs>,		;VALUE
	<mask FT_STATISTICAL,	ListArgs>,		;VAR
	<mask FT_STATISTICAL,	ListArgs>,		;VARP
	<mask FT_INFORMATION,	LookupArgs>,		;VLOOKUP
	<mask FT_TIME_DATE,	DateArgs>,		;WEEKDAY
	<mask FT_TIME_DATE,	DateArgs>,		;YEAR
	<mask FT_PRINT,		NoneArgs>,		;FILENAME
	<mask FT_PRINT,		NoneArgs>,		;PAGE
	<mask FT_PRINT,		NoneArgs>,		;PAGES
	<mask FT_TRIGONOMETRIC,	DEGREESArgs>,		;DEGREES
	<mask FT_TRIGONOMETRIC,	RADIANSArgs>,		;RADIANS
	<mask FT_FINANCIAL,	DDBArgs>		;DB	; Pizza
else
funcTypeTable FuncEntry \
	<mask FT_MATH,		ValueArgs>,		;ABS	; Standard
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ACOS
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ACOSH
	<mask FT_LOGICAL,	LogicalArgs>,		;AND
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ASIN
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ASINH
	<mask FT_TRIGONOMETRIC,	ValueArgs>,		;ATAN
	<mask FT_TRIGONOMETRIC,	ATAN2Args>,		;ATAN2
	<mask FT_TRIGONOMETRIC, ValueArgs>,		;ATANH
	<mask FT_STATISTICAL,	ListArgs>,		;AVG
	<mask FT_STRING,	ValueArgs>,		;CHAR
	<mask FT_INFORMATION,	CHOOSEArgs>,		;CHOOSE
	<mask FT_STRING,	StringArgs>,		;CLEAN
	<mask FT_STRING,	StringArgs>,		;CODE
	<mask FT_INFORMATION,	RangeArgs>,		;COLS
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;COS
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;COSH
	<mask FT_INFORMATION,	ListArgs>,		;COUNT
	<mask FT_FINANCIAL,	CTERMArgs>,		;CTERM
	<mask FT_TIME_DATE,	DATEArgs>,		;DATE
	<mask FT_TIME_DATE,	StringArgs>,		;DATEVALUE
	<mask FT_TIME_DATE,	DateArgs>,		;DAY
	<mask FT_FINANCIAL,	DDBArgs>,		;DDB
	<mask FT_TRIGONOMETRIC,	DEGREESArgs>,		;DEGREES
	<mask FT_INFORMATION,	NoneArgs>,		;ERR
	<mask FT_STRING,	EXACTArgs>,		;EXACT
	<mask FT_MATH,		ValueArgs>,		;EXP
	<mask FT_MATH,		ValueArgs>,		;FACT
	<mask FT_LOGICAL,	NoneArgs>,		;FALSE
	<mask FT_PRINT,		NoneArgs>,		;FILENAME
	<mask FT_STRING,	FINDArgs>,		;FIND
	<mask FT_FINANCIAL,	FVArgs>,		;FV
	<mask FT_INFORMATION,	LookupArgs>,		;HLOOKUP
	<mask FT_TIME_DATE,	TimeArgs>,		;HOUR
	<mask FT_LOGICAL,	IFArgs>,		;IF
	<mask FT_INFORMATION,	INDEXArgs>,		;INDEX
	<mask FT_MATH,		ValueArgs>,		;INT
	<mask FT_FINANCIAL,	IRRArgs>,		;IRR
	<mask FT_INFORMATION,	ValueArgs>,		;ISERR
	<mask FT_INFORMATION,	ValueArgs>,		;ISNUMBER
	<mask FT_INFORMATION,	ValueArgs>,		;ISSTRING
	<mask FT_STRING,	StringNArgs>,		;LEFT
	<mask FT_STRING,	StringArgs>,		;LENGTH
	<mask FT_MATH,		ValueArgs>,		;LN
	<mask FT_MATH,		ValueArgs>,		;LOG
	<mask FT_STRING,	StringArgs>,		;LOWER
	<mask FT_STATISTICAL,	ListArgs>,		;MAX
	<mask FT_STRING,	MIDArgs>,		;MID
	<mask FT_STATISTICAL,	ListArgs>,		;MIN
	<mask FT_TIME_DATE,	TimeArgs>,		;MINUTE
	<mask FT_MATH,		MODArgs>,		;MOD
	<mask FT_TIME_DATE,	DateArgs>,		;MONTH
	<mask FT_INFORMATION,	RangeArgs>,		;N
	<mask FT_INFORMATION,	NoneArgs>,		;NA
	<mask FT_TIME_DATE,	NoneArgs>,		;NOW
	<mask FT_FINANCIAL,	NPVArgs>,		;NPV
	<mask FT_LOGICAL,	LogicalArgs>,		;OR
	<mask FT_PRINT,		NoneArgs>,		;PAGE
	<mask FT_PRINT,		NoneArgs>,		;PAGES
	<mask FT_TRIGONOMETRIC,	NoneArgs>,		;PI
	<mask FT_FINANCIAL,	PMTArgs>,		;PMT
	<mask FT_MATH,		ListArgs>,		;PRODUCT
	<mask FT_STRING,	StringArgs>,		;PROPER
	<mask FT_FINANCIAL,	PVArgs>,		;PV
	<mask FT_TRIGONOMETRIC,	RADIANSArgs>,		;RADIANS
	<mask FT_STATISTICAL,	ValueArgs>,		;RANDOMN
	<mask FT_STATISTICAL,	NoneArgs>,		;RANDOM
	<mask FT_FINANCIAL,	RATEArgs>,		;RATE
	<mask FT_STRING,	StringNArgs>,		;REPEAT
	<mask FT_STRING,	REPLACEArgs>,		;REPLACE
	<mask FT_STRING,	StringNArgs>,		;RIGHT
	<mask FT_MATH,		ROUNDArgs>,		;ROUND
	<mask FT_INFORMATION,	RangeArgs>,		;ROWS
	<mask FT_TIME_DATE,	TimeArgs>,		;SECOND
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;SIN
	<mask FT_TRIGONOMETRIC, TrigArgs>,		;SINH
	<mask FT_FINANCIAL,	SLNArgs>,		;SLN
	<mask FT_MATH,		ValueArgs>,		;SQRT
	<mask FT_STATISTICAL,	ListArgs>,		;STD
	<mask FT_STATISTICAL,	ListArgs>,		;STDP
	<mask FT_STRING,	STRINGArgs>,		;STRING
	<mask FT_MATH,		ListArgs>,		;SUM
	<mask FT_FINANCIAL,	SYDArgs>,		;SYD
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;TAN
	<mask FT_TRIGONOMETRIC,	TrigArgs>,		;TANH
	<mask FT_FINANCIAL,	TERMArgs>,		;TERM
	<mask FT_TIME_DATE,	TIMEArgs>,		;TIME
	<mask FT_TIME_DATE,	StringArgs>,		;TIMEVALUE
	<mask FT_TIME_DATE,	NoneArgs>,		;TODAY
	<mask FT_STRING,	StringArgs>,		;TRIM
	<mask FT_LOGICAL,	NoneArgs>,		;TRUE
	<mask FT_MATH,		ValueArgs>,		;TRUNC
	<mask FT_STRING,	StringArgs>,		;UPPER
	<mask FT_STRING,	StringArgs>,		;VALUE
	<mask FT_STATISTICAL,	ListArgs>,		;VAR
	<mask FT_STATISTICAL,	ListArgs>,		;VARP
	<mask FT_INFORMATION,	LookupArgs>,		;VLOOKUP
	<mask FT_TIME_DATE,	DateArgs>,		;WEEKDAY
	<mask FT_TIME_DATE,	DateArgs>		;YEAR
endif

CheckHack <(length funcTypeTable) eq (length funcTable)>

ParserGetFunctionArgs		proc	far
	uses	ds, si
	.enter

	call	FuncTypeToNum			;cx <- Nth match

	call	LockFuncStringsDS

	mov	si, cx
	shl	si, 1				;si <- # * 2
	shl	si, 1				;si <- # * 4
CheckHack <(size FuncEntry) eq 4>
	mov	si, cs:funcTypeTable[si].FE_args
	mov	si, ds:[si]			;ds:si <- ptr to chunk
	ChunkSizePtr ds, si, cx			;cx <- # of SBCS chars
DBCS <	shr	cx				;cx <- # of DBCS chars >
	dec	cx				;cx <- one less for NULL

	call	CopyArgNString

	call	UnlockFuncStrings

	.leave
	ret
ParserGetFunctionArgs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FuncTypeToNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the index of a FunctionType to an absolute index

CALLED BY:	ParserGetFunctionArgs(), ParserGetFunctionMoniker()
PASS:		cx - index #
		ax - FunctionType to match
RETURN:		cx - absolute index
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FuncTypeToNum		proc	near
	uses	dx, si
	.enter

	clr	si				;si <- ptr in table
	clr	dx				;dx <- index so far
funcLoop:
	test	ax, cs:funcTypeTable[si].FE_type
	jz	noMatch				;branch if wrong type
	jcxz	foundIndex			;branch if found enough
	dec	cx				;cx <- one less to match
noMatch:
	inc	dx				;dx <- next index
	add	si, (size FuncEntry)		;cs:si <- ptr to next
EC <	cmp	si, (size funcTypeTable)	;end of table?>
EC <	ERROR_A	ILLEGAL_FUNCTION_INDEX		;>
	jmp	funcLoop

foundIndex:
	mov	cx, dx				;cx <- absolute index

	.leave
	ret
FuncTypeToNum		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFuncStringsDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the function strings resource

CALLED BY:	UTILITY
PASS:		none
RETURN:		ds - seg addr of function strings
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The function strings resource is assumed to be read-only
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockFuncStringsDS		proc	near
	uses	ax, bx
	.enter

	mov	bx, handle FunctionArgs
	call	MemLock
	mov	ds, ax

	.leave
	ret
LockFuncStringsDS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockFuncStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the function strings resource

CALLED BY:	UTILITY
PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The function strings resource is assumed to be read-only
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockFuncStrings		proc	near
	uses	bx
	.enter

	mov	bx, handle FunctionArgs
	call	MemUnlock

	.leave
	ret
UnlockFuncStrings		endp


if DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopySBCSToDBCSNString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a specific count of SBCS chars into a DBCS buffer.
		The DBCS string is the C_NULL terminated. (See CopyNString.)

CALLED BY:	Utility (Parse Local)
		
PASS:		cx - # of chars in string (w/o NULL)
		ds:si - ptr to source
		es:di - ptr to dest
RETURN:		nothing
DESTROYED:	si
SIDE EFFECTS:	copies string

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	11/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopySBCSToDBCSNString	proc	near
	uses	ax,cx,di
	.enter

	clr	ah
expandLoop:
	lodsb					;in with ASCII..
	stosw					;..out with Unicode
	loop	expandLoop

	clr	ax				;and terminate string
	stosw

	.leave
	ret
CopySBCSToDBCSNString	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyArgNString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy and NULL-terminate a string, changing list separators
		as needed.

CALLED BY:	UTILITY
PASS:		cx - # of chars in string (w/o NULL)
		ds:si - ptr to source
		es:di - ptr to dest
RETURN:		none
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/12/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyArgNString		proc	near
	uses	ax, cx, di
listSeparator	local	TCHAR
	.enter

	push	ds
	segmov	ds, <segment idata>, ax		;ds = dgroup
if DBCS_PCGEOS
	mov	ax, ds:listSep
	mov	ss:listSeparator, ax		;ax <- list separator
else
	mov	al, ds:listSep			;al <- list separator
	mov	ss:listSeparator, al
endif
	pop	ds

copyLoop:
	LocalGetChar ax, dssi			;ax <- character
	LocalCmpChar ax, ','			;comma?
	jne	putChar				;branch if not comma
DBCS <	mov	ax, ss:listSeparator		;ax <- list separator >
SBCS <	mov	al, ss:listSeparator		;al <- list separator >
putChar:
	LocalPutChar esdi, ax			;store character
	loop	copyLoop			;loop while more chars

	clr	ax				;ax <- null terminator
	LocalPutChar esdi, ax			;NULL terminate

	.leave
	ret
CopyArgNString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy and NULL-terminate a string

CALLED BY:	UTILITY
PASS:		cx - # of chars in string (w/o NULL)
		ds:si - ptr to source
		es:di - ptr to dest
RETURN:		none
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNString		proc	near
	uses	ax, cx, di
	.enter

	LocalCopyNString
	clr	ax				;ax <- null terminator
	LocalPutChar esdi, ax			;NULL terminate

	.leave
	ret
CopyNString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserGetFunctionDescription
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the arguments for a specified function

CALLED BY:	GLOBAL
PASS:		cx - item #
		ax - FunctionType to match
		es:di - buffer for string
RETURN:		cx - # of chars (w/o NULL terminator)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Relies on long descriptions being "chunk.char/.wchar" types.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserGetFunctionDescription		proc	far
	uses	ds, si
	.enter

	call	FuncTypeToNum			;cx <- absolute index
	call	LockFuncStringsDS
	mov	si, cx				;si <- index
	shl	si, 1				;si <- *2 for lptrs
	add	si, offset absDesc		;si <- + 1st chunk
	mov	si, ds:[si]			;ds:si <- ptr to string
	ChunkSizePtr ds, si, cx			;cx <- size of string
DBCS< EC< cmp	cx, MAX_FUNCTION_ARGS_SIZE+MAX_FUNCTION_NAME_SIZE	> >
DBCS< EC< ERROR_AE  PARSE_STRING_TOO_LONG				> >
DBCS< EC< cmp	cx, MAX_FUNCTION_DESCRIPTION_SIZE			> >
DBCS< EC< ERROR_AE  PARSE_STRING_TOO_LONG				> >
DBCS<	shr	cx, 1				;cx <- length of string	>
	dec	cx				;cx <- one less for NULL

	call	CopyNString

	call	UnlockFuncStrings

	.leave
	ret
ParserGetFunctionDescription		endp

ParseMonikerCode	ends

FunctionArgs		segment lmem	LMEM_TYPE_GENERAL

;
; Commonly used arguments
;
LocalDefString ValueArgs	<"(value)", 0>
LocalDefString ListArgs		<"(value1,value2,...)", 0>
LocalDefString LogicalArgs	<"(logical1,logical2,...)", 0>
LocalDefString TrigArgs		<"(angle)", 0>
LocalDefString StringArgs	<"(string)", 0>
LocalDefString NoneArgs		<"()", 0>
LocalDefString RangeArgs	<"(range)", 0>
LocalDefString DateArgs		<"(date_value)", 0>
LocalDefString TimeArgs		<"(time_value)", 0>
LocalDefString StringNArgs	<"(string,num)", 0>
LocalDefString LookupArgs	<"(value,range,offset)", 0>
;
; Specialty arguments
;
LocalDefString ROUNDArgs	<"(value,places)", 0>
LocalDefString MODArgs		<"(value,divisor)", 0>
LocalDefString MIDArgs		<"(string,start,num)", 0>
LocalDefString REPLACEArgs	<"(original,start,num,replace)", 0>
LocalDefString SLNArgs		<"(cost,salvage,life)", 0>
LocalDefString SYDArgs		<"(cost,salvage,life,period)", 0>
LocalDefString STRINGArgs	<"(value,N)", 0>
LocalDefString DATEArgs		<"(year,month,day)", 0>
LocalDefString TIMEArgs		<"(hour,minute,second)", 0>
LocalDefString ATAN2Args	<"(x,y)", 0>
LocalDefString INDEXArgs	<"(range,column_offset,row_offset)", 0>
LocalDefString IFArgs		<"(logical,true_value,false_value)", 0>
LocalDefString CHOOSEArgs	<"(index,value1,value2,...)", 0>
LocalDefString FVArgs		<"(payments,interest,term)", 0>
LocalDefString IRRArgs		<"(guess,range)", 0>
LocalDefString NPVArgs		<"(interest,range)", 0>
LocalDefString PMTArgs		<"(principal,interest,term)", 0>
LocalDefString PVArgs		<"(payments,interest,term)", 0>
LocalDefString RATEArgs		<"(future_value,present_value,term)", 0>
LocalDefString CTERMArgs	<"(interest,future_value,present_value)", 0>
LocalDefString TERMArgs		<"(payments,interest,future_value)", 0>
LocalDefString DDBArgs		<"(cost,salvage,life,period)", 0>
LocalDefString EXACTArgs	<"(string1,string2)", 0>
LocalDefString FINDArgs		<"(substring,string,start)", 0>
LocalDefString DEGREESArgs	<"(radians)", 0>
LocalDefString RADIANSArgs	<"(degrees)", 0>

;
; Descriptions of each function
; IMPORTANT: The order of this list must match the order of the funcIDTable
;		declared in the parseVariables.asm	-- ChrisL 5/12/95.
;
;
.warn -unref

if PZ_PCGEOS
	LocalDefString	absDesc,	<"Absolute value", 0>
	LocalDefString	acosDesc,	<"Arc cosine", 0>
	LocalDefString	acoshDesc,	<"Hyperbolic arc cosine", 0>
	LocalDefString	andDesc,	<"Logical AND", 0>
	LocalDefString	asinDesc,	<"Arc sine", 0>
	LocalDefString	asinhDesc,	<"Hyperbolic arc sine", 0>
	LocalDefString	atanDesc,	<"Arc tangent", 0>
	LocalDefString	atan2Desc,	<"Four-quadrant arc tangent", 0>
	LocalDefString	atanhDesc,	<"Hyperbolic arc tangent", 0>
	LocalDefString	avgDesc,	<"Average of numbers", 0>
	LocalDefString	charDesc,	<"Character for given code", 0>
	LocalDefString	chooseDesc,	<"Choose from argument list", 0>
	LocalDefString	cleanDesc,	<"Remove control characters from string", 0>
	LocalDefString	codeDesc,	<"Return code for a given character", 0>
	LocalDefString	colsDesc,	<"Number of columns in a range", 0>
	LocalDefString	cosDesc,	<"Cosine", 0>
	LocalDefString	coshDesc,	<"Hyperbolic cosine", 0>
	LocalDefString	countDesc,	<"Count number of items in list", 0>
	LocalDefString	ctermDesc,	<"Number of periods for investment to grow", 0>
	LocalDefString	dateDesc,	<"Calculate date value from year, month, day", 0>
	LocalDefString	datevalueDesc,	<"Calculate date value from a date string", 0>
	LocalDefString	dayDesc,	<"Get day from date value", 0>
	LocalDefString	ddbDesc,	<"Depreciation using double-declining balance", 0>
	LocalDefString	errDesc,	<"Return #ERROR#", 0>
	LocalDefString	exactDesc,	<"Compare two strings", 0>
SBCS<	LocalDefString	expDesc,	<"Exponential \xd1 e to a power", 0>
DBCS<	LocalDefString	expDesc,	<"Exponential - e to a power", 0>
	LocalDefString	factDesc,	<"Factorial", 0>
	LocalDefString	falseDesc,	<"Logical FALSE value", 0>
	LocalDefString	findDesc,	<"Find substring in string", 0>
	LocalDefString	fvDesc, 	<"Future value of an investment", 0>
	LocalDefString	hlookupDesc,	<"Look up value in horizontal table", 0>
	LocalDefString	hourDesc,	<"Calculate hours from time value", 0>
	LocalDefString	ifDesc, 	<"Return one value if true, else other value", 0>
	LocalDefString	indexDesc,	<"Value of cell in range", 0>
	LocalDefString	intDesc,	<"Integer portion of a value", 0>
	LocalDefString	irrDesc,	<"Internal rate of return", 0>
	LocalDefString	iserrDesc,	<"Return TRUE if expression is an error", 0>
	LocalDefString	isnumberDesc,	<"Return TRUE if expression is a number", 0>
	LocalDefString	isstringDesc,	<"Return TRUE if expression is a string", 0>
	LocalDefString	leftDesc,	<"Return first characters of a string", 0>
	LocalDefString	lengthDesc,	<"Length of a string", 0>
	LocalDefString	lnDesc,  	<"Natural logarithm of a number", 0>
	LocalDefString	logDesc,	<"Logarithm base 10 of a number", 0>
	LocalDefString	lowerDesc,	<"Downcase a string", 0>
	LocalDefString	maxDesc,	<"Maximum of numbers", 0>
	LocalDefString	midDesc,	<"Return middle characters of a string", 0>
	LocalDefString	minDesc,	<"Minimum of numbers", 0>
	LocalDefString	minuteDesc,	<"Calculate minutes from time value", 0>
	LocalDefString	modDesc,	<"Remainder from division", 0>
	LocalDefString	monthDesc,	<"Calculate month from date value", 0>
	LocalDefString	nDesc,  	<"Return value from start of range", 0>
	LocalDefString	naDesc, 	<"Returns #N/A# error", 0>
	LocalDefString	nowDesc,	<"Current time", 0>
	LocalDefString	npvDesc,	<"Net present value", 0>
	LocalDefString	orDesc, 	<"Logical OR", 0>
SBCS<	LocalDefString	piDesc, 	<"\xb9 \xd1 pi", 0>
DBCS<	LocalDefString	piDesc, 	<C_GREEK_SMALL_LETTER_PI, " - pi", 0>
	LocalDefString	pmtDesc,	<"Payment for loan", 0>
	LocalDefString	productDesc,	<"Product of values", 0>
	LocalDefString	properDesc,	<"Capitalize string appropriately", 0>
	LocalDefString	pvDesc, 	<"Present value", 0>
	LocalDefString	randomnDesc,	<"Random value from zero to N-1", 0>
	LocalDefString	randomDesc,	<"Random value from zero to one", 0>
	LocalDefString	rateDesc,	<"Interest rate required for future value", 0>
	LocalDefString	repeatDesc,	<"Repeat string", 0>
	LocalDefString	replaceDesc,	<"Replace characters in a string", 0>
	LocalDefString	rightDesc,	<"Return last characters of a string", 0>
	LocalDefString	roundDesc,	<"Round to N places", 0>
	LocalDefString	rowsDesc,	<"Number of rows in a range", 0>
	LocalDefString	secondDesc,	<"Calculate seconds from time value", 0>
	LocalDefString	sinDesc,	<"Sine", 0>
	LocalDefString	sinhDesc,	<"Hyperbolic sine", 0>
	LocalDefString	slnDesc,	<"Depreciation using straight-line", 0>
	LocalDefString	sqrtDesc,	<"Square root", 0>
	LocalDefString	stdDesc,	<"Standard deviation of sample", 0>
	LocalDefString	stdpDesc,	<"Standard deviation of population", 0>
	LocalDefString	stringDesc,	<"Convert value into string", 0>
	LocalDefString	sumDesc,	<"Sum of numbers", 0>
	LocalDefString	sydDesc,	<"Sum of year's digits depreciation allowance", 0>
	LocalDefString	tanDesc,	<"Tangent", 0>
	LocalDefString	tanhDesc,	<"Hyperbolic tangent", 0>
	LocalDefString	termDesc,	<"Number of periods for investment to grow", 0>
	LocalDefString	timeDesc,	<"Calculate time value from hours, mins, secs", 0>
	LocalDefString	timevalueDesc,	<"Calculate time value from a string", 0>
	LocalDefString	todayDesc,	<"Date value for today", 0>
	LocalDefString	trimDesc,	<"Remove extra spaces", 0>
	LocalDefString	trueDesc,	<"Logical TRUE value", 0>
	LocalDefString	truncDesc,	<"Truncate to nearest integer", 0>
	LocalDefString	upperDesc,	<"Upcase string", 0>
	LocalDefString	valueDesc,	<"Convert string to a value", 0>
	LocalDefString	varDesc,	<"Variance of sample", 0>
	LocalDefString	varpDesc,	<"Variance of population", 0>
	LocalDefString	vlookupDesc,	<"Look up value in vertical table", 0>
	LocalDefString	weekdayDesc,	<"Calculate day of week from datevalue", 0>
	LocalDefString	yearDesc,	<"Calculate year from datevalue", 0>
	LocalDefString	fileDescDesc,	<"Name of document", 0>
	LocalDefString	pageDesc,	<"Current page of document", 0>
	LocalDefString	pagesDesc,	<"Total pages in document", 0>
	LocalDefString	degreesDesc,	<"Convert radians to degrees", 0>
	LocalDefString	radiansDesc,	<"Convert degrees to radians", 0>
PZ <	LocalDefString	declineBalanceDesc, <"Depreciation using declining balance method", 0>	>

else

	LocalDefString	absDesc,	<"Absolute value", 0>
	LocalDefString	acosDesc,	<"Arc cosine", 0>
	LocalDefString	acoshDesc,	<"Hyperbolic arc cosine", 0>
	LocalDefString	andDesc,	<"Logical AND", 0>
	LocalDefString	asinDesc,	<"Arc sine", 0>
	LocalDefString	asinhDesc,	<"Hyperbolic arc sine", 0>
	LocalDefString	atanDesc,	<"Arc tangent", 0>
	LocalDefString	atan2Desc,	<"Four-quadrant arc tangent", 0>
	LocalDefString	atanhDesc,	<"Hyperbolic arc tangent", 0>
	LocalDefString	avgDesc,	<"Average of numbers", 0>
	LocalDefString	charDesc,	<"Character for given code", 0>
	LocalDefString	chooseDesc,	<"Choose from argument list", 0>
	LocalDefString	cleanDesc,	<"Remove control characters from string", 0>
	LocalDefString	codeDesc,	<"Return code for a given character", 0>
	LocalDefString	colsDesc,	<"Number of columns in a range", 0>
	LocalDefString	cosDesc,	<"Cosine", 0>
	LocalDefString	coshDesc,	<"Hyperbolic cosine", 0>
	LocalDefString	countDesc,	<"Count number of items in list", 0>
	LocalDefString	ctermDesc,	<"Number of periods for investment to grow", 0>
	LocalDefString	dateDesc,	<"Calculate date value from year, month, day", 0>
	LocalDefString	datevalueDesc,	<"Calculate date value from a date string", 0>
	LocalDefString	dayDesc,	<"Get day from date value", 0>
	LocalDefString	ddbDesc,	<"Depreciation using double-declining balance", 0>
	LocalDefString	degreesDesc,	<"Convert radians to degrees", 0>
	LocalDefString	errDesc,	<"Return #ERROR#", 0>
	LocalDefString	exactDesc,	<"Compare two strings", 0>
SBCS<	LocalDefString	expDesc,	<"Exponential \xd1 e to a power", 0>
DBCS<	LocalDefString	expDesc,	<"Exponential - e to a power", 0>
	LocalDefString	factDesc,	<"Factorial", 0>
	LocalDefString	falseDesc,	<"Logical FALSE value", 0>
	LocalDefString	fileDescDesc,	<"Name of document", 0>
	LocalDefString	findDesc,	<"Find substring in string", 0>
	LocalDefString	fvDesc, 	<"Future value of an investment", 0>
	LocalDefString	hlookupDesc,	<"Look up value in horizontal table", 0>
	LocalDefString	hourDesc,	<"Calculate hours from time value", 0>
	LocalDefString	ifDesc, 	<"Return one value if true, else other value", 0>
	LocalDefString	indexDesc,	<"Value of cell in range", 0>
	LocalDefString	intDesc,	<"Integer portion of a value", 0>
	LocalDefString	irrDesc,	<"Internal rate of return", 0>
	LocalDefString	iserrDesc,	<"Return TRUE if expression is an error", 0>
	LocalDefString	isnumberDesc,	<"Return TRUE if expression is a number", 0>
	LocalDefString	isstringDesc,	<"Return TRUE if expression is a string", 0>
	LocalDefString	leftDesc,	<"Return first characters of a string", 0>
	LocalDefString	lengthDesc,	<"Length of a string", 0>
	LocalDefString	lnDesc,  	<"Natural logarithm of a number", 0>
	LocalDefString	logDesc,	<"Logarithm base 10 of a number", 0>
	LocalDefString	lowerDesc,	<"Downcase a string", 0>
	LocalDefString	maxDesc,	<"Maximum of numbers", 0>
	LocalDefString	midDesc,	<"Return middle characters of a string", 0>
	LocalDefString	minDesc,	<"Minimum of numbers", 0>
	LocalDefString	minuteDesc,	<"Calculate minutes from time value", 0>
	LocalDefString	modDesc,	<"Remainder from division", 0>
	LocalDefString	monthDesc,	<"Calculate month from date value", 0>
	LocalDefString	nDesc,  	<"Return value from start of range", 0>
	LocalDefString	naDesc, 	<"Returns #N/A# error", 0>
	LocalDefString	nowDesc,	<"Current time", 0>
	LocalDefString	npvDesc,	<"Net present value", 0>
	LocalDefString	orDesc, 	<"Logical OR", 0>
	LocalDefString	pageDesc,	<"Current page of document", 0>
	LocalDefString	pagesDesc,	<"Total pages in document", 0>
SBCS<	LocalDefString	piDesc, 	<"\xb9 \xd1 pi", 0>
DBCS<	LocalDefString	piDesc, 	<C_GREEK_SMALL_LETTER_PI, " - pi", 0>
	LocalDefString	pmtDesc,	<"Payment for loan", 0>
	LocalDefString	productDesc,	<"Product of values", 0>
	LocalDefString	properDesc,	<"Capitalize string appropriately", 0>
	LocalDefString	pvDesc, 	<"Present value", 0>
	LocalDefString	radiansDesc,	<"Convert degrees to radians", 0>
	LocalDefString	randomnDesc,	<"Random value from zero to N-1", 0>
	LocalDefString	randomDesc,	<"Random value from zero to one", 0>
	LocalDefString	rateDesc,	<"Interest rate required for future value", 0>
	LocalDefString	repeatDesc,	<"Repeat string", 0>
	LocalDefString	replaceDesc,	<"Replace characters in a string", 0>
	LocalDefString	rightDesc,	<"Return last characters of a string", 0>
	LocalDefString	roundDesc,	<"Round to N places", 0>
	LocalDefString	rowsDesc,	<"Number of rows in a range", 0>
	LocalDefString	secondDesc,	<"Calculate seconds from time value", 0>
	LocalDefString	sinDesc,	<"Sine", 0>
	LocalDefString	sinhDesc,	<"Hyperbolic sine", 0>
	LocalDefString	slnDesc,	<"Depreciation using straight-line", 0>
	LocalDefString	sqrtDesc,	<"Square root", 0>
	LocalDefString	stdDesc,	<"Standard deviation of sample", 0>
	LocalDefString	stdpDesc,	<"Standard deviation of population", 0>
	LocalDefString	stringDesc,	<"Convert value into string", 0>
	LocalDefString	sumDesc,	<"Sum of numbers", 0>
	LocalDefString	sydDesc,	<"Sum of year's digits depreciation allowance", 0>
	LocalDefString	tanDesc,	<"Tangent", 0>
	LocalDefString	tanhDesc,	<"Hyperbolic tangent", 0>
	LocalDefString	termDesc,	<"Number of periods for investment to grow", 0>
	LocalDefString	timeDesc,	<"Calculate time value from hours, mins, secs", 0>
	LocalDefString	timevalueDesc,	<"Calculate time value from a string", 0>
	LocalDefString	todayDesc,	<"Date value for today", 0>
	LocalDefString	trimDesc,	<"Remove extra spaces", 0>
	LocalDefString	trueDesc,	<"Logical TRUE value", 0>
	LocalDefString	truncDesc,	<"Truncate to nearest integer", 0>
	LocalDefString	upperDesc,	<"Upcase string", 0>
	LocalDefString	valueDesc,	<"Convert string to a value", 0>
	LocalDefString	varDesc,	<"Variance of sample", 0>
	LocalDefString	varpDesc,	<"Variance of population", 0>
	LocalDefString	vlookupDesc,	<"Look up value in vertical table", 0>
	LocalDefString	weekdayDesc,	<"Calculate day of week from datevalue", 0>
	LocalDefString	yearDesc,	<"Calculate year from datevalue", 0>

endif	; if Pizza

.warn @unref

FunctionArgs		ends

