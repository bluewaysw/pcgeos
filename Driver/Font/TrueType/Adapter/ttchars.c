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
#include <string.h>


static void CopyChar( FontBuf* fontBuf, word geosChar, void* charData, word charDataSize );
static void ShrinkFontBuf( FontBuf* fontBuf );
static int FindLRUChar( FontBuf* fontBuf, int numOfChars );
static void AdjustPointers( CharTableEntry* charTableEntries, 
                            CharTableEntry* lruEntry, 
                            word sizeLRUEntry,
                            word numOfChars );
static word ShiftCharData( FontBuf* fontBuf, CharData* charData );
static word ShiftRegionCharData( FontBuf* fontBuf, RegionCharData* charData );


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
 *      12/23/22  JK        Initial Revision
 * 
 *******************************************************************/

void _pascal TrueType_Gen_Chars(
                        word                 character, 
                        FontBuf*             fontBuf,
                        WWFixedAsDWord       pointSize,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            bitmapHandle
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
        TT_Raster_Map          rasterMap;
        void*                  charData;
        word                   width, height, size;


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
                /* We calculate with an average of 4 on/off points, line number and line end code. */
                size = height * 6 * sizeof( word ) + SIZE_REGION_HEADER; 

                /* get pointer to bitmapBlock */
                if( MemGetInfo( bitmapHandle, MGIT_SIZE ) < size )
                        MemReAlloc( bitmapHandle, size, HAF_NO_ERR );
                charData = MemLock( bitmapHandle );

                /* init rasterMap */
                rasterMap.rows   = height;
                rasterMap.width  = width;
                rasterMap.flow   = TT_Flow_Down;
                rasterMap.bitmap = ((byte*)charData) + SIZE_REGION_HEADER;

                /* translate outline and render it */
                TT_Translate_Outline( &outline, -bbox.xMin, -bbox.yMin );
                TT_Get_Outline_Region( &outline, &rasterMap );

                /* fill header of charData */
                ((RegionCharData*)charData)->RCD_xoff = bbox.xMin;
                ((RegionCharData*)charData)->RCD_xoff = bbox.yMin;
                ((RegionCharData*)charData)->RCD_size = rasterMap.size;
                ((RegionCharData*)charData)->RCD_bounds.R_left   = 0;
                ((RegionCharData*)charData)->RCD_bounds.R_right  = width;
                ((RegionCharData*)charData)->RCD_bounds.R_top    = height;
                ((RegionCharData*)charData)->RCD_bounds.R_bottom = 0;

                size = rasterMap.size;
        }
        else
        {      
                size = height * ( ( width + 7 ) / 8 ) + SIZE_CHAR_HEADER;

                /* get pointer to bitmapBlock */
                if( MemGetInfo( bitmapHandle, MGIT_SIZE ) < size )
                        MemReAlloc( bitmapHandle, size, HAF_NO_ERR );
                charData = MemLock( bitmapHandle );

                /* init rasterMap */
                rasterMap.rows   = height;
                rasterMap.width  = width;
                rasterMap.cols   = (width + 7) / 8;
                rasterMap.size   = rasterMap.rows * rasterMap.cols;
                rasterMap.flow   = TT_Flow_Down;
                rasterMap.bitmap = ((byte*)charData) + SIZE_CHAR_HEADER;

                /* translate outline and render it */
                TT_Translate_Outline( &outline, -bbox.xMin, -bbox.yMin );
                TT_Get_Outline_Bitmap( &outline, &rasterMap );

                /* fill header of charData */
                ((CharData*)charData)->CD_pictureWidth = width;
                ((CharData*)charData)->CD_numRows      = height;
                ((CharData*)charData)->CD_xoff         = bbox.xMin;
                ((CharData*)charData)->CD_yoff         = bbox.yMin;
        }

        TT_Done_Glyph( glyph );
        TT_Done_Instance( instance );

        if( fontBuf->FB_dataSize > MAX_FONTBUF_SIZE )
                ShrinkFontBuf( fontBuf );

        /* realloc FontBuf if necessary */
 /*       if( MemGetInfo( MemPtrToHandle( fontBuf ), MGIT_SIZE ) < fontBuf->FB_dataSize + size )
        {
                MemReAlloc( PtrToSegment( fontBuf ),
                        fontBuf->FB_dataSize + size,
                        HAF_STANDARD_NO_ERR );
                fontBuf = MemDeref( PtrToSegment( fontBuf ));
        } */

        /* add rendered glyph to fontbuf */
        CopyChar( fontBuf, character, charData ,size );

        /* cleanup */
        MemUnlock( bitmapHandle );
Fail:
        FileClose( truetypeFile, FALSE );
        FilePopDir(); 
}


