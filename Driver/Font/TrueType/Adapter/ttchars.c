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

#include "ttacache.h"
#include "ttadapter.h"
#include "ttchars.h"
#include "ttcharmapper.h"
#include <ec.h>
#include <string.h>


static void CopyChar( FontBuf* fontBuf, word geosChar, void* charData, word charDataSize );
static void ShrinkFontBuf( FontBuf* fontBuf, word sizeNewChar );
static int FindLRUChar( FontBuf* fontBuf, int numOfChars );
static void AdjustPointers( CharTableEntry* charTableEntries, 
                            CharTableEntry* lruEntry, 
                            word sizeLRUEntry,
                            word numOfChars );
static word RemoveCharData( FontBuf* fontBuf, word offsetCharData );
static void* EnsureBitmapBlock( MemHandle bitmapHandle, word size );
static sword RenderGreyChar( TT_Outline* outline, TT_Raster_Map* rasterMap, TT_BBox* glyphBBox,
                             TransformMatrix* transformMatrix,
                             sword width, sword height, word phases,
                             MemHandle bitmapHandle, void** charDataPtr );
static void RenderGreyFallback( TT_Outline* outline, TT_Raster_Map* rasterMap,
                                sword width, sword height,
                                word pad, word phases,
                                byte* out, word greyCols, word phaseSize,
                                byte* work, word workSize );
static byte GreyCoverage( const byte* row, word hiCols, word hiWidth, sword col );


/********************************************************************
 *                      TrueType_Gen_Chars
 ********************************************************************
 * SYNOPSIS:	  Generate one character for a font.
 * 
 * PARAMETERS:    character             Character to build (Chars).
 *                *fontBuf              Ptr to font data structure.
 *                pointsize             Desired point size.
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                bitmapHandle          Memory handle to bitmapblock.
 *                varBlock              Memory handle to var block.
 *                
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
                        Byte                 widthIn,
                        Byte                 weight,
                        const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            bitmapHandle,
                        MemHandle            varBlock ) 
{
        MemHandle              fontBufHandle;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_UShort              charIndex;
        TrueTypeVars*          trueTypeVars;
        TransformMatrix*       transformMatrix;
        TT_Raster_Map          rasterMap;
        TT_BBox                glyphBBox;
        TT_Outline             outline;
        void*                  charData;
        sword                  width, height, size;


EC(     ECCheckBounds( (void*)fontBuf ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckMemHandle( bitmapHandle ) );
EC(     ECCheckMemHandle( varBlock ) );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
EC(     ECCheckBounds( (void*)trueTypeOutline ) );

        /* open face and instance */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fin;

         /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );
        if( charIndex == 0 )
                goto Fail;

        /* get transformmatrix */
        transformMatrix = (TransformMatrix*)(((byte*)fontBuf) + sizeof( FontBuf ) + ( fontBuf->FB_lastChar - fontBuf->FB_firstChar + 1 ) * sizeof( CharTableEntry ));
