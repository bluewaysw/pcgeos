
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		customIBM4019PScript.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial revision 


DESCRIPTION:
		

	$Id: customIBM4019PScript.asm,v 1.1 97/04/18 11:50:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEnterIBM4019PScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	INTERNAL jumped to from PrintStartJob

PASS:		es	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintEnterIBM4019PScript	proc	near
		;first set to PPDS mode and set the tray source.
	mov	si,offset pr_codes_IBMSelectTraySIC
	call	SendCodeOut
        jc      exit
		;now we need to set the paperpath......
        mov     al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
	mov	cl,10010000b			;assume bottom tray....
	cmp	al,ASF_TRAY2 shl offset PIO_ASF	;Lower Tray?
	je	setTray
	mov	cl,10000000b			;assume Man feed....
	cmp	al,MF_MANUAL1 shl offset PIO_MANUAL	;Man feed?
	je	setTray
	mov	cl,10011000b			;assume Envelope tray....
	cmp	al,ASF_TRAY3 shl offset PIO_ASF	;Envelope Tray?
	je	setTray
	mov	cl,10001000b			;default to upper tray....
setTray:
	call	PrintStreamWriteByte		;send DSOPT4 byte....
        jc      exit

		;now set the emmulation to PostScript...
        mov     si,offset pr_codes_IBMEnterPostScriptSIC
        call    SendCodeOut
exit:
	jmp	BeginInit
PrintEnterIBM4019PScript	endp
