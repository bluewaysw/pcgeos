COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamInitDMARedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version


DESCRIPTION:
	contains the routines to write init commands to the DMA Controller in
	the Redwood devices

	$Id: streamInitDMARedwood.asm,v 1.1 97/04/18 11:49:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInitDMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the DMA controller for printing

CALLED BY:	INTERNAL

PASS:		es	- PState segment

RETURN:		carry set on error.	

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	enable DMA transfers using channel 1 in demand transfer mode.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitDMA	proc	near
	uses	dx
	.enter
		;load the DMA driver.
	call	PrintLoadDMADriver

		;set up the 8237 to do DMA on channel 1. 
	mov	dl,REDWOOD_DMA_CHANNEL_MASK
        mov     di, DR_REQUEST_CHANNEL
        INT_OFF
        call    es:[PS_redwoodSpecific].[RS_DMADriver]     ; call DMA driver
        INT_ON
        tst     dl                              ; did we get it?
        jnz     error

		;leave the chip disabled for now....
        mov     dl, REDWOOD_DMA_CHANNEL_MASK     ; dl <- channel of transfer
        mov     di, DR_DISABLE_DMA_REQUESTS
        INT_OFF
        call    es:[PS_redwoodSpecific].[RS_DMADriver] ; turn off requests
        INT_ON

	clc

exit:
	.leave
	ret

error:
	stc
	jmp	exit

PrintInitDMA	endp
