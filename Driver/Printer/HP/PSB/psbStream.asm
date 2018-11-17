COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Printer Driver
FILE:		psbStream.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream

	$Id: psbStream.asm,v 1.1 97/04/18 11:52:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexToAsciiStreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a buffer to the stream

CALLED BY:	GLOBAL

PASS:		dx	- hex number

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
	uses	ax, bx, cx, dx, si, di, ds, es
convbuff local	10 dup (byte)
	mov	bx,bp		;save PSTATE segment.
	.enter
	segmov	es,ss,ax
	mov	ds,ax		;also point with ds.
	mov	ax,dx
	clr	dx		;clear the top word for kernal routine.
	mov	cx,mask UHTAF_INCLUDE_LEADING_ZEROS
	lea	di,convbuff		;point at the buffer to load.
	call	UtilHex32ToAscii	;convert the hex to ascii.
	mov	al,"0"			;scan the string for the length.
	mov	cx,10			;limit to the length of convbuff.
	repe	scasb			
	inc	cx			;adjust for true byte count.
	mov	es,bx			;get PSTATE segment.
	mov	si,di			;get buffer start
	dec	si			;adjust for post increment in scasb.
		;PASS:		es	- segment of PState
		;		ds:si	- pointer to buffer
		;		cx	- byte count
	call	PrintStreamWrite
	.leave
	ret
HexToAsciiStreamWrite endp
