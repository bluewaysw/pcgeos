

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferScanBand.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/92	initial version

DESCRIPTION:

	$Id: bufferScanBand.asm,v 1.1 97/04/18 11:50:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrScanBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the screen (band Buffer) to find out how wide to print.

CALLED BY:	
	PrPrintABand

PASS:	
		es	=	PSTATE segment

RETURN:	
		dx	=	number of columns that we are going to print.
		bx	=	number of bytes wide to print.

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrScanBandBuffer	proc	near
	uses	es,ax,cx,di,si
	.enter
	mov	cx,es:[PS_buffHeight] ;height of the band buffer.
	mov	bx,es:PS_bandBWidth ;get the width of the screen input buffer.
	mov	es,es:[PS_bufSeg]
	std			;set the direction flag to decrement..
	clr	al		;clear al (check for zero bytes).
	clr	dx		;start with zero width.

		;get the start of buffer.
		;adjust to point at end of "previous line".
	mov	si, (offset GPB_bandBuffer)-1

		;loop once/scanline.

DoScanLine:
	push	cx		;save cx loop counter
	mov	di,si		;save index, because scas screws it up.
	mov	cx,bx		;get the width of the screen input buffer.
	add	di,cx		;add to the reference start of line.

	;check a byte.
	repe	scasb		;see if this byte is blank (nothing to print).

	jz	LastByteOK	;if last byte was blank, skip.
	inc	cx
LastByteOK:
	cmp	dx,cx		;see if cx is less than dx
	jnc	NewWidth	;if so, skip.
	mov	dx,cx		;load dx with new width.
NewWidth:
	pop	cx		;get back the loop counter.
	cmp	dx,bx		;see if the width is the max already.
	je	FinalWidth	;if so, no need to check any more.
	add	si,bx		;add the byte band width for next time.
	loop	DoScanLine	;do for all lines.

	mov	bx,dx		;pass the number of bytes wide also.
FinalWidth:
	mov	cl,3		;multiply number of bytes by 8
	sal	dx,cl		; to get number of columns.
	cld			;clear the direction flag.
	.leave
	ret
PrScanBandBuffer	endp
