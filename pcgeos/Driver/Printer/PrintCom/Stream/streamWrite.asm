COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamWrite.asm

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

	$Id: streamWrite.asm,v 1.1 97/04/18 11:49:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a buffer to the stream

CALLED BY:	GLOBAL

PASS:		es	- segment of PState
		ds:si	- pointer to buffer
		cx	- byte count

RETURN:		carry	- set if not all bytes were written
			  (PS_error field in PState also set to 1)
		cx	- #bytes written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStreamWrite proc	near
		uses	ax, bx, di
		.enter
		mov	di, DR_STREAM_WRITE	; stream driver function #
		mov	ax, STREAM_BLOCK	; wait for it
		mov	bx, es:[PS_streamToken]	; get stream token
		call	es:[PS_streamStrategy] ; make the call
		jnc	done
		mov	es:[PS_error], 1	; set error condition
done:
		.leave
		ret
PrintStreamWrite endp
