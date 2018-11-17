COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetRecalc.asm

AUTHOR:		John Wedgwood, Mar 22, 1991

ROUTINES:
	Name			Description
	----			-----------
    EXT RecalcDependentsNoRedraw Recalculate the dependents of a cell, but
				do not redraw

    EXT RecalcDependents	Recalculate the dependents of a cell and
				call CellRedraw when appropriate.

    EXT RecalcDependentsWithRedrawCallback Recalculate the dependents of a
				cell and use a callback for the cell
				redraw.

    INT RecalcCellList		Recalculate the cell list.
    INT RecalcCellListCallback	Callback routine for recalculating cell
				dependents.
    INT RecalcOneCell		Recalculate a single cell.
    INT RecalcFormulaCell	Recalculate a formula cell but don't store
				the result.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	3/22/91		Initial revision
	jeremy	7/20/92		Modified code for C use


DESCRIPTION:
	Code to do recalculation.

NOTES:
	I keep a cell-list which consists of cells to handle and cells
	which have been handled.

	I use the CRC_ABSOLUTE flag for the cell row to determine if
	a cell has been handled already.
	
	I use the CRC_ABSOLUTE flag for the cell column to determine if
	a cell has been handled and has been determined to be part of
	a circular reference loop.

	CF_current.RV_TEXT is a size; FP_nChars is a length.

	$Id: spreadsheetRecalc.asm,v 1.1 97/04/07 11:14:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcDependentsNoRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the dependents of a cell, but do not redraw

CALLED BY:	FillPasteCommon()
PASS:		(ax,cx)	- (r,c) of the cell
		ds:si - Spreadsheet instance
RETURN:		carry - set on error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcDependentsNoRedraw		proc	far
	class	SpreadsheetClass
	uses	bx, dx, bp
	.enter

	;
	; Create a PCT_structure for RecalcCellList.
	;
	push	bp
	sub	sp, size PCT_vars	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- ptr to the stack frame

	;
	; Initialize the common parameters.
	;
	call	SpreadsheetInitCommonParams

	;
	; Set the redraw callback pointer
	;
	mov	ss:[bp].PCTV_redrawCallback.segment, vseg NoRedrawCallback
	mov	ss:[bp].PCTV_redrawCallback.offset, offset NoRedrawCallback

	call	RecalcDependentsWithRedrawCallback
	
	;
	; Fix up the stack.
	;
	add	sp, size PCT_vars	; Restore the stack
	pop	bp

	.leave
	ret
RecalcDependentsNoRedraw		endp

NoRedrawCallback	proc	far
	ret
NoRedrawCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcDependents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the dependents of a cell and call CellRedraw
		when appropriate.

CALLED BY:	EnterDataFromEditBar
PASS:		ax/cx	= Row/column of the cell
		ds:si	= Spreadsheet instance
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	7/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcDependents	proc	far
	class	SpreadsheetClass
	uses	bx, dx, bp
	.enter

	;
	; Create a PCT_structure for RecalcCellList.
	;
	push	bp
	sub	sp, size PCT_vars	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- ptr to the stack frame

	;
	; Initialize the common parameters.
	;
	call	SpreadsheetInitCommonParams

	;
	; Set the redraw callback pointer
	;
	mov	ss:[bp].PCTV_redrawCallback.segment, vseg CellRedrawDXCX
	mov	ss:[bp].PCTV_redrawCallback.offset, offset CellRedrawDXCX

	call	RecalcDependentsWithRedrawCallback
	
	;
	; Fix up the stack.
	;
	add	sp, size PCT_vars	; Restore the stack
	pop	bp

	.leave
	ret
RecalcDependents	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcDependentsWithRedrawCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the dependents of a cell and use a callback
		for the cell redraw.

CALLED BY:	EnterDataFromEditBar
PASS:		ax/cx	= Row/column of the cell
		ss:bp	= PCT_struct, initialized with
			  SpreadsheetInitCommonParams.
		ds:si	= Spreadsheet instance
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/28/91		Initial version
	jeremy	7/17/92		Added redraw callback so C routines can
				use this function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcDependentsWithRedrawCallback	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	test	ds:[si].SSI_flags, mask SF_MANUAL_RECALC
	jnz	quitRecalcThisCell	; Quit if not auto-recalc

	mov	bx, offset cs:AppendDependentsToCellList
	call	CreateCellList		; bx <- end of cell list
					; al <- cumulative CellListEntryFlags

	mov	cx, mask RLF_FIRST_CELL	; Force first cell to be updated

	call	RecalcCellList		; Recalculate the cell list

	call	FreeFinalList		; Free up the cell list
quit:
	clc				; Signal: no error
	.leave
	ret

quitRecalcThisCell:
	;
	; If we are doing manual recalc then we need to recalc and
	; draw this cell.
	;
	cmp	ax, NAME_ROW		; Check for recomputing a name
	je	quit			; Branch if doing a name.

	mov	ss:[bp].CP_row, ax	; Set the row/column we're evaluating
	mov	ss:[bp].CP_column, cx
	mov	ss:[bp].PCTV_row, ax
	mov	ss:[bp].PCTV_column, cx

	;
	; It's not a name, recalculate it.
	;
	SpreadsheetCellLock		; *es:di <- cell
	jnc	noCell			; Branch if there's no cell

	mov	di, es:[di]		; es:di <- cell
	call	RecalcOneCell		; Recalc the cell
	SpreadsheetCellUnlock		; Release the cell

noCell:
	mov	bx, ss:[bp].PCTV_redrawCallback.segment
	mov	dx, ss:[bp].PCTV_redrawCallback.offset
	xchg	ax, dx			; bx:ax   <- addr to call
					; (dx,cx) <- cell to draw
	call	ProcCallFixedOrMovable

	jmp	quit			; Branch to quit
RecalcDependentsWithRedrawCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the cell list.

CALLED BY:	RecalcDependents, ManualRecalc
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= PCT_struct, initialized with
			  SpreadsheetInitCommonParams.
		bx	= Handle to end of cell list
		al	= Cumulative CellListEntryFlags
			  CLEF_PART_CIRCULARITY set if there was a circularity
		cx	= Initial PCTV_flags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	You need to free the list yourself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcCellList	proc	near
	class	SpreadsheetClass
	uses	ax, cx, dx, bp
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Set our loop counter in case there were no circularities and we
	; decide to branch right into the loop.
	;
	mov	dx, 1			; Assume only one time through the loop

	test	al, mask CLEF_PART_CIRCULARITY
	jz	recalcList		; Branch if no circularities
	
	;
	; There were circularities. See if we're allowing them and if we are
	; then get the iteration counter.
	;
	test	ds:[si].SSI_flags, mask SF_ALLOW_ITERATION
	jz	recalcList		; Branch if not allowing iteration

	;
	; There was a circularity and we are allowing iteration. Set the number
	; of times we want to recalculate.
	;
	mov	dx, ds:[si].SSI_circCount

recalcList:
	;
	; Now we can start processing it. First we need the stack frame to pass.
	; dx = # of times to go through the loop
	;
	mov	ss:[bp].PCTV_flags, cl	; Set the initial flags

	;
	; Process the list 'dx' times.
	;
	mov	cx, dx			; cx <- count (1 or greater)
recalcLoop:
	;
	; Note that we haven't diverged.
	;
	andnf	ss:[bp].PCTV_flags, not mask RLF_DIVERGED

	;
	; Recalculate the tree.
	;
	mov	ax, offset cs:RecalcCellListCallback
	call	ForeachCellListEntry	; Call callback for each entry
	
	;
	; Before we loop, check to see if we are converging. If we are then
	; we can just quit now.
	;
	test	ss:[bp].PCTV_flags, mask RLF_DIVERGED
	jz	endLoop			; Branch if we're converging

	;
	; We diverged, try it all over again.
	;
	loop	recalcLoop		; Loop to do it all over again

endLoop:	
	.leave
	ret
RecalcCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcCellListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for recalculating cell dependents.

CALLED BY:	RecalcDependents via ForeachCellListEntry
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= PCT_vars structure on the stack
		dx	= Row
		cl	= Column
		ch	= Flags
		es:di	= Pointer to the current cell list entry
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

bREVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcCellListCallback	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Set up ax/cx with the row/column and dh with the flags.
	;
	mov	ax, dx			; ax <- row
	mov	dh, ch			; dh <- flags
	clr	ch			; cx <- column
	
	;
	; It is possible that the cell doesn't exist. This can only happen
	; when the user has replaced the current cell with an empty one. The
	; cell gets removed, but is the root of the recalc tree anyway.
	; We need to detect this condition and do nothing.
	;
	SpreadsheetCellLock		; *es:di <- cell data
	LONG jnc cellDoesNotExist	; Branch if cell doesn't exist

	;
	; Cell does exist. Recalculate it appropriately.
	;
	mov	di, es:[di]		; es:di <- cell data

if _PROTECT_CELL
	;
	; For cell protection, we have to leave the protection bit unchanged.
	;
	andnf	es:[di].CC_recalcFlags, mask CRF_PROTECTION
else
	;
	; We left the "reserved" bit as it is
	;
	andnf	es:[di].CC_recalcFlags, mask CRF_RESERVED
endif
	SpreadsheetCellDirty		; Dirty the cell

	;
	; We don't want to compute names. We did need to lock the cell in 
	; order to clear out the recalc flags though.
	;
	cmp	ax, NAME_ROW		; Don't recalc names
	je	quitUnlock		; Branch if it's a name

	mov	ss:[bp].CP_row, ax	; Set the row/column we're evaluating
	mov	ss:[bp].CP_column, cx
	mov	ss:[bp].PCTV_row, ax
	mov	ss:[bp].PCTV_column, cx

	;
	; Check for iterating through circularities. If we are then we don't
	; mark  cells which are part of a circularity with an error.
	;
	test	ds:[si].SSI_flags, mask SF_ALLOW_ITERATION
	jnz	recalcCell		; Branch if allowing iteration

	;
	; We aren't iterating through circularities. Check for an error.
	; Check for start of a circularity or part of a circularity.
	;
	test	dh, mask CLEF_PART_CIRCULARITY
	jz	recalcCell		; Branch if not part of circularity
	
	;
	; It is the start of a circular reference. Mark the cell appropriately.
	;
	; First make sure it isn't already marked as such:
	;	type	= Formula
	;	return	= Error
	;	value	= CE_CIRC_DEPEND
	;
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
	cmp	es:[di].CC_type, CT_FORMULA
	jne	saveError		; Branch if not already formula
	cmp	es:[di].CF_return, RT_ERROR
	jne	saveError		; Branch if not an error result
	cmp	es:[di].CF_current.RV_ERROR, CE_CIRC_DEPEND
	je	quitUnlock		; Branch if already this error

saveError:
	push	ax			; Save the row
	mov	ax, RT_ERROR		; ax <- type of result
	call	ResizeFormulaResult	; Resize the cell
	mov	es:[di].CF_current.RV_ERROR, CE_CIRC_DEPEND
	SpreadsheetCellDirty		; Dirty the cell
	pop	ax			; Restore the row
	jmp	redrawCell		; Branch to redraw the cell

recalcCell:
	call	RecalcOneCell		; Recalculate the cell
	
	test	ss:[bp].PCTV_flags, mask RLF_CHANGED
	jz	quitUnlock		; Branch if cell didn't change

redrawCell:
	mov	dx, ax			; (dx, cx) <- the cell to redraw
	call	CheckIfLocked		;send recalc locked cells msg if locked
	mov	ax, ss:[bp].PCTV_redrawCallback.offset
	mov	bx, ss:[bp].PCTV_redrawCallback.segment
	call	ProcCallFixedOrMovable	; Draw the cell
					; Nukes ax, bx, cx, dx, di

quitUnlock:
	SpreadsheetCellUnlock		; Release the cell

quit:	
	and	ss:[bp].PCTV_flags, not mask RLF_FIRST_CELL
	clc				; Signal: continue
	.leave
	ret

cellDoesNotExist:
	;
	; The cell doesn't exist. We need to redraw it anyway...
	;
	; ax/cx = Row/Column
	; ds:si = Spreadsheet pointer
	;
	mov	dx, ax			; dx/cx = Row/Column
	mov	ax, ss:[bp].PCTV_redrawCallback.offset
	mov	bx, ss:[bp].PCTV_redrawCallback.segment
	call	ProcCallFixedOrMovable

	jmp	quit
RecalcCellListCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A cell has changed. If it is a locked cell, send
		a notification message.

CALLED BY:	RecalcCellListCallback
PASS:		ds:si - Spreadsheet instance
		dx, cx - cell which changed
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfLocked		proc	near
		class	SpreadsheetClass
		uses	si
		.enter
		
	;
	; If the cell to be drawn is in the locked area, calling the
	; redraw callback won't do it.  Notify ourselves that this
	; cell needs to be redrawn. It will be handled in GeoCalc.
	;
		mov	si, ds:[si].SSI_chunk		
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		call	ObjVarFindData		
		jnc	notLocked

		cmp	dx, ds:[bx].SDO_rowCol.CR_row
		jb	locked
		cmp	cx, ds:[bx].SDO_rowCol.CR_column
		jae	notLocked

locked:			
		push	cx, dx, bp
		mov	ax, MSG_SPREADSHEET_LOCKED_CELL_RECALC
		call	ObjCallInstanceNoLock	
		pop	cx, dx, bp

notLocked:		
		.leave
		ret
CheckIfLocked		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcOneCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a single cell.

CALLED BY:	IntelligentRecalc via DoSomethingToDependents
PASS:		ss:bp	= Pointer to PCT_vars on stack
		ds:si	= Spreadsheet instance
		es:di	= Pointer to cell data
RETURN:		es:di	= Pointer to cell data (may have moved)
		ss:bp.PCTV_flags with RLF_CHANGED and RLF_DIVERGED set if
			appropriate.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine must be declared "far" since it is passed on the stack
	as a callback routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcOneCell	proc	near
		uses	ax, bx, cx, si, ds
		.enter
EC <		call	ECCheckInstancePtr		;>
	;
	; Check for a chart cell.
	;
		cmp	ss:[bp].PCTV_row, CHART_ROW
CHART<		je	recalcChartCell	; Branch if a chart cell	>
NOCHART<	je	quit		; don't handle chart cell	>

	;
	; We don't want to calculate any other non-formula cells.
	;
EC <		test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <		ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
		cmp	es:[di].CC_type, CT_FORMULA
		jne	quitMayHaveChanged	; Branch if not formula cell

		call	RecalcFormulaCell	; Recalc the formula
	;
	; The result is pointed at by ss:bx
	;
		call	SaveResult		; Save the result
quit:
		.leave
		ret

recalcChartCell::
CHART <		call	SpreadsheetRecalcChart				>
	;
	; Since a chart cannot have any dependents, we don't modify the
	; RLF_CHANGED flag.
	;
CHART <		jmp	quit						>

quitMayHaveChanged:
	;
	; The cell may have changed.
	;
	; If it's a display-formula cell then we want to force it to redraw so
	; we return that it has changed.
	;
	; Otherwise it's a constant cell so it couldn't have changed.
	;
		and	ss:[bp].PCTV_flags, not mask RLF_CHANGED

	;
	; If it's the first cell then the user has just entered this data and
	; we definitely want to mark it as changed.
	;
		test	ss:[bp].PCTV_flags, mask RLF_FIRST_CELL
		jnz	hasChanged		; Branch if first cell

EC <		test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <		ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >

		cmp	es:[di].CC_type, CT_DISPLAY_FORMULA
		jne	quit			; Branch if not display formula

hasChanged:
	;
	; It's a display formula or it's the first cell, force it to redraw.
	;
		or	ss:[bp].PCTV_flags, mask RLF_CHANGED
		jmp	quit
RecalcOneCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a formula cell but don't store the result.

CALLED BY:	RecalcOneCell, FormulaDisplayCellGetResult
PASS:		ss:bp	= Pointer to PCT_vars on stack
		ds:si	= Spreadsheet instance
		es:di	= Pointer to cell data
RETURN:		ss:bx	= Pointer to the result
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Evaluate the expression, then if the result is an error, change
	the error code on the argument stack from a parser error to a
	cell error.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcFormulaCell	proc	far
	uses	ax, cx, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	add	di, CF_formula		; es:di <- ptr to the formula

	segmov	ds, es, si		; ds:si <- ptr to the formula
	mov	si, di
	
CheckHack< (size PCTV_evalBuffer) eq PARSE_TEXT_BUFFER_SIZE >
	mov	ss:[bp].EP_flags, 0	; Evaluate me...
	segmov	es, ss, di		; es:di <- ptr to scratch buffer
	lea	di, ss:[bp].PCTV_evalBuffer
	mov	cx, PARSE_TEXT_BUFFER_SIZE
	call	ParserEvalExpression		; Evaluate it...
	jc	errorEval		; Branch on error
	;
	; Check for an error. If there is one, we want to convert it to a
	; cell error.
	;
	test	ss:[bx].ASE_type, mask ESAT_ERROR
	jz	quit
	
	;
	; Convert the parser error to a cell error and stick it back on
	; the stack.
	;
	mov	al, ss:[bx].ASE_data.ESAD_error.EED_errorCode
	call	ConvertParserError	; al <- new error
	mov	ss:[bx].ASE_data.ESAD_error.EED_errorCode, al
quit:
	.leave
	ret

errorEval:
	;
	; There was some serious evaluator error.
	; Possible errors include:
	;	- Out of stack space (expression too complicated)
	;	- Names are nested too deeply
	;
	; We just stuff a "too complex" error
	;
	lea	bx, ss:[bp].PCTV_evalBuffer
	mov	ss:[bx].ASE_type, mask ESAT_ERROR
	mov	ss:[bx].ASE_data.ESAD_error.EED_errorCode, CE_TOO_COMPLEX
	jmp	quit
RecalcFormulaCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the result of a calculation into a cell.

CALLED BY:	RecalcOneCell
PASS:		ss:bp	= Pointer to PCT_vars
		ss:bx	= Pointer to the result
		ds:si	= Spreadsheet instance
		es:di	= Pointer to the cell data
RETURN:		es:di	= Pointer to cell (may have moved)
		ss:bp.PCTV_flags with:
			- RLF_CHANGED bit set if the cell changed
			- RLF_CHANGED bit clear otherwise
			- RLF_DIVERGED bit set if the cell changed by more than
			  value in SSI_converge. This bit is never cleared
			  since it is a cumulative marker...
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveResult	proc	near
	class	SpreadsheetClass
	uses	ax, cx, dx, ds, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Check to see if the cell has changed. If we're doing iteration, then
	; this routine will also check for convergence.
	;
	call	CompareResultToCell	; Check for a change
	
	test	ss:[bp].PCTV_flags, mask RLF_CHANGED
	jz	quit			; Branch if no change

	;
	; Check for an error first, since it's a conglomerate of the
	; other bit fields.
	;
	test	ss:[bx].ASE_type, mask ESAT_ERROR
	jnz	saveError

	test	ss:[bx].ASE_type, mask ESAT_NUMBER
	jnz	saveNumber
	
	test	ss:[bx].ASE_type, mask ESAT_STRING
	jnz	saveString
;------------------------------------------------------------------------------
; Some sort of an error
;
	mov	cl, CE_TYPE		; Bad type is our "generic" error
	jmp	gotError

saveError:
	mov	cl, ss:[bx].ASE_data.ESAD_error.EED_errorCode

gotError:
	mov	ax, RT_ERROR		; al <- new formula result
	call	ResizeFormulaResult	; Adjust the result of the formula
	
	mov	es:[di].CF_current.RV_ERROR, cl
	jmp	done

;------------------------------------------------------------------------------
; Result is a number
;
saveNumber:
	;
	; Save a numeric result into the cell.
	; ss:bx.ASE_data = ptr to the number to save
	;
	mov	al, RT_VALUE		; al <- new formula result
	call	ResizeFormulaResult	; Adjust the result of the formula
					; dx <- position to save data at

	push	di			; Save pointer to cell data
	mov	di, dx			; es:di <- ptr to place to put result
	call	FloatPopNumber		; Save the number
	pop	di			; Restore pointer to cell data
	jmp	done			; Branch to finish up

;------------------------------------------------------------------------------
; Result is a string
;
saveString:
	;
	; Save a string result into the cell
	; ss:bx.ASE_data = the string: length followed by data (no NULL).
	;
	mov	al, RT_TEXT		; al <- new formula result
	call	ResizeFormulaResult	; Adjust the result of the formula

	push	ds, si, di		; Save instance ptr, cell ptr
	segmov	ds, ss, ax		; ds <- source (arg stack)
					; Save the string length
	mov	ax, ds:[bx].ASE_data.ESAD_string.ESD_length

	mov	cx, ax			; cx <- string length

DBCS<	shl	ax, 1			; ax <- size of string		>
	mov	es:[di].CF_current.RV_TEXT, ax
	
	mov	di, dx			; es:di <- ptr to put the string

	mov	si, bx			; ds:si <- ptr to arg-stack element
	add	si, offset ASE_data + 2	; ds:si <- ptr to the string
	LocalCopyNString 		; Copy the string data
	pop	ds, si, di		; Restore instance ptr, cell ptr
	;
	; Fall thru to finish up
	;

done:
	;
	; es:di must contain a pointer to the cell data here.
	; ds:si must contain a pointer to the spreadsheet instance data.
	;
	SpreadsheetCellDirty		; Mark the cell as dirty
quit:
	.leave
	ret
SaveResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareResultToCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the new result to the old cell data.

CALLED BY:	SaveResult
PASS:		es:di	= Pointer to cell data
		ss:bp	= Pointer to PCT_vars structure on the stack
		ds:si	= Spreadsheet instance
		ss:bx	= Pointer to the new result.
RETURN:		ss:bp.PCTV_flags with:
			- RLF_CHANGED bit set if the cell changed
			- RLF_CHANGED bit clear otherwise
			- RLF_DIVERGED bit set if the cell changed by more than
			  value in SSI_converge. This bit is never cleared
			  since it is a cumulative marker...
		If the RLF_CHANGED bit is clear and the cell contains a number
		then the new result (same as the old) will have been removed
		from the fp-stack.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 3/91	Initial version
	witt	11/17/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareResultToCell	proc	near
	class	SpreadsheetClass
	uses	ax, cx, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; The first cell that ever gets computed is considered to have changed
	; but not diverged.
	;
	test	ss:[bp].PCTV_flags, mask RLF_FIRST_CELL
	LONG jnz quitChanged

	;
	; Clear the bit signalling a change in the cell.
	;
	and	ss:[bp].PCTV_flags, not mask RLF_CHANGED

	;
	; If the cell type is anything other than "formula" then it must have
	; changed.
	;
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >

	cmp	es:[di].CC_type, CT_FORMULA
	LONG jne quitDiverged		; If different, changed and diverged

	;
	; It was a formula cell (and it is now a formula cell).
	;
	; Compare the return types.
	;
	mov	al, ss:[bx].ASE_type	; al <- evaluator type bits
	
	mov	ah, RT_ERROR		; Assume error type
	test	al, mask ESAT_ERROR	; Check for evaluator type == error
	jnz	gotReturnType		; Branch if it is an error

	mov	ah, RT_VALUE		; Assume value
	test	al, mask ESAT_NUMBER	; Check for evaluator type == number
	jnz	gotReturnType		; Branch if it is a number

	mov	ah, RT_TEXT		; Assume text
	test	al, mask ESAT_STRING	; Check for evaluator type == text
	jnz	gotReturnType		; Branch if it is a text
	
	;
	; Hmmm... It is something mysterious. Assume it must have changed
	;
	jmp	quitDiverged		; Branch if something mysterious

gotReturnType:
	;
	; ah = Return type for the new value. Always one of:
	;	RT_ERROR, RT_VALUE, RT_TEXT
	;
	cmp	ah, es:[di].CF_return	; Check for same return type
	LONG jne  quitDiverged		; Branch if not the same
	
	;
	; We know that the types are the same, now we take the type and do
	; a comparison based on the type.
	;
	cmp	ah, RT_ERROR		; Check for error
	jne	notError		; Branch if not

	;
	; Compare the error values.
	;
	mov	al, ss:[bx].ASE_data.ESAD_error.EED_errorCode
	cmp	al, es:[di].CF_current.RV_ERROR
	jne	quitDiverged		; Branch if errors differ
	jmp	quit			; Otherwise just quit

