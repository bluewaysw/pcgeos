COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseScanner.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	ScannerInit		Initialize the scanner
	ScannerGetNextToken	Get the next token from the stream
	ScannerLookAheadToken	Look ahead at the next token in the stream
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	Scanner for the parser library.

	$Id: parseScanner.asm,v 1.1 97/04/05 01:27:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Scanner		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScannerInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the scanner

CALLED BY:	Parser
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to the text to scan
RETURN:		carry set if error.
		structure initialized and ready to parse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Basically zeros out error and condition flags that are set
		internally.

		Saves the start of the text so that string constants can
		 be referred to as an offset into the string. (Need to
		 know where the string starts in order to calculate the
		 offset).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScannerInit	proc	far
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>

	and	ss:[bp].PP_flags, not (mask PF_HAS_LOOKAHEAD)
	movdw	ss:[bp].PP_textPtr, dssi	; Store the text start
	clc					; Signal no error
	ret
ScannerInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScannerGetNextToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next token from the token stream

CALLED BY:	Parser
PASS:		ds:si	= Pointer to text to scan
		ss:bp	= ParserParameters
RETURN:		currentToken of ParserParameters filled in
		ds:si	= Pointer past the scanned text
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if next token is already in the look-ahead token then
	    copy the look-ahead token into the current token
	    clear the flag
	else
	    parse the text into the current token
	fi
	
	** For more information see ScanToken **

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScannerGetNextToken	proc	far
	uses	bx, di, ds, es
	.enter
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>

	mov	bx, bp
	add	bx, offset PP_currentToken	; ss:bx <- ptr to place to
						;   put scanned token

	test	ss:[bp].PP_flags, mask PF_HAS_LOOKAHEAD
	jz	getToken			; Branch if no look-ahead
	;
	; There is a lookahead token, clear the bit and then grab it.
	;
	push	si				; Save pointer
	and	ss:[bp].PP_flags, not mask PF_HAS_LOOKAHEAD

	segmov	ds, ss				; ds <- seg addr of source
	mov	si, bp				; si <- offset to source
	add	si, offset PP_lookAheadToken

	segmov	es, ss				; es <- seg addr of destination
	mov	di, bx				; di <- offse to destination
	
	mov	cx, size ScannerToken		; cx <- size of token
	rep	movsb				; Copy the token
	pop	si				; Restore pointer

	clc					; Signal: no error
	jmp	done
getToken:
	call	ScanToken			; Scan the token
done:

EC <	call	ECCheckPointer			>
	.leave
	ret
ScannerGetNextToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScannerLookAheadToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look ahead one token

CALLED BY:	Parser
PASS:		ds:si	= Pointer to text to scan
		ss:bp	= ParserParameters
RETURN:		lookAheadToken of ParserParameters filled in
		ds:si	= Pointer past the scanned text
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Grab the next token and put it in the look-ahead token.
	Mark the scanner as having a look-ahead token saved away.

	** For more information see ScanToken **

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScannerLookAheadToken	proc	far
	uses	bx
	.enter
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>
	;
	; We want bx to be set correctly, even if we branch to "done"
	; so that any tcl code will have the correct pointer to
	; work with.
	;
	mov	bx, bp
	add	bx, offset PP_lookAheadToken	; ss:bx <- ptr to place to
						;   put scanned token
	;
	; Check for already got look-ahead token
	; 'test' clears the carry, so if we quit out early, we won't be
	; signalling an error (which is what we want).
	;
	test	ss:[bp].PP_flags, mask PF_HAS_LOOKAHEAD
	jnz	done				; Quit if already got it.

	or	ss:[bp].PP_flags, mask PF_HAS_LOOKAHEAD
						; Has lookahead token (now)
	call	ScanToken			; Scan the token

done:				; Used by tcl debugging code
	ForceRef	done

EC <	call	ECCheckPointer			>
	.leave
	ret
ScannerLookAheadToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a token

CALLED BY:	ScannerGetNextToken, ScannerLookAheadToken
PASS:		ds:si	= Pointer to the text to scan
		ss:bp	= Pointer to ParserParameters
		ss:bx	= Pointer to the place to put the scanned token
RETURN:		ds:si	= Pointer past scanned text
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    The code in this routine is really just one big switch statement
	c = next character
	if (c == NULL) {
	    scan end-of-expression
	} else if (c == ") {
	    scan string constant
	} else if (c == operator) {
	    scan operator
	} else if (c == () {
	    scan open-paren
	} else if (c == )) {
	    scan close-paren
	} else if (c == ,) {
	    scan list separator
	} else if (isdigit(c)) {
	    scan numeric constant
	} else if (c == :) {
	    scan range separator
	} else if (c == .) {
	    if (isdigit(nextchar())) {
	        scan numeric constant
	    } else {
	        scan range separator
	    }
	} else if (isalpha(c)) {
	    /* it's either a cell-reference or an identifier */
	    scan cell reference
	    scan identifier
	}


    Like most scanners, all this does is to skip white space, attempt to
    identify what item is in the text stream, and then interpret that item.
    
    The scanner has no knowledge of the current context. It only interprets
    what it is looking at without regard to what it has seen or what is to
    come. All interpretation of the current context is left to the parser.
    
    For more information on the scanner see the README file.
    
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanToken	proc	near
	uses	ax
	.enter
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>

	call	SkipWhiteSpace		; Skip over any white space

	mov	ax, si			; ax <- offset to current position
	sub	ax, ss:[bp].PP_textPtr.offset
