/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttchars.c
 *
 * AUTHOR:	  Jirka Kunze: December 23 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/23/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_GEN_CHARS.
 ***********************************************************************/

#include "ttadapter.h"
#include "ttchars.h"

/********************************************************************
 *                      TrueType_Gen_Chars
 ********************************************************************
 * SYNOPSIS:	  Generate one character for a font.
 * 
 * PARAMETERS:    character             Character to build (Chars).
 *                pointsize
 *                *fontBuf              Ptr to font data structure.
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Handle to current gstate.
 *                stylesToImplement
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      - find font-file for the requested style from fontInfo
 *                - open outline of character in founded font-file
 *                - calculate requested metrics and return it
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/12/22  JK        Initial Revision
 * 
 *******************************************************************/

void _pascal TrueType_Gen_Chars(
                        word                 character, 
                        WWFixedAsDWord       pointSize,
                        void*                fontBuf,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        TextStyle            stylesToImplement
			) 
{
        /* Api-Funktion für DR_FONT_GEN_CHARS */

        
}
