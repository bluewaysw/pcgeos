
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		jobPaperInfoRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/93	initial version

DESCRIPTION:
	Routines to return Information about the paper or paper path for
	this job.
	They are all internal routines.

	$Id: jobPaperInfoRedwood.asm,v 1.1 97/04/18 11:51:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetPaperPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		es	- PSTATE segment address.

RETURN:		ax	- paper position in 1/360"
				(if 0 then paper is not loaded)
		carry cleared

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintGetPaperPosition	proc	near
	uses	bp,si,cx
	.enter
	mov	bp,es			;bp --> PState
	call	PrintGetErrors		;see if there is paper at all.
	clr	ax			;assume no paper in.
	cmp	cx,PERROR_NO_ERROR	;if paper is in, cx is PERROR_NO_ERROR
	jne	exit
        mov     si,offset pr_codes_GetPaperPosition
        call    SendCodeOut
        jc      exitErr
        mov     ax,1
        call    TimerSleep              ;wait for things to get loaded.
        call    StatusPacketIn
        jc      exitErr
        cmp     es:[PS_redwoodSpecific].RS_status.RSB_length,3
        jne     exitErr
        cmp     es:[PS_redwoodSpecific].RS_status.RSB_ID,26h
        jne     exitErr
	mov	al,es:[PS_redwoodSpecific].RS_status.RSB_parameters
	mov	ah,es:[PS_redwoodSpecific].RS_status.RSB_parameters+1

exit:
	.leave
	ret

exitErr:
	clr	ax
	jmp	exit
PrintGetPaperPosition	endp
