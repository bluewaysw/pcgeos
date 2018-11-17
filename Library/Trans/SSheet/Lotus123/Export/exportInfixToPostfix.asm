
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportInfixToPostfix.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
	Code that converts GeoCalc's infix formulas into Lotus's postfix
	formulas.

GOALS:
	Hopefully, stuff will be written in a generic enough manner that
	getting this code to work with formulas other than Lotus' will
	be easy.

TERMINOLOGY:
    OPERATOR:
	An operator, as used in this file, includes all of the GeoCalc
	OperatorTypes and the left parenthesis (PARSER_TOKEN_OPEN_PAREN)
	Since OperatorTypes and ParserTokenTypes are byte entities, we will
	use bytes for storage and distinguish the two by tacking on an ms 1 bit
	for the parenthesis.  We will call the resulting entities OPERATOR
	STACK ENTRIES.

    CURRENT TOKEN:
	The GeoCalc ParserTokenType that has just been gotten from the parser
	data stream.

    CURRENT OPERATOR:
	The operator that was just gotten from the parser data stream.

    OPERATOR STACK:
	This is a block of memory that we keep OPERATOR STACK ENTRIES.
	Operator stack entries are pushed onto and popped off this stack
	as part of the translation effort.

REGISTER USAGE (adhered to as far as possible):
	ds:si - stream of Geocalc parser tokens
	es:di - output stream

REFERENCES:
	Algorithm gotten from Data Structures & Program Design by
	Robert L. Kruse, pg 328-333.
	See also Data Structures in Pascal by Horowitz & Sahni, pg 81.

	$Id: exportInfixToPostfix.asm,v 1.1 97/04/07 11:41:49 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaCalcInfixToLotusPostfix

DESCRIPTION:	Reads from a GeoCalc parser token data stream and writes the
		equivalent Lotus formula out to an output stream.

CALLED BY:	INTERNAL ()

PASS:		ExportStackFrame
		ds:si - stream of Geocalc parser tokens
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	icp = incoming priority
	isp = instack priority

	Algorithm gotten from Data Structures & Program Design by
	Robert L. Kruse, pg 328-333.
	See also Data Structures in Pascal by Horowitz & Sahni, pg 81.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaCalcInfixToLotusPostfix	proc	near	uses	bx, cx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

	;-----------------------------------------------------------------------
	; initialize stack

	call	ExportFormulaInitOperatorStack

	;-----------------------------------------------------------------------
	; evaluate till PARSER_TOKEN_END_OF_EXPRESSION

	push	di			; save output stream pointer

processLoop:
	lodsb				; al <- ParserTokenType, ds:si <- data

	mov	bl, locals.ESF_operatorCount
	push	bx, ax				; save operator count, token
	cmp	al, PARSER_TOKEN_FUNCTION	; is this a function token?
	jne	$10
	clr	locals.ESF_operatorCount	; yes, reset operator count

$10:
	mov	bl, al
	clr	bh
	shl	bx, 1				; bx <- offset into table
	mov	bx, cs:[bx].ParserTokenProcessor ; al <- 0 or END_OF_EXPRESSION
EC<	tst	bx 			>
EC<	ERROR_Z	IMPEX_ASSERTION_FAILED 	>
	call	bx
	jc	overflow
	
	pop	cx, bx				; restore count, token
	cmp	bl, PARSER_TOKEN_FUNCTION	; is it a function token?
	jne	$20
	mov	locals.ESF_operatorCount, cl	; yes, restore operator count

$20:
	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	jne	processLoop
	add	sp, 2				; clear di off stack
done:
EC < 	mov	bx, 1			>
EC <	CheckSize	bx, ax		>
EC <	ERROR_C IMPEX_BUFFER_OVERFLOW   >
	mov	al, LOTUS_FUNCTION_RETURN	; Lotus' end of expression
	stosb	

	.leave
	ret

overflow:
	add	sp, 4				; clear cx, bx from the stack
	pop	di				; restore output stream pointer
	mov	al, LOTUS_FUNCTION_ERR
	stosb
	jmp	done

ExportFormulaCalcInfixToLotusPostfix	endp


ParserTokenProcessor	nptr \
    offset ExportFormulaProcessNumber,		; PARSER_TOKEN_NUMBER
    offset ExportFormulaProcessString,		; PARSER_TOKEN_STRING
    offset ExportFormulaProcessCell,		; PARSER_TOKEN_CELL
    offset ExportFormulaProcessEndOfExpr,	; PARSER_TOKEN_END_OF_EXPRESSION
    offset ExportFormulaProcessLeftParen,	; PARSER_TOKEN_OPEN_PAREN	
    offset ExportFormulaProcessRightParen,	; PARSER_TOKEN_CLOSE_PAREN
    offset ExportFormulaProcessName,		; PARSER_TOKEN_NAME
    offset ExportFormulaProcessFunction,	; PARSER_TOKEN_FUNCTION
    0,		 				; PARSER_TOKEN_CLOSE_FUNCTION
    0,		 				; PARSER_TOKEN_ARG_END
    offset ExportFormulaProcessOperator		; PARSER_TOKEN_OPERATOR


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaInitOperatorStack

DESCRIPTION:	Initialize the fields of the stack frame vars that track
		the operator stack.  (The operator stack is not recycled on
		each invocation of ExportFormulaCalcInfixToLotusPostfix.
		Instead, it is marked for creation in ExportInit, and
		subsequent calls to ExportFormulaCalcInfixToLotusPostfix will
		find that the block handle exists).

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix)

PASS:		ExportStackFrame

