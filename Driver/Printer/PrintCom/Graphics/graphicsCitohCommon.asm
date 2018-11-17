
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CItoh print drivers
FILE:		graphicsCitohCommon.asm

AUTHOR:		Dave Durran 23 March 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/23/92		Initial revision


DESCRIPTION:
	This file consists of the common graphics routines for all the CItoh
	type print drivers.

	$Id: graphicsCitohCommon.asm,v 1.1 97/04/18 11:51:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendGraphicControlCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the actual graphics control code, and byte count.

CALLED BY:	INTERNAL

PASS:		si	- pointer to control code in Code Seg.
		cx	- column width to print.
		es	- segment of PSTATE

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendGraphicControlCode	proc	near
	uses	ax,cx
	.enter
	call	SendCodeOut		;send control code pointed at cs:si.
	jc	exit
	mov	ax,cx			;send the ASCII width.
	mov	cx,4			;4 digits
	call	HexToAsciiStreamWrite	;send 'em.
exit:
	.leave
	ret
PrSendGraphicControlCode	endp
