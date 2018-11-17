COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PCL Drivers
FILE:		streamPCLCommand.asm

AUTHOR:		Gene Anderson, Apr 16, 1990
		Dave Durran, Apr 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	WriteNumCommand		Write a command of the form "aaa#bbb" (#<65536)
	WriteNumByteCommand	Write a command of the form "aaa#bbb" (#<256)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/16/90		Initial revision
	Dave	4/16/91		New Initial revision
	Dave	1/92		Moved from Laserdwn

DESCRIPTION:
	Utility routines for PCL printer driver.

	$Id: streamPCLCommand.asm,v 1.1 97/04/18 11:49:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteNumCommand, WriteNumByteCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a command of the form "aaa#bbb".
CALLED BY:	INTERNAL: FontInit, FontAddFace, DownloadFontHeader, etc.

PASS:		cs:di - ptr to command string of form "aaa#bbb"
		ax - # to insert (WriteNumCommand)
		al - # to insert (WriteNumByteCommand)
		es - seg addr of PState
RETURN:		carry - set if write failed
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteNumByteCommand	proc	near
	push	ax
	clr	ah
	jmp	WriteNumCommon
WriteNumByteCommand	endp

WriteNumCommand	proc	near
	uses	cx, dx, si, ds

	push	ax
WriteNumCommon	label	near
	.enter

	mov	si, di
	segmov	ds, cs				;ds:si <- ptr to string
	mov	dx, ax				;dx <- # to insert

charLoop:
	lodsb					;al <- byte of string
	tst	al				;see if end (clear carry)
	jz	endString
	cmp	al, '#'				;see if # command
	je	insertNum
	mov	cl, al				;cl <- byte to write
	call	PrintStreamWriteByte
	jnc	charLoop			;branch if write OK
	jmp	endString			;branch if write failed

insertNum:
	mov	ax, dx				;ax <- # to write
	call	HexToAsciiStreamWrite
	jnc	charLoop			;branch if write OK

endString:
	.leave
	pop	ax
	ret
WriteNumCommand	endp

