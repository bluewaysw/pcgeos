COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseDepend.asm

AUTHOR:		John Wedgwood, Feb  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/ 4/91	Initial revision

DESCRIPTION:
	Code to generate dependency lists.

	$Id: parseDepend.asm,v 1.1 97/04/05 01:27:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EvalCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FuncArgDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to the application to generate dependencies for
		a list of function arguments.

CALLED BY:	PopOperatorAndEval
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		Arguments popped off the stack
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	count = func.nArgs;
	ArgDependencies( count );

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FuncArgDependencies	proc	near
	uses	cx
	.enter
	mov	cx, es:[di].OSE_data.ESOD_function.EFD_nArgs
	call	ArgDependencies
	jc	quit			; Quit on error
	;
	; Now that we've added the arguments of the function to the
	; dependency list we want to add the function as well.
	;
	mov	al, ESAT_FUNCTION	; Argument type
	push	bx			; Save argument ptr
	mov	bx, di			; es:bx <- ptr to EvalFunctionData
	inc	bx
	call	AddEntryToDependencyBlock
	pop	bx			; Restore argument ptr
	jc	quit			; Quit on error
	;
	; All functions return something. A function can only return a single
	; argument... Therefore it doesn't matter what we push, as long as
	; it's something...
	;
	clr	cx			; No extra space
	mov	al, mask ESAT_NUMBER	; al <- type of the token
	call	ParserEvalPushArgument		; Push the number token
quit:
	.leave
	ret
FuncArgDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpArgDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate dependencies for the arguments of an operator.

CALLED BY:	PopOperatorAndEval
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
RETURN:		carry set on error
		al	= Error code
		Arguments popped off the stack
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	count = opArgCountTable[opType];
	ArgDependencies( count );

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpArgDependencies	proc	near
	uses	cx, si
	.enter
	mov	al, es:[di].OSE_data.ESOD_operator.EOD_opType
	cmp	al, OP_RANGE_SEPARATOR
	je	handleRangeSep

	cmp	al, OP_RANGE_INTERSECTION
	je	handleRangeInt
	
	clr	ah
	mov	si, ax		; si <- index into the arg-count table
	
	clr	ch
	mov	cl, cs:opArgCountTable[si]
	call	ArgDependencies
	;
	; All operators (except the range-separator, handled above) produce
	; a number as their result. It doesn't really matter actually, all
	; that matters is that we put some result back on the argument
	; stack so that evaluation can continue as it should.
	;
	; We can't really push a number because the fp-fixup code will choke
	; after generating dependencies if it thinks we are returning a number.
	;
	clr	cx			; No extra space
	mov	al, mask ESAT_NUMBER	; al <- type of the token
	call	ParserEvalPushArgument		; Push the number token
quit:
	.leave
	ret

handleRangeSep:
	;
	; Ranges get handled separately since we actually want to accumulate
	; them.
	;
	call	OpRangeSeparator
	jmp	quit

handleRangeInt:
	;
	; We also want to accumulate ranges defined by the range-intersection
	; operator.
	;
	call	OpParserRangeIntersection
	jmp	quit
OpArgDependencies	endp

;
; A list of the number of arguments each operator takes.
;
opArgCountTable		byte	-1,	; OpRangeSeparator,
				1,	; OpNegation,
				1,	; OpPercent,
				2,	; OpExponentiation,
				2,	; OpMultiplication,
				2,	; OpDivision,
				2,	; OpModulo,
				2,	; OpAddition,
				2,	; OpSubtraction,
				2,	; OpEqual,
				2,	; OpNotEqual,
				2,	; OpLessThan,
				2,	; OpGreaterThan,
				2,	; OpLessThanOrEqual,
				2,	; OpGreaterThanOrEqual
				2,	; OpStringConcat
				-1,	; OpParserRangeIntersection
				2,	; OpNotEqualGraphic
				2,	; OpDivisionGraphic
				2,	; OpLessThanOrEqualGraphic
				2	; OpGreaterThanOrEqualGraphic


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArgDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the application for each argument.

CALLED BY:	FuncArgDependencies, OpArgDependencies
PASS:		es:di	= Pointer to top of operator/function stack
		es:bx	= Pointer to top of argument stack
		ss:bp	= Pointer to EvalParameters structure on the stack.
		cx	= # of arguments to handle
RETURN:		carry set on error
		al	= Error code
		Arguments popped off the stack
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArgDependencies	proc	near
	uses	cx
	.enter
EC <	cmp	cl, -1				>
EC <	ERROR_Z	ARG_COUNT_IS_VERY_UNREASONABLE	>
	tst	cx				; Check for no args
	; (The tst instruction clears the carry, which is what I want)
	jz	quit				; Quit if no arguments
argLoop:
	push	bx				; Save arg stack pointer
	mov	al, es:[bx]			; al <- the token type
	inc	bx				; es:bx <- ptr to the data
	call	AddEntryToDependencyBlock	; Add a single entry
	pop	bx				; Restore arg stack pointer
	jc	quit				; Quit if error

	push	cx				; Save arg count
	mov	cx, 1				; Pop one argument
	call	ParserEvalPopNArgs			; Pop me jesus
	pop	cx				; Restore arg count
	loop	argLoop				; Loop while there are args

	clc					; Signal: no error
quit:
	.leave
	ret
ArgDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddEntryToDependencyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the evaluators dependency block

CALLED BY:	ArgDependencies
PASS:		es:bx	= Pointer to the data which we want to add to the
			  dependency block
		al	= EvalStackArgumentType
		ss:bp	= Pointer to EvalParameters
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The evaluator, when generating dependencies, keeps a list of the
	dependencies in a global memory block. This block is returned to
	the application so that it can actually add the dependencies
	in whatever way it wants.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddEntryToDependencyBlock	proc	near
	uses	bx, cx, dx, di, si, ds, es
	.enter
	;
	; We may not want to do anything with name-dependencies. We check
	; for that here.
	;
	test	ss:[bp].EP_flags, mask EF_NO_NAMES
	jz	skipNoNameCheck		; Branch if we don't care
	cmp	al, ESAT_NAME		; Check for a name
	je	quitNoErrorNoBlock	; Branch if it's a name
skipNoNameCheck:

	;
	; We may be only adding name dependencies... If we are we want to make
	; sure that we have the right type here.
	;
	test	ss:[bp].EP_flags, mask EF_ONLY_NAMES
	jz	skipNameCheck		; Branch if we don't care
	cmp	al, ESAT_NAME		; We do care, check for name
	jne	quitNoErrorNoBlock	; Branch if not a name
skipNameCheck:
	;
	; We only want to add the dependency if it's to a name, cell, range
	; or externally defined function.
	;
	cmp	al, ESAT_FUNCTION	; Check for function type
	jne	checkDependencyType	; Branch if not a function
	;
	; It's a function, check for externally defined.
	;
	cmp	es:[bx].EFD_functionID, FUNCTION_ID_FIRST_EXTERNAL_FUNCTION
	jb	quitNoErrorNoBlock	; Quit if defined internally

