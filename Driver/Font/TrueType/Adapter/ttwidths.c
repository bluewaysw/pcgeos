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
#include "ftxkern.h"
#include "../FreeType/ftxkern.h"


static word  AllocFontBlock( word               additionalSpace,
                        word                    numOfCharacters,
                        word                    numOfKernPairs,
                        MemHandle*              fontHandle );

static void ConvertHeader( TRUETYPE_VARS,
                        FontHeader*             fontHeader, 
                        FontBuf*                fontBuf );

static void ConvertWidths( TRUETYPE_VARS, 
                        FontHeader*             fontHeader, 
                        FontBuf*                fontBuf );
            
static void ConvertKernPairs( TRUETYPE_VARS, FontBuf* fontBuf );

static void CalcScaleForWidths( TRUETYPE_VARS,
                        WWFixedAsDWord          pointSize,
                        TextStyle               styleToImplement );

static void CalcTransform( 
                        TransformMatrix*        transMatrix,
                        FontMatrix*             fontMatrix, 
                        WWFixedAsDWord          pointSize,
                        TextStyle               stylesToImplement );

static void AdjustFontBuf( TransformMatrix*     transMatrix, 
                        FontMatrix*             fontMatrix, 
                        TextStyle               stylesToImplement, 
                        FontBuf*                fontBuf );

static Boolean IsRegionNeeded( TransformMatrix* transMatrix, 
                        FontMatrix* fontMatrix, FontBuf* fontBuf );


#define ROUND_WWFIXED( value )    ( value & 0xffff ? ( value >> 16 ) + 1 : value >> 16 )

#define ROUND_WBFIXED( value )    ( value.WBF_frac ? ( value.WBF_int + 1 ) : value.WBF_int )

#define OFFSET_KERN_PAIRS         ( sizeof(FontBuf) +                                   \
                                    fontHeader->FH_numChars * sizeof( CharTableEntry) + \
                                    sizeof( TransformMatrix ) )

#define OFFSET_KERN_VALUES        ( sizeof(FontBuf) +                                   \
                                    fontHeader->FH_numChars * sizeof( CharTableEntry) + \
                                    sizeof( TransformMatrix ) +                         \
                                    fontHeader->FH_kernCount * sizeof( KernPair ) )

#define BASELINE_CORRECTION       1


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:	  Generate header width infomation about a front 
 *                in a given pointsize and style.
 * 
 * PARAMETERS:    fontHandle            Memory handle to font block.
 *                *fontMatrix           Ptr. to tranformation matrix.
 *                pointSize             Desired point size.
 *                *fontInfo             Ptr. to font info structure.
 *                *headerEntry          Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                *firstEntry           Ptr. to outline entry containing 
 *                                      FontHeader.
 *                stylesToImplement     Desired text style.
 *                varBlock              Memory handle to var block.
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
                        MemHandle            fontHandle,
                        FontMatrix*          fontMatrix,
                        WWFixedAsDWord       pointSize,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  headerEntry,
                        const OutlineEntry*  firstEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            varBlock ) 
{
        TrueTypeOutlineEntry*  trueTypeOutline;
        TrueTypeVars*          trueTypeVars;
        FontHeader*            fontHeader;
        FontBuf*               fontBuf;
        word                   size;
        TransformMatrix*       transMatrix;


EC(     ECCheckMemHandle( fontHandle ) );
EC(     ECCheckBounds( (void*)fontMatrix ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)headerEntry ) );
EC(     ECCheckBounds( (void*)firstEntry ) );
EC(     ECCheckStack() );


        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        // get filename an load ttf file 
        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), headerEntry->OE_handle );
EC(     ECCheckBounds( (void*)trueTypeOutline ) );

        // get pointer to FontHeader
        fontHeader = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), firstEntry->OE_handle );
