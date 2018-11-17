COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetFunctions.asm

AUTHOR:		John Wedgwood, Aug 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 8/21/91	Initial revision

DESCRIPTION:
	Functions implemented in the spreadsheet application.

	$Id: spreadsheetFunctions.asm,v 1.1 97/04/07 11:14:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetFunctionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCallFunctionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implement a spreadsheet-function.

CALLED BY:	PC_EvalFunction
PASS:		ss:bp	= EvalParameters
		si	= Function id
		cx	= Number of arguments
		es:di	= Operator stack
		es:bx	= Argument stack
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCallFunctionHandler	proc	far
	sub	si, FUNCTION_ID_FIRST_SPREADSHEET_FUNCTION
	mov	si, cs:functionHandlers[si]	; si <- handling routine
	
	call	si				; Call the handler
	ret
SpreadsheetCallFunctionHandler	endp

functionHandlers	word	offset cs:CellFunctionHandler


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellFunctionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the CELL function.

CALLED BY:	PC_EvalFunction
PASS:		cx	= # of arguments
		es:di	= Operator stack
		es:bx	= Argument stack
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The parameters to this routine are:
		"string"	- Attribute to get
		range		- First cell of range is the cell to get the
				  attribute from

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellFunctionHandler	proc	near
	uses	cx, dx, si
	.enter
	;
	; Check to make sure that we have only two arguments
	;
	cmp	cx, 2				; Must be two arguments
	jne	argCountError			; Branch if different

	;
	; Check the type of the two arguments. The top one (second arg) must
	; be a number.
	;
	mov	cx, bx				; Save the arg-stack ptr
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	jz	badTypeError			; Branch if second not a range
	
	;
	; Move to check the next argument (first arg). It must be a range.
	;
	call	SpreadsheetPop1Arg		; Remove number argument
	
	test	es:[bx].ASE_type, mask ESAT_RANGE
	mov	bx, cx				; Restore stack (flags intact)
	jz	badTypeError			; Branch if second not a range
	
	;
	; The types are correct, check to see if the number is in bounds.
	;
	call	FloatFloatToDword		; dx.ax <- value
	tst	dx				; Check for out of bounds
	jnz	badNumError
	
	tst	ax				; 0 isn't valid
	jz	badNumError

	cmp	ax, length cellInfoHandlers	; Check against table length
	ja	badNumError
	
	;
	; The types are correct and the numeric argument is in bounds. Get
	; the data.
	;
	; es:bx	= Argument stack
	; es:di	= Operator stack
	; ss:bp	= EvalParameters
	; ax	= The type of data to get.
	;
	mov	si, ax				; si <- type of data to get
	dec	si				; Zero based table
	shl	si, 1				; Index into table of words
	
	call	SpreadsheetPop1Arg		; Remove number argument
	
	mov	ax, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_row
	mov	cx, es:[bx].ASE_data.ESAD_range.ERD_firstCell.CR_column
	
	and	ax, mask CRC_VALUE
	and	cx, mask CRC_VALUE
	
	call	SpreadsheetPop1Arg		; Remove range argument

	;
	; ss:bp	= EvalParameters
	; es:bx	= Argument stack
	; es:di	= Operator stack
	; ax	= Row
	; cx	= Column
	; si	= Offset into table of handlers to call
	;
	call	cs:cellInfoHandlers[si]

quit:
	;
	; carry set on error
	; al	= Error code
	;
	; Otherwise:
	; es:bx	= Argument stack with result
	; es:di	= Operator stack
	;
	.leave
	ret

argCountError:
	;
	; Wrong number of arguments.
	; es:bx	= Argument stack
	; es:di	= Operator stack
	;
	mov	al, PSEE_BAD_ARG_COUNT

propError:
	mov	cx, 2
	call	ParserEvalPropagateEvalError
	jmp	quit

badTypeError:
	mov	al, PSEE_WRONG_TYPE
	jmp	propError

badNumError:
	mov	al, PSEE_NUMBER_OUT_OF_RANGE
	jmp	propError
CellFunctionHandler	endp

cellInfoHandlers	word	offset cs:Return1


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Return1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Return1	proc	near
	uses	cx
	.enter
	mov	cx, 1				; Push a 1
	call	ParserEvalPushNumericConstantWord
	.leave
	ret
Return1	endp

SpreadsheetFunctionCode	ends
