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
 *	Declarations of types and functions for the driver function DR_INIT.
 ***********************************************************************/

#ifndef _TTINIT_H_
#define _TTINIT_H_

#include <geos.h>
#include <fontID.h>
#include <font.h>
#include <graphics.h>
#include "../FreeType/freetype.h"
#include "ttadapter.h"


/***********************************************************************
 *      constants for font mapping
 ***********************************************************************/

#define FONTMAPPING_CATEGORY            "FontMapping"   


/***********************************************************************
 *      constants for ttf name tables
 ***********************************************************************/

#define FAMILY_NAME_ID                  1 
#define STYLE_NAME_ID                   2

#define PLATFORM_ID_MAC                 1
#define PLATFORM_ID_MS                  3

#define ENCODING_ID_MAC_ROMAN           0
#define ENCODING_ID_MS_UNICODE_BMP      1
#define ENCODING_ID_UNICODE		        3

#define LANGUAGE_ID_MAC_EN              0
#define LANGUAGE_ID_WIN_EN_US           0x0409


/***********************************************************************
 *      constants for string length
 ***********************************************************************/

#define FAMILY_NAME_LENGTH              20
#define STYLE_NAME_LENGTH               16
#define FONT_FILE_LENGTH                FILE_LONGNAME_BUFFER_SIZE


/***********************************************************************
 *      macros for calculating values in FontHeader
 ***********************************************************************/

#define DEFAULT_CONTINUITY_CUTOFF( value )  ( value / 40 )      // 2.5% of size
#define DEFAULT_DEFAULT_CHAR                '.'
#define BASELINE( value )                   ( 3 * value / 4 )	// 75% of size
#define DESCENT( value )            	    ( value / 4 )       // 25% of size
#define DEFAULT_UNDER_THICK( value )	    ( value / 10 )      // 10% of size
#define DEFAULT_UNDER_POSITION( value )	    ( value / -10 )     // -10% of size
#define SAFETY( value )			            ( value / 40 )      // 2.5% of size


/***********************************************************************
 *      macro for calculating font ID
 ***********************************************************************/

#define MAKE_FONTID( family )               ( FM_TRUETYPE | ( 0x0fff & toHash ( family )))


/***********************************************************************
 *      structues
 ***********************************************************************/

typedef struct
{
    word                        FH_h_height;        //top of 'H'
    word                        FH_x_height;        //top of 'x'
    word                        FH_ascender;        //top of 'd'
    word                        FH_descender;       //bottom of 'p'
    word                        FH_avgwidth;        //average character width
    word                        FH_maxwidth;        //widest character width
    word                        FH_height;          //height of font box
    word                        FH_accent;          //height of accents
    word                        FH_ascent;          //height of caps
    word                        FH_descent;         //descent (from baseline)
    word                        FH_baseAdjust;      //adjustment for baseline
    char                        FH_firstChar;       //first char defined
    char                        FH_lastChar;        //last char defined
    char                        FH_defaultChar;     //default character
    word                        FH_underPos;        //position of underline   		
    word                        FH_underThick;      //thickness of underline
    word                        FH_strikePos;       //position of strikethrough
    word                        FH_numChars;        //number of characters
    sword                       FH_minLSB;          //minimum left side bearing
    sword                       FH_minTSB;          //minimum top side bound
    sword                       FH_maxBSB;          //maximum bottom side bound
    sword                       FH_maxRSB;          //maximum right side bound
    sword                       FH_continuitySize;  //continuity cutoff
} FontHeader;


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal  TrueType_InitFonts( MemHandle fontInfoBlock );


#endif  /* _TTINT_H_ */
