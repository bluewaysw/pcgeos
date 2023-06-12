/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttinit.h
 *
 * AUTHOR:	  Jirka Kunze: February 27 2023
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	23/02/23  JK	    Initial version
 *
 * DESCRIPTION:
 *	Declarations of types and functions for the driver function DR_GEN_CHAR.
 ***********************************************************************/

#ifndef _TTCHARS_H_
#define _TTCHARS_H_

#include <geos.h>


/***********************************************************************
 *      varaibles initialized by driver
 ***********************************************************************/

extern word       bitmapSize;


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal  TrueType_Gen_Chars( word                 character, 
                                  FontBuf*             fontBuf,
                                  WWFixedAsDWord       pointSize,
			          const FontInfo*      fontInfo, 
                                  const OutlineEntry*  outlineEntry,
                                  MemHandle            bitmapBlock,
                                  MemHandle            varBlock );


#endif /* _TTCHARS_H_ */
