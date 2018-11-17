

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferCreate.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	5/92	initial version

DESCRIPTION:

	$Id: bufferCreate.asm,v 1.1 97/04/18 11:50:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrCreatePrintBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Looks at the PSTATE to find out what graphics resolution this document
is printing at.  The routine then allocates a chunk of memory for a output
buffer for the graphic print routines.

CALLED BY:	PrintSwath

PASS:		es	- pointer to locked PState

RETURN:	
	PSTATE loaded with handle and segment of buffers
DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:
	create the buffer space used by the print drivers in this mode.
	BandBuffer is created to hold a complete band of print data extracted
	from the HugeArray blocks. It is BM_width x BYTES_COLUMN long.
	OutputBuffer is created to hold a small section of rotated data, and
	pass it to the stream driver. It is PRINT_OUTPUT_BUFFER_SIZE long.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrCreatePrintBuffers	proc	near
	uses	ax,bx,cx,dx
	.enter
	mov	ax,es:[PS_bandBWidth]	;get the x dimension of the bitmap.
	mov	cx, es:[PS_buffHeight]  ;get # for buff height
	mul	cx			; ax = buffer size needed
	add	ax,PRINT_OUTPUT_BUFFER_SIZE ;add the size of the outputbuffer
	mov	cx,ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE ;mem flags
	call	MemAlloc	;allocate a buffer in memory.
	mov	es:[PS_bufHan],bx	;store handle in PSTATE.
	mov	es:[PS_bufSeg],ax	;store the segment in PSTATE.
	.leave
	ret
PrCreatePrintBuffers	endp

