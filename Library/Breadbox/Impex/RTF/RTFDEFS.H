/*----------------------------------------------------------------------------
	%%File: RTFDEFS.H
	%%Unit: RTFREAD
	%%Contact: smueller

	Miscellaneous Rtf related definitions.
----------------------------------------------------------------------------*/

#ifndef RTFDEFS_H
#define RTFDEFS_H

//
// Symbolic names for numeric arguments to enumeration-type keywords
//

// \cpg argument values
#define cpgIBM				437		// United States IBM
#define cpgGreece			737
#define cpgANSI				819		// Windows 3.1
#define cpgIBMMulti			850		// IBM multilingual
#define cpgEasternEurope	852
#define cpgPortugal			860
#define cpgFrenchCanada		863
#define cpgNorway			865
#define cpgRussia			866
#define cpgEasternEuropeWin	1250
#define cpgCyrillicWin		1251
#define cpgGreeceWin		1253
#define cpgTurkey			1254

// \ansicpg argument values
// see codepage.h

// \fbias argument values
#define fbDefault			0
#define fbFarEast			1

// \fcharset, \cchs argument values
// some of these values may also be #defined in windows.h; here's the
// complete list
#define ANSI_CHARSET				0
#define DEFAULT_CHARSET				1
#define SYMBOL_CHARSET				2
#define INVALID_CHARSET				3		// nil value
#define MAC_CHARSET					77
#define SHIFTJIS_CHARSET			128		// CP 932:	Japanese
#define HANGEUL_CHARSET				129		// CP 949:	Korean
#define JOHAB_CHARSET				130
#define GB2312_CHARSET				134		// CP 936:	PRC 		
#define CHINESEBIG5_CHARSET			136		// CP 950:	Taiwan
#define GREEK_CHARSET				161
#define TURKISH_CHARSET				162
#define HEBREW_CHARSET				177
#define ARABIC_CHARSET				178
#define ARABICTRADITIONAL_CHARSET	179
#define ARABICUSER_CHARSET			180
#define HEBREWUSER_CHARSET			181
#define BALTIC_CHARSET				186
#define RUSSIAN_CHARSET				204
#define THAI_CHARSET				222
#define EASTEUROPE_CHARSET			238
#define PC437_CHARSET				254
#define OEM_CHARSET					255

// \fprq argument values
#define prqDefault			0
#define prqFixed			1
#define prqVariable			2

// \lang and \deflang argument values
// see lang.h

// \levelnfc argument values
#define nfcArabic			0	// 1, 2, 3
#define nfcUCRoman			1	// I, II, III
#define nfcLCRoman			2	// i, ii, iii
#define nfcUCLetter			3	// A, B, C
#define nfcLCLetter			4	// a, b, c
#define nfcOrdinal			5	// 1st, 2nd, 3rd
#define nfcCardtext			6	// One, Two, Three
#define nfcOrdtext			7	// First, Second, Third
#define nfcArabicLZ			22	// leading zero: 01, 02, ... 09, 10, 11, ...
#define nfcBullet			23	// bullet, no number
#define nfcNone				255	// no number

// \revbar argument values
#define rvbNoDisplay		0
#define rvbLeftMargin		1
#define rvbRightMargin		2
#define rvbOutsideMargin	3	// default

// \revprop argument values
#define revNoDisplay		0
#define revBold				1
#define revItalic			2
#define revUnderline		3	// default
#define revDoubleUnderline	4

// \wmetafile argument values
// these values are also #defined in windows.h; on platforms that have it
#define MM_TEXT             1
#define MM_LOMETRIC         2
#define MM_HIMETRIC         3
#define MM_LOENGLISH        4
#define MM_HIENGLISH        5
#define MM_TWIPS            6
#define MM_ISOTROPIC        7
#define MM_ANISOTROPIC      8
#define MM_MIN              MM_TEXT
#define MM_MAX              MM_ANISOTROPIC

#endif // RTFDEFS_H
