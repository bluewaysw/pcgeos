

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		colorSetFirstCMYK.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:

	$Id: colorSetFirstCMYK.asm,v 1.1 97/04/18 11:51:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFirstCMYK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next color in PState , and printer.

CALLED BY:	LoadBandBuffer
PASS:	
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
SetFirstCMYK	proc	near
	uses	ax,si
	.enter
	mov	al,es:[PS_swath].[B_type]	;see if its a color bitmap.
	and	al,mask BM_FORMAT
	cmp	al,BMF_4CMYK			;CMYK?
	clc					;(make sure that there are no
						;bogus errors passed out).
	jne	exit				;if not, then exit
	mov	si,cs:colorCodeTab		;get offset to first color set
	call	SendCodeOut
exit:
	.leave
	ret
SetFirstCMYK	endp
