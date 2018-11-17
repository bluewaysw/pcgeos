COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseParse.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	ParserParseString		Parse a string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	Parsing routines.

	$Id: parseParse.asm,v 1.1 97/04/05 01:27:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserParseString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a string.

CALLED BY:	Global
PASS:		ds:si	= Pointer to text to scan
		es:di	= Buffer to put parsed data in
		ss:bp	= Pointer to ParserParameters structure on the stack
RETURN:		carry set on error
		al	= Error code (ParserScannerEvaluatorError)
		cx,dx	= Range of text where the error was encountered
		es:di	= Pointer past the last token written
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
	The parser is too complicated to document completely here.
	The README, GRAMMAR, and THOUGHTS files contains a description of
	the language, tokens, errors, etc.
	
	The parser is a recursive descent parser. Each node corresponds
	to an item in the GRAMMAR file.
	
	The functions for each node should make pretty good sense
	individually. You will want the complete language definition
	to get the overall view though.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserParseString	proc	far
	uses	bx, si, bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].EP_common.CP_callback		>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>
EC <	call	ECCheckParserParameters		>

	mov	dx, di				; Save ptr to start of tokens

	call	ScannerInit			; Init the scanner
	jc	quit				; Quit if error

	call	ParseFullExpression		; Do the parsing
	jc	quit				; Quit if error
	;
	; If we get here we should be staring at the end of the
	; expression. If we grab the next token and it's not the end of
	; the text, we flag an error (bad expression).
	;
	call	ScannerGetNextToken		; Grab next token
	jc	quit				; Quit on error
	
	cmp	ss:[bp].PP_currentToken.ST_type,
					SCANNER_TOKEN_END_OF_EXPRESSION
	jne	errorBadExpr			; Branch on error

	call	WriteEndOfExpression		; Write the EOE marker
	jc	quit				; Quit if error
	;
	; Since we know it parsed, we now want to resolve all the name
	; references.
	;
	call	CountNameReferences		; cx <- # of name references
	jcxz	noNames				; jump if no name references
	call	CheckNameSpace			; Make sure there's space
	jc	quit				; Branch on error
noNames:
	;
	; Now turn the names into something meaningful.
	;
	call	ResolveNameReferences
	;;; Carry is set correctly here
quit:
	mov	al, ss:[bp].PP_error		; al <- error code
	mov	cx, ss:[bp].PP_tokenStart	; cx <- start of token
	mov	dx, ss:[bp].PP_tokenEnd		; dx <- end of token
DBCS <	pushf								>
DBCS <	shr	cx, 1				; char offset -> byte offset>
DBCS <	shr	dx, 1				; char offset -> byte offset>
DBCS <	popf								>
	.leave
	ret

errorBadExpr:
	mov	al, PSEE_EXPECTED_END_OF_EXPRESSION
	call	ParserReportError
	jmp	quit
ParserParseString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseFullExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an expression (as defined by our language)

CALLED BY:	ParserParseString, ParseFullExpression (recursively),
		ParseMoreExpression, ParseArgList
PASS:		ds:si	= Pointer to the text to parse
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to put parser tokens
RETURN:		ds:si	= Pointer past parsed text
		es:di	= Pointer past inserted parser tokens
		carry set on error.
		    PP_error holds the error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	t = GetNextToken()
	if (t == OPEN_PAREN) then
	    Parse( fullExpr )
	    t = GetNextToken()
	    if (t != CLOSE_PAREN) then
	        error()
	    endif
	    Parse( moreExpr )
	else if (t == '-') then
	    Parse( fullExpr )
	else if (t == IDENTIFIER) then
	    l = LookAhead()
	    if (l == OPEN_PAREN) then
		Parse( function )
	    else
	        Parse( moreExpr )
	    endif
	else if (isExprStarter( t )) then
	    Parse( moreExpr )
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseFullExpression	proc	near
	call	ScannerGetNextToken	; Grab next token
	jc	quit			; Quit if error
	
	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_OPEN_PAREN
	jne	checkNegation

	;
	; Token is an open paren. That means it contains an expression.
	;
	call	WriteSingleToken	; Write an open paren
	jc	quit			; Quit if error

	call	ParseFullExpression	; Parse it recursively
	jc	quit			; Quit if error

	call	ScannerGetNextToken	; Grab next token
	jc	quit			; Quit if error
	;
	; The next token MUST be a close-paren to finish off the
	; parenthesized expression.
	;
	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_CLOSE_PAREN
	jne	missingCloseParen
	
	call	WriteSingleToken	; Write a close paren
	jmp	parseMoreIfNoError	; Branch to parse more

