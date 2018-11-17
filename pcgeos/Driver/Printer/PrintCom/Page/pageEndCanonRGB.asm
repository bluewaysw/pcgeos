
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageEndCanonRGB.asm

AUTHOR:		Dave Hunter

ROUTINES:
	Name		Description
	----		-----------
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	DH	5/19/00	initial version from pageEndASFOnly.asm

DESCRIPTION:

	$$

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

		; Don't send a form feed in banner mode
		
		mov	es, bp
		BranchIfBannerMode	afterfont

		; send a form feed to the bugger

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