RETURN:		ESF_operatorStackHan
		ESF_operatorStackSeg

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaInitOperatorStack	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

	cmp	locals.ESF_operatorStackHan, 0	; already initialized?
	jne	initFields

	mov	ax, OPERATOR_STACK_MAX_ENTRIES
	mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8 or \
		     mask HF_SWAPABLE
	call	MemAlloc
	mov	locals.ESF_operatorStackHan, bx
	mov	locals.ESF_operatorStackSeg, ax

initFields:
	;
	; clear the item stack
	;
	mov	locals.ESF_operatorStackTopToken, -1	; no token
	mov	locals.ESF_curOperator, -1		; no operator
	clr	locals.ESF_operatorStackTopOffset
	clr	locals.ESF_operatorCount

	.leave
	ret
ExportFormulaInitOperatorStack	endp


;*******************************************************************************
;
;	THE TRANSLATION ROUTINES FOLLOW
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessNumber

DESCRIPTION:	Since a number is an operand, we write it out to the
		output stream.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		ds:si - parser token data (GeoCalc fp number)
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if output buffer overflowed
		al    - 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessNumber	proc	near	uses	cx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_NUMBER >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	mov	cx, (FPSIZE_IEEE64+1)
	CheckSize	cx, ax
	jc	exit

	mov	al, LOTUS_FUNCTION_CONSTANT
	stosb

	call	FloatPushNumber			; push number at ds:si
	call	FloatGeos80ToIEEE64		; convert and store at es:di
	add	si, FPSIZE			; update si
	add	di, FPSIZE_IEEE64		; update di (destroys ax)

exit:
	pushf
	clr	al
	popf
	.leave
	ret
ExportFormulaProcessNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessString

DESCRIPTION:	Since a string is an operand, we write it out to the
		output stream.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		ds:si - parser token data (ParserTokenStringData)
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if buffer overflow
		al - 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus expects a null terminated string
	GeoCalc uses a length followed by the string data

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessString	proc	near	uses	cx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_STRING >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	lodsw					; ax <- length of string
	mov	cx, ax				; cx <- length
	add	cx, 2
	CheckSize	cx, ax
	jc	exit
	sub 	cx, 2

	mov	al, LOTUS_FUNCTION_STR_CONST
	stosb
	rep	movsb				; transfer data
	clr	al				; this clears the carry bit
	stosb					; null terminate
	clc		
exit:
	pushf	
	clr	al
	popf
	.leave
	ret
ExportFormulaProcessString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessCell

DESCRIPTION:	Since a cell is an operand, we write it out to the
		output stream.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		ds:si - parser data stream (ParserTokenCellData)
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if buffer overflow
		al - 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	CellRowColumn	record
	    CRC_ABSOLUTE:1		; Set if the reference is absolute
	    CRC_VALUE:15		; The value of the row/column
	CellRowColumn	end

	CellReference	struct
	    CR_row	CellRowColumn <>
	    CR_column	CellRowColumn <>
	CellReference	ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessCell	proc	near 	uses cx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_CELL >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	mov	cx, (CellReference+1)
	CheckSize	cx, ax
	jc	exit

	mov	al, LOTUS_FUNCTION_VARIABLE
	stosb

	call	ProcessCellReference		; carry set if overflow

exit:
	pushf
	clr	al
	popf
	.leave
	ret
ExportFormulaProcessCell	endp


ProcessCellReference	proc	near		uses	cx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near
	
	mov	cx, size CellReference
	CheckSize	cx, ax
	jc	exit

	;
	; need to store column in bytes 0,1 and row in bytes 2,3 (lsb first)
	; ds:si points at the ParserTokenCellData (= CellReference structure)
	;
	mov	ax, ds:[si] + offset CR_column	; get value
	xor	ax, mask CRC_ABSOLUTE
	and	ax, not mask LCR_UNKNOWN
	stosw

	mov	ax, ds:[si] + offset CR_row
	xor	ax, mask CRC_ABSOLUTE
	and	ax, not mask LCR_UNKNOWN
	and	ax, not mask LCR_UNKNOWN
	stosw

	add	si, size CellReference		; update si
exit:
	pushf
	clr	al
	popf
	.leave
	ret
ProcessCellReference	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessEndOfExpr

DESCRIPTION:	The end of the expression has been reached.  We will pop
		off all remaining operators and write them out.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		es:di - output stream

RETURN:		es:di - updated
		al    -  PARSER_TOKEN_END_OF_EXPRESSION
		carry set if output buffer overflow
		
DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessEndOfExpr	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_END_OF_EXPRESSION >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

endExprLoop:
	cmp	locals.ESF_operatorCount, 0
	je	done

	call	ExportFormulaPopOperator	; al <- operator
	call	ExportFormulaPutOperator	; write al to output
	jc	exit
	jmp	short endExprLoop
	
done:
	clc
	mov	al, PARSER_TOKEN_END_OF_EXPRESSION 
exit:
	.leave
	ret
ExportFormulaProcessEndOfExpr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessLeftParen

DESCRIPTION:	

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
;		al - ParserTokenType (PARSER_TOKEN_OPEN_PAREN)
		es:di - output stream

RETURN:		es:di - updated
		carry clear

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessLeftParen	proc	near
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

EC<	cmp	{byte}ds:[si-1], PARSER_TOKEN_OPEN_PAREN >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >	

	mov	al, PARSER_TOKEN_OPEN_PAREN
	call	ExportFormulaPushOperator
	clc

	.leave
	ret
ExportFormulaProcessLeftParen	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessRightParen

DESCRIPTION:	All operators found since the corresponding left parenthesis
		will be output.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		es:di - output stream

RETURN:		es:di - updated
		carry set if output buffer overflow
		al - 0

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessRightParen	proc	near	uses	ds,si
	locals	local	ExportStackFrame
	.enter	inherit near

	call	ExportFormulaPopOperator		; al <- operator

popLoop:
	cmp	al, 80h	or PARSER_TOKEN_OPEN_PAREN	; left paren?
	je	done					; done if so

if 0
	push	ax					; save operator
	call	ExportFormulaGetIncomingPriority	; al <- icp
	mov	ah, al					; save icp

	lds	si, locals.ESF_operatorStackTopAddr	; ds:si <- top of stack
	mov	al, ds:[si-1]				; al <- top operator

	call	ExportFormulaGetInstackPriority		; al <- isp
	cmp	al, ah					; isp >= icp ?
	jb	done					; done if not

	pop	ax					; retrieve operator
endif

	call	ExportFormulaPutOperator
	jc	exit	
	call	ExportFormulaPopOperator
	jmp	short popLoop

done:
	call	ExportFormulaPutOperator
exit:
	pushf
	clr	al
	popf
	.leave
	ret
ExportFormulaProcessRightParen	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessName

DESCRIPTION:	Since a name is an operand, we write it out to the
		output stream.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		ds:si - parser data stream
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if buffer overflow
		al - 0

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus substitutes names with the range of the name
	problem is, we can easily get to the name token but not the range...

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@
nameError byte "#NAME#", 0

ExportFormulaProcessName	proc	near
	locals	local	ExportStackFrame
	ForceRef locals
	uses	cx	
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_NAME >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	lodsw					; ax <- name token
	;
	; retrieve name entry
	;

	mov	cx, 8
	CheckSize	cx, ax
	jc	exit

	;
	; copy name into output stream
	;
	mov	al, LOTUS_FUNCTION_STR_CONST
	stosb
	push	ds, si
	segmov	ds, cs, ax
	mov	si, offset nameError
	mov	cx, 7
	rep	movsb
	pop	ds, si

	;
	; push the error function on the stack
	;
	; 
;	mov	al, LOTUS_FUNCTION_NA
;	stosb

	clc
exit:
	pushf	
	clr	al
	popf

	.leave
	ret
ExportFormulaProcessName	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessFunction

DESCRIPTION:	Since a function is an operand, we write it out to the
		output stream.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		ds:si - parser data stream (ParserTokenFunctionData)
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		carry set if buffer overflow

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus stores functions thus:
	    length of function
	    arguments
	    function token
	    number of arguments
	    return
	
	For us, we will need to process the data stream from the
	functionID till we hit PARSER_TOKEN_CLOSE_FUNCTION.

	We will deal with this recursively.  We basically want to delay the
	output of the function till the end (FILO).

	ProcessFunction(ds:si)
	begin
	    GetToken(t)
	    if (t = operand) then begin
		PutToken(t)
	    end else if (t = function) then begin
		ProcessFunction()	; recursive call
		PutToken(t)		; put function token
	    end
	end

	A major hack is used to deal with translating GeoCalc's AND/OR
	functions into the equivalent Lotus binary operators.  We keep
	track of how many arguments there are to the function, and if
	the function is AND/OR, we stuff that many copies of the Lotus
	function code for AND or OR into the output stream, followed by
	the lotus paren code for readability.

	However, if the argument turns out to be a range, instead of
	translating the range into an expression of the individual cells
	in the range AND'ed or OR'ed together, we return the lotus error
	function.  To do this, we replace the GeoCalc function code, which
	is on the top of the stack, with the code for the GeoCalc error 
	function.  Then we clear the remaining bytes of the function from
	the input stream and let the end-of-function processing take
	care of storing the correct information.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

;
; for each FunctionID, we will have a matching Lotus function
;
; Missing:
;	LOTUS_FUNCTION_ISNA
;	LOTUS_FUNCTION_CELLPOINTER
;	LOTUS_FUNCTION_DSUM
;	LOTUS_FUNCTION_DAVG
;	LOTUS_FUNCTION_DCNT
;	LOTUS_FUNCTION_DMIN
;	LOTUS_FUNCTION_DMAX
;	LOTUS_FUNCTION_DVAR
;	LOTUS_FUNCTION_DSTD
;	LOTUS_FUNCTION_CELL
;	LOTUS_FUNCTION_S
;	LOTUS_FUNCTION_CALL			; Symphony 1.1
;	LOTUS_FUNCTION_AAF_START		; 123/2
;	LOTUS_FUNCTION_AAF_UNKNOWN		; 123/2
;	LOTUS_FUNCTION_AAF_END			; Symphony 1.1
;
; -1 = no equivalent in Lotus
;

;	mov	cx, length LotusFunctionEquivTable	;<- # entries
;	mov	cx, size LotusFunctionEquivTable	;<- # bytes

