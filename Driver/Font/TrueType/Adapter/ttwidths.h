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


/*
 * Structure to hold information necessary to fill FontBuf structure. 
 */
typedef struct
{
    word                        FH_h_height;        //top of 'H'
    word                        FH_x_height;        //top of 'x'
    word                        FH_ascender;        //top of 'd'
    sword                       FH_descender;       //bottom of 'p'
    word                        FH_avgwidth;        //average character width
    word                        FH_maxwidth;        //widest character width
    word                        FH_height;          //height of font box
    sword                       FH_accent;          //height of accents
    word                        FH_ascent;          //height of caps
    sword                       FH_descent;         //descent (from baseline)
    sword                       FH_baseAdjust;      //adjustment for baseline
    word                        FH_firstChar;       //first char defined
    word                        FH_lastChar;        //last char defined
    word                        FH_defaultChar;     //default character
    sword                       FH_underPos;        //position of underline   		
    sword                       FH_underThick;      //thickness of underline
    word                        FH_strikePos;       //position of strikethrough
    word                        FH_numChars;        //number of characters
    sword                       FH_minLSB;          //minimum left side bearing
    sword                       FH_minTSB;          //minimum top side bound
    sword                       FH_maxBSB;          //maximum bottom side bound
    sword                       FH_maxRSB;          //maximum right side bound
    sword                       FH_continuitySize;  //continuity cutoff
} FontHeader;



/*
 * constants for calculating values in FontHeader
 */
#define DEFAULT_CONTINUITY_CUTOFF( value )  ( value / 40 )      // 2.5% of size
#define DEFAULT_DEFAULT_CHAR                '.'
#define BASELINE( value )                   ( 3 * value / 4 )	// 75% of size
#define DESCENT( value )            	    ( value / 4 )       // 25% of size
#define DEFAULT_UNDER_THICK( value )	    ( value / 10 )      // 10% of size
#define DEFAULT_UNDER_POSITION( value )	    ( value / -10 )     // -10% of size
#define SAFETY( value )			            ( value / 40 )      // 2.5% of size




/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal TrueType_Gen_Widths();


/***********************************************************************
 *      internal functions
 ***********************************************************************/

TT_Error Fill_CharTableEntry( const FontInfo*  fontInfo, 
                              word             character,
                              CharTableEntry*  charTableEntry );

TT_Error Fill_FontBuf( TT_Face face, WBFixed pointSize, FontBuf* fontBuf );

TT_Error fillFontHeader( TT_Face face, TT_Instance instance, FontHeader* fontHeader );

word GetNumKernPairs( TT_Face face);

void ConvertHeader();

void ConvertKernPairs();

void CalcTransform();

void CalcRoutines();


#endif  /* _TTWIDTHS_H_ */
