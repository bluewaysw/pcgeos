
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		graphicsSendBitmapCompressedPCL4.asm

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

	$Id: graphicsSendBitmapCompressedPCL4.asm,v 1.1 97/04/18 11:51:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendBitmapCompressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap taking out as much white space as
		possible. The white space is removed by sending a cursor move
		to the right the blank bytes' amount. There is a trade off
		between the amount of raster bytes it would take to move and 
		the number of bytes a cursor move costs. This routine checks
		for the magic number of bytes that will yeild a memory savings
		and sends the appropriate method of blank space. For LaserJets
		with memory constraints.

CALLED BY:	PrintSwath

PASS:		es	- PState segment

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendBitmapCompressed	proc	near
	uses	ax,cx,bx,dx,si,di
thisLine	local	PrintScanlineInfo
	.enter

EC<	mov	ax,es							>
EC<	mov	thisLine.PSI_pstateSeg,ax				>
EC<	mov	ax,ds							>
EC<	mov	thisLine.PSI_bitmapSeg,ax				>
EC<	mov	ax,es:[PS_bandBWidth]					>
EC<	mov	thisLine.PSI_bandBWidth,ax				>


		; obtain the # of scanlines
	mov	cx,es:[PS_swath].[B_height]	;get the height of this bitmap
						;swath for counter.
	call	DerefFirstScanline		;get the pointer to data


		;ds:si	- input bitmap data source (beginning of scanline)
		;es	- PSTATE segment

ScanLineLoop:
		;save height of bitmap and segment addresses.
	push	cx,es,ds
	mov	di,si			;copy bitmap offset.

		;swap segments.
	push	es			;PState
	segmov	es,ds,ax		;swap segment of bitmap.
	pop	ds			;pop PState into ds

	mov	thisLine.PSI_begOLine,di	;save the starting address of
						;this scanline

		;send a scanline to the printer, looking for areas of lots of 0s
		;so that these may be sent as a cursor move instead of wasting
		;memory on them as bitmap data.

		;this section reads a scanline up to the point where some data 
		;is present
		;es:di	- address of input bitmap scanline
		;ds	- Segment of PSTATE
	mov	thisLine.PSI_begOData,di ;initialize the beginning pointer.
	mov	cx,ds:[PS_bandBWidth]	;get byte width of bitmap

		;this section scans data for a zero byte, so that the routine 
		;to check for the length of the zero bytes can be called.
scanforzeros:
EC<	cmp	cx,ds:PS_bandBWidth					>
EC<	ERROR_A LINE_COUNT_OUT_OF_RANGE					>
	clr	al			;check for a zero match.
	repne	scasb
	jnz	dataendofscanline	;if z flag is clr, cx reached zero
					;before a match, meaning that we
					;must be at end of line -- we just
					;want to send any data and exit.
EC<	cmp	cx,ds:PS_bandBWidth					>
EC<	ERROR_A LINE_COUNT_OUT_OF_RANGE					>
	dec	di			;point back at first zero byte.
	inc	cx
	mov	thisLine.PSI_begOZeros,di ;set the beginning of zeros address.
	clr	al			;compare with zeros.
	repe scasb
	jz	zeroendofscanline	;if z flag is set, cx reached zero
					;before a mismatch, meaning that we
					;must be at end of line -- we just want
					;to send any data that preceeded the
					;zeros and exit.
EC<	cmp	cx,ds:PS_bandBWidth					>
EC<	ERROR_A LINE_COUNT_OUT_OF_RANGE					>
		;this section tests the length of zero bytes to see if it
		;worth sending the adjust cursor control code. di should
		;contain the current position of the scan.

	dec	di			;point back at the first data found.
	inc	cx
	mov	dx,di			;get offset in dx.
	sub	dx,thisLine.PSI_begOZeros ;how many zeros are there?
	cmp	dx,ENOUGH_BLANK		;are there enough for an adjust cursor?
	jb	scanforzeros		;if not, start looking through the
					;following data for more zero bytes
					;again.

		;This section converts the distance in blank bytes to the
		;distance in dots, and sends the control code out to move the
		;cursor to the right.
		;dx = number of blank bytes.

	push	es,ds
	push	es			;swap the PState, and bitmap seg regs
	segmov	es,ds,ax
	pop	ds
	call	PrSendGraphicData ;send out the data preceeding the blanks.
	pop	es,ds
	jnc	newBeginning		;no errors, continue....
	pop	cx,es,ds		;else pop everything,
	jmp	exit			;and exit.

