COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetFill.asm

AUTHOR:		Gene Anderson, Aug  7, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/ 7/92		Initial revision


DESCRIPTION:
	Code for filling a range in the spreadsheet
		

	$Id: spreadsheetFill.asm,v 1.1 97/04/07 11:13:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CHECK_LIMIT_FOR_FILL
;
; We piggy back on the cut/copy dialog box code.
;
CutPasteStrings	segment lmem	LMEM_TYPE_GENERAL

LocalDefString FillSizeWarning <"Due to memory constraints only \
part of the selected range can be filled.", 0>

CutPasteStrings	ends
endif

RareCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetFillRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a range with a value

CALLED BY:	MSG_SPREADSHEET_FILL_RANGE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cl - SpreadsheetSeriesFillFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetFillRange		method dynamic SpreadsheetClass,
						MSG_SPREADSHEET_FILL_RANGE
locals	local	CellLocals
	.enter

	call	SpreadsheetMarkBusy

	mov	si, di				;ds:si <- ptr to instance
if _PROTECT_CELL
	;
	; For cell protection, make sure no data is copied to the protected
	; cells, so we have to do the check here. If carry is set after the
	; call FillCheckProtection, that means the user is attempting to
	; copy data to some protected cell. So we have to abort the operation.
	;
	call	FillCheckProtection
	jc	fillError
endif

if _CHECK_LIMIT_FOR_FILL
	;
	; init end row to end selected row, in case no limit
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	ss:[locals].CL_data3, ax

	call	GetSheetTransferRangeLimit
	;
	; See if there is a limit to the number of cells we want to
	; copy.  If there is, then count the number of allocated
	; cells, and if it is greater then the limit, reduce the
	; number of rows copied so that the number of copied cells is
	; below the limit
	;
	jc	ok	
	mov	di, mask REF_ALL_CELLS or mask REF_NO_LOCK
	mov	ss:[locals].CL_data1, ax	; CL_data1 <- max # of
						; cells to copy
	clr	ss:[locals].CL_data2		; CL_data2 <- count of cells
	mov	ss:[locals].CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:[locals].CL_params.REP_callback.offset, offset RangeCheckLimit
	call	CallRangeEnumSelected
	;
	; CL_data3 contains the last row visited
	; carry flag if set means that we are trying to copy more than
	; the limit
	;
	jnc	ok
	
	;
	; Warn the user that we're trying to fill too much.
	;
	mov	ax, offset FillSizeWarning
	call	WarnUserDB
ok:
endif

	mov	ax, offset CellFillRangeRight
	test	cl, mask SSFF_ROWS
	jz	gotRoutine
	mov	ax, offset CellFillRangeDown
gotRoutine:

	mov	di, mask REF_ALL_CELLS or mask REF_NO_LOCK
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, ax

if _CHECK_LIMIT_FOR_FILL
	;
	; Previously at this point all of the selected cells would be
	; enumerated. Now we just enumerate through the cells
	; specified by the limiting range.  This is done so we
	; can adjust the range if the number of cells to be filled
	; exceeds the set limit
	;
	push	bx, cx, dx
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	bx, ss:[locals].CL_data3

	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column

	call	CallRangeEnum			; destroys di
	pop	bx, cx, dx
else
	call	CallRangeEnumSelected
endif
	;
	; Update the row heights, document size, and UI
	;
	call	RecalcRowHeightsFar
	mov	ax, SNFLAGS_SELECTION_ATTRIBUTES_CHANGE or \
			SNFLAGS_ACTIVE_CELL_DATA_CHANGE
	call	UpdateDocUIRedrawAll
quit::
	call	SpreadsheetMarkNotBusy
	.leave
	ret

if _PROTECT_CELL
fillError:
	;
	; bring up the error dialog box to inform the user
	;
	mov	si, offset CellProtectionError
	call	PasteNameNotifyDB
	jmp	quit
endif

SpreadsheetFillRange		endm

if _CHECK_LIMIT_FOR_FILL

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeCheckLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of cells we are copying, if it is
		greater than the limit specified in CL_data1, then
		quit. 

CALLED BY:	INTERNAL, SpreadsheetFillRange
PASS:		ax, cx 	= (row, col) of cell
		ss:bp 	= CellLocals
RETURN:		carry set if we passed the limit
		CL_data3= row of last cell enumerated

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeCheckLimit	proc	far
	uses	ax
locals	local	CellLocals
	.enter	inherit

	mov	ss:[locals].CL_data3, ax	; CL_data3 = row
	inc	ss:[locals].CL_data2		; increment count of
						; cells
	mov	ax, ss:[locals].CL_data1	; ax = limit
	;
	; if CL_data2 > CL_data1 then we have reached our limit.  The
	; cmp will set the carry flag, which will stop the enumeration
	;
	cmp	ax, ss:[locals].CL_data2
					
	.leave
	ret

RangeCheckLimit	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellFillRangeRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do part of a fill range right for one cell

CALLED BY:	SpreadsheetFillRange() via RangeEnum()
PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		ss:bx - ptr to stack frame passed as RangeEnumParams

RETURN:		carry - set to abort enum
		dl - RangeEnumFlags with REF_ALLOCATED bit set if we've
		     allocated a cell.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Uses CL_buffer
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellFillRangeRight	proc	far
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; If we're at the first column, copy the cell
	;
	cmp	cx, ss:[bx].REP_bounds.R_left
	ja	pasteCell			;branch if not first cell
	call	FillCopyCommon
	clc
	jmp	done

	;
	; We're at a later cell...paste what we've copied
	;
