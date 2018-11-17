
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LBP print driver
FILE:		cursorSetCursorCapsl.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the LBP
	print driver cursor movement support

	$Id: cursorSetCursorCapsl.asm,v 1.1 97/04/18 11:49:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE and moves the cursor
	to the new position.

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
        WWFixed:
        cx.si   - new X position
        dx.ax   - new Y position

RETURN:
	nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
        uses    ax,si,ds,es
        .enter
        mov     es,bp           ;get PSTATE segment.

                ;convert the WWFixed into 1/300 units.
        call    PrConvertToDriverCoordinates    ;get into dot units.
        mov     es:[PS_cursorPos].P_y,dx ;save the new Y Position.
        mov     dx,cx           ;now ge the x pos into
        mov     ax,si
        call    PrConvertToDriverCoordinates    ;dot units.
        mov     es:[PS_cursorPos].P_x,dx ;save the new X Position.
        call    PrMoveCursor

        .leave
        ret
PrintSetCursor	endp

PrMoveCursor	proc	near
	uses	si,ax,cx
	.enter
	mov	si,offset pr_codes_CSIcode
	call	SendCodeOut
	jc	exit
	mov     ax,es:[PS_cursorPos].P_y
	call	HexToAsciiStreamWrite	;send it.
	jc	exit
	mov	cl,';'
	call	PrintStreamWriteByte
	jc	exit
	mov     ax,es:[PS_cursorPos].P_x
	call	HexToAsciiStreamWrite	;send it.
	jc	exit
	mov	cl,'f'
	call	PrintStreamWriteByte
exit:
	.leave
	ret
PrMoveCursor	endp
