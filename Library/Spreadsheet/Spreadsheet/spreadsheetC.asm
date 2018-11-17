COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Spreadsheet
FILE:		spreadsheetC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	10/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: spreadsheetC.asm,v 1.1 97/04/07 11:14:08 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

;
; For now, there isn't enough C initialization code to justify
; a separate resource
;

InitCode	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetInitFile

C DECLARATION:	extern VMBlockHandle
		_far _pascal SpreadsheetInitFile(SpreadsheetInitFileData *ifd);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Anna	10/91		Initial version

------------------------------------------------------------------------------@
SPREADSHEETINITFILE	proc	far	ifd:fptr
	.enter

EC <	push	ax					;>
EC <	mov	ax, ss					;>
EC <	cmp	ax, ss:ifd.segment			;>
EC <	ERROR_NE NAME_PARAMS_MUST_BE_ON_STACK		;>
EC <	pop	ax					;>
	mov	bp, ss:ifd.offset
	call	SpreadsheetInitFile

	.leave
	ret

SPREADSHEETINITFILE	endp

InitCode	ends


SpreadsheetNameCode	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetParseNameToToken
		This function is a C stub to call PC_NameToToken, which handles
		when the Parse library's eval code wants to convert a string to
		a name token, and possibly create a new cell (when creating
		dependencies, for example).

C DECLARATION:	extern void
			_far _pascal SpreadsheetParseNameToToken(
				C_CallbackStruct *cb_s);
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/16/92		Initial version

------------------------------------------------------------------------------@
SPREADSHEETPARSENAMETOTOKEN	proc	far	cb_s:fptr
	uses	es, ds, di, si, bp
	.enter

	lds	si, cb_s	; ds:si <- C_CallbackStruct pointer
	; Make sure the eval parameters are in the same stack segment...
EC <	mov	ax, ss							>
EC <	cmp	ax, ds:[si].C_params.high				>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>
	;
	; Load up the regs as expected in PC_NameToToken
	;
	; ds:si <- Pointer to the name text
	; cx    <- Length of the name text
	; ss:bp <- Pointer to EvalParameters
	;
	les	di, ds:[si].C_u.CT_ntt.NTT_text
	mov	cx, ds:[si].C_u.CT_ntt.NTT_length
	push	bp
	mov	bp, ds:[si].C_params.low
	segxchg	ds, es			; ds:si <- Pointer to the name text
	xchg	si, di			; es:di <- Pointer to C_CallbackStruct

	call	PC_NameToToken_far
	
	; Load up the return values.
	pop	bp
	segmov	ds, es, si		; ds:si <- Pointer to C_CallbackStruct
	mov	si, di
	mov	ds:[si].C_u.CT_ntt.NTT_nameID, cx
	mov	ds:[si].C_u.CT_ntt.NTT_error, al
	mov	ds:[si].C_u.CT_ntt.NTT_errorOccurred, 0

	jnc	done			; jump if no error occurred.
	mov	ds:[si].C_u.CT_ntt.NTT_errorOccurred, 0xff
done:	
	.leave
	ret

SPREADSHEETPARSENAMETOTOKEN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetParseCreateCell
		This function is a C stub to call PC_CreateCell, which handles
		when the Parse library's eval code wants to create a new cell
		(when creating dependencies, for example).

C DECLARATION:	extern void
			_far _pascal SpreadsheetParseCreateCell(
				C_CallbackStruct *cb_s);
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/16/92		Initial version

------------------------------------------------------------------------------@
SPREADSHEETPARSECREATECELL	proc	far	cb_s:fptr
	uses	es, ds, di, si, bp
	.enter

	lds	si, cb_s	; ds:si <- C_CallbackStruct pointer
	; Make sure the eval parameters are in the same stack segment...
