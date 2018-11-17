
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobResetPrinterAndWait.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	4/93		Initial revision 


DESCRIPTION:
		

	$Id: jobResetPrinterAndWait.asm,v 1.1 97/04/18 11:51:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintResetPrinterAndWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do Hard reset on the printer hardware, and wait for the 
		printer to init.

CALLED BY:	GLOBAL

PASS:		es	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintResetPrinterAndWait	proc	far
	uses	ax,bx,cx,si,di
	.enter

	; Make sure the port is really empty enough to accomidate the reset code
	; bytes.  We dont want it to block!

	clr	ch
	mov	cl,cs:pr_codes_ResetPrinter ;load the byte count.
checkagain:
	mov	di,DR_STREAM_QUERY
	mov	ax,STREAM_WRITE
	mov	bx,es:[PS_streamToken]
	call	es:[PS_streamStrategy]
	jc	exit
	cmp	ax,cx			;see if the byte length of code is less
						;than available space.
	jle	checkagain		;check till the stream empties a little.

	; initialize the printer

	mov	si,offset pr_codes_ResetPrinter
	call	SendCodeOut
		

	; stop looking at the port for PR_INIT_WAIT_PERIOD sec.
	; this prevents silly pulses coming back on the SLCT' line and 
	; screwing up the port error detection.  If the printer is really off
	; line or in an error condition, the InitPrinter below will catch it.

	mov	ax,PR_INIT_WAIT_PERIOD
	call	TimerSleep
exit:
	clc			;no errors get passed out of here, so CAUTION
				;is advised on what follows: make sure some
				;thing follows that passes port errors back.

	.leave
	ret
PrintResetPrinterAndWait	endp
