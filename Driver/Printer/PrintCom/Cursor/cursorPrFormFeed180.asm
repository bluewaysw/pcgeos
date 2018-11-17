
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		cursorPrFormFeed180.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	6/92	Initial version

DESCRIPTION:

	$Id: cursorPrFormFeed180.asm,v 1.1 97/04/18 11:49:45 newdeal Exp $

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

	NOTE: OBSOLESCED BY THE 1/60" VERSION DJD 2/18/93

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial version

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
	mov	si,offset pr_codes_FormFeed
	call	SendCodeOut
	jc	exit		;pass any errors out.

	mov	dx,es:[PS_currentMargins].[PM_bottom] ;get the bottom margin
				;value in points, now convert it to 1/180".
        mov     cx,dx           ;save orig.
        shr     cx,1            ;x .5
        shl     dx,1		;x 2
        add     cx,dx           ;add for x2.5 so cx is our length in 1/180"
EC <	test	cx,0ff80h	;see if we are too big for 7 bit value >
EC <	ERROR_NZ	PAGE_LENGTH_OVERFLOW				>
				;IMPORTANT: This value had better be less than
				;127, because we can only use 7 bit (cl) here.
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
