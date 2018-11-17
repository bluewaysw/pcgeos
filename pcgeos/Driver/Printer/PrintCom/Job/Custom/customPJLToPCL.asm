
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		customPJLToPCL.asm

AUTHOR:		Dave Durran, 20 October 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/92		Initial revision 


DESCRIPTION:
		

	$Id: customPJLToPCL.asm,v 1.1 97/04/18 11:50:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEnterPJL/PrintExitPJL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	INTERNAL jumped to from PrintStartJob/PrintEndJob

PASS:		es	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintEnterPJL	proc	near
	mov	si,offset pr_codes_PJLUEL
        call    SendCodeOut
        jc      exit
	mov	si,offset pr_codes_PJLCRLF
        call    SendCodeOut
        jc      exit
	mov	si,offset pr_codes_PJLEnterPCL
	call	SendCodeOut
exit:
	jmp	BeginInit
PrintEnterPJL	endp

PrintExitPJL    proc    near
        mov     si,offset pr_codes_ResetPrinter
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLUEL
        call    SendCodeOut
exit:
        jmp     EndExit
PrintExitPJL    endp
