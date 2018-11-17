COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetFormulaCell.asm

AUTHOR:		John Wedgwood, Mar 22, 1991

ROUTINES:
	Name			Description
	----			-----------
	FormulaCellAlloc	Create a formula cell given an expression
	FormulaCellGetResult	Get the formatted result from a formula cell
	FormulaCellFormat	Format the expression in a formula cell
	FormulaCellParseText	Parse a formula and save the result
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/22/91		Initial revision


DESCRIPTION:
	Routines defined on the spreadsheet object to handle formula cells.
		

	$Id: spreadsheetFormulaCell.asm,v 1.1 97/04/07 11:14:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaCellAddParserRemoveDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove any dependencies which might be
		associated with a cell. 

CALLED BY:	DeleteCell, AllocTextCell, AllocChartCell

PASS:		ds:si	= Pointer to spreadsheet instance
		ax/cx	= Row/column of the cell
		dx	= -1 to remove dependencies
			= 0 to add them
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaCellAddParserRemoveDependencies	proc	far
	uses	bp
	.enter
	sub	sp, size PCT_vars
	mov	bp, sp			; ss:bp <- ptr to parameters
	call	SpreadsheetInitCommonParams

EC <	cmp	ax, NAME_ROW			>
EC <	ERROR_Z	CELL_SHOULD_NOT_BE_A_NAME_CELL	>

	mov	ss:[bp].CP_row, ax	; Save our row/column
	mov	ss:[bp].CP_column, cx
	
	mov	ss:[bp].PCTV_row, ax	; Save our row/column here too
	mov	ss:[bp].PCTV_column, cx

	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES

	call	CellAddRemoveDeps	; Remove the dependencies
	
	add	sp, size PCT_vars
	.leave
	ret
FormulaCellAddParserRemoveDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellAddRemoveDeps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove dependencies for a cell.

CALLED BY:	FormulaCellParserRemoveDependencies, AddRemoveCellDependencies
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to initialized PCT_vars structure
			  EP_flags initialized
		dx	= 0 to add dependencies
			= non-zero to remove dependencies
		ax/cx	= Row/column of the cell
RETURN:		es same. This may be bad if es pointed at an lmem heap
		which moved.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellAddRemoveDeps	proc	far
	uses	ax, bx
	.enter
	call	CreatePrecedentList	; Make the precedents list
	jnc	quit			; Quit if no precedents

	;
	; Call the appropriate routine. Add/ParserRemoveDependencies unlock and
	; free the precedents block so we don't have to.
	;
	tst	dx			; Check add/remove flag
	jz	addDeps			; Branch if we want to add

	call	ParserRemoveDependencies	; Remove dependencies
	ERROR_C	UNABLE_TO_REMOVE_DEPENDENCIES
	jmp	unlockAndFreeBlock

addDeps:
	call	ParserAddDependencies		; Add dependencies
	ERROR_C	UNABLE_TO_ADD_DEPENDENCIES

unlockAndFreeBlock:
	call	MemFree			; Free the dependency block

	clc				; Signal: no error
quit:
	.leave
	ret
CellAddRemoveDeps	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaCellAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a formula cell

CALLED BY:	EnterDataFromEditBar
PASS:		ds:si	= Pointer to the spreadsheet instance data
		es:di	= ptr to the text of the cell
		dx	= length of the text
		ax	= row
		cx	= column
RETURN:		carry set on error
		al	= Error code
		cx, dx	= Range of text that generated the error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaCellAlloc	proc	far
	uses	bx, ds, di, si, bp
	.enter
	xchg	cx, dx			; cx <- length of text
					; dx <- column of cell
	call	FormulaCellParseText	; Parse me jesus

	.leave
	ret
FormulaCellAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaCellGetResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the formatted result of a formula cell

CALLED BY:	DrawFormulaCell
PASS:		ds:si	= Pointer to the spreadsheet instance
		dx:bp	= Pointer to the cell data
		es:di	= Pointer to place to put the result
