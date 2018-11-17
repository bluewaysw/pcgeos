COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscBottomColorBitmap.asm

AUTHOR:		Ted H. Kim, 2/6/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/6/90		Initial revision

DESCRIPTION:
	Contains colored version of bottom part of card bitmap.

	$Id: miscBottomColorBitmap.asm,v 1.1 97/04/04 15:50:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColorBottomResource segment resource
		StartbottomIcon label byte
		Bitmap <279,24,BMC_PACKBITS, mask BMT_MASK or BMF_4BIT>
		db	0dfh, 0ffh, 000h, 0feh
		db	000h, 00fh, 0dfh, 0ffh, 0f5h, 000h, 000h, 00fh, 
			0e6h, 0ffh, 0f5h, 000h, 000h, 00fh, 0d4h, 0ffh, 
			006h, 007h, 077h, 007h, 077h, 007h, 077h, 000h
		db	0f8h, 0ffh, 002h, 000h, 000h, 001h, 0fah, 0ffh, 
			002h, 000h, 000h, 001h, 0f5h, 0ffh, 000h, 0feh
		db	000h, 00fh, 0e0h, 0ffh, 001h, 000h, 070h, 0f6h, 
			0ddh, 001h, 0d0h, 00fh, 0e8h, 0ffh, 001h, 000h, 
			070h, 0f6h, 0ddh, 001h, 0d0h, 00fh, 0d5h, 0ffh, 
			006h, 007h, 077h, 007h, 077h, 007h, 077h, 000h
		db	0f8h, 0ffh, 0feh, 000h, 000h, 07fh, 0fbh, 0ffh, 
			0feh, 000h, 000h, 07fh, 0f6h, 0ffh, 000h, 0feh
		db	000h, 00fh, 0e1h, 0ffh, 002h, 0f0h, 007h, 070h, 
			0f5h, 0ddh, 000h, 0d0h, 0e9h, 0ffh, 002h, 0f0h, 
			077h, 070h, 0f5h, 0ddh, 000h, 0d0h, 0d5h, 0ffh, 
			006h, 007h, 077h, 007h, 077h, 007h, 077h, 000h
		db	0f8h, 0ffh, 003h, 080h, 000h, 000h, 03fh, 0fbh, 
			0ffh, 003h, 080h, 000h, 000h, 03fh, 0f6h, 0ffh, 
			000h, 0feh
		db	000h, 00fh, 0e1h, 0ffh, 003h, 007h, 077h, 070h, 
			00dh, 0f5h, 0ddh, 000h, 00fh, 0eah, 0ffh, 003h, 
			007h, 077h, 070h, 00dh, 0f5h, 0ddh, 000h, 00fh, 
			0d6h, 0ffh, 006h, 007h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	0f8h, 0ffh, 003h, 080h, 000h, 000h, 03fh, 0fbh, 
			0ffh, 003h, 080h, 000h, 000h, 03fh, 0f6h, 0ffh, 
			000h, 0feh
		db	000h, 00fh, 0e1h, 0ffh, 003h, 007h, 077h, 077h, 
			00dh, 0f5h, 0ddh, 000h, 00fh, 0eah, 0ffh, 003h, 
			000h, 077h, 077h, 00dh, 0f5h, 0ddh, 000h, 00fh, 
			0d6h, 0ffh, 006h, 007h, 077h, 007h, 077h, 007h, 
			077h, 000h
		db	0f8h, 0ffh, 003h, 0c0h, 000h, 000h, 01fh, 0fbh, 
			0ffh, 003h, 0c0h, 000h, 000h, 01fh, 0f6h, 0ffh, 
			000h, 0fch
		db	000h, 00fh, 0e2h, 0ffh, 004h, 0f0h, 070h, 077h, 
			077h, 070h, 0f5h, 0ddh, 000h, 0d0h, 0ebh, 0ffh, 
			004h, 0f0h, 070h, 077h, 077h, 070h, 0f5h, 0ddh, 
			000h, 0d0h, 0d6h, 0ffh, 006h, 007h, 077h, 007h, 
			077h, 007h, 070h, 0d0h
		db	0f8h, 0ffh, 003h, 0f0h, 000h, 000h, 01fh, 0fbh, 
			0ffh, 003h, 0f0h, 000h, 000h, 01fh, 0f6h, 0ffh, 
			000h, 0f8h
		db	000h, 00fh, 0e2h, 0ffh, 001h, 0f0h, 070h, 0feh, 
			077h, 000h, 000h, 0f6h, 0ddh, 000h, 0d0h, 0ebh, 
			0ffh, 001h, 0f0h, 070h, 0feh, 077h, 000h, 000h, 
			0f6h, 0ddh, 000h, 0d0h, 0d6h, 0ffh, 006h, 007h, 
			077h, 007h, 077h, 007h, 00dh, 0d0h
		db	0f7h, 0ffh, 001h, 0e0h, 007h, 0f9h, 0ffh, 001h, 
			0e0h, 007h, 0f5h, 0ffh, 000h, 0f8h
		db	000h, 00fh, 0e2h, 0ffh, 001h, 0f0h, 070h, 0feh, 
			077h, 000h, 070h, 0feh, 000h, 000h, 00dh, 0fdh, 
			0ddh, 000h, 0d0h, 0feh, 000h, 0ebh, 0ffh, 005h, 
			0f0h, 077h, 007h, 077h, 077h, 070h, 0feh, 000h, 
			000h, 00dh, 0fdh, 0ddh, 000h, 0d0h, 0feh, 000h, 
			0d6h, 0ffh, 006h, 007h, 077h, 007h, 077h, 007h, 
			00dh, 0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 00fh, 0f9h, 0ffh, 001h, 
			0f0h, 00fh, 0f5h, 0ffh, 000h, 0f0h
		db	000h, 00fh, 0e2h, 0ffh, 002h, 0f0h, 077h, 007h, 
			0fbh, 077h, 000h, 000h, 0fdh, 0ddh, 003h, 007h, 
			077h, 077h, 070h, 0ebh, 0ffh, 002h, 0f0h, 077h, 
			070h, 0fbh, 077h, 000h, 000h, 0fdh, 0ddh, 003h, 
			007h, 077h, 077h, 070h, 0d6h, 0ffh, 006h, 007h, 
			077h, 007h, 077h, 000h, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 00fh, 0f9h, 0ffh, 001h, 
			0f0h, 00fh, 0f5h, 0ffh, 000h, 0f0h
		db	000h, 00fh, 0e2h, 0ffh, 002h, 0f0h, 077h, 070h, 
			0fbh, 077h, 000h, 070h, 0fdh, 0ddh, 003h, 007h, 
			077h, 077h, 070h, 0ebh, 0ffh, 003h, 0f0h, 077h, 
			077h, 007h, 0fch, 077h, 000h, 070h, 0fdh, 0ddh, 
			003h, 007h, 077h, 077h, 070h, 0d6h, 0ffh, 006h, 
			007h, 077h, 007h, 077h, 000h, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 00fh, 0f9h, 0ffh, 001h, 
			0f0h, 00fh, 0f5h, 0ffh, 000h, 0e0h
		db	000h, 00fh, 0e2h, 0ffh, 003h, 0f0h, 077h, 077h, 
			007h, 0fch, 077h, 000h, 070h, 0fdh, 0ddh, 003h, 
			007h, 077h, 077h, 070h, 0ebh, 0ffh, 003h, 0f0h, 
			077h, 077h, 070h, 0fch, 077h, 000h, 070h, 0fdh, 
			0ddh, 003h, 007h, 077h, 077h, 070h, 0d6h, 0ffh, 
			006h, 007h, 077h, 007h, 077h, 00dh, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 00fh, 0f9h, 0ffh, 001h, 
			0f0h, 00fh, 0f5h, 0ffh, 000h, 0c0h
		db	000h, 00fh, 0e2h, 0ffh, 003h, 0f0h, 077h, 077h, 
			070h, 0fch, 077h, 000h, 070h, 0fdh, 0ddh, 003h, 
			007h, 077h, 077h, 000h, 0ebh, 0ffh, 000h, 0f0h, 
			0feh, 077h, 000h, 007h, 0fdh, 077h, 000h, 070h, 
			0fdh, 0ddh, 003h, 007h, 077h, 077h, 070h, 0d6h, 
			0ffh, 006h, 007h, 077h, 007h, 070h, 0ddh, 0ddh, 
			0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 03fh, 0f9h, 0ffh, 001h, 
			0f0h, 03fh, 0f5h, 0ffh, 000h, 0c0h
		db	000h, 00fh, 0e1h, 0ffh, 002h, 007h, 077h, 077h, 
			0feh, 000h, 002h, 007h, 077h, 070h, 0feh, 0ddh, 
			0fdh, 000h, 000h, 00fh, 0eah, 0ffh, 003h, 007h, 
			077h, 077h, 070h, 0feh, 000h, 001h, 077h, 070h, 
			0feh, 0ddh, 0fdh, 000h, 000h, 00fh, 0d6h, 0ffh, 
			006h, 007h, 077h, 007h, 000h, 0ddh, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 0f0h, 07fh, 0f9h, 0ffh, 001h, 
			0f0h, 07fh, 0f5h, 0ffh, 000h, 080h
		db	000h, 00fh, 0e1h, 0ffh, 000h, 000h, 0fch, 077h, 
			005h, 070h, 077h, 070h, 0ddh, 0ddh, 0d0h, 0fdh, 
			077h, 000h, 00fh, 0eah, 0ffh, 000h, 000h, 0fbh, 
			077h, 004h, 007h, 070h, 0ddh, 0ddh, 0d0h, 0fdh, 
			077h, 000h, 00fh, 0d6h, 0ffh, 006h, 007h, 077h, 
			007h, 00dh, 0ddh, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 0e0h, 07fh, 0f9h, 0ffh, 001h, 
			0e0h, 07fh, 0f5h, 0ffh, 000h, 080h
		db	000h, 00fh, 0e1h, 0ffh, 001h, 0f0h, 007h, 0fch, 
			077h, 004h, 000h, 00dh, 0ddh, 0ddh, 0d0h, 0feh, 
			077h, 000h, 000h, 0e9h, 0ffh, 001h, 0f0h, 007h, 
			0fch, 077h, 004h, 000h, 00dh, 0ddh, 0ddh, 0d0h, 
			0feh, 077h, 000h, 000h, 0d5h, 0ffh, 006h, 007h, 
			077h, 000h, 00dh, 0ddh, 0ddh, 0d0h
		db	0f7h, 0ffh, 001h, 080h, 07fh, 0f9h, 0ffh, 001h, 
			080h, 07fh, 0f5h, 0ffh, 000h, 000h
		db	000h, 00fh, 0e0h, 0ffh, 000h, 000h, 0fch, 077h, 
			000h, 00dh, 0feh, 0ddh, 004h, 0d0h, 077h, 070h, 
			000h, 00fh, 0e8h, 0ffh, 000h, 000h, 0fch, 077h, 
			000h, 00dh, 0feh, 0ddh, 004h, 0d0h, 077h, 070h, 
			000h, 00fh, 0d5h, 0ffh, 002h, 007h, 077h, 000h, 
			0feh, 0ddh, 000h, 0d0h
		db	0f7h, 0ffh, 000h, 081h, 0f8h, 0ffh, 000h, 081h, 
			0f5h, 0ffh, 001h, 0feh, 000h
		db	000h, 00fh, 0dfh, 0ffh, 0feh, 000h, 005h, 007h, 
			077h, 00dh, 0ddh, 0ddh, 0d0h, 0feh, 000h, 0e5h, 
			0ffh, 0feh, 000h, 005h, 007h, 077h, 00dh, 0ddh, 
			0ddh, 0d0h, 0feh, 000h, 0d3h, 0ffh, 002h, 007h, 
			077h, 00dh, 0feh, 0ddh, 000h, 0d0h
		db	0f7h, 0ffh, 000h, 083h, 0f8h, 0ffh, 000h, 083h, 
			0f5h, 0ffh, 001h, 0feh, 000h
		db	000h, 00fh, 0dch, 0ffh, 005h, 0f0h, 077h, 00dh, 
			0ddh, 0ddh, 00fh, 0dfh, 0ffh, 005h, 0f0h, 077h, 
			00dh, 0ddh, 0ddh, 00fh, 0d0h, 0ffh, 002h, 007h, 
			070h, 00dh, 0feh, 0ddh, 000h, 0d0h
		db	0f7h, 0ffh, 000h, 083h, 0f8h, 0ffh, 000h, 083h, 
			0f5h, 0ffh, 001h, 0fch, 000h
		db	000h, 00fh, 0dch, 0ffh, 005h, 0f0h, 007h, 00dh, 
			0ddh, 0ddh, 00fh, 0dfh, 0ffh, 005h, 0f0h, 007h, 
			00dh, 0ddh, 0ddh, 00fh, 0d0h, 0ffh, 001h, 007h, 
			070h, 0fdh, 0ddh, 000h, 0d0h
		db	0f7h, 0ffh, 000h, 003h, 0f8h, 0ffh, 000h, 003h, 
			0f5h, 0ffh, 001h, 0f8h, 000h
		db	000h, 00fh, 0dch, 0ffh, 001h, 0f0h, 000h, 0feh, 
			0ddh, 000h, 00fh, 0dfh, 0ffh, 001h, 0f0h, 000h, 
			0feh, 0ddh, 000h, 00fh, 0d0h, 0ffh, 001h, 007h, 
			00dh, 0fdh, 0ddh, 000h, 0d0h
		db	0f8h, 0ffh, 001h, 0fch, 003h, 0f9h, 0ffh, 001h, 
			0fch, 003h, 0f5h, 0ffh, 001h, 0f8h, 000h
		db	000h, 00fh, 0dch, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0dfh, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0d0h, 0ffh, 001h, 000h, 00dh, 0fdh, 
			0ddh, 000h, 0d0h
		db	0f8h, 0ffh, 001h, 0fch, 003h, 0f9h, 0ffh, 001h, 
			0fch, 003h, 0f5h, 0ffh, 001h, 0f0h, 000h
		db	000h, 00fh, 0dch, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0dfh, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0d0h, 0ffh, 000h, 000h, 0fch, 0ddh, 
			000h, 0d0h
		db	0f8h, 0ffh, 001h, 0fch, 003h, 0f9h, 0ffh, 001h, 
			0fch, 003h, 0f5h, 0ffh, 001h, 0f0h, 000h
		db	000h, 00fh, 0dch, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0dfh, 0ffh, 000h, 0f0h, 0fdh, 0ddh, 
			000h, 00fh, 0d0h, 0ffh, 000h, 000h, 0fch, 0ddh, 
			000h, 0d0h
		db	0f8h, 0ffh, 001h, 0f8h, 001h, 0f9h, 0ffh, 001h, 
			0f8h, 001h, 0f5h, 0ffh, 001h, 0e0h, 000h
		db	0dbh, 000h, 000h, 00dh, 0fdh, 0ddh, 000h, 0d0h, 
			0dfh, 000h, 000h, 00dh, 0fdh, 0ddh, 000h, 0d0h, 
			0d0h, 000h, 000h, 00dh, 0fch, 0ddh, 000h, 0d0h

ColorBottomResource ends