checkNegation:
	;
	; Check for an expression led by a "-"
	;
	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_OPERATOR
	jne	checkFunction
	cmp	ss:[bp].PP_currentToken.ST_data.STD_operator.STOD_operatorID,
						OP_SUBTRACTION_NEGATION
	jne	errorBadExpression	; If operator, must be "-"
	;
	; Found an operator that is "-", parse a full expression after it
	;
	call	WriteNegationOp		; Write a negation operator
	jc	quit			; Quit if error

	call	ParseFullExpression	; Parse recursively
	jmp	quit			; Quit, error code set correctly

checkFunction:
	;
	; Check for an expression led off by a function invocation
	;
	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_IDENTIFIER
	jne	checkSingle
	;
	; It may be a function call, check for an open-paren following the
	; identifier.
	;
	call	ScannerLookAheadToken	; Grab the lookahead token
	jc	quit			; Quit on error

	cmp	ss:[bp].PP_lookAheadToken.ST_type, SCANNER_TOKEN_OPEN_PAREN
	jne	checkSingle		; Branch if not function invocation

	call	WriteFunctionCall	; Write out a function invocation
	jc	quit			; Quit on error

	call	ParseFunctionArgs	; Parse the function call
	jmp	parseMoreIfNoError	; Parse the rest of the expr

checkSingle:
	;
	; Check for a single item leading the expression
	;
	call	IsExprStartToken
	jnc	errorBadExpression	; Branch if error
	;
	; Is the start of an expression, fall thru to parse more expression
	;
	call	WriteSingleToken	; Write the current token
	;;; Carry set if error. Fall thru

parseMoreIfNoError:
	;
	; Carry set if error
	;
	jc	quit			; Quit if error
	call	ParseMoreExpression
	;;; Carry is set correctly for returning here
quit:
	ret

;------------------------------------------------------------

missingCloseParen:
	;
	; Error, close-paren missing from parenthesized expression
	;
	mov	al, PSEE_MISSING_CLOSE_PAREN
	call	ParserReportError
	jmp	quit

errorBadExpression:
	;
	; Error, the expression starts with something meaningless
	;
	mov	al, PSEE_BAD_EXPRESSION
	call	ParserReportError
	jmp	quit

ParseFullExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseMoreExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse more of an expression. Assumes that we have encountered
		the first part of an expression already.

CALLED BY:	ParseMoreExpression(recursively), ParseFullExpression,
		ParseArgList
PASS:		ds:si	= Pointer to text to parse
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to put parser tokens
RETURN:		ds:si	= Pointer past parsed text
		es:di	= Pointer past inserted parser tokens
		carry set on error.
			PP_error holds the error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	l = LookAhead()
	if (l == OPERATOR) then
	    t = GetNextToken()			/* grab the token */
	    if (t.opType == '+', '*', '/', '^') then
		/* Normal binary operator */
	        Parse( fullExpr )
	    else if (t.opType == '%') then
	        l = LookAhead()
	        if (isExprStarter( l )) then
	            /* current operator must be a binary operator */
		    Parse( fullExpr )
	        else
	            /* current operator must be a left unary operator */
		    Parse( moreExpr )
	        endif
	    endif
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseMoreExpression	proc	near
	;
	; Check for the "rest" of an expression
	;
	call	ScannerLookAheadToken
	jc	quit				; Quit if error
	;
	; If there is no operator, then there can't be more expression.
	; This isn't an error. Just a reason to stop.
	;
	cmp	ss:[bp].PP_lookAheadToken.ST_type, SCANNER_TOKEN_OPERATOR
	jne	quitNoError
	;
	; OK. We know it's an operator. Scarf it up and see what we want
	; to do about it.
	;
	call	ScannerGetNextToken
	jc	quit				; Quit if error
	;
	; Assume it's a binary operator (since there are more of these).
	; This means we only need to check for the PERCENT_MODULO operator
	; since it is the only left-associative unary operator.
	;
	cmp	ss:[bp].PP_currentToken.ST_data.STD_operator.STOD_operatorID,
							OP_PERCENT_MODULO
	jne	parseBinary
	;
	; The operator is either a percent or a modulo. We need to look
	; ahead and see if what ever is after us is more expression.
	; If it is, then we are looking at a binary operator (modulo).
	;
	call	ScannerLookAheadToken
	jc	quit				; Quit if error
	
	call	IsExprStartLookAhead		; Check for more expression
	jc	parseBinary			; Branch if more expression
	;
	; Looks like a unary operator to me... Write it out.
	; Then parse whatever follows... It must be more expression.
	; Otherwise we would have branched.
	;
	call	WritePercentOp			; Write out the operator
	jc	quit				; Quit if error
	call	ParseMoreExpression		; Parse more of it
	jmp	quit				; Quit (carry already set)