RETURN:		dl	= Return type
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ds:[si].CF_current.RV_TEXT	= size of text

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 8/91	Initial version
	witt	11/15/93	DBCS-ized, RV_TEXT is *size*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaCellGetResult	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, di, si, ds, bp
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds				; save ptr to instance
	mov	cx, si

	mov	ds, dx				; ds:si <- ptr to cell data
	mov	si, bp

	;
	; Check for the cell not being of type "CT_FORMULA". If it's not then
	; the caller really shouldn't have called this routine.
	;
EC <	cmp	ds:[si].CC_type, CT_FORMULA			>
EC <	ERROR_NE CELL_SHOULD_BE_A_FORMULA			>
	
	cmp	ds:[si].CF_return, RT_ERROR	; Check for error type
	je	formatError			; Branch if it's an error
	
	cmp	ds:[si].CF_return, RT_TEXT	; Check for text type
	je	formatText			; Branch if it's text

	;-----------------------------------------------------------------------
	; It must be a number (since those are the only three return types
	; currently supported). If it's anything else then that is a sign that
	; this cells data somehow got screwed up.

EC <	cmp	ds:[si].CF_return, RT_VALUE		>
EC <	ERROR_NZ ILLEGAL_RETURN_TYPE			>

	mov	ax, ds:[si].CC_attrs		; ax <- token

	push	ds,si
	mov	ds, bx				; ds:si <- ptr to instance
	mov	si, cx
	mov	bx, offset CA_format		; bx <- field
	call	StyleGetAttrByTokenFar		; get format token
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, ds:[si].SSI_formatArray
	pop	ds,si

	add	si, offset CF_current		; ds:si <- ptr to current value
	call	FloatFormatNumber
	
	mov	dl, RT_VALUE			; assume number formatted
	jnc	quit
	
	mov	dl, RT_ERROR			; number didn't format
	
	;-----------------------------------------------------------------------

quit:
	.leave
	ret

formatError:
	;
	; Format an error code.
	;
	mov	bl, ds:[si].CF_current.RV_ERROR	; bx <- error code
	call	CalcFormatError

	mov	dl, RT_ERROR			; return type
	jmp	quit

formatText:
	;
	; Format a string.
	;
	mov	cx, ds:[si].CF_current.RV_TEXT	; cx <- size of text
	add	si, ds:[si].CF_formulaSize	; ds:si <- ptr to string
	add	si, size CellFormula
	;
	; Skip over any leading quote for 1-2-3 compatibility
	;
	call	Skip123QuoteFar
EC <	cmp	cx, MAX_CELL_TEXT_SIZE+1	; overflowing size?	>
EC <	ERROR_A	REQUESTED_ENTRY_IS_TOO_LARGE				> 

	rep	movsb				; Copy the string
	LocalClrChar	ax			; Null terminate the string
	LocalPutChar	esdi, ax

	mov	dl, RT_TEXT			; return type
	jmp	quit
FormulaCellGetResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaDisplayCellGetResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the formatted result of a formula display cell

CALLED BY:	DrawDisplayFormulaCell, GetDisplayFormulaCellAsTextInt,
		SizeDisplayFormulaCell
PASS:		ds:si	= Pointer to the spreadsheet instance
		dx:bp	= Pointer to the cell data
		es:di	= Pointer to place to put the result
		ax,cx	= Row/Column of the cell
