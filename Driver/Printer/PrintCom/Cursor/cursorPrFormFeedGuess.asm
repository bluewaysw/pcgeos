
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		cursorPrFormFeedGuess.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	6/92	Initial version

DESCRIPTION:

	$Id: cursorPrFormFeedGuess.asm,v 1.1 97/04/18 11:49:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrFormFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	execute a form feed at the end of the page when not in
		tractor modes.

CALLED BY:	PrintEndPage

PASS:		es	- PSTATE segment address.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		I GUESS a FF sent out now will get me to the next top of form!

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrFormFeed	proc	far
	uses	cx
	.enter
	mov	cl,C_FF		;finally send the actual Form Feed character.
	call	PrintStreamWriteByte
				;we rely on the next PrintStartPage to set the
				;page length back to some large value.

	.leave
	ret
PrFormFeed	endp