EC(     ECCheckBounds( (void*)fontHeader ) );

        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fail;

        /* alloc Block for FontBuf, CharTableEntries, KernPairs and kerning values */
        size = AllocFontBlock( sizeof( TransformMatrix ), 
                               fontHeader->FH_numChars, 
                               fontHeader->FH_kernCount, 
                               &fontHandle );
        fontBuf = (FontBuf*)MemDeref( fontHandle );
EC(     ECCheckBounds( (void*) fontBuf ) );

        /* initialize fields in FontBuf that do not have to be scaled */
        fontBuf->FB_dataSize     = size;
        fontBuf->FB_maker        = FM_TRUETYPE;
        fontBuf->FB_flags        = FBF_IS_OUTLINE;
        fontBuf->FB_heapCount    = 0;

        fontBuf->FB_firstChar    = fontHeader->FH_firstChar;
        fontBuf->FB_lastChar     = fontHeader->FH_lastChar;
        fontBuf->FB_defaultChar  = fontHeader->FH_defaultChar;

        fontBuf->FB_kernCount    = fontHeader->FH_kernCount;
        fontBuf->FB_kernPairs    = fontHeader->FH_kernCount ? OFFSET_KERN_PAIRS : 0;
        fontBuf->FB_kernValues   = fontHeader->FH_kernCount ? OFFSET_KERN_VALUES : 0;

        /* calculate scale factor */
        CalcScaleForWidths( trueTypeVars, pointSize, stylesToImplement );

        /* convert FontHeader and fill FontBuf structure */
        ConvertHeader( trueTypeVars, fontHeader, fontBuf );

        /* fill kerning pairs and kerning values */
        ConvertKernPairs( trueTypeVars, fontBuf );

        /* convert widths and fill CharTableEntries */
        ConvertWidths( trueTypeVars, fontHeader, fontBuf );

        /* calculate the transformation matrix and copy it into the FontBlock */
        transMatrix = (TransformMatrix*)(((byte*)fontBuf) + sizeof( FontBuf ) + fontHeader->FH_numChars * sizeof( CharTableEntry ));
EC(     ECCheckBounds( (void*)transMatrix ) );
        CalcTransform( transMatrix, fontMatrix, pointSize, stylesToImplement );

        /* adjust FB_height, FB_minTSB, FB_pixHeight and FB_baselinePos */
        AdjustFontBuf( transMatrix, fontMatrix, stylesToImplement, fontBuf );

        /* Are the glyphs rendered as regions? */
        if( IsRegionNeeded( transMatrix, fontMatrix, fontBuf ) )
                fontBuf->FB_flags |= FBF_IS_REGION;

        TrueType_Unlock_Face( trueTypeVars );
Fail:        
        MemUnlock( varBlock );
        return fontHandle;
}


