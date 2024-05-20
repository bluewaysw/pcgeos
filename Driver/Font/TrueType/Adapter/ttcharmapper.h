/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttcharmapper.h
 *
 * AUTHOR:	  Jirka Kunze: December 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/5/22	  JK	    Initial version
 *
 * DESCRIPTION:
 *	    Structures and definitions for mapping character from FreeGEOS 
 *      charset zu Unicode charset.
 ***********************************************************************/
#ifndef _TTCHARMAPPER_H_
#define _TTCHARMAPPER_H_

#include <geos.h>
#include <freetype.h>
#include "ttadapter.h"


typedef ByteFlags CharMapFlags;
#define CMF_CAP         0x10
#define CMF_ASCENT      0x08
#define CMF_DESCENT     0x04
#define CMF_MEAN        0x02
#define CMF_ACCENT      0x01


/*
 * Entry for converting FreeGEOS chars to unicode. 
 */
typedef struct 
{
        word            unicode;
        CharMapFlags    flags;
        word            ttIndex;
} CharMapEntry;


/***********************************************************************
 *      internal functions
 ***********************************************************************/

word GeosCharToUnicode( word geosChar );

word InitGeosCharsInCharMap( TT_CharMap map, char* firstChar, char* lastChar );

TT_Error getCharMap( TRUETYPE_VARS, TT_CharMap* charMap );

CharMapFlags GeosCharMapFlag( word geosChar );

char getGeosCharForIndex( word ttIndex );


#endif  /* _TTCHARMAPPER_H_ */
