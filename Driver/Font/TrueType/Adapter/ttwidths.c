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
#include "freetype.h"
#include "../FreeType/ftxkern.h"


static TextStyle  findOutlineData( 
                        OutlineDataEntry**  outlineData,
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

static TT_Error ConvertHeader( 
                        TT_Face         face, 
                        WWFixedAsDWord  pointSize, 
                        FontHeader*     fontHeader, 
                        FontBuf*        fontBuf );

static void ConvertWidths( 
                        TT_Face         face, 
                        FontHeader*     fontHeader, 
                        WWFixedAsDWord  scaleFactor, 
                        FontBuf*        fontBuf );
            
static void ConvertKernPairs( TT_Face face, FontBuf* fontBuf );

static void CalcTransform( 
                        TransformMatrix*  transMatrix,
                        FontMatrix*       fontMatrix, 
                        TextStyle         styleToImplement );


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:	  Generate header width infomation about a front 
 *                in a given pointsize, style and weight.
 * 
 * PARAMETERS:    fontHandle            Memory handle to font block.
 *                *fontMatrix           Pointer to tranformation matrix.
 *                *fontInfo             Pointer to font info structure.
 *                pointSize             Desired point size.
 *                textStyle             Desired text style.
 *                fontWidth             Desired font width.
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
        OutlineDataEntry*      outlineData;
        TrueTypeOutlineEntry*  trueTypeOutlineEntry;
        TextStyle              stylesToImplement;
        TT_Face                face;
        TT_Face_Properties     faceProperties;
        TT_Error               error;
        word                   size;
        FontHeader*            fontHeader;
        FontBuf*               fontBuf;
        WWFixedAsDWord         scaleFactor;
        
        
        ECCheckMemHandle( fontHandle );
        ECCheckBounds( fontMatrix );
        ECCheckBounds( (void*)fontInfo );

        /* find outline for textStyle and fontWeight */
        stylesToImplement = findOutlineData( &outlineData, fontInfo, textStyle, fontWeight );

        /* get filename an load ttf file */
        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        /* get pointer to TrueTypeOutline and FontHeader*/
        trueTypeOutlineEntry = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineData->ODE_header.OE_handle );
        fontHeader = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineData->ODE_first.OE_handle );

        /* open ttf file, face, properties and properties */
        truetypeFile = FileOpen( trueTypeOutlineEntry->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );

        ECCheckFileHandle( truetypeFile );

        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fail;

        error = TT_Get_Face_Properties( face, &faceProperties );
        if( error )
                goto Fail;
        
        /* alloc Block for FontBuf, CharTableEntries, KernPairs and kerning values */
        size = AllocFontBlock( sizeof( TransformMatrix ), 
                               fontHeader->FH_numChars, 
                               CountKernPairsWithGeosChars( face ), 
                               &fontHandle );

        /* calculate scale factor and transformation matrix */
        scaleFactor = CalcScaleForWidths( pointSize, 
                                          fontWidth, 
                                          fontWeight, 
                                          stylesToImplement, 
                                          faceProperties.header->Units_Per_EM );

        /* convert FontHeader and fill FontBuf structure */
        fontBuf = (FontBuf*)MemDeref( fontHandle );
        fontBuf->FB_dataSize = size;
        ConvertHeader( face, pointSize, fontHeader, fontBuf );

        /* fill kerning pairs and kerning values */
        ConvertKernPairs( face, fontBuf );

        /* convert widths and fill CharTableEntries */
        ConvertWidths( face, fontHeader, scaleFactor, fontBuf );

        /* calculate the transformation matrix and copy it into the FontBlock */
        CalcTransform( (TransformMatrix*)((byte*)fontBuf) + sizeof( FontBuf ) + fontHeader->FH_numChars * sizeof( CharTableEntry ),
                       fontMatrix, 
                       stylesToImplement );

Fail:
        TT_Close_Face( face );
        FileClose( truetypeFile, FALSE );
        FilePopDir();
	return fontHandle;
}