pasteCell:
	call	FillPasteCommon
done:
	.leave
	ret
CellFillRangeRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellFillRangeDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do part of a fill range down for one cell

CALLED BY:	SpreadsheetFillRange() via RangeEnum()
PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		ss:bx - ptr to stack frame passed as RangeEnumParams

RETURN:		carry - set to abort enum
		dl - RangeEnumFlags with REF_ALLOCATED bit set if we've
		     allocated a cell.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Because RangeEnum() goes left to right, top to bottom, we can't
	use quite the same technique as CellFillRangeRight(), where we
	can just get the first cell once and copy it.
	We could simply bump the range we enumerate by one row, and avoid
	the cmp at the start, but given the use of common code elsewhere,
	and the miriad little conditions to check for (eg. one row, last row,
	etc.), this is simpler.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Uses CL_buffer
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellFillRangeDown		proc	far
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; If we're at the first row, ignore it
	;
	cmp	ax, ss:[bx].REP_bounds.R_top
	je	nextCell			;branch if first e
	;
	; We're at a later cell...copy the top cell in the column and paste
	;
	push	ax
	;
	; Special case a single column, because then we can get away with
	; copying the data just once.  If we're at the second row, we
	; need to copy the first row (for the first time), otherwise
	; we can just paste.
	;
	mov	dx, ss:[bx].REP_bounds.R_right
	cmp	dx, ss:[bx].REP_bounds.R_left	;single column?
	jne	doCopy				;branch if not single column
	mov	dx, ss:[bx].REP_bounds.R_top
	inc	dx				;dx <- 2nd row
	cmp	ax, dx				;are we at 2nd row?
	jne	doPaste				;if not 2nd row, just paste
doCopy:
	mov	ax, ss:[bx].REP_bounds.R_top	;(ax,cx) <- top of column
	call	FillCopyCommon
doPaste:
	pop	ax
	call	FillPasteCommon
nextCell:

	.leave
	ret
CellFillRangeDown		endp


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillCheckProtection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the range to be filled contains protected cells

CALLED BY:	SpreadsheetFillRange
PASS:		ds:si	= Spreadsheet instance
		cl	= SpreadsheetSeriesFillFlags
RETURN:		carry	set if the range contains protected cells;
		otherwise, carry is clear.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Find out whether this operation is fill-right or fill-down, and then
		find out the corresponding range for the operation.
	* Check if there exists any protected cell inside that range, and
		return the appropriate flag.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillCheckProtection	proc	near
		class	SpreadsheetClass
		uses	ax, bx, cx, dx, bp
		.enter
EC <		call	ECCheckInstancePtr		;		>
		Assert record	cl, SpreadsheetSeriesFillFlags
	;
	; Get the selected range first.
	; Find out whether this is fill right or fill down. And then check
	; the corresponding range.
	;
		mov	ax, ds:[si].SSI_selected.CR_start.CR_row
		mov	bp, ds:[si].SSI_selected.CR_start.CR_column
		mov	bx, ds:[si].SSI_selected.CR_end.CR_row
		mov	dx, ds:[si].SSI_selected.CR_end.CR_column
		test	cl, mask SSFF_ROWS
		jz	fillRight
		inc	ax			;fill down operation
		jmp	gotRange
fillRight:
		inc	bp			;fill right operation
gotRange:
	;
	; Check if there exists any protected cell inside the ranage
	;
		mov	cx, bp			;ax,cx = top-left bound
		call	CheckProtectedCell
		.leave
		ret
FillCheckProtection		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillCopyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a cell as part of Fill

CALLED BY:	CellFillRangeDown(), CellFillRangeRight()
PASS:		(ax,cx) - (r,c) of cell to copy
		ds:si - ptr to SpreadsheetInstance
		ss:bp - inherited CellLocals
			CL_styleToken - style token of previous cell
RETURN:		ss:bp - CellLocals
			CL_buffer - contents of cell
			CL_styleToken - style token of cell
			CL_cellAttrs - styles for cell
			CL_data1.low - CellType of cell
			CL_data2 - size of data
		dl - RangeEnumFlags
			REF_NO_LOCK
			REF_ALL_CELLS
		carry - set if the cell exists
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 7/92		Initial version
	witt	11/15/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillCopyCommon		proc	near
	uses	ax, bx, cx, es, di
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	dx, DEFAULT_STYLE_TOKEN		;dx <- assume default style
	SpreadsheetCellLock
	;
	; Special case the cell not existing
	;
	push	ds, es, si
	pushf
	mov	bl, CT_EMPTY
	jnc	setCellType			;branch if cell doesn't exist
	;
	; The cell exists.  Copy its attrs, and see if there is
	; any data to copy
	;
	segmov	ds, es
	mov	si, ds:[di]			;ds:si <- ptr to cell data
	mov	di, si
	mov	dx, ds:[si].CC_attrs		;dx <- style token
	mov	bl, ds:[si].CC_type		;bl <- CellType
	;
	; The cell has data.  Save the type, and copy the data
	;
setCellType:
	clr	bh				;bx <- CellType
	mov	ss:locals.CL_data1.low, bl	;store CellType
