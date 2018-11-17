
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		graphicsSendBitmapPCL4.asm

AUTHOR:		Dave Durran January 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial laserjet revision
	Dave	1/21/92		2.0 PCL 4 driver revision


DESCRIPTION:

	$Id: graphicsSendBitmapPCL4.asm,v 1.1 97/04/18 11:51:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap. This version does no compression,
		other than not sending white space to the right of active
		print areas. For LaserJets with more than 1Mbyte of memory.

CALLED BY:	PrintSwath

PASS:		es	- PState segment
		dx:si	- Start of bitmap structure.

RETURN:		carry	-set if some communications error
		ds	-sptr to last Huge array block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version
	Dave	2/92		optimized and wrapped into pcl4 driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendBitmap	proc	near
	uses	ax,cx,si,di,es
	.enter


		;send the start graphics control code.
	mov	si,offset pr_codes_StartGraphics
	call	SendCodeOut		;
	jc	exit			; check for transmission error

	mov	cx,es:[PS_swath].[B_height] ;get the number of scanlines.
	call	DerefFirstScanline		;get the pointer to data

ScanLineLoop:
		;ds:si	- input bitmap data source (beginning of scanline)
		;es	- PSTATE segment

	push	cx		;save height of bitmap.

		;determine the live print width of this scanline.
		;optimized PrScanBuffer Routine (once/scanline).
	mov	cx,es:PS_bandBWidth ;get the width of the screen input buffer.
	push	ds,es
	segmov	es,ds,ax
	std			;set the direction flag to decrement..
	clr	al		;clear al (check for zero bytes).
	mov	di,si		;get the start of buffer.
	dec	di		;adjust to point at end of "previous line".
	add	di,cx		;add to the reference start of line.
	repe	scasb		;see if this byte is blank (nothing to print).
	inc	cx		;cx now has the printed byte width.
				;or at least 1 if there was no printed info.
	cld			;clear the direction flag.
	pop	ds,es		;switch the segs back

		;send control code to send graphics.
		;cx	- number of bytes in this scanline.
		;es	- PSTATE segment
	mov	ax,cx		;get in ax for ascii routine.
	mov	di,offset pr_codes_TransferGraphics
	call	WriteNumCommand
	jc	exitErr

		;send the scanline out
		;cx	- number of bytes in this scanline.
		;ds:si	- input bitmap data source (beginning of scanline)
		;es	- PSTATE segment
	call	PrintStreamWrite	;send them out.
	jc	exitErr

		;do another scanline.
	pop	cx
	cmp	cx,1			;see if that was the last line.
	je	endGraphics
	inc	es:[PS_newScanNumber]	;point at next scanline element.
	call	DerefAScanline		;ds:si --> next scan line.
	loop	ScanLineLoop

		;send the end graphics control code.
endGraphics:
	mov	si,offset pr_codes_EndGraphics
	call	SendCodeOut		;
exit:
	.leave
	ret

	; some transmission error. cleanup and exit
exitErr:
	pop	cx			; restore count
	jmp	exit
PrSendBitmap	endp

