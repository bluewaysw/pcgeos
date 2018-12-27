/****************************************************************************
 *
 * ==CONFIDENTIAL INFORMATION== 
 * COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
 * ALL RIGHTS RESERVED  --
 * THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
 * NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
 * RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
 * NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
 * CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
 * AGREEMENT.
 *
 * Project: Word For Windows Core Library
 * File:    global.h
 *
 ***************************************************************************/

#ifndef __GLOBAL_H
#define __GLOBAL_H

#include <graphics.h>
#include <Objects/Text/tCommon.h>
#include <file.h>
#include <sstor.h>
#include <xlatLib.h>
#include "structs.h"

extern TransError G_WFWError;
#define SetError(x) G_WFWError = (x)
#define GetError() G_WFWError

extern Boolean G_WFW8;
#define IsWord8 G_WFW8
#define IsWord6 (!G_WFW8)

extern FileHandle hInputFile;
extern StgDocfile hInputDoc;
extern StgStorage hInputRootStg;
extern StgStream hInputDocStream;
extern StgStream hInputTextStream;
extern StgStream hInputTableStream;
extern StgStream hInputDataStream;
extern ushort hInputStyle;
extern CHP sInputStyleChp;
extern SEP sGlobalSep;

/* If vtextc.goh hasn't been included, define the PageSetupInfo struct here.
   This allows code files that don't need to be GOC to include this header. */
#ifndef VM_ELEMENT_ARRAY_CHUNK

#include <vm.h>
#include <print.h>
/*
 *	The following structure is plugged into the TTBH_pageSetup field
 *	by apps during an export.
 */
typedef struct {
    VMChainLink	PSI_meta;
    XYSize  	PSI_page;
    PageLayout  PSI_layout;
    word    	PSI_numColumns;
    word    	PSI_columnSpacing;  	/* Points * 8 */
    word    	PSI_ruleWidth;		/* Pixels (points) */
/* The margins are relative to the edges of the page */
    word    	PSI_leftMargin;	    	/* Points * 8 */
    word    	PSI_rightMargin;    	/* Points * 8 */
    word    	PSI_topMargin;	    	/* Points * 8 */
    word    	PSI_bottomMargin;   	/* Points * 8 */
} PageSetupInfo;

#endif

void TextBufferInit(void);
void TextBufferFree(void);
Boolean TextBufferIsEmpty(void);
void TextBufferAddChar(char c);
void TextBufferAddString(char* p);
void TextBufferDump(void);

void DefaultGetCharAttrs(CHP *pChp);
void DefaultGetParaAttrs(PAP *pPap);
void DefaultGetSepAttrs(SEP *pSep);

void GlobalGetPageSetup(PageSetupInfo *psi);

Boolean SetErrorStg(StgError error);	/* returns FALSE on error */

#endif /* __GLOBAL_H */
