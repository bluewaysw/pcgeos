COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupParam.asm

AUTHOR:		John Wedgwood, Nov  6, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/ 6/91	Initial revision

DESCRIPTION:
	Routines that interact with the data block

	$Id: cgroupData.asm,v 1.1 97/04/04 17:45:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put new data into the chart.  Set the
		ChartDataAttributes based on the data in the data
		block.

CALLED BY:	via MSG_CHART_OBJECT_SET_DATA

PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= VM block handle of data block

RETURN:		al - ChartReturnType

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupSetData	method dynamic	ChartGroupClass,
			MSG_CHART_GROUP_SET_DATA
	uses	cx,dx,bp
	.enter
	ornf	ds:[di].CGI_buildChangeFlags, mask BCF_DATA

	mov	bx, cx			; new VM data block

	;
	; Save the old series / category count in case it's going to
	; change. 
	;

	mov	ax, MSG_CHART_GROUP_GET_SERIES_COUNT
	call	ObjCallInstanceNoLock
	push	cx			; old series count

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock
	push	cx			; old category count

	;
	; Set the new data block, and free the old one
	;

	DerefChartObject ds, si, di
	xchg	bx, ds:[di].CGI_data
	tst	bx
	jz	afterFree

	mov_tr	ax, bx
	call	GetFileHandle
	call	VMFree
afterFree:
	call	ChartGroupSetDataAttributes

	;
	; See if the series / category count has changed
	;
	clr	bx

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	call	ObjCallInstanceNoLock

	pop	ax			; old category count
	cmp	ax, cx
	je	afterCategories
	mov	bx, mask BCF_CATEGORY_COUNT

afterCategories:

	mov	ax, MSG_CHART_GROUP_GET_SERIES_COUNT
	call	ObjCallInstanceNoLock

	pop	ax			; old series count
	cmp	ax, cx
	je	saveChanges
	ornf	bx, mask BCF_SERIES_COUNT

saveChanges:
	DerefChartObject ds, si, di
	or	ds:[di].CGI_buildChangeFlags, bx

	call	CheckToCreateChartTitleFromPassedData
	call	ObjMarkDirty
	.leave
	ret
ChartGroupSetData	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckToCreateChartTitleFromPassedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the chart data has both series titles and category
		titles, and the upper left-hand corner has text in it, and
		we don't already have a chart title, then create one with
		this text.
	
CALLED BY:	ChartGroupSetData

PASS:		*ds:si - chart group

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,bp,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckToCreateChartTitleFromPassedData	proc near

	class	ChartGroupClass

	.enter

	;
	; data MUST have both series and category titles 
	;

	DerefChartObject ds, si, di
	mov	al, ds:[di].CGI_dataAttrs
	and	al, mask CDA_HAS_CATEGORY_TITLES or mask CDA_HAS_SERIES_TITLES
	cmp	al, mask CDA_HAS_CATEGORY_TITLES or mask CDA_HAS_SERIES_TITLES
	jne	done

	;
	; Chart shouldn't already have a title
	;
	test	ds:[di].CGI_groupFlags, mask CGF_CHART_TITLE
	jnz	done

	;
	; Make sure the cell in the first row/column is non-empty
	;

	mov	al, ds:[di].CGI_dataAttrs
	clr	cx, dx
	call	LockDataBlock
	push	bx
	
	call	GetDataEntry
	cmp	al, CDCT_EMPTY
	je	unlock


	;
	; There's something there -- create a chart title.
	;

	mov	ax, MSG_CHART_GROUP_SET_GROUP_FLAGS
	mov	cl, mask CGF_CHART_TITLE
	clr	ch
	call	ObjCallInstanceNoLock

unlock:
	pop	bx
	call	UnlockDataBlock

done:

	.leave
	ret
CheckToCreateChartTitleFromPassedData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file handle of the current file

CALLED BY:

PASS:		ds - data segment of block of file in question.

RETURN:		bx - VM file handle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileHandle	proc near	
	uses	ax
	.enter
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo
	mov	bx, ax

	.leave
	ret
GetFileHandle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the data block

CALLED BY:	Utility
PASS:		ds	= Chart block segment
RETURN:		es	= Segment address of the data block
		bx	= mem handle of data block

DESTROYED:	nothing


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
assume	ds:ChartUI

LockDataBlock	proc	near
	class	ChartGroupClass
	uses	ax, bp, si
	.enter
	mov	si, ds:[TemplateChartGroup]
	mov	ax, ds:[si].CGI_data	; ax <- params block handle
	call	GetFileHandle
	call	VMLock				; ax <- segment
						; bx <- handle
	mov	es, ax				; Return segment in es
	mov	bx, bp

	; Check that the block is valid	
EC <	call	ECCheckParamsBlock			>
	
	.leave
	ret
LockDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the data block

CALLED BY:	Utility

PASS:		bx - memory handle of data block

RETURN:		nothing

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDataBlock	proc	near
	.enter
	xchg	bp, bx
	call	VMUnlock
	xchg	bp, bx
	.leave
	ret
UnlockDataBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each category.

CALLED BY:	Utility
PASS:		ds:di 	= ChartGroup instance
		bx	= Callback routine (must be in ChartGroupCode segment)
		ax,cx	= Arguments to callback

RETURN:		carry set if callback aborted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach category:
	    CallCallback(category, args)

	Callback should be defined as:
		PASS:	ds:di	= ChartGroup instance
			ax,cx	= Arguments
			dx	= Category number
		RETURN:	carry set to abort processing
			ax,cx	= Arguments to next callback
		DESTROYED: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachCategory	proc	near
	uses	bx, dx, bp
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	;
	; Count the number of categories
	;
	push	cx
	call	ChartGroupGetCategoryCount
	dec	cx
	mov	bp, cx				; last category
	clr	dx				; first category
	pop	cx
	call	ForeachCategoryInRange
	.leave
	ret
ForeachCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each series

CALLED BY:	Utility
PASS:		*ds:si	= ChartGroup instance
		ax	= Callback routine (must be in ChartGroupCode segment)
		dx,bp	= Arguments to callback
RETURN:		carry set if callback aborted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach series;
	    CallCallback(series, args)

	Callback should be defined as:
		PASS:	*ds:si	= ChartGroup instance
			dx,bp	= Arguments
			cx	= Series number
		RETURN:	carry set to abort processing
			dx,bp	= Arguments to next callback
		DESTROYED: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachSeries	proc	near
	uses	cx
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	call	ChartGroupGetSeriesCount	; last series
	dec	cl
	mov	ch, cl
	clr	cl				; cx <- first series
	call	ForeachSeriesInRange
	.leave
	ret
ForeachSeries	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachSeriesInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each series of a given range

CALLED BY:	Utility
PASS:		*ds:si	= ChartGroup instance
		ax	= Callback routine (must be in ChartGroupCode
		segment)
		cl - first series to call
		ch - last series to call

		dx,bp	= Arguments to callback

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach series;
	    CallCallback(series, args)

	Callback should be defined as:
		PASS:	*ds:si	= ChartGroup instance
			dx,bp	= Arguments
			cx	= Series number
		RETURN:	carry set to abort processing
			dx,bp	= Arguments to next callback
		DESTROYED: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachSeriesInRange	proc	near
	uses	cx
	.enter
callLoop:
	;
	; ax	= Callback
	; cl	= Current series
	; ch 	= last series
	; di	= Total number of series
	; *ds:si= Plot group
	; dx,bp	= Arguments to callback
	;
	cmp	cl, ch
	ja	doneNoAbort			; Branch if too far
	
	call	ax				; Call callback
	jc	done
	inc	cl				; Move to next series
	jmp	callLoop
doneNoAbort:
	clc
done:
	.leave
	ret
ForeachSeriesInRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSeriesCategoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a number from the data block. 

CALLED BY:	

PASS:		cl - series #
		dx - category #
		al - ChartDataAttributes
		es - segment of params block
		ds:di - ChartGroup instance data

RETURN:		es:di - pointer to data entry
		al - ChartDataCellType 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSeriesCategoryEntry	proc near	
	uses	bx,cx,dx,bp
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	mov	bp, di			; instance ptr

	mov	bl, al			; ChartDataAttributes

	push	cx, dx
	call	AdjustForTitles
	call	GetDataEntry
	pop	cx, dx

	; If it's not a number, then done

	cmp	al, CDCT_NUMBER
	jne	done

	; Otherwise, if there are duplicates, then figure out the
	; offset into the dup area, and use that.

	test	bl, mask CDA_HAS_DUPLICATES
	jz	done

	; Get the number from the "duplicate" table.  Multiply by size
	; FloatNum and add to es:[endOfData]

	; offset = endOfData + (numCategories*seriesNum + catNum)*size Float

	mov	al, cl
	clr	ah
	mov	di, bp				; instance ptr
	call	ChartGroupGetCategoryCount	; cx = category count
	mov	di, dx				; category #
	mul	cx
	add	ax, di
	mov	cx, size FloatNum
	mul	cx
	mov	di, ax
	add	di, es:[CD_endOfData]
	mov	al, CDCT_NUMBER

						; al <- entry type
done:
	.leave
	ret
GetSeriesCategoryEntry	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust series and category numbers for titles

CALLED BY:

PASS:		al - ChartDataAttributes
		cl - series number
		dx - category number

RETURN:		cl - series number, adjusted
		dx - category number, adjusted

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForTitles	proc near	
	.enter
	test	al, mask CDA_HAS_CATEGORY_TITLES
	jz	noIncSeries
	inc	cl
noIncSeries:

	test	al, mask CDA_HAS_SERIES_TITLES
	jz	noIncCategory
	inc	dx
noIncCategory:

	.leave
	ret
AdjustForTitles	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a field from the data block.  Don't adjust
		for titles, but adjust for row/column orientation

CALLED BY:	Utility

PASS:		al	= ChartDataAttributes
		cl	= Series number (adjusted for titles)
		dx	= Category number (adjusted for titles)
		es	= Segment address of the data block

RETURN:		al	= Type of the data
		es:di	= Pointer to the data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (rowsAreSeries) {
	    entry = (series * nColumns) + category
	} else {
	    entry = (category * nColumns) + series
	}
	
	ptr = table[entry*2]
	
	type = *ptr
	data = ptr+1
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDataEntry	proc	near
	uses	cx, dx
	.enter
	clr	ch
	test	al, mask CDA_ROWS_ARE_SERIES
	jnz	gotRowColumn
	xchg	cx, dx
gotRowColumn:
	call	GetRowColumnEntry
	.leave
	ret
GetDataEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRowColumnEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an entry given row and column numbers

CALLED BY:

PASS:		cx - row number
		dx - column number
		es - data block
		al - ChartDataAttributes

RETURN:		es:di - data entry
		al - ChartDataCellType

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRowColumnEntry	proc near	
	uses	cx, dx
	.enter

EC <	cmp	cx, es:CD_nRows				>
EC <	ERROR_AE ROW_TOO_LARGE				>
EC <	cmp	dx, es:CD_nColumns			>
EC <	ERROR_AE COLUMN_TOO_LARGE			>

	mov	di, dx				; di <- column number

	mov	ax, cx				; ax <- row number
	mul	es:CD_nColumns			; ax <- partial result
	add	di, ax				; di <- entry number
	;
	; di	= Entry number
	;
	shl	di, 1				; ax <- index
	mov	di, es:CD_cellOffsets[di]	; di <- ptr to cell data
	
	mov	al, {byte} es:[di]		; al <- type
	inc	di				; di <- ptr to data
	.leave
	ret
GetRowColumnEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupSetDataAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the data block and determine the following
		things:

		Whether it has row/column headings
		Whether rows or columns are series
		Whether there's any data to chart

CALLED BY:	ChartGroupSetData

PASS:		*ds:si - ChartGroup object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Assume that rows are series

	If (first row contains text)
		set HAS_CATEGORY_TITLES
	if (first column has text)
		set HAS_SERIES_TITLES

	numSeries = numRows (-1 if cat titles)
	numCats = numRows (-1 if series titles)

	if not(OVERRIDE)
		if numSeries <= numCategories
			set ROWS_ARE_SERIES
		else
			clear ROWS_ARE_SERIES
			
	if not(ROWS_ARE_SERIES)
		swap the HAS_CATEGORY_TITLES and the HAS_SERIES_TITLES
		flags. 


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/19/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupSetDataAttributes	proc near	

		.enter
	
		class	ChartGroupClass
		
		call	LockDataBlock
		
	;
	; Fetch the old set of attributes
	;
		
		mov	al, ds:[di].CGI_dataAttrs
		
		call	DetermineIfHasSeriesTitles
		call	DetermineIfHasCategoryTitles
		
	; Determine the number of NUMERIC rows and columns
		
		mov	cx, es:[CD_nRows]	
EC <		cmp	cx, MAX_CATEGORY_COUNT+1	>
EC <		ERROR_A TOO_MANY_ROWS			>
		mov	dx, es:[CD_nColumns]
EC <		cmp	dx, MAX_CATEGORY_COUNT+1	>
EC <		ERROR_A TOO_MANY_COLUMNS		>
		
		test	al, mask CDA_HAS_SERIES_TITLES
		jz	gotNumColumns
		dec	dx
		
gotNumColumns:
		test	al, mask CDA_HAS_CATEGORY_TITLES
		jz	gotNumRows
		dec	cx
		
gotNumRows:
		
	;
	; cx - # of rows
	; dx - # of columns
	;
	; ROWS are always series, (4/93), except for pie charts
	;
		
		or	al, mask CDA_ROWS_ARE_SERIES

		cmp	ds:[di].CGI_type, CT_PIE
		jne	gotFlag

		
	;
	; In a pie chart, if there are more rows than columns, then 
	; clear the ROWS_ARE_SERIES flag (thus, columns will be series).
	; 
	;
		cmp	cx, dx		; compare rows, columns
		jle	gotFlag

		and	al, not mask CDA_ROWS_ARE_SERIES

gotFlag:
		
	;
	; Up until now, I've assumed that ROWS are SERIES and COLUMNS
	; are categories.  If the opposite is true, then swap
	; the HAS_SERIES_TITLES and HAS_CATEGORY_TITLES flags
	;
		
		mov	ah, al			; make a copy
		test	al, mask CDA_ROWS_ARE_SERIES
		jnz	storeFlags

	;
	; Clear both bits 
	;

		and	ah, not (mask CDA_HAS_SERIES_TITLES or \
				mask CDA_HAS_CATEGORY_TITLES)

	;
	; Set (dest)CATEGORY_TITLES if (source)SERIES_TITLES is set
	;

		test	al, mask CDA_HAS_SERIES_TITLES
		jz	gotCategoryTitles
		or	ah, mask CDA_HAS_CATEGORY_TITLES

gotCategoryTitles:
	;
	; Set (dest)SERIES_TITLES if (source)CATEGORY_TITLES is set
	;

		test	al, mask CDA_HAS_CATEGORY_TITLES
		jz	storeFlags
		or	ah, mask CDA_HAS_SERIES_TITLES

storeFlags:	
		mov	ds:[di].CGI_dataAttrs, ah
		call	UnlockDataBlock
		.leave
		ret

ChartGroupSetDataAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineIfHasSeriesTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assuming that ROWS are SERIES, see if the first column
		contains titles, and if so, set CDA_HAS_SERIES_TITLES	

CALLED BY:	ChartGroupSetDataAttributes

PASS:		es - param block
		al - original ChartDataAttributes

RETURN:		al - ChartDataAttributes with
			CDA_HAS_SERIES_TITLES flag set correctly

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	If nRows == 1
		startRow = 0
	else	
		startRow = 1
	
	if there are ANY text cells, then has titles
	else
		if there are ANY numeric cells, then doesn't have
		titles
		else
			has titles

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetermineIfHasSeriesTitles	proc near	
	uses	bx,cx,dx,bp,di
	.enter
	mov	bl, al			; ChartDataAttributes

	clr	cx, dx
	mov	bp, es:[CD_nRows]
	cmp	bp, 1
	je	gotCount
	inc	cx

gotCount:

	;
	; Search for text
	;

	push	cx
textLoop:
	call	GetRowColumnEntry
	cmp	al, CDCT_TEXT
	je	hasTitlesPopCX
	inc	cx
	cmp	cx, bp
	jl	textLoop

	;
	; There's no text, see if there're any numbers
	;

	pop	cx
numLoop:
	call	GetRowColumnEntry
	cmp	al, CDCT_NUMBER
	je	noTitles
	inc	cx
	cmp	cx, bp
	jl	numLoop

	;
	; This column is empty.  Assume it's titles.  
	;
hasTitles:
	ornf	bl, mask CDA_HAS_SERIES_TITLES
	jmp	done

noTitles:
	andnf	bl, not mask CDA_HAS_SERIES_TITLES
done:
	mov	al, bl
	.leave
	ret

hasTitlesPopCX:
	pop	cx
	jmp	hasTitles

DetermineIfHasSeriesTitles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineIfHasCategoryTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if all the entries in the first row are numbers.

CALLED BY:

PASS:		es - param block
		al - ChartDataAttributes

