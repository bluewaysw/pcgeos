COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetChart.asm

AUTHOR:		John Wedgwood, Sep 16, 1991

METHODS:
	Name				Description
	----				-----------
	MSG_SPREADSHEET_CHART_RANGE	Chart the selected range

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 9/16/91	Initial revision

DESCRIPTION:
	Charting code for the spreadsheet library.

	$Id: spreadsheetChart.asm,v 1.2 98/03/11 21:20:15 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetChartCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
Template for the Chart cell.  The chart cell consists of a header
CellChart structure, (which is basically just a CellFormula
structure), followed by the expression of the formula itself.  Since
the chart formula never returns a value, we use the ERR formula (this
is a catch-all formula that simply dumps all its arguments, and
propagates the error to its dependents).  As the chart cell never has
any dependents, this is no problem.  Since there is no value stored in
RV_VALUE, the VM block handle of the chart objects is stored there.

The chart formula is:	=ERR(range), where the range is made up of two
cells, for example: =ERR(A1:C5).  Cell references are absolute, since
the chart cell isn't expected to move at any time.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

chartCellTemplate	CellChart <<
    <						; CF_common
    	0,					;    CC_dependencies
	CT_CHART,				;    CC_type
	0,					;    CC_recalcFlags
	DEFAULT_STYLE_TOKEN,			;    CC_attrs
	0					;    CC_nots
    >,
    RT_VALUE,					; CF_return
    <RV_VALUE <0,0,0,0,0>>,			; CF_current (FloatNum)
    CHART_FORMULA_SIZE				; CF_formulaSize
>>

;
; Template for the formula that defines the chart.
;
    ;
    ; Function token
    ;
    byte	PARSER_TOKEN_FUNCTION
    ParserTokenFunctionData <
    	FUNCTION_ID_ERR			; bullshit value
    >
    
CHART_TEMPLATE_RANGE_FIRST_CELL = $-chartCellTemplate

    ;
    ; First cell (absolute references)
    ;
    byte	PARSER_TOKEN_CELL
    ParserTokenCellData <
    	<
	    <1, 0>,
	    <1, 0>
	>
    >

    ;
    ; The separator between the two cells in the range.
    ;
    byte	PARSER_TOKEN_OPERATOR
    ParserTokenOperatorData <
        OP_RANGE_SEPARATOR
    >

CHART_TEMPLATE_RANGE_SECOND_CELL = $-chartCellTemplate

    ;
    ; Last cell
    ;
    byte	PARSER_TOKEN_CELL
    ParserTokenCellData <
    	<
	    <1, 0>,
	    <1, 0>
	>
    >

    byte	PARSER_TOKEN_ARG_END
    byte	PARSER_TOKEN_CLOSE_FUNCTION
    byte	PARSER_TOKEN_END_OF_EXPRESSION

align 2
CHART_CELL_SIZE		=	$-chartCellTemplate

; Formula size is size of entire cell minus the (fixed-size) header part

CHART_FORMULA_SIZE	=	CHART_CELL_SIZE - (size CellChart)

if _CHARTS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetChartRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chart the current range.

CALLED BY:	via MSG_SPREADSHEET_CHART_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= MSG_SPREADSHEET_CHART_RANGE
		cl	= ChartType
		ch	= ChartVariation

RETURN:		al - ChartReturnType
		if CRT_OTHER_ERROR
			ah - SpreadsheetChartReturnType

DESTROYED:	cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetChartRange	method	dynamic 	SpreadsheetClass, 
						MSG_SPREADSHEET_CHART_RANGE

locals	local	SpreadsheetChartLocals

	call	SpreadsheetMarkBusy

	.enter
		CheckHack <offset SCL_variation eq offset SCL_type+1 >
	mov	{word} locals.SCL_type, cx

	mov	si, di			; ds:si <- instance ptr

	; No chart body, no chart!

	mov	ax, CRT_OTHER_ERROR or (SCRT_INSUFFICIENT_MEMORY shl 8)
	tst	ds:[si].SSI_chartBody.chunk
