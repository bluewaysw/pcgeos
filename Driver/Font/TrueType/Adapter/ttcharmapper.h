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
 *	05.12.22  JK	    Initial version
 *      21.09.25  JK        refactoring
 *
 * DESCRIPTION:
 *	Structures and definitions for mapping character from FreeGEOS 
 *      charset zu Unicode charset.
 ***********************************************************************/
#ifndef _TTCHARMAPPER_H_
#define _TTCHARMAPPER_H_

#include <geos.h>
#include <freetype.h>
#include "ttadapter.h"


/*
 * Entry for lookup table for handling truetype kernpairs.
 */
typedef struct
{
        word ttindex;
        char geoscode;
} LookupEntry;


/***********************************************************************
 *      definitions
 ***********************************************************************/

#define DestroyIndexLookupTable( memH ) ( MemFree( memH ))


/***********************************************************************
 *      internal functions
 ***********************************************************************/

word  GeosCharToUnicode( const word  geosChar );

word  CountValidGeosChars( const TT_CharMap  map, 
                           char*  firstChar, char*  lastChar );

MemHandle  CreateIndexLookupTable( const TT_CharMap  map );

word  GetGEOSCharForIndex( const LookupEntry*  lookupTable, const word  index );

#endif  /* _TTCHARMAPPER_H_ */
