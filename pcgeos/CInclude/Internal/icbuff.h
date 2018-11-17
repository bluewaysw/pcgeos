/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  Spell library
 * FILE:	  icbuff.h
 *
 * AUTHOR:  	  Joon Song: Oct 11, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	10/11/94   	Initial version
 *
 * DESCRIPTION:
 *	This file contains a description of the ICBuff structure.
 *
 *
 * 	$Id: icbuff.h,v 1.1 97/04/04 15:54:02 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _ICBUFF_H_
#define _ICBUFF_H_

typedef struct {
    word	WM_data[4];
} WordMap;

typedef WordFlags SpellInitFlags;
	#define SIF_USER_DICT_ERR	(0x8000)
	/* 1 bit unused */
	#define SIF_HYP_INIT_ERR	(0x2000)
	#define SIF_MULTI_DIAL		(0x1000)
	#define SIF_NO_DIAL		(0x0800)
	#define SIF_BUS_FIN		(0x0400)
	#define SIF_LEGAL_AVAIL		(0x0200)
	#define SIF_MED_SCI_AVAIL	(0x0100)
	#define SIF_INIT_OK		(0x0080)
	#define SIF_SEEK_ERR		(0x0040)
	#define SIF_READ_ERR		(0x0020)
	#define SIF_HEAD_ERR		(0x0010)
	#define SIF_ALLOC_ERR		(0x0008)
	#define SIF_OPEN_ERR		(0x0004)
	#define SIF_CLOSE_ERR		(0x0002)
	#define SIF_LANG_ERR		(0x0001)


typedef WordFlags SpellProcessFlags;
	/* 7 bits unused */
	#define SPF_ODD_HARD_HYPHEN_COMPOUND		(0x0100)
	#define SPF_FOUND_ACRONYM_WITHOUT_PERIODS	(0x0080)
	#define SPF_FOUND_ALTERNATE_HYPHENATION		(0x0040)
	#define SPF_IN_USER_DICT			(0x0020)
	#define SPF_COMPOUND_SPELLING_CHANGE		(0x0010)
	#define SPF_SOFT_HYPHEN				(0x0008)
	#define SPF_MANDATORY_HYPHEN_ALTERNATIVE	(0x0004)
	#define SPF_MANDATORY_HYPHEN_INPUT		(0x0002)
	#define SPF_SPLIT_WORD				(0x0001)


#define ICS_IPDICTIONARY		(1)
#define ICS_CLITIC_PROCESS		(1)
#define ICS_COMPOUND_PROCESS		(1)

#define ICS_DOUBLE_WORD			(1)
#define ICS_HYPHENATION			(0)

#if NO_ANAGRAM_WILDCARD_IN_SPELL_LIBRARY
  #define ICS_ANAGRAM			(0)
#else
  #define ICS_ANAGRAM			(1)
#endif

#define ICS_VREFNUM			(0)
#define ICS_ELECTRONIC_THESAURUS	(0)

#define ICFNAMEMAX			(64)
#define ICPREMAX			(9)
#define ICPOSTMAX			(12)
#define ICCORMAX			(200)
#define ICMAX				(64)
#define ICMAXALT			(20)
#define SPELL_MAX_WORD_LENGTH		(ICMAX+1)


typedef struct {
    SpellTask		ICB_task;
    StandardLanguage	ICB_language;
    LanguageDialect	ICB_dialect;
    char		ICB_masterFname[ICFNAMEMAX+1];

#if ICS_HYPHENATION
    char		ICB_hypmstFname[ICFNAMEMAX+1]l
#endif

    SpellInitFlags	ICB_initFlags;
    SpellProcessFlags	ICB_processFlags;
    SpellErrorFlags	ICB_errorFlags;
    SpellErrorFlagsHigh	ICB_errorFlagsHigh;
    SpellResult		ICB_retCode;
    word		ICB_hypFlag;
    word		ICB_parseFlag;
    WordMap		ICB_hypmap;
    WordMap		ICB_altmap;
    char		ICB_softHypChar;
    char		ICB_word[ICMAX+1];
    char		ICB_altWord[ICMAX+1];
    byte		ICB_periodFlag;
    byte		ICB_trailHyp;
    byte		ICB_leadHyp;
    byte		ICB_trailApostrophe;
    byte		ICB_leadApostrophe;

#if	ICS_CLITIC_PROCESS
    char		ICB_preClitic[ICPREMAX+1];
    char		ICB_postClitic[ICPOSTMAX+1];
#endif

#if	ICS_DOUBLE_WORD
    char		ICB_prevWord[ICMAX+1];
#endif

    word	ICB_len;
    word	ICB_lside;
    word	ICB_rside;

    /* ICB_maps */
    WordMap	ICB_slashMap;
    WordMap	ICB_hyphenMap;
    WordMap	ICB_emDashMap;
    WordMap	ICB_elDashMap;
    /* ICB_endMaps */

    word	ICB_numAlts;
    word	ICB_nextAlt;
    char	ICB_altList[ICCORMAX];
    word	ICB_correctPtr[ICMAXALT];

#if	ICS_ANAGRAM
    word	ICB_subsetAnagram;
#endif

#if	ICS_VREFNUM
    word	ICB_volRefNum;
    word	ICB_hypVolRefNum;
#endif

    void	*ICB_pctlBuff;
    MemHandle	ICB_hctlBuff;
    ChunkHandle	ICB_pwrdBuff;

#if	ICS_COMPOUND_PROCESS
    void	*ICB_pcmpBuff;
    void	*ICB_hcmpBuff;
#endif

#if	ICS_HYPHENATION
    MemHandle	ICB_hypBufHan;
#endif

#if	 ICS_IPDICTIONARY
    MemHandle	ICB_husrBuff;
    void	*ICB_pusrBuff;
    void	*ICB_udid;
#endif

#if	ICS_ELECTRONIC_THESAURUS
    char	ICB_definition[1024];
#endif

    ThreadHandle ICB_spellThread;
} ICBuff;

#endif /* _ICBUFF_H_ */