EC <	ERROR_Z	SPREADSHEET_NO_CHART_BODY	;>
NEC <	LONG jz	quit				;>
	
	;
	; Find a cell to put the chart in.
	;
	mov	ax, offset FindEmptyCellCB
	mov	dl, mask REF_ALL_CELLS or mask REF_NO_LOCK
	call	FindChartCell		; cx <- column to hold the
					; chart
	mov	ax, CRT_OTHER_ERROR or (SCRT_TOO_MANY_CHARTS shl 8)
	LONG jnc quit			; Branch if there's no space for it

	mov	locals.SCL_cell, cx

	; Figure out 

	call	GetRangeToChart
	LONG jc	quit
	mov	locals.SCL_enum.REP_bounds.R_left, cx
	mov	locals.SCL_enum.REP_bounds.R_top, ax
	mov	locals.SCL_enum.REP_bounds.R_right, bx
	mov	locals.SCL_enum.REP_bounds.R_bottom, dx
	;
	; Allocate a chart cell
	;
	mov	cx, locals.SCL_cell	; cx <- column for chart cell
	call	AllocChartCell		; Create the cell itself

	;
	; Create data block for charting
	;
	
	call	CreateChartData
	LONG jc	errorNotEnoughMemory	; Branch on error
	mov	locals.SCL_block, ax	; store VM handle 

	;
	; Create a GState so we can get the window bounds.  If no
	; gstate, then we don't know where to draw the chart, so bail.
	;

	push	bp
	mov	si, ds:[si].SSI_chunk
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp
	pop	bp

	pushf
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset
	popf

	LONG jnc noGState 

	;
	; Set up the chart creation parameters 
	;
	mov	ax, locals.SCL_block
	mov	bx, {word} locals.SCL_type

	push	bp
	sub	sp, size ChartCreateParameters
	mov	bp, sp
	
	mov	ss:[bp].CCP_data, ax
		CheckHack <offset CCP_variation eq offset CCP_type+1>
	mov	{word} ss:[bp].CCP_type, bx

	push	ds, si
	sub	sp, size RectDWord
	segmov	ds, ss, si
	mov	si, sp
	call	GrGetWinBoundsDWord
	call	GrDestroyState

	; Place chart in the lower-right hand quarter of the screen
	; -- 1/4 the screen size, unless that is too small
	; -- positioned in the lower right
	; Leave some room for the grobj handles!

	movdw	bxax, ds:[si].RD_right
	subdw	bxax, ds:[si].RD_left
	sardw	bxax				;ax <- window width / 2
EC <	tst	bx				;>
EC <	ERROR_NZ SPREADSHEET_CHART_TOO_LARGE	;>
	cmp	ax, DEFAULT_CHART_WIDTH
	jae	widthOK
	mov	ax, DEFAULT_CHART_WIDTH

widthOK:
	mov	ss:[bp].CCP_size.P_x, ax	;set width
	clr	bx				;bx:ax <- chart width
	movdw	dxcx, ds:[si].RD_right
	subdw	dxcx, CHART_MARGIN
	subdw	dxcx, bxax			;dx:cx <- chart left
	movdw	ss:[bp].CCP_position.PD_x, dxcx	;set left coord

	movdw	bxax, ds:[si].RD_bottom
	subdw	bxax, ds:[si].RD_top
	sardw	bxax
EC <	tst	bx				;>
EC <	ERROR_NZ SPREADSHEET_CHART_TOO_LARGE	;>
	cmp	ax, DEFAULT_CHART_HEIGHT
	jae	heightOK
	mov	ax, DEFAULT_CHART_HEIGHT

heightOK:
	mov	ss:[bp].CCP_size.P_y, ax	;set height
	clr	bx				;bx:ax <- chart height
	movdw	dxcx, ds:[si].RD_bottom
	subdw	dxcx, CHART_MARGIN
	subdw	dxcx, bxax			;dx:cx <- chart top
	movdw	ss:[bp].CCP_position.PD_y, dxcx	;set top coord

	add	sp, size RectDWord
	pop	ds, si

	push	si
	movdw	bxsi, ds:[si].SSI_chartBody
	mov	ax, MSG_CHART_BODY_CREATE_CHART
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	bx, cx		; VM block handle of created chart
	pop	si

	add	sp, size ChartCreateParameters
	pop	bp

	cmp	al, CRT_OK
	jne	errorFreeCell	

	;
	; Save VM block handle of new chart.
	;

	mov	ax, CHART_ROW		; ax <- cell row
	mov	cx, locals.SCL_cell
	
	SpreadsheetCellLock		; *es:di <- chart cell
EC <	ERROR_NC CELL_DOES_NOT_EXIST	;baby, baby, where did my cell go?>

	mov	di, es:[di]		; es:di <- chart cell
	mov	{word} es:[di].CG_formula.CF_current, bx

	SpreadsheetCellDirty		; Dirty the cell
	SpreadsheetCellUnlock		; Release the cell
	mov	al, CRT_OK

quit:
	.leave
	call	SpreadsheetMarkNotBusy
	ret

noGState:
	; AX is a VM block that won't be needed, so free it.

	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	VMFree			; ax <- new vm block handle

errorNotEnoughMemory:
	mov	ax, CRT_OTHER_ERROR or (SCRT_INSUFFICIENT_MEMORY shl 8)
errorFreeCell:

	;
	; Free the chart cell
	;

	mov	cx, ss:[locals].SCL_cell
	call	SpreadsheetDeleteChartCell
	jmp	quit	

SpreadsheetChartRange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeToChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range to chart

CALLED BY:	SpreadsheetChartRange()
PASS:		ds:si - ptr to 
RETURN:		(ax,cx),
		(dx,bx) - range to chart
		carry - set for error
			al - ChartReturnType
			if CRT_OTHER_ERROR
				ah - SpreadsheetChartReturnType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRangeToChart		proc	near
	uses	di
	class	SpreadsheetClass