/********************************************************************
 *                      ConvertWidths
 ********************************************************************
 * SYNOPSIS:	  Converts the information from the FontHeader and 
 *                fills FontBuf with it.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                *fontHeader           Ptr. to FontHeader structure.
 *                *fontBuf              Ptr. to FontBuf structure.
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

static void ConvertWidths( TRUETYPE_VARS, FontHeader* fontHeader, FontBuf* fontBuf )
{
        word             currentChar;
        CharTableEntry*  charTableEntry = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));
        WWFixedAsDWord   scaledWidth;


        TT_New_Glyph( FACE, &GLYPH );

        for( currentChar = fontHeader->FH_firstChar; currentChar <= fontHeader->FH_lastChar; ++currentChar )
        {
                word    charIndex;


EC(             ECCheckBounds( (void*)charTableEntry ) );

                /* get glyph index of currentChar */
                charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( currentChar ) );
                if ( charIndex == 0 )
                {
                        charTableEntry->CTE_flags          = CTF_NO_DATA;
                        charTableEntry->CTE_dataOffset     = CHAR_NOT_EXIST;
                        charTableEntry->CTE_width.WBF_int  = 0;
                        charTableEntry->CTE_width.WBF_frac = 0;
                        charTableEntry->CTE_usage          = 0;

                        ++charTableEntry;
                        continue;
                }
                      
                /* load glyph and metrics */
                TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
                TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

                /* fill CharTableEntry */
                scaledWidth = GrMulWWFixed( MakeWWFixed( GLYPH_METRICS.advance), SCALE_WIDTH );
                charTableEntry->CTE_width.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( scaledWidth );
                charTableEntry->CTE_width.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( scaledWidth );
                charTableEntry->CTE_dataOffset     = CHAR_NOT_BUILT;
                charTableEntry->CTE_usage          = 0;
                
               
                /* set flags in CTE_flags if needed */
                if( GLYPH_BBOX.xMin < 0 )
                        charTableEntry->CTE_flags |= CTF_NEGATIVE_LSB;
                        
                if( -GLYPH_BBOX.yMin > fontHeader->FH_descent )
                        charTableEntry->CTE_flags |= CTF_BELOW_DESCENT;

                if( GLYPH_BBOX.yMax > fontHeader->FH_ascent )
                        charTableEntry->CTE_flags |= CTF_ABOVE_ASCENT;
                

                if( fontBuf->FB_kernCount )
                {
                        word       i;
                        KernPair*  kernPair  = (KernPair*) ( ( (byte*)fontBuf ) + fontBuf->FB_kernPairs );

                        for( i = 0; i < fontBuf->FB_kernCount; ++i )
                        {
                                /* If currentChar is right or left char in a kernpair set corresponding flags. */
                                if( currentChar == kernPair->KP_charRight )
                                        charTableEntry->CTE_flags |= CTF_IS_FIRST_KERN;
                                else if ( currentChar == kernPair->KP_charLeft )
                                        charTableEntry->CTE_flags |= CTF_IS_SECOND_KERN;

                                /* If currentChar is right and left char in a kernpair, it can be aborted. */
                                if( charTableEntry->CTE_flags && CTF_IS_FIRST_KERN & 
                                    charTableEntry->CTE_flags && CTF_IS_SECOND_KERN )
                                        break;
                        }
                }

                ++charTableEntry;
        } 

        TT_Done_Glyph( GLYPH );
}


/********************************************************************
 *                      ConvertKernPairs
 ********************************************************************
 * SYNOPSIS:	  Fills kern pairs and kern values in FontBuf with 
 *                kerning information.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                *fontBuf              Ptr. to FontBuf structure.
 * 
 * RETURNS:       void
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

static void ConvertKernPairs( TRUETYPE_VARS, FontBuf* fontBuf )
{
        TT_Kerning        kerningDir;
        word              table;

        KernPair*  kernPair  = (KernPair*) ( ( (byte*)fontBuf ) + fontBuf->FB_kernPairs );
        BBFixed*   kernValue = (BBFixed*) ( ( (byte*)fontBuf ) + fontBuf->FB_kernValues );


EC(     ECCheckBounds( (void*)kernPair ) );
EC(     ECCheckBounds( (void*)kernValue ) );

        /* load kerning directory */
        if( TT_Get_Kerning_Directory( FACE, &kerningDir ) )
                return;

        /* search for format 0 subtable */
        for( table = 0; table < kerningDir.nTables; ++table )
        {
                word i;

                if( TT_Load_Kerning_Table( FACE, table ) )
                        return;

                if( kerningDir.tables->format != 0 )
                        continue;

                for( i = 0; i < kerningDir.tables->t.kern0.nPairs; ++i )
                {
                        char left  = getGeosCharForIndex( kerningDir.tables->t.kern0.pairs[i].left );
                        char right = getGeosCharForIndex( kerningDir.tables->t.kern0.pairs[i].right );


                        /* We only support decreasing the character spacing.*/
                        if( kerningDir.tables->t.kern0.pairs[i].value > 0 )
                                continue;

                        if( left && right )
                        {
                                WWFixedAsDWord  scaledKernValue;

                                kernPair->KP_charLeft  = left;
                                kernPair->KP_charRight = right;

                                /* save scaled kerning value */
                                scaledKernValue = SCALE_WORD( kerningDir.tables->t.kern0.pairs[i].value, SCALE_WIDTH );
                                kernValue->BBF_int = IntegerOf( scaledKernValue );
                                kernValue->BBF_frac = FractionOf( scaledKernValue ) >> 8;

                                ++kernPair;
                                ++kernValue;
                        }
                }
        }
}

