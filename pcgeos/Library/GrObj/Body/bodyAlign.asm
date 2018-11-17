COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicBodyAlign.asm

AUTHOR:		Jon Witort, Nov 6, 1991

ROUTINES:
	Name			Description
	----			-----------

METHOD HANDLERS
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6 Nov 1991	Initial revision


DESCRIPTION:

	$Id: bodyAlign.asm,v 1.1 97/04/04 18:07:51 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjObscureExtNonInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyAlignSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_ALIGN_SELECTED_GROBJS

Called by:	UI

Pass:		*ds:si = GrObjBody
		cl = AlignType

Return:		nothing

Destroyed:	nothing

Comments:	This routine needs common code analysis.

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  6, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GBASOFlags	record
	:6
	GBASOF_CALCULATED_SUMMED_DIMENSIONS : 1
	GBASOF_CREATED_SORTABLE_ARRAY : 1
GBASOFlags	end

GrObjBodyAlignSelectedGrObjs	method	dynamic	GrObjBodyClass, \
						MSG_GB_ALIGN_SELECTED_GROBJS

	uses	ax, cx

selectedBounds		local	RectDWFixed		;bounding rect of all
							;selected objects
alignParams		local	AlignParams
localFlags		local	GBASOFlags
objectBounds		local	RectDWFixed
objectCenter		local	PointDWFixed
summedDimensions	local	PointDWFixed
numSelectedGrObjs	local	word
	.enter

	;    see if there's any alignment to be done...
	;

	mov	ss:alignParams.AP_type, cl
	test	cl, mask AT_DISTRIBUTE_X or mask AT_DISTRIBUTE_Y
	jz	checkAlignFlags

	mov_tr	ax, cx
	push	ds, si
	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	call	ChunkArrayGetCount
	call	MemUnlock
	pop	ds, si
	jcxz	done					;if none selected, bail
	xchg	ax, cx					;ax <- # selected
							;cl <- AlignType
	mov	ss:numSelectedGrObjs, ax
	jmp	continue

done:
	.leave
	ret

checkAlignFlags:
	test	ss:[alignParams].AP_type, mask AT_ALIGN_X or mask AT_ALIGN_Y
	jz	done

continue:
	clr	ss:localFlags

	;    get the bounding rectangle of the selected children
	;

	push	bp
	lea	bp, ss:selectedBounds
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	pop	bp

	;    see if we're aligning horizontally
	;

	test	ss:[alignParams].AP_type, mask AT_ALIGN_X or mask AT_DISTRIBUTE_X
	LONG	jz	checkY

	;    do we want center horizontal alignment?
	;
	
	mov	al, ss:[alignParams].AP_type
	and	al, mask AT_CLRW
	LONG	jnz	checkRight

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_X
	jnz	centerDistribute

	;    Calculate the horizontal center of the bounds
	;
	movdwf	dxbxax, selectedBounds.RDWF_right
	adddwf	dxbxax, selectedBounds.RDWF_left

	;    dx:bx:ax <- center = (right + left) / 2
	;

	sardwf	dxbxax

	;    alignPoint <- center
	;

	movdwf	alignParams.AP_x, dxbxax
	jmp	checkY

centerDistribute:
	movnf	dx, <offset PDF_x>
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	call	CreateAndSortArrayCommon

	push	bp
	lea	bp, ss:objectCenter
	mov	dx, size PointDWFixed
	mov	ax, MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	ss:alignParams.AP_x, ss:objectCenter.PDF_x, ax

	;   Get second object's center
	;

	push	bp
	lea	bp, ss:objectCenter
	mov	ax, MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	dxcxax, ss:objectCenter.PDF_x
	subdwf	dxcxax, ss:alignParams.AP_x

	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	ss:alignParams.AP_spacingX, dxcxax
	jmp	checkY

checkRight:
	;    or maybe right alignment?
	;

	cmp	al, CLRW_RIGHT shl offset AT_CLRW
	jne	checkLeft

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_X
	jnz	distributeRight

	;    we want right alignment, so load the right bound
	;

	movdwf	alignParams.AP_x, selectedBounds.RDWF_right, dx

	jmp	checkY