EC <	push	ax				;>
EC <	mov	ax, ds				;ax <- seg addr of string>
EC <	cmp	ax, ss:[bp].PP_textPtr.segment	;>
EC <	ERROR_NE PARSE_STRING_SEGMENT_FAILED_ASSERTION >
EC <	pop	ax
	mov	ss:[bp].PP_tokenStart, ax

	LocalGetChar	ax, dssi, NO_ADVANCE	; al <- current character
	;
	; First check for a NULL. That means end of the expression.
	;
	LocalIsNull	ax		; Check for reached NULL
	jnz	notEndOfExpression	; Branch if end of expression
	call	ScanEndOfExpression	; Found end of expression
	jmp	done			; Finish (carry set correctly)
notEndOfExpression:
	;
	; Check for range intersection operator.
	;
	LocalCmpChar	ax, '#'		; That's the operator
	jne	checkSeparator		; Branch if not
	call	ScanParserRangeIntersection
	jmp	done
checkSeparator:
	;
	; Check for a range separator.
	;
	LocalCmpChar	ax, ':'		; One type of separator
	je	scanSeparator		; Branch if this is one type
	cmp	al, '.'			; Check for '..' separator
	jne	checkDecimal		; Branch if not
	cmp	ds:[si][1], '.'		; Check for '..' separator
	jne	checkDecimal		; Branch if not
scanSeparator:
	call	ScanRangeSeparator	; Scan separator if not number
	jmp	done			; Finish (carry set correctly)
checkDecimal:
	;
	; Check for a decimal point followed by a digit.
	;
	call	CheckDecimalPoint	; Check for decimal point
	jne	checkNumber		; Branch if not
SBCS<	mov	al, ds:[si][1]		; al <- next character	>
DBCS<	mov	ax, ds:[si][2]		; ax <- next character	>
	call	IsDigit			; Check for a digit
	jc	scanNumber		; Scan number if of form ".[0-9]"
	mov	al, ds:[si]		; al <- current character
checkNumber:
	;
	; Check to see if the character is a digit
	;
	call	IsDigit			; Check for start of a number
	jnc	checkString		; Branch if not
scanNumber:
	call	ScanNumericConstant	; Scan a numeric constant
	jmp	done			; Finish (carry set correctly)
checkString:
	;
	; Check to see if we are looking at a string constant
	;
	LocalCmpChar	ax, '"'		; Check for start of a string
	jne	checkOperator		; Branch if not
	call	ScanStringConstant	; Scan a string constant
	jmp	done			; Finish (carry set correctly)
checkOperator:
	;
	; Check to see if the character is an operator
	;
	call	IsOperator		; Check for an operator
	jc	doneNoError		; Branch if found one
	;
	; Check for a whole list of one-character items
	;
	call	IsOther			; Returns token
	jc	doneNoError		; Branch if found one
	;
	; If we are here, it really should be either an identifier or
	; a cell reference. The only real way to check this is to try
	; one and if that doesn't work, try the other.
	;
	; Well, there is one shortcut: if cell references are not allowed,
	; then skip the cell reference check altogether.
	;
	test	ss:[bp].PP_flags, mask PF_CELLS
	jz	doScanIdentifier	; jump if we don't do cell references.

	mov	ax, si			; Save ptr into the text in ax

	call	ScanCellReference	; Scan the cell reference
	jnc	done			; Quit if it was a cell reference

	mov	si, ax			; Restore pointer to the text
	;
	; It must be an identifier.
	;

doScanIdentifier:	
	call	ScanIdentifier		; Sets carry on error
done:

	pushf				; Save carry (error)
	mov	ax, si			; ax <- offset to current position
	sub	ax, ss:[bp].PP_textPtr.offset
EC <	push	ax				;>
EC <	mov	ax, ds				;ax <- seg addr of string>
EC <	cmp	ax, ss:[bp].PP_textPtr.segment	;>
EC <	ERROR_NE PARSE_STRING_SEGMENT_FAILED_ASSERTION >
EC <	pop	ax
	mov	ss:[bp].PP_tokenEnd, ax
	popf				; Restore carry (error)

EC <	call	ECCheckPointer			>
	.leave
	ret

doneNoError:
	clc				; Signal: no error
	jmp	done			; Quit
ScanToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanNumericConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a numeric constant from the input stream.

