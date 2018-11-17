
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageStart.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version
	Dave	3/92	copied from epson24Page.asm

DESCRIPTION:

	$Id: pageStart.asm,v 1.1 97/04/18 11:51:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

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
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintStartPage	proc	far
	uses	ds,es,dx
	.enter
		
		; see if the spooler is in the suppress formfeed mode.
	cmp	cl,C_FF
	jne	suppressformfeed

		; start cursor out at top,left position
	call	PrintHomeCursor	;start out from home position.
	jc	exit

suppressformfeed:
	mov	es,bp
		; init font style.  
	call	PrintClearStyles		; set clear styles
exit:
	.leave
	ret
PrintStartPage	endp