/********************************************************************
 *                      ConvertWidths
 ********************************************************************
 * SYNOPSIS:	  Converts the information from the FontHeader and 
 *                fills FontBuf with it.
 * 
 * PARAMETERS:    face                  TrueType face of font file.
 *                *fontHeader           Pointer to FontHeader structure.
 *                scaleFactor           Factor by which the chars width
 *                                      must be scaled.
 *                *fontBuf              Pointer to FontBuf structure.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/02/23  JK        Initial Revision
 *******************************************************************/

static void ConvertWidths( TT_Face face, FontHeader* fontHeader, WWFixedAsDWord scaleFactor, FontBuf* fontBuf )
{
        TT_Instance       instance;
        TT_Glyph          glyph;
        TT_CharMap        charMap;
        TT_Glyph_Metrics  metrics;
        char              currentChar;
        CharTableEntry*   charTableEntry = (CharTableEntry*) ((byte*)fontBuf) + sizeof( FontBuf );

        TT_New_Glyph( face, &glyph );
        TT_New_Instance( face, &instance );
        getCharMap( face, &charMap );

        for( currentChar = fontHeader->FH_firstChar; currentChar < fontHeader->FH_lastChar; currentChar++ )
        {
                word charIndex;
                word width;
                WWFixedAsDWord scaledWidth;
                

                //Geos Char to Unicode
                word unicode = GeosCharToUnicode( currentChar );

                //Unicode to TT ID
                charIndex = TT_Char_Index( charMap, unicode );
                if ( charIndex == 0 )
                {
                        charTableEntry->CTE_flags          = CTF_NO_DATA;
                        charTableEntry->CTE_dataOffset     = CHAR_NOT_EXIST;
                        charTableEntry->CTE_width.WBF_int  = 0;
                        charTableEntry->CTE_width.WBF_frac = 0;
                        charTableEntry->CTE_usage          = 0;

                        charTableEntry++;
                        continue;
                }
                        
                //Glyph laden
                TT_Load_Glyph( instance, glyph, charIndex, TTLOAD_DEFAULT );
                TT_Get_Glyph_Metrics( glyph, &metrics );

                //width berechnen
                width = metrics.bbox.xMax - metrics.bbox.xMin;
                scaledWidth = SCALE_WORD( width, scaleFactor );
                charTableEntry->CTE_width.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( scaledWidth );
                charTableEntry->CTE_width.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( scaledWidth );
                charTableEntry->CTE_dataOffset     = CHAR_NOT_BUILT;
                charTableEntry->CTE_flags          = 0;
                charTableEntry->CTE_usage          = 0;
                
                // set flags in CTE_flags if needed
                if( metrics.bbox.xMin < 0 )
                        charTableEntry->CTE_flags |= CTF_NEGATIVE_LSB;

                //below descent
                if( -metrics.bbox.yMin > fontHeader->FH_descent )
                        charTableEntry->CTE_flags |= CTF_BELOW_DESCENT;

                //above ascent
                if( metrics.bbox.yMax > fontHeader->FH_ascent )
                        charTableEntry->CTE_flags |= CTF_ABOVE_ASCENT;


                if( fontBuf->FB_kernCount > 0 )
                {
                        //first kern

                        //second kern
                }

                charTableEntry++;
        } 

        TT_Done_Instance( instance );
        TT_Done_Glyph( glyph );
}


/********************************************************************
 *                      findOutlineData
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12/02/23  JK        Initial Revision
 *******************************************************************/

static TextStyle  findOutlineData( 
                        OutlineDataEntry**  outline,
                        const FontInfo*    fontInfo, 
                        TextStyle          textStyle, 
                        FontWeight         fontWeight )
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
                        *outline = outlineData;
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
        *outline = outlineToUse;
        return styleDiff;
}


/********************************************************************
 *                      CalcScaleForWidths
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
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
 *      12/02/23  JK        Initial Revision
 *******************************************************************/

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
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