extent		local	CellRange
reParams	local	RangeEnumParams
ForceRef extent
ForceRef reParams

	.enter
	;
	; Get the extent of the data within the selection
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	bx, ds:[si].SSI_selected.CR_end.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	mov	di, SET_NO_EMPTY_CELLS
	call	CallRangeExtent
	mov	di, CRT_OTHER_ERROR or (SCRT_NO_DATA shl 8)
	je	errorCommon			;branch if no data
	;
	; See if there are too many rows (categories) or columns (series)
	;
	mov	di, bx
	sub	di, cx
	inc	di				;di <- # of columns
	cmp	di, MAX_SERIES_COUNT
	mov	di, CRT_TOO_MANY_SERIES
	ja	errorCommon
	mov	di, dx
	sub	di, ax
	inc	di				;di <- # of rows
	cmp	di, MAX_CATEGORY_COUNT
	mov	di, CRT_TOO_MANY_CATEGORIES
	ja	errorCommon
	clc					;carry <- no error
quit:
	.leave
	ret

errorCommon:
	mov	ax, di				;ax <- ChartReturnType, etc.
	stc					;carry <- error
	jmp	quit
GetRangeToChart		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDeleteChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a chart from the spreadsheet.

CALLED BY:	via MSG_SPREADSHEET_DELETE_CHART
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= VM block handle of chart that's being deleted

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetDeleteChart	method	dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_DELETE_CHART

	.enter
	mov	si, di			; ds:si - spreadsheet instance

	mov	ax, offset FindPassedChartCB
	clr	dl			; RangeEnumFlags
	call	FindChartCell		; cx <- column
	jnc	done

	call	SpreadsheetDeleteChartCell
done:
	.leave
	ret
SpreadsheetDeleteChart	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDeleteChartCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the cell containing the chart formula

CALLED BY:	SpreadsheetDeleteChart, SpreadsheetChartRange

PASS:		cx - column of chart cell

RETURN:		nothing 

DESTROYED:	bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetDeleteChartCell	proc near
	uses	ax
	.enter

	mov	ax, CHART_ROW			; ax <- row 
	mov	dx, -1				; Signal: remove dependencies
	call	FormulaCellAddParserRemoveDependencies
	
	;
	; Remove the cell itself.
	;

	clr	dx
	SpreadsheetCellReplaceAll

	.leave
	ret
SpreadsheetDeleteChartCell	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindChartCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an empty cell to put the chart in.

CALLED BY:	SpreadsheetChartRange

PASS:		ds:si	= Spreadsheet instance
		ax - offset of callback routine
		cx - data to pass to callback
		dl - RangeEnumFlags

RETURN:		if found
			carry set
			cx	= column # of cell
		else 
			carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindChartCell	proc	near
	uses	dx

locals	local	RangeEnumParams

	.enter
	
	mov	locals.REP_bounds.R_top, CHART_ROW
	mov	locals.REP_bounds.R_bottom, CHART_ROW
	mov	locals.REP_bounds.R_left, 0
	mov	locals.REP_bounds.R_right, LARGEST_COLUMN
	
	mov	locals.REP_callback.segment, SEGMENT_CS
	mov	locals.REP_callback.offset,  ax
	
	push	bp
	lea	bx, locals
	mov	bp, cx				; starting value
	
	call	RangeEnum			; 
	mov	cx, bp				; column #
	pop	bp
	
	.leave
	ret

FindChartCell	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPassedChartCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to find the passed chart vm block

CALLED BY:	SpreadsheetDeleteChart via RangeEnum

PASS:		bp - VM block handle of chart block
		*es:di - chart cell

RETURN:		if found:
			carry set
			bp - column
		else
			carry clear

DESTROYED:	di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPassedChartCB	proc far
	.enter
	mov	di, es:[di]
	cmp	{word} es:[di].CG_formula.CF_current, bp
	je	found
	clc
done:
	.leave
	ret
found:
	mov	bp, cx			; column number
	stc
	jmp	done
FindPassedChartCB	endp

if _CHARTS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindEmptyCellCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an empty cell if one exists.

CALLED BY:	FindChartCell via RangeEnum

PASS:		carry clear if we've found an empty cell
		cx - column #

RETURN:		carry set to abort
		bp	= Column of the cell

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindEmptyCellCB	proc	far
	cmc			; set carry if empty, clear carry
				; otherwise 
	mov	bp, cx				; bp <- column
	ret

FindEmptyCellCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocChartCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chart cell for the currently selected range.

