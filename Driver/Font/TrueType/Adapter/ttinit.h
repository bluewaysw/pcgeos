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


/***********************************************************************
 *      constants
 ***********************************************************************/

#define TTF_DIRECTORY           "TTF"
#define FAMILY_NAME_INDEX       1       // font family name
#define STYLE_NAME_INDEX        2       // font style

#define FONT_FILE_LENGTH        FILE_LONGNAME_BUFFER_SIZE

#define FAMILY_NAME_LENGTH      20
#define STYLE_NAME_LENGTH       16

#define MAKE_FONTID( family )   ( FM_TRUETYPE | ( 0x0fff & toHash ( family )))


/***********************************************************************
 *      functions called by driver
 ***********************************************************************/

void _pascal  TrueType_InitFonts( MemHandle fontInfoBlock );

TT_Error  TrueType_ProcessFont( const char* file, MemHandle fontInfoBlock );

Boolean  isRegistredFontID( FontID fontID, MemHandle fontInfoBlock );

Boolean  isMappedFont( const char* familiyName );

FontID  getMappedFontID( const char* familyName );


/***********************************************************************
 *      internal functions
 ***********************************************************************/

static FontAttrs    mapFamilyClass( TT_Short familyClass );

static FontWeight   mapFontWeight( TT_Short weightClass );

static TextStyle    mapTextStyle( const char* subfamily );

static int  toHash( const char* str );

static int  strlen( const char* str );

static void strcpy( char* dest, const char* source );


#endif  /* _TTINT_H_ */
