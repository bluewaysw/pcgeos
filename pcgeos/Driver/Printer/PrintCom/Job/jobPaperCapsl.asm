
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		HP PCL printer drivers
FILE:		jobPaperCapsl.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/92	initial version

DESCRIPTION:

	$Id: jobPaperCapsl.asm,v 1.1 97/04/18 11:51:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer's paper path.
		Set margins in PState

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		al	- PaperInputOptions record from ui (this is the raw
			  data, I set the PaperInputOptions record here)
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
	push	ax			;save inputs.
	mov	bx,offset inputConversionTab	;point at conversion table
	xlatb 	cs:
	mov	es:[PS_paperInput],al
	mov	es:[PS_paperOutput],ah
	;and	ah,not mask POO_DUPLEX	;deal with possible duplex printing.
	;test	ah,ah
	;jz	handleInputOptions
	;mov	cl,offset POO_DUPLEX	;get in least significant bits.
	;shr	ah,cl
	;mov	al,ah
	;mov	si,offset pr_codes_DuplexMode
	;call	SendCodeOut
handleInputOptions:
	pop	ax			;get the byte back.
	jc	exit			;pass errors out
	mov	si,offset pr_codes_CSIcode
	call	SendCodeOut
	clr	ah			;get the paper path argument in ax
	call	HexToAsciiStreamWrite
	jc	exit			;errors out.
	mov	cl,"q"			;get the paper path code in cl.
	call	PrintStreamWriteByte
	jc	exit			;errors out.

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

inputConversionTab	label	byte
	byte	ASF_TRAY1 shl offset PIO_ASF
	byte	MF_MANUAL1 shl offset PIO_MANUAL
	byte	ASF_TRAY1 shl offset PIO_ASF
	byte	ASF_TRAY2 shl offset PIO_ASF
	byte	ASF_TRAY3 shl offset PIO_ASF
