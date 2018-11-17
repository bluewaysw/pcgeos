
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon Redwood 64-jet print drivers
FILE:		red64Graphics.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/14/92	Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Canon Redwood
	print driver graphics mode support

	$Id: red64Graphics.asm,v 1.1 97/04/18 11:55:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include Graphics/graphicsPrintSwathRedwood.asm	;PrintSwath routine.
include	Graphics/graphicsHiRedwood.asm		;Both res routine,
include Graphics/Rotate/rotateRedwood.asm	;and rotate routine
include Graphics/Rotate/rotateRedwoodDraft.asm	;and rotate routine


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendGraphicControlCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the actual graphics control code, and column count.

CALLED BY:	INTERNAL

PASS:		
		cx	- 8 bytes x column width to print.
		es	- segment of PSTATE

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendGraphicControlCode	proc	near
	uses	ax,cx,si
	.enter
	shr	cx			;divide the byte length into column
	shr	cx			;width by dividing by 8.
	shr	cx
	dec	cx			;convert width to right column number
	mov	si,offset pr_codes_SetGraphicsWidth
	call	SendCodeOut		;set up the width to print to.
	jc	exit
	mov	ax,es:[PS_redwoodSpecific].RS_xOffset ;get the offset for this
					;paper loaded.
	add	cx,ax			;al = low byte of start column #
	call	ControlByteOut
	jc	exit
	mov	al,ah			;al = hi byte of start column #
	call	ControlByteOut
	jc	exit
	mov	al,cl			;low byte of end column#.
	call	ControlByteOut
	jc	exit
	mov	al,ch			;hi byte of end column#.
        call    ControlByteOut
	jc	exit
	mov	si,offset pr_codes_StartPrinting
	call    SendCodeOut             ;Start to print!
exit:
	.leave
	ret
PrSendGraphicControlCode	endp