RETURN:		dl	= ReturnType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Skip123Quote takes cx = size.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version
	witt	11/29/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaDisplayCellGetResult	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di, ds, si, bp
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, bp			; bx <- offset to cell data

	sub	sp, size PCT_vars	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- ptr to stack frame
	
	push	dx, bx			; Save ptr to the cell data
	push	es, di			; Save place to put the result

	mov	es, dx			; es:di <- ptr to cell data
	mov	di, bx

	;
	; ss:bp	= Pointer to PCT_vars
	; ax	= Row
	; cx	= Column
	; es:di	= Pointer to cell data
	; ds:si	= Spreadsheet instance
	; On stack:
	;	Ptr to place to put the result
	;	Ptr to cell data
	;
	call	SpreadsheetInitCommonParams
	mov	ss:[bp].CP_row, ax	; Save our row/column
	mov	ss:[bp].CP_column, cx
	
	mov	ss:[bp].PCTV_row, ax	; Save our row/column here too
	mov	ss:[bp].PCTV_column, cx

	;
	; We need to calculate the value in the cell.
	; ss:bp	= Pointer to PCT_vars on stack
	; ds:si	= Spreadsheet instance
	; es:di	= Pointer to cell data
	; On stack:
	;	Ptr to place to put the result
	;	Ptr to cell data
	;
	call	RecalcFormulaCell	; Calculate result
					; es:bx <- ptr to result
	pop	es, di			; Restore place to put the result
	
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Place to put the result
	; ss:bx	= Pointer to result
	; On stack:
	;	Ptr to cell data
	;
	mov	al, {byte} ss:[bx]	; al <- type of result
	inc	bx			; ss:bx <- ptr to data

	mov	cx, ds			; cx:dx <- Ptr to spreadsheet instance
	mov	dx, si
	pop	ds, si			; ds:si <- Ptr to cell data
	
	;
	; al	= Type of the result
	; ds:si	= Pointer to cell data
	; ss:bx	= Pointer to the result data
	; es:di	= Pointer to the place to put the result
	; cx:dx	= Spreadsheet instance
	;
	test	al, mask ESAT_ERROR	; Check for an error
	jnz	formatError

	test	al, mask ESAT_STRING	; Check for a string
	jnz	formatString
	
	test	al, mask ESAT_NUMBER	; Check for a number
	jnz	formatNumber
	
	;
	; We should never get here. The only way it's possible is if somehow
	; the return value isn't one of these types. It should always be one
	; of these types.
	;
EC <	ERROR	-1			>

quit:
	add	sp, size PCT_vars	; Restore the stack frame
	.leave
	ret

formatError:
	;
	; Format an error.
	; ss:bx	= Pointer to the cell-error code
	; es:di	= Pointer to place to put the data
	;
	mov	bl, {byte} ss:[bx]	; bl <- CellError
	call	CalcFormatError		; Format the string
	jmp	quit

formatString:
	;
	; Format a string.
	; ss:bx	= Pointer to the string data
	; es:di	= Pointer to place to put the data
	;
	segmov	ds, ss, si		; ds:si <- ptr to the string
	mov	si, bx

	lodsw				; ax <- length of the string
					; ds:si <- ptr to the string
	mov	cx, ax			; cx <- length of the string
	;
	; Skip over any leading quote for 1-2-3 compatibility
	;
DBCS<	shl	cx, 1			; cx <- size of the string	>
	call	Skip123QuoteFar
EC <	cmp	cx, MAX_CELL_TEXT_SIZE+1 ; Over sized?		>
EC <	ERROR_A REQUESTED_ENTRY_IS_TOO_LARGE			>
	rep	movsb			; Copy the string
	
	LocalClrChar	ax		; Null terminate the string
	LocalPutChar	esdi, ax
	jmp	quit

formatNumber:
	;
	; Format a number.
	; Number is on fp-stack, we need to pop it into some safe place.
	; es:di	= Pointer to place to put the data
	; ds:si	= Pointer to the cell data
	; cx:dx	= Pointer to the spreadsheet instance
	;
	push	es, di			; Save place to put the result text
	segmov	es, ss, di		; es:di <- place to store result
	lea	di, ss:[bp].PCTV_evalBuffer
	mov	bx, di			; ss:bx <- place to put result too
	
	call	FloatPopNumber		; Pop result off into es:di
	pop	es, di			; Restore place to put the result

	;
	; Now we have the number on the stack at ss:bx.
	;
	mov	ax, ds:[si].CC_attrs	; ax <- style token

	push	bx			; Save ptr to number data

	mov	ds, cx			; ds:si <- ptr to spreadsheet instance
	mov	si, dx
	mov	bx, offset CA_format	; bx <- field to get
	call	StyleGetAttrByTokenFar	; Get format token
;	mov	cx, ds			; cx:dx <- spreadsheet instance
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, ds:[si].SSI_formatArray
	pop	si			; ds:si <- ptr to number data
	segmov	ds, ss

	;
	; ax	= Format token
	; ds:si	= Number
	; es:di	= Place to put the text
	;
	call	FloatFormatNumber	; Format the number
	jmp	quit
FormulaDisplayCellGetResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFormatError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format an error type.

