/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  sllang.h
 * FILE:	  sllang.h
 *
 * AUTHOR:  	  Gene Anderson: Sep 20, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
	3/ 7/91	  atw	    Initial revision
 *	9/20/92	  gene	    Initial C version
 *
 * DESCRIPTION:
 *	This file contains language values.
 *
 *
 * 	$Id: sllang.h,v 1.1 97/04/04 15:58:12 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SLLANG_H_
#define _SLLANG_H_

typedef ByteEnum StandardLanguage;
    #define SL_UNIVERSAL	0

    #define SL_FRENCH		5
    #define SL_GERMAN		6
    #define SL_SWEDISH		7
    #define SL_SPANISH		8
    #define SL_ITALIAN		9
    #define SL_DANISH		10
    #define SL_DUTCH		11
    #define SL_PORTUGUESE	12
    #define SL_NORWEGIAN	13
    #define SL_FINNISH		14
    #define SL_SWISS		15
    #define SL_ENGLISH		16

    #define SL_ARABIC		20
    #define SL_AUSTRALIAN	21
    #define SL_CHINESE		22
    #define SL_GAELIC		23
    #define SL_GREEK		24
    #define SL_HEBREW		25
    #define SL_HUNGARIAN	26
    #define SL_JAPANESE		27
    #define SL_POLISH		28
    #define SL_SERBO_CROATN	29
    #define SL_SLOVAK		30
    #define SL_RUSSIAN		31
    #define SL_TURKISH		32
    #define SL_URDU		33
    #define SL_AFRIKAANS	34
    #define SL_BASQUE		35
    #define SL_CATALAN		36
    #define SL_CANADIAN		37
    #define SL_FLEMISH		38
    #define SL_HAWAIIAN		39
    #define SL_KOREAN		40
    #define SL_LATIN		41
    #define SL_MAORI		42
    #define SL_NZEALAND		43

    #define SL_DEFAULT		SL_ENGLISH

/*
#ifdef ANSI_HACK

struct {
  WordFlags LD_DUMMY_SPACE;
} LanguageDialect;

#else

typedef WordFlags LanguageDialect;

#endif

*/
    #define LD_DEFAULT		0x0080
    #define LD_ISE_BRITISH	0x0040
    #define LD_IZE_BRITISH	0x0020
    #define LD_AUSTRALIAN	0x0010
    #define LD_FINANCIAL	0x0008
    #define LD_LEGAL		0x0004
    #define LD_MEDICAL		0x0002
    #define LD_SCIENCE		0x0001

#endif /* _SLLANG_H_ */