CALLED BY:	SpreadsheetChartRange
PASS:		ds:si	= Spreadsheet instance
		cx	= Column to hold the chart
		ss:bp - inherited locals
		    locals.SCL_enum.REP_bounds - area to chart

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The only argument to the chart formula is the range of data in the
	chart.
	
	The chart formula looks like:
		Chart Function
		Chart Range
		End Function
		End Expression

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocChartCell	proc	near
	uses	ax, bx, cx, dx, di, bp, es

	.enter	inherit	SpreadsheetChartRange
	sub	sp, CHART_CELL_SIZE		; Allocate stack frame
	mov	bx, sp				; ss:bp <- frame ptr

	;
	; Fill the buffer with the cell data.
	;
	; ds:si	= Spreadsheet instance
	; ss:bx	= Pointer to of block to build in
	; cx	= Column of the chart cell
	;
	segmov	es, ss, di			; es:di <- ptr to data
	mov	di, bx
	call	FillInChartCellData		; Put the cell data in there

	;
	; Create the cell and copy in the data.
	;
	mov	dx, CHART_CELL_SIZE		; dx <- size of the data
	mov	ax, CHART_ROW			; ax <- row

	SpreadsheetCellReplaceAll		; Poof... A chart cell
	
	;
	; Now add add the dependencies for the chart cell.
	; ax/cx	= Row/Column of the cell
	; ds:si	= Spreadsheet instance
	;
	clr	dx				; Signal: add dependencies
	call	FormulaCellAddParserRemoveDependencies

	add	sp, CHART_CELL_SIZE		; Restore stack frame
	.leave
	ret
AllocChartCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInChartCellData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the cell data associated with a chart cell.

CALLED BY:	AllocChartCell()
PASS:		es:di	= Pointer to the block to fill in.
		ds:si   = Spreadsheet object
		ss:bp - inherited locals
		    locals.SCL_enum.REP_bounds - area to chart

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInChartCellData	proc	near
	uses	cx, di, si, ds
	.enter	inherit	AllocChartCell
EC <	call	ECCheckPointerESDI			>
	
	push	ds, si, di			; Save ptr to buffer
	segmov	ds, cs, si			; ds:si <- source
	mov	si, offset chartCellTemplate
	
	mov	cx, CHART_CELL_SIZE		; cx <- size
	
	rep	movsb				; Copy the data
	pop	ds, si, di			; Restore ptr to buffer

	call	FillInChartFormula		; Fill in the formula
	.leave
	ret
FillInChartCellData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInChartFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the chart-formula block.

CALLED BY:	FillInChartCellData()
PASS:		ds:si	= Spreadsheet instance
		es:di	= Place to put the formula
		ss:bp - inherited locals
		    locals.SCL_enum.REP_bounds - area to chart
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInChartFormula	proc	near
	class	SpreadsheetClass
	uses	ax, bx

EC <	call	ECCheckInstancePtr			>

	.enter	inherit	FillInChartCellData
	;
	; Stuff the range, being careful not to overwrite CRC_ABSOLUTE
	; flags. 
	;

	mov	bx, CHART_TEMPLATE_RANGE_FIRST_CELL

	mov	ax, ss:locals.SCL_enum.REP_bounds.R_top
	ornf	es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_row, ax

	mov	ax, ss:locals.SCL_enum.REP_bounds.R_left
	ornf	es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_column, ax
	
	mov	bx, CHART_TEMPLATE_RANGE_SECOND_CELL

	mov	ax, ss:locals.SCL_enum.REP_bounds.R_bottom
	ornf	es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_row, ax

	mov	ax, ss:locals.SCL_enum.REP_bounds.R_right
	ornf	es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_column, ax
	.leave
	ret
FillInChartFormula	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateChartData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chart data block for a given chart.

CALLED BY:	SpreadsheetChartRange, SpreadsheetRecalcChart

PASS:		ds:si	= Spreadsheet instance
		ss:bp   = inherited SpreadsheetChartLocals
				SCL_enum.REP_bounds filled in

RETURN:		ax - data block VM handle
		carry - set if error

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Create a block

	block.nCols  = nColumns
	block.nRows  = nRows

	curCell = &block.cellHdr
	ptr = end of block.cellHdr

	Foreach cell in range:
	    curCell->ptr = ptr
	    ptr->cellType = cell.type
	    ptr = CopyCellData(cell,ptr)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateChartData	proc	near

	class	SpreadsheetClass

	uses	bx, cx, dx, bp, es

	.enter	inherit	SpreadsheetChartRange


	;
	; Allocate the parameter block
	;
	call	AllocParameterBlock		; bx <- block handle
						; es <- block segment
						; cx <- block size
	LONG jc	quit				; Branch if couldn't allocate

	mov	locals.SCL_block, bx		; Save block handle
	mov	locals.SCL_blockSize, cx	; Save block size
	
	;
	; Initialize it.
	;
	mov	es:CD_endOfData, cx

	mov	ax, locals.SCL_enum.REP_bounds.R_bottom
	sub	ax, locals.SCL_enum.REP_bounds.R_top
	inc	ax
	mov	es:CD_nRows, ax

	mov	cx, locals.SCL_enum.REP_bounds.R_right
	sub	cx, locals.SCL_enum.REP_bounds.R_left
	inc	cx
	mov	es:CD_nColumns, cx
	
	call	MemUnlock			; Release the block

	;
	; Set up the next cell ptr / data ptr
	;
	mov	locals.SCL_nextCellPtr, size ChartData

	mul	cx				; ax <- # of cells
	shl	ax, 1				; ax <- size of table
	
	add	ax, size ChartData	; Account for header
	mov	locals.SCL_nextCellData, ax
	
	; Set up callback address for RangeEnum

	mov	locals.SCL_enum.REP_callback.segment, SEGMENT_CS
	mov	locals.SCL_enum.REP_callback.offset, \
						offset CreateDataCallback
	
	;
	; Call a callback for each cell in the selection
	;
	lea	bx, locals.SCL_enum		; ss:bx <- RangeEnumParams
	mov	dl, mask REF_ALL_CELLS		; Callback for all cells
	call	RangeEnum			; Fill in the block

	jc	quitError			; Branch on error
	
	;
	; Resize the block down to the final size. This realloc should always
	; succeed since we are always making the block smaller or keeping it
	; the same size.
	;
	mov	ax, locals.SCL_nextCellData	; ax <- ptr past block end
	mov	bx, locals.SCL_block		; bx <- block handle
	clr	ch				; No HeapAllocFlags
	call	MemReAlloc			; ax <- segment address
	
	;
	; Associate the memory block with the VM file.
	;
	mov	cx, bx				; cx <- block handle
	clr	ax				; Allocate new vm block
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	VMAttach			; ax <- new vm block handle
	clc					; Signal no error