EC <	mov	ax, ss							>
EC <	cmp	ax, ds:[si].C_params.high				>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>
	;
	; Load up the regs as expected in PC_CreateCell
	;
	; dx    <- Row of cell to create
	; cx    <- Column of cell to create
	; ss:bp <- Pointer to DependencyParameters
	;
	mov	dx, ds:[si].C_u.CT_cc.CC_row
	mov	cx, ds:[si].C_u.CT_cc.CC_column
	push	bp
	mov	bp, ds:[si].C_params.low

	call	PC_CreateCell_far
	
	; Load up the return values.
	pop	bp
	mov	ds:[si].C_u.CT_cc.CC_error, al
	mov	ds:[si].C_u.CT_cc.CC_errorOccurred, 0

	jnc	done			; jump if no error occurred.
	mov	ds:[si].C_u.CT_cc.CC_errorOccurred, 0xff
done:	
	.leave
	ret

SPREADSHEETPARSECREATECELL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetParseEmptyCell --
		This function is a C stub to call PC_EmptyCell, which handles
		when the Parse library's eval code wants to remove a cell that
		no longer has any dependents.  Obviously, this routine
		is only called when removing dependencies.

C DECLARATION:	extern void
			_far _pascal SpreadsheetParseEmptyCell(
				C_CallbackStruct *cb_s);
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/16/92		Initial version

------------------------------------------------------------------------------@
SPREADSHEETPARSEEMPTYCELL	proc	far	cb_s:fptr
	uses	es, ds, di, si, bp
	.enter

	lds	si, cb_s	; ds:si <- C_CallbackStruct pointer
	; Make sure the dependency parameters are in the same stack segment...
EC <	mov	ax, ss							>
EC <	cmp	ax, ds:[si].C_params.high				>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>
	;
	; Load up the regs as expected in PC_EmptyCell
	;
	; dx    <- Row of cell to empty
	; cx    <- Column of cell to empty
	; ss:bp <- Pointer to DependencyParameters
	;
	mov	dx, ds:[si].C_u.CT_ec.EC_row
	mov	cx, ds:[si].C_u.CT_ec.EC_column
	push	bp
	mov	bp, ds:[si].C_params.low

	call	PC_EmptyCell_far
	
	; Load up the return values.
	pop	bp
	mov	ds:[si].C_u.CT_ec.EC_error, al
	mov	ds:[si].C_u.CT_ec.EC_errorOccurred, 0

	jnc	done			; jump if no error occurred.
	mov	ds:[si].C_u.CT_ec.EC_errorOccurred, 0xff
done:	
	.leave
	ret

SPREADSHEETPARSEEMPTYCELL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetParseDerefCell
		This function is a C stub to call PC_DerefCell, which handles
		when the Parse library's eval code wants to dereference a
		cell.

C DECLARATION:	extern void
			_far _pascal SpreadsheetParseDerefCell(
				C_CallbackStruct *cb_s);
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	6/15/92		Initial version

------------------------------------------------------------------------------@
SPREADSHEETPARSEDEREFCELL	proc	far	cb_s:fptr
	uses	es, ds, di, si, bp
	.enter

	lds	si, cb_s	; ds:si <- C_CallbackStruct pointer
	; Make sure the eval parameters are in the same stack segment...
EC <	mov	ax, ss							>
EC <	cmp	ax, ds:[si].C_params.high				>
EC <	ERROR_NE POINTER_SEGMENT_NOT_SAME_AS_STACK_FRAME		>
	;
	; Load up the regs as expected in PC_DerefCell.
	;
	; es:di <- Pointer to operator/function stack
	; es:bx <- Pointer to evaluator argument stack
	; dx    <- row of the cell
	; ch    <- DerefFlags
	; cl	<- cell column
	; ss:bp <- Pointer to EvalParameters
	;
	les	di, ds:[si].C_u.CT_dc.DC_opFnStack
	mov	bx, ds:[si].C_u.CT_dc.DC_argStack.low
	mov	dx, ds:[si].C_u.CT_dc.DC_row
	mov	cl, ds:[si].C_u.CT_dc.DC_column
	mov	ch, ds:[si].C_u.CT_dc.DC_derefFlags
	push	bp
	mov	bp, ds:[si].C_params.low

	call	PC_DerefCell_far
	
	; Load up the return values.
	pop	bp
	mov	ds:[si].C_u.CT_dc.DC_newArgStack.high, es	
	mov	ds:[si].C_u.CT_dc.DC_newArgStack.low, bx	
	mov	ds:[si].C_u.CT_dc.DC_error, al
	mov	ds:[si].C_u.CT_dc.DC_errorOccurred, 0
	jnc	done
	mov	ds:[si].C_u.CT_dc.DC_errorOccurred, 0xff