parseBinary:
	;
	; We have a binary operator, write it out.
	;
	call	WriteBinaryOp			; Write operator
	jc	quit				; Quit if error

	call	ParseFullExpression		; Parse the rest.
	;;; Carry is set correctly by ParseFullExpression()
quit:
	ret

quitNoError:
	clc					; Signal: no error
	jmp	quit
ParseMoreExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseFunctionArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a function call. Assumes that the function name has
		been encountered and we are about to grab the open-paren.

CALLED BY:	ParseFullExpression
PASS:		ds:si	= Pointer to text to parse
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to put parser tokens
RETURN:		ds:si	= Pointer past parsed text
		es:di	= Pointer past inserted parser tokens
		carry set on error.
			PP_error holds the error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	t = GetNextToken()
	if (t != OPEN_PAREN) then
	    error()
	endif
	
	l = LookAhead()
	if (l != CLOSE_PAREN) then
	    Parse( argList )
	endif
	
	t = GetNextToken()
	if (t != CLOSE_PAREN) then
	    error()
	endif
	
	WriteOutput( EVAL )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseFunctionArgs	proc	near
	call	ScannerGetNextToken		; Grab next token
	jc	quit				; Quit on error

	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_OPEN_PAREN
	jne	expectedOpenParen		; Error if next isn't "("
	
	call	ScannerLookAheadToken
	jc	quit				; Quit on error
	;
	; Check for a close-paren (no arguments).
	;
	cmp	ss:[bp].PP_lookAheadToken.ST_type, SCANNER_TOKEN_CLOSE_PAREN
	je	closeFunc			; Branch if ")"
	;
	; No close paren, Parse the arg-list
	;
	call	ParseArgList
	jc	quit				; Quit on error
closeFunc:
	;
	; Discard the close-paren.
	;
	call	ScannerGetNextToken
	jc	quit				; Quit on error
	
	cmp	ss:[bp].PP_currentToken.ST_type, SCANNER_TOKEN_CLOSE_PAREN
	jne	expectedCloseParen		; Branch if not close-paren
	;
	; was a close-paren. Mark that the function call was o'tay.
	;
	call	WriteCloseFunction		; Note that the function closed
	;;; Carry set correctly for return
quit:
	ret

expectedOpenParen:
	;
	; No open-paren was found
	;
	push	ax
	mov	al, PSEE_EXPECTED_OPEN_PAREN
	call	ParserReportError
	pop	ax
	jmp	quit

expectedCloseParen:
	;
	; No close-paren was found
	;
	push	ax
	mov	al, PSEE_EXPECTED_CLOSE_PAREN
	call	ParserReportError
	pop	ax
	jmp	quit

ParseFunctionArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseArgList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an argument list. Assumes we are at the beginning.
		(ie: right after the open-paren of the function call).

CALLED BY:	ParseFunctionArgs
PASS:		ds:si	= Pointer to text to parse
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to put parser tokens
RETURN:		ds:si	= Pointer past parsed text
		es:di	= Pointer past inserted parser tokens
		carry set on error
			PP_error holds the error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Parse(fullExpression)
	Parse( moreArgs )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseArgList	proc	near
	call	ParseFullExpression		; Parse the whole thing
	jc	quit				; Carry set if error

	call	WriteArgEnd			; Signal done with this arg
	jc	quit				; Quit if error

	call	ParseMoreArgs			; Parse more args.

	;;; Carry is set correctly here by ParseMoreArgs()
