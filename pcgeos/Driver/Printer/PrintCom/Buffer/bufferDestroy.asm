

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferDestroy.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	5/92	initial version

DESCRIPTION:

	$Id: bufferDestroy.asm,v 1.1 97/04/18 11:50:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrDestroyPrintBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Get rid of the buffer space used for the print buffer.

CALLED BY:

PASS:
	ds	- sptr to huge array element block.
	es	- Segment of PSTATE

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
	call	HugeArrayUnlock		;get rid of last locked block in 
					;huge array.
	mov	bx,es:[PS_bufHan]	;get handle from PSTATE.
	call	MemFree		;discard the block of memory.
	.leave
	ret
PrDestroyPrintBuffers	endp
