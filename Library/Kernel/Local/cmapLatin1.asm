COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Local
FILE:		cmapLatin1.asm

AUTHOR:		Chris Hawley-Ruppel, 5/25/95

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/22/89		Initial revision
	cbh	5/25/95		Stolen for Latin 1

DESCRIPTION:
	Contains character map for Latin 1 code page.
		
	$Id: cmapLatin1.asm,v 1.1 97/04/05 01:17:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Latin1Map	segment	resource

codePageLatin1	Chars \
	0,			;0x80
	0,			;0x81
	C_SNGQUOTELOW,		;0x82
	C_FLORIN,		;0x83
	C_DBLQUOTELOW,		;0x84
	C_ELLIPSIS,		;0x85
	C_DAGGER,		;0x86
	C_DBLDAGGER,		;0x87
	C_CIRCUMFLEX,		;0x88
	C_PERTHOUSAND,		;0x89
	0,			;0x8a
	C_GUILSNGLEFT,		;0x8b
	C_U_OE,			;0x8c
	0,			;0x8d
	0,			;0x8e
	0,			;0x8f
	0,			;0x90
	C_QUOTESNGLEFT,		;0x91
	C_QUOTESNGRIGHT,	;0x92
	C_QUOTEDBLLEFT,		;0x93
	C_QUOTEDBLRIGHT,	;0x94
	C_BULLET,		;0x95
	C_ENDASH,		;0x96
	C_EMDASH,		;0x97
	C_TILDE,		;0x98
	C_TRADEMARK,		;0x99
	0,			;0x9a
	C_GUILSNGRIGHT,		;0x9b
	C_L_OE,			;0x9c
	0,			;0x9d
	0,			;0x9e
	C_UY_DIERESIS,		;0x9f
	C_NONBRKSPACE,		;0xa0
	C_EXCLAMDOWN,		;0xa1
	C_CENT,			;0xa2
	C_STERLING,		;0xa3
	C_CURRENCY,		;0xa4
	C_YEN,			;0xa5
	C_VERTICAL_BAR,		;0xa6
	C_SECTION,		;0xa7
	C_DIERESIS,		;0xa8
	C_COPYRIGHT,		;0xa9
	C_ORDFEMININE,		;0xaa
	C_GUILLEDBLLEFT,	;0xab
	C_LOGICAL_NOT,		;0xac
	C_OPTHYPHEN,		;0xad
	C_REGISTERED,		;0xae
	C_MACRON,		;0xaf
	C_DEGREE,		;0xb0	
	C_PLUSMINUS,		;0xb1
	0,			;0xb2
	0,			;0xb3
	C_ACUTE,		;0xb4
	C_L_MU,			;0xb5
	C_PARAGRAPH,		;0xb6
	C_CNTR_DOT,		;0xb7
	C_CEDILLA,		;0xb8
	0,			;0xb9
	C_ORDMASCULINE,		;0xba
	C_GUILLEDBLRIGHT,	;0xbb
	0,			;0xbc
	0,			;0xbd
	0,			;0xbe
	C_QUESTIONDOWN,		;0xbf
	C_UA_GRAVE,		;0xc0
	C_UA_ACUTE,		;0xc1
	C_UA_CIRCUMFLEX,	;0xc2
	C_UA_TILDE,		;0xc3
	C_UA_DIERESIS,		;0xc4
	C_UA_RING,		;0xc5
	C_U_AE,			;0xc6
	C_UC_CEDILLA,		;0xc7
	C_UE_GRAVE,		;0xc8
	C_UE_ACUTE,		;0xc9
	C_UE_CIRCUMFLEX,	;0xca
	C_UE_DIERESIS,		;0xcb
	C_UI_GRAVE,		;0xcc
	C_UI_ACUTE,		;0xcd
	C_UI_CIRCUMFLEX,	;0xce
	C_UI_DIERESIS,		;0xcf
	0,			;0xd0
	C_UN_TILDE,		;0xd1
	C_UO_GRAVE,		;0xd2
	C_UO_ACUTE,		;0xd3
	C_UO_CIRCUMFLEX,	;0xd4
	C_UO_TILDE,		;0xd5
	C_UO_DIERESIS,		;0xd6
	C_SMALL_X,		;0xd7
	C_UO_SLASH,		;0xd8
	C_UU_GRAVE,		;0xd9
	C_UU_ACUTE,		;0xda
	C_UU_CIRCUMFLEX,	;0xdb
	C_UU_DIERESIS,		;0xdc
	C_UY_ACUTE,		;0xdd
	0,			;0xde
	C_GERMANDBLS,		;0xdf	
	C_LA_GRAVE,		;0xe0
	C_LA_ACUTE,		;0xe1
	C_LA_CIRCUMFLEX,	;0xe2
	C_LA_TILDE,		;0xe3
	C_LA_DIERESIS,		;0xe4
	C_LA_RING,		;0xe5
	C_L_AE,			;0xe6
	C_LC_CEDILLA,		;0xe7
	C_LE_GRAVE,		;0xe8
	C_LE_ACUTE,		;0xe9
	C_LE_CIRCUMFLEX,	;0xea
	C_LE_DIERESIS,		;0xeb
	C_LI_GRAVE,		;0xec
	C_LI_ACUTE,		;0xed
	C_LI_CIRCUMFLEX,	;0xee
	C_LI_DIERESIS,		;0xef
	0,			;0xf0
	C_LN_TILDE,		;0xf1
	C_LO_GRAVE,		;0xf2
	C_LO_ACUTE,		;0xf3
	C_LO_CIRCUMFLEX,	;0xf4
	C_LO_TILDE,		;0xf5
	C_LO_DIERESIS,		;0xf6
	C_DIVISION,		;0xf7
	C_LO_SLASH,		;0xf8
	C_LU_GRAVE,		;0xf9
	C_LU_ACUTE,		;0xfa
	C_LU_CIRCUMFLEX,	;0xfb
	C_LU_DIERESIS,		;0xfc
	C_LY_ACUTE,		;0xfd
	0,			;0xfe
	C_LY_DIERESIS		;0xff	