/********************************************************************
 *                      CopyChar
 ********************************************************************
 *
 *******************************************************************/
static void CopyChar( FontBuf* fontBuf, word geosChar, void* charData, word charDataSize ) 
{
        word  indexGeosChar = geosChar - fontBuf->FB_firstChar;
        CharTableEntry*  charTableEntries = (CharTableEntry*) ((byte*)fontBuf) + sizeof( FontBuf );


        /* copy rendered Glyph to fontBuf */
        memmove( ((byte*)fontBuf) + fontBuf->FB_dataSize, charData, charDataSize );

        /* update CharTableEntry and FontBuf */
        charTableEntries[indexGeosChar].CTE_dataOffset = fontBuf->FB_dataSize;       
        fontBuf->FB_dataSize += charDataSize;
}


/********************************************************************
 *                      ShrinkFontBuf
 ********************************************************************
 *
 *******************************************************************/
static void ShrinkFontBuf( FontBuf* fontBuf ) 
{
        word  numOfChars = fontBuf->FB_lastChar - fontBuf->FB_firstChar + 1;
        CharTableEntry*  charTableEntries = (CharTableEntry*) ((byte*)fontBuf) + sizeof( FontBuf );
        word  sizeCharData;


        /* shrink fontBuf if necessary */
        while( fontBuf->FB_dataSize > MAX_FONTBUF_SIZE )
        {
                word  indexLRUChar = FindLRUChar( fontBuf, numOfChars );
                void* charData = ((byte*)fontBuf) + charTableEntries[indexLRUChar].CTE_dataOffset;

                /* ensure that we have a char to remove */
                if( indexLRUChar == -1 )
                        return;

                /* remove CharData of lru char */
                if( fontBuf->FB_flags & FBF_IS_REGION )
                        sizeCharData = ShiftRegionCharData( fontBuf, (RegionCharData*)charData );
                else
                        sizeCharData = ShiftCharData( fontBuf, (CharData*)charData );

                /* adjust pointers in CharTableEntries */
                AdjustPointers( charTableEntries, &charTableEntries[indexLRUChar], sizeCharData, numOfChars );

                /* update CharTableEntry */
                charTableEntries[indexLRUChar].CTE_dataOffset = CHAR_NOT_BUILT;
                charTableEntries[indexLRUChar].CTE_usage      = 0;

                /* update FontBuf */
                fontBuf->FB_dataSize -= sizeCharData;
        }
}

/********************************************************************
 *                      FindLRUChar
 ********************************************************************
 *
 *******************************************************************/
static int FindLRUChar( FontBuf* fontBuf, int numOfChars )
{
        word             lru = 0xffff;
        int              indexLRUChar = -1;
        int              i;
        CharTableEntry*  charTableEntry = (CharTableEntry*) ((byte*)fontBuf) + sizeof( FontBuf );


        for( i = 0; i < numOfChars; i++, charTableEntry++ )
        {
                /* if no data, go to next char */
                if( charTableEntry->CTE_dataOffset < CHAR_MISSING )
                        continue;

                if( charTableEntry->CTE_usage < lru )
                {
                        lru = charTableEntry->CTE_usage;
                        indexLRUChar = i;
                }

        }

        return indexLRUChar;
} 

/********************************************************************
 *                      AdjustPointers
 ********************************************************************
 *
 *******************************************************************/
static void AdjustPointers( CharTableEntry* charTableEntries, 
                            CharTableEntry* lruEntry, 
                            word sizeLRUEntry,
                            word numOfChars )
{
        word  i;

        for( i = 0; i < numOfChars; i++ )
                if( charTableEntries[i].CTE_dataOffset > lruEntry->CTE_dataOffset )
                        charTableEntries[i].CTE_dataOffset -= sizeLRUEntry;
}

/********************************************************************
 *                      ShiftCharData
 ********************************************************************
 *
 *******************************************************************/
static word ShiftCharData( FontBuf* fontBuf, CharData* charData )
{
        word  size = charData->CD_pictureWidth * charData->CD_numRows + SIZE_CHAR_HEADER;
 
 
        memmove( charData, 
                ((byte*)charData) + size, 
                ((byte*)charData) - ((byte*)fontBuf) + fontBuf->FB_dataSize );

        return size;
}

/********************************************************************
 *                      ShiftRegionCharData
 ********************************************************************
 *
 *******************************************************************/
static word ShiftRegionCharData( FontBuf* fontBuf, RegionCharData* charData )
{
        word size = charData->RCD_size + SIZE_REGION_HEADER;


        memmove( charData, 
                ((byte*)charData) + size, 
                ((byte*)charData) - ((byte*)fontBuf) + fontBuf->FB_dataSize );

        return size;
}
