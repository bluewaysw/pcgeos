
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageEndASFOnly.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/92	initial version from laserdwnPage.asm
	Dave	5/92	parsed from printcomPCLPage.asm

DESCRIPTION:

	$Id: pageEndASFOnly.asm,v 1.1 97/04/18 11:51:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	form feed and clean up after the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		cl	- Suppress form feed flag, C_FF is FF non-suppressed

RETURN:		carry	-set if some communications error

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEndPage	proc	far
		uses	cx, es, dx
		.enter

		; send a form feed to the bugger

		mov	es, bp
		mov	cl,C_FF		;send a form-feed.
		call	PrintStreamWriteByte
		jc	exit


		; make sure all the styles are reset at the printer for 
		; the next page.  Use version that doesn't care about
		; NLQ mode, since we want to biff it

                mov     ds,bp           ;ds----->PState
                cmp     ds:PS_mode,PM_FIRST_TEXT_MODE
                jb      afterfont
		clr	dx			; init styles to all clear
		call	PrintSetStyles		; set clear styles @ printer
		jc	exit			; pass errors out.
afterfont:
                clc                     ; no problems

exit:
		.leave
		ret
PrintEndPage	endp
