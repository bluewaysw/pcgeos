COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeCalc.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Calculation related code for a large text object.

	$Id: tlLargeCalc.asm,v 1.1 97/04/07 11:21:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate some set of lines in a large text object.

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
LargeLineCalculate	proc	far
	uses	ax, cx, di, es
	.enter
	mov	di, cx			; bx.di <- line
	mov	cx, dx			; cx <- LineFlags

	mov	ax, cx			; cx <- flags for current line
	call	LargeGetLinePointer	; es:di	<- ptr to the line
					; cx <- size of line
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
	movcb	ss:[bp].LICL_addFieldCallback, LargeLineAddField
	movcb	ss:[bp].LICL_truncateFieldsCallback, LargeLineTruncateFields
	movcb	ss:[bp].LICL_dirtyLineCallback, LargeLineDirty

	call	CommonLineCalculate
	
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineCalculate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a field to a line.

CALLED BY:	AddFieldToLine via LICL_addFieldCallback
PASS:		*ds:si	= Instance ptr
		es:di	= Pointer to the line
		es:dx	= Pointer to the field we want to have
		cx	= Pointer past line/field data
		ss:bp	= LICL_vars
RETURN:		es:di	= Pointer to the line
		es:dx	= Pointer to the new field
		cx	= Pointer past line/field data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineAddField	proc	far
	uses	ax, bx
	.enter
	;
	; Unlock the huge-array block
	;
	call	LargeReleaseLineBlock		; Release the line

	;
	; When we resize the element things may move around on the heap.
	;
	sub	dx, di				; dx <- offset to field we want
	push	dx				; Save offset to field

	;
	; For HugeArrayElementResize() we need:
	;	di	= Line array
	;	dx.ax	= Element number
	;	cx	= New size
	;
	mov	cx, dx				; cx <- size we want
	add	cx, size FieldInfo		; With space for another field

	call	LargeGetLineArray		; di <- array

	movdw	dxax, ss:[bp].LICL_line		; dx.ax <- line to resize

	call	T_GetVMFile
	call	HugeArrayResize			; Resize the element
	
	movdw	bxdi, dxax			; bx.di <- line we want
	call	LargeGetLinePointer		; es:di	<- ptr to the line
						; cx <- size of line
	pop	dx				; dx <- offset to field
	
	
	add	cx, di				; cx <- ptr past line/field data
	add	dx, di				; es:dx <- ptr to new field
	.leave
	ret
LargeLineAddField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineTruncateFields
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

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineTruncateFields	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Unlock the huge-array block
	;
	call	LargeReleaseLineBlock		; Release the line

	;
	; For HugeArrayElementResize() we need:
	;	di	= Line array
	;	dx.ax	= Element number
	;	cx	= New size
	;
	mov	cx, dx				; cx <- size we want
	
	call	LargeGetLineArray		; di <- array
	
	movdw	dxax, ss:[bp].LICL_line		; dx.ax <- line
	
	call	T_GetVMFile
	call	HugeArrayResize			; Resize the element
	
	;
	; Re-lock the line
	;
	movdw	bxdi, dxax			; bx.di <- line we want
	call	LargeGetLinePointer		; es:di	<- ptr to the line
						; cx <- size of line/field data
	.leave
	ret
LargeLineTruncateFields	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark a large-line as dirty.

CALLED BY:	CommonLineCalculate via LICL_dirtyLineCallback
PASS:		es:di	= Line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineDirty	proc	far
	uses	si, ds
	.enter
	segmov	ds, es, si			; ds:si <- line
	mov	si, di
	call	HugeArrayDirty			; Dirty the array
	.leave
	ret
LargeLineDirty	endp


Text	ends
