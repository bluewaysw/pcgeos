
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Escape P2 24-pin print driver
FILE:		escp2Graphics.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the escp2
	print driver graphics mode support

	$Id: escp2Graphics.asm,v 1.1 97/04/18 11:54:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		dx:si	- Start of bitmap structure.

RETURN:		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwath	proc	far
		uses	ax,cx,ds,bx,dx,si,di,ds
bandSize	local	word
		push	es			; save segreg
		mov	es, bp			; es -> PState
		.enter

		; save the bitmap pointer

		push	si			;save source of bitmap.
		push	dx			;

		; load up the band width and height

		call	PrLoadPstateVars	;set up the pstate band Vars.

	;---------------------------------------------------------------------
	;Hack to get the spooler to build out 48 lines high, but the ESCP2
	;printer can only take 24 at a time.
	;---------------------------------------------------------------------
	;begin hack
		cmp	es:PS_mode,PM_GRAPHICS_HI_RES ;if in hires mode,
		jne	endHack
		mov	es:PS_bandHeight,HI_RES_BAND_HEIGHT ;send 24 bits high.
endHack:
		; restore the bitmap pointer

		pop	ds			; ds:si -> bitmap
		pop	si

		; get width, and calculate byte width of bitmap

		mov	ax,ds:[si][BM_width]
		add	ax, 7			; round up to next byte boundary
		and	ax,0xfff8
		mov	es:[PS_bandWidth],ax	;load the dot width.
		mov	cl,3			;divide by 8....
		shr	ax,cl			;to obtain the byte width.
		mov	es:[PS_bandBWidth],ax

		; size and allocate a graphics data buffer

		call	PrMakeGraphicBuffer	;allocate the print buffer.

		; calculate size of band of data

		mov	ax, es:[PS_bandBWidth]	; get byte width of data
		mul	es:[PS_bandHeight]	; ax = size
		mov	bandSize, ax		; save it for the loop

		; calculate the #bands

		mov	ax,ds:[si][BM_height]	;get the height of bitmap.
		clr	dx			; dx:ax = divisor
		div	es:[PS_bandHeight]	;get number of bands in this
		mov	cx,ax			;swath for counter.
						; dx has remainder of division
						; this is the #scans

		; adjust pointer to data

		test	ds:[si][BM_type],mask BM_COMPLEX
		jz	addSimple
		mov	si, ds:[si].BM_data	; get offset to data
bandLoop:
		jcxz	printLastBand
		call	PrPrintABand		;print a band from this swath.
		jc	exitErr
		DoPush	ax,dx,bp			; save band count
		mov	ax,HI_RES_BAND_HEIGHT 
		call	AdjustForResolution	;get into 1/360"
		mov	dx,ax
		mov	bp, es			; bp -> PState
		call	PrLineFeed	;send control code for hi res.
		DoPopRV	ax,dx,bp
		jc	exitErr
		add	si, bandSize		;for the next starting index.
		loop	bandLoop

		; if any remainder, then we need to send it, plus a shorter
		; line feed
printLastBand:
		tst	dx			; any remainder ?
		jz	destroyBuffer
		call	PrPrintABand		; print last band
		jc	exitErr
		mov	ax, dx			; amount to line feed (in hires)
		call	AdjustForResolution	;get into 1/360"
		mov	dx,ax
sendLastLineFeed:
		push	bp
		mov	bp, es			; bp -> PState
		call	PrLineFeed	; 
		pop	bp
		jc	exitErr

		; all done, kill the buffer and leave
destroyBuffer:
		call	PrDestroyGraphicBuffer	;get rid of print buffer space.
		clc				; no errors
exit:
		.leave
		pop	es			; restore es
		ret

		; add overhead for simple bitmap
addSimple:
		add	si,size Bitmap		;add to index to get by info
		jmp	bandLoop

		; some transmission error.  cleanup and exit.
exitErr:
		call	PrDestroyGraphicBuffer	;get rid of print buffer space.
		stc
		jmp	exit
PrintSwath	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintABand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
	ds:si	=	fptr to bitmap structure (pointer to data)
	es	= 	PState segment

RETURN:		carry	- set if some transmission error

DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		In all the routines below this one, we assume the following
		in the registers:
			es	- points to output buffer
			bp	- points to PState
			ds:si	- pointer into bitmap data (input buffer)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrPrintABand	proc	near
	uses	bx,cx,dx,ds,si,bp
	.enter

	; rearrange segments so that ds -> PState and es -> our buffer

	mov	bp, es			; bp -> PState
	mov	cl, es:[PS_mode]	; get the mode while we still have PStae
	mov	es, es:[PS_bufSeg]	; es -> our buffer
	call	PrScanBuffer		;get the width of this buffer.
	tst	dx			;see if there is anything to print.
	jz	done			;just do line feed if not.
	cmp	cl, PM_GRAPHICS_LOW_RES	;see if the lores bit is set.
	ja	checkMedRes		;if anything other than low res or 
	mov	es:GB_columns,dx	;load the column count for printer.
	call	PrPrintLoBuffer		;non scaling, skip to call hires rout.
	jmp	done			;  all done, send a line feed
checkMedRes:
EC<	cmp	cl,PM_GRAPHICS_HI_RES				>
EC<	ERROR_A	INVALID_MODE					>
	call	PrSendRasterGraphics		;must be hires graphics.
done:
	mov	es, bp			; es -> PState
exit:
	.leave
	ret


PrPrintABand	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendRasterGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a Raster Graphics band.

CALLED BY:
	PrPrintABand

PASS:
	bx	=	number of bytes wide to print.
	dx	=	number of columns wide to print.
	ds:si	=	pointer into bitmap data
	bp	=	segment of PState
	PS_bandHeight = number of dots high to print.

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
	Dave	03/01/90	Initial version
	Dave	03/20/90	combined some routines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendRasterGraphics	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es,bp		;es------>PState
;SEND GRAPHICS CONTROL CODE GOES HERE.
	push	si
	mov	si,offset cs:pr_codes_SetMedGraphics
	cmp	es:PS_mode,PM_GRAPHICS_MED_RES
	je	modeOK
	mov	si,offset cs:pr_codes_SetHiGraphics
modeOK:
	call	SendCodeOut
	pop	si
	mov	cx,dx		;load cx, with the column count from PrScan..
	jc	exit	;pass any error out.
	call	PrintStreamWriteByte
	jc	exit	;pass any error out.
	mov	cl,ch
	call	PrintStreamWriteByte
	jc	exit

;negate the bitmap.
;	ds:si	- input bitmap data source (beginning of bitmap)
;	bx	- number of leading zero bytes.
	push	si		;save start of live print area.
	mov	cx,es:PS_bandHeight ;number of lines to negate.
negOuterLoop:
	DoPush	cx,si,es
	mov	cx,bx		;get live print width.
	segmov	es,ds,di	;copy ds into es.
	mov	di,si		;get source and destination to the same byte.
negLoop:
	lodsb			;get data,
	not	al		;invert data,
	stosb			;and put back in string.
	loop	negLoop
	DoPopRV	cx,si,es
	add	si,es:PS_bandBWidth ;get to next line beginning of data.
	loop	negOuterLoop
	pop	si		;si --> start of live print area.


;send the negated bitmap out
;	ds:si	- input bitmap data source (beginning of live print area)
	mov	es, bp			;get es --> PSTATE
	mov	cx,es:PS_bandHeight ;number of lines to send.
sendOuterLoop:
	DoPush	cx,si
	mov	cx,bx			;get live print width.
	call	PrintStreamWrite	;send them out.
	DoPopRV	cx,si
	jc	exit
	add	si,es:PS_bandBWidth ;get to next line beginning of data.
	loop	sendOuterLoop

;------------------------------------------------------------------------------
;	Do not do vertical cursor movement for the start of next bitmap (swath)
;------------------------------------------------------------------------------
;	mov	ax,es:PS_bandHeight
;adjust ax for the resolution, add it to the cursor position for next time.
;	call	AdjustForResolution
;	mov	dx,ax
;	call	PrLineFeed
;------------------------------------------------------------------------------
	; some transmission error. cleanup and exit
exit:
	.leave
	ret
PrSendRasterGraphics	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendRasterGraphicsOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a Raster Graphics band.

