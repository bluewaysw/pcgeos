
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		pageEnd.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/93	initial version

DESCRIPTION:

	$Id: pageEnd.asm,v 1.1 97/04/18 11:51:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use PrFormFeed to get to the next TOF, clean up , and exit page.

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
	Dave	2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEndPage	proc	far
	uses	ax,cx, es, dx
	.enter

	mov	es, bp

		;get rid of more than 1 integral form length.

	clr	ax
	mov	dx,es:PS_customHeight	;get the paper size in Y.
	call	PrConvertToDriverCoordinates
	mov	ax,es:PS_cursorPos.P_y	;get the current Y pos.

checkIfMoreThanPage:
	sub	ax,dx			;subtract a paper size
	js	nosub
	mov	es:PS_cursorPos.P_y,ax	;set the current Y pos.
	jmp	checkIfMoreThanPage

nosub:
		; make sure all the styles are reset at the printer for 
		; the next page.  Use version that doesn't care about
		; NLQ mode, since we want to biff it
	call	PrintClearStyles	; set clear styles @ printer
	jc	exit

		; see if the spooler is in the suppress formfeed mode.
	cmp	cl,C_FF
	clc
	jne	exit

	call	PrFormFeed		;execute this printer's specific FF
					;routine.

	jc	exit

exit:
	.leave
	ret
PrintEndPage	endp