CALLED BY:	FormulaCellGetResult, FormulaDisplayCellGetResult
PASS:		bl	= CellError
		es:di	= Pointer to the buffer
RETURN:		es:di	= Pointer past the end of the buffer
DESTROYED:	ax, bx, cx, ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	DBCS: For double bytes, we read single byte error message and
		unpack them.  Error strings are not localizable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version
	witt	11/08/93	DBCS-ized, strings not localizable

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcFormatError	proc	far
	clr	bh
	shl	bx, 1				; Use as index into table of
						;    strings
	segmov	ds, cs
	mov	si, cs:errorStrings[bx]		; ds:si <- ptr to the string
	clr	ch
	mov	cl, ds:[si]			; cx <- length of the string
	inc	si				; ds:si <- ptr to the text
if DBCS_PCGEOS
	clr	ah
unpackErrorString:
	lodsb					; single byte in..
	stosw					; ..double byte out
	loop	unpackErrorString
else
	rep	movsb				; Copy the error string
endif
	
	LocalClrChar	ax			; Null terminate the string
	LocalPutChar	esdi, ax
	ret
CalcFormatError	endp

;
; These need to go into a resource, unless we determine that they are not
; going to be localized.
;
errorStrings	word	offset cs:CE_noErrorString,	; CE_NO_ERROR
			offset cs:CE_tooComplexString,	; CE_TOO_COMPLEX
			offset cs:CE_rangeString,	; CE_REF_OUT_OF_RANGE
			offset cs:CE_nameString,	; CE_NAME
			offset cs:CE_argCountString,	; CE_ARG_COUNT
			offset cs:CE_typeString,	; CE_TYPE
			offset cs:CE_divByZeroString,	; CE_DIVIDE_BY_ZERO
			offset cs:CE_circularRef,	; CE_CIRCULAR_REF
			offset cs:CE_genErr,		; CE_GEN_ERR
			offset cs:CE_naErr,		; CE_NA_ERR
			offset cs:CE_floatPosInf,	; CE_FLOAT_POS_INF
			offset cs:CE_floatNegInf,	; CE_FLOAT_NEG_INF
			offset cs:CE_numOutOfRange,	; CE_FLOAT_GEN_ERR
			offset cs:CE_circNameRef,	; CE_CIRC_NAME_REF
			offset cs:CE_circDep,		; CE_CIRC_DEPEND
			offset cs:CE_numOutOfRange	; CE_NUM_OUT_OF_RANGE

;
; NOTE: CE_FLOAT_GEN_ERR and CE_NUM_OUT_OF_RANGE are basically the same
; thing (argument out of range) so they are both mapped to #VALUE#.
;

CE_noErrorString	byte	4, "Why?"
CE_tooComplexString	byte	7, "#CMPLX#"
CE_rangeString		byte	7, "#RANGE#"
CE_nameString		byte	6, "#NAME#"
CE_argCountString	byte	7, "#COUNT#"
CE_typeString		byte	6, "#TYPE#"
CE_divByZeroString	byte	7, "#DIV/0#"
CE_circularRef		byte	6, "#CREF#"
CE_genErr		byte	7, "#ERROR#"
CE_naErr		byte	4, "#NA#"
CE_floatPosInf		byte	8, "#OVRFLW#"
CE_floatNegInf		byte	8, "#UNDFLW#"
CE_circNameRef		byte	7, "#CNAME#"
CE_circDep		byte	6, "#CIRC#"
CE_numOutOfRange	byte	7, "#VALUE#"


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaCellFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a formula

CALLED BY:	EditFormatFormulaCell
PASS:		ds:si	= Pointer to the spreadsheet instance
		ax:cx	= Pointer to the formula
		es:di	= Pointer to the place to put it.
		dx	= Size of the buffer pointed at by es:di
		ss:bx	= ptr to CellReference for "current cell"