CALLED BY:
	PrPrintABand

PASS:
	ds:si	=	pointer into bitmap data
	bp	=	segment of PState

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
	Dave	03/01/90	Initial version
	Dave	03/20/90	combined some routines.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendRasterGraphicsOld	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es,bp		;es------>PState
;
;------------------------------------------------------------------------------
;	scan the left to see where we can start sending stuff.
;------------------------------------------------------------------------------
	clr	dx			;init the live print width to zero.
	mov	cx,es:PS_bandHeight	;use height as counter.
	push 	si
forwardScanLoop:
	DoPush	cx,es,ds
	segmov	es,ds,di
	mov	ds,bp
					;direction is assumed to be forward.
	mov	di,si			;load index for compare.
	mov	al,0ffh			;compare inverted zero.
	mov	cx,ds:PS_bandBWidth	;width of input bitmap (swath)
	repe	scasb			;test the byte for "zero"
	jz	aroundInc1
	inc	cx			;cx has # of non-zero bytes.
aroundInc1:
	cmp	cx,dx			;see if less than previous line.
	jle	dxIsOK
	mov	dx,cx			;if not, load dx (new width)
dxIsOK:
	DoPopRV	cx,es,ds
	add	si,es:PS_bandBWidth	;add for the start of the next line.
	loop	forwardScanLoop		;do # lines times.
	pop	si
		;dx now = # bytes to right of leading blank bytes.
	test	dx,dx			;see if zero.
	jz	exit			;done if no data.
	mov	ax,es:PS_bandBWidth	;width of input bitmap (swath)
	mov	es:PS_intWidth,dx	;save width of data.
	sub	ax,dx			;get width of leading blank bytes.
	mov	cl,3			;x8 for bit width.
	sal	ax,cl
		;set the CAP to the correct place in X to start picture.
	call	AdjustForResolution	;get into 1/360"
	call	PrLinePos		;set the printhead there.
carryStage:
	jc	carryStage2			;pass error out.
;------------------------------------------------------------------------------
;	scan the right to see where we can stop sending stuff.
;------------------------------------------------------------------------------
	push	si
	clr	dx			;initialize the width to zero.
	mov	cx,es:PS_bandHeight	;use height as counter.
	add	si,es:PS_bandBWidth	;width of input bitmap (swath)
	dec	si			;start from right side.
	std				;go backwards.
backwardScanLoop:
	DoPush	cx,es,ds
	segmov	es,ds,di
	mov	ds,bp
					;direction is assumed to be forward.
	mov	di,si			;load index for compare.
	mov	al,0ffh			;compare inverted zero.
	mov	cx,ds:PS_intWidth	;width of live data 
	repe	scasb			;test the byte for "zero"
	inc	cx			;cx has # of non-zero bytes.
					;there has to be at least 1.
	cmp	cx,dx			;see if less than previous line.
	jle	dxIsOTay
	mov	dx,cx			;if not, load dx (new width)
dxIsOTay:
	DoPopRV	cx,es,ds
	add	si,es:PS_bandBWidth	;add for the start of the next line.
	loop	backwardScanLoop		;do # lines times.
	cld
	pop	si
		;dx now = # bytes of live print area.
	mov	bx,es:PS_bandBWidth
	sub	bx,es:PS_intWidth	;bx now = # of leading blank bytes.
	mov	es:PS_intWidth,dx	;intWidth now = live print width.
;------------------------------------------------------------------------------
;	Send a bitmap (swath)
;	dx	- number of bytes wide to send.
;	bx	- number of leading zero bytes.
;------------------------------------------------------------------------------
		;send control code to send graphics.
	mov	ax,dx
	mov	cl,3
	sal	ax,cl			;8 bits/byte.
	mov	cx,ax			;get in cx for counter later.
;SEND GRAPHICS CONTROL CODE GOES HERE.
	push	si
	mov	si,offset cs:pr_codes_SetMedGraphics
	cmp	es:PS_mode,PM_GRAPHICS_MED_RES
	je	modeOK
	mov	si,offset cs:pr_codes_SetHiGraphics
