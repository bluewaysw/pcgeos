COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		streamStatusPacketInRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/93		Initial version


DESCRIPTION:
	contains the routine to read status packets from the gate array in the
	Redwood devices

	$Id: streamStatusPacketInRedwood.asm,v 1.1 97/04/18 11:49:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StatusPacketIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the status packet requested from the Gate Array

CALLED BY:	INTERNAL

PASS:		es	- PState segment

RETURN:		carry set on error.	
		Our input buffer PS_redwoodSpecific.RS_status loaded with data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	09/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StatusPacketIn	proc	near
	uses	ax,cx,di
	.enter

getAnotherByte:
	call	GetOneStatusByte	;get a byte from the gate array.
	jc	exit
	test	ah,mask HST1_SCD	;see if it is a length byte
	jz	itsData			;if not length, skip init.
	clr	cl			;reset the byte counter
	mov     di,offset PS_redwoodSpecific.RS_status ;point at input buffer

itsData:
	stosb				;es:di is our buffer.
	inc	cl			;add one byte to our counter.
	cmp	cl,es:PS_redwoodSpecific.RS_status.RSB_length ;are we done?
	jle	getAnotherByte
	clc

exit:
	.leave
	ret
StatusPacketIn	endp

GetOneStatusByte	proc	near
	uses	bx,dx
	.enter

	mov	dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add	dx,HST1

	call	TimerGetCount
	add	ax,WATCHDOG_COUNT_INIT
	mov	es:[PS_redwoodSpecific].RS_watchDogCount,ax
testLoop:

	in	al,dx		;read the HST1 reg.
	mov	ah,al		;save away.
	test	ah,mask HST1_SDBSY	;do we have data?
	jnz	tested		;if so, get data

	push	ax
	call	TimerGetCount
	cmp	ax,es:[PS_redwoodSpecific].RS_watchDogCount
	pop	ax
	jne	testLoop	;try to read the regs again
	stc
	jmp	exit

tested:
	sub	dx,HST1		;back to the data reg.
	in	al,dx		;get data.

	clc			;set no error....

exit:
	.leave
	ret
GetOneStatusByte	endp