RETURN:		al - ChartDataAttributes with
			CDA_HAS_CATEGORY_TITLES flag set correctly.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Same as above.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure is almost identical to the one above. Yuck!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetermineIfHasCategoryTitles	proc near	
	uses	bx,cx,dx,bp,di
	.enter

	mov	bl, al			; ChartDataAttributes

	clr	cx, dx
	mov	bp, es:[CD_nColumns]
	cmp	bp, 1
	je	gotCount
	inc	dx

gotCount:
	;
	; Search for text
	;

	push	dx
textLoop:
	call	GetRowColumnEntry
	cmp	al, CDCT_TEXT
	je	hasTitlesPopDX
	inc	dx
	cmp	dx, bp
	jl	textLoop

	;
	; There's no text, see if there're any numbers
	;

	pop	dx
numLoop:
	call	GetRowColumnEntry
	cmp	al, CDCT_NUMBER
	je	noTitles
	inc	dx
	cmp	dx, bp
	jl	numLoop

	;
	; This column is empty.  Assume it's titles.  
	;
hasTitles:
	ornf	bl, mask CDA_HAS_CATEGORY_TITLES
	jmp	done

noTitles:
	andnf	bl, not mask CDA_HAS_CATEGORY_TITLES
done:
	mov	al, bl
	.leave
	ret

hasTitlesPopDX:
	pop	dx
	jmp	hasTitles

DetermineIfHasCategoryTitles	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupFixupNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix-up the numbers in the data block to represent
		what the user wants

CALLED BY:

PASS:		*ds:si - ChartGroup object
		ds:di - instance data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If STACKED 
		if SINGLE_SERIES
			Make the first series STACKED
		else
			Make each category STACKED
		endif

	If FULL
		if SINGLE_SERIES
			Make the first series FULL
		else
			Make each category FULL
		endif
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupFixupNumbers	proc near	
	uses	ax,bx,cx,dx,di,si,es
	class	ChartGroupClass
	.enter
	call	LockDataBlock
	push	bx

	mov	ax, ds:[di].CGI_flags

	; check if stacked
	test	ax, mask CF_STACKED
	jz	afterStacked

	test	ax, mask CF_SINGLE_SERIES
	jz	multipleSeries

	; Single series (ie, pie chart)

	clr	cl
	call	ChartGroupMakeSeriesStacked
	jmp	afterStacked

multipleSeries:
	; Multiple series, make each category stacked.

	mov	bx, offset ChartGroupMakeCategoryStacked
	call	ForeachCategory

afterStacked:
	test	ax, mask CF_FULL
	jz	done

	test	ax, mask CF_SINGLE_SERIES
	jz	multipleSeriesFull
	call	ChartGroupMakeSeriesFull
	jmp	done

multipleSeriesFull:
	; Make each category FULL
	mov	bx, offset ChartGroupMakeCategoryFull
	call	ForeachCategory
done:

	pop	bx
	call	UnlockDataBlock
	.leave
	ret
ChartGroupFixupNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeCategoryStacked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert all the series of the current category to
		"cumulative" values.

CALLED BY:

PASS:		dx - category number
		*ds:si - ChartGroup
		es - segment of params block
		bp low - ChartDataAttributes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeCategoryStacked	proc near	
	uses	ax
	.enter
	call	Float0		; put total on FP stack
	mov	ax, offset ChartGroupMakeEntryStacked
	call	ForeachSeries
	call	FloatDrop
	.leave
	ret
ChartGroupMakeCategoryStacked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeSeriesStacked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current series "stacked"

CALLED BY:

PASS:		cl - series #
		ds:di - ChartGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeSeriesStacked	proc near	
	uses	ax,bx
	.enter
EC <	call	ECCheckChartGroupDSDI		> 

	call	Float0		; put total on FP stack
	mov	bx, offset ChartGroupMakeEntryStacked
	call	ForeachCategory
	call	FloatDrop

	.leave
	ret
ChartGroupMakeSeriesStacked	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeEntryStacked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current series entry cumulative

CALLED BY:

PASS:		ds:di - ChartGroup
		cl - series #
		dx - category #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeEntryStacked	proc near	
		uses	ax,ds,si,di
		class	ChartGroupClass 
		.enter

EC <		call	ECCheckChartGroupDSDI		> 

		mov	al, ds:[di].CGI_dataAttrs
		call	GetSeriesCategoryEntry	; es:di - number
		cmp	al, CDCT_NUMBER
		jne	done

		segmov	ds, es, si
		mov	si, di
		call	FloatPushNumber		; push it, baby!

	;
	; Take absolute value, to keep us out of trouble
	;
		
		call	FloatAbs
		call	FloatAdd		; add to total
		call	FloatDup		; keep total on stack
		call	FloatPopNumber		; stick number back in block
done:
		clc				; don't halt enumeration
		.leave
		ret
ChartGroupMakeEntryStacked	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeCategoryFull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current category "full"

CALLED BY:

PASS:		ds:di - ChartGroup
		dx - category #

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Get MAX for this category
	multiply every entry by 1/max

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeCategoryFull	proc near	
	uses	ax,cx,dx,bp
	.enter

	; Get the max/min for all series for this category

	mov	bp, dx			; category number
	mov	cx, (MAX_SERIES_COUNT shl 8)
	call	ChartGroupGetRangeMaxMin
	jc	done
	call	FloatDrop		; get rid of MIN

	call	FloatInverse		; FP: 1/max

	mov	ax, offset ChartGroupMakeEntryFull
	call	ForeachSeries

	call	FloatDrop		; drop category max
done:
	.leave
	ret
ChartGroupMakeCategoryFull	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeSeriesFull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make series 0 "full"

CALLED BY:	ChartGroupFixupNumbers

