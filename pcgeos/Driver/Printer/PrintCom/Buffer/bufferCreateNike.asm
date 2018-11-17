COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferCreateNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/94	initial version

DESCRIPTION:

	$Id: bufferCreateNike.asm,v 1.1 97/04/18 11:50:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrCreatePrintBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks at the PSTATE to find out what graphics resolution
		this document is printing at.  The routine then allocates
		a chunk of memory for a output buffer for the graphic print
		routines.

CALLED BY:	PrintSwath

PASS:		es - pointer to locked PState

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
	Dave	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrCreatePrintBuffers	proc	near
	uses	ax,bx,cx
	.enter

NEC <	mov	ax,PRINT_OUTPUT_BUFFER_SIZE	;assume PS_bandBWidth < 9.1"  >
EC <	mov	ax,PRINT_OUTPUT_BUFFER_SIZE+2	;assume PS_bandBWidth < 9.1"  >
	mov	cx,(mask HAF_NO_ERR shl 8) or mask HF_FIXED or mask HF_SHARABLE
	call	MemAlloc		;allocate a buffer in memory.
	mov	es:[PS_bufHan],bx	;store handle in PSTATE.
	mov	es:[PS_bufSeg],ax	;store the segment in PSTATE.

EC <	push	ds							>
EC <	mov	ds, ax							>
EC <	mov	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	pop	ds							>

	; Allocate history buffer for color printing

	mov	al,es:[PS_printerType]
	andnf	al,mask PT_COLOR
	cmp	al,BMF_MONO
	je	done

NEC <	mov	ax,PRINT_COLOR_HISTORY_BUFFER_SIZE			>
EC <	mov	ax,PRINT_COLOR_HISTORY_BUFFER_SIZE+2			>
	mov	cx,(mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8 or \
		   mask HF_FIXED or mask HF_SHARABLE
	call	MemAlloc
	mov	es:[PS_dWP_Specific].DWPS_buffer2Handle,bx
	mov	es:[PS_dWP_Specific].DWPS_buffer2Segment,ax

EC <	push	ds							>
EC <	mov	ds, ax							>
EC <	mov	ds:[PRINT_COLOR_HISTORY_BUFFER_SIZE], 0xadeb		>
EC <	pop	ds							>

done:
	.leave
	ret
PrCreatePrintBuffers	endp