/********************************************************************
 *                      CalcScaleForWidths
 ********************************************************************
 * SYNOPSIS:	  Fills scale factors in chached variables for calculating 
 *                FontBuf and ChatTableEntries.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                pointSize             Desired point size.
 *                stylesToImplement     Desired text style.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/07/23  JK        Initial Revision
 *******************************************************************/

static void CalcScaleForWidths( TRUETYPE_VARS, WWFixedAsDWord pointSize, 
                                TextStyle stylesToImplement )
{
        SCALE_HEIGHT = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );
        SCALE_WIDTH  = SCALE_HEIGHT;

        if( stylesToImplement & ( TS_BOLD ) )
                SCALE_WIDTH = GrMulWWFixed( SCALE_HEIGHT, WWFIXED_1_POINR_1 );

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )     
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_0_POINT_5 );
}


/********************************************************************
 *                      CalcTransform
 ********************************************************************
 * SYNOPSIS:	  Calculates the transformation matrix for missing
 *                style attributes and weights.
 * 
 * PARAMETERS:    *transMatrix          Pointer to TransformMatrix.
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
                           WWFixedAsDWord    pointSize,
                           TextStyle         stylesToImplement )
{
        TT_Matrix  tempMatrix;
 

EC(     ECCheckBounds( (void*)transMatrix ) );
EC(     ECCheckBounds( (void*)fontMatrix ) );

        /* copy fontMatrix into transMatrix */
        tempMatrix.xx           = 1L << 16;
        tempMatrix.xy           = 0;
        tempMatrix.yx           = 0;
        tempMatrix.yy           = 1L << 16;

        transMatrix->TM_heightX = 0;
        transMatrix->TM_scriptX = 0;
        transMatrix->TM_heightY = 0;
        transMatrix->TM_scriptY = 0;

        /* fake bold style       */
        if( stylesToImplement & TS_BOLD )
                tempMatrix.xx = BOLD_FACTOR;

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                tempMatrix.xy = ITALIC_FACTOR;

        /* fake script style      */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {      
                tempMatrix.xx = GrMulWWFixed( tempMatrix.xx, SCRIPT_FACTOR );
                tempMatrix.yy = GrMulWWFixed( tempMatrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                {
                        transMatrix->TM_scriptY = GrMulWWFixed( SUBSCRIPT_OFFSET, pointSize ) >> 16;
                }
                else
                {
                        transMatrix->TM_scriptY = -( GrMulWWFixed( SUPERSCRIPT_OFFSET, pointSize ) ) >> 16;
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
 * PARAMETERS:    additionalSpace       Additional space in block.
 *                numOfCharacters       Number of GEOS characters.
 *                numOfKernPairs        Number of kerning pairs.
 *                *fontHandle           Pointer to MemHandle of font 
 *                                      block.
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

static word AllocFontBlock( word        additionalSpace,
                            word        numOfCharacters,
                            word        numOfKernPairs,
                            MemHandle*  fontHandle )
{
        word size = sizeof( FontBuf ) + numOfCharacters * sizeof( CharTableEntry ) +
                numOfKernPairs * ( sizeof( KernPair ) + sizeof( WBFixed ) ) +
                additionalSpace; 
                     
        /* allocate memory for FontBuf, CharTableEntries, KernPairs and additional space */
        if( *fontHandle == NullHandle )
        {
                *fontHandle = MemAllocSetOwner( FONT_MAN_ID, MAX_FONTBUF_SIZE, 
                        HF_SWAPABLE | HF_SHARABLE | HF_DISCARDABLE,
                        HAF_NO_ERR | HAF_LOCK | HAF_ZERO_INIT );
EC(             ECCheckMemHandle( *fontHandle ) );
                HandleP( *fontHandle );
        }
        else
        {
                MemReAlloc( *fontHandle, MAX_FONTBUF_SIZE, HAF_NO_ERR | HAF_LOCK );
EC(             ECCheckMemHandle( *fontHandle ) );
        }

        return size;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  Converts FontInfo and fill FontBuf structure.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                *fontHeader           Ptr to FontHeader structure.
 *                *fontBuf              Ptr to FontBuf structure.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11/12/22  JK        Initial Revision
 *******************************************************************/

static void ConvertHeader( TRUETYPE_VARS, FontHeader* fontHeader, FontBuf* fontBuf ) 
{
        WWFixedAsDWord      ttfElement;
        WWFixedAsDWord      scaleWidth  = SCALE_WIDTH;
        WWFixedAsDWord      scaleHeight = SCALE_HEIGHT;
      

 EC(    ECCheckBounds( (void*)fontBuf ) );
 EC(    ECCheckBounds( (void*)fontHeader ) );


        /* Fill elements in FontBuf structure.                               */
        ttfElement = SCALE_WORD( fontHeader->FH_avgwidth, scaleWidth );
        fontBuf->FB_avgwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_avgwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxwidth, scaleWidth );
        fontBuf->FB_maxwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_maxwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_baseAdjust, scaleHeight );
        fontBuf->FB_heightAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_heightAdjust.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_height, scaleHeight );
        fontBuf->FB_height.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_height.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_accent, scaleHeight );
        fontBuf->FB_accent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_accent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
 
        ttfElement = SCALE_WORD( fontHeader->FH_x_height, scaleHeight );
        fontBuf->FB_mean.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_mean.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
 
        ttfElement = SCALE_WORD( fontHeader->FH_baseAdjust, scaleHeight );
        fontBuf->FB_baseAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_baseAdjust.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_ascent + fontHeader->FH_accent, scaleHeight );
        fontBuf->FB_baselinePos.WBF_int  = ROUND_WWFIXED( ttfElement );
        fontBuf->FB_baselinePos.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_descent, scaleHeight );
        fontBuf->FB_descent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_descent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        fontBuf->FB_extLeading.WBF_int  = 0;
        fontBuf->FB_extLeading.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_underPos, scaleHeight );
        fontBuf->FB_underPos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement ) + BASELINE_CORRECTION;
        fontBuf->FB_underPos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_underThick, scaleHeight );
        fontBuf->FB_underThickness.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underThickness.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_accent + fontHeader->FH_ascent - fontHeader->FH_strikePos, scaleHeight );
        fontBuf->FB_strikePos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_strikePos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_minTSB, scaleHeight );
        fontBuf->FB_aboveBox.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_aboveBox.WBF_frac = 0;
        fontBuf->FB_minTSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxBSB, scaleHeight );
        fontBuf->FB_belowBox.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_belowBox.WBF_frac = 0;
        fontBuf->FB_maxBSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_minLSB, scaleWidth );
        fontBuf->FB_minLSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement ); 

        ttfElement = SCALE_WORD( fontHeader->FH_maxRSB, scaleWidth );
        fontBuf->FB_maxRSB  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_height, scaleHeight );
        fontBuf->FB_pixHeight = INTEGER_OF_WWFIXEDASDWORD( ttfElement ) + fontBuf->FB_minTSB;
}


