COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Buffer
FILE:		bufferDestroyNike.asm

AUTHOR:		Joon Song, Apr  5, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/ 5/95   	Initial revision


DESCRIPTION:
		

	$Id: bufferDestroyNike.asm,v 1.1 97/04/18 11:50:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrDestroyPrintBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rid of the buffer space used for the print buffer.

CALLED BY:

PASS:		es	- Segment of PSTATE
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrDestroyPrintBuffers	proc	near
	uses	bx
	.enter

EC <	push	ds							>
EC <	mov	bx, es:[PS_bufSeg]					>
EC <	mov	ds, bx							>
EC <	cmp	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>
EC <	pop	ds							>

	mov	bx, es:[PS_bufHan]	;get handle from PSTATE.
	call	MemFree			;discard the block of memory.

	; Destroy history buffer created for color printing

	mov	al,es:[PS_printerType]
	andnf	al,mask PT_COLOR
	cmp	al,BMF_MONO
	je	done

EC <	push	ds							>
EC <	mov	bx, es:[PS_dWP_Specific].DWPS_buffer2Segment		>
EC <	mov	ds, bx							>
EC <	cmp	ds:[PRINT_COLOR_HISTORY_BUFFER_SIZE], 0xadeb		>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>
EC <	pop	ds							>

	mov	bx, es:[PS_dWP_Specific].DWPS_buffer2Handle
	call	MemFree			;discard the block of memory.
done:
	.leave
	ret
PrDestroyPrintBuffers	endp