EC(     ECCheckBounds( (void*)transformMatrix ) );

        /* set pointsize and resolution */
        TT_Set_Instance_CharSize_And_Resolutions( INSTANCE, pointSize >> 10, transformMatrix->TM_resolution );

        /* load glyph and load glyphs outline */
        /* Greyscale glyphs may be loaded without hinting: then they */
        /* keep the proportions of their linear advance widths, which */
        /* gives more even spacing; the smoothing makes up for the    */
        /* softer stems.                                              */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex,
                       ( ( fontBuf->FB_flags & FBF_IS_GREY ) && !trueTypeGreyHinting ) ?
                                TTLOAD_SCALE_GLYPH : TTLOAD_DEFAULT );
        TT_Get_Glyph_Outline( GLYPH, &outline );

        TT_Transform_Outline( &outline, &transformMatrix->TM_matrix );

        /* get glyphs boundig box */
        TT_Get_Outline_BBox( &outline, &glyphBBox );

        /* Grid-fit it */
        glyphBBox.xMin &= -64;
        glyphBBox.xMax  = ( glyphBBox.xMax + 63 ) & -64;
        glyphBBox.yMin &= -64;
        glyphBBox.yMax  = ( glyphBBox.yMax + 63 ) & -64;

        /* compute pixel dimensions */
        width  = (glyphBBox.xMax - glyphBBox.xMin) >> 6;
        height = (glyphBBox.yMax - glyphBBox.yMin) >> 6;

        if( fontBuf->FB_flags & FBF_IS_REGION )
        {
                TT_Matrix         flipmatrix = HORIZONTAL_FLIP_MATRIX;


                /* We calculate with an average of 6 on/off points, line number and line end code. */
                size = height * 8 * sizeof( word ) + REGION_SAFETY + SIZE_REGION_HEADER; 

                /* get pointer to bitmapBlock */
                charData = EnsureBitmapBlock( bitmapHandle, size );
EC(             ECCheckBounds( (void*)charData ) );

                /* init rasterMap */
                rasterMap.rows   = height;
                rasterMap.width  = width;
                rasterMap.cols   = width;
                rasterMap.bitmap = ((byte*)charData) + SIZE_REGION_HEADER;

                /* translate outline and render it */
                TT_Transform_Outline( &outline, &flipmatrix );
                TT_Translate_Outline( &outline, -glyphBBox.xMin, glyphBBox.yMax );
                TT_Get_Outline_Region( &outline, &rasterMap );

EC_ERROR_IF(    size < rasterMap.size, ERROR_BITMAP_BUFFER_OVERFLOW );

                /* fill header of charData */
                ((RegionCharData*)charData)->RCD_xoff = transformMatrix->TM_scriptX + 
                                                        transformMatrix->TM_heightX + ( glyphBBox.xMin >> 6 );
                ((RegionCharData*)charData)->RCD_yoff = transformMatrix->TM_scriptY + 
                                                        transformMatrix->TM_heightY - ( glyphBBox.yMax >> 6 ); 
                /* RCD_size is the size of the character including its */
                /* header, as for all font drivers (see fontDr.def).    */
                ((RegionCharData*)charData)->RCD_size = rasterMap.size + SIZE_REGION_HEADER;
                ((RegionCharData*)charData)->RCD_bounds.R_left   = 0;
                ((RegionCharData*)charData)->RCD_bounds.R_right  = width;
                ((RegionCharData*)charData)->RCD_bounds.R_top    = 0;
                ((RegionCharData*)charData)->RCD_bounds.R_bottom = height;

                size = rasterMap.size + SIZE_REGION_HEADER;
        }
        else if( fontBuf->FB_flags & FBF_IS_GREY )
        {
                size = RenderGreyChar( &outline, &rasterMap, &glyphBBox, transformMatrix, width, height,
                                       ( fontBuf->FB_flags & FBF_GREY_PHASES ) ? GREY_PHASES : 1,
                                       bitmapHandle, &charData );
        }
        else
        {      
                /* Avoid heights of 0 pixels */
                if( height == 0 && width > 0 )
                        height = 1;

                size = height * ( ( width + 7 ) >> 3 ) + SIZE_CHAR_HEADER;

                /* get pointer to bitmapBlock */
                charData = EnsureBitmapBlock( bitmapHandle, size );
EC(             ECCheckBounds( (void*)charData ) );

                /* init rasterMap */
                rasterMap.rows   = height;
                rasterMap.width  = width;
                rasterMap.cols   = (width + 7) >> 3;
                rasterMap.size   = rasterMap.rows * rasterMap.cols;
                rasterMap.bitmap = ((byte*)charData) + SIZE_CHAR_HEADER;

                /* translate outline and render it */
                TT_Translate_Outline( &outline, -glyphBBox.xMin, -glyphBBox.yMin );
                TT_Get_Outline_Bitmap( &outline, &rasterMap );

EC_ERROR_IF(    size < rasterMap.size, ERROR_BITMAP_BUFFER_OVERFLOW );

                /* fill header of charData */
                ((CharData*)charData)->CD_pictureWidth = width;
                ((CharData*)charData)->CD_numRows      = height;
                ((CharData*)charData)->CD_xoff         = transformMatrix->TM_scriptX + 
                                                         transformMatrix->TM_heightX + ( glyphBBox.xMin >> 6 );
                ((CharData*)charData)->CD_yoff         = transformMatrix->TM_scriptY + 
                                                         transformMatrix->TM_heightY - ( glyphBBox.yMax >> 6 );
        }

        /* make room for the new char, within the limit for this fontbuf */
        ShrinkFontBuf( fontBuf, size );

        /* realloc FontBuf if necessary */
        fontBufHandle = MemPtrToHandle( fontBuf );
