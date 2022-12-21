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


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal TrueType_Gen_Widths();


/***********************************************************************
 *      internal functions
 ***********************************************************************/

word GetNumKernPairs( TT_Face face);

void ConvertHeader();

void ConvertKernPairs();

void CalcTransform();

void CalcRoutines();


#endif  /* _TTWIDTHS_H_ */
