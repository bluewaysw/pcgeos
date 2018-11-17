
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ImageWriter 9-pin Print Driver
FILE:		iwriter9ControlCodes.asm

AUTHOR:		Dave Durran, 1 April 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/1/90		Initial revision


DC_ESCRIPTION:
	This file contains all the Printer Control Codes for the iwriter 9-pin
	driver.
		
	$Id: iwriter9ControlCodes.asm,v 1.1 97/04/18 11:53:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;*****************************************************************************
;
;CONTROL CODES FOR THE IMAGEWRITER 9-PIN PRINTERS.....
;
;	the first byte is the byte count for the control code.
;
;*****************************************************************************

pr_codes_ResetPrinter:
	byte	2,C_ESC,"c"
pr_codes_PosCursorX:
	byte	2,C_ESC,"F"
pr_codes_DoLineFeed:
	byte	2,C_ESC,"T"
pr_codes_ShortLineFeed:
	byte	5,C_ESC,"T01",C_LF
pr_codes_LongLineFeed:
	byte	5,C_ESC,"T15",C_LF
pr_codes_SetMaxFeed:
	byte	4,C_ESC,"T50"
pr_codes_DoMaxFeed:
	byte	2,C_LF,C_LF
pr_codes_SetLoGraphics:
	byte	4,C_ESC,"N",C_ESC,"S"
pr_codes_SetHiGraphics:
	byte	4,C_ESC,"P",C_ESC,"S"
pr_codes_SetNoPerfSkip:		;general init codes.
	byte	2,C_ESC,">"	;unidirectional print.
pr_codes_Set10Pitch:
	byte	2,C_ESC,"N"
pr_codes_Set12Pitch:
	byte	2,C_ESC,"E"
pr_codes_SetProportional:
	byte	2,C_ESC,"p"
pr_codes_SetCondensed:
	byte	2,C_ESC,"Q"
pr_codes_SetSubscript:
	byte	3,C_ESC,"s2"
pr_codes_SetSuperscript:
	byte	3,C_ESC,"s1"
pr_codes_SetNLQ:
	byte	3,C_ESC,"a2"
pr_codes_SetBold:
	byte	2,C_ESC,"!"
pr_codes_SetUnderline:
	byte	2,C_ESC,"X"
pr_codes_SetDblWidth:
	byte	1,14
pr_codes_ResetCondensed:
	byte	2,C_ESC,"N"
pr_codes_ResetScript:
	byte	3,C_ESC,"s0"
pr_codes_ResetNLQ:
	byte	3,C_ESC,"a1"
pr_codes_ResetBold:
	byte	2,C_ESC,"\""
pr_codes_ResetUnderline:
	byte	2,C_ESC,"Y"
pr_codes_ResetDblWidth:
	byte	1,15


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexToAsciiConv4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert a hex number into 4 bytes of ascii

CALLED BY:	GLOBAL

PASS:		dx	- hex number

RETURN:		al	=	high order byte
		ah	=	med high order byte
		dl	=	med low order byte
		dh	=	low order byte

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HexToAsciiConv4 proc	near
	uses	cx, di, ds, es
convbuff local	5 dup (word)
	.enter
	segmov	es,ss,ax
	mov	ds,ax		;also point with ds.
	clr	ax		;clear the top word for kernal routine.
	mov	cx,mask UHTAF_INCLUDE_LEADING_ZEROS
	lea	di,convbuff		;point at the buffer to load.
	call	UtilHex32ToAscii	;convert the hex to ascii.
	mov	dx,convbuff+8		;reload the regs.
	mov	ax,convbuff+6
	.leave
	ret
HexToAsciiConv4 endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexToAsciiSend4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Jump Table

PASS:	dx	- hex number
	bp	- Segment of PSTATE

RETURN:
	nothing

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HexToAsciiSend4	proc	near
	uses	ax,cx,es
	.enter
	call	HexToAsciiConv4		;convert the number.
	mov	es,bp			;get PSTATE
	mov	cl,al
	call	PrintStreamWriteByte
	mov	cl,ah
	call	PrintStreamWriteByte
	mov	cl,dl
	call	PrintStreamWriteByte
	mov	cl,dh
	call	PrintStreamWriteByte
	.leave
	ret
HexToAsciiSend4	endp