LotusFunctionEquivTable	byte \
	LOTUS_FUNCTION_ABS,		; FUNCTION_ID_ABS
	LOTUS_FUNCTION_ACOS,		; FUNCTION_ID_ACOS
	-1,				; FUNCTION_ID_ACOSH
	LOTUS_FUNCTION_AND,		; FUNCTION_ID_AND
	LOTUS_FUNCTION_ASIN,		; FUNCTION_ID_ASIN
	-1,				; FUNCTION_ID_ASINH
	LOTUS_FUNCTION_ATAN,		; FUNCTION_ID_ATAN
	LOTUS_FUNCTION_ATAN2,		; FUNCTION_ID_ATAN2
	-1,				; FUNCTION_ID_ATANH
	LOTUS_FUNCTION_AVG,		; FUNCTION_ID_AVG
	LOTUS_FUNCTION_CHR,		; FUNCTION_ID_CHAR
	LOTUS_FUNCTION_CHOOSE,		; FUNCTION_ID_CHOOSE
	LOTUS_FUNCTION_CLEAN,		; FUNCTION_ID_CLEAN
	LOTUS_FUNCTION_ASCII,		; FUNCTION_ID_CODE
	LOTUS_FUNCTION_COLS,		; FUNCTION_ID_COLS
	LOTUS_FUNCTION_COS,		; FUNCTION_ID_COS
	-1,				; FUNCTION_ID_COSH
	LOTUS_FUNCTION_CNT,		; FUNCTION_ID_COUNT
	LOTUS_FUNCTION_CTERM,		; FUNCTION_ID_CTERM
	LOTUS_FUNCTION_DATE,		; FUNCTION_ID_DATE
	LOTUS_FUNCTION_DATEVALUE,	; FUNCTION_ID_DATEVALUE
	LOTUS_FUNCTION_DAY,		; FUNCTION_ID_DAY
	LOTUS_FUNCTION_DDB,		; FUNCTION_ID_DDB
	LOTUS_FUNCTION_ERR,		; FUNCTION_ID_ERR
	LOTUS_FUNCTION_EXACT,		; FUNCTION_ID_EXACT	!!!
	LOTUS_FUNCTION_EXP,		; FUNCTION_ID_EXP
	-1,				; FUNCTION_ID_FACT
	LOTUS_FUNCTION_FALSE,		; FUNCTION_ID_FALSE
	LOTUS_FUNCTION_FIND,		; FUNCTION_ID_FIND
	LOTUS_FUNCTION_FV,		; FUNCTION_ID_FV
	LOTUS_FUNCTION_HLOOKUP,		; FUNCTION_ID_HLOOKUP	!!!
	LOTUS_FUNCTION_HOUR,		; FUNCTION_ID_HOUR
	LOTUS_FUNCTION_IF,		; FUNCTION_ID_IF
	LOTUS_FUNCTION_INDEX,		; FUNCTION_ID_INDEX
	LOTUS_FUNCTION_INT,		; FUNCTION_ID_INT
	LOTUS_FUNCTION_IRR,		; FUNCTION_ID_IRR	!!!
	LOTUS_FUNCTION_ISERR,		; FUNCTION_ID_ISERR
	LOTUS_FUNCTION_ISNUMBER,	; FUNCTION_ID_ISNUMBER
	LOTUS_FUNCTION_ISSTRING,	; FUNCTION_ID_ISSTRING
	LOTUS_FUNCTION_LEFT,		; FUNCTION_ID_LEFT
	LOTUS_FUNCTION_LENGTH,		; FUNCTION_ID_LENGTH
	LOTUS_FUNCTION_LN,		; FUNCTION_ID_LN
	LOTUS_FUNCTION_LOG,		; FUNCTION_ID_LOG
	LOTUS_FUNCTION_LOWER,		; FUNCTION_ID_LOWER
	LOTUS_FUNCTION_MAX,		; FUNCTION_ID_MAX
	LOTUS_FUNCTION_MID,		; FUNCTION_ID_MID
	LOTUS_FUNCTION_MIN,		; FUNCTION_ID_MIN
	LOTUS_FUNCTION_MINUTE,		; FUNCTION_ID_MINUTE
	LOTUS_FUNCTION_MOD,		; FUNCTION_ID_MOD
	LOTUS_FUNCTION_MONTH,		; FUNCTION_ID_MONTH
	LOTUS_FUNCTION_N,		; FUNCTION_ID_N
	LOTUS_FUNCTION_NA,		; FUNCTION_ID_NA
	LOTUS_FUNCTION_TODAY,		; FUNCTION_ID_NOW
	LOTUS_FUNCTION_NPV,		; FUNCTION_ID_NPV
	LOTUS_FUNCTION_OR,		; FUNCTION_ID_OR
	LOTUS_FUNCTION_PI,		; FUNCTION_ID_PI
	LOTUS_FUNCTION_PMT,		; FUNCTION_ID_PMT
	-1,				; FUNCTION_ID_PRODUCT
	LOTUS_FUNCTION_PROPER,		; FUNCTION_ID_PROPER
	LOTUS_FUNCTION_PV,		; FUNCTION_ID_PV
	-1,				; FUNCTION_ID_RANDOM_N
	LOTUS_FUNCTION_RAND,		; FUNCTION_ID_RANDOM
	LOTUS_FUNCTION_RATE,		; FUNCTION_ID_RATE
	LOTUS_FUNCTION_REPEAT,		; FUNCTION_ID_REPEAT
	LOTUS_FUNCTION_REPLACE,		; FUNCTION_ID_REPLACE
	LOTUS_FUNCTION_RIGHT,		; FUNCTION_ID_RIGHT
	LOTUS_FUNCTION_ROUND,		; FUNCTION_ID_ROUND
	LOTUS_FUNCTION_ROWS,		; FUNCTION_ID_ROWS
	LOTUS_FUNCTION_SECOND,		; FUNCTION_ID_SECOND
	LOTUS_FUNCTION_SIN,		; FUNCTION_ID_SIN
	-1,				; FUNCTION_ID_SINH
	LOTUS_FUNCTION_SLN,		; FUNCTION_ID_SLN
	LOTUS_FUNCTION_SQRT,		; FUNCTION_ID_SQRT
	LOTUS_FUNCTION_STD,		; FUNCTION_ID_STD
	-1,				; FUNCTION_ID_STDP
	LOTUS_FUNCTION_STRING,		; FUNCTION_ID_STRING	!!!
	LOTUS_FUNCTION_SUM,		; FUNCTION_ID_SUM
	LOTUS_FUNCTION_SOY,		; FUNCTION_ID_SYD
	LOTUS_FUNCTION_TAN,		; FUNCTION_ID_TAN
	-1,				; FUNCTION_ID_TANH
	LOTUS_FUNCTION_TERM,		; FUNCTION_ID_TERM
	LOTUS_FUNCTION_TIME,		; FUNCTION_ID_TIME
	LOTUS_FUNCTION_TIMEVALUE,	; FUNCTION_ID_TIMEVALUE
	LOTUS_FUNCTION_TODAY,		; FUNCTION_ID_TODAY
	LOTUS_FUNCTION_TRIM,		; FUNCTION_ID_TRIM
	LOTUS_FUNCTION_TRUE,		; FUNCTION_ID_TRUE
	-1,				; FUNCTION_ID_TRUNC
	LOTUS_FUNCTION_UPPER,		; FUNCTION_ID_UPPER
	LOTUS_FUNCTION_VALUE,		; FUNCTION_ID_VALUE
	LOTUS_FUNCTION_VAR,		; FUNCTION_ID_VAR
	-1,				; FUNCTION_ID_VARP
	LOTUS_FUNCTION_VLOOKUP,		; FUNCTION_ID_VLOOKUP
	-1,				; FUNCTION_ID_WEEKDAY
	LOTUS_FUNCTION_YEAR,		; FUNCTION_ID_YEAR
	-1,				; FUNCTION_ID_FILENAME
	-1,				; FUNCTION_ID_PAGE
	-1				; FUNCTION_ID_PAGES

