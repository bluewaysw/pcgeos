COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscMiddleColorBitmap.asm

AUTHOR:		Ted H. Kim, 2/6/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/6/90		Initial revision

DESCRIPTION:
	Contains colored mid section of card.

	$Id: miscMiddleColorBitmap.asm,v 1.1 97/04/04 15:50:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColorMidsectResource segment resource
		StartmidsecIcon label byte

		Bitmap <12,113,BMC_PACKBITS, mask BMT_MASK or BMF_4BIT>
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h
		db	001h, 0ffh, 0f0h
		db	005h, 077h, 070h, 077h, 070h, 077h, 070h

ColorMidsectResource ends
