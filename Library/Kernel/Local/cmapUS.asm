COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Local/CharModule
FILE:		cmapUS.def

AUTHOR:		Gene Anderson, Aug 22, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/22/89		Initial revision

DESCRIPTION:
	Contains character map for IBM US code page.
		
	$Id: cmapUS.asm,v 1.1 97/04/05 01:16:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

USMap	segment	resource

codePageUS	Chars \
	C_UC_CEDILLA,		;0x80
	C_LU_DIERESIS,		;0x81
	C_LE_ACUTE,		;0x82
	C_LA_CIRCUMFLEX,	;0x83
	C_LA_DIERESIS,		;0x84
	C_LA_GRAVE,		;0x85
	C_LA_RING,		;0x86
	C_LC_CEDILLA,		;0x87
	C_LE_CIRCUMFLEX,	;0x88
	C_LE_DIERESIS,		;0x89
	C_LE_GRAVE,		;0x8a
	C_LI_DIERESIS,		;0x8b
	C_LI_CIRCUMFLEX,	;0x8c
	C_LI_GRAVE,		;0x8d
	C_UA_DIERESIS,		;0x8e
	C_UA_RING,		;0x8f
	C_UE_ACUTE,		;0x90
	C_L_AE,			;0x91
	C_U_AE,			;0x92
	C_LO_CIRCUMFLEX,	;0x93
	C_LO_DIERESIS,		;0x94
	C_LO_GRAVE,		;0x95
	C_LU_CIRCUMFLEX,	;0x96
	C_LU_GRAVE,		;0x97
	C_LY_DIERESIS,		;0x98
	C_UO_DIERESIS,		;0x99
	C_UU_DIERESIS,		;0x9a
	C_CENT,			;0x9b
	C_STERLING,		;0x9c
	C_YEN,			;0x9d
	0,			;0x9e
	C_FLORIN,		;0x9f
	C_LA_ACUTE,		;0xa0
	C_LI_ACUTE,		;0xa1
	C_LO_ACUTE,		;0xa2
	C_LU_ACUTE,		;0xa3
	C_LN_TILDE,		;0xa4
	C_UN_TILDE,		;0xa5
	C_ORDFEMININE,		;0xa6
	C_ORDMASCULINE,		;0xa7
	C_QUESTIONDOWN,		;0xa8
	0,			;0xa9
	0,			;0xaa
	0,			;0xab
	0,			;0xac
	C_EXCLAMDOWN,		;0xad
	C_GUILLEDBLLEFT,	;0xae
	C_GUILLEDBLRIGHT,	;0xaf
	0,			;0xb0	start of graphics chars
	0,			;0xb1
	0,			;0xb2
	0,			;0xb3
	0,			;0xb4
	0,			;0xb5
	0,			;0xb6
	0,			;0xb7
	0,			;0xb8
	0,			;0xb9
	0,			;0xba
	0,			;0xbb
	0,			;0xbc
	0,			;0xbd
	0,			;0xbe
	0,			;0xbf
	0,			;0xc0
	0,			;0xc1
	0,			;0xc2
	0,			;0xc3
	0,			;0xc4
	0,			;0xc5
	0,			;0xc6
	0,			;0xc7
	0,			;0xc8
	0,			;0xc9
	0,			;0xca
	0,			;0xcb
	0,			;0xcc
	0,			;0xcd
	0,			;0xce
	0,			;0xcf
	0,			;0xd0
	0,			;0xd1
	0,			;0xd2
	0,			;0xd3
	0,			;0xd4
	0,			;0xd5
	0,			;0xd6
	0,			;0xd7
	0,			;0xd8
	0,			;0xd9
	0,			;0xda
	0,			;0xdb
	0,			;0xdc
	0,			;0xdd
	0,			;0xde
	0,			;0xdf	end of graphics chars
	0,			;0xe0
	C_GERMANDBLS,		;0xe1
	0,			;0xe2
	C_L_PI,			;0xe3
	C_U_SIGMA,		;0xe4
	0,			;0xe5
	C_L_MU,			;0xe6
	0,			;0xe7
	0,			;0xe8
	0,			;0xe9
	C_U_OMEGA,		;0xea
	C_L_DELTA,		;0xeb
	C_INFINITY,		;0xec
	0,			;0xed
	0,			;0xee
	0,			;0xef
	0,			;0xf0
	C_PLUSMINUS,		;0xf1
	C_GREATEREQUAL,		;0xf2
	C_LESSEQUAL,		;0xf3
	0,			;0xf4
	C_INTEGRAL,		;0xf5
	C_DIVISION,		;0xf6
	C_APPROX_EQUAL,		;0xf7
	C_DEGREE,		;0xf8
	C_BULLET,		;0xf9
	C_CNTR_DOT,		;0xfa
	C_ROOT,			;0xfb
	0,			;0xfc
	0,			;0xfd
	0,			;0xfe
	0			;0xff