EC <	cmp	cs:fillGetSizeAndPtr[bx], -1	;>
EC <	ERROR_E ILLEGAL_CELL_TYPE		;>
	call	cs:fillGetSizeAndPtr[bx]
	segmov	es, ss
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to dest
	rep	movsb
	popf
	pop	ds, es, si
	jnc	skipUnlock			;branch if no cell existed
	SpreadsheetCellUnlock
skipUnlock:
	;
	; Get the cell attributes, if we don't already have them
	;
	pushf
	cmp	dx, ss:locals.CL_styleToken	;same attrs?
	je	gotAttrs			;branch if same attrs
	mov	ss:locals.CL_styleToken, dx	;store new attrs
	mov	ax, dx				;ax <- style token
	segmov	es, ss
	lea	di, ss:locals.CL_cellAttrs	;es:di <- ptr to buffer
	call	StyleGetStyleByTokenFar
gotAttrs:
	mov	dl, mask REF_NO_LOCK or \
		mask REF_ALL_CELLS
	popf					;carry <- set if cell exists

	.leave
	ret

fillGetSizeAndPtr nptr \
	getTextSize,				;CT_TEXT
	getConstantSize,			;CT_CONSTANT
	getFormulaSize,				;CT_FORMULA
	-1,					;CT_NAME
	-1,					;CT_CHART
	getZeroForEmpty,			;CT_EMPTY
	getFormulaSize				;CT_DISPLAY_FORMULA
CheckHack <(length fillGetSizeAndPtr) eq (CellType/2)>

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

const0	FloatNum \
	<0, 0, 0, 0, 0>

if FULL_EXECUTE_IN_PLACE
idata	ends
endif

getZeroForEmpty:
NOFXIP<	segmov	ds, cs, si						>
FXIP<	mov	si, bx				;save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov	bx, si				;restore bx value	>
	mov	si, offset const0		;ds:si <- ptr to data
	mov	cx, (size const0)
	jmp	setSize

getTextSize:
	add	si, offset CT_text		;ds:si <- ptr to data
	add	di, offset CT_text
	call	LocalStringSize			;cx <- size of text (w/o NULL)
	mov	ss:locals.CL_data2, cx		;store size
	LocalNextChar	dscx			;+1 to copy NULL
	ret

getConstantSize:
	mov	cx, size CC_current		;cx <- size of data
	add	si, offset CC_current		;ds:si <- ptr to data
	jmp	setSize

getFormulaSize:
	mov	cx, ds:[si].CF_formulaSize	;cx <- size of data
	add	si, offset CF_formula		;ds:si <- ptr to data
setSize:
	mov	ss:locals.CL_data2, cx		;store size
	ret
FillCopyCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste a cell as part of Fill

CALLED BY:	CellFillRangeDown(), CellFillRangeRight()
PASS:		(ax,cx) - (r,c) of cell to paste into
		ds:si - ptr to SpreadsheetInstance
		ss:bp - inherited CellLocals
			CL_buffer - contents to paste
			CL_cellAttrs - attributes to paste with
			CL_data1.low - CellType of cell
			CL_data2 - size of data
RETURN:		dl - RangeEnumFlags
			REF_CELL_FREED - if cell freed
			REF_CELL_ALLOCATED - if cell was allocated
			REF_OTHER_ALLOC_OR_FREE - if cell was formula
		(FLOPPY_BASED_DOCUMENTS):
			carry set if spreadsheet too large
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillPasteCommon		proc	near
	uses	bx, es, di
locals	local	CellLocals
	.enter	inherit

if FLOPPY_BASED_DOCUMENTS
	call	SpreadsheetCheckDocumentSize
	jc	done
endif		
		
EC <	call	ECCheckInstancePtr		;>
	mov	di, ss:locals.CL_data1
	andnf	di, 0x00ff			;di <- CellType
	lea	bx, ss:locals.CL_cellAttrs	;ss:bx <- CellAttrs to use
	mov	dx, ss:locals.CL_data2		;dx <- size of data
	segmov	es, ss
EC <	cmp	cs:fillPasteRoutine[di], -1	;>
EC <	ERROR_E	ILLEGAL_CELL_TYPE		;>
	call	cs:fillPasteRoutine[di]
	;
	; Recalculate the cell and its dependents, but don't
	; redraw, because we're going to do that anyway.
	;
	call	RecalcDependentsNoRedraw
	;
	; Tell RangeEnum() that we've allocated a cell and allocated
	; or freed a different one.  Any or none of these may be true,
	; depending on whether the old cell existed or not, and whether
	; the cell that is replacing them is a formula.
	;
	mov	dl, mask REF_NO_LOCK or \
		mask REF_ALL_CELLS or \
		mask REF_CELL_ALLOCATED or \
		mask REF_OTHER_ALLOC_OR_FREE
	clc
done::
	.leave
	ret

fillPasteRoutine nptr \
	fillPasteText,				;CT_TEXT
	fillPasteConstant,			;CT_CONSTANT
	fillPasteFormula,			;CT_FORMULA
	-1,					;CT_NAME
	-1,					;CT_CHART
	fillPasteEmpty,				;CT_EMPTY
	fillPasteFormula			;CT_DISPLAY_FORMULA
CheckHack <(length fillPasteRoutine) eq (CellType/2)>

fillPasteText:
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to cell
	call	AllocTextCell
	ret

