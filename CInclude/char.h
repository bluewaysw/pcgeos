/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	char.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines the GEOS character set
 *
 *	$Id: char.h,v 1.1 97/04/04 15:56:59 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__CHAR_H
#define __CHAR_H

#ifdef DO_DBCS
#include <unicode.h>
#else
/*
 *	The following represent the low byte of the character value
 *	 only when the high byte is CS_BSW:
 */

typedef ByteEnum Chars;
#define C_NULL   0x0	/* NULL */
#define C_CTRL_A   0x1	/* <ctrl>-A */
#define C_CTRL_B   0x2	/* <ctrl>-B */
#define C_CTRL_C   0x3	/* <ctrl>-C */
#define C_CTRL_D   0x4	/* <ctrl>-D */
#define C_CTRL_E   0x5	/* <ctrl>-E */
#define C_CTRL_F   0x6	/* <ctrl>-F */
#define C_CTRL_G   0x7	/* <ctrl>-G */
#define C_CTRL_H   0x8	/* <ctrl>-H */
#define C_TAB   0x9	/*  TAB */
#define C_LINEFEED   0xa	/*  LINE FEED */
#define C_CTRL_K   0xb	/* <ctrl>-K */
#define C_CTRL_L   0xc	/* <ctrl>-L */
#define C_ENTER   0xd	/*  ENTER or CR */
#define C_SHIFT_OUT   0xe	/* <ctrl>-N */
#define C_SHIFT_IN   0xf	/* <ctrl>-O */
#define C_CTRL_P   0x10	/* <ctrl>-P */
#define C_CTRL_Q   0x11	/* <ctrl>-Q */
#define C_CTRL_R   0x12	/* <ctrl>-R */
#define C_CTRL_S   0x13	/* <ctrl>-S */
#define C_CTRL_T   0x14	/* <ctrl>-T */
#define C_CTRL_U   0x15	/* <ctrl>-U */
#define C_CTRL_V   0x16	/* <ctrl>-V */
#define C_CTRL_W   0x17	/* <ctrl>-W */
#define C_CTRL_X   0x18	/* <ctrl>-X */
#define C_CTRL_Y   0x19	/* <ctrl>-Y */
#define C_CTRL_Z   0x1a	/* <ctrl>-Z */
#define C_ESCAPE   0x1b	/* ESC */

#define C_NULL_WIDTH   0x19	/* null width character */
#define C_GRAPHIC   0x1a	/* Graphic in text. */

#define C_THINSPACE   0x1b	/* 1/4 width space */
#define C_ENSPACE   0x1c	/* En-space, fixed width */
#define C_EMSPACE   0x1d	/* Em-space, fixed width. */

#define C_NONBRKHYPHEN   0x1e	/* Non breaking hyphen. */
#define C_OPTHYPHEN   0x1f	/* Optional hyphen, only drawn at eol */

/*  the standard ASCII chars: */