;CheckHack <(length LotusFunctionEquivTable) eq (FUNCTION_ID_PAGES/2)>

NUM_ARGS_REQ		= 1	; number of arguments required
NUM_ARGS_NOT_REQ	= 0	; no need to store number of arguments
; -1 = FUNC_NOT_SUPPORTED (constant not used cos "-1" is visually clearer)

LotusNumArgsRequiredTable	byte \
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ABS
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ACOS
	-1,				; FUNCTION_ID_ACOSH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_AND
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ASIN
	-1,				; FUNCTION_ID_ASINH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ATAN
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ATAN2
	-1,				; FUNCTION_ID_ATANH
	NUM_ARGS_REQ,			; FUNCTION_ID_AVG
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_CHAR
	NUM_ARGS_REQ,			; FUNCTION_ID_CHOOSE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_CLEAN
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_CODE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_COLS
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_COS
	-1,				; FUNCTION_ID_COSH
	NUM_ARGS_REQ,			; FUNCTION_ID_COUNT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_CTERM
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_DATE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_DATEVALUE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_DAY
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_DDB
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ERR
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_EXACT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_EXP
	-1,				; FUNCTION_ID_FACT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_FALSE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_FIND
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_FV
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_HLOOKUP
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_HOUR
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_IF
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_INDEX
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_INT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_IRR
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ISERR
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ISNUMBER
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ISSTRING
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_LEFT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_LENGTH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_LN
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_LOG
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_LOWER
	NUM_ARGS_REQ,			; FUNCTION_ID_MAX
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_MID
	NUM_ARGS_REQ,			; FUNCTION_ID_MIN
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_MINUTE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_MOD
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_MONTH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_N
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_NA
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_NOW
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_NPV
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_OR
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_PI
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_PMT
	-1,				; FUNCTION_ID_PRODUCT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_PROPER
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_PV
	-1,				; FUNCTION_ID_RANDOM_N
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_RANDOM
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_RATE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_REPEAT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_REPLACE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_RIGHT
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ROUND
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_ROWS
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_SECOND
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_SIN
	-1,				; FUNCTION_ID_SINH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_SLN
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_SQRT
	NUM_ARGS_REQ,			; FUNCTION_ID_STD
	-1,				; FUNCTION_ID_STDP
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_STRING
	NUM_ARGS_REQ,			; FUNCTION_ID_SUM
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_SYD
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TAN
	-1,				; FUNCTION_ID_TANH
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TERM
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TIME
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TIMEVALUE
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TODAY
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TRIM
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_TRUE
	-1,				; FUNCTION_ID_TRUNC
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_UPPER
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_VALUE
	NUM_ARGS_REQ,			; FUNCTION_ID_VAR
	-1,				; FUNCTION_ID_VARP
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_VLOOKUP	!!!
	-1,				; FUNCTION_ID_WEEKDAY
	NUM_ARGS_NOT_REQ,		; FUNCTION_ID_YEAR
	-1,				; FUNCTION_ID_FILENAME
	-1,				; FUNCTION_ID_PAGE
	-1				; FUNCTION_ID_PAGES

;CheckHack <(length LotusNumArgsRequiredTable) eq (FUNCTION_ID_PAGES/2)>

ExportFormulaProcessFunction	proc	near	uses	bx,cx,dx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

	;
	; save offset in case we need to back out
	;
	mov	dx, di

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_FUNCTION >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	;
	; use ch = number of operators for this argument
	;     cl = number of arguments for this function
	;
	clr	cx			; init argument count
	lodsw				; ax <- function id
	push	ax			; save function id

