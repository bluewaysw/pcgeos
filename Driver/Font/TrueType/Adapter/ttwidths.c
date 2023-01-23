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
 *	Definition of driver function DR_FONT_GEN_WIDTHS.
 ***********************************************************************/

#include <geos.h>
#include <ec.h>
#include <unicode.h>
#include <graphics.h>
#include <heap.h>
#include "ttwidths.h"
#include "ttcharmapper.h"
#include "ttinit.h"
#include "../FreeType/ftxkern.h"


static TextStyle  findOutlineData( 
                        ChunkHandle*     truetypeOutlineEntryChunk,
                        ChunkHandle*     fontHeaderChunk,
                        const FontInfo*  fontInfo, 
                        TextStyle        textStyle, 
                        FontWeight       fontWeight );

static word  AllocFontBlock( 
                        word        additionalSpace,
                        word        numOfCharacters,
                        word        numOfKernPairs,
                        MemHandle*  fontHandle );

static WWFixedAsDWord CalcScaleForWidths( 
                        WWFixedAsDWord  pointSize,
                        FontWidth       fontWidth,
                        FontWeight      fontWeight,
                        TextStyle       stylesToImplement,
                        word            unitsPerEM );

TT_Error Fill_CharTableEntry( 
                        const FontInfo*  fontInfo, 
                        word             character,
                        CharTableEntry*  charTableEntry );

TT_Error Fill_FontBuf( TT_Face face, WBFixed pointSize, FontBuf* fontBuf );

void ConvertHeader();

void ConvertKernPairs();

void CalcTransform(     TT_Matrix*   resultMatrix, 
                        FontMatrix*  transformMatrix, 
                        TextStyle    styleToImplement );


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:	  Generate header width infomation about a front 
 *                in a given pointsize, style and weight.
 * 
 * PARAMETERS:    fontHandle            Memory handle to font block.
 *                tMatrix               Pointer to tranformation matrix.
 *                fontInfo              Pointer to font info block.
 *                pointSize             Desired point size.
 *                textStyle             Desired text style.
 *                fontWeight            Desired font weight.
 * 
 * RETURNS:       MemHandle             Memory handle to font block.
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

MemHandle _pascal TrueType_Gen_Widths(
                            MemHandle        fontHandle,
                            FontMatrix*      fontMatrix,
                            const FontInfo*  fontInfo,
                            WWFixedAsDWord   pointSize,
                            TextStyle        textStyle,
                            FontWidth        fontWidth,
                            FontWeight       fontWeight )
{
        FileHandle             truetypeFile;
        ChunkHandle            truetypeChunkHandle;
        ChunkHandle            fontHeaderChunkHandle;
        TrueTypeOutlineEntry*  trueTypeOutlineEntry;
        TextStyle              stylesToImplement;
        TT_Face                face;
        TT_Face_Properties     faceProperties;
        TT_CharMap             charMap;
        TT_Error               error;
        word                   numChars;
        word                   numKernPairs;
        char                   firstChar;
        char                   lastChar;
        word                   size;
        FontHeader*            fontHeader;
        FontBuf*               fontBuf;
        CharTableEntry*        charTableEntry;
        KernPair*              kernPair;
        WBFixed*               kernValue;
        WWFixedAsDWord         scaleFactor;
        

        ECCheckMemHandle( fontHandle );
        ECCheckBounds( fontMatrix );
        ECCheckBounds( (void*)fontInfo );

        /* find outline for textStyle and fontWeight */
        stylesToImplement = findOutlineData( &truetypeChunkHandle, &fontHeaderChunkHandle, fontInfo, textStyle, fontWeight );

        /* get filename an load ttf file */
        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        trueTypeOutlineEntry = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), truetypeChunkHandle );
        truetypeFile = FileOpen( trueTypeOutlineEntry->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );

        ECCheckFileHandle( truetypeFile );

        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fail_Face;

        error = TT_Get_Face_Properties( face, &faceProperties );
        if( error )
                goto Fail_Map;

        error = getCharMap( face, &charMap );
        if( error )
                goto Fail_Map;

        numChars = InitGeosCharsInCharMap( charMap, &firstChar, &lastChar );
        numKernPairs = CountKernPairsWithGeosChars( face );
        
        /* alloc Block for FontBuf, CharTableEntries, KernPairs and kerning values */
        AllocFontBlock( 0, numChars, numKernPairs, &fontHandle );
        ECCheckMemHandle( fontHandle );

        /* calculate scale factor and transformation matrix */
        scaleFactor = CalcScaleForWidths( pointSize, 
                                          fontWidth, 
                                          fontWeight, 
                                          stylesToImplement, 
                                          faceProperties.header->Units_Per_EM );

        //Widths berechen und einfügen (CharTableEntries)


        //Header konvertieren


        //Kernpairs konvertieren und einfügen


