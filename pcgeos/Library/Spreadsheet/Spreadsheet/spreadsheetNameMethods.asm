COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetNameMethods.asm

AUTHOR:		John Wedgwood, Mar 22, 1991

METHODS:
	Name			Description
	----			-----------
    (MSG_SPREADSHEET_...)
	ADD_NAME		Add a name to name list
	DELETE_NAME		Delete a name from the name list
	CHANGE_NAME		Change a name in the name list
	GET_NAME_COUNT		Get the number of names in the name list
	GET_NAME_INFO		Get information about a name in the name list
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/22/91		Initial revision


DESCRIPTION:
	Method handlers for the name related methods that the spreadsheet
	object handles.

	$Id: spreadsheetNameMethods.asm,v 1.1 97/04/07 11:14:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetAddName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a name to the spreadsheet name-list

CALLED BY:	via MSG_SPREADSHEET_ADD_NAME
PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
		dx:bp	= Pointer to SpreadsheetNameParameters
				SNP_textLength
				SNP_text
				SNP_defLength
				SNP_definition
RETURN:		ax	= Token number 
		cx	= Entry number in the defined name list
		dx	= # of defined names in the name list
		bp	= # of undefined names in the name list
		If there was an error in the name definition then
		    cx	= -1
		    dl	= ParserScannerEvaluatorError code
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetAddName	method	SpreadsheetClass,
			MSG_SPREADSHEET_ADD_NAME
	mov	si, di			; ds:si <- instance ptr
EC <	push	ax			;>
EC <	mov	ax, ss			;>
EC <	cmp	dx, ax			;>
EC <	ERROR_NE	NAME_PARAMS_MUST_BE_ON_STACK >
EC <	pop	ax			;>

	call	NameValidateString	; Check if the name string is valid.
	jc	quit			; Branch if error

	tst	ss:[bp].SNP_defLength	; Check for no definition text
	LONG jz	errorNoDefinition	; Branch if none
	
	mov	cx, ss:[bp].SNP_textLength
	segmov	es, ss, di		; es:di <- ptr to text of name
	lea	di, ss:[bp].SNP_text

	call	NameDefineEntry		; Define a new name
	jc	errorNameAlreadyDefined	; Branch on error
	;
	; ax = the token number
	; dx = the entry number
	; ds:si = spreadsheet instance ptr
	;

	;
	; Parse the definition and update the dependencies.
	;
	push	ax, dx			; Save the token and entry
	segmov	es, ss, di		; es:di <- ptr to the definition
	lea	di, ss:[bp].SNP_definition
	mov	cx, ss:[bp].SNP_defLength

	mov	dx, ax			; dx <- the column
	mov	ax, NAME_ROW		; ax <- the row
	call	FormulaCellParseText	; Parse the definition
	pop	ax, cx			; Restore token and entry
	jc	errorBadDefinition	; Branch if definition is no good
	
	;
	; Recalculate the cells which depend on the name.
	;
	push	ax, cx			; Save the token and entry
	mov	cx, ax			; cx <- column
	mov	ax, NAME_ROW		; ax <- row
	call	RecalcDependents	; Recalc the cells which depend on it
	pop	ax, cx			; Restore token and entry

	call	NameGetListCounts	; dx <- # of defined names
					; bp <- # of undefined names
quit:
	;
	; If there was an error
	;	cx = -1
	;	dl = The error code
	; Otherwise
	;	cx = The entry number
	;	dx = # of defined names
	;	bp = # of undefined names
	; 
	ret

errorNoDefinition:
	;
	; No definition was supplied. Signal an error and return.
	;
	mov	dl, PSEE_NO_DEFINITION_GIVEN
	mov	cx, -1
	jmp	quit

errorNameAlreadyDefined:
	;
	; The instance pointer is on the stack here.
	;
	mov	dl, PSEE_NAME_ALREADY_DEFINED
	mov	cx, -1
	jmp	quit

errorBadDefinition:
	;
	; The definition didn't parse.
	; ax	= Token of the name to remove
	;
	mov	cx, ax			; cx <- Entry to remove
	call	NameRemoveEntry		; Remove it...

	mov	dl, PSEE_BAD_NAME_DEFINITION
	mov	cx, -1
	jmp	quit
SpreadsheetAddName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetValidateName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a name can be added to the spreadsheet
		name-list

