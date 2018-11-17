
COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mine
FILE:           monobmp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik   2/6/92		Initial program

DESCRIPTION:
	All monochrome mine bitmaps (to be in code segment)

RCS STAMP:
	$Id: monobmp.asm,v 1.1 97/04/04 14:52:03 newdeal Exp $

------------------------------------------------------------------------------@


Mono_BM_Tile_Flagged label byte
		Bitmap <16,16,BMC_UNCOMPACTED, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	0aah, 0aah
		db	081h, 080h
		db	0d7h, 0d5h
		db	08fh, 080h
		db	0afh, 0aah
		db	081h, 080h
		db	0d4h, 0d5h
		db	080h, 080h
		db	0abh, 0eah
		db	08fh, 0f0h
		db	0dfh, 0f5h
		db	080h, 000h
		db	0aah, 0aah
		db	080h, 000h
Mono_BM_Tile_Normal label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	0aah, 0aah
		db	080h, 000h
		db	0d5h, 055h
		db	080h, 000h
		db	0aah, 0aah
		db	080h, 000h
		db	0d5h, 055h
		db	080h, 000h
		db	0aah, 0aah
		db	080h, 000h
		db	0d5h, 055h
		db	080h, 000h
		db	0aah, 0aah
		db	080h, 000h
Mono_BM_Mine_Exposed 	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 080h
		db	080h, 080h
		db	08bh, 0e8h
		db	087h, 0f0h
		db	08ch, 0f8h
		db	08ch, 0f8h
		db	0bfh, 0feh
		db	08fh, 0f8h
		db	08fh, 0f8h
		db	087h, 0f0h
		db	08bh, 0e8h
		db	080h, 080h
		db	080h, 080h
		db	080h, 000h
Mono_BM_Mine_X 	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 080h
		db	0b0h, 086h
		db	09bh, 0ech
		db	08fh, 0f8h
		db	08eh, 0f8h
		db	08fh, 0f8h
		db	0bfh, 0feh
		db	08fh, 0f8h
		db	08fh, 0f8h
		db	087h, 0f0h
		db	08fh, 0f8h
		db	098h, 08ch
		db	0b0h, 086h
		db	080h, 000h
Mono_BM_Tile_8	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	08fh, 0f0h
		db	09fh, 0f8h
		db	09ch, 038h
		db	09ch, 038h
		db	08fh, 0f0h
		db	08fh, 0f0h
		db	09ch, 038h
		db	09ch, 038h
		db	09fh, 0f8h
		db	08fh, 0f0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_7	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	09fh, 0f8h
		db	09fh, 0f8h
		db	080h, 038h
		db	080h, 038h
		db	080h, 070h
		db	080h, 070h
		db	080h, 0e0h
		db	080h, 0e0h
		db	081h, 0c0h
		db	081h, 0c0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_6	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	08fh, 0f0h
		db	09fh, 0f0h
		db	09ch, 000h
		db	09ch, 000h
		db	09fh, 0f0h
		db	09fh, 0f8h
		db	09ch, 038h
		db	09ch, 038h
		db	09fh, 0f8h
		db	08fh, 0f0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_5	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	09fh, 0f8h
		db	09fh, 0f8h
		db	09ch, 000h
		db	09ch, 000h
		db	09fh, 0f0h
		db	09fh, 0f8h
		db	080h, 038h
		db	080h, 038h
		db	09fh, 0f8h
		db	09fh, 0f0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_4	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	087h, 070h
		db	087h, 070h
		db	08eh, 070h
		db	08eh, 070h
		db	09fh, 0f8h
		db	09fh, 0f8h
		db	080h, 070h
		db	080h, 070h
		db	080h, 070h
		db	080h, 070h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_3	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	09fh, 0f0h
		db	09fh, 0f8h
		db	080h, 038h
		db	080h, 038h
		db	083h, 0f0h
		db	083h, 0f0h
		db	080h, 038h
		db	080h, 038h
		db	09fh, 0f8h
		db	09fh, 0f0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_2	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	08fh, 0f0h
		db	09fh, 0f8h
		db	09ch, 038h
		db	080h, 038h
		db	080h, 0f0h
		db	083h, 0e0h
		db	08fh, 080h
		db	09eh, 000h
		db	09fh, 0f8h
		db	09fh, 0f8h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_1	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	080h, 0c0h
		db	081h, 0c0h
		db	083h, 0c0h
		db	087h, 0c0h
		db	081h, 0c0h
		db	081h, 0c0h
		db	081h, 0c0h
		db	081h, 0c0h
		db	087h, 0f0h
		db	087h, 0f0h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
Mono_BM_Tile_0	label byte
		Bitmap <16,16,0, BMF_MONO>
		db	0ffh, 0ffh
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h
		db	080h, 000h

Mono_OffsetTable	label	word
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal
		dw offset Mono_BM_Tile_Normal, offset Mono_BM_Tile_Normal

		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged, offset Mono_BM_Tile_Flagged

		dw offset Mono_BM_Tile_0
		dw offset Mono_BM_Tile_1
		dw offset Mono_BM_Tile_2
		dw offset Mono_BM_Tile_3
		dw offset Mono_BM_Tile_4
		dw offset Mono_BM_Tile_5
		dw offset Mono_BM_Tile_6
		dw offset Mono_BM_Tile_7
		dw offset Mono_BM_Tile_8
		dw 0,0,0,0,0
		dw offset Mono_BM_Mine_Exposed
		dw offset Mono_BM_Mine_Exposed

		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw offset Mono_BM_Mine_X
		dw 0,0,0,0,0
		dw offset Mono_BM_Tile_Flagged
		dw offset Mono_BM_Tile_Flagged