CALLED BY:	ScanToken
PASS:		ds:si	= Pointer to the text to scan
		ss:bp	= Pointer to ParserParameters
		ss:bx	= Place to put the scanned token
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For now we find the start and length of the string and
	pass it along to a separate routine which will convert it to
	a numeric constant. When we get floating-point code ported
	over, hopefully it will include an ascii->float routine.

	Skip over any digits.
	if a decimal point exists then
	    Skip over a decimal point
	    Skip over any trailing digits
	endif
	Skip any white-space
	if the next character is "e" or "E" then
	    skip the "e"
	    skip any white-space
	    if the next character is a sign (+/-) then
	        skip the sign
		skip any white-space
	    endif
	    if the next character is a digit then
		skip over any digits
	    else
		error: bad number
	    endif
	endif
	pass the number off to an ascii->float routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanNumericConstant	proc	near
	uses	ax, cx, dx
	.enter
	mov	dx, si			; Save start of the number
	;
	; First skip any digits which would fall to the left of a decimal
	; point. (There may not be any).
	;
	call	SkipDigits		; Skip any digits to the left
	;
	; Skip over a decimal point if one exists
	;
	push	ax
	LocalGetChar	ax, dssi, NO_ADVANCE
	call	CheckDecimalPoint
	pop	ax
	jne	checkExponent		; No decimal, go to check exponent
	;
	; Found a decimal point, skip it and then start skipping digits
	;
	LocalNextChar	dssi		; Skip decimal point
	call	SkipDigits		; Skip digits on the right

checkExponent:
	;
	; Check for an exponent, and if one exists, scan it.
	;
	call	SkipWhiteSpace		; There may be white space
	LocalCmpChar	ds:[si], 'e'	; Check for the "e"
	je	scanExponent		; Branch if it is an exponent
	LocalCmpChar	ds:[si], 'E'	; Check for the "E"
	jne	finish			; Branch if no exponent
scanExponent:
	LocalNextChar	dssi		; Skip past the "e"
	call	SkipWhiteSpace		; Skip any white space
	;
	; Skip any sign (if there is one)
	;
	LocalCmpChar	ds:[si], '+'	; Check for positive exponent sign
	je	skipExponentSign	; Branch if sign exists
	LocalCmpChar	ds:[si], '-'	; Check for negative exponent sign
	jne	scanExponentValue	; Branch if sign doesn't exist
skipExponentSign:
	LocalNextChar	dssi		; Skip past the sign
	call	SkipWhiteSpace		; Skip any white space
scanExponentValue:
	;
	; Skip any number of digits.
	;
	LocalGetChar	ax, dssi, NO_ADVANCE	; Get 1st char of exponent value
	call	IsDigit			; Is it a digit?
	jnc	badNumber		; Branch if not a digit
	call	SkipDigits		; si <- ptr past the digits
finish:
	;
	; Finish up. si points past the end of the number.
	;
	mov	ss:[bx].ST_type, SCANNER_TOKEN_NUMBER
	;;; Here's where we call the conversion routine.
	;;; I expect it will take:
	;;;	ds:si	= Pointer to the text of the number
	;;;	cx	= # of characters in the text to parse
	;;;	es:di	= Place to put the number
	push	si, di, es
	mov	cx, si			; cx <- pointer past number end
	sub	cx, dx			; cx <- length of number
DBCS<	shr	cx, 1			; cx <- byte count (size)	>
	
	mov	si, dx			; si <- ptr to the start
	
	segmov	es, ss			; es <- seg addr for result
	mov	di, bx			; di <- ptr to place to put result
	add	di, offset ST_data + offset STND_value
	;
	; es:di = ptr to place to put the result
	; ds:si = ptr to the text of the number
	; cx	= # of characters in the number
	;
	mov	ax, mask FAF_STORE_NUMBER
	call	FloatAsciiToFloat
	pop	si, di, es
	jc	badNumber		; Branch if error
quit:
	.leave
	ret

badNumber:
	;
	; Signal an error because the exponent wasn't specified correctly
	;
	mov	al, PSEE_BAD_NUMBER
	call	ScannerReportError
	jmp	quit

ScanNumericConstant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipDigits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip over zero or more digits

CALLED BY:	ScanNumericConstant
PASS:		ds:si	= Pointer to text
RETURN:		ds:si	= Pointer past any digits
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipDigits	proc	near
	uses	ax
	.enter
	;
	; Skip until we find something other than a digit
	;
leftDigitLoop:
	LocalGetChar	ax, dssi, NO_ADVANCE	; al <- next character
	call	IsDigit			; Skip the digits
	jnc	done			; Branch if no more digits

	LocalNextChar	dssi			; Skip to next character
	jmp	leftDigitLoop		; Loop to skip it
done:
	.leave
	ret
SkipDigits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanStringConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a string constant from the input stream.

CALLED BY:	Scan token
PASS:		ds:si	= Pointer to the text to scan
		ss:bx	= Place to put the scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Scan until the matching close-quote was found.
	Store the offset to the start of the string and the length of the
	  string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanStringConstant	proc	near
	uses	ax, dx
	.enter
	;
	; We can't have strings if we can't have operators or functions
	;
	test	ss:[bp].PP_flags, mask PF_OPERATORS or mask PF_FUNCTIONS
	jz	illegalToken

	LocalNextChar	dssi			; Skip past the open quote
	;
	; Store the start of the string.
	;
	mov	ss:[bx].ST_type, SCANNER_TOKEN_STRING
	
	mov	ax, si				; ax <- start of string
	sub	ax, ss:[bp].PP_textPtr.offset	; ax <- offset to string start