PASS:		ds:di - ChartGroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeSeriesFull	proc near	
	uses	ax,bx,cx,dx,bp
	.enter

	; Get the max/min for all categories for this series

	clr	cx, dx		; series, category #
	mov	bp, MAX_CATEGORY_COUNT
	call	ChartGroupGetRangeMaxMin
	jc	done
	call	FloatDrop		; get rid of min
	call	FloatInverse		; FP: 1/max

	mov	bx, offset ChartGroupMakeEntryFull
	call	ForeachCategory
	call	FloatDrop		; drop max
done:
	.leave
	ret
ChartGroupMakeSeriesFull	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupMakeEntryFull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply the current value by 1/max

CALLED BY:

PASS:		es - param block
		FP stack:	1/MAX  
		ds:di - ChartGroup
		cl - series #
		dx - category #

RETURN:		FP stack unchanged

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupMakeEntryFull	proc near	
	uses	ax,cx,dx,ds,si,di
	class	ChartGroupClass 
	.enter
EC <	call	ECCheckChartGroupDSDI		> 


	mov	al, ds:[di].CGI_dataAttrs
	call	GetSeriesCategoryEntry
	cmp	al, CDCT_NUMBER
	jne	done

	call	FloatDup		; FP: 1/max 1/max

	segmov	ds, es, si
	mov	si, di
	call	FloatPushNumber		; FP: 1/max 1/max, cur

	call	FloatMultiply	; 1/max, 1/max * cur
	call	FloatPopNumber
done:
	clc
	.leave
	ret
ChartGroupMakeEntryFull	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupDuplicateNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a duplicate copy of the numeric data, if need be.

CALLED BY:	

PASS:		ds:di - ChartGroup instance data.

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupDuplicateNumbers	proc near	
	uses	ax,bx,cx,dx,di,si,bp,es
	class	ChartGroupClass 
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	; For now, reset the DUPLICATES flag, so routines will think
	; there are none.

	BitClr	ds:[di].CGI_dataAttrs, CDA_HAS_DUPLICATES

	call	LockDataBlock	; BX <= block handle

	; See if we need duplicates
	test	ds:[di].CGI_flags, 
		mask CF_STACKED or mask CF_FULL
	jz	noDuplicates

	; Determine additional size needed:
	; seriesCount * categoryCount * size FloatNum

	call	ChartGroupGetSeriesCount
	mov	ax, cx
	call	ChartGroupGetCategoryCount
	mul	cx
	mov	cx, size FloatNum
	mul	cx
	ECMakeSureZero	dx

	; reallocate block for bigger size

	call	ReAllocDataBlock

	mov	al, ds:[di].CGI_dataAttrs
	call	CopyNumbersToDuplicates

EC <	call	ECCheckChartGroupDSDI			>
	BitSet	ds:[di].CGI_dataAttrs, CDA_HAS_DUPLICATES

	; Now, fix up the duplicates for stacked, etc.

	call	ChartGroupFixupNumbers

done:
	call	UnlockDataBlock
	.leave
	ret


noDuplicates:
	clr	ax
	call	ReAllocDataBlock
	jmp	done

ChartGroupDuplicateNumbers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReAllocDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the data block, fixing up ES to point
		to the data-block segment

CALLED BY:

