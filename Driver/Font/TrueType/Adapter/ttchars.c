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
static void* EnsureBitmapBlock( MemHandle bitmapHandle, word size );


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
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            bitmapHandle,
                        MemHandle            varBlock ) 
{
        MemHandle              fontBufHandle;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_UShort              charIndex;
        TrueTypeVars*          trueTypeVars;
        TransformMatrix*       transformMatrix;
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

        /* open face, create instance and glyph */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fail;

        TT_New_Glyph( FACE, &GLYPH );

         /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        /* set pointsize and get metrics */
        TT_Set_Instance_CharSize( INSTANCE, ( pointSize >> 10 ) );

        /* load glyph and load glyphs outline */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, TTLOAD_DEFAULT );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );

        // TODO: Transformationsmatrix anwenden
        transformMatrix = (TransformMatrix*)(((byte*)fontBuf) + sizeof( FontBuf ) + ( fontBuf->FB_lastChar - fontBuf->FB_firstChar + 1 ) * sizeof( CharTableEntry ));
        TT_Transform_Outline( &OUTLINE, &transformMatrix->TM_matrix );

        /* get glyphs boundig box */
        TT_Get_Outline_BBox( &OUTLINE, &GLYPH_BBOX );

        /* Grid-fit it */
        GLYPH_BBOX.xMin &= -64;
        GLYPH_BBOX.xMax  = ( GLYPH_BBOX.xMax + 63 ) & -64;
        GLYPH_BBOX.yMin &= -64;
        GLYPH_BBOX.yMax  = ( GLYPH_BBOX.yMax + 63 ) & -64;

        /* compute pixel dimensions */
        width  = (GLYPH_BBOX.xMax - GLYPH_BBOX.xMin) >> 6;
        height = (GLYPH_BBOX.yMax - GLYPH_BBOX.yMin) >> 6;

        if( fontBuf->FB_flags & FBF_IS_REGION )
        {
                TT_Matrix         flipmatrix = HORIZONTAL_FLIP_MATRIX; 

                /* We calculate with an average of 4 on/off points, line number and line end code. */
                size = height * 6 * sizeof( word ) + REGION_SAFETY + SIZE_REGION_HEADER; 

                /* get pointer to bitmapBlock */
                charData = EnsureBitmapBlock( bitmapHandle, size );

                /* init RASTER_MAP */
                RASTER_MAP.rows   = height;
                RASTER_MAP.width  = width;
                RASTER_MAP.cols   = width;
                RASTER_MAP.bitmap = ((byte*)charData) + SIZE_REGION_HEADER;

                /* translate outline and render it */
                TT_Transform_Outline( &OUTLINE, &flipmatrix );
                TT_Translate_Outline( &OUTLINE, -GLYPH_BBOX.xMin, GLYPH_BBOX.yMax );
                TT_Get_Outline_Region( &OUTLINE, &RASTER_MAP );

                /* fill header of charData */
                ((RegionCharData*)charData)->RCD_xoff = transformMatrix->TM_scriptX + 
                                                        transformMatrix->TM_heightX + ( GLYPH_BBOX.xMin >> 6 );
                ((RegionCharData*)charData)->RCD_yoff = transformMatrix->TM_scriptY + 
                                                        transformMatrix->TM_heightY - ( GLYPH_BBOX.yMax >> 6 ); 
                ((RegionCharData*)charData)->RCD_size = RASTER_MAP.size;
                ((RegionCharData*)charData)->RCD_bounds.R_left   = 0;
                ((RegionCharData*)charData)->RCD_bounds.R_right  = width;
                ((RegionCharData*)charData)->RCD_bounds.R_top    = 0;
                ((RegionCharData*)charData)->RCD_bounds.R_bottom = height;

                size = RASTER_MAP.size + SIZE_REGION_HEADER;
        }
        else
        {      
                size = height * ( ( width + 7 ) / 8 ) + SIZE_CHAR_HEADER;

                /* get pointer to bitmapBlock */
                charData = EnsureBitmapBlock( bitmapHandle, size );

                /* init rasterMap */
                RASTER_MAP.rows   = height;
                RASTER_MAP.width  = width;
                RASTER_MAP.cols   = (width + 7) / 8;
                RASTER_MAP.size   = RASTER_MAP.rows * RASTER_MAP.cols;
                RASTER_MAP.bitmap = ((byte*)charData) + SIZE_CHAR_HEADER;

                /* translate outline and render it */
                TT_Translate_Outline( &OUTLINE, -GLYPH_BBOX.xMin, -GLYPH_BBOX.yMin );
                TT_Get_Outline_Bitmap( &OUTLINE, &RASTER_MAP );

                /* fill header of charData */
                ((CharData*)charData)->CD_pictureWidth = width;
                ((CharData*)charData)->CD_numRows      = height;
                ((CharData*)charData)->CD_xoff         = transformMatrix->TM_scriptX + 
                                                         transformMatrix->TM_heightX + ( GLYPH_BBOX.xMin >> 6 );
                ((CharData*)charData)->CD_yoff         = transformMatrix->TM_scriptY + 
                                                         transformMatrix->TM_heightY - ( GLYPH_BBOX.yMax >> 6 );
        }

        TT_Done_Glyph( GLYPH );

        if( fontBuf->FB_dataSize > MAX_FONTBUF_SIZE )
                ShrinkFontBuf( fontBuf );

        /* realloc FontBuf if necessary */
        fontBufHandle = MemPtrToHandle( fontBuf );
        if( MemGetInfo( fontBufHandle, MGIT_SIZE ) < fontBuf->FB_dataSize + size )
        {
                MemReAlloc( fontBufHandle, fontBuf->FB_dataSize + size, HAF_STANDARD_NO_ERR );
                fontBuf = MemDeref( fontBufHandle );
        }

        /* add rendered glyph to fontbuf */
        CopyChar( fontBuf, character, charData ,size );

        /* cleanup */
        MemUnlock( bitmapHandle );
        TrueType_Unlock_Face( trueTypeVars );