done:	
	.leave
	ret

SPREADSHEETPARSEDEREFCELL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPREADSHEETNAMETEXTFROMTOKEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a C stub for the Spreadsheet library's
		NameTextFromToken routine.

		The routine converts a name token to text, and places
		the text in a passed pointer.  The number of characters
		written is returned.

		Note that the pointer past the inserted text is not returned,
		as is the case with the assembly version.  You get the number
		of characters written, so it's easily ascertained.
		
CALLED BY:	GLOBAL, though it should only be used by sub-classes
       		of SpreadsheetClass.

ARGUMENTS: 	ssheet - a pointer to a SpreadsheetInstance
		nameToken - the name token to textify
		destinationPtr - where to put the text
		maxCharsToWrite - Max number of chars allowed
			
C DECLARATION:  extern word _far _pascal
		    SpreadsheetNameTextFromToken(SpreadsheetInstance *ssheet,
	  					 word nameToken,
						 char *destinationPtr,
						 word maxCharsToWrite);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPREADSHEETNAMETEXTFROMTOKEN	proc	far	ssheet:fptr,
						nameToken:word,
						destinationPtr:fptr,
						maxCharsToWrite:word
	uses	es, ds, si, di, bp
	.enter

	lds	si, ssheet
	les	di, destinationPtr
	mov	cx, nameToken
	mov	dx, maxCharsToWrite
	
	call	NameTextFromTokenFar
	
	mov	ax, dx			; return number of characters written
	
	.leave
	ret
SPREADSHEETNAMETEXTFROMTOKEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPREADSHEETNAMETOKENFROMTEXT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a C stub for the Spreadsheet library's
		NameTokenFromText routine.

		The routine gets the token for a name, given its text.
		If the name was found, non-zero is returned and
		the token and its nameFlags are loaded into passed
		pointers.  If the name wasn't found, zero is returned.

CALLED BY:	GLOBAL, though it should only be used by sub-classes
       		of SpreadsheetClass.

ARGUMENTS: 	ssheet - a pointer to a SpreadsheetInstance
		nameText - pointer to the text
		nameLen - the number of chars in the name
		tokenDest - a pointer to where the token should be placed
		flagsDest - a pointer to where the NameFlags should be placed
		
C DECLARATION:  extern Boolean _far _pascal
		    SpreadsheetNameTokenFromText(SpreadsheetInstance *ssheet,
	  					 char *nameText,
						 word nameLen,
						 word *tokenDest,
						 NameFlags *flagsDest);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPREADSHEETNAMETOKENFROMTEXT	proc	far	ssheet:fptr,
						nameText:fptr,
						nameLen:word,
						tokenDest:fptr,
						flagsDest:fptr
	uses	es, ds, si, di, bp
	.enter

	lds	si, ssheet
	les	di, nameText
	mov	cx, nameLen
	
	call	NameTokenFromTextFar
	
	mov	dx, ax			; dx <- token
	mov	ax, 0			; assume the name was NOT found.
	jc	done			; jump if no name

	mov	ax, -1			; signal: the name was found!
	lds	si, tokenDest		; ds:si <- where to put the token
	mov	ds:[si], dx
	lds	si, flagsDest		; ds:si <- where to put the flags
	mov	ds:[si], cl
	
done:
	.leave
	ret
