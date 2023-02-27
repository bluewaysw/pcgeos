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

extern MemHandle  bitmapHandle;
extern word       bitmapSize;


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal  TrueType_Gen_Chars( word                 character, 
                                  WWFixedAsDWord       pointSize,
                                  void*                fontBuf,
			          const FontInfo*      fontInfo, 
                                  const OutlineEntry*  outlineEntry,
                                  TextStyle            stylesToImplement );


#endif /* _TTCHARS_H_ */
