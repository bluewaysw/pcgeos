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


static word  AllocFontBlock( 
                        word        additionalSpace,
                        word        numOfCharacters,
                        word        numOfKernPairs,
                        MemHandle*  fontHandle );

static WWFixedAsDWord CalcScaleForWidths( 
                        WWFixedAsDWord  pointSize,
                        TextStyle       stylesToImplement,
                        word            unitsPerEM );

static void ConvertHeader( 
                        WWFixedAsDWord  scaleFactor,
                        FontHeader*     fontHeader, 
                        FontBuf*        fontBuf );

static void ConvertWidths( 
                        TRUETYPE_VARS, 
                        WWFixedAsDWord  scaleFactor,
                        FontHeader*     fontHeader, 
                        FontBuf*        fontBuf );
            
static void ConvertKernPairs( TRUETYPE_VARS, FontBuf* fontBuf );

static void CalcTransform( 
                        TransformMatrix*  transMatrix,
                        FontMatrix*       fontMatrix, 
                        TextStyle         styleToImplement );

static word round( WWFixedAsDWord toRound );


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:	  Generate header width infomation about a front 
 *                in a given pointsize and style.
 * 
 * PARAMETERS:    fontHandle            Memory handle to font block.
 *                *fontMatrix           Pointer to tranformation matrix.
 *                pointSize             Desired point size.
 *                *fontInfo             Pointer to font info structure.
 *                textStyle             Desired text style.
 *                MemHandle             Memory handle to var block.
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
        FileHandle             truetypeFile;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TrueTypeVars*          trueTypeVars;
        FontHeader*            fontHeader;
        FontBuf*               fontBuf;
        word                   size;
        WWFixedAsDWord         scaleFactor;
        TransformMatrix*       transMatrix;


        ECCheckMemHandle( fontHandle );
        ECCheckBounds( (void*)fontMatrix );
        ECCheckBounds( (void*)fontInfo );
        ECCheckBounds( (void*)headerEntry );
        ECCheckBounds( (void*)firstEntry );
        ECCheckStack();


        // get trueTypeVar block
        trueTypeVars = MemLock( varBlock );
        if( trueTypeVars == NULL )
        {
                MemReAlloc( varBlock, sizeof( TrueTypeVars ), HAF_NO_ERR );
                trueTypeVars = MemLock( varBlock );
        }
        
        ECCheckBounds( (void*)trueTypeVars );

        // get filename an load ttf file
        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        // get filename an load ttf file 
        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), headerEntry->OE_handle );
        truetypeFile = FileOpen( trueTypeOutline->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );

        ECCheckFileHandle( truetypeFile );

        // get pointer to FontHeader
        fontHeader = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), firstEntry->OE_handle );

        if ( TT_Open_Face( truetypeFile, &FACE ) )
                goto Fin;

        if ( TT_Get_Face_Properties( FACE, &FACE_PROPERTIES ) )
                goto Fail;

        /* alloc Block for FontBuf, CharTableEntries, KernPairs and kerning values */
        size = AllocFontBlock( sizeof( TransformMatrix ), 
                               fontHeader->FH_numChars, 
                               CountKernPairsWithGeosChars( FACE ), 
                               &fontHandle );

        /* calculate scale factor and transformation matrix */
        scaleFactor = CalcScaleForWidths( pointSize, 
                                          stylesToImplement, 
                                          FACE_PROPERTIES.header->Units_Per_EM );

        /* convert FontHeader and fill FontBuf structure */
        fontBuf = (FontBuf*)MemDeref( fontHandle );
        fontBuf->FB_dataSize = size;
        ConvertHeader( scaleFactor, fontHeader, fontBuf );

        /* fill kerning pairs and kerning values */
        ConvertKernPairs( trueTypeVars, fontBuf );

        /* convert widths and fill CharTableEntries */
        ConvertWidths( trueTypeVars, scaleFactor ,fontHeader, fontBuf );

        /* calculate the transformation matrix and copy it into the FontBlock */
        transMatrix = (TransformMatrix*)(((byte*)fontBuf) + sizeof( FontBuf ) + fontHeader->FH_numChars * sizeof( CharTableEntry ));
        CalcTransform( transMatrix, fontMatrix, stylesToImplement );

        //TODO: adjust FB_height, FB_minTSB, FB_pixHeight and FB_baselinePos