notError:
	cmp	ah, RT_TEXT		; Check for text
	jne	notText			; Branch if not text
	
	;
	; Compare the strings.
	;
	mov	cx, ss:[bx].ASE_data.ESAD_string.ESD_length
if DBCS_PCGEOS
	mov	si, es:[di].CF_current.RV_TEXT
	shr	si, 1			; si <- string length
EC<	ERROR_C CELL_DATA_STRING_ODDSIZE
	cmp	cx, si			; compare lengths
else
	cmp	cx, es:[di].CF_current.RV_TEXT
endif
	jne	quitDiverged		; Branch if the lengths differ

	;
	; cx == String length
	;
	add	di, es:[di].CF_formulaSize
	add	di, size CellFormula	; es:di <- ptr to the old string
	
	segmov	ds, ss, si		; ds:si <- ptr to new string
	lea	si, ss:[bx].ASE_data+2
SBCS<	repe	cmpsb			; Check for a change		>
DBCS<	repe	cmpsw			; Check for a change		>
	jne	quitDiverged		; Branch if strings differ
	jmp	quit			; Otherwise just quit

notText:
	;
	; Well... It must be a number. The new value is on the fp-stack.
	; What we need to do is duplicate it and subtract it from the old
	; value. This gives us the amount of change.
	; 
	; If the result is zero then we can just quit.
	;
	; Otherwise we take the absolute value of the result and compare
	; it to SSI_converge. If it is less than SSI_converge then we 
	; know that while we differ, we are converging.
	;
	
	;
	; Check for old and new values being the same.
	; On fp stack:
	;	New value
	;
	push	di			; Save ptr
	lea	di, es:[di].CF_current.RV_VALUE
	call	FloatCompESDI		; Compare against pointer
					; Nukes ax
	pop	di			; Restore ptr
	je	quitPopNumber		; Branch if no change

	;
	; We know that the value changed. That means we need to leave the
	; new value on the fp-stack.
	; If we are not allowing iteration, then this is all we care about.
	;
	test	ds:[si].SSI_flags, mask SF_ALLOW_ITERATION
	jz	quitChanged		; Branch if not allowing iteration

	;
	; Now take the absolute value of the difference between the old and new
	; values.
	;
	call	FloatDup		; Duplicate new value

	push	ds, si			; Save spreadsheet instance
	segmov	ds, es, si		; ds:si <- ptr to old value
	lea	si, es:[di].CF_current.RV_VALUE
	call	FloatPushNumber		; Push the old value on the stack
	call	FloatSub		; Take the difference
	call	FloatAbs		; Take the absolute value
	pop	ds, si			; Restore spreadsheet instance
	
	;
	; Now subtract this from the convergence value.
	; fp stack:
	;		New Value
	;	Top =>	Difference between old and new
	;
	lea	si, ds:[si].SSI_converge
	call	FloatPushNumber		; Push convergence value
	call	FloatCompAndDrop	; Compare and remove values
	jbe	quitChanged		; Branch if differs by only a little
	;
	; Difference is larger than the maximum allowed change.
	; The value has not converged.
	;
quitDiverged:
	or	ss:[bp].PCTV_flags, mask RLF_DIVERGED
quitChanged:
	or	ss:[bp].PCTV_flags, mask RLF_CHANGED
quit:
	.leave
	ret

quitPopNumber:
	call	FloatDrop		; Remove number from the fp-stack
	jmp	quit
CompareResultToCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertParserError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a parser error to a cell error.

CALLED BY:	SaveResult
PASS:		al	= ParserScannerEvaluatorError
RETURN:		al	= CellError
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	al must be one of the errors in parserErrorTable otherwise
	we will die with a fatal error.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertParserError	proc	near
	uses	cx, es, di
	.enter
	segmov	es, cs
	mov	di, offset cs:parserErrorTable	; es:di <- ptr to the table
	mov	cx, length parserErrorTable	; cx <- size of the table
	repne	scasb				; Try to find it...
	;
	; This error can only happen if someone has mucked with the error
	; codes or if the caller is passing a bad value.
	;
EC <	ERROR_NE PARSER_ERROR_NOT_FOUND		>

	mov	al, cs:[di][(offset cellErrorTable)-(offset parserErrorTable)-1]
	.leave
	ret
ConvertParserError	endp

;
; Two parallel tables. One contains a list of parser errors. The other
; contains the cell errors associated with each of the parser errors. Make
; sure you update them both together.
;
parserErrorTable	byte	PSEE_OUT_OF_STACK_SPACE,
				PSEE_NESTING_TOO_DEEP,
				PSEE_ROW_OUT_OF_RANGE,
				PSEE_COLUMN_OUT_OF_RANGE,
				PSEE_FUNCTION_NO_LONGER_EXISTS,
				PSEE_UNDEFINED_NAME,
				PSEE_BAD_ARG_COUNT,
				PSEE_WRONG_TYPE,
				PSEE_DIVIDE_BY_ZERO,
				PSEE_CIRCULAR_REF,
				PSEE_GEN_ERR,
				PSEE_NA,
				PSEE_FLOAT_POS_INFINITY,
				PSEE_FLOAT_NEG_INFINITY,
				PSEE_FLOAT_GEN_ERR,
				PSEE_CIRCULAR_DEP,
				PSEE_CIRC_NAME_REF,
				PSEE_NUMBER_OUT_OF_RANGE

cellErrorTable		byte	CE_TOO_COMPLEX,
				CE_TOO_COMPLEX,
				CE_REF_OUT_OF_RANGE,
				CE_REF_OUT_OF_RANGE,
				CE_NAME,
				CE_NAME,
				CE_ARG_COUNT,
				CE_TYPE,
				CE_DIVIDE_BY_ZERO,
				CE_CIRCULAR_REF,
				CE_GEN_ERR,
				CE_NA,
				CE_FLOAT_POS_INF,
				CE_FLOAT_NEG_INF,
				CE_FLOAT_GEN_ERR,
				CE_CIRC_DEPEND,
				CE_CIRC_NAME_REF,
				CE_NUM_OUT_OF_RANGE

.assert	(size cellErrorTable eq size parserErrorTable)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCellError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a cell error into a PSEE_error

CALLED BY:	DerefFormula
PASS:		al	= Error to convert
RETURN:		al	= PSEE_error to use
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertCellError	proc	near
	uses	cx, di, es
	.enter
	segmov	es, cs
	mov	di, offset cs:cellErrorTable	; es:di <- ptr to the table
	mov	cx, size cellErrorTable		; cx <- size of the table
	repne	scasb				; Try to find it...
	;
	; This can only happen if someone has mucked with the error codes
	; or if the caller passed a garbage value.
	;
EC <	ERROR_NE PARSER_ERROR_NOT_FOUND		>

	sub	di, offset cs:cellErrorTable	; di <- offset past entry
	mov	al, cs:parserErrorTable[di-1]	; al <- the parser error
	.leave
	ret
ConvertCellError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeFormulaResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a formula cell in order to make space for the result.

CALLED BY:	SaveResult
PASS:		es:di	= Pointer to the cell
		ds:si	= Spreadsheet instance
		al	= New type for the cell
		if al == ESAT_STRING
			ss:bx	= Pointer to the EvalArgumentStack
RETURN:		es:di	= Pointer to the cell (may have moved)
		es:dx	= Position to save the data at
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are only a few interesting cases here:
		Text -> Text
		Text -> other
		other-> Text

	In all other cases no resizing of the cell is necessary.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If an error is returned, the cell will be unlocked.
	
	The new type is saved into the cell, but the cell isn't marked as
	dirty. If you don't mark it as dirty before unlocking it the new type
	may be lost.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/18/91	Initial version
	witt	11/17/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeFormulaResult	proc	near
	uses	bx, cx
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; We need to figure out how many bytes to insert/delete from the
	; text area at the end of the cell data.
	;
	clr	cx				; Assume not text type

	cmp	al, RT_TEXT			; Check for new == text
	jne	gotNewSize			; Branch if it's not
	mov	cx, ss:[bx].ASE_data.ESAD_string.ESD_length
DBCS<	shl	cx, 1				; cx <- string size	>
gotNewSize:
	;
	; cx == the new size. Now we need to get the old size and adjust the
	; buffer appropriately.
	;
	cmp	es:[di].CF_return, RT_TEXT	; Check for old == text
	jne	gotOldSize			; Branch if it isn't
	sub	cx, es:[di].CF_current.RV_TEXT	; cx <- old size
DBCS< EC< test	cx, 1					> >
DBCS< EC< ERROR_NZ  CELL_DATA_STRING_ODDSIZE	; Odd ball size!  > >

gotOldSize:
	;
	; cx == change in size.
	;
	mov	bl, al				; bl <- the type of the new data
	;
	; If both the old and new entries are text cells, and if both strings
	; are the same size, then we want to grab the position of the place
	; to put the new string here so we can skip a lot of calculation.
	;
	mov	dx, es:[di].CF_formulaSize	; dx <- offset for text cell
	add	dx, size CellFormula

	jcxz	findNewDataPos			; Branch if no change in size
	;
	; Resize the data... The position to resize at is the area after the
	; formula.
	;
	SpreadsheetCellUnlock			; Release the cell
	
	push	dx				; Save position to write data
	call	InsertIntoCurrentCell		; Make the change
	pop	dx				; Restore position to write data
	
	mov	ax, ss:[bp].PCTV_row		; ax <- row
	mov	cx, ss:[bp].PCTV_column		; cx <- column
	SpreadsheetCellLock			; Lock the cell down again
	mov	di, es:[di]
findNewDataPos:
	;
	; Now we need to set es:dx == pointer to the place to put the data.
	; bl == the new data type
	;
	mov	es:[di].CF_return, bl		; Save the new data type
	mov	bx, offset CF_current		; Assume non-text type

	cmp	es:[di].CF_return, RT_TEXT	; Check for text type
	jne	quitNoError			; Branch if not text type
	;
	; It's a text cell, save the position that the text is at.
	;
	mov	bx, dx				; Fall thru w/ value in bx

quitNoError:
	;
	; bx == offset to the place to store the new data.
	;
	add	bx, di				; es:bx <- place to put data
	mov	dx, bx				; es:dx <- place to put data

	.leave
	ret
ResizeFormulaResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManualRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a spreadsheet manually.

CALLED BY:	SpreadsheetRecalc
PASS:		ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	ext = CellGetExtent()
	list = AllocChildList()

	RangeEnum( extent ):
	    Add cell to cell list

	CreateCellListFromChildList( list )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManualRecalcVars	struct
    MRV_rangeParams	RangeEnumParams
    MRV_tempListHead	hptr		; First block handle of temporary list
    MRV_tempListBlock	hptr		; Block handle of temporary list
ManualRecalcVars	ends

ManualRecalc	proc	far
	uses	ax, bx, cx, dx
localVars	local ManualRecalcVars
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Fill in the parameters.
	;
	lea	bx, localVars.MRV_rangeParams
	call	CellGetExtent		; REP_bounds <- extent of spreadsheet
	
	;
	; Check for no data at all.
	;
	cmp	localVars.MRV_rangeParams.REP_bounds.R_top, -1
	je	quit			; Branch if no data
	
	call	ManualRecalcSetup	; Setup the frame
	;
	; Now create the cell list.
	;
	; bp	= Local variables
	; ds:si	= Spreadsheet instance
	;
	push	bp, si			; Save frame ptr, instance ptr
	mov	bx, localVars.MRV_tempListBlock
	
	;
	; Create stack frame.
	;
	sub	sp, size CreateCellListParams
	mov	bp, sp			; ss:bp <- ptr to parameters

	;
	; Initialize it.
	;
	mov	ss:[bp].CCLP_moreCallback, offset cs:AppendDependentsToCellList

	;
	; Set ss:bp to point at the top of it.
	;
	add	bp, size CreateCellListParams

	call	CreateCellListFromChildList
					; bxi <- end of celllist
	
	add	sp, size CreateCellListParams
	pop	bp, si			; Restore frame ptr, instance ptr
	
	;
	; Now recalculate this cell list.
	; bx	= End of cell list
	; al	= Flags
	;
	clr	cx			; Don't force first cell to be updated

	push	bp
	sub	sp, size PCT_vars	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- ptr to the stack frame
	;
	; Initialize the common parameters.
	;
	call	SpreadsheetInitCommonParams
	mov	ss:[bp].PCTV_redrawCallback.segment, vseg CellRedrawDXCX
	mov	ss:[bp].PCTV_redrawCallback.offset, offset CellRedrawDXCX

	call	RecalcCellList		; Recalculate

	;
	; Fix up the stack.
	;
	add	sp, size PCT_vars	; Restore the stack
	pop	bp

	call	FreeFinalList		; Free up the list
