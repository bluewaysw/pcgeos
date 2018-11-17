COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NIKE 56-pin print drivers
FILE:		graphicsHiNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial revision


DESCRIPTION:

	$Id: graphicsHiNike.asm,v 1.1 97/04/18 11:51:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrPrintHighBand PrPrintHighMonoBand PrPrintHighColorBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Used to print a 56 pin High resolution band. (non-interleaved)
	Used to print a 300dpi resolution band.

CALLED BY:
	PrPrintABand

PASS:
	PS_newScanNumber pointing at top of this band
	es	=	segment of PState
	dx	=	number of scanlines hi to load and print.

RETURN:
	carry set on error

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/16/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrPrintHighBand	proc	near
	push	ax
	mov	al, es:[PS_swath].B_type
	andnf	al, mask PT_COLOR

EC <	cmp	al, BMF_MONO						>
EC <	je	bmTypeOK						>
EC <	cmp	al, BMF_3CMY						>
EC <	ERROR_NE -1			; must be mono or cmy		>
EC <bmTypeOK:								>

	cmp	al, BMF_MONO
	pop	ax
	je	doMono

	jmp	PrPrintHighColorBand

doMono:
	FALL_THRU	PrPrintHighMonoBand
PrPrintHighBand	endp


PrPrintHighMonoBand	proc	near
	uses	ax,bx,cx,dx,es,di,si
curBand	local	BandVariables
	.enter

		; Set printer options based on PrinterMode
	mov	al, es:[printOptions]
	and	al, not (mask PPO_150X150+mask PPO_UNI_DIR+mask PPO_SHINGLING)
	cmp	es:[PS_mode], PM_GRAPHICS_HI_RES
	je	noMagnify
	ornf	al, mask PPO_150X150		;150x150 magnified to 300x300
noMagnify:
	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
	je	bidirectional
	ornf	al, mask PPO_UNI_DIR		;uni-directional printing
bidirectional:
	mov	es:[printOptions], al	;save print options

	mov	curBand.BV_scanlines,dl
	mov	ax,es:[PS_newScanNumber] ;set the band start for this band.
	mov	curBand.BV_bandStart,ax

	call	PrClearBandBuffer	;zero the buffer.
	call	PrLoadMonoBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx			;cl = lo byte count value.
	jcxz	exitOK			;if no data, just exit.
	call	PrCompressBandBuffer	;move the data to the left edge.

	push	ds
	push	es

	mov	ds,es:[PS_bufSeg]

	push	bp
	clr	ax
	mov	al, es:[printOptions]
	and	al, mask PPO_150X150
	mov	cl, offset PPO_150X150
	shr	al, cl
	mov	bp, ax
	jz	shift
	shl	ds:GPB_startColumn
	shl	ds:GPB_endColumn
	inc	ds:GPB_endColumn
	shl	ds:GPB_columnsWide
	shl	ds:GPB_bytesWide

shift:		;Shift everything 1/4" to the right if paper is <= 8.5"
	cmp	es:[PS_customWidth], 264h		; 264h = 8.5*72
	ja	rotate

	add	ds:GPB_startColumn, 75	;1/4" at 300dpi
	add	ds:GPB_endColumn, 75	;1/4" at 300dpi

		;Call the printer BIOS to rotate this buffer into the new 
rotate:		;"rotate buffer".
	mov	dx,ds			;loaded bandbuffer into dx:si
	clr	si			;buffer memory start.
	mov	di,si			;same for the new rotate buffer.
	mov	es,es:[PS_dWP_Specific].DWPS_buffer1Segment
	mov	cx,GPB_HEADER_SIZE shr 1
	rep	movsw			;copy the header to the rotate buffer.
	mov	bx,ds:GPB_startColumn	;load the starting column #
	mov	cx,ds:GPB_endColumn	;load the ending column #
	mov	ah,PB_ROTATE_MONO_IMAGE	;function number
					;di is left pointing after the header.
	int	0fah			;call the printer BIOS
	pop	bp

EC <	cmp	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>

EC <	cmp	es:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_ROTATE_BUFFER		>

		;Call the Printer BIOS to merge the "rotate buffer"
	mov	dx,es			;point at the rotate buffer w/dx:si
	mov	si,di
	mov	ah,PB_MERGE_MONO_COLUMNS
	int	0fah			;call the printer BIOS
					;bx and cx should still have columns

EC <	cmp	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>

EC <	cmp	es:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_ROTATE_BUFFER		>

	mov	ds,dx			;ds:si = rotate buffer structure
	clr	si
	pop	es
	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 0
	call	PrSendTheBand		;send the 
	pop	ds
	jc	exit			;propogate errors out.

exitOK:
	clr	dh
	mov	dl,curBand.BV_scanlines
	add	es:[PS_dWP_Specific].DWPS_yOffset,dx
	test	es:[printOptions], mask PPO_150X150
	jz	exit
	add	es:[PS_dWP_Specific].DWPS_yOffset,dx