PASS:		bx - handle of data block
		es - segment of data block
		ax - amount of size to ADD to original size (original
		size as defined by es:CD_endOfData.  Passing 0 in AX
		returns the block to its original size.

RETURN:		es - fixed up, if necesssary

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReAllocDataBlock	proc near	
	uses	bp
	.enter

	; Mark the block as dirty
	mov	bp, bx
	call	VMDirty

	; re-allocate the damn thing!

	add	ax, es:[CD_endOfData]
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	es, ax
	.leave
	ret
ReAllocDataBlock	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNumbersToDuplicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy all the values to a "duplicate" area, where I can
		muck with them as I please.

CALLED BY:

PASS:		ds:di - ChartGroup object
		al - ChartDataAttributes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNumbersToDuplicates	proc near	
	uses	bx,cx,dx,si,di

seriesCount	local	byte
categoryCount	local	word
	.enter

	call	ChartGroupGetCategoryCount
	mov	categoryCount, cx
	call	ChartGroupGetSeriesCount
	mov	seriesCount, cl

	clr	cx, dx

	; Copy all the numbers to the area after CD_endOfData.  BX is
	; used as the current destination pointer.

	; (cx,dx) = current series, category entry.

	mov	bx, es:[CD_endOfData]

startLoop:
	push	ax,cx,ds,di	

	call	GetSeriesCategoryEntry	;  es:di <= next number

	; If entry isn't a number, then stick a zero in the dup table.
	; 
	cmp	al, CDCT_NUMBER
	je	gotNumber

	segmov	ds, cs, si
	mov	si, offset float0
	jmp	copyIt


gotNumber:
	; Set up pointers so that ds:si points to source, es:di points
	; to destination

	segmov	ds, es, si
	mov	si, di

copyIt:
	mov	di, bx				; current dest address
	
	MovMem	<size FloatNum>
	mov	bx, di				; updated dest address

	pop	ax,cx,ds,di


	; Now, update counters.

	inc	dx
	cmp	dx, categoryCount
	jl	startLoop
	clr	dx
	inc	cl
	cmp	cl, seriesCount
	jl	startLoop

	.leave
	ret
CopyNumbersToDuplicates	endp


float0 FloatNum	<0,0,0,0,<0,0>>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetSeriesCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of series.

CALLED BY:	via MSG_CHART_GROUP_GET_SERIES_COUNT
PASS:		ds:di - ChartGroup instance data

RETURN:		cl	= # of series

DESTROYED:	es

PSEUDO CODE/STRATEGY:
	Lock data block
	
	nSeries = nRows

	if (rowsAreSeries == 0)
	    nSeries = nColumns

	if (hasCategoryTitles)
	    nSeries -= 1

	Unlock data block
	
	return nSeries

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetSeriesCount	method	ChartGroupClass,
			MSG_CHART_GROUP_GET_SERIES_COUNT
	uses	bx,di
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	tst	ds:[di].CGI_data
	jz	none

	call	LockDataBlock		; es <- block segment
					; bx <- block handle
	
	mov	cx, es:CD_nRows		; cx <- # of rows
	test	ds:[di].CGI_dataAttrs, mask CDA_ROWS_ARE_SERIES
	jnz	gotCount
	mov	cx, es:CD_nColumns	; cx <- # of columns
gotCount:

	test	ds:[di].CGI_dataAttrs, mask CDA_HAS_CATEGORY_TITLES
	jz	done
	dec	cx			; One space is occupied by these titles
done:
	call	UnlockDataBlock	; Release the block
	.leave
	ret

none:
	clr	cx
	.leave
	ret

ChartGroupGetSeriesCount	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetCategoryCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of categories.

CALLED BY:	via MSG_CHART_GROUP_GET_CATEGORY_COUNT

PASS:		ds:di - ChartGroup instance data

RETURN:		cx	= # of categories

DESTROYED:	es

PSEUDO CODE/STRATEGY:
	Lock data block
	
	nCategories = nRows
	if (rowsAreSeries)
	    nCategories = nColumns

	if (hasCategoryTitles)
		nCategories--

	Unlock data block
	
	return nCategories

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetCategoryCount	method ChartGroupClass,
				MSG_CHART_GROUP_GET_CATEGORY_COUNT
	uses	bx, di
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

	tst	ds:[di].CGI_data
	jz	none

	call	LockDataBlock	; es <- block segment
					; bx <- block handle
	
	mov	cx, es:CD_nColumns
	test	ds:[di].CGI_dataAttrs, mask CDA_ROWS_ARE_SERIES
	jnz	gotCount
	mov	cx, es:CD_nRows

gotCount:
	test	ds:[di].CGI_dataAttrs, mask CDA_HAS_SERIES_TITLES
	jz	done
	dec	cx			; One space is occupied by these titles
done:
	call	UnlockDataBlock	; Release the block
	.leave
	ret

none:
	clr	cx
	.leave
	ret
ChartGroupGetCategoryCount	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a number from the data block.

CALLED BY:	both a method and a procedure

PASS:		ds:di - ChartGroup instance data
		cl	= Series number
		dx	= Category number

RETURN:		IF NUMBER AVAILABLE:
			carry clear, number on FP stack
		ELSE
			carry set

DESTROYED:	es

PSEUDO CODE/STRATEGY:
	Lock data block

	if (hasCategoryTitles)
	    series += 1
	if (hasSeriesTitles)
	    category += 1

	ptr = GetParamEntryPtr(series, category)
	if (ptr->type != NUMBER) {
	    SET CARRY
	} else {
	    push ptr->data
	}
	Unlock data block
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOT DYNAMIC -- so save all regs!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetValue	method ChartGroupClass, MSG_CHART_GROUP_GET_VALUE
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECCheckChartGroupDSDI		>

	clr	ch
	call	LockDataBlock		; es <- block segment

	mov	al, ds:[di].CGI_dataAttrs
	call	GetSeriesCategoryEntry

	cmp	al, CDCT_NUMBER
	jne	error

	push	ds, si
	segmov	ds, es, si			; ds:si <- ptr to number
	mov	si, di
	call	FloatPushNumber			; Push the number
	pop	ds, si
ifdef SPIDER_CHART
doneCLC:
endif
	clc
done:
	call	UnlockDataBlock		; Release the block
	.leave
	ret

error:
ifdef SPIDER_CHART
	;
	; spider chart doesn't deal well with non-number cells, so
	; substitute a 0
	;
	DerefChartObject ds, si, di
	cmp	ds:[di].CGI_type, CT_SPIDER
	jne	notEmpty
	call	Float0
	jmp	short doneCLC
notEmpty:
endif
	stc	
	jmp	done

ChartGroupGetValue	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetSeriesTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the title of a given series.

CALLED BY:	via MSG_CHART_GROUP_GET_SERIES_TITLE
PASS:		*ds:si	= ChartGroup object
		cl	= series #
		dx:bp	= Buffer large enough to hold the text.
			  CHART_PARAMETER_MAX_TEXT_LENGTH is the largest that
			  a label will be (includes the NULL).

RETURN:		Buffer filled with the piece of text

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	if (hasSeriesTitles == 0) {
	    return fake series title string
	} else {
	    if (hasCategoryTitles) {
	        series# += 1
	    }
	    ptr = GetDataEntry(flags, series#, 0)
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetSeriesTitle	method 	ChartGroupClass,
				MSG_CHART_GROUP_GET_SERIES_TITLE

	uses	ax,bx,cx,dx,si,di,ds,es

	.enter

	mov	al, ds:[di].CGI_dataAttrs		; al <- flags
	
	test	al, mask CDA_HAS_SERIES_TITLES	; Check for having series
	jz	makeSeriesTitle			; Branch if there are none
	
	test	al, mask CDA_HAS_CATEGORY_TITLES
	jz	gotSeries
	inc	cl				; Account for titles

gotSeries:
	mov	es, dx				; es:bp - buffer
	clr	dx				; Category number
	call	ChartGroupFormatDataEntry		; Format the result

done:
	.leave
	ret


makeSeriesTitle:
	;
	; Create a series title and stuff it into the buffer at dx:si
	;
	clr	ch
	push	cx				;  series #
	mov	es, dx				; es:di <- destination
	mov	di, bp
	
	mov	ax, offset StringSeriesName	; ax <- chunk handle
	call	UtilCopyStringResource		; Copy it to the destination
						; cx <- # of bytes (w/o null)
	;
	; Format the number into the buffer
	;
	add	di, cx				; Move to after the string
	pop	ax				; series #
	inc	ax				; 1-based
	clr	dx				; dx:ax <- dword to convert
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii		; Format the number
	jmp	done
ChartGroupGetSeriesTitle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupFormatDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a data entry

CALLED BY:	ChartGroupGetSeriesTitle, ChartGroupGetCategoryTitle

PASS:		cl	= Series number (adjusted for titles)
		dx	= Category number (adjusted for titles)
		*ds:si	= chart group
		es:bp	- buffer to fill

RETURN:		Buffer filled
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupFormatDataEntry	proc	far
	uses	ax, bx, cx, di, si, ds, es

	class	ChartGroupClass

	.enter

	push	es, bp				; es:bp - dest
	call	LockDataBlock			; es - data block

	DerefChartObject ds, si, di
	mov	al, ds:[di].CGI_dataAttrs

	call	GetDataEntry			; es:di <- entry data
						; al <- entry type
	segmov	ds, es
	mov	si, di				; ds:si - source data

	pop	es, di				; es:di - dest
	
	cmp	al, CDCT_NUMBER			; Check for number
	je	copyNumber			; Branch if it is a number
	
	cmp	al, CDCT_TEXT			; Check for text
	je	copyText			; Branch if it is text

	cmp	al, CDCT_EMPTY			; Check for empty
	je	copyEmpty			; Branch if it is empty

done:

	call	UnlockDataBlock

	.leave
	ret

copyNumber:
	;
	; Format the number
	;
	push	bx
	mov	ax, mask FFAF_FROM_ADDR or \
		    mask FFAF_NO_TRAIL_ZEROS or \
		    mask FFAF_USE_COMMAS
	mov	bh, DECIMAL_PRECISION
	mov	bl, DECIMAL_PRECISION
	call	FloatFloatToAscii_StdFormat
	pop	bx
	jmp	done


copyText:
	;
	; Copy the text -- only copying in the first 255 chars
	;
	mov	cx, MAX_CHART_TEXT_LENGTH
10$:
	LocalGetChar	ax, dssi		; al <- next byte
	LocalPutChar	esdi, ax		; Save next byte
	LocalIsNull	ax			; Check for null
	loopnz	10$				; Loop if not
SBCS<	clr	al						>
DBCS<	clr	ax						>
	LocalPutChar	esdi, ax		; force terminate.
	jmp	done


copyEmpty:
	;
	; Just return a NULL
	;
SBCS<	mov	{char} es:[di], C_NULL				>
DBCS<	mov	{wchar} es:[di], C_NULL				>
	jmp	done
ChartGroupFormatDataEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetCategoryTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the title of a given series.

CALLED BY:	via MSG_CHART_GROUP_GET_CATEGORY_TITLE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Category title #
		dx:bp	= Buffer large enough to hold the text.
			  CHART_PARAMETER_MAX_TEXT_LENGTH is the largest that
			  a label will be (includes the NULL).


RETURN:		Buffer filled with text

DESTROYED:	es
		

PSEUDO CODE/STRATEGY:
	if (hasCategoryTitles == 0) {
	    return fake category title string
	} else {
	    if (hasSeriesTitles) {
	        category# += 1
	    }
	    ptr = GetDataEntry(flags, 0, category#)
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetCategoryTitle	method ChartGroupClass,
				MSG_CHART_GROUP_GET_CATEGORY_TITLE

	uses	ax,bx,cx,dx,ds,si
	.enter

	mov	es, dx				; es:bp <- dest buffer

	mov	al, ds:[di].CGI_dataAttrs		; al <- flags
	test	al, mask CDA_HAS_CATEGORY_TITLES
	jz	nullString

	test	al, mask CDA_HAS_SERIES_TITLES
	jz	gotCategory
	inc	cx				; Account for titles
gotCategory:
	
	mov	dx, cx				; dx <- category number
	clr	cx				; Series number
	call	ChartGroupFormatDataEntry	; Format the result

done:
	.leave
	ret

nullString:
SBCS<	mov	{char} es:[bp], C_NULL				>
DBCS<	mov	{wchar} es:[bp], C_NULL				>
	jmp	done

ChartGroupGetCategoryTitle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetSeriesMaxMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum and minimum values over a range of series

CALLED BY:	

PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cl - first series
		ch - last series (or MAX_SERIES_COUNT for final series.

RETURN:		Max and Min pushed on the floating point stack.
		Max is pushed first then min.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

	GetValue(firstSeries, 0)
	Foreach series in list:
		Foreach Category:
		   GetValue(series, category)
		   FloatMax

	GetValue(firstSeries,0)
	Foreach series in list:
		Foreach category:
		   GetValue(series, category)
		   FloatMin


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetSeriesMaxMin	method dynamic	ChartGroupClass,
				MSG_CHART_GROUP_GET_SERIES_MAX_MIN
	uses	dx,bp
	.enter

	clr	dx
	mov	bp, MAX_CATEGORY_COUNT
	call	ChartGroupGetRangeMaxMin
	.leave
	ret
ChartGroupGetSeriesMaxMin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetRangeMaxMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the MAX and MIN values in a given range of
		series/categories

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.
		cl 	= first series
		ch	= last series
		dx	= first category
		bp 	= last category

RETURN:		IF VALUES AVAILABLE:
			carry clear
			Max, Min on FP stack (max pushed first)

		ELSE:
			carry set
			fp stack clear

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

	called as both a PROCEDURE and a METHOD

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGetRangeMaxMin	method	ChartGroupClass, 
					MSG_CHART_GROUP_GET_RANGE_MAX_MIN
	uses	ax,cx,dx

passedBP	local	word	push	bp
locals		local	DataEnumVars
	.enter	

	mov	locals.DEV_firstSeries, cl
	mov	locals.DEV_lastSeries, ch
	mov	locals.DEV_firstCategory, dx
	mov	ax, passedBP
	mov	locals.DEV_lastCategory, ax

	; Get the first number in the range.  It's possible that the
	; range is empty! in which case, return empty-handled

	mov	locals.DEV_callback, offset GetFirstNumber
	call	DataBlockEnum
	jnc	notFound

	; duplicate the first number

	call	FloatDup			; FP: first first


	mov	locals.DEV_callback, offset ComputeMax

	call	DataBlockEnum
	call	FloatSwap			; FP: Max first
	
	;
	; Now, get MIN
	;
	mov	locals.DEV_callback, offset ComputeMin
	call	DataBlockEnum			; FP: Max Min
	clc
done:
	.leave
	ret

notFound:
	stc
	jmp	done

ChartGroupGetRangeMaxMin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFirstNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first value in the data block

CALLED BY:	DataBlockEnum

PASS:		*ds:si - ChartGroup
		cl - series #
		dx - category #		

RETURN:		carry set as soon as we have a number -- this will
			stop the  search
		number is on FP stack

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFirstNumber	proc near
	.enter
	call	ChartGroupGetValue
	cmc				
	.leave
	ret
GetFirstNumber	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForeachCategoryInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the routine specified in BP for each category

CALLED BY:	
PASS:		bx	= Callback to call
		ax, cx	= arguments to callback
		dx	= first category
		bp	= last category
		*ds:si	= ChartGroup instance

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForeachCategoryInRange	proc	near
	uses	dx
	.enter

EC <	call	ECCheckChartGroupDSDI		> 

callLoop:
	;
	; dx	= Current category
	; bp 	= last category
	; bx	= routine to call
	; ds:di = ChartGroup
	; ax,cx = arguments
	;
	; See if done yet
	cmp	dx, bp			
	ja	doneNoAbort
	
	call	bx				; Call callback
	jc	done				; Branch on "abort" signal
	
	inc	dx				; Move to next category
	jmp	callLoop

done:
	;
	; Carry set on abort signal
	;
	.leave
	ret

doneNoAbort:
	clc					; Signal: no abort
	jmp	done				; Branch to done

ForeachCategoryInRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next entry and compare against current minimum

CALLED BY:	ChartGroupGetSeriesMaxMin via ForeachCategory
PASS:		cl	= Series number
		dx	= Category number
		ds:di	= ChartGroup instance ptr
		Floating point stack contains current minimum
RETURN:		Floating point stack contains new minimum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMin	proc	near
	uses	ax
	.enter
	call	ChartGroupGetValue
	jc	done
	call	FloatMin
done:
	clc
	.leave
	ret
ComputeMin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next entry and compare against current maximum

CALLED BY:	ChartGroupGetRange via ForeachCategory

PASS:		cx	= Series number
		dx	= Category number
		ds:di 	= ChartGroup instance data
		Floating point stack contains current maximum

RETURN:		Floating point stack contains new maximum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMax	proc	near
	uses	ax
	.enter
	call	ChartGroupGetValue
	jc	done

	call	FloatMax
done:
	clc					; Signal: continue
	.leave
	ret
ComputeMax	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceSeriesLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the passed series value to be legal

CALLED BY:

PASS:		cl - series number (possibly too high)

RETURN:		cl - valid series number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceSeriesLegal	proc near	
	uses	ax	
	.enter
	mov	al, cl				; passed value
	call	ChartGroupGetSeriesCount	; cl <= # of series
	dec	cl
	cmp	cl, al
	jbe	gotSeries
	mov	cl, al	
gotSeries:
	.leave
	ret
ForceSeriesLegal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceCategoryLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the passed series value to be legal

CALLED BY:

PASS:		dx - category number

RETURN:		dx - legal category number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceCategoryLegal	proc near	
	uses	cx	
	.enter
	call	ChartGroupGetCategoryCount
	dec	cx
	cmp	dx, cx
	jbe	gotCategory
	mov	dx, cx
gotCategory:
	.leave
	ret
ForceCategoryLegal	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataBlockEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate over a range of cells in the chart's data
		block. 

CALLED BY:	UTILITY

PASS:		ss:bp - DataEnumVars (growing downwards from bp)

RETURN:		CARRY SET - if enumeration was stopped by callback
		routine. 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataBlockEnum	proc near	
	uses	cx,dx
locals	local	DataEnumVars
	.enter	inherit

	; Fixup values

	mov	cl, locals.DEV_lastSeries
	call	ForceSeriesLegal
	mov	locals.DEV_lastSeries, cl

	mov	dx, locals.DEV_lastCategory
	call	ForceCategoryLegal
	mov	locals.DEV_lastCategory, dx
	
	mov	cl, locals.DEV_firstSeries
EC <	call	ECCheckSeriesNumber	; check CL legal	>

	; Now, do the loop
seriesLoop:
	cmp	cl, locals.DEV_lastSeries
	jg	clearCarryDone

	mov	dx, locals.DEV_firstCategory
EC <	call	ECCheckCategoryNumber	; check DX legal	>

categoryLoop:	
	cmp	dx, locals.DEV_lastCategory
	jg	nextSeries
	push	cx, dx, bp
	call	locals.DEV_callback
	pop	cx, dx, bp
	jc	done			; callback set the carry
	inc	dx
	jmp	categoryLoop
nextSeries:
	inc	cl
	jmp	seriesLoop

clearCarryDone:
	clc
done:

	.leave
	ret
DataBlockEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetDataAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartGroupClass object
		ds:di	- ChartGroupClass instance data
		es	- segment of ChartGroupClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupGetDataAttributes	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_GET_DATA_ATTRIBUTES
	mov	al, ds:[di].CGI_dataAttrs
	ret
ChartGroupGetDataAttributes	endm

