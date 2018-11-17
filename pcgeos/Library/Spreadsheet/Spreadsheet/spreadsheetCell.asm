COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetCell.asm

AUTHOR:		Gene Anderson, Feb 27, 1991

ROUTINES:
	Name			Description
	----			-----------
    EXT DeleteCell		Delete a cell's data and associated
				resources (don't redraw)

    EXT GetCellAttrs		Get cell style attributes, if it exists

    EXT AllocCellCommon		Common code to allocate a cell

    EXT AllocEmptyCell		Allocate and initialize an "empty" cell

    EXT AllocConstantCell	Allocate a numeric constant cell.

    EXT AllocTextCell		Allocate and initialize a text cell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/27/91		Initial revision

DESCRIPTION:
	Routines for allocating and freeing cells of different types

	$Id: spreadsheetCell.asm,v 1.1 97/04/07 11:14:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a cell's data and associated resources (don't redraw)
CALLED BY:	UTILITY

PASS:		(ax,cx) - cell (r,c) to delete
		ds:si - ptr to Spreadsheet instance data
		dl - RangeEnumFlags
RETURN:		carry - set if cell really deleted
		dl - RangeEnumFlags
			REF_CELL_FREED - if cell freed
			REF_OTHER_ALLOC_OR_FREE - if cell was formula
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: does not delete the cell entirely if there is a dependency list,
	cell notes, or non-default style attributes.
	NOTE: does not redraw the cell or recalculate its dependencies.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteCell	proc	far
	uses	ax, bx, di, es
	class	SpreadsheetClass
	.enter

	mov	bx, dx				;bl <- RangeEnumFlags
	SpreadsheetCellLock
	jnc	quit				;branch if no data
	mov	di, es:[di]			;es:di <- ptr to cell data
	;
	; See if the cell has:
	; - dependencies
	; - notes
	; - non-default cell attributes
	; and do not delete it completely if any of these is true.
	;
	tst	es:[di].CC_dependencies.segment	;check for dependencies
	jnz	replaceWithEmptyCell		;branch if has dependencies
	tst	es:[di].CC_notes.segment	;check for notes
	jnz	replaceWithEmptyCellNoDep	;branch if has notes
	;
	; NOTE: this uses the default column attrs, not DEFAULT_STYLE_TOKEN
	; because we don't want the cell to go away if when it is
	; next created it would have lost the DEFAULT_STYLE_TOKEN attributes
	; and instead picked up the default column attrs, so we can delete
	; the whole thing if it has the default column attrs.
	;
	call	ColumnGetDefaultAttrs		;dx <- default column attrs
	cmp	es:[di].CC_attrs, dx		;default attrs?
	jne	replaceWithEmptyCellNoDep
	;
	; Decrement the style token ID reference
	;
	push	ax
	mov	ax, dx				;ax <- current attr
	call	StyleDeleteStyleByTokenFar
	pop	ax
	;
	; Remove any dependencies any old formula might have had.
	;
	mov	dx, -1				;signal: remove dependencies
	call	FormulaCellAddParserRemoveDependencies
	ornf	bl, mask REF_OTHER_ALLOC_OR_FREE ;bl <- other cells freed
	;
	; All done with the cell.  Unlock the cell before nuking it.
	;
	SpreadsheetCellUnlock			;unlock the cell
	;
	; Replace cell data with nothing.
	;
	clr	dx				;dx <- no data
	SpreadsheetCellReplaceAll
	ornf	bl, mask REF_CELL_FREED		;bl <- cell freed
	stc					;carry <- cell deleted
quit:
	mov	dx, bx				;dl <- RangeEnumFlags
	.leave
	ret


	;
	; We know the cell doesn't have any dependents, because of
	; the order of the checks above.  If it isn't a formula cell,
	; it doesn't have any precedents, either.
	;
replaceWithEmptyCellNoDep:
	cmp	es:[di].CC_type, CT_FORMULA	;formula cell?
	jne	skipRemove			;branch if not formula cell
