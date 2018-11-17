
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		jobPaperInfoNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/94	initial version

DESCRIPTION:
	Routines to return Information about the paper or paper path for
	this job.
	They are all internal routines.

	$Id: jobPaperInfoNike.asm,v 1.1 97/04/18 11:51:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetPaperPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		es	- PSTATE segment address.

RETURN:		ax	- paper position in 1/300"
				(if 0 then paper is not loaded)
		carry cleared

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

if (0)	; No one uses this yet. - Joon (3/28/95)

PrintGetPaperPosition	proc	near
	uses	bp,si,cx
	.enter
	mov	ax,es:[PS_dWP_Specific].DWPS_yOffset
	.leave
	ret
PrintGetPaperPosition	endp

endif
