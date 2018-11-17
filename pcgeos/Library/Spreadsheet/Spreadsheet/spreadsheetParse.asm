COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetParse.asm

AUTHOR:		John Wedgwood, Mar 22, 1991

ROUTINES:
	Name			Description
	----			-----------
	ParserCallback		Callback routine for the parser
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/22/91		Initial revision


DESCRIPTION:
	Callback routine for the parser and evaluator. Includes support code.
		
	DBCS conversion still needs work.

	$Id: spreadsheetParse.asm,v 1.1 97/04/07 11:14:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for parser/evaluator library.

CALLED BY:	via CP_callback
PASS:		al	= CallbackType
		other arguments depending on the type
RETURN:		depends on the argument type
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserCallback	proc	far
	push	si			; Save whatever is passed in si
	clr	ah
	shl	ax, 1			; ax <- index into table of words
	mov	si, ax			; si <- index into a table of words
	mov	ax, cs:callbackHandlers[si]
	pop	si			; Restore whatever was passed in si
	call	ax			; Call the handler for the callback
	ret
ParserCallback	endp

;
; One handler for each of the callback types. All handlers are prefixed by
; the letters "PC" to show that they are Parser callback handlers.
;
callbackHandlers	\
	nptr	offset cs:PC_FunctionToToken,	; CT_FUNCTION_TO_TOKEN
		offset cs:PC_NameToToken,	; CT_NAME_TO_TOKEN
		offset cs:PC_CheckNameExists,	; CT_CHECK_NAME_EXISTS
		offset cs:PC_CheckNameSpace,	; CT_CHECK_NAME_SPACE
		offset cs:PC_EvalFunction,	; CT_EVAL_FUNCTION
		offset cs:PC_LockName,		; CT_LOCK_NAME
		offset cs:PC_Unlock,		; CT_UNLOCK
		offset cs:PC_FormatFunction,	; CT_FORMAT_FUNCTION
		offset cs:PC_FormatName,	; CT_FORMAT_NAME
		offset cs:PC_CreateCell,	; CT_CREATE_CELL
		offset cs:PC_EmptyCell,		; CT_EMPTY_CELL
		offset cs:PC_NameToCell,	; CT_NAME_TO_CELL
		offset cs:PC_FunctionToCell,	; CT_FUNCTION_TO_CELL
		offset cs:PC_DerefCell,		; CT_DEREF_CELL
		offset cs:PC_SpecialFunction	; CT_SPECIAL_FUNCTION
CheckHack <(length callbackHandlers) eq (CallbackType)>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_FunctionToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string into a function-id

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters on stack
		ds:si	= Pointer to the text of the identifier.
		cx	= Length of the text.
RETURN:		carry set if the string is a function
		di	= Function ID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_FunctionToToken	proc	near
	uses	ax, cx, dx, bp, es
	.enter
	;
	; Check the table of spreadsheet functions.
	;
FXIP<	mov_tr	ax, bx				; save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			; es = dgroup		>
FXIP<	mov_tr	bx, ax				; restore bx value	>
NOFXIP<	segmov	es, dgroup, di			; es <- segment of tables >
SBCS<	clr	di				; Start at the start..	>
DBCS<	clr	di, dx				; Start at the start..	>
	mov	ax, length funcIDTable		; ax <- # of functions

findFuncLoop:
	push	ax, di				; Save # left to do, ptr
	mov	di, es:funcNameTable[di]	; di <- offset to the name
	
	mov	dl, {byte} es:[di]		; dl <- func string length
	inc	di				; Move to string data
	
	;
	; ds:si	= Pointer to the string to compare agains
	; cx	= Length of that string
	; es:di	= Pointer to the string in the function list (SBCS!)
	; dl	= Length of that string
	;
	cmp	cl, dl				; Compare the lengths
	jne	nextFunction			; Branch if not the same
	
SBCS<	call	LocalCmpStringsNoCase				>
DBCS<	call	SSheetCmpStringsDBCSToSBCSNoCase			>
	;
	; Zero flag set (equal) if the strings matched
	;

nextFunction:
	;
	; Zero flag set (equal) if the strings match
	;
	pop	ax, di				; Restore # left to do, ptr
	
	je	foundMatch			; Branch if strings matched

	add	di, size word			; Move to next entry

	dec	ax				; One less to do
	jnz	findFuncLoop			; Loop to try the next one
	
	;
	; No matching function was found, check the subclass
	; ds:si	= Pointer to the string
	; cx	= Length of the string
	;
	mov	dx, ds				; Pass pointer in dx:di
	mov	di, si

	mov	ax, MSG_SPREADSHEET_FUNCTION_TO_TOKEN
	call	ParserCallSubclass		; zero flag set if no call made
						; carry clear if no call made
						; Nukes ax, cx, dx, bp
	
	mov	di, bp				; di <- token from callback
	;
	; If the call was made, then the callback set the carry correctly
	; If the call wasn't made, then the carry is clear (as we want it).
	;
quit:
	.leave
	ret

foundMatch:
	mov	ax, es:funcFlagsTable[di]	; ax <- flags
	or	ss:[bp].PP_flags, al		; Possibly mark this as special
	mov	di, es:funcIDTable[di]		; di <- identifier
	stc					; Signal: found match
	jmp	quit