RETURN:		cx	= Length of the formatted text.
		dx	= Remaining size in es:di buffer
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 8/91	Initial version
	witt	11/ 9/93	DBCS-ized. FP_nChars is wchar/char count

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaCellFormat	proc	far
	class	SpreadsheetClass
	uses	bp, bx, ds, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	sub	sp, size FormatParameters
	mov	bp, sp
	
	call	SpreadsheetInitCommonParams	; Initialize the common stuff
	
	mov	ds, ax				; ds:si <- ptr to expression
	mov	si, cx
	;
	; Set the "current" cell.
	;   For display in the edit bar, this will be the active cell.
	;   For "Show Formulas", this will be the current cell.
	;
	mov	ax, ss:[bx].CR_row
	mov	ss:[bp].CP_row, ax
	mov	ax, ss:[bx].CR_column
	mov	ss:[bp].CP_column, ax
	;
	; Put an equal sign at the start
	;
	mov	ax, '='
	LocalPutChar	esdi, ax		; Save the "="
	LocalPrevChar	esdx			; One less character will fit
						; (dx is buffer size)
if DBCS_PCGEOS
	mov	ax, dx				; preserve dx (size)
	shr	ax, 1				; ax <- buffer length
EC<	ERROR_C CELL_NAME_BUFFER_ODDSIZED
	mov	ss:[bp].FP_nChars, ax		; Save the buffer length
else
	mov	ss:[bp].FP_nChars, dx		; Save the buffer length
endif
	call	ParserFormatExpression		; Format the expression.
						; cx <- text length (w/out NULL)
	add	sp, size FormatParameters	; Restore stack
	.leave
	ret
FormulaCellFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormulaCellParseText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse cell text, updating dependencies and saving the
		new parsed tokens. Evaluates and saves the result.

CALLED BY:	NameParseText
PASS:		ds:si	= Pointer to the spreadsheet instance
		es:di	= Pointer to the text (null terminated)
		cx	= Length of the text
		ax	= The row of the cell (NAME_ROW for names)
		dx	= The column of the cell
RETURN:		carry set on error
		al	= ParserScannerEvaluatorError
		cx,dx	= Range of the text that didn't parse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The only errors returned from this function are parse-errors.
	These are the type of errors that the user is required to fix before
	  the application can store the data into the cell.
	So... This means that if this function returns an error then the
	  cell data did not get stored.

	Other errors (evaluator errors) result in information being stored in
	  the cell signalling that there was some sort of error. The user
	  is informed of these when the cell is displayed. The error message
	  will appear inside the cell.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormulaCellParseText	proc	near
	class	SpreadsheetClass
	uses	bx, bp, es, di, ds, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	sub	sp, size PCT_vars	; Make a stack frame
	mov	bp, sp			; ss:bp <- ptr to stack frame
	;
	; Initialize the common parts of the stack frame.
	;
	call	SpreadsheetInitCommonParams

	mov	bx, ax			; bx <- row of the cell
	;
	; We parse the text then remove the old dependencies, then add the
	; new dependencies.
	;
	push	dx			; Save column of the cell
	push	ds, si			; Save instance ptr
	mov	ss:[bp].PP_parserBufferSize, PARSE_TEXT_BUFFER_SIZE
	mov	ss:[bp].PP_flags, mask PF_OPERATORS or \
				  mask PF_CELLS or \
				  mask PF_NUMBERS or \
				  mask PF_FUNCTIONS or \
				  mask PF_NAMES or \
				  mask PF_NEW_NAMES

	segmov	ds, es, si		; ds:si <- ptr to the text to parse
	mov	si, di

	segmov	es, ss			; es:di <- ptr to place to put tokens
	lea	di, ss:[bp].PCTV_parseBuffer
	call	ParserParseString		; Parse me jesus
					; di <- ptr past the last token written
	pop	ds, si			; Restore instance ptr
	;
	; If we branch, the column of the cell is on the stack
	; If we branch, cx/dx = range of text where error was encountered.
	;
	jc	errorParsing		; Branch on error
	
	pop	dx			; Restore column of the cell
	;
	; The text parsed correctly. Get rid of the old dependencies.
	;
	call	SpreadsheetAllocFormulaCell
quit:
	lahf				; Save error flag (carry)
	add	sp, size PCT_vars	; Restore the stack frame
	sahf				; Restore error flag (carry)
	.leave
	ret

errorParsing:
	;
	; An error was encountered while parsing. It should be a nice benign
	; error that we can return to our caller. The only reason for branching
	; here after the error rather than branching directly to "quit" is
	; so we can set a nice breakpoint and catch these errors if we want
	; to.
	;
	; On stack:	Column of cell
	;
	pop	bp			; We can trash bp safely here
	stc
	jmp	quit
