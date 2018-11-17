COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamGetStatusRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/93		Initial version


DESCRIPTION:
	contains the routine to read status from the gate array in the
	Redwood devices

	$Id: streamGetStatusRedwood.asm,v 1.1 97/04/18 11:49:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StatusByteIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the status reg of the gate array.

CALLED BY:	INTERNAL

PASS:		es	- PState segment

RETURN:		carry set on error.	
		al	- state of HST1
		ah	- state of HST2

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	01/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StatusByteIn	proc	near
	uses	dx,bx
	.enter

	call	TimerGetCount
	add	ax,WATCHDOG_COUNT_INIT
	mov	es:[PS_redwoodSpecific].RS_watchDogCount,ax

testLoop:
        mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
        add     dx,HST2         ;point at status reg.
	in	al,dx		;read status byte.
	mov	ah,al		;stuff up in hi byte.

        mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
        add     dx,HST1         ;point at status reg.
        in      al,dx           ;read status byte.

	mov	bx,ax		;save the first pair of bytes in bx.

        mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
        add     dx,HST2         ;point at status reg.
        in      al,dx           ;read status byte.
        mov     ah,al           ;stuff up in hi byte.

        mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
        add     dx,HST1         ;point at status reg.
        in      al,dx           ;read status byte.

	cmp	bx,ax		;see if the reads are identical.
	je	exitOK		;if so, exit

	call	TimerGetCount
	cmp	ax,es:[PS_redwoodSpecific].RS_watchDogCount
	jne	testLoop
	stc			;set error condition
	jmp	exit

exitOK:
	clc			;set no error....

exit:
	.leave
	ret

StatusByteIn	endp
