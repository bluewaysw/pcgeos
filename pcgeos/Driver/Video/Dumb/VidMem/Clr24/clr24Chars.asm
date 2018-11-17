COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		clr24Chars.asm

AUTHOR:		Jim DeFrisco, Feb 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/21/92		Initial revision


DESCRIPTION:
	character drawing routines
		

	$Id: clr24Chars.asm,v 1.1 97/04/18 11:43:04 newdeal Exp $

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
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char1In1Out	proc	near

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		sub	di, 24
		dec	ch			; one less scan to do
		jz	done
		NextScan di			; onto next scan line
		tst	cs:[bm_scansNext]	; if zero, done
		jns	scanLoop
done:
		pop	ax
		jmp	PSL_afterDraw
Char1In1Out	endp


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
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char2In2Out	proc	near

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		sub	di, 48
		dec	ch			; one less scan to do
		jz	done
		NextScan di			; onto next scan line
		tst	cs:[bm_scansNext]	; if zero, done
		jns	scanLoop
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
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char3In3Out	proc	near

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		sub	di, 72
		dec	ch			; one less scan to do
		jz	done
		NextScan di			; onto next scan line
		tst	cs:[bm_scansNext]	; if zero, done
		jns	scanLoop
done:
		pop	ax
		jmp	PSL_afterDraw
Char3In3Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char4In4Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 4 bytes of picture data

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
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char4In4Out	proc	near

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		sub	di, 96
		dec	ch			; one less scan to do
		jz	done
		NextScan di			; onto next scan line
		tst	cs:[bm_scansNext]	; if zero, done
		jns	scanLoop
done:
		pop	ax
		jmp	PSL_afterDraw
Char4In4Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneDataByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one data byte, part of a series

CALLED BY:	INTERNAL
PASS:		ds:si	- points to byte to draw
		es:di	- points into frame buffer
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneDataByte		proc	near
		lodsb
		mov	dx, {word}cs:[currentColor].RGB_red
		mov	ah, {byte}cs:[currentColor].RGB_blue

		shl	al, 1			; test each bit (carry)
		jnc	pix6
		mov	{word}es:[di].RGB_red, dx
		mov	{byte}es:[di].RGB_blue, ah
pix6:
		jz	done			; early out
		shl	al, 1
		jnc	pix5
		mov	{word}es:[di+3].RGB_red, dx
		mov	{byte}es:[di+3].RGB_blue, ah
pix5:
		jz	done
		shl	al, 1
		jnc	pix4
		mov	{word}es:[di+6].RGB_red, dx
		mov	{byte}es:[di+6].RGB_blue, ah
pix4:
		jz	done
		shl	al, 1
		jnc	pix3
		mov	{word}es:[di+9].RGB_red, dx
		mov	{byte}es:[di+9].RGB_blue, ah
pix3:
		jz	done
		shl	al, 1
		jnc	pix2
		mov	{word}es:[di+12].RGB_red, dx
		mov	{byte}es:[di+12].RGB_blue, ah
pix2:
		jz	done
		shl	al, 1
		jnc	pix1
		mov	{word}es:[di+15].RGB_red, dx
		mov	{byte}es:[di+15].RGB_blue, ah
pix1:
		jz	done
		shl	al, 1
		jnc	pix0
		mov	{word}es:[di+18].RGB_red, dx
		mov	{byte}es:[di+18].RGB_blue, ah
pix0:
		jz	done
		shl	al, 1
		jnc	done
		mov	{word}es:[di+21].RGB_red, dx
		mov	{byte}es:[di+21].RGB_blue, ah
done:
		add	di, 24
		ret
DrawOneDataByte		endp
