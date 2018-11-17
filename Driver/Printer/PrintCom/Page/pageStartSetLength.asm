
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageStartSetLength.asm

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

	$Id: pageStartSetLength.asm,v 1.1 97/04/18 11:51:44 newdeal Exp $

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
	uses	es,dx
	.enter
		
	mov	es,bp

		;If the printer is in tractor feed  mode, we may get lucky and
		;the printer DIP SWITCH setting paper length will match the 
		;PC/GEOS paper length, so that the tear off feature of the
		;printer will function properly. So, test for tractor feed, and
		;dont muck up the paper length, since we dont need it anyway at
		;page end time for tractor.
        test    es:PS_paperInput,mask PIO_TRACTOR
        jnz	tractorBypass

		;set the paper length to the max.
	mov	si,offset pr_codes_InitPaperLength
	call	SendCodeOut
	jc	exit

tractorBypass:
		; see if the spooler is in the suppress formfeed mode.
	cmp	cl,C_FF
	jne	suppressformfeed

		; start cursor out at top,left position
	call	PrintHomeCursor	;start out from home position.
	jc	exit

suppressformfeed:
		; init font style.  
	call	PrintClearStyles		; set clear styles
exit:
	.leave
	ret
PrintStartPage	endp
