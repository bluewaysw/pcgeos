COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetExprMethods.asm

AUTHOR:		John Wedgwood, Mar 25, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/25/91		Initial revision


DESCRIPTION:
	Methods for parsing, evaluating, and formatting expressions
		

	$Id: spreadsheetExprMethods.asm,v 1.1 97/04/07 11:14:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetParserFormatExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format an expression made up of parser tokens

CALLED BY:	via MSG_SPREADSHEET_FORMAT_EXPRESSION
PASS:		ss:bp	= Pointer to SpreadsheetFormatParameters
				SFP_expression
				SFP_text
				SFP_length
		dx	= Size of SpreadsheetFormatParameters
				(if called remotely)
RETURN:		*SFP_text  = The formatted text (null terminated)
		SFP_length = Length of the formatted text.
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetParserFormatExpression	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_FORMAT_EXPRESSION
	mov	si, di				; ds:si <- instance pointer
	call	SpreadsheetInitCommonParams	; Initialize the common params
	;
	; Set up pointers to the text and the expression.
	;
	mov	ds, ss:[bp].SFP_expression.segment
	mov	si, ss:[bp].SFP_expression.offset
	
	mov	es, ss:[bp].SFP_text.segment
	mov	di, ss:[bp].SFP_text.offset
	
	mov	ax, ss:[bp].SFP_length		; Copy the buffer length
	mov	ss:[bp].FP_nChars, ax
	
	call	ParserFormatExpression		; Format the expression
	
	mov	ss:[bp].SFP_length, cx		; Save length of result
	ret
SpreadsheetParserFormatExpression	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetParseExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an expression. No new name references are allowed.

CALLED BY:	via MSG_SPREADSHEET_PARSE_EXPRESSION
PASS:		ss:bp	= Pointer to SpreadsheetParserParameters
				SPP_text
				SPP_expression
				SPP_parserParams.PP_flags
		dx	= Size of SpreadsheetParserParameters
				(if called remotely)
RETURN:		al	= ParserScannerEvaluatorError if error
		al	= -1 otherwise
		SPP_expression = parsed expression
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/25/91		Initial version
	witt	11/15/93	DBCS-ized.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetParseExpression	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_PARSE_EXPRESSION
	mov	si, di				; ds:si <- instance ptr
	call	SpreadsheetInitCommonParams	; Initialize the stack frame
	;
	; Set up the pointers
	;
	mov	ds, ss:[bp].SPP_text.segment
	mov	si, ss:[bp].SPP_text.offset
	
	mov	es, ss:[bp].SPP_expression.segment
	mov	di, ss:[bp].SPP_expression.offset
	
	mov	ax, ss:[bp].SPP_exprLength	; Copy the buffer size
DBCS<	shl	ax, 1				; ax <- buffer size	>
	mov	ss:[bp].PP_parserBufferSize, ax

	call	ParserParseString		; Parse the string
	jc	quit				; Quit on error

	mov	al, -1				; Signal: no error
quit:
	ret
SpreadsheetParseExpression	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetParserEvalExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate an expression

CALLED BY:	via MSG_SPREADSHEET_EVAL_EXPRESSION
PASS:		ss:bp	= Pointer to SpreadsheetEvalParameters
				SEP_expression
		cl	= EvalFlags
		dx	= Size of SpreadsheetEvalParameters
				(if called remotely)
RETURN:		al	= ParserScannerEvaluatorError if a serious error was
			  encountered
		al	= -1 otherwise
		SEP_result = Result of the evaluation
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS< SCRATCH_BUFFER_SIZE	equ	256*(size char) 	>
DBCS< SCRATCH_BUFFER_SIZE	equ	256*(size wchar)	>

SpreadsheetParserEvalExpression	method	SpreadsheetClass,
				MSG_SPREADSHEET_EVAL_EXPRESSION
	sub	sp, SCRATCH_BUFFER_SIZE		; Make a stack frame
	mov	bx, sp				; ss:bx <- ptr to stack frame

	mov	si, di				; ds:si <- instance ptr
	call	SpreadsheetInitCommonParams	; Initalize the stack frame
	mov	ss:[bp].EP_flags, cl		; Init the flags
	;
	; Set up the pointers
	;
	mov	ds, ss:[bp].SEP_expression.segment
	mov	si, ss:[bp].SEP_expression.offset
	
	segmov	es, ss, di			; es:di <- ptr to scratch buffer
	mov	di, bx
	mov	cx, SCRATCH_BUFFER_SIZE		; cx <- size of scratch buffer

	call	ParserEvalExpression		; Evaluate the expression
	jc	quit				; Quit on error
	
	;
	; Copy the result into the stack frame for copying back.
	;
	mov	cx, size ArgumentStackElement
	segmov	ds, es, si			; ds:si <- ptr to result
	mov	si, bx
	
	segmov	es, ss, di			; es:di <- ptr to result
	lea	di, ss:[bp].SEP_result
	
	rep	movsb				; Copy the result

	mov	al, -1				; Signal: no error
quit:
	add	sp, SCRATCH_BUFFER_SIZE		; Restore stack
	ret
SpreadsheetParserEvalExpression	endm


SpreadsheetNameCode	ends