quit:
	;
	; Carry set on error
	; Carry clear otherwise, ax = VM block handle
	;
	.leave
	ret

quitError:
	;
	; Free up the block
	;
	mov	bx, locals.SCL_block
	call	MemFree
	stc					; Signal error again
	jmp	quit
CreateChartData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocParameterBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chart-parameter block

CALLED BY:	CreateChartData
PASS:		ds:si	= Spreadsheet instance
RETURN:		bx	= Block handle
		es	= Segment address of locked block
		cx	= Size of block
		carry set if the block couldn't be allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The size to allocate is:
		size ChartData
	      + size word * (nColumn * nRows)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocParameterBlock	proc	near
	class	SpreadsheetClass
	uses	ax, dx
locals	local	SpreadsheetChartLocals

	.enter	inherit 

	mov	ax, locals.SCL_enum.REP_bounds.R_bottom
	sub	ax, locals.SCL_enum.REP_bounds.R_top
	inc	ax
	
	mov	cx, locals.SCL_enum.REP_bounds.R_right	; cx <- nColumns
	sub	cx, locals.SCL_enum.REP_bounds.R_left
	inc	cx
	
	mul	cx					; ax <- nRows*nColumns
	shl	ax, 1					; size of a word
	
	add	ax, size ChartData		; Size of header

	;
	; ax = Size of block to allocate
	;
	push	ax					; Save size
	mov	cx, ALLOC_DYNAMIC_LOCK or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc				; bx <- block handle
							; ax <- segment address
	;
	; Carry set on error
	;
	pop	cx					; cx <- size of block
	mov	es, ax					; es <- segment address
	.leave
	ret
AllocParameterBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDataCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another cell to the parameters block

CALLED BY:	via RangeEnum
PASS:		ds:si	= Spreadsheet instance
		*es:di	= Cell data (if any)
		ax	= Row
		cx	= Column
		ss:bp	= SpreadsheetChartLocals
		carry clear if cell is empty
RETURN:		carry set on alloc error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	type  = cell type
	dsize = data size
	ptr   = nextCellData
	
	if (ptr + dsize + 1 > blockSize) {
	    ReAlloc block larger
	    if (error) {
	    	quit error
	    }
	}
	
	block.ptr.type = type
	CopyData(cellData, &block.ptr.data, dsize)
	
	nextCellPtr   = nextCellData
	nextCellData += dsize + 1
	nextCellPtr  += size word
	
	quit no error

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateDataCallback	proc	far
	uses	ax, bx, cx, dx, di, si, ds, es
locals	local	SpreadsheetChartLocals
	.enter	inherit 

	call	GetCellDataAndSize		; al <- cell type
						; cx <- cell data size
	;
	; al	= Cell type
	; cx	= Cell data size
	; *es:di= Cell (if it exists)
	;
	mov	bx, locals.SCL_block		; bx <- block handle

	mov	dx, locals.SCL_nextCellData	; dx <- ptr past data
	add	dx, cx
	;
	; Bail if we're going to wrap beyond 64K or even 16K
	;
	jc	quit				; branch if overflow
	cmp	dx, 1024*16
	ja	quitError			; branch if too large

	inc	dx				; +1 for ?
	
	cmp	dx, locals.SCL_blockSize	; Check for not enough block
	jbe	gotSpace
	
	call	ReAllocParamBlock		; Make block bigger
	jc	quit				; Branch if there's an error
	
	mov	locals.SCL_blockSize, dx	; Save new block size