PC_FunctionToToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_NameToToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string into a name token

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to the name text
		cx	= Length of the name text
RETURN:		cx	= Name token
		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	If a name is already defined, then we can add the current row/column
	to the dependency list for that name.
	
	If a name is not defined, then we create an undefined name and add
	the current row/column to the dependency list for that name.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_NameToToken_far	proc	far
	call	PC_NameToToken
	ret
PC_NameToToken_far	endp

PC_NameToToken	proc	near
	uses	dx, es, di, ds, si
	.enter
	segmov	es, ds, di		; es:di <- ptr to the text
	mov	di, si
					; ds:si <- ptr to spreadsheet
	lds	si, ss:[bp].CP_cellParams

	push	cx			; Save length of the name
	call	NameTokenFromText	; ax <- the token
					; cl <- flags
	pop	cx			; Restore length of the name
	jc	quit			; Quit if found
	;
	; If the name wasn't found and we are not allowing undefined names
	; we return an error.
	;
	test	ss:[bp].PP_flags, mask PF_NEW_NAMES
	jnz	addUndefinedName	; Branch if we are allowing undefineds
	;
	; We aren't allowing them.
	;
	mov	al, PSEE_UNDEFINED_NAME
	stc				; Signal an error
	jmp	quitError		; Quit
addUndefinedName:
	;
	; The name wasn't found, we need to add an undefined name entry
	;
	call	NameAddUndefinedEntry	; ax <- the token
	
	mov	dx, ax			; Save token in ax
	call	CreateNameCell		; Make an empty cell definition
	jc	quitError		; Branch on error
	mov	ax, dx			; Restore token
quit:
	mov	cx, ax			; Return the token in cx
	clc				; Signal: no error
quitError:
	.leave
	ret
PC_NameToToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_CheckNameExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a name already exists.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters
		ds:si	= Pointer to the text of the name
		cx	= Length of the name
RETURN:		carry set if the name does exist
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_CheckNameExists	proc	near
	uses	ax, cx, di, si, ds, es
	.enter
	segmov	es, ds, di		; es:di <- ptr to the text
	mov	di, si
					; ds:si <- ptr to spreadsheet
	lds	si, ss:[bp].CP_cellParams

	call	NameTokenFromText	; Check for name existing
	jnc	quit			; Branch if name doesn't exist
	
	;
	; Name does exist, check the flags.
	;
	test	cl, mask NF_UNDEFINED	; Check for undefined (clears carry)
	jnz	quit			; Branch if undefined
	
	;
	; Name does exist and is defined
	;
	stc				; Signal: defined name
quit:
	.leave
	ret
PC_CheckNameExists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_CheckNameSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure there's enough space to create a certain
		number of names.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to ParserParameters
		cx	= # of names we want to allocate
RETURN:		carry set on error
		al	= PSEE_NOT_ENOUGH_NAME_SPACE if error
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	if (cx > MAX_NAMES - nameBlock.nDefined + nameBlock.nUndefined) then
	    return error
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_CheckNameSpace	proc	near
	uses	ds, si
	.enter
	lds	si, ss:[bp].CP_cellParams

	call	NameCountNamesLeft	; ax <- # of names left
	cmp	cx, ax			; Check for enough space
	jbe	quitNoError		; Branch if there is space

	;
	; There isn't enough space for the names.
	;
	mov	al, PSEE_NOT_ENOUGH_NAME_SPACE
	stc				; Signal error
	jmp	quit			; Branch to leave...

quitNoError:
	clc				; Signal: no error

quit:
	.leave
	ret
PC_CheckNameSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_EvalFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate a spreadsheet function.

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

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_EvalFunction	proc	near
	uses	cx, dx, bp, di
	.enter
	cmp	si, FUNCTION_ID_LAST_SPREADSHEET_FUNCTION
	jae	applicationFunction		; Branch if not ours

	;
	; Call our own handler.
	;
	call	SpreadsheetCallFunctionHandler
quit:
	.leave
	ret

applicationFunction:
	sub	sp, size SpreadsheetEvalFuncParameters
	mov	di, sp				; ss:di <- parameters
	
	;
	; Fill in the stack frame
	;
	mov	ss:[di].SEFP_stacksSeg, es
	mov	ss:[di].SEFP_opStackPtr, di
	mov	ss:[di].SEFP_argStackPtr, bx
	mov	ss:[di].SEFP_funcID, si
	mov	ss:[di].SEFP_nArgs, cx

	mov	ax, MSG_SPREADSHEET_EVAL_FUNCTION
	call	ParserCallSubclass		; Call the subclass
	
	lahf					; Save flags
	add	sp, size SpreadsheetEvalFuncParameters
	sahf					; Restore flags
	jmp	quit
PC_EvalFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_LockName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down a name definition

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to the EvalParameters
		cx	= Name token
RETURN:		carry set on error
		al	= error code
		if no error:
		  ds:si	= Pointer to the definition of the name
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The only error returned by this routine is "PSEE_UNDEFINED_NAME".
	This is not a "serious" error, but we return it anyway, knowing that
	the caller will turn it into an error token on the stack rather
	than aborting processing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_LockName	proc	near
	push	ds, si			; Save passed pointer in case of error
					; ds:si <- ptr to spreadsheet
	lds	si, ss:[bp].CP_cellParams
	call	NameLockDefinition	; ds:si <- ptr to definition
					; carry set on error
	jnc	quitNoError		; Branch if no error
	;
	; There was an error
	;
	pop	ds, si			; Restore passed pointer