EC(     ECCheckMemHandle( fontBufHandle ) );
        if( MemGetInfo( fontBufHandle, MGIT_SIZE ) < fontBuf->FB_dataSize + size )
        {
                MemReAlloc( fontBufHandle, fontBuf->FB_dataSize + size, HAF_STANDARD_NO_ERR );
EC(             ECCheckMemHandle( fontBufHandle) );
                fontBuf = MemDeref( fontBufHandle );
EC(             ECCheckBounds( (void*)fontBuf ) );
        }

        /* add rendered glyph to fontbuf */
        CopyChar( fontBuf, character, charData, size );

        /* cleanup */
        MemUnlock( bitmapHandle );

        /* Only cache glyphs up to MAX_CACHED_POINTSIZE (currently 180pt).     */
        /* Larger point sizes generate large glyph data while typically having */
        /* a very low cache hit rate, making persistent caching inefficient.   */
        if( pointSize <= MAX_CACHED_POINTSIZE )
        {
            TrueTypeCacheBufSpec   bufSpec;

            bufSpec.TTCBS_pointSize = pointSize;
            bufSpec.TTCBS_width = widthIn;
            bufSpec.TTCBS_weight = weight;
            bufSpec.TTCBS_stylesToImplement = stylesToImplement;
            bufSpec.TTCBS_flags = transformMatrix->TM_greyRequest;

            if( !( fontBuf->FB_flags & FBF_IS_COMPLEX ) ) {
                TrueType_Cache_UpdateFontBlock(
                    trueTypeVars->cacheFile,
                    trueTypeVars->entry.TTOE_fontFileName, 
                    trueTypeVars->entry.TTOE_fontFileSize,
                    trueTypeVars->entry.TTOE_magicWord,
                    &bufSpec, fontBufHandle		
                );
            }
        }
Fail:        
        TrueType_Unlock_Face( trueTypeVars );
Fin:
        MemUnlock( varBlock );
}


/********************************************************************
 *                      CopyChar
 ********************************************************************
 *
 * SYNOPSIS:	  Copies a rendered glyph from the BitmapBlock to the 
 *                fontbuf and updates the CharTableEntry.
 * 
 * PARAMETERS:    *fontBuf              Ptr to font data structure.
 *                geosChar              Code of character to copy.
 *                *charData             Ptr to bitmap block.
 *                charDataSize          Number of bytes to copy.
 *                
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/23/22  JK        Initial Revision
 *******************************************************************/

static void CopyChar( FontBuf* fontBuf, word geosChar, void* charData, word charDataSize ) 
{
        const word       indexGeosChar    = geosChar - fontBuf->FB_firstChar;
        CharTableEntry*  charTableEntries = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));

 
