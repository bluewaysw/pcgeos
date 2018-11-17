COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallGetText.asm

AUTHOR:		John Wedgwood, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/25/91	Initial revision

DESCRIPTION:
	Support for extracting text from a small text object.

	$Id: tsSmallGetText.asm,v 1.1 97/04/07 11:22:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextStorageCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallGetTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a small text object to a given text reference.

CALLED BY:	TS_GetTextRange via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		ss:bx	= VisTextRange filled in
		ss:bp	= TextReference filled in
RETURN:		dx.ax	= Number of bytes copied
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallGetTextRange	proc	far
	class	VisTextClass
	uses	bx, cx, si
	.enter
	;
	; We need to set up the parameters before we start copying the
	; data to the text-reference buffer.
	;
	
	;
	; Get a pointer to the start of the text to copy
	;
	call	TextStorage_DerefVis_DI		; ds:di <- instance ptr
	mov	si, ds:[di].VTI_text
	mov	si, ds:[si]			; ds:si <- text pointer
SBCS <	add	si, ss:[bx].VTR_start.low	; ds:si <- start of range >
DBCS <	mov	ax, ss:[bx].VTR_start.low				>
DBCS <	shl	ax, 1				; ax <- offset to text	>
DBCS <	add	si, ax							>
	
	;
	; Compute the number of bytes to copy
	;
	mov	ax, ss:[bx].VTR_end.low		; ax <- number of bytes to copy
	sub	ax, ss:[bx].VTR_start.low

	;
	; Initialize the "starting position" in the output buffer
	;
	clrdw	cxbx				; cx.bx <- starting position
						;    in output buffer
	;
	; ds:si	= Pointer to text to copy
	; ax	= Number of bytes to copy after ds:si
	; cx.bx	= Offset to write to in output TextReference
	; ss:bp	= TextReference to write to
	;
	call	AppendFromPointerToTextReference
	
	clr	dx				; dx.ax <- # of bytes written
	.leave
	ret
SmallGetTextRange	endp


TextStorageCode	ends