quit:
	ret
ParseArgList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseMoreArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse more of an argument list. Assumes that the start of
		arg-list has been found.

CALLED BY:	ParseArgList
PASS:		ds:si	= Pointer to text to parse
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to put parser tokens
RETURN:		ds:si	= Pointer past parsed text
		es:di	= Pointer past inserted parser tokens
		carry set on error
			PP_error holds the error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	l = LookAhead()
	if (l == ARGUMENT_SEPARATOR) then
	    GetNextToken();
	    Parse( argList );
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseMoreArgs	proc	near
	;
	; Check the next token (which should be the argument separator).
	;
	call	ScannerLookAheadToken
	jc	quit
	;
	; If there is a list-separator, we're in business. We can call
	; back to parse more arguments. Otherwise we can just return.
	;
	;
	cmp	ss:[bp].PP_lookAheadToken.ST_type, SCANNER_TOKEN_LIST_SEPARATOR
	jne	quitNoError			; Quit if no separator

	call	ScannerGetNextToken		; Discard separator
	jc	quit

	call	ParseArgList			; Parse more arguments
	
	;;; carry set correctly here by ParseArgList()
quit:
	ret

quitNoError:
	clc					; Signal: no error
	jmp	quit

ParseMoreArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsExprStartToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the current token could be the start
		or more of an expression

CALLED BY:	ParseFullExpression, ParseArgList
PASS:		ss:bp	= Pointer to ParserParameters (PP_currentToken)
RETURN:		carry set if the token is more expression
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The current token type must be one of:
		Function name
		Constant
		String Constant
		Cell Reference
		Right associated unary operator

	This function basically asks the question "Does the current
	expression stop here, or does it continue?".
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsExprStartToken	proc	near
	uses	di
	.enter
	mov	di, offset PP_currentToken
	call	IsExprStart
	.leave
	ret
IsExprStartToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsExprStartLookAhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the look-ahead token could be the start
		of an expression.

CALLED BY:	ParseMoreExpression
PASS:		ss:bp	= Pointer to ParserParameters (PP_lookAheadToken)
RETURN:		carry set if the token is more expression
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsExprStartLookAhead	proc	near
	uses	di
	.enter
	mov	di, offset PP_lookAheadToken
	call	IsExprStart			; Check other types
	.leave
	ret
IsExprStartLookAhead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsExprStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a token to see if could be the start of an expression

CALLED BY:	IsExprStartLookAhead, IsExprStartToken
PASS:		ss:bp.di = Pointer to the token to check
RETURN:		carry set if the token is more expression
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	A "-" isn't considered to be the start of an expression. This
	isn't really true, but it makes other code simpler.
	
	We only get here from two places. One is ParseFullExpression.
	In that case we have already checked for the existence of a
	"-".
	
	The other case is from ParseMoreExpression. In that case we
	don't want to allow the "-" to be considered the start of an
	expression anyway.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsExprStart	proc	near
	uses	ax
	.enter
	mov	al, ss:[bp][di].ST_type
	
	cmp	al, SCANNER_TOKEN_NUMBER
	je	moreExpr
	
	cmp	al, SCANNER_TOKEN_STRING
	je	moreExpr
	
	cmp	al, SCANNER_TOKEN_CELL
	je	moreExpr
	
	cmp	al, SCANNER_TOKEN_IDENTIFIER
	je	moreExpr
	
	cmp	al, SCANNER_TOKEN_OPEN_PAREN
	jne	noMoreExpr
moreExpr:
	stc			; Signal: More expression
done:
	.leave
	ret

noMoreExpr:
	clc			; Signal: No more expression
	jmp	done

IsExprStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal a parser error

CALLED BY:	Utility
PASS:		al	= Error code (ParserScannerEvaluatorError)
RETURN:		carry set always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserReportError	proc	near
	mov	ss:[bp].PP_error, al
	stc
	ret
ParserReportError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountNameReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of references to new names

CALLED BY:	ParserParseString
PASS:		es:dx	= Pointer to a stream of tokens
		ss:bp	= Pointer to ParserParameters
