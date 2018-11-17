
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageEndRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/92	initial version

DESCRIPTION:

	$Id: pageEndRedwood.asm,v 1.1 97/04/18 11:51:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use LFs to get to the next TOF, clean up , and exit page.

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEndPage	proc	far
	uses	ax,cx, es, dx
	.enter

	mov	es, bp
	mov	es:[PS_redwoodSpecific].RS_returnCode,PDR_NO_RETURN

		; send a form feed to the bugger
	mov	si,offset pr_codes_FormFeed
	call	SendCodeOut

	call	PrintWaitForMechanism	;let the paper eject.

	mov	al,PJLP_update		;update LPES
	call	PrintGetErrors		;see what the JAM bit is doing.
	test	al,mask PER_JAM
	jz	exit			;no problem if no jam.

	;PAPER JAM DIALOG WILL GET CALLED
	mov	es:[PS_redwoodSpecific].RS_returnCode,PDR_PAPER_JAM_OR_EMPTY

exit:	

	clc
	.leave
	ret
PrintEndPage	endp
