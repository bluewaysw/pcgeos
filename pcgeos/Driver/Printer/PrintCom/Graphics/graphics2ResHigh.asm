
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		graphics2ResHigh.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	3/92		moved from epson9


DESCRIPTION:

	$Id: graphics2ResHigh.asm,v 1.1 97/04/18 11:51:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintABand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Steering routine to all the print resolutions.
	uses medium routine to print "low" resolution.

CALLED BY:	

PASS:		
	ds:si	=	fptr to bitmap data
			from huge array stuff.
	es	= 	PState segment

RETURN:		carry	- set if some transmission error

DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrPrintABand	proc	near
	uses	cx
	.enter
	mov	cl, es:[PS_mode]	; get the mode while we still have PStae
	cmp	cl, PM_GRAPHICS_LOW_RES	;see if the lores bit is set.
	ja	checkHiRes		;if anything other than low res or 
	call	PrPrintMediumBand		;non scaling, skip
	jmp	done			;  all done, send a line feed
checkHiRes:
EC<	cmp	cl,PM_GRAPHICS_HI_RES				>
EC<	ERROR_A	INVALID_MODE					>
	call	PrPrintHighBand		
done:
	.leave
	ret
PrPrintABand	endp
