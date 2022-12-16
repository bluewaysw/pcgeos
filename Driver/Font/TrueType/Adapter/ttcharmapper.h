/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttcharmapper.h
 *
 * AUTHOR:	  Jirka Kunze: December 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/5/22	  JK	    Initial version
 *
 * DESCRIPTION:
 *	Structures and definitions for mapping character from FreeGEOS 
 *      charset zu Unicode charset.
 ***********************************************************************/
#ifndef _TTCHARMAPPER_H_
#define _TTCHARMAPPER_H_

#include <geos.h>
#include <freetype.h>


typedef ByteFlags CharMapFlags;
#define CMF_CAP         0x10
#define CMF_ASCENT      0x08
#define CMF_DESCENT     0x04
#define CMF_MEAN        0x02
#define CMF_ACCENT      0x01


/*
 * Entry for converting FreeGEOS chars to unicode. 
 */
typedef struct 
{
        word            unicode;
        byte            weight;
        CharMapFlags    flags;
} CharMapEntry;


/*
 * Structure to hold information necessary to fill FontBuf structure. 
 */
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
    word                        FH_firstChar;       //first char defined
    word                        FH_lastChar;        //last char defined
    word                        FH_defaultChar;     //default character
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


word CountGeosCharsInCharMap( TT_CharMap map, word *firstChar, word *lastChar );

TT_Error getCharMap( TT_Face face, TT_CharMap* charMap );

TT_Error fillFontHeader( TT_Face face, TT_Instance instance, FontHeader* fontHeader );

void ScanCharXMin( TT_Glyph glyph, FontHeader* fontHeader );

#endif  /* _TTCHARMAPPER_H_ */