fillPasteConstant:
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to cell
	call	AllocConstantCell
	ret

fillPasteFormula:
	lea	di, ss:locals.CL_buffer
	;
	; Initialize the stack frame
	;
	push	bp, ax, cx
	sub	sp, (size PCT_vars)
	mov	bp, sp				;ss:bp <- ptr to PCT_vars
	push	ax, cx
	push	ds, si
	call	SpreadsheetInitCommonParamsFar
	mov	ss:[bp].PP_parserBufferSize, PARSE_TEXT_BUFFER_SIZE
	mov	ss:[bp].PP_flags, 0
	;
	; Copy the formula
	;
	segmov	ds, ss
	mov	si, di				;ds:si <- ptr to formula
	mov	cx, dx				;cx <- size of formula
	lea	di, ss:[bp].PCTV_parseBuffer	;es:di <- ptr to dest
	rep	movsb
	;
	; Store the formula
	; IMPORTANT: SpreadsheetAllocFormulaCellFar()
	; expects es:di to be a ptr *past* the formula,
	; and expects it to be in PCT_vars (PCTV_parseBuffer)
	; (this is how it calculates the size, amongst other things).
	;
	pop	ds, si
	pop	bx, dx				;(bx,dx) <- (r,c) of cell
	call	SpreadsheetAllocFormulaCellFar
	add	sp, (size PCT_vars)
	pop	bp, ax, cx
	;
	; Set the attributes for the cell, because
	; SpreadsheetAllocFormulaCellFar() doesn't deal with them.
	;
	push	ax
	SpreadsheetCellLock
EC <	ERROR_NC CELL_DOES_NOT_EXIST		;>
	mov	di, es:[di]			;es:di <- ptr to cell data
	mov	ax, es:[di].CC_attrs		;ax <- style token
	call	StyleDeleteStyleByTokenFar	;delete reference to old attrs
	push	es, di
	segmov	es, ss
	lea	di, ss:locals.CL_cellAttrs	;es:di <- ptr to attrs
	call	StyleGetTokenByStyleFar		;add reference to new attrs
	pop	es, di
	mov	es:[di].CC_attrs, ax		;store new token
	SpreadsheetCellDirty			;mark cell data as dirty
	SpreadsheetCellUnlock
	pop	ax
	ret

	;
	; If we're using the default styles, we want to delete the
	; cell entirely, if possible.
	;
fillPasteEmpty:
	call	AllocEmptyCell
	cmp	ss:locals.CL_styleToken, DEFAULT_STYLE_TOKEN
	jne	doneEmpty			;branch if not default
	call	DeleteCell
doneEmpty:
	ret

FillPasteCommon		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetFillSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a series in the spreadsheet

CALLED BY:	MSG_SPREADSHEET_FILL_SERIES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - SpreadsheetSeriesFillParams
		dx - size SpreadsheetSeriesFillParams (if called remotely)

RETURN:		al - SpreadsheetFillError
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetFillSeries		method dynamic SpreadsheetClass,
						MSG_SPREADSHEET_FILL_SERIES
locals	local	CellLocals

	mov	bx, bp				;ss:bx <- ptr to params

	.enter
	call	SpreadsheetMarkBusy
	mov	si, di				;ds:si <- ptr to Spreadsheet
if _PROTECT_CELL
	;
	; Make the range to be fill doesn't have any protected cell. If it 
	; does, then abort the operation.
	;
	call	FillSeriesCheckProtection
	LONG	jc	protectionError		;don't fill, just quit
endif
	;
	; Get the contents of the current cell
	;
	mov	ss:locals.CL_styleToken, INVALID_STYLE_TOKEN
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	call	FillCopyCommon
	clr	ss:locals.CL_data1.high		;no day overflow yet
	;
	; See if the cell is a a formula and get its value if so
	;
	pushf
	cmp	ss:locals.CL_data1.low, CT_FORMULA
	jne	notFormula			;branch if not a formula
	call	SeriesGetFormulaValue
notFormula:
	;
	; Filling by by date?  If so, check special cases
	;
	cmp	ss:[bx].SSFP_type, SSFT_NUMBER
	LONG jne	doDateChecks
	popf
	;
	; Get the initial value
	;
getInitialValue:
	segmov	es, ss, ax
	lea	di, ss:locals.CL_scratch1
	push	ds, si
	mov	ds, ax
	lea	si, ss:locals.CL_buffer
	mov	cx, (size FloatNum)/(size word)
	rep	movsw
	pop	ds, si
	;
	; If filling by number, use zero if the first cell is text
	;
	cmp	ss:locals.CL_data1.low, CT_TEXT
	jne	notText				;branch if not text
	clr	ax
	mov	cx, (size FloatNum)/(size word)
	lea	di, ss:locals.CL_scratch1
	rep	stosw				;store FP 0
notText:
	;
	; Do the fill
	;
;doFill:
	mov	ss:locals.CL_data1.low, CT_CONSTANT