quit:
	.leave
	ret
ManualRecalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManualRecalcSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the ManualRecalcVars

CALLED BY:	ManualRecalc, CreateNamePrecedentsList
PASS:		ss:bp	= Pointer to inheritable ManualRecalcVars with:
				MRV_rangeParams.REP_bounds set
RETURN:		Rest of the stack frame set up.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManualRecalcSetup	proc	near
	uses	ax, bx, dx
localVars	local	ManualRecalcVars
	.enter	inherit
	;
	; First create the cell list and store the pointer into the
	; stack frame.
	;
	call	AllocChildList		; bx <- empty cell
	mov	localVars.MRV_tempListHead, bx
	mov	localVars.MRV_tempListBlock, bx

	lea	bx, localVars.MRV_rangeParams

	;
	; Now setup and call RangeEnum.
	;
	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset,  offset cs:MRCallback
	
	;
	; We only want cells with data in them and we don't need the cells
	; locked because we aren't using the data inside them.
	;
	mov	dl, mask REF_NO_LOCK
	call	RangeEnum		; Build the cell list
	.leave
	ret
ManualRecalcSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a cell to the cell list.

CALLED BY:	ManualRecalc via RangeEnum
PASS:		ds:si	= Spreadsheet instance
		ax,cx	= Row,Column of current cell
		ss:bp	= Pointer to inheritable ManualRecalcVars
RETURN:		carry clear always
		dl	= unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRCallback	proc	far
	uses	ax, bx, cx, si
localVars	local	ManualRecalcVars
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	;
	; Add the cell to the cell list.
	;
	mov	bx, localVars.MRV_tempListBlock
	
	;
	; bx = Block of list to add to
	; ax = Row
	; cl = Column
	;
	clr	ch			; No flags
	call	PushCellListEntry	; Add entry to the list
	
	;
	; Set the current block.
	;
	mov	localVars.MRV_tempListBlock, bx

	clc				; Signal: continue
	.leave
	ret
MRCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachDependency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each dependent of a cell

CALLED BY:	AppendDependentsToCellList, AppendNamePrecedentsToCellList
PASS:		ds:si	= Spreadsheet instance
		es:di	= Pointer to the cell
		ax	= Near routine to call for each cell in the dependency
			  list.
RETURN:		carry set if callback aborted.
			ax set by callback only if aborted.
		es	= Segment address of same block it was when we got here
DESTROYED:	nothing (although blocks may move around due to the callback)

PSEUDO CODE/STRATEGY:
	Callback will be passed:
		All registers the same as were passed in except:
		ds:si	= Spreadsheet instance
		*es:bx	= Pointer to dependency list block
		(*es:bx)+di = Pointer to the current dependency list entry
		dx	= Row of the cell
		cx	= Column of the cell
	It can return carry set to abort processing.
	It may destroy ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The cells are processed in this order:
		Foreach block (first to last)
		    Foreach entry in the block (last to first)

	Callback routines can count on this order.
	
	This may be useful. You can tell when you have reached the last
	dependency because the following will be true when the callback
	is called:
		di = size DependencyListHeader
		(*es:bx).DLH_next.segment == 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachDependency	proc	near
	class	SpreadsheetClass
	uses	bx, cx, dx, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	push	es:LMBH_handle		; Save the handle of the passed block

	mov	bx, ds:[si].SSI_cellParams.CFP_file	; bx <- file handle
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
	mov	dx, es:[di].CC_dependencies.segment	; dx <- group
	mov	di, es:[di].CC_dependencies.offset	; di <- item
	
blockLoop:
	tst	dx			; Check for no entries
	jz	quit			; Branch if none (carry clear)
	
	push	bx			; Save the file handle

	xchg	ax, dx			; ax <- group, dx <- callback
	call	DBLock			; *es:di <- first dependency list
	mov	ax, dx			; ax <- callback

	mov	bx, di			; *es:di <- ptr to the block
	mov	di, es:[di]		; es:di <- ptr to dependency list

	ChunkSizePtr	es, di, cx	; cx <- size of the block
	add	di, cx			; es:di <- ptr past end of the block
	sub	di, es:[bx]		; di <- offset into the block
	
entryLoop:
	sub	di, size Dependency	; es:di <- ptr to next entry to process
	;
	; *es:bx= Pointer to block
	; ds:si	= Spreadsheet instance
	; di	= Offset to the next item to callback for
	; ax	= Callback routine
	; bx	= File handle
	;
	add	di, es:[bx]		; es:di = pointer to item

	mov	dx, es:[di].D_row	; dx <- row
	clr	ch
	mov	cl, es:[di].D_column	; cx <- column
	
	sub	di, es:[bx]		; Make di an offset again

	;
	; Check for an invalid cell entry.  The value 0x7fff is
	; derived from masking the sign bit from the value -1.  
	; ***See UpdateRefOrRep::illegalReference for -1, and
	;    UpdateDepCallback for masking of CRC_ABSOLUTE (1st bit.)
	;
	; 7/20/95 - ptrinh
	;
	cmp	dx, 0x7fff		; invalid dependency?
	je	skipEntry

	push	ax			; Save callback
	call	ax			; Call the callback
	jc	abort			; Branch if aborted
	pop	ax			; Restore callback

skipEntry:
	;
	; Check that there are more entries to do
	;
	cmp	di, size DependencyListHeader
	jne	entryLoop		; Branch if there are more to do

	;
	; We are all done with this block. There may be more.
	;
	mov	di, es:[bx]		; es:di <- ptr to start of block

	mov	dx, es:[di].DLH_next.segment
	mov	di, es:[di].DLH_next.offset
	
	pop	bx			; Restore the file handle
	call	DBUnlock		; Release this block
	
	jmp	blockLoop		; Branch to process the next block

quit:
	pop	bx			; bx <- handle of cell block passed in
	call	MemDerefES		; es <- segment address of block
	.leave
	ret

abort:
	add	sp, 2			; Discard callback pointer from the stack

	pop	bx			; Restore the file handle
	call	DBUnlock		; Release the block
	stc				; Signal: abort
	jmp	quit			; Branch, returning ax
ForeachDependency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a cell list for recalculation and other purposes.

CALLED BY:	RecalcDependents, UpdateNameDependents
PASS:		ds:si	= Spreadsheet instance
		ax,cx	= Row,Column of the cell to start with
		bx	= Callback routine for adding dependencies/precedents
			  Currently you should use either:
				AppendDependentsToCellList
				AppendNamePrecedentsToCellList
RETURN:		bx	= Handle to the end of the cell list
		al	= Cumulative CellListEntryFlags.
			  CLEF_PART_CIRCULARITY set if there was a circularity
			  in there somewhere.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	These routines modify the CC_recalcFlags field of the cell
	by setting the CRF_IN_FINAL_LIST bit. It is the responsibility
	of the caller to make sure that the CRF_IN_FINAL_LIST is
	cleared before any recalculation takes place. This is usually
	done in the callback supplied to ForeachCellListEntry().
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateCellListParams	struct
    ;
    ; These should all be set before the call to CreateCellListFromChildList()
    ;
    CCLP_moreCallback	word	; Callback to add dependencies or precedents
    
    ;
    ; These are all set by CreateCellListFromChildList()
    ;
    CCLP_childList	word	; Block handle at the end of the children list
    CCLP_ancestorList	word	; Block handle at the end of the ancestor list
    CCLP_finalList	word	; Block handle at the end of the final list
    CCLP_count		dword	; # of cells on the final list
    CCLP_flags		CellListEntryFlags
	align	word
CreateCellListParams	ends

CreateCellList	proc	near
	uses	cx
params	local	CreateCellListParams
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Initialize the parameters.
	;
	mov	ss:params.CCLP_moreCallback, bx

	;
	; First we allocate the child list.
	;
	call	AllocChildList		; bx <- handle of empty cell list
	
	;
	; Put the starting cell onto the child list.
	; Set the flags associated with the first cell (ax/cl)
	; bx holds the tempList handle
	;
	clr	ch			; No flags for the cell
	call	PushCellListEntry	; Push ax/cx onto the list
					; bx <- new childList block
	;
	; Now starting with the child list, create the new cell list.
	;
	call	CreateCellListFromChildList
	.leave
	ret
CreateCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCellListFromChildList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a child list, create the cell list.

CALLED BY:	CreateCellList, ManualRecalc
PASS:		bx	= Block handle of the last block in the list
		ss:bp	= Pointer to inheritable CreateCellListParams
		ds:si	= Spreadsheet instance
RETURN:		al	= Cumulative CellListEntryFlags.
			  CLEF_PART_CIRCULARITY set if there was a circularity
			  in there somewhere.
		bx	= Block and offset to the end of the final cell list
		child list is free'd
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    AncestorList = {}
    FinalList = {}

    while (not empty(ChildList)) {
	cell = Pop(ChildList)		/* Move cell to ancestor list */

	if (cell == marker) then {
	    cell = Pop(AncestorList)		/* Move cell to recalc list */
	    cell.flags &= ! inParentList	/* No longer a parent */
	    cell.flags |= inFinalList		/* Now in the final list */
	    Push(cell, FinalList)
	} else if (cell.flags & inParentList) {
	    MarkCircularities()			/* Found a circularity */
	} else if (cell.flags & inFinalList) {
	    /*
	     * Do nothing. We've already found a deeper entry for this
	     * cell so we can totally disregard this entry.
	     */
	} else {
	    Push(cell, AncestorList)

	    cell.flags |= inParentList
	    Push(marker, ChildList)		/* Mark start of children */

	    foreach dependency of cell {	/* Add dependencies */
		Push(dependency, ChildList)
	    }
	}
    }

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	These routines modify the CC_recalcFlags field of the cell
	by setting the CRF_IN_FINAL_LIST bit. It is the responsibility
	of the caller to make sure that the CRF_IN_FINAL_LIST is
	cleared before any recalculation takes place. This is usually
	done in the callback supplied to ForeachCellListEntry().
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateCellListFromChildList	proc	near
	uses	cx, dx, es, di
params	local	CreateCellListParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	;
	; Save the childList handle/offset.
	;
	mov	params.CCLP_childList, bx
	;
	; Allocate the ancestorList and the finalList.
	;
	push	bx			; Save end of child list 
	call	AllocAncestorList	; bx <- handle of ancestorList
	mov	params.CCLP_ancestorList, bx

	call	AllocFinalList		; bx <- handle of finalList
	mov	params.CCLP_finalList, bx
	pop	bx			; Restore end of child list

	mov	params.CCLP_flags, 0	; No circularities yet...
	
	mov	params.CCLP_count.high,0
	mov	params.CCLP_count.low, 0

moveLoop:
	;
	; Copy the entry from the temporary list to the cell list
	;
	; ss:bp = CreateCellListParams
	; bx	= Block at the end of the child list
	; ds:si	= Spreadsheet instance
	;
	; es:di - will be used as a cell data pointer
	; dl	- will be used to hold the cell flags
	; ax/cl - will hold the cell row/column
	; ch	- will hold the flags
	;
	
	;
	; Get the next child list entry.
	;
	call	PopCellListEntry	; ax/cx <- child list entry
					; bx updated
	jc	noMoreEntries		; Branch if no more entries

	;
	; Check for a marker. This indicates that we have no more children for
	; the cell on the parent list. We want to copy the cell on the parent
	; list onto the final list.
	;
	test	ch, mask CLEF_MARKER	; Check for found a marker
	jnz	copyToFinalList		; Branch to copy the cell

	;
	; The entry isn't a marker. We want to lock the cell and check the 
	; flags.
	;
	call	LockCell		; es:di <- cell ptr
	jnc	cellDoesNotExist	; Branch if cell doesn't exist

EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
	mov	dl, es:[di].CC_recalcFlags

	;
	; Check for the cell being an ancestor of itself. We figure this out
	; by finding out if the cell is already in the parent list.
	;
	test	dl, mask CRF_IN_PARENT_LIST
	jnz	markCircularities	; Branch if it's an ancestor of itself

	;
	; The cell isn't in the parent list. Check to see if it's in the
	; final list already. If it is then the entry in the final list is
	; "deeper" than the current entry so we can totally ignore this
	; entry.
	test	dl, mask CRF_IN_FINAL_LIST
	jnz	unlockAndLoop		; Branch if in final list already
	
	;
	; We want to add the cell to the ancestor list and mark it as being
	; in that list.
	;
	call	PushOnAncestorList	; Add it to the ancestor list

	or	es:[di].CC_recalcFlags, mask CRF_IN_PARENT_LIST
	
	mov	ch, mask CLEF_MARKER	; Push a marker...
	call	PushCellListEntry	; Onto the child list

	;
	; Now we add the descendants of the current entry.
	;
	call	params.CCLP_moreCallback
	
unlockAndLoop:
	call	UnlockAndDirtyCell	; Release the cell
	jmp	moveLoop		; Loop to process next cell

noMoreEntries:
	;
	; Now we need to free up the childList and the ancestorList
	; ds:si	= Spreadsheet instance
	;
	call	FreeAncestorList	; Free ancestor list
	call	FreeChildList		; Free child list
	
	;
	; We need to return the block/offset to the end of the list.
	;
	mov	bx, params.CCLP_finalList
	mov	al, params.CCLP_flags
	.leave
	ret


copyToFinalList:
	;
	; Copy the cell that was pop'd onto the final list.
	;
	call	PopFromAncestorList	; Remove cell from ancestor list
	
	;
	; Lock the cell and set the flags correctly.
	;
	call	LockCell		; es:di <- cell pointer
EC <	ERROR_NC CELL_DOES_NOT_EXIST			>

EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
	and	es:[di].CC_recalcFlags, not mask CRF_IN_PARENT_LIST
	or	es:[di].CC_recalcFlags, mask CRF_IN_FINAL_LIST
	
	;
	; Add the cell to the final-list and increment the count of entries on
	; that list.
	;
	call	PushOnFinalList		; Add cell to final list
	jmp	unlockAndLoop		; Branch to release the cell and loop


markCircularities:
	;
	; The cell is part of a circularity.
	;
	mov	params.CCLP_flags, mask CLEF_PART_CIRCULARITY
	call	MarkCircularities	; Mark the entries as circularities
	jmp	unlockAndLoop

cellDoesNotExist:
	;
	; The cell doesn't exist. This can only happen if the cell is part
	; of the root of the final list. In that case, just move the cell
	; over to the finalList. We don't need to worry about running into
	; it again since it's at the root and doesn't really exist...
	;
	call	PushOnFinalList		; Move it to the final list
	jmp	moveLoop		; Loop to do the next one

CreateCellListFromChildList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a cell (it must exist).

CALLED BY:	CreateCellListFromChildList
PASS:		ax	= Row
		cl	= Column
		ds:si	= ptr to CellFunctionParameters
RETURN:		carry set if the cell exists
		es:di	= Pointer to the cell data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCell	proc	near
	uses	cx
	.enter
	;
	; The parameter block holds the spreadsheet instance.
	;
	clr	ch				; cx <- column
	SpreadsheetCellLock			; *es:di <- cell data
	jnc	quit				; Branch if cell doesn't exist
	mov	di, es:[di]			; es:di <- ptr to cell data
quit:
	.leave
	ret
LockCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockAndDirtyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the cell and dirty it.

CALLED BY:	CreateCellListFromChildList
PASS:		es	= Segment address of the cell data
		ds:si	= ptr to CellFunctionParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockAndDirtyCell	proc	near
	.enter
	;
	; The parameter block holds the spreadsheet instance.
	;
	SpreadsheetCellDirty			; Dirty the cell
	SpreadsheetCellUnlock			; Unlock the cell
	.leave
	ret
UnlockAndDirtyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushOnAncestorList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a cell (and flags) onto the ancestor list

CALLED BY:	CreateCellListFromChildList
PASS:		ss:bp	= Pointer to inheritable CreateCellListParams
		ax	= Row
		cl	= Column
		ch	= Flags
RETURN:		CCLP_ancestorList updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushOnAncestorList	proc	near
	uses	bx
params	local	CreateCellListParams
	.enter	inherit
	mov	bx, params.CCLP_ancestorList
	
	call	PushCellListEntry		; Push the entry
	
	mov	params.CCLP_ancestorList, bx
	.leave
	ret
PushOnAncestorList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopFromAncestorList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop a cell (and flags) from the ancestor list

CALLED BY:	CreateCellListFromChildList
PASS:		ss:bp	= Pointer to inheritable CreateCellListParams
RETURN:		ax	= Row
		cl	= Column
		ch	= Flags
		CCLP_ancestorList updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopFromAncestorList	proc	near
	uses	bx
params	local	CreateCellListParams
	.enter	inherit
	mov	bx, params.CCLP_ancestorList
	
	call	PopCellListEntry		; Pop the entry
	
	mov	params.CCLP_ancestorList, bx
	.leave
	ret
PopFromAncestorList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushOnFinalList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a cell (and flags) onto the final list

CALLED BY:	CreateCellListFromChildList
PASS:		ss:bp	= Pointer to inheritable CreateCellListParams
		ax	= Row
		cl	= Column
		ch	= Flags
RETURN:		CCLP_finalList, CCLP_count updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushOnFinalList	proc	near
	uses	bx
params	local	CreateCellListParams
	.enter	inherit
	mov	bx, params.CCLP_finalList
	
	call	PushCellListEntry		; Push the entry
	
	mov	params.CCLP_finalList, bx

	;
	; Increment the count of cells in the final list. This is a dword
	; value.
	;
	inc	params.CCLP_count.low	; One more cell on final list
	jnz	quit			; Branch if low word is zero
	inc	params.CCLP_count.high
quit:
	.leave
	ret
PushOnFinalList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkCircularities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark entries in the ancestor list as being part of a
		circularity.

CALLED BY:	CreateCellListFromChildList
PASS:		ss:bp	= Inheritable CreateCellListParams
		ax	= Row of cell that is a circularity
		cl	= Column of cell that is a circularity
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	list = Lock( parentList )
    loop:
	list.offset.flags |= mask CLEF_PART_CIRCULARITY
	if (list.offset.row != row || list.offset.column != column) then
	    PreviousEntry( list, offset )
	    goto loop
	endif

	Unlock( list )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkCircularities	proc	near
	uses	bx, si, ds
params	local	CreateCellListParams
	.enter	inherit
	;
	; Lock down the end of the ancestor list
	;
	push	ax			; Save row
	mov	bx, params.CCLP_ancestorList
	call	MemLock			; Lock the ancestor list
	mov	ds, ax			; ds <- seg address of ancestor list
	pop	ax			; Restore row

	mov	si, ds:CLH_endOfData	; ds:si <- ptr past end of block
	sub	si, size CellListEntry	; ds:si <- ptr to last entry
markLoop:
	;
	; ds:si = Last ancestor list entry
	; bx	= Block handle of ds
	;
EC <	call	ECCheckPointer			>
	or	ds:[si].CLE_flags, mask CLEF_PART_CIRCULARITY
	
	cmp	ds:[si].CLE_row, ax	; Check for same row
	jne	prevEntry		; Branch if not same row
	cmp	ds:[si].CLE_column, cl	; Check for same column
	je	done			; Branch if we've marked the loop
prevEntry:
	call	PreviousEntry		; Move to the previous entry
	jmp	markLoop		; Loop to process it

done:
	call	MemUnlock		; Release the list
	.leave
	ret
MarkCircularities	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocChildList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a list block for the childList.

CALLED BY:	ManualRecalcSetup, CreateCellList
PASS:		ds:si	= Spreadsheet instance
RETURN:		bx	= Block handle of first block of child list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocChildList	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_childList	; bx <- cached childList block
	call	CheckAndAllocListBlock		; bx <- block to use
	mov	ds:[si].SSI_childList, bx	; Save block to use
	ret
AllocChildList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocAncestorList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a list block for the ancestorList

CALLED BY:	CreateCellListFromChildList
PASS:		ds:si	= Spreadsheet instance
RETURN:		bx	= Block handle of first block of ancestor list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocAncestorList	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_ancestorList	; bx <- cached ancestorList block
	call	CheckAndAllocListBlock		; bx <- block to use
	mov	ds:[si].SSI_ancestorList, bx	; Save block to use
	ret
AllocAncestorList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocFinalList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a list block for the finalList

CALLED BY:	CreateCellListFromChildList
PASS:		ds:si	= Spreadsheet instance
RETURN:		bx	= Block handle of first block of final list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocFinalList	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_finalList	; bx <- cached finalList block
	call	CheckAndAllocListBlock		; bx <- block to use
	mov	ds:[si].SSI_finalList, bx	; Save block to use
	ret
AllocFinalList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAndAllocListBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check on a cached block and allocate a new one if the old
		one is discarded (or never existed).

CALLED BY:	AllocChildList, AllocAncestorList, AllocFinalList
PASS:		bx	= Cached block handle
RETURN:		bx	= Block handle to use
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAndAllocListBlock	proc	near
	uses	ax
	.enter
	tst	bx				; Check for cached block
	jz	noHandle			; Branch if there is no block

	;
	; We have a handle, but that doesn't mean that the block still
	; exists. It might have been discarded. The only good way to tell
	; is to call MemLock.
	;
	call	MemLock				; ax <- segment address
	jc	discarded			; Branch if block is discarded
	
	;
	; The block exists and we have it locked. We want to make it 
	; non-discardable before we unlock it.
	;
	clr	al				; No bits to set
	mov	ah, mask HF_DISCARDABLE		; Bits to clear
	call	MemModifyFlags			; Change the flags

	call	MemUnlock			; Release the block
quit:
	.leave
	ret

discarded:
	;
	; The handle exists but the block is discarded. Free up this handle
	; and fall thru to allocate a new one.
	;
	call	MemFree				; Free old handle
	;;; Fall thru

noHandle:
	;
	; There was no block, make one and cache it.
	;
	call	AllocEmptyCellList		; bx <- new list
	jmp	quit				; Branch, we have the block
CheckAndAllocListBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocEmptyCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an empty cell list

CALLED BY:	CreateCellList, CreateCellListFromChildList
PASS:		nothing
RETURN:		bx	= Block handle of the new cell list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocEmptyCellList	proc	near
	uses	ax, cx, ds
	.enter
	mov	ax, size CellListHeader	; ax <- size
	add	ax, CELL_LIST_INCREMENT	; Add size for many entries
	
	mov	cl, mask HF_SWAPABLE
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemAlloc		; bx <- block handle
					; ax <- segment address of the block
	mov	ds, ax			; ds <- segment address
	
	mov	ds:CLH_blockSize, size CellListHeader + CELL_LIST_INCREMENT
	mov	ds:CLH_endOfData, size CellListHeader
	mov	ds:CLH_prev, 0		; No previous block
	mov	ds:CLH_next, 0		; No next block
	
	call	MemUnlock		; Release the block
	.leave
	ret
AllocEmptyCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushCellListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a CellListEntry to the end of a cell list

CALLED BY:	CreateCellList
PASS:		bx	= Last block of list to add to
		ax	= Row
		cl	= Column
		ch	= Flags
RETURN:		bx	= Last block of list we added to
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushCellListEntry	proc	near
	uses	ds
	.enter
	push	ax			; Save the row
	call	MemLock			; Lock the recalc list
	mov	ds, ax			; ds:si <- ptr to list
	pop	ax			; Restore the row
	
	call	PushCellListLocked	; Push the cell

	call	MemUnlock		; Release the block
	.leave
	ret
PushCellListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushCellListLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a cell to a list that is already locked.

CALLED BY:	PushCellListEntry
PASS:		ds	= Segment address of the block
		bx	= Handle of the block
		ax	= Row
		cl	= Column
		ch	= Flags
RETURN:		ds	= New address of the block
		bx	= New handle of the block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushCellListLocked	proc	near
	uses	si
	.enter
