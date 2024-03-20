/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttpath.h
 *
 * AUTHOR:	  Jirka Kunze: August 25 2023
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	25/08/23  JK	    Initial version
 *
 * DESCRIPTION:
 *	Declarations of types and functions for the driver function 
 *      DR_FONT_GEN_WIDTHS.
 ***********************************************************************/

#ifndef _TTPATH_H_
#define _TTPATH_H_

#include "../FreeType/freetype.h"
#include "ttadapter.h"


/***********************************************************************
 *      structues
 ***********************************************************************/


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal TrueType_Gen_Path( 
                        GStateHandle         gstate,
                        FontGenPathFlags     pathFlags,
                        word                 character,
                        const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        const OutlineEntry*  firstEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            varBlock );

void _pascal TrueType_Gen_In_Region( 
                        GStateHandle         gstate,
                        Handle               regionPath,
                        word                 character,
                        WWFixedAsDWord       pointSize,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            varBlock );


/***********************************************************************
 *      wrapper functions
 ***********************************************************************/

extern void _pascal GrRegionPathMovePen(
                        Handle regionHandle, sword x, sword y );

extern void _pascal GrRegionPathLineTo( 
                        Handle regionHandle, sword x, sword y );

extern void _pascal GrRegionPathCurveTo(
                        Handle regionHandle, Point *points );

extern void _pascal GrRegionPathInit(
                        Handle regionHandle, word maxY);                        


#ifdef __HIGHC__
pragma Alias(GrRegionPathMovePen, "GRREGIONPATHMOVEPEN");
pragma Alias(GrRegionPathLineTo, "GRREGIONPATHDRAWLINETO");
pragma Alias(GrRegionPathDrawCurve, "GRREGIONPATHDRAWCURVE");
pragma Alias(GrRegionPathInit, "GRREGIONPATHINIT");
#endif

#endif  /* _TTPAHT_H_ */