RETURN:		cx	= # of references to new names
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This code doesn't entirely work. It doesn't know if a name has been
	referenced more than once. This means that the count returned may
	be too high. This is ok (I guess) since it means that we will definitely
	make sure to have enough name space. The problem is that a user might
	hit the limit earlier than they might expect. I doubt it will be a
	serious problem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountNameReferences	proc	near
	uses	di
	.enter
	clr	cx			; No new names yet
	mov	di, offset cs:CountNamesCallback
	call	ProcessTokenStream	; Process the list of tokens
	;
	; cx = # of new names
	;
	.leave
	ret
CountNameReferences	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountNamesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for an undefined name.

CALLED BY:	ProcessTokenStream
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to token data
		al	= Token type
		cx	= # of new names found so far
RETURN:		cx incremented if this name is also a new one
		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountNamesCallback	proc	near
	uses	ax, si
	.enter
	cmp	al, PARSER_TOKEN_NAME
	jne	quitContinue

	;
	; It's a name, call back to the application to find out if it's a new
	; one.
	;
	; In the first pass, we simply saved the offset of the name
	; in the text we were parsing.  In the second pass, we get back
	; the pointer to the string, and call back to the application
	; to ask it to resolve the name for us, if it can.
	;
	push	cx, ds			; Save name count, token segment
	mov	si, ds:[si].PTND_name	; si <- offset to the name
	add	si, ss:[bp].PP_textPtr.offset
	mov	ds, ss:[bp].PP_textPtr.segment

	call	FindIdentifierLength	; cx <- length of the string
	
	mov	al, CT_CHECK_NAME_EXISTS
if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bp].CP_callback
	call	ProcCallFixedOrMovable		; ds:si = token data
	pop	bx
else
	call	ss:[bp].CP_callback		; Does it exist?
endif
	pop	cx, ds			; Restore name count, token segment

	jc	quitContinue		; Branch if it exists
	
	;
	; It's a brand new name, add one to the name count.
	;
	inc	cx			; One more new name
quitContinue:
	clc				; Please continue
	.leave
	ret
CountNamesCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNameSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see that there is enough name space to parse
		this expression.

CALLED BY:	ParserParseString
PASS:		ss:bp	= Pointer to ParserParameters
		cx	= # of new names this expression references
RETURN:		carry set on error
		al	= Error code (ParserScannerEvaluatorError)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNameSpace	proc	near
	mov	al, CT_CHECK_NAME_SPACE
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL		
else
	call	ss:[bp].CP_callback	; Check for enough name space
endif
	jnc	quit			; Branch if no error
	call	ParserReportError	; Otherwise save the error
quit:
	ret
CheckNameSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolveNameReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve references to names made in the expression

CALLED BY:	ParserParseString
PASS:		ss:bp	= Pointer to ParserParameters on the stack
		es:dx	= Pointer to start of stream of tokens
RETURN:		carry set on error
		al	= Error code (ParserScannerEvaluatorError)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Run through the parsed expression, calling back for each name
	and for each function.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolveNameReferences	proc	near
	uses	di
	.enter
	mov	di, offset cs:ResolveNameCallback
	call	ProcessTokenStream	; Resolve the references
	jnc	quit			; Branch if no error

	mov	al, cl			; al <- error code (if any)
	call	ParserReportError	; Report an error
quit:
	.leave
	ret
ResolveNameReferences	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolveNameCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve a single name

CALLED BY:	ResolveNameReferences via ProcessTokenStream
PASS:		al	= Token type
		ds:si	= Token data
		ss:bp	= Pointer to ParserParameters
RETURN:		carry set on error
		cl	= Error code (ParserScannerEvaluatorError)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolveNameCallback	proc	near
	uses	bx, dx, di, si, ds, es
	.enter

	cmp	al, PARSER_TOKEN_NAME	; Check for a name
	je	resolveThing		; Branch to resolve the item

	cmp	al, PARSER_TOKEN_FUNCTION
	jne	nextToken		; Skip to next token