#define C_SPACE  ' '
#define C_EXCLAMATION  '!'
#define C_QUOTE  '"'
#define C_NUMBER_SIGN  '#'
#define C_DOLLAR_SIGN  '$'
#define C_PERCENT  '%'
#define C_AMPERSAND  '&'
#define C_SNG_QUOTE   0x27
#define C_LEFT_PAREN  '('
#define C_RIGHT_PAREN  ')'
#define C_ASTERISK  '*'
#define C_PLUS  '+'
#define C_COMMA  ','
#define C_MINUS  '-'
#define C_PERIOD  '.'
#define C_SLASH  '/'
#define C_ZERO  '0'
#define C_ONE  '1'
#define C_TWO  '2'
#define C_THREE  '3'
#define C_FOUR  '4'
#define C_FIVE  '5'
#define C_SIX  '6'
#define C_SEVEN  '7'
#define C_EIGHT  '8'
#define C_NINE  '9'
#define C_COLON  ':'
#define C_SEMICOLON  ';'
#define C_LESS_THAN  '<'
#define C_EQUAL  '='
#define C_GREATER_THAN  '>'
#define C_QUESTION_MARK  '?'
/* #define C_AT_SIGN  '@' */
/* GOC doesn't like this */
#define C_AT_SIGN   0x40
#define C_CAP_A  'A'
#define C_CAP_B  'B'
#define C_CAP_C  'C'
#define C_CAP_D  'D'
#define C_CAP_E  'E'
#define C_CAP_F  'F'
#define C_CAP_G  'G'
#define C_CAP_H  'H'
#define C_CAP_I  'I'
#define C_CAP_J  'J'
#define C_CAP_K  'K'
#define C_CAP_L  'L'
#define C_CAP_M  'M'
#define C_CAP_N  'N'
#define C_CAP_O  'O'
#define C_CAP_P  'P'
#define C_CAP_Q  'Q'
#define C_CAP_R  'R'
#define C_CAP_S  'S'
#define C_CAP_T  'T'
#define C_CAP_U  'U'
#define C_CAP_V  'V'
#define C_CAP_W  'W'
#define C_CAP_X  'X'
#define C_CAP_Y  'Y'
#define C_CAP_Z  'Z'
#define C_LEFT_BRACKET  '['
#define C_BACKSLASH   0x5c
#define C_RIGHT_BRACKET  ']'
#define C_ASCII_CIRCUMFLEX  '^'
#define C_UNDERSCORE  '_'
#define C_BACKQUOTE  '`'
#define C_SMALL_A  'a'
#define C_SMALL_B  'b'
#define C_SMALL_C  'c'
#define C_SMALL_D  'd'
#define C_SMALL_E  'e'
#define C_SMALL_F  'f'
#define C_SMALL_G  'g'
#define C_SMALL_H  'h'
#define C_SMALL_I  'i'
#define C_SMALL_J  'j'
#define C_SMALL_K  'k'
#define C_SMALL_L  'l'
#define C_SMALL_M  'm'
#define C_SMALL_N  'n'
#define C_SMALL_O  'o'
#define C_SMALL_P  'p'
#define C_SMALL_Q  'q'
#define C_SMALL_R  'r'
#define C_SMALL_S  's'
#define C_SMALL_T  't'
#define C_SMALL_U  'u'
#define C_SMALL_V  'v'
#define C_SMALL_W  'w'
#define C_SMALL_X  'x'
#define C_SMALL_Y  'y'
#define C_SMALL_Z  'z'
#define C_LEFT_BRACE  '{'
#define C_VERTICAL_BAR  '|'
#define C_RIGHT_BRACE  '}'
#define C_ASCII_TILDE  '~'
#define C_DELETE   0x7f