FormulaCellParseText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetAllocFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update dependencies and save the new tokens. Evaluate and
		save the result.

CALLED BY:	FormulaCellParseText, PasteCreateFormulaCell

PASS:		ds:si	= pointer to the spreadsheet instance
		es:di	= pointer past the parsed data
		bx	= The row of the cell (NAME_ROW for names)
		dx	= The column of the cell
		ss:bp	= PCT_vars

RETURN:		nothing

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
	The only errors returned from this function are parse-errors.
	These are the type of errors that the user is required to fix before
	  the application can store the data into the cell.
	So... This means that if this function returns an error then the
	  cell data did not get stored.

	Other errors (evaluator errors) result in information being stored in
	  the cell signalling that there was some sort of error. The user
	  is informed of these when the cell is displayed. The error message
	  will appear inside the cell.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version
	cheng	 7/24/91	Extracted from FormulaCellParseText

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetAllocFormulaCellNoGC	proc	far
	call	SpreadsheetAllocFormulaCellCommon
	ret
SpreadsheetAllocFormulaCellNoGC	endp
		
SpreadsheetAllocFormulaCellFar	proc	far
	call	SpreadsheetAllocFormulaCell
	ret
SpreadsheetAllocFormulaCellFar	endp

SpreadsheetAllocFormulaCell	proc	near
	.enter
	call	SpreadsheetAllocFormulaCellCommon
	;
	; Clean up the unreferenced names. These names used to be nuked when
	; we removed the old dependencies, but this can't work because if we
	; alter the only formula that refers to an undefined name, the name
	; will be nuked when we remove the old dependencies. Since these names
	; are created when the formula is successfully parsed, it won't exist
	; when we go to add the dependencies again.
	;
	call	NameListCleanupUndefinedEntries
	
	clc				; Signal: no error
	.leave
	ret
SpreadsheetAllocFormulaCell	endp

SpreadsheetAllocFormulaCellCommon	proc	near
EC <	call	ECCheckInstancePtr		;>
	;
	; We are getting rid of all the stuff that the old expression
	; is responsible for. After we've done this we will generate
	; the new dependencies. 
	;
	; We need to evaluate from the point of view of the cell we are
	; defining, otherwise the relative cell references won't work
	; correctly.
	;
	; bx/dx	= Row/Column of the cell that was passed in.
	;
	mov	ss:[bp].PCTV_row, bx	; This is the cell we are defining
	mov	ss:[bp].PCTV_column, dx
	mov	ss:[bp].CP_row, bx
	mov	ss:[bp].CP_column, dx

	mov	bl, ss:[bp].PP_flags	; bl <- the parser flags

	mov	dx, -1			; Signal: Remove dependencies
	call	AddRemoveCellDependencies

	;
	; Save the formula for the cell.
	;
	mov	al, CT_FORMULA		; The type for the cell
	test	bl, mask PF_CONTAINS_DISPLAY_FUNC
	jz	gotCellType		; Branch if not a display cell
	mov	al, CT_DISPLAY_FORMULA	; If it is, use this cell type
gotCellType:
	call	SaveCellFormula		; Save formula

	clr	dx			; Signal: Add dependencies
	call	AddRemoveCellDependencies
	
	clc
	
	ret
SpreadsheetAllocFormulaCellCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCellFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the cell formula into the cell

CALLED BY:	ParseCellText
PASS:		ss:bp	= Pointer to PCT_vars
		ds:si	= Pointer to spreadsheet instance
		di	= Pointer past the parsed data
		al	= CellType (either CT_FORMULA or CT_DISPLAY_FORMULA)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the cell does not exist, create it
	Find the position of the old formula
	Figure out the difference in sizes of the old formula and the new one
	Insert/delete space in the cell
	Store the new formula

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCellFormulaFar	proc	far
	call	SaveCellFormula
	ret
SaveCellFormulaFar	endp