checkDependencyType:
	call	NeedDependency		; Check for one of those things we
					;   want a dependency for
	jnc	quitNoErrorNoBlock	; Branch if not
	
	;
	; We do want to add this dependency.
	;
	mov	si, bx			; es:si <- ptr to source for data
	
	mov	cl, al			; Save the token

	push	si
	call	GetArgumentSize		; si <- size of the argument
	mov	dx, si			; dx <- size of the argument
	pop	si

	mov	bx, ss:[bp].EP_depHandle

	tst	bx			; Check for block existing
	jz	createDepBlock		; Branch if it doesn't

gotDepBlock:
	call	MemLock			; ds <- seg address of the block
	mov	ds, ax
	;
	; ds = segment address of the block
	; bx = block handle
	; dx = size of the token data (not including type byte)
	; cl = token
	;
	push	cx			; Save the token
	mov	ax, ds:DB_size		; ax <- size of the block
	inc	dx			; Allow size for the type byte
	add	ax, dx			; ax <- new size for the block
	clr	ch			; No allocation flags
	call	MemReAlloc		; Make the block bigger
	mov	ds, ax			; Reset the segment address
	pop	cx			; Restore the token
	;
	; Check for error
	;
	mov	al, PSEE_TOO_MANY_DEPENDENCIES
	jc	quitUnlock		; Quit on error
	;
	; The block is bigger... Update the size
	;
	mov	di, ds:DB_size		; ds:di <- ptr to place to put data
	segxchg	ds, es			; es:di <- ptr to dest
					; ds:si <- ptr to source
	mov	al, cl			; al <- the token
	stosb				; Save the type of the data
	mov	cx, dx			; cx <- size of the data
	dec	cx			; Move data, not the token
	rep	movsb			; Save the data
	
	add	es:DB_size, dx		; Update the size of the block
	
	clc				; Signal: no error

quitUnlock:
	call	MemUnlock		; Release the block (flags preserved)

quit:
	.leave
	ret

quitNoErrorNoBlock:
	;
	; We want to quit but we have no block yet.
	;
	clc				; Signal: no error
	jmp	quit

createDepBlock:
	;
	; Allocate and initialize the dependency block.
	;
	push	cx			; Save the token
	mov	ax, size DependencyBlock
	mov	cl, mask HF_SWAPABLE
	mov	ch, mask HAF_LOCK	; Want the block locked
	call	MemAlloc
	pop	cx			; Restore the token
	;
	; Carry set if not enough memory
	;
	mov	ds, ax			; ds <- seg address of the block
	;
	; Check for allocation error.
	;
	mov	al, PSEE_TOO_MANY_DEPENDENCIES
	jc	quit			; Quit on error
	;
	; Block was allocated just fine, save the handle and initialize it.
	;
	mov	ss:[bp].EP_depHandle, bx
	mov	ds:DB_size, size DependencyBlock
	jmp	gotDepBlock
AddEntryToDependencyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NeedDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we want a dependency for this argument type

CALLED BY:	AddEntryToDependencyBlock
PASS:		al	= EvalStackArgumentType
		es:bx	= Pointer to ParserToken...Data
		ss:bp	= Pointer to EvalParameters on stack
RETURN:		carry set if we want to add a dependency
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NeedDependency	proc	near
	uses	ax
	.enter
	cmp	al, ESAT_NAME
	je	quit			; Carry clear if we branch

	cmp	al, ESAT_FUNCTION
	je	quit			; Carry clear if we branch

	test	al, mask ESAT_RANGE	; Clears the carry
	jz	noDependency
	;
	; It's a range... How amusing. Check to see if the range is in
	; the legal bounds of the spreadsheet. If it's not, don't generate
	; a dependency for it.
	;
	mov	ax, es:[bx].ERD_firstCell.CR_row
	and	ax, mask CRC_VALUE

	cmp	ax, ss:[bp].CP_maxRow	; Check for past end
	ja	noDependency		; Branch if past end

	mov	ax, es:[bx].ERD_lastCell.CR_row
	and	ax, mask CRC_VALUE

	cmp	ax, ss:[bp].CP_maxRow	; Check for past end
	ja	noDependency		; Branch if past end

	mov	ax, es:[bx].ERD_firstCell.CR_column
	and	ax, mask CRC_VALUE

	cmp	ax, ss:[bp].CP_maxColumn; Check for past end
	ja	noDependency		; Branch if past end

	mov	ax, es:[bx].ERD_lastCell.CR_column
	and	ax, mask CRC_VALUE

	cmp	ax, ss:[bp].CP_maxColumn; Check for past end
	ja	noDependency		; Branch if past end
	
	clc				; We want the dependency
	jmp	quit

noDependency:
	stc				; Don't need a dependency
quit:
	cmc				; Reverse the carry to get the return
					;   flag set correctly
	.leave
	ret
NeedDependency	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserAddDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a set of dependencies from a dependency block

CALLED BY:	Global
PASS:		bx	= Handle of the dependency block
		ss:bp	= Pointer to DependencyParameters on the stack
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserAddDependencies	proc	far
	uses	dx
	.enter
	mov	dx, offset ParserAddSingleDependencyNear	; dx <- routine to call
	call	HandleDependencyBlock
	.leave
	ret
ParserAddDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserRemoveDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a set of dependencies from a dependency block

CALLED BY:	Global
PASS:		bx	= Handle of the dependency block
		ss:bp	= Pointer to DependencyParameters on the stack
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserRemoveDependencies	proc	far
	uses	dx
	.enter
	mov	dx, offset RemoveSingleDependency ; dx <- routine to call
	call	HandleDependencyBlock
	.leave
	ret
ParserRemoveDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleDependencyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a set of dependencies

CALLED BY:	ParserAddDependencies, ParserRemoveDependencies
PASS:		bx	= Block handle of the dependency block
		ss:bp	= Pointer to the DependencyParameters on the stack
		dx	= Offset of routine to call: Add/RemoveSingleDependency
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleDependencyBlock	proc	near
	uses	cx, dx, di
	.enter
	mov	cx, dx			; cx <- callback for callback :-)

	mov	di, cs			; di:dx <- callback routine
	mov	dx, offset cs:HandleBlockCallback
	
	call	ParserForeachPrecedent	; Process the list
	.leave
	ret
HandleDependencyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleBlockCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for ParserForeachPrecedent

CALLED BY:	HandleDependencyBlock via ParserForeachPrecedent
PASS:		dl	= Type of the precedent entry
		es:di	= Pointer to the precedent entry data
		
		ss:bp	= DependencyParameters
		cx	= Callback for callback
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleBlockCallback	proc	far
	uses	ds, si, di, dx
	.enter
	segmov	ds, es, si			; ds:si <- ptr to range data
	mov	si, di

	;
	; dl still holds the precedent entry type.
	;
	call	GetDependencyHandler		; di <- routine to call
	
	mov	dx, cx				; dx <- callback for callback

	call	di				; Call the routine
	.leave
	ret
HandleBlockCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserForeachPrecedent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run through the precedent list calling a callback.