newBeginning:

	mov	thisLine.PSI_begOData,di ;set the new beginning of data.

	jmp	scanforzeros		;do another data section.

		;At end of scanline everything winds up here....
		;if the end of the scanline was reached during the scan for a
		;zero byte, then the current index from the scan is loaded into
		;the begOZeros variable, and the data is sent.  If the end is
		;reached during the test for the length of the zero bytes, then
		;the begOZeros and begOData are compared.
		;If they are =, then the line was blank, and the line feed
		;count is increased by 1, and nothing is sent. If the line had
		;data on it, then the data is sent normally, and a graphic
		;linefeed is performed.
dataendofscanline:
	mov	thisLine.PSI_begOZeros,di ;do not dec, because cx being
					;decremented caused the jump
					;here. ie, first mismatch
					;is one past the length of the scanline.
zeroendofscanline:
	pop	cx,es,ds
		;es has to be the PState here.....
	call	PrSendGraphicData
	jc	exit
	mov	ax,1
	call	PrAdjustForResolution
	add	es:[PS_cursorPos].P_y,ax ;update the position down the page.

		;do another scanline.
	dec	cx
	jcxz	exit
	inc	es:[PS_newScanNumber]	;set to next scan line.
	call	DerefAScanline		;ds:si --> next scan line.
	jmp	ScanLineLoop

exit:
	.leave
	ret
PrSendBitmapCompressed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendGraphicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sends a block of data pointed at by ds:begOData of (begOZeros - 
	begOData) length to the stream (inverting it and preceding it
	with the transfer graphics control code).

CALLED BY:
	PrDoScanLine

PASS:
	es	- Segment of PSTATE
	ds	- Segment of input bitmap
	bp	- points at stack variables.

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
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendGraphicData	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
thisLine	local	PrintScanlineInfo
	.enter	inherit

		;figure the width of this block of scanline data.
	mov	bx,thisLine.PSI_begOZeros ;get end of data.
	mov	si,thisLine.PSI_begOData
	sub	bx,si			;get length of data
	clc
	jz	exit			;if the zeros are the beginning,
					;then there is
					;no data to send this time.

		;set the cursor to where it needs to go.
	mov	ax,es:[PS_cursorPos].P_y ;load the current cursor position.
	mov	di,offset pr_codes_AdjustInY	;control code.
	call	WriteNumCommand
	jc	exit			;pass any error out.
	mov	ax,thisLine.PSI_begOData ;adjust pointer for this resolution.
	sub	ax,thisLine.PSI_begOLine ;subtract the scanline offset.
	
EC<	cmp	ax,thisLine.PSI_bandBWidth				>
EC<	ERROR_A LINE_COUNT_OUT_OF_RANGE					>

	shl	ax,1			;shift to get from bytes to dots.
	shl	ax,1
	shl	ax,1
	call	PrAdjustForResolution

	add	ax,es:[PS_cursorPos].P_x ;dx now has the absolute cursor x pos.
	mov	di,offset pr_codes_AdjustInX
	call	WriteNumCommand
	jc	exit			;pass any error out.

		;recover the width of data
	mov	cx,bx

		;send the section of the scanline.
		;cx	- number of bytes in current data set.	
		;ds:si	- input bitmap data source (beginning of scanline)
		;es 	- PState segment
	mov	ax,cx		;get in ax for ascii routine.
	mov	di,offset pr_codes_StartAndTransferGraphics
	call	WriteNumCommand
	jc	exit
	call	PrintStreamWrite	;send them out.
	jc	exit			;pass any error out.
	mov	si,offset pr_codes_EndGraphics
	call	SendCodeOut

exit:
	.leave
	ret
PrSendGraphicData	endp