SaveCellFormula	proc	near
	uses	ax, bx, cx, dx, ds, si, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Compute the size of the parsed formula.
	;
	sub	di, bp			; di <- offset from start of frame
	sub	di, offset PCTV_parseBuffer ; di <- # of bytes in new formula
	
	mov	dx, di			; Save size of new formula in dx
	
	push	ax			; Save passed cell type

lockCell:
	mov	ax, ss:[bp].PCTV_row	; ax <- row of the cell
	mov	cx, ss:[bp].PCTV_column	; cx <- column of the cell
	SpreadsheetCellLock		; *es:di <- ptr to the cell
	jc	gotCell			; Branch if cell exists
	
	;
	; Cell doesn't exist, create it.
	;
	call	SpreadsheetCreateEmptyCell
	jmp	lockCell		; Loop to lock it again

gotCell:
	pop	bx			; Restore passed cell type into bx
	
	mov	di, es:[di]		; es:di <- ptr to the cell
	;
	; If the cell isn't a formula cell (it may be something else) then
	; we want to turn it into a formula cell.
	;
	push	dx			; Save new formula size
	cmp	es:[di].CC_type, bl	; Check for correct cell type
	jne	changeToFormulaCell	; Branch if not already formula cell

gotFormulaCell:
	pop	dx			; Restore new formula size
	;
	; ax	= Row of the current cell
	; cx	= Column of the current cell
	; es:di	= Pointer to cell data
	; dx	= Size of new formula
	;
					; dx <- change in size
	sub	dx, es:[di].CF_formulaSize
	SpreadsheetCellUnlock		; Release the cell
	;
	; Now we resize the cell
	; dx = # of bytes to insert/delete
	;
	push	cx, dx			; Save column #, change in size
	mov	cx, dx			; cx <- # to insert
	mov	dx, CF_formula		; dx <- place to insert
	call	InsertIntoCurrentCell	; Insert space
	pop	cx, dx			; Restore column #, change in size

	SpreadsheetCellLock		; *es:di <- ptr to the definition
	;
	; If the cell does not exist then something is horribly wrong. We
	; just unlocked it a second ago.
	;
EC <	ERROR_NC CELL_DOES_NOT_EXIST		>

	mov	di, es:[di]		; es:di <- ptr to the cell

	add	es:[di].CF_formulaSize, dx
	;
	; es:di	= Pointer to the cell
	; parseBuffer (on stack) contains new formula
	;
	; Get the size of the new data and copy it into the cell
	;
	push	ds, si			; Save instance pointer
	mov	cx, es:[di].CF_formulaSize
	add	di, CF_formula		; es:di <- ptr to destination
	
	segmov	ds, ss, ax		; ds:si <- ptr to source
	lea	si, ss:[bp].PCTV_parseBuffer
	
	rep	movsb			; Copy the formula
	pop	ds, si			; Restore instance ptr

	call	UnlockAndDirtyCell	; dirty the cell and unlock it

	.leave
	ret

changeToFormulaCell:
	;
	; We want to replace the cell data with an empty formula cell data.
	; This isn't too easy since we need to keep the dependencies around.
	; bx = Type for the new cell
	;
	SpreadsheetCellUnlock		; Release the cell definition

	mov	dx, (size CellFormula - size CellCommon)
	call	SpreadsheetCellResizeData
	;
	; Now we've created the cell. Lock it down and initialize it.
	;
	SpreadsheetCellLock		; *es:di <- ptr to cell definition
	mov	di, es:[di]		; es:di <- ptr to cell
	mov	es:[di].CF_common.CC_type, bl

	mov	es:[di].CF_return, RT_VALUE
	mov	es:[di].CF_formulaSize, 0
	
	push	ax, cx, di		; Save row, column, cell ptr
	add	di, offset CF_current	; es:di <- ptr to current value
	clr	al			; Byte to store
	mov	cx, size CF_current	; cx <- size of structure to fill
DBCS< CheckHack< (size CF_current) ge (size wchar) >  ; at least store C_NULL >
	rep	stosb			; Save zeros...
	pop	ax, cx, di		; Restore row, column, cell ptr
	jmp	gotFormulaCell		; Branch now that it's set up
SaveCellFormula	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddRemoveCellDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove dependencies for a cell