doFillNoType:
	;
	; Copy the step value to immediately after the initial value
	;
	push	ds, si
	segmov	ds, ss, ax
	mov	es, ax
	lea	si, ss:[bx].SSFP_stepValue	;ds:si <- ptr to step
	mov	cx, (size SSFP_stepValue)/(size word)
	lea	di, ss:locals.CL_scratch2
	rep	movsw				;copy me jesus
	pop	ds, si
	;
	; Copy the SpreadsheetSeriesFillType
	;
	mov	ax, {word}ss:[bx].SSFP_type
	mov	ss:locals.CL_data3, ax		;store type and flags
	;
	; Make the range either the first row or the first column,
	; minus the first cell.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	inc	ax
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, cx
	test	ss:locals.CL_data3.high, mask SSFF_ROWS
	jnz	doRows
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	bx, ax
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	inc	cx
doRows:
	;
	; Call RangeEnum() to callback for all the cells
	;
	mov	di, mask REF_ALL_CELLS or mask REF_NO_LOCK
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CellFillSeries
	call	CallRangeEnum
	;
	; Update the row heights, document size, and UI
	; We update the UI for:
	;	all cell attributes
	;
	call	RecalcRowHeightsFar
	mov	ax, SNFLAGS_SELECTION_ATTRIBUTES_CHANGE
	call	UpdateDocUIRedrawAll

	mov	al, SFE_NO_ERROR		;al <- SpreadsheetFillError
quit:
	call	SpreadsheetMarkNotBusy

	.leave
	ret

	;
	; We're filling by dates -- check for various error conditions
	; and special cases.
	;
doDateChecks:
	;
	; Regardless of anything else, make sure the step value is OK
	;
	push	ax, ds, si
	segmov	ds, ss
	lea	si, ss:[bx].SSFP_stepValue	;ds:si <- ptr to step value
	call	FloatPushNumber
	call	FloatAbs			;fp <- ABS(step)
	mov	ax, SPREADSHEET_MAX_DATE_FILL_STEP
	call	FloatWordToFloat		;fp <- 90
	call	FloatCompAndDrop		;cmp ABS(step),90
	pop	ax, ds, si
	ja	quitDateStepError		;branch if ABS(step) > 90
	;
	; If we're filling by dates, flag empty or numeric cells that are
	; not formatted as dates.
	;
	popf					;carry <- set if cell exists
	jc	cellExists
checkFormat:
	cmp	ss:locals.CL_cellAttrs.CA_format, FORMAT_ID_DATE_LONG
	jb	quitError			;branch if not date format
	cmp	ss:locals.CL_cellAttrs.CA_format, FORMAT_ID_DATE_WEEKDAY
	ja	quitError			;branch if not date format
	jmp	afterEmptyCheck
cellExists:
	cmp	ss:locals.CL_data1.low, CT_TEXT
	jne	checkFormat
afterEmptyCheck:
	;
	; If the cell contains text, see if it parses as a date
	;
	cmp	ss:locals.CL_data1.low, CT_TEXT
	LONG jne	getInitialValue		;branch if not text
	segmov	es, ss
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to text
	LocalGetChar	ax, esdi, NO_ADVANCE	;ax <- 1st char

SBCS<	cmp	al, C_QUOTE			;double quote?	>
DBCS<	cmp	ax, C_QUOTATION_MARK		;double quote?	>
	je	skipChar
SBCS<	cmp	al, C_SNG_QUOTE			;single quote?	>
DBCS<	cmp	ax, C_APOSTROPHE_QUOTE		;single quote?	>
	jne	tryParse
skipChar:
	LocalNextChar	esdi			;skip initial quote
tryParse:
	call	FloatStringGetDateNumber
	jc	quitError			;branch if error
	;
	; The text parsed!  Save the date number and the format
	;
	lea	di, ss:locals.CL_scratch1
	call	FloatPopNumber			;store number in buffer
	mov	ss:locals.CL_data2, ax		;save DateTimeFormat
	mov	ss:locals.CL_data1.low, CT_TEXT
	jmp	doFillNoType

quitError:
	mov	al, SFE_NOT_DATE_NUMBER		;al <- SpreadsheetFillError
	jmp	quit

quitDateStepError:
	popf					;clean up flags
	mov	al, SFE_DATE_STEP_TOO_LARGE	;al <- SpreadsheetFillError
	jmp	quit

if _PROTECT_CELL
protectionError:
	;
	; Bring up the dialog box to inform the user.
	;
	mov	si, offset CellProtectionError
	call	PasteNameNotifyDB
	clr	al
	jmp	quit
endif
SpreadsheetFillSeries		endm


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillSeriesCheckProtection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there exists any protected cell in the range to
		be filled
CALLED BY:	SpreadsheetFillSeries
PASS:		ds:si	= spreadsheet instance data
		ss:bx	= SpreadsheetSeriesFillParams
RETURN:		carry set if protected cell(s) found; otherwise, it is clear.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Find out whether this operation is fill-down or fill-right to get
		the corresponding range.
	* Do the cell protection checking	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillSeriesCheckProtection	proc	near
		class	SpreadsheetClass
		uses	ax, bx, cx, dx
		.enter
EC <	call	ECCheckInstancePtr					>
	;
	; Find out whether it is fill-right or fill-down, and then get the
	; corresponding range.
	;
		mov	ax, ds:[si].SSI_selected.CR_start.CR_row
		mov	cx, ds:[si].SSI_selected.CR_start.CR_column
		test	ss:[bx].SSFP_flags, mask SSFF_ROWS
		jnz	fillDown
		inc	cx			;fill right
		mov	bx, ax
		mov	dx, ds:[si].SSI_selected.CR_end.CR_column
		jmp	gotRange
