
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool
FILE:		libWindows8bitTab.asm

DESCRIPTION:
	conversion table for upper 128 characters of the GEOS symbol set to
	Windows symbol set.
		

	$Id: libWindows8bitTab.asm,v 1.1 97/04/07 11:10:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WindowsTable	segment	resource

if	_TEXT_PRINTING
; WindowsTab:
	byte	196	;C_UA_DIERESIS	, 0x80
	byte	197	;C_UA_RING	, 0x81
	byte	199	;C_UC_CEDILLA	, 0x82
	byte	201	;C_UE_ACUTE	, 0x83
	byte	209	;C_UN_TILDE	, 0x84
	byte	214	;C_UO_DIERESIS	, 0x85
	byte	220	;C_UU_DIERESIS	, 0x86
	byte	225	;C_LA_ACUTE	, 0x87
	byte	224	;C_LA_GRAVE	, 0x88
	byte	226	;C_LA_CIRCUMFLEX, 0x89
	byte	228	;C_LA_DIERESIS	, 0x8a
	byte	227	;C_LA_TILDE	, 0x8b
	byte	229	;C_LA_RING	, 0x8c
	byte	231	;C_LC_CEDILLA	, 0x8d
	byte	233	;C_LE_ACUTE	, 0x8e
	byte	232	;C_LE_GRAVE	, 0x8f
	byte	234	;C_LE_CIRCUMFLEX, 0x90
	byte	235	;C_LE_DIERESIS	, 0x91
	byte	237	;C_LI_ACUTE	, 0x92
	byte	236	;C_LI_GRAVE	, 0x93
	byte	238	;C_LI_CIRCUMFLEX, 0x94
	byte	239	;C_LI_DIERESIS	, 0x95
	byte	241	;C_LN_TILDE	, 0x96
	byte	243	;C_LO_ACUTE	, 0x97
	byte	242	;C_LO_GRAVE	, 0x98
	byte	244	;C_LO_CIRCUMFLEX, 0x99
	byte	246	;C_LO_DIERESIS	, 0x9a
	byte	245	;C_LO_TILDE	, 0x9b
	byte	250	;C_LU_ACUTE	, 0x9c
	byte	249	;C_LU_GRAVE	, 0x9d
	byte	251	;C_LU_CIRCUMFLEX, 0x9e
	byte	252	;C_LU_DIERESIS	, 0x9f
	byte	C_SPACE	;C_DAGGER	, 0xa0
	byte	176	;C_DEGREE	, 0xa1
	byte	162	;C_CENT		, 0xa2
	byte	163	;C_STERLING	, 0xa3
	byte	167	;C_SECTION	, 0xa4
	byte	C_SPACE	;C_BULLET	, 0xa5
	byte	182	;C_PARAGRAPH	, 0xa6
	byte	223	;C_GERMANDBLS	, 0xa7
	byte	174	;C_REGISTERED	, 0xa8
	byte	169	;C_COPYRIGHT	, 0xa9
	byte	C_SPACE	;C_TRADEMARK	, 0xaa
	byte	180	;C_ACUTE	, 0xab
	byte	168	;C_DIERESIS	, 0xac
	byte	C_SPACE	;C_NOTEQUAL	, 0xad
	byte	198	;C_U_AE		, 0xae
	byte	216	;C_UO_SLASH	, 0xaf
	byte	C_SPACE	;C_INFINITY	, 0xb0
	byte	177	;C_PLUSMINUS	, 0xb1
	byte	C_SPACE	;C_LESSEQUAL	, 0xb2
	byte	C_SPACE	;C_GREATEREQUAL	, 0xb3
	byte	165	;C_YEN		, 0xb4
	byte	181	;C_L_MU		, 0xb5
	byte	C_SPACE	;C_L_DELTA	, 0xb6
	byte	C_SPACE	;C_U_SIGMA	, 0xb7
	byte	C_SPACE	;C_U_PI		, 0xb8
	byte	C_SPACE	;C_L_PI		, 0xb9
	byte	C_SPACE	;C_INTEGRAL	, 0xba
	byte	170	;C_ORDFEMININE	, 0xbb
	byte	186	;C_ORDMASCULINE	, 0xbc
	byte	C_SPACE	;C_U_OMEGA	, 0xbd
	byte	230	;C_L_AE		, 0xbe
	byte	248	;C_LO_SLASH	, 0xbf
	byte	191	;C_QUESTIONDOWN	, 0xc0
	byte	161	;C_EXCLAMDOWN	, 0xc1
	byte	172	;C_LOGICAL_NOT	, 0xc2
	byte	C_SPACE	;C_ROOT		, 0xc3
	byte	C_SPACE	;C_FLORIN	, 0xc4
	byte	C_SPACE	;C_APPROX_EQUAL	, 0xc5
	byte	C_SPACE	;C_U_DELTA	, 0xc6
	byte	171	;C_GUILLEDBLLEFT, 0xc7
	byte	187	;C_GUILLEDBLRIGHT, 0xc8
	byte	C_SPACE	;C_ELLIPSIS	, 0xc9
	byte	C_SPACE	;C_NONBRKSPACE	, 0xca
	byte	192	;C_UA_GRAVE	, 0xcb
	byte	195	;C_UA_TILDE	, 0xcc
	byte	213	;C_UO_TILDE	, 0xcd
	byte	C_SPACE	;C_U_OE		, 0xce
	byte	C_SPACE	;C_L_OE		, 0xcf
	byte	173	;C_ENDASH	, 0xd0
	byte	C_SPACE	;C_EMDASH	, 0xd1
	byte	0x22	;C_QUOTEDBLLEFT	, 0xd2
	byte	0x22	;C_QUOTEDBLRIGHT, 0xd3
	byte	145	;C_QUOTESNGLEFT	, 0xd4
	byte	146	;C_QUOTESNGRIGHT, 0xd5
	byte	C_SPACE	;C_DIVISION	, 0xd6
	byte	C_SPACE	;C_DIAMONDBULLET, 0xd7
	byte	255	;C_LY_DIERESIS	, 0xd8
	byte	C_SPACE	;C_UY_DIERESIS	, 0xd9
	byte	47	;C_FRACTION	, 0xda
	byte	164	;C_CURRENCY	, 0xdb
	byte	C_SPACE	;C_GUILSNGLEFT	, 0xdc
	byte	C_SPACE	;C_GUILSNGRIGHT	, 0xdd
	byte	253	;C_LY_ACUTE	, 0xde
	byte	221	;C_UY_ACUTE	, 0xdf
	byte	C_SPACE	;C_DBLDAGGER	, 0xe0
	byte	183	;C_CNTR_DOT	, 0xe1
	byte	0x2c	;C_SNGQUOTELOW	, 0xe2
	byte	C_SPACE	;C_DBLQUOTELOW	, 0xe3
	byte	C_SPACE	;C_PERTHOUSAND	, 0xe4
	byte	194	;C_UA_CIRCUMFLEX, 0xe5
	byte	202	;C_UE_CIRCUMFLEX, 0xe6
	byte	193	;C_UA_ACUTE	, 0xe7
	byte	203	;C_UE_DIERESIS	, 0xe8
	byte	200	;C_UE_GRAVE	, 0xe9
	byte	205	;C_UI_ACUTE	, 0xea
	byte	206	;C_UI_CIRCUMFLEX, 0xeb
	byte	207	;C_UI_DIERESIS	, 0xec
	byte	204	;C_UI_GRAVE	, 0xed
	byte	211	;C_UO_ACUTE	, 0xee
	byte	212	;C_UO_CIRCUMFLEX, 0xef
	byte	C_SPACE	;C_LOGO		, 0xf0
	byte	210	;C_UO_GRAVE	, 0xf1
	byte	218	;C_UU_ACUTE	, 0xf2
	byte	219	;C_UU_CIRCUMFLEX, 0xf3
	byte	217	;C_UU_GRAVE	, 0xf4
	byte	C_SPACE	;C_LI_DOTLESS	, 0xf5
	byte	94	;C_CIRCUMFLEX	, 0xf6
	byte	126	;C_TILDE	, 0xf7
	byte	175	;C_MACRON	, 0xf8
	byte	C_SPACE	;C_BREVE	, 0xf9
	byte	C_SPACE	;C_DOTACCENT	, 0xfa
	byte	176	;C_RING		, 0xfb
	byte	184	;C_CEDILLA	, 0xfc
	byte	C_SPACE	;C_HUNGARUMLAT	, 0xfd
	byte	C_SPACE	;C_OGONEK	, 0xfe
	byte	C_SPACE	;C_CARON	, 0xff
endif	;_TEXT_PRINTING

WindowsTable	ends