replaceWithEmptyCell:
	;
	; The cell is being removed, but it has dependencies. We want to
	; nuke all the cell data leaving an empty cell and its dependency
	; list.
	;
	; ds:si = instance ptr
	; es:di = ptr to the cell data
	; ax/cx = row/column of the cell
	; bx	= file handle
	;
	mov	dx, -1				;signal: remove dependencies
	call	FormulaCellAddParserRemoveDependencies
	ornf	bl, mask REF_OTHER_ALLOC_OR_FREE ;bl <- other cells freed
skipRemove:
	SpreadsheetCellUnlock			;release the cell
	clr	dx				;dx <- extra data size
	call	SpreadsheetCellResizeData	;change the data part...
	SpreadsheetCellLock			;*es:di <- cell ptr
	mov	di, es:[di]			;es:di <- cell ptr
	;
	; es:di = ptr to the cell data.
	; We need to set it to be an empty cell.
	;
	mov	es:[di].CC_type, CT_EMPTY	;cell is empty thanks.
	SpreadsheetCellDirty			;mark the cell as dirty
	SpreadsheetCellUnlock			;unlock the cell data
	clc					;carry <- cell not deleted
	jmp	quit
DeleteCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurCellAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current style attributes for a cell if it exists
		(or what they would be if it did)

CALLED BY:	UTILITY
PASS:		ds:si - ptr ot Spreadsheet instance data
		(ax,cx) - cell (r,c) to get
RETURN:		ax - style token
		carry - set if cell exists
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: unlike GetNewCellAttrs(), this does not up any reference counts
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurCellAttrs		proc	far
	uses	es, di, dx
	.enter

	SpreadsheetCellLock
	jnc	noData				;branch if cell doesn't exist
	;
	; The cell exists -- get its current attributes
	;
	mov	di, es:[di]			;es:di <- ptr to CellCommon
	mov	ax, es:[di].CC_attrs
	SpreadsheetCellUnlock
done:

	.leave
	ret

	;
	; The cell doesn't exist -- get the column default
	; NOTE: this uses the column default attrs and not DEFAULT_STYLE_TOKEN
	; because the default column attrs are what the cell will be
	; created with, and hence what its current state is.
	;
noData:
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- default attrs for cell
	clc					;carry <- cell doesn't exist
	jmp	done
GetCurCellAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNewCellAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current style attributes for a cell if it exists
		or what they will be when it is created.

CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		(ax,cx) - cell (r,c) to get
		ss:bx - ptr to CellAttrs
			-OR-
		bx - 0 to use current attrs (default attrs for new cells)
RETURN:		carry - set if cell exists
		bx - style token ID (default if cell doesn't exist)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: if the cell does not exist (or even if it does and
	a non-default style structure was passed), the reference
	count on the style that is returned will be upped.  Because
	of this, you should probably only call this routine when
	creating cells or replacing existing cells.
	NOTE: if the cell exists and a non-default attribute is
	passed, nothing is done with the reference count on the
	old style token -- if you are going to replace the cell, the
	reference count should be dealt with...
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewCellAttrsFar	proc	far
	call	CreateNewCellAttrs
	ret
CreateNewCellAttrsFar	endp

CreateNewCellAttrs	proc	near
	uses	es, di, ax, dx
	class	SpreadsheetClass
	.enter

EC <	tst	bx				;>
EC <	jz	attrsOK				;>
EC <	cmp	bx, sp				;>
EC <	ERROR_BE BAD_CELL_ATTRS			;>
EC <attrsOK:					;>

	;
	; See if the cell exists
	;
	SpreadsheetCellLock			;lock cell
	;
	; Any passed style?
	;
	pushf
	tst	bx				;any passed attributes?
	jnz	passedStyles			;branch if passed attributes
	popf					;carry <- cell exists flag
	jnc	newCell				;branch if no data
	;
	; The cell exists -- get the current token
	;
	mov	di, es:[di]			;es:di <- ptr to cell
	mov	ax, es:[di].CC_attrs		;ax <- cell style
	;
	; Done with the cell data
	;
doneUnlock:
	SpreadsheetCellUnlock			;preserves carry set
	jmp	done

	;
	; There is no cell data -- use the default style token for this
	; column.
	;
newCell:
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- default for column
	call	StyleGetTokenByToken		;one more reference...
	clc					;carry <- cell doesn't exist
done:
	mov	bx, ax				;bx <- style token

	.leave
	ret

	;
	; We were passed a style -- get the new token
	;