CALLED BY:	Global, HandleDependencyBlock
PASS:		bx	= Block
		di:dx	= Routine to call
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Callback is defined as:
	    PASS:	cx, ds, si, bp	= Same as passed in
			dl	= Type of the precedent
	    		es:di	= Pointer to the precedent data
	    RETURN:	Carry set to abort
	    		al	= Error code
	    DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachPrecParams	struct
    FPP_callback	dword			; Callback
    FPP_block		hptr			; Block handle of precedent list
ForeachPrecParams	ends

ParserForeachPrecedent	proc	far
	uses	bx, dx, di, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	ax						>
EC <		mov	ax, cs						>
EC <		cmp	ax, di						>
EC <		pop	ax						>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, didx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
xipSafe::
endif
	;
	; Create a stack frame by pushing the passed data
	;
	push	bx				; Save the memory handle
	push	di				; Save segment of callback
	push	dx				; Save offset of callback
	
	;;;
	;;; We haven't set up a pointer to the stack frame so don't mess with
	;;; sp until we do.
	;;;

	;
	; Now lock the block and start processing...
	;
	call	MemLock				; es <- address of dep block
	mov	es, ax

	;
	; Set up a pointer to the stack frame.
	;
	mov	bx, sp				; ss:bx <- stack frame
	
	mov	di, size DependencyBlock	; es:di <- ptr to 1st dep
depLoop:
	;
	; es:0	= dependency block
	; es:di	= pointer to current dependency
	; es:DB_size = offset past last entry in the block
	; ss:bx	= ForeachPrecParams
	;
	cmp	di, es:DB_size			; Check for done
	je	endLoop				; Branch if done
	;
	; Load up the appropriate information for the single dependency
	;
	mov	dl, {byte} es:[di]		; dl <- the type of the arg
	inc	di				; Point to the data

if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].FPP_callback.offset
	mov	bx, ss:[bx].FPP_callback.segment
	call	ProcCallFixedOrMovable
	pop	bx
else
	call	ss:[bx].FPP_callback		; Call the callback
endif

	jc	quit				; Branch on error

	;
	; Advance to the next dependency entry
	; dl = the type of the current entry
	;
	push	si				; Save passed si
	mov	al, dl				; al <- type
	call	GetArgumentSize			; si <- size of the data
	add	di, si				; es:di <- ptr to next entry
	pop	si				; Restore passed si

	jmp	depLoop				; Loop to do the next one

endLoop:
	clc					; Signal no error

quit:
	;
	; Carry set on error
	; al = error code
	;
	mov	bx, ss:[bx].FPP_block		; bx <- block handle
	call	MemUnlock			; Release the block
	
	lahf					; Save "error" flag (carry)
	add	sp, size ForeachPrecParams	; Restore stack frame
	sahf					; Restore "error" flag (carry)
	.leave
	ret
ParserForeachPrecedent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDependencyHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the routine to handle a given dependency type

CALLED BY:	HandleDependencyBlock
PASS:		dl	= EvalStackArgumentType
RETURN:		di	= Routine to call
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDependencyHandler	proc	near
	mov	di, offset cs:HandleNameDependency
	cmp	dl, ESAT_NAME
	je	quit

	mov	di, offset cs:HandleFunctionDependency
	cmp	dl, ESAT_FUNCTION
	je	quit

	mov	di, offset cs:HandleRangeDependency
	test	dl, mask ESAT_RANGE
	jnz	quit
	
	ERROR	ILLEGAL_DEPENDENCY_TYPE
quit:
	ret
GetDependencyHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleRangeDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a dependency block entry for a range

CALLED BY:	HandleDependencyBlock via depHandlerTable
PASS:		ss:bp	= DependencyParameters
		ds:si	= Pointer to EvalRangeData
		dx	= Callback routine to use (Add/RemoveSingleDependency)
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	By the time we get here the cells have already been adjusted for
	relative references. This means that we don't need to worry about
	sign extending the value to the full 16 bits.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleRangeDependency	proc	near
	uses	bx, cx, di, si
	.enter
	;
	; Load up a bunch of registers with stuff we need.
	;
	mov	ax, ds:[si].ERD_firstCell.CR_row
	mov	cx, ds:[si].ERD_firstCell.CR_column
	mov	bx, ds:[si].ERD_lastCell.CR_row
	mov	si, ds:[si].ERD_lastCell.CR_column
	and	ax, mask CRC_VALUE		; Just the value, not the
	and	cx, mask CRC_VALUE		;    flags
	and	bx, mask CRC_VALUE
	and	si, mask CRC_VALUE
	
rowLoop:
	;
	; ax = start row
	; bx = end row
	; dx = routine to call
	;
	cmp	ax, bx				; Check for done last row
	ja	endRowLoop			; Branch if finished
	push	cx				; Save starting column
columnLoop:
	;
	; on-stack: starting column
	; cx = start column
	; si = end column
	; dx = routine to call
	;
	cmp	cx, si				; Check for done last column
	ja	endColumnLoop			; Branch if finished a row
	;
	; Handle a single dependency. ax/cx = the dependency.
	;
	mov	di, ax				; Save current row
	call	dx				; Handle the dependency
	jc	error				; Quit on error
	mov	ax, di				; Restore current row

	inc	cx				; Move to next column
	jmp	columnLoop			; Loop to handle it
endColumnLoop:
	pop	cx				; Restore starting column
	inc	ax				; Move to next row
	jmp	rowLoop				; Loop to handle it
endRowLoop:
	clc					; Signal: no error

quit:
	.leave
	ret

error:
	pop	cx				; Restore register from stack
	jmp	quit
HandleRangeDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNameDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a dependency block entry for a name

CALLED BY:	HandleDependencyBlock via depHandlerTable
PASS:		ss:bp	= DependencyParameters
		ds:si	= Pointer to EvalNameData
		dx	= Callback routine to use (Add/RemoveSingleDependency)
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Call back to the application to get the row/column for the name.
	Handle the dependency for that row/column.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNameDependency	proc	near
	uses	cx, dx, di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CP_callback			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov	di, dx			; Save the routine to call in di

	mov	cx, ds:[si].END_name	; cx <- the name token
	mov	al, CT_NAME_TO_CELL	; Dereference the name
if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bp].CP_callback	; Call the application
	call	ProcCallFixedOrMovable
	pop	bx
else
	call	ss:[bp].CP_callback	; Call the application
endif
	jc	quit			; Quit on error
	;
	; dx/cx = Row/Column of the cell holding the name dependencies
	;
	mov	ax, dx			; ax/cx <- Row/Column of the cell
	call	di			; Call the handling routine
quit:
	.leave
	ret
HandleNameDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFunctionDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a dependency block entry for a function

CALLED BY:	HandleDependencyBlock via depHandlerTable
PASS:		ss:bp	= DependencyParameters
		ds:si	= Pointer to EvalFunctionData
		dx	= Callback routine to use (Add/RemoveSingleDependency)
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFunctionDependency	proc	near
	uses	cx, dx, di
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CP_callback			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	di, dx			; Save the routine to call in di

	mov	cx, ds:[si].EFD_functionID
	mov	al, CT_FUNCTION_TO_CELL	; Dereference the function