EC <	call	ECCheckCellListHeader			>

	mov	si, ds:CLH_endOfData	; si <- offset past end of data

	cmp	si, ds:CLH_blockSize	; Check for past end of block
	jb	gotPointer		; Branch if not past end
	
	;
	; The pointer is past the end of the block, we need to make the block
	; bigger if that's possible.
	;
	cmp	si, MAX_CELL_LIST_BLOCK_SIZE
	jbe	extendBlock
	
	;
	; The block is already too large, we need to actually extend the
	; list by adding a new block.
	;
	push	ax, cx			; Save row, column, flags
	mov	cx, bx			; cx <- current cell list block
	call	AllocEmptyCellList	; bx <- new cell list block
	
	;
	; Now link the old block and new blocks together.
	; bx	= Handle of the new block
	; cx	= Handle of the old block
	; ds	= Segment address of the old block
	;
	mov	ds:CLH_next, bx		; Save link to next block
	
	xchg	bx, cx			; bx <- old block, cx <- new block
	call	MemUnlock		; Release the current block

	xchg	bx, cx			; bx <- new block, cx <- old block
	call	MemLock			; ax <- segment address of new block
	mov	ds, ax			; ds <- segment address of new block
	
	mov	ds:CLH_prev, cx		; Save link to previous block
	
	mov	si, size CellListHeader	; si <- offset to insert at
	pop	ax, cx			; Restore row, column, flags
	
	jmp	gotPointer		; Branch to add data

extendBlock:
	;
	; Extend the block by realloc'ing it larger.
	; bx	= Block handle
	; si	= Size of the block
	; ds	= Segment address of the block
	;
	push	ax, cx			; Save row, column, flags
	mov	ax, si			; ax <- old size
	add	ax, CELL_LIST_INCREMENT	; ax <- new size
	mov	ch, mask HAF_NO_ERR	; Just do it
	call	MemReAlloc		; ax <- new segment address
	mov	ds, ax			; ds <- new segment address

	add	ds:CLH_blockSize, CELL_LIST_INCREMENT
	pop	ax, cx			; Restore row, column, flags

gotPointer:
	;
	; We have a pointer to the place to put the data.
	;
	; ds:si	= Pointer to place to put the result
	; bx	= Block handle
	; ax	= Row
	; cl	= Column
	; ch	= Flags
	;
EC <	call	ECCheckCellListHeader		>
EC <	call	ECCheckPointer			>

	mov	ds:[si].CLE_row, ax
	mov	ds:[si].CLE_column, cl
	mov	ds:[si].CLE_flags, ch
	
	add	si, size CellListEntry	; Advance the pointer

	mov	ds:CLH_endOfData, si
	.leave
	ret
PushCellListLocked	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopCellListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop a cell list entry from a cell list.

CALLED BY:	MoveCellListEntry
PASS:		bx	= Block handle of the last block in the list
RETURN:		carry set if there are no entries to pop, clear otherwise
		bx	= Block handle of the last block in the list
		ax	= Row
		cl	= Column
		ch	= Flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopCellListEntry	proc	near
	uses	ds, si
	.enter
	call	MemLock			; Lock the block
	mov	ds, ax			; ds <- segment address of list
	mov	si, ds:CLH_endOfData	; ds:si <- ptr past the entry

EC <	call	ECCheckCellListHeader			>

	cmp	si, size CellListHeader	; Check for at start of block
	ja	gotPointer		; Branch if we have entries to get
	
	;
	; We are at the start of a block. We need to get the previous block.
	;
	mov	ax, ds:CLH_prev		; ax <- previous block
	
	;
	; Check for no previous block
	;
	tst	ax			; If no previous block
	jz	quitNoMoreEntries	; Branch if no more

	;
	; There are more entries in the previous block.
	;
	call	MemFree			; Free the current block (locked)
	
	mov	bx, ax			; bx <- block handle
	call	MemLock			; Lock the new block
	mov	ds, ax			; ds <- segment address of that block

	mov	ds:CLH_next, 0		; Nuke the "next" link
	mov	si, ds:CLH_blockSize	; ds:si <- ptr past the last entry

gotPointer:
	;
	; ds:si = Pointer past the entry to get
	;
	sub	si, size CellListEntry
	mov	ds:CLH_endOfData, si

EC <	call	ECCheckPointer				>

	mov	ax, ds:[si].CLE_row	; ax <- row
	mov	cl, ds:[si].CLE_column	; cl <- column
	mov	ch, ds:[si].CLE_flags	; ch <- flags
	
	clc				; Signal: Got an entry

quit:
	;
	; bx = block handle of the block to unlock.
	; carry set correctly for return.
	;
	call	MemUnlock		; Release the block
	.leave
	ret

quitNoMoreEntries:
	stc				; Signal: no more entries
	jmp	quit			; Branch to unlock the block
PopCellListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendDependentsToCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append the dependencies for a cell to a list

CALLED BY:	CreateCellListFromChildList
PASS:		ax/cl	= Cell
		es:di	= Cell pointer
		bx	= Block handle of the last list block
		ds:si	= Pointer to spreadsheet instance
RETURN:		bx	= Block handle of last block in the list
		si	= Offset to end of the list block
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDepsParams	struct
    ADP_block	word			; The block to add to
AddDepsParams	ends

AppendDependentsToCellList	proc	near
	uses	ax, cx, es, di
params	local	AddDepsParams
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Save the block/offset to pass on the stack to the callback routine.
	;
	mov	params.ADP_block, bx	; Save the current block

	mov	ax, offset cs:AddDepsCallback
	
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Pointer to the cell data
	; ax	= Callback
	; bp	= Pointer to parameters: block/offset
	;
	call	ForeachDependency
	
	mov	bx, params.ADP_block	; bx <- block to return
	.leave
	ret
AppendDependentsToCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendNameDependentsToCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append the dependencies for a name cell to a list

CALLED BY:	CreateCellListFromChildList
PASS:		ax/cl	= Cell
		bx	= Block handle of the last list block
		ds:si	= Pointer to spreadsheet instance
RETURN:		bx	= Block handle of last block in the list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendNameDependentsToCellList	proc	near
EC <	call	ECCheckInstancePtr		;>
	cmp	ax, NAME_ROW		; Check for cell is a name
	jne	quit			; Branch if it isn't
	
	;
	; It's a name, add the dependents.
	;
	call	AppendDependentsToCellList
quit:
	ret
AppendNameDependentsToCellList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDepsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single dependency to a list.

CALLED BY:	AppendDependentsToCellList via ForeachDependency
PASS:		dx	= Row of the cell
		cx	= Column of the cell
		*es:bx	= Pointer to dependeny list block
		di	= Offset into the block for this entry
RETURN:		carry clear always
		params.ADP_block updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Remember, entries are added last to first. The first call to this
	routine is for the last dependent. The last call to this routine is
	for the first dependent.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDepsCallback	proc	near
	uses	ax, bx, cx, si
params	local	AddDepsParams
	.enter	inherit
	clr	ch			; No flags
					; cl holds the column
	mov	ax, dx			; ax <- row

	mov	bx, params.ADP_block	; bx <- block
	call	PushCellListEntry	; Add the entry
	mov	params.ADP_block, bx	; Save new block
	
	clc				; Signal: continue processing
	.leave
	ret
AddDepsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendNamePrecedentsToCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append the name precedents for a cell to a list

CALLED BY:	CreateCellListFromChildList
PASS:		ax/cl	= Cell
		bx	= Block handle of the last list block
		ds:si	= Pointer to spreadsheet instance
RETURN:		bx	= Block handle of last block in the list
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendNamePrecedentsToCellList	proc	near
	uses	ax, cx, di, bp, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	clr	ch			; cx <- Column
	
	;
	; Create the stack frame for making the precedents list.
	;
	push	bx			; Save block handle of list block
	sub	sp, size PCT_vars	; Make space to create precedents list
	mov	bp, sp			; ss:bp <- ptr to frame
	call	SpreadsheetInitCommonParams
	
	;
	; We want all precedents.
	;
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES or \
				  mask EF_ONLY_NAMES
	call	CreatePrecedentList	; bx <- handle of precedents list
	
	lahf				; Save "no precedents" flag (carry)
	add	sp, size PCT_vars	; Restore the stack frame
	sahf				; Restore "no precedents" flag (carry)

	pop	bp			; Restore block handle
	
	;
	; Carry is set if there is a precedents list.
	;
	jnc	quit			; Quit if no precedents list
	
	;
	; Take the precedents list and add the entries to the temporary list.
	; ds:si	= Spreadsheet instance
	;
	; bp	= Block handle of the cell list
	; dx	= Offset into the cell list block
	;
	; bx	= Block handle of the precedents list (all entries are names)
	;
	push	bx			; Save block handle
	call	MemLock			; ds <- segment address of precedents
	mov	ds, ax
	
	mov	di, size DependencyBlock; ds:di <- ptr to dependency block
	
	mov	bx, bp			; bx <- block handle of cell list
	
	;
	; Find a name entry (anywhere).
	;
	sub	di, size EvalRangeData+1; ds:di <- offset to previous item
					;  (actually there isn't one, but this
					;   works for NextNameEntry()).
	call	NextNameEntry		; di <- next name entry
	jc	endLoop			; Branch if no more names

findNextName:
	;
	; bx	= Block.offset of temporary list
	; ds:di	= Pointer to current entry in the precedents list
	;
	mov	ax, NAME_ROW		; ax/cl = Row/column
	mov	cl, {byte} ds:[di+1].END_name
	clr	ch			; No flags
	
	call	NextNameEntry		; ds:di <- next name entry
	pushf				; Save "no more names" flag
	;
	; ax	= Row
	; cl	= Column
	; ch	= Flags for this entry
	; bx	= Block.offset into the cell list
	; ds:di	= Pointer to next name entry in the precedents list
	;
	call	PushCellListEntry	; Put the entry on the cell list

	popf				; Restore "no more names" flag
	jnc	findNextName		; Loop to process it

endLoop:
	mov	bp, bx			; bp <- block handle
	;
	; We're all done adding the entries. Clean up and escape.
	;
	pop	bx			; bx <- precedents list
	call	MemFree			; Free up the precedents list (locked)
	
quit:
	mov	bx, bp			; bx <- block to return
	.leave
	ret
AppendNamePrecedentsToCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NextNameEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next name entry.

CALLED BY:	AppendNamePrecedentsToCellList
PASS:		ds:di	= Pointer to current list entry.
RETURN:		ds:di	= Pointer to next entry that is a name
		carry set if there are no more entries
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NextNameEntry	proc	near
	uses	ax
	.enter
nextLoop:
	add	di, size EvalRangeData+1; Move to next entry
	
	cmp	di, ds:DB_size		; Check for past the end
	je	noMoreNames		; Branch if no more names

	mov	al, {byte} ds:[di]
	and	al, ESAT_NAME
	
	cmp	al, ESAT_NAME		; Check for found a name
	jne	nextLoop		; Branch if not a name

	;
	; Carry is clear here because the "equal" condition was met.
	;
quit:
	.leave
	ret

noMoreNames:
	stc				; Signal: No more names
	jmp	quit
NextNameEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNamePrecedentsListForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a name precedents list for the current selection.

CALLED BY:	
PASS:		ds:si	= Spreadsheet instance
RETURN:		bx	= Block handle containing the name info for all names
			  referenced directly or otherwise by the cells in the
			  curent selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateNamePrecedentsListForSelectionFar	proc	far
	call	CreateNamePrecedentsListForSelection
	ret
CreateNamePrecedentsListForSelectionFar	endp

CreateNamePrecedentsListForSelection	proc	near
	class	SpreadsheetClass
	uses	ax
localVars	local	ManualRecalcVars
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	localVars.MRV_rangeParams.REP_bounds.R_top, ax
	
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	localVars.MRV_rangeParams.REP_bounds.R_bottom, ax
	
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	localVars.MRV_rangeParams.REP_bounds.R_left, ax
	
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	mov	localVars.MRV_rangeParams.REP_bounds.R_right, ax

	call	CreateNamePrecedentsList
	.leave
	ret
CreateNamePrecedentsListForSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNamePrecedentsList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a list of all the names which are precedents of the
		cells in a given range.

CALLED BY:	CreateNamePrecedentsListForSelection
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable ManualRecalcVars with:
				MRV_rangeParams.REP_bounds set
RETURN:		bx	= Block handle containing the name info for all names
			  referenced directly or otherwise by the cells in the
			  range.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNamePrecedentsList	proc	near
	uses	ax, cx
