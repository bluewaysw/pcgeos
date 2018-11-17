COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamControlByteOutRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/93		Initial version


DESCRIPTION:
	contains the routines to write commands to the gate array in the
	Redwood devices

	$Id: streamControlByteOutRedwood.asm,v 1.1 97/04/18 11:49:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ControlByteOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a control code byte.

CALLED BY:	INTERNAL

PASS:		es	- PState segment
		al	- byte to send out.

RETURN:		carry clear	

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	01/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ControlByteOut	proc	near
	uses	ax,bx,dx
	.enter

	mov	ah,al
	mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add     dx,HST1         ;point at status reg.

	push	ax
	call	TimerGetCount		;ax --> low word of count.
 	add	ax,WATCHDOG_COUNT_INIT	;add standard wait time.
        mov     es:[PS_redwoodSpecific].RS_watchDogCount,ax
	pop	ax

testLoop:
	call	HardwareDelayLoop
        in      al,dx           ;get the status byte.
        test    al,mask HST1_HDBSY ;see if ready for data.
        jz      tested
	push	ax
	call    TimerGetCount           ;ax --> low word of count.
        cmp     ax,es:[PS_redwoodSpecific].RS_watchDogCount
	pop	ax
        je      error
	jmp	testLoop
tested:
				;point back at data reg.
	mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase	
	mov	al,ah			;get the byte of data
	call	HardwareDelayLoop
	out	dx,al		;stuff the data reg.
	clc
exit:
	.leave
	ret
error:
	stc
	jmp	exit
ControlByteOut	endp