if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bp].CP_callback	; Call the application
	call	ProcCallFixedOrMovable
	pop	bx
else
	call	ss:[bp].CP_callback	; Call the application
endif
	jc	quit			; Quit on error
	;
	; dx/cx = Row/Column of the cell holding the name dependencies
	;
	tst	dx			; Check for no dependency required
					; (clear the carry)
	jz	quit			; Branch if none needed

	mov	ax, dx			; ax/cx <- Row/Column of the cell
	call	di			; Call the handling routine
quit:
	.leave
	ret
HandleFunctionDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserAddSingleDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single dependency to a cell

CALLED BY:	Global
PASS:		ds:si	= CellFunctionParameters
		ax	= Row of cell to add dependency to
		cx	= Column of cell to add dependency to
		ss:bp	= DependencyParameters
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserAddSingleDependency	proc	far
	call	ParserAddSingleDependencyNear
	ret
ParserAddSingleDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserAddSingleDependencyNear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a dependency to a dependency list

CALLED BY:	Global
PASS:		ax	= Row of cell to add dependency to
		cx	= Column of cell to add dependency to
		ss:bp	= DependencyParameters
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Lock the cell
	Get a pointer to the dependency list
	
	if the cell doesn't exist
	    Call the application to create the cell
	endif

	Find the position to add the dependency

	if the dependency doesn't exist
	    insert space for the dependency
	    save the current row/cell in the dependency list
	endif
	
	Unlock the cell

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserAddSingleDependencyNear	proc	near
	uses	ds, es, di, si, dx, bx
	.enter
lockCellAgain:
	call	LockFirstDepListBlock	; carry clear if cell doesn't exist
	jnc	makeCellExist		; Branch to call the application
	
	tst	si			; Check for no dependencies at all
	jz	addNewEntry		; Branch if none

	;
	; ds:si	= ptr to the dependency list
	;
	call	FindDependencyEntry	; Locate the dependency
	jc	quitUnlock		; Quit if already exists

addNewEntry:	
	;
	; The entry wasn't found. We need to add a new one.
	;
	; ds:di	= ptr to the start of the dependency list block
	; ds:si	= ptr to the place to add the new entry
	; ax	= Row
	; cx	= Column
	;
	call	AddDependencyListEntry

	;
	; Fill in the entry
	;
	mov	ax, ss:[bp].CP_row	; Row to add as a dependency
	mov	ds:[si].D_row, ax
	mov	ax, ss:[bp].CP_column	; Column to add as a dependency
	mov	ds:[si].D_column, al

quitUnlock:
	call	UnlockDependencyList	; Release the dependency list
	clc				; Signal: no error
quit:
	;
	; Carry should be set here if you want to indicate some sort of error.
	;
	.leave
	ret

makeCellExist:

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CP_callback			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ax			; Pass row in dx
	mov	al, CT_CREATE_CELL	; al <- code ("make cell exist")
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; Call the application to make the cell
endif
	jc	quit			; Quit if error

	mov	ax, dx			; Restore row for re-lock
	jmp	lockCellAgain		; Else branch to re-lock the cell
ParserAddSingleDependencyNear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDependencyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the dependency list.

CALLED BY:	ParserAddSingleDependencyNear, RemoveSingleDependency
PASS:		ds:si	= Pointer to the dependency list item
		si	= 0 if there is no dependency list
RETURN:		nothing
DESTROYED:	es, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDependencyList	proc	near
	push	ds, si			; Save ptr to dependency list
	lds	si, ss:[bp].CP_cellParams
	mov	bx, ds:[si].CFP_file	; bx <- file handle
	pop	es, si			; Restore ptr to dependency list

	;
	; es:si	= Pointer to dependency list
	; bx	= File handle.
	;
	tst	si			; Check for no dependency list
	jz	quit			; Branch if none (carry is clear here)
	
	call	DBUnlock		; Unlock block pointed at by es
quit:
	ret
UnlockDependencyList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveSingleDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a dependency from a dependency list

CALLED BY:	Global
PASS:		ax	= Row of cell to add dependency to
		cx	= Column of cell to add dependency to
		ss:bp	= DependencyParameters
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Get a pointer to the dependency list
	
	if the cell doesn't exist
	    <<<Fatal Error>>>
	endif

	Find the position of the dependency

	if the dependency doesn't exist
	    It must have been deleted before this point, quit (no error)
	endif
	
	Delete the entry from the dependency list
	
	if the dependency list is empty
	    call back to the application
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveSingleDependency	proc	near
	uses	ds, di, si, dx
	.enter
	call	LockFirstDepListBlock	; carry clear if cell doesn't exist
	;
	; Simply exit if the cell doesn't exist.  This case occurs if
	; a cell is referred to twice in an expression (eg. =B1+B1).
	; When the first reference is encountered, B1 will be deleted
	; if it doesn't have any data in it other than dependencies.
	; When the second reference is encountered, B1 is already gone
	; so we simply exit.  Note that there are more complicated
	; cases where this can occur (eg. ranges that partially overlap),
	; so it isn't really practical to eliminate redundant entries
	; in general. -- eca 3/3/93.
	;
	jnc	quit			; branch if cell doesn't exist

	tst	si			; Check for any dependencies at all
	jz	noMoreDependencies	; Branch if there are no more

	;
	; ds:si	 = ptr to the dependency list
	;
	call	FindDependencyEntry	; Locate the dependency
	jnc	quit			; Quit if entry is already gone

	;
	; ds:di	= ptr to the start of the dependency list block
	; ds:si	= ptr to the dependency to delete
	;
	call	DeleteDependencyEntry	; Delete the entry
					; This unlocks the dependency block.
	jz	noMoreDependencies	; Branch if no more dependencies

	clc				; Signal: no error
quit:
	.leave
	ret

noMoreDependencies:

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CP_callback			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ax			; Pass row in dx
	mov	al, CT_EMPTY_CELL	; al <- code (cell is empty)
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; Let application know that there are
				;   no more dependencies for this item.
endif
	jmp	quit
RemoveSingleDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFirstDepListBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the first dependency list block.

