COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferCreateRotateNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/95	initial version

DESCRIPTION:

	$Id: bufferCreateRotateNike.asm,v 1.1 97/04/18 11:50:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrCreateRotateBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at the PSTATE to find out what graphics resolution
		this document is printing at.  The routine then allocates
		a chunk of memory for a output buffer for the graphic print
		routines.

CALLED BY:	PrintSwath

PASS:		es - pointer to locked PState
RETURN:		PSTATE loaded with handle and segment of buffers
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	create the buffer space used by the print drivers in this mode.
	BandBuffer is created to hold a complete band of print data extracted
	from the HugeArray blocks. It is BM_width x BYTES_COLUMN long.
	For DWPs, the output buffer is in fixed memory, and separate from
	this block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/09/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrCreateRotateBuffers	proc	near
	uses	ax,bx,cx
	.enter
NEC <	mov	ax,PRINT_ROTATE_BUFFER_SIZE ;get size to allocate	>
EC <	mov	ax,PRINT_ROTATE_BUFFER_SIZE + 2				>
	mov	cx,mask HF_FIXED or mask HF_SHARABLE or (mask HAF_NO_ERR shl 8)
	call	MemAlloc	;allocate a buffer in memory.
	mov	es:[PS_dWP_Specific].DWPS_buffer1Handle,bx ;handle in PSTATE.
	mov	es:[PS_dWP_Specific].DWPS_buffer1Segment,ax ;segment in PSTATE.
EC <	push	ds							>
EC <	mov	ds, ax							>
EC <	mov	ds:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	pop	ds							>
	.leave
	ret
PrCreateRotateBuffers	endp