distributeRight:
	;    Create a sortable array so that we can sort the selected
	;    objects by their left bounds.
	;

	mov	dx, offset RDWF_right
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
	call	CreateAndSortArrayCommon

	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	dxcxax, ss:[objectBounds].RDWF_right
	movdwf	ss:[alignParams.AP_x], dxcxax

	subdwf	dxcxax, ss:[selectedBounds].RDWF_right
	negdwf	dxcxax
	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	ss:alignParams.AP_spacingX, dxcxax
	jmp	checkY	

checkLeft:

	cmp	al, CLRW_LEFT shl offset AT_CLRW
	je	leftX

	;    We are aligning or distributing by width
	;

	movnf	dx, <offset PDF_x>
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	call	CreateAndSortArrayCommon

	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	alignParams.AP_x, ss:objectBounds.RDWF_left, dx

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_X
	LONG	jz	checkY
	
	;    We're distributing by width, so we need to calculate the total
	;    width, do some fancy math, and get the distribution spacing
	;

	push	bp
	lea	bp, ss:summedDimensions
	mov	dx, size PointDWFixed
	mov	ax, MSG_GB_GET_SUMMED_DWF_DIMENSIONS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	pop	bp

	BitSet	ss:localFlags, GBASOF_CALCULATED_SUMMED_DIMENSIONS

	;
	;	what 32 bit constraints on bounds??? steve???
	;	
	movdwf	dxcxax, ss:selectedBounds.RDWF_right
	subdwf	dxcxax, ss:selectedBounds.RDWF_left
	subdwf	dxcxax, ss:summedDimensions.PDF_x

	;    dx:cx.ax = bounding width - summed widths
	;

	mov	bx, ss:numSelectedGrObjs
	push	bp
	mov_tr	bp, ax
	clr	ax
	dec	bx
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	alignParams.AP_spacingX, dxcxax
	jmp	checkY

leftX:
	;    we want left alignment, so load the left bound into
	;    alignPoint.PDF_x
	;

	movdwf	alignParams.AP_x, selectedBounds.RDWF_left, dx

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_X
	jz	checkY

	movnf	dx, <offset RDWF_left>
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
	call	CreateAndSortArrayCommon

	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	
	movdwf	dxcxax, ss:objectBounds.RDWF_left
	subdwf	dxcxax, ss:selectedBounds.RDWF_left
	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	ss:alignParams.AP_spacingX, dxcxax

checkY:

	test	ss:[alignParams].AP_type, mask AT_ALIGN_Y or mask AT_DISTRIBUTE_Y
	LONG	jz	doAlign

	;    do we want center vertical alignment?
	;
	
	mov	al, ss:[alignParams].AP_type
	and	al, mask AT_CTBH
	LONG	jnz	checkBottom

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_Y
	jnz	centerDistributeY

	;    Calculate the horizontal center of the bounds
	;
	movdwf	dxbxax, selectedBounds.RDWF_bottom
	adddwf	dxbxax, selectedBounds.RDWF_top

	;    dx:bx:ax <- center = (right + left) / 2
	;

	sardwf	dxbxax

	;    alignPoint <- center
	;

	movdwf	alignParams.AP_y, dxbxax
	jmp	doAlign

centerDistributeY:
	mov	dx, offset PDF_y
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	test	ss:localFlags, mask GBASOF_CREATED_SORTABLE_ARRAY
	jz	createCenter

	call	NeedDoubleSort
	jmp	afterCreateCenter

createCenter:
	call	CreateAndSortArrayCommon

afterCreateCenter:
	push	bp
	lea	bp, ss:objectCenter
	mov	dx, size PointDWFixed
	mov	ax, MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	ss:alignParams.AP_y, ss:objectCenter.PDF_y,ax

	;   Get second object's center
	;

	push	bp
	lea	bp, ss:objectCenter
	mov	ax, MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; dx:cx.ax <- distance between left and right objects' center
	;
	movdwf	dxcxax, ss:objectCenter.PDF_y
	subdwf	dxcxax, ss:alignParams.AP_y

	;
	;    store the amount to distribute by
	;
	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	ss:alignParams.AP_spacingY, dxcxax
	jmp	doAlign

