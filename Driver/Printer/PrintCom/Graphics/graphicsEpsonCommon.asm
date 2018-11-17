
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson print drivers
FILE:		graphicsEpsonCommon.asm

AUTHOR:		Dave Durran 23 March 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/23/92		Initial revision


DESCRIPTION:
	This file consists of the common graphics routines for all the Epson
	type print drivers.

	$Id: graphicsEpsonCommon.asm,v 1.1 97/04/18 11:51:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendGraphicControlCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the actiual graphics control code, and byte count.

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
	uses	cx
	.enter
	call	SendCodeOut		;send control code pointed at cs:si.
	jc	exit
	call	PrintStreamWriteByte	;send low byte.
	jc	exit
	mov	cl,ch			;send high byte
	call	PrintStreamWriteByte
exit:
	.leave
	ret
PrSendGraphicControlCode	endp
