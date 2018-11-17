
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		LaserJet printer driver
FILE:		pageStartPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/92	initial version from laserdwnPage.asm
	Dave	5/92	parsed from printcomPCLPage.asm

DESCRIPTION:

	$Id: pageStartPCL4.asm,v 1.1 97/04/18 11:51:42 newdeal Exp $

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
	uses	es,dx,bp
	.enter
		
		; start cursor out at top,left position
	call	PrintHomeCursor	;start out from home position.

		; init font style.  
	clr	dx			; init styles to all clear
	call	PrintSetStyles		; set clear styles

	
	mov	es,bp			;es--->PState
	cmp	es:PS_mode,PM_FIRST_TEXT_MODE
	jb	exitOK			;just exit if in graphics mode.
        cmp     es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
        je      exitOK                           ;if not, skip.
	call	PrInitFont		;init the font manager for this
	jc	exit
						;page.
exitOK:
	clc
exit:
	.leave
	ret
PrintStartPage	endp