passedStyles:
	push	es
	segmov	es, ss, di
	mov	di, bx				;es:di <- CellAttrs
	call	StyleGetTokenByStyleFar		;ax <- style token
	pop	es
	popf					;carry <- cell exists flag
	jc	doneUnlock			;branch if cell exists
	jmp	done
CreateNewCellAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocCellCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to allocate a cell
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cl) - (r,c) of cell
		ch - CellType
		dx - size of data (w/o CellCommon)
		es:di - ptr to data
		ss:bx - ptr to CellAttrs
			-OR-
		bx - 0 to use current attrs (default attrs for new cells)
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/18/92		Initial version
	witt	11/8/93		DBCS-ized, dx is *size* of data (byte count)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; table of the size of the header of each cell type, minus the data
;
cellHeadSizeTable	word \
	(size CellText),		;CT_TEXT
	(size CellConstant)-(size CC_current), ;CT_CONSTANT
	(0x8000),			;CT_FORMULA (separate)
	(0x8000),			;CT_NAME
	(0x8000),			;CT_CHART
	(size CellEmpty),		;CT_EMPTY
	(0x8000)			;CT_DISPLAY_FORMULA
CheckHack <(size cellHeadSizeTable) eq CellType>

AllocCellCommon	proc	far
	uses	ax, bx, cx, es, di
	class	SpreadsheetClass
SBCS< cellData	local	MAX_CELL_TEXT_LENGTH+1 dup(char)	>
DBCS< cellData	local	MAX_CELL_TEXT_LENGTH+1 dup(wchar)	>
cellStruct	local	CellCommon
CheckHack <(offset cellData) eq (offset cellStruct)+(size cellStruct)>
	.enter

EC <	call	ECCheckInstancePtr		;>
if DBCS_PCGEOS
 if ERROR_CHECK
	cmp	ch, CT_TEXT
	jne	dbcs_cont
	test	dx, 1				; test CT_TEXT size for oddness
	ERROR_NZ CELL_DATA_STRING_ODDSIZE
dbcs_cont:
 endif
endif
	;
	; Save the type here so we can clear out ch (to get cx == column) and
	; then get at the type later if we need it.
	;
	mov	ss:cellStruct.CC_type, ch	;<- CellType
	clr	ch				;cx <- column

	;
	; Get the attribute token and see if the cell exists
	;
	call	CreateNewCellAttrs		;bx <- current/new cell attrs
	jc	cellExists			;branch if cell exists
	;
	; The cell doesn't exist -- create a new one
	;
	clr	ss:cellStruct.CC_dependencies.segment	;<- no dependencies
	clr	ss:cellStruct.CC_notes.segment	;<- no notes
	clr	ss:cellStruct.CC_recalcFlags	;<- no recalc flags
	mov	ss:cellStruct.CC_attrs, bx
	;
	; Copy the data to immediately follow the CellCommon structure
	;
	push	cx
	mov	cx, dx				;cx <- size of data
	jcxz	noData				;branch if no data
	push	ds, si
	segmov	ds, es
	mov	si, di				;ds:si <- ptr to data
	segmov	es, ss
	lea	di, ss:cellData			;es:di <- ptr to buffer
	rep	movsb
	pop	ds, si
noData:
	pop	cx
	;
	; Calculate the total size
	;
	clr	bx
	mov	bl, ss:cellStruct.CC_type	;bx <- type of cell
EC <	cmp	cs:cellHeadSizeTable[bx], 0x8000	;>
EC <	ERROR_E	ILLEGAL_CELL_TYPE_FOR_ALLOC	;>
	add	dx, cs:cellHeadSizeTable[bx]	;dx <- new size of cell
	segmov	es, ss
	lea	di, ss:cellStruct		;es:di <- ptr to "cell"
	;
	; Create the new cell
	;	es:di - ptr to CellCommon and following data
	;	dx - size of CellCommon and following data
	;
	SpreadsheetCellReplaceAll
done:

	.leave
	ret

	;
	; The cell already exists, so convert to the new type
	;