CALLED BY:	ParseCellText
PASS:		dx	= -1 to remove
			=  0 to add
		ss:bp	= Pointer to PCT_vars
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Adding and removing dependencies is really simple, except in the
	case of names. In the case of names we need to do it for the name
	and for every cell which references the name. Sigh.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine must be declared "far" because it is passed as a callback
	routine on the stack.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddRemoveCellDependenciesFar	proc	far
	call	AddRemoveCellDependencies
	ret
AddRemoveCellDependenciesFar	endp

AddRemoveCellDependencies	proc	near
	uses	ax, cx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ax, ss:[bp].PCTV_row	; ax <- row
	mov	cx, ss:[bp].PCTV_column	; cx <- column

	cmp	ax, NAME_ROW		; Check for a name
	je	handleNameDependents	; Branch if it's a name

	;
	; It's just a normal cell... Do the right thing here.
	;
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
addRemoveDeps:

	call	CellAddRemoveDeps	; Add or remove dependencies
	.leave
	ret

handleNameDependents:
	;
	; When the definition of a name changes, we need to update all the
	; cells which depend on that name. This isn't quite as easy as it
	; sounds since there may be cells which depend on the name indirectly
	; through the use of a name which references this one.
	;
	; We use the recalc-list code to build out a list of the cells which
	; depend on this name.
	;
	mov	ss:[bp].PCTV_addRem, dx	; Save add/remove flag
	call	UpdateNameDependents	; Update the dependents dependencies.
	
	;
	; Restore the row/column in the stack frame.
	;
	mov	ss:[bp].PCTV_row, ax
	mov	ss:[bp].PCTV_column, cx
	mov	ss:[bp].CP_row, ax
	mov	ss:[bp].CP_column, cx
	
	;
	; Set the flags we need for creating the dependencies for the name itself
	;
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES or \
				  mask EF_ONLY_NAMES
	jmp	addRemoveDeps		; Branch to handle the name cell
AddRemoveCellDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertIntoCurrentCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert space into a formula cell

CALLED BY:	
PASS:		ss:bp	= CommonParams structure on stack
		cx	= # of bytes to insert
		dx	= Position to insert at
		ds:si	= Pointer to spreadsheet instance
RETURN:		nothing (If there is an error, then we will choke badly)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertIntoCurrentCell	proc	near
	class	SpreadsheetClass
	uses	ax, bx, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	cx			; Save # of bytes to insert
	mov	ax, ss:[bp].PCTV_row
	mov	cx, ss:[bp].PCTV_column
	SpreadsheetCellGetDBItem	; ax, di <- dbase item
	pop	cx			; Restore # of bytes to insert
	
	;
	; Set up parameters (dx = place to insert, cx = # of bytes to insert)
	;
					; bx <- file handle
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	
	;
	; If cx is negative we want to delete space
	;
	tst	cx
	jz	quit			; Quit if nothing to insert
	js	deleteSpace
	call	DBInsertAt		; Make me some space
	jmp	quit			; Quit, returning any error

deleteSpace:
	neg	cx			; cx <- # of bytes to delete
	call	DBDeleteAt		; Delete the space
quit:
	.leave
	ret
InsertIntoCurrentCell	endp

SpreadsheetNameCode	ends

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the name block

CALLED BY:	Global
PASS:		bx	= File handle, map-item should already be allocated.
RETURN:		ax	= VM handle of name block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NameInit	proc	near
	uses	cx, es, di, bp
	.enter
	;
	; Initialize our name block.
	;
	clr	ax			; ax <- no user ID
	mov	cx, size NameHeader	; cx <- size
	call	VMAlloc			; ax <- VM block for names
	push	ax			; save VM handle of name array
	;
	; Lock and initialize the name block.
	;
	call	VMLock			; ax <- seg addr, bp <- mem handle
	mov	es, ax
	mov	es:NH_definedCount, 0
	mov	es:NH_undefinedCount, 0
	mov	es:NH_nextToken, 0
	mov	es:NH_blockSize, size NameHeader
	call	VMDirty			; Mark it as dirty
	call	VMUnlock		; Unlock it, we don't need it anymore
	pop	ax			; ax <- VM handle of name array

	.leave
	ret
NameInit	endp

InitCode	ends
