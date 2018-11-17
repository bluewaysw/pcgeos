

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common Graphics routines
FILE:		graphicsPCLTIFF.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	5/92	initial version

DESCRIPTION:

	$Id: graphicsPCLTIFF.asm,v 1.1 97/04/18 11:51:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the input scanline in ds:si to find out how wide to print.
	Then, use the HP style TIFF compression (mode 2) to send it out.

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
;	or	cx,cx		;see if zero.
;	jnz	sendALine
	jcxz	sendBlankLine	;if no data on this line, send zero byte.

		;------------Scanline transmission Routine
;sendALine:
		;see if the buffer is to be sent compresseed or not.
	test	es:[PS_jobParams].[JP_printerData].[PUID_compressionMode],02h
	jz	sendBuffer	;if uncompressed is desired, just send bitmap

		;initialize some variables for the scanline.
	clr	bx		;init the scanline byte counter.
	mov	es,es:[PS_bufSeg] ;set up for the output buffer segment,
	mov	di,offset GPB_outputBuffer ;and address.

		;------------TIFF compression Routine
		;this is the point to loop back to after every change between
		;literal and repeated bytes. ah is the count byte, and ah gets
		;initialized/re-initialized here.
		;ah = count byte
		;al = data byte
		;bx = offset to stream for storing count byte.
		;
newGroup:
        clr     ax              ;init the count byte and low byte for stosb.
        mov     bx,di           ;save offset for the count byte.
                                ;bx is left pointing at this place holder
                                ;byte, before any data bytes.
        stosb                   ;stuff a zero here, so the place is held.

	lodsb			;pick up the first data byte in this group.

		;this is the top of the next literalbyte loop.
nextLiteralByte:
	stosb			;store the data byte

		;this is the top of the next Repeat byte loop.
nextRepeatByte:
        dec     cx		;see if this is the final byte on the line.
        jz	sendBufferTIFF
	lodsb			;pick up the next data byte in this group.	
	
	cmp	al,es:[di]-1	;check this byte against the data byte already
				;stored in the output buffer.
	je	repeatEntry	;if the same, these are repeat bytes, 
				;jump out to the repeat
		;------------Literal Routine
	test	ah,080h		;see if the count byte is neg.
	jz	doLiteral

		;this routine changes the group from a repeat group to a
		;literal group. this involves re storing a count byte, and the
		;current data byte after.
	mov	es:[bx],ah	;store the old count byte.
	mov	bx,di		;get new index to current group's count byte.
	mov	ah,al		;get the data into the high byte.
	clr	al		;init the count byte.
	stosb			;store the count byte before the data byte.
	xchg	ah,al		;get them in the right regs for following...
	jmp	nextLiteralByte	;go to store this one, and check the next

doLiteral:
	inc	ah
	mov	es:[bx],ah	;store away the count byte.
	cmp	ah,127		;see if we are at the limit for count byte.
	jb	nextLiteralByte	;If not, do another byte.
	stosb
if PZ_PCGEOS
	dec	cx		;see if this is the final byte on the line.
	jz	sendBufferTIFF
endif
	jmp	newGroup	;start a new group up.


		;------------Repeat Routine
repeatEntry:
	cmp	ah,00h		;see if the count byte is neg.
	jle	doRepeat

		;This section changes from literal to reapeat bytes.
	dec	ah		;remove this byte from count.
	mov	es:[bx],ah	;save away the count byte.
	clr	ah		;-1 means 1 repeat byte.(loaded on next dec)
	mov	bx,di
	dec	bx		;point at previous byte.
	stosb			;save the data byte.

doRepeat:
	dec	ah		;increase the repeat count.
	cmp	ah,129		;see if at limit.
	ja	nextRepeatByte	;if below limit, read another data byte.
				;else,
        mov     es:[bx],ah      ;store away the count byte.
if PZ_PCGEOS
	dec	cx		;see if this is the final byte on the line.
	jz	sendBufferTIFF
endif
        jmp     newGroup        ;start a new group up.


		;------------Buffer transmit Routines (3)
		;no data on this line, send one zero byte to adjust the cursor
		;vertically downward.
sendBlankLine:
	mov	si,offset pr_codes_TransferNoGraphics
	call	SendCodeOut
	jmp	exit		;get around the blank line code.
				
		;send the compressed buffer out to the stream.
sendBufferTIFF:
	mov	es:[bx],ah	;store the old count byte.
	segmov	ds,es,cx	;get buffer segment into ds.
	mov	es,bp		;recover the PState.
	mov	cx,di		;get the byte count,
	mov	ax,di		;in ax also.
	mov	di,offset pr_codes_TIFFTransferGraphics
	call	WriteNumCommand	;send the transfer command with the byte
				;count.
	jc	exit
	mov	si,offset GPB_outputBuffer ;and address.
	call	PrintStreamWrite	;send it!
	jmp	exit		;get around the blank line code.

		;send the uncompressed bitmap data.
sendBuffer:
	mov	ax,cx			;length of bitmap scanline.
	mov	di,offset pr_codes_TransferGraphics
	call	WriteNumCommand ;send the transfer command with the byte
                                ;count.
	jc	exit
	call	PrintStreamWrite	;send it!

exit:
	.leave
	ret
PrSendScanline	endp
