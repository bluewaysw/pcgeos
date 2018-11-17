COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferCompressNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	12/94	initial version

DESCRIPTION:

	$Id: bufferCompressNike.asm,v 1.1 97/04/18 11:50:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrCompressBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compress the white space off the front and back ends of the
		Band Buffer, so that the first column is at offset 0

CALLED BY:	
	PrPrintABand

PASS:	
		es	=	PSTATE segment
		GPB_XXXX structure loaded.
RETURN:	

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	This routine simply moves all the scanlines to be one after the other
	up against the beginning of the band buffer area.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrCompressBandBuffer	proc	near
	uses	ds,es,di,si
	.enter
	mov	cx,es:[PS_buffHeight] ;height of the band buffer.
					;(loop counter for scanlines)

		;get the source buffer start address.
	mov	ds,es:[PS_bufSeg]
	mov	si,ds:GPB_startColumn
	shr	si,1			;convert columns into bytes.
	shr	si,1
	shr	si,1
	add	si, offset GPB_bandBuffer	

		;calculate the width of the final buffer.
	mov	bx,es:PS_bandBWidth ;get the width of the screen input buffer.
					;(offset between source scanlines)
	sub	bx,ds:GPB_bytesWide	;subtract the amount we will move.
					;(offset to next source scanline)

		;get the start of the destination buffer.
	mov	es,es:[PS_bufSeg]
	mov	di, (offset GPB_bandBuffer)


doScanline:
	mov	dx,cx			;save cx loop counter
	mov	cx,es:GPB_bytesWide	;move this many bytes/scanline
	shr	cx,1			;use words for any speedup.
	jnc	moveWords
	movsb				;move any odd byte now.
	jcxz	doneThisLine		;if only 1 byte in line, stop here.
moveWords:
	rep	movsw			;move the data forward in the buffer.
doneThisLine:
	mov	cx,dx			;get the scanline counter back.
	add	si,bx			;adjust source to point at next start.
	loop	doScanline		;do all the scanlines.

	.leave
	ret
PrCompressBandBuffer	endp