checkBottom:
	cmp	al, CTBH_BOTTOM shl offset AT_CTBH
	LONG	jne	checkTop

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_Y
	jnz	distributeBottom

	;    we want bottom alignment, so load the bottom bound
	;

	movdwf	alignParams.AP_y, selectedBounds.RDWF_bottom,dx
	jmp	doAlign

distributeBottom:

	mov	dx, offset RDWF_bottom
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS

	test	ss:localFlags, mask GBASOF_CREATED_SORTABLE_ARRAY
	jz	createBottom

	call	NeedDoubleSort
	jmp	afterCreateBottom

	;    Create a sortable array so that we can sort the selected
	;    objects by their left bounds.
	;

createBottom:

	call	CreateAndSortArrayCommon

afterCreateBottom:
	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	dxcxax, ss:[objectBounds].RDWF_bottom
	movdwf	alignParams.AP_y, dxcxax

	subdwf	dxcxax, ss:[selectedBounds].RDWF_bottom
	negdwf	dxcxax
	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp

	movdwf	ss:alignParams.AP_spacingY, dxcxax
	jmp	doAlign

checkTop:
	cmp	al, CTBH_TOP shl offset AT_CTBH
	LONG	je	top

	;    We are aligning or distributing by height
	;

	mov	dx, offset PDF_y
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	test	ss:localFlags, mask GBASOF_CREATED_SORTABLE_ARRAY
	jz	createHeight

	call	NeedDoubleSort
	jmp	afterCreateHeight

createHeight:
	call	CreateAndSortArrayCommon

	;   indicate that we've created a sortable array
	;

afterCreateHeight:
	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	alignParams.AP_y, ss:objectBounds.RDWF_top, dx

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_Y
	LONG	jz	doAlign
	
	;    We're distributing by width, so we need to calculate the total
	;    width, do some fancy math, and get the distribution spacing
	;

	test	ss:localFlags, mask GBASOF_CALCULATED_SUMMED_DIMENSIONS
	jnz	gotDims

	push	bp
	lea	bp, ss:summedDimensions
	mov	dx, size PointDWFixed
	mov	ax, MSG_GB_GET_SUMMED_DWF_DIMENSIONS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	pop	bp

gotDims:
	movdwf	dxcxax, ss:selectedBounds.RDWF_bottom
	subdwf	dxcxax, ss:selectedBounds.RDWF_top
	subdwf	dxcxax, ss:summedDimensions.PDF_y

	;    dx:cx.bp = bounding width - summed widths
	;

	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp
	
	movdwf	alignParams.AP_spacingY, dxcxax
	jmp	doAlign

top:
	;    we want left alignment, so load the left bound into
	;    alignPoint.PDF_x
	;

	movdwf	alignParams.AP_y, selectedBounds.RDWF_top, dx

	test	ss:[alignParams].AP_type, mask AT_DISTRIBUTE_Y
	jz	doAlign

	mov	dx, offset RDWF_top
	mov	bx, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS

	test	ss:localFlags, mask GBASOF_CREATED_SORTABLE_ARRAY
	jz	createTop

	call	NeedDoubleSort
	jmp	afterCreateTop

createTop:
	call	CreateAndSortArrayCommon

afterCreateTop:
	push	bp
	lea	bp, ss:objectBounds
	mov	dx, size RectDWFixed
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ
	call	ObjCallInstanceNoLock
	pop	bp

	movdwf	dxcxax, ss:objectBounds.RDWF_top
	subdwf	dxcxax, ss:selectedBounds.RDWF_top
	mov	bx, ss:numSelectedGrObjs
	dec	bx
	push	bp
	mov_tr	bp, ax
	clr	ax
	call	GrSDivDWFbyWWF
	mov_tr	ax, bp
	pop	bp
	movdwf	ss:alignParams.AP_spacingY, dxcxax