localVars	local	ManualRecalcVars
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	push	bp			; Save frame ptr
	;
	; Setup the stack frame.
	;
	call	ManualRecalcSetup	; Setup the stack frame

	;
	; Now create the cell list.
	;
	; bp	= Local variables
	; ds:si	= Spreadsheet instance
	;
	mov	bx, localVars.MRV_tempListBlock
	
	;
	; Create stack frame.
	;
	push	bp			; Save frame ptr
	sub	sp, size CreateCellListParams
	mov	bp, sp			; ss:bp <- ptr to parameters

	;
	; Initialize it.
	;
	mov	ss:[bp].CCLP_moreCallback, \
					offset cs:AppendNamePrecedentsToCellList
	;
	; Set ss:bp to point at the top of it.
	;
	add	bp, size CreateCellListParams

	call	CreateCellListFromChildList
					; bx <- end of cell list

	mov	sp, bp			; Restore stack
	pop	bp			; Restore frame ptr
	
	;
	; Now process the entries.
	;
	mov	ax, offset cs:CreateNameListCallback

	clr	bp			; bp <- block handle of name list
	call	ForeachCellListEntry
	
	;
	; Free up the cell list and leave.
	;
	call	FreeFinalList		; Free up the cell list
	
	mov	bx, bp			; bx <- block handle of name list
	pop	bp			; Restore frame ptr
	.leave
	ret
CreateNamePrecedentsList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNameListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for each entry in the name cell list

CALLED BY:	CreateNamePrecedentsList via ForeachCellListEntry
PASS:		dx	= Row
		cl	= Column
		ch	= Flags
		ds:si	= Spreadsheet instance
		bp	= Block handle of the name list block
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNameListCallback	proc	near
	.enter
EC <	call	ECCheckInstancePtr		;>
	cmp	dx, NAME_ROW		; Check for name entry
	jne	quit			; Branch if not a name
	
	;
	; Not only is it a name, but it's an original name.
	;
	call	AddNameToNameList	; Add the name
quit:
	;
	; CreateCellListFromChildList() has marked the cell with
	; CRF_IN_FINAL_LIST.  Normally, this is cleared during recalculation,
	; but since this routine is not for generating a recalculation list,
	; the flag will never be cleared.  So we do it here, because leaving
	; the flag set is a bad thing.
	;
	push	ax, es, di
	mov	ax, dx			; ax <- row #
	call	LockCell
EC <	ERROR_NC	CELL_DOES_NOT_EXIST	>
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
if _PROTECT_CELL
	;
	; For cell protection, we don't want to clear the protection bit.
	;
	andnf	es:[di].CC_recalcFlags, (not (mask CellRecalcFlags)) or mask CRF_PROTECTION
else
	andnf	es:[di].CC_recalcFlags, (not (mask CellRecalcFlags)) or mask CRF_RESERVED
endif
	call	UnlockAndDirtyCell
	pop	ax, es, di
	clc				; Signal: Continue
	.leave
	ret
CreateNameListCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNameToNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a name to the name list

CALLED BY:	CreateNameListCallback
PASS:		bp	= Block handle of the name list (0 for none)
		cl	= Column of the name
		ds:si	= Spreadsheet instance
RETURN:		bp	= Block handle of the name list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNameToNameList	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, bp			; bx <- block handle of name list
	;
	; Allocate a stack frame and get the information we need.
	;
	sub	sp, size SpreadsheetNameParameters
	mov	bp, sp			; ss:bp <- frame ptr
	
	mov	ss:[bp].SNP_flags, mask NAF_NAME or \
				   mask NAF_DEFINITION or \
				   mask NAF_BY_TOKEN or \
				   mask NAF_TOKEN_DEFINITION
	clr	ch			; cx <- entry
	mov	ss:[bp].SNP_listEntry, cx

	mov	dx, cx			; dx <- token

	push	bp, bx, dx		; Save frame ptr, block handle, token
	mov	dx, ss
	mov	di, si			; ds:di <- ptr to spreadsheet instance
	call	SpreadsheetGetNameInfo	; Destroys everything
	pop	bp, bx, dx		; Restore frame ptr, block handle, token

	;
	; Now that we have the information we need, figure out how large it
	; all is.
	;
	mov	cx, ss:[bp].SNP_textLength
DBCS<	shl	cx, 1			; cx <- size of name	  	>
	add	cx, ss:[bp].SNP_defLength
	add	cx, size NameListEntry	; cx <- total new size needed

	tst	bx			; Check for no name list yet
	jz	makeNameList		; Branch if there is none

gotNameList:
	;
	; We've got the name list, check for enough space in the block.
	; bx	= Block handle of the name list
	; cx	= Additional space we need (size)
	; dx	= Token
	;
	call	MemLock			; ds <- segment address of the bloc
	mov	ds, ax
	
	mov	si, ds:NLH_endOfData	; ds:si <- ptr to end of the block
	
	add	cx, si			; cx <- offset after adding the data
	
	cmp	cx, ds:NLH_blockSize	; Check for no space here
	jae	expandNameList		; Branch if no space

gotSpace:
	;
	; The block is large enough.
	;
	; bx	= Block handle of the name list block
	; cx	= Offset past end of data
	; dx	= Token
	; ds:si	= Pointer to place to put the data
	; ss:bp	= Pointer to SpreadsheetNameParameters
	;
	mov	ds:NLH_endOfData, cx	; Update end of data

	segmov	es, ds, di		; es:di <- ptr to the dest
	mov	di, si
	
	mov	ax, dx			; Save the token
	stosw

	mov	al, ss:[bp].SNP_nameFlags
	stosw				; Save the flags (*yes*, as a word)

	mov	ax, ss:[bp].SNP_textLength
	stosw				; Save the text length

	mov	ax, ss:[bp].SNP_defLength
	stosw				; Save the definition length

	;
	; Copy the text.
	;
	segmov	ds, ss, si		; ds:si <- ptr to source
	lea	si, ss:[bp].SNP_text
	
	mov	cx, ss:[bp].SNP_textLength
	
	LocalCopyNString		; Copy the text of the name
	
	;
	; Copy the definition.
	;
	lea	si, ss:[bp].SNP_definition
	mov	cx, ss:[bp].SNP_defLength
	
	rep	movsb	  		; Copy the definition (bytes)
	
	;
	; Release the name list block and cleanup.
	;
	call	MemUnlock		; Release the name list block
	add	sp, size SpreadsheetNameParameters
	
	mov	bp, bx			; Return block handle in bp
	.leave
	ret

makeNameList:
	;
	; The name-list doesn't exist. Create one.
	;
	push	cx			; Save space for this name
	mov	ax, size NameListHeader + NAME_LIST_INCREMENT
	clr	cl
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
	call	MemAlloc		; bx <- block handle
	mov	ds, ax
	
	mov	ds:NLH_blockSize, size NameListHeader + NAME_LIST_INCREMENT
	mov	ds:NLH_endOfData, size NameListHeader
	
	call	MemUnlock		; Release the block
	pop	cx			; Restore space for this name
	jmp	gotNameList

expandNameList:
	;
	; cx = Offset to new end of the block
	;
	push	cx			; Save offset
	mov	ax, cx
	add	ax, NAME_LIST_INCREMENT
	
	mov	ch, mask HAF_NO_ERR	; Just do it
	call	MemReAlloc		; ax <- new segment address
	mov	ds, ax
	
	add	ds:NLH_blockSize, NAME_LIST_INCREMENT
	
	pop	cx			; Restore offset
	jmp	gotSpace
AddNameToNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePrecedentList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a list of precedents for a given cell.

CALLED BY:	CellAddRemoveDeps, AppendNamePrecedentsToCellList
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Initialized PCT_vars structure
			  EP_flags initialized
		ax	= Row
		cx	= Column
RETURN:		carry set if the cell has precedents
		bx	= Block handle of the locked precedents list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePrecedentList	proc	far
	uses	ax, cx, dx, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	SpreadsheetCellLock		; *es:di <- ptr to cell
	jnc	quitNoDependents	; Quit if no cell definition

	mov	di, es:[di]		; es:di <- ptr to cell
	;
	; Make sure the cell is a formula. If it's not, just quit.
	;
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
	cmp	es:[di].CC_type, CT_DISPLAY_FORMULA
	je	hasPrecedents		; Branch if is a display formula

	cmp	es:[di].CC_type, CT_CHART
	je	hasPrecedents

	cmp	es:[di].CC_type, CT_FORMULA
	jne	unlockNoDependents	; Branch if not a formula

hasPrecedents:
	;
	; The cell is a formula of some type, so it does have precedents.
	;
	add	di, CF_formula		; es:di <- ptr to the formula

	;
	; First generate dependencies.
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Pointer to cell formula
	;
	push	ds, si, es		; Save instance ptr, segment of cell
	segmov	ds, es, ax		; ds:si <- ptr to formula
	mov	si, di

	segmov	es, ss, ax		; es:di <- ptr to eval scratch buffer
	lea	di, ss:[bp].PCTV_evalBuffer
	mov	cx, PARSE_TEXT_BUFFER_SIZE
	call	ParserEvalExpression		; Make a dependency block
	ERROR_C	UNABLE_TO_CREATE_PRECEDENTS_LIST
	pop	ds, si, es		; Restore instance ptr, segment of cell
	;
	; ds:si	= Spreadsheet instance
	; es	= Segment address of the cell data
	;
	SpreadsheetCellUnlock		; Unlock the cell data
	;
	; There was no error.
	; EP_depHandle holds the block handle of the dependencies.
	;
	mov	bx, ss:[bp].EP_depHandle
	tst	bx			; Check for no dependencies
	jz	quitNoDependents	; Branch if none

	stc				; Signal: has dependents
quit:
	.leave
	ret

unlockNoDependents:
	;
	; The cell isn't a formula so it can't generate any dependents.
	;
	SpreadsheetCellUnlock		; release the cell

quitNoDependents:
	clc				; Signal: no dependents
	jmp	quit			; Quit now.
CreatePrecedentList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeChildList, FreeAncestorList, FreeFinalList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up the child list.

CALLED BY:	CreateCellListFromChildList
PASS:		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeChildList	proc	near
	class	SpreadsheetClass
	uses	bx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_childList	; bx <- first child list block
	call	FreeCellList
	.leave
	ret
FreeChildList	endp

FreeAncestorList	proc	near
	class	SpreadsheetClass
	uses	bx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_ancestorList	; bx <- first ancestor list
	call	FreeCellList
	.leave
	ret
FreeAncestorList	endp

FreeFinalList	proc	near
	class	SpreadsheetClass
	uses	bx
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_finalList	; bx <- first final list
	call	FreeCellList
	.leave
	ret
FreeFinalList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a cell list

CALLED BY:	FreeChildList, FreeAncestorList, FreeFinalList
PASS:		bx	= First block handle of the block list.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellList	proc	near
	uses	ax, cx, dx, ds
	.enter
	mov	dx, bx			; dx <- first block in the list

	call	MemLock			; ax <- segment address of the list
	mov	ds, ax			; ds <- segment address of the list

	mov	cx, ds:CLH_next		; cx <- next block

	;
	; Set up the block so that if it doesn't get discarded we will
	; actually have something good to work with.
	; This means:
	;	no next block
	;	end of data is at start of block
	;
	mov	ds:CLH_next, 0		; No more next block
	mov	ds:CLH_endOfData, size CellListHeader

	call	MemUnlock		; Release the first block
	
blockLoop:
	;
	; cx = Next block to free up.
	;
	jcxz	done			; Branch if no more

	mov	bx, cx			; bx <- next block to free
	call	MemLock			; Lock the block
	mov	ds, ax			; ds <- segment address of the block

	mov	cx, ds:CLH_next		; cx <- next block

	call	MemFree			; free block (locked)
	jmp	blockLoop		; Loop to nuke the next one

done:
	;
	; dx = Block handle of the first block in the list
	;
	mov	bx, dx			; bx <- block handle
	mov	al, mask HF_DISCARDABLE	; Make it discardable
	clr	ah			; (no flags to clear)
	call	MemModifyFlags
	.leave
	ret
FreeCellList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachCellListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each entry in the cell list.

CALLED BY:	RecalcDependents
PASS:		ds:si	= Spreadsheet instance
		bx	= Block at the end of cell list
		ax	= Address of callback (near routine)
		bp	= Stack frame to pass to callback