SPREADSHEETNAMETOKENFROMTEXT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPREADSHEETNAMELOCKDEFINITION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a C stub for the Spreadsheet library's
		NameLockDefinition routine.

		If the definition was successfully locked, zero is returned
		and the definition's address is placed in defaddr.

		If there was an error of some sort, the error number is
		returned.

CALLED BY:	GLOBAL

C DECLARATION:  extern word _far _pascal
		    SpreadsheetNameLockDefinition(SpreadsheetInstance *ssheet,
	  					  word nameToken,
						  void **defaddr);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPREADSHEETNAMELOCKDEFINITION	proc	far	ssheet:fptr,
						nameToken:word,
						defaddr:fptr
	uses	es, ds, si, di, bp
	.enter

	lds	si, ssheet
	mov	cx, nameToken
	
	call	NameLockDefinitionFar
	mov	ah, 0
	jc	done		; jump if an error occurred
	
	; Success!  Load up the defaddr with the locked address.
	les	di, defaddr
	mov	es:[di].high, ds
	mov	es:[di].low, si
	clr	al

done:
	.leave
	ret
SPREADSHEETNAMELOCKDEFINITION	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SpreadsheetCellAddRemoveDeps
		This function is a C stub to call CellAddRemoveDeps, which
		adds or removes dependencies for a cell.

		Arguments:
		spreadsheetInstance - pointer to the current spreadsheet
		cellParams - a far pointer to SSI_cellParams
		callback - pointer to a parser callback function.  If this
			   is NULL, then no redraw code is called.
		dependencyVars - pointer to a dependency structure that
				 MUST BE ON THE STACK FRAME.
		addOrRemoveDeps - 0 to add dependencies, non-zero to
				  remove dependencies.
		row - Row of cell.
		column - Column of cell.
C DECLARATION:	extern void
			_far _pascal SpreadsheetCellAddRemoveDeps(
				SpreadsheetInstance *spreadsheetInstance,
				dword cellParams,
				void (*callback)(C_CallbackStruct *),
				word addOrRemoveDeps,
				EvalFlags eval_flags,
				word row,
				word column,
				word maxRow,
				word maxColumn)
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/10/92		Initial version

------------------------------------------------------------------------------@
SPREADSHEETCELLADDREMOVEDEPS	proc	far	spreadsheetInstance:fptr,
						cellParams:dword,
						callback:fptr,
						addOrRemoveDeps:word,
						eval_flags:word,
						row:word,
						column:word,
						maxRow:word,
						maxColumn:word
	uses	es, ds, di, si, bp
	depvars	local	PCT_vars
	.enter
	;
	; Load up the depvars struct with the passed args.
	;
	; The current row...
	mov	ax, row
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_row, ax
	mov	ss:depvars.PCTV_row, ax

	; The current column...
	mov	ax, column
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_column, ax
	mov	ss:depvars.PCTV_column, ax

	; The max row...
	mov	ax, maxRow
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_maxRow, ax

	; The max column...
	mov	ax, maxColumn
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_maxColumn, ax

	; The evaluation flags...
	mov	ax, eval_flags
	mov	ss:depvars.PCTV_params.VP_eval.EP_flags, al

	; The cell params...
	movdw	ss:depvars.PCTV_params.VP_eval.EP_common.CP_cellParams, cellParams, ax
	
	; The C callback (to be called from SpreadsheetDependCallback)...
	mov	ax, callback.high
	mov	ss:depvars.PCTV_CCallBack.high, ax
	mov	ax, callback.low
	mov	ss:depvars.PCTV_CCallBack.low, ax
	mov	ss:depvars.PCTV_CCallBack_ds, ds

	; Here we set the callback that the parse library calls...
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_callback.high, cs
	mov	ax, offset SpreadsheetDependCallback
	mov	ss:depvars.PCTV_params.VP_eval.EP_common.CP_callback.low, ax

	; Now make the call to CellAddRemoveDeps.
	;
	; dx    <- add or remove deps flag
	; ax	<- cell row
	; cx	<- cell column
	; ss:bp <- Pointer to DependencyParameters
	;
	lds	si, spreadsheetInstance
	mov	dx, addOrRemoveDeps
	mov	ax, row
	mov	cx, column
	push	bp
	lea	bp, depvars

	call	CellAddRemoveDeps
	pop	bp

	.leave
	ret
