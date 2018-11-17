
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet print driver
FILE:		cursorPCL4Adjust.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsCursor.asm


DESCRIPTION:

	$Id: cursorPCL4Adjust.asm,v 1.1 97/04/18 11:49:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrAdjustCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	moves the cursor to the correct X position on the current line.

CALLED BY:
	PrintSwath

PASS:
	cl	- direction to adjust "X" horizontal, "Y" vertical.
	dx	- distance in pixels to move.
	ds	- Segment of PSTATE

RETURN:
	nothing

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

PrAdjustCursor	proc	near
	uses	ax,es,si
	.enter
	segmov	es,ds,ax	;es->Pstate
;now we have the correct number of 1/300" to move for this resolution
	push	cx
	push	dx		;save distance.
	mov	si,offset pr_codes_AdjustCursor
	call	SendCodeOut
	pop	ax		;get the distance.
	jc	popcx		;pass out errors.
	call	HexToAsciiStreamWrite
popcx:	
	pop	cx		;get the direction.
	jc	exit		;pass out the errors.
	call	PrintStreamWriteByte
exit:
	.leave
	ret
PrAdjustCursor	endp

