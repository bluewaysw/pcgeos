COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscBottomBWBitmap.asm

AUTHOR:		Ted H. Kim, 2/6/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	2/6/90		Initial revision

DESCRIPTION:
	Contains B&W version of bottom portion of card.

	$Id: miscBottomBWBitmap.asm,v 1.1 97/04/04 15:50:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BWBottomResource segment resource
		StartbwbottomIcon label byte
		Bitmap <278,24,BMC_PACKBITS, BMF_MONO>
		db	000h, 080h, 0fah, 000h, 003h, 007h, 0ffh, 0ffh, 
			0feh, 0fbh, 000h, 003h, 003h, 0ffh, 0ffh, 0feh, 
			0f6h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 004h, 00ah, 000h, 000h, 
			001h, 080h, 0fch, 000h, 004h, 00fh, 000h, 000h, 
			001h, 080h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 000h, 016h, 0feh, 000h, 
			000h, 040h, 0fch, 000h, 000h, 015h, 0feh, 000h, 
			000h, 040h, 0f7h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 000h, 02bh, 0feh, 000h, 
			000h, 020h, 0fch, 000h, 004h, 02ah, 080h, 000h, 
			000h, 020h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 004h, 035h, 080h, 000h, 
			000h, 020h, 0fch, 000h, 004h, 035h, 080h, 000h, 
			000h, 020h, 0f7h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 004h, 05ah, 0c0h, 000h, 
			000h, 010h, 0fch, 000h, 004h, 05ah, 0c0h, 000h, 
			000h, 010h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 004h, 075h, 060h, 000h, 
			000h, 010h, 0fch, 000h, 004h, 075h, 060h, 000h, 
			000h, 010h, 0f7h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 004h, 05ah, 0bfh, 0e0h, 
			007h, 0f0h, 0fch, 000h, 004h, 05ah, 0bfh, 0e0h, 
			007h, 0f0h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 004h, 06dh, 055h, 050h, 
			00ah, 0b0h, 0fch, 000h, 004h, 06dh, 055h, 050h, 
			00ah, 0b0h, 0f7h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 004h, 056h, 0aah, 0b0h, 
			00dh, 050h, 0fch, 000h, 004h, 056h, 0aah, 0b0h, 
			00dh, 050h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 004h, 06bh, 055h, 050h, 
			00ah, 0b0h, 0fch, 000h, 004h, 06bh, 055h, 050h, 
			00ah, 0b0h, 0f7h, 000h, 001h, 06dh, 06ch
		db	000h, 080h, 0fah, 000h, 004h, 055h, 0aah, 0b0h, 
			00dh, 070h, 0fch, 000h, 004h, 055h, 0aah, 0b0h, 
			00dh, 050h, 0f7h, 000h, 001h, 056h, 0d4h
		db	000h, 080h, 0fah, 000h, 004h, 02ah, 0ffh, 050h, 
			03fh, 0e0h, 0fch, 000h, 004h, 02ah, 0ffh, 050h, 
			03fh, 0e0h, 0f7h, 000h, 001h, 06dh, 068h
		db	000h, 080h, 0fah, 000h, 004h, 035h, 055h, 0b0h, 
			055h, 060h, 0fch, 000h, 004h, 035h, 055h, 0b0h, 
			055h, 060h, 0f7h, 000h, 001h, 056h, 0d0h
		db	000h, 080h, 0fah, 000h, 004h, 01ah, 0aah, 0e0h, 
			06ah, 0c0h, 0fch, 000h, 004h, 01ah, 0aah, 0e0h, 
			06ah, 0c0h, 0f7h, 000h, 001h, 06dh, 060h
		db	000h, 080h, 0fah, 000h, 004h, 00dh, 055h, 080h, 
			057h, 080h, 0fch, 000h, 004h, 00dh, 055h, 080h, 
			057h, 080h, 0f7h, 000h, 001h, 056h, 0c0h
		db	000h, 080h, 0fah, 000h, 003h, 003h, 0fah, 081h, 
			0fch, 0fbh, 000h, 003h, 007h, 0fah, 081h, 0fch, 
			0f6h, 000h, 001h, 06dh, 080h
		db	000h, 080h, 0f9h, 000h, 001h, 005h, 082h, 0f9h, 
			000h, 001h, 005h, 082h, 0f5h, 000h, 001h, 057h, 
			000h
		db	000h, 080h, 0f9h, 000h, 001h, 006h, 082h, 0f9h, 
			000h, 001h, 006h, 082h, 0f5h, 000h, 001h, 06eh, 
			000h
		db	000h, 080h, 0f9h, 000h, 001h, 007h, 002h, 0f9h, 
			000h, 001h, 007h, 002h, 0f5h, 000h, 001h, 054h, 
			000h
		db	000h, 080h, 0f9h, 000h, 001h, 004h, 002h, 0f9h, 
			000h, 001h, 004h, 002h, 0f5h, 000h, 001h, 068h, 
			000h
		db	000h, 080h, 0f9h, 000h, 001h, 004h, 002h, 0f9h, 
			000h, 001h, 004h, 002h, 0f5h, 000h, 001h, 050h, 
			000h
		db	000h, 080h, 0f9h, 000h, 001h, 004h, 002h, 0f9h, 
			000h, 001h, 004h, 002h, 0f5h, 000h, 001h, 060h, 
			000h
		db	0f8h, 0ffh, 001h, 0f8h, 001h, 0f9h, 0ffh, 001h, 
			0f8h, 001h, 0f5h, 0ffh, 001h, 0c0h, 000h

BWBottomResource ends