Fail_Map:
        TT_Close_Face( face );
Fail_Face:
        FileClose( truetypeFile, FALSE );
        FilePopDir();
	return fontHandle;
}


static TextStyle  findOutlineData( 
                        ChunkHandle*     truetypeOutlineEntryChunk,
                        ChunkHandle*     fontHeaderChunk,
                        const FontInfo*  fontInfo, 
                        TextStyle        textStyle, 
                        FontWeight       fontWeight )
{
        OutlineDataEntry*  outlineToUse;
        OutlineDataEntry*  outlineData = (OutlineDataEntry*) (((byte*)fontInfo) + fontInfo->FI_outlineTab);
        OutlineDataEntry*  outlineDataEnd = (OutlineDataEntry*) (((byte*)fontInfo) + fontInfo->FI_outlineEnd);
        TextStyle          styleDiff = 127;
        byte               weightDiff = 127;


        /* adjust textWeight for AW_BOLD */
        if( textStyle >= AW_BOLD )
                textStyle = AW_BLACK;

        while( outlineData < outlineDataEnd)
	{
                /* exact match? */
                if( outlineData->ODE_style == textStyle &&
	            outlineData->ODE_weight == fontWeight )
		{
			*truetypeOutlineEntryChunk = outlineData->ODE_header.OE_handle;
                        *fontHeaderChunk = outlineData->ODE_first.OE_handle;
                        return 0;  // no styles to implement
		}

                /* style match? */
                if( outlineData->ODE_style == textStyle )
                {
                        byte currentWeightDiff = ABS( fontWeight - outlineData->ODE_weight );

                        styleDiff = 0;
                        if( weightDiff >= currentWeightDiff )
                        {
                                outlineToUse = outlineData;
                                weightDiff = currentWeightDiff;
                        }

                }

                /* try to find nearest style */
                if( ( ( textStyle & outlineData->ODE_style ) ^ outlineData->ODE_style ) == 0 )
                {
                        byte currentStyleDiff = textStyle ^ outlineData->ODE_style;
                        if( styleDiff >= currentStyleDiff )
                        {
                                outlineToUse = outlineData;
                                styleDiff = currentStyleDiff;
                        }
                }
		outlineData++;
	}

        *truetypeOutlineEntryChunk = outlineToUse->ODE_header.OE_handle;
        *fontHeaderChunk = outlineToUse->ODE_first.OE_handle;
        return styleDiff;
}

