COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallCalc.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Calculation related code for a small text object.

	$Id: tlSmallCalc.asm,v 1.1 97/04/07 11:21:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate some set of lines in a small text object.

CALLED BY:	TL_LineCalculate via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to calculate
		dx	= LineFlags for line
		ss:bp	= LICL_vars with among other things:
				LICL_range.VTR_start = line start
				Paragraph attributes set
RETURN:		LICL_range.VTR_start = start of next line
		LICL_calcFlags updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineCalculate	proc	far
	uses	ax, cx, dx, di, es
	.enter
	mov	di, cx			; bx.di <- line
	mov	cx, dx			; cx <- LineFlags

EC <	call	ECCheckSmallLineReference				>

	push	cx			; Save flags for current line
	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	pop	ax			; ax <- flags for current line

	;
	; es:di	= Pointer to the line
	; cx	= Size of line/field data
	; ax	= LineFlags for this line
	; ss:bp	= LICL_vars almost ready to go
	;
	
	;
	; Set up the callback so we can get the right routine called when
	; adding fields.
	;
	movcb	ss:[bp].LICL_addFieldCallback, SmallLineAddField
	movcb	ss:[bp].LICL_truncateFieldsCallback, SmallLineTruncateFields
	movcb	ss:[bp].LICL_dirtyLineCallback, SmallLineDirty

	call	CommonLineCalculate
	.leave
	ret
SmallLineCalculate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a field to a line.

CALLED BY:	AddFieldToLine via LICL_addFieldCallback
PASS:		*ds:si	= Instance ptr
		es:di	= Pointer to the line
		es:dx	= Pointer to the field we want to have
		cx	= Pointer past line/field data
RETURN:		es:di	= Pointer to the line
		es:dx	= Pointer to the new field
		cx	= Pointer past line/field data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineAddField	proc	far
	uses	ax, si
	.enter
	;
	; When we resize the element things may move around on the heap.
	;
	sub	dx, di				; dx <- offset to field we want

	;
	; For ChunkArrayElementResize() we need:
	;	*ds:si	= Line array
	;	ax	= Element number
	;	cx	= New size
	;
	call	SmallGetLineArray		; *ds:ax <- array
	mov	si, ax				; *ds:si <- array

	;
	; *ds:si= Line array
	; ds:di	= Element
	;
	call	ChunkArrayPtrToElement		; ax <- element number
	
	mov	cx, dx				; cx <- size we want
	add	cx, size FieldInfo		; With space for another field
	call	ChunkArrayElementResize		; Resize the element
	
	;
	; Now we convert the element number (line number) back into a pointer
	; and fix-up es to be the same as ds.
	;
	call	ChunkArrayElementToPtr		; ds:di <- element
						; cx <- current size

	add	dx, di				; ds:dx <- ptr to field to use
	add	cx, di				; cx <- ptr past line/field data
	
	segmov	es, ds				; es <- segment containing lines
	.leave
	ret
SmallLineAddField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineTruncateFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate unused fields at the end of a line.

CALLED BY:	CommonLineCalculate via LICL_truncateFieldsCallback
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		dx	= Size we want the line to be
		cx	= Current size of the line
RETURN:		es:di	= Pointer to the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since we are never making the line larger we don't need to
	dereference the line again after truncating since our pointer
	will still be valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineTruncateFields	proc	far
	uses	ax, cx, si
	.enter
	;
	; For ChunkArrayElementResize() we need:
	;	*ds:si	= Line array
	;	ax	= Element number
	;	cx	= New size
	;
	call	SmallGetLineArray		; *ds:ax <- array
	mov	si, ax				; *ds:si <- array

	;
	; *ds:si= Line array
	; ds:di	= Element
	;
	call	ChunkArrayPtrToElement		; ax <- element number
	mov	cx, dx				; cx <- size we want
	call	ChunkArrayElementResize		; Resize the element
	.leave
	ret
SmallLineTruncateFields	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing...

CALLED BY:	CommonLineCalculate via LICL_dirtyLineCallback
PASS:		xxx
RETURN:		xxx
DESTROYED:	xxx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineDirty	proc	far
	ret
SmallLineDirty	endp


Text	ends