toUSCodePage	Char \
	0x8e,			; C_UA_DIERESIS,	0x80
	0x8f,			; C_UA_RING,		0x81
	0x80,			; C_UC_CEDILLA,		0x82
	0x90,			; C_UE_ACUTE,		0x83
	0xa5,			; C_UN_TILDE,		0x84
	0x99,			; C_UO_DIERESIS,	0x85
	0x9a,			; C_UU_DIERESIS,	0x86
	0xa0,			; C_LA_ACUTE,		0x87
	0x85,			; C_LA_GRAVE,		0x88
	0x83,			; C_LA_CIRCUMFLEX,	0x89
	0x84,			; C_LA_DIERESIS		0x8a
	'a',			; C_LA_TILDE,		0x8b
	0x86,			; C_LA_RING,		0x8c
	0x87,			; C_LC_CEDILLA,		0x8d
	0x82,			; C_LE_ACUTE,		0x8e
	0x8a,			; C_LE_GRAVE,		0x8f
	0x88,			; C_LE_CIRCUMFLEX,	0x90
	0x89,			; C_LE_DIERESIS,	0x91
	0xa1,			; C_LI_ACUTE,		0x92
	0x8d,			; C_LI_GRAVE,		0x93
	0x8c,			; C_LI_CIRCUMFLEX,	0x94
	0x8b,			; C_LI_DIERESIS,	0x95
	0xa4,			; C_LN_TILDE,		0x96
	0xa2,			; C_LO_ACUTE,		0x97
	0x95,			; C_LO_GRAVE,		0x98
	0x93,			; C_LO_CIRCUMFLEX,	0x99
	0x94,			; C_LO_DIERESIS		0x9a
	'o',			; C_LO_TILDE,		0x9b
	0xa3,			; C_LU_ACUTE,		0x9c
	0x97,			; C_LU_GRAVE,		0x9d
	0x96,			; C_LU_CIRCUMFLEX,	0x9e
	0x81,			; C_LU_DIERESIS,	0x9f
	0,			; C_DAGGER		0xa0
	0xf8,			; C_DEGREE,		0xa1
	0x9b,			; C_CENT,		0xa2
	0x9c,			; C_STERLING,		0xa3
	0,			; C_SECTION,		0xa4
	0xf9,			; C_BULLET,		0xa5
	0,			; C_PARAGRAPH,		0xa6
	0xe1,			; C_GERMANDBLS,		0xa7
	0,			; C_REGISTERED,		0xa8
	'c',			; C_COPYRIGHT,		0xa9
	0,			; C_TRADEMARK,		0xaa
	0,			; C_ACUTE,		0xab
	0,			; C_DIERESIS,		0xac
	0,			; C_NOTEQUAL,		0xad
	0x92,			; C_U_AE,		0xae
	'O',			; C_UO_SLASH,		0xaf
	0xec,			; C_INFINITY,		0xb0
	0xf1,			; C_PLUSMINUS,		0xb1
	0xf3,			; C_LESSEQUAL,		0xb2
	0xf2,			; C_GREATEREQUAL,	0xb3
	0x9d,			; C_YEN,		0xb4
	0xe6,			; C_L_MU,		0xb5
	0xeb,			; C_L_DELTA,		0xb6
	0xe4,			; C_U_SIGMA,		0xb7
	0,			; C_U_PI,		0xb8
	0xe3,			; C_L_PI,		0xb9
	0xf5,			; C_INTEGRAL		0xba
	0xa6,			; C_ORDFEMININE,	0xbb
	0xa7,			; C_ORDMASCULINE,	0xbc
	0xea,			; C_U_OMEGA,		0xbd
	0x91,			; C_L_AE,		0xbe
	'o',			; C_LO_SLASH,		0xbf
	0xa8,			; C_QUESTIONDOWN,	0xc0
	0xad,			; C_EXCLAMDOWN,		0xc1
	0,			; C_LOGICAL_NOT,	0xc2
	0xfb,			; C_ROOT,		0xc3
	0x9f,			; C_FLORIN,		0xc4
	0xf7,			; C_APPROX_EQUAL,	0xc5
	0,			; C_U_DELTA,		0xc6
	0xae,			; C_GUILLEDBLLEFT,	0xc7
	0xaf,			; C_GUILLEDBLRIGHT,	0xc8
	0,			; C_ELLIPSIS,		0xc9
	' ',			; C_NONBRKSPACE		0xca
	'A',			; C_UA_GRAVE,		0xcb
	'A',			; C_UA_TILDE,		0xcc
	'O',			; C_UO_TILDE,		0xcd
	'O',			; C_U_OE,		0xce
	'o',			; C_L_OE,		0xcf
	'-',			; C_ENDASH,		0xd0
	'-',			; C_EMDASH,		0xd1
	'"',			; C_QUOTEDBLLEFT,	0xd2
	'"',			; C_QUOTEDBLRIGHT,	0xd3
	'''',			; C_QUOTESNGLEFT,	0xd4
	'''',			; C_QUOTESNGRIGHT,	0xd5
	0xf6,			; C_DIVISION,		0xd6
	0,			; C_DIAMONDBULLET,	0xd7
	0x98,			; C_LY_DIERESIS,	0xd8
	'Y',			; C_UY_DIERESIS,	0xd9
	0,			; C_FRACTION		0xda
	0,			; C_CURRENCY,		0xdb
	0,			; C_GUILSNGLEFT,	0xdc
	0,			; C_GUILSNGRIGHT,	0xdd
	'y',			; C_LY_ACUTE,		0xde
	'Y',			; C_UY_ACUTE,		0xdf
	0,			; C_DBLDAGGER,		0xe0
	0xfa,			; C_CNTR_DOT,		0xe1
	0,			; C_SNGQUOTELOW,	0xe2
	0,			; C_DBLQUOTELOW,	0xe3
	0,			; C_PERTHOUSAND,	0xe4
	'A',			; C_UA_CIRCUMFLEX,	0xe5
	'E',			; C_UE_CIRCUMFLEX,	0xe6
	'A',			; C_UA_ACUTE,		0xe7
	'E',			; C_UE_DIERESIS,	0xe8
	'E',			; C_UE_GRAVE,		0xe9
	'I',			; C_UI_ACUTE		0xea
	'I',			; C_UI_CIRCUMFLEX,	0xeb
	'I',			; C_UI_DIERESIS,	0xec
	'I',			; C_UI_GRAVE,		0xed
	'O',			; C_UO_ACUTE,		0xee
	'O',			; C_UO_CIRCUMFLEX,	0xef
	0,			; C_LOGO,		0xf0
	'O',			; C_UO_GRAVE,		0xf1
	'U',			; C_UU_ACUTE,		0xf2
	'U',			; C_UU_CIRCUMFLEX,	0xf3
	'U',			; C_UU_GRAVE,		0xf4
	'i',			; C_LI_DOTLESS,		0xf5
	'^',			; C_CIRCUMFLEX,		0xf6
	'~',			; C_TILDE,		0xf7
	0,			; C_MACRON,		0xf8
	0,			; C_BREVE,		0xf9
	0,			; C_DOTACCENT		0xfa
	0,			; C_RING,		0xfb
	0,			; C_CEDILLA,		0xfc
	0,			; C_HUNGARUMLAT,	0xfd
	0,			; C_OGONEK,		0xfe
	0			; C_CARON,		0xff

	ForceRef	codePageUS
	ForceRef	toUSCodePage

USMap	ends