CALLED BY:	ParserAddSingleDependencyNear, RemoveSingleDependency
PASS:		ax,cx	= Row/Column of the cell to lock
RETURN:		carry set if the cell exists
		ds:si	= Ptr to the dependency list
		ds:di	= Ptr to the dependency list
		si	= 0 if there is no dependency list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockFirstDepListBlock	proc	near
	uses	ax, bx, es
	.enter
	;
	; Get the dbase item for the cell (also checks to see if the cell exists)
	;
	lds	si, ss:[bp].CP_cellParams
	mov	bx, ds:[si].CFP_file	; bx <- file handle
	call	CellGetDBItem		; ax/di <- Group/Item of the cell
	jnc	quit			; Quit if no cell

	;
	; Initialize the stack frame.
	;
	mov	ss:[bp].DP_prevIsCell, 0xff
	mov	ss:[bp].DP_prev.segment, ax
	mov	ss:[bp].DP_prev.offset, di

	call	DBLock			; Lock the cell (*es:di <- cell ptr)

	;
	; The first dword of the cell data is the dbase item.
	;
	mov	si, es:[di]		; es:si <- ptr to cell data
	tst	es:[si].segment		; Check for NULL segment (which means
					;   that no dependencies exist)
	jz	quitNoDepsCellExists	; Branch if no dependencies

	;
	; OK, the cell exists and has dependencies, we need to lock the
	; dependency list.
	;
	push	es, di			; Save cell ptr
	mov	ax, es:[si].segment	; ax <- group
	mov	di, es:[si].offset	; di <- item
	
	;
	; Save the dbase item which contains the dependency list.
	;
	mov	ss:[bp].DP_dep.segment, ax
	mov	ss:[bp].DP_dep.offset, di

	;
	; Now lock down the dependency list item and return a pointer to it.
	;
	call	DBLock			; *es:di <- ptr to dependency list
	mov	ss:[bp].DP_chunk, di	; Save chunk handle

	segmov	ds, es, si		; *ds:si <- ptr to dependency list
	mov	si, di
	mov	si, ds:[si]		; ds:si <- ptr to dependency list
	pop	es, di			; Restore cell ptr
	
	;
	; We should have:
	;	*es:di	= Ptr to cell data
	;	ds:si	= Ptr to dependency list
	;	ss:bp.DP_dep = DBase item containing the dependency list
	;

quitCellExists:
	;
	; Unlock the cell. We don't need it.
	;
	push	ds, si			; Save the ptr to the dependency list
	lds	si, ss:[bp].CP_cellParams
	call	CellUnlock		; Cell release thyself
	pop	ds, si			; Restore ptr to the dependency list

	stc				; Signal: cell exists
quit:
	mov	di, si			; Return both registers the same
	.leave
	ret

quitNoDepsCellExists:
	;
	; The cell exists but has no dependencies.
	;
	clr	si			; Assume no such item exists.
	mov	ss:[bp].DP_dep.segment, si
	jmp	quitCellExists

LockFirstDepListBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindDependencyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a dependency in the dependency list

CALLED BY:	ParserAddSingleDependencyNear, RemoveSingleDependency
PASS:		ss:bp	= DependencyParameters on stack
		ds:si	= Pointer to the dependency list
			  This MUST be valid
RETURN:		ds:si	= Pointer to the dependency entry
		ds:di	= Pointer to the base of the dependency list block
		carry set if it exists
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindDependencyEntry	proc	near
	uses	ax, bx, cx, dx
	.enter
findDependencyInThisBlock:
	;
	; We need to know how many entries there are in this part of the
	; dependency list. This actually turns out not to be quick to compute
	; since the size of each entry is 3 bytes. As a result we just figure
	; the size (in bytes) of this part of the list.
	;
	ChunkSizePtr	ds, si, cx	; cx <- size of this part of the list
	sub	cx, size DependencyListHeader
	
	mov	di, si			; Save ptr to start of the block
	add	si, size DependencyListHeader

	;
	; cx	= # of bytes in this part of the list.
	; ds:si	= Pointer to first entry in this part of the list.
	; ds:di	= Pointer to the start of this block.
	;
	jcxz	quitNotFound		; Quit if no entries
	
	mov	bx, ss:[bp].CP_row	; bx <- row to find
	mov	dx, ss:[bp].CP_column	; dl <- column to find

findLoop:
	;
	; cx	= # of bytes left to scan.
	; ds:si	= Pointer to next entry to check.
	; ds:di	= Pointer to the start of this block.
	; bx	= Row to find.
	; dl	= Column to find.
	;
	cmp	ds:[si].D_row, bx	; Check for same row
	jb	nextEntry		; Branch if not found
	ja	quitNotFound		; Quit if found place for new item

	cmp	ds:[si].D_column, dl	; Check for same column
	ja	quitNotFound		; Quit if found place for new item
	je	found			; Branch if the same row and column

nextEntry:
	add	si, size Dependency	; Skip to next entry
	sub	cx, size Dependency	; This many fewer bytes
	jnz	findLoop		; Loop while there are still entries
	
	;
	; We ran out of bytes. Check to see if there is another block we can
	; move to.
	;
	call	LockNextDependencyBlock	; Lock the next block
	jc	findDependencyInThisBlock

	;
	; There is no next block. We're done and we haven't found the entry.
	;
quitNotFound:
	clc				; Signal: does not exist
	jmp	quit			;

found:
	stc				; Signal: found
quit:
	.leave
	ret
FindDependencyEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNextDependencyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the next block in the dependency list chain.

CALLED BY:	FindDependencyEntry
PASS:		ds:di	= Pointer to the current dependency block.
		ss:bp.DP_dep = DBase item for current dependency block.
RETURN:		carry set if another block exists
			ds:si	= Pointer to the new block
			ss:bp.DP_dep = DBase item for the new block
			ss:bp.DP_prev = Previous dbase item
			ss:bp.DP_prevIsCell cleared
		
		carry clear if no more blocks exist.
			ds:si unchanged
			ss:bp.DP_dep unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockNextDependencyBlock	proc	near
	uses	ax, bx, di, es
	.enter
	tst	ds:[di].DLH_next.segment	; Check for another block
	jz	quit				; Branch if no more (carry clear)
	
	;
	; Copy the current item to the previous item.
	;
	movdw	ss:[bp].DP_prev, ss:[bp].DP_dep, ax
	
	mov	ss:[bp].DP_prevIsCell, 0	; Previous is no
						; longer the cell
	
	;
	; There is another block. Unlock the current block and lock
	; the new one.
	;
	mov	ax, ds:[di].segment		; ax <- group
	mov	di, ds:[di].offset		; di <- item

	segmov	es, ds, si			; es <- segment address of item
	lds	si, ss:[bp].CP_cellParams	; ds:si <- cell paramters
	mov	bx, ds:[si].CFP_file		; bx <- file handle
	call	DBUnlock			; Unlock the item
	
	;
	; bx = File handle
	; ax = Group containing the new dependencies
	; di = Item containing the new dependencies
	;
	mov	ss:[bp].DP_dep.segment, ax	; Save group and item
	mov	ss:[bp].DP_dep.offset, di

	call	DBLock				; *es:di <- ptr to dependencies
	mov	ss:[bp].DP_chunk, di		; Save chunk handle

	segmov	ds, es, si			; ds:si <- ptr to dependencies
	mov	si, ds:[di]
	
	stc					; Signal: block exists
quit:
	;
	; Carry should be set here if a new block exists and is locked down.
	;
	.leave
	ret
LockNextDependencyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDependencyListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an empty dependency list item

CALLED BY:	ParserAddSingleDependencyNear
PASS:		ds:di	= Pointer to dependency list block
		ds:si	= Pointer to place to insert new entry
		ss:bp.DP_dep = DBase item containing the dependency list block
		ax	= Row of the cell
		cx	= Column of the cell
