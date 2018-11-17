
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		HP PCL printer drivers
FILE:		jobPaperPCL.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/92	initial version

DESCRIPTION:

	$Id: jobPaperPCL.asm,v 1.1 97/04/18 11:51:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer's paper path.
		Set margins in PState

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		al	- PaperInputOptions record
		ah	- PaperOutputOptions record

RETURN:		carry set if some transmission error.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine takes the record for the Paper input and output options
	and loads the Pstate and sets the printer up accordingly. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintSetPaperPath	proc	far
	uses	ax,bx,cx,ds,es,dx
	.enter
	mov	es,bp			;es --> PState
	mov	es:[PS_paperInput],al
	mov	es:[PS_paperOutput],ah

ifdef   PCL4MODE
	and	ah,mask POO_DUPLEX	;deal with possible duplex printing.
	test	ah,ah
	jz	handleInputOptions
	mov	cl,offset POO_DUPLEX	;get in least significant bits.
	shr	ah,cl
	mov	al,ah
	mov	di,offset pr_codes_DuplexMode
	call	WriteNumByteCommand
	jc	exit			;pass errors out
handleInputOptions:
endif

	mov	al,es:[PS_paperInput]	;get the byte back.
	test	al,mask PIO_MANUAL	;are any manual feeds selected?
	jz	handleASFs		;if not, deal with the trays.
	mov	al,2			;set manual input.
	jmp	sendCommand
handleASFs:
	mov	cl,offset PIO_ASF
	shr	al,cl
	and	al,ASF_TRAY3		;clean off unused bits
	mov	bx,offset ASFTable
	xlatb	cs:
sendCommand:
	mov	di,offset pr_codes_SetInputPath
	call	WriteNumByteCommand
	jc	exit

				;transfer the ASF margins to the PState.
	mov	bx,es:[PS_deviceInfo]	;handle to device resource.
	call	MemLock
	mov	ds,ax			;segment of device info resource.
	mov	si,offset PI_marginASF	;offset of the margin info.
	mov	di,offset PS_currentMargins ;offset to dest in PState.
	mov	cx,(size PrinterMargins) shr 1 ;length in words.
	rep movsw
	call	MemUnlock
	clc
exit:
	.leave
	ret
PrintSetPaperPath	endp

ASFTable	label	byte
	byte	1	;upper tray error correction entry (no source specified)
	byte	1	;upper tray
	byte	4	;lower tray
	byte	6	;envelope feeder


