
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobPaperPathASFControl.asm

AUTHOR:		Dave Durran, 8 Sept 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	3/92		Initial revision from epson24Setup.asm
	 Dave	5/92		Parsed from printcomEpsonSetup.asm


DESCRIPTION:
		

	$Id: jobPaperPathASFControl.asm,v 1.1 97/04/18 11:51:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer's paper path.
		set margins in PState

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		al	- PaperInputOptions record
		ah	- PaperOutputOptions record

RETURN:		carry set if some transmission error.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine takes the record for the Paper input and output options
	and loads the Pstate and sets the printer up accordingly. The LQs do
	not have any output options, so that record is ignored, and the PState
	is loaded with the only condition possible.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintSetPaperPath	proc	far
	uses	ax,bx,cx,dx,si,di,es,ds
	.enter
	mov	es,bp			;es --> PState
	mov	es:[PS_paperInput],al
	mov	es:[PS_paperOutput],PS_REVERSE shl offset POO_SORTED
	test	al,mask PIO_TRACTOR	;check for tractor feed paths first.
	jnz	handleTractor
	test	al,mask PIO_ASF	;check for ASF next.
	jnz	handleASF
handleTractor:
	mov	si,offset pr_codes_DisableASF
	call	SendCodeOut
	jc	exit
	mov	si, offset PI_marginTractor ;set tractor source for margins
	jmp	copyMarginInfo
handleASF:
	mov	si,offset pr_codes_EnableASF
	call	SendCodeOut
	jc	exit			;pass out errors.
	mov	si,offset pr_codes_ASFControl
	call	SendCodeOut
	jc	exit			;pass out errors.
	mov	si, offset PI_marginASF	;set ASF path.. source for margins
	mov	cl,1			;initialize for bin 1
	and	al,mask PIO_ASF		;clean off non ASF bits.
	cmp	al,ASF_TRAY1 shl offset PIO_ASF ;see if the bin is #1...
	je	sendArgument		;OK, send argument for bin #1
	inc	cl			;all other options go to bin #2
sendArgument:
	call	PrintStreamWriteByte
	jc	exit
copyMarginInfo:
				;source offset should already be loaded.
	mov	bx,es:[PS_deviceInfo]
	call	MemLock
	mov	ds,ax			;ds:si = source (Info resource).
	mov	di,offset PS_currentMargins	;set dest offset for margins
						;es:di = dest (PState).
	mov	cx,(size PrinterMargins) shr 1	;size of the structure to copy.
	rep movsw
	call	MemUnlock
	clc
exit:
	.leave
	ret
PrintSetPaperPath	endp