RETURN:		ds:si	= Place to put the dependency data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If (no dependencies) then
	    Insert an empty block
	endif

	if (blockSize > maxBlockSize) then
	    InsertBlock( block )
	endif
	
	InsertSpace( block, entrySize )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDependencyListEntry	proc	near
	uses	ax, bx, cx, dx, es, di
	.enter
	;
	; Set up some registers we're going to need in a few places.
	;
	segmov	es, ds, ax		; es:di <- ptr to the base of the block

	mov	ax, si			; Save pointer to place to insert
	lds	si, ss:[bp].CP_cellParams
	mov	bx, ds:[si].CFP_file	; bx <- file handle
	mov	si, ax			; Restore pointer to place to insert
	
	;
	; Check for the case of no dependencies at all. If there are none then
	; we are creating the first block in this dependency list.
	;
	tst	si			; Check for has blocks
	jnz	hasBlock		; Branch if it has a block
	
	;
	; There are no blocks. We need to insert a whole new one.
	;
	call	InsertDepListBlock	; Insert an empty block
	jmp	addItem			; Branch to add the item

hasBlock:
	;
	; First set up some pointers and get the file handle and chunk size.
	;
	ChunkSizePtr	es, di, cx	; cx <- old size of the block
	
	;
	; Check to make sure that the chunk isn't too large.
	;
	cmp	cx, DEPENDENCY_BLOCK_MAX_SIZE
	jb	addItem
	
	;
	; This block has grown too large, we need to split it
	;
	call	SplitDepListBlock	; Split the dependency list block
	
addItem:
	;
	; Unlock the entry.
	;
	; es:di	= Pointer to the chunk
	; es:si	= Pointer to the place to insert
	; ss:bp	= Frame ptr
	; bx	= File handle
	;
	sub	si, di			; si <- offset to insert at

	call	DBUnlock		; Release the block
	
	;
	; bx = File handle
	; si = Place to insert
	; ss:bp.DP_dep = the dbase item reference.
	;
	mov	ax, ss:[bp].DP_dep.segment
	mov	di, ss:[bp].DP_dep.offset
	mov	dx, si			; dx <- position to insert at
	mov	cx, size Dependency	; cx <- # of bytes to insert
	call	DBInsertAt		; Make the block larger
	
	;
	; Now that the block has been resized we need to lock it down and get
	; a pointer that we can return to the caller.
	;
	; bx = File handle
	; ax = Group
	; di = Item
	; dx = Position we inserted at
	;
	call	DBLock			; *es:di <- ptr to the item

	segmov	ds, es, si		; ds:si <- ptr to the item
	mov	si, ds:[di]
	add	si, dx			; ds:si <- ptr to the entry
	.leave
	ret
AddDependencyListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertDepListBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a dependency list block.

CALLED BY:	AddDependencyListEntry
PASS:		bx	= File handle
		ss:bp	= DependencyParameters
RETURN:		es:si	= Pointer to the first entry in the block
		es:di	= Pointer to the base of the block
		(The block is locked, obviously)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertDepListBlock	proc	near
	uses	ax, cx
	.enter
	;
	; Lock the previous entry down.
	;
	mov	ax, ss:[bp].DP_prev.segment	; ax <- group
	mov	di, ss:[bp].DP_prev.offset	; di <- item
	
	call	DBLock				; *es:di <- ptr to data
	mov	si, di				; *es:si <- ptr to data
	
	;
	; Allocate a new item to be the next list block.
	;
	mov	cx, size DependencyListHeader	; cx <- size for new block
	mov	ax, DB_UNGROUPED		; No group needed thanks
	call	DBAlloc				; ax <- group, di <- item
	
	;
	; Save the new block as the next pointer of the previous block and
	; move the next pointer of the previous block to be the next pointer
	; of the current block.
	;
	mov	si, es:[si]			; es:si <- ptr to prev entry
	push	es:[si].segment, es:[si].offset	; Save the "next" link
	
	mov	es:[si].segment, ax		; Save new block as "next"
	mov	es:[si].offset, di
	
	call	DBDirty				; Dirty the previous item
	call	DBUnlock			; Release the previous item
	
	;
	; Lock down the new block.
	;
	mov	ss:[bp].DP_dep.segment, ax	; Save new blocks group/item
	mov	ss:[bp].DP_dep.offset, di

	call	DBLock				; *es:di <- new block
	mov	di, es:[di]			; es:di <- new block
	
	pop	es:[di].segment, es:[di].offset	; Save the "next" pointer
	
	call	DBDirty				; Dirty the item

	mov	si, di				; es:si <- ptr to place to insert
	add	si, size DependencyListHeader
	.leave
	ret
InsertDepListBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitDepListBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split a dependency list block at a given point.

CALLED BY:	AddDependencyListEntry
PASS:		bx	= File handle
		es:di	= Pointer to the base of the block
		es:si	= Pointer to the place to split
		ss:bp	= DependencyParameters
RETURN:		es:di	= Pointer to the base of the block to insert into
		es:si	= Pointer to the place to insert
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Divide the block into two parts.
	Set the pointer into the correct block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplitDepListBlock	proc	near
	uses	ax, cx, ds
	.enter
	sub	si, di			; si <- offset to insert at
	push	si			; Save offset to insert at

	mov	ax, DB_UNGROUPED	; Ungrouped please
	ChunkSizePtr	es, di, cx	; cx <- Size of current block
	push	cx			; Save old size
	;
	; Compute the size for the new block:
	;	(Size of entries / 2) + Header size
	;
	sub	cx, size DependencyListHeader
	shr	cx, 1
	add	cx, size DependencyListHeader
	
	call	DBAlloc			; ax <- group, di <- item
	
	segmov	ds, es			; ds:si <- ptr to current block
	mov	si, ss:[bp].DP_chunk
	mov	si, ds:[si]
	
	;
	; bx	= File handle
	; ax	= Group
	; di	= Item
	; cx	= Size of new block
	; ds:si	= Pointer to the old block
	; On Stack:
	;	Size of the old block
	;	Offset to insert at in old block
	;
	pushdw	axdi			; Save group, item

	call	DBLock			; *es:di <- ptr to new block
	mov	di, es:[di]		; es:di <- ptr to new block
	
	movdw	es:[di].DLH_next, ds:[si].DLH_next, ax
	
	;
	; Set the "next" link for the current block to the new item.
	;
	popdw	ds:[si].DLH_next
	
	;
	; OK... The "next" links are all set up and we have:
	; ds:si	= Pointer to the current block
	; es:di	= Pointer to the new block
	; cx	= Size for new block
	; on stack:
	;	Size of the old block
	;	Offset to insert at in old block
	;
	sub	cx, size DependencyListHeader
	pop	ax

	push	di			; Save ptr to base of new block
	sub	ax, cx
	add	si, ax			; ds:si <- ptr to bytes to copy
	add	di, size DependencyListHeader
	
	rep	movsb			; Copy the dependencies
	pop	di			; Restore ptr to base of new block
	
	;
	; Now... We've copied the dependencies, we've set the links up.
	; We need to:
	;	ReAlloc the original block smaller
	;	Dirty both blocks
	;	Figure which block contains the position to insert at
	;	Unlock the other block
	;	Set the pointer correctly
	;

	;
	; Mark dirty and unlock the NEW block
	;
	call	DBDirty	
	call	DBUnlock

	;
	; Mark dirty and unlock the OLD block. 
	;
	segmov	es, ds			; es <- segment address of old block
	call	DBDirty			; Dirty the block before unlocking
	call	DBUnlock		; Unlock it

	mov_tr	cx, ax			; cx <- new size
	mov	ax, ss:[bp].DP_dep.segment ; ax <- group
	mov	di, ss:[bp].DP_dep.offset  ; di <- item
	call	DBReAlloc		; ReAlloc the item smaller
					;   into es
	
	;
	; Lock the old block again.  
	;
	mov	ax, ss:[bp].DP_dep.segment ; ax <- group
	mov	di, ss:[bp].DP_dep.offset  ; di <- item
	call	DBLock			; *es:di <- ptr to old block
	mov	di, es:[di]		; es:di <- ptr to old block
	
	pop	si			; Restore offset into the block
	
	cmp	si, cx			; Check for offset too large
	jb	quit			; Branch if offset is OK
	
	;
	; The offset is into the second block. We need to release the first one
	; and lock the second one. We also need to update the stack frame.
	; Luckily we have a routine to do this :-)
	;
	push	si			; Save offset
	segmov	ds, es			; ds:di <- ptr to base of old block
	call	LockNextDependencyBlock	; ds:si <- ptr to new block

	segmov	es, ds			; es:di <- ptr to new block
	mov	di, si
	pop	si			; Restore offset

	sub	si, cx			; Make into offset into 2nd block
	add	si, size DependencyListHeader

