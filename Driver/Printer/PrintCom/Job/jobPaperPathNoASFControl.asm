
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobPaperPathNoASFControl.asm

AUTHOR:		Dave Durran, 8 Sept 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	3/92		Initial revision from epson24Setup.asm
	 Dave	5/92		Parsed from printcomIBMSetup.asm


DESCRIPTION:
		

	$Id: jobPaperPathNoASFControl.asm,v 1.1 97/04/18 11:51:00 newdeal Exp $

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
	and loads the Pstate and sets the printer up accordingly. The IBMs do
	not have any output options, so that record is ignored, and the PState
	is loaded with the only condition possible. They also do not have any
	commands to deal with the paper path explicitly, so the PState is
	loaded with the appropriate margin info, and the path is set in there
	also.

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
	mov	si, offset PI_marginTractor ;set tractor source for margins
	jmp	copyMarginInfo
handleASF:
	mov	si, offset PI_marginASF	;set ASF path.. source for margins
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
	.leave
	ret
PrintSetPaperPath	endp