RETURN:		carry set if callback aborted
		ax	= ax returned from callback
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    Callback definition should be:
	PASS:		dx	= Row
			cl	= Column
			ch	= Flags
			ds:si	= Spreadsheet instance
			ss:bp	= Passed stack frame
	RETURN:		carry set on error
			carry clear otherwise
	DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The list is processed in the reverse order (back to front).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachCellListEntry	proc	near
	uses	bx, cx, dx, es, di
	.enter
lockBlock:
	;
	; Get a pointer to the end of the cell list.
	;
	tst	bx			; Check for no block (clears carry)
	jz	quit			; Branch if no block

	push	ax			; Save callback
	call	MemLock			; ax <- segment address of block
	mov	es, ax			; es <- seg address of block
	mov	di, es:CLH_endOfData	; es:di <- ptr past data
	sub	di, size CellListEntry	; es:di <- ptr to last entry in block
	pop	ax			; Restore callback

entryLoop:
	;
	; We loop backwards...
	;
EC <	segxchg	ds, es			; ds <- seg addr of cell list	>
EC <	call	ECCheckCellListHeader					>
EC <	segxchg	ds, es			; Restore segments		>

	cmp	di, size CellListHeader	; Check for at start of the block
	jae	gotEntry		; Branch if not past end
	
	;
	; There are no more entries in this block. Release it and move to the
	; previous block.
	;
	mov	cx, es:CLH_prev		; cx <- previous block
	call	MemUnlock		; Release this block
	
	mov	bx, cx			; bx <- previous block
	jmp	lockBlock		; Branch to lock and handle it
	

gotEntry:
	;
	; We have an entry.
	; es:di	= Pointer to the entry
	; ds:si	= Spreadsheet instance
	; ss:bp	= Frame ptr
	; ax	= Callback
	; bx	= Block handle of current list block
	;
EC <	call	ECCheckPointerESDI			>
	mov	dx, es:[di].CLE_row	; dx <- row
	mov	cl, es:[di].CLE_column	; cl <- column
	mov	ch, es:[di].CLE_flags	; ch <- flags
	
	push	ax			; Save callback address

	call	ax			; Call the callback
	jc	abort			; Branch if callback aborted
	
	pop	ax			; Restore callback address

	sub	di, size CellListEntry	; Move to the next entry
	jmp	entryLoop		; Loop to handle it

quit:
	.leave
	ret

abort:
	;
	; Callback aborted. Unlock the current block.
	; The callback address is still on the stack
	;
	pop	cx			; Discard word from the stack
					; Preserve ax, it gets returned

	call	MemUnlock		; Release block (doesn't change flags)
	jmp	quit			; Branch to finish up.
ForeachCellListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreviousEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the previous entry in the cell list.

CALLED BY:	FindParentGotChildListLocked
PASS:		bx	= Block handle of the current entry
		ds	= Segment address of the current entry
		si	= Offset to the current entry
RETURN:		carry set if there is a previous entry
		bx	= Block handle of the previous entry
		ds	= Segment address of the previous entry
		si	= Offset to previous entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreviousEntry	proc	near
	uses	ax
	.enter
	;
	; Check to make sure the block header is intact and that the pointer
	; is valid.
	;
EC <	call	ECCheckCellListHeader			>
EC <	call	ECCheckPointer				>

	cmp	si, size CellListHeader		; Check for at start of block
	jne	gotPointer			; Branch if not at start
	;
	; We're at the start of a block. We need to lock the previous one.
	;
	mov	ax, ds:CLH_prev			; ax <-  previous block handle
	tst	ax				; Check for no previous block
						; Clears the carry
	jz	quit				; Branch if none

	call	MemUnlock			; Release the current block
	
	mov	bx, ax				; bx <- previous block
	call	MemLock				; ax <- segment address of block
	mov	ds, ax				; ds <- segment address of block
	
	mov	si, ds:CLH_endOfData		; ds:si <- ptr past end of data

gotPointer:
	sub	si, size CellListEntry		; Move to previous entry
	
	stc					; Signal: Has previous entry
quit:
	.leave
	ret
PreviousEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNameDependents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the dependents of a name.

CALLED BY:	AddRemoveCellDependencies
PASS:		ss:bp	= PCT_vars
		ax	= Row of the name
		cx	= Column of the name
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	Parts of the stack frame

PSEUDO CODE/STRATEGY:
	- Create a cell list containing the recalc tree rooted at the modified
	  name whose internal nodes are all names and whose leaves are all
	  cells.

	- For each cell (non name) in the cell list:
		Update the dependency lists of that cell

	- Free the cell list
	- Fixup the stack frame

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNameDependents	proc	near
	uses	ax, bx, dx
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Create the cell list using our callback as a filter.
	;
	mov	bx, offset cs:AppendNameDependentsToCellList
	call	CreateCellList			; bx <- end of cell list
	
	;
	; Process each cell in the cell list
	;
	mov	ax, offset cs:UpdateNameCallback
	call	ForeachCellListEntry		; Process the cell list
	
	;
	; Free up the cell list and fix up the stack frame.
	;
	call	FreeFinalList			; Free the cell list
	.leave
	ret
UpdateNameDependents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNameCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for processing the cell list.

CALLED BY:	UpdateNameDependents via ForeachCellListEntry
PASS:		dx	= Row
		cl	= Column
		ch	= Flags
		ds:si	= Spreadsheet instance
		ss:bp	= PCT_vars structure on the stack
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNameCallback	proc	near
	uses	ax, cx, dx, es, di
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	ax, dx			; ax <- row
	clr	ch			; cx <- column
	;
	; We only update the dependents for non-name cells.
	;
	cmp	ax, NAME_ROW		; Check for name
	je	clearBits		; Branch if it's a name cell
	
	;
	; It's a real cell. We want to add/remove the dependencies.
	;
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES or mask EF_NO_NAMES
	mov	ss:[bp].CP_row, ax	; Update stack frame
	mov	ss:[bp].CP_column, cx
	mov	ss:[bp].PCTV_row, dx
	mov	ss:[bp].PCTV_column, cx
	
	mov	dx, ss:[bp].PCTV_addRem	; dx <- parameter for CellAddRemoveDeps
	call	CellAddRemoveDeps	; Add or remove dependencies
clearBits:
	;
	; Now we need to clear the bits in the cell which signal it as part
	; of the final recalc list.
	;
	SpreadsheetCellLock		; *es:di <- cell data
	jnc	quit			; Branch if cell doesn't exist

	mov	di, es:[di]		; es:di <- cell data
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
if _PROTECT_CELL
	;
	; For cell protection, we don't want to clear the protection bit
	;
	andnf	es:[di].CC_recalcFlags, mask CRF_PROTECTION
else
	;
	; Don't change the reserved bit.
	;
	andnf	es:[di].CC_recalcFlags, mask CRF_RESERVED
endif
	call	UnlockAndDirtyCell	; unlock and dirty the cell
quit:	
	clc				; Signal: continue
	.leave
	ret
UpdateNameCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceNameReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update cells that refer to one name token so that they refer
		to another.

CALLED BY:	SpreadsheetChangeName
PASS:		ds:si	= Instance ptr
		dx	= Old token
		ax	= New token
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	list = CreatePrecedentList( instance, NAME_ROW, oldToken )
	foreach list entry do
	    ParserRemoveDependencies()
	    Modify name references from oldToken -> newToken
	    ParserAddDependencies()
	done
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceNameParams	struct
    RNP_oldToken	word		; Token to replace
    RNP_newToken	word		; Value to replace with
ReplaceNameParams	ends

ReplaceNameReferences	proc	near
	uses	ax, bx, cx, dx, bp
params	local	ReplaceNameParams
	.enter
EC <	call	ECCheckInstancePtr		;>
	;
	; Initialize the parameters.
	;
	mov	params.RNP_newToken, ax
	mov	params.RNP_oldToken, dx

	;
	; Build a list of cells which reference the old name token.
	;
	mov	ax, NAME_ROW		; ax <- Row
	mov	cx, dx			; cx <- Column
	mov	bx, offset cs:AppendDependentsToCellList
	call	CreateCellList		; bx <- end of cell list
					; al <- cumulative CellListEntryFlags
	;
	; Now process each cell list entry.
	;
	mov	ax, offset cs:ReplaceNameReferencesCallback
	call	ForeachCellListEntry	; Process the list
	
	call	FreeFinalList		; Free up the list
	.leave
	ret
ReplaceNameReferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceNameReferencesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace one name reference with another.

CALLED BY:	ForeachCellListEntry
PASS:		dx	= Row of the cell to update
		cl	= Column
		ch	= Flags
		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable ReplaceNameParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceNameReferencesCallback	proc	near
	uses	ax, cx, dx, di, es
params	local	ReplaceNameParams
	ForceRef params
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	ax, dx			; ax <- row
	clr	ch			; cx <- Column
	
	push	ax, cx			; Save row/column
	;
	; First remove the old dependencies
	;
	mov	dx, -1			; Remove dependencies
	call	UpdateDependenciesFromCell

	;
	; Lock the cell down... It must exist.
	;
	SpreadsheetCellLock		; *es:di <- cell data
EC <	ERROR_NC CELL_DOES_NOT_EXIST	; The cell must exist	>
	mov	di, es:[di]		; es:di <- ptr to cell

	;
	; The type must be one of CT_FORMULA or CT_DISPLAY_FORMULA
	;
EC <	test	es:[di].CC_recalcFlags, not (mask CellRecalcFlags) >
EC <	ERROR_NZ SPREADSHEET_ILLEGAL_RECALC_FLAGS_IN_CELL >
EC <	cmp	es:[di].CC_type, CT_FORMULA			>
EC <	je	typeOK						>
EC <	cmp	es:[di].CC_type, CT_DISPLAY_FORMULA		>
EC <	ERROR_NZ CELL_SHOULD_BE_A_FORMULA			>
EC <typeOK:							>
if _PROTECT_CELL
	;
	; if cell protection, we don't want to clear the protection bit
	;
	andnf	es:[di].CC_recalcFlags, mask CRF_PROTECTION
else
	andnf	es:[di].CC_recalcFlags, mask CRF_RESERVED
endif
	add	di, size CellFormula	; es:di <- ptr to the expression
	
	mov	cx, SEGMENT_CS		; cx:dx <- callback routine
	mov	dx, offset cs:ReplaceNameInExpressionCallback
	
	call	ParserForeachReference	; Process all the names...

	call	UnlockAndDirtyCell	; unlock and dirty the cell
	pop	ax, cx			; Restore row/column
	
	;
	; Now add the new dependencies
	;
	clr	dx			; Add dependencies
	call	UpdateDependenciesFromCell

	clc				; Signal: continue please
	.leave
	ret
ReplaceNameReferencesCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceNameInExpressionCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the names in an expression.

CALLED BY:	ParserForeachReference
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Inheritable ReplaceNameParams
		es:di	= Pointer to the reference
		al	= Type of the reference
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceNameInExpressionCallback	proc	far
	uses	ax
params	local	ReplaceNameParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	cmp	al, PARSER_TOKEN_NAME
	jne	quit			; Branch if not a name
	
	mov	ax, params.RNP_oldToken
	cmp	ax, es:[di].PTND_name	; Check for same as old name
	jne	quit			; Branch if not old name
	
	;
	; We've found a reference to the old name. Replace it with the new
	; one and dirty the block.
	;
	mov	ax, params.RNP_newToken
	mov	es:[di].PTND_name, ax	; Save new token
	
	SpreadsheetCellDirty		; Dirty the cell
quit:
	.leave
	ret
ReplaceNameInExpressionCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDependenciesFromCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a cells dependency list.

CALLED BY:	ReplaceNameReferencesCallback
PASS:		ax	= Row
		cx	= Column
		dx	= Parameter to pass to CellAddRemoveDeps
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDependenciesFromCell	proc	near
	uses	bp
	.enter
	sub	sp, size PCT_vars	; Allocate stack frame
	mov	bp, sp			; ss:bp <- ptr to the stack frame
	
	call	SpreadsheetInitCommonParams
	
	mov	ss:[bp].CP_row, ax	; Save our row/column
	mov	ss:[bp].CP_column, cx
	
	mov	ss:[bp].PCTV_row, ax	; Save our row/column here too
	mov	ss:[bp].PCTV_column, cx
	
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	call	CellAddRemoveDeps	; Add / Remove dependencies

	add	sp, size PCT_vars	; Restore stack frame
	.leave
	ret
UpdateDependenciesFromCell	endp

SpreadsheetNameCode	ends