quit:
	add	si, di			; Make offset into a pointer
	.leave
	ret
SplitDepListBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteDependencyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a dependency list item

CALLED BY:	RemoveSingleDependency
PASS:		ds:si	= Pointer to place to delete
		ds:di	= Pointer to the start of the dependency list block
		ss:bp.DP_dep = DBase item containing the dependency list block
RETURN:		zero flag set if there are no more entries in the dependency
			list.
		Dependency list block pointed at by ds unlocked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (blockSize - entrySize == 0) then
	    Unlink( block )
	    Free( block )
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteDependencyEntry	proc	near
	uses	ax, bx, cx, dx, di, si, es
	.enter
	;
	; For DBDeleteAt we need:
	;	bx	= File handle
	;	ax	= Group
	;	di	= Item
	;	dx	= Offset to delete at
	;	cx	= # of bytes to delete
	;
	mov	dx, si			; dx <- offset to delete at
	sub	dx, di

	segmov	es, ds, si		; es:di <- ptr to block
	
	lds	si, ss:[bp].CP_cellParams
	mov	bx, ds:[si].CFP_file	; bx <- file handle

	;
	; Check for removing this block entirely
	;
	ChunkSizePtr	es, di, cx	; cx <- old size of the block
	sub	cx, size Dependency + size DependencyListHeader
	tst	cx			; Check for nuking the block
	jnz	unlockAndDelete		; Branch if we're not

	;
	; We are nuking the entire block.
	;
	push	es:[di].segment, es:[di].offset
	
	call	DBUnlock		; Unlock the item
	mov	ax, ss:[bp].DP_dep.segment
	mov	di, ss:[bp].DP_dep.offset
	call	DBFree			; Free the entry
	
	mov	ax, ss:[bp].DP_prev.segment
	mov	di, ss:[bp].DP_prev.offset
	call	DBLock			; *es:di <- previous entry
	mov	di, es:[di]		; es:di <- previous entry
	
	;
	; Restore the link from the nuked block into the current block.
	;
	pop	es:[di].segment, es:[di].offset
	
	call	DBDirty			; Dirty the item
	
	mov	ax, es:[di].segment	; ax == 0 if we've removed the tail block
					;    in the chain

	call	DBUnlock		; Release the block
	
	;
	; Now we check for an empty list. We do this by checking the following:
	;	group/item of block we just nuked are zero (ax == 0)
	;	previous block is the cell
	;
	tst	ax			; Check for removed last block
	jnz	quitNotEmpty		; Branch if we have not
	
	tst	ss:[bp].DP_prevIsCell	; Check for nuked all references
	jz	quitNotEmpty		; Branch if we haven't

	clr	ax			; Set the zero flag (empty list)
	jmp	quit			; Branch to quit

unlockAndDelete:
	call	DBUnlock		; Release the block
	
	;
	; bx = File handle
	; dx = Offset to delete at
	;
	mov	cx, size Dependency	; cx <- # of bytes to nuke
	mov	ax, ss:[bp].DP_dep.segment
	mov	di, ss:[bp].DP_dep.offset
	call	DBDeleteAt		; Resize the block smaller

quitNotEmpty:
	or	ax, -1			; Clear the zero flag (not an empty list)
quit:
	.leave
	ret
DeleteDependencyEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserForeachReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process each reference in an expression.

CALLED BY:	Global
PASS:		es:di	= Pointer to the expression
		cx:dx	= Callback routine
			  (Callback *must* be vfptr for XIP)
		ss:bp	= Arguments to the callback
		ds:si	= More arguments to the callback
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Callback should be defined as far:
		PASS:	es:di	= Pointer to the cell reference
			ss:bp	= Passed parameters
			ds:si	= More passed parameters
			al	= Type of reference:
					PARSER_TOKEN_CELL
					PARSER_TOKEN_NAME
		RETURN:	nothing
		DESTROYED: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserForeachReferenceOLD	proc	far
	FALL_THRU ParserForeachReference
ParserForeachReferenceOLD	endp

ParserForeachReference	proc	far
	uses	ax, bx, di
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	push	cx			; Save the segment of the callback
	push	dx			; Save the offset of the callback
	mov	bx, sp			; ss:bx = ptr to the callback

tokenLoop:
	;
	; es:di	= Pointer to next token
	; ds:si	= Passed ds:si
	; ds	= Segment address of parsers dgroup
	; On stack:
	;	Callback (far ptr)
	;
	mov	al, {byte} es:[di]	; ax <- type of the token
	inc	di			; es:di <- ptr past the token

	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	je	quit			; Branch if no more expression

	cmp	al, PARSER_TOKEN_CELL	; Check for a cell reference
	je	callCallback		; Branch if not a cell reference

	cmp	al, PARSER_TOKEN_NAME	; Check for a name reference
	jne	nextToken		; Branch if not a name reference

callCallback:

if FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].offset
	mov	bx, ss:[bx].segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	{dword} ss:[bx]		; Call the callback routine
endif

nextToken:
	call	ParserPointToNextToken
	jmp	tokenLoop		; Loop to process it

quit:
	pop	dx			; Restore passed dx
	pop	cx			; Restore passed cx
	.leave
	ret
ParserForeachReference	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserPointToNextToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point at the next token in the token stream

CALLED BY:	ParserForeachReference, ParserForeachToken

PASS:		al - ParserTokenType
		es:di - pointing at the PT_data part of a ParserToken