/********************************************************************
 *                      AdjustFontBuf
 ********************************************************************
 * SYNOPSIS:	  Adjust fields in FontBuf to reflect rotating and scaling.
 * 
 * PARAMETERS:    *transMatrix          Ptr to tranfomation matrix.
 *                *fontMatrix           Ptr to systems font matrix.
 *                stylesToImplement
 *                *fontBuf              Ptr to FontBuf structure.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      22/07/23  JK        Initial Revision
 *******************************************************************/

static void AdjustFontBuf( TransformMatrix* transMatrix, 
                           FontMatrix*      fontMatrix, 
                           TextStyle        stylesToImplement, 
                           FontBuf*         fontBuf )
{
        sword savedHeightY = transMatrix->TM_heightY;


        transMatrix->TM_heightY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( fontBuf->FB_baselinePos.WBF_int ), fontMatrix->FM_22 ) ) + BASELINE_CORRECTION;
        transMatrix->TM_scriptY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( transMatrix->TM_scriptY ), fontMatrix->FM_22 ) );

        if( fontMatrix->FM_flags & TF_COMPLEX )
        {
                fontBuf->FB_flags     |= FBF_IS_COMPLEX;

                /* adjust FB_pixHeight, FB_minTSB */
                fontBuf->FB_pixHeight = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ), fontMatrix->FM_22 ) );
                fontBuf->FB_minTSB    = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( fontBuf->FB_minTSB ), fontMatrix->FM_22 ) );

                if( fontMatrix->FM_flags & TF_ROTATED )
                {
                        /* adjust FB_pixHeight, FB_minTSB */
                        fontBuf->FB_pixHeight = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( fontBuf->FB_height.WBF_int ), transMatrix->TM_matrix.yy ) );
                        fontBuf->FB_minTSB    = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( fontBuf->FB_minTSB ), transMatrix->TM_matrix.xy ) );

                        /* adjust script and height */
                        transMatrix->TM_heightY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( fontBuf->FB_baselinePos.WBF_int ), transMatrix->TM_matrix.yy ) );
                        transMatrix->TM_heightX = -INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( fontBuf->FB_baselinePos.WBF_int ), transMatrix->TM_matrix.xy ) );
                        
                        transMatrix->TM_scriptX = 0; /*-INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( savedHeightY ), transMatrix->TM_matrix.xy ) );*/

                        transMatrix->TM_scriptY = 0; /* INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( savedHeightY - transMatrix->TM_heightY + transMatrix->TM_scriptY ), -transMatrix->TM_matrix.yx ) );*/
                }

                /* fontMatrix->FM_12 = -fontMatrix->FM_12;
                fontMatrix->FM_21 = -fontMatrix->FM_21; */
                transMatrix->TM_matrix.xy = -transMatrix->TM_matrix.yx;
        }

}


