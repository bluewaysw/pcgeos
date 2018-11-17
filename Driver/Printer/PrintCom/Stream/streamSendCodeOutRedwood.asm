COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamSendCodeOutRedwood.asm

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

	$Id: streamSendCodeOutRedwood.asm,v 1.1 97/04/18 11:49:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCodeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a string of bytes, which are preceded by a byte count

CALLED BY:	INTERNAL

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
	Dave	01/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendCodeOut	proc	near
	uses	ds, ax, bx, cx, dx, si
	.enter
	mov	dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add	dx,HST1		;point at status reg.
				;init watchdog count
	call	TimerGetCount
        add	ax,WATCHDOG_COUNT_INIT
        mov     es:[PS_redwoodSpecific].RS_watchDogCount,ax

testAgain:
	call	HardwareDelayLoop
	in	al,dx		;get the status byte.
	test	al,mask HST1_HDBSY ;see if ready for data.
	jz	tested1

	call	TimerGetCount
        cmp     ax,es:[PS_redwoodSpecific].RS_watchDogCount
	je	error
	jmp	testAgain

tested1:
	clr	al		;clear the command reg.
	mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add	dx,HCM1
	call	HardwareDelayLoop
	out	dx,al		;The length is coming to HCD
	segmov  ds, cs, ax	;get our segment.
	lodsb           	;get the byte count, and increment si.
	mov	cl,al		;get count of data.
	clr	ch
	jmp	sendByte

		;cx is also the length of the command
dataLoop:
	add     dx,HST1         ;point at status reg.
				;init watchdog count
	call	TimerGetCount
        add     ax,WATCHDOG_COUNT_INIT 
        mov     es:[PS_redwoodSpecific].RS_watchDogCount,ax 

testLoop:
	call	HardwareDelayLoop
        in      al,dx           ;get the status byte.
        test    al,mask HST1_HDBSY ;see if ready for data.
        jz      sendByte

	call    TimerGetCount
	cmp	ax,es:[PS_redwoodSpecific].RS_watchDogCount
	je	error
        jmp     testLoop

sendByte: 			;point back at data reg.
	mov     dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	lodsb			;get a byte of data from pr_codes
	call	HardwareDelayLoop
	out	dx,al		;stuff the data reg.
	loop	dataLoop	;do again, if more.

noErrors:
	clc

exit:
	.leave
	ret

error:
	stc
	jmp	exit
SendCodeOut	endp

HardwareDelayLoop	proc	near
        push    ax, cx
        mov     ax, 100
        mov     cx, 200
delay:
        mul     cl
        loop    delay
        pop     ax, cx
	ret
HardwareDelayLoop	endp