quit:
	ret

quitNoError:
	pop	ax, ax			; Discard passed pointer
	jmp	quit
PC_LockName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_Unlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a cell-item block.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds	= Segment address of the block to unlock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_Unlock	proc	near
	uses	es, ds, si
	.enter
	segmov	es, ds, si		; es <- segment address
					; ds:si <- ptr to spreadsheet instance
	lds	si, ss:[bp].CP_cellParams
	
	SpreadsheetCellUnlock		; Release the name data
	.leave
	ret
PC_Unlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_FormatFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a function.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= FormatParameters
		es:di	= Place to store the text
		dx	= Maximum number of characters to write (length)
		cx	= Function id
RETURN:		es:di	= Pointer passed the inserted text
		dx	= # left after we've written ours
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version
	witt	11/10/93	DBCS-ized string copy

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_FormatFunction	proc	near
	uses	ax, cx, si, ds
	.enter
	cmp	ax, FUNCTION_ID_LAST_SPREADSHEET_FUNCTION
	jae	applicationFunction

NOFXIP<	segmov	ds, dgroup, ax			; ds <- segment of tables >
FXIP<	mov_tr	ax, bx				; save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			; ds = dgroup		>
FXIP<	mov_tr	bx, ax				; restore bx value	>
	mov	ax, length funcIDTable		; ax <- # of table entries
	clr	si				; Start at the start
findLoop:
	cmp	cx, ds:funcIDTable[si]		; Compare to table
	je	found				; Branch if found

	add	si, size word			; Move to next one

	dec	ax				; One less entry to do
	jnz	findLoop			; Loop to check it

EC <	ERROR	FUNCTION_MUST_EXIST				>

found:
	;
	; ds:funcNameTable[si] == Offset to the function to use
	;
	mov	si, ds:funcNameTable[si]	; ds:si <- ptr to function
	clr	ch
	mov	cl, {byte} ds:[si]		; cx <- length
	inc	si				; ds:si <- ptr to text
	
	;
	; ds:si	= Function name (Always ASCII)
	; cx	= Length of function name
	; es:di	= Place to put the text
	; dx	= Max # of characters to write
	;
	cmp	cx, dx				; cx <- MIN( cx, dx )
	jbe	gotLength
	mov	cx, dx
gotLength:
	
	sub	dx, cx				; dx <- # of chars left
if DBCS_PCGEOS
	clr	ah
expandSBLoop:
	lodsb					; get SBCS ASCII..
	stosw					; ..put DBCS Unicode
	loop	expandSBLoop
else
	rep	movsb				; Copy the text
endif
quit:
	.leave
	ret

applicationFunction:
	;
	; es:di	= Destination (Message header sez can hold 256 chars/wchars)
	; dx	= Max count
	; cx	= Function ID
	;
	mov	ax, di				; ax <- dest offset

SBCS<	sub	sp, 256				; Allocate buffer for function	>
DBCS<	sub	sp, 256*(size wchar)		; Allocate buffer for function	>
	mov	di, sp				; Pass ptr in ss:di

	push	dx, ax				; Save max count, dest ptr
	mov	ax, MSG_SPREADSHEET_FORMAT_FUNCTION
	call	ParserCallSubclass		; Zero flag set if no call made
						; Carry flag clear if no call
						; Nukes ax, cx, dx, bp
EC <	ERROR_Z	APPLICATION_MUST_HANDLE_THIS_FUNCTION		>
	pop	dx, ax				; Restore max count, dest ptr

	;
	; Copy the data.
	;
	segmov	ds, ss, si			; ds:si <- source
	mov	si, di
	
	segmov	es, ss, di			; es:di <- dest
	mov	di, ax
	
	;
	; ds:si	= Source
	; cx	= Length of source
	; es:di	= Dest
	; dx	= Max count
	;
	cmp	cx, dx				; cx <- MIN( cx, dx )
	jbe	gotLength2
	mov	cx, dx
gotLength2:
	
	sub	dx, cx				; dx <- # of chars left
	LocalCopyNString 			; Copy the text

	;
	; Now restore the stack and return
	;
SBCS<	add	sp, 256				; Restore stack  	>
DBCS<	add	sp, 256*(size wchar)		; Restore stack  	>
	jmp	quit
PC_FormatFunction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_FormatName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a callback from the format code

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to FormatParameters
		es:di	= Place to store the text
		cx	= Name token
		dx	= Max # of characters to write (length)
RETURN:		es:di	= Pointer past the inserted text
		dx	= # of characters written (length)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The code that writes the name into the buffer must be aware of the
	number of characters that are left in the buffer. This number
	is stored in the structure on the stack in the field FP_nChars (length).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version
	witt	11/10/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_FormatName	proc	near
	uses	ds, si
	.enter
					; ds:si <- ptr to spreadsheet instance
	lds	si, ss:[bp].CP_cellParams
	call	NameTextFromToken	; dx <- # of chars written
	.leave
	ret
PC_FormatName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNameCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a cell for an undefined name

CALLED BY:	PC_NameToToken, when the name wasn't found.
PASS:		ss:bp	= Pointer to ParserParameters
		ax	= Token for the name
