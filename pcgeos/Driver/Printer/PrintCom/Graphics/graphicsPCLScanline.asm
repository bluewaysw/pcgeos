

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common Graphics routines
FILE:		graphicsPCLScanline.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	6/92	initial version

DESCRIPTION:

	$Id: graphicsPCLScanline.asm,v 1.1 97/04/18 11:51:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the input scanline in ds:si to find out how wide to print.

CALLED BY:	
	PrintSwath

PASS:	
		es	=	PSTATE segment
		ds:si	=	dereferenced bitmap scanline.

RETURN:	
	nothing

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
PrSendScanline	proc	near
	uses	ax,bx,cx,si,di,bp,ds
	.enter
	mov	cx,es:PS_bandBWidth ;get the width of the screen input buffer.
	mov	bp,es		;save PState segment.
	segmov	es,ds,ax	;get scanline segment in es for scas
	std			;set the direction flag to decrement..
	clr	al		;clear al (check for zero bytes).
	mov	di,si		;save index, because scas screws it up.
	add	di,cx		;add to the reference start of line.
	dec	di
	repe	scasb		;see if this byte is blank (nothing to print).
	jz	lastByteOK	;if last byte was blank, skip.
	inc	cx

lastByteOK: 			;cx is now the width of the scanline.
	cld			;clear the direction flag.
	mov	es,bp		;get back PState.
	jcxz	sendBlankLine	;if no data on this line, send zero byte.


		;------------Buffer transmit Routines (2)
		;send the uncompressed bitmap data.
sendBuffer:
	mov	ax,cx			;length of bitmap scanline.
	mov	di,offset pr_codes_TransferGraphics
	call	WriteNumCommand ;send the transfer command with the byte
                                ;count.
	jc	exit
	call	PrintStreamWrite	;send it!
	jmp	exit		;get around the blank line code.
				
		;no data on this line, send one zero byte to adjust the cursor
		;vertically downward.
sendBlankLine:
	mov	si,offset pr_codes_Do1ScanlineFeed
	call	SendCodeOut

exit:
	.leave
	ret
PrSendScanline	endp
