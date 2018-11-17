
COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mine
FILE:           vgabmp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik   1/92		Initial program

DESCRIPTION:
	All Vga color mine bitmaps (to be in code segment)

RCS STAMP:
	$Id: vgabmp.asm,v 1.1 97/04/04 14:51:55 newdeal Exp $

------------------------------------------------------------------------------@


BM_Tile_Flagged label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0f7h
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 078h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 07ch, 0c7h, 077h, 077h, 088h
		db	0ffh, 077h, 07ch, 0cch, 0c7h, 077h, 077h, 088h
		db	0ffh, 077h, 0cch, 0cch, 0c7h, 077h, 077h, 088h
		db	0ffh, 077h, 07ch, 0cch, 0c7h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 07ch, 0c7h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 007h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 007h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 000h, 000h, 077h, 077h, 088h
		db	0ffh, 077h, 000h, 000h, 000h, 000h, 077h, 088h
		db	0ffh, 077h, 000h, 000h, 000h, 000h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0f7h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	078h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
BM_Tile_Normal label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0f7h
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 078h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0ffh, 077h, 077h, 077h, 077h, 077h, 077h, 088h
		db	0f7h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	078h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
BM_Mine_Exposed label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	08ch, 0cch, 0cch, 0cch, 0cch, 0cch, 0cch, 0cch
		db	08ch, 0cch, 0cch, 0cch, 00ch, 0cch, 0cch, 0cch
		db	08ch, 0cch, 0cch, 0cch, 00ch, 0cch, 0cch, 0cch
		db	08ch, 0cch, 00ch, 000h, 000h, 00ch, 00ch, 0cch
		db	08ch, 0cch, 0c0h, 000h, 000h, 000h, 0cch, 0cch
		db	08ch, 0cch, 000h, 0ffh, 000h, 000h, 00ch, 0cch
		db	08ch, 0cch, 000h, 0ffh, 000h, 000h, 00ch, 0cch
		db	08ch, 000h, 000h, 000h, 000h, 000h, 000h, 00ch
		db	08ch, 0cch, 000h, 000h, 000h, 000h, 00ch, 0cch
		db	08ch, 0cch, 000h, 000h, 000h, 000h, 00ch, 0cch
		db	08ch, 0cch, 0c0h, 000h, 000h, 000h, 0cch, 0cch
		db	08ch, 0cch, 00ch, 000h, 000h, 00ch, 00ch, 0cch
		db	08ch, 0cch, 0cch, 0cch, 00ch, 0cch, 0cch, 0cch
		db	08ch, 0cch, 0cch, 0cch, 00ch, 0cch, 0cch, 0cch
		db	08ch, 0cch, 0cch, 0cch, 0cch, 0cch, 0cch, 0cch