static void ConvertKernPairs( TT_Face face, FontBuf* fontBuf )
{
        KernPair*  kernPair;
        WBFixed*   wbFixed;

        //lade TT_Kern Tabelle

        //iteriere über den FreeGEOS Zeichensatz

                //wandle das akt. Zeichen in den TT Index

                //suche den Index in der TT Kern Tabelle

                        // wenn gefunden: ist das zweite Zeichen auch ein GEOS Zeichen?
                        // ja: Kernpair in den FontBuf eintragen
                        //     Kernvalue in den FontBuf eintragen
                        //     KernCounter hochzählen

        fontBuf->FB_kernCount    = 0;
        fontBuf->FB_kernValuePtr = NULL;
        fontBuf->FB_kernPairPtr  = NULL;
}


/********************************************************************
 *                      CalcTransform
 ********************************************************************
 * SYNOPSIS:	  Calculates the transformation matrix for missing
 *                style attributes and weights.
 * 
 * PARAMETERS:    *transMatrix          Pointer to TransformMatrix
 *                                      in font block.
 *                *fontMatrix           Systems transformation matrix.
 *                styleToImplement      Styles that must be added.
 *                      
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

static void CalcTransform( TransformMatrix*  transMatrix, 
                           FontMatrix*       fontMatrix, 
                           TextStyle         stylesToImplement )
{
        TT_Matrix  tempMatrix;

        /* copy fontMatrix into transMatrix */
        tempMatrix.xx = 1L << 16;
        tempMatrix.xy = 0;
        tempMatrix.yx = 0;
        tempMatrix.yy = 1L << 16;

        /* fake bold style       */
        if( stylesToImplement & TS_BOLD )
        {
                tempMatrix.xx = BOLD_FACTOR;
        }

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
        {
                tempMatrix.yx = ITALIC_FACTOR;
        }

        /* fake script style      */
        if( stylesToImplement & TS_SUBSCRIPT || stylesToImplement & TS_SUBSCRIPT )
        {      
                tempMatrix.xx = GrMulWWFixed( tempMatrix.xx, SCRIPT_FACTOR );
                tempMatrix.yy = GrMulWWFixed( tempMatrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                {
                        transMatrix->TM_shiftY = -SCRIPT_SHIFT_FACTOR;
                }
                else
                {
                        transMatrix->TM_shiftY = SCRIPT_SHIFT_FACTOR;
                }
        }

        /* integrate fontMatrix */
        transMatrix->TM_matrix.xx = GrMulWWFixed( tempMatrix.xx, fontMatrix->FM_11 ) +
                                    GrMulWWFixed( tempMatrix.xy, fontMatrix->FM_21 );
        transMatrix->TM_matrix.xy = GrMulWWFixed( tempMatrix.xx, fontMatrix->FM_12 ) +
                                    GrMulWWFixed( tempMatrix.xy, fontMatrix->FM_22 );
        transMatrix->TM_matrix.yx = GrMulWWFixed( tempMatrix.yx, fontMatrix->FM_11 ) +
                                    GrMulWWFixed( tempMatrix.yy, fontMatrix->FM_21 );
        transMatrix->TM_matrix.yy = GrMulWWFixed( tempMatrix.yx, fontMatrix->FM_12 ) +
                                    GrMulWWFixed( tempMatrix.yy, fontMatrix->FM_22 );
}