fillDown:
		inc	ax			;fill down
		mov	bx, ds:[si].SSI_selected.CR_end.CR_row
		mov	dx, cx
gotRange:
	;
	; Do the checking here
	;
		call	CheckProtectedCell
		.leave
		ret
FillSeriesCheckProtection		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGetFormulaValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current value for a formula cell, if any

CALLED BY:	SpreadsheetFillSeries()
PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) <- cell to get value for
		ss:bp - inherited locals
RETURN:		z flag - clear if not a value
		ss:bp - inherited locals
			CL_buffer - current value (if a value, else 0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesGetFormulaValue		proc	near
	uses	es, di, cx
locals	local	CellLocals 
	.enter	inherit

	SpreadsheetCellLock
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
	push	es, ds, si
	segmov	ds, es
	mov	si, ds:[di]			;ds:si <- ptr to cell
EC <	cmp	ds:[si].CC_type, CT_FORMULA	;formula cell?>
EC <	ERROR_NE BAD_CELL_TYPE			;>
	segmov	es, ss
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to buffer
	;
	; See if the result is a number -- if not, bail
	;
	cmp	ds:[si].CF_return, RT_VALUE	;result a value?
	pushf					;save flag
	jne	getZeroForText			;branch if not a value
	add	si, offset CF_current		;ds:si <- ptr to current value
doCopy:
	mov	cx, (size CF_current)/(size word)
	rep	movsw				;copy me jesus
	popf
	pop	es, ds, si
	SpreadsheetCellUnlock

	.leave
	ret

getZeroForText:
NOFXIP<	segmov	ds, cs, si						>
FXIP<	mov	si, bx				;save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov	bx, si				;restore bx value	>
	mov	si, offset const0		;ds:si <- ptr to zero
	jmp	doCopy
SeriesGetFormulaValue		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellFillSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do series fill for one cell

CALLED BY:	SpreadsheetFillSeries() via RangeEnum()
PASS:		ss:bp - ptr to CallRangeEnum() local variables
			CL_scratch1 - initial value
			CL_scratch2 - step value
			CL_cellAttrs - attributes to paste with
			CL_data1.low - CellType of cell
			CL_data1.high - day for overflow (0 for none)
			CL_data2 - DateTimeFormat if CT_TEXT
			CL_data3.low - SpreadsheetSeriesFillType
			CL_data3.high - SpreadsheetSeriesFillFlags
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		ss:bx - ptr to stack frame passed as RangeEnumParams
RETURN:		dl - RangeEnumFlags
			REF_CELL_FREED - if cell freed
			REF_CELL_ALLOCATED - if cell was allocated
			REF_OTHER_ALLOC_OR_FREE - if cell was formula
		carry - set to abort
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	uses:
		CL_buffer, CL_cellAttrs
		CL_data1, CL_data2, CL_data3
		CL_scratch1, CL_scratch2
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellFillSeries		proc	far
	uses	es, di, bx
locals	local	CellLocals
	.enter	inherit

	segmov	es, ss
	lea	di, ss:locals.CL_scratch1	;es:di <- ptr to FloatNum
	;
	; Put the current value and step on the stack
	;
	push	ds, si, ax, cx
	segmov	ds, ss
	mov	si, di				;ds:si <- ptr to current value
	call	FloatPushNumber
	add	si, (size FloatNum)		;ds:si <- ptr to step value
	call	FloatPushNumber
CheckHack <(offset CL_scratch2) eq (offset CL_scratch1)+(size FloatNum)>
	;
	; Update the current value appropriately
	;
	mov	bl, {byte}ss:locals.CL_data3
	clr	bh				;bx <- SpreadsheetSeriesFillType
	call	cs:seriesUpdateValueRoutines[bx]
	;
	; Get the new value off the stack (into es:di)
	;
	call	FloatPopNumber
	pop	ds, si, ax, cx
	;
	; See if the initial cell was parsed as text or a number
	;
	lea	bx, ss:locals.CL_cellAttrs	;ss:bx <- CellAttrs
	cmp	ss:locals.CL_data1.low, CT_TEXT
	jne	allocConstantCell
	;
	; Format the value as text and allocate a text cell
	;
	call	FormatTextForDateFill
	jc	afterCellAlloc			;branch if error
	call	AllocTextCell
	jmp	afterCellAlloc

	;
	; Allocate a constant cell with the current value
	;
allocConstantCell:
	call	AllocConstantCell
afterCellAlloc:
	;
	; Recalculate any dependencies
	;
	call	RecalcDependentsNoRedraw
	;
	; Tell RangeEnum() that we've allocated a cell and allocated
	; or freed a different one.  Any or none of these may be true,
	; depending on whether the old cell existed or not, and whether
	; it was a formula or had dependents.
	;
	mov	dl, mask REF_NO_LOCK or \
		mask REF_ALL_CELLS or \
		mask REF_CELL_ALLOCATED or \
		mask REF_OTHER_ALLOC_OR_FREE
	clc					;carry <- don't abort
	.leave
	ret

seriesUpdateNumber:
	test	ss:locals.CL_data3.high, mask SSFF_GEOMETRIC
	jnz	doGeometric
	call	FloatAdd
	retn

doGeometric:
	call	FloatMultiply
	retn

seriesUpdateDay:
	call	SeriesDateCommon
	jc	dateError			;branch if error
	add	bh, dl				;bh <- new day
dateCommon:
	call	NormalizeDate
	jc	dateError			;branch if error
	call	FloatGetDateNumber
	retn

	;
	; For stepping by year or month, rather than normalize things
	; like 2/29/97 into 3/1/97, we try to stay in the same month,
	; eg. 2/29/97 becomes 2/28/97.
	;
dateCommon2:
	mov	dl, ss:locals.CL_data1.high	;dl <- overflow, if any
	tst	dl				;any previous overflow?
	jz	noOverflow			;branch if not
	mov	bh, dl				;bh <- previous overflow day
noOverflow:
	push	bx

	;
	; (We need to at least temporarily normalize the month, or face numbers
	;  of days in the month later (or actually death in EC)  -cbh 2/23/94)
	;
	push	ax
	call	NormalizeMonth			;bl,ax resolved to a good value
	mov	dh, bh				;dh <- current day
	call	GetDaysInMonth			;bh <- # of days in month
	mov	dl, bh				;dl <- # of days in month
	cmp	dh, bh				;gone past end of month?
	pop	ax
	pop	bx
	jbe	dateCommon			;branch if not
	;
	; We've hit the end of the month.  Flag this fact for the next
	; iteration, if any.
	;
	mov	ss:locals.CL_data1.high, bh
	mov	bh, dl				;bh <- set to end of month
	jmp	dateCommon

seriesUpdateMonth:
	call	SeriesDateCommon
	jc	dateError			;branch if error
	add	bl, dl				;bl <- new month
	jmp	dateCommon2

seriesUpdateYear:
	call	SeriesDateCommon
	jc	dateError			;branch if error
	xchg	ax, dx				;al <- step
	cbw					;ax <- step
	add	ax, dx				;ax <- new year
	jmp	dateCommon2

	;
	; An error occurred when parsing the date.  We just return
	; the value 1, since that is the first valid date number.
	; (ie. Jan 1, 1900). The next iteration should then reflect
	; the desired result of stepping by day, weekday, month or year.
	;
dateError:
	call	Float1
	retn

seriesUpdateWeekday:
	call	SeriesDateCommon
	jc	dateError			;branch if error
	;
	; Calculate the weekday
	;
	push	ax
	call	FloatGetDateNumber		;FP <- date number
	pop	ax
	jc	dateError			;branch if error
	push	ax				;year
	call	FloatDateNumberGetWeekday
	push	dx
	call	FloatFloatToDword		;dx:ax <- weekday (1-7)
EC <	ERROR_C	BAD_WEEKDAY_IN_FILL_BY_WEEKDAY				>
EC <	cmpdw	dxax, 7							>
EC <	ERROR_A	BAD_WEEKDAY_IN_FILL_BY_WEEKDAY				>
	dec	al				;al <- weekday (0-6)
	pop	dx
	;
	; Check for stepping forward, backward or 0.
	;
	mov	cl, 6				;cl <- commonly used value
	mov	ch, dl				;ch <- step size
	tst	dl				;+,- or 0?
	jz	doneWeekday			;branch if 0 (done)
	mov	ah, -1				;ah <- backward
	js	weekdayLoop			;branch if -
	mov	ah, 1				;ah <- forward
	;
	; Do the step, skipping any weekends we cover
	;
weekdayLoop:
	;
	; Advance the day and the day of the week
	;
	add	bh, ah				;bh <- advance day
	add	al, ah				;al <- advance DOW, set flags
	;
	; See if the day of the week wrapped
	;
	jns	noWrapBack
	mov	al, cl				;al <- reset to 6=Saturday
noWrapBack:
	cmp	al, cl				;day of week wrapped >6?
	jbe	noWrapForward			;branch if not
	clr	al				;al <- reset to Sunday
noWrapForward:
	;
	; Make sure the day isn't Saturday or Sunday
	;
	tst	al				;0=Sunday?
	jz	weekdayLoop			;branch if so
	cmp	al, cl				;6=Saturday?
	je	weekdayLoop			;branch if so
notWeekend::
	sub	ch, ah				;ch <- one more day done
	jnz	weekdayLoop			;loop while more days
doneWeekday:
	pop	ax
	jmp	dateCommon


seriesUpdateValueRoutines nptr \
	seriesUpdateNumber,			;SSFT_NUMBER
	seriesUpdateDay,			;SSFT_DAY
	seriesUpdateWeekday,			;SSFT_WEEKDAY
	seriesUpdateMonth,			;SSFT_MONTH
	seriesUpdateYear			;SSFT_YEAR
CheckHack <(length seriesUpdateValueRoutines) eq (SpreadsheetSeriesFillType)/2>

CellFillSeries		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesDateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for a date series

CALLED BY:	CellFillSeries()
PASS:		fp stack:
		tos->	step value
			current value
RETURN:		carry - set if error
		fp stack:
		tos->	<empty>
		ax - year
		bl - month
		bh - day
		dl - step value
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeriesDateCommon		proc	near
	.enter

	call	FloatFloatToDword		;dx:ax <- step value
	push	ax
	call	FloatDup			;2 copies of current value
	call	FloatDateNumberGetMonthAndDay	;bl <- month, bh <- day
	call	FloatDateNumberGetYear		;ax <- year (carry if error)
	pop	dx				;dl <- step value

	.leave
	ret
SeriesDateCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NormalizeDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize a date to legal values

CALLED BY:	CellFillSeries()
PASS:		ax - year (1900-2099)
		bl - month (-128 < month < 127)
		bh - day (-128 < day < 127)
RETURN:		ax - year (1900-2099)
		bl - month (1-12)
		bh - day (1-31)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	(1) normalize the month
	(2) normalize the day
	(3) if necessary, re-normalize the month
	The order is as above because normalizing the day requires a
	normalized month.  Normalizing the day may de-normalize the month,
	requiring the check at the end.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NormalizeDate		proc	near
	uses	dx
	.enter

	call	CheckYear
	jc	quit				;branch if error
	mov	dl, bh				;dl <- day
monthLoop:
	call	NormalizeMonth
	jc	quit				;branch if error
	;
	; while (days > daysinmonth(month, year) or (days <= 0)
	;
	tst	dl				;zero or negative day?
	jle	lastMonth			;<0 is last month
	call	GetDaysInMonth			;bh <- # of days in month
	cmp	dl, bh				;too many days?
	jle	gotDay
	inc	bl				;bl <- next month
	sub	dl, bh				;dl <- days left
	;
	; We jump to renormalize the month, because the above
	; increment of the month may have denormalized it...
	;
	jmp	monthLoop

lastMonth:
	dec	bl				;bl <- last month
	call	NormalizeMonth			;bl <- last month, normalized
	jc	quit				;branch if error
	call	GetDaysInMonth			;bh <- # of days last month
	add	dl, bh				;dl <- days left
	jmp	monthLoop

	;
	; Verify the month is still OK
	;
gotDay:
	cmp	bl, 12				;month OK?
	jg	monthLoop			;branch to re-adjust month

	mov	bh, dl				;bh <- day
	clc					;carry <- no error
quit:
	.leave
	ret

NormalizeDate		endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	NormalizeMonth

SYNOPSIS:	Get month between 1 and 12, changing the year as necessary.

CALLED BY:	NormalizeDate, SeriesDateCommon

PASS:		bl -- month
		ax -- year

RETURN:		bl, ax -- updated
		carry set if year forced out of range

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/94       	Pulled out of NormalizeDate

------------------------------------------------------------------------------@

NormalizeMonth	proc	near
	tst	bl				;zero or negative month?
	jle	lastYear			;zero is last year
	cmp	bl, 12				;too many months?
	jle	gotMonth
	sub	bl, 12				;bl <- months left
	inc	ax				;ax <- next year
	call	CheckYear
	jc	quitMonth			;branch if error
	jmp	short NormalizeMonth

lastYear:
	dec	ax				;ax <- last year
	add	bl, 12				;bl <- same month, last year
	call	CheckYear
	jc	quitMonth			;branch if error
	jmp	short NormalizeMonth

gotMonth:
	clc					;carry <- no error
quitMonth:
	ret

NormalizeMonth	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckYear

SYNOPSIS:	Checks that the year is valid.

CALLED BY:	NormalizeMonth, NormalizeDate

PASS:		ax -- year

RETURN:		carry set if year invalid

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/94       	Pulled out of NormalizeDate

------------------------------------------------------------------------------@

CheckYear	proc	near
	cmp	ax, YEAR_MAX			;year too large?
	ja	cyErr				;branch if too large
	cmp	ax, YEAR_MIN			;year too small? (carry set)
	ret
cyErr:
	stc					;carry <- error
	ret
CheckYear	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatTextForDateFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a number as text for a date fill

CALLED BY:	CellFillSeries()
PASS:		ds:si - spreadsheet object
		ss:bp - inherited locals
			CL_scratch1 - current value
			CL_data2 - DateTimeFormat
		(ax,cx) - (r,c) of cell
RETURN:		es:di - ptr to text
		dx - length of text
		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	uses CL_buffer
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatTextForDateFill		proc	near
	uses	ds, si, ax, bx, cx
	.enter	inherit	CellFillSeries

	segmov	ds, ss
	lea	si, ss:locals.CL_scratch1	;ds:si <- ptr to currrent value
	call	FloatPushNumber			;1 copy for date number
	call	FloatDup			;1 copy for month & day
	call	FloatDup			;1 copy for year
	;
	; Get the date number so we can calc the day of the week.
	; We can do this a bit easier than normal because we
	; know the date number is valid, and 1 = 1/1/1900 = Monday.
	;
	call	FloatFloatToDword
	jc	quit				;branch if error
	cmpdw	dxax, DATE_NUMBER_MAX
	ja	quitError			;branch if too large
	mov	cx, 7
	div	cx
	mov	cl, dl				;dl <- weekday (0-6)
	;
	; Get the month, day and year from the current value
	;
	call	FloatDateNumberGetMonthAndDay	;bl <- month, bh <- day
	jc	quit				;branch if error
	call	FloatDateNumberGetYear		;ax <- year
	jc	quit				;branch if error
	;
	; Using the format we parsed the initial text as,
	; format the current month, day and year appropriately.
	;
	mov	si, ss:locals.CL_data2		;si <- DateTimeFormat
	segmov	es, ss
	lea	di, ss:locals.CL_buffer
	call	LocalFormatDateTime
	mov	dx, cx				;dx <- length w/o NULL
	clc					;carry <- no error
quit:

	.leave
	ret

quitError:
	stc					;carry <- error
	jmp	quit
FormatTextForDateFill		endp

RareCode ends
