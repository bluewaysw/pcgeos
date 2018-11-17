COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamSendASCIICode2Part.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/1/92		Initial revision


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream

	$Id: streamSendASCIICode2Part.asm,v 1.1 97/04/18 11:49:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendASCIICode2Part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a string of bytes, which are preceded by a byte count
		on either side of an ascii argument byte.

CALLED BY:	INTERNAL
		(All the style setting/resetting routines)

PASS:		es	- PState segment
		cs:si	- pointer to string
		ax	- argument to send.

RETURN:		carry	- set if some error writing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendASCIICode2Part	proc	near
		uses	ds, ax, cx
		.enter
	push	si		;save the index to the control codes
	call	SendCodeOut	;send the first half of the code.
	pop	si		;recover the pointer to the first half.
	jc	exit		;pass errors out.
	add	si,cx		;adjust for the second half
				;(depends on PrintStreamWrite passing back
				;cx as the number of bytes written out)

				;send the argument passed in ax out.
	call	HexToAsciiStreamWrite
	jc	exit		;pass errors out.

	call	SendCodeOut	;send the second half of the control code.
exit:
		.leave
		ret
SendASCIICode2Part	endp