doAlign:

	;	Tell all the objects to align to alignPoint
	;

	call	GrObjGlobalStartUndoChainNoText
	mov	ax, MSG_GO_ALIGN
	push	bp					;save local ptr
	lea	bp, ss:alignParams
	mov	dx, size AlignParams
	call	GrObjBodySendToSelectedGrObjs
	pop	bp					;bp <- local ptr
	call	GrObjGlobalEndUndoChain

	;    See if we did an align by height or width, in which case
	;    we created a sortable array that we need to destroy
	;

	test	ss:localFlags, mask GBASOF_CREATED_SORTABLE_ARRAY
	LONG	jz	done

	mov	ax, MSG_GB_DESTROY_SORTABLE_ARRAY
	call	ObjCallInstanceNoLock
	jmp	done
GrObjBodyAlignSelectedGrObjs	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			NeedDoubleSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Called when the align/distribute needs to sort the selected
		objects in both dimensions. This routine takes the already
		sorted list, processes it, then re-sorts it.

Pass:		*ds:si = GrObjBody
		
		bx = message # to fill array:
	
			MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS

			in which case dx = offset PDF_x or offset PDF_y
			depending on whether they are to be sorted
			horizontally or vertically

			- or -

			MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS

			in which case dx = offset into RectDWFixed (e.g.,
			offset RDWF_right) to indicate which bound the
			selected objects should be sorted.

		dx - see above documentation for bx

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  2, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NeedDoubleSort	proc	far

	uses	ax, cx

	.enter inherit GrObjBodyAlignSelectedGrObjs

	mov	cl, ss:alignParams.AP_type
	push	cx					;preserve AlignType
	push	dx, bx					;save offset, message

	;    Process the children sorted in X dimension
	;

	andnf	cl, not (mask AT_ALIGN_Y or mask AT_DISTRIBUTE_Y)
	mov	ss:alignParams.AP_type, cl
	mov	ax, MSG_GO_ALIGN
	push	bp					;save local ptr
	lea	bp, ss:alignParams
	mov	dx, size AlignParams
	call	GrObjBodySendToSelectedGrObjs
	pop	bp					;bp <- local ptr

	;    Now zero out the array and re-fill it with the Y dimensions
	;

	push	ds, si					;save graphic body ptr
	call	GrObjBodySelectionArrayLock
	call	ChunkArrayZero
	pop	ds, si					;*ds:si <- GB
		
	pop	dx, ax					;dx <- struct offset
							;ax <- message #
	call	ObjCallInstanceNoLock

	;    Sort the array by Y dimensions
	;

	mov	ax, MSG_GB_SORT_SORTABLE_ARRAY
	call	ObjCallInstanceNoLock

	;    Restore the original AlignType and zero out the
	;    X stuff, then return.
	;

	pop	cx					;cl <- AlignType
	andnf	cl, not (mask AT_ALIGN_X or mask AT_DISTRIBUTE_X)
	mov	ss:alignParams.AP_type, cl

	.leave
	ret
NeedDoubleSort	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateAndSortArrayCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si = GrObjBody
		bx = message # to fill array:
	
			MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS

			in which case dx = offset PDF_x or offset PDF_y
			depending on whether they are to be sorted
			horizontally or vertically

			- or -

			MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS

			in which case dx = offset into RectDWFixed (e.g.,
			offset RDWF_right) to indicate which bound the
			selected objects should be sorted.

		dx - see above documentation for bx

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 27, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndSortArrayCommon	proc	near

	.enter inherit GrObjBodyAlignSelectedGrObjs

	;    Create a sortable array so that we can sort the selected
	;    objects by their left bounds.
	;

	mov	ax, MSG_GB_CREATE_SORTABLE_ARRAY
	call	ObjCallInstanceNoLock

	;    Fill the sortable array from the OD array
	;

	mov	ax, bx				;ax <- passed message #
	call	ObjCallInstanceNoLock

	;     Sort the objects according to their left bounds
	;

	mov	ax, MSG_GB_SORT_SORTABLE_ARRAY
	call	ObjCallInstanceNoLock

	;   indicate that we've created a sortable array
	;

	BitSet	ss:localFlags, GBASOF_CREATED_SORTABLE_ARRAY

	.leave
	ret
CreateAndSortArrayCommon	endp

GrObjObscureExtNonInteractiveCode	ends
