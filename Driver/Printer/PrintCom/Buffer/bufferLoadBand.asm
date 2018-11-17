

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferLoadBand.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/92	initial version

DESCRIPTION:

	$Id: bufferLoadBand.asm,v 1.1 97/04/18 11:50:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: Do a block transfer of the bytes from the Huge Array block to our
memory. This allows us to build out a buffer one whole band high.

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer into bitmap data
				from Huge Array.
		es:[PS_curScanNumber]	- number of the scanline to last used
		es:[PS_newScanNumber]	- number of the scanline to use
		es	- segment of PSTATE

RETURN:		
		ds:si	- adjusted to after the band in question

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrLoadBandBuffer	proc	near
	uses	ax,bx,cx,dx,di
	.enter
	mov	bx,es:[PS_bandBWidth]	;width of the band.
	mov	cx,es:[PS_buffHeight]	;do es:[PS_buffHeight] lines high.
	mov	di,offset GPB_bandBuffer ;destination offset.
scanlineLoop:
	call	DerefAScanline		;get ds:si pointing at the next line
	mov	dx,cx			;save the scanline count.
	mov	cx,bx			;reload the bandWidth
	push	es			;save the PState address.
	mov	es,es:[PS_bufSeg]	;destination segment

	shr	cx,1			;use words, they're faster.
	jnc	moveWords		;if not odd bytes, go to move words.
	movsb				;if so, send the odd byte now.
moveWords:
	rep movsw			;transfer the data to the Band Buffer.
	mov	cx,dx			;recover the scanline loop count.
	pop	es			;recover the PState segment address.
	mov	ax,es:[PS_curScanNumber]
	add	ax,es:[PS_interleaveFactor]
	mov	es:[PS_newScanNumber],ax
	loop	scanlineLoop
	.leave
	ret
PrLoadBandBuffer	endp
