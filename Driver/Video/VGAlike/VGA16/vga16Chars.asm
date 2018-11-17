COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vga16Chars.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92	Initial revision

DESCRIPTION:
	
	$Id: vga16Chars.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char1In1Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 1 byte of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char1In1Out	proc	near
		uses    bx
		.enter

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		sub     bp, 16
		mov     bx, cs:[currentColor]   ; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call    DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp						>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
		.leave
		pop	ax
		jmp	PSL_afterDraw
Char1In1Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneDataByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one data byte, part of a series

CALLED BY:	
PASS:		ds:si	- points to byte to draw
		es:di	- points into frame buffer
		bx	- color to draw with
RETURN:		nothing
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneDataByte proc    near
		lodsb				; save data byte in al

		mov	ah, 8
		NextScan	di, 0
		jc      maybepageDCB

nopageDCB:
		shl	al, 1			   
		jnc     nextPix
		mov     es:[di], bx		     
nextPix:
		add	di, 2
		dec	ah
		jnz	nopageDCB

		ret

maybepageDCB:
		mov     dx, cs:[pixelsLeft]
		cmp     dx, 8
		ja      nopageDCB

pageDCB:
		shl     al, 1	 
		jnc     nextPix2
		mov     es:[di], bx	
nextPix2:
		add	di, 2
		dec     dx
		jz	nextWin
loopPix:
		dec	ah
		jnz	pageDCB

		ret

nextWin:
		call	MidScanNextWin
		jmp	loopPix

DrawOneDataByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char2In2Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 2 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char2In2Out	proc	near
		uses    bx
		.enter

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		sub     bp, 32
		mov     bx, cs:[currentColor]   ; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call    DrawOneDataByte
		dec     ch		      ; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
		.leave
		pop	ax
		jmp	PSL_afterDraw
Char2In2Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char3In3Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 3 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char3In3Out	proc	near
		uses    bx
		.enter

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		sub     bp, 48
		mov     bx, cs:[currentColor]   ; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
		.leave
		pop	ax
		jmp	PSL_afterDraw
Char3In3Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char4In4Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character,4 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char4In4Out	proc	near
		uses    bx
		.enter

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		sub     bp, 64
		mov     bx, cs:[currentColor]   ; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
		.leave
		pop	ax
		jmp	PSL_afterDraw
Char4In4Out	endp