cellExists:
	push	bx				;save cell attrs
	;
	; Nuke any related dependencies (either dependents or precedents)
	;
	push	dx				;save data size & type
	mov	dx, -1				;signal: remove dependencies
	call	FormulaCellAddParserRemoveDependencies
	pop	dx				;restore data size & type
	;
	; Resize the data portion of the cell
	;
	push	dx
	clr	bx
	mov	bl, ss:cellStruct.CC_type	;bx <- index of type
EC <	cmp	cs:cellHeadSizeTable[bx], 0x8000	;>
EC <	ERROR_E	ILLEGAL_CELL_TYPE_FOR_ALLOC	;>
	call	SpreadsheetCellResizeData	;change the data part
	pop	dx
	;
	; Lock the cell
	;
	pop	bx				;bx <- cell attrs
	push	ds, si				;save instance ptr
	push	es, di				;save ptr to string

	SpreadsheetCellLock			;*es:di <- ptr to the cell
	mov	di, es:[di]			;es:di <- ptr to the cell
	;
	; Set the new type & style
	;
	mov	ax, bx				;ax <- new style token
	xchg	es:[di].CC_attrs, ax		;ax <- old style token
	
	push	ax
	mov	al, ss:cellStruct.CC_type
	mov	es:[di].CC_type, al		;set the type
	pop	ax

	;
	; Decrement the reference count on the old style if we're changing...
	;
	cmp	ax, bx				;changed styles?
	je	skipStyleDelete			;branch if no change
	call	StyleDeleteStyleByTokenFar
skipStyleDelete:
	;
	; Copy the data
	;
	add	di, size CellCommon		;es:di <- ptr to destination
	pop	ds, si				;ds:si <- ptr to the string
	mov	cx, dx				;cx <- # of bytes to copy

	rep	movsb				;copy the data

	pop	ds, si				;restore instance ptr
	;
	; We've changed the cell data -- make sure it is dirty, even if
	; it didn't change size.
	;
	SpreadsheetCellDirty			;dirty the cell
	SpreadsheetCellUnlock			;unlock the cell data
	jmp	done
AllocCellCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize an "empty" cell
CALLED BY:	UTILITY

PASS:		ds:si - ptr to SpreadsheetClass instance data
		(ax,cx) - cell (r,c) to allocate
		ss:bx - ptr to CellAttrs
			-OR-
		bx - 0 to use current attrs (default attrs for new cells)
RETURN:		nothing
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocEmptyCell	proc	far
	uses	cx, dx
	.enter

	mov	ch, CT_EMPTY		;ch <- CellType
	clr	dx			;dx <- size
	call	AllocCellCommon		;allocate the cell

	.leave
	ret
AllocEmptyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocConstantCellFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a numeric constant cell by parsing text.

CALLED BY:	UTILITY (EnterDataFromEditBar)
PASS:		es:di	= text to parse
		dx	= Length (glyph count) of the text
		ds:si	= Spreadsheet instance
		ax/cx	= Row/Column of the cell
		ss:bx - ptr to CellAttrs
			-OR-
		   bx - 0 to use current attrs (default attrs for new cells)
RETURN:		carry - set if parse error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version
	witt	11/ 8/93	DBCS-ized, dx takes string *length*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocConstantCellFromText	proc	near
	uses	cx, dx, es, di
numBuf	local	FloatNum
	.enter

	;
	; Try to convert the text to a number
	;
	push	ds, si, ax, cx			;save instance ptr, (r,c)

	segmov	ds, es, si
	mov	si, di				;ds:si <- ptr to text
	segmov	es, ss, di
	lea	di, ss:numBuf			;es:di <- ptr to destination
	mov	cx, dx				;dx <- # of chars

	mov	al, mask FAF_STORE_NUMBER	;al <- save result in memory
	call	FloatAsciiToFloat		;convert the number
	pop	ds, si, ax, cx			;restore instance ptr, (r,c)
	jc	quit				;quit if it doesn't parse
	;
	; We've successfully parsed the number -- store it in the cell 
	;
	mov	ch, CT_CONSTANT			;ch <- type
	mov	dx, size FloatNum		;dx <- size
	call	AllocCellCommon

	clc					;carry <- no error
quit:
	.leave
	ret
AllocConstantCellFromText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteReplaceTabs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine replaces all tabs in the string with the
		replacement character
