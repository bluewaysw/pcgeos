COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferLoadBandNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/94	initial version

DESCRIPTION:

	$Id: bufferLoadBandNike.asm,v 1.1 97/04/18 11:50:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PrLoadMonoBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a block transfer of the bytes from the Huge Array block
		to our memory. This allows us to build out a buffer one
		whole band high.

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer into bitmap data from Huge Array.
		es:[PS_curScanNumber]	- number of the scanline to last used
		es:[PS_newScanNumber]	- number of the scanline to use
		es	- segment of PSTATE
		BandVariables loaded on stack

RETURN:		
		ds:si	- adjusted to after the band in question

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLoadMonoBandBuffer	proc	near
	uses	ax,bx,cx,dx,di
curBand local   BandVariables
	.enter inherit
	mov	bx,es:[PS_bandBWidth]	;width of the band.
	clr	ch
	mov	cl,curBand.BV_scanlines	;do curBand.BV_scanlines lines high.
	mov	di,offset GPB_bandBuffer	;destination offset.
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
	inc	ax
	mov	es:[PS_newScanNumber],ax
	loop	scanlineLoop
	.leave
	ret
PrLoadMonoBandBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadColorBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a block transfer of the bytes from the Huge Array block
		to our memory. This allows us to build out a buffer one
		whole band high.

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer into bitmap data from Huge Array.
		es:[PS_curScanNumber]	- number of the scanline last used
		es:[PS_newScanNumber]	- number of the scanline to use
		es	- segment of PSTATE
		BandVariables loaded on stack

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLoadColorBandBuffer	proc	near
curBand local   BandVariables
	uses	ax,bx,cx,dx,si,di
	.enter inherit

	push	es:[PS_newScanNumber]		;save current scanline #
	mov	di, offset GPB_bandBuffer	;es:di <- yellow band offset
	call	PrLoadYellowBands
	pop	es:[PS_newScanNumber]		;restore current scanline #

	push	es:[PS_newScanNumber]		;save current scanline #
	mov	ax, es:[PS_bandHeight]
	mul	es:[PS_bandBWidth]		;width of the band.
	add	ax, offset GPB_bandBuffer
	mov	di, ax				;es:di <- magenta band offset
	call	PrLoadMagentaBands
	pop	es:[PS_newScanNumber]		;restore current scanline #

	mov	ax, es:[PS_bandHeight]
	shl	ax				;ax <- PS_bandHeight * 2
	mul	es:[PS_bandBWidth]		;width of the band.
	add	ax, offset GPB_bandBuffer
	mov	di, ax				;es:di <- magenta band offset
	call	PrLoadCyanBands

	.leave
	ret
PrLoadColorBandBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadYellowBands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load yellow bands

CALLED BY:	PrLoadColorBandBuffer
PASS:		ds:si	- pointer into bitmap data from Huge Array.
		di	- band buffer offset
		es	- segment of PSTATE
		es:[PS_curScanNumber]	- number of the scanline last used
		es:[PS_newScanNumber]	- number of the scanline to use
		BandVariables loaded on stack
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLoadYellowBands	proc	near
curBand local   BandVariables
	.enter inherit

	tst	es:[PS_dWP_Specific].DWPS_finishColor
	jnz	done

	mov	es:[PS_curColorNumber], 0	;set up CMY color (YELLOW)
	mov	cx, es:[PS_bandBWidth]		;width of the band.
	mov	bl, curBand.BV_scanlines

yellowScanlineLoop:
	call	DerefAScanline		;ds:si <- yellow scanline

	push	es, cx			;save the PState address.
	mov	es, es:[PS_bufSeg]	;destination segment
	shr	cx, 1			;use words, they're faster.
	jnc	words			;if not odd bytes, go to move words.
	movsb				;if so, send the odd byte now.
words:	rep	movsw			;transfer the data to the Band Buffer.
	pop	es, cx			;recover the PState segment address.

	inc	es:[PS_newScanNumber]
	dec	bl
	jnz	yellowScanlineLoop
done:
	.leave
	ret
PrLoadYellowBands	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadMagentaBands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load magenta bands

CALLED BY:	PrLoadColorBandBuffer
PASS:		ds:si	- pointer into bitmap data from Huge Array.
		di	- band buffer offset
		es	- segment of PSTATE
		es:[PS_curScanNumber]	- number of the scanline last used
		es:[PS_newScanNumber]	- number of the scanline to use
		BandVariables loaded on stack
RETURN:		di	- updated
DESTROYED:	ax,bx,cx,dx,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLoadMagentaBands	proc	near
curBand local   BandVariables
	.enter inherit

	clr	ax
	mov	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]	;width of the band.
	mov	cx, ax			;cx <- number of bytes to move

	push	ds, es
	mov	ds, es:[PS_dWP_Specific].DWPS_buffer2Segment
	clr	si
	mov	es, es:[PS_bufSeg]	;destination segment
	shr	cx, 1
	jnc	words
	movsb
words:	rep	movsw
	pop	ds, es

	; Now update the history buffer

	mov	ax, PRINT_HEAD_OFFSET_TO_MAGENTA
	test	es:[printOptions], mask PPO_150X150
	jz	10$
	shr	ax, 1