modeOK:
	call	SendCodeOut
	pop	si
	jc	carryStage2	;pass any error out.
	call	PrintStreamWriteByte
	jc	carryStage2	;pass any error out.
	mov	cl,ch
	call	PrintStreamWriteByte
carryStage2:
	jc	exit

;negate the bitmap.
;	ds:si	- input bitmap data source (beginning of bitmap)
;	bx	- number of leading zero bytes.
	add	si,bx		;get start of bitmap to start of live area.
	push	si		;save start of live print area.
	mov	cx,es:PS_bandHeight ;number of lines to negate.
negOuterLoop:
	DoPush	cx,si,es
	mov	cx,es:PS_intWidth ;get live print width.
	segmov	es,ds,di	;copy ds into es.
	mov	di,si		;get source and destination to the same byte.
negLoop:
	lodsb			;get data,
	not	al		;invert data,
	stosb			;and put back in string.
	loop	negLoop
	DoPopRV	cx,si,es
	add	si,es:PS_bandBWidth ;get to next line beginning of data.
	loop	negOuterLoop
	pop	si		;si --> start of live print area.


;send the negated bitmap out
;	ds:si	- input bitmap data source (beginning of live print area)
	mov	es, bp			;get es --> PSTATE
	mov	cx,es:PS_bandHeight ;number of lines to negate.
sendOuterLoop:
	DoPush	cx,si
	mov	cx,es:PS_intWidth ;get live print width.
	call	PrintStreamWrite	;send them out.
	DoPopRV	cx,si
	jc	exit
	add	si,es:PS_bandBWidth ;get to next line beginning of data.
	loop	sendOuterLoop

;------------------------------------------------------------------------------
;	Do not do vertical cursor movement for the start of next bitmap (swath)
;------------------------------------------------------------------------------
;	mov	ax,es:PS_bandHeight
;adjust ax for the resolution, add it to the cursor position for next time.
;	call	AdjustForResolution
;	mov	dx,ax
;	call	PrLineFeed
;------------------------------------------------------------------------------
	; some transmission error. cleanup and exit
exit:
	.leave
	ret
PrSendRasterGraphicsOld	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust ax from whatever resolution we're in to dots (1/360").

CALLED BY:	GLOBAL

PASS:		es	- PState segment
		ax	- number to be adjusted.

RETURN:		ax adjusted for the resolution.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustForResolution	proc	near
	push	cx
	mov	cl,es:[PS_mode]
EC<	cmp	cl,PM_GRAPHICS_HI_RES					>
EC<	ERROR_A	INVALID_MODE						>
	cmp	cl,PM_GRAPHICS_HI_RES
	je	adjustedForRes
	sal	ax,1			;x2 dots for 180dpi
	cmp	cl,PM_GRAPHICS_MED_RES		
	je	adjustedForRes
	mov	cx,ax			;x2 + x4 for 60 dpi
	sal	ax,1			
	add	ax,cx
adjustedForRes:
	pop	cx
	ret
AdjustForResolution	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintLoBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prints a lo resolution band.

CALLED BY:
	PrPrintABand

PASS:
	dx	- number of columns to print.
	ds:si	- pointer to bitmap data
	bp	- PState segment
	es	- output buffer

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

PrPrintLoBuffer	proc	near
	mov	cx,ds			;save input seg.
	mov	ds,bp			;get PSTATE seg.
	mov	bx,ds:PS_bandBWidth		;and the total possible.
	mov	ds,cx			;recover the input seg.
	mov	cl,3			;divide by 8
	shr	dx,cl
	sub	bx,dx			;subtract number of full bytes wide
					;from total bytes wide.
	
	; loop on one 8-scan line high band of the input bitmap

	mov	cl,LO_RES_BAND_HEIGHT	;8 scan lines high.
	xor	ch,ch
bandHeightLoop:
	push	cx
	mov	cx,dx			;get printed byte width.
	mov	di,offset GB_printBuffer

	; loop on one scan line width of the input bitmap

scanLineLoop:
	push	cx			;save the byte width.
	lodsb				;get a horizontal byte.
	not	al			;switch 1s and 0s.
	xor	ch,ch

	; loop on a single byte of the input bitmap

	mov	cl,8
