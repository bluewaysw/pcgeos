COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Parser Library
FILE:		parseFormat.asm

AUTHOR:		John Wedgwood, Jan 24, 1991

ROUTINES:
	Name			Description
	----			-----------
GLBL	ParserFormatExpression	Format a parsed expression
GLBL	ParserFormatColumnReference	Format a 0-based column reference (eg. 27='AB')
GLBL	ParserFormatRowReference	Format a 0-based row reference (eg. 27='28')
GLBL	ParserFormatWordConstant	Format a word constant (eg. 27='27')

INT	FormatNumber		Format a number
INT	FormatString		Format a string
INT	FormatCellReference	Format a cell reference
INT	FormatColumnRef		Format a column reference
INT	FormatBase10Number	Format a base-10 number
INT	FOrmatFunction		Format a function
INT	FormatEndOfExpression	NULL-terminate end of expression
INT	FormatOpenParen		Add open-parenthesis to output
INT	FormatCloseParen	Add close-parenthesis to output
INT	FormatName		Format a name
INT	FormatArgEnd		Add "," to output if necessary
INT	FormatOperator		Format an operator

INT	FormatWriteString	Output string of characters
INT	FormatWriteSBString	Output Single-byte string of characters
INT	FormatWriteChar		Output single character
INT	CheckReferenceBounds	Check to see if cell reference is legal
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/24/91	Initial revision
	witt	11/ 8/93	DBCS-ized, FP_nChars is glyph count.

DESCRIPTION:

	DBCS:  In line with the "minimal change" mantra, if a routine
		is commented with taking a "buffer size" or a "# chars,"
		they are left as as, and the caller adjusts whatever
		value is passed in.
	DBCS:  The field FP_nChars is a glyph count (length), and the code
		has been changed accordingly.
	

	$Id: parseFormat.asm,v 1.1 97/04/05 01:27:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatCode	segment	resource

SBCS< FormatWriteSBString   equ    FormatWriteString	; function equate   >


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format an expression into a string

CALLED BY:	Global
PASS:		ds:si	= Pointer to the parsed expression
		es:di	= Pointer to the place to put the text
		ss:bp	= Pointer to FormatParameters
