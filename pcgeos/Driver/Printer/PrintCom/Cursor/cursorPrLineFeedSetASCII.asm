
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorPrLineFeedSet.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision


DESCRIPTION:

	$Id: cursorPrLineFeedSetASCII.asm,v 1.1 97/04/18 11:49:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Executes a vertical line feed of dx <printer units>", and updates the
	cursor position accordingly.

	uses the "Set the distance, then LF" control code method.
	uses ASCII units

CALLED BY:
	SetCursor, PrintSwath, others

PASS:
	dx	=	length , in <printer units>" to line feed.
	es	=	PState segment address

RETURN:
	carry	- set if some transmission error

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrLineFeed	proc	near
	uses	cx,si
	.enter

	add	es:PS_cursorPos.P_y,dx	;update the cursor position.
	cmp	dx,PR_MAX_LINE_FEED
	jb	doRem
	mov	si,offset pr_codes_SetMaxLineFeed ;code to Set max/units" feed.
	call	SendCodeOut	;send the code to the stream.
	jc	exit
maxLoop:
	cmp	dx,PR_MAX_LINE_FEED
	jb	doRem
	sub	dx,PR_MAX_LINE_FEED			;save in storge reg.
	mov	cl, C_LF 
	call	PrintStreamWriteByte		;send the actual LF char.
	jc	exit
	jmp	maxLoop
	

;do remainder of distance.
doRem:
	test	dx,dx		;see if zero.
	jz	exit		;if so, exit.
	mov	si,offset pr_codes_SetLineFeed ;code to Set n/units" feed.
	call	SendCodeOut	;send the code to the stream.
	jc	exit
	mov	ax,dx		;get back the remainder.
	mov	cx,2		;2 digits
	call	HexToAsciiStreamWrite		;send the distance.
	jc	exit
	mov	cl, C_LF 
	call	PrintStreamWriteByte		;send the actual LF char.
exit:
	.leave
	ret
PrLineFeed	endp
