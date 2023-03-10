/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttchars.c
 *
 * AUTHOR:	  Jirka Kunze: December 23 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/23/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_GEN_CHARS.
 ***********************************************************************/

#include "ttadapter.h"
#include "ttchars.h"
#include "ttcharmapper.h"
#include <ec.h>


/********************************************************************
 *                      TrueType_Gen_Chars
 ********************************************************************
 * SYNOPSIS:	  Generate one character for a font.
 * 
 * PARAMETERS:    character             Character to build (Chars).
 *                pointsize
 *                *fontBuf              Ptr to font data structure.
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Handle to current gstate.
 *                stylesToImplement
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      - find font-file for the requested style from fontInfo
 *                - open outline of character in founded font-file
 *                - calculate requested metrics and return it
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/12/22  JK        Initial Revision
 * 
 *******************************************************************/

void _pascal TrueType_Gen_Chars(
                        word                 character, 
                        WWFixedAsDWord       pointSize,
                        FontBuf*             fontBuf,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        TextStyle            stylesToImplement
			) 
{
        FileHandle             truetypeFile;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_Error               error;
        TT_Face                face;
        TT_Instance            instance;
        TT_Glyph               glyph;
        TT_Outline             outline;
        TT_BBox                bbox;
        TT_CharMap             charMap;
        TT_UShort              charIndex;
        word                   width, height;


        ECCheckBounds( (void*)fontBuf );
        ECCheckBounds( (void*)fontInfo );
        ECCheckBounds( (void*)outlineEntry );


        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        // get filename an load ttf file 
        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
        truetypeFile = FileOpen( trueTypeOutline->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );
        
        ECCheckFileHandle( truetypeFile );

        /* open face, create instance and glyph */
        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fail;

        TT_New_Glyph( face, &glyph );
        TT_New_Instance( face, &instance );

         /* get TT char index */
        getCharMap( face, &charMap );
        charIndex = TT_Char_Index( charMap, GeosCharToUnicode( character ) );

        /* set pointsize and get metrics */
        TT_Set_Instance_CharSize( instance, ( pointSize >> 10 ) );

        /* load glyph and load glyphs outline */
        TT_Load_Glyph( instance, glyph, charIndex, TTLOAD_DEFAULT );

        // TODO: Transformationsmatrix anwenden


        TT_Get_Glyph_Outline( glyph, &outline );
        TT_Get_Outline_BBox( &outline, &bbox );

        /* Grid-fit it */
        bbox.xMin &= -64;
        bbox.xMax  = ( bbox.xMax + 63 ) & -64;
        bbox.yMin &= -64;
        bbox.yMax  = ( bbox.yMax + 63 ) & -64;

        /* compute pixel dimensions */
        width  = (bbox.xMax - bbox.xMin) / 64;
        height = (bbox.yMax - bbox.yMin) / 64;

        if( fontBuf->FB_flags & FBF_IS_REGION )
        {
                // Platzbedarf der Region ermitteln

                // absichern dass im BitmapBlock genügend Platz vorhanden ist

                // Outline verschieben

                // an TT_Get_Outline_Region delegieren

                // Header in Region verschieben

                // size in dgoup zurückschreiben
        }
        else
        {
                CharData*      charData;
                TT_Raster_Map  rasterMap;
                word           size = height * ( ( width + 7 ) / 8 ) + SIZE_CHAR_HEADER;

                /* get pointer to bitmapBlock */
                if( MemGetInfo( bitmapHandle, MGIT_SIZE ) < size )
                        MemReAlloc( bitmapHandle, size, HAF_NO_ERR );
                charData = MemLock( bitmapHandle );

                /* init rasterMap */
                rasterMap.rows   = height;
                rasterMap.width  = width;
                rasterMap.cols   = (width + 7) / 8;
                rasterMap.size   = rasterMap.rows * rasterMap.cols;
                rasterMap.bitmap = charData + SIZE_CHAR_HEADER;

                /* translate outline and render it */
                TT_Translate_Outline( &outline, -bbox.xMin, -bbox.yMin );
                TT_Get_Outline_Bitmap( &outline, &rasterMap );

                /* fill header of charData */
                charData->CD_pictureWidth = width;
                charData->CD_numRows      = height;
                charData->CD_xoff         = bbox.xMin;
                charData->CD_yoff         = bbox.yMin;

                /* save size of bitmap */
                bitmapSize = size;
        }

        // FontBlock ggf. kürzen und neues Glyph anhängen erfolgt auf asm Seite

        TT_Done_Glyph( glyph );
        TT_Done_Instance( instance );

Fail:
        FileClose( truetypeFile, FALSE );
        FilePopDir(); 
}