RETURN:		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Create a cell for an undefined name. When a name isn't defined we
	give it a default definition of "0". The reason we do this is so
	that the evaluator will not choke when it finds something like:
		honk+hoot    (where "hoot" isn't defined)
	If we didn't do this and instead left "hoot" with no definition the
	addition operator would only be getting a single argument and would
	barf. This spares us that grief.
	
	In generating dependencies it doesn't matter what the definition of
	the name is as long as it resolves to something that can be supplied
	as an argument to an operator/function.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Some day this "emptyNameCell" will probably have a more complete
; data-structure.
;
EmptyNameCellStruct	struct
    EMC_base	CellFormula <>
    EMC_token	ParserTokenType PARSER_TOKEN_CELL
    EMC_number	FloatNum <>
    EMC_eoe	ParserTokenType PARSER_TOKEN_END_OF_EXPRESSION
EmptyNameCellStruct	ends

emptyNameCell	EmptyNameCellStruct <
    <					; EMC_base
	<					; CellCommon
	    0,					;   CC_dependencies
	    CT_FORMULA,				;   CC_type
	    0,					;   CC_recalcFlags
	    0,					;   CC_attrs
	    0					;   CC_notes
	>,
	RT_VALUE,				; CF_return
	<RV_VALUE <0,0,0,0,0>>,			; CF_current
	size FloatNum + 2			; CF_formulaSize
	
    >,
    PARSER_TOKEN_NUMBER,		; EMC_token
    <0,0,0,0,0>,			; EMC_number
    PARSER_TOKEN_END_OF_EXPRESSION	; EMC_eoe
>

CreateNameCell	proc	near
	uses	cx, dx, ds, si, es, di
	.enter
	mov	cx, ax			; cx <- column
	mov	ax, NAME_ROW		; ax <- the row
	segmov	es, cs, di		; es:di <- ptr to the "new cell" struct
	mov	di, offset cs:emptyNameCell
	mov	dx, size emptyNameCell	; dx <- size of the data
					; ds:si <- ptr to spreadsheet instance
FXIP<	xchg	cx, dx			; cx = size of data		>
FXIP<	call	SysCopyToStackESDI	; es:di = ptr to struct on stack >
FXIP<	xchg	cx, dx			; restore both cx and dx	>
	lds	si, ss:[bp].CP_cellParams
	SpreadsheetCellReplaceAll
FXIP<	call	SysRemoveFromStack	; release stack space		>
	clc				; Signal: no error
	.leave
	ret
CreateNameCell	endp

	;
	; Create a name cell, given that the instance is already in ds:si
	; Destroys nothing
	;
CreateNameCellInstance	proc	far
	uses	ax, cx, dx, ds, si, es, di
	.enter
	mov	cx, ax			; cx <- column
	mov	ax, NAME_ROW		; ax <- the row
	segmov	es, cs, di		; es:di <- ptr to the "new cell" struct
	mov	di, offset cs:emptyNameCell
	mov	dx, size emptyNameCell	; dx <- size of the data
					; ds:si <- ptr to spreadsheet instance
FXIP<	xchg	cx, dx			; cx = size of the data		>
FXIP<	call	SysCopyToStackESDI	; es:di = ptr to stuct on stack	>
FXIP<	xchg	cx, dx			; restore cx and dx		>
	SpreadsheetCellReplaceAll
FXIP<	call	SysRemoveFromStack	; release stack space		>
	clc				; Signal: no error
	.leave
	ret
CreateNameCellInstance	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_CreateCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an empty cell

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		dx	= Row of cell to create
		cx	= Column of cell to create
RETURN:		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_CreateCell_far	proc	near
	call	PC_CreateCell
	ret
PC_CreateCell_far	endp
	
PC_CreateCell	proc	near
	uses	ds, si
	.enter
	lds	si, ss:[bp].CP_cellParams	; ds:si <- spreadsheet instance
	mov	ax, dx				; ax <- row
	call	SpreadsheetCreateEmptyCell	; Create the cell
	.leave
	ret
PC_CreateCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_EmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a cell no longer has dependencies

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		dx	= Row of cell
		cx	= Column of cell
RETURN:		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the cell contains no data other than a dependency
	list then we want to remove the cell.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_EmptyCell_far	proc	far
	call	PC_EmptyCell
	ret
PC_EmptyCell_far	endp

PC_EmptyCell	proc	near
	uses	bx, cx, dx, di, si, bp, ds, es
	.enter
					; ds:si <- spreadsheet instance
	lds	si, ss:[bp].CP_cellParams
	mov	ax, dx			; ax <- row
					; cx already holds the columne

	cmp	ax, NAME_ROW		; Check for removing a name
	je	removeName
	;
	; Not a name. 
	; The only situation in which we can remove a cell is when it is
	; marked as an empty cell and it contains the default style.
	;
	SpreadsheetCellLock		; *es:di <- ptr to the cell
	;
	; The cell must exist, otherwise we wouldn't have been able to remove
	; the last dependency from it.
	;
EC <	ERROR_NC CELL_DOES_NOT_EXIST		>
	clr	bx			; bx == 0 indicates we want to keep the
					;    cell

	mov	di, es:[di]		; es:di <- ptr to cell data
	cmp	es:[di].CC_type, CT_EMPTY
	jne	unlockAndDoSomething	; Branch if it's not empty
	cmp	es:[di].CC_attrs, DEFAULT_STYLE_TOKEN
	jne	unlockAndDoSomething	; Branch if it has a style
	cmp	es:[di].CC_notes.segment, 0
	jne	unlockAndDoSomething	; Branch if it has a note
	
	mov	bx, -1			; Mark cell as nukable
unlockAndDoSomething:
	;
	; bx == 0 if we want to keep the cell
	;
	SpreadsheetCellUnlock		; Release the cell
	tst	bx			; Check for keeping this cell
	jz	quitNoError		; Quit if we want to keep the cell

deleteCell::
EC <	push	es, di			; Need a reasonable pointer	>
EC <	segmov	es, cs			; Get some reasonable pointer	>
EC <	clr	di							>

	clr	dx			; dx == 0 means remove the cell
	SpreadsheetCellReplaceAll

EC <	pop	es, di			; Restore nuked ptr		>

quitNoError:
	clc				; Signal: no error
	.leave
	ret

removeName:
	jmp	quitNoError

;;;
;;; This code was replaced with the branch to 'quitNoError' because we now
;;; cleanup unreferenced and undefined names at a later time. This solves a
;;; nasty bug where an undefined name is encountered while parsing, then
;;; removed when the dependencies are removed. Attempting to add the new
;;; dependencies results in not finding the name that used to be there.
;;;			-jw  3/13/93
if	0
	;
	; Removing a name requires some extra work (removing the name from
	; the name data structure). We also can only remove undefined names.
	;
	call	NameCheckDefined	; returns carry set if it's defined
	jc	quitNoError		; Branch if it's a defined name
	;
	; Name is undefined, remove it from the name-list.
	;
	call	NameRemoveEntry		; Remove the name-list entry
	jmp	deleteCell		; Branch to delete the definition
endif
PC_EmptyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_NameToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a name token to a cell reference

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= Pointer to DependencyParameters
		cx	= Name token
RETURN:		dx	= Row of the cell
		cx	= Column of the cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_NameToCell	proc	near
	mov	dx, NAME_ROW		; dx <- row
					; cx already holds the column
	ret
PC_NameToCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_FunctionToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a function to a cell.

CALLED BY:	ParserCallback via callbackHandlers
PASS:		ss:bp	= EvalParameters
		cx	= Function ID
RETURN:		dx	= Row (0 means no dependency required)
		cx	= Column
		carry set on error
		al	= Error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_FunctionToCell	proc	near
	uses	di, bp
	.enter
	cmp	di, FUNCTION_ID_LAST_SPREADSHEET_FUNCTION
	jae	applicationDefinedFunction

	;
	; It's one of our own. In this case we don't need any dependencies.
	;
	clr	dx				; Signal: no dependency needed
						; (clears the carry)
quit:
	;
	; Carry set if error
	; al	= Error code
	; dx	= Row
	; cx	= Column
	;
	.leave
	ret

applicationDefinedFunction:
	;
	; Call the application to handle it.
	;
	mov	ax, MSG_SPREADSHEET_FUNCTION_TO_CELL
	call	ParserCallSubclass		; Zero flag set if no call made
						; Carry flag clear if no call
						; Nukes ax, cx, dx, bp

EC <	ERROR_Z	APPLICATION_MUST_HANDLE_THIS_FUNCTION		>
	jmp	quit
PC_FunctionToCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_DerefCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a cell

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

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	A little complexity here... If the top of the operator stack contains
	the CELL function then we don't want to dereference the cell since
	this operator needs the cell itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_DerefCell_far	proc	far
	call	PC_DerefCell
	ret
PC_DerefCell_far	endp
			
PC_DerefCell	proc	near
	uses	cx, dx, si, es, ds
	.enter
	cmp	es:[di].OSE_type, ESOT_FUNCTION	; Check for function
	jne	deref				; Branch if not

	cmp	es:[di].OSE_data.ESOD_function.EFD_functionID, \
					FUNCTION_ID_SPREADSHEET_CELL
	je	quit				; Branch if it's @CELL function
						; (carry clear if branch taken)

deref:
	;
	; remove the old argument from the stack if necessary
	;
	test	ch, mask DF_DONT_POP_ARGUMENT	; Don't remove argument?
	jne	10$				; Branch if so

	call	SpreadsheetPop1Arg		; Remove cell reference
10$:
	;
	; Now we actually do the dereferencing.
	;
	mov	ax, dx				; ax <- the row
						; cx already holds the column
						; ds:si <- ptr to parameters
	lds	si, ss:[bp].CP_cellParams
	
	push	es, di				; Save operator stack pointer

	clr	ch
	SpreadsheetCellLock			; *es:di <- ptr to the cell data
	jnc	noData				; Branch if cell doesn't exist

	segmov	ds, es
	mov	ax, ds:[di]			; ds:ax <- ptr to cell data
	
	pop	es, di				; Restore operator stack pointer
	
	mov	si, ax				; ds:si <- ptr to cell data
	;
	; ds:si	= ptr to cell data
	; es:di	= ptr to operator stack
	; es:bx	= ptr to argument stack
	; ss:bp	= ptr to EvalParameters
	;
	push	bx				; Save arg-stack ptr
	clr	bh
	mov	bl, ds:[si].CC_type		; bx <- type of the cell
EC <	cmp	bx, CellType			; Do we have a legal cell type?>
EC <	ERROR_AE BAD_CELL_TYPE						       >
	mov	ax, cs:derefHandlers[bx]
	pop	bx				; Restore arg-stack ptr

	call	ax				; Call the handler
	
	lahf					; Save error flag (carry)

	segmov	es, ds				; es <- segment address of cell
						; ds:si <- ptr to cell params
	lds	si, ss:[bp].CP_cellParams
	SpreadsheetCellUnlock			; Release the cell
	
	sahf					; Restore error flag (carry)
quit:
	.leave
	ret

noData:
	;
	; The cell doesn't exist, push a number (0) on the stack.
	;
	pop	ax, ax			; Discard pointer on stack
	call	DerefEmpty		; Deref an empty cell
	jmp	quit

PC_DerefCell	endp

derefHandlers	nptr	offset cs:DerefText,		; CT_TEXT
			offset cs:DerefConstant,	; CT_CONSTANT
			offset cs:DerefFormula,		; CT_FORMULA
			offset cs:DerefError,		; CT_NAME
			offset cs:DerefError,		; CT_CHART
			offset cs:DerefEmpty,		; CT_EMPTY
			offset cs:DerefDisplayFormula	; CT_DISPLAY_FORMULA
CheckHack <(size derefHandlers) eq CellType>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a text cell

CALLED BY:	DerefCell via derefHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to cell data
		es:bx	= Pointer to argument stack
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefText	proc	near
	uses	cx, si, ds
	.enter
	push	es, di			; Save segment and offset of op-stack

	add	si, size CellText	; ds:si <- ptr to the text
	;
	; Need cx = size of the string. The string is null terminated.
	;
SBCS<	clr	al			; al <- byte to find	>
DBCS<	clr	ax			; al <- byte to find	>
	segmov	es, ds			; es:di <- ptr to text to scan
	mov	di, si
SBCS<	mov	cx, -1			; cx <- # of chars to scan	>
DBCS<	mov	cx, MAX_NAME_BLOCK_SIZE/(size wchar) ; cx <- max chars to scan	>
	LocalFindChar			; Find the char
	;
	; If there is no null then somehow the cell data has gotten screwed up.
	;
EC <	ERROR_NZ NO_NULL_BYTE_FOUND_IN_TEXT_CELL	>
	;
	; es:di = pointer past the NULL
	;
	sub	di, si			; di <- # of bytes in the string (size)

	mov	cx, di			; cx <- string size (for Skip123Quote)
	LocalPrevChar	escx
	pop	es, di			; Restore ptr to op-stack

	call	Skip123QuoteFar		; cx <- updated string size

	call	ParserEvalPushStringConstant	; Push the label onto the stack
	.leave
	ret
DerefText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a constant cell

CALLED BY:	DerefCell via derefHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to cell data
		es:bx	= Pointer to argument stack
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefConstant	proc	near
	uses	si
	.enter
	add	si, offset CC_current	; ds:si <- ptr to value
	call	ParserEvalPushNumericConstant	; Push the constant
	.leave
	ret
DerefConstant	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a formula cell

CALLED BY:	DerefCell via derefHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to cell data
		es:bx	= Pointer to argument stack
		es:di	= Pointer to operator/function stack
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	CF_current.RV_TEXT is size; Skip123Quote uses size; and
	ParserEvalPushStringConstant uses size.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefFormula	proc	near
	class	SpreadsheetClass
	uses	ds, si, cx, dx
	.enter
	cmp	ds:[si].CF_return, RT_VALUE	; Check for value type
	jne	notValue			; Branch if not
	;
	; Is a value... Push the value.
	;
	add	si, offset CF_current		; ds:si <- ptr to fp-number
	call	ParserEvalPushNumericConstant		; Push the number
	jmp	quit

notValue:
	cmp	ds:[si].CF_return, RT_TEXT	; Check for text type
	jne	notText				; Branch if not

	mov	cx, ds:[si].CF_current.RV_TEXT	; cx <- size of the string
	add	si, ds:[si].CF_formulaSize	; ds:si <- ptr to the text
	add	si, size CellFormula
	call	Skip123QuoteFar
	call	ParserEvalPushStringConstant	; Push the string data
	jmp	quit

notText:
	;
	; For now just assume that this means it's an error
	;
	mov	al, CE_TYPE			; This is a good general error

	cmp	ds:[si].CF_return, RT_ERROR	; Check for error type
	jne	notStdError
	mov	al, ds:[si].CF_current.RV_ERROR
	;
	; If the error in the cell is that the cell is part of a circular
	; dependency loop, then the error associated with this cell is that
	; it references a cell which is part of a circular dependency loop.
	;
	cmp	al, CE_CIRC_DEPEND		; Check for part of loop
	jne	notStdError			; Branch if not
	;
	; If the error is a circular dependence and we are allowing 
	; circularities then we want to push a constant zero on the stack.
	; The error will go away as soon as the spreadsheet is recalc'd.
	;
	lds	si, ss:[bp].CP_cellParams	; ds:si <- spreadsheet instance
	test	ds:[si].SSI_flags, mask SF_ALLOW_ITERATION
	jnz	pushZero			; Branch if we're allowing it

	;
	; We aren't allowing iteration. Push the error on the stack.
	;
	mov	al, CE_CIRCULAR_REF		; This is the error then
notStdError:
	;
	; al == the CellError. Need to convert that to a PSEE_error
	;
	call	ConvertCellError		; al <- PSEE_error
	mov	dl, al				; Save error code in dl

	mov	al, mask ESAT_ERROR		; al <- arg type
	clr	cx				; No extra space
	call	ParserEvalPushArgument			; Push the argument
	jc	quit				; Quit on error

	mov	es:[bx].ASE_data.ESAD_error.EED_errorCode, dl
quit:
	.leave
	ret

pushZero:
	;
	; We are allowing iteration but we came upon a circular dependence.
	; This can only happen if we're recalculating after changing from not
	; allowing circularities to allowing them. Push a constant Zero on
	; the stack.
	;
	segmov	ds, cs, si			; ds:si <- constant
	mov	si, offset cs:zeroNumber
FXIP<	mov	cx, size zeroNumber		; cx = size of data	>
FXIP<	call	SysCopyToStackDSSI		; ds:si constant data on stack>
	call	ParserEvalPushNumericConstant	; Push me a constant.
FXIP<	call	SysRemoveFromStack		; release stack space	>
	jmp	quit				; Branch returning error
DerefFormula	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an error due to a bad dereference

CALLED BY:	DerefCell via derefHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to cell data
		es:bx	= Pointer to argument stack
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This means that the formula references something like a formula
	cell, name cell, or graph cell directly... Very bad.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefError	proc	near
	ERROR	-1
DerefError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference an emtpy cell

CALLED BY:	DerefCell via derefHandlers
PASS:		ss:bp	= Pointer to EvalParameters
		ds:si	= Pointer to cell data
		es:bx	= Pointer to argument stack
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefEmpty	proc	near
	uses	ds, si
	.enter
	segmov	ds, cs, si
	mov	si, offset cs:zeroNumber
FXIP<	push	cx							>
FXIP<	mov	cx, size FloatNum		; cx = size of data	>
FXIP<	call	SysCopyToStackDSSI		; ds:si = data on stack	>
	call	ParserEvalPushNumericConstant
FXIP<	call	SysRemoveFromStack		; release stack space	>
FXIP<	pop	cx							>
	;
	; Mark that this data came from an empty cell.
	;
	or	es:[bx].ASE_type, mask ESAT_EMPTY
	.leave
	ret
DerefEmpty	endp

zeroNumber	FloatNum <0,0,0,0,<0,0>>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefDisplayFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a display-formula cell.

CALLED BY:	DerefCell via derefHandlers
PASS:		nothing
RETURN:		carry set
		al	= CE_TYPE
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefDisplayFormula	proc	near
	uses	cx, dx
	.enter
	mov	al, CE_TYPE			; al <- cell error
	call	ConvertCellError		; al <- PSEE_error
	mov	dl, al				; Save error code in dl

	mov	al, mask ESAT_ERROR		; al <- arg type
	clr	cx				; No extra space
	call	ParserEvalPushArgument			; Push the argument
	jc	quit				; Quit on error

	mov	es:[bx].ASE_data.ESAD_error.EED_errorCode, dl
quit:
	.leave
	ret
DerefDisplayFormula	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PC_SpecialFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a special function request

CALLED BY:	ParserCallback via callbackHandlers
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Special function code.
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		    al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PC_SpecialFunction	proc	near
	uses	ds, si, cx
	.enter
	mov	si, cx				; si <- index to table
	mov	cx, cs:specialFunctionHandlers[si]

	lds	si, ss:[bp].CP_cellParams	; ds:si <- ptr to spreadsheet
	
	call	cx				; Call handler
	.leave
	ret
PC_SpecialFunction	endp

specialFunctionHandlers	word	offset cs:SFFilenameHandler,
				offset cs:SFPageHandler,
				offset cs:SFPagesHandler


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFFilenameHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the SF_FILENAME special function.

CALLED BY:	PC_SpecialFunction via specialFunctionHandlers
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Special function code.
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		    al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFFilenameHandler	proc	near
	class	SpreadsheetClass
	uses	ds, si, cx, dx
	.enter

	sub	sp, size FileLongName		; Allocate the stack frame
	mov	dx, sp				; ss:dx <- ptr to buffer

	push	bp				; Save passed frame ptr
	mov	cx, SF_FILENAME			; cx <- special function
	call	SubclassSpecialFunction		; Handle the function.
	pop	bp				; Restore passed frame ptr
DBCS<	shl	cx, 1				; cx <- filename size	>
	
	segmov	ds, ss, si			; ds:si <- ptr to string
	mov	si, sp
	
	;
	; ds:si = Pointer to file name buffer
	; cx	= Size of the file name (not counting the NULL)
	; ss:bp	= Passed frame ptr
	; es:bx	= Argument stack
	;
	call	ParserEvalPushStringConstant		; Push the filename
						; carry is set on error
	lahf					; Save error flag (carry)
	add	sp, size FileLongName		; Restore the stack
	sahf					; Restore error flag (carry)
	.leave
	ret
SFFilenameHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFPageHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the SF_PAGE special function.

CALLED BY:	PC_SpecialFunction via specialFunctionHandlers
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Special function code.
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		    al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFPageHandler	proc	near
	uses	cx, dx
	.enter
	mov	cx, SF_PAGE
	call	SubclassSpecialFunction		; cx <- Current page number
	call	ParserEvalPushNumericConstantWord		; Push the value
	.leave
	ret
SFPageHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFPagesHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the SF_PAGES special function.

CALLED BY:	PC_SpecialFunction via specialFunctionHandlers
PASS:		es:bx	= Pointer to the argument stack
		es:di	= Pointer to operator/function stack
		ss:bp	= Pointer to EvalParameters
		cx	= Special function code.
RETURN:		es:bx	= New pointer to argument stack
		carry set on error
		    al	= Error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFPagesHandler	proc	near
	uses	cx, dx
	.enter
	mov	cx, SF_PAGES
	call	SubclassSpecialFunction		; cx <- page count
	call	ParserEvalPushNumericConstantWord		; Push the value
	.leave
	ret
SFPagesHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SubclassSpecialFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ourselves to handle a special function.

CALLED BY:	SF*Handler
PASS:		ss:bp	= Pointer to CommonParams
		cx,dx	= Arguments to subclass
RETURN:		cx,dx	= Return values from subclass
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SubclassSpecialFunction	proc	near
	class	SpreadsheetClass
	uses	ax, ds, si, bp, di
	.enter
	mov	ax, MSG_SPREADSHEET_HANDLE_SPECIAL_FUNCTION
	lds	si, ss:[bp].CP_cellParams	; ds:si <- spreadsheet
	mov	si, ds:[si].SSI_chunk		; *ds:si <- spreadsheet
	call	ObjCallInstanceNoLock		; cx <- name length
	.leave
	ret
SubclassSpecialFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserCallSubclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a message off to the sub-class if it wants it.

CALLED BY:	PC_FunctionToToken, PC_FunctionToCell, PC_FormatFunction,
		PC_EvalFunction
PASS:		ax	= Message to pass
		ss:bp	= CommonParams
		cx,dx	= Parameters to pass
		di	= Parameter to pass in bp
RETURN:		If callback was made:
			Zero flag clear (nz)
			ax, cx, dx	= Return values from callback
			bp		= Value returned from callback in di
			carry set by callback

		If callback was not made:
			Zero flag set (z)
			carry flag clear
			no registers modified

		bx, si, di, ds, es unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserCallSubclass	proc	near
	class	SpreadsheetClass
	uses	ds, si
	.enter
	;
	; Check to see if this spreadsheet supports application functions.
	;
	lds	si, ss:[bp].CP_cellParams	; ds:si <- instance
	test	ds:[si].SSI_flags, mask SF_APPLICATION_FUNCTIONS
	jz	quitNoCall			; Branch if no call
	
	;
	; It does support them, callback.
	;
	mov	bp, di				; Pass parameter in bp

	mov	si, ds:[si].SSI_chunk		; *ds:si <- instance
	call	ObjCallInstanceNoLock		; Pass it along...

	;
	; We made a call, clear the zero flag (nz)
	;
	lahf					; ah <- flags
	and	ah, not 8			; Clear the zero flag
	sahf					; Restore flags
quit:
	;
	; Flags set to return
	;
	.leave
	ret

quitNoCall:
	;
	; No call was made, set the zero flag, clear the carry.
	;
	clr	ax				; Sets zero, clears carry
	jmp	quit
ParserCallSubclass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetPop1Arg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an argument from the argument stack.

CALLED BY:	CellFunctionHandler
PASS:		es:bx	= Argument stack
		es:di	= Operator stack
RETURN:		es:bx	= New argument stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetPop1Arg	proc	far
	uses	cx
	.enter
	mov	cx, 1
	call	ParserEvalPopNArgs
	.leave
	ret
SpreadsheetPop1Arg	endp



if DBCS_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSheetCmpStringsDBCSToSBCSNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings, one in DBCS form, the other in SBCS,
		for case-innsensitive equality.  Pass in length of strings
		to compare.  A non-ASCII char means immediate non-equality.
		Returns zero/non-zero flags

CALLED BY:	IsFunction (INTERNAL)
PASS:		ds:si	= DBCS Unicode string
		es:di	= ASCII string
		cx	= # of characters (Unicode count)
RETURN:		Zero/Non-zero flag for equal/not equal
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For each char,
			if *(ds:si) is not ASCII, then
				return not equal.
			if case insensitve char compare => not equal
				return not equal.
		Return equal.

COMMENTS/NOTES:
		* Uses LocalCmpCharsNoCase() to compare lower 8 bits.
		* This should be a library routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	10/22/93    	Initial version (copied from ParseCmpStr...)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSheetCmpStringsDBCSToSBCSNoCase	proc	near
	uses	ax, bx, cx, si, di
	.enter

	clr	bh
compareLoop:
	lodsw				; ax <- Unicode char
	mov	bl, {char} es:[di]	; bx <- ASCII char
	tst	ah			; non-ASCII Unicode?
	jnz	done			; sigh, those never match..

	xchg	bx, cx			; cx <- dest char; hide count
	call	LocalCmpCharsNoCase	; ax : cx
	jnz	done

	mov	cx, bx			; restore count.
	inc	di			; next ASCII char
	loop	compareLoop
	tst	cx			; ZF <- Equal.
done:
	.leave
	ret
SSheetCmpStringsDBCSToSBCSNoCase	endp

endif


SpreadsheetNameCode	ends
