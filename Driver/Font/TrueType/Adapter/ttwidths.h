/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttwidths.h
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
 *      DR_FONT_GEN_WIDTHS.
 ***********************************************************************/

#ifndef _TTWIDTHS_H_
#define _TTWIDTHS_H_

#include "../FreeType/freetype.h"
#include "ttadapter.h"


/***********************************************************************
 *      structues
 ***********************************************************************/


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

MemHandle _pascal TrueType_Gen_Widths(
                                MemHandle            fontHandle,
                                FontMatrix*          fontMatrix,
                                WWFixedAsDWord       pointSize,
			        const FontInfo*      fontInfo, 
                                const OutlineEntry*  headerEntry,
                                const OutlineEntry*  firstEntry,
                                TextStyle            stylesToImplement,
                                MemHandle            varBlock
);


#endif  /* _TTWIDTHS_H_ */
