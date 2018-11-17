/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	Type1/tr_names.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: tr_names.c,v 1.1 97/04/18 11:45:16 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TrNameCode")

/*****************************************************************************
*                                                                            *
*  Copyright 1988, 1989, 1990 as an unpublished work by Bitstream Inc.,      *
*  Cambridge, MA                                                             *
*                         U.S. Patent No 4,785,391                           *
*                           Other Patent Pending                             *
*                                                                            *
*         These programs are the sole property of Bitstream Inc. and         *
*           contain its proprietary and confidential information.            *
*                                                                            *
*****************************************************************************/

/************************** C H R _ N M E S . C ******************************
 *                                                                           *
 * This is an extended encoding vector for PostScript text fonts             *
 *                                                                           *
 ********************** R E V I S I O N   H I S T O R Y **********************
 * $Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_names.c,v 1.1 97/04/18 11:45:16 newdeal Exp $
 *
 * $Log:	tr_names.c,v $
 * Revision 1.1  97/04/18  11:45:16  newdeal
 * Initial revision
 * 
 * Revision 1.1.10.1  97/03/29  07:05:32  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:18:06  brianc
 * support Type1
 * 
 * Revision 28.24  93/03/15  13:11:35  roberte
 * Release
 * 
 * Revision 28.8  92/11/24  13:14:47  laurar
 * include fino.h
 * 
 * Revision 28.7  92/11/19  15:35:50  weili
 * Release
 * 
 * Revision 26.3  92/11/16  18:23:39  laurar
 * Add STACKFAR for Windows.
 * 
 * Revision 26.2  92/10/16  16:43:56  davidw
 * beautified with indent
 * 
 * Revision 26.1  92/06/26  10:26:23  leeann
 * Release
 * 
 * Revision 25.1  92/04/06  11:42:45  leeann
 * Release
 * 
 * Revision 24.1  92/03/23  14:11:02  leeann
 * Release
 * 
 * Revision 23.1  92/01/29  17:02:08  leeann
 * Release
 * 
 * Revision 22.1  92/01/20  13:33:31  leeann
 * Release
 * 
 * Revision 21.1  91/10/28  16:45:58  leeann
 * Release
 * 
 * Revision 20.1  91/10/28  15:29:40  leeann
 * Release
 * 
 * Revision 18.1  91/10/17  11:41:12  leeann
 * Release
 * 
 * Revision 17.1  91/06/13  10:45:47  leeann
 * Release
 * 
 * Revision 16.1  91/06/04  15:36:28  leeann
 * Release
 * 
 * Revision 15.1  91/05/08  18:08:35  leeann
 * Release
 * 
 * Revision 14.1  91/05/07  16:30:22  leeann
 * Release
 * 
 * Revision 13.1  91/04/30  17:05:06  leeann
 * Release
 * 
 * Revision 12.1  91/04/29  14:55:29  leeann
 * Release
 * 
 * Revision 11.2  91/04/10  13:21:18  leeann
 *  support character names as structures
 * 
 * Revision 11.1  91/04/04  10:59:17  leeann
 * Release
 * 
 * Revision 10.1  91/03/14  14:31:43  leeann
 * Release
 * 
 * Revision 9.1  91/03/14  10:06:52  leeann
 * Release
 * 
 * Revision 8.1  91/01/30  19:03:45  leeann
 * Release
 * 
 * Revision 7.2  91/01/22  16:39:03  leeann
 * make array conform to Standard Text Encoding
 * 
 * Revision 7.1  91/01/22  14:28:11  leeann
 * Release
 * 
 * Revision 6.1  91/01/16  10:53:56  leeann
 * Release
 * 
 * Revision 5.1  90/12/12  17:20:31  leeann
 * Release
 * 
 * Revision 4.1  90/12/12  14:46:19  leeann
 * Release
 * 
 * Revision 3.1  90/12/06  10:28:42  leeann
 * Release
 * 
 * Revision 2.1  90/12/03  12:57:27  mark
 * Release
 * 
 * Revision 1.1  90/11/30  11:27:30  joyce
 * Initial revision
 * 
 * Revision 1.1  90/09/26  10:59:44  joyce
 * Initial revision
 * 
 * Revision 1.2  90/09/17  13:16:52  roger
 * put in rcsid[] to help RCS
 * 
 * Revision 1.1  90/08/13  15:26:15  arg
 * Initial revision
 * 
 *                                                                           *
 *  1)  1 Mar 90  jsc  Created                                               *
 *                                                                           *
 ****************************************************************************/

