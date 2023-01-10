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
#include <fontID.h>
#include <font.h>
#include <graphics.h>
#include "../FreeType/freetype.h"
#include "ttadapter.h"


/***********************************************************************
 *      constants
 ***********************************************************************/

#define TTF_DIRECTORY                   "TTF"
#define FONTMAPPING_CATEGORY            "FontMapping"

#define FAMILY_NAME_ID                  1       // id for font family name
#define STYLE_NAME_ID                   2       // id for font style

#define FONT_FILE_LENGTH                FILE_LONGNAME_BUFFER_SIZE

#define FAMILY_NAME_LENGTH              20
#define STYLE_NAME_LENGTH               16

#define MAKE_FONTID( family )           ( FM_TRUETYPE | ( 0x0fff & toHash ( family )))


#define PLATFORM_ID_MAC                 1
#define PLATFORM_ID_MS                  3

#define ENCODING_ID_MAC_ROMAN           0
#define ENCODING_ID_MS_UNICODE_BMP      1
#define ENCODING_ID_UNICODE		3

#define LANGUAGE_ID_MAC_EN              0
#define LANGUAGE_ID_WIN_EN_US           0x0409


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal  TrueType_InitFonts( MemHandle fontInfoBlock );


/***********************************************************************
 *      internal functions
 ***********************************************************************/

static int  toHash( const char* str );

static int  strlen( const char* str );

static void strcpy( char* dest, const char* source );


#endif  /* _TTINT_H_ */