processLoop:
	lodsb				; al <- ParserTokenType, ds:si <- data
	cmp	al, PARSER_TOKEN_ARG_END
	jne	checkClose

	call	ProcessFunctionCleanOperatorStack
 	jc	overflow		; on stack: FunctionID
	inc	cl			; up argument count
	clr	ch			; init operator count
	jmp	short processLoop

checkClose:
	cmp	al, PARSER_TOKEN_CLOSE_FUNCTION
	je	doneLoop

	; 
	; is the function being processed AND or OR ?
	;
	pop	bx			; retrieve the function ID
	push	bx			; and save it again
	cmp	bx, FUNCTION_ID_AND
	je	checkForRange
	cmp	bx, FUNCTION_ID_OR
	jne	okay

checkForRange:
	;
	; Yes, it is.  Now we need to check if this token is an operator,
	; and if so, is it a range separator.
	;
	cmp	al, PARSER_TOKEN_OPERATOR
	jne	okay
	cmp	{byte}ds:[si], OP_RANGE_SEPARATOR
	jne	okay
	;
	; It is a range separator.  We can't (don't) translate
	; AND/OR over a range into the equivalent 123 statement
	; using binary AND/OR, so replace it with the error function.
	;

overflow:
	;
	; Clear operator stack
	;
	mov	al, locals.ESF_operatorCount
	clr	ah
	sub	locals.ESF_operatorStackTopOffset, ax	; dec top of stack
	clr	locals.ESF_operatorCount		; dec count
	jmp	err					; abort! abort!

okay:
	mov	bl, al
	clr	bh
	shl	bx, 1			; bx <- offset into table

	mov	al, locals.ESF_operatorCount
	push	ax
	; 
	; If the token that is about to be processed is a function,
	; we don't want it to think there are operators on the stack.
	; Our operator count is on the stack, clear the passed count.
	; 
	cmp	bx, (PARSER_TOKEN_FUNCTION shl 1)
	jne	notFunction1
	clr	locals.ESF_operatorCount
notFunction1:
	call	cs:[bx].ParserTokenProcessor
;
; all Process routines return al = 0, unless it's END_OF_EXPRESSION
;
CheckHack <PARSER_TOKEN_END_OF_EXPRESSION ne 0>
EC<	pushf					>
EC<	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION >
EC<	ERROR_E IMPEX_ENCOUNTERED_PREMATURE_EOF    >
EC<	popf					>
	pop	ax			; retrieve old count
	jc	overflow		; on stack: FunctionID

	; 
	; If the token just processed was a function, now we want
	; to restore the operator count to what it was before the
	; function was processed.  (all of this to allow nested 
	; functions to behave properly.)
	; 
	cmp	bx, (PARSER_TOKEN_FUNCTION shl 1)
	jne	notFunction2
	mov	locals.ESF_operatorCount, al
notFunction2:

	sub	al, locals.ESF_operatorCount
	neg	al			; ax <- number of operators added
	add	ch, al
	jmp	short processLoop

doneLoop:
	;
	; translate function
	;
	pop	bx			; retrieve function id
	shr	bx, 1			; bx <- offset into table
EC<	cmp	bx, length LotusFunctionEquivTable >
EC<	ERROR_AE ROUTINE_USING_BAD_PARAMS >
	push	bx			; on stack: NumArgsReqTable offset
	add	bx, offset LotusFunctionEquivTable

	mov	al, cs:[bx]
	cmp	al, -1			; is this function not supported?
	LONG	je	err		; on stack: NumArgsReqTable offset

	cmp	al, LOTUS_FUNCTION_AND
	je	handleAndOr
	cmp	al, LOTUS_FUNCTION_OR
	jne	done
	
handleAndOr:
	; 
	; cl = number of arguments to the function. Since
	; AND, OR are binary operators, we need to add the one
	; function opcode to the output stream for every pair of 
	; function arguments.  So if there are N arguments, write
	; N-1 copies of the opcode to the output stream.  
	; Put out a parenthesis, to preserve the priority of 
	; the AND/OR arguments.
	;
;;;change this to .assert or CheckHack if possible
EC <	cmp	cs:[LOTUS_FUNCTION_AND].LotusNumArgsRequiredTable, \
	NUM_ARGS_NOT_REQ>
EC <	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC <	cmp	cs:[LOTUS_FUNCTION_OR].LotusNumArgsRequiredTable, \
	NUM_ARGS_NOT_REQ>
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	cmp	cx, 2
	LONG	jl err			; if less than 2 args, error.
	sub	cx, 2			; want N-1 operators, one stored below
	tst	cx			; if only need 1, store it below
	je	done

	CheckSize	cx, bx
	jc	err			; on stack: NumArgsReqTable offset
	rep	stosb			; store the others now
	jmp	done

done:
	pop	bx			; retrieve offset into
					; LotusNumArgsRequiredTable

	push	ax, bx
	mov	bx, 1
	CheckSize	bx, ax
	pop	ax, bx
	jc	exit
	stosb				; store Lotus func, update di

	;
	; store argument count if necessary
	;
EC<	cmp	cs:[bx].LotusNumArgsRequiredTable, NUM_ARGS_REQ >
EC<	je	argsReqEntryOK >
EC<	cmp	cs:[bx].LotusNumArgsRequiredTable, NUM_ARGS_NOT_REQ >
EC<	je	argsReqEntryOK >
EC<	cmp	cs:[bx].LotusNumArgsRequiredTable, -1 >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC< argsReqEntryOK: >

	cmp	cs:[bx].LotusNumArgsRequiredTable, NUM_ARGS_REQ
	clc
	jne	exit

	mov	bx, 1
	CheckSize	bx, ax
	jc	exit
	mov	al, cl
	stosb				; store argument count, update di

