
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		customLJ4PCL.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial revision 


DESCRIPTION:
		

	$Id: customLJ4PCL.asm,v 1.1 97/04/18 11:50:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEnterLJ4PCL/PrintExitLJ4PCL
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
	Dave	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrintEnterLJ4PCL	proc	near
        mov     si,offset pr_codes_PJLUEL
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLCRLF
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLMsgPCL
        call    SendCodeOut
        jc      exit
	mov	si,offset pr_codes_PJLEnterPCL
	call	SendCodeOut
exit:
	jmp	BeginInit
PrintEnterLJ4PCL	endp

PrintExitLJ4PCL    proc    near
        mov     si,offset pr_codes_PJLUEL
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLCRLF
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLMsgClear
        call    SendCodeOut
        jc      exit
        mov     si,offset pr_codes_PJLUEL
        call    SendCodeOut
exit:
        jmp     EndExit
PrintExitLJ4PCL    endp