#define C_UA_DIERESIS   0x80
#define C_UA_RING   0x81
#define C_UC_CEDILLA   0x82
#define C_UE_ACUTE   0x83
#define C_UN_TILDE   0x84
#define C_UO_DIERESIS   0x85
#define C_UU_DIERESIS   0x86
#define C_LA_ACUTE   0x87
#define C_LA_GRAVE   0x88
#define C_LA_CIRCUMFLEX   0x89
#define C_LA_DIERESIS   0x8a
#define C_LA_TILDE   0x8b
#define C_LA_RING   0x8c
#define C_LC_CEDILLA   0x8d
#define C_LE_ACUTE   0x8e
#define C_LE_GRAVE   0x8f
#define C_LE_CIRCUMFLEX   0x90
#define C_LE_DIERESIS   0x91
#define C_LI_ACUTE   0x92
#define C_LI_GRAVE   0x93
#define C_LI_CIRCUMFLEX   0x94
#define C_LI_DIERESIS   0x95
#define C_LN_TILDE   0x96
#define C_LO_ACUTE   0x97
#define C_LO_GRAVE   0x98
#define C_LO_CIRCUMFLEX   0x99
#define C_LO_DIERESIS   0x9a
#define C_LO_TILDE   0x9b
#define C_LU_ACUTE   0x9c
#define C_LU_GRAVE   0x9d
#define C_LU_CIRCUMFLEX   0x9e
#define C_LU_DIERESIS   0x9f
#define C_DAGGER   0xa0
#define C_DEGREE   0xa1
#define C_CENT   0xa2
#define C_STERLING   0xa3
#define C_SECTION   0xa4
#define C_BULLET   0xa5
#define C_PARAGRAPH   0xa6
#define C_GERMANDBLS   0xa7
#define C_REGISTERED   0xa8
#define C_COPYRIGHT   0xa9
#define C_TRADEMARK   0xaa
#define C_ACUTE   0xab
#define C_DIERESIS   0xac
#define C_NOTEQUAL   0xad
#define C_U_AE   0xae
#define C_UO_SLASH   0xaf
#define C_INFINITY   0xb0
#define C_PLUSMINUS   0xb1
#define C_LESSEQUAL   0xb2
#define C_GREATEREQUAL   0xb3
#define C_YEN   0xb4
#define C_L_MU   0xb5
#define C_L_DELTA   0xb6
#define C_U_SIGMA   0xb7
#define C_U_PI   0xb8
#define C_L_PI   0xb9
#define C_INTEGRAL   0xba
#define C_ORDFEMININE   0xbb
#define C_ORDMASCULINE   0xbc
#define C_U_OMEGA   0xbd
#define C_L_AE   0xbe
#define C_LO_SLASH   0xbf
#define C_QUESTIONDOWN   0xc0
#define C_EXCLAMDOWN   0xc1
#define C_LOGICAL_NOT   0xc2
#define C_ROOT   0xc3
#define C_FLORIN   0xc4
#define C_APPROX_EQUAL   0xc5
#define C_U_DELTA   0xc6
#define C_GUILLEDBLLEFT   0xc7
#define C_GUILLEDBLRIGHT   0xc8
#define C_ELLIPSIS   0xc9
#define C_NONBRKSPACE   0xca
#define C_UA_GRAVE   0xcb
#define C_UA_TILDE   0xcc
#define C_UO_TILDE   0xcd
#define C_U_OE   0xce
#define C_L_OE   0xcf
#define C_ENDASH   0xd0
#define C_EMDASH   0xd1
#define C_QUOTEDBLLEFT   0xd2
#define C_QUOTEDBLRIGHT   0xd3
#define C_QUOTESNGLEFT   0xd4
#define C_QUOTESNGRIGHT   0xd5
#define C_DIVISION   0xd6
#define C_DIAMONDBULLET   0xd7
#define C_LY_DIERESIS   0xd8
#define C_UY_DIERESIS   0xd9
#define C_FRACTION   0xda
#define C_CURRENCY   0xdb
#define C_GUILSNGLEFT   0xdc
#define C_GUILSNGRIGHT   0xdd
#define C_LY_ACUTE   0xde
#define C_UY_ACUTE   0xdf
#define C_DBLDAGGER   0xe0
#define C_CNTR_DOT   0xe1
#define C_SNGQUOTELOW   0xe2
#define C_DBLQUOTELOW   0xe3
#define C_PERTHOUSAND   0xe4
#define C_UA_CIRCUMFLEX   0xe5
#define C_UE_CIRCUMFLEX   0xe6
#define C_UA_ACUTE   0xe7
#define C_UE_DIERESIS   0xe8
#define C_UE_GRAVE   0xe9
#define C_UI_ACUTE   0xea
#define C_UI_CIRCUMFLEX   0xeb
#define C_UI_DIERESIS   0xec
#define C_UI_GRAVE   0xed
#define C_UO_ACUTE   0xee
#define C_UO_CIRCUMFLEX   0xef
#define C_LOGO   0xf0
#define C_UO_GRAVE   0xf1
#define C_UU_ACUTE   0xf2
#define C_UU_CIRCUMFLEX   0xf3
#define C_UU_GRAVE   0xf4
#define C_LI_DOTLESS   0xf5
#define C_CIRCUMFLEX   0xf6
#define C_TILDE   0xf7
#define C_MACRON   0xf8
#define C_BREVE   0xf9
#define C_DOTACCENT   0xfa
#define C_RING   0xfb
#define C_CEDILLA   0xfc
#define C_HUNGARUMLAUT   0xfd
#define C_OGONEK   0xfe
#define C_CARON   0xff

/* common shortcuts for low 32 codes */

#define C_NUL		C_NULL
#define C_STX		C_CTRL_B
#define C_ETX		C_CTRL_C
#define C_BEL		C_CTRL_G
#define C_BS		C_CTRL_H
#define C_HT		C_CTRL_I
#define C_VT		C_CTRL_K
#define C_FF		C_CTRL_L
#define C_SO		C_CTRL_N
#define C_SI		C_CTRL_O
#define C_DC1		C_CTRL_Q
#define C_DC2		C_CTRL_R
#define C_DC3		C_CTRL_S
#define C_DC4		C_CTRL_T
#define C_CAN		C_CTRL_X
#define C_EM		C_CTRL_Y
#define C_ESC		C_ESCAPE

/* some alternative names: */

#define C_CR		C_ENTER
#define C_CTRL_M	C_ENTER
#define C_CTRL_I	C_TAB
#define C_CTRL_J	C_LINEFEED
#define C_LF		C_LINEFEED
#define C_CTRL_N	C_SHIFT_OUT
#define C_CTRL_O	C_SHIFT_IN
#define C_FS		C_ENSPACE
#define C_FIELD_SEP	C_FS

/* some alternative names: */

#define C_HYPHEN	C_MINUS
#define C_GRAVE		C_BACKQUOTE


/* some alternative names: */

#define C_PARTIAL_DIFF	C_L_DELTA
#define C_SUM		C_U_SIGMA
#define C_PRODUCT	C_U_PI
#define C_RADICAL	C_ROOT
#define C_LOZENGE	C_DIAMONDBULLET

/* some former spelling errors */
#define C_HUNGARUMLAT   C_HUNGARUMLAUT

#endif /* DBCS */
#endif
