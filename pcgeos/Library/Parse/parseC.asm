COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Parse
FILE:		parseC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	2/4/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: parseC.asm,v 1.1 97/04/05 01:27:28 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Code	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserGetNumberOfFunctions

C DECLARATION:	extern word
			_far _pascal ParserGetNumberOfFunctions(
						FunctionType funcType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	2/5/92		Initial version
	
------------------------------------------------------------------------------@
PARSERGETNUMBEROFFUNCTIONS proc	far
	C_GetOneWordArg	ax, cx, dx		;ax <- FunctionType

	call	ParserGetNumberOfFunctions
	mov	ax, cx				;ax <- number of functions.

	ret

PARSERGETNUMBEROFFUNCTIONS endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserGetFunctionMoniker

C DECLARATION:	extern int
			_far _pascal ParserGetFunctionMoniker(FunctionID funcID,
						char *textPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	2/4/92		Initial version
	
------------------------------------------------------------------------------@
PARSERGETFUNCTIONMONIKER proc	far	funcID:word, funcType:word, textPtr:fptr
			 uses	es, di
	.enter

	mov	cx, funcID
	mov	ax, funcType
	les	di, textPtr
	call	ParserGetFunctionMoniker
	mov	ax, cx				;ax <- # of chars in string

	.leave
	ret

PARSERGETFUNCTIONMONIKER endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserGetFunctionArgs

C DECLARATION:	extern int
			_far _pascal ParserGetFunctionArgs(FunctionID funcID,
						FunctionType funcType,
						char *textPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version
	
------------------------------------------------------------------------------@
PARSERGETFUNCTIONARGS proc	far	funcID:word, funcType:word, textPtr:fptr
			 uses	es, di
	.enter

	mov	cx, funcID
	mov	ax, funcType
	les	di, textPtr
	call	ParserGetFunctionArgs
	mov	ax, cx				;ax <- # of chars in string

	.leave
	ret

PARSERGETFUNCTIONARGS endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserGetFunctionDescription

C DECLARATION:	extern int
			_far _pascal ParserGetFunctionDescription(
						FunctionID funcID,
						FunctionType funcType,
						char *textPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/26/92		Initial version
	
------------------------------------------------------------------------------@
PARSERGETFUNCTIONDESCRIPTION proc far	funcID:word, funcType:word, textPtr:fptr
			 uses	es, di
	.enter

	mov	cx, funcID
	mov	ax, funcType
	les	di, textPtr
	call	ParserGetFunctionDescription
	mov	ax, cx				;ax <- # of chars in string

	.leave
	ret

PARSERGETFUNCTIONDESCRIPTION endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserFormatColumnReference

C DECLARATION:	extern int
			_far _pascal ParserFormatColumnReference(word colNum,
							   char *buffer, 
							   word bufferSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	anna	3/10/92		Initial version
	
------------------------------------------------------------------------------@
PARSERFORMATCOLUMNREFERENCE proc	far	colNum:word, buffer:fptr,
		      			bufferSize:word
			 uses	es, di
	.enter

	mov	ax, colNum
	les	di, buffer
	mov	cx, bufferSize
	call	ParserFormatColumnReference

	.leave
	ret

PARSERFORMATCOLUMNREFERENCE endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserParseString
		This function is the conduit between C and the assembly
		version of ParserParseString.

		The only really tricky thing going on here is that the
		callback function passed in the parserParams structure is
		replaced with a pointer to PLC_Callback, which loads
		up a callback structure that C can handle.

		This function returns 0 if no error occurred, non-zero
		otherwise.

C DECLARATION:	extern int
			_far _pascal ParserParseString(char *textBuffer,
					       byte *tokenBuffer,
					       CParserStruct *parserParams,
					       CParserReturnStruct *retval);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/7/92		Initial version
	
------------------------------------------------------------------------------@
PARSERPARSESTRING proc	far	textBuffer:fptr, tokenBuffer:fptr,
				parserParams:fptr, retval:fptr
	 uses	es, di, ds, si
	.enter
EC <	mov	ax, ss							>
EC <	cmp	ax, parserParams.high					>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>

	; Fill the asm callback pointer with the stub's callback handler.
	mov	ax, ds			; ax <- the caller's ds
	lds	si, parserParams	; ds:si <- CParserParams

	; Load up the caller's DS for when we call the callback.
	mov	ds:[si].C_callbackStruct.C_returnDS, ax

	mov	ds:[si].C_parameters.PP_common.CP_callback.high, SEGMENT_CS
	mov	ax, offset PLC_Callback
	mov	ds:[si].C_parameters.PP_common.CP_callback.low, ax

	; Load up regs and call ParserParseString.
	lds	si, textBuffer
	mov	es, tokenBuffer.high
	mov	di, tokenBuffer.low
	push	bp
	mov	bp, parserParams.low
	call	ParserParseString
	pop	bp

	; All right then, the string has been parsed.  Error
	; values might need to be passed back now.
	mov	ds, retval.high
	mov	si, retval.low
	mov	ds:[si].PRS_errorCode, al
	mov	ds:[si].PRS_textOffsetStart, cx
	mov	ds:[si].PRS_textOffsetEnd, dx
	mov	ds:[si].PRS_lastTokenPtr.high, es
	mov	ds:[si].PRS_lastTokenPtr.low, di

	mov	ax, 0		; assume no error
	jnc	noError		; Jump if no error occurred
	mov	ax, -1		; signal an error occoured

noError:
	.leave
	ret

PARSERPARSESTRING endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserFormatExpression
		This function is the conduit between C and the assembly
		version of ParserFormatExpression.

		The only really tricky thing going on here is that the
		callback function passed in the formatParams structure is
		replaced with a pointer to PLCF_Callback, which loads
		up a callback structure that C can handle.

		It returns the number of characters in the new string,
		by the way.

C DECLARATION:	extern int
			_far _pascal ParserFormatExpression(byte *tokenBuffer,
					      char *textBuffer,
					      CFormatParameters *formatParams);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/7/92		Initial version
	
------------------------------------------------------------------------------@
PARSERFORMATEXPRESSION proc	far	tokenBuffer:fptr, textBuffer:fptr,
				formatParams:fptr
	 uses	es, di, ds, si
	.enter
EC <	mov	ax, ss							>
EC <	cmp	ax, formatParams.high					>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>

	; Fill the asm callback pointer with the stub's callback handler.
	mov	ax, ds			; ax <- the caller's ds
	mov	ds, formatParams.high	; ds:si <- CFormatParams
	mov	si, formatParams.low

	; Load up the caller's DS for when we call the callback.
	mov	ds:[si].CF_callbackStruct.C_returnDS, ax

	mov	ax, cs
	mov	ds:[si].CF_parameters.FP_common.CP_callback.high, ax
	mov	ax, offset PLCF_Callback
	mov	ds:[si].CF_parameters.FP_common.CP_callback.low, ax

	; Load up regs and call ParserFormatExpression.
	mov	ds, tokenBuffer.high
	mov	si, tokenBuffer.low
	mov	es, textBuffer.high
	mov	di, textBuffer.low
	push	bp
	mov	bp, formatParams.low
	call	ParserFormatExpression
	pop	bp

	; All right then, the expression has been formatted.
	; Pass back the number of characters in the new text string.
	mov	ax, cx		; ax <- number of chars
	.leave
	ret

PARSERFORMATEXPRESSION endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ParserEvalExpression
		This function is the conduit between C and the assembly
		version of ParserEvalExpression.

		The only really tricky thing going on here is that the
		callback function passed in the evalParams structure is
		replaced with a pointer to PLCE_Callback, which loads
		up a callback structure that C can handle.

		It returns 0 if the evaluation was a success, or the
		PSEE_error otherwise.

C DECLARATION:	extern int
			_far _pascal ParserEvalExpression(byte *tokenBuffer,
				      byte *scratchBuffer, 
				      byte *resultsBuffer,
				      word bufSize,
				      CEvalStruct *evalParams);
		NOTE!  the scratchBuffer and the resultsBuffer must be the 
		       same size!  This size is passed in bufSize.
		        
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/7/92		Initial version
	
------------------------------------------------------------------------------@
PARSEREVALEXPRESSION proc	far	tokenBuffer:fptr, 
				scratchBuffer:fptr,
				resultsBuffer:fptr,
				bufSize:word,
		 		evalParams:fptr
	 uses	es, di, ds, si
	.enter
EC <	mov	ax, ss							>
EC <	cmp	ax, evalParams.high					>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>

	; Fill the asm callback pointer with the stub's callback handler.
	mov	ax, ds			; ax <- the caller's ds
	mov	ds, evalParams.high	; ds:si <- CEvalParams
	mov	si, evalParams.low

	; Load up the caller's DS for when we call the callback.
	mov	ds:[si].CE_callbackStruct.C_returnDS, ax

	mov	ax, SEGMENT_CS
	mov	ds:[si].CE_parameters.EP_common.CP_callback.high, ax
	mov	ax, offset PLCE_Callback
	mov	ds:[si].CE_parameters.EP_common.CP_callback.low, ax

	; Load up regs and call ParserEvalExpression.
	mov	ds, tokenBuffer.high
	mov	si, tokenBuffer.low
	mov	es, scratchBuffer.high
	mov	di, scratchBuffer.low
	mov	cx, bufSize

	push	bp
	mov	bp, evalParams.low
	call	ParserEvalExpression
	pop	bp

	; The expression has been evaluated!
	; Any error value is already in al
	; If there was a serious error, don't bother moving the results.
	jc	done
	
	clr	ax		; Signal: no error!

	; Move the results to the results buffer.
	segmov	ds, es, si	; ds:si <- source
	mov	si, bx
	mov	es, resultsBuffer.high	; es:di <- destination
	mov	di, resultsBuffer.low

	mov	cx, bufSize	; cx <- number of bytes to copy
	shr	cx, 1

	rep	movsw		; Copy like a fiend.
	jnc	done		; Do we have one more byte to copy?
	movsb			; Yes.  Do it and fall through.	
done:
	.leave
	ret

PARSEREVALEXPRESSION endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLC_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a parse library callback and formats it
		for a C callback routine.

CALLED BY:	parse library callback routines.

PASS:		al	= CallbackType
		ss:bp   = Pointer to C{Parser,Format}Parameters on stack
		other arguments depending on the type
RETURN:		depends on the argument type
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92		Initial version
	jeremy	4/14/92		Generalized the thing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PLC_Callback	proc	far
	.enter

	; All of the callback structures need the callback type and
	; their own address.  Set 'em here.
	mov	ss:[bp].C_callbackStruct.C_callbackType, al 

	; Since all parameter pointers are located in the same place,
	; we'll just use CP_params to load the pointer.
	mov	ax, ss
	mov	ss:[bp].C_callbackStruct.C_params.high, ax
	mov	ss:[bp].C_callbackStruct.C_params.low, bp

	push	si			; Save whatever is passed in si
	clr	ah
	mov	al, ss:[bp].C_callbackStruct.C_callbackType
	shl	ax, 1			; ax <- index into table of words
	mov	si, ax			; si <- index into a table of words
	mov	ax, cs:callbackHandlers[si]
	pop	si			; Restore whatever was passed in si
	call	ax			; Call the handler for the callback

	.leave
	ret
PLC_Callback	endp

;
; One handler for each of the callback types. All handlers are prefixed by
; the letters "CPC" to show that they are C Parser callback handlers.
;
callbackHandlers	\
	word	offset cs:CPC_FunctionToToken,	; CT_FUNCTION_TO_TOKEN
		offset cs:CPC_NameToToken,	; CT_NAME_TO_TOKEN
		offset cs:CPC_CheckNameExists,	; CT_CHECK_NAME_EXISTS
		offset cs:CPC_CheckNameSpace,	; CT_CHECK_NAME_SPACE
		offset cs:CPC_EvalFunction,	; CT_EVAL_FUNCTION
		offset cs:CPC_LockName,		; CT_LOCK_NAME
		offset cs:CPC_Unlock,		; CT_UNLOCK
		offset cs:CPC_FormatFunction,	; CT_FORMAT_FUNCTION
		offset cs:CPC_FormatName,	; CT_FORMAT_NAME
		offset cs:CPC_CreateCell,	; CT_CREATE_CELL
		offset cs:CPC_EmptyCell,	; CT_EMPTY_CELL
		offset cs:CPC_NameToCell,	; CT_NAME_TO_CELL
		offset cs:CPC_FunctionToCell,	; CT_FUNCTION_TO_CELL
		offset cs:CPC_DerefCell,	; CT_DEREF_CELL
		offset cs:CPC_SpecialFunction	; CT_SPECIAL_FUNCTION



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLCF_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a parse library callback and formats it
		for a C format callback routine.

CALLED BY:	parse library format expression callback routines.

PASS:		al	= CallbackType
		ss:bp   = Pointer to CFormatParameters on stack
		other arguments depending on the type
RETURN:		depends on the argument type
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92		Initial version
	jeremy	4/14/92		Generalized the thing
	jeremy	5/7/92		Specifized the thing again.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PLCF_Callback	proc	far
	.enter

	; All of the callback structures need the callback type and
	; their own address.  Set 'em here.
	mov	ss:[bp].CF_callbackStruct.C_callbackType, al 

	; Since all parameter pointers are located in the same place,
	; we'll just use CF_params to load the pointer.
	mov	ax, ss
	mov	ss:[bp].CF_callbackStruct.C_params.high, ax
	mov	ss:[bp].CF_callbackStruct.C_params.low, bp

	push	si			; Save whatever is passed in si
	clr	ah
	mov	al, ss:[bp].CF_callbackStruct.C_callbackType
	shl	ax, 1			; ax <- index into table of words
	mov	si, ax			; si <- index into a table of words
	mov	ax, cs:callbackHandlers[si]
	pop	si			; Restore whatever was passed in si
	call	ax			; Call the handler for the callback

	.leave
	ret
PLCF_Callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLCE_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a parse library callback and formats it
		for a C eval callback routine.

CALLED BY:	parse library expression evaluator callback routines.

PASS:		al	= CallbackType
		ss:bp   = Pointer to CEvalParameters on stack
		other arguments depending on the type
RETURN:		depends on the argument type
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PLCE_Callback	proc	far
	.enter

	; All of the callback structures need the callback type and
	; their own address.  Set 'em here.
	mov	ss:[bp].CE_callbackStruct.C_callbackType, al 

	; Since all parameter pointers are located in the same place,
	; we'll just use CE_params to load the pointer.
	mov	ax, ss
	mov	ss:[bp].CE_callbackStruct.C_params.high, ax
	mov	ss:[bp].CE_callbackStruct.C_params.low, bp

	push	si			; Save whatever is passed in si
	clr	ah
	mov	al, ss:[bp].CE_callbackStruct.C_callbackType
	shl	ax, 1			; ax <- index into table of words
	mov	si, ax			; si <- index into a table of words
	mov	ax, cs:callbackHandlers[si]
	pop	si			; Restore whatever was passed in si
	call	ax			; Call the handler for the callback

	.leave
	ret
PLCE_Callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DO_PARSER_CALLBACK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the C callback function pointed to by the parser
		callback struct in ss:bp.

CALLED BY:	Parser callback handlers

PASS:		ss:[bp] - CParserStruct

RETURN:		whatever's supposed to be returned by the callback function.

DESTROYED:	ax, bx, cx, dx, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DO_PARSER_CALLBACK	macro
	mov	ax, ss:[bp].C_callbackPtr.offset
	mov	bx, ss:[bp].C_callbackPtr.segment
	mov	ds, ss:[bp].C_callbackStruct.C_returnDS
	call	ProcCallFixedOrMovable
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DO_FORMAT_CALLBACK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the C callback function pointed to by the format
		callback struct in ss:bp.

CALLED BY:	Format callback handlers

PASS:		ss:[bp] - CFormatStruct

RETURN:		whatever's supposed to be returned by the callback function.

DESTROYED:	ax, bx, cx, dx, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DO_FORMAT_CALLBACK	macro
	mov	ax, ss:[bp].CF_callbackPtr.offset
	mov	bx, ss:[bp].CF_callbackPtr.segment
	mov	ds, ss:[bp].CF_callbackStruct.C_returnDS
	call	ProcCallFixedOrMovable
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DO_EVAL_CALLBACK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the C callback function pointed to by the eval
		callback struct in ss:bp.

CALLED BY:	Eval callback handlers

PASS:		ss:[bp] - CEvalStruct

RETURN:		whatever's supposed to be returned by the callback function.

DESTROYED:	ax, bx, cx, dx, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DO_EVAL_CALLBACK	macro
	mov	ax, ss:[bp].CE_callbackPtr.offset
	mov	bx, ss:[bp].CE_callbackPtr.segment
	mov	ds, ss:[bp].CE_callbackStruct.C_returnDS
	call	ProcCallFixedOrMovable
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_FunctionToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to CParserParameters on stack
		ss:[bp].C_callbackUnion.callBackType = callback type.
		ss:[bp].C_callbackUnion.params = ss:bp
		ds:si	= Pointer to the text of the identifier.
		cx	= Length of the text.
RETURN:		carry set if the string is a function
		di	= Function ID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_FunctionToToken	 proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ftt.FTT_text.high, ds
	mov	ss:[bp].C_callbackStruct.C_u.CT_ftt.FTT_text.low, si
	mov	ss:[bp].C_callbackStruct.C_u.CT_ftt.FTT_length, cx

	push	ax, bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	mov	di, ss:[bp].C_callbackStruct.C_u.CT_ftt.FTT_funcID

	; If the name is a function, set the carry flag.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_ftt.FTT_isFunctionName
	sal	al, 1

	; Recover passed regs (these pops don't affect CF, of course).
	pop	ax, bx, cx, dx, es, ds

	.leave
	ret
CPC_FunctionToToken endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_NameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to CParserParameters
		ds:si	= Pointer to the name text
		cx	= Length of the name text
RETURN:		cx	= Name token
		carry set on error
		al	= Error code
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_NameToToken	 proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_text.high, ds
	mov	ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_text.low, si
	mov	ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_length, cx

	push	bx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; Get the name token, if it's there.
	mov	cx, ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_nameID
	; Get an error value, if it's there.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_error

	; Set the carry flag if an error occurred.
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_ntt.NTT_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred

	; Recover passed regs (these pops don't affect the CF, of course).
	pop	bx, dx, es, ds
	
	.leave
	ret
CPC_NameToToken endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_CheckNameExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to the name text
		cx	= Length of the name
RETURN:		carry set if the name does exist
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_CheckNameExists	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_cne.CNE_text.high, ds
	mov	ss:[bp].C_callbackStruct.C_u.CT_cne.CNE_text.low, si
	mov	ss:[bp].C_callbackStruct.C_u.CT_cne.CNE_length, cx

	push	ax, bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; If the name exists, set the carry flag.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_cne.CNE_nameExists
	sal	al, 1			; CF <- set if name exists

	; Recover passed regs (these pops don't affect CF, of course).
	pop	ax, bx, cx, dx, es, ds

	.leave
	ret
CPC_CheckNameExists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_CheckNameSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters
		cx	= # of names we want to allocate
RETURN:		carry set on error
		al	= PSEE_NOT_ENOUGH_NAME_SPACE if error
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_CheckNameSpace	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_cns.CNS_numToAllocate, cx

	push	bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; Set al as the error if one exists.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_cns.CNS_error
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_cns.CNS_errorOccurred;
	sal	ah, 1			; CF <- set if an error occurred.
	jc	done			; jump if an error occurred.

	; If there is enough space, clear the carry flag.
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_cns.CNS_enoughSpace
	not	ah
	sal	ah, 1			; CF <- set if NOT enough space

done:
	; Recover passed regs (these pops don't affect CF, of course).
	pop	bx, cx, dx, es, ds

	.leave
	ret
CPC_CheckNameSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_EvalFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= EvalParameters
		si	= Function ID
		cx	= # of arguments
		es:di	= Operator stack
		es:bx	= Argument stack
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_EvalFunction	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_opStack.high, es
	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_argStack.high, es
	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_opStack.low, di
	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_argStack.low, bx
	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_funcID, si
	mov	ss:[bp].C_callbackStruct.C_u.CT_ef.EF_numArgs, cx

	push	bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; Get an error value, if it's there.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_ef.EF_error

	; Set the carry flag if an error occurred.
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_ef.EF_errorOccurred
	sal	ah, 1			; CF <- set if an error occurred.

	; Recover passed regs (these pops don't affect the CF, of course).
	pop	bx, cx, dx, es, ds

	.leave
	ret
CPC_EvalFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_LockName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserEvalExpression

CALLED BY:	EvalCallback via callbackHandlers
PASS:		ss:bp	= Pointer to the EvalParameters
		cx	= Name token
RETURN:		carry set on error
		al	= error code
		if no error:
		  ds:si	= Pointer to the definition of the name
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_LockName	proc	near
	.enter

	mov	ss:[bp].CE_callbackStruct.C_u.CT_ln.LN_nameToken, cx

	push	bx, cx, dx, es

	; Push address to the CE_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset CE_callbackStruct
	push	ss
	push	ax

	DO_EVAL_CALLBACK

	; Get an error value, if it's there.
	mov	al, ss:[bp].CE_callbackStruct.C_u.CT_ln.LN_error

	; Set the carry flag if an error occurred.
	mov	ah, ss:[bp].CE_callbackStruct.C_u.CT_ln.LN_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred.
	jc	done		; jump if an error occurred.

	; No error ocurred.  Point ds:si to the name definition
	mov	ds, ss:[bp].CE_callbackStruct.C_u.CT_ln.LN_defPtr.high
	mov	si, ss:[bp].CE_callbackStruct.C_u.CT_ln.LN_defPtr.low

done:
	; Recover passed regs (these pops don't affect the CF, of course).
	pop	bx, cx, dx, es

	.leave
	ret
CPC_LockName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_Unlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserEvalExpression

CALLED BY:	EvalCallback via callbackHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds	= Segment address of the block to unlock
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_Unlock	proc	near
	.enter

	mov	ss:[bp].CE_callbackStruct.C_u.CT_ul.UL_dataPtr.high, ds
	mov	ss:[bp].CE_callbackStruct.C_u.CT_ul.UL_dataPtr.low, 0

	push	ax, bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset CE_callbackStruct
	push	ss
	push	ax

	DO_EVAL_CALLBACK

	; Recover passed regs.
	pop	ax, bx, cx, dx, es, ds

	.leave
	ret
CPC_Unlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_FormatFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= FormatParameters
		es:di	= Place to store the text
		dx	= Maximum number of characters to write
		cx	= Function id
RETURN:		es:di	= Pointer passed the inserted text
		dx	= # left after we've written ours
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_FormatFunction	proc	near
	.enter

	mov	ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_resultPtr.high, es
	mov	ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_resultPtr.low, di
	mov	ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_maxChars, dx
	mov	ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_funcID, cx

	push	ax, bx, cx, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset CF_callbackStruct
	push	ss
	push	ax

	DO_FORMAT_CALLBACK

	mov	es, ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_resultPtr.high
	mov	di, ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_resultPtr.low
	mov	dx, ss:[bp].CF_callbackStruct.C_u.CT_ff.FF_numWritten

	; Recover passed regs.
	pop	ax, bx, cx, ds

	.leave
	ret
CPC_FormatFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_FormatName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for FormatString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to FormatParameters
		es:di	= Place to store the text
		cx	= Name token
		dx	= Max # of characters to write
RETURN:		es:di	= Pointer past the inserted text
		dx	= # of characters written
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_FormatName	proc	near
	.enter

	mov	ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_textPtr.high, es
	mov	ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_textPtr.low, di
	mov	ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_maxChars, dx
	mov	ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_nameToken, cx

	push	ax, bx, cx, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset CF_callbackStruct
	push	ss
	push	ax

	DO_FORMAT_CALLBACK

	mov	es, ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_resultPtr.high
	mov	di, ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_resultPtr.low
	mov	dx, ss:[bp].CF_callbackStruct.C_u.CT_fn.FN_numWritten

	; Recover passed regs.
	pop	ax, bx, cx, ds

	.leave
	ret
CPC_FormatName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_CreateCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		dx	= Row of cell to create
		cx	= Column of cell to create
RETURN:		carry set on error
		al	= Error code
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_CreateCell	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_cc.CC_row, dx
	mov	ss:[bp].C_callbackStruct.C_u.CT_cc.CC_column, cx

	push	bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; Get an error value, if it's there.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_cc.CC_error

	; Set the carry flag if an error occurred.
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_cc.CC_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred.

	; Recover passed regs (these pops don't affect the CF, of course).
	pop	bx, cx, dx, es, ds

	.leave
	ret
CPC_CreateCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_EmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		dx	= Row of cell
		cx	= Column of cell
RETURN:		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_EmptyCell	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ec.EC_row, dx
	mov	ss:[bp].C_callbackStruct.C_u.CT_ec.EC_column, cx

	push	bx, cx, dx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	; Get an error value, if it's there.
	mov	al, ss:[bp].C_callbackStruct.C_u.CT_ec.EC_error

	; Set the carry flag if an error occurred.
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_ec.EC_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred.

	; Recover passed regs (these pops don't affect the CF, of course).
	pop	bx, cx, dx, es, ds

	.leave
	ret
CPC_EmptyCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_NameToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		cx	= Name token
RETURN:		dx	= Row of the cell
		cx	= Column of the cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_NameToCell	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ntc.NTC_nameToken, cx

	push	ax, bx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	mov	dx, ss:[bp].C_callbackStruct.C_u.CT_ntc.NTC_row
	mov	cx, ss:[bp].C_callbackStruct.C_u.CT_ntc.NTC_column

	; Recover passed regs.
	pop	ax, bx, es, ds

	.leave
	ret
CPC_NameToCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_FunctionToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= EvalParameters
		cx	= Function ID
RETURN:		dx	= Row (0 means no dependency required)
		cx	= Column
		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_FunctionToCell	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_ftc.FTC_funcID, cx

	push	bx, es, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	mov	dx, ss:[bp].C_callbackStruct.C_u.CT_ftc.FTC_row
	mov	cx, ss:[bp].C_callbackStruct.C_u.CT_ftc.FTC_column

	mov	al, ss:[bp].C_callbackStruct.C_u.CT_ftc.FTC_error
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_ftc.FTC_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred.

	; Recover passed regs.
	pop	bx, es, ds

	.leave
	ret
CPC_FunctionToCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_DerefCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserEvalExpression

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		es:bx	= Pointer to evaluator argument stack
		es:di	= Pointer to operator/function stack
		dx	= Row of the cell
		ch	= DerefFlags
		cl	= Column of the cell
RETURN:		es:bx	= New pointer to evaluator argument stack
		carry set on error
		   al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_DerefCell	proc	near
	.enter

	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_argStack.high, es
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_argStack.low, bx
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_opFnStack.high, es
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_opFnStack.low, di
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_row, dx 
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_column, cl
	mov	ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_derefFlags, ch

	push	cx, dx, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset CE_callbackStruct
	push	ss
	push	ax

	DO_EVAL_CALLBACK

	mov	es, ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_newArgStack.high
	mov	bx, ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_newArgStack.low

	mov	al, ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_error
	mov	ah, ss:[bp].CE_callbackStruct.C_u.CT_dc.DC_errorOccurred
	sal	ah, 1		; CF <- set if an error occurred.

	; Recover passed regs.
	pop	cx, dx, ds

	.leave
	ret
CPC_DerefCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CPC_SpecialFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C callback interface for ParserParseString.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Special function code.
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		    al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CPC_SpecialFunction	proc	near
	.enter

	mov	ss:[bp].C_callbackStruct.C_u.CT_sf.SF_argStack.high, es
	mov	ss:[bp].C_callbackStruct.C_u.CT_sf.SF_argStack.low, bx
	mov	ss:[bp].C_callbackStruct.C_u.CT_sf.SF_opFnStack.high, es
	mov	ss:[bp].C_callbackStruct.C_u.CT_sf.SF_opFnStack.low, di
	mov	ss:[bp].C_callbackStruct.C_u.CT_sf.SF_specialFunction, cx

	push	cx, dx, ds

	; Push address to the C_callbackStruct and call the C handler.
	mov	ax, bp
	add	ax, offset C_callbackStruct
	push	ss
	push	ax

	DO_PARSER_CALLBACK

	mov	es, ss:[bp].C_callbackStruct.C_u.CT_sf.SF_newArgStack.high
	mov	bx, ss:[bp].C_callbackStruct.C_u.CT_sf.SF_newArgStack.low

	mov	al, ss:[bp].C_callbackStruct.C_u.CT_sf.SF_error
	mov	ah, ss:[bp].C_callbackStruct.C_u.CT_sf.SF_errorOccurred
	sal	ah, 1			; CF <- set if an error occurred.

	; Recover passed regs.
	pop	cx, dx, ds

	.leave
	ret
CPC_SpecialFunction	endp

C_Code	ends

	SetDefaultConvention

