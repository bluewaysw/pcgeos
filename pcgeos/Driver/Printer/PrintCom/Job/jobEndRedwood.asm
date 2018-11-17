
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobEndRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	11/92		Initial revision


DESCRIPTION:
		

	$Id: jobEndRedwood.asm,v 1.1 97/04/18 11:51:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post-job cleanup

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndJob	proc	far
	uses	es,bx,dx,di
	.enter
	mov	es,bp		; es--->PState
if 0
	mov	bx,es:[PS_redwoodSpecific].[RS_DMAHandle]
	tst	bx
	jz	exit			;if no DMA driver loaded yet, exit.
	mov     dl, REDWOOD_DMA_CHANNEL_MASK
        mov     di, DR_RELEASE_CHANNEL	;free up this channel.
        INT_OFF
        call    es:[PS_redwoodSpecific].[RS_DMADriver] ;free up this channel.
        INT_ON
	call	GeodeFreeDriver
endif
exit:
	clc			; no problems
	.leave
	ret
PrintEndJob	endp

