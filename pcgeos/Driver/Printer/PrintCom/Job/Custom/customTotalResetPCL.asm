
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		customTotalResetPCL.asm

AUTHOR:		Dave Durran, 7/25/94

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/94		Initial revision 


DESCRIPTION:
		

	$Id: customTotalResetPCL.asm,v 1.1 97/04/18 11:50:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintExitTotalResetPCL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post job gross resetting of the printer

CALLED BY:	INTERNAL jumped to from PrintEndJob

PASS:		es	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



PrintExitTotalResetPCL	proc    near
        mov     si,offset pr_codes_ResetPrinter
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_InitPrinter	;gross init.
        call    SendCodeOut
        jc      exit
	mov	al,1				;set 1 copy
        mov     di,offset pr_codes_NumCopies
        call    WriteNumByteCommand
        jc      exit
        mov     si,offset pr_codes_SetLetterLength
        call    SendCodeOut
exit:
        jmp     EndExit
PrintExitTotalResetPCL	endp
