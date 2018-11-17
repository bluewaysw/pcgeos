COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageEndNike56.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	11/94	initial version

DESCRIPTION:

	$Id: pageEndNike56.asm,v 1.1 97/04/18 11:51:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Eject the page, wait to see if sucessful

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEndPage	proc	far
	uses	ax,es
	.enter

	mov	es,bp
	call	PrintFinishPage

	mov	es:[PS_dWP_Specific].DWPS_returnCode,PDR_NO_RETURN

		;re-cap the printhead
	call	PrintCapHead

		;send a form feed to the bugger
	call	PrintEjectPaper

	call	PrWaitForMechanismLow	;let the paper eject.

	mov	al,PJLP_update		;update LPES
	call	PrintGetErrorsLow	;see what the JAM bit is doing.
	test	al,mask PER_JAM
	jz	exit			;no problem if no jam.

		;PAPER JAM DIALOG WILL GET CALLED
	mov	es:[PS_dWP_Specific].DWPS_returnCode,PDR_PAPER_JAM_OR_EMPTY
exit:
	clc

	.leave
	ret
PrintEndPage	endp