CALLED BY:	AllocTextCell()
PASS:		es:di - the string
		dx    - replacement character
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteReplaceTabs	proc	near
	uses	ax, cx, di
	.enter

	LocalLoadChar	ax, C_TAB			;char to look for
	call	LocalStringLength			;# of chars in string
loopTop:
	LocalFindChar					;find the tab
	jcxz	done					;end of string
	LocalPrevChar	esdi				;backup one
	LocalPutChar	esdi, dx			;replace the tab
	jmp	loopTop					;find next tab
done:
	;
	; The last char in the string could still be a tab.  Let's check...
	;
	LocalPrevChar	esdi
	LocalCmpChar	es:[di], C_TAB
	jne		dontChange
	LocalPutChar	esdi, dx			;replace it
dontChange:
	.leave
	ret
PasteReplaceTabs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocTextCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a text cell
CALLED BY:	UTILITY

PASS:		ds:si - ptr to SpreadsheetClass instance data
		ss:bx - ptr to CellAttrs
			-OR-
		bx - 0 to use current attrs (default attrs for new cells)
		(ax,cl) - cell (r,c) to allocate
		es:di - ptr to text (NULL-terminated)
		dx - length of text (w/o NULL)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocTextCell	proc	far
	uses	cx, dx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>

	push	dx				;save text length
	LocalLoadChar	dx, C_SPACE		;replacement char
	call	PasteReplaceTabs		;tabs not handled by
						;font driver.
	pop	dx				;restore text length
	inc	dx				;dx <- length w/NULL
DBCS <	shl	dx, 1				;dx <- size w/NULL	>
	mov	ch, CT_TEXT			;ch <- CellType
	call	AllocCellCommon

	.leave
	ret
AllocTextCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a CellConstant type cell
CALLED BY:	UTILITY

PASS:		ds:si - ptr to SpreadsheetClass instance data
		ss:bx - ptr to CellAttrs
			-OR-
		bx - 0 to use current attrs (default attrs for new cells)
		(ax,cl) - cell (r,c) to allocate
		es:di - ptr to FloatNum
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocConstantCell	proc	far
	uses	cx, dx
	.enter

	mov	ch, CT_CONSTANT			; ch <- type
	mov	dx, size FloatNum		; dx <- size
	call	AllocCellCommon

	.leave
	ret
AllocConstantCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCellResizeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the data portion of a cell, creating if necessary

CALLED BY:	Global
PASS:		ax/cx	= Row/column of the cell
		ds:si	= Pointer to spreadsheet instance
		dx	= New data size (not counting CellCommon structure
			  or dependencies)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCellResizeData	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di, si, bp, es, ds
	.enter
EC <	call	ECCheckInstancePtr		;>
lockCell:
	SpreadsheetCellLock			; *es:di <- ptr to cell data
	jnc	makeCellExist			; Branch if cell doesn't exist

	mov	di, es:[di]			; es:di <- ptr to the cell data

	push	dx				; Save new data size
	ChunkSizePtr	es, di, dx		; dx <- size of the cell
	sub	dx, size CellCommon		; dx <- size of "other" data
	
	SpreadsheetCellUnlock			; Release the cell
	SpreadsheetCellGetDBItem		; ax/di <- cell dbase item
	pop	cx				; cx <- new data size
	;
	; dx = old size of the cell data
	; cx = new data size
	;
	sub	cx, dx				; cx <- change in the size

	mov	dx, size CellCommon		; dx <- offset to insert at

						; bx <- file handle
	mov	bx, ds:[si].SSI_cellParams.CFP_file

	tst	cx				; Check for insert/delete/nothing
	jz	sizeChangeDone			; Branch if change is done
	js	deleteSpace			; Branch if deleting space
	;
	; Inserting space
	;
	call	DBInsertAt			; Make the new space
	jmp	sizeChangeDone			; All done

deleteSpace:
	;
	; Deleting space
	;
	neg	cx				; cx <- # of bytes to delete
	call	DBDeleteAt			; Remove the space

sizeChangeDone:
	.leave
	ret

makeCellExist:
	;
	; Cell doesn't exist. Make an empty one and loop around.
	;
	call	SpreadsheetCreateEmptyCell	; Make me a cell
	jmp	lockCell
SpreadsheetCellResizeData	endp

EditCode	ends