EC <	push	ax				;>
EC <	mov	ax, ds				;ax <- seg addr of string>
EC <	cmp	ax, ss:[bp].PP_textPtr.segment	;>
EC <	ERROR_NE PARSE_STRING_SEGMENT_FAILED_ASSERTION >
EC <	pop	ax
						; Save start of string
	mov	ss:[bx].ST_data.STD_string.STSD_start, ax
	;
	; Skip until a close quote is found, then save the length
	;
	mov	dx, si				; Save start of string
stringLoop:
	LocalGetChar	ax, dssi, NO_ADVANCE	; al <- next character

	LocalIsNull	ax			; Check for end of string
	je	noCloseQuoteError		; Branch if null found
	LocalCmpChar	ax, C_BACKSLASH		; Check for escaped character
	je	escapeCharacter			; Branch if it is
	LocalCmpChar	ax, '"'			; Check for an end quote
	je	foundStringEnd			; Branch if it is
nextChar:
	LocalNextChar	dssi			; Skip to next character
	jmp	stringLoop			; Loop to check next char
quit:
	.leave
	ret

foundStringEnd:
	;
	; Found the string end. Save the length.
	; si = pointer to the end-quote.
	; dx = pointer to start of the text.
	;
	mov	ax, si				; ax <- pointer past end
	sub	ax, dx				; ax <- offset past end
DBCS<	shr	ax, 1				; ax <- char count	>
	mov	ss:[bx].ST_data.STD_string.STSD_length,ax ; Save length

	LocalNextChar	dssi			; Skip past end-quote
	clc					; Signal: no error
	jmp	quit				; Quit

escapeCharacter:
	;
	; Found an escape character. Skip the following character, unless
	; it's a NULL, in which case we signal an error.
	;
	LocalNextChar	dssi			; Skip the escape char
	LocalIsNull	ds:[si]			; Check for NULL
	jne	nextChar			; Skip following character
	;;; Fall thru to report an error

noCloseQuoteError:
	;
	; The end of the text was encountered before a NULL was found.
	;
	mov	al, PSEE_NO_CLOSE_QUOTE
	call	ScannerReportError
	jmp	quit

illegalToken:
	;
	; Strings are not allowed in this parser.
	;
	mov	al, PSEE_ILLEGAL_TOKEN
	call	ScannerReportError
	jmp	quit
ScanStringConstant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCellReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a cell reference from the input stream

