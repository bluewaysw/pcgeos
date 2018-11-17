

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		colorSetNextCMYK.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:

	$Id: colorSetNextCMYK.asm,v 1.1 97/04/18 11:51:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextCMYK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next color in PState , and printer.

CALLED BY:	LoadBandBuffer
PASS:		ds:si	- pointer into HugeArrayData block
			to the next scanline (element of the HA)
		es	- PState segment
RETURN:		ds:si	- pointer to next CMYK scan line
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/92		Initial version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextCMYK	proc	near
	uses	ax,bx,si
	.enter
	mov	al,es:[PS_swath].[B_type]	;see if its a color bitmap.
	and	al,mask BM_FORMAT
	cmp	al,BMF_4CMYK			;CMYK?
	clc					;(make sure that there are no
						;bogus errors passed out).
	jne	exit				;if not, then exit
	mov	bx,es:[PS_curColorNumber]	;get the number of this color
	inc	bx
	and	bx,3				;limit 0-3
	mov	es:[PS_curColorNumber],bx	;get next color
	shl	bx,1
	mov	si,cs:[bx].colorCodeTab		;get offset to color setting .
	call	SendCodeOut
exit:
	.leave
	ret
SetNextCMYK	endp

colorCodeTab	label	word
	word	offset pr_codes_SetYellow
	word	offset pr_codes_SetCyan
	word	offset pr_codes_SetMagenta
	word	offset pr_codes_SetBlack
