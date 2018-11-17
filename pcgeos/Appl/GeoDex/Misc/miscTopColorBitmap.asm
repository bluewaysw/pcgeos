COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscTopColorBitmap.asm

AUTHOR:		Ted H. Kim, 2/6/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/6/90		Initial revision

DESCRIPTION:
	Contains colored version of tabs of rolodex.

	$Id: miscTopColorBitmap.asm,v 1.1 97/04/04 15:50:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColorLettersResource segment resource
		StartstarcolIcon label byte
		Bitmap <279,46,BMC_PACKBITS, mask BMT_MASK or BMF_4BIT>
		db	01eh, 000h, 001h, 0ffh, 0ffh, 0f1h, 0ffh, 0ffh, 
			0fch, 07fh, 0ffh, 0ffh, 01fh, 0ffh, 0ffh, 0c7h, 
			0ffh, 0ffh, 0f1h, 0ffh, 0ffh, 0fch, 07fh, 0ffh, 
			0ffh, 01fh, 0ffh, 0ffh, 0c7h, 0ffh, 0ffh, 0f8h, 
			0feh, 0ffh, 000h, 0c0h
		db	0fah, 0ddh, 000h, 0d0h, 0f7h, 000h, 001h, 0ddh, 
			0d0h, 0f6h, 000h, 001h, 0ddh, 0d0h, 0f6h, 000h, 
			001h, 0ddh, 0d0h, 0f6h, 000h, 001h, 0ddh, 0d0h, 
			0f6h, 000h, 001h, 0ddh, 0d0h, 0f6h, 000h, 001h, 
			0ddh, 0d0h, 0f6h, 000h, 001h, 0ddh, 0d0h, 0f6h, 
			000h, 001h, 0ddh, 0d0h, 0f6h, 000h, 001h, 00dh, 
			0ddh, 0f4h, 000h, 002h, 0ddh, 0ddh, 0d0h
		db	007h, 000h, 003h, 0ffh, 0ffh, 0fbh, 0ffh, 0ffh, 
			0feh, 0feh, 0ffh, 009h, 0bfh, 0ffh, 0ffh, 0efh, 
			0ffh, 0ffh, 0fbh, 0ffh, 0ffh, 0feh, 0feh, 0ffh, 
			006h, 0bfh, 0ffh, 0ffh, 0efh, 0ffh, 0ffh, 0fdh, 
			0feh, 0ffh, 000h, 0e0h
		db	0fah, 0ddh, 000h, 00fh, 0f7h, 0ffh, 001h, 00dh, 
			00fh, 0f6h, 0ffh, 001h, 00dh, 00fh, 0f6h, 0ffh, 
			001h, 00dh, 00fh, 0f6h, 0ffh, 001h, 00dh, 00fh, 
			0f6h, 0ffh, 001h, 00dh, 00fh, 0f6h, 0ffh, 001h, 
			00dh, 00fh, 0f6h, 0ffh, 001h, 00dh, 00fh, 0f6h, 
			0ffh, 001h, 00dh, 00fh, 0f6h, 0ffh, 001h, 0f0h, 
			0d0h, 0f6h, 0ffh, 004h, 0f0h, 077h, 00dh, 0ddh, 
			0d0h
		db	001h, 000h, 007h, 0e1h, 0ffh, 000h, 0f0h
		db	0fbh, 0ddh, 000h, 0d0h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 003h, 007h, 070h, 0ddh, 0d0h
		db	001h, 000h, 00fh, 0e1h, 0ffh, 000h, 0f8h
		db	0fbh, 0ddh, 000h, 00fh, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 003h, 0f0h, 077h, 00dh, 0d0h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0fch
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 070h, 0d0h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 01fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 002h, 007h, 077h, 000h
		db	001h, 000h, 03fh, 0e1h, 0ffh, 000h, 0feh
		db	0fch, 0ddh, 0f7h, 000h, 001h, 00fh, 0ffh, 0f6h, 
			000h, 001h, 00fh, 0ffh, 0f6h, 000h, 001h, 00fh, 
			0ffh, 0f6h, 000h, 001h, 00fh, 0ffh, 0f6h, 000h, 
			001h, 00fh, 0ffh, 0f6h, 000h, 001h, 00fh, 0ffh, 
			0f6h, 000h, 001h, 00fh, 0ffh, 0f6h, 000h, 001h, 
			00fh, 0ffh, 0f5h, 000h, 001h, 0ffh, 0f0h, 0f6h, 
			000h, 000h, 007h, 0feh, 0ffh, 002h, 007h, 077h, 
			000h
		db	001h, 000h, 07fh, 0e1h, 0ffh, 000h, 0feh
		db	0fdh, 0ddh, 000h, 0d0h, 0f7h, 0ffh, 001h, 0f0h, 
			0f0h, 0f6h, 0ffh, 001h, 0f0h, 0f0h, 0f6h, 0ffh, 
			001h, 0f0h, 0f0h, 0f6h, 0ffh, 001h, 0f0h, 0f0h, 
			0f6h, 0ffh, 001h, 0f0h, 0f0h, 0f6h, 0ffh, 001h, 
			0f0h, 0f0h, 0f6h, 0ffh, 001h, 0f0h, 0f0h, 0f6h, 
			0ffh, 001h, 0f0h, 0f0h, 0f5h, 0ffh, 001h, 00fh, 
			00fh, 0f6h, 0ffh, 006h, 0f0h, 077h, 0ffh, 0ffh, 
			007h, 077h, 000h
		db	000h, 000h, 0e0h, 0ffh, 000h, 0feh
		db	0fdh, 0ddh, 000h, 00fh, 0f6h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 005h, 007h, 07fh, 0ffh, 007h, 
			077h, 000h
		db	000h, 001h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 0d0h, 0f5h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 005h, 0f0h, 077h, 0ffh, 007h, 
			077h, 000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 07fh, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 003h, 0e0h, 0ffh, 000h, 0feh
		db	0feh, 0ddh, 000h, 00fh, 0f4h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f5h, 0ffh, 004h, 007h, 077h, 007h, 077h, 
			000h
		db	000h, 007h, 0e0h, 0ffh, 000h, 0feh
		db	002h, 0ddh, 0ddh, 0d0h, 0f7h, 000h, 001h, 0ffh, 
			0f0h, 0f6h, 000h, 001h, 0ffh, 0f0h, 0f6h, 000h, 
			001h, 0ffh, 0f0h, 0f6h, 000h, 001h, 0ffh, 0f0h, 
			0f6h, 000h, 001h, 0ffh, 0f0h, 0f6h, 000h, 001h, 
			0ffh, 0f0h, 0f6h, 000h, 001h, 0ffh, 0f0h, 0f6h, 
			000h, 001h, 0ffh, 0f0h, 0f6h, 000h, 001h, 00fh, 
			0ffh, 0f6h, 000h, 000h, 007h, 0fdh, 0ffh, 004h, 
			007h, 077h, 007h, 077h, 000h
		db	000h, 00fh, 0e0h, 0ffh, 000h, 0feh
		db	002h, 0ddh, 0ddh, 00fh, 0f7h, 0ffh, 001h, 00fh, 
			00fh, 0f6h, 0ffh, 001h, 00fh, 00fh, 0f6h, 0ffh, 
			001h, 00fh, 00fh, 0f6h, 0ffh, 001h, 00fh, 00fh, 
			0f6h, 0ffh, 001h, 00fh, 00fh, 0f6h, 0ffh, 001h, 
			00fh, 00fh, 0f6h, 0ffh, 001h, 00fh, 00fh, 0f6h, 
			0ffh, 001h, 00fh, 00fh, 0f6h, 0ffh, 001h, 0f0h, 
			0f0h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0feh, 0ffh, 
			004h, 007h, 077h, 007h, 077h, 000h
		db	000h, 01fh, 0e0h, 0ffh, 000h, 0feh
		db	001h, 0ddh, 0d0h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 008h, 007h, 07fh, 0ffh, 0ffh, 007h, 
			077h, 007h, 077h, 000h
		db	000h, 03fh, 0e0h, 0ffh, 000h, 0feh
		db	001h, 0ddh, 00fh, 0f5h, 0ffh, 001h, 007h, 07fh, 
			0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 
			007h, 07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 001h, 007h, 
			07fh, 0f6h, 0ffh, 001h, 007h, 07fh, 0f6h, 0ffh, 
			001h, 007h, 07fh, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 008h, 0f0h, 077h, 0ffh, 0ffh, 007h, 
			077h, 007h, 077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 07fh, 0ffh, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 0ffh, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 07fh, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	000h, 07fh, 0e0h, 0ffh, 000h, 0feh
		db	000h, 0d0h, 0f4h, 0ffh, 001h, 0f0h, 077h, 0f6h, 
			0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 
			077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 
			001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 0f0h, 077h, 
			0f6h, 0ffh, 001h, 0f0h, 077h, 0f6h, 0ffh, 001h, 
			0f0h, 077h, 0f5h, 0ffh, 001h, 007h, 07fh, 0f6h, 
			0ffh, 007h, 007h, 077h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	0dfh, 0ffh, 000h, 0feh
		db	080h, 000h, 0fdh, 000h, 006h, 007h, 077h, 007h, 
			077h, 007h, 077h, 000h

		StartColorArrow label byte
		Bitmap <10,10,BMC_PACKBITS, mask BMT_MASK or BMF_4BIT>
		db	001h, 00ch, 000h
		db	004h, 0ddh, 0ddh, 044h, 0ddh, 0ddh
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
		db	001h, 03fh, 000h
		db	000h, 0ddh, 0feh, 044h, 000h, 0ddh
		db	001h, 07fh, 080h
		db	000h, 0d4h, 0feh, 044h, 000h, 04dh
		db	001h, 0ffh, 0c0h
		db	0fch, 044h
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
		db	001h, 01eh, 000h
		db	004h, 0ddh, 0d4h, 044h, 04dh, 0ddh
ColorLettersResource ends
