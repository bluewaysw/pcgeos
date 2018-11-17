COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferDestroyRotateNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/95	initial version

DESCRIPTION:

	$Id: bufferDestroyRotateNike.asm,v 1.1 97/04/18 11:50:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrDestroyRotateBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at the PSTATE to find out what graphics resolution
		this document is printing at.  The routine then allocates
		a chunk of memory for a output buffer for the graphic print
		routines.

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
	For DWPs, the output buffer is in fixed memory, and separate from
	this block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/09/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrDestroyRotateBuffers	proc	near
	uses	bx
	.enter

EC <	push	ds							>
EC <	mov	bx, es:[PS_dWP_Specific].DWPS_buffer1Segment		>
EC <	mov	ds, bx							>
EC <	cmp	ds:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_ROTATE_BUFFER		>
EC <	pop	ds							>

	mov	bx, es:[PS_dWP_Specific].DWPS_buffer1Handle ;handle in PSTATE.
	call	MemFree			;discard the block of memory.

	.leave
	ret
PrDestroyRotateBuffers	endp
