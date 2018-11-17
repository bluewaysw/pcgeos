COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseWrite.asm

AUTHOR:		John Wedgwood, Jan 24, 1991

ROUTINES:
	Name			Description
	----			-----------
	WriteNegationOp
	WriteFunctionCall
	WriteSingleToken
	WritePercentOp
	WriteBinaryOp
	WriteCloseFunction
	WriteArgEnd
	WriteEndOfExpression
	AllocateParserToken


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/24/91	Initial revision

DESCRIPTION:
	Functions to write parser tokens to an output buffer.

	$Id: parseWrite.asm,v 1.1 97/04/05 01:27:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteNegationOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a negation operator to the output stream.

CALLED BY:	ParseFullExpression
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteNegationOp	proc	near
	uses	ax, dx
	.enter
	mov	dl, OP_NEGATION			; dl <- operator

	mov	al, PARSER_TOKEN_OPERATOR	; al <- token type
	call	AllocateParserToken		; ax <- size of token
	jc	quit				; Quit if too large

	mov	es:[di], dl			; The operation to do

	add	di, ax				; Advance the pointer
	clc					; Signal: no error
quit:
	.leave
	ret
WriteNegationOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteFunctionCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a function call to the output stream

CALLED BY:	ParseFullExpression
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteFunctionCall	proc	near
	uses	ax, dx
	.enter
	mov	al, PARSER_TOKEN_FUNCTION	; al <- token type
	call	AllocateParserToken		; ax <- token size
	jc	quit				; Quit if error
	
	mov	dx,ss:[bp].PP_currentToken.ST_data.STD_identifier.STID_start
	mov	es:[di], dx			; Save the position of the
						;   function.
	
	add	di, ax				; Advance the pointer
	clc					; Signal: no error
quit:
	.leave
	ret
WriteFunctionCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSingleToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single token to the output stream

CALLED BY:	ParseFullExpression, ParseArgList
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Possible types are:
		Open Paren
		Close Paren
		Numeric Constant
		Cell Reference
		Function
		Unary Minus Operator
		Named Cell or Range

	Need to figure out which type we're dealing with and write it
	appropriately.
	
	The easiest to deal with is the Unary-Minus, since it's the only
	operator.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSingleToken	proc	near
	uses	ax
	.enter
	mov	al, ss:[bp].PP_currentToken.ST_type

	cmp	al, SCANNER_TOKEN_STRING	; Strings get handled specially
	jne	notString			; Branch if not a string
	call	WriteString			; Handle this separately
	jmp	quit				; Quit, carry set correctly
notString:

	cmp	al, SCANNER_TOKEN_OPERATOR	; Check for unary minus.
	jne	notUnaryMinus			; Branch if not
	call	WriteNegationOp			; Write unary minus
	jmp	quit				; Quit, carry set correctly
notUnaryMinus:
	;
	; The rest of the tokens are the same in the scanner and the parser.
	; Allocate space for the token, and if the token is zero sized,
	; we can just return (this is true for Open/Close Paren).
	;
	call	AllocateParserToken		; ax <- size of token
	jc	quit				; Quit if error

	tst	ax				; Check for zero sized
	jz	quitNoError			; Branch if zero sized
	;
	; Token wasn't zero sized. Luckily the data we need for the parser
	; is the same as that for the scanner. As a result we can simply
	; copy the information from the PP_currentToken into the output
	; stream.
	;	ax = amount of information to copy
	;
	push	cx, ds, si			; Save everything we nuke
	mov	cx, ax				; cx <- size
	segmov	ds, ss				; ds <- source
	mov	si, bp				; si <- source
	add	si, offset PP_currentToken + offset ST_data
	
	rep	movsb				; Copy the data
	pop	cx, ds, si			; Restore nuked registers
quitNoError:
	clc					; Signal: no error
quit:
	.leave
	ret
WriteSingleToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePercentOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a percent operator to the output stream

CALLED BY:	ParseMoreExpression
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePercentOp	proc	near
	uses	ax, dx
	.enter
	mov	dl, OP_PERCENT			; dl <- the operator

	mov	al, PARSER_TOKEN_OPERATOR	; al <- token type
	call	AllocateParserToken		; ax <- size of token
	jc	quit				; Quit if too large

	mov	es:[di], dl			; The operation to do

	add	di, ax				; Advance the pointer
	clc					; Signal: no error
quit:
	.leave
	ret
WritePercentOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBinaryOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a binary operator to the output stream

CALLED BY:	ParseMoreExpression
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	First check to see if it's one of those "undecided" operators
		OP_PERCENT_MODULO	(%)	Force to OP_MODULO
		OP_SUBTRACTION_NEGATION (-)	Force to OP_SUBTRACTION
	
	All others are by nature binary operators so we can just stuff
	them directly into the operatorID field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBinaryOp	proc	near
	uses	ax, dx
	.enter
	mov	dl,ss:[bp].PP_currentToken.ST_data.STD_operator.STOD_operatorID

	mov	al, PARSER_TOKEN_OPERATOR	; al <- token type
	call	AllocateParserToken		; ax <- size
	jc	quit				; Quit if error
	
	cmp	dl, OP_PERCENT_MODULO		; Check for modulo op
	jne	checkSubNeg			; Branch if not
	
	mov	dl, OP_MODULO			; Choose the binary operator
	jmp	writeOp				; Branch