toLatin1CodePage	Char \
	0xc4,			; C_UA_DIERESIS,	0x80
	0xc5,			; C_UA_RING,		0x81
	0xc7,			; C_UC_CEDILLA,		0x82
	0xc9,			; C_UE_ACUTE,		0x83
	0xd1,			; C_UN_TILDE,		0x84
	0xd6,			; C_UO_DIERESIS,	0x85
	0xdc,			; C_UU_DIERESIS,	0x86
	0xe1,			; C_LA_ACUTE,		0x87
	0xe0,			; C_LA_GRAVE,		0x88
	0xe2,			; C_LA_CIRCUMFLEX,	0x89
	0xe4,			; C_LA_DIERESIS		0x8a
	0xe3,			; C_LA_TILDE,		0x8b
	0xe5,			; C_LA_RING,		0x8c
	0xe7,			; C_LC_CEDILLA,		0x8d
	0xe9,			; C_LE_ACUTE,		0x8e
	0xe8,			; C_LE_GRAVE,		0x8f
	0xea,			; C_LE_CIRCUMFLEX,	0x90
	0xeb,			; C_LE_DIERESIS,	0x91
	0xed,			; C_LI_ACUTE,		0x92
	0xec,			; C_LI_GRAVE,		0x93
	0xee,			; C_LI_CIRCUMFLEX,	0x94
	0xef,			; C_LI_DIERESIS,	0x95
	0xf1,			; C_LN_TILDE,		0x96
	0xf3,			; C_LO_ACUTE,		0x97
	0xf2,			; C_LO_GRAVE,		0x98
	0xf4,			; C_LO_CIRCUMFLEX,	0x99
	0xf6,			; C_LO_DIERESIS		0x9a
	0xf5,			; C_LO_TILDE,		0x9b
	0xfa,			; C_LU_ACUTE,		0x9c
	0xf9,			; C_LU_GRAVE,		0x9d
	0xfb,			; C_LU_CIRCUMFLEX,	0x9e
	0xfc,			; C_LU_DIERESIS,	0x9f
	0x86,			; C_DAGGER		0xa0
	0xb0,			; C_DEGREE,		0xa1
	0xa2,			; C_CENT,		0xa2
	0xa3,			; C_STERLING,		0xa3
	0xa7,			; C_SECTION,		0xa4
	0x95,			; C_BULLET,		0xa5
	0xb6,			; C_PARAGRAPH,		0xa6
	0xdf,			; C_GERMANDBLS,		0xa7
	0xae,			; C_REGISTERED,		0xa8
	0xa9,			; C_COPYRIGHT,		0xa9
	0x99,			; C_TRADEMARK,		0xaa
	0xb4,			; C_ACUTE,		0xab
	0xa8,			; C_DIERESIS,		0xac
	0,			; C_NOTEQUAL,		0xad
	0xc6,			; C_U_AE,		0xae
	0xd8,			; C_UO_SLASH,		0xaf
	0,			; C_INFINITY,		0xb0
	0xb1,			; C_PLUSMINUS,		0xb1
	0,			; C_LESSEQUAL,		0xb2
	0,			; C_GREATEREQUAL,	0xb3
	0xa5,			; C_YEN,		0xb4
	0xb5,			; C_L_MU,		0xb5
	0,			; C_L_DELTA,		0xb6
	0,			; C_U_SIGMA,		0xb7
	0,			; C_U_PI,		0xb8
	0,			; C_L_PI,		0xb9
	0,			; C_INTEGRAL		0xba
	0xaa,			; C_ORDFEMININE,	0xbb
	0xba,			; C_ORDMASCULINE,	0xbc
	0,			; C_U_OMEGA,		0xbd
	0xe6,			; C_L_AE,		0xbe
	0xf8,			; C_LO_SLASH,		0xbf
	0xbf,			; C_QUESTIONDOWN,	0xc0
	0xa1,			; C_EXCLAMDOWN,		0xc1
	0xac,			; C_LOGICAL_NOT,	0xc2
	0,			; C_ROOT,		0xc3
	0x83,			; C_FLORIN,		0xc4
	0,			; C_APPROX_EQUAL,	0xc5
	0,			; C_U_DELTA,		0xc6
	0xab,			; C_GUILLEDBLLEFT,	0xc7
	0xbb,			; C_GUILLEDBLRIGHT,	0xc8
	0,			; C_ELLIPSIS,		0xc9
	0xa0,			; C_NONBRKSPACE		0xca
	0xc0,			; C_UA_GRAVE,		0xcb
	0xc3,			; C_UA_TILDE,		0xcc
	0xd5,			; C_UO_TILDE,		0xcd
	0x8c,			; C_U_OE,		0xce
	0x9c,			; C_L_OE,		0xcf
	0x96,			; C_ENDASH,		0xd0
	0x97,			; C_EMDASH,		0xd1
	0x93,			; C_QUOTEDBLLEFT,	0xd2
	0x94,			; C_QUOTEDBLRIGHT,	0xd3
	0x91,			; C_QUOTESNGLEFT,	0xd4
	0x92,			; C_QUOTESNGRIGHT,	0xd5
	0xf7,			; C_DIVISION,		0xd6
	0,			; C_DIAMONDBULLET,	0xd7
	0xff,			; C_LY_DIERESIS,	0xd8
	0x9f,			; C_UY_DIERESIS,	0xd9
	0,			; C_FRACTION		0xda
	0xa4,			; C_CURRENCY,		0xdb
	0x8b,			; C_GUILSNGLEFT,	0xdc
	0x9b,			; C_GUILSNGRIGHT,	0xdd
	0xfd,			; C_LY_ACUTE,		0xde
	0xdd,			; C_UY_ACUTE,		0xdf
	0x87,			; C_DBLDAGGER,		0xe0
	0xb7,			; C_CNTR_DOT,		0xe1
	0x82,			; C_SNGQUOTELOW,	0xe2
	0x84,			; C_DBLQUOTELOW,	0xe3
	0x89,			; C_PERTHOUSAND,	0xe4
	0xc2,			; C_UA_CIRCUMFLEX,	0xe5
	0xca,			; C_UE_CIRCUMFLEX,	0xe6
	0xc1,			; C_UA_ACUTE,		0xe7
	0xcb,			; C_UE_DIERESIS,	0xe8
	0xc8,			; C_UE_GRAVE,		0xe9
	0xcd,			; C_UI_ACUTE		0xea
	0xce,			; C_UI_CIRCUMFLEX,	0xeb
	0xcf,			; C_UI_DIERESIS,	0xec
	0xcc,			; C_UI_GRAVE,		0xed
	0xd3,			; C_UO_ACUTE,		0xee
	0xd4,			; C_UO_CIRCUMFLEX,	0xef
	0,			; C_LOGO,		0xf0
	0xd2,			; C_UO_GRAVE,		0xf1
	0xda,			; C_UU_ACUTE,		0xf2
	0xdb,			; C_UU_CIRCUMFLEX,	0xf3
	0xd9,			; C_UU_GRAVE,		0xf4
	'i',			; C_LI_DOTLESS,		0xf5
	0x88,			; C_CIRCUMFLEX,		0xf6
	0x98,			; C_TILDE,		0xf7
	0,			; C_MACRON,		0xf8
	0,			; C_BREVE,		0xf9
	0,			; C_DOTACCENT		0xfa
	0,			; C_RING,		0xfb
	0xb8,			; C_CEDILLA,		0xfc
	0,			; C_HUNGARUMLAT,	0xfd
	0,			; C_OGONEK,		0xfe
	0			; C_CARON,		0xff

	ForceRef	codePageLatin1
	ForceRef	toLatin1CodePage

Latin1Map	ends