CALLED BY:	via MSG_SPREADSHEET_VALIDATE_NAME
PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
		dx:bp	= Pointer to SpreadsheetNameParameters
				SNP_textLength
				SNP_text
RETURN:		If there was an error in the name definition then
		    cx	= -1
		    dl	= ParserScannerEvaluatorError code
		Else,
		    cx != -1, and the name may be safely added to the
		    	      spreadsheet name-list.
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetValidateName	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_VALIDATE_NAME
	mov	si, di			; ds:si <- instance ptr
EC <	push	ax			;>
EC <	mov	ax, ss			;>
EC <	cmp	dx, ax			;>
EC <	ERROR_NE	NAME_PARAMS_MUST_BE_ON_STACK >
EC <	pop	ax			;>

	call	NameValidateString	; Check for valid name string.
	jc	quit			; Branch if the string wasn't valid.

	mov	cx, ss:[bp].SNP_textLength
	segmov	es, ss, di		; es:di <- ptr to text of name
	lea	di, ss:[bp].SNP_text

	call	NameCheckIfAlreadyUsed	; Is the name already in the list?
					; cx and dl are set appropriately:
quit:
	;
	; If there was an error
	;	cx = -1
	;	dl = The error code
	; Otherwise
	;	cx = The entry number
	;	dx = # of defined names
	ret
SpreadsheetValidateName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetPasteAddName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_PASTE_ADD_NAME)

PASS:		*ds:si	- instance pointer
		ds:di	- pointer to spreadsheet instance
		ss:bp	- NameListEntry

RETURN:		if error
		    cx = -1
		    dx = ParserScannerEvaluatorError code
		else
		     cx = entry number in the defined name list
		     dx = number of defined names in the name list
		     bp = number of undefined names in the name list

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
SpreadsheetPasteAddName	method	dynamic	SpreadsheetClass,
				MSG_SPREADSHEET_PASTE_ADD_NAME

	mov	si, di				; ds:si <- instance pointer
	call	NameCountNamesLeft		; ax <- number of names left
	tst	ax				; any more space?
	je	noSpaceErr

	;
	; Recalculate the cells which depend on the name.
	;
	push	cx			; Save entry #
	mov	cx, ax			; cx <- column
	mov	ax, NAME_ROW		; ax <- row
	call	RecalcDependents	; Recalc the cells which depend on it
	pop	cx			; Restore entry #

	call	NameGetListCounts	; dx <- # of defined names
					; bp <- # of undefined names
done:
	ret

noSpaceErr:
	mov	dl, PSEE_NOT_ENOUGH_NAME_SPACE
	mov	cx, -1
	jmp	short done
SpreadsheetPasteAddName	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDeleteName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a name from the spreadsheet name-list

CALLED BY:	via MSG_SPREADSHEET_DELETE_NAME
PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
		dx:bp	= Pointer to SpreadsheetNameParameters
				SNP_listEntry
RETURN:		cx	= Token of the deleted name
		dx	= # of defined names in the name list
		bp	= # of undefined names in the name list
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetDeleteName	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_DELETE_NAME
	mov	si, di			; ds:si <- instance ptr
EC <	push	ax			;>
EC <	mov	ax, ss			;>
EC <	cmp	dx, ax			;>
EC <	ERROR_NE	NAME_PARAMS_MUST_BE_ON_STACK >
EC <	pop	ax			;>
	
	mov	cx, ss:[bp].SNP_listEntry
	test	ss:[bp].SNP_flags, mask NAF_BY_TOKEN
	jnz	gotToken		; Branch if we have the token

	;
	; SNP_listEntry really contains a list entry, not just a token.
	;
	call	NameGetTokenFromEntry	; cx <- token (column)

gotToken:
	call	DeleteName		; Delete the name
	jnc	quit			; Branch if it had no dependents
	
	mov	ax, NAME_ROW		; ax <- row (cx holds the column)
	call	RecalcDependents	; Update name dependents
quit:
	;
	; Update the count of defined names and dirty/unlock the name-list
	;
	call	NameGetListCounts	; dx <- # of defined names
					; bp <- # of undefined names
	ret
SpreadsheetDeleteName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a name from the name list.

CALLED BY:	SpreadsheetDeleteName, SpreadsheetChangeName
PASS:		ds:si	= Instance ptr
		cx	= Token number of the name to delete