exit:
	.leave
	ret

err:
	; On the stack: bx = FunctionID or offset into LotusNumArgsReq.Table
	;
	; Attempting to export a function that Lotus does not support.
	; Or the output buffer has runneth over.
	;
	pop	bx			; clear stack
	stc
	jmp	exit

if 0
lateOverflow:
	mov	di, dx
	mov	al, LOTUS_FUNCTION_ERR
	stosb
	stc
	jmp	getOut
endif

ExportFormulaProcessFunction	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessFunctionCleanOperatorStack

DESCRIPTION:	The end of the argument has been reached and there may be
		operators left on the operator stack for the argument.  Deal
		with these by translating them.

CALLED BY:	INTERNAL (ExportFormulaProcessFunction)

PASS:		ch - number of operators left on the stack for this argument

RETURN:		carry set if buffer overflow
		al - clear

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ProcessFunctionCleanOperatorStack	proc	near	uses	cx
	.enter

	clr	al
	tst	ch				; any operators?
	je	done				; done if not

cleanLoop:
	call	ExportFormulaPopOperator	; al <- operator
	call	ExportFormulaPutOperator	; write al to output
	jc	exit
	dec	ch
	jne	cleanLoop
done:
	clc
exit:
	.leave
	ret
ProcessFunctionCleanOperatorStack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaProcessOperator

DESCRIPTION:	All operators on the stack that are of greater or equal
		priority will be outout.

CALLED BY:	INTERNAL (ExportFormulaCalcInfixToLotusPostfix via table)

PASS:		ExportStackFrame
		es:di - output stream

RETURN:		ds:si - updated
		es:di - updated
		al    - 0
		carry set if buffer overflow

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaProcessOperator	proc	near	uses	dx,ds
	locals	local	ExportStackFrame
	.enter	inherit near

EC<	cmp	{byte} ds:[si-1], PARSER_TOKEN_OPERATOR >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	push	ds,si				; save si
	lodsb					; al <- operator

	cmp	al, OP_RANGE_SEPARATOR
	jne	processOperator

	;
	; Ranges in Lotus are not 3 entities (ie. "cell ref", ":", "cell ref").
	; Rather, there is a dedicated range opcode.  We will deal with this by
	; going back in the output stream and modifying the output and and then
	; grabbing the cell ref in the data stream and incorporating it into
	; the Lotus range.
	;

	mov	{byte} es:[di-5], LOTUS_FUNCTION_RANGE
	lodsb
EC<	cmp	al, PARSER_TOKEN_CELL >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
	call	ProcessCellReference		; carry set if overflow
	pop	ax,ax				; clear stack
	jmp	short done

processOperator:
	call	ExportFormulaGetInstackPriority	; al <- priority
	mov	dl, al				; dl <- priority of operator
	mov	ds, locals.ESF_operatorStackSeg	; ds <- stack segment

operatorLoop:
	cmp	locals.ESF_operatorCount, 0
	je	operatorDone

	mov	si, locals.ESF_operatorStackTopOffset
	mov	al, ds:[si-1]			; get operator at top of stack

	test	al, 80h				; left paren?
	jne	operatorDone			; branch if so

	call	ExportFormulaGetInstackPriority	; al <- priority
	cmp	al, dl
	jb	operatorDone

	call	ExportFormulaPopOperator	; al <- operator
	call	ExportFormulaPutOperator	; output operator
	jc	overflow
	jmp	short operatorLoop

operatorDone:
	pop	ds,si				; retrieve si
	mov	ax, PARSER_TOKEN_OPERATOR
	call	ExportFormulaPushOperator
	clc
done:
	pushf
	clr	al
	popf
	.leave
	ret

overflow:
	pop	ds, si
	jmp	done

ExportFormulaProcessOperator	endp


;*******************************************************************************
;
;	UTILITY ROUTINES FOLLOW
;
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaPushOperator

DESCRIPTION:	Push an operator onto the operator stack.
		Since the "operators" given can be GeoCalc OperatorTypes or
		the GeoCalc ParserTokenType PARSER_TOKEN_OPEN_PAREN, this
		routine will tack on an ms 1 bit to the ParserTokenType before
		storage.

CALLED BY:	INTERNAL (ExportFormulaProcessOperator,
			ExportFormulaProcessLeftParen)

PASS:		ExportStackFrame
		al - ParserTokenType
		ds:si - GeoCalc parser data stream

RETURN:		ds:si - updated if necessary (if al = OperatorType)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Will the operator stack ever overflow?
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaPushOperator	proc	near	uses	ax,es,di
	locals	local	ExportStackFrame
	.enter	inherit near

	cmp	al, PARSER_TOKEN_OPERATOR
	je	operator

	;
	; left parenthesis
	;
EC<	cmp	al, PARSER_TOKEN_OPEN_PAREN >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >	; only left paren allowed
	or	al, 80h				; tack on ms bit
	jmp	short doPush

operator:
	lodsb					; al <- OperatorType
EC<	cmp	al, NUMBER_OF_OPERATOR_TYPES >
EC<	ERROR_A IMPEX_ASSERTION_FAILED >

doPush:
	les	di, locals.ESF_operatorStackTopAddr	; es:di <- top of stack
	stosb
	mov	locals.ESF_operatorStackTopOffset, di	; update top of stack
	inc	locals.ESF_operatorCount		; up count

	.leave
	ret
ExportFormulaPushOperator	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaPopOperator

