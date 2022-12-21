/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttinit.h
 *
 * AUTHOR:	  Jirka Kunze: December 20 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	20/12/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Declarations of types and functions for the driver function 
 *      DR_INIT.
 ***********************************************************************/

#ifndef _TTINIT_H_
#define _TTINIT_H_

#include <geos.h>
#include "../FreeType/freetype.h"


/***********************************************************************
 *      constants
 ***********************************************************************/

#define TTF_DIRECTORY           "TTF"


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal TrueType_Init();


void _pascal TrueType_Exit();


void _pascal TrueType_InitFonts( MemHandle fontInfoBlock );


TT_Error TrueType_ProcessFont( const char* file, MemHandle fontInfoBlock );


/***********************************************************************
 *      internal functions
 ***********************************************************************/


#endif  /* _TTINT_H_ */
