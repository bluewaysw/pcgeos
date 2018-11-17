COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		spline
FILE:		splineGString.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 3/91	Initial version.

DESCRIPTION:
	Routing for loading points into the spline object from a
	graphics string.

	$Id: splineGString.asm,v 1.1 97/04/07 11:09:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineGStringCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineReadGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Read a passed graphics string, adding points from
		anything that looks interesting.

PASS:		*DS:SI	= VisSplineClass object
		DS:DI	= VisSplineClass instance data
		ES	= Segment of VisSplineClass.
		AX	= Method.
		CX 	= Handle of gstring

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 3/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineReadGString	method	dynamic	VisSplineClass, 
					MSG_SPLINE_READ_GSTRING
	uses	ax,cx,dx,bp
	.enter
	call	SplineMethodCommon

	mov	si, es:[bp].VSI_scratch
	mov	si, ds:[si]
	add	si, offset SD_gstringBuffer
	mov	bx, si			; start of buffer
	mov	di, cx			; gstring handle
	mov	cx, SPLINE_GSTRING_BUFFER_SIZE
	call	GrGetGStringElement

	; Lookup the gstring opcode in the table

	push	es
	segmov	es, cs, di
	mov	di, offset GStringOpCodeTable
	mov	cx, size GStringOpCodeTable
	repne	scasb
	pop	es
	jne	done

	; Get the parse table for this opcode

	mov	bx, size GStringOpCodeTable
	sub	bx, cx
	shl	bx
	mov	ax, cs:GStringParseTable[bx]

	mov	si, es:[bp].VSI_scratch
	mov	bx, offset SD_gstringBuffer
	call	SplineParseSimpleShape

; Now make sure the new points get drawn and exit

	call	SplineRecalcVisBounds
	call	SplineInvalidate
done:
	call	SplineEndmCommon
	.leave
	ret
SplineReadGString	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineParseSimpleShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a simple shape using the passed table

CALLED BY:

PASS:		cs:ax - parse table for converting shape to spline
		points
		*ds:si - scratch chunk
		bx - offset from start of scratch chunk to data

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineParseSimpleShape	proc near	uses ax,bx,cx,dx,di,si,bp
	class	VisSplineClass 
	.enter

; Load the number of points from the parse table
	mov	di, ax
	inc	ax
	mov	cl, cs:[di]
	clr	ch
	
startLoop:
	push	cx		
	push	bx		

; Point DS:DI to the current gstring element
	mov	di, ds:[si]	
	add	di, bx
				
; Get the offset INTO the GString element from the parse table for the
; first coordinate 
	mov	bx, ax
	inc	ax		
	mov	bl, cs:[bx]	
	clr	bh

; load first coordinate
	mov	cx, ds:[bx][di]

; now, go to next table entry, and get offset into GString element for
; next coordinate:

	mov	bx, ax
	inc	ax
	mov	bl, cs:[bx]
	clr	bh
	mov	dx, ds:[bx][di]

; next table entry is the INFO field
	mov	bx, ax
	inc	ax
	mov	bl, cs:[bx]
	clr	bh

	push	ax, si
	mov	si, es:[bp].VSI_points
	call	SplineAddPointFar
	pop ax, si

	pop	bx
	pop	cx
	loop	startLoop

	.leave
	ret
SplineParseSimpleShape	endp


;-----------------------------------------------------------------------------
; 	These next 2 tables MUST be in the same order.		
;-----------------------------------------------------------------------------
 
GStringOpCodeTable	byte	\
	GR_DRAW_LINE,
	GR_DRAW_LINE_TO,
	GR_DRAW_RECT

GStringParseTable	word	\
	offset	GrDrawLineParseTable,
	offset	GrDrawLineToParseTable,
	offset	GrDrawRectParseTable


 
GrDrawLineParseTable	GStringParseElement	\
	<ODL_x1, ODL_y1, SPT_ANCHOR_POINT>,
	<ODL_x2, ODL_y2, SPT_ANCHOR_POINT>

GrDrawLineToParseTable	GStringParseElement	\
	<ODLT_x2, ODLT_y2, SPT_ANCHOR_POINT>


GrDrawRectParseTable	GStringParseElement \
	<ODR_x1, ODR_y1, SPT_ANCHOR_POINT>,
	<ODR_x2, ODR_y1, SPT_ANCHOR_POINT>,
	<ODR_x2, ODR_y2, SPT_ANCHOR_POINT>,
	<ODR_x1, ODR_y2, SPT_ANCHOR_POINT>
	


SplineGStringCode	ends
