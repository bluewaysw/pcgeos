
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		cursorPrFormFeedIBMPPDS24.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/93	Initial version

DESCRIPTION:

	$Id: cursorPrFormFeedIBMPPDS24.asm,v 1.1 97/04/18 11:49:47 newdeal Exp $

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
		Use the SetCursor routine to make sure that the cursor is at
		the bottom margin; 
		Use the page length command to set the page length to the 
		bottom margin value, and send a form-feed to the printer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrFormFeed	proc	near
	uses	ax,bx,cx,dx,si
	.enter
	mov	dx,es:[PS_customHeight]	;get the paper length.
	sub	dx,es:[PS_currentMargins].[PM_top] ;get rid of the top marg.
	sub	dx,es:[PS_currentMargins].[PM_bottom] ;and the bottom, so
						;dx now has the total height
						;of the printable area. (In
						;points)
	clr	ax			;clear for x position and WWFixed math.
	mov	si,ax
	mov	cx,ax
	call	PrintSetCursor	;make sure the cursor position is at the 
				;bottom of the live print area.
	jc	exit		;pass errors out.
				;now that the cursor is at the bottom of the 
				;printable area, set the form length to the 
				;remaining paper length, which is the bottom
				;margin value.
	mov	si,offset pr_codes_FormFeed ;This code sets the line height to
	call	SendCodeOut		;1/72" (3/216 or 5/360 or whatever)
	jc	exit		;pass any errors out.

	mov	cx,es:[PS_currentMargins].[PM_bottom] ;get the bottom margin
	add	cx,es:[PS_currentMargins].[PM_top]	;add in the top marg.
EC <	test	cx,0ff80h	;see if we overflowed		>
EC <	ERROR_NZ PAGE_LENGTH_OVERFLOW				>
				;IMPORTANT: This value had better be less than
				;127, because we can only use 7 bits (cl) here.
	call	PrintStreamWriteByte
	jc	exit		;pass any errors out.
	mov	cl,C_FF		;finally send the actual Form Feed character.
	call	PrintStreamWriteByte
				;we rely on the next PrintStartPage to set the
				;page length back to some large value.

exit:
	.leave
	ret
PrFormFeed	endp
