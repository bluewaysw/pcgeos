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
 *	    Declarations of types and functions for the driver function 
 *      DR_FONT_GEN_WIDTHS.
 ***********************************************************************/

#ifndef _TTWIDTHS_H_
#define _TTWIDTHS_H_

#include "../FreeType/freetype.h"
#include "ttadapter.h"


#define WWFIXED_0_POINT_5                   0x00008000
#define WWFIXED_1_POINR_1                   0x00012000


/***********************************************************************
 *      structues
 ***********************************************************************/

typedef	struct
{
        WWFixed                 FM_11;
        WWFixed                 FM_12;
        WWFixed                 FM_21;
        WWFixed                 FM_22;
} FontMatrix;


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

MemHandle _pascal TrueType_Gen_Widths(
                                MemHandle        fontHandle,
                                FontMatrix*      fontMatrix,
                                const FontInfo*  fontInfo,
                                WWFixedAsDWord   pointSize,
                                TextStyle        textStyle,
                                FontWidth        fontWidth,
                                FontWeight       fontWeight
);


#endif  /* _TTWIDTHS_H_ */