Fail:
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
        word  indexGeosChar = geosChar - fontBuf->FB_firstChar;
        CharTableEntry*  charTableEntries = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));


        /* copy rendered Glyph to fontBuf */
        memmove( ((byte*)fontBuf) + fontBuf->FB_dataSize, charData, charDataSize );

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

static void ShrinkFontBuf( FontBuf* fontBuf ) 
{
        word  numOfChars = fontBuf->FB_lastChar - fontBuf->FB_firstChar + 1;
        CharTableEntry*  charTableEntries = (CharTableEntry*) ( ( (byte*)fontBuf ) + sizeof( FontBuf ) );
        word  sizeCharData;


        /* shrink fontBuf if necessary */
        while( fontBuf->FB_dataSize > MAX_FONTBUF_SIZE )
        {
                int   indexLRUChar = FindLRUChar( fontBuf, numOfChars );
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


        for( i = 0; i < numOfChars; i++, charTableEntry++ )
        {
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

        for( i = 0; i < numOfChars; i++ )
                if( charTableEntries[i].CTE_dataOffset > lruEntry->CTE_dataOffset )
                        charTableEntries[i].CTE_dataOffset -= sizeLRUEntry;
}


/********************************************************************
 *                      ShiftCharData
 ********************************************************************
 * SYNOPSIS:	  Shift rendered glyphs as bitmap to fill gaps after 
 *                removing a glyph from FontBuf.
 * 
 * PARAMETERS:    *fontBuf              Ptr to font data structure.    
 *                *charData             Ptr to removed rendered glyph 
 *                                      as bitmap. 
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

static word ShiftCharData( FontBuf* fontBuf, CharData* charData )
{
        word  size = charData->CD_pictureWidth * 
                     ( ( charData->CD_numRows + 7 ) / 8 ) + SIZE_CHAR_HEADER;
 
        memmove( charData, 
                ((byte*)charData) + size, 
                (((byte*)fontBuf) + fontBuf->FB_dataSize) - ((byte*)charData) + size );

        return size;
}

/********************************************************************
 *                      ShiftRegionCharData
 ********************************************************************
 *SYNOPSIS:	  Shift rendered glyphs as region to fill gaps after 
 *                removing a glyph from FontBuf.
 * 
 * PARAMETERS:    *fontBuf              Ptr to font data structure.    
 *                *charData             Ptr to removed rendered glyph 
 *                                      as region. 
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
static word ShiftRegionCharData( FontBuf* fontBuf, RegionCharData* charData )
{
        word size = charData->RCD_size + SIZE_REGION_HEADER;


        memmove( charData, 
                ((byte*)charData) + size, 
                (((byte*)fontBuf) + fontBuf->FB_dataSize) - ((byte*)charData) + size );

        return size;
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

static void* EnsureBitmapBlock( MemHandle bitmapHandle, word size )
{
        void* bitmapData = MemLock( bitmapHandle );

        if( bitmapData == NULL )
        {
                MemReAlloc( bitmapHandle, MAX( size, BITMAP_BLOCKSIZE ), HAF_ZERO_INIT | HAF_NO_ERR );
                return MemLock( bitmapHandle );
        } else {
                word  bitmapBlockSize = MemGetInfo( bitmapHandle, MGIT_SIZE );

                if( bitmapBlockSize < size )
                {
                        MemReAlloc( bitmapHandle, size, HAF_ZERO_INIT | HAF_NO_ERR );
                        return MemLock( bitmapHandle );
                }
                
                if( size < BITMAP_BLOCKSIZE )
                {
                        MemReAlloc( bitmapHandle, BITMAP_BLOCKSIZE, HAF_ZERO_INIT | HAF_NO_ERR );
                        return MemLock( bitmapHandle );
                }
        }

        return bitmapData;
}