resolveThing:
	;
	; It's a name or function. Call the application and ask it to
	; resolve it.
	;
	push	ds, si			; Save ptr to token stream
	mov	si, ds:[si].PTND_name	; si <- offset to the name
	mov	dx, si			; dx <- position of token start

	add	si, ss:[bp].PP_textPtr.offset
	mov	ds, ss:[bp].PP_textPtr.segment
	call	FindIdentifierLength	; cx <- length of the string
	;
	; Save the position of the identifier and the end of the identifier
	; so that if there's an error we can show the user where it is.
	;
	mov	ss:[bp].PP_tokenStart, dx
	add	dx, cx			; dx <- end of the token
DBCS<	add	dx, cx			; char count to byte offset	>
	mov	ss:[bp].PP_tokenEnd, dx

	mov	dx, ax			; Save token in dx
	;
	; Now that we have a pointer and a length we need to decide whether
	; we are resolving a name or function.
	;
	cmp	al, PARSER_TOKEN_FUNCTION
	jne	resolveName		; Branch if it's a name
	;
	; It should be a function. Check to see if it's a built-in function.
	;
	call	IsFunction		; Check if it's a function
					; carry set if it's a function
	mov	al, PSEE_ILLEGAL_TOKEN	; This is the code if there is an error
	cmc				; Reverse the carry
	jc	popAndQuitOrSaveID	; Quit if not a function
	;
	; Is a function, di holds the ID of the function.
	;
	mov	cx, di			; Want the value in cx
	jmp	popAndQuitOrSaveID	; Branch to save it
resolveName:
	;
	; Don't resolve names if they aren't allowed
	;
	test	ss:[bp].PP_flags, mask PF_NAMES
	jz	illegalToken		; Branch if names are not allowed

	mov	al, CT_NAME_TO_TOKEN	; Convert name to a token
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; Call the application
endif

popAndQuitOrSaveID:
	;
	; If the carry is set here, we quit. Otherwise we save the token or
	; function id (in cx).
	;
	pop	ds, si			; Restore ptr to token stream
	jc	reportError		; Branch on error
	mov	ax, dx			; Restore token
	mov	ds:[si].PTND_name, cx	; Save the name token

nextToken:
	clc
quit:
	.leave
	ret

illegalToken:
	mov	al, PSEE_ILLEGAL_TOKEN
	stc
	jmp	popAndQuitOrSaveID

reportError:
	call	ParserReportError
	mov	cl, al			; Return error in cl
	jmp	quit
ResolveNameCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a string is a function name

CALLED BY:	ScanIdentifier
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to the string
		cx	= Length of the string
RETURN:		carry set if the string is a function name
		    di	= Function ID
		PP_flags with the PF_CONTAINS_DISPLAY_FUNC bit set if the
		    function is one of the "display only" types.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		All string lengths in the table are bytes.  For DBCS
		only the strings themselves are 'wchar's.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version
	witt	10/21/93	DBCS-ized table searching.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsFunction	proc	near
	uses	ax, bx, cx, es
	.enter
	test	ss:[bp].PP_flags, mask PF_FUNCTIONS
	jz	done			; functions not allowed (carry clear)

	tst	ch			; Function names are <256 characters
	jnz	notFunction		; Branch if larger than 256 characters

NOFXIP<	segmov	es, dgroup, ax		; es:di <- ptr to array of pointers >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES		; es = dgroup			>
FXIP <	mov_tr	bx, ax							>
	mov	di, offset funcTable
	
	mov	bx, length funcTable	; bx <- size of the table
stringCompareLoop:
	;
	; ds:si	= Pointer to string to check
	; cx	= Length of the string
	; bx	= # of strings to check
	; es:di	= Pointer to pointer to string to check against
	;
	push	di			; Save ptr
	mov	di, es:[di]		; es:di <- ptr to string to check
	mov	al, es:[di]		; al <- length of the string

	cmp	cl, al			; Make sure the lengths are the same
	jne	nextFunction		; Branch if lengths differ
	inc	di			; Skip the length byte
	
	;
	; ds:si	= Pointer to the string to check
	; es:di	= Pointer to string to compare it to (always ASCII)
	; cx	= # of characters to check
	;
SBCS<	call	LocalCmpStringsNoCase					>
DBCS<	call	ParseCmpStringsDBCSToSBCSNoCase				>
	je	isFunction		; Strings matched

