
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spooler
FILE:		libIBM863Tab.asm

DESCRIPTION:
		Code page 863 conversion table for the top 128 bytes

	$Id: libIBM863Tab.asm,v 1.1 97/04/07 11:10:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IBM863Table	segment	resource

if	_TEXT_PRINTING
;Table	label	byte
		byte	C_SPACE	;C_UA_DIERESIS	, 0x80
		byte	C_SPACE	;C_UA_RING	, 0x81
		byte	0x80	;C_UC_CEDILLA	, 0x82
		byte	0x90	;C_UE_ACUTE	, 0x83
		byte	C_SPACE	;C_UN_TILDE	, 0x84
		byte	C_SPACE	;C_UO_DIERESIS	, 0x85
		byte	0x9a	;C_UU_DIERESIS	, 0x86
		byte	C_SPACE	;C_LA_ACUTE	, 0x87
		byte	0x85	;C_LA_GRAVE	, 0x88
		byte	0x83	;C_LA_CIRCUMFLEX, 0x89
		byte	C_SPACE	;C_LA_DIERESIS	, 0x8a
		byte	C_SPACE	;C_LA_TILDE	, 0x8b
		byte	C_SPACE	;C_LA_RING	, 0x8c
		byte	0x87	;C_LC_CEDILLA	, 0x8d
		byte	C_SPACE	;C_LE_ACUTE	, 0x8e
		byte	0x8a	;C_LE_GRAVE	, 0x8f
		byte	0x88	;C_LE_CIRCUMFLEX, 0x90
		byte	0x89	;C_LE_DIERESIS	, 0x91
		byte	C_SPACE	;C_LI_ACUTE	, 0x92
		byte	C_SPACE	;C_LI_GRAVE	, 0x93
		byte	0x8c	;C_LI_CIRCUMFLEX, 0x94
		byte	C_SPACE	;C_LI_DIERESIS	, 0x95
		byte	C_SPACE	;C_LN_TILDE	, 0x96
		byte	0xa2	;C_LO_ACUTE	, 0x97
		byte	C_SPACE	;C_LO_GRAVE	, 0x98
		byte	0x93	;C_LO_CIRCUMFLEX, 0x99
		byte	C_SPACE	;C_LO_DIERESIS	, 0x9a
		byte	C_SPACE	;C_LO_TILDE	, 0x9b
		byte	0xa3	;C_LU_ACUTE	, 0x9c
		byte	0x97	;C_LU_GRAVE	, 0x9d
		byte	0x96	;C_LU_CIRCUMFLEX, 0x9e
		byte	0x81	;C_LU_DIERESIS	, 0x9f
		byte	C_SPACE	;C_DAGGER	, 0xa0
		byte	0xf8	;C_DEGREE	, 0xa1
		byte	0x9b	;C_CENT		, 0xa2
		byte	0x9c	;C_STERLING	, 0xa3
		byte	0x8f	;C_SECTION	, 0xa4
		byte	0xf9	;C_BULLET	, 0xa5
		byte	0x86	;C_PARAGRAPH	, 0xa6
		byte	0xe1	;C_GERMANDBLS	, 0xa7
		byte	C_SPACE	;C_REGISTERED	, 0xa8
		byte	C_SPACE	;C_COPYRIGHT	, 0xa9
		byte	C_SPACE	;C_TRADEMARK	, 0xaa
		byte	0xa1	;C_ACUTE	, 0xab
		byte	0xa4	;C_DIERESIS	, 0xac
		byte	C_SPACE	;C_NOTEQUAL	, 0xad
		byte	C_SPACE	;C_U_AE		, 0xae
		byte	C_SPACE	;C_UO_SLASH	, 0xaf
		byte	0xec	;C_INFINITY	, 0xb0
		byte	0xf1	;C_PLUSMINUS	, 0xb1
		byte	0xf3	;C_LESSEQUAL	, 0xb2
		byte	0xf2	;C_GREATEREQUAL	, 0xb3
		byte	C_SPACE	;C_YEN		, 0xb4
		byte	0xe6	;C_L_MU		, 0xb5
		byte	C_SPACE	;C_L_DELTA	, 0xb6
		byte	0xe4	;C_U_SIGMA	, 0xb7
		byte	0xe3	;C_U_PI		, 0xb8
		byte	0xe3	;C_L_PI		, 0xb9
		byte	0xf4	;C_INTEGRAL	, 0xba
		byte	C_SPACE	;C_ORDFEMININE	, 0xbb
		byte	C_SPACE	;C_ORDMASCULINE	, 0xbc
		byte	0xea	;C_U_OMEGA	, 0xbd
		byte	C_SPACE	;C_L_AE		, 0xbe
		byte	C_SPACE	;C_LO_SLASH	, 0xbf
		byte	C_SPACE	;C_QUESTIONDOWN	, 0xc0
		byte	C_SPACE	;C_EXCLAMDOWN	, 0xc1
		byte	0xaa	;C_LOGICAL_NOT	, 0xc2
		byte	0xfb	;C_ROOT		, 0xc3
		byte	0x9f	;C_FLORIN	, 0xc4
		byte	0xf7	;C_APPROX_EQUAL	, 0xc5
		byte	C_SPACE	;C_U_DELTA	, 0xc6
		byte	0xae	;C_GUILLEDBLLEFT, 0xc7
		byte	0xaf	;C_GUILLEDBLRIGHT, 0xc8
		byte	C_SPACE	;C_ELLIPSIS	, 0xc9
		byte	C_SPACE	;C_NONBRKSPACE	, 0xca
		byte	0x8e	;C_UA_GRAVE	, 0xcb
		byte	C_SPACE	;C_UA_TILDE	, 0xcc
		byte	C_SPACE	;C_UO_TILDE	, 0xcd
		byte	C_SPACE	;C_U_OE		, 0xce
		byte	C_SPACE	;C_L_OE		, 0xcf
		byte	0x2d	;C_ENDASH	, 0xd0
		byte	C_SPACE	;C_EMDASH	, 0xd1
		byte	0x22	;C_QUOTEDBLLEFT	, 0xd2
		byte	0x22	;C_QUOTEDBLRIGHT, 0xd3
		byte	0x27	;C_QUOTESNGLEFT	, 0xd4
		byte	0x27	;C_QUOTESNGRIGHT, 0xd5
		byte	0xf6	;C_DIVISION	, 0xd6
		byte	C_SPACE	;C_DIAMONDBULLET, 0xd7
		byte	C_SPACE	;C_LY_DIERESIS	, 0xd8
		byte	C_SPACE	;C_UY_DIERESIS	, 0xd9
		byte	0x2f	;C_FRACTION	, 0xda
		byte	0x98	;C_CURRENCY	, 0xdb
		byte	C_SPACE	;C_GUILSNGLEFT	, 0xdc
		byte	C_SPACE	;C_GUILSNGRIGHT	, 0xdd
		byte	C_SPACE	;C_LY_ACUTE	, 0xde
		byte	C_SPACE	;C_UY_ACUTE	, 0xdf
		byte	C_SPACE	;C_DBLDAGGER	, 0xe0
		byte	0xfa	;C_CNTR_DOT	, 0xe1
		byte	0x2c	;C_SNGQUOTELOW	, 0xe2
		byte	C_SPACE	;C_DBLQUOTELOW	, 0xe3
		byte	C_SPACE	;C_PERTHOUSAND	, 0xe4
		byte	0x84	;C_UA_CIRCUMFLEX, 0xe5
		byte	0x92	;C_UE_CIRCUMFLEX, 0xe6
		byte	C_SPACE	;C_UA_ACUTE	, 0xe7
		byte	0x94	;C_UE_DIERESIS	, 0xe8
		byte	0x91	;C_UE_GRAVE	, 0xe9
		byte	0x90	;C_UI_ACUTE	, 0xea
		byte	0xa8	;C_UI_CIRCUMFLEX, 0xeb
		byte	0x95	;C_UI_DIERESIS	, 0xec
		byte	C_SPACE	;C_UI_GRAVE	, 0xed
		byte	C_SPACE	;C_UO_ACUTE	, 0xee
		byte	0x99	;C_UO_CIRCUMFLEX, 0xef
		byte	C_SPACE	;C_LOGO		, 0xf0
		byte	C_SPACE	;C_UO_GRAVE	, 0xf1
		byte	C_SPACE	;C_UU_ACUTE	, 0xf2
		byte	0x9e	;C_UU_CIRCUMFLEX, 0xf3
		byte	0x9d	;C_UU_GRAVE	, 0xf4
		byte	C_SPACE	;C_LI_DOTLESS	, 0xf5
		byte	0x5e	;C_CIRCUMFLEX	, 0xf6
		byte	C_SPACE	;C_TILDE	, 0xf7
		byte	C_SPACE	;C_MACRON	, 0xf8
		byte	C_SPACE	;C_BREVE	, 0xf9
		byte	0xfa	;C_DOTACCENT	, 0xfa
		byte	0xf8	;C_RING		, 0xfb
		byte	0xa5	;C_CEDILLA	, 0xfc
		byte	C_SPACE	;C_HUNGARUMLAT	, 0xfd
		byte	C_SPACE	;C_OGONEK	, 0xfe
		byte	C_SPACE	;C_CARON	, 0xff
endif	;_TEXT_PRINTING

IBM863Table	ends
