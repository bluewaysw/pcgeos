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


#define WWFIXED_0_POINT_5                   0x00008000
#define WWFIXED_1_POINR_1                   0x00012000

#define ITALIC_FACTOR                       0x0000366A
#define BOLD_FACTOR                         0x00012000 
#define SCRIPT_FACTOR                       0x00006000 
#define SCRIPT_SHIFT_FACTOR                 0x00015000


/***********************************************************************
 *      structues
 ***********************************************************************/

/*
 * c definition of drivers FontMatrix structure
 */
typedef	struct
{
        WWFixedAsDWord          FM_11;
        WWFixedAsDWord          FM_12;
        WWFixedAsDWord          FM_21;
        WWFixedAsDWord          FM_22;
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