exit:
	.leave
	ret
PrPrintHighMonoBand	endp


PrPrintHighColorBand	proc	near
	uses	ax,bx,cx,dx,es,di,si
curBand	local	BandVariables
	.enter

		; Set printer options based on PrinterMode
	mov	al, es:[printOptions]
	and	al, not (mask PPO_SHINGLING or mask PPO_150X150)
	or	al, mask PPO_UNI_DIR		;alway uni-directional in color
	cmp	es:[PS_mode], PM_GRAPHICS_HI_RES
	jne	noShingling
	ornf	al, mask PPO_SHINGLING		;4 pass shingling in hi-res
noShingling:
	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
	jne	notLowRes
	ornf	al, mask PPO_150X150		;150x150 magnified to 300x300
	jmp	saveOptions
notLowRes:
	andnf	al, not mask PPO_INK_SAVER	;ink saver off for med and hi
saveOptions:
	mov	es:[printOptions], al	;save print options

	mov	curBand.BV_scanlines,dl
	mov	ax,es:[PS_newScanNumber] ;set the band start for this band.
	mov	curBand.BV_bandStart,ax

	call	PrClearBandBuffer	;zero the buffer.
	call	PrLoadColorBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx			;cl = lo byte count value.
	jcxz	exitOK			;if no data, just exit.
	call	PrCompressBandBuffer	;move the data to the left edge.

	push	ds
	push	es

	mov	ds,es:[PS_bufSeg]

	push	bp
	test	es:[printOptions], mask PPO_150X150
	mov	bp, 0					;assume 300dpi
	jz	shift
	inc	bp					;150 dpi
	shl	ds:GPB_startColumn
	shl	ds:GPB_endColumn
	inc	ds:GPB_endColumn
	shl	ds:GPB_columnsWide
	shl	ds:GPB_bytesWide

shift:		;Shift everything 1/4" to the right if paper is <= 8.5"
	cmp	es:[PS_customWidth], 264h		; 264h = 8.5*72
	ja	rotate

	add	ds:GPB_startColumn, 75	;1/4" at 300dpi
	add	ds:GPB_endColumn, 75	;1/4" at 300dpi

		;Call the printer BIOS to rotate this buffer into the new 
rotate:		;"rotate buffer".
	mov	ds,es:[PS_bufSeg]
	mov	dx,ds			;loaded bandbuffer into dx:si
	clr	si			;buffer memory start.
	mov	di,si			;same for the new rotate buffer.
	mov	es,es:[PS_dWP_Specific].DWPS_buffer1Segment
	mov	cx,GPB_HEADER_SIZE shr 1
	rep	movsw			;copy the header to the rotate buffer.
	mov	bx,ds:GPB_startColumn	;load the starting column #
	mov	cx,ds:GPB_endColumn	;load the ending column #
	mov	ah,PB_ROTATE_COLOR_IMAGE;function number
	int	0fah			;call the printer BIOS
	pop	bp

EC <	cmp	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>

EC <	cmp	es:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_ROTATE_BUFFER		>

		;Call the Printer BIOS to merge the "rotate buffer"
	mov	dx,es			;point at the rotate buffer w/dx:si
	mov	si,di
	mov	ah,PB_MERGE_COLOR_COLUMNS
	int	0fah			;call the printer BIOS
					;bx and cx should still have columns

EC <	cmp	ds:[PRINT_OUTPUT_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_OUTPUT_BUFFER		>

EC <	cmp	es:[PRINT_ROTATE_BUFFER_SIZE], 0xadeb			>
EC <	ERROR_NE NIKE_BIOS_IS_WRITING_BEYOND_ROTATE_BUFFER		>

	mov	ds,dx			;ds:si = rotate buffer structure
	clr	si
	pop	es
	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 0
	mov	al, es:[printOptions]
	andnf	al, mask PPO_SHINGLING
	jz	onePass

	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 1
	call	PrSendTheBand		;send the band
	jc	popDS
	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 2
	call	PrSendTheBand		;send the band
	jc	popDS
	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 3
	call	PrSendTheBand		;send the band
	jc	popDS
	mov	es:[PS_dWP_Specific].DWPS_shinglingPrint, 4
onePass:
	call	PrSendTheBand		;send the band
popDS:
	pop	ds
	jc	exit			;propogate errors out.

exitOK:
	clr	dh
	mov	dl,curBand.BV_scanlines
	add	es:[PS_dWP_Specific].DWPS_yOffset,dx
	test	es:[printOptions], mask PPO_150X150
	jz	exit
	add	es:[PS_dWP_Specific].DWPS_yOffset,dx
exit:
	.leave
	ret
PrPrintHighColorBand	endp