RETURN:		cx	= length of the text (not including the NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserFormatExpression	proc	far
	uses	ax, bx, si, di
	.enter
	;
	; Make sure the callback routine is in a reasonable place.
	;
if	FULL_EXECUTE_IN_PLACE
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, ss:[bp].CP_callback			>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
else
EC <	push	es, di				>
EC <	mov	es, ss:[bp].CP_callback.segment	>
EC <	mov	di, ss:[bp].CP_callback.offset	>
EC <	call	ECCheckPointerESDI		>
EC <	pop	es, di				>
endif

	push	di			; Save start of text

	dec	ss:[bp].FP_nChars	; Save 1 character for the NULL
tokenLoop:
EC <	call	ECCheckPointer			>
EC <	call	ECCheckPointerESDI		>

	clr	ah
	lodsb				; ax <- type of the token
EC <	cmp	al, ParserTokenType			>
EC <	ERROR_AE FORMAT_ILLEGAL_PARSER_TOKEN_TYPE	>

	mov	bx, ax			; bx <- index into list of token
	shl	bx, 1			;    handlers
	call	cs:tokenHandlerTable[bx]
	
	cmp	al, PARSER_TOKEN_END_OF_EXPRESSION
	jne	tokenLoop		; Loop to do the next one

	pop	cx			; Restore start of text
	sub	di, cx			; di <- size of text
DBCS<	shr	di, 1			; di <- length of text		>
	mov	cx, di			; cx <- length of text
	dec	cx			; Don't count the NULL
	.leave
	ret
ParserFormatExpression	endp

;
; This table of token handlers must be ordered the same as the enum
; ParserTokenType.
;
tokenHandlerTable	word	\
	offset	cs:FormatNumber,
	offset	cs:FormatString,
	offset	cs:FormatCellReference,
	offset	cs:FormatEndOfExpression,
	offset	cs:FormatOpenParen,
	offset	cs:FormatCloseParen,
	offset	cs:FormatName,
	offset	cs:FormatFunction,
	offset	cs:FormatCloseParen,		; For CLOSE_FUNCTION
	offset	cs:FormatArgEnd,
	offset	cs:FormatOperator


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a floating point number

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to a ParserTokenNumericConstantData structure
		es:di	= Place to put formatted number
RETURN:		ds:si	= Pointer to start of next token
		es:di	= Pointer past the formatted number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatNumber	proc	near
	uses	ax, bx, cx, dx, bp
	.enter
SBCS<	sub	sp, MAX_CHARS_FOR_NORMAL_NUMBER+1	>
DBCS<	sub	sp, (MAX_CHARS_FOR_NORMAL_NUMBER+1)*(size wchar) 	>
	mov	bx, sp			; ss:bx <- ptr to the buffer

	push	ds, si			; Save ptr to the token stream

	push	es, di, bx		; Save ptr to place to put text
	segmov	es, ss			; es:di <- ptr to our internal buffer
	mov	di, bx
	
	mov	ax, mask FFAF_FROM_ADDR or mask FFAF_NO_TRAIL_ZEROS
	mov	bh, DECIMAL_PRECISION
	mov	bl, DECIMAL_PRECISION - 1
	call	FloatFloatToAscii_StdFormat	; cx <- length
	;
	; The formatted number is now in our local buffer. We need to write it
	; to the output string.
	;
	pop	es, di, bx		; Restore ptr to the output string

	segmov	ds, ss			; ds:si <- ptr to formatted string
	mov	si, bx
	call	FormatWriteString	; Write the data out
	pop	ds, si			; Restore ptr to the token stream

	add	si, size ParserTokenNumberData
SBCS<	add	sp, MAX_CHARS_FOR_NORMAL_NUMBER+1			>
DBCS<	add	sp, (MAX_CHARS_FOR_NORMAL_NUMBER+1)*(size wchar) 	>
	.leave
	ret
FormatNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a text string

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to a ParserTokenStringConstantData structure
		es:di	= Place to put formatted string
RETURN:		ds:si	= Pointer to start of next token
		es:di	= Pointer past the formatted string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatString	proc	near
	uses	ax, cx
	.enter
	LocalLoadChar	ax, '"'
	call	FormatWriteChar		; Write the open-quote

	mov	cx, ds:[si].PTSD_length	; cx <- length of the string
	;
	; Advance pointer to get to the start of the string
	;
	add	si, size ParserTokenStringData
	call	FormatWriteString	; Write the string

	LocalLoadChar	ax, '"'
	call	FormatWriteChar		; Write the close-quote
DBCS<	shl	cx, 1			; cx <- string size		>
	add	si, cx			; Skip the string data
	.leave
	ret
FormatString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatCellReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell reference

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to a ParserTokenCellData structure
		es:di	= Place to put formatted cell reference
		ss:bp	= Pointer to FormatParameters
RETURN:		ds:si	= Pointer to start of next token
		es:di	= Pointer past the formatted cell reference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatCellReference	proc	near
	uses	ax, bx, cx
	.enter
	;
	; Check for a reference outside the bounds of the spreadsheet.
	;
	call	CheckReferenceBounds	; Check for out of bounds
	jc	refOutOfBounds		; Branch if reference out of bounds

	;
	; Check for absolute column reference.
	;
	mov	bx, ss:[bp].CP_column	; Assume relative reference
	test	ds:[si].PTCD_cellRef.CR_column, mask CRC_ABSOLUTE
	jz	skipAbsColumn		; Branch if relative
	LocalLoadChar	ax, '$'			; Mark column as absolute
	call	FormatWriteChar		; Write the character
	clr	bx			; No adjustment needed
skipAbsColumn:
	;
	; Write out the column in the form "AAA".
	;
	mov	ax, ds:[si].PTCD_cellRef.CR_column
	
	and	ax, mask CRC_VALUE
	shl	ax, 1			; Sign extend it into the high bit
	sar	ax, 1

	;
	; The column is in the form 0->max_column-1, to format it we need it in
	; the form 1->max_column.
	;
	inc	ax

	add	ax, bx			; Adjust for relative position
	call	FormatColumnRef		; Format the number
	;
	; Check for absolute row reference.
	;
	mov	bx, ss:[bp].CP_row	; Assume relative reference
	test	ds:[si].PTCD_cellRef.CR_row, mask CRC_ABSOLUTE
	jz	skipAbsRow		; Branch if relative
	LocalLoadChar	ax, '$'			; Mark row as absolute
	call	FormatWriteChar		; Write the character
	clr	bx			; No adjustment needed
skipAbsRow:
	;
	; Write out the row. A 5 digit base-10 number with no leading zeros.
	;
	mov	ax, ds:[si].PTCD_cellRef.CR_row
	
	and	ax, mask CRC_VALUE
	shl	ax, 1			; Sign extend it into the high bit
	sar	ax, 1

	;
	; The row is in the form 0->max_row-1, we need it in the form
	; 1->max_row.
	;
	inc	ax

	add	ax, bx			; Adjust for relative position
	call	FormatBase10Number	; Format the number
quit:
	add	si, size ParserTokenCellData
	.leave
	ret

refOutOfBounds:
	push	ds, si			; Save ptr
	segmov	ds, cs, si		; ds:si <- string pointer
	mov	si, offset cs:badRefString
	mov	cx, length badRefString
	call	FormatWriteSBString	; Write the string
	pop	ds, si			; Restore ptr
	jmp	quit			; Finish up.
FormatCellReference	endp

badRefString	char	"#REF#"		; always use SBCS.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckReferenceBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that a cell reference isn't out of bounds.

CALLED BY:	FormatCellReference
PASS:		ds:si	= Pointer to ParserTokenCellData structure
		ss:bp	= Pointer to FormatParameters
RETURN:		carry set if the reference is out of bounds
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckReferenceBounds	proc	near
	uses	ax
	.enter
	;
	; Check the column
	;
	mov	ax, ds:[si].PTCD_cellRef.CR_column
	
	and	ax, mask CRC_VALUE
	shl	ax, 1			; Sign extend it into the high bit
	sar	ax, 1
	
	test	ds:[si].PTCD_cellRef.CR_column, mask CRC_ABSOLUTE
	jnz	gotColumn		; Branch if absolute reference
	
	add	ax, ss:[bp].CP_column	; Adjust for relative reference
gotColumn:

	cmp	ax, ss:[bp].CP_maxColumn
	ja	outOfBounds
	
	;
	; Check the row
	;
	mov	ax, ds:[si].PTCD_cellRef.CR_row
	
	and	ax, mask CRC_VALUE
	shl	ax, 1			; Sign extend it into the high bit
	sar	ax, 1
	
	test	ds:[si].PTCD_cellRef.CR_row, mask CRC_ABSOLUTE
	jnz	gotRow			; Branch if absolute reference
	
	add	ax, ss:[bp].CP_row	; Adjust for relative reference
gotRow:

	cmp	ax, ss:[bp].CP_maxRow
	ja	outOfBounds

	clc				; Neither is out of bounds
quit:
	.leave
	ret

outOfBounds:
	stc				; Signal: Out of bounds
	jmp	quit
CheckReferenceBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatColumnReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a column reference in the form "AB"
CALLED BY:	EXTERNAL

PASS:		ax - column number to format (0-based)
		es:di - ptr to buffer
		cx - size of buffer
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserFormatColumnReference	proc	far
	uses	ax, bp, di
	.enter

	sub	sp, (size FormatParameters)

	mov	bp, sp				;ss:bp <- FormatParameters
DBCS<	shr	cx, 1				;cx <- string length	  >
DBCS< EC<  ERROR_C  ODDSIZED_DBCS_STRING 	; odd size string buffer  > >

	mov	ss:[bp].FP_nChars, cx
	inc	ax				;ax <- make 1-based
	call	FormatColumnRef
	call	FormatEndOfExpression		;NULL-terminate

	add	sp, (size FormatParameters)

	.leave
	ret
ParserFormatColumnReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatColumnRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a column reference in the form "AAA"

CALLED BY:	FormatCellReference
PASS:		ax	= Column number (1-based)
		es:di	= Place to put the text
		ss:bp	= ptr to FormatParameters
RETURN:		es:di	= Pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	nDigits = 0
	while (column != 0) do
	    column&digit = column/26		(Divide and save remainder)

	    if (digit == 0) then		(Check remainder)
		value = 26
		if (column != 0) then
		    column--
		endif
	    endif
	    nDigits++
	    save digit
	end
	
	while (nDigits--) do
	    restore digit
	    write (digit + 'A' - 1)
	end

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatColumnRef	proc	near
	uses	ax, cx, dx, si
	.enter
	clr	si			; si <- # of digits
	mov	cx, 26			; cx <- amount to divide by
digitLoop:
	tst	ax			; Check for no more digits
	jz	writeDigits		; Write what we have if no more
	clr	dx
	div	cx			; dl <- remainder
					; ax <- column / 26
	tst	dl			; Check for zero
	jnz	saveDigit		; Branch if not zero
	mov	dl, 26			; Force to 'Z'
	tst	ax			; Check for zero column
	jz	saveDigit		; Branch if zero
	dec	ax			; Else decrement column
saveDigit:
	;
	; ax = column
	; dl = digit
	; si = # of digits
	;
	inc	si			; One more digit
	push	dx			; Save digit (dh = 0)
	jmp	digitLoop		; Loop to process next one

writeDigits:
	;
	; si = # of digits
	;
	pop	ax			; Restore a digit
	add	al, 'A' - 1		; Force to printable
	call	FormatWriteChar		; Write the byte
	dec	si			; One less digit
	jnz	writeDigits		; Branch to write the next one

	.leave
	ret
FormatColumnRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatWordConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a word constant (aka base-10 number)
CALLED BY:	EXTERNAL

PASS:		ax - number to format
		es:di - ptr to buffer (MAX_REFERENCE_SIZE or larger)
		cx - size of buffer
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Only works for positive numbers...
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserFormatWordConstant	proc	far
	uses	bp, di
	.enter

	sub	sp, (size FormatParameters)

	mov	bp, sp				;ss:bp <- FormatParameters
DBCS<	shr	cx, 1				;cx <- string length	>
DBCS< EC< ERROR_C ODDSIZED_DBCS_STRING		; odd size string buffer > >
	mov	ss:[bp].FP_nChars, cx
	call	FormatBase10Number
	call	FormatEndOfExpression		;NULL-terminate

	add	sp, (size FormatParameters)

	.leave
	ret
ParserFormatWordConstant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatRowReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a row reference (aka base-10 number)
CALLED BY:	EXTERNAL

PASS:		ax - row number to format (0-based)
		es:di - ptr to buffer (MAX_REFERENCE_SIZE or larger)
		cx - size of buffer
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserFormatRowReference	proc	far
	uses	ax, bp, di
	.enter

	sub	sp, (size FormatParameters)

	mov	bp, sp				;ss:bp <- FormatParameters
DBCS<	shr	cx, 1				;cx <- string length	>
DBCS< EC< ERROR_C  ODDSIZED_DBCS_STRING		; odd size str buffer	> >
	mov	ss:[bp].FP_nChars, cx
	inc	ax				;ax <- make 1-based
	call	FormatBase10Number
	call	FormatEndOfExpression		;NULL-terminate

	add	sp, (size FormatParameters)

	.leave
	ret
ParserFormatRowReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatCellReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell reference of the form: AB123
CALLED BY:	EXTERNAL

PASS:		(ax,cx) - (r,c) of cell
		es:di - ptr to buffer (MAX_CELL_REF_SIZE or larger)
RETURN:		es:di - string (NULL-terminated)
		cx - length of string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserFormatCellReference	proc	far
	uses	ax, dx, bp, di
	.enter

EC <	push	ds, si				;>
EC <	segmov	ds, es				;>
EC <	mov	si, di				;ds:si <- ptr to buffer>
EC <	call	ECCheckBounds			;>
EC <	add	si, MAX_CELL_REF_SIZE		;ds:si <- ptr to end of buffer>
EC <	call	ECCheckBounds			;>
EC <	pop	ds, si				;>

	sub	sp, (size FormatParameters)

	mov	bp, sp				;ss:bp <- FormatParameters
SBCS<	mov	ss:[bp].FP_nChars, MAX_CELL_REF_SIZE			>
DBCS<	mov	ss:[bp].FP_nChars, MAX_CELL_REF_SIZE/(size wchar)	>
	push	di
	push	ax				;save row reference
	;
	; Format column
	;
	mov	ax, cx				;ax <- column reference
	inc	ax				;ax <- make 1-based
	call	FormatColumnRef
	;
	; Format row
	;
	pop	ax
	inc	ax				;ax <- make 1-based
	call	FormatBase10Number
	;
	; NULL-terminate the beast
	;
	call	FormatEndOfExpression		;NULL-terminate
	;
	; Figure out the length
	;
	mov	cx, di				;cx <- current offset
	pop	di
	sub	cx, di				;cx <- size of string
DBCS<	shr	cx, 1				;cx <- length of string	>
	dec	cx				;cx <- length (w/o NULL)

	add	sp, (size FormatParameters)

	.leave
	ret
ParserFormatCellReference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserFormatRangeReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell reference of the form: AB123:CD456

CALLED BY:	GLOBAL
PASS:		(ax,cx),
		(dx,bx) - range to format
		es:di - ptr to buffer (MAX_RANGE_REF_SIZE)
RETURN:		cx - length of string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserFormatRangeReference		proc	far
	uses	ax, di
	.enter

	call	ParserFormatCellReference	;cx <- length
	add	di, cx				;es:di <- ptr past text
DBCS<	add	di, cx				;es:di <- DBCS ptr	>
	mov	ax, ':'
	LocalPutChar esdi, ax			;store to es:di & advance
	inc	cx				;cx <- 1 more char
	push	cx				;save length of start
	mov	ax, dx
	mov	cx, bx				;(ax,cx) <- end of range
	call	ParserFormatCellReference
	pop	ax				;ax <- length of start
	add	cx, ax				;cx <- length of whole thing

	.leave
	ret
ParserFormatRangeReference		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatBase10Number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a base-10 number

CALLED BY:	FormatCellReference
PASS:		ax	= Number to format
		es:di	= Place to put the formatted number
		ss:bp	= ptr to FormatParameters
RETURN:		es:di	= Pointer past the formatted number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Both ASCII and Unicode had the decimal digits in the same range,
	and the high byte is zero in both cases.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatBase10Number	proc	near
	uses	ax, bx, cx, dx, si
	.enter
	mov	bh, '0'				; Value to add to make printable
	mov	cx, 10				; Base-10
	clr	si				; # of digits so far
nextDigit:
	cmp	ax, cx				; Check for on top digit
	jb	checkFirstDigit			; Branch to write it

	clr	dx				; dx:ax <- number
	div	cx				; ax <- next number
						; dl <- remainder
	push	dx				; Save the digit (dh = 0)
	inc	si				; Up # of digits found
	jmp	nextDigit			; Loop to get next digit

checkFirstDigit:
	;
	; al = First digit. Now it may be a leading zero, in which case
	;      we only write it if there are no other digits.
	; si = # of digits found
	;
	tst	al				; Check for zero
	jnz	writeFirstDigit			; Branch if not
	;
	; The first digit is a zero, check for a leading zero.
	;
	tst	si				; Check for other digits
	jnz	writeDigits			; Branch if there are some
writeFirstDigit:
	;
	; OK, We want to write the first digit.
	; Push this digit on the stack and up the count of digits to write.
	;
	push	ax				; Save the digit
	inc	si				; One more to save

writeDigits:
	;
	; al = First digit to write.
	; The rest of the digits are on the stack. There are 'si' of them.
	;
	pop	ax				; Grab a digit to write.

	add	al, bh				; Make into a printable value
	call	FormatWriteChar			; Save it

	dec	si				; One less digit to do
	jnz	writeDigits			; Loop to write the next one
	.leave
	ret
FormatBase10Number	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a function into the output.

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to ParserTokenFunctionData
		es:di	= Place to put function name
RETURN:		ds:si	= Pointer to the next token
		es:di	= Pointer past the function name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatFunction	proc	near
	uses	ax, bx, cx, dx
	.enter
	mov	cx, ds:[si].PTFD_functionID

	cmp	cx, FUNCTION_ID_FIRST_EXTERNAL_FUNCTION
	jae	callApplication
	;
	; The function is a built-in one
	;
	push	ds, si				; Save pointer
	mov	bx, cx				; bx <- index into table
	
NOFXIP<segmov	ds, dgroup, ax			; ds <- Seg of our table >
FXIP <	mov	ax, bx				; save bx		>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
FXIP <	mov	bx, ax				; restore bx		>
	call	FormatDerefTableEntry		; bx = index to the table
	mov	si, ds:funcTable[bx]		; ds:si <- ptr to name
	clr	cx				; cx <- size
	lodsb					; Lengh is in 1st byte of
	mov	cl, al				;    string.
	call	FormatWriteSBString		; Write the string
	pop	ds, si				; Save pointer
writeOpenParen:
	LocalLoadChar	ax, '('
	call	FormatWriteChar			; Write the character

	add	si, size ParserTokenFunctionData
	.leave
	ret

callApplication:
	;
	; Call the application to put the name of the function into the
	; output. (cx already holds the function ID).
	;
	mov	al, CT_FORMAT_FUNCTION
	mov	dx, ss:[bp].FP_nChars		; dx <- max count
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback
endif
	mov	ss:[bp].FP_nChars, dx		; Save # left
	jmp	writeOpenParen

FormatFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatDerefTableEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the etype FunctionID, it returns the index of the
		funcTable.

CALLED BY:	FormatFunction()
PASS:		bx	= FunctionID
		ds	= dgroup
RETURN:		bx	= index of the funcTable
DESTROYED:	ax, cx, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatDerefTableEntry	proc	near
		.enter
		mov	cx, length funcIDTable
		mov	si, offset funcIDTable
startSearch:
		lodsw					;ax = FunctionID
		cmp	ax, bx
		je	found
		loop	startSearch
EC <		ERROR	ILLEGAL_FUNCTION_INDEX				>
found:
	;
	; We found the entry.
	;
		sub	si, (offset funcIDTable) + 2
		mov	bx, si				;bx = real index
		.leave
		ret
FormatDerefTableEntry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatEndOfExpression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an end-of-expression to the output

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		es:di	= Place to put end-of-expression
RETURN:		es:di	= Pointer past the end-of-expression
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatEndOfExpression	proc	near
	uses	ax
	.enter
SBCS<	clr	al		; There is always room for the NULL.	>
DBCS<	clr	ax		; There is always room for the NULL.	>
	LocalPutChar	esdi, ax ; We make sure of that in ParserFormatExpression
	.leave
	ret
FormatEndOfExpression	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatOpenParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an open-paren to the output.

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		es:di	= Place to put open-paren
RETURN:		es:di	= Pointer past the open-paren
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatOpenParen	proc	near
	uses	ax
	.enter
	LocalLoadChar	ax, '('
	call	FormatWriteChar
	.leave
	ret
FormatOpenParen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a name

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to ParserTokenNameData
		es:di	= Place to put the name
RETURN:		ds:si	= Pointer to the next token
		es:di	= Pointer past the name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatName	proc	near
	uses	ax, cx, dx
	.enter
	mov	al, CT_FORMAT_NAME
	mov	cx, ds:[si].PTND_name
	add	si, size ParserTokenNameData
	mov	dx, ss:[bp].FP_nChars		; dx <- # of characters left
NOFXIP<	call	ss:[bp].CP_callback					>
FXIP <	push	bx							>
FXIP <	mov	ss:[TPD_dataBX], bx					>
FXIP <	mov	ss:[TPD_dataAX], ax					>
FXIP <	movdw	bxax, ss:[bp].CP_callback	; Call the application	>
FXIP <	call	ProcCallFixedOrMovable					>
FXIP <	pop	bx							>

	sub	ss:[bp].FP_nChars, dx		; Update # of characters
	.leave
	ret
FormatName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatCloseParen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a close-paren to the output.

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		es:di	= Place to put close-paren
RETURN:		es:di	= Pointer past the close-paren
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatCloseParen	proc	near
	uses	ax
	.enter
	LocalLoadChar	ax, ')'
	call	FormatWriteChar
	.leave
	ret
FormatCloseParen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatArgEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an argument-end to the output.

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		es:di	= Place to put argument-end
RETURN:		es:di	= Pointer past the argument-end
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatArgEnd	proc	near
	uses	ax, cx
	.enter
	;
	; Check the next token to make sure that it isn't a CLOSE_FUNCTION
	; If it is, there's no need for a ", "
	;
	cmp	{byte} ds:[si], PARSER_TOKEN_CLOSE_FUNCTION
	je	quit

	push	ds, si			; Save token pointer
NOFXIP<	mov	cx, segment idata					>
NOFXIP<	mov	ds, cx							>
FXIP <	mov	cx, bx			; cx = bx			>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS		; ds = dgroup 			>
FXIP <	mov	bx, cx			; restore bx			>
	mov	si, offset argEndString	; ds:si <- ptr to end string
	mov	cx, length argEndString	; cx <- size of the string
	call	FormatWriteString	; Write the string
	pop	ds, si			; Restore token pointer
quit:
	.leave
	ret
FormatArgEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatOperator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format an operator into the output stream

CALLED BY:	ParserFormatExpression via tokenHandlerTable
PASS:		ds:si	= Pointer to ParserTokenOperatorData
		es:di	= Place to put operator
RETURN:		ds:si	= Pointer to next token
		es:di	= Pointer past the operator
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatOperator	proc	near
	uses	ax, cx
	.enter
	clr	ah
	mov	al, ds:[si].PTOD_operatorID	; ax <- operator
	
	push	ds, si				; Save pointer
	shl	ax, 1				; index into table of words
	mov	si, ax				; si <- index into table
NOFXIP<	mov	ax, dgroup						>
NOFXIP<	mov	ds, ax				; ds <- segment of table >
FXIP <	mov_tr	ax, bx				; ax  = bx		>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
FXIP <	mov	bx, ax				; restore bx		>
	mov	si, ds:opFormatTable[si]	; ds:si <- ptr
	
	clr	cx				; cx <- size
DBCS<	lodsw					; Lengh is in 1st word >
DBCS<	mov	cx, ax				; of string.           >
SBCS<	lodsb					; Lengh is in 1st byte >
SBCS<	mov	cl, al				; of string.           >
	call	FormatWriteString		; Copy the operator
	pop	ds, si				; Restore pointer
	
	add	si, size ParserTokenOperatorData
	.leave
	ret
FormatOperator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatWriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string of characters

CALLED BY:	
PASS:		ds:si	= Pointer to the characters to write
		es:di	= Pointer to the place to write the data
		ss:bp	= Pointer to FormatParameters
		cx	= # of chars to write (length)
RETURN:		es:di	= Pointer past the written text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatWriteString	proc	near
	uses	si, cx
	.enter
	cmp	ss:[bp].FP_nChars, cx
	jb	noMoreSpace
	
	sub	ss:[bp].FP_nChars, cx	; This many fewer spaces to write to

	LocalCopyNString		; Write the string
quit:
	.leave
	ret

noMoreSpace:
	mov	ss:[bp].FP_nChars, 0	; Stop others from writing data
	jmp	quit			; Quit, don't write the string
FormatWriteString	endp


if DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatWriteSBString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a SBCS and stores it as DBCS string.

CALLED BY:	Utiltity (this file only)
PASS:		cx	= length of SBCS string
		ds:si	= SBCS ptr (read)
		es:di	= DBCS ptr (written)
		ss:bp	= ptr FP structure
RETURN:		es:di	= points after string
DESTROYED:	nothing
SIDE EFFECTS:	reduces ss:[bp].FP_nChars by 'cx' if string fits.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	12/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatWriteSBString	proc	near
	uses	si, cx, ax
	.enter
	cmp	ss:[bp].FP_nChars, cx
	jb	noMoreSpace
	
	sub	ss:[bp].FP_nChars, cx	; This many fewer spaces to write to
	clr	ah
expandSBLoop:
	lodsb				; get single byte char (ASCII)
	stosw				; put double byte char (Unicode)
	loop	expandSBLoop	
quit:
	.leave
	ret

noMoreSpace:
	mov	ss:[bp].FP_nChars, 0	; Stop others from writing data
	jmp	quit			; Quit, don't write the string
FormatWriteSBString	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatWriteChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single character

CALLED BY:	
PASS:		al	= Character to write
		es:di	= Pointer to the place to write the data
		ss:bp	= Pointer to FormatParameters
RETURN:		es:di	= Pointer past the written text
DESTROYED:	ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatWriteChar	proc	near
	tst	ss:[bp].FP_nChars
	jz	quit			; branch if no more space
	
	dec	ss:[bp].FP_nChars	; One fewer spaces to write to

SBCS<	clr	ah							>
	LocalPutChar esdi, ax		; Save the character

quit:
	ret
FormatWriteChar	endp


FormatCode	ends
