COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetSpace.asm

AUTHOR:		John Wedgwood, Apr 23, 1991

METHODS:
	Name			Description
	----			-----------
	SpreadsheetInsertSpace	Insert or delete space in a spreadsheet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/23/91	Initial revision

DESCRIPTION:
	Code to insert/delete space in a spreadsheet.

	$Id: spreadsheetSpace.asm,v 1.1 97/04/07 11:13:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Structure to pass to InsertDelete (see below)
;
InsertDeleteParams	struct
	;
	; These need to be initialized before the call to InsertDelete()
	;
    IDP_insertParams	RangeInsertParams
	;
	; These will be figured out by InsertDelete()
	;
    IDP_rep		RangeEnumParams	; Includes the range of cells that
					;   will vanish.
    IDP_curCellRow	word		; Row of current cell
    IDP_curCellColumn	word		; Column of current cell
    IDP_newArea		EvalRangeData	; The area that is newly created
InsertDeleteParams	ends

;
; NOTE: UpdateDependenciesAndReferences() and its utility routines need to
; be in the SpreadsheetNameCode resource because various routines they
; use make near callbacks
;

SpreadsheetNameCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDependenciesAndReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update all the dependency lists and references.

CALLED BY:	InsertDelete
PASS:		ss:bp	= Pointer to inheritable InsertDeleteParams
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDependenciesAndReferences	proc	far
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	sub	sp, size RangeEnumParams	; Make a stack frame
	mov	bx, sp				; ss:bx <- RangeEnumParams
	
	call	CellGetExtent			; Fill in the bounds
						; Nukes REP_callback
	
	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset, offset cs:UpdateCallback
	
	;
	; Check for no data at all.
	;
	cmp	ss:[bx].REP_bounds.R_top, -1	; top == -1 indicates no cells
	je	noCells				; Branch if no data
	
	;
	; There is data.
	;
	clr	dl				; Only cells with data
	call	RangeEnum			; Process the cells
noCells:

	;
	; Update the names.
	;
	mov	ss:[bx].REP_bounds.R_top, NAME_ROW
	mov	ss:[bx].REP_bounds.R_bottom, NAME_ROW
	mov	ss:[bx].REP_bounds.R_left, 0
	mov	ss:[bx].REP_bounds.R_right, LARGEST_COLUMN
	
	clr	dl				; Only cells with data please
	call	RangeEnum			; Process the names

	;
	; Update the charts.
	;
	mov	ss:[bx].REP_bounds.R_top, CHART_ROW
	mov	ss:[bx].REP_bounds.R_bottom, CHART_ROW
	
	clr	dl				; Only cells with data please
	call	RangeEnum			; Process the names

	add	sp, size RangeEnumParams	; Restore the stack
	.leave
	ret
UpdateDependenciesAndReferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for updating references and dependencies

CALLED BY:	UpdateDependenciesAndReferences via RangeEnum
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		ss:bp	= Inheritable InsertDeleteParams
		*es:di	= Cell data (it MUST exist)
		carry set always
RETURN:		carry clear always
		dl	= REF_OTHER_ALLOC_OR_FREE set if we added any
			  dependencies for the cell.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateCallback	proc	far
	uses	bx
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	mov	params.IDP_curCellRow, ax	; Save the current row/column
	mov	params.IDP_curCellColumn, cx

	mov	bx, es:[di]			; es:bx <- ptr to cell data
	
	;
	; Find out if the cell contains a formula with references that need
	; to be updated.  
	;
	cmp	es:[bx].CC_type, CT_NAME
	je	processReferences		; Branch if it's a name

	cmp	es:[bx].CC_type, CT_DISPLAY_FORMULA
	je	processReferences		; Branch if it has a formula
	cmp	es:[bx].CC_type, CT_CHART
	je	processReferences		; Branch if it has a formula
	cmp	es:[bx].CC_type, CT_FORMULA
	jne	processDependencies		; Branch if not formula

processReferences:
	;
	; The cell does have a formula.
	;
	call	UpdateReferences		; Update the references
	
	call	UpdateRangeDependencies		; Make sure cells referred to
						; as part of a range contain
						; the dependencies they should
	or	dl, mask REF_OTHER_ALLOC_OR_FREE

processDependencies:
	;
	; All cells can have dependencies.
	;
	call	UpdateDependencies		; Update the dependencies
	clc					; Continue processing
	.leave
	ret
UpdateCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateReferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the references associated with a cell.

CALLED BY:	UpdateCallback
PASS:		ss:bp	= Inheritable InsertDeleteParams
		*es:di	= Pointer to the cell data. Must contain a formula.
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateReferences	proc	near
	uses	cx, dx, di
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			; es:di <- ptr to cell
	add	di, size CellFormula		; es:di <- ptr to expression
	mov	cx, SEGMENT_CS			; cx:dx <- callback routine
	mov	dx, offset cs:UpdateRefCallback
	call	ParserForeachReference		; Process them all
	.leave
	ret
UpdateReferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRefCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a single reference

CALLED BY:	UpdateReferences via ParserForeachCellReference
PASS:		ds:si	= Spreadsheet instance
		es:di	= Pointer to the cell reference
		ss:bp	= Inheritable InsertDeleteParams
		al	= PARSER_TOKEN_CELL or PARSER_TOKEN_NAME
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRefCallback	proc	far
	uses	ax, bx, cx, dx
params	local	InsertDeleteParams
	.enter inherit
EC <	call	ECCheckInstancePtr		;>
	cmp	al, PARSER_TOKEN_CELL		; Only cell references...
	jne	quit				; Branch if not a cell

	mov	ax, es:[di].CR_row		; ax/cx <- row/column
	mov	cx, es:[di].CR_column		;   With CRC bits set.
	
	mov	bx, ax				; Save old ax/cx in bx/dx
	mov	dx, cx
	
	call	UpdateRefOrDep			; Update ax/cx
	
	;
	; Check for any change
	;
	cmp	ax, bx				; Check for row change
	jne	changed				; Branch if row different
	cmp	cx, dx				; Check for column change
	je	quit				; Branch if no change

changed:
	;
	; The reference has been changed.
	;
	SpreadsheetCellDirty			; Mark the cell as dirty
	
	mov	es:[di].CR_row, ax		; ax/cx <- row/column
	mov	es:[di].CR_column, cx		;   With CRC bits set.

quit:
	.leave
	ret
UpdateRefCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRangeDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update dependencies for referenced ranges.

CALLED BY:	UpdateDependenciesAndReferences
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		ss:bp	= Inheritable InsertDeleteParams
		*es:di	= Pointer to cell data
RETURN:		es	= Same block as passed in (may move)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The problem that this routine solves only occurs when we are inserting
	space. New cells are created that possibly should contain dependencies.
	
	For instance, if you insert a single row at row B and you have
	a reference from another cell that reads "a1:c1" then that reference
	gets updated to read "a1:d1". Unfortunately the new cell B1 doesn't
	have a dependency list entry for this cell. As a result changing
	cell B1 doesn't update the formula that uses this range reference.
	
	It's really hokey, but the technique we use is:
		if (inserting) then
		    list = CreatePrecedentsList()
		    foreach list entry do
		        if entry.type = RANGE then
			    intersection = RANGE & newArea
			    if insersection != NULL then
			        foreach cell in intersection
				    Add dependency to cell
				end
			    endif
			endif
		    end
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRangeDependencies	proc	near
	uses	ax, bx, dx, di
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	push	es:LMBH_handle			; Save cell block handle
	;
	; First check for either delta being positive. (inserting)
	;
	tst	params.IDP_insertParams.RIP_delta.P_x
	js	quit				; Branch if deleting
	jnz	inserting			; Branch if inserting
	tst	params.IDP_insertParams.RIP_delta.P_y
	js	quit				; Branch if deleting

inserting:
	;
	; We're inserting...
	; ds:si	= Spreadsheet instance
	; ax	= Row
	; cx	= Column
	;
	push	bp				; Save frame ptr
	sub	sp, size PCT_vars		; Allocate a stack frame
	mov	bp, sp				; ss:bp <- ptr to stack frame
	call	SpreadsheetInitCommonParamsFar	; Initialize the stack frame
	
	mov	ss:[bp].CP_row, ax		; Save our row/column
	mov	ss:[bp].CP_column, cx
	
	mov	ss:[bp].EP_flags, mask EF_MAKE_DEPENDENCIES
	call	CreatePrecedentList		; bx <- block handle
	
	lahf					; Save "has precendents" flag
	add	sp, size PCT_vars		; Restore the stack
	pop	bp				; Restore frame ptr
	sahf					; Restore "has precendents" flag

	jnc	quit				; Branch if no precedents
	
	;
	; ds:si	= Spreadsheet instance
	; bx	= Block handle of precedents list
	; ax	= Row
	; cx	= Column
	; ss:bp	= Inherited InsertDeleteParams
	;
	mov	di, SEGMENT_CS
	mov	dx, offset cs:UpdateRangeCallback
	call	ParserForeachPrecedent		; Call the callback...
	
	call	MemFree				; Free the precedents list