EC(     ECCheckBounds( (void*)charData ) );
EC(     ECCheckBounds( (void*)(((byte*)fontBuf) + fontBuf->FB_dataSize ) ) );
EC(     ECCheckBounds( (void*)(((byte*)fontBuf) + fontBuf->FB_dataSize  + charDataSize - 1) ) );

        /* copy rendered Glyph to fontBuf */
        memcpy( ((byte*)fontBuf) + fontBuf->FB_dataSize, charData, charDataSize );

        /* update CharTableEntry and FontBuf */
        charTableEntries[indexGeosChar].CTE_dataOffset = fontBuf->FB_dataSize;       
        fontBuf->FB_dataSize += charDataSize;
}


/********************************************************************
 *                      ShrinkFontBuf
 ********************************************************************
 * SYNOPSIS:	  Shrint FontBuf if it is to large.
 * 
 * PARAMETERS:    *fontBuf              Ptr to font data structure.            
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/23/22  JK        Initial Revision
 *******************************************************************/

static void ShrinkFontBuf( FontBuf* fontBuf, word sizeNewChar ) 
{
        const word       numOfChars       = fontBuf->FB_lastChar - fontBuf->FB_firstChar + 1;
        CharTableEntry*  charTableEntries = (CharTableEntry*) ( ( (byte*)fontBuf ) + sizeof( FontBuf ) );
        const word       maxSize          = FontDrGetMaxBufSize( fontBuf );
        word             sizeCharData;


EC(     ECCheckBounds( (void*)charTableEntries ) );

        /* shrink fontBuf until the new char fits within the limit */
        while( (dword)fontBuf->FB_dataSize + sizeNewChar > maxSize )
        {
                int   indexLRUChar = FindLRUChar( fontBuf, numOfChars );


                /* ensure that we have a char to remove */
                if( indexLRUChar == -1 )
                        return;

                /* remove data of lru char */
                sizeCharData = RemoveCharData( fontBuf, charTableEntries[indexLRUChar].CTE_dataOffset );

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
 * SYNOPSIS:	  Find least recently used char in FontBuf.
 * 
 * PARAMETERS:    *fontBuf              Ptr to font data structure.  
 *                numOfChars            Number of chars in FontBuf.          
 * 
 * RETURNS:       int                   Index of lru char.
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/23/22  JK        Initial Revision
 *******************************************************************/

static int FindLRUChar( FontBuf* fontBuf, int numOfChars )
{
        word             lru = 0xffff;
        int              indexLRUChar = -1;
        int              i;
        CharTableEntry*  charTableEntry = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));


        for( i = 0; i < numOfChars; ++i, ++charTableEntry )
        {

EC(             ECCheckBounds( (void*)charTableEntry ) );

                /* if no data, go to next char */
                if( charTableEntry->CTE_dataOffset <= CHAR_MISSING )
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
 * SYNOPSIS:	  Adjust pointers after removing a rendered glyph 
 *                from FontBuf.
 * 
 * PARAMETERS:    *charTableEntries     Ptr to first CharTableEntry.  
 *                *lruEntry             Ptr to CharTableEntry of 
 *                                      removed rendered glyph.    
 *                sizeLRUEntry          Size of removed rendered glyph.
 *                numOfChars            Number of chars in FontBuf.  
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/23/22  JK        Initial Revision
 *******************************************************************/
static void AdjustPointers( CharTableEntry* charTableEntries, 
                            CharTableEntry* lruEntry, 
                            word sizeLRUEntry,
                            word numOfChars )
{
        word  i;

        for( i = 0; i < numOfChars; ++i )
                if( charTableEntries[i].CTE_dataOffset > lruEntry->CTE_dataOffset )
                        charTableEntries[i].CTE_dataOffset -= sizeLRUEntry;
}


/********************************************************************
 *                      RemoveCharData
 ********************************************************************
 * SYNOPSIS:       Remove the data of a char from the fontbuf by
 *                 shifting the following data down.
 *
 * PARAMETERS:     *fontBuf             Ptr to font data structure.
 *                 offsetCharData       Offset of the char's data.
 *
 * RETURNS:        word                 Size of the removed data.
 *
 * STRATEGY:       The size comes from the kernel (FontDrCharDataSize),
 *                 which knows every char data format.
 *******************************************************************/
static word RemoveCharData( FontBuf* fontBuf, word offsetCharData )
{
        const word    dataSize    = FontDrCharDataSize( fontBuf, offsetCharData );
        const word    bytesToMove = fontBuf->FB_dataSize - offsetCharData - dataSize;
        byte*         charData    = ((byte*)fontBuf) + offsetCharData;


        if( bytesToMove == 0 )
                return dataSize;

EC(     ECCheckBounds( (void*)charData ) );
EC(     ECCheckBounds( (void*)(charData + dataSize ) ) );
EC(     ECCheckBounds( (void*)(charData + dataSize + bytesToMove - 1) ) );

        memmove( charData, charData + dataSize, bytesToMove );

        return dataSize;
}


/********************************************************************
 *                      EnsureBitmapBlock
 ********************************************************************
 * SYNOPSIS:	  Ensures that the required space is available in the 
 *                bitmap block.
 * 
 * PARAMETERS:    bitmapHandle          Memory handle to bitmap block.
 *                size                  Required size of bitmap block.
 *                

 * RETURNS:       void*                 Pointer to locked bitmap block.
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/23/22  JK        Initial Revision
 *******************************************************************/

/********************************************************************
 *                      RenderGreyFallback
 ********************************************************************
 * SYNOPSIS:       If the oversampled outline can't be rendered, render
 *                 it at the real size, 1 bit, and use full coverage
 *                 for its pixels (better than an empty glyph), in all
 *                 subpixel phases.
 *
 * PARAMETERS:     trueTypeVars         Driver variables (OUTLINE scaled
 *                                      by GREY_OVERSAMPLING, shifted by
 *                                      one pixel).
 *                 width, height        Size of the glyph in pixels.
 *                 *out                 Greyscale data (all phases).
 *                 greyCols, phaseSize  Bytes per row, per phase.
 *                 *work, workSize      Scratch space.
 *******************************************************************/
static void RenderGreyFallback( TT_Outline* outline, TT_Raster_Map* rasterMap, sword width, sword height,
                                word pad, word phases,
                                byte* out, word greyCols, word phaseSize,
                                byte* work, word workSize )
{
        TT_Matrix  unscale  = { 0x10000L / GREY_OVERSAMPLING, 0,
                                0, 0x10000L / GREY_OVERSAMPLING };
        word       monoCols = ( width + pad + 7 ) >> 3;
        word       x, y, k;


        memset( work, 0, workSize );
        TT_Transform_Outline( outline, &unscale );
        rasterMap->rows   = height;
        rasterMap->width  = width + pad;
        rasterMap->cols   = monoCols;
        rasterMap->size   = monoCols * height;
        rasterMap->bitmap = work;
        TT_Get_Outline_Bitmap( outline, rasterMap );

        for( k = 0; k < phases; k++ )
                for( y = 0; y < height; y++ )
                        for( x = 0; x < width + pad; x++ )
                                if( work[y * monoCols + ( x >> 3 )] & ( 0x80 >> ( x & 7 ) ) )
                                        out[k * phaseSize + y * greyCols + ( x >> 1 )] |=
                                                ( x & 1 ) ? ( GREY_LEVELS - 1 ) : ( ( GREY_LEVELS - 1 ) << 4 );
}

/********************************************************************
 *                      GreyCoverage
 ********************************************************************
 * SYNOPSIS:       Count the set subpixels of one oversampled column
 *                 (GREY_OVERSAMPLING rows).
 *
 * PARAMETERS:     *row                 First of the oversampled rows.
 *                 hiCols, hiWidth      Bytes per row, width in bits.
 *                 col                  Column (may be outside: 0).
 *******************************************************************/
static byte GreyCoverage( const byte* row, word hiCols, word hiWidth, sword col )
{
        byte   count = 0;
        byte   mask;
        word   i;


        if( col < 0 || col >= hiWidth )
                return 0;
        mask = 0x80 >> ( col & 7 );
        row += col >> 3;
        for( i = 0; i < GREY_OVERSAMPLING; i++, row += hiCols )
                if( *row & mask )
                        count++;
        return count;
}

/********************************************************************
 *                      RenderGreyChar
 ********************************************************************
 * SYNOPSIS:       Render the glyph outline as greyscale character data
 *                 (GreyCharData, 4 bits per pixel, GREY_PHASES subpixel
 *                 phases, see fontDr.def).
 *
 * PARAMETERS:     trueTypeVars         Driver variables (OUTLINE,
 *                                      GLYPH_BBOX, RASTER_MAP).
 *                 *transformMatrix     For the char's offsets.
 *                 width, height        Size of the glyph in pixels.
 *                 bitmapHandle         Block for rendering.
 *                 **charDataPtr        Returns ptr to the char data.
 *
 * RETURNS:        sword                Size of the char data incl.
 *                                      header.
 *
 * STRATEGY:       Scale the outline by GREY_OVERSAMPLING (4) and render
 *                 it once with the 1 bit rasterizer into a 4x4 times
 *                 larger bitmap behind the char data, one pixel from
 *                 the left edge. The character is 2 pixels wider than
 *                 the glyph (an empty column on each side), so that it
 *                 can be shifted by a fraction of a pixel either way:
 *                 with 4x oversampling a quarter pixel is exactly one
 *                 oversampled column. Phase k counts, for output pixel
 *                 x, the 4x4 subpixels starting at column
 *                 4x - (k - GREY_PHASE_ZERO); 0..16 set subpixels map to
 *                 coverage 0..GREY_LEVELS-1. The video driver picks the
 *                 phase from the fractional pen position.
 *******************************************************************/
static sword RenderGreyChar( TT_Outline* outline, TT_Raster_Map* rasterMap, TT_BBox* glyphBBox,
                             TransformMatrix* transformMatrix,
                             sword width, sword height, word phases,
                             MemHandle bitmapHandle, void** charDataPtr )
{
        TT_Matrix          scale = { (TT_Fixed)GREY_OVERSAMPLING << 16, 0,
                                     0, (TT_Fixed)GREY_OVERSAMPLING << 16 };
        word               outWidth, greyCols, phaseSize, hiCols, hiWidth, hiSize;
        word               pad = ( phases > 1 ) ? 1 : 0;   /* empty column each side */
        word               x, y, k;
        sword              size;
        byte*              charData;
        byte*              hiBitmap;
        byte*              out;


        /* Avoid heights of 0 pixels */
        if( height == 0 && width > 0 )
                height = 1;
        /* room for the empty column on each side */
        if( width > 255 - 2 * pad )
                width = 255 - 2 * pad;

        outWidth  = width + 2 * pad;
        greyCols  = ( outWidth + 1 ) >> 1;             /* 2 pixels per byte  */
        phaseSize = greyCols * height;
        size      = phases * phaseSize + SIZE_GREY_CHAR_HEADER;
        hiWidth   = outWidth * GREY_OVERSAMPLING;      /* oversampled bits   */
        hiCols    = ( hiWidth + 7 ) >> 3;
        hiSize    = hiCols * height * GREY_OVERSAMPLING;

        /* char data, followed by the oversampled bitmap (zeroed) */
        charData = EnsureBitmapBlock( bitmapHandle, size + hiSize );
EC(     ECCheckBounds( (void*)charData ) );
        hiBitmap = charData + size;

        rasterMap->rows   = height * GREY_OVERSAMPLING;
        rasterMap->width  = hiWidth;
        rasterMap->cols   = hiCols;
        rasterMap->size   = hiSize;
        rasterMap->bitmap = hiBitmap;

        /* translate outline one pixel from the origin, scale it, render it */
        TT_Translate_Outline( outline, -glyphBBox->xMin + pad * 64, -glyphBBox->yMin );
        TT_Transform_Outline( outline, &scale );
        outline->dropout_mode = 2;
        {
                /* The rasterizer sizes its render pool (and precision) */
                /* by y_ppem: tell it about the oversampled size, or    */
                /* glyphs with many edges (like 'w') overflow the pool  */
                /* and come out empty.                                  */
                TT_UShort  ppem = outline->y_ppem;
                TT_Error   error;

                outline->y_ppem = ppem * GREY_OVERSAMPLING;
                error = TT_Get_Outline_Bitmap( outline, rasterMap );
                outline->y_ppem = ppem;

                if( error )
                {
                        /* fall back to the 1 bit glyph: full coverage */
                        RenderGreyFallback( outline, rasterMap, width, height, pad, phases,
                                            charData + SIZE_GREY_CHAR_HEADER,
                                            greyCols, phaseSize, hiBitmap, hiSize );
                        goto fillHeader;
                }
        }

EC_ERROR_IF(    hiSize < rasterMap->size, ERROR_BITMAP_BUFFER_OVERFLOW );

        /* downsample every phase: count the subpixels of each 4x4 block */
        out = charData + SIZE_GREY_CHAR_HEADER;
        for( k = 0; k < phases; k++ )
        {
                sword  shift = ( phases > 1 ) ? (sword)k - GREY_PHASE_ZERO : 0;

                for( y = 0; y < height; y++ )
                {
                        const byte*  row = hiBitmap + y * GREY_OVERSAMPLING * hiCols;

                        for( x = 0; x < outWidth; x++ )
                        {
                                sword  col   = (sword)( x * GREY_OVERSAMPLING ) - shift;
                                word   count = GreyCoverage( row, hiCols, hiWidth, col ) +
                                               GreyCoverage( row, hiCols, hiWidth, col + 1 ) +
                                               GreyCoverage( row, hiCols, hiWidth, col + 2 ) +
                                               GreyCoverage( row, hiCols, hiWidth, col + 3 );
                                byte   level = (byte)( ( count * ( GREY_LEVELS - 1 ) + 8 ) >> 4 );

                                if( x & 1 )
                                        out[x >> 1] |= level;
                                else
                                        out[x >> 1] = level << 4;
                        }
                        out += greyCols;
                }
        }

fillHeader:
        /* fill header of charData (same layout as CharData) */
        ((GreyCharData*)charData)->GCD_pictureWidth = outWidth;
        ((GreyCharData*)charData)->GCD_numRows      = height;
        ((GreyCharData*)charData)->GCD_xoff         = transformMatrix->TM_scriptX +
                                                      transformMatrix->TM_heightX + ( glyphBBox->xMin >> 6 ) - pad;
        ((GreyCharData*)charData)->GCD_yoff         = transformMatrix->TM_scriptY +
                                                      transformMatrix->TM_heightY - ( glyphBBox->yMax >> 6 );

        *charDataPtr = charData;
        return size;
}

static void* EnsureBitmapBlock( MemHandle bitmapHandle, word size )
{
    void* bitmapData;
    word  currentSize;
    word  allocSize;

    /* round up to 256 bytes */
    if (size < INITIAL_BITMAP_BLOCKSIZE)
        allocSize = INITIAL_BITMAP_BLOCKSIZE;
    else
        allocSize = (size + 255) & 0xFF00;

    bitmapData  = MemLock( bitmapHandle );
    currentSize = (bitmapData == NULL) ? 0 : MemGetInfo( bitmapHandle, MGIT_SIZE );
        
    if ( currentSize != allocSize )
    {
        MemReAlloc( bitmapHandle, allocSize, HAF_NO_ERR | HAF_LOCK );
        bitmapData = MemDeref( bitmapHandle );
    }
        
    return memset( bitmapData, 0, size );
}
