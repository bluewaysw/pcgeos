COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamSendCodeOut.asm

AUTHOR:		Jim DeFrisco, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	5/92		Parsed from printcomStream.asm


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream

	$Id: streamSendCodeOut.asm,v 1.1 97/04/18 11:49:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCodeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a string of bytes, which are preceded by a byte count

CALLED BY:	INTERNAL
		(All the style setting/resetting routines)

PASS:		es	- PState segment
		cs:si	- pointer to string

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

SendCodeOut	proc	near
		uses	ds, ax, cx
		.enter
	        segmov  ds, cs, ax	;get our segment.
		lodsb           	;get the byte count, and increment si.
		mov     cl,al   	;byte count to cx
		clr     ch 	  	;zero the high byte.
		clc			;init the carry flag.
		jcxz	exit		;if the byte count is zero, exit now.
		call    PrintStreamWrite
exit:
		.leave
		ret
SendCodeOut	endp
