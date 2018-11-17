COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetColumn.asm

AUTHOR:		Gene Anderson, Aug 27, 1992

ROUTINES:
	Name			Description
	----			-----------
MSG_SPREADSHEET_SET_ROW_HEIGHT
MSG_SPREADSHEET_CHANGE_ROW_HEIGHT
MSG_SPREADSHEET_SET_COLUMN_WIDTH
MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH

    INT RecalcRowHeights	Recalculate row heights and baseline for
				selected rows
    INT RecalcRowHeightsInRange Recalculate the row-heights for a range of
				rows
    INT CalcRowHeight		Calculate the row height based on
				pointsizes in use
    INT FindMaxPointsize	Find the maximum pointsize of a row

    INT GetColumnsFromParams	Get columns to use from message parameters
    INT GetRowsFromParams	Get rows to use from message parameters


    INT GetColumnBestFit	Get the best fit for a column

    INT CellBestFit		Calculate the column width needed for one
				cell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/27/92		Initial revision


DESCRIPTION:
	Routines and method handlers for rows and columns.

	$Id: spreadsheetRowColumn.asm,v 1.1 97/04/07 11:13:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the row height of the current selection
CALLED BY:	MSG_SPREADSHEET_SET_ROW_HEIGHT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - row height (ROW_HEIGHT_AUTOMATIC or'd for automatic)
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or row #

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	The general rule for the baseline
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetRowHeight	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_SET_ROW_HEIGHT
	.enter

	call	SpreadsheetMarkBusy

	mov	si, di				;ds:si <- ptr to instance data
	call	GetRowsFromParams		;(ax,cx) <- range of rows
	jc	done

	;
	; For each row selected, set the height
	;
	mov	bx, dx
	andnf	dx, not (ROW_HEIGHT_AUTOMATIC)	;dx <- height
	andnf	bx, (ROW_HEIGHT_AUTOMATIC)	;bx <- flag
	push	ax
rowLoop:
	call	RowSetHeight
	inc	ax				;ax <- next row
	cmp	ax, cx				;at end?
	jbe	rowLoop				;branch while more rows
	pop	ax
	;
	; Recalculate the row heights
	;
	call	RecalcRowHeightsInRange
	;
	; Recalcuate the document size for the view, update the UI,
	; and redraw
	;
	mov	ax, mask SNF_CELL_WIDTH_HEIGHT
	call	UpdateDocUIRedrawAll
done:
	call	SpreadsheetMarkNotBusy

	.leave
	ret
SpreadsheetSetRowHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetChangeRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change height of a row
CALLED BY:	MSG_SPREADSHEET_CHANGE_ROW_HEIGHT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cx - change in row height
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or row #
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetChangeRowHeight	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_CHANGE_ROW_HEIGHT
	call	SpreadsheetMarkBusy

	mov	si, di				;ds:si <- ptr to spreadsheet
	mov	bp, cx				;bp <- change in height
	call	GetRowsFromParams		;(ax,cx) <- range of rows
	jc	done
	
	;
	; For each row, change the height
	;
	clr	bx				;bx <- no baseline
	push	ax
rowLoop:
	call	RowGetHeightFar			;dx <- current height
	add	dx, bp				;dx <- new height
	call	RowSetHeight
	inc	ax				;ax <- next row
	cmp	ax, cx				;at end?
	jbe	rowLoop
	pop	ax
	;
	; Recalculate the row heights
	;
	call	RecalcRowHeightsInRange
	;
	; Recalculate the document size for the view, update the UI,
	; and redraw
	;
	mov	ax, mask SNF_CELL_WIDTH_HEIGHT
	call	UpdateDocUIRedrawAll
done:
	call	SpreadsheetMarkNotBusy
	ret
SpreadsheetChangeRowHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcRowHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate row heights and baseline for selected rows
CALLED BY:	SpreadsheetSetRowHeight(), SpreadsheetSetPointsize()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecalcRowHeightsFar	proc	far
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; For each selected row, see if we should recalculate
	; the height based on the pointsize change.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_end.CR_row
	call	RecalcRowHeightsInRange
	.leave
	ret
RecalcRowHeightsFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcRowHeightsInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the row-heights for a range of rows.

CALLED BY:	RecalcRowHeights, SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ax	= Top row of range
		cx	= Bottom row of range
RETURN:		nothing
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcRowHeightsInRange	proc	far
	uses	di
	.enter
EC <	call	ECCheckInstancePtr		;>
	sub	cx, ax
	inc	cx				;cx <- # of rows to set
rowLoop:
	call	RowGetBaseline			;bx <- baseline and flag
	test	dx, ROW_HEIGHT_AUTOMATIC	;automatic height?
	jz	manualHeight			;branch if manual
	call	CalcRowHeight			;calculate row height
	ornf	bx, ROW_HEIGHT_AUTOMATIC	;bx <- set as automatic
setHeight:
	call	RowSetHeight
	inc	ax				;ax <- next row
	loop	rowLoop

	.leave
	ret

	;
	; The row height is marked as manual.  We still
	; need to calculate the baseline, but the height
	; remains unchanged.
	;
manualHeight:
	push	ax
	call	RowGetHeightFar			;dx <- current row height
	push	dx
	call	CalcRowHeight			;bx <- baseline
	mov	ax, dx				;ax <- calculated height
	pop	dx				;dx <- current row height
	add	bx, dx				;bx <- baseline = baseline
	sub	bx, ax				;	+ (height - calculated)
	pop	ax
	jns	setHeight			;baseline above bottom
						;  of cell?
	clr	bx				;if not, Sbaseline = 0
	jmp	setHeight
RecalcRowHeightsInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the row height based on pointsizes in use
CALLED BY:	SpreadsheetSetRowHeight()

PASS:		ds:si - ptr to Spreadsheet instance data
		ax - row #
RETURN:		dx - new row height
		bx - new baseline offset
DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:
	row_height = MAX(pointsize) * 1.25
	baseline = MAX(pointsize) - 1

	NOTE: in order to include pointsize in the optimizations used
	for setting attributes on an entire column, this routine will
	need to change a fair amount...
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcRowHeight	proc	near
	uses	ax, cx, es
	class	SpreadsheetClass

locals	local	CellLocals

	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ax
	mov	cx, MIN_ROW
	mov	dx, ds:[si].SSI_maxCol		;(ax,bx,cx,dx) <- range to enum

	mov	ss:locals.CL_data1, cx		;pass data word #1

	clr	di				;di <- RangeEnumFlags
	mov	ss:locals.CL_data2, di		;pass data word #2

	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset FindMaxPointsize

	call	CallRangeEnum			;ax <- max pointsize * 8
	;
	; See if all cells had data.  If not, we need to take into account
	; the default pointsize, as that is what empty cells have.
	;
	cmp	ss:locals.CL_data2, dx		;all cells have data?
	je	noEmptyCells			;branch if all cells filled
	mov	ax, DEFAULT_STYLE_TOKEN		;ax <- style to get
	mov	bx, offset CA_pointsize		;bx <- CellAttrs field
	call	StyleGetAttrByTokenFar		;ax <- pointsize
	cmp	ax, ss:locals.CL_data1		;larger than maximum?
	ja	defaultIsMax			;branch if new maximum
noEmptyCells:
	mov	ax, ss:locals.CL_data1		;ax <- (pointsize * 8)
defaultIsMax:
	mov	dx, ax				;dx <- (pointsize * 8)
	mov	bx, ax
	shr	bx, 1
	shr	bx, 1				;bx <- (pointsize * 8) / 4
	add	dx, bx				;dx <- (pointsize * 8) * 1.25

	dec	ax				;ax <- pointsize - 1
	mov	bx, ax				;bx <- pointsize - 1
	
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1				;dx <- new row height
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1				;bx <- new baseline

	.leave
	ret
CalcRowHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMaxPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the maximum pointsize of a row.
CALLED BY:	CalcRowHeight() via RangeEnum()

PASS:		(ax,cx) - current cell (r,c)
		bx - handle of file
		ss:bp - ptr to CellLocals variables
			CL_data1 - maximum pointsize
			CL_data2 - # of cells called back for
		*es:di - ptr to cell data, if any
		ds:si - ptr to Spreadsheet instance
		carry - set if cell has data
RETURN:		carry - set to abort enumeration
			CL_data1 - (new) maximum pointsize
			CL_data2 -  # of cells, updated
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindMaxPointsize	proc	far
	uses	ax, bx, cx, dx, si, di, ds, es
locals		local	CellLocals
	.enter	inherit

EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			;es:di <- ptr to cell
	mov	ax, es:[di].CC_attrs		;ax <- style token
	segmov	es, ss
	lea	di, ss:locals.CL_cellAttrs	;es:di <- ptr to style buffer
	call	StyleGetStyleByTokenFar
	mov	ax, ss:locals.CL_cellAttrs.CA_pointsize
	cmp	ax, ss:locals.CL_data1		;larger pointsize?
	jbe	notBigger
	mov	ss:locals.CL_data1, ax		;store new maximum pointsize
notBigger:

	clc					;carry <- don't abort

	.leave
	ret

FindMaxPointsize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetColumnWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the column width for selected columns
CALLED BY:	MSG_SPREADSHEET_SET_COLUMN_WIDTH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
		cx - column width
		COLUMN_WIDTH_BEST_FIT - OR'ed for best fit
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or row #

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetColumnWidth	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_SET_COLUMN_WIDTH
	.enter

	call	SpreadsheetMarkBusy

	mov	si, di				;ds:si <- ptr to instance
	call	GetColumnsFromParams		;(cx,ax) <- columns
	jc	done

	test	dx, COLUMN_WIDTH_BEST_FIT
	jnz	getBestFit
	RoundToByte dx				;dx <- round to byte multiple
	;
	; HACK: if the rounding the new column will give the current column
	; width, send out bogus notification with the unrounded column width
	; so that when we send out notification with the rounded column
	; width, the GCN list mechanism won't ignore it because the new column
	; width notification is the same as the current column width
	; notification.  We want the new column width notification to occur
	; because the column width controller is still display the unrounded
	; column width that the user just entered - brianc 10/11/94
	;	dx = new rounded column width
	;
	mov	bx, dx				;bx = new rounded column width
	call	ColumnGetWidthFar		;dx = current width
	xchg	bx, dx				;dx = new rounded column width
						;bx = current width
	cmp	bx, dx				;same?
	jne	columnLoop			;nope, notification will work
	call	SS_SendNotificationBogusWidth	;else, send bogus notif first
columnLoop:
	call	ColumnSetWidth
	inc	cx				;cx <- next column
	cmp	cx, ax				;end of selection?
	jbe	columnLoop			;branch while more columns
	;
	; Recalcuate the document size for the view, update the UI,
	; and redraw
	;
doneColumns:
	mov	ax, mask SNF_CELL_WIDTH_HEIGHT
	call	UpdateDocUIRedrawAll

done:
	call	SpreadsheetMarkNotBusy

	.leave
	ret

	;
	; Find the width of all the strings in the column and set the
	; width based on them.
	;
getBestFit:
	call	GetColumnBestFit
	cmp	dx, 0				;no data?
	je	noData				;branch if no data
	add	dx, 7				;dx <- always round up
	RoundToByte dx				;dx <- round to byte multiple
	cmp	dx, SS_COLUMN_WIDTH_MAX		;width too large?
	jbe	widthOK				;branch if OK
	mov	dx, SS_COLUMN_WIDTH_MAX		;dx <- set to maximum width
widthOK:
	call	ColumnSetWidth
	inc	cx				;cx <- next column
	cmp	cx, ax				;end of selection?
	jbe	getBestFit
	jmp	doneColumns

	;
	; The column had no data -- set the width to the default
	;
noData:
	mov	dx, COLUMN_WIDTH_DEFAULT
	jmp	widthOK
SpreadsheetSetColumnWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetChangeColumnWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the selected columns wider/narrower
CALLED BY:	MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - change in column widths
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or column #

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetChangeColumnWidth	method dynamic SpreadsheetClass, \
				MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH
	.enter

	call	SpreadsheetMarkBusy

	mov	bx, cx				;bx <- delta for widths
	mov	si, di				;ds:si <- ptr to instance

	call	GetColumnsFromParams		;(cx,ax) <- columns to use
	jc	done
		
columnLoop:
	;
	; bx = Amount to change the column width by.
	;
	call	ColumnGetWidthFar		;dx <- column width
	add	dx, bx				;dx <- new column width
	;
	; Make sure that the column isn't too narrow/wide.
	;
	jns	notTooNarrow			;branch if not too negative
	clr	dx				;new width
notTooNarrow:

	cmp	dx, SS_COLUMN_WIDTH_MAX		;check for too wide
	jbe	notTooWide			;branch if not too wide
	mov	dx, SS_COLUMN_WIDTH_MAX		;new width
notTooWide:
	RoundToByte dx				;dx <- round to byte multiple
	;
	; dx = new column width.
	;
	call	ColumnSetWidth			;set new width
	inc	cx				;cx <- next column
	cmp	cx, ax				;end of selection?
	jbe	columnLoop			;branch while more columns
	;
	; Recalcuate the document size for the view, update the UI,
	; and redraw
	;
	mov	ax, mask SNF_CELL_WIDTH_HEIGHT
	call	UpdateDocUIRedrawAll
done:
	call	SpreadsheetMarkNotBusy

	.leave
	ret
SpreadsheetChangeColumnWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColumnsFromParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get columns to use from message parameters
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or column #
RETURN:		dx - old cx
		cx - start column
		ax - end column
		carry SET if column range invalid

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetColumnsFromParams	proc	near
	class	SpreadsheetClass
	uses	bx
	.enter

	push	cx
	;
	; Assume using the passed column
	;
	mov	cx, dx				;cx <- start column
	mov	ax, dx				;ax <- end column
	cmp	ax, SPREADSHEET_ADDRESS_USE_SELECTION
	jne	done
	;
	; Use current selection
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
done:
	pop	dx				;dx <- old cx

	xchg	ax, cx
	mov	bx, offset SDO_rowCol.CR_column
	call	CheckMinRowOrColumn
	xchg	ax, cx


	.leave
	ret
GetColumnsFromParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRowsFromParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rows to use from message parameters
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		dx - SPREADSHEET_ADDRESS_USE_SELECTION or row #
RETURN:		dx - old cx
		ax - start row
		cx - end row
		carry SET if range invalid

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRowsFromParams	proc	near
	class	SpreadsheetClass
	uses	bx
	.enter

	push	cx
	;
	; Assume using the passed row
	;
	mov	ax, dx				;ax <- start row
	mov	cx, dx				;cx <- end row
	cmp	ax, SPREADSHEET_ADDRESS_USE_SELECTION
	jne	done
	;
	; Use current selection
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_end.CR_row
done:
	pop	dx				;dx <- old cx

	mov	bx, offset SDO_rowCol.CR_row
	call	CheckMinRowOrColumn

	.leave
	ret
GetRowsFromParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMinRowOrColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the passed pair of rows or columns against the
		spreadsheet's minimum

CALLED BY:	GetRowsFromParams, GetColumnsFromParams

PASS:		(ax, cx) - min, max pair
		bx - offset to vardata to check
		ds:si - pointer to spreadsheet instance data

RETURN:		if range invalid:
			carry SET
		else:
			ax - fixed up if necessary
		
DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMinRowOrColumn	proc near
		class	SpreadsheetClass

		uses	si

		.enter

		test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
		jz	checkZero

		push	ax, bx			; offset to vardata field

		mov	si, ds:[si].SSI_chunk
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		call	ObjVarFindData
		pop	ax, si

		jnc	checkZero

		mov	bx, ds:[bx][si]		; min row or column
checkMin:
		cmp	cx, bx
		stc
		jl	done			; entire range is bad


		cmp	ax, bx
		jg	done
	;
	; Beginning of range needs to be moved up
	;
		mov	ax, bx
		
done:
		.leave
		ret
checkZero:
		clr	bx
		jmp	checkMin
CheckMinRowOrColumn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColumnBestFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the best fit for a column

CALLED BY:	SpreadsheetSetColumnWidth()
PASS:		ds:si - ptr to Spreadsheet instance
		cx - column #
RETURN:		dx - best column width
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetColumnBestFit		proc	near
	uses	ax
	class	SpreadsheetClass
locals	local	CellLocals
	.enter

	clr	ax
	mov	bx, ds:[si].SSI_maxRow
	mov	dx, cx				;(ax,cx),(bx,dx) <- range
	call	CreateGStateFar
	mov	ss:locals.CL_gstate, di		;pass GState
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CellBestFit
	clr	ss:locals.CL_data1		;<- maximum width so far
	clr	di				;di <- RangeEnumFlags
	call	CallRangeEnum
	;
	; Return the maximum we found
	;
	mov	dx, ss:locals.CL_data1		;dx <- maximum width found

	call	DestroyGStateFar

	.leave
	ret
GetColumnBestFit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellBestFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the column width needed for one cell

CALLED BY:	GetColumnBestFit() via RangeEnum()
PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any

		CL_data1 - maximum width so far

RETURN:		carry - set to abort enum
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeBadCellType	proc	near
EC <	ERROR	ILLEGAL_CELL_TYPE >
NEC <	ret			  >
SizeBadCellType	endp

cellSizeRoutines	nptr \
	SizeTextCell,			;CT_TEXT
	SizeConstantCell,		;CT_CONSTANT
	SizeFormulaCell,		;CT_FORMULA
	SizeBadCellType,		;CT_NAME
	SizeBadCellType,		;CT_CHART
	SizeBadCellType,		;CT_EMPTY
	SizeDisplayFormulaCell		;CT_DISPLAY_FORMULA
CheckHack <(size cellSizeRoutines) eq CellType>

CellBestFit		proc	far
	uses	ax, bx, cx, dx, si, di, ds, es
locals	local	CellLocals
	.enter	inherit

EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>

	mov	bx, ss:locals.CL_gstate		;bx <- GState to draw with
	xchg	bx, di				;*es:bx <- ptr to cell data
						;di <- GState to use
	;
	; Set up the GState based on the current cell attributes
	;
	mov	bx, es:[bx]			;es:bx <- ptr to cell data
	mov	dx, es:[bx].CC_attrs		;dx <- cell style attrs
	call	SetCellGStateAttrsFar		;setup GState, locals correctly
	;
	; Get a pointer to the cell data and the type
	;
	mov	dx, bx				;es:dx <- ptr to cell data
	mov	bl, es:[bx].CC_type
	cmp	bl, CT_EMPTY			;no data?
	je	done				;branch if empty
	clr	bh				;bx <- cell type
	;
	; Get the data in text format
	;
	call	cs:cellSizeRoutines[bx]		;ds:si <- ptr to text
	;
	; Get the width of the text string, and see if it is a new largest value
	;
	clr	cx				;cx <- text is NULL terminated
	call	GrTextWidth			;dx <- width
	add	dx, (CELL_INSET)*2
	cmp	dx, ss:locals.CL_data1		;largest so far?
	jbe	done				;branch if not largest
	mov	ss:locals.CL_data1, dx		;store new largest
done:
	clc					;carry <- don't abort

	.leave
	ret
CellBestFit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeTextCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text for a text cell for calculating size

CALLED BY:	CellBestFit()
PASS:		es:dx - ptr to cell data
RETURN:		ds:si - ptr text string
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SizeTextCell		proc	near
	.enter
	segmov	ds, es

	mov	si, dx				;ds:si <- ptr to cell data
	add	si, (size CellText)		;ds:si <- ptr to string

	.leave
	ret
SizeTextCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text for a constant cell

CALLED BY:	CellBestFit()
PASS:		es:dx - ptr to cell data
		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited CellLocals
RETURN:		ds:si - ptr to text string
DESTROYED:	ax, bx, cx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SizeConstantCell		proc	near
	class	SpreadsheetClass
	uses	di
	locals	local	CellLocals
	.enter	inherit

	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, ds:[si].SSI_formatArray

	segmov	ds, es, ax
	mov	si, dx
	add	si, offset CC_current		;ds:si <- ptr to float number
	segmov	es, ss, ax
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to the buffer

	mov	ax, ss:locals.CL_cellAttrs.CA_format
	call	FloatFormatNumber		;convert to ASCII

	segmov	ds, ss
	mov	si, di				;ds:si <- ptr to result string

	.leave
	ret
SizeConstantCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text for a formula cell

CALLED BY:	CellBestFit()
PASS:		es:dx - ptr to cell data
		(ax,cx) - (r,c) of cell
		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited CellLocals
RETURN:		ds:si - ptr to text string
DESTROYED:	ax, bx, cx, dx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SizeFormulaCell		proc	near
	uses	di, bp
locals	local	CellLocals
	.enter	inherit

	lea	di, ss:locals.CL_buffer		;ss:di <- ptr to dest buffer

	mov	bp, dx				;dx:bp <- ptr to cell data
	mov	dx, es

	segmov	es, ss				;es:di <- ptr to dest buffer

	call	FormulaCellGetResult

	segmov	ds, es, si
	mov	si, di				;ds:si <- ptr to text

	.leave
	ret
SizeFormulaCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeDisplayFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text for a display formula cell

CALLED BY:	CellBestFit()
PASS:		es:dx - ptr to cell data
		(ax,cx) - (r,c) of cell
		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited CellLocals
RETURN:		ds:si - ptr to text string
DESTROYED:	ax, bx, cx, dx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SizeDisplayFormulaCell		proc	near
	uses	di, bp
locals	local	CellLocals
	.enter	inherit

	lea	di, ss:locals.CL_buffer		;ss:di <- ptr to dest buffer

	mov	bp, dx				;dx:bp <- ptr to cell data
	mov	dx, es

	segmov	es, ss				;es:di <- ptr to dest buffer

	call	FormulaDisplayCellGetResult

	segmov	ds, es, si
	mov	si, di				;ds:si <- ptr to text

	.leave
	ret
SizeDisplayFormulaCell		endp

AttrCode	ends