quit:
	pop	bx				; bx <- cell block handle
	call	MemDerefES			; Restore cell block segment
	.leave
	ret
UpdateRangeDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRangeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the dependencies for a given range.

CALLED BY:	UpdateRangeDependencies via ForeachPrecedent
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		es:di	= Pointer to the precedent data
		dl	= Type of the precedent data
		ss:bp	= Inheritable InsertDeleteParams
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if type == RANGE then
	    intersection = RANGE & newArae
	    if intersection != NULL then
	    	foreach cell in intersection
		    Add dependency to cell
		end
	    endif
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRangeCallback	proc	far
	uses	ax, bx, dx
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	test	dl, mask ESAT_RANGE		; Check for range type
	jz	quit				; Branch if not a range
	
	;
	; It's a range. Compute the intersection.
	;
	push	ds, si				; Save spreadsheet instance
	segmov	ds, ss, si			; ds:si <- ptr to source
	lea	si, params.IDP_newArea
	call	ParserEvalRangeIntersection		; es:di <- intersection
	pop	ds, si				; Restore spreadsheet instance

	jc	quit				; Branch if no intersection
	
	;
	; There is an area that needs updating. Use RangeEnum to do it.
	;
	sub	sp, size RangeEnumParams	; Allocate a stack frame
	mov	bx, sp				; ss:bx <- ptr to stack frame
	
	;
	; Copy the intersected range into the parameters.
	;
	mov	ax, es:[di].ERD_firstCell.CR_row
	andnf	ax, mask CRC_VALUE
	mov	ss:[bx].REP_bounds.R_top, ax

	mov	ax, es:[di].ERD_firstCell.CR_column
	andnf	ax, mask CRC_VALUE
	mov	ss:[bx].REP_bounds.R_left, ax

	mov	ax, es:[di].ERD_lastCell.CR_row
	andnf	ax, mask CRC_VALUE
	mov	ss:[bx].REP_bounds.R_bottom, ax

	mov	ax, es:[di].ERD_lastCell.CR_column
	andnf	ax, mask CRC_VALUE
	mov	ss:[bx].REP_bounds.R_right, ax

	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset, offset cs:AddRangeDependencies
	
	mov	dl, mask REF_ALL_CELLS
	call	RangeEnum			; Process the range

	add	sp, size RangeEnumParams	; Restore the stack frame
quit:
	clc					; Signal: continue
	.leave
	ret
UpdateRangeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddRangeDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add dependencies for all the cells in a range.

CALLED BY:	UpdateRangeCallback via RangeEnum
PASS:		ds:si	= Spreadsheet instance
		ax	= Row of this cell
		cx	= Column of this cell
		ss:bp	= Inheritable InsertDeleteParams
		ss:bx	= RangeEnumParams
		*es:di	= Cell data (if any)
		carry set if the cell exists
RETURN:		carry clear always
		es	= Segment address of the cell
		dl	= REF_CELL_ALLOCATED if we allocated a new cell
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddRangeDependencies	proc	far
	uses	ax, bx, di
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	;
	; If the cell doesn't exist we need to allocate it.
	;
	jc	gotCell				; Branch if cell exists
	
	;
	; The cell doesn't exist. We allocate an empty one.
	;
	call	SpreadsheetCreateEmptyCell	; Allocate the cell
	SpreadsheetCellLock			; *es:di <- ptr to the cell
	
	or	dl, mask REF_CELL_ALLOCATED	; We allocated a cell

gotCell:
	;
	; We've got a cell locked down here.
	; *es:di= Pointer to the cell data
	; ds:si	= Spreadsheet instance
	; dl	= Flags to return to caller
	; ax	= Row of current cell
	; cx	= Column of current cell
	; ss:bp	= Inherited InsertDeleteParams
	;
	push	es:LMBH_handle			; Save handle of cell block

	push	dx, bp				; Save flags to return, frame

	mov	bx, bp				; Save current frame ptr
	sub	sp, size DependencyParameters	; Allocate stack frame
	mov	bp, sp				; ss:bp <- new stack frame
	call	SpreadsheetInitCommonParamsFar	; Initialize the stack frame
	
	xchg	bp, bx				; ss:bp <- passed frame
						; ss:bx <- DependencyParameters
	mov	dx, params.IDP_curCellRow	; Copy the row
	mov	ss:[bx].CP_row, dx

	mov	dx, params.IDP_curCellColumn	; Copy the column
	mov	ss:[bx].CP_column, dx
	
	xchg	bx, bp				; ss:bp <- DependencyParameters
	
	call	ParserAddSingleDependency		; Add the dependency
EC <	ERROR_C	UNABLE_TO_ADD_DEPENDENCIES				>
	
	add	sp, size DependencyParameters	; Restore the stack
	pop	dx, bp				; Restore flags to return, frame

	;
	; Now force es to be the segment address of the cell block
	;
	pop	bx				; bx <- cell block
	call	MemDerefES			; es <- segment address of cell

	clc					; Please continue...
	.leave
	ret
AddRangeDependencies	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDependencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the dependencies associated with a cell.

CALLED BY:	UpdateCallback
PASS:		ss:bp	= Inheritable InsertDeleteParams
		*es:di	= Pointer to the cell data.
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDependencies	proc	near
	uses	ax, di
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			; es:di <- ptr to cell data
	mov	ax, offset cs:UpdateDepCallback	; ax <- callback
	call	ForeachDependency		; Process the dependencies
	.leave
	ret
UpdateDependencies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDepCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update each dependency

CALLED BY:	UpdateDependencies via ForeachDependency
PASS:		*es:bx	= Pointer to dependency list block
		ss:bp	= Pointer to inheritable InsertDeleteParams
		ds:si	= Spreadsheet instance
		di	= Offset in the block to the current entry
		dx	= Row of the cell
		cx	= Column of the cell
RETURN:		carry clear always
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	We don't need to worry about dependencies in the area that has been
	nuked since we took care of that earlier.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDepCallback	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	add	di, es:[bx]			; es:di <- ptr to dependency
	
	;
	; Get the row/column and add in the ABSOLUTE bit so we won't get
	; updated as though we were a relative reference.
	;
	mov	ax, es:[di].D_row		; ax <- row
	clr	ch
	mov	cl, es:[di].D_column		; cx <- column
	
	mov	bx, ax				; Save the current values in
	mov	dx, cx				;    bx/dx.

	or	ax, mask CRC_ABSOLUTE		; These are absolute referenes
	or	cx, mask CRC_ABSOLUTE
	
	call	UpdateRefOrDep			; Update the reference or
						;    dependency

	;
	; Clear out the ABSOLUTE bits and check for any change in the dependency
	;
	and	ax, not mask CRC_ABSOLUTE	; Clear these bits, they aren't
	and	cx, not mask CRC_ABSOLUTE	;   used in dependencies
	
	cmp	ax, bx				; Check for row changed
	jne	changed				; Branch if row changed
	cmp	cx, dx				; Check for column changed
	je	quit				; Branch if column didn't change
changed:
	
	;
	; The row or column of the dependency changed.
	;
	mov	es:[di].D_row, ax		; Save new row/column
	mov	es:[di].D_column, cl
	
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	DBDirty				; Dirty the dependency
quit:
	.leave
	ret
UpdateDepCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRefOrDep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a reference or dependency

CALLED BY:	UpdateDepCallback, UpdateRefCallback
PASS:		ss:bp	= Inheritable InsertDeleteParams
		ax	= Row (with CRC_ABSOLUTE set if absolute reference)
		cx	= Column (with CRC_ABSOLUTE set if absolute reference)