nextFunction:
	pop	di			; Restore ptr

	add	di, 2			; Move to next ptr
	dec	bx			; One less to check
	jnz	stringCompareLoop	; Loop to check next one

	jmp	notFunction		; Branch if no functions matched

isFunction:
	pop	di			; Restore ptr
	sub	di, offset funcTable	; di <- offset into the table
	mov	di, es:funcIDTable[di]	; di <- function identifier
	
	;
	; Now we run through the displayOnly list to see if the function is
	; included there.
	; di = Function id.
	; es = segment address of dgroup.
	;
	mov	cx, length displayOnlyTable
	clr	bx			; Use bx as an index
displayOnlyLoop:
	cmp	di, es:displayOnlyTable[bx]
	jne	checkNext		; Branch if not found yet
	;
	; We found it, set the flag and quit.
	;
	or	ss:[bp].PP_flags, mask PF_CONTAINS_DISPLAY_FUNC
	jmp	endDisplayLoop
checkNext:
	add	bx, 2			; Move to next table entry
	loop	displayOnlyLoop		; Loop to check it out.
endDisplayLoop:

	;
	; Signal: We've found a function.
	; di = Function id.
	;
	stc				; Signal: Is a function
done:
	.leave
	ret

notFunction:
	;
	; Call the application, perhaps this is an externally defined
	; function.
	;
	mov	al, CT_FUNCTION_TO_TOKEN
if FULL_EXECUTE_IN_PLACE
	push	bx
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bp].CP_callback
	call	ProcCallFixedOrMovable		; ds:si = token data
	pop	bx
else
	call	ss:[bp].CP_callback ; Call the application
endif
	jmp	done			; Quit

IsFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessTokenStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run through a stream of tokens calling a callback for each one.

CALLED BY:	CountNameReferences, ResolveNameReferences
PASS:		es:dx	= Pointer to token stream
		ss:bp	= Pointer to ParserParameters
		di	= Callback routine (near ptr)
		cx	= Parameters for the callback
RETURN:		cx set by the callback
		carry set by the callback
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The callback should be defined as:
		Pass:
			ss:bp	= Pointer to ParserParameters
			al	= Token type
			ds:si	= Pointer to token data
			cx	= Data from caller
		Return:
			cx	= Data to return
			carry set to abort
		Destroyed:
			nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessTokenStream	proc	near
	uses	ax, dx, si, ds, es
	.enter
	segmov	ds, es, si		; ds:si <- ptr to token stream
	mov	si, dx
	
NOFXIP<	segmov	es, dgroup, dx		; es <- parserTokenSizeTable segment >
FXIP <	mov_tr	ax, bx			; ax = bx			>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES		; es = dgroup			>
FXIP <	mov_tr	bx, ax			; restore bx			>
tokenLoop:
	;
	; ds:si = Pointer to next token
	;
	clr	ah
	lodsb				; ax <- token
EC<	cmp	ax, ParserTokenType	; ax within range?		>
EC<	ERROR_AE EVAL_ILLEGAL_PARSER_TOKEN				>

	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	je	quitNoError		; Quit if end of expression
	;
	; Call the callback...
	;
	call	di			; Call the callback
	jc	quit			; Branch on error

	;
	; es = Segment address of parserTokenSizeTable
	; di = Callback
	;
	push	di			; Save callback routine
	mov	di, ax
	clr	dh			; dx <- size of the token data
	mov	dl, es:parserTokenSizeTable[di]
	pop	di			;Restore callback routine
	
	;
	; al	= Parser token type
	; ds:si	= Pointer to token data
	; dx	= size of `base' token
	;
	cmp	al, PARSER_TOKEN_STRING
	jne	notString		; Branch if not a string
if DBCS_PCGEOS
	mov	ax, ds:[si].PTSD_length	; ax <- length of string
	shl	ax, 1			; ax <- size of string
	add	dx, ax			; dx <- token size + string size
else
	add	dx, ds:[si].PTSD_length	; dx <- token size + length of string
endif

notString:
	add	si, dx			; ds:si <- next token
	jmp	tokenLoop		; Loop to do next token

quitNoError:
	clc
quit:
	.leave
	ret
ProcessTokenStream	endp


ParserCode	ends