SPREADSHEETCELLADDREMOVEDEPS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRecalcDependents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function is a C stub to call
		RecalcDependentsWithRedrawCallback, which updates
		all of the cells that depend on a specific cell and
		calls a callback function to redraw those cells.
		
		Arguments:
		spreadsheetInstance - pointer to the current spreadsheet
		callback - pointer to a function that will redraw a specific
	 		   cell.
		row - Row of cell.
		column - Column of cell.

C DECLARATION:	extern void
			_far _pascal SpreadsheetCellAddRemoveDeps(
				SpreadsheetInstance *spreadsheetInstance,
				void (*callback)(C_CallbackStruct *),
				word row,
				word column)
CALLED BY:	Subclasses of SpreadsheetClass.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPREADSHEETRECALCDEPENDENTS	proc	far	spreadsheetInstance:fptr,
						callback:fptr,
						row:word,
						column:word
	uses	es, ds, di, si, bp
	pctStruct local	PCT_vars
	.enter

	; Set the structure to call SpreadsheetRedrawStub which will in
	; turn call the passed C callback function.
	mov	ss:pctStruct.PCTV_redrawCallback.segment, cs
	mov	ss:pctStruct.PCTV_redrawCallback.offset, offset SpreadsheetRedrawStub

	; The C callback to be called from SpreadsheetRedrawStub.
	mov	ax, callback.segment
	mov	ss:pctStruct.PCTV_CCallBack.segment, ax
	mov	ax, callback.offset
	mov	ss:pctStruct.PCTV_CCallBack.offset, ax
	mov	ss:pctStruct.PCTV_CCallBack_ds, ds
	
	mov	ax, row
	mov	cx, column
	lds	si, spreadsheetInstance
	push	bp
	lea	bp, pctStruct

	call	SpreadsheetInitCommonParams
	call	RecalcDependentsWithRedrawCallback
	pop	bp
	
	.leave
	ret
SPREADSHEETRECALCDEPENDENTS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRedrawStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine calls a C callback for when a C app needs
		to redraw a recalculated field.


CALLED BY:	Spreadsheet library, via RecalcDependentsWithRedrawCallback

PASS:		ds:si - instance data (SpreadsheetClass)
		ss:bp - PCT_vars structure on stack
		(dx,cx) - row, column of cell to draw
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRedrawStub	proc	far
	class	SpreadsheetClass
	uses	es, ds, si
	.enter

	; If there's no C callback to call, just return.
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	tst	bx
	jz	done			; Jump if no callback.

	; Call the C callback to redraw a cell with the following args:
	; (optr oself, word row, word column)

	; Push the optr to the spreadsheet/database.
	push	{word} ds:LMBH_handle
	push	{word} ds:[si].SSI_chunk
	push	dx			; Push row
	push	cx			; Push column

	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
done:
	.leave
	ret
SpreadsheetRedrawStub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDependCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine calls a C callback for when a C app needs
		to build cell dependencies.

CALLED BY:	Parse library, via SpreadsheetCellAddRemoveDeps().

PASS:		al	= CallbackType
		ss:bp   = Pointer to a PCT_vars structure.
		other arguments depending on type.
RETURN:		depends on the argument type.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDependCallback	proc	far
	.enter

        push    si                      ; Save whatever is passed in si
        clr     ah
        shl     ax, 1                   ; ax <- index into table of words
        mov     si, ax                  ; si <- index into a table of words
        mov     ax, cs:C_callbackHandlers[si]
        pop     si                      ; Restore whatever was passed in si
EC <	cmp	ax, -1							>
EC <	ERROR_E BAD_CALLBACK_TYPE					>
        call    ax                      ; Call the handler for the callback

	.leave
	ret
SpreadsheetDependCallback	endp