DESCRIPTION:	Pop an operator off the operator stack.
		Since the "operators" stored can be GeoCalc OperatorTypes or
		the GeoCalc ParserTokenType PARSER_TOKEN_OPEN_PAREN, this
		routine will return bytes that contain an ms 1 bit for the
		ParserTokenType.

CALLED BY:	INTERNAL ()

PASS:		ExportStackFrame

RETURN:		al - operator (OperatorType or ParserTokenType with ms bit set)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaPopOperator	proc	near	uses	ds,si
	locals	local	ExportStackFrame
	.enter	inherit near

EC<	cmp	locals.ESF_operatorCount, 0 >
EC<	ERROR_LE IMPEX_ATTEMPTING_POP_FROM_EMPTY_STACK >

	dec	locals.ESF_operatorStackTopOffset	; dec top of stack
	dec	locals.ESF_operatorCount		; dec count

	lds	si, locals.ESF_operatorStackTopAddr	; ds:si <- new stk top
	lodsb						; get operator

EC<	test	al, 80h >
EC<	jne	checkParen >
EC<	cmp	al, NUMBER_OF_OPERATOR_TYPES >
EC<	ERROR_A	ROUTINE_USING_BAD_PARAMS >
EC<	jmp	short done >
EC< checkParen: >
EC<	cmp	al, PARSER_TOKEN_OPEN_PAREN or 80h >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC< done: >

	.leave
	ret
ExportFormulaPopOperator	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaPutOperator

DESCRIPTION:	Write an operator out to the data stream.

CALLED BY:	INTERNAL ()

PASS:		al - OperatorType
		es:di - output stream

RETURN:		al - 0
		carry set if no Lotus equivalent
		carry set if buffer overflow
DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportFormulaPutOperator	proc	near	uses	bx
	locals	local	ExportStackFrame
	ForceRef locals
	.enter	inherit near

	test	al, 80h			; parenthesis?
	je	operator		; branch if not

	mov	al, LOTUS_FUNCTION_PARENTHESES
	jmp	short done

operator:
	mov	bl, al
	clr	bh
EC<	cmp	bx, length LotusOperatorEquivTable >
EC<	ERROR_AE ROUTINE_USING_BAD_PARAMS >
	add	bx, offset LotusOperatorEquivTable

	mov	al, cs:[bx]		; fetch Lotus equivalent
	cmp	al, -1			; no equivalent?
	stc
	je	exit			; branch if not

	; ???
;	ERROR	IMPEX_EXPORTING_INVALID_DATA

done:
	push	cx
	mov	cx, 1
	CheckSize	cx, bx
	pop	cx
	jc	exit
	stosb
	clc
exit:
	pushf
	clr	al
	popf

	.leave
	ret
ExportFormulaPutOperator	endp

LotusOperatorEquivTable		byte \
	-1,				; OP_RANGE_SEPARATOR
	LOTUS_FUNCTION_UMINUS,
	-1,				; OP_PERCENT
	LOTUS_FUNCTION_EXPONENT,
	LOTUS_FUNCTION_MULTIPLY,
	LOTUS_FUNCTION_DIVIDE,
	-1,				; OP_MODULO
	LOTUS_FUNCTION_PLUS,
	LOTUS_FUNCTION_SUB,
	LOTUS_FUNCTION_EQUAL,
	LOTUS_FUNCTION_NOT_EQUAL,
	LOTUS_FUNCTION_LT,
	LOTUS_FUNCTION_GT,
	LOTUS_FUNCTION_LT_OR_EQUAL,
	LOTUS_FUNCTION_GT_OR_EQUAL,
	-1,				; OP_STRING_CONCAT
	-1				; OP_RANGE_INTERSECTION


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportFormulaGetIncomingPriority
		ExportFormulaGetInstackPriority

DESCRIPTION:	Given an OperatorType, return its priority.

CALLED BY:	INTERNAL ()

PASS:		al - OperatorType

RETURN:		al - priority

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

NUMBER_OF_OPERATOR_TYPES	= 15

;
; lookup tables (-1 = illegal)
;

IncomingPriorityLookup	byte \
	-1,		; seperator
	8,		; negation
	-1,		; percent
	8,		; exponentiation
	6,		; multiplication
	6,		; division
	6,		; modulo
	5,		; addition
	5,		; subtraction
	4,		; =
	4,		; <>
	4,		; <
	4,		; >
	4,		; <=
	4		; >=

InstackPriorityLookup	byte \
	-1,		; seperator
	7,		; negation
	-1,		; percent
	7,		; exponentiation
	6,		; multiplication
	6,		; division
	6,		; modulo
	5,		; addition
	5,		; subtraction
	4,		; =
	4,		; <>
	4,		; <
	4,		; >
	4,		; <=
	4		; >=

if 0
ExportFormulaGetIncomingPriority	proc	near	uses	bx
	.enter

EC<	cmp	al, NUMBER_OF_OPERATOR_TYPES >
EC<	ERROR_AE ROUTINE_USING_BAD_PARAMS >

	mov	bl, al
	clr	bh
	mov	al, cs:[bx].IncomingPriorityLookup

	.leave
	ret
ExportFormulaGetIncomingPriority	endp
endif


ExportFormulaGetInstackPriority	proc	near	uses	bx
	.enter

EC<	cmp	al, NUMBER_OF_OPERATOR_TYPES >
EC<	ERROR_AE ROUTINE_USING_BAD_PARAMS >

	mov	bl, al
	clr	bh
	mov	al, cs:[bx].InstackPriorityLookup

	.leave
	ret
ExportFormulaGetInstackPriority	endp

