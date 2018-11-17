COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscMiddleBWBitmap.asm

AUTHOR:		Ted H. Kim, 2/6/90
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/6/90		Initial revision

DESCRIPTION:
	Contains B&W mid section of card.

	$Id: miscMiddleBWBitmap.asm,v 1.1 97/04/04 15:50:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BWMidsectResource segment resource
		StartbwmidsecIcon label byte

		Bitmap <13,113,BMC_PACKBITS, BMF_MONO>
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
		db	001h, 0adh, 0ach
		db	001h, 0dah, 0dch
BWMidsectResource ends
