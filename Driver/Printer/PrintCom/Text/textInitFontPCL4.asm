
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		textInitFontPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	PrInitFont		Set default font to courier 10 pitch
	PrintSetURWMono12	Set text mode font to URW Mono 12 pt
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/22/92		Initial revision from laserdwnText.asm


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver ascii text support

	$Id: textInitFontPCL4.asm,v 1.1 97/04/18 11:50:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrInitFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	PrintStartJob

PASS:
	es	- Segment of PSTATE

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, si, di, es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrInitFont	proc	near
	call	PrintSetURWMono12	;set the font.
	call	FontInit		;init the font manager.
	ret
PrInitFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetURWMono12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set font for text mode to URW Mono 12 pt which is the same as
		courier 10 pitch

CALLED BY: 	GLOBAL

PASS: 		es	- Segment of PSTATE	

RETURN: 	nothing

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetURWMono12	proc	near
	mov	es:PS_curFont.FE_fontID,FID_DTC_URW_MONO	;set mono
	mov	es:PS_curFont.FE_size,12		;12 point font.
	mov {word} es:PS_curOptFont.OFE_trackKern,0			;+
	ret
PrintSetURWMono12	endp