/********************************************************************
 *                      IsRegionNeeded
 ********************************************************************
 * SYNOPSIS:	  Determines whether glyphs should be rendered as 
 *                region.
 * 
 * PARAMETERS:    *transMatrix          Ptr to tranfomation matrix.
 *                *fontMatrix           Ptr to systems font matrix.
 *                *fontBuf              Ptr to FontBuf structure.
 * 
 * RETURNS:       Boolean
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      22/07/23  JK        Initial Revision
 *******************************************************************/

static Boolean IsRegionNeeded( TransformMatrix* transMatrix, FontMatrix* fontMatrix, FontBuf* fontBuf )
{
        sword param1;
        sword param2;


        param1 = IntegerOf( GrMulWWFixed( fontMatrix->FM_11, ( (WWFixedAsDWord)fontBuf->FB_pixHeight ) >> 16 ) );
        param2 = IntegerOf( GrMulWWFixed( fontMatrix->FM_21, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        if( ( ABS( param1 ) + ABS( param2 ) ) > MAX_BITMAP_SIZE )
                return TRUE;

        param1 = IntegerOf( GrMulWWFixed( fontMatrix->FM_12, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        param2 = IntegerOf( GrMulWWFixed( fontMatrix->FM_22, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        if( ( ABS( param1 ) + ABS( param2 ) ) > MAX_BITMAP_SIZE )
                return TRUE;

        if( transMatrix->TM_heightX + transMatrix->TM_scriptX > MAX_BITMAP_SIZE )
                return TRUE;

        if( transMatrix->TM_heightY + transMatrix->TM_scriptY > MAX_BITMAP_SIZE )
                return TRUE;

        return FALSE;
}