static char     rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/Type1/tr_names.c,v 1.1 97/04/18 11:45:16 newdeal Exp $";

#include "spdo_prv.h"		/* General definitions for Speedo */
#include "fino.h"
#include "type1.h"

#if NAME_STRUCT
/* ASCII to PostScript character name table */
CHARACTERNAME  STACKFAR*charname_tbl[256];
CHARACTERNAME   charname_structs[] =
{
 7, (unsigned char *) ".notdef",/* 00 */
 7, (unsigned char *) ".notdef",/* 01 */
 7, (unsigned char *) ".notdef",/* 02 */
 7, (unsigned char *) ".notdef",/* 03 */
 7, (unsigned char *) ".notdef",/* 04 */
 7, (unsigned char *) ".notdef",/* 05 */
 7, (unsigned char *) ".notdef",/* 06 */
 7, (unsigned char *) ".notdef",/* 07 */
 7, (unsigned char *) ".notdef",/* 08 */
 7, (unsigned char *) ".notdef",/* 09 */
 7, (unsigned char *) ".notdef",/* 0A */
 7, (unsigned char *) ".notdef",/* 0B */
 7, (unsigned char *) ".notdef",/* 0C */
 7, (unsigned char *) ".notdef",/* 0D */
 7, (unsigned char *) ".notdef",/* 0E */
 7, (unsigned char *) ".notdef",/* 0F */
 7, (unsigned char *) ".notdef",/* 10 */
 7, (unsigned char *) ".notdef",/* 11 */
 7, (unsigned char *) ".notdef",/* 12 */
 7, (unsigned char *) ".notdef",/* 13 */
 7, (unsigned char *) ".notdef",/* 14 */
 7, (unsigned char *) ".notdef",/* 15 */
 7, (unsigned char *) ".notdef",/* 16 */
 7, (unsigned char *) ".notdef",/* 17 */
 7, (unsigned char *) ".notdef",/* 18 */
 7, (unsigned char *) ".notdef",/* 19 */
 7, (unsigned char *) ".notdef",/* 1A */
 7, (unsigned char *) ".notdef",/* 1B */
 7, (unsigned char *) ".notdef",/* 1C */
 7, (unsigned char *) ".notdef",/* 1D */
 7, (unsigned char *) ".notdef",/* 1E */
 7, (unsigned char *) ".notdef",/* 1F */

 5, (unsigned char *) "space",	/* 20   */
 6, (unsigned char *) "exclam",	/* 21 ! */
 8, (unsigned char *) "quotedbl",	/* 22 " */
 10, (unsigned char *) "numbersign",	/* 23 # */
 6, (unsigned char *) "dollar",	/* 24 $ */
 7, (unsigned char *) "percent",/* 25 % */
 9, (unsigned char *) "ampersand",	/* 26 & */
 10, (unsigned char *) "quoteright",	/* 27 ' */
 9, (unsigned char *) "parenleft",	/* 28 ( */
 10, (unsigned char *) "parenright",	/* 29 ) */
 8, (unsigned char *) "asterisk",	/* 2A * */
 4, (unsigned char *) "plus",	/* 2B + */
 5, (unsigned char *) "comma",	/* 2C , */
 6, (unsigned char *) "hyphen",	/* 2D - */
 6, (unsigned char *) "period",	/* 2E . */
 5, (unsigned char *) "slash",	/* 2F / */

 4, (unsigned char *) "zero",	/* 30 0 */
 3, (unsigned char *) "one",	/* 31 1 */
 3, (unsigned char *) "two",	/* 32 2 */
 5, (unsigned char *) "three",	/* 33 3 */
 4, (unsigned char *) "four",	/* 34 4 */
 4, (unsigned char *) "five",	/* 35 5 */
 3, (unsigned char *) "six",	/* 36 6 */
 5, (unsigned char *) "seven",	/* 37 7 */
 5, (unsigned char *) "eight",	/* 38 8 */
 4, (unsigned char *) "nine",	/* 39 9 */
 5, (unsigned char *) "colon",	/* 3A : */
 9, (unsigned char *) "semicolon",	/* 3B ; */
 4, (unsigned char *) "less",	/* 3C < */
 5, (unsigned char *) "equal",	/* 3D = */
 7, (unsigned char *) "greater",/* 3E > */
 8, (unsigned char *) "question",	/* 3F ? */

 2, (unsigned char *) "at",	/* 40 @ */
 1, (unsigned char *) "A",	/* 41 A */
 1, (unsigned char *) "B",	/* 42 B */
 1, (unsigned char *) "C",	/* 43 C */
 1, (unsigned char *) "D",	/* 44 D */
 1, (unsigned char *) "E",	/* 45 E */
 1, (unsigned char *) "F",	/* 46 F */
 1, (unsigned char *) "G",	/* 47 G */
 1, (unsigned char *) "H",	/* 48 H */
 1, (unsigned char *) "I",	/* 49 I */
 1, (unsigned char *) "J",	/* 4A J */
 1, (unsigned char *) "K",	/* 4B K */
 1, (unsigned char *) "L",	/* 4C L */
 1, (unsigned char *) "M",	/* 4D M */
 1, (unsigned char *) "N",	/* 4E N */
 1, (unsigned char *) "O",	/* 4F O */

 1, (unsigned char *) "P",	/* 50 P */
 1, (unsigned char *) "Q",	/* 51 Q */
 1, (unsigned char *) "R",	/* 52 R */
 1, (unsigned char *) "S",	/* 53 S */
 1, (unsigned char *) "T",	/* 54 T */
 1, (unsigned char *) "U",	/* 55 U */
 1, (unsigned char *) "V",	/* 56 V */
 1, (unsigned char *) "W",	/* 57 W */
 1, (unsigned char *) "X",	/* 58 X */
 1, (unsigned char *) "Y",	/* 59 Y */
 1, (unsigned char *) "Z",	/* 5A Z */
 11, (unsigned char *) "bracketleft",	/* 5B [ */
 9, (unsigned char *) "backslash",	/* 5C \ */
 12, (unsigned char *) "bracketright",	/* 5D ] */
 11, (unsigned char *) "asciicircum",	/* 5E ^ */
 10, (unsigned char *) "underscore",	/* 5F _ */

 9, (unsigned char *) "quoteleft",	/* 60 ` */
 1, (unsigned char *) "a",	/* 61 a */
 1, (unsigned char *) "b",	/* 62 b */
 1, (unsigned char *) "c",	/* 63 c */
 1, (unsigned char *) "d",	/* 64 d */
 1, (unsigned char *) "e",	/* 65 e */
 1, (unsigned char *) "f",	/* 66 f */
 1, (unsigned char *) "g",	/* 67 g */
 1, (unsigned char *) "h",	/* 68 h */
 1, (unsigned char *) "i",	/* 69 i */
 1, (unsigned char *) "j",	/* 6A j */
 1, (unsigned char *) "k",	/* 6B k */
 1, (unsigned char *) "l",	/* 6C l */
 1, (unsigned char *) "m",	/* 6D m */
 1, (unsigned char *) "n",	/* 6E n */
 1, (unsigned char *) "o",	/* 6F o */

 1, (unsigned char *) "p",	/* 70 p */
 1, (unsigned char *) "q",	/* 71 q */
 1, (unsigned char *) "r",	/* 72 r */
 1, (unsigned char *) "s",	/* 73 s */
 1, (unsigned char *) "t",	/* 74 t */
 1, (unsigned char *) "u",	/* 75 u */
 1, (unsigned char *) "v",	/* 76 v */
 1, (unsigned char *) "w",	/* 77 w */
 1, (unsigned char *) "x",	/* 78 x */
 1, (unsigned char *) "y",	/* 79 y */
 1, (unsigned char *) "z",	/* 7A z */
 9, (unsigned char *) "braceleft",	/* 7B { */
 3, (unsigned char *) "bar",	/* 7C | */
 10, (unsigned char *) "braceright",	/* 7D } */
 10, (unsigned char *) "asciitilde",	/* 7E ~ */
 7, (unsigned char *) ".notdef",/* 7F */

 7, (unsigned char *) ".notdef",/* 80 */
 7, (unsigned char *) ".notdef",/* 81 */
 7, (unsigned char *) ".notdef",/* 82 */
 7, (unsigned char *) ".notdef",/* 83 */
 7, (unsigned char *) ".notdef",/* 84 */
 7, (unsigned char *) ".notdef",/* 85 */
 7, (unsigned char *) ".notdef",/* 86 */
 7, (unsigned char *) ".notdef",/* 87 */
 7, (unsigned char *) ".notdef",/* 88 */
 7, (unsigned char *) ".notdef",/* 89 */
 7, (unsigned char *) ".notdef",/* 8A */
 7, (unsigned char *) ".notdef",/* 8B */
 7, (unsigned char *) ".notdef",/* 8C */
 7, (unsigned char *) ".notdef",/* 8D */
 7, (unsigned char *) ".notdef",/* 8E */
 7, (unsigned char *) ".notdef",/* 8F */

 7, (unsigned char *) ".notdef",/* 90 */
 7, (unsigned char *) ".notdef",/* 91 */
 7, (unsigned char *) ".notdef",/* 92 */
 7, (unsigned char *) ".notdef",/* 93 */
 7, (unsigned char *) ".notdef",/* 94 */
 7, (unsigned char *) ".notdef",/* 95 */
 7, (unsigned char *) ".notdef",/* 96 */
 7, (unsigned char *) ".notdef",/* 97 */
 7, (unsigned char *) ".notdef",/* 98 */
 7, (unsigned char *) ".notdef",/* 99 */
 7, (unsigned char *) ".notdef",/* 9A */
 7, (unsigned char *) ".notdef",/* 9B */
 7, (unsigned char *) ".notdef",/* 9C */
 7, (unsigned char *) ".notdef",/* 9D */
 7, (unsigned char *) ".notdef",/* 9E */
 7, (unsigned char *) ".notdef",/* 9F */

 7, (unsigned char *) ".notdef",/* A0 */
 10, (unsigned char *) "exclamdown",	/* A1 */
 4, (unsigned char *) "cent",	/* A2 */
 8, (unsigned char *) "sterling",	/* A3 */
 8, (unsigned char *) "fraction",	/* A4 */
 3, (unsigned char *) "yen",	/* A5 */
 6, (unsigned char *) "florin",	/* A6 */
 7, (unsigned char *) "section",/* A7 */
 8, (unsigned char *) "currency",	/* A8 */
 11, (unsigned char *) "quotesingle",	/* A9 */
 12, (unsigned char *) "quotedblleft",	/* AA */
 13, (unsigned char *) "guillemotleft",	/* AB */
 13, (unsigned char *) "guilsinglleft",	/* AC */
 14, (unsigned char *) "guilsinglright",	/* AD */
 2, (unsigned char *) "fi",	/* AE */
 2, (unsigned char *) "fl",	/* AF */

 7, (unsigned char *) ".notdef",/* B0 */
 6, (unsigned char *) "endash",	/* B1 */
 6, (unsigned char *) "dagger",	/* B2 */
 9, (unsigned char *) "daggerdbl",	/* B3 */
 14, (unsigned char *) "periodcentered",	/* B4 */
 7, (unsigned char *) ".notdef",/* B5 */
 9, (unsigned char *) "paragraph",	/* B6 */
 6, (unsigned char *) "bullet",	/* B7 */
 14, (unsigned char *) "quotesinglbase",	/* B8 */
 12, (unsigned char *) "quotedblbase",	/* B9 */
 13, (unsigned char *) "quotedblright",	/* BA */
 14, (unsigned char *) "guillemotright",	/* BB */
 8, (unsigned char *) "ellipsis",	/* BC */
 11, (unsigned char *) "perthousand",	/* BD */
 7, (unsigned char *) ".notdef",/* BE */
 12, (unsigned char *) "questiondown",	/* BF */

 7, (unsigned char *) ".notdef",/* C0 */
 5, (unsigned char *) "grave",	/* C1 */
 5, (unsigned char *) "acute",	/* C2 */
 10, (unsigned char *) "circumflex",	/* C3 */
 5, (unsigned char *) "tilde",	/* C4 */
 6, (unsigned char *) "macron",	/* C5 */
 5, (unsigned char *) "breve",	/* C6 */
 9, (unsigned char *) "dotaccent",	/* C7 */
 8, (unsigned char *) "dieresis",	/* C8 */
 7, (unsigned char *) ".notdef",/* C9 */
 4, (unsigned char *) "ring",	/* CA */
 7, (unsigned char *) "cedilla",/* CB */
 7, (unsigned char *) ".notdef",/* CC */
 12, (unsigned char *) "hungarumlaut",	/* CD */
 6, (unsigned char *) "ogonek",	/* CE */
 5, (unsigned char *) "caron",	/* CF */

 6, (unsigned char *) "emdash",	/* D0 */
 7, (unsigned char *) ".notdef",/* D1 */
 7, (unsigned char *) ".notdef",/* D2 */
 7, (unsigned char *) ".notdef",/* D3 */
 7, (unsigned char *) ".notdef",/* D4 */
 7, (unsigned char *) ".notdef",/* D5 */
 7, (unsigned char *) ".notdef",/* D6 */
 7, (unsigned char *) ".notdef",/* D7 */
 7, (unsigned char *) ".notdef",/* D8 */
 7, (unsigned char *) ".notdef",/* D9 */
 7, (unsigned char *) ".notdef",/* DA */
 7, (unsigned char *) ".notdef",/* DB */
 7, (unsigned char *) ".notdef",/* DC */
 7, (unsigned char *) ".notdef",/* DD */
 7, (unsigned char *) ".notdef",/* DE */
 7, (unsigned char *) ".notdef",/* DF */

 7, (unsigned char *) ".notdef",/* E0 */
 2, (unsigned char *) "AE",	/* E1 */
 7, (unsigned char *) ".notdef",/* E2 */
 11, (unsigned char *) "ordfeminine",	/* E3 */
 7, (unsigned char *) ".notdef",/* E4 */
 7, (unsigned char *) ".notdef",/* E5 */
 7, (unsigned char *) ".notdef",/* E6 */
 7, (unsigned char *) ".notdef",/* E7 */
 6, (unsigned char *) "Lslash",	/* E8 */
 6, (unsigned char *) "Oslash",	/* E9 */
 2, (unsigned char *) "OE",	/* EA */
 12, (unsigned char *) "ordmasculine",	/* EB */
 7, (unsigned char *) ".notdef",/* EC */
 7, (unsigned char *) ".notdef",/* ED */
 7, (unsigned char *) ".notdef",/* EE */
 7, (unsigned char *) ".notdef",/* EF */

 7, (unsigned char *) ".notdef",/* F0 */
 2, (unsigned char *) "ae",	/* F1 */
 7, (unsigned char *) ".notdef",/* F2 */
 7, (unsigned char *) ".notdef",/* F3 */
 7, (unsigned char *) ".notdef",/* F4 */
 8, (unsigned char *) "dotlessi",	/* F5 */
 7, (unsigned char *) ".notdef",/* F6 */
 7, (unsigned char *) ".notdef",/* F7 */
 6, (unsigned char *) "lslash",	/* F8 */
 6, (unsigned char *) "oslash",	/* F9 */
 2, (unsigned char *) "oe",	/* FA */
 10, (unsigned char *) "germandbls",	/* FB */
 7, (unsigned char *) ".notdef",/* FC */
 7, (unsigned char *) ".notdef",/* FD */
 7, (unsigned char *) ".notdef",/* FE */
 7, (unsigned char *) ".notdef"	/* FF */
};
#else
/* ASCII to PostScript character name table */
CHARACTERNAME  STACKFAR*charname_tbl[] =
{
 (unsigned char *) ".notdef",	/* 00 */
 (unsigned char *) ".notdef",	/* 01 */
 (unsigned char *) ".notdef",	/* 02 */
 (unsigned char *) ".notdef",	/* 03 */
 (unsigned char *) ".notdef",	/* 04 */
 (unsigned char *) ".notdef",	/* 05 */
 (unsigned char *) ".notdef",	/* 06 */
 (unsigned char *) ".notdef",	/* 07 */
 (unsigned char *) ".notdef",	/* 08 */
 (unsigned char *) ".notdef",	/* 09 */
 (unsigned char *) ".notdef",	/* 0A */
 (unsigned char *) ".notdef",	/* 0B */
 (unsigned char *) ".notdef",	/* 0C */
 (unsigned char *) ".notdef",	/* 0D */
 (unsigned char *) ".notdef",	/* 0E */
 (unsigned char *) ".notdef",	/* 0F */

 (unsigned char *) ".notdef",	/* 10 */
 (unsigned char *) ".notdef",	/* 11 */
 (unsigned char *) ".notdef",	/* 12 */
 (unsigned char *) ".notdef",	/* 13 */
 (unsigned char *) ".notdef",	/* 14 */
 (unsigned char *) ".notdef",	/* 15 */
 (unsigned char *) ".notdef",	/* 16 */
 (unsigned char *) ".notdef",	/* 17 */
 (unsigned char *) ".notdef",	/* 18 */
 (unsigned char *) ".notdef",	/* 19 */
 (unsigned char *) ".notdef",	/* 1A */
 (unsigned char *) ".notdef",	/* 1B */
 (unsigned char *) ".notdef",	/* 1C */
 (unsigned char *) ".notdef",	/* 1D */
 (unsigned char *) ".notdef",	/* 1E */
 (unsigned char *) ".notdef",	/* 1F */

 (unsigned char *) "space",	/* 20   */
 (unsigned char *) "exclam",	/* 21 ! */
 (unsigned char *) "quotedbl",	/* 22 " */
 (unsigned char *) "numbersign",/* 23 # */
 (unsigned char *) "dollar",	/* 24 $ */
 (unsigned char *) "percent",	/* 25 % */
 (unsigned char *) "ampersand",	/* 26 & */
 (unsigned char *) "quoteright",/* 27 ' */
 (unsigned char *) "parenleft",	/* 28 ( */
 (unsigned char *) "parenright",/* 29 ) */
 (unsigned char *) "asterisk",	/* 2A * */
 (unsigned char *) "plus",	/* 2B + */
 (unsigned char *) "comma",	/* 2C , */
 (unsigned char *) "hyphen",	/* 2D - */
 (unsigned char *) "period",	/* 2E . */
 (unsigned char *) "slash",	/* 2F / */

 (unsigned char *) "zero",	/* 30 0 */
 (unsigned char *) "one",	/* 31 1 */
 (unsigned char *) "two",	/* 32 2 */
 (unsigned char *) "three",	/* 33 3 */
 (unsigned char *) "four",	/* 34 4 */
 (unsigned char *) "five",	/* 35 5 */
 (unsigned char *) "six",	/* 36 6 */
 (unsigned char *) "seven",	/* 37 7 */
 (unsigned char *) "eight",	/* 38 8 */
 (unsigned char *) "nine",	/* 39 9 */
 (unsigned char *) "colon",	/* 3A : */
 (unsigned char *) "semicolon",	/* 3B ; */
 (unsigned char *) "less",	/* 3C < */
 (unsigned char *) "equal",	/* 3D = */
 (unsigned char *) "greater",	/* 3E > */
 (unsigned char *) "question",	/* 3F ? */

 (unsigned char *) "at",	/* 40 @ */
 (unsigned char *) "A",		/* 41 A */
 (unsigned char *) "B",		/* 42 B */
 (unsigned char *) "C",		/* 43 C */
 (unsigned char *) "D",		/* 44 D */
 (unsigned char *) "E",		/* 45 E */
 (unsigned char *) "F",		/* 46 F */
 (unsigned char *) "G",		/* 47 G */
 (unsigned char *) "H",		/* 48 H */
 (unsigned char *) "I",		/* 49 I */
 (unsigned char *) "J",		/* 4A J */
 (unsigned char *) "K",		/* 4B K */
 (unsigned char *) "L",		/* 4C L */
 (unsigned char *) "M",		/* 4D M */
 (unsigned char *) "N",		/* 4E N */
 (unsigned char *) "O",		/* 4F O */

 (unsigned char *) "P",		/* 50 P */
 (unsigned char *) "Q",		/* 51 Q */
 (unsigned char *) "R",		/* 52 R */
 (unsigned char *) "S",		/* 53 S */
 (unsigned char *) "T",		/* 54 T */
 (unsigned char *) "U",		/* 55 U */
 (unsigned char *) "V",		/* 56 V */
 (unsigned char *) "W",		/* 57 W */
 (unsigned char *) "X",		/* 58 X */
 (unsigned char *) "Y",		/* 59 Y */
 (unsigned char *) "Z",		/* 5A Z */
 (unsigned char *) "bracketleft",	/* 5B [ */
 (unsigned char *) "backslash",	/* 5C \ */
 (unsigned char *) "bracketright",	/* 5D ] */
 (unsigned char *) "asciicircum",	/* 5E ^ */
 (unsigned char *) "underscore",/* 5F _ */

 (unsigned char *) "quoteleft",	/* 60 ` */
 (unsigned char *) "a",		/* 61 a */
 (unsigned char *) "b",		/* 62 b */
 (unsigned char *) "c",		/* 63 c */
 (unsigned char *) "d",		/* 64 d */
 (unsigned char *) "e",		/* 65 e */
 (unsigned char *) "f",		/* 66 f */
 (unsigned char *) "g",		/* 67 g */
 (unsigned char *) "h",		/* 68 h */
 (unsigned char *) "i",		/* 69 i */
 (unsigned char *) "j",		/* 6A j */
 (unsigned char *) "k",		/* 6B k */
 (unsigned char *) "l",		/* 6C l */
 (unsigned char *) "m",		/* 6D m */
 (unsigned char *) "n",		/* 6E n */
 (unsigned char *) "o",		/* 6F o */

 (unsigned char *) "p",		/* 70 p */
 (unsigned char *) "q",		/* 71 q */
 (unsigned char *) "r",		/* 72 r */
 (unsigned char *) "s",		/* 73 s */
 (unsigned char *) "t",		/* 74 t */
 (unsigned char *) "u",		/* 75 u */
 (unsigned char *) "v",		/* 76 v */
 (unsigned char *) "w",		/* 77 w */
 (unsigned char *) "x",		/* 78 x */
 (unsigned char *) "y",		/* 79 y */
 (unsigned char *) "z",		/* 7A z */
 (unsigned char *) "braceleft",	/* 7B { */
 (unsigned char *) "bar",	/* 7C | */
 (unsigned char *) "braceright",/* 7D } */
 (unsigned char *) "asciitilde",/* 7E ~ */
 (unsigned char *) ".notdef",	/* 7F */

 (unsigned char *) ".notdef",	/* 80 */
 (unsigned char *) ".notdef",	/* 81 */
 (unsigned char *) ".notdef",	/* 82 */
 (unsigned char *) ".notdef",	/* 83 */
 (unsigned char *) ".notdef",	/* 84 */
 (unsigned char *) ".notdef",	/* 85 */
 (unsigned char *) ".notdef",	/* 86 */
 (unsigned char *) ".notdef",	/* 87 */
 (unsigned char *) ".notdef",	/* 88 */
 (unsigned char *) ".notdef",	/* 89 */
 (unsigned char *) ".notdef",	/* 8A */
 (unsigned char *) ".notdef",	/* 8B */
 (unsigned char *) ".notdef",	/* 8C */
 (unsigned char *) ".notdef",	/* 8D */
 (unsigned char *) ".notdef",	/* 8E */
 (unsigned char *) ".notdef",	/* 8F */

 (unsigned char *) ".notdef",	/* 90 */
 (unsigned char *) ".notdef",	/* 91 */
 (unsigned char *) ".notdef",	/* 92 */
 (unsigned char *) ".notdef",	/* 93 */
 (unsigned char *) ".notdef",	/* 94 */
 (unsigned char *) ".notdef",	/* 95 */
 (unsigned char *) ".notdef",	/* 96 */
 (unsigned char *) ".notdef",	/* 97 */
 (unsigned char *) ".notdef",	/* 98 */
 (unsigned char *) ".notdef",	/* 99 */
 (unsigned char *) ".notdef",	/* 9A */
 (unsigned char *) ".notdef",	/* 9B */
 (unsigned char *) ".notdef",	/* 9C */
 (unsigned char *) ".notdef",	/* 9D */
 (unsigned char *) ".notdef",	/* 9E */
 (unsigned char *) ".notdef",	/* 9F */

 (unsigned char *) ".notdef",	/* A0 */
 (unsigned char *) "exclamdown",/* A1 */
 (unsigned char *) "cent",	/* A2 */
 (unsigned char *) "sterling",	/* A3 */
 (unsigned char *) "fraction",	/* A4 */
 (unsigned char *) "yen",	/* A5 */
 (unsigned char *) "florin",	/* A6 */
 (unsigned char *) "section",	/* A7 */
 (unsigned char *) "currency",	/* A8 */
 (unsigned char *) "quotesingle",	/* A9 */
 (unsigned char *) "quotedblleft",	/* AA */
 (unsigned char *) "guillemotleft",	/* AB */
 (unsigned char *) "guilsinglleft",	/* AC */
 (unsigned char *) "guilsinglright",	/* AD */
 (unsigned char *) "fi",	/* AE */
 (unsigned char *) "fl",	/* AF */

 (unsigned char *) ".notdef",	/* B0 */
 (unsigned char *) "endash",	/* B1 */
 (unsigned char *) "dagger",	/* B2 */
 (unsigned char *) "daggerdbl",	/* B3 */
 (unsigned char *) "periodcentered",	/* B4 */
 (unsigned char *) ".notdef",	/* B5 */
 (unsigned char *) "paragraph",	/* B6 */
 (unsigned char *) "bullet",	/* B7 */
 (unsigned char *) "quotesinglbase",	/* B8 */
 (unsigned char *) "quotedblbase",	/* B9 */
 (unsigned char *) "quotedblright",	/* BA */
 (unsigned char *) "guillemotright",	/* BB */
 (unsigned char *) "ellipsis",	/* BC */
 (unsigned char *) "perthousand",	/* BD */
 (unsigned char *) ".notdef",	/* BE */
 (unsigned char *) "questiondown",	/* BF */

 (unsigned char *) ".notdef",	/* C0 */
 (unsigned char *) "grave",	/* C1 */
 (unsigned char *) "acute",	/* C2 */
 (unsigned char *) "circumflex",/* C3 */
 (unsigned char *) "tilde",	/* C4 */
 (unsigned char *) "macron",	/* C5 */
 (unsigned char *) "breve",	/* C6 */
 (unsigned char *) "dotaccent",	/* C7 */
 (unsigned char *) "dieresis",	/* C8 */
 (unsigned char *) ".notdef",	/* C9 */
 (unsigned char *) "ring",	/* CA */
 (unsigned char *) "cedilla",	/* CB */
 (unsigned char *) ".notdef",	/* CC */
 (unsigned char *) "hungarumlaut",	/* CD */
 (unsigned char *) "ogonek",	/* CE */
 (unsigned char *) "caron",	/* CF */

 (unsigned char *) "emdash",	/* D0 */
 (unsigned char *) ".notdef",	/* D1 */
 (unsigned char *) ".notdef",	/* D2 */
 (unsigned char *) ".notdef",	/* D3 */
 (unsigned char *) ".notdef",	/* D4 */
 (unsigned char *) ".notdef",	/* D5 */
 (unsigned char *) ".notdef",	/* D6 */
 (unsigned char *) ".notdef",	/* D7 */
 (unsigned char *) ".notdef",	/* D8 */
 (unsigned char *) ".notdef",	/* D9 */
 (unsigned char *) ".notdef",	/* DA */
 (unsigned char *) ".notdef",	/* DB */
 (unsigned char *) ".notdef",	/* DC */
 (unsigned char *) ".notdef",	/* DD */
 (unsigned char *) ".notdef",	/* DE */
 (unsigned char *) ".notdef",	/* DF */

 (unsigned char *) ".notdef",	/* E0 */
 (unsigned char *) "AE",	/* E1 */
 (unsigned char *) ".notdef",	/* E2 */
 (unsigned char *) "ordfeminine",	/* E3 */
 (unsigned char *) ".notdef",	/* E4 */
 (unsigned char *) ".notdef",	/* E5 */
 (unsigned char *) ".notdef",	/* E6 */
 (unsigned char *) ".notdef",	/* E7 */
 (unsigned char *) "Lslash",	/* E8 */
 (unsigned char *) "Oslash",	/* E9 */
 (unsigned char *) "OE",	/* EA */
 (unsigned char *) "ordmasculine",	/* EB */
 (unsigned char *) ".notdef",	/* EC */
 (unsigned char *) ".notdef",	/* ED */
 (unsigned char *) ".notdef",	/* EE */
 (unsigned char *) ".notdef",	/* EF */

 (unsigned char *) ".notdef",	/* F0 */
 (unsigned char *) "ae",	/* F1 */
 (unsigned char *) ".notdef",	/* F2 */
 (unsigned char *) ".notdef",	/* F3 */
 (unsigned char *) ".notdef",	/* F4 */
 (unsigned char *) "dotlessi",	/* F5 */
 (unsigned char *) ".notdef",	/* F6 */
 (unsigned char *) ".notdef",	/* F7 */
 (unsigned char *) "lslash",	/* F8 */
 (unsigned char *) "oslash",	/* F9 */
 (unsigned char *) "oe",	/* FA */
 (unsigned char *) "germandbls",/* FB */
 (unsigned char *) ".notdef",	/* FC */
 (unsigned char *) ".notdef",	/* FD */
 (unsigned char *) ".notdef",	/* FE */
 (unsigned char *) ".notdef",	/* FF */

};
#endif

#pragma Code()