checkSubNeg:
	cmp	dl, OP_SUBTRACTION_NEGATION	; Check for subtraction
	jne	writeOp				; Branch if not
	mov	dl, OP_SUBTRACTION		; Force to subtraction
writeOp:
	mov	es:[di].PTOD_operatorID, dl	; Write the operator ID

	add	di, ax				; Advance the pointer
	clc					; Signal: no error
quit:
	.leave
	ret
WriteBinaryOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCloseFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a close-function to the output stream

CALLED BY:	ParseFunctionArgs
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteCloseFunction	proc	near
	uses	ax
	.enter
	mov	al, PARSER_TOKEN_CLOSE_FUNCTION
	call	AllocateParserToken		; Should return 0...
	.leave
	ret
WriteCloseFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteArgEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an arg-end token to the output stream

CALLED BY:	ParseArgList
PASS:		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write the token
RETURN:		carry set on error
		es:di	= Pointer past inserted token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteArgEnd	proc	near
	uses	ax
	.enter
	mov	al, PARSER_TOKEN_ARG_END
	call	AllocateParserToken		; Should return 0
	.leave
	ret
WriteArgEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string to the parser output stream.

CALLED BY:	ParseArgList
PASS:		es:di	= Place to write to
		ds	= Segment address of the string
		ss:bp	= ParserParameters including currentToken
RETURN:		es:di	= Position after the token written
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version
	witt	11/29/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteString	proc	near
	uses	ax, cx, si
	.enter
	mov	al, PARSER_TOKEN_STRING		; al <- token type
	call	AllocateParserToken		; ax <- token size
	jc	quit				; Quit if error
	
	mov	cx, ss:[bp].PP_currentToken.ST_data.STD_string.STSD_length
	mov	es:[di].PTSD_length, cx
	
	add	di, ax				; Advance the pointer
	;
	; Since this is a variable sized data-item we need to make sure
	; we aren't going to overwrite the end of the buffer.
	;
SBCS<	mov	ax, ss:[bp].PP_currentToken.ST_data.STD_string.STSD_length	>
DBCS<	mov	ax, cx				; this is faster!		>
DBCS<	shl	ax, 1				; ax <- string size	>
	sub	ss:[bp].PP_parserBufferSize, ax
	js	bufferOverflow			; Branch if overflow
	;
	; Now copy the text of the string.
	;
	mov	si, ss:[bp].PP_currentToken.ST_data.STD_string.STSD_start
	add	si, ss:[bp].PP_textPtr.offset	; si <- offset to string
EC <	push	ax				;>
EC <	mov	ax, ds				;ax <- seg addr of string>
EC <	cmp	ax, ss:[bp].PP_textPtr.segment	;>
EC <	ERROR_NE PARSE_STRING_SEGMENT_FAILED_ASSERTION >
EC <	pop	ax

	LocalCopyNString 			; Copy the string (cx=length)

	clc					; Signal: no error
quit:
	.leave
	ret

bufferOverflow:
	mov	al, PSEE_TOO_MANY_TOKENS
	call	ParserReportError		; Report the error
	jmp	quit
WriteString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteEndOfExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an end-of-expression marker to the parser stream

CALLED BY:	ParseArgList
PASS:		es:di	= Place to write to
		ss:bp	= ParserParameters including currentToken
RETURN:		es:di	= Position after the token written
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteEndOfExpression	proc	near
	uses	ax
	.enter
	mov	al, PARSER_TOKEN_END_OF_EXPRESSION
	call	AllocateParserToken		; Should return 0
	.leave
	ret
WriteEndOfExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateParserToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate space for a single token in the output stream

CALLED BY:	Write*
PASS:		al	= ParserTokenType
		ss:bp	= Pointer to ParserParameters
		es:di	= Pointer to place to write
RETURN:		carry set on error
		token type saved into the buffer
		ax	= Size of the token data
		es:di	= Pointer to place to put the token data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The amount of data to write is implied by the token-type.
	We keep a table of the sizes in parserTokenSizeTable in
	the file parseVariable.asm

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateParserToken	proc	near
	uses	cx, ds, si
	.enter
	mov	cl, al				; Save token in cl

	clr	ah				; ax <- token

FXIP <	mov	si, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS		; ds = dgroup			>
FXIP <	mov	bx, si							>
NOFXIP<	segmov	ds, dgroup, si			; ds <- seg addr of table >
	mov	si, offset parserTokenSizeTable	; si <- offset to table
	add	si, ax				; si <- offset to item
	
	mov	al, ds:[si]			; ax <- size of token

	;
	; Now that we have the size of the token, we need to lose that
	; much space from the buffer we are writing to.
	;
	sub	ss:[bp].PP_parserBufferSize, ax
	js	bufferOverflow			; Branch if overflow

	;
	; Subtract a byte for the token itself.
	;
	dec	ss:[bp].PP_parserBufferSize
	js	bufferOverflow
	
	mov	es:[di], cl			; Save the token
	inc	di				; Advance the pointer
	clc					; Signal: no error
quit:
	.leave
	ret

bufferOverflow:
	mov	al, PSEE_TOO_MANY_TOKENS
	call	ParserReportError		; Report the error
	jmp	quit
AllocateParserToken	endp


ParserCode	ends
