
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageStartCanonRGB.asm

AUTHOR:		Dave Hunter

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	DH	5/19/00	initial version from pageStartASFOnly.asm

DESCRIPTION:

	$$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		carry	- set if some transmission error

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
		uses	es,ds,dx
		.enter

		mov	es, bp

		; In banner mode, we ignore form feeds from the spooler.
		BranchIfBannerMode	skipFF
		
		; start cursor out at top,left position

		call	PrintHomeCursor	;start out from home position.

		; init font style.  

		clr	dx			; init styles to all clear
		call	PrintSetStyles		; set clear styles
skipFF::
		.leave
		ret
PrintStartPage	endp