10$:
	sub	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]
	mov	cx, ax			;cx <- number of bytes to move

	push	ds, es
	mov	ax, es:[PS_dWP_Specific].DWPS_buffer2Segment
	mov	ds, ax
	mov	es, ax
	clr	di
	shr	cx, 1
	jnc	words2
	movsb				;move remaining bytes from end
words2:	rep	movsw			; of buffer to the front
	pop	ds, es

	; Are we finishing off color printing???

	tst	es:[PS_dWP_Specific].DWPS_finishColor
	jz	copyMagenta

	; We're finishing off color printing, just fill history buffer with 0's

	clr	ax
	mov	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]
	mov	cx, ax			;cx <- number of bytes to fill

	push	es
	mov	es, es:[PS_dWP_Specific].DWPS_buffer2Segment
	clr	ax
	shr	cx, 1
	jnc	words3
	stosb
words3:	rep	stosw
	pop	es
	jmp	done

	; Copy magenta scanlines from bitmap to history buffer
copyMagenta:
	mov	es:[PS_curColorNumber], 2	;set up CMY color (MAGENTA)
	mov	cx, es:[PS_bandBWidth]		;width of the band.
	mov	bl, curBand.BV_scanlines

magentaScanlineLoop:
	call	DerefAScanline		;ds:si <- magenta scanline

	push	es, cx			;save the PState address.
	mov	es, es:[PS_dWP_Specific].DWPS_buffer2Segment
	shr	cx, 1			;use words, they're faster.
	jnc	words4			;if not odd bytes, go do words.
	movsb				;if so, send the odd byte now.
words4:	rep	movsw			;transfer the data to the Band Buffer.
	pop	es, cx			;recover the PState segment address.

	inc	es:[PS_newScanNumber]
	dec	bl
	jnz	magentaScanlineLoop
done:
	.leave
	ret
PrLoadMagentaBands	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLoadCyanBands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load cyan bands

CALLED BY:	PrLoadColorBandBuffer
PASS:		ds:si	- pointer into bitmap data from Huge Array.
		di	- band buffer offset
		es	- segment of PSTATE
		es:[PS_curScanNumber]	- number of the scanline last used
		es:[PS_newScanNumber]	- number of the scanline to use
		BandVariables loaded on stack
RETURN:		di	- updated
DESTROYED:	ax,bx,cx,dx,si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLoadCyanBands	proc	near
curBand local   BandVariables
	.enter inherit

	mov	ax, PRINT_HEAD_OFFSET_TO_MAGENTA
	test	es:[printOptions], mask PPO_150X150
	jz	10$
	shr	ax, 1
10$:
	mul	es:[PS_bandBWidth]	;width of the band.
	mov	si, ax			;si <- offset cyan history buffer

	clr	ax
	mov	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]	;width of the band.
	mov	cx, ax			;cx <- number of bytes to move

	push	si, ds, es
	mov	ds, es:[PS_dWP_Specific].DWPS_buffer2Segment
	mov	es, es:[PS_bufSeg]	;destination segment
	shr	cx, 1
	jnc	words
	movsb
words:	rep	movsw
	pop	di, ds, es

	; Now update the history buffer

	mov	ax, PRINT_HEAD_OFFSET_TO_CYAN
	test	es:[printOptions], mask PPO_150X150
	jz	20$
	shr	ax, 1
20$:
	sub	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]
	mov	cx, ax			;cx <- number of bytes to move

	push	ds, es
	mov	ax, es:[PS_dWP_Specific].DWPS_buffer2Segment
	mov	ds, ax
	mov	es, ax
	shr	cx, 1
	jnc	words2
	movsb				;move remaining bytes from end
words2:	rep	movsw			; of buffer to the front
	pop	ds, es

	; Are we finishing off color printing???

	tst	es:[PS_dWP_Specific].DWPS_finishColor
	jz	copyCyan

	; We're finishing off color printing, just fill history buffer with 0's

	clr	ax
	mov	al, curBand.BV_scanlines
	mul	es:[PS_bandBWidth]
	mov	cx, ax			;cx <- number of bytes to fill

	push	es
	mov	es, es:[PS_dWP_Specific].DWPS_buffer2Segment
	clr	ax
	shr	cx, 1
	jnc	words3
	stosb
words3:	rep	stosw
	pop	es
	jmp	done

	; Copy cyan scanlines from bitmap to history buffer
copyCyan:
	mov	es:[PS_curColorNumber], 1	;set up CMY color (CYAN)
	mov	cx, es:[PS_bandBWidth]	;width of the band.
	mov	bl, curBand.BV_scanlines

cyanScanlineLoop:
	call	DerefAScanline		;ds:si <- cyan scanline

	push	es, cx			;save the PState address.
	mov	es, es:[PS_dWP_Specific].DWPS_buffer2Segment
	shr	cx, 1			;use words, they're faster.
	jnc	words4			;if not odd bytes, go do words.
	movsb				;if so, send the odd byte now.
words4:	rep	movsw			;transfer the data to the Band Buffer.
	pop	es, cx			;recover the PState segment address.

	inc	es:[PS_newScanNumber]
	dec	bl
	jnz	cyanScanlineLoop
done:
	.leave
	ret
PrLoadCyanBands	endp
