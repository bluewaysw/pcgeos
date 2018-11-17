COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		stringCharTables.asm

AUTHOR:		Gene Anderson, Dec 10, 1990

TABLES:
	Name			Description
	----			-----------
	CharClassTable		table of character classes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/10/90	Initial revision
	schoon  4/13/92		Updated to Ansi C standard

DESCRIPTION:
	tables for character/string classes

	$Id: stringCharTables.asm,v 1.1 97/04/05 01:16:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringCmpMod	segment	resource
;	      A P S L S U L C D H P G
;	      L U P I Y P O O I E R R 
;	      P N A G M P W N G X I A
;	      H C C A B E E T I   N P
;	      A T E T O R R R T   T H
CharClassTable	\
    CharClass<0,0,0,0,0,0,0,0,0,0,0,0,0>,	; C_NULL,		0x0
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_A,		0x1
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_B,		0x2
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_C,		0x3
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_D,		0x4
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_E,		0x5
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_F,		0x6
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_G,		0x7
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_H,		0x8
    CharClass<0,0,1,0,0,0,0,1,0,0,0,0,0>,	; C_TAB,		0x9
    CharClass<0,0,1,0,0,0,0,1,0,0,0,0,0>,	; C_LINEFEED,		0xa
    CharClass<0,0,1,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_K,		0xb
    CharClass<0,0,1,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_L,		0xc
    CharClass<0,0,1,0,0,0,0,1,0,0,0,0,0>,	; C_ENTER,		0xd
    CharClass<0,0,0,0,0,0,0,0,0,0,0,0,0>,	; C_SHIFT_OUT,		0xe
    CharClass<0,0,0,0,0,0,0,0,0,0,0,0,0>,	; C_SHIFT_IN,		0xf
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_P,		0x10
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_Q,		0x11
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_R,		0x12
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_S,		0x13
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_T,		0x14
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_U,		0x15
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_V,		0x16
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_W,		0x17
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_CTRL_X,		0x18
    CharClass<0,0,0,0,0,0,0,0,0,0,0,0,0>,	; C_NULL_WIDTH,		0x19
    CharClass<0,0,0,0,1,0,0,0,0,0,0,0,0>,	; C_GRAPHIC,		0x1a
    CharClass<0,0,1,0,0,0,0,0,0,0,0,0,0>,	; C_THINSPACE,		0x1b
    CharClass<0,0,1,0,0,0,0,0,0,0,0,0,0>,	; C_ENSPACE,		0x1c
    CharClass<0,0,1,0,0,0,0,0,0,0,0,0,0>,	; C_EMSPACE,		0x1d
    CharClass<0,1,0,0,1,0,0,0,0,0,0,0,0>,	; C_NONBRKHYPHEN,	0x1e
    CharClass<0,1,0,0,1,0,0,0,0,0,0,0,0>,	; C_OPTHYPHEN,		0x1f
    CharClass<0,0,1,0,0,0,0,0,0,0,1,0,0>,	; C_SPACE,		' '
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_EXCLAMATION,	'!'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_QUOTE,		'"'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_NUMBER_SIGN,	'#'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DOLLAR_SIGN,	'$'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PERCENT,		'%'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_AMPERSAND,		'&'
    CharClass<0,1,0,0,1,0,0,0,0,0,1,1,0>,	; C_SNG_QUOTE,		0x27
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_LEFT_PAREN,		'('
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_RIGHT_PAREN,	')'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ASTERISK,		'*'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PLUS,		'+'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_COMMA,		','
    CharClass<0,1,0,0,1,0,0,0,0,0,1,1,0>,	; C_MINUS,		'-'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PERIOD,		'.'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_SLASH,		'/'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_ZERO,		'0'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_ONE,		'1'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_TWO,		'2'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_THREE,		'3'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_FOUR,		'4'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_FIVE,		'5'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_SIX,		'6'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_SEVEN,		'7'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_EIGHT,		'8'
    CharClass<0,0,0,0,0,0,0,0,1,1,1,1,0>,	; C_NINE,		'9'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_COLON,		':'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_SEMICOLON,		';'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_LESS_THAN,		'<'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_EQUAL,		'='
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GREATER_THAN,	'>'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_QUESTION_MARK,	'?'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_AT_SIGN,		'@'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_A,		'A'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_B,		'B'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_C,		'C'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_D,		'D'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_E,		'E'
    CharClass<1,0,0,0,0,1,0,0,0,1,1,1,0>,	; C_CAP_F,		'F'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_G,		'G'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_H,		'H'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_I,		'I'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_J,		'J'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_K,		'K'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_L,		'L'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_M,		'M'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_N,		'N'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_O,		'O'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_P,		'P'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_Q,		'Q'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_R,		'R'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_S,		'S'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_T,		'T'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_U,		'U'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_V,		'V'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_W,		'W'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_X,		'X'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_Y,		'Y'
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_CAP_Z,		'Z'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_LEFT_BRACKET,	'['
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_BACKSLASH,		0x5c
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_RIGHT_BRACKET,	']'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ASCII_CIRCUMFLEX,	'^'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_UNDERSCORE,		'_'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_BACKQUOTE,		'`'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_A,		'a'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_B,		'b'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_C,		'c'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_D,		'd'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_E,		'e'
    CharClass<1,0,0,0,0,0,1,0,0,1,1,1,0>,	; C_SMALL_F,		'f'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_G,		'g'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_H,		'h'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_I,		'i'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_J,		'j'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_K,		'k'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_L,		'l'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_M,		'm'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_N,		'n'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_O,		'o'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_P,		'p'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_Q,		'q'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_R,		'r'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_S,		's'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_T,		't'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_U,		'u'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_V,		'v'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_W,		'w'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_X,		'x'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_Y,		'y'
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_SMALL_Z,		'z'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_LEFT_BRACE,		'{'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_VERTICAL_BAR,	'|'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_RIGHT_BRACE,	'}'
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ASCII_TILDE,	'~'
    CharClass<0,0,0,0,0,0,0,1,0,0,0,0,0>,	; C_DELETE,		0x7f
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UA_DIERESIS,	0x80
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UA_RING,		0x81
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UC_CEDILLA,		0x82
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UE_ACUTE,		0x83
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UN_TILDE,		0x84
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UO_DIERESIS,	0x85
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UU_DIERESIS,	0x86
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LA_ACUTE,		0x87
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LA_GRAVE,		0x88
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LA_CIRCUMFLEX,	0x89
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LA_DIERESIS,	0x8a
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LA_TILDE,		0x8b
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LA_RING,		0x8c
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LC_CEDILLA,		0x8d
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LE_ACUTE,		0x8e
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LE_GRAVE,		0x8f
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LE_CIRCUMFLEX,	0x90
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LE_DIERESIS,	0x91
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LI_ACUTE,		0x92
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LI_GRAVE,		0x93
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LI_CIRCUMFLEX,	0x94
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LI_DIERESIS,	0x95
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LN_TILDE,		0x96
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LO_ACUTE,		0x97
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LO_GRAVE,		0x98
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LO_CIRCUMFLEX,	0x99
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LO_DIERESIS,	0x9a
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LO_TILDE,		0x9b
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LU_ACUTE,		0x9c
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LU_GRAVE,		0x9d
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LU_CIRCUMFLEX,	0x9e
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LU_DIERESIS,	0x9f
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DAGGER,		0xa0
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DEGREE,		0xa1
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_CENT,		0xa2
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_STERLING,		0xa3
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_SECTION,		0xa4
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_BULLET,		0xa5
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PARAGRAPH,		0xa6
    CharClass<1,0,0,1,0,1,1,0,0,0,1,1,0>,	; C_GERMANDBLS,		0xa7
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_REGISTERED,		0xa8
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_COPYRIGHT,		0xa9
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_TRADEMARK,		0xaa
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ACUTE,		0xab
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DIERESIS,		0xac
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_NOTEQUAL,		0xad
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_U_AE,		0xae
    CharClass<1,0,0,0,0,0,0,0,0,0,1,1,0>,	; C_UO_SLASH,		0xaf
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_INFINITY,		0xb0
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PLUSMINUS,		0xb1
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_LESSEQUAL,		0xb2
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GREATEREQUAL,	0xb3
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_YEN,		0xb4
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_L_MU,		0xb5
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_L_DELTA,		0xb6
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_U_SIGMA,		0xb7
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_U_PI,		0xb8
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_L_PI,		0xb9
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_INTEGRAL,		0xba
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ORDFEMININE,	0xbb
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ORDMASCULINE,	0xbc
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_U_OMEGA,		0xbd
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_L_AE,		0xbe
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LO_SLASH,		0xbf
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_QUESTIONDOWN,	0xc0
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_EXCLAMDOWN,		0xc1
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_LOGICAL_NOT,	0xc2
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_ROOT,		0xc3
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_FLORIN,		0xc4
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_APPROX_EQUAL,	0xc5
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_U_DELTA,		0xc6
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GUILLEDBLLEFT,	0xc7
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GUILLEDBLRIGHT,	0xc8
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_ELLIPSIS,		0xc9
    CharClass<0,0,1,0,0,0,0,0,0,0,0,0,0>,	; C_NONBRKSPACE,	0xca
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UA_GRAVE,		0xcb
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UA_TILDE,		0xcc
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UO_TILDE,		0xcd
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_U_OE,		0xce
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_L_OE,		0xcf
    CharClass<0,1,0,0,1,0,0,0,0,0,1,1,0>,	; C_ENDASH,		0xd0
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_EMDASH,		0xd1
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_QUOTEDBLLEFT,	0xd2
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_QUOTEDBLRIGHT,	0xd3
    CharClass<0,1,0,0,1,0,0,0,0,0,1,1,0>,	; C_QUOTESNGLEFT,	0xd4
    CharClass<0,1,0,0,1,0,0,0,0,0,1,1,0>,	; C_QUOTESNGRIGHT,	0xd5
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DIVISION,		0xd6
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DIAMONDBULLET,	0xd7
    CharClass<1,0,0,1,0,0,1,0,0,0,1,1,0>,	; C_LY_DIERESIS,	0xd8
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UY_DIERESIS,	0xd9
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_FRACTION,		0xda
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_CURRENCY,		0xdb
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GUILSNGLEFT,	0xdc
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_GUILSNGRIGHT,	0xdd
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LY_ACUTE,		0xde
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UY_ACUTE,		0xdf
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DBLDAGGER,		0xe0
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_CNTR_DOT,		0xe1
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_SNGQUOTELOW,	0xe2
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DBLQUOTELOW,	0xe3
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_PERTHOUSAND,	0xe4
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UA_CIRCUMFLEX,	0xe5
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UE_CIRCUMFLEX,	0xe6
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UA_ACUTE,		0xe7
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UE_DIERESIS,	0xe8
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UE_GRAVE,		0xe9
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UI_ACUTE,		0xea
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UI_CIRCUMFLEX,	0xeb
    CharClass<1,0,0,1,0,1,0,0,0,0,1,1,0>,	; C_UI_DIERESIS,	0xec
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UI_GRAVE,		0xed
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UO_ACUTE,		0xee
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UO_CIRCUMFLEX,	0xef
    CharClass<0,0,0,0,1,0,0,0,0,0,1,1,0>,	; C_LOGO,		0xf0
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UO_GRAVE,		0xf1
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UU_ACUTE,		0xf2
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UU_CIRCUMFLEX,	0xf3
    CharClass<1,0,0,0,0,1,0,0,0,0,1,1,0>,	; C_UU_GRAVE,		0xf4
    CharClass<1,0,0,0,0,0,1,0,0,0,1,1,0>,	; C_LI_DOTLESS,		0xf5
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_CIRCUMFLEX,		0xf6
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_TILDE,		0xf7
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_MACRON,		0xf8
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_BREVE,		0xf9
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_DOTACCENT,		0xfa
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_RING,		0xfb
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_CEDILLA,		0xfc
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_HUNGARUMLAT,	0xfd
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>,	; C_OGONEK,		0xfe
    CharClass<0,1,0,0,0,0,0,0,0,0,1,1,0>	; C_CARON,		0xff

;
; We better have 256 entries in this table, and they should all be
; word size.  256 * 2 = 512
;
.assert	(size CharClassTable eq 512)

StringCmpMod	ends
