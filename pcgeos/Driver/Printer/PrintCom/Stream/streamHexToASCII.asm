COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamHexToASCII.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream

	$Id: streamHexToASCII.asm,v 1.1 97/04/18 11:49:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexToAsciiStreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a ASCII - Hex number (16bit) to the stream

CALLED BY:	GLOBAL

PASS:		ax	- hex number
		es	- PState segment.

RETURN:		carry	- set if not all bytes were written (some transmission
			  error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HexToAsciiStreamWrite proc	near
	uses	ax, bx, cx, dx, si, ds
convbuff local	5 dup (byte)
	.enter
	segmov	ds,ss,dx
	lea	si,convbuff		;point at the buffer to load.
	; First convert the number to characters, storing each on the stack
	;
	clr	cx				;initialize character count
	mov	bx, 10				;print in base ten
nextDigit:
	clr	dx				;initialize High word fro div
	div	bx
	add	dl, '0'				;convert to ASCII
	push	dx				;save character
	inc	cx				;add to character count.
	or	ax, ax				;check if done
	jnz	nextDigit			;if not, do next digit

		;cx is the byte count (digit count)

		; Now pop the characters into convbuff, one-by-one
	mov	bx,si				;save ea of convbuff
	mov	dx, cx				;dx = character count
nextChar:
	pop	ax				;retrieve character
	mov	ds:[si],al			;store to buffer
	inc	si
	loop	nextChar			;loop to print all

	mov	cx, dx				;cx = character count
	mov	si,bx				;si = ea of convbuff
		;PASS:		es	- segment of PState
		;		ds:si	- pointer to buffer
		;		cx	- byte count
	call	PrintStreamWrite
	.leave
	ret
HexToAsciiStreamWrite endp