RETURN:		ax	= New row (with CRC_ABSOLUTE set if passed)
		cx	= New column (with CRC_ABSOLUTE set if passed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The cases for references and dependencies are exactly the same.
	
	We're attempting to make cells that referenced each other before
	the insert/delete continue to reference each other. Since a reference
	and a dependency are mirror images of each other that shouldn't be
	a problem.

	There are only a few cases to consider:
	    - Absolute reference from an area that didn't move to an area
	      that didn't move
	        * Do nothing
	    - Absolute reference from an area that did move to an area
	      that didn't move.
	        * Do nothing
	    - Relative reference from an area that didn't move to an area
	      that didn't move.
	        * Do nothing
	    - Relative reference from an area that did move to an area
	      that did move.
	        * Do nothing

(1)	    - Reference to the area that was nuked
		* Force the reference to be an illegal one
	    
(2) m->n    - Relative reference from an area that did move to an area
	      that did not move.
	        * Update reference by subtracting the delta

(3) n->m    - Relative reference from an area that didn't move to an area
	      that did move.
	        * Update reference by adding the delta
(4) n->m    - Absolute reference from an area that didn't move to an area
	      that did move.
	        * Update reference by adding the delta
(5) m->m    - Absolute reference from an area that did move to an area
	      that did move.
	        * Update reference by adding the delta

	This gives us 4 operations:
		Do nothing
		Force to illegal reference
		Update by subtracting delta
		Update by adding delta

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRefOrDep	proc	near
	uses	bx, dx, di, si
params	local	InsertDeleteParams
	.enter	inherit
	;
	; First we get the passed row/column ignoring the ABSOLUTE bit.
	; Since the low 15 bits constitute a signed value we need to sign
	; extend that value into the high bit.
	;
	mov	di, ax				; di <- row
	shl	di, 1				; Sign extend into high bit
	sar	di, 1

	mov	si, cx				; si <- column
	shl	si, 1				; Sign extend into high bit
	sar	si, 1

	;
	; ax	= Passed row record for the reference/dependency
	; di	= Current row value
	; cx	= Passed column record for the reference/dependency
	; si	= Current column value
	;
	; We want to set di/si so that they contain the value that the
	; reference would have had before any of this stuff happened.
	;
	; First we adjust for relative references so we can figure out where
	; the reference was going beforehand.
	;
	; If the reference is relative, and if the source cell is in the area
	; that moved, we need to adjust the reference by the amount of space
	; that was inserted or deleted in order to really know where the 
	; reference was to.
	;
	test	ax, mask CRC_ABSOLUTE		; Check for absolute reference
	jnz	gotRow				; Branch if we've got the row
	add	di, params.IDP_curCellRow	; Adjust by adding current row

	xchg	ax, di				; ax <- reference
	call	AdjustRowIfCurCellMoved		; Adjust ax
	xchg	ax, di				; Restore everything...
gotRow:
	
	test	cx, mask CRC_ABSOLUTE		; Check for absolute reference
	jnz	gotColumn			; Branch if we've got the col
	add	si, params.IDP_curCellColumn	; Adjust by adding current col
	
	xchg	ax, si				; ax <- reference
	call	AdjustColumnIfCurCellMoved	; Adjust ax
	xchg	ax, si				; Restore everything...
gotColumn:
	;
	; ax/cx	= Passed row/column with the ABSOLUTE bits
	; di/si	= The old values for the reference row/column
	;
	; Check the reference against the range which got nuked.
	; This is case (1).
	;
	lea	bx, params.IDP_rep.REP_bounds	; ss:bx <- ptr to range
	call	IsCellInRange			; Check for di/si in nuked
	jc	illegalReference		; Branch if in nuked range
	
	;
	; Check for a reference to an area that didn't move.
	; This is part of the test for case (2).
	;
	lea	bx, params.IDP_insertParams.RIP_bounds
	call	IsCellInRange			; Check for reference in moved
	jnc	checkFromMoved			; Branch if not in moved area
	
	;
	; Having eliminated cases 1 and 2 we check on case (5):
	;	Absolute reference from area that moved to an area that moved.
	;
	; We know that the reference itself falls in the area that moved.
	; We need to check on the source.
	;
	call	IsCurrentCellInRange		; Check for source moved
	jc	bothMovedCheckAbsolute		; Branch if in moved area
	
	;
	; The source is in the area that didn't move. The reference is in the
	; area that did move. We need to update the reference no matter what.
	;
	mov	di, ax				; di/si <- original values
	mov	si, cx

	add	di, params.IDP_insertParams.RIP_delta.P_y
	add	si, params.IDP_insertParams.RIP_delta.P_x
	
	and	di, mask CRC_VALUE		; Just the values
	and	si, mask CRC_VALUE
	
	and	ax, mask CRC_ABSOLUTE		; Save the 'absolute' bits
	and	cx, mask CRC_ABSOLUTE
	
	or	ax, di				; Combine absolute/relative bits
	or	cx, si				;   with the row/column values

quit:
	.leave
	ret

illegalReference:
	;
	; The conclusion of case (1).
	;
	; The reference is to the area that got deleted. We want to replace it
	; with an illegal reference.
	;
	mov	ax, -1				; Illegal row
	mov	cx, -1				; Illegal column
	jmp	quit

checkFromMoved:
	;
	; More of case (2).
	;
	; The reference is to a place that didn't move. If the reference is
	; from a cell that did move then we may need to do an update.
	; ss:bx	= Pointer to area that moved.
	;
	call	IsCurrentCellInRange		; Check for source in moved area
	jnc	quit				; Branch if in static area
	
	;
	; The source of the reference is in the moved area. The reference is
	; in an area that didn't move. The parts of the reference that are
	; relative need to be updated by the delta.
	;
	test	ax, mask CRC_ABSOLUTE		; Check for absolute row
	jnz	rowOK2				; Branch if we have the row
	sub	ax, params.IDP_insertParams.RIP_delta.P_y
	and	ax, mask CRC_VALUE
rowOK2:
	
	test	cx, mask CRC_ABSOLUTE		; Check for absolute column
	jnz	colOK2				; Branch if we have the column
	sub	cx, params.IDP_insertParams.RIP_delta.P_x
	and	cx, mask CRC_VALUE
colOK2:

	jmp	quit

bothMovedCheckAbsolute:
	;
	; Case (5):
	;
	; The source and destination are both in an area that moved. If any 
	; parts of the reference are absolute we want to add in the delta.
	;
	test	ax, mask CRC_ABSOLUTE		; Check for absolute row
	jz	rowOK5				; Branch if we have the row
	
	and	ax, not mask CRC_ABSOLUTE
	add	ax, params.IDP_insertParams.RIP_delta.P_y
	or	ax, mask CRC_ABSOLUTE
rowOK5:

	test	cx, mask CRC_ABSOLUTE		; Check for absolute column
	jz	colOK5				; Branch if we have the column
	
	and	cx, not mask CRC_ABSOLUTE
	add	cx, params.IDP_insertParams.RIP_delta.P_x
	or	cx, mask CRC_ABSOLUTE
colOK5:

	jmp	quit

UpdateRefOrDep	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCurrentCellInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if IDP_curCellRow/Column is in the given range

CALLED BY:	UpdateRefOrDep
PASS:		ss:bp	= Inheritable parameters
		ss:bx	= Range to check
RETURN:		carry set if it is in the range
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCurrentCellInRange	proc	near
params	local	InsertDeleteParams
	.enter	inherit
	;
	; Get the current row and column, but adjust them if they used to fall
	; in the area that moved.
	;
	mov	di, params.IDP_curCellRow	; di <- row where it was before
	xchg	ax, di				; ax <- reference
	call	AdjustRowIfCurCellMoved		; Adjust ax
	xchg	ax, di				; Restore everything...

	mov	si, params.IDP_curCellColumn	; si <- column where it was
	xchg	ax, si				; ax <- reference
	call	AdjustColumnIfCurCellMoved	; Adjust ax
	xchg	ax, si				; Restore everything...

	call	IsCellInRange			; Check for source in moved
	.leave
	ret
IsCurrentCellInRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustRowIfCurCellMoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a row reference if the current cell was in the
		area that moved as a result of the insert/delete.

CALLED BY:	UpdateRefOrDep
PASS:		ss:bp	= Inheritable stack frame
		ax	= Row reference
RETURN:		ax	= Updated row reference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustRowIfCurCellMoved	proc	near
	uses	di
params	local	InsertDeleteParams
	.enter	inherit
	;
	; Get the top of the area and adjust it by the inserted space
	;
	mov	di, params.IDP_insertParams.RIP_bounds.R_top
	add	di, params.IDP_insertParams.RIP_delta.P_y
	
	;
	; Compare row against the top edge of the area that moved
	;
	cmp	params.IDP_curCellRow, di
	jb	quit
	
	;
	; The row of the current cell falls in the area that moved. This means
	; that we need to adjust the reference by the inserted amount in order
	; to know where it was before.
	;
	sub	ax, params.IDP_insertParams.RIP_delta.P_y
quit:
	.leave
	ret
AdjustRowIfCurCellMoved	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustColumnIfCurCellMoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a column reference if the current cell was in the
		area that moved as a result of the insert/delete.

CALLED BY:	UpdateRefOrDep
PASS:		ss:bp	= Inheritable stack frame
		ax	= Column reference
RETURN:		ax	= Updated column reference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustColumnIfCurCellMoved	proc	near
	uses	di
params	local	InsertDeleteParams
	.enter	inherit
	;
	; Get the left of the area and adjust it by the inserted space
	;
	mov	di, params.IDP_insertParams.RIP_bounds.R_left
	add	di, params.IDP_insertParams.RIP_delta.P_x
	
	;
	; Compare column against the left edge of the area that moved
	;
	cmp	params.IDP_curCellColumn, di
	jb	quit
	
	;
	; The column of the current cell falls in the area that moved. This 
	; means that we need to adjust the reference by the inserted amount 
	; in order to know where it was before.
	;
	sub	ax, params.IDP_insertParams.RIP_delta.P_x
quit:
	.leave
	ret
AdjustColumnIfCurCellMoved	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCellInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a cell falls inside a given range.

CALLED BY:	UpdateRefOrDep
PASS:		di	= Row of cell to check
		si	= Column of cell to check
		ss:bx	= Pointer to the rectangle to compare against
RETURN:		carry set if the cell falls in the range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCellInRange	proc	near
	cmp	di, ss:[bx].R_top	; Check for above top
	jb	outside
	cmp	di, ss:[bx].R_bottom	; Check for beyond bottom
	ja	outside
	
	cmp	si, ss:[bx].R_left	; Check for below top
	jb	outside
	cmp	si, ss:[bx].R_right	; Check for beyond right
	ja	outside
	
	stc				; Signal: Cell is in range
	jmp	quit

outside:
	clc				; Signal: not in range
quit:
	ret
IsCellInRange	endp

SpreadsheetNameCode	ends

SpreadsheetSortSpaceCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCheckInsertSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if insert/delete space in a spreadsheet is OK

CALLED BY:	MSG_SPREADSHEET_INSERT_SPACE_CHECK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message
		cx	= SpreadsheetInsertFlags
RETURN:		al	= SpreadsheetInsertSpaceError
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCheckInsertSpace		method dynamic SpreadsheetClass,
					MSG_SPREADSHEET_CHECK_INSERT_SPACE
params	local	InsertDeleteParams

	.enter

	mov	si, di			;ds:si <- ptr to Spreadsheet instance
	;
	; Compute the area that will be nuked
	;
	push	cx
	call	ComputeTop
	call	ComputeLeft
	call	ComputeBottom
	call	ComputeRight
	call	ComputeDelta
	call	ComputeNukeBounds
	;
	; See if any cells exist in the area
	;
	mov	ax, ss:params.IDP_rep.REP_bounds.R_top
	mov	cl, {byte}ss:params.IDP_rep.REP_bounds.R_left
	mov	dx, ss:params.IDP_rep.REP_bounds.R_bottom
	mov	ch, {byte}ss:params.IDP_rep.REP_bounds.R_right
	call	RangeExists
	pop	cx			;cx <- SpreadsheetInsertFlags
	jc	returnError		;branch if cells exist
	;
	; No cells, no error.
	;
	clr	al			;al <- SpreadsheetInsertSpaceError
		CheckHack <SISE_NO_ERROR eq 0>
exit:
	.leave
	ret

	;
	; There is data in either the rows or columns that would be shifted
	; off the edge of spreadsheet.  Return an appropriate error
	;
returnError:
	mov	al, SISE_TOO_MANY_COLUMNS
	test	cx, mask SIF_DELETE
	jnz	deleteError

	test	cx, mask SIF_COLUMNS	;doing columns or rows?
	jnz	exit			;branch if doing columns
	dec	al			;al <- SISE_TOO_MANY_ROWS
		CheckHack <SISE_TOO_MANY_ROWS eq SISE_TOO_MANY_COLUMNS-1>
	jmp	exit

deleteError:
	inc	al			;al <- SISE_DELETE_ROW_DATA
		CheckHack <SISE_DELETE_ROW_DATA eq SISE_TOO_MANY_COLUMNS+1>
	test	cx, mask SIF_COLUMNS
	jnz	exit
	inc	al			;al <- SISE_DELETE_COLUMN_DATA
		CheckHack <SISE_DELETE_COLUMN_DATA eq SISE_DELETE_ROW_DATA+1>
	jmp	exit

SpreadsheetCheckInsertSpace		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInsertSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert/delete space in a spreadsheet.

CALLED BY:	via MSG_SPREADSHEET_INSERT_SPACE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= MSG_SPREADSHEET_INSERT_SPACE
		cx	= SpreadsheetInsertFlags
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
    The rules are:
	Insert Partial Row:
		Top	= selection.top
		Left	= selection.left
		Bottom	= SSI_maxRow - selection.height
		Right	= selection.right
		
		Delta.X	= 0
		Delta.Y	= selection.height

	Insert Partial Column:
		Top	= selection.top
		Left	= selection.left
		Bottom	= selection.bottom
		Right	= SSI_maxCol - selection.width
		
		Delta.X	= selection.width
		Delta.Y	= 0
	
	Insert Complete Row:
		Top	= selection.top
		Left	= 0
		Bottom	= SSI_maxRow - selection.height
		Right	= SSI_maxCol
		
		Delta.X	= 0
		Delta.Y	= selection.height

	Insert Complete Column:
		Top	= 0
		Left	= selection.left
		Bottom	= SSI_maxRow
		Right	= SSI_maxCol - selection.width
		
		Delta.X	= selection.width
		Delta.Y	= 0

	-------------------

	Delete Partial Row:
		Top	= selection.bottom + 1
		Left	= selection.left
		Bottom	= SSI_maxRow
		Right	= selection.right
		
		Delta.X	= 0
		Delta.Y	= -1 * selection.height

	Delete Partial Column:
		Top	= selection.top
		Left	= selection.right + 1
		Bottom	= selection.bottom
		Right	= SSI_maxCol
		
		Delta.X	= -1 * selection.width
		Delta.Y	= 0
	
	Delete Complete Row:
		Top	= selection.bottom + 1
		Left	= 0
		Bottom	= SSI_maxRow
		Right	= SSI_maxCol
		
		Delta.X	= 0
		Delta.Y	= -1 * selection.height

	Delete Complete Column:
		Top	= 0
		Left	= selection.right + 1
		Bottom	= SSI_maxRow
		Right	= SSI_maxCol
		
		Delta.X	= -1 * selection.width
		Delta.Y	= 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetInsertSpace	method	SpreadsheetClass, 
			MSG_SPREADSHEET_INSERT_SPACE
params	local	InsertDeleteParams
	.enter

	call	SpreadsheetMarkBusy

	mov	si, di			; ds:si <- ptr to spreadsheet instance
if _PROTECT_CELL
	;
	; In Jedi, we don't want to delete the row/col which contains
	; protected cells. If carry is set, that means there existed some
	; protected cells in the deleting range. So we need to abort the
	; operation.
	;
	call	SpaceProtectionCheck
	LONG	jc	error		; jmp if cell protected
endif
	push	cx			; save SpreadsheetInsertFlags
	call	ComputeTop		; Compute the area that will be moving
	call	ComputeLeft
	call	ComputeBottom
	call	ComputeRight

	call	ComputeDelta		; Compute the distance it moves

	call	InsertDelete		; Do the insert/delete
	pop	ax			; ax <- SpreadsheetInsertFlags
	;
	; Adjust the header and footer
	;
	lea	bx, ds:[si].SSI_header	;ds:bx <- CellRange to update
	call	AdjustHeaderFooter
	lea	bx, ds:[si].SSI_footer	;ds:bx <- CellRange to update
	call	AdjustHeaderFooter
	;
	; Update the row heights. If we are doing complete rows then we can
	; do a quick update by running through the row height array. 
	; Otherwise we need to actually recompute the heights.
	;
	test	ax, mask SIF_COLUMNS
	jnz	doColumns
	test	ax, mask SIF_COMPLETE
	jz	recalcHeights
	mov	cx, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ss:params.IDP_insertParams.RIP_delta.P_y
	call	RowInsertHeights
	;
	;    cx - starting row
	;    dx - # of rows (<0 = delete)
	;
	tst	dx				;delete?
	js	doneAdjust			;skip if delete
	;
	; We've inserted rows -- set the height of the new rows
	; to the default.
	;
	mov	ax, cx				;ax <- start row
	mov	cx, dx				;cx <- # of rows
	mov	dx, ROW_HEIGHT_DEFAULT		;dx <- row height
	mov	bx, ROW_BASELINE_DEFAULT or ROW_HEIGHT_AUTOMATIC
setRowLoop:
	call	RowSetHeight
	inc	ax				;ax <- next row
	loop	setRowLoop			;cx <- # of left; loop
	jmp	doneAdjust


	;
	; Recalculate the row heights for all rows in and below the selection.
	;
recalcHeights:
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_maxRow
	call	RecalcRowHeightsInRange
	jmp	doneAdjust

doColumns:
	;
	; Update the column widths. We only do this for complete columns.
	; Otherwise we do nothing at all.
	;
	test	ax, mask SIF_COMPLETE
	jz	doneAdjust
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	dx, ss:params.IDP_insertParams.RIP_delta.P_x
	;
	; If we're deleting columns, decrement the reference
	; counts on any default column attributes in use.
	;
	tst	dx				;insert?
	jns	skipDeleteAttrs			;skip if insert
	push	cx, dx
	mov	bx, dx
	neg	bx				;bx <- # of columns
colLoop:
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- default for column
	call	StyleDeleteStyleByTokenFar	;one less reference...
	inc	cx				;cx <- next column
	dec	bx				;bx <- # of columns left
	jnz	colLoop				;branch while more columns
	pop	cx, dx
skipDeleteAttrs:
	call	ColumnInsertWidths
	;
	;    cx - starting column
	;    dx - # of columns (<0 = delete)
	;
	tst	dx				;delete?
	js	doneAdjust			;done if delete

	mov	bx, dx				;bx <- # of columns
	mov	dx, COLUMN_WIDTH_DEFAULT	;dx <- column width
	clr	ax				;ax <- default style token
setColumnLoop:
	call	ColumnSetWidth			;set width
	call	ColumnSetDefaultAttrs		;set default attributes
	inc	cx				;cx <- next column
	dec	bx				;bx <- # of columns left
	jnz	setColumnLoop			;branch while more columns
	;
	; Redraw everything and update the UI
	; We update the UI for:
	;	edit bar
	;	cell notes
	;	all cell attributes
	;	header & footer in case we deleted them
	;
doneAdjust:
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	markNotBusy
	mov	ax, SNFLAGS_ACTIVE_CELL_DATA_CHANGE or \
		    SNFLAGS_SELECTION_ATTRIBUTES_CHANGE or \
		    mask SNF_DOC_ATTRS
	call	UpdateDocUIRedrawAll
	;
	; We need to recalculate everything.
	;
	call	ManualRecalc

markNotBusy:

	call	SpreadsheetMarkNotBusy

	.leave
	ret

if _PROTECT_CELL
error:
	;
	; bring up an error dialog for cell protection error.
	;
	mov	si, offset CellProtectionError
	call	PasteNameNotifyDB
	jmp	markNotBusy
endif
SpreadsheetInsertSpace	endm


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpaceProtectionCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the operation SpreadsheetInsertSpace() is safe.

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= spreadsheet instance data
		cx	= SpreadsheetInsertFlags
RETURN:		carry set if the operation is not safe.
		carry clear if the operation is ok.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Find out if the operation is a deletion or insertion. If it is a
		insertion, then it is safe. We need to do the check if the
		operation is a deletion lest it should delete any protected 
		cell
	* Find out  the bounds that will be nuked.
	* Check to see if there exists any protected cells inside the bounds
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpaceProtectionCheck	proc	near
params	local	InsertDeleteParams
		uses	ax, bx, cx, dx
		.enter
		Assert record	cx, SpreadsheetInsertFlags
	;
	; First, find out if the operation is deletion or insertion. If it is
	; insertion, then it is safe.
	;
		test	cx, mask SIF_DELETE
		jz	quit
	;
	; Compute the area that will be nuked.
	;
		call	ComputeTop
		call	ComputeLeft
		call	ComputeBottom
		call	ComputeRight
		call	ComputeDelta
		call	ComputeNukeBounds
	;
	; Find out if there exists some protected cells in this range
	;
		mov	ax, ss:params.IDP_rep.REP_bounds.R_top
		mov	cx, ss:params.IDP_rep.REP_bounds.R_left
		mov	bx, ss:params.IDP_rep.REP_bounds.R_bottom
		mov	dx, ss:params.IDP_rep.REP_bounds.R_right
		call	CheckProtectedCell
quit:
		.leave
		ret
SpaceProtectionCheck		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustHeaderFooter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the header or footer range for an insert/delete

CALLED BY:	SpreadsheetInsertSpace()
PASS:		ds:si - ptr to Spreadsheet instance
		ds:bx - ptr to CellRange() to update
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		For any bound of the header/footer that is above/to the
	left of the selection, it is not adjusted. (as one would expect)
		The top and left of the header/footer are adjusted by the
	number of rows/columns inserted/deleted, but not beyond the top/left
	of the selection.
		The bottom and right of the header/footer are adjusted
	by the number of rows/columns inserted/deleted, but not beyond one
	above/to the left of the top/left of the selection.
		By setting limits, it prevents the bounds from being
	adjusted further than the user would expect.
		By setting different limits for how much a bound can be
	adjusted, it has the desirable side-effect that the right/bottom
	bound can be adjusted beyond the left/top bound.  This case is
	checked for, and the header/footer deleted if it occurs.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustHeaderFooter		proc	near
	uses	ax, di
	class	SpreadsheetClass
	.enter	inherit	SpreadsheetInsertSpace

	;
	; Make sure there is a range to update
	;
	cmp	ds:[bx].CR_start.CR_row, -1	;any range defined?
	je	done				;branch if none
	;
	; Check each side
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ss:params.IDP_insertParams.RIP_delta.P_y

	mov	di, offset CR_start.CR_row
	call	adjustSide
	push	dx
	mov	di, offset CR_end.CR_row
	call	adjustSide
	pop	di
	cmp	di, dx				;adjusted too far?
	jg	nukeRange			;branch if so

	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	cx, ss:params.IDP_insertParams.RIP_delta.P_x

	mov	di, offset CR_start.CR_column
	call	adjustSide
	push	dx
	mov	di, offset CR_end.CR_column
	call	adjustSide
	pop	di
	cmp	di, dx				;adjusted too far?
	jg	nukeRange			;branch if so

done:
	.leave
	ret

nukeRange:
	mov	ds:[bx].CR_start.CR_row, -1
	jmp	done

	;
	; PASS:
	;	cx - delta
	;	ds:[bx][di] - ptr to row/column to adjust
	;	ax - top/left of selection
	; RETURN:
	;	dx - new side
	;

adjustSide:
	push	ax
	jcxz	noChange			;branch if no delta
	mov	dx, ds:[bx][di]			;dx <- side to adjust
	cmp	dx, ax				;above/to left of selection?
	jb	noChange			;branch if above selection
	add	dx, cx				;dx <- adjusted side
	;
	; We don't want the top or left to be adjusted beyond the selection
	;
CheckHack <(offset CR_start.CR_row) lt (offset CR_start.CR_column)>
CheckHack <(offset CR_end.CR_row) gt (offset CR_start.CR_column)>
CheckHack <(offset CR_end.CR_column) gt (offset CR_start.CR_column)>
	cmp	di, offset CR_start.CR_column	;top or left?
	jbe	doCompare			;branch if top or left
	;
	; If this is the bottom or right, it can go to one beyond the
	; selection.
	;
	tst	ax				;at start?
	jz	doCompare			;branch if at start
	dec	ax				;one before selection
doCompare:
	cmp	dx, ax				;adjusted too far?
	jae	sideOK				;branch if OK
	mov	dx, ax				;dx <- limit to selection
sideOK:
	mov	ds:[bx][di], dx			;save (new) side
noChange:
	pop	ax
	retn
AdjustHeaderFooter		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure IDP_insertParams.RIP_bounds.R_top

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
		cx	= SpreadsheetInsertFlags
RETURN:		IDP_insertParams.RIP_bounds.R_top set
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Insert Partial Row:		*** Other ***
	Insert Partial Column:
	Insert Complete Row:
	Delete Partial Column
		selection.top
	
	Insert Complete Column:		SIF_COMPLETE = 1, SIF_COLUMNS = 1
	Delete Complete Column:
		0

	Delete Partial Row:		SIF_DELETE = 1, SIF_COLUMNS = 0
	Delete Complete Row:
		selection.bottom + 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeTop	proc	near
	class	SpreadsheetClass
	uses	cx
params	local	InsertDeleteParams
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	bx, cx			; bx, cx <- flags
	
	;
	; Get the two bit masks that we care about.
	;
	andnf	bx, mask SIF_COMPLETE or mask SIF_COLUMNS
	andnf	cx, mask SIF_DELETE or mask SIF_COLUMNS

	;
	; Check the ICC or DCC case first.
	; In that case we want to check:
	;	SIF_COMPLETE = 1, SIF_COLUMNS = 1, don't care about SIF_DELETE
	;
	clr	ax			; Assume ICC or DCC

	cmp	bx, mask SIF_COMPLETE or mask SIF_COLUMNS
	je	gotTop			; Branch if ICC or DCC
	
	;
	; Check the DPR or DCR case next.
	; In that case we want to check:
	;	SIF_DELETE = 1, SIF_COLUMNS = 0, don't care about SIF_COMPLETE
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	add	ax, 1			; Assume DPR or DCR

	cmp	cx, mask SIF_DELETE
	je	gotTop			; Branch if DPR or DCR
	
	;
	; It's some other case. Luckily they all return the same value.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row

gotTop:
	;
	; ax = value for the top of the range.
	;
	mov	params.IDP_insertParams.RIP_bounds.R_top, ax
	.leave
	ret
ComputeTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure IDP_insertParams.RIP_bounds.R_left

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
		cx	= SpreadsheetInsertFlags
RETURN:		IDP_insertParams.RIP_bounds.R_left set
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Insert Partial Row:		*** Other ***
	Insert Partial Column:
	Insert Complete Column:
	Delete Partial Row:
		selection.left
	
	Insert Complete Row:		SIF_COMPLETE = 1, SIF_COLUMNS = 0
	Delete Complete Row:
		0
		
	Delete Partial Column:		SIF_DELETE = 1, SIF_COLUMNS = 1
	Delete Complete Column:
		selection.right + 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeLeft	proc	near
	class	SpreadsheetClass
	uses	cx
params	local	InsertDeleteParams
	.enter	inherit
	mov	bx, cx			; bx, cx <- flags
	
EC <	call	ECCheckInstancePtr		;>
	;
	; Get the two bit masks that we care about.
	;
	andnf	bx, mask SIF_COMPLETE or mask SIF_COLUMNS
	andnf	cx, mask SIF_DELETE or mask SIF_COLUMNS

	;
	; Check the ICR or DCR case first.
	; In that case we want to check:
	;	SIF_COMPLETE = 1, SIF_COLUMNS = 0, don't care about SIF_DELETE
	;
	clr	ax			; Assume ICR or DCR

	cmp	bx, mask SIF_COMPLETE
	je	gotLeft			; Branch if ICR or DCR
	
	;
	; Check the DPC or DCC case next.
	; In that case we want to check:
	;	SIF_DELETE = 1, SIF_COLUMNS = 1, don't care about SIF_COMPLETE
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	add	ax, 1			; Assume DPC or DCC

	cmp	cx, mask SIF_DELETE or mask SIF_COLUMNS
	je	gotLeft			; Branch if DPC or DCC
	
	;
	; It's some other case. Luckily they all return the same value.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column

gotLeft:
	;
	; ax = value for the left of the range.
	;
	mov	params.IDP_insertParams.RIP_bounds.R_left, ax
	.leave
	ret
ComputeLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure IDP_insertParams.RIP_bounds.R_bottom

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
		cx	= SpreadsheetInsertFlags
RETURN:		IDP_insertParams.RIP_bounds.R_bottom set
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Insert Partial Row:		SIF_DELETE = 0, SIF_COLUMNS = 0
	Insert Complete Row:
		SSI_maxRow - (selection.height + 1)
	
	Insert Partial Column:		SIF_COMPLETE = 0, SIF_COLUMNS = 1
	Delete Partial Column:
		selection.bottom

	Insert Complete Column:		*** Other ***
	Delete Partial Row:
	Delete Complete Row:
	Delete Complete Column:
		SSI_maxRow

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeBottom	proc	near
	class	SpreadsheetClass
	uses	cx, dx
params	local	InsertDeleteParams
	.enter	inherit
	mov	bx, cx			; bx, cx <- flags
	
EC <	call	ECCheckInstancePtr		;>
	;
	; Get the two bit masks that we care about.
	;
	andnf	bx, mask SIF_DELETE or mask SIF_COLUMNS
	andnf	cx, mask SIF_COMPLETE or mask SIF_COLUMNS

	;
	; Check the IPR or ICR case first.
	; In that case we want to check:
	;	SIF_DELETE = 0, SIF_COLUMNS = 0, don't care about SIF_COMPLETE
	;
	mov	ax, LARGEST_VISIBLE_ROW		;ax <- largest legal
	mov	dx, ds:[si].SSI_maxRow		;dx <- largest for app
	cmp	ax, dx
	jbe	gotMaxRow
	mov_tr	ax, dx				;ax <- use largest for app
gotMaxRow:
	mov	dx, ax				;dx <- max row used
	sub	ax, ds:[si].SSI_selected.CR_end.CR_row
	add	ax, ds:[si].SSI_selected.CR_start.CR_row
	dec	ax

	tst	bx
	jz	gotBottom		; Branch if IPR or ICR
	
	;
	; Check the IPC or DPC case next.
	; In that case we want to check:
	;	SIF_COMPLETE = 0, SIF_COLUMNS = 1, don't care about SIF_DELETE
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row

	cmp	cx, mask SIF_COLUMNS
	je	gotBottom		; Branch if IPC or DPC
	
	;
	; It's some other case. Luckily they all return the same value.
	;
	mov_tr	ax, dx				;ax <- return last row

gotBottom:
	;
	; ax = value for the bottom of the range.
	;
	mov	params.IDP_insertParams.RIP_bounds.R_bottom, ax
	.leave
	ret
ComputeBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure IDP_insertParams.RIP_bounds.R_right

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
		cx	= SpreadsheetInsertFlags
RETURN:		IDP_insertParams.RIP_bounds.R_right set
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Insert Partial Row:		SIF_COMPLETE =0, SIF_COLUMNS = 0
	Delete Partial Row:
		selection.right

	Insert Partial Column:		SIF_DELETE = 0, SIF_COLUMNS = 1
	Insert Complete Column:
		SSI_maxCol - (selection.width + 1)

	Insert Complete Row:		*** Other ***
	Delete Partial Column:
	Delete Complete Row:
	Delete Complete Column:
		SSI_maxCol

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeRight	proc	near
	class	SpreadsheetClass
	uses	cx
params	local	InsertDeleteParams
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	bx, cx			; bx, cx <- flags
	
	;
	; Get the two bit masks that we care about.
	;
	andnf	bx, mask SIF_COMPLETE or mask SIF_COLUMNS
	andnf	cx, mask SIF_DELETE or mask SIF_COLUMNS

	;
	; Check the IPR or DPR case first.
	; In that case we want to check:
	;	SIF_COMPLETE = 0, SIF_COLUMNS = 0, don't care about SIF_DELETE
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column

	tst	bx
	jz	gotRight		; Branch if IPR or DPR
	
	;
	; Check the IPC or ICC case next.
	; In that case we want to check:
	;	SIF_DELETE = 0, SIF_COLUMNS = 1, don't care about SIF_COMPLETE
	;
	mov	ax, ds:[si].SSI_maxCol		;ax <- largest for app
	sub	ax, ds:[si].SSI_selected.CR_end.CR_column
	add	ax, ds:[si].SSI_selected.CR_start.CR_column
	dec	ax

	cmp	cx, mask SIF_COLUMNS
	je	gotRight		; Branch if IPC or ICC
	
	;
	; It's some other case. Luckily they all return the same value.
	;
	mov	ax, ds:[si].SSI_maxCol		;ax <- largest for app

gotRight:
	;
	; ax = value for the right of the range.
	;
	mov	params.IDP_insertParams.RIP_bounds.R_right, ax
	.leave
	ret
ComputeRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure IDP_insertParams.RIP_delta

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
		cx	= SpreadsheetInsertFlags
RETURN:		IDP_insertParams.RIP_delta set
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	delta.X = selection.width
	delta.Y = selection.height

	If deleting
	    negate delta.X
	    negate delta.Y

	if rows
	    delta.X = 0
	
	if columns
	    delta.Y = 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeDelta	proc	near
	class	SpreadsheetClass
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	;
	; Usage:
	;	ax = delta.X
	;	bx = delta.Y
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	sub	ax, ds:[si].SSI_selected.CR_start.CR_column
	inc	ax

	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	sub	bx, ds:[si].SSI_selected.CR_start.CR_row
	inc	bx
	
	test	cx, mask SIF_DELETE
	jz	notDeleting		; Branch if not deleting
	
	neg	ax			; We're deleting, negate the deltas
	neg	bx
notDeleting:

	test	cx, mask SIF_COLUMNS
	jnz	doingColumns		; Branch if doing columns
	
	clr	ax			; Doing rows, no X delta
doingColumns:

	test	cx, mask SIF_COLUMNS
	jz	doingRows		; Branch if doing rows
	
	clr	bx			; Doing columns, no Y delta
doingRows:

	;
	; ax = X delta
	; bx = Y delta
	;
	mov	params.IDP_insertParams.RIP_delta.P_x, ax
	mov	params.IDP_insertParams.RIP_delta.P_y, bx

	.leave
	ret
ComputeDelta	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert or delete space in the spreadsheet.

CALLED BY:	SpreadsheetInsertSpace
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertDelete	proc	near
params	local	InsertDeleteParams
	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
	call	ComputeNukeBounds	; Figure bounds we're going to delete
	
	call	ComputeNewArea		; Compute new area (if inserting)
	
	;
	; Set up the RangeEnumParams for nuking the cells.
	;
	mov	params.IDP_rep.REP_callback.segment, SEGMENT_CS
	mov	params.IDP_rep.REP_callback.offset, offset cs:NukeCallback

	lea	bx, params.IDP_rep	; ss:bx <- ptr to parameters
	clr	dl			; Only cells with data please
	call	RangeEnum
	
	;
	; We've nuked the cells. Call the cell library to move the data around.
	;
	push	bp			; Save frame ptr
	lea	bp, params.IDP_insertParams
	call	RangeInsert
	pop	bp			; Restore frame ptr
	
	;
	; Update the dependencies and references.
	;
	call	UpdateDependenciesAndReferences
	.leave
	ret
InsertDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNukeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the bounds of the range which will be going away.

CALLED BY:	InsertDelete
PASS:		ds:si	= ptr to Spreadsheet instance
		ss:bp	= Pointer to inheritable InsertDeleteParams
RETURN:		IDP_rep.REP_bounds set to the range to be nuked
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	if delta.X == 0 then
	    *** Moving data up/down ***
	    range.left  = RIP_left
	    range.right = RIP_right

	    if delta.Y > 0 then
	        *** Moving data down ***
		range.top    = RIP_bottom+1
		range.bottom = SSI_maxRow
	    else
	        *** Moving data up ***
		range.top    = RIP_top + delta.Y	(delta.Y is negative)
		range.bottom = RIP_top - 1
	    endif
	else
	    *** Moving data left/right ***
	    range.top    = RIP_top
	    range.bottom = RIP_bottom
	    
	    if delta.X > 0 then
	        *** Moving data right ***
		range.left  = RIP_right+1
		range.right = SSI_maxCol
	    else
	        *** Moving data left ***
		range.left  = RIP_left + delta.X	(delta.X is negative)
		range.right = RIP_left - 1
	    endif
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNukeBounds	proc	near
	class	SpreadsheetClass
params	local	InsertDeleteParams
	.enter	inherit
	
EC <	call	ECCheckInstancePtr		;>
	tst	params.IDP_insertParams.RIP_delta.P_x
	jnz	moveLeftRight
	
	;
	; We're moving data up or down.
	;
	mov	ax, params.IDP_insertParams.RIP_bounds.R_left
	mov	bx, params.IDP_insertParams.RIP_bounds.R_right
	
	tst	params.IDP_insertParams.RIP_delta.P_y
	js	moveUp
	
	;
	; Moving data down
	;
	mov	cx, params.IDP_insertParams.RIP_bounds.R_bottom
	inc	cx
	mov	dx, ds:[si].SSI_maxRow
	jmp	gotRange

moveUp:
	;
	; Moving data up
	;
	mov	cx, params.IDP_insertParams.RIP_bounds.R_top
	add	cx, params.IDP_insertParams.RIP_delta.P_y
	
	mov	dx, params.IDP_insertParams.RIP_bounds.R_top
	dec	dx
	jmp	gotRange

moveLeftRight:
	mov	cx, params.IDP_insertParams.RIP_bounds.R_top
	mov	dx, params.IDP_insertParams.RIP_bounds.R_bottom
	
	tst	params.IDP_insertParams.RIP_delta.P_x
	js	moveLeft
	
	;
	; Moving data right
	;
	mov	ax, params.IDP_insertParams.RIP_bounds.R_right
	inc	ax
	mov	bx, ds:[si].SSI_maxCol
	jmp	gotRange

moveLeft:
	;
	; Moving data left
	;
	mov	ax, params.IDP_insertParams.RIP_bounds.R_left
	add	ax, params.IDP_insertParams.RIP_delta.P_x
	
	mov	bx, params.IDP_insertParams.RIP_bounds.R_left
	dec	bx

gotRange:
	;
	; ax	= Left
	; bx	= Right
	; cx	= Top
	; dx	= Bottom
	;
	mov	params.IDP_rep.REP_bounds.R_left, ax
	mov	params.IDP_rep.REP_bounds.R_right, bx
	mov	params.IDP_rep.REP_bounds.R_top, cx
	mov	params.IDP_rep.REP_bounds.R_bottom, dx
	.leave
	ret
ComputeNukeBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeNewArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the new area (if we're inserting)

CALLED BY:	InsertDelete
PASS:		ss:bp	= Inheritable InsertDeleteParams
RETURN:		IDP_newArea filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeNewArea	proc	near
	uses	ax, cx
params	local	InsertDeleteParams
	.enter	inherit
	;
	; Check for inserting (positive x or y delta).
	;
	tst	params.IDP_insertParams.RIP_delta.P_x
	js	quit				; Branch if deleting
	jnz	inserting			; Branch if inserting
	tst	params.IDP_insertParams.RIP_delta.P_y
	js	quit				; Branch if deleting

inserting:
	;
	; We're inserting.
	;
	mov	ax, params.IDP_insertParams.RIP_bounds.R_top
	mov	cx, params.IDP_insertParams.RIP_bounds.R_bottom

	;
	; If we're inserting columns then ax/cx holds the top/bottom to use
	;
	tst	params.IDP_insertParams.RIP_delta.P_x
	jnz	gotTopBottom

	;
	; We're inserting rows, this means that the top is correct, but the
	; bottom is actually at 'top + delta.Y - 1'
	;
	mov	cx, ax
	add	cx, params.IDP_insertParams.RIP_delta.P_y
	dec	cx
gotTopBottom:
	;
	; ax = Top of the new area
	; cx = Bottom of the new area
	;
	mov	params.IDP_newArea.ERD_firstCell.CR_row, ax
	mov	params.IDP_newArea.ERD_lastCell.CR_row, cx


	mov	ax, params.IDP_insertParams.RIP_bounds.R_left
	mov	cx, params.IDP_insertParams.RIP_bounds.R_right

	;
	; If we're inserting rows then ax/cx holds the left/right to use
	;
	tst	params.IDP_insertParams.RIP_delta.P_y
	jnz	gotLeftRight

	;
	; We're inserting columns, this means that the left is correct, but the
	; right is actually at 'left + delta.X - 1'
	;
	mov	cx, ax
	add	cx, params.IDP_insertParams.RIP_delta.P_x
	dec	cx
gotLeftRight:
	;
	; ax = Left of the new area
	; cx = Right of the new area
	;
	mov	params.IDP_newArea.ERD_firstCell.CR_column, ax
	mov	params.IDP_newArea.ERD_lastCell.CR_column, cx

quit:	
	.leave
	ret
ComputeNewArea	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to nuke cells

CALLED BY:	InsertDelete via RangeEnumParams
PASS:		ds:si	= Spreadsheet instance
		ax	= Row
		cx	= Column
		*es:di	= Cell data (if any)
		carry set always
RETURN:		carry clear always
		dl with the REF_FREED bit set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There's a lot of data associated with a cell:
		Dependencies
		Style
		Note

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeCallback	proc	far
	class	SpreadsheetClass
	uses	bx, dx, di, bp
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]		; es:di <- ptr to cell
	
	;
	; Nuke the dependency list.
	;
	call	SpreadsheetCellNukeDependencies

	;
	; Mark the thing as not having dependencies.
	;
	mov	es:[di].CC_dependencies.segment,0
	
	SpreadsheetCellDirty			; Cell is dirty
	
	;
	; Nuke the style reference.
	;
	push	ax			; Save row

	mov	ax, es:[di].CC_attrs	; ax <- style token
	call	StyleDeleteStyleByTokenFar ; decrement style token reference

	;
	; Nuke any note.
	;
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	ax, es:[di].CC_notes.segment
	mov	di, es:[di].CC_notes.offset
	
	tst	ax			; Check for no note
	jz	skipNoteFree		; Branch if no note
	call	DBFree			; Free the notes dbase item
skipNoteFree:

	pop	ax			; Restore the row

	;
	; Unlock the cell and remove it from any dependency lists.
	;
	SpreadsheetCellUnlock
	
	mov	dx, -1			; Signal: Remove dependencies
	call	FormulaCellAddParserRemoveDependencies
	
	;
	; ax	= Row
	; cx	= Column
	;
	clr	dx			; dx == 0 means nuke the cell
	SpreadsheetCellReplaceAll

	.leave
	or	dl, mask REF_OTHER_ALLOC_OR_FREE or mask REF_CELL_FREED
	clc				; Signal: continue
	ret
NukeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDeleteSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear selected cells (data, notes *and* attributes)

CALLED BY:	MSG_META_DELETE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetDeleteSelected	method	SpreadsheetClass,
				MSG_META_DELETE
if _PROTECT_CELL
	;
	; In Jedi version, we have to make sure the range to be cut doesn't 
	; contains any protected cell. We need to abort the operation if it
	; does.
	;
	push	si, ax
	mov	si, di				;ds:si = spreadsheet instance
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	CheckProtectedCell		;jmp if protected cell found
	pop	si, ax
	jc	protectionError

	mov	cx, mask SCF_CLEAR_DATA or \
			mask SCF_CLEAR_ATTRIBUTES or \
			mask SCF_CLEAR_NOTES
	call	SpreadsheetClearSelected
	ret

protectionError:
	;
	; Print out the cell protection error message.
	;
	mov	si, offset CellProtectionError
	call	PasteNameNotifyDB
	ret
else
	mov	cx, mask SCF_CLEAR_DATA or \
			mask SCF_CLEAR_ATTRIBUTES or \
			mask SCF_CLEAR_NOTES
	FALL_THRU	SpreadsheetClearSelected
endif

SpreadsheetDeleteSelected		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetClearSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear selected cells (data, notes and/or attributes)

CALLED BY:	MSG_SPREADSHEET_CLEAR_SELECTED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cx - SpreadsheetClearFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version
	gene	8/12/92		new header, documentation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetClearSelected		method SpreadsheetClass,
						MSG_SPREADSHEET_CLEAR_SELECTED
	locals	local	CellLocals
	.enter

EC<	test	cx, not (mask SCF_CLEAR_ATTRIBUTES or \
			mask SCF_CLEAR_DATA or \
		mask SCF_CLEAR_NOTES) >
EC<	ERROR_NE SPREADSHEET_ROUTINE_USING_BAD_PARAMS >
EC<	test	cx, mask SCF_CLEAR_ATTRIBUTES or \
		mask SCF_CLEAR_DATA or \
		mask SCF_CLEAR_NOTES >
EC<	ERROR_E	SPREADSHEET_ROUTINE_USING_BAD_PARAMS >

	call	SpreadsheetMarkBusy

	mov	si, di			; ds:si <- ptr to spreadsheet instance

	mov	locals.CL_data1, cx	; store SpreadsheetClearFlags

	clr	di			;di <- RangeEnumFlags
	mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	locals.CL_params.REP_callback.offset, offset ClearCellWithFlags
	call	CallRangeEnumSelected	; destroys ax,bx,cx,dx,di
	;
	; See if we called back for any cells or not...
	;
	tst	ss:locals.CL_data1.high
	jz	done				;branch if no cells
	;
	; Assume we're deleting nothing
	;
	clr	ax
	;
	; If we're deleting data, make a second pass to recalculate
	; the dependencies.
	;
	test	cx, mask SCF_CLEAR_DATA
	jz	noRecalc			;branch if not clearing data
	mov	di, mask REF_NO_LOCK		;di <- RangeEnumFlags
	mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	locals.CL_params.REP_callback.offset, offset RecalcCell
	call	CallRangeEnumSelected
	;
	; If we're deleting data, we need to update the edit bar
	;
	ornf	ax, mask SNF_EDIT_BAR
noRecalc:
	;
	; If we're in engine mode, we don't need to do any additional work
	; (ie. no UI update, no document size calc, no redraw)
	;
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	done
	;
	; If we're deleting notes, we need to update the note window
	;
	test	cx, mask SCF_CLEAR_NOTES
	jz	noNotes
	ornf	ax, mask SNF_CELL_NOTES
noNotes:
	;
	; If we're deleting attributes, recalculate the row heights
	;
	test	cx, mask SCF_CLEAR_ATTRIBUTES
	jz	noRowHeights
	push	ax
	call	RecalcRowHeightsFar		; destroys ax,bx,cx,dx
	pop	ax
	;
	; Update the view document size, update the UI, and redraw
	;
	ornf	ax, SNFLAGS_SELECTION_ATTRIBUTES_CHANGE
	call	UpdateDocUIRedrawAll
	jmp	done

	;
	; We're not deleting attributes, so just redraw the selection
	;
noRowHeights:
	call	UpdateUIRedrawSelection
done:
	call	SpreadsheetMarkNotBusy

	.leave
	ret
SpreadsheetClearSelected		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetClearRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears a range of cells (data, notes and/or attributes)

CALLED BY:	PasteCommon

PASS:		ds:si = SpreadsheetClass instance data
   		ss:bp = CellRange
   		cx    = SpreadsheetClearFlags

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	5/ 3/94    	Altered version of SpreadsheetClearSelected

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetClearRange	proc	far
	
	uses	ax,bx,cx,dx,di
	locals	local	CellLocals	; ss:[bp] = CellRange (saved before
   					; space for 'locals' variable 
	.enter

EC<	test	cx, not (mask SCF_CLEAR_ATTRIBUTES or \
			mask SCF_CLEAR_DATA or \
		mask SCF_CLEAR_NOTES) >
EC<	ERROR_NE SPREADSHEET_ROUTINE_USING_BAD_PARAMS >
EC<	test	cx, mask SCF_CLEAR_ATTRIBUTES or \
		mask SCF_CLEAR_DATA or \
		mask SCF_CLEAR_NOTES >
EC<	ERROR_E	SPREADSHEET_ROUTINE_USING_BAD_PARAMS >

	mov	locals.CL_data1, cx	; store SpreadsheetClearFlags

   ; -------------------------------------------------------
   ; Make the call that deletes the specified range of cells
   ; -------------------------------------------------------
	mov	di, ss:[bp]		; ss:di = CellRange parameters
	mov	ax, ss:[di].CR_start.CR_row
	mov	cx, ss:[di].CR_start.CR_column
	mov	bx, ss:[di].CR_end.CR_row
	mov	dx, ss:[di].CR_end.CR_column	
	clr	di			; di <- RangeEnumFlags
	mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	locals.CL_params.REP_callback.offset, offset ClearCellWithFlags
   	
	call	CallRangeEnum
   ; ---------------------------------------------
   ; See if we called back for any cells or not...
   ; ---------------------------------------------
	tst	ss:locals.CL_data1.high
	jz	done			;branch if no cells
   ; -----------------------------
   ; Assume we're deleting nothing
   ; -----------------------------
	clr	ax
   ; ---------------------------------------------------------
   ; If we're deleting data, make a second pass to recalculate
   ; the dependencies.
   ; ---------------------------------------------------------
	test	locals.CL_data1, mask SCF_CLEAR_DATA
	jz	done			;done if not clearing data

	mov	di, ss:[bp]		; ss:di = CellRange parameters
	mov	ax, ss:[di].CR_start.CR_row
	mov	cx, ss:[di].CR_start.CR_column
	mov	bx, ss:[di].CR_end.CR_row
	mov	dx, ss:[di].CR_end.CR_column
	mov	di, mask REF_NO_LOCK	; di <- RangeEnumFlags
	mov	locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	locals.CL_params.REP_callback.offset, offset RecalcCell
	
	call	CallRangeEnum		; destroys ax,bx,cx,dx,di
done:
	.leave
	ret
SpreadsheetClearRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear portions (or all of) a cell
CALLED BY:	SpreadsheetClearSelected() via RangeEnum()

PASS:		ClearCellWithFlags():
		    ss:bp - ptr to CallRangeEnum() local variables
			CL_data1.low = SpreadsheetClearFlags
			CL_data1.high - flag: ClearCell been called
		ClearCell():
			dh - SpreadsheetClearFlags
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data, if any

RETURN:		carry - set to abort enum
		dl - RangeEnumFlags
			REF_CELL_FREED - if cell freed
			REF_OTHER_ALLOC_OR_FREE - if other cell freed
		    ss:bp - ptr to CallRangeEnum() local variables
			CL_data1.high - flag: TRUE: ClearCell has been called
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version
	eca	7/16/92		rewrote, documented

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearCellWithFlags	proc	far
locals	local	CellLocals
	.enter	inherit
	mov	dh, {byte}locals.CL_data1	;dh <- SpreadsheetClearFlags
	mov	ss:locals.CL_data1.high, BB_TRUE
	.leave
	FALL_THRU	ClearCell
ClearCellWithFlags	endp

ClearCell	proc	far
	uses	ax, bx, di
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit far

EC <	call	ECCheckInstancePtr		;>
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>

	clr	dl				;dl <- RangeEnumFlags
	mov	di, es:[di]			;es:di <- ptr to cell
	;
	; If we're deleting the attributes...
	;
	test	dh, mask SCF_CLEAR_ATTRIBUTES
	jz	skipAttributes
	;
	; Replace the current style token with the default,
	; and decrement the reference count for it.
	; NOTE: this should be DEFAULT_STYLE_TOKEN, and not the column
	; default attribute, because we want to revert to the base styles
	; (which are token 0) regardless of what the column defaults are.
	;
	push	ax
	mov	ax, DEFAULT_STYLE_TOKEN		;ax <- default style token
	cmp	es:[di].CC_attrs, ax		;any change?
	je	noAttributes			;branch if already default
	xchg	es:[di].CC_attrs, ax		;ax <- old token
	SpreadsheetCellDirty
	call	StyleDeleteStyleByTokenFar	;one less reference to old
noAttributes:
	pop	ax
skipAttributes:
	;
	; If we're deleting notes...
	;
	test	dh, mask SCF_CLEAR_NOTES
	jz	skipNotes
	;
	; See if the cell even has notes
	;
	push	ax
	clr	ax				;ax <- new note
	xchg	es:[di].CC_notes.segment, ax
	tst	ax				;any notes?
	jz	noNotes				;branch if no notes
	;
	; Free the note DB item, and dirty the cell
	;
	push	di				;save cell ptr
	mov	di, es:[di].CC_notes.offset	;ax,di <- DB group,item
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	DBFree				;free the old note
	SpreadsheetCellDirty
	pop	di				;es:di = cell data
noNotes:
	pop	ax
skipNotes:
	;
	; If we're deleting data, delete the whole cell (if possible)
	;
	test	dh, mask SCF_CLEAR_DATA
	jnz	doDeleteCheck
	;
	; If we weren't deleting the cell data, we may still be able to
	; delete the cell, if the attributes or the notes were the only
	; thing of interest in it before.
	;
	cmp	es:[di].CC_type, CT_EMPTY	;'empty' cell?
	jne	skipDelete
	;
	; See if we will actually be able to delete the cell.
	; If dependencies, notes or non-default attributes exist, we can't
	;
doDeleteCheck:
	tst	es:[di].CC_notes.segment	;notes?
	jnz	skipUnlock
	tst	es:[di].CC_dependencies.segment	;dependencies?
	jnz	skipUnlock
	;
	; NOTE: this checks agains default column attributes, because if a
	; cell is deleted, it will be recreated with those attributes
	;
	push	dx
	call	ColumnGetDefaultAttrs		;dx <- default column attrs
	cmp	es:[di].CC_attrs, dx		;default attrs?
	pop	dx
	jnz	skipUnlock
	;
	; The cell will really be deleted -- unlock it, lest
	; RangeEnum() become horribly confused...
	;
	SpreadsheetCellUnlock
skipUnlock:
	call	DeleteCell
skipDelete:
	clc					;carry <- don't abort

	.leave
	ret

ClearCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a cell's dependents
CALLED BY:	SpreadsheetClearSelected() via RangeEnum()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)

RETURN:		carry - set to abort enum
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecalcCell	proc	far
	uses	di
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; See if the cell has any dependencies
	;
	SpreadsheetCellLock
	jnc	done				;branch if no cell data
	mov	di, es:[di]			;es:di <- ptr to data
	tst	es:[di].CC_dependencies.segment	;clears carry
	SpreadsheetCellUnlock			;preserves flags
	jz	done				;branch if no dependencies
	;
	; The cell has dependencies -- recalculate them
	;
	call	RecalcDependents		;returns carry for error
done:

	.leave
	ret
RecalcCell	endp

SpreadsheetSortSpaceCode	ends