gotSpace:
	;
	; There is enough space in the block. Lock it down and copy the data.
	;
	push	ax				; Save cell type
	call	MemLock				; ax <- segment address
	mov	ds, ax				; ds <- param block segment
	mov	si, locals.SCL_nextCellData	; ds:si <- place for data
	pop	ax				; Restore cell type
	
	;
	; al	= Cell type
	; bx	= Block handle
	; cx	= Size of cell data
	; ds:si	= Place to put cell data
	; locals.SCL_buffer = data to copy
	;
	push	cx, ds, si
	segmov	es, ds, di			; es:di <- ptr to buffer
	mov	di, si
	stosb					; Save the cell type

	jcxz	afterCopy			; Branch if no data
	segmov	ds, ss, si			; ds:si <- data
	lea	si, locals.SCL_buffer
	rep	movsb				; Copy the data
afterCopy:
	pop	cx, ds, si
	
	;
	; Update local variables
	;
	add	cx, locals.SCL_nextCellData	; cx <- offset past data
	inc	cx				; Account for type byte

	mov	locals.SCL_nextCellData, cx	; Save new end of data
	mov	ds:CD_endOfData, cx

	mov	di, locals.SCL_nextCellPtr	; di <- place to store ptr
	mov	{word} ds:[di], si		; Save ptr
	add	locals.SCL_nextCellPtr, size word
	
	;
	; Release the block
	;
	call	MemUnlock			; Release the parameter block
	
	clc					; Signal: no error
quit:
	.leave
	ret

quitError:
	stc					;carry <- error
	jmp	quit
CreateDataCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCellDataAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a pointer to a cell figure the type of the cell data
		and the size of the cell data.

CALLED BY:	CreateDataCallback
PASS:		*es:di	= Cell data
		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		ss:bp   = SpreadsheetChartLocals
		carry set if cell exists
RETURN:		al	= ChartDataCellType
		cx	= Size of data
		SCL_buffer filled with cell data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCellDataAndSize	proc	near
	uses	bx, di, bp
locals	local	SpreadsheetChartLocals
	.enter	inherit 

	jnc	noCell

	lea	bp, locals.SCL_buffer		; ss:bp <- destination buffer

	mov	di, es:[di]			; es:di <- cell data
	clr	bh				; bx <- cell type
	mov	bl, es:[di].CC_type
	call	cs:getDataHandler[bx]		; Call the handler

quit:
	.leave
	ret

noCell:
	mov	al, CDCT_EMPTY			; Empty cell
	clr	cx				; No data
	jmp	quit
GetCellDataAndSize	endp


getDataHandler	nptr	offset cs:GetTextCell,		; CT_TEXT
			offset cs:GetConstantCell,	; CT_CONSTANT
			offset cs:GetFormulaCell,	; CT_FORMULA
			offset cs:GetError,		; CT_NAME
			offset cs:GetError,		; CT_CHART
			offset cs:GetEmpty,		; CT_EMPTY
			offset cs:GetDisplayFormulaCell ; CT_DISPLAY_FORMULA

.assert (size getDataHandler) eq CellType

GetError	proc	near
	ERROR	UNEXPECTED_CELL_DATA_TYPE
GetError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text from a text cell.

CALLED BY:	GetCellDataAndSize
PASS:		es:di	= Cell data
		ds:si	= Spreadsheet instance
		ss:bp	= Buffer to fill with text
RETURN:		al	= Cell type
		cx	= Size of cell data
		Buffer filled with text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextCell	proc	near
	uses	di
	.enter
	add	di, size CellText		; es:di <- ptr to the text
	
	call	GetString			; Copy the string...
	.leave
	ret
GetTextCell	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string into a buffer

CALLED BY:	GetTextCell, GetFormulaCell
PASS:		ss:bp	= Buffer to fill
		es:di	= Text to copy
RETURN:		cx	= Length of text (including NULL)
		al	= CDCT_TEXT
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetString	proc	near
	uses	di, si, ds, es
	.enter

	call	GetStringSetup
	;
	; Copy the bytes, stopping after a NULL
	;
	push	di				; Save ptr to buffer start
	LocalCopyString
	pop	ax				; ax <- buffer start
	
	sub	di, ax				; di <- # of bytes copied

	mov	cx, di				; Return length in cx
	mov	al, CDCT_TEXT			; al <- type
	.leave
	ret
GetString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormulaString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a formula string into a buffer

CALLED BY:	GetFormulaCell()
PASS:		ss:bp	= Buffer to fill
		es:di	= Text to copy
		cx	= # of characters to copy
RETURN:		al	= CDCT_TEXT
		cx	= # of characters including NULL
DESTROYED:	ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/9/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormulaString	proc	near
	uses	di, si, ds, es
	.enter

	push	cx
	call	GetStringSetup
	LocalCopyNString
	pop	cx
	inc	cx				;cx <- +1 for NULL
	LocalLoadChar	ax, NULL
	LocalPutChar	esdi, ax
	mov	al, CDCT_TEXT			;al <- type

	.leave
	ret
GetFormulaString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup to copy a string into a buffer

CALLED BY:	GetString(), GetFormulaString()
PASS:		ss:bp	= buffer to fill
		es:di	= text to copy