BM_Mine_X 	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 007h, 077h, 077h, 077h
		db	087h, 0cch, 077h, 077h, 007h, 077h, 07ch, 0c7h
		db	087h, 07ch, 0c7h, 000h, 000h, 007h, 0cch, 077h
		db	087h, 077h, 0cch, 000h, 000h, 00ch, 0c7h, 077h
		db	087h, 077h, 00ch, 0cfh, 000h, 0cch, 007h, 077h
		db	087h, 077h, 000h, 0cch, 00ch, 0c0h, 007h, 077h
		db	087h, 000h, 000h, 00ch, 0cch, 000h, 000h, 007h
		db	087h, 077h, 000h, 00ch, 0cch, 000h, 007h, 077h
		db	087h, 077h, 000h, 0cch, 00ch, 0c0h, 007h, 077h
		db	087h, 077h, 07ch, 0c0h, 000h, 0cch, 077h, 077h
		db	087h, 077h, 0cch, 000h, 000h, 00ch, 0c7h, 077h
		db	087h, 07ch, 0c7h, 077h, 007h, 077h, 0cch, 077h
		db	087h, 0cch, 077h, 077h, 007h, 077h, 07ch, 0c7h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_8	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 088h, 088h, 088h, 088h, 077h, 077h
		db	087h, 078h, 088h, 088h, 088h, 088h, 087h, 077h
		db	087h, 078h, 088h, 077h, 077h, 088h, 087h, 077h
		db	087h, 078h, 088h, 077h, 077h, 088h, 087h, 077h
		db	087h, 077h, 088h, 088h, 088h, 088h, 077h, 077h
		db	087h, 077h, 088h, 088h, 088h, 088h, 077h, 077h
		db	087h, 078h, 088h, 077h, 077h, 088h, 087h, 077h
		db	087h, 078h, 088h, 077h, 077h, 088h, 087h, 077h
		db	087h, 078h, 088h, 088h, 088h, 088h, 087h, 077h
		db	087h, 077h, 088h, 088h, 088h, 088h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_7	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 070h, 000h, 000h, 000h, 000h, 007h, 077h
		db	087h, 070h, 000h, 000h, 000h, 000h, 007h, 077h
		db	087h, 077h, 077h, 077h, 077h, 000h, 007h, 077h
		db	087h, 077h, 077h, 077h, 077h, 000h, 007h, 077h
		db	087h, 077h, 077h, 077h, 070h, 000h, 077h, 077h
		db	087h, 077h, 077h, 077h, 070h, 000h, 077h, 077h
		db	087h, 077h, 077h, 077h, 000h, 007h, 077h, 077h
		db	087h, 077h, 077h, 077h, 000h, 007h, 077h, 077h
		db	087h, 077h, 077h, 070h, 000h, 077h, 077h, 077h
		db	087h, 077h, 077h, 070h, 000h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_6	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 0bbh, 0bbh, 0bbh, 0bbh, 077h, 077h
		db	087h, 07bh, 0bbh, 0bbh, 0bbh, 0bbh, 077h, 077h
		db	087h, 07bh, 0bbh, 077h, 077h, 077h, 077h, 077h
		db	087h, 07bh, 0bbh, 077h, 077h, 077h, 077h, 077h
		db	087h, 07bh, 0bbh, 0bbh, 0bbh, 0bbh, 077h, 077h
		db	087h, 07bh, 0bbh, 0bbh, 0bbh, 0bbh, 0b7h, 077h
		db	087h, 07bh, 0bbh, 077h, 077h, 0bbh, 0b7h, 077h
		db	087h, 07bh, 0bbh, 077h, 077h, 0bbh, 0b7h, 077h
		db	087h, 07bh, 0bbh, 0bbh, 0bbh, 0bbh, 0b7h, 077h
		db	087h, 077h, 0bbh, 0bbh, 0bbh, 0bbh, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_5	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 047h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 047h, 077h
		db	087h, 074h, 044h, 077h, 077h, 077h, 077h, 077h
		db	087h, 074h, 044h, 077h, 077h, 077h, 077h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 077h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 047h, 077h
		db	087h, 077h, 077h, 077h, 077h, 044h, 047h, 077h
		db	087h, 077h, 077h, 077h, 077h, 044h, 047h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 047h, 077h
		db	087h, 074h, 044h, 044h, 044h, 044h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_4	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 071h, 011h, 071h, 011h, 077h, 077h
		db	087h, 077h, 071h, 011h, 071h, 011h, 077h, 077h
		db	087h, 077h, 011h, 017h, 071h, 011h, 077h, 077h
		db	087h, 077h, 011h, 017h, 071h, 011h, 077h, 077h
		db	087h, 071h, 011h, 011h, 011h, 011h, 017h, 077h
		db	087h, 071h, 011h, 011h, 011h, 011h, 017h, 077h
		db	087h, 077h, 077h, 077h, 071h, 011h, 077h, 077h
		db	087h, 077h, 077h, 077h, 071h, 011h, 077h, 077h
		db	087h, 077h, 077h, 077h, 071h, 011h, 077h, 077h
		db	087h, 077h, 077h, 077h, 071h, 011h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_3	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 07ch, 0cch, 0cch, 0cch, 0cch, 077h, 077h
		db	087h, 07ch, 0cch, 0cch, 0cch, 0cch, 0c7h, 077h
		db	087h, 077h, 077h, 077h, 077h, 0cch, 0c7h, 077h
		db	087h, 077h, 077h, 077h, 077h, 0cch, 0c7h, 077h
		db	087h, 077h, 077h, 0cch, 0cch, 0cch, 077h, 077h
		db	087h, 077h, 077h, 0cch, 0cch, 0cch, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 0cch, 0c7h, 077h
		db	087h, 077h, 077h, 077h, 077h, 0cch, 0c7h, 077h
		db	087h, 07ch, 0cch, 0cch, 0cch, 0cch, 0c7h, 077h
		db	087h, 07ch, 0cch, 0cch, 0cch, 0cch, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_2	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 0aah, 0aah, 0aah, 0aah, 077h, 077h
		db	087h, 07ah, 0aah, 0aah, 0aah, 0aah, 0a7h, 077h
		db	087h, 07ah, 0aah, 077h, 077h, 0aah, 0a7h, 077h
		db	087h, 077h, 077h, 077h, 077h, 0aah, 0a7h, 077h
		db	087h, 077h, 077h, 077h, 0aah, 0aah, 077h, 077h
		db	087h, 077h, 077h, 0aah, 0aah, 0a7h, 077h, 077h
		db	087h, 077h, 0aah, 0aah, 0a7h, 077h, 077h, 077h
		db	087h, 07ah, 0aah, 0a7h, 077h, 077h, 077h, 077h
		db	087h, 07ah, 0aah, 0aah, 0aah, 0aah, 0a7h, 077h
		db	087h, 07ah, 0aah, 0aah, 0aah, 0aah, 0a7h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_1	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 079h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 099h, 099h, 077h, 077h, 077h
		db	087h, 077h, 079h, 099h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 079h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 079h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 079h, 099h, 077h, 077h, 077h
		db	087h, 077h, 077h, 079h, 099h, 077h, 077h, 077h
		db	087h, 077h, 079h, 099h, 099h, 099h, 077h, 077h
		db	087h, 077h, 079h, 099h, 099h, 099h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
BM_Tile_0	label byte
		Bitmap <16,16,0, BMF_4BIT>
		db	088h, 088h, 088h, 088h, 088h, 088h, 088h, 088h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h
		db	087h, 077h, 077h, 077h, 077h, 077h, 077h, 077h

OffsetTable	label	word
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal
		dw offset BM_Tile_Normal, offset BM_Tile_Normal

		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged, offset BM_Tile_Flagged

		dw offset BM_Tile_0
		dw offset BM_Tile_1
		dw offset BM_Tile_2
		dw offset BM_Tile_3
		dw offset BM_Tile_4
		dw offset BM_Tile_5
		dw offset BM_Tile_6
		dw offset BM_Tile_7
		dw offset BM_Tile_8
		dw 0,0,0,0,0
		dw offset BM_Mine_Exposed
		dw offset BM_Mine_Exposed

		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw offset BM_Mine_X
		dw 0,0,0,0,0
		dw offset BM_Tile_Flagged
		dw offset BM_Tile_Flagged