CALLED BY:	ScanToken
PASS:		ds:si	= Pointer to text to scan
		ss:bx	= Pointer to place to put scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set if it wasn't a cell reference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	A cell reference is of the form [$][a-zA-Z](1-3)[$][0-9](1-5)
	That is to say:
		Optional $ character (signaling absolute column reference)
		1-3 characters (column reference)
		Optional $ character (signaling absolute row reference)
		1-5 digits (row reference
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Calls IsBaseAlpha for strict Latin letters, which is a cell column.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version
	witt	10/21/93	DBCS-ized keeping syntax.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanCellReference	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	test	ss:[bp].PP_flags, mask PF_CELLS
	LONG jz illegalToken		; Branch if cells aren't allowed

	mov	ss:[bx].ST_type, SCANNER_TOKEN_CELL
	mov	di, bx			; Need bx for scratch, so we
					;   save the pointer into di.
	mov	ss:[bx].ST_data.STD_cell.STCD_cellRef.CR_column, 0
	mov	ss:[bx].ST_data.STD_cell.STCD_cellRef.CR_row, 0

	LocalCmpChar	ds:[si], '$'	; Check for absolute column reference
	jne	checkColumn		; Branch if relative reference
	or	ss:[bx].ST_data.STD_cell.STCD_cellRef.CR_column,
						mask CRC_ABSOLUTE
	LocalNextChar	dssi		; Skip past the '$'
checkColumn:
	clr	ax			; The current column reference
	clr	bx			; The amount to add
	mov	cx, 3			; Max 3 characters of column
columnLoop:
	push	ax			; Save current column
	LocalGetChar	bx, dssi, NO_ADVANCE	; bl <- next character
SBCS<	mov	al, bl			; Pass in al			>
DBCS<	mov	ax, bx			; Pass in ax			>
	call	IsBaseAlpha		; Check is [a-zA-Z]
	pop	ax			; Restore current column
	jnc	afterColumn		; Branch if no more column reference
	;
	; Convert it to upper case and subtract to get the offset
	;
	mov	dx, 26			; We're in base 26 here
	mul	dx			; Update the column reference
	LocalCmpChar	bx, 'a'		; Check for lower case
	jb	addInColumn		; Add in the column
SBCS<	sub	bl, ('a' - 'A')		; Force to A-Z			>
DBCS<	sub	bx, ('a' - 'A')		; Force to A-Z			>
addInColumn:
SBCS<	sub	bl, 'A'			; bx <- 0...25	>
DBCS<	sub	bx, 'A'			; bx <- 0...25	>
	inc	bl			; bx <- 1...26
	add	ax, bx			; ax <- current column reference
	LocalNextChar	dssi		; Skip to next character
	loop	columnLoop		; Loop to do the next one
afterColumn:
	;
	; Now we may or may not have found a column reference. Check cx.
	; If it still contains "3" then we haven't found any column reference
	;
	cmp	cx, 3			; Check for no column reference
	LONG je	noColumnError		; Branch if no column
	
	;
	; There was a column, ax holds the column value.
	;
	dec	ax			; Change from (1->n) to (0->n-1)

	cmp	ax, ss:[bp].CP_maxColumn
	LONG ja	columnTooLargeError	; Branch if column value too large

	or	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_column, ax
	;
	; Scan the row... Very similar to scanning a column, but a little
	; easier since we're in base 10.
	;
	LocalCmpChar	ds:[si], '$'	; Check for absolute row reference
	jne	checkRow		; Branch if relative reference
	or	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row,
						mask CRC_ABSOLUTE
	LocalNextChar	dssi		; Skip past the '$'

checkRow:
	clr	ax			; The current row reference
	clr	bx			; The amount to add
	mov	cx, 5			; Max # of digits
rowLoop:
	push	ax			; Save current row
	LocalGetChar	bx, dssi, NO_ADVANCE	; bl <- next digit
SBCS<	mov	al, bl			; Pass in al	>
DBCS<	mov	ax, bx			; Pass in al	>
	call	IsDigit			; Check for a digit
	pop	ax			; Restore current row
	jnc	afterRow		; Branch if not a digit
	
	mov	dx, 10			; Base 10
	mul	dx			; ax <- old value * 10
	sub	bl, '0'			; bl <- 0...9
	add	ax, bx			; ax <- new value
	LocalNextChar	dssi		; Move to next character
	loop	rowLoop			; Loop to do next one
afterRow:
	;
	; Check to see if we actually found a row
	;
	cmp	cx, 5			; If cx == 5, no row was found
	je	noRowError		; Branch if no row
	
	tst	ax			; Check for row == 0, (which is bad)
	jz	zeroRowError		; Branch if no good

	;
	; The user refers to rows by 1->max_row+1 but internally we use
	; 0->max_row-1.
	;
	dec	ax			; Change from (1->n) to (0->n-1)

	cmp	ax, ss:[bp].CP_maxRow	; Check for row too large
	ja	rowTooLargeError	; Branch if no good
	;
	; Save the row
	;
	or	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row, ax
	;
	; Now make the row/column into offsets if they are relative references
	;
	test	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_column,
						mask CRC_ABSOLUTE
	jnz	checkRowRelative	; Branch if column is absolute
	;
	; Subtract off the current column
	;
	mov	ax, ss:[bp].CP_column
	mov	cx, ss:[di].ST_data.STD_cell.STCD_cellRef.CR_column
	sub	cx, ax
	and	cx, mask CRC_VALUE
	and	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_column, \
						not mask CRC_VALUE
	or	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_column, cx
checkRowRelative:

	test	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row, \
						mask CRC_ABSOLUTE
	jnz	rowNotRelative		; Branch if row is absolute
	;
	; Subtract off the current row
	;
	mov	ax, ss:[bp].CP_row
	mov	cx, ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row
	sub	cx, ax
	and	cx, mask CRC_VALUE
	and	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row, not mask CRC_VALUE
	or	ss:[di].ST_data.STD_cell.STCD_cellRef.CR_row, cx
rowNotRelative:
	clc				; Signal: no error
done:
	.leave
	ret

illegalToken:
	mov	al, PSEE_ILLEGAL_TOKEN
	jmp	cellError

columnTooLargeError:
	mov	al, PSEE_COLUMN_TOO_LARGE
	jmp	cellError

rowTooLargeError:
	mov	al, PSEE_ROW_TOO_LARGE
	jmp	cellError

zeroRowError:
noRowError:
noColumnError:
	mov	al, PSEE_BAD_CELL_REFERENCE

cellError:
	call	ScannerReportError
	jmp	done

ScanCellReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanRangeSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a range separator from the input stream

CALLED BY:	ScanToken
PASS:		al/ax	= First character of the range separator
		ds:si	= Pointer to text to scan
		ss:bx	= Pointer to place to put scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if al == : then
	    advance pointer
	    just return that we have encountered a separator
	else if al == . then
	    skip as many consecutive .'s as there are
	    return that we have encountered a separator
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanRangeSeparator	proc	near
	test	ss:[bp].PP_flags, mask PF_CELLS
	jz	illegalToken		; Branch if cells not allowed

	LocalNextChar	dssi		; Skip past separator

	LocalCmpChar	ax, ':'		; One type of separator
	je	done			; Branch if this type of separator
periodLoop:
	LocalCmpChar	ds:[si], '.'	; Check for a sequence of .s
	jne	done			; Quit if no more periods
	LocalNextChar	dssi		; Skip to next character
	jmp	periodLoop		; Loop to skip another if needed
done:
	mov	ss:[bx].ST_type, SCANNER_TOKEN_OPERATOR
	mov	ss:[bx].ST_data.STD_operator.STOD_operatorID,OP_RANGE_SEPARATOR
	clc				; Signal: no error
quit:
	ret

illegalToken:
	mov	al, PSEE_ILLEGAL_TOKEN
	call	ScannerReportError
	jmp	quit
ScanRangeSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanParserRangeIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a range intersection operator

CALLED BY:	ScanToken
PASS:		al	= First character of the range separator
		ds:si	= Pointer to text to scan
		ss:bx	= Pointer to place to put scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanParserRangeIntersection	proc	near
	test	ss:[bp].PP_flags, mask PF_CELLS
	jz	illegalToken		; Branch if cells not allowed
	
	inc	si			; Move to next character

	mov	ss:[bx].ST_type, SCANNER_TOKEN_OPERATOR
	mov	ss:[bx].ST_data.STD_operator.STOD_operatorID, \
				OP_RANGE_INTERSECTION

	clc				; Signal: no error
quit:	
	ret

illegalToken:
	mov	al, PSEE_ILLEGAL_TOKEN
	call	ScannerReportError
	jmp	quit
ScanParserRangeIntersection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanIdentifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan an identifier from the input stream

CALLED BY:	ScanToken
PASS:		ds:si	= Pointer to text to scan
		ss:bx	= Pointer to place to put scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Skip any of the following:
		a-Z A-Z 0-9 _

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanIdentifier	proc	near
	uses	ax, cx, dx, di
	.enter
EC <	push	ax				;>
EC <	mov	ax, ds				;ax <- seg addr of string>
EC <	cmp	ax, ss:[bp].PP_textPtr.segment	;>
EC <	ERROR_NE PARSE_STRING_SEGMENT_FAILED_ASSERTION >
EC <	pop	ax
	call	FindIdentifierLength	; cx <- length of the identifier
	;
	; A length of zero indicates that the identifier is illegal.
	;
	jcxz	illegalToken

	mov	ss:[bx].ST_type, SCANNER_TOKEN_IDENTIFIER
	mov	ax, si			; ax <- start of the identifier
	sub	ax, ss:[bp].PP_textPtr.offset
	mov	ss:[bx].ST_data.STD_identifier.STID_start, ax	; byte offset

	add	si, cx			; Move to the end of the string
DBCS<	add	si, cx			; Char offset to byte offset	>
	clc				; Signal: no error
quit:
	.leave
	ret

illegalToken:
	mov	al, PSEE_ILLEGAL_TOKEN
	call	ScannerReportError
	jmp	quit
ScanIdentifier	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindIdentifierLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the length of an identifier

CALLED BY:	ScanIdentifier
PASS:		ds:si	= Pointer to the text
RETURN:		cx	= Length of the text (glyph count)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindIdentifierLength	proc	far
SBCS <	uses	ax, dx							>
DBCS <	uses	ax, bx, dx						>
	.enter
	mov	dx, si			; dx <- pointer to start of string
SBCS<	clr	ah			; Clear this for LocalIsAlpha	>
scanLoop:
	LocalGetChar	ax, dssi, NO_ADVANCE	; al <- next character
	LocalCmpChar	ax, '_'		; Underscores are valid
	je	nextCharacter		; Branch if it is
	call	IsDigit			; Digits are valid
	jc	nextCharacter		; Branch if it is
if DBCS_PCGEOS
	mov	bx, ax			; bx = char
	call	LocalGetWordPartType	; ax = WordPartType
	xchg	ax, bx			; ax = char, bx = WPT
	cmp	bx, WPT_OTHER
	je	foundEnd
	cmp	bx, WPT_PUNCTUATION
	je	foundEnd
	cmp	bx, WPT_SPACE
	je	foundEnd
else
	call	LocalIsAlpha		; Check for valid character
endif
	jz	foundEnd		; Branch if it is not
nextCharacter:
	LocalNextChar	dssi		; Move to next character
	jmp	scanLoop		; Loop to check next one
foundEnd:
	;
	; dx = start of string
	; si = end of string
	;
	mov	cx, si			; cx <- length of string
	sub	cx, dx
DBCS<	shr	cx, 1			; cx <- char count		>
	mov	si, dx			; Restore ptr to string start
	.leave
	ret
FindIdentifierLength	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanEndOfExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the end-of-expression token into the stream

CALLED BY:	ScanToken
PASS:		ds:si	= Pointer to text
		ss:bx	= Pointer to place to put scanned token
		ss:bp	= Pointer to ParserParameters
RETURN:		ds:si	= Pointer past the scanned text
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanEndOfExpression	proc	near
	mov	ss:[bx].ST_type, SCANNER_TOKEN_END_OF_EXPRESSION
	clc				; Signal: no error
	ret
ScanEndOfExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip white space in the input stream

CALLED BY:	ScanToken
PASS:		ds:si	= Pointer to text
RETURN:		ds:si	= Pointer past white space
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipWhiteSpace	proc	near	uses	ax
	.enter

	; Loop around skipping over spaces
if DBCS_PCGEOS
	;	Does same as SBCS below, but uses LocalIsSpace() instead
	;	of local compares..
skipLoop:
	LocalGetChar	ax, dssi, NO_ADVANCE
	call	LocalIsSpace
	je	done
	LocalNextChar	dssi			; skip that "space"
	jmp	skipLoop

else
skipLoop:
	mov	al, ds:[si]
	cmp	al, ' '				; Check for a space
	je	whitespace			; Branch if a space
	cmp	al, C_CR			; Check for a CR
	je	whitespace			; Branch if so
	cmp	al, C_TAB			; Check for a tab
	jne	done				; Branch if NOT a tab
whitespace:
	inc	si				; Skip past the space
	jmp	skipLoop			; Loop to check next char
endif

done:
	.leave
	ret
SkipWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsDigit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is a digit

CALLED BY:	ScanToken
PASS:		al	= Character to check
RETURN:		carry set if the character is a digit
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsDigit	proc	near
	LocalCmpChar	ax, '0'		; Check for below 0
	jb	notDigit		; Branch if it is
	LocalCmpChar	ax, '9'		; Check for above 9
	ja	notDigit		; Branch if it is
	
	stc				; Signal: is a digit
done:
	ret

notDigit:
	clc				; Signal: is not a digit
	jmp	done
IsDigit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is an operator

CALLED BY:	ScanToken
PASS:		al	= Character to check
		ds:si	= Pointer to where al came from
		ss:bx	= Place to put the token if the character is
		ss:bp	= inherited ParserParameters
RETURN:		carry set if the character is an operator
		    ds:si advanced past the character
		carry clear otherwise
		    ds,si unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Need to check 2 character operators, then 1 character operators

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	DBCS:  Assumes chars in operatorTable2 are all ASCII.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version
	witt	10/20/93	Rewrote strategy for DBCS (uugh)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsOperator	proc	near
	uses	ax, cx, dx, es, di
	.enter
	
	test	ss:[bp].PP_flags, mask PF_OPERATORS
	jz	doneNotOperator		; branch if operators not allowed

NOFXIP<	segmov	es, dgroup, cx		; es = dgroup			>
FXIP <	mov	cx, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES		; es = dgroup			>
FXIP <	mov	bx, cx			; restore bx			>

if DBCS_PCGEOS
	;	Build a character pair in ahal.  Since table of operator
	;	pairs must be ASCII, we can compress the two chars down
	;	to a byte each, then use 'scasw', which is fast.  If either
	;	char to compare has a high byte non-zero, it is Unicode
	;	unique, and thus can't match anything from OperatorTable2.
	;
	mov	cx, ds:[si][2]		; Get 2nd character
	tst	ch
	jnz	doneNotOperator2

	tst	ah			; 1st char is passed parameter.
	jnz	doneNotOperator2

	mov	ah, cl			; make AH AL char pair to search for
else
	mov	ah, ds:[si][1]		; Get 2nd character
endif

	;
	; Check the 2 character operators first.
	;
	mov	di, offset operator2Table
	mov	cx, size operator2Table / 2  ; cx <- size of the table (words)
	repne	scasw			; Find one
	jne	doneNotOperator2	; Branch if none found
	;
	; Found an operator, advance the pointer, save the operator type.
	;
if DBCS_PCGEOS
	add	si, 4			; Skip operator
else
	add	si, 2			; Skip operator
endif

	sub	di, (offset operator2Table) + 2
	shr	di, 1			; Offset into byte sized table
	mov	al, es:operator2IDTable[di]
	jmp	saveOperator		; Save operator ID
doneNotOperator2:
	;
	; Check the 1 character operators next.
	;
	mov	cx, length operatorTable
	mov	di, offset operatorTable
DBCS<	mov	ax, ds:[si]		; reload - could be Unicode unique  >
	LocalFindChar			; Find one
	jne	doneNotOperator		; Branch if none found
	;
	; Found an operator, advance the pointer, save the operator type.
	;
	LocalNextChar	dssi

if DBCS_PCGEOS
	sub	di, (offset operatorTable) + (size wchar)
	shr	di, 1			; di <- index into OperatorIDTable[]
CheckHack< ((size wchar) eq 2) and ((size OperatorType) eq 1) >
else
	sub	di, (offset operatorTable) + (size char)
endif
	mov	al, es:operatorIDTable[di]
saveOperator:
	mov	ss:[bx].ST_type, SCANNER_TOKEN_OPERATOR
	mov	ss:[bx].ST_data.STD_operator.STOD_operatorID, al
	stc				; Signal: Found an operator
	jmp	quit			; Quit

doneNotOperator:
	clc				; Signal: Not an operator
quit:
	.leave
	ret
IsOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character belongs to the set of "other"
		characters.

CALLED BY:	ScanToken
PASS:		al/ax	= Character to check
		ds:si	= Pointer to where al came from
		ss:bx	= Place to put the token if the character is
RETURN:		carry set if the character belongs to that set
		    ds:si advanced past the character
		carry clear otherwise
		    ds,si unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if char is "(" or ")" or ListSeperator then
		advance ds:si.
		return carry set, scanner token.
	else
		return carry clear.
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsOther	proc	near
	uses	cx
	.enter
	mov	cl, SCANNER_TOKEN_OPEN_PAREN
	LocalCmpChar	ax, '('		; Check open-paren
	je	doneIsOther		; Branch if it is

	mov	cl, SCANNER_TOKEN_CLOSE_PAREN
	LocalCmpChar	ax, ')'		; Check close-paren
	je	doneIsOther

	mov	cl, SCANNER_TOKEN_LIST_SEPARATOR
	call	CheckListSeparator
	je	doneIsOther

	clc				; Signal: Character was not processed
	jmp	quit			; Quit

doneIsOther:
	mov	ss:[bx].ST_type, cl	; Save the token type
	LocalNextChar	dssi		; Skip the character
	stc				; Signal: Character was processed

quit:
	.leave
	ret
IsOther	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsBaseAlpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is a base-alpha (a-z A-Z)

CALLED BY:	ScanCellReference
PASS:		al	= Character to check
RETURN:		carry set if the character is a-z A-Z
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Industry standard Cell references use Latin (US) letters
		only for row indicators.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsBaseAlpha	proc	near
DBCS<	tst	ah			; Does char have Unicode high-byte? >
DBCS<	jnz	notBaseAlpha		; sign, unique Unicode won't match  >

	cmp	al, 'A'			; Check for below A
	jb	notBaseAlpha		; Branch if it is
	cmp	al, 'Z'			; Check for below Z
	jbe	isBaseAlpha		; Branch if it is
	
	cmp	al, 'a'			; Check for below a
	jb	notBaseAlpha		; Branch if it is
	cmp	al, 'z'			; Check for above z
	ja	notBaseAlpha		; Branch if it is
isBaseAlpha:
	stc				; Signal: is a base alpha
done:
	ret

notBaseAlpha:
	clc				; Signal: is not a base alpha
	jmp	done
IsBaseAlpha	endp



if DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseCmpStringsDBCSToSBCSNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings, one in DBCS form, the other in SBCS,
		for case-innsensitive equality.  Pass in length of strings
		to compare.  A non-ASCII char means immediate non-equality.
		Returns zero/non-zero flags

CALLED BY:	IsFunction (INTERNAL)
PASS:		ds:si	= DBCS string
		es:di	= ASCII string
		cx	= # of characters (Unicode count)
RETURN:		Zero/Non-zero flag for equal/not equal
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For each char,
			if next DBCS is not ASCII, then
				return not equal.
			if case insensitve char compare => not equal
				return not equal.
		Return equal.

COMMENTS/NOTES:
		* Uses LocalCmpChars() since chars will be ASCII.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	10/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseCmpStringsDBCSToSBCSNoCase	proc	far
	uses	bx, cx, si, di
	.enter

	clr	bh
compareLoop:
	lodsw				; fetch Unicode char
	mov	bl, {char} es:[di]	; fetch ASCII char
	tst	ah			; non-ASCII Unicode?
	jnz	done			; sigh, those never match..

	xchg	bx, cx			; cx = dest char; hide count
	call	LocalCmpCharsNoCase	; ax = src char
	jnz	done

	mov	cx, bx			; restore count.
	inc	di			; next ASCII char
	loop	compareLoop
	tst	cx			; ZF <- Equal.
done:
	.leave
	ret
ParseCmpStringsDBCSToSBCSNoCase	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScannerReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal a scanner error

CALLED BY:	Utility
PASS:		al	= ScannerReportError
		ss:bp	= Pointer to ParserParameters
RETURN:		carry set always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Set the error bit.
	Save the error code.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScannerReportError	proc	near
	mov	ss:[bp].PP_error, al
	stc
	ret
ScannerReportError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDecimalPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a character is the decimal point

CALLED BY:	UTILTY
PASS:		al - character to check
RETURN:		z flag - set (jz) if decimal point
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDecimalPoint		proc	near
	uses	dx, ds
	.enter


NOFXIP<	segmov	ds, <segment idata>, dx		; ds = dgroup		>
FXIP <	mov	dx, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS		; ds = dgroup			>
FXIP <	mov	bx, dx							>
	LocalCmpChar	ax, ds:decimalSep		;set z flag if decimal

	.leave
	ret
CheckDecimalPoint		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckListSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a character is a list separator

CALLED BY:	UTILTY
PASS:		al - character to check
RETURN:		z flag - set (jz) if list separator
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckListSeparator		proc	near
	uses	dx, ds
	.enter

NOFXIP< segmov	ds, <segment idata>, dx		;ds = dgroup		>
FXIP <	mov	dx, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS		; ds = dgroup			>
FXIP <	mov	bx, dx							>
	LocalCmpChar	ax, ds:listSep			;set z flag if separator
	.leave
	ret
CheckListSeparator		endp

Scanner		ends