/********************************************************************
 *                      AllocFontBlock
 ********************************************************************
 * SYNOPSIS:	  Allocate or reallocate memory block for font.
 * 
 * PARAMETERS:    additionalSpace       Additional space in block
 *                                      for driver.
 *                numOfCharacters       Number of GEOS characters in 
 *                                      font.
 *                numOfKernPairs        Number of kerning pairs of 
 *                                      GEOS characters in font.
 *                *fontHandle           Pointer to MemHandle of font 
 *                                      block. If NullHandle alloc new 
 *                                      block. If not, realloc existing 
 *                                      one.
 * 
 * RETURNS:       word                  Size of allocated block.
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
        word size = sizeof( FontBuf ) + numOfCharacters * sizeof( CharTableEntry ) +
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
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  Converts FontInfo and fill FontBuf structure.
 * 
 * PARAMETERS:    face                  TrueType face of font file.
 *                pointSize             Current pointsize.
 *                *fontHeader           Pointer to FontHeader structure
 *                                      to fill fontBuf.
 *                *fontBuf              Pointer to FontBuf structure 
 *                                      to fill.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

TT_Error ConvertHeader( TT_Face face, WWFixedAsDWord pointSize, FontHeader* fontHeader, FontBuf* fontBuf ) 
{
        TT_Error            error;
        TT_Instance         instance;
        TT_Instance_Metrics instanceMetrics;
        WWFixedAsDWord      scaleFactor;
        WWFixedAsDWord      ttfElement;
        

        ECCheckBounds( (void*)fontBuf );
        ECCheckBounds( (void*)fontHeader );


        error = TT_New_Instance( face, &instance );
        if ( error )
                return error;

        error = TT_Set_Instance_CharSize( instance, pointSize >> 10 );
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

        ttfElement = SCALE_WORD( fontHeader->FH_minLSB, scaleFactor );
        fontBuf->FB_minLSB = ROUND_WWFIXEDASDWORD( ttfElement ); 

        ttfElement = SCALE_WORD( fontHeader->FH_avgwidth, scaleFactor );
        fontBuf->FB_avgwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_avgwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxwidth, scaleFactor );
        fontBuf->FB_maxwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_maxwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

#ifndef DBCS_PCGEOS
        ttfElement = SCALE_WORD( fontHeader->FH_maxRSB, scaleFactor );
        fontBuf->FB_maxRSB  = ROUND_WWFIXEDASDWORD( ttfElement );
#endif  /* DBCS_PCGEOS */

        scaleFactor = instanceMetrics.y_scale;

        ttfElement = SCALE_WORD( fontHeader->FH_height, scaleFactor );
        fontBuf->FB_height.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_height.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        /* FB_heightAdjust = pointSize - FH_height                           */
        ttfElement = pointSize - WORD_TO_WWFIXEDASDWORD( fontHeader->FH_height );
        fontBuf->FB_heightAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_heightAdjust.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_pixHeight = ROUND_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_baseAdjust, scaleFactor );
        fontBuf->FB_baseAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ROUND_WWFIXEDASDWORD( ttfElement ) );
        fontBuf->FB_baseAdjust.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_minTSB, scaleFactor );
        fontBuf->FB_aboveBox.WBF_int  = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_aboveBox.WBF_frac = 0;
        fontBuf->FB_minTSB = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_pixHeight += CEIL_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxBSB, scaleFactor );
        fontBuf->FB_belowBox.WBF_int  = CEIL_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_belowBox.WBF_frac = 0;
#ifdef SBCS_PCGEOS
        fontBuf->FB_maxBSB = CEIL_WWFIXEDASDWORD( ttfElement );
#endif  /* SBCS_PCGEOS */

        ttfElement = SCALE_WORD( fontHeader->FH_underPos, scaleFactor );
        fontBuf->FB_underPos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underPos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_underThick, scaleFactor );
        fontBuf->FB_underThickness.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underThickness.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_strikePos, scaleFactor );
        fontBuf->FB_strikePos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_strikePos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_x_height, scaleFactor );
        fontBuf->FB_mean.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_mean.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_descent, scaleFactor );
        fontBuf->FB_descent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_descent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_accent, scaleFactor );
        fontBuf->FB_accent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_accent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        /* baslinepos = accent + ascent                                      */
        ttfElement = SCALE_WORD( fontHeader->FH_ascent + fontHeader->FH_accent, scaleFactor );
        fontBuf->FB_baselinePos.WBF_int  = ROUND_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_baselinePos.WBF_frac = 0;

        /* Nimbus fonts and TrueType fonts has no external leading           */
        fontBuf->FB_extLeading.WBF_int  = 0;
        fontBuf->FB_extLeading.WBF_frac = 0;

        fontBuf->FB_firstChar   = fontHeader->FH_firstChar;
        fontBuf->FB_lastChar    = fontHeader->FH_lastChar;
        fontBuf->FB_defaultChar = fontHeader->FH_defaultChar;

        TT_Done_Instance( instance );

        return TT_Err_Ok;
}
