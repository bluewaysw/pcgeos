COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicBodySelectionList

AUTHOR:		Jon Witort, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------

METHOD HANDLERS
	Name				Description
	----				-----------
	GrObjBodyCreateSortableArray	Allocates a sortable array
	GrObjBodyDestroySortableArray	Frees a sortable array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	19 Nov 1991	Initial revision

DESCRIPTION:

	$Id: bodySortableArray.asm,v 1.1 97/04/04 18:07:59 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjObscureExtNonInteractiveCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyCreateSortableArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GRAPHIC_BODY_CREATE_SORTABLE_ARRAY
		Allocates a block for a sortable selected array, and changes
		the graphic body's instance data to point to it. The original
		array's descriptor is stored in the new array's header.

Pass:		*ds:si = graphic body

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateSortableArray	method	GrObjBodyClass, MSG_GB_CREATE_SORTABLE_ARRAY
	uses	ax,bx,cx,dx,di,es
	.enter

	push	ds, si				;save graphic body
	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	push	bx				;save selected array handle

	;    Allocate a chunk array to keep track of selected objects. We'll
	;    allocate enough so that we won't need to realloc.
	;
	;    size = (n elements) * (size element) + chunk array header size
	;		+ lmem block header size + fudge factor
	;

	call	ChunkArrayGetCount
	mov	ax, size SortableArrayElement
	mul	cx
	add	ax, size SortableArrayHeader + size LMemBlockHeader + 16
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8)
	call	MemAlloc
	push	bx				;save new mem handle
	push	ds, si				;save selected array chunk
	mov	ds, ax				;ax <- new block segment
	mov	cx, 4				;4 initial handles?
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	si, size SortableArrayHeader	;make room for header
	clr	di				;no lmem flags
	call	LMemInitHeap

	mov	al, mask OCF_IGNORE_DIRTY	;is this right?
	mov	bx, size SortableArrayElement	;element size
	mov	cx, size SortableArrayHeader
	clr	si
	call	ChunkArrayCreate

	;    Save a pointer to the original array in our new array
	;

	mov	di, ds:[si]
	segmov	es, ds
	pop	ds, ax				;*ds:ax <- selected array
	mov	bx, ds:[LMBH_handle]
	mov	es:[di].SAH_originalArray.chunk, ax
	mov	es:[di].SAH_originalArray.segment, bx

	;    Unlock the new array
	;

	pop	bx				;bx <- new array handle
	call	MemUnlock

	mov_tr	ax, bx				;ax <- new array handle

	;    Unlock the original array
	;

	pop	bx				;bx <- original array handle
	call	MemUnlock

	;   Point the GB's instance data to our new sortable array
	;

	mov	dx, si				;dx <- new array chunk
	pop	ds, si				;*ds:si <- graphic body
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset

	mov	ds:[di].GBI_selectionArray.handle, ax
	mov	ds:[di].GBI_selectionArray.chunk, dx

	.leave
	ret
GrObjBodyCreateSortableArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyDestroySortableArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GRAPHIC_BODY_DESTROY_SORTABLE_ARRAY
		Frees the block previously allocated for a sortable selected
		array, (in handler for MSG_GB_CREATE_SORTABLE_ARRAY) and
		changes the graphic body's instance data to point back to the
		original array.

Pass:		*ds:si = graphic body

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDestroySortableArray	method	GrObjBodyClass, MSG_GB_DESTROY_SORTABLE_ARRAY
	uses	ax,bx,di,si,es
	.enter

	;    Lock the sortable array
	;
	push	ds, si				;save graphic body ptr
	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>

	;   Copy the original array into the graphic body's instance data
	;

	segmov	es, ds
	mov	di, ds:[si]			;es:di <- sortable array

	pop	ds, si				;*ds:si <- graphic body
	mov	si, ds:[si]
	add	si, ds:[si].GrObjBody_offset	;ds:si <- graphic body

	mov	ax, es:[di].SAH_originalArray.handle
	mov	ds:[si].GBI_selectionArray.handle, ax
	mov	ax, es:[di].SAH_originalArray.chunk
	mov	ds:[si].GBI_selectionArray.chunk, ax

	;    Free the sortable array
	;

	call	MemFree
	.leave
	ret
GrObjBodyDestroySortableArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyFillSortableArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
		Fills the Sortable array from the original array contained in
		its header. The sortable array element is the OD from the
		original element, plus a DWFixed key from the object specified
		by the OD. The caller passes an offset into RectDWFixed to
		specify which parameter from the object's bounds is to be
		the key.

Pass:		*ds:si = graphic body
		dx = offset into RectDWFixed (e.g., if the array is to be
			sorted by vertical position, dx = offset RDWF_top)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFillSortableArrayUsingODWFBounds	method	GrObjBodyClass, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_DWF_BOUNDS
	uses	cx
	.enter
	mov	cx, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	GrObjBodyFillSortableArrayCommon
	.leave
	ret
GrObjBodyFillSortableArrayUsingODWFBounds	endm

GrObjBodyFillSortableArrayUsingOCenters	method	GrObjBodyClass, MSG_GB_FILL_SORTABLE_ARRAY_USING_GO_CENTERS
	uses	cx
	.enter
	mov	cx, MSG_GO_GET_CENTER
	call	GrObjBodyFillSortableArrayCommon
	.leave
	ret