;
; Since SpreadsheetDependCallback() supports only CT_LOCK_NAME,
; CT_UNLOCK, CT_CREATE_CELL, CT_EMPTY_CELL, CT_NAME_TO_CELL, and
; CT_FUNCTION_TO_CELL, they are the only ones in this list.
;
C_callbackHandlers        \
        word    -1,				; CT_FUNCTION_TO_TOKEN
                -1,				; CT_NAME_TO_TOKEN
                -1,				; CT_CHECK_NAME_EXISTS
                -1,				; CT_CHECK_NAME_SPACE
                -1,				; CT_EVAL_FUNCTION
                offset cs:SCB_LockName,		; CT_LOCK_NAME
                offset cs:SCB_Unlock,		; CT_UNLOCK
                -1,				; CT_FORMAT_FUNCTION
                -1,				; CT_FORMAT_NAME
                offset cs:SCB_CreateCell,       ; CT_CREATE_CELL
                offset cs:SCB_EmptyCell,        ; CT_EMPTY_CELL
                offset cs:SCB_NameToCell,       ; CT_NAME_TO_CELL
                offset cs:SCB_FunctionToCell,   ; CT_FUNCTION_TO_CELL
                -1,				; CT_DEREF_CELL
                -1 				; CT_SPECIAL_FUNCTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SCB_LockName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for ParserEvalExpression

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                cx      = Name token
RETURN:         carry set on error
                al      = error code
                if no error:
                  ds:si = Pointer to the definition of the name
DESTROYED:      ax
		ds, si (if an error occurred)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jeremy  7/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_LockName    proc    near
        .enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_LOCK_NAME
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_ln.LN_nameToken, cx
	
	push	bx, cx, dx, es, di
	push	si, bp
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Get an error value, if it's there.
	pop	si, bp
	mov	al, ss:[si].C_u.CT_ln.LN_error
	
	; Prepare to set the carry flag if an error occurred.
	mov	ah, ss:[si].C_u.CT_ln.LN_errorOccurred
	
	; Load ds:si with the pointer to the definition of the name.
	mov	ds, ss:[si].C_u.CT_ln.LN_defPtr.segment
	mov	si, ss:[si].C_u.CT_ln.LN_defPtr.offset

	; Clean up the stack.
	pop	bx, cx, dx, es, di
	add	sp, size C_CallbackStruct
	
	; Set the carry flag if an error occurred.
	sal	ah, 1

        .leave
        ret
SCB_LockName    endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SCB_Unlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for ParserEvalExpression

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                ds	= Segment address of block to unlock
RETURN:         nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jeremy  7/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_Unlock    proc    near
        .enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	push	si
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_UNLOCK
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_ul.UL_dataPtr.high, ds
	mov	ss:[si].C_u.CT_ul.UL_dataPtr.low, 0
	
	push	ax, bx, cx, dx, es, ds, di
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Clean up the stack.
	pop	ax, bx, cx, dx, es, ds, di
	add	sp, size C_CallbackStruct
	pop	si

        .leave
        ret
SCB_Unlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCB_CreateCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for SpreadsheetDependCallback.

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                dx      = Row of cell to create
                cx      = Column of cell to create
RETURN:         carry set on error
                al      = Error code
DESTROYED:      nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_CreateCell	proc	near
	.enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	push	si		; save whatever's in si.
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_CREATE_CELL
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_cc.CC_row, dx
	mov	ss:[si].C_u.CT_cc.CC_column, cx
	
	push	bx, cx, di, es, ds
	push	si
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Get an error value, if it's there.
	pop	si
	mov	al, ss:[si].C_u.CT_cc.CC_error
	
	; Prepare to set the carry flag if an error occurred.
	mov	ah, ss:[si].C_u.CT_cc.CC_errorOccurred
	
	; Clean up the stack.
	pop	bx, cx, di, es, ds
	add	sp, size C_CallbackStruct
	pop	si
	
	; Set the carry flag if an error occurred.
	sal	ah, 1
	
	.leave
	ret
