
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		stylesSetPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/15/92		Initial revision from pcl4Text.asm


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver ascii text support

	$Id: stylesSetPCL4.asm,v 1.1 97/04/18 11:51:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set new current style
		The only style serviced here, is underlining.

CALLED BY: 	GLOBAL

PASS:		bp	- Segment of PSTATE
		dx	- style word
	
RETURN: 	carry	- set if some type of cummunications error

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	02/90		Initial version
		Jim	3/90		Added check for NLQ mode and split
					into two routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetStyles	proc	far
		uses	es
		.enter
		mov	es,bp
		mov	es:PS_asciiStyle,dx	;just save it away.
		call	PrintSetStylesInt
		.leave
		ret
PrintSetStyles	endp

		;pass es=PState here....
PrintClearStyles        proc    near
        clr     es:PS_asciiStyle              ; init the styles word.
        call    PrintSetStylesInt
        ret
PrintClearStyles        endp

		;pass es=PState here....
		;PState already loaded with the style (underline) to set.
PrintSetStylesInt	proc	near
		uses	si,dx
		.enter
                mov     dx,es:PS_asciiStyle
		mov	si,offset pr_codes_ResetUnderline
		test	dx,mask PTS_UNDERLINE
		jz	setThoseStyles
		mov	si,offset pr_codes_SetUnderline

setThoseStyles:
		call	SendCodeOut
		.leave
		ret
PrintSetStylesInt	endp