GrObjBodyFillSortableArrayUsingOCenters	endm

GrObjBodyFillSortableArrayCommon	proc	near	

	uses	ax,bx,cx,dx,di,si,es,ds

	;    This is the RectDWFixed that the object's wil use to return
	;    their bounds
	;

utilRect	local	RectDWFixed

	.enter

	;    Lock the sortable array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	push	bx				;save sortable handle

	segmov	es, ds, ax			;es <- sortable segment
	mov	di, si				;*es:si <- sortable array

	;    Lock the original array
	;

	mov	si, ds:[si]
	mov	bx, ds:[si].SAH_originalArray.handle
	mov	si, ds:[si].SAH_originalArray.chunk
	call	MemLock
	mov	ds, ax				;ds <- original array segment

	mov_tr	ax, di				;*es:ax <- sortable array
	push	bx				;save original array handle
	;    Enumerate the objects in the original array, telling each to
	;    add themselves to the sortable array
	;

	mov	bx, cs
	mov	di, offset FillArrayCB
	push	bp				;save local ptr
	lea	bp, ss:utilRect
	call	ChunkArrayEnum
	pop	bp				;bp <- local ptr

	;    Unlock the original array
	;

	pop	bx				;bx <- original array handle
	call	MemUnlock

	;    Unlock the sortable array
	;
	pop	bx
	call	MemUnlock
	.leave
	ret
GrObjBodyFillSortableArrayCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FillArrayCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Copy the OD of the OD array element into a new sortable array
		element, along with one of the object's DWF bounds.

Pass:		ds:di = OD array element
		*ds:si = OD chunk array
		*es:ax = sortable array
		ss:bp = RectDWFixed or PointDWFixed
		dx = offset into RectDWFixed to the PointDWFixed to copy into
			the sortable array
		cx = message to send to object

Return:		nothing

Destroyed:	bx, si, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillArrayCB	proc	far
	uses	ax, ds
	.enter

	push	ax				;save sortable array chunk

	;    Get the object's bounds
	;

	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, cx				;ax <- message
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES or mask MF_CALL
	call	ObjMessage

	;     Append a new entry to the sortable array
	;

	segmov	ds, es, ax			;ds <- sortable array segment
	pop	ax				;*ds:ax <- sortable array
	xchg	ax, si				;*ds:si <- sortable array,
						;ax <- object chunk
	call	ChunkArrayAppend

	;    Store the OD in the new element
	;

	mov	ds:[di].SAE_OD.handle, bx
	mov	ds:[di].SAE_OD.chunk, ax

	
	;    Store the DWFixed key from the object's bounds
	;

	add	bp, dx				;ss:bp <- DWF of interest
	MovDWF	ds:[di].SAE_key, ss:[bp], ax
	sub	bp, dx				;ss:bp <- RectDWFixed
	.leave
	ret
FillArrayCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodySortSortableArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_SORT_SORTABLE_ARRAY
		Sort the sortable array based on each element's key.

Pass:		*ds:si = graphic body instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySortSortableArray	method	GrObjBodyClass, MSG_GB_SORT_SORTABLE_ARRAY
	uses	cx, dx, ds, si
	.enter

	;    Lock the sortable array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>

	;    Sort the array
	;

	mov	cx, SEGMENT_CS
	mov	dx, offset SortableArrayElementCompare
	call	ChunkArraySort

	;    Unlock the array
	;

	call	MemUnlock
	.leave
	ret
GrObjBodySortSortableArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SortableArrayElementCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Compares two SortableArrayElements, setting the flags as though
		a signed comparison were made between their keys.

Pass:		ds:si = first SortableArrayElement
		es:di = second SortableArrayElement

Return:		flags set so that jl, je, jg would "do the right thing"
		if SAE #1 were less than, equal to, or greater than SAE #2,
		respectively

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortableArrayElementCompare	proc	far
	uses	ax
	.enter

	;    compare the singed int.high's. If they're not equal,
	;    then the flags are set properly, and we can exit.
	;

	mov	ax, ds:[si].SAE_key.DWF_int.high	;ax <- int.high
	cmp	ax, es:[di].SAE_key.DWF_int.high	
	jne	done			


	;    compare the unsigned int.low's. If they're equal, then
	;    we check the fractional parts. If they aren't equal, we
	;    have to effect an unsigned comparison before returning.
	;

	mov	ax, ds:[si].SAE_key.DWF_int.low
	cmp	ax, es:[di].SAE_key.DWF_int.low
	ja	greaterThan
	je	checkFrac

	;    the first element is "less than" the second, so set the
	;    flags to mimic a less-than signed comparison
	;

lessThan:
	mov	al, -1
	cmp	al, 0
done:
	.leave
	ret

	;    Check the unsigned fractional portions of the DWFixed's. If
	;    they're equal, return. If not, check the sign of the number's
	;    to see which side of the origin we're on, which determine's
	;    whether a bigger fraction means a bigger or small (bigger
	;    negative) number.
	;

checkFrac:
	mov	ax, ds:[si].SAE_key.DWF_frac
	cmp	ax, es:[di].SAE_key.DWF_frac
	je	done
	jb	lessThan

greaterThan:
	mov	al, 1
	cmp	al, 0
	jmp	done
SortableArrayElementCompare	endp
	

GrObjObscureExtNonInteractiveCode	ends
