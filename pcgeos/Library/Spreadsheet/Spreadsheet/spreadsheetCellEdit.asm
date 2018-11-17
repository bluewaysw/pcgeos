COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetCellRangeEdit.asm

AUTHOR:		John Wedgwood, Feb 11, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/11/91	Initial revision

DESCRIPTION:

	$Id: spreadsheetCellEdit.asm,v 1.1 97/04/07 11:14:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetParseRangeReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse text into a range reference, if possible

CALLED BY:	MSG_SPREADSHEET_PARSE_RANGE_REFERENCE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - ptr SpreadsheetFormatParseRangeParams
		    ss:bp.SFPRP_text - text (NULL terminated)

RETURN:		carry - set for error:
		    al - ParserScannerEvaluatorError
		else:
		    ss:bp.SFPRP_range - CellRange

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetParseRangeReference		method dynamic SpreadsheetClass,
					MSG_SPREADSHEET_PARSE_RANGE_REFERENCE
	mov	si, di
	mov	dx, ss
	lea	di, ss:[bp].SFPRP_text		;dx:di <- ptr to text
	push	bp
	call	ConvertToCellOrRange
	mov	bx, bp
	pop	bp
	mov	ss:[bp].SFPRP_range.CR_start.CR_row, ax
	mov	ss:[bp].SFPRP_range.CR_start.CR_column, cx
	mov	ss:[bp].SFPRP_range.CR_end.CR_row, dx
	mov	ss:[bp].SFPRP_range.CR_end.CR_column, bx
	ret
SpreadsheetParseRangeReference		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetFormatRangeReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a range reference

CALLED BY:	MSG_SPREADSHEET_FORMAT_RANGE_REFERENCE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - ptr to SpreadsheetFormatParseRangeParams
		    ss:bp.SFPRP_range - CellRange to format
RETURN:		ss:bp.SFPRP_text - formatted text (NULL-terminated)

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetFormatRangeReference		method dynamic SpreadsheetClass,
					MSG_SPREADSHEET_FORMAT_RANGE_REFERENCE
	segmov	es, ss
	lea	di, ss:[bp].SFPRP_text		;es:di <- ptr to buffer
	mov	ax, ss:[bp].SFPRP_range.CR_start.CR_row
	mov	cx, ss:[bp].SFPRP_range.CR_start.CR_column
	mov	dx, ss:[bp].SFPRP_range.CR_end.CR_row
	mov	bx, ss:[bp].SFPRP_range.CR_end.CR_column
	call	ParserFormatRangeReference

	ret
SpreadsheetFormatRangeReference		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToCellOrRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert text into either a cell or a range

CALLED BY:	GenCellRangeEditGetData, GotoCell
PASS:		dx:di	= Pointer to the text (NULL terminated)
		ds:si	= Instance data of the current spreadsheet
RETURN:		carry set if the text is neither a cell or range
			al	= Error code
			(ah, cx, dx, bp destroyed)
		carry clear otherwise:
			ax,cx	= Row/Column of first cell in range
			dx,bp	= Row/Column of last cell in range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertParams	union
    CP_parseParams	SpreadsheetParserParameters <>
    CP_evalParams	SpreadsheetEvalParameters <>
ConvertParams	ends

ConvertToCellOrRange	proc	near
	class	SpreadsheetClass
params		local	ConvertParams
SBCS< parseBuffer	local	256 dup (char)				>
DBCS< parseBuffer	local	256 dup (wchar)				>
	push	di
	uses	bx, es, ds, si
	.enter
	;
	; Initialize the frame
	;
	mov	ss:params.CP_parseParams.SPP_text.segment, dx
	mov	ss:params.CP_parseParams.SPP_text.offset,  di

	mov	ss:params.CP_parseParams.SPP_expression.segment, ss
	lea	ax, ss:parseBuffer
	mov	ss:params.CP_parseParams.SPP_expression.offset, ax
	
	mov	ss:params.CP_parseParams.SPP_exprLength, length parseBuffer
	
	mov	ss:params.CP_parseParams.SPP_parserParams.PP_flags, \
							mask PF_CELLS or \
							mask PF_NAMES
	
	;
	; Load up the instance pointer into *ds:si. It's going to be very
	; useful...
	;
	mov	si, ds:[si].SSI_chunk	; *ds:si <- instance ptr

	push	bp			; Save frame ptr
	lea	bp, ss:params		; ss:bp <- ptr to parameters
	mov	ax, MSG_SPREADSHEET_PARSE_EXPRESSION
	call	ObjCallInstanceNoLock	; Parse the expression
	pop	bp			; Restore frame ptr

	cmp	al, -1			; Check for an error
	jne	quitError		; Quit on error

	;
	; The expression parsed, now we need to evaluate it.
	;
	mov	ss:params.CP_evalParams.SEP_expression.segment, ss
	lea	ax, ss:parseBuffer
	mov	ss:params.CP_evalParams.SEP_expression.offset, ax
	
	push	bp			; Save frame ptr
	lea	bp, ss:params		; ss:bp <- ptr to parameters
	mov	ax, MSG_SPREADSHEET_EVAL_EXPRESSION
	mov	cl, mask EF_KEEP_LAST_CELL
	call	ObjCallInstanceNoLock	; Evaluate the expression
	pop	bp			; Restore frame ptr

	cmp	al, -1			; Check for an error
	jne	quitError		; Quit on error

	;
	; Make sure that the result is a range.
	;
	test	ss:params.CP_evalParams.SEP_result.ASE_type, mask ESAT_RANGE
	jnz	grabRange
	;
	; Error: Neither a cell nor a range.
	;
	mov	al, PSEE_RESULT_SHOULD_BE_CELL_OR_RANGE
	jmp	quitError		; Branch to signal an error

grabRange:
	mov	ax, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_firstCell.CR_row
	mov	cx, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_firstCell.CR_column
	mov	dx, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_lastCell.CR_row
	mov	di, ss:params.CP_evalParams.SEP_result.ASE_data.\
					ESAD_range.ERD_lastCell.CR_column

	andnf	ax, mask CRC_VALUE	; Only want the values
	andnf	cx, mask CRC_VALUE	;   not the flags
	andnf	dx, mask CRC_VALUE
	andnf	di, mask CRC_VALUE

	clc				; Signal: no error
quit:
	.leave
	mov	bp, di			; Return lastCell.column in bp
	pop	di
	ret

quitError:
	stc				; Signal: error
	jmp	quit			; Branch to quit
ConvertToCellOrRange	endp

EditCode	ends