Fail:
        TT_Close_Face( FACE );
Fin:        
        FileClose( truetypeFile, FALSE );
        MemUnlock( varBlock );
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

static void ConvertWidths( TRUETYPE_VARS, WWFixedAsDWord scaleFactor, FontHeader* fontHeader, FontBuf* fontBuf )
{
        word             currentChar;
        CharTableEntry*  charTableEntry = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));
        WWFixedAsDWord   scaledWidth;


        TT_New_Glyph( FACE, &GLYPH );
        TT_New_Instance( FACE, &INSTANCE );
        getCharMap( FACE, &CHAR_MAP );

        for( currentChar = fontHeader->FH_firstChar; currentChar <= fontHeader->FH_lastChar; ++currentChar )
        {
                word    charIndex;


                ECCheckBounds( (void*)charTableEntry );

                //Unicode to TT ID
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
                      
                //Glyph laden
                TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
                TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

                //width berechnen
                scaledWidth = GrMulWWFixed( MakeWWFixed( GLYPH_METRICS.advance), scaleFactor );
                charTableEntry->CTE_width.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( scaledWidth );
                charTableEntry->CTE_width.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( scaledWidth );

                // nur TEST
                charTableEntry->CTE_dataOffset     = CHAR_NOT_BUILT;
                charTableEntry->CTE_flags          = 0;
                charTableEntry->CTE_usage          = 0;
                
               
                // set flags in CTE_flags if needed
                if( GLYPH_BBOX.xMin < 0 )
                        charTableEntry->CTE_flags |= CTF_NEGATIVE_LSB;

                //below descent
                if( -GLYPH_BBOX.yMin > fontHeader->FH_descent )
                        charTableEntry->CTE_flags |= CTF_BELOW_DESCENT;

                //above ascent
                if( GLYPH_BBOX.yMax > fontHeader->FH_ascent )
                        charTableEntry->CTE_flags |= CTF_ABOVE_ASCENT;
                

                if( fontBuf->FB_kernCount > 0 )
                {
                        //first kern

                        //second kern
                }

                ++charTableEntry;
        } 

        TT_Done_Instance( INSTANCE );
        TT_Done_Glyph( GLYPH );
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
                        TextStyle       stylesToImplement,
                        word            unitsPerEM )
{
        WWFixedAsDWord scaleWidth = GrUDivWWFixed( pointSize, MakeWWFixed( unitsPerEM ) );

        /* do bold need to be added? */
        if( stylesToImplement & TS_BOLD )
                scaleWidth = GrMulWWFixed( scaleWidth, WWFIXED_1_POINR_1 );

        /* do subscript or superscript to be added? */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
                scaleWidth = GrMulWWFixed( scaleWidth, WWFIXED_0_POINT_5 );

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

static void ConvertKernPairs( TRUETYPE_VARS, FontBuf* fontBuf )
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
                           TextStyle         stylesToImplement )
{
        TT_Matrix  tempMatrix;


        ECCheckBounds( (void*)transMatrix );
        ECCheckBounds( (void*)fontMatrix );

        /* copy fontMatrix into transMatrix */
        tempMatrix.xx = 1L << 16;
        tempMatrix.xy = 0;
        tempMatrix.yx = 0;
        tempMatrix.yy = 1L << 16;

        /* fake bold style       */
        if( stylesToImplement & TS_BOLD )
                tempMatrix.xx = BOLD_FACTOR;

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                tempMatrix.yx = ITALIC_FACTOR;

        /* fake script style      */
        if( stylesToImplement & TS_SUBSCRIPT || stylesToImplement & TS_SUBSCRIPT )
        {      
                tempMatrix.xx = GrMulWWFixed( tempMatrix.xx, SCRIPT_FACTOR );
                tempMatrix.yy = GrMulWWFixed( tempMatrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                        transMatrix->TM_shiftY = -SCRIPT_SHIFT_FACTOR;
                else
                        transMatrix->TM_shiftY = SCRIPT_SHIFT_FACTOR;
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
        if( *fontHandle == NullHandle )
        {
                *fontHandle = MemAllocSetOwner( FONT_MAN_ID, MAX_FONTBUF_SIZE, 
                        HF_SWAPABLE | HF_SHARABLE | HF_DISCARDABLE,
                        HAF_NO_ERR | HAF_LOCK );
                HandleP( *fontHandle );
        }
        else
        {
                MemReAlloc( *fontHandle, MAX_FONTBUF_SIZE, HAF_NO_ERR | HAF_LOCK );
        }

        return size;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  Converts FontInfo and fill FontBuf structure.
 * 
 * PARAMETERS:    pointSize             Current pointsize.
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

void ConvertHeader( WWFixedAsDWord scaleFactor, FontHeader* fontHeader, FontBuf* fontBuf ) 
{
        WWFixedAsDWord      ttfElement;
      

        ECCheckBounds( (void*)fontBuf );
        ECCheckBounds( (void*)fontHeader );


        /* Fill elements in FontBuf structure.                               */
        ttfElement = SCALE_WORD( fontHeader->FH_avgwidth, scaleFactor );
        fontBuf->FB_avgwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_avgwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxwidth, scaleFactor );
        fontBuf->FB_maxwidth.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_maxwidth.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_baseAdjust, scaleFactor );
        fontBuf->FB_heightAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_heightAdjust.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_height, scaleFactor );
        fontBuf->FB_height.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_height.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_accent, scaleFactor );
        fontBuf->FB_accent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_accent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
 
        ttfElement = SCALE_WORD( fontHeader->FH_x_height, scaleFactor );
        fontBuf->FB_mean.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_mean.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );
 
        ttfElement = SCALE_WORD( fontHeader->FH_baseAdjust, scaleFactor );
        fontBuf->FB_baseAdjust.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_baseAdjust.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_ascent + fontHeader->FH_accent, scaleFactor );
        fontBuf->FB_baselinePos.WBF_int  = round( ttfElement );
        fontBuf->FB_baselinePos.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_descent, scaleFactor );
        fontBuf->FB_descent.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_descent.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        fontBuf->FB_extLeading.WBF_int  = 0;
        fontBuf->FB_extLeading.WBF_frac = 0;

        ttfElement = SCALE_WORD( fontHeader->FH_underPos, scaleFactor );
        fontBuf->FB_underPos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underPos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_underThick, scaleFactor );
        fontBuf->FB_underThickness.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_underThickness.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_strikePos, scaleFactor );
        fontBuf->FB_strikePos.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_strikePos.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_minTSB, scaleFactor );
        fontBuf->FB_aboveBox.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_aboveBox.WBF_frac = 0;
        fontBuf->FB_minTSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_maxBSB, scaleFactor );
        fontBuf->FB_belowBox.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );
        fontBuf->FB_belowBox.WBF_frac = 0;
        fontBuf->FB_maxBSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_minLSB, scaleFactor );
        fontBuf->FB_minLSB = INTEGER_OF_WWFIXEDASDWORD( ttfElement ); 

        ttfElement = SCALE_WORD( fontHeader->FH_maxRSB, scaleFactor );
        fontBuf->FB_maxRSB  = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        ttfElement = SCALE_WORD( fontHeader->FH_height + fontHeader->FH_accent, scaleFactor );
        fontBuf->FB_pixHeight = INTEGER_OF_WWFIXEDASDWORD( ttfElement );

        fontBuf->FB_maker        = FM_TRUETYPE;
        fontBuf->FB_kernPairPtr  = 0;
        fontBuf->FB_kernValuePtr = 0;
        fontBuf->FB_kernCount    = 0;
        fontBuf->FB_heapCount    = 0;
	fontBuf->FB_flags        = fontBuf->FB_pixHeight < 125 ? FBF_IS_OUTLINE : FBF_IS_REGION;
        fontBuf->FB_firstChar    = fontHeader->FH_firstChar;
        fontBuf->FB_lastChar     = fontHeader->FH_lastChar;
        fontBuf->FB_defaultChar  = fontHeader->FH_defaultChar;
}

static word round( WWFixedAsDWord toRound )
{
        return toRound & 0xffff ? ( toRound >> 16 ) + 1 : toRound >> 16;
}