RETURN:		es:di - updated

DESTROYED:	ah (cleared), cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserPointToNextToken	proc near
		uses	ds, si
		.enter

EC <		cmp	al, ParserTokenType			>
EC <		ERROR_A EVAL_ILLEGAL_PARSER_TOKEN		>

		cbw			; clr	ah
	;
	; If the current token is PARSER_TOKEN_STRING, then add the
	; string size to DI
	;
		cmp	al, PARSER_TOKEN_STRING
		jne	afterAdd
if DBCS_PCGEOS
		mov	si, es:[di].PTSD_length
		shl	si, 1			; si <- string size
		add	di, si			; di <- ptr after string
else
		add	di, es:[di].PTSD_length
endif
afterAdd:

	;
	; Add in the size of the token to get to the next one.
	;
NOFXIP <	segmov	ds, dgroup, si	; ds <- dgroup			>
FXIP <		mov	si, bx		; si = value of bx		>
FXIP <		mov	bx, handle dgroup				>
FXIP <		call    MemDerefDS	; ds = dgroup			>
FXIP <		mov	bx, si		; restore bx			>
		mov	si, ax		; si <- index into list of token
		mov	cl, ds:parserTokenSizeTable[si]
		clr	ch
	
		add	di, cx			; Skip to next token

		.leave
		ret
ParserPointToNextToken	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserForeachToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process each token in an expression.

CALLED BY:	Global
PASS:		es:di	= Pointer to the expression
		cx:dx	= Callback routine
			  (Callback *must* be vfptr for XIP)
		ss:bp	= Arguments to the callback
		ds:si	= More arguments to the callback
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Callback should be defined as far:
		PASS:	es:di	= Pointer to the cell reference
			ss:bp	= Passed parameters
			ds:si	= More passed parameters
			al	= Type of reference:
					PARSER_TOKEN_CELL
					PARSER_TOKEN_NAME
		RETURN:	nothing
		DESTROYED: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserForeachTokenOLD	proc	far
	FALL_THRU	ParserForeachToken
ParserForeachTokenOLD	endp

ParserForeachToken	proc	far
	uses	ax, bx, di
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	push	cx			; Save the segment of the callback
	push	dx			; Save the offset of the callback
	mov	bx, sp			; ss:bx = ptr to the callback

tokenLoop:
	;
	; es:di	= Pointer to next token
	; ds:si	= Passed ds:si
	; ds	= Segment address of parsers dgroup
	; On stack:
	;	Callback (far ptr)
	;
	mov	al, {byte} es:[di]	; ax <- type of the token
	inc	di			; es:di <- ptr past the token

	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	je	quit			; Branch if no more expression

callCallback::
if FULL_EXECUTE_IN_PLACE
	push	bx, ax
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	mov	ax, ss:[bx].offset
	mov	bx, ss:[bx].segment
	call	ProcCallFixedOrMovable
	pop	bx, ax
else
	call	{dword} ss:[bx]		; Call the callback routine
endif

	call	ParserPointToNextToken
	
	jmp	tokenLoop		; Loop to process it

quit:
	pop	dx			; Restore passed dx
	pop	cx			; Restore passed cx
	.leave
	ret
ParserForeachToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserRemoveDependenciesInRange	(COMMENTED OUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove from the dependency list of a cell any references
		which fall in a given range.

CALLED BY:	Global
PASS:		ss:bp	= Pointer to the rectangle of cells to nuke from the
			  dependency list
		ax	= Row
		cx	= Column
		ds:si	= CellFunctionParameters
RETURN:		carry set if the cell is devoid of dependencies
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
ParserRemoveDependenciesInRange	proc	far
	uses	ax, bx, cx, dx, bp, di, si, ds
	.enter
	mov	bx, bp				; ss:bx <- rectangle to check

	sub	sp, size DependencyParameters	; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	
	;
	; Fill in only the stuff we need.
	;
	mov	ss:[bp].CP_cellParams.segment, ds
	mov	ss:[bp].CP_cellParams.offset, si
	
	call	LockFirstDepListBlock		; ds:si <- dependency list
						; ds:di <- dependency list
						; si == 0 if no dependencies
	tst	si				; Check for no dependencies
	jz	noMoreDependencies		; Branch if none

findInThisBlock:	
	;
	; Check each entry to see if it is in the passed range.
	;
	ChunkSizePtr	ds, si, cx		; cx <- size of this part
	sub	cx, size DependencyListHeader	; cx <- size w/o header
	
	mov	di, si				; Save ptr to block start
	add	si, size DependencyListHeader	; ds:si <- first entry
	
	;
	; cx	= # of bytes in this part of the list
	; ds:si	= Pointer to first entry in this part
	; ds:di	= Pointer to the start of this block
	; ss:bx	= Pointer to the rectangle
	;
EC <	tst	cx			>
EC <	ERROR_Z	-1			>

findLoop:
	mov	ax, ds:[si].D_row		; ax <- row
	mov	dl, ds:[si].D_column		; dl <- column
	call	IsEntryInRange			; Check for entry in range
	jnc	nextEntry			; Branch if it's not
	
	;
	; The entry falls inside the range. We want to delete it.
	;
	call	DeleteDependencyEntry		; Remove the dependency
	jz	noMoreDependencies		; Branch if no more here
	
	;
	; Well... We deleted an entry. This means that we have one less entry
	; to process, but we are already pointing at it...
	;
	jmp	nextEntryKeepPointer

nextEntry:
	add	si, size Dependency		; Move to next entry

nextEntryKeepPointer:
	sub	cx, size Dependency		; This many fewer bytes
	jnz	findLoop			; Loop to process it
	
	;
	; There were no more entries in this block, check the next one.
	;
	call	LockNextDependencyBlock		; Lock next block
	jc	findInThisBlock			; Loop to check it out
	
	;
	; There are no more dependencies at all.
	;
	clc					; Signal: there are dependencies

quit:
	lahf					; Save "no dependencies" flag
	add	sp, size DependencyParameters	; Restore stack frame
	sahf					; Rstr "no dependencies" flag
	.leave
	ret

noMoreDependencies:
	stc					; Signal: no more dependencies
	jmp	quit
ParserRemoveDependenciesInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsEntryInRange		(COMMENTED OUT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if an entry falls inside a rectangle.

CALLED BY:	ParserRemoveDependenciesInRange
PASS:		ax	= Row
		dl	= Column
		ss:bx	= Pointer to rectangle
RETURN:		carry set if entry falls in the rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsEntryInRange	proc	near
	cmp	ax, ss:[bx].R_top		; Check for above top
	jb	outside
	cmp	ax, ss:[bx].R_bottom		; Check for beyond bottom
	ja	outside
	
	cmp	dl, {byte} ss:[bx].R_left	; Check for below top
	jb	outside
	cmp	dl, {byte} ss:[bx].R_right	; Check for beyond right
	ja	outside
	
	stc					; Signal: Cell is in range
	jmp	quit

outside:
	clc					; Signal: not in range
quit:
	ret
IsEntryInRange	endp
endif

EvalCode	ends
