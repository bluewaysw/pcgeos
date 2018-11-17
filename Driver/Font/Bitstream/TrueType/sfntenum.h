/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/sfntenum.h
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: sfntenum.h,v 1.1 97/04/18 11:45:24 newdeal Exp $
 *
 ***********************************************************************/

/********************* Revision Control Information **********************************
*                                                                                    *
*     $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/sfntenum.h,v 1.1 97/04/18 11:45:24 newdeal Exp $                                                                       *
*                                                                                    *
*     $Log:	sfntenum.h,v $
 * Revision 1.1  97/04/18  11:45:24  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:55  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:16:33  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:23:02  roberte
 * Release
 * 
 * Revision 6.5  93/01/22  16:00:05  roberte
 * Changed logic of #if for tag_'s. The single quoted string approach in NO GOOD on INTEL either!
 * 
 * Revision 6.4  92/12/29  12:45:44  roberte
 * Changed #ifdef INTEL to #if INTEL so can be compatible
 * with 4-in-1 and speedo.h
 * 
 * Revision 6.3  92/11/19  16:09:16  roberte
 * Release
 * 
 * Revision 6.2  92/04/30  11:53:45  leeann
 * stripped 7 non-ASCII characters
 * 
 * Revision 6.1  91/08/14  16:48:20  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:29:28  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:55:39  mark
 * add rcs control strings
 * 
*************************************************************************************/

/*
	File:		sfnt_enum.h

	Written by:	Mike Reed

	Copyright:	) 1989-1990 by Apple Computer, Inc., all rights reserved.

	Change History (most recent first):

		 <3>	12/20/90	MR		Correct INTEL definition of tag_FontProgram. [rb]
		 <2>	12/11/90	MR		Add trademark selector to naming table list. [rb]
		<10>	  8/8/90	JT		Fixed spelling of SFNT_ENUMS semaphore at the top of the file.
									This prevents the various constants from being included twice.
		 <9>	 7/18/90	MR		Fixed INTEL version of tag_GlyphData
		 <8>	 7/16/90	MR		Conditionalize redefinition of script codes
		 <7>	 7/13/90	MR		Conditionalize enums to allow for byte-reversal on INTEL chips
		 <6>	 6/30/90	MR		Remove tag reference to Tmvt U and TcrypU
		 <4>	 6/26/90	MR		Add all script codes, with SM naming conventions
		 <3>	 6/20/90	MR		Change tag enums to #defines to be ansi-correct
		 <2>	  6/1/90	MR		Add postscript name to sfnt_NameIndex and TpostU to tags.
	To Do:
*/

#ifndef SFNT_ENUMS

typedef enum {
	plat_Unicode,
	plat_Macintosh,
	plat_ISO,
	plat_MS
} sfnt_PlatformEnum;

#ifndef smRoman
typedef enum {
	smRoman,
	smJapanese,
	smTradChinese,
    smChinese,          /* smChinese = smTradChinese,*/
	smKorean,
	smArabic,
	smHebrew,
	smGreek,
	smCyrillic,
    smRussian,          /* smRussian = smCyrillic, */
	smRSymbol,
	smDevanagari,
	smGurmukhi,
	smGujarati,
	smOriya,
	smBengali,
	smTamil,
	smTelugu,
	smKannada,
	smMalayalam,
	smSinhalese,
	smBurmese,
	smKhmer,
	smThai,
	smLaotian,
	smGeorgian,
	smArmenian,
	smSimpChinese,
	smTibetan,
	smMongolian,
	smGeez,
    smEthiopic,         /* smEthiopic = smGeez, */
    smAmharic,          /* smAmharic = smGeez,  */
	smSlavic,
    smEastEurRoman,     /* smEastEurRoman = smSlavic, */
	smVietnamese,
	smExtArabic,
    smSindhi,           /* smSindhi = smExtArabic, */
	smUninterp
} sfnt_ScriptEnum;
#endif

typedef enum {
	lang_English,
	lang_French,
	lang_German,
	lang_Italian,
	lang_Dutch,
	lang_Swedish,
	lang_Spanish,
	lang_Danish,
	lang_Portuguese,
	lang_Norwegian,
	lang_Hebrew,
	lang_Japanese,
	lang_Arabic,
	lang_Finnish,
	lang_Greek,
	lang_Icelandic,
	lang_Maltese,
	lang_Turkish,
	lang_Yugoslavian,
	lang_Chinese,
	lang_Urdu,
	lang_Hindi,
	lang_Thai
} sfnt_LanguageEnum;

typedef enum {
	name_Copyright,
	name_Family,
	name_Subfamily,
	name_UniqueName,
	name_FullName,
	name_Version,
	name_Postscript,
	name_Trademark
} sfnt_NameIndex;

typedef long sfnt_TableTag;

#ifdef NO_GOOD
/* these were #if INTEL, but INTEL hates them this way! */
#define	tag_FontHeader			'head'
#define	tag_HoriHeader			'hhea'
#define	tag_IndexToLoc			'loca'
#define	tag_MaxProfile			'maxp'
#define	tag_ControlValue		'cvt '
#define	tag_PreProgram			'prep'
#define	tag_GlyphData			'glyf'
#define	tag_HorizontalMetrics	'hmtx'
#define	tag_CharToIndexMap		'cmap'
#define	tag_Kerning				'kern'
#define	tag_HoriDeviceMetrics	'hdmx'
#define	tag_NamingTable			'name'
#define	tag_FontProgram			'fpgm'
#define	tag_Postscript			'post'
#define	tag_Editor0				'edt0'
#define	tag_Editor1				'edt1'

#else

#define tag_FontHeader          0x68656164        /* 'head' */
#define tag_HoriHeader          0x68686561        /* 'hhea' */
#define tag_IndexToLoc          0x6c6f6361        /* 'loca' */
#define tag_MaxProfile          0x6d617870        /* 'maxp' */
#define tag_ControlValue        0x63767420        /* 'cvt ' */
#define tag_MetricValue         0x6d767420        /* 'mvt ' */
#define tag_PreProgram          0x70726570        /* 'prep' */
#define tag_GlyphData           0x676c7966        /* 'glyf' */
#define tag_HorizontalMetrics   0x686d7478        /* 'hmtx' */
#define tag_CharToIndexMap      0x636d6170        /* 'cmap' */
#define tag_Kerning             0x6b65726e        /* 'kern' */
#define tag_HoriDeviceMetrics   0x68646d78        /* 'hdmx' */
#define tag_Encryption          0x63727970        /* 'cryp' */
#define tag_NamingTable         0x6e616d65        /* 'name' */
#define tag_FontProgram         0x6670676d        /* 'fpgm' */

#define tag_Editor0             0x65647430        /* 'edt0' */
#define tag_Editor1             0x65644731        /* 'edt1' */

#endif		/* intel */

#endif		/* not sfnt_enums */

#define SFNT_ENUMS