static WWFixedAsDWord CalcScaleForWidths( 
                        WWFixedAsDWord  pointSize,
                        FontWidth       fontWidth,
                        FontWeight      fontWeight,
                        TextStyle       stylesToImplement,
                        word            unitsPerEM )
{
        WWFixedAsDWord scaleWidth = GrUDivWWFixed( pointSize, WORD_TO_WWFIXEDASDWORD( unitsPerEM ) );

        /* do bold need to be added? */
        if( stylesToImplement & TS_BOLD )
                scaleWidth = GrMulWWFixed( scaleWidth, WWFIXED_1_POINR_1 );

        /* do subscript or superscript to be added? */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
                scaleWidth = GrMulWWFixed( scaleWidth, WWFIXED_0_POINT_5 );

        /* adjust for fontWidth */
        if( fontWeight != FWI_MEDIUM )
                scaleWidth = GrMulWWFixed( scaleWidth, MakeWWFixed( fontWidth ) );

        /* adjust für fontWeight */
        if( fontWidth != FW_NORMAL )
                scaleWidth = GrMulWWFixed( scaleWidth, MakeWWFixed( fontWeight ) );

        return scaleWidth;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void ConvertHeader()
{

}


/********************************************************************
 *                      ConvertKernPairs
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void ConvertKernPairs()
{

}


/********************************************************************
 *                      CalcTransform
 ********************************************************************
 * SYNOPSIS:	        Calculates the transformation matrix to 
 *                      calculate missing style attributes and weights.
 * 
 * PARAMETERS:          resultMatrix*
 *                      styleToImplement
 *                      
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

static void CalcTransform(      TT_Matrix*   resultMatrix, 
                                FontMatrix*  fontMatrix, 
                                TextStyle    styleToImplement )
{

}


/********************************************************************
 *                      AllocFontBlock
 ********************************************************************
 * SYNOPSIS:	  Allocate or reallocate memory block for font.
 * 
 * PARAMETERS:    additionalSpace       additional space in block
 *                                      for driver
 *                numOfCharacters       number of characters
 *                numOfKernPairs        number of kerning pairs
 *                fontHandle*           pointer to MemHandle of font block
 *                                      if NullHandle alloc new block, if not
 *                                      realloc existing block
 * 
 * RETURNS:       word                  size of allocated block              
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/01/23  JK        Initial Revision
 *******************************************************************/
static word AllocFontBlock( 
                word        additionalSpace,
                word        numOfCharacters,
                word        numOfKernPairs,
                MemHandle*  fontHandle )
{
        word size = sizeof( FontBuf ) +
                numOfCharacters * sizeof( CharTableEntry ) +
                numOfKernPairs * ( sizeof( KernPair ) + sizeof( WBFixed ) ) +
                additionalSpace; 
                     
        /* allocate memory for FontBuf, CharTableEntries, KernPairs and additional space */
        if( fontHandle == NullHandle )
        {
                *fontHandle = MemAllocSetOwner( FONT_MAN_ID, size, 
                        HF_SWAPABLE | HF_SHARABLE | HF_DISCARDABLE,
                        HAF_NO_ERR | HAF_LOCK );
                HandleP( *fontHandle );
        }
        else
        {
                MemReAlloc( *fontHandle, size, HAF_NO_ERR | HAF_LOCK );
        }

        return size;
}

/********************************************************************
 *                      Fill_CharTableEntry
 ********************************************************************
 * SYNOPSIS:	  Fills the FontBuf structure with infomations 
 *                of the passed in FontInfo.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                word                  Character to which the entry 
 *                                      is to be filled.
 *                charTableEntry        Pointer to entry to be filled.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      Pointsize, scale and rotation will read from gstate.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/
TT_Error Fill_CharTableEntry( const FontInfo*  fontInfo, 
                              word             character,
                              CharTableEntry*  charTableEntry )
{
        TT_CharMap          charMap;
        word                geosChar;


        ECCheckBounds( (void*)fontInfo );
        ECCheckBounds( (void*)charTableEntry );

        geosChar = GeosCharToUnicode( character );
        if ( geosChar == 0 )
        {
                charTableEntry->CTE_width.WBF_int  = 0;
                charTableEntry->CTE_width.WBF_frac = 0;
                charTableEntry->CTE_flags          = CTF_NO_DATA;
        }


Fin:
        return TT_Err_Ok;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  Fills the FontBuf structure with informations 
 *                of the passed in ttf file.
 * 
 * PARAMETERS:    fileName              Name of font file.
 *                pointSize             Current Pointsize.
 *                fontBuf               Pointer to FontBuf structure 
 *                                      to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     The current directory must be the ttf font directory.
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error Fill_FontBuf( TT_Face face, WBFixed pointSize, FontBuf* fontBuf ) 
{
        FontHeader          fontHeader;
        TT_Error            error;
        TT_Instance         instance;
        TT_Instance_Metrics instanceMetrics;
        WWFixedAsDWord      scaleFactor;
        WWFixedAsDWord      ttfElement;
        

        ECCheckBounds( (void*)fontBuf );


        error = TT_New_Instance( face, &instance );
        if ( error )
                return error;

        error = TT_Set_Instance_CharSize( instance, WBFIXED_TO_FIXED26DOT6( pointSize ) );
        if ( error )
                return error;

        error = TT_Get_Instance_Metrics( instance, &instanceMetrics );
        if ( error )
                return error;

        scaleFactor = instanceMetrics.x_scale;

        /* Fill elements in FontBuf structure.                               */

        fontBuf->FB_maker        = FM_TRUETYPE;
        fontBuf->FB_kernPairPtr  = 0;
        fontBuf->FB_kernValuePtr = 0;
        fontBuf->FB_kernCount    = 0;
        fontBuf->FB_heapCount    = 0;
	fontBuf->FB_flags        = FBF_IS_OUTLINE;

        ttfElement = SCALE_WORD( fontHeader.FH_minLSB, scaleFactor );
        fontBuf->FB_minLSB = ROUND_WWFIXEDASDWORD( ttfElement ); 

        ttfElement = SCALE_WORD( fontHeader.FH_avgwidth, scaleFactor );
        fontBuf->FB_avgwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_avgwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_maxwidth, scaleFactor );
        fontBuf->FB_maxwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_maxwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