RETURN:		ds:si	= text to copy
		es:di	= buffer to fill
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/9/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringSetup		proc	near
	.enter
	segmov	ds, ss, si			;ds:si <- ptr to buffer
	mov	si, bp

	segxchg	ds, es				;ds:si <- ptr to text
	xchg	di, si				;es:di <- ptr to buffer

	LocalGetChar ax, dssi, NO_ADVANCE	;ax <- character of string
SBCS<	cmp	al, C_SNG_QUOTE 				>
DBCS<	cmp	ax, C_APOSTROPHE_QUOTE  			>
	je	skipChar
SBCS<	cmp	al, C_QUOTE					>
DBCS<	cmp	ax, C_QUOTATION_MARK				>
	jne	doCopy
skipChar:
	LocalNextChar dssi			;skip initial quote
doCopy:

	.leave
	ret
GetStringSetup		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a constant cell into a buffer...

CALLED BY:	GetCellDataAndSize
PASS:		es:di	= Cell data
		ds:si	= Spreadsheet instance
		ss:bp	= Buffer to fill
RETURN:		al	= Cell type
		cx	= Size of data
		Buffer filled with the number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetConstantCell	proc	near
	uses	di
	.enter
	lea	di, es:[di].CC_current		; es:di <- Number to copy
	call	GetNumber			; al/cx <- Return values
	.leave
	ret
GetConstantCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a number to the buffer

CALLED BY:	GetConstantCell, GetFormulaCell
PASS:		es:di	= Number to copy
		ss:bp	= Buffer to put it in
RETURN:		cx	= size FloatNum
		al	= CDCT_NUMBER
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumber	proc	near
	uses	di, si, ds, es
	.enter
	segmov	ds, es, si			; ds:si <- source
	mov	si, di

	segmov	es, ss, di			; es:di <- dest
	mov	di, bp

	;
	; Copy the data
	;
	mov	cx, size FloatNum		; cx <- # of bytes
	rep	movsb				; Copy the data
	
	;
	; Return values
	;
	mov	cx, size FloatNum		; cx <- # of bytes
	mov	al, CDCT_NUMBER			; al <- type
	.leave
	ret
GetNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the result of a formula into the buffer

CALLED BY:	GetCellDataAndSize
PASS:		es:di	= Cell data
		ds:si	= Spreadsheet instance
		ss:bp	= Buffer to fill
RETURN:		al	= Cell type
		cx	= Size of data
		Buffer filled with the data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormulaCell	proc	near
	uses	bx, di, es
	.enter
	cmp	es:[di].CF_return, RT_VALUE
	je	copyConstant
	cmp	es:[di].CF_return, RT_TEXT
	je	copyText
	cmp	es:[di].CF_return, RT_ERROR
	je	copyError
	;
	; We shouldn't get here...
	;
EC <	ERROR	UNEXPECTED_CELL_DATA_TYPE			>

quit:
	.leave
	ret

copyConstant:
	;
	; Copy the constant into the buffer
	;
	lea	di, ds:[di].CF_current		; es:di <- Number to copy
	call	GetNumber			; al/cx <- Return values
	jmp	quit

copyText:
	;
	; Copy the text into the buffer
	;
	mov	cx, es:[di].CF_current.RV_TEXT
	mov	ax, es:[di].CF_formulaSize
	add	ax, size CellFormula
	add	di, ax				;es:di <- ptr to text
	
	call	GetFormulaString		;al/cx <- Return values
	jmp	quit

copyError:
	;
	; Format the error into the buffer
	;
	mov	bl, es:[di].CF_current.RV_ERROR
	segmov	es, ss, di			; es:di <- buffer ptr
	mov	di, bp
	call	CalcFormatError			; Format error into buffer
						; di <- ptr past buffer
	sub	di, bp				; di <- size

	mov	cx, di				; cx <- size
	mov	al, CDCT_TEXT			; al <- type
	jmp	quit
GetFormulaCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy an empty cell to the buffer.

CALLED BY:	GetCellDataAndSize
PASS:		es:di	= Cell data
		ds:si	= Spreadsheet instance
		ss:bp	= Buffer to fill
RETURN:		al	= Cell type
		cx	= Size of data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEmpty	proc	near
	mov	al, CDCT_EMPTY			; al <- type
	clr	cx				; cx <- data size
	ret
GetEmpty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the result of a display formula into the buffer

CALLED BY:	GetCellDataAndSize

PASS:		es:di	= Cell data
		ds:si	= Spreadsheet instance
		ss:bp	= Buffer to fill
RETURN:		al	= Cell type
		cx	= Size of data
		Buffer filled with the data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Format a "TYPE" error into the buffer and return that.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDisplayFormulaCell	proc	near
	uses	bx, di, es
	.enter
	mov	bl, CE_TYPE			; bl <- error code
	segmov	es, ss, di			; es:di <- buffer ptr
	mov	di, bp
	call	CalcFormatError			; Format error into buffer
						; di <- ptr past buffer
	sub	di, bp				; di <- size

	mov	cx, di				; cx <- size
	mov	al, CDCT_TEXT			; al <- type
	.leave
	ret
GetDisplayFormulaCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReAllocParamBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the chart parameter block

CALLED BY:	CreateDataCallback

PASS:		bx	= Block handle
		dx	= Minimum total size for the block
RETURN:		dx	= Size we realloc'd the block to
		carry set if we were unable to realloc
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	For now we just allocate as much space as we need an no more.
	At some time we may want to change this so that extra space is
	allocated.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReAllocParamBlock	proc	near
	uses	ax, cx
	.enter
	mov	ax, dx				; ax <- new size
	clr	ch				; No HeapAllocFlags
	call	MemReAlloc			; Make block bigger
	.leave
	ret
ReAllocParamBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRecalcChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a chart cell.

CALLED BY:	RecalcOneCell

PASS:		ds:si	= Instance ptr
		es:di	= Pointer to a chart cell
		ss:bp	= Pointer to PCT_vars on the stack
		cx	= column number of chart

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetRecalcChart	proc	far

locals	local	SpreadsheetChartLocals

	uses	ax,bx,cx,si,di
	class	SpreadsheetClass
	.enter	

EC <	call	ECCheckInstancePtr			>

	; No chart body, no chart!

	tst	ds:[si].SSI_chartBody.chunk
	jz	done

	; extract the range from the formula, and stick it in the
	; local variables structure, clearing the high bit.  Values
	; should be unsigned, so I won't worry about sign-extending. 

	mov	bx, CHART_TEMPLATE_RANGE_FIRST_CELL

	mov	ax, es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_row
	call	checkAndFixupAX
	mov	locals.SCL_enum.REP_bounds.R_top, ax

	mov	ax, es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_column
	call	checkAndFixupAX
	mov	locals.SCL_enum.REP_bounds.R_left, ax
	
	mov	bx, CHART_TEMPLATE_RANGE_SECOND_CELL

	mov	ax, es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_row
	call	checkAndFixupAX
	mov	locals.SCL_enum.REP_bounds.R_bottom, ax

	mov	ax, es:[di][bx].PT_data.PTD_cell.PTCD_cellRef.CR_column
	call	checkAndFixupAX
	mov	locals.SCL_enum.REP_bounds.R_right, ax

	lea	bx, locals.SCL_enum.REP_bounds
	call	FixupChartRecalcRange
	jc	noData

	; get chart's VM block handle

	mov	cx, {word} es:[di].CG_formula.CF_current

	; Create the parameters block

	call	CreateChartData
	jc	done
	mov_tr	dx, ax			; vm block of chart data

	mov	bx, ds:[si].SSI_chartBody.handle
	mov	si, ds:[si].SSI_chartBody.chunk

	mov	ax, MSG_META_SUSPEND
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage

	mov	ax, MSG_CHART_BODY_UPDATE_CHART
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage

	mov	ax, MSG_META_UNSUSPEND
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret

checkAndFixupAX:
	;
	; See if AX is bogus.  There's probably a constant for this,
	; but I don't know what it is.  If so, just bail, as we don't
	; have time for a more robust solution.
	;

	cmp	ax, 0xffff
	je	bogus
	andnf	ax, not mask CRC_ABSOLUTE
	retn

bogus:
	pop	ax		; nuke the return address -- we won't
				; be needing it
	jmp	done
	
noData:
	mov	bx, ds:[si].SSI_chartBody.handle
	mov	si, ds:[si].SSI_chartBody.chunk
	mov	ax, MSG_GB_DELETE_SELECTED_GROBJS
	clr	di
	call	ObjMessage
	jmp	done

SpreadsheetRecalcChart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupChartRecalcRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix cell range for recalculating a chart cell (removing
			empty cells)

CALLED BY:	SpreadsheetRecalcChart

PASS:		ds:si	= Instance ptr
		ss:bx	= Rectangle range to check

RETURN:		carry clear if ok
			ss:[bx] = fixed range
		carry set if no data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	 9/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupChartRecalcRange	proc	near
	uses	di, bp
extent		local	CellRange
reParams	local	RangeEnumParams

	.enter

; Used by called procedure.
ForceRef extent
ForceRef reParams

	push	bx
	mov	ax, ss:[bx].R_top
	mov	cx, ss:[bx].R_left
	mov	dx, ss:[bx].R_bottom
	mov	bx, ss:[bx].R_right
	mov	di, SET_NO_EMPTY_CELLS
	call	CallRangeExtent
	mov	di, bx				; di = R_right
	pop	bx				; ss:bx = range
	stc					; assume no data
	je	done				; yep, no data
	mov	ss:[bx].R_top, ax
	mov	ss:[bx].R_left, cx
	mov	ss:[bx].R_bottom, dx
	mov	ss:[bx].R_right, di
	clc
done:
	.leave
	ret
FixupChartRecalcRange	endp

endif
SpreadsheetChartCode	ends