SCB_CreateCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCB_EmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for SpreadsheetDependCallback.

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                dx      = Row of cell to clear
                cx      = Column of cell to clear
RETURN:         carry set on error
                al      = Error code
DESTROYED:      nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_EmptyCell	proc	near
	.enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	push	si		; save whatever's in si.
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_EMPTY_CELL
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_ec.EC_row, dx
	mov	ss:[si].C_u.CT_ec.EC_column, cx
	
	push	bx, cx, es, ds
	push	si
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Get an error value, if it's there.
	pop	si
	mov	al, ss:[si].C_u.CT_ec.EC_error
	
	; Prepare to set the carry flag if an error occurred.
	mov	ah, ss:[si].C_u.CT_ec.EC_errorOccurred
	
	; Clean up the stack.
	pop	bx, cx, es, ds
	add	sp, size C_CallbackStruct
	pop	si
	
	; Set the carry flag if an error occurred.
	sal	ah, 1
	
	.leave
	ret
SCB_EmptyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCB_NameToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for SpreadsheetDependCallback.

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                cx      = Name token
RETURN:         dx	= Row of cell
                cx	= Column of cell
DESTROYED:      nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_NameToCell	proc	near
	.enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	push	si		; save whatever's in si.
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_NAME_TO_CELL
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_ntc.NTC_nameToken, cx
	
	push	ax, bx, es, ds, di, si
	push	si
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Get an error value, if it's there.
	pop	si

	mov	dx, ss:[si].C_u.CT_ntc.NTC_row
	mov	cx, ss:[si].C_u.CT_ntc.NTC_column
	
	; Clean up the stack.
	pop	ax, bx, es, ds, di, si
	add	sp, size C_CallbackStruct
	pop	si
	
	.leave
	ret
SCB_NameToCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCB_FunctionToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       C callback interface for SpreadsheetDependCallback.

CALLED BY:      SpreadsheetDependCallback via callbackHandlers
PASS:           ss:bp   = Pointer to PCT_vars
                cx      = Function ID
RETURN:         dx	= Row (0 means no dependency required)
                cx	= Column
DESTROYED:      ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCB_FunctionToCell	proc	near
	.enter
	;
	; Make a local structure on the stack for the C parameters.
	; Note that we can't do this as a "local" declaration, because bp
	; is passed as an argument.
	;
	push	si		; save whatever's in si.
	sub	sp, size C_CallbackStruct
	mov	si, sp
	;
	; ss:si - pointer to the top of a C_CallbackStruct.	
	;
	mov	ss:[si].C_callbackType, CT_FUNCTION_TO_CELL
	mov	ss:[si].C_params.high, ss
	mov	ss:[si].C_params.low, bp
	mov	ss:[si].C_u.CT_ftc.FTC_funcID, cx
	
	push	bx, es, ds
	push	si
	
	; Push address to the C_CallbackStruct and call the C handler.
	push	ss
	push	si
	mov	ax, ss:[bp].PCTV_CCallBack.offset
	mov	bx, ss:[bp].PCTV_CCallBack.segment
	mov	ds, ss:[bp].PCTV_CCallBack_ds
	call	ProcCallFixedOrMovable
	
	; We're back!  Get an error value, if it's there.
	pop	si
	mov	al, ss:[si].C_u.CT_ftc.FTC_error
	
	; Prepare to set the carry flag if an error occurred.
	mov	ah, ss:[si].C_u.CT_ftc.FTC_errorOccurred
	
	; Get return values.
	mov	dx, ss:[si].C_u.CT_ftc.FTC_row
	mov	cx, ss:[si].C_u.CT_ftc.FTC_column

	; Clean up the stack.
	pop	bx, es, ds
	add	sp, size C_CallbackStruct
	pop	si
	
	; Set the carry flag if an error occurred.
	sal	ah, 1
	
	.leave
	ret
SCB_FunctionToCell	endp

SpreadsheetNameCode	ends

	SetDefaultConvention
