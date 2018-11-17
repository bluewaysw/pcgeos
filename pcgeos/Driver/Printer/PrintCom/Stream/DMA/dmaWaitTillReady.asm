COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		dmaWaitTillReady.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version


DESCRIPTION:
	contains the routines to test DMA Data out in
	the Redwood devices

	$Id: dmaWaitTillReady.asm,v 1.1 97/04/18 11:49:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDMADataOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the DMA controller for printing

CALLED BY:	INTERNAL

PASS:		es	- PState segment

RETURN:		carry set on error.	

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		wait till the DMA channel is done transferring the output
		buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintWaitTillReady	proc	near
	uses	ax
	.enter
	cmp	es:[PS_redwoodSpecific].RS_initialPass,TRUE
	je	exitOK			;dont do any waiting the first time

	;now we sit here, and wait for the buffer to get transmitted.

checkEnd:
	call	StatusByteIn		;query the gate array...
        test    al,mask HST1_PBERR              ;DMA errors?
        jnz     error				;if so, exit with carry set.
        test    ah,mask HST2_PBSY               ;Print mech moving?
        jz      checkEnd			;if so, try again.
;REMOVED 3/17/94 DJD....
;	test	ah,mask HST2_PERR		;slave error?
;	jz	error                           ;if so, exit with carry set.

	clc

exit:
	.leave
	ret

error:
	stc
	jmp	exit

exitOK:
	mov	es:[PS_redwoodSpecific].RS_initialPass,FALSE
	clc
	jmp	exit

PrintWaitTillReady	endp