scanByteLoop:
	rcl	al,1			;get a bit off the source byte.
	rcl	{byte} es:[di],1	;rotate into the output buffer.
	inc	di			;point at next byte.
	loop	scanByteLoop		;do 8 bytes.

	pop	cx			;recover the byte width of scanline.
	loop	scanLineLoop		;do Columns>>3 times.
	add	si,bx			;add to get to beginning of next line.
	pop	cx			;recover this count.
	loop	bandHeightLoop		;do 8 scan lines.
	
	mov	si,offset pr_codes_SetLoGraphics
	mov	di,offset GB_printBuffer ;beginning of buffer.
	call	PrOutPrintBuffer	;send this line.
exit:
	ret
PrPrintLoBuffer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrOutPrintBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sends the output buffer to the port.
	tests the buffer again for blank trailing space.

CALLED BY:	
	PrPrintABand

PASS:		bp	- PState segment
		si	- pointer to set graphics control codes.
		di	- pointer to the data to send.
		es	- output buffer
		GB_columns - number of columns that we are going to print.

RETURN:		carry	- set if some transmission error

DESTROYED:	ax,cx,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrOutPrintBuffer	proc	near
	uses	ax,bx,cx,di,es,ds
	.enter
	mov	bx,di			;save the pointer to the beginning of the buffer.
;si must be preserved to this point.
	call	SendCodeOut		;send the graphics controlcode.
	jc	exit			;pass out any error.
	segmov	ds,es,cx
	mov	cx,es:GB_columns
	mov	es, bp
;at this point cx should have the scanned column count.
	mov	di,cx	
	call	PrintStreamWriteByte
	jc	exit			;pass out any error.
	mov	cl,ch			;get hi byte of data length
	call	PrintStreamWriteByte
	jc	exit			;pass out any error.
	mov	cx,di			;buffer length.
	cmp	es:[PS_mode],PM_GRAPHICS_LOW_RES ;see if lo res. printing.
	je	cxOK			;if so, skip.
	shl	cx,1			;x2
	add	cx,di			;+1 = (x3)	
cxOK:
	mov	si,bx			;recover the pointer to beginning.
	call	PrintStreamWrite	;send them out.
	jc	exit
justreturn:
	mov	es, bp
	mov	cl,C_CR			;do carriage return
	call	PrintStreamWriteByte	;send it out.
exit:
	.leave
	ret
PrOutPrintBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrMakeGraphicBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Looks at the PSTATE to find out what graphics resolution this document
is printing at.  The routine then allocates a chunk of memory for a output
buffer for the graphic print routines.

CALLED BY:
	StartPrint

PASS:
	ds:si	- Start of bitmap structure.
	es	- Segment of PSTATE

RETURN:
	PSTATE loaded with handle and segment of buffer

DESTROYED:
	ax,bx,cx,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrMakeGraphicBuffer	proc	near
	cmp	es:PS_mode,PM_GRAPHICS_LOW_RES
	jne	exit
	mov	ax,es:[PS_bandWidth]	;get the x dimension of the bitmap.
	mov	cl, es:[PS_byteColumn]  ;get #bytes/column for band height
	clr	ch
	mul	cx			; ax = buffer size needed
	add	ax,ADDITIONAL_BUFFER_BYTES ;add the column count word to size
	mov	cx,ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE ;mem flags
	call	MemAlloc	;allocate a buffer in memory.
	mov	es:[PS_bufHan],bx	;store handle in PSTATE.
	mov	es:[PS_bufSeg],ax	;store the segment in PSTATE.
exit:
	ret
PrMakeGraphicBuffer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrDestroyGraphicBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Get rid of the buffer space used for the print buffer.

CALLED BY:
	PrintSwath

PASS:
	es	- Segment of PSTATE

RETURN:
	nothing

DESTROYED:
	bx,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrDestroyGraphicBuffer	proc	near
	cmp	es:PS_mode,PM_GRAPHICS_LOW_RES
	jne	exit
	mov	bx,es:[PS_bufHan]	;get handle from PSTATE.
	call	MemFree		;discard the block of memory.
exit:
	ret
PrDestroyGraphicBuffer	endp