RETURN:		carry set if the name had dependents
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteName	proc	near
	uses	ax
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; We want to remove all the dependencies generated by the definition
	; of this name. The easiest way to do this is to replace the name
	; with an empty definition. This will remove all the old dependencies.
	;
	call	NameReplaceWithEmptyDefinition

	;
	; If there are things which depend on this name then we can't really
	; delete it. We can only mark it as undefined.
	;
	call	CheckHasDependencies	; Carry set if there are dependencies
	jc	markUndefined		; Branch if it has dependents

	;
	; The name has no dependents, remove it entirely.
	;
	call	NameRemoveEntry		; See ya'

	clc				; Signal: no dependents
quit:
	.leave
	ret

markUndefined:
	;
	; The entry has dependents. We mark it as undefined so it doesn't
	; show up as part of the list of existing names.
	; cx = Name token
	;
	call	NameMarkUndefined	; Mark name as undefined
	stc				; Signal: has dependents
	jmp	quit
DeleteName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetChangeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a spreadsheet name definition

CALLED BY:	via MSG_SPREADSHEET_CHANGE_NAME
PASS:		*ds:si	= Spreadsheet instance
		ds:di	= Spreadsheet instance
		dx:bp	= SpreadsheetNameParameters
RETURN:		cx	= Entry number in the defined name list
		dx	= # of defined names in the name list
		bp	= # of undefined names in the name list
		If there was an error in the name definition then
		    cx	= -1
		    dl	= ParserScannerEvaluatorError code
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
	if (flags & NAF_BY_TOKEN) then
	    oldToken = listEntry
	else
	    oldToken = TokenByListEntry( listEntry )
	endif

	newToken, flags = FindEntryByName( newName )
	
	if (newToken != oldToken) && ! (flags & NF_UNDEFINED) then
	    /* Error, can't replace existing name */
	endif
	
	ParseText( expression, NAME_ROW, newToken )
	if (error) then
	    /* Report parser error */
	endif
	
	/*
	 * Expression parsed into destination cell.
	 */
	DeleteEntry( oldToken )
	
	if (oldToken != newToken) then
	    list = CreatePrecedentList( oldToken )
	    RemoveNameCell( oldToken )
	    foreach entry in list do
	        RemoveReferences( entry )
		Modify name references
		AddReferences( entry )
	    done
	endif
	
	AddEntry( newName, newToken )

	RecalcDependents( newToken )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetChangeName	method	SpreadsheetClass, MSG_SPREADSHEET_CHANGE_NAME
	mov	si, di				; ds:si <- instance ptr
EC <	push	ax			;>
EC <	mov	ax, ss			;>
EC <	cmp	dx, ax			;>
EC <	ERROR_NE	NAME_PARAMS_MUST_BE_ON_STACK >
EC <	pop	ax			;>

	;
	; Check for no name or no definition.
	;
	tst	ss:[bp].SNP_textLength		; Check for no name text
	LONG jz	errorNoName			; Branch if none

	tst	ss:[bp].SNP_defLength		; Check for no definition text
	LONG jz	errorNoDefinition		; Branch if none
	
	mov	cx, ss:[bp].SNP_listEntry	; cx <- entry # (or token #)
	test	ss:[bp].SNP_flags, mask NAF_BY_TOKEN
	jnz	gotToken			; Branch if cx is already the 
						; old token number
	
	call	NameGetTokenFromEntry		; cx <- old token number

