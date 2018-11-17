COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Chars.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92	Initial revision

DESCRIPTION:
	
	$Id: vga8Chars.asm,v 1.1 97/04/18 11:42:03 newdeal Exp $

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

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>

		; do next scan.  Load data byte and go for it.
scanLoop:
		lodsb
		mov	ah, al			; save data byte in al
		mov	al, cs:[currentColor]	; get current draw color
		shl	ah, 1			; test each bit (carry)
		jnc	pix6
		mov	es:[di], al
pix6:
		jz	nextScan		; early out
		shl	ah, 1
		jnc	pix5
		mov	es:[di+1], al
pix5:
		jz	nextScan
		shl	ah, 1
		jnc	pix4
		mov	es:[di+2], al
pix4:
		jz	nextScan
		shl	ah, 1
		jnc	pix3
		mov	es:[di+3], al
pix3:
		jz	nextScan
		shl	ah, 1
		jnc	pix2
		mov	es:[di+4], al
pix2:
		jz	nextScan
		shl	ah, 1
		jnc	pix1
		mov	es:[di+5], al
pix1:
		jz	nextScan
		shl	ah, 1
		jnc	pix0
		mov	es:[di+6], al
pix0:
		jz	nextScan
		shl	ah, 1
		jnc	nextScan
		mov	es:[di+7], al
nextScan:
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp						>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
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
		al	- color to draw with
RETURN:		nothing
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneDataByte		proc	near
		mov	ah, ds:[si]			; save data byte in al
		inc	si
		shl	ah, 1			; test each bit (carry)
		jnc	pix6
		mov	es:[di], al
pix6:
		jz	nextScan		; early out
		shl	ah, 1
		jnc	pix5
		mov	es:[di+1], al
pix5:
		jz	nextScan
		shl	ah, 1
		jnc	pix4
		mov	es:[di+2], al
pix4:
		jz	nextScan
		shl	ah, 1
		jnc	pix3
		mov	es:[di+3], al
pix3:
		jz	nextScan
		shl	ah, 1
		jnc	pix2
		mov	es:[di+4], al
pix2:
		jz	nextScan
		shl	ah, 1
		jnc	pix1
		mov	es:[di+5], al
pix1:
		jz	nextScan
		shl	ah, 1
		jnc	pix0
		mov	es:[di+6], al
pix0:
		jz	nextScan
		shl	ah, 1
		jnc	nextScan
		mov	es:[di+7], al
nextScan:
		ret
DrawOneDataByte		endp


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

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		mov	al, cs:[currentColor]	; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		sub	di, 8
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
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

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		mov	al, cs:[currentColor]	; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		sub	di, 16
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
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

NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
		mov	al, cs:[currentColor]	; get current draw color

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		add	di, 8
		call	DrawOneDataByte
		sub	di, 24
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
		pop	ax
		jmp	PSL_afterDraw
Char4In4Out	endp