#ifndef DBCS_PCGEOS
        ttfElement = SCALE_WORD( fontHeader.FH_maxRSB, scaleFactor );
        fontBuf->FB_maxRSB  = ROUND_WWFIXEDASDWORD( ttfElement );
#endif  /* DBCS_PCGEOS */

        scaleFactor = instanceMetrics.y_scale;

        ttfElement = SCALE_WORD( fontHeader.FH_height, scaleFactor );
        fontBuf->FB_height.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_height.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        /* FB_heightAdjust = pointSize - FH_height                           */
        ttfElement = WBFIXED_TO_WWFIXEDASDWORD( pointSize ) -
                     WORD_TO_WWFIXEDASDWORD( fontHeader.FH_height );
        fontBuf->FB_heightAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_heightAdjust.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_pixHeight = ROUND_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_baseAdjust, scaleFactor );
        fontBuf->FB_baseAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ROUND_WWFIXEDASDWORD( ttfElement ) );
        fontBuf->FB_baseAdjust.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader.FH_minTSB, scaleFactor );
        fontBuf->FB_aboveBox.WBF_int  = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_aboveBox.WBF_frac = 0;
        fontBuf->FB_minTSB = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_pixHeight += CEIL_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_maxBSB, scaleFactor );
        fontBuf->FB_belowBox.WBF_int  = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_belowBox.WBF_frac = 0;
#ifdef SBCS_PCGEOS
        fontBuf->FB_maxBSB = CEIL_WWFIXEDASDWORD( ttfElement );
#endif  /* SBCS_PCGEOS */

        ttfElement = SCALE_WORD( fontHeader.FH_underPos, scaleFactor );
        fontBuf->FB_underPos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underPos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_underThick, scaleFactor );
        fontBuf->FB_underThickness.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underThickness.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_strikePos, scaleFactor );
        fontBuf->FB_strikePos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_strikePos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_x_height, scaleFactor );
        fontBuf->FB_mean.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_mean.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_descent, scaleFactor );
        fontBuf->FB_descent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_descent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader.FH_accent, scaleFactor );
        fontBuf->FB_accent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_accent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        /* baslinepos = accent + ascent                                      */
        ttfElement = SCALE_WORD( fontHeader.FH_ascent + fontHeader.FH_accent, scaleFactor );
        fontBuf->FB_baselinePos.WBF_int  = ROUND_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_baselinePos.WBF_frac = 0;

        /* Nimbus fonts and TrueType fonts has no external leading           */
        fontBuf->FB_extLeading.WBF_int  = 0;
        fontBuf->FB_extLeading.WBF_frac = 0;

        fontBuf->FB_firstChar   = fontHeader.FH_firstChar;
        fontBuf->FB_lastChar    = fontHeader.FH_lastChar;
        fontBuf->FB_defaultChar = fontHeader.FH_defaultChar;

        TT_Done_Instance( instance );

        return TT_Err_Ok;
}