gotToken:
	mov	dx, cx				; dx <- old token number
	
	;
	; Now start the job of changing the name.
	;
	segmov	es, ss, di			; es:di <- ptr to name
	lea	di, ss:[bp].SNP_text
	mov	cx, ss:[bp].SNP_textLength	; cx <- string length

	call	NameTokenFromText		; Carry set if name found
						; ax <- new token
	jc	gotNewToken			; cl <- flags

	;
	; The name wasn't found. Since it wasn't found we use our current
	; token as the new one (basically copying the name onto itself.
	;
	mov	ax, dx				; ax <- new token
	clr	cl				; No flags

gotNewToken:
	;
	; ds:si	= Instance ptr
	; ss:bp	= SpreadsheetNameParameters
	; dx	= Old token number
	; ax	= New token number
	; cl	= Flags
	;
	cmp	ax, dx				; Check for different tokens
	je	parseText			; Branch if the same
	
	;
	; The new token is for an already existing name.
	;
	test	cl, mask NF_UNDEFINED		; Check for existing name defined
	jz	errorNameExists			; Branch if it is defined

parseText:
	;
	; The new position for the name is a valid one. Parse the text into
	; that new position.
	; ds:si	= Instance ptr
	; ss:bp	= SpreadsheetNameParameters
	; dx	= Old token
	; ax	= New token
	;
	push	ax, dx				; Save new/old tokens
	segmov	es, ss, di			; es:di <- ptr to the definition
	lea	di, ss:[bp].SNP_definition
	mov	cx, ss:[bp].SNP_defLength	; cx <- definition length

	mov	dx, ax				; dx <- the column
	mov	ax, NAME_ROW			; ax <- the row
	call	FormulaCellParseText		; Parse the definition
	pop	ax, dx				; Restore new/old tokens
	
	jc	errorBadDefinition		; Branch if def didn't parse
	
	;
	; The definition parsed just fine.
	; Now we remove the old name from the name-list.
	; ds:si	= Instance ptr
	; ss:bp	= SpreadsheetNameParameters
	; ax	= New token
	; dx	= Old token
	;
	cmp	ax, dx				; Check for changed tokens
	je	updateName			; Branch if tokens are the same

	;
	; The new and old tokens are not the same. As a result we need to:
	;	- Remove the old name structure.
	;	- Update the references to the old name token to refer
	;	  to the new name token.
	;	- Add a new name entry.
	;
	mov	cx, dx				; cx <- Token of name to delete
	call	DeleteName			; Delete the name
	
	call	ReplaceNameReferences		; Update the spreadsheet

	;
	; Add the new entry and recalculate.
	; ds:si	= Instance ptr
	; ss:bp	= SpreadsheetNameParameters
	; ax	= New token that is not the same as the old token
	;
	segmov	es, ss, di			; es:di <- name text
	lea	di, ss:[bp].SNP_text
	mov	cx, ss:[bp].SNP_textLength	; cx <- name length

	call	NameDefineEntryGivenToken	; dx <- List entry number

recalc:
	;
	; Recalculate the dependent cells.
	; ds:si	= Instance ptr
	; ax	= Token
	; dx	= List entry number
	;
	mov	cx, ax				; cx <- Column (token)
	mov	ax, NAME_ROW			; ax <- row (cx holds column)
	call	RecalcDependents		; Recalculate
	
	mov	cx, dx				; cx <- list entry number
	call	NameGetListCounts		; dx <- # of defined names
						; bp <- # of undefined names
quit:
	ret

errorNoName:
	;
	; No name was supplied. Signal an error and return.
	;
	mov	dl, PSEE_NO_NAME_GIVEN
	mov	cx, -1
	jmp	quit

errorNoDefinition:
	;
	; No definition was supplied. Signal an error and return.
	;
	mov	dl, PSEE_NO_DEFINITION_GIVEN
	mov	cx, -1
	jmp	quit

errorNameExists:
	;
	; The name already exists as a defined name, you can't do what you're
	; trying to do...
	;
	mov	dl, PSEE_NAME_ALREADY_DEFINED
	mov	cx, -1
	jmp	quit

errorBadDefinition:
	;
	; The definition didn't parse.
	;
	mov	dl, PSEE_BAD_NAME_DEFINITION
	mov	cx, -1
	jmp	quit

updateName:
	;
	; We are changing the name and definition of the current name.
	; This means that the name exists and is defined already.
	; We need to remove the name structure from the name-list and add
	; a new one.
	;
	; ds:si	= Spreadsheet instance
	; ax	= Token
	;
	segmov	es, ss, di			; es:di <- new name
	lea	di, ss:[bp].SNP_text
	mov	cx, ss:[bp].SNP_textLength	; cx <- length

	call	NameRenameEntry			; Rename the entry
	jmp	recalc				; Go recalculate
SpreadsheetChangeName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetNameCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of names in the name list

CALLED BY:	via MSG_SPREADSHEET_GET_NAME_COUNT
PASS:		*ds:si	= Instance ptr
		ds:di	= Pointer to spreadsheet instance
RETURN:		dx	= # of defined names in the name-list
		bp	= # of undefined names in the name-list
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetNameCount	method	dynamic SpreadsheetClass,
			MSG_SPREADSHEET_GET_NAME_COUNT
	mov	si, di			; ds:si <- instance ptr
	call	NameGetListCounts	; dx <- # of defined names
					; bp <- # of undefined names
	ret
SpreadsheetGetNameCount	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetNameInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a name from the name list

CALLED BY:	via MSG_SPREADSHEET_GET_NAME_INFO
		AddNameToNameList
PASS:		ds:di	= Pointer to spreadsheet instance
		dx:bp	= Pointer to SpreadsheetNameParameters
				SNP_flags
				SNP_listEntry
RETURN:		SpreadsheetNameParameters fields filled in
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		FP_nChars is a glyph count (not size).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/22/91		Initial version
	witt	11/17/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetNameInfo	method	SpreadsheetClass,
			MSG_SPREADSHEET_GET_NAME_INFO
	mov	si, di			; ds:si <- instance ptr
EC <	push	ax			;>
EC <	mov	ax, ss			;>
EC <	cmp	dx, ax			;>
EC <	ERROR_NE	NAME_PARAMS_MUST_BE_ON_STACK >
EC <	pop	ax			;>
	
	mov	cx, ss:[bp].SNP_listEntry
	test	ss:[bp].SNP_flags, mask NAF_BY_TOKEN
	jnz	gotToken		; Branch if we have the token

	;
	; SNP_listEntry really contains a list entry, not just a token.
	;
	call	NameGetTokenFromEntry	; cx <- the token number

gotToken:
	;
	; Test the flags to see if the user wants the text of the name
	;
	test	ss:[bp].SNP_flags, mask NAF_NAME
	jz	afterName		; Branch if name is not desired

	segmov	es, ss			; es:di <- ptr to destination buffer
	lea	di, ss:[bp].SNP_text
	mov	dx, length SNP_text	; dx <- max # of chars to write

	call	NameTextFromToken	; Write the text of the name
					; dx <- # of characters written
	mov	ss:[bp].SNP_textLength, dx

SBCS<	clr	al							>
DBCS<	clr	ax							>
	LocalPutChar	esdi, ax	; Null terminate the text

afterName:
	;
	; Copy the token always since we've got it...
	;
	mov	ss:[bp].SNP_token, cx	; Copy the token

	;
	; Check to see if the caller wants the definition.
	;
	test	ss:[bp].SNP_flags, mask NAF_DEFINITION
	jz	afterDefinition		; Skip if they don't
	
	push	cx
	call	NameFlagsFromToken	; cl <- token
	mov	ss:[bp].SNP_nameFlags, cl
	pop	cx

	;
	; Copy the definition, cx holds the token (column of the name).
	;
	mov	ax, NAME_ROW
	SpreadsheetCellLock		; *es:di <- ptr to the name definition

	push	es, bp, bx, ds, si	; Save segment address of name cell
					;    the frame ptr, file handle, and
					;    instance ptr.

	;
	; The caller may want the tokenized definition and not the textual
	; representation of that definition.
	;
	test	ss:[bp].SNP_flags, mask NAF_TOKEN_DEFINITION
	jnz	copyTokenDefinition	; Branch if wants tokenized data

	;
	; Format the definition of the name into the buffer on the stack.
	;
					; bx <- offset of destination buffer
	lea	bx, ss:[bp].SNP_definition

	sub	sp, size FormatParameters
	mov	bp, sp			; ss:bp <- ptr to formatting parameters
	
	;
	; Initialize the stack frame.
	;
	call	SpreadsheetInitCommonParams
	mov	ss:[bp].FP_nChars, length SNP_definition

	segmov	ds, es, si		; ds:si <- ptr to name definition
	mov	si, ds:[di]
	add	si, CF_formula		; ds:si <- ptr to the formula
	
	segmov	es, ss			; es:di <- ptr to destination
	mov	di, bx
	
	
	call	ParserFormatExpression	; cx <- length of the definition

	add	sp, size FormatParameters

popAndQuit:
	;
	; cx = Length of the definition that was copied.
	;
	pop	es, bp, bx, ds, si	; Restore segment address of name cell
					;    the frame ptr, file handle, and
					;    instance ptr
	mov	ss:[bp].SNP_defLength, cx

	SpreadsheetCellUnlock		; Release the name definition
afterDefinition:
	ret

copyTokenDefinition:
	;
	; Copy the tokenized definition.
	; *es:di = Pointer to the cell data
	; ss:bp	 = SpreadsheetNameParameters
	;
	mov	di, es:[di]		; es:di <- ptr to cell data
	
	mov	cx, es:[di].CF_formulaSize
	add	di, size CellFormula
	
	;
	; es:di = Pointer to the formula
	; cx	= Size of the formula
	; ss:bp	= Frame ptr
	;
	
	segmov	ds, es, si		; ds:si <- source
	mov	si, di
	
	segmov	es, ss, di		; es:di <- dest
	lea	di, ss:[bp].SNP_definition
	
	push	cx			; Save the definition size
	rep	movsb			; Copy the definition
	pop	cx			; Restore the size
	jmp	popAndQuit

SpreadsheetGetNameInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInitCommonParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a CommonParameters structure

CALLED BY:	SpreadsheetGetNameInfo
PASS:		ss:bp	= Pointer to CommonParameters
		ds:si	= Pointer to the SpreadsheetInstance
RETURN:		CommonParameters initialized
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/25/91		Initial version
	witt	11/19/93	stack overflow checking (paranoid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetInitCommonParamsFar	proc	far
	call	SpreadsheetInitCommonParams
	ret
SpreadsheetInitCommonParamsFar	endp

SpreadsheetInitCommonParams	proc	near
	class	SpreadsheetClass
	uses	ax
	.enter
EC <	call	ECCheckInstancePtr		;>
DBCS< EC < call	ECCHECKSTACK			; paranoid! 		>  >

	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bp].CP_row, ax

	mov	ax, ds:[si].SSI_active.CR_column
	mov	ss:[bp].CP_column, ax

	mov	ax, ds:[si].SSI_maxRow
	mov	ss:[bp].CP_maxRow, ax

	mov	ax, ds:[si].SSI_maxCol
	mov	ss:[bp].CP_maxColumn, ax

	mov	ss:[bp].CP_callback.segment, SEGMENT_CS
	mov	ss:[bp].CP_callback.offset,  offset cs:ParserCallback
	
	mov	ss:[bp].CP_cellParams.segment, ds
	mov	ss:[bp].CP_cellParams.offset,  si
CheckHack <(offset SSI_cellParams) eq 0>

	.leave
	ret
SpreadsheetInitCommonParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameReplaceWithEmptyDefinition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a name with an empty definition. This will nuke
		any dependencies it might have.

CALLED BY:	SpreadsheetDeleteName
PASS:		ds:si	= Pointer to spreadsheet instance
		cx	= Token number of the name
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	LocalDefNLString   emptyNameString, <"0",0>

NameReplaceWithEmptyDefinition	proc	near
	uses	cx, dx, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ax, NAME_ROW			; ax <- "name" row
	mov	dx, cx				; dx <- "token" column

	segmov	es, cs, di			; es:di <- ptr to new text
	mov	di, offset cs:emptyNameString
	mov	cx, length emptyNameString	; cx <- length of text
FXIP<	call	SysCopyToStackESDI		; es:di = str on stack	>
	call	FormulaCellParseText		; Parse me jesus
FXIP<	call	SysRemoveFromStack		; release stack space	>
	;
	; This is a really horrible error that should never happen.
	; The "emptyNameString" is a hard-coded string that we *know* parses
	; correctly. If it fails to parse it probably means that someone
	; has been scribbling in this code segment or something...
	;
EC <	ERROR_C	UNABLE_TO_PARSE_EMPTY_DEFINITION	>
	.leave
	ret
NameReplaceWithEmptyDefinition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHasDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a name has dependents

CALLED BY:	SpreadsheetDeleteName
PASS:		ds:si	= Spreadsheet instance
		cx	= Token of the name
RETURN:		Carry set if there are dependents
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHasDependencies	proc	near
	uses	ax, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ax, NAME_ROW		; ax <- row
	SpreadsheetCellLock		; *es:di <- ptr to the cell data
	mov	di, es:[di]		; es:di <- ptr to cell data

	tst	es:[di].CC_dependencies.segment
	jz	quit			; Branch if no dependencies (carry clear)
	stc				; Signal: Has dependencies
quit:
	pushf				; Save has dependencies flag (carry)
	SpreadsheetCellUnlock		; Release the cell
	popf				; Restore has dependencies flag (carry)
	.leave
	ret
CheckHasDependencies	endp

SpreadsheetNameCode	ends
